local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Library = {}
Library.Connections = {} 
Library.Hidden = false
Library.Registry = {}
Library.ScreenGui = nil

-- Default Theme
Library.Theme = {
    MainColor = Color3.fromRGB(20, 20, 20),
    ElementColor = Color3.fromRGB(30, 30, 30),
    TextColor = Color3.fromRGB(200, 200, 200),
    AccentColor = Color3.fromRGB(0, 255, 179),
    OutlineColor = Color3.fromRGB(0, 255, 179),
}

Library.Visuals = {
    Assets = {},
    Connections = {},
    ParticleFolder = nil
}

function Library.Visuals:Cleanup()
    for _, v in pairs(self.Assets) do v:Destroy() end
    for _, c in pairs(self.Connections) do c:Disconnect() end
    if self.ParticleFolder then self.ParticleFolder:Destroy() self.ParticleFolder = nil end
    self.Assets = {}
    self.Connections = {}
end

function Library.Visuals:SetTime(Hour)
    Lighting.ClockTime = Hour
end

function Library.Visuals:SetParticles(Type)
    if self.Connections["ParticleLoop"] then self.Connections["ParticleLoop"]:Disconnect() end
    if self.ParticleFolder then self.ParticleFolder:Destroy() end
    
    if Type == "None" then return end

    local Config = {}
    if Type == "Snow" then
        Config = {
            Count = 400, Radius = 110, Height = 60, Despawn = -30,
            SpeedMin = 4, SpeedMax = 7, SwayAmp = 0.8, SwayFreq = 1.0,
            SizeMin = 0.6, SizeMax = 1.2, Color = Color3.fromRGB(235, 245, 255),
            Material = Enum.Material.Neon
        }
    elseif Type == "Ash" then
        Config = {
            Count = 350, Radius = 110, Height = 50, Despawn = -20,
            SpeedMin = 2, SpeedMax = 4.5, SwayAmp = 1.5, SwayFreq = 2.0, -- Floaty & Chaotic
            SizeMin = 0.3, SizeMax = 0.7, Color = Color3.fromRGB(80, 80, 80), -- Dark Grey
            Material = Enum.Material.Plastic -- Dull look for ash
        }
    end

    -- Setup
    local Camera = Workspace.CurrentCamera
    local Folder = Instance.new("Folder")
    Folder.Name = "Zyph_"..Type.."_FX"
    Folder.Parent = Workspace
    self.ParticleFolder = Folder

    local Pool = {}
    local math_sin, math_cos, math_random, vector_new = math.sin, math.cos, math.random, Vector3.new
    local StartCamPos = Camera.CFrame.Position

    for i = 1, Config.Count do
        local p = Instance.new("Part")
        p.Name = "P"
        p.Material = Config.Material
        p.Color = Config.Color
        p.Shape = Enum.PartType.Ball
        p.Transparency = 1 
        p.CastShadow = false
        p.CanCollide = false
        p.Anchored = true
        p.Massless = true
        p.Size = vector_new(1,1,1) * (math_random(Config.SizeMin*10, Config.SizeMax*10)/10)
        p.Parent = Folder

        if Type == "Ash" and math_random(1,5) == 1 then
            p.Color = Color3.fromRGB(150, 50, 50) 
            p.Material = Enum.Material.Neon
        end

        local startX = math_random(-Config.Radius, Config.Radius)
        local startZ = math_random(-Config.Radius, Config.Radius)
        local startY = math_random(Config.Despawn, Config.Height)

        table.insert(Pool, {
            Part = p,
            Speed = math_random(Config.SpeedMin*10, Config.SpeedMax*10)/10,
            WaveOff = math_random(0, 100),
            Pos = vector_new(StartCamPos.X + startX, StartCamPos.Y + startY, StartCamPos.Z + startZ),
            MaxAlpha = 0.3,
            WasVisible = true
        })
    end

    -- Main
    self.Connections["ParticleLoop"] = RunService.RenderStepped:Connect(function(dt)
        if not Camera then return end
        local camCF = Camera.CFrame
        local cPos = camCF.Position
        local cLook = camCF.LookVector
        local cX, cY, cZ = cPos.X, cPos.Y, cPos.Z
        local spawnY = cY + Config.Height
        local botLimit = cY + Config.Despawn
        local time = os.clock()

        for i = 1, #Pool do
            local flake = Pool[i]
            
            local oldPos = flake.Pos
            local newY = oldPos.Y - (flake.Speed * dt)
            local waveVal = time * Config.SwayFreq + flake.WaveOff
            local swayX = math_sin(waveVal) * (Config.SwayAmp * dt * 5)
            local swayZ = math_cos(waveVal) * (Config.SwayAmp * dt * 5)
            local newPos = vector_new(oldPos.X + swayX, newY, oldPos.Z + swayZ)
            flake.Pos = newPos

            if newY < botLimit then
                local rX, rZ = math_random(-Config.Radius, Config.Radius), math_random(-Config.Radius, Config.Radius)
                flake.Pos = vector_new(cX + rX, spawnY + math_random(0,15), cZ + rZ)
                flake.Speed = math_random(Config.SpeedMin*10, Config.SpeedMax*10)/10
            end

            local diffX, diffZ = newPos.X - cX, newPos.Z - cZ
            if (diffX*diffX + diffZ*diffZ) > (Config.Radius * Config.Radius) + 400 then
                local rX, rZ = math_random(-Config.Radius, Config.Radius), math_random(-Config.Radius, Config.Radius)
                local rY = math_random(Config.Despawn, Config.Height)
                flake.Pos = vector_new(cX + rX, cY + rY, cZ + rZ)
            end

            local dirX, dirY, dirZ = newPos.X - cX, newPos.Y - cY, newPos.Z - cZ
            local dot = (dirX * cLook.X) + (dirY * cLook.Y) + (dirZ * cLook.Z)

            if dot > 0 then
                flake.Part.Position = newPos
                local distTop, distBot = spawnY - newY, newY - botLimit
                local targetAlpha = flake.MaxAlpha
                if distTop < 15 then targetAlpha = 1 - (distTop * 0.06 * (1-flake.MaxAlpha))
                elseif distBot < 15 then targetAlpha = 1 - (distBot * 0.06 * (1-flake.MaxAlpha)) end
                flake.Part.Transparency = targetAlpha
                flake.WasVisible = true
            elseif flake.WasVisible then
                flake.Part.Transparency = 1
                flake.WasVisible = false
            end
        end
    end)
