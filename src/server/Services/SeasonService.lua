--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local DataService = nil
local DataCacheService = nil
local BoostService = nil
local QuestDefinitions = nil

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local GetTableLength = require(Helpers.GetTableLength)

-- SeasonService
local SeasonService = Knit.CreateService({
	Name = "SeasonService",

	Client = {
		QuestsUpdated = Knit.CreateSignal(),
		SeasonUpdated = Knit.CreateSignal(),
		ClaimedRewardsUpdate = Knit.CreateSignal(),
		RemainingDayTimeUpdated = Knit.CreateSignal(),
		RemainingWeekTimeUpdated = Knit.CreateSignal(),
		LevelUpdated = Knit.CreateSignal(),
		ExpUpdated = Knit.CreateSignal(),
		PremiumUpdated = Knit.CreateSignal(),
		QuestCompleted = Knit.CreateSignal(),
		QuestProgressed = Knit.CreateSignal(),
	},

	Template = {},
	SeasonTemplate = {},
})

--|| Local Functions||--

local function getUtcNow()
	return os.time(os.date("!*t"))
end

local function isDST(utcTime)
	local t = os.date("!*t", utcTime)
	return t.month >= 3 and t.month <= 10 -- asumsi kasar: Maret–Oktober = DST
end

local function getRemainingSecondsUntilNewWashingtonDay()
	local utcNow = os.time()
	local offsetHours = isDST(utcNow) and -7 or -8
	local washingtonNow = utcNow + (offsetHours * 3600)

	-- Time since midnight in that timezone
	local secondsSinceMidnight = washingtonNow % 86400
	return 86400 - secondsSinceMidnight
end

local function getRemainingSecondsUntilNewWashingtonWeek()
	local utcNow = os.time()
	local offsetHours = isDST(utcNow) and -7 or -8
	local washingtonNow = utcNow + (offsetHours * 3600)
	local t = os.date("!*t", washingtonNow)

	-- Reset happens on Monday 00:00 (Sunday becomes the end of the week)
	local daysUntilMonday = (8 - t.wday) % 7
	local secondsUntilMidnight = 86400 - (washingtonNow % 86400)

	return (daysUntilMonday * 86400) + secondsUntilMidnight
end

local function isNewWashingtonDay(lastTimestamp)
	if lastTimestamp == 0 then
		return true
	end
	local utcNow = getUtcNow()
	local offsetHours = isDST(utcNow) and -7 or -8
	local lastWashington = lastTimestamp + (offsetHours * 3600)
	local nowWashington = utcNow + (offsetHours * 3600)

	local lastDate = os.date("!*t", lastWashington)
	local nowDate = os.date("!*t", nowWashington)

	if not lastDate or not nowDate then
		return true
	end
	return nowDate.year ~= lastDate.year or nowDate.month ~= lastDate.month or nowDate.day ~= lastDate.day
end

local function isNewWashingtonWeek(lastTimestamp)
	if lastTimestamp == 0 then
		return true
	end
	local utcNow = getUtcNow()
	local offsetHours = isDST(utcNow) and -7 or -8

	local lastWashington = lastTimestamp + (offsetHours * 3600)
	local nowWashington = utcNow + (offsetHours * 3600)

	local lastDate = os.date("!*t", lastWashington)
	local nowDate = os.date("!*t", nowWashington)

	if not lastDate or not nowDate then
		return true
	end

	-- Hitung "awal minggu" sebagai hari Minggu
	local function getWeekStart(dayInfo)
		local t = os.time(dayInfo)
		local dayOffset = dayInfo.wday - 1 -- Sunday = 1
		local weekStartTime = t - (dayOffset * 86400)
		return os.date("!*t", weekStartTime)
	end

	local lastWeekStart = getWeekStart(lastDate)
	local nowWeekStart = getWeekStart(nowDate)

	if not lastWeekStart or not nowWeekStart then
		return true
	end

	return nowWeekStart.year ~= lastWeekStart.year
		or nowWeekStart.month ~= lastWeekStart.month
		or nowWeekStart.day ~= lastWeekStart.day
end

--|| Client Functions ||--
function SeasonService.Client:ClaimDailyQuest(player: Player, quest: string)
	return self.Server:ClaimDailyQuest(player, quest)
end

function SeasonService.Client:ClaimReward(player: Player, reward: number)
	return self.Server:ClaimReward(player, reward)
