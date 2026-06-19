--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

---- Services
local DataService = nil
local DataCacheService = nil
local SoccerCharactersService = nil
local MatchService = nil

-- TradeService
local TradeService = Knit.CreateService({
	Name = "TradeService",

	Client = {
		TradeCompleted = Knit.CreateSignal(),
		TradeCanceled = Knit.CreateSignal(),

		RequestSent = Knit.CreateSignal(),
		RequestReceived = Knit.CreateSignal(),
		RequestAccepted = Knit.CreateSignal(),
		RequestDeclined = Knit.CreateSignal(),

		MySoccerCharactersChanged = Knit.CreateSignal(),
		HisSoccerCharactersChanged = Knit.CreateSignal(),

		PlayerReady = Knit.CreateSignal(),
		OtherReady = Knit.CreateSignal(),
		Timer = Knit.CreateSignal(),
	},

	Template = {},
	SoccerCharacters = {},

	Requests = {},
	Trades = {},
	Readys = {},
	Proceeding = {},
	PlayersSoccerCharacters = {},
})

--|| Client Functions ||--
function TradeService.Client:AddSoccerCharacter(player: Player, params: table)
	return self.Server:AddSoccerCharacter(player, params)
end

function TradeService.Client:RemoveSoccerCharacter(player: Player, params: table)
	return self.Server:RemoveSoccerCharacter(player, params)
end

function TradeService.Client:Request(player: Player, receiver: Player)
	return self.Server:Request(player, receiver)
end

function TradeService.Client:AcceptRequest(player: Player)
	return self.Server:AcceptRequest(player)
end

function TradeService.Client:DeclineRequest(player: Player)
	return self.Server:DeclineRequest(player)
end

function TradeService.Client:CancelTrade(player: Player)
	return self.Server:CancelTrade(player)
end

function TradeService.Client:Ready(player: Player, state: boolean)
	return self.Server:Ready(player, state)
end

--|| Functions ||--
function TradeService:_hasBeenRequested(player: Player)
	for sender, receiver in pairs(self.Requests) do
		if receiver == player then
			return { s = sender, r = receiver }
		end
	end

	return false
end

function TradeService:_isPlayerMatchBusy(player: Player): boolean
	if not player then
		return false
	end

	if not MatchService then
		return false
	end

	if MatchService.IsPlayerInMatch and MatchService:IsPlayerInMatch(player) then
		return true
	end

	if MatchService.IsPlayerTransitioning and MatchService:IsPlayerTransitioning(player) then
		return true
	end

	return false
end

function TradeService:_clearRequestForPlayer(player: Player)
	local outgoingReceiver = self.Requests[player]
	if outgoingReceiver then
		self.Requests[player] = nil
		self.Client.RequestDeclined:Fire(player, { text = "Trade canceled.", type = "ERROR" })
		self.Client.RequestDeclined:Fire(outgoingReceiver, { text = "Trade canceled.", type = "ERROR" })
	end

	local incomingRequest = self:_hasBeenRequested(player)
	if incomingRequest ~= false then
		self.Requests[incomingRequest.s] = nil
		self.Client.RequestDeclined:Fire(incomingRequest.s, { text = "Trade canceled.", type = "ERROR" })
		self.Client.RequestDeclined:Fire(incomingRequest.r, { text = "Trade canceled.", type = "ERROR" })
	end
end

function TradeService:CancelPlayerActivityForMatch(player: Player)
	self:_clearRequestForPlayer(player)

	local otherPlayer = self.Trades[player]
	if otherPlayer then
		self.Client.TradeCanceled:Fire(player)
		self.Client.TradeCanceled:Fire(otherPlayer)

		self.PlayersSoccerCharacters[player] = nil
		self.PlayersSoccerCharacters[otherPlayer] = nil
		self.Trades[otherPlayer] = nil
		self.Trades[player] = nil
		self.Readys[player] = nil
		self.Readys[otherPlayer] = nil
		self.Proceeding[player] = nil
		self.Proceeding[otherPlayer] = nil
	end
end

----------------------------
------ TRADE HANDLING ------
----------------------------

