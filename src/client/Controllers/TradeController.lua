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
local MatchController = nil

-- PetsService
local TradeService = nil

-- TradeController
local TradeController = Knit.CreateController({
	Name = "TradeController",
	IsTrading = false,

	Template = {},
})

local function IsMatchUiBlocked()
	if not MatchController then
		pcall(function()
			MatchController = Knit.GetController("MatchController")
		end)
	end

	if MatchController and MatchController.IsPlayingMatch then
		local ok, isPlaying = pcall(function()
			return MatchController:IsPlayingMatch()
		end)
		return ok and isPlaying == true
	end

	if UIController and UIController.IsUiBlockedForMatch then
		local ok, isBlocked = pcall(function()
			return UIController:IsUiBlockedForMatch()
		end)
		return ok and isBlocked == true
	end

	return false
end

--|| Functions ||--
function TradeController:AddSoccerCharacter(params: table)
	if IsMatchUiBlocked() then
		return
	end

	local promise, res = TradeService:AddSoccerCharacter(params):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while adding soccer character to trade.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

function TradeController:RemoveSoccerCharacter(params: table)
	if IsMatchUiBlocked() then
		return
	end

	local promise, res = TradeService:RemoveSoccerCharacter(params):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while removing soccer character from trade.")
	end

	if type(res) == "table" and res.type == "ERROR" then
		NotificationController:Notify(res)
	end
end

function TradeController:AcceptRequest()
	if IsMatchUiBlocked() then
		return
	end

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
	if IsMatchUiBlocked() then
		return
	end

	local promise, res = TradeService:Request(player):await()
	if promise == false then
		return warn("[TRADE CONTROLLER] An internal error occured while sending trade request.")
	end

	if type(res) == "table" then
		NotificationController:Notify(res)
	end
end

function TradeController:Ready(state: boolean)
	if IsMatchUiBlocked() then
		return
	end

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
	pcall(function()
		MatchController = Knit.GetController("MatchController")
	end)

	TradeService = Knit.GetService("TradeService")

	self.Template = DataCacheController:GetFile("Template")

	TradeService.TradeCompleted:Connect(function()
		self.IsTrading = false
		if not IsMatchUiBlocked() then
			UIController:HideFrame()
			NotificationController:Notify({ text = self.Template.Messages.Notifications.Trade_Completed, type = "SUCCESS" })
		end
	end)

	TradeService.TradeCanceled:Connect(function()
		self.IsTrading = false
		if not IsMatchUiBlocked() then
			UIController:HideFrame()
		end
	end)

	TradeService.RequestDeclined:Connect(function(message)
		self.IsTrading = false
		if not IsMatchUiBlocked() then
			UIController:HideFrame()
			NotificationController:Notify(message)
		end
	end)

	TradeService.RequestAccepted:Connect(function()
		if not IsMatchUiBlocked() then
			self.IsTrading = true
			UIController:JustHideFrame()
			UIController:RemoveHUD({ ignoreTopFrame = false })
		end
	end)

	TradeService.RequestReceived:Connect(function()
		if not IsMatchUiBlocked() then
			self.IsTrading = true
			UIController:JustHideFrame()
			UIController:RemoveHUD({ ignoreTopFrame = false })
		end
	end)

	print("[TRADE CONTROLLER] Controller loaded successfully.")
end

return TradeController
