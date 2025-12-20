local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local InventoryConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryConfig"))
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 10)
if not inventoryRemotes then
	warn("[INVENTORY CLIENT v3] InventoryRemotes not found!")
	return
end

local getInventoryFunc = inventoryRemotes:WaitForChild("GetInventory", 10)

-- Tunggu remote events dengan timeout
local equipAuraEvent = inventoryRemotes:WaitForChild("EquipAura", 10)
local unequipAuraEvent = inventoryRemotes:WaitForChild("UnequipAura", 10)
local equipToolEvent = inventoryRemotes:WaitForChild("EquipTool", 10)
local unequipToolEvent = inventoryRemotes:WaitForChild("UnequipTool", 10)

if not equipAuraEvent then
	warn("[INVENTORY CLIENT v3] EquipAura not found after waiting - Aura equip disabled")
end
if not equipToolEvent then
	warn("[INVENTORY CLIENT v3] EquipTool not found after waiting - Tool equip disabled")
end

local titleRemotes = ReplicatedStorage:WaitForChild("TitleRemotes", 10)
if not titleRemotes then
	warn("[INVENTORY CLIENT v3] TitleRemotes not found!")
	return
end

local getUnlockedTitlesFunc = titleRemotes:WaitForChild("GetUnlockedTitles", 5)
local equipTitleEvent = titleRemotes:WaitForChild("EquipTitle", 5)
local unequipTitleEvent = titleRemotes:WaitForChild("UnequipTitle", 5)

local currentCategory = "All"
local currentTitleFilter = "All"
local inventoryData = {
	OwnedAuras = {},
	OwnedTools = {},
	EquippedAura = nil,
	EquippedTool = nil
}

local titleData = {
	UnlockedTitles = {},
	EquippedTitle = nil
}

local COLORS = InventoryConfig.Colors

local summitTitleCache = {}
for _, titleData in ipairs(TitleConfig.SummitTitles) do
	summitTitleCache[titleData.Name] = titleData
end

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

local function makeTextAdaptive(textLabel, maxTextSize)
	textLabel.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxTextSize or 14
	constraint.Parent = textLabel
end

local function addAspectRatio(frame, ratio)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = ratio or 0.8
	aspectRatio.DominantAxis = Enum.DominantAxis.Width
	aspectRatio.Parent = frame
end

local function tweenSize(object, endSize, time, callback)
	local TweenInfo = TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(object, TweenInfo, {Size = endSize})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGUI_V3"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0.7, 0, 0.9, 0)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui

createCorner(15).Parent = mainPanel
createStroke(COLORS.Border, 2).Parent = mainPanel
addAspectRatio(mainPanel, 1.3)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.1, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = mainPanel

createCorner(15).Parent = header

local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
headerBottom.BackgroundColor3 = COLORS.Panel
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.5, 0, 1, 0)
headerTitle.Position = UDim2.new(0.03, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "INVENTORY"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header
makeTextAdaptive(headerTitle, 20)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.08, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.95, 0, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = COLORS.Text
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
makeTextAdaptive(closeBtn, 20)

createCorner(10).Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	closeBtn.BackgroundColor3 = COLORS.Danger
end)

closeBtn.MouseLeave:Connect(function()
	closeBtn.BackgroundColor3 = COLORS.Button
end)

closeBtn.MouseButton1Click:Connect(function()
	tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		mainPanel.Visible = false
		mainPanel.Size = UDim2.new(0.7, 0, 0.9, 0)
	end)
end)

local dragging = false
local dragStart = nil
local startPos = nil

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainPanel.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local viewportSize = workspace.CurrentCamera.ViewportSize
		mainPanel.Position = UDim2.new(
			startPos.X.Scale + (delta.X / viewportSize.X),
			startPos.X.Offset,
			startPos.Y.Scale + (delta.Y / viewportSize.Y),
			startPos.Y.Offset
		)
	end
end)

