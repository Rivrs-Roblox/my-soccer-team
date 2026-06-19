--!strict
-- TournamentChampionPresenter.lua
-- Strict MVP binder for the champion ceremony visual stage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sound = require(ReplicatedStorage.Packages.Sound)

local TournamentChampionView = require(script.Parent.TournamentChampionView)

local LocalPlayer = Players.LocalPlayer

local function GetOwnedCoach(CoachesController): Model?
	if not CoachesController then
		return nil
	end

	local root = CoachesController.CoachInstances or workspace:FindFirstChild("Coaches")
	if not root then
		return nil
	end

	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("Model") then
			local ownerName = child:GetAttribute("Owner")
			local ownerUserId = child:GetAttribute("OwnerUserId")
			if ownerName == LocalPlayer.Name or ownerUserId == LocalPlayer.UserId then
				return child
			end
		end
	end

	return nil
end

local TournamentChampionPresenter = {}
TournamentChampionPresenter.__index = TournamentChampionPresenter

function TournamentChampionPresenter.new()
	local self = setmetatable({}, TournamentChampionPresenter)
	self._trove = Trove.new()
	self._view = nil
	return self
end

function TournamentChampionPresenter:Init()
	self._view = self._trove:Add(TournamentChampionView.new())

	local MatchController = Knit.GetController("MatchController")
	local MatchCompanionVisualController = nil
	local CoachesController = nil

	pcall(function()
		MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
	end)

	pcall(function()
		CoachesController = Knit.GetController("CoachesController")
	end)

	if MatchController.ChampionCeremonyStarted then
		self._trove:Add(MatchController.ChampionCeremonyStarted:Connect(function(payload)
			-- Stop background music
			Sound:StopSound("MUSIC_Background")
			Sound:StopSound("MUSIC_Fight")

			-- Play champion music
			Sound:PlaySound("MUSIC_ChampionCeremony")

			local companions = {}
			if MatchCompanionVisualController and MatchCompanionVisualController.GetOwnedCompanionModels then
				companions = MatchCompanionVisualController:GetOwnedCompanionModels(LocalPlayer)
			end

			local viewPayload = type(payload) == "table" and table.clone(payload) or {}
			viewPayload.Sources = {
				MainPlayer = LocalPlayer.Character,
				Companions = companions,
				Coach = GetOwnedCoach(CoachesController),
			}

			self._view:Show(viewPayload, function(sessionId)
				return MatchController:RequestFinishChampionCeremony(sessionId)
			end)
		end))
	end

	if MatchController.ChampionCeremonyEnded then
		self._trove:Add(MatchController.ChampionCeremonyEnded:Connect(function()
			-- Stop champion music
			Sound:StopSound("MUSIC_ChampionCeremony")

			-- Play background music
			Sound:PlaySound("MUSIC_Background")

			self._view:Hide()
		end))
	end
end

function TournamentChampionPresenter:Destroy()
	self._trove:Destroy()
end

return TournamentChampionPresenter
