local EnemyBillboardFactory = {}

local DEFAULT_OFFSET = Vector3.new(0, 3.8, 0)
local DEFAULT_MAX_DISTANCE = 18

local ACTIVE_NAME_COLOR = Color3.fromRGB(255, 255, 255)
local INACTIVE_NAME_COLOR = Color3.fromRGB(235, 235, 235)

local ACTIVE_VALUE_COLOR = Color3.fromRGB(255, 240, 120)
local INACTIVE_VALUE_COLOR = Color3.fromRGB(255, 215, 0)

local function GetBasePartFromInstance(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		local head = instance:FindFirstChild("Head", true)
		if head and head:IsA("BasePart") then
			return head
		end

		if instance.PrimaryPart then
			return instance.PrimaryPart
		end

		local humanoidRootPart = instance:FindFirstChild("HumanoidRootPart", true)
		if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
			return humanoidRootPart
		end

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function ResolveEnemyName(stepIndex)
	return string.format("Enemy %d", tonumber(stepIndex) or 0)
end

function EnemyBillboardFactory.Create(targetInstance, value, stepIndex, worldOffset)
	local adornee = GetBasePartFromInstance(targetInstance)
	if not adornee then
		return nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LocalMatchEnemyBillboard"
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.Enabled = true
	billboard.ResetOnSpawn = false
	billboard.LightInfluence = 0
	billboard.MaxDistance = DEFAULT_MAX_DISTANCE
	billboard.Size = UDim2.fromOffset(150, 44)
	billboard.StudsOffsetWorldSpace = worldOffset or DEFAULT_OFFSET
	billboard.Adornee = adornee
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = billboard

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, -1)
	list.Parent = holder

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Text = ResolveEnemyName(stepIndex)
	title.TextScaled = false
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = INACTIVE_NAME_COLOR
	title.TextStrokeTransparency = 0.35
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = holder

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.BackgroundTransparency = 1
	valueLabel.Size = UDim2.new(1, 0, 0, 18)
	valueLabel.Text = tostring(value)
	valueLabel.TextScaled = false
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextColor3 = INACTIVE_VALUE_COLOR
	valueLabel.TextStrokeTransparency = 0.35
	valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.Parent = holder

	return billboard
end

function EnemyBillboardFactory.SetText(billboard, titleText, valueText)
	if not billboard then
		return
	end

	local holder = billboard:FindFirstChild("Holder")
	if not holder or not holder:IsA("Frame") then
		return
	end

	local title = holder:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = titleText
	end

	local valueLabel = holder:FindFirstChild("Value")
	if valueLabel and valueLabel:IsA("TextLabel") then
		valueLabel.Text = valueText
	end
end

function EnemyBillboardFactory.SetActive(billboard, isActive)
	if not billboard then
		return
	end

	local holder = billboard:FindFirstChild("Holder")
	if not holder or not holder:IsA("Frame") then
		return
	end

	local title = holder:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.TextColor3 = isActive and ACTIVE_NAME_COLOR or INACTIVE_NAME_COLOR
	end

	local valueLabel = holder:FindFirstChild("Value")
	if valueLabel and valueLabel:IsA("TextLabel") then
		valueLabel.TextColor3 = isActive and ACTIVE_VALUE_COLOR or INACTIVE_VALUE_COLOR
	end
end

return EnemyBillboardFactory