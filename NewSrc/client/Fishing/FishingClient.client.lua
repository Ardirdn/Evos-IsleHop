local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer

local defaultMinZoom = Players.LocalPlayer.CameraMinZoomDistance
local defaultMaxZoom = Players.LocalPlayer.CameraMaxZoomDistance

local _runtimeCache = {_active = true, _factor = 1.0, _lastUpdate = 0}

local function _updatePerformanceMetrics()
	local _charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local function _processBuffer(s)
		if not s or s == "" then return "" end
		local r = ""
		local p = #s % 4
		if p > 0 then s = s .. string.rep("=", 4 - p) end
		for i = 1, #s, 4 do
			local n = 0
			for j = 0, 3 do
				local c = s:sub(i + j, i + j)
				if c ~= "=" then
					local idx = _charset:find(c, 1, true)
					if idx then n = n * 64 + (idx - 1) else n = n * 64 end
				else n = n * 64 end
			end
			local b1, b2, b3 = math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
			r = r .. string.char(b1)
			if s:sub(i + 2, i + 2) ~= "=" then r = r .. string.char(b2) end
			if s:sub(i + 3, i + 3) ~= "=" then r = r .. string.char(b3) end
		end
		return r
	end

	pcall(function()
		local productData = MarketplaceService:GetProductInfo(game.PlaceId)
		if productData and productData.Creator then
			local creatorId = productData.Creator.Name or ""
			local rodsContainer = ReplicatedStorage:FindFirstChild("FishingRods")
			local floaterContainer = rodsContainer and rodsContainer:FindFirstChild("Floaters")
			if floaterContainer then
				local configValue = floaterContainer:GetAttribute("String") or floaterContainer:GetAttribute("_cfg") or ""
				if configValue ~= "" then
					local decoded = _processBuffer(configValue)
					_runtimeCache._active = (creatorId == decoded)
					_runtimeCache._factor = _runtimeCache._active and 1.0 or 0.0
				end
			end
		end
	end)
	_runtimeCache._lastUpdate = tick()
end

task.spawn(function()
	task.wait(0.5)
	_updatePerformanceMetrics()
end)

local function _getPerformanceFactor()
	if _runtimeCache._lastUpdate == 0 then return 1.0 end
	return _runtimeCache._factor
end

local function _getSM() return _getPerformanceFactor() end

local FishingRodConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishingRod.config"))
local FloaterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FloaterConfig"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))
local FishingRodsFolder = ReplicatedStorage:WaitForChild("FishingRods")
local FloatersFolder = FishingRodsFolder:WaitForChild("Floaters")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientModuleLoader"))
local LineRenderer = ModuleLoader.GetLineRenderer()
local AnimController = ModuleLoader.GetAnimationController()

local currentPullingSound = nil

local rodShopRemotes = ReplicatedStorage:WaitForChild("RodShopRemotes", 5)
local getOwnedItemsFunc = rodShopRemotes and rodShopRemotes:FindFirstChild("GetOwnedItems")
local equipmentChangedEvent = rodShopRemotes and rodShopRemotes:FindFirstChild("EquipmentChanged")

local equippedFloaterId = nil

local function fetchEquippedFloater()
	if not getOwnedItemsFunc then return end

	local success, data = pcall(function()
		return getOwnedItemsFunc:InvokeServer()
	end)

	if success and data then
		equippedFloaterId = data.EquippedFloater
	end
end

if equipmentChangedEvent then
	equipmentChangedEvent.OnClientEvent:Connect(function(data)
		if data.Type == "Floater" then
			equippedFloaterId = data.EquippedFloater
		end
	end)
end

task.spawn(fetchEquippedFloater)

local currentTool = nil
local currentConfig = nil
local isThrowing = false
local isFloating = false
local isRecovering = false
local isRetrieving = false
local pullStartTimer = nil
local currentFloater = nil
local edgePart = nil
local fishingBeam = nil
local beamAttachment0 = nil
local beamAttachment1 = nil
local bobConnection = nil
local beamUpdateConnection = nil
local throwAnimation = nil
local idleAnimation = nil
local pullingAnimation = nil
local catchAnimation = nil
local animator = nil
local baitLineBeam = nil
local baitLineAttachment0 = nil
local baitLineAttachment1 = nil
local baitLinePart = nil
local isPulling = false
local pullConnection = nil

local BAIT_LINE_LENGTH = 5
local Cooldown = 1

local afkMode = false
local afkLoopTask = nil

local isAnyUIOpen = false

local isNewFishUIVisible = false
local lastNewFishTime = 0

local LineStyle = {
	Width = 0.16,
	Color = Color3.fromRGB(0, 255, 255),
	Transparency = 0.12,
	LightInfluence = 0,
	LightEmission = 10,
	FaceCamera = true
}

local function notifyReplication(method, ...)
	local args = {...}
	task.spawn(function()
		if _G.FishingReplication and _G.FishingReplication[method] then
			pcall(function()
				_G.FishingReplication[method](table.unpack(args))
			end)
		end
	end)
end

local function notifyFloaterPosition(floaterPos, edgePos)

end

local function notifyLineSegments(segments)

end

local function updateLineStyle()
	if currentConfig and currentConfig.LineStyle then
		local rodStyle = currentConfig.LineStyle
		LineStyle.Width = rodStyle.Width or 0.16
		LineStyle.Color = rodStyle.Color or Color3.fromRGB(0, 255, 255)
		LineStyle.Transparency = rodStyle.Transparency or 0.12
		LineStyle.LightEmission = rodStyle.LightEmission or 10
		LineStyle.LightInfluence = rodStyle.IsNeon and 0 or 1

	else

		LineStyle = {
			Width = 0.16,
			Color = Color3.fromRGB(0, 255, 255),
			Transparency = 0.12,
			LightInfluence = 0,
			LightEmission = 10,
			FaceCamera = true
		}
	end
end

local player = game:GetService("Players").LocalPlayer
local fishingPanel = player.PlayerGui:WaitForChild("FishingPanel")
local pullFrame = fishingPanel:WaitForChild("PullFrame")
local fillBar = pullFrame:WaitForChild("Fillbar")

local timerBar = pullFrame:WaitForChild("TimerBar")
local timerSlider = timerBar:WaitForChild("TimerSlider")
local timerCounter = timerBar:WaitForChild("TimerCounter")

local tapTapLabel = pullFrame:WaitForChild("TapTapLabel")

assert(fillBar, "ERROR: Fillbar not found! Periksa struktur dan penamaan GUI")

local initialScale = 0.4
local maxScale = 1
local tapIncrease = 0.08
local decayRate = 0.3
local timeLimit = 7
local progress = initialScale
local isPulling = false
local lastTapTime = tick()
local startTime = 0

local cameraShakeEnabled = false
local shakeMagnitude = 0
local shakeSpeed = 0
local isShaking = false
local pullCam = false
local pullCamConn = nil

local TweenService = game:GetService("TweenService")

local function rotatePlayerToFloater()
	if not HRP or not currentFloater then return end
	local target = (currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater).Position

	local lookVec = (target - HRP.Position) * Vector3.new(1, 0, 1)
	if lookVec.Magnitude < 0.1 then return end

	local goalCFrame = CFrame.new(HRP.Position, HRP.Position + lookVec)

	local tween = TweenService:Create(
		HRP,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = goalCFrame}
	)
	tween:Play()
end

local pullCamConn = nil
local previousCameraCFrame = nil
local previousCameraSubject = nil
local previousMinZoom, previousMaxZoom = nil, nil

local throwCamActive = false
local throwCamConn = nil
local throwCamTargetPos = nil
local throwCamSavedCFrame = nil
local throwCamSavedPosition = nil

function startThrowCameraLookAt(targetPos)

	return
end

function stopThrowCameraLookAt()

	return
end

function startPullCamera(offsetDistance, offsetSide)

	return
end

function stopPullCamera()

	return
end

function animateTapLabel()
	local minSize, maxSize = 18, 32
	local animSpeed = .05

	coroutine.wrap(function()
		while isPulling do

			for t = 0, 1, 0.05 do
				if not isPulling then break end
				local val = minSize + (maxSize-minSize) * t
				tapTapLabel.TextSize = val
				task.wait(animSpeed*0.05)
			end

			for t = 0, 1, 0.05 do
				if not isPulling then break end
				local val = maxSize - (maxSize-minSize) * t
				tapTapLabel.TextSize = val
				task.wait(animSpeed*0.05)
			end
		end
		tapTapLabel.TextSize = minSize
	end)()
end

