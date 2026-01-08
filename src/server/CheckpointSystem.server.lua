local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local PhysicsService = game:GetService("PhysicsService")

CONFIG = {
	MONEY_PER_SUMMIT = 1000,
	MONEY_PER_CHECKPOINT = 50,
	DISTRIBUTE_MONEY_TO_CHECKPOINTS = true,
	GIVE_SUMMIT_BONUS = true,
	DISABLE_BODY_BLOCK = true,
	SKIP_PRODUCT_ID = 3466042624,
}

local PLAYERS_COLLISION_GROUP = "NoPlayerCollision"

local function setupPlayerCollisionGroup()
	if not CONFIG.DISABLE_BODY_BLOCK then return end

	local success = pcall(function()
		PhysicsService:RegisterCollisionGroup(PLAYERS_COLLISION_GROUP)
	end)

	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(PLAYERS_COLLISION_GROUP, PLAYERS_COLLISION_GROUP, false)
	end)

end

local characterCollisionConnections = {}

local function applyNoCollisionToCharacter(character, player)
	if not CONFIG.DISABLE_BODY_BLOCK then return end
	if not character then return end

	local userId = player and player.UserId

	if userId and characterCollisionConnections[userId] then
		characterCollisionConnections[userId]:Disconnect()
		characterCollisionConnections[userId] = nil
	end

	local function applyCollisionGroup()
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = PLAYERS_COLLISION_GROUP
			end
		end
	end

	applyCollisionGroup()

	task.delay(0.5, applyCollisionGroup)
	task.delay(1.5, applyCollisionGroup)

	local conn = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = PLAYERS_COLLISION_GROUP
		end
	end)

	if userId then
		characterCollisionConnections[userId] = conn
	end
end

local function getDefaultSpawnPosition()
	if mainSpawnLocation then
		local spawnPart = mainSpawnLocation:FindFirstChild("SpawnLocation") or mainSpawnLocation
		if spawnPart:IsA("BasePart") then
			return spawnPart.Position + Vector3.new(0, 3, 0)
		elseif spawnPart:IsA("Model") and spawnPart.PrimaryPart then
			return spawnPart.PrimaryPart.Position + Vector3.new(0, 3, 0)
		end
	end

	local basecamp = checkpoints[0]
	if basecamp then
		local spawnLoc = basecamp:FindFirstChild("SpawnLocation")
		if spawnLoc then
			return spawnLoc.Position + Vector3.new(0, 3, 0)
		end
		return basecamp.Position + Vector3.new(0, 5, 0)
	end

	return Vector3.new(0, 50, 0)
end

setupPlayerCollisionGroup()

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))
local CheckpointSystem = {}

local playerData = nil
local playerCurrentCheckpoint = nil

_G.SKIP_PRODUCT_ID = CONFIG.SKIP_PRODUCT_ID

local syncEvent = Instance.new("BindableEvent")
syncEvent.Name = "SyncPlayerDataEvent"
syncEvent.Parent = game.ServerScriptService

local function setupSyncListener()
	syncEvent.Event:Connect(function(player, migratedData)
		if not player or not migratedData then return end

		local userId = player.UserId

		if playerData and playerData[userId] then
			local oldSummits = playerData[userId].TotalSummits or 0
			local oldPlaytime = playerData[userId].TotalPlaytime or 0

			-- PROTEKSI: Gunakan nilai yang lebih tinggi untuk Summit (jangan pernah turun)
			local newSummits = migratedData.TotalSummits or 0
			if newSummits > 0 or oldSummits > 0 then
				playerData[userId].TotalSummits = math.max(oldSummits, newSummits)
			end
			
			-- PROTEKSI: Gunakan nilai yang lebih tinggi untuk Playtime
			local newPlaytime = migratedData.TotalPlaytime or 0
			if newPlaytime > 0 or oldPlaytime > 0 then
				playerData[userId].TotalPlaytime = math.max(oldPlaytime, newPlaytime)
			end

			-- Untuk field lain, gunakan nilai baru jika ada
			playerData[userId].TotalDonations = migratedData.TotalDonations or playerData[userId].TotalDonations
			playerData[userId].LastCheckpoint = migratedData.LastCheckpoint or playerData[userId].LastCheckpoint
			playerData[userId].BestSpeedrun = migratedData.BestSpeedrun or playerData[userId].BestSpeedrun

			if playerCurrentCheckpoint then
				playerCurrentCheckpoint[userId] = playerData[userId].LastCheckpoint
			end

			local playerStats = player:FindFirstChild("PlayerStats")
			if playerStats then
				local summitsValue = playerStats:FindFirstChild("Summit")
				if summitsValue then
					summitsValue.Value = playerData[userId].TotalSummits
				end
			end
			
			-- Debug log
			if oldSummits ~= playerData[userId].TotalSummits then
				print(string.format("[CHECKPOINT SYNC] %s Summit: %d -> %d", player.Name, oldSummits, playerData[userId].TotalSummits))
			end
		else
			warn(string.format("[CHECKPOINT SYNC] playerData[%d] not found for %s", userId, player.Name))
		end
	end)

