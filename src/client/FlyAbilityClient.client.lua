local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[FLY ABILITY INIT] Client initializer starting...")

local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
    warn("[FLY ABILITY INIT] Modules folder not found!")
    return
end

local FlyAbilityModule = Modules:WaitForChild("FlyAbility", 10)
if not FlyAbilityModule then
    warn("[FLY ABILITY INIT] FlyAbility module not found!")
    return
end

local FlyAbility = require(FlyAbilityModule)

print("[FLY ABILITY INIT] Client initialization complete!")