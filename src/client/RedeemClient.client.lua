--[[
    REDEEM CLIENT (FULL - WITH AVAILABLE CODES TAB)
    Place in StarterPlayerScripts/RedeemClient
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local RedeemConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RedeemConfig"))
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("RedeemRemotes")
local createCodeEvent = remoteFolder:WaitForChild("CreateCode")
local redeemCodeEvent = remoteFolder:WaitForChild("RedeemCode")
local getRewardOptionsFunc = remoteFolder:WaitForChild("GetRewardOptions")
local checkAdminFunc = remoteFolder:WaitForChild("CheckAdmin")
local getAllCodesFunc = remoteFolder:WaitForChild("GetAllCodes")

local COLORS = RedeemConfig.Colors

-- State
local isAdmin = false
local currentMainTab = "Redeem Codes"
local currentRewardTab = "Title"
local selectedReward = nil
local rewardOptions = {}

-- ==================== HELPER FUNCTIONS ====================
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

-- ✅ Helper: Create adaptive text with TextScaled and UITextSizeConstraint
local function makeTextAdaptive(textLabel, maxTextSize)
	textLabel.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxTextSize or 14
	constraint.MinTextSize = 1
	constraint.Parent = textLabel
end

-- ✅ Helper: Add UIAspectRatioConstraint to main frames
local function addAspectRatio(frame, ratio)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = ratio or 0.8
	aspectRatio.DominantAxis = Enum.DominantAxis.Width
	aspectRatio.Parent = frame
end

-- ✅ Helper: tweenSize for animations
local function tweenSize(object, endSize, time, callback)
	local tween = TweenService:Create(object, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = endSize
	})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

-- ==================== CREATE GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RedeemGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Main Panel (✅ FULLY ADAPTIVE)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(1, 0, 0.8, 0)  -- ✅ Full scale, controlled by AspectRatio
mainPanel.Position = UDim2.new(0.5, 0, 1.5, 0)  -- ✅ Start off-screen for animation
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui

createCorner(15).Parent = mainPanel
createStroke(COLORS.Border, 2).Parent = mainPanel
addAspectRatio(mainPanel, 0.8)  -- ✅ AspectRatio 0.8 dengan DominantAxis = Width

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.1, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = mainPanel

createCorner(15).Parent = header

local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0.3, 0)  -- ✅ Scale-based
headerBottom.Position = UDim2.new(0, 0, 0.7, 0)  -- ✅ Scale-based
headerBottom.BackgroundColor3 = COLORS.Panel
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.7, 0, 1, 0)
headerTitle.Position = UDim2.new(0.03, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "REDEEM CODES"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header
makeTextAdaptive(headerTitle, 18)  -- ✅ Adaptive text

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.1, 0, 0.7, 0)  -- ✅ Scale-based
closeBtn.Position = UDim2.new(0.95, 0, 0.5, 0)  -- ✅ Scale-based
closeBtn.AnchorPoint = Vector2.new(1, 0.5)  -- ✅ Anchor to right
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = COLORS.Text
closeBtn.Parent = header
makeTextAdaptive(closeBtn, 20)  -- ✅ Adaptive text

createCorner(10).Parent = closeBtn

-- ✅ Main Tab Frame (3 TABS: Redeem / Create / Available)
local mainTabFrame = Instance.new("Frame")
mainTabFrame.Size = UDim2.new(0.94, 0, 0.07, 0)
mainTabFrame.Position = UDim2.new(0.03, 0, 0.12, 0)
mainTabFrame.BackgroundTransparency = 1
mainTabFrame.Parent = mainPanel

local mainTabLayout = Instance.new("UIListLayout")
mainTabLayout.FillDirection = Enum.FillDirection.Horizontal
mainTabLayout.Padding = UDim.new(0.015, 0)
mainTabLayout.Parent = mainTabFrame

local mainTabs = {}

-- Redeem Codes Tab (always visible)
local redeemTab = Instance.new("TextButton")
redeemTab.Size = UDim2.new(0.31, 0, 1, 0)  -- ✅ Scale-based
redeemTab.BackgroundColor3 = COLORS.Accent
redeemTab.BorderSizePixel = 0
redeemTab.Text = "Redeem Codes"
redeemTab.Font = Enum.Font.GothamBold
redeemTab.TextColor3 = COLORS.Text
redeemTab.AutoButtonColor = false
redeemTab.Parent = mainTabFrame

