--!strict
-- TournamentRules.luau
-- Pure tournament progression rules. No Roblox APIs.

local TournamentConfig = require(script.Parent.TournamentConfig)

local TournamentRules = {}

local MODULUS = 2147483647
local MULTIPLIER = 69621

local function CloneTeam(team)
	if not team then
		return nil
	end

	return {
		TeamId = tostring(team.TeamId or ""),
		DisplayName = tostring(team.DisplayName or "Unknown FC"),
		AssetFolderName = tostring(team.AssetFolderName or team.TeamId or ""),
		AreaId = team.AreaId,
		IsPlayer = team.IsPlayer == true,
	}
end

local function NormalizeSeed(seed: number?): number
	local value = math.floor(tonumber(seed) or 1) % MODULUS
	if value <= 0 then
		value = 1
	end
	return value
end

local function NextSeed(seed: number): number
	return (NormalizeSeed(seed) * MULTIPLIER) % MODULUS
end

local function NextInteger(seed: number, minValue: number, maxValue: number): (number, number)
	local nextSeed = NextSeed(seed)
	local range = math.max(1, maxValue - minValue + 1)
	local value = minValue + (nextSeed % range)
	return value, nextSeed
end

local function CloneMatch(match)
	return {
		MatchId = match.MatchId,
		RoundId = match.RoundId,
		RoundIndex = match.RoundIndex,
		MatchIndex = match.MatchIndex,
		HomeTeam = CloneTeam(match.HomeTeam),
		AwayTeam = CloneTeam(match.AwayTeam),
		WinnerTeam = CloneTeam(match.WinnerTeam),
		Score = match.Score and { Home = match.Score.Home or 0, Away = match.Score.Away or 0 } or nil,
		IsPlayerMatch = match.IsPlayerMatch == true,
		IsFinal = match.IsFinal == true,
		IsLocked = match.IsLocked == true,
		Minute = match.Minute,
		-- Multi-leg aggregate fields
		AggregatePlayer = match.AggregatePlayer,
		AggregateOpponent = match.AggregateOpponent,
		CurrentLeg = match.CurrentLeg,
		LegsPlayed = match.LegsPlayed,
		StartMinute = match.StartMinute,
		AccumulatedMinute = match.AccumulatedMinute,
		RequiredPlayerGoals = match.RequiredPlayerGoals,
		TargetPlayerGoals = match.TargetPlayerGoals,
		TargetOpponentGoals = match.TargetOpponentGoals,
	}
end

local function CloneState(state)
	local result = {
		StateId = state.StateId,
		CupId = state.CupId,
		CupName = state.CupName,
		AreaId = state.AreaId,
		Seed = state.Seed,
		Status = state.Status,
		CurrentRoundIndex = state.CurrentRoundIndex,
		PlayerTeam = CloneTeam(state.PlayerTeam),
		Rounds = {},
		MatchesByRound = {},
		CreatedAt = state.CreatedAt,
		UpdatedAt = state.UpdatedAt,
		LegResult = state.LegResult,
	}

	for index, roundDefinition in ipairs(state.Rounds or {}) do
		result.Rounds[index] = {
			RoundId = roundDefinition.RoundId,
			RoundName = roundDefinition.RoundName,
			ShortName = roundDefinition.ShortName,
			MatchCount = roundDefinition.MatchCount,
		}
	end

	for roundIndex, matches in pairs(state.MatchesByRound or {}) do
		result.MatchesByRound[roundIndex] = {}
		for matchIndex, match in ipairs(matches) do
			result.MatchesByRound[roundIndex][matchIndex] = CloneMatch(match)
		end
	end

	return result
end

local function IsPlayerTeam(team): boolean
	return team and team.IsPlayer == true
end

local function IsPlayerMatch(match): boolean
	return IsPlayerTeam(match.HomeTeam) or IsPlayerTeam(match.AwayTeam)
end

local function GetCurrentPlayerMatch(state)
	local matches = state.MatchesByRound[state.CurrentRoundIndex]
	if not matches then
		return nil
	end

	for _, match in ipairs(matches) do
		if IsPlayerMatch(match) then
			return match
		end
	end

	return nil
end

local function GetOpponentTeam(match)
	if IsPlayerTeam(match.HomeTeam) then
		return match.AwayTeam
	end
	return match.HomeTeam
