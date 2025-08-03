-- Server Rejoiner with Fluent UI
-- Fixed version with proper error handling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Load Fluent UI with error handling
local Fluent, SaveManager, InterfaceManager
local fluentLoaded = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    return true
end)

if not fluentLoaded then
    warn("Fluent UI failed to load! Check your executor's permissions.")
    return
end

-- Persistent settings
local SETTINGS_KEY = "ServerRejoinerSettings"
local defaultSettings = {
    autoPublicRejoin = false,
    autoPrivateRejoin = false,
    rejoinDelay = 20,
    autoCheckPlayers = true,
    uiEnabled = true
}

-- Load settings
local function loadSettings()
    if not isfile then return defaultSettings end
    if not isfile(SETTINGS_KEY .. ".json") then
        return defaultSettings
    end
    
    local success, saved = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_KEY .. ".json"))
    end)
    return success and saved or defaultSettings
end

-- Save settings
local function saveSettings(settings)
    if not isfile then return end
    pcall(function()
        writefile(SETTINGS_KEY .. ".json", HttpService:JSONEncode(settings))
    end)
end

local settings = loadSettings()

-- Create main window
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
local currentJobId = game.JobId

local function getServerType()
    local success, result = pcall(function()
        return ReplicatedStorage:FindFirstChild("PrivateServerId") ~= nil or
               ReplicatedStorage:FindFirstChild("PSID") ~= nil
    end)
    return success and result
end

local function getPlayerCount()
    return #Players:GetPlayers()
end

local function rejoinServer(delay, isPublic)
    delay = delay or settings.rejoinDelay
    
    local isPrivate = getServerType()
    local playerCount = getPlayerCount()
    
    if isPrivate and playerCount < 2 and not isPublic and settings.autoCheckPlayers then
        Window:Dialog({
            Title = "Warning",
            Content = "Private server has no other players. Rejoin public server or invite friends first.",
            Buttons = {
                {
                    Title = "OK",
                    Callback = function() end
                }
            }
        })
        return false
    end
    
    local message = isPrivate and not isPublic and "Rejoining private server..." or "Rejoining public server..."
    Window:Notify({
        Title = "Rejoining",
        Content = message .. " in " .. delay .. " seconds",
        Duration = delay
    })
    
    task.wait(delay)
    
    if isPrivate and not isPublic then
        local privateServerId = ReplicatedStorage:FindFirstChild("PrivateServerId") or ReplicatedStorage:FindFirstChild("PSID")
        if privateServerId then
            TeleportService:TeleportToPrivateServer(game.PlaceId, privateServerId.Value)
        else
            TeleportService:Teleport(game.PlaceId)
        end
    else
        -- Enhanced public server rejoining
        local success, result = pcall(function()
            local code = TeleportService:ReserveServer(game.PlaceId)
            if code then
                TeleportService:TeleportToPrivateServer(game.PlaceId, code)
            else
                error("Failed to reserve server")
            end
        end)
        
        if not success then
            Window:Notify({
                Title = "Error",
                Content = "Failed to reserve server. Rejoining with JobId...",
                Duration = 5
            })
            task.wait(1)
            
            local successJobId = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, currentJobId)
            end)
            
            if not successJobId then
                Window:Notify({
                    Title = "Error",
                    Content = "Failed to rejoin with JobId. Joining new server...",
                    Duration = 5
                })
                task.wait(1)
                TeleportService:Teleport(game.PlaceId)
            end
        end
    end
    
    return true
end

-- Auto Rejoin Logic
spawn(function()
    while task.wait(1) do
        if settings.uiEnabled then
            if settings.autoPublicRejoin then
                rejoinServer(settings.rejoinDelay, true)
            elseif settings.autoPrivateRejoin then
                rejoinServer(settings.rejoinDelay, false)
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
    Default = settings.autoPublicRejoin,
    Callback = function(value)
        settings.autoPublicRejoin = value
        if value then 
            settings.autoPrivateRejoin = false
            Tabs.Main:GetElement("AutoPrivateRejoin"):Set(false)
        end
        saveSettings(settings)
    end
})

Tabs.Main:AddToggle("AutoPrivateRejoin", {
    Title = "Auto Private Rejoin",
    Description = "Enable to auto-rejoin private server",
    Default = settings.autoPrivateRejoin,
    Callback = function(value)
        settings.autoPrivateRejoin = value
        if value then 
            settings.autoPublicRejoin = false
            Tabs.Main:GetElement("AutoPublicRejoin"):Set(false)
        end
        saveSettings(settings)
    end
})

Tabs.Main:AddButton({
    Title = "Rejoin Public Now",
    Description = "Immediately rejoin public server",
    Callback = function()
        rejoinServer(settings.rejoinDelay, true)
    end
})

Tabs.Main:AddButton({
    Title = "Rejoin Private Now",
    Description = "Immediately rejoin private server",
    Callback = function()
        rejoinServer(settings.rejoinDelay, false)
    end
})

Tabs.Main:AddParagraph({
    Title = "Information",
    Content = "Private server rejoin checks for other players first."
})

-- Settings Tab
Tabs.Settings:AddSlider("RejoinDelay", {
    Title = "Rejoin Delay (seconds)",
    Description = "Time before rejoining executes",
    Default = settings.rejoinDelay,
    Min = 5,
    Max = 60,
    Rounding = 0,
    Callback = function(value)
        settings.rejoinDelay = value
        saveSettings(settings)
    end
})

Tabs.Settings:AddToggle("AutoCheckPlayers", {
    Title = "Auto Check Players",
    Description = "Check player count in private servers",
    Default = settings.autoCheckPlayers,
    Callback = function(value)
        settings.autoCheckPlayers = value
        saveSettings(settings)
    end
})

Tabs.Settings:AddToggle("UIEnabled", {
    Title = "UI Enabled",
    Description = "Toggle the UI visibility",
    Default = settings.uiEnabled,
    Callback = function(value)
        settings.uiEnabled = value
        saveSettings(settings)
        Window.Visible = value
    end
})

-- Initialize SaveManager if available
if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    InterfaceManager:SetFolder("Fluent")
    SaveManager:SetFolder("FluentConfigs")
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
end

Window:SelectTab(1)

-- Initial notification
Window:Notify({
    Title = "Server Rejoiner",
    Content = "Script loaded successfully!",
    Duration = 5
})
