--[[
    VIBE CLIENT - LOCAL LIGHTING + SAVE PREFERENCE
    Lighting changes are purely local (per-player)
    Theme preference is saved to DataHandler for persistence

    Tombol Vibe ada di bawah tombol CP (Checkpoint)
    Posisi: kanan layar, Y = 0.57
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ LOAD CONFIG
local VibeConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VibeConfig"))

-- ✅ PANEL MANAGER (shared dengan script lain)
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))

-- ✅ REMOTES FOR SAVE/LOAD
local vibeRemotes = ReplicatedStorage:WaitForChild("VibeRemotes", 10)
local saveThemeEvent = vibeRemotes and vibeRemotes:WaitForChild("SaveTheme", 5)
local getThemeFunc = vibeRemotes and vibeRemotes:WaitForChild("GetTheme", 5)

-- ✅ SKYBOX FOLDER
local skyboxesFolder = ReplicatedStorage:FindFirstChild("Skyboxes")

-- ✅ CURRENT THEME
local currentTheme = VibeConfig.DefaultTheme

-- ✅ COLOR SCHEME
local COLORS = {
	Background = Color3.fromRGB(25, 25, 30),
	Panel = Color3.fromRGB(30, 30, 35),
	Header = Color3.fromRGB(35, 35, 40),
	Button = Color3.fromRGB(45, 45, 50),
	ButtonHover = Color3.fromRGB(55, 55, 60),
	ButtonActive = Color3.fromRGB(88, 101, 242),
	Accent = Color3.fromRGB(255, 170, 80),
	AccentHover = Color3.fromRGB(255, 190, 100),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Success = Color3.fromRGB(67, 181, 129),
	Border = Color3.fromRGB(50, 50, 55)
}

local THEME_COLORS = {
	Siang = Color3.fromRGB(255, 200, 100),
	Sore  = Color3.fromRGB(255, 120, 80),
	Malam = Color3.fromRGB(80, 100, 180),
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
screenGui.Name = "VibeGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ✅ VIBE BUTTON (di bawah tombol CP)
-- CP button ada di X=0.93, Y=0.45 — Vibe button di Y=0.57
local vibeButton = Instance.new("TextButton")
vibeButton.Name = "VibeButton"
vibeButton.Size = UDim2.new(0.06, 0, 0.1, 0)
vibeButton.Position = UDim2.new(0.93, 0, 0.57, 0)
vibeButton.AnchorPoint = Vector2.new(0.5, 0.5)
vibeButton.BackgroundColor3 = COLORS.Panel
vibeButton.BorderSizePixel = 0
vibeButton.Text = ""
vibeButton.AutoButtonColor = false
vibeButton.Parent = screenGui

createCorner(8).Parent = vibeButton
createStroke(COLORS.Border, 2).Parent = vibeButton

local vibeIcon = Instance.new("TextLabel")
vibeIcon.Size = UDim2.new(1, 0, 0.6, 0)
vibeIcon.Position = UDim2.new(0, 0, 0.1, 0)
vibeIcon.BackgroundTransparency = 1
vibeIcon.Font = Enum.Font.GothamBold
vibeIcon.Text = "🌅"
vibeIcon.TextColor3 = COLORS.Text
vibeIcon.TextScaled = true
vibeIcon.Parent = vibeButton

local vibeIconConstraint = Instance.new("UITextSizeConstraint")
vibeIconConstraint.MaxTextSize = 32
vibeIconConstraint.Parent = vibeIcon

local vibeLabel = Instance.new("TextLabel")
vibeLabel.Size = UDim2.new(1, 0, 0.3, 0)
vibeLabel.Position = UDim2.new(0, 0, 0.68, 0)
vibeLabel.BackgroundTransparency = 1
vibeLabel.Font = Enum.Font.GothamBold
vibeLabel.Text = "Vibe"
vibeLabel.TextColor3 = COLORS.TextSecondary
vibeLabel.TextScaled = true
vibeLabel.Parent = vibeButton

local vibeLabelConstraint = Instance.new("UITextSizeConstraint")
vibeLabelConstraint.MaxTextSize = 14
vibeLabelConstraint.MinTextSize = 10
vibeLabelConstraint.Parent = vibeLabel

-- ✅ PANEL STATE
local panelOpen = false

-- ✅ TOGGLE PANEL FUNCTION (forward declaration)
local togglePanel

-- ✅ CREATE POPUP PANEL
local popupPanel = Instance.new("Frame")
popupPanel.Name = "VibePopup"
popupPanel.Size = UDim2.new(0.28, 0, 0.45, 0)
popupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
popupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
popupPanel.BackgroundColor3 = COLORS.Background
popupPanel.BorderSizePixel = 0
popupPanel.Visible = false
popupPanel.Parent = screenGui

createCorner(12).Parent = popupPanel
createStroke(COLORS.Border, 2).Parent = popupPanel

-- Header
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
title.Text = "🌅 Pilih Suasana"
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

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 60)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = popupPanel

