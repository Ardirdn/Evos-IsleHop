local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleServer = require(script.Parent.TitleServer)

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local AdminLogServer = require(script.Parent.AdminLogService)

local BanDataStore = DataStoreService:GetDataStore(DataStoreConfig.BannedPlayers)
local BannedUsersCache = {}

local function isPlayerBanned(userId)
	if BannedUsersCache[userId] ~= nil then
		return BannedUsersCache[userId]
	end

	local success, isBanned = pcall(function()
		return BanDataStore:GetAsync(tostring(userId))
	end)

	if success and isBanned then
		BannedUsersCache[userId] = true
		return true
	end

	BannedUsersCache[userId] = false
	return false
end

local function banPlayer(userId, bannedBy, reason)
	local banData = {
		BannedAt = os.time(),
		BannedBy = bannedBy,
		Reason = reason or "No reason provided"
	}

	local success, err = pcall(function()
		BanDataStore:SetAsync(tostring(userId), banData)
	end)

	if success then
		BannedUsersCache[userId] = true
		return true
	else
		warn("[BAN SYSTEM] Failed to save ban:", err)
		return false
	end
end

local function unbanPlayer(userId)
	local success, err = pcall(function()
		BanDataStore:RemoveAsync(tostring(userId))
	end)

	if success then
		BannedUsersCache[userId] = false
		return true
	else
		warn("[BAN SYSTEM] Failed to remove ban:", err)
		return false
	end
end

local function isAdmin(userId)
	return TitleConfig.IsAdmin(userId)
end

local function isPrimaryAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId)
end

local function isThirdpartyAdmin(userId)
	return TitleConfig.IsThirdpartyAdmin(userId)
end

local function isFullAdmin(userId)
	return TitleConfig.IsFullAdmin(userId)
end

local function hasThirdpartyPermission(permission)
	local perms = TitleConfig.ThirdpartyPermissions
	return perms and perms[permission] == true
end

local remoteFolder = ReplicatedStorage:FindFirstChild("AdminRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "AdminRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

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

local giveTitleEvent = remoteFolder:FindFirstChild("GiveTitle")
if not giveTitleEvent then
	giveTitleEvent = Instance.new("RemoteEvent")
	giveTitleEvent.Name = "GiveTitle"
	giveTitleEvent.Parent = remoteFolder
end

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

local getLeaderboardDataFunc = remoteFolder:FindFirstChild("GetLeaderboardData")
if not getLeaderboardDataFunc then
	getLeaderboardDataFunc = Instance.new("RemoteFunction")
	getLeaderboardDataFunc.Name = "GetLeaderboardData"
	getLeaderboardDataFunc.Parent = remoteFolder
end

local unbanPlayerEvent = remoteFolder:FindFirstChild("UnbanPlayer")
if not unbanPlayerEvent then
	unbanPlayerEvent = Instance.new("RemoteEvent")
	unbanPlayerEvent.Name = "UnbanPlayer"
	unbanPlayerEvent.Parent = remoteFolder
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		if isPlayerBanned(player.UserId) then
			player:Kick("You are permanently banned from this game.")
		end
	end)
end)

local inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not inventoryRemotes then
	inventoryRemotes = Instance.new("Folder")
	inventoryRemotes.Name = "InventoryRemotes"
	inventoryRemotes.Parent = ReplicatedStorage
end

local inventoryUpdatedEvent = inventoryRemotes:FindFirstChild("InventoryUpdated")
if not inventoryUpdatedEvent then
	inventoryUpdatedEvent = Instance.new("RemoteEvent")
	inventoryUpdatedEvent.Name = "InventoryUpdated"
	inventoryUpdatedEvent.Parent = inventoryRemotes
end

local sendGlobalNotificationEvent = remoteFolder:FindFirstChild("SendGlobalNotification")
if not sendGlobalNotificationEvent then
	sendGlobalNotificationEvent = Instance.new("RemoteEvent")
	sendGlobalNotificationEvent.Name = "SendGlobalNotification"
	sendGlobalNotificationEvent.Parent = remoteFolder
end

local getPlayerCheckpointFunc = remoteFolder:FindFirstChild("GetPlayerCheckpoint")
if not getPlayerCheckpointFunc then
	getPlayerCheckpointFunc = Instance.new("RemoteFunction")
	getPlayerCheckpointFunc.Name = "GetPlayerCheckpoint"
	getPlayerCheckpointFunc.Parent = remoteFolder
end

getPlayerCheckpointFunc.OnServerInvoke = function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		return 0
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local checkpoint = DataHandler:Get(targetPlayer, "LastCheckpoint")
		return checkpoint or 0
	end

	return 0
