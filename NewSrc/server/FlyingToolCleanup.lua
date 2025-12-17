local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FlyingToolCleanup = {}

local FlyAbility = nil
pcall(function()
    FlyAbility = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FlyAbility"))
end)

local FLYING_SPEED_ACCESSORY_NAME = "KudaLumpingReward"
local FLYING_SPEED_BODY_POSITION_NAME = "HeightBodyPosition"
local FLYING_SPEED_ANIMATION_ID = "rbxassetid://111312412597365"

local ADMIN_WING_ACCESSORY_NAME = "FlightAccessory"
local ADMIN_WING_GYRO_NAME = "FlightGyro"
local ADMIN_WING_VELOCITY_NAME = "FlightVelocity"

function FlyingToolCleanup:IsFlyingTool(toolId)
    if not toolId then return false end

    if toolId == "AdminWing" then
        return true, "AdminWing"
    end

    if string.match(toolId, "^FlyingSpeed%d*$") then
        return true, "FlyingSpeed"
    end

    return false, nil
end

function FlyingToolCleanup:CleanupAdminWing(player)
    if not player then return end

    if FlyAbility and FlyAbility.ForceCleanup then
        FlyAbility:ForceCleanup(player)
        return
    end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local gyro = hrp:FindFirstChild(ADMIN_WING_GYRO_NAME)
        if gyro then gyro:Destroy() end

        local velocity = hrp:FindFirstChild(ADMIN_WING_VELOCITY_NAME)
        if velocity then velocity:Destroy() end
    end

    local accessory = character:FindFirstChild(ADMIN_WING_ACCESSORY_NAME)
    if accessory then
        accessory:Destroy()
    end

    character:SetAttribute("IsFlying", nil)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end

end

function FlyingToolCleanup:CleanupFlyingSpeed(player)
    if not player then return end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bp = hrp:FindFirstChild(FLYING_SPEED_BODY_POSITION_NAME)
        if bp then
            bp:Destroy()
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") and child.Name == FLYING_SPEED_ACCESSORY_NAME then
            child:Destroy()
        end
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == FLYING_SPEED_ANIMATION_ID then
                    track:Stop()
                end
            end
        end
    end

end

function FlyingToolCleanup:CleanupByToolId(player, toolId)
    local isFlying, toolType = self:IsFlyingTool(toolId)

    if not isFlying then
        return false
    end

    if toolType == "AdminWing" then
        self:CleanupAdminWing(player)
        return true
    elseif toolType == "FlyingSpeed" then
        self:CleanupFlyingSpeed(player)
        return true
    end

    return false
end

function FlyingToolCleanup:CleanupAll(player)
    if not player then return end

    self:CleanupAdminWing(player)
    self:CleanupFlyingSpeed(player)

end

return FlyingToolCleanup
