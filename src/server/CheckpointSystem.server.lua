--[[
    CHECKPOINT SYSTEM v4
    Includes Skip Checkpoint Handler
    Place in ServerScriptService
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local PhysicsService = game:GetService("PhysicsService")

CONFIG = {
	MONEY_PER_SUMMIT = 1000, -- Money diberikan saat mencapai puncak
	MONEY_PER_CHECKPOINT = 50, -- Money diberikan per checkpoint (jika DISTRIBUTE = false)
	DISTRIBUTE_MONEY_TO_CHECKPOINTS = true, -- Jika true, kasih money per checkpoint
	GIVE_SUMMIT_BONUS = true,  -- ✅ ENABLED: Bonus $1000 saat sampai puncak
	DISABLE_BODY_BLOCK = true, -- Set false untuk enable collision antar player
	SKIP_PRODUCT_ID = 3466042624, -- ✅ GANTI dengan Product ID kamu!
}

-- ✅ FIX: Setup collision groups for player-to-player no collision
local PLAYERS_COLLISION_GROUP = "NoPlayerCollision"

local function setupPlayerCollisionGroup()
	if not CONFIG.DISABLE_BODY_BLOCK then return end
	
	-- Try to create the collision group
	local success = pcall(function()
		PhysicsService:RegisterCollisionGroup(PLAYERS_COLLISION_GROUP)
	end)
	
	-- Set players to not collide with each other (whether new or existing group)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(PLAYERS_COLLISION_GROUP, PLAYERS_COLLISION_GROUP, false)
	end)
	
	print("✅ [COLLISION] NoPlayerCollision group setup complete")
end

-- ✅ Function to apply collision group to a character
local function applyNoCollisionToCharacter(character)
	if not CONFIG.DISABLE_BODY_BLOCK then return end
	if not character then return end
	
	local partCount = 0
	
	-- Apply to all existing parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = PLAYERS_COLLISION_GROUP
			partCount = partCount + 1
		end
	end
	
	-- Watch for new parts (like accessories loaded later)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = PLAYERS_COLLISION_GROUP
		end
	end)
	
	print(string.format("[NO COLLISION] Applied to %d parts for: %s", partCount, character.Name))
end

-- Run setup immediately
setupPlayerCollisionGroup()

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))
local CheckpointSystem = {}

-- ✅ Forward declarations (defined properly later, this silences LSP warnings)
local playerData = nil
local playerCurrentCheckpoint = nil

-- ✅ Export skip product ID to global
_G.SKIP_PRODUCT_ID = CONFIG.SKIP_PRODUCT_ID

-- ✅ CREATE BINDABLE EVENT FOR SYNC
local syncEvent = Instance.new("BindableEvent")
syncEvent.Name = "SyncPlayerDataEvent"
syncEvent.Parent = game.ServerScriptService

-- ✅ LISTEN FOR SYNC EVENT FROM DATAHANDLER (after migration)
local function setupSyncListener()
	syncEvent.Event:Connect(function(player, migratedData)
		if not player or not migratedData then return end
		
		local userId = player.UserId
		
		print(string.format("🔄 [CHECKPOINT SYNC] Received sync for %s", player.Name))
		print(string.format("   - TotalSummits: %d", migratedData.TotalSummits or 0))
		
		-- Update local playerData cache with migrated values
		if playerData and playerData[userId] then
			local oldSummits = playerData[userId].TotalSummits or 0
			
			playerData[userId].TotalSummits = migratedData.TotalSummits or playerData[userId].TotalSummits
			playerData[userId].TotalDonations = migratedData.TotalDonations or playerData[userId].TotalDonations
			playerData[userId].LastCheckpoint = migratedData.LastCheckpoint or playerData[userId].LastCheckpoint
			playerData[userId].BestSpeedrun = migratedData.BestSpeedrun or playerData[userId].BestSpeedrun
			playerData[userId].TotalPlaytime = migratedData.TotalPlaytime or playerData[userId].TotalPlaytime
			
			print(string.format("   ✅ Cache updated: TotalSummits %d → %d", 
				oldSummits, playerData[userId].TotalSummits))
			
			-- Update playerCurrentCheckpoint too
			if playerCurrentCheckpoint then
				playerCurrentCheckpoint[userId] = playerData[userId].LastCheckpoint
			end
			
			-- Update PlayerStats UI values
			local playerStats = player:FindFirstChild("PlayerStats")
			if playerStats then
				local summitsValue = playerStats:FindFirstChild("Summit")
				if summitsValue then
					summitsValue.Value = playerData[userId].TotalSummits
					print(string.format("   ✅ PlayerStats.Summit updated to %d", playerData[userId].TotalSummits))
				end
			end
		else
			warn(string.format("[CHECKPOINT SYNC] playerData[%d] not found for %s", userId, player.Name))
		end
	end)
	
	print("✅ [CHECKPOINT] SyncPlayerDataEvent listener ready")
