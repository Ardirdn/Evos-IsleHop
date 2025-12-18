local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
	SHOW_CHECKPOINT_BUTTON = true,
}

if not CONFIG.SHOW_CHECKPOINT_BUTTON then
	return
end

local checkpointRemotes = ReplicatedStorage:WaitForChild("CheckpointRemotes", 30)
if not checkpointRemotes then
	warn("[CHECKPOINT CLIENT] CheckpointRemotes not found!")
	return
end

local teleportToBasecamp = checkpointRemotes:WaitForChild("TeleportToBasecamp", 10)
local skipCheckpoint = checkpointRemotes:WaitForChild("SkipCheckpoint", 10)
local toggleSwimmingMode = checkpointRemotes:WaitForChild("ToggleSwimmingMode", 10)
local getSwimmingStatus = checkpointRemotes:WaitForChild("GetSwimmingStatus", 10)
local swimmingModeChanged = checkpointRemotes:WaitForChild("SwimmingModeChanged", 10)

if not teleportToBasecamp or not skipCheckpoint then
	warn("[CHECKPOINT CLIENT] Remote events not found!")
	return
end

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
	SuccessHover = Color3.fromRGB(87, 201, 149),
	Border = Color3.fromRGB(50, 50, 55),
	Swimming = Color3.fromRGB(255, 159, 67),
	SwimmingHover = Color3.fromRGB(255, 179, 97),
}

local isSwimmingMode = false

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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheckpointGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

local cpButton = Instance.new("TextButton")
cpButton.Name = "CPButton"
cpButton.Size = UDim2.new(0.06, 0, 0.1, 0)
cpButton.Position = UDim2.new(0.93, 0, 0.45, 0)
cpButton.AnchorPoint = Vector2.new(0.5, 0.5)
cpButton.BackgroundColor3 = COLORS.Panel
cpButton.BorderSizePixel = 0
cpButton.Text = ""
cpButton.AutoButtonColor = false
cpButton.Parent = screenGui

createCorner(8).Parent = cpButton
createStroke(COLORS.Border, 2).Parent = cpButton

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(1, 0, 0.6, 0)
icon.Position = UDim2.new(0, 0, 0.1, 0)
icon.BackgroundTransparency = 1
icon.Font = Enum.Font.GothamBold
icon.Text = "⛰️"
icon.TextColor3 = COLORS.Text
icon.TextScaled = true
icon.Parent = cpButton

local iconConstraint = Instance.new("UITextSizeConstraint")
iconConstraint.MaxTextSize = 32
iconConstraint.Parent = icon

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.3, 0)
label.Position = UDim2.new(0, 0, 0.68, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.Text = "CP"
label.TextColor3 = COLORS.TextSecondary
label.TextScaled = true
label.Parent = cpButton

local labelConstraint = Instance.new("UITextSizeConstraint")
labelConstraint.MaxTextSize = 14
labelConstraint.MinTextSize = 10
labelConstraint.Parent = label

local popupPanel = Instance.new("Frame")
popupPanel.Name = "PopupPanel"
popupPanel.Size = UDim2.new(0.28, 0, 0.48, 0)
popupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
popupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
popupPanel.BackgroundColor3 = COLORS.Background
popupPanel.BorderSizePixel = 0
popupPanel.Visible = false
popupPanel.Parent = screenGui

createCorner(12).Parent = popupPanel
createStroke(COLORS.Border, 2).Parent = popupPanel

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = popupPanel

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
title.Text = "⛰️ Checkpoint Menu"
title.TextColor3 = COLORS.Text
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "✕"
closeButton.TextColor3 = COLORS.Text
closeButton.TextSize = 18
closeButton.Parent = header

createCorner(6).Parent = closeButton

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 60)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = popupPanel

local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(1, 0, 0.28, 0)
resetButton.Position = UDim2.new(0, 0, 0.02, 0)
resetButton.BackgroundColor3 = COLORS.Danger
resetButton.BorderSizePixel = 0
resetButton.Text = ""
resetButton.AutoButtonColor = false
resetButton.Parent = contentContainer

createCorner(8).Parent = resetButton
createStroke(Color3.fromRGB(200, 50, 50), 2).Parent = resetButton

