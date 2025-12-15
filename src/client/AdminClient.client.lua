--[[
    ROBLOX ADMIN PANEL SYSTEM - CLIENT
    Modern admin panel with notification system and player management
    
    Installation:
    1. Place this script in StarterPlayerScripts
    2. Place the ServerScript in ServerScriptService
    3. Make sure TopbarPlus module is available in ReplicatedStorage (optional)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ GANTI BAGIAN INI:
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

-- Check if player is admin
local function isAdmin()
	-- ✅ TAMBAH NULL CHECK
	if not TitleConfig.AdminIds then
		warn("⚠️ TitleConfig.AdminIds is nil!")
		return false
	end

	for _, id in ipairs(TitleConfig.AdminIds) do
		if player.UserId == id then
			return true
		end
	end
	return false
end

if not isAdmin() then
	return -- Exit if not admin
end



-- Wait for RemoteEvents
local remoteFolder = ReplicatedStorage:WaitForChild("AdminRemotes", 10)
if not remoteFolder then
	warn("AdminRemotes folder not found! Server script may not be running.")
	return
end

local kickPlayerEvent = remoteFolder:WaitForChild("KickPlayer")
local banPlayerEvent = remoteFolder:WaitForChild("BanPlayer")
local teleportHereEvent = remoteFolder:WaitForChild("TeleportHere")
local teleportToEvent = remoteFolder:WaitForChild("TeleportTo")
local freezePlayerEvent = remoteFolder:WaitForChild("FreezePlayer")
local setSpeedEvent = remoteFolder:WaitForChild("SetSpeed")
local setGravityEvent = remoteFolder:WaitForChild("SetGravity")
local killPlayerEvent = remoteFolder:WaitForChild("KillPlayer")
local sendNotificationEvent = remoteFolder:WaitForChild("SendGlobalNotification", 5)



-- Try to load TopbarPlus with error handling
local Icon
local topbarPlusLoaded = false

local function loadTopbarPlus()
	local success, result = pcall(function()
		-- Try different possible locations
		local iconModule = ReplicatedStorage:FindFirstChild("Icon") 
			or ReplicatedStorage:FindFirstChild("TopbarPlus")
			or ReplicatedStorage:FindFirstChild("IconModule")

		if iconModule then
			return require(iconModule)
		else
			warn("TopbarPlus module not found in ReplicatedStorage")
			return nil
		end
	end)

	if success and result then
		Icon = result
		topbarPlusLoaded = true
		print("✓ TopbarPlus loaded successfully")
		return true
	else
		warn("Failed to load TopbarPlus: " .. tostring(result))
		return false
	end
end

-- Wait a bit for ReplicatedStorage to load
task.wait(1)
loadTopbarPlus()

-- If TopbarPlus fails, we'll create a fallback button
if not topbarPlusLoaded then
	warn("TopbarPlus not available, using fallback button")
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanelGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Color Scheme
local COLORS = {
	Background = Color3.fromRGB(25, 25, 30),
	Panel = Color3.fromRGB(30, 30, 35),
	Header = Color3.fromRGB(35, 35, 40),
	Button = Color3.fromRGB(45, 45, 50),
	ButtonHover = Color3.fromRGB(55, 55, 60),
	Accent = Color3.fromRGB(88, 101, 242),
	AccentHover = Color3.fromRGB(108, 121, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Danger = Color3.fromRGB(237, 66, 69),
	DangerHover = Color3.fromRGB(255, 86, 89),
	Success = Color3.fromRGB(67, 181, 129),
	Border = Color3.fromRGB(50, 50, 55)
}

-- Utility Functions
local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createPadding(padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.02, 0)
	pad.PaddingBottom = UDim.new(0.02, 0)
	pad.PaddingLeft = UDim.new(0.02, 0)
	pad.PaddingRight = UDim.new(0.02, 0)
	return pad
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
	aspectRatio.AspectRatio = ratio or .8
	aspectRatio.DominantAxis = Enum.DominantAxis.Width  -- ✅ Ubah ke Height agar panel lebih besar
	aspectRatio.Parent = frame
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

local function tweenPosition(object, endPos, time, callback)
	local tween = TweenService:Create(object, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = endPos
	})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

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

-- Make frame draggable
-- Make frame draggable (RESPONSIVE VERSION)
local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput, mousePos, framePos

	dragHandle = dragHandle or frame

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			local viewport = workspace.CurrentCamera.ViewportSize

			-- ✅ Konversi delta pixel ke scale
			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			frame.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,  -- ✅ Offset selalu 0
				framePos.Y.Scale + deltaScaleY,
				0   -- ✅ Offset selalu 0
			)
		end
	end)
end


-- Create Button (✅ ADAPTIVE)
local function createButton(text, color, hoverColor)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0.1, 0)
	button.BackgroundColor3 = color or COLORS.Button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.AutoButtonColor = false
	
	-- ✅ TextScaled with constraint
	button.TextScaled = true
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 14
	textConstraint.MinTextSize = 1
	textConstraint.Parent = button

	createCorner(6).Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor or COLORS.ButtonHover}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or COLORS.Button}):Play()
	end)

	return button
end

local showConfirmation

-- Main Admin Panel (✅ FULLY ADAPTIVE)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(1, 0, 1, 0)  -- ✅ Ukuran lebih besar
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui

createCorner(12).Parent = mainPanel
createStroke(COLORS.Border, 2).Parent = mainPanel
addAspectRatio(mainPanel, 0.8)  -- ✅ AspectRatio 0.8 dengan DominantAxis = Width

-- Panel Header (✅ SCALE-BASED)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.08, 0)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = mainPanel

createCorner(12).Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.8, 0, 1, 0)
headerTitle.Position = UDim2.new(0.05, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "Admin Panel"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header
makeTextAdaptive(headerTitle, 18)  -- ✅ Adaptive text

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.1, 0, 0.7, 0)
closeButton.Position = UDim2.new(0.95, 0, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "×"
closeButton.TextColor3 = COLORS.Text
closeButton.Parent = header
makeTextAdaptive(closeButton, 20)  -- ✅ Adaptive text

createCorner(6).Parent = closeButton

-- Tab System (✅ SCALE-BASED)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0.94, 0, 0.06, 0)
tabContainer.Position = UDim2.new(0.03, 0, 0.1, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based padding
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabContainer

-- Content Container (✅ SCALE-BASED)
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(0.94, 0, 0.78, 0)
contentContainer.Position = UDim2.new(0.03, 0, 0.18, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainPanel

-- Tab Creation Function (✅ FULLY ADAPTIVE)
local currentTab = nil
local totalTabs = 4

local function createTab(name, order)
	local tab = Instance.new("TextButton")
	
	-- ✅ Fully Scale-based (no offset)
	tab.Size = UDim2.new(0.23, 0, 1, 0)
	tab.BackgroundColor3 = COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamMedium
	tab.Text = name
	tab.TextColor3 = COLORS.TextSecondary
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = tabContainer

	createCorner(6).Parent = tab
	makeTextAdaptive(tab, 13)  -- ✅ Adaptive text without MinTextSize

	local content = Instance.new("Frame")
	content.Name = name .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Visible = false
	content.Parent = contentContainer

	tab.MouseButton1Click:Connect(function()
		-- Hide all tabs
		for _, child in ipairs(contentContainer:GetChildren()) do
			child.Visible = false
		end

		-- Reset all tab colors
		for _, tabBtn in ipairs(tabContainer:GetChildren()) do
			if tabBtn:IsA("TextButton") then
				tabBtn.BackgroundColor3 = COLORS.Button
				tabBtn.TextColor3 = COLORS.TextSecondary
			end
		end

		-- Show selected tab
		content.Visible = true
		tab.BackgroundColor3 = COLORS.Accent
		tab.TextColor3 = COLORS.Text
		currentTab = content
	end)

	return content, tab
end



-- Notification Tab
local notifTab, notifTabBtn = createTab("Notifications", 1)

local notifScroll = Instance.new("ScrollingFrame")
notifScroll.Size = UDim2.new(1, 0, 1, 0)
notifScroll.BackgroundTransparency = 1
notifScroll.BorderSizePixel = 0
notifScroll.ScrollBarThickness = 4
notifScroll.ScrollBarImageColor3 = COLORS.Border
notifScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
notifScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
notifScroll.Parent = notifTab

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based padding
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Parent = notifScroll

-- Notification Type Selection (✅ ADAPTIVE)
local typeFrame = Instance.new("Frame")
typeFrame.Size = UDim2.new(1, 0, 0.1, 0)
typeFrame.BackgroundTransparency = 1
typeFrame.LayoutOrder = 1
typeFrame.Parent = notifScroll

local typeLabel = Instance.new("TextLabel")
typeLabel.Size = UDim2.new(0.25, 0, 1, 0)
typeLabel.BackgroundTransparency = 1
typeLabel.Font = Enum.Font.GothamMedium
typeLabel.Text = "Type:"
typeLabel.TextColor3 = COLORS.Text
typeLabel.TextXAlignment = Enum.TextXAlignment.Left
typeLabel.Parent = typeFrame
makeTextAdaptive(typeLabel, 14)

local typeButtons = Instance.new("Frame")
typeButtons.Size = UDim2.new(0.7, 0, 1, 0)
typeButtons.Position = UDim2.new(0.28, 0, 0, 0)
typeButtons.BackgroundTransparency = 1
typeButtons.Parent = typeFrame

local typeLayout = Instance.new("UIListLayout")
typeLayout.FillDirection = Enum.FillDirection.Horizontal
typeLayout.Padding = UDim.new(0.02, 0)  -- ✅ Scale-based padding
typeLayout.Parent = typeButtons

local selectedType = "Server"

local function createTypeButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.35, 0, 0.9, 0)  -- ✅ Scale-based
	btn.BackgroundColor3 = text == "Server" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.AutoButtonColor = false
	btn.Parent = typeButtons
	
	makeTextAdaptive(btn, 13)  -- ✅ Adaptive text
	createCorner(6).Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedType = text
		for _, child in ipairs(typeButtons:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = COLORS.Button
			end
		end
		btn.BackgroundColor3 = COLORS.Accent
	end)

	return btn
end

createTypeButton("Server")
createTypeButton("Global")

-- Message Input (✅ ADAPTIVE)
local messageFrame = Instance.new("Frame")
messageFrame.Size = UDim2.new(1, 0, 0.35, 0)
messageFrame.BackgroundTransparency = 1
messageFrame.LayoutOrder = 2
messageFrame.Parent = notifScroll

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, 0, 0.15, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamMedium
messageLabel.Text = "Message:"
messageLabel.TextColor3 = COLORS.Text
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Parent = messageFrame
makeTextAdaptive(messageLabel, 14)

local messageBox = Instance.new("TextBox")
messageBox.Size = UDim2.new(1, 0, 0.75, 0)
messageBox.Position = UDim2.new(0, 0, 0.2, 0)
messageBox.BackgroundColor3 = COLORS.Panel
messageBox.BorderSizePixel = 0
messageBox.Font = Enum.Font.Gotham
messageBox.PlaceholderText = "Enter notification message..."
messageBox.Text = ""
messageBox.TextColor3 = COLORS.Text
messageBox.TextWrapped = true
messageBox.TextXAlignment = Enum.TextXAlignment.Left
messageBox.TextYAlignment = Enum.TextYAlignment.Top
messageBox.ClearTextOnFocus = false
messageBox.MultiLine = true
messageBox.Parent = messageFrame
makeTextAdaptive(messageBox, 13)

createCorner(6).Parent = messageBox
createPadding(8).Parent = messageBox

-- Duration Slider (✅ ADAPTIVE)
local durationFrame = Instance.new("Frame")
durationFrame.Size = UDim2.new(1, 0, 0.12, 0)
durationFrame.BackgroundTransparency = 1
durationFrame.LayoutOrder = 3
durationFrame.Parent = notifScroll

local durationLabel = Instance.new("TextLabel")
durationLabel.Size = UDim2.new(1, 0, 0.4, 0)
durationLabel.BackgroundTransparency = 1
durationLabel.Font = Enum.Font.GothamMedium
durationLabel.Text = "Duration: 5s"
durationLabel.TextColor3 = COLORS.Text
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = durationFrame
makeTextAdaptive(durationLabel, 14)

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0.2, 0)
sliderBg.Position = UDim2.new(0, 0, 0.6, 0)
sliderBg.BackgroundColor3 = COLORS.Panel
sliderBg.BorderSizePixel = 0
sliderBg.Parent = durationFrame

