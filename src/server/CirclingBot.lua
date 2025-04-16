-- CirclingBot.lua (Server Script)
-- Place this file in src/server/

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Configuration (easily adjustable)
local CONFIG = {
    -- Bot properties
    BOT = {
        NAME = "CirclingBot",
        HEALTH = 100,
        SPEED = 16,
        CIRCLE_RADIUS = 20,
        HEIGHT_OFFSET = 2.5,
        CIRCLE_SPEED = 1.5,
        MODEL_SCALE = 1.2,
    },
    
    -- Projectile properties
    PROJECTILE = {
        FIRE_RATE = 2.0,
        SPEED = 60,
        MAX_HEIGHT = 12,
        SIZE = Vector3.new(0.8, 0.8, 1.5),
        COLOR = Color3.fromRGB(43, 173, 255),
        TRAIL_COLOR = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 173, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 95, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(112, 48, 255))
        }),
        GLOW_COLOR = Color3.fromRGB(43, 173, 255),
        EXPLOSION_RADIUS = 6,
        MIN_FIRE_DISTANCE = 30,
    }
}

-- Create folders for organization
local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "BotEffects"
effectsFolder.Parent = workspace

local projectilesFolder = Instance.new("Folder")
projectilesFolder.Name = "Projectiles"
projectilesFolder.Parent = workspace

-- Effects module
local Effects = {}

function Effects.CreateTrail(part, width, lifetime)
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(-part.Size.Z/2, 0, 0)
    attachment0.Parent = part
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(part.Size.Z/2, 0, 0)
    attachment1.Parent = part
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = CONFIG.PROJECTILE.TRAIL_COLOR
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Lifetime = lifetime
    trail.MinLength = 0.1
    trail.FaceCamera = true
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.1)
    })
    trail.Width0 = width
    trail.Width1 = width/4
    trail.Parent = part
    
    return trail
end

function Effects.CreateLight(part, range, brightness)
    local light = Instance.new("PointLight")
    light.Color = CONFIG.PROJECTILE.GLOW_COLOR
    light.Range = range
    light.Brightness = brightness
    light.Parent = part
    
    return light
end

function Effects.CreateExplosion(position)
    -- Create the explosion core
    local core = Instance.new("Part")
    core.Size = Vector3.new(1, 1, 1)
    core.Position = position
    core.Anchored = true
    core.CanCollide = false
    core.Transparency = 0.2
    core.Material = Enum.Material.Neon
    core.Color = CONFIG.PROJECTILE.COLOR
    core.Shape = Enum.PartType.Ball
    core.Parent = effectsFolder
    
    -- Add light
    local light = Instance.new("PointLight")
    light.Color = CONFIG.PROJECTILE.GLOW_COLOR
    light.Range = CONFIG.PROJECTILE.EXPLOSION_RADIUS * 2
    light.Brightness = 5
    light.Parent = core
    
    -- Create explosion particles
    local explosion = Instance.new("ParticleEmitter")
    explosion.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.PROJECTILE.COLOR),
        ColorSequenceKeypoint.new(0.5, CONFIG.PROJECTILE.COLOR:Lerp(Color3.new(1, 1, 1), 0.5)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
    })
    explosion.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 5),
        NumberSequenceKeypoint.new(1, 0)
    })
    explosion.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    explosion.Speed = NumberRange.new(20, 40)
    explosion.Lifetime = NumberRange.new(0.5, 1)
    explosion.SpreadAngle = Vector2.new(180, 180)
    explosion.EmissionDirection = Enum.NormalId.Front
    explosion.Rate = 0
    explosion.Acceleration = Vector3.new(0, -5, 0)
    explosion.Parent = core
    explosion:Emit(50)
    
    -- Create shockwave
    local shockwave = Instance.new("Part")
    shockwave.Size = Vector3.new(1, 1, 1)
    shockwave.Position = position
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Transparency = 0.4
    shockwave.Material = Enum.Material.Neon
    shockwave.Color = CONFIG.PROJECTILE.COLOR
    shockwave.Shape = Enum.PartType.Ball
    shockwave.Parent = effectsFolder
    
    -- Animate core
    TweenService:Create(core, TweenInfo.new(0.3), {Size = Vector3.new(5, 5, 5), Transparency = 1}):Play()
    TweenService:Create(light, TweenInfo.new(0.6), {Brightness = 0}):Play()
    
    -- Animate shockwave
    TweenService:Create(
        shockwave, 
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {Size = Vector3.new(CONFIG.PROJECTILE.EXPLOSION_RADIUS * 2, 0.5, CONFIG.PROJECTILE.EXPLOSION_RADIUS * 2), Transparency = 1}
    ):Play()
    
    -- Clean up
    Debris:AddItem(core, 1)
    Debris:AddItem(shockwave, 0.6)
