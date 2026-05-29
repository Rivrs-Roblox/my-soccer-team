-- Game Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.ZonePlus)

-- Services
local TeleportService = nil

-- Controllers
local DataCacheController = nil
local UIController = nil
local NotificationController = nil

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local TeleportEffectFrame = require(Helpers.TeleportEffectFrame)
local AreaVisual = require(Helpers.Teleport.AreaVisual)

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

local teleportAreas

-- TeleportController
local TeleportController = Knit.CreateController({
	Name = "TeleportController",
	Template = {},
	IsTeleporting = false,
})

local function GetAreaId(area)
	if type(area) == "table" then
		return tostring(area.Id or area.AreaId or "")
	end

	return tostring(area or "")
end

--|| Functions ||--
function TeleportController:_SetCurrentArea(area)
	local areaId = GetAreaId(area)
	if areaId == "" then
		return
	end

	self.CurrentArea = area
	self.CurrentAreaId = areaId

	if self._areaChangedEvent then
		self._areaChangedEvent:Fire(area, areaId)
	end
end

function TeleportController:_SetupTeleportArea(instance: BasePart)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	-- Handle player entering the zone
	zone.playerEntered:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:ShowFrame({ frame = FramesConstants.Travel })
		end
	end)

	zone.playerExited:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:HideFrame()
		end
	end)
end

function TeleportController:_ResetTeleportUi()
	self.IsTeleporting = false
	TeleportEffectFrame("Open")
	UIController:ShowHUD()
end

function TeleportController:_BeginTeleportUi()
	self.IsTeleporting = true
	UIController:HideFrame()
	UIController:RemoveHUD({ ignoreTopFrame = false })
	TeleportEffectFrame("Close")
end

-- Request teleportation to a zone
function TeleportController:RequestTeleport(id: string)
	if not id or id == "" then
		warn("[TeleportController] RequestTeleport called with invalid id")
		return
	end

	if self.IsTeleporting then
		NotificationController:Notify({
			text = "Please wait while teleport is being processed",
			type = "ERROR",
		})
		return
	end

	self:_BeginTeleportUi()

	return TeleportService:TeleportRequest(id)
		:andThen(function()
			task.wait(1)
			self:_ResetTeleportUi()
		end)
		:catch(function(err)
			warn("[TeleportController] TeleportRequest failed:", err)
			self:_ResetTeleportUi()

			NotificationController:Notify({
				text = "Teleport failed",
				type = "ERROR",
			})
	end)
end

function TeleportController:GetCurrentArea()
	return self.CurrentArea
end

function TeleportController:GetCurrentAreaId()
	return self.CurrentAreaId
end

--|| Knit Lifecycle ||--
function TeleportController:KnitInit()
	TeleportService = Knit.GetService("TeleportService")
	DataCacheController = Knit.GetController("DataCacheController")
	UIController = Knit.GetController("UIController")
	NotificationController = Knit.GetController("NotificationController")

	self._areaChangedEvent = Instance.new("BindableEvent")
	self.AreaChanged = self._areaChangedEvent.Event
	self.CurrentArea = nil
	self.CurrentAreaId = nil
	self.Template = DataCacheController:GetFile("Template")

	print("[TELEPORT CONTROLLER] Controller started successfully.")
end

function TeleportController:KnitStart()
	teleportAreas = CollectionService:GetTagged("TeleportArea")
	for _, instance in pairs(teleportAreas) do
		self:_SetupTeleportArea(instance)
	end

	CollectionService:GetInstanceAddedSignal("TeleportArea"):Connect(function(instance)
		self:_SetupTeleportArea(instance)
		table.insert(teleportAreas, instance)
	end)

	local function updateLeagueText(currentArea)
		if not currentArea then
			return
		end

		local areaId = GetAreaId(currentArea)
		local templateData = self.Template.Areas[areaId]
		if not templateData then
			return
		end

		local currentOrder = templateData.Order

		local nextAreaName = "Coming Soon"
		for _, areaData in pairs(self.Template.Areas) do
			if areaData.Order == currentOrder + 1 then
				nextAreaName = areaData.Name
				break
			end
		end

		for _, instance in pairs(teleportAreas) do
			local leagueText = instance.Parent:FindFirstChild("LeagueText", true)
			if leagueText then
				leagueText.Text = string.upper(nextAreaName)
			end
		end
	end

	TeleportService.AreaUpdated:Connect(function(area)
		local areaId = GetAreaId(area)
		if areaId == "" then
			return
		end

		AreaVisual:Apply(areaId)
		updateLeagueText(areaId)
		self:_SetCurrentArea(areaId)
	end)

	-- Get initial area
	task.spawn(function()
		local _, area = TeleportService:GetArea():await()
		if area then
			local areaId = GetAreaId(area)
			if areaId ~= "" then
				AreaVisual:Apply(areaId)
				updateLeagueText(areaId)
				self:_SetCurrentArea(areaId)
			end
		end

		-- Remove LoadingUI after the first area is loaded so player doesn't see void
		task.wait(0.5)
		local loadingGui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LoadingUI")
		if loadingGui then
			loadingGui:Destroy()
		end
	end)
end

return TeleportController
