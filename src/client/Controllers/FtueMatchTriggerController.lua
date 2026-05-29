local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchService
local DataService

local LOCAL_PLAYER = Players.LocalPlayer

local DEFAULT_READY_TIMEOUT_SECONDS = 12
local DEFAULT_CHARACTER_TIMEOUT_SECONDS = 8
local DEFAULT_RETRY_DELAY_SECONDS = 0.15

local FtueMatchTriggerController = Knit.CreateController({
	Name = "FtueMatchTriggerController",
})

local isQueued = false
local hasTriggered = false

local function IsCharacterReady(character)
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	return humanoid ~= nil and root ~= nil and root:IsA("BasePart") and humanoid.Health > 0
end

local function WaitForCharacterReady(timeoutSeconds)
	local deadline = os.clock() + timeoutSeconds

	while os.clock() < deadline do
		if IsCharacterReady(LOCAL_PLAYER.Character) then
			return true
		end

		task.wait(DEFAULT_RETRY_DELAY_SECONDS)
	end

	return false
end

local function WaitForClientReady(timeoutSeconds)
	local deadline = os.clock() + timeoutSeconds

	while os.clock() < deadline do
		local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
		if playerGui and LOCAL_PLAYER:GetAttribute("DataLoaded") == true then
			return true
		end

		task.wait(DEFAULT_RETRY_DELAY_SECONDS)
	end

	return false
end

function FtueMatchTriggerController:_canTrigger(options)
	options = options or {}

	if isQueued then
		return false, "TriggerQueued"
	end

	if hasTriggered and options.AllowRepeat ~= true then
		return false, "AlreadyTriggered"
	end

	if options.RequiredTutorialStep ~= nil or options.RequireTutorialIncomplete == true then
		local success, playerData = DataService:GetData(LOCAL_PLAYER):await()

		if not success or not playerData then
			return false, "DataNotLoaded"
		end

		if options.RequiredTutorialStep ~= nil then
			if playerData.TutorialStep ~= options.RequiredTutorialStep then
				return false, "TutorialStepMismatch"
			end
		end

		if options.RequireTutorialIncomplete == true then
			if playerData.TutorialComplete == true then
				return false, "TutorialComplete"
			end
		end
	end

	return true, "OK"
end

function FtueMatchTriggerController:Trigger(options)
	options = options or {}

	local canTrigger, reason = self:_canTrigger(options)
	if not canTrigger then
		if options.Debug == true then
			warn("[FtueMatchTriggerController] Trigger rejected:", reason)
		end

		return false, reason
	end

	hasTriggered = true

	if options.OnTrigger then
		local ok, callbackResult = pcall(options.OnTrigger)
		if not ok then
			warn("[FtueMatchTriggerController] OnTrigger failed:", callbackResult)
			return false, "CallbackFailed"
		end

		return callbackResult ~= false, "CallbackTriggered"
	end

	if MatchService and MatchService.StartFtueMatch then
		MatchService:StartFtueMatch()
		return true, "StartFtueMatchRequested"
	end

	warn("[FtueMatchTriggerController] No client start method found. Pass options.OnTrigger or expose a server remote.")
	return false, "MissingStartMethod"
end

function FtueMatchTriggerController:TriggerWhenReady(options)
	options = options or {}

	local canTrigger, reason = self:_canTrigger(options)
	if not canTrigger then
		if options.Debug == true then
			warn("[FtueMatchTriggerController] TriggerWhenReady rejected:", reason)
		end

		return false, reason
	end

	isQueued = true

	task.spawn(function()
		local readyTimeout = options.ReadyTimeoutSeconds or DEFAULT_READY_TIMEOUT_SECONDS
		local characterTimeout = options.CharacterTimeoutSeconds or DEFAULT_CHARACTER_TIMEOUT_SECONDS

		local clientReady = WaitForClientReady(readyTimeout)
		if not clientReady then
			isQueued = false
			if options.Debug == true then
				warn("[FtueMatchTriggerController] Client ready timeout.")
			end
			return
		end

		local characterReady = WaitForCharacterReady(characterTimeout)
		if not characterReady then
			isQueued = false
			if options.Debug == true then
				warn("[FtueMatchTriggerController] Character ready timeout.")
			end
			return
		end

		isQueued = false
		self:Trigger(options)
	end)

	return true, "Queued"
end

function FtueMatchTriggerController:Reset()
	isQueued = false
	hasTriggered = false
end

function FtueMatchTriggerController:KnitInit()
	DataService = Knit.GetService("DataService")
	MatchService = Knit.GetService("MatchService")
end

function FtueMatchTriggerController:KnitStart() end

return FtueMatchTriggerController
