local BoatConfig = {}

BoatConfig.Boats = {
	["BasicBoat"] = {
		DisplayName = "Perahu Nelayan",
		Price = 0,

		MaxSpeed = 12,
		MaxReverseSpeed = 5,
		Acceleration = 0.08,
		Deceleration = 0.015,
		BrakeForce = 0.2,

		TurnSpeed = 0.012,
		TurnSpeedAtMax = 0.006,

		FloatOffset = 2,

		WaveMultiplier = 3,
	},

}

BoatConfig.DefaultBoatStats = {
	DisplayName = "Boat",
	Price = 1000,
	MaxSpeed = 15,
	MaxReverseSpeed = 6,
	Acceleration = 0.1,
	Deceleration = 0.02,
	BrakeForce = 0.25,
	TurnSpeed = 0.015,
	TurnSpeedAtMax = 0.008,
	FloatOffset = 3,
	WaveMultiplier = 1.0,
}

BoatConfig.Physics = {
	DefaultWaterHeight = 24,
}

BoatConfig.Buoyancy = {
	Enabled = true,

	BuoyancyForce = 50000,
	BuoyancyDamping = 800,

	WaveEnabled = true,
	WaveAmplitude = 0.2,
	WaveFrequency = 0.12,

	SecondaryWaveEnabled = true,
	SecondaryWaveAmplitude = 0.08,
	SecondaryWaveFrequency = 0.2,

	RollEnabled = true,
	WaveRollAmplitude = 0.8,
	WaveRollFrequency = 0.1,
	TurnRollAmount = 3,

	PitchEnabled = true,
	AccelPitchAmount = 1.5,
	BrakePitchAmount = -1,
	WavePitchAmplitude = 0.6,
	WavePitchFrequency = 0.15,

	WaveBumpEnabled = true,
	WaveBumpChance = 0.005,
	WaveBumpAmount = 3,
	WaveBumpDuration = 0.5,
	WaveBumpMinSpeed = 3,

	SpeedWaveReduction = 0.4,
}

BoatConfig.BodyMovers = {
	GyroMaxTorque = Vector3.new(math.huge, math.huge, math.huge),
	GyroP = 5000,
	GyroD = 500,
	VelocityMaxForce = Vector3.new(math.huge, 0, math.huge),
	VelocityP = 1500,
	PositionMaxForce = Vector3.new(0, 50000, 0),
	PositionP = 5000,
	PositionD = 800,
}

BoatConfig.Folders = {
	BoatsFolder = "Boats",
	BoatAreaName = "BoatArea",
	DriverSeatName = "VehicleSeat",
}

BoatConfig.Prompt = {
	DriveActionText = "Drive",
	ObjectText = "Boat",
	HoldDuration = 0,
	MaxDistance = 10,
	RequiresLineOfSight = false,
}

BoatConfig.Camera = {
	AdjustOnEnter = true,
	MinZoom = 10,
	MaxZoom = 300,
	RestoreOnExit = true,
}

BoatConfig.Debug = {
	Enabled = false,
	ShowVelocity = false,
	ShowWaterHeight = false,
	ShowBuoyancy = false,
	ShowTilt = false,
}

function BoatConfig.GetBoatStats(boatName)
	return BoatConfig.Boats[boatName] or BoatConfig.DefaultBoatStats
end

return BoatConfig
