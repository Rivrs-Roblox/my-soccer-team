--!strict
-- TournamentTypes.luau
-- Pure type definitions for the Tournament domain.

export type Team = {
	TeamId: string,
	DisplayName: string,
	AssetFolderName: string?,
	AreaId: string?,
	IsPlayer: boolean?,
}

export type Score = {
	Home: number,
	Away: number,
}

export type MatchNode = {
	MatchId: string,
	RoundId: string,
	RoundIndex: number,
	MatchIndex: number,
	HomeTeam: Team,
	AwayTeam: Team,
	WinnerTeam: Team?,
	Score: Score?,
	IsPlayerMatch: boolean,
	IsFinal: boolean?,
	IsLocked: boolean?,
	Minute: number?,
}

export type RoundDefinition = {
	RoundId: string,
	RoundName: string,
	ShortName: string,
	MatchCount: number,
}

export type TournamentState = {
	StateId: string,
	CupId: string,
	CupName: string,
	AreaId: string,
	Seed: number,
	Status: string,
	CurrentRoundIndex: number,
	PlayerTeam: Team,
	Rounds: { RoundDefinition },
	MatchesByRound: { [number]: { MatchNode } },
	CreatedAt: number?,
	UpdatedAt: number?,
}

export type IntroContext = {
	HomeTeamName: string,
	AwayTeamName: string,
	HomeScore: number,
	AwayScore: number,
	MatchMinute: number,
	LeagueName: string,
	RoundName: string,
	HomeLogo: string?,
	AwayLogo: string?,
}

export type MatchContext = {
	StateId: string,
	CupId: string,
	CupName: string,
	AreaId: string,
	RoundId: string,
	RoundName: string,
	RoundIndex: number,
	PlayerTeam: Team,
	OpponentTeam: Team,
	CurrentScore: Score,
	MatchMinute: number,
	Intro: IntroContext,
}

return nil
