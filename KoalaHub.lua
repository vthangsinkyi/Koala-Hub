-- 👑 KOALA HUB 👑 (Grey Theme)
local safeParent = (gethui and gethui()) or game.Players.LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ✨ Inline emoji table (no ModuleScript)
local TabIcons = {
    Home = "🏠",
    Main = "💀",
    Pets = "🐶",
    Settings = "⚙️",
    Others = "👀",
}

-- 🫧 Bubble helper for rounded corners and borders
local function makeBubble(uiObject, radius, strokeColor)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = uiObject
	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor or Color3.fromRGB(120,120,120) -- Light grey stroke
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = uiObject
end

-----------------------------------------------------
-- 🔘 FLOATING ICON
-----------------------------------------------------
local FloatGui = Instance.new("ScreenGui")
FloatGui.Name = "KoalaFloatingIcon"
FloatGui.ResetOnSpawn = false
FloatGui.IgnoreGuiInset = true
FloatGui.Parent = safeParent

local IconButton = Instance.new("TextButton")
IconButton.Parent = FloatGui
IconButton.BackgroundColor3 = Color3.fromRGB(40,40,40) -- Dark grey
IconButton.Position = UDim2.new(0.02,0,0.4,0)
IconButton.Size = UDim2.new(0,26,0,26)
IconButton.Text = "K"
IconButton.TextScaled = true
IconButton.Font = Enum.Font.GothamBlack
IconButton.TextColor3 = Color3.fromRGB(200,200,200) -- Light grey text
makeBubble(IconButton,18,Color3.fromRGB(120,120,120))

local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(70,70,70)), -- Medium grey
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40,40,40)) -- Dark grey
}
iconGradient.Rotation = 45
iconGradient.Parent = IconButton

-- Dragging for floating icon
local dragging, dragInput, dragStart, startPos
IconButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = IconButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
IconButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		IconButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-----------------------------------------------------
-- 👑 MAIN GUI
-----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KoalaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = safeParent

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 520, 0, 300)
MainFrame.Position = UDim2.new(0.32, 0, 0.3, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BackgroundColor3 = Color3.fromRGB(40,40,40) -- Dark grey
makeBubble(MainFrame, 14, Color3.fromRGB(120,120,120))

local uiScale = Instance.new("UIScale")
uiScale.Scale = 0.7
uiScale.Parent = MainFrame

local gradient = Instance.new("UIGradient", MainFrame)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70,70,70)), -- Medium grey
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40,40,40)) -- Dark grey
}
gradient.Rotation = 90
MainFrame.BackgroundTransparency = 0.3

-----------------------------------------------------
-- 🏠 HOME PANEL
-----------------------------------------------------
local HomePanel = Instance.new("Frame")
HomePanel.Name = "HomePanel"
HomePanel.Size = UDim2.new(1, -120, 1, -45)
HomePanel.Position = UDim2.new(0, 120, 0, 45)
HomePanel.BackgroundTransparency = 1
HomePanel.Visible = true
HomePanel.ClipsDescendants = true
HomePanel.Parent = MainFrame

-----------------------------------------------------
-- 🏠 HOME PANEL TEXT (formal, proper caps, white)
-----------------------------------------------------
local WelcomeText = Instance.new("TextLabel")
WelcomeText.Parent = HomePanel
WelcomeText.Size = UDim2.new(1, -20, 0, 80)
WelcomeText.Position = UDim2.new(0, 10, 0, 10)
WelcomeText.BackgroundTransparency = 1
WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
WelcomeText.TextSize = 14
WelcomeText.Font = Enum.Font.Gotham
WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
WelcomeText.TextYAlignment = Enum.TextYAlignment.Top
WelcomeText.TextWrapped = true
WelcomeText.Text = [[Welcome to KoalaHub.

We sincerely appreciate your support. If you encounter any issues or have suggestions, please do not hesitate to share them through our Discord server.]]

