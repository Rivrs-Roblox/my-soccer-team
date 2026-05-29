--[=[
    Owner: JustStop__
    Version: v.0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local DataService

local DataCacheController

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)

local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local Actions = StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions
local SettingsActions = require(Actions.SettingsActions)

-- SoundController
local SoundController = Knit.CreateController({
	Name = "SoundController",
	LastVolumeValue = {
		["UI"] = 100,
		["MISC"] = 100,
		["MUSIC"] = 100,
	},

	Template = {},
	PlayingAmbientSound = nil,
})

function SoundController:SetGlobalVolume(category, value)
	Sound:SetGlobalVolume(category, value)
	DataService:ChangeValueSettings(category, value)
	if value ~= 0 then
		SoundController.LastVolumeValue[category] = value
	end
	-- Dispatch the appropriate action based on the category
	if category == "UI" then
		Store:dispatch(SettingsActions.setUIVolume(value))
	elseif category == "MUSIC" then
		Store:dispatch(SettingsActions.setMusicVolume(value))
	elseif category == "MISC" then
		Store:dispatch(SettingsActions.setMiscVolume(value))
	end
end

function SoundController:ToggleGlobalVolume(category)
	local promise, data = DataService:GetData(Players.LocalPlayer):await()
	if promise == false then
		warn("[ACTIONS CONTROLLER] An error occured while retrieving user data.")
	end

	if data then
		for cat, value in pairs(data.Settings.Sound) do
			if cat == category then
				if value > 0 then
					SoundController:SetGlobalVolume(category, 0)
				else
					SoundController:SetGlobalVolume(category, 100)
				end
			end
		end
	end
end

--|| Knit Lifecycle ||--
function SoundController:KnitInit()
	DataService = Knit.GetService("DataService")

	DataCacheController = Knit.GetController("DataCacheController")

	self.Template = DataCacheController:GetFile("Template")

	local promise, data = DataService:GetData(Players.LocalPlayer):await()
	if promise == false then
		warn("[ACTIONS CONTROLLER] An error occured while retrieving user data.")
	end
	task.wait(1)
	if data then
		for category, value in pairs(data.Settings.Sound) do
			Sound:SetGlobalVolume(category, value)

			-- Also update the store with initial values
			if category == "UI" then
				Store:dispatch(SettingsActions.setUIVolume(value))
			elseif category == "MUSIC" then
				Store:dispatch(SettingsActions.setMusicVolume(value))
			elseif category == "MISC" then
				Store:dispatch(SettingsActions.setMiscVolume(value))
			end
		end
	end

	Sound:PlaySound("MUSIC_Background")
end

return SoundController
