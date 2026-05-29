local Area01 = {}

Area01.TimePresets = {
	Area01 = {
		Ambient = Color3.fromRGB(0, 0, 0),
		Brightness = 3.1,
		ColorShift_Bottom = Color3.fromRGB(202, 89, 89),
		ColorShift_Top = Color3.fromRGB(108, 77, 9),
		EnvironmentDiffuseScale = 0,
		EnvironmentSpecularScale = 0.07,
		GlobalShadows = true,
		OutdoorAmbient = Color3.fromRGB(125, 100, 150),
		ClockTime = 11.4,
		GeographicLatitude = 6,
		FogColor = Color3.fromRGB(192, 192, 192),
		FogEnd = 100000,
		FogStart = 0,
		ExposureCompensation = 0.2,
	},
}

Area01.EffectPresets = {
	Area01 = {
		LightingChanges = {
			Atmosphere = {
				Density = 0.235,
				Offset = 0.02,
				Color = Color3.fromRGB(194, 161, 209),
				Decay = Color3.fromRGB(0, 0, 0),
				Glare = 0,
				Haze = 0,
			},
			Bloom = {
				Enabled = true,
				Intensity = 0.4,
				Size = 11,
				Threshold = 1.053,
			},
			ColorCorrection = {
				Brightness = 0.12,
				Contrast = 0.08,
				Saturation = 0.2,
				TintColor = Color3.fromRGB(255, 255, 255),
			},
			SunRays = {
				Enabled = true,
				Intensity = 0.01,
				Spread = 0.51,
			},
		},
	},
}

return Area01