end

-- Projectile system
local ProjectileSystem = {}

function ProjectileSystem.CreateProjectile(origin, target)
    if not target or not target.Position then return end
    
    local direction = (target.Position - origin).Unit
    local startPos = origin + direction * 3 + Vector3.new(0, 2, 0)
    
    -- Create projectile
    local projectile = Instance.new("Part")
    projectile.Name = "BotProjectile"
    projectile.Size = CONFIG.PROJECTILE.SIZE
    projectile.Position = startPos
    projectile.Anchored = true
    projectile.CanCollide = false
    projectile.Material = Enum.Material.Neon
    projectile.Color = CONFIG.PROJECTILE.COLOR
    projectile.CFrame = CFrame.new(startPos, startPos + direction) * CFrame.Angles(0, 0, math.pi/2)
    projectile.Parent = projectilesFolder
    
    -- Add effects
    Effects.CreateTrail(projectile, 1.5, 0.5)
    Effects.CreateLight(projectile, 8, 2)
    
    -- Add particle effects
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(CONFIG.PROJECTILE.COLOR)
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Size = NumberSequence.new(0.5)
    particles.Lifetime = NumberRange.new(0.2, 0.4)
    particles.Speed = NumberRange.new(0, 2)
    particles.Rate = 80
    particles.SpreadAngle = Vector2.new(15, 15)
    particles.Parent = projectile
    
    -- Calculate arc trajectory
    local distance = (target.Position - startPos).Magnitude
    local travelTime = distance / CONFIG.PROJECTILE.SPEED
    local gravity = workspace.Gravity
    local horizontalSpeed = distance / travelTime
    local verticalSpeed = CONFIG.PROJECTILE.MAX_HEIGHT * 2 / travelTime + gravity * travelTime / 2
    
    -- Launch projectile
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= travelTime then
            connection:Disconnect()
            
            -- Create explosion at target
            Effects.CreateExplosion(projectile.Position)
            
            -- Destroy projectile
            projectile:Destroy()
            return
        end
        
        -- Calculate position along arc
        local progress = elapsed / travelTime
        local horizontalDistance = horizontalSpeed * elapsed
        local horizontalPos = startPos + direction * horizontalDistance
        local height = startPos.Y + verticalSpeed * elapsed - 0.5 * gravity * elapsed * elapsed
        
        -- Set new position
        local newPos = Vector3.new(horizontalPos.X, height, horizontalPos.Z)
        
        projectile.CFrame = CFrame.new(newPos, newPos + (direction * Vector3.new(1, 0, 1) + Vector3.new(0, 0.1, 0)).Unit) 
            * CFrame.Angles(0, 0, math.pi/2 + elapsed * 5)
    end)
    
    return projectile
end

-- Main bot creation and control
local BotModule = {}

