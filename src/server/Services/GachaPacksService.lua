-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local DataService
local DataCacheService

local DS = game:GetService("DataStoreService")
local Config = DS:GetDataStore("GameConfigs"):GetAsync("Global") or {}
-- Access: Config.MyKeyName

local GachaPacksService = Knit.CreateService({
	Name = "GachaPacksService",
	Client = {
		PackSpawned = Knit.CreateSignal(),
	},
	ActiveLoops = {},
})

--|| Client Functions ||--
function GachaPacksService.Client:GetConfig(player: Player)
	return self.Server:GetConfig(player)
end

--|| Functions ||--

function GachaPacksService:SpawnPack(player: Player)
	local data = DataService:GetData(player)
	if not data then
		return warn("[GACHA PACKS SERVICE] Player has no data: " .. player.Name)
	end

	local gacha = self.Template.GachaPacks[data.Areas.Current]
	if gacha == nil then
		return warn("[GACHA PACKS SERVICE] Gacha pack data not found: " .. data.Areas.Current)
	end

	local rngRoll = Random.new():NextInteger(1, 100)
	local currentChance = 0

	for packId, chance in pairs(gacha) do
		currentChance += chance
		if rngRoll <= currentChance then
			self.Client.PackSpawned:Fire(player, packId)
			break
		end
	end
end

function GachaPacksService:GetConfig(player: Player)
	return Config.GachaPacksConstants
end

--|| Knit Lifecycle ||--
function GachaPacksService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")

	self.Template = DataCacheService:GetFile("Template")
end

function GachaPacksService:KnitStart()
	-- local function onPlayerAdded(player: Player)
	-- 	if self.ActiveLoops[player] then
	-- 		return
	-- 	end
	-- 	self.ActiveLoops[player] = true

	-- 	task.spawn(function()
	-- 		while player.Parent do
	-- 			self:SpawnPack(player)
	-- 			task.wait(5)
	-- 		end
	-- 		self.ActiveLoops[player] = nil
	-- 	end)
	-- end

	-- Players.PlayerRemoving:Connect(function(player: Player)
	-- 	self.ActiveLoops[player] = nil
	-- end)

	-- Players.PlayerAdded:Connect(onPlayerAdded)
	-- for _, player in ipairs(Players:GetPlayers()) do
	-- 	onPlayerAdded(player)
	-- end
end

return GachaPacksService
