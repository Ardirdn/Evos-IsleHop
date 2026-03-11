local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FlyAbility = {}

local activeFlights = {}
local toolEquipped = {}

local flightRemote = nil
local speedUpdateRemote = nil
local flightToggleRemote = nil
local equipStateRemote = nil

if RunService:IsServer() then
    flightRemote = ReplicatedStorage:FindFirstChild("FlightStateChanged")
    if not flightRemote then
        flightRemote = Instance.new("RemoteEvent")
        flightRemote.Name = "FlightStateChanged"
        flightRemote.Parent = ReplicatedStorage
    end

    speedUpdateRemote = ReplicatedStorage:FindFirstChild("FlightSpeedUpdate")
    if not speedUpdateRemote then
        speedUpdateRemote = Instance.new("RemoteEvent")
        speedUpdateRemote.Name = "FlightSpeedUpdate"
        speedUpdateRemote.Parent = ReplicatedStorage
    end

    flightToggleRemote = ReplicatedStorage:FindFirstChild("FlightToggle")
    if not flightToggleRemote then
        flightToggleRemote = Instance.new("RemoteEvent")
        flightToggleRemote.Name = "FlightToggle"
        flightToggleRemote.Parent = ReplicatedStorage
    end

    equipStateRemote = ReplicatedStorage:FindFirstChild("FlightEquipState")
    if not equipStateRemote then
        equipStateRemote = Instance.new("RemoteEvent")
        equipStateRemote.Name = "FlightEquipState"
        equipStateRemote.Parent = ReplicatedStorage
    end

    -- Remote baru: client kasih tahu server saat tool di-equip/unequip
    local equipNotifyRemote = ReplicatedStorage:FindFirstChild("FlightEquipNotify")
    if not equipNotifyRemote then
        equipNotifyRemote = Instance.new("RemoteEvent")
        equipNotifyRemote.Name = "FlightEquipNotify"
        equipNotifyRemote.Parent = ReplicatedStorage
    end

end

local DEFAULT_CONFIG = {
    FlightSpeed = 80,
    BoostSpeed = 16,
    GyroP = 20000,
    AccessoryName = "AdminWing",
    AnimationId = "rbxassetid://111312412597365",
}

local playerConfigs = {}

local function getAccessoryTemplate(accessoryName)
    if not accessoryName then return nil end

    local accecoriesFolder = ReplicatedStorage:FindFirstChild("Accecories")
    if accecoriesFolder then
        local template = accecoriesFolder:FindFirstChild(accessoryName)
        if template and template:IsA("Accessory") then
            return template
        end

        local flyingAccFolder = accecoriesFolder:FindFirstChild("FlyingToolAccecories")
        if flyingAccFolder then
            template = flyingAccFolder:FindFirstChild(accessoryName)
            if template and template:IsA("Accessory") then
                return template
            end
        end
    end
    warn("[FLY ABILITY] Accessory not found:", accessoryName)
    return nil
end

local function cleanupFlightPhysics(character)
    if not character then return end
    -- FlightGyro dan FlightVelocity sekarang dikelola oleh client
    -- Server hanya perlu clear attribute IsFlying
    character:SetAttribute("IsFlying", nil)
end

local function removeFlightAccessory(character)
    if not character then return end

    local accessory = character:FindFirstChild("FlightAccessory")
    if accessory then
        accessory:Destroy()
    end
end

function FlyAbility:StartFlight(player, config)
    if not RunService:IsServer() then return false end
    if not player then return false end

    local character = player.Character
    if not character then return false end

    if activeFlights[player] then
        return false
    end

    if character:GetAttribute("IsPetrified") or
       character:GetAttribute("IsDancing") or
       character:GetAttribute("IsDizzy") or
       character:GetAttribute("IsTrapped") then
        -- Kirim sinyal gagal ke client agar toggle direset ke OFF
        if flightRemote then
            flightRemote:FireClient(player, false, {BlockedReason = true})
        end
        return false
    end

    config = config or playerConfigs[player] or {}

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then return false end

    local state = {
        originalSpeed = humanoid.WalkSpeed,
        accessory = nil,
        animTrack = nil,
    }

    character:SetAttribute("IsFlying", true)

    -- BodyGyro dan BodyVelocity TIDAK dibuat di server
    -- Client yang membuat sendiri agar tidak ada masalah replication race condition

    local boost = config.BoostSpeed or DEFAULT_CONFIG.BoostSpeed
    humanoid.WalkSpeed = state.originalSpeed + boost

    local accessoryName = config.AccessoryName or DEFAULT_CONFIG.AccessoryName
    if accessoryName then
        local template = getAccessoryTemplate(accessoryName)
        if template then
            state.accessory = template:Clone()
            state.accessory.Name = "FlightAccessory"
            humanoid:AddAccessory(state.accessory)
        end
    end

    local animId = config.AnimationId or DEFAULT_CONFIG.AnimationId
    if animId then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = animId

        local success, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)

        if success and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play()
            state.animTrack = track
        else
            warn("[FLY ABILITY] Failed to load animation")
        end
    end

    activeFlights[player] = state

    local flightSpeed = config.FlightSpeed or DEFAULT_CONFIG.FlightSpeed
    local gyroP = config.GyroP or DEFAULT_CONFIG.GyroP
    -- Kirim config ke client agar client bisa buat BodyGyro/BodyVelocity sendiri
    flightRemote:FireClient(player, true, {FlightSpeed = flightSpeed, GyroP = gyroP})

    return true