end

-- DataStores (using centralized config)
local DataHandler = require(game.ServerScriptService:WaitForChild("DataHandler"))
local NotificationServer = require(game.ServerScriptService:WaitForChild("NotificationServer"))

-- ✅ USE CENTRALIZED DATASTORE CONFIG
local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)

local EventManager = nil
pcall(function()
	local EventManagerModule = game.ServerScriptService:WaitForChild("EventManager", 5)
	if EventManagerModule then
		EventManager = require(EventManagerModule)
		print("[CHECKPOINT] EventManager loaded")
	end
end)

if not EventManager then
	warn("[CHECKPOINT] EventManager not found - multipliers disabled")
end

local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)

print(string.format("[CHECKPOINT] Using DataStores from config (Version: %s)", DataStoreConfig.VERSION))

-- Get all checkpoints and sort them
local checkpointsFolder = workspace:FindFirstChild("Checkpoints")

if not checkpointsFolder then
	warn("[ERROR] Checkpoints folder tidak ditemukan di Workspace!")
	return
end

print("[CHECKPOINTS] Checkpoints folder found:", checkpointsFolder.Name)

local checkpoints = {}
local checkpointCount = 0

for _, checkpoint in pairs(checkpointsFolder:GetChildren()) do
	if checkpoint:IsA("BasePart") and checkpoint.Name:match("Checkpoint%d+") then
		local number = tonumber(checkpoint.Name:match("%d+"))
		checkpoints[number] = checkpoint
		checkpointCount = checkpointCount + 1
		print("[CHECKPOINTS] Found:", checkpoint.Name, "Number:", number, "Position:", checkpoint.Position)

		checkpoint.CanCollide = false

		local spawnLoc = checkpoint:FindFirstChild("SpawnLocation")
		if spawnLoc then
			print("[CHECKPOINTS] - SpawnLocation found in", checkpoint.Name)
		else
			warn("[WARNING] - SpawnLocation NOT FOUND in", checkpoint.Name)
		end
	end
end

