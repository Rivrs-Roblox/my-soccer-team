--!strict
-- TournamentController.luau
-- Client bridge for server-authoritative tournament preview and start confirmation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TournamentController = Knit.CreateController({
	Name = "TournamentController",
})

local TournamentService = nil
local MatchService = nil
local LocalPlayer = Players.LocalPlayer


local function ResolveRemoteResult(remoteResult)
	if type(remoteResult) == "table" and remoteResult.await then
		local ok, value = remoteResult:await()
		if ok then
			return value
		end
		return false
	end

	return remoteResult
end
local function RestoreSoccerFollowersBehindPlayer()
	local ok, companionController = pcall(function()
		return Knit.GetController("MatchCompanionVisualController")
	end)

	if not ok or not companionController or not companionController.RestoreCompanionsBehindOwner then
		return
	end

	local delays = { 0, 0.08, 0.22, 0.45 }
	for _, delaySeconds in ipairs(delays) do
		task.delay(delaySeconds, function()
			if LocalPlayer and LocalPlayer.Parent then
				pcall(function()
					companionController:RestoreCompanionsBehindOwner(LocalPlayer)
				end)
			end
		end)
	end
end

local function ClearMatchTransitionOverlay()
	local ok, matchUiController = pcall(function()
		return Knit.GetController("MatchUIController")
	end)

	if ok and matchUiController and matchUiController.ClearTransitionOverlay then
		pcall(function()
			matchUiController:ClearTransitionOverlay()
		end)
	end
end

local function PrepareLocalCharacterForMatchTransition()
	local ok, matchPresentationController = pcall(function()
		return Knit.GetController("MatchPresentationController")
	end)

	if ok
		and matchPresentationController
		and matchPresentationController.PrepareLocalCharacterForMatchTransition
	then
		pcall(function()
			matchPresentationController:PrepareLocalCharacterForMatchTransition()
		end)
	end
end

local function CancelLocalCharacterMatchTransition()
	local ok, matchPresentationController = pcall(function()
		return Knit.GetController("MatchPresentationController")
	end)

	if ok
		and matchPresentationController
		and matchPresentationController.CancelLocalCharacterMatchTransition
	then
		pcall(function()
			matchPresentationController:CancelLocalCharacterMatchTransition()
		end)
	end
end

local function RevealMatchTransitionOverlay()
	local ok, matchUiController = pcall(function()
		return Knit.GetController("MatchUIController")
	end)

	if ok and matchUiController then
		if matchUiController.EndMatchUi then
			pcall(function()
				matchUiController:EndMatchUi({
					PreserveTransitionOverlay = true,
				})
			end)
		end

		if not matchUiController.FadeFromBlack then
			return
		end

		task.spawn(function()
			pcall(function()
				matchUiController:FadeFromBlack()
			end)
		end)
	end
end

local function CoverMatchStartTransition()
	local ok, matchUiController = pcall(function()
		return Knit.GetController("MatchUIController")
	end)

	if not ok or not matchUiController then
		return
	end

	pcall(function()
		PrepareLocalCharacterForMatchTransition()

		if matchUiController.EndMatchUi then
			matchUiController:EndMatchUi({
				PreserveTransitionOverlay = true,
			})
		end

		if matchUiController.CutToBlack then
			matchUiController:CutToBlack("Entering Match...")
		elseif matchUiController.FadeToBlack then
			matchUiController:FadeToBlack("Entering Match...")
		end
	end)
end

local function CancelPendingStartAndReturn()
	if not TournamentService or not TournamentService.CancelPendingStart then
		RestoreSoccerFollowersBehindPlayer()
		return false
	end

	local ok, result = pcall(function()
		return ResolveRemoteResult(TournamentService:CancelPendingStart({
			TeleportToReturnPoint = true,
		}))
	end)

	if not ok then
		warn("[TournamentController] CancelPendingStart failed: " .. tostring(result))
	end

	RestoreSoccerFollowersBehindPlayer()
	return ok and result == true
end

function TournamentController:KnitInit()
	self._previewRequestedEvent = Instance.new("BindableEvent")
	self._updatedEvent = Instance.new("BindableEvent")
	self._completedEvent = Instance.new("BindableEvent")
	self._hideRequestedEvent = Instance.new("BindableEvent")

	self.PreviewRequested = self._previewRequestedEvent.Event
	self.Updated = self._updatedEvent.Event
	self.Completed = self._completedEvent.Event
	self.HideRequested = self._hideRequestedEvent.Event

	self._latestPayload = nil
	self._isPreviewOpen = false
	self._isInterstitial = false
	self._pendingInterstitialPreview = false
