-- WeaponController.lua (Client)
-- Handles client-side weapon visuals, effects, animations, and links input to actions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService") -- For mouse info if needed

local Settings = require(ReplicatedStorage.Shared.Settings)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UIManager = require(script.Parent.UIManager) -- Uncommented
local AnimationHandler = require(script.Parent.AnimationHandler) -- Uncommented
local SoundManager = require(script.Parent:WaitForChild("SoundManager")) -- Fixed path
local CameraHandler = require(script.Parent.CameraHandler) -- Added for recoil effects
-- local EffectManager = require(script.Parent.EffectManager) -- Uncomment when EffectManager exists

local WeaponController = {}

local player = Players.LocalPlayer
local currentWeapon = nil -- Reference to the Tool instance if using Tools
local weaponViewModel = nil -- Reference to the ViewModel if using one

local fireWeaponRemote = Remotes.Get("RemoteEvent", "FireWeapon")
local startReloadRemote = Remotes.Get("RemoteEvent", "StartReload")
-- TODO: Listen for server updates (e.g., ammo count, forced reload)

local isAiming = false
local isReloading = false -- Client-side prediction/state
local currentAmmo = 0 -- Client-side prediction

function WeaponController.EquipWeapon(weaponName)
	-- TODO: Handle equipping logic
	-- - Load weapon model/Tool
	-- - Load ViewModel
	-- - Update UI?
	print("Equipped weapon:", weaponName)
	-- For now, assume Musket is always equipped
	local weaponSettings = Settings.Weapons[weaponName] or Settings.Weapons.Musket
	currentAmmo = weaponSettings.AmmoCapacity
	UIManager.UpdateAmmo(currentAmmo, 0) -- Initial ammo display
end

function WeaponController.RequestFire()
	if isReloading or currentAmmo <= 0 then return end -- Don't fire while reloading or no ammo

	print("WeaponController: Requesting Fire")

	-- TODO: Check fire rate cooldown locally?

	-- Update local ammo prediction
	currentAmmo = currentAmmo - 1
	UIManager.UpdateAmmo(currentAmmo, 0)

	-- Play client-side effects immediately for responsiveness
	AnimationHandler.PlayFireAnimation(player.Character, "Musket", isAiming) -- Call AnimationHandler
	SoundManager.PlaySound("MusketFire") -- Call SoundManager
	CameraHandler.ApplyRecoil(0.8) -- Apply recoil effect - stronger for musket
	-- EffectManager.PlayMuzzleFlash()
	-- EffectManager.PlayGunSmoke()

	-- Get accurate firing data
	local camera = workspace.CurrentCamera
	local fireOrigin = camera.CFrame.Position -- TODO: Use actual muzzle position from ViewModel/WeaponModel
	local fireDirection = camera.CFrame.LookVector -- TODO: Account for spread/accuracy based on Settings

	-- Tell the server we fired
	fireWeaponRemote:FireServer(fireOrigin, fireDirection)

	-- TODO: Apply client-side recoil/camera shake via CameraHandler
end

function WeaponController.RequestReload()
	local weaponSettings = Settings.Weapons.Musket -- Assuming Musket for now
	if isReloading or currentAmmo >= weaponSettings.AmmoCapacity then return end -- Already reloading or full ammo

	print("WeaponController: Requesting Reload")

	isReloading = true
	UIManager.ShowReloadIndicator(true) -- Call UIManager
	AnimationHandler.PlayReloadAnimation(player.Character, "Musket") -- Call AnimationHandler
	SoundManager.PlaySound("Reload") -- Call SoundManager

	-- Tell the server we started reloading
	startReloadRemote:FireServer()

	-- Handle reload completion (timed locally for prediction)
	task.delay(weaponSettings.ReloadTime, function()
		-- Check if player/character still valid before completing
		if player and player.Character and isReloading then -- Check if reload wasn't cancelled/player left
			isReloading = false
			currentAmmo = weaponSettings.AmmoCapacity
			UIManager.ShowReloadIndicator(false) -- Call UIManager
			UIManager.UpdateAmmo(currentAmmo, 0) -- Update UI on completion
			print("WeaponController: Reload finished (client prediction)")
		end
	end)
end

function WeaponController.SetAiming(aimingStatus)
	if isAiming == aimingStatus then return end -- No change

	isAiming = aimingStatus
	print("WeaponController: Set Aiming:", isAiming)
	-- Tell AnimationHandler to switch aim state
	AnimationHandler.SetAiming(player.Character, "Musket", isAiming) -- Call AnimationHandler
	-- TODO: Potentially adjust crosshair via UIManager
end

-- Initialize - Equip default weapon
WeaponController.EquipWeapon("Musket") -- Assume Musket for now

-- Link with InputHandler (This module needs to be required by InputHandler or vice-versa, or use a central coordinator)
-- This example assumes InputHandler requires this module and calls these functions.


return WeaponController
