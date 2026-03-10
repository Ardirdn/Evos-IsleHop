-- LocalScript: taruh di dalam DialogueGui (StarterGui > DialogueGui)
-- ProximityPrompt DIBUAT oleh ServerScript (DialogueNPC_ServerScript)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera

print("[DIALOGUE CLIENT] Script mulai berjalan...")

-- ===================== REFERENSI GUI =====================
local gui = script.Parent

local bgPanel = gui:WaitForChild("BGPanel", 10)
if not bgPanel then warn("[DIALOGUE CLIENT] ❌ BGPanel tidak ditemukan!") return end

local dialoguePanel = gui:WaitForChild("DialoguePanel", 10)
if not dialoguePanel then warn("[DIALOGUE CLIENT] ❌ DialoguePanel tidak ditemukan!") return end

local buttonsFrame = dialoguePanel:WaitForChild("Buttons", 10)
if not buttonsFrame then warn("[DIALOGUE CLIENT] ❌ Buttons tidak ditemukan!") return end

local nextButton = buttonsFrame:WaitForChild("NextButton", 10)
if not nextButton then warn("[DIALOGUE CLIENT] ❌ NextButton tidak ditemukan!") return end

local skipButton = buttonsFrame:WaitForChild("SkipButton", 10)
if not skipButton then warn("[DIALOGUE CLIENT] ❌ SkipButton tidak ditemukan!") return end

local dialogueTextPanel = dialoguePanel:WaitForChild("DialogueTextPanel", 10)
if not dialogueTextPanel then warn("[DIALOGUE CLIENT] ❌ DialogueTextPanel tidak ditemukan!") return end

local dialogueText = dialogueTextPanel:WaitForChild("DialogueText", 10)
if not dialogueText then warn("[DIALOGUE CLIENT] ❌ DialogueText tidak ditemukan!") return end

local dialogueLabel = dialogueText:WaitForChild("DialogueLabel", 10)
if not dialogueLabel then warn("[DIALOGUE CLIENT] ❌ DialogueLabel tidak ditemukan!") return end

print("[DIALOGUE CLIENT] ✅ Semua referensi GUI ditemukan")

-- ===================== REFERENSI NPC =====================
local npcFolder = workspace:WaitForChild("DialogueNPC", 10)
if not npcFolder then warn("[DIALOGUE CLIENT] ❌ Folder DialogueNPC tidak ditemukan!") return end

local npcModel = npcFolder:WaitForChild("Kakak NPC", 10)
if not npcModel then warn("[DIALOGUE CLIENT] ❌ Model 'Kakak NPC' tidak ditemukan!") return end

local camPosPart = npcModel:WaitForChild("CamPos", 10)
if not camPosPart then warn("[DIALOGUE CLIENT] ❌ CamPos tidak ditemukan di NPC!") return end

print("[DIALOGUE CLIENT] ✅ NPC dan CamPos ditemukan")

-- ===================== DATA DIALOGUE =====================
local dialogues = {
	"HALOOO!!!",
	"Gas NgOBBYburit Bareng Aku Yaa.",
	"Sebelum Main, Jangan Lupa Baca Detail Challengenya Di Banner Belakang Aku.",
	"Selamat NgOBBYburit Dan Kumpulin Extra AXIS COINS Sebanyak Banyaknyaaaa",
}

-- ===================== KAMERA CONFIG =====================
-- Sudut mendongak ke atas setelah lookAt ke NPC (derajat, positif = lebih ke atas)
local CAMERA_PITCH_UP_DEG = 30

-- ===================== NPC ANIM CONFIG =====================
-- Animasi dimainkan secara LOKAL saja (hanya player yang sedang dialogue yang melihat)
local NPC_ANIM_IDLE_ID  = "rbxassetid://507766388"  -- Idle NPC
local NPC_ANIM_WAVE_ID  = "rbxassetid://507770239"  -- Wave (saat awal dialogue)

-- ===================== STATE =====================
local isDialogueOpen = false
local currentIndex = 1
local isTyping = false
local typingThread = nil
local originalCameraType = nil
local originalCameraSubject = nil
local activePrompt = nil

-- State animasi NPC (lokal)
local npcAnimator   = nil
local npcIdleTrack  = nil
local npcWaveTrack  = nil
local waveStoppedConn = nil  -- koneksi Stopped wave agar tidak double-connect

-- ===================== HIDE / SHOW CHARACTER (SEMUA PLAYER) =====================
-- Menyimpan per character → { part → transparency }
local hiddenCharacters = {} -- [character] = { [part] = transparency }

