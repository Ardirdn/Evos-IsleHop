local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local DanceConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DanceConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("DanceRemotes")
local toggleFavoriteEvent = remoteFolder:WaitForChild("ToggleFavorite")
local getFavoritesFunc = remoteFolder:WaitForChild("GetFavorites")

local danceComm = ReplicatedStorage:WaitForChild("DanceComm")
local StartDanceEvent = danceComm:WaitForChild("StartDance")
local StopDanceEvent = danceComm:WaitForChild("StopDance")
local SyncDanceEvent = danceComm:WaitForChild("SyncDance")
local UnsyncDanceEvent = danceComm:WaitForChild("UnsyncDance")
local SetSpeedEvent = danceComm:WaitForChild("SetSpeed")

local COLORS = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Button = Color3.fromRGB(35, 35, 38),
	Accent = Color3.fromRGB(70, 130, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Border = Color3.fromRGB(50, 50, 55),
}

local favorites = {}
local searchQuery = ""
local currentAnimation = nil
local animationSpeed = 1
local isCoordinateDancing = false

local Tracks = {}
local Animators = {}
local AnimationDatas = {}

local function createCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function makeTextAdaptive(textLabel, maxTextSize)
	textLabel.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxTextSize or 14
	constraint.MinTextSize = 1
	constraint.Parent = textLabel
end

local function addAspectRatio(frame, ratio)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = ratio or 0.8
	aspectRatio.DominantAxis = Enum.DominantAxis.Width
	aspectRatio.Parent = frame
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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DanceSystemGUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(1, 0, 0.8, 0)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.Background
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui

createCorner(15).Parent = mainPanel
addAspectRatio(mainPanel, 0.75)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.1, 0)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Parent = mainPanel

createCorner(15).Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.7, 0, 1, 0)
headerTitle.Position = UDim2.new(0.05, 0, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "DANCE"
headerTitle.TextColor3 = COLORS.Text
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header
makeTextAdaptive(headerTitle, 18)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.12, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.85, 0, 0.15, 0)
closeBtn.BackgroundColor3 = COLORS.Button
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = COLORS.Text
closeBtn.Parent = header
makeTextAdaptive(closeBtn, 20)

createCorner(8).Parent = closeBtn

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0.94, 0, 0.07, 0)
tabFrame.Position = UDim2.new(0.03, 0, 0.12, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainPanel

local allTab = Instance.new("TextButton")
allTab.Size = UDim2.new(0.48, 0, 1, 0)
allTab.BackgroundColor3 = COLORS.Accent
allTab.BorderSizePixel = 0
allTab.Text = "All"
allTab.Font = Enum.Font.GothamBold
allTab.TextColor3 = COLORS.Text
allTab.AutoButtonColor = false
allTab.Parent = tabFrame

createCorner(6).Parent = allTab
makeTextAdaptive(allTab, 13)

local favTab = Instance.new("TextButton")
favTab.Size = UDim2.new(0.48, 0, 1, 0)
favTab.Position = UDim2.new(0.52, 0, 0, 0)
favTab.BackgroundColor3 = COLORS.Button
favTab.BorderSizePixel = 0
favTab.Text = "Favorites"
favTab.Font = Enum.Font.GothamBold
favTab.TextColor3 = COLORS.Text
favTab.AutoButtonColor = false
favTab.Parent = tabFrame

createCorner(6).Parent = favTab
makeTextAdaptive(favTab, 13)

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(0.94, 0, 0.07, 0)
searchFrame.Position = UDim2.new(0.03, 0, 0.21, 0)
searchFrame.BackgroundColor3 = COLORS.Panel
searchFrame.BorderSizePixel = 0
searchFrame.Parent = mainPanel

createCorner(6).Parent = searchFrame

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0.1, 0, 1, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Font = Enum.Font.GothamBold
searchIcon.Text = "🔍"
searchIcon.TextColor3 = COLORS.TextSecondary
searchIcon.Parent = searchFrame
makeTextAdaptive(searchIcon, 14)

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.8, 0, 1, 0)
searchBox.Position = UDim2.new(0.1, 0, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search..."
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame
makeTextAdaptive(searchBox, 12)

local clearSearchBtn = Instance.new("TextButton")
clearSearchBtn.Size = UDim2.new(0.1, 0, 1, 0)
clearSearchBtn.Position = UDim2.new(0.9, 0, 0, 0)
clearSearchBtn.BackgroundTransparency = 1
clearSearchBtn.Text = "✕"
clearSearchBtn.Font = Enum.Font.GothamBold
clearSearchBtn.TextColor3 = COLORS.TextSecondary
clearSearchBtn.Visible = false
clearSearchBtn.Parent = searchFrame
makeTextAdaptive(clearSearchBtn, 14)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.94, 0, 0.5, 0)
scrollFrame.Position = UDim2.new(0.03, 0, 0.3, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.Border
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0.015, 0)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, 0, 0.15, 0)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.Text = "No animations found"
emptyLabel.TextColor3 = COLORS.TextSecondary
emptyLabel.Visible = false
emptyLabel.Parent = scrollFrame
makeTextAdaptive(emptyLabel, 12)