createCorner(8).Parent = redeemTab
makeTextAdaptive(redeemTab, 13)  -- ✅ Adaptive text

mainTabs["Redeem Codes"] = redeemTab

-- Create Redeem Code Tab (admin only)
local createTab = Instance.new("TextButton")
createTab.Size = UDim2.new(0.31, 0, 1, 0)  -- ✅ Scale-based
createTab.BackgroundColor3 = COLORS.Button
createTab.BorderSizePixel = 0
createTab.Text = "Create Code"
createTab.Font = Enum.Font.GothamBold
createTab.TextColor3 = COLORS.Text
createTab.AutoButtonColor = false
createTab.Visible = false
createTab.Parent = mainTabFrame

createCorner(8).Parent = createTab
makeTextAdaptive(createTab, 13)  -- ✅ Adaptive text

mainTabs["Create Redeem Code"] = createTab

-- ✅ AVAILABLE CODES TAB (Admin only)
local availableTab = Instance.new("TextButton")
availableTab.Size = UDim2.new(0.31, 0, 1, 0)  -- ✅ Scale-based
availableTab.BackgroundColor3 = COLORS.Button
availableTab.BorderSizePixel = 0
availableTab.Text = "Available Codes"
availableTab.Font = Enum.Font.GothamBold
availableTab.TextColor3 = COLORS.Text
availableTab.AutoButtonColor = false
availableTab.Visible = false
availableTab.Parent = mainTabFrame

createCorner(8).Parent = availableTab
makeTextAdaptive(availableTab, 13)  -- ✅ Adaptive text

mainTabs["Available Codes"] = availableTab

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(0.94, 0, 0.78, 0)
contentContainer.Position = UDim2.new(0.03, 0, 0.21, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainPanel

-- ==================== REDEEM CODES CONTENT ====================

local redeemContent = Instance.new("Frame")
redeemContent.Size = UDim2.new(1, 0, .8, 0)
redeemContent.BackgroundTransparency = 1
redeemContent.Visible = true
redeemContent.Parent = contentContainer

-- Code Input
local codeInputFrame = Instance.new("Frame")
codeInputFrame.Size = UDim2.new(1, 0, 0.1, 0)
codeInputFrame.Position = UDim2.new(0, 0, 0.3, 0)
codeInputFrame.BackgroundColor3 = COLORS.Panel
codeInputFrame.BorderSizePixel = 0
codeInputFrame.Parent = redeemContent

createCorner(10).Parent = codeInputFrame

local codeInputBox = Instance.new("TextBox")
codeInputBox.Size = UDim2.new(0.9, 0, 0.7, 0)  -- ✅ Scale-based
codeInputBox.Position = UDim2.new(0.05, 0, 0.15, 0)  -- ✅ Scale-based
codeInputBox.BackgroundTransparency = 1
codeInputBox.Font = Enum.Font.GothamBold
codeInputBox.PlaceholderText = "Enter code here..."
codeInputBox.Text = ""
codeInputBox.TextColor3 = COLORS.Text
codeInputBox.ClearTextOnFocus = false
codeInputBox.Parent = codeInputFrame
makeTextAdaptive(codeInputBox, 16)  -- ✅ Adaptive text

-- Redeem Button
local redeemButton = Instance.new("TextButton")
redeemButton.Size = UDim2.new(0.5, 0, 0.08, 0)  -- ✅ Scale-based
redeemButton.Position = UDim2.new(0.25, 0, 0.45, 0)  -- ✅ Scale-based
redeemButton.BackgroundColor3 = COLORS.Accent
redeemButton.BorderSizePixel = 0
redeemButton.Text = "REDEEM"
redeemButton.Font = Enum.Font.GothamBold
redeemButton.TextColor3 = COLORS.Text
redeemButton.Parent = redeemContent
makeTextAdaptive(redeemButton, 16)  -- ✅ Adaptive text

createCorner(10).Parent = redeemButton

-- ==================== CREATE REDEEM CODE CONTENT (ADMIN ONLY) ====================

local createContent = Instance.new("Frame")
createContent.Size = UDim2.new(1, 0, 1, 0)
createContent.BackgroundTransparency = 1
createContent.Visible = false
createContent.Parent = contentContainer

-- Reward Type Tabs
local rewardTabFrame = Instance.new("Frame")
rewardTabFrame.Size = UDim2.new(1, 0, 0.07, 0)
rewardTabFrame.BackgroundTransparency = 1
rewardTabFrame.Parent = createContent

local rewardTabLayout = Instance.new("UIListLayout")
rewardTabLayout.FillDirection = Enum.FillDirection.Horizontal
rewardTabLayout.Padding = UDim.new(0.01, 0)
rewardTabLayout.Parent = rewardTabFrame

local rewardTabs = {}

for i, rewardType in ipairs(RedeemConfig.AdminTabs) do
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0.188, 0, 1, 0)  -- ✅ Scale-based
	tab.BackgroundColor3 = (i == 1) and COLORS.Accent or COLORS.Button
	tab.BorderSizePixel = 0
	tab.Text = rewardType
	tab.Font = Enum.Font.GothamBold
	tab.TextColor3 = COLORS.Text
	tab.AutoButtonColor = false
	tab.Parent = rewardTabFrame

	createCorner(6).Parent = tab
	makeTextAdaptive(tab, 12)  -- ✅ Adaptive text

	rewardTabs[rewardType] = tab
