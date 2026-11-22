--[[
    ╔══════════════════════════════════════════════════════════╗
    ║  BimSakSin Hub                                            ║
    ║  Delta Executor Compatible                                ║
    ║  Features: ESP, Fly, Speed, Jump, Noclip, Gen Tracker,    ║
    ║            Auto TP, Region IP, Anti Lag, Team ESP         ║
    ╚══════════════════════════════════════════════════════════╝
--]]

--============================================================
-- SERVICES
--============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local WorkspaceService  = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local CoreGui           = game:GetService("CoreGui")
local Camera            = WorkspaceService.CurrentCamera

local CLIENT = Players.LocalPlayer
local PGUI = (gethui and gethui()) or CoreGui

--============================================================
-- CLEANUP
--============================================================
if PGUI:FindFirstChild("BimSakSinHub") then
    PGUI.BimSakSinHub:Destroy()
end

--============================================================
-- FLAGS / STATE
--============================================================
local State = {
    ESP           = false,
    TeamESP       = true,
    Tracer        = true,
    ShowDistance  = true,
    Fly           = false,
    FlySpeed      = 55,
    WalkSpeed     = 22,
    JumpPower     = 55,
    Noclip        = false,
    AntiLag       = false,
    AutoTP        = false,
    ViewPlayer    = nil,
    ShowGenerators= true,
    ESPFont       = Enum.Font.GothamBold,
    BlackColor    = Color3.fromRGB(0,0,0),
    TeamColors    = {},
    TweenMap      = {},
}

local FlyConnection, NoclipConnection, SpeedConn, JumpConn
local FlyBodyGyro, FlyBodyVel

--============================================================
-- TEAM COLOR
--============================================================
local function GetPlayerColor(plr)
    if plr == CLIENT then return Color3.fromRGB(80, 200, 255) end
    pcall(function()
        if plr.Team and plr.TeamColor then
            return plr.Team.TeamColor.Color
        end
    end)
    return Color3.fromRGB(255, 90, 90)
end

--============================================================
-- LOGO TENGKORAK 3D (SVG-ish via Frame)
--============================================================
local function CreateSkullLogo(parent, size)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(size, size)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = parent

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.fromScale(1,1)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://7280140048"
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = 0.45
    shadow.Position = UDim2.fromOffset(2,3)
    shadow.Parent = holder

    local skull = Instance.new("ImageLabel")
    skull.Size = UDim2.fromScale(1,1)
    skull.BackgroundTransparency = 1
    skull.Image = "rbxassetid://7280140048"
    skull.ImageColor3 = Color3.fromRGB(235,235,235)
    skull.Parent = holder

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.fromScale(1.35,1.35)
    glow.Position = UDim2.fromScale(-0.175,-0.175)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://7280140048"
    glow.ImageColor3 = Color3.fromRGB(160,220,255)
    glow.ImageTransparency = 0.75
    glow.Parent = holder

    -- rotation animation
    task.spawn(function()
        local rot = 0
        local pulse = 0
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            if not holder.Parent then conn:Disconnect() return end
            rot += dt * 8
            pulse += dt * 3
            local scale = 1 + math.sin(pulse) * 0.06
            glow.Size = UDim2.fromScale(1.35 * scale, 1.35 * scale)
            glow.Position = UDim2.fromScale(-0.175 - (scale-1)*0.175, -0.175 - (scale-1)*0.175)
            holder.Rotation = math.sin(rot * math.pi/180) * 4
        end)
    end)

    return holder
end

--============================================================
-- BLUE CHECK 3D (animated)
--============================================================
local function CreateBlueCheck(parent, size)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(size, size)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = parent

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.fromScale(1,1)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://11023429806"
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = 0.4
    shadow.Position = UDim2.fromOffset(1,2)
    shadow.Parent = holder

    local badge = Instance.new("ImageLabel")
    badge.Size = UDim2.fromScale(1,1)
    badge.BackgroundTransparency = 1
    badge.Image = "rbxassetid://11023429806"
    badge.ImageColor3 = Color3.fromRGB(60,160,255)
    badge.Parent = holder

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.fromScale(1.6,1.6)
    glow.Position = UDim2.fromScale(-0.3,-0.3)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://11023429806"
    glow.ImageColor3 = Color3.fromRGB(80,180,255)
    glow.ImageTransparency = 0.7
    glow.Parent = holder

    -- pulse + slight bob
    task.spawn(function()
        local t = 0
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            if not holder.Parent then conn:Disconnect() return end
            t += dt
            local s = 1 + math.sin(t*3) * 0.08
            glow.Size = UDim2.fromScale(1.6*s, 1.6*s)
            glow.Position = UDim2.fromScale(-0.3 - (s-1)*0.3, -0.3 - (s-1)*0.3)
            badge.Position = UDim2.fromOffset(0, math.sin(t*4)*1.2)
            holder.Rotation = math.sin(t*2) * 6
        end)
    end)

    return holder