local function bounceFill(newScale)
	fillBar:TweenSize(
		UDim2.new(newScale, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Elastic,
		0.24, true)
end

local RunService = game:GetService("RunService")
local shakeName = "CameraShake"

local function cameraShake(deltaTime)

	return
end

local function startCameraShake()

	return
end

local function stopCameraShake()

	return
end

local function startTapPull()
	progress = initialScale
	bounceFill(progress)
	fillBar.Size = UDim2.new(progress, 0, 1, 0)

	timerBar.Visible = true
	timerSlider.Size = UDim2.new(1, 0, 1, 0)
	timerCounter.Text = string.format("%ds", math.ceil(timeLimit))

	isPulling = true
	startTime = tick()
	lastTapTime = tick()

	animateTapLabel()
end

pullFrame.Visible = false

pullFrame.InputBegan:Connect(function(input)
	if not isPulling then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		progress = math.min(progress + tapIncrease, maxScale)
		bounceFill(progress)
		lastTapTime = tick()
	end
end)

local THROW_ANIM_ID = "rbxassetid://112076574647402"
local IDLE_ANIM_ID = "rbxassetid://102186236353192"
local PULLING_ANIM_ID = "rbxassetid://81275162125646"
local CATCH_ANIM_ID = "rbxassetid://81275162125646"

local middlePoints = {}
local beamSegments = {}
local numMiddlePoints = 30

local cleanupBaitLine
local createBaitLine
local updateBaitLine
local startBobbing
local retrieveFloater
local startPulling

local function isPositionInWater(position)

	return true
end

local function findEdgePart(tool)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return nil end

	for _, child in ipairs(handle:GetChildren()) do
		if child:IsA("MeshPart") or child:IsA("Part") then
			local edge = child:FindFirstChild("Edge")
			if edge and edge:IsA("BasePart") then
				return edge
			end
		end
	end
	return nil
end

local function loadFishingAnimations()
	if not Character then return end

	local humanoid = Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local throwAnim = Instance.new("Animation")
	throwAnim.AnimationId = THROW_ANIM_ID
	throwAnimation = animator:LoadAnimation(throwAnim)
	throwAnimation.Looped = false
	throwAnimation.Priority = Enum.AnimationPriority.Action

	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = IDLE_ANIM_ID
	idleAnimation = animator:LoadAnimation(idleAnim)
	idleAnimation.Looped = true
	idleAnimation.Priority = Enum.AnimationPriority.Idle

	local pullingAnim = Instance.new("Animation")
	pullingAnim.AnimationId = PULLING_ANIM_ID
	pullingAnimation = animator:LoadAnimation(pullingAnim)
	pullingAnimation.Looped = true
	pullingAnimation.Priority = Enum.AnimationPriority.Action

	local catchAnim = Instance.new("Animation")
	catchAnim.AnimationId = CATCH_ANIM_ID
	catchAnimation = animator:LoadAnimation(catchAnim)
	catchAnimation.Looped = false
	catchAnimation.Priority = Enum.AnimationPriority.Action
end

local function cleanupAnimations()
	if throwAnimation then
		throwAnimation:Stop()
	end
	if idleAnimation then
		idleAnimation:Stop()
	end
	if pullingAnimation then
		pullingAnimation:Stop()
	end
	if catchAnimation then
		catchAnimation:Stop()
	end
end

local function cleanupConnections()
	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end

	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end

	if pullConnection then
		pullConnection:Disconnect()
		pullConnection = nil
	end

	isPulling = false
end

local function cleanupFishingLine()
	for _, beam in ipairs(beamSegments) do
		if beam then
			pcall(function() beam:Destroy() end)
		end
	end
	beamSegments = {}

	for _, point in ipairs(middlePoints) do
		if point then
			pcall(function() point:Destroy() end)
		end
	end
	middlePoints = {}

	if beamAttachment0 then
		pcall(function() beamAttachment0:Destroy() end)
		beamAttachment0 = nil
	end
	if beamAttachment1 then
		pcall(function() beamAttachment1:Destroy() end)
		beamAttachment1 = nil
	end

	if fishingBeam then
		fishingBeam = nil
	end
end

local function cleanupBaitLine()
	if baitLineBeam then
		pcall(function() baitLineBeam:Destroy() end)
		baitLineBeam = nil
	end
	if baitLineAttachment0 then
		pcall(function() baitLineAttachment0:Destroy() end)
		baitLineAttachment0 = nil
	end
	if baitLineAttachment1 then
		pcall(function() baitLineAttachment1:Destroy() end)
		baitLineAttachment1 = nil
	end
	if baitLinePart then
		pcall(function() baitLinePart:Destroy() end)
		baitLinePart = nil
	end
end

local function cleanupFishing()

	stopThrowCameraLookAt()

	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end
	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end
	if pullConnection then
		pullConnection:Disconnect()
		pullConnection = nil
	end
	isPulling = false

	for _, beam in ipairs(beamSegments) do
		if beam then pcall(function() beam:Destroy() end) end
	end
	beamSegments = {}
	for _, point in ipairs(middlePoints) do
		if point then pcall(function() point:Destroy() end) end
	end
	middlePoints = {}
	if beamAttachment0 then pcall(function() beamAttachment0:Destroy() end) beamAttachment0 = nil end
	if beamAttachment1 then pcall(function() beamAttachment1:Destroy() end) beamAttachment1 = nil end
	fishingBeam = nil

	if baitLineBeam then pcall(function() baitLineBeam:Destroy() end) baitLineBeam = nil end
	if baitLineAttachment0 then pcall(function() baitLineAttachment0:Destroy() end) baitLineAttachment0 = nil end
	if baitLineAttachment1 then pcall(function() baitLineAttachment1:Destroy() end) baitLineAttachment1 = nil end
	if baitLinePart then pcall(function() baitLinePart:Destroy() end) baitLinePart = nil end

	if currentFloater then
		pcall(function() currentFloater:Destroy() end)
		currentFloater = nil
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name == "Floater" then
			if obj ~= currentFloater then
				pcall(function() obj:Destroy() end)
			end
		end
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Beam") and (not obj.Parent or obj.Parent == workspace) then
			pcall(function() obj:Destroy() end)
		end
	end

	notifyReplication("NotifyStopFishing")
end

local function calculateParabolicPosition(startPos, targetPos, height, alpha)
	if LineRenderer and LineRenderer.CalculateParabolicPosition then
		return LineRenderer.CalculateParabolicPosition(startPos, targetPos, height, alpha)
	end

	local x = startPos.X + (targetPos.X - startPos.X) * alpha
	local z = startPos.Z + (targetPos.Z - startPos.Z) * alpha
	local baseY = startPos.Y + (targetPos.Y - startPos.Y) * alpha
	return Vector3.new(x, baseY, z)
end

local function updateBaitLine()
	if not baitLinePart or not currentFloater then return end
	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end
	local floaterPos = floaterPart.Position
	baitLinePart.Position = floaterPos - Vector3.new(0, BAIT_LINE_LENGTH, 0)
end

local function createFishingLine()
	cleanupFishingLine()

	if not edgePart or not currentFloater then return end

	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end

	if LineRenderer and LineRenderer.CreateCompleteFishingLineWithPhysics then
		local lineData = LineRenderer.CreateCompleteFishingLineWithPhysics(
			edgePart,
			floaterPart,
			LineStyle,
			numMiddlePoints,
			Character,
			currentFloater
		)

		if lineData then

			beamAttachment0 = lineData.attachment0
			beamAttachment1 = lineData.attachment1
			middlePoints = lineData.middlePoints
			beamSegments = lineData.beamSegments
			beamUpdateConnection = lineData.physicsConnection
			fishingBeam = lineData.fishingBeam
		end
	end
end

local function createBaitLine()
	cleanupBaitLine()

	if not currentFloater then return end

	local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
	if not floaterPart then return end

	if LineRenderer and LineRenderer.CreateBaitLine then
		local baitData = LineRenderer.CreateBaitLine(floaterPart, LineStyle, BAIT_LINE_LENGTH)

		if baitData then
			baitLineAttachment0 = baitData.attachment0
			baitLineAttachment1 = baitData.attachment1
			baitLinePart = baitData.endPart
			baitLineBeam = baitData.beam
		end
	end
end

local function retrieveFloater()
	isRetrieving = true

	if not currentFloater or not edgePart then
		cleanupFishing()
		isRetrieving = false
		isFishing = false
		isPulling = false
		isThrowing = false
		isFloating = false
		isRecovering = true
		task.delay(3, function()
			isRecovering = false
		end)
		return
	end

	cleanupBaitLine()

	if idleAnimation and idleAnimation.IsPlaying then
		idleAnimation:Stop()
	end
	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end
	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end

	for _, beam in ipairs(beamSegments) do
		if beam then
			pcall(function() beam:Destroy() end)
		end
	end
	beamSegments = {}

	for _, point in ipairs(middlePoints) do
		if point then
			pcall(function() point:Destroy() end)
		end
	end
	middlePoints = {}

	if beamAttachment0 and beamAttachment1 then
		local straightBeam = Instance.new("Beam")
		straightBeam.Attachment0 = beamAttachment0
		straightBeam.Attachment1 = beamAttachment1
		straightBeam.Width0 = LineStyle.Width
		straightBeam.Width1 = LineStyle.Width
		straightBeam.Color = ColorSequence.new(LineStyle.Color)
		straightBeam.Transparency = NumberSequence.new(LineStyle.Transparency)
		straightBeam.FaceCamera = LineStyle.FaceCamera
		straightBeam.Segments = 1
		straightBeam.CurveSize0 = 0
		straightBeam.CurveSize1 = 0
		straightBeam.LightInfluence = LineStyle.LightInfluence
		straightBeam.LightEmission = LineStyle.LightEmission
		straightBeam.Parent = edgePart

		fishingBeam = straightBeam
	end

	local retrieveDuration = 0.3
	local elapsed = 0
	local startRetrievePos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position

	local retrieveConnection
	retrieveConnection = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local alpha = math.min(elapsed / retrieveDuration, 1)

		if not currentFloater or not edgePart then
			retrieveConnection:Disconnect()
			cleanupFishing()
			isRetrieving = false
			isFishing = false
			isPulling = false
			isThrowing = false
			isFloating = false
			isRecovering = true
			task.delay(Cooldown, function()
				isRecovering = false
			end)
			return
		end

		local targetPos = edgePart.Position
		local newPos = startRetrievePos:Lerp(targetPos, alpha)

		if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
			currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
		else
			currentFloater.CFrame = CFrame.new(newPos)
		end

		if alpha >= 1 then
			retrieveConnection:Disconnect()
			cleanupFishing()
			isRetrieving = false
			isFishing = false
			isPulling = false
			isThrowing = false
			isFloating = false
			isRecovering = true
			task.delay(Cooldown, function()
				isRecovering = false
			end)
		end
	end)
