--[[
    BimSakSin Hub v3.0
    Delta Executor | Map: District
    Fitur: ESP Player/Killer/Generator, Fly, Speed, Noclip, TP All,
           Auto Perfect Generator, Auto Heal, Auto Hit/Kill Aura,
           Fullbright, Dance 999, Anti-Ban/Detect, dll.
--]]

--=========================================================
-- SERVICES & STATE
--=========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local StarterGui       = game:GetService("StarterGui")
local Camera           = Workspace.CurrentCamera

local LP = Players.LocalPlayer
local Char, HRP, Hum

local State = {
    ESP_Player = false,
    ESP_Killer = false,
    ESP_Gen    = false,
    Fly        = false,
    Speed      = false,
    Noclip     = false,
    Fullbright = false,
    AutoGen    = false,
    AutoHeal   = false,
    AutoHit    = false,
    KillAura   = false,
    AntiBan    = true,
}
local SpeedValue = 60
local FlySpeed   = 90

local function refreshChar()
    Char = LP.Character or LP.CharacterAdded:Wait()
    HRP  = Char:WaitForChild("HumanoidRootPart")
    Hum  = Char:WaitForChild("Humanoid")
end
refreshChar()
LP.CharacterAdded:Connect(refreshChar)

--=========================================================
-- ANTI DETECT / BAN
--=========================================================
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(nil) end
end)
local function safeConnect(sig, fn)
    local ok, c = pcall(function() return sig:Connect(fn) end)
    if ok then return c end
end
local function notify(t, txt)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=txt, Duration=3})
    end)
end

--=========================================================
-- CLEANUP OLD GUI
--=========================================================
pcall(function()
    local old = CoreGui:FindFirstChild("BimSakSinHub")
    if old then old:Destroy() end
end)

--=========================================================
-- THEME
--=========================================================
local Theme = {
    Bg      = Color3.fromRGB(20, 18, 30),
    Accent  = Color3.fromRGB(255, 105, 180),
    Accent2 = Color3.fromRGB(255, 255, 255),
    Text    = Color3.fromRGB(240, 240, 240),
    Sub     = Color3.fromRGB(160, 160, 175),
    Off     = Color3.fromRGB(50, 50, 65),
    On      = Color3.fromRGB(255, 105, 180),
    Stroke  = Color3.fromRGB(255, 105, 180),
}

--=========================================================
-- MAIN GUI
--=========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

-- Draggable base
local function makeDraggable(frame, handle)
    local drag, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = i.Position
            startPos = frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--=========================================================
-- MAIN PANEL
--=========================================================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 360, 0, 460)
Main.Position = UDim2.new(0.5, -180, 0.5, -230)
Main.BackgroundColor3 = Theme.Bg
Main.BackgroundTransparency = 0.15
Main.BorderSizePixel = 0
Main.Visible = true
Main.Parent = ScreenGui
Main.ClipsDescendants = true

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Stroke
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Theme.Bg
Header.BackgroundTransparency = 0.35
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

-- RGB Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BimSakSin Hub v3.0"
Title.Font = Enum.Font.GothamMedium
Title.TextSize = 17
Title.TextColor3 = Color3.new(1,1,1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local grad = Instance.new("UIGradient", Title)
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255,150,200)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,105,180)),
})
grad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 0),
})

local rgbT = 0
RunService.RenderStepped:Connect(function(dt)
    if not grad.Parent then return end
    rgbT += dt * 0.35
    local c = Color3.fromHSV((rgbT % 1), 0.55, 1)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(0.50, c),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,105,180)),
    })
end)

-- Buttons
local function mkBtn(parent, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 26)
    b.BackgroundTransparency = 0.4
    b.BackgroundColor3 = color or Theme.Off
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local BtnMin = mkBtn(Header, "−", Theme.Off)
BtnMin.Position = UDim2.new(1, -66, 0, 12)
local BtnClose = mkBtn(Header, "×", Color3.fromRGB(200,60,60))
BtnClose.Position = UDim2.new(1, -36, 0, 12)

makeDraggable(Main, Header)

-- Mini chip (saat minimize)
local Mini = Instance.new("TextButton")
Mini.Name = "Mini"
Mini.Size = UDim2.new(0, 190, 0, 42)
Mini.Position = UDim2.new(0.5, -95, 0, 16)
Mini.BackgroundColor3 = Theme.Bg
Mini.BackgroundTransparency = 0.35
Mini.Text = "BimSakSin Hub"
Mini.Font = Enum.Font.GothamMedium
Mini.TextSize = 15
Mini.TextColor3 = Color3.new(1,1,1)
Mini.BorderSizePixel = 0
Mini.Visible = false
Mini.Parent = ScreenGui
Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 20)
local miniStroke = Instance.new("UIStroke", Mini)
miniStroke.Color = Theme.Accent
miniStroke.Thickness = 1.2
miniStroke.Transparency = 0.3
local miniGrad = Instance.new("UIGradient", Mini)
miniGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,105,180)),
})
miniGrad.Rotation = 90
makeDraggable(Mini, Mini)

--=========================================================
-- SCROLL AREA
--=========================================================
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -66)
Scroll.Position = UDim2.new(0, 10, 0, 58)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Theme.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local List = Instance.new("UIListLayout", Scroll)
List.Padding = UDim.new(0, 6)
List.SortOrder = Enum.SortOrder.LayoutOrder

local Pad = Instance.new("UIPadding", Scroll)
Pad.PaddingTop = UDim.new(0, 4)
Pad.PaddingBottom = UDim.new(0, 10)

--=========================================================
-- UI HELPERS
--=========================================================
local function section(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = "▎ " .. text
    l.TextColor3 = Theme.Accent
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = Scroll
    return l
end

local function toggle(text, key, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Theme.Bg
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -10, 0.5, 0)
    btn.BackgroundColor3 = State[key] and Theme.On or Theme.Off
    btn.Text = State[key] and "ON" or "OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local function set(v)
        State[key] = v
        btn.BackgroundColor3 = v and Theme.On or Theme.Off
        btn.Text = v and "ON" or "OFF"
        if cb then pcall(cb, v) end
    end
    btn.MouseButton1Click:Connect(function() set(not State[key]) end)
    return set
end

local function slider(text, minv, maxv, def, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Theme.Bg
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. def
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Theme.Off
    bar.BorderSizePixel = 0
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-minv)/(maxv-minv), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local drag = false
    local function update(x)
        local absX = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(minv + absX*(maxv-minv) + 0.5)
        fill.Size = UDim2.new((v-minv)/(maxv-minv), 0, 1, 0)
        lbl.Text = text .. ": " .. v
        if cb then pcall(cb, v) end
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

local function button(text, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = Theme.Bg
    b.BackgroundTransparency = 0.55
    b.Text = text
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Parent = Scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    return b
end

--=========================================================
-- MINIMIZE / CLOSE
--=========================================================
BtnMin.MouseButton1Click:Connect(function()
    Main.Visible = false
    Mini.Visible = true
end)
Mini.MouseButton1Click:Connect(function()
    Main.Visible = true
    Mini.Visible = false
end)
BtnClose.MouseButton1Click:Connect(function()
    -- reset
