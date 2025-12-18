local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))

local function isAdmin()
	return TitleConfig.IsAdmin(player.UserId)
end

local function isPrimaryAdmin()
	return TitleConfig.IsPrimaryAdmin(player.UserId)
end

local function isThirdpartyAdmin()
	return TitleConfig.IsThirdpartyAdmin(player.UserId)
end

if not isAdmin() then
	return
end

local hasPrimaryAccess = isPrimaryAdmin()
local hasFullAccess = TitleConfig.IsFullAdmin(player.UserId)
local isThirdparty = isThirdpartyAdmin()

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

local Icon
local topbarPlusLoaded = false

local function loadTopbarPlus()
	local success, result = pcall(function()
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
		return true
	else
		warn("Failed to load TopbarPlus: " .. tostring(result))
		return false
	end
end

task.wait(1)
loadTopbarPlus()

if not topbarPlusLoaded then
	warn("TopbarPlus not available, using fallback button")
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanelGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local screenPadding = Instance.new("UIPadding")
screenPadding.PaddingTop = UDim.new(0.05, 0)
screenPadding.PaddingBottom = UDim.new(0.05, 0)
screenPadding.Parent = screenGui

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

local ACCENT_COLORS = {
	Color3.fromRGB(88, 166, 255),
	Color3.fromRGB(139, 195, 74),
	Color3.fromRGB(255, 152, 0),
	Color3.fromRGB(156, 39, 176),
	Color3.fromRGB(233, 30, 99),
	Color3.fromRGB(0, 188, 212),
	Color3.fromRGB(255, 193, 7),
	Color3.fromRGB(76, 175, 80),
}

local function getCardAccentColor(index)
	return ACCENT_COLORS[((index - 1) % #ACCENT_COLORS) + 1]
end

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function createPadding(padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, padding)
	pad.PaddingBottom = UDim.new(0, padding)
	pad.PaddingLeft = UDim.new(0, padding)
	pad.PaddingRight = UDim.new(0, padding)
	return pad
end

local function createStroke(color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

local function createScaledCorner(scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	return corner
end

local function createTextSizeConstraint(maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxSize or 18
	return constraint
end

local function createScaledPadding(top, bottom, left, right)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(top or 0, 0)
	pad.PaddingBottom = UDim.new(bottom or top or 0, 0)
	pad.PaddingLeft = UDim.new(left or top or 0, 0)
	pad.PaddingRight = UDim.new(right or left or top or 0, 0)
	return pad
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

			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			frame.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,
				framePos.Y.Scale + deltaScaleY,
				0
			)
		end
	end)
end

local function createButton(text, color, hoverColor)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = color or COLORS.Button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 14
	button.AutoButtonColor = false

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

local mainContainer = Instance.new("Frame")
mainContainer.Name = "AdminPanelContainer"
mainContainer.Size = UDim2.new(0.7, 0, 0.9, 0)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = screenGui

local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 0.75
aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
aspectRatio.DominantAxis = Enum.DominantAxis.Width
aspectRatio.Parent = mainContainer

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(1, 0, 1, 0)
mainPanel.Position = UDim2.new(0, 0, 0, 0)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = mainContainer

createScaledCorner(0.02).Parent = mainPanel
createStroke(COLORS.Border, 2).Parent = mainPanel

local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingLeft = UDim.new(0.02, 0)
mainPadding.PaddingRight = UDim.new(0.02, 0)
mainPadding.PaddingTop = UDim.new(0.015, 0)
mainPadding.PaddingBottom = UDim.new(0.02, 0)
mainPadding.Parent = mainPanel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.09, 0)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = mainPanel

createScaledCorner(0.15).Parent = header

local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0.02, 0)
headerPadding.PaddingRight = UDim.new(0.02, 0)
headerPadding.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.85, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "Admin Panel"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local headerTitleConstraint = createTextSizeConstraint(20)
headerTitleConstraint.Parent = headerTitle

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.08, 0, 0.7, 0)
closeButton.Position = UDim2.new(1, 0, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "×"
closeButton.TextColor3 = COLORS.Text
closeButton.TextScaled = true
closeButton.Parent = header

createScaledCorner(0.2).Parent = closeButton
createTextSizeConstraint(24).Parent = closeButton

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0.07, 0)
tabContainer.Position = UDim2.new(0, 0, 0.11, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0.01, 0)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabContainer

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 0.8, 0)
contentContainer.Position = UDim2.new(0, 0, 0.19, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainPanel

local currentTab = nil
local totalTabs = 4

local function createTab(name, order)
	local tab = Instance.new("TextButton")

	local tabWidth = 0.24
	tab.Size = UDim2.new(tabWidth, 0, 1, 0)
	tab.BackgroundColor3 = COLORS.Button
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamMedium
	tab.Text = name
	tab.TextColor3 = COLORS.TextSecondary
	tab.TextScaled = true
	tab.AutoButtonColor = false
	tab.LayoutOrder = order
	tab.Parent = tabContainer

	createScaledCorner(0.15).Parent = tab

	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 14
	textSizeConstraint.MinTextSize = 9
	textSizeConstraint.Parent = tab

	local content = Instance.new("Frame")
	content.Name = name .. "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Visible = false
	content.Parent = contentContainer

	tab.MouseButton1Click:Connect(function()
		for _, child in ipairs(contentContainer:GetChildren()) do
			child.Visible = false
		end

		for _, tabBtn in ipairs(tabContainer:GetChildren()) do
			if tabBtn:IsA("TextButton") then
				tabBtn.BackgroundColor3 = COLORS.Button
				tabBtn.TextColor3 = COLORS.TextSecondary
			end
		end

		content.Visible = true
		tab.BackgroundColor3 = COLORS.Accent
		tab.TextColor3 = COLORS.Text
		currentTab = content
	end)

	return content, tab
end

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
notifLayout.Padding = UDim.new(0, 6)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Parent = notifScroll

local typeFrame = Instance.new("Frame")
typeFrame.Size = UDim2.new(1, 0, 0, 40)
typeFrame.BackgroundTransparency = 1
typeFrame.LayoutOrder = 1
typeFrame.Parent = notifScroll

local typeLabel = Instance.new("TextLabel")
typeLabel.Size = UDim2.new(0, 100, 1, 0)
typeLabel.BackgroundTransparency = 1
typeLabel.Font = Enum.Font.GothamMedium
typeLabel.Text = "Type:"
typeLabel.TextColor3 = COLORS.Text
typeLabel.TextSize = 14
typeLabel.TextXAlignment = Enum.TextXAlignment.Left
typeLabel.Parent = typeFrame

local typeButtons = Instance.new("Frame")
typeButtons.Size = UDim2.new(1, -110, 1, 0)
typeButtons.Position = UDim2.new(0, 110, 0, 0)
typeButtons.BackgroundTransparency = 1
typeButtons.Parent = typeFrame

local typeLayout = Instance.new("UIListLayout")
typeLayout.FillDirection = Enum.FillDirection.Horizontal
typeLayout.Padding = UDim.new(0, 8)
typeLayout.Parent = typeButtons

local selectedType = "Server"

local function createTypeButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 1, 0)
	btn.BackgroundColor3 = text == "Server" and COLORS.Accent or COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = typeButtons

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

local messageFrame = Instance.new("Frame")
messageFrame.Size = UDim2.new(1, 0, 0.4, 0)
messageFrame.BackgroundTransparency = 1
messageFrame.LayoutOrder = 2
messageFrame.Parent = notifScroll

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, 0, 0.25, 0)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.GothamMedium
messageLabel.Text = "Message:"
messageLabel.TextColor3 = COLORS.Text
messageLabel.TextSize = 14
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Parent = messageFrame

local messageBox = Instance.new("TextBox")
messageBox.Size = UDim2.new(1, 0, 0.625, 0)
messageBox.Position = UDim2.new(0, 0, 0.313, 0)
messageBox.BackgroundColor3 = COLORS.Panel
messageBox.BorderSizePixel = 0
messageBox.Font = Enum.Font.Gotham
messageBox.PlaceholderText = "Enter notification message..."
messageBox.Text = ""
messageBox.TextColor3 = COLORS.Text
messageBox.TextSize = 13
messageBox.TextWrapped = true
messageBox.TextXAlignment = Enum.TextXAlignment.Left
messageBox.TextYAlignment = Enum.TextYAlignment.Top
messageBox.ClearTextOnFocus = false
messageBox.MultiLine = true
messageBox.Parent = messageFrame

createCorner(6).Parent = messageBox
createPadding(8).Parent = messageBox

local durationFrame = Instance.new("Frame")
durationFrame.Size = UDim2.new(1, 0, 0.15, 0)
durationFrame.BackgroundTransparency = 1
durationFrame.LayoutOrder = 3
durationFrame.Parent = notifScroll

local durationLabel = Instance.new("TextLabel")
durationLabel.Size = UDim2.new(1, 0, 0, 20)
durationLabel.BackgroundTransparency = 1
durationLabel.Font = Enum.Font.GothamMedium
durationLabel.Text = "Duration: 5s"
durationLabel.TextColor3 = COLORS.Text
durationLabel.TextScaled = true
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = durationFrame

createTextSizeConstraint(14).Parent = durationLabel

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0.15, 0)
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
sliderHandle.Size = UDim2.new(0.04, 0, 2, 0)
sliderHandle.Position = UDim2.new(0.042, 0, -0.5, 0)
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

		selectedDuration = math.floor(relativePos * 120 + 1)
		durationLabel.Text = "Duration: " .. selectedDuration .. "s"

		sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
		sliderHandle.Position = UDim2.new(relativePos, 0, -0.5, 0)
	end
end)

local colorFrame = Instance.new("Frame")
colorFrame.Size = UDim2.new(1, 0, 0.15, 0)
colorFrame.BackgroundTransparency = 1
colorFrame.LayoutOrder = 4
colorFrame.Parent = notifScroll

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(1, 0, 0.4, 0)
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.Text = "Text Color:"
colorLabel.TextColor3 = COLORS.Text
colorLabel.TextScaled = true
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = colorFrame

createTextSizeConstraint(14).Parent = colorLabel

