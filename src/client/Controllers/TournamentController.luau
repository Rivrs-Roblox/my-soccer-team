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

	local ok2, coachesController = pcall(function()
		return Knit.GetController("CoachesController")
	end)

	task.spawn(function()
		local character = LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local startPos = rootPart.Position
			local elapsed = 0
			while elapsed < 0.5 do
				task.wait(0.05)
				elapsed += 0.05
				if rootPart.Parent and (rootPart.Position - startPos).Magnitude > 3 then
					break
				end
			end
		end

		task.wait(0.05)

		if LocalPlayer and LocalPlayer.Parent then
			if ok and companionController and companionController.RestoreCompanionsBehindOwner then
				pcall(function()
					companionController:RestoreCompanionsBehindOwner(LocalPlayer)
				end)
			end
			if ok2 and coachesController and coachesController.RestoreCoachesBehindOwner then
				pcall(function()
					coachesController:RestoreCoachesBehindOwner(LocalPlayer)
				end)
			end
		end
	end)
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

local function ResetMatchUiAfterTournamentPreviewClose()
	local ok, matchUiController = pcall(function()
		return Knit.GetController("MatchUIController")
	end)

	if not ok or not matchUiController then
		return
	end

	pcall(function()
		if matchUiController.EndMatchUi then
			matchUiController:EndMatchUi()
		else
			if matchUiController.ClearActiveMatchSession then
				matchUiController:ClearActiveMatchSession()
			end
			if matchUiController.HideQte then
				matchUiController:HideQte()
			end
			if matchUiController.HideExitButton then
				matchUiController:HideExitButton()
			end
			if matchUiController.HideGoalsPill then
				matchUiController:HideGoalsPill()
			end
			if matchUiController.HideComparePill then
				matchUiController:HideComparePill()
			end
			if matchUiController.HideBroadcastHud then
				matchUiController:HideBroadcastHud()
			end
			if matchUiController.SetCompareText then
				matchUiController:SetCompareText("")
			end
			if matchUiController.ClearTransitionOverlay then
				matchUiController:ClearTransitionOverlay()
			end
		end
	end)
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

local function CancelPendingStartOnly()
	if not TournamentService or not TournamentService.CancelPendingStart then
		return false
	end

	local ok, result = pcall(function()
		return ResolveRemoteResult(TournamentService:CancelPendingStart({
			TeleportToReturnPoint = false,
		}))
	end)

	if not ok then
		warn("[TournamentController] CancelPendingStart failed: " .. tostring(result))
	end

	return ok and result == true
end

local function CloseLobbyUiForTournamentPreview()
	local gachaOk, gachaController = pcall(function()
		return Knit.GetController("GachaController")
	end)

	if gachaOk and gachaController and gachaController.SkipActiveAnimation then
		pcall(function()
			gachaController:SkipActiveAnimation()
		end)
	end

	local ok, uiController = pcall(function()
		return Knit.GetController("UIController")
	end)

	if ok and uiController and uiController.CloseAllPanelsForMatch then
		pcall(function()
			uiController:CloseAllPanelsForMatch()
		end)
	end

	local notificationOk, notificationController = pcall(function()
		return Knit.GetController("NotificationController")
	end)

	if notificationOk and notificationController and notificationController.ClearQueueForMatch then
		pcall(function()
			notificationController:ClearQueueForMatch()
		end)
	end
end

local function UnlockLobbyUiAfterTournamentPreview()
	local ok, uiController = pcall(function()
		return Knit.GetController("UIController")
	end)

	if ok and uiController and uiController.SetMatchUiBlocked then
		pcall(function()
			uiController:SetMatchUiBlocked(false)
		end)
	end
end

local function IsPurchasePromptActive(): boolean
	local ok, monetizationController = pcall(function()
		return Knit.GetController("MonetizationController")
	end)

	if not ok or not monetizationController or not monetizationController.IsPurchasePromptActive then
		return false
	end

	local activeOk, isActive = pcall(function()
		return monetizationController:IsPurchasePromptActive()
	end)

	return activeOk and isActive == true
end

function TournamentController:_showPreviewPayload(payload)
	self._latestPayload = payload
	self._isPreviewOpen = true
	self._isInterstitial = self._pendingInterstitialPreview == true
	self._pendingInterstitialPreview = false
	self._previewRequestedEvent:Fire(payload)
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
	self._previewRequestToken = 0
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
		if IsPurchasePromptActive() then
			task.spawn(function()
				CancelPendingStartOnly()
			end)
			return
		end

		CloseLobbyUiForTournamentPreview()
		self._latestPayload = payload
		self._previewRequestToken += 1
		self:_showPreviewPayload(payload)
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

			-- Multi-leg: leg continuation is handled server-side.
			-- Don't show bracket preview or interstitial between legs.
			if reasonText == "LegContinuation" then
				return
			end

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
				CloseLobbyUiForTournamentPreview()
				self._previewRequestToken += 1
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
	self._previewRequestToken += 1
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
		ResetMatchUiAfterTournamentPreviewClose()
		UnlockLobbyUiAfterTournamentPreview()

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
