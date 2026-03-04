local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/JesterCat533/ZyphLib/refs/heads/main/lib.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Toggles = {
    Aimbot = false, FOVVisible = false, Speed = false, Jump = false,
    Noclip = false, Triggerbot = false, Fly = false, Orbit = false,
    SafeReload = false, Chams = false, ESP = false
}
local Values = {
    FOV = 100, AimStrength = 1, AimPart = "Head", Speed = 16, Jump = 50,
    FlySpeed = 50, OrbitSpeed = 5, OrbitHeight = 10, TriggerDelay = 0.1
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 255, 179)
FOVCircle.Filled = false
FOVCircle.Visible = false

local function GetClosestPlayer()
    local target = nil
    local dist = math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(v.Character[Values.AimPart].Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local magnitude = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if magnitude < dist and magnitude <= Values.FOV then
                    local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
                    local part = workspace:FindPartOnRayWithIgnoreList(Ray.new(ray.Origin, ray.Direction * 500), {LocalPlayer.Character, v.Character})
                    if not part then
                        dist = magnitude
                        target = v
                    end
                end
            end
        end
    end
    return target
end

local Window = Library:CreateWindow({
    Title = "Titanium Hub | Main",
    Keybind = Enum.KeyCode.RightControl
})

local PlayerTab = Window:CreateTab("Player")
local VisualTab = Window:CreateTab("Visual")
local WorldTab = Window:CreateTab("World")
local ShaderTab = Window:CreateTab("Shader")
local MiscTab = Window:CreateTab("Misc")
local SettingsTab = Window:CreateTab("Settings")

-- PLAYER TAB
PlayerTab:CreateToggle("Enable Aimbot", false, function(v) Toggles.Aimbot = v end)
PlayerTab:CreateDropdown("Aim Part", {"Head", "HumanoidRootPart"}, function(v) Values.AimPart = v end)
PlayerTab:CreateSlider("Aimbot Strength", 1, 10, 1, function(v) Values.AimStrength = v / 10 end)
PlayerTab:CreateToggle("Show FOV Circle", false, function(v) Toggles.FOVVisible = v end)
PlayerTab:CreateSlider("FOV Radius", 30, 800, 100, function(v) Values.FOV = v end)

PlayerTab:CreateButton("--- Movement ---", function() end)
PlayerTab:CreateSlider("WalkSpeed", 1, 1000, 16, function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v end)
PlayerTab:CreateDropdown("Speed Method", {"CFrame", "Humanoid", "Velocity"}, function() end)
PlayerTab:CreateSlider("Jump Power", 1, 1000, 50, function(v) LocalPlayer.Character.Humanoid.JumpPower = v end)

PlayerTab:CreateToggle("Noclip", false, function(v) Toggles.Noclip = v end)
PlayerTab:CreateToggle("Triggerbot", false, function(v) Toggles.Triggerbot = v end)
PlayerTab:CreateSlider("Trigger Delay", 0, 100, 10, function(v) Values.TriggerDelay = v / 100 end)

PlayerTab:CreateToggle("Flight", false, function(v) Toggles.Fly = v end)
PlayerTab:CreateToggle("Orbit Nearest", false, function(v) Toggles.Orbit = v end)

local savedWaypoint = nil
PlayerTab:CreateButton("Set Waypoint", function()
    savedWaypoint = LocalPlayer.Character.HumanoidRootPart.CFrame
    Library:Notify("Waypoints", "Position Saved!", 2)
end)
PlayerTab:CreateButton("TP to Waypoint", function()
    if savedWaypoint then LocalPlayer.Character.HumanoidRootPart.CFrame = savedWaypoint end
end)

-- VISUAL
VisualTab:CreateToggle("Player Chams", false, function(v) Toggles.Chams = v end)
VisualTab:CreateToggle("ESP Lines", false, function(v) Toggles.ESP = v end)
VisualTab:CreateButton("Skin Changer (DEV)", function() end)
VisualTab:CreateButton("Wrap Changer (DEV)", function() end)
VisualTab:CreateButton("Sound Changer (DEV)", function() end)

-- WORLD & SHADER
WorldTab:CreateButton("Disable Kill Zones (DEV)", function() end)
WorldTab:CreateButton("De-sync (DEV)", function() end)

ShaderTab:CreateDropdown("Presets", {"Standard", "Winter", "Hellscape", "Radioactive"}, function(v)
    if v == "Winter" then
        Library.Visuals:SetParticles("Snow")
        Library.Visuals:SetTime(0)
    elseif v == "Hellscape" then
        Library.Visuals:SetParticles("Ash")
        Library.Visuals:SetTime(0)
    elseif v == "Radioactive" then
        Library.Visuals:SetParticles("Ash")
        Library.Visuals:SetTime(6)
    end
end)
ShaderTab:CreateSlider("Time of Day", 0, 24, 12, function(v) Library.Visuals:SetTime(v) end)

-- MISC & SETTINGS
MiscTab:CreateButton("Save Config Locally", function()
    Library:Notify("System", "Config Overwritten Successfully.", 3)
end)
MiscTab:CreateButton("Skybox Changer (DEV)", function() end)

SettingsTab:CreateColorPicker("Accent Color", Library.Theme.AccentColor, function(c) Library:SetTheme("AccentColor", c) end)
SettingsTab:CreateButton("Key Used: " .. (_G.VerifiedKey or "None"), function() end)

-- LOOPS

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Toggles.FOVVisible
    FOVCircle.Radius = Values.FOV
    FOVCircle.Position = UserInputService:GetMouseLocation()

    if Toggles.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            local pos = Camera:WorldToViewportPoint(target.Character[Values.AimPart].Position)
            local mousePos = UserInputService:GetMouseLocation()
            mousemoverel((pos.X - mousePos.X) * Values.AimStrength, (pos.Y - mousePos.Y) * Values.AimStrength)
        end
    end

    -- Triggerbot
    if Toggles.Triggerbot then
        local target = LocalPlayer:GetMouse().Target
        if target and target.Parent:FindFirstChild("Humanoid") then
            mouse1click()
            task.wait(Values.TriggerDelay)
        end
    end

    -- Noclip
    if Toggles.Noclip then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- If u copy my code, do not reupload.