createCorner(4).Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.042, 0, 1, 0)
sliderFill.BackgroundColor3 = COLORS.Accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

createCorner(4).Parent = sliderFill

local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0.04, 0, 2.5, 0)  -- ✅ Scale-based
sliderHandle.Position = UDim2.new(0.042, 0, 0.5, 0)
sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
sliderHandle.BackgroundColor3 = COLORS.Text
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderBg

createCorner(8).Parent = sliderHandle

local selectedDuration = 5
local draggingSlider = false

sliderHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and draggingSlider then
		local mousePos = UserInputService:GetMouseLocation()
		local sliderPos = sliderBg.AbsolutePosition.X
		local sliderSize = sliderBg.AbsoluteSize.X
		local relativePos = math.clamp((mousePos.X - sliderPos) / sliderSize, 0, 1)

		selectedDuration = math.floor(relativePos * 120 + 1) -- 1 to 120 seconds
		durationLabel.Text = "Duration: " .. selectedDuration .. "s"

		sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
		sliderHandle.Position = UDim2.new(relativePos, 0, 0.5, 0)
	end
end)

-- Text Color Picker (✅ ADAPTIVE)
local colorFrame = Instance.new("Frame")
colorFrame.Size = UDim2.new(1, 0, 0.12, 0)
colorFrame.BackgroundTransparency = 1
colorFrame.LayoutOrder = 4
colorFrame.Parent = notifScroll

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(1, 0, 0.35, 0)
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.Text = "Text Color:"
colorLabel.TextColor3 = COLORS.Text
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = colorFrame
makeTextAdaptive(colorLabel, 14)

local colorContainer = Instance.new("Frame")
colorContainer.Size = UDim2.new(1, 0, 0.55, 0)
colorContainer.Position = UDim2.new(0, 0, 0.4, 0)
colorContainer.BackgroundTransparency = 1
colorContainer.Parent = colorFrame

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0.02, 0)  -- ✅ Scale-based padding
colorLayout.Parent = colorContainer

local selectedColor = Color3.fromRGB(255, 255, 255)

local function createColorButton(color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.1, 0, 1, 0)  -- ✅ Scale-based
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = colorContainer

	createCorner(6).Parent = btn

	local checkmark = Instance.new("TextLabel")
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Font = Enum.Font.GothamBold
	checkmark.Text = "✓"
	checkmark.TextColor3 = Color3.fromRGB(0, 0, 0)
	checkmark.Visible = color == Color3.fromRGB(255, 255, 255)
	checkmark.Parent = btn
	makeTextAdaptive(checkmark, 18)  -- ✅ Adaptive text

	btn.MouseButton1Click:Connect(function()
		selectedColor = color
		for _, child in ipairs(colorContainer:GetChildren()) do
			if child:IsA("TextButton") then
				local check = child:FindFirstChildOfClass("TextLabel")
				if check then
					check.Visible = false
				end
			end
		end
		checkmark.Visible = true
	end)
end

createColorButton(Color3.fromRGB(255, 255, 255))
createColorButton(Color3.fromRGB(88, 101, 242))
createColorButton(Color3.fromRGB(67, 181, 129))
createColorButton(Color3.fromRGB(250, 166, 26))
createColorButton(Color3.fromRGB(237, 66, 69))
createColorButton(Color3.fromRGB(153, 170, 181))

-- Send Button (✅ ADAPTIVE)
local sendFrame = Instance.new("Frame")
sendFrame.Size = UDim2.new(1, 0, 0.1, 0)
sendFrame.BackgroundTransparency = 1
sendFrame.LayoutOrder = 5
sendFrame.Parent = notifScroll

local sendButton = createButton("Send Notification", COLORS.Accent, COLORS.AccentHover)
sendButton.Size = UDim2.new(1, 0, 1, 0)
sendButton.Parent = sendFrame

-- Update send button
sendButton.MouseButton1Click:Connect(function()
	if messageBox.Text ~= "" then
		local notifText = messageBox.Text
		local color = selectedColor or Color3.fromRGB(255, 255, 255)

		-- Fire with color parameter
		sendNotificationEvent:FireServer(selectedType:lower(), notifText, color)

		messageBox.Text = ""
	end
end)



-- Players Tab (✅ ADAPTIVE)
local playersTab, playersTabBtn = createTab("Players", 2)

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, 0, 1, 0)
playersScroll.BackgroundTransparency = 1
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 4
playersScroll.ScrollBarImageColor3 = COLORS.Border
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersScroll.Parent = playersTab

local playersLayout = Instance.new("UIListLayout")
playersLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based padding
playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersLayout.Parent = playersScroll

-- Player Detail Panel (✅ FULLY ADAPTIVE)
local playerDetailPanel = Instance.new("Frame")
playerDetailPanel.Name = "PlayerDetail"
playerDetailPanel.Size = UDim2.new(0.7, 0, 0.9, 0)  -- ✅ Ukuran lebih besar
playerDetailPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
playerDetailPanel.AnchorPoint = Vector2.new(0.5, 0.5)
playerDetailPanel.BackgroundColor3 = COLORS.Background
playerDetailPanel.BorderSizePixel = 0
playerDetailPanel.Visible = false
playerDetailPanel.ZIndex = 10
playerDetailPanel.Parent = screenGui

createCorner(12).Parent = playerDetailPanel
createStroke(COLORS.Border, 2).Parent = playerDetailPanel
addAspectRatio(playerDetailPanel, 0.8)  -- ✅ AspectRatio 0.8 dengan DominantAxis = Width

local detailHeader = Instance.new("Frame")
detailHeader.Size = UDim2.new(1, 0, 0.08, 0)
detailHeader.BackgroundColor3 = COLORS.Header
detailHeader.BorderSizePixel = 0
detailHeader.Parent = playerDetailPanel

createCorner(12).Parent = detailHeader

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(0.8, 0, 1, 0)
detailTitle.Position = UDim2.new(0.03, 0, 0, 0)
detailTitle.BackgroundTransparency = 1
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Text = "Player Details"
detailTitle.TextColor3 = COLORS.Text
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.Parent = detailHeader
makeTextAdaptive(detailTitle, 18)

local detailCloseButton = Instance.new("TextButton")
detailCloseButton.Size = UDim2.new(0.1, 0, 0.7, 0)
detailCloseButton.Position = UDim2.new(0.95, 0, 0.5, 0)
detailCloseButton.AnchorPoint = Vector2.new(1, 0.5)
detailCloseButton.BackgroundColor3 = COLORS.Button
detailCloseButton.BorderSizePixel = 0
detailCloseButton.Font = Enum.Font.GothamBold
detailCloseButton.Text = "×"
detailCloseButton.TextColor3 = COLORS.Text
detailCloseButton.Parent = detailHeader
makeTextAdaptive(detailCloseButton, 20)

createCorner(6).Parent = detailCloseButton

detailCloseButton.MouseButton1Click:Connect(function()
	tweenSize(playerDetailPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		playerDetailPanel.Visible = false
		playerDetailPanel.Size = UDim2.new(0.7, 0, 0.9, 0)  -- ✅ Konsisten dengan ukuran baru
	end)
end)

local detailScroll = Instance.new("ScrollingFrame")
detailScroll.Size = UDim2.new(0.94, 0, 0.88, 0)
detailScroll.Position = UDim2.new(0.03, 0, 0.1, 0)
detailScroll.BackgroundTransparency = 1
detailScroll.BorderSizePixel = 0
detailScroll.ScrollBarThickness = 4
detailScroll.ScrollBarImageColor3 = COLORS.Border
detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
detailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailScroll.Parent = playerDetailPanel

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0.02, 0)  -- ✅ Scale-based padding
detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailLayout.Parent = detailScroll

-- Confirmation Dialog (✅ FULLY ADAPTIVE)
local confirmDialog = Instance.new("Frame")
confirmDialog.Name = "ConfirmDialog"
confirmDialog.Size = UDim2.new(0.4, 0, 0.4, 0)  -- ✅ Ukuran lebih besar
confirmDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmDialog.AnchorPoint = Vector2.new(0.5, 0.5)
confirmDialog.BackgroundColor3 = COLORS.Background
confirmDialog.BorderSizePixel = 0
confirmDialog.Visible = false
confirmDialog.ZIndex = 150
confirmDialog.Parent = screenGui

createCorner(12).Parent = confirmDialog
createStroke(COLORS.Border, 2).Parent = confirmDialog
addAspectRatio(confirmDialog, 1.9)  -- ✅ AspectRatio dengan DominantAxis = Width

-- Header (✅ ADAPTIVE)
local confirmHeader = Instance.new("Frame")
confirmHeader.Size = UDim2.new(1, 0, 0.25, 0)
confirmHeader.BackgroundColor3 = COLORS.Header
confirmHeader.BorderSizePixel = 0
confirmHeader.Parent = confirmDialog

createCorner(12).Parent = confirmHeader

local confirmHeaderBottom = Instance.new("Frame")
confirmHeaderBottom.Size = UDim2.new(1, 0, 0.3, 0)
confirmHeaderBottom.Position = UDim2.new(0, 0, 0.7, 0)
confirmHeaderBottom.BackgroundColor3 = COLORS.Header
confirmHeaderBottom.BorderSizePixel = 0
confirmHeaderBottom.Parent = confirmHeader

-- Title (✅ ADAPTIVE)
local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(0.9, 0, 1, 0)
confirmTitle.Position = UDim2.new(0.05, 0, 0, 0)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Text = "Confirm Action"
confirmTitle.TextColor3 = COLORS.Text
confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
confirmTitle.Parent = confirmHeader
makeTextAdaptive(confirmTitle, 16)

-- Message (✅ ADAPTIVE)
local confirmMessage = Instance.new("TextLabel")
confirmMessage.Size = UDim2.new(0.9, 0, 0.35, 0)
confirmMessage.Position = UDim2.new(0.05, 0, 0.28, 0)
confirmMessage.BackgroundTransparency = 1
confirmMessage.Font = Enum.Font.Gotham
confirmMessage.Text = ""
confirmMessage.TextColor3 = COLORS.TextSecondary
confirmMessage.TextWrapped = true
confirmMessage.TextXAlignment = Enum.TextXAlignment.Center
confirmMessage.TextYAlignment = Enum.TextYAlignment.Top
confirmMessage.Parent = confirmDialog
makeTextAdaptive(confirmMessage, 14)

-- Buttons Container (✅ ADAPTIVE)
local confirmButtons = Instance.new("Frame")
confirmButtons.Size = UDim2.new(0.9, 0, 0.25, 0)
confirmButtons.Position = UDim2.new(0.05, 0, 0.7, 0)
confirmButtons.BackgroundTransparency = 1
confirmButtons.Parent = confirmDialog

local confirmButtonLayout = Instance.new("UIListLayout")
confirmButtonLayout.FillDirection = Enum.FillDirection.Horizontal
confirmButtonLayout.Padding = UDim.new(0.03, 0)  -- ✅ Scale-based padding
confirmButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
confirmButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
confirmButtonLayout.Parent = confirmButtons

local currentConfirmCallback = nil

-- ✅ Assign ke variable yang sudah di-declare sebelumnya
showConfirmation = function(title, message, callback)
	confirmTitle.Text = title
	confirmMessage.Text = message
	currentConfirmCallback = callback
	confirmDialog.Size = UDim2.new(0, 0, 0, 0)
	confirmDialog.Visible = true
	tweenSize(confirmDialog, UDim2.new(0.4, 0, 0.4, 0), 0.3)  -- ✅ Ukuran lebih besar
end


-- Cancel Button (✅ ADAPTIVE)
local cancelButton = createButton("Cancel", COLORS.Button, COLORS.ButtonHover)
cancelButton.Size = UDim2.new(0.4, 0, 1, 0)
cancelButton.LayoutOrder = 1
cancelButton.Parent = confirmButtons

cancelButton.MouseButton1Click:Connect(function()
	tweenSize(confirmDialog, UDim2.new(0, 0, 0, 0), 0.3, function()
		confirmDialog.Visible = false
		currentConfirmCallback = nil
	end)
end)