end

function FlyAbility:StopFlight(player)
    if not RunService:IsServer() then return end
    if not player then return end

    local character = player.Character
    local state = activeFlights[player]

    if character then
        cleanupFlightPhysics(character)
        removeFlightAccessory(character)
    end

    if not state then return end

    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and state.originalSpeed then
        humanoid.WalkSpeed = state.originalSpeed
    end

    if state.animTrack then
        state.animTrack:Stop()
        state.animTrack = nil
    end

    if state.accessory and state.accessory.Parent then
        state.accessory:Destroy()
    end

    activeFlights[player] = nil

    if flightRemote and player.Parent then
        flightRemote:FireClient(player, false, {})
    end

end

function FlyAbility:OnEquip(player, config)
    if not RunService:IsServer() then return end
    if not player then return end

    toolEquipped[player] = true
    playerConfigs[player] = config or {}

    local flightSpeed = config and config.FlightSpeed or DEFAULT_CONFIG.FlightSpeed
    if equipStateRemote then
        equipStateRemote:FireClient(player, true, {FlightSpeed = flightSpeed})
    end
end

function FlyAbility:OnUnequip(player)
    if not RunService:IsServer() then return end
    if not player then return end

    toolEquipped[player] = false

    if activeFlights[player] then
        self:StopFlight(player)
    end

    equipStateRemote:FireClient(player, false, {})

end

function FlyAbility:ForceCleanup(player)
    if not RunService:IsServer() then return end
    if not player then return end

    if activeFlights[player] then
        self:StopFlight(player)
    end

    toolEquipped[player] = false
    playerConfigs[player] = nil

    local character = player.Character
    if character then
        cleanupFlightPhysics(character)
        removeFlightAccessory(character)

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end

    if equipStateRemote and player.Parent then
        equipStateRemote:FireClient(player, false, {ForceCleanup = true})
    end

end

function FlyAbility:IsFlying(player)
    if activeFlights[player] then
        return true
    end
    if player and player.Character then
        return player.Character:GetAttribute("IsFlying") == true
    end
    return false
end

-- Fungsi untuk cek apakah player benar-benar punya wing tool (fallback jika LocalScript belum notify)
local function playerHasAdminWingTool(player)
    local character = player.Character
    if character and character:FindFirstChild("AdminWing") then
        return true
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild("AdminWing") then
        return true
    end
    return false
end

-- Public API: InventoryServer bisa langsung set state dari server tanpa butuh LocalScript notify
function FlyAbility:SetToolEquipped(player, isEquipped, config)
    if not RunService:IsServer() then return end
    if not player then return end

    if isEquipped then
        toolEquipped[player] = true
        playerConfigs[player] = config or {}
        local flightSpeed = config and config.FlightSpeed or DEFAULT_CONFIG.FlightSpeed
        if equipStateRemote then
            equipStateRemote:FireClient(player, true, {FlightSpeed = flightSpeed})
        end
    else
        toolEquipped[player] = false
        if activeFlights[player] then
            self:StopFlight(player)
        end
        if equipStateRemote then
            equipStateRemote:FireClient(player, false, {})
        end
        playerConfigs[player] = nil
    end
end

