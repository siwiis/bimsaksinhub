--[[
================================================================================
  BimSakSin Hub v3.0 | Universal Halloween Luxury Edition
  Creator     : BimSakSin
  Environment : Roblox Luau (Universal / All-Map & R6/R15 Compatible)
  Features    :
- Transparent Luxury Halloween UI + 4 Corner 3D Pumpkins + 3D Pumpkin Toggle
- Universal Adaptive Player ESP (Team/Enemy/Random, Distance, Health,
      Transparent Avatar Highlight, Custom Font + Adaptive Translucent Backdrop)
- Universal Item ESP (Unlimited Distance, Name + Distance, No Background,
      Custom Font & Color)
- Universal Generator ESP (Name, Distance, Live Process Status, Custom Font & Color)
- Precision Auto Aimbot + Conditional RGB Weapon Laser + Auto Parry
- Melee Immunity + Hunger & Thirst Guard (Tahan Lapar & Haus)
- Interactive Replicated Carry System (Visible to Other Players + Carry/Lepas Buttons)
- Interactive Replicated R6 & R15 Dance/Emote Studio (Visible on All Devices)
- Zero-Rubberband Universal Safe Teleport ("Click") & Waypoint Manager
- Smooth Admin-Style Free-Flight & Analog-Safe NoClip Geometry Inspector
- Interactive Anti-Bug / Auto-Recovery Engine (AKTIF / OFF) + Anti-AFK
- Full Menu Font & Color Customizer + Information Tab
================================================================================
]]

-- ============================================================================
-- 0. PRE-EXECUTION CLEANUP (Mencegah duplikasi GUI, loop lama & sisa objek ESP)
-- ============================================================================
do
    if typeof(getgenv) == "function" then
        local env = getgenv()
        if type(env.BSS_UnloadOld) == "function" then
            pcall(env.BSS_UnloadOld)
            env.BSS_UnloadOld = nil
        end
    end

    local existingNames = {
        ["BimSakSinHub_v2"] = true,
        ["BimSakSinHub_v3"] = true,
        ["BSS_ESP_Folder"] = true,
        ["BSS_ItemESP_Folder"] = true,
        ["BSS_GenESP_Folder"] = true,
    }
    local function cleanupContainer(container)
        if not container then return end
        pcall(function()
            for _, child in ipairs(container:GetChildren()) do
                if existingNames[child.Name] then
                    child:Destroy()
                end
            end
        end)
    end

    if typeof(gethui) == "function" then
        cleanupContainer(gethui())
    end
    cleanupContainer(game:GetService("CoreGui"))

    local lp = game:GetService("Players").LocalPlayer
    if lp then
        cleanupContainer(lp:FindFirstChild("PlayerGui"))
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, objName in ipairs({
                "BSS_FlyVelocity",
                "BSS_FlyGyro",
                "BSS_FlyLinearVel",
                "BSS_FlyAlignOri",
                "BSS_FlyAttachment",
                "BSS_CarryVelocity",
                "BSS_CarryWeld",
            }) do
                local old = root:FindFirstChild(objName)
                if old then old:Destroy() end
            end
        end
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
        end
    end

    local oldLaser = workspace:FindFirstChild("BSS_RGB_AimLaser")
    if oldLaser then oldLaser:Destroy() end
end

-- ============================================================================
-- 1. CORE SERVICES & MODULAR STATE TABLES (Aman dari batas 200 register Luau)
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local Teams = game:GetService("Teams")

local VirtualUser = nil
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer

local App = {
    Name = "BimSakSin Hub v3.0",
    Subtitle = "semoga hari-hari kalian menyenangkan",
    Version = "v3.0 Halloween",
    GuiName = "BimSakSinHub_v3",
    IsOpen = true,
    IsMinimized = false,
    ExpandedWidth = 650,
    ExpandedHeight = 435,
    ActiveTab = "Dashboard",
    StartTime = os.clock(),
    DiscordUrl = "https://discord.gg/YwMCBq22f2",
    DonationUrl = "https://linktr.ee/bimsaksin",
}

local Theme = {
    -- Palet Halloween Mewah & Transparan
    BgPrimary = Color3.fromRGB(13, 11, 19),
    BgSecondary = Color3.fromRGB(20, 16, 30),
    BgCard = Color3.fromRGB(28, 22, 41),
    BgControl = Color3.fromRGB(40, 31, 58),
    Border = Color3.fromRGB(255, 132, 36),
    BorderSubtle = Color3.fromRGB(78, 56, 108),

    TextPrimary = Color3.fromRGB(255, 246, 235),
    TextSecondary = Color3.fromRGB(204, 186, 172),
    TextMuted = Color3.fromRGB(142, 124, 150),

    FontFamily = Enum.Font.GothamSemibold,
    FontBold = Enum.Font.GothamBold,
    FontColorMode = "Auto", -- "Auto" atau Color3 spesifik
    FontBgEnabled = false,
    FontBgColor = Color3.fromRGB(18, 14, 26),
    FontBgTransparency = 0.65,

    Accent = Color3.fromRGB(255, 118, 26),     -- Pumpkin Gold
    AccentDark = Color3.fromRGB(184, 72, 12),
    Crimson = Color3.fromRGB(214, 48, 74),
    Spectral = Color3.fromRGB(155, 89, 245),
    Success = Color3.fromRGB(46, 213, 115),
    Warning = Color3.fromRGB(255, 177, 43),
    Danger = Color3.fromRGB(235, 69, 95),
}

local initialAtmo = Lighting:FindFirstChildOfClass("Atmosphere")

local State = {
    -- Movement & Physics
    WalkSpeed = 16,
    JumpPower = 50,
    OriginalGravity = workspace.Gravity,
    Gravity = workspace.Gravity,
    FlyEnabled = false,
    FlySpeed = 65,
    NoclipEnabled = false,
    InfiniteJumpEnabled = false,

    -- Visuals & Remote Spectate
    CameraFOV = 70,
    FullbrightEnabled = false,
    NoFogEnabled = false,
    SpectatingPlayer = nil,
    SpectateStreamTick = 0,
    Waypoints = {},

    -- Teleport Concurrency Guard & Distance Telemetry
    TeleportToken = 0,
    IsTeleportLocking = false,
    PreTeleportAnchored = false,
    LastTeleportDistance = 0,

    -- UI Registries
    AccentObjects = {},
    AccentCallbacks = {},
    ActiveToggleTracks = {},
    ThemedTexts = {},

    -- Original World Cache
    OriginalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    },
    OriginalAtmosphere = initialAtmo and {
        Instance = initialAtmo,
        Density = initialAtmo.Density,
    } or nil,
}

local Physics = {
    FlyAttachment = nil,
    FlyLV = nil,
    FlyAO = nil,
    FlyBV = nil,
    FlyBG = nil,
    FlyCurrentVel = Vector3.zero,
    NoclipCache = {},
}

local ESP = {
    Enabled = false,
    ShowAvatar = true,
    ShowDistance = true,
    ShowHealth = true,
    Mode = "Auto", -- "Auto" | "Enemy" | "Ally" | "Random"
    MaxDistance = 2500,

    -- Warna & Font ESP Pemain
    HighlightColor = Color3.fromRGB(255, 118, 26),
    AllyColor = Color3.fromRGB(46, 213, 115),
    EnemyColor = Color3.fromRGB(235, 69, 95),
    DistanceColor = Color3.fromRGB(255, 210, 120),
    HealthColor = Color3.fromRGB(85, 239, 148),
    Font = Enum.Font.GothamBold,
    FontColor = Color3.fromRGB(255, 248, 240),
    FontAutoContrast = true,
    FontBgColor = Color3.fromRGB(16, 12, 24),
    FontBgTransparency = 0.56,

    Folder = nil,
    Entries = {},
    RandomColorMap = {},
}

local ItemESP = {
    Enabled = false,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(102, 242, 255),
    Folder = nil,
    Entries = {},
    Candidates = {},
}

local GeneratorESP = {
    Enabled = false,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(255, 196, 54),
    Folder = nil,
    Entries = {},
    Candidates = {},
}

local Combat = {
    AimbotEnabled = false,
    AimbotMode = "Auto", -- "Auto" | "Always" | "HoldRMB"
    AimPart = "Head", -- "Head" | "HumanoidRootPart" | "Closest"
    TeamCheck = true,
    FOVRadius = 220,
    ShowFOVCircle = false,
    Smoothness = 0.35,
    MaxRange = 800,
    RGBLaserEnabled = true,
    CurrentTarget = nil,
    LaserPart = nil,
    FOVCircle = nil,

    -- Kebal Pukulan & Survival
    MeleeImmunity = false,
    HungerThirstGuard = false,
    TouchedPartsCache = {},
    EnemyToolParts = {},

    -- Auto Parry
    AutoParryEnabled = false,
    ParryRange = 16,
    LastParryTime = 0,
    ParryCooldown = 0.4,
}

local Carry = {
    Enabled = false,
    TargetPlayer = nil,
    Style = "Depan", -- "Depan" | "Belakang" | "Pundak" | "Seret" | "Kepala" | "Melayang"
    AnimTrack = nil,
    NativePromptTriggered = false,
}

local Emotes = {
    Playing = false,
    CurrentDance = nil,
    CurrentId = nil,
    Speed = 1.0,
    ActiveTrack = nil,
}

local Protection = {
    AntiAFKEnabled = true,
    AntiBugEnabled = true,
    ErrorsCaught = 0,
    AutoRepairs = 0,
    IdleEventsHandled = 0,
    HungerThirstValues = {},
}

local Connections = {}
local UI = {
    Tabs = {},
    Pages = {},
    TelemetryLabels = {},
    FullbrightToggle = nil,
    NoFogToggle = nil,
    StatusLabel = nil,
    Pumpkins = {},
}

local Utils = {}
local Components = {}
local SafeEngine = {}

-- ============================================================================
-- 2. ANTI-BUG & AUTO-RECOVERY ENGINE (SafeEngine)
-- ============================================================================
function SafeEngine.Run(contextName, fn, ...)
    if not Protection.AntiBugEnabled then
        return fn(...)
    end
    local ok, res = xpcall(fn, function(err)
        return tostring(err)
    end, ...)
    if not ok then
        Protection.ErrorsCaught = Protection.ErrorsCaught + 1
        SafeEngine.AutoRepair(contextName, res)
    end
    return ok, res
end

function SafeEngine.AutoRepair(contextName, errMsg)
    Protection.AutoRepairs = Protection.AutoRepairs + 1

    -- Pembersihan otomatis jika ada objek yatim / fisika nyangkut
    pcall(function()
        local _, hum, root = Utils.GetCharacter()
        if hum and not State.FlyEnabled and not Carry.Enabled then
            if hum.PlatformStand then
                hum.PlatformStand = false
            end
            if not hum.AutoRotate then
                hum.AutoRotate = true
            end
        end
        if root and not State.FlyEnabled then
            for _, name in ipairs({ "BSS_FlyLinearVel", "BSS_FlyAlignOri", "BSS_FlyVelocity", "BSS_FlyGyro" }) do
                local inst = root:FindFirstChild(name)
                if inst then inst:Destroy() end
            end
        end
        if not Combat.AimbotEnabled and Combat.LaserPart then
            Combat.LaserPart.Transparency = 1
        end
        if UI.StatusLabel and UI.StatusLabel.Parent then
            UI.StatusLabel.Text = string.format("Anti-Bug Aktif (%d Fix)", Protection.AutoRepairs)
        end
    end)
end