end

-- Reward Scroll Frame
local rewardScrollFrame = Instance.new("ScrollingFrame")
rewardScrollFrame.Size = UDim2.new(1, 0, 0.5, 0)
rewardScrollFrame.Position = UDim2.new(0, 0, 0.09, 0)
rewardScrollFrame.BackgroundTransparency = 1
rewardScrollFrame.BorderSizePixel = 0
rewardScrollFrame.ScrollBarThickness = 4
rewardScrollFrame.ScrollBarImageColor3 = COLORS.Border
rewardScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
rewardScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
rewardScrollFrame.ClipsDescendants = true
rewardScrollFrame.Parent = createContent

local rewardScrollPadding = Instance.new("UIPadding")
rewardScrollPadding.PaddingLeft = UDim.new(0.03, 0)
rewardScrollPadding.PaddingRight = UDim.new(0.03, 0)
rewardScrollPadding.PaddingTop = UDim.new(0.02, 0)
rewardScrollPadding.PaddingBottom = UDim.new(0.05, 0)
rewardScrollPadding.Parent = rewardScrollFrame

local rewardGridLayout = Instance.new("UIGridLayout")
rewardGridLayout.CellSize = UDim2.new(0.29, 0, 0, 100)
rewardGridLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
rewardGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
rewardGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rewardGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
rewardGridLayout.Parent = rewardScrollFrame

-- ==================== CODE CREATION SECTION (SIDE-BY-SIDE, NO OVERFLOW) ====================

local codeCreationFrame = Instance.new("Frame")
codeCreationFrame.Size = UDim2.new(1, 0, 0.38, 0) -- ✅ 38% height
codeCreationFrame.Position = UDim2.new(0, 0, 0.61, 0) -- ✅ Start at 61% (50% scroll + 9% tabs + 2% gap)
codeCreationFrame.BackgroundColor3 = COLORS.Panel
codeCreationFrame.BorderSizePixel = 0
codeCreationFrame.ClipsDescendants = true -- ✅ CRITICAL: Prevent overflow
codeCreationFrame.Parent = createContent

createCorner(10).Parent = codeCreationFrame

local codeCreationPadding = Instance.new("UIPadding")
codeCreationPadding.PaddingTop = UDim.new(0.05, 0)  -- ✅ Scale-based
codeCreationPadding.PaddingLeft = UDim.new(0.03, 0)  -- ✅ Scale-based
codeCreationPadding.PaddingRight = UDim.new(0.03, 0)  -- ✅ Scale-based
codeCreationPadding.PaddingBottom = UDim.new(0.05, 0)  -- ✅ Scale-based
codeCreationPadding.Parent = codeCreationFrame

