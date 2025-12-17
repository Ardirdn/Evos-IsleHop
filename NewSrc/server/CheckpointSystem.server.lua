local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

CONFIG = {
	MONEY_PER_SUMMIT = 1000,
	MONEY_PER_CHECKPOINT = 50,
	DISTRIBUTE_MONEY_TO_CHECKPOINTS = true,
	GIVE_SUMMIT_BONUS = false,
	DISABLE_BODY_BLOCK = true,
	SKIP_PRODUCT_ID = 3466042624,
}

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

			playerData[userId].TotalSummits = migratedData.TotalSummits or playerData[userId].TotalSummits
			playerData[userId].TotalDonations = migratedData.TotalDonations or playerData[userId].TotalDonations
			playerData[userId].LastCheckpoint = migratedData.LastCheckpoint or playerData[userId].LastCheckpoint
			playerData[userId].BestSpeedrun = migratedData.BestSpeedrun or playerData[userId].BestSpeedrun
			playerData[userId].TotalPlaytime = migratedData.TotalPlaytime or playerData[userId].TotalPlaytime

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
		else
			warn(string.format("[CHECKPOINT SYNC] playerData[%d] not found for %s", userId, player.Name))
		end
	end)

end

local DataHandler = require(game.ServerScriptService:WaitForChild("DataHandler"))
local NotificationServer = require(game.ServerScriptService:WaitForChild("NotificationServer"))

local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)

local EventManager = nil

local function getEventMultiplierSafe()

	if _G.EventManager and _G.EventManager.GetMultiplier then
		return _G.EventManager:GetMultiplier()
	end

	if _G.GetEventMultiplier then
		return _G.GetEventMultiplier()
	end

	return 1
end

EventManager = {
	GetMultiplier = getEventMultiplierSafe
}

local checkpointsFolder = workspace:FindFirstChild("Checkpoints")

if not checkpointsFolder then
	warn("[ERROR] Checkpoints folder tidak ditemukan di Workspace!")
	return
end

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

	local maxRetries = 10
	local retries = 0
	local data = nil

	while retries < maxRetries do
		data = DataHandler:GetData(player)
		if data then
			break
		end

		retries = retries + 1
		task.wait(0.5)
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

	DataHandler:Set(player, "LastCheckpoint", data.LastCheckpoint)
	DataHandler:Set(player, "TotalSummits", data.TotalSummits)
	DataHandler:Set(player, "BestSpeedrun", data.BestSpeedrun)
	DataHandler:Set(player, "TotalPlaytime", data.TotalPlaytime)

	DataHandler:SavePlayer(player)

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

end

local function updateSpeedrunLeaderboard()

end

local function updatePlaytimeLeaderboard()

end

local function updateLeaderboards()

end

local function spawnPlayerAtCheckpoint(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	task.wait(0.1)

	if CONFIG.DISABLE_BODY_BLOCK then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end

		local userId = player.UserId
		if playerConnections[userId] and playerConnections[userId].descendantAdded then
			playerConnections[userId].descendantAdded:Disconnect()
		end

		if not playerConnections[userId] then
			playerConnections[userId] = {}
		end

		playerConnections[userId].descendantAdded = character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
			end
		end)

	end

	local maxWait = 10
	local waited = 0
	while not playerData[player.UserId] and waited < maxWait do
		task.wait(0.5)
		waited = waited + 0.5
	end

	local currentData = playerData[player.UserId]

	local spawnCheckpointNum = 0
	if currentData then
		spawnCheckpointNum = currentData.LastCheckpoint or 0
	else
		warn("[SPAWN] No data found for:", player.Name, "- spawning at checkpoint 0 as fallback")
	end

	local spawnCheckpoint = checkpoints[spawnCheckpointNum]
	if spawnCheckpoint then
		local spawnLocation = spawnCheckpoint:FindFirstChild("SpawnLocation")
		if spawnLocation then
			character:MoveTo(spawnLocation.Position + Vector3.new(0, 3, 0))
			for i = 1, spawnCheckpointNum do
				setCheckpointColor(i, Color3.fromRGB(0, 255, 0))
			end
		else
			warn("[SPAWN] SpawnLocation not found in checkpoint:", spawnCheckpointNum)

			character:MoveTo(spawnCheckpoint.Position + Vector3.new(0, 5, 0))
		end
	else
		warn("[SPAWN] Checkpoint not found:", spawnCheckpointNum, "- using default spawn")

		if checkpoints[0] then
			local fallbackSpawn = checkpoints[0]:FindFirstChild("SpawnLocation")
			if fallbackSpawn then
				character:MoveTo(fallbackSpawn.Position + Vector3.new(0, 3, 0))
			else
				character:MoveTo(checkpoints[0].Position + Vector3.new(0, 5, 0))
			end
		end
	end

	hideSummitButton:FireClient(player)

	if speedrunTimers[player.UserId] then
		speedrunTimers[player.UserId].active = false
	end

	playerCooldowns[player.UserId] = {}
	playerCurrentCheckpoint[player.UserId] = spawnCheckpointNum
