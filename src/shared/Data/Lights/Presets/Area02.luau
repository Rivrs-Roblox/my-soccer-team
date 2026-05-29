local Area02 = {}

Area02.TimePresets = {
	Area02 = {
		Ambient = Color3.fromRGB(114, 13, 58),
		Brightness = 2.5,
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(145, 17, 117),
		EnvironmentDiffuseScale = 0.4,
		EnvironmentSpecularScale = 0.05,
		GlobalShadows = true,
		OutdoorAmbient = Color3.fromRGB(202, 13, 111),
		ClockTime = 16.3,
		GeographicLatitude = 51,
		FogColor = Color3.fromRGB(192, 192, 192),
		FogEnd = 100000,
		FogStart = 0,
		ExposureCompensation = 0.5,
	},
}

Area02.EffectPresets = {
	Area02 = {
		LightingChanges = {
			Atmosphere = {
				Density = 0.28,
				Offset = 0,
				Color = Color3.fromRGB(213, 0, 110),
				Decay = Color3.fromRGB(227, 195, 97),
				Glare = 0.34,
				Haze = 4.4,
			},
			Bloom = {
				Enabled = true,
				Intensity = 1,
				Size = 9,
				Threshold = 0.8,
			},
			ColorCorrection = {
				Brightness = 0.15,
				Contrast = 0.11,
				Saturation = 0.2,
				TintColor = Color3.fromRGB(255, 251, 210),
			},
			SunRays = {
				Enabled = true,
				Intensity = 0.01,
				Spread = 0.1,
			},
		},
	},
}

return Area02