-- ✅ LEFT SIDE - CODE INPUT
local codeInputContainer = Instance.new("Frame")
codeInputContainer.Size = UDim2.new(0.48, 0, 0.45, 0)  -- ✅ Scale-based
codeInputContainer.Position = UDim2.new(0, 0, 0, 0)  -- ✅ Scale-based
codeInputContainer.BackgroundTransparency = 1
codeInputContainer.Parent = codeCreationFrame

local codeInputLabel = Instance.new("TextLabel")
codeInputLabel.Size = UDim2.new(1, 0, 0.3, 0)  -- ✅ Scale-based
codeInputLabel.BackgroundTransparency = 1
codeInputLabel.Font = Enum.Font.GothamBold
codeInputLabel.Text = "Code:"
codeInputLabel.TextColor3 = COLORS.Text
codeInputLabel.TextXAlignment = Enum.TextXAlignment.Left
codeInputLabel.Parent = codeInputContainer
makeTextAdaptive(codeInputLabel, 12)  -- ✅ Adaptive text

local createCodeInput = Instance.new("TextBox")
createCodeInput.Size = UDim2.new(1, 0, 0.65, 0)  -- ✅ Scale-based
createCodeInput.Position = UDim2.new(0, 0, 0.35, 0)  -- ✅ Scale-based
createCodeInput.BackgroundColor3 = COLORS.Button
createCodeInput.BorderSizePixel = 0
createCodeInput.Font = Enum.Font.Gotham
createCodeInput.PlaceholderText = "e.g., SUMMER2025"
createCodeInput.Text = ""
createCodeInput.TextColor3 = COLORS.Text
createCodeInput.ClearTextOnFocus = false
createCodeInput.Parent = codeInputContainer
makeTextAdaptive(createCodeInput, 12)  -- ✅ Adaptive text

createCorner(8).Parent = createCodeInput

-- ✅ RIGHT SIDE - MAX USES INPUT
local maxUsesContainer = Instance.new("Frame")
maxUsesContainer.Size = UDim2.new(0.48, 0, 0.45, 0)  -- ✅ Scale-based
maxUsesContainer.Position = UDim2.new(0.52, 0, 0, 0)  -- ✅ Scale-based
maxUsesContainer.BackgroundTransparency = 1
maxUsesContainer.Parent = codeCreationFrame

local maxUsesLabel = Instance.new("TextLabel")
maxUsesLabel.Size = UDim2.new(1, 0, 0.3, 0)  -- ✅ Scale-based
maxUsesLabel.BackgroundTransparency = 1
maxUsesLabel.Font = Enum.Font.GothamBold
maxUsesLabel.Text = "Max Uses:"
maxUsesLabel.TextColor3 = COLORS.Text
maxUsesLabel.TextXAlignment = Enum.TextXAlignment.Left
maxUsesLabel.Parent = maxUsesContainer
makeTextAdaptive(maxUsesLabel, 12)  -- ✅ Adaptive text

local maxUsesInput = Instance.new("TextBox")
maxUsesInput.Size = UDim2.new(1, 0, 0.65, 0)  -- ✅ Scale-based
maxUsesInput.Position = UDim2.new(0, 0, 0.35, 0)  -- ✅ Scale-based
maxUsesInput.BackgroundColor3 = COLORS.Button
maxUsesInput.BorderSizePixel = 0
maxUsesInput.Font = Enum.Font.Gotham
maxUsesInput.PlaceholderText = "e.g., 100"
maxUsesInput.Text = ""
maxUsesInput.TextColor3 = COLORS.Text
maxUsesInput.ClearTextOnFocus = false
maxUsesInput.Parent = maxUsesContainer
makeTextAdaptive(maxUsesInput, 12)  -- ✅ Adaptive text

createCorner(8).Parent = maxUsesInput

-- ✅ FULL-WIDTH CREATE BUTTON BELOW
local createCodeButton = Instance.new("TextButton")
createCodeButton.Size = UDim2.new(1, 0, 0.35, 0)  -- ✅ Scale-based
createCodeButton.Position = UDim2.new(0, 0, 0.55, 0)  -- ✅ Scale-based
createCodeButton.BackgroundColor3 = COLORS.Success
createCodeButton.BorderSizePixel = 0
createCodeButton.Text = "CREATE CODE"
createCodeButton.Font = Enum.Font.GothamBold
createCodeButton.TextColor3 = COLORS.Text
createCodeButton.Parent = codeCreationFrame
makeTextAdaptive(createCodeButton, 15)  -- ✅ Adaptive text

