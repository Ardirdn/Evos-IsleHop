local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local DataHandler = {}
DataHandler.__index = DataHandler

local CONFIG = {
	AutoSaveInterval = DataStoreConfig.AutoSaveInterval or 300,
	MaxRetries = DataStoreConfig.MaxRetries or 3,
	RetryDelay = DataStoreConfig.RetryDelay or 1,
}

local PlayerDataCache = {}
local SessionLocks = {}

local PlayerDataStore = DataStoreService:GetDataStore(DataStoreConfig.PlayerData)
print(string.format("✅ [DATA HANDLER] Using DataStore: %s", DataStoreConfig.PlayerData))

local function getDefaultData(userId)
	return {
		UserId = userId,

		Money = 0,
		TotalDonations = 0,

		OwnedAuras = {},
		OwnedTools = {},
		OwnedGamepasses = {},
		EquippedAura = nil,

		UnlockedTitles = {"Pengunjung"},
		EquippedTitle = nil,

		Title = "Pengunjung",
		TitleSource = "summit",
		SpecialTitle = nil,

		TotalSummits = 0,
		LastCheckpoint = 0,
		BestSpeedrun = nil,
		TotalPlaytime = 0,

		Clan = nil,

		FavoriteDances = {},

		FavoriteMusic = {},

		RedeemedCodes = {},

		FirstJoin = os.time(),
		LastJoin = os.time(),
		PlayTime = 0,
		DataVersion = 5,
	}
end

local function validateData(data, userId)
	if not data then
		return getDefaultData(userId)
	end

	local template = getDefaultData(userId)
	for key, defaultValue in pairs(template) do
		if data[key] == nil then
			data[key] = defaultValue
		end
	end

	if type(data.Money) ~= "number" then data.Money = 0 end
	if type(data.TotalDonations) ~= "number" then data.TotalDonations = 0 end
	if type(data.OwnedAuras) ~= "table" then data.OwnedAuras = {} end
	if type(data.OwnedTools) ~= "table" then data.OwnedTools = {} end
	if type(data.OwnedGamepasses) ~= "table" then data.OwnedGamepasses = {} end
	if type(data.FavoriteDances) ~= "table" then
		data.FavoriteDances = {}
	end
	if type(data.FavoriteMusic) ~= "table" then
		data.FavoriteMusic = {}
	end
	if type(data.RedeemedCodes) ~= "table" then
		data.RedeemedCodes = {}
	end

	data.LastJoin = os.time()

	return data
end