local resetIcon = Instance.new("TextLabel")
resetIcon.Size = UDim2.new(1, 0, 0.5, 0)
resetIcon.Position = UDim2.new(0, 0, 0.1, 0)
resetIcon.BackgroundTransparency = 1
resetIcon.Font = Enum.Font.GothamBold
resetIcon.Text = "🏕️"
resetIcon.TextColor3 = COLORS.Text
resetIcon.TextScaled = true
resetIcon.Parent = resetButton

local resetIconConstraint = Instance.new("UITextSizeConstraint")
resetIconConstraint.MaxTextSize = 32
resetIconConstraint.Parent = resetIcon

local resetText = Instance.new("TextLabel")
resetText.Size = UDim2.new(1, 0, 0.4, 0)
resetText.Position = UDim2.new(0, 0, 0.58, 0)
resetText.BackgroundTransparency = 1
resetText.Font = Enum.Font.GothamBold
resetText.Text = "RESET TO BASECAMP"
resetText.TextColor3 = COLORS.Text
resetText.TextScaled = true
resetText.Parent = resetButton

local resetTextConstraint = Instance.new("UITextSizeConstraint")
resetTextConstraint.MaxTextSize = 14
resetTextConstraint.MinTextSize = 10
resetTextConstraint.Parent = resetText

local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(1, 0, 0.28, 0)
skipButton.Position = UDim2.new(0, 0, 0.35, 0)
skipButton.BackgroundColor3 = COLORS.Accent
skipButton.BorderSizePixel = 0
skipButton.Text = ""
skipButton.AutoButtonColor = false
skipButton.Parent = contentContainer

createCorner(8).Parent = skipButton
createStroke(Color3.fromRGB(70, 80, 200), 2).Parent = skipButton

local skipIcon = Instance.new("TextLabel")
skipIcon.Size = UDim2.new(1, 0, 0.5, 0)
skipIcon.Position = UDim2.new(0, 0, 0.1, 0)
skipIcon.BackgroundTransparency = 1
skipIcon.Font = Enum.Font.GothamBold
skipIcon.Text = "⚡"
skipIcon.TextColor3 = COLORS.Text
skipIcon.TextScaled = true
skipIcon.Parent = skipButton

local skipIconConstraint = Instance.new("UITextSizeConstraint")
skipIconConstraint.MaxTextSize = 32
skipIconConstraint.Parent = skipIcon

local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1, 0, 0.4, 0)
skipText.Position = UDim2.new(0, 0, 0.58, 0)
skipText.BackgroundTransparency = 1
skipText.Font = Enum.Font.GothamBold
skipText.Text = "SKIP CHECKPOINT"
skipText.TextColor3 = COLORS.Text
skipText.TextScaled = true
skipText.Parent = skipButton

local skipTextConstraint = Instance.new("UITextSizeConstraint")
skipTextConstraint.MaxTextSize = 14
skipTextConstraint.MinTextSize = 10
skipTextConstraint.Parent = skipText

local swimmingButton = Instance.new("TextButton")
swimmingButton.Name = "SwimmingButton"
swimmingButton.Size = UDim2.new(1, 0, 0.28, 0)
swimmingButton.Position = UDim2.new(0, 0, 0.68, 0)
swimmingButton.BackgroundColor3 = COLORS.Panel
swimmingButton.BorderSizePixel = 0
swimmingButton.Text = ""
swimmingButton.AutoButtonColor = false
swimmingButton.Parent = contentContainer

createCorner(8).Parent = swimmingButton
local swimmingStroke = createStroke(COLORS.Swimming, 2)
swimmingStroke.Parent = swimmingButton

local swimmingIcon = Instance.new("TextLabel")
swimmingIcon.Size = UDim2.new(1, 0, 0.5, 0)
swimmingIcon.Position = UDim2.new(0, 0, 0.1, 0)
swimmingIcon.BackgroundTransparency = 1
swimmingIcon.Font = Enum.Font.GothamBold
swimmingIcon.Text = "🏊"
swimmingIcon.TextColor3 = COLORS.Text
swimmingIcon.TextScaled = true
swimmingIcon.Parent = swimmingButton

local swimmingIconConstraint = Instance.new("UITextSizeConstraint")
swimmingIconConstraint.MaxTextSize = 32
swimmingIconConstraint.Parent = swimmingIcon

