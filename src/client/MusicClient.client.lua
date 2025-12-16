-- ROBLOX MUSIC PLAYER - FIXED VERSION
-- Letakkan script ini di StarterPlayer > StarterPlayerScripts
-- Requires: TopbarPlus module (https://devforum.roblox.com/t/topbarplus/1017485)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Require TopbarPlus Icon module
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local MusicConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MusicConfig"))

-- RemoteEvents untuk Favorites
local musicRemoteFolder = ReplicatedStorage:WaitForChild("MusicRemotes")
local toggleFavoriteMusicEvent = musicRemoteFolder:WaitForChild("ToggleFavorite")
local getFavoritesMusicFunc = musicRemoteFolder:WaitForChild("GetFavorites")

-- Helper function to apply TextScaled with size constraint (✅ UPDATED - No MinTextSize)
local function applyTextScaling(textObject, maxSize)
	maxSize = maxSize or 16
	textObject.TextScaled = true
	local sizeConstraint = Instance.new("UITextSizeConstraint")
	sizeConstraint.MaxTextSize = maxSize
	sizeConstraint.MinTextSize = 1  -- ✅ No minimum size
	sizeConstraint.Parent = textObject
end

-- ✅ Helper: Add UIAspectRatioConstraint to main frames
local function addAspectRatio(frame, ratio)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = ratio or 0.75
	aspectRatio.DominantAxis = Enum.DominantAxis.Width
	aspectRatio.Parent = frame
end

-- ✅ Helper: tweenSize for animations
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

-- ==================== CREATE MAIN GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MusicPlayerGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

-- ==================== MUSIC PLAYER ====================
local musicFrame = Instance.new("Frame")
musicFrame.Name = "MusicPlayer"
musicFrame.Size = UDim2.new(0.7, 0, 0.8, 0)  -- 450/1920, 480/1080
musicFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
musicFrame.AnchorPoint = Vector2.new(0.5, 0.5)
musicFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
musicFrame.BorderSizePixel = 0
musicFrame.Visible = false
musicFrame.ClipsDescendants = true
musicFrame.Parent = screenGui

local musicCorner = Instance.new("UICorner")
musicCorner.CornerRadius = UDim.new(0, 15)
musicCorner.Parent = musicFrame

local musicStroke = Instance.new("UIStroke")
musicStroke.Color = Color3.fromRGB(50, 50, 55)
musicStroke.Thickness = 1
musicStroke.Parent = musicFrame

local musicAspectRatio = Instance.new("UIAspectRatioConstraint")
musicAspectRatio.AspectRatio = 0.75
musicAspectRatio.Parent = musicFrame

-- Music Header
local musicHeader = Instance.new("Frame")
musicHeader.Size = UDim2.new(1, 0, 0.104, 0)
musicHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
musicHeader.BorderSizePixel = 0
musicHeader.Parent = musicFrame

local musicHeaderCorner = Instance.new("UICorner")
musicHeaderCorner.CornerRadius = UDim.new(0, 15)
musicHeaderCorner.Parent = musicHeader

local musicHeaderBottom = Instance.new("Frame")
musicHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
musicHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
musicHeaderBottom.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
musicHeaderBottom.BorderSizePixel = 0
musicHeaderBottom.Parent = musicHeader

local musicTitle = Instance.new("TextLabel")
musicTitle.Size = UDim2.new(0.778, 0, 1, 0)  -- (450-100)/450
musicTitle.Position = UDim2.new(0.044, 0, 0, 0)
musicTitle.BackgroundTransparency = 1
musicTitle.Text = "MUSIC PLAYER"
musicTitle.Font = Enum.Font.GothamBold
musicTitle.TextSize = 16
musicTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
musicTitle.TextXAlignment = Enum.TextXAlignment.Left
musicTitle.Parent = musicHeader

local musicCloseBtn = Instance.new("TextButton")
musicCloseBtn.Size = UDim2.new(0.089, 0, 0.8, 0)
musicCloseBtn.Position = UDim2.new(0.9, 0, 0.5, 0)
musicCloseBtn.AnchorPoint = Vector2.new(0, 0.5)
musicCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
musicCloseBtn.BorderSizePixel = 0
musicCloseBtn.Text = "✕"
musicCloseBtn.Font = Enum.Font.GothamBold
musicCloseBtn.TextSize = 18
musicCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
musicCloseBtn.Parent = musicHeader

local musicCloseBtnCorner = Instance.new("UICorner")
musicCloseBtnCorner.CornerRadius = UDim.new(0, 10)
musicCloseBtnCorner.Parent = musicCloseBtn

-- Song Title Display
local songTitleLabel = Instance.new("TextLabel")
songTitleLabel.Size = UDim2.new(0.822, 0, 0.063, 0)  -- (450-80)/450, 30/480
songTitleLabel.Position = UDim2.new(0.044, 0, 0.125, 0)
songTitleLabel.BackgroundTransparency = 1
songTitleLabel.Text = "No Song Playing"
songTitleLabel.Font = Enum.Font.GothamBold
songTitleLabel.TextSize = 18
songTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
songTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
songTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
songTitleLabel.Parent = musicFrame

-- Favorite Button
local favoriteBtn = Instance.new("TextButton")
favoriteBtn.Size = UDim2.new(0.089, 0, 0.083, 0)  -- 40/450, 40/480
favoriteBtn.Position = UDim2.new(0.878, 0, 0.115, 0)
favoriteBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
favoriteBtn.BorderSizePixel = 0
favoriteBtn.Text = "♡"
favoriteBtn.Font = Enum.Font.GothamBold
favoriteBtn.TextSize = 20
favoriteBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
favoriteBtn.Parent = musicFrame

local favoriteBtnCorner = Instance.new("UICorner")
favoriteBtnCorner.CornerRadius = UDim.new(0, 10)
favoriteBtnCorner.Parent = favoriteBtn

-- Playlist Display (Changed to show current playlist)
local playlistLabel = Instance.new("TextLabel")
playlistLabel.Size = UDim2.new(0.911, 0, 0.042, 0)  -- 20/480
playlistLabel.Position = UDim2.new(0.044, 0, 0.208, 0) 
playlistLabel.BackgroundTransparency = 1
playlistLabel.Text = "Playlist: None"
playlistLabel.Font = Enum.Font.Gotham
playlistLabel.TextSize = 12
playlistLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
playlistLabel.TextXAlignment = Enum.TextXAlignment.Left
playlistLabel.Parent = musicFrame

-- Time Labels
local currentTimeLabel = Instance.new("TextLabel")
currentTimeLabel.Size = UDim2.new(0.133, 0, 0.042, 0)
currentTimeLabel.Position = UDim2.new(0.044, 0, 0.271, 0)
currentTimeLabel.BackgroundTransparency = 1
currentTimeLabel.Text = "0:00"
currentTimeLabel.Font = Enum.Font.Gotham
currentTimeLabel.TextSize = 11
currentTimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
currentTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
currentTimeLabel.Parent = musicFrame

local totalTimeLabel = Instance.new("TextLabel")
totalTimeLabel.Size = UDim2.new(0.133, 0, 0.042, 0)
totalTimeLabel.Position = UDim2.new(0.822, 0, 0.271, 0)
totalTimeLabel.BackgroundTransparency = 1
totalTimeLabel.Text = "0:00"
totalTimeLabel.Font = Enum.Font.Gotham
totalTimeLabel.TextSize = 11
totalTimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
totalTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
totalTimeLabel.Parent = musicFrame

-- Progress Bar
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0.911, 0, 0.013, 0)
progressBg.Position = UDim2.new(0.044, 0, 0.323, 0)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
progressBg.BorderSizePixel = 0
progressBg.Parent = musicFrame

local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(1, 0)
progressBgCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(1, 0)
progressBarCorner.Parent = progressBar

-- Control Buttons
local controlsFrame = Instance.new("Frame")
controlsFrame.Size = UDim2.new(0.911, 0, 0.104, 0)  -- 50/480
controlsFrame.Position = UDim2.new(0.044, 0, 0.375, 0)
controlsFrame.BackgroundTransparency = 1
controlsFrame.Parent = musicFrame

-- GANTI fungsi createControlButton:
local function createControlButton(name, text, position)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.122, 0, 1, 0)  -- 50/410 (frame width minus padding)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = controlsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn

	return btn
end

