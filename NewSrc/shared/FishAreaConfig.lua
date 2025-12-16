--[[
    FISH AREA CONFIG
    Place in ReplicatedStorage/Modules/FishAreaConfig.lua
    
    Konfigurasi untuk Fish Area System.
    
    Setiap area dapat:
    - Meningkatkan chance untuk mendapatkan ikan rarity tertentu
    - Memberikan bonus chance untuk ikan spesifik
    - Memiliki ikan eksklusif yang HANYA bisa didapat di area tersebut
    
    STRUKTUR DI WORKSPACE:
    workspace/
    └── FishArea/                    <- Model
        ├── VolcanoArea/             <- Folder (nama area)
        │   ├── Part1                <- Part (zona deteksi)
        │   ├── Part2                <- Part (zona deteksi)
        │   └── ...                  <- Bisa banyak part
        ├── IceArea/                 <- Folder (nama area)
        │   └── Part1                <- Part (zona deteksi)
        └── DeepSeaArea/             <- Folder (nama area)
            └── Part1                <- Part (zona deteksi)
]]

local FishAreaConfig = {}

-- ==================== RARITY MULTIPLIERS ====================
-- Ini adalah base multiplier untuk setiap rarity
-- Contoh: Jika base weight Legendary = 1, dan multiplier = 10, maka weight jadi 10
FishAreaConfig.DefaultRarityMultipliers = {
	Common = 1,
	Uncommon = 1,
	Rare = 1,
	Epic = 1,
	Legendary = 1
}

-- ==================== AREA CONFIGURATIONS ====================
-- Setiap area bisa memiliki:
-- RarityMultipliers: Mengubah weight rarity (multiplier)
-- FishChanceBonus: Bonus chance untuk ikan tertentu (additive weight)
-- ExclusiveFish: Ikan yang HANYA bisa didapat di area ini

FishAreaConfig.Areas = {
	-- ==================== VOLCANO AREA ====================
	["VolcanoArea"] = {
		DisplayName = "Volcano Waters",
		Description = "Hot volcanic waters where rare fire fish thrive!",
		Color = Color3.fromRGB(255, 100, 50), -- Orange/Red
		
		-- Rarity multipliers untuk area ini
		RarityMultipliers = {
			Common = 0.7,      -- 30% less common fish
			Uncommon = 0.8,    -- 20% less uncommon fish
			Rare = 1.5,        -- 50% more rare fish
			Epic = 2.0,        -- 2x epic fish
			Legendary = 3.0    -- 3x legendary fish!
		},
		
		-- Bonus chance untuk ikan spesifik di area ini
		-- Nilai adalah weight TAMBAHAN (bukan multiplier)
		FishChanceBonus = {
			["Dragon_Fish"] = 50,       -- +50 weight untuk Dragon Fish
			["Lion_Fish"] = 30,         -- +30 weight untuk Lion Fish
			["Flying_Fish"] = 20,       -- +20 weight untuk Flying Fish
			["Mandarin_Fish"] = 25,     -- +25 weight untuk Mandarin Fish
		},
		
		-- Ikan eksklusif HANYA bisa didapat di area ini
		ExclusiveFish = {
			-- "Lava_Fish",  -- Contoh ikan eksklusif (perlu ditambah di FishConfig)
		}
	},
	
	-- ==================== ICE AREA ====================
	["IceArea"] = {
		DisplayName = "Frozen Waters",
		Description = "Icy cold waters where arctic creatures live!",
		Color = Color3.fromRGB(150, 220, 255), -- Light Blue
		
		RarityMultipliers = {
			Common = 0.8,
			Uncommon = 1.0,
			Rare = 1.3,
			Epic = 1.8,
			Legendary = 2.5
		},
		
		FishChanceBonus = {
			["Narwehal_Whale"] = 40,    -- +40 weight untuk Narwhal
			["Killer_Whale"] = 35,      -- +35 weight untuk Orca
			["Salmon"] = 20,            -- +20 weight untuk Salmon
			["Coelacanth"] = 30,        -- +30 weight untuk Coelacanth
		},
		
		ExclusiveFish = {}
	},
	
	-- ==================== DEEP SEA AREA ====================
	["DeepSeaArea"] = {
		DisplayName = "Deep Sea Trench",
		Description = "The darkest depths where legendary creatures lurk!",
		Color = Color3.fromRGB(30, 50, 100), -- Dark Blue
		
		RarityMultipliers = {
			Common = 0.5,      -- 50% less common
			Uncommon = 0.6,    -- 40% less uncommon
			Rare = 2.0,        -- 2x rare
			Epic = 3.0,        -- 3x epic
			Legendary = 5.0    -- 5x legendary!
		},
		
		FishChanceBonus = {
			["Angler_Fish"] = 60,       -- +60 weight untuk Angler Fish
			["Goblin_Shark"] = 50,      -- +50 weight untuk Goblin Shark
			["Oar_Fish"] = 45,          -- +45 weight untuk Oar Fish
			["Megalodon"] = 40,         -- +40 weight untuk Megalodon
			["Bloop"] = 35,             -- +35 weight untuk Bloop
			["Coelacanth"] = 30,        -- +30 weight untuk Coelacanth
		},
		
		ExclusiveFish = {}
	},
	
	-- ==================== CORAL REEF AREA ====================
	["CoralReefArea"] = {
		DisplayName = "Coral Reef",
		Description = "Beautiful coral reef with colorful tropical fish!",
		Color = Color3.fromRGB(255, 150, 200), -- Pink/Coral
		
		RarityMultipliers = {
			Common = 1.0,
			Uncommon = 1.5,    -- 50% more uncommon
			Rare = 1.3,
			Epic = 1.5,
			Legendary = 1.2
		},
		
		FishChanceBonus = {
			["Clown_Fish"] = 50,        -- +50 weight untuk Clown Fish
			["Blue_Tang"] = 40,         -- +40 weight untuk Blue Tang
			["Coral_Beauties"] = 35,    -- +35 weight untuk Coral Beauties
			["Moorish_Idol"] = 30,      -- +30 weight untuk Moorish Idol
			["Parrotfish"] = 25,        -- +25 weight untuk Parrotfish
		},
		
		ExclusiveFish = {}
	},
}

-- ==================== HELPER FUNCTIONS ====================

-- Get area config by name
function FishAreaConfig.GetAreaConfig(areaName)
	return FishAreaConfig.Areas[areaName]
end

-- Get all area names
function FishAreaConfig.GetAllAreaNames()
	local names = {}
	for name, _ in pairs(FishAreaConfig.Areas) do
		table.insert(names, name)
	end
	return names
end

-- Check if fish is exclusive to an area
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

-- Get rarity multiplier for an area
function FishAreaConfig.GetRarityMultiplier(areaName, rarity)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.RarityMultipliers then
		return areaConfig.RarityMultipliers[rarity] or 1
	end
	return 1
end

-- Get fish chance bonus for an area
function FishAreaConfig.GetFishChanceBonus(areaName, fishId)
	local areaConfig = FishAreaConfig.Areas[areaName]
	if areaConfig and areaConfig.FishChanceBonus then
		return areaConfig.FishChanceBonus[fishId] or 0
	end
	return 0
end

return FishAreaConfig
