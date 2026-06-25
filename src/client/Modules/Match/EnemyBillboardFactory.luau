-- EnemyBillboardFactory
-- Billboard stats di atas kepala enemy yang aktif di QTE.
-- Layout: satu baris horizontal [Icon kiri] [Value teks kanan]
-- Value menunjukkan apakah stat player dapat melewati enemy; icon tetap putih.

local EnemyBillboardFactory = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local helpers = ReplicatedStorage.Shared.Helpers
local formatnumber = require(helpers.Numbers.FormatNumber)

local DEFAULT_OFFSET       = Vector3.new(0, 2.8, 0)
local DEFAULT_MAX_DISTANCE = 22
local KEEPER_MAX_DISTANCE  = 80   -- Shoot step: keeper jauh di gawang

-- Font Ubuntu Bold
local UBUNTU_BOLD = Font.new(
	"rbxasset://fonts/families/Ubuntu.json",
	Enum.FontWeight.Bold,
	Enum.FontStyle.Normal
)

local COLOR_DEFAULT = Color3.fromRGB(255, 255, 255)
local COLOR_CAN_PASS = Color3.fromRGB(90, 255, 130)
local COLOR_BLOCKED = Color3.fromRGB(255, 90, 90)

local function ResolveComparisonColor(canPass)
	if canPass == true then
		return COLOR_CAN_PASS
	elseif canPass == false then
		return COLOR_BLOCKED
	end
	return COLOR_DEFAULT
end

local function GetBasePartFromInstance(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") then
		local head = instance:FindFirstChild("Head", true)
		if head and head:IsA("BasePart") then return head end
		if instance.PrimaryPart then return instance.PrimaryPart end
		local hrp = instance:FindFirstChild("HumanoidRootPart", true)
		if hrp and hrp:IsA("BasePart") then return hrp end
		return instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function ResolveIconForAction(actionName)
	local name = string.lower(tostring(actionName or ""))
	if name == "dribble" then return "rbxassetid://117288549634340" end
	if name == "pass"    then return "rbxassetid://75325465516576"  end
	if name == "shoot"   then return "rbxassetid://92437273343020"  end
	return "rbxassetid://117288549634340"
end

-- Buat billboard enemy: satu baris [Icon] [Value]
function EnemyBillboardFactory.Create(targetInstance, value, stepIndex, worldOffset)
	local adornee = GetBasePartFromInstance(targetInstance)
	if not adornee then return nil end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LocalMatchEnemyBillboard"
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.Enabled = false          -- hidden sampai QTE step ini aktif
	billboard.ResetOnSpawn = false
	billboard.LightInfluence = 0
	billboard.MaxDistance = DEFAULT_MAX_DISTANCE
	billboard.Size = UDim2.fromOffset(160, 44)
	billboard.StudsOffsetWorldSpace = worldOffset or DEFAULT_OFFSET
	billboard.Adornee = adornee
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Holder transparan, full size
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = billboard

	-- Layout horizontal: icon kiri, value kanan
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 5)
	rowLayout.Parent = holder

	-- Icon QTE (kanan) — warna selalu putih
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(36, 36)
	icon.Image = "rbxassetid://117288549634340"     -- diupdate saat SetActive
	icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.LayoutOrder = 2
	icon.Parent = holder

	-- Value teks (kiri) - Text diposisikan di kanan, ukuran agar tidak overlap
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.BackgroundTransparency = 1
	valueLabel.Size = UDim2.fromOffset(0, 36)
	valueLabel.AutomaticSize = Enum.AutomaticSize.X
	valueLabel.Text = formatnumber(value or 0)
	valueLabel.TextScaled = false
	valueLabel.TextSize = 34
	valueLabel.FontFace = UBUNTU_BOLD
	valueLabel.TextColor3 = COLOR_DEFAULT
	valueLabel.TextStrokeTransparency = 0.15
	valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.LayoutOrder = 1
	valueLabel.Parent = holder

	return billboard
end

-- Tampilkan/sembunyikan billboard, update icon+nilai sesuai action QTE.
function EnemyBillboardFactory.SetActive(billboard, isActive, actionName, valueNumber, canPass)
	if not billboard then return end

	billboard.Enabled = isActive == true

	if not isActive then return end

	-- Perbesar MaxDistance untuk keeper (step SHOOT)
	local isShoot = string.lower(tostring(actionName or "")) == "shoot"
	billboard.MaxDistance = isShoot and KEEPER_MAX_DISTANCE or DEFAULT_MAX_DISTANCE

	local holder = billboard:FindFirstChild("Holder")
	if not holder then return end

	local icon = holder:FindFirstChild("Icon")
	local valueLabel = holder:FindFirstChild("Value")
	local comparisonColor = ResolveComparisonColor(canPass)

	-- Update icon sesuai action
	if icon and icon:IsA("ImageLabel") and actionName then
		icon.Image = ResolveIconForAction(actionName)
		icon.ImageColor3 = COLOR_DEFAULT
	end

	-- Update nilai dan warna berdasarkan perbandingan stat player.
	if valueLabel and valueLabel:IsA("TextLabel") then
		if valueNumber ~= nil then
			valueLabel.Text = formatnumber(valueNumber)
		end
		valueLabel.TextColor3 = comparisonColor
	end
end

function EnemyBillboardFactory.SetComparisonState(billboard, canPass, valueNumber)
	if not billboard then return end

	local holder = billboard:FindFirstChild("Holder")
	if not holder then return end

	local comparisonColor = ResolveComparisonColor(canPass)
	local valueLabel = holder:FindFirstChild("Value")

	if valueLabel and valueLabel:IsA("TextLabel") then
		if valueNumber ~= nil then
			valueLabel.Text = formatnumber(valueNumber)
		end
		valueLabel.TextColor3 = comparisonColor
	end
end

return EnemyBillboardFactory