-- Confirm Button (✅ ADAPTIVE)
local confirmButton = createButton("Confirm", COLORS.Danger, COLORS.DangerHover)
confirmButton.Size = UDim2.new(0.4, 0, 1, 0)
confirmButton.LayoutOrder = 2
confirmButton.Parent = confirmButtons

confirmButton.MouseButton1Click:Connect(function()
	if currentConfirmCallback then
		currentConfirmCallback()
	end
	tweenSize(confirmDialog, UDim2.new(0, 0, 0, 0), 0.3, function()
		confirmDialog.Visible = false
		currentConfirmCallback = nil
	end)
end)

-- Player Actions
local currentSpectatePlayer = nil
local originalCamera = nil
local spectateConnection = nil

-- ✅ ADAPTIVE Teleport Popup
local function createTeleportPopup(targetPlayer)
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0.2, 0, 0.22, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup
	addAspectRatio(popup, 1.2)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.22, 0)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
	headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.75, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Teleport " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	makeTextAdaptive(title, 14)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.12, 0, 0.7, 0)
	closeBtn.Position = UDim2.new(0.93, 0, 0.5, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header
	makeTextAdaptive(closeBtn, 16)

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
	end)

	-- Teleport Here Button (✅ ADAPTIVE)
	local tpHereBtn = Instance.new("TextButton")
	tpHereBtn.Size = UDim2.new(0.9, 0, 0.28, 0)
	tpHereBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
	tpHereBtn.BackgroundColor3 = COLORS.Button
	tpHereBtn.BorderSizePixel = 0
	tpHereBtn.Font = Enum.Font.GothamBold
	tpHereBtn.Text = "Teleport " .. targetPlayer.Name .. " Here"
	tpHereBtn.TextColor3 = COLORS.Text
	tpHereBtn.AutoButtonColor = false
	tpHereBtn.Parent = popup
	makeTextAdaptive(tpHereBtn, 13)

	createCorner(8).Parent = tpHereBtn

	tpHereBtn.MouseEnter:Connect(function()
		tpHereBtn.BackgroundColor3 = COLORS.ButtonHover
	end)

	tpHereBtn.MouseLeave:Connect(function()
		tpHereBtn.BackgroundColor3 = COLORS.Button
	end)

	tpHereBtn.MouseButton1Click:Connect(function()
		teleportHereEvent:FireServer(targetPlayer.UserId)
		popup:Destroy()
	end)

	-- Teleport To Button (✅ ADAPTIVE)
	local tpToBtn = Instance.new("TextButton")
	tpToBtn.Size = UDim2.new(0.9, 0, 0.28, 0)
	tpToBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
	tpToBtn.BackgroundColor3 = COLORS.Button
	tpToBtn.BorderSizePixel = 0
	tpToBtn.Font = Enum.Font.GothamBold
	tpToBtn.Text = "Teleport To " .. targetPlayer.Name
	tpToBtn.TextColor3 = COLORS.Text
	tpToBtn.AutoButtonColor = false
	tpToBtn.Parent = popup
	makeTextAdaptive(tpToBtn, 13)

	createCorner(8).Parent = tpToBtn

	tpToBtn.MouseEnter:Connect(function()
		tpToBtn.BackgroundColor3 = COLORS.ButtonHover
	end)

	tpToBtn.MouseLeave:Connect(function()
		tpToBtn.BackgroundColor3 = COLORS.Button
	end)

	tpToBtn.MouseButton1Click:Connect(function()
		teleportToEvent:FireServer(targetPlayer.UserId)
		popup:Destroy()
	end)

	return popup
end

-- ✅ ADAPTIVE Set Title Popup
local function showSetTitlePopup(targetPlayer)
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0.2, 0, 0.35, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Active = true
	popup.Draggable = true
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup
	addAspectRatio(popup, 0.75)

	-- Header (✅ ADAPTIVE)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
	headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Set Title for " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	makeTextAdaptive(title, 14)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.1, 0, 0.7, 0)
	closeBtn.Position = UDim2.new(0.93, 0, 0.5, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header
	makeTextAdaptive(closeBtn, 16)

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
	end)

	-- Content Container with UIListLayout (✅ ADAPTIVE)
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(0.9, 0, 0.7, 0)
	contentContainer.Position = UDim2.new(0.05, 0, 0.15, 0)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = popup

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0.02, 0)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = contentContainer

	-- Title Options
	local titleOptions = {"VVIP", "VIP", "Pengunjung"}
	local selectedTitle = nil
	local titleButtons = {}

	for i, titleName in ipairs(titleOptions) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0.22, 0)
		btn.BackgroundColor3 = COLORS.Button
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.Text = titleName
		btn.TextColor3 = COLORS.Text
		btn.AutoButtonColor = false
		btn.LayoutOrder = i
		btn.Parent = contentContainer
		makeTextAdaptive(btn, 13)

		createCorner(8).Parent = btn

		titleButtons[titleName] = btn

		btn.MouseButton1Click:Connect(function()
			selectedTitle = titleName

			for name, button in pairs(titleButtons) do
				button.BackgroundColor3 = (name == titleName) and COLORS.Accent or COLORS.Button
			end
		end)
	end

	-- Apply Button (✅ ADAPTIVE)
	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.new(1, 0, 0.18, 0)
	applyBtn.BackgroundColor3 = COLORS.Success
	applyBtn.BorderSizePixel = 0
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.Text = "Apply"
	applyBtn.TextColor3 = COLORS.Text
	applyBtn.AutoButtonColor = false
	applyBtn.LayoutOrder = 10
	applyBtn.Parent = contentContainer
	makeTextAdaptive(applyBtn, 14)

	createCorner(8).Parent = applyBtn

	applyBtn.MouseEnter:Connect(function()
		applyBtn.BackgroundColor3 = Color3.fromRGB(77, 191, 139)
	end)

	applyBtn.MouseLeave:Connect(function()
		applyBtn.BackgroundColor3 = COLORS.Success
	end)

	applyBtn.MouseButton1Click:Connect(function()
		if selectedTitle then
			local setTitleEvent = remoteFolder:FindFirstChild("SetPlayerTitle")
			if setTitleEvent then
				setTitleEvent:FireServer(targetPlayer.UserId, selectedTitle)
			end
			popup:Destroy()
		else
			StarterGui:SetCore("SendNotification", {
				Title = "Warning",
				Text = "Please select a title first!",
				Duration = 3
			})
		end
	end)

	return popup
end



-- ✅ ADAPTIVE Modify Player Popup
local function createModifyPlayerPopup(targetPlayer)
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0.22, 0, 0.35, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Active = true
	popup.Draggable = true
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup
	addAspectRatio(popup, 0.8)

	-- Header (✅ ADAPTIVE)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
	headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Modify " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	makeTextAdaptive(title, 14)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.1, 0, 0.7, 0)
	closeBtn.Position = UDim2.new(0.93, 0, 0.5, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header
	makeTextAdaptive(closeBtn, 16)

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
	end)

	-- Content Container (✅ ADAPTIVE)
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(0.9, 0, 0.82, 0)
	contentContainer.Position = UDim2.new(0.05, 0, 0.14, 0)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = popup

	-- Freeze Button (✅ ADAPTIVE)
	local isFrozen = false
	local freezeBtn = Instance.new("TextButton")
	freezeBtn.Size = UDim2.new(1, 0, 0.15, 0)
	freezeBtn.Position = UDim2.new(0, 0, 0, 0)
	freezeBtn.BackgroundColor3 = COLORS.Button
	freezeBtn.BorderSizePixel = 0
	freezeBtn.Font = Enum.Font.GothamBold
	freezeBtn.Text = "Freeze Player"
	freezeBtn.TextColor3 = COLORS.Text
	freezeBtn.AutoButtonColor = false
	freezeBtn.Parent = contentContainer
	makeTextAdaptive(freezeBtn, 13)

	createCorner(8).Parent = freezeBtn

	freezeBtn.MouseButton1Click:Connect(function()
		isFrozen = not isFrozen

		if isFrozen then
			freezeBtn.BackgroundColor3 = COLORS.Success
			freezeBtn.Text = "Unfreeze Player"
			freezePlayerEvent:FireServer(targetPlayer.UserId, true)
		else
			freezeBtn.BackgroundColor3 = COLORS.Button
			freezeBtn.Text = "Freeze Player"
			freezePlayerEvent:FireServer(targetPlayer.UserId, false)
		end
	end)

	-- Speed Label (✅ ADAPTIVE)
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1, 0, 0.08, 0)
	speedLabel.Position = UDim2.new(0, 0, 0.18, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Text = "Speed Multiplier: 1.0x"
	speedLabel.TextColor3 = COLORS.Text
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = contentContainer
	makeTextAdaptive(speedLabel, 12)

	-- Speed Slider (✅ ADAPTIVE)
	local speedSliderBg = Instance.new("Frame")
	speedSliderBg.Size = UDim2.new(1, 0, 0.04, 0)
	speedSliderBg.Position = UDim2.new(0, 0, 0.28, 0)
	speedSliderBg.BackgroundColor3 = COLORS.Panel
	speedSliderBg.BorderSizePixel = 0
	speedSliderBg.Parent = contentContainer

	createCorner(4).Parent = speedSliderBg

	local speedFill = Instance.new("Frame")
	speedFill.Size = UDim2.new(0.2, 0, 1, 0)
	speedFill.BackgroundColor3 = COLORS.Accent
	speedFill.BorderSizePixel = 0
	speedFill.Parent = speedSliderBg

	createCorner(4).Parent = speedFill

	local speedHandle = Instance.new("Frame")
	speedHandle.Size = UDim2.new(0.05, 0, 3, 0)
	speedHandle.Position = UDim2.new(0.2, 0, 0.5, 0)
	speedHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	speedHandle.BackgroundColor3 = COLORS.Text
	speedHandle.BorderSizePixel = 0
	speedHandle.Parent = speedSliderBg

	createCorner(8).Parent = speedHandle

	-- Speed slider interaction
	local draggingSpeed = false

	speedSliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSpeed = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSpeed and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position.X
			local sliderPos = speedSliderBg.AbsolutePosition.X
			local sliderSize = speedSliderBg.AbsoluteSize.X
			local relative = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)

			speedFill.Size = UDim2.new(relative, 0, 1, 0)
			speedHandle.Position = UDim2.new(relative, 0, 0.5, 0)

			local speedValue = 0.1 + (relative * 3.9)
			speedLabel.Text = string.format("Speed Multiplier: %.1fx", speedValue)
			setSpeedEvent:FireServer(targetPlayer.UserId, speedValue)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSpeed = false
		end
	end)

	-- Gravity Label (✅ ADAPTIVE)
	local gravityLabel = Instance.new("TextLabel")
	gravityLabel.Size = UDim2.new(1, 0, 0.08, 0)
	gravityLabel.Position = UDim2.new(0, 0, 0.36, 0)
	gravityLabel.BackgroundTransparency = 1
	gravityLabel.Font = Enum.Font.GothamBold
	gravityLabel.Text = "Gravity: Normal"
	gravityLabel.TextColor3 = COLORS.Text
	gravityLabel.TextXAlignment = Enum.TextXAlignment.Left
	gravityLabel.Parent = contentContainer
	makeTextAdaptive(gravityLabel, 12)

	-- Gravity Buttons Container (✅ ADAPTIVE)
	local gravityContainer = Instance.new("Frame")
	gravityContainer.Size = UDim2.new(1, 0, 0.12, 0)
	gravityContainer.Position = UDim2.new(0, 0, 0.46, 0)
	gravityContainer.BackgroundTransparency = 1
	gravityContainer.Parent = contentContainer

	local gravityLayout = Instance.new("UIListLayout")
	gravityLayout.FillDirection = Enum.FillDirection.Horizontal
	gravityLayout.Padding = UDim.new(0.02, 0)
	gravityLayout.Parent = gravityContainer

	local gravityTypes = {"Normal", "Low", "Zero", "High"}
	local currentGravity = "Normal"

	for i, gType in ipairs(gravityTypes) do
		local gBtn = Instance.new("TextButton")
		gBtn.Size = UDim2.new(0.23, 0, 1, 0)
		gBtn.BackgroundColor3 = (i == 1) and COLORS.Accent or COLORS.Button
		gBtn.BorderSizePixel = 0
		gBtn.Font = Enum.Font.GothamBold
		gBtn.Text = gType
		gBtn.TextColor3 = COLORS.Text
		gBtn.AutoButtonColor = false
		gBtn.LayoutOrder = i
		gBtn.Parent = gravityContainer
		makeTextAdaptive(gBtn, 11)

		createCorner(6).Parent = gBtn

		gBtn.MouseButton1Click:Connect(function()
			currentGravity = gType
			gravityLabel.Text = "Gravity: " .. gType

			local gravValue = 196.2
			if gType == "Low" then gravValue = 50
			elseif gType == "Zero" then gravValue = 0
			elseif gType == "High" then gravValue = 400 end

			setGravityEvent:FireServer(targetPlayer.UserId, gravValue)

			-- Update colors
			for _, btn in ipairs(gravityContainer:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = (btn.Text == gType) and COLORS.Accent or COLORS.Button
				end
			end
		end)
	end

	return popup
end

-- ✅ ADAPTIVE Modify Summit Popup
local function showModifySummitPopup(targetPlayer)
	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0.22, 0, 0.32, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup
	addAspectRatio(popup, 1.3)

	-- ✅ DRAGGABLE
	makeDraggable(popup)

	-- Header (✅ ADAPTIVE)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.18, 0)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
	headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Modify " .. targetPlayer.Name .. " Summit Data"
	title.TextColor3 = COLORS.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	makeTextAdaptive(title, 15)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.1, 0, 0.6, 0)
	closeBtn.Position = UDim2.new(0.93, 0, 0.5, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header
	makeTextAdaptive(closeBtn, 18)

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
	end)

	-- Content Container (✅ ADAPTIVE)
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(0.9, 0, 0.75, 0)
	contentContainer.Position = UDim2.new(0.05, 0, 0.22, 0)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = popup

	-- Current Summit Display (✅ ADAPTIVE)
	local currentLabel = Instance.new("TextLabel")
	currentLabel.Size = UDim2.new(1, 0, 0.12, 0)
	currentLabel.Position = UDim2.new(0, 0, 0, 0)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.Gotham
	currentLabel.Text = "Current Summit: Loading..."
	currentLabel.TextColor3 = COLORS.TextSecondary
	currentLabel.TextXAlignment = Enum.TextXAlignment.Left
	currentLabel.Parent = contentContainer
	makeTextAdaptive(currentLabel, 13)

	-- Get current summit value
	task.spawn(function()
		local playerStats = targetPlayer:FindFirstChild("PlayerStats")
		if playerStats then
			local summitValue = playerStats:FindFirstChild("Summit")
			if summitValue then
				currentLabel.Text = "Current Summit: " .. tostring(summitValue.Value)
			end
		end
	end)

	-- Input Label (✅ ADAPTIVE)
	local inputLabel = Instance.new("TextLabel")
	inputLabel.Size = UDim2.new(1, 0, 0.12, 0)
	inputLabel.Position = UDim2.new(0, 0, 0.15, 0)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Font = Enum.Font.GothamBold
	inputLabel.Text = "New Summit Value:"
	inputLabel.TextColor3 = COLORS.Text
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.Parent = contentContainer
	makeTextAdaptive(inputLabel, 14)

	-- Input Box (✅ ADAPTIVE)
	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(1, 0, 0.22, 0)
	inputBox.Position = UDim2.new(0, 0, 0.3, 0)
	inputBox.BackgroundColor3 = COLORS.Panel
	inputBox.BorderSizePixel = 0
	inputBox.Font = Enum.Font.Gotham
	inputBox.PlaceholderText = "Enter summit value (e.g. 100)"
	inputBox.Text = ""
	inputBox.TextColor3 = COLORS.Text
	inputBox.ClearTextOnFocus = false
	inputBox.Parent = contentContainer
	makeTextAdaptive(inputBox, 15)

	createCorner(8).Parent = inputBox
	createPadding(12).Parent = inputBox

	-- Set Button (✅ ADAPTIVE)
	local setBtn = createButton("Set Summit", COLORS.Success, Color3.fromRGB(77, 191, 139))
	setBtn.Size = UDim2.new(1, 0, 0.22, 0)
	setBtn.Position = UDim2.new(0, 0, 0.58, 0)
	setBtn.Parent = contentContainer

	setBtn.MouseButton1Click:Connect(function()
		local newValue = tonumber(inputBox.Text)

		if not newValue or newValue < 0 then
			StarterGui:SetCore("SendNotification", {
				Title = "❌ Invalid Input",
				Text = "Please enter a valid number (0 or greater)",
				Duration = 3
			})
			return
		end

		showConfirmation(
			"Modify Summit Data",
			string.format("Set %s's summit to %d?", targetPlayer.Name, newValue),
			function()
				local modifySummitEvent = remoteFolder:FindFirstChild("ModifySummitData")
				if modifySummitEvent then
					modifySummitEvent:FireServer(targetPlayer.UserId, newValue)
					print(string.format("[ADMIN CLIENT] Set %s's summit to %d", targetPlayer.Name, newValue))
				end
				popup:Destroy()
			end
		)
	end)

	return popup
