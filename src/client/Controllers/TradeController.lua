--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Controllers
local NotificationController = nil
local DataCacheController = nil
local UIController = nil

-- PetsService
local TradeService = nil

-- TradeController
local TradeController = Knit.CreateController({
	Name = "TradeController",
	IsTrading = false,

	Template = {},
})

--|| Functions ||--
function TradeController:AddSoccerCharacter(params: table)
	local promise, res = TradeService:AddSoccerCharacter(params):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while adding soccer character to trade.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

function TradeController:RemoveSoccerCharacter(params: table)
	local promise, res = TradeService:RemoveSoccerCharacter(params):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while removing soccer character from trade.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

function TradeController:AcceptRequest()
	local promise, res = TradeService:AcceptRequest():await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while acceting trade request.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

function TradeController:DeclineRequest()
	local promise, res = TradeService:DeclineRequest():await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while declining trade request.")
	end

	-- if type(res) == "table" and res.type == "ERROR" then NotificationController:Notify(res) end
end

function TradeController:CancelTrade()
	local promise, res = TradeService:CancelTrade():await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while canceling trade request.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

function TradeController:Request(player: Player)
	local promise, res = TradeService:Request(player):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while sending trade request.")
	end

	if type(res) == "table" then
		NotificationController:Notify(res)
	end
end

function TradeController:Ready(state: boolean)
	local promise, res = TradeService:Ready(state):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while being ready for trade.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

--|| Knit Lifecycle ||--
function TradeController:KnitInit()
	NotificationController = Knit.GetController("NotificationController")
	DataCacheController = Knit.GetController("DataCacheController")
	UIController = Knit.GetController("UIController")

	TradeService = Knit.GetService("TradeService")

	self.Template = DataCacheController:GetFile("Template")

	TradeService.TradeCompleted:Connect(function()
		UIController:HideFrame()
		NotificationController:Notify({ text = self.Template.Messages.Notifications.Trade_Completed, type = "SUCCESS" })
		self.IsTrading = false
	end)

	TradeService.TradeCanceled:Connect(function()
		UIController:HideFrame()
		self.IsTrading = false
	end)

	TradeService.RequestDeclined:Connect(function(message)
		UIController:HideFrame()
		NotificationController:Notify(message)
		self.IsTrading = false
	end)

	TradeService.RequestAccepted:Connect(function()
		UIController:RemoveHUD({ ignoreTopFrame = false })
		self.IsTrading = true
	end)

	TradeService.RequestReceived:Connect(function()
		UIController:RemoveHUD({ ignoreTopFrame = false })
		self.IsTrading = true
	end)

	print("[TRADE CONTROLLER] Controller loaded successfully.")
end

return TradeController
