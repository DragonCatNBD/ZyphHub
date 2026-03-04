local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/DragonCatNBD/ZyphHub/refs/heads/main/Lib.lua"))()

local CONFIG = {
    Title = "Zyph Hub",
    KeyURL = "https://pastebin.com/raw/c3tER31x", 
    ScriptURL = "https://raw.githubusercontent.com/DragonCatNBD/ZyphHub/refs/heads/main/Main.lua",
    DiscordLink = "https://discord.gg/pxD3EkyDYT" 
}

local function StartKeySystem()
    local Window = Library:CreateWindow({
        Title = CONFIG.Title .. " | Verification"
    })

    local KeyTab = Window:CreateTab("Key System")
    local userEnteredKey = ""

    KeyTab:CreateInput("Access Key", "Enter Key Here...", function(val)
        userEnteredKey = val
    end)

    KeyTab:CreateButton("Verify Access", function()
        Library:Notify("Security", "Validating key...", 3)
        local cleanKey = userEnteredKey:gsub("%s+", "")

        task.spawn(function()
            local s, rawPaste = pcall(function() return game:HttpGet(CONFIG.KeyURL, true) end)
            if s and rawPaste:find(cleanKey) and cleanKey ~= "" then
                _G.VerifiedKey = cleanKey
                Library:Notify("Success", "Loading Titanium Hub...", 2)
                task.wait(1)
                Library:Unload()
                loadstring(game:HttpGet(CONFIG.ScriptURL))()
            else
                Library:Notify("Error", "Invalid key!", 3)
            end
        end)
    end)
end

local function Boot()
    local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(1,0,1,0)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    
    local Text = Instance.new("TextLabel", Main)
    Text.Size = UDim2.new(1,0,1,0)
    Text.BackgroundTransparency = 1
    Text.Text = "TITANIUM"
    Text.TextColor3 = Color3.fromRGB(0, 255, 179)
    Text.Font = Enum.Font.GothamBlack
    Text.TextSize = 80
    Text.TextTransparency = 1

    game:GetService("TweenService"):Create(Text, TweenInfo.new(1.5), {TextTransparency = 0}):Play()
    task.wait(2.5)
    game:GetService("TweenService"):Create(Main, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
    game:GetService("TweenService"):Create(Text, TweenInfo.new(1), {TextTransparency = 1}):Play()
    task.wait(1)
    ScreenGui:Destroy()
    StartKeySystem()
end

Boot()