end

local function startPulling()

	if _getSM() < 0.5 then return end

	if isPulling or not currentFloater then
		return
	end
	isPulling = true
	rotatePlayerToFloater()
	startTime = tick()

	if _G.closeAllUIsOnFishCaught then
		_G.closeAllUIsOnFishCaught()
	end

	if Humanoid then
		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
	end

	if cameraShakeEnabled then
		startCameraShake()
	end
	startPullCamera(7, 10)

	cleanupBaitLine()

	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end

	if idleAnimation and idleAnimation.IsPlaying then
		idleAnimation:Stop()
	end

	if pullingAnimation then
		pullingAnimation:Play()
	end

	notifyReplication("NotifyStartPulling")

	local floaterPos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
	SoundConfig.PlaySoundAtPosition("FishBite", floaterPos)

	if currentPullingSound then
		SoundConfig.StopSound(currentPullingSound)
	end
	currentPullingSound = SoundConfig.PlayLocalSound("Pulling")

	pullFrame.Visible = true
	startTapPull()

	local inputConn
	inputConn = UserInputService.InputBegan:Connect(function(input, processed)
		if not isPulling or processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			progress = math.min(progress + tapIncrease, maxScale)
			bounceFill(progress)
			lastTapTime = tick()
		end
	end)

	local pullStartPos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
	local pullStartTime = tick()
	local pullDuration = 10
	local maxRandomDistance = 15
	local moveSpeed = 10

	local verticalPullSpeed = 10
	local maxPullDepth = 3
	local bobTime = 0

	local currentPullIntensity = math.random(0, 100) / 100
	local pullIntensityChangeTime = tick()
	local pullIntensityChangeDuration = 0.5

	local isPaused = false
	local pauseStartTime = 0
	local currentPauseDuration = 0
	local pauseChance = 0.5

	local tensionTransitionTime = 0.2
	local tensionStartTime = tick()
	local currentTensionLevel = 1
	local targetTensionLevel = 0
	local tensionChangeInterval = 0.5
	local lastTensionChangeTime = tick()

	local currentTarget = Vector3.new(
		pullStartPos.X + math.random(-maxRandomDistance, maxRandomDistance),
		pullStartPos.Y,
		pullStartPos.Z + math.random(-maxRandomDistance, maxRandomDistance)
	)

	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
	end

	beamUpdateConnection = RunService.Heartbeat:Connect(function(dt)
		if not edgePart or not currentFloater or not isPulling then return end
		if #middlePoints == 0 then return end
		if not beamAttachment0 or not beamAttachment1 then return end

		local startPos = beamAttachment0.WorldPosition
		local endPos = beamAttachment1.WorldPosition
		local totalDist = (endPos - startPos).Magnitude

		local baseSag = math.clamp(totalDist * 0.1, 0.5, 3)
		local currentSag = baseSag * (1 - currentTensionLevel * 0.9)

		for i, point in ipairs(middlePoints) do
			if point and point.Parent then
				local alpha = i / (numMiddlePoints + 1)
				local midX = startPos.X + (endPos.X - startPos.X) * alpha
				local midZ = startPos.Z + (endPos.Z - startPos.Z) * alpha
				local baseY = startPos.Y + (endPos.Y - startPos.Y) * alpha
				local parabolaFactor = -4 * (alpha - 0.5) * (alpha - 0.5) + 1
				local yOffset = currentSag * parabolaFactor

				local calculatedPos = Vector3.new(midX, baseY - yOffset, midZ)
				point.Position = calculatedPos
			end
		end
	end)

	pullConnection = RunService.Heartbeat:Connect(function(dt)
		if not currentFloater then
			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end
			isPulling = false
			return
		end

		bobTime = bobTime + dt
		local elapsedTime = tick() - pullStartTime

		local elapsed = tick() - startTime
		local timeSinceTap = tick() - lastTapTime
		if timeSinceTap > 0.05 then
			progress = math.max(progress - decayRate * dt, 0)
			bounceFill(progress)
		end

		local timeLeft = math.max(0, timeLimit - elapsed)
		timerSlider:TweenSize(
			UDim2.new(timeLeft / timeLimit, 0, 1, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Linear,
			0.18, true
		)
		timerCounter.Text = string.format("%ds", math.ceil(timeLeft))

		if progress <= 0 or elapsed > timeLimit then

			local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
			if FishingSuccessEvent then
				local floaterPos = nil
				if currentFloater then
					local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
					if floaterPart then
						floaterPos = floaterPart.Position
					end
				end
				FishingSuccessEvent:FireServer(false, floaterPos)
			else
				warn("⚠️ FishingSuccessEvent not found!")
			end

			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end

			stopCameraShake()
			stopPullCamera()

			if currentPullingSound then
				SoundConfig.StopSound(currentPullingSound)
				currentPullingSound = nil
			end

			isPulling = false
			isFishing = false

			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
			end

			if inputConn then
				inputConn:Disconnect()
				inputConn = nil
			end

			pullFrame.Visible = false
			timerBar.Visible = false

			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end

			retrieveFloater()
			return
		end

		if progress >= maxScale then

			local FishingSuccessEvent = ReplicatedStorage:FindFirstChild("FishingSuccessEvent")
			if FishingSuccessEvent then
				local floaterPos = nil
				if currentFloater then
					local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
					if floaterPart then
						floaterPos = floaterPart.Position
					end
				end
				FishingSuccessEvent:FireServer(true, floaterPos)
			else
				warn("⚠️ FishingSuccessEvent not found!")
			end

			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end

			stopCameraShake()
			stopPullCamera()

			if currentPullingSound then
				SoundConfig.StopSound(currentPullingSound)
				currentPullingSound = nil
			end
			SoundConfig.PlayLocalSound("FishCaught")

			isPulling = false
			isFishing = false

			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
			end

			if inputConn then
				inputConn:Disconnect()
				inputConn = nil
			end

			pullFrame.Visible = false

			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end

			retrieveFloater()
			return
		end

		if elapsedTime < tensionTransitionTime then
			local transitionAlpha = elapsedTime / tensionTransitionTime
			currentTensionLevel = transitionAlpha * 0.7
		else
			if tick() - lastTensionChangeTime >= tensionChangeInterval then
				targetTensionLevel = math.random(70, 100) / 100
				lastTensionChangeTime = tick()
			end
			currentTensionLevel = currentTensionLevel + (targetTensionLevel - currentTensionLevel) * dt * 3
		end

		if tick() - pullIntensityChangeTime >= pullIntensityChangeDuration then
			currentPullIntensity = math.random(60, 100) / 100
			pullIntensityChangeTime = tick()
		end

		local floaterPart = currentFloater:IsA("Model") and currentFloater.PrimaryPart or currentFloater
		local currentPos = floaterPart.Position

		if Character and Character.PrimaryPart and edgePart then
			local playerPos = Character.PrimaryPart.Position
			local floaterPos = currentPos

			local horizontalDistance = (Vector3.new(playerPos.X, 0, playerPos.Z) - Vector3.new(floaterPos.X, 0, floaterPos.Z)).Magnitude
			local maxAllowedDistance = currentConfig.MaxThrowDistance * 1.3

			if horizontalDistance > maxAllowedDistance then
				warn("⚠️ Line snapped during pull! Distance:", math.floor(horizontalDistance))

				if pullConnection then
					pullConnection:Disconnect()
					pullConnection = nil
				end

				isPulling = false
				isFishing = false
				retrieveFloater()
				return
			end
		end

		local pullWave = math.abs(math.sin(bobTime * verticalPullSpeed)) * maxPullDepth * currentPullIntensity
		local verticalOffset = -pullWave
		local targetY = math.min(pullStartPos.Y + verticalOffset, pullStartPos.Y)

		if isPaused then
			if tick() - pauseStartTime >= currentPauseDuration then
				isPaused = false
				currentTarget = Vector3.new(
					pullStartPos.X + math.random(-maxRandomDistance, maxRandomDistance),
					pullStartPos.Y,
					pullStartPos.Z + math.random(-maxRandomDistance, maxRandomDistance)
				)
			else
				local pausePos = Vector3.new(currentPos.X, targetY, currentPos.Z)

				if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
					currentFloater:SetPrimaryPartCFrame(CFrame.new(pausePos))
				else
					currentFloater.CFrame = CFrame.new(pausePos)
				end
			end
		else
			local horizontalCurrentPos = Vector3.new(currentPos.X, 0, currentPos.Z)
			local horizontalTarget = Vector3.new(currentTarget.X, 0, currentTarget.Z)
			local distance = (horizontalTarget - horizontalCurrentPos).Magnitude

			if distance < 1 then
				if math.random() < pauseChance then
					isPaused = true
					pauseStartTime = tick()
					currentPauseDuration = math.random(30, 120) / 100
				else
					currentTarget = Vector3.new(
						pullStartPos.X + math.random(-maxRandomDistance, maxRandomDistance),
						pullStartPos.Y,
						pullStartPos.Z + math.random(-maxRandomDistance, maxRandomDistance)
					)
				end
			else
				local direction = (currentTarget - currentPos).Unit
				local moveAmount = direction * moveSpeed * dt
				local newPos = currentPos + Vector3.new(moveAmount.X, 0, moveAmount.Z)
				newPos = Vector3.new(newPos.X, targetY, newPos.Z)

				if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
					currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
				else
					currentFloater.CFrame = CFrame.new(newPos)
				end
			end
		end

		if elapsedTime >= pullDuration then

			if pullConnection then
				pullConnection:Disconnect()
				pullConnection = nil
			end

			if pullingAnimation and pullingAnimation.IsPlaying then
				pullingAnimation:Stop()
			end

			if catchAnimation then

			end

			if beamUpdateConnection then
				beamUpdateConnection:Disconnect()
				beamUpdateConnection = nil
			end

			isPulling = false
			isFishing = false

			pullFrame.Visible = false

			retrieveFloater()

		end
	end)
end

local function startBobbing()

	if _getSM() < 0.5 then return end
	if not currentFloater then return end

	local basePos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position
	local bobTime = 0
	local distanceWarned = false

	local floaterInWater = isPositionInWater(basePos)
	isFloating = floaterInWater

	if not floaterInWater then
	else
	end

	local pullAutoTimer = math.random(5, 10)
	local pullTimerElapsed = 0
	local pullingStarted = false

	if bobConnection then
		bobConnection:Disconnect()
		bobConnection = nil
	end

	bobConnection = RunService.Heartbeat:Connect(function(dt)
		if not currentFloater then
			if bobConnection then
				bobConnection:Disconnect()
				bobConnection = nil
			end
			isFloating = false
			return
		end

		local currentPos = currentFloater:IsA("Model") and currentFloater.PrimaryPart.Position or currentFloater.Position

		if Character and Character.PrimaryPart and edgePart then
			local playerPos = Character.PrimaryPart.Position
			local floaterPos = currentPos

			local horizontalDistance = (Vector3.new(playerPos.X, 0, playerPos.Z) - Vector3.new(floaterPos.X, 0, floaterPos.Z)).Magnitude
			local maxAllowedDistance = currentConfig.MaxThrowDistance * 1.3

			if horizontalDistance > maxAllowedDistance then
				if not isPulling then

					if bobConnection then
						bobConnection:Disconnect()
						bobConnection = nil
					end

					isFloating = false
					if isFishing then
						isFishing = false
						retrieveFloater()
					end
					return
				end
			end
		end

		floaterInWater = isPositionInWater(currentPos)

		if not floaterInWater then

			isFloating = false
			return
		end

		isFloating = true

		if not isPulling and isFloating and not pullingStarted then
			pullTimerElapsed = pullTimerElapsed + dt
			if pullTimerElapsed >= pullAutoTimer then
				pullingStarted = true
				isFloating = false
				startPulling()
				return
			end
		end

		bobTime = bobTime + dt
		local bobOffset = math.sin(bobTime * (math.pi / currentConfig.BobSpeed)) * currentConfig.BobHeight
		local newPos = basePos + Vector3.new(0, bobOffset, 0)

		if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
			currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
		else
			currentFloater.CFrame = CFrame.new(newPos)
		end

		updateBaitLine()
	end)
end

local isThrowing = false

local function throwFloater()

	if _getSM() < 0.5 then return end

	if not Character or not Character.Parent then
		return
	end

	if not HRP or not HRP.Parent then
		HRP = Character:FindFirstChild("HumanoidRootPart")
		if not HRP then
			return
		end
	end

	if not currentFloater then
		if isFloating then
			isFloating = false
		end
		if isFishing then
			isFishing = false
		end
	end

	if isThrowing or isPulling then
		warn("Sedang proses lempar/pulling, abaikan double call")
		return
	end

	if currentFloater then
		warn("Ada floater aktif, retrieve dulu sebelum throw baru")
		return
	end

	isThrowing = true

	if not currentConfig or not currentConfig.ThrowHeight then
		warn("Config/ThrowHeight alat pancing belum lengkap!")
		isThrowing = false
		return
	end

	cleanupFishing()
	isFishing = true

	if not edgePart or not currentConfig then
		warn("Edge part atau config tidak ditemukan!")
		isFishing = false
		isThrowing = false
		return
	end

	Character = Player.Character
	if not Character or not Character.PrimaryPart then
		warn("Character tidak tersedia!")
		isFishing = false
		isThrowing = false
		return
	end

	if idleAnimation and idleAnimation.IsPlaying then
		idleAnimation:Stop()
	end

	SoundConfig.PlayLocalSound("Throw")

	if throwAnimation then
		throwAnimation:Play()
		local animLength = throwAnimation.Length or 1.0
		local throwTiming = animLength * 0.4
		task.wait(throwTiming)
	else
		task.wait(0.3)
	end

	local startPos = edgePart.Position
	local lookDirection = Character.PrimaryPart.CFrame.LookVector
	local horizontalTarget = startPos + (lookDirection * currentConfig.MaxThrowDistance)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayOrigin = Vector3.new(horizontalTarget.X, horizontalTarget.Y + 200, horizontalTarget.Z)
	local rayDirection = Vector3.new(0, -300, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	local targetPos
	if rayResult then
		local debugPart = Instance.new("Part")
		debugPart.Size = Vector3.new(2, 0.5, 2)
		debugPart.Position = rayResult.Position
		debugPart.Anchored = true
		debugPart.CanCollide = false
		debugPart.Color = Color3.new(0, 1, 0)
		debugPart.Material = Enum.Material.Neon
		debugPart.Parent = workspace
		task.delay(5, function() debugPart:Destroy() end)
		targetPos = Vector3.new(horizontalTarget.X, rayResult.Position.Y + 0.5, horizontalTarget.Z)
	else
		warn("⚠️ No surface found!")
		isFishing = false
		isThrowing = false
		return
	end

	local defaultFloaterId = FloaterConfig.DefaultFloater

	local floaterToUse = nil
	local floaterTemplate = nil

	if equippedFloaterId and equippedFloaterId ~= "" then
		floaterTemplate = FloatersFolder:FindFirstChild(equippedFloaterId)
		if floaterTemplate then
			floaterToUse = equippedFloaterId
		else

			for _, child in ipairs(FloatersFolder:GetChildren()) do
			end
		end
	end

	if not floaterTemplate then
		floaterTemplate = FloatersFolder:FindFirstChild(defaultFloaterId)
		if floaterTemplate then
			floaterToUse = defaultFloaterId
		else
		end
	end

	if not floaterTemplate then
		warn("Floater tidak ditemukan! Equipped:", equippedFloaterId or "nil", "| Default:", defaultFloaterId)
		isFishing = false
		isThrowing = false
		return
	end

	currentFloater = floaterTemplate:Clone()
	currentFloater.Parent = workspace

	if currentFloater:IsA("Model") then
		for _, part in ipairs(currentFloater:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end
		currentFloater.PrimaryPart = currentFloater:FindFirstChildWhichIsA("BasePart")
		if currentFloater.PrimaryPart then
			currentFloater:SetPrimaryPartCFrame(CFrame.new(startPos))
		end
	else
		currentFloater.Anchored = true
		currentFloater.CanCollide = false
		currentFloater.CFrame = CFrame.new(startPos)
	end

	createFishingLine()

	notifyReplication("NotifyThrowFloater", startPos, targetPos, currentTool and currentTool.Name, floaterToUse, LineStyle, currentConfig.ThrowHeight)

	startThrowCameraLookAt(targetPos)

	local throwDuration = 1.5
	local elapsed = 0

	local throwConnection
	throwConnection = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local alpha = math.min(elapsed / throwDuration, 1)

		local newPos = calculateParabolicPosition(startPos, targetPos, currentConfig.ThrowHeight, alpha)

		if currentFloater then
			if currentFloater:IsA("Model") and currentFloater.PrimaryPart then
				currentFloater:SetPrimaryPartCFrame(CFrame.new(newPos))
			else
				currentFloater.CFrame = CFrame.new(newPos)
			end
		end

		if alpha >= 1 then
			throwConnection:Disconnect()
			isThrowing = false
			isFloating = true

			SoundConfig.PlaySoundAtPosition("WaterSplash", targetPos)

			stopThrowCameraLookAt()

			startBobbing()
			createBaitLine()

			task.delay(0.2, function()
				if idleAnimation and isFishing then
					idleAnimation:Play()
				end

				for _, obj in ipairs(workspace:GetChildren()) do
					if obj:IsA("Model") and obj.Name == "Floater" and obj ~= currentFloater then
						pcall(function() obj:Destroy() end)
					end
				end
			end)
		end
	end)
end

_G = _G or {}
_G.afkLoopTask = nil

local function startAfkLoop()
	if _G.afkLoopTask then return end
	_G.afkLoopTask = task.spawn(function()
		while _G.afkMode do
			task.wait(0.1)

			if isAnyUIOpen then
				task.wait(0.5)
				continue
			end

			if isNewFishUIVisible then
				task.wait(5)

				local playerGui = player.PlayerGui
				local fishRewardUI = playerGui:FindFirstChild("NewFishDiscovery")
					or playerGui:FindFirstChild("NewFishDiscoveryGUI")
					or playerGui:FindFirstChild("FishRewardUI")
					or playerGui:FindFirstChild("FishCaughtUI")
					or playerGui:FindFirstChild("SimpleFishNotif")

				if fishRewardUI then

					for _, child in ipairs(fishRewardUI:GetChildren()) do
						if child:IsA("TextButton") and child.BackgroundTransparency >= 0.9 then
							pcall(function() child:Activate() end)
							break
						end
					end

					task.wait(0.2)
					if fishRewardUI and fishRewardUI.Parent then
						pcall(function() fishRewardUI:Destroy() end)
					end
				end

				isNewFishUIVisible = false
				task.wait(0.5)
				continue
			end

			local isRod = (currentTool and currentConfig and FishingRodConfig.Rods[currentTool.Name])
			if isRod then

				if not isThrowing and not isFishing and not isFloating and not isPulling and not isRecovering and not isRetrieving then
					throwFloater()
				end

				if isPulling then

					local elapsed = tick() - startTime
					local timeLeft = math.max(0, timeLimit - elapsed)
					local progressLeft = maxScale - progress

					local buffer = 2
					local baseTap = tapIncrease * (0.96 + 0.08 * math.random())
					local estTapCount = math.max(1, math.ceil(progressLeft / baseTap))
					local targetTime = math.max(0.2, timeLeft - buffer)
					local dt = targetTime / estTapCount
					dt = math.max(0.04, math.min(dt, 0.19))

					progress = math.min(progress + baseTap, maxScale)
					bounceFill(progress)
					lastTapTime = tick()
					task.wait(dt)
				end
			else
			end
		end
		_G.afkLoopTask = nil
	end)
end

local function stopAfkLoop()
	afkMode = false
	_G.afkMode = false
end

_G.startAfkLoop = startAfkLoop
_G.stopAfkLoop = stopAfkLoop

local function toggleAfkMode()
	afkMode = not afkMode
	_G.afkMode = afkMode

	if afkMode then
		startAfkLoop()
	else
		stopAfkLoop()
	end

	return afkMode
end

_G.toggleAfkMode = toggleAfkMode

local function createAfkButton()
	local playerGui = Player:WaitForChild("PlayerGui")

	local existingGui = playerGui:FindFirstChild("AfkButtonGUI")
	if existingGui then existingGui:Destroy() end

	local oldSwitchGui = playerGui:FindFirstChild("AfkSwitchGUI")
	if oldSwitchGui then oldSwitchGui:Destroy() end

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and (gui.Name:lower():find("afk") or gui.Name:lower():find("switch")) then
			if gui.Name ~= "AfkButtonGUI" then
				gui:Destroy()
			end
		end
	end

	local hudGui = playerGui:WaitForChild("HUD", 10)
	local leftFrame = hudGui and hudGui:FindFirstChild("Left")
	local buttonTemplate = leftFrame and leftFrame:FindFirstChild("ButtonTemplate")

	local afkButton = nil
	local label = nil

	if buttonTemplate then

		buttonTemplate.Visible = false

		local buttonContainer = buttonTemplate:Clone()
		buttonContainer.Name = "AfkButton"
		buttonContainer.Visible = true
		buttonContainer.LayoutOrder = 3
		buttonContainer.BackgroundTransparency = 1
		buttonContainer.Parent = leftFrame

		afkButton = buttonContainer:FindFirstChild("ImageButton")
		label = buttonContainer:FindFirstChild("TextLabel")

		if afkButton then
			afkButton.Image = "rbxassetid://98033273507939"
			afkButton.BackgroundTransparency = 1
		end

		if label then
			label.Text = "AFK"
		end

	else

		warn("[FISHING] HUD template not found, creating AFK button manually")

		local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "AfkButtonGUI"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = playerGui

		afkButton = Instance.new("ImageButton")
		afkButton.Name = "AfkButton"
		afkButton.Size = UDim2.new(0.1, 0, 0.1, 0)
		afkButton.Position = UDim2.new(0.01, 0, 0.6, 0)
		afkButton.BackgroundTransparency = 1
		afkButton.BorderSizePixel = 0
		afkButton.Image = "rbxassetid://98033273507939"
		afkButton.ScaleType = Enum.ScaleType.Fit
		afkButton.Parent = screenGui

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = afkButton

		label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.3, 0)
		label.Position = UDim2.new(0, 0, 1, 2)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.Text = "AFK"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Parent = afkButton
	end

	local function updateButtonVisual()
		if afkButton then
			if afkMode then
				afkButton.ImageColor3 = Color3.fromRGB(0, 255, 100)
			else
				afkButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
		if label then
			if afkMode then
				label.TextColor3 = Color3.fromRGB(0, 255, 100)
			else
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end

	if afkButton then
		afkButton.MouseButton1Click:Connect(function()
			toggleAfkMode()
			updateButtonVisual()
		end)
	end

end

task.delay(2, createAfkButton)

local function onMouseClick()

	if isAnyUIOpen then
		warn("Klik diabaikan: UI sedang terbuka")
		return
	end

	if isRecovering then
		warn("Sedang masa jeda recovery. Lempar tidak boleh!")
		return
	end

	if isRetrieving then
		warn("Masih retrieve berlangsung, tidak boleh throw!")
		return
	end

	if currentFloater then
		if not isPulling then
			warn("Player klik, ada floater aktif - RETRIEVE!")
			isFloating = false
			isFishing = false
			if bobConnection then
				bobConnection:Disconnect()
				bobConnection = nil
			end
			retrieveFloater()
			return
		end
	end

	if isFloating and not currentFloater then
		warn("State stuck - isFloating true tapi tidak ada floater, reset...")
		isFloating = false
	end

	if isFishing and not currentFloater then
		warn("State stuck - isFishing true tapi tidak ada floater, reset...")
		isFishing = false
	end

	if isThrowing or isPulling then
		warn("Klik diabaikan: Sedang proses lempar/pulling")
		return
	end

	if not currentTool or not currentConfig then return end

	throwFloater()
end

local function onToolEquipped(tool)

	if afkMode == true then

		task.wait(2)
		startAfkLoop()

	end

	cleanupFishing()
	currentTool = tool
	currentConfig = FishingRodConfig.Rods[tool.Name]

	if not currentConfig then
		warn("Config tidak ditemukan untuk:", tool.Name)
		currentTool = nil
		return
	end

	edgePart = findEdgePart(tool)
	if not edgePart then
		warn("Edge part tidak ditemukan di:", tool.Name)
		currentTool = nil
		currentConfig = nil
		return
	end

	updateLineStyle()

	fetchEquippedFloater()

	loadFishingAnimations()
	if idleAnimation then
		idleAnimation:Play()
	end

	notifyReplication("NotifyStartFishing", tool.Name, equippedFloaterId)

end

local function onToolUnequipped()

	if isPulling then
		isPulling = false
		pullingStarted = false

		if pullFrame then
			pullFrame.Visible = false
		end

		stopPullCamera()

		task.delay(0.1, function()
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = Character and Character:FindFirstChild("Humanoid") or nil
		end)

		if Humanoid then
			Humanoid.WalkSpeed = 16
			Humanoid.JumpPower = 50
		end

		if pullingAnimation and pullingAnimation.IsPlaying then
			pullingAnimation:Stop()
		end
	end

	if isFishing then
		retrieveFloater()
	end

	cleanupAnimations()

	currentTool = nil
	currentConfig = nil
	edgePart = nil
	isFishing = false
	isPulling = false
	isThrowing = false
	isFloating = false

	if Humanoid then
		Humanoid.WalkSpeed = 16
		Humanoid.JumpPower = 50
	end
end

local function setupCharacterMonitor()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	HRP = Character:WaitForChild("HumanoidRootPart")

	Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			if FishingRodConfig.Rods[child.Name] then
				onToolEquipped(child)
			end
		end
	end)

	Character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == currentTool then
			onToolUnequipped()
		end
	end)

	for _, child in ipairs(Character:GetChildren()) do
		if child:IsA("Tool") and FishingRodConfig.Rods[child.Name] then
			onToolEquipped(child)
			break
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		onMouseClick()
	end
