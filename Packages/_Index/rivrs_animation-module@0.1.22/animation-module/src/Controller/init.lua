--|| Services ||--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| Imports ||--
local ImportFolder = ReplicatedStorage:FindFirstChild("Packages")

local src = script
while src and src.Name ~= "src" do
	src = src:FindFirstAncestorWhichIsA("Folder")
end

local function importPackage(name: string)
	local RootFolder = src and src:FindFirstAncestorWhichIsA("Folder") or nil

	return RootFolder and require(RootFolder[name]) or require(ImportFolder:FindFirstChild(name))
end

local Knit = importPackage("knit")

local AnimationDataFolder = ReplicatedStorage.Shared.AnimationDataFolder
local MoonAnimationDataFolder = ReplicatedStorage.Shared.MoonAnimationDataFolder

local AnimationModule = require(script.Modules.AnimationModule)
local MoonAnimationModule = require(script.Modules.MoonAnimationModule)

-- Player
local player = Players.LocalPlayer

--|| Knit Services ||--
local AnimationService = nil

--|| Controller ||--
local AnimationCtrl = Knit.CreateController({
	Name = "AnimationCtrl",
	Animations = {},
})

function AnimationCtrl:GetOrCreateAnimation(AnimationName, Character)
	local key = AnimationName .. "_" .. Character:GetFullName()

	if self.Animations[key] then
		return self.Animations[key]
	end

	local function findModuleRecursive(folder, name)
		local found = folder:FindFirstChild(name)
		if found then
			return found
		end

		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Folder") then
				local result = findModuleRecursive(child, name)
				if result then
					return result
				end
			end
		end
		return nil
	end

	local AnimationData

	local regularAnim = findModuleRecursive(AnimationDataFolder, AnimationName)
	local moonAnim = findModuleRecursive(MoonAnimationDataFolder, AnimationName)

	if regularAnim then
		AnimationData = require(regularAnim)
	elseif moonAnim then
		AnimationData = require(moonAnim)
	else
		warn("Animation data not found for: " .. AnimationName)
		return nil
	end

	local animation

	if AnimationData.AnimationType == "Basic" then
		animation = AnimationModule.new(AnimationData.Id, AnimationData, Character)
	elseif AnimationData.AnimationType == "Moon" then
		animation = MoonAnimationModule.new(AnimationData.Id, AnimationData, Character)
	else
		warn("Unknown animation type for animation: " .. AnimationName)
		return nil
	end

	animation:preload()
	self.Animations[key] = animation
	return animation
end

function AnimationCtrl:GetAnimation(AnimationName, Character)
	local key = AnimationName .. "_" .. Character:GetFullName()
	if self.Animations[key] then
		return self.Animations[key]
	end
end

function AnimationCtrl:PlayAnim(AnimationName, Character)
	local animation = self:GetOrCreateAnimation(AnimationName, Character or player.Character)
	if animation then
		animation:play()
	end
	return animation
end

function AnimationCtrl:StopAnim(AnimationName, Character)
	Character = Character or player.Character
	if not Character then
		return
	end

	local animation = self:GetAnimation(AnimationName, Character)
	if animation then
		animation:stop()
	end
	return animation
end

function AnimationCtrl:PlayAndDestroyAnimation(AnimationName, Character)
	Character = Character or player.Character
	if not Character then
		return
	end

	local animation = self:GetOrCreateAnimation(AnimationName, Character)
	if animation then
		animation:play()

		animation.animationTrack.Stopped:Connect(function()
			task.wait(0.5) -- Small delay to ensure any end-of-animation logic completes
			self:DestroyAnimation(AnimationName, Character)
		end)
	end
	return animation
end

function AnimationCtrl:PreloadAnimation(AnimationName, Character)
	Character = Character or player.Character
	if not Character then
		warn("The Character you're trying to load an animation on is nil")
		return
	end

	return self:GetOrCreateAnimation(AnimationName, Character)
end

function AnimationCtrl:DestroyAnimation(AnimationName, Character)
	Character = Character or player.Character
	if not Character then
		return
	end

	local key = AnimationName .. "_" .. Character:GetFullName()
	local animation = self.Animations[key]

	if animation then
		animation:destroy()
		self.Animations[key] = nil
	end
end

function AnimationCtrl:CleanupPlayerAnimations(playerDis)
	for key, animation in pairs(self.Animations) do
		if key:find(playerDis.Name) then
			animation:destroy()
			self.Animations[key] = nil
		end
	end
end

function AnimationCtrl:PlayerServerAnimOnSelf(AnimationName, cameraReplication)
	self:PlayServerAnim(AnimationName, player.Character, cameraReplication)
end

function AnimationCtrl:PlayServerAnim(AnimationName, Character, cameraReplication)
	self:PlayAnim(AnimationName, Character)
	return AnimationService:PlayAnimation(AnimationName, Character, cameraReplication)
end

function AnimationCtrl:PlayOnlyItemsMoonAnim(AnimationName, Character, cameraReplication)
	local animation = self:GetOrCreateAnimation(AnimationName, Character)
	animation:playOnlyItems(cameraReplication)
end

function AnimationCtrl:PlayRequestedAnimFromServ(AnimationName, Character, cameraReplication)
	local animationData = require(
		AnimationDataFolder:FindFirstChild(AnimationName) or MoonAnimationDataFolder:FindFirstChild(AnimationName)
	)
	local playerForAnim = Players:GetPlayerFromCharacter(Character)
	if playerForAnim then
		if animationData.AnimationType == "Basic" then
			return
		elseif playerForAnim ~= player then
			self:PlayOnlyItemsMoonAnim(AnimationName, Character, cameraReplication)
		end
	else
		self:PlayAnim(AnimationName, Character)
	end
end

--|| Methods ||--

--|| Knit Lifecycle ||--
function AnimationCtrl:KnitInit()
	AnimationService = Knit.GetService("AnimationServ")

	AnimationService.PlayAnimSignal:Connect(function(animationName, Character, cameraReplication)
		self:PlayRequestedAnimFromServ(animationName, Character, cameraReplication)
	end)

	Players.PlayerRemoving:Connect(function(playerDis)
		self:CleanupPlayerAnimations(playerDis)
	end)
end

return AnimationCtrl