-- Scrolling Frame for Themes
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.Accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = contentContainer

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

-- ✅ UPDATE ACTIVE THEME VISUALS (forward declaration)
local updateThemeVisuals

-- ✅ APPLY LIGHTING LOCALLY (purely local, no server)
local function applyLightingLocal(themeKey)
	local theme = VibeConfig.Themes[themeKey]
	if not theme then
		warn(string.format("[VIBE CLIENT] ❌ Theme not found: %s", themeKey))
		return
	end

	print("========================================")
	print(string.format("[VIBE CLIENT] 🎨 Applying theme: %s", themeKey))
	print(string.format("[VIBE CLIENT] Config values:"))
	print(string.format("  - TimeOfDay: %s", theme.TimeOfDay))
	print(string.format("  - Brightness: %s", theme.Brightness))
	print(string.format("  - Skybox: %s", theme.Skybox))
	print("========================================")

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Apply lighting properties
	TweenService:Create(Lighting, tweenInfo, {
		Ambient = theme.Ambient,
		Brightness = theme.Brightness,
		ExposureCompensation = theme.ExposureCompensation,
		OutdoorAmbient = theme.OutdoorAmbient,
		ColorShift_Top = theme.ColorShift_Top,
		GeographicLatitude = theme.GeographicLatitude
	}):Play()

	Lighting.TimeOfDay = theme.TimeOfDay
	print(string.format("[VIBE CLIENT] ✅ Lighting properties applied"))

	-- Apply atmosphere
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, tweenInfo, {
			Density = theme.AtmosphereDensity,
			Offset = theme.AtmosphereOffset
		}):Play()
		print(string.format("[VIBE CLIENT] ✅ Atmosphere updated"))
	else
		warn("[VIBE CLIENT] ⚠️ No Atmosphere found in Lighting")
	end

	-- Apply skybox
	print(string.format("[VIBE CLIENT] 🌌 Changing skybox to: %s", theme.Skybox))

	if not skyboxesFolder then
		warn("[VIBE CLIENT] ❌ Skyboxes folder not found in ReplicatedStorage!")
	else
		local skyboxTemplate = skyboxesFolder:FindFirstChild(theme.Skybox)

		if not skyboxTemplate then
			warn(string.format("[VIBE CLIENT] ❌ Skybox template not found: %s", theme.Skybox))
			print("[VIBE CLIENT] Available skyboxes in folder:")
			for _, child in ipairs(skyboxesFolder:GetChildren()) do
				print(string.format("  - %s (%s)", child.Name, child.ClassName))
			end
		else
			print(string.format("[VIBE CLIENT] ✅ Found skybox template: %s (ClassName: %s)", theme.Skybox, skyboxTemplate.ClassName))

			-- Remove ALL existing Sky objects first
			local removedCount = 0
			for _, child in ipairs(Lighting:GetChildren()) do
				if child:IsA("Sky") then
					print(string.format("[VIBE CLIENT] 🗑️ Removing old skybox: %s", child.Name))
					child:Destroy()
					removedCount = removedCount + 1
				end
			end
			print(string.format("[VIBE CLIENT] Removed %d old skybox(es)", removedCount))

			-- Wait a frame to ensure destruction is complete
			task.wait()

			-- Clone and apply new skybox
			local newSky = skyboxTemplate:Clone()
			newSky.Name = theme.Skybox
			newSky.Parent = Lighting

			-- Verify skybox was added
			local verifySky = Lighting:FindFirstChildOfClass("Sky")
			if verifySky then
				print(string.format("[VIBE CLIENT] ✅ New skybox applied: %s", verifySky.Name))
			else
				warn("[VIBE CLIENT] ❌ Failed to apply new skybox!")
			end
		end
	end

	currentTheme = themeKey
	updateThemeVisuals(themeKey)
	print(string.format("[VIBE CLIENT] ✅ Theme change complete: %s", themeKey))
	print("========================================")
end

-- ✅ CREATE THEME BUTTONS
local themeButtons = {}

