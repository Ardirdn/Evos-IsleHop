local SoundConfig = {}

SoundConfig.Sounds = {

	Throw = {
		SoundIds = {"rbxassetid://72614621153419"},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 300,
	},

	WaterSplash = {
		SoundIds = {
			"rbxassetid://102170042537651",
			"rbxassetid://106670898258799"
		},
		Volume = 2,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 300,
	},

	FishBite = {
		SoundIds = {
			"rbxassetid://79388838171139",
		},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 200,
	},

	Pulling = {
		SoundIds = {
			"rbxassetid://108565467299731",
			"rbxassetid://78925789186141"
		},
		Volume = 1,
		Looped = true,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 200,
	},

	FishCaught = {
		SoundIds = {
			"rbxassetid://125198403969591",
			"rbxassetid://116854594672292",
			"rbxassetid://113248338519660"
		},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 200,
	},

	Transaction = {
		SoundIds = {"rbxassetid://87187038402856"},
		Volume = 0.6,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 50,
	},

	UIOpen = {
		SoundIds = {"rbxassetid://6895079853"},
		Volume = 0.3,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 50,
	},

	UIClose = {
		SoundIds = {"rbxassetid://6895079853"},
		Volume = 0.3,
		Looped = false,
		PlaybackSpeed = 1.2,
		RollOffMaxDistance = 50,
	},

	ButtonClick = {
		SoundIds = {"rbxassetid://6895079853"},
		Volume = 0.2,
		Looped = false,
		PlaybackSpeed = 1.5,
		RollOffMaxDistance = 50,
	},

	Bobbing = {
		SoundIds = {"rbxassetid://9114074523"},
		Volume = 0.3,
		Looped = false,
		PlaybackSpeed = 1,
		RollOffMaxDistance = 40,
	},

	Retrieve = {
		SoundIds = {"rbxassetid://72614621153419"},
		Volume = 1,
		Looped = false,
		PlaybackSpeed = 1.2,
		RollOffMaxDistance = 100,
	},
}

local ContentProvider = game:GetService("ContentProvider")

local function preloadAllSounds()
	local soundsToPreload = {}

	for category, soundData in pairs(SoundConfig.Sounds) do
		if soundData.SoundIds then
			for _, soundId in ipairs(soundData.SoundIds) do
				table.insert(soundsToPreload, soundId)
			end
		end
	end

	task.spawn(function()
		local startTime = tick()

		ContentProvider:PreloadAsync(soundsToPreload)

		local elapsed = tick() - startTime
	end)
end

preloadAllSounds()

function SoundConfig.GetRandomSoundId(category)
	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end

	local soundIds = soundData.SoundIds
	if #soundIds == 0 then
		return nil
	end

	return soundIds[math.random(1, #soundIds)]
end

function SoundConfig.GetSoundConfig(category)
	return SoundConfig.Sounds[category]
end

function SoundConfig.CreateSound(category, parent)
	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = "Sound_" .. category
	sound.SoundId = SoundConfig.GetRandomSoundId(category)
	sound.Volume = soundData.Volume
	sound.Looped = soundData.Looped
	sound.PlaybackSpeed = soundData.PlaybackSpeed or 1
	sound.RollOffMaxDistance = soundData.RollOffMaxDistance or 100

	if parent then
		sound.Parent = parent
	end

	return sound
end

function SoundConfig.PlaySoundAtPosition(category, position)
	local SoundService = game:GetService("SoundService")

	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end

	local tempPart = Instance.new("Part")
	tempPart.Name = "SoundEmitter_" .. category
	tempPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tempPart.Position = position
	tempPart.Anchored = true
	tempPart.CanCollide = false
	tempPart.Transparency = 1
	tempPart.Parent = workspace

	local sound = SoundConfig.CreateSound(category, tempPart)
	if sound then
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound:Play()

		if not soundData.Looped then
			task.delay(sound.TimeLength + 0.5, function()
				if tempPart and tempPart.Parent then
					tempPart:Destroy()
				end
			end)
		end

		return sound, tempPart
	end

	return nil, nil
end

function SoundConfig.PlayLocalSound(category)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	if not player then return nil end

	local soundData = SoundConfig.Sounds[category]
	if not soundData then
		warn("[SOUND CONFIG] Unknown sound category:", category)
		return nil
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	local soundContainer = playerGui:FindFirstChild("SoundContainer")
	if not soundContainer then
		soundContainer = Instance.new("ScreenGui")
		soundContainer.Name = "SoundContainer"
		soundContainer.ResetOnSpawn = false
		soundContainer.Parent = playerGui
	end

	local sound = SoundConfig.CreateSound(category, soundContainer)
	if sound then

		sound.RollOffMode = Enum.RollOffMode.Linear
		sound.RollOffMaxDistance = 0
		sound:Play()

		if not soundData.Looped then
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end

		return sound
	end

	return nil
end

function SoundConfig.StopSound(sound)
	if sound and sound:IsA("Sound") then
		sound:Stop()
		sound:Destroy()
	end
end

return SoundConfig
