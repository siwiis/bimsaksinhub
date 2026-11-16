--// ==========================================
--// BimSakSin Hub v4.0 - Edisi Distrik Pro
--// Kompatibel Penuh dengan Delta Executor
--// ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Hapus GUI lama jika script dijalankan ulang
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
local AutoGenPerfectEnabled = false
local AutoHealFastEnabled = false
local TeleportLockEnabled = false
local SelectedTeleportTarget = nil
local NoclipEnabled = false
local GodModeEnabled = false
local AutoParryEnabled = false
local Flying = false
local FlySpeed = 50
local FlyVerticalInput = 0

-- Kecepatan Lari (Berlaku untuk Pemain & Killer)
local SpeedHackEnabled = false
local CustomWalkSpeed = 36

-- Variabel Status Killer
local KillerNoDelayEnabled = false
local KillerBrutalHitEnabled = false
local KillerAimbotEnabled = false

local ActiveDanceTrack = nil
local Connections = {}
local ModifiedWallParts = {}

-- Palet Warna Dof
local MatteBlack      = Color3.fromRGB(15, 15, 18)     -- Hitam Dof
local MatteWhite      = Color3.fromRGB(235, 235, 240)  -- Putih Dof
local MatteLightBlue  = Color3.fromRGB(115, 185, 225)  -- Biru Muda Dof
local MatteBlueDark   = Color3.fromRGB(45, 75, 95)     -- Biru Muda Dof (Saat Mati)

--// ==========================================
--// FUNGSI DRAG & RESIZE HALUS (TOUCH & MOUSE)
--// ==========================================
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

local function MakeResizable(resizeHandle, targetFrame, minSize, maxSize)
    local resizing = false
    local resizeInput, dragStart, startSize

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            dragStart = input.Position
            startSize = targetFrame.AbsoluteSize

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    resizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            resizeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == resizeInput and resizing then
            local delta = input.Position - dragStart
            local newW = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
            local newH = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
            targetFrame.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
end

--// ==========================================
--// PANEL UTAMA (RESIZABLE + TRANSPARAN)
--// ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 425)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -212)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
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
--// LOGO TENGKORAK HITAM DOF TRANSPARAN (TENGAH PANEL)
--// ==========================================
local SkullContainer = Instance.new("Frame")
SkullContainer.Name = "SkullWatermark"
SkullContainer.AnchorPoint = Vector2.new(0.5, 0.5)
SkullContainer.Position = UDim2.new(0.5, 0, 0.56, 0)
SkullContainer.Size = UDim2.new(0.44, 0, 0.44, 0)
SkullContainer.BackgroundTransparency = 1
SkullContainer.ZIndex = 1
SkullContainer.Parent = MainFrame

local SkullAspect = Instance.new("UIAspectRatioConstraint")
SkullAspect.AspectRatio = 1
SkullAspect.Parent = SkullContainer

local function CreateSkullPart(name, size, pos, radius, color, trans)
    local p = Instance.new("Frame")
    p.Name = name
    p.Size = size
    p.Position = pos
    p.BackgroundColor3 = color
    p.BackgroundTransparency = trans
    p.BorderSizePixel = 0
    p.ZIndex = 1
    p.Parent = SkullContainer
    if radius > 0 then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(radius, 0)
        c.Parent = p
    end
    return p
end

local SocketDark = Color3.fromRGB(24, 24, 34)
local Cranium = CreateSkullPart("Cranium", UDim2.new(0.68, 0, 0.58, 0), UDim2.new(0.16, 0, 0.08, 0), 0.5, MatteBlack, 0.42)
local SkullStroke = Instance.new("UIStroke", Cranium)
SkullStroke.Color = Color3.fromRGB(45, 45, 60)
SkullStroke.Thickness = 1.5
SkullStroke.Transparency = 0.5

CreateSkullPart("CheekLeft", UDim2.new(0.24, 0, 0.24, 0), UDim2.new(0.18, 0, 0.46, 0), 0.35, MatteBlack, 0.42)
CreateSkullPart("CheekRight", UDim2.new(0.24, 0, 0.24, 0), UDim2.new(0.58, 0, 0.46, 0), 0.35, MatteBlack, 0.42)
local Jaw = CreateSkullPart("Jaw", UDim2.new(0.42, 0, 0.28, 0), UDim2.new(0.29, 0, 0.62, 0), 0.25, MatteBlack, 0.42)
local JawStroke = Instance.new("UIStroke", Jaw)
JawStroke.Color = Color3.fromRGB(45, 45, 60)
JawStroke.Thickness = 1.2
JawStroke.Transparency = 0.5

CreateSkullPart("EyeLeft", UDim2.new(0.17, 0, 0.17, 0), UDim2.new(0.26, 0, 0.36, 0), 0.5, SocketDark, 0.3)
CreateSkullPart("EyeRight", UDim2.new(0.17, 0, 0.17, 0), UDim2.new(0.57, 0, 0.36, 0), 0.5, SocketDark, 0.3)
CreateSkullPart("Nose", UDim2.new(0.10, 0, 0.12, 0), UDim2.new(0.45, 0, 0.52, 0), 0.3, SocketDark, 0.3)
CreateSkullPart("Tooth1", UDim2.new(0.04, 0, 0.12, 0), UDim2.new(0.36, 0, 0.74, 0), 0.2, SocketDark, 0.35)
CreateSkullPart("Tooth2", UDim2.new(0.04, 0, 0.12, 0), UDim2.new(0.44, 0, 0.74, 0), 0.2, SocketDark, 0.35)
CreateSkullPart("Tooth3", UDim2.new(0.04, 0, 0.12, 0), UDim2.new(0.52, 0, 0.74, 0), 0.2, SocketDark, 0.35)
CreateSkullPart("Tooth4", UDim2.new(0.04, 0, 0.12, 0), UDim2.new(0.60, 0, 0.74, 0), 0.2, SocketDark, 0.35)

