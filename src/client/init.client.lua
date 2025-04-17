print("Hello world, from client!")

-- Wait briefly for PlayerGui to be available if needed
task.wait(0.1)

-- Load client-side modules
local CameraHandler = require(script:WaitForChild("CameraHandler"))
local UIManager = require(script:WaitForChild("UIManager"))
local InputHandler = require(script:WaitForChild("InputHandler"))
local WeaponController = require(script:WaitForChild("WeaponController"))
local AnimationHandler = require(script:WaitForChild("AnimationHandler")) -- Uncommented
local SoundManager = require(script:WaitForChild("SoundManager")) -- Uncommented
-- local EffectManager = require(script:WaitForChild("EffectManager")) -- Uncomment when EffectManager exists

print("Client modules loaded.")

-- Client initialization logic can go here if needed beyond module loading
