local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local MatchIntroView = require(script.Parent.MatchIntroView)

local MatchIntroPresenter = {}
MatchIntroPresenter.__index = MatchIntroPresenter

function MatchIntroPresenter.new()
	local self = setmetatable({}, MatchIntroPresenter)

	self._trove = Trove.new()
	self._view = nil
	self._activeToken = nil
	self._activeSessionId = nil

	return self
end

function MatchIntroPresenter:Init()
	self._view = self._trove:Add(MatchIntroView.new())

	local MatchController = Knit.GetController("MatchController")

	self._trove:Add(MatchController.MatchIntroRequested:Connect(function(payload)
		self:_handleIntroRequested(MatchController, payload)
	end))

	self._trove:Add(MatchController.MatchIntroCancelled:Connect(function(payload)
		self:_handleIntroCancelled(payload)
	end))
end

function MatchIntroPresenter:_handleIntroRequested(MatchController, payload)
	if type(payload) ~= "table" then
		return
	end

	local sessionId = tostring(payload.SessionId or "")
	local token = tonumber(payload.Token)
	if sessionId == "" or token == nil then
		return
	end

	self._activeSessionId = sessionId
	self._activeToken = token

	task.spawn(function()
		local releaseCalled = false

		local function releasePresentation()
			if releaseCalled then
				return true
			end

			if self._activeSessionId ~= sessionId or self._activeToken ~= token then
				return false
			end

			releaseCalled = true
			return MatchController:CompleteMatchIntro(sessionId, token, true) == true
		end

		local ok, completed = pcall(function()
			return self._view:PlayIntro(payload.IntroData, token, releasePresentation)
		end)

		if self._activeSessionId ~= sessionId or self._activeToken ~= token then
			return
		end

		if not ok then
			warn(string.format("[MatchIntro] view error session=%s: %s", tostring(sessionId), tostring(completed)))
			completed = true
		end

		if completed == true and not releaseCalled then
			releasePresentation()
		elseif completed ~= true and not releaseCalled then
			MatchController:CompleteMatchIntro(sessionId, token, false)
		end
	end)
end

function MatchIntroPresenter:_handleIntroCancelled(payload)
	if type(payload) ~= "table" then
		return
	end

	local sessionId = tostring(payload.SessionId or "")
	if self._activeSessionId ~= sessionId then
		return
	end

	self._activeToken = nil
	self._activeSessionId = nil

	if self._view then
		self._view:Cancel(payload.Reason or "Cancelled")
	end
end

function MatchIntroPresenter:Destroy()
	self._trove:Destroy()
end

return MatchIntroPresenter
