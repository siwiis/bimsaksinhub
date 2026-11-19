--[[
================================================================================
  BimSakSin Hub v3.0 | Edisi Universal (Bahasa Indonesia & Adaptif Region Device)
  Creator     : BimSakSin
  Environment : Roblox Luau (Universal / Semua Map & Kompatibel R6/R15)
  Pembaruan   :
    - Seluruh nama tab, kategori, dan fitur diterjemahkan ke Bahasa Indonesia
      yang rapi & profesional.
    - Deteksi otomatis Region & Bahasa Perangkat pengguna (LocalizationService:
      SystemLocaleId, RobloxLocaleId, dan CountryRegion) dengan dukungan
      pengalihan bahasa langsung (Otomatis Region / Indonesia / English).
    - Integrasi Modul Lanjutan: Panel Keamanan & Anti-Cheat, Command Palette (F2),
      Diagnostik Log Live, Pemindai Zona, dan Simpan/Muat Konfigurasi JSON.
    - Struktur tab dan fitur disusun ulang berdasarkan urutan kegunaan:
      1. Informasi (Paling Atas)
      2. Beranda (Telemetri & Utilitas Server)
      3. Radar ESP (Pemain, Barang/Loot & Generator)
      4. Pertarungan (Bidik Otomatis, Tangkis & Ketahanan)
      5. Pergerakan (Kecepatan, Lompatan, Terbang & Tembus Objek)
      6. Teleportasi (Koordinat, Titik Simpan & Teleport Pemain)
      7. Gendong (Interaksi Carry & Pilihan Gaya)
      8. Tari & Emote (Animasi Replikasi R6/R15 & ID Kustom)
      9. Visual (Kamera FOV, Pencahayaan Penuh & Hapus Kabut)
     10. Salin Aset (Ekspor Struktur Item/Map & Notifikasi Telegram)
     11. Keamanan & AC (Monitor Anti-Cheat, Diagnostik & Audit Integritas)
     12. Pengaturan (Region Device, Config JSON, Anti-Bug, Tema & Kontrol Panel)
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
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local VirtualUser = nil
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer
local LocalizationService = game:GetService("LocalizationService")

local App = {
    Name = "BimSakSin Hub v3.0",
    Subtitle = "Semoga hari-hari kalian menyenangkan",
    Version = "v3.0 Universal",
    GuiName = "BimSakSinHub_v3",
    IsOpen = true,
    IsMinimized = false,
    ExpandedWidth = 650,
    ExpandedHeight = 435,
    ActiveTab = "Informasi",
    StartTime = os.clock(),
    DiscordUrl = "https://discord.gg/YwMCBq22f2",
    DonationUrl = "https://linktr.ee/bimsaksin",
}

-- ============================================================================
-- 1A. SISTEM LOKALISASI & DETEKSI REGION PERANGKAT PENGGUNA (LocaleEngine)
-- ============================================================================
local LocaleEngine = {
    Mode = "Auto", -- "Auto" | "id" | "en"
    CurrentLang = "id",
    SystemLocale = "id-ID",
    RobloxLocale = "id-ID",
    CountryCode = "ID",
    RegionDisplay = "Indonesia (ID / id-ID)",
    Updaters = {},
}

do
    local countryNamesID = {
        ID = "Indonesia", MY = "Malaysia", SG = "Singapura", BN = "Brunei Darussalam",
        US = "Amerika Serikat", GB = "Inggris", JP = "Jepang", KR = "Korea Selatan",
        PH = "Filipina", TH = "Thailand", VN = "Vietnam", AU = "Australia",
        DE = "Jerman", FR = "Prancis", BR = "Brasil", RU = "Rusia",
    }

    local countryNamesEN = {
        ID = "Indonesia", MY = "Malaysia", SG = "Singapore", BN = "Brunei",
        US = "United States", GB = "United Kingdom", JP = "Japan", KR = "South Korea",
        PH = "Philippines", TH = "Thailand", VN = "Vietnam", AU = "Australia",
        DE = "Germany", FR = "France", BR = "Brazil", RU = "Russia",
    }

    local function readInitialLocales()
        local sysLoc = ""
        local rbxLoc = ""
        pcall(function()
            sysLoc = tostring(LocalizationService.SystemLocaleId or "")
        end)
        pcall(function()
            rbxLoc = tostring(LocalizationService.RobloxLocaleId or "")
        end)
        LocaleEngine.SystemLocale = (sysLoc ~= "") and sysLoc or "id-ID"
        LocaleEngine.RobloxLocale = (rbxLoc ~= "") and rbxLoc or LocaleEngine.SystemLocale

        local lowSys = string.lower(LocaleEngine.SystemLocale)
        local lowRbx = string.lower(LocaleEngine.RobloxLocale)

        local extractedRegion = string.match(LocaleEngine.SystemLocale, "%-(%a%a)$")
            or string.match(LocaleEngine.RobloxLocale, "%-(%a%a)$")
        if extractedRegion then
            LocaleEngine.CountryCode = string.upper(extractedRegion)
        elseif string.sub(lowSys, 1, 2) == "id" or string.sub(lowRbx, 1, 2) == "id" then
            LocaleEngine.CountryCode = "ID"
        else
            LocaleEngine.CountryCode = "ID"
        end
    end

    function LocaleEngine.ComputeEffectiveLang()
        if LocaleEngine.Mode == "id" or LocaleEngine.Mode == "en" then
            return LocaleEngine.Mode
        end
        local lowSys = string.lower(LocaleEngine.SystemLocale or "")
        local lowRbx = string.lower(LocaleEngine.RobloxLocale or "")
        local cc = string.upper(LocaleEngine.CountryCode or "")

        if cc == "ID" or string.sub(lowSys, 1, 2) == "id" or string.sub(lowRbx, 1, 2) == "id" then
            return "id"
        end
        if cc ~= "" and cc ~= "ID" and string.sub(lowSys, 1, 2) ~= "id" then
            return "en"
        end
        return "id"
    end

    function LocaleEngine.UpdateRegionSummary()
        local cc = string.upper(LocaleEngine.CountryCode or "ID")
        local locTag = LocaleEngine.SystemLocale ~= "" and LocaleEngine.SystemLocale or LocaleEngine.RobloxLocale
        if LocaleEngine.CurrentLang == "id" then
            local cName = countryNamesID[cc] or ("Region " .. cc)
            LocaleEngine.RegionDisplay = string.format("%s (%s • %s)", cName, cc, locTag)
        else
            local cName = countryNamesEN[cc] or ("Region " .. cc)
            LocaleEngine.RegionDisplay = string.format("%s (%s • %s)", cName, cc, locTag)
        end
    end

    function LocaleEngine.Text(idText, enText)
        if LocaleEngine.CurrentLang == "en" and enText and enText ~= "" then
            return enText
        end
        return idText
    end

    function LocaleEngine.Bind(fn)
        if type(fn) == "function" then
            table.insert(LocaleEngine.Updaters, fn)
            pcall(fn, LocaleEngine.CurrentLang)
        end
    end

    function LocaleEngine.RefreshAll()
        LocaleEngine.CurrentLang = LocaleEngine.ComputeEffectiveLang()
        LocaleEngine.UpdateRegionSummary()
        App.Subtitle = LocaleEngine.Text(
            "Semoga hari-hari kalian menyenangkan",
            "Wishing you a wonderful day ahead"
        )
        for i = #LocaleEngine.Updaters, 1, -1 do
            local fn = LocaleEngine.Updaters[i]
            local ok = pcall(fn, LocaleEngine.CurrentLang)
            if not ok then
                table.remove(LocaleEngine.Updaters, i)
            end
        end
    end

    function LocaleEngine.SetMode(newMode)
        LocaleEngine.Mode = newMode or "Auto"
        LocaleEngine.RefreshAll()
    end

    readInitialLocales()
    LocaleEngine.CurrentLang = LocaleEngine.ComputeEffectiveLang()
    LocaleEngine.UpdateRegionSummary()

    task.spawn(function()
        local ok, regionCode = pcall(function()
            if LocalPlayer then
                return LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
            end
            return nil
        end)
        if ok and type(regionCode) == "string" and #regionCode >= 2 then
            LocaleEngine.CountryCode = string.upper(string.sub(regionCode, 1, 2))
            LocaleEngine.RefreshAll()
        end
    end)
end

local Theme = {
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
    FontColorMode = "Auto",
    FontBgEnabled = false,
    FontBgColor = Color3.fromRGB(18, 14, 26),
    FontBgTransparency = 0.65,

    Accent = Color3.fromRGB(255, 118, 26),
    AccentDark = Color3.fromRGB(184, 72, 12),
    Crimson = Color3.fromRGB(214, 48, 74),
    Spectral = Color3.fromRGB(155, 89, 245),
    Success = Color3.fromRGB(46, 213, 115),
    Warning = Color3.fromRGB(255, 177, 43),
    Danger = Color3.fromRGB(235, 69, 95),
}

local initialAtmo = Lighting:FindFirstChildOfClass("Atmosphere")

local State = {
    WalkSpeed = 16,
    JumpPower = 50,
    OriginalGravity = workspace.Gravity,
    Gravity = workspace.Gravity,
    FlyEnabled = false,
    FlySpeed = 65,
    NoclipEnabled = false,
    InfiniteJumpEnabled = false,

    CameraFOV = 70,
    FullbrightEnabled = false,
    NoFogEnabled = false,
    SpectatingPlayer = nil,
    Waypoints = {},

    TeleportToken = 0,
    IsTeleportLocking = false,
    PreTeleportAnchored = false,

    AccentObjects = {},
    AccentCallbacks = {},
    ActiveToggleTracks = {},
    ThemedTexts = {},

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
    Mode = "Auto",
    MaxDistance = 2500,

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
    ActiveColor = Color3.fromRGB(46, 213, 115),
    IdleColor = Color3.fromRGB(255, 196, 54),
    DoneColor = Color3.fromRGB(96, 175, 255),
    ShowProgressBar = true,
    ShowWorkerInfo = true,
    Folder = nil,
    Entries = {},
    Candidates = {},
}

local Combat = {
    AimbotEnabled = false,
    AimbotMode = "Auto",
    AimPart = "Head",
    TeamCheck = true,
    FOVRadius = 220,
    ShowFOVCircle = false,
    Smoothness = 0.35,
    MaxRange = 800,
    RGBLaserEnabled = true,
    CurrentTarget = nil,
    LaserPart = nil,
    FOVCircle = nil,

    MeleeImmunity = false,
    HungerThirstGuard = false,
    TouchedPartsCache = {},
    EnemyToolParts = {},

    AutoParryEnabled = false,
    AutoParryVisual = true,
    ParryRange = 18,
    ParryReactionDelay = 0.02,
    ParryKey = "Auto",
    LastParryTime = 0,
    ParryCooldown = 0.35,
    ParryCount = 0,
    ParryRingPart = nil,
    ParryShieldHL = nil,
    ParryRemoteCache = {},
    ParryRemoteScanned = false,
}

local Carry = {
    Enabled = false,
    TargetPlayer = nil,
    Style = "Depan",
    AnimTrack = nil,
    NativePromptTriggered = false,
    ShowVisualBeam = true,
    VisualBeam = nil,
    VisualAtt0 = nil,
    VisualAtt1 = nil,
    TargetHL = nil,
    CarryRemoteCache = {},
    CarryRemoteScanned = false,
}

local Emotes = {
    Playing = false,
    CurrentDance = nil,
    CurrentId = nil,
    Speed = 1.0,
    ActiveTrack = nil,
}

-- ============================================================================
-- 1B. ITEM & MAP COPY STUDIO + AUTO FILE GENERATOR + TELEGRAM NOTIFIER
-- ============================================================================
local AssetCopy = {
    FolderPath = "BimSakSinHub_v3/CopiedAssets",
    TargetFilter = "",
    CopyScope = "EquippedOrNearest",
    FormatMode = "LuauAndJSON",
    MaxDescendants = 4500,
    AutoNotifyTelegram = true,
    TelegramBotToken = "",
    TelegramChatId = "",
    LastExportedFiles = {},
    History = {},
}

local Protection = {
    AntiAFKEnabled = true,
    AntiBugEnabled = true,
    ErrorsCaught = 0,
    AutoRepairs = 0,
    IdleEventsHandled = 0,
    HungerThirstValues = {},
}

-- ============================================================================
-- 1C. MODUL BARU: KEAMANAN & ANTI-CHEAT, DIAGNOSTIK LOG, ZONA & CONFIG JSON
-- ============================================================================
local SecurityHub = {
    ServerConnected = false,
    TelemetryRemote = nil,
    AdminActionRemote = nil,
    ZoneScannerEnabled = true,
    CurrentZoneName = "Area Umum (Normal)",
    LogCaptureEnabled = true,
    ViolationLogs = {},
    ConsoleLogs = {},
    MaxLogs = 35,
    OnViolationAdded = nil,
    OnConsoleLogAdded = nil,
    OnZoneChanged = nil,
}

local ConfigManager = {
    FileName = "BimSakSinHub_v3_Config.json",
    AutoSave = false,
}

local CommandRegistry = {}

local Connections = {}
local UI = {
    Tabs = {},
    Pages = {},
    TelemetryLabels = {},
    FullbrightToggle = nil,
    NoFogToggle = nil,
    StatusLabel = nil,
    Pumpkins = {},
    CommandPalette = nil,
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
-- 2A. UNIVERSAL FEATURE API, LIFECYCLE HOOKS & ANTI-CRASH BRIDGE (FeatureAPI)
-- ============================================================================
local FeatureAPI = {
    Registry = {},
    Listeners = {},
    RemoteIndex = {
        Parry = {},
        Carry = {},
        Combat = {},
        Interact = {},
        LastScan = 0,
    },
    Capabilities = {
        Clipboard = (typeof(setclipboard) == "function" or typeof(toclipboard) == "function"),
        FileSystem = (typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"),
        ProximityPrompt = (typeof(fireproximityprompt) == "function"),
        HttpRequest = (typeof(request) == "function" or typeof(http_request) == "function" or (syn and typeof(syn.request) == "function")),
        GetHui = (typeof(gethui) == "function"),
        VirtualInput = (VirtualInputManager ~= nil),
        VirtualUser = (VirtualUser ~= nil),
    },
}

function FeatureAPI.On(eventName, callback)
    if type(eventName) ~= "string" or type(callback) ~= "function" then return nil end
    FeatureAPI.Listeners[eventName] = FeatureAPI.Listeners[eventName] or {}
    table.insert(FeatureAPI.Listeners[eventName], callback)
    return function()
        local list = FeatureAPI.Listeners[eventName]
        if not list then return end
        for i = #list, 1, -1 do
            if list[i] == callback then
                table.remove(list, i)
            end
        end
    end
end

function FeatureAPI.Emit(eventName, ...)
    local list = FeatureAPI.Listeners[eventName]
    if not list then return end
    for i = 1, #list do
        local fn = list[i]
        if type(fn) == "function" then
            SafeEngine.Run("Event:" .. tostring(eventName), fn, ...)
        end
    end
end

function FeatureAPI.Register(featureId, spec)
    assert(type(featureId) == "string", "featureId harus string")
    spec = spec or {}
    FeatureAPI.Registry[featureId] = {
        Id = featureId,
        Category = spec.Category or "General",
        Enabled = false,
        Cooldown = spec.Cooldown or 0,
        LastToggle = 0,
        Validate = spec.Validate,
        OnEnable = spec.OnEnable,
        OnDisable = spec.OnDisable,
        OnRespawn = spec.OnRespawn,
        SyncState = spec.SyncState,
    }
    return FeatureAPI.Registry[featureId]
end

function FeatureAPI.SetEnabled(featureId, state, silent)
    local entry = FeatureAPI.Registry[featureId]
    if not entry then return false, "Feature tidak terdaftar: " .. tostring(featureId) end

    local targetState = (state == true)
    if entry.Enabled == targetState then
        return true
    end

    local now = os.clock()
    if entry.Cooldown > 0 and (now - entry.LastToggle) < entry.Cooldown then
        return false, "Cooldown aktif"
    end

    if targetState and type(entry.Validate) == "function" then
        local validOk, validRes, reason = SafeEngine.Run("Validate:" .. featureId, entry.Validate)
        if not validOk or validRes == false then
            if not silent then
                Utils.Notify(
                    LocaleEngine.Text("Prasyarat Fitur", "Feature Requirement"),
                    tostring(reason or "Karakter atau kondisi map belum siap."),
                    Theme.Warning
                )
            end
            return false, reason
        end
    end

    entry.LastToggle = now
    if targetState then
        local ok, err = true, nil
        if type(entry.OnEnable) == "function" then
            ok, err = SafeEngine.Run("Enable:" .. featureId, entry.OnEnable)
        end
        if not ok then
            entry.Enabled = false
            pcall(function()
                if type(entry.OnDisable) == "function" then entry.OnDisable() end
            end)
            if not silent then
                Utils.Notify("Auto-Recovery: " .. featureId, LocaleEngine.Text("Fitur dipulihkan dari error.", "Feature recovered from error."), Theme.Danger)
            end
            return false, err
        end
        entry.Enabled = true
    else
        entry.Enabled = false
        if type(entry.OnDisable) == "function" then
            SafeEngine.Run("Disable:" .. featureId, entry.OnDisable)
        end
    end

    FeatureAPI.Emit("FeatureStateChanged", featureId, entry.Enabled)
    FeatureAPI.Emit("Feature:" .. featureId, entry.Enabled)
    return true
end

function FeatureAPI.Sync(featureId, isOn)
    local entry = FeatureAPI.Registry[featureId]
    if not entry then return end
    local target = (isOn == true)
    if entry.Enabled ~= target then
        entry.Enabled = target
        FeatureAPI.Emit("FeatureStateChanged", featureId, target)
        FeatureAPI.Emit("Feature:" .. featureId, target)
    end
end

function FeatureAPI.Toggle(featureId, silent)
    local entry = FeatureAPI.Registry[featureId]
    if not entry then return false end
    return FeatureAPI.SetEnabled(featureId, not entry.Enabled, silent)
end

function FeatureAPI.IsEnabled(featureId)
    local entry = FeatureAPI.Registry[featureId]
    return entry and entry.Enabled == true or false
end

function FeatureAPI.GetActiveCount()
    local total = 0
    for _, entry in pairs(FeatureAPI.Registry) do
        if entry.Enabled then
            total = total + 1
        end
    end
    return total
end

function FeatureAPI.ScanGameRemotes(force)
    local now = os.clock()
    if not force and (now - FeatureAPI.RemoteIndex.LastScan) < 12 then
        return FeatureAPI.RemoteIndex
    end
    FeatureAPI.RemoteIndex.LastScan = now
    table.clear(FeatureAPI.RemoteIndex.Parry)
    table.clear(FeatureAPI.RemoteIndex.Carry)
    table.clear(FeatureAPI.RemoteIndex.Combat)
    table.clear(FeatureAPI.RemoteIndex.Interact)

    local containers = {
        ReplicatedStorage,
        LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"),
        LocalPlayer and LocalPlayer.Character,
    }

    for _, root in ipairs(containers) do
        if root then
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
                    local lower = string.lower(inst.Name)
                    if string.find(lower, "parry") or string.find(lower, "block") or string.find(lower, "deflect") or string.find(lower, "guard") or string.find(lower, "counter") or string.find(lower, "tangkis") then
                        table.insert(FeatureAPI.RemoteIndex.Parry, inst)
                    elseif string.find(lower, "carry") or string.find(lower, "gendong") or string.find(lower, "angkat") or string.find(lower, "grab") or string.find(lower, "pick") or string.find(lower, "drop") then
                        table.insert(FeatureAPI.RemoteIndex.Carry, inst)
                    elseif string.find(lower, "attack") or string.find(lower, "swing") or string.find(lower, "hit") or string.find(lower, "damage") or string.find(lower, "shoot") then
                        table.insert(FeatureAPI.RemoteIndex.Combat, inst)
                    elseif string.find(lower, "interact") or string.find(lower, "prompt") or string.find(lower, "use") or string.find(lower, "collect") then
                        table.insert(FeatureAPI.RemoteIndex.Interact, inst)
                    end
                end
            end
        end
    end
    return FeatureAPI.RemoteIndex
end

function FeatureAPI.SafeFireRemote(remote, ...)
    if not remote or not remote.Parent then return false end
    local args = { ... }
    if remote:IsA("RemoteEvent") then
        local ok = pcall(function()
            remote:FireServer(table.unpack(args))
        end)
        return ok
    elseif remote:IsA("RemoteFunction") then
        local ok, res = pcall(function()
            return remote:InvokeServer(table.unpack(args))
        end)
        return ok, res
    end
    return false
end

function FeatureAPI.TriggerProximity(prompt)
    if not prompt or not prompt.Parent or not prompt:IsA("ProximityPrompt") then
        return false
    end
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end
    local okHold = pcall(function()
        prompt:InputHoldBegin()
        task.delay(math.max(0.05, prompt.HoldDuration or 0.05), function()
            if prompt and prompt.Parent then
                pcall(function() prompt:InputHoldEnd() end)
            end
        end)
    end)
    return okHold
end

-- Auto-Rebind & Pemulihan Fisika Saat Karakter Respawn
Utils.Track(LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.25)
    SafeEngine.Run("CharacterAddedAPI", function()
        local hum = newChar:FindFirstChildOfClass("Humanoid")
        if hum then
            if State.WalkSpeed ~= 16 then hum.WalkSpeed = State.WalkSpeed end
            if State.JumpPower ~= 50 then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
        if State.FlyEnabled and type(Physics.CleanupFly) == "function" then
            Physics.CleanupFly()
        end
        if Carry.Enabled then
            Carry.Stop()
        end
        if Emotes.Playing then
            Emotes.Stop()
        end
        Combat.ParryRemoteScanned = false
        Carry.CarryRemoteScanned = false
        FeatureAPI.ScanGameRemotes(true)
        for _, entry in pairs(FeatureAPI.Registry) do
            if entry.Enabled and type(entry.OnRespawn) == "function" then
                SafeEngine.Run("Respawn:" .. entry.Id, entry.OnRespawn, newChar)
            end
        end
        FeatureAPI.Emit("CharacterRespawned", newChar)
    end)
end))

if typeof(getgenv) == "function" then
    getgenv().BSS_FeatureAPI = FeatureAPI
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

function Utils.SafeTeleport(targetCFrame)
    local char, hum, root = Utils.GetCharacter(LocalPlayer)
    if not char or not root then
        return false
    end

    State.TeleportToken = State.TeleportToken + 1
    local myToken = State.TeleportToken

    if hum then
        hum.Sit = false
        if hum.SeatPart then
            local weld = hum.SeatPart:FindFirstChild("SeatWeld")
            if weld then weld:Destroy() end
        end
    end

    task.spawn(function()
        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(targetCFrame.Position, 3)
        end)
    end)

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
        for _ = 1, 8 do
            RunService.Heartbeat:Wait()
            if State.TeleportToken ~= myToken then
                return
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

    return true
end

-- ============================================================================
-- 3A. CONFIG PERSISTENCE MANAGER (JSON Simpan & Muat Aman)
-- ============================================================================
do
    function ConfigManager.BuildPayload()
        return {
            SchemaVersion = 1,
            LocaleMode = LocaleEngine.Mode,
            WalkSpeed = State.WalkSpeed,
            JumpPower = State.JumpPower,
            FlySpeed = State.FlySpeed,
            CameraFOV = State.CameraFOV,
            ESPMaxDistance = ESP.MaxDistance,
            AimbotFOV = Combat.FOVRadius,
            AimbotSmoothness = Combat.Smoothness,
            ParryRange = Combat.ParryRange,
            AntiAFK = Protection.AntiAFKEnabled,
            AntiBug = Protection.AntiBugEnabled,
            ZoneScanner = SecurityHub.ZoneScannerEnabled,
            LogCapture = SecurityHub.LogCaptureEnabled,
        }
    end

    function ConfigManager.Save()
        if typeof(writefile) ~= "function" then
            Utils.Notify("Config JSON", LocaleEngine.Text("Executor tidak mendukung writefile.", "Executor does not support writefile."), Theme.Warning)
            return false
        end
        local ok, err = pcall(function()
            local encoded = HttpService:JSONEncode(ConfigManager.BuildPayload())
            writefile(ConfigManager.FileName, encoded)
        end)
        if ok then
            Utils.Notify("Config Tersimpan ✓", ConfigManager.FileName, Theme.Success)
        else
            Utils.Notify("Gagal Simpan Config", tostring(err), Theme.Danger)
        end
        return ok
    end

    function ConfigManager.Load(silent)
        if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
            if not silent then
                Utils.Notify("Config JSON", LocaleEngine.Text("Executor tidak mendukung readfile.", "Executor does not support readfile."), Theme.Warning)
            end
            return false
        end
        if not isfile(ConfigManager.FileName) then
            if not silent then
                Utils.Notify("Config JSON", LocaleEngine.Text("File konfigurasi belum ditemukan.", "Config file not found yet."), Theme.Warning)
            end
            return false
        end
        local ok, err = pcall(function()
            local raw = readfile(ConfigManager.FileName)
            local data = HttpService:JSONDecode(raw)
            if type(data) ~= "table" then return end

            if type(data.LocaleMode) == "string" then
                LocaleEngine.SetMode(data.LocaleMode)
            end
            if type(data.WalkSpeed) == "number" then
                State.WalkSpeed = math.clamp(data.WalkSpeed, 16, 250)
            end
            if type(data.JumpPower) == "number" then
                State.JumpPower = math.clamp(data.JumpPower, 50, 300)
            end
            if type(data.FlySpeed) == "number" then
                State.FlySpeed = math.clamp(data.FlySpeed, 20, 250)
            end
            if type(data.CameraFOV) == "number" then
                State.CameraFOV = math.clamp(data.CameraFOV, 40, 120)
            end
            if type(data.ESPMaxDistance) == "number" then
                ESP.MaxDistance = math.clamp(data.ESPMaxDistance, 200, 10000)
            end
            if type(data.AimbotFOV) == "number" then
                Combat.FOVRadius = math.clamp(data.AimbotFOV, 60, 600)
            end
            if type(data.AimbotSmoothness) == "number" then
                Combat.Smoothness = math.clamp(data.AimbotSmoothness, 0.1, 1.0)
            end
            if type(data.ParryRange) == "number" then
                Combat.ParryRange = math.clamp(data.ParryRange, 6, 35)
            end
            if type(data.AntiAFK) == "boolean" then
                Protection.AntiAFKEnabled = data.AntiAFK
            end
            if type(data.AntiBug) == "boolean" then
                Protection.AntiBugEnabled = data.AntiBug
            end
            if type(data.ZoneScanner) == "boolean" then
                SecurityHub.ZoneScannerEnabled = data.ZoneScanner
            end
            if type(data.LogCapture) == "boolean" then
                SecurityHub.LogCaptureEnabled = data.LogCapture
            end
        end)

        if ok and not silent then
            Utils.Notify("Config Dimuat ✓", LocaleEngine.Text("Pengaturan berhasil dipulihkan dari JSON.", "Settings restored from JSON."), Theme.Success)
        elseif not ok and not silent then
            Utils.Notify("Config Rusak", tostring(err), Theme.Danger)
        end
        return ok
    end
end

-- ============================================================================
-- 3B. ASSET COPY ENGINE: SERIALIZER, AUTO FILE WRITER & TELEGRAM NOTIFIER
-- ============================================================================
do
    local function sanitizeFileName(rawName)
        local cleaned = tostring(rawName or "Asset"):gsub("[^%w%-%_]", "_")
        cleaned = cleaned:gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
        if cleaned == "" then
            cleaned = "CopiedAsset"
        end
        return string.sub(cleaned, 1, 48)
    end

    local function formatColor3(c)
        return string.format(
            "Color3.fromRGB(%d, %d, %d)",
            math.clamp(math.floor(c.R * 255 + 0.5), 0, 255),
            math.clamp(math.floor(c.G * 255 + 0.5), 0, 255),
            math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
        )
    end

    local function formatVector3(v)
        return string.format("Vector3.new(%.3f, %.3f, %.3f)", v.X, v.Y, v.Z)
    end

    local function formatCFrame(cf)
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
        return string.format(
            "CFrame.new(%.3f, %.3f, %.3f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)",
            x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22
        )
    end

    local function escapeLuaString(str)
        return tostring(str or ""):gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "")
    end

    local function ensureDirectoryRecursive(relDir)
        if typeof(makefolder) ~= "function" then
            return false
        end
        local acc = ""
        for seg in string.gmatch(tostring(relDir), "[^/\\]+") do
            acc = (acc == "") and seg or (acc .. "/" .. seg)
            pcall(makefolder, acc)
        end
        return true
    end

    function AssetCopy.WriteFileSafe(relPath, content)
        local dirPart = string.match(relPath, "^(.+)/[^/]+$")
        if dirPart then
            ensureDirectoryRecursive(dirPart)
        end

        if typeof(writefile) == "function" then
            local ok, err = pcall(writefile, relPath, tostring(content))
            if ok then
                return true, relPath
            end
            return false, tostring(err)
        end

        Utils.CopyText(content)
        return false, "Executor tidak mendukung writefile (data disalin ke clipboard)"
    end

    function AssetCopy.GetGameTitleSafe()
        local title = "Game_" .. tostring(game.PlaceId)
        pcall(function()
            local info = MarketplaceService:GetProductInfoAsync(game.PlaceId)
            if info and info.Name and info.Name ~= "" then
                title = info.Name
            end
        end)
        return title
    end

    function AssetCopy.ResolveTargetInstance()
        local filterTrim = string.match(AssetCopy.TargetFilter or "", "^%s*(.-)%s*$")
        local char, _, root = Utils.GetCharacter(LocalPlayer)

        if filterTrim ~= "" then
            local lowerFilter = string.lower(filterTrim)
            local searchRoots = { char, LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"), workspace }
            for _, rootContainer in ipairs(searchRoots) do
                if rootContainer then
                    for _, desc in ipairs(rootContainer:GetDescendants()) do
                        if (desc:IsA("Model") or desc:IsA("Tool") or desc:IsA("BasePart") or desc:IsA("Folder"))
                            and string.find(string.lower(desc.Name), lowerFilter, 1, true) then
                            return desc, "FilteredMatch"
                        end
                    end
                end
            end
        end

        if AssetCopy.CopyScope == "FullMap" then
            return workspace, "FullMap"
        elseif AssetCopy.CopyScope == "AllTools" then
            local container = Instance.new("Folder")
            container.Name = "AllGameTools_" .. tostring(game.PlaceId)
            local function collectTools(src)
                if not src then return end
                for _, item in ipairs(src:GetDescendants()) do
                    if item:IsA("Tool") then
                        local cloneOk, cloned = pcall(function() return item:Clone() end)
                        if cloneOk and cloned then
                            cloned.Parent = container
                        end
                    end
                end
            end
            collectTools(char)
            collectTools(LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"))
            collectTools(workspace)
            return container, "AllTools"
        else
            if char then
                local equipped = char:FindFirstChildOfClass("Tool")
                if equipped then
                    return equipped, "EquippedTool"
                end
            end

            local bestObj = nil
            local bestDist = math.huge
            local origin = root and root.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or Vector3.zero

            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("Tool") or desc:IsA("Model") or desc:IsA("BasePart") then
                    local isCharPart = false
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr.Character and desc:IsDescendantOf(plr.Character) then
                            isCharPart = true
                            break
                        end
                    end
                    if not isCharPart and desc ~= workspace then
                        local p = desc:IsA("BasePart") and desc
                            or (desc:IsA("Model") and (desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart", true)))
                            or (desc:IsA("Tool") and (desc:FindFirstChild("Handle") or desc:FindFirstChildWhichIsA("BasePart", true)))
                        if p then
                            local d = (p.Position - origin).Magnitude
                            if d < bestDist and d <= 65 then
                                bestDist = d
                                bestObj = desc
                            end
                        end
                    end
                end
            end

            if bestObj then
                return bestObj, "NearestAsset"
            end
            return workspace, "WorkspaceFallback"
        end
    end

    function AssetCopy.SerializeInstanceTree(rootObj, maxNodes)
        local nodes = {}
        local classCounts = {}
        local truncated = false

        local function visit(inst, depth, parentIndex)
            if #nodes >= maxNodes then
                truncated = true
                return
            end

            classCounts[inst.ClassName] = (classCounts[inst.ClassName] or 0) + 1

            local node = {
                Index = #nodes + 1,
                ParentIndex = parentIndex,
                Name = inst.Name,
                ClassName = inst.ClassName,
                Depth = depth,
                Attributes = {},
            }

            pcall(function()
                for k, v in pairs(inst:GetAttributes()) do
                    local tv = typeof(v)
                    if tv == "string" or tv == "number" or tv == "boolean" then
                        node.Attributes[tostring(k)] = v
                    elseif tv == "Color3" then
                        node.Attributes[tostring(k)] = formatColor3(v)
                    elseif tv == "Vector3" then
                        node.Attributes[tostring(k)] = formatVector3(v)
                    end
                end
            end)

            if inst:IsA("BasePart") then
                local pos = inst.Position
                local rotX, rotY, rotZ = inst.CFrame:ToEulerAnglesXYZ()
                node.Size = { math.floor(inst.Size.X * 1000 + 0.5) / 1000, math.floor(inst.Size.Y * 1000 + 0.5) / 1000, math.floor(inst.Size.Z * 1000 + 0.5) / 1000 }
                node.Position = { math.floor(pos.X * 1000 + 0.5) / 1000, math.floor(pos.Y * 1000 + 0.5) / 1000, math.floor(pos.Z * 1000 + 0.5) / 1000 }
                node.RotationDeg = {
                    math.floor(math.deg(rotX) * 100 + 0.5) / 100,
                    math.floor(math.deg(rotY) * 100 + 0.5) / 100,
                    math.floor(math.deg(rotZ) * 100 + 0.5) / 100,
                }
                node.CFrameRaw = formatCFrame(inst.CFrame)
                node.Material = inst.Material.Name
                node.ColorRGB = {
                    math.clamp(math.floor(inst.Color.R * 255 + 0.5), 0, 255),
                    math.clamp(math.floor(inst.Color.G * 255 + 0.5), 0, 255),
                    math.clamp(math.floor(inst.Color.B * 255 + 0.5), 0, 255),
                }
                node.Transparency = math.floor(inst.Transparency * 1000 + 0.5) / 1000
                node.Anchored = inst.Anchored
                node.CanCollide = inst.CanCollide
            elseif inst:IsA("MeshPart") then
                node.MeshId = tostring(inst.MeshId)
                node.TextureID = tostring(inst.TextureID)
            elseif inst:IsA("SpecialMesh") then
                node.MeshType = inst.MeshType.Name
                node.MeshId = tostring(inst.MeshId)
                node.TextureId = tostring(inst.TextureId)
                node.Scale = formatVector3(inst.Scale)
            elseif inst:IsA("ProximityPrompt") then
                node.ActionText = inst.ActionText
                node.ObjectText = inst.ObjectText
                node.HoldDuration = inst.HoldDuration
                node.MaxActivationDistance = inst.MaxActivationDistance
            elseif inst:IsA("ClickDetector") then
                node.MaxActivationDistance = inst.MaxActivationDistance
            elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
                node.Brightness = inst.Brightness
                node.Range = inst.Range
                node.Color = formatColor3(inst.Color)
            end

            local currentIndex = node.Index
            table.insert(nodes, node)

            for _, child in ipairs(inst:GetChildren()) do
                if #nodes >= maxNodes then
                    truncated = true
                    break
                end
                visit(child, depth + 1, currentIndex)
            end
        end

        visit(rootObj, 0, nil)
        return nodes, classCounts, truncated
    end

    function AssetCopy.BuildLuauReconstructionScript(meta, nodes)
        local lines = {
            "-- ============================================================================",
            "-- BimSakSin Hub v3.0 | Auto-Generated Asset / Map Reconstruction Script",
            "-- Source Game : " .. tostring(meta.GameTitle) .. " (PlaceId: " .. tostring(meta.PlaceId) .. ")",
            "-- Root Asset  : " .. tostring(meta.AssetName) .. " (" .. tostring(meta.ClassName) .. ")",
            "-- Total Nodes : " .. tostring(#nodes) .. (meta.Truncated and " (Capped)" or ""),
            "-- Generated   : " .. tostring(meta.TimestampISO),
            "-- ============================================================================",
            "local created = {}",
            "local rootContainer = Instance.new(\"Folder\")",
            "rootContainer.Name = \"Reconstructed_" .. escapeLuaString(sanitizeFileName(meta.AssetName)) .. "\"",
            "rootContainer.Parent = workspace",
            "",
        }

        local maxScriptNodes = math.min(#nodes, 1200)
        for i = 1, maxScriptNodes do
            local n = nodes[i]
            local varName = "obj_" .. tostring(i)
            local parentExpr = n.ParentIndex and ("created[" .. tostring(n.ParentIndex) .. "]") or "rootContainer"
            local safeClass = n.ClassName

            local instOk = pcall(function()
                local probe = Instance.new(safeClass)
                probe:Destroy()
            end)
            if not instOk then
                safeClass = (n.ParentIndex == nil) and "Model" or "Folder"
            end

            table.insert(lines, string.format("local %s = Instance.new(\"%s\")", varName, escapeLuaString(safeClass)))
            table.insert(lines, string.format("%s.Name = \"%s\"", varName, escapeLuaString(n.Name)))

            if n.ClassName == "BasePart" or n.ClassName == "Part" or n.ClassName == "WedgePart" or n.ClassName == "CornerWedgePart" or n.ClassName == "TrussPart" then
                local sz = n.Size or { 4, 1, 4 }
                local rgb = n.ColorRGB or { 255, 118, 26 }
                local cfExpr = n.CFrameRaw or "CFrame.new(0, 5, 0)"
                table.insert(lines, string.format("%s.Size = Vector3.new(%.3f, %.3f, %.3f)", varName, sz[1], sz[2], sz[3]))
                table.insert(lines, string.format("%s.CFrame = %s", varName, cfExpr))
                table.insert(lines, string.format("%s.Color = Color3.fromRGB(%d, %d, %d)", varName, rgb[1], rgb[2], rgb[3]))
                table.insert(lines, string.format("%s.Transparency = %.3f", varName, n.Transparency or 0))
                table.insert(lines, string.format("%s.Anchored = %s", varName, tostring(n.Anchored ~= false)))
                table.insert(lines, string.format("%s.CanCollide = %s", varName, tostring(n.CanCollide ~= false)))
                if n.Material and Enum.Material[n.Material] then
                    table.insert(lines, string.format("%s.Material = Enum.Material.%s", varName, n.Material))
                end
            end

            table.insert(lines, string.format("%s.Parent = %s", varName, parentExpr))
            table.insert(lines, string.format("created[%d] = %s", i, varName))
        end

        if #nodes > maxScriptNodes then
            table.insert(lines, string.format("-- Catatan: %d node tambahan tersedia di file JSON terkait.", #nodes - maxScriptNodes))
        end

        table.insert(lines, "return rootContainer")
        return table.concat(lines, "\n")
    end

    function AssetCopy.SendTelegramNotification(summaryMeta, fileList)
        local token = string.match(AssetCopy.TelegramBotToken or "", "^%s*(.-)%s*$")
        local chatId = string.match(AssetCopy.TelegramChatId or "", "^%s*(.-)%s*$")

        if token == "" or chatId == "" then
            return false, "Bot Token atau Chat ID Telegram belum diisi"
        end

        local filesText = (#fileList > 0) and table.concat(fileList, "\n• ") or "Tidak ada file tersimpan"
        local textMsg = table.concat({
            "🎃 *BimSakSin Hub v3.0 — Copy Asset / Map Alert*",
            "━━━━━━━━━━━━━━━━━━━━",
            "• *Status:* Copy & File Export Selesai",
            "• *Game:* " .. tostring(summaryMeta.GameTitle) .. " (`" .. tostring(summaryMeta.PlaceId) .. "`)",
            "• *Target:* `" .. tostring(summaryMeta.AssetName) .. "` (" .. tostring(summaryMeta.ClassName) .. ")",
            "• *Scope:* `" .. tostring(summaryMeta.Scope) .. "`",
            "• *Total Node:* `" .. tostring(summaryMeta.TotalNodes) .. "`",
            "• *Pemain:* `" .. tostring(LocalPlayer.DisplayName) .. "` (@" .. tostring(LocalPlayer.Name) .. ")",
            "• *Waktu:* `" .. tostring(summaryMeta.TimestampISO) .. "`",
            "• *File Dibuat:*",
            "• `" .. filesText .. "`",
        }, "\n")

        local url = string.format("https://api.telegram.org/bot%s/sendMessage", token)
        local payload = HttpService:JSONEncode({
            chat_id = chatId,
            text = textMsg,
            parse_mode = "Markdown",
            disable_web_page_preview = true,
        })

        local reqFn = nil
        if typeof(request) == "function" then
            reqFn = request
        elseif typeof(http_request) == "function" then
            reqFn = http_request
        elseif syn and type(syn.request) == "function" then
            reqFn = syn.request
        elseif http and type(http.request) == "function" then
            reqFn = http.request
        end

        if reqFn then
            local ok, res = pcall(reqFn, {
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload,
            })
            if ok and res then
                local code = tonumber(res.StatusCode or res.Status or 200) or 200
                if code >= 200 and code < 300 then
                    return true, "Terkirim ke Telegram"
                end
                return false, "Telegram HTTP " .. tostring(code)
            end
            return false, tostring(res)
        end

        local okPost, errPost = pcall(function()
            HttpService:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson, false)
        end)
        if okPost then
            return true, "Terkirim ke Telegram (HttpService)"
        end
        return false, "HTTP client tidak tersedia di executor: " .. tostring(errPost)
    end

    function AssetCopy.ExecuteCopyAndExport()
        local targetObj, scopeUsed = AssetCopy.ResolveTargetInstance()
        if not targetObj then
            Utils.Notify("Copy Gagal", "Objek/item/map target tidak ditemukan.", Theme.Danger)
            return false
        end

        local nodes, classCounts, truncated = AssetCopy.SerializeInstanceTree(targetObj, AssetCopy.MaxDescendants)
        local stampDate = os.date("%Y%m%d_%H%M%S")
        local stampIso = os.date("%Y-%m-%d %H:%M:%S")
        local gameTitle = AssetCopy.GetGameTitleSafe()
        local baseName = sanitizeFileName(targetObj.Name) .. "_" .. tostring(stampDate)

        local meta = {
            GameTitle = gameTitle,
            PlaceId = game.PlaceId,
            JobId = tostring(game.JobId),
            AssetName = targetObj.Name,
            ClassName = targetObj.ClassName,
            Scope = scopeUsed,
            TotalNodes = #nodes,
            ClassSummary = classCounts,
            Truncated = truncated,
            TimestampISO = stampIso,
        }

        local createdFiles = {}
        local writeErrors = {}

        if AssetCopy.FormatMode == "LuauAndJSON" or AssetCopy.FormatMode == "JSONOnly" then
            local jsonPath = string.format("%s/%s.json", AssetCopy.FolderPath, baseName)
            local jsonContent = HttpService:JSONEncode({
                Metadata = meta,
                Nodes = nodes,
            })
            local okJson, resJson = AssetCopy.WriteFileSafe(jsonPath, jsonContent)
            if okJson then
                table.insert(createdFiles, resJson)
            else
                table.insert(writeErrors, resJson)
            end
        end

        if AssetCopy.FormatMode == "LuauAndJSON" or AssetCopy.FormatMode == "LuauOnly" then
            local luaPath = string.format("%s/%s.lua", AssetCopy.FolderPath, baseName)
            local luaContent = AssetCopy.BuildLuauReconstructionScript(meta, nodes)
            local okLua, resLua = AssetCopy.WriteFileSafe(luaPath, luaContent)
            if okLua then
                table.insert(createdFiles, resLua)
            else
                table.insert(writeErrors, resLua)
            end
        end

        if scopeUsed == "AllTools" and targetObj and targetObj.Name:match("^AllGameTools_") then
            pcall(function() targetObj:Destroy() end)
        end

        AssetCopy.LastExportedFiles = createdFiles

        local tgStatus = "Nonaktif"
        if AssetCopy.AutoNotifyTelegram then
            local tgOk, tgMsg = AssetCopy.SendTelegramNotification(meta, createdFiles)
            tgStatus = tgOk and "Terkirim ✓" or ("Gagal (" .. tostring(tgMsg) .. ")")
        end

        table.insert(AssetCopy.History, 1, {
            AssetName = targetObj.Name,
            Nodes = #nodes,
            Files = createdFiles,
            Telegram = tgStatus,
            Time = stampIso,
        })
        if #AssetCopy.History > 20 then
            table.remove(AssetCopy.History)
        end

        if #createdFiles > 0 then
            Utils.Notify(
                "Copy & File Dibuat ✓",
                string.format("%s (%d node) -> %d file | Telegram: %s", targetObj.Name, #nodes, #createdFiles, tgStatus),
                Theme.Success
            )
        else
            local errSummary = (#writeErrors > 0) and writeErrors[1] or "Gagal menulis file"
            Utils.Notify("Copy Selesai (Fallback)", errSummary .. " | Telegram: " .. tgStatus, Theme.Warning)
        end

        return true
    end
end

-- ============================================================================
-- 4. 3D LUXURY ROYAL SKULL LOGO BUILDER (Pure Procedural 3D UI)
-- ============================================================================
function Utils.CreateSkull3D(parent, pixelSize, position, anchorPoint, zIndex, isHero, isMenuPumpkin)
    local z = zIndex or 20
    local holder = Utils.Create("Frame", {
        Name = "LuxurySkull3D",
        Size = UDim2.new(0, pixelSize, 0, pixelSize),
        Position = position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = anchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        ZIndex = z,
    }, parent)

    local aura = Utils.Create("Frame", {
        Size = UDim2.new(1.22, 0, 1.22, 0),
        Position = UDim2.new(0.5, 0, 0.50, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 138, 36),
        BackgroundTransparency = isHero and 0.65 or 0.78,
        BorderSizePixel = 0,
        ZIndex = z,
    }, holder)
    Utils.AddCorner(aura, math.floor(pixelSize * 0.65))

    local function makeCrownSpire(wScale, hScale, xScale, yScale, rot, spireZ)
        local spire = Utils.Create("Frame", {
            Size = UDim2.new(wScale, 0, hScale, 0),
            Position = UDim2.new(xScale, 0, yScale, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = rot,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = spireZ,
        }, holder)
        Utils.AddCorner(spire, 3)
        Utils.Create("UIGradient", {
            Rotation = 120,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 238, 156)),
                ColorSequenceKeypoint.new(0.55, Color3.fromRGB(238, 174, 48)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(154, 96, 16)),
            }),
        }, spire)
        return spire
    end

    makeCrownSpire(0.13, 0.16, 0.36, 0.11, -18, z + 1)
    makeCrownSpire(0.13, 0.16, 0.64, 0.11, 18, z + 1)
    local centerSpire = makeCrownSpire(0.15, 0.20, 0.50, 0.08, 0, z + 2)

    if isHero then
        local crownGem = Utils.Create("Frame", {
            Size = UDim2.new(0.36, 0, 0.36, 0),
            Position = UDim2.new(0.5, 0, 0.52, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(235, 58, 88),
            BorderSizePixel = 0,
            ZIndex = z + 3,
        }, centerSpire)
        Utils.AddCorner(crownGem, 6)
    end

    local crownBand = Utils.Create("Frame", {
        Size = UDim2.new(0.42, 0, 0.065, 0),
        Position = UDim2.new(0.50, 0, 0.16, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 2,
    }, holder)
    Utils.AddCorner(crownBand, 3)
    Utils.Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 228, 132)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 108, 20)),
        }),
    }, crownBand)

    local craniumRim = Utils.Create("Frame", {
        Size = UDim2.new(0.76, 0, 0.62, 0),
        Position = UDim2.new(0.50, 0, 0.41, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 2,
    }, holder)
    Utils.AddCorner(craniumRim, math.floor(pixelSize * 0.42))
    Utils.Create("UIGradient", {
        Rotation = 130,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(184, 158, 128)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(68, 52, 44)),
        }),
    }, craniumRim)
    Utils.AddStroke(craniumRim, Color3.fromRGB(218, 168, 72), 1, isHero and 0.25 or 0.4)

    local craniumMain = Utils.Create("Frame", {
        Size = UDim2.new(0.70, 0, 0.56, 0),
        Position = UDim2.new(0.50, 0, 0.40, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 3,
    }, holder)
    Utils.AddCorner(craniumMain, math.floor(pixelSize * 0.40))
    Utils.Create("UIGradient", {
        Rotation = 128,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 250, 242)),
            ColorSequenceKeypoint.new(0.42, Color3.fromRGB(236, 222, 200)),
            ColorSequenceKeypoint.new(0.80, Color3.fromRGB(174, 148, 120)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(108, 86, 70)),
        }),
    }, craniumMain)

    local craniumGloss = Utils.Create("Frame", {
        Size = UDim2.new(0.24, 0, 0.11, 0),
        Position = UDim2.new(0.38, 0, 0.24, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -18,
        BackgroundColor3 = Color3.fromRGB(255, 252, 244),
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(craniumGloss, 8)

    local cheekLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.24, 0, 0.20, 0),
        Position = UDim2.new(0.24, 0, 0.55, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -18,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(cheekLeft, 6)
    Utils.Create("UIGradient", {
        Rotation = 125,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(234, 218, 196)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(132, 108, 88)),
        }),
    }, cheekLeft)

    local cheekRight = Utils.Create("Frame", {
        Size = UDim2.new(0.24, 0, 0.20, 0),
        Position = UDim2.new(0.76, 0, 0.55, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 18,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(cheekRight, 6)
    Utils.Create("UIGradient", {
        Rotation = 125,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(204, 184, 160)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(104, 84, 68)),
        }),
    }, cheekRight)

    local jawRim = Utils.Create("Frame", {
        Size = UDim2.new(0.46, 0, 0.30, 0),
        Position = UDim2.new(0.50, 0, 0.75, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 3,
    }, holder)
    Utils.AddCorner(jawRim, 6)
    Utils.Create("UIGradient", {
        Rotation = 120,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(154, 130, 106)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 48, 42)),
        }),
    }, jawRim)
    Utils.AddStroke(jawRim, Color3.fromRGB(218, 168, 72), 1, 0.4)

    local jawMain = Utils.Create("Frame", {
        Size = UDim2.new(0.40, 0, 0.25, 0),
        Position = UDim2.new(0.50, 0, 0.74, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(jawMain, 5)
    Utils.Create("UIGradient", {
        Rotation = 125,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 214, 190)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(136, 112, 92)),
        }),
    }, jawMain)

    local socketLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.21, 0, 0.19, 0),
        Position = UDim2.new(0.36, 0, 0.47, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -10,
        BackgroundColor3 = Color3.fromRGB(18, 12, 22),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, holder)
    Utils.AddCorner(socketLeft, 5)
    Utils.AddStroke(socketLeft, Color3.fromRGB(198, 146, 56), 1, 0.35)

    local socketRight = Utils.Create("Frame", {
        Size = UDim2.new(0.21, 0, 0.19, 0),
        Position = UDim2.new(0.64, 0, 0.47, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 10,
        BackgroundColor3 = Color3.fromRGB(18, 12, 22),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, holder)
    Utils.AddCorner(socketRight, 5)
    Utils.AddStroke(socketRight, Color3.fromRGB(198, 146, 56), 1, 0.35)

    local eyeLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.13, 0, 0.11, 0),
        Position = UDim2.new(0.36, 0, 0.47, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -10,
        BackgroundColor3 = Color3.fromRGB(255, 224, 92),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(eyeLeft, 4)

    local eyeLeftCore = Utils.Create("Frame", {
        Size = UDim2.new(0.42, 0, 0.42, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 252, 232),
        BorderSizePixel = 0,
        ZIndex = z + 7,
    }, eyeLeft)
    Utils.AddCorner(eyeLeftCore, 4)

    local eyeRight = Utils.Create("Frame", {
        Size = UDim2.new(0.13, 0, 0.11, 0),
        Position = UDim2.new(0.64, 0, 0.47, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 10,
        BackgroundColor3 = Color3.fromRGB(255, 224, 92),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(eyeRight, 4)

    local eyeRightCore = Utils.Create("Frame", {
        Size = UDim2.new(0.42, 0, 0.42, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 252, 232),
        BorderSizePixel = 0,
        ZIndex = z + 7,
    }, eyeRight)
    Utils.AddCorner(eyeRightCore, 4)

    local browLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.22, 0, 0.055, 0),
        Position = UDim2.new(0.36, 0, 0.37, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 10,
        BackgroundColor3 = Color3.fromRGB(228, 212, 188),
        BorderSizePixel = 0,
        ZIndex = z + 7,
    }, holder)
    Utils.AddCorner(browLeft, 3)

    local browRight = Utils.Create("Frame", {
        Size = UDim2.new(0.22, 0, 0.055, 0),
        Position = UDim2.new(0.64, 0, 0.37, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -10,
        BackgroundColor3 = Color3.fromRGB(214, 196, 170),
        BorderSizePixel = 0,
        ZIndex = z + 7,
    }, holder)
    Utils.AddCorner(browRight, 3)

    local noseLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.06, 0, 0.11, 0),
        Position = UDim2.new(0.476, 0, 0.59, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 14,
        BackgroundColor3 = Color3.fromRGB(22, 15, 26),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(noseLeft, 3)

    local noseRight = Utils.Create("Frame", {
        Size = UDim2.new(0.06, 0, 0.11, 0),
        Position = UDim2.new(0.524, 0, 0.59, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -14,
        BackgroundColor3 = Color3.fromRGB(22, 15, 26),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(noseRight, 3)

    local mouth = Utils.Create("Frame", {
        Size = UDim2.new(0.32, 0, 0.11, 0),
        Position = UDim2.new(0.50, 0, 0.75, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 200, 64),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(mouth, 4)

    for _, toothX in ipairs({ 0.15, 0.38, 0.62, 0.85 }) do
        local tooth = Utils.Create("Frame", {
            Size = UDim2.new(0.18, 0, 0.78, 0),
            Position = UDim2.new(toothX, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(246, 238, 224),
            BorderSizePixel = 0,
            ZIndex = z + 7,
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

Utils.CreatePumpkin3D = Utils.CreateSkull3D

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

    local bgGradient = Utils.Create("UIGradient", {
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 20, 48)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(16, 13, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 22, 16)),
        }),
    }, UI.MainFrame)
    bgGradient.Name = "HalloweenLuxuryGradient"

    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(0, -8, 0, -8), Vector2.new(0, 0), 30, false, true)
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(1, 8, 0, -8), Vector2.new(1, 0), 30, false, true)
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(0, -8, 1, 8), Vector2.new(0, 1), 30, false, true)
    Utils.CreatePumpkin3D(UI.MainFrame, 28, UDim2.new(1, 8, 1, 8), Vector2.new(1, 1), 30, false, true)

    UI.InnerClip = Utils.Create("Frame", {
        Name = "InnerClip",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 11,
    }, UI.MainFrame)
    Utils.AddCorner(UI.InnerClip, 14)

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

    Utils.CreatePumpkin3D(UI.Topbar, 32, UDim2.new(0, 32, 0.5, 0), Vector2.new(0.5, 0.5), 14, true, true)

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

    UI.ContentContainer = Utils.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -initSidebarW, 1, -54),
        Position = UDim2.new(0, initSidebarW, 0, 54),
        BackgroundTransparency = 1,
        ZIndex = 12,
    }, UI.InnerClip)

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

if UI.SubLabel then
    LocaleEngine.Bind(function()
        if UI.SubLabel and UI.SubLabel.Parent then
            UI.SubLabel.Text = App.Subtitle
        end
    end)
end

-- ============================================================================
-- 9. REUSABLE UI COMPONENT BUILDERS (Mendukung Lokalisasi Dinamis & Region)
-- ============================================================================
local function resolveTextSpec(spec)
    if type(spec) == "table" then
        return LocaleEngine.Text(spec.id or spec[1] or "", spec.en or spec[2])
    end
    return tostring(spec or "")
end

function Components.SwitchTab(tabId)
    App.ActiveTab = tabId
    for id, tabData in pairs(UI.Tabs) do
        local isSelected = (id == tabId)
        Utils.Tween(tabData.Button, TweenInfo.new(0.18), {
            BackgroundColor3 = isSelected and Theme.BgControl or Theme.BgSecondary,
            BackgroundTransparency = isSelected and 0.18 or 1,
        })
        tabData.Indicator.Visible = isSelected
    end
    for id, page in pairs(UI.Pages) do
        page.Visible = (id == tabId)
    end
end

function Components.CreateTab(tabId, displayNameSpec, iconText, order)
    local btn = Utils.Create("TextButton", {
        Name = tabId .. "Tab",
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
        Text = iconText .. "  " .. resolveTextSpec(displayNameSpec),
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, btn)
    Utils.RegisterText(label, false, Theme.TextPrimary)

    LocaleEngine.Bind(function()
        if label and label.Parent then
            label.Text = iconText .. "  " .. resolveTextSpec(displayNameSpec)
        end
    end)

    local page = Utils.Create("ScrollingFrame", {
        Name = tabId .. "Page",
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
        Components.SwitchTab(tabId)
    end)

    UI.Tabs[tabId] = {
        Button = btn,
        Label = label,
        Indicator = indicator,
    }
    UI.Pages[tabId] = page
    return page
end

function Components.AddSectionHeader(parent, titleSpec, order)
    local lbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "🎃 " .. string.upper(resolveTextSpec(titleSpec)),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.RegisterAccent(lbl, "TextColor3")

    LocaleEngine.Bind(function()
        if lbl and lbl.Parent then
            lbl.Text = "🎃 " .. string.upper(resolveTextSpec(titleSpec))
        end
    end)

    return lbl
end

function Components.AddToggle(parent, titleSpec, subtitleSpec, defaultVal, order, callback)
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
        Text = resolveTextSpec(titleSpec),
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
        Text = resolveTextSpec(subtitleSpec),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 15,
    }, textBox)
    Utils.RegisterText(sLbl, false, Theme.TextSecondary)

    LocaleEngine.Bind(function()
        if tLbl and tLbl.Parent then
            tLbl.Text = resolveTextSpec(titleSpec)
        end
        if sLbl and sLbl.Parent then
            sLbl.Text = resolveTextSpec(subtitleSpec)
        end
    end)

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
            SafeEngine.Run(resolveTextSpec(titleSpec), callback, enabled)
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

function Components.AddSlider(parent, titleSpec, minVal, maxVal, defaultVal, decimals, order, callback)
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
        Size = UDim2.new(0.72, 0, 0, 18),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = resolveTextSpec(titleSpec),
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)

    LocaleEngine.Bind(function()
        if tLbl and tLbl.Parent then
            tLbl.Text = resolveTextSpec(titleSpec)
        end
    end)

    local function formatVal(v)
        if precision <= 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%." .. tostring(precision) .. "f", v)
    end

    local valueLabel = Utils.Create("TextLabel", {
        Size = UDim2.new(0.25, -12, 0, 18),
        Position = UDim2.new(0.75, 0, 0, 8),
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
            SafeEngine.Run(resolveTextSpec(titleSpec), callback, currentVal)
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

function Components.AddButton(parent, titleSpec, subtitleSpec, btnLabelSpec, order, callback)
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
        Size = UDim2.new(1, -118, 0, 18),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = resolveTextSpec(titleSpec),
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)

    local sLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -118, 0, 14),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = resolveTextSpec(subtitleSpec),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(sLbl, false, Theme.TextSecondary)

    local actionBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 96, 0, 28),
        Position = UDim2.new(1, -108, 0.5, -14),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = resolveTextSpec(btnLabelSpec),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(actionBtn, 7)
    Utils.RegisterAccent(actionBtn, "BackgroundColor3")

    LocaleEngine.Bind(function()
        if tLbl and tLbl.Parent then tLbl.Text = resolveTextSpec(titleSpec) end
        if sLbl and sLbl.Parent then sLbl.Text = resolveTextSpec(subtitleSpec) end
        if actionBtn and actionBtn.Parent then actionBtn.Text = resolveTextSpec(btnLabelSpec) end
    end)

    actionBtn.MouseButton1Click:Connect(function()
        if callback then
            SafeEngine.Run(resolveTextSpec(titleSpec), callback)
        end
    end)

    return actionBtn