-- Update positions:
local prevBtn = createControlButton("Previous", "⏮", UDim2.new(0.268, 0, 0, 0))  -- Center - 110/410
local playPauseBtn = createControlButton("PlayPause", "▶", UDim2.new(0.439, 0, 0, 0))  -- Center - 25/410
local nextBtn = createControlButton("Next", "⏭", UDim2.new(0.610, 0, 0, 0))

-- Volume Control
local volumeLabel = Instance.new("TextLabel")
volumeLabel.Size = UDim2.new(0.222, 0, 0.042, 0)
volumeLabel.Position = UDim2.new(0.044, 0, 0.510, 0)
volumeLabel.BackgroundTransparency = 1
volumeLabel.Text = "Volume: 50%"
volumeLabel.Font = Enum.Font.Gotham
volumeLabel.TextSize = 12
volumeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
volumeLabel.Parent = musicFrame

-- Volume Decrease Button
local volumeDecBtn = Instance.new("TextButton")
volumeDecBtn.Size = UDim2.new(0.067, 0, 0.063, 0)
volumeDecBtn.Position = UDim2.new(0.044, 0, 0.552, 0)
volumeDecBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
volumeDecBtn.BorderSizePixel = 0
volumeDecBtn.Text = "-"
volumeDecBtn.Font = Enum.Font.GothamBold
volumeDecBtn.TextSize = 18
volumeDecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
volumeDecBtn.Parent = musicFrame

local volumeDecBtnCorner = Instance.new("UICorner")
volumeDecBtnCorner.CornerRadius = UDim.new(0, 8)
volumeDecBtnCorner.Parent = volumeDecBtn

-- Volume Slider Background
local volumeSliderBg = Instance.new("Frame")
volumeSliderBg.Size = UDim2.new(0.756, 0, 0.013, 0)
volumeSliderBg.Position = UDim2.new(0.122, 0, 0.577, 0)
volumeSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
volumeSliderBg.BorderSizePixel = 0
volumeSliderBg.Parent = musicFrame

local volumeSliderBgCorner = Instance.new("UICorner")
volumeSliderBgCorner.CornerRadius = UDim.new(1, 0)
volumeSliderBgCorner.Parent = volumeSliderBg

local volumeSlider = Instance.new("Frame")
volumeSlider.Size = UDim2.new(0.5, 0, 1, 0)
volumeSlider.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
volumeSlider.BorderSizePixel = 0
volumeSlider.Parent = volumeSliderBg

local volumeSliderCorner = Instance.new("UICorner")
volumeSliderCorner.CornerRadius = UDim.new(1, 0)
volumeSliderCorner.Parent = volumeSlider

-- Volume Increase Button
local volumeIncBtn = Instance.new("TextButton")
volumeIncBtn.Size = UDim2.new(0.067, 0, 0.063, 0)
volumeIncBtn.Position = UDim2.new(0.889, 0, 0.552, 0)
volumeIncBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
volumeIncBtn.BorderSizePixel = 0
volumeIncBtn.Text = "+"
volumeIncBtn.Font = Enum.Font.GothamBold
volumeIncBtn.TextSize = 18
volumeIncBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
volumeIncBtn.Parent = musicFrame

local volumeIncBtnCorner = Instance.new("UICorner")
volumeIncBtnCorner.CornerRadius = UDim.new(0, 8)
volumeIncBtnCorner.Parent = volumeIncBtn

-- Next Song Info (NEW POSITION)
local nextSongFrame = Instance.new("Frame")
nextSongFrame.Size = UDim2.new(0.489, 0, 0.094, 0)
nextSongFrame.Position = UDim2.new(0.044, 0, 0.646, 0)
nextSongFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
nextSongFrame.BorderSizePixel = 0
nextSongFrame.Parent = musicFrame

local nextSongFrameCorner = Instance.new("UICorner")
nextSongFrameCorner.CornerRadius = UDim.new(0, 10)
nextSongFrameCorner.Parent = nextSongFrame

local nextSongLabel = Instance.new("TextLabel")
nextSongLabel.Size = UDim2.new(0.909, 0, 0.4, 0)
nextSongLabel.Position = UDim2.new(0.045, 0, 0.111, 0)
nextSongLabel.BackgroundTransparency = 1
nextSongLabel.Text = "NEXT SONG"
nextSongLabel.Font = Enum.Font.GothamBold
nextSongLabel.TextSize = 10
nextSongLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
nextSongLabel.TextXAlignment = Enum.TextXAlignment.Left
nextSongLabel.Parent = nextSongFrame

local nextSongTitleLabel = Instance.new("TextLabel")
nextSongTitleLabel.Size = UDim2.new(0.909, 0, 0.444, 0)
nextSongTitleLabel.Position = UDim2.new(0.045, 0, 0.489, 0)
nextSongTitleLabel.BackgroundTransparency = 1
nextSongTitleLabel.Text = "None"
nextSongTitleLabel.Font = Enum.Font.Gotham
nextSongTitleLabel.TextSize = 12
nextSongTitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
nextSongTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
nextSongTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
nextSongTitleLabel.Parent = nextSongFrame

-- Queue Button (NEW)
local queueBtn = Instance.new("TextButton")
queueBtn.Size = UDim2.new(0.4, 0, 0.094, 0)
queueBtn.Position = UDim2.new(0.556, 0, 0.646, 0)
queueBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
queueBtn.BorderSizePixel = 0
queueBtn.Text = "VIEW QUEUE"
queueBtn.Font = Enum.Font.GothamBold
queueBtn.TextSize = 12
queueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
queueBtn.Parent = musicFrame

local queueBtnCorner = Instance.new("UICorner")
queueBtnCorner.CornerRadius = UDim.new(0, 10)
queueBtnCorner.Parent = queueBtn

-- Library Button
local libraryBtn = Instance.new("TextButton")
libraryBtn.Size = UDim2.new(0.911, 0, 0.094, 0)
libraryBtn.Position = UDim2.new(0.044, 0, 0.760, 0)
libraryBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
libraryBtn.BorderSizePixel = 0
libraryBtn.Text = "OPEN LIBRARY"
libraryBtn.Font = Enum.Font.GothamBold
libraryBtn.TextSize = 14
libraryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
libraryBtn.Parent = musicFrame

local libraryBtnCorner = Instance.new("UICorner")
libraryBtnCorner.CornerRadius = UDim.new(0, 10)
libraryBtnCorner.Parent = libraryBtn

-- Add Queue Info Label
local queueInfoLabel = Instance.new("TextLabel")
queueInfoLabel.Size = UDim2.new(0.911, 0, 0.042, 0)
queueInfoLabel.Position = UDim2.new(0.044, 0, 0.875, 0)
queueInfoLabel.BackgroundTransparency = 1
queueInfoLabel.Text = "Queue: 0 songs"
queueInfoLabel.Font = Enum.Font.Gotham
queueInfoLabel.TextSize = 11
queueInfoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
queueInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
queueInfoLabel.Parent = musicFrame

-- ==================== QUEUE PANEL ====================
local queuePanel = Instance.new("Frame")
queuePanel.Size = UDim2.new(0.7, 0, 0.8, 0)  -- 350/1920, 480/1080
queuePanel.Position = UDim2.new(0.622, 0, -0.5, 0)  -- 0.5 + (235/1920)
queuePanel.AnchorPoint = Vector2.new(0, 0.5)
queuePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
queuePanel.BorderSizePixel = 0
queuePanel.Visible = false
queuePanel.ClipsDescendants = true
queuePanel.Parent = screenGui

local queuePanelCorner = Instance.new("UICorner")
queuePanelCorner.CornerRadius = UDim.new(0, 15)
queuePanelCorner.Parent = queuePanel

local queuePanelStroke = Instance.new("UIStroke")
queuePanelStroke.Color = Color3.fromRGB(50, 50, 55)
queuePanelStroke.Thickness = 1
queuePanelStroke.Parent = queuePanel

local queueAspectRatio = Instance.new("UIAspectRatioConstraint")
queueAspectRatio.AspectRatio = 0.75
queueAspectRatio.Parent = queuePanel

-- Queue Header
local queueHeader = Instance.new("Frame")
queueHeader.Size = UDim2.new(1, 0, 0.104, 0)
queueHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
queueHeader.BorderSizePixel = 0
queueHeader.Parent = queuePanel

local queueHeaderCorner = Instance.new("UICorner")
queueHeaderCorner.CornerRadius = UDim.new(0, 15)
queueHeaderCorner.Parent = queueHeader

local queueHeaderBottom = Instance.new("Frame")
queueHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
queueHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
queueHeaderBottom.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
queueHeaderBottom.BorderSizePixel = 0
queueHeaderBottom.Parent = queueHeader

