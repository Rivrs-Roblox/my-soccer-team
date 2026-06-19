-- AreaLightingPresenter.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AreaLightingPresenter = {}
AreaLightingPresenter.__index = AreaLightingPresenter

local MATCH_BATTLE_LIGHTING_PRESET = "Area01"
local MATCH_BATTLE_LIGHTING_PRESETS_BY_AREA = {
	-- Area05 = "Area05Match",
}

local mapEffectsCache = {}

local function findBattleZone(): Instance?
	local map = workspace:FindFirstChild("Map")
	local battleZone = map and map:FindFirstChild("BattleZone")
	if battleZone then
		return battleZone
	end

	for i = 1, 5 do
		local areaFolder = workspace:FindFirstChild("Area0" .. tostring(i))
		local bz = areaFolder and areaFolder:FindFirstChild("BattleZone")
		if bz then
			return bz
		end
	end

	return nil
end

local function applyMapEffectsDimming(dimmed: boolean)
	if dimmed then
		local battleZone = findBattleZone()
		if not battleZone then return end

		for _, descendant in ipairs(battleZone:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Material == Enum.Material.Neon then
				if not mapEffectsCache[descendant] then
					mapEffectsCache[descendant] = {
						Type = "Neon",
						Material = descendant.Material,
						Color = descendant.Color,
					}
				end
				descendant.Material = Enum.Material.SmoothPlastic
			elseif descendant:IsA("Light") then
				if not mapEffectsCache[descendant] then
					mapEffectsCache[descendant] = {
						Type = "Light",
						Enabled = descendant.Enabled,
					}
				end
				descendant.Enabled = false
			end
		end
	else
		for instance, original in pairs(mapEffectsCache) do
			if instance and instance.Parent then
				pcall(function()
					if original.Type == "Neon" then
						instance.Material = original.Material
						instance.Color = original.Color
					elseif original.Type == "Light" then
						instance.Enabled = original.Enabled
					end
				end)
			end
		end
		table.clear(mapEffectsCache)
	end
end

function AreaLightingPresenter.new()
	local self = setmetatable({}, AreaLightingPresenter)
	return self
end

function AreaLightingPresenter:Init()
	local TeleportService = Knit.GetService("TeleportService")
	local MatchService = Knit.GetService("MatchService")
	local LightsController = Knit.GetController("LightsController")
	local inMatchBattle = false

	local function ApplyArtistPreset(presetName)
		return LightsController:ApplyPreset(presetName, {
			useAliases = false,
			useVolumes = false,
		})
	end

	local function ApplyAreaLighting(area)
		if inMatchBattle or not area then return end
		local areaId = type(area) == "table" and area.Id or area

		ApplyArtistPreset(areaId)
	end

	local function ApplyMatchBattleLighting(payload)
		local areaId = type(payload) == "table" and (payload.AreaId or payload.Id) or nil
		local presetName = MATCH_BATTLE_LIGHTING_PRESETS_BY_AREA[areaId] or MATCH_BATTLE_LIGHTING_PRESET

		ApplyArtistPreset(presetName)
	end

	local function RestoreCurrentAreaLighting()
		if inMatchBattle then
			return
		end

		local success, area = pcall(function()
			local _, result = TeleportService:GetArea():await()
			return result
		end)

		if success and area then
			ApplyAreaLighting(area)
		end
	end

	-- Mendengarkan saat player teleport/pindah area
	TeleportService.AreaUpdated:Connect(ApplyAreaLighting)

	MatchService.MatchSessionStarted:Connect(function(payload)
		inMatchBattle = true
		ApplyMatchBattleLighting(payload)

		applyMapEffectsDimming(true)
		task.delay(0.5, function()
			applyMapEffectsDimming(true)
		end)
		task.delay(1.5, function()
			applyMapEffectsDimming(true)
		end)
	end)

	MatchService.MatchSessionEnded:Connect(function(reason)
		if reason == "ChampionCeremony" then
			return
		end

		inMatchBattle = false
		applyMapEffectsDimming(false)
		task.defer(RestoreCurrentAreaLighting)
	end)

	MatchService.ChampionCeremonyStarted:Connect(function(payload)
		inMatchBattle = true
		ApplyMatchBattleLighting(payload)

		applyMapEffectsDimming(true)
		task.delay(0.5, function()
			applyMapEffectsDimming(true)
		end)
	end)

	MatchService.ChampionCeremonyEnded:Connect(function()
		inMatchBattle = false
		applyMapEffectsDimming(false)
		task.defer(RestoreCurrentAreaLighting)
	end)

	-- Apply initial area saat game pertama kali di-load
	task.spawn(function()
		local success, result = pcall(function()
			local _, area = TeleportService:GetArea():await()
			return area
		end)
		
		if success and result then
			ApplyAreaLighting(result)
		end
	end)
end

function AreaLightingPresenter:Destroy()
end

return AreaLightingPresenter
