-- Memuat Rayfield UI Library (Anti-Block Delta)
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Gagal memuat Rayfield UI!")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Membuat Jendela Utama Panel
local Window = Rayfield:CreateWindow({
   Name = "BimSakSin Hub | Pro Survival Panel",
   LoadingTitle = "Memuat BimSakSin Hub...",
   LoadingSubtitle = "By Bima Sakti - RGB Edition",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BimSakSinConfig",
      FileName = "UltimateHub"
   },
   Discord = { Enabled = false },
   KeySystem = false,
})

---------------------------------------------------------
-- SISTEM RGB HALUS UNTUK JUDUL & TOMBOL MINIMIZE
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
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                            if desc.Text == "Show Rayfield" or desc.Text:find("Show Rayfield") then
                                desc.Text = "BimSakSin Hub"
                                desc.TextColor3 = rgbColor
                            elseif desc.Text:find("BimSakSin Hub") or desc.Text:find("Pro Survival") then
                                desc.TextColor3 = rgbColor
                            end
                        end
                    end
                end
            end
        end)
    end
end)

---------------------------------------------------------
-- TAB 1: SECURITY & ANTI-BAN
---------------------------------------------------------
local TabSecurity = Window:CreateTab("Anti-Ban", 4483362458)
local SecurityConfig = { AntiBanEnabled = false }

TabSecurity:CreateToggle({
   Name = "Anti-Ban / Bypass Deteksi Dev Map",
   CurrentValue = false,
   Callback = function(Value)
      SecurityConfig.AntiBanEnabled = Value
      if Value then
          pcall(function()
              local oldNameCall
              oldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
                  local method = getnamecallmethod()
                  if SecurityConfig.AntiBanEnabled and (method:lower() == "kick" or method:lower() == "ban") then
                      Rayfield:Notify({Title = "Anti-Ban Aktif", Content = "Berhasil memblokir Kick/Ban server!", Duration = 3})
                      return
                  end
                  return oldNameCall(self, ...)
              end)
          end)
          Rayfield:Notify({Title = "Proteksi Nyala", Content = "Sistem Anti-Ban & Bypass aktif!", Duration = 3})
      else
          Rayfield:Notify({Title = "Proteksi Mati", Content = "Anti-Ban dimatikan.", Duration = 3})
      end
   end,
})

TabSecurity:CreateButton({
   Name = "Reset Character / Bersihkan Error",
   Callback = function()
      pcall(function() LocalPlayer.Character:BreakJoints() end)
   end,
})

---------------------------------------------------------
-- TAB 2: VISUAL & ESP (Survivor, Killer, Generator)
---------------------------------------------------------
local TabESP = Window:CreateTab("Visual & ESP", 4483362458)
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
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.Parent = bg

    table.insert(ESPObjects, {Highlight = highlight, Billboard = bg, Target = obj})
end

TabESP:CreateToggle({
   Name = "ESP Survivor (Hijau | Jarak Putih)",
   CurrentValue = false,
   Callback = function(Value) ESPConfig.SurvivorESP = Value end,
})

TabESP:CreateToggle({
   Name = "ESP Killer / Monster (Merah | Jarak Putih)",
   CurrentValue = false,
   Callback = function(Value) ESPConfig.KillerESP = Value end,
})

TabESP:CreateToggle({
   Name = "ESP Generator (Kuning | Jarak Putih)",
   CurrentValue = false,
   Callback = function(Value) ESPConfig.GenESP = Value end,
})

---------------------------------------------------------
-- TAB 3: COMBAT (Aimbot & Auto Parry)
---------------------------------------------------------
local TabCombat = Window:CreateTab("Combat & Aim", 4483362458)
local AimbotEnabled = false
local AutoParryEnabled = false

TabCombat:CreateToggle({
   Name = "Aimbot Otomatis (Target Survivor/Killer)",
   CurrentValue = false,
   Callback = function(Value) AimbotEnabled = Value end,
})

