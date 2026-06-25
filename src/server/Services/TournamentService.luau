--!strict
-- TournamentService.luau
-- Server-authoritative runtime cup state for My Soccer Team.
-- Phase: Day 1 + Day 2 merged. No UI logic here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TournamentFactory = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentFactory)
local TournamentRules = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentRules)
local TournamentPolicy = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentPolicy)
local TournamentQuery = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentQuery)
local TournamentConfig = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentConfig)
local MatchAreaConfig = require(ReplicatedStorage.Shared.Data.Match.MatchAreaConfig)

local TournamentService = Knit.CreateService({
	Name = "TournamentService",

	Client = {
		TournamentPreviewRequested = Knit.CreateSignal(),
		TournamentUpdated = Knit.CreateSignal(),
		TournamentCompleted = Knit.CreateSignal(),
	},
})

local sessionsByPlayer: { [Player]: any } = {}
local pendingStartByPlayer: { [Player]: boolean } = {}
local MatchService = nil

local function NowSeed(player: Player): number
	return math.floor(os.clock() * 100000) + (player.UserId * 97)
end

local function NormalizeAreaId(areaId: string?): string
	local targetAreaId = tostring(areaId or "")
	if TournamentConfig.Areas[targetAreaId] then
		return targetAreaId
	end
	return "Area01"
end

local function CloneEnemySteps(areaId: string, roundId: string?)
	local areaConfig = MatchAreaConfig[areaId] or MatchAreaConfig.Area01
	local resolvedRoundId = tostring(roundId or "RoundOf16")
	local sourceSteps = nil

	if areaConfig.RoundEnemySteps then
		sourceSteps = areaConfig.RoundEnemySteps[resolvedRoundId]
	end

	sourceSteps = sourceSteps or areaConfig.EnemySteps or {}

	local result = {}
	for stepIndex, stepData in ipairs(sourceSteps) do
		result[stepIndex] = {
			Step = stepIndex,
			Value = tonumber(stepData.Value) or 0,
			Role = tostring(stepData.Role or "Defender"),
			AllowedActions = table.clone(stepData.AllowedActions or {}),
		}
	end

	return result
end

function TournamentService:_createTournament(player: Player, areaId: string)
	local resolvedAreaId = NormalizeAreaId(areaId)
	local state = TournamentFactory.Create({
		AreaId = resolvedAreaId,
		Seed = NowSeed(player),
		CreatedAt = os.time(),
		UpdatedAt = os.time(),
	})

	state = TournamentRules.SimulateOtherMatches(state)
	sessionsByPlayer[player] = state

	return state
end

function TournamentService:GetOrCreateTournament(player: Player, areaId: string?)
	local resolvedAreaId = NormalizeAreaId(areaId)
	local state = sessionsByPlayer[player]

	if TournamentPolicy.ShouldCreateNewCup(state) or (state and state.AreaId ~= resolvedAreaId) then
		state = self:_createTournament(player, resolvedAreaId)
	end

	if not state then
		state = self:_createTournament(player, resolvedAreaId)
	end

	return state
end

function TournamentService:PrepareTournamentForPlayer(player: Player, areaId: string?)
	local state = self:GetOrCreateTournament(player, areaId)
	local payload = TournamentQuery.BuildPreviewPayload(state)
	self.Client.TournamentPreviewRequested:Fire(player, payload)
	self.Client.TournamentUpdated:Fire(player, payload)
	return state
end

function TournamentService:GetCurrentMatchContext(player: Player, areaId: string?)
	local state = self:GetOrCreateTournament(player, areaId)
	if not TournamentPolicy.CanStartMatch(state) then
		state = self:_createTournament(player, NormalizeAreaId(areaId))
	end

	return TournamentQuery.BuildMatchContext(state)
end

function TournamentService:GetCurrentEnemySteps(player: Player, areaId: string?)
	local matchContext = self:GetCurrentMatchContext(player, areaId)
	if not matchContext then
		return CloneEnemySteps(NormalizeAreaId(areaId), "RoundOf16")
	end

	return CloneEnemySteps(matchContext.AreaId, matchContext.RoundId)
end