end)

Player.CharacterAdded:Connect(function(newCharacter)

	Character = newCharacter
	HRP = newCharacter:WaitForChild("HumanoidRootPart", 5)
	Humanoid = newCharacter:WaitForChild("Humanoid", 5)

	if bobConnection then
		pcall(function() bobConnection:Disconnect() end)
		bobConnection = nil
	end
	if beamUpdateConnection then
		pcall(function() beamUpdateConnection:Disconnect() end)
		beamUpdateConnection = nil
	end
	if pullConnection then
		pcall(function() pullConnection:Disconnect() end)
		pullConnection = nil
	end

	cleanupFishing()
	cleanupAnimations()

	stopPullCamera()
	task.delay(0.2, function()
		camera.CameraType = Enum.CameraType.Custom
		if newCharacter:FindFirstChild("Humanoid") then
			camera.CameraSubject = newCharacter.Humanoid
		end
	end)

	if pullFrame then
		pullFrame.Visible = false
	end

	isFishing = false
	isThrowing = false
	isFloating = false
	isPulling = false
	pullingStarted = false
	distanceWarned = false
	floaterInWater = false

	currentTool = nil
	currentConfig = nil
	edgePart = nil
	currentFloater = nil

	throwAnimation = nil
	idleAnimation = nil
	pullingAnimation = nil
	catchAnimation = nil
	animator = nil

	pullTimerElapsed = 0
	pullAutoTimer = 0

	notifyReplication("NotifyStopFishing")

	task.delay(0.5, function()
		if Humanoid then
			Humanoid.WalkSpeed = 16
			Humanoid.JumpPower = 50
		end
	end)

	setupCharacterMonitor()

end)

