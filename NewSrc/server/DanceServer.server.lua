local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local danceComm = ReplicatedStorage:FindFirstChild("DanceComm")
if not danceComm then
	danceComm = Instance.new("Folder")
	danceComm.Name = "DanceComm"
	danceComm.Parent = ReplicatedStorage
end

local StartDance = danceComm:FindFirstChild("StartDance")
if not StartDance then
	StartDance = Instance.new("RemoteEvent")
	StartDance.Name = "StartDance"
	StartDance.Parent = danceComm
end

local StopDance = danceComm:FindFirstChild("StopDance")
if not StopDance then
	StopDance = Instance.new("RemoteEvent")
	StopDance.Name = "StopDance"
	StopDance.Parent = danceComm
end

local SyncDanceEvent = danceComm:FindFirstChild("SyncDance")
if not SyncDanceEvent then
	SyncDanceEvent = Instance.new("RemoteEvent")
	SyncDanceEvent.Name = "SyncDance"
	SyncDanceEvent.Parent = danceComm
end

local UnsyncDanceEvent = danceComm:FindFirstChild("UnsyncDance")
if not UnsyncDanceEvent then
	UnsyncDanceEvent = Instance.new("RemoteEvent")
	UnsyncDanceEvent.Name = "UnsyncDance"
	UnsyncDanceEvent.Parent = danceComm
end

local SetSpeedEvent = danceComm:FindFirstChild("SetSpeed")
if not SetSpeedEvent then
	SetSpeedEvent = Instance.new("RemoteEvent")
	SetSpeedEvent.Name = "SetSpeed"
	SetSpeedEvent.Parent = danceComm
end

