--// ==========================================
--// BimSakSin Hub - Ultimate District Pro
--// Compatible with Delta Executor
--// Modern Tabbed UI & Advanced District Features
--// ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
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
--// ANTI-DETECTION & ANTI-BAN BYPASSER (DISTRICT ADMIN)
--// ==========================================
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "Ban" or method == "SavePlace" then
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

--// ==========================================
--// UI MAIN FRAME (MODERN TABBED PANEL)
--// ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 440)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.BackgroundTransparency = 0.25 -- Semi-transparan gaya kaca modern
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Border RGB Berputar (Putih & Merah)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 2.5
MainStroke.Parent = MainFrame

--// ==========================================
--// TOP BAR (HEADER STYLE ALA ROBLOX SETTINGS)
--// ==========================================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 55)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 12)
TopBarFix.Position = UDim2.new(0, 0, 1, -12)
TopBarFix.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
TopBarFix.BackgroundTransparency = 0.2
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

-- Judul "BimSakSin Hub" Tepat di Tengah Atas (RGB Merah & Putih Halus)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 300, 1, 0)
TitleLabel.Position = UDim2.new(0.5, -150, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Parent = TopBar

-- Tombol Minimize (-) & Close (x) ala Chrome
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 35, 0, 35)
MinBtn.Position = UDim2.new(1, -80, 0, 10)
MinBtn.BackgroundTransparency = 1
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 22
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 22
CloseBtn.Parent = TopBar

--// ==========================================
--// TAB NAVIGATION BAR (VISUAL MENU STYLE)
--// ==========================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 35)
TabBar.Position = UDim2.new(0, 10, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local UIListTab = Instance.new("UIListLayout")
UIListTab.FillDirection = Enum.FillDirection.Horizontal
UIListTab.SortOrder = Enum.SortOrder.LayoutOrder
UIListTab.Padding = UDim.new(0, 8)
UIListTab.Parent = TabBar

local containers = {}
local function CreateTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 105, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.BackgroundTransparency = 0.3
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 13
    btn.Parent = TabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, -20, 1, -110)
    scrolling.Position = UDim2.new(0, 10, 0, 105)
    scrolling.BackgroundTransparency = 1
    scrolling.BorderSizePixel = 0
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 650)
    scrolling.ScrollBarThickness = 4
    scrolling.Visible = false
    scrolling.Parent = MainFrame

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = scrolling

    table.insert(containers, {Button = btn, Frame = scrolling})
    return scrolling
end

local TabVisual = CreateTabButton("Visuals (ESP)")
local TabPlayer = CreateTabButton("Player / Char")
local TabGame   = CreateTabButton("District Tools")
local TabMisc   = CreateTabButton("Settings")

-- Sistem Tab Switcher
for _, tabData in ipairs(containers) do
    tabData.Button.MouseButton1Click:Connect(function()
        for _, t in ipairs(containers) do
            t.Frame.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        end
        tabData.Frame.Visible = true
        tabData.Button.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    end)
end
TabVisual.Visible = true
containers[1].Button.BackgroundColor3 = Color3.fromRGB(168, 85, 247)

--// ==========================================
--// FLOATING TOGGLE (SAAT DI-MINIMIZE)
--// ==========================================
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 190, 0, 46)
FloatingToggle.Position = UDim2.new(0, 30, 0, 30)
FloatingToggle.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
FloatingToggle.BackgroundTransparency = 0.3
FloatingToggle.Visible = false
FloatingToggle.Active = true
FloatingToggle.Draggable = true
FloatingToggle.Font = Enum.Font.GothamBold
FloatingToggle.Text = "BimSakSin Hub"
FloatingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingToggle.TextSize = 15
FloatingToggle.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 23)
FloatCorner.Parent = FloatingToggle

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(255, 255, 255)
FloatStroke.Thickness = 2.5
FloatStroke.Parent = FloatingToggle

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
--// ANIMASI RGB HALUS (MERAH & PUTIH) & ROTASI STROKE
--// ==========================================
task.spawn(function()
    local redColor = Color3.fromRGB(255, 40, 40)
    local whiteColor = Color3.fromRGB(255, 255, 255)
    while ScreenGui and ScreenGui.Parent do
        local t1 = (math.sin(tick() * 3.5) + 1) / 2
        local textBlended = redColor:Lerp(whiteColor, t1)
        
        local t2 = (math.cos(tick() * 3.5) + 1) / 2
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
--// HELPER PEMBUAT TOMBOL & SLIDER MENU
--// ==========================================
local function CreateToggle(parentTab, name, callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 0, 42)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    ToggleBtn.BackgroundTransparency = 0.3
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Font = Enum.Font.GothamMedium
    ToggleBtn.Text = "  " .. name
    ToggleBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
    ToggleBtn.TextSize = 13
    ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    ToggleBtn.Parent = parentTab

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleBtn

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(70, 70, 100)
    Stroke.Thickness = 1
    Stroke.Parent = ToggleBtn

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0, 80, 1, 0)
    StatusLabel.Position = UDim2.new(1, -85, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.Text = "[ OFF ]"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 12
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatusLabel.Parent = ToggleBtn

    local enabled = false
    ToggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            StatusLabel.Text = "[ ON ]"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
            Stroke.Color = Color3.fromRGB(255, 60, 60)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
        else
            StatusLabel.Text = "[ OFF ]"
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            Stroke.Color = Color3.fromRGB(70, 70, 100)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        end
        pcall(function()
            callback(enabled)
        end)
    end)
