-- Knit Packages
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local Players = game:GetService("Players")
local DataService

local TitleGuiTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GUIs"):WaitForChild("PlayerTitleGui")

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

local titlesTemplate = {
	{ Threshold = 0, Title = "Benchwarmer 🪑💤" },
	{ Threshold = 5, Title = "Sunday League 🏟️🚶‍♂️" },
	{ Threshold = 15, Title = "Local Talent ⚽🏃‍♂️" },
	{ Threshold = 30, Title = "Academy Player 🏫🎒" },
	{ Threshold = 50, Title = "Rising Star ⭐👟" },
	{ Threshold = 75, Title = "Pro Player 🏅👕" },
	{ Threshold = 100, Title = "Team Captain 🧢©️" },
	{ Threshold = 150, Title = "Playmaker 🧠👟" },
	{ Threshold = 200, Title = "Star Striker 🎯🔥" },
	{ Threshold = 300, Title = "Golden Boot 🏆👟" },
	{ Threshold = 400, Title = "MVP 🌟🥇" },
	{ Threshold = 500, Title = "World Class 🌍⚽" },
	{ Threshold = 600, Title = "Ballon d'Or Winner 🏆👑" },
	{ Threshold = 750, Title = "Football Legend 🐉🏅" },
	{ Threshold = 900, Title = "Icon 🏟️🖼️" },
	{ Threshold = 1050, Title = "Football God ⚡⚽" },
	{ Threshold = 1200, Title = "The GOAT 🐐👑" },
	{ Threshold = 1350, Title = "Ultimate Striker 🌌🚀" },
	{ Threshold = 1500, Title = "Beyond Football 🌠⚽" },
}

local TitleService = Knit.CreateService({
	Name = "TitleService",
	Titles = {},

	Client = {

		TitleGuiCreated = Knit.CreateSignal(),
	},
})

local function titleDecider(rebirths: number): string
	local result = "Newbie"
	for _, data in ipairs(titlesTemplate) do
		if rebirths >= data.Threshold then
			result = data.Title
		else
			break
		end
	end
	return result
end

--|| Client Functions ||--
function TitleService.Client:UpdateTitleData(player: Player, rebirths: number)
	self.Server:UpdateTitleData(player, rebirths)
end

function TitleService:UpdateTitleData(player: Player, rebirths: number)
	local playerTitleGui = self.Titles[player.UserId]
	if playerTitleGui then
		playerTitleGui.Frame.TitleText.Text = titleDecider(rebirths)
	end
end

-- KNIT START
function TitleService:KnitInit()
	DataService = Knit.GetService("DataService")

	DataService.RebirthUpdatedSignal:Connect(function(player: Player, rebirths: number)
		self:UpdateTitleData(player, rebirths)
	end)

	local function characterAdded(player: Player, character: Instance)
		local data = DataService:GetData(player)
		if not data then
			return
		end

		if self.Titles[player.UserId] then
			-- sudah ada title gui, jangan buat lagi
			return
		end

		-- matikan nametag player
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		-- masukkan title gui ke kepala player
		local playerTitleGui = TitleGuiTemplate:Clone()
		playerTitleGui.Parent = character
		playerTitleGui.Adornee = humanoidRootPart
		playerTitleGui.StudsOffset = Vector3.new(0, 3.5, 0)
		playerTitleGui.Frame.NameText.Text = player.DisplayName

		-- masukkan title ke tabel titles
		self.Titles[player.UserId] = playerTitleGui

		-- buat koneksi kalau player mati, perbarui referensi title gui
		humanoid.Died:Connect(function()
			if self.Titles[player.UserId] then
				self.Titles[player.UserId] = nil
			end
		end)

		self:UpdateTitleData(player, data.Rebirth or 0)
	end

	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			characterAdded(player, character)
		end)

		if player.Character then
			characterAdded(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(playerAdded)
	for _, player in pairs(Players:GetChildren()) do
		playerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		if self.Titles[player.UserId] then
			self.Titles[player.UserId] = nil
		end
	end)
end

return TitleService