-- ============================================================================
-- 3. UTILITY FUNCTIONS, SAFE TELEPORT & THEME ENGINE
-- ============================================================================
function Utils.Track(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

function Utils.Tween(obj, info, props)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

function Utils.Create(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

function Utils.AddCorner(parent, radius)
    return Utils.Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

function Utils.AddStroke(parent, color, thickness, transparency)
    return Utils.Create("UIStroke", {
        Color = color or Theme.BorderSubtle,
        Thickness = thickness or 1,
        Transparency = transparency or 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

function Utils.GetLuminance(c)
    return (0.299 * c.R) + (0.587 * c.G) + (0.114 * c.B)
end

function Utils.GetContrastTextColor(bgColor)
    if Utils.GetLuminance(bgColor) > 0.56 then
        return Color3.fromRGB(18, 14, 24)
    end
    return Color3.fromRGB(255, 248, 240)
end

function Utils.RegisterAccent(obj, property)
    table.insert(State.AccentObjects, { Object = obj, Property = property })
    obj[property] = Theme.Accent
end

function Utils.RegisterText(label, isBold, defaultColor)
    table.insert(State.ThemedTexts, {
        Label = label,
        IsBold = isBold == true,
        DefaultColor = defaultColor or Theme.TextPrimary,
        OrigBgTransparency = label.BackgroundTransparency,
        OrigBgColor = label.BackgroundColor3,
    })
    label.Font = isBold and Theme.FontBold or Theme.FontFamily
    if Theme.FontColorMode ~= "Auto" then
        label.TextColor3 = Theme.FontColorMode
    elseif Theme.FontBgEnabled then
        label.TextColor3 = Utils.GetContrastTextColor(Theme.FontBgColor)
    else
        label.TextColor3 = defaultColor or Theme.TextPrimary
    end

    if Theme.FontBgEnabled then
        label.BackgroundColor3 = Theme.FontBgColor
        label.BackgroundTransparency = Theme.FontBgTransparency
    end
end

function Utils.ApplyMenuFontAndColors()
    for i = #State.ThemedTexts, 1, -1 do
        local item = State.ThemedTexts[i]
        local lbl = item.Label
        if lbl and lbl.Parent then
            lbl.Font = item.IsBold and Theme.FontBold or Theme.FontFamily

            if Theme.FontBgEnabled then
                lbl.BackgroundColor3 = Theme.FontBgColor
                lbl.BackgroundTransparency = Theme.FontBgTransparency
                if not lbl:FindFirstChildOfClass("UICorner") then
                    Utils.AddCorner(lbl, 4)
                end
            else
                lbl.BackgroundColor3 = item.OrigBgColor
                lbl.BackgroundTransparency = item.OrigBgTransparency
            end

            if Theme.FontColorMode ~= "Auto" then
                lbl.TextColor3 = Theme.FontColorMode
            elseif Theme.FontBgEnabled then
                lbl.TextColor3 = Utils.GetContrastTextColor(Theme.FontBgColor)
            else
                lbl.TextColor3 = item.DefaultColor
            end
        else
            table.remove(State.ThemedTexts, i)
        end
    end
end

function Utils.SetAccentColor(newColor, newDark)
    Theme.Accent = newColor
    Theme.AccentDark = newDark or newColor
    Theme.Border = newColor

    for i = #State.AccentObjects, 1, -1 do
        local item = State.AccentObjects[i]
        if item.Object and item.Object.Parent then
            item.Object[item.Property] = newColor
        else
            table.remove(State.AccentObjects, i)
        end
    end

    for track, isActive in pairs(State.ActiveToggleTracks) do
        if track and track.Parent and isActive then
            track.BackgroundColor3 = newColor
        else
            State.ActiveToggleTracks[track] = nil
        end
    end

    for i = #State.AccentCallbacks, 1, -1 do
        local cb = State.AccentCallbacks[i]
        local ok = pcall(cb, newColor)
        if not ok then
            table.remove(State.AccentCallbacks, i)
        end
    end
end

function Utils.GetCharacter(plr)
    local target = plr or LocalPlayer
    local char = target and target.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

function Utils.GetAnimator(hum)
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    return animator
end

function Utils.CopyText(text)
    local ok = false
    if typeof(setclipboard) == "function" then
        ok = pcall(setclipboard, tostring(text))
    elseif typeof(toclipboard) == "function" then
        ok = pcall(toclipboard, tostring(text))
    end
    return ok
end

-- Pembaca Posisi Dunia Universal (Mendukung Player, Model, BasePart, CFrame, & Vector3)
function Utils.GetTargetWorldPosition(target)
    if typeof(target) == "CFrame" then
        return target.Position
    elseif typeof(target) == "Vector3" then
        return target
    elseif typeof(target) == "Instance" then
        if target:IsA("Player") then
            local char = target.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart"))
            return root and root.Position or nil
        elseif target:IsA("Model") then
            local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
            return root and root.Position or nil
        elseif target:IsA("BasePart") then
            return target.Position
        end
    end
    return nil
end

-- Teleport Jarak Tak Terbatas, Anti-Rubberband & Streaming-API Safe
function Utils.SafeTeleport(targetCFrame)
    local char, hum, root = Utils.GetCharacter(LocalPlayer)
    if not char or not root then
        return false, 0
    end

    local startPos = root.Position
    local destPos = targetCFrame.Position
    local travelDistance = (destPos - startPos).Magnitude
    State.LastTeleportDistance = travelDistance

    State.TeleportToken = State.TeleportToken + 1
    local myToken = State.TeleportToken

    -- 1. Lepas status duduk (Seat) jika sedang duduk agar tidak ditarik kembali oleh server
    if hum then
        hum.Sit = false
        if hum.SeatPart then
            local weld = hum.SeatPart:FindFirstChild("SeatWeld")
            if weld then weld:Destroy() end
        end
    end

    -- 2. Paksa Roblox Streaming API memuat area sekitar tujuan (Jarak Tak Terbatas)
    task.spawn(function()
        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(destPos, 5)
        end)
    end)

    -- 3. Simpan status Anchored asli dengan aman sebelum mengunci posisi beberapa frame
    if not State.IsTeleportLocking then
        State.PreTeleportAnchored = root.Anchored
        State.IsTeleportLocking = true
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    root.Anchored = true
    char:PivotTo(targetCFrame)

    task.spawn(function()
        for step = 1, 10 do
            RunService.Heartbeat:Wait()
            if State.TeleportToken ~= myToken then
                return
            end
            if step == 4 then
                task.spawn(function()
                    pcall(function()
                        LocalPlayer:RequestStreamAroundAsync(destPos, 3)
                    end)
                end)
            end
            if char and char.Parent and root and root.Parent then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                char:PivotTo(targetCFrame)
            end
        end
        if State.TeleportToken == myToken then
            if root and root.Parent then
                root.Anchored = State.PreTeleportAnchored
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
            State.IsTeleportLocking = false
        end
    end)

    return true, travelDistance
end

-- ============================================================================
-- 4. 3D LIFELIKE HALLOWEEN PUMPKIN LOGO BUILDER (Pure Procedural 3D UI)
-- ============================================================================
function Utils.CreatePumpkin3D(parent, pixelSize, position, anchorPoint, zIndex, isHero, isMenuPumpkin)
    local z = zIndex or 20
    local holder = Utils.Create("Frame", {
        Name = "Pumpkin3D",
        Size = UDim2.new(0, pixelSize, 0, pixelSize),
        Position = position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = anchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        ZIndex = z,
    }, parent)

    local aura = Utils.Create("Frame", {
        Size = UDim2.new(1.16, 0, 1.16, 0),
        Position = UDim2.new(0.5, 0, 0.52, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 115, 20),
        BackgroundTransparency = isHero and 0.68 or 0.78,
        BorderSizePixel = 0,
        ZIndex = z,
    }, holder)
    Utils.AddCorner(aura, math.floor(pixelSize * 0.6))

    local stem = Utils.Create("Frame", {
        Size = UDim2.new(0.18, 0, 0.24, 0),
        Position = UDim2.new(0.52, 0, 0.04, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        Rotation = 12,
        BackgroundColor3 = Color3.fromRGB(62, 112, 44),
        BorderSizePixel = 0,
        ZIndex = z + 1,
    }, holder)
    Utils.AddCorner(stem, 4)
    Utils.Create("UIGradient", {
        Rotation = 45,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 175, 72)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 68, 26)),
        }),
    }, stem)

    local function makeRib(wScale, hScale, xScale, rot, cTop, cBot, ribZ)
        local rib = Utils.Create("Frame", {
            Size = UDim2.new(wScale, 0, hScale, 0),
            Position = UDim2.new(xScale, 0, 0.56, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = rot,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = ribZ,
        }, holder)
        Utils.AddCorner(rib, math.floor(pixelSize * 0.45))
        Utils.Create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, cTop),
                ColorSequenceKeypoint.new(0.55, cTop:Lerp(cBot, 0.35)),
                ColorSequenceKeypoint.new(1, cBot),
            }),
        }, rib)
        if isHero then
            Utils.AddStroke(rib, Color3.fromRGB(70, 24, 4), 1, 0.45)
        end
        return rib
    end

    makeRib(0.36, 0.66, 0.21, -10, Color3.fromRGB(196, 74, 12), Color3.fromRGB(102, 32, 4), z + 1)
    makeRib(0.36, 0.66, 0.79, 10, Color3.fromRGB(196, 74, 12), Color3.fromRGB(102, 32, 4), z + 1)
    makeRib(0.40, 0.73, 0.33, -5, Color3.fromRGB(238, 102, 18), Color3.fromRGB(132, 44, 6), z + 2)
    makeRib(0.40, 0.73, 0.67, 5, Color3.fromRGB(238, 102, 18), Color3.fromRGB(132, 44, 6), z + 2)
    makeRib(0.44, 0.78, 0.50, 0, Color3.fromRGB(255, 162, 48), Color3.fromRGB(178, 62, 10), z + 3)

    local shine = Utils.Create("Frame", {
        Size = UDim2.new(0.16, 0, 0.12, 0),
        Position = UDim2.new(0.44, 0, 0.27, 0),
        Rotation = -18,
        BackgroundColor3 = Color3.fromRGB(255, 232, 180),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(shine, 8)

    local eyeLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.15, 0, 0.13, 0),
        Position = UDim2.new(0.36, 0, 0.47, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -14,
        BackgroundColor3 = Color3.fromRGB(255, 224, 92),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, holder)
    Utils.AddCorner(eyeLeft, 3)

    local eyeRight = Utils.Create("Frame", {
        Size = UDim2.new(0.15, 0, 0.13, 0),
        Position = UDim2.new(0.64, 0, 0.47, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 14,
        BackgroundColor3 = Color3.fromRGB(255, 224, 92),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, holder)
    Utils.AddCorner(eyeRight, 3)

    local mouth = Utils.Create("Frame", {
        Size = UDim2.new(0.42, 0, 0.12, 0),
        Position = UDim2.new(0.50, 0, 0.68, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 200, 64),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, holder)
    Utils.AddCorner(mouth, 5)

    if pixelSize >= 32 then
        local tooth = Utils.Create("Frame", {
            Size = UDim2.new(0.22, 0, 0.45, 0),
            Position = UDim2.new(0.35, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(168, 56, 8),
            BorderSizePixel = 0,
            ZIndex = z + 6,
        }, mouth)
        Utils.AddCorner(tooth, 2)
    end

    table.insert(UI.Pumpkins, {
        Holder = holder,
        Aura = aura,
        EyeLeft = eyeLeft,
        EyeRight = eyeRight,
        Mouth = mouth,
        BasePos = position or UDim2.new(0, 0, 0, 0),
        IsHero = isHero == true,
        IsMenuPumpkin = isMenuPumpkin == true,
    })

    return holder
end

-- ============================================================================
-- 5. SMOOTH ADMIN FLIGHT & PHYSICS CLEANUP HELPERS
-- ============================================================================
function Physics.CleanupFly()
    for _, inst in ipairs({ Physics.FlyLV, Physics.FlyAO, Physics.FlyAttachment, Physics.FlyBV, Physics.FlyBG }) do
        if inst then
            pcall(function() inst:Destroy() end)
        end
    end
    Physics.FlyLV = nil
    Physics.FlyAO = nil
    Physics.FlyAttachment = nil
    Physics.FlyBV = nil
    Physics.FlyBG = nil
    Physics.FlyCurrentVel = Vector3.zero

    local _, hum, root = Utils.GetCharacter()
    if root then
        for _, objName in ipairs({ "BSS_FlyLinearVel", "BSS_FlyAlignOri", "BSS_FlyAttachment", "BSS_FlyVelocity", "BSS_FlyGyro" }) do
            local old = root:FindFirstChild(objName)
            if old then old:Destroy() end
        end
        root.AssemblyLinearVelocity = Vector3.zero
    end
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
        if hum:GetState() == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

function Physics.StepSmoothFly(dt)
    local _, hum, root = Utils.GetCharacter()
    local cam = workspace.CurrentCamera
    if not State.FlyEnabled or not hum or not root or not cam then
        if Physics.FlyLV or Physics.FlyBV then
            Physics.CleanupFly()
        end
        return
    end

    if hum.Sit then
        hum.Sit = false
    end

    if not Physics.FlyAttachment or Physics.FlyAttachment.Parent ~= root then
        Physics.CleanupFly()
        local att = Instance.new("Attachment")
        att.Name = "BSS_FlyAttachment"
        att.Parent = root
        Physics.FlyAttachment = att

        local lv = Instance.new("LinearVelocity")
        lv.Name = "BSS_FlyLinearVel"
        lv.Attachment0 = att
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.MaxForce = 9e9
        lv.VectorVelocity = Vector3.zero
        lv.Parent = root
        Physics.FlyLV = lv

        local ao = Instance.new("AlignOrientation")
        ao.Name = "BSS_FlyAlignOri"
        ao.Attachment0 = att
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.RigidityEnabled = false
        ao.MaxTorque = 9e9
        ao.Responsiveness = 38
        ao.CFrame = cam.CFrame
        ao.Parent = root
        Physics.FlyAO = ao
    end

    hum.PlatformStand = true
    hum.AutoRotate = false
    Physics.FlyAO.CFrame = cam.CFrame

    -- Hitung arah gerak mulus dari kamera & input (PC WASD + Mobile Analog)
    local forward = 0
    local right = 0
    local up = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward = forward + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward = forward - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then right = right + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then right = right - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        up = up - 1
    end

    -- Dukungan Analog Mobile & Gamepad yang akurat bahkan saat kamera tegak lurus atas/bawah
    if forward == 0 and right == 0 and hum.MoveDirection.Magnitude > 0.05 then
        local camCF = cam.CFrame
        local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
        local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
        if flatLook.Magnitude > 0.001 then
            forward = hum.MoveDirection:Dot(flatLook.Unit)
        else
            local flatUp = Vector3.new(camCF.UpVector.X, 0, camCF.UpVector.Z)
            if flatUp.Magnitude > 0.001 then
                forward = hum.MoveDirection:Dot(flatUp.Unit) * (camCF.LookVector.Y < 0 and 1 or -1)
            end
        end
        if flatRight.Magnitude > 0.001 then
            right = hum.MoveDirection:Dot(flatRight.Unit)
        end
    end

    local desiredDir = (cam.CFrame.LookVector * forward) + (cam.CFrame.RightVector * right) + Vector3.new(0, up, 0)
    local targetVel = Vector3.zero
    if desiredDir.Magnitude > 0.01 then
        targetVel = desiredDir.Unit * State.FlySpeed
    end

    -- Interpolasi lembut seperti Admin Fly (tidak patah-patah & tidak mundur sendiri)
    local alpha = math.clamp((dt or 0.016) * 14, 0.15, 1)
    Physics.FlyCurrentVel = Physics.FlyCurrentVel:Lerp(targetVel, alpha)
    if Physics.FlyCurrentVel.Magnitude < 0.05 and targetVel == Vector3.zero then
        Physics.FlyCurrentVel = Vector3.zero
    end

    Physics.FlyLV.VectorVelocity = Physics.FlyCurrentVel
    root.AssemblyAngularVelocity = Vector3.zero
end

function Physics.RestoreNoclip()
    for part, origCollide in pairs(Physics.NoclipCache) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CanCollide = origCollide
        end
    end
    table.clear(Physics.NoclipCache)
end

-- ============================================================================
-- 6. ROOT SCREENGUI & NOTIFICATION SYSTEM
-- ============================================================================
local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

do
    UI.ScreenGui = Utils.Create("ScreenGui", {
        Name = App.GuiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, getGuiParent())

    UI.ToastContainer = Utils.Create("Frame", {
        Name = "ToastContainer",
        Size = UDim2.new(0, 300, 1, -24),
        Position = UDim2.new(1, -316, 0, 12),
        BackgroundTransparency = 1,
        ZIndex = 60,
    }, UI.ScreenGui)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, UI.ToastContainer)
end

function Utils.Notify(title, message, color)
    if not UI.ToastContainer or not UI.ToastContainer.Parent then return end
    local accent = color or Theme.Accent

    local toast = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        ZIndex = 61,
    }, UI.ToastContainer)
    Utils.AddCorner(toast, 9)
    Utils.AddStroke(toast, accent, 1.1, 0.25)

    local bar = Utils.Create("Frame", {
        Size = UDim2.new(0, 4, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        ZIndex = 62,
    }, toast)
    Utils.AddCorner(bar, 2)

    Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 18, 0, 7),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 62,
    }, toast)

    Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.new(0, 18, 0, 27),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = message,
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 62,
    }, toast)

    task.delay(3.2, function()
        if toast and toast.Parent then
            Utils.Tween(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            })
            task.wait(0.26)
            if toast and toast.Parent then
                toast:Destroy()
            end
        end
    end)
end

-- ============================================================================
-- 7. BUILD MAIN WINDOW (HALLOWEEN LUXURY TRANSPARENT + 4 CORNER PUMPKINS)
-- ============================================================================
do
    -- Floating Toggle: Logo Labu Halloween 3D Hidup (Selalu terlihat saat menu ditutup)
    UI.FloatingToggle = Utils.Create("TextButton", {
        Name = "FloatingPumpkinToggle",
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 18, 0.5, -28),
        BackgroundColor3 = Color3.fromRGB(18, 14, 28),
        BackgroundTransparency = 0.25,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 45,
    }, UI.ScreenGui)
    Utils.AddCorner(UI.FloatingToggle, 28)
    local floatStroke = Utils.AddStroke(UI.FloatingToggle, Theme.Accent, 1.6, 0.15)
    Utils.RegisterAccent(floatStroke, "Color")

    Utils.CreatePumpkin3D(
        UI.FloatingToggle,
        44,
        UDim2.new(0.5, 0, 0.5, 0),
        Vector2.new(0.5, 0.5),
        46,
        true,
        false
    )

    local initVp = UI.ScreenGui.AbsoluteSize
    local initW = (initVp.X > 0) and math.min(650, math.max(320, initVp.X - 24)) or 650
    local initH = (initVp.Y > 0) and math.min(435, math.max(240, initVp.Y - 24)) or 435
    App.ExpandedWidth = initW
    App.ExpandedHeight = initH

    -- Main Window Container (Transparan & Elegan)
    UI.MainFrame = Utils.Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, initW, 0, initH),
        Position = UDim2.new(0.5, -math.floor(initW / 2), 0.5, -math.floor(initH / 2)),
        BackgroundColor3 = Theme.BgPrimary,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 10,
    }, UI.ScreenGui)
    Utils.AddCorner(UI.MainFrame, 14)
    local mainStroke = Utils.AddStroke(UI.MainFrame, Theme.Accent, 1.5, 0.15)
    Utils.RegisterAccent(mainStroke, "Color")

    -- Gradien Kemewahan Halloween di Latar Belakang Panel
    local bgGradient = Utils.Create("UIGradient", {
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 20, 48)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(16, 13, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 22, 16)),
        }),
    }, UI.MainFrame)
    bgGradient.Name = "HalloweenLuxuryGradient"

    -- 4 Logo Labu Halloween 3D di Setiap Sudut Panel Menu
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(0, -8, 0, -8), Vector2.new(0, 0), 30, false, true)
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(1, 8, 0, -8), Vector2.new(1, 0), 30, false, true)
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(0, -8, 1, 8), Vector2.new(0, 1), 30, false, true)
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(1, 8, 1, 8), Vector2.new(1, 1), 30, false, true)

    -- Inner Clipping Frame
    UI.InnerClip = Utils.Create("Frame", {
        Name = "InnerClip",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 11,
    }, UI.MainFrame)
    Utils.AddCorner(UI.InnerClip, 14)

    -- Top Header Bar
    UI.Topbar = Utils.Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, UI.InnerClip)

    Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 13,
    }, UI.Topbar)

    -- Emblem Labu 3D di Header Kiri
    Utils.CreatePumpkin3D(UI.Topbar, 32, UDim2.new(0, 32, 0.5, 0), Vector2.new(0.5, 0.5), 14, true, true)

    -- Judul Utama ("BimSakSin Hub v3.0") & Ucapan di bawahnya
    local titleLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -142, 0, 22),
        Position = UDim2.new(0, 54, 0, 6),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = App.Name,
        TextColor3 = Theme.TextPrimary,
        TextSize = 16,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    }, UI.Topbar)
    UI.TitleLabel = titleLbl
    Utils.RegisterText(titleLbl, true, Theme.TextPrimary)

    local subLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -142, 0, 16),
        Position = UDim2.new(0, 54, 0, 29),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = App.Subtitle,
        TextColor3 = Color3.fromRGB(255, 198, 128),
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    }, UI.Topbar)
    UI.SubLabel = subLbl
    Utils.RegisterText(subLbl, false, Color3.fromRGB(255, 198, 128))

    -- Topbar Controls (Minimize & Close)
    local function createTopBtn(text, offsetX, hoverColor)
        local btn = Utils.Create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, offsetX, 0.5, -14),
            BackgroundColor3 = Theme.BgControl,
            BackgroundTransparency = 0.2,
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            TextSize = 13,
            AutoButtonColor = false,
            ZIndex = 15,
        }, UI.Topbar)
        Utils.AddCorner(btn, 7)
        btn.MouseEnter:Connect(function()
            Utils.Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor })
        end)
        btn.MouseLeave:Connect(function()
            Utils.Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.BgControl })
        end)
        return btn
    end

    UI.MinimizeBtn = createTopBtn("—", -76, Theme.Accent)
    UI.CloseBtn = createTopBtn("✕", -42, Theme.Danger)

    local initSidebarW = (initW < 500) and math.clamp(math.floor(initW * 0.30), 116, 166) or 166

    -- Left Sidebar (Transparan)
    UI.Sidebar = Utils.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, initSidebarW, 1, -54),
        Position = UDim2.new(0, 0, 0, 54),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, UI.InnerClip)

    Utils.Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.BorderSubtle,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 13,
    }, UI.Sidebar)

    UI.SidebarScroll = Utils.Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -46),
        Position = UDim2.new(0, 6, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 13,
    }, UI.Sidebar)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, UI.SidebarScroll)

    -- Sidebar Footer Badge
    local footerBox = Utils.Create("Frame", {
        Size = UDim2.new(1, -14, 0, 28),
        Position = UDim2.new(0, 7, 1, -35),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 13,
    }, UI.Sidebar)
    Utils.AddCorner(footerBox, 7)

    local dot = Utils.Create("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 10, 0.5, -4),
        BackgroundColor3 = Theme.Success,
        BorderSizePixel = 0,
        ZIndex = 14,
    }, footerBox)
    Utils.AddCorner(dot, 4)

    local statusLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -26, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Anti-Bug: AKTIF",
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    }, footerBox)
    UI.StatusLabel = statusLbl
    Utils.RegisterText(statusLbl, false, Theme.TextSecondary)

    -- Content Area
    UI.ContentContainer = Utils.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -initSidebarW, 1, -54),
        Position = UDim2.new(0, initSidebarW, 0, 54),
        BackgroundTransparency = 1,
        ZIndex = 12,
    }, UI.InnerClip)

    -- Subtle Corner Resize Handle
    UI.ResizeHandle = Utils.Create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "◢",
        TextColor3 = Theme.Accent,
        TextTransparency = 0.35,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 24,
    }, UI.InnerClip)
    Utils.RegisterAccent(UI.ResizeHandle, "TextColor3")
end

-- ============================================================================
-- 8. DRAGGING SUPPORT (Mouse & Multi-Touch Safe)
-- ============================================================================
do
    local function makeDraggable(dragHandle, targetFrame)
        local dragging = false
        local activeDragInput = nil
        local dragStart = nil
        local startPos = nil

        Utils.Track(dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                activeDragInput = input
                dragStart = input.Position
                startPos = targetFrame.Position
            end
        end))

        Utils.Track(UserInputService.InputChanged:Connect(function(input)
            if not dragging or not activeDragInput or not dragStart or not startPos then
                return
            end
            local isMatchingMouse = (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseMovement)
            local isMatchingTouch = (input == activeDragInput)

            if isMatchingMouse or isMatchingTouch then
                local delta = input.Position - dragStart
                targetFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end))

        Utils.Track(UserInputService.InputEnded:Connect(function(input)
            if dragging and (input == activeDragInput or (activeDragInput and activeDragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
                dragging = false
                activeDragInput = nil
            end
        end))
    end

    makeDraggable(UI.Topbar, UI.MainFrame)
    makeDraggable(UI.FloatingToggle, UI.FloatingToggle)
end

-- ============================================================================
-- 9. REUSABLE UI COMPONENT BUILDERS
-- ============================================================================
function Components.SwitchTab(tabName)
    App.ActiveTab = tabName
    for name, tabData in pairs(UI.Tabs) do
        local isSelected = (name == tabName)
        Utils.Tween(tabData.Button, TweenInfo.new(0.18), {
            BackgroundColor3 = isSelected and Theme.BgControl or Theme.BgSecondary,
            BackgroundTransparency = isSelected and 0.18 or 1,
        })
        tabData.Indicator.Visible = isSelected
    end
    for name, page in pairs(UI.Pages) do
        page.Visible = (name == tabName)
    end
end

function Components.CreateTab(name, iconText, order)
    local btn = Utils.Create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.BgControl,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 14,
    }, UI.SidebarScroll)
    Utils.AddCorner(btn, 7)

    local indicator = Utils.Create("Frame", {
        Size = UDim2.new(0, 3, 0, 18),
        Position = UDim2.new(0, 4, 0.5, -9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 15,
    }, btn)
    Utils.AddCorner(indicator, 2)
    Utils.RegisterAccent(indicator, "BackgroundColor3")

    local label = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 13, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = iconText .. "  " .. name,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, btn)
    Utils.RegisterText(label, false, Theme.TextPrimary)

    local page = Utils.Create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, -14, 1, -14),
        Position = UDim2.new(0, 7, 0, 7),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 13,
    }, UI.ContentContainer)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    Utils.Create("UIPadding", {
        PaddingRight = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 10),
    }, page)

    btn.MouseButton1Click:Connect(function()
        Components.SwitchTab(name)
    end)

    UI.Tabs[name] = {
        Button = btn,
        Label = label,
        Indicator = indicator,
    }
    UI.Pages[name] = page
    return page
end

function Components.AddSectionHeader(parent, title, order)
    local lbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "🎃 " .. string.upper(title),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.RegisterAccent(lbl, "TextColor3")
    return lbl
end

