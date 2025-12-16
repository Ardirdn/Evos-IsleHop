--[[
    FISH AREA SYSTEM
    Place in ReplicatedStorage/Modules/FishAreaSystem.lua
    
    Sistem untuk mendeteksi apakah posisi berada di dalam Fish Area tertentu
    dan memodifikasi chance ikan berdasarkan area tersebut.
    
    CARA PAKAI:
    1. Di FishingServer, saat mau kasih reward ikan:
       local FishAreaSystem = require(path.to.FishAreaSystem)
       local fishId, fishData = FishAreaSystem.GetRandomFishInArea(floaterPosition)
    
    2. Sistem akan otomatis:
       - Deteksi apakah floater ada di area khusus
       - Modifikasi rarity weights berdasarkan area
       - Tambahkan bonus chance untuk ikan tertentu
       - Return ikan yang sudah dimodifikasi chance-nya
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishAreaSystem = {}

-- Lazy load configs to avoid circular dependencies
local _FishConfig = nil
local _FishAreaConfig = nil

local function getFishConfig()
	if not _FishConfig then
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		_FishConfig = require(Modules:WaitForChild("FishConfig"))
	end
	return _FishConfig
end

local function getFishAreaConfig()
	if not _FishAreaConfig then
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		_FishAreaConfig = require(Modules:WaitForChild("FishAreaConfig"))
	end
	return _FishAreaConfig
end

-- ==================== AREA DETECTION ====================

-- Cache untuk FishArea parts (untuk performa)
local areaCache = {}
local cacheValid = false

-- Rebuild area cache dari workspace
local function rebuildAreaCache()
	areaCache = {}
	
	local fishAreaModel = workspace:FindFirstChild("FishArea")
	if not fishAreaModel then
		warn("[FISH AREA SYSTEM] FishArea model not found in workspace!")
		return
	end
	
	-- Iterate through all area folders
	for _, areaFolder in ipairs(fishAreaModel:GetChildren()) do
		if areaFolder:IsA("Folder") or areaFolder:IsA("Model") then
			local areaName = areaFolder.Name
			areaCache[areaName] = {}
			
			-- Collect all parts in this area folder
			for _, child in ipairs(areaFolder:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(areaCache[areaName], child)
				end
			end
			
			print(string.format("[FISH AREA] Loaded area '%s' with %d zone parts", 
				areaName, #areaCache[areaName]))
		end
	end
	
	cacheValid = true
end

-- Check if position is inside a part (simplified box check)
local function isPositionInPart(position, part)
	-- Convert position to part's local space
	local localPos = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2
	
	-- Check if within bounds
	return math.abs(localPos.X) <= halfSize.X
		and math.abs(localPos.Y) <= halfSize.Y
		and math.abs(localPos.Z) <= halfSize.Z
end

-- Get the area name that contains this position (if any)
function FishAreaSystem.GetAreaAtPosition(position)
	if not cacheValid then
		rebuildAreaCache()
	end
	
	for areaName, areaParts in pairs(areaCache) do
		for _, part in ipairs(areaParts) do
			if isPositionInPart(position, part) then
				return areaName
			end
		end
	end
	
	return nil -- Not in any special area
end

-- Check if position is in a specific area
function FishAreaSystem.IsPositionInArea(position, areaName)
	if not cacheValid then
		rebuildAreaCache()
	end
	
	local areaParts = areaCache[areaName]
	if not areaParts then return false end
	
	for _, part in ipairs(areaParts) do
		if isPositionInPart(position, part) then
			return true
		end
	end
	
	return false
end

-- ==================== FISH SELECTION WITH AREA MODIFIERS ====================

-- Get modified rarity weights based on area
local function getModifiedRarityWeights(areaName)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()
	
	local modifiedWeights = {}
	
	-- Start with base weights
	for rarity, weight in pairs(FishConfig.RarityWeights) do
		modifiedWeights[rarity] = weight
	end
	
	-- Apply area multipliers if in an area
	if areaName then
		local areaConfig = FishAreaConfig.GetAreaConfig(areaName)
		if areaConfig and areaConfig.RarityMultipliers then
			for rarity, multiplier in pairs(areaConfig.RarityMultipliers) do
				if modifiedWeights[rarity] then
					modifiedWeights[rarity] = modifiedWeights[rarity] * multiplier
				end
			end
		end
	end
	
	return modifiedWeights
end

-- Get fish with bonus weights applied
local function getFishPoolWithBonuses(selectedRarity, areaName)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()
	
	local fishPool = {}
	local totalWeight = 0
	
	-- Get all fish of the selected rarity
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then
			-- Base weight of 1 for each fish
			local weight = 1
			
			-- Add bonus weight if in special area
			if areaName then
				local bonus = FishAreaConfig.GetFishChanceBonus(areaName, fishId)
				weight = weight + bonus
			end
			
			-- Check location restriction
			local location = fishData.Location or "Anywhere"
			local canSpawnHere = (location == "Anywhere") 
				or (location == areaName)
				or (selectedRarity == "Common" or selectedRarity == "Uncommon")
			
			if canSpawnHere then
				table.insert(fishPool, {
					fishId = fishId,
					weight = weight
				})
				totalWeight = totalWeight + weight
			end
		end
	end
	
	return fishPool, totalWeight
end

-- Main function: Get random fish considering area modifiers
function FishAreaSystem.GetRandomFishInArea(position)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()
	
	-- Detect if position is in special area
	local areaName = nil
	if position then
		areaName = FishAreaSystem.GetAreaAtPosition(position)
		if areaName then
			print(string.format("[FISH AREA] Fishing in special area: %s", areaName))
		end
	end
	
	-- Get modified rarity weights
	local modifiedWeights = getModifiedRarityWeights(areaName)
	
	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(modifiedWeights) do
		totalWeight = totalWeight + weight
	end
	
	-- Random selection for rarity
	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedRarity = "Common"
	
	for rarity, weight in pairs(modifiedWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end
	
	-- Get fish pool with bonuses applied
	local fishPool, poolWeight = getFishPoolWithBonuses(selectedRarity, areaName)
	
	-- If pool is empty, fallback to any fish of that rarity
	if #fishPool == 0 then
		for fishId, fishData in pairs(FishConfig.Fish) do
			if fishData.Rarity == selectedRarity then
				table.insert(fishPool, { fishId = fishId, weight = 1 })
				poolWeight = poolWeight + 1
			end
		end
	end
	
	-- Still empty? Use first fish
	if #fishPool == 0 then
		local firstFish = next(FishConfig.Fish)
		return firstFish, FishConfig.Fish[firstFish], areaName
	end
	
	-- Weighted random selection from pool
	local poolRandom = math.random() * poolWeight
	local poolCurrent = 0
	local selectedFishId = fishPool[1].fishId
	
	for _, fishEntry in ipairs(fishPool) do
		poolCurrent = poolCurrent + fishEntry.weight
		if poolRandom <= poolCurrent then
			selectedFishId = fishEntry.fishId
			break
		end
	end
	
	return selectedFishId, FishConfig.Fish[selectedFishId], areaName
end

-- ==================== UTILITY FUNCTIONS ====================

-- Force rebuild cache (call if FishArea model changes at runtime)
function FishAreaSystem.RefreshAreaCache()
	cacheValid = false
	rebuildAreaCache()
end

-- Get info about current area at position
function FishAreaSystem.GetAreaInfo(position)
	local FishAreaConfig = getFishAreaConfig()
	
	local areaName = FishAreaSystem.GetAreaAtPosition(position)
	if not areaName then
		return nil
	end
	
	local areaConfig = FishAreaConfig.GetAreaConfig(areaName)
	return {
		Name = areaName,
		DisplayName = areaConfig and areaConfig.DisplayName or areaName,
		Description = areaConfig and areaConfig.Description or "",
		Color = areaConfig and areaConfig.Color or Color3.fromRGB(100, 100, 100)
	}
end

-- Initialize system
task.spawn(function()
	task.wait(1) -- Wait for workspace to be ready
	rebuildAreaCache()
	print("✅ [FISH AREA SYSTEM] Initialized")
end)

-- Watch for changes to FishArea model
task.spawn(function()
	local fishAreaModel = workspace:WaitForChild("FishArea", 30)
	if fishAreaModel then
		fishAreaModel.ChildAdded:Connect(function()
			task.wait(0.5)
			FishAreaSystem.RefreshAreaCache()
		end)
		fishAreaModel.ChildRemoved:Connect(function()
			task.wait(0.5)
			FishAreaSystem.RefreshAreaCache()
		end)
	end
end)

return FishAreaSystem
