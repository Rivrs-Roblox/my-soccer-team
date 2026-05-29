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
	},
})

local activeTrainings = {}
local occupiedZones = {}

local registeredZonesByStatType = {
	Shoot = {},
	Pass = {},
	Dribble = {},
}

local TICK_INTERVAL = 1

local ANIMATIONS = {
	Shoot = nil,
	Pass = "rbxassetid://507770239",
	Dribble = nil,
}

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
	isAuto: boolean?
)
	service.Client.TrainingVisualStateChanged:FireAll(
		player,
		isTraining,
		statType,
		zoneKey,
		serverStartTime,
		isAuto or false
	)
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

local function GetAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	local newAnimator = Instance.new("Animator")
	newAnimator.Parent = humanoid
	return newAnimator
end

local function StopTrack(track: AnimationTrack?)
	if not track then
		return
	end

	pcall(function()
		track:Stop(0.1)
	end)

	pcall(function()
		track:Destroy()
	end)
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

	local animTrack = nil
	local animationId = ANIMATIONS[normalizedStatType]

	if animationId then
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId

		animTrack = GetAnimator(humanoid):LoadAnimation(animation)
		animTrack.Looped = true
		animTrack:Play()

		animation:Destroy()
	end

	local session = {
		Thread = nil,
		Prompt = prompt,
		Zone = zone,
		ZoneKey = zoneKey,
		RootPart = rootPart,
		AnimTrack = animTrack,
		StatType = normalizedStatType,
		AreaId = areaId,
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
		session.IsAuto
	)

	session.Thread = task.spawn(function()
		while activeTrainings[player] == session do
			task.wait(TICK_INTERVAL)

			local ok, err = pcall(function()
				PlayerStatsService:AddStat(player, normalizedStatType, areaId)
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

	if data.AnimTrack then
		StopTrack(data.AnimTrack)
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

	return self:StartTraining(player, zoneData.Prompt, zoneData.Zone, normalizedStatType, true)
end

function TrainingService.Client:RequestStopTraining(player: Player)
	local service = Knit.GetService("TrainingService")
	service:StopTraining(player, "ClientRequest")
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

	local allTypes = { "Shoot", "Pass", "Dribble" }
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