end

function Components.AddChipSelector(parent, titleSpec, options, defaultVal, order, callback)
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
        Text = resolveTextSpec(titleSpec),
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(titleLbl, true, Theme.TextPrimary)

    LocaleEngine.Bind(function()
        if titleLbl and titleLbl.Parent then
            titleLbl.Text = resolveTextSpec(titleSpec)
        end
    end)

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
        local labelSpec = type(opt) == "table" and opt.Label or tostring(opt)
        local optVal = type(opt) == "table" and opt.Value or opt
        local previewFont = type(opt) == "table" and opt.Font or nil
        local swatchColor = type(opt) == "table" and opt.Color or nil

        local chip = Utils.Create("TextButton", {
            BackgroundColor3 = (optVal == selected) and Theme.Accent or Theme.BgControl,
            BackgroundTransparency = (optVal == selected) and 0.05 or 0.2,
            Font = previewFont or Theme.FontBold,
            Text = resolveTextSpec(labelSpec),
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 16,
        }, grid)
        Utils.AddCorner(chip, 6)

        LocaleEngine.Bind(function()
            if chip and chip.Parent then
                chip.Text = resolveTextSpec(labelSpec)
            end
        end)

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
                SafeEngine.Run(resolveTextSpec(titleSpec), callback, optVal)
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

    local genNameKeywords = {
        "generator", "genset", "reactor", "repairmachine", "powerbox",
        "dynamo", "turbine", "fusebox", "breaker", "panel", "terminal",
        "engine", "mesin", "listrik", "gardu", "trafo", "pump", "boiler", "hackstation"
    }

    local function isGeneratorObject(inst)
        if not inst or not inst.Parent or isPlayerDescendant(inst) then
            return false
        end
        local n = string.lower(inst.Name)
        if n == "gen" or string.match(n, "^gen[%d_%-]") or string.match(n, "[%d_%-]gen$") then
            return true
        end
        for _, kw in ipairs(genNameKeywords) do
            if string.find(n, kw, 1, true) then
                return true
            end
        end

        local prompt = inst:IsA("Model") and inst:FindFirstChildWhichIsA("ProximityPrompt", true) or inst:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            local pText = string.lower((prompt.ActionText or "") .. " " .. (prompt.ObjectText or "") .. " " .. prompt.Name)
            if string.find(pText, "generator", 1, true)
                or string.find(pText, "genset", 1, true)
                or string.find(pText, "distrik", 1, true)
                or ((string.find(pText, "repair", 1, true) or string.find(pText, "perbaiki", 1, true) or string.find(pText, "fix", 1, true) or string.find(pText, "charge", 1, true) or string.find(pText, "isi", 1, true) or string.find(pText, "nyalakan", 1, true) or string.find(pText, "aktifkan", 1, true))
                    and (string.find(pText, "gen", 1, true) or string.find(pText, "mesin", 1, true) or string.find(pText, "power", 1, true) or string.find(pText, "listrik", 1, true) or string.find(pText, "panel", 1, true) or string.find(pText, "daya", 1, true))) then
                return true
            end
        end

        -- Deteksi via atribut / ValueObject khas generator (Progress / Repair / Power)
        local hasGenValue = false
        pcall(function()
            for attrName, _ in pairs(inst:GetAttributes()) do
                local ak = string.lower(attrName)
                if string.find(ak, "repairprogress", 1, true) or string.find(ak, "genprogress", 1, true) or string.find(ak, "isrepaired", 1, true) then
                    hasGenValue = true
                    break
                end
            end
        end)
        if hasGenValue then return true end

        return false
    end

    local function collectGeneratorStatusValues(genObj, entry)
        local vals = {}
        local guiTexts = {}
        local sounds = {}
        local lights = {}
        for _, desc in ipairs(genObj:GetDescendants()) do
            local k = string.lower(desc.Name)
            if desc:IsA("BoolValue") then
                if string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")
                    or string.find(k, "repairing") or string.find(k, "working") or string.find(k, "inuse") or string.find(k, "active") or string.find(k, "on") then
                    table.insert(vals, desc)
                end
            elseif desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("StringValue") then
                if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") or string.find(k, "status") or string.find(k, "state") or string.find(k, "worker") or string.find(k, "user") then
                    table.insert(vals, desc)
                end
            elseif desc:IsA("TextLabel") then
                table.insert(guiTexts, desc)
            elseif desc:IsA("Sound") then
                table.insert(sounds, desc)
            elseif desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
                table.insert(lights, desc)
            end
        end
        entry.StatusValues = vals
        entry.GuiTexts = guiTexts
        entry.Sounds = sounds
        entry.Lights = lights
    end

    local function readAttrProgress(targetObj)
        local pPct = nil
        local done = false
        local working = false
        local worker = nil
        if not targetObj then return nil, false, false, nil end
        pcall(function()
            for attrName, attrVal in pairs(targetObj:GetAttributes()) do
                local k = string.lower(attrName)
                if type(attrVal) == "boolean" then
                    if (string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired") or string.find(k, "finished")) and attrVal == true then
                        done = true
                    elseif (string.find(k, "repairing") or string.find(k, "active") or string.find(k, "working") or string.find(k, "inuse") or string.find(k, "occupied")) and attrVal == true then
                        working = true
                    end
                elseif type(attrVal) == "number" then
                    if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") or string.find(k, "fuel") then
                        local maxAttr = targetObj:GetAttribute("Max" .. attrName) or targetObj:GetAttribute("MaxProgress") or targetObj:GetAttribute("MaxRepair") or 100
                        if attrVal <= 1 and maxAttr == 100 and attrVal > 0 then
                            pPct = math.floor(attrVal * 100 + 0.5)
                        else
                            pPct = math.floor((attrVal / math.max(1, maxAttr)) * 100 + 0.5)
                        end
                    end
                elseif type(attrVal) == "string" and attrVal ~= "" then
                    local lowV = string.lower(attrVal)
                    if string.find(k, "worker") or string.find(k, "player") or string.find(k, "user") or string.find(k, "occupant") then
                        worker = attrVal
                        working = true
                    elseif string.find(lowV, "done") or string.find(lowV, "complete") or string.find(lowV, "selesai") or string.find(lowV, "fixed") then
                        done = true
                    elseif string.find(lowV, "repair") or string.find(lowV, "work") or string.find(lowV, "proses") then
                        working = true
                    end
                end
            end
        end)
        return pPct, done, working, worker
    end

    local function getGeneratorStatus(genObj, entry)
        local progressPct = nil
        local isCompleted = false
        local isBeingWorked = false
        local workerName = nil

        -- 1. Baca Atribut pada genObj & seluruh descendant-nya (Map Distrik sering menyimpan atribut di Core/Prompt)
        local p0, d0, w0, wk0 = readAttrProgress(genObj)
        if p0 then progressPct = p0 end
        if d0 then isCompleted = true end
        if w0 then isBeingWorked = true end
        if wk0 then workerName = wk0 end

        for _, desc in ipairs(genObj:GetDescendants()) do
            local p1, d1, w1, wk1 = readAttrProgress(desc)
            if p1 and (not progressPct or p1 > progressPct) then progressPct = p1 end
            if d1 then isCompleted = true end
            if w1 then isBeingWorked = true end
            if wk1 and not workerName then workerName = wk1 end
        end

        -- 2. Baca ValueObjects (BoolValue, NumberValue, IntValue, StringValue)
        if entry and entry.StatusValues then
            for _, desc in ipairs(entry.StatusValues) do
                if desc and desc.Parent then
                    local k = string.lower(desc.Name)
                    if desc:IsA("BoolValue") then
                        if (string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")) and desc.Value == true then
                            isCompleted = true
                        elseif (string.find(k, "repairing") or string.find(k, "working") or string.find(k, "inuse") or string.find(k, "active")) and desc.Value == true then
                            isBeingWorked = true
                        end
                    elseif desc:IsA("StringValue") and desc.Value ~= "" then
                        local lowV = string.lower(desc.Value)
                        if string.find(k, "worker") or string.find(k, "user") then
                            workerName = desc.Value
                            isBeingWorked = true
                        elseif string.find(lowV, "selesai") or string.find(lowV, "complete") or string.find(lowV, "fixed") then
                            isCompleted = true
                        elseif string.find(lowV, "proses") or string.find(lowV, "repair") then
                            isBeingWorked = true
                        end
                    elseif (desc:IsA("NumberValue") or desc:IsA("IntValue")) then
                        if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                            local maxObj = desc.Parent and (desc.Parent:FindFirstChild("Max" .. desc.Name) or desc.Parent:FindFirstChild("MaxProgress") or desc.Parent:FindFirstChild("MaxValue"))
                            local maxV = (maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) and maxObj.Value > 0) and maxObj.Value or 100
                            local pctVal = (desc.Value <= 1 and maxV == 100 and desc.Value > 0)
                                and math.floor(desc.Value * 100 + 0.5)
                                or math.floor((desc.Value / maxV) * 100 + 0.5)
                            if not progressPct or pctVal > progressPct then
                                progressPct = pctVal
                            end
                        end
                    end
                end
            end
        end

        -- 3. Baca SurfaceGui / BillboardGui bawaan generator (angka persen seperti "45%" atau "100%")
        if entry and entry.GuiTexts then
            for _, lbl in ipairs(entry.GuiTexts) do
                if lbl and lbl.Parent and lbl.Text ~= "" then
                    local pctMatch = string.match(lbl.Text, "(%d+)%s*%%")
                    if pctMatch then
                        local num = tonumber(pctMatch)
                        if num and (not progressPct or num > progressPct) then
                            progressPct = num
                        end
                    end
                end
            end
        end

        -- 4. Cek Suara / Lampu aktif pada generator sebagai indikator sedang dikerjakan
        if not isCompleted and entry and entry.Sounds then
            for _, snd in ipairs(entry.Sounds) do
                if snd and snd.Parent and snd.IsPlaying then
                    local sn = string.lower(snd.Name)
                    if string.find(sn, "repair") or string.find(sn, "fix") or string.find(sn, "spark") or string.find(sn, "weld") or string.find(sn, "work") then
                        isBeingWorked = true
                        break
                    end
                end
            end
        end

        -- 5. Deteksi pemain lain di sekitar generator (radius 13 studs + cek animasi kerja/repair)
        local part = (entry and entry.Part) or getAdorneePart(genObj)
        local nearbyWorkers = {}
        if part and not isCompleted then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local _, pHum, pRoot = Utils.GetCharacter(plr)
                    if pRoot and pHum and pHum.Health > 0 then
                        local d = (pRoot.Position - part.Position).Magnitude
                        if d <= 13 then
                            local animWorking = false
                            local anim = pHum:FindFirstChildOfClass("Animator")
                            if anim then
                                for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
                                    local an = string.lower((tr.Name or "") .. " " .. (tr.Animation and tr.Animation.Name or ""))
                                    if string.find(an, "repair") or string.find(an, "fix") or string.find(an, "work") or string.find(an, "interact") or string.find(an, "kneel") or string.find(an, "crouch") then
                                        animWorking = true
                                        break
                                    end
                                end
                            end
                            if d <= 9.5 or animWorking then
                                table.insert(nearbyWorkers, plr.DisplayName)
                                isBeingWorked = true
                            end
                        end
                    end
                end
            end
        end

        if #nearbyWorkers > 0 then
            workerName = table.concat(nearbyWorkers, ", ")
        end

        local clampedPct = progressPct and math.clamp(progressPct, 0, 100) or 0
        if isCompleted or clampedPct >= 100 then
            return "✅ SELESAI DIPROSES (100%)", 100, "Done"
        elseif isBeingWorked then
            local who = workerName or "Pemain Lain"
            if progressPct and clampedPct > 0 then
                return string.format("🔧 SEDANG DIKERJAKAN: %s (%d%%)", who, clampedPct), clampedPct, "Active"
            end
            return string.format("🔧 SEDANG DIKERJAKAN: %s", who), math.max(clampedPct, 15), "Active"
        elseif progressPct and clampedPct > 0 then
            return string.format("⏸ TERTUNDA / PROGRES (%d%%)", clampedPct), clampedPct, "Partial"
        else
            return "⏳ BELUM DIKERJAKAN (0%)", 0, "Idle"
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
                            FillTransparency = 0.58,
                            OutlineTransparency = 0.08,
                        }, GeneratorESP.Folder)

                        local bb = Utils.Create("BillboardGui", {
                            Name = "GenBB",
                            Size = UDim2.new(0, 260, 0, 68),
                            StudsOffset = Vector3.new(0, 3.2, 0),
                            AlwaysOnTop = true,
                            MaxDistance = math.huge,
                            ResetOnSpawn = false,
                        }, GeneratorESP.Folder)

                        local card = Utils.Create("Frame", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundColor3 = Color3.fromRGB(16, 14, 22),
                            BackgroundTransparency = 0.35,
                            BorderSizePixel = 0,
                        }, bb)
                        Utils.AddCorner(card, 7)
                        local cardStroke = Utils.AddStroke(card, GeneratorESP.Color, 1.2, 0.2)

                        local lbl = Utils.Create("TextLabel", {
                            Size = UDim2.new(1, -10, 0, 44),
                            Position = UDim2.new(0, 5, 0, 3),
                            BackgroundTransparency = 1,
                            Font = GeneratorESP.Font,
                            Text = inst.Name,
                            TextColor3 = GeneratorESP.Color,
                            TextStrokeColor3 = Color3.fromRGB(10, 10, 14),
                            TextStrokeTransparency = 0.25,
                            TextSize = 11,
                            TextWrapped = true,
                        }, card)

                        local barBg = Utils.Create("Frame", {
                            Size = UDim2.new(1, -16, 0, 7),
                            Position = UDim2.new(0, 8, 1, -12),
                            BackgroundColor3 = Color3.fromRGB(36, 32, 46),
                            BorderSizePixel = 0,
                        }, card)
                        Utils.AddCorner(barBg, 4)

                        local barFill = Utils.Create("Frame", {
                            Size = UDim2.new(0, 0, 1, 0),
                            BackgroundColor3 = GeneratorESP.Color,
                            BorderSizePixel = 0,
                        }, barBg)
                        Utils.AddCorner(barFill, 4)

                        entry = {
                            Highlight = hl,
                            Billboard = bb,
                            Card = card,
                            Stroke = cardStroke,
                            Label = lbl,
                            BarBg = barBg,
                            BarFill = barFill,
                            Part = part,
                            StatusValues = {},
                            GuiTexts = {},
                            Sounds = {},
                            Lights = {},
                        }
                        collectGeneratorStatusValues(inst, entry)
                        entry.DescConn = Utils.Track(inst.DescendantAdded:Connect(function(d)
                            if d:IsA("BoolValue") or d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("StringValue") then
                                table.insert(entry.StatusValues, d)
                            elseif d:IsA("TextLabel") then
                                table.insert(entry.GuiTexts, d)
                            elseif d:IsA("Sound") then
                                table.insert(entry.Sounds, d)
                            end
                        end))
                        GeneratorESP.Entries[inst] = entry
                    end

                    local dist = (part.Position - originPos).Magnitude
                    local statusText, pct, stateCode = getGeneratorStatus(inst, entry)

                    local stateColor = GeneratorESP.Color
                    if stateCode == "Active" then
                        stateColor = GeneratorESP.ActiveColor
                    elseif stateCode == "Done" then
                        stateColor = GeneratorESP.DoneColor
                    elseif stateCode == "Idle" then
                        stateColor = GeneratorESP.IdleColor
                    end

                    entry.Highlight.Adornee = inst
                    entry.Highlight.FillColor = stateColor
                    entry.Highlight.OutlineColor = stateColor:Lerp(Color3.new(1, 1, 1), 0.3)
                    entry.Highlight.Enabled = true

                    entry.Billboard.Adornee = part
                    entry.Billboard.Enabled = true
                    entry.Stroke.Color = stateColor
                    entry.Label.Font = GeneratorESP.Font
                    entry.Label.TextColor3 = stateColor
                    entry.Label.Text = string.format("⚡ %s  [%.0f m]\n%s", inst.Name, dist, statusText)

                    entry.BarBg.Visible = GeneratorESP.ShowProgressBar
                    entry.BarFill.BackgroundColor3 = stateColor
                    entry.BarFill.Size = UDim2.new(math.clamp((pct or 0) / 100, 0, 1), 0, 1, 0)
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

    function Combat.CleanupParryVisuals()
        if Combat.ParryRingPart then
            pcall(function() Combat.ParryRingPart:Destroy() end)
            Combat.ParryRingPart = nil
        end
        if Combat.ParryShieldHL then
            pcall(function() Combat.ParryShieldHL:Destroy() end)
            Combat.ParryShieldHL = nil
        end
    end

    function Combat.UpdateParryRangeVisual()
        if not Combat.AutoParryEnabled or not Combat.AutoParryVisual then
            if Combat.ParryRingPart then
                Combat.ParryRingPart.Transparency = 1
            end
            return
        end
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myRoot then return end

        if not Combat.ParryRingPart or not Combat.ParryRingPart.Parent then
            Combat.ParryRingPart = Utils.Create("Part", {
                Name = "BSS_AutoParry_Dome",
                Shape = Enum.PartType.Ball,
                Anchored = true,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                CastShadow = false,
                Material = Enum.Material.ForceField,
                Color = Color3.fromRGB(46, 213, 115),
                Transparency = 0.88,
            }, workspace)
        end

        local diam = Combat.ParryRange * 2
        Combat.ParryRingPart.Size = Vector3.new(diam, diam, diam)
        Combat.ParryRingPart.CFrame = myRoot.CFrame
        local isCooling = (os.clock() - Combat.LastParryTime) < 0.25
        Combat.ParryRingPart.Color = isCooling and Color3.fromRGB(255, 214, 70) or Color3.fromRGB(46, 213, 115)
        Combat.ParryRingPart.Transparency = isCooling and 0.62 or 0.90
    end

    function Combat.ScanParryRemotes()
        if Combat.ParryRemoteScanned then return end
        Combat.ParryRemoteScanned = true
        table.clear(Combat.ParryRemoteCache)
        local parryWords = { "parry", "block", "deflect", "guard", "counter", "tangkis", "shield" }
        for _, container in ipairs({ ReplicatedStorage, LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer and LocalPlayer.Character }) do
            if container then
                for _, desc in ipairs(container:GetDescendants()) do
                    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                        local rn = string.lower(desc.Name)
                        for _, pw in ipairs(parryWords) do
                            if string.find(rn, pw, 1, true) then
                                table.insert(Combat.ParryRemoteCache, desc)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    function Combat.TriggerParryAction(attackerName, attackerChar)
        local now = os.clock()
        if (now - Combat.LastParryTime) < Combat.ParryCooldown then
            return
        end
        Combat.LastParryTime = now
        Combat.ParryCount = Combat.ParryCount + 1

        local myChar, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myChar or not myHum or myHum.Health <= 0 then return end

        -- Hadapkan karakter ke penyerang agar tangkisan arah depan (directional parry) akurat
        if myRoot and attackerChar then
            local aRoot = attackerChar:FindFirstChild("HumanoidRootPart")
            if aRoot then
                local flatTarget = Vector3.new(aRoot.Position.X, myRoot.Position.Y, aRoot.Position.Z)
                if (flatTarget - myRoot.Position).Magnitude > 0.1 then
                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, flatTarget)
                end
            end
        end

        -- 1. Equip & Activate Tool Parry / Melee / Shield (juga cek remote di dalam Tool)
        local activeTool = myChar:FindFirstChildOfClass("Tool")
        local toolKeywords = { "parry", "block", "shield", "sword", "blade", "bat", "katana", "knife", "weapon", "fists", "combat", "melee", "crowbar", "pipe" }
        if not activeTool then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then
                        local tn = string.lower(t.Name)
                        for _, kw in ipairs(toolKeywords) do
                            if string.find(tn, kw, 1, true) then
                                myHum:EquipTool(t)
                                activeTool = t
                                break
                            end
                        end
                        if activeTool then break end
                    end
                end
            end
        end

        if activeTool then
            pcall(function() activeTool:Activate() end)
            for _, desc in ipairs(activeTool:GetDescendants()) do
                if desc:IsA("RemoteEvent") then
                    local dn = string.lower(desc.Name)
                    if string.find(dn, "parry") or string.find(dn, "block") or string.find(dn, "deflect") or string.find(dn, "guard") then
                        pcall(function() desc:FireServer(true) end)
                        pcall(function() desc:FireServer() end)
                    end
                end
            end
        end

        -- 2. Fire Server Parry/Block RemoteEvents jika map menggunakan API Remote (seperti Map Distrik)
        Combat.ScanParryRemotes()
        for _, rem in ipairs(Combat.ParryRemoteCache) do
            if rem and rem.Parent and rem:IsA("RemoteEvent") then
                pcall(function() rem:FireServer(true) end)
                pcall(function() rem:FireServer() end)
            end
        end

        -- 3. Simulasi Tombol Input (F / RMB / E / Q) via VirtualInputManager
        if VirtualInputManager then
            local keysToTap = {}
            if Combat.ParryKey == "F" then
                keysToTap = { Enum.KeyCode.F }
            elseif Combat.ParryKey == "E" then
                keysToTap = { Enum.KeyCode.E }
            elseif Combat.ParryKey == "Q" then
                keysToTap = { Enum.KeyCode.Q }
            elseif Combat.ParryKey == "RMB" then
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
                    task.delay(0.08, function()
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
                        end)
                    end)
                end)
            else
                -- Mode Auto: kirim F dan klik kanan mouse (standar game combat & Distrik Roblox)
                keysToTap = { Enum.KeyCode.F }
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
                    task.delay(0.08, function()
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
                        end)
                    end)
                end)
            end

            for _, kc in ipairs(keysToTap) do
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, kc, false, game)
                    task.delay(0.08, function()
                        pcall(function()
                            VirtualInputManager:SendKeyEvent(false, kc, false, game)
                        end)
                    end)
                end)
            end
        end

        -- 4. Efek Visual Perisai Tangkisan pada Karakter
        if Combat.AutoParryVisual and myChar then
            if not Combat.ParryShieldHL or not Combat.ParryShieldHL.Parent then
                Combat.ParryShieldHL = Utils.Create("Highlight", {
                    Name = "BSS_ParryFlashHL",
                    DepthMode = Enum.HighlightDepthMode.Occluded,
                    FillColor = Color3.fromRGB(46, 213, 115),
                    OutlineColor = Color3.fromRGB(255, 255, 255),
                    FillTransparency = 0.35,
                    OutlineTransparency = 0,
                }, UI.ScreenGui)
            end
            Combat.ParryShieldHL.Adornee = myChar
            Combat.ParryShieldHL.Enabled = true
            task.delay(0.28, function()
                if Combat.ParryShieldHL then
                    Combat.ParryShieldHL.Enabled = false
                end
            end)
        end

        Utils.Notify(
            string.format("Auto Parry #%d ✓", Combat.ParryCount),
            "Menangkis serangan dari " .. tostring(attackerName),
            Theme.Success
        )
    end

    local function isAttackerStriking(char, hum, root, myRoot)
        -- A. Cek Atribut / State Value sedang menyerang (IsAttacking, Swinging, Combat, Dashing)
        local attrAttack = false
        pcall(function()
            for k, v in pairs(char:GetAttributes()) do
                local lk = string.lower(k)
                if v == true and (string.find(lk, "attack") or string.find(lk, "swing") or string.find(lk, "slash") or string.find(lk, "punch") or string.find(lk, "hit") or string.find(lk, "lunge")) then
                    attrAttack = true
                    break
                end
            end
        end)
        if attrAttack then return true end

        -- B. Cek Track Animasi Serangan (nama animasi atau kecepatan ayunan tinggi)
        local attackKeywords = {
            "slash", "punch", "attack", "strike", "jab", "kick", "swing", "hit",
            "heavy", "bash", "slam", "uppercut", "combo", "lunge", "chop", "melee", "stab", "m1", "m2", "skill"
        }
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.IsPlaying and track.Priority ~= Enum.AnimationPriority.Core and track.Priority ~= Enum.AnimationPriority.Idle and track.Priority ~= Enum.AnimationPriority.Movement then
                    local animName = string.lower((track.Name or "") .. " " .. (track.Animation and track.Animation.Name or ""))
                    for _, kw in ipairs(attackKeywords) do
                        if string.find(animName, kw, 1, true) then
                            return true
                        end
                    end
                    -- Jika track berprioritas Action/Action2-4 dan waktu masih fase awal ayunan (< 0.45s)
                    if (track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action2 or track.Priority == Enum.AnimationPriority.Action3 or track.Priority == Enum.AnimationPriority.Action4)
                        and track.TimePosition < 0.45 and not track.Looped then
                        return true
                    end
                end
            end
        end

        -- C. Cek Tool yang dipegang musuh (Sound ayunan / Trail aktif / Hitbox aktif)
        local enemyTool = char:FindFirstChildOfClass("Tool")
        if enemyTool then
            for _, desc in ipairs(enemyTool:GetDescendants()) do
                if desc:IsA("Trail") and desc.Enabled then
                    return true
                elseif desc:IsA("Sound") and desc.IsPlaying then
                    local sn = string.lower(desc.Name)
                    if string.find(sn, "swing") or string.find(sn, "slash") or string.find(sn, "whoosh") or string.find(sn, "punch") or string.find(sn, "hit") then
                        return true
                    end
                end
            end
        end

        -- D. Cek Lunge / Dash mendadak ke arah pemain dalam jarak sangat dekat (< 8.5 studs)
        local toMe = myRoot.Position - root.Position
        local dist = toMe.Magnitude
        if dist > 0.1 and dist <= 8.5 then
            local vel = root.AssemblyLinearVelocity
            local approachSpeed = vel:Dot(toMe.Unit)
            if approachSpeed > 26 then
                return true
            end
        end

        return false
    end

    function Combat.StepAutoParry()
        if not Combat.AutoParryEnabled then
            Combat.CleanupParryVisuals()
            return
        end
        Combat.UpdateParryRangeVisual()

        local _, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myHum or not myRoot or myHum.Health <= 0 then return end

        -- 1. Deteksi serangan dari Pemain lain
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isAlly = (#Teams:GetTeams() > 0 and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
                if not (Combat.TeamCheck and isAlly) then
                    local char, hum, root = Utils.GetCharacter(plr)
                    if char and hum and hum.Health > 0 and root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist <= Combat.ParryRange and isAttackerStriking(char, hum, root, myRoot) then
                            if Combat.ParryReactionDelay > 0 then
                                task.delay(Combat.ParryReactionDelay, function()
                                    if Combat.AutoParryEnabled then
                                        Combat.TriggerParryAction(plr.DisplayName, char)
                                    end
                                end)
                            else
                                Combat.TriggerParryAction(plr.DisplayName, char)
                            end
                            return
                        end
                    end
                end
            end
        end

        -- 2. Deteksi proyektil / tebasan terbang yang mengarah ke karakter
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and not obj.Anchored and obj.Name ~= "BSS_AutoParry_Dome" and obj.Name ~= "BSS_RGB_AimLaser" then
                local dist = (obj.Position - myRoot.Position).Magnitude
                if dist <= Combat.ParryRange and obj.AssemblyLinearVelocity.Magnitude > 30 then
                    local on = string.lower(obj.Name)
                    if string.find(on, "slash") or string.find(on, "wave") or string.find(on, "proj") or string.find(on, "ball") or string.find(on, "arrow") or string.find(on, "blade") then
                        local dirToMe = (myRoot.Position - obj.Position).Unit
                        if obj.AssemblyLinearVelocity.Unit:Dot(dirToMe) > 0.72 then
                            Combat.TriggerParryAction("Proyektil (" .. obj.Name .. ")", nil)
                            return
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

    function Carry.CleanupVisuals()
        if Carry.VisualBeam then
            pcall(function() Carry.VisualBeam:Destroy() end)
            Carry.VisualBeam = nil
        end
        if Carry.VisualAtt0 then
            pcall(function() Carry.VisualAtt0:Destroy() end)
            Carry.VisualAtt0 = nil
        end
        if Carry.VisualAtt1 then
            pcall(function() Carry.VisualAtt1:Destroy() end)
            Carry.VisualAtt1 = nil
        end
        if Carry.TargetHL then
            pcall(function() Carry.TargetHL:Destroy() end)
            Carry.TargetHL = nil
        end
    end

    function Carry.UpdateVisuals(myRoot, tChar, tRoot)
        if not Carry.Enabled or not Carry.ShowVisualBeam or not myRoot or not tChar or not tRoot then
            Carry.CleanupVisuals()
            return
        end

        if not Carry.TargetHL or not Carry.TargetHL.Parent then
            Carry.TargetHL = Utils.Create("Highlight", {
                Name = "BSS_CarryTargetHL",
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillColor = Theme.Accent,
                OutlineColor = Color3.new(1, 1, 1),
                FillTransparency = 0.65,
                OutlineTransparency = 0.1,
            }, UI.ScreenGui)
        end
        Carry.TargetHL.Adornee = tChar
        Carry.TargetHL.FillColor = Theme.Accent
        Carry.TargetHL.Enabled = true

        if not Carry.VisualAtt0 or Carry.VisualAtt0.Parent ~= myRoot then
            if Carry.VisualAtt0 then pcall(function() Carry.VisualAtt0:Destroy() end) end
            Carry.VisualAtt0 = Utils.Create("Attachment", { Name = "BSS_CarryAtt0" }, myRoot)
        end
        if not Carry.VisualAtt1 or Carry.VisualAtt1.Parent ~= tRoot then
            if Carry.VisualAtt1 then pcall(function() Carry.VisualAtt1:Destroy() end) end
            Carry.VisualAtt1 = Utils.Create("Attachment", { Name = "BSS_CarryAtt1" }, tRoot)
        end
        if not Carry.VisualBeam or not Carry.VisualBeam.Parent then
            Carry.VisualBeam = Utils.Create("Beam", {
                Name = "BSS_CarryTetherBeam",
                Attachment0 = Carry.VisualAtt0,
                Attachment1 = Carry.VisualAtt1,
                Width0 = 0.14,
                Width1 = 0.14,
                FaceCamera = true,
                LightEmission = 1,
                Transparency = NumberSequence.new(0.25),
            }, myRoot)
        end
        Carry.VisualBeam.Attachment0 = Carry.VisualAtt0
        Carry.VisualBeam.Attachment1 = Carry.VisualAtt1
        Carry.VisualBeam.Color = ColorSequence.new(Theme.Accent, Color3.fromRGB(46, 213, 115))
    end

    function Carry.ScanCarryRemotes()
        if Carry.CarryRemoteScanned then return end
        Carry.CarryRemoteScanned = true
        table.clear(Carry.CarryRemoteCache)
        local carryWords = { "carry", "gendong", "angkat", "grab", "pick", "piggy", "hold", "drop", "release" }
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                local rn = string.lower(desc.Name)
                for _, cw in ipairs(carryWords) do
                    if string.find(rn, cw, 1, true) then
                        table.insert(Carry.CarryRemoteCache, desc)
                        break
                    end
                end
            end
        end
    end

    function Carry.TryNativeMapCarry(targetPlr)
        local tChar, _, tRoot = Utils.GetCharacter(targetPlr)
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        if not tChar or not tRoot or not myRoot then return false end

        local carryWords = { "carry", "gendong", "angkat", "grab", "pick", "piggy", "hold" }
        for _, desc in ipairs(tChar:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local txt = string.lower((desc.ActionText or "") .. " " .. (desc.ObjectText or "") .. " " .. desc.Name)
                for _, kw in ipairs(carryWords) do
                    if string.find(txt, kw, 1, true) then
                        Utils.SafeTeleport(tRoot.CFrame * CFrame.new(0, 0, 2))
                        task.spawn(function()
                            task.wait(0.12)
                            if desc and desc.Parent then
                                FeatureAPI.TriggerProximity(desc)
                            end
                        end)
                        return true
                    end
                end
            end
        end

        -- Coba API RemoteEvent Carry milik server jika tersedia
        Carry.ScanCarryRemotes()
        for _, rem in ipairs(Carry.CarryRemoteCache) do
            if rem and rem.Parent and rem:IsA("RemoteEvent") then
                local rn = string.lower(rem.Name)
                if not string.find(rn, "drop") and not string.find(rn, "release") then
                    pcall(function() rem:FireServer(targetPlr) end)
                    pcall(function() rem:FireServer(tChar) end)
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

        local modeInfo = Carry.NativePromptTriggered and "Mode Server/Map" or "Mode Visual & Fisika"
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
        Carry.CleanupVisuals()

        if Carry.AnimTrack then
            pcall(function() Carry.AnimTrack:Stop(0.15) end)
            Carry.AnimTrack = nil
        end

        for _, rem in ipairs(Carry.CarryRemoteCache) do
            if rem and rem.Parent and rem:IsA("RemoteEvent") then
                local rn = string.lower(rem.Name)
                if string.find(rn, "drop") or string.find(rn, "release") or string.find(rn, "carry") then
                    pcall(function() rem:FireServer(false) end)
                    pcall(function() rem:FireServer() end)
                end
            end
        end

        if Carry.TargetPlayer then
            local tChar, tHum = Utils.GetCharacter(Carry.TargetPlayer)
            if tChar then
                for _, part in ipairs(tChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
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

        Carry.UpdateVisuals(myRoot, tChar, tRoot)

        if Carry.NativePromptTriggered then
            return
        end

        local offset = carryOffsets[Carry.Style] or carryOffsets.Depan
        tHum.PlatformStand = true
        for _, part in ipairs(tChar:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
        tRoot.AssemblyLinearVelocity = Vector3.zero
        tRoot.AssemblyAngularVelocity = Vector3.zero
        tRoot.CFrame = myRoot.CFrame * offset
    end
end

-- ============================================================================
-- 14. INTERACTIVE REPLICATED R6 & R15 DANCE / EMOTE STUDIO (Terlihat Pemain Lain)
-- ============================================================================
do
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
-- 15B. SECURITY HUB ENGINE (ANTI-CHEAT SERVER BRIDGE, ZONA & LOG DIAGNOSTIK)
-- ============================================================================
do
    function SecurityHub.ConnectServerChannel()
        local folder = ReplicatedStorage:FindFirstChild("SecurityRemotes")
        if not folder then
            SecurityHub.ServerConnected = false
            return false
        end
        local feed = folder:FindFirstChild("AntiCheatFeed")
        local action = folder:FindFirstChild("AdminSecurityAction")
        if feed and feed:IsA("RemoteEvent") and action and action:IsA("RemoteEvent") then
            SecurityHub.TelemetryRemote = feed
            SecurityHub.AdminActionRemote = action
            SecurityHub.ServerConnected = true

            Utils.Track(feed.OnClientEvent:Connect(function(eventType, payload)
                if eventType == "LOG" and type(payload) == "table" then
                    table.insert(SecurityHub.ViolationLogs, 1, payload)
                    if #SecurityHub.ViolationLogs > SecurityHub.MaxLogs then
                        table.remove(SecurityHub.ViolationLogs)
                    end
                    if type(SecurityHub.OnViolationAdded) == "function" then
                        pcall(SecurityHub.OnViolationAdded, payload)
                    end
                end
            end))
            return true
        end
        SecurityHub.ServerConnected = false
        return false
    end

    function SecurityHub.SendAdminAction(actionName, targetUserId)
        if SecurityHub.ServerConnected and SecurityHub.AdminActionRemote then
            pcall(function()
                SecurityHub.AdminActionRemote:FireServer(actionName, targetUserId)
            end)
            Utils.Notify("Moderator Action", actionName .. " dikirim ke server.", Theme.Accent)
        else
            Utils.Notify("Mode Lokal", "Map ini belum memasang server AntiCheatEngine.", Theme.Warning)
        end
    end

    function SecurityHub.ScanCurrentZone()
        if not SecurityHub.ZoneScannerEnabled then return end
        local _, _, root = Utils.GetCharacter(LocalPlayer)
        if not root then return end

        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}

        local detected = "Area Umum (Normal)"
        local ok, parts = pcall(function()
            return workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(4, 6, 4), params)
        end)
        if ok and parts then
            for _, p in ipairs(parts) do
                local n = string.lower(p.Name)
                if string.find(n, "safe") or string.find(n, "spawn") or string.find(n, "lobby") then
                    detected = "Zona Aman (" .. p.Name .. ")"
                    break
                elseif string.find(n, "pvp") or string.find(n, "combat") or string.find(n, "arena") or string.find(n, "danger") then
                    detected = "Zona Pertarungan (" .. p.Name .. ")"
                    break
                elseif string.find(n, "checkpoint") or string.find(n, "stage") then
                    detected = "Checkpoint (" .. p.Name .. ")"
                    break
                end
            end
        end

        if detected ~= SecurityHub.CurrentZoneName then
            SecurityHub.CurrentZoneName = detected
            if type(SecurityHub.OnZoneChanged) == "function" then
                pcall(SecurityHub.OnZoneChanged, detected)
            end
        end
    end

    Utils.Track(LogService.MessageOut:Connect(function(message, messageType)
        if not SecurityHub.LogCaptureEnabled then return end
        if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
            local entry = {
                Time = os.date("%H:%M:%S"),
                Level = (messageType == Enum.MessageType.MessageError) and "ERROR" or "WARN",
                Text = tostring(message),
            }
            table.insert(SecurityHub.ConsoleLogs, 1, entry)
            if #SecurityHub.ConsoleLogs > SecurityHub.MaxLogs then
                table.remove(SecurityHub.ConsoleLogs)
            end
            if type(SecurityHub.OnConsoleLogAdded) == "function" then
                pcall(SecurityHub.OnConsoleLogAdded, entry)
            end
        end
    end))

    SecurityHub.ConnectServerChannel()
end

-- ============================================================================
-- TAB 1 (PALING ATAS): INFORMASI, REGION PERANGKAT & DUKUNGAN KOMUNITAS
-- ============================================================================
do
    local page = Components.CreateTab("Informasi", { id = "Informasi", en = "Information" }, "ⓘ", 1)
    Components.AddSectionHeader(page, { id = "Informasi Pembuat & Region Perangkat", en = "Creator Information & Device Region" }, 1)

    local infoCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(infoCard, 9)
    local stroke = Utils.AddStroke(infoCard, Theme.Accent, 1.2, 0.25)
    Utils.RegisterAccent(stroke, "Color")

    Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, infoCard)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, infoCard)

    local h1 = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "🎃 " .. App.Name .. " — Edisi Universal",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 15,
    }, infoCard)
    Utils.RegisterText(h1, true, Theme.TextPrimary)

    local h2 = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Terima kasih telah menggunakan BimSakSin Hub v3.0! Semoga hari-hari kalian menyenangkan.\nTekan F2 kapan saja untuk membuka Command Palette cepat. Jika ditemukan kendala, laporkan melalui Discord resmi di bawah ini.",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 15,
    }, infoCard)
    Utils.RegisterText(h2, false, Theme.TextSecondary)

    local regionBadge = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.2,
        Font = Theme.FontBold,
        Text = "  🌍 Region Perangkat: " .. LocaleEngine.RegionDisplay,
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
        ZIndex = 15,
    }, infoCard)
    Utils.AddCorner(regionBadge, 6)
    Utils.RegisterAccent(regionBadge, "TextColor3")

    LocaleEngine.Bind(function()
        if h1 and h1.Parent then
            h1.Text = LocaleEngine.Text(
                "🎃 " .. App.Name .. " — Edisi Universal",
                "🎃 " .. App.Name .. " — Universal Edition"
            )
        end
        if h2 and h2.Parent then
            h2.Text = LocaleEngine.Text(
                "Terima kasih telah menggunakan BimSakSin Hub v3.0! Semoga hari-hari kalian menyenangkan.\nTekan F2 kapan saja untuk membuka Command Palette cepat. Jika ditemukan kendala, laporkan melalui Discord resmi di bawah ini.",
                "Thank you for using BimSakSin Hub v3.0! Wishing you a wonderful day.\nPress F2 anytime to open the quick Command Palette. If you encounter any bugs, please notify us via Discord below."
            )
        end
        if regionBadge and regionBadge.Parent then
            regionBadge.Text = LocaleEngine.Text(
                "  🌍 Region Perangkat: " .. LocaleEngine.RegionDisplay,
                "  🌍 Device Region: " .. LocaleEngine.RegionDisplay
            )
        end
    end)

    Components.AddSectionHeader(page, { id = "Tautan Resmi Komunitas & Donasi", en = "Official Community & Donation Links" }, 3)

    Components.AddButton(
        page,
        { id = "Tautan Donasi & Dukungan Developer", en = "Developer Donation & Support Link" },
        App.DonationUrl,
        { id = "Salin Tautan", en = "Copy Link" },
        4,
        function()
            if Utils.CopyText(App.DonationUrl) then
                Utils.Notify(
                    LocaleEngine.Text("Tautan Donasi Tersalin!", "Donation Link Copied!"),
                    App.DonationUrl,
                    Theme.Success
                )
            else
                Utils.Notify(
                    LocaleEngine.Text("Tautan Donasi", "Donation Link"),
                    App.DonationUrl,
                    Theme.Accent
                )
            end
        end
    )

    Components.AddButton(
        page,
        { id = "Tautan Server Discord Resmi", en = "Official Discord Server Link" },
        App.DiscordUrl,
        { id = "Salin Tautan", en = "Copy Link" },
        5,
        function()
            if Utils.CopyText(App.DiscordUrl) then
                Utils.Notify(
                    LocaleEngine.Text("Tautan Discord Tersalin!", "Discord Link Copied!"),
                    App.DiscordUrl,
                    Theme.Success
                )
            else
                Utils.Notify(
                    LocaleEngine.Text("Tautan Discord", "Discord Link"),
                    App.DiscordUrl,
                    Theme.Accent
                )
            end
        end
    )
