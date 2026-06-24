local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local LocalPlayer = Players.LocalPlayer

local LOCAL_REFRESH_DELAYS = { 0, 0.15, 0.4 }
local REMOTE_REFRESH_DELAYS = { 0, 0.15, 0.4, 0.8, 1.5, 3.0 }

local MatchVisibilityController = Knit.CreateController({
	Name = "MatchVisibilityController",
})

local MatchCompanionVisualController = nil
local SoccerCharactersController = nil
local CoachesController = nil

function MatchVisibilityController:_canControlVisibility()
	return MatchCompanionVisualController
		and MatchCompanionVisualController.SetOwnerVisualHidden ~= nil
end

function MatchVisibilityController:_nextRefreshToken(player: Player): number
	local nextToken = (self._refreshTokens[player] or 0) + 1
	self._refreshTokens[player] = nextToken
	return nextToken
end

function MatchVisibilityController:_isRefreshTokenCurrent(player: Player, token: number): boolean
	return self._refreshTokens[player] == token
end

function MatchVisibilityController:_scheduleRefresh(player: Player, delays, callback)
	if not player then
		return
	end

	local token = self:_nextRefreshToken(player)

	for _, delayTime in ipairs(delays) do
		local function run()
			if not player.Parent then
				return
			end

			if not self:_isRefreshTokenCurrent(player, token) then
				return
			end

			callback()
		end

		if delayTime <= 0 then
			task.defer(run)
		else
			task.delay(delayTime, run)
		end
	end
end

function MatchVisibilityController:_applyLocalState()
	-- During match, local visibility is owned by MatchPresentationController.
	-- After match/ceremony return, Attribute replication can arrive after cleanup,
	-- so this controller performs a delayed local restore when IsInMatch becomes false.
	if LocalPlayer:GetAttribute("IsInMatch") == true then
		return
	end

	if not self:_canControlVisibility() then
		return
	end

	if MatchCompanionVisualController.RestoreCompanionsBehindOwner then
		MatchCompanionVisualController:RestoreCompanionsBehindOwner(LocalPlayer)
	end

	MatchCompanionVisualController:SetOwnerVisualHidden(LocalPlayer, false, true)
end

function MatchVisibilityController:_applyRemoteState(player: Player)
	if not player or player == LocalPlayer then
		return
	end

	if not self:_canControlVisibility() then
		return
	end

	local isInMatch = player:GetAttribute("IsInMatch") == true

	if isInMatch then
		MatchCompanionVisualController:SetOwnerVisualHidden(player, true, true)
		return
	end

	if MatchCompanionVisualController.RestoreCompanionsBehindOwner then
		MatchCompanionVisualController:RestoreCompanionsBehindOwner(player)
	end

	MatchCompanionVisualController:SetOwnerVisualHidden(player, false, true)
end

function MatchVisibilityController:_refreshLocalState()
	self:_scheduleRefresh(LocalPlayer, LOCAL_REFRESH_DELAYS, function()
		self:_applyLocalState()
	end)
end

function MatchVisibilityController:_refreshRemoteState(player: Player)
	if not player or player == LocalPlayer then
		return
	end

	if player:GetAttribute("IsInMatch") ~= true then
		self:_refreshRemoteRenderedAssets(player)
	end

	self:_scheduleRefresh(player, REMOTE_REFRESH_DELAYS, function()
		self:_applyRemoteState(player)
	end)
end

function MatchVisibilityController:_refreshRemoteRenderedAssets(player: Player)
	if not player or player == LocalPlayer then
		return
	end

	local nextToken = (self._assetRefreshTokens[player] or 0) + 1
	self._assetRefreshTokens[player] = nextToken

	task.delay(0.2, function()
		if not player.Parent or self._assetRefreshTokens[player] ~= nextToken then
			return
		end

		if player:GetAttribute("IsInMatch") == true then
			return
		end

		if SoccerCharactersController and SoccerCharactersController.RefreshEquippedCharacters then
			SoccerCharactersController:RefreshEquippedCharacters(player)
		end

		task.delay(0.2, function()
			if self:_canControlVisibility() and player.Parent and player:GetAttribute("IsInMatch") ~= true then
				MatchCompanionVisualController:SetOwnerVisualHidden(player, false, true)
			end
		end)
	end)
end

function MatchVisibilityController:_clearRemoteState(player: Player)
	if not player or player == LocalPlayer then
		return
	end

	self:_nextRefreshToken(player)

	if not self:_canControlVisibility() then
		return
	end

	MatchCompanionVisualController:SetOwnerVisualHidden(player, false, true)
end

function MatchVisibilityController:_watchLocalPlayer(player: Player)
	local connections = {}
	self._connections[player] = connections

	table.insert(connections, player:GetAttributeChangedSignal("IsInMatch"):Connect(function()
		self:_refreshLocalState()
	end))

	self:_refreshLocalState()
end

function MatchVisibilityController:_watchRemotePlayer(player: Player)
	local connections = {}
	self._connections[player] = connections

	table.insert(connections, player:GetAttributeChangedSignal("IsInMatch"):Connect(function()
		self:_refreshRemoteState(player)
	end))

	table.insert(connections, player.CharacterAdded:Connect(function()
		self:_refreshRemoteState(player)
	end))

	table.insert(connections, player.CharacterRemoving:Connect(function()
		self:_clearRemoteState(player)
	end))

	self:_refreshRemoteState(player)
end

function MatchVisibilityController:_watchPlayer(player: Player)
	if not player then
		return
	end

	self:_unwatchPlayer(player)

	if player == LocalPlayer then
		self:_watchLocalPlayer(player)
	else
		self:_watchRemotePlayer(player)
	end
end

function MatchVisibilityController:_unwatchPlayer(player: Player)
	local connections = self._connections[player]
	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	self._connections[player] = nil
	self._refreshTokens[player] = nil

	if player and player ~= LocalPlayer then
		self:_clearRemoteState(player)
	end
end

function MatchVisibilityController:KnitInit()
	self._connections = {}
	self._refreshTokens = {}
	self._assetRefreshTokens = {}
end

function MatchVisibilityController:KnitStart()
	MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
	SoccerCharactersController = Knit.GetController("SoccerCharactersController")
	CoachesController = Knit.GetController("CoachesController")

	for _, player in ipairs(Players:GetPlayers()) do
		self:_watchPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_watchPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_unwatchPlayer(player)
	end)

	local soccerController = SoccerCharactersController
	if soccerController and soccerController.SoccerCharacterInstances then
		soccerController.SoccerCharacterInstances.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				local ownerName = child:GetAttribute("Owner")
				if ownerName then
					local player = Players:FindFirstChild(ownerName)
					if player and player ~= LocalPlayer then
						if self:_canControlVisibility() then
							MatchCompanionVisualController:SetOwnerVisualHidden(
								player,
								player:GetAttribute("IsInMatch") == true,
								true
							)
						end
					end
				end
			end
		end)
	end

	if CoachesController and CoachesController.CoachInstances then
		CoachesController.CoachInstances.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				local ownerName = child:GetAttribute("Owner")
				if ownerName then
					local player = Players:FindFirstChild(ownerName)
					if player and player ~= LocalPlayer then
						if self:_canControlVisibility() then
							MatchCompanionVisualController:SetOwnerVisualHidden(
								player,
								player:GetAttribute("IsInMatch") == true,
								true
							)
						end
					end
				end
			end
		end)
	end
end

return MatchVisibilityController
