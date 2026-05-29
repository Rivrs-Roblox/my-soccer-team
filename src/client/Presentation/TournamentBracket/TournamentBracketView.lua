--!strict
-- TournamentBracketView.lua
-- Artist ScreenGui binder for the tournament preview UI.
-- Layout belongs to StarterGui/GUIMatchBattle/Tournament. This view only writes data and visibility state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local TeamLogoConfig = require(ReplicatedStorage.Shared.Data.TeamLogoConfig)

local TournamentBracketView = {}
TournamentBracketView.__index = TournamentBracketView

local ROOT_GUI_NAME = "GUIMatchBattle"
local TOURNAMENT_ROOT_NAME = "Tournament"
local START_HITBOX_NAME = "__TournamentStartHitbox"
local CLOSE_HITBOX_NAME = "__TournamentCloseHitbox"
local CHAMPION_PLACEHOLDER_NAME = "__ChampionPlaceholder"
local DEFAULT_REWARD_WINS = 15
local TOURNAMENT_DISPLAY_ORDER = 260
local DEBUG_UI_LIFECYCLE = false
local SIMPLIFIED_MATCH_BRACKET_UI = true

-- Bracket progression animation timing
local ACTIVE_OUTLINE_ROTATION_SPEED = 260 -- degrees per second
local SCORE_ANIMATION_DURATION = 0.75
local DAMAGE_ANIMATION_DURATION = 0.65
local PROMOTION_ANIMATION_DURATION = 0.55
local RESULT_REVEAL_PAUSE = 0.12
local LOSER_BG_COLOR      = Color3.fromRGB(90, 18, 22)
local LOSER_STROKE_COLOR  = Color3.fromRGB(150, 40, 40)
local LOSER_DIM_TRANSPARENCY = 0.42

-- Runtime layer normalization. Artist layout remains source of truth; script only
-- enforces stable draw order after show/hide/match-return cycles.
local Z_ROOT = 1
local Z_BACKGROUND = 1
local Z_CONTAINER = 10
local Z_CONNECTOR = 15
local Z_CARD_BACKGROUND = 20
local Z_VISUAL = 30
local Z_BADGE = 35
local Z_START = 40
local Z_START_BACKGROUND = 45
local Z_START_CONTENT = 70
local Z_HITBOX = 130
local Z_CLOSE_HITBOX = 160

local LEAGUE_ICON_BY_KEY = {
	Amateur = "rbxassetid://81513673044770",
	Legend = "rbxassetid://127107003395969",
	Pro = "rbxassetid://124578367665905",
	Street = "rbxassetid://124093208935109",
	World = "rbxassetid://85033261558330",
}

local AREA_LEAGUE_KEY_BY_ID = {
	Area01 = "Street",
	Area02 = "Amateur",
	Area03 = "Pro",
	Area04 = "World",
	Area05 = "Legend",
}

local STAT_STORE_KEYS = {
	Wins = "Wins",
	Rebirths = "Rebirth",
	Passing = "Pass",
	Shooting = "Shoot",
	Dribbling = "Dribble",
}

local ROUND_REWARD_TITLES = {
	[1] = "ROUND OF 16",
	[2] = "QUARTER FINALS",
	[3] = "SEMI FINALS",
	[4] = "FINAL",
}

local LEADERSTAT_ALIASES = {
	Wins = { "Wins", "Win" },
	Rebirths = { "Rebirths", "Rebirth" },
	Passing = { "Passing", "Pass" },
	Shooting = { "Shooting", "Shoot" },
	Dribbling = { "Dribbling", "Dribble" },
}

local LEFT_ROUND_PATHS = {
	[1] = {
		{ "Round1", "1", "Top" },
		{ "Round1", "1", "Bottom" },
		{ "Round1", "2", "Top" },
		{ "Round1", "2", "Bottom" },
		{ "Round1", "3", "Top" },
		{ "Round1", "3", "Bottom" },
		{ "Round1", "4", "Top" },
		{ "Round1", "4", "Bottom" },
	},
	[2] = {
		{ "Round2", "1", "Top" },
		{ "Round2", "1", "Bottom" },
		{ "Round2", "2", "Top" },
		{ "Round2", "2", "Bottom" },
	},
	[3] = {
		{ "Round3", "Top" },
		{ "Round3", "Bottom" },
	},
	[4] = {
		{ "Round4" },
	},
}

local StoreResolved = false
local StoreCache: any = nil

local function GetRoduxStore()
	if StoreResolved then
		return StoreCache
	end

	StoreResolved = true

	local ok, store = pcall(function()
		return require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
	end)

	if ok then
		StoreCache = store
	else
		StoreCache = nil
	end

	return StoreCache
end

local function IsTable(value): boolean
	return type(value) == "table"
end

local function DebugLog(message: string)
	if DEBUG_UI_LIFECYCLE then
		print("[TournamentBracketView] " .. message)
	end
end

local function DisconnectAll(connections: { RBXScriptConnection })
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)
end

local function FindChild(parent: Instance?, name: string): Instance?
	if not parent then
		return nil
	end

	return parent:FindFirstChild(name)
end

local function FindPath(root: Instance?, path: { string }): Instance?
	local current = root

	for _, name in ipairs(path) do
		current = FindChild(current, name)
		if not current then
			return nil
		end
	end

	return current
end

local function FindStartRoot(root: Instance?): Instance?
	if not root then
		return nil
	end
	return FindChild(root, "Start") or FindPath(root, { "RightFrame", "Start" })
end

local function FindLeagueRoot(root: Instance?): Instance?
	if not root then
		return nil
	end
	return FindChild(root, "League") or FindPath(root, { "RightFrame", "League" })
end

local function AsGuiObject(instance: Instance?): GuiObject?
	if instance and instance:IsA("GuiObject") then
		return instance
	end

	return nil
end

local function AsTextLabel(instance: Instance?): TextLabel?
	if instance and instance:IsA("TextLabel") then
		return instance
	end

	return nil
end

local function AsImageObject(instance: Instance?): GuiObject?
	if instance and (instance:IsA("ImageLabel") or instance:IsA("ImageButton")) then
		return instance :: any
	end

	return nil
end

local function AsScreenGui(instance: Instance?): ScreenGui?
	if instance and instance:IsA("ScreenGui") then
		return instance
	end

	return nil
end

local function SetVisible(instance: Instance?, visible: boolean)
	local object = AsGuiObject(instance)
	if object then
		object.Visible = visible
	end
end

local function SetText(instance: Instance?, text: string)
	local label = AsTextLabel(instance)
	if label then
		label.Text = text
	end
end

local function SetImageIfProvided(instance: Instance?, image: string?)
	local imageValue = tostring(image or "")
	if imageValue == "" then
		return
	end

	local imageObject = AsImageObject(instance)
	if imageObject then
		(imageObject :: any).Image = imageValue
		imageObject.Visible = true
	end
end

local function SetLogoVisible(instance: Instance?, visible: boolean)
	local imageObject = AsImageObject(instance)
	if imageObject then
		imageObject.Visible = visible
	end
end

local function ParseCompactNumberText(text: string): number?
	local cleaned = string.lower(text)
	cleaned = cleaned:gsub(",", "")
	cleaned = cleaned:gsub("%s+", "")

	local numberPart, suffix = cleaned:match("^([%-%.%d]+)(%a*)$")
	local value = tonumber(numberPart)
	if value == nil then
		return nil
	end

	if suffix == "k" then
		return value * 1_000
	elseif suffix == "m" then
		return value * 1_000_000
	elseif suffix == "b" then
		return value * 1_000_000_000
	end

	return value
end

local function ReadValueObject(instance: Instance?): number?
	if not instance then
		return nil
	end

	if instance:IsA("IntValue") or instance:IsA("NumberValue") then
		return tonumber(instance.Value)
	end

	if instance:IsA("StringValue") then
		return ParseCompactNumberText(instance.Value)
	end

	return nil
end

local function TrimDecimalZeros(text: string): string
	text = text:gsub("(%..-)0+$", "%1")
	text = text:gsub("%.$", "")
	return text
end

local function FormatCompactNumber(value: number?): string
	local amount = tonumber(value) or 0
	local absAmount = math.abs(amount)

	if absAmount >= 1_000_000_000 then
		return TrimDecimalZeros(string.format("%.3f", amount / 1_000_000_000)) .. "b"
	elseif absAmount >= 1_000_000 then
		return TrimDecimalZeros(string.format("%.3f", amount / 1_000_000)) .. "m"
	elseif absAmount >= 1_000 then
		return TrimDecimalZeros(string.format("%.3f", amount / 1_000)) .. "k"
	end

	return tostring(math.floor(amount))
end

local function FormatPlainNumber(value: number?): string
	return tostring(math.floor(tonumber(value) or 0))