-- Helper: apakah part ini boleh di-hide
local function isSafeToHide(part)
	if part.Name == "HumanoidRootPart" then return false end
	return true
end

-- Hide satu character (lokal only, transparansi 1)
local function hideCharacter(char)
	if hiddenCharacters[char] then return end -- sudah di-hide
	local saved = {}

	for _, desc in ipairs(char:GetDescendants()) do
		if (desc:IsA("BasePart") or desc:IsA("MeshPart") or desc:IsA("UnionOperation")) then
			if isSafeToHide(desc) then
				saved[desc] = desc.Transparency
				desc.Transparency = 1
			end
		elseif desc:IsA("Decal") or desc:IsA("Texture") then
			saved[desc] = desc.Transparency
			desc.Transparency = 1
		end
	end

	-- Juga hide BillboardGui (overhead title) yang ada di Head
	local head = char:FindFirstChild("Head")
	if head then
		local billboard = head:FindFirstChildOfClass("BillboardGui")
		if billboard then
			saved[billboard] = billboard.Enabled and 1 or 0
			billboard.Enabled = false
		end
	end

	hiddenCharacters[char] = saved
end

-- Restore satu character ke transparency semula
local function showCharacter(char)
	local saved = hiddenCharacters[char]
	if not saved then return end

	for obj, originalTrans in pairs(saved) do
		if obj and obj.Parent then
			if obj:IsA("BillboardGui") then
				obj.Enabled = true
			else
				obj.Transparency = originalTrans
			end
		end
	end

	hiddenCharacters[char] = nil
end

-- Hide SEMUA player (lokal only)
local function hideAllPlayers()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			hideCharacter(p.Character)
		end
	end
	-- Sembunyikan juga title billboard via _G.SetHideTitles jika tersedia
	if _G.SetHideTitles then
		_G.SetHideTitles(true)
		print("[DIALOGUE CLIENT] ✅ Semua title di-hide via _G.SetHideTitles")
	end
	print("[DIALOGUE CLIENT] ✅ Semua karakter player disembunyikan")
end

-- Restore SEMUA player
local function showAllPlayers()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			showCharacter(p.Character)
		end
	end
	-- Tampilkan kembali title billboard
	if _G.SetHideTitles then
		_G.SetHideTitles(false)
		print("[DIALOGUE CLIENT] ✅ Semua title di-restore via _G.SetHideTitles")
	end
	print("[DIALOGUE CLIENT] ✅ Semua karakter player ditampilkan kembali")
end

-- ===================== KONTROL KARAKTER =====================
local function setCharacterControl(enabled)
	local ok, PlayerModule = pcall(require, player.PlayerScripts:WaitForChild("PlayerModule"))
	if not ok then
		warn("[DIALOGUE CLIENT] ⚠️ Gagal load PlayerModule:", PlayerModule)
		return
	end
	local controls = PlayerModule:GetControls()
	if enabled then
		controls:Enable()
	else
		controls:Disable()
	end
end

-- ===================== RESTORE KAMERA =====================
-- Fungsi ini memastikan kamera kembali ke normal player camera dengan aman
local function restoreCamera()
	-- Tentukan target tipe (pastikan bukan Scriptable yang tersimpan secara tidak sengaja)
	local targetType = originalCameraType
	if targetType == nil or targetType == Enum.CameraType.Scriptable then
		targetType = Enum.CameraType.Custom
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	-- LANGKAH 1: Set CameraSubject dulu
	if humanoid then
		camera.CameraSubject = humanoid
	end

	-- LANGKAH 2: Ganti tipe kamera
	camera.CameraType = targetType

	-- LANGKAH 3: Tunggu beberapa frame agar Roblox camera module wake up
	task.wait(0.1)

	-- LANGKAH 4: Re-assert ulang (kadang camera module butuh dipancing lagi)
	if humanoid then
		camera.CameraSubject = humanoid
	end
	camera.CameraType = targetType

	-- LANGKAH 5: Tunggu 1 frame lagi lalu pastikan sekali lagi
	task.wait()
	if humanoid then
		camera.CameraSubject = humanoid
	end

	print("[DIALOGUE CLIENT] ✅ Kamera dikembalikan →", tostring(camera.CameraType), "| Subject:", tostring(camera.CameraSubject))
end

