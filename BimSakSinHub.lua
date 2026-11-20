--[[
    ============================================================
    ANTI-DETECT LIBRARY v2.0
    Untuk Roblox Executor (Synapse, Fluxus, Delta, KRNL, dll)
    Menyembunyikan aktivitas: Teleport, Fly, Speed, Noclip, ESP
    ============================================================
]]

local AntiDetect = {}
AntiDetect.__index = AntiDetect

-- ============================================================
-- KONFIGURASI
-- ============================================================
local CONFIG = {
    -- Sembunyikan instance executor dari game
    HideIdentity     = true,
    -- Spoof Humanoid State (agar tidak detect "Flying")
    SpoofHumanoid    = true,
    -- Delay teleport agar tidak loncat tiba-tiba (ms)
    TeleportDelay    = 50,
    -- Maksimum delta kecepatan per frame (studs)
    MaxSpeedDelta    = 15,
    -- Rotasi halus untuk fly (derajat/frame)
    FlySmooth        = 0.15,
    -- Auto-restore setelah disable
    AutoRestore      = true,
}

-- ============================================================
-- STATE
-- ============================================================
local Services = {
    Players       = game:GetService("Players"),
    RunService    = game:GetService("RunService"),
    Workspace     = game:GetService("Workspace"),
    UserInput     = game:GetService("UserInputService"),
    TweenService  = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera      = Services.Workspace.CurrentCamera

local State = {
    Enabled        = false,
    OriginalState  = {},
    OriginalWalk   = 16,
    OriginalJump   = 50,
    FlyActive      = false,
    SpeedActive    = false,
    Connections    = {},
}

-- ============================================================
-- UTIL
-- ============================================================
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getChar()
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = getChar()
    return char:FindFirstChildOfClass("Humanoid")
end

local function safeCall(fn, ...)
    -- pcalled call agar error tidak bocor ke game (detectable)
    local ok, res = pcall(fn, ...)
    return ok and res or nil
end

local function removeTag(inst, tag)
    if inst and inst:GetAttribute(tag) then
        inst:SetAttribute(tag, nil)
    end
end

-- ============================================================
-- 1. IDENTITY SPOOF
-- ============================================================
function AntiDetect:HideIdentity()
    if not CONFIG.HideIdentity then return end

    -- Simpan original
    State.OriginalState.getidentity = getidentity
    State.OriginalState.getthreadidentity = getthreadidentity

    -- Coba spoof (aman kalau fungsi ada)
    safeCall(function()
        if setthreadidentity then setthreadidentity(2) end -- 2 = LocalScript biasa
    end)

    -- Sembunyikan executor folder / global
    safeCall(function()
        if getgenv then
            getgenv().syn    = nil
            getgenv().KRNL_LOADED = nil
            getgenv().fluxus = nil
        end
    end)

    -- Re-register script untuk menyamarkan closure
    safeCall(function()
        local env = getfenv and getfenv() or _G
        if env and env.getfenv then
            -- override identity getter agar return normal
            env.getidentity = function() return 2 end
        end
    end)
end

-- ============================================================
-- 2. SPOOF HUMANOID STATE (Fly tidak ke-detect)
-- ============================================================
function AntiDetect:SpoofHumanoid()
    if not CONFIG.SpoofHumanoid then return end
    local hum = getHum()
    if not hum then return end

    State.OriginalState.humanoidState = hum:GetState()

    -- Saat fly: paksa state "Running" agar tidak "Flying/Freefall"
    local conn = hum.StateChanged:Connect(function(old, new)
        if State.FlyActive and (new == Enum.HumanoidStateType.Freefall
            or new == Enum.HumanoidStateType.Flying) then
            -- Tahan state "Running" palsu
            hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    table.insert(State.Connections, conn)

    -- Override property humanoid yang sering dicek
    safeCall(function()
        local mt = getrawmetatable(hum)
        if setreadonly then setreadonly(mt, false) end
        local oldIndex = mt.__index
        mt.__index = function(t, k)
            if State.FlyActive and k == "FloorMaterial" then
                return Enum.Material.Plastic -- paksa tidak nil
            end
            return oldIndex(t, k)
        end
        if setreadonly then setreadonly(mt, true) end
    end)
end

-- ============================================================
-- 3. ANTI-TELEPORT DETECT
-- ============================================================
--[[
    Menyembunyikan teleport dengan cara:
      - Tidak langsung set CFrame, tapi pakai TweenService (halus)
      - Delay antar langkah
      - Sinkron dengan render step
]]
function AntiDetect:Teleport(position, lookAt)
    local hrp = getHRP()
    if not hrp then return end

    local targetCF = lookAt and CFrame.new(position, lookAt) or CFrame.new(position)

    -- Kalau jarak jauh, gerakan bertahap (2-3 frame) agar tidak teleport instan
    local dist = (hrp.Position - position).Magnitude
    if dist > 100 then
        -- split jadi beberapa tween
        local steps = math.clamp(math.floor(dist / 100), 2, 6)
        local startPos = hrp.Position
        for i = 1, steps do
            local alpha = i / steps
            local midPos = startPos:Lerp(position, alpha)
            hrp.CFrame = CFrame.new(midPos) * (targetCF - targetCF.Position)
            task.wait(CONFIG.TeleportDelay / 1000)
        end
    else
        -- dekat, langsung tapi tween halus dalam 1 frame
        local tween = Services.TweenService:Create(
            hrp,
            TweenInfo.new(0.05, Enum.EasingStyle.Linear),
            { CFrame = targetCF }
        )
        tween:Play()
    end

    -- Bersihkan attribute sisa teleport
    removeTag(hrp, "Teleporting")
    removeTag(hrp, "AntiDetect_TP")
end

-- ============================================================
-- 4. FLY (Anti-Fly Detector)
-- ============================================================
function AntiDetect:StartFly(speed)
    self.FlyActive = true
    State.SpeedActive = true
    State.OriginalWalk = getHum() and getHum().WalkSpeed or 16

    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end

    speed = speed or 50

    -- Paksa velocity langsung ke HRP (bukan humanoid)
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.Name = "_AD_Fly"
    bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = hrp

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "_AD_Gyro"
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.P = 1e4
    bodyGyro.Parent = hrp

    -- Set humanoid state ke Running (spoof)
    hum:ChangeState(Enum.HumanoidStateType.Running)

    local flyConn = Services.RunService.RenderStepped:Connect(function()
        if not self.FlyActive or not hrp.Parent then return end

        local camCF = Camera.CFrame
        local moveDir = Vector3.zero

        if Services.UserInput:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            -- Batasi delta agar tidak terlihat seperti teleport
            local maxVel = speed
            moveDir = moveDir.Unit * maxVel
            -- smoothing
            bodyVel.Velocity = bodyVel.Velocity:Lerp(moveDir, CONFIG.FlySmooth)
        else
            bodyVel.Velocity = bodyVel.Velocity:Lerp(Vector3.zero, 0.3)
        end

        bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)

    table.insert(State.Connections, flyConn)

    -- Matikan physics humanoid agar tidak bentrok
    hum.PlatformStand = true
    -- Spoof agar humanoid "Running" terus
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
end

function AntiDetect:StopFly()
    self.FlyActive = false
    State.SpeedActive = false
    local hrp = getHRP()
    local hum = getHum()
    if not hrp then return end

    -- Hapus body movers
    for _, name in ipairs({"_AD_Fly", "_AD_Gyro"}) do
        local obj = hrp:FindFirstChild(name)
        if obj then obj:Destroy() end
    end

    if hum then
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:ChangeState(Enum.HumanoidStateType.Landed)
    end
end

-- ============================================================
-- 5. SPEED (Anti-Speed Detector)
-- ============================================================
function AntiDetect:SetWalkSpeed(speed)
    local hum = getHum()
    if not hum then return end
    State.OriginalWalk = hum.WalkSpeed
    hum.WalkSpeed = speed
end

-- ============================================================
-- 6. NOCLIP
-- ============================================================
function AntiDetect:EnableNoclip()
    local conn = Services.RunService.Stepped:Connect(function()
        local char = getChar()
        if not char then return end
        pcall(function()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end)
    table.insert(State.Connections, conn)
end

-- ============================================================
-- 7. CLEANUP
-- ============================================================
function AntiDetect:Cleanup()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}

    -- Restore identity
    safeCall(function()
        if getidentity and State.OriginalState.getidentity then
            _G.getidentity = State.OriginalState.getidentity
        end
    end)

    -- Stop fly kalau masih aktif
    if self.FlyActive then self:StopFly() end
end

-- ============================================================
-- 8. ENABLE / DISABLE
-- ============================================================
function AntiDetect:Enable()
    if State.Enabled then return self end
    State.Enabled = true
    self:HideIdentity()
    self:SpoofHumanoid()
    return self
end

function AntiDetect:Disable()
    if not State.Enabled then return self end
    State.Enabled = false
    if CONFIG.AutoRestore then
        self:Cleanup()
    end
    return self
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function AntiDetect:TeleportTo(pos, lookAt) return self:Teleport(pos, lookAt) end
function AntiDetect:Fly(speed)             return self:StartFly(speed) end
function AntiDetect:NoFly()                return self:StopFly() end
function AntiDetect:Speed(s)               return self:SetWalkSpeed(s) end
function AntiDetect:Noclip()               return self:EnableNoclip() end

return AntiDetect
