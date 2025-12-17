local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishAreaSystem = {}

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

local areaCache = {}
local cacheValid = false

local function rebuildAreaCache()
	areaCache = {}

	local fishAreaModel = workspace:FindFirstChild("FishArea")
	if not fishAreaModel then
		warn("[FISH AREA SYSTEM] FishArea model not found in workspace!")
		return
	end

	for _, areaFolder in ipairs(fishAreaModel:GetChildren()) do
		if areaFolder:IsA("Folder") or areaFolder:IsA("Model") then
			local areaName = areaFolder.Name
			areaCache[areaName] = {}

			for _, child in ipairs(areaFolder:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(areaCache[areaName], child)
				end
			end

		end
	end

	cacheValid = true
end

local function isPositionInPart(position, part)

	local localPos = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2

	return math.abs(localPos.X) <= halfSize.X
		and math.abs(localPos.Y) <= halfSize.Y
		and math.abs(localPos.Z) <= halfSize.Z
end

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

	return nil
end

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

local function getModifiedRarityWeights(areaName)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()

	local modifiedWeights = {}

	for rarity, weight in pairs(FishConfig.RarityWeights) do
		modifiedWeights[rarity] = weight
	end

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

local function getFishPoolWithBonuses(selectedRarity, areaName)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()

	local fishPool = {}
	local totalWeight = 0

	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then

			local weight = 1

			if areaName then
				local bonus = FishAreaConfig.GetFishChanceBonus(areaName, fishId)
				weight = weight + bonus
			end

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

function FishAreaSystem.GetRandomFishInArea(position)
	local FishConfig = getFishConfig()
	local FishAreaConfig = getFishAreaConfig()

	local areaName = nil
	if position then
		areaName = FishAreaSystem.GetAreaAtPosition(position)
		if areaName then
		end
	end

	local modifiedWeights = getModifiedRarityWeights(areaName)

	local totalWeight = 0
	for _, weight in pairs(modifiedWeights) do
		totalWeight = totalWeight + weight
	end

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

	local fishPool, poolWeight = getFishPoolWithBonuses(selectedRarity, areaName)

	if #fishPool == 0 then
		for fishId, fishData in pairs(FishConfig.Fish) do
			if fishData.Rarity == selectedRarity then
				table.insert(fishPool, { fishId = fishId, weight = 1 })
				poolWeight = poolWeight + 1
			end
		end
	end

	if #fishPool == 0 then
		local firstFish = next(FishConfig.Fish)
		return firstFish, FishConfig.Fish[firstFish], areaName
	end

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

function FishAreaSystem.RefreshAreaCache()
	cacheValid = false
	rebuildAreaCache()
end

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

task.spawn(function()
	task.wait(1)
	rebuildAreaCache()
end)

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
