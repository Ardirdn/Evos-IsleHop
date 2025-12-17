local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FlyAbility = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FlyAbility"))

local CONFIG = {
	AccessoryName = "AdminWing",
	BoostSpeed = 16,
	FlightSpeed = 80,
	GyroP = 20000,
	AnimationId = "rbxassetid://111312412597365",
}

local tool = script.Parent
local player = nil
local equipped = false

local function onEquipped()
	if equipped then return end
	equipped = true

	local character = tool.Parent
	player = Players:GetPlayerFromCharacter(character)

	if player then

		FlyAbility:OnEquip(player, CONFIG)
	end
end

local function onUnequipped()
	if not equipped then return end
	equipped = false

	if player then

		FlyAbility:OnUnequip(player)
	end
	player = nil
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)