end

local function StableDrawScoreFromParts(parts: { string }): number
	local seedText = table.concat(parts, "|")
	local hash = 0

	for index = 1, #seedText do
		hash = (hash + string.byte(seedText, index) * index) % 9973
	end

	return (hash % 3) + 1
end

local function GetTeamName(team, fallback: string): string
	if not IsTable(team) then
		return fallback
	end

	local name = tostring(team.DisplayName or team.Name or "")
	if name == "" then
		return fallback
	end

	return name
end

local function GetTeamId(team): string
	if not IsTable(team) then
		return ""
	end

	return tostring(team.TeamId or "")
end

local function HasTeam(team): boolean
	return IsTable(team) and GetTeamName(team, "") ~= ""
end

local function IsPlayerTeam(team): boolean
	return IsTable(team) and (team.IsPlayer == true or tostring(team.TeamId or "") == "Player")
end

local function IsWinner(match, team): boolean
	if not IsTable(match) or not IsTable(team) or not IsTable(match.WinnerTeam) then
		return false
	end

	local winnerTeamId = GetTeamId(match.WinnerTeam)
	return winnerTeamId ~= "" and winnerTeamId == GetTeamId(team)
end

local function GetTeamIcon(team): string
	if not IsTable(team) then
		return ""
	end

	return tostring(team.Icon or team.IconImage or team.Logo or team.LogoImage or team.AssetId or "")
end

local function ResolveAreaId(payload, currentMatch, team): string
	if IsTable(payload) and tostring(payload.AreaId or "") ~= "" then
		return tostring(payload.AreaId)
	end

	if IsTable(currentMatch) and tostring(currentMatch.AreaId or "") ~= "" then
		return tostring(currentMatch.AreaId)
	end

	if IsTable(team) and tostring(team.AreaId or "") ~= "" then
		return tostring(team.AreaId)
	end

	return "Area01"
end

local function ResolveTournamentTeamLogo(team, payload, currentMatch, playerLogoCache: string?): string
	if IsPlayerTeam(team) then
		return "rbxassetid://81212587492189"
	end

	local directLogo = GetTeamIcon(team)
	if directLogo ~= "" then
		return directLogo
	end

	if not HasTeam(team) then
		return ""
	end

	local areaId = ResolveAreaId(payload, currentMatch, team)
	return TeamLogoConfig.GetTeamLogo(areaId, GetTeamName(team, ""))
end

local function GetActualScoreValue(match, rowIndex: number): number?
	if not IsTable(match) or not IsTable(match.Score) then
		return nil
	end

	if rowIndex == 1 then
		return tonumber(match.Score.Home or match.Score.Player or match.Score.Top)
	end

	return tonumber(match.Score.Away or match.Score.Enemy or match.Score.Bottom)
end

local function GetScoreText(match, rowIndex: number): string
	local value = GetActualScoreValue(match, rowIndex)
	if value == nil then
		return ""
	end

	return tostring(value)
end

local function GetRoundRewardWins(round): number
	if IsTable(round) then
		local reward = tonumber(round.RewardWins)
			or tonumber(round.WinsReward)
			or tonumber(round.ClaimWins)
			or tonumber(round.RewardAmount)

		if reward ~= nil then
			return reward
		end
	end

	return DEFAULT_REWARD_WINS
end

local function GetMatchStepsFromConfig(areaId: string, roundId: string?)
	local ok, MatchAreaConfig = pcall(function()
		return require(ReplicatedStorage.Shared.Data.Match.MatchAreaConfig)
	end)

	if not ok or type(MatchAreaConfig) ~= "table" then
		return nil
	end

	local areaConfig = MatchAreaConfig[areaId] or MatchAreaConfig.Area01
	if type(areaConfig) ~= "table" then
		return nil
	end

	local resolvedRoundId = tostring(roundId or "")
	if type(areaConfig.RoundEnemySteps) == "table" and resolvedRoundId ~= "" then
		return areaConfig.RoundEnemySteps[resolvedRoundId]
	end

	return areaConfig.EnemySteps
end

local function GetStepValue(steps, index: number): number?
	if not IsTable(steps) then
		return nil
	end

	local step = steps[index]
	if IsTable(step) then
		return tonumber(step.Value or step.RequiredPower or step.Power)
	end

	return tonumber(step)
end

local function ResolveLeagueKeyFromText(value: any): string?
	local text = string.lower(tostring(value or ""))
	if text == "" then
		return nil
	end

	if text:find("area01", 1, true) or text:find("brazil", 1, true) or text:find("street", 1, true) then
		return "Street"
	elseif text:find("area02", 1, true) or text:find("japan", 1, true) or text:find("amateur", 1, true) then
		return "Amateur"
	elseif text:find("area03", 1, true) or text:find("usa", 1, true) or text:find("pro league", 1, true) or text == "pro" then
		return "Pro"
	elseif text:find("area04", 1, true) or text:find("italy", 1, true) or text:find("world", 1, true) then
		return "World"
	elseif text:find("area05", 1, true) or text:find("england", 1, true) or text:find("legend", 1, true) then
		return "Legend"
	end

	return nil
end

local function ResolveLeagueIcon(payload): string
	local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}

	local directAreaId = tostring(currentMatch.AreaId or payload.AreaId or "")
	if AREA_LEAGUE_KEY_BY_ID[directAreaId] then
		return LEAGUE_ICON_BY_KEY[AREA_LEAGUE_KEY_BY_ID[directAreaId]]
	end

	local candidates = {
		payload.LeagueKey,
		payload.LeagueId,
		payload.LeagueName,
		payload.CupKey,
		payload.CupId,
		payload.CupName,
		payload.ZoneName,
		payload.AreaId,
		currentMatch.LeagueKey,
		currentMatch.LeagueId,
		currentMatch.LeagueName,
		currentMatch.CupKey,
		currentMatch.CupId,
		currentMatch.CupName,
		currentMatch.ZoneName,
		currentMatch.AreaId,
	}

	for _, candidate in ipairs(candidates) do
		local key = ResolveLeagueKeyFromText(candidate)
		if key then
			return LEAGUE_ICON_BY_KEY[key]
		end
	end

	return LEAGUE_ICON_BY_KEY.Street
end

local function GetPreviewLeagueText(payload): string
	local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}
	return tostring(
		payload.LeagueName
			or payload.CupName
			or payload.ZoneName
			or payload.AreaId
			or currentMatch.LeagueName
			or currentMatch.CupName
			or currentMatch.ZoneName
			or currentMatch.AreaId
			or ""
	)
end

local function GetPreviewRoundText(payload, match): string
	local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}
	return tostring(
		(IsTable(match) and (match.RoundName or match.RoundId))
			or currentMatch.RoundName
			or currentMatch.RoundId
			or payload.CurrentRoundName
			or payload.CurrentRoundId
			or payload.CurrentRoundIndex
			or ""
	)
end

local function ResolvePreviewDrawScore(payload, match): number
	local homeTeam = IsTable(match) and match.HomeTeam or nil
	local awayTeam = IsTable(match) and match.AwayTeam or nil

	return StableDrawScoreFromParts({
		GetPreviewLeagueText(payload),
		GetPreviewRoundText(payload, match),
		GetTeamName(homeTeam, "FC Rivrs"),
		GetTeamName(awayTeam, "Opponent FC"),
	})
end

local function ShouldUsePreviewDrawScore(match): boolean
	if not IsTable(match) then
		return false
	end

	local homeTeam = match.HomeTeam
	local awayTeam = match.AwayTeam
	if not IsPlayerTeam(homeTeam) and not IsPlayerTeam(awayTeam) then
		return false
	end

	if IsTable(match.WinnerTeam) or match.IsCompleted == true or match.Completed == true then
		return false
	end

	return true
end

local function GetPreviewScoreText(payload, match, rowIndex: number): string
	local scoreText = GetScoreText(match, rowIndex)
	if scoreText ~= "" then
		return scoreText
	end

	local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}
	local currentScore = currentMatch.CurrentScore or currentMatch.Score or payload.CurrentScore
	if IsTable(currentScore) then
		local value = rowIndex == 1
			and tonumber(currentScore.Home or currentScore.Player or currentScore.Top)
			or tonumber(currentScore.Away or currentScore.Enemy or currentScore.Bottom)
		if value ~= nil then
			return tostring(value)
		end
	end

	if IsTable(match) and HasTeam(rowIndex == 1 and match.HomeTeam or match.AwayTeam) then
		return "0"
	end

	return ""
end


