-- =========================================================
-- BIMSAKSIN HUB // ULTIMATE CYBERPUNK EDITION (FULL FEATURES)
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
if PlayerGui:FindFirstChild("BimSakSinCyberpunk") then PlayerGui.BimSakSinCyberpunk:Destroy() end
if CoreGui:FindFirstChild("BimSakSinCyberpunk") then CoreGui.BimSakSinCyberpunk:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinCyberpunk"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = gethui and gethui() or PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

---------------------------------------------------------
-- 1. FLOATING TOGGLE "BSH" (Draggable & Cyberpunk Style)
---------------------------------------------------------
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "CyberToggle"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 20, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ToggleBtn.Text = "BSH"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 200)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Fitur Geser (Draggable) Toggle
local dragging, dragStart, startPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

---------------------------------------------------------
-- 2. PANEL UTAMA CYBERPUNK (Dengan ScrollingFrame)
---------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 460, 0, 320)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 200)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Efek Animasi RGB Halus pada Border
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

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 45)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ BIMSAKSIN HUB // ULTIMATE PRO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize, CloseBtn.Font = 12, Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Container Fitur (ScrollingFrame agar rapi & muat banyak)
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -20, 1, -60)
ScrollContainer.Position = UDim2.new(0, 10, 0, 50)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 450)
ScrollContainer.ScrollBarThickness = 4
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ScrollContainer

---------------------------------------------------------
-- 3. PEMBUATAN KOMPONEN TOMBOL FITUR (UI HELPER)
---------------------------------------------------------
local function createToggle(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    btn.TextColor3 = Color3.fromRGB(0, 255, 200)
    btn.Text = name .. " [ OFF ]"
    btn.TextSize, btn.Font = 13, Enum.Font.GothamMedium
    btn.Parent = ScrollContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.Text = name .. " [ ACTIVE 🔥 ]"
            btn.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            btn.Text = name .. " [ OFF ]"
            btn.TextColor3 = Color3.fromRGB(0, 255, 200)
        end
        callback(state)
    end)
end

---------------------------------------------------------
-- 4. FITUR-FITUR UTAMA (ESP, Combat, Auto Gen, Move, TP)
---------------------------------------------------------

-- Variabel Status Fitur
local Config = {
    SurvivorESP = false,
    KillerESP = false,
    GenESP = false,
    Aimbot = false,
    AutoGenerator = false,
    CustomSpeed = false,
    SpeedVal = 16,
    NoClip = false,
    Fly = false,
    FlySpeed = 50
}

-- ESP Helper Function
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

-- 1. Toggle ESP Survivor (Hijau)
createToggle("ESP Survivor (Hijau)", function(v) Config.SurvivorESP = v end)

-- 2. Toggle ESP Killer (Merah)
createToggle("ESP Killer (Merah)", function(v) Config.KillerESP = v end)

-- 3. Toggle ESP Generator (Kuning)
createToggle("ESP Generator (Kuning)", function(v) Config.GenESP = v end)

-- 4. Toggle Aimbot Otomatis
createToggle("Aimbot Target Terdekat", function(v) Config.Aimbot = v end)

-- 5. Toggle Auto Generator (Perfect Skill Check)
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

-- 6. Toggle NoClip (Tembus Tembok)
createToggle("NoClip (Tembus Tembok)", function(v) Config.NoClip = v end)

-- 7. Toggle Fly Halus
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
-- 5. RUNSERVICE LOOP UTAMA (ESP, Speed, NoClip, Aimbot)
---------------------------------------------------------
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Custom Speed
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if Config.CustomSpeed then
                LocalPlayer.Character.Humanoid.WalkSpeed = Config.SpeedVal
            end
        end

        -- NoClip
        if Config.NoClip and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        -- ESP Logic
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

        -- ESP Generator
        if Config.GenESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("generator") and obj:IsA("Model") then
                    createHighlight(obj, Color3.fromRGB(255, 255, 0))
                end
            end
        end

        -- Aimbot Logic
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
-- 6. SISTEM BUKA / TUTUP PANEL
---------------------------------------------------------
local isOpen = false
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

CloseBtn.MouseButton1Click:Connect(function()
    isOpen = false
    MainFrame.Visible = false
end)

print("BimSakSin Hub Ultimate Cyberpunk Berhasil Dijalankan!")
