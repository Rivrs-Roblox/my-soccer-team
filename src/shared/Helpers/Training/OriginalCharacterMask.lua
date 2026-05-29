local Mask = {}

local transparencyCache = setmetatable({}, { __mode = "k" })
local enabledCache = setmetatable({}, { __mode = "k" })

function Mask.SetHidden(character: Model?, hidden: boolean)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = hidden and 1 or 0
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			if hidden then
				if transparencyCache[descendant] == nil then
					transparencyCache[descendant] = descendant.Transparency
				end
				descendant.Transparency = 1
			else
				local cached = transparencyCache[descendant]
				descendant.Transparency = cached ~= nil and cached or 0
				transparencyCache[descendant] = nil
			end
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			if hidden then
				if enabledCache[descendant] == nil then
					enabledCache[descendant] = descendant.Enabled
				end
				descendant.Enabled = false
			else
				local cached = enabledCache[descendant]
				descendant.Enabled = cached ~= nil and cached or true
				enabledCache[descendant] = nil
			end
		end
	end
end

return Mask