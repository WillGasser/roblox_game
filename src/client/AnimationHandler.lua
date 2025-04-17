-- AnimationHandler.lua (Client)
-- Handles loading and playing animations on characters and viewmodels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SoundManager = require(script.Parent:WaitForChild("SoundManager"))

local AnimationHandler = {}

local player = Players.LocalPlayer

-- Store loaded animations to avoid reloading
local loadedAnimations = {} -- loadedAnimations[characterInstance] = { Fire = animTrack, Reload = animTrack, ... }

-- Tracking reload status
local reloadStage = 0
local MAX_RELOAD_STAGES = 3
local currentReloadTracks = {}

-- Improved animation IDs using some R15 defaults & placeholders
-- These are placeholders - in a real implementation, you'd create custom animations
local ANIM_IDS = {
	Musket = {
		-- Standard locomotion - using Roblox defaults as placeholders
		Idle = "rbxassetid://507766388", -- Default R15 idle
		Walk = "rbxassetid://507777826", -- Default R15 walk
		Run = "rbxassetid://507767714", -- Default R15 run
		Jump = "rbxassetid://507765000", -- Default R15 jump
		Fall = "rbxassetid://507767968", -- Default R15 fall
		Land = "rbxassetid://507765644", -- Default R15 land
		
		-- Weapon-specific animations - would be custom in real implementation
		Fire_Hip = "rbxassetid://6730977780", -- Using rifle animation as placeholder (not perfect for musket)
		Fire_ADS = "rbxassetid://6730977780", -- Same placeholder for aimed firing
		
		-- Multi-stage reload animations for musket
		Reload_Stage1 = "rbxassetid://7378470782", -- Pour powder (using animation placeholder)
		Reload_Stage2 = "rbxassetid://7378469769", -- Ram bullet (using animation placeholder)
		Reload_Stage3 = "rbxassetid://7378470782", -- Prime pan (using animation placeholder)
		
		-- Aiming animations
		Aim_In = "rbxassetid://6730977780", -- Raise musket (placeholder)
		Aim_Out = "rbxassetid://6730977780", -- Lower musket (placeholder)
		Aim_Idle = "rbxassetid://6730977780", -- Hold aim (placeholder)
	},
	-- Other weapons would be defined here
}

-- Reload sound IDs for specific stages
local RELOAD_SOUND_IDS = {
	"PourPowder", -- Stage 1
	"RamBullet",  -- Stage 2
	"PrimePan"    -- Stage 3
}

-- Function to load animations for a character if not already loaded
function AnimationHandler.LoadCharacterAnimations(character, weaponType)
	if not character or loadedAnimations[character] then
		return -- Already loaded or no character
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	loadedAnimations[character] = {}
	local weaponAnims = ANIM_IDS[weaponType] or {}

	print("Loading animations for", character.Name, "with weapon type:", weaponType or "Default")

	for animName, animId in pairs(weaponAnims) do
		if animId ~= "rbxassetid://0" then -- Only load if ID is not placeholder 0
			local animInstance = Instance.new("Animation")
			animInstance.AnimationId = animId
			animInstance.Name = animName
			animInstance.Parent = character -- Store on character temporarily? Or just load track
			local animTrack = animator:LoadAnimation(animInstance)
			loadedAnimations[character][animName] = animTrack
			-- animInstance:Destroy() -- Clean up instance after loading track? Check best practice.
			print(" - Loaded:", animName)
		else
			print(" - Skipped placeholder:", animName)
		end
	end

	-- TODO: Load default locomotion animations if not weapon-specific
end

-- Function to play an animation
function AnimationHandler.PlayAnimation(character, animName, speed, loop, priority)
	if not character or not loadedAnimations[character] or not loadedAnimations[character][animName] then
		-- print("Warning: Cannot play animation", animName, "- not loaded for", character and character.Name or "nil")
		return
	end

	local animTrack = loadedAnimations[character][animName]
	animTrack.Priority = priority or Enum.AnimationPriority.Action
	animTrack.Looped = loop or false
	animTrack:Play(0.1, speed or 1, speed or 1) -- Fade time, weight, speed
	-- print("Playing animation:", animName, "on", character.Name)
	return animTrack
