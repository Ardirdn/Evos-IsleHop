local FishingRodConfig = {}

FishingRodConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

FishingRodConfig.DefaultRod = "WoodRod"

FishingRodConfig.DefaultLineStyle = {
	Color = Color3.fromRGB(0, 255, 255),
	Width = 0.16,
	Transparency = 0.12,
	LightEmission = 10,
	IsNeon = true,
}

FishingRodConfig.Rods = {

	["WoodRod"] = {

		ToolName = "WoodRod",
		ToolObject = "WoodRod",
		MaxThrowDistance = 35,
		ThrowHeight = 9,
		BobSpeed = 2.5,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(139, 90, 43),
			Width = 0.12,
			Transparency = 0.2,
			LightEmission = 0,
			IsNeon = false,
		},

		DisplayName = "Wooden Rod",
		Description = "Basic wooden fishing rod. Perfect for beginners!",
		Price = 0,
		Category = "Starter",
		Rarity = "Common",
		CatchBonus = 0,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["BambooRod"] = {

		ToolName = "BambooRod",
		ToolObject = "BambooRod",
		MaxThrowDistance = 40,
		ThrowHeight = 10,
		BobSpeed = 2.2,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(107, 142, 35),
			Width = 0.12,
			Transparency = 0.2,
			LightEmission = 0,
			IsNeon = false,
		},

		DisplayName = "Bamboo Rod",
		Description = "Lightweight bamboo rod with decent range and flexibility.",
		Price = 500,
		Category = "Basic",
		Rarity = "Common",
		CatchBonus = 5,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["BananaRod"] = {

		ToolName = "BananaRod",
		ToolObject = "BananaRod",
		MaxThrowDistance = 55,
		ThrowHeight = 16,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 225, 53),
			Width = 0.14,
			Transparency = 0.15,
			LightEmission = 3,
			IsNeon = true,
		},

		DisplayName = "Banana Rod",
		Description = "A-peel-ing rod that's perfect for tropical fishing!",
		Price = 1200,
		Category = "Basic",
		Rarity = "Uncommon",
		CatchBonus = 10,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["BaconRod"] = {

		ToolName = "BaconRod",
		ToolObject = "BaconRod",
		MaxThrowDistance = 45,
		ThrowHeight = 12,
		BobSpeed = 2.5,
		BobHeight = 0.4,
		LineStyle = {
			Color = Color3.fromRGB(200, 80, 60),
			Width = 0.18,
			Transparency = 0.1,
			LightEmission = 2,
			IsNeon = false,
		},

		DisplayName = "Bacon Rod",
		Description = "Crispy and delicious... wait, for fishing?!",
		Price = 1500,
		Category = "Basic",
		Rarity = "Uncommon",
		CatchBonus = 12,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["DevilRod"] = {

		ToolName = "DevilRod",
		ToolObject = "DevilRod",
		MaxThrowDistance = 48,
		ThrowHeight = 13,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 50, 50),
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 8,
			IsNeon = true,
		},

		DisplayName = "Devil Rod",
		Description = "Forged in hellfire, this rod attracts the most sinister catches.",
		Price = 5000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 25,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["WolfRod"] = {

		ToolName = "WolfRod",
		ToolObject = "WolfRod",
		MaxThrowDistance = 50,
		ThrowHeight = 14,
		BobSpeed = 2,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(100, 100, 120),
			Width = 0.14,
			Transparency = 0.15,
			LightEmission = 2,
			IsNeon = false,
		},

		DisplayName = "Wolf Rod",
		Description = "Hunt your prey with the instincts of a wolf.",
		Price = 5500,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 28,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["BoneRod"] = {

		ToolName = "BoneRod",
		ToolObject = "BoneRod",
		MaxThrowDistance = 54,
		ThrowHeight = 15,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(230, 230, 230),
			Width = 0.16,
			Transparency = 0.1,
			LightEmission = 4,
			IsNeon = true,
		},

		DisplayName = "Bone Rod",
		Description = "Crafted from ancient bones, attracts skeletal sea creatures.",
		Price = 6000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 30,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["InfernoRod"] = {

		ToolName = "InfernoRod",
		ToolObject = "InfernoRod",
		MaxThrowDistance = 52,
		ThrowHeight = 15,
		BobSpeed = 2.3,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(255, 100, 0),
			Width = 0.18,
			Transparency = 0.08,
			LightEmission = 10,
			IsNeon = true,
		},

		DisplayName = "Inferno Rod",
		Description = "Burns with eternal flames, perfect for volcanic waters.",
		Price = 6500,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 32,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["IcedRod"] = {

		ToolName = "IcedRod",
		ToolObject = "IcedRod",
		MaxThrowDistance = 50,
		ThrowHeight = 14,
		BobSpeed = 2.1,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(150, 220, 255),
			Width = 0.15,
			Transparency = 0.1,
			LightEmission = 6,
			IsNeon = true,
		},

		DisplayName = "Iced Rod",
		Description = "Frozen in eternal ice, attracts arctic creatures.",
		Price = 6000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 30,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["KnightRod"] = {

		ToolName = "KnightRod",
		ToolObject = "KnightRod",
		MaxThrowDistance = 55,
		ThrowHeight = 16,
		BobSpeed = 2.0,
		BobHeight = 0.5,
		LineStyle = {
			Color = Color3.fromRGB(192, 192, 192),
			Width = 0.18,
			Transparency = 0.1,
			LightEmission = 3,
			IsNeon = false,
		},

		DisplayName = "Knight Rod",
		Description = "Medieval power for honorable anglers. For the realm!",
		Price = 7000,
		Category = "Epic",
		Rarity = "Epic",
		CatchBonus = 35,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},

	["ReaperRod"] = {

		ToolName = "ReaperRod",
		ToolObject = "ReaperRod",
		MaxThrowDistance = 65,
		ThrowHeight = 18,
		BobSpeed = 1.8,
		BobHeight = 0.6,
		LineStyle = {
			Color = Color3.fromRGB(50, 0, 80),
			Width = 0.20,
			Transparency = 0.05,
			LightEmission = 10,
			IsNeon = true,
		},

		DisplayName = "Reaper Rod",
		Description = "The ultimate rod. Harvest souls from the deep abyss.",
		Price = 15000,
		Category = "Legendary",
		Rarity = "Legendary",
		CatchBonus = 50,
		ImageId = "rbxassetid://112916031103792",
		IsPremium = false,
		ProductId = nil
	},
}

