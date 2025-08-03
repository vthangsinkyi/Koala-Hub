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

    local function showNotify(title, content, delay)
        Window:Notify({
            Title = title,
            Content = content,
            Duration = delay or 5
        })
    end

    local currentJobId = game.JobId
    local function rejoinServer(delay, isPublic)
        delay = delay or 20
        if not TeleportService then return end
        
        local isPrivate = getServerType()
        local playerCount = getPlayerCount()
        
        if isPrivate and playerCount < 2 and not isPublic then
            showNotify("Warning", "Private server has no other players. Rejoin public server or invite friends first.", delay)
            return
        end
        
        local message = isPrivate and "Rejoining private server..." or "Rejoining public server..."
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
            -- Attempt to rejoin the same public server
            local success, result = pcall(function()
                local code = TeleportService:ReserveServer(game.PlaceId)
                TeleportService:TeleportToPrivateServer(game.PlaceId, code, {LocalPlayer})
                currentJobId = game.JobId -- Update JobId after rejoin
            end)
            if not success then
                showNotify("Error", "Failed to reserve server. Attempting to rejoin with JobId or new server... Error: " .. tostring(result), 5)
                local successJobId, _ = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, currentJobId)
                end)
                if not successJobId then
                    TeleportService:Teleport(game.PlaceId) -- Final fallback
                end
            end
        end
    end

    -- Auto Rejoin Logic
    local autoPublicRejoin = SaveManager and SaveManager:Get("AutoPublicRejoin", false) or false
    local autoPrivateRejoin = SaveManager and SaveManager:Get("AutoPrivateRejoin", false) or false
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
            if SaveManager then SaveManager:Set("AutoPublicRejoin", value) end
            if value then autoPrivateRejoin = false end
        end
    })

    Tabs.Main:AddToggle("AutoPrivateRejoin", {
        Title = "Auto Private Rejoin",
        Description = "Enable to auto-rejoin private server",
        Default = autoPrivateRejoin,
        Callback = function(value)
            autoPrivateRejoin = value
            if SaveManager then SaveManager:Set("AutoPrivateRejoin", value) end
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

    -- UI Toggle Button with Fluent UI Component
    if Window then
        local ToggleTab = Window:AddTab({ Title = "Toggle", Icon = "power" })
        ToggleTab:AddToggle("UIToggle", {
            Title = "Toggle UI",
            Description = "Show/Hide the main UI",
            Default = uiEnabled,
            Callback = function(value)
                uiEnabled = value
                Window.Visible = uiEnabled
                if SaveManager then SaveManager:Set("UIEnabled", uiEnabled) end
            end
        })
    else
        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 50, 0, 50)
        toggleButton.Position = UDim2.new(0, 10, 0, 10)
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        toggleButton.Text = uiEnabled and "☑" or "☐"
        toggleButton.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        if toggleButton.Parent then
            toggleButton.MouseButton1Click:Connect(function()
                uiEnabled = not uiEnabled
                toggleButton.BackgroundColor3 = uiEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                toggleButton.Text = uiEnabled and "☑" or "☐"
                Window.Visible = uiEnabled
                if SaveManager then SaveManager:Set("UIEnabled", uiEnabled) end
            end)
        else
            warn("Failed to create toggle button. PlayerGui inaccessible.")
        end
    end

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

        -- Load saved UI state
        uiEnabled = SaveManager:Get("UIEnabled", true)
        Window.Visible = uiEnabled
    end

    Window:SelectTab(1)

    showNotify("Server Rejoiner", "Script loaded successfully!", 5)
else
    warn("Fluent UI failed to load. Script functionality limited.")
end