end

--============================================================
-- ROOT GUI
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PGUI

-- Floating toggle (skull)
local FloatToggle = Instance.new("TextButton")
FloatToggle.Name = "FloatToggle"
FloatToggle.Size = UDim2.fromOffset(58,58)
FloatToggle.Position = UDim2.new(0, 24, 0.5, -29)
FloatToggle.BackgroundColor3 = Color3.fromRGB(20,20,28)
FloatToggle.BackgroundTransparency = 0.15
FloatToggle.BorderSizePixel = 0
FloatToggle.Text = ""
FloatToggle.AutoButtonColor = false
FloatToggle.Parent = ScreenGui

local FTLayout = Instance.new("UICorner")
FTLayout.CornerRadius = UDim.new(1,0)
FTLayout.Parent = FloatToggle

local FTStroke = Instance.new("UIStroke")
FTStroke.Color = Color3.fromRGB(80,180,255)
FTStroke.Thickness = 1.6
FTStroke.Transparency = 0.15
FTStroke.Parent = FloatToggle

local FTGradient = Instance.new("UIGradient")
FTGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30,60,120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,15,30)),
}
FTGradient.Rotation = 45
FTGradient.Parent = FloatToggle

local skullWrapper = Instance.new("Frame")
skullWrapper.Size = UDim2.fromScale(0.65,0.65)
skullWrapper.Position = UDim2.fromScale(0.175,0.175)
skullWrapper.BackgroundTransparency = 1
skullWrapper.Parent = FloatToggle
CreateSkullLogo(skullWrapper, 34)

FloatToggle.MouseEnter:Connect(function()
    TweenService:Create(FloatToggle, TweenInfo.new(0.2), {Size = UDim2.fromOffset(64,64)}):Play()
end)
FloatToggle.MouseLeave:Connect(function()
    TweenService:Create(FloatToggle, TweenInfo.new(0.2), {Size = UDim2.fromOffset(58,58)}):Play()
end)

-- Drag toggle
local dragging, dragStart, startPos
FloatToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatToggle.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        FloatToggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--============================================================
-- MAIN PANEL (transparent white glassy web-style)
--============================================================
local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.fromOffset(560, 420)
Main.Position = UDim2.new(0.5, -280, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(255,255,255)
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

-- glassy gradient background (white)
local MainBG = Instance.new("Frame")
MainBG.Size = UDim2.fromScale(1,1)
MainBG.BackgroundColor3 = Color3.fromRGB(255,255,255)
MainBG.BackgroundTransparency = 0.18
MainBG.BorderSizePixel = 0
MainBG.ZIndex = 1
MainBG.Parent = Main
Instance.new("UICorner", MainBG).CornerRadius = UDim.new(0,16)

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235,242,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
}
bgGradient.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.15),
    NumberSequenceKeypoint.new(1, 0.35),
}
bgGradient.Parent = MainBG

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255,255,255)
MainStroke.Thickness = 1.4
MainStroke.Transparency = 0.15
MainStroke.Parent = Main

-- 4 corner decorative skulls 3D
local function makeCornerSkull(posUDim, anchor)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(34,34)
    holder.Position = posUDim
    holder.AnchorPoint = anchor
    holder.BackgroundTransparency = 1
    holder.ZIndex = 5
    holder.Parent = Main
    CreateSkullLogo(holder, 34)
end
makeCornerSkull(UDim2.fromOffset(12,12), Vector2.new(0,0))
makeCornerSkull(UDim2.new(1,-12,0,12), Vector2.new(1,0))
makeCornerSkull(UDim2.new(0,12,1,-12), Vector2.new(0,1))
makeCornerSkull(UDim2.new(1,-12,1,-12), Vector2.new(1,1))

