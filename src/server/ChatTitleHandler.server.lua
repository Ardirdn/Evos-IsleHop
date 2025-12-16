--[[
    CHAT TITLE SERVER (FIXED - SENDS INITIAL TITLES)
    Handles chat title integration with TextChatService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for TitleServer
local TitleServer = require(script.Parent:WaitForChild("TitleServer"))
local DataHandler = require(script.Parent:WaitForChild("DataHandler"))

print("✅ [CHAT TITLE SERVER] Initializing...")

-- Get or create TitleRemotes folder
local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not titleRemotes then
	titleRemotes = Instance.new("Folder")
	titleRemotes.Name = "TitleRemotes"
	titleRemotes.Parent = ReplicatedStorage
end

-- ✅ CREATE ChatTitleUpdate RemoteEvent
local chatTitleUpdate = titleRemotes:FindFirstChild("ChatTitleUpdate")
if not chatTitleUpdate then
	chatTitleUpdate = Instance.new("RemoteEvent")
	chatTitleUpdate.Name = "ChatTitleUpdate"
	chatTitleUpdate.Parent = titleRemotes
end

-- Get BroadcastTitle (already created by TitleServer)
local BroadcastTitle = titleRemotes:WaitForChild("BroadcastTitle", 10)
if not BroadcastTitle then
	warn("[CHAT TITLE SERVER] BroadcastTitle not found!")
end

-- ✅ Helper: Get player's current title (check EquippedTitle first, then Title, then SpecialTitle)
local function getPlayerTitle(data)
	if data.EquippedTitle then
		return data.EquippedTitle
	elseif data.SpecialTitle then
		return data.SpecialTitle
	elseif data.Title and data.Title ~= "Pengunjung" then
		return data.Title
	end
	return nil
end

-- ✅ FIX: Send initial title to client when player joins
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		-- Wait for data to load with retry
		local data = nil
		local attempts = 0
		
		while attempts < 15 do
			task.wait(1)
			attempts = attempts + 1
			data = DataHandler:GetData(player)
			if data then break end
		end
		
		if not player or not player.Parent then return end
		
		if data then
			local title = getPlayerTitle(data)
			if title then
				-- Send to ALL clients so they know this player's title
				chatTitleUpdate:FireAllClients(player.UserId, title)
				print(string.format("[CHAT TITLE] Sent initial title for %s: %s", player.Name, title))
			else
				print(string.format("[CHAT TITLE] No title to send for %s", player.Name))
			end
		else
			warn(string.format("[CHAT TITLE] Failed to get data for %s after %d attempts", player.Name, attempts))
		end
	end)
end)

-- ✅ FIX: Also send existing players' titles to new joiner
Players.PlayerAdded:Connect(function(newPlayer)
	task.spawn(function()
		-- Wait longer for new player to fully load
		task.wait(8)
		
		if not newPlayer or not newPlayer.Parent then return end
		
		-- Send all current player titles to new joiner
		local sentCount = 0
		for _, existingPlayer in ipairs(Players:GetPlayers()) do
			if existingPlayer ~= newPlayer then
				local data = DataHandler:GetData(existingPlayer)
				if data then
					local title = getPlayerTitle(data)
					if title then
						chatTitleUpdate:FireClient(newPlayer, existingPlayer.UserId, title)
						sentCount = sentCount + 1
					end
				end
			end
		end
		
		print(string.format("[CHAT TITLE] Sent %d existing player titles to %s", sentCount, newPlayer.Name))
	end)
end)

-- NOTE: BroadcastTitle is a RemoteEvent - client listens via OnClientEvent
-- ChatTitleClient already listens to BroadcastTitle.OnClientEvent

print("✅ [CHAT TITLE SERVER] Loaded with initial title sync")