local queueHeaderTitle = Instance.new("TextLabel")
queueHeaderTitle.Size = UDim2.new(0.714, 0, 1, 0)
queueHeaderTitle.Position = UDim2.new(0.057, 0, 0, 0)
queueHeaderTitle.BackgroundTransparency = 1
queueHeaderTitle.Text = "SONGS QUEUE"
queueHeaderTitle.Font = Enum.Font.GothamBold
queueHeaderTitle.TextSize = 16
queueHeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
queueHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
queueHeaderTitle.Parent = queueHeader

local queueCloseBtn = Instance.new("TextButton")
queueCloseBtn.Size = UDim2.new(0.114, 0, 0.8, 0)
queueCloseBtn.Position = UDim2.new(0.871, 0, 0.5, 0)
queueCloseBtn.AnchorPoint = Vector2.new(0, 0.5)
queueCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
queueCloseBtn.BorderSizePixel = 0
queueCloseBtn.Text = "✕"
queueCloseBtn.Font = Enum.Font.GothamBold
queueCloseBtn.TextSize = 18
queueCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
queueCloseBtn.Parent = queueHeader

local queueCloseBtnCorner = Instance.new("UICorner")
queueCloseBtnCorner.CornerRadius = UDim.new(0, 10)
queueCloseBtnCorner.Parent = queueCloseBtn

-- Queue ScrollFrame
local queueScroll = Instance.new("ScrollingFrame")
queueScroll.Size = UDim2.new(0.886, 0, 0.854, 0)  -- (480-70)/480
queueScroll.Position = UDim2.new(0.057, 0, 0.125, 0)
queueScroll.BackgroundTransparency = 1
queueScroll.BorderSizePixel = 0
queueScroll.ScrollBarThickness = 6
queueScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
queueScroll.Parent = queuePanel

local queueLayout = Instance.new("UIListLayout")
queueLayout.SortOrder = Enum.SortOrder.LayoutOrder
queueLayout.Padding = UDim.new(0, 5)
queueLayout.Parent = queueScroll

-- Empty Queue Label
local emptyQueueLabel = Instance.new("TextLabel")
emptyQueueLabel.Size = UDim2.new(1, -10, 0, 100)
emptyQueueLabel.Position = UDim2.new(0, 5, 0, 100)
emptyQueueLabel.BackgroundTransparency = 1
emptyQueueLabel.Text = "No songs in queue"
emptyQueueLabel.Font = Enum.Font.Gotham
emptyQueueLabel.TextSize = 14
emptyQueueLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
emptyQueueLabel.Visible = true
emptyQueueLabel.Parent = queueScroll

-- ==================== LIBRARY FRAME ====================
local libraryFrame = Instance.new("Frame")
libraryFrame.Size = UDim2.new(0.7, 0, 0.8, 0)  -- 500/1920, 550/1080
libraryFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
libraryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
libraryFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
libraryFrame.BorderSizePixel = 0
libraryFrame.Visible = false
libraryFrame.ClipsDescendants = true
libraryFrame.Parent = screenGui

local libraryFrameCorner = Instance.new("UICorner")
libraryFrameCorner.CornerRadius = UDim.new(0, 15)
libraryFrameCorner.Parent = libraryFrame

local libraryFrameStroke = Instance.new("UIStroke")
libraryFrameStroke.Color = Color3.fromRGB(50, 50, 55)
libraryFrameStroke.Thickness = 1
libraryFrameStroke.Parent = libraryFrame

local libraryAspectRatio = Instance.new("UIAspectRatioConstraint")
libraryAspectRatio.AspectRatio = 0.75
libraryAspectRatio.Parent = libraryFrame

-- Library Header
local libraryHeader = Instance.new("Frame")
libraryHeader.Size = UDim2.new(1, 0, 0.091, 0)
libraryHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
libraryHeader.BorderSizePixel = 0
libraryHeader.Parent = libraryFrame

local libraryHeaderCorner = Instance.new("UICorner")
libraryHeaderCorner.CornerRadius = UDim.new(0, 15)
libraryHeaderCorner.Parent = libraryHeader

local libraryHeaderBottom = Instance.new("Frame")
libraryHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
libraryHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
libraryHeaderBottom.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
libraryHeaderBottom.BorderSizePixel = 0
libraryHeaderBottom.Parent = libraryHeader

local libraryHeaderTitle = Instance.new("TextLabel")
libraryHeaderTitle.Size = UDim2.new(0.8, 0, 1, 0)
libraryHeaderTitle.Position = UDim2.new(0.04, 0, 0, 0)
libraryHeaderTitle.BackgroundTransparency = 1
libraryHeaderTitle.Text = "MUSIC LIBRARY"
libraryHeaderTitle.Font = Enum.Font.GothamBold
libraryHeaderTitle.TextSize = 16
libraryHeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
libraryHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
libraryHeaderTitle.Parent = libraryHeader

local libraryCloseBtn = Instance.new("TextButton")
libraryCloseBtn.Size = UDim2.new(0.08, 0, 0.8, 0)
libraryCloseBtn.Position = UDim2.new(0.91, 0, 0.5, 0)
libraryCloseBtn.AnchorPoint = Vector2.new(0, 0.5)
libraryCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
libraryCloseBtn.BorderSizePixel = 0
libraryCloseBtn.Text = "✕"
libraryCloseBtn.Font = Enum.Font.GothamBold
libraryCloseBtn.TextSize = 18
libraryCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
libraryCloseBtn.Parent = libraryHeader

local libraryCloseBtnCorner = Instance.new("UICorner")
libraryCloseBtnCorner.CornerRadius = UDim.new(0, 10)
libraryCloseBtnCorner.Parent = libraryCloseBtn

-- Tab Buttons
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0.92, 0, 0.082, 0)  -- 45/550
tabFrame.Position = UDim2.new(0.04, 0, 0.109, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = libraryFrame

local function createTabButton(name, text, position, order)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.32, 0, 1, 0)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(150, 150, 150)
	btn.Parent = tabFrame
	btn.LayoutOrder = order

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	return btn
end

local allTab = createTabButton("AllTab", "ALL SONGS", UDim2.new(0, 0, 0, 0), 1)
local playlistsTab = createTabButton("PlaylistsTab", "PLAYLISTS", UDim2.new(0.33, 0, 0, 0), 2)
local favoritesTab = createTabButton("FavoritesTab", "FAVORITES", UDim2.new(0.66, 0, 0, 0), 3)

-- Content ScrollFrame
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(0.92, 0, 0.773, 0)  -- (550-125)/550
contentScroll.Position = UDim2.new(0.04, 0, 0.209, 0)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 6
contentScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
contentScroll.Parent = libraryFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = contentScroll

-- ==================== SONG DETAILS FRAME ====================
local songDetailsFrame = Instance.new("Frame")
songDetailsFrame.Size = UDim2.new(0.234, 0, 0.463, 0)  -- 450/1920, 500/1080
songDetailsFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
songDetailsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
songDetailsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
songDetailsFrame.BorderSizePixel = 0
songDetailsFrame.Visible = false
songDetailsFrame.ClipsDescendants = true
songDetailsFrame.Parent = screenGui

local songDetailsCorner = Instance.new("UICorner")
songDetailsCorner.CornerRadius = UDim.new(0, 15)
songDetailsCorner.Parent = songDetailsFrame

local songDetailsStroke = Instance.new("UIStroke")
songDetailsStroke.Color = Color3.fromRGB(50, 50, 55)
songDetailsStroke.Thickness = 1
songDetailsStroke.Parent = songDetailsFrame

local songDetailsAspectRatio = Instance.new("UIAspectRatioConstraint")
songDetailsAspectRatio.AspectRatio = 0.75
songDetailsAspectRatio.Parent = songDetailsFrame

-- Song Details Header
local songDetailsHeader = Instance.new("Frame")
songDetailsHeader.Size = UDim2.new(1, 0, 0.1, 0)
songDetailsHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
songDetailsHeader.BorderSizePixel = 0
songDetailsHeader.Parent = songDetailsFrame

local songDetailsHeaderCorner = Instance.new("UICorner")
songDetailsHeaderCorner.CornerRadius = UDim.new(0, 15)
songDetailsHeaderCorner.Parent = songDetailsHeader