end

function Library.Visuals:UpdateLighting(Props)
    local CC = Lighting:FindFirstChild("ZyphCC") or Instance.new("ColorCorrectionEffect", Lighting); CC.Name = "ZyphCC"
    CC.Brightness = Props.Brightness or 0; CC.Saturation = Props.Saturation or 0; CC.Contrast = Props.Contrast or 0; CC.TintColor = Props.TintColor or Color3.new(1,1,1)
    
    local Bloom = Lighting:FindFirstChild("ZyphBloom") or Instance.new("BloomEffect", Lighting); Bloom.Name = "ZyphBloom"
    Bloom.Intensity = Props.BloomIntensity or 0; Bloom.Size = Props.BloomSize or 24
    
    local Blur = Lighting:FindFirstChild("ZyphBlur") or Instance.new("BlurEffect", Lighting); Blur.Name = "ZyphBlur"
    Blur.Size = Props.BlurSize or 0
    
    local Rays = Lighting:FindFirstChild("ZyphRays") or Instance.new("SunRaysEffect", Lighting); Rays.Name = "ZyphRays"
    Rays.Intensity = Props.SunRays and 0.25 or 0; Rays.Spread = 1
end

local function ProtectGui(gui)
    if gethui then gui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui) gui.Parent = CoreGui
    else gui.Parent = CoreGui end