--// ==========================================
--// HEADER ATAS (TOP BAR) & TOMBOL KONTROL
--// ==========================================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
TitleLabel.Position = UDim2.new(0.2, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamMedium
TitleLabel.Text = "BimSakSin Hub v4.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 17
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.ZIndex = 4
TitleLabel.Parent = TopBar

local TitleOutline = Instance.new("UIStroke", TitleLabel)
TitleOutline.Color = MatteBlack
TitleOutline.Thickness = 1.2

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 34, 0, 34)
MinBtn.Position = UDim2.new(1, -76, 0, 5)
MinBtn.BackgroundTransparency = 1
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = MatteWhite
MinBtn.TextSize = 20
MinBtn.ZIndex = 4
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
CloseBtn.TextSize = 20
CloseBtn.ZIndex = 4
CloseBtn.Parent = TopBar

local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Name = "ResizeGrip"
ResizeGrip.Size = UDim2.new(0, 26, 0, 26)
ResizeGrip.Position = UDim2.new(1, -26, 1, -26)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Font = Enum.Font.GothamBold
ResizeGrip.Text = "◢"
ResizeGrip.TextColor3 = MatteLightBlue
ResizeGrip.TextSize = 14
ResizeGrip.ZIndex = 10
ResizeGrip.Parent = MainFrame

MakeResizable(ResizeGrip, MainFrame, Vector2.new(420, 300), Vector2.new(860, 680))

--// ==========================================
--// FLOATING TOGGLE (FONT TIPIS & HALUS)
--// ==========================================
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 195, 0, 40)
FloatingToggle.Position = UDim2.new(0, 25, 0, 25)
FloatingToggle.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
FloatingToggle.BackgroundTransparency = 0.3
FloatingToggle.AutoButtonColor = false
FloatingToggle.Visible = false
FloatingToggle.Font = Enum.Font.Gotham
FloatingToggle.Text = "BimSakSin Hub v4.0"
FloatingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingToggle.TextSize = 14
FloatingToggle.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 20)
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
--// KONTROL TERBANG NAIK / TURUN KHUSUS LAYAR HP
--// ==========================================
local FlyControlFrame = Instance.new("Frame")
FlyControlFrame.Name = "FlyControls"
FlyControlFrame.Size = UDim2.new(0, 56, 0, 120)
FlyControlFrame.Position = UDim2.new(1, -76, 0.55, -60)
FlyControlFrame.BackgroundTransparency = 1
FlyControlFrame.Visible = false
FlyControlFrame.Parent = ScreenGui

local FlyUpBtn = Instance.new("TextButton")
FlyUpBtn.Size = UDim2.new(1, 0, 0, 54)
FlyUpBtn.Position = UDim2.new(0, 0, 0, 0)
FlyUpBtn.BackgroundColor3 = MatteLightBlue
FlyUpBtn.BackgroundTransparency = 0.2
FlyUpBtn.Font = Enum.Font.GothamBold
FlyUpBtn.Text = "▲\nNAIK"
FlyUpBtn.TextColor3 = MatteWhite
FlyUpBtn.TextSize = 12
FlyUpBtn.Parent = FlyControlFrame
Instance.new("UICorner", FlyUpBtn).CornerRadius = UDim.new(0, 10)
local upStroke = Instance.new("UIStroke", FlyUpBtn)
upStroke.Color = MatteBlack
upStroke.Thickness = 1.5

local FlyDownBtn = Instance.new("TextButton")
FlyDownBtn.Size = UDim2.new(1, 0, 0, 54)
FlyDownBtn.Position = UDim2.new(0, 0, 0, 62)
FlyDownBtn.BackgroundColor3 = MatteLightBlue
FlyDownBtn.BackgroundTransparency = 0.2
FlyDownBtn.Font = Enum.Font.GothamBold
FlyDownBtn.Text = "TURUN\n▼"
FlyDownBtn.TextColor3 = MatteWhite
FlyDownBtn.TextSize = 12
FlyDownBtn.Parent = FlyControlFrame
Instance.new("UICorner", FlyDownBtn).CornerRadius = UDim.new(0, 10)
local downStroke = Instance.new("UIStroke", FlyDownBtn)
downStroke.Color = MatteBlack
downStroke.Thickness = 1.5

FlyUpBtn.MouseButton1Down:Connect(function() FlyVerticalInput = 1 end)
FlyUpBtn.MouseButton1Up:Connect(function() FlyVerticalInput = 0 end)
FlyUpBtn.MouseLeave:Connect(function() FlyVerticalInput = 0 end)

FlyDownBtn.MouseButton1Down:Connect(function() FlyVerticalInput = -1 end)
FlyDownBtn.MouseButton1Up:Connect(function() FlyVerticalInput = 0 end)
FlyDownBtn.MouseLeave:Connect(function() FlyVerticalInput = 0 end)

--// ==========================================
--// BANNER PERINGATAN AUTO TANGKIS
--// ==========================================
local ParryAlertLabel = Instance.new("TextLabel")
ParryAlertLabel.Name = "ParryAlert"
ParryAlertLabel.Size = UDim2.new(0, 340, 0, 36)
ParryAlertLabel.Position = UDim2.new(0.5, -170, 0.14, 0)
ParryAlertLabel.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
ParryAlertLabel.BackgroundTransparency = 0.15
ParryAlertLabel.Visible = false
ParryAlertLabel.Font = Enum.Font.GothamBold
ParryAlertLabel.Text = "⚠️ KILLER MENYERANG! AUTO TANGKIS AKTIF ⚠️"
ParryAlertLabel.TextColor3 = MatteWhite
ParryAlertLabel.TextSize = 13
ParryAlertLabel.Parent = ScreenGui
Instance.new("UICorner", ParryAlertLabel).CornerRadius = UDim.new(0, 8)
local ParryStroke = Instance.new("UIStroke", ParryAlertLabel)
ParryStroke.Color = MatteBlack
ParryStroke.Thickness = 1.5

--// ==========================================
--// NAVIGASI 6 TAB MENU (UKURAN FONT NORMAL & TEBAL + HITAM DOF)
--// ==========================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 50)
TabBar.BackgroundTransparency = 1
TabBar.ZIndex = 3
TabBar.Parent = MainFrame

local UIListTab = Instance.new("UIListLayout")
UIListTab.FillDirection = Enum.FillDirection.Horizontal
UIListTab.SortOrder = Enum.SortOrder.LayoutOrder
UIListTab.Padding = UDim.new(0, 5)
UIListTab.Parent = TabBar

