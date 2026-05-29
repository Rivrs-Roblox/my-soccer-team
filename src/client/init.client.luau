local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnitClient = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

require(ReplicatedStorage.Packages.Animation)
require(ReplicatedStorage.Packages.Sound)
require(ReplicatedStorage.Packages.VFX)

local Preloader = require(ReplicatedStorage.Packages.Preloader)

local ActivePresenters = {}

local function StartPresentationLayer()
	local clientRoot = StarterPlayer.StarterPlayerScripts:WaitForChild("Client")
	local presentationRoot = clientRoot:FindFirstChild("Presentation")
	if not presentationRoot then
		warn("[ClientInit] Presentation folder not found; skipping presenter registration.")
		return
	end

	local matchIntroFolder = presentationRoot:FindFirstChild("MatchIntro")
	if matchIntroFolder then
		local MatchIntroPresenter = require(matchIntroFolder:WaitForChild("MatchIntroPresenter"))
		local presenter = MatchIntroPresenter.new()
		presenter:Init()
		table.insert(ActivePresenters, presenter)
		print("MatchIntroPresenter Initialized")
	end

	local npcSupporterCheerFolder = presentationRoot:FindFirstChild("NpcSupporterCheer")
	if npcSupporterCheerFolder then
		local NpcSupporterCheerPresenter = require(npcSupporterCheerFolder:WaitForChild("NpcSupporterCheerPresenter"))
		local presenter = NpcSupporterCheerPresenter.new()
		presenter:Init()
		table.insert(ActivePresenters, presenter)
		print("NpcSupporterCheerPresenter Initialized")
	end

	local tournamentBracketFolder = presentationRoot:FindFirstChild("TournamentBracket")
	if tournamentBracketFolder then
		local TournamentBracketPresenter = require(tournamentBracketFolder:WaitForChild("TournamentBracketPresenter"))
		local presenter = TournamentBracketPresenter.new()
		presenter:Init()
		table.insert(ActivePresenters, presenter)
		print("TournamentBracketPresenter Initialized")
	end

	local battleZoneRecommendedStatsFolder = presentationRoot:FindFirstChild("BattleZoneRecommendedStats")
	if battleZoneRecommendedStatsFolder then
		local BattleZoneRecommendedStatsPresenter =
			require(battleZoneRecommendedStatsFolder:WaitForChild("BattleZoneRecommendedStatsPresenter"))
		local presenter = BattleZoneRecommendedStatsPresenter.new()
		presenter:Init()
		table.insert(ActivePresenters, presenter)
		print("BattleZoneRecommendedStatsPresenter Initialized")
	end

	local tournamentChampionFolder = presentationRoot:FindFirstChild("TournamentChampion")
	if tournamentChampionFolder then
		local TournamentChampionPresenter = require(tournamentChampionFolder:WaitForChild("TournamentChampionPresenter"))
		local presenter = TournamentChampionPresenter.new()
		presenter:Init()
		table.insert(ActivePresenters, presenter)
		print("TournamentChampionPresenter Initialized")
	end

	local areaLightingFolder = presentationRoot:FindFirstChild("AreaLighting")
	if areaLightingFolder then
		local AreaLightingPresenter = require(areaLightingFolder:WaitForChild("AreaLightingPresenter"))
		local presenter = AreaLightingPresenter.new()
		presenter:Init()
		table.insert(ActivePresenters, presenter)
		print("AreaLightingPresenter Initialized")
	end
end

Preloader:Configure({
	showLoadingScreen = true,
	loadControllers = true,
	loadImages = true, -- If at false imagesPath should be nil.
	loadUI = false, --Leave this at False
	initialDelay = 0.5,
	finalDelay = 0.5,
	skipEnabled = true,
	keepLoadingScreen = true, --if at true it won't remove the loading screen even when loading is finish
	paths = {
		controllersPath = StarterPlayer.StarterPlayerScripts.Client.Controllers,
		imagesPath = ReplicatedStorage.Shared.Data.Images,
		componentsPath = nil, --Always keep at nil
	},
})

Preloader.ControllersLoadedSignal:Connect(function()
	KnitClient.Start()
		:andThen(function()
			print("Knit Client Successfully Started")
		end)
		:catch(warn)
		:await()

	StartPresentationLayer()

	local Root = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Applications.Root.Application)
	local Sync = require(StarterPlayer.StarterPlayerScripts.Client.Modules.Synchronization)
	Sync()

	Roact.mount(
		Roact.createElement(RoduxHooks.Provider, {
			store = Store,
		}, Roact.createElement(Root.Game)),
		Players.LocalPlayer.PlayerGui,
		"GameScreenGui"
	)

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local infoGui = playerGui:FindFirstChild("InfoGui")
	if infoGui then
		infoGui.Enabled = false
	end

	local PlayerService = KnitClient.GetService("PlayerService")
	PlayerService:SetClientLoaded()
end)

Preloader:PreloadContent()
