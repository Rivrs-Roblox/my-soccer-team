local AreaPresets = {}

local PresetTime_Sore = {
	Ambient = Color3.fromRGB(170, 150, 130),
	OutdoorAmbient = Color3.fromRGB(190, 170, 140),
	ColorShift_Top = Color3.fromRGB(255, 215, 150),
	Brightness = 2.2,
	ClockTime = 15,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	ExposureCompensation = 0.1,
}

local PresetEffect_Sore = {
	LightingChanges = {
		SunRays = { Intensity = 0.2, Spread = 0.6 },
		ColorCorrection = {
			Brightness = 0,
			Contrast = 0,
			Saturation = 0.2,
			TintColor = Color3.fromRGB(255, 255, 255),
		},
		Atmosphere = {
			Density = 0.15,
			Haze = 0.5,
			Color = Color3.fromRGB(255, 220, 180),
			Decay = Color3.fromRGB(255, 160, 100),
			Glare = 0,
		},
		Bloom = { Intensity = 0.2, Size = 15, Threshold = 2 },
	},
}

local PresetTime_Malam = {
	Ambient = Color3.fromRGB(130, 140, 170),
	OutdoorAmbient = Color3.fromRGB(110, 120, 150),
	ColorShift_Top = Color3.fromRGB(200, 200, 255),
	Brightness = 2,
	ClockTime = 21,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	ExposureCompensation = 0.1,
}

local PresetEffect_Malam = {
	LightingChanges = {
		SunRays = { Intensity = 0, Spread = 1 },
		ColorCorrection = {
			Brightness = 0,
			Contrast = 0,
			Saturation = 0.15,
			TintColor = Color3.fromRGB(255, 255, 255),
		},
		Atmosphere = {
			Density = 0.3,
			Haze = 2,
			Color = Color3.fromRGB(70, 90, 180),
			Decay = Color3.fromRGB(50, 70, 150),
			Glare = 0,
		},
		Bloom = { Intensity = 0.2, Size = 15, Threshold = 2 },
	},
}

AreaPresets.TimePresets = {
	Area01_Brazil = PresetTime_Sore,
	Area02_Japan = PresetTime_Malam,
	Area03_USA = PresetTime_Sore,
	Area04_Italy = PresetTime_Sore,
	Area05_England = PresetTime_Malam,
}

AreaPresets.EffectPresets = {
	Area01_Brazil = PresetEffect_Sore,
	Area02_Japan = PresetEffect_Malam,
	Area03_USA = PresetEffect_Sore,
	Area04_Italy = PresetEffect_Sore,
	Area05_England = PresetEffect_Malam,
}

return AreaPresets
