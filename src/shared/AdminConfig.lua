local AdminConfig = {}

AdminConfig.Admins = {
	8714136305,
	987654321,
}

function AdminConfig:IsAdmin(player)
	for _, adminId in pairs(self.Admins) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

AdminConfig.BannedUsers = {}

function AdminConfig:IsBanned(userId)
	return table.find(self.BannedUsers, userId) ~= nil
end

function AdminConfig:BanUser(userId)
	if not self:IsBanned(userId) then
		table.insert(self.BannedUsers, userId)
		return true
	end
	return false
end

function AdminConfig:UnbanUser(userId)
	local index = table.find(self.BannedUsers, userId)
	if index then
		table.remove(self.BannedUsers, index)
		return true
	end
	return false
end

return AdminConfig