function Components.AddToggle(parent, title, subtitle, defaultVal, order, callback)
    local enabled = defaultVal == true

    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, card)

    local textBox = Utils.Create("Frame", {
        Size = UDim2.new(1, -56, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, card)
    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, textBox)

    local tLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 15,
    }, textBox)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)

    local sLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = subtitle,
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 15,
    }, textBox)
    Utils.RegisterText(sLbl, false, Theme.TextSecondary)

    local switchTrack = Utils.Create("TextButton", {
        Size = UDim2.new(0, 44, 0, 22),
        Position = UDim2.new(1, -44, 0.5, -11),
        BackgroundColor3 = enabled and Theme.Accent or Theme.BgControl,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(switchTrack, 11)

    if enabled then
        State.ActiveToggleTracks[switchTrack] = true
    end

    local knob = Utils.Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 16,
    }, switchTrack)
    Utils.AddCorner(knob, 8)

    local function setState(newState, fireCallback)
        enabled = newState
        State.ActiveToggleTracks[switchTrack] = enabled and true or nil

        Utils.Tween(switchTrack, TweenInfo.new(0.18), {
            BackgroundColor3 = enabled and Theme.Accent or Theme.BgControl
        })
        Utils.Tween(knob, TweenInfo.new(0.18), {
            Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        })
        if fireCallback and callback then
            SafeEngine.Run(title, callback, enabled)
        end
    end

    switchTrack.MouseButton1Click:Connect(function()
        setState(not enabled, true)
    end)

    return {
        SetState = setState,
        GetState = function() return enabled end,
    }
end

function Components.AddSlider(parent, title, minVal, maxVal, defaultVal, decimals, order, callback)
    local currentVal = math.clamp(defaultVal, minVal, maxVal)
    local precision = decimals or 0

    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    local tLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 18),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)

    local function formatVal(v)
        if precision <= 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%." .. tostring(precision) .. "f", v)
    end

    local valueLabel = Utils.Create("TextLabel", {
        Size = UDim2.new(0.3, -12, 0, 18),
        Position = UDim2.new(0.7, 0, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = formatVal(currentVal),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 15,
    }, card)
    Utils.RegisterAccent(valueLabel, "TextColor3")

    local track = Utils.Create("TextButton", {
        Size = UDim2.new(1, -24, 0, 8),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = Theme.BgControl,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(track, 4)

    local initRatio = (currentVal - minVal) / math.max(0.0001, (maxVal - minVal))
    local fill = Utils.Create("Frame", {
        Size = UDim2.new(initRatio, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 16,
    }, track)
    Utils.AddCorner(fill, 4)
    Utils.RegisterAccent(fill, "BackgroundColor3")

    local thumb = Utils.Create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(initRatio, -7, 0.5, -7),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 17,
    }, track)
    Utils.AddCorner(thumb, 7)

    local sliding = false

    local function setValue(val, fireCallback)
        currentVal = math.clamp(val, minVal, maxVal)
        if precision <= 0 then
            currentVal = math.floor(currentVal + 0.5)
        else
            local mult = 10 ^ precision
            currentVal = math.floor(currentVal * mult + 0.5) / mult
        end
        local ratio = (currentVal - minVal) / math.max(0.0001, (maxVal - minVal))
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        thumb.Position = UDim2.new(ratio, -7, 0.5, -7)
        valueLabel.Text = formatVal(currentVal)
        if fireCallback and callback then
            SafeEngine.Run(title, callback, currentVal)
        end
    end

    local function updateFromInput(inputPos)
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end
        local relX = math.clamp((inputPos.X - track.AbsolutePosition.X) / trackWidth, 0, 1)
        local rawVal = minVal + (maxVal - minVal) * relX
        setValue(rawVal, true)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromInput(input.Position)
        end
    end)

    Utils.Track(UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input.Position)
        end
    end))

    Utils.Track(UserInputService.InputEnded:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
        end
    end))

    return {
        SetValue = setValue,
        GetValue = function() return currentVal end,
    }
end

function Components.AddButton(parent, title, subtitle, btnLabel, order, callback)
    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    local tLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)

    local sLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -110, 0, 14),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = subtitle,
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(sLbl, false, Theme.TextSecondary)

    local actionBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 88, 0, 28),
        Position = UDim2.new(1, -100, 0.5, -14),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = btnLabel,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(actionBtn, 7)
    Utils.RegisterAccent(actionBtn, "BackgroundColor3")

    actionBtn.MouseButton1Click:Connect(function()
        if callback then
            SafeEngine.Run(title, callback)
        end
    end)

    return actionBtn
end

function Components.AddChipSelector(parent, title, options, defaultVal, order, callback)
    local selected = defaultVal

    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, card)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, card)

    local titleLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(titleLbl, true, Theme.TextPrimary)

    local grid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        ZIndex = 15,
    }, card)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.315, 0, 0, 26),
        CellPadding = UDim2.new(0.025, 0, 0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local chipButtons = {}

    local function refreshChips()
        for val, btn in pairs(chipButtons) do
            if btn and btn.Parent then
                local isAct = (val == selected)
                btn.BackgroundColor3 = isAct and Theme.Accent or Theme.BgControl
                btn.BackgroundTransparency = isAct and 0.05 or 0.2
            end
        end
    end

    table.insert(State.AccentCallbacks, function()
        refreshChips()
    end)

    for idx, opt in ipairs(options) do
        local labelText = type(opt) == "table" and opt.Label or tostring(opt)
        local optVal = type(opt) == "table" and opt.Value or opt
        local previewFont = type(opt) == "table" and opt.Font or nil
        local swatchColor = type(opt) == "table" and opt.Color or nil

        local chip = Utils.Create("TextButton", {
            BackgroundColor3 = (optVal == selected) and Theme.Accent or Theme.BgControl,
            BackgroundTransparency = (optVal == selected) and 0.05 or 0.2,
            Font = previewFont or Theme.FontBold,
            Text = labelText,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 16,
        }, grid)
        Utils.AddCorner(chip, 6)

        if swatchColor then
            local dot = Utils.Create("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(0, 6, 0.5, -4),
                BackgroundColor3 = swatchColor,
                BorderSizePixel = 0,
                ZIndex = 17,
            }, chip)
            Utils.AddCorner(dot, 4)
        end

        chipButtons[optVal] = chip

        chip.MouseButton1Click:Connect(function()
            selected = optVal
            refreshChips()
            if callback then
                SafeEngine.Run(title, callback, optVal)
            end
        end)
    end

    return {
        SetSelected = function(v)
            selected = v
            refreshChips()
        end,
        GetSelected = function() return selected end,
    }
end

-- ============================================================================
-- 10. UNIVERSAL PLAYER ESP ENGINE (Team/Enemy/Random + Distance + Health)
-- ============================================================================
do
    ESP.Folder = Utils.Create("Folder", {
        Name = "BSS_ESP_Folder",
    }, UI.ScreenGui)

    function ESP.GetRandomPlayerColor(plr)
        if not ESP.RandomColorMap[plr.UserId] then
            local hue = ((plr.UserId * 137.508) % 360) / 360
            ESP.RandomColorMap[plr.UserId] = Color3.fromHSV(hue, 0.85, 1)
        end
        return ESP.RandomColorMap[plr.UserId]
    end

    function ESP.ClassifyRelation(plr)
        local hasTeams = (#Teams:GetTeams() > 0) and (LocalPlayer.Team ~= nil) and (plr.Team ~= nil)
        if hasTeams then
            if plr.Team == LocalPlayer.Team then
                return "Ally"
            else
                return "Enemy"
            end
        end
        return "Random"
    end

    function ESP.RemovePlayer(plr)
        local entry = ESP.Entries[plr]
        if entry then
            if entry.Highlight then entry.Highlight:Destroy() end
            if entry.Billboard then entry.Billboard:Destroy() end
            ESP.Entries[plr] = nil
        end
    end

    function ESP.ClearAll()
        for plr, _ in pairs(ESP.Entries) do
            ESP.RemovePlayer(plr)
        end
        if ESP.Folder then
            ESP.Folder:ClearAllChildren()
        end
    end

    function ESP.EnsurePlayer(plr)
        if plr == LocalPlayer then return nil end
        local entry = ESP.Entries[plr]
        if not entry then
            local hl = Utils.Create("Highlight", {
                Name = "HL_" .. plr.Name,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillTransparency = 0.52,
                OutlineTransparency = 0.08,
                Enabled = false,
            }, ESP.Folder)

            local bb = Utils.Create("BillboardGui", {
                Name = "BB_" .. plr.Name,
                Size = UDim2.new(0, 230, 0, 62),
                StudsOffset = Vector3.new(0, 3.3, 0),
                AlwaysOnTop = true,
                MaxDistance = math.huge,
                ResetOnSpawn = false,
                Enabled = false,
            }, ESP.Folder)

            local bgBox = Utils.Create("Frame", {
                Size = UDim2.new(0, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.XY,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = ESP.FontBgColor,
                BackgroundTransparency = ESP.FontBgTransparency,
                BorderSizePixel = 0,
            }, bb)
            Utils.AddCorner(bgBox, 6)
            Utils.Create("UIPadding", {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
            }, bgBox)
            Utils.Create("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, bgBox)

            local nameLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = ESP.Font,
                Text = plr.DisplayName,
                TextColor3 = ESP.FontColor,
                TextStrokeTransparency = 0.45,
                TextSize = 12,
                LayoutOrder = 1,
            }, bgBox)

            local distLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 13),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = ESP.Font,
                Text = "Jarak: 0 m",
                TextColor3 = ESP.DistanceColor,
                TextStrokeTransparency = 0.45,
                TextSize = 11,
                LayoutOrder = 2,
            }, bgBox)

            local hpLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 13),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = ESP.Font,
                Text = "Darah: 100/100",
                TextColor3 = ESP.HealthColor,
                TextStrokeTransparency = 0.45,
                TextSize = 11,
                LayoutOrder = 3,
            }, bgBox)

            entry = {
                Highlight = hl,
                Billboard = bb,
                BgBox = bgBox,
                NameLbl = nameLbl,
                DistLbl = distLbl,
                HpLbl = hpLbl,
            }
            ESP.Entries[plr] = entry
        end
        return entry
    end

    function ESP.UpdateAll()
        if not ESP.Enabled then
            for _, entry in pairs(ESP.Entries) do
                entry.Highlight.Enabled = false
                entry.Billboard.Enabled = false
            end
            return
        end

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local entry = ESP.EnsurePlayer(plr)
                local char, hum, root = Utils.GetCharacter(plr)
                local head = char and (char:FindFirstChild("Head") or root)

                if char and root and head and entry then
                    local rel = ESP.ClassifyRelation(plr)
                    local shouldShow = true

                    if ESP.Mode == "Enemy" and rel == "Ally" then
                        shouldShow = false
                    elseif ESP.Mode == "Ally" and rel ~= "Ally" then
                        shouldShow = false
                    end

                    local originPos = myRoot and myRoot.Position or camPos
                    local distStuds = (root.Position - originPos).Magnitude
                    if distStuds > ESP.MaxDistance then
                        shouldShow = false
                    end

                    if shouldShow then
                        local mainColor = ESP.HighlightColor
                        local tagText = "[PLAYER]"
                        if ESP.Mode == "Random" or rel == "Random" then
                            mainColor = (ESP.Mode == "Random") and ESP.GetRandomPlayerColor(plr) or ESP.HighlightColor
                            tagText = "[PLAYER]"
                        elseif rel == "Ally" then
                            mainColor = ESP.AllyColor
                            tagText = "[TEMAN]"
                        elseif rel == "Enemy" then
                            mainColor = ESP.EnemyColor
                            tagText = "[MUSUH]"
                        end

                        entry.Highlight.Adornee = char
                        entry.Highlight.FillColor = mainColor
                        entry.Highlight.OutlineColor = mainColor:Lerp(Color3.new(1, 1, 1), 0.35)
                        entry.Highlight.FillTransparency = 0.52
                        entry.Highlight.OutlineTransparency = 0.08
                        entry.Highlight.Enabled = ESP.ShowAvatar

                        entry.Billboard.Adornee = head
                        entry.Billboard.Enabled = true

                        entry.BgBox.BackgroundColor3 = ESP.FontBgColor
                        entry.BgBox.BackgroundTransparency = ESP.FontBgTransparency

                        local resolvedNameColor = ESP.FontColor
                        if ESP.FontAutoContrast then
                            resolvedNameColor = Utils.GetContrastTextColor(ESP.FontBgColor):Lerp(mainColor, 0.35)
                        end

                        entry.NameLbl.Font = ESP.Font
                        entry.NameLbl.TextColor3 = resolvedNameColor
                        entry.NameLbl.Text = string.format("%s %s", tagText, plr.DisplayName)

                        entry.DistLbl.Visible = ESP.ShowDistance
                        entry.DistLbl.Font = ESP.Font
                        entry.DistLbl.TextColor3 = ESP.DistanceColor
                        entry.DistLbl.Text = string.format("Jarak: %.0f m", distStuds)

                        if ESP.ShowHealth and hum and hum.MaxHealth > 0 then
                            entry.HpLbl.Visible = true
                            entry.HpLbl.Font = ESP.Font
                            entry.HpLbl.TextColor3 = ESP.HealthColor
                            entry.HpLbl.Text = string.format("Darah: %.0f / %.0f", math.max(0, hum.Health), hum.MaxHealth)
                        else
                            entry.HpLbl.Visible = false
                        end
                    else
                        entry.Highlight.Enabled = false
                        entry.Billboard.Enabled = false
                    end
                elseif entry then
                    entry.Highlight.Enabled = false
                    entry.Billboard.Enabled = false
                end
            end
        end
    end
end

