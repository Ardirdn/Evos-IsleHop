--[[
    UNDERWATER EFFECTS CLIENT
    Applies visual effects when camera is underwater (Terrain Water)
    
    Place in StarterPlayerScripts
    
    Features:
    - Blur effect
    - Depth of Field effect
    - Color Correction tinting
    - Saves original lighting and restores on exit
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Terrain = Workspace:WaitForChild("Terrain")
local Camera = Workspace:WaitForChild("Camera")

print("🌊 [UNDERWATER EFFECTS] Starting...")

-- ==================== CONFIG ====================

local CONFIG = {
    TransitionSteps = 15,       -- How many steps for transition animation
    TransitionWait = 0.02,      -- Wait between each step (seconds)
    
    -- Blur settings
    Blur = {
        Enabled = true,
        UnderwaterSize = 15,    -- Blur size when fully underwater
    },
    
    -- Depth of Field settings
    DepthOfField = {
        Enabled = true,
        UnderwaterFarIntensity = 0.6,
        UnderwaterFocusDistance = 10,
        UnderwaterInFocusRadius = 8,
        UnderwaterNearIntensity = 0.3,
    },
    
    -- Color Correction (tint multipliers per step)
    ColorCorrection = {
        Enabled = true,
        TintR = 0.038,          -- Red reduction per step
        TintG = 0.027,          -- Green reduction per step
        TintB = 0.014,          -- Blue reduction per step (less = more blue underwater)
    },
}

-- ==================== STATE ====================

local isUnderwater = false
local isTransitioning = false

-- Store original lighting effects
local originalLighting = {
    DepthOfField = nil,
    hasOriginalDOF = false,
}

-- ==================== SAVE ORIGINAL LIGHTING ====================

local function saveOriginalLighting()
    -- Save existing DepthOfField if any
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

-- ==================== APPLY UNDERWATER EFFECTS ====================

local function applyUnderwaterEffects()
    if isTransitioning then return end
    isTransitioning = true
    
    local steps = CONFIG.TransitionSteps
    
    -- Create Blur if enabled and not exists
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
    
    -- Create Depth of Field if enabled and not exists
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
    
    -- Create Color Correction if enabled and not exists
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
    
    -- Animate transition
    task.spawn(function()
        for i = 0, steps do
            local t = i / steps
            
            -- Blur
            if blur then
                blur.Size = t * CONFIG.Blur.UnderwaterSize
            end
            
            -- Depth of Field
            if dof then
                dof.FarIntensity = t * CONFIG.DepthOfField.UnderwaterFarIntensity
                dof.NearIntensity = t * CONFIG.DepthOfField.UnderwaterNearIntensity
                dof.FocusDistance = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterFocusDistance))
                dof.InFocusRadius = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterInFocusRadius))
            end
            
            -- Color Correction (blue tint)
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
    
    print("🌊 [UNDERWATER EFFECTS] Camera ENTERED water")
end

-- ==================== REMOVE UNDERWATER EFFECTS ====================

local function removeUnderwaterEffects()
    if isTransitioning then return end
    
    local blur = Lighting:FindFirstChild("WaterBlur")
    local dof = Lighting:FindFirstChild("WaterDepthOfField")
    local cc = Lighting:FindFirstChild("WaterColorCorrection")
    
    if not blur and not dof and not cc then return end
    
    isTransitioning = true
    
    -- Rename to prevent duplicate creation during transition
    if blur then blur.Name = "WaterBlurTweening" end
    if dof then dof.Name = "WaterDOFTweening" end
    
    local steps = CONFIG.TransitionSteps
    
    task.spawn(function()
        local blurTween = Lighting:FindFirstChild("WaterBlurTweening")
        local dofTween = Lighting:FindFirstChild("WaterDOFTweening")
        
        for i = steps, 0, -1 do
            local t = i / steps
            
            -- Blur
            if blurTween then
                blurTween.Size = t * CONFIG.Blur.UnderwaterSize
            end
            
            -- Depth of Field
            if dofTween then
                dofTween.FarIntensity = t * CONFIG.DepthOfField.UnderwaterFarIntensity
                dofTween.NearIntensity = t * CONFIG.DepthOfField.UnderwaterNearIntensity
                dofTween.FocusDistance = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterFocusDistance))
                dofTween.InFocusRadius = 50 - (t * (50 - CONFIG.DepthOfField.UnderwaterInFocusRadius))
            end
            
            -- Color Correction
            if cc then
                cc.TintColor = Color3.new(
                    1 - CONFIG.ColorCorrection.TintR * i,
                    1 - CONFIG.ColorCorrection.TintG * i,
                    1 - CONFIG.ColorCorrection.TintB * i
                )
            end
            
            task.wait(CONFIG.TransitionWait)
        end
        
        -- Cleanup effects
        if blurTween then blurTween:Destroy() end
        if dofTween then dofTween:Destroy() end
        if cc then cc:Destroy() end
        
        isTransitioning = false
    end)
    
    print("🌊 [UNDERWATER EFFECTS] Camera EXITED water")
end

-- ==================== WATER DETECTION ====================

local function checkIfUnderwater()
    local camPos = Camera.CFrame.Position
    
    -- Create region around camera and align to grid
    local region = Region3.new(
        Vector3.new(camPos.X - 2, camPos.Y - 2, camPos.Z - 2),
        Vector3.new(camPos.X + 2, camPos.Y + 2, camPos.Z + 2)
    )
    region = region:ExpandToGrid(4)
    
    -- Read terrain voxels
    local success, materials = pcall(function()
        return Terrain:ReadVoxels(region, 4)
    end)
    
    if not success or not materials then
        return false
    end
    
    -- Check if camera is in water
    local material = materials[1][1][1]
    return material == Enum.Material.Water
end

-- ==================== MAIN LOOP ====================

local function onCameraChanged()
    local underwater = checkIfUnderwater()
    
    if underwater and not isUnderwater then
        -- Just entered water
        isUnderwater = true
        applyUnderwaterEffects()
        
    elseif not underwater and isUnderwater then
        -- Just exited water
        isUnderwater = false
        removeUnderwaterEffects()
    end
end

-- ==================== INITIALIZATION ====================

local function initialize()
    -- Save original lighting settings
    saveOriginalLighting()
    
    -- Connect to camera movement
    Camera:GetPropertyChangedSignal("CFrame"):Connect(onCameraChanged)
    
    -- Initial check
    onCameraChanged()
    
    print("✅ [UNDERWATER EFFECTS] System initialized!")
end

-- Start
initialize()