for index, themeKey in ipairs(VibeConfig.ThemeOrder) do
	local theme = VibeConfig.Themes[themeKey]
	if not theme then continue end

	local buttonColor = THEME_COLORS[themeKey] or COLORS.Accent

	local themeBtn = Instance.new("TextButton")
	themeBtn.Name = themeKey .. "Button"
	themeBtn.Size = UDim2.new(1, 0, 0, 70)
	themeBtn.BackgroundColor3 = COLORS.Button
	themeBtn.BorderSizePixel = 0
	themeBtn.Text = ""
	themeBtn.AutoButtonColor = false
	themeBtn.LayoutOrder = index
	themeBtn.Parent = scrollFrame

	createCorner(10).Parent = themeBtn

	local activeBar = Instance.new("Frame")
	activeBar.Name = "ActiveBar"
	activeBar.Size = UDim2.new(0, 4, 0.8, 0)
	activeBar.Position = UDim2.new(0, 5, 0.1, 0)
	activeBar.BackgroundColor3 = buttonColor
	activeBar.BackgroundTransparency = 0.7
	activeBar.BorderSizePixel = 0
	activeBar.Parent = themeBtn

	createCorner(2).Parent = activeBar

	local btnIcon = Instance.new("TextLabel")
	btnIcon.Size = UDim2.new(0, 50, 1, 0)
	btnIcon.Position = UDim2.new(0, 15, 0, 0)
	btnIcon.BackgroundTransparency = 1
	btnIcon.Font = Enum.Font.GothamBold
	btnIcon.Text = theme.Icon
	btnIcon.TextColor3 = COLORS.Text
	btnIcon.TextScaled = true
	btnIcon.Parent = themeBtn

	local btnIconConstraint = Instance.new("UITextSizeConstraint")
	btnIconConstraint.MaxTextSize = 36
	btnIconConstraint.Parent = btnIcon

	local btnTitle = Instance.new("TextLabel")
	btnTitle.Size = UDim2.new(1, -80, 0.5, 0)
	btnTitle.Position = UDim2.new(0, 70, 0, 10)
	btnTitle.BackgroundTransparency = 1
	btnTitle.Font = Enum.Font.GothamBold
	btnTitle.Text = theme.DisplayName
	btnTitle.TextColor3 = COLORS.Text
	btnTitle.TextSize = 16
	btnTitle.TextXAlignment = Enum.TextXAlignment.Left
	btnTitle.Parent = themeBtn

	local btnDesc = Instance.new("TextLabel")
	btnDesc.Size = UDim2.new(1, -80, 0.4, 0)
	btnDesc.Position = UDim2.new(0, 70, 0.5, 0)
	btnDesc.BackgroundTransparency = 1
	btnDesc.Font = Enum.Font.Gotham
	btnDesc.Text = theme.Description
	btnDesc.TextColor3 = COLORS.TextSecondary
	btnDesc.TextSize = 12
	btnDesc.TextXAlignment = Enum.TextXAlignment.Left
	btnDesc.TextTruncate = Enum.TextTruncate.AtEnd
	btnDesc.Parent = themeBtn

	local checkmark = Instance.new("TextLabel")
	checkmark.Name = "Checkmark"
	checkmark.Size = UDim2.new(0, 30, 0, 30)
	checkmark.Position = UDim2.new(1, -40, 0.5, -15)
	checkmark.BackgroundTransparency = 1
	checkmark.Font = Enum.Font.GothamBold
	checkmark.Text = "✓"
	checkmark.TextColor3 = COLORS.Success
	checkmark.TextSize = 20
	checkmark.Visible = false
	checkmark.Parent = themeBtn

	themeBtn.MouseEnter:Connect(function()
		TweenService:Create(themeBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.ButtonHover
		}):Play()
		TweenService:Create(activeBar, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.3
		}):Play()
	end)

	themeBtn.MouseLeave:Connect(function()
		if currentTheme ~= themeKey then
			TweenService:Create(themeBtn, TweenInfo.new(0.2), {
				BackgroundColor3 = COLORS.Button
			}):Play()
			TweenService:Create(activeBar, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.7
			}):Play()
		end
	end)

	themeBtn.MouseButton1Click:Connect(function()
		if currentTheme == themeKey then return end
		print(string.format("[VIBE CLIENT] Selecting theme: %s", themeKey))

		-- ✅ Apply lighting IMMEDIATELY locally
		applyLightingLocal(themeKey)

		-- ✅ Save to server (for persistence on rejoin)
		if saveThemeEvent then
			saveThemeEvent:FireServer(themeKey)
		end

		-- ✅ Close panel after selection
		if panelOpen then
			togglePanel()
		end
	end)

	themeButtons[themeKey] = {
		Button = themeBtn,
		ActiveBar = activeBar,
		Checkmark = checkmark,
		Color = buttonColor
	}
