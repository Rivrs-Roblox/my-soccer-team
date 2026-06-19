--!strict
-- TournamentChampionView.lua
-- Visual-only champion ceremony. The server owns final result, rewards, and lobby return.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ChampionCeremonyCinematicDirector = require(script.Parent.ChampionCeremonyCinematicDirector)
local ChampionCeremonyVfxConfig = require(script.Parent.ChampionCeremonyVfxConfig)
local UIJuice = require(script.Parent.Parent.Parent.Helpers.UIJuice)

local LocalPlayer = Players.LocalPlayer

local TournamentChampionView = {}
TournamentChampionView.__index = TournamentChampionView

local GUI_NAME = "TournamentChampionGui"
local DISPLAY_ORDER = 430
local CELEBRATION_ANIMATION_ID = "rbxassetid://117933581573844"
local RUNTIME_FOLDER_NAME = "ChampionRuntimeClones"

local function FindChildPath(root: Instance?, path: { string }): Instance?
	local current = root
	for _, name in ipairs(path) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function IsLikelyChampionStage(instance: Instance?): boolean
	if not instance then
		return false
	end

	if instance.Name ~= "Champion" and instance.Name ~= "ChampionStage" and instance.Name ~= "TournamentChampionStage" then
		return false
	end

	return instance:FindFirstChild("MainPlayer", true) ~= nil
		or instance:FindFirstChild("Player1", true) ~= nil
		or instance:FindFirstChild("Coach", true) ~= nil
end

local function FindChampionTemplate(): Instance?
	local exactPaths = {
		{ "Map", "BattleZone", "BattleField", "Champion" },
		{ "Assets", "Tournament", "Champion" },
		{ "Assets", "Champion" },
		{ "Tournament", "Champion" },
		{ "Champion" },
	}

	for _, path in ipairs(exactPaths) do
		local candidate = FindChildPath(ReplicatedStorage, path)
		if IsLikelyChampionStage(candidate) then
			return candidate
		end
	end

	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		if IsLikelyChampionStage(descendant) then
			return descendant
		end
	end

	return nil
end

local function SetVisualHidden(root: Instance?, hidden: boolean)
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = hidden and 1 or 0
			if hidden then
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = hidden and 1 or 0
		elseif descendant:IsA("BillboardGui")
			or descendant:IsA("SurfaceGui")
			or descendant:IsA("ParticleEmitter")
			or descendant:IsA("Beam")
			or descendant:IsA("Trail")
			or descendant:IsA("PointLight")
			or descendant:IsA("SpotLight")
			or descendant:IsA("SurfaceLight")
			or descendant:IsA("Highlight")
		then
			if hidden then
				local alreadyHidden = descendant:GetAttribute("MatchOwnerEffectHidden") == true
				if not alreadyHidden then
					local ok, enabled = pcall(function()
						return (descendant :: any).Enabled
					end)

					local isEnabled = ok and enabled == true or false
					pcall(function()
						descendant:SetAttribute("MatchOwnerEffectCachedEnabled", isEnabled)
						descendant:SetAttribute("MatchOwnerEffectHidden", true)
					end)
				end

				pcall(function()
					(descendant :: any).Enabled = false
				end)
			else
				local wasHidden = descendant:GetAttribute("MatchOwnerEffectHidden") == true
				if wasHidden then
					local cachedEnabled = descendant:GetAttribute("MatchOwnerEffectCachedEnabled") == true
					pcall(function()
						(descendant :: any).Enabled = cachedEnabled
					end)
				end

				pcall(function()
					descendant:SetAttribute("MatchOwnerEffectCachedEnabled", nil)
					descendant:SetAttribute("MatchOwnerEffectHidden", nil)
				end)
			end
		end
	end

	if root:IsA("BasePart") then
		root.LocalTransparencyModifier = hidden and 1 or 0
	end
end

