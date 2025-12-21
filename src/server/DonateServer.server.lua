local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

local remoteFolder = ReplicatedStorage:FindFirstChild("DonateRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "DonateRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getDonateDataFunc = remoteFolder:FindFirstChild("GetDonateData")
if not getDonateDataFunc then
	getDonateDataFunc = Instance.new("RemoteFunction")
	getDonateDataFunc.Name = "GetDonateData"
	getDonateDataFunc.Parent = remoteFolder
end

local purchaseDonationEvent = remoteFolder:FindFirstChild("PurchaseDonation")
if not purchaseDonationEvent then
	purchaseDonationEvent = Instance.new("RemoteEvent")
	purchaseDonationEvent.Name = "PurchaseDonation"
	purchaseDonationEvent.Parent = remoteFolder
end

getDonateDataFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			TotalDonations = 0,
			HasDonaturTitle = false
		}
	end

	local hasDonatur = data.TotalDonations >= DonateConfig.DonationThreshold

	return {
		TotalDonations = data.TotalDonations or 0,
		HasDonaturTitle = hasDonatur
	}
end

purchaseDonationEvent.OnServerEvent:Connect(function(player, productId)
	if not productId or productId == 0 then
		NotificationService:Send(player, {
			Message = "Product ID not configured!",
			Type = "error",
			Duration = 3
		})
		return
	end

	MarketplaceService:PromptProductPurchase(player, productId)
end)

local function updateDonationLeaderboard()
end

task.spawn(function()
	while task.wait(60) do
		updateDonationLeaderboard()
	end
end)

task.wait(3)
updateDonationLeaderboard()
