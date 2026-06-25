--[=[
	Owner: Shakthi
	Version: v0.0.1
	Purpose:
	- hide training proximity prompt only for local player while training
	- show again when training stops
	- does NOT affect other players
]=]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TrainingService

local localTrainingActive = false

local TrainingPromptVisibilityController = Knit.CreateController({
	Name = "TrainingPromptVisibilityController",
})

-- || Local Functions ||--

local function isTrainingZonePart(instance: Instance): boolean
	if not instance:IsA("BasePart") then
		return false
	end

	local name = instance.Name
	return string.match(name, "^ShootZone%d+$")
		or string.match(name, "^PassZone%d+$")
		or string.match(name, "^DribbleZone%d+$")
		or string.match(name, "^StaminaZone%d+$")
end

local function getTrainingMap(): Instance?
	return Workspace:FindFirstChild("Map")
end

local function setTrainingPromptsEnabledForLocalPlayer(isEnabled: boolean)
	local map = getTrainingMap()
	if not map then
		warn("[TrainingPromptVisibilityController] Map not found")
		return
	end

	local count = 0

	for _, descendant in ipairs(map:GetDescendants()) do
		if isTrainingZonePart(descendant) then
			-- Cari semua prompt di dalam zona ini (termasuk yang ada di child/attachment)
			for _, child in ipairs(descendant:GetDescendants()) do
				if child:IsA("ProximityPrompt") then
					child.Enabled = isEnabled
					count += 1
				end
			end
		end
	end
end

local function isPurchasePromptActive(): boolean
	local monetizationController = nil
	pcall(function()
		monetizationController = Knit.GetController("MonetizationController")
	end)
	return monetizationController ~= nil and monetizationController:IsPurchasePromptActive()
end

local function applyCurrentPromptVisibility()
	-- kalau sedang training atau sedang top up, prompt lokal di-hide
	-- kalau tidak sedang keduanya, prompt lokal ditampilkan lagi
	local shouldHide = localTrainingActive or isPurchasePromptActive()
	setTrainingPromptsEnabledForLocalPlayer(not shouldHide)
end

-- || Knit Lifecycle ||--

function TrainingPromptVisibilityController:KnitInit()
	TrainingService = Knit.GetService("TrainingService")
end

function TrainingPromptVisibilityController:KnitStart()
	print("[TrainingPromptVisibilityController] KnitStart running")

	-- state awal
	applyCurrentPromptVisibility()

	TrainingService.TrainingSessionChanged:Connect(function(isTraining: boolean, statType: string?, zoneKey: string?)
		localTrainingActive = isTraining
		applyCurrentPromptVisibility()
	end)

	local monetizationController = nil
	pcall(function()
		monetizationController = Knit.GetController("MonetizationController")
	end)

	if monetizationController and monetizationController.PromptStateChanged then
		monetizationController.PromptStateChanged.Event:Connect(function()
			applyCurrentPromptVisibility()
		end)
	end

	local map = getTrainingMap()
	if map then
		map.DescendantAdded:Connect(function(descendant)
			if not localTrainingActive and not isPurchasePromptActive() then
				return
			end

			if descendant:IsA("ProximityPrompt") then
				-- Jika yang baru ditambahkan adalah prompt, cek apakah parent-nya adalah Training Zone
				local current = descendant.Parent
				while current and current ~= map and current ~= Workspace do
					if isTrainingZonePart(current) then
						descendant.Enabled = false
						break
					end
					current = current.Parent
				end
			elseif isTrainingZonePart(descendant) then
				-- Jika yang ditambahkan adalah part Training Zone utuh beserta isinya
				for _, child in ipairs(descendant:GetDescendants()) do
					if child:IsA("ProximityPrompt") then
						child.Enabled = false
					end
				end
			end
		end)
	end
end

return TrainingPromptVisibilityController