function DataHandler:LoadPlayer(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	if SessionLocks[userId] then
		warn(string.format("⚠️ [DATA HANDLER] Session lock active for %s", player.Name))
		player:Kick("Data session conflict. Please rejoin.")
		return false
	end

	print(string.format("📂 [DATA HANDLER] Loading data for %s...", player.Name))

	local data = nil
	local success = false

	for attempt = 1, CONFIG.MaxRetries do
		success, data = pcall(function()
			return PlayerDataStore:GetAsync(key)
		end)

		if success then
			break
		else
			warn(string.format("⚠️ [DATA HANDLER] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(data)))
			if attempt < CONFIG.MaxRetries then
				task.wait(CONFIG.RetryDelay * attempt)
			end
		end
	end

	if not success then
		warn(string.format("❌ [DATA HANDLER] Failed to load data for %s after %d attempts", player.Name, CONFIG.MaxRetries))
		data = nil
	end

	data = validateData(data, userId)
	PlayerDataCache[player] = data
	SessionLocks[userId] = true

	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = data.Money
	moneyValue.Parent = player

	print(string.format("✅ [DATA HANDLER] Loaded data for %s (Money: $%d, Title: %s)", player.Name, data.Money, data.Title))

	return true
end

function DataHandler:SavePlayer(player)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local userId = player.UserId
	local key = "Player_" .. userId
	local data = PlayerDataCache[player]

	print(string.format("💾 [DATA HANDLER] Saving data for %s...", player.Name))

	local success = false
	local errorMsg = nil

	for attempt = 1, CONFIG.MaxRetries do
		success, errorMsg = pcall(function()
			PlayerDataStore:SetAsync(key, data)
		end)

		if success then
			break
		else
			warn(string.format("⚠️ [DATA HANDLER] Save attempt %d failed for %s: %s", attempt, player.Name, tostring(errorMsg)))
			if attempt < CONFIG.MaxRetries then
				task.wait(CONFIG.RetryDelay * attempt)
			end
		end
	end

	if success then
		print(string.format("✅ [DATA HANDLER] Saved data for %s", player.Name))
		return true
	else
		warn(string.format("❌ [DATA HANDLER] Failed to save data for %s after %d attempts", player.Name, CONFIG.MaxRetries))
		return false
	end
end

function DataHandler:GetData(player)
	return PlayerDataCache[player]
end

function DataHandler:Set(player, field, value)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	PlayerDataCache[player][field] = value

	if field == "Money" then
		local moneyValue = player:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = value
		end
	end

	print(string.format("📝 [DATA HANDLER] Set %s.%s = %s", player.Name, field, tostring(value)))
	return true
end

function DataHandler:Get(player, field)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return nil
	end

	return PlayerDataCache[player][field]
end

function DataHandler:Increment(player, field, amount)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local currentValue = PlayerDataCache[player][field] or 0
	if type(currentValue) ~= "number" then
		warn(string.format("⚠️ [DATA HANDLER] Field %s is not a number", field))
		return false
	end

	local newValue = currentValue + amount
	PlayerDataCache[player][field] = newValue

	if field == "Money" then
		local moneyValue = player:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = newValue
		end
	end
	return true
end

function DataHandler:AddToArray(player, field, value)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local array = PlayerDataCache[player][field]
	if type(array) ~= "table" then
		warn(string.format("⚠️ [DATA HANDLER] Field %s is not an array", field))
		return false
	end

	if table.find(array, value) then
		warn(string.format("⚠️ [DATA HANDLER] Value already exists in %s.%s", player.Name, field))
		return false
	end

	table.insert(array, value)
	print(string.format("📝 [DATA HANDLER] Added %s to %s.%s", tostring(value), player.Name, field))
	return true
end

function DataHandler:RemoveFromArray(player, field, value)
	if not PlayerDataCache[player] then
		warn(string.format("⚠️ [DATA HANDLER] No cached data for %s", player.Name))
		return false
	end

	local array = PlayerDataCache[player][field]
	if type(array) ~= "table" then
		warn(string.format("⚠️ [DATA HANDLER] Field %s is not an array", field))
		return false
	end

	local index = table.find(array, value)
	if not index then
		warn(string.format("⚠️ [DATA HANDLER] Value not found in %s.%s", player.Name, field))
		return false
	end

	table.remove(array, index)
	print(string.format("📝 [DATA HANDLER] Removed %s from %s.%s", tostring(value), player.Name, field))
	return true
end

function DataHandler:ArrayContains(player, field, value)
	if not PlayerDataCache[player] then
		return false
	end

	local array = PlayerDataCache[player][field]
	if type(array) ~= "table" then
		return false
	end

	return table.find(array, value) ~= nil
end

function DataHandler:CleanupPlayer(player)
	local userId = player.UserId

	self:SavePlayer(player)

	PlayerDataCache[player] = nil
	SessionLocks[userId] = nil

	print(string.format("🧹 [DATA HANDLER] Cleaned up data for %s", player.Name))
end

task.spawn(function()
	while true do
		task.wait(CONFIG.AutoSaveInterval)

		print("💾 [DATA HANDLER] Auto-save started...")
		local count = 0

		for player, _ in pairs(PlayerDataCache) do
			if player and player.Parent then
				DataHandler:SavePlayer(player)
				count = count + 1
			end
		end

		print(string.format("✅ [DATA HANDLER] Auto-saved %d players", count))
	end
end)

game:BindToClose(function()
	print("🛑 [DATA HANDLER] Server shutting down, saving all data...")

	for player, _ in pairs(PlayerDataCache) do
		if player and player.Parent then
			DataHandler:SavePlayer(player)
		end
	end

	print("✅ [DATA HANDLER] All data saved on shutdown")

	if RunService:IsStudio() then
		task.wait(1)
	else
		task.wait(5)
	end
end)

Players.PlayerAdded:Connect(function(player)
	DataHandler:LoadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataHandler:CleanupPlayer(player)
end)

print("✅ [DATA HANDLER] System initialized")

return DataHandler