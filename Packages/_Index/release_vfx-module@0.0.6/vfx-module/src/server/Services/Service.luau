--|| Services ||--
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

local Knit = importPackage("knit")
-- VFXService.lua
local VFXServ = Knit.CreateService({
    Name = "VFXServ",
    Client = {
        PlayVFXSignal = Knit.CreateSignal(),
        DestroyVFXSignal = Knit.CreateSignal(), -- New signal for destroy events
    },
    SingleVFX = {},
    GroupVFX = {},
    AuraVFX = {},
})

-- Add new client function for destroying aura
function VFXServ.Client:DestroyAura(player, character)
    local key = character:GetFullName()
    local data = self.Server.AuraVFX[key]
    if data then
        local auraFolder = data.folder
        self.Server.AuraVFX[key] = nil
        self.Server:DestroyAuraForAll(auraFolder, character)
    end
end

-- Add new server function to broadcast destroy
function VFXServ:DestroyAuraForAll(auraFolder, character)
    self.Client.DestroyVFXSignal:FireAll("Aura", auraFolder, character)
end

-- Helper function to generate keys
local function getKey(vfxName, instance)
    return vfxName .. "_" .. instance:GetFullName()
end

function VFXServ.Client:ValidateAura(_, auraFolder, character)
    local key = character:GetFullName()
    return self.Server.AuraVFX[key] ~= nil
end

-- Client exposed functions
function VFXServ.Client:PlaySingle(player, emitter, part)
    local key = getKey(emitter.Name, part)
    if not self.Server.SingleVFX[key] then
        self.Server.SingleVFX[key] = {
            emitter = emitter,
            part = part
        }
    end
    self.Server:PlaySingleForAll(emitter, part)
end

function VFXServ.Client:PlayGroup(player, vfxFolder, part)
    local key = getKey(vfxFolder.Name, part)
    if not self.Server.GroupVFX[key] then
        self.Server.GroupVFX[key] = {
            folder = vfxFolder,
            part = part
        }
    end
    self.Server:PlayGroupForAll(vfxFolder, part)
end

function VFXServ.Client:PlayAura(player, auraFolder, character)
    local key = character:GetFullName()
    if not self.Server.AuraVFX[key] then
        self.Server.AuraVFX[key] = {
            folder = auraFolder,
            character = character
        }
    end
    self.Server:PlayAuraForAll(auraFolder, character)
end

-- Server functions to broadcast to all clients
function VFXServ:PlaySingleForAll(emitter, part)
    self.Client.PlayVFXSignal:FireAll("Single", emitter, part)
end

function VFXServ:PlayGroupForAll(vfxFolder, part)
    self.Client.PlayVFXSignal:FireAll("Group", vfxFolder, part)
end

function VFXServ:PlayAuraForAll(auraFolder, character)
    self.Client.PlayVFXSignal:FireAll("Aura", auraFolder, character)
end

-- Cleanup functions
function VFXServ:CleanupVFX(instance)
    -- Cleanup singles
    for key, data in pairs(self.SingleVFX) do
        if key:find(instance:GetFullName()) then
            self.SingleVFX[key] = nil
        end
    end
    
    -- Cleanup groups
    for key, data in pairs(self.GroupVFX) do
        if key:find(instance:GetFullName()) then
            self.GroupVFX[key] = nil
        end
    end
    
    -- Cleanup auras
    if instance:IsA("Model") then
        self.AuraVFX[instance:GetFullName()] = nil
    end
end

function VFXServ:KnitStart()
    game.Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            self:CleanupVFX(player.Character)
        end
    end)
end

return VFXServ