end

--// ==========================================
--// KUMPULAN FITUR-FITUR LENGKAP & STABIL
--// ==========================================

-- TAB 1: VISUALS (ESP PLAYER + KILLER JARAK)
local ESPEnabled = false
local function ToggleESP(state)
    ESPEnabled = state
    local function applyESP(player)
        if player == LocalPlayer then return end
        local function addVisuals(char)
            if not char:FindFirstChild("BimSakSinESP") then
                -- Deteksi apakah pemain adalah Killer / Lawan (Berdasarkan nama team/role atau atribut)
                local isKiller = false
                pcall(function()
                    if player.Team and string.lower(player.Team.Name):find("killer") then
                        isKiller =arger
                    end
                end)
                
                local hl = Instance.new("Highlight")
                hl.Name = "BimSakSinESP"
                hl.Adornee = char
                -- Killer wajib warna Merah Terang, Survivor warna ungu/putih
                hl.FillColor = isKiller and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(168, 85, 247)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = char

                local bill = Instance.new("BillboardGui")
                bill.Name = "ESPInfo"
                bill.Size = UDim2.new(0, 150, 0, 50)
                bill.StudsOffset = Vector3.new(0, 3, 0)
                bill.AlwaysOnTop = true
                bill.Parent = char

                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.Font = Enum.Font.GothamBold
                text.TextSize = 12
                text.TextColor3 = isKiller and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
                text.TextStrokeTransparency = 0
                text.Parent = bill

                task.spawn(function()
                    while char and char.Parent and player and player.Character do
                        pcall(function()
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
                                text.Text = player.Name .. "\n[" .. dist .. "m]"
                            end
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
        if player.Character and ESPEnabled then addVisuals(player.Character) end
        player.CharacterAdded:Connect(function(c)
            if ESPEnabled then task.wait(1) addVisuals(c) end
        end)
    end

    if ESPEnabled then
        for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("BimSakSinESP") then p.Character.BimSakSinESP:Destroy() end
            if p.Character and p.Character:FindFirstChild("ESPInfo") then p.Character.ESPInfo:Destroy() end
        end
    end
end
CreateToggle(TabVisual, "Player & Killer ESP (Name + Dist)", ToggleESP)

-- ESP GENERATOR & JARAK
local GenESPEnabled = false
CreateToggle(TabVisual, "ESP Generator + Jarak", function(state)
    GenESPEnabled = state
    task.spawn(function()
        while GenESPEnabled do
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if string.lower(obj.Name):find("generator") or string.lower(obj.Name):find("gen") then
                        if obj:IsA("BasePart") and not obj:FindFirstChild("GenESP") then
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "GenESP"
                            bill.Size = UDim2.new(0, 100, 0, 40)
                            bill.AlwaysOnTop = true
                            bill.Parent = obj

                            local txt = Instance.new("TextLabel")
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.Font = Enum.Font.GothamBold
                            txt.TextColor3 = Color3.fromRGB(255, 255, 0)
                            txt.TextSize = 11
                            txt.TextStrokeTransparency = 0
                            txt.Parent = bill

                            task.spawn(function()
                                while obj and obj.Parent and GenESPEnabled do
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        local d = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude)
                                        txt.Text = "Generator\n[" .. d .. "m]"
                                    end
                                    task.wait(1)
                                end
                            end)
                        end
                    end
                end
            end)
            task.wait(3)
        end
        -- Hapus jika dimatikan
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:FindFirstChild("GenESP") then obj.GenESP:Destroy() end
        end
    end)
end)


-- TAB 2: PLAYER / CHAR (SPEED, JUMP, FLY, GODMODE, NOCLIP)
CreateToggle(TabPlayer, "Speed Hack (WalkSpeed 50)", function(state)
    pcall(function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = state and 50 or 16 end
    end)
end)

CreateToggle(TabPlayer, "Super Jump (JumpPower 100)", function(state)
    pcall(function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower = true h.JumpPower = state and 100 or 50 end
    end)
end)