function BotModule.CreateBot(targetPlayer)
    -- Create the bot model
    local model = Instance.new("Model")
    model.Name = CONFIG.BOT.NAME
    
    -- Create the main body
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1) * CONFIG.BOT.MODEL_SCALE
    torso.Position = Vector3.new(0, 5, 0) -- Default position, will be updated later
    torso.CanCollide = true
    torso.Anchored = false
    torso.Material = Enum.Material.Metal
    torso.Color = Color3.fromRGB(45, 45, 55)
    torso.Parent = model
    
    -- Set the primary part
    model.PrimaryPart = torso
    
    -- Create the head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5, 1.5, 1.5) * CONFIG.BOT.MODEL_SCALE
    head.Position = torso.Position + Vector3.new(0, 1.75, 0) * CONFIG.BOT.MODEL_SCALE
    head.CanCollide = false
    head.Material = Enum.Material.Metal
    head.Color = Color3.fromRGB(35, 35, 45)
    head.Parent = model
    
    -- Create eye
    local eye = Instance.new("Part")
    eye.Name = "Eye"
    eye.Size = Vector3.new(0.8, 0.3, 0.1) * CONFIG.BOT.MODEL_SCALE
    eye.Position = head.Position + Vector3.new(0, 0, -0.75) * CONFIG.BOT.MODEL_SCALE
    eye.CanCollide = false
    eye.Material = Enum.Material.Neon
    eye.Color = CONFIG.PROJECTILE.COLOR
    eye.Parent = model
    
    -- Create arms
    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(0.8, 2, 0.8) * CONFIG.BOT.MODEL_SCALE
    leftArm.Position = torso.Position + Vector3.new(-1.4, 0, 0) * CONFIG.BOT.MODEL_SCALE
    leftArm.CanCollide = false
    leftArm.Material = Enum.Material.Metal
    leftArm.Color = Color3.fromRGB(55, 55, 65)
    leftArm.Parent = model
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(0.8, 2, 0.8) * CONFIG.BOT.MODEL_SCALE
    rightArm.Position = torso.Position + Vector3.new(1.4, 0, 0) * CONFIG.BOT.MODEL_SCALE
    rightArm.CanCollide = false
    rightArm.Material = Enum.Material.Metal
    rightArm.Color = Color3.fromRGB(55, 55, 65)
    rightArm.Parent = model
    
    -- Create weapon
    local weapon = Instance.new("Part")
    weapon.Name = "Weapon"
    weapon.Size = Vector3.new(0.6, 0.6, 2.5) * CONFIG.BOT.MODEL_SCALE
    weapon.Position = rightArm.Position + Vector3.new(0.7, -1, 0) * CONFIG.BOT.MODEL_SCALE
    weapon.CanCollide = false
    weapon.Material = Enum.Material.Metal
    weapon.Color = Color3.fromRGB(40, 40, 45)
    weapon.Parent = model
    
    -- Create weapon glow
    local weaponGlow = Instance.new("Part")
    weaponGlow.Name = "WeaponGlow"
    weaponGlow.Size = Vector3.new(0.4, 0.4, 0.6) * CONFIG.BOT.MODEL_SCALE
    weaponGlow.Position = weapon.Position + Vector3.new(0, 0, -1.2) * CONFIG.BOT.MODEL_SCALE
    weaponGlow.CanCollide = false
    weaponGlow.Material = Enum.Material.Neon
    weaponGlow.Color = CONFIG.PROJECTILE.COLOR
    weaponGlow.Parent = model
    
    -- Create legs
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "LeftLeg"
    leftLeg.Size = Vector3.new(0.8, 2, 0.8) * CONFIG.BOT.MODEL_SCALE
    leftLeg.Position = torso.Position + Vector3.new(-0.6, -2, 0) * CONFIG.BOT.MODEL_SCALE
    leftLeg.CanCollide = true
    leftLeg.Material = Enum.Material.Metal
    leftLeg.Color = Color3.fromRGB(55, 55, 65)
    leftLeg.Parent = model
    
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "RightLeg"
    rightLeg.Size = Vector3.new(0.8, 2, 0.8) * CONFIG.BOT.MODEL_SCALE
    rightLeg.Position = torso.Position + Vector3.new(0.6, -2, 0) * CONFIG.BOT.MODEL_SCALE
    rightLeg.CanCollide = true
    rightLeg.Material = Enum.Material.Metal
    rightLeg.Color = Color3.fromRGB(55, 55, 65)
    rightLeg.Parent = model
    
    -- Create joints
    local neckJoint = Instance.new("Weld")
    neckJoint.Name = "NeckJoint"
    neckJoint.Part0 = torso
    neckJoint.Part1 = head
    neckJoint.C0 = CFrame.new(0, 1 * CONFIG.BOT.MODEL_SCALE, 0)
    neckJoint.Parent = torso
    
    local leftShoulderJoint = Instance.new("Weld")
    leftShoulderJoint.Name = "LeftShoulderJoint"
    leftShoulderJoint.Part0 = torso
    leftShoulderJoint.Part1 = leftArm
    leftShoulderJoint.C0 = CFrame.new(-1.4 * CONFIG.BOT.MODEL_SCALE, 0, 0)
    leftShoulderJoint.Parent = torso
    
    local rightShoulderJoint = Instance.new("Weld")
    rightShoulderJoint.Name = "RightShoulderJoint"
    rightShoulderJoint.Part0 = torso
    rightShoulderJoint.Part1 = rightArm
    rightShoulderJoint.C0 = CFrame.new(1.4 * CONFIG.BOT.MODEL_SCALE, 0, 0)
    rightShoulderJoint.Parent = torso
    
    local leftHipJoint = Instance.new("Weld")
    leftHipJoint.Name = "LeftHipJoint"
    leftHipJoint.Part0 = torso
    leftHipJoint.Part1 = leftLeg
    leftHipJoint.C0 = CFrame.new(-0.6 * CONFIG.BOT.MODEL_SCALE, -2 * CONFIG.BOT.MODEL_SCALE, 0)
    leftHipJoint.Parent = torso
    
    local rightHipJoint = Instance.new("Weld")
    rightHipJoint.Name = "RightHipJoint"
    rightHipJoint.Part0 = torso
    rightHipJoint.Part1 = rightLeg
    rightHipJoint.C0 = CFrame.new(0.6 * CONFIG.BOT.MODEL_SCALE, -2 * CONFIG.BOT.MODEL_SCALE, 0)
    rightHipJoint.Parent = torso
    
    local weaponJoint = Instance.new("Weld")
    weaponJoint.Name = "WeaponJoint"
    weaponJoint.Part0 = rightArm
    weaponJoint.Part1 = weapon
    weaponJoint.C0 = CFrame.new(0.7 * CONFIG.BOT.MODEL_SCALE, -1 * CONFIG.BOT.MODEL_SCALE, 0)
    weaponJoint.Parent = rightArm
    
    local weaponGlowJoint = Instance.new("Weld")
    weaponGlowJoint.Name = "WeaponGlowJoint"
    weaponGlowJoint.Part0 = weapon
    weaponGlowJoint.Part1 = weaponGlow
    weaponGlowJoint.C0 = CFrame.new(0, 0, -1.2 * CONFIG.BOT.MODEL_SCALE)
    weaponGlowJoint.Parent = weapon
    
    local eyeJoint = Instance.new("Weld")
    eyeJoint.Name = "EyeJoint"
    eyeJoint.Part0 = head
    eyeJoint.Part1 = eye
    eyeJoint.C0 = CFrame.new(0, 0, -0.75 * CONFIG.BOT.MODEL_SCALE)
    eyeJoint.Parent = head
    
    -- Create eye light
    local eyeLight = Instance.new("PointLight")
    eyeLight.Color = CONFIG.PROJECTILE.COLOR
    eyeLight.Range = 10
    eyeLight.Brightness = 1
    eyeLight.Parent = eye
    
    -- Add a glow effect to the weapon
    local weaponLight = Instance.new("PointLight")
    weaponLight.Color = CONFIG.PROJECTILE.COLOR
    weaponLight.Range = 8
    weaponLight.Brightness = 1
    weaponLight.Parent = weaponGlow
    
    -- Add humanoid for better physics and controls
    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    
    -- Create state values for client-side animation triggers
    local stateValue = Instance.new("StringValue")
    stateValue.Name = "AnimationState"
    stateValue.Value = "Idle"
    stateValue.Parent = model
    
    -- Create a unique ID for the bot
    local botId = Instance.new("StringValue")
    botId.Name = "BotId"
    botId.Value = tostring(math.random(1000000, 9999999))
    botId.Parent = model
    
    -- Position model in workspace and wait for character to be ready
    model.Parent = workspace
    
    -- Set initial position
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        model:SetPrimaryPartCFrame(CFrame.new(
            targetPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 5, -10)
        ))
    end
    
    -- Create bot behavior
    local lastFireTime = 0
    local angle = 0
    local botController = {}
    
    botController.Update = function(deltaTime)
        -- Validate player and character existence
        if not targetPlayer or not targetPlayer.Character then
            return false -- Return false to indicate the bot should be destroyed
        end
        
        local humanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return true -- Return true to keep the bot alive but skip this frame
        end
        
        local targetPos = humanoidRootPart.Position
        
        -- Calculate circle position around the player
        angle = angle + deltaTime * CONFIG.BOT.CIRCLE_SPEED
        local circleX = math.cos(angle) * CONFIG.BOT.CIRCLE_RADIUS
        local circleZ = math.sin(angle) * CONFIG.BOT.CIRCLE_RADIUS
        local targetCirclePos = targetPos + Vector3.new(circleX, CONFIG.BOT.HEIGHT_OFFSET, circleZ)
        
        -- Move bot towards circle position
        local moveDirection = (targetCirclePos - model.PrimaryPart.Position)
        local distance = moveDirection.Magnitude
        
        -- Always face the player - FIXED: Changed orientation to properly face player
        local lookDirection = (targetPos - model.PrimaryPart.Position).Unit
        
        -- Create a CFrame that looks from the bot's position toward the player
        local lookCFrame = CFrame.lookAt(model.PrimaryPart.Position, Vector3.new(targetPos.X, model.PrimaryPart.Position.Y, targetPos.Z))
        model:SetPrimaryPartCFrame(lookCFrame)
        
        -- Update animation state for the client
        if distance > 0.5 then
            moveDirection = moveDirection.Unit
            model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame + moveDirection * math.min(CONFIG.BOT.SPEED * deltaTime, distance))
            
            -- Set walk animation state
            stateValue.Value = "Walk"
        else
            -- Set idle animation state when not moving and not attacking
            if stateValue.Value ~= "Attack" then
                stateValue.Value = "Idle"
            end
        end
        
        -- Fire projectile at player
        local distanceToPlayer = (targetPos - model.PrimaryPart.Position).Magnitude
        local currentTime = tick()
        
        if currentTime - lastFireTime >= CONFIG.PROJECTILE.FIRE_RATE and distanceToPlayer <= CONFIG.PROJECTILE.MIN_FIRE_DISTANCE then
            lastFireTime = currentTime
            
            -- Set attack animation state
            stateValue.Value = "Attack"
            
            -- Reset to previous state after attack animation would complete
            task.delay(0.8, function()
                if not model:IsDescendantOf(workspace) then return end
                
                if stateValue.Value == "Attack" then
                    if (model.PrimaryPart.Position - targetCirclePos).Magnitude > 0.5 then
                        stateValue.Value = "Walk"
                    else
                        stateValue.Value = "Idle"
                    end
                end
            end)
            
            -- Fire projectile after a slight delay to match animation
            task.delay(0.3, function()
                if not model:IsDescendantOf(workspace) then return end
                if not weaponGlow:IsDescendantOf(workspace) then return end
                
                local muzzlePosition = weaponGlow.Position
                
                -- Muzzle flash effect
                local flash = Instance.new("Part")
                flash.Size = Vector3.new(1, 1, 1) * CONFIG.BOT.MODEL_SCALE
                flash.Position = muzzlePosition
                flash.Anchored = true
                flash.CanCollide = false
                flash.Material = Enum.Material.Neon
                flash.Color = CONFIG.PROJECTILE.COLOR
                flash.Shape = Enum.PartType.Ball
                flash.Transparency = 0
                flash.Parent = effectsFolder
                
                -- Flash light
                local flashLight = Instance.new("PointLight")
                flashLight.Color = CONFIG.PROJECTILE.COLOR
                flashLight.Range = 10
                flashLight.Brightness = 3
                flashLight.Parent = flash
                
                -- Animate flash
                TweenService:Create(flash, TweenInfo.new(0.2), {Size = Vector3.new(3, 3, 3) * CONFIG.BOT.MODEL_SCALE, Transparency = 1}):Play()
                TweenService:Create(flashLight, TweenInfo.new(0.2), {Brightness = 0}):Play()
                
                -- Clean up flash
                Debris:AddItem(flash, 0.2)
                
                -- Make sure target still exists before creating projectile
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    ProjectileSystem.CreateProjectile(muzzlePosition, targetPlayer.Character.HumanoidRootPart)
                end
            end)
        end
        
        return true -- Continue updating
    end
    
    return botController
