-- PlayerManager.lua (Server)
-- Handles player joining, leaving, data, spawning, health, etc.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Shared.Settings)
-- local MatchManager = require(ServerScriptService.Server.MatchManager) -- Uncomment when MatchManager exists

local PlayerManager = {}

local playerData = {} -- Store runtime data per player

function PlayerManager.SetupPlayer(player)
	print("Setting up player:", player.Name)
	playerData[player.UserId] = {
		Team = nil,
		Score = 0,
		Deaths = 0,
		-- Add other persistent or session data here
	}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local killsStat = Instance.new("IntValue")
	killsStat.Name = "Kills"
	killsStat.Value = 0
	killsStat.Parent = leaderstats

	local deathsStat = Instance.new("IntValue")
	deathsStat.Name = "Deaths"
	deathsStat.Value = 0
	deathsStat.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		PlayerManager.OnCharacterAdded(player, character)
	end)

	-- Assign team (basic example, MatchManager should handle this)
	-- local team = MatchManager.AssignTeam(player)
	-- playerData[player.UserId].Team = team
	-- player.Team = team -- Assign Roblox Team instance
end

function PlayerManager.CleanupPlayer(player)
	print("Cleaning up player:", player.Name)
	playerData[player.UserId] = nil
end

function PlayerManager.OnCharacterAdded(player, character)
	print("Character added for:", player.Name)
	local humanoid = character:WaitForChild("Humanoid")

	-- Set health
	humanoid.MaxHealth = 100
	humanoid.Health = humanoid.MaxHealth

	-- Apply uniform/appearance based on team
	-- local teamSettings = Settings.Teams[playerData[player.UserId].Team.Name] -- Assuming Team object has Name property matching Settings key
	-- Apply team color, load uniforms etc.

	humanoid.Died:Connect(function()
		PlayerManager.OnPlayerDied(player, character)
	end)

	-- TODO: Implement spawning logic (positioning based on team spawns)
	-- character:SetPrimaryPartCFrame(MatchManager.GetSpawnPoint(playerData[player.UserId].Team))
end

function PlayerManager.OnPlayerDied(player, character)
	print(player.Name, "died.")
	playerData[player.UserId].Deaths = playerData[player.UserId].Deaths + 1
	local deathsStat = player.leaderstats:FindFirstChild("Deaths")
	if deathsStat then
		deathsStat.Value = playerData[player.UserId].Deaths
	end

	-- Handle kill credit (WeaponHandler or other system should inform this)
	-- local killer = humanoid:FindFirstChild("creator") -- Find tag of killer
	-- if killer and killer.Value and killer.Value:IsA("Player") then
	--     local killerPlayer = killer.Value
	--     playerData[killerPlayer.UserId].Score = playerData[killerPlayer.UserId].Score + 1
	--     local killsStat = killerPlayer.leaderstats:FindFirstChild("Kills")
	--     if killsStat then
	--         killsStat.Value = playerData[killerPlayer.UserId].Score
	--     end
	-- end

	-- TODO: Trigger respawn timer via MatchManager?
	-- MatchManager.RequestRespawn(player)
end

function PlayerManager.DamagePlayer(player, damageAmount, source)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(damageAmount)
			-- TODO: Add killer tagging ('creator' tag)
			-- if humanoid.Health <= 0 and source and source:IsA("Player") then
			--     local tag = Instance.new("ObjectValue")
			--     tag.Name = "creator"
			--     tag.Value = source
			--     tag.Parent = humanoid
			--     game:GetService("Debris"):AddItem(tag, 2) -- Tag lasts 2 seconds
			-- end
			return true -- Damage applied
		end
	end
	return false -- Player likely already dead or no character
end


-- Connect player events
Players.PlayerAdded:Connect(PlayerManager.SetupPlayer)
Players.PlayerRemoving:Connect(PlayerManager.CleanupPlayer)

-- Setup existing players (if script reloads)
for _, player in ipairs(Players:GetPlayers()) do
	PlayerManager.SetupPlayer(player)
end

return PlayerManager
