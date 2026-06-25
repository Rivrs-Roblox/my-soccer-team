--[=[
	Owner: Vooldy
	Version: v.0.0.
	Contact owner if any question, concern or feedback
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

-- Modules
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIHighlighter = require(StarterPlayer.StarterPlayerScripts.Client.Modules.UIHighlighter)
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

-- Controllers
local DataCacheController
local NotificationController
local FtueMatchTriggerController
local MatchController

-- Services
local DataService
local MatchService
local PlayerStatsService
local CoachesService
local GachaService
local TeamService
local AccessoryService

-- Cache
local TutorialGUI
local TutorialFrame
local TutorialText
local CountText
local SkipButton

-- Variables
local currentTutorialStep = 0
local CurrentTutorialTarget
local tutorialArrowCount = 0
local tutorialArrows = {} --[id::string = {Part::Instance,CurrentOffset::number}]
local trove = Trove.new()
local blockTutorial = false
local isAdvancing = false

-- Consts

--| Tutorial Controller |--
local TutorialController = Knit.CreateController({
	Name = "TutorialController",
})

--| Function |--

-- Skip the current task, the boolean flag disable the success feedback
function TutorialController:_SkipTutorial()
	self:TutorialNextStep(true)
end

-- Create a tutorial frame then cache all useful components
function TutorialController:CreateTutorialFrame(visible: true)
	local PlayerGui = player:WaitForChild("PlayerGui")
	TutorialGUI = Instance.new("ScreenGui")
	TutorialGUI.Parent = PlayerGui
	TutorialGUI.Name = "feedbackGui"
	TutorialGUI.DisplayOrder = 1
	TutorialGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
	TutorialGUI.IgnoreGuiInset = true
	trove:Add(TutorialGUI)

	local GUIFolder = ReplicatedStorage.Assets.GUIs
	TutorialFrame = GUIFolder:FindFirstChild("TutorialFrame")
	if visible then
		TutorialFrame.Position = self.Config.IN_FRAME_POS
	else
		TutorialFrame.Position = self.Config.OUT_FRAME_POS
	end
	TutorialFrame.Parent = TutorialGUI

	TutorialText = TutorialFrame:FindFirstChild("TutorialText")
	TutorialText.Text = self.Template.Tutorial[currentTutorialStep].Text

	CountText = TutorialFrame:FindFirstChild("CountText")

	if self.Template.Tutorial[currentTutorialStep].Target > 0 then
		if currentTutorialStep == 3 then
			DataService:GetData(player):andThen(function(playerData)
				CountText.Text = playerData.Stats.Stamina .. "/" .. self.Template.Tutorial[currentTutorialStep].Target
			end)
		elseif currentTutorialStep == 4 then
			DataService:GetData(player):andThen(function(playerData)
				CountText.Text = playerData.Stats.Shoot .. "/" .. self.Template.Tutorial[currentTutorialStep].Target
			end)
		elseif currentTutorialStep == 5 then
			DataService:GetData(player):andThen(function(playerData)
				CountText.Text = playerData.Stats.Pass .. "/" .. self.Template.Tutorial[currentTutorialStep].Target
			end)
		elseif currentTutorialStep == 6 then
			DataService:GetData(player):andThen(function(playerData)
				CountText.Text = playerData.Stats.Dribble .. "/" .. self.Template.Tutorial[currentTutorialStep].Target
			end)
		else
			CountText.Text = "0/" .. self.Template.Tutorial[currentTutorialStep].Target
		end
	else
		CountText.Visible = false
	end

	local ButtonFrame = TutorialFrame:FindFirstChild("ButtonFrame")
	SkipButton = ButtonFrame:FindFirstChild("TextButton")
	SkipButton.Activated:Connect(function()
		self:_SkipTutorial()
	end)
end

-- Continuously spawn tutorial arrows and store them in a library
function TutorialController:CreateTutorialArrows()
	while task.wait(self.Config.ARROW_SPAWN_RATE) do
		if currentTutorialStep > #self.Template.Tutorial then
			break
		end

		if not blockTutorial and CurrentTutorialTarget then
			local MeshFolder = ReplicatedStorage.Assets.Mesh
			local ArrowPart = MeshFolder:FindFirstChild("Arrow"):Clone()
			trove:Add(ArrowPart)

			local arrowId = tostring(tutorialArrowCount)
			tutorialArrowCount += 1

			local humanoidRootPart = player.Character.HumanoidRootPart
			ArrowPart.Parent = humanoidRootPart
			ArrowPart.CFrame = CFrame.new(humanoidRootPart.CFrame.Position)
			-- tween in
			local tween = self:TweenPart(ArrowPart, Vector3.new(0, 0, 0), Vector3.new(4, 0.1, 4))
			trove:Add(tween)
			tween:Play()
			-- store the arrow
			tutorialArrows[arrowId] = {}
			tutorialArrows[arrowId].Part = ArrowPart -- string dictionnary to avoid list increment issue
			tutorialArrows[arrowId].CurrentOffset = 0
			task.delay(self.Config.ARROW_LIFETIME - self.Config.ARROW_TWEEN_TIME, function() -- tween out
				local tween = self:TweenPart(ArrowPart, Vector3.new(4, 0.1, 4), Vector3.new(0, 0, 0))
				trove:Add(tween)
				tween:Play()
			end)
			-- self-destruct
			task.delay(self.Config.ARROW_LIFETIME, function()
				tutorialArrows[arrowId] = nil
				ArrowPart:Destroy()
			end)
		end
	end
end

-- return a tween from StartSize to EndSize
function TutorialController:TweenPart(part: Instance, startSize: Vector3, endSize: Vector3)
	part.Size = startSize
	local tweenGoal = { Size = endSize }
	local tweenInfo = TweenInfo.new(self.Config.ARROW_TWEEN_TIME, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(part, tweenInfo, tweenGoal)
	return tween
end

-- Clear all existing arrows
function TutorialController:ClearArrows()
	for index, arrowTable in tutorialArrows do
		if arrowTable.Part then
			arrowTable.Part:Destroy()
		end
	end
	table.clear(tutorialArrows)
	tutorialArrowCount = 0
end

-- Update arrow Pos Cframe at renderStep.
function TutorialController:UpdateArrowsPos()
	trove:Add(RunService.RenderStepped:Connect(function(deltaTime)
		if player.Character ~= nil and CurrentTutorialTarget ~= nil then
			local humanoidRootPart = player.Character.HumanoidRootPart -- will later be stepped outside heartbeat

			local playerToTargetDistance = (CurrentTutorialTarget.Position - humanoidRootPart.Position).Magnitude

			if MatchController:IsPlayingMatch() or playerToTargetDistance < 15 then
				blockTutorial = true
			else
				blockTutorial = false
			end

			for index, arrowTable in tutorialArrows do
				arrowTable.CurrentOffset += self.Config.ARROW_SPEED * deltaTime -- add local offset
				if humanoidRootPart and CurrentTutorialTarget then
					local startCFrame =
						CFrame.new(humanoidRootPart.CFrame.Position, CurrentTutorialTarget.CFrame.Position)
					local LookVector = startCFrame.LookVector
					arrowTable.Part.CFrame = CFrame.new(
						startCFrame.Position + LookVector * arrowTable.CurrentOffset,
						CurrentTutorialTarget.CFrame.Position
					)
					-- Distance check to remove arrow if reached target
					local arrowDistance = (arrowTable.Part.CFrame.Position - humanoidRootPart.CFrame.Position).Magnitude
					local targetDistance = (CurrentTutorialTarget.CFrame.Position - humanoidRootPart.CFrame.Position).Magnitude
					if arrowDistance > targetDistance then
						tutorialArrows[index] = nil
						arrowTable.Part:Destroy()
					end
				elseif humanoidRootPart then -- if no actual target
					arrowTable.Part.CFrame = CFrame.new(Vector3.new(0, 0, 0))
				end
			end
		end
	end))
end

-- Set a new tutorial target for the arrows
function TutorialController:UpdateTutorialTarget()
	if self.Template.Tutorial[currentTutorialStep].ArrowTarget == nil then
		CurrentTutorialTarget = nil
		self:ClearArrows()
		return
	end
	local success, warnMessage = pcall(function()
		CurrentTutorialTarget = self.Template.Tutorial[currentTutorialStep].ArrowTarget()
	end)
	if not success then
		warn("Tutorial target not found : " .. warnMessage)
		CurrentTutorialTarget = nil
	end

	if CurrentTutorialTarget == nil then
		self:ClearArrows()
	end
end

-- return a tween from start pos to end pos
function TutorialController:TweenFrame(frame: Frame, startPos: UDim2, endPos: UDim2)
	frame.Position = startPos
	local tweenGoal = { Position = endPos }
	local tweenInfo = TweenInfo.new(self.Config.ARROW_TWEEN_TIME, Enum.EasingStyle.Sine)
	local tween = TweenService:Create(frame, tweenInfo, tweenGoal)
	return tween
end

-- Start a loop to check the next tutorial condition, then tween the frame in if met
function TutorialController:KeepCheckingCondition()
	local success, warnMessage = pcall(function()
		while self.Template.Tutorial[currentTutorialStep].Condition() == false do
			task.wait(self.Config.CHECK_REFRESH_TIME)
		end
	end)
	if not success then
		print("Error while performing tutorial condition check : " .. warnMessage)
	end
	self:TweenFrameIn()
end

-- Tween the frame out, change the text, then check the tutorial condition. Tween back the frame if no condition.
function TutorialController:TweenFrameOut()
	local tween = self:TweenFrame(TutorialFrame, self.Config.IN_FRAME_POS, self.Config.OUT_FRAME_POS)
	trove:Add(tween)
	tween:Play()
	tween.Completed:Connect(function()
		TutorialText.Text = self.Template.Tutorial[currentTutorialStep].Text

		if self.Template.Tutorial[currentTutorialStep].Target == 0 then
			CountText.Visible = false
		else
			if currentTutorialStep == 3 then
				DataService:GetData(player):andThen(function(playerData)
					CountText.Text = playerData.Stats.Stamina
						.. "/"
						.. self.Template.Tutorial[currentTutorialStep].Target
				end)
			elseif currentTutorialStep == 4 then
				DataService:GetData(player):andThen(function(playerData)
					CountText.Text = playerData.Stats.Shoot .. "/" .. self.Template.Tutorial[currentTutorialStep].Target
				end)
			elseif currentTutorialStep == 5 then
				DataService:GetData(player):andThen(function(playerData)
					CountText.Text = playerData.Stats.Pass .. "/" .. self.Template.Tutorial[currentTutorialStep].Target
				end)
			elseif currentTutorialStep == 6 then
				DataService:GetData(player):andThen(function(playerData)
					CountText.Text = playerData.Stats.Dribble
						.. "/"
						.. self.Template.Tutorial[currentTutorialStep].Target
				end)
			else
				CountText.Text = "0/" .. self.Template.Tutorial[currentTutorialStep].Target
			end

			CountText.Visible = true
		end

		if
			self.Template.Tutorial[currentTutorialStep].Condition
			and self.Template.Tutorial[currentTutorialStep].Condition() == false
		then -- If condition not
			CurrentTutorialTarget = nil
			self:ClearArrows()
			task.defer(function()
				self:KeepCheckingCondition()
			end)
		else -- Else continue
			self:TweenFrameIn()
		end
	end)
end

-- Tween the frame back in visible range.
function TutorialController:TweenFrameIn()
	local tween = self:TweenFrame(TutorialFrame, self.Config.OUT_FRAME_POS, self.Config.IN_FRAME_POS)
	self:UpdateTutorialTarget()
	tween:Play()
	isAdvancing = false
end

function TutorialController:UpdateUIHighlight()
	UIHighlighter.StopAll()

	if currentTutorialStep == 2 then
		local coachesButton = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("HUD")
			:WaitForChild("LeftFrame")
			:WaitForChild("Main")
			:WaitForChild("CoachesBtn")
		local coachTargetCard = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("Customize")
			:WaitForChild("Popup")
			:WaitForChild("Coaches")
			:WaitForChild("Scroll")
			:WaitForChild("3")

		task.spawn(function()
			while currentTutorialStep == 2 do
				local currentUI = Store:getState().UIReducer.CurrentUI
				local currentCustomizeUI = Store:getState().UIReducer.CurrentCustomizeUI

				if currentUI == nil or currentUI == "" then
					UIHighlighter.Stop(coachTargetCard)
					UIHighlighter.Highlight(coachesButton)
				elseif currentUI == FramesConstants.Customize and currentCustomizeUI == CustomizeConstants.Coaches then
					UIHighlighter.Stop(coachesButton)
					UIHighlighter.Highlight(coachTargetCard)
				end

				task.wait(0.1) -- Jeda loop agar tidak terjadi script exhaustion
			end

			UIHighlighter.StopAll()
		end)
	elseif currentTutorialStep == 8 then
		local packButton = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("HUD")
			:WaitForChild("LeftFrame")
			:WaitForChild("Main")
			:WaitForChild("PacksBtn")
		local packTargetCard = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("Packs")
			:WaitForChild("Popup")
			:WaitForChild("PlayerPacks")
			:WaitForChild("Scroll")
			:WaitForChild("Beginner")
			:WaitForChild("1")

		task.spawn(function()
			while currentTutorialStep == 8 do
				local currentUI = Store:getState().UIReducer.CurrentUI

				if currentUI == nil or currentUI == "" then
					UIHighlighter.Stop(packTargetCard)
					UIHighlighter.Highlight(packButton)
				elseif currentUI == FramesConstants.Packs then
					UIHighlighter.Stop(packButton)
					UIHighlighter.Highlight(packTargetCard)
				end

				task.wait(0.1) -- Jeda loop agar tidak terjadi script exhaustion
			end

			UIHighlighter.StopAll()
		end)
	elseif currentTutorialStep == 9 then
		local teamButton = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("HUD")
			:WaitForChild("LeftFrame")
			:WaitForChild("Main")
			:WaitForChild("TeamBtn")
		local equipBestButton = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("Customize")
			:WaitForChild("Popup")
			:WaitForChild("Teams")
			:WaitForChild("Players")
			:WaitForChild("EquipBest")

		task.spawn(function()
			while currentTutorialStep == 9 do
				local currentUI = Store:getState().UIReducer.CurrentUI
				local currentCustomizeUI = Store:getState().UIReducer.CurrentCustomizeUI

				if currentUI == nil or currentUI == "" then
					UIHighlighter.Stop(equipBestButton)
					UIHighlighter.Highlight(teamButton)
				elseif currentUI == FramesConstants.Customize and currentCustomizeUI == CustomizeConstants.Teams then
					UIHighlighter.Stop(teamButton)
					UIHighlighter.Highlight(equipBestButton)
				end

				task.wait(0.1) -- Jeda loop agar tidak terjadi script exhaustion
			end

			UIHighlighter.StopAll()
		end)
	elseif currentTutorialStep == 11 then
		local accessoriesButton = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("HUD")
			:WaitForChild("LeftFrame")
			:WaitForChild("Main")
			:WaitForChild("AccessoriesBtn")
		local equipBestButton = playerGui
			:WaitForChild("GameScreenGui")
			:WaitForChild("Customize")
			:WaitForChild("Popup")
			:WaitForChild("Accessories")
			:WaitForChild("Center")
			:WaitForChild("Wardrobe")
			:WaitForChild("Bottom")
			:WaitForChild("EquipBest")

		task.spawn(function()
			while currentTutorialStep == 11 do
				local currentUI = Store:getState().UIReducer.CurrentUI
				local currentCustomizeUI = Store:getState().UIReducer.CurrentCustomizeUI

				if currentUI == nil or currentUI == "" then
					UIHighlighter.Stop(equipBestButton)
					UIHighlighter.Highlight(accessoriesButton)
				elseif
					currentUI == FramesConstants.Customize and currentCustomizeUI == CustomizeConstants.Accessories
				then
					UIHighlighter.Stop(accessoriesButton)
					UIHighlighter.Highlight(equipBestButton)
				end

				task.wait(0.1) -- Jeda loop agar tidak terjadi script exhaustion
			end

			UIHighlighter.StopAll()
		end)
	end
end

-- Skip to the next tutorial step, and end it if last step. Feedback Success prompt can be disable by input.
function TutorialController:TutorialNextStep(skipped: boolean)
	if isAdvancing then
		return
	end
	isAdvancing = true

	currentTutorialStep += 1
	DataService:TutorialProgressed(currentTutorialStep)

	if currentTutorialStep == 10 then
		DataService:GetData(player):andThen(function(playerData)
			if table.find(playerData.Areas.Unlocked, "Area02") then
				isAdvancing = false
				self:TutorialNextStep(true)
			end
		end)
	end

	if currentTutorialStep == #self.Template.Tutorial + 1 then -- If tutorial ended
		if not skipped then
			NotificationController:Notify({
				text = "You finished the tutorial! Train your team, win the finals, and continue to the next league!",
				type = "SUCCESS",
				tag = "Tutorial",
			})
		end
		self:EndTutorial()
		return
	end
	if not skipped then
		NotificationController:Notify({ text = "You completed a tutorial step!", type = "SUCCESS", tag = "Tutorial" })
	end

	self:TweenFrameOut()
	self:UpdateUIHighlight()
end

-- End the tutorial by setting the last step and cleaning everything
function TutorialController:EndTutorial()
	DataService:TutorialFinished(true)
	trove:Destroy()
	self:ClearArrows()
end

function TutorialController:StartFirstMatch()
	local queued, reason = FtueMatchTriggerController:TriggerWhenReady({
		RequiredTutorialStep = 1,
		RequireTutorialIncomplete = true,
		Debug = false,
	})

	if not queued then
		warn("[TutorialController] Failed to queue FTUE match:", reason)
	end
end

--| Knit Startup |--
function TutorialController:KnitInit()
	DataService = Knit.GetService("DataService")
	MatchService = Knit.GetService("MatchService")
	PlayerStatsService = Knit.GetService("PlayerStatsService")
	CoachesService = Knit.GetService("CoachesService")
	GachaService = Knit.GetService("GachaService")
	TeamService = Knit.GetService("TeamService")
	AccessoryService = Knit.GetService("AccessoryService")

	DataCacheController = Knit.GetController("DataCacheController")
	NotificationController = Knit.GetController("NotificationController")
	FtueMatchTriggerController = Knit.GetController("FtueMatchTriggerController")
	MatchController = Knit.GetController("MatchController")

	self.Template = DataCacheController:GetFile("Template")
	self.Config = DataCacheController:GetFile("TutorialConfig")
end

function TutorialController:KnitStart()
	DataService:GetData(player):andThen(function(playerData)
		if not playerData.TutorialComplete then
			currentTutorialStep = playerData.TutorialStep

			self:UpdateUIHighlight()
			local success, warnMessage = pcall(function()
				-- Creating, caching and updating arrows
				task.defer(function()
					self:CreateTutorialArrows()
				end)
				self:UpdateArrowsPos()
				if -- IF REQUIRE A CONDITION
					self.Template.Tutorial[currentTutorialStep].Condition
					and self.Template.Tutorial[currentTutorialStep].Condition() == false
				then
					self:CreateTutorialFrame(false)
					CurrentTutorialTarget = nil
					self:ClearArrows()
					task.defer(function()
						self:KeepCheckingCondition()
					end)
				else -- ELSE NO CONDITION
					self:CreateTutorialFrame(true)
					self:UpdateTutorialTarget()
				end
			end)
			if not success then
				warn("Error while tutorial loading : " .. warnMessage)
			end

			if currentTutorialStep == 1 then
				self:StartFirstMatch()
			end

			MatchService.MatchSessionEnded:Connect(function(reason, sessionId)
				if currentTutorialStep == 1 or currentTutorialStep == 7 then
					self:TutorialNextStep(false)
				end
			end)

			CoachesService.CoachBought:Connect(function(id)
				if currentTutorialStep == 2 and id == 3 then
					self:TutorialNextStep(false)
				end
			end)

			PlayerStatsService.StatUpdated:Connect(function(stat, value)
				if currentTutorialStep == 3 and stat == "Stamina" then
					local formatedValue = FormatNumber(value)
					CountText.Text = formatedValue .. "/" .. self.Template.Tutorial[currentTutorialStep].Target

					if value >= self.Template.Tutorial[currentTutorialStep].Target then
						self:TutorialNextStep(false)
					end
				elseif currentTutorialStep == 4 and stat == "Shoot" then
					local formatedValue = FormatNumber(value)
					CountText.Text = formatedValue .. "/" .. self.Template.Tutorial[currentTutorialStep].Target

					if value >= self.Template.Tutorial[currentTutorialStep].Target then
						self:TutorialNextStep(false)
					end
				elseif currentTutorialStep == 5 and stat == "Pass" then
					local formatedValue = FormatNumber(value)
					CountText.Text = formatedValue .. "/" .. self.Template.Tutorial[currentTutorialStep].Target

					if value >= self.Template.Tutorial[currentTutorialStep].Target then
						self:TutorialNextStep(false)
					end
				elseif currentTutorialStep == 6 and stat == "Dribble" then
					local formatedValue = FormatNumber(value)
					CountText.Text = formatedValue .. "/" .. self.Template.Tutorial[currentTutorialStep].Target

					if value >= self.Template.Tutorial[currentTutorialStep].Target then
						self:TutorialNextStep(false)
					end
				end
			end)

			GachaService.GachaOpened:Connect(function(items, type, category)
				if currentTutorialStep == 8 and category == "SoccerCharacters" then
					self:TutorialNextStep(false)
				elseif currentTutorialStep == 10 and category == "Accessories" then
					self:TutorialNextStep(false)
				end
			end)

			TeamService.TeamSlotSet:Connect(function(equippedSlots)
				if currentTutorialStep == 9 then
					self:TutorialNextStep(false)
				end
			end)

			AccessoryService.AccessoriesUpdated:Connect(function()
				if currentTutorialStep == 11 then
					self:TutorialNextStep(false)
				end
			end)
		end
	end)
end

return TutorialController