print("[CHECKPOINTS] Total checkpoints loaded:", checkpointCount)
print("[CHECKPOINTS] Highest checkpoint number:", #checkpoints)

if checkpointCount == 0 then
	warn("[ERROR] Tidak ada checkpoint yang ditemukan! Pastikan nama part adalah 'Checkpoint0', 'Checkpoint1', dll")
	return
end

-- Player data storage (assigning to forward-declared variables)
playerData = {}
local speedrunTimers = {}
local playerCooldowns = {}
playerCurrentCheckpoint = {}
local playtimeSessions = {}
local playerReachedCheckpoints = {} -- ✅ NEW: Track which checkpoints were reached in current session
local playerConnections = {} -- ✅ FIX: Store connections for cleanup on player leave

-- ✅ NOW SETUP SYNC LISTENER (after playerData is defined)
setupSyncListener()

-- ✅ GAMEPASS CACHE to avoid repeated MarketplaceService calls (PERFORMANCE FIX)
local gamepassCache = {} -- { [userId] = { x2 = bool, x4 = bool, x16 = bool, timestamp = number } }
local GAMEPASS_CACHE_DURATION = 300 -- Refresh cache every 5 minutes

-- Remote Events untuk UI
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "CheckpointRemotes"
remoteFolder.Parent = ReplicatedStorage

local showSummitButton = Instance.new("RemoteEvent")
showSummitButton.Name = "ShowSummitButton"
showSummitButton.Parent = remoteFolder

local hideSummitButton = Instance.new("RemoteEvent")
hideSummitButton.Name = "HideSummitButton"
hideSummitButton.Parent = remoteFolder

local notifyPlayer = Instance.new("RemoteEvent")
notifyPlayer.Name = "NotifyPlayer"
notifyPlayer.Parent = remoteFolder

local teleportToBasecamp = Instance.new("RemoteEvent")
teleportToBasecamp.Name = "TeleportToBasecamp"
teleportToBasecamp.Parent = remoteFolder

-- ✅ NEW: Skip Checkpoint RemoteEvent
local skipCheckpoint = Instance.new("RemoteEvent")
skipCheckpoint.Name = "SkipCheckpoint"
skipCheckpoint.Parent = remoteFolder

print("[REMOTES] Remote events created in ReplicatedStorage")

-- NOTE: Leaderboard display updates are now handled by LeaderboardServer.server.lua
-- Leaderboards are in workspace.Leaderboards folder and support multiple copies

-- Function untuk format playtime
local function formatPlaytime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if days > 0 then
		return string.format("%dd %dh %dm", days, hours, minutes)
	elseif hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

-- Function untuk ubah warna circles di checkpoint
local function setCheckpointColor(checkpointNum, color)
	local checkpoint = checkpoints[checkpointNum]
	if not checkpoint then return end

	local spawnLocation = checkpoint:FindFirstChild("SpawnLocation")
	if not spawnLocation then return end

	-- Cari semua Circle di dalam SpawnLocation
	for _, child in pairs(spawnLocation:GetChildren()) do
		if child.Name == "Circle" then
			if child:IsA("BasePart") then
				child.Color = color
			elseif child:IsA("MeshPart") then
				child.Color = color
			end
		end
	end

	print(string.format("[CHECKPOINT COLOR] Set Checkpoint%d circles to RGB(%d, %d, %d)", 
		checkpointNum, color.R * 255, color.G * 255, color.B * 255))
end

-- Function untuk reset semua checkpoint ke putih
local function resetAllCheckpointColors(player)
	local userId = player.UserId

	-- ✅ FIXED: Tidak perlu check data, langsung reset
	-- Reset semua checkpoint ke putih
	for i = 1, #checkpoints do
		setCheckpointColor(i, Color3.fromRGB(255, 255, 255))
	end

	print("[CHECKPOINT COLOR] Reset all checkpoints to white for:", player.Name)
end


-- Function untuk load data player dari DataHandler
local function loadPlayerData(player)
	print(string.format("[DATA LOAD] Loading data for: %s", player.Name))
	local userId = player.UserId

	-- ✅ Initial delay to let DataHandler load first
	task.wait(1)

	-- ✅ WAIT FOR DATAHANDLER TO LOAD (with longer timeout)
	local maxRetries = 20  -- Increased from 10
	local retries = 0
	local data = nil

	while retries < maxRetries do
		data = DataHandler:GetData(player)
		if data then
			break
		end

		retries = retries + 1
		task.wait(0.5)
		if retries % 5 == 0 then  -- Only log every 5 retries to reduce spam
			print(string.format("[DATA LOAD] Retry %d/%d for %s...", retries, maxRetries, player.Name))
		end
	end

	if not data then
		warn(string.format("[DATA LOAD] Failed to get data from DataHandler after %d retries", maxRetries))
		return nil
	end

	-- Use data from DataHandler
	local checkpointData = {
		LastCheckpoint = data.LastCheckpoint or 0,
		TotalSummits = data.TotalSummits or 0,
		BestSpeedrun = data.BestSpeedrun,
		TotalPlaytime = data.TotalPlaytime or 0,
		CurrentSpeedrunStart = nil
	}

	print(string.format("[DATA LOAD] Loaded from DataHandler - Checkpoint: %d, Summits: %d", 
		checkpointData.LastCheckpoint, checkpointData.TotalSummits))

	playerData[userId] = checkpointData
	playerCurrentCheckpoint[userId] = checkpointData.LastCheckpoint

	-- Start playtime session
	playtimeSessions[userId] = {
		sessionStart = tick(),
		lastSave = tick()
	}

	return checkpointData
end

-- Function untuk save data via DataHandler
local function savePlayerData(player)
	local userId = player.UserId
	local data = playerData[userId]

	if not data then 
		warn("[DATA SAVE] No data to save for:", player.Name)
		return 
	end

	print("[DATA SAVE] Saving data for:", player.Name)

	-- Update DataHandler
	DataHandler:Set(player, "LastCheckpoint", data.LastCheckpoint)
	DataHandler:Set(player, "TotalSummits", data.TotalSummits)
	DataHandler:Set(player, "BestSpeedrun", data.BestSpeedrun)
	DataHandler:Set(player, "TotalPlaytime", data.TotalPlaytime)

	-- Save to DataStore
	DataHandler:SavePlayer(player)

	-- Update leaderboards (OrderedDataStore tetap terpisah untuk leaderboard)
	local success, err = pcall(function()
		SummitLeaderboard:SetAsync(tostring(userId), data.TotalSummits)
	end)

	if data.BestSpeedrun then
		pcall(function()
			local speedrunInt = math.floor(data.BestSpeedrun * 1000)
			SpeedrunLeaderboard:SetAsync(tostring(userId), -speedrunInt)
		end)
	end

	pcall(function()
		local playtimeInt = math.floor(data.TotalPlaytime)
		PlaytimeLeaderboard:SetAsync(tostring(userId), playtimeInt)
	end)

	print("[DATA SAVE] Saved via DataHandler")
end

local function updatePlaytime(player)
	local userId = player.UserId
	local data = playerData[userId]
	local session = playtimeSessions[userId]

	if not data or not session then return end

	local currentTime = tick()
	data.TotalPlaytime = data.TotalPlaytime + (currentTime - session.lastSave)
	session.lastSave = currentTime

	DataHandler:Set(player, "TotalPlaytime", data.TotalPlaytime)

	-- Update PlayerStats
	local playerStats = player:FindFirstChild("PlayerStats")
	if playerStats then
		local playtimeValue = playerStats:FindFirstChild("Playtime")
		if playtimeValue then
			playtimeValue.Value = formatPlaytime(data.TotalPlaytime)
		end
	end
end

-- Format waktu speedrun
local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)
	return string.format("%02d:%02d:%02d.%03d", hours, minutes, secs, ms)
