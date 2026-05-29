--!strict
-- TeamLogoConfig.luau
-- Stores logo asset IDs for every team, organized by AreaId.
-- Used by TournamentBracketView to resolve Logo images for each team slot.
-- Key: exact team name (DisplayName / Name from payload).

local TeamLogoConfig = {

	Area01 = {  -- Brazil Zone
		["Amazonia Blaze"]    = "rbxassetid://84574704596472",
		["Bahia Cyclones"]    = "rbxassetid://105301374473712",
		["Carnival Reapers"]  = "rbxassetid://138491097970654",
		["Crimson Canaries"]  = "rbxassetid://129491931688792",
		["Favela Titans"]     = "rbxassetid://83555608767155",
		["Golden Macaws"]     = "rbxassetid://130152286379933",
		["Neon Jaguars"]      = "rbxassetid://85492351898066",
		["Palmeiras Nova"]    = "rbxassetid://85661051935773",
		["Rio Vortex FC"]     = "rbxassetid://135055345771479",
		["Samba Strikers"]    = "rbxassetid://101652323912826",
		["Shadow Capybaras"]  = "rbxassetid://134802381731881",
		["Solar Cobra FC"]    = "rbxassetid://98135386675090",
		["Thunder Toucans"]   = "rbxassetid://108848424471220",
		["Tropico United"]    = "rbxassetid://93960954223343",
		["Verde Inferno FC"]  = "rbxassetid://121930603916332",
	},

	Area02 = {  -- Japan Zone
		["Crimson Kitsune"]   = "rbxassetid://130387649328425",
		["Cyber Samurai FC"]  = "rbxassetid://108726194515838",
		["Dragon Pulse"]      = "rbxassetid://112463932992425",
		["Fuji Storm"]        = "rbxassetid://73341367131893",
		["Hokkaido Wolves"]   = "rbxassetid://117885591197751",
		["Kurohana United"]   = "rbxassetid://79398240812396",
		["Neo Kyoto FC"]      = "rbxassetid://128249934122618",
		["Oni Tempest"]       = "rbxassetid://106797543989064",
		["Osaka Comets"]      = "rbxassetid://132453413527257",
		["Rising Sun FC"]     = "rbxassetid://134921940037137",
		["Ronin Eclipse"]     = "rbxassetid://103057213931818",
		["Sakura Blades"]     = "rbxassetid://96779385351986",
		["Shogun Eleven"]     = "rbxassetid://75589442960854",
		["Tokyo Voltage"]     = "rbxassetid://129876831623082",
		["Yokai Strikers"]    = "rbxassetid://72680174693947",
	},

	Area03 = {  -- USA Zone
		["Astro Kings"]       = "rbxassetid://73885844066548",
		["California Waves"]  = "rbxassetid://122862906851474",
		["Chicago Rampage"]   = "rbxassetid://122768527220906",
		["Crimson Patriots"]  = "rbxassetid://78962173404392",
		["Golden Frontier FC"]= "rbxassetid://115583865125472",
		["Liberty Hawks"]     = "rbxassetid://106772697587091",
		["Miami Cyclone"]     = "rbxassetid://96508044549082",
		["Nevada Outlaws"]    = "rbxassetid://79095390836948",
		["New York Blizzard"] = "rbxassetid://75953806434357",
		["Pacific Rhinos"]    = "rbxassetid://108517397252550",
		["Steel Phoenix FC"]  = "rbxassetid://106789617324315",
		["Texas Vipers"]      = "rbxassetid://118744640551280",
		["Thunder Canyon FC"] = "rbxassetid://90054084353627",
		["Titan Rockets"]     = "rbxassetid://95415557940269",
		["Vegas Mirage"]      = "rbxassetid://74467968909391",
	},

	Area04 = {  -- Italy Zone
		["Aurelio Strikers"]  = "rbxassetid://83105863923337",
		["Black Basilica FC"] = "rbxassetid://72794835865187",
		["Crimson Venezia"]   = "rbxassetid://91091179897369",
		["Fiora Titans"]      = "rbxassetid://110314838298456",
		["Gladiator XI"]      = "rbxassetid://102352544758444",
		["Inferno Lazio"]     = "rbxassetid://109975603211454",
		["Cobalt Roma"]       = "rbxassetid://87314431670916",
		["Milano Royale"]     = "rbxassetid://140170561563173",
		["Napoli Tempesta"]   = "rbxassetid://119777267066151",
		["Roman Eclipse"]     = "rbxassetid://80108575495307",
		["Sicilian Storm"]    = "rbxassetid://101901844345007",
		["Torino Phantom"]    = "rbxassetid://114403183070047",
		["Tuscan Wolves"]     = "rbxassetid://71057152796389",
		["Venice Tide FC"]    = "rbxassetid://139927630434219",
		["Verona Vipers"]     = "rbxassetid://71114416502463",
	},

	Area05 = {  -- England Zone
		["Albion Knights"]      = "rbxassetid://81892505321285",
		["Blackmoor Rovers"]    = "rbxassetid://126294493207305",
		["Bristol Guardians"]   = "rbxassetid://86679185537531",
		["Crimson Lions"]       = "rbxassetid://76426285740719",
		["Eastchester FC"]      = "rbxassetid://133378293762121",
		["Emerald Fortress FC"] = "rbxassetid://103854725264490",
		["Iron Crown FC"]       = "rbxassetid://99409028956964",
		["London Ravens"]       = "rbxassetid://104473719604857",
		["Manchester Fury"]     = "rbxassetid://113961264889000",
		["Northvale Athletic"]  = "rbxassetid://111488099485608",
		["Oxford Phantoms"]     = "rbxassetid://84733805508427",
		["Royal Howlers"]       = "rbxassetid://95767316017322",
		["Silver Thames FC"]    = "rbxassetid://125374608734700",
		["Stormbridge United"]  = "rbxassetid://80900779051721",
		["Winchester Wolves"]   = "rbxassetid://100234116836626",
	},
}