end


local DataHandler = require(game.ServerScriptService:WaitForChild("DataHandler"))
local NotificationServer = require(game.ServerScriptService:WaitForChild("NotificationServer"))

local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)

local EventManager = nil
pcall(function()
	local EventManagerModule = game.ServerScriptService:WaitForChild("EventManager", 5)
	if EventManagerModule then
		EventManager = require(EventManagerModule)
	end
end)

if not EventManager then
	warn("[CHECKPOINT] EventManager not found - multipliers disabled")
end


local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

local checkpointsFolder = workspace:FindFirstChild("Checkpoints")

if not checkpointsFolder then
	warn("[ERROR] Checkpoints folder tidak ditemukan di Workspace!")
	return
end


local mainSpawnLocation = checkpointsFolder:FindFirstChild("MainSpawnLocation")
if not mainSpawnLocation then
	warn("[WARNING] MainSpawnLocation not found in Checkpoints folder - will use Checkpoint0 SpawnLocation instead")
end

local deathTriggerFolder = checkpointsFolder:FindFirstChild("DeathTrigger")
local playerSwimmingMode = {}

local checkpoints = {}
local checkpointCount = 0

for _, checkpoint in pairs(checkpointsFolder:GetChildren()) do
	if checkpoint:IsA("BasePart") and checkpoint.Name:match("Checkpoint%d+") then
		local number = tonumber(checkpoint.Name:match("%d+"))
		checkpoints[number] = checkpoint
		checkpointCount = checkpointCount + 1

		checkpoint.CanCollide = false

		local spawnLoc = checkpoint:FindFirstChild("SpawnLocation")
		if spawnLoc then
		else
			warn("[WARNING] - SpawnLocation NOT FOUND in", checkpoint.Name)
		end
	end
end

if checkpointCount == 0 then
	warn("[ERROR] Tidak ada checkpoint yang ditemukan! Pastikan nama part adalah 'Checkpoint0', 'Checkpoint1', dll")
	return
end


playerData = {}
local speedrunTimers = {}
local playerCooldowns = {}
playerCurrentCheckpoint = {}
local playtimeSessions = {}
local playerReachedCheckpoints = {}
local playerConnections = {}

setupSyncListener()


local gamepassCache = {}
local GAMEPASS_CACHE_DURATION = 300

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

local skipCheckpoint = Instance.new("RemoteEvent")
skipCheckpoint.Name = "SkipCheckpoint"
skipCheckpoint.Parent = remoteFolder

local toggleSwimmingMode = Instance.new("RemoteEvent")
toggleSwimmingMode.Name = "ToggleSwimmingMode"
toggleSwimmingMode.Parent = remoteFolder

local teleportToLastCheckpoint = Instance.new("RemoteEvent")
teleportToLastCheckpoint.Name = "TeleportToLastCheckpoint"
teleportToLastCheckpoint.Parent = remoteFolder

local getSwimmingStatus = Instance.new("RemoteFunction")
getSwimmingStatus.Name = "GetSwimmingStatus"
getSwimmingStatus.Parent = remoteFolder

local swimmingModeChanged = Instance.new("RemoteEvent")
swimmingModeChanged.Name = "SwimmingModeChanged"
swimmingModeChanged.Parent = remoteFolder



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

local function setCheckpointColor(checkpointNum, color)
	local checkpoint = checkpoints[checkpointNum]
	if not checkpoint then return end

	local spawnLocation = checkpoint:FindFirstChild("SpawnLocation")
	if not spawnLocation then return end

	for _, child in pairs(spawnLocation:GetChildren()) do
		if child.Name == "Circle" then
			if child:IsA("BasePart") then
				child.Color = color
			elseif child:IsA("MeshPart") then
				child.Color = color
			end
		end
	end

end

local function resetAllCheckpointColors(player)
	local userId = player.UserId

	for i = 1, #checkpoints do
		setCheckpointColor(i, Color3.fromRGB(255, 255, 255))
	end

end

local function loadPlayerData(player)
	local userId = player.UserId

	task.wait(1)

	local maxRetries = 20
	local retries = 0
	local data = nil

	while retries < maxRetries do
		data = DataHandler:GetData(player)
		if data then
			break
		end

		retries = retries + 1
		task.wait(0.5)
		if retries % 5 == 0 then
		end
	end

	if not data then
		warn(string.format("[DATA LOAD] Failed to get data from DataHandler after %d retries", maxRetries))
		return nil
	end

	local checkpointData = {
		LastCheckpoint = data.LastCheckpoint or 0,
		TotalSummits = data.TotalSummits or 0,
		BestSpeedrun = data.BestSpeedrun,
		TotalPlaytime = data.TotalPlaytime or 0,
		CurrentSpeedrunStart = nil
	}

	playerData[userId] = checkpointData
	playerCurrentCheckpoint[userId] = checkpointData.LastCheckpoint

	playtimeSessions[userId] = {
		sessionStart = tick(),
		lastSave = tick()
	}

	return checkpointData
