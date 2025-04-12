print("Hello world, from client!")

-- Load the welcome UI
local WelcomeUI = require(script:WaitForChild("WelcomeUI"))

-- This line is missing - you need to call Init() to create the UI
WelcomeUI.Init()