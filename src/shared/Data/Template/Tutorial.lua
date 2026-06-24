return table.freeze({
	[1] = {
		Text = "Win a match!",
		ArrowTarget = function()
			return nil
		end,
		Target = 1,
	},
	[2] = {
		Text = "Buy coach to help you train.",
		ArrowTarget = function()
			return nil
		end,
		Target = 0,
	},
	[3] = {
		Text = "To get more powerful, you need to train your stats. Train your Stamina stats!",
		ArrowTarget = function()
			return workspace
				:WaitForChild("Map")
				:WaitForChild("TrainingAreas")
				:WaitForChild("StaminaZone")
				:WaitForChild("Pivot")
		end,
		Target = 150,
	},
	[4] = {
		Text = "Train your Shooting stats!",
		ArrowTarget = function()
			return workspace
				:WaitForChild("Map")
				:WaitForChild("TrainingAreas")
				:WaitForChild("ShootZone")
				:WaitForChild("Pivot")
		end,
		Target = 50,
	},
	[5] = {
		Text = "Train your Passing stats!",
		ArrowTarget = function()
			return workspace
				:WaitForChild("Map")
				:WaitForChild("TrainingAreas")
				:WaitForChild("PassZone")
				:WaitForChild("Pivot")
		end,
		Target = 50,
	},
	[6] = {
		Text = "Train your Dribbling stats!",
		ArrowTarget = function()
			return workspace
				:WaitForChild("Map")
				:WaitForChild("TrainingAreas")
				:WaitForChild("DribbleZone")
				:WaitForChild("Pivot")
		end,
		Target = 50,
	},
	[7] = {
		Text = "Go and win a match!",
		ArrowTarget = function()
			return workspace
				:WaitForChild("Map")
				:WaitForChild("BattleZone")
				:WaitForChild("BattleZone")
				:WaitForChild("Pivot")
		end,
		Target = 0,
	},
	[8] = {
		Text = "Buy character pack to unlock more players!",
		ArrowTarget = function()
			return nil
		end,
		Target = 1,
	},
	[9] = {
		Text = "Equip your new player!",
		ArrowTarget = function()
			return nil
		end,
		Target = 0,
	},
	[10] = {
		Text = "Buy accessories to boost your character stats during matches!",
		ArrowTarget = function()
			return workspace
				:WaitForChild("Map")
				:WaitForChild("Accessories")
				:WaitForChild("DripAccessoryContainer")
				:WaitForChild("Pivot")
		end,
		Target = 1,
	},
	[11] = {
		Text = "Equip your accessories!",
		ArrowTarget = function()
			return nil
		end,
		Target = 0,
	},
})