local colorContainer = Instance.new("Frame")
colorContainer.Size = UDim2.new(1, 0, 0.55, 0)
colorContainer.Position = UDim2.new(0, 0, 0.45, 0)
colorContainer.BackgroundTransparency = 1
colorContainer.Parent = colorFrame

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0.02, 0)
colorLayout.Parent = colorContainer

local selectedColor = Color3.fromRGB(255, 255, 255)

local function createColorButton(color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.08, 0, 1, 0)
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
	checkmark.TextSize = 18
	checkmark.Visible = color == Color3.fromRGB(255, 255, 255)
	checkmark.Parent = btn

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

local sendFrame = Instance.new("Frame")
sendFrame.Size = UDim2.new(1, 0, 0.113, 0)
sendFrame.BackgroundTransparency = 1
sendFrame.LayoutOrder = 5
sendFrame.Parent = notifScroll

local sendButton = createButton("Send Notification", COLORS.Accent, COLORS.AccentHover)
sendButton.Size = UDim2.new(1, 0, 1, 0)
sendButton.Parent = sendFrame

sendButton.MouseButton1Click:Connect(function()
	if messageBox.Text ~= "" then
		local notifText = messageBox.Text
		local color = selectedColor or Color3.fromRGB(255, 255, 255)
		local duration = selectedDuration or 5

		sendNotificationEvent:FireServer(selectedType:lower(), notifText, color, nil, duration)

		messageBox.Text = ""
	end
end)

local playersTab, playersTabBtn = createTab("Players", 2)

local searchContainer = Instance.new("Frame")
searchContainer.Name = "SearchContainer"
searchContainer.Size = UDim2.new(1, 0, 0, 40)
searchContainer.Position = UDim2.new(0, 0, 0, 0)
searchContainer.BackgroundTransparency = 1
searchContainer.Parent = playersTab

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 35)
searchBox.Position = UDim2.new(0, 10, 0, 0)
searchBox.BackgroundColor3 = COLORS.Panel
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "🔍 Search players..."
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.PlaceholderColor3 = COLORS.TextSecondary
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchContainer

createCorner(8).Parent = searchBox
createStroke(COLORS.Border, 1).Parent = searchBox

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 12)
searchPadding.PaddingRight = UDim.new(0, 12)
searchPadding.Parent = searchBox

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, 0, 1, -50)
playersScroll.Position = UDim2.new(0, 0, 0, 45)
playersScroll.BackgroundTransparency = 1
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 4
playersScroll.ScrollBarImageColor3 = COLORS.Border
playersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playersScroll.Parent = playersTab

local playerScrollPadding = Instance.new("UIPadding")
playerScrollPadding.PaddingLeft = UDim.new(0, 10)
playerScrollPadding.PaddingRight = UDim.new(0, 10)
playerScrollPadding.PaddingTop = UDim.new(0, 5)
playerScrollPadding.PaddingBottom = UDim.new(0, 10)
playerScrollPadding.Parent = playersScroll

local playersLayout = Instance.new("UIListLayout")
playersLayout.Padding = UDim.new(0, 8)
playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersLayout.Parent = playersScroll

local currentSearchQuery = ""

local playerDetailPanel = Instance.new("Frame")
playerDetailPanel.Name = "PlayerDetail"
playerDetailPanel.Size = UDim2.new(0.25, 0, 0.8, 0)
playerDetailPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
playerDetailPanel.AnchorPoint = Vector2.new(0.5, 0.5)
playerDetailPanel.BackgroundColor3 = COLORS.Background
playerDetailPanel.BorderSizePixel = 0
playerDetailPanel.Visible = false
playerDetailPanel.ZIndex = 10
playerDetailPanel.Parent = screenGui

createCorner(12).Parent = playerDetailPanel
createStroke(COLORS.Border, 2).Parent = playerDetailPanel

local detailHeader = Instance.new("Frame")
detailHeader.Size = UDim2.new(1, 0, 0.091, 0)
detailHeader.BackgroundColor3 = COLORS.Header
detailHeader.BorderSizePixel = 0
detailHeader.Parent = playerDetailPanel

createCorner(12).Parent = detailHeader

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(0.85, 0, 1, 0)
detailTitle.Position = UDim2.new(0.05, 0, 0, 0)
detailTitle.BackgroundTransparency = 1
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Text = "Player Details"
detailTitle.TextColor3 = COLORS.Text
detailTitle.TextScaled = true
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.Parent = detailHeader

createTextSizeConstraint(18).Parent = detailTitle

local detailCloseButton = Instance.new("TextButton")
detailCloseButton.Size = UDim2.new(0.12, 0, 0.6, 0)
detailCloseButton.Position = UDim2.new(0.85, 0, 0.2, 0)
detailCloseButton.BackgroundColor3 = COLORS.Button
detailCloseButton.BorderSizePixel = 0
detailCloseButton.Font = Enum.Font.GothamBold
detailCloseButton.Text = "×"
detailCloseButton.TextColor3 = COLORS.Text
detailCloseButton.TextScaled = true
detailCloseButton.Parent = detailHeader

createCorner(6).Parent = detailCloseButton

detailCloseButton.MouseButton1Click:Connect(function()
	tweenSize(playerDetailPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		playerDetailPanel.Visible = false
		playerDetailPanel.Size = UDim2.new(0.25, 0, 0.8, 0)
		mainContainer.Visible = true
	end)
end)

local detailScroll = Instance.new("ScrollingFrame")
detailScroll.Size = UDim2.new(0.95, 0, 0.873, 0)
detailScroll.Position = UDim2.new(0.025, 0, 0.109, 0)
detailScroll.BackgroundTransparency = 1
detailScroll.BorderSizePixel = 0
detailScroll.ScrollBarThickness = 4
detailScroll.ScrollBarImageColor3 = COLORS.Border
detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
detailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailScroll.Parent = playerDetailPanel

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0, 10)
detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailLayout.Parent = detailScroll

local confirmDialog = Instance.new("Frame")
confirmDialog.Name = "ConfirmDialog"
confirmDialog.Size = UDim2.new(0.35, 0, 0.25, 0)
confirmDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmDialog.AnchorPoint = Vector2.new(0.5, 0.5)
confirmDialog.BackgroundColor3 = COLORS.Background
confirmDialog.BorderSizePixel = 0
confirmDialog.Visible = false
confirmDialog.ZIndex = 150
confirmDialog.Parent = screenGui

createCorner(12).Parent = confirmDialog
createStroke(COLORS.Border, 2).Parent = confirmDialog

local confirmAspect = Instance.new("UIAspectRatioConstraint")
confirmAspect.AspectRatio = 1.9
confirmAspect.AspectType = Enum.AspectType.ScaleWithParentSize
confirmAspect.DominantAxis = Enum.DominantAxis.Width
confirmAspect.Parent = confirmDialog

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

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(0.9, 0, 1, 0)
confirmTitle.Position = UDim2.new(0.05, 0, 0, 0)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Text = "Confirm Action"
confirmTitle.TextColor3 = COLORS.Text
confirmTitle.TextScaled = true
confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
confirmTitle.Parent = confirmHeader

createTextSizeConstraint(18).Parent = confirmTitle

local confirmMessage = Instance.new("TextLabel")
confirmMessage.Size = UDim2.new(0.9, 0, 0.35, 0)
confirmMessage.Position = UDim2.new(0.05, 0, 0.28, 0)
confirmMessage.BackgroundTransparency = 1
confirmMessage.Font = Enum.Font.Gotham
confirmMessage.Text = ""
confirmMessage.TextColor3 = COLORS.TextSecondary
confirmMessage.TextScaled = true
confirmMessage.TextWrapped = true
confirmMessage.TextXAlignment = Enum.TextXAlignment.Center
confirmMessage.TextYAlignment = Enum.TextYAlignment.Top
confirmMessage.Parent = confirmDialog

createTextSizeConstraint(16).Parent = confirmMessage

local confirmButtons = Instance.new("Frame")
confirmButtons.Size = UDim2.new(0.9, 0, 0.25, 0)
confirmButtons.Position = UDim2.new(0.05, 0, 0.68, 0)
confirmButtons.BackgroundTransparency = 1
confirmButtons.Parent = confirmDialog

local confirmButtonLayout = Instance.new("UIListLayout")
confirmButtonLayout.FillDirection = Enum.FillDirection.Horizontal
confirmButtonLayout.Padding = UDim.new(0.03, 0)
confirmButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
confirmButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
confirmButtonLayout.Parent = confirmButtons

local currentConfirmCallback = nil

showConfirmation = function(title, message, callback)
	confirmTitle.Text = title
	confirmMessage.Text = message
	currentConfirmCallback = callback
	confirmDialog.Size = UDim2.new(0, 0, 0, 0)
	confirmDialog.Visible = true
	tweenSize(confirmDialog, UDim2.new(0.35, 0, 0.25, 0), 0.3)
end

local cancelButton = createButton("Cancel", COLORS.Button, COLORS.ButtonHover)
cancelButton.Size = UDim2.new(0.45, 0, 1, 0)
cancelButton.LayoutOrder = 1
cancelButton.Parent = confirmButtons

cancelButton.MouseButton1Click:Connect(function()
	tweenSize(confirmDialog, UDim2.new(0, 0, 0, 0), 0.3, function()
		confirmDialog.Visible = false
		currentConfirmCallback = nil
	end)
end)

local confirmButton = createButton("Confirm", COLORS.Danger, COLORS.DangerHover)
confirmButton.Size = UDim2.new(0.45, 0, 1, 0)
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

local currentSpectatePlayer = nil
local originalCamera = nil
local spectateConnection = nil

