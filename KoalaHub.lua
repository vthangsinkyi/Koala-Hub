-- 👑 KOALA HUB 👑 (Adapted to Fluent UI, Mobile Optimized)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Fluent Window (Mobile-friendly size)
local Window = Fluent:CreateWindow({
    Title = "KoalaHub",
    SubTitle = "by Koala Team",
    TabWidth = 120, -- Reduced for mobile
    Size = UDim2.fromOffset(400, 360), -- Smaller size for cellphone screens
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Define Tabs with Lucide Icons
local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Main = Window:AddTab({ Title = "Main", Icon = "gamepad" }),
    Pets = Window:AddTab({ Title = "Pets", Icon = "dog" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Others = Window:AddTab({ Title = "Others", Icon = "eye" })
}

local Options = Fluent.Options

-- Notify on load
Fluent:Notify({
    Title = "KoalaHub",
    Content = "The script has been loaded.",
    Duration = 8
})

-- ✨ Inline emoji table (for consistency)
local TabIcons = {
    Home = "🏠",
    Main = "💀",
    Pets = "🐶",
    Settings = "⚙️",
    Others = "👀",
}

-- 📌 SERVICES & REMOTES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes"))
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local PetUI = lp:WaitForChild("PlayerGui"):WaitForChild("ActivePetUI")
local DeleteObject = RS.GameEvents:WaitForChild("DeleteObject")
local SprinklerFolder = workspace.Farm.Farm.Important:WaitForChild("Objects_Physical")

-----------------------------------------------------
-- 🏠 HOME TAB
-----------------------------------------------------
Tabs.Home:AddParagraph({
    Title = "Welcome to KoalaHub",
    Content = "We sincerely appreciate your support. If you encounter any issues or have suggestions, please join our Discord server: https://discord.gg/gkgawceq"
})

Tabs.Home:AddParagraph({
    Title = "Team",
    Content = [[
Owner: koala
Co-Owner: Ard
Developers: Day
Helper: Day
Tester: Saz, Dio
    ]]
})

-----------------------------------------------------
-- 📌 MAIN TAB
-----------------------------------------------------
getgenv().SelectedMutations = {}
getgenv().SelectedFruit = nil
getgenv().AutoCollect = false
getgenv().AutoBuy = false

-- UI Toggle Button
local UIToggle = Tabs.Main:AddToggle("UIToggle", {
    Title = "Toggle UI",
    Description = "Show or hide the KoalaHub UI.",
    Default = true
})

UIToggle:OnChanged(function()
    Window:SetVisible(Options.UIToggle.Value)
    print("UI Visible:", Options.UIToggle.Value)
end)

local mutationNames = {
    "Gold", "Shiny", "Fried", "Pollinated", "Wet", "Rainbow", "Moonlit", "Chocolate", "Windstruck",
    "Frozen", "Radiant", "Tranquil", "Corrupt", "Inverted", "Windy", "Chilled", "Shocked", "Disco"
}

local MutationDropdown = Tabs.Main:AddDropdown("MutationDropdown", {
    Title = "Mutation Selector",
    Description = "Select multiple mutations to filter crops.",
    Values = mutationNames,
    Multi = true,
    Default = {}
})

MutationDropdown:OnChanged(function(Value)
    getgenv().SelectedMutations = {}
    for mutation, state in pairs(Value) do
        if state then
            table.insert(getgenv().SelectedMutations, mutation)
        end
    end
    print("Selected Mutations:", table.concat(getgenv().SelectedMutations, ", "))
end)

local fruitNames = {
    "Carrot", "Strawberry", "Blueberry", "Tomato", "Bamboo", "Cactus", "Pepper", "Cacao", "Blood Banana",
    "Giant Pinecone", "Pumpkin", "Beanstalk", "Watermelon", "Pineapple", "Grape", "Sugar Apple", "Pitcher Plant",
    "Feijoa", "Prickly Pear", "Pear", "Apple", "Dragonfruit", "Coconut", "Mushroom", "Orange Tulip", "Corn",
    "Candy Blossom", "Bone Blossom", "Moon Blossom"
}

local FruitDropdown = Tabs.Main:AddDropdown("FruitDropdown", {
    Title = "Fruit Selector",
    Description = "Select a fruit to collect.",
    Values = fruitNames,
    Multi = false,
    Default = nil
})

FruitDropdown:OnChanged(function(Value)
    getgenv().SelectedFruit = Value
    print("Selected Fruit:", Value or "None")
end)

local AutoCollectToggle = Tabs.Main:AddToggle("AutoCollect", {
    Title = "Auto Collect",
    Description = "Automatically collect selected fruits with chosen mutations.",
    Default = false
})

AutoCollectToggle:OnChanged(function()
    getgenv().AutoCollect = Options.AutoCollect.Value
    print("Auto Collect:", getgenv().AutoCollect)
end)

-- Auto Collect Loop
task.spawn(function()
    while task.wait(0.3) do
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
                    Remotes.Crops.Collect.send(collectList)
                end)
            end
        end
    end
end)

-- Auto Buy Toggle
local checkedGears, checkedSeeds = {}, {}
local AutoBuyToggle = Tabs.Main:AddToggle("AutoBuy", {
    Title = "Auto Buy",
    Description = "Automatically buy selected gears and seeds.",
    Default = false
})

AutoBuyToggle:OnChanged(function()
    getgenv().AutoBuy = Options.AutoBuy.Value
    if getgenv().AutoBuy then
        task.spawn(function()
            while getgenv().AutoBuy do
                for g, v in pairs(checkedGears) do
                    if v then
                        pcall(function()
                            game.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(g)
                        end)
                    end
                end
                for s, v in pairs(checkedSeeds) do
                    if v then
                        pcall(function()
                            game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(s)
                        end)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    print("Auto Buy:", getgenv().AutoBuy)
end)

-- Gear Shop Dropdown
local gears = {
    "Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advance Sprinkler",
    "Medium Toy", "Godly Sprinkler", "Magnifying Glass", "Tanning Mirror",
    "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot", "Levelup Lollipop"
}

local GearDropdown = Tabs.Main:AddDropdown("GearDropdown", {
    Title = "Gear Shop",
    Description = "Select gears to auto buy.",
    Values = gears,
    Multi = true,
    Default = {}
})

GearDropdown:OnChanged(function(Value)
    checkedGears = Value
    local selected = {}
    for gear, state in pairs(Value) do
        if state then
            table.insert(selected, gear)
        end
    end
    print("Selected Gears:", table.concat(selected, ", "))
end)

-- Seed Shop Dropdown
local seeds = {
    "Carrot", "Strawberry", "Blueberry", "Tomato", "Bamboo", "Cactus", "Pepper", "Cacao", "Blood Banana",
    "Giant Pinecone", "Pumpkin", "Beanstalk", "Watermelon", "Pineapple", "Grape", "Sugar Apple",
    "Pitcher Plant", "Feijoa", "Prickly Pear", "Pear", "Apple", "Dragonfruit", "Coconut",
    "Mushroom", "Orange Tulip", "Corn"
}

local SeedDropdown = Tabs.Main:AddDropdown("SeedDropdown", {
    Title = "Seed Shop",
    Description = "Select seeds to auto buy.",
    Values = seeds,
    Multi = true,
    Default = {}
})

SeedDropdown:OnChanged(function(Value)
    checkedSeeds = Value
    local selected = {}
    for seed, state in pairs(Value) do
        if state then
            table.insert(selected, seed)
        end
    end
    print("Selected Seeds:", table.concat(selected, ", "))
end)

-----------------------------------------------------
-- 🐶 PETS TAB
-----------------------------------------------------
getgenv().PetIdle = false
local SelectedPets = {}

local function getAllPetInfo()
    local pets = {}
    for _, frame in ipairs(PetUI.Frame.Main.ScrollingFrame:GetChildren()) do
        if frame:IsA("Frame") and frame.Name ~= "PetTemplate" and frame:FindFirstChild("PET_TYPE") then
            local uuid = frame.Name
            local name = frame.PET_TYPE.Text or uuid
            table.insert(pets, {uuid = uuid, name = name})
        end
    end
    return pets
end

local PetDropdown = Tabs.Pets:AddDropdown("PetDropdown", {
    Title = "Pet Selector",
    Description = "Select pets to control.",
    Values = {},
    Multi = true,
    Default = {}
})

local function rebuildPetList()
    local allPets = getAllPetInfo()
    local petNames = {}
    for _, pet in ipairs(allPets) do
        table.insert(petNames, pet.name)
    end
    PetDropdown:SetValues(petNames)
    SelectedPets = {}
    PetDropdown:SetValue({})
end

PetDropdown:OnChanged(function(Value)
    SelectedPets = {}
    local allPets = getAllPetInfo()
    for name, state in pairs(Value) do
        if state then
            for _, pet in ipairs(allPets) do
                if pet.name == name then
                    table.insert(SelectedPets, pet.uuid)
                end
            end
        end
    end
    print("Selected Pets:", table.concat(SelectedPets, ", "))
end)

local RefreshButton = Tabs.Pets:AddButton({
    Title = "Refresh Pets",
    Description = "Refresh the pet list.",
    Callback = function()
        rebuildPetList()
        Fluent:Notify({
            Title = "KoalaHub",
            Content = "Pet list refreshed.",
            Duration = 3
        })
    end
})

local AutoMidToggle = Tabs.Pets:AddToggle("AutoMid", {
    Title = "Auto Mid",
    Description = "Automatically gather pets to mid.",
    Default = false
})

local TargetPosition = Vector3.new(0, 0, 0)
local remote = RS.GameEvents:WaitForChild("ActivePetService")

local function waitUntilPetNear(uuid, pos, maxTime)
    local elapsed = 0
    while elapsed < maxTime do
        task.wait(0.05)
        elapsed += 0.05
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
                remote:FireServer("MovePetTo", uuid, TargetPosition)
            end
            waitUntilPetNear(uuid, TargetPosition, 2)
            remote:FireServer("SetPetState", uuid, "Idle")
        end)
    end
end

local currentLoopThread = nil
AutoMidToggle:OnChanged(function()
    getgenv().PetIdle = Options.AutoMid.Value
    if getgenv().PetIdle then
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
    else
        if currentLoopThread then
            task.cancel(currentLoopThread)
            currentLoopThread = nil
        end
    end
    print("Auto Mid:", getgenv().PetIdle)
end)

rebuildPetList()

-----------------------------------------------------
-- ⚙️ SETTINGS TAB
-----------------------------------------------------
Tabs.Settings:AddParagraph({
    Title = "Settings",
    Content = "Settings are coming soon. Please standby."
})

-- Add SaveManager and InterfaceManager to Settings Tab
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("KoalaHub")
SaveManager:SetFolder("KoalaHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-----------------------------------------------------
-- 👀 OTHERS TAB
-----------------------------------------------------
local weatherAttributes = {
    "Blackhole",
    "AuroraBorealis"
}
for _, attr in ipairs(weatherAttributes) do
    if workspace:GetAttribute(attr) == nil then
        workspace:SetAttribute(attr, false)
    end
end

local currentWeather = nil
local visualState = false

local function enableWeather(name)
    for _, attr in ipairs(weatherAttributes) do workspace:SetAttribute(attr, false) end
    workspace:SetAttribute(name, true)
    print("✅ Weather enabled:", name)
end

local function disableWeather()
    for _, attr in ipairs(weatherAttributes) do workspace:SetAttribute(attr, false) end
    workspace.Gravity = 196.2
    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower, hum.WalkSpeed = 50, 16 end
    print("⛔ Weather disabled.")
end

local WeatherDropdown = Tabs.Others:AddDropdown("WeatherDropdown", {
    Title = "Weather Selector",
    Description = "Select a weather effect.",
    Values = weatherAttributes,
    Multi = false,
    Default = nil
})

WeatherDropdown:OnChanged(function(Value)
    currentWeather = Value
    if visualState and currentWeather then
        enableWeather(currentWeather)
    elseif not visualState then
        disableWeather()
    end
    print("Weather selected:", Value or "None")
end)

local VisualToggle = Tabs.Others:AddToggle("VisualToggle", {
    Title = "Visual Effects",
    Description = "Enable or disable weather visual effects.",
    Default = false
})

VisualToggle:OnChanged(function()
    visualState = Options.VisualToggle.Value
    if visualState and currentWeather then
        enableWeather(currentWeather)
    else
        disableWeather()
    end
    print("Visual Effects:", visualState)
end)

local sprinklerNames = {
    "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Master Sprinkler",
    "Honey Sprinkler", "Chocolate Sprinkler"
}
local selectedSprinklers = {}

local SprinklerDropdown = Tabs.Others:AddDropdown("SprinklerDropdown", {
    Title = "Sprinkler Selector",
    Description = "Select sprinklers for auto shovel.",
    Values = sprinklerNames,
    Multi = true,
    Default = {}
})

SprinklerDropdown:OnChanged(function(Value)
    selectedSprinklers = Value
    local selected = {}
    for sprinkler, state in pairs(Value) do
        if state then
            table.insert(selected, sprinkler)
        end
    end
    print("Selected Sprinklers:", table.concat(selected, ", "))
end)

local AutoShovelToggle = Tabs.Others:AddToggle("AutoShovel", {
    Title = "Auto Shovel",
    Description = "Automatically shovel selected sprinklers.",
    Default = false
})

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

AutoShovelToggle:OnChanged(function()
    local autoShovelState = Options.AutoShovel.Value
    print("🛠️ Auto Shovel toggled:", autoShovelState)
end)

-- Auto Shovel Loop
task.spawn(function()
    while task.wait(0.3) do
        if Options.AutoShovel.Value then
            holdShovel()
            for _, model in ipairs(SprinklerFolder:GetChildren()) do
                if model:IsA("Model") then
                    for name, state in pairs(selectedSprinklers) do
                        if state and string.find(model.Name, name) then
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
end)

-----------------------------------------------------
-- FINAL SETUP
-----------------------------------------------------
Window:SelectTab(1) -- Select Home tab by default
SaveManager:LoadAutoloadConfig()