local function EnsureWorkspaceChampionRoot(): Instance?
	local battleField = FindChildPath(Workspace, { "Map", "BattleZone", "BattleField" })
	local parent = battleField or Workspace
	local existing = battleField and battleField:FindFirstChild("Champion") or Workspace:FindFirstChild("Champion")
	if existing then
		return existing
	end

	local template = FindChampionTemplate()
	if not template then
		return nil
	end

	local oldArchivable = template.Archivable
	template.Archivable = true
	local clone = template:Clone()
	template.Archivable = oldArchivable

	clone.Name = "Champion"
	clone.Parent = parent
	clone:SetAttribute("RuntimeChampionStage", true)
	SetVisualHidden(clone, true)

	return clone
end

local function GetChampionRoot(allowCreate: boolean?): Instance?
	local direct = FindChildPath(Workspace, { "Map", "BattleZone", "BattleField", "Champion" })
	if direct then
		return direct
	end

	local battleField = FindChildPath(Workspace, { "Map", "BattleZone", "BattleField" })
	if battleField then
		local nested = battleField:FindFirstChild("Champion", true)
		if nested then
			return nested
		end
	end

	local workspaceDirect = Workspace:FindFirstChild("Champion")
	if workspaceDirect then
		return workspaceDirect
	end

	if allowCreate == true then
		return EnsureWorkspaceChampionRoot()
	end

	return nil
end

local function GetPivot(instance: Instance?): CFrame?
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	local model = instance:FindFirstChildWhichIsA("Model")
	if model then
		return model:GetPivot()
	end

	local part = instance:FindFirstChildWhichIsA("BasePart", true)
	if part then
		return part.CFrame
	end

	return nil
end


local function IsTrophyVisual(instance: Instance): boolean
	local lowerName = string.lower(instance.Name)
	if
		string.find(lowerName, "trophy", 1, true)
		or string.find(lowerName, "tropy", 1, true)
		or string.find(lowerName, "trofi", 1, true)
	then
		return true
	end

	local ancestor = instance.Parent
	while ancestor do
		local lowerAncestorName = string.lower(ancestor.Name)
		if
			string.find(lowerAncestorName, "trophy", 1, true)
			or string.find(lowerAncestorName, "tropy", 1, true)
			or string.find(lowerAncestorName, "trofi", 1, true)
		then
			return true
		end
		ancestor = ancestor.Parent
	end

	return false
end

local function IsHelperPart(part: BasePart): boolean
	local lowerName = string.lower(part.Name)
	return part.Name == "HumanoidRootPart"
		or string.find(lowerName, "hitbox", 1, true) ~= nil
		or string.find(lowerName, "collider", 1, true) ~= nil
		or string.find(lowerName, "collision", 1, true) ~= nil
		or string.find(lowerName, "trigger", 1, true) ~= nil
		or string.find(lowerName, "target", 1, true) ~= nil
		or string.find(lowerName, "marker", 1, true) ~= nil
		or string.find(lowerName, "helper", 1, true) ~= nil
		or string.find(lowerName, "debug", 1, true) ~= nil
end

