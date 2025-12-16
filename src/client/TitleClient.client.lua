--[[
    TITLE CLIENT v4.0 (SUPER SIMPLE - NO LAG)
    ✅ NO FireAllClients - each client fetches titles locally
    ✅ NO server broadcasts - client pulls data when needed
    ✅ Minimal connections - no event spam
    ✅ Support for Hide Title setting
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules", 10):WaitForChild("TitleConfig", 10))

local remoteFolder = ReplicatedStorage:WaitForChild("TitleRemotes", 10)
if not remoteFolder then
	warn("❌ [TITLE CLIENT] TitleRemotes not found!")
	return
end

local getTitleFunc = remoteFolder:WaitForChild("GetTitle", 5)

-- Cache
local billboardCache = {}
local playerCountries = {}

-- ✅ Hide title setting
local hideTitlesEnabled = false

-- Config
local CONFIG = {
	MAX_DISTANCE = 100,
}

-- Design
local DESIGN = {
	TextColor = Color3.fromRGB(255, 255, 255),
	TitleColor = Color3.fromRGB(200, 200, 205),
	MoneyColor = Color3.fromRGB(255, 255, 255),  -- ✅ Changed to WHITE (was green)
	SummitColor = Color3.fromRGB(255, 255, 255), -- ✅ Changed to WHITE (was yellow)
	DefaultAccent = Color3.fromRGB(80, 80, 90),
	MainFont = Enum.Font.FredokaOne,  -- ✅ Clean modern font for all text
}

-- ✅ Function to hide/show all titles (called from SettingsClient)
local function setHideTitles(value)
	hideTitlesEnabled = value
	
	-- Hide/show ALL billboards (including own when enabled)
	for targetPlayer, billboard in pairs(billboardCache) do
		if billboard and billboard.Parent then
			billboard.Enabled = not value
		end
	end
	
	-- Also find any billboards that might not be in cache
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			local head = otherPlayer.Character:FindFirstChild("Head")
			if head then
				local billboard = head:FindFirstChild("PlayerInfoBillboard")
				if billboard then
					billboard.Enabled = not value
				end
			end
		end
	end
	
	print(string.format("🏷️ [TITLE] Hide titles: %s", tostring(value)))
end

-- Export for SettingsClient
_G.SetHideTitles = setHideTitles

-- ==================== BILLBOARD CREATION ====================

local function createBillboard(character, targetPlayer)
	local head = character:WaitForChild("Head", 5)
	if not head then return nil end

	local existing = head:FindFirstChild("PlayerInfoBillboard")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerInfoBillboard"
	billboard.Size = UDim2.new(6, 0, 3.5, 0)  -- ✅ TALLER for 4 vertical rows
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)  -- ✅ Adjusted offset
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = CONFIG.MAX_DISTANCE
	billboard.LightInfluence = 0
	
	-- ✅ Respect hide title setting (hide ALL billboards when enabled)
	if hideTitlesEnabled then
		billboard.Enabled = false
	end
	
	billboard.Parent = head

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = billboard

	-- ✅ NEW LAYOUT: 4 vertical rows (Title, Name, Summit, Money)
	-- Each row = 25% height

	-- Row 1: Title Label (top)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)  -- Row 1: 0%
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = DESIGN.MainFont
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = DESIGN.TitleColor
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Text = "👤 Visitor"
	titleLabel.Parent = mainFrame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Transparency = 0.3
	titleStroke.Parent = titleLabel

	-- Row 2: Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.28, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.22, 0)  -- Row 2: 22%
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = DESIGN.MainFont
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = DESIGN.TextColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Text = targetPlayer.DisplayName
	nameLabel.Parent = mainFrame

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Transparency = 0.2
	nameStroke.Parent = nameLabel

	-- ✅ REMOVED: Accent Bar (user requested no colored line)

	-- Row 3: Summit Label (below name) - SMALLER TEXT
	local summitsLabel = Instance.new("TextLabel")
	summitsLabel.Name = "SummitsLabel"
	summitsLabel.Size = UDim2.new(1, 0, 0.14, 0)  -- ✅ SMALLER (was 0.22)
	summitsLabel.Position = UDim2.new(0, 0, 0.55, 0)  -- Adjusted position
	summitsLabel.BackgroundTransparency = 1
	summitsLabel.Font = DESIGN.MainFont
	summitsLabel.TextScaled = true
	summitsLabel.TextColor3 = DESIGN.SummitColor
	summitsLabel.TextXAlignment = Enum.TextXAlignment.Center
	summitsLabel.Text = "⛰️ 0"
	summitsLabel.Parent = mainFrame

	local summitStroke = Instance.new("UIStroke")
	summitStroke.Color = Color3.fromRGB(0, 0, 0)
	summitStroke.Thickness = 1.5
	summitStroke.Transparency = 0.3
	summitStroke.Parent = summitsLabel

	-- Row 4: Money Label (bottom) - SMALLER TEXT
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(1, 0, 0.14, 0)  -- ✅ SMALLER (was 0.22)
	moneyLabel.Position = UDim2.new(0, 0, 0.70, 0)  -- Adjusted position
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = DESIGN.MainFont
	moneyLabel.TextScaled = true
	moneyLabel.TextColor3 = DESIGN.MoneyColor
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
	moneyLabel.Text = "💵 $0"
	moneyLabel.Parent = mainFrame

	local moneyStroke = Instance.new("UIStroke")
	moneyStroke.Color = Color3.fromRGB(0, 0, 0)
	moneyStroke.Thickness = 1.5
	moneyStroke.Transparency = 0.3
	moneyStroke.Parent = moneyLabel

	billboardCache[targetPlayer] = billboard
	return billboard