local function createTeleportPopup(targetPlayer)
	mainContainer.Visible = false
	playerDetailPanel.Visible = false

	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 280, 0, 180)
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

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 45)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 15)
	headerBottom.Position = UDim2.new(0, 0, 1, -15)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Teleport " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -36, 0, 8)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true
	end)

	local tpHereBtn = Instance.new("TextButton")
	tpHereBtn.Size = UDim2.new(1, -30, 0, 45)
	tpHereBtn.Position = UDim2.new(0, 15, 0, 55)
	tpHereBtn.BackgroundColor3 = COLORS.Button
	tpHereBtn.BorderSizePixel = 0
	tpHereBtn.Font = Enum.Font.GothamBold
	tpHereBtn.Text = "Teleport " .. targetPlayer.Name .. " Here"
	tpHereBtn.TextColor3 = COLORS.Text
	tpHereBtn.TextSize = 13
	tpHereBtn.AutoButtonColor = false
	tpHereBtn.Parent = popup

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
		mainContainer.Visible = true
	end)

	local tpToBtn = Instance.new("TextButton")
	tpToBtn.Size = UDim2.new(1, -30, 0, 45)
	tpToBtn.Position = UDim2.new(0, 15, 0, 110)
	tpToBtn.BackgroundColor3 = COLORS.Button
	tpToBtn.BorderSizePixel = 0
	tpToBtn.Font = Enum.Font.GothamBold
	tpToBtn.Text = "Teleport To " .. targetPlayer.Name
	tpToBtn.TextColor3 = COLORS.Text
	tpToBtn.TextSize = 13
	tpToBtn.AutoButtonColor = false
	tpToBtn.Parent = popup

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
		mainContainer.Visible = true
	end)

	return popup
end

local function showGiveTitlePopup(targetPlayer)
	mainContainer.Visible = false
	playerDetailPanel.Visible = false

	local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

	local givableTitles = {}
	for titleName, titleData in pairs(TitleConfig.SpecialTitles) do
		if titleData.Givable == true then
			table.insert(givableTitles, {
				Name = titleName,
				DisplayName = titleData.DisplayName or titleName,
				Color = titleData.Color or COLORS.Text,
				Icon = titleData.Icon or "🏷️",
				Priority = titleData.Priority or 0
			})
		end
	end

	table.sort(givableTitles, function(a, b)
		return a.Priority > b.Priority
	end)

	local popupHeight = 110 + (#givableTitles * 50)
	if popupHeight > 500 then popupHeight = 500 end

	local popup = Instance.new("Frame")
	popup.Name = "GiveTitlePopup"
	popup.Size = UDim2.new(0.35, 0, 0.6, 0)
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

	local popupAspect = Instance.new("UIAspectRatioConstraint")
	popupAspect.AspectRatio = 0.7
	popupAspect.AspectType = Enum.AspectType.ScaleWithParentSize
	popupAspect.DominantAxis = Enum.DominantAxis.Width
	popupAspect.Parent = popup

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.08, 0)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0.35, 0)
	headerBottom.Position = UDim2.new(0, 0, 0.65, 0)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.04, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Give Title to " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	createTextSizeConstraint(14).Parent = title

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.1, 0, 0.75, 0)
	closeBtn.Position = UDim2.new(0.88, 0, 0.125, 0)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true
	end)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(0.94, 0, 0.72, 0)
	scrollFrame.Position = UDim2.new(0.03, 0, 0.1, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = COLORS.Border
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = popup

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0.01, 0)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	local selectedTitle = nil
	local selectedButton = nil

	for i, titleInfo in ipairs(givableTitles) do
		local titleBtn = Instance.new("TextButton")
		titleBtn.Size = UDim2.new(1, 0, 0, 42)
		titleBtn.BackgroundColor3 = COLORS.Panel
		titleBtn.BorderSizePixel = 0
		titleBtn.Text = ""
		titleBtn.AutoButtonColor = false
		titleBtn.LayoutOrder = i
		titleBtn.Parent = scrollFrame

		createCorner(8).Parent = titleBtn

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 4, 1, 0)
		accentBar.BackgroundColor3 = titleInfo.Color
		accentBar.BorderSizePixel = 0
		accentBar.Parent = titleBtn

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 8)
		accentCorner.Parent = accentBar

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 30, 0, 30)
		iconLabel.Position = UDim2.new(0, 15, 0.5, 0)
		iconLabel.AnchorPoint = Vector2.new(0, 0.5)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.Gotham
		iconLabel.Text = titleInfo.Icon
		iconLabel.TextSize = 18
		iconLabel.Parent = titleBtn

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -60, 1, 0)
		nameLabel.Position = UDim2.new(0, 50, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = titleInfo.DisplayName
		nameLabel.TextColor3 = titleInfo.Color
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = titleBtn

		titleBtn.MouseEnter:Connect(function()
			if selectedButton ~= titleBtn then
				TweenService:Create(titleBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
			end
		end)

		titleBtn.MouseLeave:Connect(function()
			if selectedButton ~= titleBtn then
				TweenService:Create(titleBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
			end
		end)

		titleBtn.MouseButton1Click:Connect(function()
			if selectedButton then
				selectedButton.BackgroundColor3 = COLORS.Panel
			end

			selectedTitle = titleInfo.Name
			selectedButton = titleBtn
			titleBtn.BackgroundColor3 = COLORS.Accent
		end)
	end

	local giveBtn = Instance.new("TextButton")
	giveBtn.Size = UDim2.new(1, -20, 0, 40)
	giveBtn.Position = UDim2.new(0, 10, 1, -50)
	giveBtn.BackgroundColor3 = COLORS.Success
	giveBtn.BorderSizePixel = 0
	giveBtn.Font = Enum.Font.GothamBold
	giveBtn.Text = "Give Title"
	giveBtn.TextColor3 = COLORS.Text
	giveBtn.TextSize = 14
	giveBtn.Parent = popup

	createCorner(8).Parent = giveBtn

	giveBtn.MouseEnter:Connect(function()
		TweenService:Create(giveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(87, 201, 149)}):Play()
	end)

	giveBtn.MouseLeave:Connect(function()
		TweenService:Create(giveBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Success}):Play()
	end)

	giveBtn.MouseButton1Click:Connect(function()
		if not selectedTitle then
			StarterGui:SetCore("SendNotification", {
				Title = "Warning",
				Text = "Please select a title first!",
				Duration = 3
			})
			return
		end

		showConfirmation(
			"Give Title",
			string.format("Give '%s' title to %s?\n(Unlocks only, won't auto-equip)", selectedTitle, targetPlayer.Name),
			function()
				local giveTitleEvent = remoteFolder:FindFirstChild("GiveTitle")
				if giveTitleEvent then
					giveTitleEvent:FireServer(targetPlayer.UserId, selectedTitle)
				end
				popup:Destroy()
				mainContainer.Visible = true
			end
		)
	end)

	return popup
end

local function createModifyPlayerPopup(targetPlayer)
	mainContainer.Visible = false
	playerDetailPanel.Visible = false

	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 320, 0, 350)
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

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = COLORS.Header
	header.BorderSizePixel = 0
	header.Parent = popup

	createCorner(12).Parent = header

	local headerBottom = Instance.new("Frame")
	headerBottom.Size = UDim2.new(1, 0, 0, 15)
	headerBottom.Position = UDim2.new(0, 0, 1, -15)
	headerBottom.BackgroundColor3 = COLORS.Header
	headerBottom.BorderSizePixel = 0
	headerBottom.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Modify " .. targetPlayer.Name
	title.TextColor3 = COLORS.Text
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true
	end)

	local contentY = 60

	local isFrozen = false
	local freezeBtn = Instance.new("TextButton")
	freezeBtn.Size = UDim2.new(1, -30, 0, 45)
	freezeBtn.Position = UDim2.new(0, 15, 0, contentY)
	freezeBtn.BackgroundColor3 = COLORS.Button
	freezeBtn.BorderSizePixel = 0
	freezeBtn.Font = Enum.Font.GothamBold
	freezeBtn.Text = "Freeze Player"
	freezeBtn.TextColor3 = COLORS.Text
	freezeBtn.TextSize = 13
	freezeBtn.AutoButtonColor = false
	freezeBtn.Parent = popup

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

	contentY = contentY + 55

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1, -30, 0, 20)
	speedLabel.Position = UDim2.new(0, 15, 0, contentY)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Text = "Speed Multiplier: 1.0x"
	speedLabel.TextColor3 = COLORS.Text
	speedLabel.TextSize = 12
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.Parent = popup

	contentY = contentY + 25

	local speedSliderBg = Instance.new("Frame")
	speedSliderBg.Size = UDim2.new(1, -30, 0, 8)
	speedSliderBg.Position = UDim2.new(0, 15, 0, contentY)
	speedSliderBg.BackgroundColor3 = COLORS.Panel
	speedSliderBg.BorderSizePixel = 0
	speedSliderBg.Parent = popup

	createCorner(4).Parent = speedSliderBg

	local speedFill = Instance.new("Frame")
	speedFill.Size = UDim2.new(0.2, 0, 1, 0)
	speedFill.BackgroundColor3 = COLORS.Accent
	speedFill.BorderSizePixel = 0
	speedFill.Parent = speedSliderBg

	createCorner(4).Parent = speedFill

	local speedHandle = Instance.new("Frame")
	speedHandle.Size = UDim2.new(0, 16, 0, 16)
	speedHandle.Position = UDim2.new(0.2, -8, 0.5, -8)
	speedHandle.BackgroundColor3 = COLORS.Text
	speedHandle.BorderSizePixel = 0
	speedHandle.Parent = speedSliderBg

	createCorner(8).Parent = speedHandle

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
			speedHandle.Position = UDim2.new(relative, -8, 0.5, -8)

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

	contentY = contentY + 30

	local gravityLabel = Instance.new("TextLabel")
	gravityLabel.Size = UDim2.new(1, -30, 0, 20)
	gravityLabel.Position = UDim2.new(0, 15, 0, contentY)
	gravityLabel.BackgroundTransparency = 1
	gravityLabel.Font = Enum.Font.GothamBold
	gravityLabel.Text = "Gravity: Normal"
	gravityLabel.TextColor3 = COLORS.Text
	gravityLabel.TextSize = 12
	gravityLabel.TextXAlignment = Enum.TextXAlignment.Left
	gravityLabel.Parent = popup

	contentY = contentY + 25

	local gravityTypes = {"Normal", "Low", "Zero", "High"}
	local currentGravity = "Normal"
	local buttonWidth = 0.23
	local totalGap = 1 - (buttonWidth * 4)
	local spacing = totalGap / 5

	for i, gType in ipairs(gravityTypes) do
		local xPosition = spacing * i + buttonWidth * (i - 1)

		local gBtn = Instance.new("TextButton")
		gBtn.Size = UDim2.new(buttonWidth, 0, 0, 35)
		gBtn.Position = UDim2.new(xPosition, 0, 0, contentY)
		gBtn.BackgroundColor3 = (i == 1) and COLORS.Accent or COLORS.Button
		gBtn.BorderSizePixel = 0
		gBtn.Font = Enum.Font.GothamBold
		gBtn.Text = gType
		gBtn.TextColor3 = COLORS.Text
		gBtn.TextSize = 11
		gBtn.AutoButtonColor = false
		gBtn.Parent = popup

		createCorner(6).Parent = gBtn

		gBtn.MouseButton1Click:Connect(function()
			currentGravity = gType
			gravityLabel.Text = "Gravity: " .. gType

			local gravValue = 196.2
			if gType == "Low" then gravValue = 50
			elseif gType == "Zero" then gravValue = 0
			elseif gType == "High" then gravValue = 400 end

			setGravityEvent:FireServer(targetPlayer.UserId, gravValue)

			for _, btn in ipairs(popup:GetChildren()) do
				if btn:IsA("TextButton") and table.find(gravityTypes, btn.Text) then
					btn.BackgroundColor3 = (btn.Text == gType) and COLORS.Accent or COLORS.Button
				end
			end
		end)
	end

	return popup