local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(0.94, 0, 0.15, 0)
speedFrame.Position = UDim2.new(0.03, 0, 0.82, 0)
speedFrame.BackgroundColor3 = COLORS.Panel
speedFrame.BorderSizePixel = 0
speedFrame.Parent = mainPanel

createCorner(8).Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
speedLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Text = "Speed: 1.0x"
speedLabel.TextColor3 = COLORS.Text
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame
makeTextAdaptive(speedLabel, 12)

local speedSliderBg = Instance.new("Frame")
speedSliderBg.Size = UDim2.new(0.9, 0, 0.15, 0)
speedSliderBg.Position = UDim2.new(0.05, 0, 0.65, 0)
speedSliderBg.BackgroundColor3 = COLORS.Button
speedSliderBg.BorderSizePixel = 0
speedSliderBg.Parent = speedFrame

createCorner(4).Parent = speedSliderBg

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0.5, 0, 1, 0)
speedSlider.BackgroundColor3 = COLORS.Accent
speedSlider.BorderSizePixel = 0
speedSlider.Parent = speedSliderBg

createCorner(4).Parent = speedSlider

local speedHandle = Instance.new("Frame")
speedHandle.Size = UDim2.new(0, 12, 0, 12)
speedHandle.Position = UDim2.new(0.5, -6, 0.5, -6)
speedHandle.BackgroundColor3 = COLORS.Text
speedHandle.BorderSizePixel = 0
speedHandle.Parent = speedSliderBg

createCorner(6).Parent = speedHandle

local function playAnim(targetPlayer, animData, synchronizedPlayer)
	local currentTrack = Tracks[targetPlayer]
	if currentTrack then
		currentTrack:Stop()
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animData.AnimationId

	local animator = Animators[targetPlayer]
	if not animator then
		animator = Instance.new("Animator")
		Animators[targetPlayer] = animator
	end

	local track = animator:LoadAnimation(anim)
	track:Play()
	track:AdjustSpeed(animData.Speed or 1)

	if synchronizedPlayer then
		local syncTrack = Tracks[synchronizedPlayer]
		if syncTrack then
			track.TimePosition = syncTrack.TimePosition
		end
	end

	Tracks[targetPlayer] = track
	AnimationDatas[targetPlayer] = animData
end

local function stopAnim(targetPlayer)
	local track = Tracks[targetPlayer]
	if track then
		track:Stop()
		Tracks[targetPlayer] = nil
	end
	AnimationDatas[targetPlayer] = nil
end

local function setSpeed(targetPlayer, speed)
	local track = Tracks[targetPlayer]
	if track then
		track:AdjustSpeed(speed)
	end
end

