local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = {}
DataHandler.__index = DataHandler

local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local CONFIG = {
	DataStoreName = DataStoreConfig.PlayerData,
	AutoSaveInterval = DataStoreConfig.AutoSaveInterval,
	MaxRetries = DataStoreConfig.MaxRetries,
	RetryDelay = DataStoreConfig.RetryDelay,
}

local PlayerDataCache = {}
local SessionLocks = {}

local PlayerDataStore = DataStoreService:GetDataStore(CONFIG.DataStoreName)

local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

local function getDefaultData(userId)
	return {
		UserId = userId,

		Money = 0,
		TotalDonations = 0,

		OwnedAuras = {},
		OwnedTools = {},
		OwnedGamepasses = {},
		EquippedAura = nil,

		UnlockedTitles = {"Pendaki"},
		EquippedTitle = nil,

		Title = "Pendaki",
		TitleSource = "summit",
		SpecialTitle = nil,

		TotalSummits = 0,
		LastCheckpoint = 0,
		BestSpeedrun = nil,
		TotalPlaytime = 0,

		Clan = nil,

		FavoriteDances = {},

		FavoriteMusic = {},

		VibeTheme = nil,

		RedeemedCodes = {},

		FishInventory = {},
		TotalFishCaught = 0,
		DiscoveredFish = {},
		OwnedRods = {"WoodRod"},
		OwnedFloaters = {},
		EquippedRod = "WoodRod",
		EquippedFloater = nil,

		LegacyDataMigrated = false,
		MigrationDate = nil,

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

	if type(data.FishInventory) ~= "table" then data.FishInventory = {} end
	if type(data.TotalFishCaught) ~= "number" then data.TotalFishCaught = 0 end
	if type(data.DiscoveredFish) ~= "table" then data.DiscoveredFish = {} end
	if type(data.OwnedRods) ~= "table" then data.OwnedRods = {"WoodRod"} end
	if type(data.OwnedFloaters) ~= "table" then data.OwnedFloaters = {} end
	if data.EquippedRod == nil or data.EquippedRod == "" then data.EquippedRod = "WoodRod" end

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

	local SKIP_LEGACY_MIGRATION = false

	if SKIP_LEGACY_MIGRATION then

		if data.LegacyDataMigrated ~= true then
			data.LegacyDataMigrated = true
		end
	elseif data.LegacyDataMigrated ~= true then

		task.spawn(function()

			task.wait(10)

			if not player or not player.Parent then return end

			local DataMigration = require(script.Parent:FindFirstChild("DataMigration"))
			if DataMigration then
				local migrationSuccess = DataMigration:MigratePlayer(player, DataHandler)
				if migrationSuccess then

					local migratedData = PlayerDataCache[player]
					if migratedData then

						DataHandler:UpdateLeaderboards(player)

						local playerStats = player:FindFirstChild("PlayerStats")
						if playerStats then
							local summitValue = playerStats:FindFirstChild("Summit")
							if summitValue then
								summitValue.Value = migratedData.TotalSummits or 0
							end

							local playtimeValue = playerStats:FindFirstChild("Playtime")
							if playtimeValue and migratedData.TotalPlaytime then
								local minutes = math.floor(migratedData.TotalPlaytime / 60)
								local hours = math.floor(minutes / 60)
								if hours > 0 then
									playtimeValue.Value = string.format("%dh %dm", hours, minutes % 60)
								else
									playtimeValue.Value = string.format("%dm", minutes)
								end
							end
						end

						task.wait(0.5)

						local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")
						if syncEvent then
							syncEvent:Fire(player, {
								TotalSummits = migratedData.TotalSummits,
								TotalDonations = migratedData.TotalDonations,
								LastCheckpoint = migratedData.LastCheckpoint,
								BestSpeedrun = migratedData.BestSpeedrun,
								TotalPlaytime = migratedData.TotalPlaytime,
							})
						end
					else
						warn("[DATA HANDLER] PlayerDataCache[player] is nil!")
					end

					local TitleServerSuccess, TitleServerModule = pcall(function()
						return require(script.Parent:FindFirstChild("TitleServer"))
					end)
					if TitleServerSuccess and TitleServerModule and TitleServerModule.InitializePlayerPostMigration then
						TitleServerModule:InitializePlayerPostMigration(player)
					end
				else
					warn(string.format("⚠️ [DATA HANDLER] Migration failed for %s", player.Name))
				end
			else
				warn("[DATA HANDLER] DataMigration module not found!")
			end
		end)
	else
	end

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

function DataHandler:UpdateLeaderboards(player)
	local data = PlayerDataCache[player]
	if not data then return false end

	local userId = player.UserId
	local updated = {}

	if data.TotalSummits and data.TotalSummits > 0 then
		pcall(function()
			SummitLeaderboard:SetAsync(tostring(userId), data.TotalSummits)
			table.insert(updated, "Summit:" .. data.TotalSummits)
		end)
	end

	if data.TotalDonations and data.TotalDonations > 0 then
		pcall(function()
			DonationLeaderboard:SetAsync(tostring(userId), data.TotalDonations)
			table.insert(updated, "Donation:" .. data.TotalDonations)
		end)
	end

	if data.TotalPlaytime and data.TotalPlaytime > 0 then
		pcall(function()
			local playtimeInt = math.floor(data.TotalPlaytime)
			PlaytimeLeaderboard:SetAsync(tostring(userId), playtimeInt)
			table.insert(updated, "Playtime:" .. playtimeInt)
		end)
	end

	if data.BestSpeedrun and data.BestSpeedrun > 0 then
		pcall(function()
			local speedrunInt = -math.floor(data.BestSpeedrun)
			SpeedrunLeaderboard:SetAsync(tostring(userId), speedrunInt)
			table.insert(updated, "Speedrun:" .. data.BestSpeedrun)
		end)
	end

	if #updated > 0 then
	end

	return true
end

function DataHandler:GetConfig()
	return DataStoreConfig
end

function DataHandler:CleanupPlayer(player)
	local userId = player.UserId

	self:SavePlayer(player)

	PlayerDataCache[player] = nil
	SessionLocks[userId] = nil

end

task.spawn(function()
	while true do
		task.wait(CONFIG.AutoSaveInterval)

		local count = 0

		for player, _ in pairs(PlayerDataCache) do
			if player and player.Parent then
				DataHandler:SavePlayer(player)
				count = count + 1
			end
		end

	end
end)

game:BindToClose(function()

	for player, _ in pairs(PlayerDataCache) do
		if player and player.Parent then
			DataHandler:SavePlayer(player)
		end
	end

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

return DataHandler