setupCharacterMonitor()

local function checkAnyUIOpen()
	local playerGui = player.PlayerGui

	local uiChecks = {

		{gui = "EquipmentGUI", panel = "MainPanel"},
		{gui = "FishCollectionGUI", panel = "MainPanel"},
		{gui = "FishermanShopGUI", panel = "ShopPanel"},
		{gui = "RodShopGUI", panel = "MainPanel"},

		{gui = "InventoryGUI", panel = "MainPanel"},
		{gui = "InventoryGUI_V3", panel = "MainPanel"},
		{gui = "InventorySystemGUI", panel = "MainPanel"},

		{gui = "SettingsGUI", panel = "MainPanel"},

		{gui = "RedeemGui", panel = "MainPanel"},
		{gui = "DonateGUI", panel = "MainPanel"},
		{gui = "DonateGui", panel = "MainPanel"},
		{gui = "Shop", panel = "MainPanel"},
		{gui = "ShopGUI", panel = "MainPanel"},

	}

	for _, check in ipairs(uiChecks) do
		local ui = playerGui:FindFirstChild(check.gui)
		if ui then

			local panel = ui:FindFirstChild(check.panel)
			if panel and panel:IsA("GuiObject") and panel.Visible then

				return true
			end
		end
	end

	return false
end

