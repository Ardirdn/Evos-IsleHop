local DonateConfig = {}

DonateConfig.DonationThreshold = 1000
DonateConfig.GlobalNotificationThreshold = 500

DonateConfig.Packages = {
	{
		Title = "Starter",
		Description = "Support kecil",
		Amount = 10,
		ProductId = 3482521031,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(100, 149, 237)
	},
	{
		Title = "Bronze",
		Description = "Dukungan Bronze",
		Amount = 25,
		ProductId = 3482521169,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(205, 127, 50)
	},
	{
		Title = "Silver",
		Description = "Dukungan Silver",
		Amount = 50,
		ProductId = 3482521369,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(192, 192, 192)
	},
	{
		Title = "Gold",
		Description = "Dukungan Gold",
		Amount = 100,
		ProductId = 3482521479,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 215, 0)
	},
	{
		Title = "Platinum",
		Description = "Dukungan Platinum",
		Amount = 250,
		ProductId = 3482521764,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(229, 228, 226)
	},
	{
		Title = "Diamond",
		Description = "Dukungan Diamond",
		Amount = 500,
		ProductId = 3482522098,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(185, 242, 255)
	},
	{
		Title = "Master",
		Description = "Dukungan Master",
		Amount = 1000,
		ProductId = 3482522221,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(138, 43, 226)
	},
	{
		Title = "Champion",
		Description = "Dukungan Champion",
		Amount = 2500,
		ProductId = 3482522387,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 69, 0)
	},
	{
		Title = "Legend",
		Description = "Dukungan Legend",
		Amount = 5000,
		ProductId = 3482522774,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 0, 255)
	},
	{
		Title = "Mythic",
		Description = "Dukungan Mythic",
		Amount = 10000,
		ProductId = 3482522930,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 20, 147)
	},
	{
		Title = "Divine",
		Description = "Dukungan Divine",
		Amount = 25000,
		ProductId = 3482523090,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 255, 0)
	},
	{
		Title = "Supreme",
		Description = "Dukungan Supreme",
		Amount = 50000,
		ProductId = 3482523266,
		Thumbnail = "rbxassetid://7733992358",
		Color = Color3.fromRGB(255, 0, 0)
	},
}
DonateConfig.Colors = {
	Background = Color3.fromRGB(20, 20, 23),
	Panel = Color3.fromRGB(25, 25, 28),
	Header = Color3.fromRGB(30, 30, 33),
	Button = Color3.fromRGB(35, 35, 38),
	ButtonHover = Color3.fromRGB(45, 45, 48),
	Accent = Color3.fromRGB(70, 130, 255),
	AccentHover = Color3.fromRGB(90, 150, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 185),
	Border = Color3.fromRGB(50, 50, 55),
	Success = Color3.fromRGB(67, 181, 129),
	Premium = Color3.fromRGB(255, 215, 0),
}

DonateConfig.AnimationDuration = 0.3

return DonateConfig
