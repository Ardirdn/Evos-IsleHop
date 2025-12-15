--[[
    ADMIN SYSTEM SERVER (Refactored)
    Place in ServerScriptService/AdminServer
    
    Simplified:
    - Uses Data Handler for all data operations
    - Uses Notification System for all feedback
    - Calls Title System for title management
    - Focus: Admin commands only
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TitleServer)

-- ✅ GANTI JADI INI:
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Check if player is admin (using TitleConfig)
local function isAdmin(userId)
	for _, id in ipairs(TitleConfig.AdminIds) do
		if userId == id then
			return true
		end
	end
	return false
end

-- Create RemoteEvents folder
local remoteFolder = ReplicatedStorage:FindFirstChild("AdminRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "AdminRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local kickPlayerEvent = remoteFolder:FindFirstChild("KickPlayer")
if not kickPlayerEvent then
	kickPlayerEvent = Instance.new("RemoteEvent")
	kickPlayerEvent.Name = "KickPlayer"
	kickPlayerEvent.Parent = remoteFolder
end

local banPlayerEvent = remoteFolder:FindFirstChild("BanPlayer")
if not banPlayerEvent then
	banPlayerEvent = Instance.new("RemoteEvent")
	banPlayerEvent.Name = "BanPlayer"
	banPlayerEvent.Parent = remoteFolder
end

local teleportHereEvent = remoteFolder:FindFirstChild("TeleportHere")
if not teleportHereEvent then
	teleportHereEvent = Instance.new("RemoteEvent")
	teleportHereEvent.Name = "TeleportHere"
	teleportHereEvent.Parent = remoteFolder
end

local teleportToEvent = remoteFolder:FindFirstChild("TeleportTo")
if not teleportToEvent then
	teleportToEvent = Instance.new("RemoteEvent")
	teleportToEvent.Name = "TeleportTo"
	teleportToEvent.Parent = remoteFolder
end

local freezePlayerEvent = remoteFolder:FindFirstChild("FreezePlayer")
if not freezePlayerEvent then
	freezePlayerEvent = Instance.new("RemoteEvent")
	freezePlayerEvent.Name = "FreezePlayer"
	freezePlayerEvent.Parent = remoteFolder
end

local setSpeedEvent = remoteFolder:FindFirstChild("SetSpeed")
if not setSpeedEvent then
	setSpeedEvent = Instance.new("RemoteEvent")
	setSpeedEvent.Name = "SetSpeed"
	setSpeedEvent.Parent = remoteFolder
end

local setGravityEvent = remoteFolder:FindFirstChild("SetGravity")
if not setGravityEvent then
	setGravityEvent = Instance.new("RemoteEvent")
	setGravityEvent.Name = "SetGravity"
	setGravityEvent.Parent = remoteFolder
end

local killPlayerEvent = remoteFolder:FindFirstChild("KillPlayer")
if not killPlayerEvent then
	killPlayerEvent = Instance.new("RemoteEvent")
	killPlayerEvent.Name = "KillPlayer"
	killPlayerEvent.Parent = remoteFolder
end

local setPlayerTitleEvent = remoteFolder:FindFirstChild("SetPlayerTitle")
if not setPlayerTitleEvent then
	setPlayerTitleEvent = Instance.new("RemoteEvent")
	setPlayerTitleEvent.Name = "SetPlayerTitle"
	setPlayerTitleEvent.Parent = remoteFolder
end

local giveItemsEvent = remoteFolder:FindFirstChild("GiveItems")
if not giveItemsEvent then
	giveItemsEvent = Instance.new("RemoteEvent")
	giveItemsEvent.Name = "GiveItems"
	giveItemsEvent.Parent = remoteFolder
end

local modifySummitDataEvent = remoteFolder:FindFirstChild("ModifySummitData")
if not modifySummitDataEvent then
	modifySummitDataEvent = Instance.new("RemoteEvent")
	modifySummitDataEvent.Name = "ModifySummitData"
	modifySummitDataEvent.Parent = remoteFolder
end

-- ✅ TAMBAHKAN INI SETELAH modifySummitDataEvent

local searchLeaderboardEvent = remoteFolder:FindFirstChild("SearchLeaderboard")
if not searchLeaderboardEvent then
	searchLeaderboardEvent = Instance.new("RemoteFunction")
	searchLeaderboardEvent.Name = "SearchLeaderboard"
	searchLeaderboardEvent.Parent = remoteFolder
end

local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
if not deleteLeaderboardEvent then
	deleteLeaderboardEvent = Instance.new("RemoteEvent")
	deleteLeaderboardEvent.Name = "DeleteLeaderboard"
	deleteLeaderboardEvent.Parent = remoteFolder
end


print("✅ [ADMIN SERVER] Initialized")

-- Global/Server Notification RemoteEvent
local sendGlobalNotificationEvent = remoteFolder:FindFirstChild("SendGlobalNotification")
if not sendGlobalNotificationEvent then
	sendGlobalNotificationEvent = Instance.new("RemoteEvent")
	sendGlobalNotificationEvent.Name = "SendGlobalNotification"
	sendGlobalNotificationEvent.Parent = remoteFolder
end

-- Kick Player
kickPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to kick: %s", admin.Name))
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		targetPlayer:Kick("You have been kicked by an administrator")

		NotificationService:Send(admin, {
			Message = string.format("Kicked %s", targetPlayer.Name),
			Type = "success",
			Duration = 3
		})

		print(string.format("👮 [ADMIN SERVER] %s kicked %s", admin.Name, targetPlayer.Name))
	end
end)

-- Ban Player
banPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to ban: %s", admin.Name))
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		-- TODO: Implement ban system (save to DataStore)
		targetPlayer:Kick("You have been banned by an administrator")

		NotificationService:Send(admin, {
			Message = string.format("Banned %s", targetPlayer.Name),
			Type = "success",
			Duration = 3
		})

		print(string.format("🚫 [ADMIN SERVER] %s banned %s", admin.Name, targetPlayer.Name))
	end
end)