local remoteFolder = ReplicatedStorage:FindFirstChild("DanceRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "DanceRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local startCoordinateDanceEvent = remoteFolder:FindFirstChild("StartCoordinateDance")
if not startCoordinateDanceEvent then
	startCoordinateDanceEvent = Instance.new("RemoteEvent")
	startCoordinateDanceEvent.Name = "StartCoordinateDance"
	startCoordinateDanceEvent.Parent = remoteFolder
end

local stopCoordinateDanceEvent = remoteFolder:FindFirstChild("StopCoordinateDance")
if not stopCoordinateDanceEvent then
	stopCoordinateDanceEvent = Instance.new("RemoteEvent")
	stopCoordinateDanceEvent.Name = "StopCoordinateDance"
	stopCoordinateDanceEvent.Parent = remoteFolder
end

local syncDanceEvent = remoteFolder:FindFirstChild("SyncDance")
if not syncDanceEvent then
	syncDanceEvent = Instance.new("RemoteEvent")
	syncDanceEvent.Name = "SyncDance"
	syncDanceEvent.Parent = remoteFolder
end

local updateDanceEvent = remoteFolder:FindFirstChild("UpdateDance")
if not updateDanceEvent then
	updateDanceEvent = Instance.new("RemoteEvent")
	updateDanceEvent.Name = "UpdateDance"
	updateDanceEvent.Parent = remoteFolder
end

local stopDanceEvent = remoteFolder:FindFirstChild("StopDance")
if not stopDanceEvent then
	stopDanceEvent = Instance.new("RemoteEvent")
	stopDanceEvent.Name = "StopDance"
	stopDanceEvent.Parent = remoteFolder
end

local toggleFavoriteEvent = remoteFolder:FindFirstChild("ToggleFavorite")
if not toggleFavoriteEvent then
	toggleFavoriteEvent = Instance.new("RemoteEvent")
	toggleFavoriteEvent.Name = "ToggleFavorite"
	toggleFavoriteEvent.Parent = remoteFolder
end

local getFavoritesFunc = remoteFolder:FindFirstChild("GetFavorites")
if not getFavoritesFunc then
	getFavoritesFunc = Instance.new("RemoteFunction")
	getFavoritesFunc.Name = "GetFavorites"
	getFavoritesFunc.Parent = remoteFolder
end

local PlayerAnims = {}
local PlayerSpeeds = {}
local SynchronizedPlayer = {}

local playerDances = {}
local coordinateDanceGroups = {}
local playerToLeader = {}
local pendingCoordinates = {}

local function PlayAnim(player, data, synchronizedPlayer)
	if data == nil then return end
	PlayerAnims[player] = data
	PlayerSpeeds[player] = PlayerSpeeds[player] or 1

	data.Speed = PlayerSpeeds[player]
	SynchronizedPlayer[player] = synchronizedPlayer
	StartDance:FireAllClients(player, data, synchronizedPlayer)

	for p, target in pairs(SynchronizedPlayer) do
		if target == player then
			PlayAnim(p, data, player)
		end
	end

end

local function StopAnim(player)
	PlayerAnims[player] = nil
	StopDance:FireAllClients(player)

	for p, target in pairs(SynchronizedPlayer) do
		if target == player then
			StopAnim(p)
		end
	end

end

local lastSpeedSet = {}

local function SetSpeed(player, targetSpeed)
	local currentTime = tick()
	local lastTime = lastSpeedSet[player.UserId]

	if lastTime and (currentTime - lastTime) < 0.1 then
		return
	end

	lastSpeedSet[player.UserId] = currentTime

	if PlayerSpeeds[player] == targetSpeed then
		return
	end

	PlayerSpeeds[player] = math.max(0.0001, targetSpeed)

	if PlayerAnims[player] then
		SetSpeedEvent:FireAllClients(player, targetSpeed)

		for p, target in pairs(SynchronizedPlayer) do
			if target == player then
				SetSpeed(p, targetSpeed)
			end
		end
	end
end

local function SyncDance(player, synchronizedPlayer)
	local targetPlayer = synchronizedPlayer
	while SynchronizedPlayer[targetPlayer] ~= nil do
		targetPlayer = SynchronizedPlayer[targetPlayer]
	end
	if PlayerAnims[targetPlayer] == nil then
		return
	end

	PlayAnim(player, PlayerAnims[targetPlayer], targetPlayer)
	SyncDanceEvent:FireAllClients(player, synchronizedPlayer)

end

local function UnsyncDance(player)
	SynchronizedPlayer[player] = nil
	StopAnim(player)
	UnsyncDanceEvent:FireAllClients(player)

end

local function getPlayerDanceData(player)
	if playerDances[player] then
		local data = playerDances[player]
		local timeSinceUpdate = tick() - data.LastUpdate
		return data.AnimData, data.Speed, timeSinceUpdate
	end
	return nil, nil, nil
end

local stopCoordinateDance

local function startCoordinateDance(follower, leader)

	if playerToLeader[follower] then
		stopCoordinateDance(follower)
	end

	local animData, speed, timePosition = getPlayerDanceData(leader)

	if not animData then
		pendingCoordinates[follower] = leader
		playerToLeader[follower] = leader

		syncDanceEvent:FireClient(follower, leader, nil, 1, 0, true)
		return
	end

	pendingCoordinates[follower] = nil

	if not coordinateDanceGroups[leader] then
		coordinateDanceGroups[leader] = {
			followers = {}
		}
	end

	if not table.find(coordinateDanceGroups[leader].followers, follower) then
		table.insert(coordinateDanceGroups[leader].followers, follower)
	end

	playerToLeader[follower] = leader

	syncDanceEvent:FireClient(follower, leader, animData, speed, timePosition, false)

end

stopCoordinateDance = function(follower)
	pendingCoordinates[follower] = nil

	local leader = playerToLeader[follower]

	if leader and coordinateDanceGroups[leader] then
		local index = table.find(coordinateDanceGroups[leader].followers, follower)
		if index then
			table.remove(coordinateDanceGroups[leader].followers, index)
		end

		if #coordinateDanceGroups[leader].followers == 0 then
			coordinateDanceGroups[leader] = nil
		end
	end

	playerToLeader[follower] = nil

	syncDanceEvent:FireClient(follower, nil, nil, 1, 0, false)

end

local function updateFollowers(leader)
	if not coordinateDanceGroups[leader] then return end

	local animData, speed, timePosition = getPlayerDanceData(leader)

	if not animData then
		local followersToStop = {}
		for _, follower in ipairs(coordinateDanceGroups[leader].followers) do
			table.insert(followersToStop, follower)
		end

		for _, follower in ipairs(followersToStop) do
			stopCoordinateDance(follower)
		end
		return
	end

	for _, follower in ipairs(coordinateDanceGroups[leader].followers) do
		syncDanceEvent:FireClient(follower, leader, animData, speed, timePosition, false)
	end
end

local function checkPendingCoordinates()
	for follower, leader in pairs(pendingCoordinates) do
		if follower and follower.Parent and leader and leader.Parent then
			local animData, speed, timePosition = getPlayerDanceData(leader)
			if animData then
				startCoordinateDance(follower, leader)
			end
		else
			pendingCoordinates[follower] = nil
		end
	end
end

local lastUpdate = tick()
RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	if currentTime - lastUpdate >= 0.1 then
		lastUpdate = currentTime
		checkPendingCoordinates()
	end
end)