local function GetRecommendedStats(payload)
	local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}
	local recommendedStats = currentMatch.RecommendedStats or payload.RecommendedStats

	if IsTable(recommendedStats) then
		local passing = tonumber(recommendedStats.Passing or recommendedStats.Pass)
		local dribbling = tonumber(recommendedStats.Dribbling or recommendedStats.Dribble)
		local shooting = tonumber(recommendedStats.Shooting or recommendedStats.Shoot)

		if passing ~= nil or dribbling ~= nil or shooting ~= nil then
			local fallback = tonumber(recommendedStats.Value or recommendedStats.Power) or 0
			return {
				Passing = passing or fallback,
				Dribbling = dribbling or fallback,
				Shooting = shooting or fallback,
			}
		end
	end

	local steps = currentMatch.EnemySteps or currentMatch.Steps or payload.EnemySteps or payload.AreaSteps or payload.RoundSteps

	if not IsTable(steps) then
		local areaId = tostring(currentMatch.AreaId or payload.AreaId or "Area01")
		local roundId = tostring(currentMatch.RoundId or payload.CurrentRoundId or "")
		steps = GetMatchStepsFromConfig(areaId, roundId)
	end

	local qte4 = GetStepValue(steps, 4) or 0
	local qte5 = GetStepValue(steps, 5) or qte4

	return {
		Passing = qte4,
		Dribbling = qte4,
		Shooting = qte5,
	}
end

local function FindFirstGuiButton(root: Instance?): GuiButton?
	if not root then
		return nil
	end

	if root:IsA("GuiButton") then
		return root
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			return descendant
		end
	end

	return nil
end

local function ConfigureStartHitbox(button: TextButton, startObject: GuiObject)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Active = true
	button.Selectable = true
	button.AnchorPoint = startObject.AnchorPoint
	button.Position = startObject.Position
	button.Size = startObject.Size
	button.Rotation = startObject.Rotation
	button.ZIndex = Z_HITBOX
end

local function EnsureStartHitbox(startRoot: Instance?): GuiButton?
	local startObject = AsGuiObject(startRoot)
	if not startObject then
		return nil
	end

	-- IMPORTANT: do not parent the click hitbox inside RightFrame.Start.
	-- The artist Start frame contains a UIListLayout named "List"; adding a
	-- full-size TextButton as its child makes Roblox include the hitbox in that
	-- layout, which pushes/clips the START MATCH text and trophy icon.
	-- Keep the invisible click proxy as a sibling under RightFrame instead.
	local parentObject = AsGuiObject(startObject.Parent)
	if not parentObject then
		return nil
	end

	local staleChild = startObject:FindFirstChild(START_HITBOX_NAME)
	if staleChild then
		staleChild:Destroy()
	end

	local existing = parentObject:FindFirstChild(START_HITBOX_NAME)
	if existing and existing:IsA("TextButton") then
		ConfigureStartHitbox(existing, startObject)
		return existing
	end

	local button = Instance.new("TextButton")
	button.Name = START_HITBOX_NAME
	ConfigureStartHitbox(button, startObject)
	button.Parent = parentObject

	return button
end

local function EnsureCloseHitbox(closeRoot: Instance?): GuiButton?
	local closeObject = AsGuiObject(closeRoot)
	if not closeObject then
		return nil
	end

	local existing = closeObject:FindFirstChild(CLOSE_HITBOX_NAME)
	if existing and existing:IsA("TextButton") then
		existing.Active = true
		existing.Selectable = true
		existing.ZIndex = Z_CLOSE_HITBOX
		return existing
	end

	local button: GuiButton? = nil
	if closeObject:IsA("GuiButton") then
		button = closeObject :: GuiButton
	else
		button = FindFirstGuiButton(closeObject)
	end

	if button then
		button.Active = true
		button.Selectable = true
		button.ZIndex = math.max(button.ZIndex, Z_CLOSE_HITBOX)
		return button
	end

	local hitbox = Instance.new("TextButton")
	hitbox.Name = CLOSE_HITBOX_NAME
	hitbox.BackgroundTransparency = 1
	hitbox.BorderSizePixel = 0
	hitbox.Text = ""
	hitbox.AutoButtonColor = false
	hitbox.Active = true
	hitbox.Selectable = true
	hitbox.Size = UDim2.fromScale(1, 1)
	hitbox.Position = UDim2.fromScale(0, 0)
	hitbox.ZIndex = Z_CLOSE_HITBOX
	hitbox.Parent = closeObject

	return hitbox
end

local function IsMatchUpcoming(match): boolean
	if not IsTable(match) then return false end
	return not (IsTable(match.WinnerTeam) or match.IsCompleted == true or match.Completed == true)
end

local function SetTeamLoserColor(defaultFrame: Instance?, isLoser: boolean)
	if not defaultFrame then return end
	local obj = AsGuiObject(defaultFrame)
	if not obj then return end
	local gradient = obj:FindFirstChildOfClass("UIGradient")
	local stroke   = obj:FindFirstChildOfClass("UIStroke")
	if isLoser then
		if gradient then gradient.Enabled = false end
		obj.BackgroundTransparency = LOSER_DIM_TRANSPARENCY
		obj.BackgroundColor3 = LOSER_BG_COLOR
		if stroke then
			stroke.Color     = LOSER_STROKE_COLOR
			stroke.Thickness = 3
		end
	else
		if gradient then gradient.Enabled = true end
		obj.BackgroundTransparency = 0
		obj.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		if stroke then
			stroke.Color     = Color3.fromRGB(10, 142, 225)
			stroke.Thickness = 1.5
		end
	end
end

--- Pulses the UIStroke inside `frame` by toggling its Transparency.
--- blinkVisible=true  → stroke fully visible (Transparency=0)
--- blinkVisible=false → stroke hidden (Transparency=1)
local function SetStrokeBlink(frame: Instance?, blinkVisible: boolean)
	if not frame then return end
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = blinkVisible and 0 or 1
	end
end

--- Applies a rotating 'tail' effect to the UIStroke using a UIGradient.
--- @param rotation number  The current rotation angle (degrees).
local function SetStrokeSpin(frame: Instance?, rotation: number?)
	if not frame then return end
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if not stroke then return end

	local gradient = stroke:FindFirstChild("__SpinTail") :: UIGradient?
	if rotation == nil then
		-- Disable/Cleanup
		if gradient then gradient:Destroy() end
		local originalThickness = stroke:GetAttribute("__TournamentOriginalThickness")
		if type(originalThickness) == "number" then
			stroke.Thickness = originalThickness
			stroke:SetAttribute("__TournamentOriginalThickness", nil)
		end
		stroke.Transparency = 0
		return
	end

	if stroke:GetAttribute("__TournamentOriginalThickness") == nil then
		stroke:SetAttribute("__TournamentOriginalThickness", stroke.Thickness)
	end

	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "__SpinTail"
		-- Continuous rotating shine: the full outline stays visible, while the
		-- bright segment moves around it. No transparent gap/blink between loops.
		gradient.Transparency = NumberSequence.new(0)
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(0.18, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 180, 255)),
		})
		gradient.Parent = stroke
	end

	stroke.Transparency = 0
	stroke.Thickness = math.max(stroke.Thickness, 3)
	gradient.Rotation = rotation
end


local function GetMatchKey(roundIndex: number, matchIndex: number): string
	return string.format("R%dM%d", roundIndex, matchIndex)
end

local function GetRoundPayload(payload, roundIndex: number)
	local rounds = IsTable(payload.Rounds) and payload.Rounds or {}
	return IsTable(rounds[roundIndex]) and rounds[roundIndex] or nil
end

local function GetRoundMatches(payload, roundIndex: number)
	local round = GetRoundPayload(payload, roundIndex)
	if not round or not IsTable(round.Matches) then
		return {}
	end
	return round.Matches
end

local function GetCompletedPlayerRoundIndex(payload): number?
	if not IsTable(payload) then
		return nil
	end

	local status = tostring(payload.Status or "Active")
	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1
	local candidateRoundIndex = status == "Champion" and 4 or (currentRoundIndex - 1)
	if candidateRoundIndex < 1 then
		return nil
	end

	local matches = GetRoundMatches(payload, candidateRoundIndex)
	for _, match in ipairs(matches) do
		if IsTable(match) and match.IsPlayerMatch == true and IsTable(match.WinnerTeam) then
			return candidateRoundIndex
		end
	end

	return nil
end

local function IsPlayerMatchRow(payload, match, roundIndex: number): boolean
	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1
	if roundIndex ~= currentRoundIndex then
		return false
	end

	if not IsTable(match) or match.IsPlayerMatch ~= true then
		return false
	end

	return IsMatchUpcoming(match)
end

