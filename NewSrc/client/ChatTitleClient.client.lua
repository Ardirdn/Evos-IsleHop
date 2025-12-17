local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local titleRemotes = ReplicatedStorage:WaitForChild("TitleRemotes", 30)
if not titleRemotes then
	warn("[CHAT TITLE CLIENT] TitleRemotes not found!")
	return
end

local getTitleFunc = titleRemotes:WaitForChild("GetTitle", 10)

local playerTitles = {}
local playerTitleFetching = {}

local function ensureTitle(userId)

	if playerTitles[userId] then
		return playerTitles[userId]
	end

	if playerTitleFetching[userId] then
		return nil
	end

	local targetPlayer = Players:GetPlayerByUserId(userId)
	if not targetPlayer then return nil end

	playerTitleFetching[userId] = true
	task.spawn(function()
		local success, title = pcall(function()
			return getTitleFunc:InvokeServer(targetPlayer)
		end)

		if success and title then
			playerTitles[userId] = title
		end
		playerTitleFetching[userId] = nil
	end)

	return nil
end

local function GradientText(text, colors)
	local result = ""
	local length = #text

	if length == 0 then return "" end

	if #colors < 2 then
		local color = colors[1] or Color3.fromRGB(255, 255, 255)
		return string.format("<font color='rgb(%d,%d,%d)'>%s</font>",
			math.floor(color.R * 255),
			math.floor(color.G * 255),
			math.floor(color.B * 255),
			text)
	end

	for i = 1, length do
		local ratio = (i - 1) / math.max(length - 1, 1)
		local colorIndex = math.floor(ratio * (#colors - 1)) + 1
		local nextIndex = math.min(colorIndex + 1, #colors)
		local c1, c2 = colors[colorIndex], colors[nextIndex]
		local t = (ratio * (#colors - 1)) % 1

		local r = math.floor(c1.R * 255 * (1 - t) + c2.R * 255 * t)
		local g = math.floor(c1.G * 255 * (1 - t) + c2.G * 255 * t)
		local b = math.floor(c1.B * 255 * (1 - t) + c2.B * 255 * t)

		local char = text:sub(i, i)
		result ..= string.format("<font color='rgb(%d,%d,%d)'>%s</font>", r, g, b, char)
	end

	return result
end

task.wait(2)

local textChannels = TextChatService:WaitForChild("TextChannels", 10)
if not textChannels then
	warn("[CHAT TITLE CLIENT] TextChannels not found")
	return
end

local rbxGeneral = textChannels:WaitForChild("RBXGeneral", 10)
if not rbxGeneral then
	warn("[CHAT TITLE CLIENT] RBXGeneral not found")
	return
end

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")

	if not message.TextSource then
		return properties
	end

	local userId = message.TextSource.UserId

	local titleName = playerTitles[userId]
	if not titleName then
		ensureTitle(userId)
		return properties
	end

	local titleData = nil

	if TitleConfig.SpecialTitles[titleName] then
		titleData = TitleConfig.SpecialTitles[titleName]
	else
		for _, summitTitle in ipairs(TitleConfig.SummitTitles) do
			if summitTitle.Name == titleName then
				titleData = summitTitle
				break
			end
		end
	end

	if titleData then
		local displayName = titleData.DisplayName or titleName
		local icon = titleData.Icon or ""
		local colors = titleData.Colors or {titleData.Color or Color3.fromRGB(255, 255, 255)}
		local primaryColor = colors[1] or Color3.fromRGB(255, 255, 255)

		local tagText = string.format("[%s %s]", icon, displayName)
		local gradientTag = GradientText(tagText, colors)

		local playerName = message.TextSource.Name
		local targetPlayer = Players:GetPlayerByUserId(userId)
		if targetPlayer then
			playerName = targetPlayer.DisplayName
		end

		local r = math.floor(primaryColor.R * 255)
		local g = math.floor(primaryColor.G * 255)
		local b = math.floor(primaryColor.B * 255)
		local coloredPlayerName = string.format("<font color='rgb(%d,%d,%d)'>%s</font>", r, g, b, playerName)

		properties.PrefixText = gradientTag .. " " .. coloredPlayerName .. ":"
	else

		local playerName = message.TextSource.Name
		local targetPlayer = Players:GetPlayerByUserId(userId)
		if targetPlayer then
			playerName = targetPlayer.DisplayName
		end

		properties.PrefixText = string.format("<font color='rgb(255,255,255)'>%s:</font>", playerName)
	end

	return properties
end

Players.PlayerRemoving:Connect(function(leavingPlayer)
	playerTitles[leavingPlayer.UserId] = nil
	playerTitleFetching[leavingPlayer.UserId] = nil
end)
