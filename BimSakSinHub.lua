--// ==========================================
--// BimSakSin Hub - Edisi Distrik Sempurna v2.0
--// Kompatibel Penuh dengan Delta Executor
--// ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Hapus GUI lama jika script dieksekusi ulang
local function GetGuiParent()
    if gethui then
        return gethui()
    else
        return CoreGui
    end
end

local GuiParent = GetGuiParent()
if GuiParent:FindFirstChild("BimSakSinHub") then
    GuiParent["BimSakSinHub"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
end
ScreenGui.Parent = GuiParent

-- Variabel Status Global
local ScriptActive = true
local ESPEnabled = false
local GenESPEnabled = false
local AutoGenEnabled = false
local GodModeEnabled = false
local NoclipEnabled = false
local SpeedEnabled = false
local JumpEnabled = false
local Flying = false
local FlySpeed = 50
local ActiveDanceTrack = nil
local Connections = {}

-- Fungsi Drag Halus (Mendukung Layar Sentuh HP & Mouse PC)
local function MakeDraggable(dragHandle, targetFrame, onClickCallback)
    local dragging = false
    local dragInput, dragStart, startPos
    local moved = false

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onClickCallback then
                        onClickCallback()
                    end
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                moved = true
            end
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--// ==========================================
--// PANEL UTAMA (GAYA MENU TRANSPARAN MODERN)
--// ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 420)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

--// ==========================================
--// HEADER ATAS (TOP BAR)
--// ==========================================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 12)
TopBarFix.Position = UDim2.new(0, 0, 1, -12)
TopBarFix.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TopBarFix.BackgroundTransparency = 0.2
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 280, 1, 0)
TitleLabel.Position = UDim2.new(0.5, -140, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamMedium
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 17
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 36, 0, 36)
MinBtn.Position = UDim2.new(1, -80, 0, 6)
MinBtn.BackgroundTransparency = 1
MinBtn.Font = Enum.Font.GothamMedium
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinBtn.TextSize = 22
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -40, 0, 6)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
CloseBtn.TextSize = 22
CloseBtn.Parent = TopBar

--// ==========================================
--// FLOATING TOGGLE (FONT TIPIS & HALUS)
--// ==========================================
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 175, 0, 42)
FloatingToggle.Position = UDim2.new(0, 25, 0, 25)
FloatingToggle.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
FloatingToggle.BackgroundTransparency = 0.3
FloatingToggle.AutoButtonColor = false
FloatingToggle.Visible = false
FloatingToggle.Font = Enum.Font.Gotham
FloatingToggle.Text = "BimSakSin Hub"
FloatingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingToggle.TextSize = 14
FloatingToggle.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 21)
FloatCorner.Parent = FloatingToggle

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(255, 255, 255)
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatingToggle

MakeDraggable(TopBar, MainFrame, nil)
MakeDraggable(FloatingToggle, FloatingToggle, function()
    MainFrame.Visible = true
    FloatingToggle.Visible = false
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingToggle.Visible = true
end)

--// ==========================================
--// NAVIGASI 5 TAB MENU (BAHASA INDONESIA)
--// ==========================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 56)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local UIListTab = Instance.new("UIListLayout")
UIListTab.FillDirection = Enum.FillDirection.Horizontal
UIListTab.SortOrder = Enum.SortOrder.LayoutOrder
UIListTab.Padding = UDim.new(0, 6)
UIListTab.Parent = TabBar

local TabList = {}
local function CreateTab(tabName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, -5, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamMedium
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(215, 215, 215)
    btn.TextSize = 12
    btn.Parent = TabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, -20, 1, -104)
    scrolling.Position = UDim2.new(0, 10, 0, 98)
    scrolling.BackgroundTransparency = 1
    scrolling.BorderSizePixel = 0
    scrolling.ScrollBarThickness = 4
    scrolling.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 70)
    scrolling.Visible = false
    scrolling.Parent = MainFrame

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = scrolling

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrolling.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 14)
    end)

    table.insert(TabList, {Button = btn, Frame = scrolling})
    return scrolling
end