-----------------------------------------------------
-- function to create each role row (title grey, name white bold)
-----------------------------------------------------
local function createRoleLabel(titleText, nameText, posY)
    local holder = Instance.new("Frame")
    holder.Parent = HomePanel
    holder.Size = UDim2.new(1, -20, 0, 18)
    holder.Position = UDim2.new(0, 10, 0, posY)
    holder.BackgroundTransparency = 1

    -- 🔻 Title (Medium grey)
    local title = Instance.new("TextLabel")
    title.Parent = holder
    title.Size = UDim2.new(0, 100, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = string.upper(titleText) .. ":"
    title.TextColor3 = Color3.fromRGB(120,120,120) -- Light grey
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- 🔻 Name (White and bold)
    local name = Instance.new("TextLabel")
    name.Parent = holder
    name.Size = UDim2.new(1, -110, 1, 0)
    name.Position = UDim2.new(0, 110, 0, 0)
    name.BackgroundTransparency = 1
    name.Text = nameText
    name.TextColor3 = Color3.fromRGB(255,255,255) -- White
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
end

-----------------------------------------------------
-- add the list
-----------------------------------------------------
local startY = 95
local gap = 20
createRoleLabel("owner", "BINZZ", startY)
createRoleLabel("co owner", "KENSHIN", startY + gap)
createRoleLabel("dev", "KASH AND KIEL", startY + gap*2)
createRoleLabel("contributor", "RNZ", startY + gap*3) -- Fixed typo from "youre so gay"
createRoleLabel("helper", "FLAZHY", startY + gap*4)
createRoleLabel("tester", "MIWA", startY + gap*5)

-----------------------------------------------------
-- discord text
-----------------------------------------------------
local DiscordText = Instance.new("TextLabel")
DiscordText.Parent = HomePanel
DiscordText.AnchorPoint = Vector2.new(0.5, 1)
DiscordText.Position = UDim2.new(0.5, 0, 1, -10)
DiscordText.Size = UDim2.new(1, -20, 0, 18)
DiscordText.BackgroundTransparency = 1
DiscordText.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordText.Font = Enum.Font.GothamBold
DiscordText.TextSize = 13
DiscordText.Text = "discord server: https://discord.gg/gkgawceq"
DiscordText.TextWrapped = true
DiscordText.TextXAlignment = Enum.TextXAlignment.Center

-----------------------------------------------------
-- 📌 MAIN PANEL
-----------------------------------------------------
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(1, -120, 1, -45)
MainPanel.Position = UDim2.new(0, 120, 0, 45)
MainPanel.BackgroundTransparency = 1
MainPanel.Visible = false
MainPanel.ClipsDescendants = true
MainPanel.Parent = MainFrame

-- 🌟 INIT GLOBALS
getgenv().SelectedMutations = {}
getgenv().SelectedFruit = nil
getgenv().AutoCollect = false

-- 📌 SERVICES & REMOTES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes"))
local CollectionService = game:GetService("CollectionService")

-----------------------------------------------------
-- 🧬 MUTATION DROPDOWN
-----------------------------------------------------
local mutationNames = {
    "Gold","Shiny","Fried","Pollinated","Wet","Rainbow","Moonlit","Chocolate","Windstruck",
    "Frozen","Radiant","Tranquil","Corrupt","Inverted","Windy","Chilled","Shocked","Disco"
}

local MutationDropdown = Instance.new("Frame")
MutationDropdown.Size = UDim2.new(0,180,0,30)
MutationDropdown.Position = UDim2.new(0,10,0,120)
MutationDropdown.BackgroundColor3 = Color3.fromRGB(40,40,40) -- Dark grey
MutationDropdown.ClipsDescendants = true
MutationDropdown.Parent = MainPanel
makeBubble(MutationDropdown,6,Color3.fromRGB(120,120,120))

local MutationBtn = Instance.new("TextButton")
MutationBtn.Size = UDim2.new(1,0,1,0)
MutationBtn.BackgroundTransparency = 1
MutationBtn.Text = "MUTATION ▼"
MutationBtn.TextColor3 = Color3.fromRGB(255,255,255)
MutationBtn.Font = Enum.Font.GothamBold
MutationBtn.TextSize = 14
MutationBtn.Parent = MutationDropdown

local MutationList = Instance.new("ScrollingFrame")
MutationList.Size = UDim2.new(0,180,0,0)
MutationList.Position = UDim2.new(0,20,0,150)
MutationList.BackgroundColor3 = Color3.fromRGB(50,50,50) -- Slightly lighter grey
MutationList.BorderSizePixel = 0
MutationList.ScrollBarThickness = 4
MutationList.Visible = false
MutationList.ZIndex = 10
MutationList.ClipsDescendants = true
MutationList.Parent = MainPanel
makeBubble(MutationList,6,Color3.fromRGB(120,120,120))

local mLayout = Instance.new("UIListLayout", MutationList)
mLayout.Padding = UDim.new(0,2)
mLayout.SortOrder = Enum.SortOrder.LayoutOrder
local mPadding = Instance.new("UIPadding", MutationList)
mPadding.PaddingBottom = UDim.new(0,4)

getgenv().SelectedMutations = {}
for _, name in ipairs(mutationNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-8,0,24)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50) -- Slightly lighter grey
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = name
    btn.ZIndex = 11
    btn.Parent = MutationList
    makeBubble(btn,4,Color3.fromRGB(120,120,120))

    btn.MouseButton1Click:Connect(function()
        local foundIndex = nil
        for i,v in ipairs(getgenv().SelectedMutations) do
            if v == name then
                foundIndex = i
                break
            end
        end

        if foundIndex then
            table.remove(getgenv().SelectedMutations, foundIndex)
            btn.Text = name
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        else
            table.insert(getgenv().SelectedMutations, name)
            btn.Text = "✅ "..name
            btn.BackgroundColor3 = Color3.fromRGB(0,160,0) -- Green for selected
        end
    end)
end

