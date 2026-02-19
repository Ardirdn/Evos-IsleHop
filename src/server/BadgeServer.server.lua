-- BadgeServer.server.lua
-- Memberikan badge reward berdasarkan jumlah summit yang dicapai player
-- Badge diberikan saat join (untuk yang sudah punya summit) dan saat summit baru
-- TODO: Hapus print badge status setelah testing selesai

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ⚠️ PENTING: Badge TIDAK BISA diberikan di Studio!
-- AwardBadge hanya bekerja di Live Game (Published Game).
-- Di Studio, AwardBadge akan return false/nil tanpa error — ini NORMAL.
local IS_STUDIO = RunService:IsStudio()
if IS_STUDIO then
	warn("[BADGE] ⚠️ RUNNING IN STUDIO — Badge TIDAK akan masuk inventory!")
	warn("[BADGE] ⚠️ AwardBadge hanya bekerja di Live Published Game.")
	warn("[BADGE] ⚠️ Test di live game untuk memastikan badge diterima player.")
end

-- ============================================================
-- KONFIGURASI BADGE
-- Format: { threshold = jumlah_summit_minimum, badgeId = id_badge, name = nama_badge }
-- Diurutkan dari kecil ke besar
-- ============================================================
local SUMMIT_BADGES = {
	{ threshold = 1,   badgeId = 3584919529592726, name = "1 Summit"   },
	{ threshold = 3,   badgeId = 4157069040307325, name = "3 Summit"   },
	{ threshold = 5,   badgeId = 3525174999759342, name = "5 Summit"   },
	{ threshold = 10,  badgeId = 3790912906753996, name = "10 Summit"  },
	{ threshold = 20,  badgeId = 292586350935433,  name = "20 Summit"  },
	{ threshold = 50,  badgeId = 3689808869795336, name = "50 Summit"  },
	{ threshold = 75,  badgeId = 3248171284767144, name = "75 Summit"  },
	{ threshold = 100, badgeId = 2519792505747373, name = "100 Summit" },
}

-- ============================================================
-- FUNGSI UTAMA
-- ============================================================

-- Print status badge lengkap untuk player (untuk debugging)
local function printBadgeStatus(player, totalSummits)
	print(string.format("\n========================================"))
	print(string.format("[BADGE STATUS] Player: %s | Summit: %d", player.Name, totalSummits))
	print(string.format("========================================"))
	for _, badgeData in ipairs(SUMMIT_BADGES) do
		local eligible = totalSummits >= badgeData.threshold
		local statusIcon = eligible and "✅ LAYAK" or "❌ BELUM"
		local hasBadge = false
		if eligible then
			local success, result = pcall(function()
				return BadgeService:UserHasBadgeAsync(player.UserId, badgeData.badgeId)
			end)
			hasBadge = success and result or false
		end
		local ownedText = eligible and (hasBadge and " [SUDAH PUNYA]" or " [BELUM PUNYA - AKAN DIBERIKAN]") or ""
		print(string.format("  [%s] Badge '%s' (ID: %d)%s",
			statusIcon, badgeData.name, badgeData.badgeId, ownedText))
		task.wait(0.05) -- kecil agar tidak throttle
	end
	print(string.format("========================================\n"))
end

