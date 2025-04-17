-- Remotes.lua
-- Defines RemoteEvents and RemoteFunctions used for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure a folder exists for remotes if it doesn't already
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local Remotes = {}

-- Example RemoteEvent (replace/add as needed)
-- Remotes.FireWeapon = remotesFolder:FindFirstChild("FireWeapon") or Instance.new("RemoteEvent", remotesFolder)
-- Remotes.FireWeapon.Name = "FireWeapon"

-- Example RemoteFunction (replace/add as needed)
-- Remotes.GetServerTime = remotesFolder:FindFirstChild("GetServerTime") or Instance.new("RemoteFunction", remotesFolder)
-- Remotes.GetServerTime.Name = "GetServerTime"


-- Function to get or create a remote instance
function Remotes.Get(remoteType, remoteName)
	local remote = remotesFolder:FindFirstChild(remoteName)
	if remote and remote:IsA(remoteType) then
		return remote
	elseif remote then
		warn("Existing remote", remoteName, "is not of type", remoteType, "- destroying and recreating.")
		remote:Destroy()
	end

	-- Create new remote
	local newRemote = Instance.new(remoteType)
	newRemote.Name = remoteName
	newRemote.Parent = remotesFolder
	return newRemote
end


return Remotes