local function ShouldOutlineActiveRoundMatch(payload, match, roundIndex: number): boolean
	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1
	if roundIndex ~= currentRoundIndex then
		return false
	end

	if not IsTable(match) then
		return false
	end

	local status = tostring(payload.Status or "Active")
	if status ~= "Active" then
		return false
	end

	-- Designer request: every visible match card in the currently active round
	-- should receive the rotating outline, including default/blue simulated
	-- bracket matches. Do not depend on WinnerTeam here, because future/non-player
	-- matches can already carry simulated winners in the payload while still being
	-- presented as unplayed participants in the UI.
	return HasTeam(match.HomeTeam) or HasTeam(match.AwayTeam)
end

local function ShouldRevealResultForRound(payload, roundIndex: number): boolean
	local status = tostring(payload.Status or "Active")
	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1

	if status == "Champion" then
		return roundIndex <= 4
	end

	return roundIndex < currentRoundIndex
end

local function GetBaseScoreForAnimation(_match, _rowIndex: number): number
	-- Bracket always starts from 0-0. Final score is revealed only after the
	-- match result returns to the tournament popup.
	return 0
end

local function LerpNumber(fromValue: number, toValue: number, alpha: number): number
	return fromValue + ((toValue - fromValue) * math.clamp(alpha, 0, 1))
end

local function GetWinnerRowIndex(match): number?
	if not IsTable(match) or not IsTable(match.WinnerTeam) then
		return nil
	end

	if IsWinner(match, match.HomeTeam) then
		return 1
	elseif IsWinner(match, match.AwayTeam) then
		return 2
	end

	return nil
end

local function GetMatchRootFromLeftFrame(leftFrame: Instance?, roundIndex: number, matchIndex: number): Instance?
	local pathList = LEFT_ROUND_PATHS[roundIndex]
	if not pathList then
		return nil
	end

	local path = pathList[matchIndex]
	if not path then
		return nil
	end

	return FindPath(leftFrame, path)
end

local function GetTeamRootFromMatchRoot(matchRoot: Instance?, rowIndex: number): Instance?
	return FindChild(matchRoot, rowIndex == 1 and "Team1" or "Team2")
end

local function SetGuiObjectTransparency(instance: Instance?, transparency: number)
	local object = AsGuiObject(instance)
	if not object then
		return
	end

	if object:IsA("TextLabel") or object:IsA("TextButton") then
		(object :: any).TextTransparency = transparency
	elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
		(object :: any).ImageTransparency = transparency
	end
end

function TournamentBracketView.new()
	local self = setmetatable({}, TournamentBracketView)
	self._root = nil
	self._blueprintsGui = nil
	self._connections = {}
	self._suppressedGuiStates = {}
	self._isVisible = false
	self._onStart = nil
	self._onClose = nil
	self._isStartLocked = false
	self._isChampion = false
	self._hiddenGuardConnection = nil
	-- Reveal animation state
	self._revealToken = 0
	self._activeOutlineRotation = 0
	self._resultRevealRoundIndex = nil
	self._resultRevealPhase = "done" -- "idle" | "score" | "damage" | "promote" | "done"
	self._scoreRevealProgress = 1
	self._damageRevealProgress = 1
	self._promotionTweens = {}
	self._promotionClones = {}
	self._basePositions = {}
	self._playerLogoCache = nil  -- cached per Show() session
	return self
end

function TournamentBracketView:_getPlayerGui(): PlayerGui?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	return player:WaitForChild("PlayerGui", 5) :: PlayerGui?
end

function TournamentBracketView:_resolveRoot(): Instance?
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		warn("[TournamentBracketView] PlayerGui not found.")
		return nil
	end

	local blueprints = playerGui:FindFirstChild(ROOT_GUI_NAME)
	if not blueprints then
		warn(string.format("[TournamentBracketView] Missing PlayerGui.%s.", ROOT_GUI_NAME))
		return nil
	end

	local screenGui = AsScreenGui(blueprints)
	if screenGui then
		screenGui.Enabled = true
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = math.max(screenGui.DisplayOrder, TOURNAMENT_DISPLAY_ORDER)
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		self._blueprintsGui = screenGui
	end

	local tournamentRoot = blueprints:FindFirstChild(TOURNAMENT_ROOT_NAME)
	if not tournamentRoot then
		warn(string.format("[TournamentBracketView] Missing PlayerGui.%s.%s.", ROOT_GUI_NAME, TOURNAMENT_ROOT_NAME))
		return nil
	end

	self._root = tournamentRoot
	return tournamentRoot
end

function TournamentBracketView:_getRoot(): Instance?
	if self._root and self._root.Parent then
		return self._root
	end

	return self:_resolveRoot()
end

function TournamentBracketView:_rememberGuiState(instance: Instance, propertyName: string, value: any)
	table.insert(self._suppressedGuiStates, {
		Instance = instance,
		PropertyName = propertyName,
		Value = value,
	})
end

function TournamentBracketView:_restoreSuppressedGui()
	for index = #self._suppressedGuiStates, 1, -1 do
		local state = self._suppressedGuiStates[index]
		local instance = state.Instance

		if instance and instance.Parent then
			pcall(function()
				(instance :: any)[state.PropertyName] = state.Value
			end)
		end
	end

	table.clear(self._suppressedGuiStates)
end

function TournamentBracketView:_suppressOtherGui()
	self:_restoreSuppressedGui()

	local playerGui = self:_getPlayerGui()
	local root = self:_getRoot()
	if not playerGui or not root then
		return
	end

	for _, child in ipairs(playerGui:GetChildren()) do
		if child == self._blueprintsGui then
			continue
		end

		if child:IsA("ScreenGui") then
			self:_rememberGuiState(child, "Enabled", child.Enabled)
			child.Enabled = false
		elseif child:IsA("GuiObject") then
			self:_rememberGuiState(child, "Visible", child.Visible)
			child.Visible = false
		end
	end

	local blueprintsGui = self._blueprintsGui
	if blueprintsGui then
		for _, child in ipairs(blueprintsGui:GetChildren()) do
			if child == root then
				continue
			end

			if child:IsA("GuiObject") then
				self:_rememberGuiState(child, "Visible", child.Visible)
				child.Visible = false
			end
		end
	end
end

function TournamentBracketView:_setRootVisible(visible: boolean)
	local root = self:_getRoot()
	SetVisible(root, visible)
	self._isVisible = visible
end

local function ForceGuiVisible(instance: Instance?): number
	local object = AsGuiObject(instance)
	if object then
		object.Visible = true
		return 1
	end

	return 0
end

local function ForceZIndex(instance: Instance?, zIndex: number): number
	local object = AsGuiObject(instance)
	if object then
		object.ZIndex = zIndex
		return 1
	end

	return 0
end

local STRUCTURAL_CONTAINER_NAMES = {
	Background = true,
	TopFrame = true,
	LeftFrame = true,
	RightFrame = true,
	BottomFrame = true,
	Match = true,
	Stats = true,
	Versus = true,
	Enemy = true,
	Start = true,
	League = true,
	Round1 = true,
	Round2 = true,
	Round3 = true,
	Round4 = true,
	Top = true,
	Bottom = true,
	Team1 = true,
	Team2 = true,
	Wins = true,
	Rebirths = true,
	Passing = true,
	Shooting = true,
	Dribbling = true,
	Close = true,
}

local STATE_BACKGROUND_NAMES = {
	Default = true,
	Player = true,
	Win = true,
	Victory = true,
}

local CONNECTOR_NAMES = {
	Line = true,
	Dot = true,
	Next = true,
}

local function IsNumberedLayoutContainer(name: string): boolean
	return tonumber(name) ~= nil
end

local function ShouldRestoreStructuralVisible(object: GuiObject): boolean
	if object.Name == START_HITBOX_NAME or object.Name == CLOSE_HITBOX_NAME then
		return true
	end

	if STRUCTURAL_CONTAINER_NAMES[object.Name] then
		return true
	end

	if IsNumberedLayoutContainer(object.Name) then
		return true
	end

	if object:IsA("TextLabel") or object:IsA("TextButton") then
		return true
	end

	if object:IsA("ImageLabel") or object:IsA("ImageButton") then
		return true
	end

	return false
end

local function RestoreStructuralVisibility(root: Instance?): number
	local restored = 0
	restored += ForceGuiVisible(root)

	if not root then
		return restored
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		local object = AsGuiObject(descendant)
		if object and ShouldRestoreStructuralVisible(object) then
			object.Visible = true
			restored += 1
		end
	end

	return restored
end

local function HasTextContent(object: GuiObject): boolean
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		return tostring((object :: any).Text or "") ~= ""
	end

	return false
end

local function HasImageContent(object: GuiObject): boolean
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then
		return tostring((object :: any).Image or "") ~= ""
	end

	return false
end