end

local function showModifySummitPopup(targetPlayer)
	mainContainer.Visible = false
	playerDetailPanel.Visible = false

	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0.45, 0, 0.4, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = COLORS.Background
	popup.BorderSizePixel = 0
	popup.ZIndex = 100
	popup.Parent = screenGui

	createCorner(12).Parent = popup
	createStroke(COLORS.Border, 2).Parent = popup

	makeDraggable(popup)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.17, 0)
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
	title.Position = UDim2.new(0.04, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Modify " .. targetPlayer.Name .. " Summit Data"
	title.TextColor3 = COLORS.Text
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	createTextSizeConstraint(15).Parent = title

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.1, 0, 0.6, 0)
	closeBtn.Position = UDim2.new(0.88, 0, 0.2, 0)
	closeBtn.BackgroundColor3 = COLORS.Button
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = COLORS.Text
	closeBtn.Parent = header

	createCorner(6).Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup:Destroy()
		mainContainer.Visible = true
	end)

	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(0.9, 0, 0.75, 0)
	contentContainer.Position = UDim2.new(0.05, 0, 0.2, 0)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = popup

	local currentLabel = Instance.new("TextLabel")
	currentLabel.Size = UDim2.new(1, 0, 0.15, 0)
	currentLabel.Position = UDim2.new(0, 0, 0, 0)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.Gotham
	currentLabel.Text = "Current Summit: Loading..."
	currentLabel.TextColor3 = COLORS.TextSecondary
	currentLabel.TextScaled = true
	currentLabel.TextXAlignment = Enum.TextXAlignment.Left
	currentLabel.Parent = contentContainer

	task.spawn(function()
		local playerStats = targetPlayer:FindFirstChild("PlayerStats")
		if playerStats then
			local summitValue = playerStats:FindFirstChild("Summit")
			if summitValue then
				currentLabel.Text = "Current Summit: " .. tostring(summitValue.Value)
			end
		end
	end)

	local inputLabel = Instance.new("TextLabel")
	inputLabel.Size = UDim2.new(1, 0, 0, 25)
	inputLabel.Position = UDim2.new(0, 0, 0, 35)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Font = Enum.Font.GothamBold
	inputLabel.Text = "New Summit Value:"
	inputLabel.TextColor3 = COLORS.Text
	inputLabel.TextSize = 14
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.Parent = contentContainer

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.new(1, 0, 0, 50)
	inputBox.Position = UDim2.new(0, 0, 0, 70)
	inputBox.BackgroundColor3 = COLORS.Panel
	inputBox.BorderSizePixel = 0
	inputBox.Font = Enum.Font.Gotham
	inputBox.PlaceholderText = "Enter summit value (e.g. 100)"
	inputBox.Text = ""
	inputBox.TextColor3 = COLORS.Text
	inputBox.TextSize = 15
	inputBox.ClearTextOnFocus = false
	inputBox.Parent = contentContainer

	createCorner(8).Parent = inputBox
	createPadding(12).Parent = inputBox

	local setBtn = createButton("Set Summit", COLORS.Success, Color3.fromRGB(77, 191, 139))
	setBtn.Size = UDim2.new(1, 0, 0, 50)
	setBtn.Position = UDim2.new(0, 0, 0, 135)
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
				end
				popup:Destroy()
				mainContainer.Visible = true
			end
		)
	end)

	return popup
end

local playerCardIndex = 0