end

-- ============================================================================
-- TAB 2: BERANDA (TELEMETRI PERANGKAT REAL-TIME & UTILITAS SERVER)
-- ============================================================================
do
    local page = Components.CreateTab("Beranda", { id = "Beranda", en = "Home" }, "◈", 2)
    Components.AddSectionHeader(page, { id = "Telemetri Perangkat Real-Time", en = "Live Client Telemetry" }, 1)

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

    local function createStatCard(labelSpec, initialValue, order)
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
            Text = resolveTextSpec(labelSpec),
            TextColor3 = Theme.TextSecondary,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterText(l1, false, Theme.TextSecondary)

        LocaleEngine.Bind(function()
            if l1 and l1.Parent then
                l1.Text = resolveTextSpec(labelSpec)
            end
        end)

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

    UI.TelemetryLabels.FPS = createStatCard({ id = "Kecepatan Frame (FPS)", en = "Frame Rate (FPS)" }, "60 FPS", 1)
    UI.TelemetryLabels.Ping = createStatCard({ id = "Latensi Jaringan (Ping)", en = "Network Latency" }, "-- ms", 2)
    UI.TelemetryLabels.Memory = createStatCard({ id = "Penggunaan Memori", en = "Client Memory" }, "-- MB", 3)
    UI.TelemetryLabels.Players = createStatCard({ id = "Pemain di Server", en = "Active Players" }, tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), 4)

    Components.AddSectionHeader(page, { id = "Utilitas Server & Karakter", en = "Server & Session Utilities" }, 3)

    Components.AddButton(
        page,
        { id = "Salin ID Map & Server", en = "Copy Place & Job ID" },
        "PlaceId: " .. tostring(game.PlaceId),
        { id = "Salin ID", en = "Copy ID" },
        4,
        function()
            local infoStr = string.format("PlaceId: %s | JobId: %s", tostring(game.PlaceId), tostring(game.JobId))
            if Utils.CopyText(infoStr) then
                Utils.Notify(LocaleEngine.Text("ID Tersalin", "ID Copied"), infoStr, Theme.Success)
            else
                Utils.Notify(LocaleEngine.Text("Info Server", "Server Info"), infoStr, Theme.Accent)
            end
        end
    )

    Components.AddButton(
        page,
        { id = "Segarkan Karakter (Respawn)", en = "Respawn Character" },
        { id = "Memuat ulang karakter lokal jika tersangkut atau bug", en = "Refresh local character state" },
        { id = "Respawn", en = "Respawn" },
        5,
        function()
            local _, hum = Utils.GetCharacter()
            if hum then
                hum.Health = 0
                Utils.Notify(
                    LocaleEngine.Text("Karakter", "Character"),
                    LocaleEngine.Text("Memuat ulang karakter...", "Respawning character..."),
                    Theme.Warning
                )
            end
        end
    )

    Components.AddButton(
        page,
        { id = "Gabung Ulang Server (Rejoin)", en = "Rejoin Current Server" },
        { id = "Menghubungkan ulang ke instance server yang sama", en = "Reconnect to the same PlaceId instance" },
        { id = "Gabung Ulang", en = "Rejoin" },
        6,
        function()
            Utils.Notify(
                "TeleportService",
                LocaleEngine.Text("Menghubungkan ulang ke server...", "Rejoining current server..."),
                Theme.Accent
            )
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end
    )
