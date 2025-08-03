local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

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
    local success, saved = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_KEY .. ".json"))
    end)
    return success and saved or defaultSettings
end

-- Save settings
local function saveSettings(settings)
    pcall(function()
        writefile(SETTINGS_KEY .. ".json", HttpService:JSONEncode(settings))
    end)
end

local settings = loadSettings()

-- Fluent UI setup with better error handling
local Fluent, SaveManager, InterfaceManager
local fluentLoaded = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    return true
end)

if not fluentLoaded then
    -- Fallback to simple UI if Fluent fails
    local function simpleNotify(title, content, duration)
        duration = duration or 5
        local gui = Instance.new("ScreenGui")
        local frame = Instance.new("Frame")
        local titleLabel = Instance.new("TextLabel")
        local contentLabel = Instance.new("TextLabel")
        
        gui.Name = "SimpleNotify"
        gui.Parent = game:GetService("CoreGui")
        
        frame.Size = UDim2.new(0, 300, 0, 100)
        frame.Position = UDim2.new(1, -320, 1, -120)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        
        titleLabel.Text = title
        titleLabel.Size = UDim2.new(1, -20, 0, 30)
        titleLabel.Position = UDim2.new(0, 10, 0, 10)
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextSize = 18
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.BackgroundTransparency = 1
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = frame
        
        contentLabel.Text = content
        contentLabel.Size = UDim2.new(1, -20, 1, -40)
        contentLabel.Position = UDim2.new(0, 10, 0, 40)
        contentLabel.Font = Enum.Font.SourceSans
        contentLabel.TextSize = 14
        contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        contentLabel.BackgroundTransparency = 1
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.Parent = frame
        
        task.delay(duration, function()
            gui:Destroy()
        end)
    end
    
    simpleNotify("Error", "Fluent UI failed to load. Using limited functionality.", 10)
    return
end

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

local function showNotify(title, content, duration)
    Window:Notify({
        Title = title,
        Content = content,
        Duration = duration or 5
    })
end

local function rejoinServer(delay, isPublic)
    delay = delay or settings.rejoinDelay
    
    local isPrivate = getServerType()
    local playerCount = getPlayerCount()
    
    if isPrivate and playerCount < 2 and not isPublic then
        showNotify("Warning", "Private server has no other players.", delay)
        return false
    end
    
    local message = isPrivate and not isPublic and "Rejoining private server..." or "Rejoining public server..."
    showNotify("Rejoining", message .. " in " .. delay .. " seconds", delay)
    
    task.wait(delay)
    
    if isPrivate and not isPublic then
        local privateServerId = ReplicatedStorage:FindFirstChild("PrivateServerId") or ReplicatedStorage:FindFirstChild("PSID")
        if privateServerId then
            TeleportService:TeleportToPrivateServer(game.PlaceId, privateServerId.Value)
        else
            TeleportService:Teleport(game.PlaceId)
        end
    else
        -- Enhanced public server rejoining logic
        local success, result = pcall(function()
            local code = TeleportService:ReserveServer(game.PlaceId)
            if code then
                TeleportService:TeleportToPrivateServer(game.PlaceId, code)
            else
                error("Failed to reserve server")
            end
        end)
        
        if not success then
            showNotify("Error", "Failed to reserve server. Rejoining with JobId...", 5)
            task.wait(1)
            
            local successJobId = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, currentJobId)
            end)
            
            if not successJobId then
                showNotify("Error", "Failed to rejoin with JobId. Joining new server...", 5)
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
    Description = "Automatically check player count in private servers",
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

-- UI Toggle Button (works with Fluent UI)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = settings.uiEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
toggleButton.Text = settings.uiEnabled and "ON" or "OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.ZIndex = 100
toggleButton.Parent = game:GetService("CoreGui")

toggleButton.MouseButton1Click:Connect(function()
    settings.uiEnabled = not settings.uiEnabled
    toggleButton.BackgroundColor3 = settings.uiEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    toggleButton.Text = settings.uiEnabled and "ON" or "OFF"
    Window.Visible = settings.uiEnabled
    saveSettings(settings)
end)

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
showNotify("Server Rejoiner", "Script loaded successfully!", 5)