local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage.Shared.Data.Images)

return table.freeze({
	[0] = {
		Name = "Starter Pack",
		ShopIcon = "rbxassetid://97516854286112",
		PriceIcon = "rbxassetid://111603154886540",
		ValueIcons = "rbxassetid://132373848902240",
		gradients = {
			[1] = Color3.fromHex("1b3a9e"),
			[2] = Color3.fromHex("2e72de"),
			[3] = Color3.fromHex("1b3a9e"),
		},
		centerGradients = {
			[1] = Color3.fromHex("b0f7ff"),
			[2] = Color3.fromHex("72afff"),
		},
		titleGradients = {
			[1] = Color3.fromHex("ffffff"),
			[2] = Color3.fromHex("57ffff"),
			[3] = Color3.fromHex("2164ff"),
		},
		titleStrokeGradients = {
			[1] = Color3.fromHex("1c30b4"),
			[2] = Color3.fromHex("000000"),
		},
		beforePrice = 1200,
		price = 190,
	},
	[1] = {
		Name = "Pro Pack",
		ShopIcon = "rbxassetid://73384398659107",
		PriceIcon = "rbxassetid://125050514939698",
		ValueIcons = "rbxassetid://115815455110427",
		gradients = {
			[1] = Color3.fromHex("6a1c8b"),
			[2] = Color3.fromHex("9d3fc2"),
			[3] = Color3.fromHex("6a1c8b"),
		},
		centerGradients = {
			[1] = Color3.fromHex("e9ceff"),
			[2] = Color3.fromHex("d073ff"),
		},
		titleGradients = {
			[1] = Color3.fromHex("ffffff"),
			[2] = Color3.fromHex("d36cff"),
			[3] = Color3.fromHex("31176a"),
		},
		titleStrokeGradients = {
			[1] = Color3.fromHex("b42ab4"),
			[2] = Color3.fromHex("000000"),
		},
		beforePrice = 2400,
		price = 390,
	},
	[2] = {
		Name = "Master Pack",
		ShopIcon = "rbxassetid://105327688999311",
		PriceIcon = "rbxassetid://94238762527973",
		ValueIcons = "rbxassetid://101358279476330",
		gradients = {
			[1] = Color3.fromHex("7a1c12"),
			[2] = Color3.fromHex("cb5500"),
			[3] = Color3.fromHex("7a1c12"),
		},
		centerGradients = {
			[1] = Color3.fromHex("ffd940"),
			[2] = Color3.fromHex("ff8534"),
		},
		titleGradients = {
			[1] = Color3.fromHex("ffffff"),
			[2] = Color3.fromHex("ffe250"),
			[3] = Color3.fromHex("8d0909"),
		},
		titleStrokeGradients = {
			[1] = Color3.fromHex("b44545"),
			[2] = Color3.fromHex("000000"),
		},
		beforePrice = 4000,
		price = 790,
	},
})