end

-- ============================================================================
-- TAB 3: RADAR ESP (ESP PEMAIN, BARANG / LOOT & GENERATOR REAL-TIME)
-- ============================================================================
do
    local page = Components.CreateTab("RadarESP", { id = "Radar ESP", en = "ESP Radar" }, "👁", 3)
    Components.AddSectionHeader(page, { id = "ESP Pemain & Sorotan Avatar", en = "Player ESP & Avatar Highlight" }, 1)

    Components.AddToggle(
        page,
        { id = "Aktifkan ESP Pemain Universal", en = "Enable Universal Player ESP" },
        { id = "Menampilkan posisi dan informasi pemain menembus dinding di semua map", en = "Display long-range through-wall player ESP across all maps" },
        false,
        2,
        function(on)
            ESP.Enabled = on
            if not on then
                ESP.ClearAll()
            end
            Utils.Notify(
                "ESP Pemain",
                on and LocaleEngine.Text("ESP pemain aktif di seluruh map.", "Player ESP enabled across the map.")
                    or LocaleEngine.Text("ESP pemain dimatikan.", "Player ESP disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddToggle(
        page,
        { id = "Sorot Avatar Tembus Dinding", en = "Through-Wall Transparent Avatar" },
        { id = "Menyorot tubuh avatar pemain agar terlihat jelas dari jarak jauh", en = "Highlight player avatars so they remain visible from any distance" },
        true,
        3,
        function(on)
            ESP.ShowAvatar = on
        end
    )

    Components.AddToggle(
        page,
        { id = "Tampilkan Jarak Pemain (Meter)", en = "Show Distance (Meters)" },
        { id = "Menampilkan jarak real-time dari posisi Anda ke setiap pemain", en = "Display real-time distance to every player" },
        true,
        4,
        function(on)
            ESP.ShowDistance = on
        end
    )

    Components.AddToggle(
        page,
        { id = "Tampilkan Darah / HP Pemain", en = "Show Health (Map Adaptive)" },
        { id = "Otomatis menampilkan indikator darah jika map menggunakan sistem HP", en = "Automatically display HP when the map uses a health system" },
        true,
        5,
        function(on)
            ESP.ShowHealth = on
        end
    )

    Components.AddChipSelector(page, { id = "Filter Target ESP Pemain", en = "ESP Target Mode (Ally / Enemy / Random)" }, {
        { Label = { id = "Otomatis Map", en = "Auto Map" }, Value = "Auto" },
        { Label = { id = "Musuh Saja", en = "Enemies Only" }, Value = "Enemy" },
        { Label = { id = "Rekan Tim", en = "Allies Only" }, Value = "Ally" },
        { Label = { id = "Semua Acak", en = "Random All" }, Value = "Random" },
    }, "Auto", 6, function(val)
        ESP.Mode = val
        Utils.Notify("Radar ESP", LocaleEngine.Text("Filter target diatur ke: ", "Target filter set to: ") .. val, Theme.Accent)
    end)

    Components.AddSlider(page, { id = "Batas Jarak ESP Pemain (Studs)", en = "Max Player ESP Distance (Studs)" }, 200, 10000, 2500, 0, 7, function(val)
        ESP.MaxDistance = val
    end)

    Components.AddSectionHeader(page, { id = "Kustomisasi Warna & Huruf ESP Pemain", en = "Player ESP Color & Font Customization" }, 8)

    Components.AddChipSelector(page, { id = "Gaya Huruf (Font) ESP Pemain", en = "Player ESP Font Style" }, {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Merriweather", Value = Enum.Font.Merriweather, Font = Enum.Font.Merriweather },
    }, Enum.Font.GothamBold, 9, function(val)
        ESP.Font = val
    end)

    Components.AddChipSelector(page, { id = "Warna Sorotan Utama Avatar", en = "Primary ESP / Highlight Color" }, {
        { Label = { id = "Emas Labu", en = "Pumpkin Gold" }, Value = Color3.fromRGB(255, 118, 26), Color = Color3.fromRGB(255, 118, 26) },
        { Label = { id = "Merah Darah", en = "Blood Red" }, Value = Color3.fromRGB(235, 69, 95), Color = Color3.fromRGB(235, 69, 95) },
        { Label = { id = "Hijau Neon", en = "Neon Green" }, Value = Color3.fromRGB(46, 213, 115), Color = Color3.fromRGB(46, 213, 115) },
        { Label = { id = "Biru Sian", en = "Spectral Cyan" }, Value = Color3.fromRGB(24, 220, 255), Color = Color3.fromRGB(24, 220, 255) },
        { Label = { id = "Ungu Mistis", en = "Mystic Purple" }, Value = Color3.fromRGB(165, 94, 234), Color = Color3.fromRGB(165, 94, 234) },
        { Label = { id = "Putih Terang", en = "Bright White" }, Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(255, 118, 26), 10, function(val)
        ESP.HighlightColor = val
    end)

    Components.AddChipSelector(page, { id = "Warna Teks Jarak", en = "Distance Text Color" }, {
        { Label = { id = "Kuning Emas", en = "Golden Yellow" }, Value = Color3.fromRGB(255, 210, 120), Color = Color3.fromRGB(255, 210, 120) },
        { Label = { id = "Biru Es", en = "Ice Cyan" }, Value = Color3.fromRGB(112, 235, 255), Color = Color3.fromRGB(112, 235, 255) },
        { Label = { id = "Putih Bersih", en = "Pure White" }, Value = Color3.fromRGB(250, 250, 255), Color = Color3.fromRGB(250, 250, 255) },
        { Label = { id = "Oranye Labu", en = "Pumpkin Orange" }, Value = Color3.fromRGB(255, 145, 65), Color = Color3.fromRGB(255, 145, 65) },
        { Label = { id = "Merah Muda", en = "Neon Pink" }, Value = Color3.fromRGB(255, 118, 195), Color = Color3.fromRGB(255, 118, 195) },
        { Label = { id = "Hijau Mint", en = "Mint Green" }, Value = Color3.fromRGB(130, 255, 185), Color = Color3.fromRGB(130, 255, 185) },
    }, Color3.fromRGB(255, 210, 120), 11, function(val)
        ESP.DistanceColor = val
    end)

    Components.AddChipSelector(page, { id = "Warna Teks Darah (HP)", en = "Health (HP) Text Color" }, {
        { Label = { id = "Hijau Sehat", en = "HP Green" }, Value = Color3.fromRGB(85, 239, 148), Color = Color3.fromRGB(85, 239, 148) },
        { Label = { id = "Merah Kritis", en = "Crimson Red" }, Value = Color3.fromRGB(255, 88, 108), Color = Color3.fromRGB(255, 88, 108) },
        { Label = { id = "Kuning Amber", en = "Amber Yellow" }, Value = Color3.fromRGB(255, 214, 70), Color = Color3.fromRGB(255, 214, 70) },
        { Label = { id = "Putih Salju", en = "Snow White" }, Value = Color3.fromRGB(245, 248, 255), Color = Color3.fromRGB(245, 248, 255) },
        { Label = { id = "Biru Elektrik", en = "Electric Blue" }, Value = Color3.fromRGB(95, 185, 255), Color = Color3.fromRGB(95, 185, 255) },
        { Label = { id = "Ungu Violet", en = "Violet Purple" }, Value = Color3.fromRGB(195, 135, 255), Color = Color3.fromRGB(195, 135, 255) },
    }, Color3.fromRGB(85, 239, 148), 12, function(val)
        ESP.HealthColor = val
    end)

    Components.AddChipSelector(page, { id = "Warna Latar Label Pemain", en = "Player Label Backdrop Color" }, {
        { Label = { id = "Hitam Tipis", en = "Subtle Black" }, Value = Color3.fromRGB(16, 12, 24), Color = Color3.fromRGB(16, 12, 24) },
        { Label = { id = "Ungu Malam", en = "Night Purple" }, Value = Color3.fromRGB(36, 20, 56), Color = Color3.fromRGB(36, 20, 56) },
        { Label = { id = "Coklat Labu", en = "Pumpkin Brown" }, Value = Color3.fromRGB(48, 24, 12), Color = Color3.fromRGB(48, 24, 12) },
        { Label = { id = "Merah Gelap", en = "Dark Crimson" }, Value = Color3.fromRGB(48, 14, 22), Color = Color3.fromRGB(48, 14, 22) },
        { Label = { id = "Putih Kabut", en = "Mist White" }, Value = Color3.fromRGB(235, 230, 242), Color = Color3.fromRGB(235, 230, 242) },
        { Label = { id = "Bening Halus", en = "Ultra Clear" }, Value = Color3.fromRGB(10, 10, 14), Color = Color3.fromRGB(10, 10, 14) },
    }, Color3.fromRGB(16, 12, 24), 13, function(val)
        ESP.FontBgColor = val
        ESP.FontBgTransparency = (val == Color3.fromRGB(10, 10, 14)) and 0.78 or 0.56
    end)

    Components.AddChipSelector(page, { id = "Warna Teks Nama Pemain", en = "Player Name Font Color" }, {
        { Label = { id = "Kontras Otomatis", en = "Auto Contrast" }, Value = "Auto", Color = Color3.fromRGB(255, 195, 110) },
        { Label = { id = "Putih Tulang", en = "Ivory White" }, Value = Color3.fromRGB(255, 248, 240), Color = Color3.fromRGB(255, 248, 240) },
        { Label = { id = "Emas Labu", en = "Pumpkin Gold" }, Value = Color3.fromRGB(255, 155, 55), Color = Color3.fromRGB(255, 155, 55) },
        { Label = { id = "Merah Terang", en = "Bright Red" }, Value = Color3.fromRGB(255, 95, 115), Color = Color3.fromRGB(255, 95, 115) },
        { Label = { id = "Hijau Spektral", en = "Spectral Green" }, Value = Color3.fromRGB(95, 245, 155), Color = Color3.fromRGB(95, 245, 155) },
        { Label = { id = "Hitam Pekat", en = "Deep Black" }, Value = Color3.fromRGB(20, 16, 28), Color = Color3.fromRGB(20, 16, 28) },
    }, "Auto", 14, function(val)
        if val == "Auto" then
            ESP.FontAutoContrast = true
        else
            ESP.FontAutoContrast = false
            ESP.FontColor = val
        end
    end)

    Components.AddSectionHeader(page, { id = "ESP Barang & Loot (Jarak Tak Terbatas)", en = "Item & Loot ESP (Unlimited Range)" }, 15)

    Components.AddToggle(
        page,
        { id = "Aktifkan ESP Barang & Loot", en = "Enable Item & Loot ESP (All Maps)" },
        { id = "Mendeteksi item, senjata, dan barang jatuh tanpa batas jarak maupun latar belakang", en = "Detect items, loot, and tools at any distance without background boxes" },
        false,
        16,
        function(on)
            ItemESP.Enabled = on
            if not on then
                ItemESP.ClearAll()
            else
                ItemESP.ScanAndRender()
            end
            Utils.Notify(
                "ESP Barang",
                on and LocaleEngine.Text("ESP Barang aktif (tanpa batas jarak).", "Item ESP enabled (unlimited distance).")
                    or LocaleEngine.Text("ESP Barang dimatikan.", "Item ESP disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddChipSelector(page, { id = "Gaya Huruf (Font) ESP Barang", en = "Item ESP Font Style" }, {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Oswald", Value = Enum.Font.Oswald, Font = Enum.Font.Oswald },
    }, Enum.Font.GothamBold, 17, function(val)
        ItemESP.Font = val
    end)

    Components.AddChipSelector(page, { id = "Warna Teks ESP Barang", en = "Item ESP Text Color" }, {
        { Label = { id = "Sian Terang", en = "Bright Cyan" }, Value = Color3.fromRGB(102, 242, 255), Color = Color3.fromRGB(102, 242, 255) },
        { Label = { id = "Kuning Emas", en = "Golden Yellow" }, Value = Color3.fromRGB(255, 218, 88), Color = Color3.fromRGB(255, 218, 88) },
        { Label = { id = "Hijau Neon", en = "Neon Green" }, Value = Color3.fromRGB(85, 255, 145), Color = Color3.fromRGB(85, 255, 145) },
        { Label = { id = "Oranye Labu", en = "Pumpkin Orange" }, Value = Color3.fromRGB(255, 145, 55), Color = Color3.fromRGB(255, 145, 55) },
        { Label = { id = "Merah Muda", en = "Neon Pink" }, Value = Color3.fromRGB(255, 125, 210), Color = Color3.fromRGB(255, 125, 210) },
        { Label = { id = "Putih Bersih", en = "Pure White" }, Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(102, 242, 255), 18, function(val)
        ItemESP.Color = val
    end)

    Components.AddSectionHeader(page, { id = "ESP Generator & Status Mesin", en = "Generator ESP (Real-Time Status)" }, 19)

    Components.AddToggle(
        page,
        { id = "Aktifkan ESP Generator & Mesin", en = "Enable Generator ESP (All Maps)" },
        { id = "Menampilkan lokasi, jarak, serta status pengerjaan generator secara real-time", en = "Display generator ESP, distance, and live repair progress status" },
        false,
        20,
        function(on)
            GeneratorESP.Enabled = on
            if not on then
                GeneratorESP.ClearAll()
            else
                GeneratorESP.ScanAndRender()
            end
            Utils.Notify(
                "ESP Generator",
                on and LocaleEngine.Text("ESP Generator aktif.", "Generator ESP enabled.")
                    or LocaleEngine.Text("ESP Generator dimatikan.", "Generator ESP disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddChipSelector(page, { id = "Gaya Huruf (Font) ESP Generator", en = "Generator ESP Font Style" }, {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Oswald", Value = Enum.Font.Oswald, Font = Enum.Font.Oswald },
    }, Enum.Font.GothamBold, 21, function(val)
        GeneratorESP.Font = val
    end)

    Components.AddToggle(
        page,
        { id = "Tampilkan Progress Bar Generator", en = "Show Generator Progress Bar" },
        { id = "Menampilkan bilah visual persentase pengerjaan generator oleh pemain lain", en = "Display visual progress bar showing live repair percentage" },
        true,
        22,
        function(on)
            GeneratorESP.ShowProgressBar = on
        end
    )

    Components.AddChipSelector(page, { id = "Warna Sorotan ESP Generator", en = "Generator ESP Color" }, {
        { Label = { id = "Emas Listrik", en = "Electric Gold" }, Value = Color3.fromRGB(255, 196, 54), Color = Color3.fromRGB(255, 196, 54) },
        { Label = { id = "Hijau Mesin", en = "Engine Green" }, Value = Color3.fromRGB(72, 245, 140), Color = Color3.fromRGB(72, 245, 140) },
        { Label = { id = "Biru Plasma", en = "Plasma Blue" }, Value = Color3.fromRGB(75, 185, 255), Color = Color3.fromRGB(75, 185, 255) },
        { Label = { id = "Merah Siaga", en = "Alert Red" }, Value = Color3.fromRGB(255, 85, 105), Color = Color3.fromRGB(255, 85, 105) },
        { Label = { id = "Ungu Spektral", en = "Spectral Purple" }, Value = Color3.fromRGB(185, 115, 255), Color = Color3.fromRGB(185, 115, 255) },
        { Label = { id = "Putih Terang", en = "Bright White" }, Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(255, 196, 54), 23, function(val)
        GeneratorESP.Color = val
        GeneratorESP.IdleColor = val
    end)
end

-- ============================================================================
-- TAB 4: PERTARUNGAN (BIDIK OTOMATIS, TANGKIS SERANGAN & KETAHANAN)
-- ============================================================================
do
    local page = Components.CreateTab("Pertarungan", { id = "Pertarungan", en = "Combat" }, "🎯", 4)
    Components.AddSectionHeader(page, { id = "Bidik Otomatis (Auto Aimbot)", en = "High-Precision Auto Aimbot" }, 1)

    Components.AddToggle(
        page,
        { id = "Aktifkan Bidik Otomatis (Aimbot)", en = "Enable Precision Auto Aimbot" },
        { id = "Mengunci bidikan secara presisi ke sasaran saat menyerang atau membidik", en = "Automatically lock aim onto targets during melee or ranged combat" },
        false,
        2,
        function(on)
            Combat.AimbotEnabled = on
            if not on then
                Combat.CurrentTarget = nil
                Combat.HideLaser()
            end
            Utils.Notify(
                "Bidik Otomatis",
                on and LocaleEngine.Text("Bidik otomatis presisi aktif.", "Precision aimbot enabled.")
                    or LocaleEngine.Text("Bidik otomatis dimatikan.", "Aimbot disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddToggle(
        page,
        { id = "Laser RGB Khusus Senjata Api", en = "RGB Laser for Ranged Weapons" },
        { id = "Menampilkan garis laser RGB hanya saat memegang senjata jarak jauh", en = "Show RGB laser beam only when holding firearms or ranged weapons" },
        true,
        3,
        function(on)
            Combat.RGBLaserEnabled = on
            if not on then
                Combat.HideLaser()
            end
        end
    )

    Components.AddChipSelector(page, { id = "Mode Aktivasi Bidikan", en = "Aimbot Trigger Mode" }, {
        { Label = { id = "Otomatis (Senjata/Klik)", en = "Auto (Tool/Click)" }, Value = "Auto" },
        { Label = { id = "Selalu Mengunci", en = "Always Lock" }, Value = "Always" },
        { Label = { id = "Tahan Klik Kanan", en = "Hold Right Click" }, Value = "HoldRMB" },
    }, "Auto", 4, function(val)
        Combat.AimbotMode = val
    end)

    Components.AddChipSelector(page, { id = "Bagian Tubuh Target", en = "Target Body Part" }, {
        { Label = { id = "Kepala", en = "Head" }, Value = "Head" },
        { Label = { id = "Badan Utama", en = "Torso" }, Value = "HumanoidRootPart" },
        { Label = { id = "Terdekat FOV", en = "Closest in FOV" }, Value = "Closest" },
    }, "Head", 5, function(val)
        Combat.AimPart = val
    end)

    Components.AddToggle(
        page,
        { id = "Abaikan Rekan Satu Tim", en = "Ignore Teammates (Team Check)" },
        { id = "Mencegah bidikan mengunci pemain yang berada dalam tim yang sama", en = "Avoid locking onto teammates in team-based games" },
        true,
        6,
        function(on)
            Combat.TeamCheck = on
        end
    )

    Components.AddToggle(
        page,
        { id = "Tampilkan Lingkaran Area FOV", en = "Show Aim FOV Circle" },
        { id = "Menampilkan batas lingkaran jangkauan bidikan di tengah layar", en = "Visualize aim detection radius at screen center" },
        false,
        7,
        function(on)
            Combat.ShowFOVCircle = on
            if Combat.FOVCircle then
                Combat.FOVCircle.Visible = on
            end
        end
    )

    Components.AddSlider(page, { id = "Radius Area Bidikan (FOV)", en = "Aim FOV Radius" }, 60, 600, 220, 0, 8, function(val)
        Combat.FOVRadius = val
        if Combat.FOVCircle then
            Combat.FOVCircle.Size = UDim2.new(0, val * 2, 0, val * 2)
        end
    end)

    Components.AddSlider(page, { id = "Kecepatan Kunci Bidikan (1.0 = Instan)", en = "Aim Lock Smoothness (1 = Instant)" }, 0.1, 1.0, 0.35, 2, 9, function(val)
        Combat.Smoothness = val
    end)

    Components.AddSectionHeader(page, { id = "Tangkis Otomatis & Pertahanan Karakter", en = "Auto Parry & Character Defense" }, 10)

    Components.AddToggle(
        page,
        { id = "Tangkis Serangan Otomatis (Auto Parry)", en = "Auto Parry Incoming Attacks" },
        { id = "Otomatis menangkis serangan jarak dekat ketika pemain sekitar mulai memukul", en = "Automatically parry when nearby players launch melee attacks" },
        false,
        11,
        function(on)
            Combat.AutoParryEnabled = on
            Utils.Notify(
                "Auto Parry",
                on and LocaleEngine.Text("Tangkis otomatis aktif & memantau serangan sekitar!", "Auto Parry active and monitoring nearby attacks!")
                    or LocaleEngine.Text("Tangkis otomatis dimatikan.", "Auto Parry disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddToggle(
        page,
        { id = "Visual Radius & Perisai Auto Parry", en = "Auto Parry Visual Dome & Shield" },
        { id = "Menampilkan kubah radar jangkauan parry dan kilau perisai saat menangkis", en = "Display 3D parry detection dome and shield flash upon deflecting" },
        true,
        12,
        function(on)
            Combat.AutoParryVisual = on
            if not on then
                Combat.CleanupParryVisuals()
            end
        end
    )

    Components.AddChipSelector(page, { id = "Tombol / API Tangkisan (Parry Key)", en = "Parry Input / API Trigger" }, {
        { Label = { id = "Otomatis (Semua API)", en = "Auto (All APIs)" }, Value = "Auto" },
        { Label = { id = "Tombol F", en = "Key F" }, Value = "F" },
        { Label = { id = "Klik Kanan (RMB)", en = "Right Click" }, Value = "RMB" },
        { Label = { id = "Tombol E", en = "Key E" }, Value = "E" },
        { Label = { id = "Tombol Q", en = "Key Q" }, Value = "Q" },
    }, "Auto", 13, function(val)
        Combat.ParryKey = val
    end)

    Components.AddSlider(page, { id = "Jarak Deteksi Tangkisan (Studs)", en = "Auto Parry Detection Range (Studs)" }, 6, 40, 18, 0, 14, function(val)
        Combat.ParryRange = val
    end)

    Components.AddToggle(
        page,
        { id = "Kebal Pukulan & Anti-Mental", en = "Melee Immunity & Anti-Knockback" },
        { id = "Menahan efek terpental, jatuh (ragdoll), dan sentuhan senjata melee lawan", en = "Prevent knockback, ragdoll states, and enemy melee weapon hitboxes" },
        false,
        13,
        function(on)
            Combat.MeleeImmunity = on
            if not on then
                Protection.RestoreEnemyHitboxes()
            end
            Utils.Notify(
                "Kebal Pukulan",
                on and LocaleEngine.Text("Mode kebal pukulan & anti-mental aktif!", "Melee immunity & anti-knockback enabled!")
                    or LocaleEngine.Text("Mode kebal dimatikan.", "Melee immunity disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddToggle(
        page,
        { id = "Tahan Lapar & Tahan Haus", en = "Hunger & Thirst Guard (All Maps)" },
        { id = "Menjaga indikator lapar, haus, dan energi karakter tetap penuh di semua map", en = "Keep hunger, thirst, and energy meters full across survival maps" },
        false,
        14,
        function(on)
            Combat.HungerThirstGuard = on
            Utils.Notify(
                "Ketahanan Survival",
                on and LocaleEngine.Text("Tahan lapar & tahan haus aktif!", "Hunger & Thirst guard enabled!")
                    or LocaleEngine.Text("Tahan lapar & haus dimatikan.", "Hunger & Thirst guard disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )
end

-- ============================================================================
-- TAB 5: PERGERAKAN (KECEPATAN, LOMPATAN, TERBANG HALUS & TEMBUS OBJEK)
-- ============================================================================
do
    local page = Components.CreateTab("Pergerakan", { id = "Pergerakan", en = "Movement" }, "⚡", 5)
    Components.AddSectionHeader(page, { id = "Penyetelan Gerak Dasar", en = "Character Locomotion Tuning" }, 1)

    local wsSlider = Components.AddSlider(page, { id = "Kecepatan Berjalan (WalkSpeed)", en = "WalkSpeed" }, 16, 250, 16, 0, 2, function(val)
        State.WalkSpeed = val
        local _, hum = Utils.GetCharacter()
        if hum then hum.WalkSpeed = val end
    end)

    local jpSlider = Components.AddSlider(page, { id = "Kekuatan Lompatan (JumpPower)", en = "JumpPower" }, 50, 300, 50, 0, 3, function(val)
        State.JumpPower = val
        local _, hum = Utils.GetCharacter()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end)

    local maxGrav = math.max(300, math.ceil(State.OriginalGravity))
    local gravSlider = Components.AddSlider(page, { id = "Gravitasi Dunia (Gravity)", en = "Workspace Gravity" }, 0, maxGrav, State.OriginalGravity, 1, 4, function(val)
        State.Gravity = val
        workspace.Gravity = val
    end)

    local origGravStr = string.format("%.1f", State.OriginalGravity)
    Components.AddButton(
        page,
        { id = "Pulihkan Fisika Bawaan", en = "Reset Physics Defaults" },
        { id = "Kembalikan kecepatan jalan (16), lompatan (50), dan gravitasi (" .. origGravStr .. ")", en = "Restore WalkSpeed (16), JumpPower (50), Gravity (" .. origGravStr .. ")" },
        { id = "Pulihkan", en = "Reset All" },
        5,
        function()
            wsSlider.SetValue(16, true)
            jpSlider.SetValue(50, true)
            gravSlider.SetValue(State.OriginalGravity, true)
            Utils.Notify(
                LocaleEngine.Text("Fisika Dipulihkan", "Physics Reset"),
                LocaleEngine.Text("Nilai pergerakan dikembalikan ke bawaan.", "Movement values restored to defaults."),
                Theme.Success
            )
        end
    )

    Components.AddSectionHeader(page, { id = "Mode Terbang & Tembus Objek", en = "Flight & Navigation Modes" }, 6)

    Components.AddToggle(
        page,
        { id = "Mode Terbang Halus (Fly)", en = "Smooth Free-Flight (Fly)" },
        { id = "Terbang bebas ke segala arah dengan kendali halus untuk PC maupun Mobile", en = "Smooth admin-style free flight without rubberbanding (PC & Mobile)" },
        false,
        7,
        function(on)
            State.FlyEnabled = on
            if on then
                local _, hum = Utils.GetCharacter()
                if hum and hum.Sit then
                    hum.Sit = false
                end
            else
                Physics.CleanupFly()
            end
            Utils.Notify(
                "Mode Terbang",
                on and LocaleEngine.Text("Mode terbang halus aktif.", "Smooth flight enabled.")
                    or LocaleEngine.Text("Mode terbang dimatikan.", "Flight disabled."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddSlider(page, { id = "Kecepatan Terbang", en = "Flight Speed" }, 20, 250, 65, 0, 8, function(val)
        State.FlySpeed = val
    end)

    Components.AddToggle(
        page,
        { id = "Mode Tembus Objek (NoClip)", en = "NoClip Geometry Inspector" },
        { id = "Menonaktifkan tabrakan dinding; gerakkan analog secara perlahan saat menembus objek", en = "Disable wall collisions; push analog stick gently when passing through walls" },
        false,
        9,
        function(on)
            State.NoclipEnabled = on
            if not on then Physics.RestoreNoclip() end
            Utils.Notify(
                "Mode Tembus Objek",
                on and LocaleEngine.Text("NoClip aktif (gerakkan analog perlahan saat menembus).", "NoClip active (move analog gently through geometry).")
                    or LocaleEngine.Text("Tabrakan objek dipulihkan.", "Collisions restored."),
                on and Theme.Warning or Theme.TextSecondary
            )
        end
    )

    Components.AddToggle(
        page,
        { id = "Lompat Tanpa Batas (Infinite Jump)", en = "Infinite Jump" },
        { id = "Memungkinkan karakter melompat berkali-kali saat berada di udara", en = "Jump repeatedly while airborne" },
        false,
        10,
        function(on)
            State.InfiniteJumpEnabled = on
        end
    )
end

-- ============================================================================
-- TAB 6: TELEPORTASI (KOORDINAT, TITIK SIMPAN / WAYPOINT & TELEPORT PEMAIN)
-- ============================================================================
do
    local page = Components.CreateTab("Teleportasi", { id = "Teleportasi", en = "Teleport" }, "⌖", 6)
    Components.AddSectionHeader(page, { id = "Koordinat & Titik Simpan (Waypoint)", en = "Coordinates & Waypoint Manager" }, 1)

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
        Size = UDim2.new(1, -118, 1, 0),
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
        Size = UDim2.new(0, 96, 0, 28),
        Position = UDim2.new(1, -108, 0.5, -14),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontBold,
        Text = LocaleEngine.Text("Salin CFrame", "Copy CFrame"),
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, posCard)
    Utils.AddCorner(copyPosBtn, 6)

    LocaleEngine.Bind(function()
        if copyPosBtn and copyPosBtn.Parent then
            copyPosBtn.Text = LocaleEngine.Text("Salin CFrame", "Copy CFrame")
        end
    end)

    copyPosBtn.MouseButton1Click:Connect(function()
        local _, _, root = Utils.GetCharacter()
        if root then
            local p = root.Position
            local cfStr = string.format("CFrame.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
            if Utils.CopyText(cfStr) then
                Utils.Notify(LocaleEngine.Text("CFrame Tersalin", "CFrame Copied"), cfStr, Theme.Success)
            else
                Utils.Notify(LocaleEngine.Text("CFrame Saat Ini", "Current CFrame"), cfStr, Theme.Accent)
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
        PlaceholderText = LocaleEngine.Text("Nama titik lokasi (mis. Spawn, Atap)...", "Waypoint name (e.g. Spawn, Roof)..."),
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
        Text = LocaleEngine.Text("+ Simpan", "+ Save Point"),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
    }, wpInputCard)
    Utils.AddCorner(saveWpBtn, 6)
    Utils.RegisterAccent(saveWpBtn, "BackgroundColor3")

    LocaleEngine.Bind(function()
        if wpBox and wpBox.Parent then
            wpBox.PlaceholderText = LocaleEngine.Text("Nama titik lokasi (mis. Spawn, Atap)...", "Waypoint name (e.g. Spawn, Roof)...")
        end
        if saveWpBtn and saveWpBtn.Parent then
            saveWpBtn.Text = LocaleEngine.Text("+ Simpan", "+ Save Point")
        end
    end)

    local wpListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, wpListHolder)

    local function renderWaypoints()
        for _, child in ipairs(wpListHolder:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for idx, wp in ipairs(State.Waypoints) do
            local row = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Theme.BgSecondary,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                LayoutOrder = idx,
                ZIndex = 15,
            }, wpListHolder)
            Utils.AddCorner(row, 7)
            Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.3)

            Utils.Create("TextLabel", {
                Size = UDim2.new(1, -142, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = string.format("%s (%.0f, %.0f, %.0f)", wp.Name, wp.CFrame.X, wp.CFrame.Y, wp.CFrame.Z),
                TextColor3 = Theme.TextPrimary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 16,
            }, row)

            local tpBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 72, 0, 24),
                Position = UDim2.new(1, -116, 0.5, -12),
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
                if Utils.SafeTeleport(wp.CFrame) then
                    Utils.Notify(
                        "Teleport",
                        LocaleEngine.Text("Berpindah ke ", "Teleported to ") .. wp.Name,
                        Theme.Success
                    )
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
            Utils.Notify("Error", LocaleEngine.Text("Karakter belum siap.", "Character root not found."), Theme.Danger)
            return
        end
        local name = wpBox.Text ~= "" and wpBox.Text or (LocaleEngine.Text("Titik #", "Point #") .. tostring(#State.Waypoints + 1))
        table.insert(State.Waypoints, { Name = name, CFrame = root.CFrame })
        wpBox.Text = ""
        renderWaypoints()
        Utils.Notify(
            LocaleEngine.Text("Lokasi Tersimpan", "Waypoint Saved"),
            LocaleEngine.Text("Menyimpan '", "Saved '") .. name .. "'",
            Theme.Success
        )
    end)

    Components.AddSectionHeader(page, { id = "Teleport & Pantau Pemain di Server", en = "Player Teleport & Spectate" }, 5)

    local playerListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, playerListHolder)

    local function refreshPlayerList()
        for _, child in ipairs(playerListHolder:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                count = count + 1
                local row = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    LayoutOrder = count,
                    ZIndex = 15,
                }, playerListHolder)
                Utils.AddCorner(row, 8)
                Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.3)

                Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -162, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 16,
                }, row)

                local tpBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 68, 0, 24),
                    Position = UDim2.new(1, -146, 0.5, -12),
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
                    Size = UDim2.new(0, 64, 0, 24),
                    Position = UDim2.new(1, -72, 0.5, -12),
                    BackgroundColor3 = isSpec and Theme.Warning or Theme.BgControl,
                    Font = Theme.FontBold,
                    Text = isSpec and LocaleEngine.Text("Berhenti", "Unview") or LocaleEngine.Text("Pantau", "View"),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 16,
                }, row)
                Utils.AddCorner(viewBtn, 5)

                tpBtn.MouseButton1Click:Connect(function()
                    local targetRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        if Utils.SafeTeleport(targetRoot.CFrame * CFrame.new(0, 0.5, 3)) then
                            Utils.Notify(
                                "Teleport",
                                LocaleEngine.Text("Berpindah ke ", "Teleported to ") .. plr.DisplayName,
                                Theme.Success
                            )
                        end
                    else
                        Utils.Notify(
                            LocaleEngine.Text("Tidak Tersedia", "Unavailable"),
                            LocaleEngine.Text("Karakter pemain belum muncul.", "Target character has not spawned yet."),
                            Theme.Warning
                        )
                    end
                end)

                viewBtn.MouseButton1Click:Connect(function()
                    local cam = workspace.CurrentCamera
                    if State.SpectatingPlayer == plr then
                        State.SpectatingPlayer = nil
                        local _, myHum = Utils.GetCharacter()
                        if cam and myHum then cam.CameraSubject = myHum end
                        Utils.Notify(
                            LocaleEngine.Text("Kamera", "Camera"),
                            LocaleEngine.Text("Kamera kembali ke karakter Anda.", "Camera returned to LocalPlayer."),
                            Theme.TextSecondary
                        )
                    else
                        local targetHum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                        if cam and targetHum then
                            State.SpectatingPlayer = plr
                            cam.CameraSubject = targetHum
                            Utils.Notify(
                                LocaleEngine.Text("Memantau Pemain", "Spectating"),
                                LocaleEngine.Text("Memantau kamera ", "Viewing ") .. plr.DisplayName,
                                Theme.Warning
                            )
                        end
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
                Text = LocaleEngine.Text("Belum ada pemain lain di server ini.", "No other players in this server yet."),
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                ZIndex = 16,
            }, empty)
        end
    end

    refreshPlayerList()
    LocaleEngine.Bind(refreshPlayerList)
    Utils.Track(Players.PlayerAdded:Connect(refreshPlayerList))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if State.SpectatingPlayer == plr then
            State.SpectatingPlayer = nil
            local _, myHum = Utils.GetCharacter()
            if workspace.CurrentCamera and myHum then
                workspace.CurrentCamera.CameraSubject = myHum
            end
        end
        task.defer(refreshPlayerList)
    end))
end

-- ============================================================================
-- TAB 7: GENDONG / CARRY (INTERAKSI GENDONG PEMAIN LAIN)
-- ============================================================================
do
    local page = Components.CreateTab("Gendong", { id = "Gendong", en = "Carry" }, "🫂", 7)
    Components.AddSectionHeader(page, { id = "Kontrol Utama Gendong (Carry)", en = "Interactive Carry Controls" }, 1)

    local carryStatusLabel = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = LocaleEngine.Text("  Target Terpilih: Belum ada pemain dipilih", "  Selected Target: No player selected"),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(carryStatusLabel, 7)
    Utils.RegisterText(carryStatusLabel, true, Theme.TextSecondary)

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
        Text = LocaleEngine.Text("🫂 Mulai Gendong", "🫂 Start Carry"),
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
        Text = LocaleEngine.Text("✋ Lepaskan", "✋ Release Carry"),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
    }, actionRow)
    Utils.AddCorner(releaseCarryBtn, 8)

    LocaleEngine.Bind(function()
        if carryBtn and carryBtn.Parent then
            carryBtn.Text = LocaleEngine.Text("🫂 Mulai Gendong", "🫂 Start Carry")
        end
        if releaseCarryBtn and releaseCarryBtn.Parent then
            releaseCarryBtn.Text = LocaleEngine.Text("✋ Lepaskan", "✋ Release Carry")
        end
        if carryStatusLabel and carryStatusLabel.Parent and not Carry.TargetPlayer then
            carryStatusLabel.Text = LocaleEngine.Text("  Target Terpilih: Belum ada pemain dipilih", "  Selected Target: No player selected")
        end
    end)

    carryBtn.MouseButton1Click:Connect(function()
        SafeEngine.Run("CarryStart", function()
            if Carry.Start() and Carry.TargetPlayer then
                local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
                carryStatusLabel.Text = "  Status: Menggendong " .. Carry.TargetPlayer.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
            end
        end)
    end)

    releaseCarryBtn.MouseButton1Click:Connect(function()
        SafeEngine.Run("CarryStop", function()
            Carry.Stop()
            carryStatusLabel.Text = Carry.TargetPlayer
                and ("  Target Terpilih: " .. Carry.TargetPlayer.DisplayName .. " (Dilepaskan)")
                or LocaleEngine.Text("  Target Terpilih: Belum ada pemain dipilih", "  Selected Target: No player selected")
            Utils.Notify(
                LocaleEngine.Text("Lepas Gendong", "Carry Released"),
                LocaleEngine.Text("Target telah dilepaskan.", "Target has been released."),
                Theme.TextSecondary
            )
        end)
    end)

    Components.AddToggle(
        page,
        { id = "Visual Sorotan & Tali Energi Carry", en = "Carry Visual Highlight & Tether Beam" },
        { id = "Menampilkan sorotan avatar target dan garis penghubung visual saat menggendong", en = "Display target avatar highlight and glowing tether beam while carrying" },
        true,
        4,
        function(on)
            Carry.ShowVisualBeam = on
            if not on then
                Carry.CleanupVisuals()
            end
        end
    )

    Components.AddChipSelector(page, { id = "Pilih Posisi / Gaya Gendong", en = "Select Carry Style" }, {
        { Label = { id = "Gendong Depan", en = "Front Carry" }, Value = "Depan" },
        { Label = { id = "Gendong Belakang", en = "Piggyback" }, Value = "Belakang" },
        { Label = { id = "Panggul Pundak", en = "Shoulder" }, Value = "Pundak" },
        { Label = { id = "Seret Tanah", en = "Drag" }, Value = "Seret" },
        { Label = { id = "Angkat Kepala", en = "Head Carry" }, Value = "Kepala" },
        { Label = { id = "Melayang Samping", en = "Side Float" }, Value = "Melayang" },
    }, "Depan", 5, function(val)
        Carry.Style = val
        if Carry.Enabled and Carry.TargetPlayer then
            local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
            carryStatusLabel.Text = "  Status: Menggendong " .. Carry.TargetPlayer.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
        end
        Utils.Notify(
            LocaleEngine.Text("Gaya Gendong", "Carry Style"),
            LocaleEngine.Text("Gaya diubah ke: ", "Style changed to: ") .. val,
            Theme.Accent
        )
    end)

    Components.AddSectionHeader(page, { id = "Daftar Pemain untuk Digendong", en = "Select Player to Carry" }, 5)

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
                    Size = UDim2.new(1, -116, 1, 0),
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
                    Size = UDim2.new(0, 92, 0, 26),
                    Position = UDim2.new(1, -102, 0.5, -13),
                    BackgroundColor3 = isSelected and Theme.Success or Theme.Accent,
                    Font = Theme.FontBold,
                    Text = isSelected and LocaleEngine.Text("Terpilih ✓", "Selected ✓") or LocaleEngine.Text("Pilih Target", "Select"),
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
                        carryStatusLabel.Text = "  Status: Menggendong " .. plr.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
                    else
                        carryStatusLabel.Text = "  Target Terpilih: " .. plr.DisplayName .. " (Tekan Mulai Gendong)"
                    end
                    refreshCarryPlayers()
                    Utils.Notify(
                        LocaleEngine.Text("Target Dipilih", "Target Selected"),
                        LocaleEngine.Text("Siap menggendong ", "Ready to carry ") .. plr.DisplayName,
                        Theme.Accent
                    )
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
                Text = LocaleEngine.Text("Belum ada pemain lain di server untuk digendong.", "No other players in server to carry."),
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                ZIndex = 15,
            }, empty)
        end
    end

    refreshCarryPlayers()
    LocaleEngine.Bind(refreshCarryPlayers)
    Utils.Track(Players.PlayerAdded:Connect(refreshCarryPlayers))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if Carry.TargetPlayer == plr then
            Carry.Stop()
            Carry.TargetPlayer = nil
            carryStatusLabel.Text = LocaleEngine.Text("  Target Terpilih: Belum ada pemain dipilih", "  Selected Target: No player selected")
        end
        task.defer(refreshCarryPlayers)
    end))