local function createPlayerCard(targetPlayer)
	local isLocalPlayer = (targetPlayer == player)
	playerCardIndex = playerCardIndex + 1
	local accentColor = getCardAccentColor(playerCardIndex)

	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, 0, 0.12, 0)
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.ClipsDescendants = true
	card.Parent = playersScroll

	createCorner(8).Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = accentColor
	cardStroke.Thickness = 1.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cardStroke.Parent = card

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0.015, 0, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 8)
	accentCorner.Parent = accentBar

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0.12, 0, 0.75, 0)
	avatar.Position = UDim2.new(0.03, 0, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
	avatar.Parent = card

	createCorner(6).Parent = avatar

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.45, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0.17, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = targetPlayer.Name .. (isLocalPlayer and " (You)" or "")
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	createTextSizeConstraint(14).Parent = nameLabel

	local displayLabel = Instance.new("TextLabel")
	displayLabel.Size = UDim2.new(0.45, 0, 0.28, 0)
	displayLabel.Position = UDim2.new(0.17, 0, 0.53, 0)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Font = Enum.Font.Gotham
	displayLabel.Text = "@" .. targetPlayer.DisplayName
	displayLabel.TextColor3 = accentColor
	displayLabel.TextScaled = true
	displayLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayLabel.Parent = card

	createTextSizeConstraint(12).Parent = displayLabel

	local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

	local function updateTitleLabel()
		local titleText = "Pengunjung"
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

					local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))
					if TitleConfig.Titles[titleText] then
						titleColor = TitleConfig.Titles[titleText].Color
					end
				else
					warn("⚠️ [ADMIN CLIENT] Failed to get title for", targetPlayer.Name)
				end
			end
		end

		local titleLabel = card:FindFirstChild("TitleLabel")
		if not titleLabel then
			titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Size = UDim2.new(0, 70, 0, 20)
			titleLabel.Position = UDim2.new(1, -80, 0, 20)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 11
			titleLabel.TextXAlignment = Enum.TextXAlignment.Right
			titleLabel.Parent = card
		end

		if titleText == "Pengunjung" then
			titleLabel.Text = ""
		else
			titleLabel.Text = titleText
			titleLabel.TextColor3 = titleColor
		end
	end

	updateTitleLabel()

	local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
	local lastTitleUpdate = 0
	local TITLE_DEBOUNCE = 2

	if titleRemotes then
		local updateOther = titleRemotes:FindFirstChild("UpdateOtherPlayerTitle")
		if updateOther then
			updateOther.OnClientEvent:Connect(function(changedPlayer, newTitle)
				if changedPlayer == targetPlayer then
					local now = tick()
					if now - lastTitleUpdate < TITLE_DEBOUNCE then return end
					lastTitleUpdate = now

					task.wait(0.5)
					updateTitleLabel()
				end
			end)
		end
	end

	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Panel}):Play()
	end)

	card.MouseButton1Click:Connect(function()
		for _, child in ipairs(detailScroll:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

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

			if hasFullAccess then
				local banBtn = createButton("Ban Player", COLORS.Danger, COLORS.DangerHover)
				banBtn.LayoutOrder = 2
				banBtn.Parent = actionsFrame

				banBtn.MouseButton1Click:Connect(function()
					showConfirmation("Ban Player", "Are you sure you want to ban " .. targetPlayer.Name .. "?", function()
						if targetPlayer then
							banPlayerEvent:FireServer(targetPlayer.UserId)
						end
					end)
				end)
			end

			local teleportBtn = createButton("Teleport", COLORS.Button, COLORS.ButtonHover)
			teleportBtn.LayoutOrder = 3
			teleportBtn.Parent = actionsFrame
			teleportBtn.MouseButton1Click:Connect(function()
				playerDetailPanel.Visible = false
				createTeleportPopup(targetPlayer)
			end)

			if hasFullAccess then
				local modifyBtn = createButton("Modify Player", COLORS.Button, COLORS.ButtonHover)
				modifyBtn.LayoutOrder = 4
				modifyBtn.Parent = actionsFrame
				modifyBtn.MouseButton1Click:Connect(function()
					playerDetailPanel.Visible = false
					createModifyPlayerPopup(targetPlayer)
				end)
			end

			local spectateBtn = createButton("Spectate Player", COLORS.Accent, COLORS.AccentHover)
			spectateBtn.LayoutOrder = 5
			spectateBtn.Parent = actionsFrame

			spectateBtn.MouseButton1Click:Connect(function()
				if currentSpectatePlayer then
					if spectateConnection then
						spectateConnection:Disconnect()
					end

					workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
					workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
					currentSpectatePlayer = nil
					spectateBtn.Text = "Spectate Player"
					spectateBtn.BackgroundColor3 = COLORS.Accent
				else
					if targetPlayer and targetPlayer.Character then
						currentSpectatePlayer = targetPlayer
						local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")

						if targetHumanoid then
							workspace.CurrentCamera.CameraSubject = targetHumanoid
							spectateBtn.Text = "Stop Spectating"
							spectateBtn.BackgroundColor3 = COLORS.Success

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

			if hasFullAccess then
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
			end

			if hasFullAccess then
				local giveTitleBtn = createButton("Give Title", COLORS.Accent, COLORS.AccentHover)
				giveTitleBtn.LayoutOrder = 7
				giveTitleBtn.Parent = actionsFrame
				giveTitleBtn.MouseButton1Click:Connect(function()
					if targetPlayer then
						playerDetailPanel.Visible = false
						showGiveTitlePopup(targetPlayer)
					end
				end)
			end

			if hasFullAccess then
				local modifySummitBtn = createButton("Modify Summit Data", COLORS.Accent, Color3.fromRGB(128, 141, 255))
				modifySummitBtn.LayoutOrder = 8
				modifySummitBtn.Parent = actionsFrame
				modifySummitBtn.MouseButton1Click:Connect(function()
					if targetPlayer then
						playerDetailPanel.Visible = false
						showModifySummitPopup(targetPlayer)
					end
				end)
			end

			local giveItemsBtn = createButton("Give Items", COLORS.Success, COLORS.Success)
			giveItemsBtn.LayoutOrder = 8
			giveItemsBtn.Parent = actionsFrame

			giveItemsBtn.MouseButton1Click:Connect(function()
				if not targetPlayer then return end

				local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

				mainContainer.Visible = false
				playerDetailPanel.Visible = false

				local giveItemsPopup = Instance.new("Frame")
				giveItemsPopup.Name = "GiveItemsPopup"
				giveItemsPopup.Size = UDim2.new(0.4, 0, 0.7, 0)
				giveItemsPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
				giveItemsPopup.AnchorPoint = Vector2.new(0.5, 0.5)
				giveItemsPopup.BackgroundColor3 = COLORS.Background
				giveItemsPopup.BorderSizePixel = 0
				giveItemsPopup.ZIndex = 30
				giveItemsPopup.ClipsDescendants = true
				giveItemsPopup.Parent = screenGui

				createCorner(12).Parent = giveItemsPopup
				createStroke(COLORS.Border, 2).Parent = giveItemsPopup

				local popupAspect = Instance.new("UIAspectRatioConstraint")
				popupAspect.AspectRatio = 0.82
				popupAspect.AspectType = Enum.AspectType.ScaleWithParentSize
				popupAspect.DominantAxis = Enum.DominantAxis.Width
				popupAspect.Parent = giveItemsPopup

				local popupHeader = Instance.new("Frame")
				popupHeader.Size = UDim2.new(1, 0, 0.08, 0)
				popupHeader.BackgroundColor3 = COLORS.Header
				popupHeader.BorderSizePixel = 0
				popupHeader.Parent = giveItemsPopup

				createCorner(12).Parent = popupHeader

				local headerBottom = Instance.new("Frame")
				headerBottom.Size = UDim2.new(1, 0, 0.3, 0)
				headerBottom.Position = UDim2.new(0, 0, 0.7, 0)
				headerBottom.BackgroundColor3 = COLORS.Header
				headerBottom.BorderSizePixel = 0
				headerBottom.Parent = popupHeader

				local popupTitle = Instance.new("TextLabel")
				popupTitle.Size = UDim2.new(0.85, 0, 1, 0)
				popupTitle.Position = UDim2.new(0.03, 0, 0, 0)
				popupTitle.BackgroundTransparency = 1
				popupTitle.Font = Enum.Font.GothamBold
				popupTitle.Text = "Give Items to " .. targetPlayer.Name
				popupTitle.TextColor3 = COLORS.Text
				popupTitle.TextScaled = true
				popupTitle.TextXAlignment = Enum.TextXAlignment.Left
				popupTitle.Parent = popupHeader

				createTextSizeConstraint(16).Parent = popupTitle

				local closePopupBtn = Instance.new("TextButton")
				closePopupBtn.Size = UDim2.new(0.08, 0, 0.6, 0)
				closePopupBtn.Position = UDim2.new(0.9, 0, 0.2, 0)
				closePopupBtn.BackgroundColor3 = COLORS.Button
				closePopupBtn.BorderSizePixel = 0
				closePopupBtn.Font = Enum.Font.GothamBold
				closePopupBtn.Text = "×"
				closePopupBtn.TextColor3 = COLORS.Text
				closePopupBtn.TextScaled = true
				closePopupBtn.Parent = popupHeader

				createCorner(6).Parent = closePopupBtn

				closePopupBtn.MouseButton1Click:Connect(function()
					giveItemsPopup:Destroy()
					mainContainer.Visible = true
				end)

				local tabFrame = Instance.new("Frame")
				tabFrame.Size = UDim2.new(0.94, 0, 0.08, 0)
				tabFrame.Position = UDim2.new(0.03, 0, 0.1, 0)
				tabFrame.BackgroundTransparency = 1
				tabFrame.ClipsDescendants = true
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
				auraTab.TextScaled = true
				auraTab.AutoButtonColor = false
				auraTab.Parent = tabFrame

				createCorner(6).Parent = auraTab
				createTextSizeConstraint(14).Parent = auraTab

				local toolTab = Instance.new("TextButton")
				toolTab.Size = UDim2.new(0.3, 0, 1, 0)
				toolTab.BackgroundColor3 = COLORS.Button
				toolTab.BorderSizePixel = 0
				toolTab.Font = Enum.Font.GothamBold
				toolTab.Text = "Tools"
				toolTab.TextColor3 = COLORS.Text
				toolTab.TextScaled = true
				toolTab.AutoButtonColor = false
				toolTab.Parent = tabFrame

				local moneyTab = Instance.new("TextButton")
				moneyTab.Size = UDim2.new(0.3, 0, 1, 0)
				moneyTab.BackgroundColor3 = COLORS.Button
				moneyTab.BorderSizePixel = 0
				moneyTab.Font = Enum.Font.GothamBold
				moneyTab.Text = "Money"
				moneyTab.TextColor3 = COLORS.Text
				moneyTab.TextScaled = true
				moneyTab.AutoButtonColor = false
				moneyTab.Visible = hasFullAccess
				moneyTab.Parent = tabFrame

				createCorner(6).Parent = moneyTab
				createCorner(6).Parent = toolTab
				createTextSizeConstraint(14).Parent = toolTab
				createTextSizeConstraint(14).Parent = moneyTab

				local contentFrame = Instance.new("Frame")
				contentFrame.Size = UDim2.new(0.94, 0, 0.64, 0)
				contentFrame.Position = UDim2.new(0.03, 0, 0.19, 0)
				contentFrame.BackgroundTransparency = 1
				contentFrame.ClipsDescendants = true
				contentFrame.Parent = giveItemsPopup

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
				auraLayout.Padding = UDim.new(0, 6)
				auraLayout.SortOrder = Enum.SortOrder.LayoutOrder
				auraLayout.Parent = auraContent

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
				toolLayout.Padding = UDim.new(0, 6)
				toolLayout.SortOrder = Enum.SortOrder.LayoutOrder
				toolLayout.Parent = toolContent

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
				moneyLayout.Padding = UDim.new(0, 6)
				moneyLayout.SortOrder = Enum.SortOrder.LayoutOrder
				moneyLayout.Parent = moneyContent

				local selectedAuras = {}
				local selectedTools = {}

				for _, aura in ipairs(ShopConfig.Auras) do
					if isThirdparty and aura.IsPremium then
						continue
					end
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 40)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = auraContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0, 30, 0, 30)
					checkbox.Position = UDim2.new(0, 5, 0, 5)
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
					checkmark.TextSize = 18
					checkmark.Visible = false
					checkmark.Parent = checkbox

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -45, 1, 0)
					label.Position = UDim2.new(0, 40, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = aura.Title
					label.TextColor3 = COLORS.Text
					label.TextSize = 13
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame

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

				for _, tool in ipairs(ShopConfig.Tools) do
					if isThirdparty and tool.IsPremium then
						continue
					end
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 40)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = toolContent

					createCorner(6).Parent = frame

					local checkbox = Instance.new("TextButton")
					checkbox.Size = UDim2.new(0, 30, 0, 30)
					checkbox.Position = UDim2.new(0, 5, 0, 5)
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
					checkmark.TextSize = 18
					checkmark.Visible = false
					checkmark.Parent = checkbox

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -45, 1, 0)
					label.Position = UDim2.new(0, 40, 0, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamMedium
					label.Text = tool.Title
					label.TextColor3 = COLORS.Text
					label.TextSize = 13
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = frame

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

				for _, pack in ipairs(ShopConfig.MoneyPacks) do
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 0, 50)
					frame.BackgroundColor3 = COLORS.Panel
					frame.BorderSizePixel = 0
					frame.Parent = moneyContent

					createCorner(6).Parent = frame

					local titleLabel = Instance.new("TextLabel")
					titleLabel.Size = UDim2.new(0.5, -10, 0, 20)
					titleLabel.Position = UDim2.new(0, 10, 0, 8)
					titleLabel.BackgroundTransparency = 1
					titleLabel.Font = Enum.Font.GothamBold
					titleLabel.Text = pack.Title
					titleLabel.TextColor3 = COLORS.Text
					titleLabel.TextSize = 13
					titleLabel.TextXAlignment = Enum.TextXAlignment.Left
					titleLabel.Parent = frame

					local amountLabel = Instance.new("TextLabel")
					amountLabel.Size = UDim2.new(0.5, -10, 0, 18)
					amountLabel.Position = UDim2.new(0, 10, 0, 28)
					amountLabel.BackgroundTransparency = 1
					amountLabel.Font = Enum.Font.Gotham
					amountLabel.Text = "$" .. tostring(pack.MoneyReward)
					amountLabel.TextColor3 = COLORS.Success
					amountLabel.TextSize = 12
					amountLabel.TextXAlignment = Enum.TextXAlignment.Left
					amountLabel.Parent = frame

					local selectBtn = Instance.new("TextButton")
					selectBtn.Size = UDim2.new(0, 80, 0, 35)
					selectBtn.Position = UDim2.new(1, -90, 0.5, -17)
					selectBtn.BackgroundColor3 = COLORS.Accent
					selectBtn.BorderSizePixel = 0
					selectBtn.Font = Enum.Font.GothamBold
					selectBtn.Text = "Select"
					selectBtn.TextColor3 = COLORS.Text
					selectBtn.TextSize = 12
					selectBtn.AutoButtonColor = false
					selectBtn.Parent = frame

					createCorner(6).Parent = selectBtn

					selectBtn.MouseButton1Click:Connect(function()
						selectedMoneyAmount = pack.MoneyReward

						for _, child in ipairs(moneyContent:GetChildren()) do
							if child:IsA("Frame") then
								local btn = child:FindFirstChildWhichIsA("TextButton")
								if btn then
									btn.BackgroundColor3 = COLORS.Accent
									btn.Text = "Select"
								end
							end
						end

						selectBtn.BackgroundColor3 = COLORS.Success
						selectBtn.Text = "Selected"
					end)
				end

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

				local giveBtn = createButton("Give Selected Items", COLORS.Success, COLORS.Success)
				giveBtn.Size = UDim2.new(0.94, 0, 0.1, 0)
				giveBtn.Position = UDim2.new(0.03, 0, 0.85, 0)
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
					mainContainer.Visible = true
				end)

			end)

			mainContainer.Visible = false
			playerDetailPanel.Size = UDim2.new(0, 0, 0, 0)
			playerDetailPanel.Visible = true
			tweenSize(playerDetailPanel, UDim2.new(0.25, 0, 0.8, 0), 0.3)

	end)

	return card
