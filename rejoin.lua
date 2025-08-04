local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Fluent UI setup
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not success then
    warn("Fluent UI failed to load. Using fallback UI.")
    Fluent = nil
end
local SaveManager = Fluent and loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = Fluent and loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

if Fluent then
    local Window = Fluent:CreateWindow({
        Title = "Koala Hub",
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
        uiEnabled = true,
        autoSellInventory = false,
        autoGearShop = false,
        autoCosmeticShop = false,
        autoSeedShop = false
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
        if Window and Window.Notify then
            Window:Notify({
                Title = title,
                Content = content,
                Duration = duration or 5
            })
        else
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
            
            task.delay(duration or 5, function()
                gui:Destroy()
            end)
        end
    end

    local function rejoinServer(delay, isPublic)
        delay = delay or settings.rejoinDelay
        if not TeleportService then return end
        
        local isPrivate = getServerType()
        local playerCount = getPlayerCount()
        
        if isPrivate and not isPublic then
            if playerCount < 2 then
                showNotify("Warning", "Your private server only has 1 player. Please get more players by inviting your friends or use an alt acc.", delay)
                return false
            end
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
        Farming = Window:AddTab({ Title = "Farming", Icon = "leaf" }),
        Shop = Window:AddTab({ Title = "Shop", Icon = "shopping" }),
        Misc = Window:AddTab({ Title = "Misc", Icon = "list" }),
        JoinServer = Window:AddTab({ Title = "Join Server", Icon = "link" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    -- Main Tab
    Tabs.Main:AddParagraph({
        Title = "Information",
        Content = "This tab is reserved for future features."
    })

    -- Farming Tab
    local u6F = require(ReplicatedStorage.Data.EnumRegistry.InventoryServiceEnums)
    local u29F = require(ReplicatedStorage.Modules.CalculatePlantValue)
    local u11F = require(ReplicatedStorage.Comma_Module)

    local function u28F(p23)
        local v26 = {}
        if p23 then
            for _, v27 in pairs(p23:GetChildren()) do
                if v27:IsA("Tool") and (v27:FindFirstChild("Item_String") or v27:GetAttribute("PET_UUID")) and v27:GetAttribute(u6F.Favorite) ~= true then
                    table.insert(v26, v27)
                end
            end
        end
        return v26
    end

    local function u36F(p30, p31, p32)
        local v33 = 0
        for _, v34 in p30 do
            local v35 = u29F(v34)
            if p31 then
                v33 = v33 + v35
            end
        end
        if p32 and v33 > 0 then
            p32:FireServer()
        end
        return v33
    end

    local npcPosition = Vector3.new(0, 0, 0)
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local sellActive = false

    local function findNPC()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "NPC_Sell" or obj:FindFirstChild("SellPrompt") then
                return obj
            end
        end
        return nil
    end

    local function teleportToNPC()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local npc = findNPC()
        if npc and npc:IsA("Model") then
            npcPosition = npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart.Position or npc.Position
        end
        local humanoidRootPart = character.HumanoidRootPart
        local tween = TweenService:Create(humanoidRootPart, tweenInfo, { Position = npcPosition })
        tween:Play()
        tween.Completed:Wait()
    end

    local function autoSellInventory()
        while sellActive do
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                wait(1)
                continue
            end
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - npcPosition).Magnitude
            if distance > 10 then
                teleportToNPC()
                wait(2)
            end
            local v50 = u28F(LocalPlayer.Character)
            local v51 = u28F(LocalPlayer.Backpack)
            local v52 = {}
            for _, v53 in pairs(v50) do
                table.insert(v52, v53)
            end
            for _, v54 in pairs(v51) do
                table.insert(v52, v54)
            end
            local v55 = u36F(v52, true, ReplicatedStorage.GameEvents.Sell_Inventory)
            if v55 > 0 then
                showNotify("Success", "Sold items for " .. u11F.Comma(tostring(v55)) .. " coins.", 5)
            else
                showNotify("Warning", "No sellable items found.", 5)
            end
            wait(1)
        end
    end

    Tabs.Farming:AddToggle("AutoSellInventory", {
        Title = "Sell Item Inventory",
        Description = "Automatically sells non-favorited items and teleports to NPC",
        Default = settings.autoSellInventory,
        Callback = function(value)
            settings.autoSellInventory = value
            sellActive = value
            saveSettings(settings)
            if value then
                autoSellInventory()
            end
        end
    })

    -- Shop Tab
    local u7S = require(ReplicatedStorage.Top_Text)
    local u11S = require(ReplicatedStorage.NPC_MOD)
    local u12S = require(ReplicatedStorage.Modules.GuiController)

    local gearActive = false
    local cosmeticActive = false
    local seedActive = false

    local function cancelYes(parent, highlight, player)
        u11S.End_Speak(player)
        if highlight then
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 1 }):Play()
            game.Debris:AddItem(highlight, 0.2)
        end
        u7S.TakeAwayResponses(parent, player)
        script.Parent.Enabled = true
    end

    local function openShop(shopName, uiName, parent, highlight, player)
        while true do
            if not player.Character then break end
            u11S.Start_Speak(player)
            if highlight and highlight ~= nil then
                TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 1 }):Play()
                game.Debris:AddItem(highlight, 0.2)
            end
            script.Parent.Enabled = false
            u7S.NpcText(parent, shopName, true)
            task.wait(1)
            u12S:Open(player.PlayerGui[uiName])
            u7S.TakeAwayResponses(parent, player)
            script.Parent.Enabled = true
            u11S.End_Speak(player)
            break
        end
    end

    local function autoGearShop()
        while gearActive do
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                wait(1)
                continue
            end
            local highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 1
            highlight.Adornee = u2
            highlight.Parent = u2
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 0 }):Play()
            openShop("Here is the gear shop", "Gear_Shop", u3, highlight, LocalPlayer)
            wait(1)
        end
    end

    local function autoCosmeticShop()
        while cosmeticActive do
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                wait(1)
                continue
            end
            local highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 1
            highlight.Adornee = u2
            highlight.Parent = u2
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 0 }):Play()
            openShop("Spruce up your farm with cosmetics!", "CosmeticShop_UI", u2, highlight, LocalPlayer)
            wait(1)
        end
    end

    local function autoSeedShop()
        while seedActive do
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                wait(1)
                continue
            end
            local highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 1
            highlight.Adornee = u2
            highlight.Parent = u2
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 0 }):Play()
            openShop("Here are the seeds that are in stock", "Seed_Shop", u2, highlight, LocalPlayer)
            wait(1)
        end
    end

    Tabs.Shop:AddToggle("AutoGearShop", {
        Title = "Gear Shop",
        Description = "Automatically opens the gear shop",
        Default = settings.autoGearShop,
        Callback = function(value)
            settings.autoGearShop = value
            gearActive = value
            saveSettings(settings)
            if value then
                autoGearShop()
            end
        end
    })

    Tabs.Shop:AddToggle("AutoCosmeticShop", {
        Title = "Cosmetic Shop",
        Description = "Automatically opens the cosmetic shop",
        Default = settings.autoCosmeticShop,
        Callback = function(value)
            settings.autoCosmeticShop = value
            cosmeticActive = value
            saveSettings(settings)
            if value then
                autoCosmeticShop()
            end
        end
    })

    Tabs.Shop:AddToggle("AutoSeedShop", {
        Title = "Seed Shop",
        Description = "Automatically opens the seed shop",
        Default = settings.autoSeedShop,
        Callback = function(value)
            settings.autoSeedShop = value
            seedActive = value
            saveSettings(settings)
            if value then
                autoSeedShop()
            end
        end
    })

    -- Misc Tab
    Tabs.Misc:AddParagraph({
        Title = "Information",
        Content = "This tab is reserved for miscellaneous features."
    })

    -- Join Server Tab
    Tabs.JoinServer:AddToggle("AutoPublicRejoin", {
        Title = "Auto Public Rejoin",
        Description = "Enable to auto-rejoin public server",
        Default = autoPublicRejoin,
        Callback = function(value)
            autoPublicRejoin = value
            settings.autoPublicRejoin = value
            if value then
                autoPrivateRejoin = false
                settings.autoPrivateRejoin = false
                Tabs.JoinServer:GetElement("AutoPrivateRejoin"):SetState(false)
            end
            saveSettings(settings)
        end
    })

    Tabs.JoinServer:AddToggle("AutoPrivateRejoin", {
        Title = "Auto Private Rejoin",
        Description = "Enable to auto-rejoin private server",
        Default = autoPrivateRejoin,
        Callback = function(value)
            autoPrivateRejoin = value
            settings.autoPrivateRejoin = value
            if value then
                autoPublicRejoin = false
                settings.autoPublicRejoin = false
                Tabs.JoinServer:GetElement("AutoPublicRejoin"):SetState(false)
            end
            saveSettings(settings)
        end
    })

    Tabs.JoinServer:AddButton({
        Title = "Rejoin Public Now",
        Description = "Manually rejoin public server",
        Callback = function()
            rejoinServer(settings.rejoinDelay, true)
        end
    })

    Tabs.JoinServer:AddButton({
        Title = "Rejoin Private Now",
        Description = "Manually rejoin private server",
        Callback = function()
            rejoinServer(settings.rejoinDelay, false)
        end
    })

    Tabs.JoinServer:AddParagraph({
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

    Tabs.Settings:AddToggle("UIToggle", {
        Title = "Toggle Main GUI",
        Description = "Show/Hide the main UI with icon",
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
    warn("Fluent UI failed to load. Using fallback UI.")
end

-- Add Icon-Based Toggle Outside Fluent UI (left side)
local ToggleIconButton = Instance.new("ImageButton")
ToggleIconButton.Size = UDim2.new(0, 40, 0, 40)
ToggleIconButton.Position = UDim2.new(0, 10, 0, 100)
ToggleIconButton.BackgroundColor3 = (Fluent and Fluent.Visible or true) and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
ToggleIconButton.Image = "rbxassetid://6031068426"
ToggleIconButton.ZIndex = 100

local successParent = pcall(function()
    ToggleIconButton.Parent = CoreGui
end)
if not successParent then
    warn("Failed to parent ToggleIconButton to CoreGui. Check script context.")
else
    ToggleIconButton.MouseButton1Click:Connect(function()
        local uiEnabled = not (Fluent and Fluent.Visible or false)
        if Fluent and Fluent.Visible ~= nil then
            Fluent.Visible = uiEnabled
        end
        if _G.Window then
            _G.Window.Visible = uiEnabled
        end
        ToggleIconButton.BackgroundColor3 = uiEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        saveSettings({uiEnabled = uiEnabled})
    end)
end