local categoryFrame = Instance.new("Frame")
categoryFrame.Size = UDim2.new(0.94, 0, 0.08, 0)
categoryFrame.Position = UDim2.new(0.03, 0, 0.12, 0)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = mainPanel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0.015, 0)
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Parent = categoryFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(0.94, 0, 0.76, 0)
contentFrame.Position = UDim2.new(0.03, 0, 0.22, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainPanel

local categoryTabs = {}

local function createCategoryTab(categoryName, order)
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0.22, 0, 1, 0)
	tab.BackgroundColor3 = categoryName == "All" and COLORS.Accent or COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.Text = categoryName
	tab.TextColor3 = COLORS.Text
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = categoryFrame

	createCorner(8).Parent = tab
	makeTextAdaptive(tab, 14)

	local content = Instance.new("Frame")
	content.Name = categoryName .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Visible = categoryName == "All"
	content.Parent = contentFrame

	categoryTabs[categoryName] = {Button = tab, Content = content}

	tab.MouseButton1Click:Connect(function()
		for _, tabData in pairs(categoryTabs) do
			tabData.Content.Visible = false
			tabData.Button.BackgroundColor3 = COLORS.Button
		end

		content.Visible = true
		tab.BackgroundColor3 = COLORS.Accent
		currentCategory = categoryName

		if categoryName == "Titles" then
			updateTitlesTab()
		else
			updateInventory()
		end
	end)

	return content
end

local allContent = createCategoryTab("All", 1)
local aurasContent = createCategoryTab("Auras", 2)
local toolsContent = createCategoryTab("Tools", 3)
local titlesContent = createCategoryTab("Titles", 4)

local allScroll = Instance.new("ScrollingFrame")
allScroll.Size = UDim2.new(1, 0, 1, 0)
allScroll.BackgroundTransparency = 1
allScroll.BorderSizePixel = 0
allScroll.ScrollBarThickness = 6
allScroll.ScrollBarImageColor3 = COLORS.Border
allScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
allScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
allScroll.Parent = allContent

local allGrid = Instance.new("UIGridLayout")
allGrid.CellSize = UDim2.new(0.18, 0, 0.25, 0)
allGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
allGrid.SortOrder = Enum.SortOrder.LayoutOrder
allGrid.Parent = allScroll

local aurasScroll = Instance.new("ScrollingFrame")
aurasScroll.Size = UDim2.new(1, 0, 1, 0)
aurasScroll.BackgroundTransparency = 1
aurasScroll.BorderSizePixel = 0
aurasScroll.ScrollBarThickness = 6
aurasScroll.ScrollBarImageColor3 = COLORS.Border
aurasScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
aurasScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
aurasScroll.Parent = aurasContent

local aurasGrid = Instance.new("UIGridLayout")
aurasGrid.CellSize = UDim2.new(0.18, 0, 0.25, 0)
aurasGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
aurasGrid.SortOrder = Enum.SortOrder.LayoutOrder
aurasGrid.Parent = aurasScroll

local toolsScroll = Instance.new("ScrollingFrame")
toolsScroll.Size = UDim2.new(1, 0, 1, 0)
toolsScroll.BackgroundTransparency = 1
toolsScroll.BorderSizePixel = 0
toolsScroll.ScrollBarThickness = 6
toolsScroll.ScrollBarImageColor3 = COLORS.Border
toolsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
toolsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
toolsScroll.Parent = toolsContent

local toolsGrid = Instance.new("UIGridLayout")
toolsGrid.CellSize = UDim2.new(0.18, 0, 0.25, 0)
toolsGrid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
toolsGrid.SortOrder = Enum.SortOrder.LayoutOrder
toolsGrid.Parent = toolsScroll

local titleFilterFrame = Instance.new("Frame")
titleFilterFrame.Size = UDim2.new(1, 0, 0.1, 0)
titleFilterFrame.BackgroundTransparency = 1
titleFilterFrame.Parent = titlesContent

local titleFilterLayout = Instance.new("UIListLayout")
titleFilterLayout.FillDirection = Enum.FillDirection.Horizontal
titleFilterLayout.Padding = UDim.new(0.02, 0)
titleFilterLayout.Parent = titleFilterFrame

