--[[
    FISH CONFIG
    Place in ReplicatedStorage/Modules/FishConfig.lua
    
    SINGLE SOURCE OF TRUTH untuk semua data ikan.
    Setiap ikan memiliki:
    - Name: Nama display ikan
    - Rarity: Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret
    - Price: Harga jual (auto-calculated berdasarkan rarity jika 0)
    - Weight: Berat minimum dalam kg
    - MaxWeight: Berat maksimum dalam kg
    - ImageID: Asset ID untuk gambar ikan
    - Location: Area di mana ikan ini lebih sering muncul
    - Description: Deskripsi singkat ikan
    
    LOCATION SYSTEM:
    - "Anywhere" : Bisa didapat di mana saja (default)
    - "DeepSea" : Laut dalam
    - "River" : Sungai
    - "Lake" : Danau
    - "Swamp" : Rawa
    - "Arctic" : Daerah es/kutub
    - "Volcanic" : Daerah vulkanik
    - "CoralReef" : Terumbu karang
    - "Cave" : Gua bawah air
]]

local FishConfig = {}

-- Rarity weight untuk random selection
FishConfig.RarityWeights = {
	Common = 50, -- 50%
	Uncommon = 30, -- 30%
	Rare = 15, -- 15%
	Epic = 4, -- 4%
	Legendary = 1, -- 1%
	Mythic = 0.5, -- 0.5% (1 in 200)
	Secret = 0.1, -- 0.1% (1 in 1000)
}

-- Rarity colors
FishConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 50, 50), -- Red/Crimson
	Secret = Color3.fromRGB(40, 0, 80), -- Deep Dark Violet
}

-- Base price per rarity (auto-calculated for each fish)
FishConfig.RarityBasePrices = {
	Common = 100,
	Uncommon = 250,
	Rare = 750,
	Epic = 2000,
	Legendary = 5000,
	Mythic = 15000,
	Secret = 50000,
}

-- Location bonus multipliers (higher = more rare fish in that area)
FishConfig.LocationBonus = {
	Anywhere = 1.0,
	DeepSea = 1.5,
	River = 1.0,
	Lake = 1.0,
	Swamp = 1.2,
	Arctic = 1.4,
	Volcanic = 1.5,
	CoralReef = 1.3,
	Cave = 1.6,
}