local songDetailsHeaderBottom = Instance.new("Frame")
songDetailsHeaderBottom.Size = UDim2.new(1, 0, 0, 15)
songDetailsHeaderBottom.Position = UDim2.new(0, 0, 1, -15)
songDetailsHeaderBottom.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
songDetailsHeaderBottom.BorderSizePixel = 0
songDetailsHeaderBottom.Parent = songDetailsHeader

local songDetailsTitle = Instance.new("TextLabel")
songDetailsTitle.Size = UDim2.new(0.778, 0, 1, 0)
songDetailsTitle.Position = UDim2.new(0.044, 0, 0, 0)
songDetailsTitle.BackgroundTransparency = 1
songDetailsTitle.Text = "PLAYLIST SONGS"
songDetailsTitle.Font = Enum.Font.GothamBold
songDetailsTitle.TextSize = 16
songDetailsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
songDetailsTitle.TextXAlignment = Enum.TextXAlignment.Left
songDetailsTitle.Parent = songDetailsHeader

local songDetailsCloseBtn = Instance.new("TextButton")
songDetailsCloseBtn.Size = UDim2.new(0.089, 0, 0.8, 0)
songDetailsCloseBtn.Position = UDim2.new(0.9, 0, 0.5, 0)
songDetailsCloseBtn.AnchorPoint = Vector2.new(0, 0.5)
songDetailsCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
songDetailsCloseBtn.BorderSizePixel = 0
songDetailsCloseBtn.Text = "✕"
songDetailsCloseBtn.Font = Enum.Font.GothamBold
songDetailsCloseBtn.TextSize = 18
songDetailsCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
songDetailsCloseBtn.Parent = songDetailsHeader

local songDetailsCloseBtnCorner = Instance.new("UICorner")
songDetailsCloseBtnCorner.CornerRadius = UDim.new(0, 10)
songDetailsCloseBtnCorner.Parent = songDetailsCloseBtn

-- Song List ScrollFrame
local songListScroll = Instance.new("ScrollingFrame")
songListScroll.Size = UDim2.new(0.911, 0, 0.76, 0)
songListScroll.Position = UDim2.new(0.044, 0, 0.12, 0)
songListScroll.BackgroundTransparency = 1
songListScroll.BorderSizePixel = 0
songListScroll.ScrollBarThickness = 6
songListScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
songListScroll.Parent = songDetailsFrame

local songListLayout = Instance.new("UIListLayout")
songListLayout.SortOrder = Enum.SortOrder.LayoutOrder
songListLayout.Padding = UDim.new(0, 5)
songListLayout.Parent = songListScroll

-- Play All Button
local playAllBtn = Instance.new("TextButton")
playAllBtn.Size = UDim2.new(0.911, 0, 0.09, 0)
playAllBtn.Position = UDim2.new(0.044, 0, 0.89, 0)
playAllBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
playAllBtn.BorderSizePixel = 0
playAllBtn.Text = "PLAY ALL"
playAllBtn.Font = Enum.Font.GothamBold
playAllBtn.TextSize = 14
playAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playAllBtn.Parent = songDetailsFrame

local playAllBtnCorner = Instance.new("UICorner")
playAllBtnCorner.CornerRadius = UDim.new(0, 10)
playAllBtnCorner.Parent = playAllBtn

-- Apply TextScaled to all static text elements in main frames
local function applyTextScalingToFrame(frame, maxSize)
	for _, descendant in ipairs(frame:GetDescendants()) do
		if (descendant:IsA("TextLabel") or descendant:IsA("TextButton")) and not descendant:FindFirstChild("UITextSizeConstraint") then
			applyTextScaling(descendant, maxSize or descendant.TextSize)
		end
	end
end

-- Apply to all main frames
applyTextScalingToFrame(musicFrame, 18)
applyTextScalingToFrame(queuePanel, 16)
applyTextScalingToFrame(libraryFrame, 16)
applyTextScalingToFrame(songDetailsFrame, 16)

-- ==================== MUSIC PLAYER LOGIC ====================
local currentSound = nil
local currentPlaylist = nil
local currentIndex = 1
local playlists = {}
local allSongs = {}
local favorites = {}
local favoritesData = {} -- Store as "PlaylistName/SongName" strings
local queue = {}
local isPlaying = false
local isDraggingProgress = false
local isDraggingVolume = false
local currentTab = "all"
local currentPlaylistSongs = {}
local autoPlayStarted = false

-- Forward declarations for functions
local updateLibraryContent
local updateFavoriteButton
local updateQueueDisplay
local saveFavorites
local loadFavorites
local updateQueuePanel

local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

