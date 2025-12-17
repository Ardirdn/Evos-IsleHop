local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TitleServer)

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))

local purchaseHistory = {}

task.spawn(function()
	while true do
		task.wait(600)
		local count = 0
		for _ in pairs(purchaseHistory) do
			count = count + 1
		end
		if count > 0 then
			purchaseHistory = {}
		end
	end
end)

for i, pack in ipairs(ShopConfig.MoneyPacks) do
end

for i, pkg in ipairs(DonateConfig.Packages) do
end

local function sendDataUpdate(player)
	local data = DataHandler:GetData(player)
	if not data then return end

	local updateEvent = ReplicatedStorage:FindFirstChild("ShopRemotes"):FindFirstChild("UpdatePlayerData")
	if updateEvent then
		pcall(function()
			updateEvent:FireClient(player, {
				Money = data.Money,
				OwnedAuras = data.OwnedAuras,
				OwnedTools = data.OwnedTools,
			})
		end)
	end
end

local function updateDonationLeaderboard()
	local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
	if refreshEvent and refreshEvent:IsA("BindableEvent") then
		refreshEvent:Fire("Donation")
	end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId

	if purchaseHistory[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for _, package in ipairs(DonateConfig.Packages) do
		if package.ProductId == productId then

			local amount = package.Amount
			DataHandler:Increment(player, "TotalDonations", amount)
			local totalDonations = DataHandler:Get(player, "TotalDonations")
			DataHandler:SavePlayer(player)

			if totalDonations >= DonateConfig.DonationThreshold then
				TitleServer:GrantSpecialTitle(player, "Donatur")
				NotificationService:Send(player, {
					Message = "🎉 Kamu mendapatkan title 'Donatur'! Terima kasih!",
					Type = "success",
					Duration = 7,
					Icon = "💎"
				})
			else
				NotificationService:Send(player, {
					Message = string.format("Terima kasih telah donate R$%d! 💖", amount),
					Type = "success",
					Duration = 5,
					Icon = "💝"
				})
			end

			if DataHandler.UpdateLeaderboards then
				DataHandler:UpdateLeaderboards(player)
			end

			task.spawn(function()
				task.wait(1)
				updateDonationLeaderboard()
			end)

			purchaseHistory[purchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for i, pack in ipairs(ShopConfig.MoneyPacks) do
		if pack.ProductId == productId then

			local beforeMoney = DataHandler:Get(player, "Money") or 0

			local incrementSuccess = DataHandler:Increment(player, "Money", pack.MoneyReward)

			DataHandler:Increment(player, "TotalDonations", pack.Price)
			DataHandler:SavePlayer(player)

			local afterMoney = DataHandler:Get(player, "Money") or 0

			local totalDonations = DataHandler:Get(player, "TotalDonations")
			if totalDonations >= DonateConfig.DonationThreshold then
				TitleServer:GrantSpecialTitle(player, "Donatur")
			end

			NotificationService:Send(player, {
				Message = string.format("Received $%d! Thank you for supporting!", pack.MoneyReward),
				Type = "success",
				Duration = 5,
				Icon = "💰"
			})

			sendDataUpdate(player)
			purchaseHistory[purchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for _, aura in ipairs(ShopConfig.Auras) do
		if aura.IsPremium and aura.ProductId == productId then

			if not DataHandler:ArrayContains(player, "OwnedAuras", aura.AuraId) then
				DataHandler:AddToArray(player, "OwnedAuras", aura.AuraId)
				DataHandler:SavePlayer(player)

				NotificationService:Send(player, {
					Message = string.format("Purchased %s!", aura.Title),
					Type = "success",
					Duration = 5
				})

				sendDataUpdate(player)
			end

			purchaseHistory[purchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for _, tool in ipairs(ShopConfig.Tools) do
		if tool.IsPremium and tool.ProductId == productId then

			if not DataHandler:ArrayContains(player, "OwnedTools", tool.ToolId) then
				DataHandler:AddToArray(player, "OwnedTools", tool.ToolId)
				DataHandler:SavePlayer(player)

				NotificationService:Send(player, {
					Message = string.format("Purchased %s!", tool.Title),
					Type = "success",
					Duration = 5
				})

				sendDataUpdate(player)
			end

			purchaseHistory[purchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	if _G.SKIP_PRODUCT_ID and productId == _G.SKIP_PRODUCT_ID then

		if _G.ExecuteSkipCheckpoint then
			_G.ExecuteSkipCheckpoint(player)
		else
			warn("[MARKETPLACE] Skip function not found!")
		end

		purchaseHistory[purchaseId] = true
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	warn(string.format("⚠️ [MARKETPLACE] Unknown product ID: %d", productId))
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