end

function SeasonService.Client:PremiumClaimReward(player: Player, reward: number)
	return self.Server:PremiumClaimReward(player, reward)
end

function SeasonService.Client:RequestSync(player: Player)
	return self.Server:UpdateSeason(player)
end

--|| Functions ||--
function SeasonService:QuestExists(quests, quest)
	for index, q in quests do
		if q.Title == quest.Title then
			return true
		end
	end
	print("false")
	return false
end

function SeasonService:GenerateDailyQuests(player: Player)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local New = {}
	local DailyQuestsTemplate = table.clone(self.Template.Season["Daily Quests"])

	for i = 1, 6 do
		if #DailyQuestsTemplate == 0 then
			break
		end

		local index = math.random(1, #DailyQuestsTemplate)
		local Quest = DailyQuestsTemplate[index]
		table.remove(DailyQuestsTemplate, index)

		New[`Quest {i}`] = {
			["Title"] = Quest.Title,
			["Description"] = Quest.Description,
			["Amount"] = Quest.Amount,
			["Current"] = 0,
			["Exp"] = Quest.Exp,
		}
	end

	return New
end

function SeasonService:GenerateWeeklyQuests(player: Player)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local New = {}
	local WeeklyQuestsTemplate = table.clone(self.Template.Season["Weekly Quests"])

	for i = 1, 6 do
		if #WeeklyQuestsTemplate == 0 then
			break
		end

		local index = math.random(1, #WeeklyQuestsTemplate)
		local Quest = WeeklyQuestsTemplate[index]
		table.remove(WeeklyQuestsTemplate, index)

		New[`Quest {i}`] = {
			["Title"] = Quest.Title,
			["Description"] = Quest.Description,
			["Amount"] = Quest.Amount,
			["Current"] = 0,
			["Exp"] = Quest.Exp,
		}
	end

	return New
end

function SeasonService:UpdateSeason(player: Player)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local Season = data.Season

	-- Full season reset if season number changed
	if Season.Season ~= self.Template.Season["Current Season"] then
		data.Season = table.clone(self.SeasonTemplate)
		data.Season.Season = self.Template.Season["Current Season"]
		data.Season.LastDailyReset = os.time()
		data.Season.LastWeeklyReset = os.time()
		data.Season.DailyQuests = self:GenerateDailyQuests(player)
		data.Season.WeeklyQuests = self:GenerateWeeklyQuests(player)
		-- Refresh Season reference after reset
		Season = data.Season
	else
		-- Migrate missing fields from SeasonTemplate for existing players
		for key, defaultValue in pairs(self.SeasonTemplate) do
			if Season[key] == nil then
				if type(defaultValue) == "table" then
					Season[key] = table.clone(defaultValue)
				else
					Season[key] = defaultValue
				end
			end
		end

		-- Validate existing quests against QuestDefinitions
		local dailyInvalid = false
		for _, quest in pairs(Season.DailyQuests or {}) do
			if not QuestDefinitions.DailyQuests[quest.Title] then
				dailyInvalid = true
				break
			end
		end

		local weeklyInvalid = false
		for _, quest in pairs(Season.WeeklyQuests or {}) do
			if not QuestDefinitions.WeeklyQuests[quest.Title] then
				weeklyInvalid = true
				break
			end
		end

		if dailyInvalid then
			print("[SEASON SERVICE] Invalid DailyQuests detected for", player.Name, "- Resetting.")
			Season.DailyQuests = self:GenerateDailyQuests(player)
			Season.LastDailyReset = os.time()
		elseif not next(Season.DailyQuests) then
			Season.DailyQuests = self:GenerateDailyQuests(player)
			Season.LastDailyReset = os.time()
		end

		if weeklyInvalid then
			print("[SEASON SERVICE] Invalid WeeklyQuests detected for", player.Name, "- Resetting.")
			Season.WeeklyQuests = self:GenerateWeeklyQuests(player)
			Season.LastWeeklyReset = os.time()
		elseif not next(Season.WeeklyQuests) then
			Season.WeeklyQuests = self:GenerateWeeklyQuests(player)
			Season.LastWeeklyReset = os.time()
		end
	end

	-- Count weekly quests for debug
	local wCount = 0
	for _ in pairs(Season.WeeklyQuests or {}) do
		wCount += 1
	end
	print(
		"[SEASON SERVICE] Firing QuestsUpdated - Daily count, Weekly count:",
		(function()
			local n = 0
			for _ in pairs(Season.DailyQuests or {}) do
				n += 1
			end
			return n
		end)(),
		wCount
	)

	-- Always sync quests and timers on join
	self.Client.QuestsUpdated:Fire(
		player,
		Season.DailyQuests or {},
		Season.WeeklyQuests or {},
		getRemainingSecondsUntilNewWashingtonDay(),
		getRemainingSecondsUntilNewWashingtonWeek()
	)

	return
end

function SeasonService:Increase(player: Player, type: string, value: number)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local Season = data.Season
	local expIncrease = false

	-- Proses Daily Quests
	for _, Quest in Season.DailyQuests do
		if Quest.Title == type and Quest.Current < Quest.Amount then
			Quest.Current = math.min(Quest.Current + value, Quest.Amount)

			self.Client.QuestProgressed:Fire(player, Quest.Title, Quest.Current)

			if Quest.Current >= Quest.Amount then
				Season.Exp += Quest.Exp
				self.Client.QuestCompleted:Fire(player, Quest.Exp)

				expIncrease = true
			end
		end
	end

	-- Proses Weekly Quests
	for _, Quest in Season.WeeklyQuests do
		if Quest.Title == type and Quest.Current < Quest.Amount then
			Quest.Current = math.min(Quest.Current + value, Quest.Amount)

			self.Client.QuestProgressed:Fire(player, Quest.Title, Quest.Current)

			if Quest.Current >= Quest.Amount then
				Season.Exp += Quest.Exp
				self.Client.QuestCompleted:Fire(player, Quest.Exp)

				expIncrease = true
			end
		end
	end

	if expIncrease then
		self.Client.ExpUpdated:Fire(player, Season.Exp)
	end

	if Season.Level < 30 then
		while true do
			local nextLevelExp = 0
			for i = 1, Season.Level + 1 do
				nextLevelExp += self.Template.SeasonPass[i]
			end

			if Season.Level < 30 and Season.Exp >= nextLevelExp then
				Season.Level += 1
				self.Client.LevelUpdated:Fire(player, Season.Level)
			else
				break
			end
		end

		if Season.Level == 30 then
			data.SeasonPassCompleted += 1
		end
	end
	return
end

function SeasonService:ClaimDailyQuest(player: Player, quest: string)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local Season = data.Season
	if Season.DailyQuests[quest].Current == Season.DailyQuests[quest].Amount then
		Season.DailyQuests[quest] = nil
		Season.Completed += 1

		self.Client.QuestsUpdated:Fire(player, Season.DailyQuests, Season.WeeklyQuests)

		return { text = self.Template.Messages.Notifications.Quest_Completed, type = "SUCCESS" }
	end

	return { text = self.Template.Messages.Notifications.Quest_Not_Completed, type = "ERROR" }
end

function SeasonService:ClaimReward(player: Player, reward: number)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local Season = data.Season
	-- print("[SeasonService] Claiming Reward: ", reward)
	-- print("[SeasonService] Data Season : ", data.Season)
	if not table.find(Season.Claimed, reward) then
		local Reward = self.Template.Season.Rewards[reward]
		-- print("[SeasonService] Reward: ", Reward)
		if Reward.Type == "Currency" then
			DataService:ChangeValue(player, Reward.Currency, Reward.Amount, true)
		elseif
			Reward.Type == "Boost"
			and table.find({ "x2_Money1_Boost", "x2_Money2_Boost", "x2_Wins_Boost" }, Reward.Boost)
		then
			for index, boost in data.Inventory.Boosts do
				if boost.Name == Reward.Boost then
					BoostService:AddBoost(player, index, Reward.Amount)
					break
				end
			end
		end

		table.insert(Season.Claimed, reward)

		self.Client.ClaimedRewardsUpdate:Fire(player, { free = Season.Claimed, premium = Season["Premium Claimed"] })

		return { text = self.Template.Messages.Notifications.Quest_Reward_Claimed, type = "SUCCESS" }
	end

	return { text = self.Template.Messages.Notifications.Quest_Reward_Not_Claimed, type = "ERROR" }
end

function SeasonService:PremiumClaimReward(player: Player, reward: number)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SEASON SERVICE] Player has no data: " .. player.Name)
	end

	local Season = data.Season

	if not Season.Premium then
		return { text = self.Template.Messages.Notifications.Quest_Reward_Not_Claimed, type = "ERROR" }
	end

	if not table.find(Season["Premium Claimed"], reward) then
		local Reward = self.Template.Season["Premium Rewards"][reward]
		if Reward.Type == "Currency" then
			DataService:ChangeValue(player, Reward.Currency, Reward.Amount, true)
		elseif
			Reward.Type == "Boost"
			and table.find({ "x2_Money1_Boost", "x2_Money2_Boost", "x2_Wins_Boost" }, Reward.Boost)
		then
			for index, boost in data.Inventory.Boosts do
				if boost.Name == Reward.Boost then
					BoostService:AddBoost(player, index, Reward.Amount)
					break
				end
			end
		end

		table.insert(Season["Premium Claimed"], reward)

		self.Client.ClaimedRewardsUpdate:Fire(player, { free = Season.Claimed, premium = Season["Premium Claimed"] })

		return { text = self.Template.Messages.Notifications.Quest_Reward_Claimed, type = "SUCCESS" }
	end

	return { text = self.Template.Messages.Notifications.Quest_Reward_Not_Claimed, type = "ERROR" }
end

function SeasonService:BroadcastRemainingDayTime()
	local remainingSeconds = getRemainingSecondsUntilNewWashingtonDay()

	self.Client.RemainingDayTimeUpdated:FireAll(remainingSeconds)
end

function SeasonService:BroadcastRemainingWeekTime()
	local remainingSeconds = getRemainingSecondsUntilNewWashingtonWeek()

	self.Client.RemainingWeekTimeUpdated:FireAll(remainingSeconds)
end

--|| Knit Lifecycle ||--
function SeasonService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	BoostService = Knit.GetService("BoostService")

	self.Template = DataCacheService:GetFile("Template")
	self.SeasonTemplate = DataCacheService:GetFile("SeasonTemplate")
	QuestDefinitions = DataCacheService:GetFile("QuestDefinitions")

	Players.PlayerAdded:Connect(function(player)
		self:UpdateSeason(player)

		-- Kirim remaining time saat player join
		local remainingSeconds = getRemainingSecondsUntilNewWashingtonDay()
		self.Client.RemainingDayTimeUpdated:Fire(player, remainingSeconds)

		local remainingWeek = getRemainingSecondsUntilNewWashingtonWeek()
		self.Client.RemainingWeekTimeUpdated:Fire(player, remainingWeek)

		print("[SEASON SERVICE] Service loaded successfully.")
	end)
end

function SeasonService:KnitStart()
	task.spawn(function()
		local lastMinute = -1
		local lastHour = -1

		while true do
			local remainingDay = getRemainingSecondsUntilNewWashingtonDay()
			local remainingWeek = getRemainingSecondsUntilNewWashingtonWeek()
			local currentMinute = math.floor(remainingDay / 60)
			local currentWeekMinute = math.floor(remainingWeek / 60)

			if currentMinute ~= lastMinute then
				lastMinute = currentMinute
				self:BroadcastRemainingDayTime()
			end

			if currentWeekMinute ~= lastHour then
				lastHour = currentWeekMinute
				self:BroadcastRemainingWeekTime()
			end

			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService:GetData(player)
				local season = data and data.Season

				local questChanged = false

				if season and season.DailyQuests and season.LastDailyReset then
					if isNewWashingtonDay(season.LastDailyReset) then
						season.DailyQuests = {}
						season.DailyQuests = self:GenerateDailyQuests(player)
						season.LastDailyReset = os.time()

						print("[SEASON SERVICE] Daily quests reset for", player.Name)
						questChanged = true
					end
				end

				if season and season.WeeklyQuests and season.LastWeeklyReset then
					if isNewWashingtonWeek(season.LastWeeklyReset) then
						season.WeeklyQuests = {}
						season.WeeklyQuests = self:GenerateWeeklyQuests(player)
						season.LastWeeklyReset = os.time()

						print("[SEASON SERVICE] Weekly quests reset for", player.Name)
						questChanged = true
					end
				end

				if questChanged then
					self.Client.QuestsUpdated:Fire(player, season.DailyQuests, season.WeeklyQuests)
				end
			end

			task.wait(1)
		end
	end)
end

return SeasonService
