--[=[
    Owner: JustStop__
    Version: v1.1 (Synchronized Coach System)
]=]
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.ZonePlus)

local Helpers = ReplicatedStorage.Shared.Helpers
local CoachGridFunctions = require(Helpers.Coaches.Grid)
local UpdateCoaches = require(Helpers.Coaches.Update)
local Filter = require(Helpers.Table.Filter)

local DataCacheController, NotificationController, TrainingController, UIController
local CoachesService, DataService, SettingsService, TeleportService, CharacterService

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)
local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)

local RaycastExcludeModels = {}
local blockCoachAction = false

local Functions = {
	GetTableAmount = require(Helpers.Table.GetTableAmount),
	GetAngleDistance = require(Helpers.Math.GetAngleDistance),
	DeepCopy = require(Helpers.Table.DeepCopy),
	GetCoachModel = require(Helpers.Coaches.GetCoachModel),
}

local CoachesController = Knit.CreateController({
	Name = "CoachesController",
	CoachesInSession = {} :: table,
	CoachInstances = nil,
	CoachesTemplate = {},
	Colors = {},
	CoachAnimationTracks = {},
	CoachPreviousPositions = {},
	RawCoachesByPlayer = {},
	CharacterConnections = {},
})

--|| Local Functions ||--

local function getCoachName(coachData)
	if type(coachData) == "table" then
		return coachData.Name
	end

	return nil
end

--|| Functions ||--

function CoachesController:CleanupRenderedCoaches(player: Player, generatedCoaches: table)
	local keptByName = {}

	for _, coachModel in pairs(self.CoachInstances:GetChildren()) do
		if coachModel:GetAttribute("Owner") ~= player.Name then
			continue
		end

		local keep = false
		for index in pairs(generatedCoaches) do
			local modelName = player.Name .. "_" .. tostring(index)
			if coachModel.Name == modelName and not keptByName[modelName] then
				keptByName[modelName] = true
				generatedCoaches[index].Model = coachModel
				keep = true
				break
			end
		end

		if not keep then
			local excludeIndex = table.find(RaycastExcludeModels, coachModel)
			if excludeIndex then
				table.remove(RaycastExcludeModels, excludeIndex)
			end

			if self.CoachAnimationTracks[coachModel] then
				self.CoachAnimationTracks[coachModel]:Stop()
				self.CoachAnimationTracks[coachModel]:Destroy()
				self.CoachAnimationTracks[coachModel] = nil
			end

			self.CoachPreviousPositions[coachModel] = nil
			coachModel:Destroy()
		end
	end

	for index, grid in pairs(generatedCoaches) do
		local model = grid.Model
		if not (typeof(model) == "Instance" and model.Parent) then
			grid.Model = ""
		end
	end
end

function CoachesController:DestroyRenderedCoach(player: Player, index: string | number)
	local modelName = player.Name .. "_" .. tostring(index)

	for _, model in pairs(self.CoachInstances:GetChildren()) do
		if model.Name == modelName then
			local excludeIndex = table.find(RaycastExcludeModels, model)
			if excludeIndex then
				table.remove(RaycastExcludeModels, excludeIndex)
			end

			if self.CoachAnimationTracks[model] then
				self.CoachAnimationTracks[model]:Stop()
				self.CoachAnimationTracks[model]:Destroy()
				self.CoachAnimationTracks[model] = nil
			end

			self.CoachPreviousPositions[model] = nil
			model:Destroy()
		end
	end
end

function CoachesController:AddCoaches(player: Player, coachesDataFormat: table)
	coachesDataFormat = coachesDataFormat or {}
	self.RawCoachesByPlayer[player] = coachesDataFormat

	if not self.CoachesInSession[player] then
		self.CoachesInSession[player] = {}
	end

	for index, newCoachData in pairs(coachesDataFormat) do
		local currentGrid = self.CoachesInSession[player][index]
		if currentGrid then
			local oldCoachName = getCoachName(currentGrid.CoachData or currentGrid.PetData)
			local newCoachName = getCoachName(newCoachData)

			if oldCoachName ~= nil and newCoachName ~= nil and oldCoachName ~= newCoachName then
				self:DestroyRenderedCoach(player, index)
				currentGrid.Model = ""
				currentGrid.CoachData = "None"
				currentGrid.PetData = "None"
			end
		end
	end

	local generatedCoaches = CoachGridFunctions.GetGrids(coachesDataFormat, self.CoachesInSession[player], player)
	for i, v in pairs(generatedCoaches) do
		if not self.CoachesInSession[player][i] then
			self.CoachesInSession[player][i] = v
		else
			self.CoachesInSession[player][i] = v
		end
	end

	for i, _ in pairs(self.CoachesInSession[player]) do
		if not generatedCoaches[i] then
			self.CoachesInSession[player][i] = nil
			self:DestroyRenderedCoach(player, i)
		end
	end

	self:CleanupRenderedCoaches(player, generatedCoaches)
	self:RefreshPlayerTarget(player)
end

