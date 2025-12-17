local ShopConfig = {}

ShopConfig.Gamepasses = {
	{
		Name = "VIP",
		Price = 99,
		Thumbnail = "rbxassetid://7733964640",
		GamepassId = 1415252923,
		Description = "Unlock VIP features and exclusive perks!"
	},
	{
		Name = "VVIP",
		Price = 150,
		Thumbnail = "rbxassetid://7733964640",
		GamepassId = 1628429869,
		Description = "Ultimate VIP with premium benefits!"
	},
	{
        Name = "x2 Summit",
        DisplayName = "x2 Summit",
        Description = "Dapatkan 2x lipat summit setiap mencapai puncak!",
        Price = 500,
		GamepassId = 1626461957,
        Thumbnail = "rbxassetid://0",
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
		Thumbnail = "rbxassetid://92031641833338",
		AuraId = "FireAura"
	},
	{
		Title = "Ice Aura",
		IsPremium = false,
		Price = 1500,
		Thumbnail = "rbxassetid://92031641833338",
		AuraId = "IceAura"
	},
	{
		Title = "Lightning Aura",
		IsPremium = false,
		Price = 2000,
		Thumbnail = "rbxassetid://92031641833338",
		AuraId = "LightningAura"
	},
	{
		Title = "Shadow Aura",
		IsPremium = false,
		Price = 2500,
		Thumbnail = "rbxassetid://92031641833338",
		AuraId = "ShadowAura"
	},
	{
		Title = "Rainbow Aura",
		IsPremium = true,
		Price = 100,
		ProductId = 3465227826,
		Thumbnail = "rbxassetid://92031641833338",
		AuraId = "RainbowAura"
	},
	{
		Title = "Galaxy Aura",
		IsPremium = true,
		Price = 250,
		ProductId = 3465227441,
		Thumbnail = "rbxassetid://92031641833338",
		AuraId = "GalaxyAura"
	},
}

ShopConfig.Tools = {
	{
		Title = "Speed Coil",
		IsPremium = false,
		Price = 75000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "SpeedCoil"
	},
	{
		Title = "Gravity Coil",
		IsPremium = false,
		Price = 50000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "GravityCoil"
	},
	{
		Title = "Double Coil",
		IsPremium = false,
		Price = 100000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "DoubleCoil"
	},
	{
		Title = "Flashlight",
		IsPremium = false,
		Price = 10000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "Flashlight"
	},
	{
		Title = "Sign Board",
		IsPremium = false,
		Price = 20000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "SignBoard"
	},
	{
		Title = "Summit Board",
		IsPremium = false,
		Price = 15000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "SummitBoard"
	},
	{
		Title = "Selfie Stick",
		IsPremium = false,
		Price = 5000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "SelfieStick"
	},
	{
		Title = "Money Gun",
		IsPremium = false,
		Price = 30000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "MoneyGun"
	},
	{
		Title = "Bubble Gun",
		IsPremium = false,
		Price = 35000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "BubbleGun"
	},
	{
		Title = "Snow Ball",
		IsPremium = false,
		Price = 25000,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "SnowBall"
	},
	{
		Title = "Boom Box",
		IsPremium = true,
		Price = 50,
		ProductId = 3477257119,
		Thumbnail = "rbxassetid://72190200747830",
		ToolId = "BoomBox"
	},
}

ShopConfig.MoneyPacks = {
	{
		Title = "Starter Pack",
		Price = 50,
		Thumbnail = "rbxassetid://132896526212507",
		MoneyReward = 1000,
		ProductId = 3476997700
	},
	{
		Title = "Medium Pack",
		Price = 150,
		Thumbnail = "rbxassetid://102815949637801",
		MoneyReward = 5000,
		ProductId = 3476998144
	},
	{
		Title = "Large Pack",
		Price = 400,
		Thumbnail = "rbxassetid://95239250209839",
		MoneyReward = 15000,
		ProductId = 3476998530
	},
	{
		Title = "Mega Pack",
		Price = 1000,
		Thumbnail = "rbxassetid://80206765993152",
		MoneyReward = 50000,
		ProductId = 3476998867
	},
}

return ShopConfig