end

kickPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to kick: %s", admin.Name))
		return
	end

	if isThirdpartyAdmin(admin.UserId) and not hasThirdpartyPermission("CanKick") then
		NotificationService:Send(admin, {
			Message = "You don't have permission to kick!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local targetName = targetPlayer.Name
		targetPlayer:Kick("You have been kicked by an administrator")

		NotificationService:Send(admin, {
			Message = string.format("Kicked %s", targetName),
			Type = "success",
			Duration = 3
		})

		AdminLogServer:Log(admin.UserId, admin.Name, "kick", {UserId = targetUserId, Name = targetName}, "")

	end
end)

banPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to ban: %s", admin.Name))
		return
	end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot ban players!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local targetName = targetPlayer and targetPlayer.Name or "Unknown"

	local banSuccess = banPlayer(targetUserId, admin.Name, "Banned by admin")

	if banSuccess then
		if targetPlayer then
			targetName = targetPlayer.Name
			targetPlayer:Kick("You have been banned by an administrator. Ban is permanent.")
		end

		NotificationService:Send(admin, {
			Message = string.format("Banned %s (Permanent)", targetName),
			Type = "success",
			Duration = 3
		})

		AdminLogServer:Log(admin.UserId, admin.Name, "ban", {UserId = targetUserId, Name = targetName}, "Permanent")

	else
		NotificationService:Send(admin, {
			Message = "Failed to save ban to DataStore!",
			Type = "error",
			Duration = 3
		})
	end
end)

unbanPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then
		warn(string.format("⚠️ [ADMIN SERVER] Non-admin tried to unban: %s", admin.Name))
		return
	end

	local targetName = "Unknown"
	local nameSuccess, name = pcall(function()
		return Players:GetNameFromUserIdAsync(targetUserId)
	end)
	if nameSuccess then
		targetName = name
	end

	local unbanSuccess = unbanPlayer(targetUserId)

	if unbanSuccess then
		NotificationService:Send(admin, {
			Message = string.format("Unbanned %s", targetName),
			Type = "success",
			Duration = 3
		})

		AdminLogServer:Log(admin.UserId, admin.Name, "unban", {UserId = targetUserId, Name = targetName}, "")

	else
		NotificationService:Send(admin, {
			Message = "Failed to unban player!",
			Type = "error",
			Duration = 3
		})
	end
end)

teleportHereEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) and not hasThirdpartyPermission("CanTeleport") then
		NotificationService:Send(admin, {
			Message = "You don't have permission to teleport!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

		end
	end
end)

teleportToEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) and not hasThirdpartyPermission("CanTeleport") then
		NotificationService:Send(admin, {
			Message = "You don't have permission to teleport!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

		end
	end
end)

local frozenPlayers = {}

freezePlayerEvent.OnServerEvent:Connect(function(admin, targetUserId, shouldFreeze)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) and not hasThirdpartyPermission("CanFreeze") then
		NotificationService:Send(admin, {
			Message = "You don't have permission to freeze!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

				AdminLogServer:Log(admin.UserId, admin.Name, "freeze", {UserId = targetUserId, Name = targetPlayer.Name}, "Frozen")

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

					AdminLogServer:Log(admin.UserId, admin.Name, "freeze", {UserId = targetUserId, Name = targetPlayer.Name}, "Unfrozen")
				end
			end
		end
	end
end)

setSpeedEvent.OnServerEvent:Connect(function(admin, targetUserId, speedMultiplier)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot modify speed!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

		end
	end
end)

setGravityEvent.OnServerEvent:Connect(function(admin, targetUserId, gravityValue)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot modify gravity!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

		end
	end
end)

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

Players.PlayerRemoving:Connect(function(player)
	if frozenPlayers[player.UserId] then
		frozenPlayers[player.UserId] = nil
	end
end)

killPlayerEvent.OnServerEvent:Connect(function(admin, targetUserId)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot kill players!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

		end
	end
end)

setPlayerTitleEvent.OnServerEvent:Connect(function(admin, targetUserId, titleName)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot set titles!",
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

	local success = TitleServer:SetTitle(targetPlayer, titleName, "admin", true)

	if success then
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you title: %s", admin.Name, titleName),
			Type = "admin",
			Duration = 5,
			Icon = "👑"
		})

		NotificationService:Send(admin, {
			Message = string.format("Set %s's title to %s", targetPlayer.Name, titleName),
			Type = "success",
			Duration = 3
		})

		AdminLogServer:Log(admin.UserId, admin.Name, "set_title", {UserId = targetUserId, Name = targetPlayer.Name}, "Title: " .. titleName)
	else
		NotificationService:Send(admin, {
			Message = "Failed to set title!",
			Type = "error",
			Duration = 3
		})
	end
end)

