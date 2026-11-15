--// ==========================================
--// BimSakSin Hub - Edisi Distrik Sempurna
--// Kompatibel penuh dengan Delta Executor
--// ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Hapus GUI lama jika script dijalankan ulang
local function GetGuiParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui then
        return CoreGui
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

-- Status Global Fitur (Untuk pembersihan rapi saat ditutup)
local ScriptActive = true
local ESPEnabled = false
local GenESPEnabled = false
local AutoGenEnabled = false
local AntiHookEnabled = false
local Flying = false
local FlySpeed = 50
local Connections = {}

-- Fungsi Helper Drag Halus (Mendukung Touch HP & Mouse PC)
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
MainFrame.Size = UDim2.new(0, 540, 0, 410)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -205)
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

-- Judul Panel Utama di Tengah Atas
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

-- Tombol Perkecil (-) & Tutup (x) ala Browser
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
FloatingToggle.Font = Enum.Font.Gotham -- Font tipis tidak tebal
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

-- Aktifkan Drag untuk Panel Utama & Floating Toggle
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
--// NAVIGASI TAB MENU (BAHASA INDONESIA)
--// ==========================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 56)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local UIListTab = Instance.new("UIListLayout")
UIListTab.FillDirection = Enum.FillDirection.Horizontal
UIListTab.SortOrder = Enum.SortOrder.LayoutOrder
UIListTab.Padding = UDim.new(0, 8)
UIListTab.Parent = TabBar

local TabList = {}
local function CreateTab(tabName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -6, 1, 0)
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

    -- Otomatis menyesuaikan tinggi scroll sesuai jumlah fitur
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrolling.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
    end)

    table.insert(TabList, {Button = btn, Frame = scrolling})
    return scrolling
end

local TabVisual    = CreateTab("Visual (ESP)")
local TabKarakter  = CreateTab("Karakter")
local TabDistrik   = CreateTab("Fitur Distrik")
local TabPengaturan = CreateTab("Pengaturan")

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
--// KOMPONEN TOMBOL FITUR (TOGGLE, AKSI, PENGATUR)
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
    tag.Size = UDim2.new(0, 95, 1, 0)
    tag.Position = UDim2.new(1, -105, 0, 0)
    tag.BackgroundTransparency = 1
    tag.Font = Enum.Font.GothamMedium
    tag.Text = "[ " .. actionText .. " ]"
    tag.TextColor3 = Color3.fromRGB(255, 200, 90)
    tag.TextSize = 12
    tag.TextXAlignment = Enum.TextXAlignment.Right
    tag.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(50, 25, 30)
        task.delay(0.15, function()
            if btn and btn.Parent then
                btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
            end
        end)
        pcall(callback)
    end)
end

--// ==========================================
--// FUNGSI DETEKSI KILLER / LAWAN
--// ==========================================
local function IsPlayerKiller(player)
    if not player then return false end
    local isKiller = false
    pcall(function()
        if player.Team then
            local tName = string.lower(player.Team.Name)
            if tName:find("killer") or tName:find("hunter") or tName:find("monster") or tName:find("pembunuh") or tName:find("lawan") then
                isKiller = true
            end
        end
        if not isKiller and player.Character then
            if player.Character:GetAttribute("Killer") == true or player.Character:FindFirstChild("Killer") then
                isKiller = true
            end
            for _, item in ipairs(player.Character:GetChildren()) do
                if item:IsA("Tool") then
                    local iName = string.lower(item.Name)
                    if iName:find("knife") or iName:find("sword") or iName:find("axe") or iName:find("weapon") or iName:find("pisau") or iName:find("senjata") then
                        isKiller = true
                    end
                end
            end
        end
    end)
    return isKiller
end

--// ==========================================
--// TAB 1: VISUAL (ESP)
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

        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSinESP"
        hl.Adornee = char
        hl.FillColor = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(168, 85, 247)
        hl.OutlineColor = isKiller and Color3.fromRGB(255, 200, 200) or Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.45
        hl.OutlineTransparency = 0
        hl.Parent = char

        local bill = Instance.new("BillboardGui")
        bill.Name = "BimSakSinESPInfo"
        bill.Adornee = root
        bill.Size = UDim2.new(0, 180, 0, 44)
        bill.StudsOffset = Vector3.new(0, 3.2, 0)
        bill.AlwaysOnTop = true
        bill.Parent = char

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextColor3 = isKiller and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.2
        label.Parent = bill

        task.spawn(function()
            while ESPEnabled and ScriptActive and char and char.Parent and bill and bill.Parent do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot and root then
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        local nowKiller = IsPlayerKiller(player)
                        if nowKiller then
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            label.TextColor3 = Color3.fromRGB(255, 40, 40)
                            label.Text = "[KILLER / LAWAN] " .. player.Name .. "\nJarak: " .. dist .. "m"
                        else
                            hl.FillColor = Color3.fromRGB(168, 85, 247)
                            label.TextColor3 = Color3.fromRGB(255, 255, 255)
                            label.Text = "[PEMAIN] " .. player.Name .. "\nJarak: " .. dist .. "m"
                        end
                    end
                end)
                task.wait(0.3)
            end
        end)
    end

    if player.Character then
        task.spawn(function() setupChar(player.Character) end)
    end
