local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchActorResolver = require(ReplicatedStorage.Shared.Helpers.Match.MatchActorResolver)

local LocalPlayer = Players.LocalPlayer

local MatchService = nil
local MatchPresentationController = nil
local MatchActorRuntimeController = nil
local MatchCompanionVisualController = nil

local GUI_NAME = "BallCarrierArrowGui"
local ARROW_TEXT = "▼"
local ARROW_COLOR = Color3.fromRGB(255, 225, 35)
local ARROW_STROKE_COLOR = Color3.fromRGB(20, 18, 8)
local GLOW_COLOR = Color3.fromRGB(255, 190, 0)

local HEAD_OFFSET = Vector3.new(0, 1.65, 0)
local ROOT_OFFSET = Vector3.new(0, 4.35, 0)
local RETRY_INTERVAL = 0.12
local MAX_RETRY_SECONDS = 2.4

local MatchBallCarrierMarkerController = Knit.CreateController({
	Name = "MatchBallCarrierMarkerController",
})

local function getPlayerGui()
	return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

local function getRootPart(model: Instance?): BasePart?
	if not model then
		return nil
	end

	if model:IsA("BasePart") then
		return model
	end

	if model:IsA("Model") then
		local head = model:FindFirstChild("Head", true)
		if head and head:IsA("BasePart") then
			return head
		end

		local root = model:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			return root
		end

		if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
			return model.PrimaryPart
		end

		return model:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function findLocalPlayerProxy(): Model?
	local runtimeRoot = Workspace:FindFirstChild("LocalMatchPresentationRuntime")
	if runtimeRoot then
		local proxy = runtimeRoot:FindFirstChild("LocalMatchPlayerProxy")
		if proxy and proxy:IsA("Model") then
			return proxy
		end
	end

	return nil
end

local function isShootAction(actionName: any): boolean
	return string.lower(tostring(actionName or "")) == "shoot"
end

local function isPassAction(actionName: any): boolean
	return string.lower(tostring(actionName or "")) == "pass"
end

local function isDribbleAction(actionName: any): boolean
	return string.lower(tostring(actionName or "")) == "dribble"
end

function MatchBallCarrierMarkerController:_createGui()
	if self._billboard and self._billboard.Parent then
		return
	end

	local playerGui = getPlayerGui()
	if not playerGui then
		warn("[MatchBallCarrierMarker] PlayerGui not ready; marker skipped.")
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = GUI_NAME
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 500
	billboard.Size = UDim2.fromOffset(82, 82)
	billboard.Enabled = false
	billboard.Parent = playerGui

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = billboard

	local glow = Instance.new("TextLabel")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Position = UDim2.fromScale(0.5, 0.52)
	glow.Size = UDim2.fromScale(1, 1)
	glow.Font = Enum.Font.GothamBlack
	glow.Text = ARROW_TEXT
	glow.TextColor3 = GLOW_COLOR
	glow.TextTransparency = 0.42
	glow.TextScaled = true
	glow.TextStrokeTransparency = 1
	glow.ZIndex = 1
	glow.Parent = holder

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.BackgroundTransparency = 1
	arrow.Position = UDim2.fromScale(0.5, 0.5)
	arrow.Size = UDim2.fromScale(0.72, 0.72)
	arrow.Font = Enum.Font.GothamBlack
	arrow.Text = ARROW_TEXT
	arrow.TextColor3 = ARROW_COLOR
	arrow.TextScaled = true
	arrow.TextStrokeColor3 = ARROW_STROKE_COLOR
	arrow.TextStrokeTransparency = 0
	arrow.ZIndex = 2
	arrow.Parent = holder

	local scale = Instance.new("UIScale")
	scale.Name = "PulseScale"
	scale.Scale = 1
	scale.Parent = holder

	self._billboard = billboard
	self._holder = holder
	self._glow = glow
	self._arrow = arrow
	self._scale = scale
end

