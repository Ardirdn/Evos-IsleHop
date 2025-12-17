local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local DonateConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DonateConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("DonateRemotes")
local getDonateDataFunc = remoteFolder:WaitForChild("GetDonateData")
local purchaseDonationEvent = remoteFolder:WaitForChild("PurchaseDonation")

local COLORS = DonateConfig.Colors

local donationData = {
	TotalDonations = 0,
	HasDonaturTitle = false
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

local function makeTextAdaptive(textLabel, maxTextSize)
	textLabel.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxTextSize or 14
	constraint.Parent = textLabel
end

local function addAspectRatio(frame, ratio)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = ratio or 1.3
	aspectRatio.DominantAxis = Enum.DominantAxis.Width
	aspectRatio.Parent = frame
end

local function tweenSize(object, endSize, time, callback)
	local tweenInfo = TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(object, tweenInfo, {Size = endSize})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DonateGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
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
headerTitle.Size = UDim2.new(0.3, 0, 1, 0)
headerTitle.Position = UDim2.new(0.025, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "💝 DONATE"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header
makeTextAdaptive(headerTitle, 20)

local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(0.35, 0, 0.6, 0)
progressFrame.Position = UDim2.new(0.4, 0, 0.5, 0)
progressFrame.AnchorPoint = Vector2.new(0, 0.5)
progressFrame.BackgroundColor3 = COLORS.Background
progressFrame.BorderSizePixel = 0
progressFrame.Parent = header

createCorner(8).Parent = progressFrame

local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(0.9, 0, 1, 0)
progressLabel.Position = UDim2.new(0.05, 0, 0, 0)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.GothamBold
progressLabel.Text = "R$0 / R$1000"
progressLabel.TextColor3 = COLORS.Premium
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Parent = progressFrame
makeTextAdaptive(progressLabel, 14)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.06, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.92, 0, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = COLORS.Text
closeBtn.Parent = header
makeTextAdaptive(closeBtn, 20)

createCorner(10).Parent = closeBtn

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.94, 0, 0.06, 0)
infoLabel.Position = UDim2.new(0.03, 0, 0.12, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "Terima kasih atas dukunganmu! Donasi R$1000+ akan mendapatkan title 'Donatur' 💎"
infoLabel.TextColor3 = COLORS.TextSecondary
infoLabel.TextWrapped = true
infoLabel.Parent = mainPanel
makeTextAdaptive(infoLabel, 13)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.92, 0, 0.72, 0)
scrollFrame.Position = UDim2.new(0.04, 0, 0.22, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.Border
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainPanel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.3, 0, 0.28, 0)
gridLayout.CellPadding = UDim2.new(0.04, 0, 0.04, 0)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollFrame

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0.02, 0)
scrollPadding.PaddingRight = UDim.new(0.02, 0)
scrollPadding.PaddingTop = UDim.new(0.02, 0)
scrollPadding.PaddingBottom = UDim.new(0.02, 0)
scrollPadding.Parent = scrollFrame

local function createDonationCard(packageData, index)
	local card = Instance.new("Frame")
	card.Name = packageData.Title
	card.BackgroundColor3 = COLORS.Panel
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = scrollFrame

	createCorner(10).Parent = card
	createStroke(packageData.Color, 2).Parent = card

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.3, 0)
	icon.Position = UDim2.new(0, 0, 0.05, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.Text = "💝"
	icon.TextColor3 = packageData.Color
	icon.Parent = card
	makeTextAdaptive(icon, 40)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0.38, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = packageData.Title
	titleLabel.TextColor3 = COLORS.Text
	titleLabel.Parent = card
	makeTextAdaptive(titleLabel, 16)

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
	descLabel.Position = UDim2.new(0.05, 0, 0.53, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = packageData.Description
	descLabel.TextColor3 = COLORS.TextSecondary
	descLabel.TextWrapped = true
	descLabel.Parent = card
	makeTextAdaptive(descLabel, 11)

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
	priceLabel.Position = UDim2.new(0.05, 0, 0.66, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = "R$" .. tostring(packageData.Amount)
	priceLabel.TextColor3 = COLORS.Premium
	priceLabel.Parent = card
	makeTextAdaptive(priceLabel, 20)

	local donateBtn = Instance.new("TextButton")
	donateBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
	donateBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
	donateBtn.BackgroundColor3 = packageData.Color
	donateBtn.BorderSizePixel = 0
	donateBtn.Font = Enum.Font.GothamBold
	donateBtn.Text = "Donate"
	donateBtn.TextColor3 = COLORS.Text
	donateBtn.AutoButtonColor = false
	donateBtn.Parent = card
	makeTextAdaptive(donateBtn, 14)

	createCorner(8).Parent = donateBtn

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Thickness = 1.5
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = donateBtn

	donateBtn.MouseEnter:Connect(function()
		TweenService:Create(donateBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	end)

	donateBtn.MouseLeave:Connect(function()
		TweenService:Create(donateBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
	end)

	donateBtn.MouseButton1Click:Connect(function()
		if packageData.ProductId == 0 then
			game.StarterGui:SetCore("SendNotification", {
				Title = "Donate",
				Text = "Product ID belum di-set! Hubungi admin.",
				Duration = 3,
			})
		else
			purchaseDonationEvent:FireServer(packageData.ProductId)
		end
	end)
end

local function updateDisplay()
	progressLabel.Text = string.format("R$%d / R$%d", donationData.TotalDonations, DonateConfig.DonationThreshold)

	if donationData.HasDonaturTitle then
		infoLabel.Text = "✅ Kamu sudah memiliki title 'Donatur'! Terima kasih atas dukunganmu! 💎"
		infoLabel.TextColor3 = COLORS.Success
	end
end

local function refreshData()
	local success, data = pcall(function()
		return getDonateDataFunc:InvokeServer()
	end)

	if success and data then
		donationData = data
		updateDisplay()
	end
end

local function showPanel()
	screenGui.Enabled = true
	mainPanel.Size = UDim2.new(0, 0, 0, 0)
	mainPanel.Visible = true
	tweenSize(mainPanel, UDim2.new(0.7, 0, 0.9, 0), 0.3)
	refreshData()
end

local function hidePanel()
	tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
		mainPanel.Visible = false
		mainPanel.Size = UDim2.new(0.7, 0, 0.9, 0)
		screenGui.Enabled = false
	end)
end

closeBtn.MouseButton1Click:Connect(hidePanel)

for index, package in ipairs(DonateConfig.Packages) do
	createDonationCard(package, index)
end

local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 30)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 999
spacer.Parent = scrollFrame

local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput, mousePos, framePos

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

makeDraggable(mainPanel, header)

local donateIcon = Icon.new()
	:setImage("rbxassetid://105261272857289")
	:setLabel("Donate")
	:bindEvent("selected", showPanel)
	:bindEvent("deselected", hidePanel)

print("✅ [DONATE CLIENT] System loaded")