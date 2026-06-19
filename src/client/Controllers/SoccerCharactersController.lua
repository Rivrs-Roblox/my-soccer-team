-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- Knit packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local ZonePlus = require(ReplicatedStorage.ZonePlus)

-- Knit Services
local DataService
local TeleportService
local TeamService
local AccessoryService
local SoccerCharactersService

-- Knit Controllers
local DataCacheController
local UIController
local TrainingController

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local GridFunctions = require(Helpers.SoccerCharacters.Grid)
local Update = require(Helpers.SoccerCharacters.Update)
local TrainingUpdate = require(Helpers.Training.Update)
local Filter = require(Helpers.Table.Filter)
local EquipAccessory = require(Helpers.SoccerCharacters.EquipAccessory)
local MatchCharacterPropVisibility = require(script.Parent.Parent.Helpers.Match.Presentation.MatchCharacterPropVisibility)

-- Variables
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local RaycastExcludeModels = {}

local Functions = {
	GetTableAmount = require(Helpers.Table.GetTableAmount),
	GetAngleDistance = require(Helpers.Math.GetAngleDistance),
	DeepCopy = require(Helpers.Table.DeepCopy),
	GetModel = require(Helpers.SoccerCharacters.GetModel),
	EquipAccessory = EquipAccessory,
}

-- SoccerCharactersController
local SoccerCharactersController = Knit.CreateController({
	Name = "SoccerCharactersController",
	SoccerCharactersInSession = {} :: table,
	AccessoriesByPlayer = {} :: table,
	RawSoccerCharactersByPlayer = {} :: table,
	CharacterConnections = {} :: table,
	SoccerCharacterInstances = nil,
})

--|| Local Functions ||--
local function setupMergeZone(instance: BasePart)
	local zone = ZonePlus.new(instance)
	zone:setDetection("Centre")

	zone.playerEntered:Connect(function(player: Player)
		if player == Players.LocalPlayer then
			UIController:ShowFrame({ frame = FramesConstants.MergeCharacters })
		end
	end)

	zone.playerExited:Connect(function(player: Player)
		if player == Players.LocalPlayer then
			UIController:HideFrame()
		end
	end)
end

--|| Functions ||--
function SoccerCharactersController:BuildEquippedCharacters(data: table, equippedSoccerCharacters: table?, soccerCharacters: table?): table
	local equipped = {}
	local inventory = soccerCharacters or (data.Inventory and data.Inventory.SoccerCharacters) or {}
	local equippedIds = equippedSoccerCharacters or (data.Inventory and data.Inventory.EquippedSoccerCharacters) or {}

	for _, id in pairs(equippedIds) do
		local char = inventory[tostring(id)] or inventory[tonumber(id)] or inventory[id]
		if char then
			table.insert(equipped, char)
		end
	end

	return equipped
end

function SoccerCharactersController:ApplyEquippedCharactersPayload(player: Player, payload: table)
	payload = payload or {}
	self.AccessoriesByPlayer[player] = payload.Accessories or {}
	self:AddCharacters(player, payload.Equipped or {})
end

function SoccerCharactersController:RefreshEquippedCharacters(player: Player)
	local success, payload = SoccerCharactersService:GetEquippedCharacters(player):await()
	if success and payload then
		self:ApplyEquippedCharactersPayload(player, payload)
		return true
	end

	return false
end

function SoccerCharactersController:DestroyRenderedCharacter(player: Player, index: string | number)
	local modelName = player.Name .. "_" .. tostring(index)

	for _, soccerCharacter in self.SoccerCharacterInstances:GetChildren() do
		if soccerCharacter.Name == modelName then
			local excludeIndex = table.find(RaycastExcludeModels, soccerCharacter)
			if excludeIndex then
				table.remove(RaycastExcludeModels, excludeIndex)
			end

			soccerCharacter:Destroy()
		end
	end
end

