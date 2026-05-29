local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DiscordService = Knit.CreateService({
	Name = "DiscordService",
	Client = {
		RewardGiven = Knit.CreateSignal(),
	},
})

local DataService

local ROVER_API_KEY = "rvr2g08r1egk4bhbls4xtov6kswn0gs4v5rgv3qhofp4bki7dg2f9oknf3tbbf3641el"
local GUILD_ID = "1151832261738631168"


local function AwardDiscordMembershipOnce(player)
	local playerData = DataService:GetData(player)
	if playerData == nil then
		return
	end
	if playerData.HasReceivedDiscordReward then
		return
	end

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = `https://registry.rover.link/api/guilds/{GUILD_ID}/roblox-to-discord/{player.UserId}`,
			Method = "GET",
			Headers = {
				["Authorization"] = `Bearer {ROVER_API_KEY}`,
			},
		})
	end)
	if not success then
		warn(result)
		return
	elseif not result.Success then
		warn(result.StatusCode, result.StatusMessage)
		return
	end

	-- Bazooka exclusive rewaard
	--DanceService:UnlockDance(player, "DiscordDance")
	playerData.HasReceivedDiscordReward = true

	--print(`{player.Name} has been given Discord reward.`)
end

function DiscordService:KnitInit()
	DataService = Knit.GetService("DataService")
end

function DiscordService:KnitStart()
    
end

return DiscordService