local TabList = {}
local function CreateTab(tabName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/6, -4.2, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.Text = tabName
    btn.TextColor3 = MatteWhite
    btn.TextSize = 12
    btn.TextScaled = false
    btn.ZIndex = 3
    btn.Parent = TabBar

    local textStroke = Instance.new("UIStroke")
    textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    textStroke.Color = MatteBlack
    textStroke.Thickness = 1.2
    textStroke.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, -20, 1, -100)
    scrolling.Position = UDim2.new(0, 10, 0, 90)
    scrolling.BackgroundTransparency = 1
    scrolling.BorderSizePixel = 0
    scrolling.ScrollBarThickness = 4
    scrolling.ScrollBarImageColor3 = MatteLightBlue
    scrolling.Visible = false
    scrolling.ZIndex = 3
    scrolling.Parent = MainFrame

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 7)
    list.Parent = scrolling

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrolling.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 16)
    end)

    table.insert(TabList, {Button = btn, Frame = scrolling})
    return scrolling
end

local TabVisual    = CreateTab("Visual ESP")
local TabKarakter  = CreateTab("Karakter")
local TabDistrik   = CreateTab("Distrik")
local TabKiller    = CreateTab("Fitur Killer")
local TabDance     = CreateTab("Dance")
local TabInformasi = CreateTab("Informasi")

for _, tabData in ipairs(TabList) do
    tabData.Button.MouseButton1Click:Connect(function()
        for _, t in ipairs(TabList) do
            t.Frame.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
            t.Button.TextColor3 = MatteWhite
        end
        tabData.Frame.Visible = true
        tabData.Button.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
        tabData.Button.TextColor3 = MatteWhite
    end)
end

TabVisual.Visible = true
TabList[1].Button.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
TabList[1].Button.TextColor3 = MatteWhite

--// ==========================================
--// ANIMASI RGB HALUS PANEL & GARIS PINGGIR
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
--// HELPER KOMPONEN UI (PUTIH DOF + TOMBOL BIRU MUDA DOF)
--// ==========================================
local function CreateToggle(parentTab, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "   " .. title
    btn.TextColor3 = MatteWhite
    btn.TextSize = 12.5
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 4
    btn.Parent = parentTab

    local titleStroke = Instance.new("UIStroke")
    titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    titleStroke.Color = MatteBlack
    titleStroke.Thickness = 1.1
    titleStroke.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(65, 65, 90)
    stroke.Thickness = 1
    stroke.Parent = btn

    local statusBadge = Instance.new("TextLabel")
    statusBadge.Size = UDim2.new(0, 78, 0, 24)
    statusBadge.Position = UDim2.new(1, -86, 0.5, -12)
    statusBadge.BackgroundColor3 = MatteBlueDark
    statusBadge.BackgroundTransparency = 0.15
    statusBadge.Font = Enum.Font.GothamBold
    statusBadge.Text = "MATI"
    statusBadge.TextColor3 = MatteWhite
    statusBadge.TextSize = 11
    statusBadge.ZIndex = 5
    statusBadge.Parent = btn

    Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 6)

    local badgeBorder = Instance.new("UIStroke")
    badgeBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    badgeBorder.Color = MatteBlack
    badgeBorder.Thickness = 1.2
    badgeBorder.Parent = statusBadge

    local badgeTextStroke = Instance.new("UIStroke")
    badgeTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    badgeTextStroke.Color = MatteBlack
    badgeTextStroke.Thickness = 1
    badgeTextStroke.Parent = statusBadge

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            statusBadge.Text = "AKTIF"
            statusBadge.BackgroundColor3 = MatteLightBlue
            statusBadge.TextColor3 = MatteWhite
            stroke.Color = MatteLightBlue
            btn.BackgroundColor3 = Color3.fromRGB(25, 38, 48)
        else
            statusBadge.Text = "MATI"
            statusBadge.BackgroundColor3 = MatteBlueDark
            statusBadge.TextColor3 = MatteWhite
            stroke.Color = Color3.fromRGB(65, 65, 90)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        end
        pcall(function()
            callback(state, statusBadge)
        end)
    end)
    return btn, statusBadge
end

local function CreateActionButton(parentTab, title, actionText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "   " .. title
    btn.TextColor3 = MatteWhite
    btn.TextSize = 12.5
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 4
    btn.Parent = parentTab

    local titleStroke = Instance.new("UIStroke")
    titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    titleStroke.Color = MatteBlack
    titleStroke.Thickness = 1.1
    titleStroke.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(65, 65, 90)
    stroke.Thickness = 1
    stroke.Parent = btn

    local tagBadge = Instance.new("TextLabel")
    tagBadge.Size = UDim2.new(0, 110, 0, 24)
    tagBadge.Position = UDim2.new(1, -118, 0.5, -12)
    tagBadge.BackgroundColor3 = MatteLightBlue
    tagBadge.BackgroundTransparency = 0.1
    tagBadge.Font = Enum.Font.GothamBold
    tagBadge.Text = actionText
    tagBadge.TextColor3 = MatteWhite
    tagBadge.TextSize = 11
    tagBadge.ZIndex = 5
    tagBadge.Parent = btn

    Instance.new("UICorner", tagBadge).CornerRadius = UDim.new(0, 6)

    local badgeBorder = Instance.new("UIStroke")
    badgeBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    badgeBorder.Color = MatteBlack
    badgeBorder.Thickness = 1.2
    badgeBorder.Parent = tagBadge

    local badgeTextStroke = Instance.new("UIStroke")
    badgeTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    badgeTextStroke.Color = MatteBlack
    badgeTextStroke.Thickness = 1
    badgeTextStroke.Parent = tagBadge

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(30, 45, 58)
        task.delay(0.18, function()
            if btn and btn.Parent then
                btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
            end
        end)
        pcall(function()
            callback(tagBadge, btn)
        end)
    end)
    return btn, tagBadge
end