end

-- ============================================================================
-- TAB 8: TARI & EMOTE (STUDIO ANIMASI REPLIKASI R6 & R15)
-- ============================================================================
do
    local page = Components.CreateTab("TariEmote", { id = "Tari & Emote", en = "Dances" }, "💃", 8)
    Components.AddSectionHeader(page, { id = "Kontrol Gerakan Tari & Emote", en = "Interactive Dance Controls" }, 1)

    Components.AddSlider(page, { id = "Kecepatan Animasi Tari", en = "Dance Animation Speed" }, 0.5, 2.5, 1.0, 1, 2, function(val)
        Emotes.Speed = val
        if Emotes.ActiveTrack then
            pcall(function() Emotes.ActiveTrack:AdjustSpeed(val) end)
        end
    end)

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
        PlaceholderText = LocaleEngine.Text("Masukkan ID Animasi Roblox (angka)...", "Custom Dance Animation ID (numbers)..."),
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
        Text = LocaleEngine.Text("Putar ID", "Play ID"),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, customAnimCard)
    Utils.AddCorner(playCustomBtn, 6)
    Utils.RegisterAccent(playCustomBtn, "BackgroundColor3")

    LocaleEngine.Bind(function()
        if animBox and animBox.Parent then
            animBox.PlaceholderText = LocaleEngine.Text("Masukkan ID Animasi Roblox (angka)...", "Custom Dance Animation ID (numbers)...")
        end
        if playCustomBtn and playCustomBtn.Parent then
            playCustomBtn.Text = LocaleEngine.Text("Putar ID", "Play ID")
        end
    end)

    playCustomBtn.MouseButton1Click:Connect(function()
        if animBox.Text ~= "" then
            Emotes.PlayAsset("Custom Dance", animBox.Text)
        else
            Utils.Notify(
                LocaleEngine.Text("ID Animasi", "Dance ID"),
                LocaleEngine.Text("Masukkan angka ID animasi Roblox terlebih dahulu.", "Enter a valid Roblox animation ID first."),
                Theme.Warning
            )
        end
    end)

    Components.AddButton(
        page,
        { id = "Hentikan Tari & Pulihkan Pose", en = "Stop Dance / Reset Pose" },
        { id = "Menghentikan animasi tari yang sedang berjalan", en = "Stop currently playing dance animation" },
        { id = "Hentikan", en = "Stop Dance" },
        4,
        function()
            Emotes.Stop()
            Utils.Notify("Tari & Emote", LocaleEngine.Text("Animasi tari dihentikan.", "Dance stopped."), Theme.TextSecondary)
        end
    )

    Components.AddSectionHeader(page, { id = "Katalog Tari Replikasi (R6 & R15)", en = "Replicated Dance Catalog (R6 & R15)" }, 5)

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
        local stroke = Utils.AddStroke(btn, Theme.BorderSubtle, 1, 0.3)

        btn.MouseEnter:Connect(function()
            Utils.Tween(stroke, TweenInfo.new(0.15), { Color = Theme.Accent })
        end)
        btn.MouseLeave:Connect(function()
            Utils.Tween(stroke, TweenInfo.new(0.15), { Color = Theme.BorderSubtle })
        end)

        btn.MouseButton1Click:Connect(function()
            Emotes.PlayPreset(d)
        end)
    end