local function NormalizeStartButtonLayering(startRoot: Instance?): number
	local startObject = AsGuiObject(startRoot)
	if not startObject then
		return 0
	end

	local normalized = 0
	startObject.ZIndex = Z_START
	normalized += 1

	for _, descendant in ipairs(startObject:GetDescendants()) do
		local object = AsGuiObject(descendant)
		if not object then
			continue
		end

		if object.Name == START_HITBOX_NAME then
			object.ZIndex = Z_HITBOX
		elseif object.Name == "Background" or object.Name:lower():find("background") then
			-- Keep background layers below the text/icon.
			object.ZIndex = Z_START_BACKGROUND
		elseif HasTextContent(object) or HasImageContent(object) then
			object.ZIndex = Z_START_CONTENT
		else
			-- Keep empty/opaque artist button or frame layers below the text/icon.
			object.ZIndex = Z_START_BACKGROUND
		end

		normalized += 1
	end

	return normalized
end

local function NormalizeTournamentLayering(root: Instance?): number
	if not root then
		return 0
	end

	local normalized = 0
	normalized += ForceZIndex(root, Z_ROOT)
	normalized += ForceZIndex(FindChild(root, "Background"), Z_BACKGROUND)
	normalized += ForceZIndex(FindChild(root, "TopFrame"), Z_CONTAINER)
	normalized += ForceZIndex(FindChild(root, "LeftFrame"), Z_CONTAINER)
	normalized += ForceZIndex(FindChild(root, "RightFrame"), Z_CONTAINER)
	normalized += ForceZIndex(FindChild(root, "BottomFrame"), Z_CONTAINER)

	for _, descendant in ipairs(root:GetDescendants()) do
		local object = AsGuiObject(descendant)
		if not object then
			continue
		end

		local name = object.Name
		local zIndex: number? = nil

		if name == START_HITBOX_NAME then
			zIndex = Z_HITBOX
		elseif name == CLOSE_HITBOX_NAME then
			zIndex = Z_CLOSE_HITBOX
		elseif name == "Background" then
			zIndex = Z_BACKGROUND
		elseif name == "Start" then
			zIndex = Z_START
		elseif name == "Checklist" then
			zIndex = Z_BADGE
		elseif CONNECTOR_NAMES[name] then
			zIndex = Z_CONNECTOR
		elseif STATE_BACKGROUND_NAMES[name] then
			zIndex = Z_CARD_BACKGROUND
		elseif object:IsA("TextButton") then
			zIndex = Z_START_CONTENT
		elseif object:IsA("TextLabel") then
			zIndex = Z_VISUAL
		elseif object:IsA("ImageButton") then
			zIndex = Z_START_CONTENT
		elseif object:IsA("ImageLabel") then
			zIndex = Z_VISUAL
		elseif STRUCTURAL_CONTAINER_NAMES[name] or IsNumberedLayoutContainer(name) then
			zIndex = Z_CONTAINER
		end

		if zIndex ~= nil then
			object.ZIndex = zIndex
			normalized += 1
		end
	end

	local startRoot = FindStartRoot(root)
	if startRoot then
		normalized += NormalizeStartButtonLayering(startRoot)
	end

	local closeRoot = FindChild(root, "Close")
	if closeRoot then
		normalized += ForceZIndex(closeRoot, Z_CLOSE_HITBOX)
		for _, descendant in ipairs(closeRoot:GetDescendants()) do
			local object = AsGuiObject(descendant)
			if object then
				if object.Name == CLOSE_HITBOX_NAME then
					object.ZIndex = Z_CLOSE_HITBOX + 2
				else
					object.ZIndex = Z_CLOSE_HITBOX + 1
				end
				normalized += 1
			end
		end
	end

	return normalized
end

function TournamentBracketView:_restoreArtistLayoutVisibility()
	local root = self:_getRoot()
	if not root then
		return
	end

	-- Do not force every descendant Visible=true. State frames such as Default,
	-- Player, Win, Victory, Checklist are controlled by Render(). We only restore
	-- structural containers plus visible text/icon leaves, then enforce predictable
	-- ZIndex layers so the Background/arrow/card frames cannot cover content after
	-- match-return cycles.
	local restoredCount = RestoreStructuralVisibility(root)
	local zCount = NormalizeTournamentLayering(root)
	self:_applySimplifiedLayoutVisibility()

	DebugLog(string.format("structural visibility restored objects=%d normalizedZ=%d", restoredCount, zCount))
end

function TournamentBracketView:_applySimplifiedLayoutVisibility()
	if not SIMPLIFIED_MATCH_BRACKET_UI then
		return
	end

	local root = self:_getRoot()
	if not root then
		return
	end

	-- Central team feedback requested a simpler tournament UI. The right-side
	-- current-match card is now redundant because the bracket and MatchIntro/HUD
	-- already explain who plays. Keep only bracket, Start, Close, and a small
	-- league logo.
	SetVisible(FindChild(root, "TopFrame"), false)
	SetVisible(FindChild(root, "BottomFrame"), false)

	local matchFrame = FindPath(root, { "RightFrame", "Match" })
	SetVisible(matchFrame, false)

	local rightFrame = AsGuiObject(FindChild(root, "RightFrame"))
	if rightFrame then
		rightFrame.AnchorPoint = Vector2.new(0, 0)
		rightFrame.Position = UDim2.fromScale(0, 0)
		rightFrame.Size = UDim2.fromScale(1, 1)
		rightFrame.BackgroundTransparency = 1
	end

	local startRoot = AsGuiObject(FindStartRoot(root))
	if startRoot then
		startRoot.Visible = true
		NormalizeStartButtonLayering(startRoot)

		local parentObject = AsGuiObject(startRoot.Parent)
		local hitbox = parentObject and parentObject:FindFirstChild(START_HITBOX_NAME)
		if hitbox and hitbox:IsA("TextButton") then
			ConfigureStartHitbox(hitbox, startRoot)
		end
	end

	local league = AsGuiObject(FindLeagueRoot(root))
	if league then
		league.Visible = true
		ForceZIndex(league, Z_VISUAL + 4)
	end
end

function TournamentBracketView:_forceHidden(reason: string)
	local root = self:_getRoot()
	SetVisible(root, false)
	self._isVisible = false
	DebugLog("forced hidden: " .. reason)
end

function TournamentBracketView:_ensureHiddenGuard()
	if self._hiddenGuardConnection then
		return
	end

	self._hiddenGuardConnection = RunService.RenderStepped:Connect(function()
		local root = self._root
		local rootObject = AsGuiObject(root)
		if rootObject and rootObject.Visible and self._isVisible ~= true then
			rootObject.Visible = false
			DebugLog("hidden guard corrected stray visible root")
		end
	end)
end

function TournamentBracketView:_renderChampionPlaceholder(payload)
	local root = self:_getRoot()
	if not root then
		return
	end

	local isChampion = type(payload) == "table" and tostring(payload.Status or "") == "Champion"
	local existing = root:FindFirstChild(CHAMPION_PLACEHOLDER_NAME)

	if not isChampion then
		SetVisible(existing, false)
		return
	end

	local overlay = existing
	if not overlay then
		local frame = Instance.new("Frame")
		frame.Name = CHAMPION_PLACEHOLDER_NAME
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromScale(0.48, 0.24)
		frame.BackgroundTransparency = 0.18
		frame.BackgroundColor3 = Color3.fromRGB(12, 18, 38)
		frame.BorderSizePixel = 0
		frame.ZIndex = Z_HITBOX + 5
		frame.Parent = root

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 18)
		corner.Parent = frame

		local title = Instance.new("TextLabel")
		title.Name = "TitleText"
		title.BackgroundTransparency = 1
		title.AnchorPoint = Vector2.new(0.5, 0.5)
		title.Position = UDim2.fromScale(0.5, 0.38)
		title.Size = UDim2.fromScale(0.9, 0.34)
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 234, 148)
		title.Text = "CHAMPIONS!"
		title.ZIndex = frame.ZIndex + 1
		title.Parent = frame

		local subtitle = Instance.new("TextLabel")
		subtitle.Name = "SubtitleText"
		subtitle.BackgroundTransparency = 1
		subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
		subtitle.Position = UDim2.fromScale(0.5, 0.68)
		subtitle.Size = UDim2.fromScale(0.9, 0.22)
		subtitle.Font = Enum.Font.GothamBold
		subtitle.TextScaled = true
		subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		subtitle.Text = "Trophy scene placeholder"
		subtitle.ZIndex = frame.ZIndex + 1
		subtitle.Parent = frame

		overlay = frame
	end

	SetVisible(overlay, true)
end

