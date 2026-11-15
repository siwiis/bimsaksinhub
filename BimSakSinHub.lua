-- =========================================================
-- BIMSAKSIN HUB // DELTA EXECUTOR NATIVE UI STYLE
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
if PlayerGui:FindFirstChild("BimSakSinDeltaStyle") then PlayerGui.BimSakSinDeltaStyle:Destroy() end
if CoreGui:FindFirstChild("BimSakSinDeltaStyle") then CoreGui.BimSakSinDeltaStyle:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinDeltaStyle"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = gethui and gethui() or PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

---------------------------------------------------------
-- 1. FLOATING TOGGLE "Δ" (Gaya Khas Delta UI)
---------------------------------------------------------
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "DeltaToggle"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 20, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
ToggleBtn.Text = "Δ"
ToggleBtn.TextColor3 = Color3.fromRGB(160, 90, 255) -- Ungu khas Delta
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.ZIndex = 10
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(138, 43, 226) -- Border Ungu Violet
ToggleStroke.Thickness = 2
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
-- 2. PANEL UTAMA (Gaya Bawaan Delta Executor)
---------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 440, 0, 290)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22) -- Hitam Gelap Elegan Delta
MainFrame.Visible = false
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(138, 43, 226) -- Garis Pinggir Ungu Delta
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Bar / Header Ala Delta
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TopBar.ZIndex = 6
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

-- Tutup sudut bawah TopBar
local FixCover = Instance.new("Frame")
FixCover.Size = UDim2.new(1, 0, 0, 5)
FixCover.Position = UDim2.new(0, 0, 1, -5)
FixCover.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
FixCover.BorderSizePixel = 0
FixCover.ZIndex = 6
FixCover.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Delta // BimSakSin Hub v3.0"
Title.TextColor3 = Color3.fromRGB(220, 220, 230)
Title.TextSize, Title.Font = 13, Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 7
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize, CloseBtn.Font = 12, Enum.Font.GothamBold
CloseBtn.ZIndex = 7
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

---------------------------------------------------------
-- 3. KONTEN / FITUR DALAM PANEL (ScrollingFrame)
---------------------------------------------------------
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -16, 1, -50)
ScrollContainer.Position = UDim2.new(0, 8, 0, 44)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 400)
ScrollContainer.ScrollBarThickness = 3
ScrollContainer.ZIndex = 6
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollContainer

local function createToggle(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    btn.TextColor3 = Color3.fromRGB(200, 170, 255) -- Aksen Ungu Muda
    btn.Text = name .. " [ OFF ]"
    btn.TextSize, btn.Font = 12, Enum.Font.GothamMedium
    btn.ZIndex = 7
    btn.Parent = ScrollContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    btn.Activated:Connect(function()
        state = not state
        if state then
            btn.Text = name .. " [ ACTIVE ]"
            btn.TextColor3 = Color3.fromRGB(100, 255, 150)
        else
            btn.Text = name .. " [ OFF ]"
            btn.TextColor3 = Color3.fromRGB(200, 170, 255)
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

print("BimSakSin Hub Delta Style Berhasil Dijalankan!")