end

local function SetWinnerAndScore(match, winnerTeam, score)
	match.WinnerTeam = CloneTeam(winnerTeam)
	match.Score = {
		Home = tonumber(score.Home) or 0,
		Away = tonumber(score.Away) or 0,
	}
	match.IsLocked = true
end

local function BuildPlayerResultScore(match, didWin: boolean, playerGoals: number?, opponentGoals: number?)
	local pGoals = playerGoals
	local oGoals = opponentGoals

	if not pGoals or not oGoals then
		local winScore = TournamentConfig.LiveMatch.WinScore
		local loseScore = TournamentConfig.LiveMatch.LoseScore

		pGoals = pGoals or (didWin and math.max(tonumber(winScore.Home) or 2, tonumber(winScore.Away) or 1)
			or math.min(tonumber(loseScore.Home) or 1, tonumber(loseScore.Away) or 2))
		oGoals = oGoals or (didWin and math.min(tonumber(winScore.Home) or 2, tonumber(winScore.Away) or 1)
			or math.max(tonumber(loseScore.Home) or 1, tonumber(loseScore.Away) or 2))
	end

	-- Enforce consistency: a won match cannot be 0-0 or have the loser score more/equal goals.
	if didWin then
		pGoals = math.max(pGoals or 1, 1)
		oGoals = oGoals or 0
		if pGoals <= oGoals then
			pGoals = oGoals + 1
		end
	else
		pGoals = pGoals or 0
		oGoals = math.max(oGoals or (pGoals + 1), pGoals + 1)
	end

	if IsPlayerTeam(match.HomeTeam) then
		return { Home = pGoals, Away = oGoals }
	end

	return { Home = oGoals, Away = pGoals }
end

local function ResolveRoundGoalTarget(match)
	local roundGoalTargets = TournamentConfig.LiveMatch.RoundGoalTargets
	local target = roundGoalTargets and roundGoalTargets[tostring(match and match.RoundId or "")]
	if target then
		local initialPlayer = tonumber(target.Player) or 0
		local initialOpponent = tonumber(target.Opponent) or 0
		local requiredPlayerGoals = math.max(1, tonumber(target.RequiredPlayerGoals) or (initialOpponent - initialPlayer + 1))

		return {
			Player = initialPlayer,
			Opponent = initialOpponent,
			RequiredPlayerGoals = requiredPlayerGoals,
			TargetPlayerGoals = initialPlayer + requiredPlayerGoals,
			TargetOpponentGoals = initialOpponent,
		}
	end

	return nil
end

local function ResolveAggregateWinTarget(match): number
	local targetPlayerGoals = tonumber(match and match.TargetPlayerGoals)
	if targetPlayerGoals then
		return targetPlayerGoals
	end

	local aggregateOpponent = tonumber(match and match.AggregateOpponent) or 0
	return aggregateOpponent + 1
end

local function HasReachedAggregateWinTarget(match): boolean
	if not match or match.AggregatePlayer == nil then
		return false
	end

	return (tonumber(match.AggregatePlayer) or 0) >= ResolveAggregateWinTarget(match)
end

local function SimulateNonPlayerMatch(match, seed: number): number
	if match.WinnerTeam then
		return seed
	end

	local winnerSide = nil
	winnerSide, seed = NextInteger(seed, 1, 2)
	local winnerTeam = winnerSide == 1 and match.HomeTeam or match.AwayTeam

	local winnerGoals = nil
	local loserGoals = nil
	winnerGoals, seed = NextInteger(seed, 1, 4)
	loserGoals, seed = NextInteger(seed, 0, math.max(0, winnerGoals - 1))

	if winnerSide == 1 then
		SetWinnerAndScore(match, winnerTeam, { Home = winnerGoals, Away = loserGoals })
	else
		SetWinnerAndScore(match, winnerTeam, { Home = loserGoals, Away = winnerGoals })
	end

	match.Minute = 90
	return seed
end

local function SimulateOtherMatchesInRound(state, roundIndex: number)
	local matches = state.MatchesByRound[roundIndex]
	if not matches then
		return state
	end

	local seed = NormalizeSeed(state.Seed + (roundIndex * 9973))
	for _, match in ipairs(matches) do
		if not IsPlayerMatch(match) then
			seed = SimulateNonPlayerMatch(match, seed)
		end
	end

	state.Seed = seed
	return state
