local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Fluent UI setup
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Server Rejoiner",
    SubTitle = "by [Day]",
    TabWidth = 160,
    Size = UDim2.fromOffset(400, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Main functionality
local function getServerType()
    if not ReplicatedStorage then return false end
    local success, result = pcall(function()
        return ReplicatedStorage:FindFirstChild("PrivateServerId") ~= nil or
               ReplicatedStorage:FindFirstChild("PSID") ~= nil
    end)
    return success and result or false
end

local function getPlayerCount()
    if not Players then return 0 end
    return #Players:GetPlayers()
end

local function showMessage(title, content, delay)
    Window:Dialog({
        Title = title,
        Content = content,
        Buttons = {
            {
                Title = "OK",
                Callback = function() end
            }
        }
    })
    task.wait(delay or 5)
end

local currentJobId = game.JobId
local function rejoinServer(delay, isPublic)
    delay = delay or 20
    if not TeleportService then return end
    
    local isPrivate = getServerType()
    local playerCount = getPlayerCount()
    
    if isPrivate and playerCount < 2 and not isPublic then
        showMessage("Warning", "Private server has no other players. Rejoin public server or invite friends first.", delay)
        return
    end
    
    local message = isPrivate and "Rejoining private server..." or "Rejoining public server..."
    showMessage("Rejoining", message .. " in " .. delay .. " seconds", delay)
    
    task.wait(delay)
    
    if isPrivate and not isPublic then
        local privateServerId = ReplicatedStorage:FindFirstChild("PrivateServerId") or ReplicatedStorage:FindFirstChild("PSID")
        if privateServerId and privateServerId.Value then
            TeleportService:TeleportToPrivateServer(game.PlaceId, privateServerId.Value)
        else
            TeleportService:Teleport(game.PlaceId, currentJobId)
        end
    else
        -- Attempt to rejoin the same public server
        local success, result = pcall(function()
            local code = TeleportService:ReserveServer(game.PlaceId)
            TeleportService:TeleportToPrivateServer(game.PlaceId, code, {LocalPlayer})
            currentJobId = game.JobId -- Update JobId after rejoin
        end)
        if not success then
            showMessage("Error", "Failed to reserve server. Joining a new public server...", 5)
            TeleportService:Teleport(game.PlaceId) -- Fallback to any public server
        end
    end
end

-- Auto Rejoin Logic
local autoPublicRejoin = false
local autoPrivateRejoin = false
local uiEnabled = true

spawn(function()
    while wait(1) do
        if uiEnabled then
            if autoPublicRejoin then
                rejoinServer(20, true)
            elseif autoPrivateRejoin then
                rejoinServer(20, false)
            end
        end
    end
end)

-- Create UI
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Main Tab
Tabs.Main:AddToggle("AutoPublicRejoin", {
    Title = "Auto Public Rejoin",
    Description = "Enable to auto-rejoin public server",
    Default = autoPublicRejoin,
    Callback = function(value)
        autoPublicRejoin = value
        if value then autoPrivateRejoin = false end
    end
})

Tabs.Main:AddToggle("AutoPrivateRejoin", {
    Title = "Auto Private Rejoin",
    Description = "Enable to auto-rejoin private server",
    Default = autoPrivateRejoin,
    Callback = function(value)
        autoPrivateRejoin = value
        if value then autoPublicRejoin = false end
    end
})

Tabs.Main:AddParagraph({
    Title = "Information",
    Content = "Private server rejoin checks for other players. If none, it warns you."
})

-- Settings Tab
local delaySetting = 20
local autoCheckSetting = true

Tabs.Settings:AddSlider("RejoinDelay", {
    Title = "Rejoin Delay (seconds)",
    Description = "Delay",
    Default = delaySetting,
    Min = 5,
    Max = 60,
    Rounding = 0,
    Callback = function(value)
        delaySetting = value
    end
})

Tabs.Settings:AddToggle("AutoCheckPlayers", {
    Title = "Auto Check Players",
    Description = "Check",
    Default = autoCheckSetting,
    Callback = function(value)
        autoCheckSetting = value
    end
})

-- UI Toggle Button with Icon-like Behavior
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
toggleButton.Text = uiEnabled and "☑" or "☐"
toggleButton.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
toggleButton.MouseButton1Click:Connect(function()
    uiEnabled = not uiEnabled
    toggleButton.BackgroundColor3 = uiEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    toggleButton.Text = uiEnabled and "☑" or "☐"
    Window.Visible = uiEnabled
end)

-- Save settings
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("ServerRejoiner")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

SaveManager:SetFolder("ServerRejoiner")
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

showMessage("Server Rejoiner", "Script loaded successfully! Toggle UI with the button on the left.", 5)