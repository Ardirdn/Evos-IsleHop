local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EventConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EventConfig"))
local NotificationService = require(script.Parent.NotificationServer)
local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local EventDataStore = DataStoreService:GetDataStore(DataStoreConfig.GlobalEvents)
local EVENT_KEY = "ActiveEvent"
local MESSAGING_TOPIC = "GlobalEventChange"

local remoteFolder = ReplicatedStorage:FindFirstChild("EventRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "EventRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local getActiveEventFunc = remoteFolder:FindFirstChild("GetActiveEvent")
if not getActiveEventFunc then
	getActiveEventFunc = Instance.new("RemoteFunction")
	getActiveEventFunc.Name = "GetActiveEvent"
	getActiveEventFunc.Parent = remoteFolder
end

local setEventRemote = remoteFolder:FindFirstChild("SetEvent")
if not setEventRemote then
	setEventRemote = Instance.new("RemoteEvent")
	setEventRemote.Name = "SetEvent"
	setEventRemote.Parent = remoteFolder
end

local eventChangedRemote = remoteFolder:FindFirstChild("EventChanged")
if not eventChangedRemote then
	eventChangedRemote = Instance.new("RemoteEvent")
	eventChangedRemote.Name = "EventChanged"
	eventChangedRemote.Parent = remoteFolder
end

local CurrentActiveEvent = nil

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local function isAdmin(player)
	local data = require(script.Parent.DataHandler):GetData(player)
	if data and data.EquippedTitle == "Admin" then
		return true
	end

	if TitleConfig.AdminIds then
		for _, adminId in ipairs(TitleConfig.AdminIds) do
			if player.UserId == adminId then
				return true
			end
		end
	end

	return false
end

-- ============================================================
-- Broadcast ke semua player di SERVER INI saja
-- ============================================================
local function broadcastEventChange()
	for _, player in ipairs(Players:GetPlayers()) do
		eventChangedRemote:FireClient(player, CurrentActiveEvent)
	end
end

-- ============================================================
-- Terapkan state event baru dari MessagingService atau DataStore
-- Hanya update state lokal + broadcast ke player lokal
-- ============================================================
local function applyEventState(eventData)
	if eventData and eventData.Id then
		-- Cari data lengkap (Icon, Color) dari EventConfig karena
		-- MessagingService hanya kirim data sederhana (Id, Name, Multiplier)
		local fullData = nil
		for _, event in ipairs(EventConfig.AvailableEvents) do
			if event.Id == eventData.Id then
				fullData = {
					Id = eventData.Id,
					Name = eventData.Name,
					Multiplier = eventData.Multiplier,
					Icon = event.Icon,
					Color = event.Color,
				}
				break
			end
		end
		CurrentActiveEvent = fullData
	else
		CurrentActiveEvent = nil
	end

	broadcastEventChange()
end

-- ============================================================
-- Load event dari DataStore saat server pertama kali start
-- ============================================================
local function loadEventFromDataStore()
	local success, result = pcall(function()
		return EventDataStore:GetAsync(EVENT_KEY)
	end)

	if success then
		if result then
			applyEventState(result)
			print(string.format("[EVENT MANAGER] ✅ Loaded event from DataStore: %s (x%d)", result.Name or "?", result.Multiplier or 1))
		else
			CurrentActiveEvent = nil
			print("[EVENT MANAGER] ℹ️ No active event in DataStore")
		end
	else
		warn("[EVENT MANAGER] ❌ Failed to load event from DataStore:", result)
		CurrentActiveEvent = nil
	end
end

-- ============================================================
-- Simpan event ke DataStore
-- Gunakan RemoveAsync saat mematikan agar key benar-benar terhapus
-- ============================================================
local function saveEventToDataStore(eventData)
	local success, err = pcall(function()
		if eventData then
			local simpleData = {
				Id = eventData.Id,
				Name = eventData.Name,
				Multiplier = eventData.Multiplier,
			}
			EventDataStore:SetAsync(EVENT_KEY, simpleData)
		else
			-- FIX: Gunakan RemoveAsync agar key benar-benar terhapus,
			-- bukan SetAsync(key, nil) yang tidak reliable
			EventDataStore:RemoveAsync(EVENT_KEY)
		end
	end)

	if not success then
		warn("⚠️ [EVENT MANAGER] Failed to save/remove event in DataStore:", err)
	end

	return success
end

-- ============================================================
-- Publish perubahan event ke SEMUA server via MessagingService
-- ============================================================
local function publishEventChange(action, eventData)
	local payload = {
		action = action, -- "activate" atau "deactivate"
	}

	if action == "activate" and eventData then
		payload.eventData = {
			Id = eventData.Id,
			Name = eventData.Name,
			Multiplier = eventData.Multiplier,
		}
	end

	local ok, err = pcall(function()
		MessagingService:PublishAsync(MESSAGING_TOPIC, payload)
	end)

	if not ok then
		warn("⚠️ [EVENT MANAGER] Failed to publish cross-server event change:", err)
	end
end

-- ============================================================
-- Activate event: simpan ke DS + broadcast ke semua server
-- ============================================================
local function activateEvent(eventId)
	local eventData = nil
	for _, event in ipairs(EventConfig.AvailableEvents) do
		if event.Id == eventId then
			eventData = {
				Id = event.Id,
				Name = event.Name,
				Multiplier = event.Multiplier,
				Icon = event.Icon,
				Color = event.Color,
			}
			break
		end
	end

	if not eventData then
		warn(string.format("⚠️ [EVENT MANAGER] Event not found: %s", eventId))
		return false
	end

	-- Update state lokal server ini
	CurrentActiveEvent = eventData
	-- Simpan ke DataStore (untuk server baru yang join nanti)
	saveEventToDataStore(eventData)
	-- Broadcast ke player di server ini
	broadcastEventChange()
	-- Kirim ke semua server lain via MessagingService
	publishEventChange("activate", eventData)

	print(string.format("[EVENT MANAGER] 🎉 Event ACTIVATED: %s (x%d) — broadcast to all servers", eventData.Name, eventData.Multiplier))
	return true
end

-- ============================================================
-- Deactivate event: hapus dari DS + broadcast ke semua server
-- ============================================================
local function deactivateEvent()
	-- Update state lokal server ini
	CurrentActiveEvent = nil
	-- Hapus dari DataStore dengan RemoveAsync (bukan SetAsync nil)
	saveEventToDataStore(nil)
	-- Broadcast ke player di server ini
	broadcastEventChange()
	-- Kirim ke semua server lain via MessagingService
	publishEventChange("deactivate", nil)

	print("[EVENT MANAGER] 🛑 Event DEACTIVATED — broadcast to all servers")
	return true
end

-- ============================================================
-- Fungsi utilitas
-- ============================================================
local function getEventMultiplier()
	if CurrentActiveEvent then
		return CurrentActiveEvent.Multiplier
	end
	return 1
end

-- ============================================================
-- Subscribe ke MessagingService untuk menerima perubahan dari server lain
-- ============================================================
local function setupCrossServerSync()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(MESSAGING_TOPIC, function(message)
			local payload = message.Data
			if not payload or not payload.action then return end

			if payload.action == "activate" and payload.eventData then
				print(string.format("[EVENT MANAGER] 📡 Cross-server ACTIVATE received: %s", payload.eventData.Id or "?"))
				applyEventState(payload.eventData)

				-- Notifikasi player lokal di server ini
				for _, p in ipairs(Players:GetPlayers()) do
					NotificationService:Send(p, {
						Message = string.format("%s is now active! (x%d Summit)", payload.eventData.Name or "Event", payload.eventData.Multiplier or 1),
						Type = "info",
						Duration = 5,
						Icon = CurrentActiveEvent and CurrentActiveEvent.Icon or "🎉",
					})
				end

			elseif payload.action == "deactivate" then
				print("[EVENT MANAGER] 📡 Cross-server DEACTIVATE received")
				applyEventState(nil)

				-- Notifikasi player lokal di server ini
				for _, p in ipairs(Players:GetPlayers()) do
					NotificationService:Send(p, {
						Message = "Event has ended",
						Type = "info",
						Duration = 3,
					})
				end
			end
		end)
	end)

	if ok then
		print("[EVENT MANAGER] ✅ MessagingService cross-server sync ready")
	else
		warn("[EVENT MANAGER] ⚠️ MessagingService subscribe failed (mungkin di Studio):", err)
		-- Di Studio MessagingService tidak bisa, tapi di live server bisa
	end