local TabVisual    = CreateTab("Visual (ESP)")
local TabKarakter  = CreateTab("Karakter")
local TabDistrik   = CreateTab("Fitur Distrik")
local TabDance     = CreateTab("Dance")
local TabInformasi = CreateTab("Informasi")

for _, tabData in ipairs(TabList) do
    tabData.Button.MouseButton1Click:Connect(function()
        for _, t in ipairs(TabList) do
            t.Frame.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
            t.Button.TextColor3 = Color3.fromRGB(215, 215, 215)
        end
        tabData.Frame.Visible = true
        tabData.Button.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
        tabData.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

TabVisual.Visible = true
TabList[1].Button.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
TabList[1].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

--// ==========================================
--// ANIMASI RGB HALUS (MERAH & PUTIH)
--// ==========================================
task.spawn(function()
    local redColor = Color3.fromRGB(255, 45, 45)
    local whiteColor = Color3.fromRGB(255, 255, 255)
    while ScriptActive and ScreenGui and ScreenGui.Parent do
        local t1 = (math.sin(tick() * 3) + 1) / 2
        local textBlended = redColor:Lerp(whiteColor, t1)

        local t2 = (math.cos(tick() * 3) + 1) / 2
        local strokeBlended = whiteColor:Lerp(redColor, t2)

        pcall(function()
            TitleLabel.TextColor3 = textBlended
            FloatingToggle.TextColor3 = textBlended
            MainStroke.Color = strokeBlended
            FloatStroke.Color = strokeBlended
        end)

        RunService.RenderStepped:Wait()
    end
end)

--// ==========================================
--// KOMPONEN PEMBUAT TOMBOL MENU
--// ==========================================
local function CreateToggle(parentTab, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.Gotham
    btn.Text = "   " .. title
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parentTab

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 90)
    stroke.Thickness = 1
    stroke.Parent = btn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 85, 1, 0)
    status.Position = UDim2.new(1, -95, 0, 0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.Text = "[ MATI ]"
    status.TextColor3 = Color3.fromRGB(160, 160, 160)
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            status.Text = "[ AKTIF ]"
            status.TextColor3 = Color3.fromRGB(255, 75, 75)
            stroke.Color = Color3.fromRGB(255, 75, 75)
            btn.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
        else
            status.Text = "[ MATI ]"
            status.TextColor3 = Color3.fromRGB(160, 160, 160)
            stroke.Color = Color3.fromRGB(65, 65, 90)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        end
        pcall(function()
            callback(state)
        end)
    end)
end

local function CreateActionButton(parentTab, title, actionText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.Gotham
    btn.Text = "   " .. title
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parentTab

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 90)
    stroke.Thickness = 1
    stroke.Parent = btn

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 115, 1, 0)
    tag.Position = UDim2.new(1, -125, 0, 0)
    tag.BackgroundTransparency = 1
    tag.Font = Enum.Font.GothamMedium
    tag.Text = "[ " .. actionText .. " ]"
    tag.TextColor3 = Color3.fromRGB(255, 200, 90)
    tag.TextSize = 12
    tag.TextXAlignment = Enum.TextXAlignment.Right
    tag.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(55, 25, 30)
        task.delay(0.18, function()
            if btn and btn.Parent then
                btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
            end
        end)
        pcall(function()
            callback(tag)
        end)
    end)
end