end

-- ============================================================================
-- TAB 9: VISUAL (KAMERA FOV, PENCAHAYAAN PENUH & HAPUS KABUT)
-- ============================================================================
do
    local page = Components.CreateTab("Visual", { id = "Visual", en = "Visuals" }, "☀", 9)
    Components.AddSectionHeader(page, { id = "Pengaturan Kamera & Pencahayaan Dunia", en = "Camera & World Lighting" }, 1)

    local fovSlider = Components.AddSlider(page, { id = "Sudut Pandang Kamera (FOV)", en = "Camera Field of View (FOV)" }, 40, 120, 70, 0, 2, function(val)
        State.CameraFOV = val
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = val end
    end)

    UI.FullbrightToggle = Components.AddToggle(
        page,
        { id = "Pencahayaan Penuh (Fullbright)", en = "Fullbright Lighting" },
        { id = "Menerangi seluruh area gelap dan bayangan malam secara otomatis", en = "Remove darkness and equalize ambient lighting" },
        false,
        3,
        function(on)
            State.FullbrightEnabled = on
            if not on then
                Lighting.Brightness = State.OriginalLighting.Brightness
                Lighting.ClockTime = State.OriginalLighting.ClockTime
                Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
                Lighting.Ambient = State.OriginalLighting.Ambient
                Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
            end
            Utils.Notify(
                "Visual",
                on and LocaleEngine.Text("Pencahayaan penuh aktif.", "Fullbright enabled.")
                    or LocaleEngine.Text("Pencahayaan dikembalikan ke bawaan.", "Lighting restored."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    UI.NoFogToggle = Components.AddToggle(
        page,
        { id = "Hapus Kabut & Jarak Pandang Jauh", en = "Remove Fog & Atmosphere" },
        { id = "Menghilangkan kabut tebal dan kepadatan atmosfer untuk jarak pandang maksimal", en = "Clear fog limits and dense Atmosphere effects" },
        false,
        4,
        function(on)
            State.NoFogEnabled = on
            if not on then
                Lighting.FogEnd = State.OriginalLighting.FogEnd
                Lighting.FogStart = State.OriginalLighting.FogStart
                if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance then
                    State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
                end
            end
            Utils.Notify(
                "Visual",
                on and LocaleEngine.Text("Kabut dihapus.", "Fog cleared.")
                    or LocaleEngine.Text("Kabut dikembalikan ke bawaan.", "Fog restored."),
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddButton(
        page,
        { id = "Pulihkan Visual Bawaan Map", en = "Restore Default Visuals" },
        { id = "Mengembalikan FOV kamera ke 70 serta pencahayaan dan kabut asli map", en = "Reset Camera FOV to 70 and restore original world lighting" },
        { id = "Pulihkan", en = "Restore" },
        5,
        function()
            fovSlider.SetValue(70, true)
            if UI.FullbrightToggle then UI.FullbrightToggle.SetState(false, true) end
            if UI.NoFogToggle then UI.NoFogToggle.SetState(false, true) end
            Utils.Notify(
                LocaleEngine.Text("Visual Dipulihkan", "Visuals Restored"),
                LocaleEngine.Text("Pengaturan kamera & dunia kembali normal.", "Camera and lighting reset."),
                Theme.Success
            )
        end
    )
end

-- ============================================================================
-- TAB 10: SALIN ASET & MAP (EKSPOR FILE .LUA/.JSON + NOTIFIKASI TELEGRAM)
-- ============================================================================
do
    local page = Components.CreateTab("SalinAset", { id = "Salin Aset", en = "Copy Assets" }, "📦", 10)
    Components.AddSectionHeader(page, { id = "Copy Item / Map & Auto File Generator", en = "Copy Item / Map & Auto File Generator" }, 1)

    local targetCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(targetCard, 9)
    Utils.AddStroke(targetCard, Theme.BorderSubtle, 1, 0.3)

    local filterBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 12, 0.5, -15),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Filter nama item/map (kosongkan = otomatis item dipegang / terdekat)...", "Target item/map name filter (blank = equipped or nearest)..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, targetCard)
    Utils.AddCorner(filterBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, filterBox)
    filterBox:GetPropertyChangedSignal("Text"):Connect(function()
        AssetCopy.TargetFilter = filterBox.Text
    end)

    Components.AddChipSelector(page, { id = "Cakupan Copy (Item / Semua Senjata / Map)", en = "Copy Scope (Nearest / All Tools / Full Map)" }, {
        { Label = { id = "Item Terdekat", en = "Nearest / Held" }, Value = "EquippedOrNearest" },
        { Label = { id = "Semua Item/Tool", en = "All Tools" }, Value = "AllTools" },
        { Label = { id = "Seluruh Map", en = "Full Map" }, Value = "FullMap" },
    }, "EquippedOrNearest", 3, function(val)
        AssetCopy.CopyScope = val
    end)

    Components.AddChipSelector(page, { id = "Format File Otomatis (.LUA & .JSON)", en = "Auto-Generated File Format" }, {
        { Label = { id = "LUA + JSON", en = "LUA + JSON" }, Value = "LuauAndJSON" },
        { Label = { id = "Hanya .LUA", en = ".LUA Only" }, Value = "LuauOnly" },
        { Label = { id = "Hanya .JSON", en = ".JSON Only" }, Value = "JSONOnly" },
    }, "LuauAndJSON", 4, function(val)
        AssetCopy.FormatMode = val
    end)

    Components.AddSectionHeader(page, { id = "Konfigurasi Notifikasi Bot Telegram", en = "Telegram Bot Notification Config" }, 5)

    local tgCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 84),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(tgCard, 9)
    Utils.AddStroke(tgCard, Theme.BorderSubtle, 1, 0.3)

    local tokenBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 10),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Telegram Bot Token (mis. 123456789:ABCdef...)...", "Telegram Bot Token (e.g. 123456789:ABCdef...)..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, tgCard)
    Utils.AddCorner(tokenBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, tokenBox)
    tokenBox:GetPropertyChangedSignal("Text"):Connect(function()
        AssetCopy.TelegramBotToken = tokenBox.Text
    end)

    local chatIdBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 46),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Telegram Chat ID / User ID (mis. 987654321)...", "Telegram Chat ID / User ID (e.g. 987654321)..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, tgCard)
    Utils.AddCorner(chatIdBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, chatIdBox)
    chatIdBox:GetPropertyChangedSignal("Text"):Connect(function()
        AssetCopy.TelegramChatId = chatIdBox.Text
    end)

    LocaleEngine.Bind(function()
        if filterBox and filterBox.Parent then
            filterBox.PlaceholderText = LocaleEngine.Text("Filter nama item/map (kosongkan = otomatis item dipegang / terdekat)...", "Target item/map name filter (blank = equipped or nearest)...")
        end
        if tokenBox and tokenBox.Parent then
            tokenBox.PlaceholderText = LocaleEngine.Text("Telegram Bot Token (mis. 123456789:ABCdef...)...", "Telegram Bot Token (e.g. 123456789:ABCdef...)...")
        end
        if chatIdBox and chatIdBox.Parent then
            chatIdBox.PlaceholderText = LocaleEngine.Text("Telegram Chat ID / User ID (mis. 987654321)...", "Telegram Chat ID / User ID (e.g. 987654321)...")
        end
    end)

    Components.AddToggle(
        page,
        { id = "Kirim Notifikasi Telegram Otomatis", en = "Auto-Send Telegram Alert on Copy" },
        { id = "Otomatis mengirim laporan detail ke Bot Telegram setelah file selesai dibuat", en = "Automatically push summary alert to Telegram Bot after export completes" },
        true,
        7,
        function(on)
            AssetCopy.AutoNotifyTelegram = on
        end
    )

    local exportStatusLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.25,
        Font = Theme.FontFamily,
        Text = "  Folder Output: " .. AssetCopy.FolderPath,
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 8,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(exportStatusLbl, 6)
    Utils.RegisterText(exportStatusLbl, false, Theme.TextSecondary)

    Components.AddButton(
        page,
        { id = "Mulai Copy & Buat File Sekarang", en = "Execute Copy & Generate Files" },
        { id = "Mengekspor struktur item/map ke file .lua/.json dan mengirim alert Telegram", en = "Serialize target item/map into .lua/.json files and notify Telegram" },
        { id = "Copy & Export", en = "Copy & Export" },
        9,
        function()
            exportStatusLbl.Text = LocaleEngine.Text("  Memproses copy & membuat file...", "  Copying & generating files...")
            task.spawn(function()
                SafeEngine.Run("AssetCopyExport", function()
                    AssetCopy.ExecuteCopyAndExport()
                    if #AssetCopy.LastExportedFiles > 0 then
                        exportStatusLbl.Text = "  File Terbaru: " .. tostring(AssetCopy.LastExportedFiles[1])
                    else
                        exportStatusLbl.Text = "  Folder Output: " .. AssetCopy.FolderPath
                    end
                end)
            end)
        end
    )

    Components.AddButton(
        page,
        { id = "Uji Koneksi Bot Telegram", en = "Test Telegram Bot Connection" },
        { id = "Mengirim pesan percobaan ke Chat ID Telegram yang dimasukkan", en = "Send a test notification message to your configured Telegram Chat ID" },
        { id = "Tes Telegram", en = "Test Alert" },
        10,
        function()
            task.spawn(function()
                local ok, msg = AssetCopy.SendTelegramNotification({
                    GameTitle = AssetCopy.GetGameTitleSafe(),
                    PlaceId = game.PlaceId,
                    AssetName = "Uji_Koneksi_Bot",
                    ClassName = "DiagnosticTest",
                    Scope = "TestPing",
                    TotalNodes = 1,
                    TimestampISO = os.date("%Y-%m-%d %H:%M:%S"),
                }, { "Test_Connection_OK.txt" })
                Utils.Notify(
                    ok and LocaleEngine.Text("Telegram Terhubung ✓", "Telegram Connected ✓") or LocaleEngine.Text("Telegram Gagal", "Telegram Failed"),
                    msg,
                    ok and Theme.Success or Theme.Danger
                )
            end)
        end
    )
