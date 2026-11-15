-- =========================================================
-- BIMSAKSIN HUB // GAMING SKULL EDITION (PURPLE PRO)
-- =========================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Bersihkan UI lama agar tidak numpuk
if PlayerGui:FindFirstChild("BimSakSinSkullHub") then PlayerGui.BimSakSinSkullHub:Destroy() end
if CoreGui:FindFirstChild("BimSakSinSkullHub") then CoreGui.BimSakSinSkullHub:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinSkullHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = gethui and gethui() or PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

---------------------------------------------------------
-- 1. BAR MINIMIZE ATAS (RGB Bar saat panel dikecilkan)
---------------------------------------------------------
local MinBar = Instance.new("TextButton")
MinBar.Name = "MinimizeBar"
MinBar.Size = UDim2.new(0, 260, 0, 36)
MinBar.Position = UDim2.new(0.5, -130, 0, 12)
MinBar.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
MinBar.Text = "BimSakSin Hub"
MinBar.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBar.TextSize, MinBar.Font = 14, Enum.Font.GothamBold
MinBar.Visible = false
MinBar.ZIndex = 50
MinBar.Parent = ScreenGui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinBar

local MinStroke = Instance.new("UIStroke")
MinStroke.Color = Color3.fromRGB(160, 50, 255)
MinStroke.Thickness = 2
MinStroke.Parent = MinBar

-- Animasi RGB Bergerak untuk Bar Minimize
task.spawn(function()
    while true do
        task.wait(0.03)
        pcall(function()
            local hue = (tick() % 5) / 5
            local rgbColor = Color3.fromHSV(hue, 1, 1)
            MinStroke.Color = rgbColor
            MinBar.TextColor3 = rgbColor
        end)
    end
end)

---------------------------------------------------------
-- 2. PANEL UTAMA (Gaya Gaming Skull & Purple Neon)
---------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 380)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Visible = true
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(160, 50, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Efek Animasi RGB Halus pada Border Panel Utama
task.spawn(function()
    while true do
        task.wait(0.03)
        pcall(function()
            local hue = (tick() % 5) / 5
            local rgbColor = Color3.fromHSV(hue, 1, 1)
            MainStroke.Color = rgbColor
        end)
    end
end)

-- Background Image (Nuansa Gaming Skull / Dark Purple)
local BgImage = Instance.new("ImageLabel")
BgImage.Size = UDim2.new(1, 0, 1, 0)
BgImage.BackgroundTransparency = 1
BgImage.Image = "rbxassetid://10878152342" -- Placeholder gaming background (bisa diganti asset ID kustom kamu)
BgImage.ImageTransparency = 0.75
BgImage.ZIndex = 11
BgImage.Parent = MainFrame

---------------------------------------------------------
-- 3. HEADER / TOP BAR (Judul & Tombol Minimize/Close)
---------------------------------------------------------
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
TopBar.ZIndex = 12
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 10)
TopBarCorner.Parent = TopBar

local FixCover = Instance.new("Frame")
FixCover.Size = UDim2.new(1, 0, 0, 10)
FixCover.Position = UDim2.new(0, 0, 1, -10)
FixCover.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
FixCover.BorderSizePixel = 0
FixCover.ZIndex = 12
FixCover.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ BIMSAKSIN HUB // GAMING INTERFACE"
TitleLabel.TextColor3 = Color3.fromRGB(220, 180, 255)
TitleLabel.TextSize, TitleLabel.Font = 14, Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 13
TitleLabel.Parent = TopBar

-- Tombol Minimize (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 26)
MinBtn.Position = UDim2.new(1, -74, 0.5, -13)
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 65)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize, MinBtn.Font = 14, Enum.Font.GothamBold
MinBtn.ZIndex = 13
MinBtn.Parent = TopBar

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinBtn

-- Tombol Close (✕)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 26)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize, CloseBtn.Font = 12, Enum.Font.GothamBold
CloseBtn.ZIndex = 13
CloseBtn.Parent = TopBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

---------------------------------------------------------
-- 4. SISTEM TAB MENU DI BAWAH HEADER
---------------------------------------------------------
local TabsBar = Instance.new("Frame")
TabsBar.Size = UDim2.new(1, -30, 0, 35)
TabsBar.Position = UDim2.new(0, 15, 0, 52)
TabsBar.BackgroundTransparency = 1
TabsBar.ZIndex = 12
TabsBar.Parent = MainFrame

local TabsLayout = Instance.new("UIListLayout")
TabsLayout.FillDirection = Enum.FillDirection.Horizontal
TabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabsLayout.SortOrder = Enum.SortOrder.LayoutIndex
TabsLayout.Padding = UDim.new(0, 20)
TabsLayout.Parent = TabsBar

local PagesContainer = Instance.new("Folder")
PagesContainer.Name = "PagesContainer"
PagesContainer.ZIndex = 12
PagesContainer.Parent = MainFrame

local activeTabName = nil
local pages = {}