-- ============================================================================
-- 11. UNIVERSAL ITEM ESP & GENERATOR ESP (Unlimited Distance, Map-Adaptive)
-- ============================================================================
do
    ItemESP.Folder = Utils.Create("Folder", { Name = "BSS_ItemESP_Folder" }, UI.ScreenGui)
    GeneratorESP.Folder = Utils.Create("Folder", { Name = "BSS_GenESP_Folder" }, UI.ScreenGui)

    local function isPlayerDescendant(inst)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and inst:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local function getAdorneePart(obj)
        if not obj or not obj.Parent then return nil end
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") then
            return obj.PrimaryPart or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        if obj:IsA("Tool") then
            return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function isGeneratorObject(inst)
        local n = string.lower(inst.Name)
        if string.find(n, "generator", 1, true)
            or string.find(n, "reactor", 1, true)
            or string.find(n, "repairmachine", 1, true)
            or string.find(n, "powerbox", 1, true)
            or n == "gen"
            or string.match(n, "^gen[%d_%-]")
            or string.match(n, "[%d_%-]gen$") then
            return true
        end
        local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            local pText = string.lower((prompt.ActionText or "") .. " " .. (prompt.ObjectText or ""))
            if string.find(pText, "generator", 1, true)
                or ((string.find(pText, "repair", 1, true) or string.find(pText, "perbaiki", 1, true))
                    and (string.find(pText, "gen", 1, true) or string.find(pText, "mesin", 1, true) or string.find(pText, "power", 1, true) or string.find(pText, "listrik", 1, true))) then
                return true
            end
        end
        return false
    end

    local function collectGeneratorStatusValues(genObj, entry)
        local vals = {}
        for _, desc in ipairs(genObj:GetDescendants()) do
            local k = string.lower(desc.Name)
            if desc:IsA("BoolValue") then
                if string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")
                    or string.find(k, "repairing") or string.find(k, "working") or string.find(k, "inuse") then
                    table.insert(vals, desc)
                end
            elseif desc:IsA("NumberValue") or desc:IsA("IntValue") then
                if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                    table.insert(vals, desc)
                end
            end
        end
        entry.StatusValues = vals
    end

    local function getGeneratorStatus(genObj, entry)
        local progressPct = nil
        local isCompleted = false
        local isBeingWorked = false

        -- 1. Baca Attributes pada generator
        pcall(function()
            for attrName, attrVal in pairs(genObj:GetAttributes()) do
                local k = string.lower(attrName)
                if type(attrVal) == "boolean" then
                    if (string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")) and attrVal == true then
                        isCompleted = true
                    elseif (string.find(k, "repairing") or string.find(k, "active") or string.find(k, "working") or string.find(k, "inuse")) and attrVal == true then
                        isBeingWorked = true
                    end
                elseif type(attrVal) == "number" then
                    if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                        local maxAttr = genObj:GetAttribute("Max" .. attrName) or genObj:GetAttribute("MaxProgress") or 100
                        if attrVal <= 1 and maxAttr == 100 and attrVal > 0 then
                            progressPct = math.floor(attrVal * 100 + 0.5)
                        else
                            progressPct = math.floor((attrVal / math.max(1, maxAttr)) * 100 + 0.5)
                        end
                    end
                end
            end
        end)

        -- 2. Baca ValueObjects yang sudah di-cache di dalam generator (tanpa GetDescendants ulang)
        if entry and entry.StatusValues then
            for _, desc in ipairs(entry.StatusValues) do
                if desc and desc.Parent then
                    local k = string.lower(desc.Name)
                    if desc:IsA("BoolValue") then
                        if (string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")) and desc.Value == true then
                            isCompleted = true
                        elseif (string.find(k, "repairing") or string.find(k, "working") or string.find(k, "inuse")) and desc.Value == true then
                            isBeingWorked = true
                        end
                    elseif (desc:IsA("NumberValue") or desc:IsA("IntValue")) then
                        if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                            local maxObj = desc.Parent and (desc.Parent:FindFirstChild("Max" .. desc.Name) or desc.Parent:FindFirstChild("MaxProgress"))
                            local maxV = (maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) and maxObj.Value > 0) and maxObj.Value or 100
                            if desc.Value <= 1 and maxV == 100 and desc.Value > 0 then
                                progressPct = math.floor(desc.Value * 100 + 0.5)
                            else
                                progressPct = math.floor((desc.Value / maxV) * 100 + 0.5)
                            end
                        end
                    end
                end
            end
        end

        -- 3. Cek apakah ada pemain lain di dekat generator yang sedang memproses
        local part = (entry and entry.Part) or getAdorneePart(genObj)
        local workerName = nil
        if part and not isCompleted then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local _, _, pRoot = Utils.GetCharacter(plr)
                    if pRoot and (pRoot.Position - part.Position).Magnitude <= 11 then
                        workerName = plr.DisplayName
                        isBeingWorked = true
                        break
                    end
                end
            end
        end

        if isCompleted or (progressPct and progressPct >= 100) then
            return "Status: Selesai Diproses (100%)"
        elseif progressPct and progressPct > 0 then
            if workerName then
                return string.format("Status: Diproses %s (%d%%)", workerName, math.clamp(progressPct, 0, 100))
            end
            return string.format("Status: Sudah Diproses (%d%%)", math.clamp(progressPct, 0, 100))
        elseif isBeingWorked and workerName then
            return string.format("Status: Sedang Diproses (%s)", workerName)
        else
            return "Status: Belum Diproses (0%)"
        end
    end

    local ignoreKeywords = { "door", "pintu", "seat", "chair", "kur", "elevator", "lift", "gate", "switch", "button" }
    local candidatesInitialized = false

    local function isItemCandidate(inst)
        if inst:IsA("Tool") then
            if Players:GetPlayerFromCharacter(inst.Parent) then
                return false
            end
            return true
        elseif (inst:IsA("Model") or inst:IsA("BasePart")) then
            if inst:IsA("BasePart") and inst.Parent and inst.Parent:IsA("Model") and ItemESP.Candidates[inst.Parent] then
                return false
            end

            local lowerName = string.lower(inst.Name)
            for _, ikw in ipairs(ignoreKeywords) do
                if string.find(lowerName, ikw, 1, true) then
                    return false
                end
            end

            local prompt = inst:IsA("Model") and inst:FindFirstChildWhichIsA("ProximityPrompt", true) or inst:FindFirstChildWhichIsA("ProximityPrompt")
            local clickDet = inst:IsA("Model") and inst:FindFirstChildWhichIsA("ClickDetector", true) or inst:FindFirstChildWhichIsA("ClickDetector")
            local parentName = inst.Parent and string.lower(inst.Parent.Name) or ""
            local inItemFolder = string.find(parentName, "item")
                or string.find(parentName, "drop")
                or string.find(parentName, "loot")
                or string.find(parentName, "pickup")
                or string.find(parentName, "collect")
                or string.find(parentName, "barang")
                or string.find(parentName, "tool")

            if prompt or clickDet or inItemFolder then
                return true
            end
        end
        return false
    end

    local function evaluateCandidate(inst)
        if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then
            ItemESP.Candidates[inst] = nil
            GeneratorESP.Candidates[inst] = nil
            return
        end

        if not (inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("BasePart")) then
            return
        end

        if (inst:IsA("Model") or inst:IsA("BasePart")) and isGeneratorObject(inst) then
            local hasGenAncestor = false
            local anc = inst.Parent
            while anc and anc ~= workspace do
                if (anc:IsA("Model") or anc:IsA("Folder")) and isGeneratorObject(anc) then
                    hasGenAncestor = true
                    break
                end
                anc = anc.Parent
            end

            if not hasGenAncestor then
                GeneratorESP.Candidates[inst] = true
            else
                GeneratorESP.Candidates[inst] = nil
            end
            ItemESP.Candidates[inst] = nil
            return
        else
            GeneratorESP.Candidates[inst] = nil
        end

        if isItemCandidate(inst) then
            ItemESP.Candidates[inst] = true
        else
            ItemESP.Candidates[inst] = nil
        end
    end

    local function ensureCandidatesInitialized()
        if candidatesInitialized then return end
        candidatesInitialized = true

        -- Pemindaian awal berbasis batch agar map besar tidak mengalami micro-freeze
        task.spawn(function()
            local descendants = workspace:GetDescendants()
            for i, inst in ipairs(descendants) do
                if not ItemESP.Enabled and not GeneratorESP.Enabled then
                    candidatesInitialized = false
                    return
                end
                evaluateCandidate(inst)
                if i % 1500 == 0 then
                    RunService.Heartbeat:Wait()
                end
            end
        end)

        Utils.Track(workspace.DescendantAdded:Connect(function(desc)
            evaluateCandidate(desc)
            local parent = desc.Parent
            if parent and parent ~= workspace then
                evaluateCandidate(parent)
                local grandParent = parent.Parent
                if grandParent and grandParent ~= workspace and (desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector")) then
                    evaluateCandidate(grandParent)
                end
            end
        end))

        Utils.Track(workspace.DescendantRemoving:Connect(function(desc)
            ItemESP.Candidates[desc] = nil
            GeneratorESP.Candidates[desc] = nil

            local itemEntry = ItemESP.Entries[desc]
            if itemEntry then
                if itemEntry.Billboard then itemEntry.Billboard:Destroy() end
                ItemESP.Entries[desc] = nil
            end

            local genEntry = GeneratorESP.Entries[desc]
            if genEntry then
                if genEntry.Highlight then genEntry.Highlight:Destroy() end
                if genEntry.Billboard then genEntry.Billboard:Destroy() end
                if genEntry.DescConn then genEntry.DescConn:Disconnect() end
                GeneratorESP.Entries[desc] = nil
            end
        end))
    end

    function ItemESP.ClearAll()
        table.clear(ItemESP.Entries)
        if ItemESP.Folder then
            ItemESP.Folder:ClearAllChildren()
        end
    end

    function GeneratorESP.ClearAll()
        for _, entry in pairs(GeneratorESP.Entries) do
            if entry.DescConn then
                entry.DescConn:Disconnect()
            end
        end
        table.clear(GeneratorESP.Entries)
        if GeneratorESP.Folder then
            GeneratorESP.Folder:ClearAllChildren()
        end
    end

    function ItemESP.ScanAndRender()
        if not ItemESP.Enabled then
            if next(ItemESP.Entries) ~= nil then
                ItemESP.ClearAll()
            end
            return
        end

        ensureCandidatesInitialized()

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero
        local originPos = myRoot and myRoot.Position or camPos

        local activeSet = {}

        for inst, _ in pairs(ItemESP.Candidates) do
            if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then
                ItemESP.Candidates[inst] = nil
            elseif not isPlayerDescendant(inst) then
                local part = getAdorneePart(inst)
                if part and part:IsDescendantOf(workspace) then
                    activeSet[inst] = true
                    local entry = ItemESP.Entries[inst]
                    if not entry then
                        -- Tanpa latar belakang (TextLabel BackgroundTransparency = 1)
                        local bb = Utils.Create("BillboardGui", {
                            Name = "ItemBB",
                            Size = UDim2.new(0, 210, 0, 38),
                            StudsOffset = Vector3.new(0, 1.8, 0),
                            AlwaysOnTop = true,
                            MaxDistance = math.huge,
                            ResetOnSpawn = false,
                        }, ItemESP.Folder)

                        local lbl = Utils.Create("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Font = ItemESP.Font,
                            Text = inst.Name,
                            TextColor3 = ItemESP.Color,
                            TextStrokeColor3 = Color3.fromRGB(10, 10, 14),
                            TextStrokeTransparency = 0.25,
                            TextSize = 12,
                        }, bb)

                        entry = { Billboard = bb, Label = lbl, Part = part }
                        ItemESP.Entries[inst] = entry
                    end

                    local dist = (part.Position - originPos).Magnitude
                    entry.Billboard.Adornee = part
                    entry.Billboard.Enabled = true
                    entry.Label.Font = ItemESP.Font
                    entry.Label.TextColor3 = ItemESP.Color
                    entry.Label.BackgroundTransparency = 1
                    entry.Label.Text = string.format("[BARANG] %s\nJarak: %.0f m", inst.Name, dist)
                end
            end
        end

        for inst, entry in pairs(ItemESP.Entries) do
            if not activeSet[inst] or not inst.Parent then
                if entry.Billboard then entry.Billboard:Destroy() end
                ItemESP.Entries[inst] = nil
            end
        end
    end

    function GeneratorESP.ScanAndRender()
        if not GeneratorESP.Enabled then
            if next(GeneratorESP.Entries) ~= nil then
                GeneratorESP.ClearAll()
            end
            return
        end

        ensureCandidatesInitialized()

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero
        local originPos = myRoot and myRoot.Position or camPos

        local activeSet = {}

        for inst, _ in pairs(GeneratorESP.Candidates) do
            if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then
                GeneratorESP.Candidates[inst] = nil
            elseif not isPlayerDescendant(inst) then
                local part = getAdorneePart(inst)
                if part and part:IsDescendantOf(workspace) then
                    activeSet[inst] = true
                    local entry = GeneratorESP.Entries[inst]
                    if not entry then
                        local hl = Utils.Create("Highlight", {
                            Name = "GenHL",
                            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                            FillTransparency = 0.65,
                            OutlineTransparency = 0.1,
                        }, GeneratorESP.Folder)

                        local bb = Utils.Create("BillboardGui", {
                            Name = "GenBB",
                            Size = UDim2.new(0, 240, 0, 54),
                            StudsOffset = Vector3.new(0, 3.0, 0),
                            AlwaysOnTop = true,
                            MaxDistance = math.huge,
                            ResetOnSpawn = false,
                        }, GeneratorESP.Folder)

                        local lbl = Utils.Create("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Font = GeneratorESP.Font,
                            Text = inst.Name,
                            TextColor3 = GeneratorESP.Color,
                            TextStrokeColor3 = Color3.fromRGB(10, 10, 14),
                            TextStrokeTransparency = 0.2,
                            TextSize = 12,
                        }, bb)

                        entry = { Highlight = hl, Billboard = bb, Label = lbl, Part = part, StatusValues = {} }
                        collectGeneratorStatusValues(inst, entry)
                        entry.DescConn = Utils.Track(inst.DescendantAdded:Connect(function(d)
                            if d:IsA("BoolValue") or d:IsA("NumberValue") or d:IsA("IntValue") then
                                table.insert(entry.StatusValues, d)
                            end
                        end))
                        GeneratorESP.Entries[inst] = entry
                    end

                    local dist = (part.Position - originPos).Magnitude
                    local statusText = getGeneratorStatus(inst, entry)

                    entry.Highlight.Adornee = inst
                    entry.Highlight.FillColor = GeneratorESP.Color
                    entry.Highlight.OutlineColor = GeneratorESP.Color
                    entry.Highlight.Enabled = true

                    entry.Billboard.Adornee = part
                    entry.Billboard.Enabled = true
                    entry.Label.Font = GeneratorESP.Font
                    entry.Label.TextColor3 = GeneratorESP.Color
                    entry.Label.Text = string.format("⚡ %s\nJarak: %.0f m\n%s", inst.Name, dist, statusText)
                end
            end
        end

        for inst, entry in pairs(GeneratorESP.Entries) do
            if not activeSet[inst] or not inst.Parent then
                if entry.Highlight then entry.Highlight:Destroy() end
                if entry.Billboard then entry.Billboard:Destroy() end
                if entry.DescConn then entry.DescConn:Disconnect() end
                GeneratorESP.Entries[inst] = nil
            end
        end
    end
end

