local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, child in ipairs(playerGui:GetChildren()) do

	if child:IsA("ScreenGui") then
		for _, subChild in ipairs(child:GetChildren()) do
		end
	end
end

for _, child in ipairs(StarterGui:GetChildren()) do
end

local notificationGui = playerGui:FindFirstChild("Notification")
	or playerGui:FindFirstChild("NotificationGui")
	or playerGui:FindFirstChild("Notifications")
	or playerGui:FindFirstChild("NotificationGUI")

if not notificationGui then
	notificationGui = playerGui:WaitForChild("Notification", 15)
end

if notificationGui then
	local childCount = 0
	for _, child in ipairs(notificationGui:GetChildren()) do
		childCount = childCount + 1
	end

	local templateNames = {"MiddleNotiificationTextOnly", "SideNotiificationTextOnly", "MidleNotiificationWithSender", "SideNotiificationWithSender"}
	for _, name in ipairs(templateNames) do
		local found = notificationGui:FindFirstChild(name)
	end
end

if not notificationGui then

	local templateNames = {"MiddleNotificationTextOnly", "SideNotificationTextOnly", "MidleNotificationWithSender", "SideNotificationWithSender"}

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			for _, templateName in ipairs(templateNames) do
				local found = gui:FindFirstChild(templateName)
				if found then
					notificationGui = gui
				end
			end
			if notificationGui then
				break
			end
		end
	end
end

local useFallbackContainer = false

if not notificationGui then
	warn("⚠️ [NOTIFICATION CLIENT] Notification ScreenGui not found! Creating fallback system...")

	notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "NotificationFallback"
	notificationGui.ResetOnSpawn = false
	notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notificationGui.DisplayOrder = 100
	notificationGui.Parent = playerGui
	useFallbackContainer = true

else

	if notificationGui.DisplayOrder < 90 then
		notificationGui.DisplayOrder = 100
	end

	if not notificationGui.Enabled then
		notificationGui.Enabled = true
	end
end

local notificationContainer = notificationGui:FindFirstChild("NotificationContainer")
if not notificationContainer then

	notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0, 350, 1, -20)
	notificationContainer.Position = UDim2.new(1, -360, 0, 10)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.Parent = notificationGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = notificationContainer

end

local function waitForTemplate(name, timeout)
	local template = notificationGui:FindFirstChild(name)
	if template then return template end

	template = notificationGui:WaitForChild(name, timeout or 3)
	return template
end

local templates = {
	MiddleTextOnly = waitForTemplate("MiddleNotiificationTextOnly", 2),
	MiddleWithSender = waitForTemplate("MidleNotiificationWithSender", 2),
	SideTextOnly = waitForTemplate("SideNotiificationTextOnly", 2),
	SideWithSender = waitForTemplate("SideNotiificationWithSender", 2)
}

for name, template in pairs(templates) do
	if template then
		template.Visible = false
	else
	end
end

local hasAnyTemplate = false
for _, template in pairs(templates) do
	if template then
		hasAnyTemplate = true
		break
	end
end

local notificationComm = ReplicatedStorage:WaitForChild("NotificationComm")
local showNotificationEvent = notificationComm:WaitForChild("ShowNotification")

local notificationQueue = {}
local activeNotification = nil

local function playSound(soundId)
	if not soundId then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

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

local function showFallbackNotification(data)

	local container = notificationContainer

	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.new(0, 340, 0, 70)
	notif.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	notif.BorderSizePixel = 0
	notif.BackgroundTransparency = 0.1
	notif.ClipsDescendants = true
	notif.Parent = container

	createCorner(10).Parent = notif
	createStroke(Color3.fromRGB(88, 101, 242), 2).Parent = notif

	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -20, 1, -15)
	message.Position = UDim2.new(0, 10, 0, 5)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.GothamBold
	message.Text = data.Message or "Notification"
	message.TextColor3 = Color3.fromRGB(255, 255, 255)
	message.TextSize = 14
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Center
	message.Parent = notif

	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -10, 0, 3)
	progressBg.Position = UDim2.new(0, 5, 1, -8)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = notif

	createCorner(2).Parent = progressBg

	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(1, 0, 1, 0)
	progress.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	progress.BorderSizePixel = 0
	progress.Parent = progressBg

	createCorner(2).Parent = progress

	notif.Position = UDim2.new(1, 50, 0, 0)
	local targetPos = UDim2.new(0, 0, 0, 0)
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = targetPos
	}):Play()

	local duration = data.Duration or 5
	TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	task.delay(duration, function()
		local slideOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 50, 0, 0)
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			notif:Destroy()
			activeNotification = nil

			if #notificationQueue > 0 then
				local nextData = table.remove(notificationQueue, 1)
				showFallbackNotification(nextData)
			end
		end)
	end)

	activeNotification = notif
	playSound("rbxassetid://6026984224")

end