giveTitleEvent.OnServerEvent:Connect(function(admin, targetUserId, titleName)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot give titles!",
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

	local titleData = TitleConfig.SpecialTitles[titleName]

	if not titleData then
		NotificationService:Send(admin, {
			Message = "Title not found!",
			Type = "error",
			Duration = 3
		})
		return
	end

	if titleData.Givable == false then
		if not TitleConfig.IsOwner(targetPlayer.UserId) then
			NotificationService:Send(admin, {
				Message = "This title cannot be given!",
				Type = "error",
				Duration = 3
			})
			return
		end
	end

	local success = false

	if TitleServer.UnlockTitle then
		success = TitleServer:UnlockTitle(targetPlayer, titleName, "admin")
	else
		local ownedTitles = DataHandler:Get(targetPlayer, "OwnedTitles") or {}

		local alreadyOwned = false
		for _, owned in ipairs(ownedTitles) do
			if owned == titleName then
				alreadyOwned = true
				break
			end
		end

		if not alreadyOwned then
			DataHandler:AddToArray(targetPlayer, "OwnedTitles", titleName)
			DataHandler:SavePlayer(targetPlayer)
			success = true
		else
			NotificationService:Send(admin, {
				Message = string.format("%s already owns this title!", targetPlayer.Name),
				Type = "warning",
				Duration = 3
			})
			return
		end
	end

	if success then
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you title: %s", admin.Name, titleName),
			Type = "admin",
			Duration = 5,
			Icon = "🎁"
		})

		NotificationService:Send(admin, {
			Message = string.format("Gave '%s' title to %s", titleName, targetPlayer.Name),
			Type = "success",
			Duration = 3
		})

		AdminLogServer:Log(admin.UserId, admin.Name, "give_title", {UserId = targetUserId, Name = targetPlayer.Name}, "Title: " .. titleName)

	else
		NotificationService:Send(admin, {
			Message = "Failed to give title!",
			Type = "error",
			Duration = 3
		})
	end
end)

