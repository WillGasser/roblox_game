-- WelcomeUI.lua
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Create the UI
local WelcomeUI = {}

function WelcomeUI.Init()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WelcomeUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0, 0, 0, 0) -- Start small for animation
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner radius to main frame
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 12)
    cornerRadius.Parent = mainFrame
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
    })
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
    titleLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 28
    titleLabel.Text = "Welcome to a Musket Dev Game!"
    titleLabel.TextTransparency = 1 -- Start invisible for animation
    titleLabel.Parent = mainFrame
    
    -- Add subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "SubtitleLabel"
    subtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
    subtitleLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
    subtitleLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    subtitleLabel.TextSize = 20
    subtitleLabel.Text = "It is currently in development :)"
    subtitleLabel.TextTransparency = 1 -- Start invisible for animation
    subtitleLabel.Parent = mainFrame
    
    -- Add decorative elements
    local decorLine = Instance.new("Frame")
    decorLine.Name = "DecorLine"
    decorLine.AnchorPoint = Vector2.new(0.5, 0)
    decorLine.Position = UDim2.new(0.5, 0, 0.32, 0)
    decorLine.Size = UDim2.new(0, 0, 0, 3) -- Start with zero width for animation
    decorLine.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange accent
    decorLine.BorderSizePixel = 0
    decorLine.Parent = mainFrame
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.AnchorPoint = Vector2.new(0.5, 1)
    closeButton.Position = UDim2.new(0.5, 0, 0.85, 0)
    closeButton.Size = UDim2.new(0, 120, 0, 40)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamSemibold
    closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
    closeButton.TextSize = 18
    closeButton.Text = "Let's Go!"
    closeButton.TextTransparency = 1 -- Start invisible for animation
    closeButton.Parent = mainFrame
    
    -- Add corner radius to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    -- Add hover effect to button
    local buttonHoverStart = function()
        TweenService:Create(closeButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 165, 0)}):Play()
    end
    
    local buttonHoverEnd = function()
        TweenService:Create(closeButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
    end
    
    closeButton.MouseEnter:Connect(buttonHoverStart)
    closeButton.MouseLeave:Connect(buttonHoverEnd)
    
    -- Animation sequences
    local function playOpenAnimation()
        -- Animate main frame
        local frameAppear = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 500, 0, 300)}
        )
        frameAppear:Play()
        
        -- Wait a bit before starting the next animations
        task.wait(0.4)
        
        -- Animate title
        local titleAppear = TweenService:Create(
            titleLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        titleAppear:Play()
        
        -- Animate decorative line
        local lineAppear = TweenService:Create(
            decorLine,
            TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.7, 0, 0, 3)}
        )
        lineAppear:Play()
        
        task.wait(0.2)
        
        -- Animate subtitle
        local subtitleAppear = TweenService:Create(
            subtitleLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        subtitleAppear:Play()
        
        task.wait(0.3)
        
        -- Animate button
        local buttonAppear = TweenService:Create(
            closeButton,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        buttonAppear:Play()
        
        -- Add a slight bounce animation to the entire UI
        task.wait(0.5)
        local frameBounce = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, 0, 0.5, 0)}
        )
        frameBounce:Play()
    end
    
    -- Close animation
    local function playCloseAnimation()
        -- Animate button
        local buttonFade = TweenService:Create(
            closeButton,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 1}
        )
        buttonFade:Play()
        
        local subtitleFade = TweenService:Create(
            subtitleLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 1}
        )
        subtitleFade:Play()
        
        task.wait(0.1)
        
        local titleFade = TweenService:Create(
            titleLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 1}
        )
        titleFade:Play()
        
        local lineFade = TweenService:Create(
            decorLine,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, 3)}
        )
        lineFade:Play()
        
        task.wait(0.2)
        
        -- Shrink and fade out main frame
        local frameDisappear = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        frameDisappear:Play()
        
        -- Wait for animation to complete then destroy UI
        frameDisappear.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        playCloseAnimation()
    end)
    
    -- Play open animation
    playOpenAnimation()
    
    return screenGui
end

return WelcomeUI