--[=[
    Owner: JustStop__
    Version: v0.0.2
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local FunnelsModule = require(ReplicatedStorage.Packages.funnelsModule)

-- Services
local DataCacheService = nil
local DataService = nil
local FightService = nil

-- CoachesService
local CoachesService = Knit.CreateService({
	Name = "CoachesService",

	Template = {},

	Client = {
		CoachesUpdated = Knit.CreateSignal(),
		CoachBought = Knit.CreateSignal(),
		PlayerCoachesUpdated = Knit.CreateSignal(),
	},

	CoachesToggled = {},
})

--|| Local Functions ||--

local function ensureCoachData(data: table)
	if data.Coaches == nil then
		data.Coaches = {
			Unlocked = {},
			Current = 0,
		}
	end

	data.Coaches.Unlocked = data.Coaches.Unlocked or {}
	data.Coaches.Current = data.Coaches.Current or 0

	return data.Coaches
end

--|| Client Functions ||--

function CoachesService.Client:GetCoachesData(player: Player)
	return self.Server:GetCoachesData(player)
end

function CoachesService.Client:Buy(player: Player, id: number)
	return self.Server:Buy(player, id)
end

function CoachesService.Client:Equip(player: Player, id: number)
	return self.Server:Equip(player, id)
end

function CoachesService.Client:Unequip(player: Player)
	return self.Server:Unequip(player)
end

function CoachesService.Client:GetCoaches(player: Player, requestedPlayer: Player)
	requestedPlayer = requestedPlayer or player
	return self.Server:GetCoaches(player, requestedPlayer)
end

--|| Server Functions ||--
function CoachesService:GetCoachesData(player: Player)
	local Data = DataService:GetData(player)
	local id = Data.Coaches.Current
	return id
end

function CoachesService:BuildEquippedCoachPayload(data: table): table
	local coachesData = ensureCoachData(data)
	local equippedFormat = {}

	if coachesData.Current ~= 0 and self.Template.Coaches then
		local currentCoach = self.Template.Coaches[coachesData.Current]
		if currentCoach then
			equippedFormat["ActiveCoach"] = currentCoach
		end
	end

	return equippedFormat
end

function CoachesService:BroadcastCoachState(player: Player, data: table)
	local coachesData = ensureCoachData(data)

	self.Client.CoachesUpdated:Fire(player, {
		Unlocked = coachesData.Unlocked,
		Current = coachesData.Current,
	})

	self.Client.PlayerCoachesUpdated:FireAll(player, self:BuildEquippedCoachPayload(data))
end

function CoachesService:Buy(player: Player, id: number, bypassPrice: boolean?)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[COACH SERVICE] Player has no data: " .. player.Name)
	end

	local coachesData = ensureCoachData(data)
	local coach = self.Template.Coaches and self.Template.Coaches[id]

	if coach == nil then
		return { text = self.Template.Messages.Notifications.Coach_Not_Exists(tostring(id)), type = "ERROR" }
	end

	if table.find(coachesData.Unlocked, id) then
		return self:Equip(player, id)
	end

	local price = coach.Price or 0

	if data.Wins < price and not bypassPrice then
		return { text = self.Template.Messages.Notifications.Not_Enough_Money("Wins"), type = "ERROR" }
	end

	if not bypassPrice and price > 0 then
		FunnelsModule:LogIGPEconomyEvent(player, "Wins", price, data.Wins - price, coach.Name)
		DataService:ChangeValue(player, "Wins", -price, true)
	end

	table.insert(coachesData.Unlocked, id)
	self.Client.CoachBought:Fire(player, id)

	local equipResult = self:Equip(player, id)
	if equipResult then
		equipResult.text = self.Template.Messages.Notifications.Coach_Bought(coach.DisplayName or coach.Name)
	end

	return equipResult
		or {
			text = self.Template.Messages.Notifications.Coach_Bought(coach.DisplayName or coach.Name),
			type = "SUCCESS",
		}
end

function CoachesService:Equip(player: Player, id: number)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[COACH SERVICE] Player has no data: " .. player.Name)
	end

	local coachesData = ensureCoachData(data)

	-- simpan coach yang sedang dipakai sebelumnya
	local previousCoach = nil
	if coachesData.Current ~= 0 then
		previousCoach = self.Template.Coaches and self.Template.Coaches[coachesData.Current]
	end

	local coach = nil

	if id ~= 0 then
		coach = self.Template.Coaches and self.Template.Coaches[id]
		if coach == nil then
			return { text = self.Template.Messages.Notifications.Coach_Not_Exists(tostring(id)), type = "ERROR" }
		end

		if not table.find(coachesData.Unlocked, id) then
			return {
				text = self.Template.Messages.Notifications.Coach_Not_Owned(coach.DisplayName or coach.Name),
				type = "ERROR",
			}
		end
	end

	coachesData.Current = id

	self:BroadcastCoachState(player, data)

	if id == 0 then
		local previousCoachName = previousCoach and (previousCoach.DisplayName or previousCoach.Name) or "coach"
		return {
			text = self.Template.Messages.Notifications.Coach_Unequipped(previousCoachName),
			type = "SUCCESS",
		}
	end

	local coachName = coach.DisplayName or coach.Name
	return {
		text = self.Template.Messages.Notifications.Coach_Equipped(coachName),
		type = "SUCCESS",
	}
end

function CoachesService:Unequip(player: Player)
	return self:Equip(player, 0)
end

function CoachesService:GetCoaches(player: Player, requestedPlayer: Player)
	local data = DataService:GetData(requestedPlayer)
	if not data then
		return {}
	end

	ensureCoachData(data)
	return self:BuildEquippedCoachPayload(data)
end

--|| Knit Lifecycle ||--
function CoachesService:KnitInit()
	DataCacheService = Knit.GetService("DataCacheService")
	DataService = Knit.GetService("DataService")
	-- FightService = Knit.GetService("FightService")

	self.Template = DataCacheService:GetFile("Template")
end

function CoachesService:KnitStart()
	local function playerAdded(player: Player)
		task.spawn(function()
			while player.Parent and not player:GetAttribute("DataLoaded") do
				task.wait()
			end

			if not player.Parent then
				return
			end

			local data = DataService:GetData(player)
			if data then
				ensureCoachData(data)
				self:BroadcastCoachState(player, data)
			end
		end)
	end

	-- FightService.OnFightStarted:Connect(function(player)
	-- 	local data = DataService:GetData(player)
	-- 	if data and data.Coaches.Current ~= 0 then
	-- 		self.CoachesToggled[player.UserId] = data.Coaches.Current

	-- 		self:Unequip(player)
	-- 	end
	-- end)

	-- FightService.OnFightEnded:Connect(function(player)
	-- 	local lastCoachId = self.CoachesToggled[player.UserId]

	-- 	if lastCoachId then
	-- 		self:Equip(player, lastCoachId)

	-- 		self.CoachesToggled[player.UserId] = nil
	-- 	end
	-- end)

	Players.PlayerRemoving:Connect(function(player)
		local lastCoachId = self.CoachesToggled[player.UserId]

		if lastCoachId then
			self:Equip(player, lastCoachId)

			self.CoachesToggled[player.UserId] = nil
		end
	end)

	Players.PlayerAdded:Connect(playerAdded)

	for _, player in ipairs(Players:GetPlayers()) do
		playerAdded(player)
	end

	print("[COACHES SERVICE] Service loaded successfully.")
end

return CoachesService
