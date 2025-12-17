local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TitleServer)

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

local remoteFolder = ReplicatedStorage:FindFirstChild("ShopRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "ShopRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getShopDataEvent = remoteFolder:FindFirstChild("GetShopData")
if not getShopDataEvent then
	getShopDataEvent = Instance.new("RemoteFunction")
	getShopDataEvent.Name = "GetShopData"
	getShopDataEvent.Parent = remoteFolder
end

local purchaseItemEvent = remoteFolder:FindFirstChild("PurchaseItem")
if not purchaseItemEvent then
	purchaseItemEvent = Instance.new("RemoteEvent")
	purchaseItemEvent.Name = "PurchaseItem"
	purchaseItemEvent.Parent = remoteFolder
end

local purchaseGamepassEvent = remoteFolder:FindFirstChild("PurchaseGamepass")
if not purchaseGamepassEvent then
	purchaseGamepassEvent = Instance.new("RemoteEvent")
	purchaseGamepassEvent.Name = "PurchaseGamepass"
	purchaseGamepassEvent.Parent = remoteFolder
end

local purchaseMoneyPackEvent = remoteFolder:FindFirstChild("PurchaseMoneyPack")
if not purchaseMoneyPackEvent then
	purchaseMoneyPackEvent = Instance.new("RemoteEvent")
	purchaseMoneyPackEvent.Name = "PurchaseMoneyPack"
	purchaseMoneyPackEvent.Parent = remoteFolder
end

local updatePlayerDataEvent = remoteFolder:FindFirstChild("UpdatePlayerData")
if not updatePlayerDataEvent then
	updatePlayerDataEvent = Instance.new("RemoteEvent")
	updatePlayerDataEvent.Name = "UpdatePlayerData"
	updatePlayerDataEvent.Parent = remoteFolder
end

local function hasGamepass(userId, gamepassId)
	if not gamepassId or gamepassId == 0 then return false end

	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)

	return success and hasPass
end

local function sendDataUpdate(player)
	local data = DataHandler:GetData(player)
	if not data then return end

	pcall(function()
		updatePlayerDataEvent:FireClient(player, {
			Money = data.Money,
			OwnedAuras = data.OwnedAuras,
			OwnedTools = data.OwnedTools,
		})
	end)
end

getShopDataEvent.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			Money = 0,
			OwnedAuras = {},
			OwnedTools = {},
			OwnedGamepasses = {}
		}
	end

	local ownedGamepasses = {}
	if ShopConfig.Gamepasses then
		for _, gamepass in ipairs(ShopConfig.Gamepasses) do
			if hasGamepass(player.UserId, gamepass.GamepassId) then
				table.insert(ownedGamepasses, gamepass.Name)
			end
		end
	end

	return {
		Money = data.Money or 0,
		OwnedAuras = data.OwnedAuras or {},
		OwnedTools = data.OwnedTools or {},
		OwnedGamepasses = ownedGamepasses
	}
end

purchaseItemEvent.OnServerEvent:Connect(function(player, itemType, itemId, price, isPremium, productId)

	local arrayField = itemType == "Aura" and "OwnedAuras" or "OwnedTools"
	if DataHandler:ArrayContains(player, arrayField, itemId) then
		NotificationService:Send(player, {
			Message = "You already own this item!",
			Type = "error",
			Duration = 3
		})
		return
	end

	if isPremium then
		if not productId or productId == 0 then
			NotificationService:Send(player, {
				Message = "Invalid product ID!",
				Type = "error",
				Duration = 3
			})
			return
		end
		MarketplaceService:PromptProductPurchase(player, productId)
	else
		local currentMoney = DataHandler:Get(player, "Money") or 0

		if currentMoney >= price then
			DataHandler:Increment(player, "Money", -price)
			DataHandler:AddToArray(player, arrayField, itemId)
			DataHandler:SavePlayer(player)

			NotificationService:Send(player, {
				Message = string.format("Purchased %s for $%d!", itemId, price),
				Type = "success",
				Duration = 5,
				Icon = "✅"
			})

			sendDataUpdate(player)
		else
			NotificationService:Send(player, {
				Message = "Not enough money!",
				Type = "error",
				Duration = 3
			})
		end
	end
end)

purchaseGamepassEvent.OnServerEvent:Connect(function(player, gamepassName)

	local gamepassData = nil
	for _, gp in ipairs(ShopConfig.Gamepasses) do
		if gp.Name == gamepassName then
			gamepassData = gp
			break
		end
	end

	if not gamepassData then
		NotificationService:Send(player, {
			Message = "Invalid gamepass!",
			Type = "error"
		})
		return
	end

	if gamepassData.GamepassId == 0 then
		NotificationService:Send(player, {
			Message = "Gamepass ID not configured!",
			Type = "error"
		})
		return
	end

	MarketplaceService:PromptGamePassPurchase(player, gamepassData.GamepassId)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased then return end

	for _, gp in ipairs(ShopConfig.Gamepasses) do
		if gp.GamepassId == gamepassId then
			DataHandler:AddToArray(player, "OwnedGamepasses", gp.Name)

			if gp.Name ~= "x2 Summit" and gp.Name ~= "x4 Summit" then
				TitleServer:SetTitle(player, gp.Name, "gamepass", true)
			end

			DataHandler:SavePlayer(player)

			NotificationService:Send(player, {
				Message = string.format("You now have %s! 🎉", gp.DisplayName),
				Type = "success",
				Duration = 5,
				Icon = gp.Icon or "🌟"
			})

			sendDataUpdate(player)
			break
		end
	end
end)

purchaseMoneyPackEvent.OnServerEvent:Connect(function(player, productId)

	if productId == 0 then
		NotificationService:Send(player, {
			Message = "Product ID not configured!",
			Type = "error"
		})
		return
	end

	MarketplaceService:PromptProductPurchase(player, productId)
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		while player.Parent do
			task.wait(1)
			DataHandler:Increment(player, "Money", 1)
			sendDataUpdate(player)
		end
	end)
end)