end

function Library:AddToRegistry(Obj, Prop, ThemeKey)
    table.insert(Library.Registry, {Object = Obj, Property = Prop, ThemeKey = ThemeKey})
end

function Library:UpdateTheme()
    for _, item in pairs(Library.Registry) do
        if item.Object and item.Object.Parent then
            item.Object[item.Property] = Library.Theme[item.ThemeKey]
        end
    end
end

function Library:SetTheme(Key, Value)
    Library.Theme[Key] = Value
    Library:UpdateTheme()
end

function Library:Notify(Title, Text, Duration)
    local Holder = Library.ScreenGui:FindFirstChild("NotifyHolder")
    if not Holder then return end

    local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1, 0, 0, 60); Frame.Position = UDim2.new(1, 20, 0, 0); Frame.BackgroundColor3 = Library.Theme.ElementColor; Frame.Parent = Holder; Library:AddToRegistry(Frame, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke"); Stroke.Color = Library.Theme.OutlineColor; Stroke.Thickness = 1; Stroke.Parent = Frame; Library:AddToRegistry(Stroke, "Color", "OutlineColor")
    local Ttl = Instance.new("TextLabel"); Ttl.Size = UDim2.new(1, -10, 0, 20); Ttl.Position = UDim2.new(0, 10, 0, 5); Ttl.BackgroundTransparency = 1; Ttl.Text = Title; Ttl.TextColor3 = Library.Theme.AccentColor; Ttl.Font = Enum.Font.GothamBold; Ttl.TextSize = 14; Ttl.TextXAlignment = Enum.TextXAlignment.Left; Ttl.Parent = Frame; Library:AddToRegistry(Ttl, "TextColor3", "AccentColor")
    local Msg = Instance.new("TextLabel"); Msg.Size = UDim2.new(1, -10, 0, 30); Msg.Position = UDim2.new(0, 10, 0, 25); Msg.BackgroundTransparency = 1; Msg.Text = Text; Msg.TextColor3 = Library.Theme.TextColor; Msg.Font = Enum.Font.Gotham; Msg.TextSize = 13; Msg.TextXAlignment = Enum.TextXAlignment.Left; Msg.TextWrapped = true; Msg.Parent = Frame; Library:AddToRegistry(Msg, "TextColor3", "TextColor")

    TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0,0,0,0)}):Play()
    task.delay(Duration or 3, function() TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(1,20,0,0)}):Play(); task.wait(0.5); Frame:Destroy() end)
end

function Library:Unload()
    for _, c in pairs(Library.Connections) do c:Disconnect() end
    Library.Visuals:Cleanup()
    local Effects = {"ZyphCC", "ZyphBloom", "ZyphBlur", "ZyphRays", "MenuBlur"}
    for _, e in pairs(Effects) do if Lighting:FindFirstChild(e) then Lighting:FindFirstChild(e):Destroy() end end
    if Library.ScreenGui then Library.ScreenGui:Destroy() end
end

