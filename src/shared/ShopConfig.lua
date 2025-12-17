local ShopConfig = {}

ShopConfig.Gamepasses = {
	{
		Name = "VIP",
		Price = 100,
		Thumbnail = "rbxassetid://93839116673767",
		GamepassId = 1604161626,
		Description = "Unlock VIP features and exclusive perks!"
	},
	{
		Name = "VVIP",
		Price = 500,
		Thumbnail = "rbxassetid://113168148931190",
		GamepassId = 1603523555,
		Description = "Ultimate VIP with premium benefits!"
	},
	{
        Name = "x2 Summit",
        DisplayName = "x2 Summit",
        Description = "Dapatkan 2x lipat summit setiap mencapai puncak!",
        Price = 100,
		GamepassId = 1604095605,
        Thumbnail = "rbxassetid://130384558824672",
        Icon = "⚡",
        Color = Color3.fromRGB(255, 165, 0)
    },
}

ShopConfig.GiftProducts = {
	{
		Name = "VIP",
		Price = 99,
		Thumbnail = "rbxassetid://7733964640",
		ProductId = 3459575729,
		Description = "Gift VIP status to another player!",
		Icon = "👑",
		Color = Color3.fromRGB(70, 130, 255),
		RewardType = "Gamepass",
		RewardId = 1594042769
	},
	{
		Name = "VVIP",
		Price = 199,
		Thumbnail = "rbxassetid://7733964640",
		ProductId = 3459575802,
		Description = "Gift VVIP status to another player!",
		Icon = "💎",
		Color = Color3.fromRGB(90, 150, 255),
		RewardType = "Gamepass",
		RewardId = 1590994399
	},

	{
		Name = "Fire Aura",
		Price = 50,
		ProductId = 0,
		Description = "Gift Fire aura to another player!",
		Icon = "🔥",
		Color = Color3.fromRGB(255, 100, 50),
		RewardType = "Aura",
		RewardId = "FireAura"
	},
	{
		Name = "Ice Aura",
		Price = 60,
		ProductId = 0,
		Description = "Gift Ice aura!",
		Icon = "❄️",
		Color = Color3.fromRGB(100, 200, 255),
		RewardType = "Aura",
		RewardId = "IceAura"
	},
	{
		Name = "Galaxy Aura",
		Price = 75,
		ProductId = 3459294151,
		Description = "Gift Galaxy aura!",
		Icon = "🌌",
		Color = Color3.fromRGB(100, 50, 255),
		RewardType = "Aura",
		RewardId = "GalaxyAura"
	},
	{
		Name = "Rainbow Aura",
		Price = 100,
		ProductId = 0,
		Description = "Gift Rainbow aura!",
		Icon = "🌈",
		Color = Color3.fromRGB(255, 150, 255),
		RewardType = "Aura",
		RewardId = "RainbowAura"
	},

	{
		Name = "Speed Coil",
		Price = 80,
		ProductId = 0,
		Description = "Gift Speed Coil tool!",
		Icon = "⚡",
		Color = Color3.fromRGB(255, 255, 0),
		RewardType = "Tool",
		RewardId = "SpeedCoil"
	},
	{
		Name = "Lightsaber",
		Price = 100,
		ProductId = 3459293993,
		Description = "Gift Lightsaber tool!",
		Icon = "⚔️",
		Color = Color3.fromRGB(0, 200, 255),
		RewardType = "Tool",
		RewardId = "Lightsaber"
	},
	{
		Name = "Boombox",
		Price = 150,
		ProductId = 0,
		Description = "Gift Boombox tool!",
		Icon = "📻",
		Color = Color3.fromRGB(255, 100, 200),
		RewardType = "Tool",
		RewardId = "Boombox"
	}
}

ShopConfig.Auras = {
	{
		Title = "Fire Aura",
		IsPremium = false,
		Price = 1000,
		Thumbnail = "rbxassetid://137186433949829",
		AuraId = "FireAura"
	},
	{
		Title = "Ice Aura",
		IsPremium = false,
		Price = 1500,
		Thumbnail = "rbxassetid://117932928077084",
		AuraId = "IceAura"
	},
	{
		Title = "Lightning Aura",
		IsPremium = false,
		Price = 2000,
		Thumbnail = "rbxassetid://138063742624133",
		AuraId = "LightningAura"
	},
	{
		Title = "Shadow Aura",
		IsPremium = false,
		Price = 2500,
		Thumbnail = "rbxassetid://99172280237398",
		AuraId = "ShadowAura"
	},
	{
		Title = "Rainbow Aura",
		IsPremium = true,
		Price = 100,
		ProductId = 3465227826,
		Thumbnail = "rbxassetid://135525537490161",
		AuraId = "RainbowAura"
	},
	{
		Title = "Galaxy Aura",
		IsPremium = true,
		Price = 250,
		ProductId = 3465227441,
		Thumbnail = " rbxassetid://99172280237398",
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
		Title = "Gravity Coil",
		IsPremium = false,
		Price = 750,
		Thumbnail = "rbxassetid://78073594661667",
		ToolId = "GravityCoil"
	},
	{
		Title = "Paint Bucket",
		IsPremium = false,
		Price = 300,
		Thumbnail = "rbxassetid://7733764811",
		ToolId = "PaintBucket"
	},
	{
		Title = "Rocket Launcher",
		IsPremium = false,
		Price = 1200,
		Thumbnail = "rbxassetid://7733764811",
		ToolId = "RocketLauncher"
	},
	{
		Title = "Boombox",
		IsPremium = true,
		Price = 150,
		ProductId = 0,
		Thumbnail = "rbxassetid://136639296031649",
		ToolId = "Boombox"
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
		Title = "Gravity Coil",
		IsPremium = false,
		Price = 750,
		Thumbnail = "rbxassetid://78073594661667",
		ToolId = "GravityCoil"
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
		ProductId = 0,
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
	{
		Title = "BoomBox",
		IsPremium = false,
		Price = 200,
		Thumbnail = "rbxassetid://124949563487240",
		ToolId = "BoomBox"
	},
}
ShopConfig.MoneyPacks = {
	{
		Title = "Starter Pack",
		Price = 50,
		Thumbnail = "rbxassetid://139931791718495",
		MoneyReward = 1000,
		ProductId = 3465225709
	},
	{
		Title = "Medium Pack",
		Price = 150,
		Thumbnail = "rbxassetid://89707390656568",
		MoneyReward = 5000,
		ProductId = 3465225908
	},
	{
		Title = "Large Pack",
		Price = 400,
		Thumbnail = "rbxassetid://89707390656568",
		MoneyReward = 15000,
		ProductId = 3465226043
	},
	{
		Title = "Mega Pack",
		Price = 1000,
		Thumbnail = "rbxassetid://101242002582412",
		MoneyReward = 50000,
		ProductId = 3465226176
	},
}

return ShopConfig