end

function TournamentController:KnitStart()
	TournamentService = Knit.GetService("TournamentService")

	local matchOk, matchService = pcall(function()
		return Knit.GetService("MatchService")
	end)
	if matchOk then
		MatchService = matchService
	end

	TournamentService.TournamentPreviewRequested:Connect(function(payload)
		self._latestPayload = payload
		self._isPreviewOpen = true
		self._isInterstitial = self._pendingInterstitialPreview == true
		self._pendingInterstitialPreview = false
		self._previewRequestedEvent:Fire(payload)
	end)

	TournamentService.TournamentUpdated:Connect(function(payload)
		self._latestPayload = payload
		self._updatedEvent:Fire(payload)
	end)

	TournamentService.TournamentCompleted:Connect(function(payload)
		self._latestPayload = payload
		self._completedEvent:Fire(payload)
	end)

	if MatchService and MatchService.MatchSessionEnded then
		MatchService.MatchSessionEnded:Connect(function(reason)
			local reasonText = tostring(reason or "")
			if reasonText == "VictoryContinuation" then
				self._pendingInterstitialPreview = true
				return
			end

			if reasonText ~= "Victory" then
				return
			end

			local payload = self._latestPayload
			if type(payload) ~= "table" then
				return
			end

			-- Show the updated bracket as the post-win progression interstitial.
			-- Defeat/manual exit intentionally do not enter this path.
			task.defer(function()
				self._pendingInterstitialPreview = false
				self._isPreviewOpen = true
				self._isInterstitial = true
				self._previewRequestedEvent:Fire(payload)
			end)
		end)
	end
end

function TournamentController:GetLatestPayload()
	return self._latestPayload
end

function TournamentController:IsPreviewOpen(): boolean
	return self._isPreviewOpen == true
end

function TournamentController:IsInterstitialPreviewOpen(): boolean
	return self._isPreviewOpen == true and self._isInterstitial == true
end

function TournamentController:ConfirmPlayMatch(): boolean
	if not TournamentService then
		return false
	end

	local result = ResolveRemoteResult(TournamentService:ConfirmPlayMatch())
	if result == true then
		self._isPreviewOpen = false
		self._hideRequestedEvent:Fire()
		return true
	end

	warn("[TournamentController] ConfirmPlayMatch rejected by server.")
	return false
end

function TournamentController:CoverMatchStartTransition()
	CoverMatchStartTransition()
end

function TournamentController:HideMatchStartTransitionCover()
	CancelLocalCharacterMatchTransition()
	ClearMatchTransitionOverlay()
end

function TournamentController:HideLocalPreview()
	local wasInterstitial = self._isInterstitial == true

	self._isPreviewOpen = false
	self._pendingInterstitialPreview = false
	self._hideRequestedEvent:Fire()
	CancelLocalCharacterMatchTransition()

	if not wasInterstitial then
		ClearMatchTransitionOverlay()
	end

	local matchController = nil
	pcall(function()
		matchController = Knit.GetController("MatchController")
	end)

	local isActivelyInMatch = false
	if matchController and matchController.IsPlayingMatch then
		local ok, result = pcall(function()
			return matchController:IsPlayingMatch()
		end)
		isActivelyInMatch = ok and result == true
	end

	if wasInterstitial and isActivelyInMatch then
		self._isInterstitial = false
		if matchController and matchController.RequestExitMatch then
			matchController:RequestExitMatch("ManualExit")
		end
		return
	end

	self._isInterstitial = false

	if wasInterstitial then
		CancelPendingStartAndReturn()
		if matchController and matchController.FinalizeTournamentPreviewReturn then
			pcall(function()
				matchController:FinalizeTournamentPreviewReturn("TournamentPreviewClosed")
			end)
		else
			ClearMatchTransitionOverlay()
		end
		return
	end

	-- Restore HUD back on-screen when leaving the tournament bracket preview back to lobby.
	if not isActivelyInMatch then
		local uiController = nil
		pcall(function()
			uiController = Knit.GetController("UIController")
		end)
		if uiController and uiController.ShowHUD then
			pcall(function()
				uiController:ShowHUD()
			end)
		end
	end

	CancelPendingStartAndReturn()
end

function TournamentController:RevealMatchTransitionOverlay()
	if not self:IsInterstitialPreviewOpen() then
		return
	end

	RevealMatchTransitionOverlay()
end

return TournamentController
