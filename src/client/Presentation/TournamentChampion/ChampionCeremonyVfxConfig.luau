--!strict
-- ChampionCeremonyVfxConfig.luau
-- Visual-only tuning for the tournament champion ceremony.
-- Keeps league decal mapping separate from the cinematic controller.

local ChampionCeremonyVfxConfig = {}

ChampionCeremonyVfxConfig.LeagueIconByKey = {
	Amateur = "rbxassetid://81513673044770",
	Legend = "rbxassetid://127107003395969",
	Pro = "rbxassetid://124578367665905",
	Street = "rbxassetid://124093208935109",
	World = "rbxassetid://85033261558330",
}

ChampionCeremonyVfxConfig.AreaLeagueKeyById = {
	Area01 = "Street",
	Area02 = "Amateur",
	Area03 = "Pro",
	Area04 = "World",
	Area05 = "Legend",
}

ChampionCeremonyVfxConfig.IntensityByAreaId = {
	Area01 = {
		ConfettiBurst = 90,
		ConfettiRate = 24,
		SparkleBurst = 28,
		SparkleRate = 10,
		GoldDustBurst = 34,
		GoldDustRate = 10,
		AnchorRadius = 13,
		AnchorHeight = 10,
		EmitterLifetime = 5.2,
	},
	Area02 = {
		ConfettiBurst = 130,
		ConfettiRate = 36,
		SparkleBurst = 44,
		SparkleRate = 16,
		GoldDustBurst = 54,
		GoldDustRate = 18,
		AnchorRadius = 15,
		AnchorHeight = 11,
		EmitterLifetime = 5.6,
	},
	Area03 = {
		ConfettiBurst = 175,
		ConfettiRate = 48,
		SparkleBurst = 66,
		SparkleRate = 24,
		GoldDustBurst = 78,
		GoldDustRate = 26,
		AnchorRadius = 17,
		AnchorHeight = 12,
		EmitterLifetime = 5.9,
	},
	Area04 = {
		ConfettiBurst = 230,
		ConfettiRate = 62,
		SparkleBurst = 92,
		SparkleRate = 34,
		GoldDustBurst = 112,
		GoldDustRate = 38,
		AnchorRadius = 20,
		AnchorHeight = 13,
		EmitterLifetime = 6.2,
	},
	Area05 = {
		ConfettiBurst = 310,
		ConfettiRate = 86,
		SparkleBurst = 130,
		SparkleRate = 50,
		GoldDustBurst = 160,
		GoldDustRate = 56,
		AnchorRadius = 23,
		AnchorHeight = 14,
		EmitterLifetime = 6.6,
	},
}

ChampionCeremonyVfxConfig.DefaultIntensity = ChampionCeremonyVfxConfig.IntensityByAreaId.Area01

function ChampionCeremonyVfxConfig.GetLeagueKey(areaId: any): string
	return ChampionCeremonyVfxConfig.AreaLeagueKeyById[tostring(areaId or "Area01")] or "Street"
end

function ChampionCeremonyVfxConfig.GetLeagueIcon(areaId: any): string?
	local leagueKey = ChampionCeremonyVfxConfig.GetLeagueKey(areaId)
	return ChampionCeremonyVfxConfig.LeagueIconByKey[leagueKey]
end

function ChampionCeremonyVfxConfig.GetIntensity(areaId: any): { [string]: number }
	return ChampionCeremonyVfxConfig.IntensityByAreaId[tostring(areaId or "Area01")]
		or ChampionCeremonyVfxConfig.DefaultIntensity
end

return table.freeze(ChampionCeremonyVfxConfig)
