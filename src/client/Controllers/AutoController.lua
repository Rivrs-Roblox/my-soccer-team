--[=[
	AutoController
	- wrapper tipis untuk auto request ke TrainingService
	- manual training tetap hidup
	- cooldown 1 detik supaya klik tidak spam
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TrainingTypes = require(ReplicatedStorage.Shared.Helpers.Training.TrainingTypes)

local Actions = StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local AutoActions = require(Actions.AutoActions)

local REQUEST_COOLDOWN = 1

local AutoController = Knit.CreateController({
	Name = "AutoController",
	IsTraining = false,
	CurrentStatType = nil,
	NextRequestAt = 0,
	TrainingService = nil,
})

function AutoController:_syncStore()
	Store:dispatch(AutoActions.setAutoTraining(self.IsTraining))
	Store:dispatch(AutoActions.setAutoTrainingCurrent(self.CurrentStatType))
end

function AutoController:CanSendRequest(): boolean
	return os.clock() >= self.NextRequestAt
end

function AutoController:RequestAutoTraining(statType: string)
	local normalizedStatType = TrainingTypes.Normalize(statType)
	if not normalizedStatType or not TrainingTypes.Valid[normalizedStatType] then
		warn("[AutoController] Invalid statType:", statType)
		return
	end

	local tournamentController = nil
	pcall(function()
		tournamentController = Knit.GetController("TournamentController")
	end)
	if tournamentController and tournamentController.IsPreviewOpen and tournamentController:IsPreviewOpen() then
		return
	end

	local monetizationController = nil
	pcall(function()
		monetizationController = Knit.GetController("MonetizationController")
	end)
	if monetizationController and monetizationController.IsPurchasePromptActive and monetizationController:IsPurchasePromptActive() then
		return
	end

	local matchController = nil
	pcall(function()
		matchController = Knit.GetController("MatchController")
	end)
	if matchController and matchController.IsPlayingMatch and matchController:IsPlayingMatch() then
		return
	end

	if not self:CanSendRequest() then
		return
	end

	self.NextRequestAt = os.clock() + REQUEST_COOLDOWN

	local ok, err = pcall(function()
		self.TrainingService:RequestAutoTraining(normalizedStatType)
	end)

	if not ok then
		warn("[AutoController] RequestAutoTraining failed:", err)
	end
end

function AutoController:KnitStart()
	self.TrainingService = Knit.GetService("TrainingService")
	self:_syncStore()

	self.TrainingService.TrainingSessionChanged:Connect(function(isTraining: boolean, statType: string?)
		self.IsTraining = isTraining

		if isTraining then
			self.CurrentStatType = statType
		else
			self.CurrentStatType = nil
		end

		self:_syncStore()
	end)
end

return AutoController