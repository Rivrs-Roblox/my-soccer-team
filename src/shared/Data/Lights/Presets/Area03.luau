local Area03 = {}

Area03.TimePresets = {
	Area03 = {
		Ambient = Color3.fromRGB(0, 0, 0),
		Brightness = 2,
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(215, 190, 135),
		EnvironmentDiffuseScale = 0.3,
		EnvironmentSpecularScale = 0.25,
		GlobalShadows = true,
		OutdoorAmbient = Color3.fromRGB(125, 100, 150),
		ClockTime = 16.3,
		GeographicLatitude = 75,
		FogColor = Color3.fromRGB(192, 192, 192),
		FogEnd = 100000,
		FogStart = 0,
		ExposureCompensation = 0.2,
	},
}

Area03.EffectPresets = {
	Area03 = {
		LightingChanges = {
			Atmosphere = {
				Density = 0.283,
				Offset = 0.165,
				Color = Color3.fromRGB(194, 161, 209),
				Decay = Color3.fromRGB(0, 0, 0),
				Glare = 0,
				Haze = 0,
			},
			Bloom = {
				Enabled = true,
				Intensity = 1,
				Size = 11,
				Threshold = 1.053,
			},
			ColorCorrection = {
				Brightness = 0.08,
				Contrast = 0.15,
				Saturation = 0.2,
				TintColor = Color3.fromRGB(255, 255, 255),
			},
			SunRays = {
				Enabled = true,
				Intensity = 0.01,
				Spread = 0.1,
			},
		},
	},
}

return Area03