end

-- ============================================================================
-- TAB 11 (BARU): KEAMANAN & ANTI-CHEAT (MONITOR SERVER, ZONA & DIAGNOSTIK LOG)
-- ============================================================================
do
    local page = Components.CreateTab("KeamananAC", { id = "Keamanan & AC", en = "Security & AC" }, "🛡", 11)
    Components.AddSectionHeader(page, { id = "Status Server Anti-Cheat & Deteksi Zona", en = "Server Anti-Cheat & Zone Detection" }, 1)

    local secStatusCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.24,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(secStatusCard, 9)
    Utils.AddStroke(secStatusCard, Theme.BorderSubtle, 1, 0.3)

    local acBridgeLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = SecurityHub.ServerConnected
            and "🟢 Server AntiCheatFeed: TERHUBUNG"
            or "🟡 Server AntiCheatFeed: MODE AUDIT LOKAL",
        TextColor3 = SecurityHub.ServerConnected and Theme.Success or Theme.Warning,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, secStatusCard)

    local zoneStatusLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 29),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "📍 Zona Saat Ini: " .. SecurityHub.CurrentZoneName,
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, secStatusCard)
    Utils.RegisterText(zoneStatusLbl, false, Theme.TextSecondary)

    SecurityHub.OnZoneChanged = function(newZone)
        if zoneStatusLbl and zoneStatusLbl.Parent then
            zoneStatusLbl.Text = "📍 Zona Saat Ini: " .. tostring(newZone)
        end
    end

    Components.AddToggle(
        page,
        { id = "Pemindai Zona Otomatis (Safe / PvP)", en = "Automatic Zone Scanner (Safe / PvP)" },
        { id = "Mendeteksi area aman, zona pertarungan, dan checkpoint secara real-time", en = "Detect safe zones, combat arenas, and checkpoints in real time" },
        true,
        3,
        function(on)
            SecurityHub.ZoneScannerEnabled = on
        end
    )

    Components.AddToggle(
        page,
        { id = "Tangkap Log Error & Peringatan Live", en = "Live Console Error & Warning Capture" },
        { id = "Merekam pesan error/warning script agar mudah dianalisis tanpa membuka F9", en = "Capture runtime script errors and warnings without opening F9 console" },
        true,
        4,
        function(on)
            SecurityHub.LogCaptureEnabled = on
        end
    )

    Components.AddSectionHeader(page, { id = "Aksi Moderator Server & Audit Integritas", en = "Server Moderator Actions & Integrity Audit" }, 5)

    Components.AddButton(
        page,
        { id = "Hubungkan Ulang Channel Anti-Cheat", en = "Reconnect Anti-Cheat Channel" },
        { id = "Memindai ulang ReplicatedStorage.SecurityRemotes pada server aktif", en = "Rescan ReplicatedStorage.SecurityRemotes on current server" },
        { id = "Hubungkan", en = "Connect" },
        6,
        function()
            local ok = SecurityHub.ConnectServerChannel()
            acBridgeLbl.Text = ok
                and "🟢 Server AntiCheatFeed: TERHUBUNG"
                or "🟡 Server AntiCheatFeed: MODE AUDIT LOKAL"
            acBridgeLbl.TextColor3 = ok and Theme.Success or Theme.Warning
            Utils.Notify(
                "Security Hub",
                ok and LocaleEngine.Text("Terhubung ke server AntiCheatFeed!", "Connected to AntiCheatFeed!")
                    or LocaleEngine.Text("Map ini tidak menggunakan SecurityRemotes (Mode Lokal aktif).", "No SecurityRemotes in this map (Local Audit active)."),
                ok and Theme.Success or Theme.Warning
            )
        end
    )

    Components.AddButton(
        page,
        { id = "Salin Laporan Diagnostik & Log Error", en = "Copy Diagnostics & Error Logs" },
        { id = "Menyalin ringkasan error runtime, status zona, dan telemetri Anti-Bug ke clipboard", en = "Copy captured runtime logs, zone status, and Anti-Bug metrics to clipboard" },
        { id = "Salin Log", en = "Copy Logs" },
        7,
        function()
            local lines = {
                "=== BimSakSin Hub v3.0 Diagnostics ===",
                "PlaceId: " .. tostring(game.PlaceId) .. " | JobId: " .. tostring(game.JobId),
                "Current Zone: " .. tostring(SecurityHub.CurrentZoneName),
                "Anti-Bug Repairs: " .. tostring(Protection.AutoRepairs) .. " | Errors Caught: " .. tostring(Protection.ErrorsCaught),
                "Captured Logs (" .. tostring(#SecurityHub.ConsoleLogs) .. "):",
            }
            for i = 1, math.min(12, #SecurityHub.ConsoleLogs) do
                local l = SecurityHub.ConsoleLogs[i]
                table.insert(lines, string.format("[%s][%s] %s", l.Time, l.Level, l.Text))
            end
            local report = table.concat(lines, "\n")
            if Utils.CopyText(report) then
                Utils.Notify("Diagnostik Tersalin ✓", LocaleEngine.Text("Laporan log berhasil disalin ke clipboard.", "Diagnostic report copied to clipboard."), Theme.Success)
            else
                Utils.Notify("Diagnostik", LocaleEngine.Text("Clipboard tidak tersedia di executor.", "Clipboard unavailable."), Theme.Warning)
            end
        end
    )

    Components.AddSectionHeader(page, { id = "Log Pelanggaran & Konsol Terbaru", en = "Recent Violations & Console Feed" }, 8)

    local logFeedBox = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        LayoutOrder = 9,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(logFeedBox, 8)
    Utils.AddStroke(logFeedBox, Theme.BorderSubtle, 1, 0.3)

    local logFeedText = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, -12),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "Belum ada log pelanggaran atau error tercatat.",
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 15,
    }, logFeedBox)

    local function refreshSecurityFeedText()
        if not logFeedText or not logFeedText.Parent then return end
        local lines = {}
        for i = 1, math.min(3, #SecurityHub.ViolationLogs) do
            local v = SecurityHub.ViolationLogs[i]
            table.insert(lines, string.format("[AC] %s | %s (%s)", tostring(v.PlayerName), tostring(v.Rule), tostring(v.Detail)))
        end
        for i = 1, math.min(4, #SecurityHub.ConsoleLogs) do
            local c = SecurityHub.ConsoleLogs[i]
            table.insert(lines, string.format("[%s][%s] %s", c.Time, c.Level, string.sub(c.Text, 1, 80)))
        end
        logFeedText.Text = (#lines > 0) and table.concat(lines, "\n") or "Belum ada log pelanggaran atau error tercatat."
    end

    SecurityHub.OnViolationAdded = refreshSecurityFeedText
    SecurityHub.OnConsoleLogAdded = refreshSecurityFeedText
end

-- ============================================================================
-- TAB 12: PENGATURAN (REGION DEVICE, CONFIG JSON, ANTI-BUG & TAMPILAN)
-- ============================================================================
do
    local page = Components.CreateTab("Pengaturan", { id = "Pengaturan", en = "Settings" }, "⚙", 12)
    Components.AddSectionHeader(page, { id = "Bahasa & Deteksi Region Perangkat", en = "Language & Device Region Detection" }, 1)

    local regionInfoBox = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = "  🌍 Region Terdeteksi: " .. LocaleEngine.RegionDisplay,
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(regionInfoBox, 7)
    Utils.RegisterAccent(regionInfoBox, "TextColor3")

    LocaleEngine.Bind(function()
        if regionInfoBox and regionInfoBox.Parent then
            regionInfoBox.Text = LocaleEngine.Text(
                "  🌍 Region Terdeteksi: " .. LocaleEngine.RegionDisplay,
                "  🌍 Detected Region: " .. LocaleEngine.RegionDisplay
            )
        end
    end)

    Components.AddChipSelector(page, { id = "Mode Bahasa Antarmuka", en = "Interface Language Mode" }, {
        { Label = { id = "Otomatis Region", en = "Auto Region" }, Value = "Auto" },
        { Label = "Bahasa Indonesia", Value = "id" },
        { Label = "English (Global)", Value = "en" },
    }, "Auto", 3, function(val)
        LocaleEngine.SetMode(val)
        Utils.Notify(
            LocaleEngine.Text("Bahasa Diperbarui", "Language Updated"),
            LocaleEngine.Text("Bahasa aktif: Bahasa Indonesia", "Active language: English"),
            Theme.Success
        )
    end)

    Components.AddSectionHeader(page, { id = "Konfigurasi JSON Persisten (Simpan & Muat)", en = "Persistent JSON Config (Save & Load)" }, 4)

    Components.AddButton(
        page,
        { id = "Simpan Konfigurasi ke JSON", en = "Save Configuration to JSON" },
        { id = "Menyimpan kecepatan, FOV, bahasa, dan filter ke file lokal", en = "Save speed, FOV, language, and filters to local JSON file" },
        { id = "Simpan JSON", en = "Save JSON" },
        5,
        function()
            ConfigManager.Save()
        end
    )

    Components.AddButton(
        page,
        { id = "Muat Konfigurasi dari JSON", en = "Load Configuration from JSON" },
        { id = "Memulihkan pengaturan tersimpan dari BimSakSinHub_v3_Config.json", en = "Restore saved settings from BimSakSinHub_v3_Config.json" },
        { id = "Muat JSON", en = "Load JSON" },
        6,
        function()
            ConfigManager.Load(false)
        end
    )

    Components.AddSectionHeader(page, { id = "Sistem Anti-Bug & Perlindungan Sesi", en = "Anti-Bug & Session Protection" }, 7)

    Components.AddToggle(
        page,
        { id = "Sistem Pemulihan Anti-Bug Otomatis", en = "Anti-Bug Self-Healing Engine" },
        { id = "Menangkap error runtime dan membersihkan fisika yang tersangkut secara otomatis", en = "Catch runtime errors and auto-repair stuck physics states" },
        true,
        8,
        function(on)
            Protection.AntiBugEnabled = on
        end
    )

    Components.AddToggle(
        page,
        { id = "Perlindungan Anti-AFK (Anti-Kick 20 Menit)", en = "Anti-AFK Idle Protection" },
        { id = "Mencegah akun terputus otomatis akibat diam terlalu lama di server", en = "Prevent 20-minute idle disconnection" },
        true,
        9,
        function(on)
            Protection.AntiAFKEnabled = on
        end
    )

    Components.AddSectionHeader(page, { id = "Kustomisasi Tema, Huruf & Latar Menu", en = "Menu Font, Text & Backdrop Customization" }, 10)

    Components.AddChipSelector(page, { id = "Gaya Huruf (Font) Seluruh Menu", en = "Menu Font Style" }, {
        { Label = "Gotham Semi", Value = Enum.Font.GothamSemibold, Font = Enum.Font.GothamSemibold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Merriweather", Value = Enum.Font.Merriweather, Font = Enum.Font.Merriweather },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
    }, Enum.Font.GothamSemibold, 11, function(val)
        Theme.FontFamily = val
        Theme.FontBold = val
        Utils.ApplyMenuFontAndColors()
    end)

    Components.AddChipSelector(page, { id = "Warna Teks Menu", en = "Menu Font Color" }, {
        { Label = { id = "Kontras Otomatis", en = "Auto Contrast" }, Value = "Auto", Color = Color3.fromRGB(255, 195, 110) },
        { Label = { id = "Putih Gading", en = "Ivory White" }, Value = Color3.fromRGB(255, 246, 235), Color = Color3.fromRGB(255, 246, 235) },
        { Label = { id = "Emas Labu", en = "Pumpkin Gold" }, Value = Color3.fromRGB(255, 155, 55), Color = Color3.fromRGB(255, 155, 55) },
        { Label = { id = "Hijau Mint", en = "Mint Green" }, Value = Color3.fromRGB(115, 250, 175), Color = Color3.fromRGB(115, 250, 175) },
        { Label = { id = "Sian Es", en = "Ice Cyan" }, Value = Color3.fromRGB(110, 230, 255), Color = Color3.fromRGB(110, 230, 255) },
        { Label = { id = "Hitam Pekat", en = "Deep Black" }, Value = Color3.fromRGB(20, 16, 28), Color = Color3.fromRGB(20, 16, 28) },
    }, "Auto", 12, function(val)
        Theme.FontColorMode = val
        Utils.ApplyMenuFontAndColors()
    end)

    Components.AddToggle(
        page,
        { id = "Kotak Latar Teks Menu", en = "Enable Text Backdrop Box" },
        { id = "Memberikan latar kontras di belakang teks agar lebih mudah dibaca", en = "Add contrast backdrop behind text labels" },
        false,
        13,
        function(on)
            Theme.FontBgEnabled = on
            Utils.ApplyMenuFontAndColors()
        end
    )

    Components.AddChipSelector(page, { id = "Warna Latar Teks Menu", en = "Menu Text Backdrop Color" }, {
        { Label = { id = "Ungu Gelap", en = "Dark Purple" }, Value = Color3.fromRGB(18, 14, 26), Color = Color3.fromRGB(18, 14, 26) },
        { Label = { id = "Hitam Arang", en = "Charcoal Black" }, Value = Color3.fromRGB(12, 12, 16), Color = Color3.fromRGB(12, 12, 16) },
        { Label = { id = "Coklat Labu", en = "Pumpkin Brown" }, Value = Color3.fromRGB(48, 22, 12), Color = Color3.fromRGB(48, 22, 12) },
        { Label = { id = "Merah Gelap", en = "Crimson Dark" }, Value = Color3.fromRGB(48, 14, 22), Color = Color3.fromRGB(48, 14, 22) },
        { Label = { id = "Putih Gading", en = "Ivory White" }, Value = Color3.fromRGB(242, 236, 228), Color = Color3.fromRGB(242, 236, 228) },
        { Label = { id = "Biru Malam", en = "Midnight Blue" }, Value = Color3.fromRGB(16, 26, 46), Color = Color3.fromRGB(16, 26, 46) },
    }, Color3.fromRGB(18, 14, 26), 14, function(val)
        Theme.FontBgColor = val
        Utils.ApplyMenuFontAndColors()
    end)

    Components.AddChipSelector(page, { id = "Tema Aksen Panel Utama", en = "Main Accent Theme" }, {
        { Label = { id = "Emas Labu", en = "Pumpkin Gold" }, Value = "Pumpkin", Color = Color3.fromRGB(255, 118, 26) },
        { Label = { id = "Merah Darah", en = "Blood Crimson" }, Value = "Crimson", Color = Color3.fromRGB(225, 48, 78) },
        { Label = { id = "Ungu Spektral", en = "Spectral Violet" }, Value = "Violet", Color = Color3.fromRGB(155, 89, 245) },
        { Label = { id = "Hijau Racun", en = "Toxic Emerald" }, Value = "Emerald", Color = Color3.fromRGB(46, 213, 115) },
        { Label = { id = "Sian Hantu", en = "Phantom Cyan" }, Value = "Cyan", Color = Color3.fromRGB(24, 220, 255) },
        { Label = { id = "Emas Kerajaan", en = "Royal Gold" }, Value = "Gold", Color = Color3.fromRGB(255, 196, 54) },
    }, "Pumpkin", 15, function(val)
        if val == "Pumpkin" then
            Utils.SetAccentColor(Color3.fromRGB(255, 118, 26), Color3.fromRGB(184, 72, 12))
        elseif val == "Crimson" then
            Utils.SetAccentColor(Color3.fromRGB(225, 48, 78), Color3.fromRGB(155, 25, 48))
        elseif val == "Violet" then
            Utils.SetAccentColor(Color3.fromRGB(155, 89, 245), Color3.fromRGB(102, 52, 175))
        elseif val == "Emerald" then
            Utils.SetAccentColor(Color3.fromRGB(46, 213, 115), Color3.fromRGB(24, 148, 76))
        elseif val == "Cyan" then
            Utils.SetAccentColor(Color3.fromRGB(24, 220, 255), Color3.fromRGB(14, 145, 175))
        elseif val == "Gold" then
            Utils.SetAccentColor(Color3.fromRGB(255, 196, 54), Color3.fromRGB(184, 134, 22))
        end
    end)

    Components.AddSectionHeader(page, { id = "Kontrol Jendela & Bongkar Script", en = "Window & Unload Controls" }, 16)

    Components.AddButton(
        page,
        { id = "Tutup Menu Utama", en = "Hide Main Window" },
        { id = "Sembunyikan menu; klik ikon tengkorak mahkota emas di layar untuk membuka kembali", en = "Hide panel; tap the floating 3D royal skull icon to reopen" },
        { id = "Sembunyikan", en = "Hide UI" },
        17,
        function()
            App.IsOpen = false
            UI.MainFrame.Visible = false
        end
    )

    Components.AddButton(
        page,
        { id = "Hentikan & Bongkar Script (Unload)", en = "Unload Script Completely" },
        { id = "Mematikan seluruh fitur, memulihkan karakter, dan menghapus antarmuka", en = "Disconnect all loops, restore character defaults, and remove UI" },
        { id = "Bongkar", en = "Unload" },
        18,
        function()
            if type(getgenv) == "function" and type(getgenv().BSS_UnloadOld) == "function" then
                getgenv().BSS_UnloadOld()
            end
        end
    )
end

-- ============================================================================
-- 16. COMMAND PALETTE CEPAT (F2 SHORTCUT — PENCARIAN PERINTAH KILAT)
-- ============================================================================
do
    CommandRegistry = {
        { Name = "Buka Tab Keamanan & Anti-Cheat", Desc = "Monitor server AC, zona & log diagnostik", Run = function() Components.SwitchTab("KeamananAC") end },
        { Name = "Toggle Terbang Halus (Fly)", Desc = "Aktifkan atau matikan mode terbang", Run = function()
            State.FlyEnabled = not State.FlyEnabled
            if not State.FlyEnabled then Physics.CleanupFly() end
            Utils.Notify("Command Palette", "Fly: " .. tostring(State.FlyEnabled), Theme.Accent)
        end },
        { Name = "Toggle Tembus Objek (NoClip)", Desc = "Aktifkan atau matikan tabrakan dinding", Run = function()
            State.NoclipEnabled = not State.NoclipEnabled
            if not State.NoclipEnabled then Physics.RestoreNoclip() end
            Utils.Notify("Command Palette", "NoClip: " .. tostring(State.NoclipEnabled), Theme.Accent)
        end },
        { Name = "Toggle ESP Pemain", Desc = "Tampilkan atau sembunyikan ESP pemain", Run = function()
            ESP.Enabled = not ESP.Enabled
            if not ESP.Enabled then ESP.ClearAll() end
            Utils.Notify("Command Palette", "Player ESP: " .. tostring(ESP.Enabled), Theme.Accent)
        end },
        { Name = "Toggle ESP Barang & Loot", Desc = "Deteksi item & loot di seluruh map", Run = function()
            ItemESP.Enabled = not ItemESP.Enabled
            if not ItemESP.Enabled then ItemESP.ClearAll() else ItemESP.ScanAndRender() end
            Utils.Notify("Command Palette", "Item ESP: " .. tostring(ItemESP.Enabled), Theme.Accent)
        end },
        { Name = "Simpan Konfigurasi JSON", Desc = "Simpan pengaturan saat ini ke file JSON", Run = function() ConfigManager.Save() end },
        { Name = "Muat Konfigurasi JSON", Desc = "Pulihkan pengaturan dari file JSON", Run = function() ConfigManager.Load(false) end },
        { Name = "Segarkan Karakter (Respawn)", Desc = "Muat ulang karakter lokal jika tersangkut", Run = function()
            local _, hum = Utils.GetCharacter()
            if hum then hum.Health = 0 end
        end },
    }

    local paletteOverlay = Utils.Create("Frame", {
        Name = "BSS_CommandPalette",
        Size = UDim2.new(0, 380, 0, 250),
        Position = UDim2.new(0.5, -190, 0.25, 0),
        BackgroundColor3 = Theme.BgPrimary,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 70,
    }, UI.ScreenGui)
    Utils.AddCorner(paletteOverlay, 12)
    local pStroke = Utils.AddStroke(paletteOverlay, Theme.Accent, 1.5, 0.15)
    Utils.RegisterAccent(pStroke, "Color")

    local searchInput = Utils.Create("TextBox", {
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Ketik perintah cepat (ESC / F2 untuk tutup)...", "Type quick command (ESC / F2 to close)..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 71,
    }, paletteOverlay)
    Utils.AddCorner(searchInput, 8)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, searchInput)

    local resultsScroll = Utils.Create("ScrollingFrame", {
        Size = UDim2.new(1, -24, 1, -60),
        Position = UDim2.new(0, 12, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 71,
    }, paletteOverlay)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, resultsScroll)

    local function renderCommandResults(queryText)
        for _, child in ipairs(resultsScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local q = string.lower(queryText or "")
        local order = 0
        for _, cmd in ipairs(CommandRegistry) do
            if q == "" or string.find(string.lower(cmd.Name), q, 1, true) or string.find(string.lower(cmd.Desc), q, 1, true) then
                order = order + 1
                local itemBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.2,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = order,
                    ZIndex = 72,
                }, resultsScroll)
                Utils.AddCorner(itemBtn, 7)

                Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -16, 0, 17),
                    Position = UDim2.new(0, 8, 0, 3),
                    BackgroundTransparency = 1,
                    Font = Theme.FontBold,
                    Text = cmd.Name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 73,
                }, itemBtn)

                Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -16, 0, 14),
                    Position = UDim2.new(0, 8, 0, 20),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = cmd.Desc,
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 73,
                }, itemBtn)

                itemBtn.MouseButton1Click:Connect(function()
                    paletteOverlay.Visible = false
                    SafeEngine.Run("CommandPalette", cmd.Run)
                end)
            end
        end
    end

    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        renderCommandResults(searchInput.Text)
    end)

    Utils.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.F2 then
            if UserInputService:GetFocusedTextBox() and not paletteOverlay.Visible then
                return
            end
            paletteOverlay.Visible = not paletteOverlay.Visible
            if paletteOverlay.Visible then
                searchInput.Text = ""
                renderCommandResults("")
                searchInput:CaptureFocus()
            end
        elseif input.KeyCode == Enum.KeyCode.Escape and paletteOverlay.Visible then
            paletteOverlay.Visible = false
        end
    end))

    UI.CommandPalette = paletteOverlay