end

-- ============================================================
-- Handler RemoteFunction & RemoteEvent dari client (admin panel)
-- ============================================================
getActiveEventFunc.OnServerInvoke = function(player)
	return CurrentActiveEvent
end

setEventRemote.OnServerEvent:Connect(function(player, action, eventId)
	if not isAdmin(player) then
		NotificationService:Send(player, {
			Message = "You don't have permission!",
			Type = "error",
			Duration = 3,
		})
		return
	end

	if action == "activate" then
		local success = activateEvent(eventId)
		if success then
			NotificationService:Send(player, {
				Message = string.format("🎉 Event %s activated on ALL servers!", CurrentActiveEvent.Name),
				Type = "success",
				Duration = 5,
				Icon = "🎉",
			})
		end

	elseif action == "deactivate" then
		deactivateEvent()
		NotificationService:Send(player, {
			Message = "🛑 Event deactivated on ALL servers!",
			Type = "info",
			Duration = 3,
		})
	end
end)

-- ============================================================
-- Init: load dari DataStore + subscribe cross-server
-- ============================================================
loadEventFromDataStore()
setupCrossServerSync()

-- Notif ke player baru yang join saat event sedang aktif
Players.PlayerAdded:Connect(function(player)
	task.wait(5)
	if CurrentActiveEvent then
		NotificationService:Send(player, {
			Message = string.format("%s is active! (x%d Summit)", CurrentActiveEvent.Name, CurrentActiveEvent.Multiplier),
			Type = "info",
			Duration = 7,
			Icon = CurrentActiveEvent.Icon,
		})
	end
end)

-- ============================================================
-- Public API
-- ============================================================
local EventManager = {}

function EventManager:GetMultiplier()
	return getEventMultiplier()
end

function EventManager:GetActiveEvent()
	return CurrentActiveEvent
end

return EventManager
