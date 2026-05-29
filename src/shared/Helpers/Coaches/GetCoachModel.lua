local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local CoachAssets = Assets:WaitForChild("Coaches")
return function(Data: table)
	-- Data di sini sekarang adalah template coach (misal: {Name = "Dog", DisplayName = "Dog", ...})
	local coachName = Data.Name or "Unknown"
	local coachModel = nil
	coachModel = CoachAssets:FindFirstChild(coachName, true)
	if coachModel == nil then
		warn("Can't find coach model:", coachName)
		return nil
	end

	for _, v in coachModel:GetDescendants() do
		if v:IsA("MeshPart") then
			v.CanCollide = false
			v.CanQuery = false
			v.CanTouch = false
		end

		if v:IsA("BasePart") then
			v.CollisionGroup = "Humanoid"
			v.Anchored = false
		end
	end

	return coachModel
end
