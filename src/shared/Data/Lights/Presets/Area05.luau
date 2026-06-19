local Area05 = {}
--area05
Area05.TimePresets = {
	Area05 = {
		Ambient = Color3.fromRGB(127, 136, 161),
		Brightness = 5,
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		ColorShift_Top = Color3.fromRGB(215, 190, 135),
		EnvironmentDiffuseScale = 0.3,
		EnvironmentSpecularScale = 0.25,
		GlobalShadows = true,
		OutdoorAmbient = Color3.fromRGB(114, 106, 196),
		ClockTime = 22.3,
		GeographicLatitude = -7,
		FogColor = Color3.fromRGB(192, 192, 192),
		FogEnd = 100000,
		FogStart = 0,
		ExposureCompensation = 0.2,
	},
	Area05Match = {
		Ambient = Color3.fromRGB(55, 60, 85),
		Brightness = 2.25,
		ColorShift_Bottom = Color3.fromRGB(202, 89, 89),
		ColorShift_Top = Color3.fromRGB(108, 77, 9),
		EnvironmentDiffuseScale = 0.2,
		EnvironmentSpecularScale = 0.1,
		GlobalShadows = true,
		OutdoorAmbient = Color3.fromRGB(100, 95, 125),
		ClockTime = 11.4,
		GeographicLatitude = 6,
		FogColor = Color3.fromRGB(192, 192, 192),
		FogEnd = 100000,
		FogStart = 0,
		ExposureCompensation = 0,
	},
}

Area05.EffectPresets = {
	Area05 = {
		LightingChanges = {
			Atmosphere = {
				Density = 0.115,
				Offset = 0.06,
				Color = Color3.fromRGB(49, 20, 152),
				Decay = Color3.fromRGB(188, 249, 255),
				Glare = 0.74,
				Haze = 2.8,
			},
			Bloom = {
				Enabled = true,
				Intensity = 0.12,
				Size = 27,
				Threshold = 1.4,
			},
			ColorCorrection = {
				Brightness = 0.12,
				Contrast = 0.28,
				Saturation = -0.28,
				TintColor = Color3.fromRGB(255, 255, 255),
			},
			SunRays = {
				Enabled = true,
				Intensity = 0.01,
				Spread = 0.1,
			},
		},
	},
	Area05Match = {
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
				Intensity = 0.08,
				Size = 7,
				Threshold = 2,
			},
			ColorCorrection = {
				Brightness = 0.03,
				Contrast = 0.03,
				Saturation = 0.12,
				TintColor = Color3.fromRGB(255, 255, 255),
			},
			SunRays = {
				Enabled = true,
				Intensity = 0.005,
				Spread = 0.51,
			},
		},
	},
}

return Area05