end

local function BuildNextRound(state, nextRoundIndex: number)
	if state.MatchesByRound[nextRoundIndex] then
		return state
	end

	local previousRoundIndex = nextRoundIndex - 1
	local previousMatches = state.MatchesByRound[previousRoundIndex]
	local roundDefinition = state.Rounds[nextRoundIndex]
	if not previousMatches or not roundDefinition then
		return state
	end

	local winners = {}
	for _, previousMatch in ipairs(previousMatches) do
		if not previousMatch.WinnerTeam then
			return state
		end
		table.insert(winners, CloneTeam(previousMatch.WinnerTeam))
	end

	local nextMatches = {}
	for matchIndex = 1, roundDefinition.MatchCount do
		local homeTeam = winners[((matchIndex - 1) * 2) + 1]
		local awayTeam = winners[((matchIndex - 1) * 2) + 2]
		if homeTeam and awayTeam then
			local isPlayerMatch = IsPlayerTeam(homeTeam) or IsPlayerTeam(awayTeam)
			nextMatches[matchIndex] = {
				MatchId = string.format("%s_Match%02d", roundDefinition.RoundId, matchIndex),
				RoundId = roundDefinition.RoundId,
				RoundIndex = nextRoundIndex,
				MatchIndex = matchIndex,
				HomeTeam = homeTeam,
				AwayTeam = awayTeam,
				WinnerTeam = nil,
				Score = nil,
				IsPlayerMatch = isPlayerMatch,
				IsFinal = roundDefinition.RoundId == "Final",
				IsLocked = false,
				Minute = nil,
			}
		end
	end

	state.MatchesByRound[nextRoundIndex] = nextMatches

	-- Initialize aggregate for the new player match in this round.
	for _, match in ipairs(nextMatches) do
		if IsPlayerMatch(match) then
			TournamentRules.InitializeRoundAggregate(match, state.Seed + (nextRoundIndex * 7919))
		end
	end

	return SimulateOtherMatchesInRound(state, nextRoundIndex)
end

function TournamentRules.SimulateOtherMatches(state)
	local nextState = CloneState(state)
	return SimulateOtherMatchesInRound(nextState, nextState.CurrentRoundIndex)
end

function TournamentRules.AdvanceAfterWin(state, playerGoals: number?, opponentGoals: number?)
	local nextState = CloneState(state)
	if nextState.Status ~= "Active" then
		return nextState
	end

	local playerMatch = GetCurrentPlayerMatch(nextState)
	if not playerMatch then
		return nextState
	end

	-- Multi-leg: increment aggregate player score
	local hasAggregate = playerMatch.AggregatePlayer ~= nil
	if hasAggregate then
		playerMatch.AggregatePlayer = (playerMatch.AggregatePlayer or 0) + 1
		playerMatch.LegsPlayed = (playerMatch.LegsPlayed or 0) + 1

		-- Update accumulated minute based on the new gap for realistic pacing
		local newGap = (playerMatch.AggregatePlayer or 0) - (playerMatch.AggregateOpponent or 0)
		local startMinute = TournamentConfig.LiveMatch.DefaultStartMinute or 85
		local minuteByGap = TournamentConfig.LiveMatch.MinuteByGap
		if minuteByGap then
			local mapped = minuteByGap[newGap]
			if mapped then
				startMinute = mapped
			end
		end
		-- Ensure the next leg starts at least 6 minutes after the previous leg started
		-- to prevent the clock from overlapping/going backward if QTEs took longer.
		local previousStart = playerMatch.AccumulatedMinute or 85
		playerMatch.AccumulatedMinute = math.max(startMinute, previousStart + 6)

		if not HasReachedAggregateWinTarget(playerMatch) then
			-- Round NOT yet won. Player needs more legs.
			playerMatch.CurrentLeg = (playerMatch.CurrentLeg or 1) + 1
			nextState.LegResult = "LegWin"
			nextState.Status = "Active"
			return nextState
		end

		-- Round won! Gap >= 1. Set final aggregate as bracket score.
		nextState.LegResult = nil
	end

	local playerTeam = IsPlayerTeam(playerMatch.HomeTeam) and playerMatch.HomeTeam or playerMatch.AwayTeam

	-- Build the final score for the bracket. Use aggregate if available.
	local finalScore
	if hasAggregate then
		if IsPlayerTeam(playerMatch.HomeTeam) then
			finalScore = { Home = playerMatch.AggregatePlayer, Away = playerMatch.AggregateOpponent }
		else
			finalScore = { Home = playerMatch.AggregateOpponent, Away = playerMatch.AggregatePlayer }
		end
	else
		finalScore = BuildPlayerResultScore(playerMatch, true, playerGoals, opponentGoals)
	end

	SetWinnerAndScore(playerMatch, playerTeam, finalScore)
	playerMatch.Minute = 90

	if playerMatch.IsFinal or nextState.CurrentRoundIndex >= #nextState.Rounds then
		nextState.Status = "Champion"
		return nextState
	end

	local nextRoundIndex = nextState.CurrentRoundIndex + 1
	nextState = BuildNextRound(nextState, nextRoundIndex)
	nextState.CurrentRoundIndex = nextRoundIndex
	nextState.Status = "Active"

	return nextState