end




local function createPlayerCard(targetPlayer)
	local isLocalPlayer = (targetPlayer == player)

	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0.15, 0)  -- ✅ Scale-based
	card.BackgroundColor3 = isLocalPlayer and COLORS.Accent or COLORS.Panel
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.Parent = playersScroll

	createCorner(8).Parent = card

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0.12, 0, 0.7, 0)
	avatar.Position = UDim2.new(0.03, 0, 0.15, 0)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
	avatar.Parent = card

	createCorner(20).Parent = avatar

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0.18, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = targetPlayer.Name .. (isLocalPlayer and " (You)" or "")
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card
	makeTextAdaptive(nameLabel, 14)

	local displayLabel = Instance.new("TextLabel")
	displayLabel.Size = UDim2.new(0.55, 0, 0.3, 0)
	displayLabel.Position = UDim2.new(0.18, 0, 0.55, 0)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Font = Enum.Font.Gotham
	displayLabel.Text = "@" .. targetPlayer.DisplayName
	displayLabel.TextColor3 = COLORS.TextSecondary
	displayLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayLabel.Parent = card
	makeTextAdaptive(displayLabel, 12)



	-- ✅ TAMBAHKAN: Title Label di sebelah kanan
	local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

	local function updateTitleLabel()
		-- ✅ REQUEST TITLE DARI SERVER via ShopRemotes
		local titleText = "Pengunjung" -- Default
		local titleColor = COLORS.TextSecondary

		local shopRemotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
		if shopRemotes then
			local getTargetTitle = shopRemotes:FindFirstChild("GetTargetTitle")
			if getTargetTitle and getTargetTitle:IsA("RemoteFunction") then
				local success, serverTitle = pcall(function()
					return getTargetTitle:InvokeServer(targetPlayer)
				end)

				if success and serverTitle then
					titleText = serverTitle
					print("📥 [ADMIN CLIENT] Got title for", targetPlayer.Name, ":", titleText) -- DEBUG

					-- Set color based on title
					local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
					if TitleConfig.Titles[titleText] then
						titleColor = TitleConfig.Titles[titleText].Color
					end
				else
					warn("⚠️ [ADMIN CLIENT] Failed to get title for", targetPlayer.Name)
				end
			end
		end

		-- Create/Update title label UI (✅ ADAPTIVE)
		local titleLabel = card:FindFirstChild("TitleLabel")
		if not titleLabel then
			titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Size = UDim2.new(0.2, 0, 0.35, 0)
			titleLabel.Position = UDim2.new(0.78, 0, 0.3, 0)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextXAlignment = Enum.TextXAlignment.Right
			titleLabel.Parent = card
			makeTextAdaptive(titleLabel, 11)
		end

		-- Update text
		if titleText == "Pengunjung" then
			titleLabel.Text = ""
		else
			titleLabel.Text = titleText
			titleLabel.TextColor3 = titleColor
		end
	end

	updateTitleLabel()

	-- Listen for changes
	local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
	if titleRemotes then
		local updateOther = titleRemotes:FindFirstChild("UpdateOtherPlayerTitle")
		if updateOther then
			updateOther.OnClientEvent:Connect(function(changedPlayer, newTitle)
				if changedPlayer == targetPlayer then
					print("🔄 [ADMIN CLIENT] Title changed for", targetPlayer.Name, "to", newTitle) -- DEBUG
					task.wait(0.5) -- Delay biar data tersimpan dulu
					updateTitleLabel()
				end
			end)
		end
	end
	-- Only add hover effect and click functionality for other players
	if not isLocalPlayer then
		card.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
		end)

		card.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
		end)

		card.MouseButton1Click:Connect(function()
			-- Clear previous detail content
			for _, child in ipairs(detailScroll:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end

			-- Player Info Section
			local infoSection = Instance.new("Frame")
			infoSection.Size = UDim2.new(1, 0, 0, 120)
			infoSection.BackgroundColor3 = COLORS.Panel
			infoSection.BorderSizePixel = 0
			infoSection.LayoutOrder = 1
			infoSection.Parent = detailScroll

			createCorner(8).Parent = infoSection

			local detailAvatar = Instance.new("ImageLabel")
			detailAvatar.Size = UDim2.new(0, 80, 0, 80)
			detailAvatar.Position = UDim2.new(0, 20, 0, 20)
			detailAvatar.BackgroundColor3 = COLORS.Button
			detailAvatar.BorderSizePixel = 0
			detailAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
			detailAvatar.Parent = infoSection

			createCorner(40).Parent = detailAvatar

			local detailName = Instance.new("TextLabel")
			detailName.Size = UDim2.new(1, -120, 0, 25)
			detailName.Position = UDim2.new(0, 110, 0, 20)
			detailName.BackgroundTransparency = 1
			detailName.Font = Enum.Font.GothamBold
			detailName.Text = targetPlayer.Name
			detailName.TextColor3 = COLORS.Text
			detailName.TextSize = 18
			detailName.TextXAlignment = Enum.TextXAlignment.Left
			detailName.Parent = infoSection

			local detailDisplay = Instance.new("TextLabel")
			detailDisplay.Size = UDim2.new(1, -120, 0, 20)
			detailDisplay.Position = UDim2.new(0, 110, 0, 48)
			detailDisplay.BackgroundTransparency = 1
			detailDisplay.Font = Enum.Font.Gotham
			detailDisplay.Text = "@" .. targetPlayer.DisplayName
			detailDisplay.TextColor3 = COLORS.TextSecondary
			detailDisplay.TextSize = 14
			detailDisplay.TextXAlignment = Enum.TextXAlignment.Left
			detailDisplay.Parent = infoSection

			local detailUserId = Instance.new("TextLabel")
			detailUserId.Size = UDim2.new(1, -120, 0, 20)
			detailUserId.Position = UDim2.new(0, 110, 0, 70)
			detailUserId.BackgroundTransparency = 1
			detailUserId.Font = Enum.Font.Gotham
			detailUserId.Text = "ID: " .. targetPlayer.UserId
			detailUserId.TextColor3 = COLORS.TextSecondary
			detailUserId.TextSize = 12
			detailUserId.TextXAlignment = Enum.TextXAlignment.Left
			detailUserId.Parent = infoSection

			-- Action Buttons Grid
			local actionsFrame = Instance.new("Frame")
			actionsFrame.Size = UDim2.new(1, 0, 0, 0)
			actionsFrame.BackgroundTransparency = 1
			actionsFrame.LayoutOrder = 2
			actionsFrame.Parent = detailScroll

			local actionsLayout = Instance.new("UIListLayout")
			actionsLayout.Padding = UDim.new(0, 8)
			actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
			actionsLayout.Parent = actionsFrame

			actionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				actionsFrame.Size = UDim2.new(1, 0, 0, actionsLayout.AbsoluteContentSize.Y)
			end)

			-- Kick Button
			local kickBtn = createButton("Kick Player", COLORS.Button, COLORS.ButtonHover)
			kickBtn.LayoutOrder = 1
			kickBtn.Parent = actionsFrame

			kickBtn.MouseButton1Click:Connect(function()
				showConfirmation("Kick Player", "Are you sure you want to kick " .. targetPlayer.Name .. "?", function()
					if targetPlayer then
						kickPlayerEvent:FireServer(targetPlayer.UserId)
					end
				end)
			end)

			-- Ban Button
			local banBtn = createButton("Ban Player", COLORS.Button, COLORS.ButtonHover)
			banBtn.LayoutOrder = 2
			banBtn.Parent = actionsFrame

			banBtn.MouseButton1Click:Connect(function()
				showConfirmation("Ban Player", "Are you sure you want to ban " .. targetPlayer.Name .. "?", function()
					if targetPlayer then
						banPlayerEvent:FireServer(targetPlayer.UserId)
					end
				end)
			end)
			
			-- Teleport Button (NEW)
			local teleportBtn = createButton("Teleport", COLORS.Button, COLORS.ButtonHover)
			teleportBtn.LayoutOrder = 3
			teleportBtn.Parent = actionsFrame
			teleportBtn.MouseButton1Click:Connect(function()
				createTeleportPopup(targetPlayer)
			end)

			-- Modify Player Button (NEW)
			local modifyBtn = createButton("Modify Player", COLORS.Button, COLORS.ButtonHover)
			modifyBtn.LayoutOrder = 4
			modifyBtn.Parent = actionsFrame
			modifyBtn.MouseButton1Click:Connect(function()
				createModifyPlayerPopup(targetPlayer)
			end)



			-- Spectate Button
			local spectateBtn = createButton("Spectate Player", COLORS.Accent, COLORS.AccentHover)
			spectateBtn.LayoutOrder = 5
			spectateBtn.Parent = actionsFrame

			spectateBtn.MouseButton1Click:Connect(function()
				if currentSpectatePlayer then
					-- Stop spectating
					if spectateConnection then
						spectateConnection:Disconnect()
					end

					workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
					workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
					currentSpectatePlayer = nil
					spectateBtn.Text = "Spectate Player"
					spectateBtn.BackgroundColor3 = COLORS.Accent
				else
					-- Start spectating
					if targetPlayer and targetPlayer.Character then
						currentSpectatePlayer = targetPlayer
						local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")

						if targetHumanoid then
							workspace.CurrentCamera.CameraSubject = targetHumanoid
							spectateBtn.Text = "Stop Spectating"
							spectateBtn.BackgroundColor3 = COLORS.Success

							-- Monitor if player leaves or dies
							spectateConnection = targetPlayer.CharacterRemoving:Connect(function()
								if spectateConnection then
									spectateConnection:Disconnect()
								end
								workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
								workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
								currentSpectatePlayer = nil
								spectateBtn.Text = "Spectate Player"
								spectateBtn.BackgroundColor3 = COLORS.Accent
							end)
						end
					end
				end
			end)

			-- Kill Button
			local killBtn = createButton("Kill Player", COLORS.Danger, COLORS.DangerHover)
			killBtn.LayoutOrder = 6
			killBtn.Parent = actionsFrame

			killBtn.MouseButton1Click:Connect(function()
				showConfirmation("Kill Player", "Are you sure you want to kill " .. targetPlayer.Name .. "?", function()
					if targetPlayer then
						killPlayerEvent:FireServer(targetPlayer.UserId)
					end
				end)
			end)
			
			-- Set Title Button
			local setTitleBtn = createButton("Set Title", COLORS.Accent, COLORS.AccentHover)
			setTitleBtn.LayoutOrder = 7
			setTitleBtn.Parent = actionsFrame
			setTitleBtn.MouseButton1Click:Connect(function()
				if targetPlayer then
					showSetTitlePopup(targetPlayer)
				end
			end)
			
			-- ✅ Modify Summit Data Button (BARU)
			local modifySummitBtn = createButton("Modify Summit Data", COLORS.Accent, Color3.fromRGB(128, 141, 255))
			modifySummitBtn.LayoutOrder = 8  -- Setelah Set Title
			modifySummitBtn.Parent = actionsFrame
			modifySummitBtn.MouseButton1Click:Connect(function()
				if targetPlayer then
					showModifySummitPopup(targetPlayer)
				end
			end)


			
			-- Give Items Button (TAMBAHKAN SETELAH setTitleBtn)
			local giveItemsBtn = createButton("Give Items", COLORS.Success, COLORS.Success)
			giveItemsBtn.LayoutOrder = 8
			giveItemsBtn.Parent = actionsFrame

			giveItemsBtn.MouseButton1Click:Connect(function()
				if not targetPlayer then return end

				-- Load ShopConfig
				local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

				-- Create Give Items Popup (✅ ADAPTIVE)
				local giveItemsPopup = Instance.new("Frame")
				giveItemsPopup.Name = "GiveItemsPopup"
				giveItemsPopup.Size = UDim2.new(0.28, 0, 0.55, 0)
				giveItemsPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
				giveItemsPopup.AnchorPoint = Vector2.new(0.5, 0.5)
				giveItemsPopup.BackgroundColor3 = COLORS.Background
				giveItemsPopup.BorderSizePixel = 0
				giveItemsPopup.ZIndex = 30
				giveItemsPopup.Parent = screenGui

				createCorner(12).Parent = giveItemsPopup
				createStroke(COLORS.Border, 2).Parent = giveItemsPopup
				addAspectRatio(giveItemsPopup, 0.65)

				local popupTitle = Instance.new("TextLabel")
				popupTitle.Size = UDim2.new(0.85, 0, 0.08, 0)
				popupTitle.Position = UDim2.new(0.05, 0, 0.03, 0)
				popupTitle.BackgroundTransparency = 1
				popupTitle.Font = Enum.Font.GothamBold
				popupTitle.Text = "Give Items to " .. targetPlayer.Name
				popupTitle.TextColor3 = COLORS.Text
				popupTitle.TextXAlignment = Enum.TextXAlignment.Left
				popupTitle.Parent = giveItemsPopup
				makeTextAdaptive(popupTitle, 16)

				local closePopupBtn = Instance.new("TextButton")
				closePopupBtn.Size = UDim2.new(0.08, 0, 0.06, 0)
				closePopupBtn.Position = UDim2.new(0.9, 0, 0.03, 0)
				closePopupBtn.BackgroundColor3 = COLORS.Button
				closePopupBtn.BorderSizePixel = 0
				closePopupBtn.Font = Enum.Font.GothamBold
				closePopupBtn.Text = "×"
				closePopupBtn.TextColor3 = COLORS.Text
				closePopupBtn.Parent = giveItemsPopup
				makeTextAdaptive(closePopupBtn, 20)

				createCorner(6).Parent = closePopupBtn

				closePopupBtn.MouseButton1Click:Connect(function()
					giveItemsPopup:Destroy()
				end)

				-- Tab Frame (✅ ADAPTIVE)
				local tabFrame = Instance.new("Frame")
				tabFrame.Size = UDim2.new(0.9, 0, 0.07, 0)
				tabFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
				tabFrame.BackgroundTransparency = 1
				tabFrame.Parent = giveItemsPopup

				local tabLayout = Instance.new("UIListLayout")
				tabLayout.FillDirection = Enum.FillDirection.Horizontal
				tabLayout.Padding = UDim.new(0.02, 0)
				tabLayout.Parent = tabFrame

				local auraTab = Instance.new("TextButton")
				auraTab.Size = UDim2.new(0.3, 0, 1, 0)
				auraTab.BackgroundColor3 = COLORS.Accent
				auraTab.BorderSizePixel = 0
				auraTab.Font = Enum.Font.GothamBold
				auraTab.Text = "Auras"
				auraTab.TextColor3 = COLORS.Text
				auraTab.AutoButtonColor = false
				auraTab.Parent = tabFrame
				makeTextAdaptive(auraTab, 13)

				createCorner(6).Parent = auraTab

				local toolTab = Instance.new("TextButton")
				toolTab.Size = UDim2.new(0.3, 0, 1, 0)
				toolTab.BackgroundColor3 = COLORS.Button
				toolTab.BorderSizePixel = 0
				toolTab.Font = Enum.Font.GothamBold
				toolTab.Text = "Tools"
				toolTab.TextColor3 = COLORS.Text
				toolTab.AutoButtonColor = false
				toolTab.Parent = tabFrame
				makeTextAdaptive(toolTab, 13)
				
				local moneyTab = Instance.new("TextButton")
				moneyTab.Size = UDim2.new(0.3, 0, 1, 0)
				moneyTab.BackgroundColor3 = COLORS.Button
				moneyTab.BorderSizePixel = 0
				moneyTab.Font = Enum.Font.GothamBold
				moneyTab.Text = "Money"
				moneyTab.TextColor3 = COLORS.Text
				moneyTab.AutoButtonColor = false
				moneyTab.Parent = tabFrame
				makeTextAdaptive(moneyTab, 13)

				createCorner(6).Parent = moneyTab

				createCorner(6).Parent = toolTab

				-- Content Frame (✅ ADAPTIVE)
				local contentFrame = Instance.new("Frame")
				contentFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
				contentFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
				contentFrame.BackgroundTransparency = 1
				contentFrame.Parent = giveItemsPopup

				-- Aura Content
				local auraContent = Instance.new("ScrollingFrame")
				auraContent.Size = UDim2.new(1, 0, 1, 0)
				auraContent.BackgroundTransparency = 1
				auraContent.BorderSizePixel = 0
				auraContent.ScrollBarThickness = 4
				auraContent.ScrollBarImageColor3 = COLORS.Border
				auraContent.CanvasSize = UDim2.new(0, 0, 0, 0)
				auraContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
				auraContent.Visible = true
				auraContent.Parent = contentFrame

				local auraLayout = Instance.new("UIListLayout")
				auraLayout.Padding = UDim.new(0.015, 0)
				auraLayout.SortOrder = Enum.SortOrder.LayoutOrder
				auraLayout.Parent = auraContent

				-- Tool Content
				local toolContent = Instance.new("ScrollingFrame")
				toolContent.Size = UDim2.new(1, 0, 1, 0)
				toolContent.BackgroundTransparency = 1
				toolContent.BorderSizePixel = 0
				toolContent.ScrollBarThickness = 4
				toolContent.ScrollBarImageColor3 = COLORS.Border
				toolContent.CanvasSize = UDim2.new(0, 0, 0, 0)
				toolContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
				toolContent.Visible = false
				toolContent.Parent = contentFrame

				local toolLayout = Instance.new("UIListLayout")
				toolLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based
				toolLayout.SortOrder = Enum.SortOrder.LayoutOrder
				toolLayout.Parent = toolContent
				
				-- ✅ TAMBAHKAN MONEY CONTENT
				local moneyContent = Instance.new("ScrollingFrame")
				moneyContent.Size = UDim2.new(1, 0, 1, 0)
				moneyContent.BackgroundTransparency = 1
				moneyContent.BorderSizePixel = 0
				moneyContent.ScrollBarThickness = 4
				moneyContent.ScrollBarImageColor3 = COLORS.Border
				moneyContent.CanvasSize = UDim2.new(0, 0, 0, 0)
				moneyContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
				moneyContent.Visible = false
				moneyContent.Parent = contentFrame

				local moneyLayout = Instance.new("UIListLayout")
				moneyLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based
				moneyLayout.SortOrder = Enum.SortOrder.LayoutOrder
				moneyLayout.Parent = moneyContent

				-- Selected Items Storage
				local selectedAuras = {}
				local selectedTools = {}

				-- Create Aura Checkboxes (✅ ADAPTIVE)
				for _, aura in ipairs(ShopConfig.Auras) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0.12, 0)  -- ✅ Scale-based
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = auraContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0.1, 0, 0.75, 0)
					checkbox.Position = UDim2.new(0.02, 0, 0.125, 0)
					checkbox.BackgroundColor3 = COLORS.Button
					checkbox.BorderSizePixel = 0
					checkbox.Text = ""
					checkbox.AutoButtonColor = false
					checkbox.Parent = frame

					createCorner(6).Parent = checkbox

					local checkmark = Instance.new("TextLabel")
					checkmark.Size = UDim2.new(1, 0, 1, 0)
					checkmark.BackgroundTransparency = 1
					checkmark.Font = Enum.Font.GothamBold
					checkmark.Text = "✓"
					checkmark.TextColor3 = COLORS.Success
					checkmark.Visible = false
					checkmark.Parent = checkbox
					makeTextAdaptive(checkmark, 18)

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(0.8, 0, 1, 0)
					label.Position = UDim2.new(0.15, 0, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = aura.Title
					label.TextColor3 = COLORS.Text
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame
					makeTextAdaptive(label, 13)

					checkbox.MouseButton1Click:Connect(function()
						local isSelected = table.find(selectedAuras, aura.AuraId)
						if isSelected then
							table.remove(selectedAuras, isSelected)
							checkmark.Visible = false
							checkbox.BackgroundColor3 = COLORS.Button
						else
							table.insert(selectedAuras, aura.AuraId)
							checkmark.Visible = true
							checkbox.BackgroundColor3 = COLORS.Success
						end
					end)
				end

				-- Create Tool Checkboxes (✅ ADAPTIVE)
				for _, tool in ipairs(ShopConfig.Tools) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0.12, 0)  -- ✅ Scale-based
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = toolContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0.1, 0, 0.75, 0)
					checkbox.Position = UDim2.new(0.02, 0, 0.125, 0)
					checkbox.BackgroundColor3 = COLORS.Button
					checkbox.BorderSizePixel = 0
					checkbox.Text = ""
					checkbox.AutoButtonColor = false
					checkbox.Parent = frame

					createCorner(6).Parent = checkbox

					local checkmark = Instance.new("TextLabel")
					checkmark.Size = UDim2.new(1, 0, 1, 0)
					checkmark.BackgroundTransparency = 1
					checkmark.Font = Enum.Font.GothamBold
					checkmark.Text = "✓"
					checkmark.TextColor3 = COLORS.Success
					checkmark.Visible = false
					checkmark.Parent = checkbox
					makeTextAdaptive(checkmark, 18)

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(0.8, 0, 1, 0)
					label.Position = UDim2.new(0.15, 0, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = tool.Title
					label.TextColor3 = COLORS.Text
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame
					makeTextAdaptive(label, 13)

					checkbox.MouseButton1Click:Connect(function()
						local isSelected = table.find(selectedTools, tool.ToolId)
						if isSelected then
							table.remove(selectedTools, isSelected)
							checkmark.Visible = false
							checkbox.BackgroundColor3 = COLORS.Button
						else
							table.insert(selectedTools, tool.ToolId)
							checkmark.Visible = true
							checkbox.BackgroundColor3 = COLORS.Success
						end
					end)
				end
				
				-- ✅ TAMBAHKAN: Create Money Options (✅ ADAPTIVE)
				for _, pack in ipairs(ShopConfig.MoneyPacks) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0.15, 0)  -- ✅ Scale-based
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = moneyContent

					createCorner(6).Parent = frame

					local titleLabel = Instance.new("TextLabel")
					titleLabel.Size = UDim2.new(0.5, 0, 0.45, 0)
					titleLabel.Position = UDim2.new(0.03, 0, 0.1, 0)
					titleLabel.BackgroundTransparency = 1
					titleLabel.Font = Enum.Font.GothamBold
					titleLabel.Text = pack.Title
					titleLabel.TextColor3 = COLORS.Text
					titleLabel.TextXAlignment = Enum.TextXAlignment.Left
					titleLabel.Parent = frame
					makeTextAdaptive(titleLabel, 13)

					local amountLabel = Instance.new("TextLabel")
					amountLabel.Size = UDim2.new(0.5, 0, 0.4, 0)
					amountLabel.Position = UDim2.new(0.03, 0, 0.5, 0)
					amountLabel.BackgroundTransparency = 1
					amountLabel.Font = Enum.Font.Gotham
					amountLabel.Text = "$" .. tostring(pack.MoneyReward)
					amountLabel.TextColor3 = COLORS.Success
					amountLabel.TextXAlignment = Enum.TextXAlignment.Left
					amountLabel.Parent = frame
					makeTextAdaptive(amountLabel, 12)

					local selectBtn = Instance.new("TextButton")
					selectBtn.Size = UDim2.new(0.25, 0, 0.7, 0)
					selectBtn.Position = UDim2.new(0.72, 0, 0.5, 0)
					selectBtn.AnchorPoint = Vector2.new(0, 0.5)
					selectBtn.BackgroundColor3 = COLORS.Accent
					selectBtn.BorderSizePixel = 0
					selectBtn.Font = Enum.Font.GothamBold
					selectBtn.Text = "Select"
					selectBtn.TextColor3 = COLORS.Text
					selectBtn.AutoButtonColor = false
					selectBtn.Parent = frame
					makeTextAdaptive(selectBtn, 12)

					createCorner(6).Parent = selectBtn

					selectBtn.MouseButton1Click:Connect(function()
						selectedMoneyAmount = pack.MoneyReward

						-- Reset all buttons
						for _, child in ipairs(moneyContent:GetChildren()) do
							if child:IsA("Frame") then
								local btn = child:FindFirstChildWhichIsA("TextButton")
								if btn then
									btn.BackgroundColor3 = COLORS.Accent
									btn.Text = "Select"
								end
							end
						end

						-- Highlight selected
						selectBtn.BackgroundColor3 = COLORS.Success
						selectBtn.Text = "Selected"
					end)
				end

				-- Tab Switching
				auraTab.MouseButton1Click:Connect(function()
					auraTab.BackgroundColor3 = COLORS.Accent
					toolTab.BackgroundColor3 = COLORS.Button
					moneyTab.BackgroundColor3 = COLORS.Button
					auraContent.Visible = true
					toolContent.Visible = false
					moneyContent.Visible = false
				end)

				toolTab.MouseButton1Click:Connect(function()
					toolTab.BackgroundColor3 = COLORS.Accent
					auraTab.BackgroundColor3 = COLORS.Button
					moneyTab.BackgroundColor3 = COLORS.Button
					toolContent.Visible = true
					auraContent.Visible = false
					moneyContent.Visible = false
				end)
				
				moneyTab.MouseButton1Click:Connect(function()
					moneyTab.BackgroundColor3 = COLORS.Accent
					auraTab.BackgroundColor3 = COLORS.Button
					toolTab.BackgroundColor3 = COLORS.Button
					moneyContent.Visible = true
					auraContent.Visible = false
					toolContent.Visible = false
				end)
				

				-- Give Button (✅ ADAPTIVE)
				local giveBtn = createButton("Give Selected Items", COLORS.Success, COLORS.Success)
				giveBtn.Size = UDim2.new(0.9, 0, 0.1, 0)
				giveBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
				giveBtn.Parent = giveItemsPopup

				giveBtn.MouseButton1Click:Connect(function()
					if #selectedAuras > 0 or #selectedTools > 0 or selectedMoneyAmount > 0 then
						local giveItemsEvent = remoteFolder:FindFirstChild("GiveItems")
						if giveItemsEvent then
							giveItemsEvent:FireServer(targetPlayer.UserId, selectedAuras, selectedTools, selectedMoneyAmount)
							showNotification("Items given to " .. targetPlayer.Name, 3, COLORS.Success)
						end
					end
					giveItemsPopup:Destroy()
				end)
				
				-- ✅ TAMBAHKAN: Make popup draggable
				local isDragging = false
				local dragStart = nil
				local startPos = nil

				popupTitle.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						isDragging = true
						dragStart = input.Position
						startPos = giveItemsPopup.Position

						input.Changed:Connect(function()
							if input.UserInputState == Enum.UserInputState.End then
								isDragging = false
							end
						end)
					end
				end)

				popupTitle.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement then
						if isDragging then
							local delta = input.Position - dragStart
							giveItemsPopup.Position = UDim2.new(
								startPos.X.Scale + deltaScaleX,
								0,  -- ✅ Offset = 0
								startPos.Y.Scale + deltaScaleY,
								0   -- ✅ Offset = 0
							)
						end
					end
				end)		
			end)

			-- Show panel with animation (✅ ADAPTIVE)
			playerDetailPanel.Size = UDim2.new(0, 0, 0, 0)
			playerDetailPanel.Visible = true
			tweenSize(playerDetailPanel, UDim2.new(0.7, 0, 0.9, 0), 0.3)

		end)
	else
		-- For local player, show a simple message when clicked
		card.MouseButton1Click:Connect(function()
			showNotification("This is you! You cannot perform actions on yourself.", 3, COLORS.TextSecondary)
		end)
	end

	return card