function TournamentBracketView:_bindStartButton()
	DisconnectAll(self._connections)

	local root = self:_getRoot()
	local startRoot = FindStartRoot(root)
	local button = EnsureStartHitbox(startRoot)
	NormalizeStartButtonLayering(startRoot)

	if not button then
		warn("[TournamentBracketView] Start button root not found under Tournament.")
		return
	end

	table.insert(self._connections, button.Activated:Connect(function()
		if self._isStartLocked then
			return
		end

		self._isStartLocked = true

		local onStart = self._onStart

		-- Hide and restore this overlay before starting the match flow.
		-- This prevents MatchIntro suppression from recording Tournament.Visible = true
		-- and restoring the bracket background on top of the next match/intro.
		self:Hide()

		if onStart then
			onStart()
		end
	end))
end

function TournamentBracketView:_bindCloseButtonOnly()
	-- Adds Close button connection WITHOUT calling DisconnectAll.
	local root = self:_getRoot()
	local closeRoot = FindChild(root, "Close")
	local button = EnsureCloseHitbox(closeRoot)
	if not button then
		warn("[TournamentBracketView] Close button root not found at Tournament.Close.")
		return
	end

	table.insert(self._connections, button.Activated:Connect(function()
		if not self._isVisible then
			return
		end

		local onClose = self._onClose
		self:Hide()

		if onClose then
			onClose()
		end
	end))
end

function TournamentBracketView:_readPlayerStat(statKey: string, payload): number
	local aliases = LEADERSTAT_ALIASES[statKey] or { statKey }
	local playerStats = IsTable(payload.PlayerStats) and payload.PlayerStats or {}

	for _, statName in ipairs(aliases) do
		local fromPayload = tonumber(playerStats[statName])
		if fromPayload ~= nil then
			return fromPayload
		end
	end

	local storeKey = STAT_STORE_KEYS[statKey]
	if storeKey then
		local store = GetRoduxStore()
		if store then
			local ok, state = pcall(function()
				return store:getState()
			end)

			local playerReducer = ok and IsTable(state) and state.PlayerReducer or nil
			local fromStore = IsTable(playerReducer) and tonumber(playerReducer[storeKey]) or nil
			if fromStore ~= nil then
				return fromStore
			end
		end
	end

	local player = Players.LocalPlayer
	if not player then
		return 0
	end

	local containers = {
		player:FindFirstChild("leaderstats"),
		player:FindFirstChild("Stats"),
		player:FindFirstChild("Data"),
	}

	for _, container in ipairs(containers) do
		if container then
			for _, statName in ipairs(aliases) do
				local value = ReadValueObject(container:FindFirstChild(statName))
				if value ~= nil then
					return value
				end
			end
		end
	end

	return 0
end

function TournamentBracketView:_renderTopFrame(payload)
	local root = self:_getRoot()
	local topFrame = FindChild(root, "TopFrame")
	if not topFrame then
		return
	end

	for statKey in pairs(LEADERSTAT_ALIASES) do
		local value = self:_readPlayerStat(statKey, payload)
		SetText(FindPath(topFrame, { statKey, "MainText" }), FormatCompactNumber(value))
	end
end


function TournamentBracketView:_getRevealRoundIndex(payload): number?
	return self._resultRevealRoundIndex
end

function TournamentBracketView:_isHoldingPromotedRound(payload, roundIndex: number): boolean
	local revealRoundIndex = self:_getRevealRoundIndex(payload)
	if not revealRoundIndex then
		return false
	end

	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1
	if roundIndex ~= currentRoundIndex then
		return false
	end

	if currentRoundIndex <= revealRoundIndex then
		return false
	end

	return self._resultRevealPhase ~= "done"
end

function TournamentBracketView:_isAnimatedRevealRound(roundIndex: number): boolean
	return self._resultRevealRoundIndex == roundIndex and self._resultRevealPhase ~= "done"
end

function TournamentBracketView:_shouldRevealResult(payload, roundIndex: number): boolean
	if not ShouldRevealResultForRound(payload, roundIndex) then
		return false
	end

	if self:_isAnimatedRevealRound(roundIndex) then
		return self._resultRevealPhase == "promote"
	end

	return true
end

function TournamentBracketView:_getScoreForRow(payload, match, rowIndex: number, roundIndex: number, revealResult: boolean): string
	if not IsTable(match) then
		return ""
	end

	if self:_isAnimatedRevealRound(roundIndex) then
		local finalScore = GetActualScoreValue(match, rowIndex) or 0

		if self._resultRevealPhase == "score" then
			local baseScore = GetBaseScoreForAnimation(match, rowIndex)
			local value = LerpNumber(baseScore, finalScore, self._scoreRevealProgress or 0)
			return tostring(math.floor(value + 0.5))
		end

		if self._resultRevealPhase == "damage" or self._resultRevealPhase == "promote" then
			return tostring(finalScore)
		end
	end

	if revealResult then
		return GetScoreText(match, rowIndex)
	end

	if IsPlayerMatchRow(payload, match, roundIndex) then
		return GetPreviewScoreText(payload, match, rowIndex)
	end

	-- Non-active matches in the current/future round must not leak simulated final
	-- results before the player finishes that round. They start from 0-0.
	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1
	if roundIndex >= currentRoundIndex then
		local rowTeam = rowIndex == 1 and match.HomeTeam or match.AwayTeam
		return HasTeam(rowTeam) and "0" or ""
	end

	return GetPreviewScoreText(payload, match, rowIndex)
end

function TournamentBracketView:_rememberBasePosition(object: GuiObject)
	if not self._basePositions[object] then
		self._basePositions[object] = object.Position
	end
end

function TournamentBracketView:_applyDamageMotion(teamRoot: Instance?, active: boolean, progress: number?)
	local object = AsGuiObject(teamRoot)
	if not object then
		return
	end

	self:_rememberBasePosition(object)
	local basePosition = self._basePositions[object]

	if not active then
		object.Position = basePosition
		return
	end

	local alpha = math.clamp(tonumber(progress) or 0, 0, 1)
	local shakeStrength = (1 - alpha) * 10
	local offsetX = math.sin(alpha * math.pi * 10) * shakeStrength
	object.Position = UDim2.new(basePosition.X.Scale, basePosition.X.Offset + offsetX, basePosition.Y.Scale, basePosition.Y.Offset)
end

function TournamentBracketView:_setRowDimmed(teamRoot: Instance?, isDimmed: boolean)
	if not teamRoot then
		return
	end

	local transparency = isDimmed and LOSER_DIM_TRANSPARENCY or 0
	SetGuiObjectTransparency(FindChild(teamRoot, "NameText"), transparency)
	SetGuiObjectTransparency(FindChild(teamRoot, "ScoreText"), transparency)
	SetGuiObjectTransparency(FindChild(teamRoot, "Logo"), isDimmed and 0.35 or 0)
end

function TournamentBracketView:_resetAnimatedRows()
	for object, position in pairs(self._basePositions) do
		if object and object.Parent then
			pcall(function()
				object.Position = position
			end)
		end
	end
end

