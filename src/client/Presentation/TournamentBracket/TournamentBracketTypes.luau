--!strict
-- TournamentBracketTypes.luau
-- Shared payload aliases for the TournamentBracket presentation layer.

export type TeamPayload = {
	TeamId: string,
	DisplayName: string,
	Name: string?,
	AssetFolderName: string?,
	AreaId: string?,
	IsPlayer: boolean?,
	Icon: string?,
	IconImage: string?,
	Logo: string?,
	LogoImage: string?,
	AssetId: string?,
}

export type ScorePayload = {
	Home: number?,
	Away: number?,
	Player: number?,
	Enemy: number?,
	Top: number?,
	Bottom: number?,
}

export type MatchPayload = {
	MatchId: string?,
	MatchIndex: number?,
	HomeTeam: TeamPayload?,
	AwayTeam: TeamPayload?,
	WinnerTeam: TeamPayload?,
	Score: ScorePayload?,
	CurrentScore: ScorePayload?,
	IsPlayerMatch: boolean?,
	IsLocked: boolean?,
	Minute: number?,
	MatchMinute: number?,
	RecommendedPower: number?,
	RequiredPower: number?,
	TargetPower: number?,
	RecommendedStats: any?,
	EnemySteps: any?,
	Steps: any?,
}

export type RoundPayload = {
	RoundId: string?,
	RoundName: string?,
	ShortName: string?,
	MatchCount: number?,
	Matches: { MatchPayload }?,
	RewardWins: number?,
	WinsReward: number?,
	ClaimWins: number?,
	RewardAmount: number?,
	CanClaim: boolean?,
	IsClaimed: boolean?,
	IsCompleted: boolean?,
}

export type TournamentPreviewPayload = {
	StateId: string?,
	CupId: string?,
	CupName: string?,
	AreaId: string?,
	Status: string?,
	CurrentRoundIndex: number?,
	CurrentRoundId: string?,
	CurrentRoundName: string?,
	PlayerTeam: TeamPayload?,
	OpponentTeam: TeamPayload?,
	CurrentMatch: MatchPayload?,
	Rounds: { RoundPayload }?,
	RecommendedPower: number?,
	RequiredPower: number?,
	TargetPower: number?,
	RecommendedStats: any?,
	EnemySteps: any?,
	AreaSteps: any?,
	RoundSteps: any?,
	MatchMinute: number?,
}

return nil
