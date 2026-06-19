local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientRoot = script:FindFirstAncestor("Client")
local Sound = require(ReplicatedStorage.Packages.Sound)
local NpcSupporterCheerConfig = require(clientRoot.Config.Match.NpcSupporterCheerConfig)

local NpcSupporterCheerView = {}
NpcSupporterCheerView.__index = NpcSupporterCheerView

local RandomGenerator = Random.new()

local function debugLog(message: string)
	if NpcSupporterCheerConfig.Debug == true then
		print("[NpcSupporterCheer] " .. tostring(message))
	end
end

local function playChampionApplause()
	-- Play using the global Sound system
	local sound = Sound:PlaySound("MISC_ChampionApplause")

	-- Clean up sound after maximum 12 seconds
	if sound then
		task.delay(12, function()
			Sound:DestroySound("MISC_ChampionApplause")
		end)
	end
end

local function normalizeAreaId(areaId: any): string?
	if areaId == nil then
		return nil
	end

	local text = tostring(areaId)
	if text == "" then
		return nil
	end

	local number = tonumber(text:match("%d+"))
	if number then
		return string.format(NpcSupporterCheerConfig.AreaFolderNamePattern or "Area%02d", number)
	end

	return text
end

local function getRandomVariation(baseValue: number, variation: number): number
	local safeVariation = math.clamp(tonumber(variation) or 0, 0, 0.95)
	return (tonumber(baseValue) or 0) * RandomGenerator:NextNumber(1 - safeVariation, 1 + safeVariation)
end

local getModelPivot = nil
do
	local ok, Knit = pcall(function()
		return require(ReplicatedStorage.Packages.Knit)
	end)

	local function getMatchTimeScale()
		if ok and Knit then
			local okCtrl, controller = pcall(function()
				return Knit.GetController("MatchPresentationController")
			end)
			if okCtrl and controller and type(controller.TimeScale) == "number" then
				return controller.TimeScale
			end
		end
		return 1
	end

	NpcSupporterCheerView._getMatchTimeScale = getMatchTimeScale
end

local function getModelPivot(model: Model): CFrame?
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)

	return ok and pivot or nil
end

local function findRelativePath(root: Instance?, pathSegments: { string }): Instance?
	local current = root
	for _, segment in ipairs(pathSegments) do
		if not current then
			return nil
		end

		current = current:FindFirstChild(segment)
	end

	return current
end

local function insertUnique(candidates: { Instance }, seen: { [Instance]: boolean }, instance: Instance?)
	if instance and not seen[instance] then
		seen[instance] = true
		table.insert(candidates, instance)
	end
end

local function collectAreaRootCandidates(areaId: string): { Instance }
	local candidates = {}
	local seen = {}

	insertUnique(candidates, seen, Workspace:FindFirstChild(areaId))

	local mapAreasRoot = Workspace:FindFirstChild("MapAreas")
	insertUnique(candidates, seen, mapAreasRoot and mapAreasRoot:FindFirstChild(areaId))

	local mapRoot = Workspace:FindFirstChild("Map")
	insertUnique(candidates, seen, mapRoot and mapRoot:FindFirstChild(areaId))

	local assetsRoot = Workspace:FindFirstChild("Assets")
	local workspaceAssetAreas = assetsRoot and assetsRoot:FindFirstChild("MapAreas")
	insertUnique(candidates, seen, workspaceAssetAreas and workspaceAssetAreas:FindFirstChild(areaId))

	if #candidates <= 0 then
		local deepMatch = Workspace:FindFirstChild(areaId, true)
		insertUnique(candidates, seen, deepMatch)
	end

	return candidates
end

local function findFoldersForPaths(areaId: string, relativeFolderPaths: { { string } }): { Folder }
	local folders = {}
	local seen = {}

	for _, areaRoot in ipairs(collectAreaRootCandidates(areaId)) do
		for _, pathSegments in ipairs(relativeFolderPaths or {}) do
			local folder = findRelativePath(areaRoot, pathSegments)
			if folder and folder:IsA("Folder") and not seen[folder] then
				seen[folder] = true
				table.insert(folders, folder)
			end
		end
	end

	return folders
end