function MatchBallCarrierMarkerController:_resolveActorModel(slotNumber: number): Instance?
	if MatchPresentationController and MatchPresentationController._getControlledActorModel then
		local ok, model = pcall(function()
			return MatchPresentationController:_getControlledActorModel(slotNumber)
		end)

		if ok and model and model.Parent then
			return model
		end
	end

	if MatchActorRuntimeController and MatchActorRuntimeController.GetLocalMatchActorModel then
		local ok, model = pcall(function()
			return MatchActorRuntimeController:GetLocalMatchActorModel(LocalPlayer, slotNumber)
		end)

		if ok and model and model.Parent then
			return model
		end
	end

	if slotNumber == 1 then
		local proxy = findLocalPlayerProxy()
		if proxy then
			return proxy
		end
	end

	if MatchCompanionVisualController and MatchCompanionVisualController.GetOwnedCompanionModels then
		local ok, companions = pcall(function()
			return MatchCompanionVisualController:GetOwnedCompanionModels(LocalPlayer)
		end)

		if ok and type(companions) == "table" then
			local index = math.max(slotNumber - 1, 1)
			local model = companions[index]
			if model and model.Parent then
				return model
			end
		end
	end

	local playerProxy = MatchPresentationController and MatchPresentationController.PlayerProxy or nil
	return MatchActorResolver.GetActorModelBySlot(slotNumber, playerProxy)
end

function MatchBallCarrierMarkerController:_resolveAdorneeForSlot(slotNumber: number): (BasePart?, Vector3)
	local model = self:_resolveActorModel(slotNumber)
	local adornee = getRootPart(model)

	if adornee and adornee.Name == "Head" then
		return adornee, HEAD_OFFSET
	end

	return adornee, ROOT_OFFSET
end

function MatchBallCarrierMarkerController:_applyAdornee(slotNumber: number): boolean
	self:_createGui()
	if not self._billboard then
		return false
	end

	local adornee, offset = self:_resolveAdorneeForSlot(slotNumber)
	if not adornee or not adornee.Parent then
		return false
	end

	self._billboard.Adornee = adornee
	self._billboard.StudsOffsetWorldSpace = offset
	self._baseOffset = offset
	self._billboard.Enabled = true
	self._currentSlot = slotNumber
	self._lastResolvedAdornee = adornee
	return true
end

function MatchBallCarrierMarkerController:_ensureRenderLoop()
	if self._renderConnection then
		return
	end

	self._renderStartedAt = os.clock()
	self._renderConnection = RunService.RenderStepped:Connect(function()
		self:_renderMarker()
	end)
end

function MatchBallCarrierMarkerController:_renderMarker()
	if not self._billboard or not self._billboard.Enabled then
		return
	end

	local currentSlot = tonumber(self._currentSlot)
	if not currentSlot then
		return
	end

	local adornee = self._billboard.Adornee
	if not adornee or not adornee.Parent then
		self:_applyAdornee(currentSlot)
		return
	end

	local t = os.clock() - (self._renderStartedAt or os.clock())
	local pulse = 1 + (math.sin(t * 5.8) * 0.075)
	local bob = math.sin(t * 6.6) * 0.18
	local tilt = math.sin(t * 4.1) * 5

	if self._scale then
		self._scale.Scale = pulse
	end

	if self._arrow then
		self._arrow.Rotation = tilt
	end

	if self._glow then
		self._glow.Rotation = -tilt * 0.65
		self._glow.TextTransparency = 0.44 + (math.sin(t * 5.2) * 0.12)
	end

	self._billboard.StudsOffsetWorldSpace = (self._baseOffset or ROOT_OFFSET) + Vector3.new(0, bob, 0)
end

function MatchBallCarrierMarkerController:ShowForSlot(slotNumber: any, reason: string?)
	local numericSlot = tonumber(slotNumber)
	if not numericSlot then
		return false
	end

	self._markerToken = (self._markerToken or 0) + 1
	local token = self._markerToken
	local startedAt = os.clock()

	self._desiredSlot = numericSlot
	self._lastReason = reason or "Unknown"

	local didApply = self:_applyAdornee(numericSlot)
	self:_ensureRenderLoop()

	if didApply then
		return true
	end

	task.spawn(function()
		while token == self._markerToken and (os.clock() - startedAt) <= MAX_RETRY_SECONDS do
			if self:_applyAdornee(numericSlot) then
				return
			end
			task.wait(RETRY_INTERVAL)
		end
	end)

	return false
end

function MatchBallCarrierMarkerController:Hide(reason: string?)
	self._markerToken = (self._markerToken or 0) + 1
	self._desiredSlot = nil
	self._currentSlot = nil
	self._lastReason = reason or "Hidden"

	if self._billboard then
		self._billboard.Enabled = false
		self._billboard.Adornee = nil
	end
end