-- ===================== NPC ANIMASI (LOKAL ONLY) =====================
-- Load animator NPC sekali, lalu simpan track agar tidak load ulang
local function loadNPCAnimations()
	-- Cari Humanoid di NPC (bisa langsung atau di dalam model)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
			or npcModel:FindFirstChildWhichIsA("Humanoid", true)
	if not humanoid then
		warn("[DIALOGUE CLIENT] ⚠️ Humanoid tidak ditemukan di NPC, animasi dilewati")
		return false
	end

	-- Gunakan Animator yang ada, atau buat baru (lokal saja)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
		print("[DIALOGUE CLIENT] ℹ️ Animator dibuat secara lokal di NPC")
	end
	npcAnimator = animator

	-- Load Idle
	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = NPC_ANIM_IDLE_ID
	npcIdleTrack = animator:LoadAnimation(idleAnim)
	npcIdleTrack.Priority = Enum.AnimationPriority.Idle
	npcIdleTrack.Looped  = true

	-- Load Wave
	local waveAnim = Instance.new("Animation")
	waveAnim.AnimationId = NPC_ANIM_WAVE_ID
	npcWaveTrack = animator:LoadAnimation(waveAnim)
	npcWaveTrack.Priority = Enum.AnimationPriority.Action
	npcWaveTrack.Looped  = false

	print("[DIALOGUE CLIENT] ✅ Animasi NPC berhasil di-load (lokal)")
	return true
end

-- Mainkan wave → setelah selesai otomatis ke idle
local function playNPCWave()
	if not npcAnimator then
		if not loadNPCAnimations() then return end
	end

	-- Putus koneksi lama biar tidak double
	if waveStoppedConn then
		waveStoppedConn:Disconnect()
		waveStoppedConn = nil
	end

	-- Stop idle dulu agar tidak tumpang tindih
	if npcIdleTrack and npcIdleTrack.IsPlaying then
		npcIdleTrack:Stop(0.2)
	end

	-- Play wave
	if npcWaveTrack then
		npcWaveTrack:Play(0.2)
		print("[DIALOGUE CLIENT] 👋 NPC wave dimulai")

		-- Saat wave selesai → lanjut idle (selama dialogue masih terbuka)
		waveStoppedConn = npcWaveTrack.Stopped:Connect(function()
			waveStoppedConn:Disconnect()
			waveStoppedConn = nil
			if isDialogueOpen and npcIdleTrack then
				npcIdleTrack:Play(0.3)
				print("[DIALOGUE CLIENT] 🧍 NPC idle dimulai (setelah wave)")
			end
		end)
	end
end

-- Stop semua animasi NPC saat dialogue selesai
local function stopNPCAnimations()
	if waveStoppedConn then
		waveStoppedConn:Disconnect()
		waveStoppedConn = nil
	end
	if npcWaveTrack and npcWaveTrack.IsPlaying then
		npcWaveTrack:Stop(0.3)
	end
	if npcIdleTrack and npcIdleTrack.IsPlaying then
		npcIdleTrack:Stop(0.3)
	end
	print("[DIALOGUE CLIENT] ⏹️ NPC animasi dihentikan")
end

-- ===================== CLOSE DIALOGUE =====================
local function closeDialogue()
	if not isDialogueOpen then return end
	print("[DIALOGUE CLIENT] Menutup dialogue...")
	isDialogueOpen = false

	if typingThread then
		task.cancel(typingThread)
		typingThread = nil
	end
	isTyping = false

	-- Sembunyikan GUI
	bgPanel.Visible = false
	dialoguePanel.Visible = false

	-- Tampilkan kembali SEMUA karakter player
	showAllPlayers()

	-- ★ Kembalikan kamera dengan benar
	restoreCamera()

	-- Tampilkan kembali ProximityPrompt
	if activePrompt then
		activePrompt.Enabled = true
	end

	-- Nyalakan kembali kontrol
	setCharacterControl(true)

	-- Hentikan animasi NPC
	stopNPCAnimations()

	currentIndex = 1
	dialogueLabel.Text = ""
	print("[DIALOGUE CLIENT] ✅ Dialogue ditutup, kontrol & kamera dikembalikan")
end

-- ===================== TYPING EFFECT =====================
local function typeText(text)
	isTyping = true
	dialogueLabel.Text = ""

	typingThread = task.spawn(function()
		for i = 1, #text do
			if not isDialogueOpen then break end
			dialogueLabel.Text = string.sub(text, 1, i)
			task.wait(0.04)
		end
		isTyping = false
		typingThread = nil
	end)
end

