local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules", 10):WaitForChild("TitleConfig", 10))

local remoteFolder = ReplicatedStorage:WaitForChild("TitleRemotes", 10)
if not remoteFolder then
	warn("❌ [TITLE CLIENT] TitleRemotes not found!")
	return
end

local getTitleFunc = remoteFolder:WaitForChild("GetTitle", 5)

local billboardCache = {}
local playerCountries = {}

local hideTitlesEnabled = false

local CONFIG = {
	MAX_DISTANCE = 100,
}

local DESIGN = {
	TextColor = Color3.fromRGB(255, 255, 255),
	TitleColor = Color3.fromRGB(200, 200, 205),
	MoneyColor = Color3.fromRGB(255, 255, 255),
	SummitColor = Color3.fromRGB(255, 255, 255),
	DefaultAccent = Color3.fromRGB(80, 80, 90),
	MainFont = Enum.Font.FredokaOne,
}

local function setHideTitles(value)
	hideTitlesEnabled = value

	for targetPlayer, billboard in pairs(billboardCache) do
		if billboard and billboard.Parent then
			billboard.Enabled = not value
		end
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Character then
			local head = otherPlayer.Character:FindFirstChild("Head")
			if head then
				local billboard = head:FindFirstChild("PlayerInfoBillboard")
				if billboard then
					billboard.Enabled = not value
				end
			end
		end
	end

end

_G.SetHideTitles = setHideTitles