end

local function savePlayerData(player)
	local userId = player.UserId
	local data = playerData[userId]

	if not data then
		warn("[DATA SAVE] No data to save for:", player.Name)
		return
	end

	-- PROTEKSI: Periksa DataHandler untuk nilai yang lebih tinggi sebelum save
	local handlerSummits = DataHandler:Get(player, "TotalSummits") or 0
	local handlerPlaytime = DataHandler:Get(player, "TotalPlaytime") or 0
	
	-- Gunakan nilai tertinggi antara cache dan DataHandler
	local finalSummits = math.max(data.TotalSummits or 0, handlerSummits)
	local finalPlaytime = math.max(data.TotalPlaytime or 0, handlerPlaytime)
	
	-- Update data cache dengan nilai tertinggi
	data.TotalSummits = finalSummits
	data.TotalPlaytime = finalPlaytime
	
	-- Debug log jika ada perbedaan
	if finalSummits ~= handlerSummits then
		print(string.format("[DATA SAVE] %s Summit protection: cache=%d, handler=%d, saving=%d", 
			player.Name, data.TotalSummits or 0, handlerSummits, finalSummits))
	end

	DataHandler:Set(player, "LastCheckpoint", data.LastCheckpoint)
	DataHandler:Set(player, "TotalSummits", finalSummits)
	DataHandler:Set(player, "BestSpeedrun", data.BestSpeedrun)
	DataHandler:Set(player, "TotalPlaytime", finalPlaytime)

	DataHandler:SavePlayer(player)

	-- Save ke Summit Leaderboard (hanya jika > 0)
	if finalSummits > 0 then
		local success, err = pcall(function()
			SummitLeaderboard:SetAsync(tostring(userId), finalSummits)
		end)
		if success then
			print(string.format("[DATA SAVE] %s Summit leaderboard updated: %d", player.Name, finalSummits))
		end
	end

	if data.BestSpeedrun then
		pcall(function()
			local speedrunInt = math.floor(data.BestSpeedrun * 1000)
			SpeedrunLeaderboard:SetAsync(tostring(userId), -speedrunInt)
		end)
	end

	-- Save ke Playtime Leaderboard (hanya jika > 0)
	if finalPlaytime > 0 then
		pcall(function()
			local playtimeInt = math.floor(finalPlaytime)
			PlaytimeLeaderboard:SetAsync(tostring(userId), playtimeInt)
		end)
		print(string.format("[DATA SAVE] %s Playtime leaderboard updated: %d seconds", player.Name, math.floor(finalPlaytime)))
	end

	-- Sync donation leaderboard
	if data.TotalDonations and data.TotalDonations > 0 then
		pcall(function()
			DonationLeaderboard:SetAsync(tostring(userId), data.TotalDonations)
		end)
	end

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

	local playerStats = player:FindFirstChild("PlayerStats")
	if playerStats then
		local playtimeValue = playerStats:FindFirstChild("Playtime")
		if playtimeValue then
			playtimeValue.Value = formatPlaytime(data.TotalPlaytime)
		end
	end
end

local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)
	return string.format("%02d:%02d:%02d.%03d", hours, minutes, secs, ms)
end

local function updateSummitLeaderboard()
	local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
	if refreshEvent then
		print("[LEADERBOARD UPDATE] Triggering Summit leaderboard refresh")
		refreshEvent:Fire("Summit")
	end
end

local function updateSpeedrunLeaderboard()
	local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
	if refreshEvent then
		print("[LEADERBOARD UPDATE] Triggering Speedrun leaderboard refresh")
		refreshEvent:Fire("Speedrun")
	end
end

local function updatePlaytimeLeaderboard()
	local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
	if refreshEvent then
		print("[LEADERBOARD UPDATE] Triggering Playtime leaderboard refresh")
		refreshEvent:Fire("Playtime")
	end
end

local function updateLeaderboards()
	local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
	if refreshEvent then
		print("[LEADERBOARD UPDATE] Triggering ALL leaderboards refresh")
		refreshEvent:Fire("All")
	end
end

local function getGamepassMultiplier(player)
	local userId = player.UserId
	local cached = gamepassCache[userId]
	local currentTime = tick()

	if cached and (currentTime - cached.timestamp) < GAMEPASS_CACHE_DURATION then
		return cached.multiplier
	end

	local multiplier = 1

	if ShopConfig.Gamepasses then
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

	gamepassCache[userId] = {
		multiplier = multiplier,
		timestamp = currentTime
	}

	return multiplier
