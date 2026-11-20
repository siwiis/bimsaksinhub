--[[
    ============================================================
    ANTI-DETECT LIBRARY v2.1 (FINAL - FULL VERSION)
    ============================================================
    - HideIdentity
    - SpoofHumanoid (metatable FloorMaterial)
    - Teleport (smooth / tween, anti-detect tag)
    - Fly (BodyVelocity + BodyGyro, multi-input)
    - Speed
    - Noclip
    - Mobile Virtual Stick (keyboard + gamepad + touch unified)
    - Helper API: AntiDetect.new(), :Enable(), :Disable(), dsb.
]]

local AntiDetect = {}
AntiDetect.__index = AntiDetect

----------------------------------------------------------------
-- KONFIGURASI
----------------------------------------------------------------
local CONFIG = {
    HideIdentity     = true,
    SpoofHumanoid    = true,
    TeleportDelay    = 50,      -- ms per tween step
    FlySmooth        = 0.15,
    AutoRestore      = true,
    TouchSensitivity = 0.8,
    EnableMultiInput = true,    -- keyboard + gamepad + mobile
}

----------------------------------------------------------------
-- SERVICES & GUARD
----------------------------------------------------------------
local function svc(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    return ok and s or nil
end

local Players      = svc("Players")
local RunService   = svc("RunService")
local Workspace    = svc("Workspace")
local UIS          = svc("UserInputService")
local TweenService = svc("TweenService")
local GuiService   = svc("GuiService")

local LocalPlayer = Players and Players.LocalPlayer

if not LocalPlayer then
    warn("[AntiDetect] Tidak ada LocalPlayer. Jalankan dari executor/Studio.")
    return AntiDetect
end

local State = {
    Enabled             = false,
    FlyActive           = false,
    SpeedActive         = false,
    OriginalWalk        = 16,
    Connections         = {},
    NoclipOn            = false,
    NoclipParts         = {},       -- [part] = true
    HumanoidMT          = nil,
    HumanoidOwner       = nil,
    FlyFreefallDisabled = false,
    TouchMove           = Vector2.zero,
    StickGui            = nil,
    StickConn           = nil,
    StickConns          = {},       -- kumpulan koneksi mobile stick
    NoclipConn          = nil,
}

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok and res or nil
end

local function removeTag(inst, tag)
    if inst and inst.GetAttribute and inst:GetAttribute(tag) then
        pcall(function() inst:SetAttribute(tag, nil) end)
    end
end

local function safeGetRawMeta(inst)
    if not (getrawmetatable and type(setreadonly) == "function") then
        return nil
    end
    local ok, mt = pcall(getrawmetatable, inst)
    return ok and mt or nil
end

-- Baca input gabungan (keyboard + gamepad + mobile)
local function readInputVector(camCF)
    local dir = Vector3.zero
    if not UIS then return dir end

    -- Keyboard
    pcall(function()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift)
            or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir -= Vector3.yAxis
        end
    end)

    -- Gamepad
    if CONFIG.EnableMultiInput then
        local ok, pad = pcall(function()
            return UIS:GetGamepadState(Enum.UserInputType.Gamepad1)
        end)
        if ok and pad then
            for _, b in ipairs(pad) do
                if b.KeyCode == Enum.KeyCode.Thumbstick1 then
                    dir += camCF.LookVector * b.Position.Y
                    dir += camCF.RightVector * b.Position.X
                elseif b.KeyCode == Enum.KeyCode.Thumbstick2 then
                    dir += Vector3.new(0, b.Position.Y, 0)
                end
            end
        end
    end

    -- Mobile
    if State.TouchMove.Magnitude > 0.05 then
        local tv = State.TouchMove * CONFIG.TouchSensitivity
        dir += camCF.LookVector * tv.Y
        dir += camCF.RightVector * tv.X
    end

    return dir
end

local function disconnectAll()
    for i = #State.Connections, 1, -1 do
        local c = State.Connections[i]
        if c and c.Disconnect then
            pcall(function() c:Disconnect() end)
        end
        State.Connections[i] = nil
    end
    State.Connections = {}
end

----------------------------------------------------------------
-- 1. IDENTITY SPOOF
----------------------------------------------------------------
function AntiDetect:HideIdentity()
    if not CONFIG.HideIdentity then return end
    safeCall(function()
        if type(setthreadidentity) == "function" then
            setthreadidentity(2)
        end
    end)
    safeCall(function()
        if type(getgenv) == "function" then
            local g = getgenv()
            if g then
                g.syn = nil
                g.fluxus = nil
                g.KRNL_LOADED = nil
            end
        end
    end)
end