if RunService:IsServer() then
    task.defer(function()
        local toggleRemote = ReplicatedStorage:WaitForChild("FlightToggle", 5)
        if toggleRemote then
            toggleRemote.OnServerEvent:Connect(function(player, enabled)
                -- Fallback: jika toolEquipped belum di-set (LocalScript lambat),
                -- cek langsung apakah player benar-benar punya tool di character/backpack
                if not toolEquipped[player] then
                    if playerHasAdminWingTool(player) then
                        -- Auto-set state agar toggle bisa berjalan
                        toolEquipped[player] = true
                        playerConfigs[player] = playerConfigs[player] or {}
                        warn("[FLY ABILITY] toolEquipped auto-set via fallback for", player.Name)
                    else
                        return -- Benar-benar tidak punya tool, tolak
                    end
                end

                if enabled then
                    local config = playerConfigs[player] or {}
                    FlyAbility:StartFlight(player, config)
                else
                    FlyAbility:StopFlight(player)
                end
            end)
        end

        -- Handler dari LocalScript tool saat equip/unequip
        local equipNotifyRemote = ReplicatedStorage:WaitForChild("FlightEquipNotify", 5)
        if equipNotifyRemote then
            equipNotifyRemote.OnServerEvent:Connect(function(player, isEquipped, config)
                if isEquipped then
                    toolEquipped[player] = true
                    playerConfigs[player] = config or {}
                    local flightSpeed = config and config.FlightSpeed or DEFAULT_CONFIG.FlightSpeed
                    if equipStateRemote then
                        equipStateRemote:FireClient(player, true, {FlightSpeed = flightSpeed})
                    end
                else
                    toolEquipped[player] = false
                    if activeFlights[player] then
                        FlyAbility:StopFlight(player)
                    end
                    if equipStateRemote then
                        equipStateRemote:FireClient(player, false, {})
                    end
                    playerConfigs[player] = nil
                end
            end)
        end

        local speedRemote = ReplicatedStorage:WaitForChild("FlightSpeedUpdate", 5)
        if speedRemote then
            speedRemote.OnServerEvent:Connect(function(player, newSpeed)
                newSpeed = math.clamp(newSpeed, 30, 500)

                if flightRemote and activeFlights[player] then
                    flightRemote:FireClient(player, true, {FlightSpeed = newSpeed, UpdateSpeedOnly = true})
                end
            end)
        end
    end)
end