local function CreateStepperControl(parentTab, labelPrefix, initialVal, stepVal, minVal, maxVal, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    frame.BackgroundTransparency = 0.25
    frame.ZIndex = 4
    frame.Parent = parentTab

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", frame)
    st.Color = Color3.fromRGB(65, 65, 90)
    st.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelPrefix .. ": " .. initialVal
    lbl.TextColor3 = MatteWhite
    lbl.TextSize = 12.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = frame

    local lblStroke = Instance.new("UIStroke", lbl)
    lblStroke.Color = MatteBlack
    lblStroke.Thickness = 1.1

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 32, 0, 26)
    minus.Position = UDim2.new(1, -78, 0.5, -13)
    minus.BackgroundColor3 = MatteBlueDark
    minus.Font = Enum.Font.GothamBold
    minus.Text = "-"
    minus.TextColor3 = MatteWhite
    minus.TextSize = 15
    minus.ZIndex = 5
    minus.Parent = frame
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)
    local mStroke = Instance.new("UIStroke", minus)
    mStroke.Color = MatteBlack
    mStroke.Thickness = 1.2

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 32, 0, 26)
    plus.Position = UDim2.new(1, -40, 0.5, -13)
    plus.BackgroundColor3 = MatteLightBlue
    plus.Font = Enum.Font.GothamBold
    plus.Text = "+"
    plus.TextColor3 = MatteWhite
    plus.TextSize = 15
    plus.ZIndex = 5
    plus.Parent = frame
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)
    local pStroke = Instance.new("UIStroke", plus)
    pStroke.Color = MatteBlack
    pStroke.Thickness = 1.2

    local currentVal = initialVal
    minus.MouseButton1Click:Connect(function()
        currentVal = math.max(minVal, currentVal - stepVal)
        lbl.Text = labelPrefix .. ": " .. currentVal
        onChange(currentVal)
    end)

    plus.MouseButton1Click:Connect(function()
        currentVal = math.min(maxVal, currentVal + stepVal)
        lbl.Text = labelPrefix .. ": " .. currentVal
        onChange(currentVal)
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
--// HELPER OUTLINE HITAM DOF + RGB BERKEDIP UNTUK TEKS ESP
--// ==========================================
local function AttachMatteRGBStroke(textLabel)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.8
    stroke.Color = MatteBlack
    stroke.Parent = textLabel

    task.spawn(function()
        while ScriptActive and textLabel and textLabel.Parent and stroke and stroke.Parent do
            local hue = (tick() * 0.85) % 1
            local rgbColor = Color3.fromHSV(hue, 0.9, 1)
            local blinkMix = (math.sin(tick() * 7) + 1) / 2
            stroke.Color = MatteBlack:Lerp(rgbColor, blinkMix)
            RunService.RenderStepped:Wait()
        end
    end)
end

--// ==========================================
--// TAB 1: VISUAL ESP
--// ==========================================
local function ClearPlayerESP(player)
    if player and player.Character then
        if player.Character:FindFirstChild("BimSakSinESP") then player.Character.BimSakSinESP:Destroy() end
        if player.Character:FindFirstChild("BimSakSinESPInfo") then player.Character.BimSakSinESPInfo:Destroy() end
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
        local greenHex = "#28FF6E"
        local goldHex  = "#FFD700"
        local redHex   = "#FF2828"

        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSinESP"
        hl.Adornee = char
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = isKiller and Color3.fromRGB(255, 35, 35) or Color3.fromRGB(40, 255, 110)
        hl.OutlineColor = MatteBlack
        hl.FillTransparency = 0.45
        hl.OutlineTransparency = 0
        hl.Parent = char

        local bill = Instance.new("BillboardGui")
        bill.Name = "BimSakSinESPInfo"
        bill.Adornee = root
        bill.Size = UDim2.new(0, 210, 0, 48)
        bill.StudsOffset = Vector3.new(0, 3.3, 0)
        bill.AlwaysOnTop = true
        bill.Parent = char

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.RichText = true
        label.TextColor3 = MatteWhite
        label.Parent = bill

        AttachMatteRGBStroke(label)

        task.spawn(function()
            while ESPEnabled and ScriptActive and char and char.Parent and bill and bill.Parent do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot and root then
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        local nowKiller = IsPlayerKiller(player)
                        if nowKiller then
                            hl.FillColor = Color3.fromRGB(255, 35, 35)
                            label.Text = string.format(
                                '<font color="%s">[KILLER] %s</font>\n<font color="%s">Jarak: %dm</font>',
                                redHex, player.Name, redHex, dist
                            )
                        else
                            hl.FillColor = Color3.fromRGB(40, 255, 110)
                            label.Text = string.format(
                                '<font color="%s">[PEMAIN] %s</font>\n<font color="%s">Jarak: %dm</font>',
                                greenHex, player.Name, goldHex, dist
                            )
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

CreateToggle(TabVisual, "ESP Pemain (Hijau+Gold) & Killer (Merah)", function(state)
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

-- ESP Generator + Persentase Biru + Jarak Oranye
local function GetGeneratorProgress(genObj)
    local pct = nil
    pcall(function()
        for _, attrName in ipairs({"Progress", "RepairProgress", "Percent", "Completion", "Charge"}) do
            local val = genObj:GetAttribute(attrName)
            if type(val) == "number" then
                pct = (val <= 1.05 and val > 0) and math.floor(val * 100) or math.floor(val)
                return
            end
        end
        for _, desc in ipairs(genObj:GetDescendants()) do
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                local nLower = string.lower(desc.Name)
                if nLower:find("progress") or nLower:find("repair") or nLower:find("percent") or nLower:find("charge") or nLower:find("value") then
                    local v = desc.Value
                    if v >= 0 and v <= 100 then
                        pct = (v <= 1 and v > 0) and math.floor(v * 100) or math.floor(v)
                        return
                    end
                end
            end
        end
    end)
    return math.clamp(pct or 0, 0, 100)
end

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

CreateToggle(TabVisual, "ESP Generator (Proses Biru + Jarak Oranye)", function(state)
    GenESPEnabled = state
    if GenESPEnabled then
        task.spawn(function()
            while GenESPEnabled and ScriptActive do
                pcall(function()
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if (obj:IsA("Model") or obj:IsA("BasePart")) and IsGeneratorObject(obj) then
                            local targetModel = obj:IsA("Model") and obj or (obj.Parent and obj.Parent:IsA("Model") and obj.Parent or obj)
                            local targetPart = targetModel:IsA("BasePart") and targetModel or (targetModel:FindFirstChild("PrimaryPart") or targetModel:FindFirstChildWhichIsA("BasePart"))

                            if targetPart and not targetModel:FindFirstChild("BimSakSinGenHL") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "BimSakSinGenHL"
                                hl.Adornee = targetModel
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.FillColor = Color3.fromRGB(0, 175, 255)
                                hl.OutlineColor = Color3.fromRGB(255, 145, 30)
                                hl.FillTransparency = 0.45
                                hl.OutlineTransparency = 0
                                hl.Parent = targetModel

                                local bill = Instance.new("BillboardGui")
                                bill.Name = "BimSakSinGenESP"
                                bill.Adornee = targetPart
                                bill.Size = UDim2.new(0, 190, 0, 52)
                                bill.StudsOffset = Vector3.new(0, 3.2, 0)
                                bill.AlwaysOnTop = true
                                bill.Parent = targetModel

                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                txt.Font = Enum.Font.GothamBold
                                txt.TextSize = 12
                                txt.RichText = true
                                txt.TextColor3 = MatteWhite
                                txt.Parent = bill

                                AttachMatteRGBStroke(txt)

                                task.spawn(function()
                                    while GenESPEnabled and ScriptActive and targetModel and targetModel.Parent and bill and bill.Parent do
                                        pcall(function()
                                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            if myRoot and targetPart then
                                                local d = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                                local progress = GetGeneratorProgress(targetModel)
                                                local statusKerja = (progress > 0 and progress < 100) and "Dikerjakan" or (progress >= 100 and "Selesai" or "Belum")
                                                txt.Text = string.format(
                                                    '<font color="#EBEBF0">[GENERATOR]</font>\n<font color="#38BDF8">Proses: %d%% (%s)</font>\n<font color="#FB923C">Jarak: %dm</font>',
                                                    progress, statusKerja, d
                                                )
                                            end
                                        end)
                                        task.wait(0.35)
                                    end
                                end)
                            end
                        end
                    end
                end)
                task.wait(2)
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
--// TAB 2: KARAKTER (SPEED PEMAIN & KILLER, FLY NORMAL, TELEPORT TERLIHAT, NOCLIP)
--// ==========================================

-- 1. SPEED LARI KENCANG (BERFUNGSI UNTUK PEMAIN MAUPUN KILLER)
local SpeedPropertyConn = nil
local SpeedRenderConn = nil

local function BindWalkSpeedProtection(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    if SpeedPropertyConn then SpeedPropertyConn:Disconnect() end
    SpeedPropertyConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if SpeedHackEnabled and ScriptActive then
            if hum.WalkSpeed ~= CustomWalkSpeed then
                hum.WalkSpeed = CustomWalkSpeed
            end
        end
    end)

    if SpeedHackEnabled then
        hum.WalkSpeed = CustomWalkSpeed
    end
end

if LocalPlayer.Character then BindWalkSpeedProtection(LocalPlayer.Character) end
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(BindWalkSpeedProtection))

CreateToggle(TabKarakter, "Speed Lari Kencang (Pemain & Killer)", function(state)
    SpeedHackEnabled = state
    if SpeedHackEnabled then
        if LocalPlayer.Character then
            BindWalkSpeedProtection(LocalPlayer.Character)
        end
        SpeedRenderConn = RunService.RenderStepped:Connect(function(dt)
            if not SpeedHackEnabled or not ScriptActive or Flying then return end
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if hum and root then
                    hum.WalkSpeed = CustomWalkSpeed
                    if hum.MoveDirection.Magnitude > 0 and CustomWalkSpeed > 22 then
                        local extraSpeed = (CustomWalkSpeed - 20) * 0.45
                        root.CFrame = root.CFrame + (hum.MoveDirection * extraSpeed * dt)
                    end
                end
            end)
        end)
    else
        if SpeedRenderConn then
            SpeedRenderConn:Disconnect()
            SpeedRenderConn = nil
        end
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end)
    end
end)

CreateStepperControl(TabKarakter, "Atur Kecepatan Lari", CustomWalkSpeed, 6, 16, 150, function(val)
    CustomWalkSpeed = val
    if SpeedHackEnabled then
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = CustomWalkSpeed end
        end)
    end
end)

-- 2. TELEPORT MENETAP & TERLIHAT OLEH PEMAIN LAIN / KILLER
local function GetValidTargetPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, p)
        end
    end
    return list
