local Preloader = {}

-- Game Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| Imports ||--
local ImportFolder = ReplicatedStorage:FindFirstChild("Packages")

local src = script
while src and src.Name ~= "src" do
	src = src:FindFirstAncestorWhichIsA("Folder")
end

local function importPackage(name: string)
	local RootFolder = src and src:FindFirstAncestorWhichIsA("Folder") or nil

	return RootFolder and require(RootFolder[name]) or require(ImportFolder:FindFirstChild(name))
end

local Signal = importPackage("signal")
local LoadingTracker = require(script.Modules.Preloader.LoadingTracker)

-- Cache
local preloadUI
local touchGUIFrame
local fillFrames = {}
local loadingTexts = {}

Preloader.EndPreloaderSignal = Signal.new()
Preloader.ControllersLoadedSignal = Signal.new()
local loadingTracker

-- Default paths
local defaultPaths = {
	controllersPath = nil,
	imagesPath = nil,
	componentsPath = nil,
}

-- Default configuration
local defaultConfig = {
	showLoadingScreen = true,
	loadControllers = false,
	loadImages = false,
	loadUI = false,
	initialDelay = 0.5,
	finalDelay = 1.5,
	skipEnabled = true,
	keepLoadingScreen = true,
	paths = defaultPaths,
}

-- Current configuration
local config = table.clone(defaultConfig)

local isSkipped = false
local inScriptLoading = false

-- Configure the preloader with custom options
function Preloader:Configure(options)
	-- Deep merge paths if provided
	if options.paths then
		options.paths = {
			controllersPath = options.paths.controllersPath or defaultPaths.controllersPath,
			imagesPath = options.paths.imagesPath or defaultPaths.imagesPath,
			componentsPath = options.paths.componentsPath or defaultPaths.componentsPath,
		}
	else
		options.paths = defaultPaths
	end

	-- Merge provided options with defaults
	for key, value in pairs(options) do
		config[key] = value
	end

	-- Initialize loading tracker with relevant options
	loadingTracker = LoadingTracker.new({
		trackControllers = config.loadControllers,
		trackImages = config.loadImages,
		trackUI = config.loadUI,
	})
end

function Preloader:UpdateProgressBar(percent, text)
	if not config.showLoadingScreen then
		return
	end
	for _, fillFrame in fillFrames do
		if fillFrame then
			fillFrame.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
		end
	end
	for _, loadingText in loadingTexts do
		loadingText.Text = text
		loadingText.Text = text
	end
end

function Preloader:SetInScripLoading(bool)
	inScriptLoading = bool
end

function Preloader:_SkipButton()
	if not config.skipEnabled then
		return
	end
	isSkipped = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local infoGui = playerGui:FindFirstChild("InfoGui")
	if infoGui then
		infoGui.Enabled = true
	end

	self:EndPreload()
end

function Preloader:isSkipped()
	return isSkipped
end

function Preloader:_InitPreloader()
	if not config.showLoadingScreen then
		return
	end

	-- Disable default loading screen
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	-- Disabling core UI
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	-- Handle touch GUI
	local player = Players.LocalPlayer
	local playerGUI = player:FindFirstChild("PlayerGui")
	if UserInputService.TouchEnabled then
		local touchGUI = playerGUI:WaitForChild("TouchGui", 5)
		if touchGUI then
			touchGUIFrame = touchGUI:FindFirstChild("TouchControlFrame")
			if touchGUIFrame then
				touchGUIFrame.Visible = false
			end
		end
	end

	-- Freeze input
	ContextActionService:BindAction("freeze", function()
		return Enum.ContextActionResult.Sink
	end, false, unpack(Enum.PlayerActions:GetEnumItems()))

	-- Cache UI elements
	preloadUI = playerGUI:WaitForChild("LoadingUI", 10)
	if preloadUI then
		pcall(function()
			-- get all descendants of the preloadUI
			loadingTexts = {}
			fillFrames = {}
			for _, descendant in ipairs(preloadUI:GetDescendants()) do
				if descendant:HasTag("Text") then
					table.insert(loadingTexts, descendant)
				end
				if descendant:HasTag("Fill") then
					table.insert(fillFrames, descendant)
				end

				if descendant.Name == "SkipButton" and config.skipEnabled then
					descendant.MouseButton1Click:Connect(function()
						self:_SkipButton()
					end)

					descendant.Visible = true
				end
			end
		end)
	end
end