----------------------------------------------------------------
-- 2. SPOOF HUMANOID
----------------------------------------------------------------
function AntiDetect:SpoofHumanoid()
    if not CONFIG.SpoofHumanoid then return end
    local hum = getHum()
    if not hum then return end

    local conn = hum.StateChanged:Connect(function(_o, new)
        if not State.FlyActive then return end
        if new == Enum.HumanoidStateType.Freefall
            or new == Enum.HumanoidStateType.Flying then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end)
    table.insert(State.Connections, conn)

    local mt = safeGetRawMeta(hum)
    if mt and type(mt.__index) == "function" then
        local owner = hum
        local oldIndex = mt.__index
        local unlocked = pcall(function() setreadonly(mt, false) end)

        mt.__index = function(t, k)
            if t == owner and State.FlyActive and k == "FloorMaterial" then
                return Enum.Material.Plastic
            end
            local okv, v = pcall(oldIndex, t, k)
            if okv then return v end
            return rawget(t, k)
        end
        if unlocked then pcall(function() setreadonly(mt, true) end) end

        State.HumanoidMT    = mt
        State.HumanoidOwner = owner
    end
end

----------------------------------------------------------------
-- 3. TELEPORT
----------------------------------------------------------------
function AntiDetect:Teleport(position, lookAt)
    local hrp = getHRP()
    if not hrp or typeof(position) ~= "Vector3" then return end

    local targetCF = lookAt and CFrame.new(position, lookAt) or CFrame.new(position)
    local dist = (hrp.Position - position).Magnitude

    if dist > 100 then
        local steps = math.clamp(math.floor(dist / 100) + 1, 2, 6)
        local startPos = hrp.Position
        local rot = hrp.CFrame - hrp.CFrame.Position
        for i = 1, steps do
            local a = i / steps
            local mid = startPos:Lerp(position, a)
            if not hrp.Parent then break end
            hrp.CFrame = CFrame.new(mid) * rot
            task.wait(CONFIG.TeleportDelay / 1000)
        end
        if hrp.Parent then
            hrp.CFrame = targetCF
        end
    else
        local ok, t = pcall(function()
            return TweenService:Create(
                hrp,
                TweenInfo.new(0.05, Enum.EasingStyle.Linear),
                { CFrame = targetCF })
        end)
        if ok and t then
            t:Play()
        else
            hrp.CFrame = targetCF
        end
    end

    removeTag(hrp, "Teleporting")
    removeTag(hrp, "AntiDetect_TP")
end

----------------------------------------------------------------
-- 4. FLY
----------------------------------------------------------------
function AntiDetect:StartFly(speed)
    if State.FlyActive then return end
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end

    speed = speed or 50
    State.OriginalWalk = hum.WalkSpeed
    State.FlyActive = true
    State.SpeedActive = true

    -- Bersihkan sisa BodyMover lama (kalau ada)
    for _, o in ipairs(hrp:GetChildren()) do
        if o.Name == "_AD_Fly" or o.Name == "_AD_Gyro" then
            pcall(function() o:Destroy() end)
        end
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "_AD_Fly"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local gy = Instance.new("BodyGyro")
    gy.Name = "_AD_Gyro"
    gy.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    gy.P = 1e4
    gy.Parent = hrp

    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        State.FlyFreefallDisabled = true
    end)

    local conn = RunService.RenderStepped:Connect(function()
        if not State.FlyActive or not hrp.Parent or not hum.Parent then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end

        local camCF = cam.CFrame
        local dir = readInputVector(camCF)

        if dir.Magnitude > 0.05 then
            bv.Velocity = bv.Velocity:Lerp(dir.Unit * speed, CONFIG.FlySmooth)
        else
            bv.Velocity = bv.Velocity:Lerp(Vector3.zero, 0.3)
        end
        gy.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)
    table.insert(State.Connections, conn)

    hum.PlatformStand = true
end

function AntiDetect:StopFly()
    if not State.FlyActive then return end
    State.FlyActive = false
    State.SpeedActive = false

    local char = LocalPlayer.Character
    if char then
        for _, o in ipairs(char:GetDescendants()) do
            if o.Name == "_AD_Fly" or o.Name == "_AD_Gyro" then
                pcall(function() o:Destroy() end)
            end
        end
    end

    local hum = getHum()
    if hum then
        pcall(function() hum.PlatformStand = false end)
        if State.FlyFreefallDisabled then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            end)
            State.FlyFreefallDisabled = false
        end
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end)
        if CONFIG.AutoRestore then
            pcall(function() hum.WalkSpeed = State.OriginalWalk end)
        end
    end
end

----------------------------------------------------------------
-- 5. SPEED
----------------------------------------------------------------
function AntiDetect:SetWalkSpeed(s)
    local hum = getHum()
    if not hum or type(s) ~= "number" then return end
    State.OriginalWalk = hum.WalkSpeed
    hum.WalkSpeed = s
end

