-- ReplicatedStorage/Shared/Data/Lights/init.lua
-- Main module that loads all lighting presets from the Presets folder
-- This file should be placed in: ReplicatedStorage > Shared > Data > Lights > init.lua

local LightPresets = {}

-- Find all preset files in the Presets folder
local PresetsFolder = script.Presets

-- Initialize tables
LightPresets.TimePresets = {}
LightPresets.EffectPresets = {}

-- Loop through all children of the Presets folder
for _, moduleScript in ipairs(PresetsFolder:GetChildren()) do
	if moduleScript:IsA("ModuleScript") then
		-- Import the module
		local success, presetModule = pcall(function()
			return require(moduleScript)
		end)

		if success and presetModule then
			-- Merge TimePresets
			if presetModule.TimePresets then
				for presetName, presetConfig in pairs(presetModule.TimePresets) do
					LightPresets.TimePresets[presetName] = presetConfig
				end
			end

			-- Merge EffectPresets
			if presetModule.EffectPresets then
				for presetName, presetConfig in pairs(presetModule.EffectPresets) do
					LightPresets.EffectPresets[presetName] = presetConfig
				end
			end
		else
			warn("[LightPresets] Failed to load preset:", moduleScript.Name, presetModule)
		end
	end
end

return LightPresets
