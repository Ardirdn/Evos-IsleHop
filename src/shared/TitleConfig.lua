local TitleConfig = {}

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

TitleConfig.SpecialTitles = {
	VIP = {
		DisplayName = "VIP",
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⭐",
		Priority = 100,
		GamepassId = 1635503506,
		Givable = true,
		Privileges = {
			Tools = {"SpeedCoil", "DoubleCoil"},
			Auras = {},
			MoneyReward = 0,
		}
	},
	VVIP = {
		DisplayName = "VVIP",
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "💎",
		Priority = 200,
		GamepassId = 1635215580,
		Givable = true,
		IncludesVIP = true,
		Privileges = {
			Tools = {"Boombox"},
			Auras = {"RainbowAura", "GalaxyAura"},
			MoneyReward = 5000,
		}
	},
	Donatur = {
		DisplayName = "DONATUR",
		Color = Color3.fromRGB(67, 181, 129),
		Icon = "💰",
		Priority = 150,
		Givable = true
	},
	CDP = {
		DisplayName = "CDP",
		Color = Color3.fromRGB(90, 157, 78),
		Icon = "",
		Priority = 250,
		Givable = true,
		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	SahabatAdmin = {
		DisplayName = "SAHABAT ADMIN",
		Color = Color3.fromRGB(237, 66, 69),
		Icon = "❤️",
		Priority = 300,
		Givable = true
	},
	Owner = {
		DisplayName = "OWNER",
		Color = Color3.fromRGB(220, 3, 22),
		Icon = "👑",
		Priority = 1000,
		Givable = false
	},
	Admin = {
		DisplayName = "ADMIN",
		Color = Color3.fromRGB(237, 66, 69),
		Icon = "👑",
		Priority = 999,
		Givable = false
	},
	["EVOS TEAM"] = {
		DisplayName = "EVOS TEAM",
		Color = Color3.fromRGB(255, 0, 0),
		Icon = "",
		Priority = 998,
		Givable = true
	}
}

TitleConfig.AccessRules = {
	["AdminZones"] = {"Admin", "Owner"},

	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Admin", "Owner", "SahabatAdmin"},
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM","Admin", "Owner", "SahabatAdmin", "Akamsi"},

	["EVOSZones"] = {"EVOS TEAM", "Admin", "Owner"},
	["AkamsiZones"] = {"Akamsi", "Admin", "Owner"},

	["BoatAccess"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Admin", "Owner", "SahabatAdmin", "CDP"},
}

TitleConfig.ZoneColors = {
	["AdminZones"] = Color3.fromRGB(237, 66, 69),
	["VVIPZones"] = Color3.fromRGB(138, 43, 226),
	["VIPZones"] = Color3.fromRGB(255, 215, 0),
	["EVOSZones"] = Color3.fromRGB(255, 0, 0)
}

TitleConfig.PrimaryAdminIds = {
	8714136305,
	8970505309,

}

TitleConfig.SecondaryAdminIds = {

    4680144719,

}

TitleConfig.AdminIds = {}
for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end
for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

TitleConfig.ThirdpartyAdminIds = {

	9209793056,
	 8910155229,
	 3573849857,
	 8600262000,
	 8418638393,
	 9139343773,
	 3574034140,
	 5252854473,
}

for _, id in ipairs(TitleConfig.ThirdpartyAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

TitleConfig.ThirdpartyPermissions = {
	CanTeleport = true,
	CanFreeze = true,
	CanGiveShopItems = true,
	CanKick = true,
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

function TitleConfig.IsFullAdmin(userId)
	return TitleConfig.IsPrimaryAdmin(userId) or TitleConfig.IsSecondaryAdmin(userId)
end

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

TitleConfig.DonationThreshold = 5000

return TitleConfig
