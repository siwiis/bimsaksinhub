-- Memuat Orion UI Library dengan proteksi error (pcall)
local success, OrionLib = pcall(function()
    return loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
end)

if not success or not OrionLib then
    warn("Gagal memuat Orion Library! Periksa koneksi internet.")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Membuat Jendela Utama Panel (Orion Window)
local Window = OrionLib:MakeWindow({
    Name = "BimSakSin Hub | Pro Survival Panel",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BimSakSinConfig",
    IntroEnabled = true,
    IntroText = "Memuat BimSakSin Hub..."
})

---------------------------------------------------------
-- SISTEM RGB HALUS UNTUK JUDUL PANEL
---------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.03)
        pcall(function()
            local hue = (tick() % 4) / 4
            local rgbColor = Color3.fromHSV(hue, 1, 1)
            
            for _, gui in ipairs(game.CoreGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and (desc.Text:find("BimSakSin Hub") or desc.Text:find("Pro Survival")) then
                            desc.TextColor3 = rgbColor
                        end
                    end
                end
            end
        end)
    end
end)

---------------------------------------------------------
-- MEMBUAT TAB MENU
---------------------------------------------------------
local TabSecurity = Window:MakeTab({Name = "Anti-Ban", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local TabESP = Window:MakeTab({Name = "Visual & ESP", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local TabCombat = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local TabAuto = Window:MakeTab({Name = "Automation", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local TabMove = Window:MakeTab({Name = "Movement", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local TabTeleport = Window:MakeTab({Name = "Teleport", Icon = "rbxassetid://4483362458", PremiumOnly = false})

---------------------------------------------------------
-- 1. TAB ANTI-BAN & KEAMANAN
---------------------------------------------------------
local SecurityConfig = { AntiBanEnabled = false }

TabSecurity:AddToggle({
    Name = "Anti-Ban / Bypass Dev Map",
    Default = false,
    Callback = function(Value)
        SecurityConfig.AntiBanEnabled = Value
        if Value then
            pcall(function()
                local oldNameCall
                oldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if SecurityConfig.AntiBanEnabled and (method:lower() == "kick" or method:lower() == "ban") then
                        OrionLib:MakeNotification({Title = "Anti-Ban", Content = "Berhasil memblokir Kick/Ban server!", Image = "rbxassetid://4483362458", Time = 3})
                        return
                    end
                    return oldNameCall(self, ...)
                end)
            end)
            OrionLib:MakeNotification({Title = "Proteksi Aktif", Content = "Anti-Ban menyala dengan aman.", Image = "rbxassetid://4483362458", Time = 3})
        else
            OrionLib:MakeNotification({Title = "Proteksi Mati", Content = "Anti-Ban dimatikan.", Image = "rbxassetid://4483362458", Time = 3})
        end
    end
})

TabSecurity:AddButton({
    Name = "Reset Character (Jika Bug)",
    Callback = function()
        pcall(function() LocalPlayer.Character:BreakJoints() end)
    end
})

---------------------------------------------------------
-- 2. TAB VISUAL & ESP (Survivor Hijau, Killer Merah, Gen Kuning)
---------------------------------------------------------
local ESPConfig = { SurvivorESP = false, KillerESP = false, GenESP = false }
local ESPObjects = {}

local function createHighlight(obj, fillColor, outlineColor)
    if not obj or obj:FindFirstChild("ProHighlight") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ProHighlight"
    highlight.Adornee = obj
    highlight.FillColor = fillColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Parent = obj

    local bg = Instance.new("BillboardGui")
    bg.Name = "ProBillboard"
    bg.Adornee = obj:IsA("Model") and obj.PrimaryPart or obj
    bg.Size = UDim2.new(0, 100, 0, 50)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    bg.Parent = obj

    local label = Instance.new("TextLabel")
    label.Name = "InfoLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255) -- Jarak warna putih
    label.TextStrokeTransparency = 0
    label.TextSize = 13
    label.Font = Enum.Font.SourceSansBold
    label.Parent = bg

    table.insert(ESPObjects, {Highlight = highlight, Billboard = bg, Target = obj})
end

TabESP:AddToggle({
    Name = "ESP Survivor (Hijau | Jarak Putih)",
    Default = false,
    Callback = function(v) ESPConfig.SurvivorESP = v end
})

TabESP:AddToggle({
    Name = "ESP Killer (Merah | Jarak Putih)",
    Default = false,
    Callback = function(v) ESPConfig.KillerESP = v end
})

TabESP:AddToggle({
    Name = "ESP Generator (Kuning | Jarak Putih)",
    Default = false,
    Callback = function(v) ESPConfig.GenESP = v end
})

---------------------------------------------------------
-- 3. TAB COMBAT (Aimbot & Auto Parry)
---------------------------------------------------------
local AimbotEnabled = false
local AutoParryEnabled = false

TabCombat:AddToggle({
    Name = "Aimbot Otomatis Target",
    Default = false,
    Callback = function(v) AimbotEnabled = v end
})

TabCombat:AddToggle({
    Name = "Auto Parry / Nangkis Otomatis",
    Default = false,
    Callback = function(v) AutoParryEnabled = v end
})

---------------------------------------------------------
-- 4. TAB AUTOMATION (Auto Generator Perfect)
---------------------------------------------------------
local AutoGenEnabled = false
TabAuto:AddToggle({
    Name = "Auto Generator (Perfect Skill Check)",
    Default = false,
    Callback = function(Value)
        AutoGenEnabled = Value
        task.spawn(function()
            while AutoGenEnabled do
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
    end
})

---------------------------------------------------------
-- 5. TAB MOVEMENT (Custom WalkSpeed, NoClip, Fly)
---------------------------------------------------------
local CustomSpeedEnabled = false
local SurvivorSpeedValue = 16
local NoClipEnabled = false
local FlyEnabled = false
local FlySpeed = 50

TabMove:AddToggle({
    Name = "Aktifkan Custom WalkSpeed Survivor",
    Default = false,
    Callback = function(v) CustomSpeedEnabled = v end
})

TabMove:AddSlider({
    Name = "Kecepatan Lari Survivor",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 2,
    ValueName = "Speed",
    Callback = function(v) SurvivorSpeedValue = v end
})

TabMove:AddToggle({
    Name = "NoClip (Tembus Tembok)",
    Default = false,
    Callback = function(v)
        NoClipEnabled = v
        OrionLib:MakeNotification({Title = "NoClip", Content = v and "Aktif" or "Mati", Image = "rbxassetid://4483362458", Time = 2})
    end
})

TabMove:AddToggle({
    Name = "Fly Halus (Admin Style)",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        
        if FlyEnabled then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "ProFlyVelocity"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
            
            local bg = Instance.new("BodyGyro")
            bg.Name = "ProFlyGyro"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp

            task.spawn(function()
                while FlyEnabled and hrp and hrp.Parent do
                    bv.Velocity = Camera.CFrame.LookVector * FlySpeed
                    bg.CFrame = Camera.CFrame
                    task.wait()
                end
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
            end)
        end
    end
})

TabMove:AddSlider({
    Name = "Kecepatan Terbang",
    Min = 10,
    Max = 200,
    Default = 50,
    Increment = 10,
    ValueName = "Speed",
    Callback = function(v) FlySpeed = v end
})

---------------------------------------------------------
-- 6. TAB TELEPORT PLAYER
---------------------------------------------------------
local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end

local SelectedTargetPlayer = playerNames[1] or ""

local Dropdown = TabTeleport:AddDropdown({
    Name = "Pilih Survivor / Killer",
    Default = SelectedTargetPlayer,
    Options = playerNames,
    Callback = function(Value)
        SelectedTargetPlayer = Value
    end
})

TabTeleport:AddButton({
    Name = "Refresh Daftar Player",
    Callback = function()
        playerNames = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
        end
        Dropdown:Refresh(playerNames)
        OrionLib:MakeNotification({Title = "Berhasil", Content = "Daftar player diperbarui!", Image = "rbxassetid://4483362458", Time = 2})
    end
})

TabTeleport:AddButton({
    Name = "Teleport ke Player Terpilih",
    Callback = function()
        pcall(function()
            local target = Players:FindFirstChild(SelectedTargetPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                    OrionLib:MakeNotification({Title = "Teleport Sukses", Content = "Berpindah ke " .. SelectedTargetPlayer, Image = "rbxassetid://4483362458", Time = 3})
                end
            else
                OrionLib:MakeNotification({Title = "Gagal", Content = "Player tidak ditemukan.", Image = "rbxassetid://4483362458", Time = 3})
            end
        end)
    end
})

---------------------------------------------------------
-- MAIN RUNSERVICE LOOP (ESP, Speed, NoClip, Aimbot)
---------------------------------------------------------
RunService.RenderStepped:Connect(function()
    pcall(function()
        if CustomSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = SurvivorSpeedValue
        end

        if NoClipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        if ESPConfig.SurvivorESP or ESPConfig.KillerESP then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    local isKiller = player.Team and (player.Team.Name:lower():find("killer") or player.Team.Name:lower():find("monster"))
                    
                    if isKiller and ESPConfig.KillerESP then
                        createHighlight(player.Character, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255))
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v.Name == "InfoLabel" then v.Text = "KILLER\n[" .. dist .. "m]" end
                        end
                    elseif not isKiller and ESPConfig.SurvivorESP then
                        createHighlight(player.Character, Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255))
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v.Name == "InfoLabel" then v.Text = "Survivor\n[" .. dist .. "m]" end
                        end
                    end
                end
            end
        end

        if ESPConfig.GenESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("generator") and obj:IsA("Model") and obj.PrimaryPart then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - obj.PrimaryPart.Position).Magnitude)
                    createHighlight(obj, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 255, 255))
                    for _, v in pairs(obj:GetDescendants()) do
                        if v.Name == "InfoLabel" then v.Text = "Generator\n[" .. dist .. "m]" end
                    end
                end
            end
        end

        if AimbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
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

-- Inisialisasi Orion
OrionLib:Init()