local function createTitleFilterBtn(text, filter)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.2, 0, 1, 0)
	btn.BackgroundColor3 = filter == "All" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.AutoButtonColor = false
	btn.Parent = titleFilterFrame

	createCorner(6).Parent = btn
	makeTextAdaptive(btn, 13)

	btn.MouseButton1Click:Connect(function()
		currentTitleFilter = filter
		for _, child in ipairs(titleFilterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Button
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
		updateTitlesTab()
	end)

	return btn
end

createTitleFilterBtn("All", "All")
createTitleFilterBtn("Special", "Special")
createTitleFilterBtn("Summit", "Summit")

local titlesScroll = Instance.new("ScrollingFrame")
titlesScroll.Size = UDim2.new(1, 0, 0.88, 0)
titlesScroll.Position = UDim2.new(0, 0, 0.12, 0)
titlesScroll.BackgroundTransparency = 1
titlesScroll.BorderSizePixel = 0
titlesScroll.ScrollBarThickness = 6
titlesScroll.ScrollBarImageColor3 = COLORS.Border
titlesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
titlesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
titlesScroll.Parent = titlesContent

local titlesGrid = Instance.new("UIGridLayout")
titlesGrid.CellSize = UDim2.new(0.47, 0, 0, 65)
titlesGrid.CellPadding = UDim2.new(0.03, 0, 0, 12)
titlesGrid.SortOrder = Enum.SortOrder.LayoutOrder
titlesGrid.Parent = titlesScroll

local titlesEmptyLabel = Instance.new("TextLabel")
titlesEmptyLabel.Size = UDim2.new(1, 0, 0.25, 0)
titlesEmptyLabel.BackgroundTransparency = 1
titlesEmptyLabel.Font = Enum.Font.Gotham
titlesEmptyLabel.Text = "No titles unlocked yet"
titlesEmptyLabel.TextColor3 = COLORS.TextSecondary
titlesEmptyLabel.Visible = false
titlesEmptyLabel.Parent = titlesScroll
makeTextAdaptive(titlesEmptyLabel, 14)

local function createAuraItem(auraId, parentFrame)
	if not equipAuraEvent or not unequipAuraEvent then
		return nil
	end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createCorner(10).Parent = frame

	local isEquipped = inventoryData.EquippedAura == auraId

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0.7, 0, 0.15, 0)
		equippedBadge.Position = UDim2.new(0.5, 0, 0.02, 0)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.Parent = equippedBadge
		makeTextAdaptive(badgeLabel, 10)
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.35, 0)
	icon.Position = UDim2.new(0, 0, 0.18, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "✨"
	icon.TextColor3 = COLORS.Accent
	icon.Parent = frame
	makeTextAdaptive(icon, 30)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = auraId
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	makeTextAdaptive(nameLabel, 12)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0.2, 0)
	btn.Position = UDim2.new(0.5, 0, 0.95, 0)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.AutoButtonColor = false
	btn.Parent = frame
	makeTextAdaptive(btn, 12)

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipAuraEvent:FireServer()
			inventoryData.EquippedAura = nil
		else
			equipAuraEvent:FireServer(auraId)
			inventoryData.EquippedAura = auraId
		end
		task.delay(0.1, function()
			updateInventory()
		end)
	end)

	return frame
end

local function createToolItem(toolId, parentFrame)
	if not equipToolEvent or not unequipToolEvent then
		return nil
	end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = parentFrame

	createCorner(10).Parent = frame

	local isEquipped = inventoryData.EquippedTool == toolId

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0.7, 0, 0.15, 0)
		equippedBadge.Position = UDim2.new(0.5, 0, 0.02, 0)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.Parent = equippedBadge
		makeTextAdaptive(badgeLabel, 10)
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.35, 0)
	icon.Position = UDim2.new(0, 0, 0.18, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "🔧"
	icon.TextColor3 = COLORS.Success
	icon.Parent = frame
	makeTextAdaptive(icon, 30)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Text = toolId
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	makeTextAdaptive(nameLabel, 12)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0.2, 0)
	btn.Position = UDim2.new(0.5, 0, 0.95, 0)
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.AutoButtonColor = false
	btn.Parent = frame
	makeTextAdaptive(btn, 12)

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipToolEvent:FireServer()
			inventoryData.EquippedTool = nil
		else
			equipToolEvent:FireServer(toolId)
			inventoryData.EquippedTool = toolId
		end
		task.delay(0.1, function()
			updateInventory()
		end)
	end)

	return frame
end