end

-- ============================================================================
-- 17. WINDOW CONTROLS (Responsive Viewport Clamp, Corner Resize & Toggle)
-- ============================================================================
do
    local function getViewportSize()
        local sz = UI.ScreenGui and UI.ScreenGui.AbsoluteSize or Vector2.zero
        if sz.X > 0 and sz.Y > 0 then
            return sz
        end
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1280, 720)
    end

    local function applyResponsiveLayout(width, height)
        local sidebarW = (width < 500) and math.clamp(math.floor(width * 0.30), 116, 166) or 166
        UI.Sidebar.Size = UDim2.new(0, sidebarW, 1, -54)
        UI.ContentContainer.Size = UDim2.new(1, -sidebarW, 1, -54)
        UI.ContentContainer.Position = UDim2.new(0, sidebarW, 0, 54)

        local isCompact = (width < 430)
        UI.TitleLabel.TextSize = isCompact and 13 or 16
        UI.SubLabel.TextSize = isCompact and 10 or 11
    end

    local function clampWindowToViewport(recenter)
        if not UI.MainFrame or not UI.MainFrame.Parent then return end
        local vp = getViewportSize()
        local maxW = math.max(320, vp.X - 24)
        local maxH = math.max(240, vp.Y - 24)
        local targetW = math.clamp(App.ExpandedWidth, 320, maxW)
        local targetH = math.clamp(App.ExpandedHeight, 240, maxH)
        App.ExpandedWidth = targetW
        App.ExpandedHeight = targetH

        applyResponsiveLayout(targetW, targetH)

        if not App.IsMinimized then
            UI.MainFrame.Size = UDim2.new(0, targetW, 0, targetH)
            if recenter then
                UI.MainFrame.Position = UDim2.new(0.5, -math.floor(targetW / 2), 0.5, -math.floor(targetH / 2))
            else
                local absPos = UI.MainFrame.AbsolutePosition
                local clampedX = math.clamp(absPos.X, 12, math.max(12, vp.X - targetW - 12))
                local clampedY = math.clamp(absPos.Y, 12, math.max(12, vp.Y - targetH - 12))
                UI.MainFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
            end
        end
    end

    UI.FloatingToggle.MouseButton1Click:Connect(function()
        App.IsOpen = not App.IsOpen
        UI.MainFrame.Visible = App.IsOpen
        if App.IsOpen then
            clampWindowToViewport(false)
        end
    end)

    UI.CloseBtn.MouseButton1Click:Connect(function()
        App.IsOpen = false
        UI.MainFrame.Visible = false
    end)

    UI.MinimizeBtn.MouseButton1Click:Connect(function()
        App.IsMinimized = not App.IsMinimized
        if App.IsMinimized then
            UI.Sidebar.Visible = false
            UI.ContentContainer.Visible = false
            UI.ResizeHandle.Visible = false
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, math.min(App.ExpandedWidth, 340), 0, 54)
            })
        else
            UI.Sidebar.Visible = true
            UI.ContentContainer.Visible = true
            UI.ResizeHandle.Visible = true
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, App.ExpandedWidth, 0, App.ExpandedHeight)
            })
        end
    end)

    local resizing = false
    local activeResizeInput = nil
    local resizeStart = nil
    local startSize = nil

    Utils.Track(UI.ResizeHandle.InputBegan:Connect(function(input)
        if not App.IsMinimized and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            resizing = true
            activeResizeInput = input
            resizeStart = input.Position
            startSize = UI.MainFrame.Size
        end
    end))

    Utils.Track(UserInputService.InputChanged:Connect(function(input)
        if not resizing or not activeResizeInput or not resizeStart or not startSize then
            return
        end
        local isMatchingMouse = (activeResizeInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)
        local isMatchingTouch = (input == activeResizeInput)

        if isMatchingMouse or isMatchingTouch then
            local vp = getViewportSize()
            local delta = input.Position - resizeStart
            local newW = math.clamp(startSize.X.Offset + delta.X, 340, math.max(340, vp.X - 24))
            local newH = math.clamp(startSize.Y.Offset + delta.Y, 260, math.max(260, vp.Y - 24))
            App.ExpandedWidth = newW
            App.ExpandedHeight = newH
            UI.MainFrame.Size = UDim2.new(0, newW, 0, newH)
            applyResponsiveLayout(newW, newH)
        end
    end))

    Utils.Track(UserInputService.InputEnded:Connect(function(input)
        if resizing and (input == activeResizeInput or (activeResizeInput and activeResizeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            resizing = false
            activeResizeInput = nil
        end
    end))

    Utils.Track(UI.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        clampWindowToViewport(false)
    end))

    clampWindowToViewport(true)
end

-- ============================================================================
-- 18. CENTRAL HEARTBEAT / RENDERSTEPPED RUNTIME ENGINE
-- ============================================================================
do
    local frameCounter = 0
    local lastTick = os.clock()
    local slowScanTimer = 0
    local espTimer = 0
    local zoneScanTimer = 0

    Utils.Track(UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJumpEnabled then
            local _, hum = Utils.GetCharacter()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end))

    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        ESP.RemovePlayer(plr)
    end))

    Utils.Track(RunService.RenderStepped:Connect(function(dt)
        SafeEngine.Run("RenderSteppedLoop", function()
            local now = os.clock()
            local pulse = (math.sin(now * 3.2) + 1) * 0.5
            local wave = math.sin(now * 2.4) * 2.5

            for _, pk in ipairs(UI.Pumpkins) do
                if pk.Holder and pk.Holder.Parent then
                    if not pk.IsMenuPumpkin then
                        pk.Holder.Position = UDim2.new(
                            pk.BasePos.X.Scale,
                            pk.BasePos.X.Offset,
                            pk.BasePos.Y.Scale,
                            pk.BasePos.Y.Offset + wave
                        )
                    end
                    pk.Aura.BackgroundTransparency = (pk.IsHero and 0.62 or 0.72) + (pulse * 0.14)
                    local eyeCol = Color3.fromRGB(255, math.floor(195 + pulse * 60), math.floor(60 + pulse * 60))
                    pk.EyeLeft.BackgroundColor3 = eyeCol
                    pk.EyeRight.BackgroundColor3 = eyeCol
                    pk.Mouth.BackgroundColor3 = eyeCol
                end
            end

            if Combat.AimbotEnabled then
                local cam = workspace.CurrentCamera
                local _, isRanged = Combat.GetEquippedRangedWeapon()
                local shouldAim = false

                if Combat.AimbotMode == "Always" then
                    shouldAim = true
                elseif Combat.AimbotMode == "HoldRMB" then
                    shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    local char = Utils.GetCharacter(LocalPlayer)
                    local hasTool = char and (char:FindFirstChildOfClass("Tool") ~= nil)
                    shouldAim = hasTool or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                end

                if shouldAim and cam then
                    local targetPlr, targetPart = Combat.FindBestTarget()
                    Combat.CurrentTarget = targetPlr
                    if targetPlr and targetPart then
                        local desiredCF = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
                        local alpha = math.clamp(Combat.Smoothness, 0.08, 1)
                        cam.CFrame = (alpha >= 0.98) and desiredCF or cam.CFrame:Lerp(desiredCF, alpha)

                        if Combat.RGBLaserEnabled and isRanged then
                            local tool = Combat.GetEquippedRangedWeapon()
                            local originPart = tool and (tool:FindFirstChild("Muzzle", true) or tool:FindFirstChild("Barrel", true) or tool:FindFirstChild("Handle"))
                            if originPart and originPart:IsA("BasePart") then
                                Combat.UpdateLaser(originPart.Position, targetPart.Position)
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

            if State.FullbrightEnabled then
                Lighting.Brightness = 2.2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
            end
            if State.NoFogEnabled then
                Lighting.FogEnd = 100000
                Lighting.FogStart = 0
                for _, child in ipairs(Lighting:GetChildren()) do
                    if child:IsA("Atmosphere") then
                        child.Density = 0
                    end
                end
            end

            espTimer = espTimer + (dt or 0.016)
            if espTimer >= 0.05 then
                espTimer = 0
                ESP.UpdateAll()
            end

            frameCounter = frameCounter + 1
            if (now - lastTick) >= 0.5 then
                local fps = math.floor((frameCounter / (now - lastTick)) + 0.5)
                frameCounter = 0
                lastTick = now

                if UI.TelemetryLabels.FPS then
                    UI.TelemetryLabels.FPS.Text = tostring(fps) .. " FPS"
                end

                local pingMs = 0
                pcall(function()
                    pingMs = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                end)
                if UI.TelemetryLabels.Ping then
                    UI.TelemetryLabels.Ping.Text = tostring(pingMs) .. " ms"
                end

                local memMb = 0
                pcall(function()
                    memMb = math.floor(Stats:GetTotalMemoryUsageMb() + 0.5)
                end)
                if UI.TelemetryLabels.Memory then
                    UI.TelemetryLabels.Memory.Text = tostring(memMb) .. " MB"
                end

                if UI.TelemetryLabels.Players then
                    UI.TelemetryLabels.Players.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers)
                end
            end
        end)
    end))

    Utils.Track(RunService.Heartbeat:Connect(function(dt)
        SafeEngine.Run("HeartbeatLoop", function()
            local char, hum, root = Utils.GetCharacter()

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

            if State.FlyEnabled then
                Physics.StepSmoothFly(dt)
            end

            if State.NoclipEnabled and char then
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

            if Carry.Enabled then
                Carry.Step()
            end

            if Combat.AutoParryEnabled then
                Combat.StepAutoParry()
            end

            if Combat.MeleeImmunity then
                Protection.StepMeleeImmunity()
            end

            if Combat.HungerThirstGuard then
                Protection.StepHungerThirstGuard()
            end

            if root and UI.TelemetryLabels.Coords and UI.Pages["Teleportasi"] and UI.Pages["Teleportasi"].Visible then
                local p = root.Position
                UI.TelemetryLabels.Coords.Text = string.format("XYZ: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
            end

            zoneScanTimer = zoneScanTimer + (dt or 0.016)
            if zoneScanTimer >= 0.6 then
                zoneScanTimer = 0
                if SecurityHub.ZoneScannerEnabled then
                    SecurityHub.ScanCurrentZone()
                end
            end

            slowScanTimer = slowScanTimer + (dt or 0.016)
            if slowScanTimer >= 0.45 then
                slowScanTimer = 0
                if ItemESP.Enabled then
                    ItemESP.ScanAndRender()
                end
                if GeneratorESP.Enabled then
                    GeneratorESP.ScanAndRender()
                end
            end
        end)
    end))
end


-- ============================================================================
-- 18A. FEATURE API REGISTRATION & LIVE MODULE SYNCHRONIZATION
-- ============================================================================
do
    local function requireAliveCharacter()
        local char, hum, root = Utils.GetCharacter(LocalPlayer)
        if not char or not hum or not root or hum.Health <= 0 then
            return false, LocaleEngine.Text("Karakter belum siap atau sedang respawn.", "Character is not ready or respawning.")
        end
        return true
    end

    -- Tab 3: Radar ESP APIs
    FeatureAPI.Register("PlayerESP", {
        Category = "RadarESP",
        OnEnable = function()
            ESP.Enabled = true
            ESP.UpdateAll()
        end,
        OnDisable = function()
            ESP.Enabled = false
            ESP.ClearAll()
        end,
    })

    FeatureAPI.Register("ItemESP", {
        Category = "RadarESP",
        OnEnable = function()
            ItemESP.Enabled = true
            ItemESP.ScanAndRender()
        end,
        OnDisable = function()
            ItemESP.Enabled = false
            ItemESP.ClearAll()
        end,
    })

    FeatureAPI.Register("GeneratorESP", {
        Category = "RadarESP",
        OnEnable = function()
            GeneratorESP.Enabled = true
            GeneratorESP.ScanAndRender()
        end,
        OnDisable = function()
            GeneratorESP.Enabled = false
            GeneratorESP.ClearAll()
        end,
    })

    -- Tab 4: Combat & Survival APIs
    FeatureAPI.Register("Aimbot", {
        Category = "Combat",
        Validate = requireAliveCharacter,
        OnEnable = function()
            Combat.AimbotEnabled = true
            if Combat.FOVCircle then
                Combat.FOVCircle.Visible = Combat.ShowFOVCircle
            end
        end,
        OnDisable = function()
            Combat.AimbotEnabled = false
            Combat.CurrentTarget = nil
            Combat.HideLaser()
            if Combat.FOVCircle then
                Combat.FOVCircle.Visible = false
            end
        end,
    })

    FeatureAPI.Register("AutoParry", {
        Category = "Combat",
        Validate = requireAliveCharacter,
        OnEnable = function()
            Combat.AutoParryEnabled = true
            Combat.ParryRemoteScanned = false
            Combat.ScanParryRemotes()
            FeatureAPI.ScanGameRemotes(true)
        end,
        OnDisable = function()
            Combat.AutoParryEnabled = false
            Combat.CleanupParryVisuals()
        end,
        OnRespawn = function()
            Combat.ParryRemoteScanned = false
            Combat.ScanParryRemotes()
        end,
    })

    FeatureAPI.Register("MeleeImmunity", {
        Category = "Combat",
        Validate = requireAliveCharacter,
        OnEnable = function()
            Combat.MeleeImmunity = true
        end,
        OnDisable = function()
            Combat.MeleeImmunity = false
            Protection.RestoreEnemyHitboxes()
        end,
    })

    FeatureAPI.Register("HungerThirstGuard", {
        Category = "Combat",
        OnEnable = function()
            Combat.HungerThirstGuard = true
            Protection.BindSurvivalContainer(LocalPlayer)
            if LocalPlayer.Character then
                Protection.BindSurvivalContainer(LocalPlayer.Character)
            end
        end,
        OnDisable = function()
            Combat.HungerThirstGuard = false
        end,
    })

    -- Tab 5: Movement & Physics APIs
    FeatureAPI.Register("SmoothFly", {
        Category = "Movement",
        Validate = requireAliveCharacter,
        OnEnable = function()
            local _, hum = Utils.GetCharacter(LocalPlayer)
            if hum and hum.Sit then hum.Sit = false end
            State.FlyEnabled = true
        end,
        OnDisable = function()
            State.FlyEnabled = false
            Physics.CleanupFly()
        end,
    })

    FeatureAPI.Register("NoClip", {
        Category = "Movement",
        Validate = requireAliveCharacter,
        OnEnable = function()
            State.NoclipEnabled = true
        end,
        OnDisable = function()
            State.NoclipEnabled = false
            Physics.RestoreNoclip()
        end,
    })

    FeatureAPI.Register("InfiniteJump", {
        Category = "Movement",
        Validate = requireAliveCharacter,
        OnEnable = function()
            State.InfiniteJumpEnabled = true
        end,
        OnDisable = function()
            State.InfiniteJumpEnabled = false
        end,
    })

    -- Tab 7 & 8: Carry & Emote APIs
    FeatureAPI.Register("CarryPlayer", {
        Category = "Social",
        Validate = function()
            local ok, reason = requireAliveCharacter()
            if not ok then return false, reason end
            if not Carry.TargetPlayer or not Carry.TargetPlayer.Parent then
                return false, LocaleEngine.Text("Pilih target pemain terlebih dahulu.", "Select a target player first.")
            end
            return true
        end,
        OnEnable = function()
            FeatureAPI.ScanGameRemotes(false)
            Carry.Start()
        end,
        OnDisable = function()
            Carry.Stop()
        end,
    })

    FeatureAPI.Register("DanceEmote", {
        Category = "Social",
        Validate = requireAliveCharacter,
        OnEnable = function()
            Emotes.Playing = true
        end,
        OnDisable = function()
            Emotes.Stop()
        end,
    })

    -- Tab 9: Visual APIs
    FeatureAPI.Register("Fullbright", {
        Category = "Visual",
        OnEnable = function()
            State.FullbrightEnabled = true
        end,
        OnDisable = function()
            State.FullbrightEnabled = false
            Lighting.Brightness = State.OriginalLighting.Brightness
            Lighting.ClockTime = State.OriginalLighting.ClockTime
            Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
            Lighting.Ambient = State.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        end,
    })

    FeatureAPI.Register("NoFog", {
        Category = "Visual",
        OnEnable = function()
            State.NoFogEnabled = true
        end,
        OnDisable = function()
            State.NoFogEnabled = false
            Lighting.FogEnd = State.OriginalLighting.FogEnd
            Lighting.FogStart = State.OriginalLighting.FogStart
            if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance then
                State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
            end
        end,
    })

    -- Tab 11 & 12: Security & Protection APIs
    FeatureAPI.Register("ZoneScanner", {
        Category = "Security",
        OnEnable = function()
            SecurityHub.ZoneScannerEnabled = true
            SecurityHub.ScanCurrentZone()
        end,
        OnDisable = function()
            SecurityHub.ZoneScannerEnabled = false
        end,
    })

    FeatureAPI.Register("LogCapture", {
        Category = "Security",
        OnEnable = function()
            SecurityHub.LogCaptureEnabled = true
        end,
        OnDisable = function()
            SecurityHub.LogCaptureEnabled = false
        end,
    })

    FeatureAPI.Register("AntiAFK", {
        Category = "Protection",
        OnEnable = function()
            Protection.AntiAFKEnabled = true
        end,
        OnDisable = function()
            Protection.AntiAFKEnabled = false
        end,
    })

    -- Sinkronisasi otomatis status fitur dengan state table eksisting
    Utils.Track(RunService.Heartbeat:Connect(function()
        FeatureAPI.Sync("PlayerESP", ESP.Enabled)
        FeatureAPI.Sync("ItemESP", ItemESP.Enabled)
        FeatureAPI.Sync("GeneratorESP", GeneratorESP.Enabled)
        FeatureAPI.Sync("Aimbot", Combat.AimbotEnabled)
        FeatureAPI.Sync("AutoParry", Combat.AutoParryEnabled)
        FeatureAPI.Sync("MeleeImmunity", Combat.MeleeImmunity)
        FeatureAPI.Sync("HungerThirstGuard", Combat.HungerThirstGuard)
        FeatureAPI.Sync("SmoothFly", State.FlyEnabled)
        FeatureAPI.Sync("NoClip", State.NoclipEnabled)
        FeatureAPI.Sync("InfiniteJump", State.InfiniteJumpEnabled)
        FeatureAPI.Sync("CarryPlayer", Carry.Enabled)
        FeatureAPI.Sync("DanceEmote", Emotes.Playing)
        FeatureAPI.Sync("Fullbright", State.FullbrightEnabled)
        FeatureAPI.Sync("NoFog", State.NoFogEnabled)
        FeatureAPI.Sync("ZoneScanner", SecurityHub.ZoneScannerEnabled)
        FeatureAPI.Sync("LogCapture", SecurityHub.LogCaptureEnabled)
        FeatureAPI.Sync("AntiAFK", Protection.AntiAFKEnabled)
    end))

    FeatureAPI.ScanGameRemotes(true)
end

-- ============================================================================
-- 19. GLOBAL CLEANUP & UNLOAD HANDLER
-- ============================================================================
local function unloadScript()
    State.FlyEnabled = false
    State.NoclipEnabled = false
    State.FullbrightEnabled = false
    State.NoFogEnabled = false
    ESP.Enabled = false
    ItemESP.Enabled = false
    GeneratorESP.Enabled = false
    Combat.AimbotEnabled = false
    Combat.MeleeImmunity = false
    Combat.HungerThirstGuard = false
    Combat.AutoParryEnabled = false
    Carry.Stop()
    Emotes.Stop()

    Physics.CleanupFly()
    Physics.RestoreNoclip()
    Protection.RestoreEnemyHitboxes()
    ESP.ClearAll()
    ItemESP.ClearAll()
    GeneratorESP.ClearAll()

    Combat.CleanupParryVisuals()
    Carry.CleanupVisuals()

    if Combat.LaserPart then
        pcall(function() Combat.LaserPart:Destroy() end)
        Combat.LaserPart = nil
    end

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    if FeatureAPI then
        table.clear(FeatureAPI.Listeners)
        for _, entry in pairs(FeatureAPI.Registry) do
            entry.Enabled = false
        end
    end

    local _, hum = Utils.GetCharacter()
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
    Lighting.Brightness = State.OriginalLighting.Brightness
    Lighting.ClockTime = State.OriginalLighting.ClockTime
    Lighting.FogEnd = State.OriginalLighting.FogEnd
    Lighting.FogStart = State.OriginalLighting.FogStart
    Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
    Lighting.Ambient = State.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
    if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance then
        State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
    end

    if UI.ScreenGui then
        pcall(function() UI.ScreenGui:Destroy() end)
    end
end

if typeof(getgenv) == "function" then
    getgenv().BSS_UnloadOld = unloadScript
end

-- Muat konfigurasi JSON secara diam-diam jika file sebelumnya pernah disimpan
ConfigManager.Load(true)

-- Buka Tab Informasi (Paling Atas) sebagai tampilan awal
Components.SwitchTab("Informasi")
Utils.Notify(
    App.Name,
    LocaleEngine.Text(
        "Berhasil dimuat! Region: " .. LocaleEngine.RegionDisplay .. " | Tekan F2 untuk Command Palette.",
        "Loaded! Region: " .. LocaleEngine.RegionDisplay .. " | Press F2 for Command Palette."
    ),
    Theme.Success
)
