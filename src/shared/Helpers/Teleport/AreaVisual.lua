local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local AreaAssets = Assets:WaitForChild("MapAreas")

local AreaVisual = {} :: table
local areaPool = {} :: { [string]: Instance }
local currentAreaName: string? = nil

function AreaVisual:Apply(areaName: string)
	if currentAreaName == areaName then return end

	-- Hide current graphic instead of destroying
	if currentAreaName and areaPool[currentAreaName] then
		areaPool[currentAreaName].Parent = nil
	end

	-- Check if we already have this area in our pool
	if areaPool[areaName] then
		areaPool[areaName].Parent = game.Workspace
		currentAreaName = areaName
	else
		-- Load new graphic from assets if not pooled
		local asset = AreaAssets:FindFirstChild(areaName)
		if asset then
			local clone = asset:Clone()
			clone.Parent = game.Workspace
			areaPool[areaName] = clone
			currentAreaName = areaName
		else
			warn("[AreaVisual] Asset not found for area:", areaName)
		end
	end
end

return AreaVisual
