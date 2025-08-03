local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

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

local function rejoinServer(delay)
    delay = delay or 20
    if not TeleportService then return end
    
    local isPrivate = getServerType()
    local playerCount = getPlayerCount()
    
    if isPrivate and playerCount < 2 then
        Window:Dialog({
            Title = "Warning",
            Content = "Private server has no other players. Rejoin public server or invite friends first.",
            Buttons = {
                {
                    Title = "Rejoin Public",
                    Callback = function()
                        showMessage("Rejoining", "Rejoining public server in " .. delay .. " seconds...", delay)
                        task.wait(delay)
                        TeleportService:Teleport(game.PlaceId)
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function() end
                }
            }
        })
        return
    end
    
    local message = isPrivate and "Rejoining private server..." or "Rejoining public server..."
    showMessage("Rejoining", message .. " in " .. delay .. " seconds", delay)
    
    task.wait(delay)
    
    if isPrivate then
        local privateServerId = ReplicatedStorage:FindFirstChild("PrivateServerId") or ReplicatedStorage:FindFirstChild("PSID")
        if privateServerId and privateServerId.Value then
            TeleportService:TeleportToPrivateServer(game.PlaceId, privateServerId.Value)
        else
            TeleportService:Teleport(game.PlaceId)
        end
    else
        TeleportService:Teleport(game.PlaceId)
    end
end

-- Create UI
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Main Tab
Tabs.Main:AddButton({
    Title = "Rejoin Public Server",
    Description = "Rejoin the current public server",
    Callback = function()
        if getServerType() then
            Window:Dialog({
                Title = "Warning",
                Content = "You are in a private server. Rejoin private instead?",
                Buttons = {
                    {
                        Title = "Rejoin Private",
                        Callback = function()
                            rejoinServer()
                        end
                    },
                    {
                        Title = "Rejoin Public",
                        Callback = function()
                            rejoinServer()
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function() end
                    }
                }
            })
        else
            rejoinServer()
        end
    end
})

Tabs.Main:AddButton({
    Title = "Rejoin Private Server",
    Description = "Rejoin the current private server",
    Callback = function()
        if not getServerType() then
            Window:Dialog({
                Title = "Warning",
                Content = "You are not in a private server. Rejoin public instead?",
                Buttons = {
                    {
                        Title = "Rejoin Public",
                        Callback = function()
                            rejoinServer()
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function() end
                    }
                }
            })
        else
            rejoinServer()
        end
    end
})

Tabs.Main:AddParagraph({
    Title = "Information",
    Content = "Private server rejoin will check for other players first. If none are found, you'll get a warning."
})

-- Settings Tab
local delaySetting = 20
local autoCheckSetting = true

Tabs.Settings:AddSlider("RejoinDelay", {
    Title = "Rejoin Delay (seconds)",
    Description = "Time before rejoining executes",
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
    Description = "Automatically check player count in private servers",
    Default = autoCheckSetting,
    Callback = function(value)
        autoCheckSetting = value
    end
})

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

showMessage("Server Rejoiner", "Script loaded successfully!", 5)