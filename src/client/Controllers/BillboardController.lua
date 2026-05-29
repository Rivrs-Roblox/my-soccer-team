--[=[
    Owner: JustStop__
	Version: v0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Knit Controllers
local DataCacheController

-- BillboardController
local BillboardController = Knit.CreateController({
	Name = "BillboardController",
})

--|| Knit Lifecycle ||--
function BillboardController:KnitInit()
	DataCacheController = Knit.GetController("DataCacheController")

	self.BillboardConfig = DataCacheController:GetFile("BillboardConfig")
end

function BillboardController:KnitStart()
	-- Cache: model → ImageLabel reference, built once per model on tag.
	-- The hot loop only touches this table — zero FindFirstChild per tick.
	local posterCache: { [Model]: ImageLabel } = {}

	local function register(model: Model)
		local poster = model:FindFirstChild("Poster")
		local surfaceGui = poster and poster:FindFirstChild("SurfaceGui")
		local image = surfaceGui and surfaceGui:FindFirstChild("PosterImage")
		if image then
			posterCache[model] = image :: ImageLabel
		end
	end

	local function unregister(model: Model)
		posterCache[model] = nil
	end

	-- Cache all models already tagged on startup
	for _, model in CollectionService:GetTagged(self.BillboardConfig.Tag) do
		register(model)
	end

	-- Keep cache in sync as models get tagged / untagged / streamed out
	CollectionService:GetInstanceAddedSignal(self.BillboardConfig.Tag):Connect(register)
	CollectionService:GetInstanceRemovedSignal(self.BillboardConfig.Tag):Connect(unregister)

	-- Rotation loop: only iterates direct ImageLabel references — no lookup overhead
	local currentIndex = 1
	task.spawn(function()
		while true do
			local image = self.BillboardConfig.Images[currentIndex]
			for _, label in posterCache do
				label.Image = image
			end
			currentIndex = (currentIndex % #self.BillboardConfig.Images) + 1
			task.wait(self.BillboardConfig.Interval)
		end
	end)

	print("[BILLBOARD CONTROLLER] Controller loaded successfully.")
end

return BillboardController
