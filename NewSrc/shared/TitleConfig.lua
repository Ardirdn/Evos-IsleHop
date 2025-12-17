local TitleConfig = {}

TitleConfig.SummitTitles = {
	{
		Name = "Pendaki",
		DisplayName = "PENDAKI",
		MinSummits = 0,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "👤"
	},
	{
		Name = "Pendaki Fomo",
		DisplayName = "PENDAKI FOMO",
		MinSummits = 2,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "😰"
	},
	{
		Name = "Pendaki Amatir",
		DisplayName = "PENDAKI AMATIR",
		MinSummits = 3,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "🥾"
	},
	{
		Name = "Pendaki Pemula",
		DisplayName = "PENDAKI PEMULA",
		MinSummits = 5,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "🏃"
	},
	{
		Name = "Pendaki Tektok",
		DisplayName = "PENDAKI TEKTOK",
		MinSummits = 10,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "📱"
	},
	{
		Name = "Pendaki Handal",
		DisplayName = "PENDAKI HANDAL",
		MinSummits = 50,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "💪"
	},
	{
		Name = "Pendaki Berpengalaman",
		DisplayName = "PENDAKI BERPENGALAMAN",
		MinSummits = 100,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "⛰️"
	},
	{
		Name = "Pendaki Muka Lama",
		DisplayName = "PENDAKI MUKA LAMA",
		MinSummits = 250,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "🧔"
	},
	{
		Name = "Pendaki Professional",
		DisplayName = "PENDAKI PROFESSIONAL",
		MinSummits = 500,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "🏅"
	},
	{
		Name = "Penunggu Gunung",
		DisplayName = "PENUNGGU GUNUNG",
		MinSummits = 1000,
		Color = Color3.fromRGB(255, 255, 255),
		Icon = "🗻"
	},

	{
		Name = "Penjaga Gunung",
		DisplayName = "PENJAGA GUNUNG",
		MinSummits = 2000,
		Color = Color3.fromRGB(139, 195, 74),
		Icon = "🌲"
	},
	{
		Name = "Dewa Gunung",
		DisplayName = "DEWA GUNUNG",
		MinSummits = 3500,
		Color = Color3.fromRGB(33, 150, 243),
		Icon = "⚡"
	},
	{
		Name = "Raja Gunung",
		DisplayName = "RAJA GUNUNG",
		MinSummits = 5000,
		Color = Color3.fromRGB(156, 39, 176),
		Icon = "👑"
	},
	{
		Name = "Legenda Gunung",
		DisplayName = "LEGENDA GUNUNG",
		MinSummits = 7500,
		Color = Color3.fromRGB(255, 152, 0),
		Icon = "🔥"
	},
	{
		Name = "Immortal",
		DisplayName = "IMMORTAL",
		MinSummits = 10000,
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⭐"
	},
}

TitleConfig.SpecialTitles = {
	VIP = {
		DisplayName = "VIP",
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⭐",
		Priority = 100,
		GamepassId = 0,
		Givable = true,

		Privileges = {
			Tools = {"SpeedCoil", "BubbleGun"}
		}
	},
	VVIP = {
		DisplayName = "VVIP",
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "💎",
		Priority = 200,
		GamepassId = 0,
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
		Color = Color3.fromRGB(255, 165, 0),
		Icon = "🎯",
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
		Color = Color3.fromRGB(237, 66, 69),
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

TitleConfig.AccessRules = {

	["AdminZones"] = {"Admin", "Owner"},

	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin"},
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"},

	["EVOSZones"] = {"EVOS TEAM", "Admin", "Owner"},
	["TrimatraZones"] = {"Trimatra", "Admin", "Owner"},
	["AkamsiZones"] = {"Akamsi", "Admin", "Owner"},
	["BoatAccess"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Trimatra", "Admin", "Owner", "SahabatAdmin", "Akamsi"},
}

TitleConfig.ZoneColors = {
	["AdminZones"] = Color3.fromRGB(237, 66, 69),
	["VVIPZones"] = Color3.fromRGB(138, 43, 226),
	["VIPZones"] = Color3.fromRGB(255, 215, 0),
	["EVOSZones"] = Color3.fromRGB(255, 0, 0),
	["TrimatraZones"] = Color3.fromRGB(0, 150, 255),
}

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

TitleConfig.AdminIds = {}
for _, id in ipairs(TitleConfig.PrimaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end
for _, id in ipairs(TitleConfig.SecondaryAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

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

TitleConfig.DonationThreshold = 5000

return TitleConfig
