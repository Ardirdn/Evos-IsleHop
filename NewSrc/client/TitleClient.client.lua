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
	MoneyColor = Color3.fromRGB(0, 255, 13),
	SummitColor = Color3.fromRGB(255, 238, 0),
	DefaultAccent = Color3.fromRGB(80, 80, 90),
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
	billboard.Size = UDim2.new(8, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
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

	-- Title Label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
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

	-- Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
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

	-- Accent Bar
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0.8, 0, 0.03, 0)
	accentBar.Position = UDim2.new(0.5, 0, 0.77, 0)
	accentBar.AnchorPoint = Vector2.new(0.5, 0.5)
	accentBar.BackgroundColor3 = DESIGN.DefaultAccent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = mainFrame

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0.5, 0)
	accentCorner.Parent = accentBar

	-- Stats Row
	local statsRow = Instance.new("Frame")
	statsRow.Name = "StatsRow"
	statsRow.Size = UDim2.new(1, 0, 0.3, 0)
	statsRow.Position = UDim2.new(0, 0, 0.8, 0)
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = mainFrame

	-- Summit Label
	local summitsLabel = Instance.new("TextLabel")
	summitsLabel.Name = "SummitsLabel"
	summitsLabel.Size = UDim2.new(0.48, 0, 1, 0)
	summitsLabel.Position = UDim2.new(0, 0, 0, 0)
	summitsLabel.BackgroundTransparency = 1
	summitsLabel.Font = Enum.Font.GothamBlack
	summitsLabel.TextScaled = true
	summitsLabel.TextColor3 = DESIGN.SummitColor
	summitsLabel.TextXAlignment = Enum.TextXAlignment.Center
	summitsLabel.Text = "⛰️ 0"
	summitsLabel.Parent = statsRow

	local summitStroke = Instance.new("UIStroke")
	summitStroke.Color = Color3.fromRGB(0, 0, 0)
	summitStroke.Thickness = 1.5
	summitStroke.Transparency = 0.3
	summitStroke.Parent = summitsLabel

	-- Money Label
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(0.48, 0, 1, 0)
	moneyLabel.Position = UDim2.new(0.52, 0, 0, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBlack
	moneyLabel.TextScaled = true
	moneyLabel.TextColor3 = DESIGN.MoneyColor
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
	moneyLabel.Text = "💵 $0"
	moneyLabel.Parent = statsRow

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

	local accentBar = mainFrame:FindFirstChild("AccentBar")
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
		if accentBar then accentBar.BackgroundColor3 = titleColor end
		titleLabel.Text = titleData.Icon .. " " .. titleData.DisplayName
		titleLabel.TextColor3 = titleColor
	else
		titleLabel.Text = "👤 Visitor"
		titleLabel.TextColor3 = DESIGN.TitleColor
		if accentBar then accentBar.BackgroundColor3 = DESIGN.DefaultAccent end
	end
end

local function updateSummit(targetPlayer, summits)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local statsRow = mainFrame and mainFrame:FindFirstChild("StatsRow")
	local summitsLabel = statsRow and statsRow:FindFirstChild("SummitsLabel")

	if summitsLabel then
		summitsLabel.Text = "⛰️ " .. tostring(summits)
	end
end

local function updateMoney(targetPlayer, money)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local statsRow = mainFrame and mainFrame:FindFirstChild("StatsRow")
	local moneyLabel = statsRow and statsRow:FindFirstChild("MoneyLabel")

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
		local billboard = createBillboard(character, targetPlayer)
		if not billboard then return end

		-- ✅ SIMPLE: Client fetches title from server for THIS player only
		task.spawn(function()
			task.wait(2) -- Wait for server data to be ready
			if not targetPlayer or not targetPlayer.Parent then return end
			
			local success, title = pcall(function()
				return getTitleFunc:InvokeServer(targetPlayer)
			end)
			
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