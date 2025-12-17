local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
