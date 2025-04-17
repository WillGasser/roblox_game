-- CameraHandler.lua (Client)
-- Manages the player's camera, including first-person view, aiming zoom, recoil, and collision detection.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraHandler = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Camera settings
local defaultFOV = 70
local aimingFOV = 50 -- Less extreme zooming for better visibility
local currentFOV = defaultFOV

-- Camera state
local isAiming = false
local isBobbing = true -- Toggle for headbob effect
local cameraRecoil = Vector3.new(0, 0, 0) -- Current recoil offset
local cameraLerpSpeed = 0.2 -- How fast the camera follows the player's head
local bobCycleSpeed = 5 -- Speed of the bob cycle
local bobMagnitude = 0.05 -- Strength of the head bob
local bobTimer = 0 -- Timer for walk cycle

-- Collision detection
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {} -- Will be updated with character
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Store the connection to RenderStepped to disconnect it later if needed
local renderStepConnection = nil

-- Apply recoil to the camera
function CameraHandler.ApplyRecoil(strength)
    strength = strength or 0.5 -- Default recoil strength
    -- Random horizontal recoil -0.05 to 0.05, vertical recoil 0.1 to 0.3
    local randomX = (math.random() - 0.5) * 0.1 * strength
    local randomY = math.random() * 0.2 * strength + 0.1 * strength
    cameraRecoil = Vector3.new(randomX, randomY, 0)
    
    -- Reset recoil gradually (over about 0.5 seconds)
    task.spawn(function()
        local startRecoil = cameraRecoil
        for i = 1, 10 do
            task.wait(0.05)
            cameraRecoil = startRecoil * (1 - (i/10))
        end
        cameraRecoil = Vector3.new(0, 0, 0)
    end)
end

function CameraHandler.UpdateCamera(deltaTime)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return -- No character or root part found
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return -- Skip if no humanoid or dead
	end

	-- Update raycast filter to ignore player's character
	raycastParams.FilterDescendantsInstances = {character}

	-- First-Person Camera Logic
	local head = character:FindFirstChild("Head")
	if not head then return end -- Need head for positioning

	-- Base camera offset (adjustable)
	local cameraOffset = Vector3.new(0, 0.7, 0) -- Slightly above eye level
	
	-- Add head bobbing when moving and not aiming
	local bobOffset = Vector3.new(0, 0, 0)
	if isBobbing and humanoid.MoveDirection.Magnitude > 0.1 and not isAiming then
		bobTimer = bobTimer + deltaTime * humanoid.MoveDirection.Magnitude * bobCycleSpeed
		bobOffset = Vector3.new(
			math.sin(bobTimer) * bobMagnitude, 
			math.abs(math.sin(bobTimer)) * bobMagnitude, 
			0
		)
	end
	
	-- Combine all camera offsets
	local finalOffset = cameraOffset + bobOffset + cameraRecoil
	
	-- Calculate base position at the head
	local basePosition = head.CFrame.Position + finalOffset
	local lookDirection = head.CFrame.LookVector
	
	-- Target camera position (where we want to be)
	local targetPosition = basePosition
	
	-- Collision detection - adjust camera position if it would be inside geometry
	local raycastResult = workspace:Raycast(
		head.Position,
		finalOffset,
		raycastParams
	)
	
	if raycastResult then
		-- If something is in the way, move the camera closer to avoid collision
		-- Place camera slightly in front of hit position
		targetPosition = raycastResult.Position - (lookDirection * 0.2)
	end

	-- Point the camera forward
	local targetCFrame = CFrame.new(targetPosition, targetPosition + lookDirection)
	
	-- Smooth camera movement (lerp current camera to target)
	camera.CFrame = camera.CFrame:Lerp(targetCFrame, cameraLerpSpeed)

	-- Smooth FOV transition for aiming
	local targetFOV = isAiming and aimingFOV or defaultFOV
	currentFOV = currentFOV + (targetFOV - currentFOV) * 0.15 -- Lerp with adjusted speed
	camera.FieldOfView = currentFOV
end

function CameraHandler.SetAiming(aimingStatus)
	isAiming = aimingStatus
	-- FOV change will happen smoothly in UpdateCamera
	-- Disable bobbing while aiming
	isBobbing = not aimingStatus
end

-- Toggle head bobbing
function CameraHandler.SetHeadBobbing(enabled)
	isBobbing = enabled
end

function CameraHandler.Start()
	if renderStepConnection then return end -- Already started

	print("Starting Camera Handler")
	camera.CameraType = Enum.CameraType.Scriptable -- Take control of the camera
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter -- Lock cursor for FPS
	UserInputService.MouseIconEnabled = false -- Hide mouse cursor

	-- Run camera updates on RenderStepped for smoothness
	renderStepConnection = RunService.RenderStepped:Connect(CameraHandler.UpdateCamera)
	
	print("Advanced First-Person Camera Started")
end

function CameraHandler.Stop()
	if not renderStepConnection then return end -- Already stopped

	print("Stopping Camera Handler")
	renderStepConnection:Disconnect()
	renderStepConnection = nil
	camera.CameraType = Enum.CameraType.Custom -- Return control to Roblox default
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

-- Start the camera handler automatically
CameraHandler.Start()

-- Optional: Stop handler on death?
-- player.CharacterAdded:Connect(function(char)
--     local humanoid = char:WaitForChild("Humanoid")
--     humanoid.Died:Connect(CameraHandler.Stop)
--     -- Need to restart it on spawn if stopped
-- end)


return CameraHandler
