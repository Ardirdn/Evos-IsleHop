local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TitleServer = require(script.Parent:WaitForChild("TitleServer"))
local DataHandler = require(script.Parent:WaitForChild("DataHandler"))

local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not titleRemotes then
	titleRemotes = Instance.new("Folder")
	titleRemotes.Name = "TitleRemotes"
	titleRemotes.Parent = ReplicatedStorage
end

local chatTitleUpdate = titleRemotes:FindFirstChild("ChatTitleUpdate")
if not chatTitleUpdate then
	chatTitleUpdate = Instance.new("RemoteEvent")
	chatTitleUpdate.Name = "ChatTitleUpdate"
	chatTitleUpdate.Parent = titleRemotes
end

local BroadcastTitle = titleRemotes:WaitForChild("BroadcastTitle", 10)
if not BroadcastTitle then
	warn("[CHAT TITLE SERVER] BroadcastTitle not found!")
end

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

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
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
				chatTitleUpdate:FireAllClients(player.UserId, title)
			else
			end
		else
			warn(string.format("[CHAT TITLE] Failed to get data for %s after %d attempts", player.Name, attempts))
		end
	end)
end)

Players.PlayerAdded:Connect(function(newPlayer)
	task.spawn(function()
		task.wait(8)

		if not newPlayer or not newPlayer.Parent then return end

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

	end)
end)
