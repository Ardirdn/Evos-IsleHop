local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local FishingRodConfig = require(Modules:WaitForChild("FishingRod.config"))
local FloaterConfig = require(Modules:WaitForChild("FloaterConfig"))

local RodShopConfig = {}

RodShopConfig.RarityColors = FishingRodConfig.RarityColors

RodShopConfig.Rods = FishingRodConfig.GetRodsArray()

RodShopConfig.Floaters = FloaterConfig.GetFloatersArray()

function RodShopConfig.GetRodById(rodId)
	local rodData = FishingRodConfig.GetRodById(rodId)
	if rodData then

		local result = {}
		for k, v in pairs(rodData) do
			result[k] = v
		end
		result.RodId = rodId
		return result
	end
	return nil
end

function RodShopConfig.GetFloaterById(floaterId)
	return FloaterConfig.GetFloaterById(floaterId)
end

function RodShopConfig.GetRods()
	return FishingRodConfig.GetRodsArray()
end

function RodShopConfig.GetFloaters()
	return FloaterConfig.GetFloatersArray()
end

function RodShopConfig.GetRodsByCategory(category)
	return FishingRodConfig.GetRodsByCategory(category)
end

function RodShopConfig.GetFloatersByCategory(category)
	return FloaterConfig.GetFloatersByCategory(category)
end

function RodShopConfig.GetRodPrice(rodId)
	return FishingRodConfig.GetPrice(rodId)
end

function RodShopConfig.GetFloaterPrice(floaterId)
	return FloaterConfig.GetPrice(floaterId)
end

function RodShopConfig.GetCatchBonus(rodId)
	return FishingRodConfig.GetCatchBonus(rodId)
end

function RodShopConfig.GetLuckBonus(floaterId)
	return FloaterConfig.GetLuckBonus(floaterId)
end

function RodShopConfig.GetRarityColor(rarity)
	return RodShopConfig.RarityColors[rarity] or RodShopConfig.RarityColors.Common
end

function RodShopConfig.RodExists(rodId)
	return FishingRodConfig.Exists(rodId)
end

function RodShopConfig.FloaterExists(floaterId)
	return FloaterConfig.Exists(floaterId)
end

function RodShopConfig.GetDefaultRod()
	return FishingRodConfig.DefaultRod
end

function RodShopConfig.GetDefaultFloater()
	return FloaterConfig.DefaultFloater
end

RodShopConfig.FishingRodConfig = FishingRodConfig
RodShopConfig.FloaterConfig = FloaterConfig

return RodShopConfig
