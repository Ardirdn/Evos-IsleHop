local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataStoreConfig"))

local SummitLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Summit)
local SpeedrunLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Speedrun)
local PlaytimeLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Playtime)
local DonationLeaderboard = DataStoreService:GetOrderedDataStore(DataStoreConfig.Leaderboards.Donation)

local CONFIG = {
	UPDATE_INTERVAL = 60,
	MAX_ENTRIES = 100,  -- Keep low for fast name lookups (like template)
	INITIAL_DELAY = 3,
}

local leaderboardsFolder = workspace:WaitForChild("Leaderboards", 10)
if not leaderboardsFolder then
	warn("[LEADERBOARD SERVER] ❌ Leaderboards folder not found in Workspace!")
	return
end

print("[LEADERBOARD SERVER] Starting...")

-- Player name cache
local playerNameCache = {}

local function formatSpeedrunTime(seconds)
	local totalMinutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	
	if totalMinutes > 0 then
		return string.format("%dm %ds", totalMinutes, secs)
	else
		return string.format("%ds", secs)
	end
end

local function formatPlaytime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if days > 0 then
		return string.format("%dd %dh %dm", days, hours, minutes)
	elseif hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

local function getPlayerName(userId)
	-- Return cached immediately
	if playerNameCache[userId] then
		return playerNameCache[userId]
	end
	
	-- Check if player is currently in game (instant)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		playerNameCache[userId] = player.Name
		return player.Name
	end

	-- Sync lookup like template (only 20 entries so it's fast)
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success and name then
		playerNameCache[userId] = name
		return name
	end
	
	-- Fallback for Studio test players or failed lookups
	return "Player" .. tostring(userId):sub(-4)
end


local function getLeaderboardType(name)
	local lowerName = name:lower()

	if lowerName:match("summit") then
		return "Summit"
	elseif lowerName:match("speedrun") then
		return "Speedrun"
	elseif lowerName:match("playtime") then
		return "Playtime"
	elseif lowerName:match("donation") or lowerName:match("donate") then
		return "Donation"
	end

	return nil
end

local function findAllLeaderboardsOfType(leaderboardType)
	local found = {}

	for _, child in pairs(leaderboardsFolder:GetDescendants()) do
		if child:IsA("BasePart") or child:IsA("Model") then
			local detectedType = getLeaderboardType(child.Name)

			if detectedType == leaderboardType then
				local screen = child:FindFirstChild("Screen")
				if screen then
					local surfaceGui = screen:FindFirstChild("SurfaceGui")
					if surfaceGui then
						local scrollingFrame = surfaceGui:FindFirstChild("ScrollingFrame")
						if scrollingFrame then
							local sample = scrollingFrame:FindFirstChild("Sample")
							if sample then
								table.insert(found, {
									Container = child,
									Screen = screen,
									SurfaceGui = surfaceGui,
									ScrollingFrame = scrollingFrame,
									Sample = sample
								})
							end
						end
					end
				end
			end
		end
	end

	return found
end

local function clearEntries(scrollingFrame)
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Sample" then
			child:Destroy()
		end
	end
end

local function populateLeaderboard(leaderboardData, entries, leaderboardType)
	local scrollingFrame = leaderboardData.ScrollingFrame
	local sample = leaderboardData.Sample

	sample.Visible = false
	clearEntries(scrollingFrame)

	for rank, entry in ipairs(entries) do
		local newFrame = sample:Clone()
		newFrame.Name = "Entry" .. rank
		newFrame.Visible = true
		newFrame.LayoutOrder = rank

		local rankLabel = newFrame:FindFirstChild("Rank")
		if rankLabel then
			rankLabel.Text = "#" .. rank
		end

		local nameLabel = newFrame:FindFirstChild("PlayerName")
		if nameLabel then
			nameLabel.Text = entry.displayName
		end

		if leaderboardType == "Summit" then
			local valueLabel = newFrame:FindFirstChild("Summits") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = tostring(entry.value)
			end

		elseif leaderboardType == "Speedrun" then
			local valueLabel = newFrame:FindFirstChild("Time") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = entry.formattedValue
			end

		elseif leaderboardType == "Playtime" then
			local valueLabel = newFrame:FindFirstChild("Playtime") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = entry.formattedValue
			end

		elseif leaderboardType == "Donation" then
			local valueLabel = newFrame:FindFirstChild("Amount") or newFrame:FindFirstChild("Value")
			if valueLabel then
				valueLabel.Text = "R$" .. tostring(entry.value)
			end
		end

		newFrame.Parent = scrollingFrame
	end
	
	-- Update CanvasSize to fit all entries
	local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
	if layout then
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	else
		-- Fallback: estimate based on sample height
		local sampleHeight = sample.AbsoluteSize.Y
		if sampleHeight == 0 then sampleHeight = 30 end
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, (#entries * sampleHeight) + 10)
	end
	
	print("[LEADERBOARD] Populated " .. #entries .. " entries to " .. leaderboardType)
end


-- Standard update function
local function updateLeaderboard(orderedDataStore, leaderboardType, formatFunc)
	print("[LEADERBOARD] Updating " .. leaderboardType .. "...")
	
	local leaderboards = findAllLeaderboardsOfType(leaderboardType)
	print("[LEADERBOARD] Found " .. #leaderboards .. " " .. leaderboardType .. " leaderboards")
	if #leaderboards == 0 then 
		return 
	end

	local success, pages = pcall(function()
		return orderedDataStore:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)

	if not success then
		warn("[LEADERBOARD] Failed to get " .. leaderboardType .. " data: " .. tostring(pages))
		return
	end

	print("[LEADERBOARD] Got pages for " .. leaderboardType)
	
	local page = pages:GetCurrentPage()
	print("[LEADERBOARD] Got " .. #page .. " entries from " .. leaderboardType .. " DataStore")
	
	local entries = {}


	for rank, data in ipairs(page) do
		local userId = tonumber(data.key)
		-- Use cached name if available, otherwise use userId (names fetched in background)
		local displayName = playerNameCache[userId] or tostring(userId)
		local value = data.value
		local formattedValue = formatFunc and formatFunc(value) or tostring(value)

		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = value,
			formattedValue = formattedValue
		})
	end



	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, leaderboardType)
	end
	
	-- Background task to fetch real names for next refresh
	task.spawn(function()
		for _, entry in ipairs(entries) do
			local userId = entry.userId
			if not playerNameCache[userId] then
				local success, name = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if success and name then
					playerNameCache[userId] = name
				end
				task.wait(0.05)  -- Small delay to avoid throttling
			end
		end
	end)
end


local function updateSummitLeaderboards()
	updateLeaderboard(SummitLeaderboard, "Summit", nil)
end

local function updateSpeedrunLeaderboards()
	updateLeaderboard(SpeedrunLeaderboard, "Speedrun", function(value)
		local rawValue = math.abs(value)
		local timeSeconds = rawValue / 1000000
		return formatSpeedrunTime(timeSeconds)
	end)
end

local function updatePlaytimeLeaderboards()
	updateLeaderboard(PlaytimeLeaderboard, "Playtime", formatPlaytime)
end

local function updateDonationLeaderboards()
	updateLeaderboard(DonationLeaderboard, "Donation", nil)
end

local function updateAllLeaderboards()
	updateSummitLeaderboards()
	updateSpeedrunLeaderboards()
	updatePlaytimeLeaderboards()
	updateDonationLeaderboards()
end

-- Setup countdown labels
local countdownLabels = {}
local lastUpdateTime = 0

local function setupCountdownLabels()
	for _, descendant in pairs(leaderboardsFolder:GetDescendants()) do
		if descendant:IsA("SurfaceGui") then
			local existing = descendant:FindFirstChild("CountdownLabel")
			if not existing then
				local countdownLabel = Instance.new("TextLabel")
				countdownLabel.Name = "CountdownLabel"
				countdownLabel.Size = UDim2.new(1, 0, 0, 28)
				countdownLabel.Position = UDim2.new(0, 0, 1, -32)
				countdownLabel.BackgroundTransparency = 0.2
				countdownLabel.BackgroundColor3 = Color3.fromRGB(30, 100, 180)
				countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				countdownLabel.Font = Enum.Font.GothamBold
				countdownLabel.TextSize = 16
				countdownLabel.Text = "🔄 Refresh in 60s"
				countdownLabel.Parent = descendant
				
				table.insert(countdownLabels, countdownLabel)
			else
				table.insert(countdownLabels, existing)
			end
		end
	end
	print("[LEADERBOARD] Setup " .. #countdownLabels .. " countdown labels")
end

local function updateCountdownLabels()
	local timeLeft = math.max(0, CONFIG.UPDATE_INTERVAL - (tick() - lastUpdateTime))
	local text = "🔄 Refresh in " .. math.ceil(timeLeft) .. "s"
	
	for _, label in ipairs(countdownLabels) do
		if label and label.Parent then
			label.Text = text
		end
	end
end

-- Main loop
task.spawn(function()
	print("[LEADERBOARD] Waiting " .. CONFIG.INITIAL_DELAY .. " seconds before first update...")
	task.wait(CONFIG.INITIAL_DELAY)
	
	setupCountdownLabels()
	
	lastUpdateTime = tick()
	print("[LEADERBOARD] Running initial update...")
	updateAllLeaderboards()
	print("[LEADERBOARD] Initial update complete!")

	while true do
		task.wait(1)
		updateCountdownLabels()
		
		if tick() - lastUpdateTime >= CONFIG.UPDATE_INTERVAL then
			lastUpdateTime = tick()
			print("[LEADERBOARD] Running periodic update...")
			updateAllLeaderboards()
			print("[LEADERBOARD] Periodic update complete!")
		end
	end
end)

-- Listen for refresh events from other scripts
local refreshEvent = game.ServerScriptService:FindFirstChild("RefreshLeaderboardsEvent")
if not refreshEvent then
	refreshEvent = Instance.new("BindableEvent")
	refreshEvent.Name = "RefreshLeaderboardsEvent"
	refreshEvent.Parent = game.ServerScriptService
end

refreshEvent.Event:Connect(function(leaderboardType)
	if leaderboardType == "Summit" then
		updateSummitLeaderboards()
	elseif leaderboardType == "Donation" then
		updateDonationLeaderboards()
	elseif leaderboardType == "Playtime" then
		updatePlaytimeLeaderboards()
	elseif leaderboardType == "Speedrun" then
		updateSpeedrunLeaderboards()
	elseif leaderboardType == "All" or leaderboardType == nil then
		updateAllLeaderboards()
	end
end)

print("[LEADERBOARD SERVER] Ready!")
