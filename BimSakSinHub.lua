--// ==========================================
--// BimSakSin Hub - Edisi Distrik Pro v3.0
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
local CustomWalkSpeed = 16
local WalkSpeedEnabled = false

-- Variabel Status Killer
local KillerNoDelayEnabled = false
local KillerBrutalHitEnabled = false
local KillerAimbotEnabled = false

local ActiveDanceTrack = nil
local Connections = {}
local ModifiedWallParts = {}

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
MainFrame.Size = UDim2.new(0, 560, 0, 430)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -215)
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
SkullContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
SkullContainer.Size = UDim2.new(0.45, 0, 0.45, 0)
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

-- Struktur Emblem Tengkorak Hitam Dof
local MatteBlack = Color3.fromRGB(8, 8, 10)
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

-- Rongga Mata, Hidung, & Gigi Tengkorak
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
TopBar.Size = UDim2.new(1, 0, 0, 46)
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
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 17
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.ZIndex = 4
TitleLabel.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 36, 0, 36)
MinBtn.Position = UDim2.new(1, -78, 0, 5)
MinBtn.BackgroundTransparency = 1
MinBtn.Font = Enum.Font.GothamMedium
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinBtn.TextSize = 22
MinBtn.ZIndex = 4
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
CloseBtn.TextSize = 22
CloseBtn.ZIndex = 4
CloseBtn.Parent = TopBar

-- Handle Resize Sudut Kanan Bawah & Tepi Panel
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Name = "ResizeGrip"
ResizeGrip.Size = UDim2.new(0, 26, 0, 26)
ResizeGrip.Position = UDim2.new(1, -26, 1, -26)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Font = Enum.Font.GothamBold
ResizeGrip.Text = "◢"
ResizeGrip.TextColor3 = Color3.fromRGB(255, 80, 80)
ResizeGrip.TextSize = 14
ResizeGrip.ZIndex = 10
ResizeGrip.Parent = MainFrame

MakeResizable(ResizeGrip, MainFrame, Vector2.new(380, 290), Vector2.new(860, 680))

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
--// BANNER PERINGATAN AUTO TANGKIS (PARRY ALERT)
--// ==========================================
local ParryAlertLabel = Instance.new("TextLabel")
ParryAlertLabel.Name = "ParryAlert"
ParryAlertLabel.Size = UDim2.new(0, 340, 0, 38)
ParryAlertLabel.Position = UDim2.new(0.5, -170, 0.14, 0)
ParryAlertLabel.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
ParryAlertLabel.BackgroundTransparency = 0.15
ParryAlertLabel.Visible = false
ParryAlertLabel.Font = Enum.Font.GothamBold
ParryAlertLabel.Text = "⚠️ KILLER MENYERANG! AUTO TANGKIS AKTIF ⚠️"
ParryAlertLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ParryAlertLabel.TextSize = 13
ParryAlertLabel.Parent = ScreenGui
Instance.new("UICorner", ParryAlertLabel).CornerRadius = UDim.new(0, 8)
local ParryStroke = Instance.new("UIStroke", ParryAlertLabel)
ParryStroke.Color = Color3.fromRGB(255, 215, 0)
ParryStroke.Thickness = 2

--// ==========================================
--// NAVIGASI 6 TAB MENU (RESPONSIF SAAT DI-RESIZE)
--// ==========================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 52)
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
    btn.Font = Enum.Font.GothamMedium
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(215, 215, 215)
    btn.TextSize = 11
    btn.TextScaled = true
    btn.ZIndex = 3
    btn.Parent = TabBar

    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 3)
    pad.PaddingRight = UDim.new(0, 3)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, -20, 1, -104)
    scrolling.Position = UDim2.new(0, 10, 0, 92)
    scrolling.BackgroundTransparency = 1
    scrolling.BorderSizePixel = 0
    scrolling.ScrollBarThickness = 4
    scrolling.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 70)
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
--// HELPER KOMPONEN UI (TOGGLE, AKSI, SLIDER)
--// ==========================================
local function CreateToggle(parentTab, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.Gotham
    btn.Text = "   " .. title
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 4
    btn.Parent = parentTab

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 90)
    stroke.Thickness = 1
    stroke.Parent = btn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 80, 1, 0)
    status.Position = UDim2.new(1, -90, 0, 0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.Text = "[ MATI ]"
    status.TextColor3 = Color3.fromRGB(160, 160, 160)
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.ZIndex = 4
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
            callback(state, status)
        end)
    end)
    return btn, status
