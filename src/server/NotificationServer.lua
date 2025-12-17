local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NotificationServer = {}

local notificationComm = ReplicatedStorage:FindFirstChild("NotificationComm")
if not notificationComm then
	notificationComm = Instance.new("Folder")
	notificationComm.Name = "NotificationComm"
	notificationComm.Parent = ReplicatedStorage
end

local showNotificationEvent = notificationComm:FindFirstChild("ShowNotification")
if not showNotificationEvent then
	showNotificationEvent = Instance.new("RemoteEvent")
	showNotificationEvent.Name = "ShowNotification"
	showNotificationEvent.Parent = notificationComm
end

print("✅ [NOTIFICATION SERVER] Initialized")

function NotificationServer:Send(player, data)
	if not player or not player:IsA("Player") or not player.Parent then
		warn("⚠️ [NOTIFICATION SERVER] Invalid player")
		return
	end

	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION SERVER] No message provided")
		return
	end

	data.Type = data.Type or "info"

	local success = pcall(function()
		showNotificationEvent:FireClient(player, data)
	end)

	if success then
		print(string.format("📤 [NOTIFICATION SERVER] Sent '%s' to %s", data.Message, player.Name))
	else
		warn(string.format("⚠️ [NOTIFICATION SERVER] Failed to send to %s", player.Name))
	end
end

function NotificationServer:SendToAll(data)
	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION SERVER] No message provided")
		return
	end

	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, data)
		count = count + 1
	end

	print(string.format("📢 [NOTIFICATION SERVER] Broadcast '%s' to %d players", data.Message, count))
end

function NotificationServer:SendToPlayers(players, data)
	if not players or #players == 0 then
		warn("⚠️ [NOTIFICATION SERVER] No players provided")
		return
	end

	for _, player in ipairs(players) do
		self:Send(player, data)
	end
end

function NotificationServer:SendToAdmins(data, adminIds)
	if not adminIds or #adminIds == 0 then
		warn("⚠️ [NOTIFICATION SERVER] No admin IDs provided")
		return
	end

	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if table.find(adminIds, player.UserId) then
			self:Send(player, data)
			count = count + 1
		end
	end

	print(string.format("👑 [NOTIFICATION SERVER] Sent to %d admins", count))
end

return NotificationServer