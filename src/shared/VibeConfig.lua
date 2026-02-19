--[[
    VIBE CONFIG
    Configuration untuk lighting themes
    
    Skybox harus disimpan di ReplicatedStorage > Skyboxes
    Dengan nama sesuai yang ada di config
]]

local VibeConfig = {}

-- ✅ LIGHTING THEMES
VibeConfig.Themes = {
	Siang = {
		-- Lighting Properties
		TimeOfDay = "9:00:00",
		GeographicLatitude = 0,
		Ambient = Color3.fromHex("#97aabd"),
		Brightness = 3,
		ExposureCompensation = 1,
		OutdoorAmbient = Color3.fromHex("#e2ab87"),
		ColorShift_Top = Color3.fromHex("#e6720d"),

		-- Atmosphere Properties
		AtmosphereDensity = 0.2,
		AtmosphereOffset = 0.078,

		-- Skybox (from ReplicatedStorage.Skyboxes)
		Skybox = "SiangSkybox",

		-- Display
		Icon = "☀️",
		DisplayName = "Siang",
		Description = "Suasana cerah di pagi/siang hari"
	},

	Sore = {
		-- Lighting Properties
		TimeOfDay = "13:00:00",
		GeographicLatitude = 0,
		Ambient = Color3.fromHex("#876441"),
		Brightness = 1.5,
		ExposureCompensation = 1.58,
		OutdoorAmbient = Color3.fromHex("#e2ab87"),
		ColorShift_Top = Color3.fromHex("#e6720d"),

		-- Atmosphere Properties
		AtmosphereDensity = 0.259,
		AtmosphereOffset = 0.078,

		-- Skybox (from ReplicatedStorage.Skyboxes)
		Skybox = "SoreSkybox",

		-- Display
		Icon = "🌅",
		DisplayName = "Sore",
		Description = "Suasana senja yang hangat"
	},

	Malam = {
		-- Lighting Properties
		TimeOfDay = "15:00:00",
		GeographicLatitude = 344,
		Ambient = Color3.fromHex("#876441"),
		Brightness = 1.5,
		ExposureCompensation = 1,
		OutdoorAmbient = Color3.fromHex("#5582e2"),
		ColorShift_Top = Color3.fromHex("#0e9be6"),

		-- Atmosphere Properties
		AtmosphereDensity = 0.4,
		AtmosphereOffset = 0.078,

		-- Skybox (from ReplicatedStorage.Skyboxes)
		Skybox = "MalamSkybox",

		-- Display
		Icon = "🌙",
		DisplayName = "Malam",
		Description = "Suasana malam yang tenang"
	},
}

-- ✅ THEME ORDER (Order tombol di UI)
VibeConfig.ThemeOrder = {"Siang", "Sore", "Malam"}

-- ✅ DEFAULT THEME
VibeConfig.DefaultTheme = "Siang"

return VibeConfig