--// ==========================================
--// FUNGSI DETEKSI KILLER / LAWAN AKURAT
--// ==========================================
local function IsPlayerKiller(player)
    if not player then return false end
    local isKiller = false
    pcall(function()
        if player.Team then
            local tName = string.lower(player.Team.Name)
            if tName:find("killer") or tName:find("hunter") or tName:find("monster") or tName:find("pembunuh") or tName:find("lawan") or tName:find("slasher") then
                isKiller = true
            end
        end
        if not isKiller then
            local roleVal = player:FindFirstChild("Role") or player:FindFirstChild("TeamRole") or (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Role"))
            if roleVal and tostring(roleVal.Value):lower():find("killer") then
                isKiller = true
            end
        end
        if not isKiller and player.Character then
            if player.Character:GetAttribute("Killer") == true or player.Character:GetAttribute("IsKiller") == true or player.Character:FindFirstChild("Killer") then
                isKiller = true
            end
            for _, item in ipairs(player.Character:GetChildren()) do
                if item:IsA("Tool") then
                    local iName = string.lower(item.Name)
                    if iName:find("knife") or iName:find("sword") or iName:find("axe") or iName:find("machete") or iName:find("weapon") or iName:find("pisau") or iName:find("golok") then
                        isKiller = true
                    end
                end
            end
        end
    end)
    return isKiller
end

--// ==========================================
--// TAB 1: VISUAL (ESP HIJAU PEMAIN, MERAH KILLER, GENERATOR)
--// ==========================================
local function ClearPlayerESP(player)
    if player and player.Character then
        if player.Character:FindFirstChild("BimSakSinESP") then
            player.Character.BimSakSinESP:Destroy()
        end
        if player.Character:FindFirstChild("BimSakSinESPInfo") then
            player.Character.BimSakSinESPInfo:Destroy()
        end
    end
end

local function ApplyPlayerESP(player)
    if player == LocalPlayer or not ESPEnabled then return end

    local function setupChar(char)
        if not ESPEnabled or not char then return end
        ClearPlayerESP(player)

        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root or not ESPEnabled then return end

        local isKiller = IsPlayerKiller(player)
        local greenColor = Color3.fromRGB(40, 255, 110)
        local redColor = Color3.fromRGB(255, 35, 35)

        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSinESP"
        hl.Adornee = char
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = isKiller and redColor or greenColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Parent = char

        local bill = Instance.new("BillboardGui")
        bill.Name = "BimSakSinESPInfo"
        bill.Adornee = root
        bill.Size = UDim2.new(0, 190, 0, 44)
        bill.StudsOffset = Vector3.new(0, 3.3, 0)
        bill.AlwaysOnTop = true
        bill.Parent = char

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextColor3 = isKiller and redColor or greenColor
        label.TextStrokeTransparency = 0.15
        label.Parent = bill

        task.spawn(function()
            while ESPEnabled and ScriptActive and char and char.Parent and bill and bill.Parent do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot and root then
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        local nowKiller = IsPlayerKiller(player)
                        if nowKiller then
                            hl.FillColor = redColor
                            label.TextColor3 = redColor
                            label.Text = "[KILLER] " .. player.Name .. "\nJarak: " .. dist .. "m"
                        else
                            hl.FillColor = greenColor
                            label.TextColor3 = greenColor
                            label.Text = "[PEMAIN] " .. player.Name .. "\nJarak: " .. dist .. "m"
                        end
                    end
                end)
                task.wait(0.25)
            end
        end)
    end

    if player.Character then
        task.spawn(function() setupChar(player.Character) end)
    end
end

table.insert(Connections, Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPEnabled then
            task.wait(0.8)
            ApplyPlayerESP(player)
        end
    end)
end))

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            if ESPEnabled then
                task.wait(0.8)
                ApplyPlayerESP(p)
            end
        end)
    end
end

CreateToggle(TabVisual, "ESP Pemain (Hijau) & Killer (Merah)", function(state)
    ESPEnabled = state
    if ESPEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            ApplyPlayerESP(p)
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            ClearPlayerESP(p)
        end
    end
end)

-- ESP Generator (Highlight Tembus Tembok + Jarak)
local function ClearAllGenESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "BimSakSinGenESP" or obj.Name == "BimSakSinGenHL" then
            obj:Destroy()
        end
    end
end

local function IsGeneratorObject(obj)
    local nameLower = string.lower(obj.Name)
    if nameLower:find("generator") or nameLower == "gen" or nameLower:find("gen_") or nameLower:find("mesin") then
        return true
    end
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local act = string.lower(desc.ActionText .. " " .. desc.ObjectText)
            if act:find("generator") or act:find("repair") or act:find("perbaiki") then
                return true
            end
        end
    end
    return false
end

