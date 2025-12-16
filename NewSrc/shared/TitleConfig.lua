--[[
    TITLE CONFIG (REFACTORED WITH SUMMIT INTEGRATION + ACCESS CONTROL)
    Place in ReplicatedStorage/TitleConfig
]]

local TitleConfig = {}

-- ==================== SUMMIT TITLES ====================
-- Title yang didapat berdasarkan jumlah summit
-- Urutan dari bawah ke atas (priority otomatis berdasarkan requirement)
-- Warna putih untuk awal, 5 terakhir berwarna special

TitleConfig.SummitTitles = {
	{
		Name = "Pendaki",
		DisplayName = "PENDAKI",
		MinSummits = 0,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "👤"
	},
	{
		Name = "Pendaki Fomo",
		DisplayName = "PENDAKI FOMO",
		MinSummits = 2,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "😰"
	},
	{
		Name = "Pendaki Amatir",
		DisplayName = "PENDAKI AMATIR",
		MinSummits = 3,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "🥾"
	},
	{
		Name = "Pendaki Pemula",
		DisplayName = "PENDAKI PEMULA",
		MinSummits = 5,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "🏃"
	},
	{
		Name = "Pendaki Tektok",
		DisplayName = "PENDAKI TEKTOK",
		MinSummits = 10,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "📱"
	},
	{
		Name = "Pendaki Handal",
		DisplayName = "PENDAKI HANDAL",
		MinSummits = 50,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "💪"
	},
	{
		Name = "Pendaki Berpengalaman",
		DisplayName = "PENDAKI BERPENGALAMAN",
		MinSummits = 100,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "⛰️"
	},
	{
		Name = "Pendaki Muka Lama",
		DisplayName = "PENDAKI MUKA LAMA",
		MinSummits = 250,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "🧔"
	},
	{
		Name = "Pendaki Professional",
		DisplayName = "PENDAKI PROFESSIONAL",
		MinSummits = 500,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "🏅"
	},
	{
		Name = "Penunggu Gunung",
		DisplayName = "PENUNGGU GUNUNG",
		MinSummits = 1000,
		Color = Color3.fromRGB(255, 255, 255), -- Putih
		Icon = "🗻"
	},
	-- ===== 5 TITLE TERAKHIR BERWARNA SPECIAL =====
	{
		Name = "Penjaga Gunung",
		DisplayName = "PENJAGA GUNUNG",
		MinSummits = 2000,
		Color = Color3.fromRGB(139, 195, 74), -- Hijau
		Icon = "🌲"
	},
	{
		Name = "Dewa Gunung",
		DisplayName = "DEWA GUNUNG",
		MinSummits = 3500,
		Color = Color3.fromRGB(33, 150, 243), -- Biru
		Icon = "⚡"
	},
	{
		Name = "Raja Gunung",
		DisplayName = "RAJA GUNUNG",
		MinSummits = 5000,
		Color = Color3.fromRGB(156, 39, 176), -- Ungu
		Icon = "👑"
	},
	{
		Name = "Legenda Gunung",
		DisplayName = "LEGENDA GUNUNG",
		MinSummits = 7500,
		Color = Color3.fromRGB(255, 152, 0), -- Orange
		Icon = "🔥"
	},
	{
		Name = "Immortal",
		DisplayName = "IMMORTAL",
		MinSummits = 10000,
		Color = Color3.fromRGB(255, 215, 0), -- Gold
		Icon = "⭐"
	},
}

-- ==================== SPECIAL TITLES ====================
-- Title khusus yang override summit titles
-- Didapat dari gamepass, donation, atau admin grant

