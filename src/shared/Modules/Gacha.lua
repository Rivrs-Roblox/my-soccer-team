local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Knit
local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Knit Controller
local UIController
local DataCacheController

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local TweenBlur = require(Helpers.TweenBlur)
local CallUntilSuccess = require(Helpers.CallUntilSuccess)
local AddOutline = require(Helpers.AddOutline)
local CameraShaker = require(Helpers.Camera)

-- Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local skipGachaGui = playerGui:WaitForChild("SkipGachaGui")
local skipInfoText = skipGachaGui:WaitForChild("InfoText")
local accessoriesGui = playerGui:WaitForChild("Accessories")

-- Assets
local CardPack = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CardPack")
local Card = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Card")
local CurrentCamera = Workspace.CurrentCamera

local Gacha = {}
local CardSettings = require(ReplicatedStorage.Shared.Data.CardSettings)
local GachaConfig = require(ReplicatedStorage.Shared.Data.GachaConfig)
local EmitterModule = require(ReplicatedStorage.Shared.Modules.UI_EmitterModule)

local Template
local GachaTemplate
local CategoryTemplate
local UI
local Colors

function Gacha.SkipActive()
	local session = Gacha._activeSession
	if not session then
		return false
	end

	if session.State == "WaitingOpenFx" or session.State == "WaitingSlideRight" then
		session.NextStep:Fire()
		return true
	elseif session.State == "SlidingRight" then
		if session.AnimationThread then
			task.cancel(session.AnimationThread)
		end
		session.Completed:Fire()
		return true
	end

	if not session.SkipRequested then
		session.SkipRequested = true
		if session.AnimationThread then
			task.cancel(session.AnimationThread)
		end
		session.SkipEvent:Fire()
	end

	return true
end