FishConfig.Fish = {
	-- ==================== COMMON ====================
	["Channa striata"] = {
		Name = "Channa striata",
		Rarity = "Common",
		Price = 0,
		Weight = 0.5,
		MaxWeight = 2.3,
		ImageID = "rbxassetid://109674971249979",
		Location = "River",
		Description = "Ikan gabus umum yang sering ditemukan di sungai dan sawah.",
	},
	["Eal"] = {
		Name = "Eal",
		Rarity = "Common",
		Price = 0,
		Weight = 0.01,
		MaxWeight = 0.05,
		ImageID = "rbxassetid://109674971249979",
		Location = "Swamp",
		Description = "Belut kecil yang licin dan sulit ditangkap.",
	},
	["Light_Fish"] = {
		Name = "Light Fish",
		Rarity = "Common",
		Price = 0,
		Weight = 2.5,
		MaxWeight = 45.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Ikan yang bercahaya dalam kegelapan laut dalam.",
	},
	["Shrimp"] = {
		Name = "Shrimp",
		Rarity = "Common",
		Price = 0,
		Weight = 0.3,
		MaxWeight = 1.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Udang biasa yang enak dimakan dan mudah didapat.",
	},
	["Spinefoot"] = {
		Name = "Spinefoot",
		Rarity = "Common",
		Price = 0,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://109674971249979",
		Location = "CoralReef",
		Description = "Ikan baronang yang berduri tajam di siripnya.",
	},
	["Squid"] = {
		Name = "Squid",
		Rarity = "Common",
		Price = 0,
		Weight = 0.1,
		MaxWeight = 0.4,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Cumi-cumi kecil yang lincah berenang.",
	},
	["Star_Fish"] = {
		Name = "Star Fish",
		Rarity = "Common",
		Price = 0,
		Weight = 0.2,
		MaxWeight = 0.6,
		ImageID = "rbxassetid://109674971249979",
		Location = "CoralReef",
		Description = "Bintang laut cantik yang lambat bergerak.",
	},
	["Threadfin_Bream"] = {
		Name = "Threadfin Bream",
		Rarity = "Common",
		Price = 0,
		Weight = 0.5,
		MaxWeight = 2.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Ikan kurisi yang sering ditemukan di pasar.",
	},
	["White_Spotted"] = {
		Name = "White Spotted",
		Rarity = "Common",
		Price = 0,
		Weight = 0.3,
		MaxWeight = 1.2,
		ImageID = "rbxassetid://109674971249979",
		Location = "Lake",
		Description = "Ikan berbintik putih yang indah dipandang.",
	},

	-- ==================== UNCOMMON ====================
	["Artifact Fin"] = {
		Name = "Artifact Fin",
		Rarity = "Uncommon",
		Price = 0,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://109674971249979",
		Location = "Cave",
		Description = "Ikan misterius dengan sirip seperti artefak kuno.",
	},
	["Catfish"] = {
		Name = "Catfish",
		Rarity = "Uncommon",
		Price = 0,
		Weight = 0.2,
		MaxWeight = 0.5,
		ImageID = "rbxassetid://109674971249979",
		Location = "River",
		Description = "Ikan lele berkumis yang suka bersembunyi di lumpur.",
	},
	["Eclipse Tail"] = {
		Name = "Eclipse Tail",
		Rarity = "Uncommon",
		Price = 0,
		Weight = 0.3,
		MaxWeight = 1.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Ikan dengan ekor yang bercahaya seperti gerhana.",
	},
	["Liquid Phantom"] = {
		Name = "Liquid Phantom",
		Rarity = "Uncommon",
		Price = 0,
		Weight = 0.5,
		MaxWeight = 1.5,
		ImageID = "rbxassetid://109674971249979",
		Location = "Swamp",
		Description = "Ikan transparan yang hampir tak terlihat di air.",
	},
	["Parasite Fin"] = {
		Name = "Parasite Fin",
		Rarity = "Uncommon",
		Price = 0,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://109674971249979",
		Location = "Swamp",
		Description = "Ikan parasit yang menempel pada ikan lain.",
	},
	["Thunder Mist"] = {
		Name = "Thunder Mist",
		Rarity = "Uncommon",
		Price = 0,
		Weight = 0.3,
		MaxWeight = 1.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Lake",
		Description = "Ikan listrik yang bisa menyetrum mangsanya.",
	},

	-- ==================== RARE ====================
	["Abyss Shadow"] = {
		Name = "Abyss Shadow",
		Rarity = "Rare",
		Price = 0,
		Weight = 0.5,
		MaxWeight = 4.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Makhluk misterius dari kedalaman laut yang gelap.",
	},
	["Bluearwana"] = {
		Name = "Bluearwana",
		Rarity = "Rare",
		Price = 0,
		Weight = 0.1,
		MaxWeight = 0.3,
		ImageID = "rbxassetid://109674971249979",
		Location = "River",
		Description = "Arwana biru langka dengan sisik berkilau.",
	},
	["RedArwana"] = {
		Name = "Red Arwana",
		Rarity = "Rare",
		Price = 0,
		Weight = 700.0,
		MaxWeight = 1600.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "River",
		Description = "Arwana merah legendaris, simbol keberuntungan.",
	},
	["Vampire_Fish"] = {
		Name = "Vampire Fish",
		Rarity = "Rare",
		Price = 0,
		Weight = 60.0,
		MaxWeight = 600.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Cave",
		Description = "Ikan predator dengan taring tajam seperti vampir.",
	},
	["Void Piranha"] = {
		Name = "Void Piranha",
		Rarity = "Rare",
		Price = 0,
		Weight = 0.2,
		MaxWeight = 0.5,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Piranha dari dimensi kekosongan yang mengerikan.",
	},

	-- ==================== EPIC ====================
	["Crocodile"] = {
		Name = "Crocodile",
		Rarity = "Epic",
		Price = 0,
		Weight = 4000.0,
		MaxWeight = 6000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Swamp",
		Description = "Buaya besar dan berbahaya dari rawa-rawa.",
	},
	["Fossil Ice Fish"] = {
		Name = "Fossil Ice Fish",
		Rarity = "Epic",
		Price = 0,
		Weight = 9000.0,
		MaxWeight = 24000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Arctic",
		Description = "Ikan purba yang membeku dalam es ribuan tahun.",
	},
	["Glass Fin"] = {
		Name = "Glass Fin",
		Rarity = "Epic",
		Price = 0,
		Weight = 50000.0,
		MaxWeight = 150000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "CoralReef",
		Description = "Ikan kristal transparan yang sangat rapuh dan indah.",
	},
	["Pewter Swimmer"] = {
		Name = "Pewter Swimmer",
		Rarity = "Epic",
		Price = 0,
		Weight = 14000.0,
		MaxWeight = 22000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Ikan logam yang berkilau seperti timah.",
	},
	["Purple_axollote"] = {
		Name = "Purple Axolotl",
		Rarity = "Epic",
		Price = 0,
		Weight = 20000.0,
		MaxWeight = 32000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Lake",
		Description = "Axolotl ungu langka dengan kemampuan regenerasi.",
	},
	["Red_axollote"] = {
		Name = "Red Axolotl",
		Rarity = "Epic",
		Price = 0,
		Weight = 15000.0,
		MaxWeight = 30000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Lake",
		Description = "Axolotl merah yang sangat dicari kolektor.",
	},

	-- ==================== LEGENDARY ====================
	["Aether"] = {
		Name = "Aether",
		Rarity = "Legendary",
		Price = 0,
		Weight = 19000.0,
		MaxWeight = 42000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Ikan surgawi yang melayang di antara dimensi.",
	},
	["Grimus Scaler"] = {
		Name = "Grimus Scaler",
		Rarity = "Legendary",
		Price = 0,
		Weight = 9000.0,
		MaxWeight = 24000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Ikan bersisik gelap dengan aura mengerikan.",
	},
	["King_Frog"] = {
		Name = "King Frog",
		Rarity = "Legendary",
		Price = 0,
		Weight = 3000.0,
		MaxWeight = 9000.0,
		ImageID = "rbxassetid://109674971249979",
		Location = "Swamp",
		Description = "Raja dari semua katak, bermahkota emas.",
	},
	["Sarcophagus"] = {
		Name = "Sarcophagus",
		Rarity = "Legendary",
		Price = 0,
		Weight = 2000,
		MaxWeight = 16000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Cave",
		Description = "Ikan kuno yang menyerupai peti mati firaun.",
	},

	-- ==================== MYTHIC ====================
	["BabyCrocodile"] = {
		Name = "Baby Crocodile",
		Rarity = "Mythic",
		Price = 0,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Swamp",
		Description = "Bayi buaya ajaib dengan kekuatan magis.",
	},
	["Dawnlight Sprinter"] = {
		Name = "Dawnlight Sprinter",
		Rarity = "Mythic",
		Price = 0,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Ikan secepat cahaya fajar yang hampir mustahil ditangkap.",
	},
	["DunkyB"] = {
		Name = "DunkyB",
		Rarity = "Mythic",
		Price = 0,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Ikan raksasa misterius dari zaman prasejarah.",
	},
	["Shadow Tentacle"] = {
		Name = "Shadow Tentacle",
		Rarity = "Mythic",
		Price = 0,
		Weight = 5000,
		MaxWeight = 35000,
		ImageID = "rbxassetid://109674971249979",
		Location = "DeepSea",
		Description = "Makhluk dengan tentakel bayangan dari kegelapan.",
	},

	-- ==================== SECRET ====================
	["CosmicAlan"] = {
		Name = "Cosmic Alan",
		Rarity = "Secret",
		Price = 0,
		Weight = 49000,
		MaxWeight = 62000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Anywhere",
		Description = "Ikan kosmik dari galaksi lain. Sangat langka!",
	},
	["North Star Drifter"] = {
		Name = "North Star Drifter",
		Rarity = "Secret",
		Price = 0,
		Weight = 49000,
		MaxWeight = 62000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Arctic",
		Description = "Ikan yang muncul hanya saat bintang utara bersinar.",
	},
	["Zircon Heart"] = {
		Name = "Zircon Heart",
		Rarity = "Secret",
		Price = 0,
		Weight = 49000,
		MaxWeight = 62000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Cave",
		Description = "Ikan dengan jantung kristal zirkon yang berkilau.",
	},
	["South Star Drifter"] = {
		Name = "South Star Drifter",
		Rarity = "Secret",
		Price = 0,
		Weight = 59000,
		MaxWeight = 72000,
		ImageID = "rbxassetid://109674971249979",
		Location = "Antarctic",
		Description = "Ikan dari Kutub Selatan yang sangat misterius.",
	},
}