local function createTabButton(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 100, 1, 0)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(140, 130, 160)
    tabBtn.TextSize, tabBtn.Font = 13, Enum.Font.GothamBold
    tabBtn.ZIndex = 13
    tabBtn.Parent = TabsBar

    local pageFrame = Instance.new("ScrollingFrame")
    pageFrame.Name = name .. "Page"
    pageFrame.Size = UDim2.new(1, -30, 1, -110)
    pageFrame.Position = UDim2.new(0, 15, 0, 100)
    pageFrame.BackgroundTransparency = 1
    pageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    pageFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pageFrame.ScrollBarThickness = 3
    pageFrame.Visible = false
    pageFrame.ZIndex = 12
    pageFrame.Parent = PagesContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutIndex
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.Parent = pageFrame

    pages[name] = pageFrame

    tabBtn.Activated:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        for _, b in pairs(TabsBar:GetChildren()) do
            if b:IsA("TextButton") then b.TextColor3 = Color3.fromRGB(140, 130, 160) end
        end
        pageFrame.Visible = true
        tabBtn.TextColor3 = Color3.fromRGB(220, 180, 255)
    end)

    if not activeTabName then
        activeTabName = name
        pageFrame.Visible = true
        tabBtn.TextColor3 = Color3.fromRGB(220, 180, 255)
    end

    return pageFrame
end

---------------------------------------------------------
-- 5. PEMBUATAN FITUR DI DALAM TAB
---------------------------------------------------------
local function addOptionRow(parentPage, labelText, defaultState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    row.BackgroundTransparency = 0.3
    row.ZIndex = 13
    row.Parent = parentPage

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize, label.Font = 13, Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 14
    label.Parent = row

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 140, 0, 30)
    toggleBtn.Position = UDim2.new(1, -150, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
    toggleBtn.ZIndex = 14
    toggleBtn.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 6)
    tCorner.Parent = toggleBtn

    local state = defaultState
    local function updateVisual()
        if state then
            toggleBtn.Text = "ACTIVE 🔥"
            toggleBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
        else
            toggleBtn.Text = "OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    updateVisual()

    toggleBtn.Activated:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)
end

-- Tab 1: VISUALS
local visualPage = createTabButton("VISUALS")
addOptionRow(visualPage, "ESP Survivor (Hijau)", false, function(v) Config.SurvivorESP = v end)
addOptionRow(visualPage, "ESP Killer (Merah)", false, function(v) Config.KillerESP = v end)
addOptionRow(visualPage, "ESP Generator (Kuning)", false, function(v) Config.GenESP = v end)

-- Tab 2: COMBAT
local combatPage = createTabButton("COMBAT")
addOptionRow(combatPage, "Aimbot Target Terdekat", false, function(v) Config.Aimbot = v end)

-- Tab 3: MOVEMENT
local movePage = createTabButton("MOVEMENT")
addOptionRow(movePage, "NoClip (Tembus Tembok)", false, function(v) Config.NoClip = v end)
addOptionRow(movePage, "Fly Admin Mode", false, function(v) Config.Fly = v end)

-- Tab 4: MISC
local miscPage = createTabButton("MISC")
addOptionRow(miscPage, "Auto Generator Proximity", false, function(v) Config.AutoGenerator = v end)

---------------------------------------------------------
-- 6. INTERAKSI MINIMIZE & CLOSE
---------------------------------------------------------
MinBtn.Activated:Connect(function()
    MainFrame.Visible = false
    MinBar.Visible = true
end)

CloseBtn.Activated:Connect(function()
    ScreenGui:Destroy()
end)

MinBar.Activated:Connect(function()
    MinBar.Visible = false
    MainFrame.Visible = true
end)

---------------------------------------------------------
-- 7. CONFIG & LOGIKA UTAMA FITUR
---------------------------------------------------------
Config = {
    SurvivorESP = false,
    KillerESP = false,
    GenESP = false,
    Aimbot = false,
    AutoGenerator = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 50
}

local function createHighlight(obj, fillColor)
    if not obj or obj:FindFirstChild("BSS_Highlight") then return end
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "BSS_Highlight"
        hl.Adornee = obj
        hl.FillColor = fillColor
        hl.FillTransparency = 0.4
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Parent = obj
    end)
end

task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            if Config.AutoGenerator then
                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent.Name:lower():find("generator") then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        if Config.NoClip and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        if Config.SurvivorESP or Config.KillerESP then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local isKiller = player.Team and (player.Team.Name:lower():find("killer") or player.Team.Name:lower():find("monster"))
                    if isKiller and Config.KillerESP then
                        createHighlight(player.Character, Color3.fromRGB(255, 0, 0))
                    elseif not isKiller and Config.SurvivorESP then
                        createHighlight(player.Character, Color3.fromRGB(0, 255, 0))
                    end
                end
            end
        end

        if Config.GenESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("generator") and obj:IsA("Model") then
                    createHighlight(obj, Color3.fromRGB(255, 255, 0))
                end
            end
        end

        if Config.Aimbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local closestTarget = nil
            local shortestDist = math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestTarget = player.Character.HumanoidRootPart
                    end
                end
            end
            if closestTarget then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
            end
        end
    end)
end)

print("BimSakSin Hub Gaming Skull Edition Berhasil Dijalankan!")