function SoccerCharactersController:CleanupRenderedCharacters(player: Player, generatedCharacters: table)
	local keptByName = {}

	for _, soccerCharacter in self.SoccerCharacterInstances:GetChildren() do
		if soccerCharacter:GetAttribute("Owner") ~= player.Name then
			continue
		end

		local keep = false
		for index in pairs(generatedCharacters) do
			local modelName = player.Name .. "_" .. tostring(index)
			if soccerCharacter.Name == modelName and not keptByName[modelName] then
				keptByName[modelName] = true
				generatedCharacters[index].Model = soccerCharacter
				keep = true
				break
			end
		end

		if not keep then
			local excludeIndex = table.find(RaycastExcludeModels, soccerCharacter)
			if excludeIndex then
				table.remove(RaycastExcludeModels, excludeIndex)
			end

			soccerCharacter:Destroy()
		end
	end

	for index, grid in pairs(generatedCharacters) do
		local model = grid.Model
		if not (typeof(model) == "Instance" and model.Parent) then
			grid.Model = ""
		end
	end
end

function SoccerCharactersController:AddCharacters(player: Player, SoccerCharacters: table)
	SoccerCharacters = SoccerCharacters or {}
	self.RawSoccerCharactersByPlayer[player] = SoccerCharacters

	if not self.SoccerCharactersInSession[player] then
		self.SoccerCharactersInSession[player] = {}
	end

	--// Detection for data change
	local OldCharacterNames = {}
	for i, v in pairs(self.SoccerCharactersInSession[player]) do
		if v.Data and v.Data ~= "None" then
			OldCharacterNames[i] = v.Data.Name
		end
	end

	local GeneratedSoccerCharacters =
		GridFunctions.GetGrids(SoccerCharacters, self.SoccerCharactersInSession[player], player)

	for i, v in pairs(GeneratedSoccerCharacters) do
		if not self.SoccerCharactersInSession[player][i] then
			self.SoccerCharactersInSession[player][i] = v
		elseif OldCharacterNames[i] and v.Data.Name ~= OldCharacterNames[i] then
			-- Character in this slot changed, destroy old model to trigger recreation
			self:DestroyRenderedCharacter(player, i)

			-- Reset animation state to ensure new character plays animations
			v.LastInformation.Animations = nil
			v.LastInformation.CurrentAnimation = nil
		elseif self.SoccerCharacterInstances:FindFirstChild(player.Name .. "_" .. tostring(i)) then
			-- Model exists, check if accessories changed or just refresh them
			local model = self.SoccerCharacterInstances:FindFirstChild(player.Name .. "_" .. tostring(i))

			-- Optimization: Only re-equip if accessories data actually changed
			local HttpService = game:GetService("HttpService")
			local currentAccessoriesHash = HttpService:JSONEncode(v.Data.Accessories or {})
			local lastAccessoriesHash = v.LastAccessoriesHash

			if currentAccessoriesHash ~= lastAccessoriesHash then
				v.LastAccessoriesHash = currentAccessoriesHash
				Functions.EquipAccessory(model, v.Data, self.AccessoriesByPlayer[player] or {})
			end
		end
	end

	for i, _ in self.SoccerCharactersInSession[player] do
		if not GeneratedSoccerCharacters[i] then
			self.SoccerCharactersInSession[player][i] = nil
			self:DestroyRenderedCharacter(player, i)
		end
	end

	self:CleanupRenderedCharacters(player, GeneratedSoccerCharacters)
	self:RefreshPlayerTarget(player)
end