end

local playerCards = {}

local function removePlayerCard(targetPlayer)
	local userId = targetPlayer.UserId
	if playerCards[userId] then
		playerCards[userId]:Destroy()
		playerCards[userId] = nil
	end
end

local function addPlayerCard(targetPlayer)
	if playerCards[targetPlayer.UserId] then return end
	createPlayerCard(targetPlayer)
end

local function updatePlayerList()
	playerCardIndex = 0

	for _, card in ipairs(playersScroll:GetChildren()) do
		if card:IsA("TextButton") then
			card:Destroy()
		end
	end
	playerCards = {}

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		createPlayerCard(targetPlayer)
		local cards = playersScroll:GetChildren()
		for _, card in ipairs(cards) do
			if card:IsA("TextButton") then
				playerCards[targetPlayer.UserId] = card
			end
		end
	end
end

Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(0.5)
	if not playerCards[newPlayer.UserId] then
		playerCardIndex = playerCardIndex + 1
		createPlayerCard(newPlayer)
		playerCards[newPlayer.UserId] = playersScroll:GetChildren()[#playersScroll:GetChildren()]
	end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	task.wait(0.1)
	if playerCards[leavingPlayer.UserId] then
		playerCards[leavingPlayer.UserId]:Destroy()
		playerCards[leavingPlayer.UserId] = nil
	end
end)

updatePlayerList()

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(searchBox.Text)
	currentSearchQuery = query

	for _, card in ipairs(playersScroll:GetChildren()) do
		if card:IsA("TextButton") then
			local nameLabel = card:FindFirstChild("TextLabel")
			if nameLabel then
				local playerName = string.lower(nameLabel.Text or "")
				if query == "" or string.find(playerName, query, 1, true) then
					card.Visible = true
				else
					card.Visible = false
				end
			end
		end
	end
end)

makeDraggable(mainPanel, header)
makeDraggable(playerDetailPanel, detailHeader)

notifTabBtn.BackgroundColor3 = COLORS.Accent
notifTabBtn.TextColor3 = COLORS.Text
notifTab.Visible = true
currentTab = notifTab
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
eventsLayout.Padding = UDim.new(0, 10)
eventsLayout.SortOrder = Enum.SortOrder.LayoutOrder
eventsLayout.Parent = eventsScroll

local eventsTitle = Instance.new("TextLabel")
eventsTitle.Size = UDim2.new(1, 0, 0, 30)
eventsTitle.BackgroundTransparency = 1
eventsTitle.Font = Enum.Font.GothamBold
eventsTitle.Text = "🎉 Global Event Manager"
eventsTitle.TextColor3 = COLORS.Text
eventsTitle.TextSize = 18
eventsTitle.TextScaled = false
eventsTitle.TextXAlignment = Enum.TextXAlignment.Left
eventsTitle.LayoutOrder = 1
eventsTitle.Parent = eventsScroll

local eventsDesc = Instance.new("TextLabel")
eventsDesc.Size = UDim2.new(1, 0, 0, 40)
eventsDesc.BackgroundTransparency = 1
eventsDesc.Font = Enum.Font.Gotham
eventsDesc.Text = "Activate events to boost summit rewards across ALL servers"
eventsDesc.TextColor3 = COLORS.TextSecondary
eventsDesc.TextSize = 13
eventsDesc.TextWrapped = true
eventsDesc.TextXAlignment = Enum.TextXAlignment.Left
eventsDesc.LayoutOrder = 2
eventsDesc.Parent = eventsScroll

local EventConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EventConfig"))

local eventRemotes = ReplicatedStorage:WaitForChild("EventRemotes")
local getActiveEventFunc = eventRemotes:WaitForChild("GetActiveEvent")
local setEventRemote = eventRemotes:WaitForChild("SetEvent")
local eventChangedRemote = eventRemotes:WaitForChild("EventChanged")

local currentActiveEventId = nil

task.spawn(function()
	local success, activeEvent = pcall(function()
		return getActiveEventFunc:InvokeServer()
	end)

	if success and activeEvent then
		currentActiveEventId = activeEvent.Id
	end
end)

for i, event in ipairs(EventConfig.AvailableEvents) do
	local eventCard = Instance.new("Frame")
	eventCard.Size = UDim2.new(1, 0, 0, 120)
	eventCard.BackgroundColor3 = COLORS.Panel
	eventCard.BorderSizePixel = 0
	eventCard.LayoutOrder = 2 + i
	eventCard.Parent = eventsScroll

	createCorner(8).Parent = eventCard

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.1, 0, 0, 50)
	iconLabel.Position = UDim2.new(0.02, 0, 0.5, -25)
	iconLabel.AnchorPoint = Vector2.new(0, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = event.Icon
	iconLabel.TextSize = 32
	iconLabel.TextScaled = false
	iconLabel.Parent = eventCard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0, 30)
	nameLabel.Position = UDim2.new(0.13, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = event.Name
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 16
	nameLabel.TextScaled = false
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = eventCard

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.5, 0, 0, 25)
	descLabel.Position = UDim2.new(0.13, 0, 0.45, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = event.Description
	descLabel.TextColor3 = COLORS.TextSecondary
	descLabel.TextSize = 12
	descLabel.TextScaled = false
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = eventCard

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(0.12, 0, 0, 30)
	badgeLabel.Position = UDim2.new(0.13, 0, 0.7, 0)
	badgeLabel.BackgroundColor3 = event.Color
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.Text = "x" .. event.Multiplier
	badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeLabel.TextSize = 14
	badgeLabel.TextScaled = false
	badgeLabel.Parent = eventCard

	createCorner(6).Parent = badgeLabel

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0.28, 0, 0.42, 0)
	toggleBtn.Position = UDim2.new(0.7, 0, 0.29, 0)
	toggleBtn.BackgroundColor3 = COLORS.Button
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Text = "Activate"
	toggleBtn.TextColor3 = COLORS.Text
	toggleBtn.TextSize = 14
	toggleBtn.TextScaled = true
	toggleBtn.AutoButtonColor = false
	toggleBtn.Parent = eventCard

	createCorner(8).Parent = toggleBtn

	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 14
	textSizeConstraint.MinTextSize = 10
	textSizeConstraint.Parent = toggleBtn

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

	toggleBtn.MouseButton1Click:Connect(function()
		if currentActiveEventId == event.Id then
			showConfirmation(
				"Deactivate Event?",
				"Deactivate " .. event.Name .. "?\nSummit rewards will return to normal.",
				function()
					setEventRemote:FireServer("deactivate")
					currentActiveEventId = nil

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
			showConfirmation(
				"Activate Event?",
				string.format("Activate %s?\nAll players on ALL servers will get x%d Summit rewards!", event.Name, event.Multiplier),
				function()
					setEventRemote:FireServer("activate", event.Id)
					currentActiveEventId = event.Id

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

	toggleBtn.MouseEnter:Connect(function()
		if currentActiveEventId ~= event.Id then
			toggleBtn.BackgroundColor3 = COLORS.ButtonHover
		end
	end)

	toggleBtn.MouseLeave:Connect(function()
		updateButtonState()
	end)
end

eventChangedRemote.OnClientEvent:Connect(function(newActiveEvent)
	if newActiveEvent then
		currentActiveEventId = newActiveEvent.Id
	else
		currentActiveEventId = nil
	end

	for _, card in pairs(eventsScroll:GetChildren()) do
		if card:IsA("Frame") then
			local toggleBtn = card:FindFirstChildWhichIsA("TextButton")
			if toggleBtn then
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
leaderboardLayout.Padding = UDim.new(0, 10)
leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
leaderboardLayout.Parent = leaderboardScroll

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0, 50)
searchFrame.BackgroundTransparency = 1
searchFrame.LayoutOrder = 1
searchFrame.Parent = leaderboardScroll

local searchLabel = Instance.new("TextLabel")
searchLabel.Size = UDim2.new(1, 0, 0, 20)
searchLabel.BackgroundTransparency = 1
searchLabel.Font = Enum.Font.GothamBold
searchLabel.Text = "Search Player(s)"
searchLabel.TextColor3 = COLORS.Text
searchLabel.TextSize = 14
searchLabel.TextXAlignment = Enum.TextXAlignment.Left
searchLabel.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.82, 0, 0, 35)
searchBox.Position = UDim2.new(0, 0, 0, 25)
searchBox.BackgroundColor3 = COLORS.Panel
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Enter username(s), separate with comma (max 5)"
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.TextSize = 13
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame

createCorner(6).Parent = searchBox
createPadding(10).Parent = searchBox

local searchButton = Instance.new("TextButton")
searchButton.Size = UDim2.new(0.15, 0, 0, 35)
searchButton.Position = UDim2.new(0.84, 0, 0, 25)
searchButton.BackgroundColor3 = COLORS.Accent
searchButton.BorderSizePixel = 0
searchButton.Font = Enum.Font.GothamBold
searchButton.Text = "🔍"
searchButton.TextColor3 = COLORS.Text
searchButton.TextSize = 18
searchButton.AutoButtonColor = false
searchButton.Parent = searchFrame

createCorner(6).Parent = searchButton

local resultsContainer = Instance.new("Frame")
resultsContainer.Size = UDim2.new(1, 0, 0, 0)
resultsContainer.BackgroundTransparency = 1
resultsContainer.LayoutOrder = 2
resultsContainer.Parent = leaderboardScroll

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.Padding = UDim.new(0, 8)
resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultsLayout.Parent = resultsContainer

resultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	resultsContainer.Size = UDim2.new(1, 0, 0, resultsLayout.AbsoluteContentSize.Y)
end)

local deleteAllFrame = Instance.new("Frame")
deleteAllFrame.Size = UDim2.new(1, 0, 0, 50)
deleteAllFrame.BackgroundTransparency = 1
deleteAllFrame.LayoutOrder = 3
deleteAllFrame.Visible = false
deleteAllFrame.Parent = leaderboardScroll

local deleteAllButton = createButton("🗑️ Delete All Selected Players", COLORS.Danger, COLORS.DangerHover)
deleteAllButton.Size = UDim2.new(1, 0, 1, 0)
deleteAllButton.Parent = deleteAllFrame

local viewerSeparator = Instance.new("Frame")
viewerSeparator.Size = UDim2.new(1, 0, 0, 1)
viewerSeparator.BackgroundColor3 = COLORS.Border
viewerSeparator.LayoutOrder = 4
viewerSeparator.Parent = leaderboardScroll

local viewerTitleFrame = Instance.new("Frame")
viewerTitleFrame.Size = UDim2.new(1, 0, 0, 30)
viewerTitleFrame.BackgroundTransparency = 1
viewerTitleFrame.LayoutOrder = 5
viewerTitleFrame.Parent = leaderboardScroll

local viewerTitle = Instance.new("TextLabel")
viewerTitle.Size = UDim2.new(1, 0, 1, 0)
viewerTitle.BackgroundTransparency = 1
viewerTitle.Font = Enum.Font.GothamBold
viewerTitle.Text = "📊 Leaderboard Viewer"
viewerTitle.TextColor3 = COLORS.Text
viewerTitle.TextSize = 14
viewerTitle.TextXAlignment = Enum.TextXAlignment.Left
viewerTitle.Parent = viewerTitleFrame

local subCategoryFrame = Instance.new("Frame")
subCategoryFrame.Size = UDim2.new(1, 0, 0, 35)
subCategoryFrame.BackgroundTransparency = 1
subCategoryFrame.LayoutOrder = 6
subCategoryFrame.Parent = leaderboardScroll

local subCategoryLayout = Instance.new("UIListLayout")
subCategoryLayout.FillDirection = Enum.FillDirection.Horizontal
subCategoryLayout.Padding = UDim.new(0, 6)
subCategoryLayout.Parent = subCategoryFrame

local currentLeaderboardType = "summit"
local leaderboardSubButtons = {}

local function createSubCategoryButton(text, leaderboardType, icon)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.24, -5, 1, 0)
	btn.BackgroundColor3 = COLORS.Button
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = icon .. " " .. text
	btn.TextColor3 = COLORS.TextSecondary
	btn.TextSize = 11
	btn.TextScaled = true
	btn.AutoButtonColor = false
	btn.Parent = subCategoryFrame

	createCorner(6).Parent = btn

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 12
	textConstraint.MinTextSize = 8
	textConstraint.Parent = btn

	leaderboardSubButtons[leaderboardType] = btn
	return btn, leaderboardType