-- Teleport Here
teleportHereEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character and admin.Character then
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		local adminRoot = admin.Character:FindFirstChild("HumanoidRootPart")

		if targetRoot and adminRoot then
			targetRoot.CFrame = adminRoot.CFrame * CFrame.new(0, 0, -5)

			NotificationService:Send(admin, {
				Message = string.format("Teleported %s here", targetPlayer.Name),
				Type = "success",
				Duration = 3
			})

			print(string.format("📍 [ADMIN SERVER] %s teleported %s here", admin.Name, targetPlayer.Name))
		end
	end
end)

-- Teleport To
teleportToEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character and admin.Character then
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		local adminRoot = admin.Character:FindFirstChild("HumanoidRootPart")

		if targetRoot and adminRoot then
			adminRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)

			NotificationService:Send(admin, {
				Message = string.format("Teleported to %s", targetPlayer.Name),
				Type = "success",
				Duration = 3
			})

			print(string.format("📍 [ADMIN SERVER] %s teleported to %s", admin.Name, targetPlayer.Name))
		end
	end
end)

-- Freeze Player
local frozenPlayers = {}

freezePlayerEvent.OnServerEvent:Connect(function(admin, targetUserId, shouldFreeze)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			if shouldFreeze then
				frozenPlayers[targetUserId] = {
					originalWalkSpeed = humanoid.WalkSpeed,
					originalJumpPower = humanoid.JumpPower
				}
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0

				NotificationService:Send(admin, {
					Message = string.format("Froze %s", targetPlayer.Name),
					Type = "success",
					Duration = 3
				})

				NotificationService:Send(targetPlayer, {
					Message = "You have been frozen by an admin",
					Type = "warning",
					Duration = 5
				})

				print(string.format("❄️ [ADMIN SERVER] %s froze %s", admin.Name, targetPlayer.Name))

				-- Auto unfreeze after 3 minutes
				task.delay(180, function()
					if frozenPlayers[targetUserId] and targetPlayer.Character then
						local hum = targetPlayer.Character:FindFirstChild("Humanoid")
						if hum then
							hum.WalkSpeed = frozenPlayers[targetUserId].originalWalkSpeed
							hum.JumpPower = frozenPlayers[targetUserId].originalJumpPower
							frozenPlayers[targetUserId] = nil
						end
					end
				end)
			else
				if frozenPlayers[targetUserId] then
					humanoid.WalkSpeed = frozenPlayers[targetUserId].originalWalkSpeed
					humanoid.JumpPower = frozenPlayers[targetUserId].originalJumpPower
					frozenPlayers[targetUserId] = nil

					NotificationService:Send(admin, {
						Message = string.format("Unfroze %s", targetPlayer.Name),
						Type = "success",
						Duration = 3
					})

					NotificationService:Send(targetPlayer, {
						Message = "You have been unfrozen",
						Type = "info",
						Duration = 3
					})

					print(string.format("🔥 [ADMIN SERVER] %s unfroze %s", admin.Name, targetPlayer.Name))
				end
			end
		end
	end
end)

