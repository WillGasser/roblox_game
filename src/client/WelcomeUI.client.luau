local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Wait for player to load
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create welcome UI
local function createWelcomeUI()
	-- Create the ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WelcomeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Create background frame with blur effect
	local backgroundFrame = Instance.new("Frame")
	backgroundFrame.Name = "Background"
	backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	backgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backgroundFrame.BackgroundTransparency = 0.7
	backgroundFrame.Parent = screenGui
	
	local blurEffect = Instance.new("BlurEffect")
	blurEffect.Size = 10
	blurEffect.Parent = game:GetService("Lighting")
	
	-- Create main container
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.new(0, 500, 0, 300)
	mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	mainContainer.BorderSizePixel = 0
	mainContainer.Parent = screenGui
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainContainer
	
	-- Create a decorative header
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0, 60)
	headerFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 40)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainContainer
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = headerFrame
	
	-- Create title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextColor3 = Color3.fromRGB(255, 245, 220)
	titleLabel.TextSize = 32
	titleLabel.Text = "MUSKET TESTING"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = headerFrame
	
	-- Create musket image
	local musketImage = Instance.new("ImageLabel")
	musketImage.Name = "MusketImage"
	musketImage.Size = UDim2.new(0, 120, 0, 120)
	musketImage.Position = UDim2.new(0.85, 0, 0.6, 0)
	musketImage.BackgroundTransparency = 1
	musketImage.Image = "rbxassetid://11747573833" -- Musket icon (you may need to replace this ID)
	musketImage.ImageTransparency = 0.1
	musketImage.Rotation = 45
	musketImage.Parent = mainContainer
	
	-- Create welcome message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(0.8, 0, 0, 100)
	messageLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.SourceSansSemibold
	messageLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	messageLabel.TextSize = 24
	messageLabel.Text = "Welcome to Musket Testing!\nThis is a WIP musket game\nhave fun :)"
	messageLabel.TextWrapped = true
	messageLabel.Parent = mainContainer
	
	-- Create tap to close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 200, 0, 50)
	closeButton.Position = UDim2.new(0.5, 0, 0.8, 0)
	closeButton.AnchorPoint = Vector2.new(0.5, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Text = "TAP TO CLOSE"
	closeButton.Parent = mainContainer
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = closeButton
	
	-- Add a subtle gradient to the button
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 100, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 70, 40))
	})
	gradient.Parent = closeButton
	
	-- Add gunpowder particles
	local particleEmitter = Instance.new("Frame")
	particleEmitter.Name = "ParticleEmitter"
	particleEmitter.Size = UDim2.new(1, 0, 0, 10)
	particleEmitter.Position = UDim2.new(0, 0, 1, -10)
	particleEmitter.BackgroundTransparency = 1
	particleEmitter.Parent = mainContainer
	
	-- Animation effects
	mainContainer.Position = UDim2.new(0.5, 0, -0.5, 0)
	local targetPosition = UDim2.new(0.5, 0, 0.5, 0)
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainContainer, tweenInfo, {Position = targetPosition})
	
	-- Button hover effect
	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(150, 100, 50)}):Play()
	end)
	
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(120, 80, 40)}):Play()
	end)
	
	-- Close functionality
	closeButton.MouseButton1Click:Connect(function()
		-- Play click sound
		local clickSound = Instance.new("Sound")
		clickSound.SoundId = "rbxassetid://6042054131" -- Click sound
		clickSound.Volume = 0.5
		clickSound.Parent = screenGui
		clickSound:Play()
		
		-- Tween out
		local closeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local closeTween = TweenService:Create(mainContainer, closeInfo, {Position = UDim2.new(0.5, 0, 1.5, 0)})
		closeTween:Play()
		
		-- Fade out background
		local fadeTween = TweenService:Create(backgroundFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		fadeTween:Play()
		
		-- Remove blur
		TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 0}):Play()
		
		-- Clean up
		closeTween.Completed:Connect(function()
			blurEffect:Destroy()
			screenGui:Destroy()
		end)
	end)
	
	-- Start entrance animation
	tween:Play()
	
	-- Add some subtle ambient sound
	local ambientSound = Instance.new("Sound")
	ambientSound.SoundId = "rbxassetid://9113028109" -- Ambient war drums/marching (replace with your own)
	ambientSound.Volume = 0.2
	ambientSound.Looped = true
	ambientSound.Parent = screenGui
	ambientSound:Play()
end

-- Run when player is loaded
createWelcomeUI()
Now, to make this script load when the player joins, you need to update your client initialization file:
lua