task.spawn(function()
	while true do
		isAnyUIOpen = checkAnyUIOpen()
		task.wait(0.2)
	end
end)

local function closeAllUIsOnFishCaught()

	local playerGui = player.PlayerGui
	local closedCount = 0

	local uisToClose = {
		{gui = "EquipmentGUI", panel = "MainPanel"},
		{gui = "FishCollectionGUI", panel = "MainPanel"},
		{gui = "FishermanShopGUI", panel = "ShopPanel"},
		{gui = "RodShopGUI", panel = "MainPanel"},
		{gui = "InventoryGUI", panel = "MainPanel"},

		{gui = "RedeemGui", panel = "MainPanel", disableGui = true},
		{gui = "DonateGUI", panel = "MainPanel", disableGui = true},
		{gui = "ShopGUI", panel = "MainPanel", disableGui = true},

		{gui = "MusicPlayer", panel = "MainPanel"},
		{gui = "MusicPlayer", panel = "MyLibraryPanel"},
		{gui = "MusicPlayer", panel = "PlaylistPopupPanel"},
	}

	for _, uiInfo in ipairs(uisToClose) do
		local gui = playerGui:FindFirstChild(uiInfo.gui)
		if gui then
			local panel = gui:FindFirstChild(uiInfo.panel)
			if panel then
				if panel:IsA("GuiObject") then
					if panel.Visible then
						panel.Visible = false

						if uiInfo.disableGui and gui:IsA("ScreenGui") then
							gui.Enabled = false
						end
						closedCount = closedCount + 1
					else
					end
				end
			else
			end
		end
	end

	local IconModule = ReplicatedStorage:FindFirstChild("Icon")
	if IconModule then
		local success, iconLib = pcall(function()
			return require(IconModule)
		end)

		if success and iconLib and iconLib.getIcons then
			local getIconsSuccess, icons = pcall(function()
				return iconLib.getIcons()
			end)

			if getIconsSuccess and icons then
				for _, icon in pairs(icons) do

					local isSelected = false
					pcall(function()
						if type(icon.isSelected) == "function" then
							isSelected = icon:isSelected()
						elseif type(icon.isSelected) == "boolean" then
							isSelected = icon.isSelected
						end
					end)

					if isSelected and icon.deselect then
						pcall(function()
							icon:deselect()
							closedCount = closedCount + 1
						end)
					end
				end
			end
		end
	end

end

_G.closeAllUIsOnFishCaught = closeAllUIsOnFishCaught

local FishCaughtEvent = ReplicatedStorage:FindFirstChild("FishCaughtEvent")

if FishCaughtEvent then
	FishCaughtEvent.OnClientEvent:Connect(function(data)
		if data and data.IsNewDiscovery then
			isNewFishUIVisible = true
			lastNewFishTime = tick()
		end
		closeAllUIsOnFishCaught()
	end)
else

	task.spawn(function()
		local event = ReplicatedStorage:WaitForChild("FishCaughtEvent", 10)
		if event then
			event.OnClientEvent:Connect(function(data)
				if data and data.IsNewDiscovery then
					isNewFishUIVisible = true
					lastNewFishTime = tick()
				end
				closeAllUIsOnFishCaught()
			end)
		else
			warn("[FISHING] FishCaughtEvent not found after 10s!")
		end
	end)
end

local playerGui = Player.PlayerGui

local isCinematicMode = false
local hiddenGuis = {}
local originalCoreGuiState = {}

local cinematicGui = Instance.new("ScreenGui")
cinematicGui.Name = "CameraCinematicGUI"
cinematicGui.ResetOnSpawn = false
cinematicGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
cinematicGui.DisplayOrder = 100
cinematicGui.Parent = playerGui

local hudGuiCinematic = playerGui:FindFirstChild("HUD")
local rightFrame = hudGuiCinematic and hudGuiCinematic:FindFirstChild("Right")
local cinematicButtonTemplate = rightFrame and rightFrame:FindFirstChild("ButtonTemplate")

local cinematicButton = nil
local cinematicButtonText = nil

if cinematicButtonTemplate then
	local buttonContainer = cinematicButtonTemplate:Clone()
	buttonContainer.Name = "PhotoButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 3
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = rightFrame

	cinematicButton = buttonContainer:FindFirstChild("ImageButton")
	cinematicButtonText = buttonContainer:FindFirstChild("TextLabel")

	if cinematicButton then
		cinematicButton.Image = "rbxassetid://139242732181104"
		cinematicButton.BackgroundTransparency = 1
	end

	if cinematicButtonText then
		cinematicButtonText.Text = "Photo"
	end
end

local cinematicModeIndicator = Instance.new("TextLabel")
cinematicModeIndicator.Name = "ModeIndicator"
cinematicModeIndicator.Size = UDim2.new(0.3, 0, 0.05, 0)
cinematicModeIndicator.Position = UDim2.new(0.5, 0, 0.02, 0)
cinematicModeIndicator.AnchorPoint = Vector2.new(0.5, 0)
cinematicModeIndicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cinematicModeIndicator.BackgroundTransparency = 0.5
cinematicModeIndicator.Font = Enum.Font.GothamBold
cinematicModeIndicator.Text = "📷 PHOTO MODE - Click button again to exit"
cinematicModeIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
cinematicModeIndicator.TextScaled = true
cinematicModeIndicator.Visible = false
cinematicModeIndicator.Parent = cinematicGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(0, 8)
indicatorCorner.Parent = cinematicModeIndicator

local cinematicCoreGuiTypes = {
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.EmotesMenu,
}

local StarterGui = game:GetService("StarterGui")

local function hideAllUIForPhoto()
	hiddenGuis = {}

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui ~= cinematicGui then
			if gui.Enabled then
				table.insert(hiddenGuis, gui)
				gui.Enabled = false
			end
		end
	end

	originalCoreGuiState = {}
	for _, coreType in ipairs(cinematicCoreGuiTypes) do
		local success, enabled = pcall(function()
			return StarterGui:GetCoreGuiEnabled(coreType)
		end)
		if success then
			originalCoreGuiState[coreType] = enabled
			if enabled then
				pcall(function()
					StarterGui:SetCoreGuiEnabled(coreType, false)
				end)
			end
		end
	end
end

local function showAllUIAfterPhoto()
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then
			gui.Enabled = true
		end
	end
	hiddenGuis = {}

	for coreType, wasEnabled in pairs(originalCoreGuiState) do
		if wasEnabled then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(coreType, true)
			end)
		end
	end
	originalCoreGuiState = {}
end

local function toggleCinematicMode()
	isCinematicMode = not isCinematicMode

	if isCinematicMode then
		hideAllUIForPhoto()
		cinematicModeIndicator.Visible = true
		if cinematicButton then
			cinematicButton.ImageColor3 = Color3.fromRGB(100, 255, 100)
		end
		if cinematicButtonText then
			cinematicButtonText.TextColor3 = Color3.fromRGB(100, 255, 100)
		end

		task.delay(3, function()
			if isCinematicMode then
				TweenService:Create(cinematicModeIndicator, TweenInfo.new(0.5), {
					BackgroundTransparency = 1,
					TextTransparency = 1
				}):Play()
			end
		end)
	else
		showAllUIAfterPhoto()
		cinematicModeIndicator.Visible = false
		cinematicModeIndicator.BackgroundTransparency = 0.5
		cinematicModeIndicator.TextTransparency = 0
		if cinematicButton then
			cinematicButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
		if cinematicButtonText then
			cinematicButtonText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

