local Gamepasses = require(script.Gamepasses)
local Wins = require(script.Wins)
local StarterPacks = require(script.StarterPacks)
return table.freeze({
	Starter_Bundle = {
		Price = 249,
	},

	Shop_Egg = {
		Name = "Dominus Egg",
		Price_1 = 149,
		Price_3 = 359,
		Price_8 = 829,
	},

	Gamepasses = table.clone(Gamepasses),
	Wins = table.clone(Wins),
	StarterPacks = table.clone(StarterPacks),
})
