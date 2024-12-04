# rbx-zone
Fast and secure zone module for roblox appliances
# Some documentation
- Constructors:
```
for the constructor args, TypeOverride: Enum.PartType? (defaults to Enum.PartType.Block) is the part type you want your zone/zones to mimic
ZoneController.new() - @TODO: Create a blank identity zone controller
ZoneController.fromCFrameAndSize(CFrame: CFrame, Size: Vector3) - @TODO: Create a zone controller from a CFrame and Size
ZoneController.fromMinAndMax(Min: Vector3, Max: Vector3) - @TODO: Create a zone controller from a Min and Max vector
ZoneController.fromPartArray(Array: { BasePart }) - @TODO: Create a zone controller based off an array containing one or more BaseParts
ZoneController.fromPackage(Package: Instance) - @TODO: Create a zone controller based off an instance containing one or more BaseParts
ZoneController.fromPackageDescendants(Package: Instance) - @TODO: Create a zone controller based off an instance containing one or more BaseParts (using GetDescendants)
ZoneController.fromBasePart(Part: BasePart) - @TODO: Create a zone controller based off a BasePart
ZoneController.fromModel(Model: Model, TypeOverride: Enum.PartType?) - @TODO: Create a zone controller based off the bounding box of a model
ZoneController.fromRegion3(Region: Region3, TypeOverride: Enum.PartType?) - @TODO: Create a zone controller based off a Region3
ZoneController.fromRegion3int16(Region: Region3int16, TypeOverride: Enum.PartType?) - @TODO: Create a zone controller based off a Region3int16
ZoneController.fromRegionArray(Array: { Region3 }, TypeOverride: Enum.PartType?) - @TODO: Create a zone controller based off a Region3/Region3int16 array (can be any region3 variant)
```
- Properties
```
ZoneController.Enabled: boolean ("read only") - Whether the zone is enabled or not
ZoneController.Zones: { Zone } - The zone objects stored in the zone controller and are used by it
ZoneController.Players: { [Player]: boolean } - The current players that are bound in any zone
```
- Events
```
ZoneController.PlayerEntered - Fires whenever a player has entered the zone system
ZoneController.PlayerExited - Fires whenever a player has left the zone system
```
- Methods
```
ZoneController:Enable(): void - @TODO: Enables the zone controller
ZoneController:Disable(): void - @TODO: Disables the zone controller
ZoneController:IsPositionBound(Position: Vector3): boolean - @TODO: Returns whether the given position is bound in any zone in the zone system
ZoneController:IsPartBound(Part: BasePart): boolean - @TODO: Returns whether the given part is bound in any zone in the zone system
ZoneController:IsPlayerBound(Player: Player): boolean - @TODO: Returns whether the player is in the zone system or not
ZoneController:GetPlayers(): { Player } - @TODO: Returns an array of all bound players in the zone system
ZoneController:Destroy(): void - @TODO: Disables (if enabled) the zone controller and completely destroys it
```
# Example usage:
```lua
local Zone = require(game:GetService("ServerScriptService").Zone)
local DailyGiftZonePart = game:GetService("ServerStorage").DailyGiftZone

local DailyGiftZone = Zone.fromBasePart(DailyGiftZonePart)
DailyGiftZone.PlayerEntered:Connect(function(Player)
    --// pseudo code btw
    if not HasClaimedDailyGift(Player) then
        RewardDailyGift(Player)
    end
end)

local AntiSpawnkillZone = Zone.fromRegionArray({
    Region3.new(Vector3.new(-50, 0, -50), Vector3.new(50, 20, 50)),
    Region3.new(Vector3.new(-50, 100, -50), Vector3.new(50, 120, 50)),
})

AntiSpawnkillZone.PlayerEntered:Connect(function(Player)
    Player:SetAttribute("SpawnProtected", true)
end)

AntiSpawnkillZone.PlayerExited:Connect(function(Player)
    Player:SetAttribute("SpawnProtected", false)
end)
```