function FishingRodConfig.GetRodById(rodId)
	return FishingRodConfig.Rods[rodId]
end

function FishingRodConfig.GetLineStyle(rodName)
	local rodConfig = FishingRodConfig.Rods[rodName]
	if rodConfig and rodConfig.LineStyle then
		return rodConfig.LineStyle
	end
	return FishingRodConfig.DefaultLineStyle
end

function FishingRodConfig.GetRodsArray()
	local rodsArray = {}
	for rodId, rodData in pairs(FishingRodConfig.Rods) do

		local rodWithId = {}
		for k, v in pairs(rodData) do
			rodWithId[k] = v
		end
		rodWithId.RodId = rodId
		table.insert(rodsArray, rodWithId)
	end

	table.sort(rodsArray, function(a, b)
		return a.Price < b.Price
	end)

	return rodsArray
end

function FishingRodConfig.GetRodsByCategory(category)
	local result = {}
	for rodId, rodData in pairs(FishingRodConfig.Rods) do
		if rodData.Category == category then
			local rodWithId = {}
			for k, v in pairs(rodData) do
				rodWithId[k] = v
			end
			rodWithId.RodId = rodId
			table.insert(result, rodWithId)
		end
	end
	return result
end

function FishingRodConfig.GetPrice(rodId)
	local rod = FishingRodConfig.Rods[rodId]
	return rod and rod.Price or 0
end

function FishingRodConfig.GetCatchBonus(rodId)
	local rod = FishingRodConfig.Rods[rodId]
	return rod and rod.CatchBonus or 0
end

function FishingRodConfig.Exists(rodId)
	return FishingRodConfig.Rods[rodId] ~= nil
end

function FishingRodConfig.GetRarityColor(rodId)
	local rod = FishingRodConfig.Rods[rodId]
	if rod then
		return FishingRodConfig.RarityColors[rod.Rarity] or FishingRodConfig.RarityColors.Common
	end
	return FishingRodConfig.RarityColors.Common
end

return FishingRodConfig
