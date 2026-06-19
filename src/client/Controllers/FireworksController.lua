local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)

local FireworksController = Knit.CreateController({
	Name = "FireworksController",
})

-- Configuration Constantss
local FIREWORK_INTERVAL_SECONDS = 5
local DEBUG_FIREWORKS = false
local USE_TEST_SPAWN_POSITION = false
local TEST_SPAWN_POSITION = Vector3.new(0, 0, -60)
local TEST_MAX_LAUNCHERS = 1
local FLARE_POOL_TARGET = 120
local FLARE_POOL_MAX_IDLE = 160

local BANG_SOUND_KEYS = {
	"MISC_FireworkBurstA",
	"MISC_FireworkBurstB",
	"MISC_FireworkBurstC",
}

local FIREWORK_SOUND_KEYS = {
	"MISC_FireworkLaunch",
	"MISC_FireworkFountain",
	"MISC_FireworkBurstA",
	"MISC_FireworkBurstB",
	"MISC_FireworkBurstC",
	"MISC_FireworkFinalBurst",
}

local COLORS = {
	red = Color3.new(1, 0, 0),
	orange = Color3.new(1, 0.5, 0),
	yellow = Color3.new(1, 1, 0),
	green = Color3.new(0, 1, 0),
	blue = Color3.new(0, 0, 1),
	purple = Color3.new(1, 0, 1),
}

local COLOR_SEQUENCE = { "red", "orange", "yellow", "green", "blue", "purple" }

-- State Variables
local flarePool = {}
local activeFlares = {}
local nextFlareId = 0
local flareSpawnedCount = 0

local function debugLog(message: string, ...: any)
	if not DEBUG_FIREWORKS then
		return
	end
	print("[FireworksController DEBUG] " .. string.format(message, ...))
end

local function getColor(colorName: string?): Color3
	if colorName and COLORS[colorName] then
		return COLORS[colorName]
	end
	return Color3.new(1, 1, 0)
end

local function setParticleEnabled(flare: BasePart, enabled: boolean)
	for _, child in ipairs(flare:GetChildren()) do
		if child:IsA("Sparkles") or child:IsA("Fire") then
			child.Enabled = enabled
		end
	end
end

local function applyFlareColor(flare: BasePart, colorName: string?)
	local color = getColor(colorName)
	for _, child in ipairs(flare:GetChildren()) do
		if child:IsA("Sparkles") then
			child.SparkleColor = color
		elseif child:IsA("Fire") then
			child.Color = color
			child.SecondaryColor = Color3.new(1, 1, 1)
		end
	end
end

local function createFlarePart(): BasePart
	nextFlareId += 1

	local part = Instance.new("Part")
	part.Name = "EffectFlare_" .. tostring(nextFlareId)
	part.Transparency = 1
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(1, 1, 1)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Anchored = false

	local sparkles = Instance.new("Sparkles")
	sparkles.Name = "Sparkles"
	sparkles.Parent = part

	local fire = Instance.new("Fire")
	fire.Color = Color3.new(1, 1, 0.5)
	fire.SecondaryColor = Color3.new(1, 1, 1)
	fire.Heat = 45
	fire.Size = 15
	fire.Parent = part

	local bodyForce = Instance.new("BodyForce")
	bodyForce.Name = "FloatForce"
	bodyForce.Parent = part

	setParticleEnabled(part, false)
	part.Parent = nil

	return part
end

local function acquireFlare(): BasePart
	local flare = table.remove(flarePool)
	if not flare then
		flare = createFlarePart()
	end
	activeFlares[flare] = (activeFlares[flare] or 0) + 1
	return flare
end

local function stopFlareSounds(flare: BasePart)
	for _, soundName in ipairs(FIREWORK_SOUND_KEYS) do
		Sound:StopSound(soundName, flare)
	end
end

local function releaseFlare(flare: BasePart, token: number)
	if activeFlares[flare] ~= token then
		return
	end

	activeFlares[flare] = nil
	stopFlareSounds(flare)
	flare.AssemblyLinearVelocity = Vector3.zero
	flare.AssemblyAngularVelocity = Vector3.zero
	flare.Velocity = Vector3.zero
	flare.RotVelocity = Vector3.zero
	flare.Anchored = false
	flare.Parent = nil
	setParticleEnabled(flare, false)

	if #flarePool < FLARE_POOL_MAX_IDLE then
		table.insert(flarePool, flare)
	else
		flare:Destroy()
	end
end

local function warmFlarePool()
	while #flarePool < FLARE_POOL_TARGET do
		table.insert(flarePool, createFlarePart())
	end
end