function SoccerCharactersController:ResetCollisionGroups()
	for _, session in pairs(self.SoccerCharactersInSession) do
		for _, grid in pairs(session) do
			local model = grid.Model
			if model and typeof(model) == "Instance" then
				for _, v in ipairs(model:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CollisionGroup = "Humanoid"
						v.Anchored = false
					end
				end
			end
		end
	end
end

function SoccerCharactersController:HandleMove()
	RunService:BindToRenderStep("SoccerCharacters", Enum.RenderPriority.Last.Value, function(Delta: number)
		local trainingSessions = {}
		local normalSessions = {}

		for player, session in pairs(self.SoccerCharactersInSession) do
			local wasTraining = self._lastTrainingStates and self._lastTrainingStates[player]
			local isTraining = TrainingController.VisualStates[player] ~= nil

			if isTraining then
				trainingSessions[player] = session

				-- If they just started training, stop normal animations for a clean transition
				if not wasTraining then
					for _, grid in pairs(session) do
						local model = grid.Model
						if model and typeof(model) == "Instance" then
							local animator = model:FindFirstChildWhichIsA("Animator", true)
							if animator then
								for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
									track:Stop(0)
								end
							end
						end

						-- Reset last info to ensure TrainingUpdate starts fresh
						grid.LastInformation = {}
					end
				end
			else
				normalSessions[player] = session

				-- If they just stopped training, reset state for a clean transition
				if wasTraining then
					for _, grid in pairs(session) do
						local model = grid.Model
						if model and typeof(model) == "Instance" then
							-- Stop ALL animation tracks on this model
							local animator = model:FindFirstChildWhichIsA("Animator", true)
							if animator then
								for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
									track:Stop(0)
								end
							end

							-- Hide any embedded football parts that TrainingUpdate may have shown.
							for _, child in ipairs(model:GetDescendants()) do
								if child:IsA("BasePart") then
									local isBallPart = child.Name == "Ball" or child.Name == "Football"
									local current = child.Parent

									while not isBallPart and current do
										if current.Name == "Football" or current.Name == "BallRoot" then
											isBallPart = true
										end
										current = current.Parent
									end

									if isBallPart then
										child.Transparency = 1
										child.LocalTransparencyModifier = 1
										child.CanCollide = false
										child.CanTouch = false
										child.CanQuery = false
									end
								end
							end
						end

						-- Completely wipe the last information to force re-initialization in normal Update
						grid.LastInformation = {}
					end
				end
			end

			if not self._lastTrainingStates then
				self._lastTrainingStates = {}
			end
			self._lastTrainingStates[player] = isTraining
		end

		if next(trainingSessions) then
			TrainingUpdate(
				Delta,
				{
					GetTableAmount = Functions.GetTableAmount,
					GetAngleDistance = Functions.GetAngleDistance,
					GetModel = Functions.GetModel,
					EquipAccessory = Functions.EquipAccessory,
				},
				trainingSessions,
				self.SoccerCharacters,
				self.SoccerCharacterInstances,
				RaycastExcludeModels,
				TrainingController.VisualStates,
				self.AccessoriesByPlayer
			)
		end

		if next(normalSessions) then
			Update(
				Delta,
				Functions,
				normalSessions,
				self.SoccerCharacters,
				self.SoccerCharacterInstances,
				RaycastExcludeModels,
				self.AccessoriesByPlayer
			)

			MatchCharacterPropVisibility.ForceHideKnownRuntimeTrophies(Players.LocalPlayer)
		end
	end)
end

function SoccerCharactersController:PlayerRemove(player: Player)
	if self.CharacterConnections[player] then
		self.CharacterConnections[player]:Disconnect()
		self.CharacterConnections[player] = nil
	end

	local FoundSoccerCharacters = Filter(
		self.SoccerCharacterInstances:GetChildren(),
		function(SoccerCharacter: Model)
			return SoccerCharacter:GetAttribute("Owner") == player.Name
		end
	) :: { Model }

	for _, SoccerCharacter in FoundSoccerCharacters do
		local ExcludeIndex = table.find(RaycastExcludeModels, SoccerCharacter)
		if ExcludeIndex then
			table.remove(RaycastExcludeModels, ExcludeIndex)
		end

		SoccerCharacter:Destroy()
	end

	for Index, Model in RaycastExcludeModels do
		if Model.Name == player.Name then
			table.remove(RaycastExcludeModels, Index)
		end
	end

	self.SoccerCharactersInSession[player] = nil
	self.AccessoriesByPlayer[player] = nil
	self.RawSoccerCharactersByPlayer[player] = nil
end

function SoccerCharactersController:RefreshPlayerTarget(player: Player)
	local grids = self.SoccerCharactersInSession[player]
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

function SoccerCharactersController:SetupPlayerCharacterLifecycle(player: Player)
	if self.CharacterConnections[player] then
		return
	end

	self.CharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			character:WaitForChild("HumanoidRootPart")
			self:RefreshPlayerTarget(player)

			local soccerCharacters = self.RawSoccerCharactersByPlayer[player]
			if soccerCharacters then
				self:AddCharacters(player, soccerCharacters)
			end
		end)
	end)