end

-- Pantau pemain yang baru masuk server agar otomatis kena ESP
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

CreateToggle(TabVisual, "ESP Pemain & Killer (Nama + Jarak)", function(state)
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

-- ESP Generator & Jarak
local function ClearAllGenESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "BimSakSinGenESP" or obj.Name == "BimSakSinGenHL" then
            obj:Destroy()
        end
    end
end

CreateToggle(TabVisual, "ESP Generator & Jarak", function(state)
    GenESPEnabled = state
    if GenESPEnabled then
        task.spawn(function()
            while GenESPEnabled and ScriptActive do
                pcall(function()
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        local lowerName = string.lower(obj.Name)
                        if (lowerName:find("generator") or lowerName == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                            local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                            if targetPart and not targetPart:FindFirstChild("BimSakSinGenESP") then
                                local bill = Instance.new("BillboardGui")
                                bill.Name = "BimSakSinGenESP"
                                bill.Adornee = targetPart
                                bill.Size = UDim2.new(0, 140, 0, 38)
                                bill.StudsOffset = Vector3.new(0, 2.5, 0)
                                bill.AlwaysOnTop = true
                                bill.Parent = targetPart

                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.Font = Enum.Font.GothamMedium
                                txt.TextColor3 = Color3.fromRGB(255, 225, 50)
                                txt.TextSize = 12
                                txt.TextStrokeTransparency = 0.2
                                txt.Parent = bill

                                task.spawn(function()
                                    while GenESPEnabled and ScriptActive and targetPart and targetPart.Parent and bill and bill.Parent do
                                        pcall(function()
                                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            if myRoot then
                                                local d = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                                txt.Text = "Generator\nJarak: " .. d .. "m"
                                            end
                                        end)
                                        task.wait(0.5)
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

-- Penerangan Penuh (Fullbright)
local OrigBrightness = Lighting.Brightness
local OrigClockTime = Lighting.ClockTime
local OrigGlobalShadows = Lighting.GlobalShadows
local OrigOutdoorAmbient = Lighting.OutdoorAmbient

CreateToggle(TabVisual, "Penerangan Penuh (Anti Gelap)", function(state)
    if state then
        Lighting.Brightness = 2
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
--// TAB 2: KARAKTER
--// ==========================================
local SpeedEnabled = false
CreateToggle(TabKarakter, "Lari Cepat (Kecepatan 50)", function(state)
    SpeedEnabled = state
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = state and 50 or 16
        end
    end)
end)

local JumpEnabled = false
CreateToggle(TabKarakter, "Lompat Tinggi (Kekuatan 100)", function(state)
    JumpEnabled = state
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = state and 100 or 50
        end
    end)
end)

-- Pertahankan Speed & Jump saat karakter respawn
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.2)
        if SpeedEnabled then hum.WalkSpeed = 50 end
        if JumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = 100
        end
    end
end))

-- Lompat Tanpa Batas
local InfJumpConn = nil
CreateToggle(TabKarakter, "Lompat Tanpa Batas (Di Udara)", function(state)
    if state then
        InfJumpConn = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end)
    else
        if InfJumpConn then
            InfJumpConn:Disconnect()
            InfJumpConn = nil
        end
    end
end)

-- Terbang Halus (Mendukung Analog HP & Keyboard WASD)
local BodyGyro, BodyVelocity
local function StopFly()
    Flying = false
    pcall(function()
        if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
        if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
end

CreateToggle(TabKarakter, "Terbang Halus (Mode Terbang)", function(state)
    if state then
        Flying = true
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum then
                hum.PlatformStand = true

                BodyGyro = Instance.new("BodyGyro")
                BodyGyro.P = 9e4
                BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                BodyGyro.CFrame = root.CFrame
                BodyGyro.Parent = root

                BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.Velocity = Vector3.new(0, 0, 0)
                BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                BodyVelocity.Parent = root

                task.spawn(function()
                    while Flying and ScriptActive and root and root.Parent and hum and hum.Health > 0 do
                        local cam = Camera.CFrame
                        local moveDir = Vector3.new(0, 0, 0)

                        -- Kontrol Analog HP (MoveDirection)
                        if hum.MoveDirection.Magnitude > 0 then
                            local flatLook = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z).Unit
                            local flatRight = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z).Unit
                            local forwardAmount = hum.MoveDirection:Dot(flatLook)
                            local rightAmount = hum.MoveDirection:Dot(flatRight)
                            moveDir = (cam.LookVector * forwardAmount) + (cam.RightVector * rightAmount)
                        end

                        -- Kontrol Keyboard PC (WASD)
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end

                        if moveDir.Magnitude > 0 then
                            moveDir = moveDir.Unit
                        end

                        BodyVelocity.Velocity = moveDir * FlySpeed
                        BodyGyro.CFrame = cam
                        RunService.RenderStepped:Wait()
                    end
                    StopFly()
                end)
            end
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

local fsCorner = Instance.new("UICorner")
fsCorner.CornerRadius = UDim.new(0, 8)
fsCorner.Parent = FlySpeedFrame

local fsStroke = Instance.new("UIStroke")
fsStroke.Color = Color3.fromRGB(65, 65, 90)
fsStroke.Thickness = 1
fsStroke.Parent = FlySpeedFrame

local fsLabel = Instance.new("TextLabel")
fsLabel.Size = UDim2.new(0.6, 0, 1, 0)
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
    FlySpeed = math.max(15, FlySpeed - 15)
    fsLabel.Text = "Kecepatan Terbang: " .. FlySpeed
end)