end


Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)

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
	else
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local summitStat = Instance.new("IntValue")
	summitStat.Name = "Summit"
	summitStat.Value = data.TotalSummits or 0
	summitStat.Parent = leaderstats

	local cpStat = Instance.new("IntValue")
	cpStat.Name = "CP"
	cpStat.Value = data.LastCheckpoint or 0
	cpStat.Parent = leaderstats

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

	playerCooldowns[player.UserId] = {}

	-- Sync donation to leaderboard if player has donations
	task.spawn(function()
		task.wait(2) -- Wait for DataHandler to fully load
		local handlerData = DataHandler:GetData(player)
		print(string.format("[DONATION SYNC] Player %s - handlerData exists: %s", 
			player.Name, tostring(handlerData ~= nil)))
		
		if handlerData then
			print(string.format("[DONATION SYNC] Player %s - TotalDonations: %s", 
				player.Name, tostring(handlerData.TotalDonations)))
		end
		
		if handlerData and handlerData.TotalDonations and handlerData.TotalDonations > 0 then
			local success, err = pcall(function()
				DonationLeaderboard:SetAsync(tostring(player.UserId), handlerData.TotalDonations)
			end)
			print(string.format("[DONATION SYNC] Player %s - SetAsync success: %s, err: %s", 
				player.Name, tostring(success), tostring(err)))
		end
	end)

	local function getSpawnPosition(checkpointNumber)
		if checkpointNumber == 0 or not checkpointNumber then
			if mainSpawnLocation then
				local spawnPart = mainSpawnLocation:FindFirstChild("SpawnLocation") or mainSpawnLocation
				if spawnPart:IsA("BasePart") then
					return spawnPart.Position + Vector3.new(0, 3, 0)
				elseif spawnPart:IsA("Model") and spawnPart.PrimaryPart then
					return spawnPart.PrimaryPart.Position + Vector3.new(0, 3, 0)
				end
			end

			local basecamp = checkpoints[0]
			if basecamp then
				local spawnLoc = basecamp:FindFirstChild("SpawnLocation")
				if spawnLoc then
					return spawnLoc.Position + Vector3.new(0, 3, 0)
				end
				return basecamp.Position + Vector3.new(0, 5, 0)
			end
		else
			local spawnCheckpoint = checkpoints[checkpointNumber]
			if spawnCheckpoint then
				local spawnLocation = spawnCheckpoint:FindFirstChild("SpawnLocation")
				if spawnLocation then
					return spawnLocation.Position + Vector3.new(0, 3, 0)
				end
			end

			return getSpawnPosition(0)
		end

		return Vector3.new(0, 50, 0)
	end

	local function teleportToSpawn(character, checkpointNumber, debugSource)
		local spawnPos = getSpawnPosition(checkpointNumber)

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(spawnPos)
		else
			character:MoveTo(spawnPos)
		end

		if checkpointNumber and checkpointNumber > 0 then
			for i = 1, checkpointNumber do
				setCheckpointColor(i, Color3.fromRGB(0, 255, 0))
			end
		end

		return spawnPos
	end

	local isFirstSpawn = true

	local function handleCharacterSpawn(character)
		print(string.format("[RESPAWN DEBUG] handleCharacterSpawn called for %s", player.Name))
		
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			warn("[RESPAWN DEBUG] Humanoid not found!")
			return
		end

		applyNoCollisionToCharacter(character, player)

		local currentData = playerData[player.UserId]
		local lastCP = currentData and currentData.LastCheckpoint or 0
		
		print(string.format("[RESPAWN DEBUG] playerData exists: %s, lastCP from playerData: %d", tostring(currentData ~= nil), lastCP))
		
		-- Double check dari DataHandler juga
		local dataHandlerCP = DataHandler:Get(player, "LastCheckpoint")
		print(string.format("[RESPAWN DEBUG] lastCP from DataHandler: %s", tostring(dataHandlerCP)))

		task.wait(0.2)

		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if not hrp then
			warn("[RESPAWN DEBUG] HRP not found!")
			return
		end

		local spawnPos = getSpawnPosition(lastCP)
		local beforePos = hrp.Position
		hrp.CFrame = CFrame.new(spawnPos)
		
		print(string.format("[RESPAWN DEBUG] Teleported from %s to %s (CP=%d)", tostring(beforePos), tostring(spawnPos), lastCP))

		if isFirstSpawn then
			isFirstSpawn = false
			print("[RESPAWN DEBUG] This was FIRST spawn")
		else
			print("[RESPAWN DEBUG] This was RESPAWN (not first)")
		end

		if lastCP > 0 then
			for i = 1, lastCP do
				setCheckpointColor(i, Color3.fromRGB(0, 255, 0))
			end
		end

		task.delay(3, function()
			if not player or not player.Parent then return end
			if not character or not character.Parent then return end

			local hrpCheck = character:FindFirstChild("HumanoidRootPart")
			if not hrpCheck then return end

			local currentPos = hrpCheck.Position
			local correctPos = getSpawnPosition(lastCP)
			local distance = (currentPos - correctPos).Magnitude
			
			print(string.format("[RESPAWN DEBUG] 3s check: distance=%.1f, correctPos=%s", distance, tostring(correctPos)))

			if distance > 50 then
				print("[RESPAWN DEBUG] Re-teleporting due to distance > 50")
				hrpCheck.CFrame = CFrame.new(correctPos)
			end
		end)

		hideSummitButton:FireClient(player)

		if speedrunTimers[player.UserId] then
			speedrunTimers[player.UserId].active = false
		end

		playerCooldowns[player.UserId] = {}
		playerCurrentCheckpoint[player.UserId] = lastCP

		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local cpValue = ls:FindFirstChild("CP")
			if cpValue then
				cpValue.Value = lastCP
			end
		end
	end

	player.CharacterAdded:Connect(function(character)
		handleCharacterSpawn(character)
	end)

	if player.Character then
		task.spawn(function()
			handleCharacterSpawn(player.Character)
		end)
	end
