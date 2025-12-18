local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataHandler = require(script.Parent.DataHandler)
local NotificationService = require(script.Parent.NotificationServer)
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

local TitleServer = {}

local remoteFolder = ReplicatedStorage:FindFirstChild("TitleRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "TitleRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local updateTitleEvent = remoteFolder:FindFirstChild("UpdateTitle")
if not updateTitleEvent then
	updateTitleEvent = Instance.new("RemoteEvent")
	updateTitleEvent.Name = "UpdateTitle"
	updateTitleEvent.Parent = remoteFolder
end

local updateOtherPlayerTitleEvent = remoteFolder:FindFirstChild("UpdateOtherPlayerTitle")
if not updateOtherPlayerTitleEvent then
	updateOtherPlayerTitleEvent = Instance.new("RemoteEvent")
	updateOtherPlayerTitleEvent.Name = "UpdateOtherPlayerTitle"
	updateOtherPlayerTitleEvent.Parent = remoteFolder
end

local getTitleFunc = remoteFolder:FindFirstChild("GetTitle")
if not getTitleFunc then
	getTitleFunc = Instance.new("RemoteFunction")
	getTitleFunc.Name = "GetTitle"
	getTitleFunc.Parent = remoteFolder
end

local equipTitleEvent = remoteFolder:FindFirstChild("EquipTitle")
if not equipTitleEvent then
	equipTitleEvent = Instance.new("RemoteEvent")
	equipTitleEvent.Name = "EquipTitle"
	equipTitleEvent.Parent = remoteFolder
end

local unequipTitleEvent = remoteFolder:FindFirstChild("UnequipTitle")
if not unequipTitleEvent then
	unequipTitleEvent = Instance.new("RemoteEvent")
	unequipTitleEvent.Name = "UnequipTitle"
	unequipTitleEvent.Parent = remoteFolder
end

local getUnlockedTitlesFunc = remoteFolder:FindFirstChild("GetUnlockedTitles")
if not getUnlockedTitlesFunc then
	getUnlockedTitlesFunc = Instance.new("RemoteFunction")
	getUnlockedTitlesFunc.Name = "GetUnlockedTitles"
	getUnlockedTitlesFunc.Parent = remoteFolder
end

local BroadcastTitle = remoteFolder:FindFirstChild("BroadcastTitle")
if not BroadcastTitle then
	BroadcastTitle = Instance.new("RemoteEvent")
	BroadcastTitle.Name = "BroadcastTitle"
	BroadcastTitle.Parent = remoteFolder
end

local collidersFolder = nil
local accessControlReady = false

local zoneTouchedCooldown = {}
local playerAccessCache = {}
local broadcastDebounce = {}
local TOUCH_COOLDOWN = 0.5
local ACCESS_CACHE_DURATION = 2
local BROADCAST_DEBOUNCE = 2

local DEBUG_MODE = false

local function debugLog(...)
	if DEBUG_MODE then
	end
end

local function hasAccess(player, zoneFolderName, forceRefresh)
	local cacheKey = player.UserId .. "_" .. zoneFolderName
	local now = tick()

	if not forceRefresh then
		local cached = playerAccessCache[cacheKey]
		if cached and (now - cached.timestamp) < ACCESS_CACHE_DURATION then
			return cached.hasAccess
		end
	end

	local data = DataHandler:GetData(player)
	if not data then
		playerAccessCache[cacheKey] = {hasAccess = false, timestamp = now}
		return false
	end

	local playerTitle = data.EquippedTitle or data.Title or "Pengunjung"

	local allowedTitles = TitleConfig.AccessRules[zoneFolderName]
	if not allowedTitles then
		playerAccessCache[cacheKey] = {hasAccess = false, timestamp = now}
		return false
	end

	for _, allowedTitle in ipairs(allowedTitles) do
		if playerTitle == allowedTitle then
			playerAccessCache[cacheKey] = {hasAccess = true, timestamp = now}
			return true
		end
	end

	playerAccessCache[cacheKey] = {hasAccess = false, timestamp = now}
	return false
end

local function invalidateAccessCache(player)
	local userId = player.UserId
	for key in pairs(playerAccessCache) do
		if string.sub(key, 1, #tostring(userId)) == tostring(userId) then
			playerAccessCache[key] = nil
		end
	end
end

local function getZoneDisplayName(zoneFolderName)
	local displayNames = {
		["AdminZones"] = "Admin",
		["VVIPZones"] = "VVIP",
		["VIPZones"] = "VIP",
		["EVOSZones"] = "EVOS",
		["AkamsiZones"] = "Akamsi",
		["BoatAccess"] = "Boat",
	}
	return displayNames[zoneFolderName] or zoneFolderName
end

local function updateCanCollideForPlayer(player, part, zoneFolderName, suppressNotification)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local access = hasAccess(player, zoneFolderName)

	local function findConstraintForPart(playerPart, zonePart)
		for _, child in ipairs(playerPart:GetChildren()) do
			if child:IsA("NoCollisionConstraint") then
				if child.Part1 == zonePart then
					return child
				end
			end
		end
		return nil
	end

	if access then

		local constraintsAdded = 0
		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then

				local existingConstraint = findConstraintForPart(playerPart, part)
				if not existingConstraint then
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = playerPart
					constraint.Part1 = part
					constraint.Name = "ZonePass_" .. zoneFolderName
					constraint.Parent = playerPart
					constraintsAdded = constraintsAdded + 1
				end
			end
		end

		if constraintsAdded > 0 then
			debugLog(player.Name, "ZONE:", zoneFolderName, "PART:", part.Name, "| Added", constraintsAdded, "constraints")
		end
	else

		local constraintsRemoved = 0
		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then

				local existingConstraint = findConstraintForPart(playerPart, part)
				if existingConstraint then
					existingConstraint:Destroy()
					constraintsRemoved = constraintsRemoved + 1
				end
			end
		end

		if constraintsRemoved > 0 then
			debugLog(player.Name, "ZONE:", zoneFolderName, "PART:", part.Name, "| Removed", constraintsRemoved, "constraints")
		end

		if not suppressNotification then
			if not player:GetAttribute("ZoneWarning_" .. zoneFolderName) then
				player:SetAttribute("ZoneWarning_" .. zoneFolderName, true)

				local zoneDisplayName = getZoneDisplayName(zoneFolderName)

				pcall(function()
					NotificationService:Send(player, {
						Message = string.format("Kamu Tidak Bisa Masuk Ke Area \"%s\"", zoneDisplayName),
						Type = "error",
						Duration = 3,
						Icon = "🔒"
					})
				end)

				task.delay(3, function()
					player:SetAttribute("ZoneWarning_" .. zoneFolderName, nil)
				end)
			end
		end
	end
end

local function updateCanCollideForPlayerOptimized(player, part, zoneFolderName, suppressNotification, preCalculatedAccess)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local access = preCalculatedAccess

	local function findConstraintForPart(playerPart, zonePart)
		for _, child in ipairs(playerPart:GetChildren()) do
			if child:IsA("NoCollisionConstraint") then
				if child.Part1 == zonePart then
					return child
				end
			end
		end
		return nil
	end

	if access then

		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then
				local existingConstraint = findConstraintForPart(playerPart, part)
				if not existingConstraint then
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = playerPart
					constraint.Part1 = part
					constraint.Name = "ZonePass_" .. zoneFolderName
					constraint.Parent = playerPart
				end
			end
		end
	else

		for _, playerPart in ipairs(character:GetDescendants()) do
			if playerPart:IsA("BasePart") then
				local existingConstraint = findConstraintForPart(playerPart, part)
				if existingConstraint then
					existingConstraint:Destroy()
				end
			end
		end
	end

end

function TitleServer.RefreshZoneAccess(player)
	if not collidersFolder then
		collidersFolder = workspace:FindFirstChild("Colliders")
		if not collidersFolder then
			warn("[ACCESS CONTROL] Colliders folder not found!")
			return
		end
	end

	local character = player.Character
	if not character then return end

	invalidateAccessCache(player)

	local userId = player.UserId
	for key in pairs(zoneTouchedCooldown) do
		if string.sub(key, 1, #tostring(userId)) == tostring(userId) then
			zoneTouchedCooldown[key] = nil
		end
	end

	local data = DataHandler:GetData(player)
	local currentTitle = data and (data.EquippedTitle or data.Title) or "none"

	debugLog(player.Name, "RefreshZoneAccess started (Title:", currentTitle, ")")

	local BATCH_SIZE = 25
	local partsProcessed = 0
	local totalParts = 0

	task.spawn(function()

		local zoneAccessMap = {}
		for _, zoneFolder in ipairs(collidersFolder:GetChildren()) do
			if zoneFolder:IsA("Folder") then
				zoneAccessMap[zoneFolder.Name] = hasAccess(player, zoneFolder.Name, true)
			end
		end

		for _, zoneFolder in ipairs(collidersFolder:GetChildren()) do
			if zoneFolder:IsA("Folder") then
				local zoneFolderName = zoneFolder.Name
				local playerHasAccess = zoneAccessMap[zoneFolderName]

				for _, part in ipairs(zoneFolder:GetChildren()) do
					if part:IsA("BasePart") then
						totalParts = totalParts + 1
						partsProcessed = partsProcessed + 1

						updateCanCollideForPlayerOptimized(player, part, zoneFolderName, true, playerHasAccess)

						if partsProcessed >= BATCH_SIZE then
							partsProcessed = 0
							task.wait()

							if not player.Parent or not player.Character then
								debugLog(player.Name, "RefreshZoneAccess aborted - player left")
								return
							end
						end
					end
				end
			end
		end

		debugLog(player.Name, "RefreshZoneAccess complete. Processed", totalParts, "zone parts")
	end)
end

local function hasGamepass(userId, gamepassId)
	if not gamepassId or gamepassId == 0 then
		return false
	end

	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)

	return success and hasPass
end

local function getSummitTitle(totalSummits)
	local highestTitle = TitleConfig.SummitTitles[1]

	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if totalSummits >= titleData.MinSummits then
			highestTitle = titleData
		else
			break
		end
	end

	return highestTitle.Name
end

function TitleServer:GetTitleData(titleName)

	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if titleData.Name == titleName then
			return titleData
		end
	end

	if TitleConfig.SpecialTitles[titleName] then
		local data = TitleConfig.SpecialTitles[titleName]
		return {
			Name = titleName,
			DisplayName = data.DisplayName,
			Color = data.Color,
			Icon = data.Icon,
			Privileges = data.Privileges
		}
	end

	return nil
end

function TitleServer:UnlockTitle(player, titleName)
	local data = DataHandler:GetData(player)
	if not data then return false end

	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end

	if table.find(data.UnlockedTitles, titleName) then
		return false
	end

	local titleData = self:GetTitleData(titleName)
	if not titleData then
		warn(string.format("[TITLE] Invalid title: %s", titleName))
		return false
	end

	DataHandler:AddToArray(player, "UnlockedTitles", titleName)
	DataHandler:SavePlayer(player)

	NotificationService:Send(player, {
		Message = string.format("New Title Unlocked: %s %s", titleData.Icon, titleData.DisplayName),
		Type = "success",
		Duration = 5,
		Icon = titleData.Icon
	})

	return true
end

function TitleServer:UnlockSummitTitles(player, totalSummits)
	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if totalSummits >= titleData.MinSummits then
			self:UnlockTitle(player, titleData.Name)
		end
	end
end

function TitleServer:SyncSummitTitles(player, totalSummits)
	local data = DataHandler:GetData(player)
	if not data then return end

	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end

	local titlesToRemove = {}
	local titlesToAdd = {}

	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		local hasTitle = table.find(data.UnlockedTitles, titleData.Name)
		local qualifies = totalSummits >= titleData.MinSummits

		if qualifies and not hasTitle then

			table.insert(titlesToAdd, titleData.Name)
		elseif not qualifies and hasTitle then

			table.insert(titlesToRemove, titleData.Name)
		end
	end

	for _, titleName in ipairs(titlesToRemove) do
		local idx = table.find(data.UnlockedTitles, titleName)
		if idx then
			table.remove(data.UnlockedTitles, idx)
		end
	end

	for _, titleName in ipairs(titlesToAdd) do
		table.insert(data.UnlockedTitles, titleName)
		local titleData = self:GetTitleData(titleName)
		if titleData then
			NotificationService:Send(player, {
				Message = string.format("New Title Unlocked: %s %s", titleData.Icon, titleData.DisplayName),
				Type = "success",
				Duration = 5,
				Icon = titleData.Icon
			})
		end
	end

	if #titlesToRemove > 0 or #titlesToAdd > 0 then
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
		DataHandler:SavePlayer(player)

		if data.EquippedTitle and table.find(titlesToRemove, data.EquippedTitle) then
			self:UnequipTitle(player)
			NotificationService:Send(player, {
				Message = "Your equipped title was removed due to summit change!",
				Type = "warning",
				Duration = 5
			})
		end
	end

end

function TitleServer:EquipTitle(player, titleName)
	local data = DataHandler:GetData(player)
	if not data then return false end

	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
	end

	if not table.find(data.UnlockedTitles, titleName) then
		NotificationService:Send(player, {
			Message = "You don't have this title!",
			Type = "error",
			Duration = 3
		})
		return false
	end

	local oldTitle = data.EquippedTitle
	if oldTitle then
		self:RemovePrivileges(player, oldTitle)
	end

	DataHandler:Set(player, "EquippedTitle", titleName)
	DataHandler:SavePlayer(player)

	self:ApplyPrivileges(player, titleName)

	self:BroadcastTitle(player, titleName)

	BroadcastTitle:FireAllClients(player.UserId, titleName)

	self:UpdatePlayerTeam(player, titleName)

	if self.RefreshZoneAccess then
		self.RefreshZoneAccess(player)
	end

	local titleData = self:GetTitleData(titleName)
	NotificationService:Send(player, {
		Message = string.format("Equipped: %s %s", titleData.Icon, titleData.DisplayName),
		Type = "success",
		Duration = 3
	})

	return true
end

function TitleServer:UnequipTitle(player)
	local data = DataHandler:GetData(player)
	if not data then return false end

	local previousTitle = data.EquippedTitle
	if not previousTitle then
		NotificationService:Send(player, {
			Message = "No title equipped!",
			Type = "error",
			Duration = 3
		})
		return false
	end

	self:RemovePrivileges(player, previousTitle)

	DataHandler:Set(player, "EquippedTitle", nil)
	DataHandler:SavePlayer(player)

	self:BroadcastTitle(player, nil)

	BroadcastTitle:FireAllClients(player.UserId, nil)

	self:UpdatePlayerTeam(player, nil)

	if self.RefreshZoneAccess then
		self.RefreshZoneAccess(player)
	end

	NotificationService:Send(player, {
		Message = "Title unequipped. Access removed.",
		Type = "info",
		Duration = 3
	})

	return true
end

function TitleServer:ApplyPrivileges(player, titleName)
	local titleData = self:GetTitleData(titleName)
	if not titleData or not titleData.Privileges then return end

	local privileges = titleData.Privileges

	if privileges.Tools and #privileges.Tools > 0 then
		for _, toolName in ipairs(privileges.Tools) do
			self:GiveTool(player, toolName)
		end
	end

end

function TitleServer:RemovePrivileges(player, titleName)
	local titleData = self:GetTitleData(titleName)
	if not titleData or not titleData.Privileges then return end

	local privileges = titleData.Privileges

	if privileges.Tools and #privileges.Tools > 0 then
		for _, toolName in ipairs(privileges.Tools) do
			self:RemoveTool(player, toolName)
		end
	end

end

function TitleServer:GiveTool(player, toolName)
	if not player.Character then return end

	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then
		warn("[PRIVILEGES] Tools folder not found in ReplicatedStorage")
		return
	end

	local toolTemplate = toolsFolder:FindFirstChild(toolName)
	if not toolTemplate then
		warn(string.format("[PRIVILEGES] Tool not found: %s", toolName))
		return
	end

	local backpack = player:FindFirstChild("Backpack")

	if backpack and backpack:FindFirstChild(toolName) then
		return
	end

	if player.Character:FindFirstChild(toolName) then
		return
	end

	local toolClone = toolTemplate:Clone()
	toolClone.Parent = backpack or player.Character

end

function TitleServer:RemoveTool(player, toolName)

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local tool = backpack:FindFirstChild(toolName)
		if tool then
			tool:Destroy()
		end
	end

	if player.Character then
		local tool = player.Character:FindFirstChild(toolName)
		if tool then
			tool:Destroy()
		end
	end

end

local TEAM_CONFIG = {
	{Name = "Owner", Titles = {"Owner"}, Priority = 101},
	{Name = "Admin", Titles = {"Admin"}, Priority = 100},
	{Name = "SahabatAdmin", Titles = {"SahabatAdmin"}, Priority = 92},
	{Name = "EVOS", Titles = {"EVOS TEAM"}, Priority = 90},
	{Name = "Akamsi", Titles = {"Akamsi"}, Priority = 89},
	{Name = "VVIP", Titles = {"VVIP"}, Priority = 80},
	{Name = "VIP", Titles = {"VIP"}, Priority = 70},
	{Name = "Donatur", Titles = {"Donatur"}, Priority = 60},
	{Name = "Online", Titles = {"Pendaki", "Pendaki Fomo", "Pendaki Amatir", "Pendaki Pemula", "Pendaki Tektok", "Pendaki Handal", "Pendaki Berpengalaman", "Pendaki Muka Lama", "Pendaki Professional", "Penunggu Gunung", "Penjaga Gunung", "Dewa Gunung", "Raja Gunung", "Legenda Gunung", "Immortal"}, Priority = 0},
}

local NEUTRAL_COLOR = BrickColor.new("Really black")
local teamInstances = {}

local function getTeamForTitle(titleName)
	if not titleName or titleName == "" then
		return "Online", 0
	end

	for _, teamConfig in ipairs(TEAM_CONFIG) do
		for _, title in ipairs(teamConfig.Titles) do
			if title == titleName then
				return teamConfig.Name, teamConfig.Priority
			end
		end
	end

	return "Online", 0
end

local function getOrCreateTeam(teamName, priority)
	local Teams = game:GetService("Teams")

	if teamInstances[teamName] then
		return teamInstances[teamName]
	end

	local existingTeam = Teams:FindFirstChild(teamName)
	if existingTeam then
		teamInstances[teamName] = existingTeam
		return existingTeam
	end

	local team = Instance.new("Team")
	team.Name = teamName
	team.TeamColor = NEUTRAL_COLOR
	team.AutoAssignable = false
	team.Parent = Teams
	team:SetAttribute("Priority", priority)

	teamInstances[teamName] = team
	return team
end

local function cleanupEmptyTeams()
	for teamName, team in pairs(teamInstances) do
		if team and team.Parent then
			local players = team:GetPlayers()
			if #players == 0 then
				team:Destroy()
				teamInstances[teamName] = nil
			end
		end
	end
end

function TitleServer:UpdatePlayerTeam(player, titleName)
	local teamName, priority = getTeamForTitle(titleName)
	local team = getOrCreateTeam(teamName, priority)

	player.Team = team
	player.Neutral = false

	task.delay(0.5, cleanupEmptyTeams)
end

Players.PlayerRemoving:Connect(function(player)
	task.delay(0.1, cleanupEmptyTeams)

	local userId = player.UserId
	local userIdStr = tostring(userId)

	for key in pairs(zoneTouchedCooldown) do
		if string.sub(key, 1, #userIdStr) == userIdStr then
			zoneTouchedCooldown[key] = nil
		end
	end

	for key in pairs(playerAccessCache) do
		if string.sub(key, 1, #userIdStr) == userIdStr then
			playerAccessCache[key] = nil
		end
	end

	if broadcastDebounce then
		broadcastDebounce[userId] = nil
	end
end)

function TitleServer:DetermineTitle(player)
	local userId = player.UserId
	local data = DataHandler:GetData(player)

	if not data then
		warn(string.format("⚠️ [TITLE SERVER] No data for %s", player.Name))
		return "Pendaki"
	end

	if data.EquippedTitle then
		return data.EquippedTitle
	end

	if TitleConfig.AdminIds and table.find(TitleConfig.AdminIds, userId) then
		return "Admin"
	end

	if data.SpecialTitle and TitleConfig.SpecialTitles[data.SpecialTitle] then
		return data.SpecialTitle
	end

	if TitleConfig.SpecialTitles.VVIP and TitleConfig.SpecialTitles.VVIP.GamepassId ~= 0 then
		if hasGamepass(userId, TitleConfig.SpecialTitles.VVIP.GamepassId) then
			DataHandler:Set(player, "SpecialTitle", "VVIP")
			DataHandler:Set(player, "TitleSource", "special")
			return "VVIP"
		end
	end

	if TitleConfig.SpecialTitles.VIP and TitleConfig.SpecialTitles.VIP.GamepassId ~= 0 then
		if hasGamepass(userId, TitleConfig.SpecialTitles.VIP.GamepassId) then
			DataHandler:Set(player, "SpecialTitle", "VIP")
			DataHandler:Set(player, "TitleSource", "special")
			return "VIP"
		end
	end

	if data.TotalDonations >= TitleConfig.DonationThreshold then
		DataHandler:Set(player, "SpecialTitle", "Donatur")
		DataHandler:Set(player, "TitleSource", "special")
		return "Donatur"
	end

	local summitTitle = getSummitTitle(data.TotalSummits or 0)
	return summitTitle
end

function TitleServer:UpdateSummitTitle(player)
	local data = DataHandler:GetData(player)
	if not data then return end

	if data.EquippedTitle then

		self:UnlockSummitTitles(player, data.TotalSummits or 0)
		return
	end

	if data.SpecialTitle and data.SpecialTitle ~= "" then
		return
	end

	if data.TitleSource and data.TitleSource ~= "summit" then
		return
	end

	local newTitle = getSummitTitle(data.TotalSummits or 0)
	local currentTitle = data.Title

	self:UnlockSummitTitles(player, data.TotalSummits or 0)

	if newTitle ~= currentTitle then
		DataHandler:Set(player, "Title", newTitle)
		DataHandler:Set(player, "TitleSource", "summit")
		DataHandler:SavePlayer(player)

		self:BroadcastTitle(player, newTitle)
	else
	end
end

function TitleServer:GrantSpecialTitle(player, specialTitleName)
	if not TitleConfig.SpecialTitles[specialTitleName] then
		warn(string.format("⚠️ [TITLE] Invalid special title: %s", specialTitleName))
		return false
	end

	DataHandler:Set(player, "SpecialTitle", specialTitleName)
	DataHandler:Set(player, "Title", specialTitleName)
	DataHandler:Set(player, "TitleSource", "special")
	DataHandler:SavePlayer(player)

	self:BroadcastTitle(player, specialTitleName)
	return true
end

function TitleServer:RemoveSpecialTitle(player)
	DataHandler:Set(player, "SpecialTitle", nil)

	local newTitle = self:DetermineTitle(player)
	DataHandler:Set(player, "Title", newTitle)
	DataHandler:Set(player, "TitleSource", "summit")
	DataHandler:SavePlayer(player)

	self:BroadcastTitle(player, newTitle)
	return true
end

function TitleServer:SetTitle(player, titleName, source, isSpecial)

	local data = DataHandler:GetData(player)

	local isSummitTitle = false
	for _, titleData in ipairs(TitleConfig.SummitTitles) do
		if titleData.Name == titleName then
			isSummitTitle = true
			break
		end
	end

	if isSummitTitle then
		isSpecial = false
	end

	if isSpecial then
		if not TitleConfig.SpecialTitles[titleName] and titleName ~= "Admin" then
			warn(string.format("⚠️ [TITLE] Invalid special title: %s", titleName))
			return false
		end

		DataHandler:Set(player, "SpecialTitle", titleName)
		DataHandler:Set(player, "Title", titleName)
		DataHandler:Set(player, "TitleSource", source or "admin")
		DataHandler:SavePlayer(player)

		self:BroadcastTitle(player, titleName)
		return true
	else
		DataHandler:Set(player, "SpecialTitle", "")
		DataHandler:Set(player, "TitleSource", "summit")

		local correctSummitTitle = getSummitTitle(data.TotalSummits or 0)
		DataHandler:Set(player, "Title", correctSummitTitle)
		DataHandler:SavePlayer(player)

		self:BroadcastTitle(player, correctSummitTitle)
		return true
	end
end

function TitleServer:GetTitle(player)
	if not player or not player.Parent then
		return "Pendaki"
	end

	return self:DetermineTitle(player)
end

function TitleServer:GetPlayerTitle(player)
	return self:GetTitle(player)
end

function TitleServer:BroadcastTitle(player, titleName)
	if not player or not player.Parent then
		return
	end

	pcall(function()
		updateTitleEvent:FireClient(player, titleName)
	end)

	local userId = player.UserId
	local now = tick()
	local lastBroadcast = broadcastDebounce[userId]

	if not lastBroadcast or (now - lastBroadcast) >= BROADCAST_DEBOUNCE then
		broadcastDebounce[userId] = now
		pcall(function()
			updateOtherPlayerTitleEvent:FireAllClients(player, titleName)
		end)
	end
end

function TitleServer:InitializePlayer(player)
	task.wait(1)

	local data = DataHandler:GetData(player)
	if not data then return end

	if not data.UnlockedTitles then
		data.UnlockedTitles = {"Pendaki"}
		DataHandler:Set(player, "UnlockedTitles", data.UnlockedTitles)
	end

	self:UnlockSummitTitles(player, data.TotalSummits or 0)

	if table.find(TitleConfig.AdminIds, player.UserId) then
		self:UnlockTitle(player, "Admin")

		if data.EquippedTitle ~= "Admin" then
			DataHandler:Set(player, "EquippedTitle", "Admin")
		end

		self:GiveAdminWing(player)
	end

	for titleName, titleData in pairs(TitleConfig.SpecialTitles) do
		if titleData.GamepassId and titleData.GamepassId ~= 0 then
			if hasGamepass(player.UserId, titleData.GamepassId) then
				self:UnlockTitle(player, titleName)
			end
		end
	end

	local title = self:DetermineTitle(player)
	local currentTitle = DataHandler:Get(player, "Title")
	if currentTitle ~= title then
		DataHandler:Set(player, "Title", title)
		DataHandler:SavePlayer(player)
	end

	if data.EquippedTitle then
		task.wait(1)
		self:ApplyPrivileges(player, data.EquippedTitle)
	end

	self:UpdatePlayerTeam(player, data.EquippedTitle or title)

	task.wait(2)
	self:BroadcastTitle(player, data.EquippedTitle or title)
end

function TitleServer:InitializePlayerPostMigration(player)
	if not player or not player.Parent then return end

	local data = DataHandler:GetData(player)
	if not data then return end

	if data.TotalSummits and data.TotalSummits > 0 then
		self:UnlockSummitTitles(player, data.TotalSummits)
	end

	if table.find(TitleConfig.AdminIds, player.UserId) then

		if not table.find(data.UnlockedTitles or {}, "Admin") then
			self:UnlockTitle(player, "Admin")
		end

		if data.EquippedTitle ~= "Admin" then
			DataHandler:Set(player, "EquippedTitle", "Admin")
			DataHandler:SavePlayer(player)
			self:UpdatePlayerTeam(player, "Admin")
		end

		self:GiveAdminWing(player)
	end

	local title = self:DetermineTitle(player)

	local currentStoredTitle = data.Title
	if currentStoredTitle ~= title then
		DataHandler:Set(player, "Title", title)
		DataHandler:SavePlayer(player)
	end

	self:BroadcastTitle(player, data.EquippedTitle or title)

	self:UpdatePlayerTeam(player, data.EquippedTitle or title)

end

function TitleServer:GiveAdminWing(player)
	if not player or not player.Parent then return end
	if not table.find(TitleConfig.AdminIds, player.UserId) then return end

	if not DataHandler:ArrayContains(player, "OwnedTools", "AdminWing") then
		DataHandler:AddToArray(player, "OwnedTools", "AdminWing")
	end

	local equippedTool = DataHandler:Get(player, "EquippedTool")
	if not equippedTool then
		DataHandler:Set(player, "EquippedTool", "AdminWing")
	end

	DataHandler:SavePlayer(player)
end

function TitleServer:AdminSetSummits(player, newSummitCount)
	if newSummitCount < 0 then newSummitCount = 0 end

	DataHandler:Set(player, "TotalSummits", newSummitCount)

	if player:FindFirstChild("PlayerStats") then
		local summitValue = player.PlayerStats:FindFirstChild("Summit")
		if summitValue then
			summitValue.Value = newSummitCount
		end
	end

	self:UpdateSummitTitle(player)

	DataHandler:SavePlayer(player)
end

equipTitleEvent.OnServerEvent:Connect(function(player, titleName)
	TitleServer:EquipTitle(player, titleName)
end)

unequipTitleEvent.OnServerEvent:Connect(function(player)
	TitleServer:UnequipTitle(player)
end)

getUnlockedTitlesFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)
	if not data then
		return {
			UnlockedTitles = {"Pendaki"},
			EquippedTitle = nil
		}
	end

	return {
		UnlockedTitles = data.UnlockedTitles or {"Pendaki"},
		EquippedTitle = data.EquippedTitle
	}
end

getTitleFunc.OnServerInvoke = function(caller, targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then
		return "Pendaki"
	end

	return TitleServer:GetTitle(targetPlayer)
end

Players.PlayerAdded:Connect(function(player)
	TitleServer:InitializePlayer(player)

	player.CharacterAdded:Connect(function(character)
		task.wait(1)

		local data = DataHandler:GetData(player)
		if data and data.EquippedTitle then
			TitleServer:ApplyPrivileges(player, data.EquippedTitle)
		end

		TitleServer.RefreshZoneAccess(player)

		local title = TitleServer:GetTitle(player)
		TitleServer:BroadcastTitle(player, title)
	end)
end)

collidersFolder = workspace:WaitForChild("Colliders", 10)

if not collidersFolder then
	warn("⚠️ [ACCESS CONTROL] Colliders folder not found in Workspace!")
else
	accessControlReady = true

	local totalParts = 0

	local function setupZonePart(part, zoneFolderName)
		if not part:IsA("BasePart") then return end

		part.Transparency = 1
		part.CanCollide = true
		part.Anchored = true

		totalParts = totalParts + 1

		part.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if not player then return end

			local cooldownKey = player.UserId .. "_" .. zoneFolderName .. "_" .. part.Name
			local now = tick()
			local lastTouch = zoneTouchedCooldown[cooldownKey]

			if lastTouch and (now - lastTouch) < TOUCH_COOLDOWN then
				return
			end

			zoneTouchedCooldown[cooldownKey] = now

			updateCanCollideForPlayer(player, part, zoneFolderName)
		end)
	end

	local function setupZoneFolder(zoneFolder)
		if not zoneFolder:IsA("Folder") then return end

		local zoneFolderName = zoneFolder.Name
		debugLog("Setting up zone folder:", zoneFolderName)

		for _, part in ipairs(zoneFolder:GetChildren()) do
			setupZonePart(part, zoneFolderName)
		end

		zoneFolder.ChildAdded:Connect(function(part)
			task.wait(0.1)
			setupZonePart(part, zoneFolderName)
		end)
	end

	for _, zoneFolder in ipairs(collidersFolder:GetChildren()) do
		setupZoneFolder(zoneFolder)
	end

	collidersFolder.ChildAdded:Connect(function(zoneFolder)
		task.wait(0.1)
		setupZoneFolder(zoneFolder)
	end)

end

return TitleServer