end

-- ==================== UPDATE FUNCTIONS ====================

local function updateTitle(targetPlayer, titleName)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	if not mainFrame then return end

	-- local accentBar = mainFrame:FindFirstChild("AccentBar")  -- ✅ REMOVED
	local titleLabel = mainFrame:FindFirstChild("TitleLabel")
	if not titleLabel then return end

	-- Find title data
	local titleData = nil
	local titleColor = DESIGN.DefaultAccent

	for _, data in ipairs(TitleConfig.SummitTitles) do
		if data.Name == titleName then
			titleData = data
			break
		end
	end

	if not titleData and TitleConfig.SpecialTitles[titleName] then
		local specialData = TitleConfig.SpecialTitles[titleName]
		titleData = {
			Name = titleName,
			DisplayName = specialData.DisplayName,
			Color = specialData.Color,
			Icon = specialData.Icon
		}
	end

	if titleData then
		titleColor = titleData.Color
		-- if accentBar then accentBar.BackgroundColor3 = titleColor end  -- ✅ REMOVED
		titleLabel.Text = titleData.Icon .. " " .. titleData.DisplayName
		titleLabel.TextColor3 = titleColor
	else
		titleLabel.Text = "👤 Visitor"
		titleLabel.TextColor3 = DESIGN.TitleColor
		-- if accentBar then accentBar.BackgroundColor3 = DESIGN.DefaultAccent end  -- ✅ REMOVED
	end
end

local function updateSummit(targetPlayer, summits)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local summitsLabel = mainFrame and mainFrame:FindFirstChild("SummitsLabel")  -- ✅ Direct child now

	if summitsLabel then
		summitsLabel.Text = "⛰️ " .. tostring(summits)
	end
end

local function updateMoney(targetPlayer, money)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local moneyLabel = mainFrame and mainFrame:FindFirstChild("MoneyLabel")  -- ✅ Direct child now

	if moneyLabel then
		local formatted = tostring(money)
		if money >= 1000000 then
			formatted = string.format("%.1fM", money / 1000000)
		elseif money >= 1000 then
			formatted = string.format("%.1fK", money / 1000)
		end
		moneyLabel.Text = "💵 $" .. formatted
	end
end

-- ==================== PLAYER SETUP (SIMPLE) ====================