end

local summitBtn = createSubCategoryButton("Summit", "summit", "🏔️")
local speedrunBtn = createSubCategoryButton("Speedrun", "speedrun", "⏱️")
local donateBtn = createSubCategoryButton("Donate", "donate", "💎")
local playtimeBtn = createSubCategoryButton("Playtime", "playtime", "⌚")

local viewerContainer = Instance.new("Frame")
viewerContainer.Size = UDim2.new(1, 0, 0, 300)
viewerContainer.BackgroundColor3 = COLORS.Panel
viewerContainer.BorderSizePixel = 0
viewerContainer.LayoutOrder = 7
viewerContainer.Parent = leaderboardScroll

createCorner(8).Parent = viewerContainer

local viewerScroll = Instance.new("ScrollingFrame")
viewerScroll.Size = UDim2.new(1, -10, 1, -10)
viewerScroll.Position = UDim2.new(0, 5, 0, 5)
viewerScroll.BackgroundTransparency = 1
viewerScroll.BorderSizePixel = 0
viewerScroll.ScrollBarThickness = 4
viewerScroll.ScrollBarImageColor3 = COLORS.Border
viewerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
viewerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
viewerScroll.Parent = viewerContainer

local viewerLayout = Instance.new("UIListLayout")
viewerLayout.Padding = UDim.new(0, 4)
viewerLayout.SortOrder = Enum.SortOrder.LayoutOrder
viewerLayout.Parent = viewerScroll

local loadingLabel = Instance.new("TextLabel")
loadingLabel.Size = UDim2.new(1, 0, 0, 40)
loadingLabel.BackgroundTransparency = 1
loadingLabel.Font = Enum.Font.GothamMedium
loadingLabel.Text = "Click a category to load leaderboard..."
loadingLabel.TextColor3 = COLORS.TextSecondary
loadingLabel.TextSize = 12
loadingLabel.Parent = viewerScroll

local function createLeaderboardRow(data, leaderboardType)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 35)
	row.BackgroundColor3 = COLORS.Button
	row.BorderSizePixel = 0
	row.LayoutOrder = data.Rank
	row.Parent = viewerScroll

	createCorner(6).Parent = row

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0.08, 0, 1, 0)
	rankLabel.Position = UDim2.new(0.02, 0, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.Text = "#" .. data.Rank
	rankLabel.TextColor3 = data.Rank <= 3 and COLORS.Accent or COLORS.Text
	rankLabel.TextSize = 12
	rankLabel.TextScaled = true
	rankLabel.Parent = row

	local rankConstraint = Instance.new("UITextSizeConstraint")
	rankConstraint.MaxTextSize = 14
	rankConstraint.MinTextSize = 10
	rankConstraint.Parent = rankLabel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.1, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = data.Username
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 12
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 13
	nameConstraint.MinTextSize = 9
	nameConstraint.Parent = nameLabel

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.25, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = data.FormattedValue
	valueLabel.TextColor3 = COLORS.Accent
	valueLabel.TextSize = 12
	valueLabel.TextScaled = true
	valueLabel.Parent = row

	local valueConstraint = Instance.new("UITextSizeConstraint")
	valueConstraint.MaxTextSize = 13
	valueConstraint.MinTextSize = 9
	valueConstraint.Parent = valueLabel

	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
	deleteBtn.Position = UDim2.new(0.82, 0, 0.15, 0)
	deleteBtn.BackgroundColor3 = COLORS.Danger
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.Text = "🗑️"
	deleteBtn.TextColor3 = COLORS.Text
	deleteBtn.TextSize = 14
	deleteBtn.AutoButtonColor = false
	deleteBtn.Parent = row

	createCorner(4).Parent = deleteBtn

	deleteBtn.MouseButton1Click:Connect(function()
		local deleteLeaderboardEvent = remoteFolder:FindFirstChild("DeleteLeaderboard")
		if deleteLeaderboardEvent then
			deleteLeaderboardEvent:FireServer(data.UserId, leaderboardType)
			row:Destroy()

			game.StarterGui:SetCore("SendNotification", {
				Title = "Deleted",
				Text = string.format("Deleted %s from %s leaderboard", data.Username, leaderboardType),
				Duration = 3,
			})
		end
	end)

	deleteBtn.MouseEnter:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.DangerHover or Color3.fromRGB(255, 80, 80)}):Play()
	end)
	deleteBtn.MouseLeave:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Danger}):Play()
	end)

	return row
end

local function loadLeaderboard(leaderboardType)
	for _, child in ipairs(viewerScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	loadingLabel.Text = "⏳ Loading " .. leaderboardType .. " leaderboard..."
	loadingLabel.Visible = true

	for type, btn in pairs(leaderboardSubButtons) do
		if type == leaderboardType then
			btn.BackgroundColor3 = COLORS.Accent
			btn.TextColor3 = COLORS.Text
		else
			btn.BackgroundColor3 = COLORS.Button
			btn.TextColor3 = COLORS.TextSecondary
		end
	end

	currentLeaderboardType = leaderboardType

	local getLeaderboardFunc = remoteFolder:FindFirstChild("GetLeaderboardData")
	if not getLeaderboardFunc then
		loadingLabel.Text = "❌ Leaderboard function not available!"
		return
	end

	local success, result = pcall(function()
		return getLeaderboardFunc:InvokeServer(leaderboardType, 50)
	end)

	if success and result and result.success then
		loadingLabel.Visible = false

		if #result.data == 0 then
			loadingLabel.Text = "📭 No entries found in " .. leaderboardType .. " leaderboard"
			loadingLabel.Visible = true
			return
		end

		for _, entry in ipairs(result.data) do
			createLeaderboardRow(entry, leaderboardType)
		end
	else
		loadingLabel.Text = "❌ Failed to load leaderboard data"
		loadingLabel.Visible = true
	end
end

for leaderboardType, btn in pairs(leaderboardSubButtons) do
	btn.MouseButton1Click:Connect(function()
		loadLeaderboard(leaderboardType)
	end)

	btn.MouseEnter:Connect(function()
		if currentLeaderboardType ~= leaderboardType then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.ButtonHover or COLORS.Border}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentLeaderboardType ~= leaderboardType then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Button}):Play()
		end
	end)
end

local searchResults = {}