local swimmingText = Instance.new("TextLabel")
swimmingText.Size = UDim2.new(1, 0, 0.4, 0)
swimmingText.Position = UDim2.new(0, 0, 0.58, 0)
swimmingText.BackgroundTransparency = 1
swimmingText.Font = Enum.Font.GothamBold
swimmingText.Text = "ENABLE SWIMMING"
swimmingText.TextColor3 = COLORS.TextSecondary
swimmingText.TextScaled = true
swimmingText.Parent = swimmingButton

local swimmingTextConstraint = Instance.new("UITextSizeConstraint")
swimmingTextConstraint.MaxTextSize = 14
swimmingTextConstraint.MinTextSize = 10
swimmingTextConstraint.Parent = swimmingText

local confirmPopup = Instance.new("Frame")
confirmPopup.Name = "ConfirmPopup"
confirmPopup.Size = UDim2.new(0.35, 0, 0.35, 0)
confirmPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmPopup.AnchorPoint = Vector2.new(0.5, 0.5)
confirmPopup.BackgroundColor3 = COLORS.Background
confirmPopup.BorderSizePixel = 0
confirmPopup.Visible = false
confirmPopup.ZIndex = 20
confirmPopup.Parent = screenGui

createCorner(12).Parent = confirmPopup
createStroke(COLORS.Border, 2).Parent = confirmPopup

local confirmHeader = Instance.new("Frame")
confirmHeader.Size = UDim2.new(1, 0, 0, 50)
confirmHeader.BackgroundColor3 = COLORS.Header
confirmHeader.BorderSizePixel = 0
confirmHeader.ZIndex = 21
confirmHeader.Parent = confirmPopup

createCorner(12).Parent = confirmHeader

local confirmHeaderBottom = Instance.new("Frame")
confirmHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
confirmHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
confirmHeaderBottom.BackgroundColor3 = COLORS.Header
confirmHeaderBottom.BorderSizePixel = 0
confirmHeaderBottom.ZIndex = 21
confirmHeaderBottom.Parent = confirmHeader

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, -20, 1, 0)
confirmTitle.Position = UDim2.new(0, 10, 0, 0)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Text = "🏊 Enable Swimming Mode?"
confirmTitle.TextColor3 = COLORS.Text
confirmTitle.TextSize = 16
confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
confirmTitle.ZIndex = 22
confirmTitle.Parent = confirmHeader

local confirmContent = Instance.new("Frame")
confirmContent.Size = UDim2.new(1, -30, 1, -120)
confirmContent.Position = UDim2.new(0, 15, 0, 60)
confirmContent.BackgroundTransparency = 1
confirmContent.ZIndex = 21
confirmContent.Parent = confirmPopup

local confirmMessage = Instance.new("TextLabel")
confirmMessage.Size = UDim2.new(1, 0, 1, 0)
confirmMessage.BackgroundTransparency = 1
confirmMessage.Font = Enum.Font.Gotham
confirmMessage.Text = "Fitur ini memungkinkan kamu untuk berenang di air dan menonaktifkan fitur checkpoint.\n\nData checkpoint terakhir kamu akan disimpan."
confirmMessage.TextColor3 = COLORS.TextSecondary
confirmMessage.TextSize = 14
confirmMessage.TextWrapped = true
confirmMessage.TextYAlignment = Enum.TextYAlignment.Top
confirmMessage.ZIndex = 22
confirmMessage.Parent = confirmContent

local confirmButtonsFrame = Instance.new("Frame")
confirmButtonsFrame.Size = UDim2.new(1, -30, 0, 45)
confirmButtonsFrame.Position = UDim2.new(0, 15, 1, -60)
confirmButtonsFrame.BackgroundTransparency = 1
confirmButtonsFrame.ZIndex = 21
confirmButtonsFrame.Parent = confirmPopup

local confirmCancelBtn = Instance.new("TextButton")
confirmCancelBtn.Size = UDim2.new(0.48, 0, 1, 0)
confirmCancelBtn.Position = UDim2.new(0, 0, 0, 0)
confirmCancelBtn.BackgroundColor3 = COLORS.Button
confirmCancelBtn.BorderSizePixel = 0
confirmCancelBtn.Font = Enum.Font.GothamBold
confirmCancelBtn.Text = "Batal"
confirmCancelBtn.TextColor3 = COLORS.Text
confirmCancelBtn.TextSize = 14
confirmCancelBtn.ZIndex = 22
confirmCancelBtn.Parent = confirmButtonsFrame