-- ============================================================================
-- 12. AUTO AIMBOT, RGB WEAPON LASER & AUTO PARRY ENGINE
-- ============================================================================
do
    Combat.FOVCircle = Utils.Create("Frame", {
        Name = "BSS_AimFOV",
        Size = UDim2.new(0, Combat.FOVRadius * 2, 0, Combat.FOVRadius * 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
    }, UI.ScreenGui)
    Utils.AddCorner(Combat.FOVCircle, 999)
    local fovStroke = Utils.AddStroke(Combat.FOVCircle, Theme.Accent, 1.3, 0.35)
    Utils.RegisterAccent(fovStroke, "Color")

    function Combat.GetEquippedRangedWeapon()
        local char = Utils.GetCharacter(LocalPlayer)
        if not char then return nil, false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return nil, false end

        for _, desc in ipairs(tool:GetDescendants()) do
            local dName = string.lower(desc.Name)
            if dName == "muzzle" or dName == "barrel" or dName == "firepoint" or dName == "gunscript" or dName == "ammo" or dName == "bullet" then
                return tool, true
            end
        end

        local nameLower = string.lower(tool.Name)
        local gunKeywords = {
            "gun", "pistol", "rifle", "sniper", "ak", "m4", "m16", "shotgun",
            "smg", "bow", "crossbow", "blaster", "laser", "revolver", "glock", "deagle",
            "uzi", "carbine", "launcher", "mp5", "scar", "awp", "raygun",
            "tec", "mac", "cannon", "ray", "plasma", "magnum", "beretta"
        }
        for _, kw in ipairs(gunKeywords) do
            if string.match(nameLower, "%f[%a]" .. kw .. "%f[%A]") then
                return tool, true
            end
        end

        return tool, false
    end

    function Combat.HideLaser()
        if Combat.LaserPart then
            Combat.LaserPart.Transparency = 1
        end
    end

    function Combat.UpdateLaser(startPos, endPos)
        if not Combat.LaserPart or not Combat.LaserPart.Parent then
            Combat.LaserPart = Utils.Create("Part", {
                Name = "BSS_RGB_AimLaser",
                Anchored = true,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                CastShadow = false,
                Material = Enum.Material.Neon,
                Transparency = 0.15,
                Size = Vector3.new(0.08, 0.08, 1),
            }, workspace)
        end

        local dist = (endPos - startPos).Magnitude
        if dist < 0.2 then
            Combat.LaserPart.Transparency = 1
            return
        end

        local hue = (os.clock() * 0.65) % 1
        Combat.LaserPart.Color = Color3.fromHSV(hue, 1, 1)
        Combat.LaserPart.Transparency = 0.12
        Combat.LaserPart.Size = Vector3.new(0.08, 0.08, dist)
        Combat.LaserPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -dist / 2)
    end

    function Combat.FindBestTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil, nil end

        local viewportCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local bestTarget = nil
        local bestAimPart = nil
        local bestScore = Combat.FOVRadius

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isAlly = (#Teams:GetTeams() > 0 and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
                if not (Combat.TeamCheck and isAlly) then
                    local char, hum, root = Utils.GetCharacter(plr)
                    if char and hum and hum.Health > 0 and root then
                        if not char:FindFirstChildOfClass("ForceField") then
                            local partToAim = root
                            if Combat.AimPart == "Head" then
                                partToAim = char:FindFirstChild("Head") or root
                            elseif Combat.AimPart == "Closest" then
                                local head = char:FindFirstChild("Head")
                                if head then
                                    local hPos = cam:WorldToViewportPoint(head.Position)
                                    local rPos = cam:WorldToViewportPoint(root.Position)
                                    local dH = (Vector2.new(hPos.X, hPos.Y) - viewportCenter).Magnitude
                                    local dR = (Vector2.new(rPos.X, rPos.Y) - viewportCenter).Magnitude
                                    partToAim = (dH < dR) and head or root
                                end
                            end

                            local worldDist = myRoot and (partToAim.Position - myRoot.Position).Magnitude or 0
                            if worldDist <= Combat.MaxRange then
                                local screenPos, onScreen = cam:WorldToViewportPoint(partToAim.Position)
                                if onScreen and screenPos.Z > 0 then
                                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                                    if screenDist <= bestScore then
                                        bestScore = screenDist
                                        bestTarget = plr
                                        bestAimPart = partToAim
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return bestTarget, bestAimPart
    end

    -- Auto Parry Engine (Deteksi pukulan/serangan lawan & teman di sekitar karakter)
    function Combat.TriggerParryAction(attackerName)
        local now = os.clock()
        if (now - Combat.LastParryTime) < Combat.ParryCooldown then
            return
        end
        Combat.LastParryTime = now

        local myChar, myHum = Utils.GetCharacter(LocalPlayer)
        if not myChar or not myHum or myHum.Health <= 0 then return end

        -- 1. Equip & aktifkan Tool Parry/Block/Shield/Sword jika ada di Backpack atau Character
        local activeTool = myChar:FindFirstChildOfClass("Tool")
        if not activeTool then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then
                        local tn = string.lower(t.Name)
                        if string.find(tn, "parry") or string.find(tn, "block") or string.find(tn, "shield") or string.find(tn, "sword") or string.find(tn, "blade") or string.find(tn, "bat") then
                            myHum:EquipTool(t)
                            activeTool = t
                            break
                        end
                    end
                end
            end
        end

        if activeTool then
            pcall(function() activeTool:Activate() end)
        end

        -- 2. Kirim input tombol Parry standar ('F') via VirtualInputManager
        if VirtualInputManager then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.delay(0.06, function()
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end)
                end)
            end)
        end

        Utils.Notify("Auto Parry!", "Menangkis serangan dari " .. tostring(attackerName), Theme.Success)
    end

    function Combat.StepAutoParry()
        if not Combat.AutoParryEnabled then return end
        local _, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myHum or not myRoot or myHum.Health <= 0 then return end

        local attackKeywords = {
            "slash", "punch", "attack", "strike", "jab", "kick",
            "heavy", "bash", "slam", "uppercut", "combo", "lunge", "chop", "melee", "stab"
        }

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isAlly = (#Teams:GetTeams() > 0 and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
                if not (Combat.TeamCheck and isAlly) then
                    local char, hum, root = Utils.GetCharacter(plr)
                    if char and hum and hum.Health > 0 and root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist <= Combat.ParryRange then
                            local animator = hum:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                    local animName = string.lower((track.Name or "") .. " " .. (track.Animation and track.Animation.Name or ""))
                                    for _, kw in ipairs(attackKeywords) do
                                        if string.find(animName, kw, 1, true) then
                                            Combat.TriggerParryAction(plr.DisplayName)
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- 13. INTERACTIVE REPLICATED CARRY ENGINE (Terlihat di Device Pemain Lain)
-- ============================================================================
do
    local carryOffsets = {
        Depan = CFrame.new(0, 0.25, -1.75) * CFrame.Angles(0, math.rad(90), math.rad(15)),
        Belakang = CFrame.new(0, 0.75, 1.35) * CFrame.Angles(math.rad(-10), 0, 0),
        Pundak = CFrame.new(1.15, 1.45, -0.15) * CFrame.Angles(math.rad(85), 0, math.rad(90)),
        Seret = CFrame.new(0, -2.15, 2.8) * CFrame.Angles(math.rad(82), math.rad(180), 0),
        Kepala = CFrame.new(0, 3.1, 0),
        Melayang = CFrame.new(2.2, 1.1, -0.5) * CFrame.Angles(0, math.rad(-25), 0),
    }

    -- Animasi pose carry resmi R15 / R6 agar tereplikasi ke layar pemain lain
    local carryAnimIds = {
        R15 = "rbxassetid://3333474484",
        R6 = "rbxassetid://182435998",
    }

    function Carry.PlayReplicatedPose()
        local _, hum = Utils.GetCharacter(LocalPlayer)
        if not hum then return end
        local animator = Utils.GetAnimator(hum)
        if not animator then return end

        if Carry.AnimTrack then
            pcall(function() Carry.AnimTrack:Stop(0.1) end)
            Carry.AnimTrack = nil
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = (hum.RigType == Enum.HumanoidRigType.R6) and carryAnimIds.R6 or carryAnimIds.R15
        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if ok and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play(0.15)
            Carry.AnimTrack = track
        end
    end

    function Carry.TryNativeMapCarry(targetPlr)
        local tChar, _, tRoot = Utils.GetCharacter(targetPlr)
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        if not tChar or not tRoot or not myRoot then return false end

        -- Dekatkan posisi sejenak untuk memicu ProximityPrompt carry bawaan map jika ada
        local carryWords = { "carry", "gendong", "angkat", "grab", "pick", "piggy", "hold" }
        for _, desc in ipairs(tChar:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local txt = string.lower((desc.ActionText or "") .. " " .. (desc.ObjectText or "") .. " " .. desc.Name)
                for _, kw in ipairs(carryWords) do
                    if string.find(txt, kw, 1, true) then
                        Utils.SafeTeleport(tRoot.CFrame * CFrame.new(0, 0, 2))
                        task.spawn(function()
                            task.wait(0.12)
                            if typeof(fireproximityprompt) == "function" and desc and desc.Parent then
                                pcall(fireproximityprompt, desc)
                            end
                        end)
                        return true
                    end
                end
            end
        end
        return false
    end

    function Carry.Start()
        if not Carry.TargetPlayer then
            Utils.Notify("Pilih Pemain", "Pilih teman/player terlebih dahulu sebelum menekan Carry!", Theme.Warning)
            Carry.Enabled = false
            return false
        end

        Carry.NativePromptTriggered = false
        Carry.NativePromptTriggered = Carry.TryNativeMapCarry(Carry.TargetPlayer)
        Carry.Enabled = true
        Carry.PlayReplicatedPose()

        local modeInfo = Carry.NativePromptTriggered and "Mode Server/Map" or "Mode Visual Lokal"
        Utils.Notify(
            "Carry Aktif",
            "Meng-carry " .. Carry.TargetPlayer.DisplayName .. " (Gaya: " .. Carry.Style .. " | " .. modeInfo .. ")",
            Theme.Success
        )
        return true
    end

    function Carry.Stop()
        Carry.Enabled = false
        Carry.NativePromptTriggered = false

        if Carry.AnimTrack then
            pcall(function() Carry.AnimTrack:Stop(0.15) end)
            Carry.AnimTrack = nil
        end

        if Carry.TargetPlayer then
            local _, tHum = Utils.GetCharacter(Carry.TargetPlayer)
            if tHum then
                tHum.PlatformStand = false
                if tHum:GetState() == Enum.HumanoidStateType.Physics then
                    tHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end

    function Carry.Step()
        if not Carry.Enabled or not Carry.TargetPlayer then return end
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local tChar, tHum, tRoot = Utils.GetCharacter(Carry.TargetPlayer)

        if not myRoot or not tChar or not tRoot or not tHum or tHum.Health <= 0 then
            return
        end

        -- Jika map memiliki sistem carry bawaan yang sudah aktif (Weld/Seat), biarkan map yang menanganinya
        if Carry.NativePromptTriggered then
            return
        end

        local offset = carryOffsets[Carry.Style] or carryOffsets.Depan
        tHum.PlatformStand = true
        tRoot.AssemblyLinearVelocity = Vector3.zero
        tRoot.AssemblyAngularVelocity = Vector3.zero
        tRoot.CFrame = myRoot.CFrame * offset
    end
end

-- ============================================================================
-- 14. INTERACTIVE REPLICATED R6 & R15 DANCE / EMOTE STUDIO (Terlihat Pemain Lain)
-- ============================================================================
do
    -- Menggunakan Roblox Animator AnimationTrack sehingga gerakan tereplikasi otomatis ke semua pemain lain!
    Emotes.Catalog = {
        { Id = "Dance1", Label = "Groove Dance 1", R15 = "rbxassetid://507771019", R6 = "rbxassetid://182435998" },
        { Id = "Dance2", Label = "Party Dance 2", R15 = "rbxassetid://507776043", R6 = "rbxassetid://182436842" },
        { Id = "Dance3", Label = "Hype Dance 3", R15 = "rbxassetid://507777268", R6 = "rbxassetid://182436935" },
        { Id = "Stadium", Label = "Stadium Wave", R15 = "rbxassetid://3338010159", R6 = "rbxassetid://129423030" },
        { Id = "Tilt", Label = "Head Tilt Vibe", R15 = "rbxassetid://3334538554", R6 = "rbxassetid://128777973" },
        { Id = "Salute", Label = "Respect Salute", R15 = "rbxassetid://3333474484", R6 = "rbxassetid://128777973" },
        { Id = "Shrug", Label = "Chill Shrug", R15 = "rbxassetid://3334392772", R6 = "rbxassetid://129423131" },
        { Id = "Applause", Label = "Victory Claps", R15 = "rbxassetid://5915693819", R6 = "rbxassetid://129423030" },
        { Id = "Cheer", Label = "Happy Cheer", R15 = "rbxassetid://507770677", R6 = "rbxassetid://129423030" },
        { Id = "Laugh", Label = "Big Laugh", R15 = "rbxassetid://507770818", R6 = "rbxassetid://129423131" },
        { Id = "Point", Label = "Look There", R15 = "rbxassetid://507770453", R6 = "rbxassetid://128853357" },
        { Id = "Wave", Label = "Friendly Wave", R15 = "rbxassetid://507770239", R6 = "rbxassetid://128777973" },
    }

    function Emotes.Stop()
        Emotes.Playing = false
        Emotes.CurrentDance = nil
        if Emotes.ActiveTrack then
            pcall(function() Emotes.ActiveTrack:Stop(0.15) end)
            Emotes.ActiveTrack = nil
        end
    end

    function Emotes.PlayAsset(labelName, assetId)
        local char, hum = Utils.GetCharacter(LocalPlayer)
        if not char or not hum then
            Utils.Notify("Emote", "Karakter belum siap.", Theme.Warning)
            return
        end

        local animator = Utils.GetAnimator(hum)
        if not animator then
            Utils.Notify("Emote", "Animator karakter tidak ditemukan.", Theme.Warning)
            return
        end

        Emotes.Stop()

        local cleanId = tostring(assetId)
        if not string.find(cleanId, "rbxassetid://", 1, true) then
            local digits = string.match(cleanId, "%d+")
            if not digits then
                Utils.Notify("ID Tidak Valid", "Masukkan angka Animation ID Roblox yang valid.", Theme.Danger)
                return
            end
            cleanId = "rbxassetid://" .. digits
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = cleanId

        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)

        if ok and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play(0.15)
            track:AdjustSpeed(Emotes.Speed)

            Emotes.ActiveTrack = track
            Emotes.Playing = true
            Emotes.CurrentDance = labelName
            Emotes.CurrentId = cleanId
            Utils.Notify("Dance Terkirim ke Server", "Memainkan: " .. labelName .. " (Terlihat pemain lain)", Theme.Success)
        else
            Utils.Notify("Gagal Memuat Dance", "ID animasi tidak didukung di map ini.", Theme.Warning)
        end
    end

    function Emotes.PlayPreset(entry)
        local _, hum = Utils.GetCharacter(LocalPlayer)
        local isR6 = hum and (hum.RigType == Enum.HumanoidRigType.R6)
        local chosenId = isR6 and entry.R6 or entry.R15
        Emotes.PlayAsset(entry.Label, chosenId)
    end
end

-- ============================================================================
-- 15. PROTECTION & SURVIVAL ENGINE (Anti-AFK, Melee Immunity, Hunger & Thirst)
-- ============================================================================
do
    -- Anti-AFK (Mencegah disconnect 20 menit diam)
    Utils.Track(LocalPlayer.Idled:Connect(function()
        if Protection.AntiAFKEnabled then
            Protection.IdleEventsHandled = Protection.IdleEventsHandled + 1
            pcall(function()
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end
            end)
        end
    end))

    function Protection.RestoreEnemyHitboxes()
        for part, origTouch in pairs(Combat.TouchedPartsCache) do
            if part and part.Parent and part:IsA("BasePart") then
                part.CanTouch = origTouch
            end
        end
        table.clear(Combat.TouchedPartsCache)
        table.clear(Combat.EnemyToolParts)
    end

    local function getCachedToolParts(tool)
        local cached = Combat.EnemyToolParts[tool]
        if not cached then
            cached = {}
            for _, desc in ipairs(tool:GetDescendants()) do
                if desc:IsA("BasePart") then
                    table.insert(cached, desc)
                end
            end
            Combat.EnemyToolParts[tool] = cached
            Utils.Track(tool.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") and Combat.EnemyToolParts[tool] then
                    table.insert(Combat.EnemyToolParts[tool], desc)
                end
            end))
            Utils.Track(tool.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    Combat.EnemyToolParts[tool] = nil
                end
            end))
        end
        return cached
    end

    function Protection.StepMeleeImmunity()
        if not Combat.MeleeImmunity then return end
        local char, hum, root = Utils.GetCharacter(LocalPlayer)
        if not char or not hum or not root then return end

        local badStates = {
            [Enum.HumanoidStateType.Ragdoll] = true,
            [Enum.HumanoidStateType.FallingDown] = true,
            [Enum.HumanoidStateType.Physics] = true,
        }
        if badStates[hum:GetState()] then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if not State.FlyEnabled and not Carry.Enabled and hum.PlatformStand then
            hum.PlatformStand = false
        end

        if not State.FlyEnabled then
            local vel = root.AssemblyLinearVelocity
            local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if horizSpeed > (State.WalkSpeed + 28) or vel.Y > 65 then
                root.AssemblyLinearVelocity = Vector3.new(0, math.min(vel.Y, 65), 0)
            end
            root.AssemblyAngularVelocity = Vector3.zero
        end

        if hum.Health > 0 and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local enemyTool = plr.Character:FindFirstChildOfClass("Tool")
                if enemyTool then
                    local parts = getCachedToolParts(enemyTool)
                    for _, desc in ipairs(parts) do
                        if desc and desc.Parent then
                            if Combat.TouchedPartsCache[desc] == nil then
                                Combat.TouchedPartsCache[desc] = desc.CanTouch
                            end
                            if desc.CanTouch then
                                desc.CanTouch = false
                            end
                        end
                    end
                end
            end
        end
    end

    -- Tahan Lapar & Tahan Haus (Terkontrol & Cache-Based tanpa memindai PlayerGui)
    local survivalKeywords = {
        "hunger", "lapar", "thirst", "haus", "food", "makan",
        "water", "minum", "hydration", "starve", "energy", "calories"
    }

    local function matchesSurvivalKeyword(str)
        local lower = string.lower(str)
        for _, kw in ipairs(survivalKeywords) do
            if string.find(lower, kw, 1, true) then
                return true
            end
        end
        return false
    end

    function Protection.RegisterSurvivalValue(inst)
        if (inst:IsA("NumberValue") or inst:IsA("IntValue")) and matchesSurvivalKeyword(inst.Name) then
            Protection.HungerThirstValues[inst] = true
        end
    end

    function Protection.BindSurvivalContainer(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if not child:IsA("PlayerGui") and not child:IsA("PlayerScripts") and not child:IsA("Backpack") then
                Protection.RegisterSurvivalValue(child)
                for _, desc in ipairs(child:GetDescendants()) do
                    Protection.RegisterSurvivalValue(desc)
                end
            end
        end
        Utils.Track(container.DescendantAdded:Connect(function(desc)
            if not desc:FindFirstAncestorOfClass("PlayerGui") and not desc:FindFirstAncestorOfClass("PlayerScripts") then
                Protection.RegisterSurvivalValue(desc)
            end
        end))
    end

    Protection.BindSurvivalContainer(LocalPlayer)
    if LocalPlayer.Character then
        Protection.BindSurvivalContainer(LocalPlayer.Character)
    end
    Utils.Track(LocalPlayer.CharacterAdded:Connect(function(char)
        Protection.BindSurvivalContainer(char)
    end))

    function Protection.StepHungerThirstGuard()
        if not Combat.HungerThirstGuard then return end

        local function restoreAttributes(container)
            if not container then return end
            pcall(function()
                for attrName, attrVal in pairs(container:GetAttributes()) do
                    if type(attrVal) == "number" and matchesSurvivalKeyword(attrName) then
                        local maxAttr = container:GetAttribute("Max" .. attrName) or 100
                        if attrVal < maxAttr then
                            container:SetAttribute(attrName, maxAttr)
                        end
                    end
                end
            end)
        end

        restoreAttributes(LocalPlayer)
        restoreAttributes(LocalPlayer.Character)

        for valObj, _ in pairs(Protection.HungerThirstValues) do
            if valObj and valObj.Parent then
                local maxObj = valObj.Parent:FindFirstChild("Max" .. valObj.Name) or valObj.Parent:FindFirstChild("MaxValue")
                local targetMax = 100
                if maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) and maxObj.Value > 0 then
                    targetMax = maxObj.Value
                elseif valObj.Value > 100 then
                    targetMax = valObj.Value
                end
                if valObj.Value < targetMax then
                    valObj.Value = targetMax
                end
            else
                Protection.HungerThirstValues[valObj] = nil
            end
        end
    end
end

-- ============================================================================
-- TAB 1: DASHBOARD & TELEMETRY
-- ============================================================================
do
    local page = Components.CreateTab("Dashboard", "◈", 1)
    Components.AddSectionHeader(page, "Telemetri Klien Langsung", 1)

    local grid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 124),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.485, 0, 0, 58),
        CellPadding = UDim2.new(0.03, 0, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local function createStatCard(labelTitle, initialValue, order)
        local box = Utils.Create("Frame", {
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 14,
        }, grid)
        Utils.AddCorner(box, 9)
        Utils.AddStroke(box, Theme.BorderSubtle, 1, 0.3)

        local l1 = Utils.Create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Font = Theme.FontFamily,
            Text = labelTitle,
            TextColor3 = Theme.TextSecondary,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterText(l1, false, Theme.TextSecondary)

        local valLbl = Utils.Create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 10, 0, 26),
            BackgroundTransparency = 1,
            Font = Theme.FontBold,
            Text = initialValue,
            TextColor3 = Theme.TextPrimary,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterText(valLbl, true, Theme.TextPrimary)

        return valLbl
    end

    UI.TelemetryLabels.FPS = createStatCard("Frame Rate (FPS)", "60 FPS", 1)
    UI.TelemetryLabels.Ping = createStatCard("Network Latency", "-- ms", 2)
    UI.TelemetryLabels.Memory = createStatCard("Client Memory", "-- MB", 3)
    UI.TelemetryLabels.Players = createStatCard("Active Players", tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), 4)

    Components.AddSectionHeader(page, "Utilitas Server & Sesi", 3)

    Components.AddButton(page, "Salin Place & Job ID", "PlaceId: " .. tostring(game.PlaceId), "Copy ID", 4, function()
        local infoStr = string.format("PlaceId: %s | JobId: %s", tostring(game.PlaceId), tostring(game.JobId))
        if Utils.CopyText(infoStr) then
            Utils.Notify("Tersalin", infoStr, Theme.Success)
        else
            Utils.Notify("Info Server", infoStr, Theme.Accent)
        end
    end)

    Components.AddButton(page, "Respawn Karakter", "Segarkan kembali status karakter lokal", "Respawn", 5, function()
        local _, hum = Utils.GetCharacter()
        if hum then
            hum.Health = 0
            Utils.Notify("Karakter", "Melakukan respawn karakter...", Theme.Warning)
        end
    end)

    Components.AddButton(page, "Rejoin Server Saat Ini", "Hubungkan ulang ke instance PlaceId yang sama", "Rejoin", 6, function()
        Utils.Notify("TeleportService", "Mencoba masuk kembali ke server...", Theme.Accent)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end)
end

