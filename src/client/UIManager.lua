-- UIManager.lua (Client)
-- Manages the game's user interface elements (HUD, menus, etc.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Settings = require(ReplicatedStorage.Shared.Settings)
-- local Remotes = require(ReplicatedStorage.Shared.Remotes) -- If needed for UI updates triggered by server

local UIManager = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainScreenGui = nil
local healthLabel = nil
local ammoLabel = nil
local reloadIndicator = nil -- Added
-- Leaderboard elements
local leaderboardFrame = nil
local leaderboardScrollingFrame = nil
local leaderboardPlayerTemplate = nil
local isLeaderboardVisible = false -- Added state tracking
local leaderboardUpdateConnection = nil -- Added for update loop

function UIManager.CreateHUD()
	if mainScreenGui then mainScreenGui:Destroy() end -- Clear existing UI

	mainScreenGui = Instance.new("ScreenGui")
	mainScreenGui.Name = "MainHUD"
	mainScreenGui.ResetOnSpawn = false -- Keep UI persistent across spawns
	mainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Health Bar Frame
	local healthBarFrame = Instance.new("Frame")
	healthBarFrame.Name = "HealthBarFrame"
	healthBarFrame.Size = UDim2.new(0, 180, 0, 22) -- Width, height
	healthBarFrame.Position = UDim2.new(0, 10, 1, -30) -- Bottom left corner
	healthBarFrame.AnchorPoint = Vector2.new(0, 1)
	healthBarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark grey background
	healthBarFrame.BackgroundTransparency = 0.2
	healthBarFrame.BorderSizePixel = 2
	healthBarFrame.BorderColor3 = Color3.fromRGB(60, 60, 60) -- Subtle border
	healthBarFrame.Parent = mainScreenGui

	-- Health Bar Fill (Green)
	healthLabel = Instance.new("Frame") -- Repurpose the variable for the health bar
	healthLabel.Name = "HealthFill"
	healthLabel.Size = UDim2.new(1, -4, 1, -4) -- Slightly smaller than parent
	healthLabel.Position = UDim2.new(0, 2, 0, 2) -- 2px padding
	healthLabel.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Green
	healthLabel.BorderSizePixel = 0
	healthLabel.Parent = healthBarFrame
	
	-- Health Icon
	local healthIcon = Instance.new("ImageLabel")
	healthIcon.Name = "HealthIcon"
	healthIcon.Size = UDim2.new(0, 24, 0, 24)
	healthIcon.Position = UDim2.new(0, -28, 0, -1) -- Left of the bar
	healthIcon.BackgroundTransparency = 1
	healthIcon.Image = "rbxassetid://6031763741" -- Heart icon (placeholder asset ID)
	healthIcon.Parent = healthBarFrame

	-- Ammo Display Container
	local ammoContainer = Instance.new("Frame")
	ammoContainer.Name = "AmmoContainer"
	ammoContainer.Size = UDim2.new(0, 120, 0, 40)
	ammoContainer.Position = UDim2.new(1, -20, 1, -35) -- Bottom right
	ammoContainer.AnchorPoint = Vector2.new(1, 1)
	ammoContainer.BackgroundTransparency = 1 -- Invisible background
	ammoContainer.Parent = mainScreenGui
	
	-- Ammo Icon (Musket)
	local ammoIcon = Instance.new("ImageLabel")
	ammoIcon.Name = "AmmoIcon"
	ammoIcon.Size = UDim2.new(0, 32, 0, 32)
	ammoIcon.Position = UDim2.new(0, 0, 0.5, 0)
	ammoIcon.AnchorPoint = Vector2.new(0, 0.5)
	ammoIcon.BackgroundTransparency = 1
	ammoIcon.Image = "rbxassetid://9214432639" -- Musket icon (placeholder asset ID)
	ammoIcon.Parent = ammoContainer

	-- Ammo Counter Label (Hand-drawn style)
	ammoLabel = Instance.new("TextLabel")
	ammoLabel.Name = "AmmoCounter"
	ammoLabel.Size = UDim2.new(0, 80, 0, 40)
	ammoLabel.Position = UDim2.new(1, 0, 0.5, 0)
	ammoLabel.AnchorPoint = Vector2.new(1, 0.5)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.TextColor3 = Color3.fromRGB(250, 220, 180) -- Parchment-like color
	ammoLabel.Font = Enum.Font.Fondamento -- Handwritten style font
	ammoLabel.TextSize = 30 -- Larger size for visibility
	ammoLabel.Text = "1" -- Just the number for simplicity
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
	-- Add text stroke for readability
	ammoLabel.TextStrokeTransparency = 0.5
	ammoLabel.TextStrokeColor3 = Color3.fromRGB(30, 30, 30)
	ammoLabel.Parent = ammoContainer

	-- Reload Indicator (Basic Text)
	reloadIndicator = Instance.new("TextLabel")
	reloadIndicator.Name = "ReloadIndicator"
	reloadIndicator.Size = UDim2.new(0, 150, 0, 30)
	reloadIndicator.Position = UDim2.new(0.5, -75, 0.8, 0) -- Near bottom center
	reloadIndicator.AnchorPoint = Vector2.new(0.5, 0)
	reloadIndicator.BackgroundTransparency = 1.0
	reloadIndicator.TextColor3 = Color3.new(1, 0.8, 0) -- More orange-yellow
	reloadIndicator.Font = Enum.Font.Michroma -- Changed font
	reloadIndicator.TextSize = 22 -- Larger
	reloadIndicator.Text = "RELOADING..."
	reloadIndicator.TextStrokeTransparency = 0.5 -- Add slight stroke
	reloadIndicator.TextStrokeColor3 = Color3.new(0,0,0)
	reloadIndicator.Visible = false -- Initially hidden
	reloadIndicator.Parent = mainScreenGui

	-- TODO: Create other HUD elements (crosshair, kill feed, etc.)

	mainScreenGui.Parent = playerGui
	print("HUD Created")

	-- Connect health updates
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	UIManager.UpdateHealth(humanoid.Health, humanoid.MaxHealth) -- Initial update
	humanoid.HealthChanged:Connect(function(newHealth)
		UIManager.UpdateHealth(newHealth, humanoid.MaxHealth)
	end)

	-- Show keybinds message briefly
	UIManager.ShowTemporaryMessage("LMB: Fire | RMB: Aim | R: Reload | Tab: Scoreboard", 5)