function MatchBallCarrierMarkerController:DestroyMarker()
	self:Hide("Destroy")

	if self._renderConnection then
		self._renderConnection:Disconnect()
		self._renderConnection = nil
	end

	if self._billboard then
		self._billboard:Destroy()
		self._billboard = nil
	end

	self._holder = nil
	self._glow = nil
	self._arrow = nil
	self._scale = nil
end

function MatchBallCarrierMarkerController:_handleSessionStarted(payload)
	self._activeSessionId = payload and payload.SessionId or nil
	self:Hide("SessionStarted")
end

function MatchBallCarrierMarkerController:_handleStepStarted(stepPayload)
	if not stepPayload then
		return
	end

	if self._activeSessionId ~= nil and stepPayload.SessionId ~= nil then
		if tostring(stepPayload.SessionId) ~= tostring(self._activeSessionId) then
			return
		end
	end

	self:ShowForSlot(stepPayload.ActorSlot or stepPayload.FromSlot or 1, "StepStarted")
end

function MatchBallCarrierMarkerController:_handleStepResolved(resultPayload)
	if not resultPayload then
		return
	end

	if self._activeSessionId ~= nil and resultPayload.SessionId ~= nil then
		if tostring(resultPayload.SessionId) ~= tostring(self._activeSessionId) then
			return
		end
	end

	if resultPayload.Succeeded ~= true then
		self:Hide("StepFailed")
		return
	end

	local actionName = resultPayload.Action
	if isPassAction(actionName) and resultPayload.TargetSlot then
		local targetSlot = resultPayload.TargetSlot
		task.delay(0.30, function()
			if self._activeSessionId ~= nil and resultPayload.SessionId ~= nil then
				if tostring(resultPayload.SessionId) ~= tostring(self._activeSessionId) then
					return
				end
			end
			self:ShowForSlot(targetSlot, "PassResolved")
		end)
		return
	end

	if isDribbleAction(actionName) then
		self:ShowForSlot(resultPayload.ActorSlot or resultPayload.FromSlot or self._currentSlot or 1, "DribbleResolved")
		return
	end

	if isShootAction(actionName) then
		task.delay(0.20, function()
			if self._activeSessionId ~= nil and resultPayload.SessionId ~= nil then
				if tostring(resultPayload.SessionId) ~= tostring(self._activeSessionId) then
					return
				end
			end
			self:Hide("ShootResolved")
		end)
		return
	end

	self:ShowForSlot(resultPayload.ActorSlot or resultPayload.FromSlot or self._currentSlot or 1, "StepResolved")
end

function MatchBallCarrierMarkerController:_handleSessionEnded()
	self._activeSessionId = nil
	self:Hide("SessionEnded")
end

function MatchBallCarrierMarkerController:KnitInit()
	self._activeSessionId = nil
	self._desiredSlot = nil
	self._currentSlot = nil
	self._markerToken = 0
	self._renderConnection = nil
	self._renderStartedAt = nil
	self._billboard = nil
end

function MatchBallCarrierMarkerController:KnitStart()
	MatchService = Knit.GetService("MatchService")

	pcall(function()
		MatchPresentationController = Knit.GetController("MatchPresentationController")
	end)

	pcall(function()
		MatchActorRuntimeController = Knit.GetController("MatchActorRuntimeController")
	end)

	pcall(function()
		MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
	end)

	if MatchService.MatchSessionStarted then
		MatchService.MatchSessionStarted:Connect(function(payload)
			self:_handleSessionStarted(payload)
		end)
	end

	if MatchService.MatchStepStarted then
		MatchService.MatchStepStarted:Connect(function(stepPayload)
			self:_handleStepStarted(stepPayload)
		end)
	end

	if MatchService.MatchStepResolved then
		MatchService.MatchStepResolved:Connect(function(resultPayload)
			self:_handleStepResolved(resultPayload)
		end)
	end

	if MatchService.MatchReturnStarted then
		MatchService.MatchReturnStarted:Connect(function()
			self:Hide("ReturnStarted")
		end)
	end

	if MatchService.MatchSessionEnded then
		MatchService.MatchSessionEnded:Connect(function()
			self:_handleSessionEnded()
		end)
	end

	if MatchService.ChampionCeremonyStarted then
		MatchService.ChampionCeremonyStarted:Connect(function()
			self:Hide("ChampionCeremonyStarted")
		end)
	end

	if MatchService.ChampionCeremonyEnded then
		MatchService.ChampionCeremonyEnded:Connect(function()
			self:Hide("ChampionCeremonyEnded")
		end)
	end
end

return MatchBallCarrierMarkerController
