-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Example PlayerController stub (you'll implement this fully)
local PlayerController = Knit.CreateController({
	Name = "PlayerController",
})

function PlayerController:KnitInit()
	self.currentPlane = nil
end

function PlayerController:StartPlaneControl(planeModule)
	self.currentPlane = planeModule

	local player = Players.LocalPlayer
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.JumpPower = 0
			humanoid.WalkSpeed = 0
		end
	end

	-- Input handling
	game:GetService("UserInputService").InputBegan:Connect(function(input)
		if not self.currentPlane then
			return
		end

		if input.KeyCode == Enum.KeyCode.A then
			self.currentPlane.tilt = Vector3.new(0, 0, math.rad(45))
		elseif input.KeyCode == Enum.KeyCode.D then
			self.currentPlane.tilt = Vector3.new(0, 0, -math.rad(45))
		elseif input.KeyCode == Enum.KeyCode.W then
			self.currentPlane.tilt = Vector3.new(-math.rad(45), 0, 0)
		elseif input.KeyCode == Enum.KeyCode.S then
			self.currentPlane.tilt = Vector3.new(math.rad(45), 0, 0)
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if not self.currentPlane then
			return
		end

		if
			input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.D
			or input.KeyCode == Enum.KeyCode.W
			or input.KeyCode == Enum.KeyCode.S
		then
			self.currentPlane.tilt = Vector3.new(0, 0, 0)
		end
	end)

	self.currentPlane:startFlight()
end

return PlayerController