end

local function CreateActionButton(parentTab, title, actionText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.BackgroundTransparency = 0.25
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.Gotham
    btn.Text = "   " .. title
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 4
    btn.Parent = parentTab

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 90)
    stroke.Thickness = 1
    stroke.Parent = btn

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(0, 130, 1, 0)
    tag.Position = UDim2.new(1, -140, 0, 0)
    tag.BackgroundTransparency = 1
    tag.Font = Enum.Font.GothamMedium
    tag.Text = "[ " .. actionText .. " ]"
    tag.TextColor3 = Color3.fromRGB(255, 200, 90)
    tag.TextSize = 11
    tag.TextXAlignment = Enum.TextXAlignment.Right
    tag.ZIndex = 4
    tag.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(55, 25, 30)
        task.delay(0.18, function()
            if btn and btn.Parent then
                btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
            end
        end)
        pcall(function()
            callback(tag, btn)
        end)
    end)
    return btn, tag
end

local function CreateStepperControl(parentTab, labelPrefix, initialVal, stepVal, minVal, maxVal, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 38)
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
    lbl.Font = Enum.Font.Gotham
    lbl.Text = labelPrefix .. ": " .. initialVal
    lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = frame

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 30, 0, 26)
    minus.Position = UDim2.new(1, -74, 0.5, -13)
    minus.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    minus.Font = Enum.Font.GothamBold
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    minus.TextSize = 15
    minus.ZIndex = 5
    minus.Parent = frame
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 30, 0, 26)
    plus.Position = UDim2.new(1, -38, 0.5, -13)
    plus.BackgroundColor3 = Color3.fromRGB(180, 35, 45)
    plus.Font = Enum.Font.GothamBold
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    plus.TextSize = 15
    plus.ZIndex = 5
    plus.Parent = frame
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)

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
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(12, 12, 15)
    stroke.Parent = textLabel

    task.spawn(function()
        local matteBlack = Color3.fromRGB(12, 12, 15)
        while ScriptActive and textLabel and textLabel.Parent and stroke and stroke.Parent do
            local hue = (tick() * 0.85) % 1
            local rgbColor = Color3.fromHSV(hue, 0.9, 1)
            local blinkMix = (math.sin(tick() * 7) + 1) / 2
            stroke.Color = matteBlack:Lerp(rgbColor, blinkMix)
            RunService.RenderStepped:Wait()
        end
    end)
end

--// ==========================================
--// TAB 1: VISUAL ESP (PEMAIN, KILLER, GENERATOR + %)
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
        hl.OutlineColor = Color3.fromRGB(15, 15, 18)
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
        label.Font = Enum.Font.GothamBold -- Font agak tebal
        label.TextSize = 12
        label.RichText = true
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
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