createCorner(10).Parent = createCodeButton




-- ==================== AVAILABLE CODES CONTENT (ADMIN ONLY) ====================

local availableContent = Instance.new("Frame")
availableContent.Size = UDim2.new(1, 0, 1, 0)
availableContent.BackgroundTransparency = 1
availableContent.Visible = false
availableContent.Parent = contentContainer

local availableScrollFrame = Instance.new("ScrollingFrame")
availableScrollFrame.Size = UDim2.new(1, 0, 0.85, 0)
availableScrollFrame.BackgroundTransparency = 1
availableScrollFrame.BorderSizePixel = 0
availableScrollFrame.ScrollBarThickness = 4
availableScrollFrame.ScrollBarImageColor3 = COLORS.Border
availableScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
availableScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
availableScrollFrame.ClipsDescendants = true
availableScrollFrame.Parent = availableContent

local availableLayout = Instance.new("UIListLayout")
availableLayout.Padding = UDim.new(0.02, 0)  -- ✅ Scale-based padding
availableLayout.SortOrder = Enum.SortOrder.LayoutOrder
availableLayout.Parent = availableScrollFrame

local function refreshAvailableCodes()
	-- Clear existing
	for _, child in ipairs(availableScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get from server
	task.spawn(function()
		local success, codes = pcall(function()
			return getAllCodesFunc:InvokeServer()
		end)

		if success and codes then
			for _, codeData in ipairs(codes) do
				local codeCard = Instance.new("Frame")
				codeCard.Size = UDim2.new(1, 0, 0.15, 0)  -- ✅ Scale-based
				codeCard.BackgroundColor3 = COLORS.Panel
				codeCard.BorderSizePixel = 0
				codeCard.Parent = availableScrollFrame

				createCorner(10).Parent = codeCard

				-- Code Label
				local codeLabel = Instance.new("TextLabel")
				codeLabel.Size = UDim2.new(0.6, 0, 0.4, 0)  -- ✅ Scale-based
				codeLabel.Position = UDim2.new(0.05, 0, 0.1, 0)  -- ✅ Scale-based
				codeLabel.BackgroundTransparency = 1
				codeLabel.Font = Enum.Font.GothamBold
				codeLabel.Text = codeData.Code
				codeLabel.TextColor3 = COLORS.Accent
				codeLabel.TextXAlignment = Enum.TextXAlignment.Left
				codeLabel.Parent = codeCard
				makeTextAdaptive(codeLabel, 14)  -- ✅ Adaptive text

				-- Type & Reward
				local rewardLabel = Instance.new("TextLabel")
				rewardLabel.Size = UDim2.new(0.9, 0, 0.3, 0)  -- ✅ Scale-based
				rewardLabel.Position = UDim2.new(0.05, 0, 0.5, 0)  -- ✅ Scale-based
				rewardLabel.BackgroundTransparency = 1
				rewardLabel.Font = Enum.Font.Gotham
				rewardLabel.Text = string.format("%s: %s", codeData.Type, tostring(codeData.Reward))
				rewardLabel.TextColor3 = COLORS.TextSecondary
				rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
				rewardLabel.Parent = codeCard
				makeTextAdaptive(rewardLabel, 12)  -- ✅ Adaptive text

				-- Remaining Uses
				local remainingLabel = Instance.new("TextLabel")
				remainingLabel.Size = UDim2.new(0.3, 0, 0.4, 0)  -- ✅ Scale-based
				remainingLabel.Position = UDim2.new(0.65, 0, 0.1, 0)  -- ✅ Scale-based
				remainingLabel.BackgroundTransparency = 1
				remainingLabel.Font = Enum.Font.GothamBold
				remainingLabel.Text = string.format("%d/%d", codeData.Remaining, codeData.MaxUses)
				remainingLabel.TextColor3 = codeData.Remaining > 0 and COLORS.Success or COLORS.Danger
				remainingLabel.TextXAlignment = Enum.TextXAlignment.Right
				remainingLabel.Parent = codeCard
				makeTextAdaptive(remainingLabel, 16)  -- ✅ Adaptive text
			end
		else
			warn("⚠️ Failed to get available codes")
		end
	end)
end

-- Refresh Button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.5, 0, 0.08, 0)  -- ✅ Scale-based
refreshBtn.Position = UDim2.new(0.25, 0, 0.9, 0)  -- ✅ Scale-based
refreshBtn.BackgroundColor3 = COLORS.Accent
refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "REFRESH"
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextColor3 = COLORS.Text
refreshBtn.Parent = availableContent
makeTextAdaptive(refreshBtn, 14)  -- ✅ Adaptive text

