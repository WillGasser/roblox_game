-- WeaponHandler.lua (Server)
-- Handles server-side weapon logic: firing, hit detection, damage, ammo, reload state.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Settings = require(ReplicatedStorage.Shared.Settings)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerManager = require(ServerScriptService.Server.PlayerManager)

local WeaponHandler = {}

-- Runtime data for player weapon states
local weaponStates = {} -- weaponStates[playerUserId] = { Ammo = 1, IsReloading = false, LastFireTime = 0 }

-- Get RemoteEvents
local fireWeaponRemote = Remotes.Get("RemoteEvent", "FireWeapon")
local startReloadRemote = Remotes.Get("RemoteEvent", "StartReload")
-- Add remotes for reload completion/stages, ammo updates etc. later

function WeaponHandler.InitializePlayerWeaponState(player)
	weaponStates[player.UserId] = {
		Ammo = Settings.Weapons.Musket.AmmoCapacity, -- Assuming Musket for now
		IsReloading = false,
		LastFireTime = 0,
		EquippedWeapon = "Musket", -- Default weapon
	}
	-- TODO: Send initial ammo state to client
end

function WeaponHandler.CleanupPlayerWeaponState(player)
	weaponStates[player.UserId] = nil
end

function WeaponHandler.OnFireWeapon(player, fireOrigin, fireDirection)
	local state = weaponStates[player.UserId]
	if not state or state.IsReloading or state.Ammo <= 0 then
		return -- Can't fire: No state, reloading, or out of ammo
	end

	local weaponSettings = Settings.Weapons[state.EquippedWeapon]
	if not weaponSettings then
		warn("Player", player.Name, "tried to fire unknown weapon:", state.EquippedWeapon)
		return
	end

	-- TODO: Add cooldown check based on LastFireTime

	print(player.Name, "fired weapon from", fireOrigin, "towards", fireDirection)
	state.Ammo = state.Ammo - 1
	state.LastFireTime = tick()
	-- TODO: Send ammo update to client

	-- Perform Raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = Workspace:Raycast(fireOrigin, fireDirection * weaponSettings.Range, raycastParams)

	if raycastResult then
		print("Hit:", raycastResult.Instance.Name, "at position:", raycastResult.Position)
		local hitPart = raycastResult.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")

		if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
			local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(hitModel)
			if targetPlayer and targetPlayer ~= player then
				-- TODO: Check team affiliation (prevent friendly fire?)
				local damage = weaponSettings.Damage
				-- TODO: Implement headshot detection/multiplier
				print("Applying", damage, "damage to", targetPlayer.Name)
				PlayerManager.DamagePlayer(targetPlayer, damage, player)
			end
		end
		-- TODO: Handle hitting environment (visual effects?)
	else
		print("Missed.")
	end

	-- TODO: Trigger reload automatically if needed, or wait for player input
end

function WeaponHandler.OnStartReload(player)
	local state = weaponStates[player.UserId]
	if not state or state.IsReloading or state.Ammo >= Settings.Weapons[state.EquippedWeapon].AmmoCapacity then
		return -- Can't reload: No state, already reloading, or full ammo
	end

	local weaponSettings = Settings.Weapons[state.EquippedWeapon]
	print(player.Name, "started reloading", state.EquippedWeapon)
	state.IsReloading = true

	-- Simulate reload time (replace with stage-based logic later)
	task.delay(weaponSettings.ReloadTime, function()
		if weaponStates[player.UserId] then -- Check if player still exists/connected
			state.Ammo = weaponSettings.AmmoCapacity
			state.IsReloading = false
			print(player.Name, "finished reloading.")
			-- TODO: Send ammo update to client
		end
	end)
end


-- Connect RemoteEvents
fireWeaponRemote.OnServerEvent:Connect(WeaponHandler.OnFireWeapon)
startReloadRemote.OnServerEvent:Connect(WeaponHandler.OnStartReload)

-- Initialize state for players already in game (e.g., script reload)
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
	WeaponHandler.InitializePlayerWeaponState(player)
end

-- Hook into PlayerManager events if needed (e.g., on spawn)
-- PlayerManager.PlayerSpawned:Connect(function(player) ... end) -- Requires custom signal in PlayerManager

-- Connect to player joining/leaving
game:GetService("Players").PlayerAdded:Connect(WeaponHandler.InitializePlayerWeaponState)
game:GetService("Players").PlayerRemoving:Connect(WeaponHandler.CleanupPlayerWeaponState)


return WeaponHandler
