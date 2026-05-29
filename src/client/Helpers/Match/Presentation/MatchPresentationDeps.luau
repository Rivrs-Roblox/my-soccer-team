local MatchPresentationDeps = {}

function MatchPresentationDeps.Resolve(controller, Context)
	local Knit = Context.Knit

	controller.MatchService = Knit.GetService("MatchService")

	pcall(function()
		controller.MatchBattleCameraController = Knit.GetController("MatchBattleCameraController")
	end)
	pcall(function()
		controller.MatchBallController = Knit.GetController("MatchBallController")
	end)
	pcall(function()
		controller.MatchKeeperPresentationController = Knit.GetController("MatchKeeperPresentationController")
	end)
	pcall(function()
		controller.MatchSpawnLayoutController = Knit.GetController("MatchSpawnLayoutController")
	end)
	pcall(function()
		controller.MatchUIController = Knit.GetController("MatchUIController")
	end)
	pcall(function()
		controller.UIController = Knit.GetController("UIController")
	end)
	pcall(function()
		controller.MatchActorRuntimeController = Knit.GetController("MatchActorRuntimeController")
	end)
	pcall(function()
		controller.MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
	end)
	pcall(function()
		controller.NpcSupporterCheerController = Knit.GetController("NpcSupporterCheerController")
	end)
end

return MatchPresentationDeps
