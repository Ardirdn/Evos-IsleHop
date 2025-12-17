local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)

local SKIP_PRODUCT_ID = 3477254962

_G.SKIP_PRODUCT_ID = SKIP_PRODUCT_ID

local checkpointsFolder = workspace:WaitForChild("Checkpoints", 10)
if not checkpointsFolder then
	warn("❌ [SKIP CHECKPOINT] Checkpoints folder not found!")
	return
end
local checkpoints = {}

for _, checkpoint in pairs(checkpointsFolder:GetChildren()) do
	if checkpoint:IsA("BasePart") and checkpoint.Name:match("Checkpoint%d+") then
		local number = tonumber(checkpoint.Name:match("%d+"))
		checkpoints[number] = checkpoint
	end
end

for checkpointNum, checkpoint in pairs(checkpoints) do

	if checkpointNum >= #checkpoints then
		continue
	end

	local skipBoard = checkpoint:FindFirstChild("SkipBoard")
	if not skipBoard then
		warn("[SKIP] SkipBoard not found in Checkpoint" .. checkpointNum)
		continue
	end

	local proximityPrompt = skipBoard:FindFirstChild("ProximityPrompt")
	if not proximityPrompt then
		warn("[SKIP] ProximityPrompt not found in Checkpoint" .. checkpointNum)
		continue
	end

	proximityPrompt.Triggered:Connect(function(player)

		local data = DataHandler:GetData(player)
		if not data then
			NotificationService:Send(player, {
				Message = "Data not loaded!",
				Type = "error",
				Duration = 3
			})
			return
		end

		local currentCheckpoint = data.LastCheckpoint

		if currentCheckpoint ~= checkpointNum then
			NotificationService:Send(player, {
				Message = "Kamu harus ada di checkpoint ini untuk skip!",
				Type = "warning",
				Duration = 3
			})
			return
		end

		MarketplaceService:PromptProductPurchase(player, SKIP_PRODUCT_ID)
	end)
end

local pendingSkips = {}

local remoteFolder = ReplicatedStorage:FindFirstChild("SkipCheckpointRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "SkipCheckpointRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local executeSkipEvent = remoteFolder:FindFirstChild("ExecuteSkip")
if not executeSkipEvent then
	executeSkipEvent = Instance.new("BindableEvent")
	executeSkipEvent.Name = "ExecuteSkip"
	executeSkipEvent.Parent = remoteFolder
end

local function executeSkip(player)
	local character = player.Character
	if not character then return end

	local data = DataHandler:GetData(player)
	if not data then return end

	local currentCheckpoint = data.LastCheckpoint
	local nextCheckpoint = currentCheckpoint + 1

	if not checkpoints[nextCheckpoint] then
		NotificationService:Send(player, {
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
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = string.format("🚀 Skipped to Checkpoint %d!", nextCheckpoint),
		Type = "success",
		Duration = 3,
		Icon = "⚡"
	})

end

executeSkipEvent.Event:Connect(function(player)
	executeSkip(player)
end)

_G.ExecuteSkipCheckpoint = function(player)
	executeSkip(player)
end
