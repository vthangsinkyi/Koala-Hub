local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
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
local InterfaceManager = Fluent and loadstring(game:HttpGet("https://raw.githubusercontent.com/Day326/Koala-Hub/refs/heads/main/InterfaceManager.lua"))()

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
        autoSeedShop = false,
        autoBuy = false
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
    local u9F = require(ReplicatedStorage.Top_Text)
    local u10F = require(ReplicatedStorage.NPC_MOD)
    local u13F = require(ReplicatedStorage.Data.EnumRegistry.ItemTypeEnums)
    local u12F = require(ReplicatedStorage.Modules.CalculatePetValue)

    local function u21F(p19)
        local v20 = time()
        while time() - v20 < p19 do
            task.wait()
            if u17F then return false end
        end
        return true
    end

    local function u28F(p23, p24)
        local v26 = {}
        if p23 then
            for _, v27 in pairs(p23:GetChildren()) do
                if v27:IsA("Tool") and (v27:FindFirstChild("Item_String") or v27:GetAttribute("PET_UUID")) and (v27:GetAttribute(u6F.Favorite) ~= true or p24) then
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

    local npcPosition = Vector2.new(0, 0, 0)
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local sellActive = false
    local u17F = false

    local function findSteven()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Steven" or obj:FindFirstChild("SellNPC") then
                return obj
            end
        end
        return nil
    end

    local function teleportToSteven()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local steven = findSteven()
        if steven and steven:IsA("Model") then
            npcPosition = steven:FindFirstChild("HumanoidRootPart") and steven.HumanoidRootPart.Position or steven.Position
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
                break
            end
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - npcPosition).Magnitude
            if distance > 10 then
                teleportToSteven()
                wait(2)
            end
            u17F = true
            local v50 = u28F(LocalPlayer.Character)
            local v51 = u28F(LocalPlayer.Backpack)
            local v52 = {}
            for _, v53 in pairs(v50) do
                table.insert(v52, v53)
            end
            for _, v54 in pairs(v51) do
                table.insert(v52, v54)
            end
            local v55 = 0
            local v59 = {}
            local v61 = {}
            for _, v56 in pairs(v52) do
                if v56:GetAttribute(u6F.ITEM_TYPE) == u13F.Pet then
                    v55 = v55 + u12F(v56)
                    table.insert(v59, v56)
                else
                    v55 = v55 + u29F(v56)
                    table.insert(v61, v56)
                end
            end
            if v55 > 0 then
                if #v61 > 0 then
                    u36F(v61, true, ReplicatedStorage.GameEvents.Sell_Item)
                end
                for _, v66 in v59 do
                    ReplicatedStorage.GameEvents.SellPet_RE:FireServer(v66)
                end
                showNotify("Success", "Sold items for " .. u11F.Comma(tostring(v55)) .. " coins.", 5)
            else
                showNotify("Warning", "No sellable items found.", 5)
            end
            u17F = false
            wait(1)
        end
    end

    Tabs.Farming:AddToggle("AutoSellInventory", {
        Title = "Sell Item Inventory",
        Description = "Automatically sells non-favorited items and teleports to Steven",
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

    local gears = {
        "Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advance Sprinkler",
        "Medium Toy", "Medium Treat", "Godly Sprinkler", "Magnifying Glass", "Tanning Mirror",
        "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot", "Levelup Lollipop"
    }
    local checkedGears = {}
    for _, g in ipairs(gears) do
        checkedGears[g] = false
    end

    local seeds = {
        "Carrot", "Strawberry", "Blueberry", "Tomato", "Bamboo", "Cactus", "Pepper", "Cacao", "Blood Banana",
        "Giant Pinecone", "Pumpkin", "Beanstalk", "Watermelon", "Pineapple", "Grape", "Sugar Apple",
        "Pitcher Plant", "Feijoa", "Prickly Pear", "Pear", "Apple", "Dragonfruit", "Coconut",
        "Mushroom", "Orange Tulip", "Corn"
    }
    local checkedSeeds = {}
    for _, s in ipairs(seeds) do
        checkedSeeds[s] = false
    end

    local gearActive = false
    local cosmeticActive = false
    local seedActive = false
    local autoBuy = settings.autoBuy

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
                break
            end
            local highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 1
            highlight.Adornee = workspace:FindFirstChild("GearNPC")
            highlight.Parent = workspace:FindFirstChild("GearNPC")
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 0 }):Play()
            openShop("Here is the gear shop", "Gear_Shop", workspace:FindFirstChild("GearNPC"), highlight, LocalPlayer)
            wait(1)
        end
    end

    local function autoCosmeticShop()
        while cosmeticActive do
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                wait(1)
                break
            end
            local highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 1
            highlight.Adornee = workspace:FindFirstChild("CosmeticNPC")
            highlight.Parent = workspace:FindFirstChild("CosmeticNPC")
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 0 }):Play()
            openShop("Spruce up your farm with cosmetics!", "CosmeticShop_UI", workspace:FindFirstChild("CosmeticNPC"), highlight, LocalPlayer)
            wait(1)
        end
    end

    local function autoSeedShop()
        while seedActive do
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                wait(1)
                break
            end
            local highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 1
            highlight.Adornee = workspace:FindFirstChild("SeedNPC")
            highlight.Parent = workspace:FindFirstChild("SeedNPC")
            TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { OutlineTransparency = 0 }):Play()
            openShop("Here are the seeds that are in stock", "Seed_Shop", workspace:FindFirstChild("SeedNPC"), highlight, LocalPlayer)
            wait(1)
        end
    end

    Tabs.Shop:AddDropdown("GearSelect", {
        Title = "Select Gear",
        Values = gears,
        Multi = true,
        Default = {},
        Callback = function(value)
            for g, _ in pairs(checkedGears) do
                checkedGears[g] = false
            end
            for _, v in ipairs(value) do
                checkedGears[v] = true
            end
        end
    })

    Tabs.Shop:AddDropdown("SeedSelect", {
        Title = "Select Seed",
        Values = seeds,
        Multi = true,
        Default = {},
        Callback = function(value)
            for s, _ in pairs(checkedSeeds) do
                checkedSeeds[s] = false
            end
            for _, v in ipairs(value) do
                checkedSeeds[v] = true
            end
        end
    })

    Tabs.Shop:AddToggle("AutoBuy", {
        Title = "Auto Buy",
        Description = "Automatically buys selected gears and seeds",
        Default = autoBuy,
        Callback = function(value)
            settings.autoBuy = value
            saveSettings(settings)
            if value then
                task.spawn(function()
                    while autoBuy do
                        for g, v in pairs(checkedGears) do
                            if v then
                                pcall(function()
                                    ReplicatedStorage.GameEvents.BuyGearStock:FireServer(g)
                                end)
                            end
                        end
                        for s, v in pairs(checkedSeeds) do
                            if v then
                                pcall(function()
                                    ReplicatedStorage.GameEvents.BuySeedStock:FireServer(s)
                                end)
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

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
