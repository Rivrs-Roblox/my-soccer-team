--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local ChatCommandService = nil

-- Controllers
local DataCacheController = nil

-- Commands
local Commands = {
	["/Reset"] = {
		Name = "ResetCommand",
		Function = function(self, ...)
			self:ResetPlayer(...)
		end,
		Admin = true,
	},

	["/Give"] = {
		Name = "GiveCommand",
		Function = function(self, _: Player, text: string)
			self:Give(text)
		end,
		Admin = true,
	},

	["/Teleport"] = {
		Name = "TeleportCommand",
		Function = function(self, _: Player, text: string)
			self:Teleport(text)
		end,
		Admin = true,
	},

	["/OpenGacha"] = {
		Name = "OpenGachaCommand",
		Function = function(self, _: Player, text: string)
			self:OpenGacha(text)
		end,
		Admin = true,
	},
	["/EquipAccessory"] = {
		Name = "EquipAccessoryCommand",
		Function = function(self, _: Player, text: string)
			self:EquipAccessory(text)
		end,
		Admin = true,
	},
	["/UnequipAccessory"] = {
		Name = "UnequipAccessoryCommand",
		Function = function(self, _: Player, text: string)
			self:UnequipAccessory(text)
		end,
		Admin = true,
	},
	["/BuyCoach"] = {
		Name = "BuyCoachCommand",
		Function = function(self, _: Player, text: string)
			self:BuyCoach(text)
		end,
		Admin = true,
	},
	["/EquipCoach"] = {
		Name = "EquipCoachCommand",
		Function = function(self, _: Player, text: string)
			self:EquipCoach(text)
		end,
		Admin = true,
	},
}

-- ChatCommandController
local ChatCommandController = Knit.CreateController({
	Name = "ChatCommandController",

	Template = {},
})

--|| Commands ||-
function ChatCommandController:ResetPlayer()
	ChatCommandService:ResetPlayer()
end

function ChatCommandController:Give(text: string)
	ChatCommandService:Give(text)
end

function ChatCommandController:Teleport(text: string)
	ChatCommandService:Teleport(text)
end

function ChatCommandController:OpenGacha(text: string)
	ChatCommandService:OpenGacha(text)
end

function ChatCommandController:EquipAccessory(text: string)
	ChatCommandService:EquipAccessory(text)
end

function ChatCommandController:UnequipAccessory(text: string)
	ChatCommandService:UnequipAccessory(text)
end

function ChatCommandController:BuyCoach(text: string)
	ChatCommandService:BuyCoach(text)
end

function ChatCommandController:EquipCoach(text: string)
	ChatCommandService:EquipCoach(text)
end

--|| Knit Lifecycle ||--
function ChatCommandController:KnitInit()
	ChatCommandService = Knit.GetService("ChatCommandService")

	DataCacheController = Knit.GetController("DataCacheController")

	self.Template = DataCacheController:GetFile("Template")

	for cmd, command in Commands do
		if self.Template.Config.Commands == true or command.Admin == false then
			local Command = Instance.new("TextChatCommand")
			Command.Parent = TextChatService
			Command.PrimaryAlias = cmd
			Command.Name = command.Name

			Command.Triggered:Connect(function(originTextSource, unfilteredText)
				command.Function(self, originTextSource, unfilteredText)
			end)
		end
	end
end

return ChatCommandController