local function animateTimerSlider(timerSlider, duration, onComplete)
	if not timerSlider then
		task.delay(duration, onComplete)
		return
	end

	local slider = timerSlider:FindFirstChild("Slider")
	local fillBar = slider and slider:FindFirstChild("FillBar")

	if fillBar then

		fillBar.Size = UDim2.new(1, 0, 1, 0)

		local tween = TweenService:Create(fillBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0)
		})
		tween:Play()
		tween.Completed:Connect(onComplete)
	else

		task.delay(duration, onComplete)
	end
end

local function showNotification(data)

	data.Duration = data.Duration or 5
	data.NotificationType = data.NotificationType or "SideTextOnly"

	if not hasAnyTemplate then
		showFallbackNotification(data)
		return
	end

	local templateName = data.NotificationType
	local template = templates[templateName]

	if not template then
		warn(string.format("⚠️ [NOTIFICATION CLIENT] Template not found: %s, using fallback", templateName))
		showFallbackNotification(data)
		return
	end

	local notif = template:Clone()
	notif.Name = "ActiveNotification"
	notif.Parent = notificationGui
	notif.Visible = true

	local mainInfo = notif:FindFirstChild("MainInfo")

	for _, child in ipairs(notif:GetChildren()) do
	end

	if mainInfo then
		local notifInfo = mainInfo:FindFirstChild("NotificationInfo")
		local notifText = notifInfo and notifInfo:FindFirstChild("NotificationText")

		if notifText then
			notifText.Text = data.Message or "Notification"
		else

			notifText = mainInfo:FindFirstChild("NotificationText")
			if notifText then
				notifText.Text = data.Message or "Notification"
			end
		end

		local timerSlider = notifInfo and notifInfo:FindFirstChild("TimerSlider")
		if not timerSlider then
			timerSlider = mainInfo:FindFirstChild("TimerSlider")
		end

		local senderInfo = mainInfo:FindFirstChild("SenderInfo")
		if senderInfo and data.Sender then

			local avatar = senderInfo:FindFirstChild("Avatar")
			if avatar then
				avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. (data.Sender.UserId or player.UserId) .. "&w=150&h=150"
			end

			local namePanel = senderInfo:FindFirstChild("SenderNameUsernamePanel")
			if namePanel then
				local playerName = namePanel:FindFirstChild("PlayerName")
				local username = namePanel:FindFirstChild("Username")

				if playerName then
					playerName.Text = data.Sender.DisplayName or data.Sender.Name or "Admin"
				end
				if username then
					username.Text = "@" .. (data.Sender.Name or "admin")
				end
			end
		elseif senderInfo then

			if data.SenderUserId then
				local avatar = senderInfo:FindFirstChild("Avatar")
				if avatar then
					avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. data.SenderUserId .. "&w=150&h=150"
				end

				local namePanel = senderInfo:FindFirstChild("SenderNameUsernamePanel")
				if namePanel then
					local playerName = namePanel:FindFirstChild("PlayerName")
					local username = namePanel:FindFirstChild("Username")

					if playerName then
						playerName.Text = data.SenderName or "Admin"
					end
					if username then
						username.Text = "@" .. (data.SenderUsername or "admin")
					end
				end
			end
		end

		animateTimerSlider(timerSlider, data.Duration, function()

			local fadeOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			})

			for _, desc in ipairs(notif:GetDescendants()) do
				if desc:IsA("Frame") then
					TweenService:Create(desc, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
				elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
					TweenService:Create(desc, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
				elseif desc:IsA("ImageLabel") then
					TweenService:Create(desc, TweenInfo.new(0.3), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
				end
			end

			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				notif:Destroy()
				activeNotification = nil

				if #notificationQueue > 0 then
					local nextData = table.remove(notificationQueue, 1)
					showNotification(nextData)
				end
			end)
		end)
	else

		notif:Destroy()
		showFallbackNotification(data)
		return
	end

	local closeButton = notif:FindFirstChild("CloseButton")
	if closeButton then
		closeButton.MouseButton1Click:Connect(function()

			local fadeOut = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			})

			for _, desc in ipairs(notif:GetDescendants()) do
				if desc:IsA("Frame") then
					TweenService:Create(desc, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
					TweenService:Create(desc, TweenInfo.new(0.2), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
				elseif desc:IsA("ImageLabel") then
					TweenService:Create(desc, TweenInfo.new(0.2), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
				end
			end

			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				notif:Destroy()
				activeNotification = nil

				if #notificationQueue > 0 then
					local nextData = table.remove(notificationQueue, 1)
					showNotification(nextData)
				end
			end)
		end)
	end

	if templateName:find("Middle") then

		notif.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = template.Size
		}):Play()
	else

		local originalPos = notif.Position
		notif.Position = UDim2.new(originalPos.X.Scale + 0.3, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset)
		TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = originalPos
		}):Play()
	end

	activeNotification = notif

	playSound("rbxassetid://6026984224")
end

showNotificationEvent.OnClientEvent:Connect(function(data)
	if not data or not data.Message then
		warn("⚠️ [NOTIFICATION CLIENT] Invalid notification data")
		return
	end

	if activeNotification then
		table.insert(notificationQueue, data)
	else
		showNotification(data)
	end
end)