createCorner(8).Parent = confirmCancelBtn

local confirmAcceptBtn = Instance.new("TextButton")
confirmAcceptBtn.Size = UDim2.new(0.48, 0, 1, 0)
confirmAcceptBtn.Position = UDim2.new(0.52, 0, 0, 0)
confirmAcceptBtn.BackgroundColor3 = COLORS.Accent
confirmAcceptBtn.BorderSizePixel = 0
confirmAcceptBtn.Font = Enum.Font.GothamBold
confirmAcceptBtn.Text = "Lanjutkan"
confirmAcceptBtn.TextColor3 = COLORS.Text
confirmAcceptBtn.TextSize = 14
confirmAcceptBtn.ZIndex = 22
confirmAcceptBtn.Parent = confirmButtonsFrame

createCorner(8).Parent = confirmAcceptBtn

local disablePopup = Instance.new("Frame")
disablePopup.Name = "DisablePopup"
disablePopup.Size = UDim2.new(0.35, 0, 0.3, 0)
disablePopup.Position = UDim2.new(0.5, 0, 0.5, 0)
disablePopup.AnchorPoint = Vector2.new(0.5, 0.5)
disablePopup.BackgroundColor3 = COLORS.Background
disablePopup.BorderSizePixel = 0
disablePopup.Visible = false
disablePopup.ZIndex = 20
disablePopup.Parent = screenGui

createCorner(12).Parent = disablePopup
createStroke(COLORS.Border, 2).Parent = disablePopup

local disableHeader = Instance.new("Frame")
disableHeader.Size = UDim2.new(1, 0, 0, 50)
disableHeader.BackgroundColor3 = COLORS.Header
disableHeader.BorderSizePixel = 0
disableHeader.ZIndex = 21
disableHeader.Parent = disablePopup

createCorner(12).Parent = disableHeader

local disableHeaderBottom = Instance.new("Frame")
disableHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
disableHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
disableHeaderBottom.BackgroundColor3 = COLORS.Header
disableHeaderBottom.BorderSizePixel = 0
disableHeaderBottom.ZIndex = 21
disableHeaderBottom.Parent = disableHeader

local disableTitle = Instance.new("TextLabel")
disableTitle.Size = UDim2.new(1, -20, 1, 0)
disableTitle.Position = UDim2.new(0, 10, 0, 0)
disableTitle.BackgroundTransparency = 1
disableTitle.Font = Enum.Font.GothamBold
disableTitle.Text = "⛰️ Disable Swimming Mode?"
disableTitle.TextColor3 = COLORS.Text
disableTitle.TextSize = 16
disableTitle.TextXAlignment = Enum.TextXAlignment.Left
disableTitle.ZIndex = 22
disableTitle.Parent = disableHeader

local disableContent = Instance.new("Frame")
disableContent.Size = UDim2.new(1, -30, 1, -120)
disableContent.Position = UDim2.new(0, 15, 0, 60)
disableContent.BackgroundTransparency = 1
disableContent.ZIndex = 21
disableContent.Parent = disablePopup

local disableMessage = Instance.new("TextLabel")
disableMessage.Size = UDim2.new(1, 0, 1, 0)
disableMessage.BackgroundTransparency = 1
disableMessage.Font = Enum.Font.Gotham
disableMessage.Text = "Matikan fitur berenang dan teleport ke checkpoint terakhir?"
disableMessage.TextColor3 = COLORS.TextSecondary
disableMessage.TextSize = 14
disableMessage.TextWrapped = true
disableMessage.TextYAlignment = Enum.TextYAlignment.Top
disableMessage.ZIndex = 22
disableMessage.Parent = disableContent

local disableButtonsFrame = Instance.new("Frame")
disableButtonsFrame.Size = UDim2.new(1, -30, 0, 45)
disableButtonsFrame.Position = UDim2.new(0, 15, 1, -60)
disableButtonsFrame.BackgroundTransparency = 1
disableButtonsFrame.ZIndex = 21
disableButtonsFrame.Parent = disablePopup