end




-- Update player list
local function updatePlayerList()
	for _, card in ipairs(playersScroll:GetChildren()) do
		if card:IsA("TextButton") then
			card:Destroy()
		end
	end

	-- Add all players including the local player (admin)
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		createPlayerCard(targetPlayer)
	end
end

Players.PlayerAdded:Connect(function()
	task.wait(0.5)
	updatePlayerList()
end)

Players.PlayerRemoving:Connect(function()
	task.wait(0.5)
	updatePlayerList()
end)

-- Initial player list
updatePlayerList()

-- Make panels draggable
makeDraggable(mainPanel, header)
makeDraggable(playerDetailPanel, detailHeader)

-- Set default tab
notifTabBtn.BackgroundColor3 = COLORS.Accent
notifTabBtn.TextColor3 = COLORS.Text
notifTab.Visible = true
currentTab = notifTab
-- ✅✅✅ EVENT MANAGER TAB (FULLY RESPONSIVE)
local eventsTab, eventsTabBtn = createTab("Events", 3)

local eventsScroll = Instance.new("ScrollingFrame")
eventsScroll.Size = UDim2.new(1, 0, 1, 0)
eventsScroll.BackgroundTransparency = 1
eventsScroll.BorderSizePixel = 0
eventsScroll.ScrollBarThickness = 4
eventsScroll.ScrollBarImageColor3 = COLORS.Border
eventsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
eventsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
eventsScroll.Parent = eventsTab