end

function UIManager.ShowTemporaryMessage(messageText, duration)
	local messageLabel = mainScreenGui:FindFirstChild("TemporaryMessage")
	if not messageLabel then
		messageLabel = Instance.new("TextLabel")
		messageLabel.Name = "TemporaryMessage"
		messageLabel.Size = UDim2.new(0.8, 0, 0.1, 0) -- Wide, short
		messageLabel.Position = UDim2.new(0.5, 0, 0.1, 0) -- Top center
		messageLabel.AnchorPoint = Vector2.new(0.5, 0)
		messageLabel.BackgroundTransparency = 0.4
		messageLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		messageLabel.BorderSizePixel = 1
		messageLabel.BorderColor3 = Color3.fromRGB(200, 200, 200)
		messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		messageLabel.Font = Enum.Font.SourceSansSemibold
		messageLabel.TextSize = 18
		messageLabel.TextWrapped = true
		messageLabel.Parent = mainScreenGui
	end

	messageLabel.Text = messageText
	messageLabel.Visible = true

	-- Use Debris service to automatically remove after duration
	game:GetService("Debris"):AddItem(messageLabel, duration)
	-- Alternatively, use task.delay to hide it:
	-- task.delay(duration, function()
	--     if messageLabel and messageLabel.Parent then
	--         messageLabel.Visible = false
	--         -- Optionally destroy it: messageLabel:Destroy()
	--     end
	-- end)
end