local disableCancelBtn = Instance.new("TextButton")
disableCancelBtn.Size = UDim2.new(0.48, 0, 1, 0)
disableCancelBtn.Position = UDim2.new(0, 0, 0, 0)
disableCancelBtn.BackgroundColor3 = COLORS.Button
disableCancelBtn.BorderSizePixel = 0
disableCancelBtn.Font = Enum.Font.GothamBold
disableCancelBtn.Text = "Batal"
disableCancelBtn.TextColor3 = COLORS.Text
disableCancelBtn.TextSize = 14
disableCancelBtn.ZIndex = 22
disableCancelBtn.Parent = disableButtonsFrame

createCorner(8).Parent = disableCancelBtn

local disableAcceptBtn = Instance.new("TextButton")
disableAcceptBtn.Size = UDim2.new(0.48, 0, 1, 0)
disableAcceptBtn.Position = UDim2.new(0.52, 0, 0, 0)
disableAcceptBtn.BackgroundColor3 = COLORS.Accent
disableAcceptBtn.BorderSizePixel = 0
disableAcceptBtn.Font = Enum.Font.GothamBold
disableAcceptBtn.Text = "Lanjutkan"
disableAcceptBtn.TextColor3 = COLORS.Text
disableAcceptBtn.TextSize = 14
disableAcceptBtn.ZIndex = 22
disableAcceptBtn.Parent = disableButtonsFrame

createCorner(8).Parent = disableAcceptBtn

local resetCooldownActive = false
local skipCooldownActive = false
local COOLDOWN_TIME = 3

local panelOpen = false

local function updateSwimmingButtonVisual()
	if isSwimmingMode then
		swimmingButton.BackgroundColor3 = COLORS.Swimming
		swimmingStroke.Color = Color3.fromRGB(44, 204, 188)
		swimmingText.Text = "DISABLE SWIMMING"
		swimmingText.TextColor3 = COLORS.Text
		swimmingIcon.Text = "🏊"
	else
		swimmingButton.BackgroundColor3 = COLORS.Panel
		swimmingStroke.Color = COLORS.Swimming
		swimmingText.Text = "ENABLE SWIMMING"
		swimmingText.TextColor3 = COLORS.TextSecondary
		swimmingIcon.Text = "🏊"
	end
end

local function togglePanel()
	panelOpen = not panelOpen

	if panelOpen then
		popupPanel.Size = UDim2.new(0, 0, 0, 0)
		popupPanel.Visible = true
		TweenService:Create(popupPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.28, 0, 0.48, 0)
		}):Play()

		TweenService:Create(cpButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Accent
		}):Play()
	else
		TweenService:Create(popupPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()

		task.delay(0.2, function()
			popupPanel.Visible = false
		end)

		TweenService:Create(cpButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Panel
		}):Play()
	end
end

local function showConfirmPopup()
	popupPanel.Visible = false
	panelOpen = false
	TweenService:Create(cpButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Panel
	}):Play()
	
	confirmPopup.Size = UDim2.new(0, 0, 0, 0)
	confirmPopup.Visible = true
	TweenService:Create(confirmPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.35, 0, 0.35, 0)
	}):Play()
end

local function hideConfirmPopup()
	TweenService:Create(confirmPopup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.delay(0.2, function()
		confirmPopup.Visible = false
	end)
end

local function showDisablePopup()
	popupPanel.Visible = false
	panelOpen = false
	TweenService:Create(cpButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Panel
	}):Play()
	
	disablePopup.Size = UDim2.new(0, 0, 0, 0)
	disablePopup.Visible = true
	TweenService:Create(disablePopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.35, 0, 0.3, 0)
	}):Play()
end

local function hideDisablePopup()
	TweenService:Create(disablePopup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.delay(0.2, function()
		disablePopup.Visible = false
	end)
end

cpButton.MouseButton1Click:Connect(togglePanel)

cpButton.MouseEnter:Connect(function()
	if not panelOpen then
		TweenService:Create(cpButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Button
		}):Play()
	end
end)

cpButton.MouseLeave:Connect(function()
	if not panelOpen then
		TweenService:Create(cpButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Panel
		}):Play()
	end
end)

closeButton.MouseButton1Click:Connect(togglePanel)

resetButton.MouseEnter:Connect(function()
	if resetCooldownActive then return end
	TweenService:Create(resetButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.DangerHover
	}):Play()
end)

resetButton.MouseLeave:Connect(function()
	if resetCooldownActive then return end
	TweenService:Create(resetButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Danger
	}):Play()
end)