-- Cek dan berikan semua badge yang layak berdasarkan totalSummits
-- Digunakan untuk: inisialisasi join, perubahan dari admin, atau summit normal
local function awardEligibleBadges(player, totalSummits, source)
	if not player or not player.Parent then return end
	if not totalSummits or totalSummits <= 0 then return end

	source = source or "unknown"
	local awarded = 0

	for _, badgeData in ipairs(SUMMIT_BADGES) do
		if totalSummits >= badgeData.threshold then
			-- Cek apakah player sudah punya badge ini (hindari spam API)
			local checkSuccess, hasBadge = pcall(function()
				return BadgeService:UserHasBadgeAsync(player.UserId, badgeData.badgeId)
			end)

			if checkSuccess and not hasBadge then
				-- Berikan badge
				local awardSuccess, awardResult = pcall(function()
					return BadgeService:AwardBadge(player.UserId, badgeData.badgeId)
				end)

				if awardSuccess then
					-- awardResult = true  → badge berhasil diberikan (live game)
					-- awardResult = false → badge sudah dimiliki, atau Studio (tidak masuk inventory)
					-- awardResult = nil   → kemungkinan error silent
					if awardResult == true then
						awarded = awarded + 1
						print(string.format(
							"[BADGE] ✅ %s mendapat badge '%s'! (ID: %d) [source: %s]",
							player.Name, badgeData.name, badgeData.badgeId, source
						))
					elseif IS_STUDIO then
						awarded = awarded + 1 -- hitung tetap untuk tracking
						print(string.format(
							"[BADGE] 🟡 STUDIO: Badge '%s' dipanggil untuk %s (tidak masuk inventory di Studio) [source: %s]",
							badgeData.name, player.Name, source
						))
					else
						-- Di live game tapi return false = sudah punya (race condition dengan cek awal)
						print(string.format(
							"[BADGE] ℹ️ %s sudah punya badge '%s' (double-check) [source: %s]",
							player.Name, badgeData.name, source
						))
					end
				else
					warn(string.format(
						"[BADGE] ❌ Gagal memberikan badge '%s' ke %s: %s",
						badgeData.name, player.Name, tostring(awardResult)
					))
				end

				-- Jeda kecil antar award untuk menghindari rate limit
				task.wait(0.1)

			elseif not checkSuccess then
				warn(string.format(
					"[BADGE] ⚠️ Gagal cek badge '%s' untuk %s: %s",
					badgeData.name, player.Name, tostring(hasBadge)
				))
			end
		end
	end

	if awarded > 0 then
		if IS_STUDIO then
			print(string.format("[BADGE] 🟡 STUDIO: %s — %d badge dipanggil (tidak masuk inventory). [source: %s]", player.Name, awarded, source))
		else
			print(string.format("[BADGE] %s total mendapat %d badge baru. [source: %s]", player.Name, awarded, source))
		end
	end
end

-- ============================================================
-- INISIALISASI SAAT PLAYER JOIN
-- Cek summit yang sudah ada, print status, dan berikan badge yang layak
-- ============================================================
local function initializeBadgesForPlayer(player)
	-- Tunggu PlayerStats tersedia (dibuat oleh CheckpointSystem)
	local playerStats = player:WaitForChild("PlayerStats", 30)
	if not playerStats then
		warn(string.format("[BADGE] PlayerStats tidak ditemukan untuk %s", player.Name))
		return
	end

	local summitValue = playerStats:WaitForChild("Summit", 10)
	if not summitValue then
		warn(string.format("[BADGE] Summit value tidak ditemukan untuk %s", player.Name))
		return
	end

	local currentSummits = summitValue.Value
	print(string.format("[BADGE] 🔍 Inisialisasi badge untuk %s (Summit: %d)", player.Name, currentSummits))

	-- ✅ PRINT STATUS BADGE LENGKAP (hapus setelah testing)
	task.spawn(function()
		printBadgeStatus(player, currentSummits)
	end)

	-- Berikan badge yang belum dimiliki berdasarkan summit saat ini
	if currentSummits > 0 then
		task.spawn(function()
			awardEligibleBadges(player, currentSummits, "join-init")
		end)
	end

	-- ============================================================
	-- LISTEN perubahan summit (dari summit normal MAUPUN dari admin)
	-- AdminServer mengubah PlayerStats.Summit.Value langsung (line 954)
	-- CheckpointSystem juga mengubah PlayerStats.Summit.Value (line 1094)
	-- Jadi satu listener ini menangkap KEDUANYA
	-- ============================================================
	summitValue.Changed:Connect(function(newValue)
		if not player or not player.Parent then return end
		if not newValue or newValue <= 0 then return end

		print(string.format(
			"[BADGE] 📊 Summit %s berubah menjadi %d — mengecek badge...",
			player.Name, newValue
		))

		task.spawn(function()
			awardEligibleBadges(player, newValue, "summit-changed")
		end)
	end)
end

-- ============================================================
-- KONEKSI EVENT PLAYER
-- ============================================================
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		initializeBadgesForPlayer(player)
	end)
end)

-- Handle player yang sudah join sebelum script ini ready (race condition fix)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		initializeBadgesForPlayer(player)
	end)
end

print("[BADGE] ✅ BadgeServer siap! Summit badge system aktif.")
print("[BADGE] Badge terdaftar:")
for _, b in ipairs(SUMMIT_BADGES) do
	print(string.format("  - %s (threshold: %d, ID: %d)", b.name, b.threshold, b.badgeId))
end