-- Set Speed
setSpeedEvent.OnServerEvent:Connect(function(admin, targetUserId, speedMultiplier)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16 * speedMultiplier

			NotificationService:Send(admin, {
				Message = string.format("Set %s's speed to %dx", targetPlayer.Name, speedMultiplier),
				Type = "success",
				Duration = 3
			})

			print(string.format("⚡ [ADMIN SERVER] %s set %s's speed to %dx", admin.Name, targetPlayer.Name, speedMultiplier))
		end
	end
end)

-- Set Gravity
setGravityEvent.OnServerEvent:Connect(function(admin, targetUserId, gravityValue)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local bodyForce = humanoidRootPart:FindFirstChild("AdminGravityForce")
			if not bodyForce then
				bodyForce = Instance.new("BodyForce")
				bodyForce.Name = "AdminGravityForce"
				bodyForce.Parent = humanoidRootPart
			end

			local mass = 0
			for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					mass = mass + part:GetMass()
				end
			end

			local gravityDifference = workspace.Gravity - gravityValue
			bodyForce.Force = Vector3.new(0, mass * gravityDifference, 0)

			NotificationService:Send(admin, {
				Message = string.format("Set %s's gravity to %d", targetPlayer.Name, gravityValue),
				Type = "success",
				Duration = 3
			})

			print(string.format("🌍 [ADMIN SERVER] %s set %s's gravity to %d", admin.Name, targetPlayer.Name, gravityValue))
		end
	end
end)

-- Reset gravity on respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bodyForce = hrp:FindFirstChild("AdminGravityForce")
			if bodyForce then
				bodyForce:Destroy()
			end
		end
	end)
end)

-- Kill Player
killPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer and targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0

			NotificationService:Send(admin, {
				Message = string.format("Killed %s", targetPlayer.Name),
				Type = "success",
				Duration = 3
			})

			print(string.format("💀 [ADMIN SERVER] %s killed %s", admin.Name, targetPlayer.Name))
		end
	end
end)

-- Set Player Title
setPlayerTitleEvent.OnServerEvent:Connect(function(admin, targetUserId, titleName)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then 
		NotificationService:Send(admin, {
			Message = "Target player not found!",
			Type = "error",
			Duration = 3
		})
		return 
	end

	print(string.format("👑 [ADMIN SERVER] %s setting title for %s to %s", admin.Name, targetPlayer.Name, titleName))

	-- Use Title System to set title
	local success = TitleServer:SetTitle(targetPlayer, titleName, "admin", true)

	if success then
		-- Notify target player
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you title: %s", admin.Name, titleName),
			Type = "admin",
			Duration = 5,
			Icon = "👑"
		})

		-- Notify admin
		NotificationService:Send(admin, {
			Message = string.format("Set %s's title to %s", targetPlayer.Name, titleName),
			Type = "success",
			Duration = 3
		})

		print(string.format("✅ [ADMIN SERVER] Title set successfully"))
	else
		NotificationService:Send(admin, {
			Message = "Failed to set title!",
			Type = "error",
			Duration = 3
		})
	end
end)

