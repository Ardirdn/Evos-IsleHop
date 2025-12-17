local VibeConfig = {}

VibeConfig.Themes = {
    Siang = {

        TimeOfDay = "9:00:00",
        GeographicLatitude = 0,
        Ambient = Color3.fromHex("#97aabd"),
        Brightness = 3,
        ExposureCompensation = 1,
        OutdoorAmbient = Color3.fromHex("#e2ab87"),
        ColorShift_Top = Color3.fromHex("#e6720d"),

        AtmosphereDensity = 0.2,
        AtmosphereOffset = 0.078,

        Skybox = "SiangSkybox",

        Icon = "☀️",
        DisplayName = "Siang",
        Description = "Suasana cerah di pagi/siang hari"
    },

    Sore = {

        TimeOfDay = "13:00:00",
        GeographicLatitude = 0,
        Ambient = Color3.fromHex("#876441"),
        Brightness = 1.5,
        ExposureCompensation = 1.58,
        OutdoorAmbient = Color3.fromHex("#e2ab87"),
        ColorShift_Top = Color3.fromHex("#e6720d"),

        AtmosphereDensity = 0.259,
        AtmosphereOffset = 0.078,

        Skybox = "SoreSkybox",

        Icon = "🌅",
        DisplayName = "Sore",
        Description = "Suasana senja yang hangat"
    },

    Malam = {

        TimeOfDay = "15:00:00",
        GeographicLatitude = 344,
        Ambient = Color3.fromHex("#876441"),
        Brightness = 1.5,
        ExposureCompensation = 1,
        OutdoorAmbient = Color3.fromHex("#5582e2"),
        ColorShift_Top = Color3.fromHex("#0e9be6"),

        AtmosphereDensity = 0.4,
        AtmosphereOffset = 0.078,

        Skybox = "MalamSkybox",

        Icon = "🌙",
        DisplayName = "Malam",
        Description = "Suasana malam yang tenang"
    },
}

VibeConfig.ThemeOrder = {"Siang", "Sore", "Malam"}

VibeConfig.DefaultTheme = "Siang"

return VibeConfig
