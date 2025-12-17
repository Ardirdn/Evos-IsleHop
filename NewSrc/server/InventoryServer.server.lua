local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)

local FlyAbility = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FlyAbility"))

local FlyingToolCleanup = require(script.Parent.FlyingToolCleanup)

local function cleanupFlyingToolsBeforeSwitch(player, currentToolId)

	if currentToolId then
		local wasFlying = FlyingToolCleanup:CleanupByToolId(player, currentToolId)
		if wasFlying then
		end
	else

		FlyingToolCleanup:CleanupAll(player)
	end
end

local remoteFolder = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "InventoryRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getInventoryEvent = remoteFolder:FindFirstChild("GetInventory")
if not getInventoryEvent then
	getInventoryEvent = Instance.new("RemoteFunction")
	getInventoryEvent.Name = "GetInventory"
	getInventoryEvent.Parent = remoteFolder
end

local equipAuraEvent = remoteFolder:FindFirstChild("EquipAura")
if not equipAuraEvent then
	equipAuraEvent = Instance.new("RemoteEvent")
	equipAuraEvent.Name = "EquipAura"
	equipAuraEvent.Parent = remoteFolder
end

local unequipAuraEvent = remoteFolder:FindFirstChild("UnequipAura")
if not unequipAuraEvent then
	unequipAuraEvent = Instance.new("RemoteEvent")
	unequipAuraEvent.Name = "UnequipAura"
	unequipAuraEvent.Parent = remoteFolder
end

local equipToolEvent = remoteFolder:FindFirstChild("EquipTool")
if not equipToolEvent then
	equipToolEvent = Instance.new("RemoteEvent")
	equipToolEvent.Name = "EquipTool"
	equipToolEvent.Parent = remoteFolder
end

local unequipToolEvent = remoteFolder:FindFirstChild("UnequipTool")
if not unequipToolEvent then
	unequipToolEvent = Instance.new("RemoteEvent")
	unequipToolEvent.Name = "UnequipTool"
	unequipToolEvent.Parent = remoteFolder
end

local function findAuraTemplate(auraId)
	local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
	if not aurasFolder then return nil end

	local template = aurasFolder:FindFirstChild(auraId)
	if template then return template end

	local olderAuras = aurasFolder:FindFirstChild("OlderAuras")
	if olderAuras then
		template = olderAuras:FindFirstChild(auraId)
		if template then return template end
	end

	return nil
end

local function findToolTemplate(toolId)
	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then return nil end

	local template = toolsFolder:FindFirstChild(toolId)
	if template then return template end

	local shopTools = toolsFolder:FindFirstChild("ShopTools")
	if shopTools then
		template = shopTools:FindFirstChild(toolId)
		if template then return template end
	end

	local flyingTools = toolsFolder:FindFirstChild("FlyingTools")
	if flyingTools then
		template = flyingTools:FindFirstChild(toolId)
		if template then return template end
	end

	return nil
end

getInventoryEvent.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			OwnedAuras = {},
			OwnedTools = {},
			EquippedAura = nil,
			EquippedTool = nil
		}
	end

	return {
		OwnedAuras = data.OwnedAuras or {},
		OwnedTools = data.OwnedTools or {},
		EquippedAura = data.EquippedAura,
		EquippedTool = data.EquippedTool
	}
end

equipAuraEvent.OnServerEvent:Connect(function(player, auraId)
	if not player or not player.Parent then return end

	if not DataHandler:ArrayContains(player, "OwnedAuras", auraId) then
		NotificationService:Send(player, {
			Message = "You don't own this aura!",
			Type = "error",
			Duration = 3
		})
		return
	end

	DataHandler:Set(player, "EquippedAura", auraId)
	DataHandler:SavePlayer(player)

	if player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local oldAura = humanoidRootPart:FindFirstChild("EquippedAura")
			if oldAura then
				oldAura:Destroy()
			end

			local auraTemplate = findAuraTemplate(auraId)
			if auraTemplate then
				local auraClone = auraTemplate:Clone()
				auraClone.Name = "EquippedAura"
				auraClone.CFrame = humanoidRootPart.CFrame

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = humanoidRootPart
				weld.Part1 = auraClone
				weld.Parent = auraClone

				auraClone.Parent = humanoidRootPart

			else
				warn(string.format("⚠️ [INVENTORY SERVER] Aura template not found: %s", auraId))
			end
		end
	end

	NotificationService:Send(player, {
		Message = string.format("Equipped %s!", auraId),
		Type = "success",
		Duration = 3,
		Icon = "✨"
	})

end)

unequipAuraEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	DataHandler:Set(player, "EquippedAura", nil)
	DataHandler:SavePlayer(player)

	if player.Character then
		local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local equippedAura = humanoidRootPart:FindFirstChild("EquippedAura")
			if equippedAura then
				equippedAura:Destroy()
			end
		end
	end

	NotificationService:Send(player, {
		Message = "Aura unequipped",
		Type = "info",
		Duration = 3
	})

end)

equipToolEvent.OnServerEvent:Connect(function(player, toolId)
	if not player or not player.Parent then return end

	if not DataHandler:ArrayContains(player, "OwnedTools", toolId) then
		NotificationService:Send(player, {
			Message = "You don't own this tool!",
			Type = "error",
			Duration = 3
		})
		return
	end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		if player.Character.HumanoidRootPart:FindFirstChild("CarryWeld") then
			NotificationService:Send(player, {
				Message = "Cannot equip tools while being carried!",
				Type = "error",
				Duration = 2
			})
			return
		end
	end

	local toolTemplate = findToolTemplate(toolId)
	if not toolTemplate then
		warn(string.format("⚠️ [INVENTORY SERVER] Tool not found: %s", toolId))
		return
	end

	local currentToolId = DataHandler:Get(player, "EquippedTool")

	cleanupFlyingToolsBeforeSwitch(player, currentToolId)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:UnequipTools()
	end

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and child.Name ~= toolId then

				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					child.Parent = backpack
				end
			end
		end
	end

	if character then
		local toolClone = toolTemplate:Clone()
		toolClone.Parent = character
	end

	DataHandler:Set(player, "EquippedTool", toolId)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = string.format("Equipped %s!", toolId),
		Type = "success",
		Duration = 3,
		Icon = "🔧"
	})

end)

unequipToolEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	local currentToolId = DataHandler:Get(player, "EquippedTool")

	cleanupFlyingToolsBeforeSwitch(player, currentToolId)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:UnequipTools()
	end

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					child.Parent = backpack
				end
			end
		end
	end

	DataHandler:Set(player, "EquippedTool", nil)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = "Tool unequipped",
		Type = "info",
		Duration = 3
	})

end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)

		local data = DataHandler:GetData(player)
		if not data then return end

		if data.EquippedAura then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local auraTemplate = findAuraTemplate(data.EquippedAura)
				if auraTemplate then
					local auraClone = auraTemplate:Clone()
					auraClone.Name = "EquippedAura"
					auraClone.CFrame = humanoidRootPart.CFrame

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = humanoidRootPart
					weld.Part1 = auraClone
					weld.Parent = auraClone

					auraClone.Parent = humanoidRootPart

				end
			end
		end

		if data.EquippedTool then
			local toolTemplate = findToolTemplate(data.EquippedTool)
			if toolTemplate then
				local toolClone = toolTemplate:Clone()
				toolClone.Parent = character

			end
		end

	end)
end)