local function waitForFolders(
	areaId: string,
	relativeFolderPaths: { { string } },
	token: number,
	isTokenAlive
): { Folder }
	local timeout = tonumber(NpcSupporterCheerConfig.ResolveFolderTimeout) or 8
	local pollInterval = tonumber(NpcSupporterCheerConfig.ResolveFolderPollInterval) or 0.1
	local deadline = os.clock() + math.max(0, timeout)

	repeat
		if not isTokenAlive(token) then
			return {}
		end

		local folders = findFoldersForPaths(areaId, relativeFolderPaths)
		if #folders > 0 then
			return folders
		end

		task.wait(pollInterval)
	until os.clock() >= deadline

	return {}
end

local function isNestedInsideAnotherModel(instance: Instance, boundary: Instance): boolean
	local parent = instance.Parent
	while parent and parent ~= boundary do
		if parent:IsA("Model") then
			return true
		end

		parent = parent.Parent
	end

	return false
end

local function collectNpcModelsFromFolders(folders: { Folder }): { Model }
	local models = {}
	local seen = {}

	for _, folder in ipairs(folders) do
		for _, descendant in ipairs(folder:GetDescendants()) do
			if
				descendant:IsA("Model")
				and not seen[descendant]
				and not isNestedInsideAnotherModel(descendant, folder)
			then
				seen[descendant] = true
				table.insert(models, descendant)
			end
		end
	end

	return models
end

local function shuffleModels(models: { Model }): { Model }
	local shuffled = {}

	for _, model in ipairs(models) do
		table.insert(shuffled, model)
	end

	for index = #shuffled, 2, -1 do
		local swapIndex = RandomGenerator:NextInteger(1, index)
		shuffled[index], shuffled[swapIndex] = shuffled[swapIndex], shuffled[index]
	end

	return shuffled
end