end

-- Start bot when a player joins
local function onPlayerAdded(player)
    -- Wait for character to load
    player.CharacterAdded:Connect(function(character)
        -- Ensure character is fully loaded with humanoid root part
        if not character:FindFirstChild("HumanoidRootPart") then
            character:WaitForChild("HumanoidRootPart", 5)
        end
        
        -- Check if HumanoidRootPart exists
        if not character:FindFirstChild("HumanoidRootPart") then
            warn("Failed to create bot for player", player.Name, "- HumanoidRootPart not found")
            return
        end
        
        -- Small delay to ensure everything is loaded
        task.wait(2)
        
        -- Create bot that follows this player
        local botController = BotModule.CreateBot(player)
        
        -- Update bot every frame
        local connection
        connection = RunService.Heartbeat:Connect(function(deltaTime)
            -- Update bot behavior
            local shouldContinue = pcall(function()
                return botController.Update(deltaTime)
            end)
            
            -- If there was an error or the bot should stop, disconnect
            if not shouldContinue then
                connection:Disconnect()
            end
        end)
        
        -- Handle character removal
        character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                connection:Disconnect()
            end
        end)
    end)
end

-- Connect player added event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            onPlayerAdded(player)
        else
            player.CharacterAdded:Wait()
            onPlayerAdded(player)
        end
    end)
end

return BotModule