local function loadPlaylists()
	playlists = {}
	allSongs = {}
	
	-- ✅ Create a folder in SoundService for organization
	local SoundService = game:GetService("SoundService")
	local musicFolder = SoundService:FindFirstChild("MusicPlayerSounds")
	if not musicFolder then
		musicFolder = Instance.new("Folder")
		musicFolder.Name = "MusicPlayerSounds"
		musicFolder.Parent = SoundService
	end

	-- Load from MusicConfig
	for playlistName, playlistData in pairs(MusicConfig.Playlists) do
		local songs = {}

		for _, songData in ipairs(playlistData.Songs) do
			-- Create Sound object in SoundService (better than workspace)
			local sound = Instance.new("Sound")
			sound.Name = songData.Title
			sound.SoundId = songData.AssetId
			sound.Volume = MusicConfig.Settings.DefaultVolume
			sound.Looped = false
			sound.Parent = musicFolder  -- ✅ Parent to SoundService folder

			table.insert(songs, sound)
			table.insert(allSongs, sound)
		end

		if #songs > 0 then
			playlists[playlistName] = songs
		end
	end

	-- Wait for sounds to load
	task.wait(1)

	print(string.format("✅ Loaded %d playlists with %d total songs", 
		#playlists, #allSongs))
end

-- Load favorites from DataStore (NEW - server-side)
loadFavorites = function()
	task.spawn(function()
		task.wait(2) -- Wait for DataHandler to load

		local success, loadedFavorites = pcall(function()
			return getFavoritesMusicFunc:InvokeServer()
		end)

		if success and loadedFavorites then
			favoritesData = loadedFavorites
			favorites = {}

			-- Convert stored IDs back to Sound objects
			for _, id in ipairs(favoritesData) do
				local parts = string.split(id, "/")
				if #parts == 2 then
					local playlistName = parts[1]
					local soundName = parts[2]
					if playlists[playlistName] then
						for _, sound in ipairs(playlists[playlistName]) do
							if sound.Name == soundName then
								table.insert(favorites, sound)
								break
							end
						end
					end
				end
			end

			print(string.format("🎵 [MUSIC CLIENT] Loaded %d favorite songs", #favorites))

			-- Refresh UI if library is open
			if libraryFrame.Visible then
				updateLibraryContent()
			end
		else
			warn("⚠️ [MUSIC CLIENT] Failed to load favorites")
		end
	end)
end


updateQueueDisplay = function()
	-- Update next song display
	if #queue > 0 then
		nextSongTitleLabel.Text = queue[1].Name
	elseif currentPlaylist and playlists[currentPlaylist] then
		local songs = playlists[currentPlaylist]
		local nextIndex = currentIndex + 1
		if nextIndex > #songs then
			nextIndex = 1
		end
		nextSongTitleLabel.Text = songs[nextIndex].Name
	else
		nextSongTitleLabel.Text = "None"
	end

	-- Update queue info
	queueInfoLabel.Text = "Queue: "..#queue.." songs"
end

updateQueuePanel = function()
	-- Clear existing queue items
	for _, child in ipairs(queueScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if #queue == 0 then
		emptyQueueLabel.Visible = true
	else
		emptyQueueLabel.Visible = false

		for i, song in ipairs(queue) do
			local queueItem = Instance.new("Frame")
			queueItem.Size = UDim2.new(0.968, 0, 0.09, 0)
			queueItem.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
			queueItem.BorderSizePixel = 0
			queueItem.LayoutOrder = i
			queueItem.Parent = queueScroll

			local queueItemCorner = Instance.new("UICorner")
			queueItemCorner.CornerRadius = UDim.new(0, 8)
			queueItemCorner.Parent = queueItem

			local queueNumLabel = Instance.new("TextLabel")
			queueNumLabel.Size = UDim2.new(0.088, 0, 1, 0)  -- 30/340
			queueNumLabel.Position = UDim2.new(0.029, 0, 0, 0)
			queueNumLabel.BackgroundTransparency = 1
			queueNumLabel.Text = i
			queueNumLabel.Font = Enum.Font.GothamBold
			queueNumLabel.TextSize = 12
			queueNumLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			queueNumLabel.Parent = queueItem

			local queueSongNameLabel = Instance.new("TextLabel")
			queueSongNameLabel.Size = UDim2.new(0.676, 0, 0.364, 0)  -- (340-110)/340, 20/55
			queueSongNameLabel.Position = UDim2.new(0.132, 0, 0.182, 0)
			queueSongNameLabel.BackgroundTransparency = 1
			queueSongNameLabel.Text = song.Name
			queueSongNameLabel.Font = Enum.Font.Gotham
			queueSongNameLabel.TextSize = 12
			queueSongNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			queueSongNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			queueSongNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			queueSongNameLabel.Parent = queueItem

			local queueDurLabel = Instance.new("TextLabel")
			queueDurLabel.Size = UDim2.new(0.676, 0, 0.273, 0)
			queueDurLabel.Position = UDim2.new(0.132, 0, 0.582, 0)
			queueDurLabel.BackgroundTransparency = 1
			queueDurLabel.Text = formatTime(song.TimeLength)
			queueDurLabel.Font = Enum.Font.Gotham
			queueDurLabel.TextSize = 10
			queueDurLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			queueDurLabel.TextXAlignment = Enum.TextXAlignment.Left
			queueDurLabel.Parent = queueItem

			local removeBtn = Instance.new("TextButton")
			removeBtn.Size = UDim2.new(0.147, 0, 0.727, 0)
			removeBtn.Position = UDim2.new(0.832, 0, 0.145, 0)
			removeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			removeBtn.BorderSizePixel = 0
			removeBtn.Text = "✕"
			removeBtn.Font = Enum.Font.GothamBold
			removeBtn.TextSize = 14
			removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			removeBtn.Parent = queueItem

			local removeBtnCorner = Instance.new("UICorner")
			removeBtnCorner.CornerRadius = UDim.new(0, 8)
			removeBtnCorner.Parent = removeBtn

			removeBtn.MouseButton1Click:Connect(function()
				table.remove(queue, i)
				updateQueueDisplay()
				updateQueuePanel()
			end)
		end
	end

	queueScroll.CanvasSize = UDim2.new(0, 0, 0, queueLayout.AbsoluteContentSize.Y)
	
	-- Apply TextScaled to dynamically created elements
	applyTextScalingToFrame(queueScroll, 14)
end

local function isFavorite(sound)
	for _, fav in ipairs(favorites) do
		if fav == sound then
			return true
		end
	end
	return false
end

local function toggleFavorite(sound)
	local playlistName = "Unknown"

	-- Find which playlist this song belongs to
	for pName, songs in pairs(playlists) do
		if table.find(songs, sound) then
			playlistName = pName
			break
		end
	end

	local songId = playlistName.."/"..sound.Name

	-- Toggle locally
	if isFavorite(sound) then
		for i, fav in ipairs(favorites) do
			if fav == sound then
				table.remove(favorites, i)
				break
			end
		end

		-- Remove from favoritesData
		for i, id in ipairs(favoritesData) do
			if id == songId then
				table.remove(favoritesData, i)
				break
			end
		end
	else
		table.insert(favorites, sound)
		table.insert(favoritesData, songId)
	end

	-- Save to server
	toggleFavoriteMusicEvent:FireServer(songId)

	updateFavoriteButton()

	-- ✅ Refresh UI if on favorites tab
	if currentTab == "favorites" and libraryFrame.Visible then
		updateLibraryContent()
	end
end



updateFavoriteButton = function()
	if currentSound and isFavorite(currentSound) then
		favoriteBtn.Text = "♥"
		favoriteBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		favoriteBtn.Text = "♡"
		favoriteBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

local function playSong(sound, fromQueue)
	if currentSound then
		currentSound:Stop()
	end

	currentSound = sound
	currentSound.Volume = volumeSlider.Size.X.Scale
	currentSound:Play()
	isPlaying = true
	playPauseBtn.Text = "⏸"
	songTitleLabel.Text = sound.Name

	-- Update playlist label
	if currentPlaylist then
		playlistLabel.Text = "Playlist: "..currentPlaylist
	else
		playlistLabel.Text = "Playlist: All Songs"
	end

	updateFavoriteButton()
	updateQueueDisplay()

	-- Update library display to show currently playing
	if libraryFrame.Visible then
		updateLibraryContent()
	end

	if fromQueue then
		table.remove(queue, 1)
		updateQueueDisplay()
		updateQueuePanel()
	end
end

updateLibraryContent = function()
	for _, child in ipairs(contentScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if currentTab == "all" then
		-- Show all songs
		for _, song in ipairs(allSongs) do
			local isCurrentlyPlaying = (currentSound == song)

			local songItem = Instance.new("Frame")
			songItem.Size = UDim2.new(1, -10, 0, 60)  -- Fixed pixel height to prevent scaling issues
			songItem.BackgroundColor3 = isCurrentlyPlaying and Color3.fromRGB(50, 80, 150) or Color3.fromRGB(30, 30, 33)
			songItem.BorderSizePixel = 0
			songItem.Parent = contentScroll

			local songItemCorner = Instance.new("UICorner")
			songItemCorner.CornerRadius = UDim.new(0, 10)
			songItemCorner.Parent = songItem

			-- Playing indicator
			if isCurrentlyPlaying then
				local playingIndicator = Instance.new("Frame")
				playingIndicator.Size = UDim2.new(0.009, 0, 0.667, 0)  -- Dari (0, 4, 0, 40)
				playingIndicator.Position = UDim2.new(0.011, 0, 0.167, 0)
				playingIndicator.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
				playingIndicator.BorderSizePixel = 0
				playingIndicator.Parent = songItem

				local playingIndicatorCorner = Instance.new("UICorner")
				playingIndicatorCorner.CornerRadius = UDim.new(1, 0)
				playingIndicatorCorner.Parent = playingIndicator
			end

			local songNameLabel = Instance.new("TextLabel")
			songNameLabel.Size = UDim2.new(0.533, 0, 0.417, 0)  -- Dari (1, -210, 0, 25)
			songNameLabel.Position = UDim2.new(isCurrentlyPlaying and 0.044 or 0.033, 0, 0.167, 0)  -- Dari (0, ..., 0, 10)
			songNameLabel.TextSize = 13
			songNameLabel.BackgroundTransparency = 1
			songNameLabel.Text = song.Name..(isCurrentlyPlaying and " ♫" or "")
			songNameLabel.Font = isCurrentlyPlaying and Enum.Font.GothamBold or Enum.Font.GothamBold
			songNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			songNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			songNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			songNameLabel.Parent = songItem

			local durationLabel = Instance.new("TextLabel")
			durationLabel.Size = UDim2.new(0.533, 0, 0.3, 0)
			durationLabel.Position = UDim2.new(isCurrentlyPlaying and 0.044 or 0.033, 0, 0.583, 0)  -- Dari (0, ..., 0, 35)
			durationLabel.BackgroundTransparency = 1
			durationLabel.Text = formatTime(song.TimeLength)
			durationLabel.Font = Enum.Font.Gotham
			durationLabel.TextSize = 11
			durationLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			durationLabel.TextXAlignment = Enum.TextXAlignment.Left
			durationLabel.Parent = songItem

			-- Add to Queue Button (NEW)
			local addQueueBtn = Instance.new("TextButton")
			addQueueBtn.Size = UDim2.new(0.089, 0, 0.667, 0)  -- Dari (0, 40, 0, 40)
			addQueueBtn.Position = UDim2.new(0.667, 0, 0.167, 0)
			addQueueBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
			addQueueBtn.BorderSizePixel = 0
			addQueueBtn.Text = "+"
			addQueueBtn.Font = Enum.Font.GothamBold
			addQueueBtn.TextSize = 16
			addQueueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			addQueueBtn.Parent = songItem

			local addQueueBtnCorner = Instance.new("UICorner")
			addQueueBtnCorner.CornerRadius = UDim.new(0, 8)
			addQueueBtnCorner.Parent = addQueueBtn

			addQueueBtn.MouseButton1Click:Connect(function()
				table.insert(queue, song)
				updateQueueDisplay()
				updateQueuePanel()
			end)

			local favBtn = Instance.new("TextButton")
			favBtn.Size = UDim2.new(0.089, 0, 0.667, 0)  -- Dari (0, 40, 0, 40)
			favBtn.Position = UDim2.new(0.778, 0, 0.167, 0)
			favBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 43)
			favBtn.BorderSizePixel = 0
			favBtn.Text = isFavorite(song) and "♥" or "♡"
			favBtn.Font = Enum.Font.GothamBold
			favBtn.TextSize = 16
			favBtn.TextColor3 = isFavorite(song) and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 200)
			favBtn.Parent = songItem

			local favBtnCorner = Instance.new("UICorner")
			favBtnCorner.CornerRadius = UDim.new(0, 8)
			favBtnCorner.Parent = favBtn

			favBtn.MouseButton1Click:Connect(function()
				toggleFavorite(song)
				favBtn.Text = isFavorite(song) and "♥" or "♡"
				favBtn.TextColor3 = isFavorite(song) and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 200)
			end)

			local playBtn = Instance.new("TextButton")
			playBtn.Size = UDim2.new(0.111, 0, 0.667, 0)  -- Dari (0, 50, 0, 40)
			playBtn.Position = UDim2.new(0.884, 0, 0.167, 0)
			playBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
			playBtn.BorderSizePixel = 0
			playBtn.Text = "▶"
			playBtn.Font = Enum.Font.GothamBold
			playBtn.TextSize = 14
			playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			playBtn.Parent = songItem

			local playBtnCorner = Instance.new("UICorner")
			playBtnCorner.CornerRadius = UDim.new(0, 8)
			playBtnCorner.Parent = playBtn

			playBtn.MouseButton1Click:Connect(function()
				currentPlaylist = nil
				currentIndex = 1

				-- Find current song index in allSongs
				for i, s in ipairs(allSongs) do
					if s == song then
						currentIndex = i
						break
					end
				end

				playSong(song, false)

				-- Build queue from remaining songs (if queue is empty)
				if #queue == 0 then
					for i = currentIndex + 1, #allSongs do
						table.insert(queue, allSongs[i])
					end
				end
				updateQueueDisplay()
				updateQueuePanel()
			end)
		end

	elseif currentTab == "playlists" then
		-- Show playlists
		for playlistName, songs in pairs(playlists) do
			local playlistItem = Instance.new("Frame")
			playlistItem.Size = UDim2.new(1, -10, 0, 70)  -- Fixed pixel height
			playlistItem.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
			playlistItem.BorderSizePixel = 0
			playlistItem.Parent = contentScroll

			local playlistItemCorner = Instance.new("UICorner")
			playlistItemCorner.CornerRadius = UDim.new(0, 10)
			playlistItemCorner.Parent = playlistItem

			local playlistNameLabel = Instance.new("TextLabel")
			playlistNameLabel.Size = UDim2.new(0.733, 0, 0.417, 0)
			playlistNameLabel.Position = UDim2.new(0.033, 0, 0.167, 0)
			playlistNameLabel.BackgroundTransparency = 1
			playlistNameLabel.Text = playlistName
			playlistNameLabel.Font = Enum.Font.GothamBold
			playlistNameLabel.TextSize = 13
			playlistNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			playlistNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			playlistNameLabel.Parent = playlistItem

			local songCountLabel = Instance.new("TextLabel")
			songCountLabel.Size = UDim2.new(0.733, 0, 0.3, 0)
			songCountLabel.Position = UDim2.new(0.033, 0, 0.583, 0)
			songCountLabel.BackgroundTransparency = 1
			songCountLabel.Text = #songs.." songs"
			songCountLabel.Font = Enum.Font.Gotham
			songCountLabel.TextSize = 11
			songCountLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			songCountLabel.TextXAlignment = Enum.TextXAlignment.Left
			songCountLabel.Parent = playlistItem

			local viewBtn = Instance.new("TextButton")
			viewBtn.Size = UDim2.new(0.111, 0, 0.667, 0)
			viewBtn.Position = UDim2.new(0.862, 0, 0.167, 0)
			viewBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
			viewBtn.BorderSizePixel = 0
			viewBtn.Text = "📋"
			viewBtn.Font = Enum.Font.GothamBold
			viewBtn.TextSize = 16
			viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			viewBtn.Parent = playlistItem

			local viewBtnCorner = Instance.new("UICorner")
			viewBtnCorner.CornerRadius = UDim.new(0, 8)
			viewBtnCorner.Parent = viewBtn

			viewBtn.MouseButton1Click:Connect(function()
				currentPlaylistSongs = songs
				songDetailsTitle.Text = playlistName

				-- Clear song list
				for _, child in ipairs(songListScroll:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end

				-- Populate song list
				for i, song in ipairs(songs) do
					local songListItem = Instance.new("Frame")
					songListItem.Size = UDim2.new(1, -10, 0, 45)  -- Fixed pixel height
					songListItem.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
					songListItem.BorderSizePixel = 0
					songListItem.LayoutOrder = i
					songListItem.Parent = songListScroll

					local songListItemCorner = Instance.new("UICorner")
					songListItemCorner.CornerRadius = UDim.new(0, 8)
					songListItemCorner.Parent = songListItem

					local songNumLabel = Instance.new("TextLabel")
					songNumLabel.Size = UDim2.new(0.065, 0, 1, 0)
					songNumLabel.Position = UDim2.new(0.02, 0, 0, 0)
					songNumLabel.TextSize = 13
					songNumLabel.BackgroundTransparency = 1
					songNumLabel.Text = i
					songNumLabel.Font = Enum.Font.GothamBold
					songNumLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					songNumLabel.Parent = songListItem

					local songListNameLabel = Instance.new("TextLabel")
					songListNameLabel.Size = UDim2.new(0.512, 0, 1, 0)
					songListNameLabel.Position = UDim2.new(0.1, 0, 0, 0)
					songListNameLabel.BackgroundTransparency = 1
					songListNameLabel.Text = song.Name
					songListNameLabel.Font = Enum.Font.Gotham
					songListNameLabel.TextSize = 12
					songListNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					songListNameLabel.TextXAlignment = Enum.TextXAlignment.Left
					songListNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
					songListNameLabel.Parent = songListItem

					local songDurLabel = Instance.new("TextLabel")
					songDurLabel.Size = UDim2.new(0.11, 0, 1, 0)
					songDurLabel.Position = UDim2.new(0.63, 0, 0, 0)
					songDurLabel.BackgroundTransparency = 1
					songDurLabel.Text = formatTime(song.TimeLength)
					songDurLabel.Font = Enum.Font.Gotham
					songDurLabel.TextSize = 11
					songDurLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					songDurLabel.TextXAlignment = Enum.TextXAlignment.Right
					songDurLabel.Parent = songListItem

					-- Add to Queue Button in song details (NEW)
					local addQueueBtnDetails = Instance.new("TextButton")
					addQueueBtnDetails.Size = UDim2.new(0.087, 0, 0.75, 0)
					addQueueBtnDetails.Position = UDim2.new(0.765, 0, 0.125, 0)
					addQueueBtnDetails.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
					addQueueBtnDetails.BorderSizePixel = 0
					addQueueBtnDetails.Text = "+"
					addQueueBtnDetails.Font = Enum.Font.GothamBold
					addQueueBtnDetails.TextSize = 14
					addQueueBtnDetails.TextColor3 = Color3.fromRGB(255, 255, 255)
					addQueueBtnDetails.Parent = songListItem

					local addQueueBtnDetailsCorner = Instance.new("UICorner")
					addQueueBtnDetailsCorner.CornerRadius = UDim.new(0, 6)
					addQueueBtnDetailsCorner.Parent = addQueueBtnDetails

					addQueueBtnDetails.MouseButton1Click:Connect(function()
						table.insert(queue, song)
						updateQueueDisplay()
						updateQueuePanel()
					end)

					local songPlayBtn = Instance.new("TextButton")
					songPlayBtn.Size = UDim2.new(0.1, 0, 0.75, 0)
					songPlayBtn.Position = UDim2.new(0.88, 0, 0.125, 0)
					songPlayBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
					songPlayBtn.BorderSizePixel = 0
					songPlayBtn.Text = "▶"
					songPlayBtn.Font = Enum.Font.GothamBold
					songPlayBtn.TextSize = 12
					songPlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					songPlayBtn.Parent = songListItem

					local songPlayBtnCorner = Instance.new("UICorner")
					songPlayBtnCorner.CornerRadius = UDim.new(0, 6)
					songPlayBtnCorner.Parent = songPlayBtn

					songPlayBtn.MouseButton1Click:Connect(function()
						currentPlaylist = playlistName
						currentIndex = i
						playSong(song, false)
						if #queue == 0 then
							for j = i + 1, #songs do
								table.insert(queue, songs[j])
							end
						end
						updateQueueDisplay()
						updateQueuePanel()
					end)
				end

				songListScroll.CanvasSize = UDim2.new(0, 0, 0, songListLayout.AbsoluteContentSize.Y)

				-- Animate song details frame
				songDetailsFrame.Visible = true
				local openTween = TweenService:Create(songDetailsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5, 0, 0.5, 0)
				})
				openTween:Play()
			end)
		end

	elseif currentTab == "favorites" then
		-- Show favorites
		if #favorites == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, -10, 0, 100)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "No favorite songs yet\nTap ♡ to add favorites"
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.TextSize = 14
			emptyLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			emptyLabel.Parent = contentScroll
		else
			for _, song in ipairs(favorites) do
				local isCurrentlyPlaying = (currentSound == song)

				local songItem = Instance.new("Frame")
				songItem.Size = UDim2.new(1, -10, 0, 60)  -- Fixed pixel height to prevent scaling issues
				songItem.BackgroundColor3 = isCurrentlyPlaying and Color3.fromRGB(50, 80, 150) or Color3.fromRGB(30, 30, 33)
				songItem.BorderSizePixel = 0
				songItem.Parent = contentScroll

				local songItemCorner = Instance.new("UICorner")
				songItemCorner.CornerRadius = UDim.new(0, 10)
				songItemCorner.Parent = songItem

				-- Playing indicator
				if isCurrentlyPlaying then
					local playingIndicator = Instance.new("Frame")
					playingIndicator.Size = UDim2.new(0.009, 0, 0.667, 0)  -- 4/450, 40/60
					playingIndicator.Position = UDim2.new(0.011, 0, 0.167, 0)
					playingIndicator.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
					playingIndicator.BorderSizePixel = 0
					playingIndicator.Parent = songItem

					local playingIndicatorCorner = Instance.new("UICorner")
					playingIndicatorCorner.CornerRadius = UDim.new(1, 0)
					playingIndicatorCorner.Parent = playingIndicator
				end

				local songNameLabel = Instance.new("TextLabel")
				songNameLabel.Size = UDim2.new(0.533, 0, 0.417, 0)
				songNameLabel.Position = UDim2.new(isCurrentlyPlaying and 0.044 or 0.033, 0, 0.167, 0)
				songNameLabel.BackgroundTransparency = 1
				songNameLabel.Text = song.Name..(isCurrentlyPlaying and " ♫" or "")
				songNameLabel.Font = Enum.Font.GothamBold
				songNameLabel.TextSize = 13
				songNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				songNameLabel.TextXAlignment = Enum.TextXAlignment.Left
				songNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				songNameLabel.Parent = songItem

				local durationLabel = Instance.new("TextLabel")
				durationLabel.Size = UDim2.new(0.533, 0, 0.3, 0)
				durationLabel.Position = UDim2.new(isCurrentlyPlaying and 0.044 or 0.033, 0, 0.583, 0)
				durationLabel.BackgroundTransparency = 1
				durationLabel.Text = formatTime(song.TimeLength)
				durationLabel.Font = Enum.Font.Gotham
				durationLabel.TextSize = 11
				durationLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				durationLabel.TextXAlignment = Enum.TextXAlignment.Left
				durationLabel.Parent = songItem

				-- Add to Queue Button (NEW)
				local addQueueBtn = Instance.new("TextButton")
				addQueueBtn.Size = UDim2.new(0.089, 0, 0.667, 0)
				addQueueBtn.Position = UDim2.new(0.667, 0, 0.167, 0)
				addQueueBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
				addQueueBtn.BorderSizePixel = 0
				addQueueBtn.Text = "+"
				addQueueBtn.Font = Enum.Font.GothamBold
				addQueueBtn.TextSize = 16
				addQueueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				addQueueBtn.Parent = songItem

				local addQueueBtnCorner = Instance.new("UICorner")
				addQueueBtnCorner.CornerRadius = UDim.new(0, 8)
				addQueueBtnCorner.Parent = addQueueBtn

				addQueueBtn.MouseButton1Click:Connect(function()
					table.insert(queue, song)
					updateQueueDisplay()
					updateQueuePanel()
				end)

				local favBtn = Instance.new("TextButton")
				favBtn.Size = UDim2.new(0.089, 0, 0.667, 0)
				favBtn.Position = UDim2.new(0.778, 0, 0.167, 0)
				favBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 43)
				favBtn.BorderSizePixel = 0
				favBtn.Text = "♥"
				favBtn.Font = Enum.Font.GothamBold
				favBtn.TextSize = 16
				favBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
				favBtn.Parent = songItem

				local favBtnCorner = Instance.new("UICorner")
				favBtnCorner.CornerRadius = UDim.new(0, 8)
				favBtnCorner.Parent = favBtn

				favBtn.MouseButton1Click:Connect(function()
					toggleFavorite(song)
					updateLibraryContent()
				end)

				local playBtn = Instance.new("TextButton")
				playBtn.Size = UDim2.new(0.111, 0, 0.667, 0)
				playBtn.Position = UDim2.new(0.884, 0, 0.167, 0)
				playBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
				playBtn.BorderSizePixel = 0
				playBtn.Text = "▶"
				playBtn.Font = Enum.Font.GothamBold
				playBtn.TextSize = 14
				playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				playBtn.Parent = songItem

				local playBtnCorner = Instance.new("UICorner")
				playBtnCorner.CornerRadius = UDim.new(0, 8)
				playBtnCorner.Parent = playBtn

				playBtn.MouseButton1Click:Connect(function()
					currentPlaylist = nil
					currentIndex = 1

					-- Find current song index in favorites
					for i, s in ipairs(favorites) do
						if s == song then
							currentIndex = i
							break
						end
					end

					playSong(song, false)

					-- Build queue from remaining favorites (if queue is empty)
					if #queue == 0 then
						for i = currentIndex + 1, #favorites do
							table.insert(queue, favorites[i])
						end
					end
					updateQueueDisplay()
					updateQueuePanel()
				end)
			end
		end
	end

	task.wait()
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
	
	-- Apply TextScaled to dynamically created elements
	applyTextScalingToFrame(contentScroll, 16)
end

local function setActiveTab(tab)
	-- Reset all tabs
	allTab.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
	allTab.TextColor3 = Color3.fromRGB(150, 150, 150)
	playlistsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
	playlistsTab.TextColor3 = Color3.fromRGB(150, 150, 150)
	favoritesTab.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
	favoritesTab.TextColor3 = Color3.fromRGB(150, 150, 150)

	-- Set active tab
	if tab == "all" then
		allTab.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
		allTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif tab == "playlists" then
		playlistsTab.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
		playlistsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif tab == "favorites" then
		favoritesTab.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
		favoritesTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	currentTab = tab
	updateLibraryContent()
end

-- ==================== BUTTON EVENTS ====================

-- Favorite Button
favoriteBtn.MouseButton1Click:Connect(function()
	if currentSound then
		toggleFavorite(currentSound)
	end
end)

-- Play/Pause
playPauseBtn.MouseButton1Click:Connect(function()
	if currentSound then
		if isPlaying then
			currentSound:Pause()
			playPauseBtn.Text = "▶"
			isPlaying = false
		else
			currentSound:Resume()
			playPauseBtn.Text = "⏸"
			isPlaying = true
		end
	end
end)

-- Next Song
nextBtn.MouseButton1Click:Connect(function()
	if #queue > 0 then
		playSong(queue[1], true)
	elseif currentPlaylist and playlists[currentPlaylist] then
		local songs = playlists[currentPlaylist]
		currentIndex = currentIndex + 1
		if currentIndex > #songs then
			currentIndex = 1
		end
		playSong(songs[currentIndex], false)
	elseif not currentPlaylist and #allSongs > 0 then
		-- Play from all songs in order
		currentIndex = currentIndex + 1
		if currentIndex > #allSongs then
			currentIndex = 1
		end
		playSong(allSongs[currentIndex], false)
	end
end)

-- Previous Song
prevBtn.MouseButton1Click:Connect(function()
	if currentPlaylist and playlists[currentPlaylist] then
		local songs = playlists[currentPlaylist]
		currentIndex = currentIndex - 1
		if currentIndex < 1 then
			currentIndex = #songs
		end
		playSong(songs[currentIndex], false)
	elseif not currentPlaylist and #allSongs > 0 then
		-- Navigate in all songs
		currentIndex = currentIndex - 1
		if currentIndex < 1 then
			currentIndex = #allSongs
		end
		playSong(allSongs[currentIndex], false)
	end
end)

-- Volume Decrease Button
volumeDecBtn.MouseButton1Click:Connect(function()
	local newVolume = math.max(0, volumeSlider.Size.X.Scale - 0.1)
	volumeSlider.Size = UDim2.new(newVolume, 0, 1, 0)
	volumeLabel.Text = "Volume: "..math.floor(newVolume * 100).."%"
	if currentSound then
		currentSound.Volume = newVolume
	end
end)

-- Volume Increase Button
volumeIncBtn.MouseButton1Click:Connect(function()
	local newVolume = math.min(1, volumeSlider.Size.X.Scale + 0.1)
	volumeSlider.Size = UDim2.new(newVolume, 0, 1, 0)
	volumeLabel.Text = "Volume: "..math.floor(newVolume * 100).."%"
	if currentSound then
		currentSound.Volume = newVolume
	end
end)

-- Volume Slider
volumeSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingVolume = true
		local mousePos = UserInputService:GetMouseLocation().X
		local sliderPos = volumeSliderBg.AbsolutePosition.X
		local sliderSize = volumeSliderBg.AbsoluteSize.X
		local relative = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
		volumeSlider.Size = UDim2.new(relative, 0, 1, 0)
		volumeLabel.Text = "Volume: "..math.floor(relative * 100).."%"
		if currentSound then
			currentSound.Volume = relative
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingVolume = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDraggingVolume and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = UserInputService:GetMouseLocation().X
		local sliderPos = volumeSliderBg.AbsolutePosition.X
		local sliderSize = volumeSliderBg.AbsoluteSize.X
		local relative = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
		volumeSlider.Size = UDim2.new(relative, 0, 1, 0)
		volumeLabel.Text = "Volume: "..math.floor(relative * 100).."%"
		if currentSound then
			currentSound.Volume = relative
		end
	end
end)