function UIManager.UpdateHealth(currentHealth, maxHealth)
	if healthLabel then
		-- Calculate health percentage
		local healthPercent = math.clamp(currentHealth / maxHealth, 0, 1)
		
		-- Update the health bar's size
		healthLabel.Size = UDim2.new(healthPercent, -4, 1, -4)
		
		-- Gradient color based on health percentage
		local r = math.floor(255 * (1 - healthPercent))
		local g = math.floor(200 * healthPercent)
		healthLabel.BackgroundColor3 = Color3.fromRGB(r, g, 50)
		
		-- Visual effect on damage
		if currentHealth < maxHealth then
			-- Flash effect when health changes
			local originalTransparency = healthLabel.BackgroundTransparency
			healthLabel.BackgroundTransparency = 0.7
			task.delay(0.1, function()
				if healthLabel and healthLabel.Parent then
					healthLabel.BackgroundTransparency = originalTransparency
				end
			end)
		end
	end
end

function UIManager.UpdateAmmo(currentAmmo, reserveAmmo)
	if ammoLabel then
		-- Directly show the number for musket
		ammoLabel.Text = tostring(currentAmmo)
		
		-- Add visual effect on ammo change
		ammoLabel.TextSize = 36 -- Temporarily increase size
		task.delay(0.1, function()
			if ammoLabel and ammoLabel.Parent then
				ammoLabel.TextSize = 30 -- Return to normal size
			end
		end)
	end
end

function UIManager.ShowReloadIndicator(show)
	if reloadIndicator then
		reloadIndicator.Visible = show
		print("Reload Indicator:", show)
	end
end

-- Leaderboard Functions Start ---