MutationBtn.MouseButton1Click:Connect(function()
    MutationList.Visible = not MutationList.Visible
    if MutationList.Visible then
        MutationList.CanvasSize = UDim2.new(0,0,0,#mutationNames*26)
        MutationList.Size = UDim2.new(0,180,0, math.min(#mutationNames*26,150))
    else
        MutationList.Size = UDim2.new(0,180,0,0)
    end
end)

-----------------------------------------------------
-- 🍎 FRUIT DROPDOWN
-----------------------------------------------------
local fruitNames = {
    "Carrot","Strawberry","Blueberry","Tomato","Bamboo","Cactus","Pepper","Cacao","Blood Banana",
    "Giant Pinecone","Pumpkin","Beanstalk","Watermelon","Pineapple","Grape","Sugar Apple","Pitcher Plant",
    "Feijoa","Prickly Pear","Pear","Apple","Dragonfruit","Coconut","Mushroom","Orange Tulip","Corn",
    "Candy Blossom","Bone Blossom","Moon Blossom"
}

local FruitDropdown = Instance.new("Frame")
FruitDropdown.Size = UDim2.new(0,180,0,30)
FruitDropdown.Position = UDim2.new(0,10,0,160)
FruitDropdown.BackgroundColor3 = Color3.fromRGB(40,40,40)
FruitDropdown.ClipsDescendants = true
FruitDropdown.Parent = MainPanel
makeBubble(FruitDropdown,6,Color3.fromRGB(120,120,120))

local FruitBtn = Instance.new("TextButton")
FruitBtn.Size = UDim2.new(1,0,1,0)
FruitBtn.BackgroundTransparency = 1
FruitBtn.Text = "FRUIT ▼"
FruitBtn.TextColor3 = Color3.fromRGB(255,255,255)
FruitBtn.Font = Enum.Font.GothamBold
FruitBtn.TextSize = 14
FruitBtn.Parent = FruitDropdown

local FruitList = Instance.new("ScrollingFrame")
FruitList.Size = UDim2.new(0,180,0,0)
FruitList.Position = UDim2.new(0,20,0,190)
FruitList.BackgroundColor3 = Color3.fromRGB(50,50,50)
FruitList.BorderSizePixel = 0
FruitList.ScrollBarThickness = 4
FruitList.Visible = false
FruitList.ZIndex = 10
FruitList.ClipsDescendants = true
FruitList.Parent = MainPanel
makeBubble(FruitList,6,Color3.fromRGB(120,120,120))

local fLayout = Instance.new("UIListLayout", FruitList)
fLayout.Padding = UDim.new(0,2)
fLayout.SortOrder = Enum.SortOrder.LayoutOrder
local fPadding = Instance.new("UIPadding", FruitList)
fPadding.PaddingBottom = UDim.new(0,4)

for _, name in ipairs(fruitNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-8,0,24)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = name
    btn.ZIndex = 11
    btn.Parent = FruitList
    makeBubble(btn,4,Color3.fromRGB(120,120,120))

    btn.MouseButton1Click:Connect(function()
        if getgenv().SelectedFruit == name then
            getgenv().SelectedFruit = nil
            btn.Text = name
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            FruitBtn.Text = "FRUIT ▼"
        else
            getgenv().SelectedFruit = name
            for _, child in ipairs(FruitList:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Text = child.Text:gsub("✅ ","")
                    child.BackgroundColor3 = Color3.fromRGB(50,50,50)
                end
            end
            btn.Text = "✅ "..name
            btn.BackgroundColor3 = Color3.fromRGB(0,160,0)
            FruitBtn.Text = "FRUIT: "..name
        end
    end)
end

FruitBtn.MouseButton1Click:Connect(function()
    FruitList.Visible = not FruitList.Visible
    if FruitList.Visible then
        FruitList.CanvasSize = UDim2.new(0,0,0,#fruitNames*26)
        FruitList.Size = UDim2.new(0,180,0, math.min(#fruitNames*26,150))
    else
        FruitList.Size = UDim2.new(0,180,0,0)
    end
end)

-----------------------------------------------------
-- ✅ AUTO COLLECT TOGGLE
-----------------------------------------------------
local AutoCollectFrame = Instance.new("Frame")
AutoCollectFrame.Size = UDim2.new(0,180,0,30)
AutoCollectFrame.Position = UDim2.new(0,10,0,200)
AutoCollectFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
AutoCollectFrame.Parent = MainPanel
makeBubble(AutoCollectFrame,6,Color3.fromRGB(120,120,120))

local AutoCollectLabel = Instance.new("TextLabel")
AutoCollectLabel.Size = UDim2.new(0.6,0,1,0)
AutoCollectLabel.BackgroundTransparency = 1
AutoCollectLabel.Text = "Auto Collect"
AutoCollectLabel.TextColor3 = Color3.fromRGB(255,255,255)
AutoCollectLabel.Font = Enum.Font.GothamBold
AutoCollectLabel.TextSize = 14
AutoCollectLabel.Parent = AutoCollectFrame

local ToggleBG = Instance.new("Frame")
ToggleBG.AnchorPoint = Vector2.new(1,0.5)
ToggleBG.Position = UDim2.new(1,-8,0.5,0)
ToggleBG.Size = UDim2.new(0,50,0,20)
ToggleBG.BackgroundColor3 = Color3.fromRGB(50,50,50)
ToggleBG.ClipsDescendants = true
ToggleBG.Parent = AutoCollectFrame
ToggleBG.BorderSizePixel = 0
Instance.new("UICorner",ToggleBG).CornerRadius = UDim.new(1,0)

local Knob = Instance.new("Frame")
Knob.Size = UDim2.new(0,18,0,18)
Knob.Position = UDim2.new(0,1,0.5,-9)
Knob.BackgroundColor3 = Color3.fromRGB(120,120,120)
Knob.Parent = ToggleBG
Instance.new("UICorner",Knob).CornerRadius = UDim.new(1,0)

local ToggleButton = Instance.new("TextButton")
ToggleButton.BackgroundTransparency = 1
ToggleButton.Size = UDim2.new(1,0,1,0)
ToggleButton.Text = ""
ToggleButton.Parent = AutoCollectFrame

local autoCollectOn = false
ToggleButton.MouseButton1Click:Connect(function()
    autoCollectOn = not autoCollectOn
    getgenv().AutoCollect = autoCollectOn
    if autoCollectOn then
        ToggleBG.BackgroundColor3 = Color3.fromRGB(0,160,0)
        Knob:TweenPosition(UDim2.new(1,-19,0.5,-9),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true)
    else
        ToggleBG.BackgroundColor3 = Color3.fromRGB(50,50,50)
        Knob:TweenPosition(UDim2.new(0,1,0.5,-9),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true)
    end
end)

-----------------------------------------------------
-- 🔁 AUTO COLLECT LOOP
-----------------------------------------------------
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().AutoCollect and getgenv().SelectedFruit then
            local collectList = {}

            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and CollectionService:HasTag(prompt,"CollectPrompt") then
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

-----------------------------------------------------
-- ⭐ Title (light grey, no border/outline)
-----------------------------------------------------
local TitleHolder = Instance.new("Frame")
TitleHolder.Parent = MainFrame
TitleHolder.Size = UDim2.new(1, -120, 0, 40)
TitleHolder.Position = UDim2.new(0, 120, 0, 0)
TitleHolder.BackgroundTransparency = 1

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleHolder
TitleText.Size = UDim2.new(1, 0, 0, 24)
TitleText.Position = UDim2.new(0, 0, 0, 4)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "👹•Welcome to KoalaHub!"
TitleText.TextSize = 22
TitleText.TextColor3 = Color3.fromRGB(200,200,200) -- Light grey
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextYAlignment = Enum.TextYAlignment.Top

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = TitleHolder
SubTitle.Size = UDim2.new(1, 0, 0, 18)
SubTitle.Position = UDim2.new(0, 0, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Font = Enum.Font.Gotham
SubTitle.Text = "[💢] Grow a Garden🌶️"
SubTitle.TextSize = 16
SubTitle.TextColor3 = Color3.fromRGB(200,200,200)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.TextYAlignment = Enum.TextYAlignment.Top

-----------------------------------------------------
-- CLOSE / MINIMIZE
-----------------------------------------------------
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.Text = "✖"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Size = UDim2.new(0,24,0,24)
CloseBtn.Position = UDim2.new(1,-28,0,3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
makeBubble(CloseBtn,6,Color3.fromRGB(120,120,120))

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = MainFrame
MinimizeBtn.Text = "▭"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.Size = UDim2.new(0,24,0,24)
MinimizeBtn.Position = UDim2.new(1,-56,0,3)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
makeBubble(MinimizeBtn,6,Color3.fromRGB(120,120,120))

-----------------------------------------------------
-- LEFT SIDE TABS
-----------------------------------------------------
local SideTabs = Instance.new("Frame")
SideTabs.Parent = MainFrame
SideTabs.BackgroundColor3 = Color3.fromRGB(40,40,40)
SideTabs.Size = UDim2.new(0,110,1,0)
makeBubble(SideTabs,10,Color3.fromRGB(120,120,120))

local KCHLabel = Instance.new("TextLabel")
KCHLabel.Parent = SideTabs
KCHLabel.Size = UDim2.new(1,0,0,60)
KCHLabel.BackgroundTransparency = 0.3
KCHLabel.BackgroundColor3 = Color3.fromRGB(50,50,50)
KCHLabel.Text = "K C H"
KCHLabel.TextColor3 = Color3.fromRGB(255,255,255)
KCHLabel.Font = Enum.Font.GothamBold
KCHLabel.TextScaled = true
KCHLabel.TextWrapped = true
KCHLabel.TextStrokeTransparency = 0
KCHLabel.TextStrokeColor3 = Color3.fromRGB(120,120,120)

local KCHCorner = Instance.new("UICorner")
KCHCorner.CornerRadius = UDim.new(0,10)
KCHCorner.Parent = KCHLabel

local stroke = Instance.new("UIStroke")
stroke.Parent = KCHLabel
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color = Color3.fromRGB(120,120,120)

local TabsContainer = Instance.new("Frame")
TabsContainer.Parent = SideTabs
TabsContainer.BackgroundTransparency = 1
TabsContainer.Size = UDim2.new(1,0,1,-60)
TabsContainer.Position = UDim2.new(0,0,0,60)

local TabPadding = Instance.new("UIPadding")
TabPadding.Parent = TabsContainer
TabPadding.PaddingTop = UDim.new(0,10)
TabPadding.PaddingBottom = UDim.new(0,10)

local SideList = Instance.new("UIListLayout")
SideList.Parent = TabsContainer
SideList.Padding = UDim.new(0,8)
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.VerticalAlignment = Enum.VerticalAlignment.Top

local tabs = {}
local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9,0,0,30)
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = TabIcons[name] .. " " .. name
	btn.Parent = TabsContainer
	makeBubble(btn,6,Color3.fromRGB(120,120,120))
	table.insert(tabs, btn)
	return btn
end

local currentTab
local function selectTab(btn)
	for _,b in ipairs(tabs) do
		b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	end
	btn.BackgroundColor3 = Color3.fromRGB(100,100,100) -- Highlighted grey
	currentTab = btn
end

local homeTab = createTab("Home")
local mainTab = createTab("Main")
local petsTab = createTab("Pets")
local settingsTab = createTab("Settings")
local othersTab = createTab("Others")
selectTab(homeTab)

-----------------------------------------------------
-- 📌 RIGHT PANEL
-----------------------------------------------------
local RightPanel = Instance.new("Frame")
RightPanel.Name = "RightPanel"
RightPanel.Size = UDim2.new(1,-120,1,-45)
RightPanel.Position = UDim2.new(0,120,0,45)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = MainFrame

-----------------------------------------------------
-- Dropdown creator
-----------------------------------------------------
local function createDropdown(title, posY, highZ, parentPanel)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,-16,0,26)
	frame.Position = UDim2.new(0,8,0,posY)
	frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
	frame.ZIndex = highZ
	makeBubble(frame,6,Color3.fromRGB(120,120,120))
	frame.Parent = parentPanel

	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(1,0,1,0)
	btn.BackgroundTransparency = 1
	btn.Text = title.." ▼"
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.ZIndex = highZ+1

	local content = Instance.new("Frame", frame)
	content.Size = UDim2.new(1,0,0,110)
	content.Position = UDim2.new(0,0,1,0)
	content.BackgroundColor3 = Color3.fromRGB(50,50,50)
	content.Visible = false
	content.ZIndex = highZ+2
	content.ClipsDescendants = true
	makeBubble(content,6,Color3.fromRGB(120,120,120))

	local scroll = Instance.new("ScrollingFrame", content)
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = 5
	scroll.BackgroundTransparency = 1
	scroll.ZIndex = highZ+3

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0,2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
	end)

	btn.MouseButton1Click:Connect(function()
		content.Visible = not content.Visible
		btn.Text = title .. (content.Visible and " ▲" or " ▼")
	end)

	return frame, scroll
end

-- Main tab dropdowns
local gearDropdown, gearScroll = createDropdown("Gear Shop", 0, 50, MainPanel)
local seedDropdown, seedScroll = createDropdown("Seed Shop", 36, 60, MainPanel)

-----------------------------------------------------
-- PETS TAB PANEL
-----------------------------------------------------
local PetsPanel = Instance.new("Frame")
PetsPanel.Size = UDim2.new(1,-120,1,-45)
PetsPanel.Position = UDim2.new(0,120,0,45)
PetsPanel.BackgroundTransparency = 1
PetsPanel.Parent = MainFrame
PetsPanel.Visible = false

local petsDropdown, petsScroll = createDropdown("List Pets",0,50,PetsPanel)
petsScroll.ScrollingEnabled = true
petsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
petsScroll.CanvasSize = UDim2.new(0,0,0,0)
petsScroll.ScrollBarThickness = 6
petsScroll.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)
petsScroll.BackgroundTransparency = 1
petsScroll.BorderSizePixel = 0

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0,4)
listLayout.Parent = petsScroll

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0,4)
padding.PaddingRight = UDim.new(0,4)
padding.PaddingTop = UDim.new(0,4)
padding.PaddingBottom = UDim.new(0,4)
padding.Parent = petsScroll

local samplePets = {"Pet A","Pet B","Pet C","Pet D","Pet E","Pet F","Pet G","Pet H","Pet I","Pet J","Pet K","Pet L"}
for _,p in ipairs(samplePets) do
	local petBtn = Instance.new("TextButton")
	petBtn.Size = UDim2.new(1,-10,0,24)
	petBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	petBtn.TextColor3 = Color3.fromRGB(255,255,255)
	petBtn.Font = Enum.Font.GothamBold
	petBtn.TextSize = 13
	petBtn.TextXAlignment = Enum.TextXAlignment.Left
	petBtn.Text = p
	petBtn.ZIndex = 80
	petBtn.AutoButtonColor = true
	petBtn.Parent = petsScroll
	makeBubble(petBtn,6,Color3.fromRGB(120,120,120))

	petBtn.MouseButton1Click:Connect(function()
		print("Selected Pet:", p)
	end)
end

-----------------------------------------------------
-- REFRESH BUTTON
-----------------------------------------------------
local RefreshBtn = Instance.new("TextButton", PetsPanel)
RefreshBtn.Size = UDim2.new(0,100,0,30)
RefreshBtn.Position = UDim2.new(1,-120,0,35)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
RefreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Text = "⟳ Refresh"
makeBubble(RefreshBtn,8,Color3.fromRGB(120,120,120))
RefreshBtn.MouseButton1Click:Connect(function()
	print("TODO: refresh pets list here")
end)

-----------------------------------------------------
-- AUTO MID TOGGLE
-----------------------------------------------------
local AutoMidFrame = Instance.new("Frame", PetsPanel)
AutoMidFrame.Size = UDim2.new(0, 130, 0, 28)
AutoMidFrame.Position = UDim2.new(0, 8, 0, 35)
AutoMidFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
makeBubble(AutoMidFrame, 8, Color3.fromRGB(120,120,120))

local AutoMidLabel = Instance.new("TextLabel", AutoMidFrame)
AutoMidLabel.Size = UDim2.new(0.7, 0, 1, 0)
AutoMidLabel.Position = UDim2.new(0.05, 0, 0, 0)
AutoMidLabel.BackgroundTransparency = 1
AutoMidLabel.Font = Enum.Font.GothamBold
AutoMidLabel.TextSize = 14
AutoMidLabel.TextColor3 = Color3.fromRGB(255,255,255)
AutoMidLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoMidLabel.Text = "Auto Mid"

local AutoMidToggle = Instance.new("TextButton", AutoMidFrame)
AutoMidToggle.Size = UDim2.new(0, 30, 0, 16)
AutoMidToggle.Position = UDim2.new(1, -40, 0.5, -8)
AutoMidToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
AutoMidToggle.Text = ""
AutoMidToggle.AutoButtonColor = false
makeBubble(AutoMidToggle, 8, Color3.fromRGB(120,120,120))

local AutoMidKnob = Instance.new("Frame", AutoMidToggle)
AutoMidKnob.Size = UDim2.new(0, 14, 0, 14)
AutoMidKnob.Position = UDim2.new(0, 1, 0, 1)
AutoMidKnob.BackgroundColor3 = Color3.fromRGB(120,120,120)
makeBubble(AutoMidKnob, 7, Color3.fromRGB(120,120,120))

local autoMid = false
local function updateAutoMid(state)
	if state then
		TweenService:Create(AutoMidKnob,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
			{Position=UDim2.new(1,-15,0,1)}):Play()
		AutoMidToggle.BackgroundColor3 = Color3.fromRGB(0,160,0)
	else
		TweenService:Create(AutoMidKnob,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
			{Position=UDim2.new(0,1,0,1)}):Play()
		AutoMidToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
	end
end
AutoMidToggle.MouseButton1Click:Connect(function()
	autoMid = not autoMid
	updateAutoMid(autoMid)
end)
updateAutoMid(autoMid)

-----------------------------------------------------
-- 🔥 AUTO BUY TOGGLE
-----------------------------------------------------
local checkedGears, checkedSeeds = {}, {}
local autoBuy = false
local autoBuyRunning = false
local closingHub = false

local AutoBuyFrame = Instance.new("Frame")
AutoBuyFrame.Size = UDim2.new(0, 130, 0, 28)
AutoBuyFrame.Position = UDim2.new(0, 8, 0, 80)
AutoBuyFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
makeBubble(AutoBuyFrame, 8, Color3.fromRGB(120,120,120))
AutoBuyFrame.Parent = MainPanel

local AutoBuyLabel = Instance.new("TextLabel", AutoBuyFrame)
AutoBuyLabel.Size = UDim2.new(0.7, 0, 1, 0)
AutoBuyLabel.Position = UDim2.new(0.05, 0, 0, 0)
AutoBuyLabel.BackgroundTransparency = 1
AutoBuyLabel.Font = Enum.Font.GothamBold
AutoBuyLabel.TextSize = 14
AutoBuyLabel.TextColor3 = Color3.fromRGB(255,255,255)
AutoBuyLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoBuyLabel.Text = "Auto Buy"

local AutoBuyToggle = Instance.new("TextButton", AutoBuyFrame)
AutoBuyToggle.Size = UDim2.new(0, 30, 0, 16)
AutoBuyToggle.Position = UDim2.new(1, -40, 0.5, -8)
AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
AutoBuyToggle.Text = ""
AutoBuyToggle.AutoButtonColor = false
makeBubble(AutoBuyToggle, 8, Color3.fromRGB(120,120,120))

local AutoKnob = Instance.new("Frame", AutoBuyToggle)
AutoKnob.Size = UDim2.new(0, 14, 0, 14)
AutoKnob.Position = UDim2.new(0, 1, 0, 1)
AutoKnob.BackgroundColor3 = Color3.fromRGB(120,120,120)
makeBubble(AutoKnob, 7, Color3.fromRGB(120,120,120))

local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function updateAutoBuy(state)
    if state then
        TweenService:Create(AutoKnob, tweenInfo, {Position = UDim2.new(1, -15, 0, 1)}):Play()
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(0,160,0)
    else
        TweenService:Create(AutoKnob, tweenInfo, {Position = UDim2.new(0, 1, 0, 1)}):Play()
        AutoBuyToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    end
end

local function startAutoBuy()
    if autoBuyRunning then return end
    autoBuyRunning = true
    task.spawn(function()
        while autoBuy and not closingHub do
            for g,v in pairs(checkedGears) do
                if v then
                    pcall(function()
                        game.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(g)
                    end)
                end
            end
            for s,v in pairs(checkedSeeds) do
                if v then
                    pcall(function()
                        game.ReplicatedStorage.GameEvents.BuySeedStock:FireServer(s)
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
    updateAutoBuy(autoBuy)
    if autoBuy then startAutoBuy() end
end)
updateAutoBuy(autoBuy)

-----------------------------------------------------
-- GEAR ITEMS
-----------------------------------------------------
local gears = {
	"Watering Can","Trowel","Recall Wrench","Basic Sprinkler","Advance Sprinkler",
	"Medium Toy","Godly Sprinkler","Magnifying Glass","Tanning Mirror",
	"Master Sprinkler","Cleaning Spray","Favorite Tool","Harvest Tool","Friendship Pot","Levelup Lollipop"
}
for _,g in ipairs(gears) do
	local item = Instance.new("TextButton")
	item.Size = UDim2.new(1,-10,0,24)
	item.BackgroundColor3 = Color3.fromRGB(50,50,50)
	item.TextColor3 = Color3.fromRGB(255,255,255)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 13
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.Text = g
	item.ZIndex = 70
	item.Parent = gearScroll
	makeBubble(item,6,Color3.fromRGB(120,120,120))
	item.MouseButton1Click:Connect(function()
		checkedGears[g] = not checkedGears[g]
		item.Text = checkedGears[g] and (g.." ✓") or g
	end)
end

-----------------------------------------------------
-- SEED ITEMS
-----------------------------------------------------
local seeds = {
	"Carrot","Strawberry","Blueberry","Tomato","Bamboo","Cactus","Pepper","Cacao","Blood Banana",
	"Giant Pinecone","Pumpkin","Beanstalk","Watermelon","Pineapple","Grape","Sugar Apple",
	"Pitcher Plant","Feijoa","Prickly Pear","Pear","Apple","Dragonfruit","Coconut",
	"Mushroom","Orange Tulip","Corn"
}
for _, s in ipairs(seeds) do
	local seedBtn = Instance.new("TextButton")
	seedBtn.Size = UDim2.new(1, -10, 0, 24)
	seedBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	seedBtn.TextColor3 = Color3.fromRGB(255,255,255)
	seedBtn.Font = Enum.Font.GothamBold
	seedBtn.TextSize = 13
	seedBtn.TextXAlignment = Enum.TextXAlignment.Left
	seedBtn.Text = s
	seedBtn.ZIndex = 80
	seedBtn.Parent = seedScroll
	makeBubble(seedBtn,6,Color3.fromRGB(120,120,120))
	seedBtn.MouseButton1Click:Connect(function()
		checkedSeeds[s] = not checkedSeeds[s]
		seedBtn.Text = checkedSeeds[s] and (s.." ✓") or s
	end)
end

-----------------------------------------------------
-- SETTINGS PANEL
-----------------------------------------------------
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Size = UDim2.new(1, -120, 1, -45)
SettingsPanel.Position = UDim2.new(0, 120, 0, 45)
SettingsPanel.BackgroundTransparency = 1
SettingsPanel.Visible = false
SettingsPanel.ClipsDescendants = true
SettingsPanel.Parent = MainFrame

local StandbyText = Instance.new("TextLabel")
StandbyText.Parent = SettingsPanel
StandbyText.Size = UDim2.new(1, 0, 1, 0)
StandbyText.BackgroundTransparency = 1
StandbyText.Text = "WE ARE WORKING ON IT PLEASE STANDBY COMING SOON"
StandbyText.TextColor3 = Color3.fromRGB(255,255,255)
StandbyText.TextScaled = true
StandbyText.Font = Enum.Font.GothamBold
StandbyText.TextWrapped = true
StandbyText.AnchorPoint = Vector2.new(0.5,0.5)
StandbyText.Position = UDim2.new(0.5,0,0.5,0)

-----------------------------------------------------
-- OTHERS PANEL
-----------------------------------------------------
local OthersPanel = Instance.new("Frame")
OthersPanel.Name = "OthersPanel"
OthersPanel.Size = UDim2.new(1,-120,1,-45)
OthersPanel.Position = UDim2.new(0,120,0,45)
OthersPanel.BackgroundTransparency = 1
OthersPanel.Visible = false
OthersPanel.ClipsDescendants = true
OthersPanel.Parent = MainFrame

local function createStyledDropdown(titleText, posX, posY, parent)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, 200, 0, 32)
    dropdownFrame.Position = UDim2.new(0, posX, 0, posY)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    dropdownFrame.Parent = parent
    makeBubble(dropdownFrame,8,Color3.fromRGB(120,120,120))

    local mainButton = Instance.new("TextButton")
    mainButton.Size = UDim2.new(1,0,1,0)
    mainButton.BackgroundTransparency = 1
    mainButton.Font = Enum.Font.GothamBold
    mainButton.TextSize = 14
    mainButton.TextColor3 = Color3.fromRGB(255,255,255)
    mainButton.Text = titleText.." ▼"
    mainButton.Parent = dropdownFrame

    local listContainer = Instance.new("Frame")
    listContainer.Size = UDim2.new(1,0,0,0)
    listContainer.Position = UDim2.new(0,0,1,0)
    listContainer.BackgroundColor3 = Color3.fromRGB(50,50,50)
    listContainer.Visible = false
    listContainer.ClipsDescendants = true
    listContainer.Parent = dropdownFrame
    makeBubble(listContainer,8,Color3.fromRGB(120,120,120))

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Parent = listContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
        listContainer.Size = UDim2.new(1,0,0, math.min(layout.AbsoluteContentSize.Y,140))
    end)

    mainButton.MouseButton1Click:Connect(function()
        listContainer.Visible = not listContainer.Visible
        mainButton.Text = titleText .. (listContainer.Visible and " ▲" or " ▼")
    end)

    return dropdownFrame, scroll, mainButton, listContainer
end

-----------------------------------------------------
-- 🌦 WEATHER LOGIC + VISUAL TOGGLE
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

local VisualFrame = Instance.new("Frame")
VisualFrame.Size = UDim2.new(0,200,0,32)
VisualFrame.Position = UDim2.new(0,8,0,50)
VisualFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
VisualFrame.Parent = OthersPanel
makeBubble(VisualFrame,8,Color3.fromRGB(120,120,120))

local VisualLabel = Instance.new("TextLabel")
VisualLabel.Size = UDim2.new(0.7,0,1,0)
VisualLabel.Position = UDim2.new(0.05,0,0,0)
VisualLabel.BackgroundTransparency = 1
VisualLabel.Font = Enum.Font.GothamBold
VisualLabel.TextSize = 14
VisualLabel.TextColor3 = Color3.fromRGB(255,255,255)
VisualLabel.TextXAlignment = Enum.TextXAlignment.Left
VisualLabel.Text = "Visual"
VisualLabel.Parent = VisualFrame

local VisualToggle = Instance.new("TextButton")
VisualToggle.Size = UDim2.new(0,30,0,16)
VisualToggle.Position = UDim2.new(1,-40,0.5,-8)
VisualToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
VisualToggle.Text = ""
VisualToggle.AutoButtonColor = false
VisualToggle.Parent = VisualFrame
makeBubble(VisualToggle,8,Color3.fromRGB(120,120,120))

local VisualKnob = Instance.new("Frame")
VisualKnob.Size = UDim2.new(0,14,0,14)
VisualKnob.Position = UDim2.new(0,1,0,1)
VisualKnob.BackgroundColor3 = Color3.fromRGB(120,120,120)
VisualKnob.Parent = VisualToggle
makeBubble(VisualKnob,7,Color3.fromRGB(120,120,120))

local function updateVisual(state)
    local targetPos = state and UDim2.new(1,-15,0,1) or UDim2.new(0,1,0,1)
    VisualToggle.BackgroundColor3 = state and Color3.fromRGB(0,160,0) or Color3.fromRGB(50,50,50)
    TweenService:Create(VisualKnob,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=targetPos}):Play()
end

VisualToggle.MouseButton1Click:Connect(function()
    visualState = not visualState
    updateVisual(visualState)
    if visualState then
        if currentWeather then enableWeather(currentWeather) end
    else
        disableWeather()
    end
end)
updateVisual(visualState)

local weatherDropdownFrame, weatherScroll, weatherMainBtn, weatherListContainer =
    createStyledDropdown("Weather List", 10, 10, OthersPanel)

weatherScroll.ScrollingEnabled = true
weatherScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
weatherScroll.CanvasSize = UDim2.new(0,0,0,0)
weatherScroll.ScrollBarThickness = 6
weatherScroll.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)

