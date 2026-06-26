--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local FunnelsModule = require(ReplicatedStorage.Packages.funnelsModule)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)
local FindValue = require(Helpers.Table.FindValue)

-- Services
local DataCacheService = nil

-- ProfileService
local ServerModules = script.Parent.Parent.Modules
local ProfileService = require(ServerModules.ProfileService)
local ProfileTemplate = nil
local ProfileStore = nil

-- Tambahkan table untuk menyimpan checkpoint terakhir setiap player
local economyMilestones = {}

-- Variables
local USE_DEFAULT_DATA = false

-- Knit Logic
local DataService = Knit.CreateService({
	Name = "DataService",
	Profiles = {},
	Template = {},
	Client = {
		DataInit = Knit.CreateSignal(),
		Money1Updated = Knit.CreateSignal(),
		Money2Updated = Knit.CreateSignal(),
		WinsUpdated = Knit.CreateSignal(),
		GoalsUpdated = Knit.CreateSignal(),
		RebirthsUpdated = Knit.CreateSignal(),
		AreasUpdated = Knit.CreateSignal(),
		AreaUpdated = Knit.CreateSignal(),
		TutorialCompleted = Knit.CreateSignal(),
	},

	PowerUpdatedSignal = Signal.new(),
	RebirthUpdatedSignal = Signal.new(),
	TutorialCompletedSignal = Signal.new(),
})

-- Constants
local TYPES = {
	Money1 = "Money1Updated",
	Money2 = "Money2Updated",
	Wins = "WinsUpdated",
	Goals = "GoalsUpdated",
	Rebirth = "RebirthsUpdated",
}

--|| Client Functions ||--

-- Returns player's data to client
function DataService.Client:GetData(player: Player): {} | nil
	return self.Server:GetData(player)
end

function DataService.Client:TutorialFinished(player: Player, state: boolean)
	return self.Server:TutorialFinished(player, state)
end

function DataService.Client:AddArea(player: Player, name: string)
	return self.Server:AddArea(player, name)
end

function DataService.Client:TutorialProgressed(player: Player, step: number)
	return self.Server:TutorialProgressed(player, step)
end

--|| Local Functions ||--
function DataService:_createLeaderStats(player: Player, data: {})
	if not data or not next(data) then
		warn("[DATA SERVICE] _createLeaderStats called with empty data for player: " .. player.Name)
	end

	local LeaderStats = Instance.new("Folder")
	LeaderStats.Name = "leaderstats"

	local Money2 = Instance.new("StringValue")
	Money2.Name = self.Template.Economy.Money2 -- To change with config call when done
	Money2.Value = FormatNumber(if data and data.Money2 then data.Money2 else 0)
	Money2.Parent = LeaderStats

	local Wins = Instance.new("StringValue")
	Wins.Name = "Wins"
	Wins.Value = FormatNumber(if data and data.Wins then data.Wins else 0)
	Wins.Parent = LeaderStats

	LeaderStats.Parent = player
end

-- Update LeaderStats
function DataService:_updateLeaderStats(player: Player)
	local data = self:GetData(player)
	if not data then
		warn("[DATA SERVICE] _updateLeaderStats called with nil data for player: " .. player.Name)
		return
	end
	player.leaderstats[self.Template.Economy.Money2].Value = FormatNumber(if data.Money2 then data.Money2 else 0)
	player.leaderstats.Wins.Value = FormatNumber(if data.Wins then data.Wins else 0)
end

-- Init & cache player profile
function DataService:_initAndCache(player: Player, profile: {})
	local data = profile.Data

	self:_createLeaderStats(player, data)

	self.Profiles[player] = profile
	player:SetAttribute("DataLoaded", true)

	print("[DATA SERVICE] Data loaded: " .. player.Name)
end

-- Delete player datas
function DataService:_deletePlayerProfile(userId: string)
	return ProfileStore:WipeProfileAsync("FinalData_1" .. PlayerService:GetUserIdFromNameAsync(userId.Name)) --FinalData_6
end

-- Load player datas
function DataService:_loadData(player: Player)
	local profile = ProfileStore:LoadProfileAsync("FinalData_1" .. player.UserId) ---FinalData_6

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			self.Profiles[player] = nil
			player:Kick("Data loaded on another server. Please rejoin!")
		end)

		if player:IsDescendantOf(Players) == true then
			if USE_DEFAULT_DATA then
				profile.Data = TableUtil.Copy(ProfileTemplate, true)
			end

			self:_initAndCache(player, profile)
			return profile
		else
			profile:Release()
		end
	else
		player:Kick("An error occured while loading your datas. Please rejoin!")
	end
