--|| Services ||--
local RunService = game:GetService("RunService")

--|| Constants ||--
local SRC = script.src

--|| Runtime Environment Check ||--
if RunService:IsServer() then
	if not SRC:FindFirstChild("Service") then
		error("[" .. script.Name .. "] Service for this module not found.")
	end

	return require(SRC.Service)
elseif RunService:IsClient() then
	if not SRC:FindFirstChild("Controller") then
		error("[" .. script.Name .. "] Controller for this module not found.")
	end

	return require(SRC.Controller)
else
	error("[" .. script.Name .. "] Invalid Run Environment.")
	return nil
end