-- header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,64)
Header.BackgroundTransparency = 1
Header.ZIndex = 4
Header.Parent = Main

local HeaderTitle = Instance.new("Frame")
HeaderTitle.Size = UDim2.fromOffset(230,64)
HeaderTitle.Position = UDim2.fromOffset(24,0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.ZIndex = 5
HeaderTitle.Parent = Header

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1,-34,1,0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "BimSakSin Hub"
TitleText.TextColor3 = Color3.fromRGB(20,30,50)
TitleText.Font = Enum.Font.GothamBlack
TitleText.TextSize = 22
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 5
TitleText.Parent = HeaderTitle
local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30,90,180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5,20,60)),
}
TitleGradient.Parent = TitleText

local blueCheckHolder = Instance.new("Frame")
blueCheckHolder.Size = UDim2.fromOffset(26,26)
blueCheckHolder.Position = UDim2.new(1, -30, 0.5, -13)
blueCheckHolder.BackgroundTransparency = 1
blueCheckHolder.ZIndex = 6
blueCheckHolder.Parent = HeaderTitle
CreateBlueCheck(blueCheckHolder, 26)

-- close btn
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(30,30)
CloseBtn.Position = UDim2.new(1,-46,0,17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255,90,90)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 16
CloseBtn.ZIndex = 6
CloseBtn.Parent = Main
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1,0)
CloseBtn.MouseButton1Click:Connect(function()
    local t = TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0,0), Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 1
    })
    t:Play()
    t.Completed:Wait()
    Main.Visible = false
    Main.Size = UDim2.fromOffset(560,420)
    Main.Position = UDim2.new(0.5,-280,0.5,-210)
end)

-- drag main
local draggingMain, dragStartMain, startPosMain
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStartMain
        Main.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + d.X, startPosMain.Y.Scale, startPosMain.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        draggingMain = false
    end
end)

--============================================================
-- TABS
--============================================================
local TabsBar = Instance.new("Frame")
TabsBar.Size = UDim2.new(1,-48,0,36)
TabsBar.Position = UDim2.fromOffset(24, 68)
TabsBar.BackgroundTransparency = 1
TabsBar.ZIndex = 4
TabsBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0,8)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabsBar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1,-48,1,-128)
ContentArea.Position = UDim2.fromOffset(24, 108)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 4
ContentArea.Parent = Main

local function MakeScroll()
    local scroller = Instance.new("ScrollingFrame")
    scroller.Size = UDim2.fromScale(1,1)
    scroller.BackgroundTransparency = 1
    scroller.BorderSizePixel = 0
    scroller.ScrollBarThickness = 3
    scroller.ScrollBarImageColor3 = Color3.fromRGB(80,140,220)
    scroller.Visible = false
    scroller.CanvasSize = UDim2.new()
    scroller.ZIndex = 4
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0,6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroller
    scroller.Parent = ContentArea
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroller.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y + 8)
    end)
    return scroller
end

local Scrolls = {
    Player = MakeScroll(),
    World  = MakeScroll(),
    Misc   = MakeScroll(),
}