local function setupPlayer(targetPlayer)
	-- Watch for character
	local function onCharacterAdded(character)
		-- ✅ FIX: Add retry for billboard creation
		local billboard = nil
		local retries = 0
		
		while not billboard and retries < 5 do
			billboard = createBillboard(character, targetPlayer)
			if not billboard then
				retries = retries + 1
				task.wait(0.5)
			end
		end
		
		if not billboard then 
			warn("[TITLE] Failed to create billboard for", targetPlayer.Name)
			return 
		end

		-- ✅ SIMPLE: Client fetches title from server for THIS player only
		task.spawn(function()
			task.wait(2) -- Wait for server data to be ready
			if not targetPlayer or not targetPlayer.Parent then return end
			
			-- ✅ FIX: Retry title fetch with better error handling
			local success, title = nil, nil
			for attempt = 1, 3 do
				success, title = pcall(function()
					return getTitleFunc:InvokeServer(targetPlayer)
				end)
				
				if success and title then
					break
				end
				task.wait(1)
			end
			
			if success and title then
				updateTitle(targetPlayer, title)
			end
		end)

		-- Watch PlayerStats for summit
		local function watchPlayerStats()
			local playerStats = targetPlayer:FindFirstChild("PlayerStats")
			if playerStats then
				local summit = playerStats:FindFirstChild("Summit")
				if summit then
					updateSummit(targetPlayer, summit.Value)
					summit:GetPropertyChangedSignal("Value"):Connect(function()
						updateSummit(targetPlayer, summit.Value)
					end)
				end
			end
		end

		-- Try immediately, then try after delay if not ready
		watchPlayerStats()
		task.delay(3, watchPlayerStats)

		-- Watch Money
		local moneyValue = targetPlayer:FindFirstChild("Money")
		if moneyValue then
			updateMoney(targetPlayer, moneyValue.Value)
			moneyValue:GetPropertyChangedSignal("Value"):Connect(function()
				updateMoney(targetPlayer, moneyValue.Value)
			end)
		else
			local conn
			conn = targetPlayer.ChildAdded:Connect(function(child)
				if child.Name == "Money" and child:IsA("IntValue") then
					updateMoney(targetPlayer, child.Value)
					child:GetPropertyChangedSignal("Value"):Connect(function()
						updateMoney(targetPlayer, child.Value)
					end)
					conn:Disconnect()
				end
			end)
		end
	end

	targetPlayer.CharacterAdded:Connect(onCharacterAdded)
	if targetPlayer.Character then
		onCharacterAdded(targetPlayer.Character)
	end
end

local function onPlayerRemoving(targetPlayer)
	billboardCache[targetPlayer] = nil
	playerCountries[targetPlayer] = nil
end

-- ==================== TITLE CHANGE LISTENER (MINIMAL) ====================

-- ✅ ONLY listen for OWN title changes (from EquipTitle etc)
local updateTitleEvent = remoteFolder:FindFirstChild("UpdateTitle")
if updateTitleEvent then
	updateTitleEvent.OnClientEvent:Connect(function(titleName)
		updateTitle(player, titleName)
	end)
end

-- ✅ Listen for OTHER player title changes (SIMPLE - no loops)
local updateOtherEvent = remoteFolder:FindFirstChild("UpdateOtherPlayerTitle")
if updateOtherEvent then
	updateOtherEvent.OnClientEvent:Connect(function(targetPlayer, titleName)
		if targetPlayer and targetPlayer ~= player then
			updateTitle(targetPlayer, titleName)
		end
	end)
end

-- ==================== ✅ HIDE ROBLOX DEFAULT NAME (ALWAYS) ====================
-- This permanently hides the built-in Roblox name display above heads
-- Only TitleClient's custom billboard will be visible

local function hideRobloxDefaultName(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

-- Apply to character when added
local function setupHideDefaultName(targetPlayer)
	if targetPlayer.Character then
		hideRobloxDefaultName(targetPlayer.Character)
	end
	
	targetPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		hideRobloxDefaultName(character)
	end)
end

-- ==================== INITIALIZATION ====================

-- Setup existing players
for _, targetPlayer in ipairs(Players:GetPlayers()) do
	setupPlayer(targetPlayer)
	setupHideDefaultName(targetPlayer)  -- ✅ Hide Roblox default name
end

-- Setup new players
Players.PlayerAdded:Connect(function(targetPlayer)
	setupPlayer(targetPlayer)
	setupHideDefaultName(targetPlayer)  -- ✅ Hide Roblox default name
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ [TITLE CLIENT v4] Super simple - loaded (Roblox default names hidden)")