local weatherLayout = Instance.new("UIListLayout", weatherScroll)
weatherLayout.Padding = UDim.new(0,4)

local weatherPad = Instance.new("UIPadding", weatherScroll)
weatherPad.PaddingLeft = UDim.new(0,4)
weatherPad.PaddingRight = UDim.new(0,4)
weatherPad.PaddingTop = UDim.new(0,4)
weatherPad.PaddingBottom = UDim.new(0,4)

for _, weatherName in ipairs(weatherAttributes) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-10,0,24)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = weatherName
    btn.ZIndex = 80
    btn.Parent = weatherScroll
    makeBubble(btn,6,Color3.fromRGB(120,120,120))

    btn.MouseButton1Click:Connect(function()
        if currentWeather == weatherName then
            currentWeather = nil
            weatherMainBtn.Text = "Weather List ▼"
            if visualState then disableWeather() end
        else
            currentWeather = weatherName
            weatherMainBtn.Text = "✔ "..weatherName.." ▼"
            if visualState then enableWeather(weatherName) end
        end
        weatherListContainer.Visible = false
    end)
end

-----------------------------------------------------
-- 💧 SPRINKLER DROPDOWN
-----------------------------------------------------
local sprinklerDropdownFrame, sprinklerScroll, sprinklerMainBtn, sprinklerListContainer =
    createStyledDropdown("Sprinkler List", 10, 90, OthersPanel)