end)

-- Handle players yang sudah join sebelum script ready (Race Condition Fix)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local player = existingPlayer
		local data = loadPlayerData(player)

		if not data then
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

		-- Create leaderstats if not exists
		if not player:FindFirstChild("leaderstats") then
			local leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player

			local summitStat = Instance.new("IntValue")
			summitStat.Name = "Summit"
			summitStat.Value = data.TotalSummits or 0
			summitStat.Parent = leaderstats

			local cpStat = Instance.new("IntValue")
			cpStat.Name = "CP"
			cpStat.Value = data.LastCheckpoint or 0
			cpStat.Parent = leaderstats
		end

		-- Create PlayerStats if not exists
		if not player:FindFirstChild("PlayerStats") then
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
		end

		playerCooldowns[player.UserId] = {}
		
		-- Function to get spawn position for this player
		local function getSpawnPositionForPlayer(checkpointNumber)
			if checkpointNumber == 0 or not checkpointNumber then
				if mainSpawnLocation then
					local spawnPart = mainSpawnLocation:FindFirstChild("SpawnLocation") or mainSpawnLocation
					if spawnPart:IsA("BasePart") then
						return spawnPart.Position + Vector3.new(0, 3, 0)
					end
				elseif checkpoints[0] then
					local spawnLoc = checkpoints[0]:FindFirstChild("SpawnLocation")
					if spawnLoc then
						return spawnLoc.Position + Vector3.new(0, 3, 0)
					end
				end
			else
				local spawnCheckpoint = checkpoints[checkpointNumber]
				if spawnCheckpoint then
					local spawnLocation = spawnCheckpoint:FindFirstChild("SpawnLocation")
					if spawnLocation then
						return spawnLocation.Position + Vector3.new(0, 3, 0)
					end
				end
			end
			return Vector3.new(0, 50, 0)
		end
		
		-- Handle character spawns (both initial and respawn)
		local function handleExistingPlayerCharacter(character)

			
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid then return end
			
			applyNoCollisionToCharacter(character, player)
			
			local currentData = playerData[player.UserId]
			local lastCP = currentData and currentData.LastCheckpoint or 0
			

			
			task.wait(0.2)
			
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if not hrp then return end
			
			local spawnPos = getSpawnPositionForPlayer(lastCP)
			hrp.CFrame = CFrame.new(spawnPos)
			

			
			-- Re-teleport 3 seconds later if needed
			task.delay(3, function()
				if not player or not player.Parent then return end
				if not character or not character.Parent then return end
				
				local hrpCheck = character:FindFirstChild("HumanoidRootPart")
				if not hrpCheck then return end
				
				local currentPos = hrpCheck.Position
				local correctPos = getSpawnPositionForPlayer(lastCP)
				local distance = (currentPos - correctPos).Magnitude
				
				if distance > 50 then
					hrpCheck.CFrame = CFrame.new(correctPos)
				end
			end)
			
			playerCooldowns[player.UserId] = {}
			playerCurrentCheckpoint[player.UserId] = lastCP
			
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local cpValue = ls:FindFirstChild("CP")
				if cpValue then
					cpValue.Value = lastCP
				end
			end
		end
		
		-- Setup CharacterAdded for respawns
		player.CharacterAdded:Connect(function(character)

			handleExistingPlayerCharacter(character)
		end)
		
		-- Handle current character if exists
		if player.Character then
			handleExistingPlayerCharacter(player.Character)
		end
	end)
end