local function chooseActiveNpcModels(models: { Model }, maxActive: number): { Model }
	local safeMaxActive = math.max(0, tonumber(maxActive) or #models)
	if safeMaxActive <= 0 then
		return {}
	end

	if #models <= safeMaxActive then
		return models
	end

	local selected = {}
	local shuffled = shuffleModels(models)

	for index = 1, safeMaxActive do
		table.insert(selected, shuffled[index])
	end

	return selected
end

local function prepareModelForJump(model: Model)
	local originalPartStates = {}

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			originalPartStates[descendant] = {
				Anchored = descendant.Anchored,
				CanCollide = descendant.CanCollide,
			}

			if NpcSupporterCheerConfig.ForceAnchorDuringJump == true then
				descendant.Anchored = true
			end

			if NpcSupporterCheerConfig.DisableCollisionDuringJump == true then
				descendant.CanCollide = false
			end
		end
	end

	return originalPartStates
end

local function restoreModelAfterJump(originalPartStates)
	for part, state in pairs(originalPartStates or {}) do
		if part and part.Parent then
			part.Anchored = state.Anchored
			part.CanCollide = state.CanCollide
		end
	end
end

local function cleanupJumpState(state, shouldReset: boolean)
	if not state or state.Cleaned then
		return
	end

	state.Cleaned = true
	state.Stopped = true

	if state.CurrentTween then
		pcall(function()
			state.CurrentTween:Cancel()
		end)
		state.CurrentTween = nil
	end

	if state.Connection then
		state.Connection:Disconnect()
		state.Connection = nil
	end

	if shouldReset and state.Model and state.Model.Parent and state.OriginPivot then
		pcall(function()
			state.Model:PivotTo(state.OriginPivot)
		end)
	end

	if state.OriginalPartStates then
		restoreModelAfterJump(state.OriginalPartStates)
		state.OriginalPartStates = nil
	end

	if state.PivotValue then
		state.PivotValue:Destroy()
		state.PivotValue = nil
	end
end

local function waitWithStopCheck(seconds: number, state): boolean
	local deadline = os.clock() + math.max(0, seconds)

	while os.clock() < deadline do
		if state.Stopped then
			return false
		end

		task.wait(0.03)
	end

	return not state.Stopped
end

local function createJumpTween(
	state,
	targetPivot: CFrame,
	duration: number,
	easingDirection: Enum.EasingDirection
): Tween
	local tweenInfo = TweenInfo.new(math.max(0.01, duration), Enum.EasingStyle.Sine, easingDirection, 0, false, 0)

	return TweenService:Create(state.PivotValue, tweenInfo, {
		Value = targetPivot,
	})
end

local function playTween(state, targetPivot: CFrame, duration: number, easingDirection: Enum.EasingDirection): boolean
	if state.Stopped or not state.Model or not state.Model.Parent or not state.PivotValue then
		return false
	end

	local timeScale = NpcSupporterCheerView._getMatchTimeScale and NpcSupporterCheerView._getMatchTimeScale() or 1
	local scaledDuration = duration / timeScale

	state.CurrentTween = createJumpTween(state, targetPivot, scaledDuration, easingDirection)
	state.CurrentTween:Play()

	local playbackState = state.CurrentTween.Completed:Wait()
	state.CurrentTween = nil

	if state.Stopped or not state.Model or not state.Model.Parent then
		return false
	end

	return playbackState == Enum.PlaybackState.Completed
end

function NpcSupporterCheerView.new()
	local self = setmetatable({}, NpcSupporterCheerView)

	self._ambientStates = {}
	self._goalStates = {}
	self._championStates = {}
	self._modelToState = {}
	self._ambientToken = 0
	self._goalToken = 0
	self._championToken = 0
	self._activeAreaId = nil
	self._activeSessionId = nil
	self._isAmbientRunning = false

	return self
end

function NpcSupporterCheerView:_isAmbientTokenAlive(token: number): boolean
	return self._ambientToken == token
end

function NpcSupporterCheerView:_isGoalTokenAlive(token: number): boolean
	return self._goalToken == token
end

function NpcSupporterCheerView:_isChampionTokenAlive(token: number): boolean
	return self._championToken == token
end

function NpcSupporterCheerView:_removeStateReference(state)
	if state and state.Model and self._modelToState[state.Model] == state then
		self._modelToState[state.Model] = nil
	end
end

function NpcSupporterCheerView:_cleanupState(state, shouldReset: boolean)
	self:_removeStateReference(state)
	cleanupJumpState(state, shouldReset)
end

function NpcSupporterCheerView:_cleanupStateList(stateList: { any }, shouldReset: boolean)
	for _, state in ipairs(stateList) do
		self:_cleanupState(state, shouldReset)
	end

	table.clear(stateList)
end

function NpcSupporterCheerView:_stopModelCurrentState(model: Model, shouldReset: boolean)
	local existingState = self._modelToState[model]
	if not existingState then
		return
	end

	self:_cleanupState(existingState, shouldReset)
end

function NpcSupporterCheerView:_createJumpState(model: Model, token: number, mode: string)
	local originPivot = getModelPivot(model)
	if not originPivot then
		return nil
	end

	self:_stopModelCurrentState(model, NpcSupporterCheerConfig.ResetToOriginOnStop == true)

	local originalPartStates = prepareModelForJump(model)

	local pivotValue = Instance.new("CFrameValue")
	pivotValue.Name = "_NpcSupporterCheerPivotValue"
	pivotValue.Value = originPivot
	pivotValue.Parent = model

	local state = {
		Model = model,
		OriginPivot = originPivot,
		PivotValue = pivotValue,
		Connection = nil,
		CurrentTween = nil,
		Stopped = false,
		Cleaned = false,
		OriginalPartStates = originalPartStates,
		Token = token,
		Mode = mode,
	}

	state.Connection = pivotValue:GetPropertyChangedSignal("Value"):Connect(function()
		if state.Stopped then
			return
		end

		if mode == "Ambient" and not self:_isAmbientTokenAlive(token) then
			return
		end

		if mode == "Goal" and not self:_isGoalTokenAlive(token) then
			return
		end

		if mode == "Champion" and not self:_isChampionTokenAlive(token) then
			return
		end

		if not model.Parent then
			self:_cleanupState(state, false)
			return
		end

		model:PivotTo(pivotValue.Value)
	end)

	self._modelToState[model] = state
	return state
end

function NpcSupporterCheerView:_startAmbientLoop(model: Model, index: number, token: number)
	local state = self:_createJumpState(model, token, "Ambient")
	if not state then
		return nil
	end

	task.spawn(function()
		local startDelay = ((index - 1) * (NpcSupporterCheerConfig.AmbientStartOffsetStep or 0.18))
			+ RandomGenerator:NextNumber(0, NpcSupporterCheerConfig.AmbientStartOffsetRandom or 0.35)

		if not waitWithStopCheck(startDelay, state) or not self:_isAmbientTokenAlive(token) then
			self:_cleanupState(state, NpcSupporterCheerConfig.ResetToOriginOnStop == true)
			return
		end

		while not state.Stopped and model.Parent and self:_isAmbientTokenAlive(token) do
			local jumpHeight = getRandomVariation(
				NpcSupporterCheerConfig.AmbientJumpHeight or 1.5,
				NpcSupporterCheerConfig.AmbientJumpHeightVariation or 0.4
			)
			local upDuration = getRandomVariation(
				NpcSupporterCheerConfig.AmbientUpDuration or 0.28,
				NpcSupporterCheerConfig.AmbientDurationVariation or 0.25
			)
			local downDuration = getRandomVariation(
				NpcSupporterCheerConfig.AmbientDownDuration or 0.32,
				NpcSupporterCheerConfig.AmbientDurationVariation or 0.25
			)

			local upPivot = state.OriginPivot + Vector3.new(0, jumpHeight, 0)

			if not playTween(state, upPivot, upDuration, Enum.EasingDirection.Out) then
				break
			end

			if not playTween(state, state.OriginPivot, downDuration, Enum.EasingDirection.In) then
				break
			end

			local restTime = RandomGenerator:NextNumber(
				NpcSupporterCheerConfig.AmbientRestTimeMin or 0.15,
				NpcSupporterCheerConfig.AmbientRestTimeMax or 0.45
			)
			local timeScale = NpcSupporterCheerView._getMatchTimeScale and NpcSupporterCheerView._getMatchTimeScale() or 1
			if not waitWithStopCheck(restTime / timeScale, state) then
				break
			end
		end

		self:_cleanupState(state, NpcSupporterCheerConfig.ResetToOriginOnStop == true)
	end)

	return state
end

function NpcSupporterCheerView:_startGoalBurst(model: Model, index: number, token: number)
	local state = self:_createJumpState(model, token, "Goal")
	if not state then
		return nil
	end

	task.spawn(function()
		local startDelay = ((index - 1) * (NpcSupporterCheerConfig.GoalStartOffsetStep or 0.015))
			+ RandomGenerator:NextNumber(0, NpcSupporterCheerConfig.GoalStartOffsetRandom or 0.18)

		if not waitWithStopCheck(startDelay, state) or not self:_isGoalTokenAlive(token) then
			self:_cleanupState(state, NpcSupporterCheerConfig.ResetToOriginOnStop == true)
			return
		end

		local jumpCount = math.max(1, math.floor(tonumber(NpcSupporterCheerConfig.GoalJumpCount) or 3))
		for _ = 1, jumpCount do
			if state.Stopped or not model.Parent or not self:_isGoalTokenAlive(token) then
				break
			end

			local jumpHeight = getRandomVariation(
				NpcSupporterCheerConfig.GoalJumpHeight or 2.15,
				NpcSupporterCheerConfig.GoalJumpHeightVariation or 0.28
			)
			local upDuration = getRandomVariation(
				NpcSupporterCheerConfig.GoalUpDuration or 0.18,
				NpcSupporterCheerConfig.GoalDurationVariation or 0.18
			)
			local downDuration = getRandomVariation(
				NpcSupporterCheerConfig.GoalDownDuration or 0.22,
				NpcSupporterCheerConfig.GoalDurationVariation or 0.18
			)

			local upPivot = state.OriginPivot + Vector3.new(0, jumpHeight, 0)

			if not playTween(state, upPivot, upDuration, Enum.EasingDirection.Out) then
				break
			end

			if not playTween(state, state.OriginPivot, downDuration, Enum.EasingDirection.In) then
				break
			end

			local restTime = RandomGenerator:NextNumber(
				NpcSupporterCheerConfig.GoalRestTimeMin or 0.035,
				NpcSupporterCheerConfig.GoalRestTimeMax or 0.09
			)
			local timeScale = NpcSupporterCheerView._getMatchTimeScale and NpcSupporterCheerView._getMatchTimeScale() or 1
			if not waitWithStopCheck(restTime / timeScale, state) then
				break
			end
		end

		self:_cleanupState(state, NpcSupporterCheerConfig.ResetToOriginOnStop == true)
	end)

	return state
end

-- Loop tak terbatas hingga StopChampionCheer dipanggil.
function NpcSupporterCheerView:_startChampionLoop(model: Model, index: number, token: number)
	local state = self:_createJumpState(model, token, "Champion")
	if not state then
		return nil
	end

	task.spawn(function()
		local startDelay = ((index - 1) * (NpcSupporterCheerConfig.ChampionStartOffsetStep or 0.004))
			+ RandomGenerator:NextNumber(0, NpcSupporterCheerConfig.ChampionStartOffsetRandom or 0.06)

		if not waitWithStopCheck(startDelay, state) or not self:_isChampionTokenAlive(token) then
			self:_cleanupState(state, NpcSupporterCheerConfig.ResetToOriginOnStop == true)
			return
		end

		-- Loop terus sampai token berubah (ceremony selesai)
		while not state.Stopped and model.Parent and self:_isChampionTokenAlive(token) do
			local jumpHeight = getRandomVariation(
				NpcSupporterCheerConfig.ChampionJumpHeight or 3.2,
				NpcSupporterCheerConfig.ChampionJumpHeightVariation or 0.35
			)
			local upDuration = getRandomVariation(
				NpcSupporterCheerConfig.ChampionUpDuration or 0.16,
				NpcSupporterCheerConfig.ChampionDurationVariation or 0.20
			)
			local downDuration = getRandomVariation(
				NpcSupporterCheerConfig.ChampionDownDuration or 0.20,
				NpcSupporterCheerConfig.ChampionDurationVariation or 0.20
			)

			local upPivot = state.OriginPivot + Vector3.new(0, jumpHeight, 0)

			if not playTween(state, upPivot, upDuration, Enum.EasingDirection.Out) then
				break
			end

			if not playTween(state, state.OriginPivot, downDuration, Enum.EasingDirection.In) then
				break
			end

			local restTime = RandomGenerator:NextNumber(
				NpcSupporterCheerConfig.ChampionRestTimeMin or 0.02,
				NpcSupporterCheerConfig.ChampionRestTimeMax or 0.06
			)
			local timeScale = NpcSupporterCheerView._getMatchTimeScale and NpcSupporterCheerView._getMatchTimeScale() or 1
			if not waitWithStopCheck(restTime / timeScale, state) then
				break
			end
		end

		self:_cleanupState(state, NpcSupporterCheerConfig.ResetToOriginOnStop == true)
	end)

	return state
end

function NpcSupporterCheerView:_resolveModels(
	areaId: string,
	folderPaths: { { string } },
	maxActive: number,
	token: number,
	tokenPredicate
): { Model }
	local folders = waitForFolders(areaId, folderPaths, token, tokenPredicate)
	if #folders <= 0 then
		return {}
	end

	local allModels = collectNpcModelsFromFolders(folders)
	return chooseActiveNpcModels(allModels, maxActive)
end

function NpcSupporterCheerView:_stopAmbient(reason: string?, shouldReset: boolean?)
	self._ambientToken += 1
	self._isAmbientRunning = false
	self:_cleanupStateList(self._ambientStates, shouldReset ~= false)

	if self._activeAreaId then
		debugLog(
			string.format("stop ambient area=%s reason=%s", tostring(self._activeAreaId), tostring(reason or "Unknown"))
		)
	end
end

function NpcSupporterCheerView:_stopGoal(reason: string?, shouldReset: boolean?)
	self._goalToken += 1
	self:_cleanupStateList(self._goalStates, shouldReset ~= false)

	if self._activeAreaId then
		debugLog(
			string.format("stop goal area=%s reason=%s", tostring(self._activeAreaId), tostring(reason or "Unknown"))
		)
	end
end

function NpcSupporterCheerView:_stopChampion(reason: string?, shouldReset: boolean?)
	self._championToken += 1
	self:_cleanupStateList(self._championStates, shouldReset ~= false)

	if self._activeAreaId then
		debugLog(
			string.format(
				"stop champion area=%s reason=%s",
				tostring(self._activeAreaId),
				tostring(reason or "Unknown")
			)
		)
	end
end

function NpcSupporterCheerView:StartAmbientCheer(areaId: string, sessionId: any)
	local normalizedAreaId = normalizeAreaId(areaId)
	if not normalizedAreaId then
		return
	end

	self:_stopAmbient("Restart", true)

	self._activeAreaId = normalizedAreaId
	self._activeSessionId = sessionId
	self._isAmbientRunning = true

	if NpcSupporterCheerConfig.AmbientEnabled ~= true then
		return
	end

	self._ambientToken += 1
	local token = self._ambientToken

	debugLog(string.format("start ambient area=%s session=%s", tostring(normalizedAreaId), tostring(sessionId)))

	task.spawn(function()
		local selectedModels = self:_resolveModels(
			normalizedAreaId,
			NpcSupporterCheerConfig.AmbientFolderPaths or {},
			NpcSupporterCheerConfig.AmbientMaxActiveNpcs or 95,
			token,
			function(activeToken)
				return self:_isAmbientTokenAlive(activeToken)
			end
		)

		if not self:_isAmbientTokenAlive(token) then
			return
		end

		if #selectedModels <= 0 then
			warn(
				string.format("[NpcSupporterCheer] No ambient NPCAnim models found for %s", tostring(normalizedAreaId))
			)
			return
		end

		debugLog(string.format("ambient activate %d NPCs area=%s", #selectedModels, tostring(normalizedAreaId)))

		for index, model in ipairs(selectedModels) do
			if not self:_isAmbientTokenAlive(token) then
				return
			end

			if model.Parent then
				local state = self:_startAmbientLoop(model, index, token)
				if state then
					table.insert(self._ambientStates, state)
				end
			end
		end
	end)
end

function NpcSupporterCheerView:PlayGoalCheer(areaId: string, sessionId: any, payload: any?)
	local normalizedAreaId = normalizeAreaId(areaId or self._activeAreaId)
	if not normalizedAreaId then
		return
	end

	if self._activeSessionId ~= nil and sessionId ~= nil and tostring(sessionId) ~= tostring(self._activeSessionId) then
		debugLog(
			string.format(
				"ignore goal for stale session=%s active=%s",
				tostring(sessionId),
				tostring(self._activeSessionId)
			)
		)
		return
	end

	if NpcSupporterCheerConfig.GoalEnabled ~= true then
		return
	end

	local shouldResumeAmbient = self._isAmbientRunning == true
		and NpcSupporterCheerConfig.ResumeAmbientAfterGoal == true

	if NpcSupporterCheerConfig.GoalStopAmbientBeforeBurst == true then
		self:_stopAmbient("GoalBurst", true)
	end

	self:_stopGoal("RestartGoal", true)
	self._goalToken += 1
	local token = self._goalToken

	debugLog(
		string.format(
			"goal cheer area=%s session=%s tier=%s step=%s",
			tostring(normalizedAreaId),
			tostring(sessionId),
			tostring(type(payload) == "table" and payload.QteTier or nil),
			tostring(type(payload) == "table" and payload.StepIndex or nil)
		)
	)

	task.spawn(function()
		local selectedModels = self:_resolveModels(
			normalizedAreaId,
			NpcSupporterCheerConfig.GoalFolderPaths or {},
			NpcSupporterCheerConfig.GoalMaxActiveNpcs or 180,
			token,
			function(activeToken)
				return self:_isGoalTokenAlive(activeToken)
			end
		)

		if not self:_isGoalTokenAlive(token) then
			return
		end

		if #selectedModels <= 0 then
			warn(
				string.format("[NpcSupporterCheer] No goal NPC/NPCAnim models found for %s", tostring(normalizedAreaId))
			)
			return
		end

		debugLog(string.format("goal activate %d NPCs area=%s", #selectedModels, tostring(normalizedAreaId)))

		for index, model in ipairs(selectedModels) do
			if not self:_isGoalTokenAlive(token) then
				return
			end

			if model.Parent then
				local state = self:_startGoalBurst(model, index, token)
				if state then
					table.insert(self._goalStates, state)
				end
			end
		end

		if shouldResumeAmbient then
			local totalApproxDuration = (
				(NpcSupporterCheerConfig.GoalUpDuration or 0.18)
				+ (NpcSupporterCheerConfig.GoalDownDuration or 0.22)
				+ (NpcSupporterCheerConfig.GoalRestTimeMax or 0.09)
			)
					* math.max(1, tonumber(NpcSupporterCheerConfig.GoalJumpCount) or 3)
				+ (NpcSupporterCheerConfig.GoalStartOffsetRandom or 0.18)

			task.delay(totalApproxDuration + 0.1, function()
				if
					self:_isGoalTokenAlive(token)
					and self._activeAreaId == normalizedAreaId
					and self._activeSessionId == sessionId
				then
					self:StartAmbientCheer(normalizedAreaId, sessionId)
				end
			end)
		end
	end)
end

function NpcSupporterCheerView:PlayChampionCheer(areaId: string?, sessionId: any)
	local normalizedAreaId = normalizeAreaId(areaId or self._activeAreaId)
	if not normalizedAreaId then
		warn("[NpcSupporterCheer] PlayChampionCheer: no areaId resolved")
		return
	end

	if NpcSupporterCheerConfig.ChampionEnabled ~= true then
		return
	end

	-- Hentikan ambient dan goal, champion cycle yang jalan
	if NpcSupporterCheerConfig.ChampionStopAmbientBeforeBurst then
		self:_stopAmbient("ChampionStart", true)
	end
	if NpcSupporterCheerConfig.ChampionStopGoalBeforeBurst then
		self:_stopGoal("ChampionStart", true)
	end
	self:_stopChampion("RestartChampion", true)

	self._activeAreaId = normalizedAreaId
	self._activeSessionId = sessionId
	self._championToken += 1
	local token = self._championToken

	debugLog(string.format("champion cheer start area=%s session=%s", tostring(normalizedAreaId), tostring(sessionId)))

	-- Mainkan suara tepuk tangan besar langsung di awal ceremony
	playChampionApplause()

	task.spawn(function()
		-- Semua folder (NPCAnim + NPC) ikut, tanpa batas jumlah NPC
		local selectedModels = self:_resolveModels(
			normalizedAreaId,
			NpcSupporterCheerConfig.ChampionFolderPaths or {},
			NpcSupporterCheerConfig.ChampionMaxActiveNpcs or 9999,
			token,
			function(activeToken)
				return self:_isChampionTokenAlive(activeToken)
			end
		)

		if not self:_isChampionTokenAlive(token) then
			return
		end

		if #selectedModels <= 0 then
			warn(
				string.format(
					"[NpcSupporterCheer] No NPC models found for champion cheer area=%s",
					tostring(normalizedAreaId)
				)
			)
			return
		end

		debugLog(string.format("champion activate %d NPCs area=%s", #selectedModels, tostring(normalizedAreaId)))

		for index, model in ipairs(selectedModels) do
			if not self:_isChampionTokenAlive(token) then
				return
			end

			if model.Parent then
				local state = self:_startChampionLoop(model, index, token)
				if state then
					table.insert(self._championStates, state)
				end
			end
		end
	end)
end

function NpcSupporterCheerView:StopChampionCheer(reason: string?)
	self:_stopChampion(reason or "StopChampionCheer", true)
	debugLog(string.format("champion cheer stopped reason=%s", tostring(reason or "StopChampionCheer")))
end

function NpcSupporterCheerView:StopCheer(reason: string?)
	self:_stopAmbient(reason or "StopCheer", true)
	self:_stopGoal(reason or "StopCheer", true)
	self:_stopChampion(reason or "StopCheer", true)

	self._activeAreaId = nil
	self._activeSessionId = nil
	self._isAmbientRunning = false
end

-- Backward-compatible method for earlier presenter patch revisions.
function NpcSupporterCheerView:StartCheer(areaId: string, sessionId: any)
	self:StartAmbientCheer(areaId, sessionId)
end

function NpcSupporterCheerView:Destroy()
	self:StopCheer("Destroy")
end

return NpcSupporterCheerView