local eventsLayout = Instance.new("UIListLayout")
eventsLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based padding
eventsLayout.SortOrder = Enum.SortOrder.LayoutOrder
eventsLayout.Parent = eventsScroll

-- Title (✅ ADAPTIVE)
local eventsTitle = Instance.new("TextLabel")
eventsTitle.Size = UDim2.new(1, 0, 0.06, 0)
eventsTitle.BackgroundTransparency = 1
eventsTitle.Font = Enum.Font.GothamBold
eventsTitle.Text = "🎉 Global Event Manager"
eventsTitle.TextColor3 = COLORS.Text
eventsTitle.TextXAlignment = Enum.TextXAlignment.Left
eventsTitle.LayoutOrder = 1
eventsTitle.Parent = eventsScroll
makeTextAdaptive(eventsTitle, 18)

local eventsDesc = Instance.new("TextLabel")
eventsDesc.Size = UDim2.new(1, 0, 0.08, 0)
eventsDesc.BackgroundTransparency = 1
eventsDesc.Font = Enum.Font.Gotham
eventsDesc.Text = "Activate events to boost summit rewards across ALL servers"
eventsDesc.TextColor3 = COLORS.TextSecondary
eventsDesc.TextWrapped = true
eventsDesc.TextXAlignment = Enum.TextXAlignment.Left
eventsDesc.LayoutOrder = 2
eventsDesc.Parent = eventsScroll
makeTextAdaptive(eventsDesc, 13)

-- Load EventConfig
local EventConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EventConfig"))

-- Get active event from server
local eventRemotes = ReplicatedStorage:WaitForChild("EventRemotes")
local getActiveEventFunc = eventRemotes:WaitForChild("GetActiveEvent")
local setEventRemote = eventRemotes:WaitForChild("SetEvent")
local eventChangedRemote = eventRemotes:WaitForChild("EventChanged")

local currentActiveEventId = nil

-- Function to request current active event
task.spawn(function()
	local success, activeEvent = pcall(function()
		return getActiveEventFunc:InvokeServer()
	end)

	if success and activeEvent then
		currentActiveEventId = activeEvent.Id
		print("[ADMIN CLIENT] Current active event:", activeEvent.Name)
	end
end)

