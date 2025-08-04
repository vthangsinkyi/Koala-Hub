local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage
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
        autoSeedShop = false,
        autoCollect = false,
        autoMid = false,
        autoBuy = false,
        autoShovel = false,
        autoCosmeticBuy = false
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

    -- UI Styling Function
    local function applyStyle(element, cornerRadius, borderColor)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, cornerRadius)
        corner.Parent = element
        if borderColor then
            local border = Instance.new("UIStroke")
            border.Color = borderColor
            border.Thickness = 1
            border.Parent = element
        end
    end

    local function createStyledDropdown(title, xOffset, yOffset, parent)
        local dropdownFrame = Instance.new("Frame")
        dropdownFrame.Size = UDim2.new(0, 180, 0, 30)
        dropdownFrame.Position = UDim2.new(0, xOffset, 0, yOffset)
        dropdownFrame.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
        dropdownFrame.Parent = parent
        applyStyle(dropdownFrame, 6, Color3.fromRGB(255, 0, 80))

        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(1, 0, 1, 0)
        dropdownBtn.BackgroundTransparency = 1
        dropdownBtn.Text = title .. " ▼"
        dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownBtn.Font = Enum.Font.GothamBold
        dropdownBtn.TextSize = 14
        dropdownBtn.Parent = dropdownFrame

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(0, 180, 0, 0)
        scrollFrame.Position = UDim2.new(0, xOffset + 10, 0, yOffset + 30)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.Visible = false
        scrollFrame.ZIndex = 10
        scrollFrame.ClipsDescendants = true
        scrollFrame.Parent = parent
        applyStyle(scrollFrame, 6, Color3.fromRGB(255, 0, 80))

        local layout = Instance.new("UIListLayout", scrollFrame)
        layout.Padding = UDim.new(0, 2)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        local padding = Instance.new("UIPadding", scrollFrame)
        padding.PaddingBottom = UDim.new(0, 4)

        dropdownBtn.MouseButton1Click:Connect(function()
            scrollFrame.Visible = not scrollFrame.Visible
            if scrollFrame.Visible then
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #fruitNames * 26)
                scrollFrame.Size = UDim2.new(0, 180, 0, math.min(#fruitNames * 26, 150))
            else
                scrollFrame.Size = UDim2.new(0, 180, 0, 0)
            end
        end)

        return dropdownFrame, scrollFrame, dropdownBtn
    end

    -- Main Frame and Panels
    local MainFrame = Instance.new("ScreenGui")
    MainFrame.Parent = CoreGui
    MainFrame.Name = "ServerRejoinerUI"

    local MainPanel = Instance.new("Frame")
    MainPanel.Size = UDim2.new(1, -120, 1, -45)
    MainPanel.Position = UDim2.new(0, 120, 0, 45)
    MainPanel.BackgroundTransparency = 1
    MainPanel.Visible = true
    MainPanel.Parent = MainFrame

    local GearPanel = Instance.new("Frame")
    GearPanel.Size = UDim2.new(1, -120, 1, -45)
    GearPanel.Position = UDim2.new(0, 120, 0, 45)
    GearPanel.BackgroundTransparency = 1
    GearPanel.Visible = false
    GearPanel.Parent = MainFrame

    local OthersPanel = Instance.new("Frame")
    OthersPanel.Size = UDim2.new(1, -120, 1, -45)
    OthersPanel.Position = UDim2.new(0, 120, 0, 45)
    OthersPanel.BackgroundTransparency = 1
    OthersPanel.Visible = false
    OthersPanel.Parent = MainFrame

    local SettingsPanel = Instance.new("Frame")
    SettingsPanel.Size = UDim2.new(1, -120, 1, -45)
    SettingsPanel.Position = UDim2.new(0, 120, 0, 45)
    SettingsPanel.BackgroundTransparency = 1
    SettingsPanel.Visible = false
    SettingsPanel.Parent = MainFrame

    local StandbyText = Instance.new("TextLabel")
    StandbyText.Parent = SettingsPanel
    StandbyText.Size = UDim2.new(1, 0, 1, 0)
    StandbyText.BackgroundTransparency = 1
    StandbyText.Text = "WE ARE WORKING FOR IT PLEASE STANDBY COMING SOON"
    StandbyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StandbyText.TextScaled = true
    StandbyText.Font = Enum.Font.GothamBold
    StandbyText.TextWrapped = true
    StandbyText.AnchorPoint = Vector2.new(0.5, 0.5)
    StandbyText.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- Tab Buttons
    local TabButtonsFrame = Instance.new("Frame")
    TabButtonsFrame.Size = UDim2.new(0, 120, 1, 0)
    TabButtonsFrame.Position = UDim2.new(0, 0, 0, 0)
    TabButtonsFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    TabButtonsFrame.Parent = MainFrame
    applyStyle(TabButtonsFrame, 8, Color3.fromRGB(255, 0, 80))

    local TabLayout = Instance.new("UIListLayout", TabButtonsFrame)
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function selectTab(selectedTab)
        for _, tab in ipairs(TabButtonsFrame:GetChildren()) do
            if tab:IsA("TextButton") then
                tab.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
            end
        end
        selectedTab.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    end

    local Tab1 = Instance.new("TextButton", TabButtonsFrame)
    Tab1.Size = UDim2.new(1, -10, 0, 40)
    Tab1.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    Tab1.Text = "Main"
    Tab1.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab1.Font = Enum.Font.GothamBold
    Tab1.TextSize = 14
    Tab1.Parent = TabButtonsFrame
    applyStyle(Tab1, 8, Color3.fromRGB(255, 0, 80))
    Tab1.MouseButton1Click:Connect(function()
        selectTab(Tab1)
        MainPanel.Visible = true
        GearPanel.Visible = false
        OthersPanel.Visible = false
        SettingsPanel.Visible = false
    end)

    local Tab2 = Instance.new("TextButton", TabButtonsFrame)
    Tab2.Size = UDim2.new(1, -10, 0, 40)
    Tab2.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
    Tab2.Text = "Gear"
    Tab2.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab2.Font = Enum.Font.GothamBold
    Tab2.TextSize = 14
    Tab2.Parent = TabButtonsFrame
    applyStyle(Tab2, 8, Color3.fromRGB(255, 0, 80))
    Tab2.MouseButton1Click:Connect(function()
        selectTab(Tab2)
        MainPanel.Visible = false
        GearPanel.Visible = true
        OthersPanel.Visible = false
        SettingsPanel.Visible = false
    end)

    local Tab3 = Instance.new("TextButton", TabButtonsFrame)
    Tab3.Size = UDim2.new(1, -10, 0, 40)
    Tab3.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
    Tab3.Text = "Others"
    Tab3.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab3.Font = Enum.Font.GothamBold
    Tab3.TextSize = 14
    Tab3.Parent = TabButtonsFrame
    applyStyle(Tab3, 8, Color3.fromRGB(255, 0, 80))
    Tab3.MouseButton1Click:Connect(function()
        selectTab(Tab3)
        MainPanel.Visible = false
        GearPanel.Visible = false
        OthersPanel.Visible = true
        SettingsPanel.Visible = false
    end)

    local Tab4 = Instance.new("TextButton", TabButtonsFrame)
    Tab4.Size = UDim2.new(1, -10, 0, 40)
    Tab4.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
    Tab4.Text = "Settings"
    Tab4.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab4.Font = Enum.Font.GothamBold
    Tab4.TextSize = 14
    Tab4.Parent = TabButtonsFrame
    applyStyle(Tab4, 8, Color3.fromRGB(255, 0, 80))
    Tab4.MouseButton1Click:Connect(function()
        selectTab(Tab4)
        MainPanel.Visible = false
        GearPanel.Visible = false
        OthersPanel.Visible = false
        SettingsPanel.Visible = true
    end)

    -- Main Panel
    local fruitNames = {
        "Carrot", "Strawberry", "Blueberry", "Tomato", "Bamboo", "Cactus", "Pepper", "Cacao", "Blood Banana",
        "Giant Pinecone", "Pumpkin", "Beanstalk", "Watermelon", "Pineapple", "Grape", "Sugar Apple", "Pitcher Plant",
        "Feijoa", "Prickly Pear", "Pear", "Apple", "Dragonfruit", "Coconut", "Mushroom", "Orange Tulip", "Corn",
        "Candy Blossom", "Bone Blossom", "Moon Blossom"
    }
    local fruitDropdown, fruitList = createStyledDropdown("Fruit", 10, 60, MainPanel)
    getgenv().SelectedFruit = nil
    for _, name in ipairs(fruitNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = name
        btn.ZIndex = 11
        btn.Parent = fruitList
        applyStyle(btn, 4, Color3.fromRGB(255, 0, 80))

        btn.MouseButton1Click:Connect(function()
            if getgenv().SelectedFruit == name then
                getgenv().SelectedFruit = nil
                btn.Text = name
                btn.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
                fruitDropdown.TextButton.Text = "Fruit ▼"
            else
                getgenv().SelectedFruit = name
                for _, child in ipairs(fruitList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.Text = child.Text:gsub("✅ ", "")
                        child.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
                    end
                end
                btn.Text = "✅ " .. name
                btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                fruitDropdown.TextButton.Text = "Fruit: " .. name
            end
        end)
    end

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

    local autoBuy = settings.autoBuy
    local autoBuyRunning = false
    local closingHub = false

    local AutoBuyFrame = Instance.new("Frame", MainPanel)
    AutoBuyFrame.Size = UDim2.new(0, 130, 0, 28)
    AutoBuyFrame.Position = UDim2.new(0, 10, 0, 100)
    AutoBuyFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    applyStyle(AutoBuyFrame, 8, Color3.fromRGB(255, 0, 80))

    local AutoBuyLabel = Instance.new("TextLabel", AutoBuyFrame)
    AutoBuyLabel.Size = UDim2.new(0.7, 0, 1, 0)
    AutoBuyLabel.Position = UDim2.new(0.05, 0, 0, 0)
    AutoBuyLabel.BackgroundTransparency = 1
    AutoBuyLabel.Font = Enum.Font.GothamBold
    AutoBuyLabel.TextSize = 14
    AutoBuyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoBuyLabel.TextXAlignment = Enum.TextXAlignment.Left
    AutoBuyLabel.Text = "Auto Buy"

    local AutoBuyToggle = Instance.new("TextButton", AutoBuyFrame)
    AutoBuyToggle.Size = UDim2.new(0, 30, 0, 16)
    AutoBuyToggle.Position = UDim2.new(1, -40, 0.5, -8)
    AutoBuyToggle.BackgroundColor3 = autoBuy and Color3.fromRGB(200, 0, 60) or Color3.fromRGB(60, 0, 0)
    AutoBuyToggle.Text = ""
    AutoBuyToggle.AutoButtonColor = false
    applyStyle(AutoBuyToggle, 8, Color3.fromRGB(80, 0, 0))

    local AutoKnob = Instance.new("Frame", AutoBuyToggle)
    AutoKnob.Size = UDim2.new(0, 14, 0, 14)
    AutoKnob.Position = UDim2.new(0, autoBuy and -15 or 1, 0, 1)
    AutoKnob.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    AutoKnob.Parent = AutoBuyToggle
    applyStyle(AutoKnob, 7, Color3.fromRGB(255, 0, 80))
    local knobGradient = Instance.new("UIGradient", AutoKnob)
    knobGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 60))
    }

    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function updateAutoBuy(state)
        if state then
            TweenService:Create(AutoKnob, tweenInfo, {Position = UDim2.new(1, -15, 0, 1)}):Play()
            AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 60)
        else
            TweenService:Create(AutoKnob, tweenInfo, {Position = UDim2.new(0, 1, 0, 1)}):Play()
            AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
        end
    end

    local function startAutoBuy()
        if autoBuyRunning then return end
        autoBuyRunning = true
        task.spawn(function()
            while autoBuy and not closingHub do
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
            autoBuyRunning = false
        end)
    end

    AutoBuyToggle.MouseButton1Click:Connect(function()
        autoBuy = not autoBuy
        settings.autoBuy = autoBuy
        updateAutoBuy(autoBuy)
        saveSettings(settings)
        if autoBuy then startAutoBuy() end
    end)
    updateAutoBuy(autoBuy)

    -- Gear Panel
    local gearDropdown, gearScroll = createStyledDropdown("Gear Items", 10, 60, GearPanel)
    for _, g in ipairs(gears) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, -10, 0, 24)
        item.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        item.TextColor3 = Color3.fromRGB(255, 255, 255)
        item.Font = Enum.Font.GothamBold
        item.TextSize = 13
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Text = g
        item.ZIndex = 70
        item.Parent = gearScroll
        applyStyle(item, 4, Color3.fromRGB(255, 0, 80))

        item.MouseButton1Click:Connect(function()
            checkedGears[g] = not checkedGears[g]
            item.Text = checkedGears[g] and (g .. " ✓") or g
        end)
    end

    -- Cosmetic Items
    local cosmeticItems = require(ReplicatedStorage.Modules.Chalk)
    local checkedCosmetics = {}
    for name, _ in pairs(cosmeticItems) do
        checkedCosmetics[name] = false
    end

    local cosmeticDropdown, cosmeticScroll = createStyledDropdown("Cosmetic Items", 10, 110, GearPanel)
    for name, data in pairs(cosmeticItems) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, -10, 0, 24)
        item.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        item.TextColor3 = Color3.fromRGB(255, 255, 255)
        item.Font = Enum.Font.GothamBold
        item.TextSize = 13
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Text = name
        item.ZIndex = 70
        item.Parent = cosmeticScroll
        applyStyle(item, 4, Color3.fromRGB(255, 0, 80))

        item.MouseButton1Click:Connect(function()
            checkedCosmetics[name] = not checkedCosmetics[name]
            item.Text = checkedCosmetics[name] and (name .. " ✓") or name
        end)
    end

    local autoCosmeticBuy = settings.autoCosmeticBuy
    local autoCosmeticBuyRunning = false

    local AutoCosmeticBuyFrame = Instance.new("Frame", GearPanel)
    AutoCosmeticBuyFrame.Size = UDim2.new(0, 130, 0, 28)
    AutoCosmeticBuyFrame.Position = UDim2.new(0, 10, 0, 170)
    AutoCosmeticBuyFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    applyStyle(AutoCosmeticBuyFrame, 8, Color3.fromRGB(255, 0, 80))

    local AutoCosmeticBuyLabel = Instance.new("TextLabel", AutoCosmeticBuyFrame)
    AutoCosmeticBuyLabel.Size = UDim2.new(0.7, 0, 1, 0)
    AutoCosmeticBuyLabel.Position = UDim2.new(0.05, 0, 0, 0)
    AutoCosmeticBuyLabel.BackgroundTransparency = 1
    AutoCosmeticBuyLabel.Font = Enum.Font.GothamBold
    AutoCosmeticBuyLabel.TextSize = 14
    AutoCosmeticBuyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoCosmeticBuyLabel.TextXAlignment = Enum.TextXAlignment.Left
    AutoCosmeticBuyLabel.Text = "Auto Cosmetic Buy"

    local AutoCosmeticBuyToggle = Instance.new("TextButton", AutoCosmeticBuyFrame)
    AutoCosmeticBuyToggle.Size = UDim2.new(0, 30, 0, 16)
    AutoCosmeticBuyToggle.Position = UDim2.new(1, -40, 0.5, -8)
    AutoCosmeticBuyToggle.BackgroundColor3 = autoCosmeticBuy and Color3.fromRGB(200, 0, 60) or Color3.fromRGB(60, 0, 0)
    AutoCosmeticBuyToggle.Text = ""
    AutoCosmeticBuyToggle.AutoButtonColor = false
    applyStyle(AutoCosmeticBuyToggle, 8, Color3.fromRGB(80, 0, 0))

    local AutoCosmeticKnob = Instance.new("Frame", AutoCosmeticBuyToggle)
    AutoCosmeticKnob.Size = UDim2.new(0, 14, 0, 14)
    AutoCosmeticKnob.Position = UDim2.new(0, autoCosmeticBuy and -15 or 1, 0, 1)
    AutoCosmeticKnob.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    AutoCosmeticKnob.Parent = AutoCosmeticBuyToggle
    applyStyle(AutoCosmeticKnob, 7, Color3.fromRGB(255, 0, 80))
    local cosmeticKnobGradient = Instance.new("UIGradient", AutoCosmeticKnob)
    cosmeticKnobGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 60))
    }

    local function updateAutoCosmeticBuy(state)
        if state then
            TweenService:Create(AutoCosmeticKnob, tweenInfo, {Position = UDim2.new(1, -15, 0, 1)}):Play()
            AutoCosmeticBuyToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 60)
        else
            TweenService:Create(AutoCosmeticKnob, tweenInfo, {Position = UDim2.new(0, 1, 0, 1)}):Play()
            AutoCosmeticBuyToggle.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
        end
    end

    local function startAutoCosmeticBuy()
        if autoCosmeticBuyRunning then return end
        autoCosmeticBuyRunning = true
        task.spawn(function()
            while autoCosmeticBuy and not closingHub do
                for name, v in pairs(checkedCosmetics) do
                    if v then
                        pcall(function()
                            ReplicatedStorage.GameEvents.BuyCosmetic:FireServer(name, cosmeticItems[name].PurchaseID)
                        end)
                    end
                end
                task.wait(0.5)
            end
            autoCosmeticBuyRunning = false
        end)
    end

    AutoCosmeticBuyToggle.MouseButton1Click:Connect(function()
        autoCosmeticBuy = not autoCosmeticBuy
        settings.autoCosmeticBuy = autoCosmeticBuy
        updateAutoCosmeticBuy(autoCosmeticBuy)
        saveSettings(settings)
        if autoCosmeticBuy then startAutoCosmeticBuy() end
    end)
    updateAutoCosmeticBuy(autoCosmeticBuy)

    -- Others Panel
    local autoShovelState = settings.autoShovel

    local ShovelFrame = Instance.new("Frame", OthersPanel)
    ShovelFrame.Size = UDim2.new(0, 200, 0, 32)
    ShovelFrame.Position = UDim2.new(0, 8, 0, 130)
    ShovelFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    applyStyle(ShovelFrame, 8, Color3.fromRGB(255, 0, 80))

    local ShovelLabel = Instance.new("TextLabel", ShovelFrame)
    ShovelLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ShovelLabel.Position = UDim2.new(0.05, 0, 0, 0)
    ShovelLabel.BackgroundTransparency = 1
    ShovelLabel.Font = Enum.Font.GothamBold
    ShovelLabel.TextSize = 14
    ShovelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ShovelLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShovelLabel.Text = "Auto Shovel"

    local ShovelToggle = Instance.new("TextButton", ShovelFrame)
    ShovelToggle.Size = UDim2.new(0, 30, 0, 16)
    ShovelToggle.Position = UDim2.new(1, -40, 0.5, -8)
    ShovelToggle.BackgroundColor3 = autoShovelState and Color3.fromRGB(200, 0, 60) or Color3.fromRGB(60, 0, 0)
    ShovelToggle.Text = ""
    ShovelToggle.AutoButtonColor = false
    applyStyle(ShovelToggle, 8, Color3.fromRGB(80, 0, 0))

    local ShovelKnob = Instance.new("Frame", ShovelToggle)
    ShovelKnob.Size = UDim2.new(0, 14, 0, 14)
    ShovelKnob.Position = UDim2.new(0, autoShovelState and -15 or 1, 0, 1)
    ShovelKnob.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    applyStyle(ShovelKnob, 7, Color3.fromRGB(255, 0, 80))

    local shovelGradient = Instance.new("UIGradient", ShovelKnob)
    shovelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 60))
    }

    local function updateShovelToggle(state)
        local targetPos = state and UDim2.new(1, -15, 0, 1) or UDim2.new(0, 1, 0, 1)
        ShovelToggle.BackgroundColor3 = state and Color3.fromRGB(200, 0, 60) or Color3.fromRGB(60, 0, 0)
        TweenService:Create(ShovelKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end

    local function holdShovel()
        local plr = game.Players.LocalPlayer
        if not plr.Character then return end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local current = plr.Character:FindFirstChildOfClass("Tool")
        if current and current.Name:lower():find("shovel") then return end
        local backpack = plr:FindFirstChildOfClass("Backpack")
        if not backpack then return end
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("shovel") then
                hum:EquipTool(tool)
                print("✅ Equipped shovel:", tool.Name)
                return
            end
        end
        print("⚠️ No shovel found in backpack!")
    end

    ShovelToggle.MouseButton1Click:Connect(function()
        autoShovelState = not autoShovelState
        settings.autoShovel = autoShovelState
        updateShovelToggle(autoShovelState)
        saveSettings(settings)
        print("🛠️ Auto Shovel toggled:", autoShovelState)
    end)
    updateShovelToggle(autoShovelState)

    task.spawn(function()
        while task.wait(0.3) do
            if autoShovelState then
                holdShovel()
                local DeleteObject = ReplicatedStorage.GameEvents:FindFirstChild("DeleteObject")
                local SprinklerFolder = workspace.Farm.Farm.Important:WaitForChild("Objects_Physical", 5)
                if DeleteObject and SprinklerFolder then
                    for _, model in ipairs(SprinklerFolder:GetChildren()) do
                        if model:IsA("Model") then
                            for name, _ in pairs(selectedSprinklers) do
                                if selectedSprinklers[name] and string.find(model.Name, name) then
                                    DeleteObject:FireServer(model)
                                    print("🛠 Shoveling:", model.Name)
                                    task.wait(0.15)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local sprinklerDropdownFrame, sprinklerScroll = createStyledDropdown("Sprinkler List", 10, 90, OthersPanel)
    sprinklerScroll.ScrollingEnabled = true
    sprinklerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sprinklerScroll.ScrollBarThickness = 6
    sprinklerScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 60)

    local sprinklerNames = {
        "Basic Sprinkler",
        "Advanced Sprinkler",
        "Godly Sprinkler",
        "Master Sprinkler",
        "Honey Sprinkler",
        "Chocolate Sprinkler"
    }
    local selectedSprinklers = {}

    local function isSelected(name)
        return selectedSprinklers[name] == true
    end

    local function toggleSprinkler(name, btn)
        if isSelected(name) then
            selectedSprinklers[name] = nil
            btn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        else
            selectedSprinklers[name] = true
            btn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
        end
    end

    for _, sName in ipairs(sprinklerNames) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 24)
        b.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.ZIndex = 60
        b.Text = "   " .. sName
        b.Parent = sprinklerScroll
        applyStyle(b, 4, Color3.fromRGB(255, 0, 80))

        b.MouseButton1Click:Connect(function()
            toggleSprinkler(sName, b)
        end)
    end

    -- Pet System
    getgenv().PetIdle = settings.autoMid
    local TargetPosition = Vector3.new(0, 0, 0)
    local SelectedPets = {}

    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local RS = game:GetService("ReplicatedStorage")
    local remote = RS.GameEvents:WaitForChild("ActivePetService", 5)
    local PetUI = lp:WaitForChild("PlayerGui", 5):WaitForChild("ActivePetUI", 5)

    local function getAllPetInfo()
        local pets = {}
        if PetUI and PetUI:FindFirstChild("Frame") and PetUI.Frame.Main:FindFirstChild("ScrollingFrame") then
            for _, frame in ipairs(PetUI.Frame.Main.ScrollingFrame:GetChildren()) do
                if frame:IsA("Frame") and frame.Name ~= "PetTemplate" and frame:FindFirstChild("PET_TYPE") then
                    local uuid = frame.Name
                    local name = frame.PET_TYPE.Text or uuid
                    table.insert(pets, {uuid = uuid, name = name})
                end
            end
        end
        return pets
    end

    local function waitUntilPetNear(uuid, pos, maxTime)
        local elapsed = 0
        while elapsed < maxTime do
            task.wait(0.05)
            elapsed = elapsed + 0.05
            local petModel = workspace:FindFirstChild(uuid)
            if petModel and petModel:FindFirstChild("HumanoidRootPart") then
                local petPos = petModel.HumanoidRootPart.Position
                if (petPos - pos).Magnitude < 3 then
                    return true
                end
            end
        end
        return false
    end

    local function gatherPetsOnce()
        if #SelectedPets == 0 then return end
        for _, uuid in ipairs(SelectedPets) do
            task.spawn(function()
                for n = 1, 6 do
                    if remote then
                        remote:FireServer("MovePetTo", uuid, TargetPosition)
                    end
                end
                waitUntilPetNear(uuid, TargetPosition, 2)
                if remote then
                    remote:FireServer("SetPetState", uuid, "Idle")
                end
            end)
        end
    end

    local currentLoopThread = nil
    local function startAutoMid()
        if currentLoopThread then
            task.cancel(currentLoopThread)
            currentLoopThread = nil
        end
        currentLoopThread = task.spawn(function()
            gatherPetsOnce()
            while getgenv().PetIdle do
                task.wait(0.1)
                gatherPetsOnce()
            end
        end)
    end

    local function rebuildPetList()
        for _, c in ipairs(petsScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        SelectedPets = {}
        local allPets = getAllPetInfo()
        for _, pet in ipairs(allPets) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "◻️ " .. pet.name
            btn.ZIndex = 80
            btn.Parent = petsScroll
            applyStyle(btn, 4, Color3.fromRGB(255, 0, 80))

            local selected = false
            btn.MouseButton1Click:Connect(function()
                selected = not selected
                if selected then
                    table.insert(SelectedPets, pet.uuid)
                    btn.Text = "✅ " .. pet.name
                    btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                else
                    for i, v in ipairs(SelectedPets) do
                        if v == pet.uuid then table.remove(SelectedPets, i) break end
                    end
                    btn.Text = "◻️ " .. pet.name
                    btn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
                end
            end)
        end
    end

    local RefreshBtn = Instance.new("TextButton", OthersPanel)
    RefreshBtn.Size = UDim2.new(0, 100, 0, 30)
    RefreshBtn.Position = UDim2.new(1, -120, 0, 35)
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
    RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshBtn.Font = Enum.Font.GothamBold
    RefreshBtn.Text = "⟳ Refresh"
    applyStyle(RefreshBtn, 8, Color3.fromRGB(255, 0, 80))
    RefreshBtn.MouseButton1Click:Connect(function()
        rebuildPetList()
    end)

    local autoMid = settings.autoMid
    local AutoMidFrame = Instance.new("Frame", OthersPanel)
    AutoMidFrame.Size = UDim2.new(0, 130, 0, 28)
    AutoMidFrame.Position = UDim2.new(0, 8, 0, 35)
    AutoMidFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    applyStyle(AutoMidFrame, 8, Color3.fromRGB(255, 0, 80))

    local AutoMidLabel = Instance.new("TextLabel", AutoMidFrame)
    AutoMidLabel.Size = UDim2.new(0.7, 0, 1, 0)
    AutoMidLabel.Position = UDim2.new(0.05, 0, 0, 0)
    AutoMidLabel.BackgroundTransparency = 1
    AutoMidLabel.Font = Enum.Font.GothamBold
    AutoMidLabel.TextSize = 14
    AutoMidLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoMidLabel.TextXAlignment = Enum.TextXAlignment.Left
    AutoMidLabel.Text = "Auto Mid"

    local AutoMidToggle = Instance.new("TextButton", AutoMidFrame)
    AutoMidToggle.Size = UDim2.new(0, 30, 0, 16)
    AutoMidToggle.Position = UDim2.new(1, -40, 0.5, -8)
    AutoMidToggle.BackgroundColor3 = autoMid and Color3.fromRGB(200, 0, 60) or Color3.fromRGB(60, 0, 0)
    AutoMidToggle.Text = ""
    AutoMidToggle.AutoButtonColor = false
    applyStyle(AutoMidToggle, 8, Color3.fromRGB(80, 0, 0))

    local AutoMidKnob = Instance.new("Frame", AutoMidToggle)
    AutoMidKnob.Size = UDim2.new(0, 14, 0, 14)
    AutoMidKnob.Position = UDim2.new(0, autoMid and -15 or 1, 0, 1)
    AutoMidKnob.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    applyStyle(AutoMidKnob, 7, Color3.fromRGB(255, 0, 80))
    local knobMidGradient = Instance.new("UIGradient", AutoMidKnob)
    knobMidGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 60))
    }

    local function updateAutoMid(state)
        if state then
            TweenService:Create(AutoMidKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -15, 0, 1)}):Play()
            AutoMidToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 60)
        else
            TweenService:Create(AutoMidKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 1, 0, 1)}):Play()
            AutoMidToggle.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
        end
    end

    AutoMidToggle.MouseButton1Click:Connect(function()
        autoMid = not autoMid
        getgenv().PetIdle = autoMid
        settings.autoMid = autoMid
        saveSettings(settings)
        updateAutoMid(autoMid)
        if autoMid then
            startAutoMid()
        else
            if currentLoopThread then
                task.cancel(currentLoopThread)
                currentLoopThread = nil
            end
        end
    end)
    updateAutoMid(autoMid)
    rebuildPetList()

    -- Farming Tab (Integrated into Others for now)
    local autoCollect = settings.autoCollect
    getgenv().AutoCollect = autoCollect
    getgenv().SelectedMutations = getgenv().SelectedMutations or {}

    local AutoCollectFrame = Instance.new("Frame", OthersPanel)
    AutoCollectFrame.Size = UDim2.new(0, 180, 0, 30)
    AutoCollectFrame.Position = UDim2.new(0, 10, 0, 70)
    AutoCollectFrame.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
    applyStyle(AutoCollectFrame, 6, Color3.fromRGB(255, 0, 80))

    local AutoCollectLabel = Instance.new("TextLabel", AutoCollectFrame)
    AutoCollectLabel.Size = UDim2.new(0.6, 0, 1, 0)
    AutoCollectLabel.BackgroundTransparency = 1
    AutoCollectLabel.Text = "Auto Collect"
    AutoCollectLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoCollectLabel.Font = Enum.Font.GothamBold
    AutoCollectLabel.TextSize = 14
    AutoCollectLabel.Parent = AutoCollectFrame

    local ToggleBG = Instance.new("Frame", AutoCollectFrame)
    ToggleBG.AnchorPoint = Vector2.new(1, 0.5)
    ToggleBG.Position = UDim2.new(1, -8, 0.5, 0)
    ToggleBG.Size = UDim2.new(0, 50, 0, 20)
    ToggleBG.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
    ToggleBG.ClipsDescendants = true
    applyStyle(ToggleBG, 1, nil)

    local Knob = Instance.new("Frame", ToggleBG)
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, autoCollect and -19 or 1, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    applyStyle(Knob, 1, nil)

    local ToggleButton = Instance.new("TextButton", AutoCollectFrame)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.Size = UDim2.new(1, 0, 1, 0)
    ToggleButton.Text = ""
    ToggleButton.Parent = AutoCollectFrame

    ToggleButton.MouseButton1Click:Connect(function()
        autoCollect = not autoCollect
        getgenv().AutoCollect = autoCollect
        settings.autoCollect = autoCollect
        saveSettings(settings)
        if autoCollect then
            ToggleBG.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -19, 0.5, -9)}):Play()
        else
            ToggleBG.BackgroundColor3 = Color3.fromRGB(90, 0, 0)
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 1, 0.5, -9)}):Play()
        end
    end)

    task.spawn(function()
        while wait(0.3) do
            if getgenv().AutoCollect and getgenv().SelectedFruit then
                local collectList = {}
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and CollectionService:HasTag(prompt, "CollectPrompt") then
                        local model = prompt.Parent and prompt.Parent.Parent
                        if model and string.find(string.lower(model.Name), string.lower(getgenv().SelectedFruit)) then
                            if #getgenv().SelectedMutations == 0 then
                                table.insert(collectList, model)
                            else
                                local mName = string.lower(model.Name)
                                for _, mut in ipairs(getgenv().SelectedMutations) do
                                    if string.find(mName, string.lower(mut)) then
                                        table.insert(collectList, model)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                if #collectList > 0 then
                    pcall(function()
                        Remotes.Crops.Collect:FireServer(collectList)
                    end)
                end
            end
        end
    end)

    -- Shop Tab (Integrated into Gear for now)
    local u7S = require(ReplicatedStorage.Top_Text)
    local u11S = require(ReplicatedStorage.NPC_MOD)
    local u12S = require(ReplicatedStorage.Modules.GuiController)

    local gearActive = settings.autoGearShop
    local cosmeticActive = settings.autoCosmeticShop
    local seedActive = settings.autoSeedShop

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
            MainFrame.Visible = uiEnabled
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
    MainFrame.Visible = uiEnabled

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
        if MainFrame then
            MainFrame.Visible = uiEnabled
        end
        ToggleIconButton.BackgroundColor3 = uiEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        saveSettings({uiEnabled = uiEnabled})
    end)
end