sprinklerScroll.ScrollingEnabled = true
sprinklerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
sprinklerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sprinklerScroll.ScrollBarThickness = 6
sprinklerScroll.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)

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
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    else
        selectedSprinklers[name] = true
        btn.BackgroundColor3 = Color3.fromRGB(0,160,0)
    end
end

for _, sName in ipairs(sprinklerNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 24)
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = "   " .. sName
    b.ZIndex = 60
    b.Parent = sprinklerScroll
    makeBubble(b,6,Color3.fromRGB(120,120,120))

    b.MouseButton1Click:Connect(function()
        toggleSprinkler(sName, b)
    end)
end

-----------------------------------------------------
-- 🌱 AUTO SHOVEL TOGGLE UI
-----------------------------------------------------
local ShovelFrame = Instance.new("Frame")
ShovelFrame.Size = UDim2.new(0,200,0,32)
ShovelFrame.Position = UDim2.new(0,8,0,130)
ShovelFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
ShovelFrame.Parent = OthersPanel
makeBubble(ShovelFrame,8,Color3.fromRGB(120,120,120))

local ShovelLabel = Instance.new("TextLabel")
ShovelLabel.Size = UDim2.new(0.7,0,1,0)
ShovelLabel.Position = UDim2.new(0.05,0,0,0)
ShovelLabel.BackgroundTransparency = 1
ShovelLabel.Font = Enum.Font.GothamBold
ShovelLabel.TextSize = 14
ShovelLabel.TextColor3 = Color3.fromRGB(255,255,255)
ShovelLabel.TextXAlignment = Enum.TextXAlignment.Left
ShovelLabel.Text = "Auto Shovel"
ShovelLabel.Parent = ShovelFrame

