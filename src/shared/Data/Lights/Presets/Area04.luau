local Area04 = {}

Area04.TimePresets = {
	Area04 = {
		Ambient = Color3.fromRGB(114, 63, 0),
		Brightness = 0.7,
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(215, 190, 135),
		EnvironmentDiffuseScale = 0.3,
		EnvironmentSpecularScale = 0.25,
		GlobalShadows = true,
		OutdoorAmbient = Color3.fromRGB(219, 106, 0),
		ClockTime = 16.6,
		GeographicLatitude = 13,
		FogColor = Color3.fromRGB(192, 192, 192),
		FogEnd = 100000,
		FogStart = 0,
		ExposureCompensation = 0.2,
	},
}

Area04.EffectPresets = {
	Area04 = {
		LightingChanges = {
			Atmosphere = {
				Density = 0.283,
				Offset = 0.25,
				Color = Color3.fromRGB(242, 156, 103),
				Decay = Color3.fromRGB(198, 96, 0),
				Glare = 1,
				Haze = 3.6,
			},
			Bloom = {
				Enabled = true,
				Intensity = 1,
				Size = 11,
				Threshold = 1.053,
			},
			ColorCorrection = {
				Brightness = 0.05,
				Contrast = 0.1,
				Saturation = 0.19,
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

return Area04
