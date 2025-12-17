local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)

local remoteFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "MusicRemotes"
	remoteFolder.Parent = ReplicatedStorage
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

toggleFavoriteEvent.OnServerEvent:Connect(function(player, songId)
	if not player or not songId then return end

	local isFavorite = DataHandler:ArrayContains(player, "FavoriteMusic", songId)

	if isFavorite then

		DataHandler:RemoveFromArray(player, "FavoriteMusic", songId)
	else

		DataHandler:AddToArray(player, "FavoriteMusic", songId)
	end

	DataHandler:SavePlayer(player)
end)

getFavoritesFunc.OnServerInvoke = function(player)
	local data = DataHandler:GetData(player)

	if data then
		return data.FavoriteMusic or {}
	end

	return {}
end
