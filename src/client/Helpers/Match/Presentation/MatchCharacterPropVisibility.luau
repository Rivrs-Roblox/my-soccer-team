--!strict
-- Visual-only guard for ceremony-only props on real/runtime characters.
-- Champion ceremony clones are skipped so the winner clone can show the trophy.

local Workspace = game:GetService("Workspace")

local MatchCharacterPropVisibility = {}

local GUARDED_KEYWORDS = { "trophy", "tropy", "trofi" }
local RUNTIME_ROOT_NAMES = { "LocalMatchPresentationRuntime", "SoccerCharacters", "Coaches" }

local function hasKeyword(name: string?): boolean
	local loweredName = string.lower(tostring(name or ""))
	for _, keyword in ipairs(GUARDED_KEYWORDS) do
		if string.find(loweredName, keyword, 1, true) then
			return true
		end
	end
	return false
end

local function isGuardedProp(instance: Instance): boolean
	local current: Instance? = instance
	while current do
		if hasKeyword(current.Name) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isChampionRuntime(instance: Instance): boolean
	local current: Instance? = instance
	while current do
		if current.Name == "ChampionStage" or current.Name == "ChampionRuntimeClones" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function hideInstance(instance: Instance)
	if not isGuardedProp(instance) or isChampionRuntime(instance) then
		return
	end

	if instance:IsA("BasePart") then
		instance.Transparency = 1
		instance.LocalTransparencyModifier = 1
		instance.CanCollide = false
		instance.CanTouch = false
		instance.CanQuery = false
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		instance.Transparency = 1
	elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
		instance.Enabled = false
	elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
		instance.Enabled = false
	end
end

function MatchCharacterPropVisibility.HidePropsUnder(root: Instance?)
	if not root then
		return
	end

	hideInstance(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		hideInstance(descendant)
	end
end

function MatchCharacterPropVisibility.ForceHideKnownRuntimeTrophies(player: Player?)
	if player then
		MatchCharacterPropVisibility.HidePropsUnder(player.Character)
	end

	for _, rootName in ipairs(RUNTIME_ROOT_NAMES) do
		local root = Workspace:FindFirstChild(rootName)
		if root then
			MatchCharacterPropVisibility.HidePropsUnder(root)
		end
	end
end

return MatchCharacterPropVisibility
