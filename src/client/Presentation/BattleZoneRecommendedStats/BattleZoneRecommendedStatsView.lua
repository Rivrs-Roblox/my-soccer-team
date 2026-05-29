--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Trove = require(ReplicatedStorage.Packages.Trove)
local FormatNumber = require(ReplicatedStorage.Shared.Helpers.Numbers.FormatNumber)

type RecommendedStats = {
	AreaId: string?,
	Passing: number,
	Dribbling: number,
	Shooting: number,
}

local BattleZoneRecommendedStatsView = {}
BattleZoneRecommendedStatsView.__index = BattleZoneRecommendedStatsView

local BILLBOARD_PATH = { "Map", "BattleZone", "BattleZone", "Title", "BillboardGui" }
local RESOLVE_TIMEOUT_SECONDS = 10

function BattleZoneRecommendedStatsView.new()
	local self = setmetatable({}, BattleZoneRecommendedStatsView)

	self._trove = Trove.new()
	self._billboardGui = nil
	self._pendingStats = nil
	self._isResolving = false
	self._resolveToken = 0
	self._warnedMissingPath = false

	return self
end

local function waitForPath(root: Instance, path: { string }, timeoutSeconds: number): Instance?
	local current = root

	for _, childName in ipairs(path) do
		local nextChild = current:WaitForChild(childName, timeoutSeconds)
		if not nextChild then
			return nil
		end

		current = nextChild
	end

	return current
end

local function getNumberText(billboardGui: Instance, statName: string): TextLabel?
	local statFrame = billboardGui:FindFirstChild(statName)
	if not statFrame then
		return nil
	end

	local numberText = statFrame:FindFirstChild("NumberText")
	if not numberText then
		numberText = statFrame:FindFirstChild("NumberText", true)
	end

	if numberText and numberText:IsA("TextLabel") then
		return numberText
	end

	return nil
end

local function formatStat(value: number?): string
	return FormatNumber(math.floor(tonumber(value) or 0))
end

function BattleZoneRecommendedStatsView:_apply(stats: RecommendedStats)
	local billboardGui = self._billboardGui
	if not billboardGui or not billboardGui.Parent or not billboardGui:IsDescendantOf(Workspace) then
		self._billboardGui = nil
		return false
	end

	local passingText = getNumberText(billboardGui, "Passing")
	if passingText then
		passingText.Text = formatStat(stats.Passing)
	end

	local dribblingText = getNumberText(billboardGui, "Dribbling")
	if dribblingText then
		dribblingText.Text = formatStat(stats.Dribbling)
	end

	local shootingText = getNumberText(billboardGui, "Shooting")
	if shootingText then
		shootingText.Text = formatStat(stats.Shooting)
	end

	return true
end

function BattleZoneRecommendedStatsView:_resolveBillboardAsync()
	if self._isResolving then
		return
	end

	self._isResolving = true
	self._resolveToken += 1
	local token = self._resolveToken

	task.spawn(function()
		local billboardGui = waitForPath(Workspace, BILLBOARD_PATH, RESOLVE_TIMEOUT_SECONDS)
		if token ~= self._resolveToken then
			return
		end

		self._isResolving = false

		if not billboardGui then
			if not self._warnedMissingPath then
				self._warnedMissingPath = true
				warn("[BattleZoneRecommendedStatsView] Missing Workspace.Map.BattleZone.BattleZone.Title.BillboardGui.")
			end
			return
		end

		self._warnedMissingPath = false
		self._billboardGui = billboardGui

		if self._pendingStats then
			self:_apply(self._pendingStats)
		end
	end)
end

function BattleZoneRecommendedStatsView:Render(stats: RecommendedStats)
	self._pendingStats = stats

	if not self:_apply(stats) then
		self:_resolveBillboardAsync()
	end
end

function BattleZoneRecommendedStatsView:Destroy()
	self._resolveToken += 1
	self._trove:Destroy()
end

return BattleZoneRecommendedStatsView
