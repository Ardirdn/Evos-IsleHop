local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Header = Color3.fromRGB(30, 30, 33),
	Button = Color3.fromRGB(35, 35, 38),
	ButtonHover = Color3.fromRGB(45, 45, 48),
	Accent = Color3.fromRGB(70, 130, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(150, 150, 160),
	Border = Color3.fromRGB(50, 50, 55),
	ToggleOn = Color3.fromRGB(67, 181, 129),
	ToggleOff = Color3.fromRGB(70, 70, 80),
}

local Settings = {
	HideTitle = false,
	HidePlayer = "Disable",
	HideAura = false,
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
screenGui.Name = "SettingsGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.new(0.25, 0, 0.4, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = COLORS.Background
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelAspect = Instance.new("UIAspectRatioConstraint")
panelAspect.AspectRatio = 1.15
panelAspect.AspectType = Enum.AspectType.ScaleWithParentSize
panelAspect.DominantAxis = Enum.DominantAxis.Width
panelAspect.Parent = panel

local panelSize = Instance.new("UISizeConstraint")
panelSize.MinSize = Vector2.new(280, 240)
panelSize.MaxSize = Vector2.new(400, 350)
panelSize.Parent = panel

createCorner(12).Parent = panel
createStroke(COLORS.Border, 2).Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.14, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = panel

createCorner(12).Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0.4, 0)
headerFix.Position = UDim2.new(0, 0, 0.6, 0)
headerFix.BackgroundColor3 = COLORS.Panel
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Size = UDim2.new(0.7, 0, 1, 0)
headerTitle.Position = UDim2.new(0.05, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "⚙️ Settings"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextScaled = true
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local titleTextConstraint = Instance.new("UITextSizeConstraint")
titleTextConstraint.MaxTextSize = 18
titleTextConstraint.MinTextSize = 10
titleTextConstraint.Parent = headerTitle

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0.12, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.86, 0, 0.15, 0)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLORS.Text
closeBtn.TextScaled = true
closeBtn.Parent = header

local closeBtnAspect = Instance.new("UIAspectRatioConstraint")
closeBtnAspect.AspectRatio = 1
closeBtnAspect.DominantAxis = Enum.DominantAxis.Height
closeBtnAspect.Parent = closeBtn

createCorner(8).Parent = closeBtn

local closeTextConstraint = Instance.new("UITextSizeConstraint")
closeTextConstraint.MaxTextSize = 16
closeTextConstraint.MinTextSize = 8
closeTextConstraint.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.ButtonHover}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Button}):Play()
end)

local dragging = false
local dragStart = nil
local startPos = nil

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
		
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
		panel.Position = UDim2.new(
			startPos.X.Scale + (delta.X / viewportSize.X),
			startPos.X.Offset,
			startPos.Y.Scale + (delta.Y / viewportSize.Y),
			startPos.Y.Offset
		)
	end
end)

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(0.9, 0, 0.78, 0)
content.Position = UDim2.new(0.05, 0, 0.18, 0)
content.BackgroundTransparency = 1
content.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0.03, 0)
contentLayout.Parent = content

local activeDropdown = nil

local function createToggle(label, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = label .. "Toggle"
	container.Size = UDim2.new(1, 0, 0.28, 0)
	container.BackgroundColor3 = COLORS.Panel
	container.BorderSizePixel = 0
	container.Parent = content
	
	createCorner(8).Parent = container
	
	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.65, 0, 1, 0)
	labelText.Position = UDim2.new(0.04, 0, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.GothamMedium
	labelText.Text = label
	labelText.TextColor3 = COLORS.Text
	labelText.TextScaled = true
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Parent = container
	
	local labelTextConstraint = Instance.new("UITextSizeConstraint")
	labelTextConstraint.MaxTextSize = 14
	labelTextConstraint.MinTextSize = 8
	labelTextConstraint.Parent = labelText
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0.18, 0, 0.55, 0)
	toggleBg.Position = UDim2.new(0.78, 0, 0.5, 0)
	toggleBg.AnchorPoint = Vector2.new(0, 0.5)
	toggleBg.BackgroundColor3 = defaultValue and COLORS.ToggleOn or COLORS.ToggleOff
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	local toggleAspect = Instance.new("UIAspectRatioConstraint")
	toggleAspect.AspectRatio = 1.85
	toggleAspect.DominantAxis = Enum.DominantAxis.Height
	toggleAspect.Parent = toggleBg
	
	createCorner(12).Parent = toggleBg
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Name = "Circle"
	toggleCircle.Size = UDim2.new(0.4, 0, 0.75, 0)
	toggleCircle.Position = defaultValue and UDim2.new(0.95, 0, 0.5, 0) or UDim2.new(0.05, 0, 0.5, 0)
	toggleCircle.AnchorPoint = defaultValue and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
	toggleCircle.BackgroundColor3 = COLORS.Text
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local circleAspect = Instance.new("UIAspectRatioConstraint")
	circleAspect.AspectRatio = 1
	circleAspect.DominantAxis = Enum.DominantAxis.Height
	circleAspect.Parent = toggleCircle
	
	createCorner(100).Parent = toggleCircle
	
	local isOn = defaultValue
	
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Parent = container
	
	toggleBtn.MouseButton1Click:Connect(function()
		isOn = not isOn
		
		TweenService:Create(toggleBg, TweenInfo.new(0.2), {
			BackgroundColor3 = isOn and COLORS.ToggleOn or COLORS.ToggleOff
		}):Play()
		
		toggleCircle.AnchorPoint = isOn and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
		TweenService:Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Position = isOn and UDim2.new(0.95, 0, 0.5, 0) or UDim2.new(0.05, 0, 0.5, 0)
		}):Play()
		
		if callback then callback(isOn) end
	end)
	
	return container