function TradeService:AddSoccerCharacter(player: Player, params: table)
	setmetatable(params, {
		__index = {
			id = 0,
			name = "",
		},
	})

	local data = DataService:GetData(player)
	if data == nil then
		return warn("[TRADE SERVICE] Player has no data: " .. player.Name)
	end

	if self.Trades[player] == nil then
		return { text = self.Template.Messages.Notifications.Not_Trading, type = "ERROR" }
	end

	local soccerCharacters = self.Template.SoccerCharacters or self.Template.SoccerCharacter
	if not soccerCharacters or soccerCharacters[params.name] == nil then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Not_Exists(params.name), type = "ERROR" }
	end

	local charId = tostring(params.id)
	local soccerCharacter = data.Inventory.SoccerCharacters[charId] or data.Inventory.SoccerCharacters[tonumber(charId)]

	if soccerCharacter == nil then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Not_Yours(params.name), type = "ERROR" }
	end

	local function isEquipped(id)
		for _, equippedId in pairs(data.Inventory.EquippedSoccerCharacters or {}) do
			if tostring(equippedId) == tostring(id) then
				return true
			end
		end
		return false
	end

	if isEquipped(charId) then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Equipped(params.name), type = "ERROR" }
	end

	if self.PlayersSoccerCharacters[player][charId] ~= nil then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Already_Added(params.name), type = "ERROR" }
	end

	self.PlayersSoccerCharacters[player][charId] = soccerCharacter
	self.Client.MySoccerCharactersChanged:Fire(player, self.PlayersSoccerCharacters[player])
	self.Client.HisSoccerCharactersChanged:Fire(self.Trades[player], self.PlayersSoccerCharacters[player])

	return true
end

function TradeService:RemoveSoccerCharacter(player: Player, params: table)
	setmetatable(params, {
		__index = {
			id = 0,
			name = "",
		},
	})

	local data = DataService:GetData(player)
	if data == nil then
		return warn("[TRADE SERVICE] Player has no data: " .. player.Name)
	end

	if self.Trades[player] == nil then
		return { text = self.Template.Messages.Notifications.Not_Trading, type = "ERROR" }
	end

	local soccerCharacters = self.Template.SoccerCharacters or self.Template.SoccerCharacter
	if not soccerCharacters or soccerCharacters[params.name] == nil then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Not_Exists(params.name), type = "ERROR" }
	end

	local charId = tostring(params.id)
	if self.PlayersSoccerCharacters[player][charId] == nil then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Not_Added(params.name), type = "ERROR" }
	end

	self.PlayersSoccerCharacters[player][charId] = nil
	self.Client.MySoccerCharactersChanged:Fire(player, self.PlayersSoccerCharacters[player])
	self.Client.HisSoccerCharactersChanged:Fire(self.Trades[player], self.PlayersSoccerCharacters[player])

	return true
end

function TradeService:Ready(player: Player, state: boolean)
	if self.Trades[player] == nil then
		return { text = self.Template.Messages.Notifications.Not_Trading, type = "ERROR" }
	end
	if self.Proceeding[player] ~= nil then
		return { text = self.Template.Messages.Notifications.Trade_Proceeding, type = "ERROR" }
	end

	self.Readys[player] = state

	self.Client.PlayerReady:Fire(player, state)
	self.Client.OtherReady:Fire(self.Trades[player], state)

	if self.Readys[player] == true and self.Readys[self.Trades[player]] == true then
		for i = 5, 1, -1 do
			if self.Readys[player] == false or self.Readys[self.Trades[player]] == false then
				return
			end

			self.Client.Timer:Fire(player, i)
			self.Client.Timer:Fire(self.Trades[player], i)

			task.wait(1)
		end

		self:ProcessTrade(self.Trades[player])
		self:ProcessTrade(player)
	end
end

function TradeService:ProcessTrade(player: Player)
	if self.Trades[player] == nil then
		return { text = self.Template.Messages.Notifications.Not_Trading, type = "ERROR" }
	end

	self.Proceeding[player] = true

	for id, SoccerCharacter in pairs(self.PlayersSoccerCharacters[player]) do
		SoccerCharactersService:DeleteCharacter(player, id)
		SoccerCharactersService:AddCharacter(self.Trades[player], SoccerCharacter.Name, SoccerCharacter)
	end

	self.PlayersSoccerCharacters[player] = nil
	self.Trades[player] = nil
	self.Readys[player] = nil
	self.Proceeding[player] = nil

	self.Client.TradeCompleted:Fire(player)

	return true
end

function TradeService:CancelTrade(player: Player)
	if self.Trades[player] == nil then
		return { text = self.Template.Messages.Notifications.Not_Trading, type = "ERROR" }
	end

	self.Client.TradeCanceled:Fire(player)
	self.Client.TradeCanceled:Fire(self.Trades[player])

	self.PlayersSoccerCharacters[player] = nil
	self.PlayersSoccerCharacters[self.Trades[player]] = nil
	self.Trades[self.Trades[player]] = nil
	self.Readys[player] = nil
	self.Readys[self.Trades[player]] = nil
	self.Trades[player] = nil
end

-------------------------------
------ REQUESTS HANDLING ------
-------------------------------