local function MakeTabButton(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(90,32)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 0.4
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(20,30,50)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.ZIndex = 5
    btn.Parent = TabsBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    return btn
end

local ActiveTab = nil
local function SelectTab(name)
    for k, s in pairs(Scrolls) do
        s.Visible = (k == name)
    end
    ActiveTab = name
end

local tabButtons = {
    MakeTabButton("Player", 1),
    MakeTabButton("World", 2),
    MakeTabButton("Misc", 3),
}

tabButtons[1].MouseButton1Click:Connect(function() SelectTab("Player") end)
tabButtons[2].MouseButton1Click:Connect(function() SelectTab("World") end)
tabButtons[3].MouseButton1Click:Connect(function() SelectTab("Misc") end)
SelectTab("Player")

--============================================================
-- COMPONENTS
--============================================================
local function MakeLabel(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Text = "› "..text
    lbl.TextColor3 = Color3.fromRGB(60,70,90)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.ZIndex = 5
    lbl.Parent = parent
    return lbl
end

local function MakeToggle(parent, name, order, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 0.35
    btn.Text = ""
    btn.LayoutOrder = order
    btn.ZIndex = 5
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150,180,220)
    stroke.Transparency = 0.5
    stroke.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0)
    lbl.Position = UDim2.fromOffset(12,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(20,30,50)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    lbl.Parent = btn

    local knobBg = Instance.new("Frame")
    knobBg.Size = UDim2.fromOffset(40,20)
    knobBg.Position = UDim2.new(1,-52,0.5,-10)
    knobBg.BackgroundColor3 = Color3.fromRGB(190,200,215)
    knobBg.ZIndex = 5
    knobBg.Parent = btn
    Instance.new("UICorner", knobBg).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16,16)
    knob.Position = UDim2.fromOffset(2,2)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.ZIndex = 6
    knob.Parent = knobBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local on = default or false
    local function setState(v)
        on = v
        TweenService:Create(knobBg, TweenInfo.new(0.18), {BackgroundColor3 = v and Color3.fromRGB(70,150,255) or Color3.fromRGB(190,200,215)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {Position = v and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2)}):Play()
        if callback then pcall(callback, v) end
    end
    if on then setState(true) end

    btn.MouseButton1Click:Connect(function() setState(not on) end)
    return {Toggle = btn, Set = setState}
end

local function MakeSlider(parent, name, order, min, max, def, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,44)
    holder.BackgroundColor3 = Color3.fromRGB(255,255,255)
    holder.BackgroundTransparency = 0.35
    holder.LayoutOrder = order
    holder.ZIndex = 5
    holder.Parent = parent
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-20,0,20)
    lbl.Position = UDim2.fromOffset(12,2)
    lbl.BackgroundTransparency = 1
    lbl.Text = name..": "..tostring(def)
    lbl.TextColor3 = Color3.fromRGB(20,30,50)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    lbl.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-24,0,6)
    bar.Position = UDim2.new(0,12,1,-14)
    bar.BackgroundColor3 = Color3.fromRGB(210,220,235)
    bar.ZIndex = 5
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(70,150,255)
    fill.ZIndex = 6
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local dragging = false
    local function setVal(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max-min) * alpha)
        fill.Size = UDim2.new(alpha,0,1,0)
        lbl.Text = name..": "..tostring(v)
        if callback then pcall(callback, v) end
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setVal(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setVal(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function MakeButton(parent, name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = Color3.fromRGB(70,150,255)
    btn.BackgroundTransparency = 0.1
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.LayoutOrder = order
    btn.ZIndex = 5
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return btn
end

local function MakeInfo(parent, name, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,28)
    holder.BackgroundColor3 = Color3.fromRGB(255,255,255)
    holder.BackgroundTransparency = 0.4
    holder.LayoutOrder = order
    holder.ZIndex = 5
    holder.Parent = parent
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-20,1,0)
    lbl.Position = UDim2.fromOffset(10,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(30,40,60)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    lbl.Parent = holder
    return lbl
end

--============================================================
-- PLAYER TAB
--============================================================
MakeLabel(Scrolls.Player, "Visual", 1)
MakeToggle(Scrolls.Player, "ESP Players", 2, false, function(v) State.ESP = v end)
MakeToggle(Scrolls.Player, "ESP Team Color", 3, true, function(v) State.TeamESP = v end)
MakeToggle(Scrolls.Player, "ESP Tracer", 4, true, function(v) State.Tracer = v end)
MakeToggle(Scrolls.Player, "Show Distance", 5, true, function(v) State.ShowDistance = v end)
MakeButton(Scrolls.Player, "View Local Player Camera", 6, function()
    Camera.CameraSubject = CLIENT.Character and CLIENT.Character:FindFirstChild("Humanoid")
    State.ViewPlayer = nil
end)

local function StopFly()
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end
    if FlyBodyVel then FlyBodyVel:Destroy(); FlyBodyVel = nil end
    local char = CLIENT.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

local function StartFly()
    StopFly()
    local char = CLIENT.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
    FlyBodyGyro.CFrame = hrp.CFrame
    FlyBodyGyro.Parent = hrp
    FlyBodyVel = Instance.new("BodyVelocity")
    FlyBodyVel.Velocity = Vector3.new(0,0,0)
    FlyBodyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
    FlyBodyVel.Parent = hrp
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not State.Fly or not hrp.Parent or not hum.Parent then return end
        local direction = Vector3.zero
        local camCF = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0,1,0) end
        if direction.Magnitude > 0.001 then
            FlyBodyVel.Velocity = direction.Unit * State.FlySpeed
            FlyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + direction.Unit)
        else
            FlyBodyVel.Velocity = Vector3.zero
        end
    end)
