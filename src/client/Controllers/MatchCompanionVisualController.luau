local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchCharacterVisualRestore = require(script.Parent.Parent.Helpers.Match.Presentation.MatchCharacterVisualRestore)

local MATCH_RETURN_FORMATION_OFFSETS = {
	[1] = Vector3.new(-3.5, 0, 5.5),
	[2] = Vector3.new(0, 0, 6.4),
	[3] = Vector3.new(3.5, 0, 5.5),
}

local SoccerCharactersController = nil
local MatchActorRuntimeController = nil
local CoachesController = nil

local maskStateByInstance = setmetatable({}, { __mode = "k" })

local MatchCompanionVisualController = Knit.CreateController({
	Name = "MatchCompanionVisualController",

	OriginalCharacterMask = nil,
	HasWarnedMissingMask = false,
})

-- // [ MASK RESOLVER ] // --

local function findOriginalCharacterMaskModule()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		return nil
	end

	local helpers = shared:FindFirstChild("Helpers")
	if not helpers then
		return nil
	end

	local soccerCharacters = helpers:FindFirstChild("SoccerCharacters")
	if soccerCharacters then
		local maskModule = soccerCharacters:FindFirstChild("OriginalCharacterMask")
		if maskModule and maskModule:IsA("ModuleScript") then
			return maskModule
		end
	end

	local soccerCharacter = helpers:FindFirstChild("SoccerCharacter")
	if soccerCharacter then
		local maskModule = soccerCharacter:FindFirstChild("OriginalCharacterMask")
		if maskModule and maskModule:IsA("ModuleScript") then
			return maskModule
		end
	end

	local maskModule = helpers:FindFirstChild("OriginalCharacterMask", true)
	if maskModule and maskModule:IsA("ModuleScript") then
		return maskModule
	end

	return nil
end

local function cacheVisualState(instance: Instance)
	if maskStateByInstance[instance] then
		return
	end

	if instance:IsA("BasePart") then
		maskStateByInstance[instance] = {
			ClassName = "BasePart",
			LocalTransparencyModifier = instance.LocalTransparencyModifier,
			CanCollide = instance.CanCollide,
			CanTouch = instance.CanTouch,
			CanQuery = instance.CanQuery,
		}
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		maskStateByInstance[instance] = {
			ClassName = instance.ClassName,
			Transparency = instance.Transparency,
		}
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("Highlight") then
		maskStateByInstance[instance] = {
			ClassName = instance.ClassName,
			Enabled = instance.Enabled,
		}
	end
end

local function applyFallbackMask(root: Instance?, hidden: boolean)
	if not root then
		return
	end

	local function applyToInstance(instance: Instance)
		if instance:IsA("BasePart") then
			if hidden then
				cacheVisualState(instance)

				instance.LocalTransparencyModifier = 1
				instance.CanCollide = false
				instance.CanTouch = false
				instance.CanQuery = false
			else
				local cachedState = maskStateByInstance[instance]
				if cachedState then
					instance.LocalTransparencyModifier = cachedState.LocalTransparencyModifier or 0
					instance.CanCollide = cachedState.CanCollide == true
					instance.CanTouch = cachedState.CanTouch == true
					instance.CanQuery = cachedState.CanQuery == true
					maskStateByInstance[instance] = nil
				else
					instance.LocalTransparencyModifier = 0
				end
			end
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			if hidden then
				cacheVisualState(instance)
				instance.Transparency = 1
			else
				local cachedState = maskStateByInstance[instance]
				if cachedState then
					instance.Transparency = cachedState.Transparency or 0
					maskStateByInstance[instance] = nil
				else
					instance.Transparency = 0
				end
			end
		elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") or instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("Highlight") then
			if hidden then
				cacheVisualState(instance)
				instance.Enabled = false
			else
				local cachedState = maskStateByInstance[instance]
				if cachedState then
					instance.Enabled = cachedState.Enabled == true
					maskStateByInstance[instance] = nil
				else
					instance.Enabled = true
				end
			end
		end
	end

	applyToInstance(root)

	for _, descendant in ipairs(root:GetDescendants()) do
		applyToInstance(descendant)
	end
end

function MatchCompanionVisualController:_getOriginalCharacterMask()
	if self.OriginalCharacterMask then
		return self.OriginalCharacterMask
	end

	local maskModule = findOriginalCharacterMaskModule()
	if maskModule then
		local ok, resolvedMask = pcall(function()
			return require(maskModule)
		end)

		if ok and type(resolvedMask) == "table" and type(resolvedMask.SetHidden) == "function" then
			self.OriginalCharacterMask = resolvedMask
			return self.OriginalCharacterMask
		end

		warn("[MatchCompanionVisualController] OriginalCharacterMask found but failed to load. Using fallback visual mask.")
	elseif not self.HasWarnedMissingMask then
		self.HasWarnedMissingMask = true
		warn("[MatchCompanionVisualController] OriginalCharacterMask not found. Using fallback visual mask.")
	end

	self.OriginalCharacterMask = {
		SetHidden = applyFallbackMask,
	}

	return self.OriginalCharacterMask