function TournamentService:BuildPreviewPayload(player: Player, areaId: string?)
	local state = self:GetOrCreateTournament(player, areaId)
	return TournamentQuery.BuildPreviewPayload(state)
end


function TournamentService:OpenContinuationPreview(player: Player)
	local state = sessionsByPlayer[player]
	if not state then
		return nil
	end

	local canStart = TournamentPolicy.CanStartMatch(state)
	self:SetPendingStart(player, canStart)

	local payload = TournamentQuery.BuildPreviewPayload(state)
	self.Client.TournamentPreviewRequested:Fire(player, payload)
	self.Client.TournamentUpdated:Fire(player, payload)

	if state.Status == "Champion" then
		self.Client.TournamentCompleted:Fire(player, payload)
	end

	return payload
end

function TournamentService:SetPendingStart(player: Player, isPending: boolean)
	pendingStartByPlayer[player] = isPending == true or nil
end

function TournamentService:IsPendingStart(player: Player): boolean
	return pendingStartByPlayer[player] == true
end

function TournamentService:CancelPendingStart(player: Player, options: any?)
	pendingStartByPlayer[player] = nil

	if MatchService and MatchService.CancelPendingTournamentStart then
		local ok, result = pcall(function()
			return MatchService:CancelPendingTournamentStart(player, options)
		end)

		if ok then
			return result == true
		end

		warn("[TournamentService] CancelPendingTournamentStart failed: " .. tostring(result))
	end

	return true
end

function TournamentService:ApplyMatchResult(player: Player, didWin: boolean, playerGoals: number?, opponentGoals: number?)
	local state = sessionsByPlayer[player]
	if not state then
		return nil
	end

	if didWin then
		state = TournamentRules.AdvanceAfterWin(state, playerGoals, opponentGoals)
	else
		state = TournamentRules.ApplyPlayerLoss(state, playerGoals, opponentGoals)
	end

	state.UpdatedAt = os.time()
	sessionsByPlayer[player] = state

	local payload = TournamentQuery.BuildPreviewPayload(state)

	-- Multi-leg: propagate LegResult so MatchService can handle continuation
	if state.LegResult == "LegWin" then
		payload.LegResult = "LegWin"
		-- Don't fire TournamentUpdated for intermediate legs —
		-- bracket stays unchanged until round is complete.
		return payload
	end

	self.Client.TournamentUpdated:Fire(player, payload)

	if state.Status == "Champion" then
		self.Client.TournamentCompleted:Fire(player, payload)
	elseif state.Status == "Lost" then
		-- Prepare the next attempt immediately, but return the terminal loss payload
		-- to the caller. MatchService must observe "Lost" for this completed match;
		-- the reset payload is only the state used by the next explicit play request.
		local resetState = self:_createTournament(player, state.AreaId)
		local resetPayload = TournamentQuery.BuildPreviewPayload(resetState)
		self.Client.TournamentUpdated:Fire(player, resetPayload)
		return payload
	end

	return payload
end

function TournamentService.Client:RequestCurrentTournament(player: Player, areaId: string?)
	return self.Server:BuildPreviewPayload(player, areaId)
end

function TournamentService.Client:RequestTournamentPreview(player: Player, areaId: string?)
	local payload = self.Server:BuildPreviewPayload(player, areaId)
	self.Server.Client.TournamentPreviewRequested:Fire(player, payload)
	return payload
end


function TournamentService.Client:CancelPendingStart(player: Player, options: any?)
	return self.Server:CancelPendingStart(player, options)
end

function TournamentService.Client:ConfirmPlayMatch(player: Player)
	if not self.Server:IsPendingStart(player) then
		return false
	end

	if not MatchService or not MatchService.StartConfirmedTournamentMatch then
		self.Server:SetPendingStart(player, false)
		return false
	end

	return MatchService:StartConfirmedTournamentMatch(player) == true
end

function TournamentService:KnitStart()
	local ok, service = pcall(function()
		return Knit.GetService("MatchService")
	end)

	if ok then
		MatchService = service
	end

	Players.PlayerRemoving:Connect(function(player)
		sessionsByPlayer[player] = nil
		pendingStartByPlayer[player] = nil
	end)
end

return TournamentService
