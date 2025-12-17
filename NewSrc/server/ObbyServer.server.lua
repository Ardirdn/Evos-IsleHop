local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local NotificationService = require(script.Parent.NotificationServer)

local remoteFolder = ReplicatedStorage:FindFirstChild("ObbyRemotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "ObbyRemotes"
    remoteFolder.Parent = ReplicatedStorage
end

local replaceObbyFunc = remoteFolder:FindFirstChild("ReplaceObby")
if not replaceObbyFunc then
    replaceObbyFunc = Instance.new("RemoteFunction")
    replaceObbyFunc.Name = "ReplaceObby"
    replaceObbyFunc.Parent = remoteFolder
end

local CONFIG = {
    ServerCooldown = 60,
    PlayerCooldown = 15,
    PromptReenableDelay = 2,
}

local lastServerReplace = 0
local playerCooldowns = {}

local ObbyTemplates = nil
local ActiveObbys = nil

local function getObbyTemplates()
    if not ObbyTemplates then
        ObbyTemplates = ServerStorage:FindFirstChild("Obby")
        if not ObbyTemplates then
            warn("⚠️ [OBBY SERVER] ServerStorage.Obby folder not found!")
        end
    end
    return ObbyTemplates
end

local function getActiveObbys()
    if not ActiveObbys then
        local mapFolder = Workspace:FindFirstChild("map")
        if mapFolder then
            ActiveObbys = mapFolder:FindFirstChild("Obby")
        end
        if not ActiveObbys then
            warn("⚠️ [OBBY SERVER] Workspace.map.Obby folder not found!")
        end
    end
    return ActiveObbys
end

local function isPlayerInObbyArea(obbyName)
    local activeObbys = getActiveObbys()
    if not activeObbys then return true end

    local obbyFolder = activeObbys:FindFirstChild(obbyName)
    if not obbyFolder then
        warn(string.format("⚠️ [OBBY SERVER] Obby folder '%s' not found", obbyName))
        return true
    end

    local areasFolder = obbyFolder:FindFirstChild("Areas")
    if not areasFolder then
        warn(string.format("⚠️ [OBBY SERVER] Areas folder not found in '%s'", obbyName))
        return false
    end

    for _, areaPart in ipairs(areasFolder:GetChildren()) do
        if areaPart:IsA("BasePart") then
            local touchingParts = Workspace:GetPartsInPart(areaPart)
            for _, part in ipairs(touchingParts) do
                local player = Players:GetPlayerFromCharacter(part.Parent)
                if player then
                    return true
                end
            end
        end
    end

    return false
end

local function replaceObby(player, obbyName)
    if not player or not player.Parent then
        return "Error"
    end

    if not obbyName or obbyName == "" then
        NotificationService:Send(player, {
            Message = "Nama obby tidak valid!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end

    local currentTime = os.time()
    if currentTime - lastServerReplace < CONFIG.ServerCooldown then
        local remaining = CONFIG.ServerCooldown - (currentTime - lastServerReplace)
        NotificationService:Send(player, {
            Message = string.format("Server cooldown. Coba lagi dalam %d detik.", remaining),
            Type = "error",
            Duration = 3,
            Icon = "⏳"
        })
        return "Cooldown"
    end

    if playerCooldowns[player.UserId] and currentTime - playerCooldowns[player.UserId] < CONFIG.PlayerCooldown then
        local remaining = CONFIG.PlayerCooldown - (currentTime - playerCooldowns[player.UserId])
        NotificationService:Send(player, {
            Message = string.format("Coba lagi dalam %d detik.", remaining),
            Type = "error",
            Duration = 3,
            Icon = "⏳"
        })
        return "Cooldown"
    end

    if isPlayerInObbyArea(obbyName) then
        NotificationService:Send(player, {
            Message = "Rintangan sedang dilewati pemain lain.",
            Type = "error",
            Duration = 3,
            Icon = "🚶"
        })
        return "InUse"
    end

    local obbyTemplates = getObbyTemplates()
    if not obbyTemplates then
        NotificationService:Send(player, {
            Message = "Template obby tidak ditemukan!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end

    local obbyTemplate = obbyTemplates:FindFirstChild(obbyName)
    if not obbyTemplate then
        warn(string.format("⚠️ [OBBY SERVER] Template '%s' not found in ServerStorage.Obby", obbyName))
        NotificationService:Send(player, {
            Message = "Template rintangan tidak ditemukan!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end

    local activeObbys = getActiveObbys()
    if not activeObbys then
        NotificationService:Send(player, {
            Message = "Folder obby tidak ditemukan!",
            Type = "error",
            Duration = 3
        })
        return "Error"
    end

    local activeObby = activeObbys:FindFirstChild(obbyName)
    if activeObby then
        activeObby:Destroy()
    end

    local newObby = obbyTemplate:Clone()
    newObby.Parent = activeObbys

    playerCooldowns[player.UserId] = currentTime
    lastServerReplace = currentTime

    NotificationService:Send(player, {
        Message = "✅ Rintangan berhasil diperbarui!",
        Type = "success",
        Duration = 3,
        Icon = "🔧"
    })

    return "Success"
end

replaceObbyFunc.OnServerInvoke = function(player, obbyName)
    return replaceObby(player, obbyName)
end

Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player.UserId] = nil
end)