-- ===================== SHOW DIALOGUE =====================
local function showDialogue(index)
	if index > #dialogues then
		print("[DIALOGUE CLIENT] Dialog habis, menutup...")
		closeDialogue()
		return
	end
	currentIndex = index
	print("[DIALOGUE CLIENT] Menampilkan dialog ke-" .. index)
	typeText(dialogues[index])
end

-- ===================== OPEN DIALOGUE =====================
local function openDialogue()
	if isDialogueOpen then return end
	print("[DIALOGUE CLIENT] Membuka dialogue...")
	isDialogueOpen = true
	currentIndex = 1

	-- JANGAN simpan camera type di sini!
	-- originalCameraType sudah disimpan di prompt.Triggered SEBELUM kamera diubah ke Scriptable.
	-- Kalau disimpan di sini, nilainya akan Scriptable (sudah diubah) → restore akan gagal!

	-- Sembunyikan SEMUA karakter player (lokal only)
	hideAllPlayers()

	-- Sembunyikan ProximityPrompt (lokal saja)
	if activePrompt then
		activePrompt.Enabled = false
	end

	-- Tampilkan GUI
	bgPanel.Visible = true
	dialoguePanel.Visible = true

	-- Matikan kontrol
	setCharacterControl(false)

	-- Play wave NPC lokal → lanjut idle otomatis
	playNPCWave()

	showDialogue(1)
end

-- ===================== TOMBOL NEXT =====================
nextButton.MouseButton1Click:Connect(function()
	if not isDialogueOpen then return end
	if isTyping then
		if typingThread then
			task.cancel(typingThread)
			typingThread = nil
		end
		isTyping = false
		dialogueLabel.Text = dialogues[currentIndex]
	else
		showDialogue(currentIndex + 1)
	end
end)

-- ===================== TOMBOL SKIP =====================
skipButton.MouseButton1Click:Connect(function()
	if not isDialogueOpen then return end
	closeDialogue()
end)

-- ===================== DETEKSI PROXIMITY PROMPT =====================
local function connectPrompt(prompt)
	print("[DIALOGUE CLIENT] ✅ ProximityPrompt terhubung di:", prompt.Parent.Name)
	activePrompt = prompt

	prompt.Triggered:Connect(function()
		if isDialogueOpen then return end
		print("[DIALOGUE CLIENT] Prompt di-trigger! Menunggu 1 detik...")

		task.wait(1)

		-- Simpan camera type sebelum diubah ke Scriptable
		originalCameraType = camera.CameraType
		originalCameraSubject = camera.CameraSubject

		-- Pindahkan kamera ke CamPos, lalu tilt ke atas sebesar CAMERA_PITCH_UP_DEG
		camera.CameraType = Enum.CameraType.Scriptable
		local camPosition = camPosPart.Position
		local npcCenter = npcModel:GetBoundingBox().Position
		-- CFrame.lookAt dulu, lalu putar pitch ke atas (X negatif = mendongak)
		camera.CFrame = CFrame.lookAt(camPosition, npcCenter)
			* CFrame.Angles(math.rad(-CAMERA_PITCH_UP_DEG), 0, 0)
		print("[DIALOGUE CLIENT] ✅ Kamera dipindahkan ke CamPos (pitch +" .. CAMERA_PITCH_UP_DEG .. "°)")

		openDialogue()
	end)
end

local function findAndConnectPrompt()
	print("[DIALOGUE CLIENT] Mencari ProximityPrompt di NPC...")

	for _, desc in ipairs(npcModel:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			connectPrompt(desc)
			return
		end
	end

	print("[DIALOGUE CLIENT] ProximityPrompt belum ada, menunggu ServerScript membuatnya...")
	npcModel.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then
			connectPrompt(desc)
		end
	end)
end

-- ===================== INISIALISASI =====================
gui.Enabled = true
bgPanel.Visible = false
dialoguePanel.Visible = false

-- Update referensi character saat respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar

	-- Apabila karakter baru muncul saat dialogue terbuka, paksa close
	if isDialogueOpen then
		isDialogueOpen = false
		bgPanel.Visible = false
		dialoguePanel.Visible = false
		hiddenCharacters = {} -- reset cache karena character lama sudah hilang
		currentIndex = 1
		dialogueLabel.Text = ""

		-- Restore camera dan kontrol
		task.wait(0.5) -- tunggu karakter baru siap
		character = newChar
		restoreCamera()
		setCharacterControl(true)
	end
end)

findAndConnectPrompt()
print("[DIALOGUE CLIENT] ✅ Script selesai diinisialisasi")
