--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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
local Streamable = importPackage("Streamable").Streamable
local Modules = script.Modules

local VFXServ
local SingleEmitter = require(Modules.SingleEmitter)
local GroupEmitter = require(Modules.GroupEmitter)
local Aura = require(Modules.Aura)

local VFXCtrl = Knit.CreateController({
	Name = "VFXCtrl",
	SingleEmitters = {},
	GroupEmitters = {},
	CharacterAuras = {},
	StreamableCharacters = {}, -- New table to track character streamables
})

-- Helper function to generate unique keys
local function getKey(identifier, part)
	return tostring(identifier) .. "_" .. part:GetFullName()
end

-- Helper function to handle streamed character
function VFXCtrl:HandleStreamedCharacter(character, auraFolder)
	-- First validate if the aura is still valid on the server
	local isValid = VFXServ:ValidateAura(auraFolder, character)

	if isValid then
		-- If valid, play the aura
		self:PlayAura(auraFolder, character)
	else
		warn("Aura no longer valid for character:", character:GetFullName())
	end
end

function VFXCtrl:PlaySingle(emitter, part)
	local key = getKey(emitter, part)
	local singleEmitter = SingleEmitter.new(emitter, part)
	self.SingleEmitters[key] = self.SingleEmitters[key] or {}
	table.insert(self.SingleEmitters[key], singleEmitter)
	singleEmitter:play()
	return singleEmitter
end

function VFXCtrl:DestroySingle(emitter, part)
	local key = getKey(emitter, part)
	if self.SingleEmitters[key] then
		for _, instance in ipairs(self.SingleEmitters[key]) do
			instance:destroy()
		end
		self.SingleEmitters[key] = nil
	end
end

function VFXCtrl:PlayGroup(vfxFolder, part)
	local key = getKey(vfxFolder, part)
	if not self.GroupEmitters[key] then
		local groupEmitter = GroupEmitter.new(vfxFolder, part)
		self.GroupEmitters[key] = groupEmitter
		groupEmitter:play()
		return groupEmitter
	end
end

function VFXCtrl:DestroyGroup(vfxFolder, part)
	local key = getKey(vfxFolder, part)
	if self.GroupEmitters[key] then
		self.GroupEmitters[key]:destroy()
		self.GroupEmitters[key] = nil
	end
end

function VFXCtrl:PlayAura(auraFolder, character)
	if self.CharacterAuras[character] then
		self:DestroyAura(character)
	end

	local aura = Aura.new(auraFolder, character)
	self.CharacterAuras[character] = aura
	aura:play()
	return aura
end

function VFXCtrl:DestroyAura(character)
	if self.CharacterAuras[character] then
		self.CharacterAuras[character]:destroy()
		self.CharacterAuras[character] = nil
	end
end

-- Add cleanup for streamables
function VFXCtrl:CleanupPlayerVFX(player)
	-- Cleanup streamable
	local streamableKey = player.Character and player.Character:GetFullName()
	if streamableKey and self.StreamableCharacters[streamableKey] then
		self.StreamableCharacters[streamableKey]:Destroy()
		self.StreamableCharacters[streamableKey] = nil
	end

	-- Rest of existing cleanup code...
	for key, emitters in pairs(self.SingleEmitters) do
		if key:find(player.Name) then
			for _, emitter in ipairs(emitters) do
				emitter:destroy()
			end
			self.SingleEmitters[key] = nil
		end
	end

	for key, groupEmitter in pairs(self.GroupEmitters) do
		if key:find(player.Name) then
			groupEmitter:destroy()
			self.GroupEmitters[key] = nil
		end
	end

	if player.Character and self.CharacterAuras[player.Character] then
		self.CharacterAuras[player.Character]:destroy()
		self.CharacterAuras[player.Character] = nil
	end
end

-- VFXController Updates (Add these to your existing controller)
function VFXCtrl:PlayServerSingle(emitter, part)
	self:PlaySingle(emitter, part)
	return VFXServ:PlaySingle(emitter, part)
end

function VFXCtrl:PlayServerGroup(vfxFolder, part)
	self:PlayGroup(vfxFolder, part)
	return VFXServ:PlayGroup(vfxFolder, part)
end

function VFXCtrl:PlayServerAura(auraFolder)
	local character = Players.LocalPlayer.Character
	self:PlayAura(auraFolder, character)
	return VFXServ:PlayAura(auraFolder, character)
end

function VFXCtrl:HandleServerVFX(vfxType, ...)
	if vfxType == "Single" then
		self:PlaySingle(...)
	elseif vfxType == "Group" then
		self:PlayGroup(...)
	elseif vfxType == "Aura" then
		local auraFolder, character = ...

		-- Only handle streaming for other players' characters
		if character ~= Players.LocalPlayer.Character then
			local streamableKey = character:GetFullName()
			local characterStreamable = self.StreamableCharacters[streamableKey]

			if not characterStreamable then
				characterStreamable = Streamable.new(character, "HumanoidRootPart")
				self.StreamableCharacters[streamableKey] = characterStreamable

				-- Set up the observer
				characterStreamable:Observe(function(hrp, trove)
					print("Character streamed in:", character:GetFullName())

					-- Handle the streamed character
					self:HandleStreamedCharacter(character, auraFolder)

					-- Cleanup when the part is removed
					trove:Add(function()
						print("Character streamed out:", character:GetFullName())
						if self.CharacterAuras[character] then
							self:DestroyAura(auraFolder, character)
						end
					end)
				end)
			end

			-- If the character is already streamed in, play immediately
			if characterStreamable.Instance then
				self:HandleStreamedCharacter(character, auraFolder)
			end
		else
			-- For local player, just play the aura directly
			self:PlayAura(auraFolder, character)
		end
	end
end

-- Add to VFXController.lua
-- VFXController.lua changes
function VFXCtrl:DestroyServerAura()
	local character = Players.LocalPlayer.Character
	return VFXServ:DestroyAura(character)
end

function VFXCtrl:KnitInit()
	VFXServ = Knit.GetService("VFXServ")

	-- Listen for VFX play signals
	VFXServ.PlayVFXSignal:Connect(function(vfxType, ...)
		self:HandleServerVFX(vfxType, ...)
	end)

	-- Listen for VFX destroy signals
	VFXServ.DestroyVFXSignal:Connect(function(vfxType, ...)
		if vfxType == "Aura" then
			local _, character = ...

			-- If this is another player's character
			if character ~= Players.LocalPlayer.Character then
				-- Clean up streamable if it exists
				local streamableKey = character:GetFullName()
				local characterStreamable = self.StreamableCharacters[streamableKey]
				if characterStreamable then
					characterStreamable:Destroy()
					self.StreamableCharacters[streamableKey] = nil
				end

				-- Remove the aura if it's currently playing
				if self.CharacterAuras[character] then
					self:DestroyAura(character)
				end
			else
				-- For local player, just destroy the aura
				print("here")
				self:DestroyAura(character)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerVFX(player)
	end)
end

return VFXCtrl
