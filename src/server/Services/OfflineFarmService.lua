-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local DataService
local PlayerStatsService

local OfflineFarmService = Knit.CreateService({
	Name = "OfflineFarmService",
	Client = {},
})

--|| Client Functions ||--

function OfflineFarmService.Client:GetStatsEarned(player: Player)
	self.Server:GetStatsEarned(player)
end

function OfflineFarmService.Client:CheckStatsEarned(player: Player)
	return self.Server:CheckStatsEarned(player)
end

--|| Functions ||--

function OfflineFarmService:GetStatsEarned(player: Player)
	local playerData = DataService:GetData(player)
	if not playerData or not playerData.LastConnection then
		warn("Data atau LastConnection tidak ditemukan untuk " .. player.Name)
		return
	end

	local lastConnection = playerData.LastConnection
	local now = os.time()
	local secondsPassed = now - lastConnection
	local hoursPassed = math.floor(secondsPassed / 3600) -- dibulatkan ke bawah

	-- Clamp hasil ke maksimum 24 jam
	hoursPassed = math.clamp(hoursPassed, 0, 24)

	if hoursPassed >= 1 then
		local shootEarned = math.floor(hoursPassed * 0.04 * playerData.Stats.Shoot)
		local passEarned = math.floor(hoursPassed * 0.04 * playerData.Stats.Pass)
		local dribbleEarned = math.floor(hoursPassed * 0.04 * playerData.Stats.Dribble)

		PlayerStatsService:SetStat(player, "Shoot", playerData.Stats.Shoot + shootEarned)
		PlayerStatsService:SetStat(player, "Pass", playerData.Stats.Pass + passEarned)
		PlayerStatsService:SetStat(player, "Dribble", playerData.Stats.Dribble + dribbleEarned)
	end
end

function OfflineFarmService:CheckStatsEarned(player: Player)
	local playerData = DataService:GetData(player)
	if not playerData or not playerData.LastConnection then
		warn("Data atau LastConnection tidak ditemukan untuk " .. player.Name)
		return 0
	end

	local lastConnection = playerData.LastConnection
	local now = os.time()
	local secondsPassed = now - lastConnection
	local hoursPassed = math.floor(secondsPassed / 3600) -- dibulatkan ke bawah

	-- Clamp hasil ke maksimum 24 jam
	hoursPassed = math.clamp(hoursPassed, 0, 24)

	local statsEarned = 0

	if hoursPassed >= 1 then
		local shootEarned = math.floor(hoursPassed * 0.04 * playerData.Stats.Shoot)
		local passEarned = math.floor(hoursPassed * 0.04 * playerData.Stats.Pass)
		local dribbleEarned = math.floor(hoursPassed * 0.04 * playerData.Stats.Dribble)
		
		statsEarned = shootEarned + passEarned + dribbleEarned
	end

	return statsEarned
end

-- KNIT START
function OfflineFarmService:KnitStart()
	DataService = Knit.GetService("DataService")
	PlayerStatsService = Knit.GetService("PlayerStatsService")
end

return OfflineFarmService