local TEAM_SHORT_NAMES = {
	Player = {
		["FC Rivrs"] = "RIV",
		["Rivrs FC"] = "RIV",
	},

	Area01 = {
		["Amazonia Blaze"] = "AMB",
		["Bahia Cyclones"] = "BAH",
		["Carnival Reapers"] = "CAR",
		["Crimson Canaries"] = "CRI",
		["Favela Titans"] = "FAV",
		["Golden Macaws"] = "GOL",
		["Neon Jaguars"] = "NEO",
		["Palmeiras Nova"] = "PAL",
		["Rio Vortex FC"] = "RIO",
		["Samba Strikers"] = "SAM",
		["Shadow Capybaras"] = "SHA",
		["Solar Cobra FC"] = "SOL",
		["Thunder Toucans"] = "THU",
		["Tropico United"] = "TRO",
		["Verde Inferno FC"] = "VER",
	},

	Area02 = {
		["Crimson Kitsune"] = "CKI",
		["Cyber Samurai FC"] = "CYB",
		["Dragon Pulse"] = "DRA",
		["Fuji Storm"] = "FUJ",
		["Hokkaido Wolves"] = "HOK",
		["Kurohana United"] = "KUR",
		["Neo Kyoto FC"] = "NEO",
		["Oni Tempest"] = "ONI",
		["Osaka Comets"] = "OSA",
		["Rising Sun FC"] = "RIS",
		["Ronin Eclipse"] = "RON",
		["Sakura Blades"] = "SAK",
		["Shogun Eleven"] = "SHO",
		["Tokyo Voltage"] = "TOK",
		["Yokai Strikers"] = "YOK",
	},

	Area03 = {
		["Astro Kings"] = "AST",
		["California Waves"] = "CAL",
		["Chicago Rampage"] = "CHI",
		["Crimson Patriots"] = "CPA",
		["Golden Frontier FC"] = "GFF",
		["Liberty Hawks"] = "LIB",
		["Miami Cyclone"] = "MIA",
		["Nevada Outlaws"] = "NEV",
		["New York Blizzard"] = "NYB",
		["Pacific Rhinos"] = "PAC",
		["Steel Phoenix FC"] = "SPX",
		["Texas Vipers"] = "TEX",
		["Thunder Canyon FC"] = "TCF",
		["Titan Rockets"] = "TIT",
		["Vegas Mirage"] = "VEG",
	},

	Area04 = {
		["Aurelio Strikers"] = "AUR",
		["Black Basilica FC"] = "BBF",
		["Crimson Venezia"] = "VEN",
		["Fiora Titans"] = "FIO",
		["Gladiator XI"] = "GLA",
		["Inferno Lazio"] = "LAZ",
		["Cobalt Roma"] = "ROM",
		["Milano Royale"] = "MIL",
		["Napoli Tempesta"] = "NAP",
		["Roman Eclipse"] = "REC",
		["Sicilian Storm"] = "SIC",
		["Torino Phantom"] = "TOR",
		["Tuscan Wolves"] = "TUS",
		["Venice Tide FC"] = "VTF",
		["Verona Vipers"] = "VRN",
	},

	Area05 = {
		["Albion Knights"] = "ALB",
		["Blackmoor Rovers"] = "BLA",
		["Bristol Guardians"] = "BRI",
		["Crimson Lions"] = "LIO",
		["Eastchester FC"] = "EAS",
		["Emerald Fortress FC"] = "EME",
		["Iron Crown FC"] = "IRO",
		["London Ravens"] = "LON",
		["Manchester Fury"] = "MAN",
		["Northvale Athletic"] = "NOR",
		["Oxford Phantoms"] = "OXF",
		["Royal Howlers"] = "ROY",
		["Silver Thames FC"] = "SIL",
		["Stormbridge United"] = "STO",
		["Winchester Wolves"] = "WIN",
	},
}