end

-- Specific animation functions
function AnimationHandler.PlayFireAnimation(character, weaponType, isAiming)
	local animName = isAiming and "Fire_ADS" or "Fire_Hip"
	print("AnimationHandler: Playing Fire Animation -", animName)
	AnimationHandler.LoadCharacterAnimations(character, weaponType) -- Ensure loaded
	AnimationHandler.PlayAnimation(character, animName, 1, false, Enum.AnimationPriority.Action)
end

function AnimationHandler.PlayReloadAnimation(character, weaponType)
	-- Reset any existing reload process
	AnimationHandler.StopReloadAnimations()
	
	-- Start multi-stage reload sequence
	reloadStage = 1
	print("AnimationHandler: Starting Reload Animation Sequence")
	AnimationHandler.PlayReloadStage(character, weaponType, reloadStage)
end

function AnimationHandler.PlayReloadStage(character, weaponType, stage)
	if not character or stage > MAX_RELOAD_STAGES then return end
	
	-- Clear any existing reload animation tracks
	for _, track in pairs(currentReloadTracks) do
		if track.IsPlaying then
			track:Stop()
		end
	end
	currentReloadTracks = {}
	
	local stageName = "Reload_Stage" .. stage
	print("AnimationHandler: Playing Reload Stage", stage, "-", stageName)
	
	-- Load animations if needed
	AnimationHandler.LoadCharacterAnimations(character, weaponType)
	
	-- Play animation for this stage
	local track = AnimationHandler.PlayAnimation(character, stageName, 1, false, Enum.AnimationPriority.Action)
	if track then
		table.insert(currentReloadTracks, track)
		
		-- Play appropriate sound for this stage
		SoundManager.PlaySound(RELOAD_SOUND_IDS[stage] or "Reload")
		
		-- Move to next stage when animation completes
		track.Stopped:Connect(function()
			if reloadStage == stage then -- Only proceed if we're still on this stage
				reloadStage = stage + 1
				if reloadStage <= MAX_RELOAD_STAGES then
					task.delay(0.3, function() -- Small delay between stages
						AnimationHandler.PlayReloadStage(character, weaponType, reloadStage)
					end)
				else
					reloadStage = 0 -- Reset when complete
					print("AnimationHandler: Reload sequence complete")
				end
			end
		end)
		
		-- Alternatively, for testing/development, force progression after a fixed time
		-- task.delay(1.5, function() -- Force progress after 1.5s
		--     if reloadStage == stage then
		--         reloadStage = stage + 1
		--         if reloadStage <= MAX_RELOAD_STAGES then
		--             AnimationHandler.PlayReloadStage(character, weaponType, reloadStage)
		--         else
		--             reloadStage = 0 -- Reset when complete
		--         end
		--     end
		-- end)
	end
end

function AnimationHandler.StopReloadAnimations()
	reloadStage = 0
	for _, track in pairs(currentReloadTracks) do
		if track.IsPlaying then
			track:Stop()
		end
	end
	currentReloadTracks = {}
end