function CoachesController:HandleMove()
	RunService:BindToRenderStep("CoachesMovement", Enum.RenderPriority.Last.Value, function(Delta: number)
		UpdateCoaches(
			Delta,
			Functions,
			self.CoachesInSession,
			self.CoachesTemplate,
			self.CoachInstances,
			RaycastExcludeModels,
			self,
			TrainingController.VisualStates
		)
	end)
end

function CoachesController:BuyCoach(id: number)
	if blockCoachAction then
		NotificationController:Notify({ tag = "Coach", text = "Processing...", type = "ERROR" })
		return
	end

	blockCoachAction = true
	return CoachesService:Buy(id)
		:andThen(function(result)
			if result then
				NotificationController:Notify({ tag = "Coach", text = result.text, type = result.type })
			end
			blockCoachAction = false
			return result
		end)
		:catch(function(err)
			warn(err)
			blockCoachAction = false
		end)
end

function CoachesController:EquipCoach(id: number)
	if blockCoachAction then
		NotificationController:Notify({ tag = "Coach", text = "Processing...", type = "ERROR" })
		return
	end

	blockCoachAction = true
	return CoachesService:Equip(id)
		:andThen(function(result)
			if result then
				NotificationController:Notify({ tag = "Coach", text = result.text, type = result.type })
			end
			blockCoachAction = false
			return result
		end)
		:catch(function(err)
			warn(err)
			blockCoachAction = false
		end)
end

function CoachesController:UnequipCoach(id: number)
	if blockCoachAction then
		NotificationController:Notify({ tag = "Coach", text = "Processing...", type = "ERROR" })
		return
	end

	blockCoachAction = true
	return CoachesService:Unequip()
		:andThen(function(result)
			if result then
				NotificationController:Notify({ tag = "Coach", text = result.text, type = result.type })
			end
			blockCoachAction = false
			return result
		end)
		:catch(function(err)
			warn(err)
			blockCoachAction = false
		end)
end

function CoachesController:PlayerRemove(player: Player)
	if self.CharacterConnections[player] then
		self.CharacterConnections[player]:Disconnect()
		self.CharacterConnections[player] = nil
	end

	local foundCoaches = Filter(self.CoachInstances:GetChildren(), function(coachModel: Model)
		return coachModel:GetAttribute("Owner") == player.Name
	end) :: { Model }

	for _, coachModel in pairs(foundCoaches) do
		local excludeIndex = table.find(RaycastExcludeModels, coachModel)
		if excludeIndex then
			table.remove(RaycastExcludeModels, excludeIndex)
		end

		if self.CoachAnimationTracks[coachModel] then
			self.CoachAnimationTracks[coachModel]:Stop()
			self.CoachAnimationTracks[coachModel]:Destroy()
			self.CoachAnimationTracks[coachModel] = nil
		end
		self.CoachPreviousPositions[coachModel] = nil
		coachModel:Destroy()
	end

	for Index, Model in pairs(RaycastExcludeModels) do
		if Model.Name == player.Name then
			table.remove(RaycastExcludeModels, Index)
		end
	end

	self.CoachesInSession[player] = nil
	self.RawCoachesByPlayer[player] = nil
end

function CoachesController:RestoreCoachesBehindOwner(player: Player)
	if not player then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local grids = self.CoachesInSession[player]
	if type(grids) ~= "table" then
		return
	end

	for index, grid in pairs(grids) do
		local model = grid and grid.Model
		if typeof(model) == "Instance" and model:IsA("Model") and model.Parent then
			local numericIndex = tonumber(index) or 1
			local targetCFrame = rootPart.CFrame * CFrame.new((numericIndex - 1) * 2.5, 0, 7.5)
			model:PivotTo(targetCFrame)

			if grid.Information then
				grid.Information.Target = rootPart
				grid.Information.Position = targetCFrame.Position
				grid.Information.CFrame = targetCFrame
			end

			self.CoachPreviousPositions[model] = targetCFrame.Position
		end
	end
end

function CoachesController:RefreshPlayerTarget(player: Player)
	local grids = self.CoachesInSession[player]
	if not grids then
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	for _, grid in pairs(grids) do
		if grid.Information then
			grid.Information.Target = hrp
		end
	end
end

function CoachesController:SetupPlayerCharacterLifecycle(player: Player)
	if self.CharacterConnections[player] then
		return
	end

	self.CharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			character:WaitForChild("HumanoidRootPart")
			self:RefreshPlayerTarget(player)

			local coachesData = self.RawCoachesByPlayer[player]
			if coachesData then
				self:AddCoaches(player, coachesData)
			end
		end)
	end)
end

function CoachesController:ReloadCoaches(player: Player)
	self:PlayerRemove(player)
	self:SetupPlayerCharacterLifecycle(player)

	local success, coaches = CoachesService:GetCoaches(player):await()
	if success and coaches then
		local _, data = DataService:GetData(player):await()
		if data and data.Settings.Pets_Visible == true then
			self:AddCoaches(player, coaches)
			return true
		end
	end
	return false
end