end

MakeLabel(Scrolls.Player, "Movement", 7)
MakeToggle(Scrolls.Player, "Fly", 8, false, function(v)
    State.Fly = v
    if v then
        StartFly()
    else
        StopFly()
    end
end)

MakeSlider(Scrolls.Player, "Fly Speed", 9, 10, 250, 55, function(v) State.FlySpeed = v end)
MakeSlider(Scrolls.Player, "WalkSpeed", 10, 16, 300, 22, function(v)
    State.WalkSpeed = v
    local hum = CLIENT.Character and CLIENT.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
MakeSlider(Scrolls.Player, "JumpPower", 11, 50, 500, 55, function(v)
    State.JumpPower = v
    local hum = CLIENT.Character and CLIENT.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v; hum.UseJumpPower = true end
end)
MakeToggle(Scrolls.Player, "Noclip", 12, false, function(v)
    State.Noclip = v
    if v then
        if NoclipConnection then NoclipConnection:Disconnect() end
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = CLIENT.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    end
end)

MakeLabel(Scrolls.Player, "Teleport", 13)
local tpTarget = nil
local tpLabel = MakeInfo(Scrolls.Player, "Selected: (none)", 14)
MakeButton(Scrolls.Player, "Auto Teleport (follow selected)", 15, function()
    State.AutoTP = not State.AutoTP
    StarterGui:SetCore("SendNotification", {Title="BimSakSin Hub", Text="Auto TP: "..tostring(State.AutoTP), Duration=2})
end)
MakeButton(Scrolls.Player, "Refresh Player List", 16, function()
    for _, child in ipairs(Scrolls.Player:GetChildren()) do
        if child:IsA("TextButton") and child.Name:sub(1,4) == "TPL_" then child:Destroy() end
    end
    local idx = 100
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= CLIENT then
            local b = MakeButton(Scrolls.Player, "→ "..plr.Name, idx, function()
                tpTarget = plr
                tpLabel.Text = "Selected: "..plr.Name
                if plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and CLIENT.Character then
                        CLIENT.Character:PivotTo(hrp.CFrame + Vector3.new(2,0,2))
                    end
                end
            end)
            b.Name = "TPL_"..plr.Name
            idx += 1
        end
    end
end)

MakeButton(Scrolls.Player, "View Player (dropdown-lite)", 17, function()
    local list = Players:GetPlayers()
    local names = {}
    for _, p in ipairs(list) do
        if p ~= CLIENT then table.insert(names, p.Name) end
    end
    if #names == 0 then return end
    -- cycle view
    local current = State.ViewPlayer
    local idx = 1
    if current then
        for i, p in ipairs(list) do
            if p == current then idx = i + 1 break end
        end
    end
    for i = idx, #list + idx - 1 do
        local p = list[((i-1) % #list) + 1]
        if p ~= CLIENT and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum then
                State.ViewPlayer = p
                Camera.CameraSubject = hum
                StarterGui:SetCore("SendNotification", {Title="BimSakSin Hub", Text="Viewing: "..p.Name, Duration=2})
                break
            end
        end
    end
end)

--============================================================
-- WORLD TAB
--============================================================
local genListLabel = MakeInfo(Scrolls.World, "Generators: scanning...", 1)
local genProgressLabel = MakeInfo(Scrolls.World, "Progress: -", 2)

MakeToggle(Scrolls.World, "ESP Generators", 3, true, function(v) State.ShowGenerators = v end)
MakeToggle(Scrolls.World, "Anti Lag (map)", 4, false, function(v)
    State.AntiLag = v
    if v then
        pcall(function()
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("PostEffect") then obj.Enabled = false end
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 350
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            for _, p in ipairs(WorkspaceService:GetDescendants()) do
                if p:IsA("ParticleEmitter") then p.Enabled = false end
                if p:IsA("BasePart") and p.Material == Enum.Material.Neon then p.Material = Enum.Material.Plastic end
            end
        end)
    else
        pcall(function()
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("PostEffect") then obj.Enabled = true end
            end
            Lighting.GlobalShadows = true
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level07
        end)
    end
end)

MakeLabel(Scrolls.World, "Regions / Info", 5)
local infoMy = MakeInfo(Scrolls.World, "My Region: scanning...", 6)
local infoFP = MakeInfo(Scrolls.World, "Players (region): -", 7)

local function FetchRegion()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://ipapi.co/json/"))
    end)
    if ok and type(data) == "table" then
        infoMy.Text = "My Region: "..tostring(data.city or "?")..", "..tostring(data.country_name or "?").." ["..tostring(data.ip or "?").."]"
    else
        infoMy.Text = "My Region: failed"
    end
    local txt = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local ping = "-"
        pcall(function() ping = math.floor(p:GetNetworkPing()*1000).."ms" end)
        table.insert(txt, p.Name.." ("..ping..")")
    end
    infoFP.Text = "Players: "..table.concat(txt, ", ")
end
task.spawn(FetchRegion)
task.delay(2, FetchRegion)

--============================================================
-- MISC TAB
--============================================================
MakeLabel(Scrolls.Misc, "Utility", 1)
MakeButton(Scrolls.Misc, "Anti AFK", 2, function()
    CLIENT.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new())
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new())
    end)
    StarterGui:SetCore("SendNotification", {Title="BimSakSin Hub", Text="Anti AFK ON", Duration=2})
