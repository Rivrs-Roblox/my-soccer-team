local Players = game:GetService("Players")

local PlayerTeamIdentity = {}

local DEFAULT_PLAYER_TEAM_NAME = "Player"
local DEFAULT_PLAYER_TEAM_LOGO = "rbxassetid://81212587492189"

local cachedThumbnailByUserId = {}

local function getLocalPlayer()
	return Players.LocalPlayer
end

function PlayerTeamIdentity.GetName(fallback)
	local player = getLocalPlayer()
	local name = player and tostring(player.Name or "") or ""
	if name ~= "" then
		return name
	end

	return tostring(fallback or DEFAULT_PLAYER_TEAM_NAME)
end

function PlayerTeamIdentity.GetThumbnail(fallback)
	local player = getLocalPlayer()
	if not player then
		return tostring(fallback or DEFAULT_PLAYER_TEAM_LOGO)
	end

	local userId = tonumber(player.UserId) or 0
	local cached = cachedThumbnailByUserId[userId]
	if type(cached) == "string" and cached ~= "" then
		return cached
	end

	local ok, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
		)
	end)

	if ok and type(thumbnail) == "string" and thumbnail ~= "" then
		cachedThumbnailByUserId[userId] = thumbnail
		return thumbnail
	end

	return tostring(fallback or DEFAULT_PLAYER_TEAM_LOGO)
end

function PlayerTeamIdentity.GetShortName(fallback)
	local name = PlayerTeamIdentity.GetName("")
	local code = ""

	for word in string.gmatch(string.upper(name), "%a+") do
		code ..= string.sub(word, 1, 1)
		if #code >= 3 then
			break
		end
	end

	if #code < 3 then
		local compact = string.upper((name:gsub("%W", "")))
		for index = 1, #compact do
			if #code >= 3 then
				break
			end
			code ..= string.sub(compact, index, index)
		end
	end

	if #code > 0 then
		while #code < 3 do
			code ..= "X"
		end
		return string.sub(code, 1, 3)
	end

	return tostring(fallback or "PLY")
end

return table.freeze(PlayerTeamIdentity)