-- Auto-calculate prices untuk semua ikan berdasarkan rarity
function FishConfig.AutoCalculatePrices()
	local count = 0
	for fishId, fishData in pairs(FishConfig.Fish) do
		count = count + 1
		-- Fix typo: Dugong seharusnya Legendary bukan "Dugong"
		if fishData.Rarity == "Dugong" then
			fishData.Rarity = "Legendary"
		end

		-- Set price based on rarity if currently 0
		if fishData.Price == 0 then
			local basePrice = FishConfig.RarityBasePrices[fishData.Rarity]
			if basePrice then
				-- Add slight variation (±20%) untuk variety
				local variation = math.random(80, 120) / 100
				fishData.Price = math.floor(basePrice * variation)
			else
				warn("⚠️ Unknown rarity for fish:", fishId, "-", fishData.Rarity)
				fishData.Price = 50 -- Default fallback
			end
		end
	end
	print("✅ [FISH CONFIG] Auto-calculated prices for", count, "fish types")
end

-- Function untuk get random fish berdasarkan rarity weight
function FishConfig.GetRandomFish()
	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(FishConfig.RarityWeights) do
		totalWeight = totalWeight + weight
	end

	-- Random selection
	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedRarity = "Common"

	for rarity, weight in pairs(FishConfig.RarityWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end

	-- Get all fish of selected rarity
	local fishPool = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then
			table.insert(fishPool, fishId)
		end
	end

	-- Return random fish from pool
	if #fishPool > 0 then
		local randomFish = fishPool[math.random(1, #fishPool)]
		return randomFish, FishConfig.Fish[randomFish]
	end

	-- Fallback ke ikan pertama
	local firstFish = next(FishConfig.Fish)
	return firstFish, FishConfig.Fish[firstFish]
end

-- Function untuk get random fish berdasarkan location
function FishConfig.GetRandomFishByLocation(location)
	location = location or "Anywhere"
	
	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(FishConfig.RarityWeights) do
		totalWeight = totalWeight + weight
	end

	-- Random selection for rarity
	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedRarity = "Common"

	for rarity, weight in pairs(FishConfig.RarityWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			selectedRarity = rarity
			break
		end
	end

	-- Get all fish of selected rarity that match location or are "Anywhere"
	local fishPool = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == selectedRarity then
			if fishData.Location == location or fishData.Location == "Anywhere" or location == "Anywhere" then
				table.insert(fishPool, fishId)
			end
		end
	end

	-- Return random fish from pool
	if #fishPool > 0 then
		local randomFish = fishPool[math.random(1, #fishPool)]
		return randomFish, FishConfig.Fish[randomFish]
	end

	-- Fallback to GetRandomFish
	return FishConfig.GetRandomFish()
end

-- Get fish by ID
function FishConfig.GetFishById(fishId)
	return FishConfig.Fish[fishId]
end

-- Get all fish of a specific rarity
function FishConfig.GetFishByRarity(rarity)
	local result = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Rarity == rarity then
			result[fishId] = fishData
		end
	end
	return result
end

-- Get all fish in a specific location
function FishConfig.GetFishByLocation(location)
	local result = {}
	for fishId, fishData in pairs(FishConfig.Fish) do
		if fishData.Location == location then
			result[fishId] = fishData
		end
	end
	return result
end

-- Get rarity color
function FishConfig.GetRarityColor(rarity)
	return FishConfig.RarityColors[rarity] or FishConfig.RarityColors.Common
end

-- Auto-calculate prices saat module di-load
FishConfig.AutoCalculatePrices()

return FishConfig
