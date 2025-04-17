-- SoundManager.lua (Client)
-- Handles playing sounds for the client

local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- Placeholder Sound IDs (Replace with better ones later)
local SOUND_IDS = {
	-- Weapon sounds
	MusketFire = "rbxassetid://184202799", -- Musket Fire sound (deeper boom)
	Reload = "rbxassetid://130968971",     -- Generic Gun Reload sound
	
	-- Multi-stage reload sounds
	PourPowder = "rbxassetid://9120232587", -- Pouring powder sound (placeholder)
	RamBullet = "rbxassetid://9114532333",  -- Ramrod sound (placeholder)
	PrimePan = "rbxassetid://7149333266",   -- Prime pan sound (placeholder)
	
	-- UI sounds
	ButtonClick = "rbxassetid://6732690176", -- UI button click
	MenuOpen = "rbxassetid://6732690176",    -- UI menu open
	
	-- Ambient sounds
	BattleAmbient = "rbxassetid://169202305" -- Distant battle sounds (placeholder)
}

-- Sound configuration
local SOUND_CONFIG = {
	MusketFire = {
		Volume = 1.0,
		PlaybackSpeed = 0.9, -- Slightly deeper sound
		RollOffMaxDistance = 300, -- Can hear shots from far away
	},
	Reload = {
		Volume = 0.6,
	},
	PourPowder = {
		Volume = 0.7,
	},
	RamBullet = {
		Volume = 0.8,
	},
	PrimePan = {
		Volume = 0.7,
	},
	ButtonClick = {
		Volume = 0.4,
	}
	-- Add configurations for other sounds as needed
}

-- Cache for loaded sound instances
local soundCache = {}

function SoundManager.PlaySound(soundName, parent)
	local soundId = SOUND_IDS[soundName]
	if not soundId then
		warn("SoundManager: Sound not found in list:", soundName)
		return
	end

	-- Use cache or create new sound instance
	local sound = soundCache[soundName]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Name = soundName
		-- Decide where to parent - SoundService for global, parts for positional
		sound.Parent = parent or SoundService -- Default to global SoundService
		
		-- Apply sound configuration if available
		local config = SOUND_CONFIG[soundName]
		if config then
			if config.Volume then sound.Volume = config.Volume end
			if config.PlaybackSpeed then sound.PlaybackSpeed = config.PlaybackSpeed end
			if config.RollOffMaxDistance then sound.RollOffMaxDistance = config.RollOffMaxDistance end
			if config.RollOffMinDistance then sound.RollOffMinDistance = config.RollOffMinDistance end
			-- Apply other configurations as needed
		end
		
		soundCache[soundName] = sound
		print("SoundManager: Created sound instance for", soundName)
	else
		-- Ensure parent is correct if specified differently
		if parent and sound.Parent ~= parent then
			sound.Parent = parent
		elseif not parent and sound.Parent ~= SoundService then
			sound.Parent = SoundService
		end
		
		-- Reset playback position if sound is already playing
		if sound.IsPlaying then
			sound:Stop()
		end
	end

	-- Play the sound
	sound:Play()
	print("SoundManager: Playing sound", soundName)
	
	return sound -- Return sound instance for further manipulation if needed
end

-- Function to create and play a 3D positional sound at a location
function SoundManager.PlaySoundAtLocation(soundName, position)
	if not position or not SOUND_IDS[soundName] then return end
	
	-- Create a temporary part to host the sound
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Transparency = 1
	soundPart.Position = position
	soundPart.Parent = workspace
	
	-- Create the sound attached to this part
	local sound = SoundManager.PlaySound(soundName, soundPart)
	
	-- Clean up after playing
	if sound then
		sound.Ended:Connect(function()
			soundPart:Destroy()
		end)
		
		-- Backup cleanup in case sound doesn't end properly
		task.delay(sound.TimeLength + 1, function()
			if soundPart and soundPart.Parent then
				soundPart:Destroy()
			end
		end)
	else
		-- Immediate cleanup if sound failed to play
		soundPart:Destroy()
	end
end

-- Function for ambient battle sounds (called once to start looping ambient audio)
function SoundManager.StartBattleAmbience()
	local sound = SoundManager.PlaySound("BattleAmbient")
	if sound then
		sound.Looped = true
		sound.Volume = 0.3
		print("SoundManager: Started battle ambience")
	end
end

-- Preload sounds? (Optional)
-- for name, id in pairs(SOUND_IDS) do
--     ContentProvider:PreloadAsync({id})
-- end

return SoundManager
