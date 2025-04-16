-- BotAnimations.lua (Client Script)
-- Place this file in src/client/

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Animation IDs - these can be different ones or use the defaults
local ANIMATIONS = {
    IDLE = "http://www.roblox.com/asset/?id=507766388", -- Default Roblox animations
    WALK = "http://www.roblox.com/asset/?id=507777826",
    ATTACK = "http://www.roblox.com/asset/?id=507768375"
}

-- Function to set up animations for a bot
local function setupBotAnimations(botModel)
    print("Setting up animations for bot:", botModel.Name)
    
    -- Make sure the bot has a humanoid
    local humanoid = botModel:WaitForChild("Humanoid")
    
    -- Create animator if it doesn't exist
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    -- Create and load animations
    local animations = {}
    
    for name, id in pairs(ANIMATIONS) do
        local animation = Instance.new("Animation")
        animation.AnimationId = id
        animations[name] = animator:LoadAnimation(animation)
        
        -- Configure animations
        if name == "IDLE" then
            animations[name].Looped = true
        elseif name == "WALK" then
            animations[name].Looped = true
        elseif name == "ATTACK" then
            animations[name].Looped = false
        end
    end
    
    -- Get the animation state value
    local animState = botModel:WaitForChild("AnimationState")
    local currentState = ""
    
    -- Function to update animations based on state
    local function updateAnimation(state)
        if state == currentState then
            return
        end
        
        -- Stop all animations
        for _, anim in pairs(animations) do
            anim:Stop()
        end
        
        -- Play the appropriate animation
        if state == "Idle" then
            animations.IDLE:Play()
        elseif state == "Walk" then
            animations.WALK:Play()
        elseif state == "Attack" then
            animations.ATTACK:Play()
        end
        
        currentState = state
    end
    
    -- Connect to state changes
    animState.Changed:Connect(updateAnimation)
    
    -- Initial animation
    updateAnimation(animState.Value)
    
    return animations
end

-- Watch for new bots being added to the workspace
local function onDescendantAdded(descendant)
    if descendant:IsA("Model") and descendant.Name == "CirclingBot" then
        task.spawn(function()
            setupBotAnimations(descendant)
        end)
    end
end

-- Connect to workspace descendants being added
workspace.DescendantAdded:Connect(onDescendantAdded)

-- Check for existing bots
for _, descendant in pairs(workspace:GetDescendants()) do
    if descendant:IsA("Model") and descendant.Name == "CirclingBot" then
        task.spawn(function()
            setupBotAnimations(descendant)
        end)
    end
end

print("Bot animation system initialized")