CreateToggle(TabVisual, "ESP Generator (Tembus Tembok + Jarak)", function(state)
    GenESPEnabled = state
    if GenESPEnabled then
        task.spawn(function()
            while GenESPEnabled and ScriptActive do
                pcall(function()
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if (obj:IsA("Model") or obj:IsA("BasePart")) and IsGeneratorObject(obj) then
                            -- Hindari duplikasi jika bagian dari model yang sudah diberi ESP
                            local targetModel = obj:IsA("Model") and obj or (obj.Parent:IsA("Model") and obj.Parent or obj)
                            local targetPart = targetModel:IsA("BasePart") and targetModel or (targetModel:FindFirstChild("PrimaryPart") or targetModel:FindFirstChildWhichIsA("BasePart"))

                            if targetPart and not targetModel:FindFirstChild("BimSakSinGenHL") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "BimSakSinGenHL"
                                hl.Adornee = targetModel
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.FillColor = Color3.fromRGB(255, 215, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.45
                                hl.OutlineTransparency = 0
                                hl.Parent = targetModel

                                local bill = Instance.new("BillboardGui")
                                bill.Name = "BimSakSinGenESP"
                                bill.Adornee = targetPart
                                bill.Size = UDim2.new(0, 150, 0, 40)
                                bill.StudsOffset = Vector3.new(0, 3, 0)
                                bill.AlwaysOnTop = true
                                bill.Parent = targetModel

                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.Font = Enum.Font.GothamMedium
                                txt.TextColor3 = Color3.fromRGB(255, 230, 50)
                                txt.TextSize = 12
                                txt.TextStrokeTransparency = 0.15
                                txt.Parent = bill

                                task.spawn(function()
                                    while GenESPEnabled and ScriptActive and targetModel and targetModel.Parent and bill and bill.Parent do
                                        pcall(function()
                                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            if myRoot and targetPart then
                                                local d = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                                txt.Text = "[GENERATOR]\nJarak: " .. d .. "m"
                                            end
                                        end)
                                        task.wait(0.4)
                                    end
                                end)
                            end
                        end
                    end
                end)
                task.wait(2.5)
            end
            ClearAllGenESP()
        end)
    else
        ClearAllGenESP()
    end
end)

-- Penerangan Penuh
local OrigBrightness = Lighting.Brightness
local OrigClockTime = Lighting.ClockTime
local OrigGlobalShadows = Lighting.GlobalShadows
local OrigOutdoorAmbient = Lighting.OutdoorAmbient

CreateToggle(TabVisual, "Penerangan Penuh (Anti Gelap Map)", function(state)
    if state then
        Lighting.Brightness = 2.2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(225, 225, 225)
    else
        Lighting.Brightness = OrigBrightness
        Lighting.ClockTime = OrigClockTime
        Lighting.GlobalShadows = OrigGlobalShadows
        Lighting.OutdoorAmbient = OrigOutdoorAmbient
    end
end)

--// ==========================================
--// TAB 2: KARAKTER (KEBAL TRANSPARAN, FLY HALUS, DLL)
--// ==========================================

-- Kebal Pukulan & Transparan Terhadap Serangan Killer/Pemain
local GodModeConn = nil
local function RestoreCharacterHitbox()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanTouch = true
                    part.CanQuery = true
                    if part.Name ~= "HumanoidRootPart" then
                        part.LocalTransparencyModifier = 0
                    end
                end
            end
        end
    end)
end

CreateToggle(TabKarakter, "Kebal Pukulan & Transparan Serangan", function(state)
    GodModeEnabled = state
    if GodModeEnabled then
        GodModeConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        hum.Health = hum.MaxHealth
                    end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            -- Matikan hitbox sentuhan & raycast senjata killer
                            part.CanTouch = false
                            part.CanQuery = false
                            if part.Name ~= "HumanoidRootPart" then
                                part.LocalTransparencyModifier = 0.55
                            end
                        end
                    end
                end
            end)
        end)
    else
        if GodModeConn then
            GodModeConn:Disconnect()
            GodModeConn = nil
        end
        RestoreCharacterHitbox()
    end
end)