if RunService:IsClient() then
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")

    local isFlying = false
    local flightConnection = nil
    local collisionCache = {}
    local currentFlightSpeed = 80

    local flightControlUI = nil
    local isFlightEnabled = false

    local function disableCollision(character)
        collisionCache = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                collisionCache[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    end

    local function restoreCollision(character)
        for part, originalState in pairs(collisionCache) do
            if part and part.Parent then
                part.CanCollide = originalState
            end
        end
        collisionCache = {}
    end

    local function createFlightUI()
        if flightControlUI then return end

        local playerGui = LocalPlayer:WaitForChild("PlayerGui")

        flightControlUI = Instance.new("ScreenGui")
        flightControlUI.Name = "FlightControlUI"
        flightControlUI.ResetOnSpawn = false
        flightControlUI.Parent = playerGui

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(0, 50, 0, 280)
        container.Position = UDim2.new(0.85, 0, 0.5, -140)
        container.BackgroundTransparency = 1
        container.Parent = flightControlUI

        local toggleFrame = Instance.new("Frame")
        toggleFrame.Name = "ToggleFrame"
        toggleFrame.Size = UDim2.new(1, 0, 0, 50)
        toggleFrame.Position = UDim2.new(0, 0, 0, 0)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        toggleFrame.BackgroundTransparency = 0.3
        toggleFrame.BorderSizePixel = 0
        toggleFrame.Parent = container

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 8)
        toggleCorner.Parent = toggleFrame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleBtn"
        toggleBtn.Size = UDim2.new(1, -10, 1, -10)
        toggleBtn.Position = UDim2.new(0, 5, 0, 5)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Text = "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 14
        toggleBtn.AutoButtonColor = false
        toggleBtn.Parent = toggleFrame

        local toggleBtnCorner = Instance.new("UICorner")
        toggleBtnCorner.CornerRadius = UDim.new(0, 6)
        toggleBtnCorner.Parent = toggleBtn

        local sliderFrame = Instance.new("Frame")
        sliderFrame.Name = "SliderFrame"
        sliderFrame.Size = UDim2.new(1, 0, 0, 220)
        sliderFrame.Position = UDim2.new(0, 0, 0, 55)
        sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        sliderFrame.BackgroundTransparency = 0.3
        sliderFrame.BorderSizePixel = 0
        sliderFrame.Parent = container

        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 8)
        sliderCorner.Parent = sliderFrame

        local speedLabel = Instance.new("TextLabel")
        speedLabel.Name = "SpeedLabel"
        speedLabel.Size = UDim2.new(1, 0, 0, 25)
        speedLabel.Position = UDim2.new(0, 0, 0, 5)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = tostring(math.floor(currentFlightSpeed))
        speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        speedLabel.TextSize = 14
        speedLabel.Font = Enum.Font.GothamBold
        speedLabel.Parent = sliderFrame

        local track = Instance.new("Frame")
        track.Name = "Track"
        track.Size = UDim2.new(0, 6, 0, 150)
        track.Position = UDim2.new(0.5, -3, 0, 35)
        track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        track.BorderSizePixel = 0
        track.Parent = sliderFrame

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 3)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(1, 0, 0.5, 0)
        fill.Position = UDim2.new(0, 0, 0.5, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        fill.BorderSizePixel = 0
        fill.Parent = track

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0.5, -10, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = track

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local maxLabel = Instance.new("TextLabel")
        maxLabel.Size = UDim2.new(1, 0, 0, 15)
        maxLabel.Position = UDim2.new(0, 0, 1, -20)
        maxLabel.BackgroundTransparency = 1
        maxLabel.Text = "30"
        maxLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        maxLabel.TextSize = 10
        maxLabel.Font = Enum.Font.Gotham
        maxLabel.Parent = sliderFrame

        local minLabel = Instance.new("TextLabel")
        minLabel.Size = UDim2.new(1, 0, 0, 15)
        minLabel.Position = UDim2.new(0, 0, 0, 20)
        minLabel.BackgroundTransparency = 1
        minLabel.Text = "500"
        minLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        minLabel.TextSize = 10
        minLabel.Font = Enum.Font.Gotham
        minLabel.Parent = sliderFrame

        local dragging = false

        local function updateSlider(yPos)
            local trackAbsPos = track.AbsolutePosition.Y
            local trackAbsSize = track.AbsoluteSize.Y

            local relativeY = math.clamp((yPos - trackAbsPos) / trackAbsSize, 0, 1)

            local speed = 500 - (relativeY * (500 - 30))
            currentFlightSpeed = math.floor(speed)

            knob.Position = UDim2.new(0.5, -10, relativeY, -10)
            fill.Size = UDim2.new(1, 0, 1 - relativeY, 0)
            fill.Position = UDim2.new(0, 0, relativeY, 0)
            speedLabel.Text = tostring(currentFlightSpeed)

            if isFlying then
                local remote = ReplicatedStorage:FindFirstChild("FlightSpeedUpdate")
                if remote then
                    remote:FireServer(currentFlightSpeed)
                end
            end
        end

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input.Position.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                            input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input.Position.Y)
            end
        end)

        local function updateToggleVisual()
            if isFlightEnabled then
                TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(67, 181, 129)
                }):Play()
                toggleBtn.Text = "ON"
            else
                TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                }):Play()
                toggleBtn.Text = "OFF"
            end
        end

        toggleBtn.MouseButton1Click:Connect(function()
            isFlightEnabled = not isFlightEnabled
            updateToggleVisual()

            local remote = ReplicatedStorage:FindFirstChild("FlightToggle")
            if remote then
                remote:FireServer(isFlightEnabled)
            end
        end)

        local initialRatio = (500 - currentFlightSpeed) / (500 - 30)
        knob.Position = UDim2.new(0.5, -10, initialRatio, -10)
        fill.Size = UDim2.new(1, 0, 1 - initialRatio, 0)
        fill.Position = UDim2.new(0, 0, initialRatio, 0)

        isFlightEnabled = false
        updateToggleVisual()

    end

    local function showFlightUI()
        if flightControlUI then
            flightControlUI.Enabled = true
        end
    end

    local function hideFlightUI()
        if flightControlUI then
            flightControlUI.Enabled = false
        end
    end

    local function destroyFlightUI()
        if flightControlUI then
            flightControlUI:Destroy()
            flightControlUI = nil
        end
        isFlightEnabled = false
    end

    local function resetToggle()
        isFlightEnabled = false
        if flightControlUI then
            local container = flightControlUI:FindFirstChild("Container")
            if container then
                local toggleFrame = container:FindFirstChild("ToggleFrame")
                if toggleFrame then
                    local toggleBtn = toggleFrame:FindFirstChild("ToggleBtn")
                    if toggleBtn then
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                        toggleBtn.Text = "OFF"
                    end
                end
            end
        end
    end

    local function startFlightControl(params)
        if isFlying and not params.UpdateSpeedOnly then return end

        if params.UpdateSpeedOnly then
            currentFlightSpeed = params.FlightSpeed or currentFlightSpeed
            return
        end

        isFlying = true
        currentFlightSpeed = params.FlightSpeed or 80
        local gyroP = params.GyroP or 20000

        local character = LocalPlayer.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not hrp then return end

        disableCollision(character)
        humanoid.PlatformStand = true

        -- CLIENT buat BodyGyro dan BodyVelocity sendiri (bukan tunggu replikasi dari server)
        -- Ini fix race condition: tidak perlu FindFirstChild yang bisa return nil
        local flightGyro = hrp:FindFirstChild("FlightGyro")
        if not flightGyro then
            flightGyro = Instance.new("BodyGyro")
            flightGyro.Name = "FlightGyro"
            flightGyro.P = gyroP
            flightGyro.MaxTorque = Vector3.new(gyroP, gyroP, gyroP)
            flightGyro.CFrame = hrp.CFrame
            flightGyro.Parent = hrp
        end

        local flightVelocity = hrp:FindFirstChild("FlightVelocity")
        if not flightVelocity then
            flightVelocity = Instance.new("BodyVelocity")
            flightVelocity.Name = "FlightVelocity"
            flightVelocity.P = 1250
            flightVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flightVelocity.Velocity = Vector3.new(0, 0, 0)
            flightVelocity.Parent = hrp
        end

        local cachedParts = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(cachedParts, part)
            end
        end

        flightConnection = RunService.RenderStepped:Connect(function()
            if not isFlying then return end
            if not character or not character.Parent then return end
            if humanoid.Health <= 0 then return end

            for _, part in ipairs(cachedParts) do
                if part and part.Parent then
                    part.CanCollide = false
                end
            end

            -- Pakai variabel yang sudah dibuat di atas, bukan FindFirstChild setiap frame
            if not flightGyro or not flightGyro.Parent then return end
            if not flightVelocity or not flightVelocity.Parent then return end

            local camera = workspace.CurrentCamera
            local moveDirection = humanoid.MoveDirection

            if moveDirection.Magnitude > 0.01 then
                local horizontalDir = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
                flightGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + horizontalDir)
            end

            if moveDirection.Magnitude > 0.01 then
                local camLook = CFrame.new(Vector3.new(), Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit)
                local dirInCamSpace = camLook:VectorToObjectSpace(moveDirection)
                local moveVector = (camera.CFrame.RightVector * dirInCamSpace.X) + (camera.CFrame.LookVector * -dirInCamSpace.Z)

                flightVelocity.Velocity = moveVector * currentFlightSpeed
            else
                local bobY = math.sin(tick() * 2) * 0.5
                flightVelocity.Velocity = flightVelocity.Velocity:Lerp(Vector3.new(0, bobY, 0), 0.1)
            end
        end)

    end

    local function stopFlightControl()
        if not isFlying then return end
        isFlying = false

        if flightConnection then
            flightConnection:Disconnect()
            flightConnection = nil
        end

        local character = LocalPlayer.Character
        if character then
            restoreCollision(character)

            -- Destroy objek fisika yang dibuat oleh client
            local hrp2 = character:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                local g = hrp2:FindFirstChild("FlightGyro")
                if g then g:Destroy() end
                local v = hrp2:FindFirstChild("FlightVelocity")
                if v then v:Destroy() end
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end

        resetToggle()
    end

    local function setupClientListeners()
        local flightRemote = ReplicatedStorage:WaitForChild("FlightStateChanged", 10)
        if flightRemote then
            flightRemote.OnClientEvent:Connect(function(isStarting, params)
                if isStarting then
                    startFlightControl(params)
                else
                    if params and params.BlockedReason then
                        -- Flight diblokir oleh kondisi player, reset toggle ke OFF saja
                        resetToggle()
                    else
                        stopFlightControl()
                    end
                end
            end)
        end

        local equipRemote = ReplicatedStorage:WaitForChild("FlightEquipState", 10)
        if equipRemote then
            equipRemote.OnClientEvent:Connect(function(isEquipped, params)
                if isEquipped then
                    currentFlightSpeed = params.FlightSpeed or 80
                    createFlightUI()
                    showFlightUI()
                else
                    hideFlightUI()
                    destroyFlightUI()
                end
            end)
        end
    end

    task.spawn(setupClientListeners)
end

if RunService:IsServer() then
    local function setupPlayerCleanup(player)
        player.CharacterRemoving:Connect(function(character)
            if activeFlights[player] then
                FlyAbility:StopFlight(player)
            else
                cleanupFlightPhysics(character)
                removeFlightAccessory(character)
            end
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayerCleanup(player)
    end

    Players.PlayerAdded:Connect(setupPlayerCleanup)

    Players.PlayerRemoving:Connect(function(player)
        activeFlights[player] = nil
        toolEquipped[player] = nil
        playerConfigs[player] = nil
    end)
end

return FlyAbility