PlusFlyBtn.MouseButton1Click:Connect(function()
    FlySpeed = math.min(250, FlySpeed + 15)
    fsLabel.Text = "Kecepatan Terbang: " .. FlySpeed
end)

-- Tembus Tembok (Noclip)
local NoclipConn = nil
CreateToggle(TabKarakter, "Tembus Tembok (Noclip)", function(state)
    if state then
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

-- Mode Kebal Pukulan
local GodModeConn = nil
CreateToggle(TabKarakter, "Kebal Pukulan (Mode Kebal)", function(state)
    if state then
        GodModeConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    hum.Health = hum.MaxHealth
                end
            end)
        end)
    else
        if GodModeConn then
            GodModeConn:Disconnect()
            GodModeConn = nil
        end
    end
end)

--// ==========================================
--// TAB 3: FITUR DISTRIK
--// ==========================================

-- Perbaikan Generator Otomatis
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
                                local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
                                local modelName = (obj.Parent and obj.Parent.Parent) and string.lower(obj.Parent.Parent.Name) or ""
                                if parentName:find("gen") or modelName:find("gen") or parentName:find("repair") then
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
                task.wait(0.4)
            end
        end)
    end
end)

-- Lepas Gantungan Otomatis (Anti Hook)
CreateToggle(TabDistrik, "Lepas Gantungan Otomatis (Anti Hook)", function(state)
    AntiHookEnabled = state
    if AntiHookEnabled then
        task.spawn(function()
            while AntiHookEnabled and ScriptActive do
                pcall(function()
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if root and hum then
                        if root.Anchored then
                            root.Anchored = false
                        end
                        if hum.PlatformStand and not Flying then
                            hum.PlatformStand = false
                            root.CFrame = root.CFrame + Vector3.new(0, 4, 0)
                        end
                    end
                end)
                task.wait(0.35)
            end
        end)
    end
end)

-- Teleport ke Pemain Terdekat
CreateActionButton(TabDistrik, "Teleport ke Pemain Terdekat", "PINDAH", function()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local targetCFrame = nil
    local closestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsPlayerKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                targetCFrame = p.Character.HumanoidRootPart.CFrame
            end
        end
    end

    if targetCFrame then
        myRoot.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end
end)

-- Teleport ke Killer / Lawan
CreateActionButton(TabDistrik, "Teleport ke Killer (Lawan)", "PINDAH", function()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsPlayerKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            myRoot.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 4)
            break
        end
    end
end)

--// ==========================================
--// TAB 4: PENGATURAN
--// ==========================================

-- Transparansi Panel
CreateToggle(TabPengaturan, "Mode Panel Lebih Transparan", function(state)
    MainFrame.BackgroundTransparency = state and 0.65 or 0.25
    TopBar.BackgroundTransparency = state and 0.6 or 0.2
    TopBarFix.BackgroundTransparency = state and 0.6 or 0.2
end)

-- Anti-Lag & Patah-Patah
CreateActionButton(TabPengaturan, "Optimasi Anti-Lag & FPS Boost", "BERSIHKAN", function()
    Lighting.GlobalShadows = false
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
        end
    end
end)

-- Pulihkan Karakter Jika Nyangkut
CreateActionButton(TabPengaturan, "Bebaskan Karakter Nyangkut", "PULIHKAN", function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum then
        root.Anchored = false
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
    end
end)

--// ==========================================
--// PEMBERSIHAN TOTAL SAAT TOMBOL TUTUP (×) DITEKAN
--// ==========================================
CloseBtn.MouseButton1Click:Connect(function()
    ScriptActive = false
    ESPEnabled = false
    GenESPEnabled = false
    AutoGenEnabled = false
    AntiHookEnabled = false
    StopFly()

    if NoclipConn then NoclipConn:Disconnect() end
    if GodModeConn then GodModeConn:Disconnect() end
    if InfJumpConn then InfJumpConn:Disconnect() end

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        ClearPlayerESP(p)
    end
    ClearAllGenESP()

    ScreenGui:Destroy()
end)

print("BimSakSin Hub (Versi Sempurna Bahasa Indonesia) Berhasil Dimuat!")