function UIManager.CreateLeaderboard()
	if leaderboardFrame then leaderboardFrame:Destroy() end

	-- Main frame with parchment/scroll appearance
	leaderboardFrame = Instance.new("Frame")
	leaderboardFrame.Name = "Leaderboard"
	leaderboardFrame.Size = UDim2.new(0.6, 0, 0.7, 0) -- Larger for better readability
	leaderboardFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centered
	leaderboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Parchment-like background color
	leaderboardFrame.BackgroundColor3 = Color3.fromRGB(240, 230, 200)
	leaderboardFrame.BackgroundTransparency = 0.05
	-- Fancy border
	leaderboardFrame.BorderSizePixel = 0 -- We'll use a UIStroke instead
	leaderboardFrame.Visible = false -- Start hidden
	leaderboardFrame.Parent = mainScreenGui
	
	-- Add decorative border (ornate frame look)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(120, 80, 40) -- Brown color like a wooden frame
	uiStroke.Thickness = 4
	uiStroke.Parent = leaderboardFrame
	
	-- Decorative corner embellishments (four corners)
	local function createCornerDecoration(position, rotation)
		local decoration = Instance.new("ImageLabel")
		decoration.Size = UDim2.new(0, 40, 0, 40)
		decoration.Position = position
		decoration.Rotation = rotation
		decoration.BackgroundTransparency = 1
		decoration.Image = "rbxassetid://6031094661" -- Placeholder for ornate corner decoration
		decoration.Parent = leaderboardFrame
		return decoration
	end
	
	-- Create corner decorations
	createCornerDecoration(UDim2.new(0, 0, 0, 0), 0)
	createCornerDecoration(UDim2.new(1, 0, 0, 0), 90)
	createCornerDecoration(UDim2.new(1, 0, 1, 0), 180)
	createCornerDecoration(UDim2.new(0, 0, 1, 0), 270)

	-- Title with Napoleonic era styling
	local titleBackground = Instance.new("Frame")
	titleBackground.Name = "TitleBackground"
	titleBackground.Size = UDim2.new(0.7, 0, 0, 50)
	titleBackground.Position = UDim2.new(0.5, 0, 0, 15)
	titleBackground.AnchorPoint = Vector2.new(0.5, 0)
	titleBackground.BackgroundColor3 = Color3.fromRGB(120, 60, 20) -- Dark wood color
	titleBackground.BackgroundTransparency = 0.3
	titleBackground.BorderSizePixel = 0
	titleBackground.Parent = leaderboardFrame
	
	-- Decorative top element (imperial eagle or similar Napoleonic symbol)
	local imperialSymbol = Instance.new("ImageLabel")
	imperialSymbol.Size = UDim2.new(0, 60, 0, 60)
	imperialSymbol.Position = UDim2.new(0.5, 0, 0, -25)
	imperialSymbol.AnchorPoint = Vector2.new(0.5, 0.5)
	imperialSymbol.BackgroundTransparency = 1
	imperialSymbol.Image = "rbxassetid://6026568215" -- Placeholder for imperial eagle or symbol
	imperialSymbol.Parent = titleBackground

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(250, 240, 220) -- Aged paper color
	title.Font = Enum.Font.Fondamento
	title.TextSize = 28
	title.Text = "Imperial Register of Combat"
	title.Parent = titleBackground
	
	-- Column Headers in a separate frame (like a register heading)
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "HeaderFrame"
	headerFrame.Size = UDim2.new(0.9, 0, 0, 40)
	headerFrame.Position = UDim2.new(0.5, 0, 0, 80)
	headerFrame.AnchorPoint = Vector2.new(0.5, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(70, 50, 30) -- Dark wood color
	headerFrame.BackgroundTransparency = 0.4
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = leaderboardFrame
	
	-- Column Headers
	local function createHeader(text, position, size)
		local header = Instance.new("TextLabel")
		header.Text = text
		header.Size = size
		header.Position = position
		header.BackgroundTransparency = 1
		header.TextColor3 = Color3.fromRGB(250, 240, 220)
		header.Font = Enum.Font.Fondamento
		header.TextSize = 18
		header.Parent = headerFrame
		return header
	end
	
	createHeader("Soldier", UDim2.new(0, 10, 0, 0), UDim2.new(0.5, 0, 1, 0))
	createHeader("Victories", UDim2.new(0.6, 0, 0, 0), UDim2.new(0.2, 0, 1, 0))
	createHeader("Defeats", UDim2.new(0.8, 0, 0, 0), UDim2.new(0.2, 0, 1, 0))

	-- Scrolling frame with parchment background
	leaderboardScrollingFrame = Instance.new("ScrollingFrame")
	leaderboardScrollingFrame.Name = "PlayerList"
	leaderboardScrollingFrame.Size = UDim2.new(0.9, 0, 1, -140) -- Leave space for headers and padding
	leaderboardScrollingFrame.Position = UDim2.new(0.5, 0, 0, 130)
	leaderboardScrollingFrame.AnchorPoint = Vector2.new(0.5, 0)
	leaderboardScrollingFrame.BackgroundTransparency = 1
	leaderboardScrollingFrame.BorderSizePixel = 0
	leaderboardScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-adjusts with UIListLayout
	leaderboardScrollingFrame.ScrollBarThickness = 8
	-- Style the scrollbar to match theme
	leaderboardScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 70, 40)
	leaderboardScrollingFrame.Parent = leaderboardFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10) -- More spacing between entries
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = leaderboardScrollingFrame

	-- Create Template Row with Napoleonic styling
	leaderboardPlayerTemplate = Instance.new("Frame")
	leaderboardPlayerTemplate.Name = "PlayerRowTemplate"
	leaderboardPlayerTemplate.Size = UDim2.new(1, 0, 0, 40) -- Taller rows
	leaderboardPlayerTemplate.BackgroundColor3 = Color3.fromRGB(235, 225, 195) -- Slightly darker than main parchment
	leaderboardPlayerTemplate.BackgroundTransparency = 0.1
	leaderboardPlayerTemplate.BorderSizePixel = 0
	
	-- Bottom separator line for each row
	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "Separator"
	bottomLine.Size = UDim2.new(0.9, 0, 0, 1)
	bottomLine.Position = UDim2.new(0.5, 0, 1, 0)
	bottomLine.AnchorPoint = Vector2.new(0.5, 0)
	bottomLine.BackgroundColor3 = Color3.fromRGB(120, 100, 80)
	bottomLine.BackgroundTransparency = 0.5
	bottomLine.BorderSizePixel = 0
	bottomLine.Parent = leaderboardPlayerTemplate
	
	-- Rank insignia image (based on kills - placeholder logic)
	local rankInsignia = Instance.new("ImageLabel")
	rankInsignia.Name = "RankInsignia"
	rankInsignia.Size = UDim2.new(0, 30, 0, 30)
	rankInsignia.Position = UDim2.new(0, 8, 0.5, 0)
	rankInsignia.AnchorPoint = Vector2.new(0, 0.5)
	rankInsignia.BackgroundTransparency = 1
	rankInsignia.Image = "rbxassetid://6034328955" -- Placeholder for rank insignia
	rankInsignia.Parent = leaderboardPlayerTemplate

	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(0.5, -50, 1, 0) -- Leave space for rank insignia
	playerName.Position = UDim2.new(0, 45, 0, 0)
	playerName.BackgroundTransparency = 1.0
	playerName.TextColor3 = Color3.fromRGB(30, 30, 30) -- Dark text on parchment
	playerName.Font = Enum.Font.Fondamento -- Handwritten style font
	playerName.TextSize = 20
	playerName.TextXAlignment = Enum.TextXAlignment.Left
	playerName.Text = "Player Name"
	playerName.Parent = leaderboardPlayerTemplate

	local kills = Instance.new("TextLabel")
	kills.Name = "Kills"
	kills.Size = UDim2.new(0.2, 0, 1, 0)
	kills.Position = UDim2.new(0.6, 0, 0, 0)
	kills.BackgroundTransparency = 1.0
	kills.TextColor3 = Color3.fromRGB(30, 30, 30)
	kills.Font = Enum.Font.Fondamento
	kills.TextSize = 20
	kills.TextXAlignment = Enum.TextXAlignment.Center
	kills.Text = "0"
	kills.Parent = leaderboardPlayerTemplate

	local deaths = Instance.new("TextLabel")
	deaths.Name = "Deaths"
	deaths.Size = UDim2.new(0.2, 0, 1, 0)
	deaths.Position = UDim2.new(0.8, 0, 0, 0)
	deaths.BackgroundTransparency = 1.0
	deaths.TextColor3 = Color3.fromRGB(30, 30, 30)
	deaths.Font = Enum.Font.Fondamento
	deaths.TextSize = 20
	deaths.TextXAlignment = Enum.TextXAlignment.Center
	deaths.Text = "0"
	deaths.Parent = leaderboardPlayerTemplate

	-- Close button with period design
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 80, 0, 30)
	closeButton.Position = UDim2.new(0.5, 0, 1, -30)
	closeButton.AnchorPoint = Vector2.new(0.5, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
	closeButton.TextColor3 = Color3.fromRGB(250, 240, 220)
	closeButton.Font = Enum.Font.Fondamento
	closeButton.TextSize = 18
	closeButton.Text = "Close"
	closeButton.BorderSizePixel = 0
	closeButton.Parent = leaderboardFrame
	
	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		UIManager.HideLeaderboard()
	end)

	print("Napoleonic Leaderboard UI Created")