local ShovelToggle = Instance.new("TextButton")
ShovelToggle.Size = UDim2.new(0,30,0,16)
ShovelToggle.Position = UDim2.new(1,-40,0.5,-8)
ShovelToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
ShovelToggle.Text = ""
ShovelToggle.AutoButtonColor = false
ShovelToggle.Parent = ShovelFrame
makeBubble(ShovelToggle,8,Color3.fromRGB(120,120,120))

local ShovelKnob = Instance.new("Frame")
ShovelKnob.Size = UDim2.new(0,14,0,14)
ShovelKnob.Position = UDim2.new(0,1,0,1)
ShovelKnob.BackgroundColor3 = Color3.fromRGB(120,120,120)
ShovelKnob.Parent = ShovelToggle
makeBubble(ShovelKnob,7,Color3.fromRGB(120,120,120))

local autoShovelState = false
local function updateShovelToggle(state)
    local targetPos = state and UDim2.new(1,-15,0,1) or UDim2.new(0,1,0,1)
    ShovelToggle.BackgroundColor3 = state and Color3.fromRGB(0,160,0) or Color3.fromRGB(50,50,50)
    TweenService:Create(ShovelKnob,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=targetPos}):Play()
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
    updateShovelToggle(autoShovelState)
    print("🛠️ Auto Shovel toggled:", autoShovelState)
