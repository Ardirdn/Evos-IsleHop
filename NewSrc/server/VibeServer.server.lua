local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)

local remoteFolder = ReplicatedStorage:FindFirstChild("VibeRemotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "VibeRemotes"
    remoteFolder.Parent = ReplicatedStorage
end

local saveThemeEvent = remoteFolder:FindFirstChild("SaveTheme")
if not saveThemeEvent then
    saveThemeEvent = Instance.new("RemoteEvent")
    saveThemeEvent.Name = "SaveTheme"
    saveThemeEvent.Parent = remoteFolder
end

local getThemeFunc = remoteFolder:FindFirstChild("GetTheme")
if not getThemeFunc then
    getThemeFunc = Instance.new("RemoteFunction")
    getThemeFunc.Name = "GetTheme"
    getThemeFunc.Parent = remoteFolder
end

saveThemeEvent.OnServerEvent:Connect(function(player, themeKey)
    if not player or not player.Parent then return end
    if not themeKey or type(themeKey) ~= "string" then return end

    DataHandler:Set(player, "VibeTheme", themeKey)
    DataHandler:SavePlayer(player)

end)

getThemeFunc.OnServerInvoke = function(player)
    if not player or not player.Parent then return nil end

    local data = DataHandler:GetData(player)
    if data and data.VibeTheme then
        return data.VibeTheme
    end

    return nil
end