local function HideRealTrophy(model: Model?)
	if not model then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		local isTrophy = IsTrophyVisual(descendant)
		if isTrophy and descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
			descendant.Transparency = 1
		elseif isTrophy and (descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail")) then
			descendant.Enabled = false
		end
	end
end
--
local function SetTrophyVisible(root: Instance?, visible: boolean)
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = visible and 0 or 1
			descendant.LocalTransparencyModifier = visible and 0 or 1
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = visible and 0 or 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") then
			descendant.Enabled = visible
		end
	end

	if root:IsA("BasePart") then
		root.Transparency = visible and 0 or 1
		root.LocalTransparencyModifier = visible and 0 or 1
	end
end

local function RestoreCloneCharacterVisuals(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if IsTrophyVisual(descendant) then
			continue
		end

		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.LocalTransparencyModifier = IsHelperPart(descendant) and 1 or 0
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 0
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			descendant.Enabled = true
		end
	end
end

local function PrepareClone(model: Model): Model
	local oldArchivable = model.Archivable
	model.Archivable = true
	local clone = model:Clone()
	model.Archivable = oldArchivable

	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.LocalTransparencyModifier = 0
			if IsTrophyVisual(descendant) then
				descendant.Transparency = 1
				descendant.LocalTransparencyModifier = 1
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			if not IsTrophyVisual(descendant) then
				descendant.Transparency = 0
			end
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			if not IsTrophyVisual(descendant) then
				descendant.Enabled = true
			end
		end
	end

	RestoreCloneCharacterVisuals(clone)

	local root = clone:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = true
	end

	return clone
end

local function ResolveSlot(championRoot: Instance, slotName: string): Instance?
	if slotName == "MainPlayer" then
		return FindChildPath(championRoot, { "MainPlayer", "Player" }) or championRoot:FindFirstChild("MainPlayer")
	end

	return championRoot:FindFirstChild(slotName)
end

local function ResolveCelebrationAnimation(slot: Instance?): string
	local animation = slot and slot:FindFirstChild("Celebration", true)
	if animation and animation:IsA("Animation") and animation.AnimationId ~= "" then
		return animation.AnimationId
	end

	return CELEBRATION_ANIMATION_ID
end

local function PlayCelebration(model: Model, animationId: string, tracks: { AnimationTrack })
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.12, 1, 1)
		table.insert(tracks, track)
	end
end

local function WeldTrophyToHand(trophy: Instance, hand: BasePart)
	local parts = {}
	if trophy:IsA("BasePart") then
		table.insert(parts, trophy)
	end

	for _, descendant in ipairs(trophy:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	for _, part in ipairs(parts) do
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
	end
end

local function AttachTrophy(template: Instance?, templateHand: BasePart?, clone: Model)
	if not template or not templateHand then
		return
	end

	local hand = clone:FindFirstChild("RightHand", true)
	if not (hand and hand:IsA("BasePart")) then
		return
	end

	local trophy = template:Clone()
	trophy.Name = "ChampionTrophy"
	trophy.Parent = hand

	if template:IsA("Model") then
		local relative = templateHand.CFrame:ToObjectSpace(template:GetPivot())
		trophy:PivotTo(hand.CFrame * relative)
	elseif template:IsA("BasePart") and trophy:IsA("BasePart") then
		local relative = templateHand.CFrame:ToObjectSpace(template.CFrame)
		trophy.CFrame = hand.CFrame * relative
	else
		local part = trophy:FindFirstChildWhichIsA("BasePart", true)
		if part then
			part.CFrame = hand.CFrame
		end
	end

	SetTrophyVisible(trophy, true)
	WeldTrophyToHand(trophy, hand)
end

local function EnsureGui(): (ScreenGui, TextLabel, TextButton)
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild(GUI_NAME)

	if not (gui and gui:IsA("ScreenGui")) then
		gui = Instance.new("ScreenGui")
		gui.Name = GUI_NAME
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = DISPLAY_ORDER
		gui.Enabled = false
		gui.Parent = playerGui
	end

	local title = gui:FindFirstChild("TitleText")
	if not (title and title:IsA("TextLabel")) then
		title = Instance.new("TextLabel")
		title.Name = "TitleText"
		title.AnchorPoint = Vector2.new(0.5, 0.5)
		title.Position = UDim2.fromScale(0.5, 0.16)
		title.Size = UDim2.fromScale(0.8, 0.12)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 232, 96)
		title.TextStrokeTransparency = 0.25
		title.Text = "CHAMPIONS!"
		title.ZIndex = 20
		title.Parent = gui
	end

	local skip = gui:FindFirstChild("SkipButton")
	if not (skip and skip:IsA("TextButton")) then
		skip = Instance.new("TextButton")
		skip.Name = "SkipButton"
		skip.AnchorPoint = Vector2.new(1, 1)
		skip.Position = UDim2.new(1, -24, 1, -24)
		skip.Size = UDim2.fromOffset(140, 42)
		skip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		skip.BackgroundTransparency = 0.5
		skip.BorderSizePixel = 0
		skip.Font = Enum.Font.GothamMedium
		skip.Text = "Skip >>"
		skip.TextSize = 18
		skip.TextColor3 = Color3.fromRGB(255, 255, 255)
		skip.ZIndex = 30
		skip.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = skip
	end

	return gui :: ScreenGui, title :: TextLabel, skip :: TextButton
end

function TournamentChampionView.new()
	local self = setmetatable({}, TournamentChampionView)
	self._active = false
	self._clones = {}
	self._hiddenOriginals = {}
	self._tracks = {}
	self._connections = {}
	self._skipRequested = false
	self._cameraState = nil
	self._hiddenBalls = {}
	self._cinematic = ChampionCeremonyCinematicDirector.new()

	task.defer(function()
		HideRealTrophy(LocalPlayer.Character)
		local stage = GetChampionRoot(false)
		if stage then
			SetVisualHidden(stage, true)
		end
	end)

	table.insert(self._connections, LocalPlayer.CharacterAdded:Connect(function(character)
		task.defer(function()
			HideRealTrophy(character)
		end)
	end))

	return self
end

function TournamentChampionView:_clearClones()
	for _, track in ipairs(self._tracks) do
		pcall(function()
			track:Stop(0.08)
			track:Destroy()
		end)
	end
	table.clear(self._tracks)

	for _, clone in ipairs(self._clones) do
		if clone and clone.Parent then
			clone:Destroy()
		end
	end
	table.clear(self._clones)
end

function TournamentChampionView:_restoreOriginals()
	for model in pairs(self._hiddenOriginals) do
		if model and model.Parent then
			SetVisualHidden(model, false)
			HideRealTrophy(model)
		end
	end
	table.clear(self._hiddenOriginals)
end

function TournamentChampionView:_hideOriginal(model: Model?)
	if not model or self._hiddenOriginals[model] then
		return
	end

	self._hiddenOriginals[model] = true
	SetVisualHidden(model, true)
	HideRealTrophy(model)
end

function TournamentChampionView:_spawnClone(source: Model?, slot: Instance?, runtimeFolder: Instance, attachTrophy: boolean)
	if not source or not source.Parent or not slot then
		return
	end

	local pivot = GetPivot(slot)
	if not pivot then
		return
	end

	-- Clone before hiding the original. Otherwise face decals/textures inherit hidden state.
	local clone = PrepareClone(source)
	self:_hideOriginal(source)
	clone.Name = "Champion_" .. source.Name
	clone.Parent = runtimeFolder
	clone:PivotTo(pivot)
	table.insert(self._clones, clone)

	if attachTrophy then
		local template = slot:FindFirstChild("Trophy", true)
		local templateHand = slot:FindFirstChild("RightHand", true)
		if templateHand and not templateHand:IsA("BasePart") then
			templateHand = nil
		end
		AttachTrophy(template, templateHand :: BasePart?, clone)
	end

	PlayCelebration(clone, ResolveCelebrationAnimation(slot), self._tracks)
end

function TournamentChampionView:_captureCameraState()
	local camera = Workspace.CurrentCamera
	if not camera or self._cameraState then
		return
	end

	self._cameraState = {
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		CFrame = camera.CFrame,
		FieldOfView = camera.FieldOfView,
	}
end

function TournamentChampionView:_applyLeagueDecal(stage: Instance, payload: any)
	local areaId = type(payload) == "table" and payload.AreaId or "Area01"
	local logoAssetId = ChampionCeremonyVfxConfig.GetLeagueIcon(areaId)
	local leagueDecal = stage:FindFirstChild("LeagueImage", true)
	if leagueDecal and leagueDecal:IsA("Decal") and logoAssetId then
		leagueDecal.Texture = logoAssetId
		leagueDecal.Transparency = 0
	end
end

function TournamentChampionView:Show(payload, onSkip)
	self:Hide()
	self._active = true
	self._skipRequested = false

	HideRealTrophy(LocalPlayer.Character)

	-- Clean up and hide any leftover match balls or original arena balls
	self._hiddenBalls = {}
	local battleZone = Workspace:FindFirstChild("Map")
		and Workspace.Map:FindFirstChild("BattleZone")
	if battleZone then
		local runtimeFolder = battleZone:FindFirstChild("Runtime")
		if runtimeFolder then
			local localBall = runtimeFolder:FindFirstChild("LocalMatchBall")
			if localBall then
				pcall(function() localBall:Destroy() end)
			end
		end

		for _, descendant in ipairs(battleZone:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local loweredName = string.lower(descendant.Name)
				local parentName = descendant.Parent and string.lower(descendant.Parent.Name) or ""
				if loweredName == "football"
					or loweredName == "ball"
					or loweredName == "matchball"
					or parentName == "ballarea"
				then
					self._hiddenBalls[descendant] = descendant.Transparency
					descendant.Transparency = 1
					descendant.LocalTransparencyModifier = 1
				end
			end
		end
	end

	-- Clean up and hide any leftover match-specific presentation rigs/enemies in Workspace during the ceremony
	local playerProxy = Workspace:FindFirstChild("LocalMatchPlayerProxy", true)
	if playerProxy and playerProxy:IsA("Model") then
		self:_hideOriginal(playerProxy)
	end

	local runtimePresentation = Workspace:FindFirstChild("LocalMatchPresentationRuntime")
	if runtimePresentation then
		self:_hideOriginal(runtimePresentation)
	end

	local spawnedEnemies = Workspace:FindFirstChild("SpawnedEnemies", true)
	if spawnedEnemies then
		self:_hideOriginal(spawnedEnemies)
	end

	local stage = GetChampionRoot(true)
	if not stage then
		warn("[TournamentChampionView] Champion stage not found at Workspace.Map.BattleZone.BattleField.Champion")
		if type(onSkip) == "function" then
			onSkip(type(payload) == "table" and payload.SessionId or nil)
		end
		return
	end

	self:_captureCameraState()
	SetVisualHidden(stage, false)
	self:_applyLeagueDecal(stage, payload)

	local runtimeFolder = stage:FindFirstChild(RUNTIME_FOLDER_NAME)
	if runtimeFolder then
		runtimeFolder:Destroy()
	end
	runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = RUNTIME_FOLDER_NAME
	runtimeFolder.Parent = stage

	local mainSlot = ResolveSlot(stage, "MainPlayer")
	local player1Slot = ResolveSlot(stage, "Player1")
	local player2Slot = ResolveSlot(stage, "Player2")
	local player3Slot = ResolveSlot(stage, "Player3")
	local coachSlot = ResolveSlot(stage, "Coach")

	SetVisualHidden(mainSlot, true)
	SetVisualHidden(player1Slot, true)
	SetVisualHidden(player2Slot, true)
	SetVisualHidden(player3Slot, true)
	SetVisualHidden(coachSlot, true)

	local sources = type(payload) == "table" and payload.Sources or nil
	local companions = type(sources) == "table" and sources.Companions or {}
	local mainPlayer = type(sources) == "table" and sources.MainPlayer or LocalPlayer.Character
	local coach = type(sources) == "table" and sources.Coach or nil

	self:_spawnClone(mainPlayer, mainSlot, runtimeFolder, true)
	self:_spawnClone(companions[1], player1Slot, runtimeFolder, false)
	self:_spawnClone(companions[2], player2Slot, runtimeFolder, false)
	self:_spawnClone(companions[3], player3Slot, runtimeFolder, false)
	self:_spawnClone(coach, coachSlot, runtimeFolder, false)

	local gui, title, skip = EnsureGui()
	title.Text = type(payload) == "table" and tostring(payload.Message or "CHAMPIONS!") or "CHAMPIONS!"
	title.Visible = false
	title.TextTransparency = 1
	title.TextStrokeTransparency = 1
	gui.Enabled = true
	skip.Visible = false
	skip.Active = false
	skip.AutoButtonColor = true
	UIJuice.Cancel(skip)

	task.delay(10, function()
		if self._active and not self._skipRequested and skip.Parent then
			skip.Visible = true
			skip.Active = true
			UIJuice.PopIn(skip, {
				StartScale = 0.72,
				OvershootScale = 1.08,
				Duration = 0.14,
				SettleDuration = 0.12,
			})
		end
	end)

	local mainClone = self._clones[1]
	self._cinematic:Play({
		Stage = stage,
		RuntimeFolder = runtimeFolder,
		MainClone = mainClone,
		Gui = gui,
		Title = title,
		AreaId = type(payload) == "table" and payload.AreaId or "Area01",
		DurationSeconds = type(payload) == "table" and tonumber(payload.DurationSeconds) or 20,
	})

	local sessionId = type(payload) == "table" and payload.SessionId or nil
	local durationSeconds = type(payload) == "table" and tonumber(payload.DurationSeconds) or 20
	local connection = skip.Activated:Connect(function()
		if self._skipRequested then
			return
		end
		self._skipRequested = true
		skip.Active = false
		skip.AutoButtonColor = false
		UIJuice.Punch(skip, {
			PeakScale = 1.06,
			UpDuration = 0.05,
			DownDuration = 0.10,
		})
		if type(onSkip) == "function" then
			onSkip(sessionId)
		end
	end)
	table.insert(self._connections, connection)

	task.delay(math.max(durationSeconds, 1) + 1.5, function()
		if not self._active or self._skipRequested then
			return
		end

		self._skipRequested = true
		if skip.Parent then
			skip.Active = false
			skip.AutoButtonColor = false
		end
		if type(onSkip) == "function" then
			onSkip(sessionId)
		end
	end)
end

function TournamentChampionView:Hide()
	self._active = false
	self._skipRequested = false

	if self._cinematic then
		self._cinematic:Cleanup()
	end

	self:_clearClones()
	self:_restoreOriginals()

	if self._hiddenBalls then
		for part, originalTransparency in pairs(self._hiddenBalls) do
			if part and part.Parent then
				part.Transparency = originalTransparency
				part.LocalTransparencyModifier = 0
			end
		end
		self._hiddenBalls = nil
	end

	HideRealTrophy(LocalPlayer.Character)

	local stage = GetChampionRoot(false)
	if stage then
		local runtimeFolder = stage:FindFirstChild(RUNTIME_FOLDER_NAME)
		if runtimeFolder then
			runtimeFolder:Destroy()
		end
		SetVisualHidden(stage, true)
	end

	local camera = Workspace.CurrentCamera
	if camera and self._cameraState then
		camera.CameraType = self._cameraState.CameraType
		camera.CameraSubject = self._cameraState.CameraSubject
		camera.CFrame = self._cameraState.CFrame
		camera.FieldOfView = self._cameraState.FieldOfView or camera.FieldOfView
	end
	self._cameraState = nil

	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild(GUI_NAME)
	if gui and gui:IsA("ScreenGui") then
		gui.Enabled = false
		local skip = gui:FindFirstChild("SkipButton")
		if skip and skip:IsA("TextButton") then
			UIJuice.Cancel(skip)
			skip.Active = true
			skip.AutoButtonColor = true
		end
	end
end

function TournamentChampionView:Destroy()
	self:Hide()
	if self._cinematic then
		self._cinematic:Destroy()
	end
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return TournamentChampionView
