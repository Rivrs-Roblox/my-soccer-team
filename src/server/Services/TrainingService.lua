--[=[
	Owner: Shakthi
	Version: v0.1.0
	Notes:
	- manual training flow tetap dipakai
	- auto training tetap wrapper aman
	- occupied logic tetap dipakai
	- billboard logic tidak disentuh
	- visual aktif via broadcast state ke client runtime
	- [v0.1.0] RegisterTrainingZones & RegisterZone kini support Model zone (Dribble)
	- [v0.1.0] StartTraining support zona Model via GetPivot()
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TrainingTypes = require(ReplicatedStorage.Shared.Helpers.Training.TrainingTypes)
local ZoneUtils = require(ReplicatedStorage.Shared.Helpers.Training.ZoneUtils)

local PlayerStatsService = nil
local DataService = nil
local TeleportService = nil

local TrainingService = Knit.CreateService({
	Name = "TrainingService",
	Client = {
		TrainingFeedback = Knit.CreateSignal(),
		TrainingSessionChanged = Knit.CreateSignal(),
		TrainingVisualStateChanged = Knit.CreateSignal(),
		TrainingRestingStateChanged = Knit.CreateSignal(),
		TrainingLevelChanged = Knit.CreateSignal(),
		TrainingTempStaminaChanged = Knit.CreateSignal(),
	},
})

local activeTrainings = {}
local occupiedZones = {}
local playerStaminaTracking = {}

local registeredZonesByStatType = {
	Shoot = {},
	Pass = {},
	Dribble = {},
	Stamina = {},
}

local TICK_INTERVAL = 1

local TRAINING_ZONE_CONFIGS = {
	Shoot = {
		FolderName = "ShootZone",
		Pattern = "^ShootZone%d+$",
	},
	Pass = {
		FolderName = "PassZone",
		Pattern = "^PassZone%d+$",
	},
	Dribble = {
		FolderName = "DribbleZone",
		Pattern = "^DribbleZone%d+$",
	},
	Stamina = {
		FolderName = "StaminaZone",
		Pattern = "^StaminaZone%d+$",
	},
}

local function GetZoneCFrame(zone: Instance): CFrame
	if zone:IsA("Model") then
		return zone:GetPivot()
	elseif zone:IsA("BasePart") then
		return zone.CFrame
	end

	return CFrame.new()
end

local function SendTrainingFeedback(service, player: Player, code: string, message: string)
	service.Client.TrainingFeedback:Fire(player, code, message)
end

local function SendTrainingSessionChanged(
	service,
	player: Player,
	isTraining: boolean,
	statType: string?,
	zoneKey: string?
)
	service.Client.TrainingSessionChanged:Fire(player, isTraining, statType, zoneKey)
end

local function SendTrainingVisualStateChanged(
	service,
	player: Player,
	isTraining: boolean,
	statType: string?,
	zoneKey: string?,
	serverStartTime: number?,
	isAuto: boolean?,
	level: number?
)
	service.Client.TrainingVisualStateChanged:FireAll(
		player,
		isTraining,
		statType,
		zoneKey,
		serverStartTime,
		isAuto or false,
		level
	)
end

local function SendTrainingRestingStateChanged(service, player: Player, isResting: boolean)
	service.Client.TrainingRestingStateChanged:Fire(player, isResting)
end

local function SendTrainingLevelChanged(service, player: Player, level: number)
	service.Client.TrainingLevelChanged:FireAll(player, level)
end

local function GetZoneKey(zone: Instance): string
	return zone:GetFullName()
end

local function GetCurrentAreaId(player: Player): string
	local playerData = DataService:GetData(player)
	if not playerData then
		return "Area01"
	end

	if playerData.Areas and playerData.Areas.Current then
		return playerData.Areas.Current
	end

	if playerData.Area then
		return playerData.Area
	end

	return "Area01"
end

function TrainingService:IsPlayerTraining(player: Player): boolean
	return activeTrainings[player] ~= nil
end

function TrainingService:IsZoneOccupied(zone: Instance, requester: Player?): boolean
	local zoneKey = GetZoneKey(zone)
	local occupant = occupiedZones[zoneKey]

	if occupant == nil then
		return false
	end

	if requester and occupant == requester then
		return false
	end

	return true
end

function TrainingService:GetZoneOccupant(zone: Instance): Player?
	return occupiedZones[GetZoneKey(zone)]
end

function TrainingService:FindAvailableZone(statType: string)
	local normalizedStatType = TrainingTypes.Normalize(statType)
	if not normalizedStatType then
		return nil
	end

	local registeredZones = registeredZonesByStatType[normalizedStatType]
	if not registeredZones or #registeredZones == 0 then
		return nil
	end

	local availableZones = {}

	for _, zoneData in ipairs(registeredZones) do
		if zoneData.Zone and zoneData.Zone.Parent and not self:IsZoneOccupied(zoneData.Zone) then
			table.insert(availableZones, zoneData)
		end
	end

	if #availableZones == 0 then
		return nil
	end

	return availableZones[math.random(1, #availableZones)]
end

function TrainingService:StartTraining(
	player: Player,
	prompt: ProximityPrompt,
	zone: Instance,
	statType: string,
	isAuto: boolean?
)
	local MatchService = nil
	pcall(function()
		MatchService = Knit.GetService("MatchService")
	end)

	if MatchService then
		if MatchService.IsPlayerInMatch and MatchService:IsPlayerInMatch(player) then
			SendTrainingFeedback(self, player, "InMatch", "Cannot start training while in a match.")
			return false
		end
		if MatchService.IsPlayerTransitioning and MatchService:IsPlayerTransitioning(player) then
			SendTrainingFeedback(self, player, "Transitioning", "Cannot start training during match transition.")
			return false
		end
	end

	local TournamentService = nil
	pcall(function()
		TournamentService = Knit.GetService("TournamentService")
	end)

	if TournamentService then
		if TournamentService.IsPendingStart and TournamentService:IsPendingStart(player) then
			SendTrainingFeedback(
				self,
				player,
				"PendingMatch",
				"Cannot start training while tournament preview is active."
			)
			return false
		end
	end

	local normalizedStatType = TrainingTypes.Normalize(statType)
	if not normalizedStatType then
		SendTrainingFeedback(self, player, "InvalidStatType", "Invalid training type.")
		return false
	end

	if self:IsPlayerTraining(player) then
		SendTrainingFeedback(self, player, "AlreadyTraining", "You are already training.")
		return false
	end

	if self:IsZoneOccupied(zone, player) then
		local occupant = self:GetZoneOccupant(zone)
		local occupantName = occupant and occupant.Name or "Another player"
		SendTrainingFeedback(self, player, "Occupied", occupantName .. " is using the equipment.")
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		SendTrainingFeedback(self, player, "InvalidCharacter", "Character is not ready.")
		return false
	end

	local zoneKey = GetZoneKey(zone)
	local areaId = GetCurrentAreaId(player)

	occupiedZones[zoneKey] = player

	if normalizedStatType == "Shoot" then
		rootPart.CFrame = ZoneUtils.GetShootStandCFrame(zone)
	elseif normalizedStatType == "Dribble" then
		local startPoint = zone:FindFirstChild("StartPoint", true)
		if startPoint and startPoint:IsA("BasePart") then
			rootPart.CFrame = startPoint.CFrame * CFrame.new(0, 3, 0)
		else
			rootPart.CFrame = GetZoneCFrame(zone) * CFrame.new(0, 3, 0)
		end
	else
		rootPart.CFrame = GetZoneCFrame(zone) * CFrame.new(0, 3, 0)
	end

	rootPart.Anchored = true

	local playerStats = PlayerStatsService:GetStats(player)
	local maxStamina = playerStats.Stamina or 100

	-- Calculate off-training regeneration
	local tracker = playerStaminaTracking[player]
	if not tracker then
		tracker = { Value = maxStamina, Max = maxStamina, LastUpdate = os.time() }
		playerStaminaTracking[player] = tracker
	else
		-- Scale proportionally if max stamina changed
		if tracker.Max and tracker.Max > 0 and tracker.Max ~= maxStamina then
			local ratio = tracker.Value / tracker.Max
			tracker.Value = ratio * maxStamina
			tracker.Max = maxStamina
		elseif not tracker.Max then
			tracker.Max = maxStamina
		end

		local timeElapsed = os.time() - tracker.LastUpdate
		if timeElapsed > 0 then
			local regenAmount = timeElapsed * (maxStamina * 0.15)
			tracker.Value = math.clamp(tracker.Value + regenAmount, 0, maxStamina)
			tracker.LastUpdate = os.time()
		end
	end

	local session = {
		Thread = nil,
		Prompt = prompt,
		Zone = zone,
		ZoneKey = zoneKey,
		RootPart = rootPart,

		StatType = normalizedStatType,
		AreaId = areaId,
		Level = 1,
		TempStamina = tracker.Value,
		MaxStamina = maxStamina,
		IsResting = false,
		Character = character,
		IsAuto = isAuto or false,
	}

	session.ServerStartTime = workspace:GetServerTimeNow()

	activeTrainings[player] = session
	SendTrainingSessionChanged(self, player, true, normalizedStatType, zoneKey)
	SendTrainingVisualStateChanged(
		self,
		player,
		true,
		normalizedStatType,
		zoneKey,
		session.ServerStartTime,
		session.IsAuto,
		session.Level
	)
	self.Client.TrainingTempStaminaChanged:Fire(player, session.TempStamina, maxStamina)

	session.Thread = task.spawn(function()
		while activeTrainings[player] == session do
			task.wait(TICK_INTERVAL)

			local ok, err = pcall(function()
				local currentStats = PlayerStatsService:GetStats(player)
				local currentMaxStamina = currentStats.Stamina or 100
				
				-- Update MaxStamina, but only scale TempStamina if resting
				if session.IsResting then
					if session.MaxStamina and session.MaxStamina > 0 and session.MaxStamina ~= currentMaxStamina then
						local ratio = session.TempStamina / session.MaxStamina
						session.TempStamina = ratio * currentMaxStamina
					end
				end
				session.MaxStamina = currentMaxStamina

				if session.IsResting then
					-- Regenerate 15% of max stamina
					local regenAmount = currentMaxStamina * 0.15
					session.TempStamina += regenAmount

					if session.TempStamina >= currentMaxStamina then
						session.TempStamina = currentMaxStamina
						session.IsResting = false
						SendTrainingRestingStateChanged(self, player, false)
					end
					self.Client.TrainingTempStaminaChanged:Fire(player, session.TempStamina, currentMaxStamina)
				else
					local cost = PlayerStatsService:GetStaminaCostPerTick(player, areaId, normalizedStatType, session.Level) or 0
					if session.TempStamina >= cost then
						session.TempStamina -= cost
						PlayerStatsService:AddStat(player, normalizedStatType, areaId, session.Level)
						self.Client.TrainingTempStaminaChanged:Fire(player, session.TempStamina, currentMaxStamina)
					else
						session.IsResting = true
						SendTrainingRestingStateChanged(self, player, true)
					end
				end
				
				-- Update tracking
				if playerStaminaTracking[player] then
					playerStaminaTracking[player].Value = session.TempStamina
					playerStaminaTracking[player].Max = session.MaxStamina
					playerStaminaTracking[player].LastUpdate = os.time()
				end
			end)

			if not ok then
				warn("[TrainingService] Tick AddStat failed for", player.Name, err)
			end
		end
	end)

	return true
end

function TrainingService:StopTraining(player: Player, reason: string?)
	local data = activeTrainings[player]
	if not data then
		return
	end

	activeTrainings[player] = nil

	if data.Thread then
		task.cancel(data.Thread)
	end

	if data.RootPart and data.RootPart.Parent then
		data.RootPart.Anchored = false
	end

	if data.ZoneKey then
		occupiedZones[data.ZoneKey] = nil
	end

	SendTrainingSessionChanged(self, player, false, data.StatType, data.ZoneKey)
	SendTrainingVisualStateChanged(self, player, false, data.StatType, data.ZoneKey, nil)
end

function TrainingService:RequestAutoTraining(player: Player, statType: string)
	local normalizedStatType = TrainingTypes.Normalize(statType)
	if not normalizedStatType then
		SendTrainingFeedback(self, player, "InvalidStatType", "Invalid training type.")
		return false
	end

	local currentSession = activeTrainings[player]

	if currentSession and currentSession.StatType == normalizedStatType then
		SendTrainingFeedback(
			self,
			player,
			"AlreadyTraining",
			string.format("You are already training %s.", normalizedStatType)
		)
		return false
	end

	if currentSession then
		self:StopTraining(player, "AutoSwitch")
	end

	local zoneData = self:FindAvailableZone(normalizedStatType)
	if not zoneData then
		SendTrainingFeedback(
			self,
			player,
			"NoAvailableSlot",
			string.format("All %s slots are currently full.", normalizedStatType)
		)
		return false
	end

	local success = self:StartTraining(player, zoneData.Prompt, zoneData.Zone, normalizedStatType, true)
	if success then
		for level = 3, 1, -1 do
			local levelSuccess = self:SetTrainingLevel(player, level)
			if levelSuccess then
				break
			end
		end
	end

	return success
end

function TrainingService.Client:RequestStopTraining(player: Player)
	local service = Knit.GetService("TrainingService")
	service:StopTraining(player, "ClientRequest")
end

function TrainingService:SetTrainingLevel(player: Player, level: number)
	local session = activeTrainings[player]
	if session then
		if type(level) == "number" and level >= 1 and level <= 3 then
			local cost = PlayerStatsService:GetStaminaCostPerTick(player, session.AreaId, session.StatType, level) or 0
			local currentStats = PlayerStatsService:GetStats(player)
			local maxStamina = currentStats.Stamina or 100

			if maxStamina < cost then
				return false, "Not enough stamina for this level!"
			end

			session.Level = level
			SendTrainingLevelChanged(self, player, level)
			return true, nil
		end
	end
	return false, "Invalid state or level"
end

function TrainingService.Client:RequestSetTrainingLevel(player: Player, level: number)
	local service = Knit.GetService("TrainingService")
	return service:SetTrainingLevel(player, level)
end

function TrainingService.Client:RequestAutoTraining(player: Player, statType: string)
	local service = Knit.GetService("TrainingService")
	return service:RequestAutoTraining(player, statType)
end

function TrainingService:FindFallbackTrainingZone(preferredStatType: string)
	local normalizedStatType = TrainingTypes.Normalize(preferredStatType)
	if normalizedStatType then
		local zoneData = self:FindAvailableZone(normalizedStatType)
		if zoneData then
			return zoneData, normalizedStatType
		end
	end

	local allTypes = { "Shoot", "Pass", "Dribble", "Stamina" }
	for _, statType in ipairs(allTypes) do
		if statType ~= normalizedStatType then
			local zoneData = self:FindAvailableZone(statType)
			if zoneData then
				return zoneData, statType
			end
		end
	end

	return nil
end

function TrainingService:HandlePlayerAdded(player: Player)
	local joinData = player:GetJoinData()
	if not joinData or not joinData.TeleportData then
		return
	end

	local teleportData = joinData.TeleportData
	if not teleportData.isAutoTraining then
		return
	end

	local preferredStat = teleportData.autoTrainType
	if not preferredStat then
		return
	end

	-- Wait for character to load
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not rootPart then
		warn("[TrainingService] Character rootPart not ready for auto-rejoin training.")
		return
	end

	-- Wait brief moment for streaming/loading stability
	task.wait(1)

	-- Try to start training
	local zoneData, finalStatType = self:FindFallbackTrainingZone(preferredStat)
	if zoneData then
		print(
			("[TrainingService] Auto-resuming training for %s in %s (requested: %s)"):format(
				player.Name,
				finalStatType,
				preferredStat
			)
		)
		self:StartTraining(player, zoneData.Prompt, zoneData.Zone, finalStatType, true)
	else
		warn("[TrainingService] No available slots found to auto-resume training for " .. player.Name)
	end
end

function TrainingService:RegisterZone(zone: Instance, statType: string)
	local prompt = zone:FindFirstChildWhichIsA("ProximityPrompt") or zone:FindFirstChild("ProximityPrompt", true)

	if not prompt or not prompt:IsA("ProximityPrompt") then
		warn("[TrainingService] Missing ProximityPrompt on", zone:GetFullName())
		return
	end

	local normalizedStatType = TrainingTypes.Normalize(statType)
	if not normalizedStatType then
		warn("[TrainingService] Invalid statType on zone register:", zone:GetFullName(), statType)
		return
	end

	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true

	table.insert(registeredZonesByStatType[normalizedStatType], {
		Zone = zone,
		Prompt = prompt,
		StatType = normalizedStatType,
	})

	prompt.Triggered:Connect(function(player)
		self:StartTraining(player, prompt, zone, normalizedStatType)
	end)
end

function TrainingService:RegisterTrainingZones()
	local map = workspace:FindFirstChild("Map")
	if not map then
		warn("[TrainingService] Map not found")
		return
	end

	local trainingAreas = map:FindFirstChild("TrainingAreas")
	if not trainingAreas then
		warn("[TrainingService] TrainingAreas not found")
		return
	end

	for statType in pairs(registeredZonesByStatType) do
		registeredZonesByStatType[statType] = {}
	end

	for statType, config in pairs(TRAINING_ZONE_CONFIGS) do
		local statFolder = trainingAreas:FindFirstChild(config.FolderName)
		if not statFolder then
			continue
		end

		if not (statFolder:IsA("Folder") or statFolder:IsA("Model")) then
			continue
		end

		for _, child in ipairs(statFolder:GetChildren()) do
			local nameMatch = string.match(child.Name, config.Pattern)
			if not nameMatch then
				continue
			end

			if child:IsA("BasePart") or child:IsA("Model") then
				self:RegisterZone(child, statType)
			end
		end
	end
end

function TrainingService:KnitInit()
	PlayerStatsService = Knit.GetService("PlayerStatsService")
	DataService = Knit.GetService("DataService")
	TeleportService = Knit.GetService("TeleportService")
	
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		playerStaminaTracking[player] = nil
	end)
end

function TrainingService:KnitStart()
	self:RegisterTrainingZones()

	TeleportService.PlayerTeleporting:Connect(function(player: Player)
		if self:IsPlayerTraining(player) then
			self:StopTraining(player, "Teleport")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:StopTraining(player, "PlayerRemoving")
	end)

	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerAdded(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:HandlePlayerAdded(player)
		end)
	end
end

return TrainingService