end)

MakeButton(Scrolls.Misc, "FullBright", 3, function()
    Lighting.Ambient = Color3.fromRGB(200,200,200)
    Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    Lighting.Brightness = 3
    StarterGui:SetCore("SendNotification", {Title="BimSakSin Hub", Text="FullBright ON", Duration=2})
end)

MakeButton(Scrolls.Misc, "Reset Character", 4, function()
    if CLIENT.Character then
        CLIENT.Character:BreakJoints()
    end
end)

MakeButton(Scrolls.Misc, "Rejoin Server", 5, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, CLIENT)
end)

MakeButton(Scrolls.Misc, "Destroy Hub", 6, function()
    StopFly()
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    ScreenGui:Destroy()
end)

MakeInfo(Scrolls.Misc, "BimSakSin Hub | Delta Ready", 7)

--============================================================
-- OPEN / CLOSE with animation
--============================================================
local opening = false
local function OpenPanel()
    if opening then return end
    opening = true
    Main.Visible = true
    Main.Size = UDim2.fromOffset(0,0)
    Main.Position = UDim2.new(0.5,0,0.5,0)
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(560,420),
        Position = UDim2.new(0.5,-280,0.5,-210),
    }):Play()
    task.wait(0.35)
    opening = false
end

local function ClosePanel()
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0,0),
        Position = UDim2.new(0.5,0,0.5,0),
    }):Play()
    task.delay(0.25, function() Main.Visible = false end)
end

FloatToggle.MouseButton1Click:Connect(function()
    if Main.Visible then ClosePanel() else OpenPanel() end
end)

-- initial pulse for toggle
task.spawn(function()
    for _ = 1, 3 do
        TweenService:Create(FTStroke, TweenInfo.new(0.4), {Transparency = 0.7}):Play()
        task.wait(0.5)
        TweenService:Create(FTStroke, TweenInfo.new(0.4), {Transparency = 0.15}):Play()
        task.wait(0.5)
    end
end)

--============================================================
-- ESP (Players) - billboard, bold font with black stroke background ONLY on the font
--============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "BimSakSin_ESP"
ESPFolder.Parent = WorkspaceService
local DRAWINGS = {}

local function ClearPlayerESP(plr)
    if DRAWINGS[plr] then
        for _, c in pairs(DRAWINGS[plr]) do
            if typeof(c) == "Instance" then c:Destroy()
            elseif typeof(c) == "table" and c.Remove then pcall(function() c:Remove() end)
            elseif typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        end
        DRAWINGS[plr] = nil
    end
end

