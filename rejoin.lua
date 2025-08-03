local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Fluent UI setup
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not success then Fluent = nil end
local SaveManager = Fluent and loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = Fluent and loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

if Fluent then
    local Window = Fluent:CreateWindow({
        Title = "Server Rejoiner",
        SubTitle = "by [Day]",
        TabWidth = 160,
        Size = UDim2.fromOffset(400, 350),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift
    })

    -- Persistent settings
    local SETTINGS_KEY = "ServerRejoinerSettings"
    local defaultSettings = {
        autoPublicRejoin = false,
        autoPrivateRejoin = false,
        rejoinDelay = 20,
        uiEnabled = true
    }

    local function loadSettings()
        if not isfile(SETTINGS_KEY .. ".json") then
            return defaultSettings
        end
        local success, saved = pcall(function()
            return HttpService:JSONDecode(readfile(SETTINGS_KEY .. ".json"))
        end)
        return success and saved or defaultSettings
    end

    local function saveSettings(settings)
        pcall(function()
            writefile(SETTINGS_KEY .. ".json", HttpService:JSONEncode(settings))
        end)
    end

    local settings = loadSettings()

    -- Main functionality
    local currentJobId = game.JobId

    local function getServerType()
        local success, result = pcall(function()
            return ReplicatedStorage:FindFirstChild("PrivateServerId") ~= nil or
                   ReplicatedStorage:FindFirstChild("PSID") ~= nil
        end)
        return success and result or false
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
        if not TeleportService then return end
        
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
            if privateServerId and privateServerId.Value then
                TeleportService:TeleportToPrivateServer(game.PlaceId, privateServerId.Value)
            else
                TeleportService:Teleport(game.PlaceId, currentJobId)
            end
        else
            local success, result = pcall(function()
                local code = TeleportService:ReserveServer(game.PlaceId)
                if code then
                    TeleportService:TeleportToPrivateServer(game.PlaceId, code, {LocalPlayer})
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
    local autoPublicRejoin = settings.autoPublicRejoin
    local autoPrivateRejoin = settings.autoPrivateRejoin
    local uiEnabled = settings.uiEnabled

    spawn(function()
        while wait(1) do
            if uiEnabled then
                if autoPublicRejoin then
                    rejoinServer(settings.rejoinDelay, true)
                elseif autoPrivateRejoin then
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
        Default = autoPublicRejoin,
        Callback = function(value)
            autoPublicRejoin = value
            settings.autoPublicRejoin = value
            if value then
                autoPrivateRejoin = false
                settings.autoPrivateRejoin = false
                Tabs.Main:UpdateToggle("AutoPrivateRejoin", false)
            end
            saveSettings(settings)
        end
    })

    Tabs.Main:AddToggle("AutoPrivateRejoin", {
        Title = "Auto Private Rejoin",
        Description = "Enable to auto-rejoin private server",
        Default = autoPrivateRejoin,
        Callback = function(value)
            autoPrivateRejoin = value
            settings.autoPrivateRejoin = value
            if value then
                autoPublicRejoin = false
                settings.autoPublicRejoin = false
                Tabs.Main:UpdateToggle("AutoPublicRejoin", false)
            end
            saveSettings(settings)
        end
    })

    Tabs.Main:AddButton({
        Title = "Rejoin Public Now",
        Description = "Manually rejoin public server",
        Callback = function()
            rejoinServer(settings.rejoinDelay, true)
        end
    })

    Tabs.Main:AddButton({
        Title = "Rejoin Private Now",
        Description = "Manually rejoin private server",
        Callback = function()
            rejoinServer(settings.rejoinDelay, false)
        end
    })

    Tabs.Main:AddParagraph({
        Title = "Information",
        Content = "Private server rejoin checks for other players. If none, it warns you."
    })

    -- Settings Tab
    Tabs.Settings:AddSlider("RejoinDelay", {
        Title = "Rejoin Delay (seconds)",
        Description = "Delay between rejoin attempts",
        Default = settings.rejoinDelay,
        Min = 5,
        Max = 60,
        Rounding = 0,
        Callback = function(value)
            settings.rejoinDelay = value
            saveSettings(settings)
        end
    })

    -- UI Toggle within Fluent
    Tabs.Settings:AddToggle("UIToggle", {
        Title = "Toggle UI",
        Description = "Show/Hide the main UI",
        Default = uiEnabled,
        Callback = function(value)
            uiEnabled = value
            settings.uiEnabled = value
            Window.Visible = uiEnabled
            saveSettings(settings)
        end
    })

    -- Save settings
    if SaveManager and InterfaceManager then
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)

        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})

        InterfaceManager:SetFolder("ServerRejoiner")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)

        SaveManager:SetFolder("ServerRejoiner")
        SaveManager:BuildConfigSection(Tabs.Settings)
    end

    Window:SelectTab(1)
    Window.Visible = uiEnabled

    showNotify("Server Rejoiner", "Script loaded successfully!", 5)
else
    warn("Fluent UI failed to load. Script functionality limited.")
end