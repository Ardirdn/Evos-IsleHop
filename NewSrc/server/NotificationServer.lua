--[[
    NOTIFICATION SERVER
    Place in ServerScriptService/NotificationServer
    
    Supports 4 notification types:
    - MiddleTextOnly: Center of screen, text only
    - MiddleWithSender: Center of screen, with sender info
    - SideTextOnly: Side of screen, text only (DEFAULT)
    - SideWithSender: Side of screen, with sender info
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NotificationServer = {}

-- Create communication folder
local notificationComm = ReplicatedStorage:FindFirstChild("NotificationComm")
if not notificationComm then
	notificationComm = Instance.new("Folder")
	notificationComm.Name = "NotificationComm"
	notificationComm.Parent = ReplicatedStorage
end

-- Create RemoteEvent
local showNotificationEvent = notificationComm:FindFirstChild("ShowNotification")
if not showNotificationEvent then
	showNotificationEvent = Instance.new("RemoteEvent")
	showNotificationEvent.Name = "ShowNotification"
	showNotificationEvent.Parent = notificationComm
end

print("✅ [NOTIFICATION SERVER] Initialized")

--[[
    Send notification to a specific player
    
    @param player Player - Target player
    @param data table - Notification data
        - Message: string (required)
        - NotificationType: "MiddleTextOnly" | "MiddleWithSender" | "SideTextOnly" | "SideWithSender" (default: "SideTextOnly")
        - Duration: number (optional, default 5)
        - Sender: table {UserId, Name, DisplayName} (optional, for WithSender types)
        - SenderUserId: number (optional, alternative to Sender)
        - SenderName: string (optional)
        - SenderUsername: string (optional)
]]
function NotificationServer:Send(player, data)
	if not player or not player:IsA("Player") or not player.Parent then
		warn("⚠️ [NOTIFICATION SERVER] Invalid player")
		return
	end

	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION SERVER] No message provided")
		return
	end

	-- Default notification type
	data.NotificationType = data.NotificationType or "SideTextOnly"
	data.Duration = data.Duration or 5

	-- Fire to client
	local success = pcall(function()
		showNotificationEvent:FireClient(player, data)
	end)

	if success then
		print(string.format("📤 [NOTIFICATION SERVER] Sent '%s' to %s (Type: %s)", 
			data.Message, player.Name, data.NotificationType))
	else
		warn(string.format("⚠️ [NOTIFICATION SERVER] Failed to send to %s", player.Name))
	end
end

--[[
    Send notification to all players
    
    @param data table - Notification data
    @param sender Player (optional) - The admin/sender for WithSender types
]]
function NotificationServer:SendToAll(data, sender)
	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION SERVER] No message provided")
		return
	end
	
	-- Add sender info if provided
	if sender and (data.NotificationType == "MiddleWithSender" or data.NotificationType == "SideWithSender") then
		data.SenderUserId = sender.UserId
		data.SenderName = sender.Name
		data.SenderUsername = sender.Name
		data.Sender = {
			UserId = sender.UserId,
			Name = sender.Name,
			DisplayName = sender.DisplayName
		}
	end

	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, data)
		count = count + 1
	end

	print(string.format("📢 [NOTIFICATION SERVER] Broadcast '%s' to %d players (Type: %s)", 
		data.Message, count, data.NotificationType or "SideTextOnly"))
end

--[[
    Send notification to multiple players
    
    @param players table - Array of players
    @param data table - Notification data
]]
function NotificationServer:SendToPlayers(players, data)
	if not players or #players == 0 then
		warn("⚠️ [NOTIFICATION SERVER] No players provided")
		return
	end

	for _, player in ipairs(players) do
		self:Send(player, data)
	end
end

--[[
    Send notification to all admins (requires admin check)
    
    @param data table - Notification data
    @param adminIds table - Array of admin user IDs
]]
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