TabCombat:CreateToggle({
   Name = "Auto Parry / Nangkis Serangan Otomatis",
   CurrentValue = false,
   Callback = function(Value) AutoParryEnabled = Value end,
})

---------------------------------------------------------
-- TAB 4: AUTOMATION (Auto Generator Perfect)
---------------------------------------------------------
local TabAuto = Window:CreateTab("Automation", 4483362458)

TabAuto:CreateToggle({
   Name = "Auto Generator (Selalu Perfect Skill Check)",
   CurrentValue = false,
   Callback = function(Value)
      ESPConfig.AutoGenerator = Value
      task.spawn(function()
          while ESPConfig.AutoGenerator do
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
   end,
})

---------------------------------------------------------
-- TAB 5: MOVEMENT (Custom Speed Survivor, NoClip, Fly)
---------------------------------------------------------
local TabMove = Window:CreateTab("Movement", 4483362458)
local CustomSpeedEnabled = false
local SurvivorSpeedValue = 16
local NoClipEnabled = false
local FlyEnabled = false
local FlySpeed = 50

TabMove:CreateToggle({
   Name = "Aktifkan Custom Kecepatan Survivor",
   CurrentValue = false,
   Callback = function(Value) CustomSpeedEnabled = Value end,
})

TabMove:CreateSlider({
   Name = "Atur Kecepatan Lari Survivor",
   Range = {16, 100},
   Increment = 2,
   Suffix = "WalkSpeed",
   CurrentValue = 16,
   Callback = function(Value) SurvivorSpeedValue = Value end,
})

TabMove:CreateToggle({
   Name = "NoClip (Tembus Tembok / Objek)",
   CurrentValue = false,
   Callback = function(Value)
      NoClipEnabled = Value
      Rayfield:Notify({Title = "NoClip Status", Content = Value and "Aktif (Tembus Tembok)" or "Mati", Duration = 2})
   end,
})

TabMove:CreateToggle({
   Name = "Fly Halus (Admin Developer Style)",
   CurrentValue = false,
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
   end,
})

TabMove:CreateSlider({
   Name = "Kecepatan Terbang (Fly Speed)",
   Range = {10, 200},
   Increment = 10,
   Suffix = "Speed",
   CurrentValue = 50,
   Callback = function(Value) FlySpeed = Value end,
})

---------------------------------------------------------
-- TAB 6: TELEPORT MENU (Pilih Nama Player)
---------------------------------------------------------
local TabTeleport = Window:CreateTab("Teleport Player", 4483362458)
local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end

local SelectedTargetPlayer = playerNames[1] or ""
local PlayerDropdown = TabTeleport:CreateDropdown({
   Name = "Pilih Survivor / Killer Tujuan",
   Options = playerNames,
   CurrentOption = SelectedTargetPlayer,
   Flag = "TeleportPlayerDropdown",
   Callback = function(Option) SelectedTargetPlayer = Option end,
})

TabTeleport:CreateButton({
   Name = "Refresh Daftar Nama Player",
   Callback = function()
      playerNames = {}
      for _, p in ipairs(Players:GetPlayers()) do
          if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
      end
      PlayerDropdown:Refresh(playerNames)
      Rayfield:Notify({Title = "Berhasil", Content = "Daftar player diperbarui!", Duration = 2})
   end,
})

TabTeleport:CreateButton({
   Name = "Teleport ke Player Terpilih",
   Callback = function()
      pcall(function()
          local target = Players:FindFirstChild(SelectedTargetPlayer)
          if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
              if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                  LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                  Rayfield:Notify({Title = "Teleport Sukses", Content = "Berpindah ke " .. SelectedTargetPlayer, Duration = 3})
              end
          else
              Rayfield:Notify({Title = "Gagal", Content = "Player tidak ditemukan atau mati.", Duration = 3})
          end
      end)
   end,
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

Rayfield:LoadConfiguration()