-- ============================================================================
-- TAB 2: ESP & VISUAL RADAR (Pemain, Barang-Barang Tanpa Latar, & Generator)
-- ============================================================================
do
    local page = Components.CreateTab("ESP Radar", "👁", 2)
    Components.AddSectionHeader(page, "ESP Pemain & Transparansi Avatar", 1)

    Components.AddToggle(page, "Universal Player ESP (Tembus Tembok)", "Tampilkan ESP jarak jauh menembus tembok di semua map", false, 2, function(on)
        ESP.Enabled = on
        if not on then
            ESP.ClearAll()
        end
        Utils.Notify("Universal ESP", on and "ESP pemain aktif di seluruh map." or "ESP pemain dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Highlight Avatar Transparan", "Sorot tubuh avatar pemain agar terlihat dari jarak sejauh mana pun", true, 3, function(on)
        ESP.ShowAvatar = on
    end)

    Components.AddToggle(page, "Indikator Jarak Pemain (Meter)", "Tampilkan jarak real-time ke setiap pemain", true, 4, function(on)
        ESP.ShowDistance = on
    end)

    Components.AddToggle(page, "Indikator Darah / HP Adaptif", "Otomatis menampilkan HP jika map menggunakan sistem darah", true, 5, function(on)
        ESP.ShowHealth = on
    end)

    Components.AddChipSelector(page, "Mode Target ESP (Teman / Musuh / Random)", {
        { Label = "Auto Map", Value = "Auto" },
        { Label = "Musuh Saja", Value = "Enemy" },
        { Label = "Teman Saja", Value = "Ally" },
        { Label = "Random Semua", Value = "Random" },
    }, "Auto", 6, function(val)
        ESP.Mode = val
        Utils.Notify("Mode ESP", "Mode target diatur ke: " .. val, Theme.Accent)
    end)

    Components.AddSlider(page, "Jarak Maksimal ESP Pemain (Studs)", 200, 10000, 2500, 0, 7, function(val)
        ESP.MaxDistance = val
    end)

    Components.AddSectionHeader(page, "Kustomisasi Warna & Font ESP Pemain", 8)

    Components.AddChipSelector(page, "Pilih Gaya Font ESP Pemain", {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Merriweather", Value = Enum.Font.Merriweather, Font = Enum.Font.Merriweather },
    }, Enum.Font.GothamBold, 9, function(val)
        ESP.Font = val
    end)

    Components.AddChipSelector(page, "Warna Utama ESP / Highlight", {
        { Label = "Labu Emas", Value = Color3.fromRGB(255, 118, 26), Color = Color3.fromRGB(255, 118, 26) },
        { Label = "Merah Darah", Value = Color3.fromRGB(235, 69, 95), Color = Color3.fromRGB(235, 69, 95) },
        { Label = "Hijau Neon", Value = Color3.fromRGB(46, 213, 115), Color = Color3.fromRGB(46, 213, 115) },
        { Label = "Cyan Spektral", Value = Color3.fromRGB(24, 220, 255), Color = Color3.fromRGB(24, 220, 255) },
        { Label = "Ungu Mistis", Value = Color3.fromRGB(165, 94, 234), Color = Color3.fromRGB(165, 94, 234) },
        { Label = "Putih Terang", Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(255, 118, 26), 10, function(val)
        ESP.HighlightColor = val
    end)

    Components.AddChipSelector(page, "Warna Teks Jarak", {
        { Label = "Kuning Emas", Value = Color3.fromRGB(255, 210, 120), Color = Color3.fromRGB(255, 210, 120) },
        { Label = "Cyan Es", Value = Color3.fromRGB(112, 235, 255), Color = Color3.fromRGB(112, 235, 255) },
        { Label = "Putih Bersih", Value = Color3.fromRGB(250, 250, 255), Color = Color3.fromRGB(250, 250, 255) },
        { Label = "Oranye Labu", Value = Color3.fromRGB(255, 145, 65), Color = Color3.fromRGB(255, 145, 65) },
        { Label = "Pink Neon", Value = Color3.fromRGB(255, 118, 195), Color = Color3.fromRGB(255, 118, 195) },
        { Label = "Hijau Mint", Value = Color3.fromRGB(130, 255, 185), Color = Color3.fromRGB(130, 255, 185) },
    }, Color3.fromRGB(255, 210, 120), 11, function(val)
        ESP.DistanceColor = val
    end)

    Components.AddChipSelector(page, "Warna Teks Darah (HP)", {
        { Label = "Hijau HP", Value = Color3.fromRGB(85, 239, 148), Color = Color3.fromRGB(85, 239, 148) },
        { Label = "Merah Crimson", Value = Color3.fromRGB(255, 88, 108), Color = Color3.fromRGB(255, 88, 108) },
        { Label = "Kuning Amber", Value = Color3.fromRGB(255, 214, 70), Color = Color3.fromRGB(255, 214, 70) },
        { Label = "Putih Salju", Value = Color3.fromRGB(245, 248, 255), Color = Color3.fromRGB(245, 248, 255) },
        { Label = "Biru Elektrik", Value = Color3.fromRGB(95, 185, 255), Color = Color3.fromRGB(95, 185, 255) },
        { Label = "Ungu Violet", Value = Color3.fromRGB(195, 135, 255), Color = Color3.fromRGB(195, 135, 255) },
    }, Color3.fromRGB(85, 239, 148), 12, function(val)
        ESP.HealthColor = val
    end)

    Components.AddChipSelector(page, "Warna Latar Belakang Font Pemain", {
        { Label = "Hitam Tipis", Value = Color3.fromRGB(16, 12, 24), Color = Color3.fromRGB(16, 12, 24) },
        { Label = "Ungu Malam", Value = Color3.fromRGB(36, 20, 56), Color = Color3.fromRGB(36, 20, 56) },
        { Label = "Coklat Labu", Value = Color3.fromRGB(48, 24, 12), Color = Color3.fromRGB(48, 24, 12) },
        { Label = "Merah Gelap", Value = Color3.fromRGB(48, 14, 22), Color = Color3.fromRGB(48, 14, 22) },
        { Label = "Putih Kabut", Value = Color3.fromRGB(235, 230, 242), Color = Color3.fromRGB(235, 230, 242) },
        { Label = "Bening Halus", Value = Color3.fromRGB(10, 10, 14), Color = Color3.fromRGB(10, 10, 14) },
    }, Color3.fromRGB(16, 12, 24), 13, function(val)
        ESP.FontBgColor = val
        ESP.FontBgTransparency = (val == Color3.fromRGB(10, 10, 14)) and 0.78 or 0.56
    end)

    Components.AddChipSelector(page, "Warna Font Nama ESP (Auto / Custom)", {
        { Label = "Auto Kontras", Value = "Auto", Color = Color3.fromRGB(255, 195, 110) },
        { Label = "Putih Tulang", Value = Color3.fromRGB(255, 248, 240), Color = Color3.fromRGB(255, 248, 240) },
        { Label = "Emas Labu", Value = Color3.fromRGB(255, 155, 55), Color = Color3.fromRGB(255, 155, 55) },
        { Label = "Merah Terang", Value = Color3.fromRGB(255, 95, 115), Color = Color3.fromRGB(255, 95, 115) },
        { Label = "Hijau Spektral", Value = Color3.fromRGB(95, 245, 155), Color = Color3.fromRGB(95, 245, 155) },
        { Label = "Hitam Pekat", Value = Color3.fromRGB(20, 16, 28), Color = Color3.fromRGB(20, 16, 28) },
    }, "Auto", 14, function(val)
        if val == "Auto" then
            ESP.FontAutoContrast = true
        else
            ESP.FontAutoContrast = false
            ESP.FontColor = val
        end
    end)

    -- FITUR BARU: ESP BARANG-BARANG (TANPA LATAR BELAKANG, JARAK TAK TERBATAS)
    Components.AddSectionHeader(page, "ESP Barang-Barang (Jarak Tak Terbatas & Tanpa Latar)", 15)

    Components.AddToggle(page, "Universal Item & Loot ESP (Jarak Tak Terbatas)", "Deteksi struktur barang/loot/tool sejauh mana pun (ESP, Nama, Jarak tanpa latar)", false, 16, function(on)
        ItemESP.Enabled = on
        if not on then
            ItemESP.ClearAll()
        else
            ItemESP.ScanAndRender()
        end
        Utils.Notify("ESP Barang", on and "ESP Barang aktif (tanpa batas jarak)." or "ESP Barang dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddChipSelector(page, "Gaya Font ESP Barang-Barang", {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Oswald", Value = Enum.Font.Oswald, Font = Enum.Font.Oswald },
    }, Enum.Font.GothamBold, 17, function(val)
        ItemESP.Font = val
    end)

    Components.AddChipSelector(page, "Warna Font ESP Barang-Barang", {
        { Label = "Cyan Terang", Value = Color3.fromRGB(102, 242, 255), Color = Color3.fromRGB(102, 242, 255) },
        { Label = "Kuning Emas", Value = Color3.fromRGB(255, 218, 88), Color = Color3.fromRGB(255, 218, 88) },
        { Label = "Hijau Neon", Value = Color3.fromRGB(85, 255, 145), Color = Color3.fromRGB(85, 255, 145) },
        { Label = "Oranye Labu", Value = Color3.fromRGB(255, 145, 55), Color = Color3.fromRGB(255, 145, 55) },
        { Label = "Pink Neon", Value = Color3.fromRGB(255, 125, 210), Color = Color3.fromRGB(255, 125, 210) },
        { Label = "Putih Bersih", Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(102, 242, 255), 18, function(val)
        ItemESP.Color = val
    end)

    -- FITUR BARU: ESP GENERATOR (NAMA, JARAK, STATUS PROSES PEMAIN LAIN)
    Components.AddSectionHeader(page, "ESP Generator (Status Proses Real-Time)", 19)

    Components.AddToggle(page, "Universal Generator ESP (Status Real-Time)", "Tampilkan ESP, Nama, Jarak & status generator (belum / sedang diproses pemain / selesai)", false, 20, function(on)
        GeneratorESP.Enabled = on
        if not on then
            GeneratorESP.ClearAll()
        else
            GeneratorESP.ScanAndRender()
        end
        Utils.Notify("ESP Generator", on and "ESP Generator aktif." or "ESP Generator dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddChipSelector(page, "Gaya Font ESP Generator", {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Oswald", Value = Enum.Font.Oswald, Font = Enum.Font.Oswald },
    }, Enum.Font.GothamBold, 21, function(val)
        GeneratorESP.Font = val
    end)

    Components.AddChipSelector(page, "Warna ESP Generator", {
        { Label = "Emas Listrik", Value = Color3.fromRGB(255, 196, 54), Color = Color3.fromRGB(255, 196, 54) },
        { Label = "Hijau Mesin", Value = Color3.fromRGB(72, 245, 140), Color = Color3.fromRGB(72, 245, 140) },
        { Label = "Biru Plasma", Value = Color3.fromRGB(75, 185, 255), Color = Color3.fromRGB(75, 185, 255) },
        { Label = "Merah Siaga", Value = Color3.fromRGB(255, 85, 105), Color = Color3.fromRGB(255, 85, 105) },
        { Label = "Ungu Spektral", Value = Color3.fromRGB(185, 115, 255), Color = Color3.fromRGB(185, 115, 255) },
        { Label = "Putih Terang", Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(255, 196, 54), 22, function(val)
        GeneratorESP.Color = val
    end)
end

-- ============================================================================
-- TAB 3: AIMBOT, AUTO PARRY & PERTAHANAN (Kebal Pukulan + Tahan Lapar & Haus)
-- ============================================================================
do
    local page = Components.CreateTab("Combat", "🎯", 3)
    Components.AddSectionHeader(page, "Auto Aimbot Presisi Tinggi", 1)

    Components.AddToggle(page, "Precision Auto Aimbot", "Bidik sasaran akurat otomatis (pukulan & senjata)", false, 2, function(on)
        Combat.AimbotEnabled = on
        if not on then
            Combat.CurrentTarget = nil
            Combat.HideLaser()
        end
        Utils.Notify("Auto Aimbot", on and "Aimbot presisi aktif." or "Aimbot dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Conditional RGB Weapon Laser", "Tampilkan laser RGB hanya saat memegang pistol/senjata (tanpa laser saat memukul)", true, 3, function(on)
        Combat.RGBLaserEnabled = on
        if not on then
            Combat.HideLaser()
        end
    end)

    Components.AddChipSelector(page, "Mode Pemicu Aimbot", {
        { Label = "Auto (Tool/Klik)", Value = "Auto" },
        { Label = "Selalu Kunci", Value = "Always" },
        { Label = "Tahan Klik Kanan", Value = "HoldRMB" },
    }, "Auto", 4, function(val)
        Combat.AimbotMode = val
    end)

    Components.AddChipSelector(page, "Bagian Tubuh Sasaran", {
        { Label = "Kepala (Head)", Value = "Head" },
        { Label = "Badan (Torso)", Value = "HumanoidRootPart" },
        { Label = "Terdekat FOV", Value = "Closest" },
    }, "Head", 5, function(val)
        Combat.AimPart = val
    end)

    Components.AddToggle(page, "Filter Tim (Abaikan Rekan Satu Tim)", "Jangan bidik teman satu tim pada map berbasis tim", true, 6, function(on)
        Combat.TeamCheck = on
    end)

    Components.AddToggle(page, "Visualisasi Lingkaran FOV Aimbot", "Visualisasi area jangkauan deteksi aimbot di layar", false, 7, function(on)
        Combat.ShowFOVCircle = on
        if Combat.FOVCircle then
            Combat.FOVCircle.Visible = on
        end
    end)

    Components.AddSlider(page, "Radius FOV Bidikan", 60, 600, 220, 0, 8, function(val)
        Combat.FOVRadius = val
        if Combat.FOVCircle then
            Combat.FOVCircle.Size = UDim2.new(0, val * 2, 0, val * 2)
        end
    end)

    Components.AddSlider(page, "Tingkat Akurasi / Kunci (1 = Instan)", 0.1, 1.0, 0.35, 2, 9, function(val)
        Combat.Smoothness = val
    end)

    Components.AddSectionHeader(page, "Auto Parry & Pertahanan Karakter", 10)

    Components.AddToggle(page, "Auto Parry & Counter-Block", "Otomatis menangkis saat lawan atau teman melancarkan pukulan di dekat Anda", false, 11, function(on)
        Combat.AutoParryEnabled = on
        Utils.Notify("Auto Parry", on and "Auto Parry aktif & memantau serangan sekitar!" or "Auto Parry dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddSlider(page, "Jarak Deteksi Auto Parry (Studs)", 6, 35, 16, 0, 12, function(val)
        Combat.ParryRange = val
    end)

    Components.AddToggle(page, "Melee Immunity & Anti-Knockback", "Anti-knockback, anti-ragdoll, dan tahan hitbox pukulan melee lawan", false, 13, function(on)
        Combat.MeleeImmunity = on
        if not on then
            Protection.RestoreEnemyHitboxes()
        end
        Utils.Notify("Kebal Pukulan", on and "Mode kebal pukulan & anti-mental aktif!" or "Mode kebal dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Survival Guard (Tahan Lapar & Haus)", "Menjaga indikator lapar (Hunger) dan haus (Thirst) tetap penuh secara interaktif", false, 14, function(on)
        Combat.HungerThirstGuard = on
        Utils.Notify("Survival Guard", on and "Tahan lapar & tahan haus aktif!" or "Tahan lapar & haus dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)
end

-- ============================================================================
-- TAB 4: CARRY SYSTEM (Interaktif Terlihat di Pemain Lain + Tombol Carry/Lepas)
-- ============================================================================
do
    local page = Components.CreateTab("Carry", "🫂", 4)
    Components.AddSectionHeader(page, "Kontrol Carry Interaktif (Replikasi Server)", 1)

    local carryStatusLabel = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = "  Target Terpilih: Belum ada pemain dipilih",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(carryStatusLabel, 7)
    Utils.RegisterText(carryStatusLabel, true, Theme.TextSecondary)

    -- Baris 2 Tombol Utama: Tombol "Carry" & Tombol "Lepas Carry"
    local actionRow = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        ZIndex = 14,
    }, page)

    local carryBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0.485, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Success,
        Font = Theme.FontBold,
        Text = "🫂 Carry",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
    }, actionRow)
    Utils.AddCorner(carryBtn, 8)

    local releaseCarryBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0.485, 0, 1, 0),
        Position = UDim2.new(0.515, 0, 0, 0),
        BackgroundColor3 = Theme.Danger,
        Font = Theme.FontBold,
        Text = "✋ Lepas Carry",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
    }, actionRow)
    Utils.AddCorner(releaseCarryBtn, 8)

    carryBtn.MouseButton1Click:Connect(function()
        SafeEngine.Run("CarryStart", function()
            if Carry.Start() and Carry.TargetPlayer then
                local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
                carryStatusLabel.Text = "  Status: Meng-carry " .. Carry.TargetPlayer.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
            end
        end)
    end)

    releaseCarryBtn.MouseButton1Click:Connect(function()
        SafeEngine.Run("CarryStop", function()
            Carry.Stop()
            carryStatusLabel.Text = Carry.TargetPlayer
                and ("  Target Terpilih: " .. Carry.TargetPlayer.DisplayName .. " (Dilepas)")
                or "  Target Terpilih: Belum ada pemain dipilih"
            Utils.Notify("Lepas Carry", "Target telah dilepaskan.", Theme.TextSecondary)
        end)
    end)

    Components.AddChipSelector(page, "Pilih Gaya Carry Lengkap", {
        { Label = "Carry Depan", Value = "Depan" },
        { Label = "Carry Belakang", Value = "Belakang" },
        { Label = "Carry di Pundak", Value = "Pundak" },
        { Label = "Carry di Seret", Value = "Seret" },
        { Label = "Carry di Kepala", Value = "Kepala" },
        { Label = "Carry Melayang", Value = "Melayang" },
    }, "Depan", 4, function(val)
        Carry.Style = val
        if Carry.Enabled and Carry.TargetPlayer then
            local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
            carryStatusLabel.Text = "  Status: Meng-carry " .. Carry.TargetPlayer.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
        end
        Utils.Notify("Gaya Carry", "Gaya diubah ke: Carry " .. val, Theme.Accent)
    end)

    Components.AddSectionHeader(page, "Pilih Teman / Player untuk Di-Carry", 5)

    local carryListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, carryListHolder)

    local function refreshCarryPlayers()
        for _, child in ipairs(carryListHolder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                count = count + 1
                local isSelected = (Carry.TargetPlayer == plr)
                local row = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    LayoutOrder = count,
                    ZIndex = 14,
                }, carryListHolder)
                Utils.AddCorner(row, 8)
                Utils.AddStroke(row, isSelected and Theme.Accent or Theme.BorderSubtle, 1, 0.25)

                local nameLbl = Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 15,
                }, row)
                Utils.RegisterText(nameLbl, false, Theme.TextPrimary)

                local pickBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 86, 0, 26),
                    Position = UDim2.new(1, -96, 0.5, -13),
                    BackgroundColor3 = isSelected and Theme.Success or Theme.Accent,
                    Font = Theme.FontBold,
                    Text = isSelected and "Terpilih ✓" or "Pilih Target",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 15,
                }, row)
                Utils.AddCorner(pickBtn, 6)

                pickBtn.MouseButton1Click:Connect(function()
                    if Carry.TargetPlayer and Carry.TargetPlayer ~= plr then
                        local _, oldHum = Utils.GetCharacter(Carry.TargetPlayer)
                        if oldHum then
                            oldHum.PlatformStand = false
                            if oldHum:GetState() == Enum.HumanoidStateType.Physics then
                                oldHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end
                        end
                    end
                    Carry.TargetPlayer = plr
                    if Carry.Enabled then
                        Carry.NativePromptTriggered = false
                        Carry.NativePromptTriggered = Carry.TryNativeMapCarry(plr)
                        local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
                        carryStatusLabel.Text = "  Status: Meng-carry " .. plr.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
                    else
                        carryStatusLabel.Text = "  Target Terpilih: " .. plr.DisplayName .. " (Tekan tombol Carry)"
                    end
                    refreshCarryPlayers()
                    Utils.Notify("Target Dipilih", "Siap meng-carry " .. plr.DisplayName .. ".", Theme.Accent)
                end)
            end
        end

        if count == 0 then
            local empty = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BgCard,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                ZIndex = 14,
            }, carryListHolder)
            Utils.AddCorner(empty, 8)
            Utils.Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = "Belum ada pemain lain di server untuk di-carry.",
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                ZIndex = 15,
            }, empty)
        end
    end

    refreshCarryPlayers()
    Utils.Track(Players.PlayerAdded:Connect(refreshCarryPlayers))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if Carry.TargetPlayer == plr then
            Carry.Stop()
            Carry.TargetPlayer = nil
            carryStatusLabel.Text = "  Target Terpilih: Belum ada pemain dipilih"
        end
        task.defer(refreshCarryPlayers)
    end))
end

-- ============================================================================
-- TAB 5: DANCE & EMOTE STUDIO (Replicated ke Semua Device Pemain Lain)
-- ============================================================================
do
    local page = Components.CreateTab("Dances", "💃", 5)
    Components.AddSectionHeader(page, "Studio Dance & Emote (Replikasi R6 & R15)", 1)

    Components.AddSlider(page, "Kecepatan Gerakan Dance", 0.5, 2.5, 1.0, 1, 2, function(val)
        Emotes.Speed = val
        if Emotes.ActiveTrack then
            pcall(function() Emotes.ActiveTrack:AdjustSpeed(val) end)
        end
    end)

    -- Input Custom Animation ID Roblox (Tereplikasi ke pemain lain)
    local customAnimCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(customAnimCard, 9)
    Utils.AddStroke(customAnimCard, Theme.BorderSubtle, 1, 0.3)

    local animBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -118, 0, 28),
        Position = UDim2.new(0, 10, 0.5, -14),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = "Custom Dance Animation ID (angka)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, customAnimCard)
    Utils.AddCorner(animBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, animBox)

    local playCustomBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 92, 0, 28),
        Position = UDim2.new(1, -102, 0.5, -14),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = "Play ID",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, customAnimCard)
    Utils.AddCorner(playCustomBtn, 6)
    Utils.RegisterAccent(playCustomBtn, "BackgroundColor3")

    playCustomBtn.MouseButton1Click:Connect(function()
        if animBox.Text ~= "" then
            Emotes.PlayAsset("Custom Dance", animBox.Text)
        else
            Utils.Notify("Dance ID", "Masukkan angka ID animasi Roblox terlebih dahulu.", Theme.Warning)
        end
    end)

    Components.AddButton(page, "Hentikan Dance / Reset Pose", "Hentikan animasi dance yang sedang aktif", "Stop Dance", 4, function()
        Emotes.Stop()
        Utils.Notify("Emote", "Dance dihentikan.", Theme.TextSecondary)
    end)

    Components.AddSectionHeader(page, "Daftar Dance Replikasi (R6 & R15)", 5)

    local danceGrid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.485, 0, 0, 34),
        CellPadding = UDim2.new(0.03, 0, 0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, danceGrid)

    for idx, d in ipairs(Emotes.Catalog) do
        local btn = Utils.Create("TextButton", {
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.22,
            Font = Theme.FontBold,
            Text = "🎵 " .. d.Label,
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 15,
        }, danceGrid)
        Utils.AddCorner(btn, 8)
        local stroke = Utils.AddStroke(btn, Theme.Accent, 1, 0.45)
        Utils.RegisterAccent(stroke, "Color")
        Utils.RegisterText(btn, true, Theme.TextPrimary)

        btn.MouseButton1Click:Connect(function()
            Emotes.PlayPreset(d)
        end)
    end
end