-- Terbang Halus Anti-Balik (Smooth Anti-Rollback Fly)
local FlyConn = nil
local function StopFly()
    Flying = false
    if FlyConn then
        FlyConn:Disconnect()
        FlyConn = nil
    end
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

CreateToggle(TabKarakter, "Terbang Halus (Anti-Balik / Smooth Fly)", function(state)
    if state then
        Flying = true
        FlyConn = RunService.Heartbeat:Connect(function(dt)
            if not Flying or not ScriptActive then return end
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    -- Nol-kan kecepatan jatuh agar server tidak mendeteksi fall/fly glitch
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                    local cam = Camera.CFrame
                    local moveDir = Vector3.new(0, 0, 0)

                    -- Analog HP (Touch Thumbstick)
                    if hum.MoveDirection.Magnitude > 0 then
                        local flatLook = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
                        local flatRight = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
                        if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end

                        local fwd = hum.MoveDirection:Dot(flatLook)
                        local rgt = hum.MoveDirection:Dot(flatRight)
                        moveDir = (cam.LookVector * fwd) + (cam.RightVector * rgt)
                    end

                    -- Keyboard PC (WASD + Space/LeftControl)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit
                    end

                    local targetPos = root.Position + (moveDir * FlySpeed * dt)
                    local lookTarget = targetPos + Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
                    root.CFrame = CFrame.lookAt(targetPos, lookTarget)
                end
            end)
        end)
    else
        StopFly()
    end
end)

-- Pengatur Kecepatan Terbang (- / +)
local FlySpeedFrame = Instance.new("Frame")
FlySpeedFrame.Size = UDim2.new(1, -4, 0, 40)
FlySpeedFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
FlySpeedFrame.BackgroundTransparency = 0.25
FlySpeedFrame.Parent = TabKarakter

Instance.new("UICorner", FlySpeedFrame).CornerRadius = UDim.new(0, 8)
local fsStroke = Instance.new("UIStroke", FlySpeedFrame)
fsStroke.Color = Color3.fromRGB(65, 65, 90)
fsStroke.Thickness = 1

local fsLabel = Instance.new("TextLabel")
fsLabel.Size = UDim2.new(0.65, 0, 1, 0)
fsLabel.Position = UDim2.new(0, 12, 0, 0)
fsLabel.BackgroundTransparency = 1
fsLabel.Font = Enum.Font.Gotham
fsLabel.Text = "Kecepatan Terbang: " .. FlySpeed
fsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
fsLabel.TextSize = 13
fsLabel.TextXAlignment = Enum.TextXAlignment.Left
fsLabel.Parent = FlySpeedFrame

local MinusFlyBtn = Instance.new("TextButton")
MinusFlyBtn.Size = UDim2.new(0, 32, 0, 28)
MinusFlyBtn.Position = UDim2.new(1, -78, 0.5, -14)
MinusFlyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
MinusFlyBtn.Font = Enum.Font.GothamMedium
MinusFlyBtn.Text = "-"
MinusFlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusFlyBtn.TextSize = 16
MinusFlyBtn.Parent = FlySpeedFrame
Instance.new("UICorner", MinusFlyBtn).CornerRadius = UDim.new(0, 6)

local PlusFlyBtn = Instance.new("TextButton")
PlusFlyBtn.Size = UDim2.new(0, 32, 0, 28)
PlusFlyBtn.Position = UDim2.new(1, -40, 0.5, -14)
PlusFlyBtn.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
PlusFlyBtn.Font = Enum.Font.GothamMedium
PlusFlyBtn.Text = "+"
PlusFlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusFlyBtn.TextSize = 16
PlusFlyBtn.Parent = FlySpeedFrame
Instance.new("UICorner", PlusFlyBtn).CornerRadius = UDim.new(0, 6)

MinusFlyBtn.MouseButton1Click:Connect(function()
    FlySpeed = math.max(15, FlySpeed - 10)
    fsLabel.Text = "Kecepatan Terbang: " .. FlySpeed
end)

PlusFlyBtn.MouseButton1Click:Connect(function()
    FlySpeed = math.min(200, FlySpeed + 10)
    fsLabel.Text = "Kecepatan Terbang: " .. FlySpeed
end)

