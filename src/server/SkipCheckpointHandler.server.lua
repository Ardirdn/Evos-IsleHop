local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)

local SKIP_PRODUCT_ID = 3524123407

_G.SKIP_PRODUCT_ID = SKIP_PRODUCT_ID

local checkpointsFolder = workspace:WaitForChild("Checkpoints", 10)
if not checkpointsFolder then
	warn("❌ [SKIP CHECKPOINT] Checkpoints folder not found!")
	return
end
local checkpoints = {}
local maxCheckpointNum = 0

for _, checkpoint in pairs(checkpointsFolder:GetChildren()) do
	if checkpoint:IsA("BasePart") and checkpoint.Name:match("Checkpoint%d+") then
		local number = tonumber(checkpoint.Name:match("%d+"))
		checkpoints[number] = checkpoint
		if number > maxCheckpointNum then
			maxCheckpointNum = number
		end
	end
end

print(string.format("[SKIP CHECKPOINT] Found checkpoints 0-%d, setting up skip boards...", maxCheckpointNum))

-- Debug: log all checkpoint numbers found
local checkpointNums = {}
for num, _ in pairs(checkpoints) do
	table.insert(checkpointNums, num)
end
table.sort(checkpointNums)
print(string.format("[SKIP CHECKPOINT] Checkpoint numbers found: %s", table.concat(checkpointNums, ", ")))

local setupCount = 0
local skippedCount = 0
local missingBoardCount = 0
local missingPromptCount = 0

for checkpointNum, checkpoint in pairs(checkpoints) do
	print(string.format("[SKIP DEBUG] Processing Checkpoint%d...", checkpointNum))
	
	-- Skip checkpoint terakhir karena tidak ada lagi yang bisa di-skip
	if checkpointNum >= maxCheckpointNum then
		print(string.format("[SKIP] Skipping Checkpoint%d (last checkpoint, no next to skip to)", checkpointNum))
		skippedCount = skippedCount + 1
		continue
	end

	local skipBoard = checkpoint:FindFirstChild("SkipBoard")
	if not skipBoard then
		warn(string.format("[SKIP] ❌ SkipBoard NOT FOUND in Checkpoint%d", checkpointNum))
		missingBoardCount = missingBoardCount + 1
		continue
	end
	
	print(string.format("[SKIP DEBUG] Found SkipBoard in Checkpoint%d", checkpointNum))

	local proximityPrompt = skipBoard:FindFirstChild("ProximityPrompt")
	if not proximityPrompt then
		warn(string.format("[SKIP] ❌ ProximityPrompt NOT FOUND in Checkpoint%d/SkipBoard - Creating new one!", checkpointNum))
		
		-- Create a new ProximityPrompt if missing
		proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.Name = "ProximityPrompt"
		proximityPrompt.ActionText = "Skip"
		proximityPrompt.ObjectText = "Skip Checkpoint"
		proximityPrompt.MaxActivationDistance = 10
		proximityPrompt.HoldDuration = 0
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Enabled = true
		proximityPrompt.Parent = skipBoard
		
		print(string.format("[SKIP] ✅ Created new ProximityPrompt for Checkpoint%d", checkpointNum))
	end

	-- Log current properties for debugging
	print(string.format("[SKIP DEBUG] Checkpoint%d ProximityPrompt properties: Enabled=%s, MaxDist=%.1f, RequiresLOS=%s, HoldDuration=%.1f", 
		checkpointNum,
		tostring(proximityPrompt.Enabled),
		proximityPrompt.MaxActivationDistance,
		tostring(proximityPrompt.RequiresLineOfSight),
		proximityPrompt.HoldDuration
	))

	-- FIX: Ensure ProximityPrompt is properly configured
	local needsFix = false
	
	if not proximityPrompt.Enabled then
		warn(string.format("[SKIP FIX] Checkpoint%d: ProximityPrompt was DISABLED - Enabling it!", checkpointNum))
		proximityPrompt.Enabled = true
		needsFix = true
	end
	
	if proximityPrompt.MaxActivationDistance < 5 then
		warn(string.format("[SKIP FIX] Checkpoint%d: MaxActivationDistance too small (%.1f) - Setting to 10!", checkpointNum, proximityPrompt.MaxActivationDistance))
		proximityPrompt.MaxActivationDistance = 10
		needsFix = true
	end
	
	if proximityPrompt.RequiresLineOfSight then
		warn(string.format("[SKIP FIX] Checkpoint%d: RequiresLineOfSight was true - Setting to false!", checkpointNum))
		proximityPrompt.RequiresLineOfSight = false
		needsFix = true
	end
	
	if needsFix then
		print(string.format("[SKIP FIX] Checkpoint%d ProximityPrompt FIXED!", checkpointNum))
	end

	-- Setup the proximity prompt trigger
	print(string.format("[SKIP] ✅ Setting up ProximityPrompt for Checkpoint%d", checkpointNum))
	
	proximityPrompt.Triggered:Connect(function(player)
		print(string.format("[SKIP TRIGGERED] Player %s triggered skip at Checkpoint%d", player.Name, checkpointNum))

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
		print(string.format("[SKIP TRIGGERED] Player %s current checkpoint: %d, board checkpoint: %d", player.Name, currentCheckpoint, checkpointNum))

		if currentCheckpoint ~= checkpointNum then
			NotificationService:Send(player, {
				Message = "Kamu harus ada di checkpoint ini untuk skip!",
				Type = "warning",
				Duration = 3
			})
			return
		end

		print(string.format("[SKIP TRIGGERED] Prompting product purchase for %s", player.Name))
		MarketplaceService:PromptProductPurchase(player, SKIP_PRODUCT_ID)
	end)
	
	setupCount = setupCount + 1
end

print(string.format("[SKIP CHECKPOINT] Setup complete! ✅ Setup: %d, ⏭️ Skipped (last): %d, ❌ Missing SkipBoard: %d, ❌ Missing ProximityPrompt: %d", 
	setupCount, skippedCount, missingBoardCount, missingPromptCount))

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
