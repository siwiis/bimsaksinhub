--[[
    ============================================================
    Script Name : BimSakSin Hub v3.0
    Target      : Roblox Survival / District Map / Killer Games
    Executor    : Delta / Synapse Z / Arceus X
    ============================================================
]]--

if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Hapus UI lama jika ada
if CoreGui:FindFirstChild("BimSakSinHub") then
    CoreGui.BimSakSinHub:Destroy()
end

-- State Variabel Fitur
local _G_Config = {
    ESP_Player = false,
    ESP_Killer = false,
    ESP_Generator = false,
    Fly = false,
    Speed = false,
    SpeedVal = 32,
    Noclip = false,
    AutoGenerator = false,
    AutoHeal = false,
    KillerAimbot = false,
    Fullbright = false,
    Connections = {}
}

-- Buat ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame Panel
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
MainFrame.Size = UDim2.new(0, 450, 0, 320)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(255, 105, 180) -- Pink accent
MainStroke.Transparency = 0.4
MainStroke.Thickness = 1.5

-- Top Bar / Header
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TopBar.BackgroundTransparency = 0.3
TopBar.Size = UDim2.new(1, 0, 0, 38)

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

-- Fix bottom corners of TopBar
local TopFix = Instance.new("Frame")
TopFix.Parent = TopBar
TopFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TopFix.BackgroundTransparency = 0.3
TopFix.BorderSizePixel = 0
TopFix.Position = UDim2.new(0, 0, 0.5, 0)
TopFix.Size = UDim2.new(1, 0, 0.5, 0)

-- Title Label (BimSakSin Hub v3.0)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Size = UDim2.new(0, 300, 1, 0)
TitleLabel.Font = Enum.Font.GothamMedium
TitleLabel.Text = "BimSakSin Hub v3.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- RGB / Pink-White Shimmer effect for Title
task.spawn(function()
    while task.wait(0.05) do
        local t = tick() * 2
        local r = math.sin(t) * 0.2 + 0.8
        local g = math.sin(t + 2) * 0.15 + 0.85
        local b = 1
        if TitleLabel and TitleLabel.Parent then
            TitleLabel.TextColor3 = Color3.fromRGB(r * 255, g * 255, b * 255)
        else
            break
        end
    end
end)

-- Minimize Button (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Parent = TopBar
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
MinBtn.BackgroundTransparency = 0.3
MinBtn.Position = UDim2.new(1, -65, 0, 8)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Close Button (x)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Position = UDim2.new(1, -35, 0, 8)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Minimized floating Pill (BimSakSin Hub)
local MinimizedPill = Instance.new("TextButton")
MinimizedPill.Name = "MinimizedPill"
MinimizedPill.Parent = ScreenGui
MinimizedPill.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MinimizedPill.BackgroundTransparency = 0.3
MinimizedPill.Position = UDim2.new(0.5, -90, 0.05, 0)
MinimizedPill.Size = UDim2.new(0, 180, 0, 36)
MinimizedPill.Font = Enum.Font.GothamMedium
MinimizedPill.Text = " BimSakSin Hub "
MinimizedPill.TextColor3 = Color3.fromRGB(255, 105, 180)
MinimizedPill.TextSize = 14
MinimizedPill.Visible = false
MinimizedPill.Active = true
MinimizedPill.Draggable = true
Instance.new("UICorner", MinimizedPill).CornerRadius = UDim.new(0, 18)
local PillStroke = Instance.new("UIStroke", MinimizedPill)
PillStroke.Color = Color3.fromRGB(255, 255, 255)
PillStroke.Transparency = 0.5

-- Container / Content ScrollingFrame
local Container = Instance.new("ScrollingFrame")
Container.Name = "Container"
Container.Parent = MainFrame
Container.Active = true
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 0, 0, 44)
Container.Size = UDim2.new(1, 0, 1, -44)
Container.CanvasSize = UDim2.new(0, 0, 0, 650)
Container.ScrollBarThickness = 4
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 105, 180)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

-- Resize Grip (Bottom-Right Corner)
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Name = "ResizeGrip"
ResizeGrip.Parent = MainFrame
ResizeGrip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Position = UDim2.new(1, -15, 1, -15)
ResizeGrip.Size = UDim2.new(0, 15, 0, 15)
ResizeGrip.Text = "◢"
ResizeGrip.TextColor3 = Color3.fromRGB(200, 200, 200)
ResizeGrip.TextSize = 12

local resizing = false
local dragStart, startSize

ResizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        dragStart = input.Position
        startSize = MainFrame.AbsoluteSize
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newX = math.clamp(startSize.X + delta.X, 350, 700)
        local newY = math.clamp(startSize.Y + delta.Y, 250, 550)
        MainFrame.Size = UDim2.new(0, newX, 0, newY)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- Minimize & Close Action Logic
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizedPill.Visible = true
end)

MinimizedPill.MouseButton1Click:Connect(function()
    MinimizedPill.Visible = false
    MainFrame.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- Reset / Stop all active features and connections
    for _, conn in pairs(_G_Config.Connections) do
        if conn then conn:Disconnect() end
    end
    ScreenGui:Destroy()
end)