-- Give Items (Money, Auras, Tools)
giveItemsEvent.OnServerEvent:Connect(function(admin, targetUserId, auras, tools, moneyAmount)
	if not isAdmin(admin.UserId) then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then return end

	print(string.format("🎁 [ADMIN SERVER] %s giving items to %s", admin.Name, targetPlayer.Name))

	local itemList = {}

	-- Give Money
	if moneyAmount and moneyAmount > 0 then
		DataHandler:Increment(targetPlayer, "Money", moneyAmount)
		table.insert(itemList, string.format("$%d", moneyAmount))
		print(string.format("💰 [ADMIN SERVER] Gave $%d to %s", moneyAmount, targetPlayer.Name))
	end

	-- Give Auras
	if auras and #auras > 0 then
		for _, auraId in ipairs(auras) do
			DataHandler:AddToArray(targetPlayer, "OwnedAuras", auraId)
		end
		table.insert(itemList, string.format("%d Aura(s)", #auras))
		print(string.format("✨ [ADMIN SERVER] Gave %d auras to %s", #auras, targetPlayer.Name))
	end

	-- Give Tools
	if tools and #tools > 0 then
		for _, toolId in ipairs(tools) do
			DataHandler:AddToArray(targetPlayer, "OwnedTools", toolId)
		end
		table.insert(itemList, string.format("%d Tool(s)", #tools))
		print(string.format("🔧 [ADMIN SERVER] Gave %d tools to %s", #tools, targetPlayer.Name))
	end

	-- Save data
	DataHandler:SavePlayer(targetPlayer)

	if #itemList > 0 then
		-- Notify target player
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you: %s", admin.Name, table.concat(itemList, ", ")),
			Type = "admin",
			Duration = 5,
			Icon = "🎁"
		})

		-- Notify admin
		NotificationService:Send(admin, {
			Message = string.format("Gave %s: %s", targetPlayer.Name, table.concat(itemList, ", ")),
			Type = "success",
			Duration = 3
		})

		print(string.format("✅ [ADMIN SERVER] Items given successfully"))
	end
end)

-- Update SendGlobalNotification handler
sendGlobalNotificationEvent.OnServerEvent:Connect(function(admin, notifType, message, textColor)
	if not isAdmin(admin.UserId) then return end

	print(string.format("📢 [ADMIN SERVER] %s sending %s notification: %s (color: %s)", 
		admin.Name, notifType, message, tostring(textColor)))

	if notifType == "global" or notifType == "server" then
		-- Convert Color3 to table if needed
		local colorData = textColor
		if typeof(textColor) == "Color3" then
			colorData = {textColor.R, textColor.G, textColor.B}
		end

		-- Send to all players with custom color
		NotificationService:SendToAll({
			Message = message,
			Type = "info",
			Duration = 10,
			Icon = "📢",
			CustomColor = colorData -- Pass custom color
		})

		-- Confirm to admin
		NotificationService:Send(admin, {
			Message = "Global notification sent!",
			Type = "success",
			Duration = 3
		})

		print("✅ [ADMIN SERVER] Global notification sent")
	end
end)

modifySummitDataEvent.OnServerEvent:Connect(function(admin, targetUserId, newSummitValue)
	if not isAdmin(admin.UserId) then return end

	if type(newSummitValue) ~= "number" or newSummitValue < 0 then
		NotificationService:Send(admin, {
			Message = "Invalid summit value!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		NotificationService:Send(admin, {
			Message = "Target player not found!",
			Type = "error",
			Duration = 3
		})
		return
	end

	print(string.format("[ADMIN] %s modifying summit for %s to %d", admin.Name, targetPlayer.Name, newSummitValue))

	-- 1. Update DataHandler & Save
	DataHandler:Set(targetPlayer, "TotalSummits", newSummitValue)
	DataHandler:SavePlayer(targetPlayer)
	print("[ADMIN] ✅ DataStore updated")

	-- 2. Update PlayerStats UI
	if targetPlayer:FindFirstChild("PlayerStats") then
		local summitValue = targetPlayer.PlayerStats:FindFirstChild("Summit")
		if summitValue then
			summitValue.Value = newSummitValue
			print("[ADMIN] ✅ PlayerStats updated")
		end
	end

	-- 3. SYNC LOCAL CACHE VIA BINDABLE EVENT
	task.spawn(function()
		task.wait(0.5)

		print("[ADMIN] Triggering sync via BindableEvent...")
		local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")

		if syncEvent and syncEvent:IsA("BindableEvent") then
			syncEvent:Fire(targetPlayer)
			print("[ADMIN] ✅ Sync event fired!")
		else
			warn("[ADMIN] ❌ Sync event not found!")
		end
	end)


	-- 4. Update title
	task.spawn(function()
		task.wait(1)  -- Wait biar sync selesai dulu
		TitleServer:UpdateSummitTitle(targetPlayer)
		print("[ADMIN] ✅ Title updated")
	end)

	-- 5. Notify
	NotificationService:Send(targetPlayer, {
		Message = string.format("Admin set your summit to %d", newSummitValue),
		Type = "info",
		Duration = 5
	})

	NotificationService:Send(admin, {
		Message = string.format("Set %s's summit to %d", targetPlayer.Name, newSummitValue),
		Type = "success",
		Duration = 3
	})

	print(string.format("[ADMIN] ✅ DONE! %s summit = %d", targetPlayer.Name, newSummitValue))
end)

-- ✅ SEARCH LEADERBOARD DATA
searchLeaderboardEvent.OnServerInvoke = function(admin, username)
	if not isAdmin(admin.UserId) then
		return {success = false, message = "Not authorized"}
	end

	print(string.format("[ADMIN] %s searching for: %s", admin.Name, username))

	-- Get player by username
	local targetUserId = nil
	local targetUsername = nil

	-- Try to get UserID from username
	local success, result = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)

	if not success or not result then
		return {success = false, message = "Player not found"}
	end

	targetUserId = result

	-- Get username (for display)
	local nameSuccess, displayName = pcall(function()
		return Players:GetNameFromUserIdAsync(targetUserId)
	end)

	targetUsername = nameSuccess and displayName or username

	-- Get data from all leaderboards
	local DataStoreService = game:GetService("DataStoreService")
	local SummitLeaderboard = DataStoreService:GetOrderedDataStore("SummitLeaderboard")
	local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore("SpeedrunLeaderboard")
	local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore("PlaytimeLeaderboard")
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore("DonationLeaderboard")

	local leaderboardData = {
		UserId = targetUserId,
		Username = targetUsername,
		Summit = 0,
		Speedrun = "N/A",
		Playtime = 0,
		Donate = 0
	}

	-- Get Summit data
	pcall(function()
		local data = SummitLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Summit = data
		end
	end)

	-- Get Speedrun data
	pcall(function()
		local data = SpeedrunLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			local timeSeconds = math.abs(data) / 1000
			leaderboardData.Speedrun = string.format("%02d:%02d:%02d", 
				math.floor(timeSeconds / 3600),
				math.floor((timeSeconds % 3600) / 60),
				math.floor(timeSeconds % 60)
			)
		end
	end)

	-- Get Playtime data
	pcall(function()
		local data = PlaytimeLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Playtime = data
		end
	end)

	-- Get Donation data
	pcall(function()
		local data = DonationLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Donate = data
		end
	end)

	return {success = true, data = leaderboardData}
end

deleteLeaderboardEvent.OnServerEvent:Connect(function(player, targetUserId, dataType)
	if not isAdmin(player.UserId) then return end

	print("[ADMIN] " .. player.Name .. " deleting " .. dataType .. " data for UserID: " .. targetUserId)

	local DataStoreService = game:GetService("DataStoreService")
	local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v5") -- ✅ Match dengan DataHandler

	-- ✅ LANGSUNG UPDATE DATASTORE dengan UpdateAsync (bypass cache completely)
	local success, errorMsg = pcall(function()
		return PlayerDataStore:UpdateAsync("Player_" .. targetUserId, function(oldData)
			if not oldData then
				oldData = DataHandler:GetData(Players:GetPlayerByUserId(targetUserId))
				if not oldData then return nil end
			end

			-- Reset fields
			if dataType == "summit" or dataType == "all" then
				oldData.TotalSummits = 0
			end
			if dataType == "speedrun" or dataType == "all" then
				oldData.BestSpeedrun = 0
			end
			if dataType == "playtime" or dataType == "all" then
				oldData.TotalPlaytime = 0
			end
			if dataType == "donate" or dataType == "all" then
				oldData.TotalDonation = 0
			end

			print("[ADMIN] ✅ UpdateAsync writing: TotalSummits = " .. (oldData.TotalSummits or 0))
			return oldData -- ✅ This OVERWRITES DataStore immediately
		end)
	end)

	if not success then
		warn("[ADMIN] ❌ Failed UpdateAsync: " .. tostring(errorMsg))
		NotificationService:Send(player, {
			Message = "Failed to delete data!",
			Type = "error",
			Duration = 3
		})
		return
	end

	print("[ADMIN] ✅ DataStore updated via UpdateAsync")

	-- ✅ DELETE FROM LEADERBOARDS
	local SummitLeaderboard = DataStoreService:GetOrderedDataStore("SummitLeaderboard")
	local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore("SpeedrunLeaderboard")
	local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore("PlaytimeLeaderboard")
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore("DonationLeaderboard")

	if dataType == "summit" or dataType == "all" then
		pcall(function() SummitLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end
	if dataType == "speedrun" or dataType == "all" then
		pcall(function() SpeedrunLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end
	if dataType == "playtime" or dataType == "all" then
		pcall(function() PlaytimeLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end
	if dataType == "donate" or dataType == "all" then
		pcall(function() DonationLeaderboard:RemoveAsync(tostring(targetUserId)) end)
	end

	-- ✅ UPDATE IN-MEMORY CACHE (kalau player online)
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		-- FORCE reload data from DataStore
		task.spawn(function()
			task.wait(0.5)

			-- ✅ Get fresh data from DataStore
			local freshData = nil
			pcall(function()
				freshData = PlayerDataStore:GetAsync("Player_" .. targetUserId)
			end)

			if freshData then
				-- ✅ Update DataHandler cache dengan data fresh
				local cache = DataHandler:GetData(targetPlayer)
				if cache then
					if dataType == "summit" or dataType == "all" then
						cache.TotalSummits = 0
					end
					if dataType == "speedrun" or dataType == "all" then
						cache.BestSpeedrun = 0
					end
					if dataType == "playtime" or dataType == "all" then
						cache.TotalPlaytime = 0
					end
					if dataType == "donate" or dataType == "all" then
						cache.TotalDonation = 0
					end
					print("[ADMIN] ✅ Updated in-memory cache")
				end

				-- Update PlayerStats
				if targetPlayer:FindFirstChild("PlayerStats") then
					local playerStats = targetPlayer.PlayerStats
					if dataType == "summit" or dataType == "all" and playerStats:FindFirstChild("Summit") then
						playerStats.Summit.Value = 0
					end
					if dataType == "speedrun" or dataType == "all" and playerStats:FindFirstChild("Best Speedrun") then
						playerStats["Best Speedrun"].Value = 0
					end
					if dataType == "playtime" or dataType == "all" and playerStats:FindFirstChild("Playtime") then
						playerStats.Playtime.Value = 0
					end
					print("[ADMIN] ✅ Updated PlayerStats")
				end

				-- Update CheckpointSystem cache
				local successCP, CheckpointSystem = pcall(function()
					return require(game.ServerScriptService.CheckpointSystem)
				end)

				if successCP and CheckpointSystem and CheckpointSystem.playerProgress then
					local progress = CheckpointSystem.playerProgress[targetUserId]
					if progress then
						if dataType == "summit" or dataType == "all" then
							progress.totalSummits = 0
						end
						if dataType == "speedrun" or dataType == "all" then
							progress.bestSpeedrun = 0
						end
						print("[ADMIN] ✅ Updated CheckpointSystem cache")
					end
				end
			end
		end)

		-- Notify player
		NotificationService:Send(targetPlayer, {
			Message = string.format("%s data has been reset to 0!", dataType:upper()),
			Type = "warning",
			Duration = 5
		})
	end

	-- ✅ Force leaderboard update
	task.delay(1, function()
		local successCP, CheckpointSystem = pcall(function()
			return require(game.ServerScriptService.CheckpointSystem)
		end)

		if successCP and CheckpointSystem and CheckpointSystem.updateLeaderboards then
			CheckpointSystem.updateLeaderboards()
			print("[ADMIN] ✅ Leaderboard updated")
		end
	end)

	-- Notify admin
	NotificationService:Send(player, {
		Message = string.format("%s data PERMANENTLY deleted!", dataType:upper()),
		Type = "success",
		Duration = 5
	})

	print("[ADMIN] ✅ DONE! Data deleted via UpdateAsync")
end)






print("✅ [ADMIN SERVER] System loaded")