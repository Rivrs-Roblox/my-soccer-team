--!strict
-- TournamentChampionPresenter.lua
-- Strict MVP binder for the champion ceremony visual stage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

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
	local SoundController = Knit.GetController("SoundController")
	local MatchCompanionVisualController = nil
	local CoachesController = nil

	local championMusic = Instance.new("Sound")
	championMusic.Name = "ChampionCeremonyMusic"
	championMusic.SoundId = "rbxassetid://82926677318271"
	championMusic.Volume = 1
	championMusic.Looped = true
	championMusic.Parent = game:GetService("SoundService")

	pcall(function()
		MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
	end)

	pcall(function()
		CoachesController = Knit.GetController("CoachesController")
	end)

	if MatchController.ChampionCeremonyStarted then
		self._trove:Add(MatchController.ChampionCeremonyStarted:Connect(function(payload)
			-- Mute background music
			if SoundController and SoundController.SetGlobalVolume then
				SoundController:SetGlobalVolume("MUSIC", 0)
			end

			-- Play champion music
			championMusic:Play()

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
			championMusic:Stop()

			-- Restore background music
			if SoundController and SoundController.SetGlobalVolume then
				SoundController:SetGlobalVolume("MUSIC", 100)
			end

			self._view:Hide()
		end))
	end
end

function TournamentChampionPresenter:Destroy()
	self._trove:Destroy()
end

return TournamentChampionPresenter