function TradeService:Request(player: Player, receiver: Player)
	if self:_isPlayerMatchBusy(player) or self:_isPlayerMatchBusy(receiver) then
		return { text = "Cannot trade during a match.", type = "ERROR" }
	end

	if player == receiver then
		return { text = self.Template.Messages.Notifications.Cant_Trade_Yourself, type = "ERROR" }
	end
	if self.Requests[player] ~= nil then
		return { text = self.Template.Messages.Notifications.Already_Requesting, type = "ERROR" }
	end
	if self.Trades[player] ~= nil then
		return { text = self.Template.Messages.Notifications.Already_Trading, type = "ERROR" }
	end
	if self.Trades[receiver] ~= nil then
		return { text = self.Template.Messages.Notifications.Player_Already_Trading(receiver.Name), type = "ERROR" }
	end

	local data = DataService:GetData(player)
	local rData = DataService:GetData(receiver)

	if data.Settings.Trade == false then
		return { text = self.Template.Messages.Notifications.Enable_Trade, type = "ERROR" }
	end
	if rData.Settings.Trade == false then
		return { text = self.Template.Messages.Notifications.Trade_Disabled(receiver.Name), type = "ERROR" }
	end

	self.Requests[player] = receiver

	self.Client.RequestSent:Fire(player, receiver)
	-- Signale au receveur qu'il a reçu une demande
	self.Client.RequestReceived:Fire(receiver, player)

	-- Délai de 10 secondes avant d'annuler automatiquement la demande
	task.delay(10, function()
		-- Vérifie si la demande existe encore après 10 secondes
		if self.Requests[player] == receiver then
			-- Annule la demande si elle n'a pas été acceptée ou refusée
			self.Requests[player] = nil
			self.Client.RequestDeclined:Fire(receiver, { text = "Trade request has expired.", type = "ERROR" })
			self.Client.RequestDeclined:Fire(player, { text = "Trade request has expired.", type = "ERROR" })
			warn("La demande de trade a expiré entre " .. player.Name .. " et " .. receiver.Name)
		end
	end)

	return { text = self.Template.Messages.Notifications.Request_Sent(receiver.Name), type = "SUCCESS" }
end

function TradeService:AcceptRequest(player: Player)
	local request = self:_hasBeenRequested(player)
	if request == false then
		return { text = self.Template.Messages.Notifications.No_Request, type = "ERROR" }
	end
	if self:_isPlayerMatchBusy(player) or self:_isPlayerMatchBusy(request.s) then
		self.Requests[request.s] = nil
		self.Client.RequestDeclined:Fire(request.s, { text = "Trade canceled.", type = "ERROR" })
		self.Client.RequestDeclined:Fire(player, { text = "Trade canceled.", type = "ERROR" })
		return { text = "Cannot trade during a match.", type = "ERROR" }
	end
	if self.Trades[player] ~= nil then
		return { text = self.Template.Messages.Notifications.Already_Trading, type = "ERROR" }
	end

	-- Vérifie si la demande a expiré
	if self.Requests[request.s] ~= player then
		return { text = self.Template.Messages.Notifications.Request_Expired, type = "ERROR" }
	end

	self.Requests[request.s] = nil

	self.Trades[request.s] = request.r
	self.Trades[request.r] = request.s

	self.PlayersSoccerCharacters[request.s] = {}
	self.PlayersSoccerCharacters[request.r] = {}

	self.Client.RequestAccepted:Fire(request.s, request.r)
	self.Client.RequestAccepted:Fire(request.r, nil)
end

function TradeService:DeclineRequest(player: Player)
	local request = self:_hasBeenRequested(player)
	if request == false then
		return { text = self.Template.Messages.Notifications.No_Request, type = "ERROR" }
	end
	if self.Trades[player] ~= nil then
		return { text = self.Template.Messages.Notifications.Already_Trading, type = "ERROR" }
	end

	self.Requests[request.s] = nil

	self.Client.RequestDeclined:Fire(
		request.s,
		{ text = self.Template.Messages.Notifications.Request_Declined(request.r.Name), type = "ERROR" }
	)
	self.Client.RequestDeclined:Fire(
		request.r,
		{ text = self.Template.Messages.Notifications.Request_Declined(request.r.Name), type = "ERROR" }
	)

	return { text = self.Template.Messages.Notifications.Request_Declined(player.Name), type = "ERROR" }
end

--|| Knit Lifecycle ||--
function TradeService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	SoccerCharactersService = Knit.GetService("SoccerCharactersService")

	self.Template = DataCacheService:GetFile("Template")
	self.SoccerCharacters = self.Template.SoccerCharacters

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_clearRequestForPlayer(player)

		if self.Trades[player] ~= nil then
			self.Client.TradeCanceled:Fire(self.Trades[player])

			self.PlayersSoccerCharacters[player] = nil
			self.PlayersSoccerCharacters[self.Trades[player]] = nil
			self.Trades[self.Trades[player]] = nil
			self.Readys[player] = nil
			self.Readys[self.Trades[player]] = nil
			self.Proceeding[player] = nil
			self.Trades[player] = nil
		end
	end)

	print("[TRADE SERVICE] Service loaded successfully.")
end

function TradeService:KnitStart()
	local ok, service = pcall(function()
		return Knit.GetService("MatchService")
	end)
	if ok then
		MatchService = service
	end
end

return TradeService