-- Speed & Jump
CreateToggle(TabKarakter, "Lari Cepat (Kecepatan 45)", function(state)
    SpeedEnabled = state
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state and 45 or 16 end
    end)
end)

CreateToggle(TabKarakter, "Lompat Tinggi (Kekuatan 95)", function(state)
    JumpEnabled = state
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = state and 95 or 50
        end
    end)
end)

-- Tembus Tembok (Noclip)
local NoclipConn = nil
CreateToggle(TabKarakter, "Tembus Tembok (Noclip)", function(state)
    NoclipEnabled = state
    if NoclipEnabled then
        NoclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end)
    else
        if NoclipConn then
            NoclipConn:Disconnect()
            NoclipConn = nil
        end
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CanCollide = true
            end
        end)
    end
end)

--// ==========================================
--// TAB 3: FITUR DISTRIK (ANTI-HOOK MANUAL, TELEPORT MENETAP, GENERATOR)
--// ==========================================

-- Fungsi Lepas Gantungan Manual (Memutus Weld Hook + Unanchor + Escape)
local function ManualEscapeHook()
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        -- 1. Lepas semua part yang dikunci (Anchored)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanTouch = false
            end
        end

        -- 2. Putus Weld/Constraint dari gantungan hook luar tanpa merusak sendi tubuh
        local validJoints = {
            RootJoint = true, Neck = true,
            ["Left Shoulder"] = true, ["Right Shoulder"] = true,
            ["Left Hip"] = true, ["Right Hip"] = true,
            Waist = true, LeftShoulder = true, RightShoulder = true,
            LeftElbow = true, RightElbow = true, LeftWrist = true, RightWrist = true,
            LeftHip = true, RightHip = true, LeftKnee = true, RightKnee = true,
            LeftAnkle = true, RightAnkle = true
        }

        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("Motor6D") or desc:IsA("BallSocketConstraint") or desc:IsA("AlignPosition") then
                if not validJoints[desc.Name] then
                    desc:Destroy()
                end
            end
        end

        -- 3. Picu ProximityPrompt di sekitar hook jika tersedia
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local pPart = obj.Parent and (obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart"))
                if pPart and (root.Position - pPart.Position).Magnitude <= 15 then
                    if fireproximityprompt then
                        fireproximityprompt(obj)
                    end
                end
            end
        end

        -- 4. Pulihkan status berdiri & geser keluar dari hitbox hook
        hum.PlatformStand = false
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.CFrame = root.CFrame * CFrame.new(0, 3, -5)

        task.delay(1.5, function()
            if not GodModeEnabled then
                RestoreCharacterHitbox()
            end
        end)
    end)
end

CreateActionButton(TabDistrik, "Lepas dari Hook / Gantungan (Manual)", "LEPAS SEKARANG", function(tag)
    ManualEscapeHook()
    tag.Text = "[ TERLEPAS! ]"
    task.delay(1.5, function()
        if tag and tag.Parent then tag.Text = "[ LEPAS SEKARANG ]" end
    end)
end)

-- Fungsi Teleport Anti-Balik (Menetap Permanen di Tujuan)
local function SafeTeleportTo(targetRoot)
    pcall(function()
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not targetRoot or not hum then return end

        hum.Sit = false
        hum.PlatformStand = false

        -- Matikan tabrakan sesaat agar tidak tersangkut dinding
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        local destCFrame = targetRoot.CFrame * CFrame.new(0, 2.5, 3.5)
        local dist = (myRoot.Position - destCFrame.Position).Magnitude
        local duration = math.clamp(dist / 350, 0.15, 0.65)

        local tween = TweenService:Create(
            myRoot,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {CFrame = destCFrame}
        )
        tween:Play()
        tween.Completed:Wait()

        -- Kunci posisi sebentar & nol-kan kecepatan agar tidak ditarik balik oleh server
        for i = 1, 10 do
            if myRoot and targetRoot then
                myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.5, 3.5)
            end
            RunService.Heartbeat:Wait()
        end

        if not NoclipEnabled then
            myRoot.CanCollide = true
        end
    end)
