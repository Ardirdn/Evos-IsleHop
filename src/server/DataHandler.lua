local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local DataHandler = {}
DataHandler.__index = DataHandler

local CONFIG = {
	AutoSaveInterval = DataStoreConfig.AutoSaveInterval or 300,
	MaxRetries = DataStoreConfig.MaxRetries or 5,  -- Increased from 3
	RetryDelay = DataStoreConfig.RetryDelay or 2,  -- Increased from 1
}

local PlayerDataCache = {}
local SessionLocks = {}
local LoadSuccessFlags = {}  -- Track jika load berhasil

local PlayerDataStore = DataStoreService:GetDataStore(DataStoreConfig.PlayerData)

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

-- Merge arrays without duplicates
local function mergeArrays(arr1, arr2)
	local result = {}
	local seen = {}
	
	for _, v in ipairs(arr1 or {}) do
		if not seen[tostring(v)] then
			table.insert(result, v)
			seen[tostring(v)] = true
		end
	end
	
	for _, v in ipairs(arr2 or {}) do
		if not seen[tostring(v)] then
			table.insert(result, v)
			seen[tostring(v)] = true
		end
	end
	
	return result
end

-- Safe merge: ambil nilai terbaik dari kedua data
local function safeMergeData(oldData, newData)
	if not oldData then return newData end
	if not newData then return oldData end
	
	local merged = {}
	
	-- Copy semua dari newData dulu
	for k, v in pairs(newData) do
		merged[k] = v
	end
	
	-- Untuk nilai numerik penting: ambil yang lebih tinggi
	merged.TotalSummits = math.max(oldData.TotalSummits or 0, newData.TotalSummits or 0)
	merged.TotalPlaytime = math.max(oldData.TotalPlaytime or 0, newData.TotalPlaytime or 0)
	merged.Money = math.max(oldData.Money or 0, newData.Money or 0)
	merged.TotalDonations = math.max(oldData.TotalDonations or 0, newData.TotalDonations or 0)
	
	-- Untuk BestSpeedrun: ambil yang lebih rendah (lebih cepat)
	if oldData.BestSpeedrun and newData.BestSpeedrun then
		merged.BestSpeedrun = math.min(oldData.BestSpeedrun, newData.BestSpeedrun)
	else
		merged.BestSpeedrun = oldData.BestSpeedrun or newData.BestSpeedrun
	end
	
	-- Untuk LastCheckpoint: ambil yang lebih tinggi
	merged.LastCheckpoint = math.max(oldData.LastCheckpoint or 0, newData.LastCheckpoint or 0)
	
	-- Untuk arrays: merge tanpa duplikat
	merged.OwnedAuras = mergeArrays(oldData.OwnedAuras, newData.OwnedAuras)
	merged.OwnedTools = mergeArrays(oldData.OwnedTools, newData.OwnedTools)
	merged.OwnedGamepasses = mergeArrays(oldData.OwnedGamepasses, newData.OwnedGamepasses)
	merged.UnlockedTitles = mergeArrays(oldData.UnlockedTitles, newData.UnlockedTitles)
	merged.FavoriteDances = mergeArrays(oldData.FavoriteDances, newData.FavoriteDances)
	merged.FavoriteMusic = mergeArrays(oldData.FavoriteMusic, newData.FavoriteMusic)
	merged.RedeemedCodes = mergeArrays(oldData.RedeemedCodes, newData.RedeemedCodes)
	
	-- FirstJoin: ambil yang lebih awal
	if oldData.FirstJoin and newData.FirstJoin then
		merged.FirstJoin = math.min(oldData.FirstJoin, newData.FirstJoin)
	else
		merged.FirstJoin = oldData.FirstJoin or newData.FirstJoin or os.time()
	end
	
	return merged
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
	local isNewPlayer = false

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
		-- PENTING: Jangan save jika load gagal!
		warn(string.format("❌ [DATA HANDLER] Failed to load data for %s after %d attempts - SAVE DISABLED", player.Name, CONFIG.MaxRetries))
		LoadSuccessFlags[userId] = false
		
		-- Beri player data default tapi JANGAN save
		data = getDefaultData(userId)
		PlayerDataCache[player] = data
		SessionLocks[userId] = true
		
		local moneyValue = Instance.new("IntValue")
		moneyValue.Name = "Money"
		moneyValue.Value = 0
		moneyValue.Parent = player
		
		return true  -- Return true agar player bisa main, tapi save disabled
	end

	-- Load berhasil
	LoadSuccessFlags[userId] = true
	
	if data == nil then
		-- Player baru
		isNewPlayer = true
		data = getDefaultData(userId)
		print(string.format("✅ [DATA HANDLER] New player %s - created default data", player.Name))
	else
		print(string.format("✅ [DATA HANDLER] Loaded data for %s - Summit:%d, Money:%d, Playtime:%d", 
			player.Name, data.TotalSummits or 0, data.Money or 0, math.floor(data.TotalPlaytime or 0)))
	end

	data = validateData(data, userId)
	PlayerDataCache[player] = data
	SessionLocks[userId] = true

	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = data.Money
	moneyValue.Parent = player

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
	
	-- PENTING: Jangan save jika load awal gagal
	if LoadSuccessFlags[userId] == false then
		warn(string.format("🚫 [DATA HANDLER] SAVE BLOCKED for %s - initial load failed", player.Name))
		return false
	end

	local success = false
	local errorMsg = nil

	-- Gunakan UpdateAsync untuk safe merge
	for attempt = 1, CONFIG.MaxRetries do
		success, errorMsg = pcall(function()
			PlayerDataStore:UpdateAsync(key, function(oldData)
				-- Merge data lama dengan data baru
				local mergedData = safeMergeData(oldData, data)
				return mergedData
			end)
		end)

		if success then
			print(string.format("✅ [DATA HANDLER] Saved data for %s - Summit:%d, Money:%d", 
				player.Name, data.TotalSummits or 0, data.Money or 0))
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

	-- Proteksi untuk field penting: jangan set ke nilai lebih rendah
	-- Note: TotalPlaytime tidak diproteksi di sini karena selalu di-update dari CheckpointSystem
	local protectedFields = {TotalSummits = true, Money = true}
	if protectedFields[field] and type(value) == "number" then
		local currentValue = PlayerDataCache[player][field] or 0
		if value < currentValue then
			warn(string.format("🚫 [DATA HANDLER] Blocked setting %s to lower value: %d -> %d", field, currentValue, value))
			return false
		end
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
	
	-- Jangan biarkan nilai negatif untuk field tertentu
	local nonNegativeFields = {TotalSummits = true, TotalPlaytime = true, Money = true}
	if nonNegativeFields[field] and newValue < 0 then
		warn(string.format("🚫 [DATA HANDLER] Blocked negative value for %s: %d", field, newValue))
		newValue = 0
	end
	
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
		return false  -- Already exists, not an error
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
		return false  -- Not found, not an error
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