-- Progress Bar
progressBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingProgress = true
		local mousePos = UserInputService:GetMouseLocation().X
		local sliderPos = progressBg.AbsolutePosition.X
		local sliderSize = progressBg.AbsoluteSize.X
		local relative = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
		if currentSound then
			currentSound.TimePosition = relative * currentSound.TimeLength
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isDraggingProgress and currentSound then
			local mousePos = UserInputService:GetMouseLocation().X
			local sliderPos = progressBg.AbsolutePosition.X
			local sliderSize = progressBg.AbsoluteSize.X
			local relative = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
			currentSound.TimePosition = relative * currentSound.TimeLength
		end
		isDraggingProgress = false
	end
end)

-- Queue Button
queueBtn.MouseButton1Click:Connect(function()
	queuePanel.Visible = true
	updateQueuePanel()
	local openTween = TweenService:Create(queuePanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.622, 0, 0.5, 0)
	})
	openTween:Play()
end)

-- Queue Close Button
queueCloseBtn.MouseButton1Click:Connect(function()
	local closeTween = TweenService:Create(queuePanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.622, 0, -0.5, 0)
	})
	closeTween:Play()
	closeTween.Completed:Wait()
	queuePanel.Visible = false
end)

-- Library Button
libraryBtn.MouseButton1Click:Connect(function()
	libraryFrame.Visible = true
	setActiveTab("all")

	-- ✅ Force refresh layout after opening
	task.wait(0.1)
	updateLibraryContent()

	local openTween = TweenService:Create(libraryFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	openTween:Play()
end)


-- Library Close Button
libraryCloseBtn.MouseButton1Click:Connect(function()
	local closeTween = TweenService:Create(libraryFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, -0.5, 0)
	})
	closeTween:Play()
	closeTween.Completed:Wait()
	libraryFrame.Visible = false
