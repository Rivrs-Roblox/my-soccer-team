--!strict
-- TournamentPolicy.luau
-- Pure guard rules for tournament state usage.

local TournamentRules = require(script.Parent.TournamentRules)

local TournamentPolicy = {}

function TournamentPolicy.CanStartMatch(state): boolean
	if type(state) ~= "table" then
		return false
	end

	if state.Status ~= "Active" then
		return false
	end

	local currentMatch = TournamentRules.GetCurrentPlayerMatch(state)
	return currentMatch ~= nil and currentMatch.WinnerTeam == nil
end

function TournamentPolicy.ShouldCreateNewCup(state): boolean
	if type(state) ~= "table" then
		return true
	end

	return state.Status == "Champion" or state.Status == "Lost"
end

return TournamentPolicy
