-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- CameraController
local CameraController = Knit.CreateController({
	Name = "CameraController",
})

-- Local Variables
local CameraInput = nil
local originalGetRotation = nil
local sensitivityMultiplier = 1
local runFovConnection = nil

local DEFAULT_FIELD_OF_VIEW = 70
local RUN_FIELD_OF_VIEW = 76
local RUN_FOV_LERP_SPEED = 8
local RUN_MOVE_THRESHOLD = 0.08

local function getLocalHumanoid(): Humanoid?
	local player = Players.LocalPlayer
	local character = player and player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRunFovTarget(): number
	local humanoid = getLocalHumanoid()
	if not humanoid or humanoid.Health <= 0 then
		return DEFAULT_FIELD_OF_VIEW
	end

	local moveAlpha = math.clamp(humanoid.MoveDirection.Magnitude, 0, 1)
	if moveAlpha <= RUN_MOVE_THRESHOLD then
		return DEFAULT_FIELD_OF_VIEW
	end

	local speedAlpha = math.clamp((humanoid.WalkSpeed or 16) / 16, 0.75, 1.35)
	return DEFAULT_FIELD_OF_VIEW + ((RUN_FIELD_OF_VIEW - DEFAULT_FIELD_OF_VIEW) * moveAlpha * speedAlpha)
end

function CameraController:ApplySensitivityMultiplier(multiplier: number)
	sensitivityMultiplier = multiplier
end

function CameraController:ResetSensitivity()
	sensitivityMultiplier = 1
end

function CameraController:KnitInit() end

function CameraController:KnitStart()
	-- Require CameraInput from Roblox PlayerModule
	task.spawn(function()
		local player = Players.LocalPlayer
		local playerScripts = player:WaitForChild("PlayerScripts")

		-- Wait for PlayerModule and its hierarchy
		local playerModule = playerScripts:WaitForChild("PlayerModule")
		local cameraModule = playerModule:WaitForChild("CameraModule")
		local cameraInputModule = cameraModule:WaitForChild("CameraInput")

		CameraInput = require(cameraInputModule)

		if CameraInput and CameraInput.getRotation then
			originalGetRotation = CameraInput.getRotation

			-- Hook into getRotation
			CameraInput.getRotation = function(self, ...)
				local rotation = originalGetRotation(self, ...)
				if sensitivityMultiplier ~= 1 then
					-- Rotation is a Vector2 (delta X, delta Y)
					return rotation * sensitivityMultiplier
				end
				return rotation
			end
			print("[CameraController] Successfully hooked into CameraInput.getRotation")
		else
			warn("[CameraController] Failed to hook into CameraInput.getRotation")
		end
	end)

	if runFovConnection then
		runFovConnection:Disconnect()
	end

	runFovConnection = RunService.RenderStepped:Connect(function(deltaTime)
		local camera = Workspace.CurrentCamera
		if not camera or camera.CameraType == Enum.CameraType.Scriptable then
			return
		end

		local targetFov = getRunFovTarget()
		local alpha = 1 - math.exp(-RUN_FOV_LERP_SPEED * math.max(deltaTime or 0, 0))
		camera.FieldOfView = camera.FieldOfView + ((targetFov - camera.FieldOfView) * alpha)
	end)
end

return CameraController
