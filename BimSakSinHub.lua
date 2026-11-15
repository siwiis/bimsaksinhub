-- =========================================================
-- BIMSAKSIN HUB // CHROME EDITION + Prabowo Background
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
if PlayerGui:FindFirstChild("BimSakSinChrome") then PlayerGui.BimSakSinChrome:Destroy() end
if CoreGui:FindFirstChild("BimSakSinChrome") then CoreGui.BimSakSinChrome:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinChrome"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = gethui and gethui() or PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

---------------------------------------------------------
-- 1. FLOATING TOGGLE "BSH" (RGB Border & 100% Responsive Tap)
---------------------------------------------------------
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "BSHToggle"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 20, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleBtn.Text = "BSH"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.ZIndex = 10
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 200)
ToggleStroke.Thickness = 2.5
ToggleStroke.Parent = ToggleBtn

-- Logika Drag & Tap Anti-Gagal untuk HP
local isOpen = false
local dragging = false
local dragStart, startPos
local moved = false

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPos = ToggleBtn.Position

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                conn:Disconnect()
                if not moved then
                    isOpen = not isOpen
                    MainFrame.Visible = isOpen
                    print("Panel Menu Toggled:", isOpen)
                end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then
            moved = true
        end
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

---------------------------------------------------------
-- 2. PANEL UTAMA (Gaya Chrome Minimalis + Background)
---------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 280)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 200)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Efek Animasi RGB Halus pada Border Tombol & Panel
task.spawn(function()
    while true do
        task.wait(0.03)
        pcall(function()
            local hue = (tick() % 5) / 5
            local rgbColor = Color3.fromHSV(hue, 1, 1)
            MainStroke.Color = rgbColor
            ToggleStroke.Color = rgbColor
        end)
    end
end)

-- Background Image (Nuansa Prabowo / Custom Decal ID)
-- Kamu bisa ganti angka rbxassetid:// dengan asset ID gambar Prabowo pilihanmu
local BgImage = Instance.new("ImageLabel")
BgImage.Size = UDim2.new(1, 0, 1, 0)
BgImage.BackgroundTransparency = 1
BgImage.Image = "rbxassetid://10878152342" -- Placeholder aesthetic background (bisa diganti ID Decal Prabowo)
BgImage.ImageTransparency = 0.65 -- Supaya tidak terlalu mencolok dan teks tetap terbaca jelas
BgImage.ZIndex = 6
BgImage.Parent = MainFrame

-- Chrome Header / Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
TopBar.ZIndex = 7
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

-- Tutup bagian bawah sudut TopBar agar lurus
local FixCover = Instance.new("Frame")
FixCover.Size = UDim2.new(1, 0, 0, 5)
FixCover.Position = UDim2.new(0, 0, 1, -5)
FixCover.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
FixCover.BorderSizePixel = 0
FixCover.ZIndex = 7
FixCover.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌐 BimSakSin Hub // Chrome Panel"
Title.TextColor3 = Color3.fromRGB(220, 220, 230)
Title.TextSize, Title.Font = 13, Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 8
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize, CloseBtn.Font = 12, Enum.Font.GothamBold
CloseBtn.ZIndex = 8
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

---------------------------------------------------------
-- 3. KONTEN / FITUR DALAM PANEL (ScrollingFrame)
---------------------------------------------------------
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -16, 1, -45)
ScrollContainer.Position = UDim2.new(0, 8, 0, 40)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 380)
ScrollContainer.ScrollBarThickness = 3
ScrollContainer.ZIndex = 7
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollContainer

local function createToggle(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.BackgroundTransparency = 0.3
    btn.TextColor3 = Color3.fromRGB(0, 255, 200)
    btn.Text = name .. " [ OFF ]"
    btn.TextSize, btn.Font = 12, Enum.Font.GothamMedium
    btn.ZIndex = 8
    btn.Parent = ScrollContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    btn.Activated:Connect(function()
        state = not state
        if state then
            btn.Text = name .. " [ ACTIVE ]"
            btn.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            btn.Text = name .. " [ OFF ]"
            btn.TextColor3 = Color3.fromRGB(0, 255, 200)
        end
        callback(state)
    end)
end

---------------------------------------------------------
-- 4. DAFTAR FITUR UTAMA
---------------------------------------------------------
local Config = {
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

createToggle("ESP Survivor (Hijau)", function(v) Config.SurvivorESP = v end)
createToggle("ESP Killer (Merah)", function(v) Config.KillerESP = v end)
createToggle("ESP Generator (Kuning)", function(v) Config.GenESP = v end)
createToggle("Aimbot Target Terdekat", function(v) Config.Aimbot = v end)

createToggle("Auto Generator Proximity", function(v)
    Config.AutoGenerator = v
    task.spawn(function()
        while Config.AutoGenerator do
            task.wait(0.3)
            pcall(function()
                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent.Name:lower():find("generator") then
                        fireproximityprompt(prompt)
                    end
                end
            end)
        end
    end)
end)

createToggle("NoClip (Tembus Tembok)", function(v) Config.NoClip = v end)

createToggle("Fly Admin Mode", function(v)
    Config.Fly = v
    pcall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        if Config.Fly then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "BSS_FlyVel"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0,0,0)
            bv.Parent = hrp
            local bg = Instance.new("BodyGyro")
            bg.Name = "BSS_FlyGyro"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp
            task.spawn(function()
                while Config.Fly and hrp and hrp.Parent do
                    bv.Velocity = Camera.CFrame.LookVector * Config.FlySpeed
                    bg.CFrame = Camera.CFrame
                    task.wait()
                end
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
            end)
        end
    end)
end)

---------------------------------------------------------
-- 5. LOOP UTAMA (ESP, Aimbot, NoClip)
---------------------------------------------------------
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

---------------------------------------------------------
-- 6. TOMBOL CLOSE
---------------------------------------------------------
CloseBtn.Activated:Connect(function()
    isOpen = false
    MainFrame.Visible = false
end)

print("BimSakSin Hub Chrome Panel Berhasil Dijalankan!")
