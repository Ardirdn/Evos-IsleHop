--[[
	BoatController.server.lua
	
	CENTRALIZED boat access control service.
	
	PENTING: JANGAN taruh script di dalam boat!
	Script ini akan OTOMATIS mendeteksi semua boat di:
	- Workspace > Boats (folder)
	
	Features:
	1. Title-based access control
	2. Throw unauthorized players
	3. Notification + open shop gamepass tab
	4. Auto-reset boat position after 5 seconds
	5. Monitor title equip/unequip while seated
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(script.Parent.DataHandler)
local TitleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TitleConfig"))

print("[BOAT CONTROLLER] Starting...")
print("[BOAT CONTROLLER] TitleConfig.AccessRules:", TitleConfig.AccessRules)
print("[BOAT CONTROLLER] BoatAccess titles:", TitleConfig.AccessRules and TitleConfig.AccessRules["BoatAccess"])

local boatRemotes = ReplicatedStorage:FindFirstChild("BoatRemotes")
if not boatRemotes then
	boatRemotes = Instance.new("Folder")
	boatRemotes.Name = "BoatRemotes"
	boatRemotes.Parent = ReplicatedStorage
end

local openShopGamepassEvent = boatRemotes:FindFirstChild("OpenShopGamepassTab")
if not openShopGamepassEvent then
	openShopGamepassEvent = Instance.new("RemoteEvent")
	openShopGamepassEvent.Name = "OpenShopGamepassTab"
	openShopGamepassEvent.Parent = boatRemotes
end

local notificationComm = ReplicatedStorage:FindFirstChild("NotificationComm")
local showNotificationEvent = notificationComm and notificationComm:FindFirstChild("ShowNotification")

local titleRemotes = ReplicatedStorage:FindFirstChild("TitleRemotes")
local equipTitleEvent = titleRemotes and titleRemotes:FindFirstChild("EquipTitle")
local unequipTitleEvent = titleRemotes and titleRemotes:FindFirstChild("UnequipTitle")

local boatInitialPositions = {}
local boatResetTimers = {}
local boatConnections = {}

local RESET_DELAY = 5
local THROW_DISTANCE = 5
local THROW_HEIGHT = 3

local function hasBoatAccess(player)
	print("[BOAT ACCESS] Checking access for:", player.Name)
	
	if not player or not player.Parent then
		print("[BOAT ACCESS] Player invalid or left")
		return false
	end
	
	local allowedTitles = TitleConfig.AccessRules and TitleConfig.AccessRules["BoatAccess"]
	print("[BOAT ACCESS] Allowed titles:", allowedTitles)
	
	if not allowedTitles then
		print("[BOAT ACCESS] No BoatAccess rule found, allowing everyone")
		return true
	end
	
	local data = DataHandler:GetData(player)
	print("[BOAT ACCESS] Player data:", data)
	
	if not data then
		print("[BOAT ACCESS] No data found for player, denying access")
		return false
	end
	
	local playerTitle = data.EquippedTitle or data.Title or "Pengunjung"
	print("[BOAT ACCESS] Player title:", playerTitle)
	print("[BOAT ACCESS] EquippedTitle:", data.EquippedTitle)
	print("[BOAT ACCESS] Title:", data.Title)
	
	for _, title in ipairs(allowedTitles) do
		if playerTitle == title then
			print("[BOAT ACCESS] ✅ Access GRANTED - Title matches:", title)
			return true
		end
	end
	
	print("[BOAT ACCESS] ❌ Access DENIED - Title not in allowed list")
	return false
end

local function sendNotification(player, message, notifType, icon)
	if showNotificationEvent and player and player.Parent then
		pcall(function()
			showNotificationEvent:FireClient(player, {
				Message = message,
				Type = notifType or "error",
				Duration = 5,
				Icon = icon or "⛵"
			})
		end)
	end
end

local function throwPlayer(player, seat)
	print("[BOAT] Throwing player:", player.Name)
	
	if not player or not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then
		return
	end
	
	-- Save throw direction BEFORE unseating (while still on boat)
	local throwDirection = rootPart.CFrame.LookVector
	local throwStartPos = rootPart.Position
	
	-- STEP 1: Find and destroy the SeatWeld to break connection
	local seatWeld = nil
	
	-- Look for weld in character
	for _, obj in ipairs(player.Character:GetDescendants()) do
		if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
			if obj.Name == "SeatWeld" then
				seatWeld = obj
				break
			end
		end
	end
	
	-- Also check the seat itself
	if not seatWeld and seat then
		for _, obj in ipairs(seat:GetChildren()) do
			if (obj:IsA("Weld") or obj:IsA("WeldConstraint")) and obj.Name == "SeatWeld" then
				seatWeld = obj
				break
			end
		end
	end
	
	-- Destroy the weld if found
	if seatWeld then
		print("[BOAT] Found and destroying SeatWeld")
		seatWeld:Destroy()
	end
	
	-- STEP 2: Force unseat using multiple methods
	humanoid.Sit = false
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	
	-- Double check and try again
	task.wait()
	if humanoid.SeatPart then
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		
		-- Try destroying weld again if still exists
		for _, obj in ipairs(player.Character:GetDescendants()) do
			if (obj:IsA("Weld") or obj:IsA("WeldConstraint")) and obj.Name == "SeatWeld" then
				obj:Destroy()
			end
		end
	end
	
	print("[BOAT] Forced unseat, SeatWeld destroyed")
	
	-- STEP 3: Send notification and open shop immediately
	sendNotification(player, "🚫 Kamu tidak mempunyai akses ke boat! Beli gamepass untuk akses.", "error", "⛵")
	
	if openShopGamepassEvent and player and player.Parent then
		pcall(function()
			openShopGamepassEvent:FireClient(player)
		end)
	end
	
	-- STEP 4: Wait for physics to update (unseat to take effect)
	task.wait(0.1)
	
	-- STEP 5: Now move and throw the player (after weld is broken)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		
		-- Move player away from boat using saved direction
		local newPosition = throwStartPos + (throwDirection * THROW_DISTANCE) + Vector3.new(0, THROW_HEIGHT, 0)
		hrp.CFrame = CFrame.new(newPosition, newPosition + throwDirection)
		
		-- Apply velocity for throw effect
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = (throwDirection * 30) + Vector3.new(0, 20, 0)
		bv.Parent = hrp
		
		task.delay(0.3, function()
			if bv and bv.Parent then
				bv:Destroy()
			end
		end)
		
		print("[BOAT] Throw completed for:", player.Name)
	end
end

local function saveBoatInitialPosition(boat)
	if boatInitialPositions[boat] then
		return
	end
	
	local primaryPart = boat.PrimaryPart or boat:FindFirstChild("Drive") or boat:FindFirstChild("Body")
	if primaryPart then
		boatInitialPositions[boat] = primaryPart.CFrame
		print("[BOAT] Saved initial position for:", boat.Name)
	end
end

local function resetBoatPosition(boat)
	if not boatInitialPositions[boat] then
		return
	end
	
	local driverSeat = boat:FindFirstChild("Drive")
	local passengerSeat = boat:FindFirstChild("Seat")
	
	if (driverSeat and driverSeat.Occupant) or (passengerSeat and passengerSeat.Occupant) then
		return
	end
	
	print("[BOAT] Resetting position for:", boat.Name)
	
	local primaryPart = boat.PrimaryPart or boat:FindFirstChild("Drive") or boat:FindFirstChild("Body")
	if primaryPart and boat:IsA("Model") then
		local originalCFrame = boatInitialPositions[boat]
		
		if boat.PrimaryPart then
			boat:SetPrimaryPartCFrame(originalCFrame)
		else
			local currentCFrame = primaryPart.CFrame
			local offset = currentCFrame:Inverse() * originalCFrame
			
			for _, part in ipairs(boat:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CFrame = offset * part.CFrame
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end
end

local function startResetTimer(boat)
	if boatResetTimers[boat] then
		task.cancel(boatResetTimers[boat])
		boatResetTimers[boat] = nil
	end
	
	boatResetTimers[boat] = task.delay(RESET_DELAY, function()
		boatResetTimers[boat] = nil
		resetBoatPosition(boat)
	end)
end

local function cancelResetTimer(boat)
	if boatResetTimers[boat] then
		task.cancel(boatResetTimers[boat])
		boatResetTimers[boat] = nil
	end
end

local function onSeatOccupantChanged(seat, boat)
	return function()
		local occupant = seat.Occupant
		print("[BOAT] Occupant changed on", boat.Name, "- Seat:", seat.Name, "- Occupant:", occupant)
		
		if occupant then
			cancelResetTimer(boat)
			
			local player = Players:GetPlayerFromCharacter(occupant.Parent)
			print("[BOAT] Player seated:", player and player.Name or "nil")
			
			if player then
				local hasAccess = hasBoatAccess(player)
				print("[BOAT] Has access:", hasAccess)
				
				if not hasAccess then
					print("[BOAT] Throwing player because no access")
					task.defer(function()
						throwPlayer(player, seat)
					end)
				end
			end
		else
			local driverSeat = boat:FindFirstChild("Drive")
			local passengerSeat = boat:FindFirstChild("Seat")
			
			local driverOccupied = driverSeat and driverSeat.Occupant
			local passengerOccupied = passengerSeat and passengerSeat.Occupant
			
			if not driverOccupied and not passengerOccupied then
				print("[BOAT] Starting reset timer for:", boat.Name)
				startResetTimer(boat)
			end
		end
	end
end

local function setupProximityPrompt(boat)
	local body = boat:FindFirstChild("Body")
	if not body then
		print("[BOAT] No Body found in:", boat.Name)
		return
	end
	
	local prompt = body:FindFirstChild("ProximityPrompt")
	if not prompt then
		print("[BOAT] No ProximityPrompt found in Body of:", boat.Name)
		return
	end
	
	print("[BOAT] Setting up ProximityPrompt for:", boat.Name)
	
	local conn = prompt.Triggered:Connect(function(player)
		print("[BOAT] ProximityPrompt triggered by:", player.Name)
		
		local hasAccess = hasBoatAccess(player)
		print("[BOAT] Has access via prompt:", hasAccess)
		
		if not hasAccess then
			print("[BOAT] Denying boarding via prompt")
			sendNotification(player, "🚫 Kamu tidak mempunyai akses ke boat! Beli gamepass untuk akses.", "error", "⛵")
			
			if openShopGamepassEvent and player and player.Parent then
				pcall(function()
					openShopGamepassEvent:FireClient(player)
				end)
			end
			return
		end
		
		local driverSeat = boat:FindFirstChild("Drive")
		local passengerSeat = boat:FindFirstChild("Seat")
		
		if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
			if driverSeat and not driverSeat.Occupant then
				print("[BOAT] Seating player in Drive")
				driverSeat:Sit(player.Character.Humanoid)
			elseif passengerSeat and not passengerSeat.Occupant then
				print("[BOAT] Seating player in Seat")
				passengerSeat:Sit(player.Character.Humanoid)
			end
		end
	end)
	
	table.insert(boatConnections[boat], conn)
end

local function setupBoat(boat)
	if boatConnections[boat] then
		print("[BOAT] Already setup:", boat.Name)
		return
	end
	
	print("[BOAT] Setting up boat:", boat.Name)
	boatConnections[boat] = {}
	
	saveBoatInitialPosition(boat)
	
	local driverSeat = boat:FindFirstChild("Drive")
	local passengerSeat = boat:FindFirstChild("Seat")
	
	print("[BOAT] Drive seat:", driverSeat and "found" or "not found")
	print("[BOAT] Passenger seat:", passengerSeat and "found" or "not found")
	
	if driverSeat then
		local conn = driverSeat:GetPropertyChangedSignal("Occupant"):Connect(onSeatOccupantChanged(driverSeat, boat))
		table.insert(boatConnections[boat], conn)
		print("[BOAT] Connected Drive occupant listener")
	end
	
	if passengerSeat then
		local conn = passengerSeat:GetPropertyChangedSignal("Occupant"):Connect(onSeatOccupantChanged(passengerSeat, boat))
		table.insert(boatConnections[boat], conn)
		print("[BOAT] Connected Seat occupant listener")
	end
	
	setupProximityPrompt(boat)
	
	local childAddedConn = boat.ChildAdded:Connect(function(child)
		if child.Name == "Drive" or child.Name == "Seat" then
			local conn = child:GetPropertyChangedSignal("Occupant"):Connect(onSeatOccupantChanged(child, boat))
			table.insert(boatConnections[boat], conn)
		elseif child.Name == "Body" then
			setupProximityPrompt(boat)
		end
	end)
	table.insert(boatConnections[boat], childAddedConn)
	
	print("[BOAT] ✅ Setup complete for:", boat.Name)
end

local function cleanupBoat(boat)
	if boatConnections[boat] then
		for _, conn in ipairs(boatConnections[boat]) do
			conn:Disconnect()
		end
		boatConnections[boat] = nil
	end
	
	cancelResetTimer(boat)
	boatInitialPositions[boat] = nil
end

local function checkPlayerInBoatAfterTitleChange(player)
	print("[BOAT] Title changed for:", player.Name, "- checking if in boat")
	
	if not player or not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.SeatPart then
		print("[BOAT] Player not in any seat")
		return
	end
	
	local seat = humanoid.SeatPart
	if not seat then
		return
	end
	
	local boat = seat.Parent
	if not boat then
		return
	end
	
	print("[BOAT] Player is in boat:", boat.Name)
	
	if boat:FindFirstChild("Drive") or boat:FindFirstChild("Seat") then
		local hasAccess = hasBoatAccess(player)
		print("[BOAT] Has access after title change:", hasAccess)
		
		if not hasAccess then
			print("[BOAT] Throwing due to title change")
			task.defer(function()
				throwPlayer(player, seat)
			end)
		end
	end
end

local function initializeBoats()
	local boatsFolder = workspace:FindFirstChild("Boats")
	
	print("[BOAT CONTROLLER] Looking for Boats folder...")
	
	if boatsFolder then
		print("[BOAT CONTROLLER] Found Boats folder with", #boatsFolder:GetChildren(), "children")
		
		for _, boat in ipairs(boatsFolder:GetChildren()) do
			print("[BOAT CONTROLLER] Found child:", boat.Name, "- IsModel:", boat:IsA("Model"))
			if boat:IsA("Model") then
				setupBoat(boat)
			end
		end
		
		boatsFolder.ChildAdded:Connect(function(boat)
			if boat:IsA("Model") then
				task.wait(0.1)
				setupBoat(boat)
			end
		end)
		
		boatsFolder.ChildRemoved:Connect(function(boat)
			cleanupBoat(boat)
		end)
	else
		print("[BOAT CONTROLLER] ⚠️ Boats folder NOT FOUND in Workspace!")
	end
end

print("[BOAT CONTROLLER] Setting up title event listeners...")

if equipTitleEvent then
	print("[BOAT CONTROLLER] EquipTitle event found")
	equipTitleEvent.OnServerEvent:Connect(function(player, titleName)
		print("[BOAT CONTROLLER] EquipTitle fired - Player:", player.Name, "Title:", titleName)
		task.delay(0.3, function()
			checkPlayerInBoatAfterTitleChange(player)
		end)
	end)
else
	print("[BOAT CONTROLLER] ⚠️ EquipTitle event NOT FOUND")
end

if unequipTitleEvent then
	print("[BOAT CONTROLLER] UnequipTitle event found")
	unequipTitleEvent.OnServerEvent:Connect(function(player)
		print("[BOAT CONTROLLER] UnequipTitle fired - Player:", player.Name)
		task.delay(0.3, function()
			checkPlayerInBoatAfterTitleChange(player)
		end)
	end)
else
	print("[BOAT CONTROLLER] ⚠️ UnequipTitle event NOT FOUND")
end

Players.PlayerRemoving:Connect(function(player)
	for boat, _ in pairs(boatInitialPositions) do
		if boat and boat.Parent then
			local driverSeat = boat:FindFirstChild("Drive")
			local passengerSeat = boat:FindFirstChild("Seat")
			
			local hasOtherOccupants = false
			
			if driverSeat and driverSeat.Occupant then
				local occupantPlayer = Players:GetPlayerFromCharacter(driverSeat.Occupant.Parent)
				if occupantPlayer and occupantPlayer ~= player then
					hasOtherOccupants = true
				end
			end
			
			if passengerSeat and passengerSeat.Occupant then
				local occupantPlayer = Players:GetPlayerFromCharacter(passengerSeat.Occupant.Parent)
				if occupantPlayer and occupantPlayer ~= player then
					hasOtherOccupants = true
				end
			end
			
			if not hasOtherOccupants then
				startResetTimer(boat)
			end
		end
	end
end)

task.spawn(function()
	task.wait(2)
	print("[BOAT CONTROLLER] Initializing boats...")
	initializeBoats()
	print("[BOAT CONTROLLER] ✅ Initialization complete")
end)
