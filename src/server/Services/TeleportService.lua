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
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Services
local DataService = nil
local DataCacheService = nil

local function GetSpawnLocation(): BasePart?
	local spawnFolder = workspace:FindFirstChild("Spawn")
	local spawnLocation = spawnFolder and spawnFolder:FindFirstChild("SpawnLocation")
	if spawnLocation then
		return spawnLocation :: BasePart
	end
	return workspace:FindFirstChildWhichIsA("SpawnLocation")
end

local AuthorizedUsers = {
	7823060855,
	7660212220,
	7660239356,
	7516240581,
	7823986403,
	1621760624,
	8499329506,
}

-- TeleportService
local TeleportService = Knit.CreateService({
	Name = "TeleportService",

	Client = {
		AreaUpdated = Knit.CreateSignal(),
		PlayerTeleported = Knit.CreateSignal(),
	},

	PlayerTeleporting = Signal.new(),

	Template = {},
})

--|| Client Functions ||--
function TeleportService.Client:TeleportRequest(player: Player, name: string, params: string)
	return self.Server:TeleportRequest(player, name, params)
end

function TeleportService.Client:BuyTeleporter(player: Player, name: string)
	return self.Server:BuyTeleporter(player, name)
end

function TeleportService.Client:GetArea(player)
	return self.Server:GetArea(player)
end

--|| Functions ||--
-- Returns teleporter from area name
function TeleportService:ProcessTeleport(player: Player, name: string, bypass: boolean?, callback)
	local function try()
		if not bypass then
			local data = DataService:GetData(player)
			if not data then
				task.delay(0.1, try)
				return
			end

			if table.find(data.Areas.Unlocked, name) == nil then
				callback(false)
				return
			end
		end

		callback(true)
	end

	try()
end

-- Handle player teleport request
function TeleportService:TeleportRequest(player: Player, name: string)
	local userId = Players:GetUserIdFromNameAsync(player.Name)

	local function isAuthorized(id)
		for _, authorizedId in ipairs(AuthorizedUsers) do
			if authorizedId == id then
				return true
			end
		end
		return false
	end

	self:ProcessTeleport(player, name, isAuthorized(userId), function(success)
		if success or isAuthorized(userId) then
			local data = DataService:GetData(player)
			if not data then
				warn("[TELEPORT SERVICE] Failed to get data for player:", player.Name)
				return
			end

			self.PlayerTeleporting:Fire(player, name)

			data.Areas.Current = name

			self.Client.PlayerTeleported:FireAll(player)
			self.Client.AreaUpdated:Fire(player, data.Areas.Current)

			-- request streaming around the teleporter
			if player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.Anchored = true
					local spawnLoc = GetSpawnLocation()
					local targetCFrame = spawnLoc and spawnLoc.CFrame or CFrame.new(0, 10, 0)
					player.Character:PivotTo(targetCFrame + Vector3.new(0, 3, 0))

					if workspace.StreamingEnabled then
						player:RequestStreamAroundAsync(targetCFrame.Position)
					end

					task.wait(0.5) -- Memberi waktu sedikit untuk physics di sisi client
					hrp.Anchored = false
				end
			end
		end
	end)
end

-- Buy teleporter for player
function TeleportService:BuyTeleporter(player: Player, name: string)
	local data = DataService:GetData(player)
	if table.find(data.Areas.Unlocked, name) then
		return { text = self.Template.Messages.Notifications.Teleporter_Already_Bought, type = "ERROR" }, false
	end

	if data.Wins >= self.Template.Areas[name].Price then
		DataService:AddArea(player, name)
		DataService:ChangeValue(player, "Wins", -self.Template.Areas[name].Price, true)

		return {
			text = self.Template.Messages.Notifications.Teleporter_Bought(name),
			type = "SUCCESS",
		}
	end

	return { text = self.Template.Messages.Notifications.Not_Enough_Money("Wins"), type = "ERROR" }, false
end

function TeleportService:GetArea(player: Player)
	local data = DataService:GetData(player)
	if data and data.Areas then
		return data.Areas.Current
	end
	return nil
end

--|| Knit Lifecycle ||--
function TeleportService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")

	self.Template = DataCacheService:GetFile("Template")

	print("[TELEPORT SERVICE] Service loaded successfully.")
end

return TeleportService