function TournamentBracketView:_clearPromotionClones()
	for _, tween in ipairs(self._promotionTweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(self._promotionTweens)

	for _, clone in ipairs(self._promotionClones) do
		if clone and clone.Parent then
			clone:Destroy()
		end
	end
	table.clear(self._promotionClones)
end

function TournamentBracketView:_renderTeamRow(teamRoot: Instance?, match, team, rowIndex: number, payload, roundIndex: number, matchIndex: number, options: any?)
	local teamObject = AsGuiObject(teamRoot)
	local forceTbd = IsTable(options) and options.ForceTbd == true

	if teamObject then
		teamObject.Visible = true
	end

	-- Saat promosi sedang animasi (clone bergerak ke slot ini), sembunyikan
	-- hanya teks TBD dan logo saja — frame tetap ada agar layout bracket tidak berubah.
	-- Slot kembali penuh begitu fase promote selesai (ForceTbd = false).
	if forceTbd then
		SetVisible(FindChild(teamRoot, "NameText"), false)
		SetVisible(FindChild(teamRoot, "ScoreText"), false)
		SetLogoVisible(FindChild(teamRoot, "Logo"), false)
		return
	end

	local hasTeam = HasTeam(team)
	local isPlayer = hasTeam and IsPlayerTeam(team)
	local revealResult = self:_shouldRevealResult(payload, roundIndex) and IsTable(match and match.WinnerTeam)
	local isWinner = revealResult and hasTeam and IsWinner(match, team)
	local isLoser = revealResult and hasTeam and IsTable(match and match.WinnerTeam) and not isWinner
	local isActiveMatch = ShouldOutlineActiveRoundMatch(payload, match, roundIndex)

	local defaultFrame = FindChild(teamRoot, "Default")
	local playerFrame  = FindChild(teamRoot, "Player")
	local winFrame     = FindChild(teamRoot, "Win")
	local logo         = FindChild(teamRoot, "Logo")
	local nameText     = FindChild(teamRoot, "NameText")
	local scoreLabel   = FindChild(teamRoot, "ScoreText")

	local damageActive = false
	if self:_isAnimatedRevealRound(roundIndex) and self._resultRevealPhase == "damage" then
		damageActive = hasTeam and IsTable(match and match.WinnerTeam) and not IsWinner(match, team)
	end

	if damageActive then
		local progress = math.clamp(tonumber(self._damageRevealProgress) or 0, 0, 1)
		local flashOn = math.floor(progress * 8) % 2 == 0
		SetTeamLoserColor(defaultFrame, true)
		local object = AsGuiObject(defaultFrame)
		if object then
			object.BackgroundColor3 = flashOn and Color3.fromRGB(230, 45, 45) or LOSER_BG_COLOR
		end
		self:_applyDamageMotion(teamRoot, true, progress)
	else
		self:_applyDamageMotion(teamRoot, false, 1)
	end

	if not damageActive then
		SetTeamLoserColor(defaultFrame, isLoser)
	end

	self:_setRowDimmed(teamRoot, isLoser and not damageActive)

	local showWin = hasTeam and isWinner
	local showPlayer = hasTeam and isPlayer and not revealResult
	local showDefault = (not showWin) and (not showPlayer)
	local activeFrame = showPlayer and playerFrame or defaultFrame

	-- Stop old spin tails only on inactive frames. Do not destroy/recreate the
	-- active frame gradient every RenderStepped; that caused a visible loop gap.
	if not (isActiveMatch and activeFrame == defaultFrame and self._resultRevealPhase == "done") then
		SetStrokeSpin(defaultFrame, nil)
	end
	if not (isActiveMatch and activeFrame == playerFrame and self._resultRevealPhase == "done") then
		SetStrokeSpin(playerFrame, nil)
	end
	SetStrokeSpin(winFrame, nil)

	SetVisible(defaultFrame, showDefault)
	SetVisible(playerFrame, showPlayer)
	SetVisible(winFrame, showWin)
	SetVisible(nameText, true)
	SetVisible(scoreLabel, hasTeam)
	SetLogoVisible(logo, hasTeam)

	SetText(nameText, hasTeam and GetTeamName(team, "TBD") or "TBD")
	SetText(scoreLabel, hasTeam and self:_getScoreForRow(payload, match, rowIndex, roundIndex, revealResult) or "")

	if isActiveMatch and self._resultRevealPhase == "done" then
		SetStrokeSpin(activeFrame, self._activeOutlineRotation)
	end

	-- Resolve logo: server icon takes priority, then TeamLogoConfig by name, then player random cache.
	local resolvedIcon = ""
	if hasTeam then
		if isPlayer then
			resolvedIcon = "rbxassetid://81212587492189"
		else
			resolvedIcon = GetTeamIcon(team)
			if resolvedIcon == "" then
				local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}
				local areaId = tostring(payload.AreaId or currentMatch.AreaId or "Area01")
				resolvedIcon = TeamLogoConfig.GetTeamLogo(areaId, GetTeamName(team, ""))
			end
		end
	end
	SetImageIfProvided(logo, resolvedIcon)
end

function TournamentBracketView:_renderMatch(matchRoot: Instance?, match, payload, roundIndex: number, matchIndex: number)
	local forceTbd = self:_isHoldingPromotedRound(payload, roundIndex)
	local options = { ForceTbd = forceTbd }
	local team1 = (not forceTbd and IsTable(match)) and match.HomeTeam or nil
	local team2 = (not forceTbd and IsTable(match)) and match.AwayTeam or nil

	self:_renderTeamRow(FindChild(matchRoot, "Team1"), match, team1, 1, payload, roundIndex, matchIndex, options)
	self:_renderTeamRow(FindChild(matchRoot, "Team2"), match, team2, 2, payload, roundIndex, matchIndex, options)
end

function TournamentBracketView:_renderLeftFrame(payload)
	local root = self:_getRoot()
	local leftFrame = FindChild(root, "LeftFrame")
	if not leftFrame then
		return
	end

	local rounds = IsTable(payload.Rounds) and payload.Rounds or {}

	for roundIndex, pathList in pairs(LEFT_ROUND_PATHS) do
		local round = rounds[roundIndex] or {}
		local matches = IsTable(round.Matches) and round.Matches or {}

		for matchIndex, path in ipairs(pathList) do
			local matchRoot = FindPath(leftFrame, path)
			local match = matches[matchIndex] or {}
			self:_renderMatch(matchRoot, match, payload, roundIndex, matchIndex)
		end
	end
end

function TournamentBracketView:_renderRightFrame(payload)
	local root = self:_getRoot()
	if not root then
		return
	end

	local matchFrame = FindPath(root, { "RightFrame", "Match" })
	local currentMatch = IsTable(payload.CurrentMatch) and payload.CurrentMatch or {}
	local playerTeam = payload.PlayerTeam or currentMatch.PlayerTeam
	local opponentTeam = payload.OpponentTeam or currentMatch.OpponentTeam
	local recommended = GetRecommendedStats(payload)
	local isChampion = tostring(payload.Status or "") == "Champion"

	local startRoot = FindStartRoot(root)
	SetVisible(startRoot, true)
	NormalizeStartButtonLayering(startRoot)

	if matchFrame then
		-- Keep data binding for compatibility, but simplified mode hides this card.
		SetText(FindPath(matchFrame, { "Versus", "Player", "NameText" }), GetTeamName(playerTeam, "Rivrs FC"))
		SetImageIfProvided(
			FindPath(matchFrame, { "Versus", "Player", "Logo" }),
			ResolveTournamentTeamLogo(playerTeam, payload, currentMatch, self._playerLogoCache)
		)

		SetText(FindPath(matchFrame, { "Versus", "Enemy", "NameText" }), isChampion and "TROPHY CEREMONY" or GetTeamName(opponentTeam, "Opponent FC"))
		if not isChampion then
			SetImageIfProvided(
				FindPath(matchFrame, { "Versus", "Enemy", "Logo" }),
				ResolveTournamentTeamLogo(opponentTeam, payload, currentMatch, self._playerLogoCache)
			)
		end

		SetText(FindPath(matchFrame, { "Stats", "Passing", "NumberText" }), FormatPlainNumber(recommended.Passing))
		SetText(FindPath(matchFrame, { "Stats", "Dribbling", "NumberText" }), FormatPlainNumber(recommended.Dribbling))
		SetText(FindPath(matchFrame, { "Stats", "Shooting", "NumberText" }), FormatPlainNumber(recommended.Shooting))
		SetVisible(matchFrame, not SIMPLIFIED_MATCH_BRACKET_UI)
	end

	SetImageIfProvided(FindLeagueRoot(root), ResolveLeagueIcon(payload))
	self:_applySimplifiedLayoutVisibility()
end

function TournamentBracketView:_renderRewardCard(cardRoot: Instance?, roundIndex: number, round, currentRoundIndex: number, status: string)
	if not cardRoot then
		return
	end

	local defaultFrame = FindChild(cardRoot, "Default")
	local victoryFrame = FindChild(cardRoot, "Victory")
	local checklist = FindChild(cardRoot, "Checklist")
	local victoryText = FindChild(cardRoot, "VictoryText")
	local titleText = FindChild(cardRoot, "TitleText")
	local rewardText = FindChild(cardRoot, "RewardText")

	local isChampion = status == "Champion"
	local isWon = (currentRoundIndex > roundIndex) or (isChampion and roundIndex <= 4)
	if IsTable(round) and round.IsCompleted == true then
		isWon = true
	end

	SetText(titleText, ROUND_REWARD_TITLES[roundIndex] or string.upper(tostring(round.RoundName or "ROUND")))	
	SetText(rewardText, string.format("%s Wins", FormatCompactNumber(GetRoundRewardWins(round))))

	-- Final card currently has no Victory/Checklist in the artist layout. All optional paths are safely ignored.
	if roundIndex == 4 then
		return
	end

	SetVisible(defaultFrame, not isWon)
	SetVisible(victoryFrame, isWon)
	SetVisible(checklist, isWon)
	SetVisible(victoryText, isWon)
	SetText(victoryText, isWon and "VICTORY" or "")
end

function TournamentBracketView:_renderBottomFrame(payload)
	local root = self:_getRoot()
	local bottomFrame = FindChild(root, "BottomFrame")
	if not bottomFrame then
		return
	end

	local rounds = IsTable(payload.Rounds) and payload.Rounds or {}
	local currentRoundIndex = tonumber(payload.CurrentRoundIndex) or 1
	local status = tostring(payload.Status or "Active")

	for roundIndex = 1, 4 do
		self:_renderRewardCard(
			FindChild(bottomFrame, tostring(roundIndex)),
			roundIndex,
			rounds[roundIndex] or {},
			currentRoundIndex,
			status
		)
	end