StartDance.OnServerEvent:Connect(function(player, data)
	PlayAnim(player, data, SynchronizedPlayer[player])

	playerDances[player] = {
		AnimData = data,
		Speed = PlayerSpeeds[player] or 1,
		LastUpdate = tick()
	}

	updateFollowers(player)
end)

StopDance.OnServerEvent:Connect(function(player)
	StopAnim(player)
	playerDances[player] = nil
	updateFollowers(player)
end)

SetSpeedEvent.OnServerEvent:Connect(function(player, speed)
	SetSpeed(player, speed)

	if playerDances[player] then
		playerDances[player].Speed = speed
		playerDances[player].LastUpdate = tick()
	end
end)

SyncDanceEvent.OnServerEvent:Connect(function(player, synchronizedPlayer)
	SyncDance(player, synchronizedPlayer)
end)

UnsyncDanceEvent.OnServerEvent:Connect(function(player)
	UnsyncDance(player)
	stopCoordinateDance(player)
end)

updateDanceEvent.OnServerEvent:Connect(function(player, animData, speed)

	playerDances[player] = {
		AnimData = animData,
		Speed = speed,
		LastUpdate = tick()
	}

	updateFollowers(player)
end)

stopDanceEvent.OnServerEvent:Connect(function(player)
	playerDances[player] = nil
	updateFollowers(player)
end)

startCoordinateDanceEvent.OnServerEvent:Connect(function(follower, leader)
	if not leader or not leader.Parent then
		warn("⚠️ [DANCE SERVER] Invalid leader for coordinate dance")
		return
	end

	if leader == follower then
		warn("⚠️ [DANCE SERVER] Cannot coordinate dance with yourself")
		return
	end

	startCoordinateDance(follower, leader)
end)

stopCoordinateDanceEvent.OnServerEvent:Connect(function(follower)
	stopCoordinateDance(follower)
end)

toggleFavoriteEvent.OnServerEvent:Connect(function(player, danceTitle)
	if not player or not player.Parent or not danceTitle then return end

	local DataHandler = require(script.Parent:WaitForChild("DataHandler"))

	local isFavorite = DataHandler:ArrayContains(player, "FavoriteDances", danceTitle)

	if isFavorite then

		DataHandler:RemoveFromArray(player, "FavoriteDances", danceTitle)
		DataHandler:SavePlayer(player)
	else

		DataHandler:AddToArray(player, "FavoriteDances", danceTitle)
		DataHandler:SavePlayer(player)
	end
end)

getFavoritesFunc.OnServerInvoke = function(player)
	local DataHandler = require(script.Parent:WaitForChild("DataHandler"))
	local data = DataHandler:GetData(player)

	if data then
		return data.FavoriteDances or {}
	end

	return {}
end

Players.PlayerRemoving:Connect(function(player)
	PlayerAnims[player] = nil
	PlayerSpeeds[player] = nil
	SynchronizedPlayer[player] = nil
	lastSpeedSet[player.UserId] = nil

	playerDances[player] = nil

	stopCoordinateDance(player)

	if coordinateDanceGroups[player] then
		local followersToStop = {}
		for _, follower in ipairs(coordinateDanceGroups[player].followers) do
			table.insert(followersToStop, follower)
		end

		for _, follower in ipairs(followersToStop) do
			stopCoordinateDance(follower)
		end
		coordinateDanceGroups[player] = nil
	end

end)
