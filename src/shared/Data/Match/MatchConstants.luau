local MatchConstants = {
	DEFAULT_AREA_ID = "Area01",

	MAP_ROOT_NAME = "Map",
	BATTLE_ZONE_ROOT_NAME = "BattleZone",
	RUNTIME_FOLDER_NAME = "Runtime",

	PLAYER_SPAWN_NAME = "PlayerSpawn",
	PLAYER_PIVOTS_FOLDER_NAME = "PlayerPivots",
	COMPANION_PIVOTS_FOLDER_NAME = "CompanionPivots",
	ENEMIES_FOLDER_NAME = "Enemies",

	ENEMY_INSTANCE_NAMES = {
		[1] = "Enemy01",
		[2] = "Enemy02",
		[3] = "Enemy03",
		[4] = "Enemy04",
		[5] = "GoalKeeper",
	},

	TRANSITION_FADE_TIME = 0.35,
	POST_TELEPORT_DELAY = 0.15,
	TELEPORT_OFFSET = Vector3.new(0, 3, 0),

	ENTER_TRANSITION_TIMEOUT = 2.5,
	LEAVE_TRANSITION_TIMEOUT = 0.9,

	STEP_ADVANCE_DELAY = 0.85,
	MATCH_FINISH_DELAY = 0.45,

	QTE_RESPONSE_TIMEOUT = 3.0,
	QTE_CURSOR_TRAVEL_TIME = 0.9,

	QTE_TIER_MULTIPLIERS = {
		Red = 0.50,
		Yellow = 1.00,
		Green = 1.20,
	},
}

return table.freeze(MatchConstants)