end)
updateShovelToggle(autoShovelState)

-----------------------------------------------------
-- 🔄 AUTO SHOVEL LOOP
-----------------------------------------------------
local DeleteObject = game.ReplicatedStorage.GameEvents:FindFirstChild("DeleteObject")
local SprinklerFolder = workspace.Farm.Farm.Important:WaitForChild("Objects_Physical")

task.spawn(function()
    while task.wait(0.3) do
        if autoShovelState then
            holdShovel()
            for _, model in ipairs(SprinklerFolder:GetChildren()) do
                if model:IsA("Model") then
                    for name,_ in pairs(selectedSprinklers) do
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
end)

-----------------------------------------------------
-- PET SYSTEM INTEGRATION
-----------------------------------------------------
getgenv().PetIdle = false
local TargetPosition = Vector3.new(0,0,0)
local SelectedPets = {}

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local remote = RS.GameEvents:WaitForChild("ActivePetService")
local PetUI = lp:WaitForChild("PlayerGui"):WaitForChild("ActivePetUI")

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
        btn.Size = UDim2.new(1,-10,0,24)
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Text = "◻️ "..pet.name
        btn.ZIndex = 80
        btn.Parent = petsScroll
        makeBubble(btn,6,Color3.fromRGB(120,120,120))

        local selected = false
        btn.MouseButton1Click:Connect(function()
            selected = not selected
            if selected then
                table.insert(SelectedPets, pet.uuid)
                btn.Text = "✅ "..pet.name
                btn.BackgroundColor3 = Color3.fromRGB(0,160,0)
            else
                for i,v in ipairs(SelectedPets) do
                    if v == pet.uuid then table.remove(SelectedPets,i) break end
                end
                btn.Text = "◻️ "..pet.name
                btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            end
        end)
    end
