local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local VIPStore = DataStoreService:GetDataStore(DataStoreConfig.VIPStatus)

local PlayerInfoRemotes = ReplicatedStorage:WaitForChild("PlayerInfoRemotes")
local GiveGamepassEvent = PlayerInfoRemotes:WaitForChild("GiveGamepass")

GiveGamepassEvent.OnServerEvent:Connect(function(buyerPlayer, targetUserId, gamepassType)
	print("🎁 [SERVER] Gift request received!")
	print("  Buyer:", buyerPlayer.Name)
	print("  Target UserId:", targetUserId)
	print("  Type:", gamepassType)

	if not buyerPlayer or not targetUserId or not gamepassType then
		warn("⚠️ Invalid gift request!")
		return
	end

	local saveSuccess = pcall(function()
		local currentData = VIPStore:GetAsync(tostring(targetUserId)) or {}

		if gamepassType == "VIP" then
			currentData.HasVIP = true
			currentData.VIPGiftedBy = buyerPlayer.UserId
			currentData.VIPGiftedAt = os.time()
		elseif gamepassType == "VVIP" then
			currentData.HasVVIP = true
			currentData.VVIPGiftedBy = buyerPlayer.UserId
			currentData.VVIPGiftedAt = os.time()
		end

		VIPStore:SetAsync(tostring(targetUserId), currentData)
		print("✅ [SERVER] VIP status saved to DataStore")
	end)

	if not saveSuccess then
		warn("⚠️ Failed to save VIP status")
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then
		print("✅ [SERVER] Target player is ONLINE:", targetPlayer.Name)

		task.spawn(function()
			task.wait(0.5)

			local TitleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
			if not TitleRemotes then
				warn("⚠️ TitleRemotes not found!")
				return
			end

			local SetTitle = TitleRemotes:FindFirstChild("SetTitle")
			if not SetTitle then
				warn("⚠️ SetTitle RemoteFunction not found!")
				return
			end

			local titleName = gamepassType

			local setSuccess = pcall(function()
				SetTitle:InvokeClient(targetPlayer, titleName)
				print("✅ [SERVER] Title set to:", titleName)
			end)

			if setSuccess then
				local NotificationRemote = ReplicatedStorage:FindFirstChild("NotificationRemote")
				if NotificationRemote then
					NotificationRemote:FireClient(targetPlayer, {
						Title = "Gift Received!",
						Text = buyerPlayer.DisplayName .. " gave you " .. titleName .. "!",
						Duration = 5
					})
				end

				print("✅ [SERVER] Title assigned and notification sent")
			else
				warn("⚠️ Failed to set title")
			end
		end)
	else
		print("ℹ️ [SERVER] Target player is OFFLINE")
	end
end)

local GiveItemEvent = PlayerInfoRemotes:FindFirstChild("GiveItem")
if not GiveItemEvent then
	GiveItemEvent = Instance.new("RemoteEvent")
	GiveItemEvent.Name = "GiveItem"
	GiveItemEvent.Parent = PlayerInfoRemotes
	print("✅ [SERVER] GiveItem RemoteEvent created")
end

GiveItemEvent.OnServerEvent:Connect(function(buyerPlayer, targetUserId, rewardType, rewardId)
	print("🎁 [SERVER] Item gift request received!")
	print("  Buyer:", buyerPlayer.Name)
	print("  Target UserId:", targetUserId)
	print("  Type:", rewardType)
	print("  ID:", rewardId)

	if not buyerPlayer or not targetUserId or not rewardType or not rewardId then
		warn("⚠️ Invalid item gift request!")
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then
		print("✅ [SERVER] Target player is ONLINE:", targetPlayer.Name)

		if rewardType == "Aura" then
			print("🌟 [SERVER] Giving aura:", rewardId)

			local AuraStore = DataStoreService:GetDataStore(DataStoreConfig.AuraData)
			local saveSuccess = pcall(function()
				local currentData = AuraStore:GetAsync(tostring(targetUserId)) or {UnlockedAuras = {}}

				if not table.find(currentData.UnlockedAuras, rewardId) then
					table.insert(currentData.UnlockedAuras, rewardId)
					AuraStore:SetAsync(tostring(targetUserId), currentData)
					print("✅ [SERVER] Aura unlocked in DataStore")
				end
			end)

			local AuraRemotes = ReplicatedStorage:FindFirstChild("AuraRemotes")
			if AuraRemotes then
				local UnlockAuraEvent = AuraRemotes:FindFirstChild("UnlockAura")
				if UnlockAuraEvent then
					UnlockAuraEvent:FireClient(targetPlayer, rewardId)
					print("✅ [SERVER] Aura unlock event sent to client")
				end
			end

		elseif rewardType == "Tool" then
			print("⚔️ [SERVER] Giving tool:", rewardId)

			local tool = game:GetService("ServerStorage"):FindFirstChild(rewardId)

			if not tool then
				tool = ReplicatedStorage:FindFirstChild(rewardId)
			end

			if tool then
				local toolClone = tool:Clone()
				toolClone.Parent = targetPlayer.Backpack
				print("✅ [SERVER] Tool given to player")
			else
				warn("⚠️ Tool not found:", rewardId)
			end

		elseif rewardType == "Gamepass" then
			print("👑 [SERVER] Giving gamepass:", rewardId)
		end

	else
		print("ℹ️ [SERVER] Target player is OFFLINE")
	end
end)

print("✓ Player Info Server loaded successfully")