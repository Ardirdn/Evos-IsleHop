local FishAreaConfig = {}

FishAreaConfig.DefaultRarityMultipliers = {
	Common = 1,
	Uncommon = 1,
	Rare = 1,
	Epic = 1,
	Legendary = 1
}

FishAreaConfig.Areas = {

	["VolcanoArea"] = {
		DisplayName = "Volcano Waters",
		Description = "Hot volcanic waters where rare fire fish thrive!",
		Color = Color3.fromRGB(255, 100, 50),

		RarityMultipliers = {
			Common = 0.7,
			Uncommon = 0.8,
			Rare = 1.5,
			Epic = 2.0,
			Legendary = 3.0
		},

		FishChanceBonus = {
			["Dragon_Fish"] = 50,
			["Lion_Fish"] = 30,
			["Flying_Fish"] = 20,
			["Mandarin_Fish"] = 25,
		},

		ExclusiveFish = {

		}
	},

	["IceArea"] = {
		DisplayName = "Frozen Waters",
		Description = "Icy cold waters where arctic creatures live!",
		Color = Color3.fromRGB(150, 220, 255),

		RarityMultipliers = {
			Common = 0.8,
			Uncommon = 1.0,
			Rare = 1.3,
			Epic = 1.8,
			Legendary = 2.5
		},

		FishChanceBonus = {
			["Narwehal_Whale"] = 40,
			["Killer_Whale"] = 35,
			["Salmon"] = 20,
			["Coelacanth"] = 30,
		},

		ExclusiveFish = {}
	},

	["DeepSeaArea"] = {
		DisplayName = "Deep Sea Trench",
		Description = "The darkest depths where legendary creatures lurk!",
		Color = Color3.fromRGB(30, 50, 100),

		RarityMultipliers = {
			Common = 0.5,
			Uncommon = 0.6,
			Rare = 2.0,
			Epic = 3.0,
			Legendary = 5.0
		},

		FishChanceBonus = {
			["Angler_Fish"] = 60,
			["Goblin_Shark"] = 50,
			["Oar_Fish"] = 45,
			["Megalodon"] = 40,
			["Bloop"] = 35,
			["Coelacanth"] = 30,
		},

		ExclusiveFish = {}
	},

	["CoralReefArea"] = {
		DisplayName = "Coral Reef",
		Description = "Beautiful coral reef with colorful tropical fish!",
		Color = Color3.fromRGB(255, 150, 200),

		RarityMultipliers = {
			Common = 1.0,
			Uncommon = 1.5,
			Rare = 1.3,
			Epic = 1.5,
			Legendary = 1.2
		},

		FishChanceBonus = {
			["Clown_Fish"] = 50,
			["Blue_Tang"] = 40,
			["Coral_Beauties"] = 35,
			["Moorish_Idol"] = 30,
			["Parrotfish"] = 25,
		},

		ExclusiveFish = {}
	},
}

function FishAreaConfig.GetAreaConfig(areaName)
	return FishAreaConfig.Areas[areaName]
end

function FishAreaConfig.GetAllAreaNames()
	local names = {}
	for name, _ in pairs(FishAreaConfig.Areas) do
		table.insert(names, name)
	end
	return names
end

function FishAreaConfig.IsFishExclusive(fishId)
	for areaName, areaConfig in pairs(FishAreaConfig.Areas) do
		if areaConfig.ExclusiveFish then
			for _, exclusiveFishId in ipairs(areaConfig.ExclusiveFish) do
				if exclusiveFishId == fishId then
					return true, areaName
				end
			end
		end
	end
	return false, nil
end

function FishAreaConfig.GetRarityMultiplier(areaName, rarity)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.RarityMultipliers then
		return areaConfig.RarityMultipliers[rarity] or 1
	end
	return 1
end

function FishAreaConfig.GetFishChanceBonus(areaName, fishId)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.FishChanceBonus then
		return areaConfig.FishChanceBonus[fishId] or 0
	end
	return 0
end

return FishAreaConfig
