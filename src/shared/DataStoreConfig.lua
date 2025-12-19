local DataStoreConfig = {}

DataStoreConfig.VERSION = "v1002"

DataStoreConfig.PlayerData = "PlayersData_" .. DataStoreConfig.VERSION

DataStoreConfig.Leaderboards = {
    Summit = "SummitLeaderboard_" .. DataStoreConfig.VERSION,
    Speedrun = "SpeedrunLeaderboard_" .. DataStoreConfig.VERSION,
    Playtime = "PlaytimeLeaderboard_" .. DataStoreConfig.VERSION,
    Donation = "DonationLeaderboard_" .. DataStoreConfig.VERSION,
}

DataStoreConfig.VIPStatus = "VIPStatus_" .. DataStoreConfig.VERSION
DataStoreConfig.AuraData = "AuraData_" .. DataStoreConfig.VERSION
DataStoreConfig.RedeemCodes = "RedeemCodes_" .. DataStoreConfig.VERSION
DataStoreConfig.GlobalEvents = "GlobalEvents_" .. DataStoreConfig.VERSION
DataStoreConfig.AdminLogs = "AdminLogs_" .. DataStoreConfig.VERSION
DataStoreConfig.AdminList = "AdminList_" .. DataStoreConfig.VERSION
DataStoreConfig.BannedPlayers = "BannedPlayers_" .. DataStoreConfig.VERSION

DataStoreConfig.Legacy = {
    SummitLeaderboard = "Summits",
    DonationLeaderboard = "Donations",
    PlaytimeLeaderboard = "TopTimePlayed",

    Wings = "FlyTogetherWingsStatus_V2",
}

DataStoreConfig.AutoSaveInterval = 300
DataStoreConfig.MaxRetries = 3
DataStoreConfig.RetryDelay = 1

function DataStoreConfig:GetVersion()
    return self.VERSION
end

function DataStoreConfig:GetAllNames()
    return {
        PlayerData = self.PlayerData,
        SummitLeaderboard = self.Leaderboards.Summit,
        SpeedrunLeaderboard = self.Leaderboards.Speedrun,
        PlaytimeLeaderboard = self.Leaderboards.Playtime,
        DonationLeaderboard = self.Leaderboards.Donation,
    }
end

function DataStoreConfig:PrintInfo()
end

return DataStoreConfig