end

local TargetIndex = 1
CreateActionButton(TabKarakter, "Pilih Target Pemain Teleport", "TERDEKAT", function(tag)
    local list = GetValidTargetPlayers()
    if #list == 0 then
        SelectedTeleportTarget = nil
        tag.Text = "KOSONG"
        return
    end
    TargetIndex = (TargetIndex % #list) + 1
    SelectedTeleportTarget = list[TargetIndex]
    tag.Text = string.sub(SelectedTeleportTarget.Name, 1, 12)
end)

local function ReplicatedMoveTo(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum then return end

        hum.Sit = false
        hum.PlatformStand = false
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        local startPos = root.Position
        local endPos = targetCFrame.Position
        local distance = (endPos - startPos).Magnitude

        if distance > 75 then
            local steps = math.min(math.ceil(distance / 60), 12)
            for i = 1, steps do
                local alpha = i / steps
                local stepPos = startPos:Lerp(endPos, alpha)
                char:PivotTo(CFrame.new(stepPos) * (targetCFrame - targetCFrame.Position))
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                task.wait(0.03)
            end
        else
            char:PivotTo(targetCFrame)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local TeleportLockConn = nil
CreateToggle(TabKarakter, "Teleport & Menetap (Terlihat Pemain Lain)", function(state)
    TeleportLockEnabled = state
    if TeleportLockEnabled then
        if not SelectedTeleportTarget or not SelectedTeleportTarget.Parent then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local minD = math.huge
            for _, p in ipairs(GetValidTargetPlayers()) do
                local d = myRoot and (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude or 0
                if d < minD then
                    minD = d
                    SelectedTeleportTarget = p
                end
            end
        end

        if SelectedTeleportTarget and SelectedTeleportTarget.Character and SelectedTeleportTarget.Character:FindFirstChild("HumanoidRootPart") then
            local dest = SelectedTeleportTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3.8)
            task.spawn(function()
                ReplicatedMoveTo(dest)
            end)
        end

        local lastSync = 0
        TeleportLockConn = RunService.Heartbeat:Connect(function()
            if not TeleportLockEnabled or not ScriptActive then return end
            if (tick() - lastSync) < 0.08 then return end
            lastSync = tick()

            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetChar = SelectedTeleportTarget and SelectedTeleportTarget.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                if myChar and myRoot and targetRoot then
                    local dest = targetRoot.CFrame * CFrame.new(0, 0, 3.8)
                    myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    myChar:PivotTo(dest)
                end
            end)
        end)
    else
        if TeleportLockConn then
            TeleportLockConn:Disconnect()
            TeleportLockConn = nil
        end
        pcall(function()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myRoot and hum then
                myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hum:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end)
    end
end)

-- 3. FITUR FLY / TERBANG NORMAL & HALUS
local FlyBodyVel, FlyBodyGyro, FlyRenderConn
local function StopFly()
    Flying = false
    FlyVerticalInput = 0
    FlyControlFrame.Visible = false
    if FlyRenderConn then
        FlyRenderConn:Disconnect()
        FlyRenderConn = nil
    end
    pcall(function()
        if FlyBodyVel then FlyBodyVel:Destroy() FlyBodyVel = nil end
        if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

CreateToggle(TabKarakter, "Terbang Halus & Normal (Fly Mode)", function(state)
    if state then
        Flying = true
        FlyControlFrame.Visible = true
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not hum then return end

            hum.PlatformStand = true

            FlyBodyGyro = Instance.new("BodyGyro")
            FlyBodyGyro.P = 9e4
            FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyBodyGyro.CFrame = root.CFrame
            FlyBodyGyro.Parent = root

            FlyBodyVel = Instance.new("BodyVelocity")
            FlyBodyVel.Velocity = Vector3.new(0, 0, 0)
            FlyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyBodyVel.Parent = root

            FlyRenderConn = RunService.RenderStepped:Connect(function()
                if not Flying or not ScriptActive then return end
                pcall(function()
                    if not root or not root.Parent or not hum or hum.Health <= 0 then
                        StopFly()
                        return
                    end

                    hum.PlatformStand = true
                    local cam = Camera.CFrame
                    local moveDir = Vector3.new(0, 0, 0)

                    if hum.MoveDirection.Magnitude > 0 then
                        local flatLook = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
                        local flatRight = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
                        if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
                        moveDir = (cam.LookVector * hum.MoveDirection:Dot(flatLook)) + (cam.RightVector * hum.MoveDirection:Dot(flatRight))
                    end

                    if FlyVerticalInput ~= 0 then
                        moveDir = moveDir + Vector3.new(0, FlyVerticalInput, 0)
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit
                    end

                    FlyBodyVel.Velocity = moveDir * FlySpeed
                    FlyBodyGyro.CFrame = cam
                end)
            end)
        end)
    else
        StopFly()
    end
end)

CreateStepperControl(TabKarakter, "Kecepatan Terbang", FlySpeed, 15, 15, 250, function(val)
    FlySpeed = val
end)

-- 4. TEMBUS TEMBOK HALUS + TEMBOK TRANSPARAN
local function RestoreTransparentWalls()
    for part, _ in pairs(ModifiedWallParts) do
        pcall(function()
            if part and part.Parent then
                part.CanCollide = true
                part.LocalTransparencyModifier = 0
            end
        end)
    end
    ModifiedWallParts = {}
end

local NoclipConn = nil
CreateToggle(TabKarakter, "Tembus Tembok Halus + Transparan", function(state)
    NoclipEnabled = state
    if NoclipEnabled then
        NoclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                local overlapParams = OverlapParams.new()
                overlapParams.FilterDescendantsInstances = {char}
                overlapParams.FilterType = Enum.RaycastFilterType.Exclude

                local nearbyParts = Workspace:GetPartBoundsInRadius(root.Position, 6.5, overlapParams)
                local currentFrameWalls = {}

                for _, wall in ipairs(nearbyParts) do
                    if wall:IsA("BasePart") and wall.CanCollide and wall.Position.Y >= (root.Position.Y - 2.6) then
                        currentFrameWalls[wall] = true
                        ModifiedWallParts[wall] = true
                        wall.CanCollide = false
                        wall.LocalTransparencyModifier = 0.68
                    end
                end

                for wall, _ in pairs(ModifiedWallParts) do
                    if not currentFrameWalls[wall] then
                        if wall and wall.Parent then
                            wall.CanCollide = true
                            wall.LocalTransparencyModifier = 0
                        end
                        ModifiedWallParts[wall] = nil
                    end
                end
            end)
        end)
    else
        if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
        RestoreTransparentWalls()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CanCollide = true
            end
        end)
    end
