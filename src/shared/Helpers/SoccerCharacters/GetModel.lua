local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local SoccerCharactersAssets = Assets:WaitForChild("SoccerCharacters")

return function(Data: { [any]: any })
	local Name = Data.Name
	local Template = SoccerCharactersAssets:FindFirstChild(Name, true)
	if Template == nil then
		warn("Can't find soccer character model:", Name)
		return
	end
	
	local Model = Template:Clone()
	
	for i, v in Model:GetDescendants() do
		pcall(function()
			if v:IsA("MeshPart") then
				v.CanCollide = false
				v.CanQuery = false
				v.CanTouch = false
			end

			if v:IsA("BasePart") then
				v.CollisionGroup = "Humanoid"
				v.Anchored = false
			end
		end)
	end

	return Model
end
