-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local UpdateLogService = nil
local DataService = nil

local DataCacheController
local UIController

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- UpdateLogController
local UpdateLogController = Knit.CreateController({
	Name = "UpdateLogController",
	Template = {},
})

--|| Local Functions ||--

--|| Functions ||--
function UpdateLogController:SetAlreadyRead()
	UpdateLogService:SetAlreadyRead()
end

function UpdateLogController:SetFirstJoinFalse()
	UpdateLogService:SetFirstJoinFalse()
end

function UpdateLogController:KnitStart()
	DataService = Knit.GetService("DataService")
	UpdateLogService = Knit.GetService("UpdateLogService")
	DataCacheController = Knit.GetController("DataCacheController")
	UIController = Knit.GetController("UIController")

	self.Template = DataCacheController:GetFile("Template")

	local version = self.Template.Config.Version

	DataService:GetData():andThen(function(data)
		if data == nil then
			return false
		end

		if not data.FirstJoin then
			if data.TutorialComplete == false and data.TutorialStep == 1 then
				-- Prevent popups if the player is about to start the FTUE Match
				return
			end

			if data.UpdateLogRead[version] then
				UIController:ShowFrame({ frame = FramesConstants.DailyRewards })
			else
				UIController:ShowFrame({ frame = FramesConstants.UpdateLog })
			end
		else
			self:SetFirstJoinFalse()
		end
	end)
end

return UpdateLogController