local function OnCharacterAdded(targetPlayer, char)
	local hum = char:WaitForChild("Humanoid")
	local anim = hum:FindFirstChildOfClass("Animator")
	Animators[targetPlayer] = anim

	if AnimationDatas[targetPlayer] then
		playAnim(targetPlayer, AnimationDatas[targetPlayer])
	end
end

local function OnPlayerAdded(targetPlayer)
	if targetPlayer.Character then
		OnCharacterAdded(targetPlayer, targetPlayer.Character)
	end
	targetPlayer.CharacterAdded:Connect(function(char)
		OnCharacterAdded(targetPlayer, char)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(p)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

StartDanceEvent.OnClientEvent:Connect(playAnim)
StopDanceEvent.OnClientEvent:Connect(stopAnim)
SetSpeedEvent.OnClientEvent:Connect(setSpeed)

local function isFavorite(title)
	return table.find(favorites, title) ~= nil
end

local function toggleFavorite(title)
	toggleFavoriteEvent:FireServer(title)

	if isFavorite(title) then
		local index = table.find(favorites, title)
		table.remove(favorites, index)
	else
		table.insert(favorites, title)
	end
end

local function playAnimation(animData)
	StartDanceEvent:FireServer(animData)
	currentAnimation = animData
end

local function stopAnimation()
	StopDanceEvent:FireServer()
	currentAnimation = nil
end

local function updateSpeedLabel()
	speedLabel.Text = string.format("Speed: %.1fx", animationSpeed)
	SetSpeedEvent:FireServer(animationSpeed)
end

local function createAnimItem(animData)
	local isPlaying = currentAnimation and currentAnimation.Title == animData.Title

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0.12, 0)
	frame.BackgroundColor3 = isPlaying and COLORS.Accent or COLORS.Panel
	frame.BorderSizePixel = 0
	frame.Parent = scrollFrame

	createCorner(6).Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = animData.Title
	titleLabel.TextColor3 = COLORS.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = frame
	makeTextAdaptive(titleLabel, 13)

	local favBtn = Instance.new("TextButton")
	favBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
	favBtn.Position = UDim2.new(0.8, 0, 0.15, 0)
	favBtn.BackgroundColor3 = COLORS.Button
	favBtn.BorderSizePixel = 0
	favBtn.Text = isFavorite(animData.Title) and "♥" or "♡"
	favBtn.Font = Enum.Font.GothamBold
	favBtn.TextColor3 = isFavorite(animData.Title) and Color3.fromRGB(255, 100, 100) or COLORS.TextSecondary
	favBtn.AutoButtonColor = false
	favBtn.Parent = frame
	makeTextAdaptive(favBtn, 16)

	createCorner(4).Parent = favBtn

	favBtn.MouseButton1Click:Connect(function()
		toggleFavorite(animData.Title)
		updateAnimList()
	end)

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(0.75, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = frame

	clickBtn.MouseButton1Click:Connect(function()
		if isPlaying then
			stopAnimation()
		else
			playAnimation(animData)
		end
		updateAnimList()
	end)
end

function updateAnimList()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local animsToShow = {}

	if allTab.BackgroundColor3 == COLORS.Accent then
		animsToShow = DanceConfig.Animations
	else
		for _, anim in ipairs(DanceConfig.Animations) do
			if isFavorite(anim.Title) then
				table.insert(animsToShow, anim)
			end
		end
	end

	if searchQuery ~= "" then
		local filtered = {}
		local lower = string.lower(searchQuery)
		for _, anim in ipairs(animsToShow) do
			if string.find(string.lower(anim.Title), lower, 1, true) or string.find(anim.AnimationId, searchQuery, 1, true) then
				table.insert(filtered, anim)
			end
		end
		animsToShow = filtered
	end

	if #animsToShow == 0 then
		emptyLabel.Visible = true
		emptyLabel.Text = searchQuery ~= "" and "Animasi tidak ditemukan" or "No animations found"
	else
		emptyLabel.Visible = false
		for _, anim in ipairs(animsToShow) do
			createAnimItem(anim)
		end
	end
end

local activeDragState = nil

local function makeDraggable(frame, handle)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeDragState = {
				frame = frame,
				mousePos = input.Position,
				framePos = frame.Position,
				dragging = true
			}

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if activeDragState and activeDragState.frame == frame then
						activeDragState = nil
					end
				end
			end)
		end
	end)
