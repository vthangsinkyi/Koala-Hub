-- Server Rejoiner Script with Persistent Settings
-- By [Day] - Fixed Version

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Persistent settings
local SETTINGS_KEY = "ServerRejoinerSettings"
local defaultSettings = {
    autoPublicRejoin = false,
    autoPrivateRejoin = false,
    rejoinDelay = 20,
    uiEnabled = true
}

-- Load settings with error handling
local function loadSettings()
    if not isfile(SETTINGS_KEY .. ".json") then
        return defaultSettings
    end
    
    local success, saved = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_KEY .. ".json"))
    end)
    return success and saved or defaultSettings
end

-- Save settings with error handling
local function saveSettings(settings)
    pcall(function()
        writefile(SETTINGS_KEY .. ".json", HttpService:JSONEncode(settings))
    end)
end

local settings = loadSettings()

-- Simple notification system
local function showNotify(title, content, duration)
    duration = duration or 5
    local gui = Instance.new("ScreenGui")
    local frame = Instance.new("Frame")
    local titleLabel = Instance.new("TextLabel")
    local contentLabel = Instance.new("TextLabel")
    
    gui.Name = "ServerRejoinerNotify"
    gui.Parent = CoreGui
    
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

-- Create main UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerRejoinerUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = settings.uiEnabled
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "Server Rejoiner"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

-- Auto Rejoin Toggles
local AutoPublicToggle = Instance.new("TextButton")
AutoPublicToggle.Text = "Auto Public: " .. (settings.autoPublicRejoin and "ON" or "OFF")
AutoPublicToggle.Size = UDim2.new(1, -20, 0, 40)
AutoPublicToggle.Position = UDim2.new(0, 10, 0, 50)
AutoPublicToggle.Font = Enum.Font.SourceSans
AutoPublicToggle.TextSize = 16
AutoPublicToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoPublicToggle.BackgroundColor3 = settings.autoPublicRejoin and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
AutoPublicToggle.BorderSizePixel = 0
AutoPublicToggle.Parent = MainFrame

local AutoPrivateToggle = Instance.new("TextButton")
AutoPrivateToggle.Text = "Auto Private: " .. (settings.autoPrivateRejoin and "ON" or "OFF")
AutoPrivateToggle.Size = UDim2.new(1, -20, 0, 40)
AutoPrivateToggle.Position = UDim2.new(0, 10, 0, 100)
AutoPrivateToggle.Font = Enum.Font.SourceSans
AutoPrivateToggle.TextSize = 16
AutoPrivateToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoPrivateToggle.BackgroundColor3 = settings.autoPrivateRejoin and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
AutoPrivateToggle.BorderSizePixel = 0
AutoPrivateToggle.Parent = MainFrame

-- Manual Rejoin Buttons
local RejoinPublicBtn = Instance.new("TextButton")
RejoinPublicBtn.Text = "Rejoin Public Now"
RejoinPublicBtn.Size = UDim2.new(1, -20, 0, 40)
RejoinPublicBtn.Position = UDim2.new(0, 10, 0, 150)
RejoinPublicBtn.Font = Enum.Font.SourceSans
RejoinPublicBtn.TextSize = 16
RejoinPublicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinPublicBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RejoinPublicBtn.BorderSizePixel = 0
RejoinPublicBtn.Parent = MainFrame

local RejoinPrivateBtn = Instance.new("TextButton")
RejoinPrivateBtn.Text = "Rejoin Private Now"
RejoinPrivateBtn.Size = UDim2.new(1, -20, 0, 40)
RejoinPrivateBtn.Position = UDim2.new(0, 10, 0, 200)
RejoinPrivateBtn.Font = Enum.Font.SourceSans
RejoinPrivateBtn.TextSize = 16
RejoinPrivateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinPrivateBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RejoinPrivateBtn.BorderSizePixel = 0
RejoinPrivateBtn.Parent = MainFrame

-- UI Toggle Button
local ToggleUIButton = Instance.new("TextButton")
ToggleUIButton.Size = UDim2.new(0, 40, 0, 40)
ToggleUIButton.Position = UDim2.new(0, 10, 0, 10)
ToggleUIButton.BackgroundColor3 = settings.uiEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
ToggleUIButton.Text = settings.uiEnabled and "ON" or "OFF"
ToggleUIButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleUIButton.Font = Enum.Font.SourceSansBold
ToggleUIButton.TextSize = 14
ToggleUIButton.ZIndex = 100
ToggleUIButton.Parent = CoreGui

-- Button functionality
AutoPublicToggle.MouseButton1Click:Connect(function()
    settings.autoPublicRejoin = not settings.autoPublicRejoin
    if settings.autoPublicRejoin then
        settings.autoPrivateRejoin = false
        AutoPrivateToggle.Text = "Auto Private: OFF"
        AutoPrivateToggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    end
    AutoPublicToggle.Text = "Auto Public: " .. (settings.autoPublicRejoin and "ON" or "OFF")
    AutoPublicToggle.BackgroundColor3 = settings.autoPublicRejoin and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
    saveSettings(settings)
end)

AutoPrivateToggle.MouseButton1Click:Connect(function()
    settings.autoPrivateRejoin = not settings.autoPrivateRejoin
    if settings.autoPrivateRejoin then
        settings.autoPublicRejoin = false
        AutoPublicToggle.Text = "Auto Public: OFF"
        AutoPublicToggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    end
    AutoPrivateToggle.Text = "Auto Private: " .. (settings.autoPrivateRejoin and "ON" or "OFF")
    AutoPrivateToggle.BackgroundColor3 = settings.autoPrivateRejoin and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
    saveSettings(settings)
end)

RejoinPublicBtn.MouseButton1Click:Connect(function()
    rejoinServer(settings.rejoinDelay, true)
end)

RejoinPrivateBtn.MouseButton1Click:Connect(function()
    rejoinServer(settings.rejoinDelay, false)
end)

ToggleUIButton.MouseButton1Click:Connect(function()
    settings.uiEnabled = not settings.uiEnabled
    ToggleUIButton.BackgroundColor3 = settings.uiEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    ToggleUIButton.Text = settings.uiEnabled and "ON" or "OFF"
    MainFrame.Visible = settings.uiEnabled
    saveSettings(settings)
end)

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

showNotify("Server Rejoiner", "Script loaded successfully!", 5)