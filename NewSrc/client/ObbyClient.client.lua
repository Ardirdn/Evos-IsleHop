local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local obbyRemotes = ReplicatedStorage:WaitForChild("ObbyRemotes", 30)
if not obbyRemotes then
    warn("[OBBY CLIENT] ObbyRemotes not found!")
    return
end

local replaceObbyFunc = obbyRemotes:WaitForChild("ReplaceObby", 10)
if not replaceObbyFunc then
    warn("[OBBY CLIENT] ReplaceObby remote not found!")
    return
end

local CONFIG = {
    PromptReenableDelay = 2,
}

local function setupBoard(board)
    local prompt = board:FindFirstChildOfClass("ProximityPrompt")
    local obbyNameValue = board:FindFirstChild("ObbyName")

    if not prompt then
        warn(string.format("[OBBY CLIENT] ProximityPrompt not found in board: %s", board.Name))
        return
    end

    if not obbyNameValue or not obbyNameValue:IsA("StringValue") then
        warn(string.format("[OBBY CLIENT] ObbyName StringValue not found in board: %s", board.Name))
        return
    end

    if obbyNameValue.Value == "" then
        warn(string.format("[OBBY CLIENT] ObbyName is empty in board: %s", board.Name))
        return
    end

    prompt.Triggered:Connect(function(triggeringPlayer)

        if triggeringPlayer ~= player then return end

        local obbyName = obbyNameValue.Value

        prompt.Enabled = false

        local status = replaceObbyFunc:InvokeServer(obbyName)

        if status == "Success" then
        elseif status == "Cooldown" then
        elseif status == "InUse" then
        else
        end

        task.wait(CONFIG.PromptReenableDelay)
        prompt.Enabled = true
    end)
end

local function initialize()

    local mapFolder = Workspace:WaitForChild("map", 30)
    if not mapFolder then
        warn("[OBBY CLIENT] Workspace.map not found!")
        return
    end

    local replaceBoardsFolder = mapFolder:WaitForChild("ReplaceBoards", 10)
    if not replaceBoardsFolder then
        warn("[OBBY CLIENT] ReplaceBoards folder not found in map!")
        return
    end

    for _, board in ipairs(replaceBoardsFolder:GetChildren()) do
        setupBoard(board)
    end

    replaceBoardsFolder.ChildAdded:Connect(function(board)
        task.wait(0.1)
        setupBoard(board)
    end)

end

initialize()
