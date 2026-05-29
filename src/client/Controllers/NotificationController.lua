local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)
local UIJuice = require(script.Parent.Parent.Helpers.UIJuice)

local DEFAULT_TWEEN_SPEED = 0.5
local DEFAULT_TWEEN_DELAY = 0
local DEFAULT_DISPLAY_DURATION = 3
local NOTIFICATION_POS_START = UDim2.fromScale(0.5, 1.2)
local NOTIFICATION_POS_END = UDim2.fromScale(0.5, 0.8)

local NotificationController = Knit.CreateController({
	Name = "NotificationController",
	Colors = {},
	Frame = nil,
	IsProcessing = false,
	Queue = {},
	CurrentTag = nil,
})

local DataCacheController = nil

function NotificationController:ApplyTextStyling(content)
	local rich = false
	if string.find(content, "stopping") then
		if string.find(content, "Shiny") then
			content = string.gsub(content, "Shiny", '<font color="rgb(255,215,0)">Shiny</font>')
			rich = true
		elseif string.find(content, "Rainbow") then
			content = string.gsub(content, "Rainbow", '<font color="rgb(230,72,72)">Rainbow</font>')
			rich = true
		end
	end
	return content, rich
end

function NotificationController:Animate(duration)
	local tweenInfo = TweenInfo.new(
		DEFAULT_TWEEN_SPEED,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0,
		false,
		DEFAULT_TWEEN_DELAY
	)
	local fadeIn = TweenService:Create(self.Frame, tweenInfo, { Position = NOTIFICATION_POS_END })

	UIJuice.PopIn(self.Frame, {
		StartScale = 0.72,
		OvershootScale = 1.08,
		Duration = 0.15,
		SettleDuration = 0.12,
	})
	fadeIn:Play()

	if self._fadeOutTask and coroutine.status(self._fadeOutTask) == "suspended" then
		task.cancel(self._fadeOutTask)
	end

	self._fadeOutTask = task.delay(duration or DEFAULT_DISPLAY_DURATION, function()
		if not self.Frame then
			return
		end

		local fadeOut = TweenService:Create(
			self.Frame,
			TweenInfo.new(DEFAULT_TWEEN_SPEED * 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = NOTIFICATION_POS_START }
		)
		fadeOut:Play()
		UIJuice.PopOut(self.Frame, {
			Duration = DEFAULT_TWEEN_SPEED * 0.35,
			EndScale = 0.86,
		}, function()
			if self.Frame then
				self.Frame:Destroy()
			end
			self.Frame = nil
			self.CurrentTag = nil
			self.IsProcessing = false
			self:ProcessQueue()
		end)
	end)
end

function NotificationController:ShowNotification(params)
	setmetatable(params, { __index = { tag = "", text = "", type = "INFO" } })
	self.CurrentTag = params.tag

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrame"
	frame.Parent = Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = NOTIFICATION_POS_START
	frame.Size = UDim2.fromScale(0.6, 0.2)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 1000000000

	local text = Instance.new("TextLabel")
	text.Name = "NotificationText"
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.5)
	text.Size = UDim2.fromScale(1, 1)
	text.TextSize = 35
	text.FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold)
	text.TextColor3 = self.Colors[params.type]
	text.BackgroundTransparency = 1
	text.ZIndex = 1000000001
	text.TextScaled = true

	local styledText, isRich = self:ApplyTextStyling(params.text)
	text.Text = styledText
	text.RichText = isRich

	local stroke = Instance.new("UIStroke")
	stroke.Parent = text
	stroke.Thickness = 1.5

	text.Parent = frame
	self.Frame = frame

	self:Animate(DEFAULT_DISPLAY_DURATION)
end

function NotificationController:ProcessQueue()
	if self.IsProcessing then
		return
	end
	self.IsProcessing = true

	local params = table.remove(self.Queue, 1)
	if params then
		self:ShowNotification(params)
	else
		self.IsProcessing = false
	end
end

function NotificationController:Notify(params)
	setmetatable(params, { __index = { tag = "", text = "", type = "INFO" } })

	if params.tag ~= "" then
		-- Jika sedang ditampilkan tag yang sama
		if self.CurrentTag == params.tag and self.Frame and self.Frame:FindFirstChild("NotificationText") then
			local textLabel = self.Frame:FindFirstChild("NotificationText")
			if textLabel then
				local styledText, isRich = self:ApplyTextStyling(params.text)
				textLabel.Text = styledText
				textLabel.RichText = isRich
				textLabel.TextColor3 = self.Colors[params.type]
				UIJuice.Punch(self.Frame, {
					PeakScale = 1.08,
					UpDuration = 0.06,
					DownDuration = 0.13,
				})

				-- Mainkan ulang suara
				if params.type == "SUCCESS" then
					Sound:PlaySound("UI_Success")
				elseif params.type == "ERROR" then
					Sound:PlaySound("UI_Error")
				elseif params.type == "WINS" then
					Sound:PlaySound("UI_Wins")
				end
			end

			-- Reset durasi tampil
			if self._fadeOutTask then
				task.cancel(self._fadeOutTask)
				self._fadeOutTask = task.delay(DEFAULT_DISPLAY_DURATION, function()
					if not self.Frame then
						return
					end

					local tweenInfo =
						TweenInfo.new(DEFAULT_TWEEN_SPEED * 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					local fadeOut = TweenService:Create(self.Frame, tweenInfo, { Position = NOTIFICATION_POS_START })
					fadeOut:Play()
					UIJuice.PopOut(self.Frame, {
						Duration = DEFAULT_TWEEN_SPEED * 0.35,
						EndScale = 0.86,
					}, function()
						if self.Frame then
							self.Frame:Destroy()
						end
						self.Frame = nil
						self.CurrentTag = nil
						self.IsProcessing = false
						self:ProcessQueue()
					end)
				end)
			end

			return
		end

		-- Jika tag sudah ada di queue, update notifikasinya
		for i, notif in ipairs(self.Queue) do
			if notif.tag == params.tag then
				self.Queue[i] = params
				return
			end
		end
	end

	-- Mainkan suara jika perlu
	if params.type == "SUCCESS" then
		Sound:PlaySound("UI_Success")
	elseif params.type == "ERROR" then
		Sound:PlaySound("UI_Error")
	elseif params.type == "WINS" then
		Sound:PlaySound("UI_Wins")
	end

	-- Tambahkan ke antrian dan proses
	table.insert(self.Queue, params)
	task.spawn(function()
		self:ProcessQueue()
	end)
end

function NotificationController:KnitInit()
	DataCacheController = Knit.GetController("DataCacheController")
	self.Colors = DataCacheController:GetFile("Colors")
	print("[NOTIFICATION CONTROLLER] Controller loaded successfully.")
end

return NotificationController
