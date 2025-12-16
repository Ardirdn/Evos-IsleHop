--[[
    INVENTORY SERVER (FIXED)
    Place in ServerScriptService/InventoryServer
    
    FIXES:
    - Block tool equip while being carried
    - Proper cleanup when switching tools (move to backpack instead of destroy)
    - Find tools/auras from subfolders
    - Handle duplicate tools
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)

-- Create RemoteEvents
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

-- ✅ Helper: Find aura in Auras folder (including OlderAuras subfolder)
local function findAuraTemplate(auraId)
	local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
	if not aurasFolder then return nil end
	
	-- First try direct child
	local template = aurasFolder:FindFirstChild(auraId)
	if template then return template end
	
	-- Then try OlderAuras subfolder (Crystal Event auras: Aura1-Aura8)
	local olderAuras = aurasFolder:FindFirstChild("OlderAuras")
	if olderAuras then
		template = olderAuras:FindFirstChild(auraId)
		if template then return template end
	end
	
	return nil
end

-- ✅ Helper: Find tool in Tools folder (including subfolders)
local function findToolTemplate(toolId)
	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then return nil end
	
	-- First try direct child
	local template = toolsFolder:FindFirstChild(toolId)
	if template then return template end
	
	-- Then try ShopTools subfolder (purchasable tools from shop)
	local shopTools = toolsFolder:FindFirstChild("ShopTools")
	if shopTools then
		template = shopTools:FindFirstChild(toolId)
		if template then return template end
	end
	
	-- Then try FlyingTools subfolder (FlyTogether Event tools: FlyingSpeed1-8)
	local flyingTools = toolsFolder:FindFirstChild("FlyingTools")
	if flyingTools then
		template = flyingTools:FindFirstChild(toolId)
		if template then return template end
	end
	
	return nil
end

print("✅ [INVENTORY SERVER] Initialized")

-- Get player inventory
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

-- Equip Aura
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

				print(string.format("✨ [INVENTORY SERVER] Applied aura visual: %s", auraId))
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

	print(string.format("✨ [INVENTORY SERVER] %s equipped aura: %s", player.Name, auraId))
end)

-- Unequip Aura
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
				print(string.format("✨ [INVENTORY SERVER] Removed aura visual from %s", player.Name))
			end
		end
	end

	NotificationService:Send(player, {
		Message = "Aura unequipped",
		Type = "info",
		Duration = 3
	})

	print(string.format("✨ [INVENTORY SERVER] %s unequipped aura", player.Name))
end)

-- ✅ FIXED: Equip Tool with carry check and proper cleanup
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

	-- ✅ Block tool equip while being carried
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

	-- ✅ UNEQUIP properly (don't destroy) - triggers Unequipped event
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	
	if humanoid then
		humanoid:UnequipTools()  -- This properly triggers Unequipped event on the tool
	end
	
	-- ✅ Move old tool to backpack instead of destroying (prevents lag)
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and child.Name ~= toolId then
				-- Move to backpack instead of destroy to prevent lag
				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					child.Parent = backpack
				end
			end
		end
	end

	-- ✅ Equip new tool
	if character then
		local toolClone = toolTemplate:Clone()
		toolClone.Parent = character  -- This triggers Equipped event
	end

	DataHandler:Set(player, "EquippedTool", toolId)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = string.format("Equipped %s!", toolId),
		Type = "success",
		Duration = 3,
		Icon = "🔧"
	})

	print(string.format("🔧 [INVENTORY SERVER] %s equipped tool: %s", player.Name, toolId))
end)


-- ✅ FIXED: Unequip Tool (move to backpack, NO destroy)
unequipToolEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	-- ✅ UNEQUIP properly (triggers Unequipped event)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	
	if humanoid then
		humanoid:UnequipTools()  -- Triggers Unequipped event, moves to Backpack
	end
	
	-- ✅ Move tool to backpack (NOT destroy - prevents lag)
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

	-- Clear equipped tool data
	DataHandler:Set(player, "EquippedTool", nil)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = "Tool unequipped",
		Type = "info",
		Duration = 3
	})

	print(string.format("🔧 [INVENTORY SERVER] %s unequipped tool", player.Name))
end)


-- ✅ FIXED: Reapply on respawn (combined aura + tool)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)

		local data = DataHandler:GetData(player)
		if not data then return end

		-- Reapply Aura
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

					print(string.format("✨ [INVENTORY SERVER] Reapplied aura on respawn: %s", data.EquippedAura))
				end
			end
		end

		-- Reapply Tool
		if data.EquippedTool then
			local toolTemplate = findToolTemplate(data.EquippedTool)
			if toolTemplate then
				local toolClone = toolTemplate:Clone()
				toolClone.Parent = character

				print(string.format("🔧 [INVENTORY SERVER] Reapplied tool on respawn: %s", data.EquippedTool))
			end
		end
	end)
end)

print("✅ [INVENTORY SERVER] System loaded")