--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local RecommendedStatsResolver = require(ReplicatedStorage.Shared.Helpers.Match.TournamentRecommendedStatsResolver)
local BattleZoneRecommendedStatsView = require(script.Parent.BattleZoneRecommendedStatsView)

local BattleZoneRecommendedStatsPresenter = {}
BattleZoneRecommendedStatsPresenter.__index = BattleZoneRecommendedStatsPresenter

function BattleZoneRecommendedStatsPresenter.new()
	local self = setmetatable({}, BattleZoneRecommendedStatsPresenter)

	self._trove = Trove.new()
	self._view = nil

	return self
end

function BattleZoneRecommendedStatsPresenter:_renderArea(area: any)
	if not self._view then
		return
	end

	self._view:Render(RecommendedStatsResolver.GetFinalAreaStats(area))
end

function BattleZoneRecommendedStatsPresenter:Init()
	self._view = self._trove:Add(BattleZoneRecommendedStatsView.new())

	local TeleportController = Knit.GetController("TeleportController")

	if TeleportController.AreaChanged then
		self._trove:Add(TeleportController.AreaChanged:Connect(function(area, areaId)
			self:_renderArea(areaId or area)
		end))
	end

	if TeleportController.GetCurrentArea then
		local currentArea = TeleportController:GetCurrentArea()
		if currentArea then
			self:_renderArea(currentArea)
			return
		end
	end

	if TeleportController.GetCurrentAreaId then
		local currentAreaId = TeleportController:GetCurrentAreaId()
		if currentAreaId then
			self:_renderArea(currentAreaId)
			return
		end
	end

	self:_renderArea("Area01")
end

function BattleZoneRecommendedStatsPresenter:Destroy()
	self._trove:Destroy()
end

return BattleZoneRecommendedStatsPresenter
