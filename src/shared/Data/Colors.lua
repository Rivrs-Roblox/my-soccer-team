return table.freeze({
	["INFO"] = Color3.fromRGB(55, 94, 222),
	["SUCCESS"] = Color3.fromRGB(54, 212, 40),
	["ERROR"] = Color3.fromRGB(212, 40, 40),
	["WINS"] = Color3.fromRGB(255, 206, 10),

	Gradients = {
		Blue = {
			startColor = Color3.fromRGB(0, 200, 255),
			endColor = Color3.fromRGB(36, 119, 221),
		},
		Green = {
			startColor = Color3.fromRGB(77, 255, 0),
			endColor = Color3.fromRGB(0, 157, 26),
		},
		Yellow = {
			startColor = Color3.fromRGB(255, 255, 0),
			endColor = Color3.fromRGB(255, 200, 0),
		},
		Pink = {
			startColor = Color3.fromRGB(255, 170, 255),
			endColor = Color3.fromRGB(255, 85, 127),
		},
		Orange = {
			startColor = Color3.fromRGB(255, 234, 0),
			endColor = Color3.fromRGB(255, 119, 0),
		},
		Purple = {
			startColor = Color3.fromRGB(168, 128, 255),
			endColor = Color3.fromRGB(142, 68, 194),
		},
		Red = {
			startColor = Color3.fromRGB(255, 84, 84),
			endColor = Color3.fromRGB(166, 33, 33),
		},
		Gray = {
			startColor = Color3.fromRGB(255, 255, 255),
			endColor = Color3.fromRGB(135, 135, 135),
		},
		Common = {
			startColor = Color3.fromHex("d7d8cd"),
			endColor = Color3.fromHex("797979"),
		},
		Uncommon = {
			startColor = Color3.fromHex("50ff20"),
			endColor = Color3.fromHex("1a8a18"),
		},
		Rare = {
			startColor = Color3.fromHex("6085ff"),
			endColor = Color3.fromHex("3a559e"),
		},
		Epic = {
			startColor = Color3.fromHex("c041ff"),
			endColor = Color3.fromHex("5b1579"),
		},
		Legendary = {
			startColor = Color3.fromHex("ffe76a"),
			endColor = Color3.fromHex("d88916"),
		},
		["Gold Legendary"] = {
			startColor = Color3.fromHex("ffd447"),
			endColor = Color3.fromHex("b48e1b"),
		},
		Mythical = {
			startColor = Color3.fromHex("ff494c"),
			endColor = Color3.fromHex("8d0909"),
		},
		Exclusive = {
			startColor = Color3.fromHex("e0b33a"),
			endColor = Color3.fromHex("8f5f12"),
		},
	},

	Stroke = {
		Common = Color3.fromHex("e1e1e1"),
		Uncommon = Color3.fromHex("64ff39"),
		Rare = Color3.fromHex("46a9ff"),
		Epic = Color3.fromHex("c743ff"),
		Legendary = Color3.fromHex("ffd447"),
		["Gold Legendary"] = Color3.fromHex("e4a327"),
		Mythical = Color3.fromHex("e13b3e"),
		Exclusive = Color3.fromHex("b9861b"),
	},

	-- Names
	["Normal"] = Color3.fromRGB(216, 216, 216),
	["Gold"] = Color3.fromRGB(237, 201, 116),
	["Rainbow"] = Color3.fromRGB(230, 72, 72),

	-- Rarities
	["Common"] = Color3.fromRGB(205, 205, 205),
	["Uncommon"] = Color3.fromRGB(87, 220, 87),
	["Rare"] = Color3.fromRGB(46, 102, 255),
	["Epic"] = Color3.fromRGB(170, 0, 255),
	["Legendary"] = Color3.fromRGB(237, 201, 116),
	["Mythical"] = Color3.fromRGB(227, 66, 44),
	["Exclusive"] = Color3.fromRGB(185, 134, 27),
	["Gold Legendary"] = Color3.fromRGB(228, 163, 39),
})