end

-- Saver player datas
function DataService:_saveData(player: Player)
	local profile = self.Profiles[player]

	if profile ~= nil then
		profile.Data.LastConnection = os.time()
		profile:Release()
	end

	self.Profiles[player] = nil
	print("[DATA SERVICE] Data saved: " .. player.Name)
end

-- Reset player datas
function DataService:_resetData(player: Player)
	-- Pastikan profil dan template tersedia
	if not ProfileTemplate or not ProfileStore then
		warn("[DATA SERVICE] ProfileTemplate or ProfileStore not initialized!")
		return false
	end

	local profile = self.Profiles[player]

	if profile then
		-- Set data pemain ke template default
		profile.Data = TableUtil.Copy(ProfileTemplate, true)

		-- Perbarui data dan tampilan leaderstats
		self:_updateLeaderStats(player)

		-- Kirim notifikasi pembaruan data ke client
		player:SetAttribute("DataLoaded", true)
		print("[DATA SERVICE] Data has been reset for player:", player.Name)
		return true
	else
		warn("[DATA SERVICE] Failed to reset data for player:", player.Name, "- Profile not found!")
		return false
	end
end

--|| Server Functions ||--
function DataService:GetData(player: Player): {} | nil
	local profile = self.Profiles[player]

	if profile == nil then
		repeat
			task.wait(1)
			profile = self.Profiles[player]
		until profile ~= nil or player.Parent == nil
	end

	if profile ~= nil then
		return profile.Data
	else
		return nil
	end
end

-- Get the amount of given wins froms packs in the store based on player's rebirths
function DataService:GetWinsPackAmount(player: Player, pack: string)
	local data = self:GetData(player)
	if data == nil then
		return 0
	end

	return self.Template.WinsPacks[data.Areas.Unlocked[table.maxn(data.Areas.Unlocked)]][pack]
end

