local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDButtonHelper = require(script.Parent:WaitForChild("HUDButtonHelper"))
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))

local VibeConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VibeConfig"))

local vibeRemotes = ReplicatedStorage:WaitForChild("VibeRemotes", 10)
local saveThemeEvent = vibeRemotes and vibeRemotes:WaitForChild("SaveTheme", 5)
local getThemeFunc = vibeRemotes and vibeRemotes:WaitForChild("GetTheme", 5)

local skyboxesFolder = ReplicatedStorage:FindFirstChild("Skyboxes")

local currentTheme = VibeConfig.DefaultTheme

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
    Sore = Color3.fromRGB(255, 120, 80),
    Malam = Color3.fromRGB(80, 100, 180),
}

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
screenGui.Name = "VibeGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

local panelOpen = false
local vibeButtonRef = nil

local togglePanel

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

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 60)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = popupPanel

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

local updateThemeVisuals

local function applyLightingLocal(themeKey)
    local theme = VibeConfig.Themes[themeKey]
    if not theme then
        warn(string.format("[VIBE CLIENT] ❌ Theme not found: %s", themeKey))
        return
    end

    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    TweenService:Create(Lighting, tweenInfo, {
        Ambient = theme.Ambient,
        Brightness = theme.Brightness,
        ExposureCompensation = theme.ExposureCompensation,
        OutdoorAmbient = theme.OutdoorAmbient,
        ColorShift_Top = theme.ColorShift_Top,
        GeographicLatitude = theme.GeographicLatitude
    }):Play()

    Lighting.TimeOfDay = theme.TimeOfDay

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        TweenService:Create(atmosphere, tweenInfo, {
            Density = theme.AtmosphereDensity,
            Offset = theme.AtmosphereOffset
        }):Play()
    else
        warn("[VIBE CLIENT] ⚠️ No Atmosphere found in Lighting")
    end

    if not skyboxesFolder then
        warn("[VIBE CLIENT] ❌ Skyboxes folder not found in ReplicatedStorage!")
    else
        local skyboxTemplate = skyboxesFolder:FindFirstChild(theme.Skybox)

        if not skyboxTemplate then
            warn(string.format("[VIBE CLIENT] ❌ Skybox template not found: %s", theme.Skybox))
            for _, child in ipairs(skyboxesFolder:GetChildren()) do
            end
        else

            if skyboxTemplate:IsA("Sky") then
            else
                warn(string.format("[VIBE CLIENT] ⚠️ Template is NOT a Sky! ClassName: %s", skyboxTemplate.ClassName))
            end

            local removedCount = 0
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Sky") then
                    child:Destroy()
                    removedCount = removedCount + 1
                end
            end

            task.wait()

            local newSky = skyboxTemplate:Clone()
            newSky.Name = theme.Skybox
            newSky.Parent = Lighting

            local verifySky = Lighting:FindFirstChildOfClass("Sky")
            if verifySky then

                if verifySky.SkyboxBk == "" and verifySky.SkyboxFt == "" then
                    warn("[VIBE CLIENT] ⚠️ WARNING: Skybox textures are EMPTY!")
                end
            else
                warn("[VIBE CLIENT] ❌ Failed to apply new skybox!")
            end
        end
    end

    currentTheme = themeKey
    updateThemeVisuals(themeKey)
end

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

        applyLightingLocal(themeKey)

        if saveThemeEvent then
            saveThemeEvent:FireServer(themeKey)
        end

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

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    TweenService:Create(popupPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.delay(0.2, function()
        popupPanel.Visible = false
    end)
    PanelManager:Close("VibePanel")
end

local function openPanel()
    PanelManager:Open("VibePanel")
    panelOpen = true
    popupPanel.Size = UDim2.new(0, 0, 0, 0)
    popupPanel.Visible = true
    TweenService:Create(popupPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.28, 0, 0.45, 0)
    }):Play()
end

togglePanel = function()
    if panelOpen then
        closePanel()
    else
        openPanel()
    end
end

PanelManager:Register("VibePanel", closePanel)

vibeButtonRef = HUDButtonHelper.Create({
    Side = "Right",
    Name = "VibeButton",
    Icon = "rbxassetid://106864593351306",
    Text = "Vibe",
    OnClick = togglePanel
})

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

local function updateScale()
    local viewportSize = workspace.CurrentCamera.ViewportSize

    if viewportSize.X < 600 then
        popupPanel.Size = UDim2.new(0.85, 0, 0.55, 0)
    else
        popupPanel.Size = UDim2.new(0.28, 0, 0.45, 0)
    end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

task.spawn(function()
    task.wait(1)

    local savedTheme = nil
    if getThemeFunc then
        local success, result = pcall(function()
            return getThemeFunc:InvokeServer()
        end)

        if success and result and VibeConfig.Themes[result] then
            savedTheme = result
        end
    end

    local themeToApply = savedTheme or VibeConfig.DefaultTheme
    applyLightingLocal(themeToApply)
end)