createCorner(10).Parent = refreshBtn

refreshBtn.MouseButton1Click:Connect(function()
	refreshAvailableCodes()
end)

-- ==================== FUNCTIONS ====================

local function checkAdmin()
	task.spawn(function()
		task.wait(2)

		local success, result = pcall(function()
			return checkAdminFunc:InvokeServer()
		end)

		if success and result then
			isAdmin = true
			createTab.Visible = true
			availableTab.Visible = true -- ✅ SHOW AVAILABLE TAB
			print("✅ [REDEEM CLIENT] Admin access granted")
		else
			isAdmin = false
			createTab.Visible = false
			availableTab.Visible = false
			print("⚠️ [REDEEM CLIENT] Not an admin")
		end
	end)
end

local function createRewardCard(rewardData, rewardType)
	local card = Instance.new("Frame")
	card.Name = rewardData.Id
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.Parent = rewardScrollFrame

	createCorner(8).Parent = card
	createStroke(COLORS.Border, 1).Parent = card

	-- ✅ SEMUA TIPE: HANYA TEXT
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.8, 0)  -- ✅ Scale-based
	nameLabel.Position = UDim2.new(0.05, 0, 0.1, 0)  -- ✅ Scale-based
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = rewardData.Name
	nameLabel.TextColor3 = rewardData.Color or COLORS.Text
	nameLabel.TextWrapped = true
	nameLabel.Parent = card
	makeTextAdaptive(nameLabel, 12)  -- ✅ Adaptive text

	-- Click handler
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = card

	clickBtn.MouseButton1Click:Connect(function()
		-- Deselect all
		for _, child in ipairs(rewardScrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = COLORS.Border
					stroke.Thickness = 1
				end
				child.BackgroundColor3 = COLORS.Panel
			end
		end

		-- Select this one
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = COLORS.Accent
			stroke.Thickness = 2
		end
		card.BackgroundColor3 = COLORS.Selected

		-- Store selection
		if rewardType == "Money" or rewardType == "Summit" then
			selectedReward = {
				Type = rewardType,
				Value = rewardData.Value
			}
		else
			selectedReward = {
				Type = rewardType,
				Value = rewardData.Id
			}
		end

		print(string.format("✅ [REDEEM CLIENT] Selected: %s (%s)", rewardData.Name, rewardType))
	end)

	return card
end

local function updateRewardDisplay(rewardType)
	print(string.format("🔍 [REDEEM CLIENT] updateRewardDisplay called: %s", rewardType)) -- ✅ DEBUG

	-- Clear existing
	for _, child in ipairs(rewardScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Reset selection
	selectedReward = nil

	-- Get options from server
	task.spawn(function()
		print(string.format("🔍 [REDEEM CLIENT] Requesting %s from server...", rewardType)) -- ✅ DEBUG

		local success, options = pcall(function()
			return getRewardOptionsFunc:InvokeServer(rewardType)
		end)

		if success and options then
			print(string.format("✅ [REDEEM CLIENT] Received %d %s options", #options, rewardType)) -- ✅ DEBUG
			rewardOptions = options

			for _, option in ipairs(options) do
				createRewardCard(option, rewardType)
			end
		else
			warn(string.format("⚠️ [REDEEM CLIENT] Failed to load %s options: %s", rewardType, tostring(options)))
		end
	end)
end


local function showPanel()
	screenGui.Enabled = true
	mainPanel.Visible = true
	mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)  -- ✅ Center position
	mainPanel.Size = UDim2.new(0, 0, 0, 0)  -- ✅ Start small for tweenSize

	task.wait()

	-- ✅ Use tweenSize for smooth animation
	tweenSize(mainPanel, UDim2.new(1, 0, 0.8, 0), RedeemConfig.AnimationDuration)
end

local function hidePanel()
	-- ✅ Use tweenSize for smooth animation
	tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), RedeemConfig.AnimationDuration, function()
		mainPanel.Visible = false
		screenGui.Enabled = false
		mainPanel.Size = UDim2.new(1, 0, 0.8, 0)  -- ✅ Reset size for next show
	end)
end

-- ==================== EVENT CONNECTIONS ====================

closeBtn.MouseButton1Click:Connect(function()
	hidePanel()
end)

-- Main Tab Switching
for tabName, tab in pairs(mainTabs) do
	tab.MouseButton1Click:Connect(function()
		currentMainTab = tabName

		-- Update tab colors
		for name, t in pairs(mainTabs) do
			t.BackgroundColor3 = (name == tabName) and COLORS.Accent or COLORS.Button
		end

		-- Show/hide content
		if tabName == "Redeem Codes" then
			redeemContent.Visible = true
			createContent.Visible = false
			availableContent.Visible = false
		elseif tabName == "Create Redeem Code" then
			redeemContent.Visible = false
			createContent.Visible = true
			availableContent.Visible = false
			updateRewardDisplay(currentRewardTab)
		elseif tabName == "Available Codes" then
			redeemContent.Visible = false
			createContent.Visible = false
			availableContent.Visible = true
			refreshAvailableCodes() -- ✅ Auto refresh
		end
	end)
end

-- Reward Tab Switching (line ~650)
for rewardType, tab in pairs(rewardTabs) do
	tab.MouseButton1Click:Connect(function()
		currentRewardTab = rewardType

		print(string.format("🔍 [REDEEM CLIENT] Switching to tab: %s", rewardType)) -- ✅ DEBUG

		-- Update tab colors
		for type, t in pairs(rewardTabs) do
			t.BackgroundColor3 = (type == rewardType) and COLORS.Accent or COLORS.Button
		end

		-- Update display
		updateRewardDisplay(rewardType)
	end)
end


-- Redeem Code Button
redeemButton.MouseButton1Click:Connect(function()
	local code = codeInputBox.Text

	if code == "" then
		return
	end

	-- Disable button temporarily
	redeemButton.Text = "REDEEMING..."
	redeemButton.BackgroundColor3 = COLORS.Button

	redeemCodeEvent:FireServer(code)

	task.wait(0.5)

	-- Reset button
	redeemButton.Text = "REDEEM"
	redeemButton.BackgroundColor3 = COLORS.Accent
	codeInputBox.Text = ""
end)

-- Create Code Button
createCodeButton.MouseButton1Click:Connect(function()
	if not isAdmin then
		return
	end

	local code = createCodeInput.Text
	local maxUses = tonumber(maxUsesInput.Text)

	if not code or code == "" then
		return
	end

	if not maxUses or maxUses < 1 then
		maxUses = 1
	end

	if not selectedReward then
		warn("⚠️ [REDEEM CLIENT] Please select a reward first")
		return
	end

	-- Disable button temporarily
	createCodeButton.Text = "CREATING..."
	createCodeButton.BackgroundColor3 = COLORS.Button

	createCodeEvent:FireServer(
		code,
		selectedReward.Type,
		selectedReward.Value,
		maxUses
	)

	task.wait(0.5)

	-- Reset button & inputs
	createCodeButton.Text = "CREATE CODE"
	createCodeButton.BackgroundColor3 = COLORS.Success
	createCodeInput.Text = ""
	maxUsesInput.Text = ""

	-- Deselect reward
	for _, child in ipairs(rewardScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = COLORS.Border
				stroke.Thickness = 1
			end
			child.BackgroundColor3 = COLORS.Panel
		end
	end

	selectedReward = nil
end)

-- ==================== TOPBAR ICON ====================
local redeemIcon = Icon.new()
	:setImage("rbxassetid://11419703997")
	:setLabel("Redeem")
	:bindEvent("selected", function()
		showPanel()
	end)
	:bindEvent("deselected", function()
		hidePanel()
	end)

-- ==================== INITIALIZATION ====================
checkAdmin()

print("✅ [REDEEM CLIENT] System loaded")
