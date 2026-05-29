--!strict
-- TournamentFactory.luau
-- Creates a deterministic 16-team knockout bracket without touching Roblox APIs.

local TournamentConfig = require(script.Parent.TournamentConfig)

local TournamentFactory = {}

local MODULUS = 2147483647
local MULTIPLIER = 48271

local function NormalizeSeed(seed: number?): number
	local value = math.floor(tonumber(seed) or 1) % MODULUS
	if value <= 0 then
		value = 1
	end
	return value
end

local function NextSeed(seed: number): number
	return (seed * MULTIPLIER) % MODULUS
end

local function NextInteger(seed: number, minValue: number, maxValue: number): (number, number)
	local nextSeed = NextSeed(seed)
	local range = math.max(1, maxValue - minValue + 1)
	local value = minValue + (nextSeed % range)
	return value, nextSeed
end

local function CloneTeam(team)
	return {
		TeamId = tostring(team.TeamId or ""),
		DisplayName = tostring(team.DisplayName or "Unknown FC"),
		AssetFolderName = tostring(team.AssetFolderName or team.TeamId or ""),
		AreaId = team.AreaId,
		IsPlayer = team.IsPlayer == true,
	}
end

local function ShuffleTeams(teams, seed: number)
	local result = {}
	for index, team in ipairs(teams) do
		result[index] = CloneTeam(team)
	end

	local currentSeed = NormalizeSeed(seed)
	for index = #result, 2, -1 do
		local swapIndex = 1
		swapIndex, currentSeed = NextInteger(currentSeed, 1, index)
		result[index], result[swapIndex] = result[swapIndex], result[index]
	end

	return result, currentSeed
end

local function CloneRounds()
	local rounds = {}
	for index, roundDefinition in ipairs(TournamentConfig.RoundOrder) do
		rounds[index] = {
			RoundId = roundDefinition.RoundId,
			RoundName = roundDefinition.RoundName,
			ShortName = roundDefinition.ShortName,
			MatchCount = roundDefinition.MatchCount,
		}
	end
	return rounds
end

local function BuildMatch(roundDefinition, roundIndex: number, matchIndex: number, homeTeam, awayTeam, isPlayerMatch: boolean)
	return {
		MatchId = string.format("%s_Match%02d", roundDefinition.RoundId, matchIndex),
		RoundId = roundDefinition.RoundId,
		RoundIndex = roundIndex,
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

function TournamentFactory.Create(params)
	params = params or {}

	local areaConfig = TournamentConfig.GetAreaConfig(params.AreaId)
	local seed = NormalizeSeed(params.Seed)
	local shuffledOpponents = nil
	shuffledOpponents, seed = ShuffleTeams(areaConfig.Teams or {}, seed)

	local playerTeam = CloneTeam(TournamentConfig.PlayerTeam)
	local bracketTeams = { playerTeam }
	for _, opponent in ipairs(shuffledOpponents) do
		table.insert(bracketTeams, opponent)
	end

	local rounds = CloneRounds()
	local firstRound = rounds[1]
	local firstRoundMatches = {}

	for matchIndex = 1, firstRound.MatchCount do
		local homeTeam = bracketTeams[((matchIndex - 1) * 2) + 1]
		local awayTeam = bracketTeams[((matchIndex - 1) * 2) + 2]
		if homeTeam and awayTeam then
			local isPlayerMatch = homeTeam.IsPlayer == true or awayTeam.IsPlayer == true
			firstRoundMatches[matchIndex] = BuildMatch(firstRound, 1, matchIndex, homeTeam, awayTeam, isPlayerMatch)
		end
	end

	return {
		StateId = tostring(params.StateId or string.format("Tournament_%s_%d", areaConfig.AreaId, seed)),
		CupId = tostring(areaConfig.CupId or "TournamentCup"),
		CupName = tostring(areaConfig.CupName or "Tournament Cup"),
		AreaId = tostring(areaConfig.AreaId or "Area01"),
		Seed = seed,
		Status = "Active",
		CurrentRoundIndex = 1,
		PlayerTeam = playerTeam,
		Rounds = rounds,
		MatchesByRound = {
			[1] = firstRoundMatches,
		},
		CreatedAt = tonumber(params.CreatedAt) or nil,
		UpdatedAt = tonumber(params.UpdatedAt) or nil,
	}
end

return TournamentFactory