end

-- ✅ UPDATE ACTIVE THEME VISUALS
updateThemeVisuals = function(themeKey)
	for key, data in pairs(themeButtons) do
		if key == themeKey then
			TweenService:Create(data.Button, TweenInfo.new(0.3), {
				BackgroundColor3 = Color3.fromRGB(
					math.floor(data.Color.R * 255 * 0.3 + COLORS.Button.R * 255 * 0.7),
					math.floor(data.Color.G * 255 * 0.3 + COLORS.Button.G * 255 * 0.7),
					math.floor(data.Color.B * 255 * 0.3 + COLORS.Button.B * 255 * 0.7)
				)
			}):Play()
			TweenService:Create(data.ActiveBar, TweenInfo.new(0.3), {
				BackgroundTransparency = 0,
				Size = UDim2.new(0, 5, 0.8, 0)
			}):Play()
			data.Checkmark.Visible = true
		else
			TweenService:Create(data.Button, TweenInfo.new(0.3), {
				BackgroundColor3 = COLORS.Button
			}):Play()
			TweenService:Create(data.ActiveBar, TweenInfo.new(0.3), {
				BackgroundTransparency = 0.7,
				Size = UDim2.new(0, 4, 0.8, 0)
			}):Play()
			data.Checkmark.Visible = false
		end
	end
end

-- ✅ CLOSE PANEL
local function closePanel()
	if not panelOpen then return end
	panelOpen = false

	TweenService:Create(popupPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()

	task.delay(0.2, function()
		popupPanel.Visible = false
	end)

	TweenService:Create(vibeButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Panel
	}):Play()

	PanelManager:Close("VibePanel")
end

-- ✅ OPEN PANEL
local function openPanel()
	PanelManager:Open("VibePanel") -- Closes other panels first
	panelOpen = true

	popupPanel.Size = UDim2.new(0, 0, 0, 0)
	popupPanel.Visible = true
	TweenService:Create(popupPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.28, 0, 0.45, 0)
	}):Play()

	TweenService:Create(vibeButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Accent
	}):Play()
end

-- ✅ TOGGLE PANEL
togglePanel = function()
	if panelOpen then
		closePanel()
	else
		openPanel()
	end
end

-- Register with PanelManager
PanelManager:Register("VibePanel", closePanel)

-- ✅ BUTTON EVENTS
vibeButton.MouseButton1Click:Connect(togglePanel)

vibeButton.MouseEnter:Connect(function()
	if not panelOpen then
		TweenService:Create(vibeButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Button
		}):Play()
	end
end)

vibeButton.MouseLeave:Connect(function()
	if not panelOpen then
		TweenService:Create(vibeButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.Panel
		}):Play()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.ButtonHover
	}):Play()
end)

closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), {
		BackgroundColor3 = COLORS.Button
	}):Play()
end)

-- ✅ ADAPTIVE SCALING FOR POPUP
local function updateScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize

	if viewportSize.X < 600 then
		popupPanel.Size = UDim2.new(0.85, 0, 0.55, 0)
		vibeButton.Size = UDim2.new(0.12, 0, 0.12, 0)
	else
		popupPanel.Size = UDim2.new(0.28, 0, 0.45, 0)
		vibeButton.Size = UDim2.new(0.06, 0, 0.1, 0)
	end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

-- ✅ INITIALIZE - LOAD SAVED THEME OR DEFAULT
task.spawn(function()
	task.wait(1)

	-- Try to load saved theme from server
	local savedTheme = nil
	if getThemeFunc then
		local success, result = pcall(function()
			return getThemeFunc:InvokeServer()
		end)

		if success and result and VibeConfig.Themes[result] then
			savedTheme = result
			print(string.format("[VIBE CLIENT] Loaded saved theme: %s", savedTheme))
		end
	end

	-- Apply saved theme or default
	local themeToApply = savedTheme or VibeConfig.DefaultTheme
	applyLightingLocal(themeToApply)
	print(string.format("[VIBE CLIENT] Initialized with theme: %s", themeToApply))
end)

print("✅ [VIBE CLIENT] UI loaded (Local Lighting + Save Preference)")
