--[[
    CHECKPOINT CLIENT v2
    Modern UI styled like Admin Panel
    Place in StarterGui
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ CONFIG
local CONFIG = {
	SHOW_CHECKPOINT_BUTTON = true, -- Set false untuk hide button
}

if not CONFIG.SHOW_CHECKPOINT_BUTTON then
	print("[CHECKPOINT CLIENT] Button hidden by config")
	return
end

-- Wait for CheckpointRemotes
local checkpointRemotes = ReplicatedStorage:WaitForChild("CheckpointRemotes", 30)
if not checkpointRemotes then
	warn("[CHECKPOINT CLIENT] CheckpointRemotes not found!")
	return
end

local teleportToBasecamp = checkpointRemotes:WaitForChild("TeleportToBasecamp", 10)
local skipCheckpoint = checkpointRemotes:WaitForChild("SkipCheckpoint", 10)

if not teleportToBasecamp or not skipCheckpoint then
	warn("[CHECKPOINT CLIENT] Remote events not found!")
	return
end

-- ✅ COLOR SCHEME (Same as Admin Panel)
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

-- ✅ UTILITY FUNCTIONS
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

-- ✅ CREATE SCREENGUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheckpointGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ✅ CREATE CP BUTTON (KOTAK dengan Icon + Text)
local cpButton = Instance.new("TextButton")
cpButton.Name = "CPButton"
cpButton.Size = UDim2.new(0.06, 0, 0.1, 0) -- Square-ish
cpButton.Position = UDim2.new(0.93, 0, 0.45, 0) -- Right middle
cpButton.AnchorPoint = Vector2.new(0.5, 0.5)
cpButton.BackgroundColor3 = COLORS.Panel
cpButton.BorderSizePixel = 0
cpButton.Text = ""
cpButton.AutoButtonColor = false
cpButton.Parent = screenGui

createCorner(8).Parent = cpButton
createStroke(COLORS.Border, 2).Parent = cpButton

-- ✅ ICON (Top)
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

-- ✅ TEXT (Bottom)
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

-- ✅ CREATE POPUP PANEL (KOTAK - Center)
local popupPanel = Instance.new("Frame")
popupPanel.Name = "PopupPanel"
popupPanel.Size = UDim2.new(0.25, 0, 0.35, 0) -- Square-ish
popupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
popupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
popupPanel.BackgroundColor3 = COLORS.Background
popupPanel.BorderSizePixel = 0
popupPanel.Visible = false
popupPanel.Parent = screenGui

createCorner(12).Parent = popupPanel
createStroke(COLORS.Border, 2).Parent = popupPanel

-- ✅ HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = popupPanel

createCorner(12).Parent = header

-- Header bottom filler (fix rounded corner)
local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0, 15)
headerBottom.Position = UDim2.new(0, 0, 1, -15)
headerBottom.BackgroundColor3 = COLORS.Header
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

-- ✅ TITLE
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

-- ✅ CLOSE BUTTON
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

-- ✅ CONTENT CONTAINER
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 60)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = popupPanel

-- ✅ RESET BUTTON (Kotak dengan Icon + Text)
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(1, 0, 0.4, 0)
resetButton.Position = UDim2.new(0, 0, 0.05, 0)
resetButton.BackgroundColor3 = COLORS.Danger
resetButton.BorderSizePixel = 0
resetButton.Text = ""
resetButton.AutoButtonColor = false
resetButton.Parent = contentContainer

createCorner(8).Parent = resetButton
createStroke(Color3.fromRGB(200, 50, 50), 2).Parent = resetButton

-- Reset Icon
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
resetIconConstraint.MaxTextSize = 40
resetIconConstraint.Parent = resetIcon

-- Reset Text
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

-- ✅ SKIP BUTTON (Kotak dengan Icon + Text)
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(1, 0, 0.4, 0)
skipButton.Position = UDim2.new(0, 0, 0.55, 0)
skipButton.BackgroundColor3 = COLORS.Accent
skipButton.BorderSizePixel = 0
skipButton.Text = ""
skipButton.AutoButtonColor = false
skipButton.Parent = contentContainer

createCorner(8).Parent = skipButton
createStroke(Color3.fromRGB(70, 80, 200), 2).Parent = skipButton

-- Skip Icon
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
skipIconConstraint.MaxTextSize = 40
skipIconConstraint.Parent = skipIcon

-- Skip Text
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

-- ✅ COOLDOWN SYSTEM
local resetCooldownActive = false
local skipCooldownActive = false
local COOLDOWN_TIME = 3

-- ✅ TOGGLE PANEL
local panelOpen = false

local function togglePanel()
	panelOpen = not panelOpen

	if panelOpen then
		popupPanel.Size = UDim2.new(0, 0, 0, 0)
		popupPanel.Visible = true
		TweenService:Create(popupPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.25, 0, 0.35, 0)
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

-- ✅ CP BUTTON CLICK
cpButton.MouseButton1Click:Connect(togglePanel)

-- ✅ CP BUTTON HOVER
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

-- ✅ CLOSE BUTTON CLICK
closeButton.MouseButton1Click:Connect(togglePanel)

-- ✅ RESET BUTTON HOVER
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

-- ✅ SKIP BUTTON HOVER
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

-- ✅ RESET BUTTON CLICK
resetButton.MouseButton1Click:Connect(function()
	if resetCooldownActive then
		warn("[CHECKPOINT CLIENT] Reset cooldown active")
		return
	end

	resetCooldownActive = true
	local originalText = resetText.Text

	TweenService:Create(resetButton, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(150, 30, 30)
	}):Play()

	teleportToBasecamp:FireServer()
	print("[CHECKPOINT CLIENT] Reset to basecamp requested")

	-- Cooldown countdown
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

-- ✅ SKIP BUTTON CLICK
skipButton.MouseButton1Click:Connect(function()
	if skipCooldownActive then
		warn("[CHECKPOINT CLIENT] Skip cooldown active")
		return
	end

	skipCooldownActive = true
	local originalText = skipText.Text

	TweenService:Create(skipButton, TweenInfo.new(0.1), {
		BackgroundColor3 = Color3.fromRGB(60, 70, 180)
	}):Play()

	skipCheckpoint:FireServer()
	print("[CHECKPOINT CLIENT] Skip checkpoint requested")

	-- Close panel
	togglePanel()

	-- Cooldown countdown
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

-- ✅ ADAPTIVE SCALING
local function updateScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize

	if viewportSize.X < 600 then
		-- Mobile
		popupPanel.Size = UDim2.new(0.65, 0, 0.45, 0)
		cpButton.Size = UDim2.new(0.12, 0, 0.12, 0)
	else
		-- Desktop
		popupPanel.Size = UDim2.new(0.25, 0, 0.35, 0)
		cpButton.Size = UDim2.new(0.06, 0, 0.1, 0)
	end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

print("✅ [CHECKPOINT CLIENT] UI loaded (Admin Panel style)")
