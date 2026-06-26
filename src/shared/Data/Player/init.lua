--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsTemplate = require(ReplicatedStorage.Shared.Data.Player.SettingsTemplate)
local BoostsTemplate = require(ReplicatedStorage.Shared.Data.Player.BoostsTemplate)
local DailyRewardsTemplate = require(ReplicatedStorage.Shared.Data.Player.DailyRewardsTemplate)

return table.freeze({
	["Money1"] = 0, -- DO NOT CHANGE THIS, WILL BE CALLED IN GAME TEMPLATE CONFIG
	["Money2"] = 0, -- DO NOT CHANGE THIS, WILL BE CALLED IN GAME TEMPLATE CONFIG
	["Rebirth"] = 0,
	["Wins"] = 0,
	["RobuxSpent"] = 0,
	["Goals"] = 0,

	["Spins"] = {
		["Free"] = 1,
		["Premium"] = 0,
	},

	["Settings"] = table.clone(SettingsTemplate),

	["Areas"] = {
		["Unlocked"] = { "Area01" },
		["Current"] = "Area01",
		["CurrentWave"] = 1,
	},

	["Coaches"] = {
		["Unlocked"] = {},
		["Current"] = 0,
	},

	["Chests"] = {
		["Group Chest"] = 0,
	},

	["Invites"] = {
		["Stars"] = 0,
		["Invited_Friends"] = {},
	},

	["Codes"] = {
		["Redeemed"] = {},
		["Verified"] = false,
	},

	["BoughtStarterPacks"] = 0,
	["FirstConnection"] = os.time(),
	["ClaimedRejoinPet"] = false,
	["DailyRewards"] = table.clone(DailyRewardsTemplate),
	["LastDailyRewarded"] = 0,
	["LastRedeemedId"] = 0,

	["Inventory"] = {
		["SoccerCharacters"] = {
			["1"] = {
				["Name"] = "Savanen",
				["Level"] = 1,
				["Accessories"] = {
					["Head"] = nil,
					["Body"] = nil,
					["Hand"] = nil,
					["Foot"] = nil,
				},
			},
			["2"] = {
				["Name"] = "Verstorm",
				["Level"] = 1,
				["Accessories"] = {
					["Head"] = nil,
					["Body"] = nil,
					["Hand"] = nil,
					["Foot"] = nil,
				},
			},
			["3"] = {
				["Name"] = "Kravetsky",
				["Level"] = 1,
				["Accessories"] = {
					["Head"] = nil,
					["Body"] = nil,
					["Hand"] = nil,
					["Foot"] = nil,
				},
			},
		},

		["EquippedSoccerCharacters"] = {
			[1] = "1",
			[2] = "2",
			[3] = "3",
		},

		["Accessories"] = {},

		["Storage"] = {
			["Stored"] = 75,
		},

		["Boosts"] = table.clone(BoostsTemplate),
		["ActiveBoosts"] = {},
	},

	["Season"] = {
		["Season"] = 0,
		["DailyQuests"] = {},
		["WeeklyQuests"] = {},
		["Claimed"] = {},
		["Premium Claimed"] = {},
		["Completed"] = 0,
		["Exp"] = 0,
		["Level"] = 1,
		["Premium"] = false,
		["LastDailyReset"] = 0,
		["LastWeeklyReset"] = 0,
	},
	["SeasonPassCompleted"] = 0,

	["Gamepasses"] = {},

	["TutorialStep"] = 1,
	["TutorialComplete"] = false,
	["PacksOpened"] = 0,

	["GroupRewardClaimed"] = false,

	["HasReceivedDiscordReward"] = false,

	["LastConnection"] = os.time(),

	["FirstJoin"] = true,
	["UpdateLogRead"] = {},

	["ExitGiftClaimed"] = false,

	-- Highest round won per area
	["HighestRoundsWon"] = {},

	-- stats character
	["Stats"] = {
		["Shoot"] = 20,
		["Pass"] = 20,
		["Dribble"] = 20,
		["Stamina"] = 100,
	},
})