TitleConfig.SpecialTitles = {
	VIP = {
		DisplayName = "VIP",
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⭐",
		Priority = 100, -- Higher priority = override summit titles
		GamepassId = 0, -- GANTI DENGAN GAMEPASS ID VIP
		Givable = true, -- Can be given by admin
		-- ✅ Tools yang diberikan saat equip title ini
		-- Nama harus SAMA PERSIS dengan nama tool di ReplicatedStorage/Tools
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	VVIP = {
		DisplayName = "VVIP",
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "💎",
		Priority = 200,
		GamepassId = 0, -- GANTI DENGAN GAMEPASS ID VVIP
		Givable = true, -- Can be given by admin
		-- ✅ Tools yang diberikan saat equip title ini
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	Donatur = {
		DisplayName = "DONATUR",
		Color = Color3.fromRGB(67, 181, 129),
		Icon = "💰",
		Priority = 150,
		Givable = true -- Can be given by admin
	},
	Akamsi = {
		DisplayName = "AKAMSI",
		Color = Color3.fromRGB(255, 165, 0), -- Orange
		Icon = "🎯",
		Priority = 250,
		Givable = true, -- Can be given by admin
		-- ✅ Tools yang diberikan saat equip title ini
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	SahabatAdmin = {
		DisplayName = "SAHABAT ADMIN",
		Color = Color3.fromRGB(237, 66, 69), -- Merah
		Icon = "❤️",
		Priority = 300,
		Givable = true -- Can be given by admin
	},
	Owner = {
		DisplayName = "OWNER",
		Color = Color3.fromRGB(237, 66, 69), -- Merah
		Icon = "👑",
		Priority = 1000, -- Highest priority
		Givable = false -- Cannot be given, owner only
	},
	Admin = {
		DisplayName = "ADMIN",
		Color = Color3.fromRGB(237, 66, 69),
		Icon = "👑",
		Priority = 999,
		Givable = false -- Cannot be given, admin only
	},
	["EVOS TEAM"] = {
		DisplayName = "EVOS TEAM",
		Color = Color3.fromRGB(255, 0, 0),
		Icon = "🔥",
		Priority = 998,
		Givable = true -- Can be given by admin
	},
	Trimatra = {
		DisplayName = "TRIMATRA",
		Color = Color3.fromRGB(0, 150, 255),
		Icon = "🛡️",
		Priority = 998,
		Givable = true -- Can be given by admin
	}
}

-- ==================== ACCESS CONTROL RULES ====================
-- Folder name di Workspace/Colliders/ → Allowed titles

TitleConfig.AccessRules = {
	-- Admin zones: Only admin
	["AdminZones"] = {"Admin", "Owner"},

	-- Premium zones: VIP hierarchy
	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin"}, -- VVIP + Community
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"}, -- VIP+

	-- Community/Clan zones: Exact match only (+ admin)
	["EVOSZones"] = {"EVOS TEAM", "Admin", "Owner"}, -- Only EVOS members
	["TrimatraZones"] = {"Trimatra", "Admin", "Owner"}, -- Only Trimatra members
	["AkamsiZones"] = {"Akamsi", "Admin", "Owner"}, -- Only Akamsi members
	["BoatAccess"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"},
}


-- ==================== ZONE COLORS ====================
-- Visual identification untuk zone colliders

TitleConfig.ZoneColors = {
	["AdminZones"] = Color3.fromRGB(237, 66, 69), -- Red
	["VVIPZones"] = Color3.fromRGB(138, 43, 226), -- Purple
	["VIPZones"] = Color3.fromRGB(255, 215, 0), -- Gold
	["EVOSZones"] = Color3.fromRGB(255, 0, 0), -- Bright Red
	["TrimatraZones"] = Color3.fromRGB(0, 150, 255), -- Blue
}



-- ==================== ADMIN IDS ====================
-- Primary Admin: Full access to all features
-- Secondary Admin: Limited access (cannot use Notifications & Events)
-- Both have the same "Admin" title

TitleConfig.PrimaryAdminIds = {
	8714136305,
	8578879617,
	8592664252,
}

TitleConfig.SecondaryAdminIds = {
    4680144719,
    3539387444,
    5670874280,
	9378557196,
	9099778359,
	9515803542,
	9288548837,
	9164623064,
}

-- Combine semua admin IDs (untuk compatibility dengan existing code)
TitleConfig.AdminIds = {}
for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end
for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

-- Helper functions
function TitleConfig.IsPrimaryAdmin(userId)
	for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
		if userId == id then
			return true
		end
	end
	return false
end

function TitleConfig.IsSecondaryAdmin(userId)
	for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
		if userId == id then
			return true
		end
	end
	return false
end

function TitleConfig.IsAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId) or TitleConfig.IsSecondaryAdmin(userId)
end

-- ==================== DONATION THRESHOLD ====================
-- Minimum donation untuk mendapat title "Donatur"

TitleConfig.DonationThreshold = 5000

return TitleConfig
