--!strict
-- MatchCharacterVisualRestore.luau
-- Presentation-only safety restore for character faces/nameplates after match or ceremony masking.

local MatchCharacterVisualRestore = {}

local HELPER_NAME_HINTS = {
	"hitbox",
	"collider",
	"collision",
	"hurtbox",
	"trigger",
	"zone",
	"marker",
	"target",
	"debug",
	"helper",
	"pivot",
	"spawn",
}

local TROPHY_NAME_HINTS = {
	"trophy",
	"tropy",
	"trofi",
}

local EMBEDDED_BALL_NAMES = {
	ball = true,
	football = true,
	soccerball = true,
	matchball = true,
	dribbleball = true,
}

local BODY_PART_NAMES = {
	Head = true,
	UpperTorso = true,
	LowerTorso = true,
	Torso = true,
	LeftUpperArm = true,
	LeftLowerArm = true,
	LeftHand = true,
	RightUpperArm = true,
	RightLowerArm = true,
	RightHand = true,
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true,
	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
}

local function nameContainsAny(instance: Instance?, hints: { string }): boolean
	local current = instance
	while current do
		local lowered = string.lower(current.Name)
		for _, hint in ipairs(hints) do
			if string.find(lowered, hint, 1, true) then
				return true
			end
		end
		current = current.Parent
	end
	return false
end

local function isEmbeddedBallVisual(instance: Instance): boolean
	local current: Instance? = instance
	while current do
		if EMBEDDED_BALL_NAMES[string.lower(current.Name)] then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isAccessoryVisual(instance: Instance): boolean
	return instance:FindFirstAncestorWhichIsA("Accessory") ~= nil
end

local function isHeadVisual(instance: Instance): boolean
	local current: Instance? = instance
	while current do
		if current.Name == "Head" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function shouldSkip(instance: Instance): boolean
	if isEmbeddedBallVisual(instance) then
		return true
	end

	if nameContainsAny(instance, TROPHY_NAME_HINTS) then
		return true
	end

	return false
end

local function isHelperPart(part: BasePart): boolean
	if part.Name == "HumanoidRootPart" then
		return true
	end

	if nameContainsAny(part, HELPER_NAME_HINTS) then
		return true
	end

	return false
end

local function shouldRestorePart(part: BasePart): boolean
	if shouldSkip(part) or isHelperPart(part) then
		return false
	end

	if BODY_PART_NAMES[part.Name] then
		return true
	end

	if isAccessoryVisual(part) then
		return true
	end

	-- Some custom Roblox rigs use MeshPart body names. If a visible visual part was
	-- masked to 1 by match presentation, restore it unless it is clearly a helper.
	return part:IsA("MeshPart")
end

local function shouldRestoreFaceVisual(instance: Instance): boolean
	if shouldSkip(instance) then
		return false
	end

	if nameContainsAny(instance, HELPER_NAME_HINTS) then
		return false
	end

	if isHeadVisual(instance) or isAccessoryVisual(instance) then
		return true
	end

	local lowered = string.lower(instance.Name)
	return string.find(lowered, "face", 1, true) ~= nil
		or string.find(lowered, "head", 1, true) ~= nil
		or string.find(lowered, "name", 1, true) ~= nil
end

function MatchCharacterVisualRestore.RestoreCharacterVisuals(root: Instance?)
	if not root then
		return
	end

	local function restore(instance: Instance)
		pcall(function()
			instance:SetAttribute("MatchForceDisabledActionFx", nil)
		end)

		if instance:IsA("BasePart") then
			pcall(function()
				instance.CollisionGroup = "Humanoid"
			end)
			if shouldRestorePart(instance) then
				instance.LocalTransparencyModifier = 0
				if instance.Transparency >= 1 then
					instance.Transparency = 0
				end
			end
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			if shouldRestoreFaceVisual(instance) then
				instance.Transparency = 0
			end
		elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
			if shouldRestoreFaceVisual(instance) then
				instance.Enabled = true
			end
		end
	end

	restore(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		restore(descendant)
	end
end

function MatchCharacterVisualRestore.HideTrophyVisuals(root: Instance?)
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if nameContainsAny(descendant, TROPHY_NAME_HINTS) then
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = 1
				descendant.Transparency = 1
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				descendant.Transparency = 1
			elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") then
				descendant.Enabled = false
			end
		end
	end
end

return MatchCharacterVisualRestore
