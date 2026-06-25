-- PlayerBillboardFactory
-- Menyiapkan UI nama/title secara permanen untuk player dan companion selama match
-- Menggunakan sistem cache pada PlayerGui agar tidak kedip jika actor model diganti.
-- UI QTE Stats dipisah menjadi billboard tersendiri di atas nama agar tidak mengganggu layout name bawaan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local helpers = ReplicatedStorage.Shared.Helpers
local formatnumber = require(helpers.Numbers.FormatNumber)

local LocalPlayer = Players.LocalPlayer

-- Font Ubuntu Bold
local UBUNTU_BOLD = Font.new(
	"rbxasset://fonts/families/Ubuntu.json",
	Enum.FontWeight.Bold,
	Enum.FontStyle.Normal
)

-- Warna
local COLOR_STAT    = Color3.fromRGB(255, 255, 255)

local PlayerBillboardFactory = {}
local cachedBillboards = {}      -- Menyimpan billboard nama
local cachedStatsBillboards = {} -- Menyimpan billboard stats QTE

local TitleService = nil
local Knit = nil
pcall(function()
	Knit = require(ReplicatedStorage.Packages.Knit)
	TitleService = Knit.GetService("TitleService")
end)

local function ResolveIconForAction(actionName)
	local name = string.lower(tostring(actionName or ""))
	if name == "dribble" then return "rbxassetid://117288549634340" end
	if name == "pass"    then return "rbxassetid://75325465516576"  end
	if name == "shoot"   then return "rbxassetid://92437273343020"  end
	return "rbxassetid://117288549634340"
end

-- Sembunyikan billboard bawaan actor model agar tidak muncul ganda (duplikat)
local function HideInherentActorBillboards(actorModel)
	if not actorModel then return end
	local titleGui = actorModel:FindFirstChild("PlayerTitleGuiName") or actorModel:FindFirstChild("PlayerTitleGui")
	if titleGui then
		titleGui.Enabled = false
	end
	local charNameGui = actorModel:FindFirstChild("CharacterName")
	if charNameGui then
		charNameGui.Enabled = false
	end
end

-- Cari atau buat billboard nama
local function GetOrCreateNameBillboard(actorModel, slotNumber)
	if not actorModel then return nil end

	-- Matikan billboard bawaan model agar tidak dobel
	HideInherentActorBillboards(actorModel)

	if cachedBillboards[slotNumber] then
		return cachedBillboards[slotNumber]
	end

	local targetParent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or workspace
	local billboard

	if slotNumber == 1 then
		local char = LocalPlayer.Character
		local existing = char and (char:FindFirstChild("PlayerTitleGuiName") or char:FindFirstChild("PlayerTitleGui"))
		if existing then
			billboard = existing:Clone()
		else
			local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GUIs"):WaitForChild("PlayerTitleGui")
			if template then
				billboard = template:Clone()
				billboard.Frame.NameText.Text = LocalPlayer.DisplayName
				if TitleService then
					local ok, title = pcall(function() return TitleService:GetMyTitle() end)
					if ok and type(title) == "string" then
						billboard.Frame.TitleText.Text = title
					end
				end
			end
		end
		
		if billboard then
			billboard.Name = "PlayerTitleGuiName_Slot1"
			billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		end
	else
		-- Untuk Slot 2,3,4, coba ambil dari original model di SoccerCharactersController agar Rarity/Level tercopy utuh
		local soccerNameAttr = actorModel:GetAttribute("SoccerCharacter")
		local SoccerCharactersController = Knit and Knit.GetController("SoccerCharactersController") or nil
		local originalModel = nil
		if soccerNameAttr and SoccerCharactersController and SoccerCharactersController.SoccerCharacterInstances then
			originalModel = SoccerCharactersController.SoccerCharacterInstances:FindFirstChild(soccerNameAttr)
		end

		local existing = (originalModel and originalModel:FindFirstChild("CharacterName")) or actorModel:FindFirstChild("CharacterName")
		if existing then
			billboard = existing:Clone()
		else
			local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Prompts"):WaitForChild("CharacterName")
			if template then
				billboard = template:Clone()
				local NameTL = billboard:WaitForChild("Name", 3)
				if NameTL and soccerNameAttr then
					NameTL.Text = soccerNameAttr
				end
			end
		end
		
		if billboard then
			billboard.Name = "CharacterName_Slot" .. tostring(slotNumber)
			billboard.StudsOffset = Vector3.new(0, 3.8, 0)
		end
	end

	if billboard then
		billboard.AlwaysOnTop = true
		billboard.ResetOnSpawn = false
		billboard.Parent = targetParent
		billboard.Enabled = true
		cachedBillboards[slotNumber] = billboard
	end

	return billboard
end