local function ApplyPlayerESP(plr)
    ClearPlayerESP(plr)
    if plr == CLIENT then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BimSakSin_ESP_"..plr.Name
    billboard.Size = UDim2.fromOffset(220, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 5000
    billboard.Parent = head or hrp

    local isFriend = false
    if plr.Team and CLIENT.Team and plr.Team == CLIENT.Team then isFriend = true end
    local prefix = isFriend and "[ALLY] " or "[ENEMY] "

    -- Name (bold, thick, black stroke = "latar belakang" on font only)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,0,0,22)
    label.Position = UDim2.fromOffset(0,0)
    label.Font = State.ESPFont
    label.TextSize = 15
    label.TextColor3 = State.TeamESP and GetPlayerColor(plr) or Color3.fromRGB(255,255,255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    label.Text = prefix..plr.Name
    label.Parent = billboard

    -- Distance
    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1,0,0,18)
    distLabel.Position = UDim2.fromOffset(0,22)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 12
    distLabel.TextColor3 = Color3.fromRGB(230,240,255)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    distLabel.Text = ""
    distLabel.Visible = State.ShowDistance
    distLabel.Parent = billboard

    -- Tracer line (built-in Drawing if available)
    local tracer
    if Drawing and Drawing.new then
        local ok, tr = pcall(function() return Drawing.new("Line") end)
        if ok and tr then
            tracer = tr
            tracer.Thickness = 1.5
            tracer.Color = GetPlayerColor(plr)
            tracer.Transparency = 1
        end
    end

    local conns = {}
    table.insert(conns, RunService.RenderStepped:Connect(function()
        if not billboard.Parent then return end
        local myChar = CLIENT.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP and hrp.Parent then
            local dist = (myHRP.Position - hrp.Position).Magnitude
            distLabel.Text = "["..math.floor(dist).."m]"
            distLabel.Visible = State.ShowDistance and State.ESP
            local friendNow = (plr.Team and CLIENT.Team and plr.Team == CLIENT.Team) and true or false
            label.Text = (friendNow and "[ALLY] " or "[ENEMY] ")..plr.Name
            label.TextColor3 = State.TeamESP and GetPlayerColor(plr) or Color3.fromRGB(255,255,255)
            if tracer then
                local wp = Camera:WorldToViewportPoint(hrp.Position)
                if wp.Z > 0 and State.ESP and State.Tracer then
                    tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(wp.X, wp.Y)
                    tracer.Visible = true
                    tracer.Color = State.TeamESP and GetPlayerColor(plr) or Color3.fromRGB(255,255,255)
                else
                    tracer.Visible = false
                end
            end
            billboard.Enabled = State.ESP
        elseif tracer then
            tracer.Visible = false
        end
    end))

    DRAWINGS[plr] = {billboard, tracer}
    for _, c in ipairs(conns) do table.insert(DRAWINGS[plr], c) end
end

local function RefreshAllESP()
    for _, p in ipairs(Players:GetPlayers()) do ApplyPlayerESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1) ApplyPlayerESP(p) end)
end)
Players.PlayerRemoving:Connect(function(p) ClearPlayerESP(p) end)

for _, p in ipairs(Players:GetPlayers()) do
    ApplyPlayerESP(p)
end

--============================================================
-- GENERATOR TRACKER (ESP + progress)
--============================================================
local GENFolder = Instance.new("Folder")
GENFolder.Name = "BimSakSin_Generators"
GENFolder.Parent = WorkspaceService
local GEN_GUIS = {}

local function IsLikelyGenerator(obj)
    if not obj:IsA("Model") and not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    return n:find("generator") or n:find("gen") or n:find("fuse") or n:find("repair") or n:find("engine") or n:find("task")
end

local function GetGeneratorProgress(obj)
    local cand = obj
    while cand and cand ~= WorkspaceService do
        for _, attrName in ipairs({"Progress","progress","Percent","percent","Completed","completed","Value","value"}) do
            local v = cand:GetAttribute(attrName)
            if typeof(v) == "number" then
                if v <= 1 then return math.floor(v*100) end
                return math.clamp(math.floor(v), 0, 100)
            end
        end
        for _, ch in ipairs(cand:GetChildren()) do
            if ch:IsA("NumberValue") or ch:IsA("IntValue") then
                local n = ch.Name:lower()
                if n:find("progress") or n:find("percent") or n:find("complete") or n:find("value") then
                    local v = ch.Value
                    if v <= 1 then return math.floor(v*100) end
                    return math.clamp(math.floor(v),0,100)
                end
            end
        end
        cand = cand.Parent
    end
    return nil
end

