-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local HUMANOID_DESCRIPTION_KEYS = {
	"Head", -- bodypart classic head (paket R6/R15 classic)
	"Face", -- decal/face asset id
	"HeadColor", -- Color3
	"LeftArmColor", -- Color3
	"LeftLegColor", -- Color3
	"RightArmColor", -- Color3
	"RightLegColor", -- Color3
	"TorsoColor", -- Color3
}

local ALL_ACCESSORY_SLOTS = {
	"BackAccessory",
	"FaceAccessory",
	"FrontAccessory",
	"HairAccessory",
	"HatAccessory",
	"NeckAccessory",
	"ShouldersAccessory",
	"WaistAccessory",
}

local CharacterService = Knit.CreateService({
	Name = "CharacterService",
	Client = {
		CharacterLoaded = Knit.CreateSignal(),
	},

	CachedHumanoidDescriptions = {}, -- [userId] = HumanoidDescription
	CharacterLoadedSignal = Signal.new(),
})

local function tryGetHumanoidDescWithRetry(userId: number, maxAttempts: number?, firstDelay: number?)
	maxAttempts = maxAttempts or 4 -- total percobaan
	firstDelay = firstDelay or 0.25 -- jeda awal
	local delay = firstDelay

	for attempt = 1, maxAttempts do
		local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, userId)
		if ok and desc then
			return desc
		end

		-- percobaan terakhir, keluar
		if attempt == maxAttempts then
			warn("Failed to get HumanoidDescription for userId:", userId, attempt, "attempts")
			return nil
		end

		-- exponential backoff + jitter kecil (0–50 ms)
		local jitter = math.random() * 0.05
		task.wait(delay + jitter)
		delay = delay * 2
	end

	return nil
end

local function copySelectedFields(dstDesc: HumanoidDescription, srcDesc: HumanoidDescription)
	for _, key in ipairs(HUMANOID_DESCRIPTION_KEYS) do
		dstDesc[key] = srcDesc[key]
	end
end

local function clearAccessories(desc: HumanoidDescription)
	for _, key in ipairs(ALL_ACCESSORY_SLOTS) do
		desc[key] = ""
	end
end

-- KNIT START
function CharacterService:KnitStart()
	local function characterAdded(player: Player, character: Model)
		-- matikan visible forcefield kalau ada
		local forceField = character:FindFirstChildOfClass("ForceField")
		if forceField then
			forceField.Visible = false
		end

		local humanoid = character:WaitForChild("Humanoid")
		local userId = player.UserId

		-- ambil desc yang sudah nempel di karakter (baseline)
		local currentDesc = humanoid:GetAppliedDescription()

		local userDesc = self.CachedHumanoidDescriptions[userId] or tryGetHumanoidDescWithRetry(userId)

		-- simpan cache
		if not self.CachedHumanoidDescriptions[userId] then
			self.CachedHumanoidDescriptions[userId] = userDesc
		end

		-- merge: hanya head & accessories jika data ditemukan
		if userDesc then
			-- Amankan model Football agar tidak dihapus ApplyDescriptionAsync
			local football = character:FindFirstChild("Football", true)
			local savedParent = football and football.Parent

			if football then
				football.Parent = nil -- Pindah sementara ke luar
			end

			clearAccessories(currentDesc)
			copySelectedFields(currentDesc, userDesc)

			-- apply ulang: yang lain tidak berubah
			local success, err = pcall(function()
				humanoid:ApplyDescriptionAsync(currentDesc)
			end)

			if not success then
				warn("CharacterService: ApplyDescriptionAsync failed for", player.Name, ":", err)
			end

			-- Kembalikan Football ke HumanoidRootPart
			if football then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				football.Parent = hrp or savedParent or character
			end
		else
			warn("CharacterService: userDesc is nil for", player.Name, "(UserId:", userId, ")")
		end

		self.CharacterLoadedSignal:Fire(player, character)
		self.Client.CharacterLoaded:Fire(player, character)
	end

	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			characterAdded(player, character)
		end)

		-- Jika karakter sudah ada saat script ini jalan (misal baru masuk studio)
		if player.Character then
			characterAdded(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(playerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		playerAdded(player)
	end
end

return CharacterService
