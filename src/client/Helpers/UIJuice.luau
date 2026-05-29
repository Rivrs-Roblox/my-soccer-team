local TweenService = game:GetService("TweenService")

local UIJuice = {}

local SCALE_NAME = "__UIJuiceScale"
local activeTweens = setmetatable({}, { __mode = "k" })

local function isGuiObject(instance: Instance?): boolean
	return instance ~= nil and instance:IsA("GuiObject")
end

local function cancelTweens(target)
	local tweens = activeTweens[target]
	if not tweens then
		return
	end

	for _, tween in ipairs(tweens) do
		pcall(function()
			tween:Cancel()
			tween:Destroy()
		end)
	end

	activeTweens[target] = nil
end

local function trackTween(target, tween: Tween)
	if not activeTweens[target] then
		activeTweens[target] = {}
	end

	table.insert(activeTweens[target], tween)
	return tween
end

function UIJuice.GetScale(guiObject: GuiObject): UIScale?
	if not isGuiObject(guiObject) then
		return nil
	end

	local scale = guiObject:FindFirstChild(SCALE_NAME)
	if scale and scale:IsA("UIScale") then
		return scale
	end

	scale = Instance.new("UIScale")
	scale.Name = SCALE_NAME
	scale.Scale = 1
	scale.Parent = guiObject
	return scale
end

function UIJuice.SetScale(guiObject: GuiObject, value: number)
	local scale = UIJuice.GetScale(guiObject)
	if not scale then
		return
	end

	cancelTweens(scale)
	scale.Scale = value
end

function UIJuice.PopIn(guiObject: GuiObject, options)
	if not isGuiObject(guiObject) then
		return nil
	end

	options = options or {}
	local scale = UIJuice.GetScale(guiObject)
	if not scale then
		return nil
	end

	cancelTweens(scale)

	local baseScale = tonumber(options.BaseScale) or 1
	local startScale = tonumber(options.StartScale) or 0.72
	local overshootScale = tonumber(options.OvershootScale) or 1.08
	local inDuration = tonumber(options.Duration) or 0.16
	local settleDuration = tonumber(options.SettleDuration) or 0.12

	guiObject.Visible = true
	scale.Scale = startScale

	local grow = trackTween(scale, TweenService:Create(
		scale,
		TweenInfo.new(inDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = overshootScale }
	))

	grow.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or not scale.Parent then
			return
		end

		local settle = trackTween(scale, TweenService:Create(
			scale,
			TweenInfo.new(settleDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = baseScale }
		))
		settle:Play()
	end)

	grow:Play()
	return grow
end

function UIJuice.PopOut(guiObject: GuiObject, options, onComplete)
	if not isGuiObject(guiObject) then
		return nil
	end

	options = options or {}
	local scale = UIJuice.GetScale(guiObject)
	if not scale then
		return nil
	end

	cancelTweens(scale)

	local endScale = tonumber(options.EndScale) or 0.82
	local duration = tonumber(options.Duration) or 0.12
	local hideOnComplete = options.HideOnComplete ~= false

	local shrink = trackTween(scale, TweenService:Create(
		scale,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = endScale }
	))

	shrink.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or not guiObject.Parent then
			return
		end

		if hideOnComplete then
			guiObject.Visible = false
		end

		scale.Scale = 1

		if type(onComplete) == "function" then
			onComplete()
		end
	end)

	shrink:Play()
	return shrink
end

function UIJuice.Punch(guiObject: GuiObject, options)
	if not isGuiObject(guiObject) then
		return nil
	end

	options = options or {}
	local scale = UIJuice.GetScale(guiObject)
	if not scale then
		return nil
	end

	cancelTweens(scale)

	local baseScale = tonumber(options.BaseScale) or 1
	local peakScale = tonumber(options.PeakScale) or 1.12
	local upDuration = tonumber(options.UpDuration) or 0.07
	local downDuration = tonumber(options.DownDuration) or 0.14

	scale.Scale = baseScale

	local up = trackTween(scale, TweenService:Create(
		scale,
		TweenInfo.new(upDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = peakScale }
	))

	up.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or not scale.Parent then
			return
		end

		local down = trackTween(scale, TweenService:Create(
			scale,
			TweenInfo.new(downDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = baseScale }
		))
		down:Play()
	end)

	up:Play()
	return up
end

function UIJuice.Cancel(guiObject: GuiObject)
	if not isGuiObject(guiObject) then
		return
	end

	local scale = guiObject:FindFirstChild(SCALE_NAME)
	if scale and scale:IsA("UIScale") then
		cancelTweens(scale)
		scale.Scale = 1
	end
end

return UIJuice