local function AttachGenESP(gen)
    if GEN_GUIS[gen] then return end
    local base = gen:IsA("BasePart") and gen or gen:FindFirstChildWhichIsA("BasePart", true)
    if not base then return end

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(200, 44)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 5000
    bb.Name = "GenESP"
    bb.Parent = base

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1,0,0,20)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = Color3.fromRGB(120,220,255)
    nameLbl.TextStrokeTransparency = 0
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    nameLbl.Text = gen.Name
    nameLbl.Parent = bb

    local progLbl = Instance.new("TextLabel")
    progLbl.BackgroundTransparency = 1
    progLbl.Size = UDim2.new(1,0,0,18)
    progLbl.Position = UDim2.fromOffset(0,20)
    progLbl.Font = Enum.Font.GothamBold
    progLbl.TextSize = 12
    progLbl.TextColor3 = Color3.fromRGB(255,255,255)
    progLbl.TextStrokeTransparency = 0
    progLbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    progLbl.Text = "…"
    progLbl.Parent = bb

    GEN_GUIS[gen] = bb

    task.spawn(function()
        while GEN_GUIS[gen] and bb.Parent do
            local prog = GetGeneratorProgress(gen)
            if prog then
                progLbl.Text = "Progress: "..prog.."%"
                progLbl.TextColor3 = prog >= 100 and Color3.fromRGB(120,255,140) or Color3.fromRGB(255,220,120)
            else
                progLbl.Text = "Status: idle / unknown"
                progLbl.TextColor3 = Color3.fromRGB(200,200,200)
            end
            bb.Enabled = State.ShowGenerators
            task.wait(0.5)
        end
        if GEN_GUIS[gen] then GEN_GUIS[gen] = nil end
    end)
end

local function ScanGenerators()
    for _, obj in ipairs(WorkspaceService:GetDescendants()) do
        if IsLikelyGenerator(obj) and not GEN_GUIS[obj] then
            AttachGenESP(obj)
        end
    end
end

task.spawn(function()
    while ScreenGui.Parent do
        ScanGenerators()
        local count = 0
        for _ in pairs(GEN_GUIS) do count += 1 end
        genListLabel.Text = "Generators found: "..count
        local done, total = 0, 0
        for gen in pairs(GEN_GUIS) do
            total += 1
            local p = GetGeneratorProgress(gen)
            if p and p >= 100 then done += 1 end
        end
        genProgressLabel.Text = "Completed: "..done.." / "..total
        task.wait(1.2)
    end
end)

--============================================================
-- MAIN LOOPS
--============================================================
-- Auto teleport / follow selected
RunService.Heartbeat:Connect(function()
    if State.AutoTP and tpTarget and tpTarget.Parent then
        local tChar = tpTarget.Character
        local mChar = CLIENT.Character
        if tChar and mChar then
            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
            local mHRP = mChar:FindFirstChild("HumanoidRootPart")
            if tHRP and mHRP then
                mHRP.CFrame = tHRP.CFrame + Vector3.new(3,1,3)
            end
        end
    end
end)

-- WalkSpeed & JumpPower auto-apply
RunService.Heartbeat:Connect(function()
    local char = CLIENT.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if hum.WalkSpeed ~= State.WalkSpeed then hum.WalkSpeed = State.WalkSpeed end
            if hum.JumpPower ~= State.JumpPower then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
    end
end)

-- ESP refresh loop (apply to any player missing gui)
RunService.Heartbeat:Connect(function()
    if not State.ESP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= CLIENT and not DRAWINGS[plr] then
            ApplyPlayerESP(plr)
        end
    end
end)

--============================================================
-- CHARACTER RESPAWN HOOK
--============================================================
CLIENT.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = State.JumpPower
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= CLIENT then ApplyPlayerESP(plr) end
    end
    if State.Fly then
        StartFly()
    end
end)

--============================================================
-- BIND: toggle panel with RightCtrl
--============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if Main.Visible then ClosePanel() else OpenPanel() end
    end
end)

--============================================================
-- STARTUP NOTIFICATION
--============================================================
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "BimSakSin Hub",
        Text = "Loaded successfully. Press RightCtrl to open panel.",
        Icon = "rbxassetid://7280140048",
        Duration = 4,
    })
end)

-- Open panel once at start
task.wait(0.3)
OpenPanel()

print("[BimSakSin Hub] Loaded.")