end

--|| Knit Lifecycle ||--
function SoccerCharactersController:KnitInit()
	local existingSoccerCharactersFolder = workspace:FindFirstChild("SoccerCharacters")
	if existingSoccerCharactersFolder and existingSoccerCharactersFolder:IsA("Folder") then
		self.SoccerCharacterInstances = existingSoccerCharactersFolder
	else
		self.SoccerCharacterInstances = Instance.new("Folder")
		self.SoccerCharacterInstances.Name = "SoccerCharacters"
		self.SoccerCharacterInstances.Parent = workspace
	end

	DataService = Knit.GetService("DataService")
	TeleportService = Knit.GetService("TeleportService")
	TeamService = Knit.GetService("TeamService")
	AccessoryService = Knit.GetService("AccessoryService")
	SoccerCharactersService = Knit.GetService("SoccerCharactersService")

	DataCacheController = Knit.GetController("DataCacheController")
	UIController = Knit.GetController("UIController")
	TrainingController = Knit.GetController("TrainingController")

	self.SoccerCharacters = DataCacheController:GetFile("Template").SoccerCharacters
	self.Colors = DataCacheController:GetFile("Colors")
end

function SoccerCharactersController:KnitStart()
	task.spawn(function()
		for _, Player in Players:GetPlayers() do
			self:SetupPlayerCharacterLifecycle(Player)

			task.spawn(function()
				local _ = Player.Character or Player.CharacterAdded:Wait()
				self:RefreshEquippedCharacters(Player)
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:PlayerRemove(player)
	end)
	Players.PlayerAdded:Connect(function(player: Player)
		self:SetupPlayerCharacterLifecycle(player)

		self:RefreshEquippedCharacters(player)
	end)

	self.SoccerCharacterInstances.ChildAdded:Connect(function(SoccerCharacter: Model)
		local CharacterName = ReplicatedStorage.Assets.Prompts.CharacterName:Clone()
		CharacterName.Parent = SoccerCharacter

		local Name = SoccerCharacter:GetAttribute("SoccerCharacter")
		local NameTL = CharacterName:WaitForChild("Name")
		local RarityTL = CharacterName:WaitForChild("Rarity")
		local LevelTL = CharacterName:FindFirstChild("Level", true)

		NameTL.Text = self.SoccerCharacters[Name].Name

		RarityTL.Text = self.SoccerCharacters[Name].Rarity
		RarityTL.TextColor3 = self.Colors[RarityTL.Text]

		LevelTL.Text = `{SoccerCharacter:GetAttribute("Level")}`
	end)

	TeamService.TeamSlotSet:Connect(function(player)
		self:RefreshEquippedCharacters(player)
	end)

	TeleportService.PlayerTeleported:Connect(function(player)
		local soccerCharacters = self.RawSoccerCharactersByPlayer[player]
		if soccerCharacters then
			self:AddCharacters(player, {})
			self:AddCharacters(player, soccerCharacters)
		end
	end)

	AccessoryService.AccessoriesUpdated:Connect(function(accessoriesInventory)
		self.AccessoriesByPlayer[Players.LocalPlayer] = accessoriesInventory
	end)

	SoccerCharactersService.SoccerCharactersUpdated:Connect(function(soccerInventory)
		local ___, Data = DataService:GetData():await()
		if Data and Data.Inventory then
			self.AccessoriesByPlayer[Players.LocalPlayer] = Data.Inventory.Accessories
			self:AddCharacters(Players.LocalPlayer, self:BuildEquippedCharacters(Data, nil, soccerInventory))
		end
	end)

	SoccerCharactersService.EquippedCharactersUpdated:Connect(function(player, payload)
		self:ApplyEquippedCharactersPayload(player, payload)
	end)

	self:HandleMove()

	local existingAreas = CollectionService:GetTagged("MergeCharacters")
	for _, instance in existingAreas do
		setupMergeZone(instance)
	end

	CollectionService:GetInstanceAddedSignal("MergeCharacters"):Connect(setupMergeZone)
end

return SoccerCharactersController
