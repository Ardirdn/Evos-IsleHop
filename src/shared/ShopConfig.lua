local ShopConfig = {}

ShopConfig.Gamepasses = {
	{
		Name = "VIP",
		Price = 129,
		Thumbnail = "rbxassetid://93839116673767",
		GamepassId = 1635503506,
		Description = "⭐ Title VIP Eksklusif | 🚪 Akses Area VIP | ⛵ Akses Boat | 🔧 Speed Coil & Double Coil"
	},
	{
		Name = "VVIP",
		Price = 249,
		Thumbnail = "rbxassetid://113168148931190",
		GamepassId = 1635215580,
		Description = "💎 Semua Reward VIP | ⭐ Title VVIP Eksklusif | ⛵ Akses Boat | 🎵 Boombox | ✨ Rainbow & Galaxy Aura | 💰 Money Large Pack"
	},
	{
        Name = "x2 Summit",
        DisplayName = "x2 Summit",
        Description = "Dapatkan 2x lipat summit setiap mencapai puncak!",
        Price = 199,
		GamepassId = 1635605352,
        Thumbnail = "rbxassetid://130384558824672",
        Icon = "⚡",
        Color = Color3.fromRGB(255, 165, 0)
    },
}

ShopConfig.Auras = {
	{
		Title = "Fire Aura",
		IsPremium = false,
		Price = 1065,
		Thumbnail = "rbxassetid://137186433949829",
		AuraId = "FireAura"
	},
	{
		Title = "Ice Aura",
		IsPremium = false,
		Price = 5325,
		Thumbnail = "rbxassetid://117932928077084",
		AuraId = "IceAura"
	},
	{
		Title = "Lightning Aura",
		IsPremium = false,
		Price = 10650,
		Thumbnail = "rbxassetid://138063742624133",
		AuraId = "LightningAura"
	},
	{
		Title = "Shadow Aura",
		IsPremium = false,
		Price = 7455,
		Thumbnail = "rbxassetid://99172280237398",
		AuraId = "ShadowAura"
	},
	{
		Title = "Rainbow Aura",
		IsPremium = true,
		Price = 100,
		ProductId = 3465227826,
		Thumbnail = "rbxassetid://119081023364677",
		AuraId = "RainbowAura"
	},
	{
		Title = "Galaxy Aura",
		IsPremium = true,
		Price = 250,
		ProductId = 3482497613,
		Thumbnail = "rbxassetid://99172280237398",
		AuraId = "GalaxyAura"
	},
}

ShopConfig.Tools = {
	{
		Title = "Speed Coil",
		IsPremium = false,
		Price = 500,
		Thumbnail = "rbxassetid://126083559497297",
		ToolId = "SpeedCoil"
	},
	{
		Title = "Double Coil",
		IsPremium = false,
		Price = 1000,
		Thumbnail = "rbxassetid://78073594661667",
		ToolId = "DoubleCoil"
	},
	{
		Title = "Flashlight",
		IsPremium = false,
		Price = 300,
		Thumbnail = "rbxassetid://106048277357918",
		ToolId = "Flashlight"
	},
	{
		Title = "Sign Board",
		IsPremium = false,
		Price = 400,
		Thumbnail = "rbxassetid://92313592030698",
		ToolId = "SignBoard"
	},
	{
		Title = "Summit Board",
		IsPremium = false,
		Price = 600,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "SummitBoard"
	},
	{
		Title = "Boombox",
		IsPremium = true,
		Price = 150,
		ProductId = 3481886004,
		Thumbnail = "rbxassetid://104882725235129",
		ToolId = "Boombox"
	},
	{
		Title = "Selfie Stick",
		IsPremium = false,
		Price = 2000,
		Thumbnail = "rbxassetid://132639002206556",
		ToolId = "SelfieStick"
	},
}
ShopConfig.MoneyPacks = {
	{
		Title = "Starter Pack",
		Price = 29,
		Thumbnail = "rbxassetid://79418658322705",
		MoneyReward = 1000,
		ProductId = 3481884364
	},
	{
		Title = "Medium Pack",
		Price = 39,
		Thumbnail = "rbxassetid://73578426695423",
		MoneyReward = 5000,
		ProductId = 3481884609
	},
	{
		Title = "Large Pack",
		Price = 79,
		Thumbnail = "rbxassetid://85712527609444",
		MoneyReward = 15000,
		ProductId = 3481884804
	},
	{
		Title = "Mega Pack",
		Price = 119,
		Thumbnail = "rbxassetid://111605086890519",
		MoneyReward = 50000,
		ProductId = 3481884989
	},
}

return ShopConfig