end

local function setVisualHidden(maskModule, model: Instance?, hidden: boolean)
	if not model then
		return
	end

	if maskModule and type(maskModule.SetHidden) == "function" then
		maskModule.SetHidden(model, hidden)
		return
	end

	applyFallbackMask(model, hidden)
end

-- // [ CONTROLLER RESOLVERS ] // --

local function getSoccerCharactersController()
	if SoccerCharactersController then
		return SoccerCharactersController
	end

	local ok, controller = pcall(function()
		return Knit.GetController("SoccerCharactersController")
	end)

	if ok then
		SoccerCharactersController = controller
	end

	return SoccerCharactersController
end

local function getMatchActorRuntimeController()
	if MatchActorRuntimeController then
		return MatchActorRuntimeController
	end

	local ok, controller = pcall(function()
		return Knit.GetController("MatchActorRuntimeController")
	end)

	if ok then
		MatchActorRuntimeController = controller
	end

	return MatchActorRuntimeController
end

local function getCoachesController()
	if CoachesController then
		return CoachesController
	end

	local ok, controller = pcall(function()
		return Knit.GetController("CoachesController")
	end)

	if ok then
		CoachesController = controller
	end

	return CoachesController
end

-- // [ PRIVATE HELPERS ] // --

local function getOwnedCompanionModels(player: Player)
	local soccerController = getSoccerCharactersController()
	if not soccerController or not soccerController.SoccerCharacterInstances then
		return {}
	end

	local result = {}

	for _, soccerCharacter in ipairs(soccerController.SoccerCharacterInstances:GetChildren()) do
		if soccerCharacter:IsA("Model") then
			local ownerName = soccerCharacter:GetAttribute("Owner")
			local ownerUserId = soccerCharacter:GetAttribute("OwnerUserId")

			if ownerName == player.Name or ownerUserId == player.UserId then
				table.insert(result, soccerCharacter)
			end
		end
	end

	table.sort(result, function(a, b)
		local slotA = tonumber(a:GetAttribute("CompanionSlot")) or math.huge
		local slotB = tonumber(b:GetAttribute("CompanionSlot")) or math.huge

		if slotA == slotB then
			return a.Name < b.Name
		end

		return slotA < slotB
	end)

	return result
end

local function getResolvedMatchCompanionPivotOrder(companionPivotOrder)
	local resolved = {}

	if typeof(companionPivotOrder) == "table" then
		for _, slotNumber in ipairs(companionPivotOrder) do
			local numericSlot = tonumber(slotNumber)

			if numericSlot and numericSlot >= 2 and numericSlot <= 4 then
				if not table.find(resolved, numericSlot) then
					table.insert(resolved, numericSlot)
				end
			end
		end
	end

	for slotNumber = 2, 4 do
		if not table.find(resolved, slotNumber) then
			table.insert(resolved, slotNumber)
		end
	end

	return resolved
end

local function getMatchCompanionPivotCFrame(slotNumber: number, fallbackCFrame: CFrame): (CFrame, BasePart?)
	local pivotPart = MatchSceneQuery.GetCompanionPivot(slotNumber)

	if pivotPart and pivotPart:IsA("BasePart") then
		return pivotPart.CFrame, pivotPart
	end

	return fallbackCFrame, nil
end

local function getOwnerRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function getReturnFormationOffset(index: number): Vector3
	return MATCH_RETURN_FORMATION_OFFSETS[index] or Vector3.new((index - 2) * 3.5, 0, 6.4)
end

local function buildReturnFormationCFrame(player: Player, index: number, fallback: CFrame?): CFrame
	local rootPart = getOwnerRootPart(player)
	if not rootPart then
		return fallback or CFrame.new()
	end

	local localOffset = getReturnFormationOffset(index)
	local targetPosition = rootPart.CFrame:PointToWorldSpace(localOffset)
	targetPosition = Vector3.new(targetPosition.X, rootPart.Position.Y, targetPosition.Z)

	return CFrame.lookAt(targetPosition, targetPosition + rootPart.CFrame.LookVector)
end

local function syncCompanionGridStateToCFrame(player: Player, gridIndex: number, targetCFrame: CFrame)
	local soccerController = getSoccerCharactersController()
	if not soccerController or not soccerController.SoccerCharactersInSession then
		return
	end

	local playerGrids = soccerController.SoccerCharactersInSession[player]
	local grid = playerGrids and playerGrids[gridIndex]
	if not grid then
		return
	end

	local lastInfo = grid.LastInformation
	if lastInfo then
		lastInfo.Position = CFrame.new(targetCFrame.Position.X, 0, targetCFrame.Position.Z)
		lastInfo.Raycast = CFrame.new(0, targetCFrame.Position.Y, 0)
		lastInfo.Distance = 0
		lastInfo.AnimationPosition = CFrame.new()
		lastInfo.AnimationRotation = CFrame.new()
		lastInfo.AnimationHeight = 0

		local _, y, _ = targetCFrame:ToOrientation()
		lastInfo.Orientation = CFrame.fromOrientation(0, y, 0)
	end

	if grid.Information then
		grid.Information.Arrived = true
	end

	grid.TimeElapsed = 0