function Gacha.Open(items, type, category)
	category = category or "SoccerCharacters" -- Fallback to legacy behavior

	CategoryTemplate = Template[category]

	skipGachaGui.Enabled = true

	TweenBlur(GachaConfig.General.InitialBlur.Intensity, GachaConfig.General.InitialBlur.Duration)

	CallUntilSuccess(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)

	UserInputService.MouseIconEnabled = false
	UIController:RemoveHUD({ ignoreTopFrame = false })
	UIController:JustHideFrame()

	local PackModel
	local RewardsFolder
	local RenderStepName = "CardPackRender" .. os.clock()
	local RewardStepName = "CardRewardRender" .. os.clock()
	local camShake
	local BlurredBackground
	local activeCards = {}
	local currentShakeOffset = CFrame.new()

	local completed = Instance.new("BindableEvent")
	local nextStep = Instance.new("BindableEvent")
	local skipEvent = Instance.new("BindableEvent")

	local activeSession = {
		Completed = completed,
		AnimationThread = nil,
		SkipRequested = false,
		State = "Animating",
		NextStep = nextStep,
		SkipEvent = skipEvent,
	}
	Gacha._activeSession = activeSession
	skipInfoText.Text = "Click anywhere to skip"

	local function ShowFinalCards()
		if PackModel then PackModel:Destroy() end
		RunService:UnbindFromRenderStep(RenderStepName)

		if not RewardsFolder then
			RewardsFolder = Instance.new("Folder")
			RewardsFolder.Name = "GachaRewards"
			RewardsFolder.Parent = CurrentCamera
		else
			RewardsFolder:ClearAllChildren()
		end

		activeCards = {}

		local countKey = if CardSettings.Placements[#items] then #items else (if #items > 5 then 10 else (if #items > 1 then 5 else 1))
		local placements = CardSettings.Placements[countKey]
		local sizes = CardSettings.Sizes[countKey]
		local baseRotation = CFrame.Angles(0, math.rad(180), 0)

		for i, item in ipairs(items) do
			local card = Card:Clone()
			for _, v in ipairs(card:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = true
					v.CanCollide = false
				end
			end
			card.Parent = RewardsFolder

			local offset = placements[i] or Vector3.new(0, 0, 0)
			local size = sizes[i] or Vector3.new(1, 1, 1)

			for _, v in ipairs(card:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Size *= (size.Y / 3)
				end
			end

			local CardOffsetValue = Instance.new("CFrameValue", card)
			local zPos = GachaConfig.Characters.Cards.RevealBounce.ZoomOutZ + offset.Z
			CardOffsetValue.Value = CFrame.new(offset.X, offset.Y, zPos) * baseRotation

			table.insert(activeCards, { Card = card, Value = CardOffsetValue })

			local realItemData = CategoryTemplate[item]
			if realItemData then
				local name = realItemData.Name
				local shoot = realItemData.Multipliers.Shoot
				local dribble = realItemData.Multipliers.Dribble
				local pass = realItemData.Multipliers.Pass
				local rarity = realItemData.Rarity

				card:FindFirstChild("Name", true).Text = name
				card:FindFirstChild("Dribble", true).Number.Text = dribble or 0
				card:FindFirstChild("Shooting", true).Number.Text = shoot or 0
				card:FindFirstChild("Passing", true).Number.Text = pass or 0

				card:FindFirstChild("CardImage", true).Image = UI["Card_" .. string.gsub(rarity, " ", "_")]
				card:FindFirstChild("CardMaskImage", true).Image = UI["Card_" .. string.gsub(rarity, " ", "_") .. "_Mask"]
				card:FindFirstChild("CharacterImage", true).Image = UI[name]

				local rarityFxs = card:FindFirstChild(rarity, true)
				if rarityFxs then
					for _, desc in ipairs(rarityFxs:GetDescendants()) do
						if desc:IsA("ParticleEmitter") then
							desc.Enabled = true

							if desc.Parent.Name == "RevealFx" then
								task.delay(0.5, function()
									desc.Enabled = false
								end)
							end
						end
					end
				end
			end
		end

		RunService:BindToRenderStep(RewardStepName, Enum.RenderPriority.Last.Value, function()
			local baseCameraCF = CurrentCamera.CFrame
			CurrentCamera.CFrame = baseCameraCF * currentShakeOffset
			for _, data in ipairs(activeCards) do
				if data.Card and data.Value then
					data.Card:PivotTo(baseCameraCF * data.Value.Value)
				end
			end
		end)
	end

	local function SlideCardsRightAndComplete()
		activeSession.State = "SlidingRight"
		local exitTweenInfo = TweenInfo.new(
			GachaConfig.Characters.Cards.Exit.Duration,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.In
		)
		for _, data in ipairs(activeCards) do
			if data.Card and data.Value then
				local currentCF = data.Value.Value
				local exitCF = CFrame.new(currentCF.Position + GachaConfig.Characters.Cards.Exit.Offset)
					* CFrame.Angles(0, math.rad(180), 0)
				TweenService:Create(data.Value, exitTweenInfo, { Value = exitCF }):Play()
			end
		end
		task.wait(GachaConfig.Characters.Cards.Exit.Duration)
	end

	skipEvent.Event:Connect(function()
		if category == "SoccerCharacters" then
			ShowFinalCards()
			activeSession.State = "WaitingSlideRight"
			skipInfoText.Text = "Click anywhere to continue"
			nextStep.Event:Wait()
			SlideCardsRightAndComplete()
			completed:Fire()
		else
			completed:Fire()
		end
	end)

	local animationThread = task.spawn(function()
		if category == "SoccerCharacters" then
			PackModel = CardPack:Clone()

			for k, j in PackModel:GetDescendants() do
				if j:IsA("BasePart") then
					j.Anchored = true
					j.CanCollide = false
				end
			end

			AddOutline(PackModel)
			PackModel.Parent = CurrentCamera

			local packBottom = PackModel:FindFirstChild("Bottom", true)
			local packFull = PackModel:FindFirstChild("Full", true)
			local packTop = PackModel:FindFirstChild("Top", true)

			-- Apply pack images based on type and category
			if type and GachaTemplate and GachaTemplate[category] then
				local packData = GachaTemplate[category][tostring(type)]
				if packData then
					local packKey = string.gsub(string.gsub(packData.Name, " ", "_"), "-", "_")
					if packBottom and UI then
						packBottom.Image = UI[packKey .. "_Bottom"] or ""
					end
					if packFull and UI then
						packFull.Image = UI[packKey .. "_Full"] or ""
					end
					if packTop and UI then
						packTop.Image = UI[packKey .. "_Top"] or ""
					end
				end
			end

			BlurredBackground = Instance.new("DepthOfFieldEffect")
			BlurredBackground.FarIntensity = 0
			BlurredBackground.Parent = Lighting

			local BlurredBackgroundTween1 = TweenService:Create(
				BlurredBackground,
				TweenInfo.new(GachaConfig.Characters.DepthOfField.Duration, Enum.EasingStyle.Quint),
				{ FarIntensity = GachaConfig.Characters.DepthOfField.Intensity }
			)
			BlurredBackgroundTween1:Play()
			BlurredBackgroundTween1.Completed:Connect(function()
				BlurredBackgroundTween1:Destroy()
			end)

			local PositionValue = Instance.new("CFrameValue", PackModel)
			PositionValue.Name = "PositionValue"
			PositionValue.Value = GachaConfig.Characters.Pack.Spawn.Position

			local RotationValue = Instance.new("CFrameValue", PackModel)
			RotationValue.Name = "RotationValue"
			RotationValue.Value = GachaConfig.Characters.Pack.Spawn.Rotation

			local top
			for _, v in ipairs(PackModel:GetDescendants()) do
				if v:IsA("ImageLabel") and v.Name == "Top" then
					top = v
					break
				end
			end

			local cardPivot = PackModel:FindFirstChild("CardPivot", true)
			local cardPivotInitialRelative = if cardPivot
				then PackModel:GetPivot():Inverse() * cardPivot.CFrame
				else nil
			local CardOffsetValue = Instance.new("CFrameValue", PackModel)
			CardOffsetValue.Value = CFrame.new()

			local packPivot = PackModel:FindFirstChild("PackPivot", true)
			local packPivotInitialRelative = if packPivot
				then PackModel:GetPivot():Inverse() * packPivot.CFrame
				else nil
			local PackOffsetValue = Instance.new("CFrameValue", PackModel)
			PackOffsetValue.Value = CFrame.new()

			RunService:BindToRenderStep(RenderStepName, Enum.RenderPriority.Last.Value, function()
				local cameraCF = CurrentCamera.CFrame
				local offsetCF = PositionValue.Value * RotationValue.Value
				local currentPivot = cameraCF * offsetCF
				PackModel:PivotTo(currentPivot)

				if cardPivot and cardPivotInitialRelative then
					cardPivot.CFrame = currentPivot * cardPivotInitialRelative * CardOffsetValue.Value
				end

				if packPivot and packPivotInitialRelative then
					packPivot.CFrame = currentPivot * packPivotInitialRelative * PackOffsetValue.Value
				end
			end)

			Sound:PlaySound("Slide_In")

			-- Move up
			local PositionTween1 = TweenService:Create(
				PositionValue,
				TweenInfo.new(
					GachaConfig.Characters.Pack.Reveal.Duration,
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				),
				{ Value = GachaConfig.Characters.Pack.Reveal.Position }
			)
			PositionTween1:Play()

			PositionTween1.Completed:Wait()

			activeSession.State = "WaitingOpenFx"
			skipInfoText.Text = "Click anywhere to open"
			nextStep.Event:Wait()
			activeSession.State = "Animating"
			skipInfoText.Text = "Click anywhere to skip"

			local openFxs = PackModel:FindFirstChild("OpenFx", true):GetChildren()
			local packGui = PackModel:FindFirstChild("PackGui", true)

			local gachaStorage = ReplicatedStorage:FindFirstChild("GachaFxStorage")
			if not gachaStorage then
				gachaStorage = Instance.new("Folder")
				gachaStorage.Name = "GachaFxStorage"
				gachaStorage.Parent = ReplicatedStorage
			end

			for _, fx in ipairs(openFxs) do
				if fx:IsA("ParticleEmitter") then
					fx.Parent = gachaStorage
					fx.Enabled = true
					EmitterModule:AddEmitter(fx, 1, packGui.Frame.Fx)
				end
			end

			Sound:PlaySound("Pack_Slice")

			task.wait(0.1)

			for _, fx in ipairs(openFxs) do
				if fx:IsA("ParticleEmitter") then
					fx.Enabled = false
					fx.Parent = packGui.Frame.Fx
					EmitterModule:RemoveEmitter(fx)
				end
			end

			if top then
				local TopTween = TweenService:Create(
					top,
					TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Position = UDim2.fromScale(0.6, 0.3), Rotation = 50 }
				)
				TopTween:Play()
				TopTween.Completed:Wait()
			end

			local DismissTweenInfo = TweenInfo.new(
				GachaConfig.Characters.Pack.Dismiss.Duration,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.In
			)
			local cardDismiss = TweenService:Create(
				CardOffsetValue,
				DismissTweenInfo,
				{ Value = GachaConfig.Characters.Pack.Dismiss.CardOffset }
			)
			local packDismiss = TweenService:Create(
				PackOffsetValue,
				DismissTweenInfo,
				{ Value = GachaConfig.Characters.Pack.Dismiss.PackOffset }
			)

			Sound:PlaySound("Slide_Out")

			cardDismiss:Play()
			packDismiss:Play()

			task.wait(GachaConfig.Characters.Pack.Dismiss.Duration)

			PackModel:Destroy()
			RunService:UnbindFromRenderStep(RenderStepName)

			-- Spawning cards
			local count = #items
			local countKey = if CardSettings.Placements[count]
				then count
				else (if count > 5 then 10 else (if count > 1 then 5 else 1))
			local placements = CardSettings.Placements[countKey]
			local sizes = CardSettings.Sizes[countKey]

			RewardsFolder = Instance.new("Folder")
			RewardsFolder.Name = "GachaRewards"
			RewardsFolder.Parent = CurrentCamera

			camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value + 1, function(shakeCFrame)
				currentShakeOffset = shakeCFrame
			end)
			camShake:Start()

			RunService:BindToRenderStep(RewardStepName, Enum.RenderPriority.Last.Value, function()
				local baseCameraCF = CurrentCamera.CFrame

				CurrentCamera.CFrame = baseCameraCF * currentShakeOffset

				for _, data in ipairs(activeCards) do
					if data.Card and data.Value then
						data.Card:PivotTo(baseCameraCF * data.Value.Value)
					end
				end
			end)

			for i, item in ipairs(items) do
				local card = Card:Clone()

				-- Ensure anchored and no collide
				for _, v in ipairs(card:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Anchored = true
						v.CanCollide = false
					end
				end

				card.Parent = RewardsFolder

				local offset = placements[i] or Vector3.new(0, 0, 0)
				local size = sizes[i] or Vector3.new(1, 1, 1)

				-- Apply size to all parts in card (simplified)
				for _, v in ipairs(card:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Size *= (size.Y / 3)
					end
				end

				local CardOffsetValue = Instance.new("CFrameValue", card)
				local baseRotation = CFrame.Angles(0, math.rad(180), 0)
				CardOffsetValue.Value = CFrame.new(-20, offset.Y, -8 + offset.Z) * baseRotation

				table.insert(activeCards, { Card = card, Value = CardOffsetValue })

				-- Staggered entrance
				task.delay(i * 0.1, function()
					TweenService:Create(
						CardOffsetValue,
						TweenInfo.new(
							GachaConfig.Characters.Cards.EntranceDuration,
							Enum.EasingStyle.Quint,
							Enum.EasingDirection.Out
						),
						{ Value = CFrame.new(offset.X, offset.Y, -8 + offset.Z) * baseRotation }
					):Play()
				end)
			end

			-- Wait for all cards to finish entering
			task.wait(1 + (#items * 0.1))

			-- Rolling stats sequence (sequentially for each card)
			for i, item in ipairs(items) do
				local cardData = activeCards[i]
				if not cardData then
					continue
				end

				local card = cardData.Card

				-- Determine the pool of items from the same pack
				local possibleItems = {}
				if GachaTemplate and GachaTemplate[category] then
					for _, packData in pairs(GachaTemplate[category]) do
						if table.find(packData.Items, item) then
							possibleItems = packData.Items
							break
						end
					end
				end

				-- Fallback just in case
				if #possibleItems == 0 then
					table.insert(possibleItems, item)
				end

				-- Roll for 2 seconds
				local rollDuration = GachaConfig.Characters.Cards.Roll.Duration
				local rollInterval = GachaConfig.Characters.Cards.Roll.Interval
				local elapsed = 0

				local nameText = card:FindFirstChild("Name", true)
				local dribbleText = card:FindFirstChild("Dribble", true).Number
				local shootText = card:FindFirstChild("Shooting", true).Number
				local passText = card:FindFirstChild("Passing", true).Number
				local cardImage = card:FindFirstChild("CardImage", true)
				local cardMaskImage = card:FindFirstChild("CardMaskImage", true)
				local characterImage = card:FindFirstChild("CharacterImage", true)

				local originalCF = cardData.Value.Value

				Sound:PlaySound("Card_Shuffle")
				Sound:PlaySound("Suspension")

				while elapsed < rollDuration do
					local randomItemName = possibleItems[math.random(1, #possibleItems)]
					local randomItemData = CategoryTemplate[randomItemName]

					if randomItemData then
						local name = randomItemData.Name
						local shoot, dribble, pass
						local rarity = randomItemData.Rarity

						shoot = randomItemData.Multipliers.Shoot
						dribble = randomItemData.Multipliers.Dribble
						pass = randomItemData.Multipliers.Pass

						nameText.Text = name
						dribbleText.Text = dribble or 0
						shootText.Text = shoot or 0
						passText.Text = pass or 0
						cardImage.Image = UI["Card_" .. string.gsub(rarity, " ", "_")]
						cardMaskImage.Image = UI["Card_" .. string.gsub(rarity, " ", "_") .. "_Mask"]
						characterImage.Image = UI[name]
					end

					-- Bergoyang (Shake effect)
					cardData.Value.Value = originalCF
						* CFrame.Angles(
							math.rad(math.random(-1, 1)),
							math.rad(math.random(-1, 1)),
							math.rad(math.random(-2, 2))
						)
						* CFrame.new(math.random(-10, 10) / 100, math.random(-10, 10) / 100, math.random(-6, 6) / 100)

					task.wait(rollInterval)
					elapsed += rollInterval
				end

				-- Reset posisi setelah selesai bergoyang
				cardData.Value.Value = originalCF

				-- Final (Real) Item Data
				local realItemData = CategoryTemplate[item]
				if realItemData then
					local name = realItemData.Name
					local shoot, dribble, pass
					local rarity = realItemData.Rarity

					shoot = realItemData.Multipliers.Shoot
					dribble = realItemData.Multipliers.Dribble
					pass = realItemData.Multipliers.Pass

					nameText.Text = name
					dribbleText.Text = dribble or 0
					shootText.Text = shoot or 0
					passText.Text = pass or 0

					cardImage.Image = UI["Card_" .. string.gsub(rarity, " ", "_")]
					cardMaskImage.Image = UI["Card_" .. string.gsub(rarity, " ", "_") .. "_Mask"]
					characterImage.Image = UI[name]

					if rarity == "Legendary" then
						Sound:PlaySound("Card_Reveal_Legendary")
					elseif rarity == "Gold Legendary" then
						Sound:PlaySound("Card_Reveal_Gold_Legendary")
					else
						Sound:PlaySound("Card_Reveal_Global")
					end

					local rarityFxs = card:FindFirstChild(rarity, true)
					if rarityFxs then
						for _, desc in ipairs(rarityFxs:GetDescendants()) do
							if desc:IsA("ParticleEmitter") then
								desc.Enabled = true

								if desc.Parent.Name == "RevealFx" then
									task.delay(0.5, function()
										desc.Enabled = false
									end)
								end
							end
						end
					end
				end

				-- Bounce zoom-in effect for the revealed card
				local countKey = if CardSettings.Placements[#items]
					then #items
					else (if #items > 5 then 10 else (if #items > 1 then 5 else 1))
				local offset = CardSettings.Placements[countKey][i] or Vector3.new(0, 0, 0)
				local baseRotation = CFrame.Angles(0, math.rad(180), 0)

				local popZoomIn = TweenService:Create(
					cardData.Value,
					TweenInfo.new(
						GachaConfig.Characters.Cards.RevealBounce.InDuration,
						Enum.EasingStyle.Elastic,
						Enum.EasingDirection.Out
					),
					{
						Value = CFrame.new(
							offset.X,
							offset.Y,
							GachaConfig.Characters.Cards.RevealBounce.ZoomInZ + offset.Z
						) * baseRotation,
					}
				)

				local popZoomOut = TweenService:Create(
					cardData.Value,
					TweenInfo.new(
						GachaConfig.Characters.Cards.RevealBounce.OutDuration,
						Enum.EasingStyle.Back,
						Enum.EasingDirection.Out
					),
					{
						Value = CFrame.new(
							offset.X,
							offset.Y,
							GachaConfig.Characters.Cards.RevealBounce.ZoomOutZ + offset.Z
						) * baseRotation,
					}
				)

				camShake:ShakeOnce(
					GachaConfig.Characters.Cards.Shake.Intensity,
					GachaConfig.Characters.Cards.Shake.Magnitude,
					0.1,
					GachaConfig.Characters.Cards.Shake.Duration
				)
				popZoomIn:Play()
				popZoomIn.Completed:Wait()

				popZoomOut:Play()
				popZoomOut.Completed:Wait()

				-- Optional pause after finding the real item before moving to next card
				task.wait(0.2)
			end

			-- Slide all cards to the right
			activeSession.State = "WaitingSlideRight"
			skipInfoText.Text = "Click anywhere to continue"
			nextStep.Event:Wait()
			
			SlideCardsRightAndComplete()
		elseif category == "Accessories" then
			accessoriesGui.Enabled = true

			local chestClosed = accessoriesGui:FindFirstChild("ChestClosed", true)
			local chestOpened = accessoriesGui:FindFirstChild("ChestOpen", true)
			local effect = accessoriesGui:FindFirstChild("Effect", true)
			local item = accessoriesGui:FindFirstChild("Item", true)
			local itemName = item:WaitForChild("ItemName")

			if type and GachaTemplate and GachaTemplate[category] then
				local packData = GachaTemplate[category][tostring(type)]
				if packData then
					local packKey = string.gsub(string.gsub(packData.Name, " ", "_"), "-", "_")
					if UI then
						chestClosed.Image = UI[packKey .. "_Closed"] or ""
						chestOpened.Image = UI[packKey .. "_Open"] or ""
					end
				end
			end

			-- Initial state
			chestClosed.Visible = true
			chestClosed.Size = UDim2.fromScale(0, 0)
			chestClosed.Rotation = 0
			chestOpened.Visible = false
			effect.Visible = false
			effect.Size = GachaConfig.Accessories.Effect.InitialSize
			item.Visible = false
			item.Size = GachaConfig.Accessories.Item.InitialSize

			-- Tween size to 0.7
			local tweenInfo = TweenInfo.new(
				GachaConfig.Accessories.Chest.Shake.Speed * 7,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			)
			local sizeTween =
				TweenService:Create(chestClosed, tweenInfo, { Size = GachaConfig.Accessories.Chest.InitialSize })
			sizeTween:Play()
			sizeTween.Completed:Wait()

			Sound:PlaySound("Suspension")

			-- Shake back and forth
			local shakeDuration = GachaConfig.Accessories.Chest.Shake.Duration
			local shakeSpeed = GachaConfig.Accessories.Chest.Shake.Speed
			local elapsed = 0
			while elapsed < shakeDuration do
				local targetRotation = if chestClosed.Rotation >= 0
					then -GachaConfig.Accessories.Chest.Shake.Rotation
					else GachaConfig.Accessories.Chest.Shake.Rotation
				local shakeTween = TweenService:Create(
					chestClosed,
					TweenInfo.new(shakeSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Rotation = targetRotation }
				)
				shakeTween:Play()
				shakeTween.Completed:Wait()
				elapsed += shakeSpeed
			end
			chestClosed.Rotation = 0

			-- Open Chest Reveal with Bounce Zoom
			chestClosed.Visible = false
			chestOpened.Visible = true
			chestOpened.Size = GachaConfig.Accessories.Chest.InitialSize
			effect.Visible = true

			Sound:PlaySound("Chest_Open")

			local openTween = TweenService:Create(
				chestOpened,
				TweenInfo.new(
					GachaConfig.Accessories.Chest.Shake.Speed * 5,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{ Size = GachaConfig.Accessories.Chest.ExpandedSize }
			)
			openTween:Play()
			openTween.Completed:Wait()

			TweenService:Create(
				chestOpened,
				TweenInfo.new(
					GachaConfig.Accessories.Chest.Shake.Speed * 3,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{ Size = GachaConfig.Accessories.Chest.InitialSize }
			):Play()
			-- Background effect rotation
			local effectTween = TweenService:Create(
				effect,
				TweenInfo.new(
					GachaConfig.Accessories.Effect.RotationDuration,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.InOut,
					-1
				),
				{ Rotation = 360 }
			)
			effectTween:Play()

			task.wait(GachaConfig.Accessories.Transition.WaitAfterChestOpen)

			local closeTweenInfo = TweenInfo.new(
				GachaConfig.Accessories.Transition.CloseDuration,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.In
			)
			TweenService:Create(chestOpened, closeTweenInfo, { Size = UDim2.fromScale(0, 0) }):Play()

			Sound:PlaySound("Reward")

			-- Start Item reveal AT THE SAME TIME as the chest closing
			for _, name in ipairs(items) do
				if name then
					item.Visible = true
					item.Image = UI[name] or ""
					item.Size = UDim2.fromScale(0, 0)
					itemName.Text = name
					itemName.TextColor3 = Colors[CategoryTemplate[name].Rarity]

					local popTween = TweenService:Create(
						item,
						TweenInfo.new(
							GachaConfig.Accessories.Item.RevealDuration,
							Enum.EasingStyle.Elastic,
							Enum.EasingDirection.Out
						),
						{ Size = UDim2.fromScale(1, 1) }
					)
					popTween:Play()
					popTween.Completed:Wait()

					task.wait(GachaConfig.Accessories.Item.WaitDuration)

					-- Scale down Item and Effect at the very end TOGETHER
					if _ == #items then
						effectTween:Cancel()
						TweenService:Create(item, closeTweenInfo, { Size = UDim2.fromScale(0, 0) }):Play()
						TweenService:Create(effect, closeTweenInfo, { Size = UDim2.fromScale(0, 0) }):Play()
					else
						TweenService:Create(item, closeTweenInfo, { Size = UDim2.fromScale(0, 0) }):Play()
					end

					task.wait(GachaConfig.Accessories.Transition.FinalCleanupWait)
				end
			end
		end
		completed:Fire()
	end)

	activeSession.AnimationThread = animationThread

	local skipConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Gacha.SkipActive()
		end
	end)

	completed.Event:Wait()
	if Gacha._activeSession == activeSession then
		Gacha._activeSession = nil
	end
	skipConnection:Disconnect()
	completed:Destroy()
	nextStep:Destroy()
	skipEvent:Destroy()

	-- CLEANUP
	if PackModel then
		PackModel:Destroy()
	end
	if RewardsFolder then
		RewardsFolder:Destroy()
	end
	if camShake then
		camShake:Stop()
	end
	if BlurredBackground then
		BlurredBackground:Destroy()
	end

	RunService:UnbindFromRenderStep(RenderStepName)
	RunService:UnbindFromRenderStep(RewardStepName)

	TweenBlur(0, GachaConfig.General.CleanupBlurDuration)

	skipGachaGui.Enabled = false
	accessoriesGui.Enabled = false

	UIController:ShowHUD()
	UserInputService.MouseIconEnabled = true

	CallUntilSuccess(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	end)
end

task.spawn(function()
	Knit.OnStart():andThen(function()
		UIController = Knit.GetController("UIController")
		DataCacheController = Knit.GetController("DataCacheController")

		Template = DataCacheController:GetFile("Template")
		GachaTemplate = Template.Gacha
		UI = DataCacheController:GetFile("Images")
		Colors = DataCacheController:GetFile("Colors")
	end)
end)

return Gacha