end)

-- 5. KEBAL PUKULAN & TRANSPARAN SERANGAN
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
                    if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
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
        if GodModeConn then GodModeConn:Disconnect() GodModeConn = nil end
        RestoreCharacterHitbox()
    end
end)

-- 6. AUTO MENANGKIS SERANGAN KILLER
local LastParryTime = 0
CreateToggle(TabKarakter, "Auto Menangkis Serangan Killer + Tanda", function(state)
    AutoParryEnabled = state
    if AutoParryEnabled then
        task.spawn(function()
            while AutoParryEnabled and ScriptActive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    local threatDetected = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and IsPlayerKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local kRoot = p.Character.HumanoidRootPart
                            local dist = (myRoot.Position - kRoot.Position).Magnitude
                            if dist <= 16 then
                                local kHum = p.Character:FindFirstChildOfClass("Humanoid")
                                local animator = kHum and kHum:FindFirstChildOfClass("Animator")
                                if animator then
                                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                        local aName = string.lower(track.Name)
                                        if aName:find("attack") or aName:find("swing") or aName:find("slash") or aName:find("hit") or aName:find("punch") or track.Priority == Enum.AnimationPriority.Action then
                                            threatDetected = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end

                    ParryAlertLabel.Visible = threatDetected
                    if threatDetected and (tick() - LastParryTime) > 0.75 then
                        LastParryTime = tick()
                        if VirtualInputManager then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                            task.wait(0.05)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        end
                    end
                end)
                task.wait(0.1)
            end
            ParryAlertLabel.Visible = false
        end)
    else
        ParryAlertLabel.Visible = false
    end