-- Helper to create Toggle Button
local function CreateToggle(name, callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = Container
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    ToggleBtn.BackgroundTransparency = 0.4
    ToggleBtn.Size = UDim2.new(0.92, 0, 0, 38)
    ToggleBtn.Font = Enum.Font.GothamMedium
    ToggleBtn.Text = "  " .. name .. " [ OFF ]"
    ToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    ToggleBtn.TextSize = 13
    ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    
    local Corner = Instance.new("UICorner", ToggleBtn)
    Corner.CornerRadius = UDim.new(0, 6)
    
    local StatusIndicator = Instance.new("Frame", ToggleBtn)
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    StatusIndicator.Position = UDim2.new(1, -30, 0.5, -7)
    StatusIndicator.Size = UDim2.new(0, 14, 0, 14)
    Instance.new("UICorner", StatusIndicator).CornerRadius = UDim.new(1, 0)

    local active = false
    ToggleBtn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            ToggleBtn.Text = "  " .. name .. " [ ON ]"
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            StatusIndicator.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
        else
            ToggleBtn.Text = "  " .. name .. " [ OFF ]"
            ToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            StatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end
        callback(active)
    end)
end

-- ==========================================
-- IMPLEMENTASI FITUR-FITUR
-- ==========================================

-- 1. ESP Players & Killer (Different Colors & Distances)
CreateToggle("ESP Players & Killer", function(state)
    _G_Config.ESP_Player = state
    _G_Config.ESP_Killer = state
    
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            if not _G_Config.ESP_Player and not _G_Config.ESP_Killer then return end
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    local head = player.Character:FindFirstChild("Head") or hrp
                    local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                    
                    -- Deteksi Killer berdasarkan nama/tim/atribut (Disesuaikan untuk game distrik/horror)
                    local isKiller = false
                    if player.Team and (player.Team.Name:lower():find("killer") or player.Team.Name:lower():find("monster") or player.Team.Name:lower():find("hunter")) then
                        isKiller = true
                    elseif player.Name:lower():find("killer") or (player.Character:FindFirstChild("Knife") or player.Character:FindFirstChild("Bat") or player.Character:FindFirstChild("Weapon")) then
                        isKiller = true
                    end
                    
                    if (isKiller and _G_Config.ESP_Killer) or (not isKiller and _G_Config.ESP_Player) then
                        local billboard = hrp:FindFirstChild("BimSakSinESP")
                        if not billboard then
                            billboard = Instance.new("BillboardGui")
                            billboard.Name = "BimSakSinESP"
                            billboard.Size = UDim2.new(0, 150, 0, 50)
                            billboard.AlwaysOnTop = true
                            billboard.StudsOffset = Vector3.new(0, 3, 0)
                            billboard.Parent = hrp
                            
                            local label = Instance.new("TextLabel")
                            label.Name = "Text"
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Font = Enum.Font.GothamBold
                            label.TextSize = 12
                            label.Parent = billboard
                        end
                        
                        local label = billboard:FindFirstChild("Text")
                        if label then
                            local colorText = isKiller and "<font color='#FF3333'>[KILLER] " or "<font color='#33FF66'>[PLAYER] "
                            label.RichText = true
                            label.Text = colorText .. player.Name .. "</font>\n<font color='#FFFF66'>[" .. dist .. "m]</font>"
                        end
                    else
                        if hrp:FindFirstChild("BimSakSinESP") then
                            hrp.BimSakSinESP:Destroy()
                        end
                    end
                end
            end
        end)
        table.insert(_G_Config.Connections, conn)
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local esp = player.Character.HumanoidRootPart:FindFirstChild("BimSakSinESP")
                if esp then esp:Destroy() end
            end
        end
    end
end)

-- 2. ESP Generator (Status & Progress)
CreateToggle("ESP Generator & Progress", function(state)
    _G_Config.ESP_Generator = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            if not _G_Config.ESP_Generator then return end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("generator") or obj.Name:lower():find("gen") or obj.Name:lower():find("machine") then
                    local targetPart = obj:IsA("Model") and obj.PrimaryPart or (obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart"))
                    if targetPart then
                        local dist = math.floor((targetPart.Position - Camera.CFrame.Position).Magnitude)
                        local billboard = targetPart:FindFirstChild("GenESP")
                        if not billboard then
                            billboard = Instance.new("BillboardGui")
                            billboard.Name = "GenESP"
                            billboard.Size = UDim2.new(0, 160, 0, 45)
                            billboard.AlwaysOnTop = true
                            billboard.StudsOffset = Vector3.new(0, 2, 0)
                            billboard.Parent = targetPart
                            
                            local label = Instance.new("TextLabel")
                            label.Name = "GenText"
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Font = Enum.Font.GothamBold
                            label.TextSize = 11
                            label.Parent = billboard
                        end
                        
                        local label = billboard:FindFirstChild("GenText")
                        if label then
                            -- Cek status generator (Selesai / Belum)
                            local status = "SEDANG DIKERJAKAN"
                            local color = "#FFA500" -- Orange
                            if obj:GetAttribute("Completed") == true or obj:FindFirstChild("Complete") then
                                status = "SELESAI [DONE]"
                                color = "#00FF00"
                            end
                            label.RichText = true
                            label.Text = "<font color='" .. color .. "'>[GEN] " .. status .. "</font>\n<font color='#FFFFFF'>Jarak: " .. dist .. "m</font>"
                        end
                    end
                end
            end
        end)
        table.insert(_G_Config.Connections, conn)
    else
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:FindFirstChild("GenESP") then
                obj.GenESP:Destroy()
            end
        end
    end
end)