end

function UIManager.UpdateLeaderboard()
	if not leaderboardScrollingFrame or not leaderboardPlayerTemplate then return end

	-- Clear existing entries
	for _, child in ipairs(leaderboardScrollingFrame:GetChildren()) do
		if child:IsA("Frame") then -- Only remove player rows, not layout
			child:Destroy()
		end
	end

	local players = Players:GetPlayers()
	-- Sort players by kills (descending)
	table.sort(players, function(a, b)
		local killsA = a.leaderstats and a.leaderstats:FindFirstChild("Kills") and a.leaderstats.Kills.Value or 0
		local killsB = b.leaderstats and b.leaderstats:FindFirstChild("Kills") and b.leaderstats.Kills.Value or 0
		return killsA > killsB
	end)

	local layoutOrder = 0
	for _, p in ipairs(players) do
		local kills = p.leaderstats and p.leaderstats:FindFirstChild("Kills") and p.leaderstats.Kills.Value or 0
		local deaths = p.leaderstats and p.leaderstats:FindFirstChild("Deaths") and p.leaderstats.Deaths.Value or 0

		local playerRow = leaderboardPlayerTemplate:Clone()
		playerRow.Name = p.Name
		playerRow.LayoutOrder = layoutOrder
		playerRow.PlayerName.Text = p.Name
		playerRow.Kills.Text = tostring(kills)
		playerRow.Deaths.Text = tostring(deaths)

		-- Assign rank insignia based on kills
		local rankInsignia = playerRow:FindFirstChild("RankInsignia")
		if rankInsignia then
			-- Simple rank logic based on kills
			if kills >= 20 then
				rankInsignia.Image = "rbxassetid://6034328964" -- Marshal/General (placeholder)
			elseif kills >= 15 then
				rankInsignia.Image = "rbxassetid://6034328955" -- Colonel (placeholder)
			elseif kills >= 10 then
				rankInsignia.Image = "rbxassetid://6034328941" -- Captain (placeholder)
			elseif kills >= 5 then
				rankInsignia.Image = "rbxassetid://6034328912" -- Lieutenant (placeholder)
			else
				rankInsignia.Image = "rbxassetid://6034328894" -- Private (placeholder)
			end
		end

		-- Set team appearance - in a real implementation, would use team data
		-- For now, alternate between French/British styling (even/odd)
		if layoutOrder % 2 == 0 then
			-- French styling (blue accents)
			playerRow.BackgroundColor3 = Color3.fromRGB(235, 225, 195)
			if playerRow:FindFirstChild("Separator") then
				playerRow.Separator.BackgroundColor3 = Color3.fromRGB(50, 70, 120)
			end
		else
			-- British styling (red accents)
			playerRow.BackgroundColor3 = Color3.fromRGB(228, 218, 188)
			if playerRow:FindFirstChild("Separator") then
				playerRow.Separator.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
			end
		end

		-- Highlight local player with gold trim
		if p == player then
			local highlight = Instance.new("UIStroke")
			highlight.Color = Color3.fromRGB(200, 160, 60) -- Gold trim
			highlight.Thickness = 2
			highlight.Parent = playerRow
		end

		playerRow.Parent = leaderboardScrollingFrame
		layoutOrder = layoutOrder + 1
	end