local function createTitleItem(titleName)
	local titleInfo = summitTitleCache[titleName]

	if not titleInfo and TitleConfig.SpecialTitles[titleName] then
		local data = TitleConfig.SpecialTitles[titleName]
		titleInfo = {
			Name = titleName,
			DisplayName = data.DisplayName,
			Color = data.Color,
			Icon = data.Icon
		}
	end

	if not titleInfo then return nil end

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = titlesScroll

	createCorner(10).Parent = frame
	createStroke(titleInfo.Color, 2).Parent = frame

	local isEquipped = titleData.EquippedTitle == titleName

	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.new(0.35, 0, 0.25, 0)
		equippedBadge.Position = UDim2.new(0.5, 0, 0.02, 0)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = COLORS.Equipped
		equippedBadge.BorderSizePixel = 0
		equippedBadge.Parent = frame

		createCorner(6).Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Text = "EQUIPPED"
		badgeLabel.TextColor3 = COLORS.Text
		badgeLabel.Parent = equippedBadge
		makeTextAdaptive(badgeLabel, 10)
	end

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0.15, 0, 0.6, 0)
	icon.Position = UDim2.new(0.03, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = titleInfo.Icon
	icon.TextColor3 = titleInfo.Color
	icon.Parent = frame
	makeTextAdaptive(icon, 24)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.2, 0, 0.5, 0)
	nameLabel.AnchorPoint = Vector2.new(0, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = titleInfo.DisplayName
	nameLabel.TextColor3 = titleInfo.Color
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	makeTextAdaptive(nameLabel, 14)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.25, 0, 0.45, 0)
	btn.Position = UDim2.new(0.95, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.BackgroundColor3 = isEquipped and COLORS.Danger or COLORS.Accent
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = isEquipped and "Unequip" or "Equip"
	btn.TextColor3 = COLORS.Text
	btn.AutoButtonColor = false
	btn.Parent = frame
	makeTextAdaptive(btn, 12)

	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			unequipTitleEvent:FireServer()
			titleData.EquippedTitle = nil
		else
			equipTitleEvent:FireServer(titleName)
			titleData.EquippedTitle = titleName
		end
		task.delay(0.1, function()
			updateTitlesTab()
		end)
	end)

	return frame
end

function updateInventory()
	for _, child in ipairs(allScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, child in ipairs(aurasScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, child in ipairs(toolsScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if inventoryData.OwnedAuras then
		for _, auraId in ipairs(inventoryData.OwnedAuras) do
			if currentCategory == "All" or currentCategory == "Auras" then
				local targetParent = currentCategory == "All" and allScroll or aurasScroll
				createAuraItem(auraId, targetParent)
			end
		end
	end

	if inventoryData.OwnedTools then
		for _, toolId in ipairs(inventoryData.OwnedTools) do
			if currentCategory == "All" or currentCategory == "Tools" then
				local targetParent = currentCategory == "All" and allScroll or toolsScroll
				createToolItem(toolId, targetParent)
			end
		end
	end
end

function updateTitlesTab()
	for _, child in ipairs(titlesScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local itemsToShow = {}

	if not titleData.UnlockedTitles then
		titleData.UnlockedTitles = {}
	end

	for _, titleName in ipairs(titleData.UnlockedTitles) do
		local isSpecial = TitleConfig.SpecialTitles[titleName] ~= nil
		local isSummit = summitTitleCache[titleName] ~= nil

		if currentTitleFilter == "All" then
			table.insert(itemsToShow, titleName)
		elseif currentTitleFilter == "Special" and isSpecial then
			table.insert(itemsToShow, titleName)
		elseif currentTitleFilter == "Summit" and isSummit then
			table.insert(itemsToShow, titleName)
		end
	end

	if #itemsToShow == 0 then
		titlesEmptyLabel.Visible = true
		titlesEmptyLabel.Text = currentTitleFilter == "All"
			and "No titles unlocked yet"
			or ("No " .. currentTitleFilter .. " titles unlocked")
	else
		titlesEmptyLabel.Visible = false
		for _, titleName in ipairs(itemsToShow) do
			createTitleItem(titleName)
		end
	end
end

local function fetchInventory()
	if not getInventoryFunc then return end

	local success, data = pcall(function()
		return getInventoryFunc:InvokeServer()
	end)

	if success and data then
		inventoryData = data
		updateInventory()
	end
end

local function fetchTitles()
	if not getUnlockedTitlesFunc then return end

	local success, data = pcall(function()
		return getUnlockedTitlesFunc:InvokeServer()
	end)

	if success and data then
		titleData = data
		if currentCategory == "Titles" then
			updateTitlesTab()
		end
	end
end

local inventoryIcon = Icon.new()
	:setLabel("Inventory")
	:setImage(18929686504)
	:setOrder(2)
	:bindEvent("selected", function()
		mainPanel.Visible = true
		fetchInventory()
		fetchTitles()
	end)
	:bindEvent("deselected", function()
		mainPanel.Visible = false
	end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if mainPanel.Visible then
			mainPanel.Visible = false
			inventoryIcon:deselect()
		else
			mainPanel.Visible = true
			inventoryIcon:select()
			fetchInventory()
			fetchTitles()
		end
	end
end)
