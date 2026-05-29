-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Knit packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.ZonePlus)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Knit Services
local GachaService

-- Knit Controllers
local NotificationController
local UIController

-- Shared Modules
local Gacha = require(ReplicatedStorage.Shared.Modules.Gacha)

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- GachaController
local GachaController = Knit.CreateController({
	Name = "GachaController",
	Opening = false,
	Queue = {},
	CurrentStock = {},
	NextRefillTime = 0,
	StockUpdated = Signal.new(),
	RefillTimeUpdated = Signal.new(),
})

--|| Functions ||--
function GachaController:_SetupGachaArea(instance: BasePart)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	-- Handle player entering the zone
	zone.playerEntered:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:ShowFrame({ frame = FramesConstants.Packs })
		end
	end)

	zone.playerExited:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:HideFrame()
		end
	end)
end

function GachaController:Buy(category, type, currency, amount)
	GachaService:BuyGacha(category, type, currency, amount):andThen(function(result)
		if result.type == "ERROR" then
			NotificationController:Notify({
				tag = "Gacha",
				text = result.text,
				type = result.type,
			})
		end
	end)
end

function GachaController:Open(items, type, category)
	if self.Opening then
		table.insert(self.Queue, { items = items, type = type, category = category })
		return
	end
	self.Opening = true

	Gacha.Open(items, type, category)

	while #self.Queue > 0 do
		local nextGacha = table.remove(self.Queue, 1)
		Gacha.Open(nextGacha.items, nextGacha.type, nextGacha.category)
	end

	self.Opening = false
end

--|| Knit Lifecycle ||--
function GachaController:KnitInit()
	GachaService = Knit.GetService("GachaService")

	NotificationController = Knit.GetController("NotificationController")
	UIController = Knit.GetController("UIController")
end

function GachaController:KnitStart()
	GachaService.GachaOpened:Connect(function(items, type, category)
		self:Open(items, type, category)
	end)

	GachaService.StockUpdated:Connect(function(stock, nextRefillTime)
		self.CurrentStock = stock
		if nextRefillTime then
			self.NextRefillTime = nextRefillTime
			self.RefillTimeUpdated:Fire(nextRefillTime)
		end
		self.StockUpdated:Fire(stock)
		NotificationController:Notify({
			tag = "Gacha",
			text = "Packs have been restocked!",
			type = "SUCCESS",
		})
	end)

	GachaService:GetStock():andThen(function(stock)
		self.CurrentStock = stock
		self.StockUpdated:Fire(stock)
	end)

	GachaService:GetNextRefillTime():andThen(function(nextRefillTime)
		if nextRefillTime then
			self.NextRefillTime = nextRefillTime
			self.RefillTimeUpdated:Fire(nextRefillTime)
		end
	end)

	local existingAreas = CollectionService:GetTagged("GachaArea")
	for _, instance in pairs(existingAreas) do
		self:_SetupGachaArea(instance)
	end

	CollectionService:GetInstanceAddedSignal("GachaArea"):Connect(function(instance)
		self:_SetupGachaArea(instance)
	end)
end

return GachaController