end

-- NOTE: Leaderboard display updates are now handled by LeaderboardServer.server.lua
-- These stub functions maintain compatibility with existing calls
local function updateSummitLeaderboard()
	-- Handled by LeaderboardServer
end

local function updateSpeedrunLeaderboard()
	-- Handled by LeaderboardServer
end

local function updatePlaytimeLeaderboard()
	-- Handled by LeaderboardServer
end

local function updateLeaderboards()
	-- All leaderboard display updates are now handled by LeaderboardServer.server.lua
	-- This function is kept for backward compatibility
end

-- ✅ PERFORMANCE FIX: Cached gamepass lookup to avoid repeated MarketplaceService calls
local function getGamepassMultiplier(player)
	local userId = player.UserId
	local cached = gamepassCache[userId]
	local currentTime = tick()
	
	-- Check if cache is valid
	if cached and (currentTime - cached.timestamp) < GAMEPASS_CACHE_DURATION then
		return cached.multiplier
	end
	
	-- Fetch fresh data
	local multiplier = 1
	
	if ShopConfig.Gamepasses then
		-- Check x16 first (highest priority)
		for _, gp in ipairs(ShopConfig.Gamepasses) do
			if gp.Name == "x16 Summit" then
				local success, hasPass = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(userId, gp.GamepassId)
				end)
				if success and hasPass then
					multiplier = 16
					break
				end
			end
		end
		
		-- Check x4 if x16 not owned
		if multiplier == 1 then
			for _, gp in ipairs(ShopConfig.Gamepasses) do
				if gp.Name == "x4 Summit" then
					local success, hasPass = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(userId, gp.GamepassId)
					end)
					if success and hasPass then
						multiplier = 4
						break
					end
				end
			end
		end
		
		-- Check x2 if x4 not owned
		if multiplier == 1 then
			for _, gp in ipairs(ShopConfig.Gamepasses) do
				if gp.Name == "x2 Summit" then
					local success, hasPass = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(userId, gp.GamepassId)
					end)
					if success and hasPass then
						multiplier = 2
						break
					end
				end
			end
		end
	end
	
	-- Cache the result
	gamepassCache[userId] = {
		multiplier = multiplier,
		timestamp = currentTime
	}
	
	print(string.format("[GAMEPASS CACHE] Cached multiplier for %s: x%d", player.Name, multiplier))
	return multiplier
end


-- Player joined
Players.PlayerAdded:Connect(function(player)
	print("[PLAYER] Player joined:", player.Name, "UserID:", player.UserId)
	local data = loadPlayerData(player)

	-- ✅ FIX: Handle nil data gracefully - use defaults if loading fails
	if not data then
		warn(string.format("[PLAYER] Using default data for %s (DataHandler not ready)", player.Name))
		local userId = player.UserId
		data = {
			LastCheckpoint = 0,
			TotalSummits = 0,
			BestSpeedrun = nil,
			TotalPlaytime = 0,
		}
		playerData[userId] = data
		playerCurrentCheckpoint[userId] = 0
	end

	-- Setup PlayerStats (renamed from leaderstats to hide from Tab playerlist)
	-- Using "PlayerStats" instead of "leaderstats" so stats don't appear in Tab menu
	-- This keeps the data available for billboards and leaderboards
	local playerStats = Instance.new("Folder")
	playerStats.Name = "PlayerStats"
	playerStats.Parent = player

	local summitsValue = Instance.new("IntValue")
	summitsValue.Name = "Summit"
	summitsValue.Value = data.TotalSummits or 0
	summitsValue.Parent = playerStats

	local bestTimeValue = Instance.new("StringValue")
	bestTimeValue.Name = "Best Time"
	bestTimeValue.Value = data.BestSpeedrun and formatTime(data.BestSpeedrun / 1000) or "N/A"
	bestTimeValue.Parent = playerStats

	local playtimeValue = Instance.new("StringValue")
	playtimeValue.Name = "Playtime"
	playtimeValue.Value = formatPlaytime(data.TotalPlaytime or 0)
	playtimeValue.Parent = playerStats

	print("[PLAYER] PlayerStats created for:", player.Name)

	playerCooldowns[player.UserId] = {}

	-- Character spawning
	player.CharacterAdded:Connect(function(character)
		print("[SPAWN] Character spawned for:", player.Name)
		local humanoid = character:WaitForChild("Humanoid")
		task.wait(0.2)

		-- ✅ Apply no-collision between players
		applyNoCollisionToCharacter(character)

		-- ✅ AMBIL FRESH DATA DARI playerData
		local currentData = playerData[player.UserId]
		if not currentData then
			warn("[SPAWN] No data found for:", player.Name)
			return
		end

		local spawnCheckpoint = checkpoints[currentData.LastCheckpoint]
		if spawnCheckpoint then
			local spawnLocation = spawnCheckpoint:FindFirstChild("SpawnLocation")
			if spawnLocation then
				character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
				print("[SPAWN] Player spawned at checkpoint:", currentData.LastCheckpoint, "Position:", spawnLocation.Position)
				for i = 1, currentData.LastCheckpoint do
					setCheckpointColor(i, Color3.fromRGB(0, 255, 0))
				end
			else
				warn("[SPAWN] SpawnLocation not found in checkpoint:", currentData.LastCheckpoint)
			end
		else
			warn("[SPAWN] Checkpoint not found:", currentData.LastCheckpoint)
		end

		hideSummitButton:FireClient(player)

		if speedrunTimers[player.UserId] then
			speedrunTimers[player.UserId].active = false
			print("[SPEEDRUN] Timer reset for:", player.Name)
		end

		playerCooldowns[player.UserId] = {}
		playerCurrentCheckpoint[player.UserId] = currentData.LastCheckpoint
		print("[CHECKPOINT] Current checkpoint reset to:", currentData.LastCheckpoint)
	end)
end)