function AnimationHandler.UpdateLocomotion(character, moveDirection, isSprinting, isJumping, isFalling)
	-- TODO: Implement logic to blend/play walk/run/jump/fall/idle animations
	-- This is complex and involves checking Humanoid state (FloorMaterial, MoveDirection magnitude, etc.)
	-- print("AnimationHandler: UpdateLocomotion (Not Implemented)")
	AnimationHandler.LoadCharacterAnimations(character, "Musket") -- Load default anims if needed
	-- Example: Play walk if moving, idle if not (very basic)
	-- local idleAnim = loadedAnimations[character] and loadedAnimations[character].Idle
	-- local walkAnim = loadedAnimations[character] and loadedAnimations[character].Walk
	-- if moveDirection.Magnitude > 0.1 then
	--     if idleAnim and idleAnim.IsPlaying then idleAnim:Stop() end
	--     if walkAnim and not walkAnim.IsPlaying then AnimationHandler.PlayAnimation(character, "Walk", 1, true, Enum.AnimationPriority.Core) end
	-- else
	--     if walkAnim and walkAnim.IsPlaying then walkAnim:Stop() end
	--     if idleAnim and not idleAnim.IsPlaying then AnimationHandler.PlayAnimation(character, "Idle", 1, true, Enum.AnimationPriority.Core) end
	-- end
end

function AnimationHandler.SetAiming(character, weaponType, isAiming)
	if not character then return end
	
	print("AnimationHandler: Set Aiming State -", isAiming)
	
	-- Load animations if needed
	AnimationHandler.LoadCharacterAnimations(character, weaponType or "Musket")
	
	-- Play appropriate aim transition animation
	if isAiming then
		local aimInTrack = AnimationHandler.PlayAnimation(character, "Aim_In", 1, false, Enum.AnimationPriority.Action)
		if aimInTrack then
			-- When aim-in completes, play the aiming idle if we're still aiming
			aimInTrack.Stopped:Connect(function()
				if isAiming then -- Check if still aiming
					local aimIdleTrack = AnimationHandler.PlayAnimation(character, "Aim_Idle", 1, true, Enum.AnimationPriority.Movement)
					if aimIdleTrack then
						aimIdleTrack.Looped = true -- Ensure the idle animation loops
					end
				end
			end)
		end
	else
		-- Play aim-out animation
		AnimationHandler.PlayAnimation(character, "Aim_Out", 1, false, Enum.AnimationPriority.Action)
		
		-- Stop any aim idle animations
		local aimIdleTrack = loadedAnimations[character] and loadedAnimations[character]["Aim_Idle"]
		if aimIdleTrack and aimIdleTrack.IsPlaying then
			aimIdleTrack:Stop()
		end
	end
end

-- Function to create a procedural walk/run animation cycle based on character state
function AnimationHandler.UpdateLocomotion(character, isAiming)
	if not character or not loadedAnimations[character] then return end
	
	RunService:BindToRenderStep("LocomotionUpdate", Enum.RenderPriority.Character, function()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		
		local velocity = humanoid.MoveDirection.Magnitude
		local idleTrack = loadedAnimations[character]["Idle"]
		local walkTrack = loadedAnimations[character]["Walk"]
		local runTrack = loadedAnimations[character]["Run"]
		
		-- Determine which animation to play based on movement and aiming
		if velocity < 0.1 then
			-- Idle
			if walkTrack and walkTrack.IsPlaying then walkTrack:Stop() end
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			if idleTrack and not idleTrack.IsPlaying and not isAiming then
				idleTrack:Play()
			end
		elseif velocity < 0.5 or isAiming then
			-- Walking (or aiming+moving)
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			if walkTrack and not walkTrack.IsPlaying then
				walkTrack:Play()
			end
		else
			-- Running
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
			if walkTrack and walkTrack.IsPlaying then walkTrack:Stop() end
			if runTrack and not runTrack.IsPlaying and not isAiming then
				runTrack:Play()
			end
		end
	end)
end

-- Clean up loaded animations when character is removed
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(character)
		if loadedAnimations[character] then
			print("Cleaning up animations for", character.Name)
			for _, animTrack in pairs(loadedAnimations[character]) do
				if animTrack.IsPlaying then
					animTrack:Stop()
				end
				-- animTrack:Destroy() -- Destroy tracks? Check best practice.
			end
			loadedAnimations[character] = nil
		end
	end)
end)


return AnimationHandler
