local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")

local Knit = require(ReplicatedStorage.Packages.Knit)

--[[
	MatchPresentationController
	Rojo path:
		src/client/Controllers/MatchPresentationController.luau

	Presentation modules path:
		src/client/Helpers/Match/Presentation/*.luau

	This controller is intentionally kept as the Knit entry point only.
	All heavy logic is attached from Presentation modules to avoid a God Controller.
]]

local LocalPlayer = Players.LocalPlayer
local ClientRoot = script.Parent.Parent

local HelpersRoot = ClientRoot:WaitForChild("Helpers")
local MatchHelpersRoot = HelpersRoot:WaitForChild("Match")
local PresentationRoot = MatchHelpersRoot:WaitForChild("Presentation")
local ConfigRoot = ClientRoot:WaitForChild("Config")
local MatchConfigRoot = ConfigRoot:WaitForChild("Match")

local MatchActorResolver = require(ReplicatedStorage.Shared.Helpers.Match.MatchActorResolver)
local MatchGrounding = require(ReplicatedStorage.Shared.Helpers.Match.MatchGrounding)
local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)

local MatchMotionMath = require(MatchHelpersRoot:WaitForChild("MatchMotionMath"))
local MatchAnimationHelper = require(MatchHelpersRoot:WaitForChild("MatchAnimationHelper"))
local MatchBallConfig = require(MatchConfigRoot:WaitForChild("MatchBallConfig"))

local MatchPresentationConstants = require(PresentationRoot:WaitForChild("MatchPresentationConstants"))
local MatchPresentationState = require(PresentationRoot:WaitForChild("MatchPresentationState"))
local MatchPresentationDeps = require(PresentationRoot:WaitForChild("MatchPresentationDeps"))
local MatchPresentationUtilsFactory = require(PresentationRoot:WaitForChild("MatchPresentationUtils"))

local MatchPresentationController = Knit.CreateController(MatchPresentationState.CreateControllerDefinition())

local Context = {
	Services = {
		Players = Players,
		ReplicatedStorage = ReplicatedStorage,
		RunService = RunService,
		Workspace = Workspace,
		Debris = Debris,
		PhysicsService = PhysicsService,
	},

	Knit = Knit,
	LocalPlayer = LocalPlayer,

	MatchActorResolver = MatchActorResolver,
	MatchGrounding = MatchGrounding,
	MatchSceneQuery = MatchSceneQuery,
	MatchZoneQuery = MatchZoneQuery,
	MatchMotionMath = MatchMotionMath,
	MatchBallConfig = MatchBallConfig,
	MatchAnimationHelper = MatchAnimationHelper,

	Constants = MatchPresentationConstants,
	DepsResolver = MatchPresentationDeps,
}

Context.Utils = MatchPresentationUtilsFactory(Context)

MatchPresentationState.Attach(MatchPresentationController, Context)

local ModulesToAttach = {
	"MatchAnimationDirector",
	"MatchQteFreezeDirector",
	"MatchEnemyDirector",
	"MatchSupportDirector",
	"MatchBallBridge",
	"MatchResolveDirector",
	"MatchShootDirector",
	"MatchApproachDirector",
	"MatchActorLookAtDirector",
	"MatchPresentationCleanup",
}

local function attachPresentationModule(moduleName: string)
	local moduleScript = PresentationRoot:WaitForChild(moduleName)
	local attach = require(moduleScript)

	assert(
		type(attach) == "function",
		string.format("[MatchPresentationController] Presentation module '%s' must return an attach(controller, context) function.", moduleName)
	)

	attach(MatchPresentationController, Context)
end

for _, moduleName in ipairs(ModulesToAttach) do
	attachPresentationModule(moduleName)
end

return MatchPresentationController
