--// Author: 8ch99
--// Fast and secure zone module for roblox appliances
--// NOTE : Does not support CornerWedges (yet)

--[[

MIT License

Copyright (c) 2024 8ch99

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

--!native
--!optimize 2

local Signal = require(script.Signal)
--^ this can either be any signal module you prefer, or my one that comes with the package in the repo

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// cached players array
local CurrentPlayers = Players:GetPlayers()

local PlayerCache = {
	Data = CurrentPlayers,
	Size = #CurrentPlayers,
}

Players.PlayerAdded:Connect(function(Player)
	local Data = PlayerCache.Data
	if not table.find(Data, Player) then
		table.insert(Data, Player)
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	local Data = PlayerCache.Data
	local Index = table.find(Data, Player)
	if Index then
		table.remove(Data, Index)
	end
end)

CurrentPlayers = nil --// this gets GCed later but its here for good measure

--// dependency functions

local function IsInRange(Number: number, Range: number)
	if Range == 0 then
		return Number == 0
	end
	if Range < 0 then
		return math.clamp(Number, Range, -Range) == Number
	end
	return math.clamp(Number, -Range, Range) == Number
end

--// Enum.PartType.Ball
local function IsBoundInSphere(CFrame: CFrame, Size: Vector3, Position: Vector3)
	return (Position - CFrame.Position).Magnitude <= (math.min(Size.X, Size.Y, Size.Z) / 2)
end

--// Enum.PartType.Block
local function IsBoundInBox(CFrame: CFrame, Size: Vector3, Position: Vector3)
	Size /= 2
	local Position = CFrame:PointToObjectSpace(Position)
	return IsInRange(Position.X, Size.X) and IsInRange(Position.Y, Size.Y) and IsInRange(Position.Z, Size.Z)
end

--// Enum.PartType.Cylinder
local function IsBoundInCylinder(CFrame: CFrame, Size: Vector3, Position: Vector3)
	Size /= 2
	local Position = CFrame:PointToObjectSpace(Position)
	if IsInRange(Position.X, Size.X) then
		local PositionRelativeToCylinder = Vector2.new(Position.Y, Position.Z)
		local SizeRadius = math.min(Size.Y, Size.Z)
		return PositionRelativeToCylinder.Magnitude < SizeRadius
	end
	return false
end

--// Enum.PartType.Wedge
local function IsBoundInWedge(CFrame: CFrame, Size: Vector3, Position: Vector3)
	Size /= 2
	local Position = CFrame:PointToObjectSpace(Position)
	if IsInRange(Position.X, Size.X) and IsInRange(Position.Y, Size.Y) and IsInRange(Position.Z, Size.Z) then
		local SlopeHeightAtRelativePosition = Position.Z + Size.Z
		return Position.Y + Size.Y < SlopeHeightAtRelativePosition
	end
	return false
end

local PartTypeFunctions = {}
PartTypeFunctions.Ball = IsBoundInSphere
PartTypeFunctions.Block = IsBoundInBox
PartTypeFunctions.CornerWedge = IsBoundInBox --// temporarily overrides to this
PartTypeFunctions.Cylinder = IsBoundInCylinder
PartTypeFunctions.Wedge = IsBoundInWedge

--// @class Zone

local Zone = {}
Zone.__index = Zone

function Zone.new(CFrame: CFrame, Size: Size, Type: Enum.PartType)
	local self = setmetatable({}, Zone)
	self.CFrame = CFrame
	self.Size = Size
	self.Type = Type.Name
	return self
end

function Zone:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

--// @class ZoneController

local ZoneController = {}
ZoneController.__index = ZoneController

--// constructors

--// TODO: Create a blank identity zone controller
function ZoneController.new()
	local self = setmetatable({}, ZoneController)
	self.Enabled = false
	self.Zones = {}
	self.Players = {}
	self.PlayerEntered = Signal.new()
	self.PlayerExited = Signal.new()
	return self
end

--// TODO: Create a zone controller from a CFrame and Size
function ZoneController.fromCFrameAndSize(CFrame: CFrame, Size: Vector3, TypeOverride: Enum.PartType?)
	TypeOverride = TypeOverride or Enum.PartType.Block
	local self = ZoneController.new()
	table.insert(self.Zones, Zone.new(CFrame, Size, TypeOverride))
	self:Enable()
	return self
end

--// TODO: Create a zone controller from a Min and Max vector
--// its almost as if you were just creating a Region3, but its a zone system instead
function ZoneController.fromMinAndMax(Min: Vector3, Max: Vector3, TypeOverride: Enum.PartType?)
	return ZoneController.fromCFrameAndSize(CFrame.new((Min + Max) / 2), Max - Min, TypeOverride)
end

--// TODO: Create a zone controller based off an array containing one or more BaseParts
function ZoneController.fromPartArray(Array: { BasePart })
	local self = ZoneController.new()
	for _, v in Array do
		if v:IsA("BasePart") then
			table.insert(self.Zones, Zone.new(v.CFrame, v.Size, v.Shape))
		end
	end
	self:Enable()
	return self
end

--// TODO: Create a zone controller based off an instance containing one or more BaseParts
function ZoneController.fromPackage(Package: Instance)
	return ZoneController.fromPartArray(Package:GetChildren())
end

--// TODO: Create a zone controller based off an instance containing one or more BaseParts (using GetDescendants)
function ZoneController.fromPackageDescendants(Package: Instance)
	return ZoneController.fromPartArray(Package:GetDescendants())
end

--// TODO: Create a zone controller based off a BasePart
function ZoneController.fromBasePart(Part: BasePart)
	return ZoneController.fromCFrameAndSize(Part.CFrame, Part.Size, Part.Shape)
end

--// TODO: Create a zone controller based off the bounding box of a model
function ZoneController.fromModel(Model: Model, TypeOverride: Enum.PartType?)
	return ZoneController.fromCFrameAndSize(Model:GetBoundingBox(), TypeOverride)
end

--// TODO: Create a zone controller based off a Region3
function ZoneController.fromRegion3(Region: Region3, TypeOverride: Enum.PartType?)
	return ZoneController.fromCFrameAndSize(Region.CFrame, Region.Size, TypeOverride)
end

--// TODO: Create a zone controller based off a Region3int16
function ZoneController.fromRegion3int16(Region: Region3int16, TypeOverride: Enum.PartType?)
	return ZoneController.fromMinAndMax(Region.Min, Region.Max, TypeOverride)
end

--// TODO: Create a zone controller based off a Region3/Region3int16 array (can be any region3 variant)
function ZoneController.fromRegionArray(Array: { Region3 }, TypeOverride: Enum.PartType?)
	TypeOverride = TypeOverride or Enum.PartType.Block
	local self = ZoneController.new()
	for _, Region in Array do
		local Type = typeof(Region)
		local RegionZone = nil
		if Type == "Region3" then
			RegionZone = Zone.new(Region.CFrame, Region.Size, TypeOverride)
		elseif Type == "Region3int16" then
			RegionZone = Zone.new(CFrame.new((Region.Min + Region.Max) / 2), Region.Max - Region.Min, TypeOverride)
		end
		table.insert(self.Zones, RegionZone)
	end
	self:Enable()
	return self
end

--// object functions

function ZoneController:Enable()
	if self.Enabled then
		return
	end
	
	self.Enabled = true
	
	local Zones = self.Zones
	local ZonePlayers = self.Players
	local PlayerEntered = self.PlayerEntered
	local PlayerExited = self.PlayerExited
	
	self.RunnerThread = task.defer(function()
		while true do
			RunService.Heartbeat:Wait()
			for _, Player in PlayerCache.Data do
				local PlayerIsAlreadyBound = ZonePlayers[Player] ~= nil
				local Character = Player.Character
				local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
				--// remove players that were bound, but have no root/character
				if not HumanoidRootPart then
					if PlayerIsAlreadyBound then
						ZonePlayers[Player] = nil
						PlayerExited:Fire(Player)
					end
					continue
				end
				--// check all zones
				local Position = HumanoidRootPart.Position
				local PlayerIsBound = false
				for _, Zone in Zones do
					if PartTypeFunctions[Zone.Type](Zone.CFrame, Zone.Size, Position) then
						if not PlayerIsAlreadyBound then
							ZonePlayers[Player] = true
							PlayerEntered:Fire(Player)
						end
						PlayerIsBound = true
						break
					end
				end
				--// no longer bound? remove them
				if PlayerIsAlreadyBound and not PlayerIsBound then
					ZonePlayers[Player] = nil
					PlayerExited:Fire(Player)
				end
			end
		end
	end)
end

function ZoneController:Disable()
	if not self.Enabled then
		return
	end
	self.Enabled = false
	task.cancel(self.RunnerThread)
	self.RunnerThread = nil
	local ZonePlayers = self.Players
	local PlayerExited = self.PlayerExited
	for Player in ZonePlayers do
		ZonePlayers[Player] = nil
		PlayerExited:Fire(Player)
	end
end

function ZoneController:IsPositionBound(Position: Vector3)
	for _, Zone in self.Zones do
		if PartTypeFunctions[Zone.Type](Zone.CFrame, Zone.Size, Position) then
			return true
		end
	end
	return false
end

function ZoneController:IsPartBound(Object: BasePart)
	local Size = Object.Size
	local Position = Object.Position
	for _, Zone in self.Zones do
		if PartTypeFunctions[Zone.Type](Zone.CFrame, Zone.Size + Size, Position) then
			return true
		end
	end
	return false
end

function ZoneController:IsPlayerBound(Player: Player)
	return self.Players[Player] ~= nil
end

function ZoneController:GetPlayers()
	local Players = {}
	for Player in self.Players do
		table.insert(Players, Player)
	end
	return Players
end

function ZoneController:Destroy()
	self:Disable()
	self.PlayerEntered:Destroy()
	self.PlayerExited:Destroy()
	for _, Zone in self.Zones do
		Zone:Destroy()
	end
	table.clear(self.Zones)
	table.clear(self)
	setmetatable(self, nil)
end

return ZoneController