function DataHandler:CleanupPlayer(player)
	local userId = player.UserId

	self:SavePlayer(player)

	PlayerDataCache[player] = nil
	SessionLocks[userId] = nil
	LoadSuccessFlags[userId] = nil  -- Cleanup flag

end

-- Auto-save loop
task.spawn(function()
	while true do
		task.wait(CONFIG.AutoSaveInterval)

		local count = 0

		for player, _ in pairs(PlayerDataCache) do
			if player and player.Parent then
				DataHandler:SavePlayer(player)
				count = count + 1
				task.wait(0.5)  -- Stagger saves untuk hindari throttle
			end
		end
		
		if count > 0 then
			print(string.format("💾 [DATA HANDLER] Auto-saved %d players", count))
		end

	end
end)

game:BindToClose(function()
	print("🔒 [DATA HANDLER] Server closing - saving all players...")
	
	local saveThreads = {}
	
	for player, _ in pairs(PlayerDataCache) do
		if player and player.Parent then
			local thread = task.spawn(function()
				DataHandler:SavePlayer(player)
			end)
			table.insert(saveThreads, thread)
		end
	end

	-- Tunggu lebih lama di production
	if RunService:IsStudio() then
		task.wait(2)
	else
		task.wait(10)  -- Lebih lama untuk memastikan semua save selesai
	end
	
	print("✅ [DATA HANDLER] Server close save complete")
end)

Players.PlayerAdded:Connect(function(player)
	DataHandler:LoadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataHandler:CleanupPlayer(player)
end)

return DataHandler
