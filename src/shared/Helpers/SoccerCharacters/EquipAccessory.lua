local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local AccessoriesAssets = Assets:WaitForChild("Accessories")

local function findAllAccessoriesRecursive(parent, results)
	results = results or {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Accessory") then
			table.insert(results, child)
		end
		findAllAccessoriesRecursive(child, results)
	end
	return results
end

local function applyAccessoryManual(model, characterData, accessoriesInventory)
	if not model or not characterData then
		return
	end

	local accessoryList = characterData.Accessories or {}

	-- 1. Identify which accessories should stay and which should be removed
	-- Map of target slot -> target accessory ID
	local targetAccessories = {}
	for slot, id in pairs(accessoryList) do
		targetAccessories[tostring(slot)] = tostring(id)
	end

	-- 2. Scan existing objects in the model and remove those that are no longer needed
	-- or need to be replaced (because ID changed)
	local existingBySlot = {}
	for _, child in ipairs(model:GetChildren()) do
		local slot = child:GetAttribute("AccessorySlot")
		if slot then
			local id = tostring(child:GetAttribute("AccessoryId"))
			local targetId = targetAccessories[tostring(slot)]

			if targetId == id then
				-- Matches! Keep it.
				existingBySlot[tostring(slot)] = true
			else
				-- Different ID or slot no longer exists, remove it.
				child:Destroy()
			end
		elseif child:IsA("Accessory") or child:GetAttribute("IsAccessory") then
			-- Old untagged accessory, remove it.
			child:Destroy()
		end
	end

	-- 3. Equip missing or changed accessories
	for slot, accessoryId in pairs(accessoryList) do
		if existingBySlot[tostring(slot)] then
			continue -- Already correctly equipped, skip.
		end

		local invData = accessoriesInventory[tostring(accessoryId)] or accessoriesInventory[tonumber(accessoryId)]
		local assetName = if invData then invData.Name else tostring(accessoryId)
		local asset = AccessoriesAssets:FindFirstChild(assetName, true)

		if asset then
			local accessories = findAllAccessoriesRecursive(asset)
			for _, accessory in ipairs(accessories) do
				local clone = accessory:Clone()
				clone:SetAttribute("IsAccessory", true)
				clone:SetAttribute("AccessorySlot", tostring(slot))
				clone:SetAttribute("AccessoryId", tostring(accessoryId))

				-- Optimization: Unanchor and disable collisions
				for _, desc in ipairs(clone:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Anchored = false
						desc.CanCollide = false
						desc.CanTouch = false
						desc.CanQuery = false
						desc.Massless = true
					end
				end

				-- Find manual welds and RE-TARGET them instead of recreating
				local handle = clone:FindFirstChild("Handle")
				if handle then
					for _, desc in ipairs(clone:GetDescendants()) do
						if desc:IsA("Weld") or desc:IsA("ManualWeld") or desc:IsA("WeldConstraint") then
							local p0 = desc.Part0
							local p1 = desc.Part1

							local potentialRef0 = if p0 then model:FindFirstChild(p0.Name) else nil
							local potentialRef1 = if p1 then model:FindFirstChild(p1.Name) else nil

							local refPart = nil
							local accessoryPart = nil

							if p0 and potentialRef0 and potentialRef0.Parent == model and p0.Name ~= "Handle" then
								refPart = potentialRef0
								accessoryPart = p1
							elseif p1 and potentialRef1 and potentialRef1.Parent == model and p1.Name ~= "Handle" then
								refPart = potentialRef1
								accessoryPart = p0
							end

							if refPart and accessoryPart then
								-- Pre-align the accessory to the current animation frame before welding
								accessoryPart.CFrame = refPart.CFrame * desc.C0 * desc.C1:Inverse()

								-- RE-TARGET the existing weld to the real character part
								if desc.Part0 == p0 and p0.Name == refPart.Name then
									desc.Part0 = refPart
								else
									desc.Part1 = refPart
								end
							end
						end
					end

					clone.Parent = model
				else
					clone.Parent = model
				end
			end
		end
	end
end

return applyAccessoryManual
