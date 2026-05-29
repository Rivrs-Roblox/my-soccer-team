local Resolver = {}

local DEFAULTS = {
	Idle = "rbxassetid://507766388",
	Run = "rbxassetid://507767714",
	Jump = "rbxassetid://507765000",
	Fall = "rbxassetid://507767968",
	Shoot = nil,
}

local function FindAnimationId(model: Model, animationName: string, fallback: string?)
	local candidate = model:FindFirstChild(animationName, true)
	if candidate and candidate:IsA("Animation") and candidate.AnimationId ~= "" then
		return candidate.AnimationId
	end

	return fallback
end

function Resolver.BuildTracks(animator: Animator, model: Model, overrides: table?)
	local tracks = {
		Animator = animator,
		Source = model,
	}

	for animationName, fallback in pairs(DEFAULTS) do
		local finalFallback = fallback
		if overrides and overrides[animationName] ~= nil then
			finalFallback = overrides[animationName]
		end

		local animationId = FindAnimationId(model, animationName, finalFallback)
		if animationId then
			local animation = Instance.new("Animation")
			animation.Name = "__SoccerCharacters_" .. animationName
			animation.AnimationId = animationId

			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)

			animation:Destroy()

			if ok and track then
				tracks[animationName] = track
			end
		end
	end

	return tracks
end

function Resolver.Play(tracks, animationName: string)
	if not tracks then
		return
	end

	for name, track in pairs(tracks) do
		if typeof(track) == "Instance" and track:IsA("AnimationTrack") then
			if name == animationName then
				if not track.IsPlaying then
					track:Play(0.12)
				end
			else
				if track.IsPlaying then
					track:Stop(0.12)
				end
			end
		end
	end
end

function Resolver.StopAll(tracks)
	if not tracks then
		return
	end

	for _, track in pairs(tracks) do
		if typeof(track) == "Instance" and track:IsA("AnimationTrack") then
			pcall(function()
				track:Stop(0.1)
			end)
		end
	end
end

return Resolver