end)

-- Tab Buttons
allTab.MouseButton1Click:Connect(function()
	setActiveTab("all")
end)

playlistsTab.MouseButton1Click:Connect(function()
	setActiveTab("playlists")
end)

favoritesTab.MouseButton1Click:Connect(function()
	setActiveTab("favorites")
end)

-- Song Details Close Button
songDetailsCloseBtn.MouseButton1Click:Connect(function()
	local closeTween = TweenService:Create(songDetailsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, -0.5, 0)
	})
	closeTween:Play()
	closeTween.Completed:Wait()
	songDetailsFrame.Visible = false
end)

-- Play All Button
playAllBtn.MouseButton1Click:Connect(function()
	if #currentPlaylistSongs > 0 then
		currentPlaylist = songDetailsTitle.Text
		currentIndex = 1
		playSong(currentPlaylistSongs[1], false)
		queue = {}
		for i = 2, #currentPlaylistSongs do
			table.insert(queue, currentPlaylistSongs[i])
		end
		updateQueueDisplay()
		updateQueuePanel()

		-- Close song details
		local closeTween = TweenService:Create(songDetailsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, -0.5, 0)
		})
		closeTween:Play()
		closeTween.Completed:Wait()
		songDetailsFrame.Visible = false
	end
end)

-- Update Progress Bar
RunService.Heartbeat:Connect(function()
	if currentSound and currentSound.IsPlaying then
		local progress = currentSound.TimePosition / currentSound.TimeLength
		if not isDraggingProgress then
			progressBar.Size = UDim2.new(progress, 0, 1, 0)
		end
		currentTimeLabel.Text = formatTime(currentSound.TimePosition)
		totalTimeLabel.Text = formatTime(currentSound.TimeLength)

		-- Auto next when song ends
		if currentSound.TimePosition >= currentSound.TimeLength - 0.1 then
			if #queue > 0 then
				playSong(queue[1], true)
			elseif currentPlaylist and playlists[currentPlaylist] then
				local songs = playlists[currentPlaylist]
				currentIndex = currentIndex + 1
				if currentIndex > #songs then
					currentIndex = 1
				end
				playSong(songs[currentIndex], false)
			else
				isPlaying = false
				playPauseBtn.Text = "▶"
			end
		end
	end
end)

