local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local NpcSupporterCheerController = Knit.CreateController({
	Name = "NpcSupporterCheerController",
	ActiveSessionId = nil,
})

local MatchService = nil
local TeleportService = nil

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
		return string.format("Area%02d", number)
	end

	return text
end

local function isShootGoalPayload(payload: any): boolean
	if type(payload) ~= "table" then
		return false
	end

	local actionName = payload.Action or payload.ActionName or payload.Type
	if actionName ~= nil and tostring(actionName) ~= "Shoot" then
		return false
	end

	if payload.Succeeded == true or payload.Success == true or payload.IsGoal == true or payload.Goal == true then
		return true
	end

	if tostring(payload.Result or "") == "Goal" or tostring(payload.Outcome or "") == "Goal" then
		return true
	end

	return false
end

function NpcSupporterCheerController:KnitInit()
	self._currentAreaId = nil
	self._activeSessionId = nil
	self._isAmbientActive = false
	self._lastGoalCheerKey = nil
	self._lastGoalCheerClock = 0

	self._ambientStartedEvent = Instance.new("BindableEvent")
	self._goalCheerRequestedEvent = Instance.new("BindableEvent")
	self._cheerStoppedEvent = Instance.new("BindableEvent")
	self._championCheerRequestedEvent = Instance.new("BindableEvent")
	self._championCheerStoppedEvent = Instance.new("BindableEvent")

	self.AmbientStarted = self._ambientStartedEvent.Event
	self.GoalCheerRequested = self._goalCheerRequestedEvent.Event
	self.CheerStopped = self._cheerStoppedEvent.Event
	self.ChampionCheerRequested = self._championCheerRequestedEvent.Event
	self.ChampionCheerStopped = self._championCheerStoppedEvent.Event

	-- Backward-compatible event name for earlier presenter patch revisions.
	self.CheerStarted = self.AmbientStarted
end

function NpcSupporterCheerController:_fireAmbientStart(areaId: string?, sessionId: any, reason: string)
	local normalizedAreaId = normalizeAreaId(areaId)
	if not normalizedAreaId then
		return
	end

	self._currentAreaId = normalizedAreaId
	self._activeSessionId = sessionId
	self._isAmbientActive = true

	self._ambientStartedEvent:Fire({
		AreaId = normalizedAreaId,
		SessionId = sessionId,
		Reason = reason,
	})
end

function NpcSupporterCheerController:_buildGoalCheerKey(areaId: string, sessionId: any, stepIndex: any): string
	return string.format(
		"%s:%s:%s",
		tostring(areaId),
		tostring(sessionId or "NoSession"),
		tostring(stepIndex or "Shoot")
	)
end

function NpcSupporterCheerController:_fireGoalCheer(payload: any, source: string)
	if not isShootGoalPayload(payload) then
		return
	end

	local sessionId = payload.SessionId or self._activeSessionId
	if self._activeSessionId ~= nil and sessionId ~= nil and tostring(sessionId) ~= tostring(self._activeSessionId) then
		return
	end

	local areaId = normalizeAreaId(payload.AreaId) or self._currentAreaId
	if not areaId then
		return
	end

	local now = os.clock()
	local key = self:_buildGoalCheerKey(areaId, sessionId, payload.StepIndex)
	local debounceSeconds = tonumber(payload.DebounceSeconds) or 0.35
	if self._lastGoalCheerKey == key and (now - self._lastGoalCheerClock) <= debounceSeconds then
		return
	end

	self._lastGoalCheerKey = key
	self._lastGoalCheerClock = now

	self._goalCheerRequestedEvent:Fire({
		AreaId = areaId,
		SessionId = sessionId,
		StepIndex = payload.StepIndex,
		QteTier = payload.QteTier,
		Reason = payload.Reason or source or "ShootGoal",
	})
end

function NpcSupporterCheerController:RequestGoalCheer(payload: any)
	if type(payload) ~= "table" then
		payload = {}
	end

	payload.Action = payload.Action or "Shoot"
	if payload.Succeeded == nil then
		payload.Succeeded = true
	end
	payload.Reason = payload.Reason or "ManualGoalCheer"

	self:_fireGoalCheer(payload, tostring(payload.Reason))
end

function NpcSupporterCheerController:RequestChampionCheer(payload: any)
	local areaId = (type(payload) == "table" and payload.AreaId) or self._currentAreaId
	local sessionId = (type(payload) == "table" and payload.SessionId) or self._activeSessionId
	self._championCheerRequestedEvent:Fire({
		AreaId = areaId,
		SessionId = sessionId,
	})
end

