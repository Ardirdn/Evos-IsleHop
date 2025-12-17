local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDButtonHelper = {}

local function getHUD()
    return playerGui:WaitForChild("HUD", 30)
end

function HUDButtonHelper.Create(config)
    local hud = getHUD()
    if not hud then
        warn("[HUD BUTTON] HUD ScreenGui not found!")
        return nil
    end

    local side = config.Side or "Right"
    local icon = config.Icon
    local text = config.Text or ""
    local onClick = config.OnClick
    local name = config.Name or text .. "Button"

    local sideFrame = hud:FindFirstChild(side)
    if not sideFrame then
        warn(string.format("[HUD BUTTON] Side frame '%s' not found in HUD!", side))
        return nil
    end

    local template = sideFrame:FindFirstChild("ButtonTemplate")
    if not template then
        warn(string.format("[HUD BUTTON] ButtonTemplate not found in HUD.%s!", side))
        return nil
    end

    local button = template:Clone()
    button.Name = name
    button.Visible = true
    button.BackgroundTransparency = 1
    button.Parent = sideFrame

    for _, child in ipairs(button:GetDescendants()) do
        if child:IsA("Frame") then
            child.BackgroundTransparency = 1
        end
    end

    local imageButton = button:FindFirstChild("ImageButton")
    if imageButton then

        imageButton.BackgroundTransparency = 1

        if icon then
            imageButton.Image = icon
        end

        if onClick then
            imageButton.MouseButton1Click:Connect(onClick)
        end

        imageButton.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.7
            }):Play()
        end)

        imageButton.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {
                BackgroundTransparency = 1
            }):Play()
        end)
    end

    local textLabel = button:FindFirstChild("TextLabel")
    if textLabel then
        textLabel.Text = text
        textLabel.BackgroundTransparency = 1
    end

    return {
        Frame = button,
        ImageButton = imageButton,
        TextLabel = textLabel,

        SetIcon = function(self, newIcon)
            if self.ImageButton then
                self.ImageButton.Image = newIcon
            end
        end,

        SetText = function(self, newText)
            if self.TextLabel then
                self.TextLabel.Text = newText
            end
        end,

        SetVisible = function(self, visible)
            if self.Frame then
                self.Frame.Visible = visible
            end
        end,

        Destroy = function(self)
            if self.Frame then
                self.Frame:Destroy()
            end
        end
    }
end

function HUDButtonHelper.HideTemplates()
    local hud = getHUD()
    if not hud then return end

    for _, sideName in ipairs({"Left", "Right", "Top"}) do
        local sideFrame = hud:FindFirstChild(sideName)
        if sideFrame then
            local template = sideFrame:FindFirstChild("ButtonTemplate")
            if template then
                template.Visible = false
            end
        end
    end
end

return HUDButtonHelper