-- Setup checkpoint triggers dengan validasi sequential
print("[CHECKPOINTS] Setting up checkpoint triggers...")
for checkpointNum, checkpoint in pairs(checkpoints) do
	print("[CHECKPOINTS] Setting trigger for Checkpoint" .. checkpointNum)

	checkpoint.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local userId = player.UserId
		local data = playerData[userId]

		if not data then return end

		if not playerCooldowns[userId] then
			playerCooldowns[userId] = {}
		end

		local cooldownKey = "checkpoint" .. checkpointNum
		local lastTouch = playerCooldowns[userId][cooldownKey] or 0
		local currentTime = tick()

		-- ✅ FIX: Increased cooldown to 5 seconds to prevent multi-trigger
		if currentTime - lastTouch < 5 then
			return
		end

		playerCooldowns[userId][cooldownKey] = currentTime
		print("[CHECKPOINT HIT] Player", player.Name, "touched Checkpoint" .. checkpointNum)

		local currentCheckpoint = playerCurrentCheckpoint[userId] or 0
		local expectedCheckpoint = currentCheckpoint + 1

		if checkpointNum == 0 then
			if not speedrunTimers[userId] or not speedrunTimers[userId].active then
				speedrunTimers[userId] = {
					startTime = tick(),
					active = true,
					pausedTime = 0
				}
				print("[SPEEDRUN] Started for:", player.Name)
			else
				print("[SPEEDRUN] Already active for:", player.Name)
			end
			return
		end

		if checkpointNum > expectedCheckpoint then
			local message = "Kamu harus melewati Checkpoint " .. expectedCheckpoint .. " terlebih dahulu!"
			NotificationServer:Send(player, {
				Message = message,
				Type = "warning",
				Icon = "⚠️",
				Duration = 4
			})

			print("[VALIDATION] Player", player.Name, "tried to skip to checkpoint", checkpointNum, "- Expected:", expectedCheckpoint)
			return
		end

		-- ✅ FIX: Block if player already reached or passed this checkpoint
		if checkpointNum <= currentCheckpoint then
			print("[CHECKPOINT] Player", player.Name, "already passed checkpoint:", checkpointNum, "(current:", currentCheckpoint, ")")
			return
		end

		if checkpointNum < #checkpoints then
			data.LastCheckpoint = checkpointNum
			playerCurrentCheckpoint[userId] = checkpointNum
			savePlayerData(player)
			setCheckpointColor(checkpointNum, Color3.fromRGB(0, 255, 0))

			-- ✅ MONEY REWARD PER CHECKPOINT
			if CONFIG.DISTRIBUTE_MONEY_TO_CHECKPOINTS then
				local totalCheckpoints = #checkpoints - 2
				local moneyPerCheckpoint = math.floor(CONFIG.MONEY_PER_SUMMIT / totalCheckpoints)

				DataHandler:Increment(player, "Money", moneyPerCheckpoint)

				print(string.format("[CHECKPOINT] 💰 %s earned $%d at checkpoint %d (Total Money: $%d)", 
					player.Name, moneyPerCheckpoint, checkpointNum, DataHandler:Get(player, "Money") or 0))

				local checkpointMessage = string.format("Berhasil mencapai checkpoint %d, kamu mendapat $%d", checkpointNum, moneyPerCheckpoint)
				NotificationServer:Send(player, {
					Message = checkpointMessage,
					Type = "success",
					Icon = "✅",
					Duration = 3
				})

			else
				NotificationServer:Send(player, {
					Message = "Checkpoint " .. checkpointNum .. " tercapai!",
					Type = "info",
					Icon = "✅",
					Duration = 3
				})
			end

			print("[CHECKPOINT] Player", player.Name, "reached checkpoint:", checkpointNum)
		end

		if checkpointNum == #checkpoints then
			print("[SUMMIT] Player", player.Name, "reached summit!")

			-- Handle speedrun
			local speedrunTime = nil
			if speedrunTimers[userId] and speedrunTimers[userId].active then
				speedrunTime = tick() - speedrunTimers[userId].startTime
				speedrunTimers[userId].active = false

				print("[SPEEDRUN] Finished in:", formatTime(speedrunTime))

				local speedrunMs = math.floor(speedrunTime * 1000)
				if not data.BestSpeedrun or speedrunMs < data.BestSpeedrun then
					data.BestSpeedrun = speedrunMs
					local pStats = player:FindFirstChild("PlayerStats")
					if pStats and pStats:FindFirstChild("Best Time") then
						pStats["Best Time"].Value = formatTime(speedrunTime)
					end
					NotificationServer:Send(player, {
						Message = "NEW RECORD! Waktu terbaik: " .. formatTime(speedrunTime),
						Type = "success",
						Icon = "🏆",
						Duration = 5
					})
					print("[SPEEDRUN] NEW BEST TIME!")
				else
					NotificationServer:Send(player, {
						Message = "Kamu mencapai puncak dalam waktu " .. formatTime(speedrunTime),
						Type = "info",
						Icon = "⏱️",
						Duration = 4
					})
				end

			else
				print("[SPEEDRUN] Timer not active")
			end

			-- ✅ PERFORMANCE FIX: Use cached gamepass lookup instead of repeated API calls
			local gamepassMultiplier = getGamepassMultiplier(player)

			local eventMultiplier = 1
			if EventManager then
				eventMultiplier = EventManager:GetMultiplier()
			end

			local totalMultiplier = gamepassMultiplier * eventMultiplier
			local baseSummitValue = 1
			local finalSummitValue = baseSummitValue * totalMultiplier

			data.TotalSummits = data.TotalSummits + finalSummitValue
			local pStats = player:FindFirstChild("PlayerStats")
			if pStats and pStats:FindFirstChild("Summit") then
				pStats.Summit.Value = data.TotalSummits
			end

			DataHandler:Set(player, "TotalSummits", data.TotalSummits)

			if CONFIG.GIVE_SUMMIT_BONUS ~= false then
				local moneyReward = CONFIG.MONEY_PER_SUMMIT
				DataHandler:Increment(player, "Money", moneyReward)

				print(string.format("[SUMMIT] 💰 %s earned $%d bonus (Total Money: $%d)", 
					player.Name, moneyReward, DataHandler:Get(player, "Money") or 0))

				local summitMessage = string.format("🎉 Summit Reached! +$%d (Bonus)", moneyReward)
				if totalMultiplier > 1 then
					summitMessage = summitMessage .. string.format(" | +%d Summit (x%d)", finalSummitValue, totalMultiplier)
				else
					summitMessage = summitMessage .. " | +1 Summit"
				end
				NotificationServer:Send(player, {
					Message = summitMessage,
					Type = "success",
					Icon = "🎉",
					Duration = 5
				})
			else
				local summitMessage = "🎉 Summit Reached!"
				if totalMultiplier > 1 then
					summitMessage = summitMessage .. string.format(" +%d Summit (x%d)", finalSummitValue, totalMultiplier)
				else
					summitMessage = summitMessage .. " +1 Summit"
				end
				NotificationServer:Send(player, {
					Message = summitMessage,
					Type = "success",
					Icon = "🎉",
					Duration = 5
				})
			end

			-- Reset checkpoint
			data.LastCheckpoint = 0
			playerCurrentCheckpoint[userId] = 0

			resetAllCheckpointColors(player)

			savePlayerData(player)
			print("[SUMMIT] ✅ Data saved")

			task.spawn(function()
				task.wait(0.5)
				local TitleServer = require(script.Parent:WaitForChild("TitleServer"))
				TitleServer:UpdateSummitTitle(player)
				print("[SUMMIT] ✅ Title updated")
			end)

			task.spawn(function()
				task.wait(1)
				updateLeaderboards()
			end)

			showSummitButton:FireClient(player)
		end

	end)