end

-- // [ PUBLIC API ] // --

function MatchCompanionVisualController:GetOwnedCompanionModels(player: Player)
	if not player then
		return {}
	end

	return getOwnedCompanionModels(player)
end

function MatchCompanionVisualController:ResolveMatchCompanionPivotOrder(companionPivotOrder)
	return getResolvedMatchCompanionPivotOrder(companionPivotOrder)
end

function MatchCompanionVisualController:GetMatchCompanionPivotCFrame(slotNumber: number, fallbackCFrame: CFrame)
	local cframe = select(1, getMatchCompanionPivotCFrame(slotNumber, fallbackCFrame))
	return cframe
end

function MatchCompanionVisualController:SyncCompanionGridStateToCFrame(
	player: Player,
	gridIndex: number,
	targetCFrame: CFrame
)
	if not player or not targetCFrame then
		return
	end

	syncCompanionGridStateToCFrame(player, gridIndex, targetCFrame)
end

function MatchCompanionVisualController:RestoreCompanionsBehindOwner(player: Player)
	if not player then
		return
	end

	local ownedCompanions = getOwnedCompanionModels(player)
	if #ownedCompanions == 0 then
		return
	end

	for index, companionModel in ipairs(ownedCompanions) do
		if companionModel and companionModel.Parent then
			local targetCFrame = buildReturnFormationCFrame(player, index, companionModel:GetPivot())
			companionModel:PivotTo(targetCFrame)
			syncCompanionGridStateToCFrame(player, index, targetCFrame)
		end
	end
end

function MatchCompanionVisualController:SetOwnerVisualHidden(
	ownerPlayer: Player,
	hidden: boolean,
	includeOriginalCharacter: boolean?
)
	if not ownerPlayer then
		return
	end

	local maskModule = self:_getOriginalCharacterMask()
	local shouldHideOriginal = includeOriginalCharacter ~= false

	if shouldHideOriginal and ownerPlayer.Character then
		setVisualHidden(maskModule, ownerPlayer.Character, hidden)
		if not hidden then
			MatchCharacterVisualRestore.RestoreCharacterVisuals(ownerPlayer.Character)
			MatchCharacterVisualRestore.HideTrophyVisuals(ownerPlayer.Character)
		end
	end

	local soccerController = getSoccerCharactersController()
	if soccerController and soccerController.SoccerCharacterInstances then
		for _, companionModel in ipairs(soccerController.SoccerCharacterInstances:GetChildren()) do
			if companionModel:IsA("Model") then
				local ownerName = companionModel:GetAttribute("Owner")
				local ownerUserId = companionModel:GetAttribute("OwnerUserId")

				if ownerName == ownerPlayer.Name or ownerUserId == ownerPlayer.UserId then
					setVisualHidden(maskModule, companionModel, hidden)
					if not hidden then
						MatchCharacterVisualRestore.RestoreCharacterVisuals(companionModel)
						MatchCharacterVisualRestore.HideTrophyVisuals(companionModel)
					end
				end
			end
		end
	end

	local coachesController = getCoachesController()
	if coachesController and coachesController.CoachInstances then
		local hideCoach = hidden or (ownerPlayer:GetAttribute("IsInMatch") == true)
		for _, coachModel in ipairs(coachesController.CoachInstances:GetChildren()) do
			if coachModel:IsA("Model") then
				local ownerName = coachModel:GetAttribute("Owner")
				local ownerUserId = coachModel:GetAttribute("OwnerUserId")

				if ownerName == ownerPlayer.Name or ownerUserId == ownerPlayer.UserId then
					setVisualHidden(maskModule, coachModel, hideCoach)
					if not hideCoach then
						MatchCharacterVisualRestore.RestoreCharacterVisuals(coachModel)
						MatchCharacterVisualRestore.HideTrophyVisuals(coachModel)
					end
				end
			end
		end
	end
end

function MatchCompanionVisualController:IsLocalMatchActive(player: Player): boolean
	if not player then
		return false
	end

	local runtimeController = getMatchActorRuntimeController()
	if runtimeController and runtimeController.IsLocalMatchActive then
		return runtimeController:IsLocalMatchActive(player) == true
	end

	return false
end

function MatchCompanionVisualController:KnitStart()
	self:_getOriginalCharacterMask()
	getSoccerCharactersController()
	getMatchActorRuntimeController()
	getCoachesController()
end

return MatchCompanionVisualController