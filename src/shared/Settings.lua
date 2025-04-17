-- Settings.lua
-- Contains shared game settings, constants, and configurations

local Settings = {}

-- General Game Settings
Settings.Game = {
	RoundTime = 300, -- Seconds (5 minutes)
	ScoreToWin = 50,
	MinPlayersToStart = 2,
}

-- Weapon Settings
Settings.Weapons = {
	Musket = {
		Damage = 80,
		Range = 200, -- Studs
		ReloadTime = 5.0, -- Seconds (Placeholder for multi-stage)
		AmmoCapacity = 1,
		HeadshotMultiplier = 1.5,
		Accuracy = { -- Degrees of spread
			Hipfire = 5.0,
			ADS = 1.0,
			MovePenalty = 2.0,
		},
	},
	-- Add other weapons like Pistol, Saber here
}

-- Team Settings
Settings.Teams = {
	Team1 = {
		Name = "French Empire",
		Color = BrickColor.new("Bright blue"),
		-- Uniform Asset IDs?
	},
	Team2 = {
		Name = "British Empire",
		Color = BrickColor.new("Bright red"),
		-- Uniform Asset IDs?
	},
}

-- Other settings can be added here (e.g., Physics, UI themes)


return Settings