local function playSound(soundName: string, parent: Instance, pitch: number?)
	if pitch then
		local sound = Sound:GetOrCreateSound(soundName, parent)
		if not sound then
			return
		end
		sound:setPitch(pitch)
		sound:play()
		return
	end
	Sound:PlaySound(soundName, parent)
end

local function playRandomBang(flare: BasePart)
	playSound(BANG_SOUND_KEYS[math.random(1, #BANG_SOUND_KEYS)], flare, 0.8 + math.random() * 0.4)
end

local function createTestSpawnMarker()
	if not USE_TEST_SPAWN_POSITION then
		return
	end

	local existing = Workspace:FindFirstChild("FireworksTestSpawnMarker")
	if existing then
		existing:Destroy()
	end

	local marker = Instance.new("Part")
	marker.Name = "FireworksTestSpawnMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.new(1, 0, 0)
	marker.Size = Vector3.new(4, 4, 4)
	marker.Position = TEST_SPAWN_POSITION
	marker.Parent = Workspace
end

local function getLauncherCFrame(launcher: Instance): CFrame
	if launcher:IsA("BasePart") then
		return launcher.CFrame
	elseif launcher:IsA("Model") then
		return launcher:GetPivot()
	end
	return CFrame.new()
end

local function getLauncherPosition(launcher: Instance): Vector3
	if USE_TEST_SPAWN_POSITION then
		return TEST_SPAWN_POSITION
	end

	return getLauncherCFrame(launcher).Position
end

local function flareAt(
	effectParent: Instance,
	position: Vector3,
	velocity: Vector3,
	floaty: number?,
	timer: number?,
	colorName: string?
): BasePart
	local lifetime = timer or 2
	local flarePart = acquireFlare()
	local token = activeFlares[flarePart]

	-- Parent MUST be set before setting physics/velocity in Roblox
	flarePart.CFrame = CFrame.new(position) * CFrame.Angles(math.pi, 0, 0)
	flarePart.Parent = effectParent

	flarePart.AssemblyLinearVelocity = velocity
	flarePart.AssemblyAngularVelocity = Vector3.zero
	flarePart.Velocity = velocity
	flarePart.RotVelocity = Vector3.zero

	local bodyForce = flarePart:FindFirstChild("FloatForce")
	if bodyForce and bodyForce:IsA("BodyForce") then
		bodyForce.Force = Vector3.new(0, flarePart:GetMass() * Workspace.Gravity * (floaty or 0), 0)
	end

	applyFlareColor(flarePart, colorName)
	setParticleEnabled(flarePart, true)

	debugLog("Spawned flare pos=%s velocity=%s part=%s", tostring(position), tostring(velocity), flarePart:GetFullName())

	task.delay(lifetime, function()
		if activeFlares[flarePart] == token then
			setParticleEnabled(flarePart, false)
		end
	end)

	task.delay(lifetime + 3, function()
		releaseFlare(flarePart, token)
	end)

	return flarePart
end

local function flare(launcher: Instance, velocity: Vector3, floaty: number?, timer: number?, colorName: string?): BasePart
	return flareAt(launcher, getLauncherPosition(launcher), velocity, floaty, timer, colorName)
end

local function getLauncherBurstCFrame(launcher: Instance): CFrame
	if USE_TEST_SPAWN_POSITION then
		return CFrame.new(TEST_SPAWN_POSITION)
	end

	return getLauncherCFrame(launcher)
end

local function createFuse(launcher: Instance)
	local fuse = launcher:FindFirstChild("EffectFuse")
	local fire
	if fuse then
		fire = fuse:FindFirstChildWhichIsA("Fire") or fuse:FindFirstChildWhichIsA("ParticleEmitter")
	end

	if not fuse then
		if not launcher:IsA("BasePart") then
			return
		end
		fuse = Instance.new("Part")
		fuse.Name = "EffectFuse"
		fuse.Size = Vector3.new(0.1, 0.1, 0.1)
		fuse.Anchored = false
		fuse.CanCollide = false
		fuse.Transparency = 1
		fuse.Parent = launcher

		local weld = Instance.new("Weld")
		weld.Part0 = launcher
		weld.Part1 = fuse
		weld.C0 = CFrame.new(-0.3, -1.8, 1.4)
		weld.Parent = launcher
	end

	if not fire then
		fire = Instance.new("Fire")
		fire.Size = 2
		fire.Parent = fuse
	end

	fire.Enabled = true
	task.delay(7, function()
		if fire.Parent then
			fire.Enabled = false
		end
	end)
end

-- Patterns
local function fireClassic(launcher: Instance, shouldRun: () -> boolean)
	local launcherCFrame = getLauncherBurstCFrame(launcher)

	for _ = 1, 3 do
		if not shouldRun() then
			return
		end

		task.spawn(function()
			if not shouldRun() then
				return
			end

			local colorName = COLOR_SEQUENCE[math.random(1, #COLOR_SEQUENCE)]
			local launchDirection = (
				CFrame.Angles(math.pi / 2, 0, 0)
				* CFrame.Angles((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, 0)
			).LookVector

			local rocketFlare = flare(launcher, launchDirection * 220, 0.8, 3)
			rocketFlare.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 100

			playSound("MISC_FireworkLaunch", rocketFlare)

			task.wait(3)
			if not shouldRun() or not activeFlares[rocketFlare] then
				return
			end

			playRandomBang(rocketFlare)
			local totalFlares = 16
			for i = 1, totalFlares do
				local burstFlare = flareAt(
					launcher,
					rocketFlare.Position,
					(launcherCFrame * CFrame.Angles((i / totalFlares) * math.pi * 2, 0, 0)).LookVector * 90,
					0.96,
					4,
					colorName
				)

				if i == totalFlares then
					playSound("MISC_FireworkFinalBurst", burstFlare, 0.5)
				end
			end
		end)

		task.wait(0.4)
	end
end

local function fireFan(launcher: Instance, colorCounter: { Value: number }, shouldRun: () -> boolean)
	local launcherCFrame = getLauncherBurstCFrame(launcher)

	for sweep = 1, 2 do
		for i = 1, 9 do
			if not shouldRun() then
				return
			end

			colorCounter.Value = (colorCounter.Value + 1) % #COLOR_SEQUENCE
			local normalized = (i - 1) / 8
			local angle = sweep == 1 and (normalized - 0.5) * 1.8 or ((1 - normalized) - 0.5) * 1.8
			local fanFlare = flare(
				launcher,
				(launcherCFrame * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.Angles(angle, 0, 0)).LookVector * 90,
				0.95,
				3,
				COLOR_SEQUENCE[colorCounter.Value + 1]
			)

			playSound("MISC_FireworkFountain", fanFlare, 0.5 + math.random() * 0.1)

			task.wait(0.2)
		end

		if sweep == 1 then
			task.wait(0.3)
		end
	end
end

local function fireDisplay(launcher: Instance, colorCounter: { Value: number }, shouldRun: () -> boolean)
	local launcherCFrame = getLauncherBurstCFrame(launcher)

	local function sideShot(angle: number, speed: number)
		if not shouldRun() then
			return
		end

		local sideFlare = flare(
			launcher,
			(launcherCFrame * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.Angles(angle, 0, 0)).LookVector * speed,
			0.95,
			2.5
		)
		playSound("MISC_FireworkLaunch", sideFlare)
	end

	if not shouldRun() then
		return
	end

	sideShot(0.9, 90)
	sideShot(-0.9, 90)
	task.wait(0.4)

	sideShot(0.6, 110)
	sideShot(-0.6, 110)
	task.wait(0.4)

	sideShot(0.3, 130)
	sideShot(-0.3, 130)
	task.wait(0.8)

	local rocketFlare = flare(launcher, Vector3.new(0, 260, 0), 0.8, 2)
	playSound("MISC_FireworkLaunch", rocketFlare)
	task.wait(2)

	if not shouldRun() or not activeFlares[rocketFlare] then
		return
	end

	playRandomBang(rocketFlare)
	local displayFlares = 14
	for i = 1, displayFlares do
		if not shouldRun() then
			return
		end

		colorCounter.Value = (colorCounter.Value + 1) % #COLOR_SEQUENCE
		flareAt(
			launcher,
			rocketFlare.Position,
			(launcherCFrame * CFrame.Angles((i / displayFlares) * math.pi * 2, 0, 0)).LookVector * 100,
			0.96,
			3.5,
			COLOR_SEQUENCE[colorCounter.Value + 1]
		)
	end
end

function FireworksController:_runLauncher(launcher: Instance, runToken: number)
	debugLog("Running launcher: %s token=%d", launcher:GetFullName(), runToken)

	local colorCounter = { Value = 0 }
	local patternIndex = 0

	createFuse(launcher)

	local function shouldRun()
		return launcher.Parent ~= nil and self._runToken == runToken
	end

	while launcher.Parent and self._runToken == runToken do
		patternIndex = (patternIndex % 3) + 1

		if patternIndex == 1 then
			debugLog("Pattern fireFan launcher=%s", launcher:GetFullName())
			fireFan(launcher, colorCounter, shouldRun)
		elseif patternIndex == 2 then
			debugLog("Pattern fireDisplay launcher=%s", launcher:GetFullName())
			fireDisplay(launcher, colorCounter, shouldRun)
		else
			debugLog("Pattern fireClassic launcher=%s", launcher:GetFullName())
			fireClassic(launcher, shouldRun)
		end

		task.wait(FIREWORK_INTERVAL_SECONDS)
	end
end

function FireworksController:_startFireworks(launchers: { Instance })
	if self._isRunning then
		return
	end

	warmFlarePool()
	self._isRunning = true
	self._runToken += 1
	local runToken = self._runToken

	for index, launcher in ipairs(launchers) do
		if USE_TEST_SPAWN_POSITION and index > TEST_MAX_LAUNCHERS then
			break
		end

		task.spawn(function()
			self:_runLauncher(launcher, runToken)
		end)
	end

	debugLog(
		"Started %d local launcher(s). testSpawn=%s testPosition=%s",
		USE_TEST_SPAWN_POSITION and math.min(#launchers, TEST_MAX_LAUNCHERS) or #launchers,
		tostring(USE_TEST_SPAWN_POSITION),
		tostring(TEST_SPAWN_POSITION)
	)
end

local function findLobby(): Instance?
	local area05Direct = Workspace:FindFirstChild("Area05")
	if area05Direct then
		local lobby = area05Direct:FindFirstChild("Lobby")
		if lobby then
			debugLog("Using runtime Area05 lobby: %s", lobby:GetFullName())
			return lobby
		end
	end

	local mapAreas = Workspace:FindFirstChild("MapAreas")
	if mapAreas then
		local area05 = mapAreas:FindFirstChild("Area05")
		if area05 then
			local lobby = area05:FindFirstChild("Lobby")
			if lobby then
				debugLog("Using staging MapAreas Area05 lobby: %s", lobby:GetFullName())
				return lobby
			end
		end
	end

	return nil
end

local function getLaunchers(lobby: Instance): { Instance }
	local launchers = {}
	for _, child in ipairs(lobby:GetChildren()) do
		if child.Name == "Model" and (child:IsA("BasePart") or child:IsA("Model")) then
			table.insert(launchers, child)
		end
	end
	return launchers
end

function FireworksController:KnitInit()
	self._isRunning = false
	self._runToken = 0
end

function FireworksController:KnitStart()
	debugLog("KnitStart.")
	createTestSpawnMarker()

	local function tryLaunchFromLobby(lobby: Instance): boolean
		if not lobby then
			return false
		end

		local launchers = getLaunchers(lobby)
		if #launchers == 0 then
			debugLog("Lobby found but no launchers inside: %s", lobby:GetFullName())
			return false
		end

		-- Disable/destroy old script inside launchers to prevent double execution
		for _, launcher in ipairs(launchers) do
			local oldScript = launcher:FindFirstChild("FireworksScript")
			if oldScript then
				oldScript.Enabled = false
				oldScript:Destroy()
			end
		end

		self:_startFireworks(launchers)
		return true
	end

	local function waitAndLaunch()
		-- Coba langsung dulu (jika sudah ada di workspace)
		local lobby = findLobby()
		if lobby and tryLaunchFromLobby(lobby) then
			return
		end

		debugLog("Area05 belum ter-load, menunggu dengan timeout lebih panjang...")

		-- Coba path langsung (Workspace.Area05) dengan timeout lebih panjang
		local area05Direct = Workspace:WaitForChild("Area05", 60)
		if area05Direct then
			local lobbyDirect = area05Direct:WaitForChild("Lobby", 15)
			if lobbyDirect and tryLaunchFromLobby(lobbyDirect) then
				return
			end
		end

		-- Fallback: coba path MapAreas
		local mapAreas = Workspace:FindFirstChild("MapAreas")
			or Workspace:WaitForChild("MapAreas", 10)
		if mapAreas then
			local area05 = mapAreas:FindFirstChild("Area05")
				or mapAreas:WaitForChild("Area05", 60)
			if area05 then
				local lobbyNested = area05:FindFirstChild("Lobby")
					or area05:WaitForChild("Lobby", 15)
				if lobbyNested then
					tryLaunchFromLobby(lobbyNested)
				end
			end
		end
	end

	task.spawn(waitAndLaunch)

	-- Fallback dinamis: jika Area05 ter-stream masuk workspace SETELAH timeout habis
	-- (misalnya player teleport ke Area05 jauh setelah game start)
	local streamConn
	streamConn = Workspace.ChildAdded:Connect(function(child)
		if child.Name ~= "Area05" then
			return
		end
		if self._isRunning then
			streamConn:Disconnect()
			return
		end
		debugLog("Area05 ter-stream masuk workspace, mencoba launch fireworks...")
		task.spawn(function()
			local lobby = child:WaitForChild("Lobby", 15)
			if lobby and tryLaunchFromLobby(lobby) then
				streamConn:Disconnect()
			end
		end)
	end)
end

return FireworksController