end

Players.PlayerAdded:Connect(function(player)

	playerCooldowns[player.UserId] = {}

	player.CharacterAdded:Connect(function(character)

		task.spawn(function()
			spawnPlayerAtCheckpoint(player, character)
		end)
	end)

	local data = loadPlayerData(player)

	local playerStats = Instance.new("Folder")
	playerStats.Name = "PlayerStats"
	playerStats.Parent = player

	local summitsValue = Instance.new("IntValue")
	summitsValue.Name = "Summit"
	summitsValue.Value = data.TotalSummits
	summitsValue.Parent = playerStats

	local bestTimeValue = Instance.new("StringValue")
	bestTimeValue.Name = "Best Time"
	bestTimeValue.Value = data.BestSpeedrun and formatTime(data.BestSpeedrun / 1000) or "N/A"
	bestTimeValue.Parent = playerStats

	local playtimeValue = Instance.new("StringValue")
	playtimeValue.Name = "Playtime"
	playtimeValue.Value = formatPlaytime(data.TotalPlaytime)
	playtimeValue.Parent = playerStats

	if player.Character and playerData[player.UserId] then
		task.spawn(function()
			spawnPlayerAtCheckpoint(player, player.Character)
		end)
	end
end)

local playerTouchDebounce = {}

local VALID_BODY_PARTS = {
	["HumanoidRootPart"] = true,
	["Torso"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["Head"] = true,
	["LeftFoot"] = true,
	["RightFoot"] = true,
	["LeftLowerLeg"] = true,
	["RightLowerLeg"] = true,
}

for checkpointNum, checkpoint in pairs(checkpoints) do

	checkpoint.Touched:Connect(function(hit)

		if not VALID_BODY_PARTS[hit.Name] then return end

		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local debounceKey = player.UserId .. "_" .. checkpointNum
		local now = tick()
		if playerTouchDebounce[debounceKey] and now < playerTouchDebounce[debounceKey] then
			return
		end
		playerTouchDebounce[debounceKey] = now + 2

		if humanoid.Health <= 0 then return end

		local userId = player.UserId
		local data = playerData[userId]

		if not data then return end

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

		if checkpointNum < currentCheckpoint then
			return
		end

		if not playerReachedCheckpoints[userId] then
			playerReachedCheckpoints[userId] = {}
		end

		if playerReachedCheckpoints[userId][checkpointNum] then

			return
		end

		if checkpointNum < #checkpoints then
			data.LastCheckpoint = checkpointNum
			playerCurrentCheckpoint[userId] = checkpointNum
			savePlayerData(player)
			setCheckpointColor(checkpointNum, Color3.fromRGB(0, 255, 0))

			playerReachedCheckpoints[userId][checkpointNum] = true

			if CONFIG.DISTRIBUTE_MONEY_TO_CHECKPOINTS then
				local moneyPerCheckpoint = CONFIG.MONEY_PER_CHECKPOINT

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

			local gamepassMultiplier = 1

			if ShopConfig.Gamepasses then
				for _, gp in ipairs(ShopConfig.Gamepasses) do
					if gp.Name == "x16 Summit" then
						local success, hasX16 = pcall(function()
							return MarketplaceService:UserOwnsGamePassAsync(userId, gp.GamepassId)
						end)
						if success and hasX16 then
							gamepassMultiplier = 16
							break
						end
					end
				end
			end

			if gamepassMultiplier == 1 then
				for _, gp in ipairs(ShopConfig.Gamepasses) do
					if gp.Name == "x4 Summit" then
						local success, hasX4 = pcall(function()
							return MarketplaceService:UserOwnsGamePassAsync(userId, gp.GamepassId)
						end)
						if success and hasX4 then
							gamepassMultiplier = 4
							break
						end
					end
				end
			end

			if gamepassMultiplier == 1 then
				for _, gp in ipairs(ShopConfig.Gamepasses) do
					if gp.Name == "x2 Summit" then
						local success, hasX2 = pcall(function()
							return MarketplaceService:UserOwnsGamePassAsync(userId, gp.GamepassId)
						end)
						if success and hasX2 then
							gamepassMultiplier = 2
							break
						end
					end
				end
			end

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

			playerReachedCheckpoints[userId] = {}

			resetAllCheckpointColors(player)

			savePlayerData(player)

			task.spawn(function()
				task.wait(0.5)
				local TitleServer = require(game.ServerScriptService:WaitForChild("TitleServer"))
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

		playerReachedCheckpoints[userId] = {}

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

	if playerConnections[userId] then
		for connectionName, connection in pairs(playerConnections[userId]) do
			if connection and typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end
		end
		playerConnections[userId] = nil
	end

	playerData[userId] = nil
	speedrunTimers[userId] = nil
	playerCooldowns[userId] = nil
	playerCurrentCheckpoint[userId] = nil
	playtimeSessions[userId] = nil
	playerReachedCheckpoints[userId] = nil

	for key in pairs(playerTouchDebounce) do
		if string.find(key, "^" .. tostring(userId) .. "_") then
			playerTouchDebounce[key] = nil
		end
	end

end)

task.spawn(function()
	while task.wait(30) do
		local players = Players:GetPlayers()
		if #players > 0 then

			for i, player in ipairs(players) do
				task.spawn(function()
					task.wait((i - 1) * 0.5)
					if player and player.Parent then
						updatePlaytime(player)
					end
				end)
			end
		end
	end
end)

task.spawn(function()
	while task.wait(60) do
		local players = Players:GetPlayers()
		if #players > 0 then

			for i, player in ipairs(players) do
				task.spawn(function()
					task.wait((i - 1) * 1)
					if player and player.Parent then
						updatePlaytime(player)
						savePlayerData(player)
					end
				end)
			end

			task.delay(#players * 1 + 2, function()
				updateLeaderboards()
			end)
		end
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

		local playerStats = player:FindFirstChild("PlayerStats")
		if playerStats then
			local summitValue = playerStats:FindFirstChild("Summit")
			if summitValue then
				summitValue.Value = freshData.TotalSummits
			end
		end

		return true
	else
		playerData[userId] = {
			TotalSummits = freshData.TotalSummits,
			LastCheckpoint = freshData.LastCheckpoint,
			BestSpeedrun = freshData.BestSpeedrun,
			TotalPlaytime = freshData.TotalPlaytime
		}

		local playerStats = player:FindFirstChild("PlayerStats")
		if playerStats then
			local summitValue = playerStats:FindFirstChild("Summit")
			if summitValue then
				summitValue.Value = freshData.TotalSummits
			end
		end

		return true
	end
end

return CheckpointSystem