end

CreateActionButton(TabDistrik, "Teleport ke Pemain Terdekat", "PINDAH", function(tag)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local bestRoot = nil
    local minDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsPlayerKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < minDist then
                minDist = d
                bestRoot = p.Character.HumanoidRootPart
            end
        end
    end

    if bestRoot then
        tag.Text = "[ PROSES... ]"
        task.spawn(function()
            SafeTeleportTo(bestRoot)
            if tag and tag.Parent then tag.Text = "[ PINDAH ]" end
        end)
    end
end)

CreateActionButton(TabDistrik, "Teleport ke Killer (Lawan)", "PINDAH", function(tag)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsPlayerKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            tag.Text = "[ PROSES... ]"
            task.spawn(function()
                SafeTeleportTo(p.Character.HumanoidRootPart)
                if tag and tag.Parent then tag.Text = "[ PINDAH ]" end
            end)
            break
        end
    end
end)

-- Auto Perbaikan Generator
CreateToggle(TabDistrik, "Perbaikan Generator Otomatis", function(state)
    AutoGenEnabled = state
    if AutoGenEnabled then
        task.spawn(function()
            while AutoGenEnabled and ScriptActive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local pName = obj.Parent and string.lower(obj.Parent.Name) or ""
                                local mName = (obj.Parent and obj.Parent.Parent) and string.lower(obj.Parent.Parent.Name) or ""
                                if pName:find("gen") or mName:find("gen") or pName:find("repair") then
                                    local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
                                    if part and (myRoot.Position - part.Position).Magnitude <= (obj.MaxActivationDistance + 8) then
                                        if fireproximityprompt then
                                            fireproximityprompt(obj)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.35)
            end
        end)
    end
end)

-- Anti-Lag & Transparansi Panel
CreateToggle(TabDistrik, "Mode Panel Lebih Transparan", function(state)
    MainFrame.BackgroundTransparency = state and 0.62 or 0.25
    TopBar.BackgroundTransparency = state and 0.58 or 0.2
    TopBarFix.BackgroundTransparency = state and 0.58 or 0.2
end)

CreateActionButton(TabDistrik, "Optimasi Anti-Lag & FPS Boost", "BERSIHKAN", function(tag)
    Lighting.GlobalShadows = false
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then v.Enabled = false end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
        end
    end
    tag.Text = "[ SELESAI! ]"
    task.delay(1.5, function()
        if tag and tag.Parent then tag.Text = "[ BERSIHKAN ]" end
    end)
end)

--// ==========================================
--// TAB 4: DANCE LENGKAP (TERLIHAT SEMUA PEMAIN / FE)
--// ==========================================
local DanceList = {
    {Name = "Dance 1 (Groove Klasik)", Chat = "/e dance",  R15 = "rbxassetid://507771019", R6 = "rbxassetid://182435998"},
    {Name = "Dance 2 (Robot / Pop)",   Chat = "/e dance2", R15 = "rbxassetid://507776043", R6 = "rbxassetid://182436842"},
    {Name = "Dance 3 (Spin / Wave)",   Chat = "/e dance3", R15 = "rbxassetid://507777268", R6 = "rbxassetid://182436935"},
    {Name = "Sorak Gembira (Cheer)",   Chat = "/e cheer",  R15 = "rbxassetid://507770677", R6 = "rbxassetid://129423030"},
    {Name = "Tertawa Lepas (Laugh)",   Chat = "/e laugh",  R15 = "rbxassetid://507770818", R6 = "rbxassetid://129423131"},
    {Name = "Melambai (Wave)",         Chat = "/e wave",   R15 = "rbxassetid://507770239", R6 = "rbxassetid://128777973"},
    {Name = "Menunjuk (Point)",        Chat = "/e point",  R15 = "rbxassetid://507770453", R6 = "rbxassetid://128853357"},
}

local function StopDance()
    if ActiveDanceTrack then
        pcall(function()
            ActiveDanceTrack:Stop()
            ActiveDanceTrack:Destroy()
        end)
        ActiveDanceTrack = nil
    end
end

