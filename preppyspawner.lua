local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local ContextActionService = game:GetService('ContextActionService')

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local PREPPY_PRIMARY_COLOR = Color3.fromRGB(0, 200, 220)
local PREPPY_SECONDARY_COLOR = Color3.fromRGB(120, 90, 255)
local PREPPY_BACKGROUND = Color3.fromRGB(25, 30, 45)
local PREPPY_TEXT_COLOR = Color3.fromRGB(230, 230, 230)
local PREPPY_HOVER_COLOR = Color3.fromRGB(50, 55, 70)

local function setThreadIdentity(identity)
    pcall(function()
        setthreadidentity(identity)
    end)
end
setThreadIdentity(2)

local function _util_generate_id()
    return HttpService:GenerateGUID(false)
end

local function _util_clone_table(tbl)
    local newTable = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            newTable[k] = _util_clone_table(v)
        else
            newTable[k] = v
        end
    end
    return newTable
end

local function _util_find_in_table(array, predicate)
    for i, v in pairs(array) do
        if predicate(v, i) then
            return i
        end
    end
    return nil
end

local SimulatedFsys = {}
SimulatedFsys.load = function(moduleName)
    if moduleName == "ClientData" then
        return {
            get = function(key)
                if key == "inventory" then
                    return { pets = {}, toys = {} }
                elseif key == "pet_char_wrappers" then
                    return {}
                elseif key == "pet_state_managers" then
                    return {}
                end
                return {}
            end,
            predict = function(key, value)
            end
        }
    elseif moduleName == "KindDB" then
        return {
            pets = {
                ["Shadow Dragon"] = { name = "Shadow Dragon", kind = "pet", id = "Shadow Dragon" },
                ["Bat Dragon"] = { name = "Bat Dragon", kind = "pet", id = "Bat Dragon" },
                ["Frost Dragon"] = { name = "Frost Dragon", kind = "pet", id = "Frost Dragon" },
                ["Giraffe"] = { name = "Giraffe", kind = "pet", id = "Giraffe" },
                ["Owl"] = { name = "Owl", kind = "pet", id = "Owl" },
                ["Parrot"] = { name = "Parrot", kind = "pet", id = "Parrot" },
                ["Turtle"] = { name = "Turtle", kind = "pet", id = "Turtle" },
                ["Kangaroo"] = { name = "Kangaroo", kind = "pet", id = "Kangaroo" },
                ["Lion"] = { name = "Lion", kind = "pet", id = "Lion" },
                ["Elephant"] = { name = "Elephant", kind = "pet", id = "Elephant" },
            },
            toys = {
                ["Squeaky Toy"] = { name = "Squeaky Toy", kind = "toy", id = "Squeaky Toy" }
            }
        }
    elseif moduleName == "UIManager" then
        return {
            apps = {
                BackpackApp = {
                    refresh_rendered_items = function()
                    end
                }
            }
        }
    elseif moduleName == "RouterClient" then
        return {
            get = function(endpoint)
                return {
                    InvokeServer = function(...)
                        return true
                    end,
                    FireServer = function(...)
                        return true
                    end
                }
            end
        }
    elseif moduleName == "AnimationManager" then
         return {
             get_track = function(trackName)
                 return Instance.new("Animation")
             end
         }
    elseif moduleName == "DownloadClient" then
        return {
            promise_download_copy = function(storage, name)
                return {
                    expect = function()
                        local model = Instance.new("Model")
                        model.Name = name .. "Model"
                        return model
                    end
                }
            end
        }
     elseif moduleName == "PetRigs" then
         return {
             get = function(model)
                 return {
                     get_geo_part = function(model, partName)
                         local part = model:FindFirstChild(partName)
                         if not part then
                             part = Instance.new("Part")
                             part.Name = partName
                             part.Parent = model
                         end
                         return part
                     end
                 }
             end
         }
     elseif moduleName == "AilmentsClient" then
         return {
             on_ailments_changed = function(player)
             end
         }
     elseif moduleName == "AilmentsDB" then
         return {
             at_work = {}, mystery = {}, walking = {}
         }
    end
    return {}
end

local ClientData = SimulatedFsys.load("ClientData")
local KindDB = SimulatedFsys.load("KindDB")
local UIManager = SimulatedFsys.load("UIManager")
local RouterClient = SimulatedFsys.load("RouterClient")
local AnimationManager = SimulatedFsys.load("AnimationManager")
local DownloadClient = SimulatedFsys.load("DownloadClient")
local PetRigs = SimulatedFsys.load("PetRigs")
local AilmentsClient = SimulatedFsys.load("AilmentsClient")
local AilmentsDB = SimulatedFsys.load("AilmentsDB")

local SpawnedObjects = {}
local ObjectModelCache = {}

local function GenerateUniquePetName()
    local prefixes = {"☆", "✨", "☁️", "💖", "🌸", "🍓", "🌙", "🌈", "💫"}
    local names = {"Sparkle", "Glimmer", "Dream", "Star", "Moonbeam", "Cloud", "Petal", "Berry", "Rainbow", "Shimmer", "Aurora", "Nova", "Cosmo"}
    
    local usePrefix = math.random(1, 2) == 1
    local name = names[math.random(1, #names)]
    
    if usePrefix then
        return prefixes[math.random(1, #prefixes)] .. " " .. name
    else
        return name .. " " .. prefixes[math.random(1, #prefixes)]
    end
end

local NewnessGroups = {
    mega_neon_flyable_rideable = 990000, mega_neon_flyable = 980000, mega_neon_rideable = 970000, mega_neon = 960000,
    neon_flyable_rideable = 950000, neon_flyable = 940000, neon_rideable = 930000, neon = 920000,
    flyable_rideable = 910000, flyable = 900000, rideable = 890000, regular = 880000
}

local function GetPropertyGroup(properties)
    local isMega = properties.mega_neon or false
    local isNeon = properties.neon or false
    local canFly = properties.flyable or false
    local canRide = properties.rideable or false

    if isMega then
        if canFly and canRide then return "mega_neon_flyable_rideable"
        elseif canFly then return "mega_neon_flyable"
        elseif canRide then return "mega_neon_rideable"
        else return "mega_neon" end
    elseif isNeon then
        if canFly and canRide then return "neon_flyable_rideable"
        elseif canFly then return "neon_flyable"
        elseif canRide then return "neon_rideable"
        else return "neon" end
    else
        if canFly and canRide then return "flyable_rideable"
        elseif canFly then return "flyable"
        elseif canRide then return "rideable"
        else return "regular" end
    end
end

local nextToyOrder = 60000

local function CreateInventoryItem(itemId, category, properties)
    local uniqueId = _util_generate_id()
    local itemKindData = KindDB[category] and KindDB[category][itemId] or KindDB[itemId]
    
    if not itemKindData then
        warn("Item kind not found in simulated DB: " .. itemId)
        return nil
    end

    properties = properties or {}
    local newnessValue = nextToyOrder

    if category == "pets" then
        local groupKey = GetPropertyGroup(properties)
        NewnessGroups[groupKey] = (NewnessGroups[groupKey] or 0) - 1
        newnessValue = NewnessGroups[groupKey]

        properties.ailments_completed = properties.ailments_completed or 0
        if not properties.rp_name or properties.rp_name == "" then
            properties.rp_name = GenerateUniquePetName()
        end
    else
        nextToyOrder = nextToyOrder - 1
        newnessValue = nextToyOrder
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind or "unknown",
        newness_order = newnessValue,
        properties = properties,
        _source = "ZetaScripts" 
    }

    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local clientData = ClientData.get("inventory") or {}
    clientData[category] = clientData[category] or {}
    clientData[category][uniqueId] = itemData
    ClientData.predict("inventory", clientData)
    set_thread_identity(identity)

    SpawnedObjects[uniqueId] = { data = itemData, model = nil, category = category }

    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)
    
    print("Creato item: " .. itemId .. " (Unique: " .. uniqueId .. ")")
    return itemData
end

local function DeleteAllSpawnedObjects()
    local deletedCount = 0
    local inventory = ClientData.get("inventory") or {}
    
    for uniqueId, obj in pairs(SpawnedObjects) do
        if obj.model then
            obj.model:Destroy()
        end
        
        if inventory[obj.category] and inventory[obj.category][uniqueId] and inventory[obj.category][uniqueId]._source == "ZetaScripts" then
            inventory[obj.category][uniqueId] = nil
            deletedCount = deletedCount + 1
        end
    end
    
    SpawnedObjects = {}
    
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    ClientData.predict("inventory", inventory)
    set_thread_identity(identity)
    
    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)
    
    print("Eliminati " .. deletedCount .. " oggetti spawnati da ZetaScripts.")
    return deletedCount
end

local function FindPetId(petName)
    for id, info in pairs(KindDB.pets) do
        if info.name:lower() == petName:lower() then
            return id
        end
    end
    return nil
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZetaScriptsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 380)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -190)
mainFrame.BackgroundColor3 = PREPPY_BACKGROUND
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2.5
uiStroke.Color = PREPPY_PRIMARY_COLOR
uiStroke.Transparency = 0.3
uiStroke.Parent = mainFrame

local strokeColorSequence = {
    PREPPY_PRIMARY_COLOR,
    PREPPY_SECONDARY_COLOR,
    Color3.fromRGB(255, 90, 180),
    Color3.fromRGB(255, 170, 0)
}
local colorIdx = 1
task.spawn(function()
    while true do
        colorIdx = colorIdx % #strokeColorSequence + 1
        TweenService:Create(uiStroke, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Color = strokeColorSequence[colorIdx] }):Play()
        task.wait(5)
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextColor3 = PREPPY_TEXT_COLOR
titleLabel.Parent = mainFrame
titleLabel.Text = "✨ ZetaScripts(last4zeta on tt) ✨" 

local tabContainer = Instance.new('Frame')
tabContainer.Size = UDim2.new(0.92, 0, 0, 28)
tabContainer.Position = UDim2.new(0.04, 0, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {
    { key = 'Spawn', label = 'Spawn Pet', icon = '🐾' },
    { key = 'Settings', label = 'Settings', icon = '⚙️' }
}

local activeTab = 'Spawn'
local tabButtons = {}

local function SwitchTab(tabName)
    activeTab = tabName
    for key, button in pairs(tabButtons) do
        local isActive = (key == tabName)
        button.BackgroundColor3 = isActive and PREPPY_HOVER_COLOR or Color3.fromRGB(40, 44, 60)
        button.UIStroke.Color = isActive and PREPPY_PRIMARY_COLOR or Color3.fromRGB(80, 85, 100)
        button.UIStroke.Thickness = isActive and 1.5 or 0.8
        button.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 220)
        
        if key == 'Spawn' then spawnPanel.Visible = isActive end
        if key == 'Settings' then settingsPanel.Visible = isActive end
    end
end

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new('TextButton')
    tabButton.Size = UDim2.new(1 / #tabs - 0.02, 0, 1, 0)
    tabButton.Position = UDim2.new((i - 1) * (1 / #tabs), (i == 1) and 0 or 4, 0, 0)
    tabButton.BackgroundColor3 = i == 1 and PREPPY_HOVER_COLOR or Color3.fromRGB(40, 44, 60)
    tabButton.BackgroundTransparency = 0.1
    tabButton.Text = tab.icon .. " " .. tab.label
    tabButton.Font = Enum.Font.GothamBold
    tabButton.TextSize = 10
    tabButton.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 220)
    tabButton.Parent = tabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tabButton
    
    local stroke = Instance.new('UIStroke')
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = i == 1 and PREPPY_PRIMARY_COLOR or Color3.fromRGB(80, 85, 100)
    stroke.Thickness = i == 1 and 1.5 or 0.8
    stroke.Transparency = 0.4
    stroke.Parent = tabButton
    
    tabButtons[tab.key] = tabButton
    tabButton.UIStroke = stroke
    
    tabButton.MouseButton1Click:Connect(function()
        SwitchTab(tab.key)
    end)
end

local spawnPanel = Instance.new("Frame")
spawnPanel.Size = UDim2.new(0.92, 0, 1, -75)
spawnPanel.Position = UDim2.new(0.04, 0, 0, 75)
spawnPanel.BackgroundTransparency = 1
spawnPanel.Parent = mainFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 12)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🐾 Pet Name"
nameLabel.Font = Enum.Font.Gotham
nameLabel.TextSize = 8
nameLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = spawnPanel

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, 0, 0, 24)
nameInput.Position = UDim2.new(0, 0, 0, 12)
nameInput.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
nameInput.TextColor3 = PREPPY_TEXT_COLOR
nameInput.TextSize = 11
nameInput.Font = Enum.Font.Gotham
nameInput.PlaceholderText = "e.g., Shadow Dragon"
nameInput.PlaceholderColor3 = Color3.fromRGB(140, 150, 180)
nameInput.ClearTextOnFocus = false
nameInput.Text = "Shadow Dragon"
nameInput.Parent = spawnPanel

local nameInputCorner = Instance.new("UICorner")
nameInputCorner.CornerRadius = UDim.new(0, 7)
nameInputCorner.Parent = nameInput

local inputGlow = Instance.new("UIStroke")
inputGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputGlow.Color = Color3.fromRGB(220, 220, 220)
inputGlow.Thickness = 1.8
inputGlow.Transparency = 0.5
inputGlow.Parent = nameInput

local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(1, 0, 0, 12)
ageLabel.Position = UDim2.new(0, 0, 0, 42)
ageLabel.BackgroundTransparency = 1
ageLabel.Text = "📅 Age"
ageLabel.Font = Enum.Font.Gotham
ageLabel.TextSize = 8
ageLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
ageLabel.TextXAlignment = Enum.TextXAlignment.Left
ageLabel.Parent = spawnPanel

local ageGrid = Instance.new("Frame")
ageGrid.Size = UDim2.new(1, 0, 0, 26)
ageGrid.Position = UDim2.new(0, 0, 0, 55)
ageGrid.BackgroundTransparency = 1
ageGrid.Parent = spawnPanel

local ageCodes = {"N", "J", "PT", "T", "PG", "FG"}
local ageDescriptions = {"Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown"}
local currentAgeIndex = 1

for i, code in ipairs(ageCodes) do
    local ageButton = Instance.new("TextButton")
    ageButton.Size = UDim2.new(1/6 - 0.01, 0, 1, 0)
    ageButton.Position = UDim2.new((i-1) * (1/6), (i > 1) and 2 or 0, 0, 0)
    ageButton.Text = code
    ageButton.BackgroundColor3 = i == currentAgeIndex and Color3.fromRGB(80, 85, 100) or Color3.fromRGB(40, 44, 60)
    ageButton.Font = Enum.Font.GothamBold
    ageButton.TextColor3 = PREPPY_TEXT_COLOR
    ageButton.TextSize = 11
    ageButton.Parent = ageGrid
    
    local ageCorner = Instance.new("UICorner")
    ageCorner.CornerRadius = UDim.new(0, 6)
    ageCorner.Parent = ageButton
    
    local hintBox = Instance.new("TextLabel")
    hintBox.Text = ageDescriptions[i]
    hintBox.BackgroundColor3 = PREPPY_BACKGROUND
    hintBox.TextColor3 = PREPPY_TEXT_COLOR
    hintBox.TextSize = 7
    hintBox.Font = Enum.Font.Gotham
    hintBox.Size = UDim2.new(0, 0, 0, 0)
    hintBox.Visible = false
    hintBox.Parent = ageButton
    Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 4)
    
    ageButton.MouseEnter:Connect(function()
        hintBox.Size = UDim2.new(0, hintBox.TextBounds.X + 10, 0, hintBox.TextBounds.Y + 6)
        hintBox.Position = UDim2.new(0.5, -hintBox.Size.X.Offset/2, -1.2, 0)
        hintBox.Visible = true
    end)
    
    ageButton.MouseLeave:Connect(function()
        hintBox.Visible = false
    end)
    
    ageButton.MouseButton1Click:Connect(function()
        currentAgeIndex = i
        for _, btn in pairs(ageGrid:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
            end
        end
        ageButton.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
    end)
end

local flagLabel = Instance.new("TextLabel")
flagLabel.Size = UDim2.new(1, 0, 0, 12)
flagLabel.Position = UDim2.new(0, 0, 0, 85)
flagLabel.BackgroundTransparency = 1
flagLabel.Text = "✨ Pet Flags"
flagLabel.Font = Enum.Font.Gotham
flagLabel.TextSize = 8
flagLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
flagLabel.TextXAlignment = Enum.TextXAlignment.Left
flagLabel.Parent = spawnPanel

local flagGrid = Instance.new("Frame")
flagGrid.Size = UDim2.new(1, 0, 0, 30)
flagGrid.Position = UDim2.new(0, 0, 0, 98)
flagGrid.BackgroundTransparency = 1
flagGrid.Parent = spawnPanel

local flagConfig = {
    M = { name = "Mega Neon", color = Color3.fromRGB(170, 0, 255), defaultValue = false },
    N = { name = "Neon", color = Color3.fromRGB(0, 255, 100), defaultValue = true },
    F = { name = "Flyable", color = Color3.fromRGB(0, 200, 255), defaultValue = true },
    R = { name = "Rideable", color = Color3.fromRGB(255, 50, 150), defaultValue = true }
}

local flagState = {}
local flagButtons = {}

for i, flagKey in ipairs({"M", "N", "F", "R"}) do
    local config = flagConfig[flagKey]
    flagState[flagKey] = config.defaultValue

    local flagButton = Instance.new("TextButton")
    flagButton.Size = UDim2.new(0.23, -2, 1, 0)
    flagButton.Position = UDim2.new((i-1) * 0.25, (i > 1) and 3 or 0, 0, 0)
    flagButton.Text = flagKey
    flagButton.BackgroundColor3 = flagState[flagKey] and config.color or Color3.fromRGB(40, 44, 60)
    flagButton.Font = Enum.Font.GothamBold
    flagButton.TextColor3 = PREPPY_TEXT_COLOR
    flagButton.TextSize = 12
    flagButton.Parent = flagGrid
    
    local flagCorner = Instance.new("UICorner")
    flagCorner.CornerRadius = UDim.new(0, 8)
    flagCorner.Parent = flagButton
    
    local flagStroke = Instance.new("UIStroke")
    flagStroke.Color = config.color
    flagStroke.Thickness = flagState[flagKey] and 2.5 or 1.5
    flagStroke.Transparency = flagState[flagKey] and 0.2 or 0.5
    flagStroke.Parent = flagButton
    
    flagButton.MouseButton1Click:Connect(function()
        if (flagKey == "M" and flagState["N"]) or (flagKey == "N" and flagState["M"]) then
            warn("Non puoi selezionare sia Mega Neon che Neon contemporaneamente.")
            return
        end

        flagState[flagKey] = not flagState[flagKey]
        
        if flagState[flagKey] then
            flagButton.BackgroundColor3 = config.color
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 2.5,
                Transparency = 0.2
            }):Play()
        else
            flagButton.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 1.5,
                Transparency = 0.5
            }):Play()
        end
    end)
    flagButtons[flagKey] = flagButton
end

local quickLabel = Instance.new("TextLabel")
quickLabel.Size = UDim2.new(1, 0, 0, 12)
quickLabel.Position = UDim2.new(0, 0, 0, 130)
quickLabel.BackgroundTransparency = 1
quickLabel.Text = "⚡ Quick Select"
quickLabel.Font = Enum.Font.Gotham
quickLabel.TextSize = 8
quickLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.Parent = spawnPanel

local quickGrid = Instance.new("Frame")
quickGrid.Size = UDim2.new(1, 0, 0, 50)
quickGrid.Position = UDim2.new(0, 0, 0, 142)
quickGrid.BackgroundTransparency = 1
quickGrid.Parent = spawnPanel

local quickPetsData = {
    {name = "Shadow Dragon", color = Color3.fromRGB(70, 30, 90)},
    {name = "Frost Dragon", color = Color3.fromRGB(100, 180, 220)},
    {name = "Bat Dragon", color = Color3.fromRGB(180, 50, 50)},
    {name = "Giraffe", color = Color3.fromRGB(200, 150, 0)},
    {name = "Owl", color = Color3.fromRGB(150, 100, 50)},
    {name = "Parrot", color = Color3.fromRGB(255, 100, 0)}
}

for i, petInfo in ipairs(quickPetsData) do
    local row = math.floor((i-1) / 3)
    local col = (i-1) % 3
    
    local quickButton = Instance.new("TextButton")
    quickButton.Size = UDim2.new(0.31, -2, 0.48, 0)
    quickButton.Position = UDim2.new(col * 0.33, (col > 0) and 3 or 0, row * 0.5, (row > 0) and 3 or 0)
    
    quickButton.Text = petInfo.name:match("^(%w+)") or petInfo.name
    quickButton.BackgroundColor3 = petInfo.color
    quickButton.Font = Enum.Font.GothamBold
    quickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickButton.TextSize = 8
    quickButton.Parent = quickGrid
    
    local quickCorner = Instance.new("UICorner")
    quickCorner.CornerRadius = UDim.new(0, 6)
    quickCorner.Parent = quickButton
    
    quickButton.MouseButton1Click:Connect(function()
        nameInput.Text = petInfo.name
        
        if petInfo.name == "Shadow Dragon" then
            flagState.M = true; flagState.N = false; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Frost Dragon" then
            flagState.M = false; flagState.N = true; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Bat Dragon" then
            flagState.M = false; flagState.N = true; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Giraffe" then
             flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Owl" then
             flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Parrot" then
             flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        else
            flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        end
        for key, button in pairs(flagButtons) do
            local config = flagConfig[key]
            button.BackgroundColor3 = flagState[key] and config.color or Color3.fromRGB(40, 44, 60)
            local stroke = button.UIStroke
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Thickness = flagState[key] and 2.5 or 1.5,
                Transparency = flagState[key] and 0.2 or 0.5
            }):Play()
        end
    end)
end

local spawnButton = Instance.new("TextButton")
spawnButton.Size = UDim2.new(0.92, 0, 0, 30)
spawnButton.Position = UDim2.new(0.04, 0, 1, -38)
spawnButton.Text = "✨ Spawn Pet"
spawnButton.Font = Enum.Font.GothamBold
spawnButton.TextSize = 13
spawnButton.BackgroundColor3 = PREPPY_PRIMARY_COLOR
spawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnButton.Parent = mainFrame

local spawnCorner = Instance.new("UICorner")
spawnCorner.CornerRadius = UDim.new(0, 10)
spawnCorner.Parent = spawnButton

local spawnStroke = Instance.new("UIStroke")
spawnStroke.Color = Color3.fromRGB(0, 255, 255)
spawnStroke.Thickness = 2
spawnStroke.Transparency = 0.4
spawnStroke.Parent = spawnButton

spawnButton.MouseButton1Click:Connect(function()
    local petName = nameInput.Text
    if petName == "" then return end
    
    local petId = FindPetId(petName)
    if not petId then
        TweenService:Create(inputGlow, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 80, 80) }):Play()
        spawnButton.Text = "Pet Not Found!"
        task.wait(1)
        spawnButton.Text = "✨ Spawn Pet"
        return
    end
    
    TweenService:Create(inputGlow, TweenInfo.new(0.2), { Color = Color3.fromRGB(80, 255, 120) }):Play()

    local options = {
        mega_neon = flagState["M"],
        neon = flagState["N"],
        flyable = flagState["F"],
        rideable = flagState["R"],
        age = currentAgeIndex,
        trick_level = 5,
        ailments_completed = 0,
        rp_name = GenerateUniquePetName()
    }
    
    local item = CreateInventoryItem(petId, "pets", options)
    if item then
        spawnButton.Text = "✓ Spawned!"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(50, 200, 50) }):Play()
        task.wait(1.2)
        spawnButton.Text = "✨ Spawn Pet"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = PREPPY_PRIMARY_COLOR }):Play()
    else
        spawnButton.Text = "Spawn Failed!"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
        task.wait(1)
        spawnButton.Text = "✨ Spawn Pet"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = PREPPY_PRIMARY_COLOR }):Play()
    end
end)

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(0.92, 0, 1, -75)
settingsPanel.Position = UDim2.new(0.04, 0, 0, 75)
settingsPanel.BackgroundTransparency = 1
settingsPanel.Visible = false
settingsPanel.Parent = mainFrame

local deleteAllButton = Instance.new("TextButton")
deleteAllButton.Size = UDim2.new(1, 0, 0, 30)
deleteAllButton.Position = UDim2.new(0, 0, 0, 10)
deleteAllButton.Text = "🗑️ Delete All Spawned Pets"
deleteAllButton.Font = Enum.Font.GothamBold
deleteAllButton.TextSize = 11
deleteAllButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
deleteAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteAllButton.Parent = settingsPanel

local deleteAllCorner = Instance.new("UICorner")
deleteAllCorner.CornerRadius = UDim.new(0, 8)
deleteAllCorner.Parent = deleteAllButton

deleteAllButton.MouseButton1Click:Connect(function()
    local count = DeleteAllSpawnedObjects()
    deleteAllButton.Text = "✓ Deleted " .. count .. "!"
    TweenService:Create(deleteAllButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(60, 180, 60) }):Play()
    task.wait(1.5)
    deleteAllButton.Text = "🗑️ Delete All Spawned Pets"
    TweenService:Create(deleteAllButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(180, 60, 60) }):Play()
end)

local uiLocked = false
local lockButton = Instance.new("TextButton")
lockButton.Size = UDim2.new(1, 0, 0, 30)
lockButton.Position = UDim2.new(0, 0, 0, 50)
lockButton.Text = "🔓 Unlock UI Movement"
lockButton.Font = Enum.Font.GothamBold
lockButton.TextSize = 10
lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.Parent = settingsPanel
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 8)

lockButton.MouseButton1Click:Connect(function()
    uiLocked = not uiLocked
    if uiLocked then
        lockButton.Text = "🔒 Lock UI Movement"
        lockButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
    else
        lockButton.Text = "🔓 Unlock UI Movement"
        lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
    end
end)

local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Size = UDim2.new(1, 0, 0, 12)
watermarkLabel.Position = UDim2.new(0, 0, 1, -14)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.Font = Enum.Font.Gotham
watermarkLabel.TextSize = 7
watermarkLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
watermarkLabel.TextWrapped = true
watermarkLabel.Parent = mainFrame
watermarkLabel.Text = "ZetaScripts | " .. HttpService:GenerateGUID(false) 

local original_print = print
print = function(...)
    local args = {...}
    original_print(unpack(args))
end

local dragging = false
local dragStart = Vector2.new(0, 0)
local startPos = Vector2.new(0, 0)

mainFrame.InputBegan:Connect(function(input)
    if not uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        mainFrame.ZIndex = 100
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                mainFrame.ZIndex = 1
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if not uiLocked and dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

SwitchTab(activeTab)

print("ZetaScripts UI caricata con successo!")
local RouterClient = load('RouterClient')
local UIManager = load('UIManager')
local InventoryDB = load('InventoryDB')
local KindDB = load('KindDB')
local DownloadClient = load('DownloadClient')
local AnimationManager = load('AnimationManager')
local PetRigs = load('new:PetRigs')
local AilmentsClient = load('new:AilmentsClient')
local AilmentsDB = load('new:AilmentsDB')
local CharWrapperClient = load('CharWrapperClient')
local SettingsHelper = load('SettingsHelper')
local FamilyHelper = load('FamilyHelper')
local InteractionsEngine = load('InteractionsEngine')

-- Store original functions to prevent conflicts
local originalFunctions = {}

-- ==================== GLOBAL STATE ====================
local UIState = {
    currentTab = 'Spawn',
    tabFrames = {},
    tabButtons = {},
    activeTabPulseTween = nil,
    noclipEnabled = true,
    selectedPlayers = {},
    selectionMode = false,
    pulsationTweens = {},
    richestData = {},
    expandedPlayers = {},
    keybinds = {
        selectPartner = Enum.KeyCode.P,
        addRandomItem = Enum.KeyCode.R,
        startTrade = Enum.KeyCode.T,
        blockPlayer = Enum.KeyCode.B,
        toggleUI = Enum.KeyCode.F6
    },
    waitingForKeybind = nil,
    playerContainers = {},
    currentScale = 0.7,
    fakePetType = 'regular',
    RGBState = { hue = 0, speed = 0.5, enabled = true },
    spamActive = false,
    spamCoroutine = nil,
    spamSpeed = 0.01,
    currentDialogMessage = "ZetaScripts gave you: ",
    selectedToy = "",
    petSpawnState = { activeFlags = { F = false, R = false, N = false, M = false } },
    mockState = {
        active = false, trade = nil, isAddingItem = false, partnerActionPending = false,
        originalFunctions = {}, controlPanelOpen = false, tradeCompleting = false,
        scamWarningShown = true, originalDialogFunction = nil, blockedTradeRequests = {},
        tradeHistory = {}, addedTradeIds = {}, pendingTradeRequest = false,
        canShowTradeRequest = true, tradeRequestBlocked = false,
        removePartnerPetsOnConfirm = false, partnerPetsBeforeConfirm = {},
        isMockTradeDialog = false,
    },
    RefreshState = {
       autoRefreshEnabled = true, playerCache = {}, isRefreshing = false,
       lastRefreshTime = 0, REFRESH_COOLDOWN = 2,
    },
    petModelsCache = {},
    spawnedPets = {},
    equippedPet = nil,
    currentRideId = nil,
    rideAnimationTrack = nil,
    petAilmentsCache = {},
    spawnedItems = {}
}
local UIState.mockState.activeFlags = { F = false, R = false, N = false, M = false }
local UIState.mockState.tradeHistory = {}
local UIState.mockState.addedTradeIds = {}
local UIState.mockState.blockedTradeRequests = {}

-- ==================== UI CONFIGURATION ====================
local UI_CONFIG = {
    primaryColor = Color3.fromRGB(255, 182, 193), -- Rosa cipria
    secondaryColor = Color3.fromRGB(173, 216, 230), -- Azzurro cielo
    accentColor = Color3.fromRGB(147, 112, 219), -- Lavanda
    textColor = Color3.fromRGB(255, 240, 245), -- Bianco quasi trasparente
    font = Enum.Font.GothamBold,
    cornerRadius = UDim.new(0, 15),
    strokeThickness = 2.5,
    strokeColor = Color3.fromRGB(255, 105, 180), -- Rosa acceso per accenti
    backgroundColor = Color3.fromRGB(230, 220, 240), -- Colore sfondo principale preppy
    titleBarColor = Color3.fromRGB(220, 200, 230),
    tabActiveColor = Color3.fromRGB(230, 210, 230),
    tabInactiveColor = Color3.fromRGB(210, 190, 220),
    tabStrokeActive = Color3.fromRGB(255, 105, 180),
    tabStrokeInactive = Color3.fromRGB(180, 160, 190),
    watermarkText = "ZetaScripts (last4zeta on tt)",
    watermarkFont = Enum.Font.SourceSansSemibold,
    watermarkSize = 9,
    watermarkColor = Color3.fromRGB(180, 180, 220),
    footerColor = Color3.fromRGB(30, 30, 40),
    footerStrokeColor = Color3.fromRGB(170, 0, 255),
    footerStrokeThickness = 3,
    gradientColors = { Color3.fromRGB(170, 0, 255), Color3.fromRGB(120, 0, 255), Color3.fromRGB(0, 100, 255), Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 255, 150), Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 50, 150) }
}

-- ==================== FILIGRANA HARDCODED ====================
local function createHardcodedWatermark(parentFrame)
    local watermarkFrame = Instance.new("Frame")
    watermarkFrame.Size = UDim2.new(0.3, 0, 0, 18)
    watermarkFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
    watermarkFrame.BackgroundColor3 = UI_CONFIG.footerColor
    watermarkFrame.BackgroundTransparency = 0.7
    watermarkFrame.Parent = parentFrame

    local watermarkCorner = Instance.new("UICorner")
    watermarkCorner.CornerRadius = UDim.new(0, 5)
    watermarkCorner.Parent = watermarkFrame

    local watermarkStroke = Instance.new("UIStroke")
    watermarkStroke.Color = UI_CONFIG.footerStrokeColor
    watermarkStroke.Thickness = UI_CONFIG.footerStrokeThickness
    watermarkStroke.Transparency = 0.3
    watermarkStroke.Parent = watermarkFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = UI_CONFIG.watermarkText
    textLabel.Font = UI_CONFIG.watermarkFont
    textLabel.TextSize = UI_CONFIG.watermarkSize
    textLabel.TextColor3 = UI_CONFIG.watermarkColor
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.Parent = watermarkFrame
    
    return watermarkFrame
end

-- ==================== GLOBAL UTILITY FUNCTIONS ====================
local function GenerateUniquePetName()
    local prefixes = {"★", "☆", "♡", "☁️", "✨", "🍓", "🌸", "🍯", "☕", "🌙", "🌈", "❄️", "🫧", "🍬", "🍪", "🥛"}
    local names = {"Shadow", "Blaze", "Frost", "Thunder", "Moon", "Star", "Sky", "Ocean", "River", "Storm", 
                   "Ember", "Ash", "Dusk", "Dawn", "Night", "Day", "Sun", "Wind", "Rain", "Snow", "Ice", "Fire",
                   "Nova", "Cosmo", "Galaxy", "Orbit", "Comet", "Meteor", "Aurora", "Nebula", "Crystal", "Gem",
                   "Ruby", "Sapphire", "Emerald", "Diamond", "Gold", "Silver", "Mystic", "Magic", "Enchant"}
    local usePrefix = math.random(1, 3) == 1
    local name = names[math.random(1, #names)]
    if usePrefix then return prefixes[math.random(1, #prefixes)] .. name else return name .. " " .. prefixes[math.random(1, #prefixes)] end
end

local function FindInTable(array, checker)
    for index, value in pairs(array) do if checker(value, index) then return index end end return nil
end

local function UpdateClientData(dataPath, modifier)
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local currentData = ClientData.get(dataPath)
    local clonedData = table.clone(currentData)
    local result = modifier(clonedData)
    ClientData.predict(dataPath, result)
    set_thread_identity(identity)
    return result
end

local function GenerateUniqueID()
    return HttpService:GenerateGUID(false)
end

local function GetKindPet(petName)
    for id, info in pairs(InventoryDB.pets) do if info.name:lower() == petName:lower() then return id end end return nil
end

local function GetKindToy(toyName)
    for id, info in pairs(InventoryDB.toys) do if info.name:lower() == toyName:lower() then return id end end return nil
end

local function FindItemId(itemName)
    local id, category = GetKindPet(itemName)
    if id then return id, "pets" end
    id, category = GetKindToy(itemName)
    if id then return id, "toys" end
    return nil, nil
end

local function UpdatePetSpawnStateFlags(flagState)
    for flag, value in pairs(flagState) do
        UIState.petSpawnState.activeFlags[flag] = value
    end
end

-- ==================== PET SPAWNER FUNCTIONS ====================
local function EquipPet(petData)
    if petData.category ~= "pets" then return end
    if EquippedPet then UnequipPet(EquippedPet) end
    
    for _, wrapper in pairs(ClientData.get("pet_char_wrappers")) do
        if wrapper.controller == LocalPlayer then
            RouterClient.get("ToolAPI/Unequip"):InvokeServer(wrapper.pet_unique)
        end
    end

    local petModel = DownloadClient.promise_download_copy("Pets", petData.kind):expect():Clone()
    petModel.Parent = workspace
    UIState.spawnedPets[petData.unique] = { data = petData, model = petModel }
    
    local petKindData = KindDB[petData.id]
    if petKindData and (petData.properties.neon or petData.properties.mega_neon) then
        local modelInstance = petModel:FindFirstChild("PetModel")
        if modelInstance then
            for partName, partProps in pairs(petKindData.neon_parts) do
                local geoPart = PetRigs.get(modelInstance).get_geo_part(modelInstance, partName)
                if geoPart then
                    geoPart.Material = partProps.Material
                    geoPart.Color = partProps.Color
                end
            end
        end
    end

    EquippedPet = petData

    task.defer(function()
        RegisterPetWrapper({
            char = petModel, mega_neon = petData.properties.mega_neon or false, neon = petData.properties.neon or false,
            player = LocalPlayer, entity_controller = LocalPlayer, controller = LocalPlayer, rp_name = petData.properties.rp_name or "",
            pet_trick_level = petData.properties.pet_trick_level or 0, pet_unique = petData.unique, pet_id = petData.id,
            location = { full_destination_id = "housing", destination_id = "housing", house_owner = LocalPlayer },
            pet_progression = { age = petData.properties.age or math.random(1, 6), percentage = math.random(0, 99) / 100 },
            are_colors_sealed = false, is_pet = true,
        })
        RegisterPetState({
            char = petModel, player = LocalPlayer, store_key = "pet_state_managers", is_sitting = false,
            chars_connected_to_me = {}, states = {}
        })
        task.wait(0.15)
        AilmentsClient.on_ailments_changed(LocalPlayer)
    end)
end

local function UnequipPet(petData)
    local pet = UIState.spawnedPets[petData.unique]
    if not pet or not pet.model then return end

    if CurrentRideId == petData.unique then DismountPet() end

    RemovePetWrapper(petData.unique)
    RemovePetState(petData.unique)
    pet.model:Destroy()
    pet.model = nil

    if EquippedPet and EquippedPet.unique == petData.unique then EquippedPet = nil end
    UIState.petAilmentsCache[petData.unique] = nil
    task.wait(0.15)
    AilmentsClient.on_ailments_changed(LocalPlayer)
end

local function CreateInventoryItem(itemId, category, properties)
    local uniqueId = GenerateUniqueID()
    local itemKindData = KindDB[itemId]
    if not itemKindData then warn("Item not found: " .. itemId); return nil end

    properties = properties or {}
    local newnessValue = NewnessGroups[GetPropertyGroup(properties)] - 1 or 1
    NewnessGroups[GetPropertyGroup(properties)] = newnessValue

    local itemData = {
        unique = uniqueId, category = category, id = itemId, kind = itemKindData.kind,
        newness_order = newnessValue, properties = properties, _source = "blueprint.lua"
    }

    UpdateClientData("inventory", function(inv)
        inv[category][uniqueId] = itemData
        return inv
    end)

    if category == "pets" then UIState.spawnedPets[uniqueId] = { data = itemData, model = nil } end
    UIState.spawnedItems[uniqueId] = true

    task.defer(function()
        UIManager.apps.BackpackApp.refresh_rendered_items()
    end)
    return itemData
end

local function DeleteAllSpawnedPets()
    local removed = 0
    UpdateClientData("inventory", function(inv)
        if inv.pets then
            for uniqueId, _ in pairs(UIState.spawnedItems) do
                if inv.pets[uniqueId] and inv.pets[uniqueId]._source == "blueprint.lua" then
                    inv.pets[uniqueId] = nil
                    removed = removed + 1
                end
            end
        end
        return inv
    end)
    
    for uniqueId, _ in pairs(UIState.spawnedPets) do
        if UIState.spawnedPets[uniqueId] and UIState.spawnedPets[uniqueId].data and UIState.spawnedPets[uniqueId].data._source == "blueprint.lua" then
            if UIState.spawnedPets[uniqueId].model then UIState.spawnedPets[uniqueId].model:Destroy() end
        end
    end
    UIState.spawnedPets = {}
    UIState.spawnedItems = {}
    UIState.petAilmentsCache = {}
    EquippedPet = nil
    CurrentRideId = nil
    
    task.defer(function() UIManager.apps.BackpackApp.refresh_rendered_items() end)
    return removed
end

local function GetPetByName(petName)
    for id, info in pairs(InventoryDB.pets) do if info.name:lower() == petName:lower() then return id end end return nil
end

local function GetToyByName(toyName)
    for id, info in pairs(InventoryDB.toys) do if info.name:lower() == toyName:lower() then return id end end return nil
end

-- ==================== TRADE SIM FUNCTIONS ====================
local function UpdateMockState(changes)
    for k, v in pairs(changes) do
        if type(v) == "table" and type(UIState.mockState.trade[k]) == "table" then
            for tk, tv in pairs(v) do UIState.mockState.trade[k][tk] = tv end
        else
            UIState.mockState.trade[k] = v
        end
    end
    UIState.mockState.trade.offer_version = (UIState.mockState.trade.offer_version or 0) + 1
    TradeApp:_overwrite_local_trade_state(UIState.mockState.trade)
end

function TradeApp:_change_local_trade_state(changes, ...)
    local currentState = TradeApp.local_trade_state
    if currentState and currentState.trade_id then
        local isSender = currentState.sender == LocalPlayer
        local isRecipient = currentState.recipient == LocalPlayer
        if isSender and changes.sender_offer and changes.sender_offer.items then
            UIState.mockState.currentTradeItems = table.clone(changes.sender_offer.items)
        elseif isRecipient and changes.recipient_offer and changes.recipient_offer.items then
            UIState.mockState.currentTradeItems = table.clone(changes.recipient_offer.items)
        end
    end
    return TradeApp._ORIGINAL_change_local_trade_state(self, changes, ...)
end

function TradeApp._overwrite_local_trade_state(self, tradeState, ...)
    if tradeState then
        local isSender = tradeState.sender == LocalPlayer
        local isRecipient = tradeState.recipient == LocalPlayer
        if isSender and tradeState.sender_offer and UIState.mockState.currentTradeItems then
            tradeState.sender_offer.items = UIState.mockState.currentTradeItems
        elseif isRecipient and tradeState.recipient_offer and UIState.mockState.currentTradeItems then
            tradeState.recipient_offer.items = UIState.mockState.currentTradeItems
        end
    else
        UIState.mockState.currentTradeItems = nil
        if TradeApp._last_trade_id then
            UIState.mockState.tradeHistory[TradeApp._last_trade_id] = nil
            TradeApp._last_trade_id = nil
        end
    end
    return TradeApp._ORIGINAL_overwrite_local_trade_state(self, tradeState, ...)
end

local function createMockPartner(player)
    local partnerName = player and player.Name or CONFIG.PARTNER_NAME
    local partnerDisplayName = player and player.DisplayName or CONFIG.PARTNER_NAME
    local partnerUserId = player and player.UserId or CONFIG.PARTNER_USER_ID
    
    local mockPlayer = {
        Name = partnerName, DisplayName = partnerDisplayName, UserId = partnerUserId, ClassName = 'Player',
        Character = nil, Team = nil, TeamColor = BrickColor.new('White'), Neutral = true, AccountAge = 365,
        MembershipType = Enum.MembershipType.None, CharacterAdded = Instance.new('BindableEvent'),
        CharacterRemoving = Instance.new('BindableEvent'),
    }
    return setmetatable(mockPlayer, { __index = function(t, k)
        if k == 'Parent' then return Players end
        if k == 'IsA' then return function(self, className) return className == 'Player' or className == 'Instance' end end
        if k == 'GetAttribute' then return function(self, attr) return nil end end
        if k == 'FindFirstChild' then return function(self, name) return nil end end
        if k == 'WaitForChild' then return function(self, name, timeout) return nil end end
        return rawget(t, k)
    end, __tostring = function() return partnerName end, __eq = function(a, b)
        if type(b) == 'table' then return rawget(a, 'UserId') == rawget(b, 'UserId') end return false
    end})
end

local mockPartner = createMockPartner()

local function createMockTrade(realPlayer)
    local partner = realPlayer and createMockPartner(realPlayer) or mockPartner
    local hasLicense = true
    if realPlayer then hasLicense = checkTradeLicense(realPlayer) end
    return {
        trade_id = 'MOCK_' .. tick(), sender = LocalPlayer, recipient = partner,
        sender_offer = { items = {}, player_name = LocalPlayer.Name, negotiated = false, confirmed = false },
        recipient_offer = { items = {}, player_name = CONFIG.PARTNER_NAME, negotiated = false, confirmed = false },
        current_stage = 'negotiation', offer_version = 1,
        sender_has_trade_license = true, recipient_has_trade_license = hasLicense,
        busy_indicators = {}, subscriber_count = CONFIG.SPECTATOR_COUNT,
    }
end

local function startMockTradeDirectly()
    if UIState.mockState.active or UIState.mockState.pendingTradeRequest then return end
    
    pcall(function()
        UIState.mockState.active = false; UIState.mockState.trade = nil; UIState.mockState.isAddingItem = false;
        UIState.mockState.partnerActionPending = false; UIState.mockState.tradeCompleting = false;
        UIState.mockState.scamWarningShown = true; UIState.mockState.tradeRequestBlocked = true;
        UIState.mockState.blockedTradeRequests = {}; UIState.mockState.pendingTradeRequest = false;
        
        UIState.mockState.trade = createMockTrade()
        UIState.mockState.active = true
        UIManager.set_app_visibility('TradeApp', false); task.wait(0.05)
        TradeApp:_overwrite_local_trade_state(UIState.mockState.trade)
        task.wait(0.05)
        UIManager.set_app_visibility('TradeApp', true)
        FriendHighlight(true)
        if TradeApp._show_intro_message then TradeApp:_show_intro_message() end
        task.wait(0.05)
        if TradeApp.refresh_all then TradeApp:refresh_all(); FriendHighlight(true) end
    end)
end

local function BlockPlayer(player)
    pcall(function()
        setthreadidentity(8)
        StarterGui:SetCore('PromptBlockPlayer', player)
        repeat task.wait() until GuiService:FindFirstChild('BlockingModalScreen')
        local modalScreen = GuiService:FindFirstChild('BlockingModalScreen')
        if modalScreen then
            local container = modalScreen.BlockingModalContainer.BlockingModalContainerWrapper.BlockingModal
            container.BackgroundTransparency = 1
            container.BlockingModalContainerWrapper.BackgroundTransparency = 1
            container.BlockingModalContainerWrapper.BlockingModal.BackgroundTransparency = 1
            local btn = container.BlockingModalContainerWrapper.BlockingModal.AlertModal.Footer.Buttons['3']
            if btn then
                GuiService.SelectedObject = btn
                task.wait()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, GuiService)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, GuiService)
                task.wait()
                GuiService.SelectedObject = nil
            end
        end
        setthreadidentity(2)
    end)
end

local function sendTradeChatMessage(message)
    if not UIState.mockState.active or not UIState.mockState.trade then return false end
    if TradeApp and TradeApp._render_message_in_trade_chat then
        TradeApp:_render_message_in_trade_chat(nil, string.format('%s: %s', mockPartner.Name, message), true)
        return true
    end
    return false
end

local function showTradeRequest()
    if UIState.mockState.pendingTradeRequest or UIState.mockState.active then return end
    UIState.mockState.pendingTradeRequest = true
    UIState.mockState.canShowTradeRequest = false
    task.wait(CONFIG.TRADE_REQUEST_DELAY)
    if not UIState.mockState.pendingTradeRequest or UIState.mockState.active then
        UIState.mockState.pendingTradeRequest = false
        UIState.mockState.canShowTradeRequest = true
        return
    end
    
    local name = CONFIG.PARTNER_NAME
    local trade_request_table_friend = {
        text = name .. " sent you a trade request", left = "Decline", right = "Accept",
        header = { text = "Verified Friend", icon = 'rbxassetid://84667805159408' },
        tooltip_options = { force_display_post_trade_values = true }, yields = true
    }
    local trade_request_table_not_friend = { text = name .. " sent you a trade request", left = "Decline", right = "Accept", yields = true }
    
    UIState.mockState.isMockTradeDialog = true
    local dialogResult
    pcall(function()
        if UIState.mockState.originalDialogFunction then
            dialogResult = UIState.mockState.originalDialogFunction(DialogApp, CONFIG.FRIEND_PARTNER and trade_request_table_friend or trade_request_table_not_friend)
        else
            dialogResult = DialogApp:dialog(CONFIG.FRIEND_PARTNER and trade_request_table_friend or trade_request_table_not_friend)
        end
    end)
    UIState.mockState.isMockTradeDialog = false
    UIState.mockState.pendingTradeRequest = false
    
    if dialogResult == "Accept" or dialogResult == "right" then
        startMockTradeDirectly()
    else
        UIState.mockState.canShowTradeRequest = true
    end
end

local function hookTradeRequestEvent()
    local tradeRequestEvent = RouterClient.get_event('TradeAPI/TradeRequestReceived')
    if tradeRequestEvent then
        local originalConnections = getconnections(tradeRequestEvent.OnClientEvent)
        for _, connection in pairs(originalConnections) do connection:Disable() end
        tradeRequestEvent.OnClientEvent:Connect(function(requestingPlayer)
            if UIState.mockState.active or UIState.mockState.tradeRequestBlocked then
                table.insert(UIState.mockState.blockedTradeRequests, { player = requestingPlayer, timestamp = tick() })
                return
            end
            for _, connection in pairs(originalConnections) do if connection.Function then connection.Function(requestingPlayer) end end
        end)
    end
end

local function hookDialogApp()
    if not DialogApp or not DialogApp.dialog then return end
    UIState.mockState.originalDialogFunction = DialogApp.dialog
    DialogApp.dialog = function(self, dialogData)
        if dialogData and dialogData.text and string.find(dialogData.text, 'has expired!') then return 'Okay' end
        if UIState.mockState.isMockTradeDialog then return UIState.mockState.originalDialogFunction(self, dialogData) end
        if dialogData and dialogData.header and type(dialogData.header) == 'table' and dialogData.header.text == 'Verified Friend' then return UIState.mockState.originalDialogFunction(self, dialogData) end
        if dialogData and dialogData.handle == 'trade_request' then
            if UIState.mockState.pendingTradeRequest or UIState.mockState.active or UIState.mockState.tradeRequestBlocked then return 'Decline' end
        end
        return UIState.mockState.originalDialogFunction(self, dialogData)
    end
end

local function showBlockedTradeRequests()
    if #UIState.mockState.blockedTradeRequests > 0 then
        task.wait(0.5)
        local TradeExcluder = load('TradeExcluder')
        for _, request in ipairs(UIState.mockState.blockedTradeRequests) do
            local requestingPlayer = request.player
            if TradeExcluder and TradeExcluder.is_player_excluded(requestingPlayer) then
                RouterClient.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(requestingPlayer, false)
            else
                if DialogApp and UIState.mockState.originalDialogFunction then
                    local response = UIState.mockState.originalDialogFunction(DialogApp, {
                        text = string.format('%s sent you a trade request', requestingPlayer.Name),
                        left = 'Decline', right = 'Accept', handle = 'trade_request',
                    })
                    if response == 'Accept' then
                        local shouldAccept = true
                        if TradeApp._confirm_player_if_suspicious then shouldAccept = TradeApp:_confirm_player_if_suspicious(requestingPlayer) end
                        if shouldAccept and not TradeApp:check_and_warn_if_trading_restricted() then TradeApp:show_scam_warning() end
                        RouterClient.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(requestingPlayer, shouldAccept)
                    else
                        RouterClient.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(requestingPlayer, false)
                    end
                end
            end
        end
        UIState.mockState.blockedTradeRequests = {}
    end
end

-- ==================== TOOLS FUNCTIONS ====================
local function GetPetValue(petKind, petProps)
    local displayName = petDisplayNames[petKind] or petKind
    local petData = petsByName[displayName]
    if not petData then return 0 end
    local baseKey = petProps.mega_neon and "mvalue" or (petProps.neon and "nvalue" or "rvalue")
    local suffix = ""
    if petProps.rideable and petProps.flyable then suffix = " - fly&ride"
    elseif petProps.rideable then suffix = " - ride"
    elseif petProps.flyable then suffix = " - fly" else suffix = " - nopotion" end
    local key = baseKey .. suffix
    return petData[key] or petData[baseKey] or 0
end

local function FormatValue(value)
    if value >= 1e9 then return string.format("%.2fB", value / 1e9)
    elseif value >= 1e6 then return string.format("%.2fM", value / 1e6)
    elseif value >= 1e3 then return string.format("%.1fK", value / 1e3)
    elseif value >= 100 then return string.format("%.0f", value) else return string.format("%.1f", value) end
end

local function CreateRichestPlayerButton(playerData, index)
    local container = Instance.new('Frame')
    container.Size, container.BackgroundColor3, container.BackgroundTransparency, container.LayoutOrder, container.Name = UDim2.new(1, -8, 0, 32), Color3.fromRGB(35, 35, 50), 0.1, index, 'RichestPlayer_' .. playerData.playerName
    container.ClipsDescendants, container.Parent = true, richestListFrame
    Instance.new('UICorner', container).CornerRadius = UDim.new(0, 8)
    
    local gradient = Instance.new('UIGradient')
    gradient.Color, gradient.Rotation = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 45, 65)), ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 32, 48)) }), 90
    gradient.Parent = container
    
    local stroke = Instance.new('UIStroke')
    stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, container

    local rankColors = { [1] = Color3.fromRGB(255, 215, 0), [2] = Color3.fromRGB(192, 192, 192), [3] = Color3.fromRGB(205, 127, 50) }
    local rankBadge = Instance.new('TextLabel')
    rankBadge.Size, rankBadge.Position, rankBadge.BackgroundColor3, rankBadge.BackgroundTransparency, rankBadge.Text = UDim2.new(0, 22, 0, 22), UDim2.new(0, 5, 0, 5), rankColors[index] or Color3.fromRGB(70, 70, 90), 0.2, tostring(index)
    rankBadge.Font, rankBadge.TextSize, rankBadge.TextColor3, rankBadge.Parent = Enum.Font.GothamBlack, 11, Color3.fromRGB(255, 255, 255), container
    Instance.new('UICorner', rankBadge).CornerRadius = UDim.new(0, 11)

    local tradeButton = Instance.new('TextButton')
    tradeButton.Size, tradeButton.Position, tradeButton.BackgroundColor3, tradeButton.BackgroundTransparency, tradeButton.Text = UDim2.new(0, 32, 0, 22), UDim2.new(1, -74, 0, 5), Color3.fromRGB(50, 130, 100), 0.1, '?'
    tradeButton.Font, tradeButton.TextSize, tradeButton.TextColor3, tradeButton.Parent = Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), container
    Instance.new('UICorner', tradeButton).CornerRadius = UDim.new(0, 6)

    local profileButton = Instance.new('TextButton')
    profileButton.Size, profileButton.Position, profileButton.BackgroundColor3, profileButton.BackgroundTransparency, profileButton.Text = UDim2.new(0, 32, 0, 22), UDim2.new(1, -38, 0, 5), Color3.fromRGB(100, 70, 150), 0.1, '?'
    profileButton.Font, profileButton.TextSize, profileButton.TextColor3, profileButton.Parent = Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), container
    Instance.new('UICorner', profileButton).CornerRadius = UDim.new(0, 6)

    local mainButton = Instance.new('TextButton')
    mainButton.Size, mainButton.Position, mainButton.BackgroundTransparency, mainButton.Text, mainButton.Parent = UDim2.new(1, -110, 0, 32), UDim2.new(0, 30, 0, 0), 1, '', container

    local nameLabel = Instance.new('TextLabel')
    nameLabel.Size, nameLabel.Position, nameLabel.BackgroundTransparency, nameLabel.Text, nameLabel.Font, nameLabel.TextSize, nameLabel.TextColor3, nameLabel.TextXAlignment, nameLabel.TextTruncate, nameLabel.Parent = UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 0, 0, 0), 1, playerData.playerName, Enum.Font.GothamBold, 10, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd, mainButton

    local valueLabel = Instance.new('TextLabel')
    valueLabel.Size, valueLabel.Position, valueLabel.BackgroundTransparency, valueLabel.Text, valueLabel.Font, valueLabel.TextSize, valueLabel.TextColor3, valueLabel.TextXAlignment, valueLabel.Parent = UDim2.new(0.45, 0, 1, 0), UDim2.new(0.55, 0, 0, 0), 1, FormatValue(playerData.totalValue), Enum.Font.GothamBold, 10, Color3.fromRGB(120, 255, 120), Enum.TextXAlignment.Right, mainButton

    local petsSection = Instance.new('Frame')
    petsSection.Size, petsSection.Position, petsSection.BackgroundColor3, petsSection.BackgroundTransparency, petsSection.Visible, petsSection.Name, petsSection.Parent = UDim2.new(1, -8, 0, 0), UDim2.new(0, 4, 0, 34), Color3.fromRGB(30, 30, 45), 0.3, false, 'PetsSection', container
    Instance.new('UICorner', petsSection).CornerRadius = UDim.new(0, 6)

    local petsLayout = Instance.new('UIListLayout')
    petsLayout.SortOrder, petsLayout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 2)
    petsLayout.Parent = petsSection

    local petsPadding = Instance.new('UIPadding')
    petsPadding.PaddingTop, petsPadding.PaddingBottom, petsPadding.PaddingLeft, petsPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 6), UDim.new(0, 6)
    petsPadding.Parent = petsSection
    
    local isExpanded = false
    local expandId = 0

    mainButton.MouseButton1Click:Connect(function()
        if isExpanded then
            isExpanded, petsSection.Visible, petsSection.Size, container.Size = false, false, UDim2.new(1, -8, 0, 0), UDim2.new(1, -8, 0, 32)
        else
            isExpanded, expandId = true, expandId + 1
            local currentExpandId = expandId
            
            for _, child in ipairs(petsSection:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
            local petsHeight = 0
            if playerData.pets and #playerData.pets > 0 then
                local sortedPets = table.clone(playerData.pets)
                table.sort(sortedPets, function(a, b) return a.value > b.value end)
                local displayCount = math.min(#sortedPets, 8)
                for i = 1, displayCount do
                    local pet = sortedPets[i]
                    local prefix = (pet.isMega and "M " or "") .. (pet.isNeon and "N " or "") .. (pet.isFly and "F" or "") .. (pet.isRide and "R" or "")
                    if prefix ~= "" then prefix = "[" .. prefix:gsub("%s+$", "") .. "] " end
                    
                    local petLabel = Instance.new('TextLabel')
                    petLabel.Size, petLabel.Position, petLabel.BackgroundTransparency, petLabel.Text, petLabel.Font, petLabel.TextSize, petLabel.TextColor3, petLabel.LayoutOrder, petLabel.Parent = UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 0), 1, prefix .. pet.displayName .. ' - ' .. FormatValue(pet.value), Enum.Font.SourceSans, 9, pet.isMega and Color3.fromRGB(170, 100, 255) or (pet.isNeon and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(200, 200, 200)), i, petsSection
                end
                if #sortedPets > 8 then
                    local moreLabel = Instance.new('TextLabel')
                    moreLabel.Size, moreLabel.Position, moreLabel.BackgroundTransparency, moreLabel.Text, moreLabel.Font, moreLabel.TextSize, moreLabel.TextColor3, moreLabel.LayoutOrder, moreLabel.Parent = UDim2.new(1, 0, 0, 12), UDim2.new(0, 0, 0, 0), 1, '... and ' .. (#sortedPets - 8) .. ' more pets', Enum.Font.SourceSansItalic, 8, Color3.fromRGB(150, 150, 150), 999, petsSection
                end
                petsHeight = (#sortedPets > 8 and (#sortedPets * 16) + 14 + 10 or (#sortedPets * 16) + 10)
            else
                local noPetsLabel = Instance.new('TextLabel')
                noPetsLabel.Size, noPetsLabel.Position, noPetsLabel.BackgroundTransparency, noPetsLabel.Text, noPetsLabel.Font, noPetsLabel.TextSize, noPetsLabel.TextColor3, noPetsLabel.Parent = UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 0), 1, 'No pets listed in profile', Enum.Font.SourceSansItalic, 9, Color3.fromRGB(150, 150, 150), petsSection
                petsHeight = 22
            end
            petsSection.Size, petsSection.Visible = UDim2.new(1, -8, 0, petsHeight), true
            container.Size = UDim2.new(1, -8, 0, 36 + petsHeight)
            
            task.spawn(function() -- Auto-close pets section
                task.wait(10)
                if isExpanded and expandId == currentExpandId then
                    isExpanded, petsSection.Visible, petsSection.Size, container.Size = false, false, UDim2.new(1, -8, 0, 0), UDim2.new(1, -8, 0, 32)
                end
            end)
        end
        
        local totalHeight = 8
        for _, child in ipairs(richestListFrame:GetChildren()) do if child:IsA('Frame') then totalHeight = totalHeight + child.AbsoluteSize.Y + 3 end end
        richestListFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end)

    tradeButton.MouseEnter:Connect(function() TweenService:Create(tradeButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 160, 120) }):Play() end)
    tradeButton.MouseLeave:Connect(function() TweenService:Create(tradeButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(50, 130, 100) }):Play() end)
    tradeButton.MouseButton1Click:Connect(function()
        local targetPlayer = Players:FindFirstChild(playerData.playerName)
        if targetPlayer then sendTradeToPlayer(targetPlayer)
        else for _, player in ipairs(Players:GetPlayers()) do if player.Name == playerData.playerName then sendTradeToPlayer(player) return end end
            if HintApp then HintApp:hint({ text = playerData.playerName .. ' not found.', length = 3, overridable = true }) end
        end
    end)

    profileButton.MouseEnter:Connect(function() TweenService:Create(profileButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(130, 90, 180) }):Play() end)
    profileButton.MouseLeave:Connect(function() TweenService:Create(profileButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 70, 150) }):Play() end)
    profileButton.MouseButton1Click:Connect(function()
        local targetPlayer = Players:FindFirstChild(playerData.playerName)
        if targetPlayer then pcall(OpenProfile, targetPlayer.UserId)
        else for _, player in ipairs(Players:GetPlayers()) do if player.Name == playerData.playerName then pcall(OpenProfile, player.UserId) return end end
            if HintApp then HintApp:hint({ text = playerData.playerName .. ' not found.', length = 3, overridable = true }) end
        end
    end)
    
    return container
end

local function refreshRichestPlayers(forceRefresh)
    if RefreshState.isRefreshing then return end
    local currentTime = tick()
    if not forceRefresh and (currentTime - RefreshState.lastRefreshTime) < RefreshState.REFRESH_COOLDOWN then return end
    
    RefreshState.isRefreshing = true
    RefreshState.lastRefreshTime = currentTime
    
    local currentPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then currentPlayers[player.Name] = player end
    end
    
    local existingNames = {}
    for _, child in ipairs(richestListFrame:GetChildren()) do
        if child:IsA('Frame') and child.Name:sub(1, 14) == 'RichestPlayer_' then existingNames[child.Name:sub(15)] = true end
    end
    
    for playerName in pairs(existingNames) do
        if not currentPlayers[playerName] then
            local container = richestListFrame:FindFirstChild('RichestPlayer_' .. playerName)
            if container then container:Destroy() end
            RefreshState.playerContainers[playerName] = nil
            for i, data in ipairs(richestData) do if data.playerName == playerName then table.remove(richestData, i) break end end
        end
    end
    
    if forceRefresh then
        for _, child in ipairs(richestListFrame:GetChildren()) do if child:IsA('Frame') then child:Destroy() end end
        UIState.expandedPlayers = {}
        richestData = {}
        RefreshState.playerContainers = {}
        existingNames = {}
        local loadingLabel = Instance.new('TextLabel')
        loadingLabel.Size, loadingLabel.Position, loadingLabel.BackgroundTransparency, loadingLabel.Text, loadingLabel.Font, loadingLabel.TextSize, loadingLabel.TextColor3, loadingLabel.LayoutOrder, loadingLabel.Parent = UDim2.new(1, -8, 0, 30), UDim2.new(0, 4, 0, 4), 1, '? Scanning players...', Enum.Font.FredokaOne, 11, Color3.fromRGB(200, 200, 200), 0, richestListFrame
    end
    
    task.spawn(function()
        local playersToFetch = {}
        for playerName, player in pairs(currentPlayers) do
            if forceRefresh or not existingNames[playerName] then table.insert(playersToFetch, player) end
        end
        
        for _, player in ipairs(playersToFetch) do
            local success, profileData = pcall(function() return fetchProfile:InvokeServer(player.UserId) end)
            local totalValue = 0
            local allPets = {}
            if success and profileData then
                local processedData = processRawProfileData(profileData)
                allPets = extractAllPets(processedData)
                for _, pet in ipairs(allPets) do totalValue = totalValue + pet.value end
            end
            local playerData = { playerName = player.Name, totalValue = totalValue, pets = allPets, player = player }
            RefreshState.playerCache[player.Name] = { totalValue = totalValue, pets = allPets, player = player, lastUpdated = tick() }
            table.insert(richestData, playerData)
        end
        
        local loadingLabel = richestListFrame:FindFirstChild('LoadingLabel')
        if loadingLabel then loadingLabel:Destroy() end
        table.sort(richestData, function(a, b) return a.totalValue > b.totalValue end)
        
        local displayCount = math.min(#richestData, 35)
        for i = 1, displayCount do
            local data = richestData[i]
            local existingContainer = richestListFrame:FindFirstChild('RichestPlayer_' .. data.playerName)
            if not existingContainer then
                createRichestPlayerButton(data, i)
                RefreshState.playerContainers[data.playerName] = true
            else
                existingContainer.LayoutOrder = i
                local rankBadge = existingContainer:FindFirstChildOfClass('TextLabel')
                if rankBadge and rankBadge.Size == UDim2.new(0, 20, 0, 20) then
                    rankBadge.Text = tostring(i)
                    rankBadge.BackgroundColor3 = rankColors[i] or Color3.fromRGB(80, 80, 100)
                end
            end
        end
        
        for i = displayCount + 1, #richestData do
            local data = richestData[i]
            local container = richestListFrame:FindFirstChild('RichestPlayer_' .. data.playerName)
            if container then container:Destroy() end
        end
        
        local totalHeight = 8
        for _, child in ipairs(richestListFrame:GetChildren()) do if child:IsA('Frame') then totalHeight = totalHeight + child.AbsoluteSize.Y + 3 end end
        richestListFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        
        if forceRefresh and HintApp then HintApp:hint({ text = 'Updated ' .. #richestData .. ' players!', length = 2, overridable = true }) end
        RefreshState.isRefreshing = false
    end)
end

local function autoRefreshCheck()
    if not RefreshState.autoRefreshEnabled then return end
    refreshRichestPlayers(false)
end

task.spawn(function() while true do task.wait(5) autoRefreshCheck() end end)

local function createPlayerButton(player, index, isSelected)
    local button = Instance.new('TextButton')
    button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.LayoutOrder, button.Parent = UDim2.new(1, -8, 0, 32), isSelected and Color3.fromRGB(50, 80, 100) or Color3.fromRGB(40, 40, 50), 0.2, '', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), index, playerListFrame
    Instance.new('UICorner', button).CornerRadius = UDim.new(0, 4)
    local buttonStroke = Instance.new('UIStroke')
    buttonStroke.ApplyStrokeMode, buttonStroke.Color, buttonStroke.Thickness, buttonStroke.Parent = Enum.ApplyStrokeMode.Border, isSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80), 1.0, button

    local nameLabel = Instance.new('TextLabel')
    nameLabel.Size, nameLabel.Position, nameLabel.BackgroundTransparency, nameLabel.Text, nameLabel.Font, nameLabel.TextSize, nameLabel.TextColor3, nameLabel.TextXAlignment, nameLabel.Parent = UDim2.new(1, -30, 1, 0), UDim2.new(0, 4, 0, 0), 1, player.Name, Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left, button

    local checkBox = Instance.new('Frame')
    checkBox.Size, checkBox.Position, checkBox.BackgroundColor3, checkBox.BackgroundTransparency, checkBox.Visible, checkBox.Parent = UDim2.new(0, 20, 0, 20), UDim2.new(1, -25, 0.5, -10), isSelected and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70), 0.2, UIState.selectionMode, button
    Instance.new('UICorner', checkBox).CornerRadius = UDim.new(0, 4)
    local checkBoxStroke = Instance.new('UIStroke')
    checkBoxStroke.ApplyStrokeMode, checkBoxStroke.Color, checkBoxStroke.Thickness, checkBoxStroke.Parent = Enum.ApplyStrokeMode.Border, isSelected and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80), 1.0, checkBox

    local checkMark = Instance.new('TextLabel')
    checkMark.Size, checkMark.Position, checkMark.BackgroundTransparency, checkMark.Text, checkMark.Font, checkMark.TextSize, checkMark.TextColor3, checkMark.Visible, checkMark.Parent = UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 1, '?', Enum.Font.FredokaOne, 14, Color3.fromRGB(255, 255, 255), isSelected, checkBox

    button.MouseButton1Click:Connect(function()
        if UIState.selectionMode then
            local isNowSelected = not UIState.selectedPlayers[player.Name]
            UIState.selectedPlayers[player.Name] = isNowSelected
            checkBox.BackgroundColor3 = isNowSelected and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
            checkBoxStroke.Color = isNowSelected and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
            checkMark.Visible = isNowSelected
            button.BackgroundColor3 = isNowSelected and Color3.fromRGB(50, 80, 100) or Color3.fromRGB(40, 40, 50)
            buttonStroke.Color = isNowSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80)
        else
            setActiveTab('Control')
            partnerBox.Text = player.Name
            updatePartnerFromUsername(player.Name)
        end
    end)
    return button, checkBox
end

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA('TextButton') and child.Name ~= 'SelectFromTradeButton' then child:Destroy() end
    end
    UIState.playerListButtons = {}

    local searchText = playerSearchBox.Text:lower()
    local filteredPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if searchText == '' or player.Name:lower():sub(1, #searchText) == searchText then
            table.insert(filteredPlayers, player)
        end
    end
    table.sort(filteredPlayers, function(a, b) return a.Name:lower() < b.Name:lower() end)

    for i, player in ipairs(filteredPlayers) do
        local isSelected = UIState.selectedPlayers[player.Name] == true
        local button, checkBox = createPlayerButton(player, i, isSelected)
        table.insert(UIState.playerListButtons, { button = button, checkbox = checkBox })
    end
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, (#filteredPlayers * 36) + 40)
end

--==================== Main UI ====================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 300)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
mainFrame.BackgroundColor3 = UI_CONFIG.backgroundColor
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale", mainFrame)
uiScale.Scale = UIState.currentScale

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UI_CONFIG.cornerRadius
mainCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = UI_CONFIG.strokeThickness
uiStroke.Color = UI_CONFIG.strokeColor
uiStroke.Parent = mainFrame

local colorGradient = Instance.new("UIGradient")
colorGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, UI_CONFIG.gradientColors[1]), ColorSequenceKeypoint.new(1, UI_CONFIG.gradientColors[2]) })
colorGradient.Rotation = 90
colorGradient.Parent = uiStroke

local colorIdx = 1
task.spawn(function()
    while true do
        colorIdx = colorIdx % #UI_CONFIG.gradientColors + 1
        local nextIdx = colorIdx % #UI_CONFIG.gradientColors + 1
        TweenService:Create(colorGradient, TweenInfo.new(4, Enum.EasingStyle.Linear), {
            Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, UI_CONFIG.gradientColors[colorIdx]), ColorSequenceKeypoint.new(1, UI_CONFIG.gradientColors[nextIdx]) })
        }):Play()
        task.wait(4)
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Text = "✨ ZetaScripts Suite ✨"
title.Font = UI_CONFIG.font
title.TextSize = 12
title.TextColor3 = UI_CONFIG.textColor
title.Parent = mainFrame

local tabContainer = Instance.new('Frame')
tabContainer.Size = UDim2.new(0.94, 0, 0, 25)
tabContainer.Position = UDim2.new(0.03, 0, 0, 26)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {
    { key = 'Spawn', label = 'Pet Spawner', icon = '🐾' },
    { key = 'Trade Sim', label = 'Trade Sim', icon = '🤝' },
    { key = 'Tools / Dialog', label = 'Tools / Dialog', icon = '🔧' }
}

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new('TextButton')
    tabButton.Size = UDim2.new(1 / #tabs - 0.02, 0, 1, 0)
    tabButton.Position = UDim2.new((i - 1) * (1 / #tabs), (i > 1) and 4 or 0, 0, 0)
    tabButton.BackgroundColor3 = i == 1 and UI_CONFIG.tabActiveColor or UI_CONFIG.tabInactiveColor
    tabButton.Text = tab.icon .. " " .. tab.label
    tabButton.Font = UI_CONFIG.font
    tabButton.TextSize = 10
    tabButton.TextColor3 = UI_CONFIG.textColor
    tabButton.Parent = tabContainer
    
    Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 8)
    
    local tabStroke = Instance.new("UIStroke")
    tabStroke.Color = i == 1 and UI_CONFIG.tabStrokeActive or UI_CONFIG.tabStrokeInactive
    tabStroke.Thickness = i == 1 and 3 or 1.5
    tabStroke.Parent = tabButton
    
    UIState.tabButtons[tab.key] = { button = tabButton, stroke = tabStroke }
    
    tabButton.MouseButton1Click:Connect(function() SwitchTab(tab.key) end)
end

local function SwitchTab(tabName)
    UIState.currentTab = tabName
    for name, data in pairs(UIState.tabButtons) do
        local isActive = name == tabName
        TweenService:Create(data.button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = isActive and UI_CONFIG.tabActiveColor or UI_CONFIG.tabInactiveColor
        }):Play()
        TweenService:Create(data.stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = isActive and UI_CONFIG.tabStrokeActive or UI_CONFIG.tabStrokeInactive,
            Thickness = isActive and 3 or 1.5
        }):Play()
        data.button.ZIndex = isActive and 2 or 1
    end
    
    for name, frame in pairs(UIState.tabFrames) do frame.Visible = name == tabName end
end

local spawnPanel = Instance.new("Frame")
spawnPanel.Size = UDim2.new(0.94, 0, 1, -55)
spawnPanel.Position = UDim2.new(0.03, 0, 0, 50)
spawnPanel.BackgroundTransparency = 1
spawnPanel.Visible = true
spawnPanel.Parent = mainFrame

local tradeSimPanel = Instance.new("Frame")
tradeSimPanel.Size = UDim2.new(0.94, 0, 1, -55)
tradeSimPanel.Position = UDim2.new(0.03, 0, 0, 50)
tradeSimPanel.BackgroundTransparency = 1
tradeSimPanel.Visible = false
tradeSimPanel.Parent = mainFrame

local toolsPanel = Instance.new("Frame")
toolsPanel.Size = UDim2.new(0.94, 0, 1, -55)
toolsPanel.Position = UDim2.new(0.03, 0, 0, 50)
toolsPanel.BackgroundTransparency = 1
toolsPanel.Visible = false
toolsPanel.Parent = mainFrame

UIState.tabFrames['Pet Spawner'] = spawnPanel
UIState.tabFrames['Trade Sim'] = tradeSimPanel
UIState.tabFrames['Tools / Dialog'] = toolsPanel

-- Create the hardcoded watermark
createHardcodedWatermark(mainFrame)

--==================== SPAWNER TAB CONTENT ====================
local function setupSpawnerTab()
    local petNameLabel = Instance.new("TextLabel")
    petNameLabel.Size, petNameLabel.Position, petNameLabel.BackgroundTransparency, petNameLabel.Text = UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, 0), 1, "🐾 Pet Name"
    petNameLabel.Font, petNameLabel.TextSize, petNameLabel.TextColor3, petNameLabel.TextXAlignment = Enum.Font.Gotham, 8, Color3.fromRGB(160, 170, 200), Enum.TextXAlignment.Left
    petNameLabel.Parent = spawnPanel

    local nameInput = Instance.new("TextBox")
    nameInput.Size, nameInput.Position, nameInput.BackgroundColor3, nameInput.TextColor3, nameInput.TextSize, nameInput.Font, nameInput.PlaceholderText, nameInput.PlaceholderColor3, nameInput.ClearTextOnFocus = UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 11), Color3.fromRGB(32, 36, 58), Color3.fromRGB(240, 240, 255), 11, Enum.Font.Gotham, "Enter pet name...", Color3.fromRGB(140, 150, 180), false
    nameInput.Text = "Bat Dragon"
    nameInput.Parent = spawnPanel

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = nameInput

    local glowColors = { neutral = Color3.fromRGB(220, 220, 255), valid = Color3.fromRGB(120, 255, 150), invalid = Color3.fromRGB(255, 120, 120) }
    local inputGlow = Instance.new("UIStroke")
    inputGlow.ApplyStrokeMode, inputGlow.Color, inputGlow.Thickness, inputGlow.Parent = Enum.ApplyStrokeMode.Border, glowColors.neutral, 2, nameInput

    local ageLabel = Instance.new("TextLabel")
    ageLabel.Size, ageLabel.Position, ageLabel.BackgroundTransparency, ageLabel.Text = UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, 38), 1, "📅 Age"
    ageLabel.Font, ageLabel.TextSize, ageLabel.TextColor3, ageLabel.TextXAlignment = Enum.Font.Gotham, 8, Color3.fromRGB(160, 170, 200), Enum.TextXAlignment.Left
    ageLabel.Parent = spawnPanel

    local ageGrid = Instance.new("Frame")
    ageGrid.Size, ageGrid.Position, ageGrid.BackgroundTransparency, ageGrid.Parent = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 49), 1, spawnPanel

    local ageCodes = {"N", "J", "P", "T", "P", "F"}
    local ageDescriptions = {"Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown"}
    local currentAge = 1

    for i, code in ipairs(ageCodes) do
        local ageButton = Instance.new("TextButton")
        ageButton.Size, ageButton.Position, ageButton.BackgroundColor3, ageButton.Text, ageButton.Font, ageButton.TextColor3, ageButton.TextSize, ageButton.Parent = UDim2.new(1/6 - 0.01, 0, 1, 0), UDim2.new((i-1) * (1/6), (i > 1) and 2 or 0, 0, 0), i == 1 and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(40, 44, 66), code, Enum.Font.GothamBold, Color3.fromRGB(240, 240, 255), 11, ageGrid
        Instance.new("UICorner", ageButton).CornerRadius = UDim.new(0, 6)
        
        local hintBox = Instance.new("TextLabel")
        hintBox.Text, hintBox.BackgroundColor3, hintBox.TextColor3, hintBox.TextSize, hintBox.Font, hintBox.Size, hintBox.Visible, hintBox.Parent = ageDescriptions[i], Color3.fromRGB(22, 26, 40), Color3.fromRGB(255, 255, 255), 7, Enum.Font.Gotham, UDim2.new(0, 0, 0, 0), false, ageButton
        Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 4)
        
        ageButton.MouseEnter:Connect(function() hintBox.Size, hintBox.Position, hintBox.Visible = UDim2.new(0, 65, 0, 15), UDim2.new(0, 0, -1.2, 0), true end)
        ageButton.MouseLeave:Connect(function() hintBox.Visible = false end)
        ageButton.MouseButton1Click:Connect(function()
            currentAge = i
            for _, btn in pairs(ageGrid:GetChildren()) do if btn:IsA("TextButton") then btn.BackgroundColor3 = Color3.fromRGB(40, 44, 66) end end
            ageButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        end)
    end

    local flagLabel = Instance.new("TextLabel")
    flagLabel.Size, flagLabel.Position, flagLabel.BackgroundTransparency, flagLabel.Text = UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, 74), 1, "✨ Pet Flags"
    flagLabel.Font, flagLabel.TextSize, flagLabel.TextColor3, flagLabel.TextXAlignment = Enum.Font.Gotham, 8, Color3.fromRGB(160, 170, 200), Enum.TextXAlignment.Left
    flagLabel.Parent = spawnPanel

    local flagGrid = Instance.new("Frame")
    flagGrid.Size, flagGrid.Position, flagGrid.BackgroundTransparency, flagGrid.Parent = UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 85), 1, spawnPanel

    local flagColors = { M = Color3.fromRGB(170, 0, 255), N = Color3.fromRGB(0, 255, 100), F = Color3.fromRGB(0, 200, 255), R = Color3.fromRGB(255, 50, 150) }
    local flagOrder = {"M", "N", "F", "R"}
    
    for i, flag in ipairs(flagOrder) do
        local flagButton = Instance.new("TextButton")
        flagButton.Size, flagButton.Position, flagButton.BackgroundColor3, flagButton.Text, flagButton.Font, flagButton.TextColor3, flagButton.TextSize, flagButton.Parent = UDim2.new(0.23, -2, 1, 0), UDim2.new((i-1) * 0.25, (i > 1) and 3 or 0, 0, 0), UIState.petSpawnState.activeFlags[flag] and flagColors[flag] or Color3.fromRGB(40, 44, 66), flag, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255), 12, flagGrid
        Instance.new("UICorner", flagButton).CornerRadius = UDim.new(0, 8)
        
        local flagStroke = Instance.new("UIStroke")
        flagStroke.Color, flagStroke.Thickness, flagStroke.Transparency, flagStroke.Parent = flagColors[flag], UIState.petSpawnState.activeFlags[flag] and 2.5 or 1.5, UIState.petSpawnState.activeFlags[flag] and 0.2 or 0.5, flagButton
        
        flagButton.MouseButton1Click:Connect(function()
            if flag == "M" and UIState.petSpawnState.activeFlags["N"] then return end
            if flag == "N" and UIState.petSpawnState.activeFlags["M"] then return end
            
            UIState.petSpawnState.activeFlags[flag] = not UIState.petSpawnState.activeFlags[flag]
            
            if UIState.petSpawnState.activeFlags[flag] then
                flagButton.BackgroundColor3 = flagColors[flag]
                TweenService:Create(flagStroke, TweenInfo.new(0.2), { Thickness = 2.5, Transparency = 0.2 }):Play()
            else
                flagButton.BackgroundColor3 = Color3.fromRGB(40, 44, 66)
                TweenService:Create(flagStroke, TweenInfo.new(0.2), { Thickness = 1.5, Transparency = 0.5 }):Play()
            end
        end)
    end

    local quickLabel = Instance.new("TextLabel")
    quickLabel.Size, quickLabel.Position, quickLabel.BackgroundTransparency, quickLabel.Text = UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, 114), 1, "⚡ Quick Select"
    quickLabel.Font, quickLabel.TextSize, quickLabel.TextColor3, quickLabel.TextXAlignment = Enum.Font.Gotham, 8, Color3.fromRGB(160, 170, 200), Enum.TextXAlignment.Left
    quickLabel.Parent = spawnPanel

    local quickGrid = Instance.new("Frame")
    quickGrid.Size, quickGrid.Position, quickGrid.BackgroundTransparency, quickGrid.Parent = UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 125), 1, spawnPanel

    local quickPets = {
        {"Shadow Dragon", Color3.fromRGB(100, 0, 100)}, {"Frost Dragon", Color3.fromRGB(0, 150, 255)}, {"Bat Dragon", Color3.fromRGB(150, 0, 0)},
        {"Giraffe", Color3.fromRGB(200, 150, 0)}, {"Owl", Color3.fromRGB(150, 100, 50)}, {"Parrot", Color3.fromRGB(255, 100, 0)}
    }

    for i, petData in ipairs(quickPets) do
        local row, col = math.floor((i-1) / 3), (i-1) % 3
        local quickButton = Instance.new("TextButton")
        quickButton.Size, quickButton.Position, quickButton.BackgroundColor3, quickButton.Text, quickButton.Font, quickButton.TextSize, quickButton.Parent = UDim2.new(0.32, -2, 0.45, 0), UDim2.new(col * 0.33, (col > 0) and 3 or 0, row * 0.5, (row > 0) and 3 or 0), petData[2], i <= 3 and petData[1] or petData[1]:match("^(%w+)") or petData[1], Enum.Font.GothamBold, 7, quickGrid
        Instance.new("UICorner", quickButton).CornerRadius = UDim.new(0, 6)
        quickButton.MouseButton1Click:Connect(function() nameInput.Text = petData[1] end)
    end

    local spawnAllButton = Instance.new("TextButton")
    spawnAllButton.Size, spawnAllButton.Position, spawnAllButton.Text, spawnAllButton.Font, spawnAllButton.TextSize, spawnAllButton.BackgroundColor3, spawnAllButton.TextColor3, spawnAllButton.Parent = UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 180), "👑 SPAWN ALL HIGH TIERS", Enum.Font.GothamBold, 9, Color3.fromRGB(180, 120, 50), Color3.fromRGB(255, 255, 255), spawnPanel
    Instance.new("UICorner", spawnAllButton).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", spawnAllButton).Color, Instance.new("UIStroke", spawnAllButton).Thickness, Instance.new("UIStroke", spawnAllButton).Transparency, Instance.new("UIStroke", spawnAllButton).Parent = Color3.fromRGB(255, 200, 100), 1.5, 0.3, spawnAllButton

    local spawnButton = Instance.new("TextButton")
    spawnButton.Size, spawnButton.Position, spawnButton.Text, spawnButton.Font, spawnButton.TextSize, spawnButton.BackgroundColor3, spawnButton.TextColor3, spawnButton.Parent = UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 180), "✨ SPAWN PET", Enum.Font.GothamBold, 12, Color3.fromRGB(0, 140, 200), Color3.fromRGB(255, 255, 255), spawnPanel
    Instance.new("UICorner", spawnButton).CornerRadius = UDim.new(0, 10)

    spawnAllButton.MouseButton1Click:Connect(function()
        local ageMap = {1, 2, 3, 4, 5, 6}
        local options = {
            mega_neon = UIState.petSpawnState.activeFlags["M"], neon = UIState.petSpawnState.activeFlags["N"],
            flyable = UIState.petSpawnState.activeFlags["F"], rideable = UIState.petSpawnState.activeFlags["R"],
            age = ageMap[currentAge], trick_level = 5, ailments_completed = 0
        }
        
        local successCount = 0
        spawnAllButton.Text = "⚡ SPAWNING..."
        
        for _, petName in ipairs(HighTierPets) do
            local petId = GetPetByName(petName)
            if petId then
                local petOptions = table.clone(options)
                petOptions.rp_name = GenerateUniquePetName()
                local item = CreateInventoryItem(petId, "pets", petOptions)
                if item then successCount = successCount + 1 end
            end
        end
        
        spawnAllButton.Text = "✓ SPAWNED " .. successCount .. "!"
        task.wait(1.5)
        spawnAllButton.Text = "👑 SPAWN ALL HIGH TIERS"
    end)

    spawnButton.MouseButton1Click:Connect(function()
        local petName = nameInput.Text
        if petName == "" then return end
        
        local petId = GetPetId(petName)
        if not petId then return end
        
        local ageMap = {1, 2, 3, 4, 5, 6}
        local options = {
            mega_neon = UIState.petSpawnState.activeFlags["M"], neon = UIState.petSpawnState.activeFlags["N"],
            flyable = UIState.petSpawnState.activeFlags["F"], rideable = UIState.petSpawnState.activeFlags["R"],
            age = ageMap[currentAge], trick_level = 5, ailments_completed = 0,
            rp_name = GenerateUniquePetName()
        }
        
        local item = CreateInventoryItem(petId, "pets", options)
        if item then
            spawnButton.Text = "✓ SPAWNED!"
            task.wait(0.5)
            spawnButton.Text = "✨ SPAWN PET"
        end
    end)

    nameInput:GetPropertyChangedSignal("Text"):Connect(function()
        local text = nameInput.Text
        if text == "" then inputGlow.Color = glowColors.neutral else
            local isValid = GetPetByName(text) ~= nil
            inputGlow.Color = isValid and glowColors.valid or glowColors.invalid
        end
    end)
end

--==================== TRADE SIM TAB CONTENT ====================
local function setupTradeSimTab()
    local controlFrame = Instance.new('ScrollingFrame')
    controlFrame.Size, controlFrame.Position, controlFrame.BackgroundTransparency, controlFrame.BorderSizePixel, controlFrame.ScrollBarThickness, controlFrame.ScrollBarImageColor3, controlFrame.ScrollBarImageTransparency, controlFrame.Parent = UDim2.new(0.95, 0, 0.55, 0), UDim2.new(0.025, 0, 0, 0), 1, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, tradeSimPanel
    Instance.new('UICorner', controlFrame).CornerRadius = UDim.new(0, 8)
    local controlStroke = Instance.new('UIStroke', controlFrame); controlStroke.Color, controlStroke.Thickness, controlStroke.Transparency = Color3.fromRGB(100, 100, 255), 1.5, 0.2
    
    local controlLayout = Instance.new('UIListLayout')
    controlLayout.SortOrder, controlLayout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 6)
    controlLayout.Parent = controlFrame
    
    local controlPadding = Instance.new('UIPadding')
    controlPadding.PaddingTop, controlPadding.PaddingBottom, controlPadding.PaddingLeft, controlPadding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
    controlPadding.Parent = controlFrame

    local function createSettingRow(labelText, defaultValue, parent)
        local heading = Instance.new('TextLabel')
        heading.Size, heading.BackgroundTransparency, heading.Text, heading.Font, heading.TextSize, heading.TextColor3, heading.TextXAlignment, heading.Parent = UDim2.new(1, 0, 0, 14), 1, labelText, Enum.Font.SourceSansSemibold, 10, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, parent

        local box = Instance.new('TextBox')
        box.Size, box.BackgroundColor3, box.BackgroundTransparency, box.Text, box.Font, box.TextSize, box.TextColor3, box.ClearTextOnFocus, box.TextXAlignment, box.Parent = UDim2.new(1, 0, 0, 24), Color3.fromRGB(40, 40, 50), 0.2, tostring(defaultValue), Enum.Font.SourceSans, 12, Color3.fromRGB(255, 255, 255), false, Enum.TextXAlignment.Center, parent

        local corner = Instance.new('UICorner')
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = box

        local stroke = Instance.new('UIStroke')
        stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(100, 100, 100), 0.8, 0.5, box

        box.FocusLost:Connect(function()
            if UIState.pulsationTweens[box] then UIState.pulsationTweens[box]:Cancel() UIState.pulsationTweens[box] = nil end
            TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = Color3.fromRGB(100, 100, 100), Thickness = 0.8, Transparency = 0.5 }):Play()
        end)
        
        box.Focused:Connect(function()
            if UIState.pulsationTweens[box] then UIState.pulsationTweens[box]:Cancel() end
            UIState.pulsationTweens[box] = TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = Color3.fromRGB(100, 100, 255):Lerp(Color3.fromRGB(150, 150, 255), 0.5), Thickness = 1.2, Transparency = 0.2 })
            UIState.pulsationTweens[box]:Play()
        end)
        return box, stroke, heading
    end

    local function createButton(text, bgColor, strokeColor, parent, onClick)
        local btn = Instance.new('TextButton')
        btn.Size, btn.BackgroundColor3, btn.BackgroundTransparency, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(1, 0, 0, 26), bgColor, 0.2, text, Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), parent
        local corner = Instance.new('UICorner'); corner.CornerRadius = UDim.new(0, 4); corner.Parent = btn
        local stroke = Instance.new('UIStroke'); stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Parent = Enum.ApplyStrokeMode.Border, strokeColor, 1.0, btn
        if onClick then btn.MouseButton1Click:Connect(onClick) end
        return btn, stroke
    end
    
    local function createSpacer(parent, height)
        local spacer = Instance.new('Frame')
        spacer.Size, spacer.BackgroundTransparency, spacer.Parent = UDim2.new(1, 0, 0, height or 3), 1, parent
        return spacer
    end

    local partnerBox, partnerStroke = createSettingRow('Partner Username', CONFIG.PARTNER_NAME, controlFrame)
    local acceptBox = createSettingRow('Accept Delay (s)', CONFIG.AUTO_ACCEPT_DELAY, controlFrame)
    local confirmBox = createSettingRow('Confirm Delay (s)', CONFIG.AUTO_CONFIRM_DELAY, controlFrame)
    spectatorBox = createSettingRow('Spectator Count', CONFIG.SPECTATOR_COUNT, controlFrame)
    local requestDelayBox = createSettingRow('Request Delay (s)', CONFIG.TRADE_REQUEST_DELAY, controlFrame)

    partnerBox.FocusLost:Connect(function() updatePartnerFromUsername(partnerBox.Text) end)
    acceptBox.FocusLost:Connect(function() local v = tonumber(acceptBox.Text); if v and v >= 0 then CONFIG.AUTO_ACCEPT_DELAY = v else acceptBox.Text = tostring(CONFIG.AUTO_ACCEPT_DELAY) end end)
    confirmBox.FocusLost:Connect(function() local v = tonumber(confirmBox.Text); if v and v >= 0 then CONFIG.AUTO_CONFIRM_DELAY = v else confirmBox.Text = tostring(CONFIG.AUTO_CONFIRM_DELAY) end end)
    spectatorBox.FocusLost:Connect(function()
        local v = tonumber(spectatorBox.Text)
        if v and v >= 0 then
            CONFIG.SPECTATOR_COUNT = v
            ORIGINAL_SPECTATOR_COUNT = v
            if UIState.mockState.trade then
                UIState.mockState.trade.subscriber_count = v
                if TradeApp.refresh_all then TradeApp:refresh_all(); FriendHighlight(true) end
            end
        else
            spectatorBox.Text = tostring(CONFIG.SPECTATOR_COUNT)
        end
    end)
    requestDelayBox.FocusLost:Connect(function()
        local v = tonumber(requestDelayBox.Text)
        if v and v >= 0 then CONFIG.TRADE_REQUEST_DELAY = v else requestDelayBox.Text = tostring(CONFIG.TRADE_REQUEST_DELAY) end
    end)

    createSpacer(controlFrame)

    local autoSpectateButton = Instance.new('TextButton')
    autoSpectateButton.Size, autoSpectateButton.BackgroundColor3, autoSpectateButton.BackgroundTransparency, autoSpectateButton.Text, autoSpectateButton.Font, autoSpectateButton.TextSize, autoSpectateButton.TextColor3, autoSpectateButton.Parent = UDim2.new(1, 0, 0, 32), Color3.fromRGB(150, 50, 50), 0.1, '? Auto Spectate: OFF', Enum.Font.FredokaOne, 13, Color3.fromRGB(255, 255, 255), controlFrame
    Instance.new('UICorner', autoSpectateButton).CornerRadius = UDim.new(0, 4)
    local autoSpectateStroke = Instance.new('UIStroke')
    autoSpectateStroke.ApplyStrokeMode, autoSpectateStroke.Color, autoSpectateStroke.Thickness, autoSpectateStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 100, 100), 1.5, autoSpectateButton

    autoSpectateButton.MouseButton1Click:Connect(function()
        CONFIG.AUTO_SPECTATE_ENABLED = not CONFIG.AUTO_SPECTATE_ENABLED
        if CONFIG.AUTO_SPECTATE_ENABLED then
            autoSpectateButton.Text, autoSpectateButton.BackgroundColor3, autoSpectateStroke.Color = '? Auto Spectate: ON (Random)', Color3.fromRGB(50, 150, 50), Color3.fromRGB(100, 255, 100)
            ORIGINAL_SPECTATOR_COUNT = CONFIG.SPECTATOR_COUNT
            startAutoSpectate()
            if HintApp then HintApp:hint({ text = 'Auto Spectate ON! Range: ' .. (ORIGINAL_SPECTATOR_COUNT + CONFIG.SPECTATOR_VARIATION_MIN) .. '-' .. (ORIGINAL_SPECTATOR_COUNT + CONFIG.SPECTATOR_VARIATION_MAX), length = 3, overridable = true }) end
        else
            autoSpectateButton.Text, autoSpectateButton.BackgroundColor3, autoSpectateStroke.Color = '? Auto Spectate: OFF', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100)
            stopAutoSpectate()
            if HintApp then HintApp:hint({ text = 'Auto Spectate OFF', length = 2, overridable = true }) end
        end
    end)

    createSpacer(controlFrame)

    createButton('Add Random Item', Color3.fromRGB(100, 50, 150), Color3.fromRGB(200, 100, 255), controlFrame, function()
        if UIState.mockState.active then addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties()) end
    end)
    createSpacer(controlFrame)

    createButton('Clear Trade', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
        if UIState.mockState.active and UIState.mockState.trade then
            UIState.mockState.trade.sender_offer.items, UIState.mockState.trade.recipient_offer.items = {}, {}
            UpdateMockState({ sender_offer = { negotiated = false }, recipient_offer = { negotiated = false, confirmed = false }, current_stage = 'negotiation' })
        end
    end)
    createSpacer(controlFrame)

    createButton('Start Trade', Color3.fromRGB(50, 80, 60), Color3.fromRGB(0, 255, 100), controlFrame, function()
        if UIState.mockState.active or UIState.mockState.pendingTradeRequest then return end
        if CONFIG.SHOW_TRADE_REQUEST then task.spawn(showTradeRequest) else task.spawn(startMockTradeDirectly) end
    end)

    createButton('Block Player', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
        local player = Players:FindFirstChild(partnerBox.Text)
        if player then BlockPlayer(player) end
    end)
    createSpacer(controlFrame)

    local makePartnerAcceptButton, makePartnerAcceptStroke = createButton('Make Partner Accept', Color3.fromRGB(50, 150, 50), Color3.fromRGB(100, 255, 100), controlFrame, function()
        if UIState.mockState.active and UIState.mockState.trade then
            if UIState.mockState.trade.current_stage == 'negotiation' then
                if not UIState.mockState.trade.recipient_offer.negotiated then
                    UIState.mockState.trade.recipient_offer.negotiated = true
                    if UIState.mockState.trade.sender_offer.negotiated then
                        UIState.mockState.trade.current_stage = 'confirmation'
                        if TradeApp._evaluate_trade_fairness then TradeApp:_evaluate_trade_fairness() end
                        if TradeApp._lock_trade_for_appropriate_time then TradeApp:_lock_trade_for_appropriate_time() end
                    end
                    UpdateMockState({ sender_offer = { negotiated = UIState.mockState.trade.sender_offer.negotiated } })
                end
            elseif UIState.mockState.trade.current_stage == 'confirmation' then
                if not UIState.mockState.trade.recipient_offer.confirmed then
                    UIState.mockState.trade.recipient_offer.confirmed = true
                    UpdateMockState({ recipient_offer = { confirmed = true } })
                    if UIState.mockState.trade.sender_offer.confirmed and not UIState.mockState.tradeCompleting then
                        UIState.mockState.tradeCompleting = true
                        if TradeApp._set_confirmation_arrow_rotating then TradeApp:_set_confirmation_arrow_rotating(true) end
                        task.wait(3)
                        local historyRecord = createTradeHistoryRecord(UIState.mockState.trade)
                        appendToTradeHistory(historyRecord)
                        UIState.mockState = { active = false, trade = nil, scamWarningShown = true, canShowTradeRequest = true, tradeRequestBlocked = false }
                        UIManager.set_app_visibility('TradeApp', false)
                        task.wait(0.1)
                        showBlockedTradeRequests()
                        if HintApp then HintApp:hint({ text = 'Trade successful!', length = 5, overridable = true }) end
                        if UIState.mockState.tradeHistory and UIManager.is_visible('TradeHistoryApp') then TradeHistoryApp:_refresh() end
                    end
                end
            end
        end
    end)

    local noclipButton, noclipStroke = createButton('Toggle Noclip: ON', Color3.fromRGB(80, 80, 180), Color3.fromRGB(100, 100, 255), controlFrame, function()
        UIState.noclipEnabled = not UIState.noclipEnabled
        noclipButton.Text = 'Toggle Noclip: ' .. (UIState.noclipEnabled and 'ON' or 'OFF')
        noclipButton.BackgroundColor3 = UIState.noclipEnabled and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(180, 80, 80)
        noclipStroke.Color = UIState.noclipEnabled and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(255, 100, 100)
        enableNoclipForAllFakePlayers()
        enableNoclipForPets()
    end)

    createSpacer(controlFrame)

    local makePartnerUnacceptButton, makePartnerUnacceptStroke = createButton('Make Partner Unaccept', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
        if UIState.mockState.active and UIState.mockState.trade then
            if UIState.mockState.trade.current_stage == 'negotiation' then
                if UIState.mockState.trade.recipient_offer.negotiated then
                    UIState.mockState.trade.recipient_offer.negotiated = false
                    UpdateMockState({ recipient_offer = { negotiated = false } })
                end
            elseif UIState.mockState.trade.current_stage == 'confirmation' then
                if UIState.mockState.trade.recipient_offer.confirmed then
                    UIState.mockState.trade.recipient_offer.confirmed = false
                    UpdateMockState({ recipient_offer = { confirmed = false } })
                end
            end
        end
    end)

    local petTypeContainer = Instance.new('Frame')
    petTypeContainer.Size, petTypeContainer.BackgroundTransparency, petTypeContainer.Parent = UDim2.new(1, 0, 0, 24), 1, controlFrame
    
    local petTypeLabel = Instance.new('TextLabel')
    petTypeLabel.Size, petTypeLabel.Position, petTypeLabel.BackgroundTransparency, petTypeLabel.Text = UDim2.new(0.4, 0, 1, 0), UDim2.new(0, 0, 0, 0), 1, 'Fake Player Pet:'
    petTypeLabel.Font, petTypeLabel.TextSize, petTypeLabel.TextColor3, petTypeLabel.TextXAlignment, petTypeLabel.Parent = Enum.Font.SourceSansSemibold, 10, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petTypeContainer

    local petTypeButtons = {}
    local petTypes = { { name = 'regular', label = 'Reg', pos = 0.4 }, { name = 'neon', label = 'Neon', pos = 0.6 }, { name = 'mega', label = 'Mega', pos = 0.8 } }
    
    for _, pt in ipairs(petTypes) do
        local btn = Instance.new('TextButton')
        btn.Size, btn.Position, btn.BackgroundColor3, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(0.18, 0, 1, 0), UDim2.new(pt.pos, 0, 0, 0), pt.name == 'regular' and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70), pt.label, Enum.Font.FredokaOne, 9, Color3.fromRGB(255, 255, 255), petTypeContainer
        Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 4)
        petTypeButtons[pt.name] = btn
        btn.MouseButton1Click:Connect(function()
            UIState.fakePetType = pt.name
            for name, b in pairs(petTypeButtons) do b.BackgroundColor3 = name == pt.name and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70) end
        end)
    end

    createButton('Spawn fake player', Color3.fromRGB(65, 50, 150), Color3.fromRGB(74, 207, 255), controlFrame, function()
        local petData, petFlags = nil, nil
        if CONFIG.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET then
            local highValuePet = getRandomHighValuePet()
            petFlags = { M = UIState.fakePetType == 'mega', N = UIState.fakePetType == 'neon', F = true, R = true }
            petData = { kind = GetKindPet(highValuePet) }
        end
        CreateFakePlayerCharacterFromPARTNER_NAME(CONFIG.PARTNER_NAME, Players:GetUserIdFromNameAsync(CONFIG.PARTNER_NAME), petData, petFlags)
    end)

    local spawnWithPetsButton = Instance.new('TextButton')
    spawnWithPetsButton.Size, spawnWithPetsButton.BackgroundColor3, spawnWithPetsButton.BackgroundTransparency, spawnWithPetsButton.Text, spawnWithPetsButton.Font, spawnWithPetsButton.TextSize, spawnWithPetsButton.TextColor3, spawnWithPetsButton.Parent = UDim2.new(1, 0, 0, 14), Color3.fromRGB(150, 50, 50), 0.2, 'Spawn with random pet: false', Enum.Font.FredokaOne, 7, Color3.fromRGB(255, 255, 255), controlFrame
    Instance.new('UICorner', spawnWithPetsButton).CornerRadius = UDim.new(0, 3)
    local spawnWithPetsStroke = Instance.new('UIStroke')
    spawnWithPetsStroke.ApplyStrokeMode, spawnWithPetsStroke.Color, spawnWithPetsStroke.Thickness, spawnWithPetsStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 100, 100), 0.8, spawnWithPetsButton

    spawnWithPetsButton.MouseButton1Click:Connect(function()
        CONFIG.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET = not CONFIG.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET
        spawnWithPetsButton.Text = 'Spawn with random pet: ' .. (CONFIG.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET and 'true' or 'false')
        spawnWithPetsButton.BackgroundColor3 = CONFIG.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
        spawnWithPetsStroke.Color = CONFIG.SPAWN_FAKE_PLAYER_WITH_RANDOM_PET and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    end)

    createSpacer(controlFrame)

    local deleteFakePlayerButton = Instance.new('TextButton')
    deleteFakePlayerButton.Size, deleteFakePlayerButton.BackgroundColor3, deleteFakePlayerButton.Text, deleteFakePlayerButton.Font, deleteFakePlayerButton.TextSize, deleteFakePlayerButton.TextColor3, deleteFakePlayerButton.Parent = UDim2.new(1, 0, 0, 14), Color3.fromRGB(157, 58, 0), 'Delete all fake players', Enum.Font.FredokaOne, 7, Color3.fromRGB(255, 255, 255), controlFrame
    Instance.new('UICorner', deleteFakePlayerButton).CornerRadius = UDim.new(0, 3)

    deleteFakePlayerButton.MouseButton1Click:Connect(function()
        pcall(function()
            AnimationManager:Stop()
            for _, petData in ipairs(UIState.FakePetRegistry) do
                if petData and petData.model then
                    UpdateClientData('pet_char_wrappers', function(wrappers)
                        for i = #wrappers, 1, -1 do if wrappers[i].pet_unique == petData.wrapper.pet_unique then table.remove(wrappers, i) end end return wrappers
                    end)
                    UpdateClientData('pet_state_managers', function(managers)
                        for i = #managers, 1, -1 do if managers[i].char == petData.model then table.remove(managers, i) end end return managers
                    end)
                end
            end
            for _, folder in pairs(UIState.FakePlayers) do if folder and folder.Parent then folder:Destroy() end end
            UIState.FakePlayers, UIState.FakePetRegistry, fakePlayerIds = {}, {}, {}
            _G.fakePlayerIds = {}
            print('? All fake players and pets deleted successfully')
        end)
    end)

    createSpacer(controlFrame)

    local removePetsButton, removePetsStroke = createButton('Remove Partner Pets: OFF', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
        UIState.mockState.removePartnerPetsOnConfirm = not UIState.mockState.removePartnerPetsOnConfirm
        CONFIG.REMOVE_PARTNER_PETS_ON_CONFIRM = UIState.mockState.removePartnerPetsOnConfirm
        removePetsButton.Text = 'Remove Partner Pets: ' .. (UIState.mockState.removePartnerPetsOnConfirm and 'ON' or 'OFF')
        removePetsButton.BackgroundColor3 = UIState.mockState.removePartnerPetsOnConfirm and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
        removePetsStroke.Color = UIState.mockState.removePartnerPetsOnConfirm and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    end)

    -- Initialize fake player Noclip state
    local noclipButton, noclipStroke = createButton('Toggle Noclip: ON', Color3.fromRGB(80, 80, 180), Color3.fromRGB(100, 100, 255), controlFrame, function()
        UIState.noclipEnabled = not UIState.noclipEnabled
        noclipButton.Text = 'Toggle Noclip: ' .. (UIState.noclipEnabled and 'ON' or 'OFF')
        noclipButton.BackgroundColor3 = UIState.noclipEnabled and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(180, 80, 80)
        noclipStroke.Color = UIState.noclipEnabled and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(255, 100, 100)
        enableNoclipForAllFakePlayers()
        enableNoclipForPets()
    end)

    -- Keybind Settings Section
    local spacer = Instance.new('Frame')
    spacer.Size, spacer.BackgroundTransparency, spacer.LayoutOrder, spacer.Parent = UDim2.new(1, 0, 0, 10), 1, 10, controlFrame
    
    local heading = Instance.new('TextLabel')
    heading.Size, heading.BackgroundTransparency, heading.Text, heading.Font, heading.TextSize, heading.TextColor3, heading.LayoutOrder, heading.Parent = UDim2.new(1, 0, 0, 18), 1, '🔑 Keybind Settings', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), 11, controlFrame

    local function createKeybindRow(labelText, keybindKey, layoutOrder)
        local row = Instance.new('Frame')
        row.Size, row.BackgroundColor3, row.BackgroundTransparency, row.LayoutOrder, row.Parent = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, layoutOrder, controlFrame
        Instance.new('UICorner', row).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new('UIStroke')
        stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, row
        
        local label = Instance.new('TextLabel')
        label.Size, label.Position, label.BackgroundTransparency, label.Text, label.Font, label.TextSize, label.TextColor3, label.Parent = UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, labelText, Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), row
        
        local btn = Instance.new('TextButton')
        btn.Size, btn.Position, btn.BackgroundColor3, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(0.35, -8, 0, 26), UDim2.new(0.65, 0, 0.5, -13), Color3.fromRGB(70, 65, 95), UIState.keybinds[keybindKey].Name, Enum.Font.GothamBold, 11, Color3.fromRGB(255, 255, 255), row
        Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 4)
        Instance.new('UIStroke', btn).Color, Instance.new('UIStroke', btn).Thickness = Color3.fromRGB(100, 100, 150), 1.0
        
        UIState.keybindButtons[keybindKey] = btn
        
        btn.MouseEnter:Connect(function() if UIState.waitingForKeybind ~= keybindKey then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(90, 85, 120) }):Play() end end)
        btn.MouseLeave:Connect(function() if UIState.waitingForKeybind ~= keybindKey then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play() end end)
        btn.MouseButton1Click:Connect(function()
            if UIState.waitingForKeybind then
                local oldBtn = UIState.keybindButtons[UIState.waitingForKeybind]
                if oldBtn then oldBtn.Text = UIState.keybinds[UIState.waitingForKeybind].Name; oldBtn.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
            end
            UIState.waitingForKeybind = keybindKey
            btn.Text = '...'
            btn.BackgroundColor3 = Color3.fromRGB(100, 80, 150)
        end)
        return row
    end

    createKeybindRow('Select Partner from Trade', 'selectPartner', 1)
    createKeybindRow('Add Random Item', 'addRandomItem', 2)
    createKeybindRow('Start Trade', 'startTrade', 3)
    createKeybindRow('Block Player', 'blockPlayer', 4)

    -- RGB Settings
    local spacer = Instance.new('Frame'); spacer.Size, spacer.BackgroundTransparency, spacer.LayoutOrder, spacer.Parent = UDim2.new(1, 0, 0, 10), 1, 10, controlFrame
    local heading = Instance.new('TextLabel')
    heading.Size, heading.BackgroundTransparency, heading.Text, heading.Font, heading.TextSize, heading.TextColor3, heading.LayoutOrder, heading.Parent = UDim2.new(1, 0, 0, 18), 1, '? RGB Settings', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), 11, controlFrame
    
    local row = Instance.new('Frame')
    row.Size, row.BackgroundColor3, row.BackgroundTransparency, row.LayoutOrder, row.Parent = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, 12, controlFrame
    Instance.new('UICorner', row).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new('UIStroke')
    stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, row
    
    local label = Instance.new('TextLabel')
    label.Size, label.Position, label.BackgroundTransparency, label.Text, label.Font, label.TextSize, label.TextColor3, label.Parent = UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, 'RGB Speed', Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), row
    
    local valueBox = Instance.new('TextBox')
    valueBox.Size, valueBox.Position, valueBox.BackgroundColor3, valueBox.Text, valueBox.Font, valueBox.TextSize, valueBox.TextColor3, valueBox.Parent = UDim2.new(0.2, 0, 0, 24), UDim2.new(0.5, 0, 0.5, -12), Color3.fromRGB(70, 65, 95), '0.5', Enum.Font.GothamBold, 11, Color3.fromRGB(255, 255, 255), controlFrame
    Instance.new('UICorner', valueBox).CornerRadius = UDim.new(0, 4)
    
    local minusBtn = Instance.new('TextButton')
    minusBtn.Size, minusBtn.Position, minusBtn.BackgroundColor3, minusBtn.Text, minusBtn.Font, minusBtn.TextSize, minusBtn.TextColor3, minusBtn.Parent = UDim2.new(0, 26, 0, 24), UDim2.new(0.72, 0, 0.5, -12), Color3.fromRGB(150, 60, 60), '-', Enum.Font.GothamBold, 14, Color3.fromRGB(255, 255, 255), row
    Instance.new('UICorner', minusBtn).CornerRadius = UDim.new(0, 4)
    
    local plusBtn = Instance.new('TextButton')
    plusBtn.Size, plusBtn.Position, plusBtn.BackgroundColor3, plusBtn.Text, plusBtn.Font, plusBtn.TextSize, plusBtn.TextColor3, plusBtn.Parent = UDim2.new(0, 26, 0, 24), UDim2.new(0.86, 0, 0.5, -12), Color3.fromRGB(60, 150, 60), '+', Enum.Font.GothamBold, 14, Color3.fromRGB(255, 255, 255), row
    Instance.new('UICorner', plusBtn).CornerRadius = UDim.new(0, 4)
    
    minusBtn.MouseButton1Click:Connect(function() local current = math.max(0.1, (tonumber(valueBox.Text) or 0.5) - 0.1); valueBox.Text = string.format('%.1f', current); UIState.RGBState.speed = current end)
    plusBtn.MouseButton1Click:Connect(function() local current = math.min(2.0, (tonumber(valueBox.Text) or 0.5) + 0.1); valueBox.Text = string.format('%.1f', current); UIState.RGBState.speed = current end)
    valueBox.FocusLost:Connect(function()
        local val = tonumber(valueBox.Text)
        if val then val = math.clamp(val, 0.1, 2.0); valueBox.Text = string.format('%.1f', val); UIState.RGBState.speed = val
        else valueBox.Text = '0.5'; UIState.RGBState.speed = 0.5 end
    end)

    -- Server Uptime
    local spacer2 = Instance.new('Frame'); spacer2.Size, spacer2.BackgroundTransparency, spacer2.LayoutOrder, spacer2.Parent = UDim2.new(1, 0, 0, 10), 1, 13, controlFrame
    local heading2 = Instance.new('TextLabel')
    heading2.Size, heading2.BackgroundTransparency, heading2.Text, heading2.Font, heading2.TextSize, heading2.TextColor3, heading2.LayoutOrder, heading2.Parent = UDim2.new(1, 0, 0, 18), 1, '? Server Info', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), 14, controlFrame
    
    local row2 = Instance.new('Frame')
    row2.Size, row2.BackgroundColor3, row2.BackgroundTransparency, row2.LayoutOrder, row2.Parent = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, 15, controlFrame
    Instance.new('UICorner', row2).CornerRadius = UDim.new(0, 6)
    local stroke2 = Instance.new('UIStroke')
    stroke2.ApplyStrokeMode, stroke2.Color, stroke2.Thickness, stroke2.Transparency, stroke2.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, row2
    
    local label2 = Instance.new('TextLabel')
    label2.Size, label2.Position, label2.BackgroundTransparency, label2.Text, label2.Font, label2.TextSize, label2.TextColor3, label2.Parent = UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, 'Server Uptime', Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), row2
    
    local valueLabel = Instance.new('TextLabel')
    valueLabel.Size, valueLabel.Position, valueLabel.BackgroundTransparency, valueLabel.Text, valueLabel.Font, valueLabel.TextSize, valueLabel.TextColor3, valueLabel.Parent = UDim2.new(0.5, -8, 1, 0), UDim2.new(0.5, 0, 0, 0), 1, '0h 0m 0s', Enum.Font.GothamBold, 11, Color3.fromRGB(100, 255, 150), row2
    
    task.spawn(function()
        while true do
            local uptime = workspace.DistributedGameTime
            valueLabel.Text = string.format('%dh %dm %ds', math.floor(uptime/3600), math.floor((uptime%3600)/60), math.floor(uptime%60))
            task.wait(1)
        end
    end)

    -- GUI Size Section
    local spacer3 = Instance.new('Frame'); spacer3.Size, spacer3.BackgroundTransparency, spacer3.LayoutOrder, spacer3.Parent = UDim2.new(1, 0, 0, 10), 1, 16, controlFrame
    local heading3 = Instance.new('TextLabel')
    heading3.Size, heading3.BackgroundTransparency, heading3.Text, heading3.Font, heading3.TextSize, heading3.TextColor3, heading3.LayoutOrder, heading3.Parent = UDim2.new(1, 0, 0, 18), 1, '? GUI Size (Mobile)', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), 17, controlFrame
    
    local row3 = Instance.new('Frame')
    row3.Size, row3.BackgroundTransparency, row3.LayoutOrder, row3.Parent = UDim2.new(1, 0, 0, 40), 1, 18, controlFrame
    
    local smallBtn = Instance.new('TextButton')
    smallBtn.Size, smallBtn.Position, smallBtn.BackgroundColor3, smallBtn.Text, smallBtn.Font, smallBtn.TextSize, smallBtn.TextColor3, smallBtn.Parent = UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(80, 60, 120), '? Small', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), row3
    Instance.new('UICorner', smallBtn).CornerRadius = UDim.new(0, 6)
    local ss = Instance.new('UIStroke', smallBtn); ss.Color, ss.Thickness = Color3.fromRGB(255, 200, 50), 1.5; ss.Transparency = 0.2
    
    local bigBtn = Instance.new('TextButton')
    bigBtn.Size, bigBtn.Position, bigBtn.BackgroundColor3, bigBtn.Text, bigBtn.Font, bigBtn.TextSize, bigBtn.TextColor3, bigBtn.Parent = UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(60, 120, 80), '? Big', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), row3
    Instance.new('UICorner', bigBtn).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new('UIStroke', bigBtn); bs.Color, bs.Thickness, bs.Transparency = Color3.fromRGB(255, 200, 50), 1.5, 0.2

    smallBtn.MouseButton1Click:Connect(function() UIState.currentScale = math.max(0.7, UIState.currentScale - 0.05); uiScale.Scale = UIState.currentScale; if HintApp then HintApp:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', UIState.currentScale * 100), length = 1, overridable = true }) end end)
    bigBtn.MouseButton1Click:Connect(function() UIState.currentScale = math.min(1.3, UIState.currentScale + 0.05); uiScale.Scale = UIState.currentScale; if HintApp then HintApp:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', UIState.currentScale * 100), length = 1, overridable = true }) end end)
    smallBtn.MouseEnter:Connect(function() TweenService:Create(smallBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 80, 150) }):Play() end)
    smallBtn.MouseLeave:Connect(function() TweenService:Create(smallBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 60, 120) }):Play() end)
    bigBtn.MouseEnter:Connect(function() TweenService:Create(bigBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 150, 100) }):Play() end)
    bigBtn.MouseLeave:Connect(function() TweenService:Create(bigBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 120, 80) }):Play() end)
    
    -- Pet Value Calculator
    local spacer4 = Instance.new('Frame'); spacer4.Size, spacer4.BackgroundTransparency, spacer4.LayoutOrder, spacer4.Parent = UDim2.new(1, 0, 0, 10), 1, 19, controlFrame
    local heading4 = Instance.new('TextLabel')
    heading4.Size, heading4.BackgroundTransparency, heading4.Text, heading4.Font, heading4.TextSize, heading4.TextColor3, heading4.LayoutOrder, heading4.Parent = UDim2.new(1, 0, 0, 18), 1, '? Pet Value Calculator', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), 20, controlFrame
    
    local PVC = { state = { M = false, N = false, F = false, R = false }, btns = {} }
    local colors = { M = {Color3.fromRGB(170,0,255), Color3.fromRGB(80,60,100)}, N = {Color3.fromRGB(255,215,0), Color3.fromRGB(80,60,100)}, F = {Color3.fromRGB(0,200,255), Color3.fromRGB(80,60,100)}, R = {Color3.fromRGB(0,255,100), Color3.fromRGB(80,60,100)} }
    
    local ir = Instance.new('Frame')
    ir.Size, ir.BackgroundColor3, ir.BackgroundTransparency, ir.LayoutOrder, ir.Parent = UDim2.new(1, 0, 0, 30), Color3.fromRGB(40, 40, 50), 0.2, 21, controlFrame
    Instance.new('UICorner', ir).CornerRadius = UDim.new(0, 4)
    local irs = Instance.new('UIStroke'); irs.Color, irs.Thickness, irs.Transparency, irs.Parent = Color3.fromRGB(255,200,50), 1.5, 0.2, ir
    
    PVC.input = Instance.new('TextBox')
    PVC.input.Size, PVC.input.Position, PVC.input.BackgroundTransparency, PVC.input.Text, PVC.input.PlaceholderText, PVC.input.Font, PVC.input.TextSize, PVC.input.TextColor3, PVC.input.PlaceholderColor3, PVC.input.Parent = UDim2.new(1, -16, 1, -1), UDim2.new(0, 8, 0, 3), 1, '', 'Enter pet name...', Enum.Font.GothamMedium, 11, Color3.fromRGB(255,255,255), Color3.fromRGB(150,150,160), ir
    
    local pr = Instance.new('Frame')
    pr.Size, pr.BackgroundTransparency, pr.LayoutOrder, pr.Parent = UDim2.new(1, 0, 0, 28), 1, 22, controlFrame
    
    for i, p in ipairs({'M','N','F','R'}) do
        local b = Instance.new('TextButton')
        b.Size, b.Position, b.BackgroundColor3, b.Text, b.Font, b.TextSize, b.TextColor3, b.Parent = UDim2.new(0.24,-4,1,0), UDim2.new((i-1)*0.25,2,0,0), colors[p][2], p, Enum.Font.GothamBold, 12, Color3.fromRGB(255,255,255), pr
        Instance.new('UICorner', b).CornerRadius = UDim.new(0, 4)
        PVC.btns[p] = b
        b.MouseButton1Click:Connect(function()
            if p == 'M' then PVC.state.M = not PVC.state.M; if PVC.state.M then PVC.state.N = false end
            elseif p == 'N' then PVC.state.N = not PVC.state.N; if PVC.state.N then PVC.state.M = false end
            else PVC.state[p] = not PVC.state[p] end
            for k, v in pairs(PVC.btns) do v.BackgroundColor3 = PVC.state[k] and colors[k][1] or colors[k][2] end
        end)
    end
    
    local cb = Instance.new('TextButton')
    cb.Size, cb.BackgroundColor3, cb.Text, cb.Font, cb.TextSize, cb.TextColor3, cb.LayoutOrder, cb.Parent = UDim2.new(1, 0, 0, 32), Color3.fromRGB(80, 160, 80), '? Calculate Value', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), 23, controlFrame
    Instance.new('UICorner', cb).CornerRadius = UDim.new(0, 6)
    local cbs = Instance.new('UIStroke')
    cbs.Color, cbs.Thickness, cbs.Transparency, cbs.Parent = Color3.fromRGB(255, 200, 50), 1.5, 0.2, cb
    
    PVC.result = Instance.new('TextLabel')
    PVC.result.Size, PVC.result.Position, PVC.result.BackgroundTransparency, PVC.result.Text, PVC.result.Font, PVC.result.TextSize, PVC.result.TextColor3, PVC.result.LayoutOrder, PVC.result.Parent = UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 36), 1, 'Value: --', Enum.Font.GothamBold, 14, Color3.fromRGB(100, 255, 150), 24, controlFrame
    Instance.new('UICorner', PVC.result).CornerRadius = UDim.new(0, 6)
    local rs = Instance.new('UIStroke')
    rs.Color, rs.Thickness, rs.Transparency, rs.Parent = Color3.fromRGB(255, 200, 50), 1.5, 0.2, PVC.result
    
    cb.MouseButton1Click:Connect(function()
        local sn = PVC.input.Text:lower():gsub('%s+', '')
        if sn == '' then PVC.result.Text, PVC.result.TextColor3 = 'Enter a pet name!', Color3.fromRGB(255, 100, 100) return end
        local fp, fk = nil, nil
        for k, pet in pairs(petsByName) do if k:lower():gsub('%s+',''):find(sn,1,true) then fp, fk = pet, k break end end
        if not fp then PVC.result.Text, PVC.result.TextColor3 = 'Pet not found!', Color3.fromRGB(255, 100, 100) return end
        local bk = PVC.state.M and "mvalue" or (PVC.state.N and "nvalue" or "rvalue")
        local sf = (PVC.state.R and PVC.state.F) and " - fly&ride" or (PVC.state.R and " - ride" or (PVC.state.F and " - fly" or " - nopotion"))
        local v = fp[bk .. sf] or fp[bk] or 0
        local fv = v >= 1e9 and string.format('%.2fB',v/1e9) or (v >= 1e6 and string.format('%.2fM',v/1e6) or (v >= 1e3 and string.format('%.2fK',v/1e3) or tostring(v)))
        local ps = (PVC.state.M and 'Mega ' or '')..(PVC.state.N and 'Neon ' or '')..(PVC.state.F and 'F' or '')..(PVC.state.R and 'R' or ''); if ps == '' then ps = 'Normal' end
        PVC.result.Text, PVC.result.TextColor3 = fk..' ('..ps..'): '..fv, Color3.fromRGB(100, 255, 150)
    end)
    cb.MouseEnter:Connect(function() TweenService:Create(cb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 180, 100) }):Play() end)
    cb.MouseLeave:Connect(function() TweenService:Create(cb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 160, 80) }):Play() end)

    -- Auto Spectate Button
    local autoSpectateButton = Instance.new('TextButton')
    autoSpectateButton.Size, autoSpectateButton.BackgroundColor3, autoSpectateButton.BackgroundTransparency, autoSpectateButton.Text, autoSpectateButton.Font, autoSpectateButton.TextSize, autoSpectateButton.TextColor3, autoSpectateButton.Parent = UDim2.new(1, 0, 0, 32), Color3.fromRGB(150, 50, 50), 0.1, '? Auto Spectate: OFF', Enum.Font.FredokaOne, 13, Color3.fromRGB(255, 255, 255), controlFrame
    Instance.new('UICorner', autoSpectateButton).CornerRadius = UDim.new(0, 4)
    local autoSpectateStroke = Instance.new('UIStroke')
    autoSpectateStroke.ApplyStrokeMode, autoSpectateStroke.Color, autoSpectateStroke.Thickness, autoSpectateStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 100, 100), 1.5, autoSpectateButton

    autoSpectateButton.MouseButton1Click:Connect(function()
        CONFIG.AUTO_SPECTATE_ENABLED = not CONFIG.AUTO_SPECTATE_ENABLED
        autoSpectateButton.Text, autoSpectateButton.BackgroundColor3, autoSpectateStroke.Color = '? Auto Spectate: ' .. (CONFIG.AUTO_SPECTATE_ENABLED and 'ON (Random)' or 'OFF'), CONFIG.AUTO_SPECTATE_ENABLED and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50), CONFIG.AUTO_SPECTATE_ENABLED and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        if CONFIG.AUTO_SPECTATE_ENABLED then
            ORIGINAL_SPECTATOR_COUNT = CONFIG.SPECTATOR_COUNT
            startAutoSpectate()
            if HintApp then HintApp:hint({ text = 'Auto Spectate ON! Range: ' .. (ORIGINAL_SPECTATOR_COUNT + CONFIG.SPECTATOR_VARIATION_MIN) .. '-' .. (ORIGINAL_SPECTATOR_COUNT + CONFIG.SPECTATOR_VARIATION_MAX), length = 3, overridable = true }) end
        else
            stopAutoSpectate()
            if HintApp then HintApp:hint({ text = 'Auto Spectate OFF', length = 2, overridable = true }) end
        end
    end)
end

--==================== TOOLS TAB CONTENT ====================
local function setupToolsDialogTab()
    local deleteButton = Instance.new("TextButton")
    deleteButton.Size, deleteButton.Position, deleteButton.Text, deleteButton.Font, deleteButton.TextSize, deleteButton.BackgroundColor3, deleteButton.TextColor3, deleteButton.Parent = UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), "🗑️ Delete All Pets", Enum.Font.GothamBold, 9, Color3.fromRGB(180, 60, 60), Color3.fromRGB(255, 255, 255), toolsPanel
    Instance.new("UICorner", deleteButton).CornerRadius = UDim.new(0, 8)
    
    deleteButton.MouseButton1Click:Connect(function()
        local count = DeleteAllSpawnedPets()
        deleteButton.Text = "✓ DELETED " .. count .. "!"
        task.wait(1)
        deleteButton.Text = "🗑️ Delete All Pets"
    end)

    local scaleLabel = Instance.new("TextLabel")
    scaleLabel.Size, scaleLabel.Position, scaleLabel.BackgroundTransparency, scaleLabel.Text = UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, 52), 1, "📏 UI Scale (70% default)"
    scaleLabel.Font, scaleLabel.TextSize, scaleLabel.TextColor3, scaleLabel.Parent = Enum.Font.Gotham, 7, Color3.fromRGB(160, 170, 200), toolsPanel

    local scaleControls = Instance.new("Frame")
    scaleControls.Size, scaleControls.Position, scaleControls.BackgroundTransparency, scaleControls.Parent = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 63), 1, toolsPanel
    
    local scaleDown = Instance.new("TextButton")
    scaleDown.Size, scaleDown.Position, scaleDown.BackgroundColor3, scaleDown.Text, scaleDown.Font, scaleDown.TextSize, scaleDown.TextColor3, scaleDown.Parent = UDim2.new(0.2, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(150, 50, 50), "−", Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), scaleControls
    Instance.new("UICorner", scaleDown).CornerRadius = UDim.new(0, 6)

    local scaleValue = Instance.new("TextLabel")
    scaleValue.Size, scaleValue.Position, scaleValue.BackgroundColor3, scaleValue.Text, scaleValue.Font, scaleValue.TextSize, scaleValue.TextColor3, scaleValue.Parent = UDim2.new(0.5, 0, 1, 0), UDim2.new(0.25, 0, 0, 0), Color3.fromRGB(32, 36, 58), "70%", Enum.Font.GothamBold, 9, Color3.fromRGB(240, 240, 255), scaleControls
    Instance.new("UICorner", scaleValue).CornerRadius = UDim.new(0, 4)

    local scaleUp = Instance.new("TextButton")
    scaleUp.Size, scaleUp.Position, scaleUp.BackgroundColor3, scaleUp.Text, scaleUp.Font, scaleUp.TextSize, scaleUp.TextColor3, scaleUp.Parent = UDim2.new(0.2, 0, 1, 0), UDim2.new(0.8, 0, 0, 0), Color3.fromRGB(50, 150, 50), "+", Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), scaleControls
    Instance.new("UICorner", scaleUp).CornerRadius = UDim.new(0, 6)

    local resetScale = Instance.new("TextButton")
    resetScale.Size, resetScale.Position, resetScale.Text, resetScale.Font, resetScale.TextSize, resetScale.BackgroundColor3, resetScale.TextColor3, resetScale.Parent = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 88), "↪️ Reset to 70%", Enum.Font.GothamBold, 8, Color3.fromRGB(100, 100, 180), Color3.fromRGB(255, 255, 255), toolsPanel
    Instance.new("UICorner", resetScale).CornerRadius = UDim.new(0, 6)

    local lockButton = Instance.new("TextButton")
    lockButton.Size, lockButton.Position, lockButton.Text, lockButton.Font, lockButton.TextSize, lockButton.BackgroundColor3, lockButton.TextColor3, lockButton.Parent = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 113), "🔓 Unlocked", Enum.Font.GothamBold, 8, Color3.fromRGB(150, 150, 50), Color3.fromRGB(255, 255, 255), toolsPanel
    Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 6)

    scaleDown.MouseButton1Click:Connect(function() UIState.currentScale = math.max(0.7, UIState.currentScale - 0.05); uiScale.Scale = UIState.currentScale; if HintApp then HintApp:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', UIState.currentScale * 100), length = 1, overridable = true }) end end)
    scaleUp.MouseButton1Click:Connect(function() UIState.currentScale = math.min(1.3, UIState.currentScale + 0.05); uiScale.Scale = UIState.currentScale; if HintApp then HintApp:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', UIState.currentScale * 100), length = 1, overridable = true }) end end)
    resetScale.MouseButton1Click:Connect(function() UIState.currentScale = 0.7; uiScale.Scale = UIState.currentScale; scaleValue.Text = "70%" end)
    
    lockButton.MouseButton1Click:Connect(function()
        UIState.uiLocked = not UIState.uiLocked
        lockButton.Text = UIState.uiLocked and "🔒 Locked" or "🔓 Unlocked"
        lockButton.BackgroundColor3 = UIState.uiLocked and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 150, 50)
    end)

    -- Custom Dialog Message Editor
    local dialogMessageHeading = Instance.new("TextLabel")
    dialogMessageHeading.Size, dialogMessageHeading.Position, dialogMessageHeading.BackgroundTransparency, dialogMessageHeading.Text = UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 113), 1, "💬 Custom Dialog Message:"
    dialogMessageHeading.Font, dialogMessageHeading.TextSize, dialogMessageHeading.TextColor3, dialogMessageHeading.TextXAlignment, dialogMessageHeading.Parent = Enum.Font.GothamBold, 11, Color3.fromRGB(235, 240, 255), Enum.TextXAlignment.Left, toolsPanel

    local dialogMessageBox = Instance.new("TextBox")
    dialogMessageBox.Size, dialogMessageBo.Position, dialogMessageBox.BackgroundColor3, dialogMessageBox.BackgroundTransparency, dialogMessageBox.Text, dialogMessageBox.PlaceholderText, dialogMessageBox.Font, dialogMessageBox.TextSize, dialogMessageBox.TextColor3, dialogMessageBox.ClearTextOnFocus, dialogMessageBox.TextWrapped, dialogMessageBox.Parent = UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 125), Color3.fromRGB(32, 36, 58), 0.2, UIState.currentDialogMessage, "Enter custom dialog message...", Enum.Font.Gotham, 11, Color3.fromRGB(255, 255, 255), false, true, toolsPanel
    Instance.new("UICorner", dialogMessageBox).CornerRadius = UDim.new(0, 6)

    local applyButton = Instance.new("TextButton")
    applyButton.Size, applyButton.Position, applyButton.Text, applyButton.Font, applyButton.TextSize, applyButton.BackgroundColor3, applyButton.TextColor3, applyButton.Parent = UDim2.new(0.48, 0, 0, 26), UDim2.new(0, 0, 0, 180), "Apply", Enum.Font.FredokaOne, 11, Color3.fromRGB(30, 170, 80), Color3.fromRGB(255, 255, 255), toolsPanel
    Instance.new("UICorner", applyButton).CornerRadius = UDim.new(0, 6)

    local revertButton = Instance.new("TextButton")
    revertButton.Size, revertButton.Position, revertButton.Text, revertButton.Font, revertButton.TextSize, revertButton.BackgroundColor3, revertButton.TextColor3, revertButton.Parent = UDim2.new(0.48, 0, 0, 26), UDim2.new(0.52, 0, 0, 180), "Revert", Enum.Font.FredokaOne, 11, Color3.fromRGB(170, 30, 30), Color3.fromRGB(255, 255, 255), toolsPanel
    Instance.new("UICorner", revertButton).CornerRadius = UDim.new(0, 6)

    applyButton.MouseButton1Click:Connect(function()
        local newMessage = dialogMessageBox.Text
        if newMessage ~= "" then
            UIState.currentDialogMessage = newMessage
            local oldText = applyButton.Text
            applyButton.Text = "? Applied!"
            applyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            task.wait(1)
            applyButton.Text = oldText
            applyButton.BackgroundColor3 = Color3.fromRGB(30, 170, 80)
            print("Dialog message updated to: " .. UIState.currentDialogMessage)
        end
    end)

    revertButton.MouseButton1Click:Connect(function()
        UIState.currentDialogMessage = "ZetaScripts gave you: " -- Reset to default
        dialogMessageBox.Text = UIState.currentDialogMessage
        local oldText = revertButton.Text
        revertButton.Text = "? Reverted!"
        revertButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        task.wait(1)
        revertButton.Text = "Revert"
        revertButton.BackgroundColor3 = Color3.fromRGB(170, 30, 30)
        print("Dialog message reverted to original")
    end)

    -- Dialog Message Presets
    local presetsHeading = Instance.new("TextLabel")
    presetsHeading.Size, presetsHeading.Position, presetsHeading.BackgroundTransparency, presetsHeading.Text = UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 215), 1, "Presets:"
    presetsHeading.Font, presetsHeading.TextSize, presetsHeading.TextColor3, presetsHeading.TextXAlignment, presetsHeading.Parent = Enum.Font.FredokaOne, 10, Color3.fromRGB(200, 200, 255), Enum.TextXAlignment.Left, toolsPanel

    local presetsScroll = Instance.new("ScrollingFrame")
    presetsScroll.Size, presetsScroll.Position, presetsScroll.BackgroundColor3, presetsScroll.BackgroundTransparency, presetsScroll.ScrollBarThickness, presetsScroll.ScrollBarImageColor3, presetsScroll.ScrollBarImageTransparency, presetsScroll.Parent = UDim2.new(1, 0, 0, 100), UDim2.new(0, 0, 0, 233), Color3.fromRGB(40, 40, 50), 0.2, 6, Color3.fromRGB(100, 100, 100), 0.5, toolsPanel
    Instance.new("UICorner", presetsScroll).CornerRadius = UDim.new(0, 6)
    local scrollStroke = Instance.new("UIStroke")
    scrollStroke.Color, scrollStroke.Thickness, scrollStroke.Transparency, scrollStroke.Parent = Color3.fromRGB(120, 0, 255), 2, 0.3, presetsScroll
    
    local presetsLayout = Instance.new("UIListLayout")
    presetsLayout.Padding, presetsLayout.SortOrder, presetsLayout.Parent = UDim.new(0, 5), Enum.SortOrder.LayoutOrder, presetsScroll

    local presets = {
        "Adopt Me! Has partnered with Starpets and given you:",
        "Thank you for buying from the tropicaljules shop! Heres your pet:",
        "JesseRaen and NewFissy have given you a PERMANENT:",
        "ZetaScripts gave you: " -- Default message
    }
    table.insert(presets, 1, "Adopt Me! Has partnered with Starpets and given you:") -- Ensure default is first

    for i, presetText in ipairs(presets) do
        local presetButton = Instance.new("TextButton")
        presetButton.Size, presetButton.Position, presetButton.Text, presetButton.Font, presetButton.TextSize, presetButton.TextColor3, presetButton.BackgroundColor3, presetButton.AutoButtonColor, presetButton.TextWrapped, presetButton.LayoutOrder, presetButton.Parent = UDim2.new(0.95, 0, 0, 40), UDim2.new(0, 5, 0, (i-1)*45), presetText, Enum.Font.FredokaOne, 9, Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 60, 80), true, true, i
        Instance.new("UICorner", presetButton).CornerRadius = UDim.new(0, 6)
        
        presetButton.MouseButton1Click:Connect(function()
            dialogMessageBox.Text = presetText
        end)
    end
    
    task.spawn(function() -- Update canvas size
        wait()
        presetsScroll.CanvasSize = UDim2.new(0, 0, 0, presetsLayout.AbsoluteContentSize.Y)
    end)
end

--==================== GLOBAL FUNCTIONS ====================
_G.createPet = function(petId, properties)
    local item = CreateInventoryItem(petId, "pets", properties)
    if item then
        print("Created pet:", item.data.properties.rp_name or item.data.kind)
    else
        warn("Failed to create pet.")
    end
end

_G.createToy = function(toyName, properties)
    local toyId, category = FindItemId(toyName)
    if toyId and category == "toys" then
        local item = CreateInventoryItem(toyId, "toys", properties)
        if item then
            print("Created toy:", item.data.kind)
        else
            warn("Failed to create toy.")
        end
    else
        warn("Toy not found:", toyName)
    end
end

_G.equipPet = function(petData)
    EquipPet(petData)
end

_G.unequipPet = function(petData)
    UnequipPet(petData)
end

_G.GetPetByName = function(petName)
    return FindPetId(petName)
end

_G.GetToyByName = function(toyName)
    return FindToyId(toyName)
end

--==================== INITIALIZATION ====================
local function initializeSuite()
    SwitchTab(UIState.currentTab) -- Set initial tab visibility
    
    -- Populate tabs with content
    setupSpawnerTab()
    setupTradeSimTab()
    setupToolsDialogTab()

    -- Add event listeners for UI elements
    
    -- Initialize town list etc if needed
    
    print("ZetaScripts Preppy Suite Loaded!")
end

initializeSuite()

--==================== DRAGGING & CLOSING ====================
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if not UIState.uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == UIState.keybinds.toggleUI then
        mainFrame.Visible = not mainFrame.Visible
    end

    -- Handle keybind input for setting new keybinds
    if UIState.waitingForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.Escape then
            local button = UIState.keybindButtons[UIState.waitingForKeybind]
            if button then button.Text = UIState.keybinds[UIState.waitingForKeybind].Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
            UIState.waitingForKeybind = nil
            return
        end
        UIState.keybinds[UIState.waitingForKeybind] = key
        local button = UIState.keybindButtons[UIState.waitingForKeybind]
        if button then button.Text = key.Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
        UIState.waitingForKeybind = nil
        if HintApp then HintApp:hint({ text = 'Keybind set to ' .. key.Name, length = 2, overridable = true }) end
        return
    end
    
    -- Handle keybind actions
    if input.UserInputType == Enum.UserInputType.Keyboard and not UIState.waitingForKeybind then
        local key = input.KeyCode
        
        if key == UIState.keybinds.selectPartner then
            pcall(function()
                local partner = nil
                if UIState.mockState.active and UIState.mockState.trade then
                    partner = UIState.mockState.trade.recipient
                else
                    partner = TradeApp:_get_partner()
                end
                if partner and partner.Name then
                    partnerBox.Text = partner.Name
                    updatePartnerFromUsername(partner.Name)
                    if HintApp then HintApp:hint({ text = 'Partner set to ' .. partner.Name, length = 2, overridable = true }) end
                end
            end)
        end
        
        if key == UIState.keybinds.addRandomItem then
            if UIState.mockState.active then addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties()) end
        end
        
        if key == UIState.keybinds.startTrade then
            if not UIState.mockState.active then
                task.spawn(startMockTradeDirectly)
            end
        end
        
        if key == UIState.keybinds.blockPlayer then
            local player = Players:FindFirstChild(partnerBox.Text)
            if player then BlockPlayer(player) end
        end
    end
end)

-- Close popups when clicking outside
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = input.Position
        
        -- Check pet list
        if petListFrame.Visible then
            local listAbsPos = petListFrame.AbsolutePosition
            local listSize = petListFrame.AbsoluteSize
            local mainAbsPos = mainFrame.AbsolutePosition
            local mainSize = mainFrame.AbsoluteSize
            
            local isInPetList = (mousePos.X >= listAbsPos.X and mousePos.X <= listAbsPos.X + listSize.X and
                               mousePos.Y >= listAbsPos.Y and mousePos.Y <= listAbsPos.Y + listSize.Y)
            
            local isInMainFrame = (mousePos.X >= mainAbsPos.X and mousePos.X <= mainAbsPos.X + mainSize.X and
                                 mousePos.Y >= mainAbsPos.Y and mousePos.Y <= mainAbsPos.Y + mainSize.Y)
            
            if not isInPetList and not isInMainFrame then
                petListFrame.Visible = false
            end
        end
        
        -- Check toy list (if implemented)
        -- ...
    end
end)

-- Initial population of lists
refreshPlayerList()
refreshRichestPlayers(true)

-- Auto-start systems
task.spawn(function()
    task.wait(1)
    local success, err = pcall(function()
        -- Hooking game systems
        local oldIdentity = get_thread_identity and get_thread_identity() or 8
        set_thread_identity(2)
        
        -- Hook TradeApp functions
        local tradeApp = UIManager.apps.TradeApp
        if tradeApp then
            if tradeApp._get_local_trade_state then tradeApp._ORIGINAL_get_local_trade_state = tradeApp._get_local_trade_state end
            if tradeApp._overwrite_local_trade_state then tradeApp._ORIGINAL_overwrite_local_trade_state = tradeApp._overwrite_local_trade_state end
            if tradeApp._change_local_trade_state then tradeApp._ORIGINAL_change_local_trade_state = tradeApp._change_local_trade_state end
            if tradeApp._add_item_to_my_offer then tradeApp._ORIGINAL_add_item_to_my_offer = tradeApp._add_item_to_my_offer end
            if tradeApp._remove_item_from_my_offer then tradeApp._ORIGINAL_remove_item_from_my_offer = tradeApp._remove_item_from_my_offer end
            if tradeApp._on_accept_pressed then tradeApp._ORIGINAL_on_accept_pressed = tradeApp._on_accept_pressed end
            if tradeApp._on_confirm_pressed then tradeApp._ORIGINAL_on_confirm_pressed = tradeApp._on_confirm_pressed end
            if tradeApp._on_unaccept_pressed then tradeApp._ORIGINAL_on_unaccept_pressed = tradeApp._on_unaccept_pressed end
            if tradeApp._decline_trade then tradeApp._ORIGINAL_decline_trade = tradeApp._decline_trade end
            if tradeApp._evaluate_trade_fairness then tradeApp._ORIGINAL_evaluate_trade_fairness = tradeApp._evaluate_trade_fairness end
            if tradeApp._lock_trade_for_appropriate_time then tradeApp._ORIGINAL_lock_trade_for_appropriate_time = tradeApp._lock_trade_for_appropriate_time end
            if tradeApp._get_lock_time then tradeApp._ORIGINAL_get_lock_time = tradeApp._get_lock_time end
            if tradeApp._set_confirmation_arrow_rotating then tradeApp._ORIGINAL_set_confirmation_arrow_rotating = tradeApp._set_confirmation_arrow_rotating end
        end

        -- Hook TradeHistoryApp functions
        local tradeHistoryApp = UIManager.apps.TradeHistoryApp
        if tradeHistoryApp then
            if tradeHistoryApp._create_trade_frame then tradeHistoryApp._ORIGINAL_create_trade_frame = tradeHistoryApp._create_trade_frame end
            if tradeHistoryApp.report_scam then tradeHistoryApp._ORIGINAL_report_scam = tradeHistoryApp.report_scam end
            if tradeHistoryApp._get_trade_history then tradeHistoryApp._ORIGINAL_get_trade_history = tradeHistoryApp._get_trade_trade_history end
        end
        
        -- Hook DialogApp
        if UIManager.apps.DialogApp and UIManager.apps.DialogApp.dialog then
            UIState.mockState.originalDialogFunction = UIManager.apps.DialogApp.dialog
        end
        
        -- Hook Other Modules
        hookTradeFunctions()
        hookTradeHistoryFunctions()
        hookDialogApp()
        hookTradeRequestEvent()
        
        set_thread_identity(oldIdentity)
        print("Game systems hooked successfully.")
    end)
    if err then warn("Error hooking game systems:", err) end
end)

--==================== DRAGGING SYSTEM ====================
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if not UIState.uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--==================== KEYBIND INPUT HANDLER ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle UI visibility
    if input.KeyCode == UIState.keybinds.toggleUI then
        mainFrame.Visible = not mainFrame.Visible
        return
    end
    
    -- Handle keybind input for setting new keybinds
    if UIState.waitingForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.Escape then
            local button = UIState.keybindButtons[UIState.waitingForKeybind]
            if button then button.Text = UIState.keybinds[UIState.waitingForKeybind].Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
            UIState.waitingForKeybind = nil
            return
        end
        UIState.keybinds[UIState.waitingForKeybind] = key
        local button = UIState.keybindButtons[UIState.waitingForKeybind]
        if button then button.Text = key.Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
        UIState.waitingForKeybind = nil
        if HintApp then HintApp:hint({ text = 'Keybind set to ' .. key.Name, length = 2, overridable = true }) end
        return
    end
    
    -- Handle keybind actions
    if input.UserInputType == Enum.UserInputType.Keyboard and not UIState.waitingForKeybind then
        local key = input.KeyCode
        
        if key == UIState.keybinds.selectPartner then
            pcall(function()
                local partner = nil
                if UIState.mockState.active and UIState.mockState.trade then
                    partner = UIState.mockState.trade.recipient
                else
                    partner = TradeApp:_get_partner()
                end
                if partner and partner.Name then
                    partnerBox.Text = partner.Name
                    updatePartnerFromUsername(partner.Name)
                    if HintApp then HintApp:hint({ text = 'Partner set to ' .. partner.Name, length = 2, overridable = true }) end
                end
            end)
        end
        
        if key == UIState.keybinds.addRandomItem then
            if UIState.mockState.active then addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties()) end
        end
        
        if key == UIState.keybinds.startTrade then
            if not UIState.mockState.active then
                task.spawn(startMockTradeDirectly)
            end
        end
        
        if key == UIState.keybinds.blockPlayer then
            local player = Players:FindFirstChild(partnerBox.Text)
            if player then BlockPlayer(player) end
        end
    end
end)

--==================== INITIAL POPULATION ====================
SwitchTab(UIState.currentTab) -- Set initial tab visibility
setupSpawnerTab()
setupTradeSimTab()
setupToolsDialogTab()

--==================== INITIAL SETUP ====================
if UIState.activeTabPulseTween == nil then
    local data = UIState.tabButtons[UIState.currentTab]
    if data then
        UIState.activeTabPulseTween = TweenService:Create(data.stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Color = data.stroke.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.25), Thickness = 1.5
        })
        UIState.activeTabPulseTween:Play()
    end
end

task.wait(3)
refreshRichestPlayers(true)

--==================== AUTO PARTNER EMOJI ====================
_G.EmojiSystem = {
    running = false,
    reactions = load('SharedConstants').trade_spectate_reactions
}

_G.EmojiSystem.display = function(index)
    if not _G.EmojiSystem.reactions[index] then return end
    if not UIState.mockState.active or not UIState.mockState.trade then return end
    
    pcall(function()
        local tradeFrame = Players.LocalPlayer.PlayerGui.TradeApp.Frame
        local e = Instance.new('ImageLabel')
        e.Image, e.BackgroundTransparency, e.ImageTransparency, e.Size, e.Position, e.AnchorPoint, e.ZIndex, e.Parent = _G.EmojiSystem.reactions[index], 1, 1, UDim2.fromOffset(40, 40), UDim2.new(0.92 + math.random(-3, 3) / 100, 0, 0.95, 0), Vector2.new(0.5, 1), 100, tradeFrame
        
        TweenService:Create(e, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            ImageTransparency = 0, Size = UDim2.fromOffset(45, 45)
        }):Play()
        
        local st, dur, spd = tick(), math.random(18, 28) / 10, 0.18
        local c
        c = RunService.Heartbeat:Connect(function(dt)
            local el = tick() - st
            if el >= dur or not e.Parent then c:Disconnect(); if e.Parent then e:Destroy() end return end
            local newY = e.Position.Y.Scale - spd * dt
            local drift = math.sin(el * 4) * dt * 0.0
            e.Position = UDim2.new(math.clamp(e.Position.X.Scale + drift, 0.85, 0.98), 0, newY, 0)
            if el >= dur * 0.5 then e.ImageTransparency = (el - dur * 0.5) / (dur * 0.5) end
        end)
    end)
end

local emojiButton = Instance.new('TextButton')
emojiButton.Size, emojiButton.Position, emojiButton.BackgroundColor3, emojiButton.BackgroundTransparency, emojiButton.Text, emojiButton.Font, emojiButton.TextSize, emojiButton.TextColor3, emojiButton.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 263), Color3.fromRGB(150, 50, 50), '? Auto Partner Emoji: OFF', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), toolsPanel
Instance.new('UICorner', emojiButton).CornerRadius = UDim.new(0, 6)

emojiButton.MouseButton1Click:Connect(function()
    _G.EmojiSystem.running = not _G.EmojiSystem.running
    emojiButton.Text = '? Auto Partner Emoji: ' .. (_G.EmojiSystem.running and 'ON' or 'OFF')
    emojiButton.BackgroundColor3 = _G.EmojiSystem.running and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    
    if _G.EmojiSystem.running then
        task.spawn(function()
            while _G.EmojiSystem.running do
                task.wait(math.random(8, 20) / 10)
                if _G.EmojiSystem.running and UIState.mockState.active and UIState.mockState.trade then
                    _G.EmojiSystem.display(math.random(1, #_G.EmojiSystem.reactions))
                end
            end
        end)
    end
end)

--==================== FINALIZATION ====================
print("ZetaScripts Preppy Suite Loaded!")
   TradeApp = UIManager.apps.TradeApp,
   DialogApp = UIManager.apps.DialogApp,
   HintApp = UIManager.apps.HintApp,
   BackpackApp = UIManager.apps.BackpackApp,
   PlayerProfileApp = UIManager.apps.PlayerProfileApp,
   TradeHistoryApp = UIManager.apps.TradeHistoryApp,
   SettingsApp = UIManager.apps.SettingsApp,
}
local UIManager = Modules.UIManager
local ClientData = Modules.ClientData
local TableUtil = Modules.TableUtil
local RouterClient = Modules.RouterClient
local InventoryDB = Modules.InventoryDB
local ColorThemeManager = Modules.ColorThemeManager
local animationManager = Modules.animationManager
local downloader = Modules.DownloadClient
local PetRigs = Modules.PetRigs
local AilmentsClient = Modules.AilmentsClient
local AilmentsDB = Modules.AilmentsDB
local CharWrapperClient = Modules.CharWrapperClient
local SettingsHelper = Modules.SettingsHelper
local FamilyHelper = Modules.FamilyHelper
local InteractionsEngine = Modules.InteractionsEngine
local TradeApp = Modules.TradeApp
local DialogApp = Modules.DialogApp
local HintApp = Modules.HintApp
local BackpackApp = Modules.BackpackApp
local PlayerProfileApp = Modules.PlayerProfileApp
local TradeHistoryApp = Modules.TradeHistoryApp
local SettingsApp = Modules.SettingsApp

if UIManager.wait_for_initialization then UIManager:wait_for_initialization() else task.wait(2) end

-- ==================== GLOBAL CONFIGURATION ====================
local CONFIG = {
    PARTNER_NAME = 'RobyPolarBearYT',
    PARTNER_USER_ID = 987654321, -- Placeholder, will be updated by player name lookup
    AUTO_ACCEPT_DELAY = 0.2,
    AUTO_CONFIRM_DELAY = 0.3,
    SPECTATOR_COUNT = 4,
    SPECTATOR_VARIATION_MIN = -1,
    SPECTATOR_VARIATION_MAX = 2,
    AUTO_SPECTATE_ENABLED = false,
    AUTO_SPECTATE_INTERVAL = 1.5,
    AUTO_PARTNER = true,
    NEGOTIATION_LOCK = 5,
    CONFIRMATION_LOCK_PER_ITEM = 3,
    SHOW_TRADE_REQUEST = true,
    TRADE_REQUEST_DELAY = 0,
    ADD_PET_REQUEST_DELAY = 0.5,
    SPAWN_FAKE_PLAYER_WITH_RANDOM_PET = false,
    FAKE_PLAYER_ACCEPT_TRADE_REQUEST = 2,
    CHAT_MESSAGES = {
        'Ucciditi?', 'Obeso fai schifo regalami i tuoi pet', 'Aggiungi coglione??', 'Negro di merda', 'frocio succhiami il cazzo', 'Tutti a mettere il follow?',
        'Respinna ti prego?', 'balena', 'aggiungi o ti declino lo scambio coglione', 'abiti a Venezia vero?', 'è finita per te',
        'Can i get mega pet', 'Disabile', 'Hai 10 secondi per darmi i pet', '5 secondi da adesso',
        'sei da solo a casa?', 'frocetto sto arrivando a casa tua, ora uccido tutti i tuoi parenti',
    },
    AUTO_CHAT_DELAY = 2,
    VERIFIED_FRIENDS = {
        'Agusmareborn', 'Kellyvault', 'J3llynoah', 'Rainbowriley321',
        'Bobazmalibu', 'H3llSANG3LX', 'Xcallmeholly', 'Niniko_201999',
    },
    SHOW_VERIFIED_FRIEND = false,
    FRIEND_PARTNER = true,
    REMOVE_PARTNER_PETS_ON_CONFIRM = false,
}
local ORIGINAL_SPECTATOR_COUNT = CONFIG.SPECTATOR_COUNT

-- ==================== MOCK TRADE STATE ====================
local mockState = {
   active = false, trade = nil, isAddingItem = false, partnerActionPending = false,
   tradeCompleting = false, scamWarningShown = true, originalFunctions = {},
   blockedTradeRequests = {}, tradeHistory = {}, addedTradeIds = {},
   pendingTradeRequest = false, canShowTradeRequest = true,
   removePartnerPetsOnConfirm = false, partnerPetsBeforeConfirm = {},
   isMockTradeDialog = false,
}

-- ==================== PET SPAWNER/VALUE STATE ====================
local petSpawnState = {
   activeFlags = { M = false, N = false, F = false, R = false },
   validPetNames = {}, validPetNamesClean = {},
}
local FakePetRegistry = {}
local FakePlayers = {}
local fakePlayerIds = {}
_G.fakePlayerIds = fakePlayerIds

local petModelsCache = {}
local function getPetModel(kind)
   if petModelsCache[kind] then return petModelsCache[kind]:Clone() end
   local success, model = pcall(function()
       local promise = downloader.promise_download_copy('Pets', kind)
       if promise then return promise:expect() end
       return nil
   end)
   if success and model then
       petModelsCache[kind] = model
       return model:Clone()
   else
       warn('Failed to download pet model for:', kind)
       return nil
   end
end

local function applyMegaNeonEffects(petModel, kind)
   local petData = InventoryDB.pets[kind]
   if not petData or not petData.neon_parts then return end
   for neonPart, configuration in pairs(petData.neon_parts) do
       local geoPart = PetRigs.get(petModel).get_geo_part(petModel, neonPart)
       if geoPart then
           geoPart.Material = Enum.Material.Neon
           local originalColor = configuration.Color or Color3.fromRGB(170, 0, 255)
           local h, s, v = originalColor:ToHSV()
           geoPart.Color = Color3.fromHSV(h, math.min(s * 1.3, 1), math.min(v * 1.4, 1))
       end
   end
end

local function applyNeonEffects(petModel, kind)
   local petData = InventoryDB.pets[kind]
   if not petData or not petData.neon_parts then return end
   for neonPart, configuration in pairs(petData.neon_parts) do
       local geoPart = PetRigs.get(petModel).get_geo_part(petModel, neonPart)
       if geoPart then
           geoPart.Material = Enum.Material.Neon
           if configuration.Color then geoPart.Color = configuration.Color end
       end
   end
end

local AnimationManager = { running = false, checkInterval = 0.3, animationTracks = {}, get_track = function(animName) return animationManager.animationTracks[animName] end }
AnimationManager.animationTracks['PlayerRidingPet'] = Instance.new('Animation')
AnimationManager.animationTracks['PlayerRidingPet'].AnimationId = 'rbxassetid://507766666'

function AnimationManager:Start()
   if self.running then return end
   self.running = true
   task.spawn(function()
       while self.running do
           task.wait(self.checkInterval)
           for _, petData in ipairs(FakePetRegistry) do
               if petData and petData.model and petData.model.Parent then
                   pcall(function()
                       local character = petData.character
                       if character and character.Parent then
                           local humanoid = character:FindFirstChild('Humanoid')
                           if humanoid and humanoid.Animator then
                               local isRiding = false
                               for _, track in ipairs(humanoid.Animator:GetPlayingAnimationTracks()) do
                                   if track.Animation.AnimationId:find('PlayerRidingPet') then isRiding = true break end
                               end
                               if not isRiding and petData.hasRidingPet then
                                   if not petData.ridingAnim or not petData.ridingAnim.IsPlaying then
                                       if petData.ridingAnim then petData.ridingAnim:Stop() end
                                       petData.ridingAnim = humanoid.Animator:LoadAnimation(self.get_track('PlayerRidingPet'))
                                       petData.ridingAnim.Looped = true
                                       petData.ridingAnim:Play()
                                       humanoid.Sit = true
                                   end
                               end
                           end
                       end
                       if petData.wrapper.mega_neon then applyMegaNeonEffects(petData.model, petData.wrapper.pet_id)
                       elseif petData.wrapper.neon then applyNeonEffects(petData.model, petData.wrapper.pet_id) end
                   end)
               end
           end
       end
   end)
end

function AnimationManager:Stop()
   self.running = false
   for _, petData in ipairs(FakePetRegistry) do if petData.ridingAnim then petData.ridingAnim:Stop() end end
end

function AnimationManager:AddPet(petData)
   table.insert(FakePetRegistry, petData)
   if not self.running then self:Start() end
end

local function updateData(key, action)
   local data = ClientData.get(key)
   local clonedData = table.clone(data)
   ClientData.predict(key, action(clonedData))
end

local function createFakePetOwner(fakeCharacter, partnerName, partnerId)
   return setmetatable({
       Name = partnerName, DisplayName = partnerName, UserId = partnerId, Character = fakeCharacter,
   }, {
       __index = function(t, k)
           if k == 'Parent' then return Players end
           if k == 'IsA' then return function(self, className) return className == 'Player' end end
           if k == 'GetChildren' then return function() return {} end end
           return rawget(t, k)
       end,
       __tostring = function() return partnerName end
   })
end

function OpenProfile(Id)
   if UIManager.apps.PlayerProfileApp then UIManager.apps.PlayerProfileApp:open_player_profile_for_user_id(Id) end
end

task.spawn(function()
   task.wait(0.1)
   local InteractionsEngine = load('InteractionsEngine')
   local original_register = InteractionsEngine.register
   InteractionsEngine.register = function(self, interactionData)
       if interactionData and interactionData.part then
           local checkPart = interactionData.part
           while checkPart do
               if checkPart:GetAttribute('IsFakePet') == true and checkPart.Parent then return end
               checkPart = checkPart.Parent
           end
       end
       return original_register(self, interactionData)
   end
end)

local function GetKindPet(name)
   for k, v in pairs(InventoryDB.pets) do
       if v['name']:lower() == name:lower() then return k end
   end
end

local function enableNoclip(character)
   if not character then return end
   for _, part in ipairs(character:GetDescendants()) do
       if part:IsA('BasePart') then
           part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
           pcall(function() part.CollisionGroup = 'Noclip' end)
       end
   end
   character.DescendantAdded:Connect(function(descendant)
       if descendant:IsA('BasePart') then
           task.wait()
           descendant.CanCollide = false; descendant.CanTouch = false; descendant.CanQuery = false
           pcall(function() descendant.CollisionGroup = 'Noclip' end)
       end
   end)
end

local function enableNoclipForAllFakePlayers()
   for _, folder in ipairs(FakePlayers) do
       if folder and folder.Parent then
           for _, child in ipairs(folder:GetChildren()) do
               if child:IsA('Model') then enableNoclip(child) end
           end
       end
   end
end

local function enableNoclipForPets()
   for _, petData in ipairs(FakePetRegistry) do
       if petData and petData.model and petData.model.Parent then enableNoclip(petData.model) end
   end
end

local function GetPetByName(name)
   for id, info in pairs(InventoryDB.pets) do
       if info.name:lower() == name:lower() then return id end
   end
   return nil
end

-- ==================== MOCK TRADE FUNCTIONS ====================
local function createMockPartner(player)
   local partnerName = player and player.Name or CONFIG.PARTNER_NAME
   local partnerDisplayName = player and player.DisplayName or CONFIG.PARTNER_NAME
   local partnerUserId = player and player.UserId or CONFIG.PARTNER_USER_ID
   return setmetatable({
       Name = partnerName, DisplayName = partnerDisplayName, UserId = partnerUserId, ClassName = 'Player', Character = nil,
       Team = nil, TeamColor = BrickColor.new('White'), Neutral = true, AccountAge = 365, MembershipType = Enum.MembershipType.None,
       CharacterAdded = Instance.new('BindableEvent'), CharacterRemoving = Instance.new('BindableEvent'),
   }, {
       __index = function(t, k)
           if k == 'Parent' then return Players end
           if k == 'IsA' then return function(self, className) return className == 'Player' or className == 'Instance' end end
           if k == 'GetAttribute' then return function() return nil end end
           if k == 'FindFirstChild' then return function() return nil end end
           if k == 'WaitForChild' then return function() return nil end end
           return rawget(t, k)
       end,
       __tostring = function() return partnerName end,
       __eq = function(a, b)
           if type(b) == 'table' then return rawget(a, 'UserId') == rawget(b, 'UserId') end
           return false
       end,
   })
end
local mockPartner = createMockPartner()

local function createMockTrade(realPlayer)
   local partner = realPlayer and createMockPartner(realPlayer) or mockPartner
   local hasLicense = true
   if realPlayer then
       local success, licensed = pcall(function() return checkTradeLicense(realPlayer) end)
       hasLicense = success and licensed or true
   end
   return {
       trade_id = 'MOCK_' .. tick(), sender = Players.LocalPlayer, recipient = partner,
       sender_offer = { items = {}, player_name = Players.LocalPlayer.Name, negotiated = false, confirmed = false },
       recipient_offer = { items = {}, player_name = CONFIG.PARTNER_NAME, negotiated = false, confirmed = false },
       current_stage = 'negotiation', offer_version = 1,
       sender_has_trade_license = true, recipient_has_trade_license = hasLicense,
       busy_indicators = {}, subscriber_count = CONFIG.SPECTATOR_COUNT,
   }
end

local function createTradeHistoryRecord(trade)
   return {
       trade_id = trade.trade_id, timestamp = os.time(),
       sender_user_id = Players.LocalPlayer.UserId, sender_name = Players.LocalPlayer.Name,
       sender_items = TableUtil.deep_copy(trade.sender_offer.items),
       recipient_user_id = trade.recipient.UserId, recipient_name = CONFIG.PARTNER_NAME,
       recipient_items = TableUtil.deep_copy(trade.recipient_offer.items),
       reported = false, reverted = nil,
   }
end
local function appendToTradeHistory(tradeRecord)
   if mockState.addedTradeIds[tradeRecord.trade_id] then return end
   mockState.addedTradeIds[tradeRecord.trade_id] = true
   table.insert(mockState.tradeHistory, tradeRecord)
end

local function fetchPetValues()
   local success, response = pcall(function()
       return request({
           Url = "https://elvebredd.com/api/pets/get-latest", Method = "GET",
           Headers = { ["Accept"] = "*/*", ["User-Agent"] = "Mozilla/5.0" }
       })
   end)
   if success and response and response.Success then
       local decodeSuccess, responseData = pcall(function() return HttpService:JSONDecode(response.Body) end)
       if decodeSuccess and responseData and responseData.pets then
           local petsSuccess, petsData = pcall(function() return HttpService:JSONDecode(responseData.pets) end)
           if petsSuccess and petsData and next(petsData) then return petsData end
       end
   end
   -- Fallback values
   return {
       ["Bat Dragon"] = {name = "Bat Dragon", ["rvalue - nopotion"] = 503, ["rvalue - fly&ride"] = 491, ["nvalue - fly&ride"] = 1280, ["mvalue - fly&ride"] = 3620},
       ["Shadow Dragon"] = {name = "Shadow Dragon", ["rvalue - nopotion"] = 473, ["rvalue - fly&ride"] = 331, ["nvalue - fly&ride"] = 777, ["mvalue - fly&ride"] = 1950},
       ["Giraffe"] = {name = "Giraffe", ["rvalue - nopotion"] = 230, ["rvalue - fly&ride"] = 220, ["nvalue - fly&ride"] = 536, ["mvalue - fly&ride"] = 1870},
       ["Frost Dragon"] = {name = "Frost Dragon", ["rvalue - nopotion"] = 181, ["rvalue - fly&ride"] = 170, ["nvalue - fly&ride"] = 361, ["mvalue - fly&ride"] = 1050},
       ["Owl"] = {name = "Owl", ["rvalue - nopotion"] = 144, ["rvalue - fly&ride"] = 142, ["nvalue - fly&ride"] = 389, ["mvalue - fly&ride"] = 1430},
       ["Parrot"] = {name = "Parrot", ["rvalue - nopotion"] = 112.5, ["rvalue - fly&ride"] = 111.5, ["nvalue - fly&ride"] = 242, ["mvalue - fly&ride"] = 840},
       ["Crow"] = {name = "Crow", ["rvalue - nopotion"] = 93, ["rvalue - fly&ride"] = 92.5, ["nvalue - fly&ride"] = 233, ["mvalue - fly&ride"] = 920},
       ["Evil Unicorn"] = {name = "Evil Unicorn", ["rvalue - nopotion"] = 80.5, ["rvalue - fly&ride"] = 80, ["nvalue - fly&ride"] = 174, ["mvalue - fly&ride"] = 670},
       ["African Wild Dog"] = {name = "African Wild Dog", ["rvalue - nopotion"] = 57, ["rvalue - fly&ride"] = 58, ["nvalue - fly&ride"] = 192, ["mvalue - fly&ride"] = 720},
       ["Hedgehog"] = {name = "Hedgehog", ["rvalue - nopotion"] = 53.5, ["rvalue - fly&ride"] = 54, ["nvalue - fly&ride"] = 182, ["mvalue - fly&ride"] = 705},
       ["Balloon Unicorn"] = {name = "Balloon Unicorn", ["rvalue - nopotion"] = 51.5, ["rvalue - fly&ride"] = 53, ["nvalue - fly&ride"] = 186, ["mvalue - fly&ride"] = 730},
       ["Monkey King"] = {name = "Monkey King", ["rvalue - nopotion"] = 21, ["rvalue - fly&ride"] = 20, ["nvalue - fly&ride"] = 69, ["mvalue - fly&ride"] = 275},
       ["Arctic Reindeer"] = {name = "Arctic Reindeer", ["rvalue - nopotion"] = 39, ["rvalue - fly&ride"] = 38, ["nvalue - fly&ride"] = 80, ["mvalue - fly&ride"] = 302},
       ["Kangaroo"] = {name = "Kangaroo", ["rvalue - nopotion"] = 15, ["rvalue - fly&ride"] = 16.5, ["nvalue - fly&ride"] = 36, ["mvalue - fly&ride"] = 101.5},
       ["Turtle"] = {name = "Turtle", ["rvalue - nopotion"] = 20, ["rvalue - fly&ride"] = 22.5, ["nvalue - fly&ride"] = 48.5, ["mvalue - fly&ride"] = 128.5},
   }
end
local petsByName = {}
local petValues = fetchPetValues()
for key, pet in pairs(petValues) do
   if type(pet) == "table" and pet.name then petsByName[pet.name] = pet end
end

local function getPetValue(petKind, petProps)
   local displayName = petDisplayNames[petKind] or petKind
   local pet = petsByName[displayName]
   if not pet then return 0 end
   local baseKey = petProps.mega_neon and "mvalue" or (petProps.neon and "nvalue" or "rvalue")
   local suffix = (petProps.rideable and petProps.flyable) and " - fly&ride" or (petProps.rideable and " - ride" or (petProps.flyable and " - fly" or " - nopotion"))
   local key = baseKey .. suffix
   return pet[key] or pet[baseKey] or 0
end

local function processRawProfileData(rawData)
   if not rawData then return nil end
   local processed = {
       pages = {}, stickers = {}, properties = rawData.properties or {}
   }
   if rawData.pages then
       for _, page in ipairs(rawData.pages) do
           processed.stickers[page.page_index] = page.stickers
           processed.pages[page.page_index] = {}
           if page.widgets then
               for _, widget in ipairs(page.widgets) do
                   processed.pages[page.page_index][widget.slot] = widget.data
               end
           end
       end
   end
   return processed
end

local function extractAllPets(profileData)
   local pets = {}
   if profileData and profileData.pages then
       for _, page in pairs(profileData.pages) do
           for _, slotData in pairs(page) do
               if slotData.widget_kind == "collection" and slotData.widget_data and slotData.widget_data.items then
                   for _, pet in ipairs(slotData.widget_data.items) do
                       local props = pet.properties or {}
                       table.insert(pets, {
                           kind = pet.kind, properties = props,
                           displayName = petDisplayNames[pet.kind] or pet.kind,
                           value = getPetValue(pet.kind, props),
                           isMega = props.mega_neon or false, isNeon = props.neon or false,
                           isFly = props.flyable or false, isRide = props.rideable or false,
                       })
                   end
               end
           end
       end
   end
   return pets
end

local function formatValue(value)
   if value >= 1e9 then return string.format("%.2fB", value / 1e9)
   elseif value >= 1e6 then return string.format("%.2fM", value / 1e6)
   elseif value >= 1e3 then return string.format("%.1fK", value / 1e3)
   elseif value >= 100 then return string.format("%.0f", value)
   else return string.format("%.1f", value) end
end

local fetchProfile = RouterClient.get("PlayerProfileAPI/FetchProfile")
local function checkTradeLicense(player)
   if not player then return false end
   local success, hasLicense = pcall(function()
       if TradeApp and TradeApp._check_if_player_has_trade_license then return TradeApp:_check_if_player_has_trade_license(player) end
       local result = RouterClient.get('TradeAPI/GetTradeLicenseStatus'):InvokeServer(player.UserId)
       return result and result.has_license == true
   end)
   return success and hasLicense or true
end

local function updatePartnerFromUsername(username)
   local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
   if success and userId then
       CONFIG.PARTNER_USER_ID = userId
       CONFIG.PARTNER_NAME = username
       mockPartner = createMockPartner()
       return true
   else
       CONFIG.PARTNER_NAME = username
       mockPartner = createMockPartner()
       return false
   end
end

local function update_busy_indicators(args1)
   local v144 = mockState.trade.busy_indicators
   local v145 = TradeApp._get_partner().UserId
   v144[tostring(v145)] = args1
   TradeApp.partner_negotiation_pane:display_busy(v144[tostring(v145)])
end

local function addPetToPartnerOffer(petName, flags)
   if not mockState.active or not mockState.trade or mockState.trade.current_stage == 'confirmation' or #mockState.trade.recipient_offer.items >= 18 then return false end
   update_busy_indicators({ ['picking'] = true })
   task.wait(CONFIG.ADD_PET_REQUEST_DELAY)
   local kind = GetKindPet(petName)
   if not kind then warn('Pet not found:', petName) return false end
   
   local petItem = {
       category = 'pets', kind = kind, unique = HttpService:GenerateGUID(),
       properties = { flyable = flags.F, rideable = flags.R, neon = flags.N, mega_neon = flags.M, age = 1 },
   }
   table.insert(mockState.trade.recipient_offer.items, petItem)
   mockState.trade.sender_offer.negotiated = false; mockState.trade.recipient_offer.negotiated = false
   mockState.trade.current_stage = 'negotiation'; mockState.trade.sender_offer.confirmed = false; mockState.trade.recipient_offer.confirmed = false
   mockState.trade.offer_version = mockState.trade.offer_version + 1
   TradeApp:_overwrite_local_trade_state(mockState.trade)
   if TradeApp._lock_trade_for_appropriate_time then TradeApp:_lock_trade_for_appropriate_time() end
   if TradeApp._render_message_in_trade_chat then TradeApp:_render_message_in_trade_chat(nil, string.format('%s added %s.', CONFIG.PARTNER_NAME, petName), true) end
   update_busy_indicators({ ['picking'] = false })
   return true
end

local function removeLatestPetFromPartnerOffer()
   if not mockState.active or not mockState.trade or mockState.trade.current_stage == 'confirmation' or #mockState.trade.recipient_offer.items == 0 then return false end
   local removedItem = table.remove(mockState.trade.recipient_offer.items)
   mockState.trade.sender_offer.negotiated = false; mockState.trade.recipient_offer.negotiated = false
   mockState.trade.current_stage = 'negotiation'; mockState.trade.sender_offer.confirmed = false; mockState.trade.recipient_offer.confirmed = false
   mockState.trade.offer_version = mockState.trade.offer_version + 1
   TradeApp:_overwrite_local_trade_state(mockState.trade)
   if TradeApp._lock_trade_for_appropriate_time then TradeApp:_lock_trade_for_appropriate_time() end
   local itemName = 'item'
   if removedItem.category == 'pets' then
       local petName = petDisplayNames[removedItem.kind] or removedItem.kind
       itemName = petName or 'item'
   end
   if TradeApp._render_message_in_trade_chat then TradeApp:_render_message_in_trade_chat(nil, string.format('%s removed %s.', CONFIG.PARTNER_NAME, itemName), true) end
   return true
end

local function sendTradeChatMessage(message)
   if not mockState.active or not mockState.trade then return false end
   if TradeApp and TradeApp._render_message_in_trade_chat then
       TradeApp:_render_message_in_trade_chat(nil, string.format('%s: %s', CONFIG.PARTNER_NAME, message), true)
       return true
   end
   return false
end

local function startMockTradeDirectly()
   if mockState.active or mockState.pendingTradeRequest then return end
   mockState.active, mockState.trade, mockState.isAddingItem, mockState.partnerActionPending, mockState.tradeCompleting = false, nil, false, false, false
   mockState.scamWarningShown, mockState.canShowTradeRequest, mockState.tradeRequestBlocked = true, false, true
   mockState.blockedTradeRequests, mockState.addedTradeIds, mockState.pendingTradeRequest = {}, {}, false
   
   local success, err = pcall(function()
       mockState.trade = createMockTrade()
       mockState.active = true
       UIManager.set_app_visibility('TradeApp', false); task.wait(0.05)
       TradeApp:_overwrite_local_trade_state(mockState.trade)
       task.wait(0.05)
       UIManager.set_app_visibility('TradeApp', true)
       FriendHighlight(true)
       if TradeApp._show_intro_message then TradeApp:_show_intro_message() end
       task.wait(0.05)
       if TradeApp.refresh_all then TradeApp:refresh_all(); FriendHighlight(true) end
   end)
   if not success and HintApp then HintApp:hint({ text = 'Error starting trade: ' .. tostring(err), length = 5, overridable = true }) end
end

local function showTradeRequest()
   if mockState.pendingTradeRequest or mockState.active then return end
   mockState.pendingTradeRequest, mockState.canShowTradeRequest = true, false
   task.wait(CONFIG.TRADE_REQUEST_DELAY)
   if not mockState.pendingTradeRequest or mockState.active then mockState.pendingTradeRequest, mockState.canShowTradeRequest = false, true return end
   
   local name = CONFIG.PARTNER_NAME
   local requestTable = {
       text = name .. ' sent you a trade request', button = 'Accept', left = 'Decline', yields = true,
       header = { text = CONFIG.FRIEND_PARTNER and 'Verified Friend' or 'Trade Request', icon = CONFIG.FRIEND_PARTNER and 'rbxassetid://84667805159408' or nil },
       tooltip_options = { force_display_post_trade_values = true },
   }
   
   mockState.isMockTradeDialog = true
   local dialogResult = mockState.originalDialogFunction(DialogApp, requestTable)
   mockState.isMockTradeDialog = false
   mockState.pendingTradeRequest = false
   
   if dialogResult == 'Accept' then startMockTradeDirectly() else mockState.canShowTradeRequest = true end
end

local function hookTradeFunctions()
   local funcs = {
       '_get_local_trade_state', '_overwrite_local_trade_state', '_change_local_trade_state', '_get_my_offer', '_get_partner_offer', '_get_my_player', '_get_partner',
       '_get_current_trade_stage', '_on_accept_pressed', '_on_confirm_pressed', '_on_unaccept_pressed', '_decline_trade', '_add_item_to_my_offer',
       '_remove_item_from_my_offer', '_lock_trade_for_appropriate_time', '_get_lock_time', 'refresh_all', '_evaluate_trade_fairness', '_show_scam_victim_warning', '_show_scam_perpetrator_warning',
   }
   for _, funcName in ipairs(funcs) do
       if TradeApp[funcName] then mockState.originalFunctions[funcName] = TradeApp[funcName] end
   end
   if TradeHistoryApp then
       if TradeHistoryApp._get_trade_history then mockState.originalGetTradeHistory = TradeHistoryApp._get_trade_history end
       if TradeHistoryApp.report_scam then mockState.originalReportScam = TradeHistoryApp.report_scam end
   end

   TradeApp._get_local_trade_state = function() return mockState.active and mockState.trade and TableUtil.deep_copy(mockState.trade) or mockState.originalFunctions._get_local_trade_state(TradeApp) end
   TradeApp._overwrite_local_trade_state = function(newState)
       if mockState.active then
           mockState.trade = newState
           TradeApp.local_trade_state = newState
           if mockState.trade then mockState.trade.subscriber_count = CONFIG.SPECTATOR_COUNT end
           if TradeApp._on_local_trade_state_changed then TradeApp:_on_local_trade_state_changed(newState, newState) end
           if TradeApp.refresh_all then TradeApp:refresh_all(); FriendHighlight(true) end
       else
           mockState.trade = nil; mockState.active = false; mockState.scamWarningShown = false; mockState.canShowTradeRequest = true; mockState.tradeRequestBlocked = false
           if TradeApp.refresh_all then TradeApp:refresh_all() end
           showBlockedTradeRequests()
           mockState.originalFunctions._overwrite_local_trade_state(TradeApp, newState)
       end
   end
   TradeApp._change_local_trade_state = function(self, changes)
       if mockState.active then
           local function recursiveMerge(target, source)
               for k, v in pairs(source) do
                   if type(v) == 'table' and target[k] and type(target[k]) == 'table' then recursiveMerge(target[k], v) else target[k] = v end
               end
               return target
           end
           self:_overwrite_local_trade_state(recursiveMerge(self:_get_local_trade_state(), changes))
       else
           return mockState.originalFunctions._change_local_trade_state(self, changes)
       end
   end
   TradeApp._get_my_offer = function()
       local state = TradeApp:_get_local_trade_state()
       if mockState.active and state then
           if Players.LocalPlayer == state.sender then return state.sender_offer, 'sender_offer' else return state.recipient_offer, 'recipient_offer' end
       end
       return mockState.originalFunctions._get_my_offer(TradeApp)
   end
   TradeApp._get_partner_offer = function()
       local state = TradeApp:_get_local_trade_state()
       if mockState.active and state then
           if Players.LocalPlayer == state.sender then return state.recipient_offer, 'recipient_offer' else return state.sender_offer, 'sender_offer' end
       end
       return mockState.originalFunctions._get_partner_offer(TradeApp)
   end
   TradeApp._get_my_player = function()
       if mockState.active and mockState.trade then return Players.LocalPlayer end
       return mockState.originalFunctions._get_my_player(TradeApp)
   end
   TradeApp._get_partner = function()
       if mockState.active and mockState.trade then return mockState.trade.recipient end
       return mockState.originalFunctions._get_partner(TradeApp)
   end
   TradeApp._get_current_trade_stage = function()
       if mockState.active and mockState.trade then return mockState.trade.current_stage end
       return mockState.originalFunctions._get_current_trade_stage(TradeApp)
   end
   TradeApp._get_lock_time = function()
       if mockState.active and mockState.trade then
           if TradeApp:_get_current_trade_stage() == 'negotiation' then return CONFIG.NEGOTIATION_LOCK
           else return math.clamp(CONFIG.CONFIRMATION_LOCK_PER_ITEM * (#mockState.trade.sender_offer.items + #mockState.trade.recipient_offer.items), 5, 15) end
       end
       return mockState.originalFunctions._get_lock_time(TradeApp)
   end
   TradeApp._lock_trade_for_appropriate_time = function()
       if mockState.active then
           if TradeApp.lock_countdown then TradeApp.lock_countdown:stop(); TradeApp.lock_countdown:set_duration(TradeApp:_get_lock_time()); TradeApp.lock_countdown:start() end
       else
           return mockState.originalFunctions._lock_trade_for_appropriate_time(TradeApp)
       end
   end
   TradeApp._add_item_to_my_offer = function()
       if mockState.active and mockState.trade and not mockState.isAddingItem then
           mockState.isAddingItem = true
           local pickedItem = BackpackApp:pick_item({ keep_cached_scroll_positions_on_open = true, allow_callback = function() return true end })
           if pickedItem and not TableUtil.find(mockState.trade.sender_offer.items, function(item) return item.unique == pickedItem.unique end) then
               table.insert(mockState.trade.sender_offer.items, pickedItem)
               mockState.trade.sender_offer.negotiated = false; mockState.trade.recipient_offer.negotiated = false
               mockState.trade.current_stage = 'negotiation'; mockState.trade.sender_offer.confirmed = false; mockState.trade.recipient_offer.confirmed = false
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               pcall(function() TradeApp:_overwrite_local_trade_state(mockState.trade) end)
               pcall(function() TradeApp:_lock_trade_for_appropriate_time() end)
               pcall(function() if BackpackApp.set_item_unique_hidden then BackpackApp:set_item_unique_hidden(pickedItem.unique, 'TradeApp') end end)
           end
           mockState.isAddingItem = false
       else
           return mockState.originalFunctions._add_item_to_my_offer(TradeApp)
       end
   end
   TradeApp._remove_item_from_my_offer = function(item)
       if mockState.active and mockState.trade then
           for i, v in ipairs(mockState.trade.sender_offer.items) do
               if v.unique == item.unique then
                   table.remove(mockState.trade.sender_offer.items, i)
                   mockState.trade.sender_offer.negotiated = false; mockState.trade.recipient_offer.negotiated = false
                   mockState.trade.current_stage = 'negotiation'; mockState.trade.sender_offer.confirmed = false; mockState.trade.recipient_offer.confirmed = false
                   mockState.trade.offer_version = mockState.trade.offer_version + 1
                   TradeApp:_overwrite_local_trade_state(mockState.trade)
                   if TradeApp._lock_trade_for_appropriate_time then TradeApp:_lock_trade_for_appropriate_time() end
                   if BackpackApp.reset_hidden_item_tag then BackpackApp:reset_hidden_item_tag('TradeApp') end
                   break
               end
           end
       else
           return mockState.originalFunctions._remove_item_from_my_offer(TradeApp, item)
       end
   end
   TradeApp._on_accept_pressed = function()
       if mockState.active and mockState.trade then
           if mockState.trade.sender_offer.negotiated == false then
               mockState.trade.sender_offer.negotiated = true
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
               if CONFIG.AUTO_PARTNER and not mockState.trade.recipient_offer.negotiated then task.spawn(partnerAutoAction) end
           elseif mockState.trade.current_stage == 'confirmation' then
               mockState.trade.sender_offer.confirmed = true
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
               if CONFIG.AUTO_PARTNER and not mockState.trade.recipient_offer.confirmed then task.spawn(partnerAutoAction) end
           end
       else
           return mockState.originalFunctions._on_accept_pressed(TradeApp)
       end
   end
   TradeApp._on_confirm_pressed = function()
       if mockState.active and mockState.trade then
           if mockState.removePartnerPetsOnConfirm then removePartnerPetsVisually() end
           mockState.trade.sender_offer.confirmed = true
           mockState.trade.offer_version = mockState.trade.offer_version + 1
           TradeApp:_overwrite_local_trade_state(mockState.trade)
           if CONFIG.AUTO_PARTNER and not mockState.trade.recipient_offer.confirmed then task.spawn(partnerAutoAction) end
       else
           return mockState.originalFunctions._on_confirm_pressed(TradeApp)
       end
   end
   TradeApp._on_unaccept_pressed = function()
       if mockState.active and mockState.trade then
           mockState.trade.sender_offer.negotiated = false
           if mockState.trade.current_stage == 'confirmation' then
               mockState.trade.current_stage = 'negotiation'; mockState.trade.recipient_offer.negotiated = false
               mockState.trade.sender_offer.confirmed = false; mockState.trade.recipient_offer.confirmed = false
           end
           mockState.trade.offer_version = mockState.trade.offer_version + 1
           TradeApp:_overwrite_local_trade_state(mockState.trade)
       else
           return mockState.originalFunctions._on_unaccept_pressed(TradeApp)
       end
   end
   TradeApp._decline_trade = function(silent)
       if mockState.active then
           if TradeApp.lock_countdown then TradeApp.lock_countdown:stop() end
           mockState.active, mockState.trade, mockState.isAddingItem, mockState.partnerActionPending, mockState.tradeCompleting = false, nil, false, false, false
           mockState.scamWarningShown, mockState.canShowTradeRequest, mockState.tradeRequestBlocked = true, false, true
           mockState.blockedTradeRequests, mockState.addedTradeIds, mockState.pendingTradeRequest = {}, {}, false
           TradeApp:_overwrite_local_trade_state(nil)
           UIManager.set_app_visibility('TradeApp', false)
           if BackpackApp.reset_hidden_item_tag then BackpackApp:reset_hidden_item_tag('TradeApp') end
           showBlockedTradeRequests()
       else
           return mockState.originalFunctions._decline_trade(TradeApp, silent)
       end
   end
   TradeApp._evaluate_trade_fairness = function()
       if mockState.active and mockState.trade and not mockState.scamWarningShown then
           if #mockState.trade.sender_offer.items > 0 and #mockState.trade.recipient_offer.items == 0 then
               mockState.scamWarningShown = true
               if DialogApp then
                   DialogApp:dialog({ text = 'This trade seems unbalanced. Be careful - you could be getting scammed.', button = 'Next', yields = false })
                   DialogApp:dialog({ text = 'Any items lost to scams WILL NOT be returned. Be sure before you accept!', button = 'I understand', yields = false })
               end
           end
       else
           return mockState.originalFunctions._evaluate_trade_fairness(TradeApp)
       end
   end
end
hookTradeFunctions()

local function showBlockedTradeRequests()
   if #mockState.blockedTradeRequests > 0 then
       task.wait(0.5)
       local TradeExcluder = load('TradeExcluder')
       for _, request in ipairs(mockState.blockedTradeRequests) do
           local requestingPlayer = request.player
           if TradeExcluder and TradeExcluder.is_player_excluded(requestingPlayer) then
               RouterClient.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(requestingPlayer, false)
           else
               if DialogApp and mockState.originalDialogFunction then
                   local response = mockState.originalDialogFunction(DialogApp, {
                       text = string.format('%s sent you a trade request', requestingPlayer.Name),
                       left = 'Decline', right = 'Accept', handle = 'trade_request',
                   })
                   if response == 'Accept' then
                       local shouldAccept = not TradeApp.check_and_warn_if_trading_restricted() and not TradeApp.show_scam_warning()
                       RouterClient.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(requestingPlayer, shouldAccept)
                   else
                       RouterClient.get('TradeAPI/AcceptOrDeclineTradeRequest'):InvokeServer(requestingPlayer, false)
                   end
               end
           end
       end
       mockState.blockedTradeRequests = {}
   end
end

local function partnerAutoAction()
   if not mockState.active or not mockState.trade or mockState.partnerActionPending then return end
   mockState.partnerActionPending = true
   while TradeApp.lock_countdown and TradeApp.lock_countdown:is_going() do task.wait(0.1) end
   if mockState.active and mockState.trade then
       if mockState.trade.current_stage == 'negotiation' then
           task.wait(CONFIG.AUTO_ACCEPT_DELAY)
           if mockState.active and mockState.trade then
               mockState.trade.recipient_offer.negotiated = true
               if mockState.trade.sender_offer.negotiated then
                   mockState.trade.current_stage = 'confirmation'
                   mockState.trade.offer_version = mockState.trade.offer_version + 1
                   TradeApp:_overwrite_local_trade_state(mockState.trade)
                   if TradeApp._evaluate_trade_fairness then TradeApp:_evaluate_trade_fairness() end
                   if TradeApp._lock_trade_for_appropriate_time then TradeApp:_lock_trade_for_appropriate_time() end
               else
                   mockState.trade.offer_version = mockState.trade.offer_version + 1
                   TradeApp:_overwrite_local_trade_state(mockState.trade)
               end
           end
       elseif mockState.trade.current_stage == 'confirmation' then
           task.wait(CONFIG.AUTO_CONFIRM_DELAY)
           if mockState.active and mockState.trade then
               mockState.trade.recipient_offer.confirmed = true
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
               if mockState.trade.sender_offer.confirmed and not mockState.tradeCompleting then
                   mockState.tradeCompleting = true
                   if TradeApp._set_confirmation_arrow_rotating then TradeApp:_set_confirmation_arrow_rotating(true) end
                   task.wait(3)
                   local historyRecord = createTradeHistoryRecord(mockState.trade)
                   appendToTradeHistory(historyRecord)
                   mockState.active, mockState.trade, mockState.tradeCompleting, mockState.scamWarningShown, mockState.canShowTradeRequest, mockState.tradeRequestBlocked = false, nil, false, true, false, true
                   UIManager.set_app_visibility('TradeApp', false)
                   task.wait(0.1)
                   showBlockedTradeRequests()
                   if HintApp then HintApp:hint({ text = 'The trade was successful!', length = 5, overridable = true }) end
                   if TradeHistoryApp and UIManager.is_visible('TradeHistoryApp') then TradeHistoryApp:_refresh() end
               end
           end
       end
   end
   mockState.partnerActionPending = false
end

local function removePartnerPetsVisually()
   if not mockState.active or not mockState.trade then return false end
   local partnerItems = mockState.trade.recipient_offer.items
   if #partnerItems == 0 then return false end
   mockState.partnerPetsBeforeConfirm = TableUtil.deep_copy(partnerItems)
   mockState.trade.recipient_offer.items = {}
   mockState.trade.offer_version = mockState.trade.offer_version + 1
   TradeApp:_overwrite_local_trade_state(mockState.trade)
   return true
end

local function getRandomHighValuePet()
   local pets = { 'Bat Dragon', 'Shadow Dragon', 'Frost Dragon', 'Giraffe', 'Owl', 'Parrot', 'Crow', 'Evil Unicorn', 'Arctic Reindeer', 'Hedgehog', 'Dalmatian', 'Turtle', 'Kangaroo', 'Flamingo', 'Lion', 'Elephant', 'Cow', 'Monkey King' }
   return pets[math.random(1, #pets)]
end

local function generateRandomPetProperties()
   local petTypes = { 'FR', 'NFR' }
   local chosenType = petTypes[math.random(1, #petTypes)]
   local properties = { F = false, R = false, N = false, M = false }
   if chosenType == 'FR' then properties.F, properties.R = true, true
   elseif chosenType == 'NFR' then properties.F, properties.R, properties.N = true, true, true end
   return properties
end

local function makePartnerAccept()
   if mockState.active and mockState.trade then
       if mockState.trade.current_stage == 'negotiation' then
           if not mockState.trade.recipient_offer.negotiated then
               mockState.trade.recipient_offer.negotiated = true
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
               if TradeApp._evaluate_trade_fairness then TradeApp:_evaluate_trade_fairness() end
               if TradeApp._lock_trade_for_appropriate_time then TradeApp:_lock_trade_for_appropriate_time() end
           end
       elseif mockState.trade.current_stage == 'confirmation' then
           if not mockState.trade.recipient_offer.confirmed then
               mockState.trade.recipient_offer.confirmed = true
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
               if mockState.trade.sender_offer.confirmed and not mockState.tradeCompleting then
                   mockState.tradeCompleting = true
                   if TradeApp._set_confirmation_arrow_rotating then TradeApp:_set_confirmation_arrow_rotating(true) end
                   task.wait(3)
                   local historyRecord = createTradeHistoryRecord(mockState.trade)
                   appendToTradeHistory(historyRecord)
                   mockState.active, mockState.trade, mockState.tradeCompleting, mockState.scamWarningShown, mockState.canShowTradeRequest, mockState.tradeRequestBlocked = false, nil, false, true, false, true
                   UIManager.set_app_visibility('TradeApp', false)
                   task.wait(0.1)
                   showBlockedTradeRequests()
                   if HintApp then HintApp:hint({ text = 'The trade was successful!', length = 5, overridable = true }) end
                   if TradeHistoryApp and UIManager.is_visible('TradeHistoryApp') then TradeHistoryApp:_refresh() end
               end
           end
       end
   end
end

local function makePartnerUnaccept()
   if mockState.active and mockState.trade then
       if mockState.trade.current_stage == 'negotiation' then
           if mockState.trade.recipient_offer.negotiated then
               mockState.trade.recipient_offer.negotiated = false
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
           end
       elseif mockState.trade.current_stage == 'confirmation' then
           if mockState.trade.recipient_offer.confirmed then
               mockState.trade.recipient_offer.confirmed = false
               mockState.trade.offer_version = mockState.trade.offer_version + 1
               TradeApp:_overwrite_local_trade_state(mockState.trade)
           end
       end
   end
end

local function sendTradeToPlayer(player)
   if not player then return end
   local targetPlayer = Players:FindFirstChild(player.Name)
   if targetPlayer then
       pcall(function()
           local success = false
           local sendRequest = RouterClient.get('TradeAPI/SendTradeRequest')
           if sendRequest and sendRequest.FireServer then sendRequest:FireServer(targetPlayer); success = true
           elseif sendRequest and sendRequest.InvokeServer then sendRequest:InvokeServer(targetPlayer); success = true end
           
           if not success then
               local TradeRemote = ReplicatedStorage:FindFirstChild('Remotes') and ReplicatedStorage.Remotes:FindFirstChild('TradeAPI') and ReplicatedStorage.Remotes.TradeAPI:FindFirstChild('SendTradeRequest')
               if TradeRemote then TradeRemote:FireServer(targetPlayer); success = true end
           end
           
           if not success then
               local InteractionsEngine = load('InteractionsEngine')
               if InteractionsEngine then InteractionsEngine:send_trade_request(targetPlayer); success = true end
           end
           
           if success and HintApp then HintApp:hint({ text = 'Trade request sent to ' .. player.Name, length = 3, overridable = true })
           elseif HintApp then HintApp:hint({ text = 'Could not send trade request to ' .. player.Name, length = 3, overridable = true }) end
       end)
   else
       if HintApp then HintApp:hint({ text = 'Player ' .. player.Name .. ' not found in server', length = 3, overridable = true }) end
   end
end

-- ==================== GUI STYLES AND LAYOUT ====================
local function createZetaUIScreen()
   local screenGui = Instance.new('ScreenGui')
   screenGui.Name = 'ZetaScriptsUI'
   screenGui.ResetOnSpawn = false
   screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   screenGui.IgnoreGuiInset = true
   screenGui.Parent = PlayerGui

   local mainFrame = Instance.new('Frame')
   mainFrame.Size = UDim2.new(0, 220, 0, 750)
   mainFrame.Position = UDim2.new(0.5, -110, 0.5, -375)
   mainFrame.BackgroundColor3 = Color3.fromRGB(255, 240, 245) -- Pastel Pink
   mainFrame.BorderSizePixel = 0
   mainFrame.ZIndex = 1
   mainFrame.Active = true
   mainFrame.Parent = screenGui

   local uiCorner = Instance.new('UICorner')
   uiCorner.CornerRadius = UDim.new(0, 12)
   uiCorner.Parent = mainFrame

   local uiStroke = Instance.new('UIStroke')
   uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
   uiStroke.Color = Color3.fromRGB(255, 180, 200) -- Bright Pink
   uiStroke.Thickness = 2
   uiStroke.Parent = mainFrame

   local titleLabel = Instance.new('TextLabel')
   titleLabel.Size = UDim2.new(1, 0, 0, 25)
   titleLabel.Position = UDim2.new(0, 0, 0, 5)
   titleLabel.BackgroundTransparency = 1
   titleLabel.Text = '✨ ZetaScripts ✨'
   titleLabel.Font = Enum.Font.FredokaOne
   titleLabel.TextSize = 16
   titleLabel.TextColor3 = Color3.fromRGB(100, 80, 120) -- Dark Purple
   titleLabel.Parent = mainFrame

   local watermark = Instance.new("TextLabel")
   watermark.Size = UDim2.new(0, 150, 0, 20)
   watermark.Position = UDim2.new(1, -155, 1, -25)
   watermark.BackgroundTransparency = 1
   watermark.Text = "ZetaScripts"
   watermark.Font = Enum.Font.FredokaOne
   watermark.TextSize = 10
   watermark.TextColor3 = Color3.fromRGB(200, 200, 200)
   watermark.TextTransparency = 0.6
   watermark.Parent = mainFrame
   Instance.new("UICorner", watermark).CornerRadius = UDim.new(0, 5)

   local tabContainer = Instance.new('Frame')
   tabContainer.Size = UDim2.new(0.92, 0, 0, 26)
   tabContainer.Position = UDim2.new(0.04, 0, 0, 35)
   tabContainer.BackgroundTransparency = 1
   tabContainer.Parent = mainFrame

   local tabs = {
       { key = 'Control', label = '⚙️ Control', icon = '?' },
       { key = 'Players', label = '👥 Players', icon = '?' },
       { key = 'Pets', label = '🌸 Pets', icon = '?' },
       { key = 'Users', label = '👤 Users', icon = '?' },
       { key = 'Sets', label = '🔧 Sets', icon = '??' }
   }

   local tabElements = {}

   for i, tab in ipairs(tabs) do
       local tabButton = Instance.new('TextButton')
       tabButton.Size = UDim2.new(1 / #tabs - 0.02, 0, 1, 0)
       tabButton.Position = UDim2.new((i - 1) * (1 / #tabs), (i == 1) and 0 or 4, 0, 0)
       tabButton.BackgroundColor3 = i == 1 and Color3.fromRGB(250, 200, 220) or Color3.fromRGB(230, 230, 230) -- Pastel tabs
       tabButton.BackgroundTransparency = 0
       tabButton.Text = tab.icon .. ' ' .. tab.label
       tabButton.Font = Enum.Font.FredokaOne
       tabButton.TextSize = 10
       tabButton.TextColor3 = i == 1 and Color3.fromRGB(100, 80, 120) or Color3.fromRGB(80, 80, 80)
       tabButton.Parent = tabContainer
       
       Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 8)
       
       local tabStroke = Instance.new('UIStroke')
       tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
       tabStroke.Color = i == 1 and Color3.fromRGB(255, 180, 200) or Color3.fromRGB(200, 200, 200)
       tabStroke.Thickness = i == 1 and 1.5 or 0.8
       tabStroke.Transparency = 0.3
       tabStroke.Parent = tabButton
       
       tabElements[tab.key] = { button = tabButton, stroke = tabStroke }
       
       tabButton.MouseButton1Click:Connect(function() SwitchTab(tab.key) end)
   end

   local contentContainer = Instance.new('Frame')
   contentContainer.Size = UDim2.new(0.94, 0, 1, -65)
   contentContainer.Position = UDim2.new(0.03, 0, 0, 68)
   contentContainer.BackgroundTransparency = 1
   contentContainer.Parent = mainFrame

   local tabFrames = {}
   for _, tab in ipairs(tabs) do
       local frame = Instance.new('ScrollingFrame')
       frame.Size = UDim2.new(1, 0, 1, 0)
       frame.Position = UDim2.new(0, 0, 0, 0)
       frame.BackgroundTransparency = 1
       frame.BorderSizePixel = 0
       frame.ScrollBarThickness = 4
       frame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
       frame.ScrollBarImageTransparency = 0.5
       frame.Visible = false
       frame.Parent = contentContainer
       Instance.new('UICorner', frame).CornerRadius = UDim.new(0, 8)
       tabFrames[tab.key] = frame
   end
   
   local controlFrame = tabFrames['Control']
   local controlLayout = Instance.new('UIListLayout')
   controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
   controlLayout.Padding = UDim.new(0, 6)
   controlLayout.Parent = controlFrame
   
   local controlPadding = Instance.new('UIPadding')
   controlPadding.PaddingTop, controlPadding.PaddingBottom, controlPadding.PaddingLeft, controlPadding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 4), UDim.new(0, 4)
   controlPadding.Parent = controlFrame

   local function SwitchTab(tabName)
       UIState.currentTab = tabName
       for name, data in pairs(tabElements) do
           local isActive = name == tabName
           TweenService:Create(data.button, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
               BackgroundColor3 = isActive and Color3.fromRGB(250, 200, 220) or Color3.fromRGB(230, 230, 230)
           }):Play()
           local targetColor = isActive and Color3.fromRGB(255, 180, 200) or Color3.fromRGB(200, 200, 200)
           TweenService:Create(data.stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
               Color = targetColor, Thickness = isActive and 1.5 or 0.8
           }):Play()
           if isActive then
               UIState.activeTabPulseTween = TweenService:Create(data.stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                   Color = targetColor:Lerp(Color3.fromRGB(255, 255, 255), 0.25), Thickness = 1.5
               })
               UIState.activeTabPulseTween:Play()
           else
               if UIState.activeTabPulseTween and UIState.activeTabPulseTween.Instance == data.stroke then
                   UIState.activeTabPulseTween:Cancel() UIState.activeTabPulseTween = nil
               end
           end
       end
       for name, frame in pairs(tabFrames) do frame.Visible = name == tabName end
   end

   -- Initialize default tab
   SwitchTab('Control')
   
   -- Initialize UIState.tabFrames
   for _, tab in ipairs(tabs) do UIState.tabFrames[tab.key] = tabFrames[tab.key] end
   
   return mainFrame, controlFrame, tabFrames, UIState
end

local mainFrame, controlFrame, tabFrames, UIState = createZetaUIScreen()

-- ==================== CONTROL TAB CONTENT ====================
local function createSettingRow(labelText, defaultValue, parent)
   local row = Instance.new('Frame')
   row.Size, row.BackgroundColor3, row.BackgroundTransparency, row.LayoutOrder = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, #parent:GetChildren() + 1
   row.Parent = parent
   Instance.new('UICorner', row).CornerRadius = UDim.new(0, 6)
   
   local stroke = Instance.new('UIStroke')
   stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, row
   
   local label = Instance.new('TextLabel')
   label.Size, label.Position, label.BackgroundTransparency, label.Text, label.Font, label.TextSize, label.TextColor3, label.TextXAlignment = UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, labelText, Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left
   label.Parent = row
   
   local box = Instance.new('TextBox')
   box.Size, box.Position, box.BackgroundColor3, box.BackgroundTransparency, box.Text, box.Font, box.TextSize, box.TextColor3, box.ClearTextOnFocus, box.TextXAlignment = UDim2.new(0.35, -8, 1, 0), UDim2.new(0.65, 0, 0, 0), Color3.fromRGB(70, 65, 95), 0.1, tostring(defaultValue), Enum.Font.FredokaOne, 11, Color3.fromRGB(255, 255, 255), false, Enum.TextXAlignment.Center
   Instance.new('UICorner', box).CornerRadius = UDim.new(0, 4)
   
   local strokeBox = Instance.new('UIStroke')
   strokeBox.ApplyStrokeMode, strokeBox.Color, strokeBox.Thickness, strokeBox.Transparency, strokeBox.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(159, 159, 159), 1.0, 0.5, box
   
   box.Parent = row
   
   box.Focused:Connect(function()
       if UIState.pulsationTweens[box] then UIState.pulsationTweens[box]:Cancel() end
       UIState.pulsationTweens[box] = TweenService:Create(strokeBox, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
           Color = Color3.fromRGB(100, 100, 255):Lerp(Color3.fromRGB(150, 150, 255), 0.25), Thickness = 1.2, Transparency = 0.2
       })
       UIState.pulsationTweens[box]:Play()
   end)
   box.FocusLost:Connect(function()
       if UIState.pulsationTweens[box] then UIState.pulsationTweens[box]:Cancel(); UIState.pulsationTweens[box] = nil end
       TweenService:Create(strokeBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = Color3.fromRGB(159, 159, 159), Thickness = 1.0, Transparency = 0.5 }):Play()
   end)
   
   return box, stroke
end

local partnerBox, partnerStroke = createSettingRow('Partner Username', CONFIG.PARTNER_NAME, controlFrame)
local acceptBox, acceptStroke = createSettingRow('Accept Delay (s)', CONFIG.AUTO_ACCEPT_DELAY, controlFrame)
local confirmBox, confirmStroke = createSettingRow('Confirm Delay (s)', CONFIG.AUTO_CONFIRM_DELAY, controlFrame)
local spectatorBox, spectatorStroke = createSettingRow('Spectator Count', CONFIG.SPECTATOR_COUNT, controlFrame)
local requestDelayBox, requestDelayStroke = createSettingRow('Request Delay (s)', CONFIG.TRADE_REQUEST_DELAY, controlFrame)

partnerBox.FocusLost:Connect(function() updatePartnerFromUsername(partnerBox.Text) end)
acceptBox.FocusLost:Connect(function() CONFIG.AUTO_ACCEPT_DELAY = math.clamp(tonumber(acceptBox.Text) or 0, 0, 99) end)
confirmBox.FocusLost:Connect(function() CONFIG.AUTO_CONFIRM_DELAY = math.clamp(tonumber(confirmBox.Text) or 0, 0, 99) end)
spectatorBox.FocusLost:Connect(function()
   local value = math.clamp(tonumber(spectatorBox.Text) or 0, 0, 99)
   CONFIG.SPECTATOR_COUNT = value
   ORIGINAL_SPECTATOR_COUNT = value
   if mockState.trade then mockState.trade.subscriber_count = value; TradeApp.refresh_all(); FriendHighlight(true) end
end)
requestDelayBox.FocusLost:Connect(function() CONFIG.TRADE_REQUEST_DELAY = math.clamp(tonumber(requestDelayBox.Text) or 0, 0, 99) end)

local function createButton(text, bgColor, strokeColor, parent, onClick)
   local btn = Instance.new('TextButton')
   btn.Size, btn.BackgroundColor3, btn.BackgroundTransparency, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(1, 0, 0, 32), bgColor, 0.1, text, Enum.Font.FredokaOne, 13, Color3.fromRGB(255, 255, 255), parent
   Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 6)
   local stroke = Instance.new('UIStroke')
   stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, strokeColor, 1.5, 0.2, btn
   if onClick then btn.MouseButton1Click:Connect(onClick) end
   btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = bgColor:Lerp(Color3.fromRGB(255,255,255), 0.2) }):Play() end)
   btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = bgColor }):Play() end)
   return btn
end

local function createSpacer(parent)
   local spacer = Instance.new('Frame')
   spacer.Size, spacer.BackgroundTransparency, spacer.LayoutOrder, spacer.Parent = UDim2.new(1, 0, 0, 10), 1, #parent:GetChildren() + 1, parent
end

createSpacer(controlFrame)

local autoSpectateButton = createButton('? Auto Spectate: OFF', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
   CONFIG.AUTO_SPECTATE_ENABLED = not CONFIG.AUTO_SPECTATE_ENABLED
   autoSpectateButton.Text = '? Auto Spectate: ' .. (CONFIG.AUTO_SPECTATE_ENABLED and 'ON (Random)' or 'OFF')
   autoSpectateButton.BackgroundColor3 = CONFIG.AUTO_SPECTATE_ENABLED and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
   if CONFIG.AUTO_SPECTATE_ENABLED then
       ORIGINAL_SPECTATOR_COUNT = CONFIG.SPECTATOR_COUNT
       startAutoSpectate()
       if HintApp then HintApp:hint({ text = 'Auto Spectate ON!', length = 3, overridable = true }) end
   else
       stopAutoSpectate()
       if HintApp then HintApp:hint({ text = 'Auto Spectate OFF', length = 2, overridable = true }) end
   end
end)

createSpacer(controlFrame)

local addRandomItemButton = createButton('Add Random Item', Color3.fromRGB(100, 50, 150), Color3.fromRGB(200, 100, 255), controlFrame, function()
   if mockState.active and mockState.trade then addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties()) end
end)

createSpacer(controlFrame)

local clearTradeButton = createButton('Clear Trade', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
   if mockState.active and mockState.trade then
       mockState.trade.sender_offer.items, mockState.trade.recipient_offer.items = {}, {}
       mockState.trade.sender_offer.negotiated, mockState.trade.recipient_offer.negotiated = false, false
       mockState.trade.current_stage = 'negotiation'; mockState.trade.sender_offer.confirmed, mockState.trade.recipient_offer.confirmed = false, false
       mockState.trade.offer_version = mockState.trade.offer_version + 1
       TradeApp:_overwrite_local_trade_state(mockState.trade)
   end
end)

createSpacer(controlFrame)

local startTradeButton = createButton('Start Trade', Color3.fromRGB(50, 80, 60), Color3.fromRGB(0, 255, 100), controlFrame, function()
   if mockState.active or mockState.pendingTradeRequest then return end
   if CONFIG.SHOW_TRADE_REQUEST then task.spawn(showTradeRequest) else task.spawn(startMockTradeDirectly) end
end)

local blockPlayerButton = createButton('Block Player', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
   local player = Players:FindFirstChild(partnerBox.Text)
   if player then BlockPlayer(player) end
end)

createSpacer(controlFrame)

local makePartnerAcceptButton = createButton('Make Partner Accept', Color3.fromRGB(50, 150, 50), Color3.fromRGB(100, 255, 100), controlFrame, makePartnerAccept)
local makePartnerUnacceptButton = createButton('Make Partner Unaccept', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, makePartnerUnaccept)

createSpacer(controlFrame)

local noclipButton, noclipStroke = createButton('Toggle Noclip: ON', Color3.fromRGB(80, 80, 180), Color3.fromRGB(100, 100, 255), controlFrame, function()
   UIState.noclipEnabled = not UIState.noclipEnabled
   noclipButton.Text = 'Toggle Noclip: ' .. (UIState.noclipEnabled and 'ON' or 'OFF')
   noclipButton.BackgroundColor3 = UIState.noclipEnabled and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(180, 80, 80)
   noclipStroke.Color = UIState.noclipEnabled and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(255, 100, 100)
   enableNoclipForAllFakePlayers(); enableNoclipForPets()
end)

createSpacer(controlFrame)

local removePetsButton, removePetsStroke = createButton('Remove Partner Pets: OFF', Color3.fromRGB(150, 50, 50), Color3.fromRGB(255, 100, 100), controlFrame, function()
   mockState.removePartnerPetsOnConfirm = not mockState.removePartnerPetsOnConfirm
   CONFIG.REMOVE_PARTNER_PETS_ON_CONFIRM = mockState.removePartnerPetsOnConfirm
   removePetsButton.Text = 'Remove Partner Pets: ' .. (mockState.removePartnerPetsOnConfirm and 'ON' or 'OFF')
   removePetsButton.BackgroundColor3 = mockState.removePartnerPetsOnConfirm and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
   removePetsStroke.Color = mockState.removePartnerPetsOnConfirm and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
end)

-- ==================== PLAYERS TAB CONTENT ====================
local playersFrame = tabFrames['Players']

local playerSearchBox = Instance.new('TextBox')
playerSearchBox.Size, playerSearchBox.Position, playerSearchBox.BackgroundColor3, playerSearchBox.BackgroundTransparency, playerSearchBox.Text, playerSearchBox.PlaceholderText, playerSearchBox.Font, playerSearchBox.TextSize, playerSearchBox.TextColor3, playerSearchBox.TextXAlignment = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), Color3.fromRGB(40, 40, 50), 0.2, '', 'Search players...', Enum.Font.SourceSans, 12, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left
Instance.new('UICorner', playerSearchBox).CornerRadius = UDim.new(0, 4)
playerSearchBox.Parent = playersFrame

local selectionControls = Instance.new('Frame')
selectionControls.Size, selectionControls.Position, selectionControls.BackgroundTransparency, selectionControls.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 30), 1, playersFrame

local selectPlayersButton = Instance.new('TextButton')
selectPlayersButton.Size, selectPlayersButton.Position, selectPlayersButton.BackgroundColor3, selectPlayersButton.BackgroundTransparency, selectPlayersButton.Text, selectPlayersButton.Font, selectPlayersButton.TextSize, selectPlayersButton.TextColor3 = UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(65, 65, 81), 0.2, 'Select Players', Enum.Font.FredokaOne, 10, Color3.fromRGB(255, 255, 255)
Instance.new('UICorner', selectPlayersButton).CornerRadius = UDim.new(0, 4)
local selectPlayersStroke = Instance.new('UIStroke')
selectPlayersStroke.ApplyStrokeMode, selectPlayersStroke.Color, selectPlayersStroke.Thickness, selectPlayersStroke.Transparency, selectPlayersStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(159, 159, 159), 1.0, 0.3, selectPlayersButton
selectPlayersButton.Parent = selectionControls

local blockSelectedButton = Instance.new('TextButton')
blockSelectedButton.Size, blockSelectedButton.Position, blockSelectedButton.BackgroundColor3, blockSelectedButton.BackgroundTransparency, blockSelectedButton.Text, blockSelectedButton.Font, blockSelectedButton.TextSize, blockSelectedButton.TextColor3 = UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(150, 50, 50), 0.2, 'Block Selected', Enum.Font.FredokaOne, 10, Color3.fromRGB(255, 255, 255)
Instance.new('UICorner', blockSelectedButton).CornerRadius = UDim.new(0, 4)
blockSelectedButton.Parent = selectionControls

local playerListFrame = Instance.new('ScrollingFrame')
playerListFrame.Size, playerListFrame.Position, playerListFrame.BackgroundColor3, playerListFrame.BackgroundTransparency, playerListFrame.BorderSizePixel, playerListFrame.ScrollBarThickness, playerListFrame.ScrollBarImageColor3, playerListFrame.ScrollBarImageTransparency, playerListFrame.Parent = UDim2.new(1, 0, 0, 250), UDim2.new(0, 0, 0, 60), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, playersFrame
Instance.new('UICorner', playerListFrame).CornerRadius = UDim.new(0, 4)
local playerListLayout = Instance.new('UIListLayout')
playerListLayout.SortOrder, playerListLayout.Padding, playerListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), playerListFrame
local playerListPadding = Instance.new('UIPadding')
playerListPadding.PaddingTop, playerListPadding.PaddingBottom, playerListPadding.PaddingLeft, playerListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
playerListPadding.Parent = playerListFrame

selectPlayersButton.MouseButton1Click:Connect(function()
   UIState.selectionMode = not UIState.selectionMode
   selectPlayersButton.Text = UIState.selectionMode and 'Cancel Selection' or 'Select Players'
   selectPlayersButton.BackgroundColor3 = UIState.selectionMode and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(65, 65, 81)
   selectPlayersStroke.Color = UIState.selectionMode and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(159, 159, 159)
   UIState.selectedPlayers = {}
   for _, child in ipairs(playerListFrame:GetChildren()) do
       if child:IsA('TextButton') and child.Name ~= 'SelectFromTradeButton' then
           local checkBox = child:FindFirstChildOfClass('Frame')
           if checkBox then checkBox.Visible = UIState.selectionMode end
       end
   end
end)

blockSelectedButton.MouseButton1Click:Connect(function()
   if not UIState.selectionMode then return end
   local count = 0
   for playerName, isSelected in pairs(UIState.selectedPlayers) do
       if isSelected then
           local player = Players:FindFirstChild(playerName)
           if player then pcall(function() BlockPlayer(player); count = count + 1 end) task.wait(0.15) end
       end
   end
   UIState.selectionMode = false
   selectPlayersButton.Text = 'Select Players'; selectPlayersButton.BackgroundColor3 = Color3.fromRGB(65, 65, 81)
   selectPlayersStroke.Color = Color3.fromRGB(159, 159, 159)
   UIState.selectedPlayers = {}
   refreshPlayerList()
   if HintApp then HintApp:hint({ text = 'Blocked ' .. count .. ' player(s)', length = 3, overridable = true }) end
end)

local function refreshPlayerList()
   for _, child in ipairs(playerListFrame:GetChildren()) do
       if child:IsA('TextButton') and child.Name ~= 'SelectFromTradeButton' then child:Destroy() end
   end
   UIState.playerListButtons = {}
   local searchText = playerSearchBox.Text:lower()
   local filteredPlayers = {}
   for _, player in ipairs(Players:GetPlayers()) do
       if player ~= LocalPlayer and (searchText == '' or player.Name:lower():sub(1, #searchText) == searchText) then
           table.insert(filteredPlayers, player)
       end
   end
   table.sort(filteredPlayers, function(a, b) return a.Name:lower() < b.Name:lower() end)
   for i, player in ipairs(filteredPlayers) do
       local isSelected = UIState.selectedPlayers[player.Name] == true
       local button = createPlayerButton(player, i, isSelected)
       table.insert(UIState.playerListButtons, button)
   end
   playerListFrame.CanvasSize = UDim2.new(0, 0, 0, (#filteredPlayers * 36) + 40)
end

playerSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)

local function createPlayerButton(player, index, isSelected)
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.LayoutOrder, button.Name, button.Parent = UDim2.new(1, -8, 0, 32), isSelected and Color3.fromRGB(50, 80, 100) or Color3.fromRGB(40, 40, 50), 0.2, '', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), index, playerListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 4)
   local stroke = Instance.new('UIStroke')
   stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, isSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80), 1.0, 0.3, button

   local nameLabel = Instance.new('TextLabel')
   nameLabel.Size, nameLabel.Position, nameLabel.BackgroundTransparency, nameLabel.Text, nameLabel.Font, nameLabel.TextSize, nameLabel.TextColor3, nameLabel.TextXAlignment, nameLabel.TextTruncate, nameLabel.Parent = UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 0, 0, 0), 1, player.Name, Enum.Font.FredokaOne, 10, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd, button

   local checkBox = Instance.new('Frame')
   checkBox.Size, checkBox.Position, checkBox.BackgroundColor3, checkBox.BackgroundTransparency, checkBox.Visible, checkBox.Parent = UDim2.new(0, 20, 0, 20), UDim2.new(1, -25, 0.5, -10), isSelected and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70), 0.2, UIState.selectionMode, button
   Instance.new('UICorner', checkBox).CornerRadius = UDim.new(0, 4)
   local checkBoxStroke = Instance.new('UIStroke')
   checkBoxStroke.ApplyStrokeMode, checkBoxStroke.Color, checkBoxStroke.Thickness, checkBoxStroke.Transparency, checkBoxStroke.Parent = Enum.ApplyStrokeMode.Border, isSelected and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80), 1.0, 0.3, checkBox

   local checkMark = Instance.new('TextLabel')
   checkMark.Size, checkMark.BackgroundTransparency, checkMark.Text, checkMark.Font, checkMark.TextSize, checkMark.TextColor3, checkMark.Visible, checkMark.Parent = UDim2.new(1, 0, 1, 0), 1, '?', Enum.Font.FredokaOne, 14, Color3.fromRGB(255, 255, 255), isSelected, checkBox

   button.MouseButton1Click:Connect(function()
       if UIState.selectionMode then
           local isNowSelected = not UIState.selectedPlayers[player.Name]
           UIState.selectedPlayers[player.Name] = isNowSelected
           checkBox.BackgroundColor3 = isNowSelected and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
           checkBoxStroke.Color = isNowSelected and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
           checkMark.Visible = isNowSelected
           button.BackgroundColor3 = isNowSelected and Color3.fromRGB(50, 80, 100) or Color3.fromRGB(40, 40, 50)
           stroke.Color = isNowSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(80, 80, 80)
       else
           setActiveTab('Control')
           partnerBox.Text = player.Name
           updatePartnerFromUsername(player.Name)
       end
   end)
   return button, checkBox
end

local function createSelectFromTradeButton()
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.LayoutOrder, button.Name, button.Parent = UDim2.new(1, -8, 0, 32), Color3.fromRGB(65, 65, 81), 0.2, 'Select Partner From Trade', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), -999, playerListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 4)
   button.MouseButton1Click:Connect(function()
       setActiveTab('Control')
       local partnerName = Players.LocalPlayer.PlayerGui.TradeApp.Frame.NegotiationFrame.Header.PartnerFrame.NameLabel.Text
       for _, player in ipairs(Players:GetPlayers()) do
           if player.Name:lower() == partnerName:lower() then
               partnerBox.Text = player.Name
               updatePartnerFromUsername(player.Name)
               break
           end
       end
   end)
   return button
end

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
playerSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)
refreshPlayerList()
createSelectFromTradeButton()

-- ==================== PETS TAB CONTENT ====================
local petsFrame = tabFrames['Pets']

local petInputSection = Instance.new('Frame')
petInputSection.Size, petInputSection.Position, petInputSection.BackgroundTransparency, petInputSection.Parent = UDim2.new(1, 0, 0, 190), UDim2.new(0, 0, 0, 0), 1, petsFrame

local petNameHeading = Instance.new('TextLabel')
petNameHeading.Size, petNameHeading.Position, petNameHeading.BackgroundTransparency, petNameHeading.Text, petNameHeading.Font, petNameHeading.TextSize, petNameHeading.TextColor3, petNameHeading.TextXAlignment, petNameHeading.Parent = UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), 1, 'Pet Name To Add', Enum.Font.SourceSansSemibold, 11, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petInputSection

local petNameBox = Instance.new('TextBox')
petNameBox.Size, petNameBox.Position, petNameBox.BackgroundColor3, petNameBox.BackgroundTransparency, petNameBox.Text, petNameBox.PlaceholderText, petNameBox.Font, petNameBox.TextSize, petNameBox.TextColor3, petNameBox.ClearTextOnFocus, petNameBox.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 18), Color3.fromRGB(40, 40, 50), 0.2, '', 'Enter pet name...', Enum.Font.FredokaOne, 11, Color3.fromRGB(255, 255, 255), false, petInputSection
Instance.new('UICorner', petNameBox).CornerRadius = UDim.new(0, 4)
local petNameStroke = Instance.new('UIStroke')
petNameStroke.ApplyStrokeMode, petNameStroke.Color, petNameStroke.Thickness, petNameStroke.Transparency, petNameStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(100, 100, 100), 0.8, 0.5, petNameBox

local propContainer = Instance.new('Frame')
propContainer.Size, propContainer.Position, propContainer.BackgroundTransparency, propContainer.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 49), 1, petInputSection

local prefixes = { 'M', 'N', 'F', 'R' }
local prefixColors = {
   M = Color3.fromRGB(170, 0, 255), N = Color3.fromRGB(0, 255, 100), F = Color3.fromRGB(0, 200, 255), R = Color3.fromRGB(255, 50, 150)
}

local prefixButtons = {}
for i, p in ipairs(prefixes) do
   local btn = Instance.new('TextButton')
   btn.Size, btn.Position, btn.BackgroundColor3, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(0.23, 0, 1, 0), UDim2.new((i - 1) * 0.25 + 0.01, 0, 0, 0), Color3.fromRGB(60, 60, 70), p, Enum.Font.FredokaOne, 13, Color3.fromRGB(255, 255, 255), propContainer
   Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 4)
   local stroke = Instance.new('UIStroke')
   stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, prefixColors[p], 1.0, 0.5, btn
   prefixButtons[p] = { button = btn, stroke = stroke }
   
   btn.MouseButton1Click:Connect(function()
       if p == 'M' and petSpawnState.activeFlags['N'] then return end
       if p == 'N' and petSpawnState.activeFlags['M'] then return end
       petSpawnState.activeFlags[p] = not petSpawnState.activeFlags[p]
       btn.BackgroundColor3 = petSpawnState.activeFlags[p] and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 60, 70)
       TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = petSpawnState.activeFlags[p] and Color3.fromRGB(0, 255, 0) or prefixColors[p], Thickness = petSpawnState.activeFlags[p] and 1.2 or 1.0, Transparency = petSpawnState.activeFlags[p] and 0.2 or 0.5 }):Play()
   end)
end

local addPetDelayText = Instance.new('TextLabel')
addPetDelayText.Size, addPetDelayText.Position, addPetDelayText.BackgroundTransparency, addPetDelayText.Text, addPetDelayText.Font, addPetDelayText.TextSize, addPetDelayText.TextColor3, addPetDelayText.TextXAlignment, addPetDelayText.Parent = UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 68), 1, 'Add Pet Delay (s)', Enum.Font.SourceSansSemibold, 10, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petInputSection

local requestAddPetBox = Instance.new('TextBox')
requestAddPetBox.Size, requestAddPetBox.Position, requestAddPetBox.BackgroundColor3, requestAddPetBox.BackgroundTransparency, requestAddPetBox.Text, requestAddPetBox.Font, requestAddPetBox.TextSize, requestAddPetBox.TextColor3, requestAddPetBox.ClearTextOnFocus, requestAddPetBox.TextXAlignment, requestAddPetBox.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 82), Color3.fromRGB(40, 40, 50), 0.2, tostring(CONFIG.ADD_PET_REQUEST_DELAY), Enum.Font.SourceSans, 11, Color3.fromRGB(255, 255, 255), false, Enum.TextXAlignment.Center, petInputSection
Instance.new('UICorner', requestAddPetBox).CornerRadius = UDim.new(0, 4)
requestAddPetBox.FocusLost:Connect(function() CONFIG.ADD_PET_REQUEST_DELAY = math.clamp(tonumber(requestAddPetBox.Text) or 0, 0, 99) end)

local addPetButton = createButton('Add Pet to Trade', Color3.fromRGB(0, 100, 200), Color3.fromRGB(255, 200, 50), petInputSection, function()
   local petName = petNameBox.Text
   if petName and petName ~= '' then addPetToPartnerOffer(petName, petSpawnState.activeFlags) end
end)

local removePetButton2 = createButton('Remove Latest Pet', Color3.fromRGB(200, 50, 50), Color3.fromRGB(255, 100, 100), petInputSection, function()
   removeLatestPetFromPartnerOffer()
end)

local addRandomPetButton = createButton('Add Random High-Value Pet', Color3.fromRGB(100, 50, 150), Color3.fromRGB(255, 200, 50), petInputSection, function()
   addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties())
end)

local petListSection = Instance.new('Frame')
petListSection.Size, petListSection.Position, petListSection.BackgroundTransparency, petListSection.Parent = UDim2.new(1, 0, 0, 380), UDim2.new(0, 0, 0, 195), 1, petsFrame

local petListHeading = Instance.new('TextLabel')
petListHeading.Size, petListHeading.Position, petListHeading.BackgroundTransparency, petListHeading.Text, petListHeading.Font, petListHeading.TextSize, petListHeading.TextColor3, petListHeading.TextXAlignment, petListHeading.Parent = UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), 1, 'High-Value Pets (Balloon Unicorn+)', Enum.Font.SourceSansSemibold, 11, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petListSection

local petListFrame = Instance.new('ScrollingFrame')
petListFrame.Size, petListFrame.Position, petListFrame.BackgroundColor3, petListFrame.BackgroundTransparency, petListFrame.BorderSizePixel, petListFrame.ScrollBarThickness, petListFrame.ScrollBarImageColor3, petListFrame.ScrollBarImageTransparency, petListFrame.Parent = UDim2.new(1, 0, 0, 380), UDim2.new(0, 0, 0, 18), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, petListSection
Instance.new('UICorner', petListFrame).CornerRadius = UDim.new(0, 4)
local petListLayout = Instance.new('UIListLayout')
petListLayout.SortOrder, petListLayout.Padding, petListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), petListFrame
local petListPadding = Instance.new('UIPadding')
petListPadding.PaddingTop, petListPadding.PaddingBottom, petListPadding.PaddingLeft, petListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
petListPadding.Parent = petListFrame

for i, petName in ipairs(completePetList) do
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.LayoutOrder, button.Parent = UDim2.new(1, -8, 0, 28), Color3.fromRGB(55, 50, 75), 0.1, petName, Enum.Font.GothamBold, 10, Color3.fromRGB(255, 255, 255), i, petListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 6)
   local buttonStroke = Instance.new('UIStroke')
   buttonStroke.ApplyStrokeMode, buttonStroke.Color, buttonStroke.Thickness, buttonStroke.Transparency, buttonStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, button
   
   button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play() end)
   button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play() end)
   button.MouseButton1Click:Connect(function()
       petNameBox.Text = petName
       TweenService:Create(petNameStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Color3.fromRGB(255, 200, 50), Thickness = 1.5 }):Play()
       task.wait(0.5)
       TweenService:Create(petNameStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Color3.fromRGB(100, 100, 100), Thickness = 0.8 }):Play()
   end)
end
petListFrame.CanvasSize = UDim2.new(0, 0, 0, (#completePetList * 29) + 8)

-- ==================== USERS TAB CONTENT ====================
local usersFrame = tabFrames['Users']

local userSearchBox = Instance.new('TextBox')
userSearchBox.Size, userSearchBox.Position, userSearchBox.BackgroundColor3, userSearchBox.BackgroundTransparency, userSearchBox.Text, userSearchBox.PlaceholderText, userSearchBox.Font, userSearchBox.TextSize, userSearchBox.TextColor3, userSearchBox.TextXAlignment, userSearchBox.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), Color3.fromRGB(40, 40, 50), 0.2, '', 'Search users...', Enum.Font.SourceSans, 12, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left, usersFrame
Instance.new('UICorner', userSearchBox).CornerRadius = UDim.new(0, 4)
userSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshUserList)

local userListFrame = Instance.new('ScrollingFrame')
userListFrame.Size, userListFrame.Position, userListFrame.BackgroundColor3, userListFrame.BackgroundTransparency, userListFrame.BorderSizePixel, userListFrame.ScrollBarThickness, userListFrame.ScrollBarImageColor3, userListFrame.ScrollBarImageTransparency, userListFrame.Parent = UDim2.new(1, 0, 0, 180), UDim2.new(0, 0, 0, 30), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, usersFrame
Instance.new('UICorner', userListFrame).CornerRadius = UDim.new(0, 4)
local userListLayout = Instance.new('UIListLayout')
userListLayout.SortOrder, userListLayout.Padding, userListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), userListFrame
local userListPadding = Instance.new('UIPadding')
userListPadding.PaddingTop, userListPadding.PaddingBottom, userListPadding.PaddingLeft, userListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
userListPadding.Parent = userListFrame

local function createUserButton(username, index)
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.LayoutOrder, button.Parent = UDim2.new(1, -8, 0, 28), Color3.fromRGB(55, 50, 75), 0.1, '  ' .. username, Enum.Font.GothamBold, 11, Color3.fromRGB(255, 255, 255), index, userListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 6)
   local buttonStroke = Instance.new('UIStroke')
   buttonStroke.ApplyStrokeMode, buttonStroke.Color, buttonStroke.Thickness, buttonStroke.Transparency, buttonStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, button
   
   button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play() end)
   button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play() end)
   button.MouseButton1Click:Connect(function()
       setActiveTab('Control')
       partnerBox.Text = username
       updatePartnerFromUsername(username)
   end)
   return button
end

local function refreshUserList()
   for _, child in ipairs(userListFrame:GetChildren()) do if child:IsA('TextButton') then child:Destroy() end end
   UIState.userListButtons = {}
   local searchText = userSearchBox.Text:lower()
   local filteredUsers = {}
   for _, username in ipairs(CONFIG.CUSTOM_USERS) do
       if searchText == '' or username:lower():sub(1, #searchText) == searchText then
           table.insert(filteredUsers, username)
       end
   end
   table.sort(filteredUsers, function(a, b) return a:lower() < b:lower() end)
   for i, username in ipairs(filteredUsers) do
       local button = createUserButton(username, i)
       table.insert(UIState.userListButtons, button)
   end
   userListFrame.CanvasSize = UDim2.new(0, 0, 0, (#filteredUsers * 29) + 8)
end

userSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshUserList)
refreshUserList()

local chatListFrame = Instance.new('ScrollingFrame')
chatListFrame.Size, chatListFrame.Position, chatListFrame.BackgroundColor3, chatListFrame.BackgroundTransparency, chatListFrame.BorderSizePixel, chatListFrame.ScrollBarThickness, chatListFrame.ScrollBarImageColor3, chatListFrame.ScrollBarImageTransparency, chatListFrame.Parent = UDim2.new(1, 0, 0, 300), UDim2.new(0, 0, 0, 313), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, usersFrame
Instance.new('UICorner', chatListFrame).CornerRadius = UDim.new(0, 4)
local chatListLayout = Instance.new('UIListLayout')
chatListLayout.SortOrder, chatListLayout.Padding, chatListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), chatListFrame
local chatListPadding = Instance.new('UIPadding')
chatListPadding.PaddingTop, chatListPadding.PaddingBottom, chatListPadding.PaddingLeft, chatListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
chatListPadding.Parent = chatListFrame

for i, message in ipairs(CONFIG.CHAT_MESSAGES) do
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.TextTruncate, button.LayoutOrder, button.Parent = UDim2.new(1, -8, 0, 24), Color3.fromRGB(55, 50, 75), 0.1, '  ' .. message, Enum.Font.GothamMedium, 10, Color3.fromRGB(255, 255, 255), Enum.TextTruncate.AtEnd, i, chatListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 5)
   local buttonStroke = Instance.new('UIStroke')
   buttonStroke.ApplyStrokeMode, buttonStroke.Color, buttonStroke.Thickness, buttonStroke.Transparency, buttonStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, button
   button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play() end)
   button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play() end)
   button.MouseButton1Click:Connect(function() sendTradeChatMessage(message) end)
end
chatListFrame.CanvasSize = UDim2.new(0, 0, 0, (#CONFIG.CHAT_MESSAGES * 27) + 8)

-- ==================== PETS TAB CONTENT ====================
local petsFrame = tabFrames['Pets']

local petInputSection = Instance.new('Frame')
petInputSection.Size, petInputSection.Position, petInputSection.BackgroundTransparency, petInputSection.Parent = UDim2.new(1, 0, 0, 190), UDim2.new(0, 0, 0, 0), 1, petsFrame

local petNameHeading = Instance.new('TextLabel')
petNameHeading.Size, petNameHeading.Position, petNameHeading.BackgroundTransparency, petNameHeading.Text, petNameHeading.Font, petNameHeading.TextSize, petNameHeading.TextColor3, petNameHeading.TextXAlignment, petNameHeading.Parent = UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), 1, 'Pet Name To Add', Enum.Font.SourceSansSemibold, 11, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petInputSection

local petNameBox = Instance.new('TextBox')
petNameBox.Size, petNameBox.Position, petNameBox.BackgroundColor3, petNameBox.BackgroundTransparency, petNameBox.Text, petNameBox.PlaceholderText, petNameBox.Font, petNameBox.TextSize, petNameBox.TextColor3, petNameBox.ClearTextOnFocus, petNameBox.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 18), Color3.fromRGB(40, 40, 50), 0.2, '', 'Enter pet name...', Enum.Font.FredokaOne, 11, Color3.fromRGB(255, 255, 255), false, petInputSection
Instance.new('UICorner', petNameBox).CornerRadius = UDim.new(0, 4)
local petNameStroke = Instance.new('UIStroke')
petNameStroke.ApplyStrokeMode, petNameStroke.Color, petNameStroke.Thickness, petNameStroke.Transparency, petNameStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(100, 100, 100), 0.8, 0.5, petNameBox

local propContainer = Instance.new('Frame')
propContainer.Size, propContainer.Position, propContainer.BackgroundTransparency, propContainer.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 49), 1, petInputSection

for i, p in ipairs(prefixes) do
   local btn = Instance.new('TextButton')
   btn.Size, btn.Position, btn.BackgroundColor3, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(0.23, 0, 1, 0), UDim2.new((i - 1) * 0.25 + 0.01, 0, 0, 0), Color3.fromRGB(60, 60, 70), p, Enum.Font.FredokaOne, 13, Color3.fromRGB(255, 255, 255), propContainer
   Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 4)
   local stroke = Instance.new('UIStroke')
   stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, prefixColors[p], 1.0, 0.5, btn
   prefixButtons[p] = { button = btn, stroke = stroke }
   
   btn.MouseButton1Click:Connect(function()
       if p == 'M' and petSpawnState.activeFlags['N'] then return end
       if p == 'N' and petSpawnState.activeFlags['M'] then return end
       petSpawnState.activeFlags[p] = not petSpawnState.activeFlags[p]
       btn.BackgroundColor3 = petSpawnState.activeFlags[p] and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 60, 70)
       TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Color = petSpawnState.activeFlags[p] and Color3.fromRGB(0, 255, 0) or prefixColors[p], Thickness = petSpawnState.activeFlags[p] and 1.2 or 1.0, Transparency = petSpawnState.activeFlags[p] and 0.2 or 0.5 }):Play()
   end)
end

local addPetDelayText = Instance.new('TextLabel')
addPetDelayText.Size, addPetDelayText.Position, addPetDelayText.BackgroundTransparency, addPetDelayText.Text, addPetDelayText.Font, addPetDelayText.TextSize, addPetDelayText.TextColor3, addPetDelayText.TextXAlignment, addPetDelayText.Parent = UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 68), 1, 'Add Pet Delay (s)', Enum.Font.SourceSansSemibold, 10, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petInputSection

local requestAddPetBox = Instance.new('TextBox')
requestAddPetBox.Size, requestAddPetBox.Position, requestAddPetBox.BackgroundColor3, requestAddPetBox.BackgroundTransparency, requestAddPetBox.Text, requestAddPetBox.Font, requestAddPetBox.TextSize, requestAddPetBox.TextColor3, requestAddPetBox.ClearTextOnFocus, requestAddPetBox.TextXAlignment, requestAddPetBox.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 82), Color3.fromRGB(40, 40, 50), 0.2, tostring(CONFIG.ADD_PET_REQUEST_DELAY), Enum.Font.SourceSans, 11, Color3.fromRGB(255, 255, 255), false, Enum.TextXAlignment.Center, petInputSection
Instance.new('UICorner', requestAddPetBox).CornerRadius = UDim.new(0, 4)
requestAddPetBox.FocusLost:Connect(function() CONFIG.ADD_PET_REQUEST_DELAY = math.clamp(tonumber(requestAddPetBox.Text) or 0, 0, 99) end)

local addPetButton = createButton('Add Pet to Trade', Color3.fromRGB(0, 100, 200), Color3.fromRGB(255, 200, 50), petInputSection, function()
   local petName = petNameBox.Text
   if petName and petName ~= '' then addPetToPartnerOffer(petName, petSpawnState.activeFlags) end
end)

local removePetButton2 = createButton('Remove Latest Pet', Color3.fromRGB(200, 50, 50), Color3.fromRGB(255, 100, 100), petInputSection, function()
   removeLatestPetFromPartnerOffer()
end)

local addRandomPetButton = createButton('Add Random High-Value Pet', Color3.fromRGB(100, 50, 150), Color3.fromRGB(255, 200, 50), petInputSection, function()
   addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties())
end)

local petListSection = Instance.new('Frame')
petListSection.Size, petListSection.Position, petListSection.BackgroundTransparency, petListSection.Parent = UDim2.new(1, 0, 0, 380), UDim2.new(0, 0, 0, 195), 1, petsFrame

local petListHeading = Instance.new('TextLabel')
petListHeading.Size, petListHeading.Position, petListHeading.BackgroundTransparency, petListHeading.Text, petListHeading.Font, petListHeading.TextSize, petListHeading.TextColor3, petListHeading.TextXAlignment, petListHeading.Parent = UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), 1, 'High-Value Pets (Balloon Unicorn+)', Enum.Font.SourceSansSemibold, 11, Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Left, petListSection

local petListFrame = Instance.new('ScrollingFrame')
petListFrame.Size, petListFrame.Position, petListFrame.BackgroundColor3, petListFrame.BackgroundTransparency, petListFrame.BorderSizePixel, petListFrame.ScrollBarThickness, petListFrame.ScrollBarImageColor3, petListFrame.ScrollBarImageTransparency, petListFrame.Parent = UDim2.new(1, 0, 0, 380), UDim2.new(0, 0, 0, 18), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, petListSection
Instance.new('UICorner', petListFrame).CornerRadius = UDim.new(0, 4)
local petListLayout = Instance.new('UIListLayout')
petListLayout.SortOrder, petListLayout.Padding, petListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), petListFrame
local petListPadding = Instance.new('UIPadding')
petListPadding.PaddingTop, petListPadding.PaddingBottom, petListPadding.PaddingLeft, petListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
petListPadding.Parent = petListFrame

for i, petName in ipairs(completePetList) do
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.LayoutOrder, button.Parent = UDim2.new(1, -8, 0, 28), Color3.fromRGB(55, 50, 75), 0.1, petName, Enum.Font.GothamBold, 10, Color3.fromRGB(255, 255, 255), i, petListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 6)
   local buttonStroke = Instance.new('UIStroke')
   buttonStroke.ApplyStrokeMode, buttonStroke.Color, buttonStroke.Thickness, buttonStroke.Transparency, buttonStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, button
   
   button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play() end)
   button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play() end)
   button.MouseButton1Click:Connect(function()
       petNameBox.Text = petName
       TweenService:Create(petNameStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Color3.fromRGB(255, 200, 50), Thickness = 1.5 }):Play()
       task.wait(0.5)
       TweenService:Create(petNameStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Color3.fromRGB(100, 100, 100), Thickness = 0.8 }):Play()
   end)
end
petListFrame.CanvasSize = UDim2.new(0, 0, 0, (#completePetList * 29) + 8)

-- ==================== USERS TAB CONTENT ====================
local usersFrame = tabFrames['Users']

local userSearchBox = Instance.new('TextBox')
userSearchBox.Size, userSearchBox.Position, userSearchBox.BackgroundColor3, userSearchBox.BackgroundTransparency, userSearchBox.Text, userSearchBox.PlaceholderText, userSearchBox.Font, userSearchBox.TextSize, userSearchBox.TextColor3, userSearchBox.TextXAlignment, userSearchBox.Parent = UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), Color3.fromRGB(40, 40, 50), 0.2, '', 'Search users...', Enum.Font.SourceSans, 12, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left, usersFrame
Instance.new('UICorner', userSearchBox).CornerRadius = UDim.new(0, 4)
userSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshUserList)

local userListFrame = Instance.new('ScrollingFrame')
userListFrame.Size, userListFrame.Position, userListFrame.BackgroundColor3, userListFrame.BackgroundTransparency, userListFrame.BorderSizePixel, userListFrame.ScrollBarThickness, userListFrame.ScrollBarImageColor3, userListFrame.ScrollBarImageTransparency, userListFrame.Parent = UDim2.new(1, 0, 0, 180), UDim2.new(0, 0, 0, 30), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, usersFrame
Instance.new('UICorner', userListFrame).CornerRadius = UDim.new(0, 4)
local userListLayout = Instance.new('UIListLayout')
userListLayout.SortOrder, userListLayout.Padding, userListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), userListFrame
local userListPadding = Instance.new('UIPadding')
userListPadding.PaddingTop, userListPadding.PaddingBottom, userListPadding.PaddingLeft, userListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
userListPadding.Parent = userListFrame

local chatListFrame = Instance.new('ScrollingFrame')
chatListFrame.Size, chatListFrame.Position, chatListFrame.BackgroundColor3, chatListFrame.BackgroundTransparency, chatListFrame.BorderSizePixel, chatListFrame.ScrollBarThickness, chatListFrame.ScrollBarImageColor3, chatListFrame.ScrollBarImageTransparency, chatListFrame.Parent = UDim2.new(1, 0, 0, 300), UDim2.new(0, 0, 0, 313), Color3.fromRGB(25, 25, 35), 0.5, 0, 4, Color3.fromRGB(100, 100, 100), 0.5, usersFrame
Instance.new('UICorner', chatListFrame).CornerRadius = UDim.new(0, 4)
local chatListLayout = Instance.new('UIListLayout')
chatListLayout.SortOrder, chatListLayout.Padding, chatListLayout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 0, 0, 3), chatListFrame
local chatListPadding = Instance.new('UIPadding')
chatListPadding.PaddingTop, chatListPadding.PaddingBottom, chatListPadding.PaddingLeft, chatListPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
chatListPadding.Parent = chatListFrame

for i, message in ipairs(CONFIG.CHAT_MESSAGES) do
   local button = Instance.new('TextButton')
   button.Size, button.BackgroundColor3, button.BackgroundTransparency, button.Text, button.Font, button.TextSize, button.TextColor3, button.TextTruncate, button.LayoutOrder, button.Parent = UDim2.new(1, -8, 0, 24), Color3.fromRGB(55, 50, 75), 0.1, '  ' .. message, Enum.Font.GothamMedium, 10, Color3.fromRGB(255, 255, 255), Enum.TextTruncate.AtEnd, i, chatListFrame
   Instance.new('UICorner', button).CornerRadius = UDim.new(0, 5)
   local buttonStroke = Instance.new('UIStroke')
   buttonStroke.ApplyStrokeMode, buttonStroke.Color, buttonStroke.Thickness, buttonStroke.Transparency, buttonStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, button
   button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 220, 80), Transparency = 0 }):Play() end)
   button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(55, 50, 75) }):Play(); TweenService:Create(buttonStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(255, 200, 50), Transparency = 0.2 }):Play() end)
   button.MouseButton1Click:Connect(function() sendTradeChatMessage(message) end)
end
chatListFrame.CanvasSize = UDim2.new(0, 0, 0, (#CONFIG.CHAT_MESSAGES * 27) + 8)

-- ==================== SETS TAB CONTENT ====================
local setsFrame = tabFrames['Sets']

-- Keybind Settings
local function createKeybindRow(labelText, keybindKey, layoutOrder)
   local row = Instance.new('Frame')
   row.Size, row.BackgroundColor3, row.BackgroundTransparency, row.LayoutOrder, row.Parent = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, layoutOrder, setsFrame
   Instance.new('UICorner', row).CornerRadius = UDim.new(0, 6)
   local stroke = Instance.new('UIStroke')
   stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, row
   
   local label = Instance.new('TextLabel')
   label.Size, label.Position, label.BackgroundTransparency, label.Text, label.Font, label.TextSize, label.TextColor3, label.Parent = UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, labelText, Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), row
   
   local btn = Instance.new('TextButton')
   btn.Size, btn.Position, btn.BackgroundColor3, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(0.35, -8, 0, 26), UDim2.new(0.65, 0, 0.5, -13), Color3.fromRGB(70, 65, 95), UIState.keybinds[keybindKey].Name, Enum.Font.GothamBold, 11, Color3.fromRGB(255, 255, 255), row
   Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 4)
   Instance.new('UIStroke', btn).Color = Color3.fromRGB(150, 150, 150)
   
   UIState.keybindButtons[keybindKey] = btn
   
   btn.MouseEnter:Connect(function() if UIState.waitingForKeybind ~= keybindKey then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(90, 85, 120) }):Play() end end)
   btn.MouseLeave:Connect(function() if UIState.waitingForKeybind ~= keybindKey then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(70, 65, 95) }):Play() end end)
   btn.MouseButton1Click:Connect(function()
       if UIState.waitingForKeybind then
           local old = UIState.keybindButtons[UIState.waitingForKeybind]
           if old then old.Text = UIState.keybinds[UIState.waitingForKeybind].Name; old.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
       end
       UIState.waitingForKeybind = keybindKey
       btn.Text = '...'
       btn.BackgroundColor3 = Color3.fromRGB(100, 80, 150)
   end)
   return row
end

createKeybindRow('Select Partner from Trade', 'selectPartner', 1)
createKeybindRow('Add Random Item', 'addRandomItem', 2)
createKeybindRow('Start Trade', 'startTrade', 3)
createKeybindRow('Block Player', 'blockPlayer', 4)

-- RGB Speed Settings
local spacer = Instance.new('Frame')
spacer.Size, spacer.BackgroundTransparency, spacer.LayoutOrder, spacer.Parent = UDim2.new(1, 0, 0, 10), 1, 10, setsFrame

local heading = Instance.new('TextLabel')
heading.Size, heading.BackgroundTransparency, heading.Text, heading.Font, heading.TextSize, heading.TextColor3, heading.TextXAlignment, heading.LayoutOrder, heading.Parent = UDim2.new(1, 0, 0, 18), 1, '? RGB Settings', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), Enum.TextXAlignment.Center, 11, setsFrame

local row = Instance.new('Frame')
row.Size, row.BackgroundColor3, row.BackgroundTransparency, row.LayoutOrder, row.Parent = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, 12, setsFrame
Instance.new('UICorner', row).CornerRadius = UDim.new(0, 6)
local stroke = Instance.new('UIStroke')
stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, row

local label = Instance.new('TextLabel')
label.Size, label.Position, label.BackgroundTransparency, label.Text, label.Font, label.TextSize, label.TextColor3, label.Parent = UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, 'RGB Speed', Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), row

local valueBox = Instance.new('TextBox')
valueBox.Size, valueBox.Position, valueBox.BackgroundColor3, valueBox.Text, valueBox.Font, valueBox.TextSize, valueBox.TextColor3, valueBox.Parent = UDim2.new(0.2, 0, 0, 24), UDim2.new(0.5, 0, 0.5, -12), Color3.fromRGB(70, 65, 95), '0.5', Enum.Font.GothamBold, 11, Color3.fromRGB(255, 255, 255), row
Instance.new('UICorner', valueBox).CornerRadius = UDim.new(0, 4)

local minusBtn = Instance.new('TextButton')
minusBtn.Size, minusBtn.Position, minusBtn.BackgroundColor3, minusBtn.Text, minusBtn.Font, minusBtn.TextSize, minusBtn.TextColor3, minusBtn.Parent = UDim2.new(0, 26, 0, 24), UDim2.new(0.72, 0, 0.5, -12), Color3.fromRGB(150, 60, 60), '-', Enum.Font.GothamBold, 14, Color3.fromRGB(255, 255, 255), row
Instance.new('UICorner', minusBtn).CornerRadius = UDim.new(0, 4)

local plusBtn = Instance.new('TextButton')
plusBtn.Size, plusBtn.Position, plusBtn.BackgroundColor3, plusBtn.Text, plusBtn.Font, plusBtn.TextSize, plusBtn.TextColor3, plusBtn.Parent = UDim2.new(0, 26, 0, 24), UDim2.new(0.86, 0, 0.5, -12), Color3.fromRGB(60, 150, 60), '+', Enum.Font.GothamBold, 14, Color3.fromRGB(255, 255, 255), row
Instance.new('UICorner', plusBtn).CornerRadius = UDim.new(0, 4)

minusBtn.MouseButton1Click:Connect(function() local current = math.max(0.1, (tonumber(valueBox.Text) or 0.5) - 0.1); valueBox.Text = string.format('%.1f', current); RGBState.speed = current end)
plusBtn.MouseButton1Click:Connect(function() local current = math.min(2.0, (tonumber(valueBox.Text) or 0.5) + 0.1); valueBox.Text = string.format('%.1f', current); RGBState.speed = current end)
valueBox.FocusLost:Connect(function() local val = math.clamp(tonumber(valueBox.Text) or 0.5, 0.1, 2.0); valueBox.Text = string.format('%.1f', val); RGBState.speed = val end)

-- Server Uptime
local serverInfoHeading = Instance.new('TextLabel')
serverInfoHeading.Size, serverInfoHeading.BackgroundTransparency, serverInfoHeading.Text, serverInfoHeading.Font, serverInfoHeading.TextSize, serverInfoHeading.TextColor3, serverInfoHeading.TextXAlignment, serverInfoHeading.LayoutOrder, serverInfoHeading.Parent = UDim2.new(1, 0, 0, 18), 1, '? Server Info', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), Enum.TextXAlignment.Center, 14, setsFrame

local serverUptimeRow = Instance.new('Frame')
serverUptimeRow.Size, serverUptimeRow.BackgroundColor3, serverUptimeRow.BackgroundTransparency, serverUptimeRow.LayoutOrder, serverUptimeRow.Parent = UDim2.new(1, 0, 0, 36), Color3.fromRGB(55, 50, 75), 0.1, 15, setsFrame
Instance.new('UICorner', serverUptimeRow).CornerRadius = UDim.new(0, 6)
local serverUptimeStroke = Instance.new('UIStroke')
serverUptimeStroke.ApplyStrokeMode, serverUptimeStroke.Color, serverUptimeStroke.Thickness, serverUptimeStroke.Transparency, serverUptimeStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, serverUptimeRow

local serverLabel = Instance.new('TextLabel')
serverLabel.Size, serverLabel.Position, serverLabel.BackgroundTransparency, serverLabel.Text, serverLabel.Font, serverLabel.TextSize, serverLabel.TextColor3, serverLabel.Parent = UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 8, 0, 0), 1, 'Server Uptime', Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), serverUptimeRow

local uptimeValueLabel = Instance.new('TextLabel')
uptimeValueLabel.Size, uptimeValueLabel.Position, uptimeValueLabel.BackgroundTransparency, uptimeValueLabel.Text, uptimeValueLabel.Font, uptimeValueLabel.TextSize, uptimeValueLabel.TextColor3, uptimeValueLabel.TextXAlignment, uptimeValueLabel.Parent = UDim2.new(0.5, -8, 1, 0), UDim2.new(0.5, 0, 0, 0), 1, '0h 0m 0s', Enum.Font.GothamBold, 11, Color3.fromRGB(100, 255, 150), Enum.TextXAlignment.Right, serverUptimeRow

task.spawn(function()
   while true do
       local uptime = workspace.DistributedGameTime
       uptimeValueLabel.Text = string.format('%dh %dm %ds', math.floor(uptime/3600), math.floor((uptime%3600)/60), math.floor(uptime%60))
       task.wait(1)
   end
end)

-- GUI Size Section
local spacer2 = Instance.new('Frame')
spacer2.Size, spacer2.BackgroundTransparency, spacer2.LayoutOrder, spacer2.Parent = UDim2.new(1, 0, 0, 10), 1, 16, setsFrame

local guiSizeHeading = Instance.new('TextLabel')
guiSizeHeading.Size, guiSizeHeading.BackgroundTransparency, guiSizeHeading.Text, guiSizeHeading.Font, guiSizeHeading.TextSize, guiSizeHeading.TextColor3, guiSizeHeading.TextXAlignment, guiSizeHeading.LayoutOrder, guiSizeHeading.Parent = UDim2.new(1, 0, 0, 18), 1, '? GUI Size (Mobile)', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), Enum.TextXAlignment.Center, 17, setsFrame

local guiSizeRow = Instance.new('Frame')
guiSizeRow.Size, guiSizeRow.BackgroundTransparency, guiSizeRow.LayoutOrder, guiSizeRow.Parent = UDim2.new(1, 0, 0, 40), 1, 18, setsFrame

local smallBtn = Instance.new('TextButton')
smallBtn.Size, smallBtn.Position, smallBtn.BackgroundColor3, smallBtn.Text, smallBtn.Font, smallBtn.TextSize, smallBtn.TextColor3, smallBtn.Parent = UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(80, 60, 120), '? Small', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), guiSizeRow
Instance.new('UICorner', smallBtn).CornerRadius = UDim.new(0, 6)
local ss = Instance.new('UIStroke')
ss.ApplyStrokeMode, ss.Color, ss.Thickness, ss.Transparency, ss.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, smallBtn

local bigBtn = Instance.new('TextButton')
bigBtn.Size, bigBtn.Position, bigBtn.BackgroundColor3, bigBtn.Text, bigBtn.Font, bigBtn.TextSize, bigBtn.TextColor3, bigBtn.Parent = UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(60, 120, 80), '? Big', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), guiSizeRow
Instance.new('UICorner', bigBtn).CornerRadius = UDim.new(0, 6)
local bs = Instance.new('UIStroke')
bs.ApplyStrokeMode, bs.Color, bs.Thickness, bs.Transparency, bs.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, bigBtn

local uiScale = mainFrame:FindFirstChild('UIScale') or Instance.new('UIScale')
uiScale.Name = 'UIScale'; uiScale.Parent = mainFrame
SetsUI.currentScale = 1.0 -- Default scale

smallBtn.MouseButton1Click:Connect(function()
   SetsUI.currentScale = math.max(0.7, SetsUI.currentScale - 0.05)
   uiScale.Scale = SetsUI.currentScale
   if HintApp then HintApp:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', SetsUI.currentScale * 100), length = 1, overridable = true }) end
end)

bigBtn.MouseButton1Click:Connect(function()
   SetsUI.currentScale = math.min(1.3, SetsUI.currentScale + 0.05)
   uiScale.Scale = SetsUI.currentScale
   if HintApp then HintApp:hint({ text = 'GUI Scale: ' .. string.format('%.0f%%', SetsUI.currentScale * 100), length = 1, overridable = true }) end
end)

smallBtn.MouseEnter:Connect(function() TweenService:Create(smallBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 80, 150) }):Play() end)
smallBtn.MouseLeave:Connect(function() TweenService:Create(smallBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 60, 120) }):Play() end)
bigBtn.MouseEnter:Connect(function() TweenService:Create(bigBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 150, 100) }):Play() end)
bigBtn.MouseLeave:Connect(function() TweenService:Create(bigBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 120, 80) }):Play() end)

-- Pet Value Calculator Section
do
   local PVC = { state = { M = false, N = false, F = false, R = false }, btns = {} }
   local colors = { M = {Color3.fromRGB(170,0,255), Color3.fromRGB(80,60,100)}, N = {Color3.fromRGB(255,215,0), Color3.fromRGB(80,60,100)}, F = {Color3.fromRGB(0,200,255), Color3.fromRGB(80,60,100)}, R = {Color3.fromRGB(0,255,100), Color3.fromRGB(80,60,100)} }
   
   local spacer = Instance.new('Frame')
   spacer.Size, spacer.BackgroundTransparency, spacer.LayoutOrder, spacer.Parent = UDim2.new(1, 0, 0, 10), 1, 20, setsFrame
   
   local heading = Instance.new('TextLabel')
   heading.Size, heading.BackgroundTransparency, heading.Text, heading.Font, heading.TextSize, heading.TextColor3, heading.TextXAlignment, heading.LayoutOrder, heading.Parent = UDim2.new(1, 0, 0, 18), 1, '? Pet Value Calculator', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 200, 50), Enum.TextXAlignment.Center, 21, setsFrame
   
   local inputRow = Instance.new('Frame')
   inputRow.Size, inputRow.BackgroundColor3, inputRow.BackgroundTransparency, inputRow.LayoutOrder, inputRow.Parent = UDim2.new(1, 0, 0, 30), Color3.fromRGB(55, 50, 75), 0.1, 22, setsFrame
   Instance.new('UICorner', inputRow).CornerRadius = UDim.new(0, 6)
   local inputStroke = Instance.new('UIStroke')
   inputStroke.ApplyStrokeMode, inputStroke.Color, inputStroke.Thickness, inputStroke.Transparency, inputStroke.Parent = Enum.ApplyStrokeMode.Border, Color3.fromRGB(255, 200, 50), 1.5, 0.2, inputRow
   
   PVC.input = Instance.new('TextBox')
   PVC.input.Size, PVC.input.Position, PVC.input.BackgroundTransparency, PVC.input.Text, PVC.input.PlaceholderText, PVC.input.Font, PVC.input.TextSize, PVC.input.TextColor3, PVC.input.TextXAlignment, PVC.input.Parent = UDim2.new(1, -16, 1, -6), UDim2.new(0, 8, 0, 3), 1, '', 'Enter pet name...', Enum.Font.GothamMedium, 11, Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 150, 160), Enum.TextXAlignment.Left, inputRow
   
   local propRow = Instance.new('Frame')
   propRow.Size, propRow.BackgroundTransparency, propRow.LayoutOrder, propRow.Parent = UDim2.new(1, 0, 0, 28), 1, 23, setsFrame
   
   for i, p in ipairs({ 'M', 'N', 'F', 'R' }) do
       local btn = Instance.new('TextButton')
       btn.Size, btn.Position, btn.BackgroundColor3, btn.Text, btn.Font, btn.TextSize, btn.TextColor3, btn.Parent = UDim2.new(0.24, -4, 1, 0), UDim2.new((i - 1) * 0.25 + 2, 0, 0, 0), colors[p][2], p, Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), propRow
       Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 4)
       PVC.btns[p] = btn
       btn.MouseButton1Click:Connect(function()
           if p == 'M' and PVC.state.N then PVC.state.N = false; PVC.btns.N.BackgroundColor3 = colors.N[2] end
           if p == 'N' and PVC.state.M then PVC.state.M = false; PVC.btns.M.BackgroundColor3 = colors.M[2] end
           PVC.state[p] = not PVC.state[p]
           btn.BackgroundColor3 = PVC.state[p] and colors[p][1] or colors[p][2]
       end)
   end
   
   local calcButton = Instance.new('TextButton')
   calcButton.Size, calcButton.BackgroundColor3, calcButton.Text, calcButton.Font, calcButton.TextSize, calcButton.TextColor3, calcButton.LayoutOrder, calcButton.Parent = UDim2.new(1, 0, 0, 32), Color3.fromRGB(80, 160, 80), '? Calculate Value', Enum.Font.GothamBold, 12, Color3.fromRGB(255, 255, 255), 24, setsFrame
   Instance.new('UICorner', calcButton).CornerRadius = UDim.new(0, 6)
   local cbs = Instance.new('UIStroke')
   cbs.Color, cbs.Thickness, cbs.Transparency, cbs.Parent = Color3.fromRGB(255, 200, 50), 1.5, 0.2, calcButton
   
   PVC.result = Instance.new('TextLabel')
   PVC.result.Size, PVC.result.BackgroundColor3, PVC.result.Text, PVC.result.Font, PVC.result.TextSize, PVC.result.TextColor3, PVC.result.LayoutOrder, PVC.result.Parent = UDim2.new(1, -8, 0, 36), Color3.fromRGB(40, 35, 55), 'Value: --', Enum.Font.GothamBold, 14, Color3.fromRGB(100, 255, 150), 25, setsFrame
   Instance.new('UICorner', PVC.result).CornerRadius = UDim.new(0, 6)
   local rs = Instance.new('UIStroke')
   rs.Color, rs.Thickness, rs.Transparency, rs.Parent = Color3.fromRGB(255, 200, 50), 1.5, 0.2, PVC.result
   
   calcButton.MouseButton1Click:Connect(function()
       local sn = PVC.input.Text:lower():gsub('%s+', '')
       if sn == '' then PVC.result.Text, PVC.result.TextColor3 = 'Enter a pet name!', Color3.fromRGB(255, 100, 100) return end
       local fp, fk = nil, nil
       for k, pet in pairs(petsByName) do
           if k:lower():gsub('%s+','') == sn or k:lower():gsub('%s+',''):find(sn,1,true) then fp, fk = pet, k break end
       end
       if not fp then PVC.result.Text, PVC.result.TextColor3 = 'Pet not found!', Color3.fromRGB(255, 100, 100) return end
       local bk = PVC.state.M and "mvalue" or (PVC.state.N and "nvalue" or "rvalue")
       local sf = (PVC.state.R and PVC.state.F) and " - fly&ride" or (PVC.state.R and " - ride" or (PVC.state.F and " - fly" or " - nopotion"))
       local v = fp[bk..sf] or fp[bk] or 0
       local fv = v >= 1e9 and string.format('%.2fB',v/1e9) or (v >= 1e6 and string.format('%.2fM',v/1e6) or (v >= 1e3 and string.format('%.2fK',v/1e3) or tostring(v)))
       local ps = (PVC.state.M and 'Mega ' or '')..(PVC.state.N and 'Neon ' or '')..(PVC.state.F and 'F' or '')..(PVC.state.R and 'R' or ''); if ps == '' then ps = 'Normal' end
       PVC.result.Text, PVC.result.TextColor3 = fk..' ('..ps..'): '..fv, Color3.fromRGB(100, 255, 150)
   end)
   calcButton.MouseEnter:Connect(function() TweenService:Create(calcButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 160, 80) }):Play() end)
   calcButton.MouseLeave:Connect(function() TweenService:Create(calcButton, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 120, 80) }):Play() end)
end

-- ==================== INITIALIZATION AND EVENT CONNECTIONS ====================
local function initialize()
   -- Ensure all original functions are stored
   local TradeAppExists = pcall(function() return UIManager.apps.TradeApp end)
   if TradeAppExists and TradeAppExists.value then
       storeOriginalFunctions()
       hookTradeFunctions()
       hookTradeHistoryFunctions()
       hookDialogApp()
       hookTradeRequestEvent()
   end
   
   -- Load pet names for the spawner
   local petNames = {}
   for category_name, category_table in pairs(InventoryDB) do
       if category_name == 'pets' then
           for id, item in pairs(category_table) do
               table.insert(petNames, item.name)
           end
           break
       end
   end
   petSpawnState.validPetNames = petNames
   
   -- Set initial state for buttons and UI
   local autoSpectateButton = mainFrame:FindFirstChild('Control'):FindFirstChild('AutoSpectateButton')
   if autoSpectateButton then
       autoSpectateButton.Text = '? Auto Spectate: ' .. (CONFIG.AUTO_SPECTATE_ENABLED and 'ON (Random)' or 'OFF')
       autoSpectateButton.BackgroundColor3 = CONFIG.AUTO_SPECTATE_ENABLED and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
   end
   
   local removePetsButton = mainFrame:FindFirstChild('Control'):FindFirstChild('Remove Partner Pets: OFF')
   if removePetsButton then
       removePetsButton.Text = 'Remove Partner Pets: ' .. (CONFIG.REMOVE_PARTNER_PETS_ON_CONFIRM and 'ON' or 'OFF')
       removePetsButton.BackgroundColor3 = CONFIG.REMOVE_PARTNER_PETS_ON_CONFIRM and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
   end
   
   -- Initial Noclip State
   UIState.noclipEnabled = true
   local noclipButton = mainFrame:FindFirstChild('Control'):FindFirstChild('Toggle Noclip: ON')
   if noclipButton then
       local noclipStroke = noclipButton:FindFirstChildOfClass('UIStroke')
       noclipButton.Text = 'Toggle Noclip: ON'
       noclipButton.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
       if noclipStroke then noclipStroke.Color = Color3.fromRGB(100, 100, 255) end
   end
   
   -- Initial Pet Value State
   for _, p in ipairs({ 'M', 'N', 'F', 'R' }) do
       local btn = UIState.keybindButtons[p]
       if btn then
           local stroke = btn:FindFirstChildOfClass('UIStroke')
           btn.BackgroundColor3 = PVC.state[p] and colors[p][1] or colors[p][2]
           if stroke then
               stroke.Color = PVC.state[p] and colors[p][1] or colors[p][2]
               stroke.Thickness = PVC.state[p] and 1.2 or 1.0
               stroke.Transparency = PVC.state[p] and 0.2 or 0.5
           end
       end
   end
   
   -- Initial RGB State
   local rgbValBox = mainFrame:FindFirstChild('Sets'):FindFirstChild('TextBox')
   if rgbValBox then rgbValBox.Text = tostring(RGBState.speed) end
   
   -- Initial Player List State
   refreshPlayerList()
   createSelectFromTradeButton()
   
   -- Initial Users List State
   refreshUserList()
   
   -- Initial Fake Player/Pet State
   pcall(function()
       local existingPlayers = {}
       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer then table.insert(existingPlayers, player) end
       end
       for i, player in ipairs(existingPlayers) do
           if player and player.UserId then
               local success, err = pcall(function()
                   CreateFakePlayerCharacterFromPARTNER_NAME(player.Name, player.UserId, nil, nil)
               end)
               if not success then warn('Error creating initial fake player:', player.Name, err) end
           end
       end
   end)
   
   -- Initial Pet Value Calculation
   local petNameBox = petsFrame:FindFirstChild('PetInputSection'):FindFirstChild('TextBox')
   local calcButton = petsFrame:FindFirstChild('Calculate Value')
   local calcResultLabel = petsFrame:FindFirstChild('ResultLabel')
   if petNameBox and calcButton and calcResultLabel then
       local sn = petNameBox.Text:lower():gsub('%s+', '')
       if sn ~= '' and sn ~= 'enter pet name...' then
           local fp, fk = nil, nil
           for k, pet in pairs(petsByName) do
               if k:lower():gsub('%s+','') == sn or k:lower():gsub('%s+',''):find(sn,1,true) then fp, fk = pet, k break end
           end
           if fp then
               local bk = petSpawnState.activeFlags.M and "mvalue" or (petSpawnState.activeFlags.N and "nvalue" or "rvalue")
               local sf = (petSpawnState.activeFlags.R and petSpawnState.activeFlags.F) and " - fly&ride" or (petSpawnState.activeFlags.R and " - ride" or (petSpawnState.activeFlags.F and " - fly" or " - nopotion"))
               local v = fp[bk..sf] or fp[bk] or 0
               local fv = v >= 1e9 and string.format('%.2fB',v/1e9) or (v >= 1e6 and string.format('%.2fM',v/1e6) or (v >= 1e3 and string.format('%.2fK',v/1e3) or tostring(v)))
               local ps = (petSpawnState.activeFlags.M and 'Mega ' or '')..(petSpawnState.activeFlags.N and 'Neon ' or '')..(petSpawnState.activeFlags.F and 'F' or '')..(petSpawnState.activeFlags.R and 'R' or ''); if ps == '' then ps = 'Normal' end
               calcResultLabel.Text, calcResultLabel.TextColor3 = fk..' ('..ps..'): '..fv, Color3.fromRGB(100,255,150)
           else
               calcResultLabel.Text, calcResultLabel.TextColor3 = 'Pet not found!', Color3.fromRGB(255,100,100)
           end
       end
   end
   
   -- Initial Auto Refresh State
   local autoRefreshButton = playersFrame:FindFirstChild('Auto Refresh Button')
   if autoRefreshButton then
       RefreshState.autoRefreshEnabled = true
       autoRefreshButton.Text = 'Auto: ON'
       autoRefreshButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
       refreshRichestPlayers(true)
   end
end

initialize()

-- ==================== KEYBIND HANDLER ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   
   if UIState.waitingForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
       local key = input.KeyCode
       if key == Enum.KeyCode.Escape then
           local button = UIState.keybindButtons[UIState.waitingForKeybind]
           if button then button.Text = UIState.keybinds[UIState.waitingForKeybind].Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
           UIState.waitingForKeybind = nil
           return
       end
       UIState.keybinds[UIState.waitingForKeybind] = key
       local button = UIState.keybindButtons[UIState.waitingForKeybind]
       if button then button.Text = key.Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
       UIState.waitingForKeybind = nil
       if HintApp then HintApp:hint({ text = 'Keybind set to ' .. key.Name, length = 2, overridable = true }) end
       return
   end
   
   -- Handle keybind actions
   if input.UserInputType == Enum.UserInputType.Keyboard and not UIState.waitingForKeybind then
       local key = input.KeyCode
       if key == UIState.keybinds.selectPartner then
           local partner = mockState.active and mockState.trade and mockState.trade.recipient or TradeApp:_get_partner()
           if partner and partner.Name then
               partnerBox.Text = partner.Name
               updatePartnerFromUsername(partner.Name)
               if HintApp then HintApp:hint({ text = 'Partner set to ' .. partner.Name, length = 2, overridable = true }) end
           end
       elseif key == UIState.keybinds.addRandomItem then
           if mockState.active then addPetToPartnerOffer(getRandomHighValuePet(), generateRandomPetProperties()) end
       elseif key == UIState.keybinds.startTrade then
           if not mockState.active then task.spawn(startMockTradeDirectly) end
       elseif key == UIState.keybinds.blockPlayer then
           local player = Players:FindFirstChild(partnerBox.Text)
           if player then BlockPlayer(player) end
       end
   end
end)

-- ==================== DRAGGABLE GUI & KEYBOARD SHORTCUTS ====================
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
       dragging = true; dragStart = input.Position; startPos = mainFrame.Position
       input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
   end
end)

mainFrame.InputChanged:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
       dragInput = input
   end
end)

UserInputService.InputChanged:Connect(function(input)
   if input == dragInput and dragging then
       local delta = input.Position - dragStart
       mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
   end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   if input.KeyCode == Enum.KeyCode.F6 then mainFrame.Visible = not mainFrame.Visible end
   if UIState.waitingForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
       local key = input.KeyCode
       if key == Enum.KeyCode.Escape then
           local button = UIState.keybindButtons[UIState.waitingForKeybind]
           if button then button.Text = UIState.keybinds[UIState.waitingForKeybind].Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
           UIState.waitingForKeybind = nil
           return
       end
       UIState.keybinds[UIState.waitingForKeybind] = key
       local button = UIState.keybindButtons[UIState.waitingForKeybind]
       if button then button.Text = key.Name; button.BackgroundColor3 = Color3.fromRGB(70, 65, 95) end
       UIState.waitingForKeybind = nil
       if HintApp then HintApp:hint({ text = 'Keybind set to ' .. key.Name, length = 2, overridable = true }) end
   end
end)

-- ==================== NOCLIP MAINTENANCE ====================
task.spawn(function()
   while true do
       task.wait(1)
       if UIState.noclipEnabled then enableNoclipForAllFakePlayers(); enableNoclipForPets() end
   end
end)

-- ==================== FINAL INITIALIZATION ====================
if UIState.activeTabPulseTween == nil then
   local data = tabElements['Control']
   if data then
       UIState.activeTabPulseTween = TweenService:Create(data.stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
           Color = Color3.fromRGB(255, 180, 200):Lerp(Color3.fromRGB(255, 255, 255), 0.25), Thickness = 1.5
       })
       UIState.activeTabPulseTween:Play()
   end
end
refreshRichestPlayers(true)

-- ==================== AUTO PARTNER EMOJI SYSTEM ====================
_G.EmojiSystem = {
   running = false,
   reactions = load('SharedConstants').trade_spectate_reactions
}
_G.EmojiSystem.display = function(index)
   if not _G.EmojiSystem.running or not _G.EmojiSystem.reactions[index] or not mockState.active or not mockState.trade then return end
   pcall(function()
       local tradeFrame = Players.LocalPlayer.PlayerGui.TradeApp.Frame
       local e = Instance.new('ImageLabel')
       e.Image, e.BackgroundTransparency, e.ImageTransparency, e.Size, e.Position, e.AnchorPoint, e.ZIndex = _G.EmojiSystem.reactions[index], 1, 1, UDim2.fromOffset(40, 40), UDim2.new(0.92 + math.random(-3, 3) / 100, 0, 0.95, 0), Vector2.new(0.5, 1), 100
       e.Parent = tradeFrame
       TweenService:Create(e, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { ImageTransparency = 0, Size = UDim2.fromOffset(45, 45) }):Play()
       local st, dur, spd = tick(), math.random(18, 28) / 10, 0.18
       local c
       c = RunService.Heartbeat:Connect(function(dt)
           local el = tick() - st
           if el >= dur or not e.Parent then c:Disconnect(); if e.Parent then e:Destroy() end return end
           local newY = e.Position.Y.Scale - spd * dt
           local drift = math.sin(el * 4) * dt * 0.0
           e.Position = UDim2.new(math.clamp(e.Position.X.Scale + drift, 0.85, 0.98), 0, newY, 0)
           if el >= dur * 0.5 then e.ImageTransparency = (el - dur * 0.5) / (dur * 0.5) end
       end)
   end)
end

local emojiButton = Instance.new('TextButton')
emojiButton.Size, emojiButton.Position, emojiButton.BackgroundColor3, emojiButton.BackgroundTransparency, emojiButton.Text, emojiButton.Font, emojiButton.TextSize, emojiButton.TextColor3, emojiButton.Parent = UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 300), Color3.fromRGB(150, 50, 50), '? Auto Partner Emoji: OFF', Enum.Font.FredokaOne, 12, Color3.fromRGB(255, 255, 255), controlFrame
Instance.new('UICorner', emojiButton).CornerRadius = UDim.new(0, 6)

emojiButton.MouseButton1Click:Connect(function()
   _G.EmojiSystem.running = not _G.EmojiSystem.running
   emojiButton.Text = '? Auto Partner Emoji: ' .. (_G.EmojiSystem.running and 'ON' or 'OFF')
   emojiButton.BackgroundColor3 = _G.EmojiSystem.running and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
   if _G.EmojiSystem.running then
       task.spawn(function()
           while _G.EmojiSystem.running do
               task.wait(math.random(8, 20) / 10)
               if _G.EmojiSystem.running and mockState.active and mockState.trade then
                   _G.EmojiSystem.display(math.random(1, #_G.EmojiSystem.reactions))
               end
           end
       end)
   end
end)

print("ZetaScripts - Unified Control Panel Loaded!")
if TradeHistoryApp._ORIGINAL_create_trade_frame then
   TradeHistoryApp._create_trade_frame = TradeHistoryApp._ORIGINAL_create_trade_frame
end
if TradeApp._ORIGINAL_change_local_trade_state then
   TradeApp._change_local_trade_state = TradeApp._ORIGINAL_change_local_trade_state
end
if TradeApp._ORIGINAL_overwrite_local_trade_state then
   TradeApp._overwrite_local_trade_state = TradeApp._ORIGINAL_overwrite_local_trade_state
end

TradeHistoryApp._ORIGINAL_create_trade_frame = TradeHistoryApp._create_trade_frame
TradeApp._ORIGINAL_change_local_trade_state = TradeApp._change_local_trade_state
TradeApp._ORIGINAL_overwrite_local_trade_state = TradeApp._ORIGINAL_overwrite_local_trade_state

local tradeCache = {}
local currentTradeItems = nil

function TradeApp._change_local_trade_state(self, changes, ...)
   local currentState = TradeApp.local_trade_state

   if currentState and currentState.trade_id then
       local isSender = currentState.sender == LocalPlayer
       local isRecipient = currentState.recipient == LocalPlayer

       if isSender and changes.sender_offer and changes.sender_offer.items then
           tradeCache[currentState.trade_id] = {
               items = table.clone(changes.sender_offer.items),
               isSender = true
           }
           currentTradeItems = changes.sender_offer.items
       elseif isRecipient and changes.recipient_offer and changes.recipient_offer.items then
           tradeCache[currentState.trade_id] = {
               items = table.clone(changes.recipient_offer.items),
               isSender = false
           }
           currentTradeItems = changes.recipient_offer.items
       end
   end

   return TradeApp._ORIGINAL_change_local_trade_state(self, changes, ...)
end

function TradeApp._overwrite_local_trade_state(self, tradeState, ...)
   if tradeState then
       local isSender = tradeState.sender == LocalPlayer
       local isRecipient = tradeState.recipient == LocalPlayer

       if isSender and tradeState.sender_offer and currentTradeItems then
           tradeState.sender_offer.items = currentTradeItems
       elseif isRecipient and tradeState.recipient_offer and currentTradeItems then
           tradeState.recipient_offer.items = currentTradeItems
       end
   else
       currentTradeItems = nil
       if TradeApp._last_trade_id then
           tradeCache[TradeApp._last_trade_id] = nil
           TradeApp._last_trade_id = nil
       end
   end

   return TradeApp._ORIGINAL_overwrite_local_trade_state(self, tradeState, ...)
end

function TradeHistoryApp._create_trade_frame(self, tradeData, ...)
   if tradeData.trade_id and tradeCache[tradeData.trade_id] then
       local cachedData = tradeCache[tradeData.trade_id]
       local modifiedData = table.clone(tradeData)

       if cachedData.isSender then
           modifiedData.sender_items = table.clone(cachedData.items)
       else
           modifiedData.recipient_items = table.clone(cachedData.items)
       end

       return TradeHistoryApp._ORIGINAL_create_trade_frame(self, modifiedData, ...)
   end

   return TradeHistoryApp._ORIGINAL_create_trade_frame(self, tradeData, ...)
end

local HighTierPets = {
    "Shadow Dragon", "Bat Dragon", "Frost Dragon", "Giraffe", "Owl", "Parrot", "Crow",
    "Evil Unicorn", "Arctic Reindeer", "Hedgehog", "Dalmatian", "Turtle", "Kangaroo",
    "Lion", "Elephant", "Blazing Lion", "African Wild Dog", "Flamingo", "Diamond Butterfly",
    "Mini Pig", "Caterpillar", "Albino Monkey", "Candyfloss Chick", "Pelican", "Blue Dog",
    "Pink Cat", "Haetae", "Peppermint Penguin", "Winged Tiger", "Sugar Glider",
    "Shark Puppy", "Goat", "Sheeeeep", "Lion Cub", "Nessie", "Frostbite Bear",
    "Balloon Unicorn", "Honey Badger", "Hot Doggo", "Crocodile", "Hare", "Ram", "Yeti",
    "Meerkat", "Jellyfish", "Happy Clown", "Orchid Butterfly", "Many Mackerel",
    "Strawberry Shortcake Bat Dragon", "Zombie Buffalo", "Fairy Bat Dragon",
    "Chocolate Chip Bat Dragon", "Cow", "Dragonfruit Fox", "Monkey King", "Cryptid",
    "Undead Jousting Horse", "Mermicorn", "Frost Unicorn", "Irish Water Spaniel",
    "Jekyll Hydra", "Papa Moose", "Strawberry Penguin", "Bush Elephant", "Cupid Dragon",
    "Black-Chested Pheasant", "Alpaca", "Field Mouse", "Pineapple Owl", "Owlbear",
    "Tio De Nadal", "Pig", "Royal Mistletroll", "Pirate Ghost Capuchin Monkey",
    "Moose Calf", "Vampire Dragon", "Shrew", "Mechapup", "Bald Eagle",
    "Ring-Tailed Lemur", "Tortuga De La Isla", "Werewolf", "Puffin", "Fallow Deer",
    "Caelum Cervi", "Diamond Amazon", "Sea Slug", "Sugar Axolotl", "Purple Butterfly",
    "Grim Dragon", "Brown Bear", "Polar Bear", "Sakura Spirit", "Platypus", "Groundhog",
    "Lava Dragon", "Glacier Moth", "Emperor Gorilla", "2D Kitty", "Hyena",
    "Arctic Dusk Dragon", "Alley Cat", "Siamese Cat", "Phantom Dragon",
    "Christmas Pudding Pup", "Glacier Kitsune", "Giant Gold Scarab", "Diamond Albatross"
}

local SpawnedPets = {}
local PetModelCache = {}
local EquippedPet = nil
local CurrentRideId = nil
local RideAnimationTrack = nil
local PetAilmentsCache = {}
local SpawnedItems = {}

local function GenerateUniquePetName()
    local prefixes = {"✨", "💖", "🌟", "🌈", "🦄", "🌸", "🎀", "🍬", "💫", "🌙", "👑"}
    local suffixes = {"Dream", "Sparkle", "Glimmer", "Whisper", "Blossom", "Starlight", "Moonbeam", "Rainbow", "Pixie", "Cloud"}
    
    local prefix = prefixes[math.random(1, #prefixes)]
    local suffix = suffixes[math.random(1, #suffixes)]
    
    return prefix .. " " .. suffix
end

local NewnessGroups = {
    mega_neon_flyable_rideable = 990000,
    mega_neon_flyable = 980000,
    mega_neon_rideable = 970000,
    mega_neon = 960000,
    neon_flyable_rideable = 950000,
    neon_flyable = 940000,
    neon_rideable = 930000,
    neon = 920000,
    flyable_rideable = 910000,
    flyable = 900000,
    rideable = 890000,
    regular = 880000
}

local function GetPropertyGroup(properties)
    local isMega = properties.mega_neon or false
    local isNeon = properties.neon or false
    local canFly = properties.flyable or false
    local canRide = properties.rideable or false

    if isMega then
        if canFly and canRide then return "mega_neon_flyable_rideable"
        elseif canFly then return "mega_neon_flyable"
        elseif canRide then return "mega_neon_rideable"
        else return "mega_neon" end
    elseif isNeon then
        if canFly and canRide then return "neon_flyable_rideable"
        elseif canFly then return "neon_flyable"
        elseif canRide then return "neon_rideable"
        else return "neon" end
    else
        if canFly and canRide then return "flyable_rideable"
        elseif canFly then return "flyable"
        elseif canRide then return "rideable"
        else return "regular" end
    end
end

local function UpdateClientData(dataPath, modifier)
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local currentData = ClientData.get(dataPath)
    local clonedData = table.clone(currentData)
    local result = modifier(clonedData)
    ClientData.predict(dataPath, result)
    set_thread_identity(identity)
    return result
end

local function GenerateUniqueID()
    return HttpService:GenerateGUID(false)
end

local function FindInTable(array, checker)
    for index, value in pairs(array) do
        if checker(value, index) then
            return index
        end
    end
    return nil
end

local originalGetServer = ClientData.get_server

function ClientData.get_server(player, key, ...)
    local data = originalGetServer(player, key, ...)

    if key == "ailments_manager" and player == LocalPlayer then
        local ailmentsData = {}
        if data then
            for k, v in pairs(data) do
                ailmentsData[k] = type(v) == "table" and table.clone(v) or v
            end
        end
        
        ailmentsData.ailments = ailmentsData.ailments or {}
        
        for petId, _ in pairs(SpawnedPets) do
            if PetAilmentsCache[petId] then
                ailmentsData.ailments[petId] = PetAilmentsCache[petId]
            else
                local ailmentTypes = {}
                for kind, _ in pairs(AilmentsDB) do
                    if kind ~= "at_work" and kind ~= "mystery" and kind ~= "walking" then
                        table.insert(ailmentTypes, kind)
                    end
                end

                local ailmentCount = math.random(2, 4)
                local petAilments = {}
                local usedTypes = {}

                for i = 1, math.min(ailmentCount, #ailmentTypes) do
                    local ailmentKind
                    repeat
                        ailmentKind = ailmentTypes[math.random(1, #ailmentTypes)]
                    until not usedTypes[ailmentKind]
                    usedTypes[ailmentKind] = true

                    local ailmentId = GenerateUniqueID()
                    petAilments[ailmentId] = {
                        components = {},
                        created_timestamp = os.time(),
                        kind = ailmentKind,
                        progress = 0,
                        rate = 0,
                        rate_timestamp = os.time(),
                        sort_order = i * 100
                    }
                end

                PetAilmentsCache[petId] = petAilments
                ailmentsData.ailments[petId] = petAilments
            end
        end

        return ailmentsData
    end

    return data
end

local function FetchPetModel(petKind)
    if PetModelCache[petKind] then
        return PetModelCache[petKind]
    end
    local model = DownloadClient.promise_download_copy("Pets", petKind):expect()
    PetModelCache[petKind] = model
    return model
end

local function ApplyNeonVisuals(petModel, petData)
    local modelInstance = petModel:FindFirstChild("PetModel")
    if modelInstance and (petData.properties.neon or petData.properties.mega_neon) then
        local petKindData = KindDB[petData.id]
        for partName, partProps in pairs(petKindData.neon_parts) do
            local geoPart = PetRigs.get(modelInstance).get_geo_part(modelInstance, partName)
            if geoPart then
                geoPart.Material = partProps.Material
                geoPart.Color = partProps.Color
            end
        end
    end
end

local function RegisterPetWrapper(wrapperData)
    UpdateClientData("pet_char_wrappers", function(wrappers)
        wrapperData.unique = #wrappers + 1
        wrapperData.index = #wrappers + 1
        wrappers[#wrappers + 1] = wrapperData
        return wrappers
    end)
end

local function RegisterPetState(stateManager)
    UpdateClientData("pet_state_managers", function(managers)
        managers[#managers + 1] = stateManager
        return managers
    end)
end

local function RemovePetWrapper(petUniqueId)
    UpdateClientData("pet_char_wrappers", function(wrappers)
        local wrapperIndex = FindInTable(wrappers, function(w)
            return w.pet_unique == petUniqueId
        end)
        if wrapperIndex then
            table.remove(wrappers, wrapperIndex)
            for i = wrapperIndex, #wrappers do
                wrappers[i].unique = i
                wrappers[i].index = i
            end
        end
        return wrappers
    end)
end

local function RemovePetState(petUniqueId)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    UpdateClientData("pet_state_managers", function(managers)
        local managerIndex = FindInTable(managers, function(m)
            return m.char == pet.model
        end)
        if managerIndex then
            table.remove(managers, managerIndex)
        end
        return managers
    end)
end

local function ClearPetStates(petUniqueId)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    UpdateClientData("pet_state_managers", function(managers)
        local managerIndex = FindInTable(managers, function(m)
            return m.char == pet.model
        end)
        if managerIndex then
            local updated = table.clone(managers)
            updated[managerIndex] = table.clone(updated[managerIndex])
            updated[managerIndex].states = {}
            return updated
        end
        return managers
    end)
end

local function SetPetState(petUniqueId, stateId)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    UpdateClientData("pet_state_managers", function(managers)
        local managerIndex = FindInTable(managers, function(m)
            return m.char == pet.model
        end)
        if managerIndex then
            local updated = table.clone(managers)
            updated[managerIndex] = table.clone(updated[managerIndex])
            updated[managerIndex].states = {{ id = stateId }}
            return updated
        end
        return managers
    end)
end

local function ClearPlayerStates()
    UpdateClientData("state_manager", function(stateManager)
        local updated = table.clone(stateManager)
        updated.states = {}
        updated.is_sitting = false
        return updated
    end)
end

local function SetPlayerState(stateId)
    UpdateClientData("state_manager", function(stateManager)
        local updated = table.clone(stateManager)
        updated.states = {{ id = stateId }}
        updated.is_sitting = true
        return updated
    end)
end

local function AttachRideConstraint(petModel)
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return false end

    local ridePos = petModel:FindFirstChild("RidePosition", true)
    if not ridePos then return false end

    local sourceAttach = Instance.new("Attachment")
    sourceAttach.Parent = ridePos
    sourceAttach.Position = Vector3.new(0, 1.237, 0)
    sourceAttach.Name = "SourceAttachment"

    local rigidConstraint = Instance.new("RigidConstraint")
    rigidConstraint.Name = "StateConnection"
    rigidConstraint.Attachment0 = sourceAttach
    rigidConstraint.Attachment1 = character.PrimaryPart.RootAttachment
    rigidConstraint.Parent = character

    return true
end

local function DismountPet()
    if not CurrentRideId then return end

    local pet = SpawnedPets[CurrentRideId]
    if pet and pet.model then
        if RideAnimationTrack then
            RideAnimationTrack:Stop()
            RideAnimationTrack:Destroy()
            RideAnimationTrack = nil
        end

        local sourceAttach = pet.model:FindFirstChild("SourceAttachment", true)
        if sourceAttach then sourceAttach:Destroy() end

        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part:GetAttribute("HaveMass") then
                    part.Massless = false
                end
            end
        end

        ClearPetStates(CurrentRideId)
        ClearPlayerStates()
        pet.model:ScaleTo(1)
    end
    CurrentRideId = nil
end

local function MountPet(petUniqueId, playerState, petState)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart or not character:FindFirstChild("Humanoid") then return end

    DismountPet()
    CurrentRideId = petUniqueId

    SetPetState(petUniqueId, petState)
    SetPlayerState(playerState)
    pet.model:ScaleTo(2)
    AttachRideConstraint(pet.model)

    RideAnimationTrack = character.Humanoid.Animator:LoadAnimation(AnimationManager.get_track("PlayerRidingPet"))
    character.Humanoid.Sit = true

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Massless == false then
            part.Massless = true
            part:SetAttribute("HaveMass", true)
        end
    end

    RideAnimationTrack:Play()
end

local function RidePet(petUniqueId)
    MountPet(petUniqueId, "PlayerRidingPet", "PetBeingRidden")
end

local function FlyPet(petUniqueId)
    MountPet(petUniqueId, "PlayerFlyingPet", "PetBeingFlown")
end

local function UnequipPet(petData)
    local pet = SpawnedPets[petData.unique]
    if not pet or not pet.model then return end

    if CurrentRideId == petData.unique then
        DismountPet()
    end

    RemovePetWrapper(petData.unique)
    RemovePetState(petData.unique)
    pet.model:Destroy()
    pet.model = nil

    if EquippedPet and EquippedPet.unique == petData.unique then
        EquippedPet = nil
    end

    PetAilmentsCache[petData.unique] = nil
    task.wait(0.15)
    AilmentsClient.on_ailments_changed(LocalPlayer)
end

local function EquipPet(petData)
    if petData.category ~= "pets" then return end

    if EquippedPet then
        UnequipPet(EquippedPet)
    end

    for _, wrapper in pairs(ClientData.get("pet_char_wrappers")) do
        if wrapper.controller == LocalPlayer then
            RouterClient.get("ToolAPI/Unequip"):InvokeServer(wrapper.pet_unique)
        end
    end

    if not SpawnedPets[petData.unique] then
        SpawnedPets[petData.unique] = { data = petData, model = nil }
    end

    local petModel = FetchPetModel(petData.kind):Clone()
    petModel.Parent = workspace
    SpawnedPets[petData.unique].model = petModel
    ApplyNeonVisuals(petModel, petData)

    EquippedPet = petData

    task.defer(function()
        RegisterPetWrapper({
            char = petModel,
            mega_neon = petData.properties.mega_neon or false,
            neon = petData.properties.neon or false,
            player = LocalPlayer,
            entity_controller = LocalPlayer,
            controller = LocalPlayer,
            rp_name = petData.properties.rp_name or "",
            pet_trick_level = petData.properties.pet_trick_level or 0,
            pet_unique = petData.unique,
            pet_id = petData.id,
            location = {
                full_destination_id = "housing",
                destination_id = "housing",
                house_owner = LocalPlayer
            },
            pet_progression = {
                age = petData.properties.age or math.random(1, 6),
                percentage = math.random(0, 99) / 100
            },
            are_colors_sealed = false,
            is_pet = true,
        })

        RegisterPetState({
            char = petModel,
            player = LocalPlayer,
            store_key = "pet_state_managers",
            is_sitting = false,
            chars_connected_to_me = {},
            states = {}
        })
        task.wait(0.15)
        AilmentsClient.on_ailments_changed(LocalPlayer)
    end)
end

local NextToyOrder = 60000

local function CreateInventoryItem(itemId, category, properties)
    local uniqueId = GenerateUniqueID()
    local itemKindData = KindDB[itemId]

    if not itemKindData then
        warn("Item not found: " .. itemId)
        return nil
    end

    properties = properties or {}
    local newnessValue = NextToyOrder

    if category == "pets" then
        local groupKey = GetPropertyGroup(properties)
        NewnessGroups[groupKey] = NewnessGroups[groupKey] - 1
        newnessValue = NewnessGroups[groupKey]

        if not properties.ailments_completed then
            properties.ailments_completed = 0
        end

        if not properties.rp_name or properties.rp_name == "" then
            properties.rp_name = GenerateUniquePetName()
        end
    else
        NextToyOrder = NextToyOrder - 1
        newnessValue = NextToyOrder
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind,
        newness_order = newnessValue,
        properties = properties,
        _source = "blueprint.lua"
    }

    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local inventory = ClientData.get("inventory")
    if inventory and inventory[category] then
        inventory[category][uniqueId] = itemData
    end
    set_thread_identity(identity)

    if category == "pets" then
        SpawnedPets[uniqueId] = { data = itemData, model = nil }
    end
    
    SpawnedItems[uniqueId] = true

    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)

    return itemData
end

local function DeleteAllSpawnedPets()
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    
    local inventory = ClientData.get("inventory")
    local removed = 0
    
    if inventory and inventory.pets then
        for uniqueId, _ in pairs(SpawnedItems) do
            if inventory.pets[uniqueId] and inventory.pets[uniqueId]._source == "blueprint.lua" then
                inventory.pets[uniqueId] = nil
                removed = removed + 1
            end
        end
    end
    
    set_thread_identity(identity)
    
    for uniqueId, _ in pairs(SpawnedPets) do
        if SpawnedPets[uniqueId] and SpawnedPets[uniqueId].data and SpawnedPets[uniqueId].data._source == "blueprint.lua" then
            if SpawnedPets[uniqueId].model then
                SpawnedPets[uniqueId].model:Destroy()
            end
        end
    end
    
    SpawnedPets = {}
    SpawnedItems = {}
    PetAilmentsCache = {}
    EquippedPet = nil
    CurrentRideId = nil
    
    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)
    
    return removed
end

local function FindPetId(petName)
    for id, info in pairs(InventoryDB.pets) do
        if info.name:lower() == petName:lower() then
            return id
        end
    end
    return nil
end

local function FindToyId(toyName)
    for id, info in pairs(InventoryDB.toys) do
        if info.name:lower() == toyName:lower() then
            return id
        end
    end
    return nil
end

local function FindItemId(itemName)
    local categories = {
        {name = "pets", finder = FindPetId},
        {name = "toys", finder = FindToyId}
    }
    
    for _, cat in ipairs(categories) do
        local id = cat.finder(itemName)
        if id then return id, cat.name end
    end
    return nil, nil
end

local OriginalRouterGet = RouterClient.get

function RouterClient.get(endpoint)
    if endpoint == "ToolAPI/Equip" then
        return {
            InvokeServer = function(_, uniqueId)
                local pet = SpawnedPets[uniqueId]
                if not pet then
                    return OriginalRouterGet("ToolAPI/Equip"):InvokeServer(uniqueId)
                end
                EquipPet(pet.data)
                return true, { action = "equip", is_server = true }
            end
        }
    elseif endpoint == "ToolAPI/Unequip" then
        return {
            InvokeServer = function(_, uniqueId)
                local pet = SpawnedPets[uniqueId]
                if not pet then
                    return OriginalRouterGet("ToolAPI/Unequip"):InvokeServer(uniqueId)
                end
                UnequipPet(pet.data)
                return true, { action = "unequip", is_server = true }
            end
        }
    elseif endpoint == "AdoptAPI/RidePet" then
        return {
            InvokeServer = function(_, petData)
                local pet = SpawnedPets[petData.pet_unique]
                if not pet then
                    return OriginalRouterGet("AdoptAPI/RidePet"):InvokeServer(petData)
                end
                RidePet(petData.pet_unique)
                return true
            end
        }
    elseif endpoint == "AdoptAPI/FlyPet" then
        return {
            InvokeServer = function(_, petData)
                local pet = SpawnedPets[petData.pet_unique]
                if not pet then
                    return OriginalRouterGet("AdoptAPI/FlyPet"):InvokeServer(petData)
                end
                FlyPet(petData.pet_unique)
                return true
            end
        }
    elseif endpoint == "AdoptAPI/ExitSeatStates" then
        return {
            FireServer = function()
                if CurrentRideId then
                    DismountPet()
                    return true
                end
                return OriginalRouterGet("AdoptAPI/ExitSeatStates"):FireServer()
            end
        }
    elseif endpoint == "SettingsAPI/SetPetRoleplayName" then
        return {
            InvokeServer = function(_, petUniqueId, newName)
                local pet = SpawnedPets[petUniqueId]
                if not pet then
                    return OriginalRouterGet("SettingsAPI/SetPetRoleplayName"):InvokeServer(petUniqueId, newName)
                end
                
                local identity = get_thread_identity and get_thread_identity() or 8
                set_thread_identity(2)
                
                local inventory = ClientData.get("inventory")
                if inventory and inventory.pets and inventory.pets[petUniqueId] then
                    inventory.pets[petUniqueId].properties.rp_name = newName
                end
                
                if pet.data then
                    pet.data.properties.rp_name = newName
                end
                
                local wrappers = ClientData.get("pet_char_wrappers")
                for _, wrapper in pairs(wrappers) do
                    if wrapper.pet_unique == petUniqueId then
                        wrapper.rp_name = newName
                        break
                    end
                end
                
                set_thread_identity(identity)
                return true
            end
        }
    else
        return OriginalRouterGet(endpoint)
    end
end

for _, wrapper in pairs(ClientData.get("pet_char_wrappers")) do
    OriginalRouterGet("ToolAPI/Unequip"):InvokeServer(wrapper.pet_unique)
end

-- Interfaccia Utente ZetaScripts (Stile Preppy)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZetaScriptsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true -- Ignora gli insetti della GUI per un look più pulito
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 340) -- Dimensioni leggermente più grandi
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -170) -- Centrato
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 240, 245) -- Colore di sfondo rosa pastello
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale", mainFrame)
uiScale.Scale = 0.75 -- Scala leggermente più grande per un look più spazioso

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16) -- Angoli più arrotondati
mainCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(255, 180, 200) -- Colore del bordo rosa acceso
uiStroke.Parent = mainFrame

local palette = {
    Color3.fromRGB(255, 180, 200), -- Rosa acceso
    Color3.fromRGB(170, 220, 255), -- Azzurro pastello
    Color3.fromRGB(200, 255, 170), -- Verde menta
    Color3.fromRGB(255, 230, 150)  -- Giallo chiaro
}
local colorIdx = 1
task.spawn(function()
    while true do
        colorIdx = colorIdx % #palette + 1
        TweenService:Create(uiStroke, TweenInfo.new(5), { Color = palette[colorIdx] }):Play()
        task.wait(5)
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "✨ ZetaScripts ✨" -- Testo del titolo con emoji
title.Font = Enum.Font.FredokaOne -- Font più giocoso
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(100, 80, 120) -- Viola scuro per il testo
title.Parent = mainFrame

-- Filigrana ZetaScripts
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 150, 0, 20)
watermark.Position = UDim2.new(1, -155, 1, -25) -- Posizionata in basso a destra
watermark.BackgroundTransparency = 1
watermark.Text = "ZetaScripts"
watermark.Font = Enum.Font.FredokaOne
watermark.TextSize = 10
watermark.TextColor3 = Color3.fromRGB(200, 200, 200) -- Grigio chiaro per la filigrana
watermark.TextTransparency = 0.6 -- Trasparenza per renderla meno invasiva
watermark.Parent = mainFrame
Instance.new("UICorner", watermark).CornerRadius = UDim.new(0, 5)

local tabContainer = Instance.new('Frame')
tabContainer.Size = UDim2.new(0.92, 0, 0, 26)
tabContainer.Position = UDim2.new(0.04, 0, 0, 35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {
    { key = 'Spawn', label = '🌸 Spawn Pet' }, -- Emoji per ogni tab
    { key = 'Tools', label = '🛠️ Tools' }
}

local activeTab = 'Spawn'
local tabElements = {}

local function SwitchTab(tabName)
    activeTab = tabName
    for name, data in pairs(tabElements) do
        local isActive = name == tabName
        data.button.BackgroundColor3 = isActive and Color3.fromRGB(250, 200, 220) or Color3.fromRGB(230, 230, 230) -- Colori pastello per i tab
        data.button.TextColor3 = isActive and Color3.fromRGB(100, 80, 120) or Color3.fromRGB(80, 80, 80)
        data.stroke.Color = isActive and Color3.fromRGB(255, 180, 200) or Color3.fromRGB(200, 200, 200)
        data.stroke.Thickness = isActive and 1.5 or 0.8
    end
end

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new('TextButton')
    tabButton.Size = UDim2.new(1 / #tabs - 0.02, 0, 1, 0)
    tabButton.Position = UDim2.new((i - 1) * (1 / #tabs), (i == 1) and 0 or 4, 0, 0)
    tabButton.BackgroundColor3 = i == 1 and Color3.fromRGB(250, 200, 220) or Color3.fromRGB(230, 230, 230)
    tabButton.BackgroundTransparency = 0
    tabButton.Text = tab.label
    tabButton.Font = Enum.Font.FredokaOne
    tabButton.TextSize = 10
    tabButton.TextColor3 = i == 1 and Color3.fromRGB(100, 80, 120) or Color3.fromRGB(80, 80, 80)
    tabButton.Parent = tabContainer
    
    Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 8)
    
    local tabStroke = Instance.new('UIStroke')
    tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tabStroke.Color = i == 1 and Color3.fromRGB(255, 180, 200) or Color3.fromRGB(200, 200, 200)
    tabStroke.Thickness = i == 1 and 1.5 or 0.8
    tabStroke.Transparency = 0.3
    tabStroke.Parent = tabButton
    
    tabElements[tab.key] = { button = tabButton, stroke = tabStroke }
    
    tabButton.MouseButton1Click:Connect(function()
        SwitchTab(tab.key)
    end)
end

local spawnPanel = Instance.new("Frame")
spawnPanel.Size = UDim2.new(0.94, 0, 1, -65) -- Leggermente più spazio per i contenuti
spawnPanel.Position = UDim2.new(0.03, 0, 0, 68)
spawnPanel.BackgroundTransparency = 1
spawnPanel.Visible = true
spawnPanel.Parent = mainFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 12)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🐾 Pet Name"
nameLabel.Font = Enum.Font.FredokaOne
nameLabel.TextSize = 10
nameLabel.TextColor3 = Color3.fromRGB(120, 100, 140) -- Viola più chiaro
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = spawnPanel

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, 0, 0, 25)
nameInput.Position = UDim2.new(0, 0, 0, 13)
nameInput.BackgroundColor3 = Color3.fromRGB(255, 245, 250) -- Rosa molto chiaro
nameInput.TextColor3 = Color3.fromRGB(80, 60, 100) -- Viola scuro per il testo
nameInput.TextSize = 12
nameInput.Font = Enum.Font.FredokaOne
nameInput.PlaceholderText = "Enter pet name..."
nameInput.PlaceholderColor3 = Color3.fromRGB(180, 160, 200) -- Viola più tenue per placeholder
nameInput.ClearTextOnFocus = false
nameInput.Text = "Bat Dragon"
nameInput.Parent = spawnPanel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 10)
inputCorner.Parent = nameInput

local glowColors = {
    neutral = Color3.fromRGB(230, 230, 230),
    valid = Color3.fromRGB(150, 255, 180), -- Verde acqua chiaro
    invalid = Color3.fromRGB(255, 150, 150) -- Rosa corallo chiaro
}

local inputGlow = Instance.new("UIStroke")
inputGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputGlow.Color = glowColors.neutral
inputGlow.Thickness = 2
inputGlow.Transparency = 0.4
inputGlow.Parent = nameInput

local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(1, 0, 0, 12)
ageLabel.Position = UDim2.new(0, 0, 0, 43)
ageLabel.BackgroundTransparency = 1
ageLabel.Text = "📅 Age Progression"
ageLabel.Font = Enum.Font.FredokaOne
ageLabel.TextSize = 10
ageLabel.TextColor3 = Color3.fromRGB(120, 100, 140)
ageLabel.TextXAlignment = Enum.TextXAlignment.Left
ageLabel.Parent = spawnPanel

local ageGrid = Instance.new("Frame")
ageGrid.Size = UDim2.new(1, 0, 0, 25)
ageGrid.Position = UDim2.new(0, 0, 0, 56)
ageGrid.BackgroundTransparency = 1
ageGrid.Parent = spawnPanel

local ageCodes = {"✨", "🌸", "🌟", "👑", "💖", "💎"} -- Emoji per le età
local ageDescriptions = {"Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown"}
local currentAge = 1

for i, code in ipairs(ageCodes) do
    local ageButton = Instance.new("TextButton")
    ageButton.Size = UDim2.new(1/6 - 0.01, 0, 1, 0)
    ageButton.Position = UDim2.new((i-1) * (1/6), (i > 1) and 2 or 0, 0, 0)
    ageButton.Text = code
    ageButton.BackgroundColor3 = i == 1 and Color3.fromRGB(220, 180, 230) or Color3.fromRGB(245, 245, 245) -- Colori pastello per i bottoni età
    ageButton.Font = Enum.Font.FredokaOne
    ageButton.TextColor3 = Color3.fromRGB(80, 60, 100)
    ageButton.TextSize = 13
    ageButton.Parent = ageGrid
    
    local ageCorner = Instance.new("UICorner")
    ageCorner.CornerRadius = UDim.new(0, 8)
    ageCorner.Parent = ageButton
    
    local hintBox = Instance.new("TextLabel")
    hintBox.Text = ageDescriptions[i]
    hintBox.BackgroundColor3 = Color3.fromRGB(255, 240, 245)
    hintBox.TextColor3 = Color3.fromRGB(100, 80, 120)
    hintBox.TextSize = 8
    hintBox.Font = Enum.Font.FredokaOne
    hintBox.Size = UDim2.new(0, 0, 0, 0)
    hintBox.Visible = false
    hintBox.Parent = ageButton
    Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 4)
    
    ageButton.MouseEnter:Connect(function()
        hintBox.Size = UDim2.new(0, 75, 0, 18)
        hintBox.Position = UDim2.new(0, 0, -1.3, 0)
        hintBox.Visible = true
    end)
    
    ageButton.MouseLeave:Connect(function()
        hintBox.Visible = false
    end)
    
    ageButton.MouseButton1Click:Connect(function()
        currentAge = i
        for _, btn in pairs(ageGrid:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            end
        end
        ageButton.BackgroundColor3 = Color3.fromRGB(220, 180, 230)
    end)
end

local flagLabel = Instance.new("TextLabel")
flagLabel.Size = UDim2.new(1, 0, 0, 12)
flagLabel.Position = UDim2.new(0, 0, 0, 86)
flagLabel.BackgroundTransparency = 1
flagLabel.Text = "✨ Pet Flags (Neon/Fly/Ride)"
flagLabel.Font = Enum.Font.FredokaOne
flagLabel.TextSize = 10
flagLabel.TextColor3 = Color3.fromRGB(120, 100, 140)
flagLabel.TextXAlignment = Enum.TextXAlignment.Left
flagLabel.Parent = spawnPanel

local flagGrid = Instance.new("Frame")
flagGrid.Size = UDim2.new(1, 0, 0, 30)
flagGrid.Position = UDim2.new(0, 0, 0, 99)
flagGrid.BackgroundTransparency = 1
flagGrid.Parent = spawnPanel

local flagColors = {
    M = Color3.fromRGB(190, 150, 220), -- Viola pastello
    N = Color3.fromRGB(150, 230, 200), -- Verde acqua
    F = Color3.fromRGB(170, 200, 255), -- Azzurro cielo
    R = Color3.fromRGB(255, 170, 190)  -- Rosa corallo
}

local flagOrder = {"M", "N", "F", "R"}
local flagState = {M = false, N = false, F = true, R = true} -- Default su Fly e Ride

for i, flag in ipairs(flagOrder) do
    local flagButton = Instance.new("TextButton")
    flagButton.Size = UDim2.new(0.23, -2, 0.8, 0)
    flagButton.Position = UDim2.new((i-1) * 0.25, (i > 1) and 3 or 0, 0.1, 0)
    flagButton.Text = flag
    flagButton.BackgroundColor3 = flagState[flag] and flagColors[flag] or Color3.fromRGB(245, 245, 245)
    flagButton.Font = Enum.Font.FredokaOne
    flagButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    flagButton.TextSize = 13
    flagButton.Parent = flagGrid
    
    local flagCorner = Instance.new("UICorner")
    flagCorner.CornerRadius = UDim.new(0, 8)
    flagCorner.Parent = flagButton
    
    local flagStroke = Instance.new("UIStroke")
    flagStroke.Color = flagColors[flag]
    flagStroke.Thickness = flagState[flag] and 2.5 or 1.5
    flagStroke.Transparency = flagState[flag] and 0.2 or 0.5
    flagStroke.Parent = flagButton
    
    flagButton.MouseButton1Click:Connect(function()
        if flag == "M" and flagState["N"] then return end -- Non si possono avere Mega Neon e Neon contemporaneamente
        if flag == "N" and flagState["M"] then return end
        
        flagState[flag] = not flagState[flag]
        
        if flagState[flag] then
            flagButton.BackgroundColor3 = flagColors[flag]
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 2.5,
                Transparency = 0.2
            }):Play()
        else
            flagButton.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 1.5,
                Transparency = 0.5
            }):Play()
        end
    end)
end

local quickLabel = Instance.new("TextLabel")
quickLabel.Size = UDim2.new(1, 0, 0, 12)
quickLabel.Position = UDim2.new(0, 0, 0, 135)
quickLabel.BackgroundTransparency = 1
quickLabel.Text = "⚡ Quick Select Pets"
quickLabel.Font = Enum.Font.FredokaOne
quickLabel.TextSize = 10
quickLabel.TextColor3 = Color3.fromRGB(120, 100, 140)
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.Parent = spawnPanel

local quickGrid = Instance.new("Frame")
quickGrid.Size = UDim2.new(1, 0, 0, 50)
quickGrid.Position = UDim2.new(0, 0, 0, 148)
quickGrid.BackgroundTransparency = 1
quickGrid.Parent = spawnPanel

local quickPets = {
    {"Shadow Dragon", Color3.fromRGB(120, 100, 140)}, -- Viola pastello
    {"Frost Dragon", Color3.fromRGB(170, 220, 255)}, -- Azzurro pastello
    {"Bat Dragon", Color3.fromRGB(255, 170, 190)}, -- Rosa corallo
    {"Giraffe", Color3.fromRGB(255, 230, 150)},  -- Giallo chiaro
    {"Owl", Color3.fromRGB(200, 150, 100)}, -- Marrone chiaro
    {"Parrot", Color3.fromRGB(255, 180, 150)}  -- Arancio pesca
}

for i, petData in ipairs(quickPets) do
    local row = math.floor((i-1) / 3)
    local col = (i-1) % 3
    
    local quickButton = Instance.new("TextButton")
    quickButton.Size = UDim2.new(0.31, -2, 0.45, 0)
    quickButton.Position = UDim2.new(col * 0.33, (col > 0) and 3 or 0, row * 0.5, (row > 0) and 3 or 0)
    
    if i <= 3 then
        quickButton.Text = petData[1]
    else
        quickButton.Text = petData[1]:match("^(%w+)") or petData[1]
    end
    
    quickButton.BackgroundColor3 = petData[2]
    quickButton.Font = Enum.Font.FredokaOne
    quickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickButton.TextSize = 8
    quickButton.Parent = quickGrid
    
    local quickCorner = Instance.new("UICorner")
    quickCorner.CornerRadius = UDim.new(0, 8)
    quickCorner.Parent = quickButton
    
    quickButton.MouseButton1Click:Connect(function()
        nameInput.Text = petData[1]
        local isValid = FindPetId(nameInput.Text) ~= nil
        inputGlow.Color = isValid and glowColors.valid or glowColors.invalid
    end)
end

local spawnAllButton = Instance.new("TextButton")
spawnAllButton.Size = UDim2.new(1, 0, 0, 28)
spawnAllButton.Position = UDim2.new(0, 0, 0, 205)
spawnAllButton.Text = "👑 SPAWN ALL HIGH TIERS"
spawnAllButton.Font = Enum.Font.FredokaOne
spawnAllButton.TextSize = 11
spawnAllButton.BackgroundColor3 = Color3.fromRGB(230, 180, 100) -- Arancio dorato
spawnAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnAllButton.Parent = spawnPanel

local allCorner = Instance.new("UICorner")
allCorner.CornerRadius = UDim.new(0, 10)
allCorner.Parent = spawnAllButton

local allStroke = Instance.new("UIStroke")
allStroke.Color = Color3.fromRGB(255, 220, 130)
allStroke.Thickness = 1.8
allStroke.Transparency = 0.3
allStroke.Parent = spawnAllButton

local spawnButton = Instance.new("TextButton")
spawnButton.Size = UDim2.new(1, 0, 0, 32)
spawnButton.Position = UDim2.new(0, 0, 1, -40)
spawnButton.Text = "✨ SPAWN MY PET"
spawnButton.Font = Enum.Font.FredokaOne
spawnButton.TextSize = 13
spawnButton.BackgroundColor3 = Color3.fromRGB(150, 200, 255) -- Azzurro cielo
spawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnButton.Parent = spawnPanel

local spawnCorner = Instance.new("UICorner")
spawnCorner.CornerRadius = UDim.new(0, 12)
spawnCorner.Parent = spawnButton

local toolsPanel = Instance.new("Frame")
toolsPanel.Size = UDim2.new(0.94, 0, 1, -65)
toolsPanel.Position = UDim2.new(0.03, 0, 0, 68)
toolsPanel.BackgroundTransparency = 1
toolsPanel.Visible = false
toolsPanel.Parent = mainFrame

local toolsTitle = Instance.new("TextLabel")
toolsTitle.Size = UDim2.new(1, 0, 0, 18)
toolsTitle.Position = UDim2.new(0, 0, 0, 0)
toolsTitle.BackgroundTransparency = 1
toolsTitle.Text = "🛠️ Tools & Settings"
toolsTitle.Font = Enum.Font.FredokaOne
toolsTitle.TextSize = 12
toolsTitle.TextColor3 = Color3.fromRGB(100, 80, 120)
toolsTitle.TextXAlignment = Enum.TextXAlignment.Left
toolsTitle.Parent = toolsPanel

local deleteButton = Instance.new("TextButton")
deleteButton.Size = UDim2.new(1, 0, 0, 28)
deleteButton.Position = UDim2.new(0, 0, 0, 25)
deleteButton.Text = "🗑️ Delete All Spawned Pets"
deleteButton.Font = Enum.Font.FredokaOne
deleteButton.TextSize = 11
deleteButton.BackgroundColor3 = Color3.fromRGB(255, 150, 150) -- Rosa corallo chiaro
deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteButton.Parent = toolsPanel
Instance.new("UICorner", deleteButton).CornerRadius = UDim.new(0, 10)

deleteButton.MouseButton1Click:Connect(function()
    local count = DeleteAllSpawnedPets()
    deleteButton.Text = "✓ Deleted " .. count .. " Pets!"
    task.wait(1.5)
    deleteButton.Text = "🗑️ Delete All Spawned Pets"
end)

local scaleLabel = Instance.new("TextLabel")
scaleLabel.Size = UDim2.new(1, 0, 0, 12)
scaleLabel.Position = UDim2.new(0, 0, 0, 60)
scaleLabel.BackgroundTransparency = 1
scaleLabel.Text = "📏 UI Scale (75% default)"
scaleLabel.Font = Enum.Font.FredokaOne
scaleLabel.TextSize = 10
scaleLabel.TextColor3 = Color3.fromRGB(120, 100, 140)
scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
scaleLabel.Parent = toolsPanel

local scaleControls = Instance.new("Frame")
scaleControls.Size = UDim2.new(1, 0, 0, 25)
scaleControls.Position = UDim2.new(0, 0, 0, 73)
scaleControls.BackgroundTransparency = 1
scaleControls.Parent = toolsPanel

local scaleDown = Instance.new("TextButton")
scaleDown.Size = UDim2.new(0.18, 0, 1, 0)
scaleDown.Position = UDim2.new(0, 0, 0, 0)
scaleDown.Text = "−"
scaleDown.Font = Enum.Font.FredokaOne
scaleDown.TextSize = 14
scaleDown.BackgroundColor3 = Color3.fromRGB(255, 150, 150) -- Rosa corallo
scaleDown.TextColor3 = Color3.fromRGB(255, 255, 255)
scaleDown.Parent = scaleControls
Instance.new("UICorner", scaleDown).CornerRadius = UDim.new(0, 8)

local scaleValue = Instance.new("TextLabel")
scaleValue.Size = UDim2.new(0.5, 0, 1, 0)
scaleValue.Position = UDim2.new(0.25, 0, 0, 0)
scaleValue.BackgroundColor3 = Color3.fromRGB(255, 245, 250)
scaleValue.TextColor3 = Color3.fromRGB(80, 60, 100)
scaleValue.Text = "75%"
scaleValue.Font = Enum.Font.FredokaOne
scaleValue.TextSize = 11
scaleValue.Parent = scaleControls
Instance.new("UICorner", scaleValue).CornerRadius = UDim.new(0, 8)

local scaleUp = Instance.new("TextButton")
scaleUp.Size = UDim2.new(0.18, 0, 1, 0)
scaleUp.Position = UDim2.new(0.82, 0, 0, 0)
scaleUp.Text = "+"
scaleUp.Font = Enum.Font.FredokaOne
scaleUp.TextSize = 14
scaleUp.BackgroundColor3 = Color3.fromRGB(150, 230, 200) -- Verde acqua
scaleUp.TextColor3 = Color3.fromRGB(255, 255, 255)
scaleUp.Parent = scaleControls
Instance.new("UICorner", scaleUp).CornerRadius = UDim.new(0, 8)

local resetScale = Instance.new("TextButton")
resetScale.Size = UDim2.new(1, 0, 0, 25)
resetScale.Position = UDim2.new(0, 0, 0, 100)
resetScale.Text = "↩️ Reset to 75%"
resetScale.Font = Enum.Font.FredokaOne
resetScale.TextSize = 9
resetScale.BackgroundColor3 = Color3.fromRGB(200, 180, 220) -- Viola chiaro
resetScale.TextColor3 = Color3.fromRGB(255, 255, 255)
resetScale.Parent = toolsPanel
Instance.new("UICorner", resetScale).CornerRadius = UDim.new(0, 8)

local lockButton = Instance.new("TextButton")
lockButton.Size = UDim2.new(1, 0, 0, 25)
lockButton.Position = UDim2.new(0, 0, 0, 130)
lockButton.Text = "🔓 UI Unlocked"
lockButton.Font = Enum.Font.FredokaOne
lockButton.TextSize = 9
lockButton.BackgroundColor3 = Color3.fromRGB(230, 230, 150) -- Giallo tenue
lockButton.TextColor3 = Color3.fromRGB(80, 60, 100)
lockButton.Parent = toolsPanel
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 8)

local currentScale = 0.75

scaleDown.MouseButton1Click:Connect(function()
    currentScale = math.max(0.5, currentScale - 0.1)
    uiScale.Scale = currentScale
    scaleValue.Text = math.floor(currentScale * 100) .. "%"
end)

scaleUp.MouseButton1Click:Connect(function()
    currentScale = math.min(2.0, currentScale + 0.1)
    uiScale.Scale = currentScale
    scaleValue.Text = math.floor(currentScale * 100) .. "%"
end)

resetScale.MouseButton1Click:Connect(function()
    currentScale = 0.75
    uiScale.Scale = currentScale
    scaleValue.Text = "75%"
end)

local uiLocked = false
lockButton.MouseButton1Click:Connect(function()
    uiLocked = not uiLocked
    if uiLocked then
        lockButton.Text = "🔒 UI Locked"
        lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Grigio per bloccato
        lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        lockButton.Text = "🔓 UI Unlocked"
        lockButton.BackgroundColor3 = Color3.fromRGB(230, 230, 150) -- Giallo tenue per sbloccato
        lockButton.TextColor3 = Color3.fromRGB(80, 60, 100)
    end
end)

local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if not uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if not uiLocked and dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

tabElements.Spawn.button.MouseButton1Click:Connect(function()
    SwitchTab('Spawn')
    spawnPanel.Visible = true
    toolsPanel.Visible = false
end)

tabElements.Tools.button.MouseButton1Click:Connect(function()
    SwitchTab('Tools')
    spawnPanel.Visible = false
    toolsPanel.Visible = true
end)

spawnButton.MouseButton1Click:Connect(function()
    local petName = nameInput.Text
    if petName == "" then return end
    
    local petId = FindPetId(petName)
    if not petId then 
        inputGlow.Color = glowColors.invalid
        return 
    end
    inputGlow.Color = glowColors.valid
    
    local ageMap = {1, 2, 3, 4, 5, 6}
    local options = {
        mega_neon = flagState["M"],
        neon = flagState["N"],
        flyable = flagState["F"],
        rideable = flagState["R"],
        age = ageMap[currentAge],
        trick_level = 5,
        ailments_completed = 0,
        rp_name = GenerateUniquePetName() -- Usa la funzione per nomi più carini
    }
    
    local item = CreateInventoryItem(petId, "pets", options)
    if item then
        spawnButton.Text = "✅ Spawned!"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(150, 255, 180)}):Play()
        task.wait(1)
        spawnButton.Text = "✨ SPAWN MY PET"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(150, 200, 255)}):Play()
    end
end)

spawnAllButton.MouseButton1Click:Connect(function()
    local ageMap = {1, 2, 3, 4, 5, 6}
    local options = {
        mega_neon = flagState["M"],
        neon = flagState["N"],
        flyable = flagState["F"],
        rideable = flagState["R"],
        age = ageMap[currentAge],
        trick_level = 5,
        ailments_completed = 0
    }
    
    local successCount = 0
    spawnAllButton.Text = "✨ Spawning..."
    TweenService:Create(spawnAllButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(200, 180, 100)}):Play()
    
    for _, petName in ipairs(HighTierPets) do
        local petId = FindPetId(petName)
        if petId then
            local petOptions = table.clone(options)
            petOptions.rp_name = GenerateUniquePetName()
            
            local item = CreateInventoryItem(petId, "pets", petOptions)
            if item then
                successCount = successCount + 1
            end
        end
    end
    
    spawnAllButton.Text = "✅ Spawned " .. successCount .. " Pets!"
    TweenService:Create(spawnAllButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(180, 230, 150)}):Play()
    task.wait(1.5)
    spawnAllButton.Text = "👑 SPAWN ALL HIGH TIERS"
    TweenService:Create(spawnAllButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(230, 180, 100)}):Play()
end)

nameInput:GetPropertyChangedSignal("Text"):Connect(function()
    local text = nameInput.Text
    if text == "" then
        inputGlow.Color = glowColors.neutral
        return
    end
    
    local isValid = FindPetId(text) ~= nil
    inputGlow.Color = isValid and glowColors.valid or glowColors.invalid
end)

print("ZetaScripts Loaded - Enjoy your preppy pets!")