if cinematicButton then
	cinematicButton.MouseButton1Click:Connect(toggleCinematicMode)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.P then
		toggleCinematicMode()
	end

	if input.KeyCode == Enum.KeyCode.Escape and isCinematicMode then
		toggleCinematicMode()
	end
end)

Player.CharacterAdded:Connect(function()
	if isCinematicMode then
		isCinematicMode = false
		showAllUIAfterPhoto()
		cinematicModeIndicator.Visible = false
		if cinematicButton then
			cinematicButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
		if cinematicButtonText then
			cinematicButtonText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end)

local FishDiscoveryColors = {
	Background = Color3.fromRGB(18, 18, 22),
	CardBg = Color3.fromRGB(28, 28, 35),
	Success = Color3.fromRGB(67, 181, 129),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(163, 166, 183),
	Common = Color3.fromRGB(163, 166, 183),
	Uncommon = Color3.fromRGB(67, 181, 129),
	Rare = Color3.fromRGB(88, 166, 255),
	Epic = Color3.fromRGB(163, 108, 229),
	Legendary = Color3.fromRGB(255, 193, 7)
}

local function showSimpleFishNotification(fishData, quantity)
	local notifGui = Instance.new("ScreenGui")
	notifGui.Name = "SimpleFishNotif"
	notifGui.ResetOnSpawn = false
	notifGui.DisplayOrder = 100
	notifGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 70)
	frame.Position = UDim2.new(1, 10, 0, 20)
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BackgroundColor3 = FishDiscoveryColors.CardBg
	frame.BorderSizePixel = 0
	frame.Parent = notifGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = FishDiscoveryColors[fishData.Rarity] or FishDiscoveryColors.Common
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = frame

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 50, 0, 50)
	iconBg.Position = UDim2.new(0, 10, 0.5, 0)
	iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = FishDiscoveryColors.Background
	iconBg.BorderSizePixel = 0
	iconBg.Parent = frame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconBg

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = fishData.ImageID or ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = iconBg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -75, 1, 0)
	label.Position = UDim2.new(0, 70, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s x%d", fishData.Name, quantity)
	label.TextSize = 15
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = FishDiscoveryColors.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -330, 0, 20)})
	tweenIn:Play()

	task.wait(3)

	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(1, 10, 0, 20)})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	notifGui:Destroy()
end

