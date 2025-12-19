local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")

local NotificationServer = {}

local GLOBAL_NOTIFICATION_TOPIC = "GlobalNotification"

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

pcall(function()
	MessagingService:SubscribeAsync(GLOBAL_NOTIFICATION_TOPIC, function(message)
		local data = message.Data
		if data and data.Message then
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function()
					showNotificationEvent:FireClient(player, data)
				end)
			end
		end
	end)
end)

function NotificationServer:Send(player, data)
	if not player or not player:IsA("Player") or not player.Parent then
		return
	end

	if not data or not data.Message then
		return
	end

	data.Type = data.Type or "info"

	pcall(function()
		showNotificationEvent:FireClient(player, data)
	end)
end

function NotificationServer:SendToAll(data)
	if not data or not data.Message then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, data)
	end
end

function NotificationServer:SendGlobal(data)
	if not data or not data.Message then
		return
	end

	data.Type = data.Type or "info"

	pcall(function()
		MessagingService:PublishAsync(GLOBAL_NOTIFICATION_TOPIC, data)
	end)
end

function NotificationServer:SendToPlayers(players, data)
	if not players or #players == 0 then
		return
	end

	for _, player in ipairs(players) do
		self:Send(player, data)
	end
end

function NotificationServer:SendToAdmins(data, adminIds)
	if not adminIds or #adminIds == 0 then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if table.find(adminIds, player.UserId) then
			self:Send(player, data)
		end
	end
end

return NotificationServer
