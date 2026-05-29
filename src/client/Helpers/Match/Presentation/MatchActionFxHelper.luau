--[[
	MatchActionFxHelper
	Rojo path:
		src/client/Helpers/Match/Presentation/MatchActionFxHelper.luau

	Visual-only helper for artist-authored action FX. Manual ball trails stay removed in MatchBallController; artist Trails under Effects still work.
	Used when QTE result is Green for Pass / Dribble / Shoot.

	Supported artist hierarchy examples:
		Character/LowerTorso/Effects/Fx1
		Character/RightFoot/Fx1
		Character/RightFoot/Trail
		Character/Football/BallRoot/Ball/Effects/Fx1
		Character/SpecialEffects/...

	This helper intentionally only toggles visual objects. It does not own gameplay.
]]

local MatchActionFxHelper = {}

local FORCE_DISABLED_ATTRIBUTE = "MatchForceDisabledActionFx"

local EFFECT_ROOT_NAMES = {
	Effects = true,
	SpecialEffects = true,
	ActionEffects = true,
	GreenEffects = true,
	QteEffects = true,
}

local ENABLED_CLASSES = {
	ParticleEmitter = true,
	Trail = true,
	Beam = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	Highlight = true,
}

local function isEnabledVisualInstance(instance: Instance): boolean
	return ENABLED_CLASSES[instance.ClassName] == true
end

local function isEffectRootName(name: string?): boolean
	return EFFECT_ROOT_NAMES[tostring(name or "")] == true
end

local function isInsideEffectRoot(instance: Instance): boolean
	local current = instance.Parent

	while current do
		if isEffectRootName(current.Name) then
			return true
		end

		current = current.Parent
	end

	return false
end

local function isLikelyDirectFx(instance: Instance): boolean
	local loweredName = string.lower(instance.Name or "")
	local parentName = instance.Parent and string.lower(instance.Parent.Name or "") or ""

	if loweredName == "trail" or loweredName == "aura" or loweredName == "glow" then
		return true
	end

	if string.match(loweredName, "^fx%d*$") ~= nil then
		return true
	end

	if string.match(loweredName, "^vfx%d*$") ~= nil then
		return true
	end

	if string.find(loweredName, "green") or string.find(loweredName, "special") then
		return true
	end

	-- Current artist assets sometimes place Fx1 / Trail directly under feet.
	if parentName:find("foot") or parentName:find("hand") or parentName:find("torso") or parentName:find("ball") then
		if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
			return true
		end
	end

	return false
end

local function shouldControlEffectInstance(instance: Instance): boolean
	if not isEnabledVisualInstance(instance) then
		return false
	end

	if isInsideEffectRoot(instance) then
		return true
	end

	return isLikelyDirectFx(instance)
end

local function setEnabled(instance: Instance, enabled: boolean)
	local ok = pcall(function()
		(instance :: any).Enabled = enabled == true
	end)

	if not ok then
		return
	end

	if enabled == true and instance:IsA("ParticleEmitter") then
		local emitCount = instance:GetAttribute("EmitCount")
			or instance:GetAttribute("BurstCount")
			or instance:GetAttribute("GreenEmitCount")

		if type(emitCount) == "number" and emitCount > 0 then
			pcall(function()
				instance:Emit(math.floor(emitCount))
			end)
		end
	end
end

local function collectEffectInstances(actorModel: Instance?): { Instance }
	local collected = {}
	local visited = {}

	if not actorModel then
		return collected
	end

	for _, descendant in ipairs(actorModel:GetDescendants()) do
		if shouldControlEffectInstance(descendant) and not visited[descendant] then
			visited[descendant] = true
			table.insert(collected, descendant)
		end
	end

	return collected
end

function MatchActionFxHelper.SetActorEffectsEnabled(actorModel: Instance?, enabled: boolean): number
	local count = 0

	for _, effectInstance in ipairs(collectEffectInstances(actorModel)) do
		setEnabled(effectInstance, enabled == true)
		count += 1
	end

	return count
end

function MatchActionFxHelper.StartActorEffects(actorModel: Instance?, options)
	options = options or {}

	if not actorModel then
		return function() end
	end

	local effectInstances = collectEffectInstances(actorModel)
	local originalEnabled = {}

	for _, effectInstance in ipairs(effectInstances) do
		local ok, enabled = pcall(function()
			return (effectInstance :: any).Enabled
		end)

		originalEnabled[effectInstance] = ok and enabled or false
		setEnabled(effectInstance, true)
	end

	local cleaned = false
	local cleanupDelay = tonumber(options.CleanupDelay) or 0

	local function cleanup()
		if cleaned then
			return
		end

		cleaned = true

		local function restore()
			for effectInstance, wasEnabled in pairs(originalEnabled) do
				if effectInstance and effectInstance.Parent then
					if effectInstance:GetAttribute(FORCE_DISABLED_ATTRIBUTE) == true then
						setEnabled(effectInstance, false)
					else
						setEnabled(effectInstance, wasEnabled == true)
					end
				end
			end
		end

		if cleanupDelay > 0 then
			task.delay(cleanupDelay, restore)
		else
			restore()
		end
	end

	local duration = tonumber(options.Duration)
	if duration and duration > 0 then
		task.delay(duration, cleanup)
	end

	return cleanup
end

function MatchActionFxHelper.StartActorGreenFx(actorModel: Instance?, options)
	options = options or {}

	if options.Duration == nil then
		options.Duration = 1.35
	end

	return MatchActionFxHelper.StartActorEffects(actorModel, options)
end

function MatchActionFxHelper.StopAllEffectsIn(root: Instance?): number
	if not root then
		return 0
	end

	local count = 0
	local function shouldSkip(instance: Instance): boolean
		local current: Instance? = instance
		while current do
			if current.Name == "ChampionStage" or current.Name == "ChampionRuntimeClones" then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function forceDisable(instance: Instance)
		if shouldSkip(instance) or not shouldControlEffectInstance(instance) then
			return
		end

		pcall(function()
			instance:SetAttribute(FORCE_DISABLED_ATTRIBUTE, true)
		end)

		setEnabled(instance, false)
		count += 1
	end

	forceDisable(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		forceDisable(descendant)
	end

	return count
end

function MatchActionFxHelper.IsGreenTier(value): boolean
	local str = string.upper(tostring(value or ""))
	return str == "GREEN" or str == "PERFECT" or str == "EXCELLENT"
end

function MatchActionFxHelper.IsGreenPayload(payload): boolean
	if type(payload) ~= "table" then
		return false
	end

	return MatchActionFxHelper.IsGreenTier(payload.QteTier)
		or MatchActionFxHelper.IsGreenTier(payload.Tier)
		or MatchActionFxHelper.IsGreenTier(payload.ResultTier)
end

return MatchActionFxHelper
