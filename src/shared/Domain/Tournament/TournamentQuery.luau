--!strict
-- TournamentQuery.luau
-- Pure read-model builders for UI, MatchService, and future bracket presentation.

local TournamentConfig = require(script.Parent.TournamentConfig)
local TournamentRules = require(script.Parent.TournamentRules)
local TournamentRewardCalculator = require(script.Parent.TournamentRewardCalculator)

local TournamentQuery = {}

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

local function CloneScore(score)
	if not score then
		return nil
	end

	return {
		Home = tonumber(score.Home) or 0,
		Away = tonumber(score.Away) or 0,
	}
end

local function PickOpeningScore(_seed: number)
	-- Designer flow: every unplayed tournament match starts visually at 0-0.
	-- The real score is revealed only after the match result is applied.
	return { Home = 0, Away = 0 }
end

local function PickMinute(seed: number): number
	local liveConfig = TournamentConfig.LiveMatch
	local minMinute = tonumber(liveConfig.MinMinute) or 85
	local maxMinute = tonumber(liveConfig.MaxMinute) or 90
	local range = math.max(1, maxMinute - minMinute + 1)
	return minMinute + ((math.floor(tonumber(seed) or 1) % range))
end

local function IsPlayerTeam(team): boolean
	return team and team.IsPlayer == true
end

local function GetOpponentTeam(match)
	if IsPlayerTeam(match.HomeTeam) then
		return match.AwayTeam
	end
	return match.HomeTeam
end

local function IsSameMatch(left, right): boolean
	if not left or not right then
		return false
	end

	local leftId = tostring(left.MatchId or "")
	local rightId = tostring(right.MatchId or "")
	if leftId ~= "" and rightId ~= "" then
		return leftId == rightId
	end

	return tonumber(left.RoundIndex) == tonumber(right.RoundIndex)
		and tonumber(left.MatchIndex) == tonumber(right.MatchIndex)
end

function TournamentQuery.GetCurrentRound(state)
	if type(state) ~= "table" then
		return TournamentConfig.RoundOrder[1]
	end

	return state.Rounds[state.CurrentRoundIndex] or TournamentConfig.RoundOrder[1]
end

function TournamentQuery.GetNextOpponent(state)
	local currentMatch = TournamentRules.GetCurrentPlayerMatch(state)
	if not currentMatch then
		return nil
	end

	return CloneTeam(GetOpponentTeam(currentMatch))
end

function TournamentQuery.BuildMatchContext(state)
	local currentRound = TournamentQuery.GetCurrentRound(state)
	local currentMatch = TournamentRules.GetCurrentPlayerMatch(state)
	if not currentMatch then
		return nil
	end

	local opponentTeam = CloneTeam(GetOpponentTeam(currentMatch))
	local playerTeam = CloneTeam(state.PlayerTeam)
	local contextSeed = (state.Seed or 1) + (state.CurrentRoundIndex * 17)
	local score = currentMatch.Score and CloneScore(currentMatch.Score) or PickOpeningScore(contextSeed)
	local minute = tonumber(currentMatch.Minute) or PickMinute(contextSeed)
	local rewardPreview = TournamentRewardCalculator.BuildRoundPreview({
		AreaId = tostring(state.AreaId or "Area01"),
		RoundId = tostring(currentRound.RoundId or "RoundOf16"),
		RoundIndex = tonumber(state.CurrentRoundIndex) or 1,
	})

	return {
		StateId = tostring(state.StateId or ""),
		CupId = tostring(state.CupId or ""),
		CupName = tostring(state.CupName or "Tournament Cup"),
		AreaId = tostring(state.AreaId or "Area01"),
		MatchId = tostring(currentMatch.MatchId or ""),
		MatchIndex = tonumber(currentMatch.MatchIndex) or 1,
		IsPlayerMatch = currentMatch.IsPlayerMatch == true,
		RoundId = tostring(currentRound.RoundId or "RoundOf16"),
		RoundName = tostring(currentRound.RoundName or "Round of 16"),
		RoundIndex = tonumber(state.CurrentRoundIndex) or 1,
		PlayerTeam = playerTeam,
		OpponentTeam = opponentTeam,
		CurrentScore = score,
		MatchMinute = minute,
		RewardPreview = rewardPreview,
		RewardWins = rewardPreview.RewardWins,
		RewardText = rewardPreview.RewardText,
		Intro = {
			AreaId = tostring(state.AreaId or "Area01"),
			HomeTeamName = playerTeam and playerTeam.DisplayName or "FC Rivrs",
			AwayTeamName = opponentTeam and opponentTeam.DisplayName or "FC Roblox",
			HomeScore = score.Home,
			AwayScore = score.Away,
			MatchMinute = minute,
			LeagueName = tostring(state.CupName or "Tournament Cup"),
			RoundName = tostring(currentRound.RoundName or "Round of 16"),
			RewardPreview = rewardPreview,
			RewardWins = rewardPreview.RewardWins,
			RewardText = rewardPreview.RewardText,
			HomeLogo = "",
			AwayLogo = "",
		},
	}