local function createLeaderboardCard(data)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 180)
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.Parent = resultsContainer

	createCorner(8).Parent = card

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 60, 0, 60)
	avatar.Position = UDim2.new(0, 10, 0, 10)
	avatar.BackgroundColor3 = COLORS.Button
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. data.UserId .. "&w=150&h=150"
	avatar.Parent = card

	createCorner(30).Parent = avatar

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -85, 0, 25)
	nameLabel.Position = UDim2.new(0, 75, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = data.Username
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local idLabel = Instance.new("TextLabel")
	idLabel.Size = UDim2.new(1, -85, 0, 20)
	idLabel.Position = UDim2.new(0, 75, 0, 35)
	idLabel.BackgroundTransparency = 1
	idLabel.Font = Enum.Font.Gotham
	idLabel.Text = "ID: " .. data.UserId
	idLabel.TextColor3 = COLORS.TextSecondary
	idLabel.TextSize = 12
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Parent = card

	local statsY = 75
	local stats = {
		{icon = "🏔️", label = "Summit", value = tostring(data.Summit)},
		{icon = "⏱️", label = "Speedrun", value = data.Speedrun},
		{icon = "⌚", label = "Playtime", value = string.format("%dh %dm", math.floor(data.Playtime / 3600), math.floor((data.Playtime % 3600) / 60))},
		{icon = "💎", label = "Donate", value = "R$" .. tostring(data.Donate)}
	}

	for i, stat in ipairs(stats) do
		local statFrame = Instance.new("Frame")
		statFrame.Size = UDim2.new(0.48, 0, 0, 20)
		statFrame.Position = UDim2.new((i - 1) % 2 == 0 and 0.02 or 0.5, 0, 0, statsY + math.floor((i - 1) / 2) * 25)
		statFrame.BackgroundTransparency = 1
		statFrame.Parent = card

		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(1, 0, 1, 0)
		statLabel.BackgroundTransparency = 1
		statLabel.Font = Enum.Font.Gotham
		statLabel.Text = stat.icon .. " " .. stat.label .. ": " .. stat.value
		statLabel.TextColor3 = COLORS.TextSecondary
		statLabel.TextSize = 12
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Parent = statFrame
	end

	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Size = UDim2.new(0.96, 0, 0, 35)
	deleteBtn.Position = UDim2.new(0.02, 0, 1, -45)
	deleteBtn.BackgroundColor3 = COLORS.Danger
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.Text = "🗑️ Delete Data"
	deleteBtn.TextColor3 = COLORS.Text
	deleteBtn.TextSize = 13
	deleteBtn.AutoButtonColor = false
	deleteBtn.Parent = card

	createCorner(6).Parent = deleteBtn

	deleteBtn.MouseEnter:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.DangerHover}):Play()
	end)

	deleteBtn.MouseLeave:Connect(function()
		TweenService:Create(deleteBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Danger}):Play()
	end)

	deleteBtn.MouseButton1Click:Connect(function()
		local deletePopup = Instance.new("Frame")
		deletePopup.Size = UDim2.new(0, 320, 0, 280)
		deletePopup.Position = UDim2.new(0.5, 0, 0.5, 0)
		deletePopup.AnchorPoint = Vector2.new(0.5, 0.5)
		deletePopup.BackgroundColor3 = COLORS.Background
		deletePopup.BorderSizePixel = 0
		deletePopup.ZIndex = 200
		deletePopup.Parent = screenGui

		createCorner(12).Parent = deletePopup
		createStroke(COLORS.Border, 2).Parent = deletePopup

		local popupHeader = Instance.new("Frame")
		popupHeader.Size = UDim2.new(1, 0, 0, 50)
		popupHeader.BackgroundColor3 = COLORS.Header
		popupHeader.BorderSizePixel = 0
		popupHeader.Parent = deletePopup

		createCorner(12).Parent = popupHeader

		local headerBottom = Instance.new("Frame")
		headerBottom.Size = UDim2.new(1, 0, 0, 15)
		headerBottom.Position = UDim2.new(0, 0, 1, -15)
		headerBottom.BackgroundColor3 = COLORS.Header
		headerBottom.BorderSizePixel = 0
		headerBottom.Parent = popupHeader

		local popupTitle = Instance.new("TextLabel")
		popupTitle.Size = UDim2.new(1, -50, 1, 0)
		popupTitle.Position = UDim2.new(0, 15, 0, 0)
		popupTitle.BackgroundTransparency = 1
		popupTitle.Font = Enum.Font.GothamBold
		popupTitle.Text = "Delete " .. data.Username .. "'s Data"
		popupTitle.TextColor3 = COLORS.Text
		popupTitle.TextSize = 14
		popupTitle.TextXAlignment = Enum.TextXAlignment.Left
		popupTitle.Parent = popupHeader

		local closePopupBtn = Instance.new("TextButton")
		closePopupBtn.Size = UDim2.new(0, 30, 0, 30)
		closePopupBtn.Position = UDim2.new(1, -40, 0, 10)
		closePopupBtn.BackgroundColor3 = COLORS.Button
		closePopupBtn.BorderSizePixel = 0
		closePopupBtn.Text = "✕"
		closePopupBtn.Font = Enum.Font.GothamBold
		closePopupBtn.TextSize = 16
		closePopupBtn.TextColor3 = COLORS.Text
		closePopupBtn.Parent = popupHeader

		createCorner(6).Parent = closePopupBtn

		closePopupBtn.MouseButton1Click:Connect(function()
			deletePopup:Destroy()
		end)

		local yPos = 65
		local deleteOptions = {
			{text = "Delete Summit Data", type = "summit"},
			{text = "Delete Speedrun Data", type = "speedrun"},
			{text = "Delete Playtime Data", type = "playtime"},
			{text = "Delete Donation Data", type = "donate"},
			{text = "DELETE ALL DATA", type = "all", isAll = true}
		}

		for _, option in ipairs(deleteOptions) do
			local optionBtn = Instance.new("TextButton")
			optionBtn.Size = UDim2.new(1, -30, 0, 38)
			optionBtn.Position = UDim2.new(0, 15, 0, yPos)
			optionBtn.BackgroundColor3 = option.isAll and COLORS.Danger or COLORS.Button
			optionBtn.BorderSizePixel = 0
			optionBtn.Font = Enum.Font.GothamBold
			optionBtn.Text = option.text
			optionBtn.TextColor3 = COLORS.Text
			optionBtn.TextSize = 12
			optionBtn.AutoButtonColor = false
			optionBtn.Parent = deletePopup

			createCorner(6).Parent = optionBtn

			optionBtn.MouseButton1Click:Connect(function()
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

searchButton.MouseButton1Click:Connect(function()
	if searchBox.Text == "" then
		game.StarterGui:SetCore("SendNotification", {
			Title = "Search Error",
			Text = "Please enter at least one username!",
			Duration = 3,
		})
		return
	end

	for _, child in pairs(resultsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	searchResults = {}

	local usernames = {}
	for username in string.gmatch(searchBox.Text, "[^,]+") do
		local trimmed = string.match(username, "^%s*(.-)%s*$")
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
	tweenSize(confirmDialog, UDim2.new(0, 380, 0, 200), 0.3)
end)

if not hasPrimaryAccess then
	if notifTabBtn then
		notifTabBtn.Visible = false
		notifTabBtn.Active = false
	end
	if notifTab then
		notifTab.Visible = false
	end

	if eventsTabBtn then
		eventsTabBtn.Visible = false
		eventsTabBtn.Active = false
	end
	if eventsTab then
		eventsTab.Visible = false
	end

	if playersTab and playersTabBtn then
		playersTab.Visible = true
		playersTabBtn.BackgroundColor3 = COLORS.Accent
		playersTabBtn.TextColor3 = COLORS.Text
		currentTab = playersTab
	end

	for _, tabBtn in ipairs(tabContainer:GetChildren()) do
		if tabBtn:IsA("TextButton") and tabBtn.Visible then
			tabBtn.Size = UDim2.new(0.49, 0, 1, 0)
		end
	end

else
	if notifTab and notifTabBtn then
		notifTab.Visible = true
		notifTabBtn.BackgroundColor3 = COLORS.Accent
		notifTabBtn.TextColor3 = COLORS.Text
		currentTab = notifTab
	end

end

local isOpen = false

local closeAdminPanel
local openAdminPanel

closeAdminPanel = function()
	if not isOpen then return end
	isOpen = false
	for _, child in ipairs(contentContainer:GetChildren()) do
		child.Visible = false
	end

	tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		mainPanel.Visible = false
		mainPanel.Size = UDim2.new(1, 0, 1, 0)
		if currentTab then
			currentTab.Visible = true
		end
	end)
	PanelManager:Close("AdminPanel")
end

openAdminPanel = function()
	PanelManager:Open("AdminPanel")
	isOpen = true
	mainPanel.Size = UDim2.new(0, 0, 0, 0)
	mainPanel.Visible = true
	tweenSize(mainPanel, UDim2.new(1, 0, 1, 0), 0.3)
end

PanelManager:Register("AdminPanel", closeAdminPanel)

if topbarPlusLoaded and Icon then
	local adminIcon = Icon.new()
	adminIcon:setLabel("Admin")
	adminIcon:setImage("rbxassetid://128692376033664")

	adminIcon.selected:Connect(function()
		openAdminPanel()
	end)

	adminIcon.deselected:Connect(function()
		closeAdminPanel()
	end)

	closeButton.MouseButton1Click:Connect(function()
		adminIcon:deselect()
	end)

else
	warn("Using fallback admin button")

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

	local fallbackButton = Instance.new("ScreenGui")
	fallbackButton.Name = "AdminButton"
	fallbackButton.ResetOnSpawn = false
	fallbackButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fallbackButton.DisplayOrder = 999
	fallbackButton.Parent = playerGui

	local buttonFrame = Instance.new("TextButton")
	buttonFrame.Size = UDim2.new(0.063, 0, 0.037, 0)
	buttonFrame.Position = UDim2.new(0.005, 0, 0.009, 0)
	buttonFrame.BackgroundColor3 = COLORS.Panel
	buttonFrame.BorderSizePixel = 0
	buttonFrame.Font = Enum.Font.GothamBold
	buttonFrame.Text = ""
	buttonFrame.AutoButtonColor = false
	buttonFrame.Parent = fallbackButton

	createCorner(8).Parent = buttonFrame
	createStroke(COLORS.Border, 2).Parent = buttonFrame

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.Position = UDim2.new(0, 8, 0, 8)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://7733954760"
	icon.ImageColor3 = COLORS.Text
	icon.Parent = buttonFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 40, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "Admin"
	label.TextColor3 = COLORS.Text
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = buttonFrame

	buttonFrame.MouseButton1Click:Connect(function()
		if isOpen then
			closeAdminPanel()
			buttonFrame.BackgroundColor3 = COLORS.Panel
		else
			openAdminPanel()
			buttonFrame.BackgroundColor3 = COLORS.Accent
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

	closeButton.MouseButton1Click:Connect(function()
		closeAdminPanel()
		buttonFrame.BackgroundColor3 = COLORS.Panel
	end)

end