local function createBillboard(character, targetPlayer)
	local head = character:WaitForChild("Head", 5)
	if not head then return nil end

	local existing = head:FindFirstChild("PlayerInfoBillboard")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerInfoBillboard"
	billboard.Size = UDim2.new(6, 0, 3.5, 0)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = CONFIG.MAX_DISTANCE
	billboard.LightInfluence = 0

	if hideTitlesEnabled then
		billboard.Enabled = false
	end

	billboard.Parent = head

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = billboard

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = DESIGN.MainFont
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = DESIGN.TitleColor
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Text = "👤 Visitor"
	titleLabel.Parent = mainFrame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Transparency = 0.3
	titleStroke.Parent = titleLabel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.28, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.22, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = DESIGN.MainFont
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = DESIGN.TextColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Text = targetPlayer.DisplayName
	nameLabel.Parent = mainFrame

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Transparency = 0.2
	nameStroke.Parent = nameLabel

	local summitsLabel = Instance.new("TextLabel")
	summitsLabel.Name = "SummitsLabel"
	summitsLabel.Size = UDim2.new(1, 0, 0.14, 0)
	summitsLabel.Position = UDim2.new(0, 0, 0.55, 0)
	summitsLabel.BackgroundTransparency = 1
	summitsLabel.Font = DESIGN.MainFont
	summitsLabel.TextScaled = true
	summitsLabel.TextColor3 = DESIGN.SummitColor
	summitsLabel.TextXAlignment = Enum.TextXAlignment.Center
	summitsLabel.Text = "⛰️ 0"
	summitsLabel.Parent = mainFrame

	local summitStroke = Instance.new("UIStroke")
	summitStroke.Color = Color3.fromRGB(0, 0, 0)
	summitStroke.Thickness = 1.5
	summitStroke.Transparency = 0.3
	summitStroke.Parent = summitsLabel

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.new(1, 0, 0.14, 0)
	moneyLabel.Position = UDim2.new(0, 0, 0.70, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = DESIGN.MainFont
	moneyLabel.TextScaled = true
	moneyLabel.TextColor3 = DESIGN.MoneyColor
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
	moneyLabel.Text = "💵 $0"
	moneyLabel.Parent = mainFrame

	local moneyStroke = Instance.new("UIStroke")
	moneyStroke.Color = Color3.fromRGB(0, 0, 0)
	moneyStroke.Thickness = 1.5
	moneyStroke.Transparency = 0.3
	moneyStroke.Parent = moneyLabel

	billboardCache[targetPlayer] = billboard
	return billboard
end

local function updateTitle(targetPlayer, titleName)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local titleLabel = mainFrame:FindFirstChild("TitleLabel")
	if not titleLabel then return end

	local titleData = nil
	local titleColor = DESIGN.DefaultAccent

	for _, data in ipairs(TitleConfig.SummitTitles) do
		if data.Name == titleName then
			titleData = data
			break
		end
	end

	if not titleData and TitleConfig.SpecialTitles[titleName] then
		local specialData = TitleConfig.SpecialTitles[titleName]
		titleData = {
			Name = titleName,
			DisplayName = specialData.DisplayName,
			Color = specialData.Color,
			Icon = specialData.Icon
		}
	end

	if titleData then
		titleColor = titleData.Color
		titleLabel.Text = titleData.Icon .. " " .. titleData.DisplayName
		titleLabel.TextColor3 = titleColor
	else
		titleLabel.Text = "👤 Visitor"
		titleLabel.TextColor3 = DESIGN.TitleColor
	end
end

local function updateSummit(targetPlayer, summits)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local summitsLabel = mainFrame and mainFrame:FindFirstChild("SummitsLabel")

	if summitsLabel then
		summitsLabel.Text = "⛰️ " .. tostring(summits)
	end
end

local function updateMoney(targetPlayer, money)
	local billboard = billboardCache[targetPlayer]
	if not billboard then return end

	local mainFrame = billboard:FindFirstChild("MainFrame")
	local moneyLabel = mainFrame and mainFrame:FindFirstChild("MoneyLabel")

	if moneyLabel then
		local formatted = tostring(money)
		if money >= 1000000 then
			formatted = string.format("%.1fM", money / 1000000)
		elseif money >= 1000 then
			formatted = string.format("%.1fK", money / 1000)
		end
		moneyLabel.Text = "💵 $" .. formatted
	end
end

local playerConnections = {}

local function cleanupPlayerConnections(targetPlayer)
	if playerConnections[targetPlayer] then
		for _, conn in ipairs(playerConnections[targetPlayer]) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end
		playerConnections[targetPlayer] = nil
	end
end

local function setupPlayer(targetPlayer)
	local function onCharacterAdded(character)
		cleanupPlayerConnections(targetPlayer)
		playerConnections[targetPlayer] = {}

		local billboard = nil
		local retries = 0

		while not billboard and retries < 5 do
			billboard = createBillboard(character, targetPlayer)
			if not billboard then
				retries = retries + 1
				task.wait(0.5)
			end
		end

		if not billboard then
			warn("[TITLE] Failed to create billboard for", targetPlayer.Name)
			return
		end

		task.spawn(function()
			task.wait(0.5)
			if not targetPlayer or not targetPlayer.Parent then return end
			if not billboardCache[targetPlayer] then return end

			local success, title = nil, nil
			for attempt = 1, 5 do
				success, title = pcall(function()
					return getTitleFunc:InvokeServer(targetPlayer)
				end)

				if success and title then
					break
				end
				task.wait(0.5)
			end

			if success and title then
				updateTitle(targetPlayer, title)
			end
		end)

		local function watchPlayerStats()
			local playerStats = targetPlayer:FindFirstChild("PlayerStats")
			if playerStats then
				local summit = playerStats:FindFirstChild("Summit")
				if summit then
					updateSummit(targetPlayer, summit.Value)
					local conn = summit:GetPropertyChangedSignal("Value"):Connect(function()
						updateSummit(targetPlayer, summit.Value)
					end)
					table.insert(playerConnections[targetPlayer], conn)
				end
			end
		end

		watchPlayerStats()
		task.delay(3, watchPlayerStats)

		local moneyValue = targetPlayer:FindFirstChild("Money")
		if moneyValue then
			updateMoney(targetPlayer, moneyValue.Value)
			local conn = moneyValue:GetPropertyChangedSignal("Value"):Connect(function()
				updateMoney(targetPlayer, moneyValue.Value)
			end)
			table.insert(playerConnections[targetPlayer], conn)
		else
			local conn
			conn = targetPlayer.ChildAdded:Connect(function(child)
				if child.Name == "Money" and child:IsA("IntValue") then
					updateMoney(targetPlayer, child.Value)
					local moneyConn = child:GetPropertyChangedSignal("Value"):Connect(function()
						updateMoney(targetPlayer, child.Value)
					end)
					if playerConnections[targetPlayer] then
						table.insert(playerConnections[targetPlayer], moneyConn)
					end
					conn:Disconnect()
				end
			end)
			table.insert(playerConnections[targetPlayer], conn)
		end
	end

	targetPlayer.CharacterAdded:Connect(onCharacterAdded)
	if targetPlayer.Character then
		onCharacterAdded(targetPlayer.Character)
	end
end

local function onPlayerRemoving(targetPlayer)
	cleanupPlayerConnections(targetPlayer)
	billboardCache[targetPlayer] = nil
	playerCountries[targetPlayer] = nil
end

local updateTitleEvent = remoteFolder:FindFirstChild("UpdateTitle")
if updateTitleEvent then
	updateTitleEvent.OnClientEvent:Connect(function(titleName)
		updateTitle(player, titleName)
	end)
end

local updateOtherEvent = remoteFolder:FindFirstChild("UpdateOtherPlayerTitle")
if updateOtherEvent then
	updateOtherEvent.OnClientEvent:Connect(function(targetPlayer, titleName)
		if not targetPlayer then return end
		
		task.spawn(function()
			for attempt = 1, 10 do
				if billboardCache[targetPlayer] then
					updateTitle(targetPlayer, titleName)
					return
				end
				task.wait(0.3)
			end
		end)
	end)
end

local function hideRobloxDefaultName(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function setupHideDefaultName(targetPlayer)
	if targetPlayer.Character then
		hideRobloxDefaultName(targetPlayer.Character)
	end

	targetPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		hideRobloxDefaultName(character)
	end)
end

for _, targetPlayer in ipairs(Players:GetPlayers()) do
	setupPlayer(targetPlayer)
	setupHideDefaultName(targetPlayer)
end

Players.PlayerAdded:Connect(function(targetPlayer)
	setupPlayer(targetPlayer)
	setupHideDefaultName(targetPlayer)
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)

task.spawn(function()
	while task.wait(30) do
		local players = Players:GetPlayers()
		local count = 0
		for _, targetPlayer in ipairs(players) do
			if targetPlayer ~= player and billboardCache[targetPlayer] then
				count = count + 1
				if count > 10 then break end
				
				task.spawn(function()
					local success, title = pcall(function()
						return getTitleFunc:InvokeServer(targetPlayer)
					end)
					
					if success and title then
						updateTitle(targetPlayer, title)
					end
				end)
				task.wait(0.3)
			end
		end
	end
end)

