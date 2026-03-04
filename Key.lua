local KeySystem = {}
local Player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Config
local CONFIG = {
    Title = "Zyph Hub",
    KeyURL = "https://pastebin.com/raw/YOUR_PASTE_ID",
    DiscordLink = "https://discord.gg/yourinvite",
    Theme = {
        Background = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(0, 120, 215),
        Text = Color3.fromRGB(255, 255, 255),
        Error = Color3.fromRGB(255, 80, 80)
    }
}

-- Utility
local function animate(object, properties, time)
    local info = TweenInfo.new(time or 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(object, info, properties):Play()
end

function KeySystem.Init(MainScriptFunction)
    -- Protect GUI
    local ScreenGui = Instance.new("ScreenGui")
    pcall(function() syn.protect_gui(ScreenGui) end)
    ScreenGui.Name = "TitaniumKeySystem"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Main
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 400, 0, 250)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
    MainFrame.BackgroundColor3 = CONFIG.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Text = CONFIG.Title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.TextColor3 = CONFIG.Theme.Text
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.BackgroundTransparency = 1
    Title.Parent = MainFrame

    -- Key Input
    local KeyInput = Instance.new("TextBox")
    KeyInput.PlaceholderText = "Enter Key Here..."
    KeyInput.Text = ""
    KeyInput.Size = UDim2.new(0.8, 0, 0, 40)
    KeyInput.Position = UDim2.new(0.1, 0, 0.35, 0)
    KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    KeyInput.TextColor3 = CONFIG.Theme.Text
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.TextSize = 16
    KeyInput.Parent = MainFrame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = KeyInput

    -- Status
    local Status = Instance.new("TextLabel")
    Status.Text = "Status: Waiting for key..."
    Status.Size = UDim2.new(1, 0, 0, 20)
    Status.Position = UDim2.new(0, 0, 0.85, 0)
    Status.BackgroundTransparency = 1
    Status.TextColor3 = Color3.fromRGB(150, 150, 150)
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 12
    Status.Parent = MainFrame

    -- Buttons
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(0.8, 0, 0, 40)
    ButtonContainer.Position = UDim2.new(0.1, 0, 0.6, 0)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame

    local function CreateButton(text, posScale, callback)
        local Btn = Instance.new("TextButton")
        Btn.Text = text
        Btn.Size = UDim2.new(0.48, 0, 1, 0)
        Btn.Position = UDim2.new(posScale, 0, 0, 0)
        Btn.BackgroundColor3 = CONFIG.Theme.Accent
        Btn.TextColor3 = CONFIG.Theme.Text
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 14
        Btn.Parent = ButtonContainer
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = Btn
        
        Btn.MouseButton1Click:Connect(callback)
        return Btn
    end

    -- Verify
    local function VerifyKey()
        Status.Text = "Checking key..."
        Status.TextColor3 = CONFIG.Theme.Text
        
        local userKey = KeyInput.Text
        userKey = userKey:gsub("%s+", "")

        spawn(function()
            local success, response = pcall(function()
                return game:HttpGet(CONFIG.KeyURL)
            end)

            if success then
                if string.find(response, userKey) and userKey ~= "" then
                    Status.Text = "Success! Loading..."
                    Status.TextColor3 = Color3.fromRGB(0, 255, 0)
                    
                    wait(1)
                    ScreenGui:Destroy()
                    
                    MainScriptFunction()
                else
                    Status.Text = "Invalid Key"
                    Status.TextColor3 = CONFIG.Theme.Error
                    animate(KeyInput, {BackgroundColor3 = Color3.fromRGB(100, 40, 40)}, 0.2)
                    wait(0.5)
                    animate(KeyInput, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.2)
                end
            else
                Status.Text = "Connection Failed"
                Status.TextColor3 = CONFIG.Theme.Error
            end
        end)
    end

    -- Get Key
    local function GetKey()
        setclipboard(CONFIG.DiscordLink)
        Status.Text = "Discord Link Copied to Clipboard!"
    end

    CreateButton("Verify", 0, VerifyKey)
    CreateButton("Get Key", 0.52, GetKey)
    
    -- Draggable
    local Dragging, DragInput, DragStart, StartPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            DragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)
end

return KeySystem