for checkpointNum, checkpoint in pairs(checkpoints) do

	checkpoint.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if not player then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local userId = player.UserId
		local data = playerData[userId]

		if not data then return end

		if playerSwimmingMode[userId] then
			return
		end

		if not playerCooldowns[userId] then
			playerCooldowns[userId] = {}
		end

		local cooldownKey = "checkpoint" .. checkpointNum
		local lastTouch = playerCooldowns[userId][cooldownKey] or 0
		local currentTime = tick()

		if currentTime - lastTouch < 5 then
			return
		end

		playerCooldowns[userId][cooldownKey] = currentTime

		local currentCheckpoint = playerCurrentCheckpoint[userId] or 0
		local expectedCheckpoint = currentCheckpoint + 1

		if checkpointNum == 0 then
			if not speedrunTimers[userId] or not speedrunTimers[userId].active then
				speedrunTimers[userId] = {
					startTime = tick(),
					active = true,
					pausedTime = 0
				}
			else
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

			return
		end

		if checkpointNum <= currentCheckpoint then
			return
		end

		if checkpointNum < #checkpoints then
			data.LastCheckpoint = checkpointNum
			playerCurrentCheckpoint[userId] = checkpointNum
			savePlayerData(player)
			setCheckpointColor(checkpointNum, Color3.fromRGB(0, 255, 0))

			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local cpValue = ls:FindFirstChild("CP")
				if cpValue then
					cpValue.Value = checkpointNum
				end
			end

			if CONFIG.DISTRIBUTE_MONEY_TO_CHECKPOINTS then
				local totalCheckpoints = #checkpoints - 2
				local moneyPerCheckpoint = math.floor(CONFIG.MONEY_PER_SUMMIT / totalCheckpoints)

				DataHandler:Increment(player, "Money", moneyPerCheckpoint)

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

		end

		if checkpointNum == #checkpoints then

			local speedrunTime = nil
			if speedrunTimers[userId] and speedrunTimers[userId].active then
				speedrunTime = tick() - speedrunTimers[userId].startTime
				speedrunTimers[userId].active = false

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
				else
					NotificationServer:Send(player, {
						Message = "Kamu mencapai puncak dalam waktu " .. formatTime(speedrunTime),
						Type = "info",
						Icon = "⏱️",
						Duration = 4
					})
				end

			else
			end

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

			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local summitStat = ls:FindFirstChild("Summit")
				if summitStat then
					summitStat.Value = data.TotalSummits
				end
				local cpStat = ls:FindFirstChild("CP")
				if cpStat then
					cpStat.Value = 0
				end
			end

			DataHandler:Set(player, "TotalSummits", data.TotalSummits)

			if CONFIG.GIVE_SUMMIT_BONUS ~= false then
				local moneyReward = CONFIG.MONEY_PER_SUMMIT
				DataHandler:Increment(player, "Money", moneyReward)

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

			data.LastCheckpoint = 0
			playerCurrentCheckpoint[userId] = 0

			resetAllCheckpointColors(player)

			savePlayerData(player)

			task.spawn(function()
				task.wait(0.5)
				local TitleServer = require(script.Parent:WaitForChild("TitleServer"))
				TitleServer:UpdateSummitTitle(player)
			end)

			task.spawn(function()
				task.wait(1)
				updateLeaderboards()
			end)

			showSummitButton:FireClient(player)
		end

	end)
end

for checkpointNum, checkpoint in pairs(checkpoints) do
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

	proximityPrompt.Triggered:Connect(function(player)

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
			return
		end

		MarketplaceService:PromptProductPurchase(player, CONFIG.SKIP_PRODUCT_ID)
	end)
end

