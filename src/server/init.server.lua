print("Hello world, from server!")

-- Load server-side modules
local PlayerManager = require(script:WaitForChild("PlayerManager"))
local WeaponHandler = require(script:WaitForChild("WeaponHandler"))
-- local MatchManager = require(script:WaitForChild("MatchManager")) -- Uncomment when MatchManager exists

print("Server modules loaded.")

-- Server initialization logic can go here if needed beyond module loading