-- Fungsi Pembaca Persentase Generator (0% - 100%)
local function GetGeneratorProgress(genObj)
    local pct = nil
    pcall(function()
        -- Cek Attribute terlebih dahulu
        for _, attrName in ipairs({"Progress", "RepairProgress", "Percent", "Completion", "Charge"}) do
            local val = genObj:GetAttribute(attrName)
            if type(val) == "number" then
                pct = (val <= 1.05 and val > 0) and math.floor(val * 100) or math.floor(val)
                return
            end
        end
        -- Cek ValueObject di dalam model generator
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
                                txt.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                                                    '<font color="#FFFFFF">[GENERATOR]</font>\n<font color="#38BDF8">Proses: %d%% (%s)</font>\n<font color="#FB923C">Jarak: %dm</font>',
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
--// TAB 2: KARAKTER (NOCLIP TRANSPARAN, FLY, TELEPORT LOCK, AUTO PARRY)
--// ==========================================

-- 1. NOCLIP HALUS + TEMBOK TRANSPARAN (TANPA MENTAL / KEMBALI KE BELAKANG)
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
CreateToggle(TabKarakter, "Tembus Tembok Halus + Tembok Transparan", function(state)
    NoclipEnabled = state
    if NoclipEnabled then
        NoclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                -- Matikan tabrakan pada seluruh bagian tubuh
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                -- Deteksi dinding/objek di sekitar tubuh & buat transparan + tembus
                local overlapParams = OverlapParams.new()
                overlapParams.FilterDescendantsInstances = {char}
                overlapParams.FilterType = Enum.RaycastFilterType.Exclude

                local nearbyParts = Workspace:GetPartBoundsInRadius(root.Position, 6.5, overlapParams)
                local currentFrameWalls = {}

                for _, wall in ipairs(nearbyParts) do
                    -- Jangan hilangkan lantai tepat di bawah kaki agar tidak jatuh ke bawah map
                    if wall:IsA("BasePart") and wall.CanCollide and wall.Position.Y >= (root.Position.Y - 2.6) then
                        currentFrameWalls[wall] = true
                        ModifiedWallParts[wall] = true
                        wall.CanCollide = false
                        wall.LocalTransparencyModifier = 0.68
                    end
                end

                -- Kembalikan tembok yang sudah dilewati
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
        if NoclipConn then
            NoclipConn:Disconnect()
            NoclipConn = nil
        end
        RestoreTransparentWalls()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CanCollide = true
            end
        end)
    end
end)

-- 2. TELEPORT TOGGLE ON/OFF MENETAP DI PEMAIN LAIN
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
        tag.Text = "[ KOSONG ]"
        return
    end
    TargetIndex = (TargetIndex % #list) + 1
    SelectedTeleportTarget = list[TargetIndex]
    tag.Text = "[ " .. SelectedTeleportTarget.Name .. " ]"
end)

local TeleportLockConn = nil
CreateToggle(TabKarakter, "Teleport & Menetap di Pemain (ON/OFF)", function(state)
    TeleportLockEnabled = state
    if TeleportLockEnabled then
        -- Jika belum memilih target, otomatis pilih pemain terdekat
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

        TeleportLockConn = RunService.Heartbeat:Connect(function()
            if not TeleportLockEnabled or not ScriptActive then return end
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetChar = SelectedTeleportTarget and SelectedTeleportTarget.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                if myRoot and targetRoot then
                    myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    -- Menetap di dekat target dengan jarak aman 3.5 stud
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3.5)
                end
            end)
        end)
    else
        -- Saat di-OFF kan, tetap menetap di lokasi terakhir tanpa ditarik balik
        if TeleportLockConn then
            TeleportLockConn:Disconnect()
            TeleportLockConn = nil
        end
        pcall(function()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end)

-- 3. SMOOTH FLY HALUS (MENDUKUNG ANALOG HP & KEYBOARD)
local FlyConn = nil
local function StopFly()
    Flying = false
    if FlyConn then
        FlyConn:Disconnect()
        FlyConn = nil
    end
    pcall(function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
    end)
end

CreateToggle(TabKarakter, "Terbang Halus (Smooth Fly)", function(state)
    if state then
        Flying = true
        FlyConn = RunService.Heartbeat:Connect(function(dt)
            if not Flying or not ScriptActive then return end
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                    local cam = Camera.CFrame
                    local moveDir = Vector3.new(0, 0, 0)

                    if hum.MoveDirection.Magnitude > 0 then
                        local flatLook = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
                        local flatRight = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
                        if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
                        moveDir = (cam.LookVector * hum.MoveDirection:Dot(flatLook)) + (cam.RightVector * hum.MoveDirection:Dot(flatRight))
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                    local nextPos = root.Position + (moveDir * FlySpeed * dt)
                    root.CFrame = CFrame.lookAt(nextPos, nextPos + Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z))
                end
            end)
        end)
    else
        StopFly()
    end