-- ============================================================================
-- TAB 6: MOVEMENT & PHYSICS (Smooth Fly & Analog-Safe NoClip)
-- ============================================================================
do
    local page = Components.CreateTab("Movement", "⚡", 6)
    Components.AddSectionHeader(page, "Pengaturan Lokomosi Karakter", 1)

    local wsSlider = Components.AddSlider(page, "Kecepatan Jalan (WalkSpeed)", 16, 250, 16, 0, 2, function(val)
        State.WalkSpeed = val
        local _, hum = Utils.GetCharacter()
        if hum then hum.WalkSpeed = val end
    end)

    local jpSlider = Components.AddSlider(page, "Daya Lompat (JumpPower)", 50, 300, 50, 0, 3, function(val)
        State.JumpPower = val
        local _, hum = Utils.GetCharacter()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end)

    local maxGrav = math.max(300, math.ceil(State.OriginalGravity))
    local gravSlider = Components.AddSlider(page, "Gravitasi Dunia (Workspace Gravity)", 0, maxGrav, State.OriginalGravity, 1, 4, function(val)
        State.Gravity = val
        workspace.Gravity = val
    end)

    local origGravStr = string.format("%.1f", State.OriginalGravity)
    Components.AddButton(page, "Reset Fisika ke Default", "Kembalikan WalkSpeed (16), JumpPower (50), Gravity (" .. origGravStr .. ")", "Reset All", 5, function()
        wsSlider.SetValue(16, true)
        jpSlider.SetValue(50, true)
        gravSlider.SetValue(State.OriginalGravity, true)
        Utils.Notify("Fisika Direset", "Nilai pergerakan dikembalikan ke bawaan.", Theme.Success)
    end)

    Components.AddSectionHeader(page, "Mode Navigasi & Inspeksi", 6)

    Components.AddToggle(page, "Free-Flight Inspector (Fly)", "Terbang halus seperti admin map tanpa mundur-mundur atau tersangkut (PC & Mobile)", false, 7, function(on)
        State.FlyEnabled = on
        if on then
            local _, hum = Utils.GetCharacter()
            if hum and hum.Sit then
                hum.Sit = false
            end
        else
            Physics.CleanupFly()
        end
        Utils.Notify("Free-Flight", on and "Mode terbang halus aktif." or "Mode terbang dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddSlider(page, "Kecepatan Terbang (Flight Speed)", 20, 250, 65, 0, 8, function(val)
        State.FlySpeed = val
    end)

    Components.AddToggle(
        page,
        "NoClip Geometry Inspector",
        "tidak disarankan untuk fitur NoClip ingin menembus tetapi analog di tarik berlebihan, jika ingin menembus tarik analog secara perlahan-lahan",
        false,
        9,
        function(on)
            State.NoclipEnabled = on
            if not on then Physics.RestoreNoclip() end
            Utils.Notify("NoClip", on and "NoClip aktif (tarik analog perlahan saat menembus)." or "Kolisi dipulihkan.", on and Theme.Warning or Theme.TextSecondary)
        end
    )

    Components.AddToggle(page, "Lompat Tanpa Batas (Infinite Jump)", "Lompat tanpa batas di udara", false, 10, function(on)
        State.InfiniteJumpEnabled = on
    end)
end

-- ============================================================================
-- TAB 7: TELEPORTASI & VIEW PEMAIN (Jarak Real-Time & Remote Stream API)
-- ============================================================================
do
    local page = Components.CreateTab("Teleport", "⌖", 7)
    Components.AddSectionHeader(page, "Koordinat & Manajemen Lokasi (Waypoint)", 1)

    local posCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(posCard, 9)
    Utils.AddStroke(posCard, Theme.BorderSubtle, 1, 0.3)

    UI.TelemetryLabels.Coords = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -112, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "XYZ: 0.0, 0.0, 0.0",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, posCard)

    local copyPosBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 92, 0, 28),
        Position = UDim2.new(1, -104, 0.5, -14),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontBold,
        Text = "Salin CFrame",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, posCard)
    Utils.AddCorner(copyPosBtn, 6)

    copyPosBtn.MouseButton1Click:Connect(function()
        local _, _, root = Utils.GetCharacter()
        if root then
            local p = root.Position
            local cfStr = string.format("CFrame.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
            if Utils.CopyText(cfStr) then
                Utils.Notify("CFrame Tersalin", cfStr, Theme.Success)
            else
                Utils.Notify("CFrame Saat Ini", cfStr, Theme.Accent)
            end
        end
    end)

    local wpInputCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(wpInputCard, 9)
    Utils.AddStroke(wpInputCard, Theme.BorderSubtle, 1, 0.3)

    local wpBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -124, 0, 30),
        Position = UDim2.new(0, 10, 0.5, -15),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = "Nama lokasi waypoint (mis. Spawn, Puncak)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, wpInputCard)
    Utils.AddCorner(wpBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, wpBox)

    local saveWpBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 96, 0, 30),
        Position = UDim2.new(1, -106, 0.5, -15),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = "+ Simpan Titik",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, wpInputCard)
    Utils.AddCorner(saveWpBtn, 6)
    Utils.RegisterAccent(saveWpBtn, "BackgroundColor3")

    local wpListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, wpListHolder)

    local wpDistanceLabels = {}

    local function renderWaypoints()
        table.clear(wpDistanceLabels)
        for _, child in ipairs(wpListHolder:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for idx, wp in ipairs(State.Waypoints) do
            local row = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = Theme.BgSecondary,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                LayoutOrder = idx,
                ZIndex = 15,
            }, wpListHolder)
            Utils.AddCorner(row, 7)
            Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.3)

            local infoLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(1, -138, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = string.format("%s | Jarak: -- m", wp.Name),
                TextColor3 = Theme.TextPrimary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 16,
            }, row)
            wpDistanceLabels[idx] = { Label = infoLbl, Waypoint = wp }

            local tpBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 68, 0, 24),
                Position = UDim2.new(1, -112, 0.5, -12),
                BackgroundColor3 = Theme.Accent,
                Font = Theme.FontBold,
                Text = "Teleport",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 16,
            }, row)
            Utils.AddCorner(tpBtn, 5)
            Utils.RegisterAccent(tpBtn, "BackgroundColor3")

            local delBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 28, 0, 24),
                Position = UDim2.new(1, -38, 0.5, -12),
                BackgroundColor3 = Theme.Danger,
                Font = Theme.FontBold,
                Text = "✕",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 16,
            }, row)
            Utils.AddCorner(delBtn, 5)

            tpBtn.MouseButton1Click:Connect(function()
                local ok, dist = Utils.SafeTeleport(wp.CFrame)
                if ok then
                    Utils.Notify("Teleportasi Berhasil", string.format("Berpindah ke %s (Jarak: %.0f m)", wp.Name, dist), Theme.Success)
                end
            end)

            delBtn.MouseButton1Click:Connect(function()
                table.remove(State.Waypoints, idx)
                renderWaypoints()
            end)
        end
    end

    saveWpBtn.MouseButton1Click:Connect(function()
        local _, _, root = Utils.GetCharacter()
        if not root then
            Utils.Notify("Gagal Menyimpan", "Karakter utama belum tersedia.", Theme.Danger)
            return
        end
        local name = wpBox.Text ~= "" and wpBox.Text or ("Titik #" .. tostring(#State.Waypoints + 1))
        table.insert(State.Waypoints, { Name = name, CFrame = root.CFrame })
        wpBox.Text = ""
        renderWaypoints()
        Utils.Notify("Waypoint Tersimpan", "Lokasi '" .. name .. "' berhasil disimpan.", Theme.Success)
    end)

    Components.AddSectionHeader(page, "Teleportasi & View Pemain Lain (Jarak Real-Time)", 5)

    local playerListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, playerListHolder)

    local playerDistanceRows = {}

    local function stopSpectating(notifyUser)
        State.SpectatingPlayer = nil
        local cam = workspace.CurrentCamera
        local _, myHum = Utils.GetCharacter(LocalPlayer)
        if cam and myHum then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = myHum
        end
        if notifyUser then
            Utils.Notify("View Dimatikan", "Kamera kembali ke karakter Anda.", Theme.TextSecondary)
        end
    end

    local function refreshPlayerList()
        table.clear(playerDistanceRows)
        for _, child in ipairs(playerListHolder:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                count = count + 1
                local row = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    LayoutOrder = count,
                    ZIndex = 15,
                }, playerListHolder)
                Utils.AddCorner(row, 8)
                Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.3)

                Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -158, 0, 18),
                    Position = UDim2.new(0, 10, 0, 6),
                    BackgroundTransparency = 1,
                    Font = Theme.FontBold,
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 16,
                }, row)

                local distLbl = Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -158, 0, 16),
                    Position = UDim2.new(0, 10, 0, 25),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = "Jarak: Menghitung...",
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 16,
                }, row)

                playerDistanceRows[plr] = distLbl

                local tpBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 68, 0, 26),
                    Position = UDim2.new(1, -142, 0.5, -13),
                    BackgroundColor3 = Theme.Accent,
                    Font = Theme.FontBold,
                    Text = "Teleport",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 16,
                }, row)
                Utils.AddCorner(tpBtn, 5)
                Utils.RegisterAccent(tpBtn, "BackgroundColor3")

                local isSpec = (State.SpectatingPlayer == plr)
                local viewBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 62, 0, 26),
                    Position = UDim2.new(1, -68, 0.5, -13),
                    BackgroundColor3 = isSpec and Theme.Warning or Theme.BgControl,
                    Font = Theme.FontBold,
                    Text = isSpec and "Unview" or "View",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 16,
                }, row)
                Utils.AddCorner(viewBtn, 5)

                tpBtn.MouseButton1Click:Connect(function()
                    local targetPos = Utils.GetTargetWorldPosition(plr)
                    if targetPos then
                        local targetRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        local destCF = targetRoot and (targetRoot.CFrame * CFrame.new(0, 0.5, 3)) or CFrame.new(targetPos + Vector3.new(0, 1.5, 3))
                        local ok, dist = Utils.SafeTeleport(destCF)
                        if ok then
                            Utils.Notify("Teleportasi Pemain", string.format("Berpindah ke %s (Jarak: %.0f m)", plr.DisplayName, dist), Theme.Success)
                        end
                    else
                        Utils.Notify("Target Belum Terdeteksi", "Karakter target belum spawn atau berada di luar zona.", Theme.Warning)
                    end
                end)

                viewBtn.MouseButton1Click:Connect(function()
                    if State.SpectatingPlayer == plr then
                        stopSpectating(true)
                    else
                        State.SpectatingPlayer = plr
                        local targetPos = Utils.GetTargetWorldPosition(plr)
                        if targetPos then
                            task.spawn(function()
                                pcall(function()
                                    LocalPlayer:RequestStreamAroundAsync(targetPos, 4)
                                end)
                            end)
                        end
                        local cam = workspace.CurrentCamera
                        local targetHum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                        local targetRoot = plr.Character and (plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character.PrimaryPart)
                        if cam and (targetHum or targetRoot) then
                            cam.CameraType = Enum.CameraType.Custom
                            cam.CameraSubject = targetHum or targetRoot
                        end
                        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
                        local distStr = (targetPos and myRoot)
                            and string.format(" (Jarak: %.0f m)", (targetPos - myRoot.Position).Magnitude)
                            or ""
                        Utils.Notify("Mode View Aktif", "Memantau " .. plr.DisplayName .. distStr, Theme.Warning)
                    end
                    refreshPlayerList()
                end)
            end
        end

        if count == 0 then
            local empty = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BgCard,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                ZIndex = 15,
            }, playerListHolder)
            Utils.AddCorner(empty, 8)
            Utils.Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = "Belum ada pemain lain di server ini.",
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                ZIndex = 16,
            }, empty)
        end
    end

    -- Sinkronisasi Jarak Teleport & Remote View Stream API Real-Time
    Utils.Track(RunService.Heartbeat:Connect(function()
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local myPos = myRoot and myRoot.Position

        -- 1. Update jarak ke semua Waypoint tersimpan
        for _, item in pairs(wpDistanceLabels) do
            if item.Label and item.Label.Parent then
                if myPos then
                    local d = (item.Waypoint.CFrame.Position - myPos).Magnitude
                    item.Label.Text = string.format("%s | Jarak: %.0f m", item.Waypoint.Name, d)
                else
                    item.Label.Text = string.format("%s (%.0f, %.0f, %.0f)", item.Waypoint.Name, item.Waypoint.CFrame.X, item.Waypoint.CFrame.Y, item.Waypoint.CFrame.Z)
                end
            end
        end

        -- 2. Update jarak ke semua pemain lain secara real-time
        for plr, lbl in pairs(playerDistanceRows) do
            if lbl and lbl.Parent then
                local tPos = Utils.GetTargetWorldPosition(plr)
                if tPos and myPos then
                    local dist = (tPos - myPos).Magnitude
                    lbl.Text = string.format("Jarak: %.0f m  |  XYZ: %.0f, %.0f, %.0f", dist, tPos.X, tPos.Y, tPos.Z)
                else
                    lbl.Text = "Jarak: Menunggu karakter spawn..."
                end
            end
        end

        -- 3. Jaga kamera & Streaming API tetap terkunci saat View pemain jarak jauh
        local specPlr = State.SpectatingPlayer
        if specPlr then
            if not specPlr.Parent then
                stopSpectating(false)
                refreshPlayerList()
            else
                local cam = workspace.CurrentCamera
                local targetChar = specPlr.Character
                local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                local targetRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart)
                local subject = targetHum or targetRoot

                if cam and subject and cam.CameraSubject ~= subject then
                    cam.CameraType = Enum.CameraType.Custom
                    cam.CameraSubject = subject
                end

                local now = os.clock()
                if (now - State.SpectateStreamTick) >= 0.75 then
                    State.SpectateStreamTick = now
                    local tPos = Utils.GetTargetWorldPosition(specPlr)
                    if tPos then
                        task.spawn(function()
                            pcall(function()
                                LocalPlayer:RequestStreamAroundAsync(tPos, 3)
                            end)
                        end)
                    end
                end
            end
        end
    end))

    refreshPlayerList()
    Utils.Track(Players.PlayerAdded:Connect(refreshPlayerList))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if State.SpectatingPlayer == plr then
            stopSpectating(false)
        end
        task.defer(refreshPlayerList)
    end))
end

-- ============================================================================
-- TAB 8: VISUALS & ENVIRONMENT
-- ============================================================================
do
    local page = Components.CreateTab("Visuals", "☀", 8)
    Components.AddSectionHeader(page, "Kontrol Kamera & Pencahayaan", 1)

    local fovSlider = Components.AddSlider(page, "Sudut Pandang Kamera (FOV)", 40, 120, 70, 0, 2, function(val)
        State.CameraFOV = val
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = val
        end
    end)

    UI.FullbrightToggle = Components.AddToggle(page, "Pencahayaan Penuh (Fullbright Studio)", "Hilangkan bayangan gelap dan terangkan pencahayaan", false, 3, function(on)
        State.FullbrightEnabled = on
        if on then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        else
            local orig = State.OriginalLighting
            Lighting.Brightness = orig.Brightness
            Lighting.ClockTime = orig.ClockTime
            Lighting.GlobalShadows = orig.GlobalShadows
            Lighting.Ambient = orig.Ambient
            Lighting.OutdoorAmbient = orig.OutdoorAmbient
        end
        Utils.Notify("Lighting", on and "Fullbright aktif." or "Pencahayaan asli dipulihkan.", Theme.Accent)
    end)

    UI.NoFogToggle = Components.AddToggle(page, "Hapus Kabut Atmosfer (No Fog)", "Hapus kabut FogEnd dan Atmosphere Density modern", false, 4, function(on)
        State.NoFogEnabled = on
        local currentAtmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if on then
            Lighting.FogEnd = 100000
            if currentAtmo then
                if not State.OriginalAtmosphere or State.OriginalAtmosphere.Instance ~= currentAtmo then
                    State.OriginalAtmosphere = { Instance = currentAtmo, Density = currentAtmo.Density }
                end
                currentAtmo.Density = 0
            end
        else
            Lighting.FogEnd = State.OriginalLighting.FogEnd
            if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance and State.OriginalAtmosphere.Instance.Parent then
                State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
            end
        end
    end)

    local todSlider = Components.AddSlider(page, "Waktu Siang / Malam Klien (Jam)", 0, 24, math.floor(Lighting.ClockTime), 1, 5, function(val)
        Lighting.ClockTime = val
    end)

    Components.AddButton(page, "Reset Kamera & Pencahayaan", "Pulihkan FOV (70), toggle, dan pencahayaan bawaan", "Reset", 6, function()
        fovSlider.SetValue(70, true)
        if UI.FullbrightToggle then UI.FullbrightToggle.SetState(false, true) end
        if UI.NoFogToggle then UI.NoFogToggle.SetState(false, true) end

        local orig = State.OriginalLighting
        Lighting.Brightness = orig.Brightness
        Lighting.ClockTime = orig.ClockTime
        Lighting.FogEnd = orig.FogEnd
        Lighting.FogStart = orig.FogStart
        Lighting.GlobalShadows = orig.GlobalShadows
        Lighting.Ambient = orig.Ambient
        Lighting.OutdoorAmbient = orig.OutdoorAmbient
        todSlider.SetValue(orig.ClockTime, false)

        if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance and State.OriginalAtmosphere.Instance.Parent then
            State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
        end
        Utils.Notify("Visual Direset", "Kamera, toggle, dan pencahayaan dipulihkan.", Theme.Success)
    end)
end

-- ============================================================================
-- TAB 9: SETTINGS, ANTI-BUG / ERROR ENGINE, FONT & COLOR CUSTOMIZER
-- ============================================================================
local unloadHub = nil

