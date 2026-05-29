-- AreaLightingPresenter.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AreaLightingPresenter = {}
AreaLightingPresenter.__index = AreaLightingPresenter

local MATCH_BATTLE_LIGHTING_PRESET = "Area01"
local MATCH_BATTLE_LIGHTING_PRESETS_BY_AREA = {
	Area05 = "Area05Match",
}

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
	end)

	MatchService.MatchSessionEnded:Connect(function(reason)
		if reason == "ChampionCeremony" then
			return
		end

		inMatchBattle = false
		task.defer(RestoreCurrentAreaLighting)
	end)

	MatchService.ChampionCeremonyStarted:Connect(function(payload)
		inMatchBattle = true
		ApplyMatchBattleLighting(payload)
	end)

	MatchService.ChampionCeremonyEnded:Connect(function()
		inMatchBattle = false
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
