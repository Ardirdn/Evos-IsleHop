local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Terrain = Workspace:WaitForChild("Terrain")
local Camera = Workspace:WaitForChild("Camera")

local CONFIG = {
    TransitionSteps = 15,
    TransitionWait = 0.02,

    Blur = {
        Enabled = true,
        UnderwaterSize = 15,
    },

    DepthOfField = {
        Enabled = true,
        UnderwaterFarIntensity = 0.6,
        UnderwaterFocusDistance = 10,
        UnderwaterInFocusRadius = 8,
        UnderwaterNearIntensity = 0.3,
    },

    ColorCorrection = {
        Enabled = true,
        TintR = 0.038,
        TintG = 0.027,
        TintB = 0.014,
    },
}

local isUnderwater = false
local isTransitioning = false

local originalLighting = {
    DepthOfField = nil,
    hasOriginalDOF = false,
}

local function saveOriginalLighting()

    local existingDOF = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if existingDOF and existingDOF.Name ~= "WaterDepthOfField" then
        originalLighting.DepthOfField = {
            FarIntensity = existingDOF.FarIntensity,
            FocusDistance = existingDOF.FocusDistance,
            InFocusRadius = existingDOF.InFocusRadius,
            NearIntensity = existingDOF.NearIntensity,
        }
        originalLighting.hasOriginalDOF = true
    end
end

local function applyUnderwaterEffects()
    if isTransitioning then return end
    isTransitioning = true

    local steps = CONFIG.TransitionSteps

    local blur = nil
    if CONFIG.Blur.Enabled then
        blur = Lighting:FindFirstChild("WaterBlur")
        if not blur then
            blur = Instance.new("BlurEffect")
            blur.Name = "WaterBlur"
            blur.Size = 0
            blur.Parent = Lighting
        end
    end

    local dof = nil
    if CONFIG.DepthOfField.Enabled then
        dof = Lighting:FindFirstChild("WaterDepthOfField")
        if not dof then
            dof = Instance.new("DepthOfFieldEffect")
            dof.Name = "WaterDepthOfField"
            dof.FarIntensity = 0
            dof.FocusDistance = 50
            dof.InFocusRadius = 50
            dof.NearIntensity = 0
            dof.Parent = Lighting
        end
    end

    local cc = nil
    if CONFIG.ColorCorrection.Enabled then
        cc = Lighting:FindFirstChild("WaterColorCorrection")
        if not cc then
            cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "WaterColorCorrection"
            cc.TintColor = Color3.new(1, 1, 1)
            cc.Parent = Lighting
        end
    end

    task.spawn(function()
        for i = 0, steps do
            local t = i / steps

            if blur then
                blur.Size = t * CONFIG.Blur.UnderwaterSize
            end

            if dof then
                dof.FarIntensity = t * CONFIG.DepthOfField.UnderwaterFarIntensity
                dof.NearIntensity = t * CONFIG.DepthOfField.UnderwaterNearIntensity
                dof.FocusDistance = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterFocusDistance))
                dof.InFocusRadius = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterInFocusRadius))
            end

            if cc then
                cc.TintColor = Color3.new(
                    1 - CONFIG.ColorCorrection.TintR * i,
                    1 - CONFIG.ColorCorrection.TintG * i,
                    1 - CONFIG.ColorCorrection.TintB * i
                )
            end

            task.wait(CONFIG.TransitionWait)
        end

        isTransitioning = false
    end)

end

local function removeUnderwaterEffects()
    if isTransitioning then return end

    local blur = Lighting:FindFirstChild("WaterBlur")
    local dof = Lighting:FindFirstChild("WaterDepthOfField")
    local cc = Lighting:FindFirstChild("WaterColorCorrection")

    if not blur and not dof and not cc then return end

    isTransitioning = true

    if blur then blur.Name = "WaterBlurTweening" end
    if dof then dof.Name = "WaterDOFTweening" end

    local steps = CONFIG.TransitionSteps

    task.spawn(function()
        local blurTween = Lighting:FindFirstChild("WaterBlurTweening")
        local dofTween = Lighting:FindFirstChild("WaterDOFTweening")

        for i = steps, 0, -1 do
            local t = i / steps

            if blurTween then
                blurTween.Size = t * CONFIG.Blur.UnderwaterSize
            end

            if dofTween then
                dofTween.FarIntensity = t * CONFIG.DepthOfField.UnderwaterFarIntensity
                dofTween.NearIntensity = t * CONFIG.DepthOfField.UnderwaterNearIntensity
                dofTween.FocusDistance = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterFocusDistance))
                dofTween.InFocusRadius = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterInFocusRadius))
            end

            if cc then
                cc.TintColor = Color3.new(
                    1 - CONFIG.ColorCorrection.TintR * i,
                    1 - CONFIG.ColorCorrection.TintG * i,
                    1 - CONFIG.ColorCorrection.TintB * i
                )
            end

            task.wait(CONFIG.TransitionWait)
        end

        if blurTween then blurTween:Destroy() end
        if dofTween then dofTween:Destroy() end
        if cc then cc:Destroy() end

        isTransitioning = false
    end)

end

local function checkIfUnderwater()
    local camPos = Camera.CFrame.Position

    local region = Region3.new(
        Vector3.new(camPos.X - 2, camPos.Y - 2, camPos.Z - 2),
        Vector3.new(camPos.X + 2, camPos.Y + 2, camPos.Z + 2)
    )
    region = region:ExpandToGrid(4)

    local success, materials = pcall(function()
        return Terrain:ReadVoxels(region, 4)
    end)

    if not success or not materials then
        return false
    end

    local material = materials[1][1][1]
    return material == Enum.Material.Water
end

local function onCameraChanged()
    local underwater = checkIfUnderwater()

    if underwater and not isUnderwater then

        isUnderwater = true
        applyUnderwaterEffects()

    elseif not underwater and isUnderwater then

        isUnderwater = false
        removeUnderwaterEffects()
    end
end

local function initialize()

    saveOriginalLighting()

    Camera:GetPropertyChangedSignal("CFrame"):Connect(onCameraChanged)

    onCameraChanged()

end

initialize()
