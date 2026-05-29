local Placements = {
	[1] = {
		Vector3.new(0, 0, 0),
	},
	[5] = {
		Vector3.new(-8.0, 0.3, 0),
		Vector3.new(-4.0, 0.1, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(4.0, 0.1, 0),
		Vector3.new(8.0, 0.3, 0),
	},
	[10] = {
		-- Top Row (5 cards)
		Vector3.new(-7.5, 2.0, 0),
		Vector3.new(-3.75, 2.0, 0),
		Vector3.new(0, 2.0, 0),
		Vector3.new(3.75, 2.0, 0),
		Vector3.new(7.5, 2.0, 0),
		-- Bottom Row (5 cards)
		Vector3.new(-7.5, -2.0, 0),
		Vector3.new(-3.75, -2.0, 0),
		Vector3.new(0, -2.0, 0),
		Vector3.new(3.75, -2.0, 0),
		Vector3.new(7.5, -2.0, 0),
	},
}

local Sizes = {
	[1] = {
		Vector3.new(2.254, 2.663, 2.254),
	},
	[5] = {
		Vector3.new(2.254, 2.663, 2.254),
		Vector3.new(2.254, 2.663, 2.254),
		Vector3.new(2.254, 2.663, 2.254),
		Vector3.new(2.254, 2.663, 2.254),
		Vector3.new(2.254, 2.663, 2.254),
	},
	[10] = {
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
		Vector3.new(1.53, 1.8, 1.53),
	},
}

return {
	Placements = Placements,
	Sizes = Sizes,
}