local function executeSkip(player)
	local character = player.Character
	if not character then return end

	local data = DataHandler:GetData(player)
	if not data then return end

	local currentCheckpoint = data.LastCheckpoint
	local nextCheckpoint = currentCheckpoint + 1

	if not checkpoints[nextCheckpoint] then
		NotificationServer:Send(player, {
			Message = "Tidak ada checkpoint selanjutnya!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local spawnLocation = checkpoints[nextCheckpoint]:FindFirstChild("SpawnLocation")
	if spawnLocation then
		character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
	else
		character:MoveTo(checkpoints[nextCheckpoint].Position + Vector3.new(0, 5, 0))
	end

	DataHandler:Set(player, "LastCheckpoint", nextCheckpoint)

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

end

_G.ExecuteSkipCheckpoint = function(player)
	executeSkip(player)
end

skipCheckpoint.OnServerEvent:Connect(function(player)

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

	MarketplaceService:PromptProductPurchase(player, CONFIG.SKIP_PRODUCT_ID)
end)

teleportToBasecamp.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then
		warn("[TELEPORT] Character not found")
		return
	end

	local userId = player.UserId
	local data = playerData[userId]

	if data then
		data.LastCheckpoint = 0
		playerCurrentCheckpoint[userId] = 0

		DataHandler:Set(player, "LastCheckpoint", 0)
		DataHandler:SavePlayer(player)

		resetAllCheckpointColors(player)
	end

	local basecamp = checkpoints[0]
	if basecamp then
		local spawnLocation = basecamp:FindFirstChild("SpawnLocation")
		if spawnLocation then
			character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
			hideSummitButton:FireClient(player)
		else
			character:MoveTo(basecamp.Position + Vector3.new(0, 5, 0))
			hideSummitButton:FireClient(player)
			warn("[TELEPORT] SpawnLocation not found, teleported to basecamp part position")
		end
	else
		warn("[TELEPORT] Basecamp checkpoint not found")
	end

	NotificationServer:Send(player, {
		Message = "🏕️ Checkpoint reset! Kamu kembali ke basecamp.",
		Type = "info",
		Icon = "🏕️",
		Duration = 3
	})
end)

Players.PlayerRemoving:Connect(function(player)

	local userId = player.UserId
	local data = playerData[userId]

	if data then
		updatePlaytime(player)

		local cachedSummits = DataHandler:Get(player, "TotalSummits")
		local cachedSpeedrun = DataHandler:Get(player, "BestSpeedrun")
		local cachedCheckpoint = DataHandler:Get(player, "LastCheckpoint")
		local cachedPlaytime = DataHandler:Get(player, "TotalPlaytime")

		if cachedSummits ~= nil then
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
	else
		warn("[PLAYER LEAVE] No data found for:", player.Name)
	end

	playerData[userId] = nil
	speedrunTimers[userId] = nil
	playerCooldowns[userId] = nil
	playerCurrentCheckpoint[userId] = nil
	playtimeSessions[userId] = nil
	gamepassCache[userId] = nil

end)

task.spawn(function()
	while task.wait(30) do
		for _, player in pairs(Players:GetPlayers()) do
			updatePlaytime(player)
		end
	end
end)

task.spawn(function()
	while task.wait(60) do
		for _, player in pairs(Players:GetPlayers()) do
			updatePlaytime(player)
			savePlayerData(player)
		end
		updateLeaderboards()
	end
end)

task.wait(2)
updateLeaderboards()

function CheckpointSystem.SyncPlayerData(player)

	local userId = player.UserId

	task.wait(0.3)

	local freshData = DataHandler:GetData(player)

	if not freshData then
		warn(string.format("[CHECKPOINT SYNC] ❌ Failed to get data for %s", player.Name))
		return false
	end

	if playerData[userId] then
		local oldSummits = playerData[userId].TotalSummits

		playerData[userId].TotalSummits = freshData.TotalSummits
		playerData[userId].LastCheckpoint = freshData.LastCheckpoint
		playerData[userId].BestSpeedrun = freshData.BestSpeedrun
		playerData[userId].TotalPlaytime = freshData.TotalPlaytime

		return true
	else
		playerData[userId] = {
			TotalSummits = freshData.TotalSummits,
			LastCheckpoint = freshData.LastCheckpoint,
			BestSpeedrun = freshData.BestSpeedrun,
			TotalPlaytime = freshData.TotalPlaytime
		}

		return true
	end
end

syncEvent.Event:Connect(function(player)
	CheckpointSystem.SyncPlayerData(player)
end)

local function teleportPlayerToLastCheckpoint(player)
	local character = player.Character
	if not character then return end
	
	local userId = player.UserId
	local data = playerData[userId]
	if not data then return end
	
	local lastCP = data.LastCheckpoint or 0
	
	-- Helper function to get spawn position for a checkpoint
	local function getSpawnPositionForCP(cpNum)
		local spawnCheckpoint = checkpoints[cpNum]
		if spawnCheckpoint then
			local spawnLocation = spawnCheckpoint:FindFirstChild("SpawnLocation")
			if spawnLocation then
				return spawnLocation.Position + Vector3.new(0, 3, 0)
			else
				return spawnCheckpoint.Position + Vector3.new(0, 5, 0)
			end
		else
			local basecamp = checkpoints[0]
			if basecamp then
				local spawnLoc = basecamp:FindFirstChild("SpawnLocation")
				if spawnLoc then
					return spawnLoc.Position + Vector3.new(0, 3, 0)
				end
			end
		end
		return Vector3.new(0, 50, 0)
	end
	
	local spawnPos = getSpawnPositionForCP(lastCP)
	
	-- Check for carry system integration
	local CarryRemote = ReplicatedStorage:FindFirstChild("CarryRemote")
	local hasCarryWeld = false
	local isCarrier = false
	local isBeingCarried = false
	local carrierPlayer = nil
	local carriedPlayers = {}
	
	-- Check if this player has carry welds (is carrier or being carried)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, child in ipairs(hrp:GetChildren()) do
			if child:IsA("WeldConstraint") and child.Name == "CarryWeld" then
				hasCarryWeld = true
				-- Check if Part0 is our HRP (we are carrier) or Part1 is our HRP (we are carried)
				if child.Part0 and child.Part0.Parent then
					local otherChar = child.Part0.Parent
					local otherPlayer = Players:GetPlayerFromCharacter(otherChar)
					if otherPlayer and otherPlayer ~= player then
						isBeingCarried = true
						carrierPlayer = otherPlayer
					end
				end
				if child.Part1 and child.Part1.Parent then
					local otherChar = child.Part1.Parent
					local otherPlayer = Players:GetPlayerFromCharacter(otherChar)
					if otherPlayer and otherPlayer ~= player then
						isCarrier = true
						table.insert(carriedPlayers, otherPlayer)
					end
				end
			end
		end
	end
	
	-- Also check if carrier has welds pointing to us
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if otherHRP then
				for _, child in ipairs(otherHRP:GetChildren()) do
					if child:IsA("WeldConstraint") and child.Name == "CarryWeld" then
						if child.Part1 and child.Part1 == hrp then
							isBeingCarried = true
							carrierPlayer = otherPlayer
						end
						if child.Part0 and child.Part0 == hrp then
							isCarrier = true
							if not table.find(carriedPlayers, otherPlayer) then
								table.insert(carriedPlayers, otherPlayer)
							end
						end
					end
				end
			end
		end
	end
	
	-- If player is being carried, teleport the whole group via carrier
	if isBeingCarried and carrierPlayer then
		-- Find all players being carried by the carrier
		local allInGroup = {carrierPlayer}
		local carrierHRP = carrierPlayer.Character and carrierPlayer.Character:FindFirstChild("HumanoidRootPart")
		if carrierHRP then
			for _, child in ipairs(carrierHRP:GetChildren()) do
				if child:IsA("WeldConstraint") and child.Name == "CarryWeld" then
					if child.Part1 and child.Part1.Parent then
						local carriedPlayer = Players:GetPlayerFromCharacter(child.Part1.Parent)
						if carriedPlayer and not table.find(allInGroup, carriedPlayer) then
							table.insert(allInGroup, carriedPlayer)
						end
					end
				end
			end
		end
		
		-- Teleport the whole group to the carrier's checkpoint (or triggering player's)
		local carrierData = playerData[carrierPlayer.UserId]
		local carrierCP = carrierData and carrierData.LastCheckpoint or lastCP
		local groupSpawnPos = getSpawnPositionForCP(carrierCP)
		
		-- Teleport carrier first
		if carrierPlayer.Character then
			local cHRP = carrierPlayer.Character:FindFirstChild("HumanoidRootPart")
			if cHRP then
				cHRP.CFrame = CFrame.new(groupSpawnPos)
			end
		end
		
		return -- The carrier will handle moving carried players via welds
	end
	
	-- If player is carrier, teleport self and all carried players
	if isCarrier and #carriedPlayers > 0 then
		-- Teleport carrier
		if hrp then
			hrp.CFrame = CFrame.new(spawnPos)
		end
		
		-- Carried players will follow via welds automatically
		-- But we need to ensure they stay attached
		task.delay(0.1, function()
			if hrp and hrp.Parent then
				-- Re-check welds are intact
				for _, child in ipairs(hrp:GetChildren()) do
					if child:IsA("WeldConstraint") and child.Name == "CarryWeld" then
						if child.Part1 then
							child.Enabled = true
						end
					end
				end
			end
		end)
		
		return
	end
	
	-- Normal teleport for players not in carry relationship
	if hrp then
		hrp.CFrame = CFrame.new(spawnPos)
	else
		character:MoveTo(spawnPos)
	end
