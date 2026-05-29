local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local NpcSupporterCheerView = require(script.Parent.NpcSupporterCheerView)

local NpcSupporterCheerPresenter = {}
NpcSupporterCheerPresenter.__index = NpcSupporterCheerPresenter

function NpcSupporterCheerPresenter.new()
	local self = setmetatable({}, NpcSupporterCheerPresenter)

	self._trove = Trove.new()
	self._view = nil

	return self
end

function NpcSupporterCheerPresenter:Init()
	self._view = self._trove:Add(NpcSupporterCheerView.new())

	local CheerController = Knit.GetController("NpcSupporterCheerController")

	self._trove:Add(CheerController.AmbientStarted:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		self._view:StartAmbientCheer(payload.AreaId, payload.SessionId)
	end))

	self._trove:Add(CheerController.GoalCheerRequested:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		self._view:PlayGoalCheer(payload.AreaId, payload.SessionId, payload)
	end))

	self._trove:Add(CheerController.CheerStopped:Connect(function(payload)
		local reason = "Unknown"
		if type(payload) == "table" then
			reason = tostring(payload.Reason or reason)
		end

		self._view:StopCheer(reason)
	end))

	-- Champion ceremony: NPC loncat semua + big applause sound
	if CheerController.ChampionCheerRequested then
		self._trove:Add(CheerController.ChampionCheerRequested:Connect(function(payload)
			if type(payload) ~= "table" then
				payload = {}
			end
			self._view:PlayChampionCheer(payload.AreaId, payload.SessionId)
		end))
	end

	if CheerController.ChampionCheerStopped then
		self._trove:Add(CheerController.ChampionCheerStopped:Connect(function()
			self._view:StopChampionCheer("CeremonyEnded")
		end))
	end
end

function NpcSupporterCheerPresenter:Destroy()
	self._trove:Destroy()
end

return NpcSupporterCheerPresenter