end

function TournamentRules.ApplyPlayerLoss(state, playerGoals: number?, opponentGoals: number?)
	local nextState = CloneState(state)
	local playerMatch = GetCurrentPlayerMatch(nextState)
	if playerMatch then
		local opponentTeam = GetOpponentTeam(playerMatch)
		SetWinnerAndScore(playerMatch, opponentTeam, BuildPlayerResultScore(playerMatch, false, playerGoals, opponentGoals))
		playerMatch.Minute = 90
	end

	nextState.Status = "Lost"
	return nextState
end

function TournamentRules.GetCurrentPlayerMatch(state)
	return GetCurrentPlayerMatch(state)
end

-- Multi-leg aggregate helpers

function TournamentRules.InitializeRoundAggregate(match, seed: number)
	local fixedTarget = ResolveRoundGoalTarget(match)
	if fixedTarget then
		match.AggregatePlayer = fixedTarget.Player
		match.AggregateOpponent = fixedTarget.Opponent
		match.RequiredPlayerGoals = fixedTarget.RequiredPlayerGoals
		match.TargetPlayerGoals = fixedTarget.TargetPlayerGoals
		match.TargetOpponentGoals = fixedTarget.TargetOpponentGoals
		match.CurrentLeg = 1
		match.LegsPlayed = 0
	else
		local initialScores = TournamentConfig.LiveMatch.InitialScores
		if not initialScores or #initialScores == 0 then
			return
		end

		local normalizedSeed = NormalizeSeed(seed)
		local index = (normalizedSeed % #initialScores) + 1
		local picked = initialScores[index]

		match.AggregatePlayer = tonumber(picked.Player) or 0
		match.AggregateOpponent = tonumber(picked.Opponent) or 0
		match.RequiredPlayerGoals = math.max(1, (match.AggregateOpponent - match.AggregatePlayer) + 1)
		match.TargetPlayerGoals = match.AggregatePlayer + match.RequiredPlayerGoals
		match.TargetOpponentGoals = match.AggregateOpponent
		match.CurrentLeg = 1
		match.LegsPlayed = 0
	end

	-- Determine start minute from gap
	local gap = match.AggregatePlayer - match.AggregateOpponent
	local minuteByGap = TournamentConfig.LiveMatch.MinuteByGap
	local startMinute = TournamentConfig.LiveMatch.DefaultStartMinute or 85
	if minuteByGap then
		local mapped = minuteByGap[gap]
		if mapped then
			startMinute = mapped
		end
	end

	match.StartMinute = startMinute
	match.AccumulatedMinute = startMinute
end

function TournamentRules.IsRoundComplete(match): boolean
	if not match or match.AggregatePlayer == nil then
		return match ~= nil and match.WinnerTeam ~= nil
	end

	return HasReachedAggregateWinTarget(match)
end

function TournamentRules.GetAggregateGap(match): number
	if not match or match.AggregatePlayer == nil then
		return 0
	end

	return (match.AggregatePlayer or 0) - (match.AggregateOpponent or 0)
end

return TournamentRules