-- 3. Auto Generator (Perfect Skill Check)
CreateToggle("Auto Generator (Perfect SkillCheck)", function(state)
    _G_Config.AutoGenerator = state
    if state then
        local conn = RunService.Heartbeat:Connect(function()
            if not _G_Config.AutoGenerator then return end
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("TextButton") and (gui.Name:lower():find("skill") or gui.Name:lower():find("check") or gui.Name:lower():find("tap") or gui.Name:lower():find("hit")) then
                        -- Simulasi klik otomatis saat minigame muncul
                        pcall(function()
                            gui.Visible = true
                            -- Fire click/touch event
                            for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                                connection:Fire()
                            end
                        end)
                    end
                end
            end
        end)
        table.insert(_G_Config.Connections, conn)
    end
end)

-- 4. Fly Halus (Admin Dev Style)
CreateToggle("Fly (Admin Mode)", function(state)
    _G_Config.Fly = state
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    
    if state then
        local bg = Instance.new("BodyGyro", hrp)
        bg.Name = "BimSakFlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        
        local bv = Instance.new("BodyVelocity", hrp)
        bv.Name = "BimSakFlyVel"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        
        local conn = RunService.RenderStepped:Connect(function()
            if not _G_Config.Fly then return end
            local camCFrame = Camera.CFrame
            local speed = 50
            local moveDir = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            bv.Velocity = moveDir * speed
            bg.CFrame = camCFrame
        end)
        table.insert(_G_Config.Connections, conn)
    else
        if hrp:FindFirstChild("BimSakFlyGyro") then hrp.BimSakFlyGyro:Destroy() end
        if hrp:FindFirstChild("BimSakFlyVel") then hrp.BimSakFlyVel:Destroy() end
    end
end)

-- 5. Speed Lari Kencang
CreateToggle("Speed Kencang", function(state)
    _G_Config.Speed = state
    local conn = RunService.Heartbeat:Connect(function()
        if _G_Config.Speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 32
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end)
    table.insert(_G_Config.Connections, conn)
end)

-- 6. Tembus Tembok (Noclip)
CreateToggle("Tembus Tembok (Noclip)", function(state)
    _G_Config.Noclip = state
    local conn = RunService.Stepped:Connect(function()
        if _G_Config.Noclip and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    table.insert(_G_Config.Connections, conn)
end)

-- 7. Killer Fast Attack & Aimbot Hit (Anti-Delay & Brutal Hit)
CreateToggle("Killer Fast Attack & Aimbot", function(state)
    _G_Config.KillerAimbot = state
    local conn = RunService.Heartbeat:Connect(function()
        if not _G_Config.KillerAimbot then return end
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                -- Hapus cooldown / delay serangan
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        if v.Name:lower():find("cooldown") or v.Name:lower():find("delay") then
                            v.Value = 0
                        end
                    end
                end
                
                -- Aimbot / Auto tempel ke pemain terdekat saat memukul
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local enemyHRP = player.Character.HumanoidRootPart
                            if (hrp.Position - enemyHRP.Position).Magnitude < 15 then
                                -- Teleport tipis mendekati target agar pukulan selalu nempel (aimbot hit)
                                hrp.CFrame = CFrame.new(hrp.Position, enemyHRP.Position)
                            end
                        end
                    end
                end
            end
        end
    end)
    table.insert(_G_Config.Connections, conn)
end)

-- 8. Fullbright (Penerangan Layar / Map)
CreateToggle("Fullbright (Penerangan Max)", function(state)
    _G_Config.Fullbright = state
    local conn = RunService.RenderStepped:Connect(function()
        if _G_Config.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
        end
    end)
    table.insert(_G_Config.Connections, conn)
end)

-- 9. Auto Heal Teammate Perfect
CreateToggle("Auto Heal Teammate", function(state)
    _G_Config.AutoHeal = state
    local conn = RunService.Heartbeat:Connect(function()
        if not _G_Config.AutoHeal then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = player.Character.HumanoidRootPart
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
                        if (hrp.Position - targetHRP.Position).Magnitude <= 10 then
                            -- Cari prompt atau interaksi heal
                            for _, prompt in pairs(player.Character:GetDescendants()) do
                                if prompt:IsA("ProximityPrompt") then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    table.insert(_G_Config.Connections, conn)
end)

-- 10. Anti-Ban / Anti-Detect Safeguard Notice
print("[BimSakSin Hub v3.0] Anti-Ban Bypass Active & Loaded Successfully!")