function NpcSupporterCheerController:_scheduleStepResolvedGoalFallback(payload: any)
	if not isShootGoalPayload(payload) then
		return
	end

	local areaId = normalizeAreaId(payload.AreaId) or self._currentAreaId
	if not areaId then
		return
	end

	local sessionId = payload.SessionId or self._activeSessionId
	local key = self:_buildGoalCheerKey(areaId, sessionId, payload.StepIndex)
	local fallbackDelay = tonumber(payload.GoalCheerFallbackDelay) or 1.15

	task.delay(fallbackDelay, function()
		if self._lastGoalCheerKey == key then
			return
		end

		if self._activeSessionId ~= nil and sessionId ~= nil and tostring(self._activeSessionId) ~= tostring(sessionId) then
			return
		end

		local fallbackPayload = table.clone(payload)
		fallbackPayload.AreaId = areaId
		fallbackPayload.SessionId = sessionId
		fallbackPayload.Reason = fallbackPayload.Reason or "MatchStepResolvedFallback"
		fallbackPayload.Action = fallbackPayload.Action or "Shoot"
		fallbackPayload.Succeeded = fallbackPayload.Succeeded ~= false

		self:_fireGoalCheer(fallbackPayload, "MatchStepResolvedFallback")
	end)
end

function NpcSupporterCheerController:_fireStop(reason: string)
	if not self._isAmbientActive and not self._activeSessionId then
		return
	end

	local oldSessionId = self._activeSessionId
	local oldAreaId = self._currentAreaId

	self._isAmbientActive = false
	self._activeSessionId = nil

	self._cheerStoppedEvent:Fire({
		AreaId = oldAreaId,
		SessionId = oldSessionId,
		Reason = reason,
	})
end

function NpcSupporterCheerController:GetCurrentAreaId(): string?
	return self._currentAreaId
end

function NpcSupporterCheerController:GetActiveSessionId(): any
	return self._activeSessionId
end

function NpcSupporterCheerController:KnitStart()
	MatchService = Knit.GetService("MatchService")
	TeleportService = Knit.GetService("TeleportService")

	TeleportService.AreaUpdated:Connect(function(areaId: string)
		self:_fireStop("AreaUpdated")
		self._currentAreaId = normalizeAreaId(areaId)
	end)

	task.spawn(function()
		local ok, areaId = pcall(function()
			local success, value = TeleportService:GetArea():await()
			if success then
				return value
			end
			return nil
		end)

		if ok and areaId then
			self._currentAreaId = normalizeAreaId(areaId)
		end
	end)

	MatchService.MatchSessionStarted:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		self.ActiveSessionId = tostring(payload.SessionId or "")
		local areaId = normalizeAreaId(payload.AreaId) or self._currentAreaId
		self:_fireAmbientStart(areaId, payload.SessionId, "MatchSessionStarted")
	end)

	-- Primary goal burst is requested from MatchShootDirector when the shooter
	-- result animation starts. This delayed fallback keeps the crowd reliable on
	-- older/stable branches where the shoot director may not request it yet.
	MatchService.MatchStepResolved:Connect(function(payload)
		self:_scheduleStepResolvedGoalFallback(payload)
	end)

	MatchService.MatchReturnStarted:Connect(function()
		self:_fireStop("MatchReturnStarted")
	end)

	MatchService.MatchSessionEnded:Connect(function(_, sessionId)
		local endedSessionId = tostring(sessionId or "")
		if endedSessionId ~= "" and self.ActiveSessionId ~= nil and tostring(self.ActiveSessionId) ~= endedSessionId then
			return
		end

		self.ActiveSessionId = nil
		self:_fireStop("MatchSessionEnded")
	end)

	-- Champion ceremony: loncat semua NPC selama ceremony berlangsung
	local MatchController = nil
	pcall(function()
		MatchController = Knit.GetController("MatchController")
	end)

	if MatchController then
		if MatchController.ChampionCeremonyStarted then
			MatchController.ChampionCeremonyStarted:Connect(function(payload)
				self:RequestChampionCheer(payload)
			end)
		end

		if MatchController.ChampionCeremonyEnded then
			MatchController.ChampionCeremonyEnded:Connect(function()
				self._championCheerStoppedEvent:Fire({})
			end)
		end
	end
end

function NpcSupporterCheerController:Destroy()
	self:_fireStop("Destroy")

	if self._ambientStartedEvent then
		self._ambientStartedEvent:Destroy()
		self._ambientStartedEvent = nil
	end

	if self._goalCheerRequestedEvent then
		self._goalCheerRequestedEvent:Destroy()
		self._goalCheerRequestedEvent = nil
	end

	if self._cheerStoppedEvent then
		self._cheerStoppedEvent:Destroy()
		self._cheerStoppedEvent = nil
	end
end

return NpcSupporterCheerController
