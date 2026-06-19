--[[
	MatchAudioHelper
	Rojo path:
		src/client/Helpers/Match/Presentation/MatchAudioHelper.luau

	Small visual/audio helper for match presentation sounds.
	It now wraps the global Sound package to integrate directly with the existing sound system.
]]

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sound = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Sound"))

local MatchAudioHelper = {}

local function getScaledVolume(sound, baseVolume)
	if not sound or not sound.soundData then
		return baseVolume
	end

	local category = sound.soundData.Category
	local multiplier = 1.0

	if Sound.Categories and Sound.GlobalVolume then
		if category == Sound.Categories.UI then
			multiplier = (Sound.GlobalVolume.UI or 100) / 100
		elseif category == Sound.Categories.MUSIC then
			multiplier = (Sound.GlobalVolume.MUSIC or 100) / 100
		elseif category == Sound.Categories.MISC then
			multiplier = (Sound.GlobalVolume.MISC or 100) / 100
		end
	end

	return baseVolume * multiplier
end

function MatchAudioHelper.PlaySoundId(soundIdOrKey: string?, options)
	options = options or {}

	if type(soundIdOrKey) ~= "string" or soundIdOrKey == "" then
		return nil
	end

	local soundKey = soundIdOrKey
	if string.match(soundKey, "^rbxassetid://") then
		warn("[MatchAudioHelper] Raw rbxassetid passed to Sound system. Use keys instead! Key:", soundKey)
	end

	local parent = nil

	if typeof(options.WorldPosition) == "Vector3" then
		local part = Instance.new("Part")
		part.Name = "MatchSoundEmitter"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.Position = options.WorldPosition
		part.Parent = Workspace
		parent = part
	elseif typeof(options.Parent) == "Instance" then
		parent = options.Parent
	end

	-- Play using the global Sound controller/package
	local sound = Sound:PlaySound(soundKey, parent)

	local lifetime = tonumber(options.Lifetime) or 4
	if parent and parent.Name == "MatchSoundEmitter" then
		Debris:AddItem(parent, lifetime)
	end

	if sound then
		if options.PlaybackSpeed then
			pcall(function()
				sound:setPlaybackSpeed(options.PlaybackSpeed)
			end)
		end
		
		if options.Volume then
			pcall(function()
				local scaledVolume = getScaledVolume(sound, options.Volume)
				sound:setVolume(scaledVolume)
			end)
		end
	end

	return sound
end

function MatchAudioHelper.PlayKey(key: string, options)
	return MatchAudioHelper.PlaySoundId(key, options)
end

return MatchAudioHelper