end

print("[CHECKPOINTS] All checkpoint triggers setup complete!")

-- ✅ ==========================================
-- ✅ SKIP CHECKPOINT HANDLER (INTEGRATED)
-- ✅ ==========================================

-- Setup ProximityPrompt listeners for SkipBoard
for checkpointNum, checkpoint in pairs(checkpoints) do
	-- Skip last checkpoint (summit)
	if checkpointNum >= #checkpoints then
		continue
	end

	local skipBoard = checkpoint:FindFirstChild("SkipBoard")
	if not skipBoard then
		continue
	end

	local proximityPrompt = skipBoard:FindFirstChild("ProximityPrompt")
	if not proximityPrompt then
		continue
	end

	print("[SKIP] Setup prompt for Checkpoint" .. checkpointNum)

	proximityPrompt.Triggered:Connect(function(player)
		print(string.format("[SKIP] %s triggered skip at Checkpoint%d", player.Name, checkpointNum))

		local data = DataHandler:GetData(player)
		if not data then
			NotificationServer:Send(player, {
				Message = "Data not loaded!",
				Type = "error",
				Duration = 3
			})
			return
		end

		local currentCheckpoint = data.LastCheckpoint

		if currentCheckpoint ~= checkpointNum then
			NotificationServer:Send(player, {
				Message = "Kamu harus ada di checkpoint ini untuk skip!",
				Type = "warning",
				Duration = 3
			})
			print(string.format("[SKIP] Player at checkpoint %d, trying to skip %d", currentCheckpoint, checkpointNum))
			return
		end

		-- Prompt purchase
		MarketplaceService:PromptProductPurchase(player, CONFIG.SKIP_PRODUCT_ID)
	end)
