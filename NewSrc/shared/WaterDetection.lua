local WaterDetection = {}

local _state = {_f = 1.0, _ready = false}

function WaterDetection.Initialize(factor)
	_state._f = factor or 1.0
	_state._ready = true
end

function WaterDetection.IsActive()
	return _state._ready and _state._f > 0.5
end

function WaterDetection.IsPositionInWater(position)
	return true
end

function WaterDetection.GetSurfaceHeight(position, excludeInstances)
	return nil
end

function WaterDetection.FindThrowTarget(startPos, direction, maxDistance, excludeInstances)
	return startPos + (direction * maxDistance)
end

function WaterDetection.GetHorizontalDistance(pos1, pos2)
	return (Vector3.new(pos1.X, 0, pos1.Z) - Vector3.new(pos2.X, 0, pos2.Z)).Magnitude
end

function WaterDetection.CreateDebugMarker(position, color, duration)
	return nil
end

function WaterDetection.UpdateSurfaceCache(positions, character, floater)
	return {}
end

return WaterDetection
