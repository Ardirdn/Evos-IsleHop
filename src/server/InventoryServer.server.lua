local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Lazy-load FlyAbility agar tidak crash jika belum tersedia
local FlyAbility = nil
task.defer(function()
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules", 10):WaitForChild("FlyAbility", 10))
	end)
	if ok then FlyAbility = mod end
end)

local ADMIN_WING_CONFIG = {
	AccessoryName = "AdminWing",
	BoostSpeed = 16,
	FlightSpeed = 80,
	GyroP = 20000,
	AnimationId = "rbxassetid://111312412597365",
}

-- Tool-tool yang hanya boleh dimiliki oleh admin tertentu
-- Key: toolId, Value: fungsi pengecek izin (return true jika boleh)
local RESTRICTED_TOOLS = {
	AdminWing = function(userId)
		-- Hanya Owner, Primary Admin, dan Secondary Admin yang boleh punya AdminWing
		return TitleConfig.IsOwner(userId) or TitleConfig.IsFullAdmin(userId)
	end,
}

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

	-- Jika AdminWing, langsung notify FlyAbility dari server-side
	if toolId == "AdminWing" and FlyAbility then
		FlyAbility:SetToolEquipped(player, true, ADMIN_WING_CONFIG)
	end

	NotificationService:Send(player, {
		Message = string.format("Equipped %s!", toolId),
		Type = "success",
		Duration = 3,
		Icon = "🔧"
	})

end)

unequipToolEvent.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end

	-- Cek dulu tool yang sedang equipped sebelum di-unequip
	local currentTool = DataHandler:Get(player, "EquippedTool")

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

	-- Jika unequip AdminWing, hentikan flight
	if currentTool == "AdminWing" and FlyAbility then
		FlyAbility:SetToolEquipped(player, false)
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
			local toolId = data.EquippedTool

			-- Cek apakah tool ini hanya untuk admin tertentu
			local restrictionCheck = RESTRICTED_TOOLS[toolId]
			if restrictionCheck and not restrictionCheck(player.UserId) then
				-- Player tidak punya izin → hapus dari DataStore (cleanup data lama)
				warn(string.format(
					"[INVENTORY] ⚠️ %s tidak berhak punya '%s' — menghapus dari DataStore",
					player.Name, toolId
				))
				local index = table.find(data.OwnedTools or {}, toolId)
				if index then
					table.remove(data.OwnedTools, index)
					DataHandler:Set(player, "OwnedTools", data.OwnedTools)
				end
				DataHandler:Set(player, "EquippedTool", nil)
				DataHandler:SavePlayer(player)
				return -- Jangan spawn tool
			end

			local toolTemplate = findToolTemplate(toolId)
			if toolTemplate then
				local toolClone = toolTemplate:Clone()
				toolClone.Parent = character

				-- Jika AdminWing, notify FlyAbility dari server-side
				if toolId == "AdminWing" then
					task.delay(0.5, function() -- Kecil delay agar tool settle dulu
						if FlyAbility and player.Parent then
							FlyAbility:SetToolEquipped(player, true, ADMIN_WING_CONFIG)
						end
					end)
				end
			end
		end
	end)
end)