-- ✅ FULLY ADAPTIVE EVENT CARDS
for i, event in ipairs(EventConfig.AvailableEvents) do
	local eventCard = Instance.new("Frame")
	eventCard.Size = UDim2.new(1, 0, 0.18, 0)  -- ✅ Scale-based
	eventCard.BackgroundColor3 = COLORS.Panel
	eventCard.BorderSizePixel = 0
	eventCard.LayoutOrder = 2 + i
	eventCard.Parent = eventsScroll

	createCorner(8).Parent = eventCard

	-- ✅ Icon (FULLY SCALE)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.1, 0, 0.5, 0)
	iconLabel.Position = UDim2.new(0.02, 0, 0.5, 0)
	iconLabel.AnchorPoint = Vector2.new(0, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = event.Icon
	iconLabel.Parent = eventCard
	makeTextAdaptive(iconLabel, 32)

	-- ✅ Event Name (FULLY SCALE)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
	nameLabel.Position = UDim2.new(0.13, 0, 0.1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = event.Name
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = eventCard
	makeTextAdaptive(nameLabel, 16)

	-- ✅ Event Description (FULLY SCALE)
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
	descLabel.Position = UDim2.new(0.13, 0, 0.38, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = event.Description
	descLabel.TextColor3 = COLORS.TextSecondary
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = eventCard
	makeTextAdaptive(descLabel, 12)

	-- ✅ Multiplier Badge (FULLY SCALE)
	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(0.12, 0, 0.25, 0)
	badgeLabel.Position = UDim2.new(0.13, 0, 0.68, 0)
	badgeLabel.BackgroundColor3 = event.Color
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.Text = "x" .. event.Multiplier
	badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeLabel.Parent = eventCard
	makeTextAdaptive(badgeLabel, 14)

	createCorner(6).Parent = badgeLabel

	-- ✅ Toggle Button (FULLY SCALE)
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0.28, 0, 0.42, 0)
	toggleBtn.Position = UDim2.new(0.7, 0, 0.29, 0)
	toggleBtn.BackgroundColor3 = COLORS.Button
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Text = "Activate"
	toggleBtn.TextColor3 = COLORS.Text
	toggleBtn.AutoButtonColor = false
	toggleBtn.Parent = eventCard
	makeTextAdaptive(toggleBtn, 14)

	createCorner(8).Parent = toggleBtn

	-- Update button state based on active event
	local function updateButtonState()
		if currentActiveEventId == event.Id then
			toggleBtn.BackgroundColor3 = COLORS.Success
			toggleBtn.Text = "Active ✓"
		else
			toggleBtn.BackgroundColor3 = COLORS.Button
			toggleBtn.Text = "Activate"
		end
	end

	updateButtonState()

	-- Toggle Button Click
	toggleBtn.MouseButton1Click:Connect(function()
		if currentActiveEventId == event.Id then
			-- Deactivate current event
			showConfirmation(
				"Deactivate Event?",
				"Deactivate " .. event.Name .. "?\nSummit rewards will return to normal.",
				function()
					setEventRemote:FireServer("deactivate")
					currentActiveEventId = nil

					-- Update all buttons
					for _, card in pairs(eventsScroll:GetChildren()) do
						if card:IsA("Frame") and card ~= eventsTitle and card ~= eventsDesc then
							local btn = card:FindFirstChildWhichIsA("TextButton")
							if btn then
								btn.BackgroundColor3 = COLORS.Button
								btn.Text = "Activate"
							end
						end
					end
				end
			)
		else
			-- Activate this event
			showConfirmation(
				"Activate Event?",
				string.format("Activate %s?\nAll players on ALL servers will get x%d Summit rewards!", event.Name, event.Multiplier),
				function()
					setEventRemote:FireServer("activate", event.Id)
					currentActiveEventId = event.Id

					-- Update all buttons
					for _, card in pairs(eventsScroll:GetChildren()) do
						if card:IsA("Frame") and card ~= eventsTitle and card ~= eventsDesc then
							local btn = card:FindFirstChildWhichIsA("TextButton")
							if btn then
								btn.BackgroundColor3 = COLORS.Button
								btn.Text = "Activate"
							end
						end
					end

					updateButtonState()
				end
			)
		end
	end)

	-- Hover effects
	toggleBtn.MouseEnter:Connect(function()
		if currentActiveEventId ~= event.Id then
			toggleBtn.BackgroundColor3 = COLORS.ButtonHover
		end
	end)

	toggleBtn.MouseLeave:Connect(function()
		updateButtonState()
	end)
end

-- Listen for event changes from server
eventChangedRemote.OnClientEvent:Connect(function(newActiveEvent)
	if newActiveEvent then
		currentActiveEventId = newActiveEvent.Id
		print("[ADMIN CLIENT] Event changed to:", newActiveEvent.Name)
	else
		currentActiveEventId = nil
		print("[ADMIN CLIENT] Event deactivated")
	end

	-- Update all buttons
	for _, card in pairs(eventsScroll:GetChildren()) do
		if card:IsA("Frame") then
			local toggleBtn = card:FindFirstChildWhichIsA("TextButton")
			if toggleBtn then
				-- Check if this card matches active event
				for _, ev in ipairs(EventConfig.AvailableEvents) do
					local nameLabel = card:FindFirstChild("TextLabel")
					if nameLabel and nameLabel.Text == ev.Name then
						if currentActiveEventId == ev.Id then
							toggleBtn.BackgroundColor3 = COLORS.Success
							toggleBtn.Text = "Active ✓"
						else
							toggleBtn.BackgroundColor3 = COLORS.Button
							toggleBtn.Text = "Activate"
						end
						break
					end
				end
			end
		end
	end
end)

-- ✅✅✅ AKHIR EVENT MANAGER TAB



-- Leaderboard Tab (✅ ADAPTIVE)
local leaderboardTab, leaderboardTabBtn = createTab("Leaderboard", 4)

local leaderboardScroll = Instance.new("ScrollingFrame")
leaderboardScroll.Size = UDim2.new(1, 0, 1, 0)
leaderboardScroll.BackgroundTransparency = 1
leaderboardScroll.BorderSizePixel = 0
leaderboardScroll.ScrollBarThickness = 4
leaderboardScroll.ScrollBarImageColor3 = COLORS.Border
leaderboardScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
leaderboardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
leaderboardScroll.Parent = leaderboardTab

local leaderboardLayout = Instance.new("UIListLayout")
leaderboardLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based padding
leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
leaderboardLayout.Parent = leaderboardScroll

-- Search Input (✅ ADAPTIVE)
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0.12, 0)
searchFrame.BackgroundTransparency = 1
searchFrame.LayoutOrder = 1
searchFrame.Parent = leaderboardScroll

local searchLabel = Instance.new("TextLabel")
searchLabel.Size = UDim2.new(1, 0, 0.35, 0)
searchLabel.BackgroundTransparency = 1
searchLabel.Font = Enum.Font.GothamBold
searchLabel.Text = "Search Player(s)"
searchLabel.TextColor3 = COLORS.Text
searchLabel.TextXAlignment = Enum.TextXAlignment.Left
searchLabel.Parent = searchFrame
makeTextAdaptive(searchLabel, 14)

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.82, 0, 0.55, 0)
searchBox.Position = UDim2.new(0, 0, 0.4, 0)
searchBox.BackgroundColor3 = COLORS.Panel
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Enter username(s), separate with comma (max 5)"
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame
makeTextAdaptive(searchBox, 13)

createCorner(6).Parent = searchBox
createPadding(10).Parent = searchBox

local searchButton = Instance.new("TextButton")
searchButton.Size = UDim2.new(0.15, 0, 0.55, 0)
searchButton.Position = UDim2.new(0.84, 0, 0.4, 0)
searchButton.BackgroundColor3 = COLORS.Accent
searchButton.BorderSizePixel = 0
searchButton.Font = Enum.Font.GothamBold
searchButton.Text = "🔍"
searchButton.TextColor3 = COLORS.Text
searchButton.AutoButtonColor = false
searchButton.Parent = searchFrame
makeTextAdaptive(searchButton, 18)

createCorner(6).Parent = searchButton

-- Search Results Container
local resultsContainer = Instance.new("Frame")
resultsContainer.Size = UDim2.new(1, 0, 0, 0)
resultsContainer.BackgroundTransparency = 1
resultsContainer.LayoutOrder = 2
resultsContainer.Parent = leaderboardScroll

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.Padding = UDim.new(0.015, 0)  -- ✅ Scale-based
resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultsLayout.Parent = resultsContainer

resultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	resultsContainer.Size = UDim2.new(1, 0, 0, resultsLayout.AbsoluteContentSize.Y)
end)

-- Delete All Button (Hidden by default) (✅ ADAPTIVE)
local deleteAllFrame = Instance.new("Frame")
deleteAllFrame.Size = UDim2.new(1, 0, 0.1, 0)
deleteAllFrame.BackgroundTransparency = 1
deleteAllFrame.LayoutOrder = 3
deleteAllFrame.Visible = false
deleteAllFrame.Parent = leaderboardScroll

local deleteAllButton = createButton("🗑️ Delete All Selected Players", COLORS.Danger, COLORS.DangerHover)
deleteAllButton.Size = UDim2.new(1, 0, 1, 0)
deleteAllButton.Parent = deleteAllFrame

-- Function to create player result card (✅ ADAPTIVE)
local searchResults = {} -- Store search results

