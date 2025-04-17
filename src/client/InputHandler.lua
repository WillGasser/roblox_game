-- InputHandler.lua (Client)
-- Handles player input for actions like movement, firing, reloading, aiming, etc.

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponController = require(script.Parent.WeaponController) -- Uncommented
local CameraHandler = require(script.Parent.CameraHandler) -- Uncommented
local UIManager = require(script.Parent.UIManager) -- Added

local InputHandler = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse() -- Useful for getting mouse position/target

local fireWeaponRemote = Remotes.Get("RemoteEvent", "FireWeapon")
local startReloadRemote = Remotes.Get("RemoteEvent", "StartReload")

-- Action bindings
local ACTION_FIRE = "FireWeapon"
local ACTION_RELOAD = "ReloadWeapon"
local ACTION_AIM = "AimDownSights"
local ACTION_TOGGLE_LEADERBOARD = "ToggleLeaderboard" -- Added
-- Add actions for jump, sprint, crouch, melee, etc.

local isAiming = false -- Track aiming state

function InputHandler.HandleFireAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		print("Input: Fire Pressed")
		-- Need WeaponController to handle the actual firing logic (VFX, sound, remote call)
		WeaponController.RequestFire() -- Call WeaponController
		-- local camera = workspace.CurrentCamera -- Moved fire data gathering to WeaponController
		-- local fireOrigin = camera.CFrame.Position -- Or weapon muzzle position
		-- local fireDirection = camera.CFrame.LookVector -- Or mouse.UnitRay.Direction
		-- fireWeaponRemote:FireServer(fireOrigin, fireDirection) -- Moved remote call to WeaponController
	elseif inputState == Enum.UserInputState.End then
		-- Handle semi-auto logic if needed (stop firing)
		-- WeaponController.StopFire() ?
	end
	return Enum.ContextActionResult.Pass -- Allow other actions to process this input if needed
end

function InputHandler.HandleReloadAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		print("Input: Reload Pressed")
		-- Need WeaponController to handle reload request
		WeaponController.RequestReload() -- Call WeaponController
		-- startReloadRemote:FireServer() -- Moved remote call to WeaponController
	end
	return Enum.ContextActionResult.Pass
end

function InputHandler.HandleAimAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		isAiming = true
		print("Input: Aim Started")
		-- Need CameraHandler to adjust FOV/zoom
		CameraHandler.SetAiming(true) -- Call CameraHandler
		-- Need WeaponController to potentially change animations/accuracy
		WeaponController.SetAiming(true) -- Call WeaponController
	elseif inputState == Enum.UserInputState.End then
		isAiming = false
		print("Input: Aim Stopped")
		CameraHandler.SetAiming(false) -- Call CameraHandler
		WeaponController.SetAiming(false) -- Call WeaponController
	end
	return Enum.ContextActionResult.Pass
end

function InputHandler.HandleToggleLeaderboardAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		print("Input: Toggle Leaderboard Pressed")
		UIManager.ToggleLeaderboard() -- Call UIManager function
	end
	-- Sink this input so it doesn't trigger other actions (like Roblox's default leaderboard)
	return Enum.ContextActionResult.Sink
end


function InputHandler.BindActions()
	-- Bind Fire (Left Mouse Button)
	ContextActionService:BindAction(ACTION_FIRE, InputHandler.HandleFireAction, true, Enum.UserInputType.MouseButton1)

	-- Bind Reload (R Key)
	ContextActionService:BindAction(ACTION_RELOAD, InputHandler.HandleReloadAction, true, Enum.KeyCode.R)

	-- Bind Aim (Right Mouse Button)
	ContextActionService:BindAction(ACTION_AIM, InputHandler.HandleAimAction, true, Enum.UserInputType.MouseButton2)

	-- Bind Leaderboard Toggle (Tab Key)
	ContextActionService:BindAction(ACTION_TOGGLE_LEADERBOARD, InputHandler.HandleToggleLeaderboardAction, true, Enum.KeyCode.Tab)

	-- TODO: Bind other actions (movement overrides, sprint, crouch, jump, melee)

	print("Input Actions Bound")
end

function InputHandler.UnbindActions()
	ContextActionService:UnbindAction(ACTION_FIRE)
	ContextActionService:UnbindAction(ACTION_RELOAD)
	ContextActionService:UnbindAction(ACTION_AIM)
	ContextActionService:UnbindAction(ACTION_TOGGLE_LEADERBOARD) -- Added
	-- TODO: Unbind others
	print("Input Actions Unbound")
end

-- Bind actions when the script starts
InputHandler.BindActions()

-- Optional: Unbind actions if the character dies or enters a menu state
-- player.CharacterRemoving:Connect(InputHandler.UnbindActions)


return InputHandler