end

RefreshBtn.MouseButton1Click:Connect(function()
    rebuildPetList()
end)

AutoMidToggle.MouseButton1Click:Connect(function()
    getgenv().PetIdle = not getgenv().PetIdle
    updateAutoMid(getgenv().PetIdle)
    if getgenv().PetIdle then
        startAutoMid()
    else
        if currentLoopThread then
            task.cancel(currentLoopThread)
            currentLoopThread = nil
        end
    end
end)

rebuildPetList()

-----------------------------------------------------
-- TAB SWITCHING
-----------------------------------------------------
local function showMain()
	RightPanel.Visible = true
	PetsPanel.Visible = false
	OthersPanel.Visible = false
	SettingsPanel.Visible = false
	HomePanel.Visible = false
end
local function showPets()
	RightPanel.Visible = false
	PetsPanel.Visible = true
	OthersPanel.Visible = false
	SettingsPanel.Visible = false
	HomePanel.Visible = false
end
local function showOthers()
	RightPanel.Visible = false
	PetsPanel.Visible = false
	OthersPanel.Visible = true
	SettingsPanel.Visible = false
	HomePanel.Visible = false
end
local function showSettings()
	RightPanel.Visible = false
	PetsPanel.Visible = false
	OthersPanel.Visible = false
	SettingsPanel.Visible = true
	HomePanel.Visible = false
end
local function showHome()
	RightPanel.Visible = false
	PetsPanel.Visible = false
	OthersPanel.Visible = false
	SettingsPanel.Visible = false
	HomePanel.Visible = true
end

homeTab.MouseButton1Click:Connect(function()
	selectTab(homeTab)
	showHome()
end)
mainTab.MouseButton1Click:Connect(function()
	selectTab(mainTab)
	showMain()
end)
petsTab.MouseButton1Click:Connect(function()
	selectTab(petsTab)
	showPets()
end)
settingsTab.MouseButton1Click:Connect(function()
	selectTab(settingsTab)
	showSettings()
end)
othersTab.MouseButton1Click:Connect(function()
	selectTab(othersTab)
	showOthers()
end)
showHome()

-----------------------------------------------------
-- MINIMIZE
-----------------------------------------------------
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	local targetSize = minimized and UDim2.new(0,520,0,40) or UDim2.new(0,520,0,300)
	TweenService:Create(
		MainFrame,
		TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
		{Size = targetSize}
	):Play()
	SideTabs.Visible = not minimized
	RightPanel.Visible = not minimized and currentTab == mainTab
	PetsPanel.Visible = not minimized and currentTab == petsTab
	OthersPanel.Visible = not minimized and currentTab == othersTab
	SettingsPanel.Visible = not minimized and currentTab == settingsTab
	HomePanel.Visible = not minimized and currentTab == homeTab
end)

-----------------------------------------------------
-- CLOSE CONFIRM
-----------------------------------------------------
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Name = "ConfirmFrame"
ConfirmFrame.Parent = MainFrame
ConfirmFrame.Size = UDim2.new(0, 180, 0, 100)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
ConfirmFrame.Visible = false
ConfirmFrame.Position = UDim2.new(0.5,-90,0.5,-50)
ConfirmFrame.ZIndex = 100
makeBubble(ConfirmFrame,10,Color3.fromRGB(120,120,120))

local ConfirmLabel = Instance.new("TextLabel", ConfirmFrame)
ConfirmLabel.Size = UDim2.new(1,-20,0,40)
ConfirmLabel.Position = UDim2.new(0,10,0,8)
ConfirmLabel.BackgroundTransparency = 1
ConfirmLabel.Font = Enum.Font.GothamBold
ConfirmLabel.Text = "Close KoalaHub?"
ConfirmLabel.TextColor3 = Color3.fromRGB(200,200,200)
ConfirmLabel.TextScaled = true
ConfirmLabel.ZIndex = 101

local YesBtn = Instance.new("TextButton", ConfirmFrame)
YesBtn.Size = UDim2.new(0.45,0,0,30)
YesBtn.Position = UDim2.new(0.05,0,1,-38)
YesBtn.BackgroundColor3 = Color3.fromRGB(0,160,0)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextColor3 = Color3.fromRGB(255,255,255)
YesBtn.Text = "✓ YES"
YesBtn.ZIndex = 102
makeBubble(YesBtn,6,Color3.fromRGB(120,120,120))
YesBtn.MouseButton1Click:Connect(function()
    closingHub = true
    autoBuy = false
    ScreenGui:Destroy()
    FloatGui:Destroy()
end)

local NoBtn = Instance.new("TextButton", ConfirmFrame)
NoBtn.Size = UDim2.new(0.45,0,0,30)
NoBtn.Position = UDim2.new(0.5,0,1,-38)
NoBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextColor3 = Color3.fromRGB(255,255,255)
NoBtn.Text = "✘ NO"
NoBtn.ZIndex = 102
makeBubble(NoBtn,6,Color3.fromRGB(120,120,120))
NoBtn.MouseButton1Click:Connect(function()
    ConfirmFrame.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    ConfirmFrame.Visible = true
end)

-----------------------------------------------------
-- TOGGLE MAIN GUI WITH ICON
-----------------------------------------------------
IconButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)