end


function TournamentBracketView:_getPromotionTargetRoot(leftFrame: Instance?, revealRoundIndex: number, sourceMatchIndex: number): Instance?
	local targetRoundIndex = revealRoundIndex + 1
	if targetRoundIndex > 4 then
		return nil
	end

	local targetMatchIndex = math.ceil(sourceMatchIndex / 2)
	local targetRowIndex = (sourceMatchIndex % 2 == 1) and 1 or 2
	local targetMatchRoot = GetMatchRootFromLeftFrame(leftFrame, targetRoundIndex, targetMatchIndex)
	return GetTeamRootFromMatchRoot(targetMatchRoot, targetRowIndex)
end

function TournamentBracketView:_createPromotionClone(sourceRoot: Instance?, targetRoot: Instance?): GuiObject?
	local root = self:_getRoot()
	local rootObject = AsGuiObject(root)
	local sourceObject = AsGuiObject(sourceRoot)
	local targetObject = AsGuiObject(targetRoot)

	if not rootObject or not sourceObject or not targetObject then
		return nil
	end

	local rootPosition = rootObject.AbsolutePosition
	local sourcePosition = sourceObject.AbsolutePosition - rootPosition
	local targetPosition = targetObject.AbsolutePosition - rootPosition
	local sourceSize = sourceObject.AbsoluteSize

	local clone = sourceObject:Clone()
	clone.Name = "__TournamentPromotionClone"
	clone.AnchorPoint = Vector2.new(0, 0)
	clone.Position = UDim2.fromOffset(sourcePosition.X, sourcePosition.Y)
	clone.Size = UDim2.fromOffset(sourceSize.X, sourceSize.Y)
	clone.ZIndex = Z_HITBOX + 10
	clone.Parent = rootObject

	for _, descendant in ipairs(clone:GetDescendants()) do
		local object = AsGuiObject(descendant)
		if object then
			object.ZIndex = clone.ZIndex + 1
		end
	end

	table.insert(self._promotionClones, clone)

	local tween = TweenService:Create(
		clone,
		TweenInfo.new(PROMOTION_ANIMATION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.fromOffset(targetPosition.X, targetPosition.Y),
			Size = UDim2.fromOffset(targetObject.AbsoluteSize.X, targetObject.AbsoluteSize.Y),
		}
	)
	table.insert(self._promotionTweens, tween)

	return clone
end

function TournamentBracketView:_playPromotionAnimation(payload, token: number)
	self:_clearPromotionClones()

	local revealRoundIndex = self._resultRevealRoundIndex
	if not revealRoundIndex or revealRoundIndex >= 4 then
		return
	end

	local root = self:_getRoot()
	local leftFrame = FindChild(root, "LeftFrame")
	if not leftFrame then
		return
	end

	local matches = GetRoundMatches(payload, revealRoundIndex)
	for matchIndex, match in ipairs(matches) do
		local winnerRowIndex = GetWinnerRowIndex(match)
		if winnerRowIndex then
			local sourceMatchRoot = GetMatchRootFromLeftFrame(leftFrame, revealRoundIndex, matchIndex)
			local sourceRoot = GetTeamRootFromMatchRoot(sourceMatchRoot, winnerRowIndex)
			local targetRoot = self:_getPromotionTargetRoot(leftFrame, revealRoundIndex, matchIndex)
			local clone = self:_createPromotionClone(sourceRoot, targetRoot)
			if clone then
				local tween = self._promotionTweens[#self._promotionTweens]
				tween:Play()
			end
		end
	end

	task.delay(PROMOTION_ANIMATION_DURATION + 0.05, function()
		if self._revealToken ~= token then
			return
		end
		self:_clearPromotionClones()
	end)
end

function TournamentBracketView:_startActiveOutlineLoop(payload, token: number)
	task.spawn(function()
		local lastClock = os.clock()
		while self._revealToken == token and self._isVisible do
			local now = os.clock()
			local delta = now - lastClock
			lastClock = now
			self._activeOutlineRotation = (self._activeOutlineRotation + (delta * ACTIVE_OUTLINE_ROTATION_SPEED)) % 360
			self:_renderLeftFrame(payload)
			RunService.RenderStepped:Wait()
		end
	end)
end

function TournamentBracketView:_startBracketAnimation(payload)
	self._revealToken = (self._revealToken or 0) + 1
	local token = self._revealToken

	self:_clearPromotionClones()
	self:_resetAnimatedRows()
	self._activeOutlineRotation = 0
	self._scoreRevealProgress = 1
	self._damageRevealProgress = 1
	self._resultRevealRoundIndex = GetCompletedPlayerRoundIndex(payload)

	if self._resultRevealRoundIndex then
		self._resultRevealPhase = "score"
		self._scoreRevealProgress = 0
	else
		self._resultRevealPhase = "done"
	end

	self:Render(payload)

	task.spawn(function()
		if not self._resultRevealRoundIndex then
			self:_startActiveOutlineLoop(payload, token)
			return
		end

		local scoreStartTime = os.clock()
		while self._revealToken == token and self._isVisible do
			local alpha = (os.clock() - scoreStartTime) / SCORE_ANIMATION_DURATION
			self._scoreRevealProgress = math.clamp(alpha, 0, 1)
			self:_renderLeftFrame(payload)
			if alpha >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end

		if self._revealToken ~= token or not self._isVisible then return end
		task.wait(RESULT_REVEAL_PAUSE)

		self._resultRevealPhase = "damage"
		self._damageRevealProgress = 0
		local damageStartTime = os.clock()
		while self._revealToken == token and self._isVisible do
			local alpha = (os.clock() - damageStartTime) / DAMAGE_ANIMATION_DURATION
			self._damageRevealProgress = math.clamp(alpha, 0, 1)
			self:_renderLeftFrame(payload)
			if alpha >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end

		if self._revealToken ~= token or not self._isVisible then return end
		task.wait(RESULT_REVEAL_PAUSE)

		self._resultRevealPhase = "promote"
		self:_renderLeftFrame(payload)
		self:_playPromotionAnimation(payload, token)
		task.wait(PROMOTION_ANIMATION_DURATION + RESULT_REVEAL_PAUSE)

		if self._revealToken ~= token or not self._isVisible then return end
		self._resultRevealPhase = "done"
		self:_resetAnimatedRows()
		self:_clearPromotionClones()
		self:_renderLeftFrame(payload)
		self:_startActiveOutlineLoop(payload, token)
	end)
end

function TournamentBracketView:Render(payload)
	if type(payload) ~= "table" then
		return
	end

	if not self:_getRoot() then
		return
	end

	DebugLog("Render payload")
	self._isChampion = tostring(payload.Status or "") == "Champion"

	if not SIMPLIFIED_MATCH_BRACKET_UI then
		self:_renderTopFrame(payload)
		self:_renderBottomFrame(payload)
	end

	self:_renderLeftFrame(payload)
	self:_renderRightFrame(payload)
	self:_renderChampionPlaceholder(payload)
	self:_applySimplifiedLayoutVisibility()
end

function TournamentBracketView:Show(payload, onStart, onClose)
	if not self:_getRoot() then
		return false
	end

	self._onStart = onStart
	self._onClose = onClose
	self._isStartLocked = false

	-- Pick a stable random player logo for this Show() session.
	do
		self._playerLogoCache = "rbxassetid://81212587492189"
	end

	self:_ensureHiddenGuard()
	DebugLog("Show requested")
	self:_suppressOtherGui()
	self:_restoreArtistLayoutVisibility()
	self:_setRootVisible(true)
	self:_bindStartButton()
	self:_bindCloseButtonOnly()

	self:_startBracketAnimation(payload)

	return true
end

function TournamentBracketView:Hide()
	-- Cancel any in-progress bracket animation
	self._revealToken = (self._revealToken or 0) + 1
	self._resultRevealPhase = "done"
	self:_clearPromotionClones()
	self:_resetAnimatedRows()

	DisconnectAll(self._connections)
	self:_renderChampionPlaceholder({ Status = "Hidden" })
	self:_forceHidden("Hide begin")
	self:_restoreSuppressedGui()
	self:_forceHidden("Hide after restore")
	self._onStart = nil
	self._onClose = nil
	self._isStartLocked = false
	self._isChampion = false
	self._playerLogoCache = nil
end

function TournamentBracketView:IsVisible(): boolean
	return self._isVisible == true
end

function TournamentBracketView:Destroy()
	self:Hide()
	if self._hiddenGuardConnection then
		self._hiddenGuardConnection:Disconnect()
		self._hiddenGuardConnection = nil
	end
	self._root = nil
	self._blueprintsGui = nil
end

return TournamentBracketView
