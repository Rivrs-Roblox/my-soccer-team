--[[
	Module: Lights Controller
	Version: V1.00

	Description:
	Manages lighting configuration and preset application at runtime.
	Handles startup lighting setup and preset switching.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local LightsController = Knit.CreateController({
	Name = "LightsController",
})

local Lighting = game:GetService("Lighting")
local LightPresetsModule = nil

-- Read a lighting volume and convert it to preset format
local function readVolumeAsPreset(volumePart)
	local preset = {
		TimePreset = {},
		EffectPreset = {
			LightingChanges = {},
		},
	}

	-- Read all Configuration objects
	for _, config in ipairs(volumePart:GetChildren()) do
		if not config:IsA("Configuration") then
			continue
		end

		local configName = config.Name:gsub("Config", "")

		-- Lighting properties
		if configName == "Lighting" then
			for _, valueObj in ipairs(config:GetChildren()) do
				if valueObj:IsA("ValueBase") then
					preset.TimePreset[valueObj.Name] = valueObj.Value
				end
			end
		-- Atmosphere
		elseif configName == "Atmosphere" then
			preset.EffectPreset.LightingChanges.Atmosphere = {}
			for _, valueObj in ipairs(config:GetChildren()) do
				if valueObj:IsA("ValueBase") then
					preset.EffectPreset.LightingChanges.Atmosphere[valueObj.Name] = valueObj.Value
				end
			end
		-- Effects
		elseif configName == "BloomEffect" then
			preset.EffectPreset.LightingChanges.Bloom = {}
			for _, valueObj in ipairs(config:GetChildren()) do
				if valueObj:IsA("ValueBase") then
					preset.EffectPreset.LightingChanges.Bloom[valueObj.Name] = valueObj.Value
				end
			end
		elseif configName == "DepthOfFieldEffect" then
			preset.EffectPreset.LightingChanges.DepthOfField = {}
			for _, valueObj in ipairs(config:GetChildren()) do
				if valueObj:IsA("ValueBase") then
					preset.EffectPreset.LightingChanges.DepthOfField[valueObj.Name] = valueObj.Value
				end
			end
		elseif configName == "SunRaysEffect" then
			preset.EffectPreset.LightingChanges.SunRays = {}
			for _, valueObj in ipairs(config:GetChildren()) do
				if valueObj:IsA("ValueBase") then
					preset.EffectPreset.LightingChanges.SunRays[valueObj.Name] = valueObj.Value
				end
			end
		elseif configName == "ColorCorrectionEffect" then
			preset.EffectPreset.LightingChanges.ColorCorrection = {}
			for _, valueObj in ipairs(config:GetChildren()) do
				if valueObj:IsA("ValueBase") then
					preset.EffectPreset.LightingChanges.ColorCorrection[valueObj.Name] = valueObj.Value
				end
			end
		end
	end

	return preset
end

-- Apply a preset from a volume
function LightsController:ApplyVolumePreset(volumePart)
	local preset = readVolumeAsPreset(volumePart)

	-- Apply TimePreset (Lighting properties)
	if preset.TimePreset then
		for property, value in pairs(preset.TimePreset) do
			pcall(function()
				Lighting[property] = value
			end)
		end
	end

	-- Apply EffectPreset.LightingChanges
	if preset.EffectPreset and preset.EffectPreset.LightingChanges then
		local changes = preset.EffectPreset.LightingChanges

		-- Apply Atmosphere
		if changes.Atmosphere then
			local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
			if not atmosphere then
				atmosphere = Instance.new("Atmosphere")
				atmosphere.Parent = Lighting
			end
			for property, value in pairs(changes.Atmosphere) do
				pcall(function()
					atmosphere[property] = value
				end)
			end
		end

		-- Apply Bloom
		if changes.Bloom then
			local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
			if not bloom then
				bloom = Instance.new("BloomEffect")
				bloom.Parent = Lighting
			end
			for property, value in pairs(changes.Bloom) do
				pcall(function()
					bloom[property] = value
				end)
			end
		end

		-- Apply SunRays
		if changes.SunRays then
			local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
			if not sunRays then
				sunRays = Instance.new("SunRaysEffect")
				sunRays.Parent = Lighting
			end
			for property, value in pairs(changes.SunRays) do
				pcall(function()
					sunRays[property] = value
				end)
			end
		end

		-- Apply DepthOfField
		if changes.DepthOfField then
			local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
			if not dof then
				dof = Instance.new("DepthOfFieldEffect")
				dof.Parent = Lighting
			end
			for property, value in pairs(changes.DepthOfField) do
				pcall(function()
					dof[property] = value
				end)
			end
		end

		-- Apply ColorCorrection
		if changes.ColorCorrection then
			local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
			if not cc then
				cc = Instance.new("ColorCorrectionEffect")
				cc.Parent = Lighting
			end
			for property, value in pairs(changes.ColorCorrection) do
				pcall(function()
					cc[property] = value
				end)
			end
		end
	end

	print("[LightsController] Applied volume preset:", volumePart.Name)
end

-- Apply a preset by name (checks both module presets and volume presets)
function LightsController:ApplyPreset(presetName)
	-- First try to find a volume with this name
	for _, volumePart in ipairs(CollectionService:GetTagged("LightingVolume")) do
		if volumePart.Name == presetName then
			self:ApplyVolumePreset(volumePart)
			return
		end
	end

	-- If no volume found, try module presets
	if not LightPresetsModule then
		warn("[LightsController] Light presets not loaded and no volume found for:", presetName)
		return
	end

	-- Apply TimePreset (Lighting properties)
	local timePreset = LightPresetsModule.TimePresets[presetName]
	if timePreset then
		for property, value in pairs(timePreset) do
			pcall(function()
				Lighting[property] = value
			end)
		end
	end

	-- Apply EffectPreset.LightingChanges only (ignore particle stuff)
	local effectPreset = LightPresetsModule.EffectPresets[presetName]
	if effectPreset and effectPreset.LightingChanges then
		local changes = effectPreset.LightingChanges

		-- Apply Atmosphere
		if changes.Atmosphere then
			local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
			if not atmosphere then
				atmosphere = Instance.new("Atmosphere")
				atmosphere.Parent = Lighting
			end
			for property, value in pairs(changes.Atmosphere) do
				pcall(function()
					atmosphere[property] = value
				end)
			end
		end

		-- Apply Bloom
		if changes.Bloom then
			local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
			if not bloom then
				bloom = Instance.new("BloomEffect")
				bloom.Parent = Lighting
			end
			for property, value in pairs(changes.Bloom) do
				pcall(function()
					bloom[property] = value
				end)
			end
		end

		-- Apply SunRays
		if changes.SunRays then
			local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
			if not sunRays then
				sunRays = Instance.new("SunRaysEffect")
				sunRays.Parent = Lighting
			end
			for property, value in pairs(changes.SunRays) do
				pcall(function()
					sunRays[property] = value
				end)
			end
		end

		-- Apply DepthOfField
		if changes.DepthOfField then
			local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
			if not dof then
				dof = Instance.new("DepthOfFieldEffect")
				dof.Parent = Lighting
			end
			for property, value in pairs(changes.DepthOfField) do
				pcall(function()
					dof[property] = value
				end)
			end
		end

		-- Apply ColorCorrection
		if changes.ColorCorrection then
			local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
			if not cc then
				cc = Instance.new("ColorCorrectionEffect")
				cc.Parent = Lighting
			end
			for property, value in pairs(changes.ColorCorrection) do
				pcall(function()
					cc[property] = value
				end)
			end
		end
	end

	print("[LightsController] Applied preset:", presetName)
end

function LightsController:KnitInit()
	-- Load Light presets module
	local success, result = pcall(function()
		return require(ReplicatedStorage.Shared.Data.Lights)
	end)

	if success then
		LightPresetsModule = result
		print("[LightsController] Light presets loaded")
	else
		warn("[LightsController] Failed to load Light presets from ReplicatedStorage.Shared.Data.Lights")
		warn("[LightsController] Error:", result)
	end

	-- Load volume presets from workspace
	local volumeCount = 0
	for _, volumePart in ipairs(CollectionService:GetTagged("LightingVolume")) do
		volumeCount = volumeCount + 1
	end
	if volumeCount > 0 then
		print("[LightsController] Found", volumeCount, "lighting volume(s) in workspace")
	end
end

function LightsController:KnitStart() end

return LightsController