function Preloader:_LoadControllers()
	if not config.loadControllers then
		return
	end

	-- Get all controller modules recursively
	local function getControllerModules(folder)
		local modules = {}
		for _, item in ipairs(folder:GetDescendants()) do
			if item:IsA("ModuleScript") then
				table.insert(modules, item)
			end
		end
		return modules
	end

	local controllerFolder = config.paths.controllersPath
	local controllerModules = getControllerModules(controllerFolder)

	-- Register the total number of controllers
	loadingTracker:registerAssets("controllers", #controllerModules)

	-- Load each controller
	for _, controllerModule in ipairs(controllerModules) do
		require(controllerModule)
		loadingTracker:assetLoaded("controllers")
		self:UpdateProgressBar(loadingTracker:getProgress(), loadingTracker:getProgressText())
		task.wait(0.1)
	end

	-- Fire the controllers loaded signal in the next frame
	task.defer(function()
		Preloader.ControllersLoadedSignal:Fire(true)
	end)
end

function Preloader:_LoadUI()
	if not config.loadImages then
		return
	end

	local UIDatas = require(config.paths.imagesPath)
	local uiToPreload = {}

	local function countImages(data)
		local count = 0
		for key, value in pairs(data) do
			if type(value) == "string" then
				count += 1
			elseif type(value) == "table" then
				count += countImages(value)
			end
		end
		return count
	end

	local function collectImages(data, path, images)
		path = path or ""
		images = images or {}

		for key, value in pairs(data) do
			local currentPath = path == "" and key or path .. "." .. key
			if type(value) == "string" then
				table.insert(images, { name = currentPath, id = value })
			elseif type(value) == "table" then
				collectImages(value, currentPath, images)
			end
		end
		return images
	end

	local imageCount = countImages(UIDatas)
	loadingTracker:registerAssets("images", imageCount)

	local function processImageBatch(imageBatch)
		local threads = {}

		for _, imageData in ipairs(imageBatch) do
			local thread = task.spawn(function()
				local newImage = Instance.new("ImageLabel")
				newImage.Image = imageData.id
				table.insert(uiToPreload, newImage)
				ContentProvider:PreloadAsync({ newImage }, function(contentId, status)
					if status == Enum.AssetFetchStatus.Success then
						loadingTracker:assetLoaded("images")
						self:UpdateProgressBar(loadingTracker:getProgress(), loadingTracker:getProgressText())
					end
				end)
			end)
			table.insert(threads, thread)
		end
	end

	local allImages = collectImages(UIDatas)
	local batchSize = config.batchSize or math.huge
	local currentBatch = {}
	local count = 0

	for _, imageData in ipairs(allImages) do
		count = count + 1
		table.insert(currentBatch, imageData)

		if count % batchSize == 0 or count == imageCount then
			processImageBatch(currentBatch)
			task.wait()
			currentBatch = {}
		end
	end

	for index, value in uiToPreload do
		value:Destroy()
	end
end

function Preloader:_LoadRoactComponents()
	if not config.loadUI then
		return
	end

	local function countComponents(folder)
		local count = 0
		for _, item in ipairs(folder:GetDescendants()) do
			if item:IsA("ModuleScript") then
				count += 1
			end
		end
		return count
	end

	local componentsFolder = config.paths.componentsPath
	local componentCount = countComponents(componentsFolder)
	loadingTracker:registerAssets("uiComponents", componentCount)

	local function loadComponents(folder)
		for _, item in ipairs(folder:GetDescendants()) do
			if item:IsA("ModuleScript") then
				require(item)
				loadingTracker:assetLoaded("uiComponents")
				self:UpdateProgressBar(loadingTracker:getProgress(), loadingTracker:getProgressText())
				task.wait(0.05)
			end
		end
	end

	loadComponents(componentsFolder)
end

function Preloader:DestroyLoadingScreen()
	if preloadUI then
		preloadUI:Destroy()
		preloadUI = nil
	end
end

function Preloader:EndPreload()
	-- Re-enable core UI if it was disabled
	if config.showLoadingScreen then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

		if touchGUIFrame then
			touchGUIFrame.Visible = true
		end

		-- Only destroy the UI if we're not keeping the loading screen
		if preloadUI and not config.keepLoadingScreen then
			preloadUI:Destroy()
		end

		ContextActionService:UnbindAction("freeze")
	end

	-- disable respawn
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	-- Fire the completion signal in the next frame
	task.defer(function()
		Preloader.EndPreloaderSignal:Fire(true)
	end)
end

function Preloader:PreloadContent()
	if not loadingTracker then
		self:Configure({}) -- Use defaults if not configured
	end

	self:_InitPreloader()
	task.wait(config.initialDelay)

	-- Load everything according to configuration
	self:_LoadControllers()
	self:_LoadUI()
	--self:_LoadRoactComponents()

	if not self:isSkipped() then
		local finalMessage = config.keepLoadingScreen and "You'll be teleported to a new place..."
			or "Loading Complete! Have Fun!"

		self:UpdateProgressBar(1, finalMessage)
		task.wait(config.finalDelay)
		self:EndPreload()
	end
end

return Preloader
