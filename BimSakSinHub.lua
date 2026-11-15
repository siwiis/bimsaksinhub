--// ==========================================
--// BimSakSin Hub - Ultimate District Edition
--// Compatible with Delta Executor
--// Theme Inspired by Luxury Gaming Interface[span_1](start_span)[span_1](end_span)
--// ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Mencegah duplikasi GUI jika script dieksekusi ulang
if CoreGui:FindFirstChild("BimSakSinHub") then
    CoreGui["BimSakSinHub"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub"
ScreenGui.ResetOnSpawn = false

-- Kompatibilitas Environment Delta / Executor
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

--// ==========================================
--// UI MAIN FRAME (PANEL UTAMA MEWAH)
--// ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 420)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18) -- Dark Theme Elegan
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Bisa digeser dengan mudah di layar HP/PC
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

-- Border / Garis Pinggir Mewah (Neon Ungu)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(168, 85, 247)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

--// ==========================================
--// TOP BAR (HEADER PANEL)
--// ==========================================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = TopBar

-- Perbaikan sudut bawah TopBar agar rata
local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 14)
TopBarFix.Position = UDim2.new(0, 0, 1, -14)
TopBarFix.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

-- Judul "BimSakSin Hub" Tepat di Tengah Atas (Gaya Panel Mewah)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 320, 1, 0)
TitleLabel.Position = UDim2.new(0.5, -160, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextColor3 = Color3.fromRGB(212, 175, 55) -- Warna Gold Mewah
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Parent = TopBar

-- Tombol Minimize (-) ala Chrome
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -90, 0, 5)
MinBtn.BackgroundTransparency = 1
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 24
MinBtn.Parent = TopBar

-- Tombol Close (x) ala Chrome
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
CloseBtn.TextSize = 24
CloseBtn.Parent = TopBar

--// ==========================================
--// FLOATING TOGGLE (SAAT DI-MINIMIZE)
--// ==========================================
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 190, 0, 46)
FloatingToggle.Position = UDim2.new(0, 30, 0, 30)
FloatingToggle.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
FloatingToggle.Visible = false
FloatingToggle.Active = true
FloatingToggle.Draggable = true
FloatingToggle.Font = Enum.Font.GothamBold
FloatingToggle.Text = "BimSakSin Hub"
FloatingToggle.TextColor3 = Color3.fromRGB(212, 175, 55) -- Gold Text
FloatingToggle.TextSize = 15
FloatingToggle.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 23)
FloatCorner.Parent = FloatingToggle

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(168, 85, 247)
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatingToggle

-- Logika Interaksi Tombol Minimize & Close
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingToggle.Visible = true
end)

FloatingToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingToggle.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// ==========================================
--// CONTAINER MENU FITUR (SCROLLABLE)
--// ==========================================
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -65)
Container.Position = UDim2.new(0, 10, 0, 56)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.CanvasSize = UDim2.new(0, 0, 0, 520)
Container.ScrollBarThickness = 4
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Container

-- Template Pembuatan Tombol Fitur (Toggle)
local function CreateToggle(name, callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 0, 45)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Font = Enum.Font.GothamMedium
    ToggleBtn.Text = "  " .. name
    ToggleBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
    ToggleBtn.TextSize = 14
    ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    ToggleBtn.Parent = Container

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleBtn

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(50, 50, 75)
    Stroke.Thickness = 1
    Stroke.Parent = ToggleBtn

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0, 90, 1, 0)
    StatusLabel.Position = UDim2.new(1, -95, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.Text = "[ OFF ]"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 13
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatusLabel.Parent = ToggleBtn

    local enabled = false
    ToggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            StatusLabel.Text = "[ ON ]"
            StatusLabel.TextColor3 = Color3.fromRGB(168, 85, 247)
            Stroke.Color = Color3.fromRGB(168, 85, 247)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 22, 52)
        else
            StatusLabel.Text = "[ OFF ]"
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            Stroke.Color = Color3.fromRGB(50, 50, 75)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        end
        pcall(function()
            callback(enabled)
        end)
    end)
end

--// ==========================================
--// KUMPULAN FITUR UTAMA LENGKAP (ANTI-CRASH)
--// ==========================================