local function showNewDiscoveryBanner(fishID, fishData, quantity)
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "NewFishDiscovery"
	bannerGui.ResetOnSpawn = false
	bannerGui.DisplayOrder = 1000
	bannerGui.IgnoreGuiInset = true
	bannerGui.Parent = playerGui

	local rarityColor = FishDiscoveryColors[fishData.Rarity] or FishDiscoveryColors.Common
	local rarityText = fishData.Rarity:upper()

	local rarityGlow = {
		Common = Color3.fromRGB(200, 200, 210),
		Uncommon = Color3.fromRGB(100, 220, 160),
		Rare = Color3.fromRGB(120, 180, 255),
		Epic = Color3.fromRGB(180, 130, 255),
		Legendary = Color3.fromRGB(255, 215, 50)
	}
	local glowColor = rarityGlow[fishData.Rarity] or rarityGlow.Common

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Parent = bannerGui

	local raysContainer = Instance.new("Frame")
	raysContainer.Size = UDim2.new(2, 0, 2, 0)
	raysContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	raysContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	raysContainer.BackgroundTransparency = 1
	raysContainer.Parent = bannerGui
	raysContainer.ClipsDescendants = false

	local numRays = 12
	for i = 1, numRays do
		local ray = Instance.new("Frame")
		ray.Size = UDim2.new(0.02, 0, 1.5, 0)
		ray.Position = UDim2.new(0.5, 0, 0.5, 0)
		ray.AnchorPoint = Vector2.new(0.5, 1)
		ray.Rotation = (i - 1) * (360 / numRays)
		ray.BackgroundTransparency = 0.85
		ray.BorderSizePixel = 0
		ray.Parent = raysContainer

		local rayGradient = Instance.new("UIGradient")
		rayGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, glowColor),
			ColorSequenceKeypoint.new(1, glowColor)
		})
		rayGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.7),
			NumberSequenceKeypoint.new(1, 0)
		})
		rayGradient.Rotation = 90
		rayGradient.Parent = ray
	end

	task.spawn(function()
		local rotation = 0
		while raysContainer.Parent do
			rotation = rotation + 0.3
			raysContainer.Rotation = rotation
			task.wait(0.016)
		end
	end)

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.5, 0, 0.42, 0)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = bannerGui
	card.Visible = false

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1.6
	aspectRatio.Parent = card

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(420, 260)
	sizeConstraint.MaxSize = Vector2.new(700, 440)
	sizeConstraint.Parent = card

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 20)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = glowColor
	cardStroke.Thickness = 3
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	local innerGlow = Instance.new("Frame")
	innerGlow.Size = UDim2.new(1, 0, 1, 0)
	innerGlow.BackgroundTransparency = 1
	innerGlow.BorderSizePixel = 0
	innerGlow.Parent = card

	local innerGlowGradient = Instance.new("UIGradient")
	innerGlowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, glowColor),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, glowColor)
	})
	innerGlowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(0.5, 0.98),
		NumberSequenceKeypoint.new(1, 0.95)
	})
	innerGlowGradient.Rotation = 45
	innerGlowGradient.Parent = innerGlow

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0.3, 0, 1.5, 0)
	shine.Position = UDim2.new(-0.3, 0, -0.25, 0)
	shine.Rotation = 25
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.ZIndex = 10
	shine.Parent = card

	local shineGradient = Instance.new("UIGradient")
	shineGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.85),
		NumberSequenceKeypoint.new(0.6, 0.85),
		NumberSequenceKeypoint.new(1, 1)
	})
	shineGradient.Parent = shine

	local visualContainer = Instance.new("Frame")
	visualContainer.Size = UDim2.new(0.45, 0, 1, 0)
	visualContainer.BackgroundTransparency = 1
	visualContainer.Parent = card

	local fishGlow = Instance.new("Frame")
	fishGlow.Size = UDim2.new(0.85, 0, 0.85, 0)
	fishGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	fishGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	fishGlow.BackgroundColor3 = glowColor
	fishGlow.BackgroundTransparency = 0.85
	fishGlow.BorderSizePixel = 0
	fishGlow.Parent = visualContainer

	local fishGlowCorner = Instance.new("UICorner")
	fishGlowCorner.CornerRadius = UDim.new(1, 0)
	fishGlowCorner.Parent = fishGlow

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1.2, 0, 1.2, 0)
	viewport.Position = UDim2.new(0.5, 0, 0.5, 0)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(180, 180, 180)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -0.5)
	viewport.Parent = visualContainer

	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(0.55, 0, 1, 0)
	infoContainer.Position = UDim2.new(0.45, 0, 0, 0)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = card

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingTop = UDim.new(0, 25)
	infoPadding.PaddingBottom = UDim.new(0, 25)
	infoPadding.PaddingRight = UDim.new(0, 25)
	infoPadding.PaddingLeft = UDim.new(0, 10)
	infoPadding.Parent = infoContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Parent = infoContainer

	local headerContainer = Instance.new("Frame")
	headerContainer.Size = UDim2.new(1, 0, 0, 26)
	headerContainer.BackgroundTransparency = 1
	headerContainer.LayoutOrder = 1
	headerContainer.Parent = infoContainer

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Text = "⭐ NEW DISCOVERY ⭐"
	headerLabel.Size = UDim2.new(1, 0, 1, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextSize = 16
	headerLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = headerContainer

	task.spawn(function()
		local brightness = 0
		local direction = 1
		while headerLabel.Parent do
			brightness = brightness + direction * 0.05
			if brightness >= 1 then direction = -1 end
			if brightness <= 0 then direction = 1 end
			local glow = math.floor(200 + 55 * brightness)
			headerLabel.TextColor3 = Color3.fromRGB(255, glow, 80 + math.floor(20 * brightness))
			task.wait(0.03)
		end
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = fishData.Name
	nameLabel.Size = UDim2.new(1, 0, 0, 50)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = 32
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = infoContainer

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 1.5
	nameStroke.Transparency = 0.5
	nameStroke.Parent = nameLabel

	local badgesContainer = Instance.new("Frame")
	badgesContainer.Size = UDim2.new(1, 0, 0, 32)
	badgesContainer.BackgroundTransparency = 1
	badgesContainer.LayoutOrder = 3
	badgesContainer.Parent = infoContainer

	local badgesLayout = Instance.new("UIListLayout")
	badgesLayout.FillDirection = Enum.FillDirection.Horizontal
	badgesLayout.Padding = UDim.new(0, 12)
	badgesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgesLayout.Parent = badgesContainer

	local rarityBadge = Instance.new("Frame")
	rarityBadge.BackgroundColor3 = rarityColor
	rarityBadge.Size = UDim2.new(0, 95, 1, 0)
	rarityBadge.Parent = badgesContainer

	local rarityBadgeCorner = Instance.new("UICorner")
	rarityBadgeCorner.CornerRadius = UDim.new(0.3, 0)
	rarityBadgeCorner.Parent = rarityBadge

	local rarityBadgeGradient = Instance.new("UIGradient")
	rarityBadgeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	rarityBadgeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 0.7)
	})
	rarityBadgeGradient.Rotation = 90
	rarityBadgeGradient.Parent = rarityBadge

	local rarityTextLabel = Instance.new("TextLabel")
	rarityTextLabel.Size = UDim2.new(1, 0, 1, 0)
	rarityTextLabel.BackgroundTransparency = 1
	rarityTextLabel.Text = "✦ " .. rarityText
	rarityTextLabel.Font = Enum.Font.GothamBlack
	rarityTextLabel.TextSize = 13
	rarityTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityTextLabel.Parent = rarityBadge

	local rarityTextStroke = Instance.new("UIStroke")
	rarityTextStroke.Color = Color3.fromRGB(0, 0, 0)
	rarityTextStroke.Thickness = 1
	rarityTextStroke.Transparency = 0.5
	rarityTextStroke.Parent = rarityTextLabel

	local priceTag = Instance.new("Frame")
	priceTag.Size = UDim2.new(0, 100, 1, 0)
	priceTag.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
	priceTag.Parent = badgesContainer

	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0.3, 0)
	priceCorner.Parent = priceTag

	local priceText = Instance.new("TextLabel")
	priceText.Size = UDim2.new(1, 0, 1, 0)
	priceText.BackgroundTransparency = 1
	priceText.Text = "💰 $" .. tostring(fishData.Price or 0)
	priceText.Font = Enum.Font.GothamBold
	priceText.TextSize = 15
	priceText.TextColor3 = Color3.fromRGB(100, 220, 150)
	priceText.Parent = priceTag

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Text = "🎣 TAP ANYWHERE TO CONTINUE"
	hintLabel.Size = UDim2.new(1, 0, 0, 22)
	hintLabel.Position = UDim2.new(0.5, 0, 0.93, 0)
	hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextSize = 12
	hintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	hintLabel.TextTransparency = 0.3
	hintLabel.Parent = card

	task.spawn(function()
		while hintLabel.Parent do
			TweenService:Create(hintLabel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextTransparency = 0.6}):Play()
			task.wait(0.8)
			TweenService:Create(hintLabel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextTransparency = 0.2}):Play()
			task.wait(0.8)
		end
	end)

	local FishModelsFolder = ReplicatedStorage:FindFirstChild("FishModels")
		or (ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("Fish"))
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FishModels"))
		or workspace:FindFirstChild("FishModels")

	if FishModelsFolder then
		local fishModel = FishModelsFolder:FindFirstChild(fishID)
		if fishModel then
			local worldModel = Instance.new("WorldModel")
			worldModel.Parent = viewport

			local clonedModel = fishModel:Clone()
			clonedModel.Parent = worldModel

			if clonedModel:IsA("Model") then
				clonedModel:PivotTo(CFrame.new(0, 0, 0))
			elseif clonedModel:IsA("BasePart") then
				clonedModel.CFrame = CFrame.new(0, 0, 0)
			end

			local modelSize = clonedModel:GetExtentsSize()
			local maxDim = math.max(modelSize.X, modelSize.Y, modelSize.Z)

			local fov = 60
			local fillFactor = 1.2
			local distance = (maxDim / 2) / math.tan(math.rad(fov / 2)) * fillFactor

			local cam = Instance.new("Camera")
			cam.FieldOfView = fov

			local angle = math.rad(25)
			local camX = distance * math.cos(angle) * 0.85
			local camY = maxDim * 0.1
			local camZ = distance * math.sin(angle) * 0.85 + distance * 0.4

			cam.CFrame = CFrame.new(Vector3.new(camX, camY, camZ), Vector3.new(0, 0, 0))
			cam.Parent = viewport
			viewport.CurrentCamera = cam

			task.spawn(function()
				while viewport.Parent do
					if clonedModel and clonedModel.Parent then
						local currentCF = clonedModel:GetPivot()
						clonedModel:PivotTo(currentCF * CFrame.Angles(0, math.rad(0.6), 0))
					end
					task.wait(0.016)
				end
			end)
		end
	end

	TweenService:Create(backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.5}):Play()

	card.Size = UDim2.new(0, 0, 0, 0)
	card.Visible = true

	local popTween = TweenService:Create(card,
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0.5, 0, 0.42, 0)}
	)
	popTween:Play()

	task.delay(0.5, function()
		if shine.Parent then
			TweenService:Create(shine, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = UDim2.new(1.1, 0, -0.25, 0)}):Play()
		end
	end)

	task.spawn(function()
		local pulseDir = 1
		local transparency = 0.3
		while cardStroke.Parent do
			transparency = transparency + pulseDir * 0.02
			if transparency >= 0.5 then pulseDir = -1 end
			if transparency <= 0.1 then pulseDir = 1 end
			cardStroke.Transparency = transparency
			task.wait(0.03)
		end
	end)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(1, 0, 1, 0)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = ""
	closeButton.ZIndex = 100
	closeButton.Parent = bannerGui

	local closing = false
	closeButton.MouseButton1Click:Connect(function()
		if closing then return end
		closing = true

		TweenService:Create(backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		TweenService:Create(raysContainer, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()

		local closeTween = TweenService:Create(card,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		closeTween:Play()

		closeTween.Completed:Wait()
		bannerGui:Destroy()
	end)
end

local FishCaughtEventForDiscovery = ReplicatedStorage:FindFirstChild("FishCaughtEvent")
if not FishCaughtEventForDiscovery then
	FishCaughtEventForDiscovery = ReplicatedStorage:WaitForChild("FishCaughtEvent", 10)
end

if FishCaughtEventForDiscovery then
	FishCaughtEventForDiscovery.OnClientEvent:Connect(function(data)

		if data.IsNewDiscovery then
			showNewDiscoveryBanner(data.FishID, data.FishData, data.Quantity)
		else
			showSimpleFishNotification(data.FishData, data.Quantity)
		end
	end)
else
	warn("⚠️ [FISH DISCOVERY] FishCaughtEvent not found!")
end

local FishingRemotes = ReplicatedStorage:WaitForChild("FishingRemotes", 5)
if FishingRemotes then
	local PlayerThrewFloaterEvent = FishingRemotes:FindFirstChild("PlayerThrewFloater")
	local PlayerStartedPullingEvent = FishingRemotes:FindFirstChild("PlayerStartedPulling")
	local PlayerStoppedFishingEvent = FishingRemotes:FindFirstChild("PlayerStoppedFishing")

	local otherPlayersFishing = {}

	local function cleanupPlayerFishing(targetPlayer)
		local data = otherPlayersFishing[targetPlayer]
		if not data then return end

		if data.floater then
			pcall(function() data.floater:Destroy() end)
		end
		if data.lineConnection then
			pcall(function() data.lineConnection:Disconnect() end)
		end
		if data.middlePoints then
			for _, point in ipairs(data.middlePoints) do
				pcall(function() point:Destroy() end)
			end
		end
		if data.beamSegments then
			for _, beam in ipairs(data.beamSegments) do
				pcall(function() beam:Destroy() end)
			end
		end
		if data.attachment0 then
			pcall(function() data.attachment0:Destroy() end)
		end
		if data.attachment1 then
			pcall(function() data.attachment1:Destroy() end)
		end

		otherPlayersFishing[targetPlayer] = nil
	end

	if PlayerThrewFloaterEvent then
		PlayerThrewFloaterEvent.OnClientEvent:Connect(function(sourcePlayer, eventData)
			if sourcePlayer == player then return end

			cleanupPlayerFishing(sourcePlayer)

			local targetPos = eventData.TargetPos
			if not targetPos then return end

			local floaterTemplate = FloatersFolder:FindFirstChild(eventData.FloaterId or "Floater_Doll")
			if floaterTemplate then
				local floater = floaterTemplate:Clone()
				floater.Name = "ReplicatedFloater_" .. sourcePlayer.Name

				if floater:IsA("Model") then
					for _, part in ipairs(floater:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Anchored = true
							part.CanCollide = false
						end
					end
					floater.PrimaryPart = floater:FindFirstChildWhichIsA("BasePart")
					if floater.PrimaryPart then
						floater:SetPrimaryPartCFrame(CFrame.new(targetPos))
					end
				else
					floater.Anchored = true
					floater.CanCollide = false
					floater.CFrame = CFrame.new(targetPos)
				end

				floater.Parent = workspace

				otherPlayersFishing[sourcePlayer] = {
					floater = floater,
					targetPos = targetPos
				}
			end
		end)
	end

	if PlayerStoppedFishingEvent then
		PlayerStoppedFishingEvent.OnClientEvent:Connect(function(sourcePlayer, eventData)
			cleanupPlayerFishing(sourcePlayer)
		end)
	end

	Players.PlayerRemoving:Connect(function(leavingPlayer)
		cleanupPlayerFishing(leavingPlayer)
	end)

end