end

function UIManager.ShowLeaderboard()
	if not leaderboardFrame then UIManager.CreateLeaderboard() end
	if not leaderboardFrame or isLeaderboardVisible then return end

	print("Showing Leaderboard")
	isLeaderboardVisible = true
	UIManager.UpdateLeaderboard() -- Update immediately when shown
	leaderboardFrame.Visible = true

	-- Start update loop if not already running
	if not leaderboardUpdateConnection then
		leaderboardUpdateConnection = RunService.Heartbeat:Connect(function(dt)
			-- Update periodically while visible (e.g., every 1 second)
			-- Using Heartbeat for simplicity, could use a timer
			if math.random() < dt / 1.0 then -- Approx once per second
				UIManager.UpdateLeaderboard()
			end
		end)
	end
end

function UIManager.HideLeaderboard()
	if not leaderboardFrame or not isLeaderboardVisible then return end

	print("Hiding Leaderboard")
	isLeaderboardVisible = false
	leaderboardFrame.Visible = false

	-- Stop update loop
	if leaderboardUpdateConnection then
		leaderboardUpdateConnection:Disconnect()
		leaderboardUpdateConnection = nil
	end
end

function UIManager.ToggleLeaderboard()
	if isLeaderboardVisible then
		UIManager.HideLeaderboard()
	else
		UIManager.ShowLeaderboard()
	end
end

-- Leaderboard Functions End ---


-- Initialize the HUD when the script runs
-- Might need to wait for character spawn depending on dependencies
task.wait(1) -- Simple delay, better to use CharacterAdded if needed earlier
UIManager.CreateHUD()
UIManager.CreateLeaderboard() -- Create leaderboard structure immediately

-- Disable Roblox core UI elements we might replace
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- Assuming no backpack needed


return UIManager
