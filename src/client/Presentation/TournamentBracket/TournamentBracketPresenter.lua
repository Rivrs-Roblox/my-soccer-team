--!strict
-- TournamentBracketPresenter.lua
-- Strict MVP presenter for the artist-authored Tournament ScreenGui.
-- It bridges TournamentController events to the View without owning layout or gameplay rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local TournamentBracketView = require(script.Parent.TournamentBracketView)

local TournamentBracketPresenter = {}
TournamentBracketPresenter.__index = TournamentBracketPresenter

function TournamentBracketPresenter.new()
	local self = setmetatable({}, TournamentBracketPresenter)
	self._trove = Trove.new()
	self._view = nil
	self._currentPayload = nil
	self._isConfirming = false
	return self
end

function TournamentBracketPresenter:Init()
	self._view = self._trove:Add(TournamentBracketView.new())

	local TournamentController = Knit.GetController("TournamentController")

	self._trove:Add(TournamentController.PreviewRequested:Connect(function(payload)
		self:_show(TournamentController, payload)
	end))

	self._trove:Add(TournamentController.Updated:Connect(function(payload)
		self._currentPayload = payload

		if self._view and self._view:IsVisible() then
			self._view:Render(payload)
		end
	end))

	self._trove:Add(TournamentController.Completed:Connect(function(payload)
		self._currentPayload = payload

		if self._view and self._view:IsVisible() then
			self._view:Render(payload)
		end
	end))

	self._trove:Add(TournamentController.HideRequested:Connect(function()
		if self._view then
			self._view:Hide()
		end
	end))
end

function TournamentBracketPresenter:_show(TournamentController, payload)
	if type(payload) ~= "table" or not self._view then
		return
	end

	self._currentPayload = payload

	self._view:Show(payload, function()
		self:_confirmStart(TournamentController)
	end, function()
		-- Close button: hide preview and return to lobby.
		pcall(function()
			TournamentController:HideLocalPreview()
		end)
	end)

	if TournamentController.RevealMatchTransitionOverlay
		and TournamentController.IsInterstitialPreviewOpen
		and TournamentController:IsInterstitialPreviewOpen()
	then
		task.defer(function()
			RunService.RenderStepped:Wait()
			if TournamentController:IsInterstitialPreviewOpen() then
				TournamentController:RevealMatchTransitionOverlay()
			end
		end)
	end
end

function TournamentBracketPresenter:_confirmStart(TournamentController)
	if self._isConfirming then
		return
	end

	self._isConfirming = true

	if type(self._currentPayload) == "table" and tostring(self._currentPayload.Status or "") == "Champion" then
		TournamentController:HideLocalPreview()
		self._isConfirming = false
		return
	end

	local payloadBeforeConfirm = self._currentPayload

	if TournamentController.CoverMatchStartTransition then
		TournamentController:CoverMatchStartTransition()
	end

	-- Hide the tournament bracket before the yielding remote call. The server can
	-- start the next match and fire MatchSessionStarted before ConfirmPlayMatch()
	-- returns; if the bracket is still visible, its GUI suppression can hide
	-- GUIMatchBattle.MatchStart and make round-2+ intros look skipped.
	if self._view then
		self._view:Hide()
		RunService.RenderStepped:Wait()
	end

	local ok = false
	local success, result = pcall(function()
		return TournamentController:ConfirmPlayMatch()
	end)

	if success then
		ok = result == true
	else
		warn("[TournamentBracketPresenter] Failed to confirm tournament match:", result)
	end

	if not ok and self._view and type(payloadBeforeConfirm) == "table" then
		if TournamentController.HideMatchStartTransitionCover then
			TournamentController:HideMatchStartTransitionCover()
		end
		self._view:Show(payloadBeforeConfirm, function()
			self:_confirmStart(TournamentController)
		end, function()
			pcall(function()
				TournamentController:HideLocalPreview()
			end)
		end)
	end

	self._isConfirming = false
end

function TournamentBracketPresenter:Destroy()
	self._trove:Destroy()
end

return TournamentBracketPresenter