function Library:CreateWindow(Config)
    local Title = Config.Title or "Zyph Hub"
    Library.GuiKey = Config.Keybind or Enum.KeyCode.RightControl

    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "ZyphUI_V8"; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ProtectGui(ScreenGui); Library.ScreenGui = ScreenGui

    local Blur = Instance.new("BlurEffect"); Blur.Name = "MenuBlur"; Blur.Size = 0; Blur.Parent = Lighting
    local NotifyHolder = Instance.new("Frame"); NotifyHolder.Name = "NotifyHolder"; NotifyHolder.Size = UDim2.new(0, 250, 1, 0); NotifyHolder.Position = UDim2.new(1, -260, 0, 0); NotifyHolder.BackgroundTransparency = 1; NotifyHolder.Parent = ScreenGui
    Instance.new("UIListLayout", NotifyHolder).Padding = UDim.new(0, 10); Instance.new("UIListLayout", NotifyHolder).VerticalAlignment = Enum.VerticalAlignment.Bottom; Instance.new("UIListLayout", NotifyHolder).HorizontalAlignment = Enum.HorizontalAlignment.Right; Instance.new("UIPadding", NotifyHolder).PaddingBottom = UDim.new(0, 20)

    local function ToggleMenu()
        Library.Hidden = not Library.Hidden; ScreenGui.Enabled = not Library.Hidden
        if Library.Hidden then TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play(); Library:Notify("Hidden", "Press "..Library.GuiKey.Name.." to open.", 3)
        else TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 18}):Play() end
    end
    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, gp) if input.KeyCode == Library.GuiKey and not gp then ToggleMenu() end end))
    TweenService:Create(Blur, TweenInfo.new(1), {Size = 18}):Play()

    local MainFrame = Instance.new("Frame"); MainFrame.Size = UDim2.new(0, 600, 0, 450); MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225); MainFrame.BackgroundColor3 = Library.Theme.MainColor; MainFrame.Parent = ScreenGui; Library:AddToRegistry(MainFrame, "BackgroundColor3", "MainColor"); Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    local Outline = Instance.new("UIStroke"); Outline.Color = Library.Theme.OutlineColor; Outline.Thickness = 3; Outline.Parent = MainFrame; Library:AddToRegistry(Outline, "Color", "OutlineColor")

    local Dragging, DragStart, StartPos
    MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true; DragStart = input.Position; StartPos = MainFrame.Position end end)
    UserInputService.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement and Dragging then local Delta = input.Position - DragStart; TweenService:Create(MainFrame, TweenInfo.new(0.05), {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)}):Play() end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)

    local Header = Instance.new("TextLabel"); Header.Size = UDim2.new(1, -100, 0, 40); Header.Position = UDim2.new(0, 20, 0, 0); Header.BackgroundTransparency = 1; Header.Text = Title; Header.TextColor3 = Library.Theme.TextColor; Header.Font = Enum.Font.GothamBlack; Header.TextSize = 22; Header.TextXAlignment = Enum.TextXAlignment.Left; Header.Parent = MainFrame; Library:AddToRegistry(Header, "TextColor3", "TextColor")
    local Controls = Instance.new("Frame"); Controls.Size = UDim2.new(0, 80, 0, 30); Controls.Position = UDim2.new(1, -90, 0, 5); Controls.BackgroundTransparency = 1; Controls.Parent = MainFrame
    local CLayout = Instance.new("UIListLayout"); CLayout.FillDirection = Enum.FillDirection.Horizontal; CLayout.Padding = UDim.new(0, 5); CLayout.Parent = Controls
    local function MakeCtrlBtn(Sym, Col, Func) local B = Instance.new("TextButton"); B.Size = UDim2.new(0, 35, 1, 0); B.BackgroundColor3 = Color3.fromRGB(40,40,40); B.Text = Sym; B.TextColor3 = Col; B.Font = Enum.Font.GothamBold; B.TextSize = 16; B.Parent = Controls; Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6); B.MouseButton1Click:Connect(Func) end
    MakeCtrlBtn("-", Color3.fromRGB(255, 200, 0), ToggleMenu); MakeCtrlBtn("X", Color3.fromRGB(255, 80, 80), function() Library:Unload() end)

    local TabHolder = Instance.new("Frame"); TabHolder.Size = UDim2.new(0, 140, 1, -50); TabHolder.Position = UDim2.new(0, 15, 0, 45); TabHolder.BackgroundColor3 = Library.Theme.ElementColor; TabHolder.Parent = MainFrame; Library:AddToRegistry(TabHolder, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", TabHolder).CornerRadius = UDim.new(0, 6); Instance.new("UIListLayout", TabHolder).Padding = UDim.new(0, 5); Instance.new("UIPadding", TabHolder).PaddingTop = UDim.new(0, 10)
    local PageHolder = Instance.new("Frame"); PageHolder.Size = UDim2.new(1, -170, 1, -50); PageHolder.Position = UDim2.new(0, 160, 0, 45); PageHolder.BackgroundTransparency = 1; PageHolder.Parent = MainFrame

    local WindowObj = {}; local First = true
    function WindowObj:CreateTab(Name)
        local TabBtn = Instance.new("TextButton"); TabBtn.Size = UDim2.new(1,0,0,32); TabBtn.BackgroundTransparency = 1; TabBtn.Text = Name; TabBtn.TextColor3 = Color3.fromRGB(150,150,150); TabBtn.Font = Enum.Font.GothamBold; TabBtn.TextSize = 14; TabBtn.Parent = TabHolder
        local Page = Instance.new("ScrollingFrame"); Page.Size = UDim2.new(1,0,1,0); Page.BackgroundTransparency = 1; Page.ScrollBarThickness = 2; Page.ScrollBarImageColor3 = Library.Theme.AccentColor; Page.Visible = false; Page.Parent = PageHolder; Library:AddToRegistry(Page, "ScrollBarImageColor3", "AccentColor")
        local PLayout = Instance.new("UIListLayout"); PLayout.Padding = UDim.new(0, 8); PLayout.Parent = Page
        PLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Page.CanvasSize = UDim2.new(0,0,0,PLayout.AbsoluteContentSize.Y+20) end); Instance.new("UIPadding", Page).PaddingTop = UDim.new(0, 5)
        if First then First = false; Page.Visible = true; TabBtn.TextColor3 = Library.Theme.AccentColor; Library:AddToRegistry(TabBtn, "TextColor3", "AccentColor") end
        TabBtn.MouseButton1Click:Connect(function() for _,v in pairs(TabHolder:GetChildren()) do if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150,150,150)}):Play() end end; for _,v in pairs(PageHolder:GetChildren()) do v.Visible = false end; Page.Visible = true; TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Library.Theme.AccentColor}):Play() end)

        local TabObj = {}
        -- BUTTON
        function TabObj:CreateButton(Text, Callback)
            local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1, 0, 0, 38); Btn.BackgroundColor3 = Library.Theme.ElementColor; Btn.Text = ""; Btn.AutoButtonColor = false; Btn.Parent = Page; Library:AddToRegistry(Btn, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
            local Str = Instance.new("UIStroke"); Str.Color = Library.Theme.AccentColor; Str.Transparency = 1; Str.Parent = Btn; Library:AddToRegistry(Str, "Color", "AccentColor")
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(1,0,1,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.Parent = Btn; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            Btn.MouseEnter:Connect(function() TweenService:Create(Str, TweenInfo.new(0.2), {Transparency = 0.5}):Play() end); Btn.MouseLeave:Connect(function() TweenService:Create(Str, TweenInfo.new(0.2), {Transparency = 1}):Play() end); Btn.MouseButton1Click:Connect(Callback)
        end
        -- TOGGLE
        function TabObj:CreateToggle(Text, Default, Callback)
            local Toggled = Default or false
            local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1, 0, 0, 38); Btn.BackgroundColor3 = Library.Theme.ElementColor; Btn.Text = ""; Btn.AutoButtonColor = false; Btn.Parent = Page; Library:AddToRegistry(Btn, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(0.7,0,1,0); Lbl.Position = UDim2.new(0,10,0,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Btn; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            local Switch = Instance.new("Frame"); Switch.Size = UDim2.new(0, 42, 0, 22); Switch.Position = UDim2.new(1, -50, 0.5, -11); Switch.BackgroundColor3 = Toggled and Library.Theme.AccentColor or Color3.fromRGB(50,50,50); Switch.Parent = Btn; if Toggled then Library:AddToRegistry(Switch, "BackgroundColor3", "AccentColor") end; Instance.new("UICorner", Switch).CornerRadius = UDim.new(1,0)
            local Dot = Instance.new("Frame"); Dot.Size = UDim2.new(0, 18, 0, 18); Dot.Position = Toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9); Dot.BackgroundColor3 = Color3.new(1,1,1); Dot.Parent = Switch; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
            local function Update(Val) Toggled = Val; Callback(Toggled); TweenService:Create(Dot, TweenInfo.new(0.2), {Position = Toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play(); TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Toggled and Library.Theme.AccentColor or Color3.fromRGB(50,50,50)}):Play(); if Toggled then Library:AddToRegistry(Switch, "BackgroundColor3", "AccentColor") end end
            Btn.MouseButton1Click:Connect(function() Update(not Toggled) end)
            return {Set = function(self, val) Update(val) end}
        end
        -- SLIDER
        function TabObj:CreateSlider(Text, Min, Max, Default, Callback)
            local Val = Default or Min
            local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1,0,0,55); Frame.BackgroundColor3 = Library.Theme.ElementColor; Frame.Parent = Page; Library:AddToRegistry(Frame, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,6)
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(1,-20,0,25); Lbl.Position = UDim2.new(0,10,0,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Frame; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            local ValLbl = Instance.new("TextLabel"); ValLbl.Size = UDim2.new(1,-20,0,25); ValLbl.BackgroundTransparency = 1; ValLbl.Text = tostring(Val); ValLbl.TextColor3 = Color3.fromRGB(150,150,150); ValLbl.Font = Enum.Font.Gotham; ValLbl.TextSize = 13; ValLbl.TextXAlignment = Enum.TextXAlignment.Right; ValLbl.Parent = Frame
            local Bar = Instance.new("TextButton"); Bar.Size = UDim2.new(1,-20,0,6); Bar.Position = UDim2.new(0,10,0,35); Bar.BackgroundColor3 = Color3.fromRGB(50,50,50); Bar.Text = ""; Bar.AutoButtonColor = false; Bar.Parent = Frame; Instance.new("UICorner", Bar).CornerRadius = UDim.new(1,0)
            local Fill = Instance.new("Frame"); Fill.Size = UDim2.new((Val-Min)/(Max-Min), 0, 1, 0); Fill.BackgroundColor3 = Library.Theme.AccentColor; Fill.Parent = Bar; Library:AddToRegistry(Fill, "BackgroundColor3", "AccentColor"); Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
            local function Update(NewVal) NewVal = math.clamp(NewVal, Min, Max); local S = (NewVal - Min) / (Max - Min); Fill.Size = UDim2.new(S, 0, 1, 0); ValLbl.Text = tostring(NewVal); Callback(NewVal) end
            local Drag = false; Bar.MouseButton1Down:Connect(function() Drag = true end); UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Drag = false end end); UserInputService.InputChanged:Connect(function(i) if Drag and i.UserInputType == Enum.UserInputType.MouseMovement then local S = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1); Update(math.floor(Min + ((Max-Min)*S))) end end)
            return {Set = function(self, val) Update(val) end}
        end
        -- DROPDOWN
        function TabObj:CreateDropdown(Text, Options, Callback)
            local Open = false
            local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1,0,0,40); Frame.BackgroundColor3 = Library.Theme.ElementColor; Frame.ClipsDescendants = true; Frame.Parent = Page; Library:AddToRegistry(Frame, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,6)
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(1,-40,0,40); Lbl.Position = UDim2.new(0,10,0,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Frame; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            local Arrow = Instance.new("ImageLabel"); Arrow.Size = UDim2.new(0,20,0,20); Arrow.Position = UDim2.new(1,-30,0,10); Arrow.BackgroundTransparency = 1; Arrow.Image = "rbxassetid://6034818372"; Arrow.Parent = Frame
            local List = Instance.new("Frame"); List.Size = UDim2.new(1,-10,0,0); List.Position = UDim2.new(0,5,0,40); List.BackgroundTransparency = 1; List.Parent = Frame; local LLayout = Instance.new("UIListLayout"); LLayout.Padding = UDim.new(0,2); LLayout.Parent = List
            local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1,0,0,40); Btn.BackgroundTransparency = 1; Btn.Text = ""; Btn.Parent = Frame
            local function Refresh()
                for _,v in pairs(List:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _,opt in pairs(Options) do
                    local OBtn = Instance.new("TextButton"); OBtn.Size = UDim2.new(1,0,0,25); OBtn.BackgroundColor3 = Color3.fromRGB(40,40,40); OBtn.Text = opt; OBtn.TextColor3 = Color3.fromRGB(200,200,200); OBtn.Font = Enum.Font.Gotham; OBtn.TextSize = 13; OBtn.Parent = List; Instance.new("UICorner", OBtn).CornerRadius = UDim.new(0,4)
                    OBtn.MouseButton1Click:Connect(function() Callback(opt); Lbl.Text = Text..": "..opt; Open = false; TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,40)}):Play(); TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play() end)
                end
            end
            Refresh(); Btn.MouseButton1Click:Connect(function() Open = not Open; TweenService:Create(Frame, TweenInfo.new(0.2), {Size = Open and UDim2.new(1,0,0,45+(#Options*27)) or UDim2.new(1,0,0,40)}):Play(); TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = Open and 180 or 0}):Play() end)
            return {Set = function(self, val) end}
        end
        -- COLOR PICKER
        function TabObj:CreateColorPicker(Text, Default, Callback)
            local Color = Default or Color3.new(1,1,1); local Open = false; local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1,0,0,40); Frame.BackgroundColor3 = Library.Theme.ElementColor; Frame.ClipsDescendants = true; Frame.Parent = Page; Library:AddToRegistry(Frame, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,6)
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(0.6,0,0,40); Lbl.Position = UDim2.new(0,10,0,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Frame; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            local Preview = Instance.new("TextButton"); Preview.Size = UDim2.new(0,40,0,20); Preview.Position = UDim2.new(1,-50,0,10); Preview.BackgroundColor3 = Color; Preview.Text = ""; Preview.Parent = Frame; Instance.new("UICorner", Preview).CornerRadius = UDim.new(0,4)
            local Sliders = Instance.new("Frame"); Sliders.Size = UDim2.new(1,-20,0,100); Sliders.Position = UDim2.new(0,10,0,45); Sliders.BackgroundTransparency = 1; Sliders.Parent = Frame
            local R, G, B = math.floor(Color.R*255), math.floor(Color.G*255), math.floor(Color.B*255)
            local function Update() Color = Color3.fromRGB(R,G,B); Preview.BackgroundColor3 = Color; Callback(Color) end
            local function MakeRGB(Type, Y)
                local SFrame = Instance.new("Frame"); SFrame.Size = UDim2.new(1,0,0,20); SFrame.Position = UDim2.new(0,0,0,Y); SFrame.BackgroundTransparency = 1; SFrame.Parent = Sliders
                local SLbl = Instance.new("TextLabel"); SLbl.Size = UDim2.new(0,20,1,0); SLbl.Text = Type; SLbl.TextColor3 = Library.Theme.TextColor; SLbl.BackgroundTransparency = 1; SLbl.Font = Enum.Font.GothamBold; SLbl.Parent = SFrame; Library:AddToRegistry(SLbl, "TextColor3", "TextColor")
                local Bar = Instance.new("TextButton"); Bar.Size = UDim2.new(1,-30,0,6); Bar.Position = UDim2.new(0,30,0.5,-3); Bar.BackgroundColor3 = Color3.fromRGB(50,50,50); Bar.Text = ""; Bar.AutoButtonColor = false; Bar.Parent = SFrame; Instance.new("UICorner", Bar).CornerRadius = UDim.new(1,0)
                local Fill = Instance.new("Frame"); local Val = (Type=="R" and R or Type=="G" and G or B); Fill.Size = UDim2.new(Val/255,0,1,0); Fill.BackgroundColor3 = (Type=="R" and Color3.new(1,0,0) or Type=="G" and Color3.new(0,1,0) or Color3.new(0,0,1)); Fill.Parent = Bar; Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
                local Drag = false; Bar.MouseButton1Down:Connect(function() Drag = true end); UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Drag = false end end); UserInputService.InputChanged:Connect(function(i) if Drag and i.UserInputType == Enum.UserInputType.MouseMovement then local S = math.clamp((i.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1); Fill.Size = UDim2.new(S,0,1,0); local V = math.floor(S*255); if Type == "R" then R=V elseif Type == "G" then G=V else B=V end; Update() end end)
            end
            MakeRGB("R", 0); MakeRGB("G", 30); MakeRGB("B", 60)
            Preview.MouseButton1Click:Connect(function() Open = not Open; TweenService:Create(Frame, TweenInfo.new(0.2), {Size = Open and UDim2.new(1,0,0,150) or UDim2.new(1,0,0,40)}):Play() end)
        end
        -- KEYBIND
        function TabObj:CreateKeybind(Text, Default, Callback)
            local Key = Default or Enum.KeyCode.RightControl; local Waiting = false; local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1,0,0,40); Frame.BackgroundColor3 = Library.Theme.ElementColor; Frame.Parent = Page; Library:AddToRegistry(Frame, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,6)
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(0.5,0,1,0); Lbl.Position = UDim2.new(0,10,0,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Frame; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            local Bind = Instance.new("TextButton"); Bind.Size = UDim2.new(0,80,0,24); Bind.Position = UDim2.new(1,-90,0.5,-12); Bind.BackgroundColor3 = Color3.fromRGB(40,40,40); Bind.Text = Key.Name; Bind.TextColor3 = Color3.fromRGB(200,200,200); Bind.Font = Enum.Font.Gotham; Bind.TextSize = 13; Bind.Parent = Frame; Instance.new("UICorner", Bind).CornerRadius = UDim.new(0,4)
            Bind.MouseButton1Click:Connect(function() Waiting = true; Bind.Text = "..."; Bind.TextColor3 = Library.Theme.AccentColor end)
            table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input) if Waiting and input.UserInputType == Enum.UserInputType.Keyboard then Key = input.KeyCode; Bind.Text = Key.Name; Bind.TextColor3 = Color3.fromRGB(200,200,200); Waiting = false; Callback(Key) end end))
        end
        -- INPUT
        function TabObj:CreateInput(Text, Placeholder, Callback)
            local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(1,0,0,45); Frame.BackgroundColor3 = Library.Theme.ElementColor; Frame.Parent = Page; Library:AddToRegistry(Frame, "BackgroundColor3", "ElementColor"); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,6)
            local Lbl = Instance.new("TextLabel"); Lbl.Size = UDim2.new(0.4,0,1,0); Lbl.Position = UDim2.new(0,10,0,0); Lbl.BackgroundTransparency = 1; Lbl.Text = Text; Lbl.TextColor3 = Library.Theme.TextColor; Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Frame; Library:AddToRegistry(Lbl, "TextColor3", "TextColor")
            local Box = Instance.new("TextBox"); Box.Size = UDim2.new(0.55, -5, 0, 30); Box.Position = UDim2.new(0.45, 0, 0.5, -15); Box.BackgroundColor3 = Color3.fromRGB(20,20,20); Box.PlaceholderText = Placeholder or "..."; Box.Text = ""; Box.TextColor3 = Color3.new(1,1,1); Box.Font = Enum.Font.Gotham; Box.TextSize = 13; Box.Parent = Frame; Instance.new("UICorner", Box).CornerRadius = UDim.new(0,4)
            Box.FocusLost:Connect(function(enter) if enter then Callback(Box.Text) end end)
        end

        return TabObj
    end
    return WindowObj
end

return Library
