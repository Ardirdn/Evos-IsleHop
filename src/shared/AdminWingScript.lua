-- LocalScript di dalam Tool AdminWing
-- Kirim notifikasi ke SERVER via RemoteEvent agar server bisa set toolEquipped[player]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CONFIG = {
	AccessoryName = "AdminWing",
	BoostSpeed = 16,
	FlightSpeed = 80,
	GyroP = 20000,
	AnimationId = "rbxassetid://111312412597365",
}

local tool = script.Parent
local player = Players.LocalPlayer
local equipped = false

-- Tunggu remote tersedia
local equipNotifyRemote = ReplicatedStorage:WaitForChild("FlightEquipNotify", 10)

local function onEquipped()
	if equipped then return end
	equipped = true

	if equipNotifyRemote then
		equipNotifyRemote:FireServer(true, CONFIG)
	end
end

local function onUnequipped()
	if not equipped then return end
	equipped = false

	if equipNotifyRemote then
		equipNotifyRemote:FireServer(false, nil)
	end
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

