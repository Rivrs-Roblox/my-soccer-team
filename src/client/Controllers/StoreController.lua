--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.ZonePlus)

-- Services
local MonetizationService = nil

-- Controllers
local NotificationController = nil
local DataCacheController = nil
local MonetizationController = nil
local UIController = nil

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- StoreController
local StoreController = Knit.CreateController({
	Name = "StoreController",

	Template = {} :: nil,
})

--|| Functions ||--
function StoreController:BuyItem(params: table)
	setmetatable(params, { __index = { name = "" :: string } })

	if params.name == "" then
		return
	end

	local res = MonetizationController:GetID(params.name)

	if res ~= nil then
		local p, r = MonetizationService:PromptPurchase(res.ID, res.Type):await()
		if p == false then
			return warn("[STORE CONTROLLER] An internal error occured while prompting for purchase.")
		end

		if r ~= nil then
			NotificationController:Notify(r)
		end
	end
end

function StoreController:_SetupStoreArea(instance: BasePart)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	zone.playerEntered:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:ShowFrame({ frame = FramesConstants.Store })
		end
	end)

	zone.playerExited:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:HideFrame()
		end
	end)
end

--|| Knit Lifecycle ||--
function StoreController:KnitInit()
	MonetizationService = Knit.GetService("MonetizationService")

	NotificationController = Knit.GetController("NotificationController")
	DataCacheController = Knit.GetController("DataCacheController")
	MonetizationController = Knit.GetController("MonetizationController")
	UIController = Knit.GetController("UIController")

	self.Template = DataCacheController:GetFile("Template")
end

function StoreController:KnitStart()
	MonetizationService.PurchaseFinished:Connect(function(success)
		if success then
			NotificationController:Notify({
				text = self.Template.Messages.Notifications.Purchase_Success,
				type = "SUCCESS",
			})
		else
			NotificationController:Notify({ text = self.Template.Messages.Notifications.Purchase_Error, type = "ERROR" })
		end
	end)

	local existingAreas = CollectionService:GetTagged("StoreArea")
	for _, instance in pairs(existingAreas) do
		self:_SetupStoreArea(instance)
	end

	CollectionService:GetInstanceAddedSignal("StoreArea"):Connect(function(instance)
		self:_SetupStoreArea(instance)
	end)

	print("[STORE CONTROLLER] Controller loaded successfully.")
end

return StoreController
