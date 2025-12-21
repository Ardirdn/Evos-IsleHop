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
	MAX_ENTRIES = 10,
	INITIAL_DELAY = 5,
}

local leaderboardsFolder = workspace:WaitForChild("Leaderboards", 10)
if not leaderboardsFolder then
	warn("[LEADERBOARD SERVER] ❌ Leaderboards folder not found in Workspace!")
	return
end

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

local playerNameCache = {}
local function getPlayerName(userId)
	if playerNameCache[userId] then
		return playerNameCache[userId]
	end

	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success and name then
		playerNameCache[userId] = name
		return name
	end

	return "Player"
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
	
	print(string.format("[POPULATE DEBUG] Type: %s, ScrollingFrame: %s, Sample: %s, Entries: %d",
		leaderboardType, 
		scrollingFrame and scrollingFrame:GetFullName() or "nil",
		sample and sample.Name or "nil",
		#entries))

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
			print(string.format("[POPULATE DEBUG] Created donation entry: rank=%d, name=%s, value=%s, parent=%s",
				rank, entry.displayName, tostring(entry.value), scrollingFrame:GetFullName()))
		end

		newFrame.Parent = scrollingFrame
	end
	
	-- Debug: count entries after populate
	local entryCount = 0
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Sample" and child.Visible then
			entryCount = entryCount + 1
		end
	end
	print(string.format("[POPULATE DEBUG] After populate: %d visible entries in scrollframe", entryCount))
end

local function updateSummitLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Summit")
	if #leaderboards == 0 then return end

	local success, data = pcall(function()
		return SummitLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)

	if not success then
		warn("[LEADERBOARD] Failed to fetch Summit data")
		return
	end

	local page = data:GetCurrentPage()
	local entries = {}

	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)

		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = entry.value
		})
	end

	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Summit")
	end

end

local function updateSpeedrunLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Speedrun")
	if #leaderboards == 0 then return end

	local success, data = pcall(function()
		return SpeedrunLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)

	if not success then
		warn("[LEADERBOARD] Failed to fetch Speedrun data")
		return
	end

	local page = data:GetCurrentPage()
	local entries = {}

	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		local rawValue = math.abs(entry.value)
		-- Data was stored with double multiplier (ms * 1000), so divide by 1,000,000
		local timeSeconds = rawValue / 1000000
		
		print(string.format("[SPEEDRUN DEBUG] Rank %d: rawValue=%d, timeSeconds=%.2f, formatted=%s",
			rank, entry.value, timeSeconds, formatSpeedrunTime(timeSeconds)))

		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = rawValue,
			formattedValue = formatSpeedrunTime(timeSeconds)
		})
	end

	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Speedrun")
	end

end

local function updatePlaytimeLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Playtime")
	if #leaderboards == 0 then return end

	local success, data = pcall(function()
		return PlaytimeLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)

	if not success then
		warn("[LEADERBOARD] Failed to fetch Playtime data")
		return
	end

	local page = data:GetCurrentPage()
	local entries = {}

	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		local playtime = entry.value

		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = playtime,
			formattedValue = formatPlaytime(playtime)
		})
	end

	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Playtime")
	end

end

local function updateDonationLeaderboards()
	local leaderboards = findAllLeaderboardsOfType("Donation")
	print("[DONATION DEBUG] Found " .. #leaderboards .. " donation leaderboard(s)")
	if #leaderboards == 0 then return end

	local success, data = pcall(function()
		return DonationLeaderboard:GetSortedAsync(false, CONFIG.MAX_ENTRIES)
	end)

	if not success then
		warn("[LEADERBOARD] Failed to fetch Donation data: " .. tostring(data))
		return
	end

	local page = data:GetCurrentPage()
	local entries = {}
	
	print("[DONATION DEBUG] Got " .. #page .. " entries from DataStore")

	for rank, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		local displayName = getPlayerName(userId)
		
		print(string.format("[DONATION DEBUG] Entry %d: userId=%s, name=%s, value=%s", 
			rank, tostring(userId), displayName, tostring(entry.value)))

		table.insert(entries, {
			rank = rank,
			userId = userId,
			displayName = displayName,
			value = entry.value
		})
	end
	
	print("[DONATION DEBUG] Populating " .. #entries .. " entries to " .. #leaderboards .. " leaderboard(s)")

	for _, leaderboardData in ipairs(leaderboards) do
		populateLeaderboard(leaderboardData, entries, "Donation")
	end

end

local function updateAllLeaderboards()

	updateSummitLeaderboards()
	updateSpeedrunLeaderboards()
	updatePlaytimeLeaderboards()
	updateDonationLeaderboards()

end

leaderboardsFolder.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "Sample" and descendant:IsA("Frame") then
		task.wait(0.5)
		updateAllLeaderboards()
	end
end)

task.spawn(function()
	task.wait(CONFIG.INITIAL_DELAY)

	updateAllLeaderboards()

	while true do
		task.wait(CONFIG.UPDATE_INTERVAL)
		updateAllLeaderboards()
	end
end)

task.defer(function()
	task.wait(1)

	local types = {"Summit", "Speedrun", "Playtime", "Donation"}

	for _, leaderboardType in ipairs(types) do
		local found = findAllLeaderboardsOfType(leaderboardType)
		if #found > 0 then
			for i, data in ipairs(found) do
			end
		else
		end
	end
end)

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
