local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local HUDButton = require(script.Parent:WaitForChild("HUDButtonHelper"))
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

local screenGui = playerGui:WaitForChild("Dance")

local mainPanel = screenGui:WaitForChild("MainPanel")

local header = mainPanel:WaitForChild("Header")

local headerTitle = header:WaitForChild("HeaderTitle")

local closeBtn = header:WaitForChild("CloseButton")

local tabFrame = mainPanel:WaitForChild("Category")

local allTab = tabFrame:WaitForChild("AllButton")

local favTab = tabFrame:WaitForChild("FavoritesButton")
local danceTab = tabFrame:WaitForChild("DanceButton")
local poseTab = tabFrame:WaitForChild("PoseButton")

local scrollFrame = mainPanel:WaitForChild("ScrollPanel")

local animSlot = scrollFrame:WaitForChild("DanceCard")
animSlot.Parent = playerGui

local emptyLabel = scrollFrame:WaitForChild("EmptyCard")

local speedFrame = mainPanel:WaitForChild("SpeedPanel")

local speedLabel = speedFrame:WaitForChild("TextLabel")

local speedSliderBg = speedFrame:WaitForChild("Slider")

local speedSlider = speedSliderBg:WaitForChild("FillBar")

local speedHandle = speedSliderBg:WaitForChild("FillCircle")

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

Players.PlayerRemoving:Connect(function(targetPlayer)
	if Tracks[targetPlayer] then
		Tracks[targetPlayer]:Stop()
		Tracks[targetPlayer] = nil
	end
	Animators[targetPlayer] = nil
	AnimationDatas[targetPlayer] = nil
end)

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

	local frame = animSlot:Clone()

	frame.Parent = scrollFrame

	local favoritedColor = Color3.fromHex("#fd0a73")
	local nonFavoritedColor = Color3.fromHex("#8badab")

	frame:WaitForChild("UIStroke").Transparency = isPlaying and 0 or 1

	local titleLabel = frame:WaitForChild("DanceInfo"):WaitForChild("DanceTitle")

	titleLabel.Text = animData.Title

	local favBtn = frame:WaitForChild("FavoriteButton")

	local favIcon = favBtn:WaitForChild("ImageLabel")
	favIcon.ImageColor3 = isFavorite(animData.Title) and favoritedColor or nonFavoritedColor

	favBtn.MouseButton1Click:Connect(function()
		toggleFavorite(animData.Title)
		updateAnimList()
	end)

	frame.MouseButton1Click:Connect(function()
		if isPlaying then
			stopAnimation()
		else
			playAnimation(animData)
		end
		updateAnimList()
	end)
end

local currentTab = "All"
function updateAnimList()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		local destroyed = false
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local animsToShow = {}

	if currentTab == "All" then
		animsToShow = DanceConfig.Animations
	elseif currentTab == "Dance" then
		for _, anim in ipairs(DanceConfig.Animations) do
			if anim.Category == "Dance" then
				table.insert(animsToShow, anim)
			end
		end
	elseif currentTab == "Pose" then
		for _, anim in ipairs(DanceConfig.Animations) do
			if anim.Category == "Pose" then
				table.insert(animsToShow, anim)
			end
		end
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

	else
		emptyLabel.Visible = false
		for _, anim in ipairs(animsToShow) do
			createAnimItem(anim)
		end
	end
end

local function makeDraggable(frame, handle)
	local dragging = false
	local dragInput, mousePos, framePos

	handle.InputBegan:Connect(function(input)
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

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			local viewport = workspace.CurrentCamera.ViewportSize
			frame.Position = UDim2.new(
				framePos.X.Scale + (delta.X / viewport.X),
				0,
				framePos.Y.Scale + (delta.Y / viewport.Y),
				0
			)
		end
	end)
end

makeDraggable(mainPanel, header)

allTab.MouseButton1Click:Connect(function()

	favTab:FindFirstChild("UIStroke").Transparency = 1
	danceTab:FindFirstChild("UIStroke").Transparency = 1
	poseTab:FindFirstChild("UIStroke").Transparency = 1
	allTab:FindFirstChild("UIStroke").Transparency = 0
	currentTab = "All"
	updateAnimList()
end)

favTab.MouseButton1Click:Connect(function()
	favTab:FindFirstChild("UIStroke").Transparency = 0
	danceTab:FindFirstChild("UIStroke").Transparency = 1
	poseTab:FindFirstChild("UIStroke").Transparency = 1
	allTab:FindFirstChild("UIStroke").Transparency = 1
	currentTab = "Favorite"
	updateAnimList()
end)
danceTab.MouseButton1Click:Connect(function()
	favTab:FindFirstChild("UIStroke").Transparency = 1
	danceTab:FindFirstChild("UIStroke").Transparency = 0
	poseTab:FindFirstChild("UIStroke").Transparency = 1
	allTab:FindFirstChild("UIStroke").Transparency = 1
	currentTab = "Dance"
	updateAnimList()
end)
poseTab.MouseButton1Click:Connect(function()
	favTab:FindFirstChild("UIStroke").Transparency = 1
	danceTab:FindFirstChild("UIStroke").Transparency = 1
	poseTab:FindFirstChild("UIStroke").Transparency = 0
	allTab:FindFirstChild("UIStroke").Transparency = 1
	currentTab = "Pose"
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
	if draggingSpeed and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mouseX = UserInputService:GetMouseLocation().X
		local posX = speedSliderBg.AbsolutePosition.X
		local sizeX = speedSliderBg.AbsoluteSize.X
		local rel = math.clamp((mouseX - posX) / sizeX, 0, 1)

		speedSlider.Size = UDim2.new(rel, 0, 1, 0)
		speedHandle.Position = UDim2.new(rel, -6, 0.5, -6)

		animationSpeed = 0.1 + (rel * 3.9)
	end
end)

local isPanelOpen = false

local function openDancePanel()
	if isPanelOpen then return end
	isPanelOpen = true
	screenGui.Enabled = true
	mainPanel.Visible = true

	task.spawn(function()
		task.wait(2)
		local success, loaded = pcall(function()
			return getFavoritesFunc:InvokeServer()
		end)

		if success and loaded then
			favorites = loaded
			if mainPanel.Visible then
				updateAnimList()
			end
		else
			warn("⚠️ [DANCE CLIENT] Failed to load favorites")
		end
	end)

	updateAnimList()
end

local function closeDancePanel()
	if not isPanelOpen then return end
	isPanelOpen = false
	screenGui.Enabled = false
	mainPanel.Visible = false
end

local danceButton = HUDButton.Create({
	Side = "Left",
	Icon = "rbxassetid://128874172331140",
	Text = "Dance",
	Name = "DanceButton",
	OnClick = function()
		if isPanelOpen then
			closeDancePanel()
		else
			openDancePanel()
		end
	end
})

closeBtn.MouseButton1Click:Connect(function()
	closeDancePanel()
end)