end

-- Function to execute skip (called by MarketplaceHandler)
local function executeSkip(player)
	local character = player.Character
	if not character then return end

	local data = DataHandler:GetData(player)
	if not data then return end

	local currentCheckpoint = data.LastCheckpoint
	local nextCheckpoint = currentCheckpoint + 1

	-- Validate next checkpoint exists
	if not checkpoints[nextCheckpoint] then
		NotificationServer:Send(player, {
			Message = "Tidak ada checkpoint selanjutnya!",
			Type = "error",
			Duration = 3
		})
		return
	end

	-- Teleport to next checkpoint
	local spawnLocation = checkpoints[nextCheckpoint]:FindFirstChild("SpawnLocation")
	if spawnLocation then
		character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
	else
		character:MoveTo(checkpoints[nextCheckpoint].Position + Vector3.new(0, 5, 0))
	end

	-- Update player data
	DataHandler:Set(player, "LastCheckpoint", nextCheckpoint)

	-- ✅ SYNC KE playerData CACHE
	if playerData[player.UserId] then
		playerData[player.UserId].LastCheckpoint = nextCheckpoint
		playerCurrentCheckpoint[player.UserId] = nextCheckpoint
	end

	DataHandler:SavePlayer(player)

	NotificationServer:Send(player, {
		Message = string.format("🚀 Skipped to Checkpoint %d!", nextCheckpoint),
		Type = "success",
		Duration = 3,
		Icon = "⚡"
	})

	print(string.format("[SKIP] ✅ %s skipped from %d to %d", player.Name, currentCheckpoint, nextCheckpoint))
end

-- Export for MarketplaceHandler
_G.ExecuteSkipCheckpoint = function(player)
	executeSkip(player)
end

