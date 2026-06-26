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

	self._renderToken = (self._renderToken or 0) + 1
	local token = self._renderToken

	task.spawn(function()
		local DataService = Knit.GetService("DataService")
		local Players = game:GetService("Players")
		-- ponytail: fetch live data to check HighestRoundsWon progress
		local success, playerData = DataService:GetData(Players.LocalPlayer):await()

		if token ~= self._renderToken or not self._view then
			return
		end

		self._view:Render(RecommendedStatsResolver.GetFinalAreaStats(area, success and playerData))
	end)
end

function BattleZoneRecommendedStatsPresenter:Init()
	self._view = self._trove:Add(BattleZoneRecommendedStatsView.new())

	local TeleportController = Knit.GetController("TeleportController")
	local TournamentService = Knit.GetService("TournamentService")

	if TeleportController.AreaChanged then
		self._trove:Add(TeleportController.AreaChanged:Connect(function(area, areaId)
			self:_renderArea(areaId or area)
		end))
	end

	-- ponytail: update billboard whenever tournament bracket progression updates
	self._trove:Add(TournamentService.TournamentUpdated:Connect(function()
		local currentArea = TeleportController:GetCurrentAreaId() or TeleportController:GetCurrentArea() or "Area01"
		self:_renderArea(currentArea)
	end))

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