end)

CreateStepperControl(TabKarakter, "Kecepatan Terbang", FlySpeed, 15, 15, 250, function(val)
    FlySpeed = val
end)

-- 4. KEBAL PUKULAN & TRANSPARAN SERANGAN
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

-- 5. AUTO MENANGKIS PUKULAN KILLER (DENGAN TANDA PERINGATAN)
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
                    if threatDetected and (tick() - LastParryTime) > 0.8 then
                        LastParryTime = tick()
                        -- Simulasi tombol tangkis / block (F / Q / Klik Kanan)
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
--// TAB 3: DISTRIK (AUTO PERFECT SKILL CHECK GEN & HEAL + ANTI HOOK)
--// ==========================================

-- SISTEM AUTO PERFECT SKILL CHECK (LINGKARAN JARUM PUTIH SEPERTI GAMBAR)
local LastSkillCheckHit = 0
local function RunSkillCheckWatcher()
    RunService.RenderStepped:Connect(function()
        if (not AutoGenPerfectEnabled and not AutoHealFastEnabled) or not ScriptActive then return end
        if (tick() - LastSkillCheckHit) < 0.35 then return end

        pcall(function()
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not pGui then return end

            for _, gui in ipairs(pGui:GetDescendants()) do
                if gui:IsA("GuiObject") and gui.Visible then
                    local gName = string.lower(gui.Name)
                    if gName:find("skillcheck") or gName:find("skill_check") or gName:find("minigame") or gName:find("qte") then
                        local needle, targetZone = nil, nil
                        for _, child in ipairs(gui:GetDescendants()) do
                            if child:IsA("GuiObject") and child.Visible then
                                local cName = string.lower(child.Name)
                                if cName:find("needle") or cName:find("jarum") or cName:find("pointer") or cName:find("arrow") or cName:find("line") then
                                    needle = child
                                elseif cName:find("target") or cName:find("perfect") or cName:find("great") or cName:find("success") or cName:find("white") or cName:find("zone") then
                                    targetZone = child
                                end
                            end
                        end

                        if needle and targetZone then
                            local nRot = needle.Rotation % 360
                            local tRot = targetZone.Rotation % 360
                            local diff = math.abs((nRot - tRot + 180) % 360 - 180)

                            -- Jika jarum masuk area putih (toleransi 16 derajat)
                            if diff <= 16 then
                                LastSkillCheckHit = tick()
                                if VirtualInputManager then
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                    task.wait(0.03)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
end
RunSkillCheckWatcher()

CreateToggle(TabDistrik, "Auto Perfect Generator (Lingkaran Jarum)", function(state)
    AutoGenPerfectEnabled = state
    if AutoGenPerfectEnabled then
        task.spawn(function()
            while AutoGenPerfectEnabled and ScriptActive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local act = string.lower(obj.ActionText .. " " .. obj.Name .. " " .. (obj.Parent and obj.Parent.Name or ""))
                                if act:find("gen") or act:find("repair") or act:find("perbaiki") then
                                    local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
                                    if part and (myRoot.Position - part.Position).Magnitude <= (obj.MaxActivationDistance + 6) then
                                        obj.HoldDuration = 0
                                        if fireproximityprompt then fireproximityprompt(obj) end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.3)
            end
        end)
    end
end)

CreateToggle(TabDistrik, "Penyembuhan Teman Cepat + Auto Perfect", function(state)
    AutoHealFastEnabled = state
    if AutoHealFastEnabled then
        task.spawn(function()
            while AutoHealFastEnabled and ScriptActive do
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local act = string.lower(obj.ActionText .. " " .. obj.Name .. " " .. (obj.Parent and obj.Parent.Name or ""))
                                if act:find("heal") or act:find("sembuh") or act:find("revive") or act:find("tolong") or act:find("rescue") then
                                    local part = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
                                    if part and (myRoot.Position - part.Position).Magnitude <= (obj.MaxActivationDistance + 6) then
                                        obj.HoldDuration = 0
                                        if fireproximityprompt then fireproximityprompt(obj) end
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
        root.CFrame = root.CFrame * CFrame.new(0, 3, -5)
    end)
    tag.Text = "[ TERLEPAS! ]"
    task.delay(1.5, function()
        if tag and tag.Parent then tag.Text = "[ LEPAS ]" end
    end)
end)

--// ==========================================
--// TAB 4: FITUR KILLER (NO DELAY, SPEED, BRUTAL HIT, AIMBOT)
--// ==========================================

-- 1. Pukulan Tanpa Delay / Anti-Stuck
CreateToggle(TabKiller, "Pukulan Tanpa Delay / Anti-Stuck", function(state)
    KillerNoDelayEnabled = state
    if KillerNoDelayEnabled then
        task.spawn(function()
            while KillerNoDelayEnabled and ScriptActive do
                pcall(function()
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and WalkSpeedEnabled then
                        hum.WalkSpeed = CustomWalkSpeed
                    elseif hum and hum.WalkSpeed < 16 then
                        hum.WalkSpeed = 16
                    end
                    -- Reset cooldown pada tool/senjata killer
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

-- 2. Pengatur Kecepatan Jalan Killer & Karakter
CreateToggle(TabKiller, "Aktifkan Kecepatan Jalan Kustom", function(state)
    WalkSpeedEnabled = state
    if WalkSpeedEnabled then
        task.spawn(function()
            while WalkSpeedEnabled and ScriptActive do
                pcall(function()
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = CustomWalkSpeed end
                end)
                task.wait(0.15)
            end
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        end)
    end
end)

CreateStepperControl(TabKiller, "Atur Kecepatan Jalan", 32, 4, 16, 150, function(val)
    CustomWalkSpeed = val
end)

-- 3. Aimbot Pukulan Killer (Otomatis Mengarah ke Pemain Terdekat)
CreateToggle(TabKiller, "Aimbot Pukulan Killer (Auto Target)", function(state)
    KillerAimbotEnabled = state
end)

-- 4. Pukulan Brutal Multi-Damage (Serangan Berkali-Kali)
CreateToggle(TabKiller, "Pukulan Brutal Multi-Damage (Spam Hit)", function(state)
    KillerBrutalHitEnabled = state
end)

-- Koneksi Aksi Ayunan Senjata Killer (Aimbot + Brutal Multi-Hit)
local function BindKillerWeapon(char)
    if not char then return end
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(function()
                if not ScriptActive then return end
                pcall(function()
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    -- Cari pemain terdekat dalam jangkauan 18 stud
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

                    -- Aimbot Pukulan: Arahkan karakter tepat ke target
                    if KillerAimbotEnabled and nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                        local tPos = nearestTarget.HumanoidRootPart.Position
                        myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(tPos.X, myRoot.Position.Y, tPos.Z))
                    end

                    -- Pukulan Brutal: Kirim sentuhan damage berkali-kali
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
    tag.Text = "[ BERHENTI ]"
    task.delay(1.2, function()
        if tag and tag.Parent then tag.Text = "[ STOP ]" end
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
        tag.Text = "[ JOGET! ]"
        task.delay(1.5, function()
            if tag and tag.Parent then tag.Text = "[ MULAI ]" end
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
    header.TextColor3 = Color3.fromRGB(255, 85, 85)
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.ZIndex = 4
    header.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -24, 0, 34)
    desc.Position = UDim2.new(0, 12, 0, 26)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.Text = bodyText
    desc.TextColor3 = Color3.fromRGB(230, 230, 230)
    desc.TextSize = 11
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.ZIndex = 4
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
        copyBtn.ZIndex = 5
        copyBtn.Parent = card
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

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
    WalkSpeedEnabled = false
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

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        ClearPlayerESP(p)
    end
    ClearAllGenESP()

    ScreenGui:Destroy()
end)

print("BimSakSin Hub v3.0 (Edisi Lengkap & Bebas Bug) Berhasil Dimuat!")
