--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local NotificationActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.NotificationActions)

-- Controllers
local DataCacheController = nil
local NotificationController = nil

-- UINotificationController
local UINotificationController = Knit.CreateController({
	Name = "UINotificationController",

	Notifications = {},
	Stored_Datas = {},

	SendNotif = false,

	-- Datas
	RebirthTable = {},
	Template = {},
})

--|| Functions ||--
function UINotificationController:InitChecks()
	task.spawn(function()
		while task.wait(2) do
			local State = Store:getState()

			local Rebirth = State["PlayerReducer"].Rebirth
			local Wins = State["PlayerReducer"].Wins
			local Money2 = State["PlayerReducer"].Money2
			local Shoot = State["PlayerReducer"].Shoot or 0
			local Pass = State["PlayerReducer"].Pass or 0
			local Dribble = State["PlayerReducer"].Dribble or 0
			local Areas = State["AreaReducer"].Areas
			local Coaches = (State["CoachReducer"] and State["CoachReducer"].Coaches) or {}

			if self.Stored_Datas["Shoot"] ~= Shoot or self.Stored_Datas["Pass"] ~= Pass or self.Stored_Datas["Dribble"] ~= Dribble or self.Stored_Datas["Rebirth"] ~= Rebirth then
				self.Stored_Datas["Shoot"] = Shoot
				self.Stored_Datas["Pass"] = Pass
				self.Stored_Datas["Dribble"] = Dribble
				self.Stored_Datas["Rebirth"] = Rebirth

				local req = self.RebirthTable[Rebirth + 1]

				if req == nil then
					if Rebirth + 1 < 2000 then
						local sizeOfArray = #self.RebirthTable
						local last = self.RebirthTable[sizeOfArray]
						local mult = math.pow(1.3, (Rebirth + 1) - sizeOfArray)
						req = { A = last.A * mult, B = last.B * mult, C = last.C * mult }
					end
				end

				if req and Shoot >= req.A and Pass >= req.B and Dribble >= req.C then
					local RebirthCount = 1

					if
						self.Notifications["Rebirth"] ~= RebirthCount
						and self.SendNotif == true
						and RebirthCount > 0
					then
						NotificationController:Notify({
							text = self.Template.Messages.Notifications.Can_Rebirth_X_Times(1),
							type = "SUCCESS",
						})
					end

					self.Notifications["Rebirth"] = RebirthCount
					Store:dispatch(NotificationActions.setNotification("Rebirth", RebirthCount))
				else
					local RebirthCount = 0

					self.Notifications["Rebirth"] = RebirthCount
					Store:dispatch(NotificationActions.setNotification("Rebirth", RebirthCount))
				end
			end

			if self.Stored_Datas["Wins"] ~= Wins then
				self.Stored_Datas["Wins"] = Wins

				local AreaCount = 0
				for name, area in self.Template.Areas do
					if not table.find(Areas, name) and Wins >= area.Price then
						AreaCount += 1
					end
				end

				if self.Notifications["Areas"] ~= AreaCount and self.SendNotif == true and AreaCount > 0 then
					NotificationController:Notify({
						text = self.Template.Messages.Notifications.Can_Buy_X_Areas(1),
						type = "SUCCESS",
					})
				end

				self.Notifications["Areas"] = AreaCount
				Store:dispatch(NotificationActions.setNotification("Areas", AreaCount))

				local CoachCount = 0
				for id, coach in (self.Template.Coaches or {}) do
					if not table.find(Coaches, id) and Wins >= coach.Price and not coach.VIP and not coach.Chest then
						CoachCount += 1
					end
				end

				if self.Notifications["Coaches"] ~= CoachCount and self.SendNotif == true and CoachCount > 0 then
					NotificationController:Notify({
						text = self.Template.Messages.Notifications.Can_Buy_X_Coaches(CoachCount),
						type = "SUCCESS",
					})
				end

				self.Notifications["Coaches"] = CoachCount
				Store:dispatch(NotificationActions.setNotification("Coaches", CoachCount))
			end

			local DailyRewardsReducer = State["DailyRewardsReducer"]
			local RewardClaimable = false

			for id, _ in DailyRewardsReducer.rewards do
				if
					DailyRewardsReducer.lastRedeemedId == 0
					or (
						os.time() - DailyRewardsReducer.lastRedeemedTimestamp >= 86400
						and id == DailyRewardsReducer.lastRedeemedId + 1
					)
				then
					RewardClaimable = true
					break
				end
			end

			if
				self.Notifications["DailyRewards"] ~= RewardClaimable
				and self.SendNotif == true
				and RewardClaimable == 1
			then
				NotificationController:Notify({
					text = self.Template.Messages.Notifications.Can_Buy_Claim_Daily_Reward,
					type = "SUCCESS",
				})
			end
			-- We need to make sure we update UI only when a value changes
			-- It is to make continuous UI animations
			local notification = if RewardClaimable then 1 else 0
			if self.Notifications["DailyRewards"] ~= notification then
				self.Notifications["DailyRewards"] = notification
				Store:dispatch(NotificationActions.setNotification("DailyRewards", if RewardClaimable then 1 else 0))
			end
		end
	end)
end

--|| Knit Lifecycle ||--
function UINotificationController:KnitInit()
	DataCacheController = Knit.GetController("DataCacheController")
	NotificationController = Knit.GetController("NotificationController")

	task.delay(1, function()
		self:InitChecks()

		task.wait(10)

		self.SendNotif = true
	end)

	self.RebirthTable = DataCacheController:GetFile("RebirthTable")
	self.Template = DataCacheController:GetFile("Template")

	print("[UI NOTIFICATION CONTROLLER] Controller loaded successfully!")
end

return UINotificationController
