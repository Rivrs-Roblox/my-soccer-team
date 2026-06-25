local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchAnimationConfig = require(
	script.Parent.Parent.Parent.Config.Match.MatchAnimationConfig
)
local MatchAnimationHelper = {}

local IDLE_TRANSITION_DEBOUNCE_SECONDS = 0.18

local function isIdleAnimationName(animationName: string?): boolean
	return animationName == "Idle" or animationName == "Idle1" or animationName == "Stand"
end

local function isLocomotionAnimationName(animationName: string?): boolean
	return animationName == "Run"
		or animationName == "Running"
		or animationName == "Jogging"
		or animationName == "Jog"
		or animationName == "Walk"
		or animationName == "Sprint"
		or animationName == "Dribble"
		or animationName == "StrafeLeft"
		or animationName == "StrafeRight"
		or animationName == "WalkLeft"
		or animationName == "WalkRight"
		or animationName == "Walk - Left"
		or animationName == "Walk - Right"
end

local function findAnimationCarrier(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animationController = model:FindFirstChildOfClass("AnimationController")

	if humanoid then
		return humanoid
	end

	if animationController then
		return animationController
	end

	animationController = Instance.new("AnimationController")
	animationController.Name = "RuntimeAnimationController"
	animationController.Parent = model
	return animationController
end

local function ensureAnimator(model: Model): Animator?
	if not model then
		return nil
	end

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if animator then
		return animator
	end

	local carrier = findAnimationCarrier(model)
	if not carrier then
		return nil
	end

	animator = Instance.new("Animator")
	animator.Parent = carrier
	return animator
end

local function loadTrack(animator: Animator, animationObjectOrId, trackName: string)
	local animationObject = nil

	if typeof(animationObjectOrId) == "Instance" and animationObjectOrId:IsA("Animation") then
		animationObject = animationObjectOrId
	else
		animationObject = Instance.new("Animation")
		animationObject.AnimationId = tostring(animationObjectOrId)
	end

	local ok, track = pcall(function()
		return animator:LoadAnimation(animationObject)
	end)

	if not ok or not track then
		if animationObject.Parent == nil then
			animationObject:Destroy()
		end

		return nil
	end

	track.Name = trackName

	if animationObject.Parent == nil then
		animationObject:Destroy()
	end

	return track
end

local function getAnimationFolder(model: Model)
	return model:FindFirstChild("Animations") or model:FindFirstChild("Animations", true)
end

local function resolveTrack(state, model: Model, requestedName: string)
	local animator = state.Animator
	if not animator then
		return nil, nil
	end

	local candidates = MatchAnimationConfig.Candidates[requestedName] or { requestedName }
	local animationFolder = getAnimationFolder(model)

	for _, candidateName in ipairs(candidates) do
		if state.Tracks[candidateName] then
			return state.Tracks[candidateName], candidateName
		end

		local animObject = animationFolder and animationFolder:FindFirstChild(candidateName)
		if animObject and animObject:IsA("Animation") then
			local track = loadTrack(animator, animObject, candidateName)
			state.Tracks[candidateName] = track
			-- Force Looped state immediately upon load if configured
			track.Looped = MatchAnimationConfig.Looped[candidateName] == true
			return track, candidateName
		end
	end

	local fallbackId = MatchAnimationConfig.FallbackIds[requestedName]
	if fallbackId then
		local track = loadTrack(animator, fallbackId, requestedName)
		state.Tracks[requestedName] = track
		track.Looped = MatchAnimationConfig.Looped[requestedName] == true
		return track, requestedName
	end

	return nil, nil
end

function MatchAnimationHelper.EnsureState(cacheTable, model: Model)
	if not model then
		return nil
	end

	cacheTable[model] = cacheTable[model] or {
		Tracks = {},
		Animator = nil,
		Current = nil,
		LastChangedAt = 0,
	}

	local state = cacheTable[model]
	if not state.Animator or not state.Animator.Parent then
		state.Animator = ensureAnimator(model)
	end

	return state
end

function MatchAnimationHelper.ComputeRunSpeed(moveSpeed: number?): number
	local speedValue = tonumber(moveSpeed) or MatchAnimationConfig.RunSpeed.ReferenceMoveSpeed
	local reference = MatchAnimationConfig.RunSpeed.ReferenceMoveSpeed
	local alpha = math.clamp(speedValue / math.max(reference, 0.001), 0, 1.35)

	local minSpeed = MatchAnimationConfig.RunSpeed.Min or 0.98
	local maxSpeed = MatchAnimationConfig.RunSpeed.Max or 1.22
	local computedSpeed = minSpeed + ((maxSpeed - minSpeed) * alpha)

	-- Match locomotion is tactical. Characters can move slowly into a lane,
	-- but the run cycle must stay alive so it does not read as slow motion.
	if speedValue > 0.01 then
		computedSpeed = math.max(computedSpeed, minSpeed)
	end

	return math.clamp(computedSpeed, minSpeed, maxSpeed)
end

function MatchAnimationHelper.Play(cacheTable, model: Model, requestedName: string, options)
	if not model or not requestedName then
		return nil
	end

	local state = MatchAnimationHelper.EnsureState(cacheTable, model)
	if not state then
		return nil
	end

	local track, actualName = resolveTrack(state, model, requestedName)
	if not track then
		return nil
	end

	local fadeTime = (options and options.fadeTime) or MatchAnimationConfig.FadeTime
	local speed = (options and options.speed) or 1
	local currentName = state.Current
	local now = os.clock()

	if currentName ~= nil
		and currentName ~= actualName
		and isLocomotionAnimationName(currentName)
		and isIdleAnimationName(actualName)
		and now - (state.LastChangedAt or 0) <= IDLE_TRANSITION_DEBOUNCE_SECONDS
	then
		local currentTrack = state.Tracks[currentName]
		if currentTrack and currentTrack.IsPlaying then
			currentTrack:AdjustSpeed(speed)
			currentTrack:SetAttribute("BaseSpeed", speed)
			return currentTrack
		end
	end

	if currentName ~= actualName then
		for _, otherTrack in ipairs(state.Animator:GetPlayingAnimationTracks()) do
			if otherTrack ~= track then
				otherTrack:Stop(fadeTime)
			end
		end
		state.LastChangedAt = now
	end

	-- Apply configuration
	local isLooped = MatchAnimationConfig.Looped[actualName] == true
	if track.Looped ~= isLooped then
		track.Looped = isLooped
	end

	track:AdjustSpeed(speed)
	track:SetAttribute("BaseSpeed", speed)

	-- Logic to ensure the track is playing without resetting it every frame.
	-- If it's a new animation (switching) or the current one somehow stopped, we play it.
	local isSwitching = (currentName ~= actualName)
	if isSwitching or not track.IsPlaying then
		-- Ensure no other tracks are fighting for dominance
		for _, otherTrack in ipairs(state.Animator:GetPlayingAnimationTracks()) do
			if otherTrack ~= track then
				otherTrack:Stop(fadeTime)
			end
		end
		track:Play(fadeTime, 1, speed)
		track:SetAttribute("BaseSpeed", speed)
	else
		track:AdjustSpeed(speed)
		track:SetAttribute("BaseSpeed", speed)
		track:AdjustWeight(1, fadeTime)
	end

	state.Current = actualName
	return track
end


function MatchAnimationHelper.ResetModel(cacheTable, model: Model)
	local state = cacheTable[model]
	if not state then
		return
	end

	for _, track in pairs(state.Tracks) do
		pcall(function()
			track:Stop(MatchAnimationConfig.FadeTime)
		end)
	end

	cacheTable[model] = nil
end

function MatchAnimationHelper.StopAll(cacheTable)
	for model, _ in pairs(cacheTable) do
		MatchAnimationHelper.ResetModel(cacheTable, model)
	end
end

local function createFallbackAnimation(animationId: string?): Animation?
	if type(animationId) ~= "string" or animationId == "" then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	return animation
end

return MatchAnimationHelper
