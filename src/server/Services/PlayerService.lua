--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Helpers
local AddOutline = require(ReplicatedStorage.Shared.Helpers.AddOutline)

-- PlayerService
local PlayerService = Knit.CreateService({
	Name = "PlayerService",
})

function PlayerService.Client:SetClientLoaded(player)
	self.Server:SetClientLoaded(player)
end

--|| Functions ||--
function PlayerService:SetClientLoaded(player)
	player:SetAttribute("ClientLoaded", true)
end

function PlayerService:CharacterAdded(character: Model)
	AddOutline(character)
	for _, descendant in character:GetDescendants() do
		self:DescendantAdded(descendant)
	end

	character.DescendantAdded:Connect(function(descendant: BasePart?)
		self:DescendantAdded(descendant)
	end)
end

function PlayerService:DescendantAdded(descendant: BasePart?)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Humanoid"
	end
end

--|| Knit Lifecycle ||--
function PlayerService:KnitInit()
	PhysicsService:RegisterCollisionGroup("Humanoid")
	PhysicsService:CollisionGroupSetCollidable("Humanoid", "Humanoid", false)

	print("[PLAYER SERVICE] Service loaded successfully.")
end

function PlayerService:KnitStart()
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			self:CharacterAdded(character)
		end)
	end)

	for _, player in Players:GetPlayers() do
		if player.Character then
			self:CharacterAdded(player.Character)
		end
	end
end

return PlayerService