do
    local page = Components.CreateTab("Settings", "⚙", 9)
    Components.AddSectionHeader(page, "Sistem Anti-Bug / Error & Anti-AFK", 1)

    Components.AddToggle(page, "Anti-Bug & Auto-Recovery Engine (AKTIF / OFF)", "Mencegah bug/error pada setiap fitur dan langsung memperbaiki otomatis jika terjadi gangguan", true, 2, function(on)
        Protection.AntiBugEnabled = on
        if UI.StatusLabel and UI.StatusLabel.Parent then
            UI.StatusLabel.Text = on and "Anti-Bug: AKTIF" or "Anti-Bug: OFF"
        end
        Utils.Notify("Anti-Bug Engine", on and "Anti-Bug & Auto-Repair AKTIF." or "Anti-Bug dimatikan (OFF).", on and Theme.Success or Theme.Warning)
    end)

    Components.AddToggle(page, "Anti-AFK Otomatis (Semua Map)", "Mencegah disconnect otomatis saat diam lebih dari 20 menit", true, 3, function(on)
        Protection.AntiAFKEnabled = on
        Utils.Notify("Anti-AFK", on and "Anti-AFK aktif." or "Anti-AFK dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddSectionHeader(page, "Kustomisasi Font & Warna Panel Menu", 4)

    Components.AddChipSelector(page, "Pilih Gaya Font Panel Menu", {
        { Label = "Gotham Modern", Value = "Gotham", Font = Enum.Font.GothamSemibold },
        { Label = "Fredoka Bulat", Value = "Fredoka", Font = Enum.Font.FredokaOne },
        { Label = "Creepster Spooky", Value = "Creepster", Font = Enum.Font.Creepster },
        { Label = "Fondamento Klasik", Value = "Fondamento", Font = Enum.Font.Fondamento },
        { Label = "Bangers Komik", Value = "Bangers", Font = Enum.Font.Bangers },
        { Label = "Roboto Mono", Value = "RobotoMono", Font = Enum.Font.RobotoMono },
        { Label = "Merriweather", Value = "Merriweather", Font = Enum.Font.Merriweather },
        { Label = "Ubuntu Clean", Value = "Ubuntu", Font = Enum.Font.Ubuntu },
        { Label = "Oswald Tegas", Value = "Oswald", Font = Enum.Font.Oswald },
    }, "Gotham", 5, function(val)
        local fontMap = {
            Gotham = { Enum.Font.GothamSemibold, Enum.Font.GothamBold },
            Fredoka = { Enum.Font.FredokaOne, Enum.Font.FredokaOne },
            Creepster = { Enum.Font.Creepster, Enum.Font.Creepster },
            Fondamento = { Enum.Font.Fondamento, Enum.Font.Fondamento },
            Bangers = { Enum.Font.Bangers, Enum.Font.Bangers },
            RobotoMono = { Enum.Font.RobotoMono, Enum.Font.RobotoMono },
            Merriweather = { Enum.Font.Merriweather, Enum.Font.Merriweather },
            Ubuntu = { Enum.Font.Ubuntu, Enum.Font.Ubuntu },
            Oswald = { Enum.Font.Oswald, Enum.Font.Oswald },
        }
        local pair = fontMap[val] or fontMap.Gotham
        Theme.FontFamily = pair[1]
        Theme.FontBold = pair[2]
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Font Diperbarui", "Menggunakan font: " .. val, Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Aksen Tema Panel", {
        { Label = "Pumpkin Gold", Value = Color3.fromRGB(255, 118, 26), Color = Color3.fromRGB(255, 118, 26) },
        { Label = "Blood Crimson", Value = Color3.fromRGB(220, 48, 78), Color = Color3.fromRGB(220, 48, 78) },
        { Label = "Spectral Violet", Value = Color3.fromRGB(155, 89, 245), Color = Color3.fromRGB(155, 89, 245) },
        { Label = "Poison Emerald", Value = Color3.fromRGB(39, 194, 108), Color = Color3.fromRGB(39, 194, 108) },
        { Label = "Cobalt Blue", Value = Color3.fromRGB(79, 124, 255), Color = Color3.fromRGB(79, 124, 255) },
        { Label = "Amber Gold", Value = Color3.fromRGB(243, 168, 24), Color = Color3.fromRGB(243, 168, 24) },
    }, Color3.fromRGB(255, 118, 26), 6, function(val)
        Utils.SetAccentColor(val)
        Utils.Notify("Tema Diperbarui", "Warna aksen panel diperbarui.", val)
    end)

    Components.AddChipSelector(page, "Warna Font Panel Menu", {
        { Label = "Auto Kontras", Value = "Auto", Color = Color3.fromRGB(255, 210, 140) },
        { Label = "Putih Tulang", Value = Color3.fromRGB(255, 246, 235), Color = Color3.fromRGB(255, 246, 235) },
        { Label = "Oranye Labu", Value = Color3.fromRGB(255, 162, 72), Color = Color3.fromRGB(255, 162, 72) },
        { Label = "Ungu Pastel", Value = Color3.fromRGB(218, 178, 255), Color = Color3.fromRGB(218, 178, 255) },
        { Label = "Hijau Mint", Value = Color3.fromRGB(145, 255, 195), Color = Color3.fromRGB(145, 255, 195) },
        { Label = "Hitam Gelap", Value = Color3.fromRGB(22, 18, 30), Color = Color3.fromRGB(22, 18, 30) },
    }, "Auto", 7, function(val)
        Theme.FontColorMode = val
        Utils.ApplyMenuFontAndColors()
    end)

    Components.AddChipSelector(page, "Latar Belakang Font Menu (Tipis & Adaptif)", {
        { Label = "Tanpa Latar", Value = "None", Color = Color3.fromRGB(40, 31, 58) },
        { Label = "Obsidian Tipis", Value = Color3.fromRGB(16, 12, 24), Color = Color3.fromRGB(16, 12, 24) },
        { Label = "Ungu Malam", Value = Color3.fromRGB(36, 22, 58), Color = Color3.fromRGB(36, 22, 58) },
        { Label = "Coklat Labu", Value = Color3.fromRGB(48, 26, 14), Color = Color3.fromRGB(48, 26, 14) },
        { Label = "Merah Gelap", Value = Color3.fromRGB(52, 16, 24), Color = Color3.fromRGB(52, 16, 24) },
        { Label = "Putih Kabut", Value = Color3.fromRGB(238, 232, 245), Color = Color3.fromRGB(238, 232, 245) },
    }, "None", 8, function(val)
        if val == "None" then
            Theme.FontBgEnabled = false
        else
            Theme.FontBgEnabled = true
            Theme.FontBgColor = val
            Theme.FontBgTransparency = 0.68
        end
        Utils.ApplyMenuFontAndColors()
    end)

    Components.AddSectionHeader(page, "Kontrol Pintasan & Pembersihan Panel", 9)

    Components.AddButton(page, "Pintasan Sembunyikan UI (RightShift)", "Atau ketuk logo labu 3D di layar kapan saja", "Hide UI", 10, function()
        App.IsOpen = false
        UI.MainFrame.Visible = false
    end)

    unloadHub = function()
        State.FlyEnabled = false
        State.NoclipEnabled = false
        State.InfiniteJumpEnabled = false
        ESP.Enabled = false
        ItemESP.Enabled = false
        GeneratorESP.Enabled = false
        Combat.AimbotEnabled = false
        Combat.AutoParryEnabled = false
        Combat.MeleeImmunity = false
        Combat.HungerThirstGuard = false
        Protection.AntiAFKEnabled = false
        Protection.AntiBugEnabled = false

        Physics.CleanupFly()
        Physics.RestoreNoclip()
        ESP.ClearAll()
        ItemESP.ClearAll()
        GeneratorESP.ClearAll()
        Combat.HideLaser()
        if Combat.LaserPart then Combat.LaserPart:Destroy() end
        Carry.Stop()
        Emotes.Stop()
        Protection.RestoreEnemyHitboxes()

        local _, hum, root = Utils.GetCharacter()
        if root and State.IsTeleportLocking then
            root.Anchored = State.PreTeleportAnchored
            State.IsTeleportLocking = false
        end
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
            hum.AutoRotate = true
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CameraSubject = hum
                workspace.CurrentCamera.FieldOfView = 70
            end
        end

        workspace.Gravity = State.OriginalGravity

        local orig = State.OriginalLighting
        Lighting.Brightness = orig.Brightness
        Lighting.ClockTime = orig.ClockTime
        Lighting.FogEnd = orig.FogEnd
        Lighting.FogStart = orig.FogStart
        Lighting.GlobalShadows = orig.GlobalShadows
        Lighting.Ambient = orig.Ambient
        Lighting.OutdoorAmbient = orig.OutdoorAmbient

        if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance and State.OriginalAtmosphere.Instance.Parent then
            State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
        end

        for _, conn in ipairs(Connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(Connections)
        table.clear(State.AccentObjects)
        table.clear(State.AccentCallbacks)
        table.clear(State.ActiveToggleTracks)
        table.clear(State.ThemedTexts)
        table.clear(ESP.RandomColorMap)
        table.clear(Protection.HungerThirstValues)

        if UI.ScreenGui then
            UI.ScreenGui:Destroy()
        end
    end

    if typeof(getgenv) == "function" then
        getgenv().BSS_UnloadOld = unloadHub
    end

    Components.AddButton(page, "Unload & Bersihkan Panel", "Putus semua loop, pulihkan bawaan karakter/map, dan tutup GUI", "Unload", 11, unloadHub)
end

-- ============================================================================
-- TAB 10: INFORMASI (DISCORD, DONASI & PESAN BANTUAN BUG/ERROR)
-- ============================================================================
do
    local page = Components.CreateTab("Informasi", "ⓘ", 10)
    Components.AddSectionHeader(page, "Informasi Pembuat & Dukungan", 1)

    local infoCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 96),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(infoCard, 9)
    local stroke = Utils.AddStroke(infoCard, Theme.Accent, 1.2, 0.25)
    Utils.RegisterAccent(stroke, "Color")

    local h1 = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "🎃 " .. App.Name .. " — Universal Edition",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, infoCard)
    Utils.RegisterText(h1, true, Theme.TextPrimary)

    local h2 = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 60),
        Position = UDim2.new(0, 12, 0, 30),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Terima kasih telah menggunakan BimSakSin Hub v3.0! Semoga hari-hari kalian menyenangkan.\njika ada bug/error pada fitur dan fitur tidak berfungsi, beritau admin/dev melaluin discord yang tertera.",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, infoCard)
    Utils.RegisterText(h2, false, Theme.TextSecondary)

    Components.AddSectionHeader(page, "Tautan Resmi Komunitas & Donasi", 3)

    Components.AddButton(page, "Link Donasi / Dukungan Dev", App.DonationUrl, "Salin Link", 4, function()
        if Utils.CopyText(App.DonationUrl) then
            Utils.Notify("Link Donasi Tersalin!", App.DonationUrl, Theme.Success)
        else
            Utils.Notify("Link Donasi", App.DonationUrl, Theme.Accent)
        end
    end)

    Components.AddButton(page, "Link Server Discord Resmi", App.DiscordUrl, "Salin Link", 5, function()
        if Utils.CopyText(App.DiscordUrl) then
            Utils.Notify("Link Discord Tersalin!", App.DiscordUrl, Theme.Success)
        else
            Utils.Notify("Link Discord", App.DiscordUrl, Theme.Accent)
        end
    end)
end

-- ============================================================================
-- 16. RUNTIME LOOPS & EVENT HANDLERS
-- ============================================================================
do
    local function togglePanelVisibility()
        App.IsOpen = not App.IsOpen
        UI.MainFrame.Visible = App.IsOpen
    end

    UI.FloatingToggle.MouseButton1Click:Connect(togglePanelVisibility)
    UI.CloseBtn.MouseButton1Click:Connect(function()
        App.IsOpen = false
        UI.MainFrame.Visible = false
        Utils.Notify("Disembunyikan", "Ketuk logo labu 3D atau tekan RightShift untuk membuka.", Theme.Accent)
    end)

    local function getTitleFittedMinWidth()
        local titleWidth = (UI.TitleLabel and UI.TitleLabel.TextBounds.X > 0) and UI.TitleLabel.TextBounds.X or 172
        return math.max(278, math.ceil(titleWidth) + 148)
    end

    local function applyResponsiveLayout(panelWidth)
        local sidebarW = (panelWidth < 500) and math.clamp(math.floor(panelWidth * 0.30), 116, 166) or 166
        UI.Sidebar.Size = UDim2.new(0, sidebarW, 1, -54)
        UI.ContentContainer.Size = UDim2.new(1, -sidebarW, 1, -54)
        UI.ContentContainer.Position = UDim2.new(0, sidebarW, 0, 54)
    end

    -- Drag Resize
    do
        local resizing = false
        local resizeInput = nil
        local resizeStartPos = nil
        local resizeStartSize = nil

        Utils.Track(UI.ResizeHandle.InputBegan:Connect(function(input)
            if App.IsMinimized then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeInput = input
                resizeStartPos = input.Position
                resizeStartSize = UI.MainFrame.AbsoluteSize
            end
        end))

        Utils.Track(UserInputService.InputChanged:Connect(function(input)
            if resizing and resizeStartPos and resizeStartSize and (input == resizeInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - resizeStartPos
                local vp = (UI.ScreenGui and UI.ScreenGui.AbsoluteSize) or Vector2.new(1280, 720)
                local minW = math.max(320, getTitleFittedMinWidth())
                local maxW = math.max(minW, vp.X - 24)
                local maxH = math.max(220, vp.Y - 24)

                local newW = math.clamp(math.floor(resizeStartSize.X + delta.X + 0.5), minW, maxW)
                local newH = math.clamp(math.floor(resizeStartSize.Y + delta.Y + 0.5), 220, maxH)

                App.ExpandedWidth = newW
                App.ExpandedHeight = newH
                UI.MainFrame.Size = UDim2.new(0, newW, 0, newH)
                applyResponsiveLayout(newW)
            end
        end))

        Utils.Track(UserInputService.InputEnded:Connect(function(input)
            if resizing and (input == resizeInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
                resizing = false
                resizeInput = nil
            end
        end))
    end

    UI.MinimizeBtn.MouseButton1Click:Connect(function()
        if not App.IsMinimized then
            local curSize = UI.MainFrame.AbsoluteSize
            if curSize.X >= 260 and curSize.Y >= 180 then
                App.ExpandedWidth = math.floor(curSize.X + 0.5)
                App.ExpandedHeight = math.floor(curSize.Y + 0.5)
            end
        end

        App.IsMinimized = not App.IsMinimized
        UI.Sidebar.Visible = not App.IsMinimized
        UI.ContentContainer.Visible = not App.IsMinimized
        if UI.ResizeHandle then
            UI.ResizeHandle.Visible = not App.IsMinimized
        end
        UI.MinimizeBtn.Text = App.IsMinimized and "□" or "—"

        local targetWidth = App.IsMinimized and getTitleFittedMinWidth() or App.ExpandedWidth
        local targetHeight = App.IsMinimized and 54 or App.ExpandedHeight
        if not App.IsMinimized then
            applyResponsiveLayout(targetWidth)
        end

        Utils.Tween(UI.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, targetWidth, 0, targetHeight)
        })
    end)

    Utils.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            togglePanelVisibility()
        end
    end))

    Utils.Track(UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJumpEnabled then
            local _, hum = Utils.GetCharacter()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end))

    local function onCharacterAdded(char)
        table.clear(Physics.NoclipCache)
        State.IsTeleportLocking = false
        Emotes.Playing = false
        Emotes.ActiveTrack = nil
        Physics.CleanupFly()

        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            if State.WalkSpeed ~= 16 then hum.WalkSpeed = State.WalkSpeed end
            if State.JumpPower ~= 50 then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
    end

    if LocalPlayer.Character then
        task.spawn(onCharacterAdded, LocalPlayer.Character)
    end
    Utils.Track(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))

    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        ESP.RemovePlayer(plr)
        ESP.RandomColorMap[plr.UserId] = nil
    end))

    -- Stepped Loop: Noclip, Carry Alignment, Melee Immunity, & Auto Parry
    Utils.Track(RunService.Stepped:Connect(function()
        SafeEngine.Run("SteppedLoop", function()
            if State.NoclipEnabled then
                local char = Utils.GetCharacter()
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if Physics.NoclipCache[part] == nil then
                                Physics.NoclipCache[part] = part.CanCollide
                            end
                            if part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end

            if Carry.Enabled then
                Carry.Step()
            end

            if Combat.MeleeImmunity then
                Protection.StepMeleeImmunity()
            end

            if Combat.AutoParryEnabled then
                Combat.StepAutoParry()
            end
        end)
    end))

    -- Unified RenderStepped Loop: Smooth Admin Fly, Aimbot + RGB Gun Laser, Animasi Labu 3D, & Throttled Telemetry/ESP
    local frameCount = 0
    local lastTick = os.clock()
    local lastWorldScan = 0

    Utils.Track(RunService.RenderStepped:Connect(function(dt)
        local tNow = os.clock()

        SafeEngine.Run("RenderSteppedLoop", function()
            -- 1. Animasi Hidup pada Logo Labu 3D (Lewati labu menu jika panel disembunyikan)
            local pulse = (math.sin(tNow * 3.4) + 1) * 0.5
            local eyeGlow = Color3.fromRGB(255, math.floor(195 + pulse * 60), math.floor(55 + pulse * 95))
            for _, pData in ipairs(UI.Pumpkins) do
                if (App.IsOpen or not pData.IsMenuPumpkin) and pData.Holder and pData.Holder.Parent then
                    pData.EyeLeft.BackgroundColor3 = eyeGlow
                    pData.EyeRight.BackgroundColor3 = eyeGlow
                    pData.Mouth.BackgroundColor3 = eyeGlow
                    if pData.IsHero then
                        pData.Aura.BackgroundTransparency = 0.62 + (1 - pulse) * 0.18
                        pData.Holder.Rotation = math.sin(tNow * 2.2) * 5.5
                    end
                end
            end

            -- 2. Smooth Admin Flight Loop
            Physics.StepSmoothFly(dt)

            -- 3. Auto Aimbot & Conditional RGB Weapon Laser
            local cam = workspace.CurrentCamera
            if Combat.AimbotEnabled and cam then
                local tool, isGun = Combat.GetEquippedRangedWeapon()
                local shouldLock = false

                if Combat.AimbotMode == "Always" then
                    shouldLock = true
                elseif Combat.AimbotMode == "HoldRMB" then
                    shouldLock = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    local isClicking = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                    shouldLock = (tool ~= nil) or isClicking
                end

                if shouldLock then
                    local targetPlr, aimPart = Combat.FindBestTarget()
                    Combat.CurrentTarget = targetPlr
                    if targetPlr and aimPart and (aimPart.Position - cam.CFrame.Position).Magnitude > 0.05 then
                        local desiredCF = CFrame.lookAt(cam.CFrame.Position, aimPart.Position)
                        if desiredCF == desiredCF then
                            cam.CFrame = cam.CFrame:Lerp(desiredCF, math.clamp(Combat.Smoothness, 0.08, 1))
                        end

                        if Combat.RGBLaserEnabled and isGun and tool then
                            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                            if handle then
                                Combat.UpdateLaser(handle.Position, aimPart.Position)
                            else
                                Combat.HideLaser()
                            end
                        else
                            Combat.HideLaser()
                        end
                    else
                        Combat.HideLaser()
                    end
                else
                    Combat.CurrentTarget = nil
                    Combat.HideLaser()
                end
            else
                Combat.HideLaser()
            end
        end)

        -- 4. Throttled Telemetry, Persistence & ESP Updater (~6 Hz)
        frameCount = frameCount + 1
        local elapsed = tNow - lastTick
        if elapsed >= 0.16 then
            local fps = math.floor((frameCount / elapsed) + 0.5)
            frameCount = 0
            lastTick = tNow

            SafeEngine.Run("TelemetryAndESP", function()
                if UI.TelemetryLabels.FPS then
                    UI.TelemetryLabels.FPS.Text = tostring(fps) .. " FPS"
                end

                local pingOk, pingVal = pcall(function()
                    return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                end)
                if UI.TelemetryLabels.Ping then
                    UI.TelemetryLabels.Ping.Text = pingOk and (tostring(math.floor(pingVal + 0.5)) .. " ms") or "N/A"
                end

                local memOk, memVal = pcall(function()
                    return Stats:GetTotalMemoryUsageMb()
                end)
                if UI.TelemetryLabels.Memory then
                    UI.TelemetryLabels.Memory.Text = memOk and (string.format("%.1f MB", memVal)) or "N/A"
                end

                if UI.TelemetryLabels.Players then
                    UI.TelemetryLabels.Players.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers)
                end

                local _, hum, root = Utils.GetCharacter()
                if UI.TelemetryLabels.Coords then
                    if root then
                        local p = root.Position
                        UI.TelemetryLabels.Coords.Text = string.format("XYZ: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
                    else
                        UI.TelemetryLabels.Coords.Text = "XYZ: Menunggu karakter..."
                    end
                end

                if hum then
                    if State.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.WalkSpeed then
                        hum.WalkSpeed = State.WalkSpeed
                    end
                    if State.JumpPower ~= 50 then
                        hum.UseJumpPower = true
                        if hum.JumpPower ~= State.JumpPower then
                            hum.JumpPower = State.JumpPower
                        end
                    end
                end

                if workspace.CurrentCamera and State.CameraFOV ~= 70 and workspace.CurrentCamera.FieldOfView ~= State.CameraFOV then
                    workspace.CurrentCamera.FieldOfView = State.CameraFOV
                end

                if State.FullbrightEnabled then
                    Lighting.Brightness = 2
                    Lighting.GlobalShadows = false
                    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                end

                if State.NoFogEnabled then
                    Lighting.FogEnd = 100000
                    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
                    if atmo and atmo.Density ~= 0 then
                        atmo.Density = 0
                    end
                end

                ESP.UpdateAll()

                if Combat.HungerThirstGuard then
                    Protection.StepHungerThirstGuard()
                end

                if (tNow - lastWorldScan) >= 0.5 then
                    lastWorldScan = tNow
                    ItemESP.ScanAndRender()
                    GeneratorESP.ScanAndRender()
                end
            end)
        end
    end))
end

-- Inisialisasi Tab Awal & Notifikasi Selamat Datang
Components.SwitchTab("Dashboard")
Utils.Notify(App.Name, "Semoga hari-hari kalian menyenangkan! 🎃", Theme.Accent)
