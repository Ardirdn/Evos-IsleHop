-- EventManagerInit.server.lua
-- Pastikan EventManager (ModuleScript) di-require sedini mungkin
-- agar RemoteEvents-nya sudah siap sebelum script lain atau admin panel mengaksesnya.

local ok, err = pcall(function()
	require(script.Parent:WaitForChild("EventManager", 10))
end)

if ok then
	print("[EVENT MANAGER INIT] ✅ EventManager berhasil diinisialisasi")
else
	warn("[EVENT MANAGER INIT] ❌ Gagal inisialisasi EventManager:", err)
end