end


if deathTriggerFolder then
	local function setupDeathTrigger(triggerPart)
		if not triggerPart:IsA("BasePart") then return end
		
		triggerPart.CanCollide = false
		triggerPart.Transparency = 1
		
		triggerPart.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			
			if not player then return end
			
			local userId = player.UserId
			
			if playerSwimmingMode[userId] then
				return
			end
			
			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then return end
			
			local cooldownKey = "deathTrigger"
			if not playerCooldowns[userId] then
				playerCooldowns[userId] = {}
			end
			
			local lastTouch = playerCooldowns[userId][cooldownKey] or 0
			local currentTime = tick()
			
			if currentTime - lastTouch < 0.5 then
				return
			end
			
			playerCooldowns[userId][cooldownKey] = currentTime
			
			teleportPlayerToLastCheckpoint(player)
		end)
	end
	
	for _, triggerPart in pairs(deathTriggerFolder:GetChildren()) do
		setupDeathTrigger(triggerPart)
	end
	
	deathTriggerFolder.ChildAdded:Connect(function(child)
		task.wait(0.1)
		setupDeathTrigger(child)
	end)
end

getSwimmingStatus.OnServerInvoke = function(player)
	local userId = player.UserId
	return playerSwimmingMode[userId] == true
end

toggleSwimmingMode.OnServerEvent:Connect(function(player, enableSwimming)
	local userId = player.UserId
	
	if enableSwimming then
		playerSwimmingMode[userId] = true
		
		swimmingModeChanged:FireClient(player, true)
		
		NotificationServer:Send(player, {
			Message = "🏊 Mode Berenang aktif! Kamu bisa berenang, tapi checkpoint dinonaktifkan.",
			Type = "info",
			Icon = "🏊",
			Duration = 4
		})
	else
		playerSwimmingMode[userId] = false
		
		swimmingModeChanged:FireClient(player, false)
		
		teleportPlayerToLastCheckpoint(player)
		
		NotificationServer:Send(player, {
			Message = "⛰️ Mode Berenang nonaktif! Kamu kembali ke checkpoint terakhir.",
			Type = "info",
			Icon = "⛰️",
			Duration = 4
		})
	end
end)

teleportToLastCheckpoint.OnServerEvent:Connect(function(player)
	teleportPlayerToLastCheckpoint(player)
	
	NotificationServer:Send(player, {
		Message = "📍 Teleport ke checkpoint terakhir!",
		Type = "info",
		Icon = "📍",
		Duration = 2
	})
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	playerSwimmingMode[userId] = nil

	if characterCollisionConnections[userId] then
		characterCollisionConnections[userId]:Disconnect()
		characterCollisionConnections[userId] = nil
	end
end)

return CheckpointSystem