end)

--// ==========================================
--// TAB 3: DISTRIK (AUTO GENERATOR & HEAL PERFECT BERFUNGSI NORMAL)
--// ==========================================

local LastSkillCheckTrigger = 0
local LastNeedleRotations = {}

local function TriggerSkillCheckInput()
    LastSkillCheckTrigger = tick()
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            local vp = Camera.ViewportSize
            VirtualInputManager:SendMouseButtonEvent(vp.X * 0.5, vp.Y * 0.5, 0, true, game, 1)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            VirtualInputManager:SendMouseButtonEvent(vp.X * 0.5, vp.Y * 0.5, 0, false, game, 1)
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if (not AutoGenPerfectEnabled and not AutoHealFastEnabled) or not ScriptActive then return end
    if (tick() - LastSkillCheckTrigger) < 0.35 then return end

    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end

        for _, obj in ipairs(pGui:GetDescendants()) do
            if (obj:IsA("ImageLabel") or obj:IsA("Frame")) and obj.Visible and obj.Parent then
                local currentRot = obj.Rotation % 360
                local prevRot = LastNeedleRotations[obj]
                LastNeedleRotations[obj] = currentRot

                if prevRot and math.abs(currentRot - prevRot) > 0.5 and math.abs(currentRot - prevRot) < 45 then
                    local container = obj.Parent
                    for _, sibling in ipairs(container:GetChildren()) do
                        if sibling ~= obj and (sibling:IsA("ImageLabel") or sibling:IsA("Frame")) and sibling.Visible then
                            local sName = string.lower(sibling.Name)
                            local isTarget = sName:find("target") or sName:find("white") or sName:find("perfect")
                                or sName:find("great") or sName:find("zone") or sName:find("success")
                                or (sibling.BackgroundColor3.R > 0.85 and sibling.BackgroundColor3.G > 0.85 and sibling.BackgroundColor3.B > 0.85)

                            if isTarget then
                                local targetRot = sibling.Rotation % 360
                                local angleDiff = math.abs((currentRot - targetRot + 180) % 360 - 180)
                                if angleDiff <= 18 then
                                    TriggerSkillCheckInput()
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end)

local function TriggerPromptAction(prompt)
    pcall(function()
        prompt.HoldDuration = 0
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
        if prompt.InputHoldBegin then
            prompt:InputHoldBegin()
        end
    end)
end

CreateToggle(TabDistrik, "Auto Perbaikan Generator + Auto Perfect", function(state)
    AutoGenPerfectEnabled = state
    if AutoGenPerfectEnabled then
        task.spawn(function()
            while AutoGenPerfectEnabled and ScriptActive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local combined = string.lower(obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. (obj.Parent and obj.Parent.Name or ""))
                                if combined:find("gen") or combined:find("repair") or combined:find("perbaiki") or combined:find("fix") or combined:find("mesin") then
                                    local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
                                    if part and (myRoot.Position - part.Position).Magnitude <= (obj.MaxActivationDistance + 8) then
                                        TriggerPromptAction(obj)
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.25)
            end
        end)
    end
end)

CreateToggle(TabDistrik, "Auto Selamatkan & Sembuhkan Tim + Perfect", function(state)
    AutoHealFastEnabled = state
    if AutoHealFastEnabled then
        task.spawn(function()
            while AutoHealFastEnabled and ScriptActive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local combined = string.lower(obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. (obj.Parent and obj.Parent.Name or ""))
                                if combined:find("heal") or combined:find("sembuh") or combined:find("revive") or combined:find("tolong") or combined:find("rescue") or combined:find("selamat") or combined:find("unhook") or combined:find("lepas") then
                                    local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
                                    if part and (myRoot.Position - part.Position).Magnitude <= (obj.MaxActivationDistance + 10) then
                                        TriggerPromptAction(obj)
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.2)
            end
        end)
    end
end)

-- Lepas Gantungan Hook Manual
CreateActionButton(TabDistrik, "Lepas dari Hook / Gantungan (Manual)", "LEPAS", function(tag)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = false end
        end

        local keepJoints = {
            RootJoint = true, Neck = true, Waist = true,
            ["Left Shoulder"] = true, ["Right Shoulder"] = true,
            ["Left Hip"] = true, ["Right Hip"] = true,
            LeftShoulder = true, RightShoulder = true,
            LeftElbow = true, RightElbow = true, LeftWrist = true, RightWrist = true,
            LeftHip = true, RightHip = true, LeftKnee = true, RightKnee = true,
            LeftAnkle = true, RightAnkle = true
        }
        for _, desc in ipairs(char:GetDescendants()) do
            if (desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("Motor6D")) and not keepJoints[desc.Name] then
                desc:Destroy()
            end
        end

        hum.PlatformStand = false
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        char:PivotTo(root.CFrame * CFrame.new(0, 3, -5))
    end)
    tag.Text = "TERLEPAS!"
    task.delay(1.5, function()
        if tag and tag.Parent then tag.Text = "LEPAS" end
    end)
end)