-- Make frames draggable (IMPROVED - only drag on header)
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

	-- GANTI DENGAN:
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			local viewport = workspace.CurrentCamera.ViewportSize

			local deltaScaleX = delta.X / viewport.X
			local deltaScaleY = delta.Y / viewport.Y

			frame.Position = UDim2.new(
				framePos.X.Scale + deltaScaleX,
				0,  -- ✅ Offset = 0
				framePos.Y.Scale + deltaScaleY,
				0   -- ✅ Offset = 0
			)
		end
	end)
end

-- Apply draggable only to headers
makeDraggable(musicFrame, musicHeader)
makeDraggable(libraryFrame, libraryHeader)
makeDraggable(songDetailsFrame, songDetailsHeader)
makeDraggable(queuePanel, queueHeader)

-- Initialize
loadPlaylists()
task.wait(0.5)  -- Give extra time for sounds to fully load
loadFavorites()
updateQueueDisplay()

-- AUTO-PLAY FIRST SONG ON START
task.wait(2) -- Wait for everything to load
if #allSongs > 0 and not autoPlayStarted then
	autoPlayStarted = true
	currentIndex = 1
	playSong(allSongs[1], false)
	-- Build queue with remaining songs
	for i = 2, #allSongs do
		table.insert(queue, allSongs[i])
	end
	updateQueueDisplay()
	updateQueuePanel()
end

-- ==================== TOPBAR ICON (CREATE LAST) ====================
local musicIcon = Icon.new()
	:setImage("rbxassetid://99799967722215")
	:setLabel("Music")
	:bindEvent("selected", function()
		screenGui.Enabled = true
		musicFrame.Visible = true
		musicFrame.Position = UDim2.new(0.5, 0, 0.5, 0)  -- ✅ Centered
		musicFrame.Size = UDim2.new(0, 0, 0, 0)  -- ✅ Start small
		
		-- ✅ Use tweenSize for smooth animation
		tweenSize(musicFrame, UDim2.new(0.7, 0, 0.8, 0), 0.3)
	end)
	:bindEvent("deselected", function()
		-- ✅ Use tweenSize for smooth animation
		tweenSize(musicFrame, UDim2.new(0, 0, 0, 0), 0.2, function()
			musicFrame.Visible = false
			screenGui.Enabled = false
			musicFrame.Size = UDim2.new(0.7, 0, 0.8, 0)  -- ✅ Reset size
		end)
	end)

-- Music Close Button (needs musicIcon defined first)
musicCloseBtn.MouseButton1Click:Connect(function()
	musicIcon:deselect()
end)