end

makeDraggable(mainPanel, header)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	screenGui.Enabled = false
end)

allTab.MouseButton1Click:Connect(function()
	allTab.BackgroundColor3 = COLORS.Accent
	favTab.BackgroundColor3 = COLORS.Button
	updateAnimList()
end)

favTab.MouseButton1Click:Connect(function()
	favTab.BackgroundColor3 = COLORS.Accent
	allTab.BackgroundColor3 = COLORS.Button
	updateAnimList()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = searchBox.Text
	clearSearchBtn.Visible = searchQuery ~= ""
	updateAnimList()
end)

clearSearchBtn.MouseButton1Click:Connect(function()
	searchBox.Text = ""
	searchQuery = ""
	clearSearchBtn.Visible = false
	updateAnimList()
end)

local draggingSpeed = false

speedSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
		local mouseX = UserInputService:GetMouseLocation().X
		local posX = speedSliderBg.AbsolutePosition.X
		local sizeX = speedSliderBg.AbsoluteSize.X
		local rel = math.clamp((mouseX - posX) / sizeX, 0, 1)

		speedSlider.Size = UDim2.new(rel, 0, 1, 0)
		speedHandle.Position = UDim2.new(rel, -6, 0.5, -6)

		animationSpeed = 0.1 + (rel * 3.9)
	end
end)

speedHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = false
		updateSpeedLabel()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

	if draggingSpeed then
		local mouseX = UserInputService:GetMouseLocation().X
		local posX = speedSliderBg.AbsolutePosition.X
		local sizeX = speedSliderBg.AbsoluteSize.X
		local rel = math.clamp((mouseX - posX) / sizeX, 0, 1)

		speedSlider.Size = UDim2.new(rel, 0, 1, 0)
		speedHandle.Position = UDim2.new(rel, -6, 0.5, -6)

		animationSpeed = 0.1 + (rel * 3.9)
	end

	if activeDragState and activeDragState.dragging then
		local delta = input.Position - activeDragState.mousePos
		local viewport = workspace.CurrentCamera.ViewportSize
		activeDragState.frame.Position = UDim2.new(
			activeDragState.framePos.X.Scale + (delta.X / viewport.X),
			0,
			activeDragState.framePos.Y.Scale + (delta.Y / viewport.Y),
			0
		)
	end
end)

local danceIcon = Icon.new()
	:setImage("rbxassetid://99793375909873")
	:setLabel("Dance")
	:bindEvent("selected", function()
		screenGui.Enabled = true
		mainPanel.Visible = true
		mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
		mainPanel.Size = UDim2.new(0, 0, 0, 0)

		tweenSize(mainPanel, UDim2.new(1, 0, 0.8, 0), 0.3)

		task.spawn(function()
			task.wait(2)
			local success, loaded = pcall(function()
				return getFavoritesFunc:InvokeServer()
			end)

			if success and loaded then
				favorites = loaded
				print(string.format("💃 [DANCE CLIENT] Loaded %d favorites", #favorites))
				if mainPanel.Visible then
					updateAnimList()
				end
			else
				warn("⚠️ [DANCE CLIENT] Failed to load favorites")
			end
		end)

		updateAnimList()
	end)
	:bindEvent("deselected", function()
		tweenSize(mainPanel, UDim2.new(0, 0, 0, 0), 0.3, function()
			screenGui.Enabled = false
			mainPanel.Visible = false
			mainPanel.Size = UDim2.new(1, 0, 0.8, 0)
		end)
	end)

print("✅ [DANCE CLIENT] System loaded")