end

function TournamentQuery.BuildPreviewPayload(state)
	if type(state) ~= "table" then
		return nil
	end

	local currentRound = TournamentQuery.GetCurrentRound(state)
	local matchContext = TournamentQuery.BuildMatchContext(state)
	local currentPlayerMatch = TournamentRules.GetCurrentPlayerMatch(state)

	local roundsPayload = {}
	for roundIndex, roundDefinition in ipairs(state.Rounds or {}) do
		local matchesPayload = {}
		local matches = state.MatchesByRound[roundIndex] or {}
		local roundRewardPreview = TournamentRewardCalculator.BuildRoundPreview({
			AreaId = tostring(state.AreaId or "Area01"),
			RoundId = tostring(roundDefinition.RoundId or "RoundOf16"),
			RoundIndex = roundIndex,
		})
		for matchIndex, match in ipairs(matches) do
			local previewScore = CloneScore(match.Score)
			local previewMinute = match.Minute

			-- Important: the playable match preview score must be server-side and shared
			-- by bracket + MatchIntro. If Score is still nil for the current player match,
			-- expose the same 0-0 opening score from BuildMatchContext instead of forcing
			-- each client View to calculate its own fallback.
			if matchContext and IsSameMatch(match, currentPlayerMatch) and not previewScore then
				previewScore = CloneScore(matchContext.CurrentScore)
				previewMinute = matchContext.MatchMinute
			end

			matchesPayload[matchIndex] = {
				MatchId = match.MatchId,
				RoundId = match.RoundId,
				RoundIndex = match.RoundIndex,
				MatchIndex = match.MatchIndex,
				HomeTeam = CloneTeam(match.HomeTeam),
				AwayTeam = CloneTeam(match.AwayTeam),
				WinnerTeam = CloneTeam(match.WinnerTeam),
				Score = previewScore,
				IsPlayerMatch = match.IsPlayerMatch == true,
				IsLocked = match.IsLocked == true,
				Minute = previewMinute,
			}
		end

		roundsPayload[roundIndex] = {
			RoundId = roundDefinition.RoundId,
			RoundName = roundDefinition.RoundName,
			ShortName = roundDefinition.ShortName,
			MatchCount = roundDefinition.MatchCount,
			RewardPreview = roundRewardPreview,
			RewardWins = roundRewardPreview.RewardWins,
			RewardText = roundRewardPreview.RewardText,
			Matches = matchesPayload,
		}
	end

	return {
		StateId = tostring(state.StateId or ""),
		CupId = tostring(state.CupId or ""),
		CupName = tostring(state.CupName or "Tournament Cup"),
		AreaId = tostring(state.AreaId or "Area01"),
		Status = tostring(state.Status or "Active"),
		CurrentRoundIndex = tonumber(state.CurrentRoundIndex) or 1,
		CurrentRoundId = tostring(currentRound.RoundId or "RoundOf16"),
		CurrentRoundName = tostring(currentRound.RoundName or "Round of 16"),
		PlayerTeam = CloneTeam(state.PlayerTeam),
		OpponentTeam = matchContext and matchContext.OpponentTeam or nil,
		CurrentMatch = matchContext,
		Rounds = roundsPayload,
	}
end

return TournamentQuery