local function BuildFallbackShortName(teamName: string): string
	local cleanedWords = {}
	for word in string.gmatch(string.upper(teamName or ""), "%a+") do
		if word ~= "FC" and word ~= "UNITED" then
			table.insert(cleanedWords, word)
		end
	end

	if #cleanedWords == 0 then
		return "TBD"
	end

	if #cleanedWords == 1 then
		return string.sub(cleanedWords[1], 1, 3)
	end

	local code = ""
	for _, word in ipairs(cleanedWords) do
		code ..= string.sub(word, 1, 1)
		if #code >= 3 then
			break
		end
	end

	if #code < 3 then
		local primary = cleanedWords[1]
		for index = 2, #primary do
			if #code >= 3 then
				break
			end
			code ..= string.sub(primary, index, index)
		end
	end

	while #code < 3 do
		code ..= "X"
	end

	return string.sub(code, 1, 3)
end

--- Returns the logo asset ID for a given team name within an area.
--- @param areaId   string  e.g. "Area01"
--- @param teamName string  exact DisplayName / Name of the team
--- @return string  asset URL or empty string
function TeamLogoConfig.GetTeamLogo(areaId: string, teamName: string): string
	local areaMap = TeamLogoConfig[areaId]
	if type(areaMap) ~= "table" then
		return ""
	end
	return tostring(areaMap[teamName] or "")
end


--- Returns a 3-letter broadcast code for a given team name.
--- Primary source is the explicit table above; generated fallback is only for safety.
--- @param areaId   string  e.g. "Area01"
--- @param teamName string  exact DisplayName / Name of the team
--- @return string  3-letter team code
function TeamLogoConfig.GetTeamShortName(areaId: string, teamName: string): string
	local playerMap = TEAM_SHORT_NAMES.Player
	local playerCode = playerMap and playerMap[teamName]
	if type(playerCode) == "string" and playerCode ~= "" then
		return playerCode
	end

	local areaMap = TEAM_SHORT_NAMES[areaId]
	local code = type(areaMap) == "table" and areaMap[teamName] or nil
	if type(code) == "string" and code ~= "" then
		return code
	end

	return BuildFallbackShortName(tostring(teamName or ""))
end

--- Returns the player-team broadcast code.
--- @return string
function TeamLogoConfig.GetPlayerShortName(): string
	return "RIV"
end

--- Returns the player-team logo asset.
--- @return string
function TeamLogoConfig.GetPlayerLogo(): string
	return "rbxassetid://81212587492189"
end

--- Returns a random logo from the given area's pool (for player team display).
--- The result is deterministic per (areaId, seed) pair so callers can cache it.
--- @param areaId string
--- @param seed   number?  optional seed for reproducibility (e.g. os.clock())
--- @return string  asset URL or empty string
function TeamLogoConfig.GetRandomAreaLogo(areaId: string, seed: number?): string
	local areaMap = TeamLogoConfig[areaId]
	if type(areaMap) ~= "table" then
		return ""
	end

	local logos: { string } = {}
	for _, assetId in pairs(areaMap) do
		table.insert(logos, assetId)
	end

	if #logos == 0 then
		return ""
	end

	local rng = Random.new(math.floor(seed or os.clock() * 1000) % 2147483647)
	return logos[rng:NextInteger(1, #logos)]
end

return table.freeze(TeamLogoConfig)