--// ==========================================
--// TAB 4: FITUR KILLER
--// ==========================================
CreateToggle(TabKiller, "Pukulan Tanpa Delay / Anti-Stuck", function(state)
    KillerNoDelayEnabled = state
    if KillerNoDelayEnabled then
        task.spawn(function()
            while KillerNoDelayEnabled and ScriptActive do
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, tool in ipairs(char:GetChildren()) do
                            if tool:IsA("Tool") then
                                tool:SetAttribute("Cooldown", 0)
                                tool:SetAttribute("AttackCooldown", 0)
                                for _, val in ipairs(tool:GetDescendants()) do
                                    if (val:IsA("NumberValue") or val:IsA("BoolValue")) and string.lower(val.Name):find("cooldown") then
                                        if val:IsA("NumberValue") then val.Value = 0 else val.Value = false end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

CreateToggle(TabKiller, "Aimbot Pukulan Killer (Auto Target)", function(state)
    KillerAimbotEnabled = state
end)

CreateToggle(TabKiller, "Pukulan Brutal Multi-Damage (Spam Hit)", function(state)
    KillerBrutalHitEnabled = state
end)

local function BindKillerWeapon(char)
    if not char then return end
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                if not ScriptActive then return end
                pcall(function()
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    local nearestTarget = nil
                    local minDist = 18
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local tRoot = p.Character.HumanoidRootPart
                            local d = (myRoot.Position - tRoot.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                nearestTarget = p.Character
                            end
                        end
                    end

                    if KillerAimbotEnabled and nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                        local tPos = nearestTarget.HumanoidRootPart.Position
                        myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(tPos.X, myRoot.Position.Y, tPos.Z))
                    end

                    if KillerBrutalHitEnabled and nearestTarget and firetouchinterest then
                        local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
                        local targetPart = nearestTarget:FindFirstChild("HumanoidRootPart")
                        if handle and targetPart then
                            for _ = 1, 6 do
                                firetouchinterest(handle, targetPart, 0)
                                task.wait(0.02)
                                firetouchinterest(handle, targetPart, 1)
                            end
                        end
                    end
                end)
            end)
        end
    end)
end

if LocalPlayer.Character then BindKillerWeapon(LocalPlayer.Character) end
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(BindKillerWeapon))

--// ==========================================
--// TAB 5: DANCE LENGKAP (TERLIHAT SEMUA PEMAIN)
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

CreateActionButton(TabDance, "Hentikan Gerakan Dance", "STOP", function(tag)
    StopDance()
    tag.Text = "BERHENTI"
    task.delay(1.2, function()
        if tag and tag.Parent then tag.Text = "STOP" end
    end)
end)

for _, dance in ipairs(DanceList) do
    CreateActionButton(TabDance, dance.Name, "MULAI", function(tag)
        StopDance()
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
            local anim = Instance.new("Animation")
            anim.AnimationId = (hum.RigType == Enum.HumanoidRigType.R6) and dance.R6 or dance.R15
            ActiveDanceTrack = animator:LoadAnimation(anim)
            ActiveDanceTrack.Priority = Enum.AnimationPriority.Action
            ActiveDanceTrack.Looped = true
            ActiveDanceTrack:Play()
            Players:Chat(dance.Chat)
        end)
        tag.Text = "JOGET!"
        task.delay(1.5, function()
            if tag and tag.Parent then tag.Text = "MULAI" end
        end)
    end)
end

--// ==========================================
--// TAB 6: INFORMASI & DUKUNGAN DEVELOPER
--// ==========================================
local function CreateInfoCard(titleText, bodyText, linkUrl, buttonLabel)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -6, 0, linkUrl and 92 or 68)
    card.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    card.BackgroundTransparency = 0.2
    card.ZIndex = 4
    card.Parent = TabInformasi

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(75, 75, 105)
    stroke.Thickness = 1

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 22)
    header.Position = UDim2.new(0, 12, 0, 6)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.Text = titleText
    header.TextColor3 = MatteLightBlue
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.ZIndex = 4
    header.Parent = card

    local hStroke = Instance.new("UIStroke", header)
    hStroke.Color = MatteBlack
    hStroke.Thickness = 1.1

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -24, 0, 34)
    desc.Position = UDim2.new(0, 12, 0, 26)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.Text = bodyText
    desc.TextColor3 = MatteWhite
    desc.TextSize = 11.5
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.ZIndex = 4
    desc.Parent = card

    local dStroke = Instance.new("UIStroke", desc)
    dStroke.Color = MatteBlack
    dStroke.Thickness = 1

    if linkUrl then
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 175, 0, 24)
        copyBtn.Position = UDim2.new(0, 12, 1, -30)
        copyBtn.BackgroundColor3 = MatteLightBlue
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.Text = buttonLabel
        copyBtn.TextColor3 = MatteWhite
        copyBtn.TextSize = 11
        copyBtn.ZIndex = 5
        copyBtn.Parent = card
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

        local cbBorder = Instance.new("UIStroke", copyBtn)
        cbBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        cbBorder.Color = MatteBlack
        cbBorder.Thickness = 1.2

        local cbText = Instance.new("UIStroke", copyBtn)
        cbText.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        cbText.Color = MatteBlack
        cbText.Thickness = 1

        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(linkUrl) end
            copyBtn.Text = "Link Berhasil Disalin!"
            task.delay(2, function()
                if copyBtn and copyBtn.Parent then copyBtn.Text = buttonLabel end
            end)
        end)
    end
end

CreateInfoCard(
    "Laporan Bug & Bantuan Admin",
    "jika ada eror atau bug pada fitur - fitur hubungin dev/admin melaluin discord.",
    nil,
    nil
)

CreateInfoCard(
    "Update Script Terbaru (Discord)",
    "Join discord jika ada upadatean untuk fitur script terbaru : https://discord.gg/uSuzTJSuV",
    "https://discord.gg/uSuzTJSuV",
    "Salin Link Discord"
)

CreateInfoCard(
    "Dukungan Developer",
    "Link dukungan dev : https://linktr.ee/bimsaksin",
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
    AutoGenPerfectEnabled = false
    AutoHealFastEnabled = false
    TeleportLockEnabled = false
    NoclipEnabled = false
    GodModeEnabled = false
    AutoParryEnabled = false
    SpeedHackEnabled = false
    KillerNoDelayEnabled = false
    KillerBrutalHitEnabled = false
    KillerAimbotEnabled = false

    StopFly()
    StopDance()
    RestoreCharacterHitbox()
    RestoreTransparentWalls()

    if NoclipConn then NoclipConn:Disconnect() end
    if GodModeConn then GodModeConn:Disconnect() end
    if TeleportLockConn then TeleportLockConn:Disconnect() end
    if SpeedRenderConn then SpeedRenderConn:Disconnect() end
    if SpeedPropertyConn then SpeedPropertyConn:Disconnect() end

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        ClearPlayerESP(p)
    end
    ClearAllGenESP()

    ScreenGui:Destroy()
end)

print("BimSakSin Hub v4.0 Berhasil Dimuat!")