end

local function createDropdown(label, options, defaultValue, callback)
	local container = Instance.new("Frame")
	container.Name = label .. "Dropdown"
	container.Size = UDim2.new(1, 0, 0.28, 0)
	container.BackgroundColor3 = COLORS.Panel
	container.BorderSizePixel = 0
	container.ZIndex = 10
	container.Parent = content
	
	createCorner(8).Parent = container
	
	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.45, 0, 1, 0)
	labelText.Position = UDim2.new(0.04, 0, 0, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.GothamMedium
	labelText.Text = label
	labelText.TextColor3 = COLORS.Text
	labelText.TextScaled = true
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.ZIndex = 10
	labelText.Parent = container
	
	local labelTextConstraint = Instance.new("UITextSizeConstraint")
	labelTextConstraint.MaxTextSize = 14
	labelTextConstraint.MinTextSize = 8
	labelTextConstraint.Parent = labelText
	
	local dropdownBtn = Instance.new("TextButton")
	dropdownBtn.Name = "DropdownBtn"
	dropdownBtn.Size = UDim2.new(0.42, 0, 0.7, 0)
	dropdownBtn.Position = UDim2.new(0.54, 0, 0.5, 0)
	dropdownBtn.AnchorPoint = Vector2.new(0, 0.5)
	dropdownBtn.BackgroundColor3 = COLORS.Button
	dropdownBtn.BorderSizePixel = 0
	dropdownBtn.Font = Enum.Font.GothamMedium
	dropdownBtn.Text = defaultValue .. " ▼"
	dropdownBtn.TextColor3 = COLORS.Text
	dropdownBtn.TextScaled = true
	dropdownBtn.ZIndex = 10
	dropdownBtn.Parent = container
	
	local dropdownTextConstraint = Instance.new("UITextSizeConstraint")
	dropdownTextConstraint.MaxTextSize = 12
	dropdownTextConstraint.MinTextSize = 8
	dropdownTextConstraint.Parent = dropdownBtn
	
	createCorner(6).Parent = dropdownBtn
	
	local dropdownList = Instance.new("Frame")
	dropdownList.Name = "DropdownList"
	dropdownList.Size = UDim2.new(1, 0, 0, #options * 28 + 10)
	dropdownList.Position = UDim2.new(0, 0, 1, 5)
	dropdownList.BackgroundColor3 = COLORS.Background
	dropdownList.BorderSizePixel = 0
	dropdownList.Visible = false
	dropdownList.ZIndex = 999
	dropdownList.Parent = dropdownBtn
	
	createCorner(6).Parent = dropdownList
	createStroke(COLORS.Border, 1).Parent = dropdownList
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = dropdownList
	
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 5)
	listPadding.PaddingLeft = UDim.new(0, 5)
	listPadding.PaddingRight = UDim.new(0, 5)
	listPadding.Parent = dropdownList
	
	local currentValue = defaultValue
	
	for _, option in ipairs(options) do
		local optionBtn = Instance.new("TextButton")
		optionBtn.Size = UDim2.new(1, 0, 0, 24)
		optionBtn.BackgroundColor3 = COLORS.Panel
		optionBtn.BorderSizePixel = 0
		optionBtn.Font = Enum.Font.GothamMedium
		optionBtn.Text = option
		optionBtn.TextColor3 = COLORS.Text
		optionBtn.TextScaled = true
		optionBtn.ZIndex = 1000
		optionBtn.Parent = dropdownList
		
		local optionTextConstraint = Instance.new("UITextSizeConstraint")
		optionTextConstraint.MaxTextSize = 12
		optionTextConstraint.MinTextSize = 8
		optionTextConstraint.Parent = optionBtn
		
		createCorner(4).Parent = optionBtn
		
		optionBtn.MouseEnter:Connect(function()
			TweenService:Create(optionBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Accent}):Play()
		end)
		
		optionBtn.MouseLeave:Connect(function()
			TweenService:Create(optionBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.Panel}):Play()
		end)
		
		optionBtn.MouseButton1Click:Connect(function()
			currentValue = option
			dropdownBtn.Text = option .. " ▼"
			dropdownList.Visible = false
			activeDropdown = nil
			if callback then callback(option) end
		end)
	end
	
	dropdownBtn.MouseButton1Click:Connect(function()
		if activeDropdown and activeDropdown ~= dropdownList then
			activeDropdown.Visible = false
		end
		
		dropdownList.Visible = not dropdownList.Visible
		activeDropdown = dropdownList.Visible and dropdownList or nil
	end)
	
	return container