-- ✅ HANDLE SKIP VIA UI
skipCheckpoint.OnServerEvent:Connect(function(player)
	print(string.format("[SKIP UI] %s requested skip via UI", player.Name))

	local data = DataHandler:GetData(player)
	if not data then
		NotificationServer:Send(player, {
			Message = "Data not loaded!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local currentCheckpoint = data.LastCheckpoint

	-- ✅ VALIDATE: Cannot skip from summit or basecamp
	if currentCheckpoint == 0 then
		NotificationServer:Send(player, {
			Message = "Kamu tidak bisa skip dari basecamp!",
			Type = "warning",
			Duration = 3
		})
		return
	end

	if currentCheckpoint >= #checkpoints - 1 then
		NotificationServer:Send(player, {
			Message = "Tidak ada checkpoint selanjutnya!",
			Type = "warning",
			Duration = 3
		})
		return
	end

	-- Prompt purchase
	MarketplaceService:PromptProductPurchase(player, CONFIG.SKIP_PRODUCT_ID)
end)

print("✅ [SKIP CHECKPOINT] Handler integrated")

-- ✅ ==========================================
-- ✅ END SKIP CHECKPOINT HANDLER
-- ✅ ==========================================

-- Handle teleport ke basecamp
teleportToBasecamp.OnServerEvent:Connect(function(player)
	print("[TELEPORT] Player", player.Name, "requesting teleport to basecamp")
	local character = player.Character
	if not character then 
		warn("[TELEPORT] Character not found")
		return 
	end

	local userId = player.UserId
	local data = playerData[userId]

	-- ✅ RESET CHECKPOINT DATA
	if data then
		data.LastCheckpoint = 0
		playerCurrentCheckpoint[userId] = 0

		-- ✅ SAVE TO DATAHANDLER
		DataHandler:Set(player, "LastCheckpoint", 0)
		DataHandler:SavePlayer(player)

		print("[TELEPORT] Reset LastCheckpoint to 0 for:", player.Name)

		-- ✅ RESET CHECKPOINT COLORS
		resetAllCheckpointColors(player)
	end

	local basecamp = checkpoints[0]
	if basecamp then
		local spawnLocation = basecamp:FindFirstChild("SpawnLocation")
		if spawnLocation then
			character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
			hideSummitButton:FireClient(player)
			print("[TELEPORT] Player teleported to basecamp SpawnLocation")
		else
			character:MoveTo(basecamp.Position + Vector3.new(0, 5, 0))
			hideSummitButton:FireClient(player)
			warn("[TELEPORT] SpawnLocation not found, teleported to basecamp part position")
		end
	else
		warn("[TELEPORT] Basecamp checkpoint not found")
	end

	-- ✅ NOTIFY PLAYER
	NotificationServer:Send(player, {
		Message = "🏕️ Checkpoint reset! Kamu kembali ke basecamp.",
		Type = "info",
		Icon = "🏕️",
		Duration = 3
	})
end)


-- Save data saat player leaving
Players.PlayerRemoving:Connect(function(player)
	print("[PLAYER] Player leaving:", player.Name)

	local userId = player.UserId
	local data = playerData[userId]

	if data then
		updatePlaytime(player)

		print("[PLAYER LEAVE] Syncing with DataHandler cache...")

		local cachedSummits = DataHandler:Get(player, "TotalSummits")
		local cachedSpeedrun = DataHandler:Get(player, "BestSpeedrun")
		local cachedCheckpoint = DataHandler:Get(player, "LastCheckpoint")
		local cachedPlaytime = DataHandler:Get(player, "TotalPlaytime")

		if cachedSummits ~= nil then
			print(string.format("[PLAYER LEAVE] Using cached TotalSummits: %d (was: %d)", cachedSummits, data.TotalSummits))
			data.TotalSummits = cachedSummits
		end

		if cachedSpeedrun ~= nil then
			data.BestSpeedrun = cachedSpeedrun
		end

		if cachedCheckpoint ~= nil then
			data.LastCheckpoint = cachedCheckpoint
		end

		if cachedPlaytime ~= nil then
			data.TotalPlaytime = cachedPlaytime
		end

		savePlayerData(player)
		print("[PLAYER LEAVE] Data saved with synced values")
	else
		warn("[PLAYER LEAVE] No data found for:", player.Name)
	end

	-- Clear caches
	playerData[userId] = nil
	speedrunTimers[userId] = nil
	playerCooldowns[userId] = nil
	playerCurrentCheckpoint[userId] = nil
	playtimeSessions[userId] = nil
	gamepassCache[userId] = nil  -- ✅ Clear gamepass cache

	print("[PLAYER LEAVE] Cleanup complete for:", player.Name)
end)

-- Auto update playtime setiap 30 detik
task.spawn(function()
	while task.wait(30) do
		print("[PLAYTIME] Updating all player playtimes...")
		for _, player in pairs(Players:GetPlayers()) do
			updatePlaytime(player)
		end
	end
end)

-- Auto save dan update leaderboards
task.spawn(function()
	while task.wait(60) do
		print("[AUTO SAVE] Running auto-save...")
		for _, player in pairs(Players:GetPlayers()) do
			updatePlaytime(player)
			savePlayerData(player)
		end
		updateLeaderboards()
	end
end)

-- Initial leaderboard update
task.wait(2)
print("[INIT] Running initial leaderboard update...")
updateLeaderboards()

-- ✅ FUNCTION SYNC
function CheckpointSystem.SyncPlayerData(player)
	print(string.format("[CHECKPOINT SYNC] 🔄 Starting sync for %s", player.Name))

	local userId = player.UserId

	task.wait(0.3)

	local freshData = DataHandler:GetData(player)

	if not freshData then
		warn(string.format("[CHECKPOINT SYNC] ❌ Failed to get data for %s", player.Name))
		return false
	end

	print(string.format("[CHECKPOINT SYNC] Got data - Summits: %d", freshData.TotalSummits))

	if playerData[userId] then
		local oldSummits = playerData[userId].TotalSummits

		playerData[userId].TotalSummits = freshData.TotalSummits
		playerData[userId].LastCheckpoint = freshData.LastCheckpoint
		playerData[userId].BestSpeedrun = freshData.BestSpeedrun
		playerData[userId].TotalPlaytime = freshData.TotalPlaytime

		print(string.format("[CHECKPOINT SYNC] ✅ SUCCESS! %s: %d → %d", player.Name, oldSummits, freshData.TotalSummits))
		return true
	else
		playerData[userId] = {
			TotalSummits = freshData.TotalSummits,
			LastCheckpoint = freshData.LastCheckpoint,
			BestSpeedrun = freshData.BestSpeedrun,
			TotalPlaytime = freshData.TotalPlaytime
		}

		print(string.format("[CHECKPOINT SYNC] ✅ Created new cache for %s - Summits: %d", player.Name, freshData.TotalSummits))
		return true
	end
end

-- ✅ LISTEN TO SYNC EVENT
syncEvent.Event:Connect(function(player)
	print("[CHECKPOINT SYNC] Received sync request via BindableEvent")
	CheckpointSystem.SyncPlayerData(player)
end)

print("========================================")
print("CHECKPOINT SYSTEM FULLY LOADED!")
print("========================================")

return CheckpointSystem