skipButton.MouseEnter:Connect(function()
	if skipCooldownActive then return end
	TweenService:Create(skipButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.AccentHover
	}):Play()
end)

skipButton.MouseLeave:Connect(function()
	if skipCooldownActive then return end
	TweenService:Create(skipButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Accent
	}):Play()
end)

swimmingButton.MouseEnter:Connect(function()
	if isSwimmingMode then
		TweenService:Create(swimmingButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.SwimmingHover
		}):Play()
	else
		TweenService:Create(swimmingButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Button
		}):Play()
	end
end)

swimmingButton.MouseLeave:Connect(function()
	if isSwimmingMode then
		TweenService:Create(swimmingButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Swimming
		}):Play()
	else
		TweenService:Create(swimmingButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Panel
		}):Play()
	end
end)

resetButton.MouseButton1Click:Connect(function()
	if resetCooldownActive then
		return
	end

	resetCooldownActive = true
	local originalText = resetText.Text

	TweenService:Create(resetButton, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(150, 30, 30)
	}):Play()

	teleportToBasecamp:FireServer()

	for i = COOLDOWN_TIME, 1, -1 do
		resetText.Text = string.format("⏳ %ds", i)
		task.wait(1)
	end

	resetText.Text = originalText
	resetCooldownActive = false

	TweenService:Create(resetButton, TweenInfo.new(0.3), {
		BackgroundColor3 = COLORS.Danger
	}):Play()
end)

skipButton.MouseButton1Click:Connect(function()
	if skipCooldownActive then
		return
	end

	skipCooldownActive = true
	local originalText = skipText.Text

	TweenService:Create(skipButton, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(60, 70, 180)
	}):Play()

	skipCheckpoint:FireServer()

	togglePanel()

	for i = COOLDOWN_TIME, 1, -1 do
		skipText.Text = string.format("⏳ %ds", i)
		task.wait(1)
	end

	skipText.Text = originalText
	skipCooldownActive = false

	TweenService:Create(skipButton, TweenInfo.new(0.3), {
		BackgroundColor3 = COLORS.Accent
	}):Play()
end)

swimmingButton.MouseButton1Click:Connect(function()
	if isSwimmingMode then
		showDisablePopup()
	else
		showConfirmPopup()
	end
end)

confirmCancelBtn.MouseButton1Click:Connect(function()
	hideConfirmPopup()
	togglePanel()
end)

confirmAcceptBtn.MouseButton1Click:Connect(function()
	hideConfirmPopup()
	togglePanel()
	
	if toggleSwimmingMode then
		toggleSwimmingMode:FireServer(true)
	end
	
	isSwimmingMode = true
	updateSwimmingButtonVisual()
end)

disableCancelBtn.MouseButton1Click:Connect(function()
	hideDisablePopup()
	togglePanel()
end)

disableAcceptBtn.MouseButton1Click:Connect(function()
	hideDisablePopup()
	togglePanel()
	
	if toggleSwimmingMode then
		toggleSwimmingMode:FireServer(false)
	end
	
	isSwimmingMode = false
	updateSwimmingButtonVisual()
end)

if swimmingModeChanged then
	swimmingModeChanged.OnClientEvent:Connect(function(enabled)
		isSwimmingMode = enabled
		updateSwimmingButtonVisual()
	end)
end

task.spawn(function()
	if getSwimmingStatus then
		local success, status = pcall(function()
			return getSwimmingStatus:InvokeServer()
		end)
		
		if success then
			isSwimmingMode = status
			updateSwimmingButtonVisual()
		end
	end
end)

local function updateScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize

	if viewportSize.X < 600 then
		popupPanel.Size = UDim2.new(0.75, 0, 0.55, 0)
		cpButton.Size = UDim2.new(0.12, 0, 0.12, 0)
		confirmPopup.Size = UDim2.new(0.85, 0, 0.4, 0)
		disablePopup.Size = UDim2.new(0.85, 0, 0.35, 0)
	else
		popupPanel.Size = UDim2.new(0.28, 0, 0.48, 0)
		cpButton.Size = UDim2.new(0.06, 0, 0.1, 0)
		confirmPopup.Size = UDim2.new(0.35, 0, 0.35, 0)
		disablePopup.Size = UDim2.new(0.35, 0, 0.3, 0)
	end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()
