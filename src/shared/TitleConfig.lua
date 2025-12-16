--[[
    TITLE CONFIG (REFACTORED WITH SUMMIT INTEGRATION + ACCESS CONTROL)
    Place in ReplicatedStorage/TitleConfig
    
    UPDATED: 3-TIER ADMIN SYSTEM
    - Primary Admin: Full access
    - Secondary Admin: Limited access (no Notifications & Events)
    - Thirdparty Admin: Very limited (Teleport, Freeze, Give Shop Items, Kick, Delete Leaderboard)
]]

local TitleConfig = {}

-- ==================== SUMMIT TITLES ====================
-- Title yang didapat berdasarkan jumlah summit
-- Urutan dari bawah ke atas (priority otomatis berdasarkan requirement)

TitleConfig.SummitTitles = {
	{
		Name = "Pengunjung",
		DisplayName = "PENGUNJUNG",
		MinSummits = 0,
		Color = Color3.fromRGB(180, 180, 185),
		Icon = "👤"
	},
	{
		Name = "Pendaki Pemula",
		DisplayName = "PENDAKI PEMULA",
		MinSummits = 10,
		Color = Color3.fromRGB(139, 195, 74),
		Icon = "🥾"
	},
	{
		Name = "Pendaki Terampil",
		DisplayName = "PENDAKI TERAMPIL",
		MinSummits = 50,
		Color = Color3.fromRGB(33, 150, 243),
		Icon = "⛰️"
	},
	{
		Name = "Pendaki Ahli",
		DisplayName = "PENDAKI AHLI",
		MinSummits = 100,
		Color = Color3.fromRGB(156, 39, 176),
		Icon = "🏔️"
	},
	{
		Name = "Master Pendaki",
		DisplayName = "MASTER PENDAKI",
		MinSummits = 500,
		Color = Color3.fromRGB(255, 152, 0),
		Icon = "🏅"
	},
	{
		Name = "Legenda Gunung",
		DisplayName = "LEGENDA GUNUNG",
		MinSummits = 1000,
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "👑"
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
		Givable = true,
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	Donatur = {
		DisplayName = "DONATUR",
		Color = Color3.fromRGB(67, 181, 129),
		Icon = "💰",
		Priority = 150,
		Givable = true
	},
	Akamsi = {
		DisplayName = "AKAMSI",
		Color = Color3.fromRGB(255, 165, 0), -- Orange
		Icon = "🎯",
		Priority = 250,
		Givable = true,
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	SahabatAdmin = {
		DisplayName = "SAHABAT ADMIN",
		Color = Color3.fromRGB(237, 66, 69), -- Merah
		Icon = "❤️",
		Priority = 300,
		Givable = true
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
		Givable = true
	},
	Trimatra = {
		DisplayName = "TRIMATRA",
		Color = Color3.fromRGB(0, 150, 255),
		Icon = "🛡️",
		Priority = 998,
		Givable = true
	}
}

-- ==================== ACCESS CONTROL RULES ====================
-- Folder name di Workspace/Colliders/ → Allowed titles

TitleConfig.AccessRules = {
	-- Admin zones: Only admin
	["AdminZones"] = {"Admin", "Owner"},

	-- Premium zones: VIP hierarchy
	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin"},
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"},

	-- Community/Clan zones: Exact match only (+ admin)
	["EVOSZones"] = {"EVOS TEAM", "Admin", "Owner"},
	["TrimatraZones"] = {"Trimatra", "Admin", "Owner"},
	["AkamsiZones"] = {"Akamsi", "Admin", "Owner"},
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
-- Note: ThirdpartyAdminIds ditambahkan di bawah setelah didefinisikan
TitleConfig.AdminIds = {}
for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end
for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

-- ==================== THIRDPARTY ADMIN ====================
-- Thirdparty Admin: Very limited permissions
-- Can ONLY do: Teleport, Freeze, Give Shop Items (non-premium), Kick (no ban), Delete Leaderboard Data

TitleConfig.ThirdpartyAdminIds = {
	8714136305,
	-- Tambahkan User ID thirdparty admin di sini
	-- Contoh: 1234567890,
}

-- Add ThirdpartyAdminIds to AdminIds for compatibility
for _, id in ipairs(TitleConfig.ThirdpartyAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

-- Thirdparty Admin Permissions (untuk reference di AdminServer)
TitleConfig.ThirdpartyPermissions = {
	CanTeleport = true,
	CanFreeze = true,
	CanGiveShopItems = true, -- Only non-premium items
	CanKick = true, -- No ban permission
	CanDeleteLeaderboard = true,
	CanBan = false,
	CanSetTitle = false,
	CanGiveTitle = false,
	CanSetSummit = false,
	CanSendNotifications = false,
	CanKill = false,
	CanSetSpeed = false,
	CanSetGravity = false,
	CanViewLogs = false,
}

-- ==================== HELPER FUNCTIONS ====================

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

function TitleConfig.IsThirdpartyAdmin(userId)
	for _, id in ipairs(TitleConfig.ThirdpartyAdminIds) do
		if userId == id then
			return true
		end
	end
	return false
end

function TitleConfig.IsAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId) or TitleConfig.IsSecondaryAdmin(userId) or TitleConfig.IsThirdpartyAdmin(userId)
end

-- Check if user is full admin (Primary or Secondary, NOT thirdparty)
function TitleConfig.IsFullAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId) or TitleConfig.IsSecondaryAdmin(userId)
end

-- Get admin tier (for UI display)
function TitleConfig.GetAdminTier(userId)
	if TitleConfig.IsPrimaryAdmin(userId) then
		return "Primary"
	elseif TitleConfig.IsSecondaryAdmin(userId) then
		return "Secondary"
	elseif TitleConfig.IsThirdpartyAdmin(userId) then
		return "Thirdparty"
	end
	return nil
end

-- ==================== DONATION THRESHOLD ====================
-- Minimum donation untuk mendapat title "Donatur"

TitleConfig.DonationThreshold = 5000

return TitleConfig
