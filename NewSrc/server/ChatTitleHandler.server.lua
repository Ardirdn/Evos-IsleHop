local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TitleServer = require(script.Parent:WaitForChild("TitleServer"))

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
	return
end
