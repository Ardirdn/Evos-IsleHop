local TitleConfig = {}

TitleConfig.SummitTitles = {
	{
		Name = "Stranded Sailor",
		DisplayName = "STRANDED SAILOR",
		MinSummits = 0,
		Color = Color3.fromRGB(180, 180, 185),
		Icon = "⚓"
	},
	{
		Name = "Deck Rookie",
		DisplayName = "DECK ROOKIE",
		MinSummits = 1,
		Color = Color3.fromRGB(160, 160, 165),
		Icon = "🚢"
	},
	{
		Name = "Coast Explorer",
		DisplayName = "COAST EXPLORER",
		MinSummits = 10,
		Color = Color3.fromRGB(139, 195, 74),
		Icon = "🏝️"
	},
	{
		Name = "Island Hopper",
		DisplayName = "ISLAND HOPPER",
		MinSummits = 20,
		Color = Color3.fromRGB(100, 200, 100),
		Icon = "🌴"
	},
	{
		Name = "Wave Drifter",
		DisplayName = "WAVE DRIFTER",
		MinSummits = 35,
		Color = Color3.fromRGB(64, 164, 223),
		Icon = "🌊"
	},
	{
		Name = "Sea Legs Acquired",
		DisplayName = "SEA LEGS ACQUIRED",
		MinSummits = 50,
		Color = Color3.fromRGB(33, 150, 243),
		Icon = "🦿"
	},
	{
		Name = "Jungle Scout",
		DisplayName = "JUNGLE SCOUT",
		MinSummits = 75,
		Color = Color3.fromRGB(76, 175, 80),
		Icon = "🌿"
	},
	{
		Name = "Vine Breaker",
		DisplayName = "VINE BREAKER",
		MinSummits = 99,
		Color = Color3.fromRGB(56, 142, 60),
		Icon = "🌱"
	},
	{
		Name = "Lost in the Canopy",
		DisplayName = "LOST IN THE CANOPY",
		MinSummits = 120,
		Color = Color3.fromRGB(46, 125, 50),
		Icon = "🌳"
	},
	{
		Name = "Heatproof Explorer",
		DisplayName = "HEATPROOF EXPLORER",
		MinSummits = 150,
		Color = Color3.fromRGB(255, 152, 0),
		Icon = "🔥"
	},
	{
		Name = "Lava Dodger",
		DisplayName = "LAVA DODGER",
		MinSummits = 180,
		Color = Color3.fromRGB(255, 87, 34),
		Icon = "🌋"
	},
	{
		Name = "Ash Survivor",
		DisplayName = "ASH SURVIVOR",
		MinSummits = 200,
		Color = Color3.fromRGB(121, 85, 72),
		Icon = "💨"
	},
	{
		Name = "Frozen Drifter",
		DisplayName = "FROZEN DRIFTER",
		MinSummits = 250,
		Color = Color3.fromRGB(129, 212, 250),
		Icon = "❄️"
	},
	{
		Name = "Icebound Veteran",
		DisplayName = "ICEBOUND VETERAN",
		MinSummits = 300,
		Color = Color3.fromRGB(79, 195, 247),
		Icon = "🧊"
	},
	{
		Name = "Whiteout Walker",
		DisplayName = "WHITEOUT WALKER",
		MinSummits = 400,
		Color = Color3.fromRGB(224, 247, 250),
		Icon = "�️"
	},
	{
		Name = "Sea Legend",
		DisplayName = "SEA LEGEND",
		MinSummits = 500,
		Color = Color3.fromRGB(156, 39, 176),
		Icon = "🏆"
	},
	{
		Name = "Pirate King",
		DisplayName = "PIRATE KING",
		MinSummits = 750,
		Color = Color3.fromRGB(255, 152, 0),
		Icon = "🏴‍☠️"
	},
	{
		Name = "Myth of the Seven Seas",
		DisplayName = "MYTH OF THE SEVEN SEAS",
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
		Color = Color3.fromRGB(255, 128, 0),
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
		DisplayName = "EVOSFAMS",
		Color = Color3.fromRGB(120, 197, 239),
		Icon = "",
		Priority = 998,
		Givable = true
	},
	BETA = {
		DisplayName = "BETA",
		Color = Color3.fromRGB(0, 188, 212),
		Icon = "🧪",
		Priority = 50,
		Givable = true
	}
}

TitleConfig.OwnerIds = {
	8714136305,
	8970505309,
}

TitleConfig.AccessRules = {
	["AdminZones"] = {"Admin", "Owner"},

	["VVIPZones"] = {"VVIP", "Donatur", "EVOS TEAM", "Admin", "Owner", "SahabatAdmin"},
	["VIPZones"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM","Admin", "Owner", "SahabatAdmin", "Akamsi"},

	["EVOSZones"] = {"EVOS TEAM", "Admin", "Owner"},
	["CDPZones"] = {"CDP", "Admin", "Owner"},
	["AkamsiZones"] = {"Akamsi", "Admin", "Owner"},

	["BoatAccess"] = {"VIP", "VVIP", "Donatur", "EVOS TEAM", "Admin", "Owner", "SahabatAdmin", "CDP"},
}

TitleConfig.ZoneColors = {
	["AdminZones"] = Color3.fromRGB(237, 66, 69),
	["VVIPZones"] = Color3.fromRGB(138, 43, 226),
	["VIPZones"] = Color3.fromRGB(255, 215, 0),
	["EVOSZones"] = Color3.fromRGB(255, 0, 0),
	["CDPZones"] = Color3.fromRGB(90, 157, 78),
	["AkamsiZones"] = Color3.fromRGB(255, 215, 0),
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
	7228593387,
	1373072637,
	9209793056,
	 8910155229,
	 3573849857,
	 8600262000,
	 8418638393,
	 9139343773,
	 3574034140,
	 5252854473,
	 8729387257,
	 9131669758,
	 9022677412,
	 6102793082,
	 7881797747
	 
}

for _, id in ipairs(TitleConfig.ThirdpartyAdminIds) do
	table.insert(TitleConfig.AdminIds, id)
end

TitleConfig.ThirdpartyPermissions = {
	CanTeleport = true,
	CanFreeze = true,
	CanGiveShopItems = true,
	CanGiveMoney = false,  -- Third party admin tidak bisa give money
	CanCreateMoneyCode = false,  -- Third party admin tidak bisa buat redeem code money
	CanKick = true,
	CanDeleteLeaderboard = true,
	CanBan = false,
	CanSetTitle = false,
	CanGiveTitle = false,
	CanSetSummit = false,
	CanSendNotifications = true,
	CanKill = false,
	CanSetSpeed = false,
	CanSetGravity = false,
	CanViewLogs = false,
	CanRemoveInventory = true,  -- Third party admin bisa remove inventory items
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

function TitleConfig.IsOwner(userId)
	for _, id in ipairs(TitleConfig.OwnerIds) do
		if userId == id then
			return true
		end
	end
	return false
end

TitleConfig.DonationThreshold = 5000

return TitleConfig