-- Buat billboard khusus stats (terpisah agar posisinya bisa dinaikkan dan tidak bertumpuk/clipping)
local function GetOrCreateStatsBillboard(actorModel, slotNumber)
	if not actorModel then return nil end

	if cachedStatsBillboards[slotNumber] then
		return cachedStatsBillboards[slotNumber]
	end

	local targetParent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or workspace
	
	local statsBillboard = Instance.new("BillboardGui")
	statsBillboard.Name = "QteStatsBillboard_Slot" .. tostring(slotNumber)
	statsBillboard.Size = UDim2.fromOffset(160, 44)
	-- Offset diletakkan jauh lebih tinggi agar tidak menutupi nama
	statsBillboard.StudsOffset = (slotNumber == 1) and Vector3.new(0, 5.5, 0) or Vector3.new(0, 5.8, 0)
	statsBillboard.AlwaysOnTop = true
	statsBillboard.ResetOnSpawn = false
	statsBillboard.Enabled = false -- awalnya hidden
	statsBillboard.Parent = targetParent

	local qteRow = Instance.new("Frame")
	qteRow.Name = "QteStatsRow"
	qteRow.BackgroundTransparency = 1
	qteRow.Size = UDim2.fromScale(1, 1)
	qteRow.Parent = statsBillboard

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 5)
	rowLayout.Parent = qteRow

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(36, 36)
	icon.Image = "rbxassetid://117288549634340"
	icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.LayoutOrder = 2
	icon.Parent = qteRow

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.BackgroundTransparency = 1
	valueLabel.Size = UDim2.fromOffset(0, 36)
	valueLabel.AutomaticSize = Enum.AutomaticSize.X
	valueLabel.Text = "0"
	valueLabel.TextScaled = false
	valueLabel.TextSize = 34
	valueLabel.FontFace = UBUNTU_BOLD
	valueLabel.TextColor3 = COLOR_STAT
	valueLabel.TextStrokeTransparency = 0.15
	valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.LayoutOrder = 1
	valueLabel.Parent = qteRow

	cachedStatsBillboards[slotNumber] = statsBillboard
	return statsBillboard
end

function PlayerBillboardFactory.SetActive(actorModel, slotNumber, isActive, actionName, statValue)
	-- Pastikan billboard nama tetap hidup
	local nameBillboard = GetOrCreateNameBillboard(actorModel, slotNumber)
	if nameBillboard then
		nameBillboard.Enabled = true
	end
	
	local statsBillboard = GetOrCreateStatsBillboard(actorModel, slotNumber)
	if not statsBillboard then return end

	statsBillboard.Enabled = isActive == true

	if not isActive then return end

	local qteRow = statsBillboard:FindFirstChild("QteStatsRow")
	if qteRow then
		local icon = qteRow:FindFirstChild("Icon")
		local valueLabel = qteRow:FindFirstChild("Value")

		if icon then
			icon.Image = ResolveIconForAction(actionName)
			icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
		if valueLabel then
			valueLabel.Text = formatnumber(tonumber(statValue) or 0)
			valueLabel.TextColor3 = COLOR_STAT
		end
	end
end

function PlayerBillboardFactory.SetResolvedValue(actorModel, slotNumber, finalVal)
	local statsBillboard = GetOrCreateStatsBillboard(actorModel, slotNumber)
	if not statsBillboard then return end
	
	local qteRow = statsBillboard:FindFirstChild("QteStatsRow")
	if qteRow then
		local valueLabel = qteRow:FindFirstChild("Value")
		if valueLabel then
			if finalVal then
				valueLabel.Text = formatnumber(tonumber(finalVal) or 0)
			end
			valueLabel.TextColor3 = COLOR_STAT
		end
	end
end

function PlayerBillboardFactory.Hide(actorModel, slotNumber)
	-- Sembunyikan stats QTE saja, billboard nama tetap hidup
	local statsBillboard = GetOrCreateStatsBillboard(actorModel, slotNumber)
	if statsBillboard then
		statsBillboard.Enabled = false
	end
end

function PlayerBillboardFactory.EnsureBillboard(actorModel, slotNumber)
	-- Terus-menerus mengupdate Adornee untuk Name dan Stats billboard
	local root = actorModel:FindFirstChild("HumanoidRootPart") or actorModel.PrimaryPart or actorModel:FindFirstChildWhichIsA("BasePart", true)
	
	local nameBillboard = GetOrCreateNameBillboard(actorModel, slotNumber)
	if nameBillboard then
		nameBillboard.Enabled = true
		if root and nameBillboard.Adornee ~= root then
			nameBillboard.Adornee = root
		end
	end
	
	local statsBillboard = GetOrCreateStatsBillboard(actorModel, slotNumber)
	if statsBillboard then
		if root and statsBillboard.Adornee ~= root then
			statsBillboard.Adornee = root
		end
	end
end

function PlayerBillboardFactory.Cleanup()
	for _, bb in pairs(cachedBillboards) do
		if bb then bb:Destroy() end
	end
	table.clear(cachedBillboards)
	
	for _, bb in pairs(cachedStatsBillboards) do
		if bb then bb:Destroy() end
	end
	table.clear(cachedStatsBillboards)
end

return PlayerBillboardFactory