function CoachesController:_SetupCoachesArea(instance: BasePart)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	zone.playerEntered:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:ShowFrame({ frame = FramesConstants.Customize })
			Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Coaches))
		end
	end)

	zone.playerExited:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:HideFrame()
		end
	end)
end

--|| Knit Lifecycle ||--
function CoachesController:KnitInit()
	local existingCoachesFolder = workspace:FindFirstChild("Coaches")
	if existingCoachesFolder and existingCoachesFolder:IsA("Folder") then
		self.CoachInstances = existingCoachesFolder
	else
		self.CoachInstances = Instance.new("Folder")
		self.CoachInstances.Name = "Coaches"
		self.CoachInstances.Parent = workspace
	end

	CoachesService = Knit.GetService("CoachesService")
	SettingsService = Knit.GetService("SettingsService")
	DataService = Knit.GetService("DataService")
	TeleportService = Knit.GetService("TeleportService")
	CharacterService = Knit.GetService("CharacterService")

	DataCacheController = Knit.GetController("DataCacheController")
	NotificationController = Knit.GetController("NotificationController")
	TrainingController = Knit.GetController("TrainingController")
	UIController = Knit.GetController("UIController")

	local templateData = DataCacheController:GetFile("Template")
	if templateData and templateData.Coaches then
		self.CoachesTemplate = templateData.Coaches
	else
		self.CoachesTemplate = DataCacheController:GetFile("Coaches")
	end

	self.Colors = DataCacheController:GetFile("Colors")
end

function CoachesController:KnitStart()
	self:HandleMove()

	task.spawn(function()
		for _, Player in pairs(Players:GetPlayers()) do
			self:SetupPlayerCharacterLifecycle(Player)

			task.spawn(function()
				local _ = Player.Character or Player.CharacterAdded:Wait()
				local __, coachesData = CoachesService:GetCoaches(Player):await()
				self:AddCoaches(Player, coachesData)
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:PlayerRemove(player)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		self:SetupPlayerCharacterLifecycle(player)

		local __, coachesData = CoachesService:GetCoaches(player):await()
		self:AddCoaches(player, coachesData)
	end)

	self.CoachInstances.ChildAdded:Connect(function(coachModel: Model)
		local coachNameUI = ReplicatedStorage.Assets.Prompts.CharacterName:Clone()
		coachNameUI.Parent = coachModel

		local NameTL = coachNameUI:WaitForChild("Name")
		local RarityTL = coachNameUI:WaitForChild("Rarity")
		local LevelFrame = coachNameUI:WaitForChild("LevelFrame")
		LevelFrame.Visible = false

		local coachAttributeName = coachModel:GetAttribute("Coach") or coachModel:GetAttribute("Pet")
		local currentCoachData = nil

		for _, coachData in pairs(self.CoachesTemplate) do
			if coachData.Name == coachAttributeName then
				currentCoachData = coachData
				break
			end
		end

		if currentCoachData then
			NameTL.Text = currentCoachData.DisplayName or currentCoachData.Name
			NameTL.TextColor3 = self.Colors["Normal"] or Color3.fromRGB(255, 255, 255)

			if currentCoachData.VIP then
				RarityTL.Text = "VIP Coach"
				RarityTL.TextColor3 = self.Colors["Legendary"] or Color3.fromRGB(255, 215, 0)
			else
				RarityTL.Text = "Coach"
				RarityTL.TextColor3 = self.Colors["Common"] or Color3.fromRGB(200, 200, 200)
			end
		else
			NameTL.Text = coachAttributeName or "Unknown"
		end
	end)

	CoachesService.PlayerCoachesUpdated:Connect(function(player: Player, coachesData)
		self:AddCoaches(player, coachesData)
	end)

	TeleportService.PlayerTeleported:Connect(function(player)
		local coachesData = self.RawCoachesByPlayer[player]
		if coachesData then
			self:AddCoaches(player, {})
			self:AddCoaches(player, coachesData)
		end
	end)

	SettingsService.SettingsUpdated:Connect(function(settings: table)
		for _, Player in pairs(Players:GetPlayers()) do
			local _ = Player.Character or Player.CharacterAdded:Wait()
			local __, coachesData = CoachesService:GetCoaches(Player):await()
			self:AddCoaches(Player, coachesData)
		end
	end)

	CharacterService.CharacterLoaded:Connect(function()
		task.spawn(function()
			local player = Players.LocalPlayer

			local character = player.Character
			if not character or not character.Parent then
				character = player.CharacterAdded:Wait()
			end

			character:WaitForChild("HumanoidRootPart")
			self:ReloadCoaches(player)
		end)
	end)

	local existingAreas = CollectionService:GetTagged("CoachesArea")
	for _, instance in pairs(existingAreas) do
		self:_SetupCoachesArea(instance)
	end

	CollectionService:GetInstanceAddedSignal("CoachesArea"):Connect(function(instance)
		self:_SetupCoachesArea(instance)
	end)

	print("[COACHES CONTROLLER] Controller loaded successfully.")
end

return CoachesController
