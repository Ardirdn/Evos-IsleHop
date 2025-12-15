--[[
    TITLE CLIENT (Clean Minimal Design)
    Place in StarterPlayerScripts/TitleClient
    
    Features:
    - Only main frame has background
    - Inner elements are transparent
    - Accent bar on LEFT side
    - Name: left-aligned, Title: right-aligned
    - Summit/Money: left-aligned
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("TitleRemotes")
local updateTitleEvent = remoteFolder:WaitForChild("UpdateTitle")
local updateOtherPlayerTitleEvent = remoteFolder:WaitForChild("UpdateOtherPlayerTitle")
local getTitleFunc = remoteFolder:WaitForChild("GetTitle")

-- Cache
local playerTitles = {}
local playerCountries = {}
local billboardCache = {}

-- Config
local CONFIG = {
	MAX_DISTANCE = 50,
	FADE_START = 40,
}

-- Design
local DESIGN = {
	BackgroundColor = Color3.fromRGB(18, 18, 22),
	BackgroundTransparency = 0.15,
	TextColor = Color3.fromRGB(255, 255, 255),
	SubTextColor = Color3.fromRGB(160, 160, 165),
	MoneyColor = Color3.fromRGB(67, 181, 129),
	SummitColor = Color3.fromRGB(255, 193, 7),
	DefaultAccent = Color3.fromRGB(80, 80, 90),
}

-- Create billboard
local function createUnifiedBillboard(character, targetPlayer)
	local head = character:WaitForChild("Head", 5)
	if not head then return nil end

	local existing = head:FindFirstChild("PlayerInfoBillboard")
	if existing then existing:Destroy() end

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerInfoBillboard"
	billboard.Size = UDim2.new(0, 220, 0, 55)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = CONFIG.MAX_DISTANCE
	billboard.LightInfluence = 0
	billboard.Parent = head

	-- Main Frame (only this has background)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = DESIGN.BackgroundColor
	mainFrame.BackgroundTransparency = DESIGN.BackgroundTransparency
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = billboard

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = mainFrame

	-- Accent Bar (LEFT side)
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 4, 1, -10)
	accentBar.Position = UDim2.new(0, 5, 0, 5)
	accentBar.BackgroundColor3 = DESIGN.DefaultAccent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = mainFrame

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accentBar

	-- Content area (after accent bar)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -22, 1, -10)
	content.Position = UDim2.new(0, 14, 0, 5)
	content.BackgroundTransparency = 1
	content.Parent = mainFrame

	-- ========== ROW 1: Name (left) + Title (right) ==========
	local row1 = Instance.new("Frame")
	row1.Name = "Row1"
	row1.Size = UDim2.new(1, 0, 0, 20)
	row1.Position = UDim2.new(0, 0, 0, 0)
	row1.BackgroundTransparency = 1
	row1.Parent = content

	-- Name Label (left-aligned, auto-scale)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = false
	nameLabel.TextColor3 = DESIGN.TextColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = character.Name
	nameLabel.Parent = row1

	-- Text size constraint for name (min/max)
	local nameSizeConstraint = Instance.new("UITextSizeConstraint")
	nameSizeConstraint.MinTextSize = 10
	nameSizeConstraint.MaxTextSize = 14
	nameSizeConstraint.Parent = nameLabel

	-- Title Label (right-aligned, auto-scale)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0.45, 0, 1, 0)
	titleLabel.Position = UDim2.new(0.55, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = false
	titleLabel.TextColor3 = DESIGN.SubTextColor
	titleLabel.TextXAlignment = Enum.TextXAlignment.Right
	titleLabel.Text = "—"
	titleLabel.Parent = row1

	-- Text size constraint for title (min/max)
	local titleSizeConstraint = Instance.new("UITextSizeConstraint")
	titleSizeConstraint.MinTextSize = 8
	titleSizeConstraint.MaxTextSize = 12
	titleSizeConstraint.Parent = titleLabel


	-- ========== ROW 2: Summit + Money + Flag ==========
	local row2 = Instance.new("Frame")
	row2.Name = "Row2"
	row2.Size = UDim2.new(1, 0, 0, 18)
	row2.Position = UDim2.new(0, 0, 0, 24)
	row2.BackgroundTransparency = 1
	row2.Parent = content

	-- Summit Label (left-aligned)
	local summitsLabel = Instance.new("TextLabel")
	summitsLabel.Name = "SummitsLabel"
	summitsLabel.Size = UDim2.new(0.28, 0, 1, 0)
	summitsLabel.Position = UDim2.new(0, 0, 0, 0)
	summitsLabel.BackgroundTransparency = 1
	summitsLabel.Font = Enum.Font.GothamBold
	summitsLabel.TextSize = 11
	summitsLabel.TextColor3 = DESIGN.SummitColor
	summitsLabel.TextXAlignment = Enum.TextXAlignment.Left
	summitsLabel.Text = "⛰️ 0"
	summitsLabel.Parent = row2

	-- Money Label (left-aligned)
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(0.42, 0, 1, 0)
	moneyLabel.Position = UDim2.new(0.28, 0, 0, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextSize = 11
	moneyLabel.TextColor3 = DESIGN.MoneyColor
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = "💵 $0"
	moneyLabel.Parent = row2

	-- Flag Label (right)
	local flagLabel = Instance.new("TextLabel")
	flagLabel.Name = "FlagLabel"
	flagLabel.Size = UDim2.new(0.3, 0, 1, 0)
	flagLabel.Position = UDim2.new(0.7, 0, 0, 0)
	flagLabel.BackgroundTransparency = 1
	flagLabel.Font = Enum.Font.SourceSans
	flagLabel.TextSize = 14
	flagLabel.TextXAlignment = Enum.TextXAlignment.Right
	flagLabel.Text = "🌍"
	flagLabel.Parent = row2

	billboardCache[targetPlayer] = billboard
	return billboard
end

-- Update title with accent color
local function updateTitleDisplay(targetPlayer, titleName)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local accentBar = mainFrame:FindFirstChild("AccentBar")
	local content = mainFrame:FindFirstChild("Content")
	local row1 = content:FindFirstChild("Row1")
	local titleLabel = row1:FindFirstChild("TitleLabel")

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
		if accentBar then
			accentBar.BackgroundColor3 = titleColor
		end

		if titleName == "Pengunjung" then
			titleLabel.Text = "👤 Visitor"
			titleLabel.TextColor3 = DESIGN.SubTextColor
		else
			titleLabel.Text = titleData.Icon .. " " .. titleData.DisplayName
			titleLabel.TextColor3 = titleColor
		end
	else
		titleLabel.Text = "—"
		titleLabel.TextColor3 = DESIGN.SubTextColor
		if accentBar then
			accentBar.BackgroundColor3 = DESIGN.DefaultAccent
		end
	end
end

-- Update summit
local function updateSummitDisplay(targetPlayer, summits)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local content = mainFrame:FindFirstChild("Content")
	local row2 = content:FindFirstChild("Row2")
	local summitsLabel = row2:FindFirstChild("SummitsLabel")

	if summitsLabel then
		local formatted = tostring(summits)
		if summits >= 1000000 then
			formatted = string.format("%.1fM", summits / 1000000)
		elseif summits >= 1000 then
			formatted = string.format("%.1fK", summits / 1000)
		end
		summitsLabel.Text = "⛰️ " .. formatted
	end
end

-- Update money
local function updateMoneyDisplay(targetPlayer, money)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local content = mainFrame:FindFirstChild("Content")
	local row2 = content:FindFirstChild("Row2")
	local moneyLabel = row2:FindFirstChild("MoneyLabel")

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

-- Update flag
local function updateFlagDisplay(targetPlayer, flag)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local content = mainFrame:FindFirstChild("Content")
	local row2 = content:FindFirstChild("Row2")
	local flagLabel = row2:FindFirstChild("FlagLabel")

	if flagLabel then
		flagLabel.Text = flag
	end
end

-- Get country
local function getPlayerCountry(targetPlayer)
	if playerCountries[targetPlayer] then
		return playerCountries[targetPlayer]
	end

	task.spawn(function()
		local success, result = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(targetPlayer)
		end)

		if success and result then
			local flagEmojis = {
				US = "🇺🇸", ID = "🇮🇩", GB = "🇬🇧", JP = "🇯🇵",
				CN = "🇨🇳", KR = "🇰🇷", FR = "🇫🇷", DE = "🇩🇪",
				BR = "🇧🇷", IN = "🇮🇳", AU = "🇦🇺", CA = "🇨🇦",
				MY = "🇲🇾", SG = "🇸🇬", TH = "🇹🇭", VN = "🇻🇳",
				PH = "🇵🇭", MX = "🇲🇽", ES = "🇪🇸", IT = "🇮🇹",
				RU = "🇷🇺", NL = "🇳🇱", PL = "🇵🇱", SE = "🇸🇪",
			}
			local flag = flagEmojis[result] or "🌍"
			playerCountries[targetPlayer] = flag
			updateFlagDisplay(targetPlayer, flag)
		else
			playerCountries[targetPlayer] = "🌍"
		end
	end)

	return "🌍"
end

-- Setup player
local function setupPlayerBillboard(targetPlayer)
	local function onCharacterAdded(character)
		local billboard = createUnifiedBillboard(character, targetPlayer)
		if not billboard then return end

		local flag = getPlayerCountry(targetPlayer)
		updateFlagDisplay(targetPlayer, flag)

		local playerStats = targetPlayer:WaitForChild("PlayerStats", 5)
		if playerStats then
			local summitValue = playerStats:FindFirstChild("Summit")
			if summitValue then
				updateSummitDisplay(targetPlayer, summitValue.Value)
				summitValue:GetPropertyChangedSignal("Value"):Connect(function()
					updateSummitDisplay(targetPlayer, summitValue.Value)
				end)
			end
		end

		local moneyValue = targetPlayer:FindFirstChild("Money")
		if moneyValue then
			updateMoneyDisplay(targetPlayer, moneyValue.Value)
			moneyValue:GetPropertyChangedSignal("Value"):Connect(function()
				updateMoneyDisplay(targetPlayer, moneyValue.Value)
			end)
		else
			targetPlayer.ChildAdded:Connect(function(child)
				if child.Name == "Money" and child:IsA("IntValue") then
					updateMoneyDisplay(targetPlayer, child.Value)
					child:GetPropertyChangedSignal("Value"):Connect(function()
						updateMoneyDisplay(targetPlayer, child.Value)
					end)
				end
			end)
		end

		task.spawn(function()
			task.wait(1.5)
			local success, title = pcall(function()
				return getTitleFunc:InvokeServer(targetPlayer)
			end)
			if success and title then
				playerTitles[targetPlayer] = title
				updateTitleDisplay(targetPlayer, title)
			end
		end)
	end

	targetPlayer.CharacterAdded:Connect(onCharacterAdded)
	if targetPlayer.Character then
		onCharacterAdded(targetPlayer.Character)
	end
end

local function onPlayerRemoving(targetPlayer)
	billboardCache[targetPlayer] = nil
	playerTitles[targetPlayer] = nil
	playerCountries[targetPlayer] = nil
end

updateTitleEvent.OnClientEvent:Connect(function(titleName)
	playerTitles[player] = titleName
	if titleName then
		updateTitleDisplay(player, titleName)
	end
end)

updateOtherPlayerTitleEvent.OnClientEvent:Connect(function(targetPlayer, titleName)
	if targetPlayer and targetPlayer ~= player then
		playerTitles[targetPlayer] = titleName
		updateTitleDisplay(targetPlayer, titleName)
	end
end)

RunService.RenderStepped:Connect(function()
	local cameraPos = camera.CFrame.Position
	for targetPlayer, billboard in pairs(billboardCache) do
		if billboard and billboard.Parent then
			local head = billboard.Parent
			if head and head:IsA("BasePart") then
				local distance = (head.Position - cameraPos).Magnitude
				local mainFrame = billboard:FindFirstChild("MainFrame")
				if mainFrame then
					if distance >= CONFIG.FADE_START then
						local fadeRange = CONFIG.MAX_DISTANCE - CONFIG.FADE_START
						local fadeProgress = math.clamp((distance - CONFIG.FADE_START) / fadeRange, 0, 1)
						mainFrame.BackgroundTransparency = DESIGN.BackgroundTransparency + (fadeProgress * (1 - DESIGN.BackgroundTransparency))
					else
						mainFrame.BackgroundTransparency = DESIGN.BackgroundTransparency
					end
				end
			end
		end
	end
end)

for _, targetPlayer in ipairs(Players:GetPlayers()) do
	setupPlayerBillboard(targetPlayer)
end

Players.PlayerAdded:Connect(setupPlayerBillboard)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ [TITLE CLIENT] Minimal billboard loaded")