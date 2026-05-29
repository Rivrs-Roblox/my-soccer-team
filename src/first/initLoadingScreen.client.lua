-- wait for the loading screen
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGUI = player:WaitForChild("PlayerGui")
local LoadingUI = playerGUI:WaitForChild("LoadingUI")

if LoadingUI then
	LoadingUI.Enabled = true
end

-- Function to clean up when loading is done
local function cleanupLoading()
	if LoadingUI and LoadingUI.Parent then
		LoadingUI:Destroy()
	end
end

task.wait(0.1)

-- Remove the default loading screen
game.ReplicatedFirst:RemoveDefaultLoadingScreen()

return {
	GUI = LoadingUI,
	Cleanup = cleanupLoading,
}
