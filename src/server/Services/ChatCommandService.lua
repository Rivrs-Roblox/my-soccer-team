--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local DataService = nil
local TeleportService = nil
local GachaService = nil
local AccessoryService = nil
local CoachesService = nil

local AuthorizedUsers = {
	7660212220,
	7660239356,
	7475265620,
	8499329506,
	9243225098,
}

-- ChatCommandService
local ChatCommandService = Knit.CreateService({
	Name = "ChatCommandService",
})

--|| Local Functions ||--

local function isAuthorized(id)
	for _, authorizedId in ipairs(AuthorizedUsers) do
		if authorizedId == id then
			return true
		end
	end
	return false
end

--|| Client Functions ||--
function ChatCommandService.Client:ResetPlayer(player: Player)
	return self.Server:ResetPlayer(player)
end

function ChatCommandService.Client:Give(player: Player, text: string)
	return self.Server:Give(player, text)
end

function ChatCommandService.Client:Teleport(player: Player, text: string)
	return self.Server:Teleport(player, text)
end

function ChatCommandService.Client:OpenGacha(player: Player, text: string)
	return self.Server:OpenGacha(player, text)
end

function ChatCommandService.Client:EquipAccessory(player: Player, text: string)
	return self.Server:EquipAccessory(player, text)
end

function ChatCommandService.Client:UnequipAccessory(player: Player, text: string)
	return self.Server:UnequipAccessory(player, text)
end

function ChatCommandService.Client:BuyCoach(player: Player, text: string)
	return self.Server:BuyCoach(player, text)
end

function ChatCommandService.Client:EquipCoach(player: Player, text: string)
	return self.Server:EquipCoach(player, text)
end

--|| Functions ||-
function ChatCommandService:ResetPlayer(player: Player)
	local userId = Players:GetUserIdFromNameAsync(player.Name)
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /Reset command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	DataService:_deletePlayerProfile(player)

	player:Kick("Your data has been reset, please log in again!")
end

function ChatCommandService:Give(player: Player, text: string)
	local userId = Players:GetUserIdFromNameAsync(player.Name)
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /Give command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	DataService:ChangeValue(player, string.split(text, " ")[2], tonumber(string.split(text, " ")[3]), true)
end

function ChatCommandService:Teleport(player: Player, text: string)
	return TeleportService:TeleportRequest(player, string.split(text, " ")[2])
end

function ChatCommandService:OpenGacha(player: Player, text: string)
	local userId = Players:GetUserIdFromNameAsync(player.Name)
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /OpenGacha command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	local args = string.split(text, " ")
	local category = args[2]
	local packType = args[3]
	local amount = tonumber(args[4]) or 1

	-- Bypass prerequisite untuk authorized users
	GachaService:OpenGacha(player, category, packType, amount)
end

function ChatCommandService:EquipAccessory(player: Player, text: string)
	local userId = player.UserId
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /EquipAccessory command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	local args = string.split(text, " ")
	local charId = args[2]
	local accessoryId = args[3]

	if not charId or not accessoryId then
		return warn(
			"[CHAT COMMAND SERVICE] Missing charId or accessoryId. Usage: /EquipAccessory [charId] [accessoryId]"
		)
	end

	local data = DataService:GetData(player)
	if not data or not data.Inventory then
		return
	end

	AccessoryService:EquipAccessory(player, tostring(charId), tostring(accessoryId))
end

function ChatCommandService:UnequipAccessory(player: Player, text: string)
	local userId = player.UserId
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /UnequipAccessory command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	local args = string.split(text, " ")
	local charId = args[2]
	local slot = args[3]

	if not charId or not slot then
		return warn("[CHAT COMMAND SERVICE] Missing charId or slot. Usage: /UnequipAccessory [charId] [slot]")
	end

	AccessoryService:UnequipAccessory(player, tostring(charId), tostring(slot))
end

function ChatCommandService:BuyCoach(player: Player, text: string)
	local userId = player.UserId
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /BuyCoach command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	local args = string.split(text, " ")
	local coachId = tonumber(args[2])

	if not coachId then
		return warn("[CHAT COMMAND SERVICE] Missing coachId. Usage: /BuyCoach [coachId]")
	end

	return CoachesService:Buy(player, coachId, true)
end

function ChatCommandService:EquipCoach(player: Player, text: string)
	local userId = player.UserId
	if not isAuthorized(userId) then
		DataService:_deletePlayerProfile(player)

		pcall(function()
			Players:BanAsync({
				UserIds = { player.UserId },
				Duration = -1,
				DisplayReason = "Cheating attempt",
				PrivateReason = "Unauthorized user tried to use /EquipCoach command",
				ExcludeAltAccounts = false,
				ApplyToUniverse = true,
			})
		end)

		player:Kick("You have been banned for cheating.")

		return
	end

	local args = string.split(text, " ")
	local coachId = tonumber(args[2])

	if coachId == nil then
		return warn("[CHAT COMMAND SERVICE] Missing coachId. Usage: /EquipCoach [coachId]")
	end

	return CoachesService:Equip(player, coachId)
end

--|| Knit Lifecycle ||--
function ChatCommandService:KnitInit()
	DataService = Knit.GetService("DataService")
	TeleportService = Knit.GetService("TeleportService")
	GachaService = Knit.GetService("GachaService")
	AccessoryService = Knit.GetService("AccessoryService")
	CoachesService = Knit.GetService("CoachesService")
end

return ChatCommandService