end

createToggle("🏷️ Hide Title", Settings.HideTitle, function(value)
	Settings.HideTitle = value
	if _G.SetHideTitles then _G.SetHideTitles(value) end
end)

createDropdown("👥 Hide Players", {"Disable", "Friends Only", "All"}, Settings.HidePlayer, function(value)
	Settings.HidePlayer = value
	
	local hideAll = (value == "All")
	local friendsOnly = (value == "Friends Only")
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local shouldHide = hideAll
			
			if friendsOnly then
				local success, isFriend = pcall(function() 
					return player:IsFriendsWith(otherPlayer.UserId) 
				end)
				shouldHide = success and not isFriend
			end
			
			if otherPlayer.Character then
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = shouldHide and 1 or 0
					elseif part:IsA("Decal") or part:IsA("Texture") then
						part.LocalTransparencyModifier = shouldHide and 1 or 0
					end
				end
				
				local head = otherPlayer.Character:FindFirstChild("Head")
				if head then
					local billboard = head:FindFirstChild("PlayerInfoBillboard")
					if billboard then
						billboard.Enabled = not shouldHide
					end
				end
			end
		end
	end
end)

createToggle("✨ Hide Aura", Settings.HideAura, function(value)
	Settings.HideAura = value
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local equippedAura = hrp:FindFirstChild("EquippedAura")
				if equippedAura then
					for _, child in ipairs(equippedAura:GetDescendants()) do
						if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
							child.Enabled = not value
						elseif child:IsA("BasePart") or child:IsA("MeshPart") then
							child.LocalTransparencyModifier = value and 1 or 0
						elseif child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
							child.Enabled = not value
						end
					end
				end
			end
			
			for _, child in ipairs(otherPlayer.Character:GetDescendants()) do
				if child.Name:lower():find("aura") then
					if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
						child.Enabled = not value
					elseif child:IsA("BasePart") then
						child.LocalTransparencyModifier = value and 1 or 0
					end
				end
			end
		end
	end
end)

local function togglePanel()
	panel.Visible = not panel.Visible
end

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if activeDropdown then
			task.wait()
			activeDropdown.Visible = false
			activeDropdown = nil
		end
	end
	if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		panel.Visible = false
	end
end)

local settingsBtn = Instance.new("TextButton")
settingsBtn.Name = "SettingsHUDButton"
settingsBtn.AnchorPoint = Vector2.new(1, 0.5)
settingsBtn.Size = UDim2.new(0.035, 0, 0.06, 0)
settingsBtn.Position = UDim2.new(0.96, 0, 0.05, 0)
settingsBtn.BackgroundColor3 = COLORS.Panel
settingsBtn.BorderSizePixel = 0
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.Text = "⚙️"
settingsBtn.TextColor3 = COLORS.Text
settingsBtn.TextScaled = true
settingsBtn.Parent = screenGui

local settingsBtnAspect = Instance.new("UIAspectRatioConstraint")
settingsBtnAspect.AspectRatio = 1
settingsBtnAspect.AspectType = Enum.AspectType.ScaleWithParentSize
settingsBtnAspect.DominantAxis = Enum.DominantAxis.Width
settingsBtnAspect.Parent = settingsBtn

local settingsBtnSize = Instance.new("UISizeConstraint")
settingsBtnSize.MinSize = Vector2.new(35, 35)
settingsBtnSize.MaxSize = Vector2.new(55, 55)
settingsBtnSize.Parent = settingsBtn

createCorner(10).Parent = settingsBtn
createStroke(COLORS.Border, 1).Parent = settingsBtn

local settingsTextConstraint = Instance.new("UITextSizeConstraint")
settingsTextConstraint.MaxTextSize = 24
settingsTextConstraint.MinTextSize = 14
settingsTextConstraint.Parent = settingsBtn

settingsBtn.MouseEnter:Connect(function()
	TweenService:Create(settingsBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.ButtonHover}):Play()
end)
settingsBtn.MouseLeave:Connect(function()
	TweenService:Create(settingsBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Panel}):Play()
end)

settingsBtn.MouseButton1Click:Connect(togglePanel)

_G.GameSettings = Settings