-- FLY HACK HALUS DENGAN KONTROL KECEPATAN
local Flying = false
local FlySpeed = 50
local BodyGyro, BodyVelocity
CreateToggle(TabPlayer, "Smooth Fly Hack (Terbang Halus)", function(state)
    Flying = state
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if Flying and root and hum then
            hum.PlatformStand = true
            BodyGyro = Instance.new("BodyGyro")
            BodyGyro.P = 9e4
            BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BodyGyro.CFrame = root.CFrame
            BodyGyro.Parent = root

            BodyVelocity = Instance.new("BodyVelocity")
            BodyVelocity.Velocity = Vector3.new(0, 0, 0)
            BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            BodyVelocity.Parent = root

            task.spawn(function()
                while Flying and root and hum and hum.Health > 0 do
                    local cam = Camera.CFrame
                    local dir = Vector3.new()
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
                    BodyVelocity.Velocity = dir * FlySpeed
                    BodyGyro.CFrame = cam
                    RunService.RenderStepped:Wait()
                end
                if BodyGyro then BodyGyro:Destroy() end
                if BodyVelocity then BodyVelocity:Destroy() end
                if hum then hum.PlatformStand = false end
            end)
        else
            if BodyGyro then BodyGyro:Destroy() end
            if BodyVelocity then BodyVelocity:Destroy() end
            if hum then hum.PlatformStand = false end
        end
    end)
end)

-- KEBAL / GODMODE (TERHADAP PUKULAN / KILLER)
local GodModeConn = nil
CreateToggle(TabPlayer, "Kebal Pukulan / GodMode", function(state)
    if state then
        GodModeConn = RunService.Stepped:Connect(function()
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.MaxHealth = math.huge
                    hum.Health = math.huge
                end
            end)
        end)
    else
        if GodModeConn then GodModeConn:Disconnect() GodModeConn = nil end
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.MaxHealth = 100 hum.Health = 100 end
        end)
    end
end)

-- NOCLIP (TEMBUS TEMBOK MAP)
local NoclipConn = nil
CreateToggle(TabPlayer, "Noclip (Tembus Tembok)", function(state)
    if state then
        NoclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                if LocalPlayer.Character then
                    for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                    end
                end
            end)
        end)
    else
        if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
    end
end)


-- TAB 3: DISTRICT TOOLS (AUTO PERFECT GEN, ANTI HOOK, TELEPORT)

-- AUTO PERFECT GENERATOR
CreateToggle(TabGame, "Auto Perfect Generator", function(state)
    task.spawn(function()
        while state do
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if string.lower(obj.Name):find("generator") or string.lower(obj.Name):find("gen") then
                        -- Simulasi interaksi cepat / bypass mini game generator
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end)

-- ANTI HOOK (MELARIKAN DIRI SENDIRI SAAT DIGANTUNG)
CreateToggle(TabGame, "Anti Hook (Auto Escape Gantung)", function(state)
    task.spawn(function()
        while state do
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and char:FindFirstChild("Humanoid") then
                    -- Jika tersangkut / digantung (biasanya di-parent ke hook atau platform stand aktif)
                    if char.Humanoid.PlatformStand then
                        char.Humanoid.PlatformStand = false
                        root.CFrame = root.CFrame + Vector3.new(0, 5, 0) -- Teleport lepas ke atas
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end)

-- TELEPORT KE PEMAIN / KILLER TERDEKAT
CreateToggle(TabGame, "Teleport ke Player Terdekat", function(state)
    if state then
        pcall(function()
            local targetPos = nil
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        targetPos = p.Character.HumanoidRootPart.CFrame
                    end
                end
            end
            if targetPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPos + Vector3.new(0, 3, 0)
            end
        end)
    end
end)


-- TAB 4: SETTINGS & MISC (ANTI-LAG, TRANSPARAN PANEL)

-- ANTI-LAG / STUCK OPTIMIZER
CreateToggle(TabMisc, "Anti-Lag & Stuck Fixer", function(state)
    if state then
        pcall(function()
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("Sky") then v.Enabled = false end
            end
            Lighting.GlobalShadows = false
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.SmoothPlastic
                    part.Reflectance = 0
                end
            end
        end)
    end
end)

-- TRANSPARAN PANEL
CreateToggle(TabMisc, "Transparan Panel Toggle", function(state)
    pcall(function()
        MainFrame.BackgroundTransparency = state and 0.65 or 0.25
        TopBar.BackgroundTransparency = state and 0.6 or 0.2
        TopBarFix.BackgroundTransparency = state and 0.6 or 0.2
    end)
end)

print("BimSakSin Hub District Edition Loaded Successfully!")
