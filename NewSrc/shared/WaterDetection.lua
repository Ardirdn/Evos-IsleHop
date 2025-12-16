--[[
	WaterDetection Module (DISABLED/STUB)
	Water detection is disabled - fishing allowed anywhere
	This module is kept as a stub for compatibility
]]

local WaterDetection = {}

-- Runtime state
local _state = {_f = 1.0, _ready = false}

function WaterDetection.Initialize(factor)
	_state._f = factor or 1.0
	_state._ready = true
end

function WaterDetection.IsActive()
	return _state._ready and _state._f > 0.5
end

-- Always return true - fishing allowed anywhere
function WaterDetection.IsPositionInWater(position)
	return true
end

-- Get surface height (stub - returns nil)
function WaterDetection.GetSurfaceHeight(position, excludeInstances)
	return nil
end

-- Find target position for throw (simplified - just returns horizontal target)
function WaterDetection.FindThrowTarget(startPos, direction, maxDistance, excludeInstances)
	return startPos + (direction * maxDistance)
end

-- Check horizontal distance between two positions
function WaterDetection.GetHorizontalDistance(pos1, pos2)
	return (Vector3.new(pos1.X, 0, pos1.Z) - Vector3.new(pos2.X, 0, pos2.Z)).Magnitude
end

-- Create debug visualization (disabled - returns nil)
function WaterDetection.CreateDebugMarker(position, color, duration)
	return nil
end

-- Cache surface heights (disabled - returns empty table)
function WaterDetection.UpdateSurfaceCache(positions, character, floater)
	return {}
end

return WaterDetection