-- 1. PLAYER ESP (Highlight Pemain Lain di Map Distrik)
local ESPEnabled = false
local function ToggleESP(state)
    ESPEnabled = state
    
    local function applyESP(player)
        if player == LocalPlayer then return end
        
        local function addHighlight(char)
            if not char:FindFirstChild("BimSakSinESP") then
                local hl = Instance.new("Highlight")
                hl.Name = "BimSakSinESP"
                hl.Adornee = char
                hl.FillColor = Color3.fromRGB(168, 85, 247)
                hl.OutlineColor = Color3.fromRGB(212, 175, 55)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = char
            end
        end
        
        if player.Character and ESPEnabled then
            addHighlight(player.Character)
        end
        
        player.CharacterAdded:Connect(function(char)
            if ESPEnabled then
                task.wait(1)
                addHighlight(char)
            end
        end)
    end
    
    if ESPEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            applyESP(p)
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("BimSakSinESP") then
                p.Character.BimSakSinESP:Destroy()
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if ESPEnabled and player ~= LocalPlayer then
            task.wait(1)
            local hl = Instance.new("Highlight")
            hl.Name = "BimSakSinESP"
            hl.Adornee = char
            hl.FillColor = Color3.fromRGB(168, 85, 247)
            hl.OutlineColor = Color3.fromRGB(212, 175, 55)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.Parent = char
        end
    end)
end)

CreateToggle("Player ESP (Highlight)", ToggleESP)


-- 2. NOCLIP (Tembus Tembok / Objek Gedung di Map Distrik)
local NoclipConnection = nil
CreateToggle("Noclip (Tembus Tembok)", function(state)
    if state then
        NoclipConnection = RunService.Stepped:Connect(function()
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
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
    end
end)


-- 3. FULLBRIGHT (Menerangi Area Gelap / Malam Hari di Map)
local OriginalBrightness = Lighting.Brightness
local OriginalClock = Lighting.ClockTime
CreateToggle("Fullbright (Anti Gelap Map)", function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220)
    else
        Lighting.Brightness = OriginalBrightness
        Lighting.ClockTime = OriginalClock
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
end)


-- 4. SPEED HACK (Kecepatan Lari 50)
CreateToggle("Speed Hack (WalkSpeed 50)", function(state)
    pcall(function()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = state and 50 or 16
        end
    end)
end)


-- 5. SUPER JUMP (Loncat Tinggi 100)
CreateToggle("Super Jump (JumpPower 100)", function(state)
    pcall(function()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = state and 100 or 50
        end
    end)
end)


-- 6. INFINITE JUMP (Loncat Terus di Udara)
local InfJumpConn = nil
CreateToggle("Infinite Jump (Loncat di Udara)", function(state)
    if state then
        InfJumpConn = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
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


-- 7. FLY HACK (Terbang Menjelajahi Seluruh Map Distrik)
local Flying = false
local FlySpeed = 50
local BodyGyro, BodyVelocity
CreateToggle("Fly Hack (Terbang Bebas)", function(state)
    Flying = state
    pcall(function()
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if Flying and rootPart and humanoid then
            humanoid.PlatformStand = true
            
            BodyGyro = Instance.new("BodyGyro")
            BodyGyro.P = 9e4
            BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BodyGyro.CFrame = rootPart.CFrame
            BodyGyro.Parent = rootPart
            
            BodyVelocity = Instance.new("BodyVelocity")
            BodyVelocity.Velocity = Vector3.new(0, 0, 0)
            BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            BodyVelocity.Parent = rootPart
            
            task.spawn(function()
                while Flying and rootPart and humanoid and humanoid.Health > 0 do
                    local camCFrame = Camera.CFrame
                    local moveDir = Vector3.new()
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveDir = moveDir + camCFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDir = moveDir - camCFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveDir = moveDir - camCFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDir = moveDir + camCFrame.RightVector
                    end
                    
                    BodyVelocity.Velocity = moveDir * FlySpeed
                    BodyGyro.CFrame = camCFrame
                    RunService.RenderStepped:Wait()
                end
                
                if BodyGyro then BodyGyro:Destroy() end
                if BodyVelocity then BodyVelocity:Destroy() end
                if humanoid then humanoid.PlatformStand = false end
            end)
        else
            if BodyGyro then BodyGyro:Destroy() end
            if BodyVelocity then BodyVelocity:Destroy() end
            if humanoid then humanoid.PlatformStand = false end
        end
    end)
end)

print("BimSakSin Hub Loaded Successfully!")