-- Edit value in player data & leaderstats
function DataService:ChangeValue(player: Player, key: string, value: number, cancelMultipliers: boolean?)
	local data = self:GetData(player)
	if data == nil then
		return
	end
	if not table.find({ "Money1", "Money2", "Rebirth", "Wins", "Goals" }, key) then
		return
	end -- Can't use this function if not for a number data

	local function GetFriends()
		local Friends = {}
		for _, Player in Players:GetPlayers() do
			if Player ~= player then
				if Player:IsFriendsWith(player.UserId) then
					table.insert(Friends, Player)
				end
			end
		end
		return Friends
	end

	if not cancelMultipliers and value > 0 then
		-- Item Boosts
		local Template = DataCacheService:GetFile("Template")
		local Boosts = Template.Boosts

		if Boosts then
			for _, item in pairs(data.Inventory.ActiveFruits or {}) do
				local itemName = (typeof(item) == "table" and item.Name) or item
				local itemData = Template.Fruits and Template.Fruits[itemName]
				if itemData and key == itemData.Type then
					value *= 1 + (itemData.Boost or 0)
				end
			end

			for _, item in pairs(data.Inventory.ActiveBoosts or {}) do
				local itemName = (typeof(item) == "table" and item.Name) or item
				local itemData = Boosts[itemName]
				if itemData and key == itemData.Type then
					value *= 2
				end
			end
		end

		-- Global Multipliers
		value = value * (1 + (data.Rebirth * 0.2)) -- Each rebirth give a +20% multiplier
		value = value * (1 + (#GetFriends() * 0.10)) -- Each friend online gives a +10% multiplier to the player

		if data.Codes and data.Codes.Verified then
			value *= 2
		end

		if player.MembershipType == Enum.MembershipType.Premium then
			value *= 1.1
		end

		if FindValue(data.Gamepasses, "VIP") then
			value *= 2
		end

		if
			FindValue(
				data.Gamepasses,
				"x2 "
					.. key:gsub("Money1", self.Template.Economy.Money1)
						:gsub("Money2", self.Template.Economy.Money2)
						:gsub("Rebirth", "Rebirths")
			)
		then
			value *= 2
		end
	end
	value = math.round(value)

	data[key] += value

	if data[key] < 0 then
		data[key] = 0
	end

	if key == "Goals" and data[key] >= 100 then
		if self.Template.Badges and self.Template.Badges.Goal then
			self:GiveBadge(player, self.Template.Badges.Goal)
		end
	end

	-- --- INI BAGIAN TAMBAHAN UNTUK LOG ECONOMY HANYA PADA KELIPATAN 1 T ---
	-- --- ECONOMY LOGGING SAFETY PATCH ---
	local milestoneKey = player.UserId .. "_" .. key
	local currentMilestone = math.floor(data[key] / 1_000_000_000_000)

	if not economyMilestones[milestoneKey] then
		economyMilestones[milestoneKey] = -1
	end

	if currentMilestone > economyMilestones[milestoneKey] then
		economyMilestones[milestoneKey] = currentMilestone

		local shouldLogEconomy = key == "Money1" or key == "Money2" or key == "Wins" or key == "Rebirth"

		if shouldLogEconomy then
			local successLog, logError = pcall(function()
				FunnelsModule:LogInGameEconomyEvent(player, key, math.abs(value), data[key])
			end)

			if not successLog then
				warn(("[DATA SERVICE] Economy log skipped for key %s: %s"):format(tostring(key), tostring(logError)))
			end
		end
	end
	-- ------------------------------------
	-- --------------------------------------------------------------------------

	task.delay(1.5, function()
		self.Client[TYPES[key]]:Fire(player, value)
		if key == "Money2" then
			self.PowerUpdatedSignal:Fire(player, data.Money2)
		elseif key == "Rebirth" then
			self.RebirthUpdatedSignal:Fire(player, data.Rebirth)
		end
	end) -- Send information to client to update stores
	self:_updateLeaderStats(player)

	return value
end

function DataService:ChangeValueRebirth(player: Player)
	local data = self:GetData(player)
	local value = 1
	if FindValue(data.Gamepasses, "x2 Rebirths") then
		value *= 2
	end
	data.Rebirth += 1 * value
	self.Client.RebirthsUpdated:Fire(player, value)
	self.RebirthUpdatedSignal:Fire(player, data.Rebirth)

	FunnelsModule:LogInGameEconomyEvent(player, "Rebirth", value, data.Rebirth)

	return 1
end

function DataService.Client:ChangeValueSettings(player, category, value)
	return self.Server:ChangeValueSettings(player, category, value)
end

function DataService:ChangeValueSettings(player: Player, category, value)
	local data = self:GetData(player)
	if data.Settings.Sound[category] then
		data.Settings.Sound[category] = value
	end
end

function DataService.Client:GetValue(player: Player, key: string, value: number, cancelMultipliers: boolean?)
	return self.Server:GetValue(player, key, value, cancelMultipliers)
end

function DataService:GetValue(player: Player, key: string, value: number, cancelMultipliers: boolean?)
	local data = self:GetData(player)
	if data == nil then
		return
	end
	if not table.find({ "Money1", "Money2", "Rebirth", "Wins" }, key) then
		return
	end -- Can't use this function if not for a number data

	local function GetFriends()
		local Friends = {}
		for _, Player in Players:GetPlayers() do
			if Player ~= player then
				if Player:IsFriendsWith(player.UserId) then
					table.insert(Friends, Player)
				end
			end
		end
		return Friends
	end

	if not cancelMultipliers and value > 0 then
		-- Item Boosts
		local Template = DataCacheService:GetFile("Template")
		local Boosts = Template.Boosts

		if Boosts then
			for _, item in pairs(data.Inventory.ActiveFruits or {}) do
				local itemName = (typeof(item) == "table" and item.Name) or item
				local itemData = Template.Fruits and Template.Fruits[itemName]
				if itemData and key == itemData.Type then
					value *= 1 + (itemData.Boost or 0)
				end
			end

			for _, item in pairs(data.Inventory.ActiveBoosts or {}) do
				local itemName = (typeof(item) == "table" and item.Name) or item
				local itemData = Boosts[itemName]
				if itemData and key == itemData.Type then
					value *= 2
				end
			end
		end

		-- Global Multipliers
		value = value * (1 + (data.Rebirth * 0.2)) -- Each rebirth give a +20% multiplier
		value = value * (1 + (#GetFriends() * 0.10)) -- Each friend online gives a +10% multiplier to the player

		if data.Codes and data.Codes.Verified then
			value *= 2
		end

		if player.MembershipType == Enum.MembershipType.Premium then
			value *= 1.1
		end

		if FindValue(data.Gamepasses, "VIP") then
			value *= 2
		end

		if
			FindValue(
				data.Gamepasses,
				"x2 "
					.. key:gsub("Money1", self.Template.Economy.Money1)
						:gsub("Money2", self.Template.Economy.Money2)
						:gsub("Rebirth", "Rebirths")
			)
		then
			value *= 2
		end
	end

	value = math.round(value)
	return value
end

function DataService:UpdateData(player: Player, data: {})
	self.Profiles[player] = data
end

-- Add area to player's data
function DataService:AddArea(player: Player, name: string)
	local data = self:GetData(player)
	if data == nil then
		return
	end

	local number = tonumber(string.match(name, "%d+"))

	table.insert(data.Areas.Unlocked, name)
	self.Client.AreasUpdated:Fire(player, data.Areas.Unlocked)
	FunnelsModule:LogProgressionStep(player, 1, number)

	self:GiveBadge(player, self.Template.Badges[name])
end

-- Change player's area
function DataService:SetArea(player: Player, name: string)
	local data = self:GetData(player)
	if data == nil then
		return
	end

	data.Area = name

	data.Areas = data.Areas or {
		Unlocked = {},
		Current = name,
		CurrentWave = 1,
	}

	data.Areas.Current = name

	self.Client.AreaUpdated:Fire(player, name)
end

function DataService:TutorialProgressed(player: Player, step: number)
	local data = self:GetData(player)
	if data == nil then
		return
	end

	local currentStep = data.TutorialStep or 0

	if step > currentStep then
		if step == 2 then
			self:ChangeValue(player, "Wins", 1000, true)
		elseif step == 7 then
			self:ChangeValue(player, "Wins", 500, true)
		elseif step == 9 then
			self:ChangeValue(player, "Wins", 200, true)
		end

		data.TutorialStep = step
		FunnelsModule:LogOnboardingStep(player, step)
	end
end

-- Change tutorial state
function DataService:TutorialFinished(player: Player, state: boolean)
	local data = self:GetData(player)
	if data == nil then
		return
	end

	data.TutorialComplete = true
	FunnelsModule:LogOnboardingStep(player, 12)
	self.Client.TutorialCompleted:Fire(player)
	self.TutorialCompletedSignal:Fire(player)
end

function DataService:GiveBadge(player: Player, badgeId: number)
	if not badgeId or typeof(badgeId) ~= "number" then
		return
	end

	local data = self:GetData(player)
	if data == nil then
		return
	end

	-- Award badge directly (AwardBadge handles checking if the user already has the badge internally)
	local successAward, resultAward = pcall(function()
		return BadgeService:AwardBadge(player.UserId, badgeId)
	end)

	if not successAward then
		warn(`Failed to award badge {badgeId} to {player.Name}: {resultAward}`)
	end
end

function DataService:GiveBadgeForEachUnlockedArea(player: Player)
	local data = self:GetData(player)
	if data == nil then
		return
	end

	for _, value in data.Areas.Unlocked do
		if self.Template.Badges[value] then
			local badgeId = self.Template.Badges[value]

			self:GiveBadge(player, badgeId)
		end
	end
end

--|| Knit Lifecycle ||--
function DataService:KnitInit()
	DataCacheService = Knit.GetService("DataCacheService")

	ProfileTemplate = DataCacheService:GetFile("Player")
	ProfileStore = ProfileService.GetProfileStore("1", ProfileTemplate)

	self.Template = DataCacheService:GetFile("Template")
	local funnelInfo = {
		groupName = "Progression",
		step = 1,
		name = "Player Joined",
	}

	local function _playerAdded(player: Player)
		self:_loadData(player)
		self:GiveBadgeForEachUnlockedArea(player)
	end

	local function _playerRemoved(player: Player)
		self:_saveData(player)
		-- self:_resetData(player)
	end

	for _, Player in pairs(Players:GetPlayers()) do
		_playerAdded(Player)
	end

	Players.PlayerAdded:Connect(_playerAdded)
	Players.PlayerRemoving:Connect(_playerRemoved)

	print("[DATA SERVICE] Service loaded successfully.")
end

return DataService
