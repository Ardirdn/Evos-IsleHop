local FloaterConfig = {}

FloaterConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

FloaterConfig.DefaultFloater = "FloaterDoll"

FloaterConfig.Floaters = {

	["FloaterDoll"] = {
		FloaterId = "FloaterDoll",
		DisplayName = "Doll Floater",
		Description = "Cute doll-shaped floater. Perfect for beginners!",
		Price = 0,
		Category = "Basic",
		Rarity = "Common",
		LuckBonus = 0,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["BoneFloater"] = {
		FloaterId = "BoneFloater",
		DisplayName = "Bone Floater",
		Description = "Skeletal floater crafted from ancient bones. Attracts undead sea creatures!",
		Price = 3000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 30,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["DevilFloater"] = {
		FloaterId = "DevilFloater",
		DisplayName = "Devil Floater",
		Description = "Forged in hellfire, this demonic floater attracts the most sinister catches!",
		Price = 3500,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 35,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["IcedFloater"] = {
		FloaterId = "IcedFloater",
		DisplayName = "Iced Floater",
		Description = "Frozen in eternal ice, perfect for catching arctic creatures!",
		Price = 3000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 30,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["InfernoFloater"] = {
		FloaterId = "InfernoFloater",
		DisplayName = "Inferno Floater",
		Description = "Burns with eternal flames! Fish are drawn to its warmth and light.",
		Price = 4000,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 40,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["KnightFloater"] = {
		FloaterId = "KnightFloater",
		DisplayName = "Knight Floater",
		Description = "Medieval armored floater for honorable fishing! For the realm!",
		Price = 4500,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 45,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["WolfFloater"] = {
		FloaterId = "WolfFloater",
		DisplayName = "Wolf Floater",
		Description = "Hunt your prey with the instincts of a wolf. Howl at the moon!",
		Price = 3500,
		Category = "Epic",
		Rarity = "Epic",
		LuckBonus = 35,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["ReaperFloater"] = {
		FloaterId = "ReaperFloater",
		DisplayName = "Reaper Floater",
		Description = "The ultimate floater. Harvest souls from the deep abyss!",
		Price = 10000,
		Category = "Legendary",
		Rarity = "Legendary",
		LuckBonus = 75,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},
}

function FloaterConfig.GetFloaterById(floaterId)
	return FloaterConfig.Floaters[floaterId]
end

function FloaterConfig.GetFloatersArray()
	local floatersArray = {}
	for floaterId, floaterData in pairs(FloaterConfig.Floaters) do

		local floaterWithId = {}
		for k, v in pairs(floaterData) do
			floaterWithId[k] = v
		end
		floaterWithId.FloaterId = floaterId
		table.insert(floatersArray, floaterWithId)
	end

	table.sort(floatersArray, function(a, b)
		return a.Price < b.Price
	end)

	return floatersArray
end

function FloaterConfig.GetFloatersByCategory(category)
	local result = {}
	for floaterId, floaterData in pairs(FloaterConfig.Floaters) do
		if floaterData.Category == category then
			local floaterWithId = {}
			for k, v in pairs(floaterData) do
				floaterWithId[k] = v
			end
			floaterWithId.FloaterId = floaterId
			table.insert(result, floaterWithId)
		end
	end
	return result
end

function FloaterConfig.GetPrice(floaterId)
	local floater = FloaterConfig.Floaters[floaterId]
	return floater and floater.Price or 0
end

function FloaterConfig.GetLuckBonus(floaterId)
	local floater = FloaterConfig.Floaters[floaterId]
	return floater and floater.LuckBonus or 0
end

function FloaterConfig.Exists(floaterId)
	return FloaterConfig.Floaters[floaterId] ~= nil
end

function FloaterConfig.GetRarityColor(floaterId)
	local floater = FloaterConfig.Floaters[floaterId]
	if floater then
		return FloaterConfig.RarityColors[floater.Rarity] or FloaterConfig.RarityColors.Common
	end
	return FloaterConfig.RarityColors.Common
end

return FloaterConfig
