-- Script (bukan LocalScript!)
-- Taruh di: ServerScriptService > DialogueNPCSetup
-- Tugasnya: membuat ProximityPrompt di NPC dari sisi Server

print("[DIALOGUE NPC] Script mulai berjalan...")

local workspace = game:GetService("Workspace")

-- Tunggu folder dan NPC
local npcFolder = workspace:WaitForChild("DialogueNPC", 10)
if not npcFolder then
	warn("[DIALOGUE NPC] ❌ Folder 'DialogueNPC' tidak ditemukan di Workspace!")
	return
end
print("[DIALOGUE NPC] ✅ Folder DialogueNPC ditemukan")

local npcModel = npcFolder:WaitForChild("Kaka AXIS", 10)
if not npcModel then
	warn("[DIALOGUE NPC] ❌ Model 'Kaka AXIS' tidak ditemukan di dalam DialogueNPC!")
	return
end
print("[DIALOGUE NPC] ✅ Model 'Kaka AXIS' ditemukan")

-- Debug: print semua children NPC
print("[DIALOGUE NPC] Children dari 'Kaka AXIS':")
for _, child in ipairs(npcModel:GetChildren()) do
	print("  -", child.Name, "(" .. child.ClassName .. ")")
end

-- Cari HumanoidRootPart
local rootPart = npcModel:FindFirstChild("HumanoidRootPart")

if not rootPart then
	warn("[DIALOGUE NPC] ⚠️ HumanoidRootPart tidak ditemukan, mencari Part pertama...")
	-- Fallback: cari BasePart apapun yang bukan CamPos
	for _, child in ipairs(npcModel:GetDescendants()) do
		if child:IsA("BasePart") and child.Name ~= "CamPos" then
			rootPart = child
			print("[DIALOGUE NPC] ✅ Menggunakan Part fallback:", child.Name)
			break
		end
	end
end

if not rootPart then
	warn("[DIALOGUE NPC] ❌ Tidak ada Part sama sekali di NPC! ProximityPrompt tidak bisa dibuat.")
	return
end

print("[DIALOGUE NPC] ✅ ProximityPrompt akan dipasang di Part:", rootPart.Name)

-- Hapus prompt lama kalau ada
local existing = rootPart:FindFirstChildOfClass("ProximityPrompt")
if existing then
	existing:Destroy()
	print("[DIALOGUE NPC] 🗑️ ProximityPrompt lama dihapus")
end

-- Buat ProximityPrompt
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Bicara"
prompt.ObjectText = ""
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Parent = rootPart

print("[DIALOGUE NPC] ✅ ProximityPrompt berhasil dibuat di:", rootPart:GetFullName())
print("[DIALOGUE NPC] Setup selesai!")