----------------------------------------------------------------
-- 6. NOCLIP
----------------------------------------------------------------
function AntiDetect:EnableNoclip()
    if State.NoclipOn then return end
    State.NoclipOn = true

    local conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                State.NoclipParts[p] = true
                p.CanCollide = false
            end
        end
    end)
    State.NoclipConn = conn
    table.insert(State.Connections, conn)
end

function AntiDetect:DisableNoclip()
    if not State.NoclipOn then return end
    State.NoclipOn = false

    if State.NoclipConn and State.NoclipConn.Disconnect then
        pcall(function() State.NoclipConn:Disconnect() end)
        for i = #State.Connections, 1, -1 do
            if State.Connections[i] == State.NoclipConn then
                table.remove(State.Connections, i)
                break
            end
        end
    end
    State.NoclipConn = nil

    for part in pairs(State.NoclipParts) do
        if part and part.Parent then
            pcall(function() part.CanCollide = true end)
        end
    end
    State.NoclipParts = {}
end

----------------------------------------------------------------
-- 7. MOBILE VIRTUAL STICK (GUARDED)
----------------------------------------------------------------
function AntiDetect:EnableMobileStick()
    if not (UIS and UIS.TouchEnabled) then return end
    if State.StickGui then return end
    if not (LocalPlayer.GetPlayerGui) then return end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "_AD_MobileStick"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(180, 180)
    frame.Position = UDim2.new(0, 30, 1, -210)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = frame

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(60, 60)
    knob.Position = UDim2.new(0.5, -30, 0.5, -30)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0.3
    knob.BorderSizePixel = 0
    knob.Parent = frame
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(1, 0)
    c2.Parent = knob

    State.StickGui = gui
    State.StickConns = {}

    -- fungsi untuk reset knob ke tengah
    local function resetKnob()
        knob.Position = UDim2.new(0.5, -30, 0.5, -30)
        State.TouchMove = Vector2.zero
    end

    local dragging = false
    local function updateKnob(input)
        local rel = Vector2.new(
            input.Position.X - frame.AbsolutePosition.X - frame.AbsoluteSize.X / 2,
            input.Position.Y - frame.AbsolutePosition.Y - frame.AbsoluteSize.Y / 2
        )
        local max = frame.AbsoluteSize.X / 2
        if max <= 0 then max = 1 end
        if rel.Magnitude > max then rel = rel.Unit * max end
        knob.Position = UDim2.new(0.5, rel.X - 30, 0.5, rel.Y - 30)
        State.TouchMove = rel / max
    end

    -- Input Began: mulai drag
    local connBegan = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateKnob(input)
        end
    end)

    -- Input Changed: perbarui knob saat drag
    local connChanged = UIS.InputChanged:Connect(function(input, gp)
        if gp then return end
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            updateKnob(input)
        end
    end)

    -- Input Ended: reset knob & stop drag
    local connEnded = UIS.InputEnded:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            resetKnob()
        end
    end)

    table.insert(State.StickConns, connBegan)
    table.insert(State.StickConns, connChanged)
    table.insert(State.StickConns, connEnded)
end

function AntiDetect:DisableMobileStick()
    if State.StickConns then
        for _, c in ipairs(State.StickConns) do
            if c and c.Disconnect then
                pcall(function() c:Disconnect() end)
            end
        end
        State.StickConns = {}
    end
    if State.StickGui then
        pcall(function() State.StickGui:Destroy() end)
        State.StickGui = nil
    end
    State.TouchMove = Vector2.zero
end

----------------------------------------------------------------
-- 8. INIT / ENABLE / DISABLE
----------------------------------------------------------------
function AntiDetect:init()
    if State.Enabled then return end
    State.Enabled = true

    self:HideIdentity()
    self:SpoofHumanoid()

    -- Re-apply saat respawn
    local conn = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.25)
        if not State.Enabled then return end
        self:SpoofHumanoid()
        if State.FlyActive then
            self:StopFly()
            self:StartFly()
        end
        if State.NoclipOn then
            State.NoclipOn = false
            self:EnableNoclip()
        end
    end)
    table.insert(State.Connections, conn)

    -- Mobile stick opsional
    pcall(function() self:EnableMobileStick() end)
end

function AntiDetect:Enable()
    self:init()
end

function AntiDetect:Disable()
    if not State.Enabled then return end
    State.Enabled = false

    self:StopFly()
    self:DisableNoclip()
    self:DisableMobileStick()

    if State.HumanoidMT and State.HumanoidOwner then
        pcall(function()
            if type(setreadonly) == "function" then
                setreadonly(State.HumanoidMT, false)
            end
            State.HumanoidMT = nil
            State.HumanoidOwner = nil
        end)
    end

    disconnectAll()
end

function AntiDetect.new()
    local self = setmetatable({}, AntiDetect)
    return self
end

-- Auto-init
pcall(function() AntiDetect:init() end)

return AntiDetect