local function createLeaderboardCard(data)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0.35, 0)  -- ✅ Scale-based
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.Parent = resultsContainer

	createCorner(8).Parent = card

	-- Avatar (✅ ADAPTIVE)
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0.15, 0, 0.35, 0)
	avatar.Position = UDim2.new(0.02, 0, 0.05, 0)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. data.UserId .. "&w=150&h=150"
	avatar.Parent = card

	createCorner(30).Parent = avatar

	-- Username (✅ ADAPTIVE)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.65, 0, 0.15, 0)
	nameLabel.Position = UDim2.new(0.2, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = data.Username
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card
	makeTextAdaptive(nameLabel, 16)

	-- User ID (✅ ADAPTIVE)
	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(0.65, 0, 0.12, 0)
	idLabel.Position = UDim2.new(0.2, 0, 0.2, 0)
	idLabel.BackgroundTransparency = 1
	idLabel.Font = Enum.Font.Gotham
	idLabel.Text = "ID: " .. data.UserId
	idLabel.TextColor3 = COLORS.TextSecondary
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Parent = card
	makeTextAdaptive(idLabel, 12)

	-- Stats Display (✅ ADAPTIVE)
	local stats = {
		{icon = "🏔️", label = "Summit", value = tostring(data.Summit)},
		{icon = "⏱️", label = "Speedrun", value = data.Speedrun},
		{icon = "⌚", label = "Playtime", value = string.format("%dh %dm", math.floor(data.Playtime / 3600), math.floor((data.Playtime % 3600) / 60))},
		{icon = "💎", label = "Donate", value = "R$" .. tostring(data.Donate)}
	}

	for i, stat in ipairs(stats) do
		local statFrame = Instance.new("Frame")
		statFrame.Size = UDim2.new(0.48, 0, 0.12, 0)
		local xPos = (i - 1) % 2 == 0 and 0.02 or 0.5
		local yPos = 0.35 + math.floor((i - 1) / 2) * 0.14
		statFrame.Position = UDim2.new(xPos, 0, yPos, 0)
		statFrame.BackgroundTransparency = 1
		statFrame.Parent = card

		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(1, 0, 1, 0)
		statLabel.BackgroundTransparency = 1
		statLabel.Font = Enum.Font.Gotham
		statLabel.Text = stat.icon .. " " .. stat.label .. ": " .. stat.value
		statLabel.TextColor3 = COLORS.TextSecondary
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = statFrame
		makeTextAdaptive(statLabel, 12)
	end

	-- Delete Button (✅ ADAPTIVE)
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0.96, 0, 0.18, 0)
	deleteBtn.Position = UDim2.new(0.02, 0, 0.78, 0)
	deleteBtn.BackgroundColor3 = COLORS.Danger
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.Text = "🗑️ Delete Data"
	deleteBtn.TextColor3 = COLORS.Text
	deleteBtn.AutoButtonColor = false
	deleteBtn.Parent = card
	makeTextAdaptive(deleteBtn, 13)

	createCorner(6).Parent = deleteBtn

	deleteBtn.MouseEnter:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.DangerHover}):Play()
	end)

	deleteBtn.MouseLeave:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Danger}):Play()
	end)

	deleteBtn.MouseButton1Click:Connect(function()
		-- Show delete options popup (✅ ADAPTIVE)
		local deletePopup = Instance.new("Frame")
		deletePopup.Size = UDim2.new(0.22, 0, 0.35, 0)
		deletePopup.Position = UDim2.new(0.5, 0, 0.5, 0)
		deletePopup.AnchorPoint = Vector2.new(0.5, 0.5)
		deletePopup.BackgroundColor3 = COLORS.Background
		deletePopup.BorderSizePixel = 0
		deletePopup.ZIndex = 200
		deletePopup.Parent = screenGui

		createCorner(12).Parent = deletePopup
		createStroke(COLORS.Border, 2).Parent = deletePopup
		addAspectRatio(deletePopup, 1.15)

		-- Header (✅ ADAPTIVE)
		local popupHeader = Instance.new("Frame")
		popupHeader.Size = UDim2.new(1, 0, 0.15, 0)
		popupHeader.BackgroundColor3 = COLORS.Header
		popupHeader.BorderSizePixel = 0
		popupHeader.Parent = deletePopup

		createCorner(12).Parent = popupHeader

		local headerBottom = Instance.new("Frame")
		headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
		headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
		headerBottom.BackgroundColor3 = COLORS.Header
		headerBottom.BorderSizePixel = 0
		headerBottom.Parent = popupHeader

		local popupTitle = Instance.new("TextLabel")
		popupTitle.Size = UDim2.new(0.8, 0, 1, 0)
		popupTitle.Position = UDim2.new(0.05, 0, 0, 0)
		popupTitle.BackgroundTransparency = 1
		popupTitle.Font = Enum.Font.GothamBold
		popupTitle.Text = "Delete " .. data.Username .. "'s Data"
		popupTitle.TextColor3 = COLORS.Text
		popupTitle.TextXAlignment = Enum.TextXAlignment.Left
		popupTitle.Parent = popupHeader
		makeTextAdaptive(popupTitle, 14)

		local closePopupBtn = Instance.new("TextButton")
		closePopupBtn.Size = UDim2.new(0.1, 0, 0.6, 0)
		closePopupBtn.Position = UDim2.new(0.93, 0, 0.5, 0)
		closePopupBtn.AnchorPoint = Vector2.new(1, 0.5)
		closePopupBtn.BackgroundColor3 = COLORS.Button
		closePopupBtn.BorderSizePixel = 0
		closePopupBtn.Text = "✕"
		closePopupBtn.Font = Enum.Font.GothamBold
		closePopupBtn.TextColor3 = COLORS.Text
		closePopupBtn.Parent = popupHeader
		makeTextAdaptive(closePopupBtn, 16)

		createCorner(6).Parent = closePopupBtn

		closePopupBtn.MouseButton1Click:Connect(function()
			deletePopup:Destroy()
		end)

		-- Delete options container (✅ ADAPTIVE)
		local optionsContainer = Instance.new("Frame")
		optionsContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
		optionsContainer.Position = UDim2.new(0.05, 0, 0.18, 0)
		optionsContainer.BackgroundTransparency = 1
		optionsContainer.Parent = deletePopup

		local optionsLayout = Instance.new("UIListLayout")
		optionsLayout.Padding = UDim.new(0.02, 0)
		optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		optionsLayout.Parent = optionsContainer

		local deleteOptions = {
			{text = "Delete Summit Data", type = "summit"},
			{text = "Delete Speedrun Data", type = "speedrun"},
			{text = "Delete Playtime Data", type = "playtime"},
			{text = "Delete Donation Data", type = "donate"},
			{text = "DELETE ALL DATA", type = "all", isAll = true}
		}

		for idx, option in ipairs(deleteOptions) do
			local optionBtn = Instance.new("TextButton")
			optionBtn.Size = UDim2.new(1, 0, 0.16, 0)
			optionBtn.BackgroundColor3 = option.isAll and COLORS.Danger or COLORS.Button
			optionBtn.BorderSizePixel = 0
			optionBtn.Font = Enum.Font.GothamBold
			optionBtn.Text = option.text
			optionBtn.TextColor3 = COLORS.Text
			optionBtn.AutoButtonColor = false
			optionBtn.LayoutOrder = idx
			optionBtn.Parent = optionsContainer
			makeTextAdaptive(optionBtn, 12)

			createCorner(6).Parent = optionBtn

			optionBtn.MouseButton1Click:Connect(function()
				-- Langsung pakai confirmDialog yang sudah ada
				confirmTitle.Text = "Confirm Delete"
				confirmMessage.Text = string.format("Are you sure you want to delete %s data from %s?", 
					option.type == "all" and "ALL" or option.type, 
					data.Username
				)
				currentConfirmCallback = function()
					local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
					if deleteLeaderboardEvent then
						deleteLeaderboardEvent:FireServer(data.UserId, option.type)
					end

					deletePopup:Destroy()
					card:Destroy()

					local hasResults = false
					for _, child in pairs(resultsContainer:GetChildren()) do
						if child:IsA("Frame") then
							hasResults = true
							break
						end
					end

					if not hasResults then
						deleteAllFrame.Visible = false
					end
				end

				confirmDialog.Size = UDim2.new(0, 0, 0, 0)
				confirmDialog.Visible = true
				tweenSize(confirmDialog, UDim2.new(0, 380, 0, 200), 0.3)
			end)


			yPos = yPos + 43
		end
	end)

	return card
end

-- Search Button Handler
searchButton.MouseButton1Click:Connect(function()
	if searchBox.Text == "" then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "Please enter at least one username!",
			Duration = 3,
		})
		return
	end

	-- Clear previous results
	for _, child in pairs(resultsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	searchResults = {}

	-- Parse usernames (split by comma)
	local usernames = {}
	for username in string.gmatch(searchBox.Text, "[^,]+") do
		local trimmed = string.match(username, "^%s*(.-)%s*$") -- Trim whitespace
		if trimmed ~= "" then
			table.insert(usernames, trimmed)
		end
	end

	if #usernames == 0 then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "No valid usernames entered!",
			Duration = 3,
		})
		return
	end

	if #usernames > 5 then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "Maximum 5 players at once!",
			Duration = 3,
		})
		return
	end

	-- Search each player
	local searchLeaderboardFunc = remoteFolder:FindFirstChild("SearchLeaderboard")
	if not searchLeaderboardFunc then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Error",
			Text = "Search function not available!",
			Duration = 3,
		})
		return
	end

	local foundCount = 0

	for _, username in ipairs(usernames) do
		local success, result = pcall(function()
			return searchLeaderboardFunc:InvokeServer(username)
		end)

		if success and result and result.success then
			createLeaderboardCard(result.data)
			table.insert(searchResults, result.data)
			foundCount = foundCount + 1
		else
			game.StarterGui:SetCore("SendNotification", {
				Title = "Player Not Found",
				Text = string.format("'%s' not found in database!", username),
				Duration = 3,
			})
		end
	end

	-- Show delete all button if results found
	if foundCount > 0 then
		deleteAllFrame.Visible = true
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Complete",
			Text = string.format("Found %d player(s)!", foundCount),
			Duration = 3,
		})
	else
		deleteAllFrame.Visible = false
	end
end)

deleteAllButton.MouseButton1Click:Connect(function()
	if #searchResults == 0 then return end

	local playerNames = {}
	for _, data in ipairs(searchResults) do
		table.insert(playerNames, data.Username)
	end

	-- Langsung pakai confirmDialog
	confirmTitle.Text = "Delete All Data"
	confirmMessage.Text = string.format("Delete ALL leaderboard data from %d player(s)?\n%s", 
		#searchResults,
		table.concat(playerNames, ", ")
	)
	currentConfirmCallback = function()
		local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
		if deleteLeaderboardEvent then
			for _, data in ipairs(searchResults) do
				deleteLeaderboardEvent:FireServer(data.UserId, "all")
			end
		end

		-- Clear results
		for _, child in pairs(resultsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		searchResults = {}
		deleteAllFrame.Visible = false
		searchBox.Text = ""

		game.StarterGui:SetCore("SendNotification", {
			Title = "Success",
			Text = "All selected data deleted!",
			Duration = 3,
		})
	end

	confirmDialog.Size = UDim2.new(0, 0, 0, 0)
	confirmDialog.Visible = true
	tweenSize(confirmDialog, UDim2.new(0.4, 0, 0.4, 0), 0.3)  -- ✅ Ukuran lebih besar
end)

-- Create Admin Button
local isOpen = false -- Pindahkan ke scope global

if topbarPlusLoaded and Icon then
	-- Use TopbarPlus
	print("Creating TopbarPlus icon...")
	local adminIcon = Icon.new()
	adminIcon:setLabel("Admin")
	adminIcon:setImage("rbxassetid://128692376033664")

	-- Removed setTip() since it's not available in all TopbarPlus versions

	adminIcon.selected:Connect(function()
		isOpen = true
		mainPanel.Size = UDim2.new(0, 0, 0, 0)
		mainPanel.Visible = true
		tweenSize(mainPanel, UDim2.new(0.7, 0, 0.9, 0), 0.3)  -- ✅ Scale-based
	end)

	adminIcon.deselected:Connect(function()
		isOpen = false
		-- Sembunyikan konten sebelum animasi
		for _, child in ipairs(contentContainer:GetChildren()) do
			child.Visible = false
		end

		tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
			mainPanel.Visible = false
			mainPanel.Size = UDim2.new(0.7, 0, 0.9, 0)  -- ✅ Scale-based
			-- Kembalikan visibility tab yang aktif
			if currentTab then
				currentTab.Visible = true
			end
		end)
	end)

	-- Connect close button to deselect icon
	closeButton.MouseButton1Click:Connect(function()
		adminIcon:deselect()
	end)

	print("✓ TopbarPlus icon created")
else
	-- Fallback: Create custom button (✅ FULLY ADAPTIVE)
	warn("Using fallback admin button")

	-- Hide default topbar to prevent conflicts
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

	local fallbackButton = Instance.new("ScreenGui")
	fallbackButton.Name = "AdminButton"
	fallbackButton.ResetOnSpawn = false
	fallbackButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fallbackButton.DisplayOrder = 999
	fallbackButton.Parent = playerGui

	local buttonFrame = Instance.new("TextButton")
	buttonFrame.Size = UDim2.new(0.07, 0, 0.04, 0)  -- ✅ Scale-based
	buttonFrame.Position = UDim2.new(0.005, 0, 0.01, 0)
	buttonFrame.BackgroundColor3 = COLORS.Panel
	buttonFrame.BorderSizePixel = 0
	buttonFrame.Font = Enum.Font.GothamBold
	buttonFrame.Text = ""
	buttonFrame.AutoButtonColor = false
	buttonFrame.Parent = fallbackButton

	createCorner(8).Parent = buttonFrame
	createStroke(COLORS.Border, 2).Parent = buttonFrame

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.3, 0, 0.8, 0)  -- ✅ Scale-based
	icon.Position = UDim2.new(0.05, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://7733954760"
	icon.ImageColor3 = COLORS.Text
	icon.Parent = buttonFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)  -- ✅ Scale-based
	label.Position = UDim2.new(0.38, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "Admin"
	label.TextColor3 = COLORS.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = buttonFrame
	makeTextAdaptive(label, 14)  -- ✅ Adaptive text

	buttonFrame.MouseButton1Click:Connect(function()
		isOpen = not isOpen

		if isOpen then
			buttonFrame.BackgroundColor3 = COLORS.Accent
			mainPanel.Size = UDim2.new(0, 0, 0, 0)
			mainPanel.Visible = true
			tweenSize(mainPanel, UDim2.new(0.7, 0, 0.9, 0), 0.3)  -- ✅ Scale-based
		else
			buttonFrame.BackgroundColor3 = COLORS.Panel
			tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
				mainPanel.Visible = false
				mainPanel.Size = UDim2.new(0.7, 0, 0.9, 0)  -- ✅ Scale-based
			end)
		end
	end)

	buttonFrame.MouseEnter:Connect(function()
		if not isOpen then
			TweenService:Create(buttonFrame, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
		end
	end)

	buttonFrame.MouseLeave:Connect(function()
		if not isOpen then
			TweenService:Create(buttonFrame, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
		end
	end)

	-- Close panel when close button is clicked
	closeButton.MouseButton1Click:Connect(function()
		isOpen = false
		buttonFrame.BackgroundColor3 = COLORS.Panel

		-- Sembunyikan konten sebelum animasi
		for _, child in ipairs(contentContainer:GetChildren()) do
			child.Visible = false
		end

		tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
			mainPanel.Visible = false
			mainPanel.Size = UDim2.new(0.7, 0, 0.9, 0)  -- ✅ Scale-based
			-- Kembalikan visibility tab yang aktif
			if currentTab then
				currentTab.Visible = true
			end
		end)
	end)

	print("✓ Fallback admin button created")
end


print("Admin Panel System Loaded Successfully")