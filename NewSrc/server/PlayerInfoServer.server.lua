local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local VIPStore = DataStoreService:GetDataStore("VIPStatus_v1")

local PlayerInfoRemotes = ReplicatedStorage:WaitForChild("PlayerInfoRemotes", 10)
if not PlayerInfoRemotes then
	warn("❌ [PLAYER INFO SERVER] PlayerInfoRemotes not found - creating...")
	PlayerInfoRemotes = Instance.new("Folder")
	PlayerInfoRemotes.Name = "PlayerInfoRemotes"
	PlayerInfoRemotes.Parent = ReplicatedStorage
end

local GiveGamepassEvent = PlayerInfoRemotes:WaitForChild("GiveGamepass", 5)
if not GiveGamepassEvent then
	GiveGamepassEvent = Instance.new("RemoteEvent")
	GiveGamepassEvent.Name = "GiveGamepass"
	GiveGamepassEvent.Parent = PlayerInfoRemotes
end

GiveGamepassEvent.OnServerEvent:Connect(function(buyerPlayer, targetUserId, gamepassType)

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
	end)

	if not saveSuccess then
		warn("⚠️ Failed to save VIP status")
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then

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

			else
				warn("⚠️ Failed to set title")
			end
		end)
	else
	end
end)

local GiveItemEvent = PlayerInfoRemotes:FindFirstChild("GiveItem")
if not GiveItemEvent then
	GiveItemEvent = Instance.new("RemoteEvent")
	GiveItemEvent.Name = "GiveItem"
	GiveItemEvent.Parent = PlayerInfoRemotes
end

GiveItemEvent.OnServerEvent:Connect(function(buyerPlayer, targetUserId, rewardType, rewardId)

	if not buyerPlayer or not targetUserId or not rewardType or not rewardId then
		warn("⚠️ Invalid item gift request!")
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then

		if rewardType == "Aura" then

			local AuraStore = DataStoreService:GetDataStore("AuraData_v1")
			local saveSuccess = pcall(function()
				local currentData = AuraStore:GetAsync(tostring(targetUserId)) or {UnlockedAuras = {}}

				if not table.find(currentData.UnlockedAuras, rewardId) then
					table.insert(currentData.UnlockedAuras, rewardId)
					AuraStore:SetAsync(tostring(targetUserId), currentData)
				end
			end)

			local AuraRemotes = ReplicatedStorage:FindFirstChild("AuraRemotes")
			if AuraRemotes then
				local UnlockAuraEvent = AuraRemotes:FindFirstChild("UnlockAura")
				if UnlockAuraEvent then
					UnlockAuraEvent:FireClient(targetPlayer, rewardId)
				end
			end

		elseif rewardType == "Tool" then

			local tool = game:GetService("ServerStorage"):FindFirstChild(rewardId)

			if not tool then
				tool = ReplicatedStorage:FindFirstChild(rewardId)
			end

			if tool then
				local toolClone = tool:Clone()
				toolClone.Parent = targetPlayer.Backpack
			else
				warn("⚠️ Tool not found:", rewardId)
			end

		elseif rewardType == "Gamepass" then

		end

	else
	end
end)