giveItemsEvent.OnServerEvent:Connect(function(admin, targetUserId, auras, tools, moneyAmount)
	if not isAdmin(admin.UserId) then return end

	local isThirdparty = isThirdpartyAdmin(admin.UserId)

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then return end

	local itemList = {}

	if moneyAmount and moneyAmount > 0 then
		DataHandler:Increment(targetPlayer, "Money", moneyAmount)
		table.insert(itemList, string.format("$%d", moneyAmount))
	end

	if auras and #auras > 0 then
		for _, auraId in ipairs(auras) do
			DataHandler:AddToArray(targetPlayer, "OwnedAuras", auraId)
		end
		table.insert(itemList, string.format("%d Aura(s)", #auras))
	end

	if tools and #tools > 0 then
		for _, toolId in ipairs(tools) do
			DataHandler:AddToArray(targetPlayer, "OwnedTools", toolId)
		end
		table.insert(itemList, string.format("%d Tool(s)", #tools))
	end

	DataHandler:SavePlayer(targetPlayer)

	if #itemList > 0 then
		NotificationService:Send(targetPlayer, {
			Message = string.format("Admin %s gave you: %s", admin.Name, table.concat(itemList, ", ")),
			Type = "admin",
			Duration = 5,
			Icon = "🎁"
		})

		NotificationService:Send(admin, {
			Message = string.format("Gave %s: %s", targetPlayer.Name, table.concat(itemList, ", ")),
			Type = "success",
			Duration = 3
		})

		if inventoryUpdatedEvent then
			local updatedData = {
				OwnedAuras = DataHandler:Get(targetPlayer, "OwnedAuras") or {},
				OwnedTools = DataHandler:Get(targetPlayer, "OwnedTools") or {},
				EquippedAura = DataHandler:Get(targetPlayer, "EquippedAura"),
				EquippedTool = DataHandler:Get(targetPlayer, "EquippedTool"),
			}
			inventoryUpdatedEvent:FireClient(targetPlayer, updatedData)
		end

	end
end)

sendGlobalNotificationEvent.OnServerEvent:Connect(function(admin, notifType, message, textColor, notificationType, duration)
	if not isAdmin(admin.UserId) then
		return
	end

	if notifType == "event" then
		if not isPrimaryAdmin(admin.UserId) then
			NotificationService:Send(admin, {
				Message = "Only Primary Admin can send event notifications!",
				Type = "error",
				Duration = 3
			})
			return
		end
	end

	if isThirdpartyAdmin(admin.UserId) and not hasThirdpartyPermission("CanSendNotifications") then
		NotificationService:Send(admin, {
			Message = "You don't have permission to send notifications!",
			Type = "error",
			Duration = 3
		})
		return
	end

	if notifType == "global" or notifType == "server" then
		local colorData = textColor
		if typeof(textColor) == "Color3" then
			colorData = {textColor.R, textColor.G, textColor.B}
		end

		local notifData = {
			Message = message,
			NotificationType = notificationType or "SideTextOnly",
			Duration = duration or 10,
			SenderUserId = admin.UserId,
			SenderName = admin.DisplayName,
			SenderUsername = admin.Name,
			Sender = {
				UserId = admin.UserId,
				Name = admin.Name,
				DisplayName = admin.DisplayName
			}
		}

		if notifType == "global" then
			NotificationService:SendGlobal(notifData)
			NotificationService:Send(admin, {
				Message = "Global notification sent to ALL SERVERS!",
				NotificationType = "SideTextOnly",
				Duration = 3
			})
		else
			NotificationService:SendToAll(notifData)
			NotificationService:Send(admin, {
				Message = "Notification sent to THIS SERVER only!",
				NotificationType = "SideTextOnly",
				Duration = 3
			})
		end

		AdminLogServer:Log(admin.UserId, admin.Name, "notification", {UserId = 0, Name = "All Players"}, "Type: " .. notifType .. ", Msg: " .. string.sub(message, 1, 50))
	end
end)

modifySummitDataEvent.OnServerEvent:Connect(function(admin, targetUserId, newSummitValue)
	if not isAdmin(admin.UserId) then return end

	if isThirdpartyAdmin(admin.UserId) then
		NotificationService:Send(admin, {
			Message = "Thirdparty admins cannot modify summit data!",
			Type = "error",
			Duration = 3
		})
		return
	end

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

	DataHandler:Set(targetPlayer, "TotalSummits", newSummitValue)
	DataHandler:SavePlayer(targetPlayer)

	if DataHandler.UpdateLeaderboards then
		DataHandler:UpdateLeaderboards(targetPlayer)
	end

	task.spawn(function()
		task.wait(0.5)
		local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
		if refreshEvent and refreshEvent:IsA("BindableEvent") then
			refreshEvent:Fire("Summit")
		end
	end)

	if targetPlayer:FindFirstChild("PlayerStats") then
		local summitValue = targetPlayer.PlayerStats:FindFirstChild("Summit")
		if summitValue then
			summitValue.Value = newSummitValue
		end
	end

	task.spawn(function()
		task.wait(0.5)

		local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")

		if syncEvent and syncEvent:IsA("BindableEvent") then
			local syncData = {
				TotalSummits = newSummitValue,
				TotalDonations = DataHandler:Get(targetPlayer, "TotalDonations"),
				LastCheckpoint = DataHandler:Get(targetPlayer, "LastCheckpoint"),
				BestSpeedrun = DataHandler:Get(targetPlayer, "BestSpeedrun"),
				TotalPlaytime = DataHandler:Get(targetPlayer, "TotalPlaytime"),
			}
			syncEvent:Fire(targetPlayer, syncData)
		else
			warn("[ADMIN] ❌ Sync event not found!")
		end
	end)

	task.spawn(function()
		task.wait(1)
		if TitleServer.SyncSummitTitles then
			TitleServer:SyncSummitTitles(targetPlayer, newSummitValue)
		end
	end)

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

	AdminLogServer:Log(admin.UserId, admin.Name, "set_summit", {UserId = targetUserId, Name = targetPlayer.Name}, "New value: " .. newSummitValue)
end)

searchLeaderboardEvent.OnServerInvoke = function(admin, username)
	if not isAdmin(admin.UserId) then
		return {success = false, message = "Not authorized"}
	end

	local targetUserId = nil
	local targetUsername = nil

	local success, result = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)

	if not success or not result then
		return {success = false, message = "Player not found"}
	end

	targetUserId = result

	local nameSuccess, displayName = pcall(function()
		return Players:GetNameFromUserIdAsync(targetUserId)
	end)

	targetUsername = nameSuccess and displayName or username

	local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
	local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
	local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

	local leaderboardData = {
		UserId = targetUserId,
		Username = targetUsername,
		Summit = 0,
		Speedrun = "N/A",
		Playtime = 0,
		Donate = 0
	}

	pcall(function()
		local data = SummitLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Summit = data
		end
	end)

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

	pcall(function()
		local data = PlaytimeLeaderboard:GetAsync(tostring(targetUserId))
		if data then
			leaderboardData.Playtime = data
		end
	end)

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

	if isThirdpartyAdmin(player.UserId) and not hasThirdpartyPermission("CanDeleteLeaderboard") then
		NotificationService:Send(player, {
			Message = "You don't have permission to delete leaderboard data!",
			Type = "error",
			Duration = 3
		})
		return
	end

	local PlayerDataStore = DataStoreService:GetDataStore(DataStoreConfig.PlayerData)

	local success, errorMsg = pcall(function()
		return PlayerDataStore:UpdateAsync("Player_" .. targetUserId, function(oldData)
			if not oldData then
				oldData = DataHandler:GetData(Players:GetPlayerByUserId(targetUserId))
				if not oldData then return nil end
			end

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

			return oldData
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

	local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
	local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
	local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
	local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

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

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		task.spawn(function()
			task.wait(0.5)

			local freshData = nil
			pcall(function()
				freshData = PlayerDataStore:GetAsync("Player_" .. targetUserId)
			end)

			if freshData then
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
				end

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
				end

				local syncEvent = game.ServerScriptService:FindFirstChild("SyncPlayerDataEvent")
				if syncEvent and syncEvent:IsA("BindableEvent") then
					local syncData = {
						TotalSummits = cache and cache.TotalSummits or 0,
						TotalDonations = cache and cache.TotalDonations or 0,
						LastCheckpoint = cache and cache.LastCheckpoint or 0,
						BestSpeedrun = cache and cache.BestSpeedrun or nil,
						TotalPlaytime = cache and cache.TotalPlaytime or 0,
					}
					syncEvent:Fire(targetPlayer, syncData)
				end
			end
		end)

		NotificationService:Send(targetPlayer, {
			Message = string.format("%s data has been reset to 0!", dataType:upper()),
			Type = "warning",
			Duration = 5
		})
	end

	task.delay(1, function()
		local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
		if refreshEvent and refreshEvent:IsA("BindableEvent") then
			refreshEvent:Fire("All")
		end
	end)

	NotificationService:Send(player, {
		Message = string.format("%s data PERMANENTLY deleted!", dataType:upper()),
		Type = "success",
		Duration = 5
	})

	local targetUsername = "Unknown"
	pcall(function()
		targetUsername = Players:GetNameFromUserIdAsync(targetUserId)
	end)
	AdminLogServer:Log(player.UserId, player.Name, "delete_data", {UserId = targetUserId, Name = targetUsername}, "Type: " .. dataType:upper())

end)

getLeaderboardDataFunc.OnServerInvoke = function(admin, leaderboardType, limit)
	if not isAdmin(admin.UserId) then
		return {success = false, message = "Not authorized"}
	end

	limit = limit or 50
	if limit > 100 then limit = 100 end

	local leaderboard = nil
	local isAscending = false
	local formatValue = nil

	if leaderboardType == "summit" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
		formatValue = function(val) return tostring(val) end
	elseif leaderboardType == "speedrun" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
		isAscending = true
		formatValue = function(val)
			local timeSeconds = math.abs(val) / 1000
			return string.format("%02d:%02d:%02d",
				math.floor(timeSeconds / 3600),
				math.floor((timeSeconds % 3600) / 60),
				math.floor(timeSeconds % 60)
			)
		end
	elseif leaderboardType == "donate" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)
		formatValue = function(val) return "R$" .. tostring(val) end
	elseif leaderboardType == "playtime" then
		leaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
		formatValue = function(val)
			return string.format("%dh %dm", math.floor(val / 3600), math.floor((val % 3600) / 60))
		end
	else
		return {success = false, message = "Invalid leaderboard type"}
	end

	local entries = {}

	local success, errorMsg = pcall(function()
		local pages
		if isAscending then
			pages = leaderboard:GetSortedAsync(true, limit)
		else
			pages = leaderboard:GetSortedAsync(false, limit)
		end

		local currentPage = pages:GetCurrentPage()

		for rank, entry in ipairs(currentPage) do
			local userId = tonumber(entry.key)
			local value = entry.value

			local username = "Unknown"
			local nameSuccess, displayName = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameSuccess then
				username = displayName
			end

			table.insert(entries, {
				Rank = rank,
				UserId = userId,
				Username = username,
				Value = value,
				FormattedValue = formatValue(value)
			})
		end
	end)

	if not success then
		warn("[ADMIN] Failed to fetch leaderboard: " .. tostring(errorMsg))
		return {success = false, message = "Failed to fetch data"}
	end

	return {success = true, data = entries, type = leaderboardType}
end