local function PlayFeDance(danceData)
    StopDance()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
        local anim = Instance.new("Animation")
        anim.AnimationId = (hum.RigType == Enum.HumanoidRigType.R6) and danceData.R6 or danceData.R15

        ActiveDanceTrack = animator:LoadAnimation(anim)
        ActiveDanceTrack.Priority = Enum.AnimationPriority.Action
        ActiveDanceTrack.Looped = true
        ActiveDanceTrack:Play()

        -- Kirim emote chat standar Roblox agar 100% tereplikasi ke server & semua pemain
        Players:Chat(danceData.Chat)
    end)
end

CreateActionButton(TabDance, "Hentikan Semua Gerakan Dance", "STOP", function(tag)
    StopDance()
    tag.Text = "[ BERHENTI ]"
    task.delay(1.2, function()
        if tag and tag.Parent then tag.Text = "[ STOP ]" end
    end)
end)

for _, dance in ipairs(DanceList) do
    CreateActionButton(TabDance, dance.Name, "MULAI", function(tag)
        PlayFeDance(dance)
        tag.Text = "[ JOGET! ]"
        task.delay(1.5, function()
            if tag and tag.Parent then tag.Text = "[ MULAI ]" end
        end)
    end)
end

--// ==========================================
--// TAB 5: INFORMASI & KONTAK DEVELOPER
--// ==========================================
local function CreateInfoCard(titleText, bodyText, linkUrl, buttonLabel)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, linkUrl and 92 or 70)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    card.BackgroundTransparency = 0.2
    card.Parent = TabInformasi

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(75, 75, 105)
    stroke.Thickness = 1

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 22)
    header.Position = UDim2.new(0, 12, 0, 8)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamMedium
    header.Text = titleText
    header.TextColor3 = Color3.fromRGB(255, 85, 85)
    header.TextSize = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -24, 0, 34)
    desc.Position = UDim2.new(0, 12, 0, 28)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.Text = bodyText
    desc.TextColor3 = Color3.fromRGB(225, 225, 225)
    desc.TextSize = 12
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Parent = card

    if linkUrl then
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 175, 0, 24)
        copyBtn.Position = UDim2.new(0, 12, 1, -30)
        copyBtn.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
        copyBtn.Font = Enum.Font.GothamMedium
        copyBtn.Text = buttonLabel
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.TextSize = 11
        copyBtn.Parent = card
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(linkUrl)
            end
            copyBtn.Text = "Link Berhasil Disalin!"
            task.delay(2, function()
                if copyBtn and copyBtn.Parent then
                    copyBtn.Text = buttonLabel
                end
            end)
        end)
    end
end

CreateInfoCard(
    "Laporan Bug & Bantuan Admin",
    "Jika ada eror atau bug pada fitur - fitur hubungin dev/admin melaluin discord.",
    nil,
    nil
)

CreateInfoCard(
    "Update Script Terbaru (Discord)",
    "Join Discord jika ada updatean untuk fitur script terbaru: https://discord.gg/uSuzTJSuV",
    "https://discord.gg/uSuzTJSuV",
    "Salin Link Discord"
)

CreateInfoCard(
    "Dukungan Developer",
    "Link dukungan dev: https://linktr.ee/bimsaksin",
    "https://linktr.ee/bimsaksin",
    "Salin Link Dukungan"
)

--// ==========================================
--// PEMBERSIHAN TOTAL SAAT TOMBOL TUTUP (×) DITEKAN
--// ==========================================
CloseBtn.MouseButton1Click:Connect(function()
    ScriptActive = false
    ESPEnabled = false
    GenESPEnabled = false
    AutoGenEnabled = false
    GodModeEnabled = false
    NoclipEnabled = false

    StopFly()
    StopDance()
    RestoreCharacterHitbox()

    if NoclipConn then NoclipConn:Disconnect() end
    if GodModeConn then GodModeConn:Disconnect() end

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        ClearPlayerESP(p)
    end
    ClearAllGenESP()

    ScreenGui:Destroy()
end)

print("BimSakSin Hub v2.0 (Bebas Bug & Lengkap) Berhasil Dimuat!")
