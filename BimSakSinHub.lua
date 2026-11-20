--[[
================================================================================
  BimSakSin Hub v3.0 + Universal Anti-Ban Framework v3.1 | Edisi Universal
  Creator     : BimSakSin
  Environment : Roblox Luau (Universal / Semua Map & Kompatibel R6/R15)
  Pembaruan   :
    - Integrasi penuh Universal Anti-Ban Framework v3.1 (Anti-Kick __namecall
      & hookfunction, Anti-Remote Rate-Limit & Ban-Remote Guard, Anti-Stats
      Scan, HWID Spoofer, SafeFire API, Webhook Reporter & Mini-Console).
    - Perbaikan seluruh bug & potensi error pada kedua modul (safe LocalPlayer
      autoexec guard, weak-key remote tracker, rawequal Stats index guard,
      Telegram HTML escaping, MeshPart serializer, dan cleanup menyeluruh).
    - Seluruh nama tab, kategori, dan fitur diterjemahkan ke Bahasa Indonesia
      yang rapi & profesional dengan deteksi otomatis Region Perangkat.
    - Struktur tab dan fitur disusun berdasarkan urutan kegunaan:
      1. Informasi (Paling Atas)
      2. Beranda (Telemetri & Utilitas Server)
      3. Radar ESP (Pemain, Barang/Loot, Generator & Auto Generator)
      4. Pertarungan (Bidik Otomatis, Auto Parry & Ketahanan)
      5. Pergerakan (Kecepatan, Lompatan, Terbang & Tembus Objek)
      6. Teleportasi (Koordinat, Titik Simpan & Teleport Pemain)
      7. Gendong (Interaksi Carry & Pilihan Gaya)
      8. Tari & Emote (Animasi Replikasi R6/R15 & ID Kustom)
      9. Visual (Kamera FOV, Pencahayaan Penuh & Hapus Kabut)
     10. Salin Aset (Ekspor Struktur Item/Map & Notifikasi Telegram)
     11. Keamanan & AC (Anti-Ban Framework v3.1, Monitor AC & Diagnostik)
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
                if existingNames[child.Name] or string.sub(child.Name, 1, 10) == "AntiBanUI_" then
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
local CoreGui = game:GetService("CoreGui")

local VirtualUser = nil
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        LocalPlayer = Players.LocalPlayer
    end)
end
local LocalizationService = game:GetService("LocalizationService")

local App = {
    Name = "BimSakSin Hub v3.0",
    Subtitle = "Semoga hari-hari kalian menyenangkan",
    Version = "v3.0 Universal + AntiBan v3.1",
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
-- 1D. UNIVERSAL ANTI-BAN FRAMEWORK v3.1 (HARDENED & INTEGRATED MODULE)
--     Compatible: Synapse X, Krnl, Fluxus, Delta, Arceus X, Hydrogen, Codex,
--                 Wave, Solara, Xeno, AWP, Nihon (Auto-Fallback Capability Check)
-- ============================================================================
local AntiBan = {
    Active = true,
    ConsoleGui = nil,
    OnStatsChanged = nil,
    Config = {
        Version             = "3.1",
        EnableAntiKick      = true,
        EnableAntiRemote    = true,
        EnableAntiDetect    = true,
        EnableAntiStatsScan = true,
        EnableSpoofHWID     = true,
        EnableWebhook       = false,
        WebhookURL          = "",
        WebhookInterval     = 60,
        RemoteRateLimit     = 0.03,
        Debug               = false,
        InteractiveConsole  = false, -- Terintegrasi rapi di Tab Keamanan & AC (bisa dibuka opsional)
    },
    Stats = {
        KicksBlocked = 0,
        RemotesThrottled = 0,
        BanRemotesBlocked = 0,
        StatsScansFiltered = 0,
        SpoofedHWID = "N/A",
    },
}

do
    local function getGlobalEnv()
        if type(getgenv) == "function" then
            local ok, env = pcall(getgenv)
            if ok and type(env) == "table" then
                return env
            end
        end
        return _G
    end

    local function abLog(tag, ...)
        if AntiBan.Config.Debug then
            print(("[AntiBan:%s]"):format(tostring(tag)), ...)
        end
    end

    local function abSafe(fn, ...)
        local ok, res = pcall(fn, ...)
        if not ok then
            abLog("safe", "ERR:", res)
        end
        return ok, res
    end

    local CAP = {
        hookfunction      = (type(hookfunction)      == "function"),
        hookmetamethod    = (type(hookmetamethod)    == "function"),
        getrawmetatable   = (type(getrawmetatable)   == "function"),
        setreadonly       = (type(setreadonly)       == "function"),
        make_writeable    = (type(make_writeable)    == "function"),
        newcclosure       = (type(newcclosure)       == "function"),
        getnamecallmethod = (type(getnamecallmethod) == "function"),
        checkcaller       = (type(checkcaller)       == "function"),
        gethui            = (type(gethui)            == "function"),
        gethwid           = (type(gethwid)           == "function"),
        request           = (type(request) == "function") and "request"
                         or (type(syn) == "table" and type(syn.request) == "function") and "syn"
                         or (type(http_request) == "function") and "http"
                         or (type(http) == "table" and type(http.request) == "function") and "http_tbl" or nil,
    }
    AntiBan.CAP = CAP
    abLog("CAP", "hookmetamethod:", CAP.hookmetamethod, "| hookfunction:", CAP.hookfunction, "| request:", CAP.request)

    local function wrapCClosure(fn)
        if CAP.newcclosure then
            local ok, wrapped = pcall(newcclosure, fn)
            if ok and type(wrapped) == "function" then
                return wrapped
            end
        end
        return fn
    end

    local function emitAntiBanUpdate()
        if type(AntiBan.OnStatsChanged) == "function" then
            pcall(AntiBan.OnStatsChanged, AntiBan.Stats)
        end
    end

    -- Helper HTTP Request Cross-Executor
    local function httpPost(url, body)
        local reqPayload = {
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        }
        if CAP.request == "request" then
            return request(reqPayload)
        elseif CAP.request == "syn" then
            return syn.request(reqPayload)
        elseif CAP.request == "http" then
            return http_request(reqPayload)
        elseif CAP.request == "http_tbl" then
            return http.request(reqPayload)
        end
        return nil
    end

    -- 1. ANTI-KICK (Direct Function Hook + __namecall Guard)
    abSafe(function()
        if CAP.hookfunction and LocalPlayer and LocalPlayer.Kick then
            local oldKick
            oldKick = hookfunction(LocalPlayer.Kick, wrapCClosure(function(self, ...)
                if AntiBan.Active and AntiBan.Config.EnableAntiKick and (self == LocalPlayer or self == nil) then
                    AntiBan.Stats.KicksBlocked = AntiBan.Stats.KicksBlocked + 1
                    abLog("AntiKick", "Direct Kick blocked (#" .. tostring(AntiBan.Stats.KicksBlocked) .. ")")
                    emitAntiBanUpdate()
                    return
                end
                return oldKick(self, ...)
            end))
        end
    end)

    -- 2. ANTI-REMOTE RATE LIMIT + ANTI-DETECT BAN REMOTES + NAMECALL KICK GUARD
    local suspiciousRemoteKeywords = {
        "banplayer", "ban_player", "reportcheat", "report_cheat",
        "logexploit", "log_exploit", "cheatdetected", "cheat_detected",
        "anticheatreport", "ac_ban", "kickself", "exploitdetected"
    }

    local function isSuspiciousBanRemote(remoteName)
        local lower = string.lower(tostring(remoteName or ""))
        for _, kw in ipairs(suspiciousRemoteKeywords) do
            if string.find(lower, kw, 1, true) then
                return true
            end
        end
        return false
    end

    abSafe(function()
        if not (CAP.hookmetamethod and CAP.getnamecallmethod) then return end
        local lastFire = setmetatable({}, { __mode = "k" })
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", wrapCClosure(function(self, ...)
            local method = getnamecallmethod()

            -- Tangkap LocalPlayer:Kick() melalui __namecall
            if method == "Kick" and AntiBan.Active and AntiBan.Config.EnableAntiKick and self == LocalPlayer then
                AntiBan.Stats.KicksBlocked = AntiBan.Stats.KicksBlocked + 1
                abLog("AntiKick", "__namecall Kick blocked (#" .. tostring(AntiBan.Stats.KicksBlocked) .. ")")
                emitAntiBanUpdate()
                return
            end

            if (method == "FireServer" or method == "InvokeServer") and AntiBan.Active then
                local isOurCall = CAP.checkcaller and checkcaller() or false

                -- Blokir remote pelapor ban/exploit otomatis saat AntiDetect aktif
                if not isOurCall and AntiBan.Config.EnableAntiDetect and typeof(self) == "Instance" then
                    if isSuspiciousBanRemote(self.Name) then
                        AntiBan.Stats.BanRemotesBlocked = AntiBan.Stats.BanRemotesBlocked + 1
                        abLog("AntiDetect", "Blocked suspicious report remote:", self.Name)
                        emitAntiBanUpdate()
                        if method == "InvokeServer" then
                            return true
                        end
                        return
                    end
                end

                -- Rate limiter per-instance (weak table agar bebas memory leak & tabrakan nama)
                if not isOurCall and AntiBan.Config.EnableAntiRemote and typeof(self) == "Instance" then
                    local now = os.clock()
                    local prev = lastFire[self]
                    if prev and (now - prev) < AntiBan.Config.RemoteRateLimit then
                        AntiBan.Stats.RemotesThrottled = AntiBan.Stats.RemotesThrottled + 1
                        abLog("AntiRemote", "Throttled rapid FireServer:", self.Name)
                        if method == "FireServer" then
                            return
                        end
                    end
                    lastFire[self] = now
                end
            end

            return oldNamecall(self, ...)
        end))
    end)

    -- 3. ANTI-STATS SCAN (Surgical rawequal(self, Stats) Filter)
    abSafe(function()
        if not (CAP.getrawmetatable and (CAP.setreadonly or CAP.make_writeable)) then return end
        local mt = getrawmetatable(Stats)
        if not mt or type(mt.__index) ~= "function" then return end

        local function setTableReadonly(tbl, state)
            if CAP.setreadonly then
                pcall(setreadonly, tbl, state)
            elseif CAP.make_writeable and not state then
                pcall(make_writeable, tbl)
            end
        end

        setTableReadonly(mt, false)
        local oldIndex = mt.__index
        mt.__index = wrapCClosure(function(self, key)
            if AntiBan.Active and AntiBan.Config.EnableAntiStatsScan and rawequal(self, Stats) then
                if key == "GetChildren" or key == "GetDescendants" then
                    local res = oldIndex(self, key)
                    if type(res) == "function" then
                        return wrapCClosure(function(s)
                            local list = res(s)
                            local out = {}
                            for _, c in ipairs(list) do
                                if not string.find(string.lower(c.Name), "script", 1, true) then
                                    table.insert(out, c)
                                else
                                    AntiBan.Stats.StatsScansFiltered = AntiBan.Stats.StatsScansFiltered + 1
                                end
                            end
                            return out
                        end)
                    end
                end
            end
            return oldIndex(self, key)
        end)
        setTableReadonly(mt, true)
    end)

    -- 4. SPOOF HWID
    function AntiBan.RegenerateHWID()
        abSafe(function()
            local newGuid = HttpService:GenerateGUID(false)
            AntiBan.Stats.SpoofedHWID = newGuid
            local env = getGlobalEnv()
            env.hwid = newGuid
            abLog("Spoof", "HWID:", newGuid)
            emitAntiBanUpdate()
        end)
    end

    if AntiBan.Config.EnableSpoofHWID then
        AntiBan.RegenerateHWID()
        abSafe(function()
            if CAP.hookfunction and CAP.gethwid then
                local oldGetHwid
                oldGetHwid = hookfunction(gethwid, wrapCClosure(function(...)
                    if AntiBan.Active and AntiBan.Config.EnableSpoofHWID and AntiBan.Stats.SpoofedHWID ~= "N/A" then
                        return AntiBan.Stats.SpoofedHWID
                    end
                    return oldGetHwid(...)
                end))
            end
        end)
    end

    -- 5. DISCORD WEBHOOK REPORTER (Non-Yielding & Clean Lifecycle)
    if AntiBan.Config.EnableWebhook and AntiBan.Config.WebhookURL ~= "" and CAP.request then
        task.spawn(function()
            local placeName = "Unknown"
            pcall(function()
                if type(MarketplaceService.GetProductInfoAsync) == "function" then
                    placeName = MarketplaceService:GetProductInfoAsync(game.PlaceId).Name
                else
                    placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
                end
            end)
            while AntiBan.Active and task.wait(math.max(10, AntiBan.Config.WebhookInterval or 60)) do
                if not AntiBan.Active then break end
                if AntiBan.Config.EnableWebhook and AntiBan.Config.WebhookURL ~= "" then
                    local plrName = (LocalPlayer and LocalPlayer.Name) or "Unknown"
                    local data = {
                        username = "AntiBan v" .. AntiBan.Config.Version,
                        embeds = {{
                            title = "Session Report — BimSakSin Hub",
                            color = 65280,
                            fields = {
                                { name = "Place",   value = tostring(placeName), inline = true },
                                { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
                                { name = "Player",  value = tostring(plrName), inline = true },
                                { name = "HWID",    value = tostring(AntiBan.Stats.SpoofedHWID or "N/A") },
                            }
                        }}
                    }
                    pcall(httpPost, AntiBan.Config.WebhookURL, HttpService:JSONEncode(data))
                end
            end
        end)
    end

    -- 6. SAFE FIRE API (Jittered Execution untuk Remote Calls)
    local SafeFire = {}
    function SafeFire.Fire(remote, ...)
        if not remote or typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then
            return false
        end
        task.wait(math.random(1, 3) / 1000)
        local args = { ... }
        return abSafe(function()
            remote:FireServer(table.unpack(args))
        end)
    end

    function SafeFire.Invoke(remote, ...)
        if not remote or typeof(remote) ~= "Instance" or not remote:IsA("RemoteFunction") then
            return false, nil
        end
        task.wait(math.random(1, 3) / 1000)
        local args = { ... }
        return abSafe(function()
            return remote:InvokeServer(table.unpack(args))
        end)
    end

    AntiBan.Fire = SafeFire.Fire
    AntiBan.Invoke = SafeFire.Invoke
    AntiBan.Log = abLog
    AntiBan.Version = AntiBan.Config.Version

    -- 7. FLOATING MINI-CONSOLE OPSIONAL (Aman dari Leak & Mendukung Touch/Mouse)
    function AntiBan.SetConsoleVisible(visible)
        AntiBan.Config.InteractiveConsole = (visible == true)
        if not visible then
            if AntiBan.ConsoleGui then
                pcall(function() AntiBan.ConsoleGui:Destroy() end)
                AntiBan.ConsoleGui = nil
            end
            return
        end

        if AntiBan.ConsoleGui and AntiBan.ConsoleGui.Parent then
            AntiBan.ConsoleGui.Enabled = true
            return
        end

        abSafe(function()
            local parent = (CAP.gethui and gethui()) or CoreGui
            local gui = Instance.new("ScreenGui")
            gui.Name = "AntiBanUI_" .. HttpService:GenerateGUID(false)
            gui.ResetOnSpawn = false
            gui.Parent = parent
            AntiBan.ConsoleGui = gui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 310, 0, 215)
            frame.Position = UDim2.new(1, -330, 0, 20)
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            frame.BorderSizePixel = 0
            frame.Active = true
            frame.Parent = gui
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame

            local dragging, dragInput, dragStart, startPos
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragInput = input
                    dragStart = input.Position
                    startPos = frame.Position
                end
            end)
            frame.InputEnded:Connect(function(input)
                if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    dragInput = nil
                end
            end)
            local dragConn = UserInputService.InputChanged:Connect(function(input)
                if dragging and dragStart and startPos and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
                    local d = input.Position - dragStart
                    frame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + d.X,
                        startPos.Y.Scale, startPos.Y.Offset + d.Y
                    )
                end
            end)
            table.insert(Connections, dragConn)

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 28)
            title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            title.Text = " 🛡️  Anti-Ban v" .. AntiBan.Config.Version
            title.TextColor3 = Color3.fromRGB(0, 255, 150)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 13
            title.Parent = frame

            local status = Instance.new("TextLabel")
            status.Size = UDim2.new(1, -20, 1, -78)
            status.Position = UDim2.new(0, 10, 0, 36)
            status.BackgroundTransparency = 1
            status.TextXAlignment = Enum.TextXAlignment.Left
            status.TextYAlignment = Enum.TextYAlignment.Top
            status.TextColor3 = Color3.fromRGB(210, 210, 220)
            status.Font = Enum.Font.Code
            status.TextSize = 11
            status.Text = "● Loading..."
            status.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 26)
            btn.Position = UDim2.new(0, 10, 1, -36)
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            btn.Text = "TOGGLE DEBUG LOG"
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.Parent = frame
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            btn.MouseButton1Click:Connect(function()
                AntiBan.Config.Debug = not AntiBan.Config.Debug
            end)

            task.spawn(function()
                while AntiBan.Active and gui and gui.Parent and task.wait(0.8) do
                    local env = getGlobalEnv()
                    local hwidShort = string.sub(tostring(env.hwid or AntiBan.Stats.SpoofedHWID or "N/A"), 1, 12)
                    status.Text = string.format(
                        "● Status     : ACTIVE\n● Debug      : %s\n● HWID       : %s...\n● AntiKick   : %s (%d blk)\n● AntiRemote : %s (%d thr)\n● AntiStats  : %s",
                        tostring(AntiBan.Config.Debug),
                        hwidShort,
                        tostring(AntiBan.Config.EnableAntiKick),
                        AntiBan.Stats.KicksBlocked,
                        tostring(AntiBan.Config.EnableAntiRemote),
                        AntiBan.Stats.RemotesThrottled,
                        tostring(AntiBan.Config.EnableAntiStatsScan)
                    )
                end
            end)
        end)
    end

    function AntiBan.Shutdown()
        AntiBan.Active = false
        if AntiBan.ConsoleGui then
            pcall(function() AntiBan.ConsoleGui:Destroy() end)
            AntiBan.ConsoleGui = nil
        end
    end

    if AntiBan.Config.InteractiveConsole then
        AntiBan.SetConsoleVisible(true)
    end

    -- Expose API secara global untuk kompatibilitas script eksternal
    _G.AntiBan = AntiBan
    local env = getGlobalEnv()
    env.BSS_AntiBan = AntiBan
    abLog("Boot", ("✅ Anti-Ban v%s loaded | PlaceId=%s"):format(AntiBan.Config.Version, tostring(game.PlaceId)))
end
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
        Generator = {},
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
    table.clear(FeatureAPI.RemoteIndex.Generator)

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
                    if string.find(lower, "gen") or string.find(lower, "repair") or string.find(lower, "fix") or string.find(lower, "power") or string.find(lower, "charge") or string.find(lower, "skill") then
                        table.insert(FeatureAPI.RemoteIndex.Generator, inst)
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

if typeof(getgenv) == "function" then
    getgenv().BSS_FeatureAPI = FeatureAPI
end

-- ============================================================================
-- 2B. GENERATOR READER API & AUTO GENERATOR STATE (MAP DISTRIK & UNIVERSAL)
-- ============================================================================
local GeneratorAPI = {
    Cache = {},
    LastScan = 0,
    Listeners = {},
    Keywords = {
        "generator", "genset", "reactor", "repairmachine", "powerbox",
        "dynamo", "turbine", "fusebox", "breaker", "panel", "terminal",
        "engine", "mesin", "listrik", "gardu", "trafo", "pump", "boiler", "hackstation"
    },
}

local AutoGen = {
    Enabled = false,
    AutoTeleport = true,
    AutoInteract = true,
    AutoSkillCheck = true,
    AutoSwitchNext = true,
    OffsetMode = "Front",
    TeleportOffset = Vector3.new(0, 2.2, 3.2),
    InteractRange = 14,
    ScanInterval = 0.25,
    CurrentTarget = nil,
    CompletedCount = 0,
    LastActionTime = 0,
    LastNotifyTime = 0,
    LastSkillCheckTime = 0,
    StatusText = "Siap",
}

do
    function GeneratorAPI.OnUpdate(callback)
        if type(callback) ~= "function" then return nil end
        table.insert(GeneratorAPI.Listeners, callback)
        return function()
            for i = #GeneratorAPI.Listeners, 1, -1 do
                if GeneratorAPI.Listeners[i] == callback then
                    table.remove(GeneratorAPI.Listeners, i)
                end
            end
        end
    end

    local function emitGeneratorUpdate(list)
        for _, cb in ipairs(GeneratorAPI.Listeners) do
            pcall(cb, list)
        end
    end

    local function isCharPart(inst)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and inst:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    function GeneratorAPI.IsGeneratorInstance(inst)
        if not inst or not inst.Parent or isCharPart(inst) then
            return false
        end
        local n = string.lower(inst.Name)
        if n == "gen" or string.match(n, "^gen[%d_%-]") or string.match(n, "[%d_%-]gen$") then
            return true
        end
        for _, kw in ipairs(GeneratorAPI.Keywords) do
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
        return false
    end

    function GeneratorAPI.GetPrimaryPart(genObj)
        if not genObj or not genObj.Parent then return nil end
        if genObj:IsA("BasePart") then return genObj end
        if genObj:IsA("Model") then
            return genObj.PrimaryPart or genObj:FindFirstChild("Handle") or genObj:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function parseTextProgress(txt)
        if type(txt) ~= "string" or txt == "" then
            return nil, false, false
        end
        local pctVal = nil
        local done = false
        local working = false

        local numPct = string.match(txt, "(%d+%.?%d*)%s*%%")
        if numPct then
            local parsed = tonumber(numPct)
            if parsed and parsed >= 0 and parsed <= 100 then
                pctVal = math.floor(parsed + 0.5)
            end
        end

        if not pctVal then
            local cur, tot = string.match(txt, "(%d+)%s*/%s*(%d+)")
            local nCur, nTot = tonumber(cur), tonumber(tot)
            if nCur and nTot and nTot > 0 and nCur <= nTot then
                pctVal = math.floor((nCur / nTot) * 100 + 0.5)
            end
        end

        local low = string.lower(txt)
        if string.find(low, "selesai", 1, true)
            or string.find(low, "fixed", 1, true)
            or string.find(low, "complete", 1, true)
            or string.find(low, "repaired", 1, true)
            or string.find(low, "online", 1, true)
            or string.find(low, "aktif", 1, true) then
            done = true
            pctVal = 100
        elseif string.find(low, "memperbaiki", 1, true)
            or string.find(low, "repairing", 1, true)
            or string.find(low, "fixing", 1, true)
            or string.find(low, "charging", 1, true)
            or string.find(low, "proses", 1, true) then
            working = true
        end

        return pctVal, done, working
    end

    local function scanAttributes(targetObj)
        local pPct = nil
        local done = false
        local working = false
        local worker = nil
        if not targetObj then return nil, false, false, nil end
        pcall(function()
            for attrName, attrVal in pairs(targetObj:GetAttributes()) do
                local k = string.lower(tostring(attrName))
                if type(attrVal) == "boolean" then
                    if (string.find(k, "complete", 1, true) or string.find(k, "fixed", 1, true) or string.find(k, "done", 1, true) or string.find(k, "repaired", 1, true) or string.find(k, "finished", 1, true)) and attrVal == true then
                        done = true
                    elseif (string.find(k, "repairing", 1, true) or string.find(k, "active", 1, true) or string.find(k, "working", 1, true) or string.find(k, "inuse", 1, true) or string.find(k, "occupied", 1, true)) and attrVal == true then
                        working = true
                    end
                elseif type(attrVal) == "number" then
                    if string.find(k, "progress", 1, true) or string.find(k, "percent", 1, true) or string.find(k, "charge", 1, true) or string.find(k, "repair", 1, true) or string.find(k, "power", 1, true) or string.find(k, "fuel", 1, true) or string.find(k, "persen", 1, true) then
                        local maxAttr = targetObj:GetAttribute("Max" .. attrName) or targetObj:GetAttribute("MaxProgress") or targetObj:GetAttribute("MaxRepair") or 100
                        local calc = (attrVal <= 1 and maxAttr == 100 and attrVal > 0)
                            and math.floor(attrVal * 100 + 0.5)
                            or math.floor((attrVal / math.max(1, maxAttr)) * 100 + 0.5)
                        if not pPct or calc > pPct then
                            pPct = calc
                        end
                    end
                elseif type(attrVal) == "string" and attrVal ~= "" then
                    local lowV = string.lower(attrVal)
                    if string.find(k, "worker", 1, true) or string.find(k, "player", 1, true) or string.find(k, "user", 1, true) or string.find(k, "occupant", 1, true) then
                        worker = attrVal
                        working = true
                    else
                        local tp, td, tw = parseTextProgress(attrVal)
                        if tp and (not pPct or tp > pPct) then pPct = tp end
                        if td then done = true end
                        if tw then working = true end
                        if string.find(lowV, "work", 1, true) then working = true end
                    end
                end
            end
        end)
        return pPct, done, working, worker
    end

    function GeneratorAPI.ReadProgress(genObj)
        if not genObj or not genObj.Parent then
            return 0, "Invalid", false, false, nil, nil
        end

        local maxPct = nil
        local isDone = false
        local isWorking = false
        local workerName = nil
        local foundPrompt = nil

        local p0, d0, w0, wk0 = scanAttributes(genObj)
        if p0 then maxPct = p0 end
        if d0 then isDone = true end
        if w0 then isWorking = true end
        if wk0 then workerName = wk0 end

        for _, desc in ipairs(genObj:GetDescendants()) do
            local p1, d1, w1, wk1 = scanAttributes(desc)
            if p1 and (not maxPct or p1 > maxPct) then maxPct = p1 end
            if d1 then isDone = true end
            if w1 then isWorking = true end
            if wk1 and not workerName then workerName = wk1 end

            local dLow = string.lower(desc.Name)
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                if string.find(dLow, "prog", 1, true) or string.find(dLow, "fix", 1, true) or string.find(dLow, "repair", 1, true)
                    or string.find(dLow, "charge", 1, true) or string.find(dLow, "power", 1, true) or string.find(dLow, "persen", 1, true)
                    or string.find(dLow, "percent", 1, true) or string.find(dLow, "current", 1, true) or string.find(dLow, "value", 1, true) then
                    local val = desc.Value
                    local maxObj = desc.Parent and (
                        desc.Parent:FindFirstChild("Max" .. desc.Name)
                        or desc.Parent:FindFirstChild("MaxProgress")
                        or desc.Parent:FindFirstChild("MaxRepair")
                        or desc.Parent:FindFirstChild("MaxValue")
                        or desc.Parent:FindFirstChild("Max")
                    )
                    local maxV = (maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) and maxObj.Value > 0) and maxObj.Value or 100
                    local calc = (val > 0 and val <= 1 and maxV == 100)
                        and math.floor(val * 100 + 0.5)
                        or math.floor((val / maxV) * 100 + 0.5)
                    if calc >= 0 and calc <= 100 and (not maxPct or calc > maxPct) then
                        maxPct = calc
                    end
                end
            elseif desc:IsA("BoolValue") then
                if (string.find(dLow, "done", 1, true) or string.find(dLow, "fixed", 1, true) or string.find(dLow, "complete", 1, true)
                    or string.find(dLow, "repaired", 1, true) or string.find(dLow, "finished", 1, true)) and desc.Value == true then
                    isDone = true
                elseif (string.find(dLow, "repairing", 1, true) or string.find(dLow, "working", 1, true)
                    or string.find(dLow, "inuse", 1, true) or string.find(dLow, "occupied", 1, true)) and desc.Value == true then
                    isWorking = true
                end
            elseif desc:IsA("StringValue") and desc.Value ~= "" then
                if string.find(dLow, "worker", 1, true) or string.find(dLow, "user", 1, true) or string.find(dLow, "player", 1, true) then
                    workerName = desc.Value
                    isWorking = true
                else
                    local tp, td, tw = parseTextProgress(desc.Value)
                    if tp and (not maxPct or tp > maxPct) then maxPct = tp end
                    if td then isDone = true end
                    if tw then isWorking = true end
                end
            elseif desc:IsA("TextLabel") and desc.Text ~= "" then
                local tp, td, tw = parseTextProgress(desc.Text)
                if tp and (not maxPct or tp > maxPct) then maxPct = tp end
                if td then isDone = true end
                if tw then isWorking = true end
            elseif (desc:IsA("Frame") and desc:FindFirstAncestorWhichIsA("SurfaceGui")) or (desc:IsA("Frame") and desc:FindFirstAncestorWhichIsA("BillboardGui")) then
                if string.find(dLow, "fill", 1, true) or string.find(dLow, "bar", 1, true) or string.find(dLow, "prog", 1, true) then
                    local sx = desc.Size.X.Scale
                    if sx > 0.01 and sx <= 1.0 then
                        local calc = math.floor(sx * 100 + 0.5)
                        if not maxPct or calc > maxPct then
                            maxPct = calc
                        end
                    end
                end
            elseif desc:IsA("ProximityPrompt") then
                if not foundPrompt or desc.Enabled then
                    foundPrompt = desc
                end
                local tp, td, tw = parseTextProgress((desc.ActionText or "") .. " " .. (desc.ObjectText or ""))
                if tp and (not maxPct or tp > maxPct) then maxPct = tp end
                if td then isDone = true end
                if tw then isWorking = true end
                if not desc.Enabled and (maxPct and maxPct >= 95) then
                    isDone = true
                end
            elseif (desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight")) and desc.Enabled then
                if desc.Color.G > 0.72 and desc.Color.R < 0.45 and desc.Color.B < 0.45 then
                    isDone = true
                end
            end
        end

        local clamped = maxPct and math.clamp(maxPct, 0, 100) or 0
        if isDone or clamped >= 100 then
            isDone = true
            clamped = 100
        end

        local statusLabel = isDone and "✅ SELESAI DIPROSES (100%)"
            or ((isWorking or clamped > 0) and string.format("🔧 PROGRES GENERATOR (%d%%)", clamped))
            or "⏳ BELUM DIKERJAKAN (0%)"

        return clamped, statusLabel, isDone, isWorking, workerName, foundPrompt
    end

    function GeneratorAPI.ScanAll(force)
        local now = os.clock()
        if not force and (now - GeneratorAPI.LastScan) < 0.25 and #GeneratorAPI.Cache > 0 then
            return GeneratorAPI.Cache
        end
        GeneratorAPI.LastScan = now

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local originPos = myRoot and myRoot.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)

        local results = {}
        local seen = {}

        local function registerCandidate(inst)
            if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then return end
            if not GeneratorAPI.IsGeneratorInstance(inst) then return end

            local target = inst
            local anc = inst.Parent
            while anc and anc ~= workspace do
                if (anc:IsA("Model") or anc:IsA("Folder")) and GeneratorAPI.IsGeneratorInstance(anc) then
                    target = anc
                end
                anc = anc.Parent
            end

            if seen[target] then return end
            seen[target] = true

            local part = GeneratorAPI.GetPrimaryPart(target)
            if not part then return end

            local pct, statusText, isDone, isWorking, worker, prompt = GeneratorAPI.ReadProgress(target)
            local dist = originPos and (part.Position - originPos).Magnitude or 9999

            table.insert(results, {
                Instance = target,
                Name = target.Name,
                Part = part,
                Position = part.Position,
                CFrame = part.CFrame,
                Distance = math.floor(dist + 0.5),
                Progress = pct,
                Status = statusText,
                Completed = isDone,
                Working = isWorking,
                Worker = worker,
                Prompt = prompt,
            })
        end

        if GeneratorESP and GeneratorESP.Candidates and next(GeneratorESP.Candidates) ~= nil then
            for inst, _ in pairs(GeneratorESP.Candidates) do
                registerCandidate(inst)
            end
        end

        if #results == 0 then
            for _, inst in ipairs(workspace:GetDescendants()) do
                if inst:IsA("Model") or inst:IsA("BasePart") then
                    registerCandidate(inst)
                end
            end
        end

        table.sort(results, function(a, b)
            return a.Distance < b.Distance
        end)

        GeneratorAPI.Cache = results
        emitGeneratorUpdate(results)
        return results
    end

    function GeneratorAPI.GetNearestIncomplete()
        local list = GeneratorAPI.ScanAll(true)
        for _, item in ipairs(list) do
            if not item.Completed and item.Progress < 100 then
                return item
            end
        end
        return nil
    end

    function GeneratorAPI.GetStats()
        local list = GeneratorAPI.ScanAll(false)
        local total = #list
        local done = 0
        local active = 0
        local nearest = nil
        for _, item in ipairs(list) do
            if item.Completed or item.Progress >= 100 then
                done = done + 1
            else
                if not nearest then
                    nearest = item
                end
                if item.Working or item.Progress > 0 then
                    active = active + 1
                end
            end
        end
        return {
            Total = total,
            Completed = done,
            InProgress = active,
            Idle = math.max(0, total - done - active),
            Nearest = nearest,
        }
    end
end

if typeof(getgenv) == "function" then
    getgenv().BSS_GeneratorAPI = GeneratorAPI
end
FeatureAPI.Generator = GeneratorAPI
-- ============================================================================
-- 3. UTILITY FUNCTIONS, SAFE TELEPORT & THEME ENGINE
-- ============================================================================
function Utils.Track(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

-- Auto-Rebind & Pemulihan Fisika Saat Karakter Respawn
do
    local function bindCharacterRespawn(plr)
        if not plr then return end
        Utils.Track(plr.CharacterAdded:Connect(function(newChar)
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
    end

    if LocalPlayer then
        bindCharacterRespawn(LocalPlayer)
    else
        task.spawn(function()
            local plr = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)
            LocalPlayer = plr
            bindCharacterRespawn(plr)
        end)
    end
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
-- 3A. CONFIG PERSISTENCE MANAGER (JSON Simpan & Muat Aman + AntiBan Sync)
-- ============================================================================
do
    function ConfigManager.BuildPayload()
        return {
            SchemaVersion = 2,
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
            AutoGenTeleport = AutoGen.AutoTeleport,
            AutoGenInteract = AutoGen.AutoInteract,
            AutoGenSkillCheck = AutoGen.AutoSkillCheck,
            AutoGenSwitchNext = AutoGen.AutoSwitchNext,
            AntiBanKick = AntiBan.Config.EnableAntiKick,
            AntiBanRemote = AntiBan.Config.EnableAntiRemote,
            AntiBanDetect = AntiBan.Config.EnableAntiDetect,
            AntiBanStatsScan = AntiBan.Config.EnableAntiStatsScan,
            AntiBanSpoofHWID = AntiBan.Config.EnableSpoofHWID,
            AntiBanRateLimit = AntiBan.Config.RemoteRateLimit,
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
                Combat.ParryRange = math.clamp(data.ParryRange, 6, 40)
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
            if type(data.AutoGenTeleport) == "boolean" then
                AutoGen.AutoTeleport = data.AutoGenTeleport
            end
            if type(data.AutoGenInteract) == "boolean" then
                AutoGen.AutoInteract = data.AutoGenInteract
            end
            if type(data.AutoGenSkillCheck) == "boolean" then
                AutoGen.AutoSkillCheck = data.AutoGenSkillCheck
            end
            if type(data.AutoGenSwitchNext) == "boolean" then
                AutoGen.AutoSwitchNext = data.AutoGenSwitchNext
            end
            if type(data.AntiBanKick) == "boolean" then
                AntiBan.Config.EnableAntiKick = data.AntiBanKick
            end
            if type(data.AntiBanRemote) == "boolean" then
                AntiBan.Config.EnableAntiRemote = data.AntiBanRemote
            end
            if type(data.AntiBanDetect) == "boolean" then
                AntiBan.Config.EnableAntiDetect = data.AntiBanDetect
            end
            if type(data.AntiBanStatsScan) == "boolean" then
                AntiBan.Config.EnableAntiStatsScan = data.AntiBanStatsScan
            end
            if type(data.AntiBanSpoofHWID) == "boolean" then
                AntiBan.Config.EnableSpoofHWID = data.AntiBanSpoofHWID
            end
            if type(data.AntiBanRateLimit) == "number" then
                AntiBan.Config.RemoteRateLimit = math.clamp(data.AntiBanRateLimit, 0.005, 0.5)
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

    local function escapeHtmlTelegram(str)
        return tostring(str or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
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
            local info = nil
            if type(MarketplaceService.GetProductInfoAsync) == "function" then
                info = MarketplaceService:GetProductInfoAsync(game.PlaceId)
            else
                info = MarketplaceService:GetProductInfo(game.PlaceId)
            end
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

                if inst:IsA("MeshPart") then
                    node.MeshId = tostring(inst.MeshId)
                    node.TextureID = tostring(inst.TextureID)
                end
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
                if n.Size then
                    safeClass = "Part"
                else
                    safeClass = (n.ParentIndex == nil) and "Model" or "Folder"
                end
            end

            table.insert(lines, string.format("local %s = Instance.new(\"%s\")", varName, escapeLuaString(safeClass)))
            table.insert(lines, string.format("%s.Name = \"%s\"", varName, escapeLuaString(n.Name)))

            if n.Size then
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

        local escapedFiles = {}
        for _, f in ipairs(fileList) do
            table.insert(escapedFiles, escapeHtmlTelegram(f))
        end
        local filesText = (#escapedFiles > 0) and table.concat(escapedFiles, "\n• ") or "Tidak ada file tersimpan"
        local dispName = (LocalPlayer and LocalPlayer.DisplayName) or "Player"
        local usrName = (LocalPlayer and LocalPlayer.Name) or "unknown"

        local textMsg = table.concat({
            "🎃 <b>BimSakSin Hub v3.0 — Copy Asset / Map Alert</b>",
            "━━━━━━━━━━━━━━━━━━━━",
            "• <b>Status:</b> Copy &amp; File Export Selesai",
            "• <b>Game:</b> " .. escapeHtmlTelegram(summaryMeta.GameTitle) .. " (<code>" .. tostring(summaryMeta.PlaceId) .. "</code>)",
            "• <b>Target:</b> <code>" .. escapeHtmlTelegram(summaryMeta.AssetName) .. "</code> (" .. escapeHtmlTelegram(summaryMeta.ClassName) .. ")",
            "• <b>Scope:</b> <code>" .. escapeHtmlTelegram(summaryMeta.Scope) .. "</code>",
            "• <b>Total Node:</b> <code>" .. tostring(summaryMeta.TotalNodes) .. "</code>",
            "• <b>Pemain:</b> <code>" .. escapeHtmlTelegram(dispName) .. "</code> (@" .. escapeHtmlTelegram(usrName) .. ")",
            "• <b>Waktu:</b> <code>" .. escapeHtmlTelegram(summaryMeta.TimestampISO) .. "</code>",
            "• <b>File Dibuat:</b>",
            "• <code>" .. filesText .. "</code>",
        }, "\n")

        local url = string.format("https://api.telegram.org/bot%s/sendMessage", token)
        local payload = HttpService:JSONEncode({
            chat_id = chatId,
            text = textMsg,
            parse_mode = "HTML",
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
        Text = "AntiBan + AntiBug: ON",
        TextColor3 = Theme.TextSecondary,
        TextSize = 9,
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
        CellPadding = UDim.new(0.025, 0, 0, 6),
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
                local k = string.lower(tostring(attrName))
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

        if GeneratorAPI and type(GeneratorAPI.ReadProgress) == "function" then
            local apiPct, _, apiDone, apiWorking, apiWorker = GeneratorAPI.ReadProgress(genObj)
            if apiPct and apiPct > 0 then progressPct = apiPct end
            if apiDone then isCompleted = true end
            if apiWorking then isBeingWorked = true end
            if apiWorker then workerName = apiWorker end
        end

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
    local workspaceListenersBound = false
    local initialScanComplete = false
    local initialScanRunning = false

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
        if not workspaceListenersBound then
            workspaceListenersBound = true

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

        if not initialScanComplete and not initialScanRunning then
            initialScanRunning = true
            task.spawn(function()
                local descendants = workspace:GetDescendants()
                for i, inst in ipairs(descendants) do
                    if not ItemESP.Enabled and not GeneratorESP.Enabled then
                        initialScanRunning = false
                        return
                    end
                    evaluateCandidate(inst)
                    if i % 1500 == 0 then
                        RunService.Heartbeat:Wait()
                    end
                end
                initialScanRunning = false
                initialScanComplete = true
            end)
        end
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

        if myRoot and attackerChar then
            local aRoot = attackerChar:FindFirstChild("HumanoidRootPart")
            if aRoot then
                local flatTarget = Vector3.new(aRoot.Position.X, myRoot.Position.Y, aRoot.Position.Z)
                if (flatTarget - myRoot.Position).Magnitude > 0.1 then
                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, flatTarget)
                end
            end
        end

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

        Combat.ScanParryRemotes()
        for _, rem in ipairs(Combat.ParryRemoteCache) do
            if rem and rem.Parent and rem:IsA("RemoteEvent") then
                pcall(function() rem:FireServer(true) end)
                pcall(function() rem:FireServer() end)
            end
        end

        local keysToPress = {}
        if Combat.ParryKey == "Auto" then
            keysToPress = { Enum.KeyCode.F, Enum.KeyCode.Q }
        elseif Combat.ParryKey == "F" then
            keysToPress = { Enum.KeyCode.F }
        elseif Combat.ParryKey == "Q" then
            keysToPress = { Enum.KeyCode.Q }
        elseif Combat.ParryKey == "E" then
            keysToPress = { Enum.KeyCode.E }
        elseif Combat.ParryKey == "R" then
            keysToPress = { Enum.KeyCode.R }
        elseif Combat.ParryKey == "RMB" then
            if VirtualInputManager then
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
                    task.delay(0.06, function()
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
                        end)
                    end)
                end)
            end
        end

        if VirtualInputManager and #keysToPress > 0 then
            for _, kc in ipairs(keysToPress) do
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, kc, false, game)
                    task.delay(0.06, function()
                        pcall(function()
                            VirtualInputManager:SendKeyEvent(false, kc, false, game)
                        end)
                    end)
                end)
            end
        end

        if Combat.AutoParryVisual then
            if not Combat.ParryShieldHL or not Combat.ParryShieldHL.Parent then
                Combat.ParryShieldHL = Utils.Create("Highlight", {
                    Name = "BSS_ParryShieldFX",
                    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                    FillColor = Color3.fromRGB(46, 213, 115),
                    OutlineColor = Color3.fromRGB(255, 255, 255),
                    FillTransparency = 0.45,
                    OutlineTransparency = 0.05,
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

        FeatureAPI.Emit("AutoParryTriggered", attackerName, Combat.ParryCount)
    end

    function Combat.StepAutoParry()
        if not Combat.AutoParryEnabled then
            if Combat.ParryRingPart then
                Combat.ParryRingPart.Transparency = 1
            end
            return
        end

        Combat.UpdateParryRangeVisual()

        local myChar, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myChar or not myHum or myHum.Health <= 0 or not myRoot then return end
        if (os.clock() - Combat.LastParryTime) < Combat.ParryCooldown then return end

        local threatDetected = false
        local threatSourceName = "Enemy"
        local threatChar = nil

        local attackKeywords = {
            "slash", "swing", "attack", "punch", "kick", "hit", "strike",
            "stab", "heavy", "lunge", "combo", "smash", "cut", "cleave", "melee", "serang", "pukul"
        }

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isAlly = (#Teams:GetTeams() > 0 and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
                if not (Combat.TeamCheck and isAlly) then
                    local eChar, eHum, eRoot = Utils.GetCharacter(plr)
                    if eChar and eHum and eHum.Health > 0 and eRoot then
                        local dist = (eRoot.Position - myRoot.Position).Magnitude
                        if dist <= Combat.ParryRange then
                            local anim = eHum:FindFirstChildOfClass("Animator")
                            if anim then
                                for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                                    local aName = string.lower((track.Name or "") .. " " .. (track.Animation and track.Animation.Name or ""))
                                    for _, kw in ipairs(attackKeywords) do
                                        if string.find(aName, kw, 1, true) then
                                            threatDetected = true
                                            threatSourceName = plr.DisplayName
                                            threatChar = eChar
                                            break
                                        end
                                    end
                                    if threatDetected then break end
                                end
                            end

                            if not threatDetected then
                                local tool = eChar:FindFirstChildOfClass("Tool")
                                if tool then
                                    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                                    if handle and handle.AssemblyLinearVelocity.Magnitude > 14 then
                                        threatDetected = true
                                        threatSourceName = plr.DisplayName
                                        threatChar = eChar
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if threatDetected then break end
        end

        if not threatDetected then
            local scanBoxSize = Vector3.new(Combat.ParryRange * 2, Combat.ParryRange * 2, Combat.ParryRange * 2)
            local params = OverlapParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { myChar }
            local nearbyParts = workspace:GetPartBoundsInBox(myRoot.CFrame, scanBoxSize, params)
            for _, part in ipairs(nearbyParts) do
                if part and part:IsA("BasePart") and not part.Anchored then
                    local speed = part.AssemblyLinearVelocity.Magnitude
                    if speed > 32 then
                        local pName = string.lower(part.Name)
                        local isProj = string.find(pName, "ball")
                            or string.find(pName, "proj")
                            or string.find(pName, "arrow")
                            or string.find(pName, "bullet")
                            or string.find(pName, "slash")
                            or string.find(pName, "wave")
                            or string.find(pName, "orb")
                            or string.find(pName, "fire")
                            or string.find(pName, "blade")
                            or part:FindFirstChildOfClass("BodyVelocity")
                            or part:FindFirstChildOfClass("LinearVelocity")
                        if isProj then
                            local toMe = (myRoot.Position - part.Position)
                            if toMe.Magnitude > 0.1 and part.AssemblyLinearVelocity.Unit:Dot(toMe.Unit) > 0.45 then
                                threatDetected = true
                                threatSourceName = part.Name
                                break
                            end
                        end
                    end
                end
            end
        end

        if threatDetected then
            if Combat.ParryReactionDelay > 0 then
                task.delay(Combat.ParryReactionDelay, function()
                    if Combat.AutoParryEnabled then
                        Combat.TriggerParryAction(threatSourceName, threatChar)
                    end
                end)
            else
                Combat.TriggerParryAction(threatSourceName, threatChar)
            end
        end
    end

    function Combat.StepAimbot()
        if Combat.FOVCircle then
            Combat.FOVCircle.Visible = Combat.AimbotEnabled and Combat.ShowFOVCircle
            Combat.FOVCircle.Size = UDim2.new(0, Combat.FOVRadius * 2, 0, Combat.FOVRadius * 2)
        end

        if not Combat.AimbotEnabled then
            Combat.CurrentTarget = nil
            Combat.HideLaser()
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then
            Combat.HideLaser()
            return
        end

        local tool, isRanged = Combat.GetEquippedRangedWeapon()
        local activeAim = false
        if Combat.AimbotMode == "Always" then
            activeAim = true
        else
            activeAim = isRanged
        end

        if not activeAim then
            Combat.CurrentTarget = nil
            Combat.HideLaser()
            return
        end

        local targetPlr, aimPart = Combat.FindBestTarget()
        Combat.CurrentTarget = targetPlr

        if targetPlr and aimPart then
            local targetPos = aimPart.Position
            local desiredCF = CFrame.lookAt(cam.CFrame.Position, targetPos)
            local alpha = math.clamp(1 - (Combat.Smoothness * 0.75), 0.15, 1)
            cam.CFrame = cam.CFrame:Lerp(desiredCF, alpha)

            if Combat.RGBLaserEnabled then
                local startPos = nil
                if tool then
                    local muzzle = tool:FindFirstChild("Muzzle", true)
                        or tool:FindFirstChild("FirePoint", true)
                        or tool:FindFirstChild("Barrel", true)
                        or tool:FindFirstChild("Handle")
                        or tool:FindFirstChildWhichIsA("BasePart", true)
                    if muzzle and muzzle:IsA("BasePart") then
                        startPos = muzzle.Position
                    end
                end
                if not startPos then
                    local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
                    startPos = myRoot and (myRoot.Position + Vector3.new(0, 1.4, 0)) or cam.CFrame.Position
                end
                Combat.UpdateLaser(startPos, targetPos)
            else
                Combat.HideLaser()
            end
        else
            Combat.HideLaser()
        end
    end
end

-- ============================================================================
-- 13. INTERACTIVE REPLICATED CARRY ENGINE (Universal Map & R6/R15 Replicated)
-- ============================================================================
do
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
        if not Carry.Enabled or not Carry.ShowVisualBeam or not myRoot or not tRoot then
            Carry.CleanupVisuals()
            return
        end

        if not Carry.VisualAtt0 or Carry.VisualAtt0.Parent ~= myRoot then
            Carry.CleanupVisuals()
            local a0 = Instance.new("Attachment")
            a0.Name = "BSS_CarryAtt0"
            a0.Parent = myRoot
            Carry.VisualAtt0 = a0

            local a1 = Instance.new("Attachment")
            a1.Name = "BSS_CarryAtt1"
            a1.Parent = tRoot
            Carry.VisualAtt1 = a1

            local beam = Instance.new("Beam")
            beam.Name = "BSS_CarryBeam"
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.Width0 = 0.16
            beam.Width1 = 0.16
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.Color = ColorSequence.new(Theme.Accent, Color3.fromRGB(255, 224, 120))
            beam.Transparency = NumberSequence.new(0.25)
            beam.Parent = myRoot
            Carry.VisualBeam = beam
        elseif Carry.VisualAtt1 and Carry.VisualAtt1.Parent ~= tRoot then
            Carry.VisualAtt1.Parent = tRoot
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
        Carry.TargetHL.Enabled = true
    end

    function Carry.StopAnimation()
        if Carry.AnimTrack then
            pcall(function() Carry.AnimTrack:Stop(0.2) end)
            pcall(function() Carry.AnimTrack:Destroy() end)
            Carry.AnimTrack = nil
        end
    end

    function Carry.PlayReplicatedPose(hum)
        Carry.StopAnimation()
        if not hum then return end
        local animator = Utils.GetAnimator(hum)
        if not animator then return end

        local anim = Instance.new("Animation")
        if hum.RigType == Enum.HumanoidRigType.R15 then
            anim.AnimationId = "rbxassetid://3333499508"
        else
            anim.AnimationId = "rbxassetid://180435571"
        end

        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if ok and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play(0.2)
            track:AdjustSpeed(0.05)
            Carry.AnimTrack = track
        end
    end

    function Carry.ScanCarryRemotes()
        if Carry.CarryRemoteScanned then return end
        Carry.CarryRemoteScanned = true
        table.clear(Carry.CarryRemoteCache)
        local keywords = { "carry", "gendong", "angkat", "grab", "pick", "hold", "hug", "peluk", "piggy" }
        for _, container in ipairs({ ReplicatedStorage, LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer and LocalPlayer.Character }) do
            if container then
                for _, desc in ipairs(container:GetDescendants()) do
                    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                        local rn = string.lower(desc.Name)
                        for _, kw in ipairs(keywords) do
                            if string.find(rn, kw, 1, true) then
                                table.insert(Carry.CarryRemoteCache, desc)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    function Carry.TryNativeMapCarry(targetPlr)
        if not targetPlr or not targetPlr.Character then return end
        local tChar = targetPlr.Character

        for _, desc in ipairs(tChar:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local txt = string.lower((desc.ActionText or "") .. " " .. (desc.ObjectText or "") .. " " .. desc.Name)
                if string.find(txt, "carry") or string.find(txt, "gendong") or string.find(txt, "angkat") or string.find(txt, "grab") or string.find(txt, "pick") or string.find(txt, "hug") then
                    if typeof(fireproximityprompt) == "function" then
                        pcall(fireproximityprompt, desc)
                    else
                        pcall(function()
                            desc:InputHoldBegin()
                            task.delay(math.max(0.05, desc.HoldDuration or 0.1), function()
                                pcall(function() desc:InputHoldEnd() end)
                            end)
                        end)
                    end
                    Carry.NativePromptTriggered = true
                end
            end
        end

        Carry.ScanCarryRemotes()
        for _, rem in ipairs(Carry.CarryRemoteCache) do
            if rem and rem.Parent and rem:IsA("RemoteEvent") then
                pcall(function() rem:FireServer(targetPlr) end)
                pcall(function() rem:FireServer(targetPlr.Name) end)
                pcall(function() rem:FireServer("Carry", targetPlr) end)
            end
        end
    end

    function Carry.Start(targetPlr)
        if not targetPlr or targetPlr == LocalPlayer then
            Utils.Notify("Gendong Pemain", "Pilih pemain target yang valid terlebih dahulu.", Theme.Warning)
            return false
        end
        local _, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        local tChar, _, tRoot = Utils.GetCharacter(targetPlr)
        if not myHum or not myRoot or not tChar or not tRoot then
            Utils.Notify("Gendong Pemain", "Karakter kamu atau target belum muncul di map.", Theme.Warning)
            return false
        end

        Carry.Enabled = true
        Carry.TargetPlayer = targetPlr
        Carry.NativePromptTriggered = false

        Carry.TryNativeMapCarry(targetPlr)
        Carry.PlayReplicatedPose(myHum)
        FeatureAPI.Sync("CarryPlayer", true)
        FeatureAPI.Emit("CarryStarted", targetPlr, Carry.Style)

        Utils.Notify(
            "Mode Gendong Aktif",
            string.format("Menggendong %s (Gaya: %s)", targetPlr.DisplayName, Carry.Style),
            Theme.Success
        )
        return true
    end

    function Carry.Stop()
        Carry.Enabled = false
        Carry.StopAnimation()
        Carry.CleanupVisuals()
        FeatureAPI.Sync("CarryPlayer", false)
        FeatureAPI.Emit("CarryStopped")

        local _, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        if myHum then
            myHum.PlatformStand = false
            myHum.AutoRotate = true
        end
        if myRoot then
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end

    function Carry.Step()
        if not Carry.Enabled then return end
        local targetPlr = Carry.TargetPlayer
        if not targetPlr or not targetPlr.Parent then
            Carry.Stop()
            return
        end

        local myChar, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        local tChar, tHum, tRoot = Utils.GetCharacter(targetPlr)
        if not myChar or not myHum or myHum.Health <= 0 or not myRoot or not tChar or not tHum or tHum.Health <= 0 or not tRoot then
            Carry.CleanupVisuals()
            return
        end

        Carry.UpdateVisuals(myRoot, tChar, tRoot)

        local attachOffset = CFrame.new(0, 0.55, -1.35)
        if Carry.Style == "Punggung" then
            attachOffset = CFrame.new(0, 0.85, 1.35)
        elseif Carry.Style == "Bahu" then
            attachOffset = CFrame.new(1.15, 1.45, 0.15) * CFrame.Angles(0, 0, math.rad(82))
        elseif Carry.Style == "Kepala" then
            attachOffset = CFrame.new(0, 3.15, 0)
        end

        local desiredRootCF = tRoot.CFrame * attachOffset:Inverse()
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        myRoot.CFrame = myRoot.CFrame:Lerp(desiredRootCF, 0.65)
    end
end

-- ============================================================================
-- 14. INTERACTIVE REPLICATED R6 & R15 DANCE / EMOTE STUDIO
-- ============================================================================
do
    Emotes.Catalog = {
        { Name = "Dance 1 (Klasik)", R6 = "182435998", R15 = "507771019" },
        { Name = "Dance 2 (Groove)", R6 = "182436842", R15 = "507776043" },
        { Name = "Dance 3 (Pop)",    R6 = "182436935", R15 = "507777268" },
        { Name = "Wave (Sapa)",      R6 = "128777973", R15 = "507770239" },
        { Name = "Cheer (Sorak)",    R6 = "129423030", R15 = "507770677" },
        { Name = "Point (Tunjuk)",   R6 = "128853357", R15 = "507770453" },
        { Name = "Laugh (Tertawa)",  R6 = "129423131", R15 = "507770818" },
        { Name = "Hero Float",       R6 = "180436148", R15 = "3333499508" },
        { Name = "Robot / Tilt",     R6 = "180435792", R15 = "3338025566" },
    }

    function Emotes.Stop()
        Emotes.Playing = false
        Emotes.CurrentDance = nil
        FeatureAPI.Sync("EmotePlayer", false)
        FeatureAPI.Emit("EmoteStopped")
        if Emotes.ActiveTrack then
            pcall(function() Emotes.ActiveTrack:Stop(0.2) end)
            pcall(function() Emotes.ActiveTrack:Destroy() end)
            Emotes.ActiveTrack = nil
        end
    end

    function Emotes.Play(entryOrId, customName)
        local _, hum = Utils.GetCharacter(LocalPlayer)
        if not hum then
            Utils.Notify("Tari & Emote", "Karakter kamu belum siap.", Theme.Warning)
            return false
        end

        Emotes.Stop()
        local animator = Utils.GetAnimator(hum)
        if not animator then return false end

        local animId = ""
        local labelName = customName or "Custom Emote"

        if type(entryOrId) == "table" then
            labelName = entryOrId.Name
            if hum.RigType == Enum.HumanoidRigType.R15 then
                animId = entryOrId.R15
            else
                animId = entryOrId.R6
            end
        else
            animId = tostring(entryOrId):gsub("%D", "")
        end

        if animId == "" then
            Utils.Notify("Tari & Emote", "ID Animasi tidak valid.", Theme.Danger)
            return false
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. animId

        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)

        if ok and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play(0.2)
            track:AdjustSpeed(Emotes.Speed)
            Emotes.ActiveTrack = track
            Emotes.Playing = true
            Emotes.CurrentDance = labelName
            Emotes.CurrentId = animId
            FeatureAPI.Sync("EmotePlayer", true)
            FeatureAPI.Emit("EmoteStarted", labelName, animId)
            Utils.Notify("Emote Aktif", string.format("Memutar: %s (ID: %s)", labelName, animId), Theme.Success)
            return true
        else
            Utils.Notify("Tari & Emote", "Map ini memblokir asset animasi eksternal.", Theme.Warning)
            return false
        end
    end
end

-- ============================================================================
-- 15. PROTECTION & SURVIVAL ENGINE (Anti-AFK, Melee Immunity, Hunger/Thirst Guard)
-- ============================================================================
do
    if LocalPlayer then
        Utils.Track(LocalPlayer.Idled:Connect(function()
            if Protection.AntiAFKEnabled and VirtualUser then
                Protection.IdleEventsHandled = Protection.IdleEventsHandled + 1
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end))
    end

    local pruneTick = 0
    function Protection.StepMeleeImmunity()
        if not Combat.MeleeImmunity then
            if next(Combat.TouchedPartsCache) ~= nil then
                for part, origTouch in pairs(Combat.TouchedPartsCache) do
                    if part and part.Parent and part:IsA("BasePart") then
                        part.CanTouch = origTouch
                    end
                end
                table.clear(Combat.TouchedPartsCache)
            end
            return
        end

        pruneTick = pruneTick + 1
        if pruneTick >= 30 then
            pruneTick = 0
            for part, _ in pairs(Combat.TouchedPartsCache) do
                if not part or not part.Parent then
                    Combat.TouchedPartsCache[part] = nil
                end
            end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                for _, item in ipairs(plr.Character:GetChildren()) do
                    if item:IsA("Tool") then
                        for _, desc in ipairs(item:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                if Combat.TouchedPartsCache[desc] == nil then
                                    Combat.TouchedPartsCache[desc] = desc.CanTouch
                                end
                                desc.CanTouch = false
                            end
                        end
                    end
                end
            end
        end
    end

    function Protection.StepHungerThirstGuard()
        if not Combat.HungerThirstGuard then return end

        local statKeywords = { "hunger", "thirst", "stamina", "energy", "lapar", "haus", "food", "water", "saturation", "hydrate" }
        local containers = { LocalPlayer, LocalPlayer and LocalPlayer.Character }

        for _, root in ipairs(containers) do
            if root then
                for _, desc in ipairs(root:GetDescendants()) do
                    if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                        local lower = string.lower(desc.Name)
                        for _, kw in ipairs(statKeywords) do
                            if string.find(lower, kw, 1, true) then
                                local prev = Protection.HungerThirstValues[desc]
                                if prev == nil or desc.Value > prev then
                                    Protection.HungerThirstValues[desc] = desc.Value
                                elseif desc.Value < prev then
                                    desc.Value = prev
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- 15B. SECURITY HUB ENGINE (Anti-Cheat Monitor, Log Diagnostik & Pemindai Zona)
-- ============================================================================
do
    local function pushBoundedLog(list, text)
        local stamp = os.date("%H:%M:%S")
        local formatted = string.format("[%s] %s", stamp, tostring(text))
        table.insert(list, 1, formatted)
        if #list > SecurityHub.MaxLogs then
            table.remove(list)
        end
        return formatted
    end

    function SecurityHub.AddViolation(reason, detail)
        local msg = string.format("%s — %s", tostring(reason), tostring(detail))
        pushBoundedLog(SecurityHub.ViolationLogs, msg)
        if type(SecurityHub.OnViolationAdded) == "function" then
            pcall(SecurityHub.OnViolationAdded, SecurityHub.ViolationLogs)
        end
    end

    function SecurityHub.AddConsoleLog(msgType, message)
        if not SecurityHub.LogCaptureEnabled then return end
        local prefix = "INFO"
        if msgType == Enum.MessageType.MessageWarning then
            prefix = "WARN"
        elseif msgType == Enum.MessageType.MessageError then
            prefix = "ERR"
        end
        pushBoundedLog(SecurityHub.ConsoleLogs, string.format("[%s] %s", prefix, tostring(message)))
        if type(SecurityHub.OnConsoleLogAdded) == "function" then
            pcall(SecurityHub.OnConsoleLogAdded, SecurityHub.ConsoleLogs)
        end
    end

    pcall(function()
        Utils.Track(LogService.MessageOut:Connect(function(message, messageType)
            if messageType == Enum.MessageType.MessageWarning or messageType == Enum.MessageType.MessageError then
                SecurityHub.AddConsoleLog(messageType, message)
            end
        end))
    end)

    function SecurityHub.ConnectRemotes()
        local folder = ReplicatedStorage:FindFirstChild("BimSakSinAdminRemotes")
        if folder then
            local tRem = folder:FindFirstChild("SecurityTelemetry")
            local aRem = folder:FindFirstChild("AdminAction")
            if tRem and tRem:IsA("RemoteEvent") then
                SecurityHub.TelemetryRemote = tRem
                SecurityHub.ServerConnected = true
                Utils.Track(tRem.OnClientEvent:Connect(function(payload)
                    if type(payload) == "table" then
                        SecurityHub.AddViolation(payload.Reason or "ServerAlert", payload.Detail or "Pelanggaran terdeteksi")
                    else
                        SecurityHub.AddViolation("ServerAlert", tostring(payload))
                    end
                end))
            end
            if aRem and aRem:IsA("RemoteEvent") then
                SecurityHub.AdminActionRemote = aRem
            end
        end
    end
    SecurityHub.ConnectRemotes()

    function SecurityHub.SendAdminAction(actionName, targetArg)
        if SecurityHub.AdminActionRemote and SecurityHub.AdminActionRemote.Parent then
            pcall(function()
                SecurityHub.AdminActionRemote:FireServer(actionName, targetArg)
            end)
            Utils.Notify("Admin Server", "Perintah dikirim: " .. tostring(actionName), Theme.Success)
            return true
        end
        Utils.Notify(
            "Mode Klien Mandiri",
            LocaleEngine.Text(
                "Map ini belum memasang Remote Server BimSakSin; aksi dijalankan di sisi klien.",
                "Server remote not present in this map; running client-side fallback."
            ),
            Theme.Warning
        )
        return false
    end

    local lastZoneScan = 0
    local zoneKeywords = {
        { key = "safe", label = "Zona Aman (SafeZone)" },
        { key = "lobby", label = "Area Lobi (Lobby)" },
        { key = "spawn", label = "Titik Spawn" },
        { key = "vip", label = "Area Khusus VIP" },
        { key = "admin", label = "Area Terbatas Admin" },
        { key = "pvp", label = "Zona Pertarungan (PvP)" },
        { key = "shop", label = "Area Toko / Pasar" },
    }

    function SecurityHub.StepZoneScanner()
        if not SecurityHub.ZoneScannerEnabled then return end
        local now = os.clock()
        if (now - lastZoneScan) < 0.75 then return end
        lastZoneScan = now

        local _, _, root = Utils.GetCharacter(LocalPlayer)
        if not root then return end

        local detected = "Area Umum (Normal)"
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character }

        local parts = workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(6, 8, 6), params)
        for _, p in ipairs(parts) do
            local fullName = string.lower(p:GetFullName())
            for _, z in ipairs(zoneKeywords) do
                if string.find(fullName, z.key, 1, true) then
                    detected = z.label
                    break
                end
            end
            if detected ~= "Area Umum (Normal)" then
                break
            end
        end

        if detected ~= SecurityHub.CurrentZoneName then
            SecurityHub.CurrentZoneName = detected
            if type(SecurityHub.OnZoneChanged) == "function" then
                pcall(SecurityHub.OnZoneChanged, detected)
            end
        end
    end

    function SecurityHub.RunIntegrityAudit()
        local _, hum, root = Utils.GetCharacter(LocalPlayer)
        local issues = 0
        if not hum or not root then
            issues = issues + 1
        else
            if hum.WalkSpeed > 80 and State.WalkSpeed <= 16 then
                issues = issues + 1
            end
            if root.Anchored and not State.IsTeleportLocking then
                issues = issues + 1
            end
        end
        local abStatus = AntiBan.Active and string.format("AntiBan v%s AKTIF (KickBlk:%d)", AntiBan.Version, AntiBan.Stats.KicksBlocked) or "AntiBan OFF"
        local summary = (issues == 0)
            and ("Audit Integritas: BERSIH (0 Anomali) | " .. abStatus)
            or string.format("Audit Integritas: %d Anomali | %s", issues, abStatus)
        SecurityHub.AddViolation("AuditKlien", summary)
        Utils.Notify("Audit Integritas", summary, issues == 0 and Theme.Success or Theme.Warning)
    end
end
-- ============================================================================
-- TAB 1: INFORMASI (Paling Atas — Profil Creator, Ringkasan Fitur & Komunitas)
-- ============================================================================
do
    local page = Components.CreateTab("Informasi", { id = "Informasi", en = "Information" }, "ℹ️", 1)

    local heroCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 128),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(heroCard, 11)
    local heroStroke = Utils.AddStroke(heroCard, Theme.Accent, 1.3, 0.2)
    Utils.RegisterAccent(heroStroke, "Color")

    Utils.CreatePumpkin3D(heroCard, 66, UDim2.new(0, 44, 0.5, 0), Vector2.new(0.5, 0.5), 16, true, false)

    local hTitle = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -104, 0, 22),
        Position = UDim2.new(0, 90, 0, 12),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "BimSakSin Hub v3.0 + Anti-Ban v3.1",
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterText(hTitle, true, Theme.TextPrimary)

    local hSub = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -104, 0, 56),
        Position = UDim2.new(0, 90, 0, 36),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = LocaleEngine.Text(
            "Creator: BimSakSin  |  Kompatibel Semua Map (R6 & R15)\nDilengkapi Universal Anti-Ban Framework v3.1 (Anti-Kick, Anti-Remote, Anti-Stats Scan & HWID Spoofer), Radar ESP, Auto Generator, Auto Parry, dan Salin Aset.",
            "Creator: BimSakSin  |  All-Map Compatible (R6 & R15)\nEquipped with Universal Anti-Ban Framework v3.1 (Anti-Kick, Anti-Remote, Anti-Stats Scan & HWID Spoofer), Radar ESP, Auto Generator, Auto Parry, and Asset Copier."
        ),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterText(hSub, false, Theme.TextSecondary)

    local hRegion = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -104, 0, 18),
        Position = UDim2.new(0, 90, 1, -24),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "🌍 Region: " .. LocaleEngine.RegionDisplay,
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterAccent(hRegion, "TextColor3")

    LocaleEngine.Bind(function()
        if hSub and hSub.Parent then
            hSub.Text = LocaleEngine.Text(
                "Creator: BimSakSin  |  Kompatibel Semua Map (R6 & R15)\nDilengkapi Universal Anti-Ban Framework v3.1 (Anti-Kick, Anti-Remote, Anti-Stats Scan & HWID Spoofer), Radar ESP, Auto Generator, Auto Parry, dan Salin Aset.",
                "Creator: BimSakSin  |  All-Map Compatible (R6 & R15)\nEquipped with Universal Anti-Ban Framework v3.1 (Anti-Kick, Anti-Remote, Anti-Stats Scan & HWID Spoofer), Radar ESP, Auto Generator, Auto Parry, and Asset Copier."
            )
        end
        if hRegion and hRegion.Parent then
            hRegion.Text = "🌍 Region: " .. LocaleEngine.RegionDisplay
        end
    end)

    Components.AddSectionHeader(page, { id = "Komunitas & Dukungan", en = "Community & Support" }, 2)

    Components.AddButton(
        page,
        { id = "Server Discord Resmi", en = "Official Discord Server" },
        { id = "Salin tautan undangan Discord BimSakSin", en = "Copy BimSakSin Discord invite link" },
        { id = "Salin Link", en = "Copy Link" },
        3,
        function()
            local ok = Utils.CopyText(App.DiscordUrl)
            Utils.Notify("Discord", ok and ("Tersalin: " .. App.DiscordUrl) or App.DiscordUrl, Theme.Success)
        end
    )

    Components.AddButton(
        page,
        { id = "Dukungan & Donasi Creator", en = "Support & Creator Donation" },
        { id = "Salin tautan Linktree dukungan BimSakSin", en = "Copy BimSakSin Linktree support URL" },
        { id = "Salin Link", en = "Copy Link" },
        4,
        function()
            local ok = Utils.CopyText(App.DonationUrl)
            Utils.Notify("Dukungan", ok and ("Tersalin: " .. App.DonationUrl) or App.DonationUrl, Theme.Success)
        end
    )

    Components.AddButton(
        page,
        { id = "Buka Command Palette (F2)", en = "Open Command Palette (F2)" },
        { id = "Cari & jalankan fitur apa pun secara instan", en = "Search and trigger any feature instantly" },
        { id = "Buka [F2]", en = "Open [F2]" },
        5,
        function()
            if UI.CommandPalette and UI.CommandPalette.Open then
                UI.CommandPalette.Open()
            end
        end
    )
end

-- ============================================================================
-- TAB 2: BERANDA (Telemetri Perangkat, Server & Utilitas Cepat)
-- ============================================================================
do
    local page = Components.CreateTab("Beranda", { id = "Beranda", en = "Dashboard" }, "🏠", 2)

    Components.AddSectionHeader(page, { id = "Telemetri Performa & Server", en = "Performance & Server Telemetry" }, 1)

    local telemetryGrid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 114),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.485, 0, 0, 52),
        CellPadding = UDim2.new(0.03, 0, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, telemetryGrid)

    local function makeStatBox(key, labelSpec, initVal, order)
        local box = Utils.Create("Frame", {
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 14,
        }, telemetryGrid)
        Utils.AddCorner(box, 9)
        Utils.AddStroke(box, Theme.BorderSubtle, 1, 0.3)

        local lTop = Utils.Create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 10, 0, 6),
            BackgroundTransparency = 1,
            Font = Theme.FontFamily,
            Text = resolveTextSpec(labelSpec),
            TextColor3 = Theme.TextSecondary,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterText(lTop, false, Theme.TextSecondary)

        LocaleEngine.Bind(function()
            if lTop and lTop.Parent then
                lTop.Text = resolveTextSpec(labelSpec)
            end
        end)

        local lVal = Utils.Create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 10, 0, 23),
            BackgroundTransparency = 1,
            Font = Theme.FontBold,
            Text = initVal,
            TextColor3 = Theme.Accent,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterAccent(lVal, "TextColor3")
        UI.TelemetryLabels[key] = lVal
    end

    makeStatBox("FPS", { id = "Frame Rate (FPS)", en = "Frame Rate (FPS)" }, "60 FPS", 1)
    makeStatBox("Ping", { id = "Latensi Jaringan", en = "Network Ping" }, "0 ms", 2)
    makeStatBox("Memory", { id = "Memori Klien", en = "Client Memory" }, "0 MB", 3)
    makeStatBox("Players", { id = "Pemain & Fitur Aktif", en = "Players & Active Mods" }, "1/1 | 0", 4)

    Components.AddSectionHeader(page, { id = "Utilitas Server & Koneksi", en = "Server & Connection Utilities" }, 3)

    Components.AddButton(
        page,
        { id = "Salin Place ID & Job ID", en = "Copy Place ID & Job ID" },
        { id = "Salin identitas server saat ini ke clipboard", en = "Copy current server identifiers to clipboard" },
        { id = "Salin ID", en = "Copy ID" },
        4,
        function()
            local info = string.format("PlaceId: %s | JobId: %s", tostring(game.PlaceId), tostring(game.JobId))
            Utils.CopyText(info)
            Utils.Notify("Server ID", info, Theme.Success)
        end
    )

    Components.AddButton(
        page,
        { id = "Gabung Ulang Server (Rejoin)", en = "Rejoin Current Server" },
        { id = "Masuk kembali ke server yang sama dengan cepat", en = "Reconnect back to the same server instance" },
        { id = "Rejoin", en = "Rejoin" },
        5,
        function()
            Utils.Notify("Rejoin", "Menghubungkan ulang ke server...", Theme.Warning)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end
    )
end

-- ============================================================================
-- TAB 3: RADAR ESP (Pemain, Barang/Loot, Generator & Auto Generator)
-- ============================================================================
do
    local page = Components.CreateTab("RadarESP", { id = "Radar ESP", en = "Radar ESP" }, "📡", 3)

    Components.AddSectionHeader(page, { id = "Radar ESP Pemain", en = "Player Radar ESP" }, 1)

    local espToggle = Components.AddToggle(
        page,
        { id = "Aktifkan ESP Pemain", en = "Enable Player ESP" },
        { id = "Menampilkan sorotan karakter, nama, jarak & darah pemain", en = "Displays character highlight, name, distance & health" },
        ESP.Enabled,
        2,
        function(val)
            ESP.Enabled = val
            FeatureAPI.Sync("PlayerESP", val)
            if not val then ESP.ClearAll() end
        end
    )

    FeatureAPI.Register("PlayerESP", {
        Category = "RadarESP",
        OnEnable = function() ESP.Enabled = true; espToggle.SetState(true, false) end,
        OnDisable = function() ESP.Enabled = false; ESP.ClearAll(); espToggle.SetState(false, false) end,
    })

    Components.AddChipSelector(
        page,
        { id = "Mode Filter Tim ESP", en = "ESP Team Filter Mode" },
        {
            { Label = { id = "Otomatis", en = "Auto" }, Value = "Auto" },
            { Label = { id = "Musuh", en = "Enemy" }, Value = "Enemy" },
            { Label = { id = "Teman", en = "Ally" }, Value = "Ally" },
            { Label = { id = "Acak RGB", en = "Random" }, Value = "Random" },
        },
        ESP.Mode,
        3,
        function(v) ESP.Mode = v end
    )

    Components.AddSlider(
        page,
        { id = "Jarak Maksimal ESP (Meter)", en = "Max ESP Distance (Meters)" },
        200, 10000, ESP.MaxDistance, 0, 4,
        function(v) ESP.MaxDistance = v end
    )

    Components.AddSectionHeader(page, { id = "Radar Barang & Generator", en = "Item & Generator Radar" }, 5)

    local itemEspToggle = Components.AddToggle(
        page,
        { id = "ESP Barang & Loot", en = "Item & Loot ESP" },
        { id = "Mendeteksi item jatuh, tool & objek interaktif di map", en = "Detects dropped items, tools & interactive objects" },
        ItemESP.Enabled,
        6,
        function(val)
            ItemESP.Enabled = val
            FeatureAPI.Sync("ItemESP", val)
            if not val then ItemESP.ClearAll() end
        end
    )

    FeatureAPI.Register("ItemESP", {
        Category = "RadarESP",
        OnEnable = function() ItemESP.Enabled = true; itemEspToggle.SetState(true, false) end,
        OnDisable = function() ItemESP.Enabled = false; ItemESP.ClearAll(); itemEspToggle.SetState(false, false) end,
    })

    local genEspToggle = Components.AddToggle(
        page,
        { id = "ESP Generator & Progres", en = "Generator & Progress ESP" },
        { id = "Menampilkan lokasi mesin/generator & persentase perbaikan", en = "Shows generator locations & live repair percentages" },
        GeneratorESP.Enabled,
        7,
        function(val)
            GeneratorESP.Enabled = val
            FeatureAPI.Sync("GeneratorESP", val)
            if not val then GeneratorESP.ClearAll() end
        end
    )

    FeatureAPI.Register("GeneratorESP", {
        Category = "RadarESP",
        OnEnable = function() GeneratorESP.Enabled = true; genEspToggle.SetState(true, false) end,
        OnDisable = function() GeneratorESP.Enabled = false; GeneratorESP.ClearAll(); genEspToggle.SetState(false, false) end,
    })

    Components.AddSectionHeader(page, { id = "Otomatisasi Generator (Map Distrik & Universal)", en = "Generator Automation" }, 8)

    local autoGenToggle = Components.AddToggle(
        page,
        { id = "Auto Generator (Teleport & Perbaiki)", en = "Auto Generator (Teleport & Repair)" },
        { id = "Otomatis menuju generator terdekat, berinteraksi & pindah saat 100%", en = "Automatically teleports to nearest generator, interacts & switches at 100%" },
        AutoGen.Enabled,
        9,
        function(val)
            AutoGen.Enabled = val
            FeatureAPI.Sync("AutoGenerator", val)
            if val then
                AutoGen.CurrentTarget = nil
                Utils.Notify("Auto Generator", "Memindai generator belum selesai di map...", Theme.Success)
            else
                AutoGen.StatusText = "Nonaktif"
            end
        end
    )

    FeatureAPI.Register("AutoGenerator", {
        Category = "RadarESP",
        OnEnable = function() AutoGen.Enabled = true; autoGenToggle.SetState(true, false) end,
        OnDisable = function() AutoGen.Enabled = false; AutoGen.CurrentTarget = nil; autoGenToggle.SetState(false, false) end,
    })

    Components.AddToggle(
        page,
        { id = "Auto Skill Check Generator", en = "Auto Generator Skill Check" },
        { id = "Menyelesaikan mini-game skill check generator secara otomatis", en = "Automatically completes generator skill check prompts" },
        AutoGen.AutoSkillCheck,
        10,
        function(val) AutoGen.AutoSkillCheck = val end
    )

    Components.AddButton(
        page,
        { id = "Pindai Semua Generator (GeneratorAPI)", en = "Scan All Generators (GeneratorAPI)" },
        { id = "Cek jumlah total, selesai, dan jarak generator terdekat", en = "Check total count, completed, and nearest generator distance" },
        { id = "Pindai", en = "Scan" },
        11,
        function()
            local stats = GeneratorAPI.GetStats()
            local nearestStr = stats.Nearest
                and string.format("%s (%d%% | %dm)", stats.Nearest.Name, stats.Nearest.Progress, stats.Nearest.Distance)
                or LocaleEngine.Text("Semua selesai / Tidak ada", "All complete / None")
            Utils.Notify(
                string.format("GeneratorAPI (%d/%d Selesai)", stats.Completed, stats.Total),
                LocaleEngine.Text("Terdekat: ", "Nearest: ") .. nearestStr,
                Theme.Accent
            )
        end
    )
end

-- ============================================================================
-- TAB 4: PERTARUNGAN (Aimbot, RGB Laser, Auto Parry & Ketahanan)
-- ============================================================================
do
    local page = Components.CreateTab("Pertarungan", { id = "Pertarungan", en = "Combat" }, "⚔️", 4)

    Components.AddSectionHeader(page, { id = "Bidik Otomatis & Laser", en = "Auto Aimbot & Laser" }, 1)

    local aimToggle = Components.AddToggle(
        page,
        { id = "Aktifkan Aimbot Kamera", en = "Enable Camera Aimbot" },
        { id = "Mengunci kamera ke target musuh dalam lingkaran FOV", en = "Locks camera onto enemy target within FOV radius" },
        Combat.AimbotEnabled,
        2,
        function(val)
            Combat.AimbotEnabled = val
            FeatureAPI.Sync("Aimbot", val)
            if not val then Combat.HideLaser() end
        end
    )

    FeatureAPI.Register("Aimbot", {
        Category = "Pertarungan",
        OnEnable = function() Combat.AimbotEnabled = true; aimToggle.SetState(true, false) end,
        OnDisable = function() Combat.AimbotEnabled = false; Combat.HideLaser(); aimToggle.SetState(false, false) end,
    })

    Components.AddChipSelector(
        page,
        { id = "Mode Aktivasi & Bagian Target", en = "Activation Mode & Target Part" },
        {
            { Label = { id = "Senjata (Auto)", en = "Weapon Auto" }, Value = "Auto" },
            { Label = { id = "Selalu Aktif", en = "Always On" }, Value = "Always" },
            { Label = { id = "Kepala (Head)", en = "Head" }, Value = "Head" },
            { Label = { id = "Terdekat", en = "Closest" }, Value = "Closest" },
        },
        Combat.AimbotMode,
        3,
        function(v)
            if v == "Head" or v == "Closest" then
                Combat.AimPart = v
            else
                Combat.AimbotMode = v
            end
        end
    )

    Components.AddToggle(
        page,
        { id = "Lingkaran FOV & Laser RGB", en = "FOV Circle & RGB Laser" },
        { id = "Tampilkan indikator radius FOV serta garis laser RGB ke target", en = "Display FOV circle overlay and RGB laser beam to target" },
        Combat.ShowFOVCircle,
        4,
        function(val)
            Combat.ShowFOVCircle = val
            Combat.RGBLaserEnabled = val
        end
    )

    Components.AddSlider(
        page,
        { id = "Radius FOV Aimbot (Px)", en = "Aimbot FOV Radius (Px)" },
        60, 600, Combat.FOVRadius, 0, 5,
        function(v) Combat.FOVRadius = v end
    )

    Components.AddSlider(
        page,
        { id = "Kehalusan Bidikan (Smoothness)", en = "Aim Smoothness" },
        0.1, 1.0, Combat.Smoothness, 2, 6,
        function(v) Combat.Smoothness = v end
    )

    Components.AddSectionHeader(page, { id = "Auto Parry & Ketahanan", en = "Auto Parry & Survivability" }, 7)

    local parryToggle = Components.AddToggle(
        page,
        { id = "Auto Parry / Tangkis Otomatis", en = "Auto Parry / Deflect" },
        { id = "Mendeteksi animasi serangan jarak dekat & proyektil masuk", en = "Detects incoming melee swing animations & projectiles" },
        Combat.AutoParryEnabled,
        8,
        function(val)
            Combat.AutoParryEnabled = val
            FeatureAPI.Sync("AutoParry", val)
            if not val then Combat.CleanupParryVisuals() end
        end
    )

    FeatureAPI.Register("AutoParry", {
        Category = "Pertarungan",
        OnEnable = function() Combat.AutoParryEnabled = true; parryToggle.SetState(true, false) end,
        OnDisable = function() Combat.AutoParryEnabled = false; Combat.CleanupParryVisuals(); parryToggle.SetState(false, false) end,
    })

    Components.AddSlider(
        page,
        { id = "Jarak Deteksi Auto Parry (Studs)", en = "Auto Parry Detection Range" },
        6, 40, Combat.ParryRange, 0, 9,
        function(v) Combat.ParryRange = v end
    )

    Components.AddToggle(
        page,
        { id = "Kebal Sentuhan Senjata Melee", en = "Melee Tool Touch Immunity" },
        { id = "Menonaktifkan CanTouch pada senjata melee milik pemain lain", en = "Disables CanTouch on other players' melee tools" },
        Combat.MeleeImmunity,
        10,
        function(val) Combat.MeleeImmunity = val end
    )

    Components.AddToggle(
        page,
        { id = "Kunci Lapar, Haus & Stamina", en = "Lock Hunger, Thirst & Stamina" },
        { id = "Mencegah penurunan nilai Hunger, Thirst, dan Stamina karakter", en = "Prevents Hunger, Thirst, and Stamina values from decreasing" },
        Combat.HungerThirstGuard,
        11,
        function(val) Combat.HungerThirstGuard = val end
    )
end

-- ============================================================================
-- TAB 5: PERGERAKAN (Kecepatan, Lompatan, Terbang & Noclip)
-- ============================================================================
do
    local page = Components.CreateTab("Pergerakan", { id = "Pergerakan", en = "Movement" }, "🏃", 5)

    Components.AddSectionHeader(page, { id = "Modifikasi Kecepatan & Lompatan", en = "Speed & Jump Modification" }, 1)

    Components.AddSlider(
        page,
        { id = "Kecepatan Jalan (WalkSpeed)", en = "WalkSpeed" },
        16, 250, State.WalkSpeed, 0, 2,
        function(v)
            State.WalkSpeed = v
            local _, hum = Utils.GetCharacter()
            if hum then hum.WalkSpeed = v end
        end
    )

    Components.AddSlider(
        page,
        { id = "Kekuatan Lompat (JumpPower)", en = "JumpPower" },
        50, 300, State.JumpPower, 0, 3,
        function(v)
            State.JumpPower = v
            local _, hum = Utils.GetCharacter()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = v
            end
        end
    )

    Components.AddSlider(
        page,
        { id = "Gravitasi Dunia (Gravity)", en = "World Gravity" },
        10, 300, State.Gravity, 0, 4,
        function(v)
            State.Gravity = v
            workspace.Gravity = v
        end
    )

    Components.AddSectionHeader(page, { id = "Terbang & Tembus Objek", en = "Flight & Noclip" }, 5)

    local flyToggle = Components.AddToggle(
        page,
        { id = "Terbang Bebas (Smooth Admin Fly)", en = "Smooth Admin Flight" },
        { id = "Gunakan WASD / Analog & Spasi / Ctrl untuk terbang halus", en = "Use WASD / Thumbstick & Space / Ctrl to fly smoothly" },
        State.FlyEnabled,
        6,
        function(val)
            State.FlyEnabled = val
            FeatureAPI.Sync("Fly", val)
            if not val then Physics.CleanupFly() end
        end
    )

    FeatureAPI.Register("Fly", {
        Category = "Pergerakan",
        OnEnable = function() State.FlyEnabled = true; flyToggle.SetState(true, false) end,
        OnDisable = function() State.FlyEnabled = false; Physics.CleanupFly(); flyToggle.SetState(false, false) end,
    })

    Components.AddSlider(
        page,
        { id = "Kecepatan Terbang (FlySpeed)", en = "Flight Speed" },
        20, 250, State.FlySpeed, 0, 7,
        function(v) State.FlySpeed = v end
    )

    local noclipToggle = Components.AddToggle(
        page,
        { id = "Tembus Dinding (Noclip)", en = "Noclip (Walk Through Walls)" },
        { id = "Menonaktifkan kolisi fisik tubuh agar dapat menembus rintangan", en = "Disables character collision to pass through obstacles" },
        State.NoclipEnabled,
        8,
        function(val)
            State.NoclipEnabled = val
            FeatureAPI.Sync("Noclip", val)
            if not val then Physics.RestoreNoclip() end
        end
    )

    FeatureAPI.Register("Noclip", {
        Category = "Pergerakan",
        OnEnable = function() State.NoclipEnabled = true; noclipToggle.SetState(true, false) end,
        OnDisable = function() State.NoclipEnabled = false; Physics.RestoreNoclip(); noclipToggle.SetState(false, false) end,
    })

    Components.AddToggle(
        page,
        { id = "Lompat Tanpa Batas (Infinite Jump)", en = "Infinite Jump" },
        { id = "Memungkinkan melompat berulang kali di udara", en = "Allows jumping repeatedly mid-air" },
        State.InfiniteJumpEnabled,
        9,
        function(val) State.InfiniteJumpEnabled = val end
    )
end

-- ============================================================================
-- TAB 6: TELEPORTASI (Koordinat, Titik Simpan & Teleport Pemain)
-- ============================================================================
do
    local page = Components.CreateTab("Teleportasi", { id = "Teleportasi", en = "Teleport" }, "🧭", 6)

    Components.AddSectionHeader(page, { id = "Koordinat & Titik Simpan", en = "Coordinates & Saved Waypoints" }, 1)

    local coordCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(coordCard, 9)
    Utils.AddStroke(coordCard, Theme.BorderSubtle, 1, 0.3)

    local coordLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "Posisi: X: 0 | Y: 0 | Z: 0",
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, coordCard)
    Utils.RegisterAccent(coordLbl, "TextColor3")
    UI.TelemetryLabels.Coords = coordLbl

    Components.AddButton(
        page,
        { id = "Simpan Titik Lokasi (Waypoint)", en = "Save Current Waypoint" },
        { id = "Menyimpan koordinat CFrame saat ini untuk teleport cepat", en = "Saves current CFrame coordinates for quick return" },
        { id = "Simpan", en = "Save" },
        3,
        function()
            local _, _, root = Utils.GetCharacter()
            if not root then
                Utils.Notify("Teleportasi", "Karakter tidak ditemukan.", Theme.Warning)
                return
            end
            State.Waypoints["TitikUtama"] = root.CFrame
            Utils.Notify("Waypoint Disimpan", string.format("X:%.0f Y:%.0f Z:%.0f", root.Position.X, root.Position.Y, root.Position.Z), Theme.Success)
        end
    )

    Components.AddButton(
        page,
        { id = "Kembali ke Titik Simpan", en = "Teleport to Saved Waypoint" },
        { id = "Berpindah secara aman ke koordinat yang telah disimpan", en = "Safely teleports back to your saved coordinates" },
        { id = "Teleport", en = "Teleport" },
        4,
        function()
            local wp = State.Waypoints["TitikUtama"]
            if not wp then
                Utils.Notify("Teleportasi", "Belum ada titik lokasi yang disimpan.", Theme.Warning)
                return
            end
            Utils.SafeTeleport(wp)
            Utils.Notify("Teleportasi", "Berhasil berpindah ke titik simpan.", Theme.Success)
        end
    )

    Components.AddSectionHeader(page, { id = "Teleportasi ke Pemain", en = "Teleport to Player" }, 5)

    local plrInputBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.2,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Ketik nama / display name pemain tujuan...", "Type target player username or display name..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(plrInputBox, 8)
    Utils.AddStroke(plrInputBox, Theme.BorderSubtle, 1, 0.3)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, plrInputBox)

    local function findPlayerByPartial(query)
        local q = string.lower(string.match(query or "", "^%s*(.-)%s*$"))
        if q == "" then return nil end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if string.find(string.lower(plr.Name), q, 1, true) or string.find(string.lower(plr.DisplayName), q, 1, true) then
                    return plr
                end
            end
        end
        return nil
    end

    Components.AddButton(
        page,
        { id = "Teleport ke Pemain Target", en = "Teleport to Target Player" },
        { id = "Pindah langsung ke posisi pemain yang diketik di atas", en = "Instantly move to the player typed above" },
        { id = "Menuju", en = "Go To" },
        7,
        function()
            local target = findPlayerByPartial(plrInputBox.Text)
            if not target then
                Utils.Notify("Teleportasi", "Pemain tidak ditemukan di server.", Theme.Warning)
                return
            end
            local _, _, tRoot = Utils.GetCharacter(target)
            if not tRoot then
                Utils.Notify("Teleportasi", "Karakter target belum spawn.", Theme.Warning)
                return
            end
            Utils.SafeTeleport(tRoot.CFrame * CFrame.new(0, 1.5, 2.5))
            Utils.Notify("Teleportasi", "Berpindah ke: " .. target.DisplayName, Theme.Success)
        end
    )
end

-- ============================================================================
-- TAB 7: GENDONG (Interaksi Carry & Pilihan Gaya)
-- ============================================================================
do
    local page = Components.CreateTab("Gendong", { id = "Gendong", en = "Carry" }, "🫂", 7)

    Components.AddSectionHeader(page, { id = "Kontrol Gendong Pemain", en = "Player Carry Controls" }, 1)

    local carryInput = Utils.Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.2,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Ketik nama pemain yang ingin digendong...", "Type player name to carry..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(carryInput, 8)
    Utils.AddStroke(carryInput, Theme.BorderSubtle, 1, 0.3)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, carryInput)

    Components.AddChipSelector(
        page,
        { id = "Pilih Gaya Gendong", en = "Select Carry Style" },
        {
            { Label = { id = "Depan", en = "Front" }, Value = "Depan" },
            { Label = { id = "Punggung", en = "Back" }, Value = "Punggung" },
            { Label = { id = "Bahu", en = "Shoulder" }, Value = "Bahu" },
            { Label = { id = "Kepala", en = "Head" }, Value = "Kepala" },
        },
        Carry.Style,
        3,
        function(v) Carry.Style = v end
    )

    Components.AddButton(
        page,
        { id = "Mulai Gendong Target", en = "Start Carrying Target" },
        { id = "Menempel dan memicu interaksi gendong pada pemain tujuan", en = "Attaches and triggers carry interaction on target player" },
        { id = "Gendong", en = "Carry" },
        4,
        function()
            local q = string.lower(string.match(carryInput.Text or "", "^%s*(.-)%s*$"))
            local target = nil
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    if q == "" or string.find(string.lower(plr.Name), q, 1, true) or string.find(string.lower(plr.DisplayName), q, 1, true) then
                        target = plr
                        break
                    end
                end
            end
            Carry.Start(target)
        end
    )

    Components.AddButton(
        page,
        { id = "Lepaskan Gendongan", en = "Stop Carrying" },
        { id = "Menghentikan mode gendong dan memulihkan posisi karakter", en = "Stops carry mode and restores character movement" },
        { id = "Lepas", en = "Release" },
        5,
        function()
            Carry.Stop()
            Utils.Notify("Gendong", "Mode gendong dihentikan.", Theme.Success)
        end
    )
end

-- ============================================================================
-- TAB 8: TARI & EMOTE (Animasi Replikasi R6/R15 & ID Kustom)
-- ============================================================================
do
    local page = Components.CreateTab("TariEmote", { id = "Tari & Emote", en = "Dance & Emote" }, "💃", 8)

    Components.AddSectionHeader(page, { id = "Pengaturan Pemutar Emote", en = "Emote Player Controls" }, 1)

    Components.AddSlider(
        page,
        { id = "Kecepatan Animasi Emote", en = "Emote Animation Speed" },
        0.2, 3.0, Emotes.Speed, 1, 2,
        function(v)
            Emotes.Speed = v
            if Emotes.ActiveTrack then
                pcall(function() Emotes.ActiveTrack:AdjustSpeed(v) end)
            end
        end
    )

    Components.AddButton(
        page,
        { id = "Hentikan Semua Tari / Emote", en = "Stop All Dances / Emotes" },
        { id = "Menghentikan animasi yang sedang diputar", en = "Stops currently playing animation track" },
        { id = "Stop", en = "Stop" },
        3,
        function()
            Emotes.Stop()
            Utils.Notify("Emote", "Animasi dihentikan.", Theme.Success)
        end
    )

    Components.AddSectionHeader(page, { id = "Katalog Animasi R6 & R15", en = "R6 & R15 Animation Catalog" }, 4)

    for idx, entry in ipairs(Emotes.Catalog) do
        Components.AddButton(
            page,
            entry.Name,
            string.format("R6: %s  |  R15: %s", entry.R6, entry.R15),
            { id = "Putar", en = "Play" },
            4 + idx,
            function()
                Emotes.Play(entry)
            end
        )
    end
end

-- ============================================================================
-- TAB 9: VISUAL (Kamera FOV, Fullbright & Hapus Kabut)
-- ============================================================================
do
    local page = Components.CreateTab("Visual", { id = "Visual", en = "Visuals" }, "👁️", 9)

    Components.AddSectionHeader(page, { id = "Kamera & Pencahayaan Dunia", en = "Camera & World Lighting" }, 1)

    Components.AddSlider(
        page,
        { id = "Sudut Pandang Kamera (FOV)", en = "Camera Field of View (FOV)" },
        40, 120, State.CameraFOV, 0, 2,
        function(v)
            State.CameraFOV = v
            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = v
            end
        end
    )

    UI.FullbrightToggle = Components.AddToggle(
        page,
        { id = "Penerangan Penuh (Fullbright)", en = "Fullbright Lighting" },
        { id = "Menghilangkan area gelap dan bayangan berat di seluruh map", en = "Removes dark areas and heavy shadows across the map" },
        State.FullbrightEnabled,
        3,
        function(val)
            State.FullbrightEnabled = val
            if not val then
                Lighting.Brightness = State.OriginalLighting.Brightness
                Lighting.ClockTime = State.OriginalLighting.ClockTime
                Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
                Lighting.Ambient = State.OriginalLighting.Ambient
                Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
            end
        end
    )

    UI.NoFogToggle = Components.AddToggle(
        page,
        { id = "Hapus Kabut & Atmosfer (No Fog)", en = "Remove Fog & Atmosphere" },
        { id = "Memperluas jarak pandang dengan menghapus kabut tebal", en = "Extends visibility by clearing dense fog" },
        State.NoFogEnabled,
        4,
        function(val)
            State.NoFogEnabled = val
            if not val then
                Lighting.FogEnd = State.OriginalLighting.FogEnd
                Lighting.FogStart = State.OriginalLighting.FogStart
                if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance and State.OriginalAtmosphere.Instance.Parent then
                    State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
                end
            end
        end
    )
end

-- ============================================================================
-- TAB 10: SALIN ASET (Ekspor Item/Map ke Luau/JSON & Notifikasi Telegram)
-- ============================================================================
do
    local page = Components.CreateTab("SalinAset", { id = "Salin Aset", en = "Asset Copier" }, "📦", 10)

    Components.AddSectionHeader(page, { id = "Konfigurasi Ekspor Item & Map", en = "Item & Map Export Config" }, 1)

    local filterBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.2,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Filter nama objek/item (kosongkan = otomatis terdekat)...", "Filter object/item name (leave empty = auto nearest)..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = AssetCopy.TargetFilter,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(filterBox, 8)
    Utils.AddStroke(filterBox, Theme.BorderSubtle, 1, 0.3)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, filterBox)
    filterBox.FocusLost:Connect(function()
        AssetCopy.TargetFilter = filterBox.Text
    end)

    Components.AddChipSelector(
        page,
        { id = "Cakupan & Format Ekspor", en = "Export Scope & Format" },
        {
            { Label = { id = "Terdekat/Tool", en = "Nearest/Tool" }, Value = "EquippedOrNearest" },
            { Label = { id = "Semua Tool", en = "All Tools" }, Value = "AllTools" },
            { Label = { id = "Seluruh Map", en = "Full Map" }, Value = "FullMap" },
            { Label = "Luau + JSON", Value = "LuauAndJSON" },
            { Label = "Luau (.lua)", Value = "LuauOnly" },
            { Label = "JSON (.json)", Value = "JSONOnly" },
        },
        AssetCopy.CopyScope,
        3,
        function(v)
            if v == "LuauAndJSON" or v == "LuauOnly" or v == "JSONOnly" then
                AssetCopy.FormatMode = v
            else
                AssetCopy.CopyScope = v
            end
        end
    )

    Components.AddButton(
        page,
        { id = "Salin & Ekspor Aset Sekarang", en = "Copy & Export Asset Now" },
        { id = "Menyimpan struktur objek ke folder executor + kirim Telegram", en = "Saves serialized object to executor folder + sends Telegram" },
        { id = "Ekspor", en = "Export" },
        4,
        function()
            AssetCopy.TargetFilter = filterBox.Text
            AssetCopy.ExecuteCopyAndExport()
        end
    )
end

-- ============================================================================
-- TAB 11: KEAMANAN & AC (Universal Anti-Ban Framework v3.1 + Monitor AC & Zona)
-- ============================================================================
do
    local page = Components.CreateTab("KeamananAC", { id = "Keamanan & AC", en = "Security & AC" }, "🛡️", 11)

    Components.AddSectionHeader(page, { id = "Universal Anti-Ban Framework v3.1", en = "Universal Anti-Ban Framework v3.1" }, 1)

    local abStatusCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(abStatusCard, 9)
    local abStroke = Utils.AddStroke(abStatusCard, Theme.Success, 1.2, 0.2)

    local abLiveLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -20, 1, -12),
        Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 15,
    }, abStatusCard)
    Utils.RegisterText(abLiveLbl, false, Theme.TextPrimary)

    local function refreshAntiBanCard()
        if not abLiveLbl or not abLiveLbl.Parent then return end
        local capSummary = string.format(
            "HookMeta:%s | HookFn:%s | RawMT:%s | Req:%s",
            AntiBan.CAP.hookmetamethod and "ON" or "N/A",
            AntiBan.CAP.hookfunction and "ON" or "N/A",
            AntiBan.CAP.getrawmetatable and "ON" or "N/A",
            tostring(AntiBan.CAP.request or "N/A")
        )
        abLiveLbl.Text = string.format(
            "🛡️ Anti-Ban v%s: AKTIF  |  HWID: %s...\n• Kick Diblokir: %d  |  Remote Dibatasi: %d  |  Ban-Remote Diblokir: %d\n• Capability: %s",
            AntiBan.Version,
            string.sub(tostring(AntiBan.Stats.SpoofedHWID or "N/A"), 1, 14),
            AntiBan.Stats.KicksBlocked,
            AntiBan.Stats.RemotesThrottled,
            AntiBan.Stats.BanRemotesBlocked,
            capSummary
        )
    end
    refreshAntiBanCard()
    AntiBan.OnStatsChanged = refreshAntiBanCard

    Components.AddToggle(
        page,
        { id = "Anti-Kick Protection (Hook + Namecall)", en = "Anti-Kick Protection (Hook + Namecall)" },
        { id = "Memblokir pemanggilan LocalPlayer:Kick() dari skrip game", en = "Blocks LocalPlayer:Kick() invocations from game scripts" },
        AntiBan.Config.EnableAntiKick,
        3,
        function(val)
            AntiBan.Config.EnableAntiKick = val
            FeatureAPI.Sync("AntiBanKick", val)
            refreshAntiBanCard()
        end
    )

    FeatureAPI.Register("AntiBanKick", {
        Category = "KeamananAC",
        OnEnable = function() AntiBan.Config.EnableAntiKick = true; refreshAntiBanCard() end,
        OnDisable = function() AntiBan.Config.EnableAntiKick = false; refreshAntiBanCard() end,
    })
    FeatureAPI.Sync("AntiBanKick", AntiBan.Config.EnableAntiKick)

    Components.AddToggle(
        page,
        { id = "Anti-Remote Rate Limit & Anti-Detect", en = "Anti-Remote Rate Limit & Anti-Detect" },
        { id = "Mencegah spam remote berlebihan & memblokir remote pelapor ban", en = "Prevents excessive remote spam & blocks ban-reporting remotes" },
        AntiBan.Config.EnableAntiRemote,
        4,
        function(val)
            AntiBan.Config.EnableAntiRemote = val
            AntiBan.Config.EnableAntiDetect = val
            FeatureAPI.Sync("AntiBanRemote", val)
            refreshAntiBanCard()
        end
    )

    FeatureAPI.Register("AntiBanRemote", {
        Category = "KeamananAC",
        OnEnable = function() AntiBan.Config.EnableAntiRemote = true; AntiBan.Config.EnableAntiDetect = true; refreshAntiBanCard() end,
        OnDisable = function() AntiBan.Config.EnableAntiRemote = false; AntiBan.Config.EnableAntiDetect = false; refreshAntiBanCard() end,
    })
    FeatureAPI.Sync("AntiBanRemote", AntiBan.Config.EnableAntiRemote)

    Components.AddToggle(
        page,
        { id = "Anti-Stats Memory Scan", en = "Anti-Stats Memory Scan" },
        { id = "Menyembunyikan jejak script pada pemeriksaan Stats service", en = "Filters script traces during Stats service inspection" },
        AntiBan.Config.EnableAntiStatsScan,
        5,
        function(val)
            AntiBan.Config.EnableAntiStatsScan = val
            FeatureAPI.Sync("AntiBanStats", val)
            refreshAntiBanCard()
        end
    )

    FeatureAPI.Register("AntiBanStats", {
        Category = "KeamananAC",
        OnEnable = function() AntiBan.Config.EnableAntiStatsScan = true; refreshAntiBanCard() end,
        OnDisable = function() AntiBan.Config.EnableAntiStatsScan = false; refreshAntiBanCard() end,
    })
    FeatureAPI.Sync("AntiBanStats", AntiBan.Config.EnableAntiStatsScan)

    Components.AddToggle(
        page,
        { id = "Spoof HWID & Mini-Console Mengambang", en = "Spoof HWID & Floating Mini-Console" },
        { id = "Menyamarkan HWID sesi & menampilkan jendela status Anti-Ban", en = "Masks session HWID & displays floating Anti-Ban monitor" },
        AntiBan.Config.InteractiveConsole,
        6,
        function(val)
            AntiBan.SetConsoleVisible(val)
            refreshAntiBanCard()
        end
    )

    Components.AddButton(
        page,
        { id = "Acak Ulang HWID Sesi (Regenerate)", en = "Regenerate Session HWID" },
        { id = "Membuat identitas GUID HWID baru secara instan", en = "Generates a fresh spoofed HWID GUID immediately" },
        { id = "Acak HWID", en = "New HWID" },
        7,
        function()
            AntiBan.RegenerateHWID()
            refreshAntiBanCard()
            Utils.Notify("Spoof HWID", "HWID Baru: " .. tostring(AntiBan.Stats.SpoofedHWID), Theme.Success)
        end
    )

    Components.AddSectionHeader(page, { id = "Pemindai Zona & Audit Integritas", en = "Zone Scanner & Integrity Audit" }, 8)

    local zoneCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 9,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(zoneCard, 9)
    Utils.AddStroke(zoneCard, Theme.BorderSubtle, 1, 0.3)

    local zoneLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "📍 Zona Saat Ini: " .. SecurityHub.CurrentZoneName,
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, zoneCard)
    Utils.RegisterAccent(zoneLbl, "TextColor3")
    SecurityHub.OnZoneChanged = function(newZone)
        if zoneLbl and zoneLbl.Parent then
            zoneLbl.Text = "📍 Zona Saat Ini: " .. tostring(newZone)
        end
    end

    Components.AddButton(
        page,
        { id = "Jalankan Audit Integritas Klien", en = "Run Client Integrity Audit" },
        { id = "Periksa anomali fisika, kecepatan & status Anti-Ban", en = "Checks physics anomalies, speed & Anti-Ban status" },
        { id = "Audit", en = "Audit" },
        10,
        function()
            SecurityHub.RunIntegrityAudit()
            refreshAntiBanCard()
        end
    )
end

-- ============================================================================
-- TAB 12: PENGATURAN (Region Device, Config JSON, Tema & Kontrol Panel)
-- ============================================================================
do
    local page = Components.CreateTab("Pengaturan", { id = "Pengaturan", en = "Settings" }, "⚙️", 12)

    Components.AddSectionHeader(page, { id = "Bahasa & Deteksi Region Perangkat", en = "Language & Device Region" }, 1)

    Components.AddChipSelector(
        page,
        { id = "Pilih Bahasa Antarmuka", en = "Select Interface Language" },
        {
            { Label = { id = "Otomatis Region", en = "Auto Region" }, Value = "Auto" },
            { Label = "Indonesia", Value = "id" },
            { Label = "English", Value = "en" },
        },
        LocaleEngine.Mode,
        2,
        function(v)
            LocaleEngine.SetMode(v)
            Utils.Notify("Bahasa Diperbarui", LocaleEngine.RegionDisplay, Theme.Success)
        end
    )

    Components.AddSectionHeader(page, { id = "Manajemen Konfigurasi JSON", en = "JSON Config Persistence" }, 3)

    Components.AddButton(
        page,
        { id = "Simpan Pengaturan ke JSON", en = "Save Settings to JSON" },
        { id = "Menyimpan konfigurasi fitur & Anti-Ban ke file lokal", en = "Saves feature & Anti-Ban settings to local JSON file" },
        { id = "Simpan", en = "Save" },
        4,
        function()
            ConfigManager.Save()
        end
    )

    Components.AddButton(
        page,
        { id = "Muat Pengaturan dari JSON", en = "Load Settings from JSON" },
        { id = "Memulihkan pengaturan tersimpan dari file JSON", en = "Restores saved settings from JSON file" },
        { id = "Muat", en = "Load" },
        5,
        function()
            ConfigManager.Load(false)
        end
    )

    Components.AddSectionHeader(page, { id = "Proteksi Sistem & Tema Warna", en = "System Protection & Theme Colors" }, 6)

    Components.AddToggle(
        page,
        { id = "Anti-AFK Otomatis (Anti Kick Idle)", en = "Auto Anti-AFK (Idle Kick Guard)" },
        { id = "Mencegah terputus dari server akibat diam lebih dari 20 menit", en = "Prevents idle disconnection after 20 minutes" },
        Protection.AntiAFKEnabled,
        7,
        function(val) Protection.AntiAFKEnabled = val end
    )

    Components.AddToggle(
        page,
        { id = "Anti-Bug & Pemulihan Fisika Otomatis", en = "Anti-Bug & Auto Physics Recovery" },
        { id = "Menangkap error runtime dan memulihkan karakter otomatis", en = "Catches runtime errors and recovers character automatically" },
        Protection.AntiBugEnabled,
        8,
        function(val) Protection.AntiBugEnabled = val end
    )

    Components.AddChipSelector(
        page,
        { id = "Warna Aksen Panel", en = "Panel Accent Color" },
        {
            { Label = "Oranye Royal", Value = "Orange", Color = Color3.fromRGB(255, 118, 26) },
            { Label = "Merah Crimson", Value = "Crimson", Color = Color3.fromRGB(224, 52, 82) },
            { Label = "Ungu Spektral", Value = "Purple", Color = Color3.fromRGB(155, 89, 245) },
            { Label = "Hijau Emerald", Value = "Emerald", Color = Color3.fromRGB(46, 213, 115) },
            { Label = "Biru Cyber", Value = "Cyber", Color = Color3.fromRGB(56, 182, 255) },
            { Label = "Emas Mewah", Value = "Gold", Color = Color3.fromRGB(245, 192, 54) },
        },
        "Orange",
        9,
        function(v)
            local palette = {
                Orange  = { Color3.fromRGB(255, 118, 26), Color3.fromRGB(184, 72, 12) },
                Crimson = { Color3.fromRGB(224, 52, 82),  Color3.fromRGB(156, 28, 52) },
                Purple  = { Color3.fromRGB(155, 89, 245), Color3.fromRGB(102, 48, 178) },
                Emerald = { Color3.fromRGB(46, 213, 115), Color3.fromRGB(24, 148, 76) },
                Cyber   = { Color3.fromRGB(56, 182, 255), Color3.fromRGB(24, 118, 186) },
                Gold    = { Color3.fromRGB(245, 192, 54), Color3.fromRGB(178, 132, 22) },
            }
            local chosen = palette[v]
            if chosen then
                Utils.SetAccentColor(chosen[1], chosen[2])
            end
        end
    )

    Components.AddButton(
        page,
        { id = "Perbaiki Karakter & Fisika Sekarang", en = "Force Repair Character & Physics" },
        { id = "Membersihkan gaya terbang macet dan memulihkan kontrol", en = "Clears stuck flight forces and restores movement controls" },
        { id = "Perbaiki", en = "Repair" },
        10,
        function()
            SafeEngine.AutoRepair("ManualRepair", "UserTriggered")
            Utils.Notify("Pemulihan", "Fisika dan status karakter dipulihkan.", Theme.Success)
        end
    )
end

-- ============================================================================
-- 16. COMMAND PALETTE (F2 QUICK SEARCH & EXECUTE)
-- ============================================================================
do
    CommandRegistry = {
        { Title = "Toggle ESP Pemain", Category = "Radar ESP", Action = function() FeatureAPI.Toggle("PlayerESP") end },
        { Title = "Toggle ESP Barang & Loot", Category = "Radar ESP", Action = function() FeatureAPI.Toggle("ItemESP") end },
        { Title = "Toggle ESP Generator", Category = "Radar ESP", Action = function() FeatureAPI.Toggle("GeneratorESP") end },
        { Title = "Toggle Auto Generator", Category = "Radar ESP", Action = function() FeatureAPI.Toggle("AutoGenerator") end },
        { Title = "Toggle Aimbot Kamera", Category = "Pertarungan", Action = function() FeatureAPI.Toggle("Aimbot") end },
        { Title = "Toggle Auto Parry", Category = "Pertarungan", Action = function() FeatureAPI.Toggle("AutoParry") end },
        { Title = "Toggle Smooth Admin Fly", Category = "Pergerakan", Action = function() FeatureAPI.Toggle("Fly") end },
        { Title = "Toggle Noclip (Tembus Dinding)", Category = "Pergerakan", Action = function() FeatureAPI.Toggle("Noclip") end },
        { Title = "Acak Ulang HWID (Anti-Ban)", Category = "Keamanan", Action = function() AntiBan.RegenerateHWID() end },
        { Title = "Toggle Mini-Console Anti-Ban", Category = "Keamanan", Action = function() AntiBan.SetConsoleVisible(not AntiBan.Config.InteractiveConsole) end },
        { Title = "Jalankan Audit Integritas", Category = "Keamanan", Action = function() SecurityHub.RunIntegrityAudit() end },
        { Title = "Salin & Ekspor Aset Terdekat", Category = "Salin Aset", Action = function() AssetCopy.ExecuteCopyAndExport() end },
        { Title = "Simpan Konfigurasi JSON", Category = "Pengaturan", Action = function() ConfigManager.Save() end },
    }

    local overlay = Utils.Create("Frame", {
        Name = "CommandPaletteOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Visible = false,
        ZIndex = 70,
    }, UI.ScreenGui)

    local modal = Utils.Create("Frame", {
        Size = UDim2.new(0, 380, 0, 270),
        Position = UDim2.new(0.5, -190, 0.5, -135),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 71,
    }, overlay)
    Utils.AddCorner(modal, 12)
    Utils.AddStroke(modal, Theme.Accent, 1.4, 0.15)

    local searchInput = Utils.Create("TextBox", {
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = LocaleEngine.Text("Ketik perintah cepat (ESC / Klik luar untuk tutup)...", "Type quick command (ESC / Click outside to close)..."),
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 72,
    }, modal)
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
        ZIndex = 72,
    }, modal)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, resultsScroll)

    local function renderCommands(filter)
        for _, child in ipairs(resultsScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local q = string.lower(filter or "")
        for idx, cmd in ipairs(CommandRegistry) do
            if q == "" or string.find(string.lower(cmd.Title), q, 1, true) or string.find(string.lower(cmd.Category), q, 1, true) then
                local btn = Utils.Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.BgCard,
                    Font = Theme.FontBold,
                    Text = string.format("  [%s] %s", cmd.Category, cmd.Title),
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = idx,
                    ZIndex = 73,
                }, resultsScroll)
                Utils.AddCorner(btn, 6)
                btn.MouseButton1Click:Connect(function()
                    overlay.Visible = false
                    SafeEngine.Run("CmdPalette:" .. cmd.Title, cmd.Action)
                end)
            end
        end
    end

    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        renderCommands(searchInput.Text)
    end)

    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = input.Position
            local mPos = modal.AbsolutePosition
            local mSize = modal.AbsoluteSize
            if pos.X < mPos.X or pos.X > (mPos.X + mSize.X) or pos.Y < mPos.Y or pos.Y > (mPos.Y + mSize.Y) then
                overlay.Visible = false
            end
        end
    end)

    UI.CommandPalette = {
        Open = function()
            overlay.Visible = true
            searchInput.Text = ""
            renderCommands("")
            pcall(function() searchInput:CaptureFocus() end)
        end,
        Close = function()
            overlay.Visible = false
        end,
        Toggle = function()
            if overlay.Visible then
                overlay.Visible = false
            else
                UI.CommandPalette.Open()
            end
        end,
    }
end

-- ============================================================================
-- 17. WINDOW CONTROLS, RESIZE HANDLE, MINIMIZE & FLOATING TOGGLE
-- ============================================================================
do
    local function setWindowVisible(visible)
        App.IsOpen = visible
        UI.MainFrame.Visible = visible
    end

    UI.FloatingToggle.MouseButton1Click:Connect(function()
        setWindowVisible(not App.IsOpen)
    end)

    UI.CloseBtn.MouseButton1Click:Connect(function()
        setWindowVisible(false)
    end)

    UI.MinimizeBtn.MouseButton1Click:Connect(function()
        App.IsMinimized = not App.IsMinimized
        if App.IsMinimized then
            UI.Sidebar.Visible = false
            UI.ContentContainer.Visible = false
            UI.ResizeHandle.Visible = false
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, App.ExpandedWidth, 0, 54)
            })
        else
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, App.ExpandedWidth, 0, App.ExpandedHeight)
            })
            task.delay(0.12, function()
                if not App.IsMinimized and UI.Sidebar and UI.ContentContainer then
                    UI.Sidebar.Visible = true
                    UI.ContentContainer.Visible = true
                    UI.ResizeHandle.Visible = true
                end
            end)
        end
    end)

    local resizing = false
    local resizeStartPos = nil
    local resizeStartSize = nil

    UI.ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStartPos = input.Position
            resizeStartSize = UI.MainFrame.AbsoluteSize
        end
    end)

    Utils.Track(UserInputService.InputChanged:Connect(function(input)
        if resizing and resizeStartPos and resizeStartSize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartPos
            local newW = math.clamp(resizeStartSize.X + delta.X, 340, 920)
            local newH = math.clamp(resizeStartSize.Y + delta.Y, 260, 680)
            App.ExpandedWidth = newW
            App.ExpandedHeight = newH
            UI.MainFrame.Size = UDim2.new(0, newW, 0, newH)

            local sideW = (newW < 500) and math.clamp(math.floor(newW * 0.30), 116, 166) or 166
            UI.Sidebar.Size = UDim2.new(0, sideW, 1, -54)
            UI.ContentContainer.Size = UDim2.new(1, -sideW, 1, -54)
            UI.ContentContainer.Position = UDim2.new(0, sideW, 0, 54)
        end
    end))

    Utils.Track(UserInputService.InputEnded:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            resizing = false
        end
    end))

    Utils.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            setWindowVisible(not App.IsOpen)
        elseif input.KeyCode == Enum.KeyCode.F2 then
            if UI.CommandPalette then
                UI.CommandPalette.Toggle()
            end
        elseif input.KeyCode == Enum.KeyCode.Escape then
            if UI.CommandPalette then
                UI.CommandPalette.Close()
            end
        end
    end))
end

-- ============================================================================
-- 18. AUTO-GENERATOR AUTOMATION ENGINE (Map Distrik & Universal)
-- ============================================================================
do
    local function trySolveSkillCheckUI()
        local now = os.clock()
        if (now - AutoGen.LastSkillCheckTime) < 0.12 then return end

        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end

        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local gName = string.lower(gui.Name)
                if string.find(gName, "skill", 1, true) or string.find(gName, "check", 1, true) or string.find(gName, "repair", 1, true) or string.find(gName, "gen", 1, true) or string.find(gName, "qte", 1, true) then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                            if desc.Visible and desc.Active then
                                AutoGen.LastSkillCheckTime = now
                                pcall(function()
                                    if typeof(firesignal) == "function" then
                                        firesignal(desc.MouseButton1Click)
                                    end
                                end)
                                if VirtualInputManager then
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                        task.delay(0.03, function()
                                            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                                        end)
                                    end)
                                end
                                return
                            end
                        end
                    end
                end
            end
        end
    end

    function AutoGen.Step()
        if not AutoGen.Enabled then return end

        if AutoGen.AutoSkillCheck then
            trySolveSkillCheckUI()
        end

        local now = os.clock()
        if (now - AutoGen.LastActionTime) < AutoGen.ScanInterval then
            return
        end
        AutoGen.LastActionTime = now

        local target = AutoGen.CurrentTarget
        if target and target.Instance and target.Instance.Parent then
            local pct, _, isDone, _, _, prompt = GeneratorAPI.ReadProgress(target.Instance)
            target.Progress = pct
            target.Completed = isDone
            target.Prompt = prompt
            if isDone or pct >= 100 then
                AutoGen.CompletedCount = AutoGen.CompletedCount + 1
                if AutoGen.AutoSwitchNext then
                    AutoGen.CurrentTarget = nil
                    target = nil
                else
                    AutoGen.Enabled = false
                    FeatureAPI.Sync("AutoGenerator", false)
                    return
                end
            end
        else
            AutoGen.CurrentTarget = nil
            target = nil
        end

        if not target then
            target = GeneratorAPI.GetNearestIncomplete()
            AutoGen.CurrentTarget = target
        end

        if not target or not target.Part or not target.Part.Parent then
            AutoGen.StatusText = "Semua generator selesai!"
            return
        end

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myRoot then return end

        local dist = (target.Part.Position - myRoot.Position).Magnitude
        AutoGen.StatusText = string.format("%s (%d%% | %.0fm)", target.Name, target.Progress, dist)

        if AutoGen.AutoTeleport and dist > (AutoGen.InteractRange - 2) then
            local destCF = target.Part.CFrame * CFrame.new(AutoGen.TeleportOffset)
            Utils.SafeTeleport(destCF)
        end

        if AutoGen.AutoInteract and dist <= AutoGen.InteractRange then
            if target.Prompt and target.Prompt.Parent and target.Prompt.Enabled then
                FeatureAPI.TriggerProximity(target.Prompt)
            end
            FeatureAPI.ScanGameRemotes(false)
            for _, rem in ipairs(FeatureAPI.RemoteIndex.Generator) do
                if rem and rem.Parent then
                    AntiBan.Fire(rem, target.Instance)
                    AntiBan.Fire(rem, "Repair", target.Instance)
                end
            end
        end
    end
end

-- ============================================================================
-- 19. MASTER RUNTIME LOOPS (RenderStepped, Heartbeat & JumpRequest)
-- ============================================================================
do
    Utils.Track(RunService.RenderStepped:Connect(function(dt)
        SafeEngine.Run("RenderStepped", function()
            if State.FlyEnabled then
                Physics.StepSmoothFly(dt)
            end

            if Combat.AimbotEnabled then
                Combat.StepAimbot()
            end

            local cam = workspace.CurrentCamera
            if cam and State.CameraFOV ~= 70 and math.abs(cam.FieldOfView - State.CameraFOV) > 0.2 then
                cam.FieldOfView = State.CameraFOV
            end
        end)
    end))

    local fpsFrames = 0
    local fpsLastClock = os.clock()
    local currentFPS = 60
    local espTick = 0

    Utils.Track(RunService.Heartbeat:Connect(function()
        SafeEngine.Run("Heartbeat", function()
            fpsFrames = fpsFrames + 1
            local now = os.clock()
            if (now - fpsLastClock) >= 0.5 then
                currentFPS = math.floor((fpsFrames / (now - fpsLastClock)) + 0.5)
                fpsFrames = 0
                fpsLastClock = now

                if UI.TelemetryLabels.FPS and UI.TelemetryLabels.FPS.Parent then
                    UI.TelemetryLabels.FPS.Text = tostring(currentFPS) .. " FPS"
                end
                if UI.TelemetryLabels.Ping and UI.TelemetryLabels.Ping.Parent then
                    local pingMs = 0
                    pcall(function()
                        pingMs = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                    end)
                    UI.TelemetryLabels.Ping.Text = tostring(pingMs) .. " ms"
                end
                if UI.TelemetryLabels.Memory and UI.TelemetryLabels.Memory.Parent then
                    local memMb = 0
                    pcall(function()
                        memMb = math.floor(Stats:GetTotalMemoryUsageMb() + 0.5)
                    end)
                    UI.TelemetryLabels.Memory.Text = tostring(memMb) .. " MB"
                end
                if UI.TelemetryLabels.Players and UI.TelemetryLabels.Players.Parent then
                    UI.TelemetryLabels.Players.Text = string.format("%d/%d | %d", #Players:GetPlayers(), Players.MaxPlayers, FeatureAPI.GetActiveCount())
                end
            end

            local char, hum, root = Utils.GetCharacter(LocalPlayer)
            if hum then
                if State.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.WalkSpeed then
                    hum.WalkSpeed = State.WalkSpeed
                end
                if State.JumpPower ~= 50 and hum.JumpPower ~= State.JumpPower then
                    hum.UseJumpPower = true
                    hum.JumpPower = State.JumpPower
                end
            end

            if State.NoclipEnabled and char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        if Physics.NoclipCache[part] == nil then
                            Physics.NoclipCache[part] = true
                        end
                        part.CanCollide = false
                    end
                end
            end

            if root and UI.TelemetryLabels.Coords and UI.Pages["Teleportasi"] and UI.Pages["Teleportasi"].Visible then
                UI.TelemetryLabels.Coords.Text = string.format(
                    "Posisi: X: %.1f | Y: %.1f | Z: %.1f",
                    root.Position.X, root.Position.Y, root.Position.Z
                )
            end

            if State.FullbrightEnabled then
                Lighting.Brightness = 2.5
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            end

            if State.NoFogEnabled then
                Lighting.FogEnd = 100000
                Lighting.FogStart = 99999
                local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
                if atmo then atmo.Density = 0 end
            end

            espTick = espTick + 1
            if espTick >= 3 then
                espTick = 0
                if ESP.Enabled then ESP.UpdateAll() end
                if ItemESP.Enabled then ItemESP.ScanAndRender() end
                if GeneratorESP.Enabled then GeneratorESP.ScanAndRender() end
            end

            if Combat.AutoParryEnabled then Combat.StepAutoParry() end
            if Combat.MeleeImmunity then Protection.StepMeleeImmunity() end
            if Combat.HungerThirstGuard then Protection.StepHungerThirstGuard() end
            if Carry.Enabled then Carry.Step() end
            if AutoGen.Enabled then AutoGen.Step() end
            if SecurityHub.ZoneScannerEnabled then SecurityHub.StepZoneScanner() end
        end)
    end))

    Utils.Track(UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJumpEnabled then
            local _, hum = Utils.GetCharacter(LocalPlayer)
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end))

    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        ESP.RemovePlayer(plr)
        if Carry.TargetPlayer == plr then
            Carry.Stop()
        end
    end))
end

-- ============================================================================
-- 20. CLEAN UNLOAD & GLOBAL REGISTRATION
-- ============================================================================
local function unloadScript()
    State.FlyEnabled = false
    State.NoclipEnabled = false
    ESP.Enabled = false
    ItemESP.Enabled = false
    GeneratorESP.Enabled = false
    Combat.AimbotEnabled = false
    Combat.AutoParryEnabled = false
    Combat.MeleeImmunity = false
    AutoGen.Enabled = false

    pcall(function() AntiBan.Shutdown() end)
    pcall(function() Physics.CleanupFly() end)
    pcall(function() Physics.RestoreNoclip() end)
    pcall(function() Carry.Stop() end)
    pcall(function() Emotes.Stop() end)
    pcall(function() Combat.HideLaser() end)
    pcall(function() Combat.CleanupParryVisuals() end)
    pcall(function() Protection.StepMeleeImmunity() end)

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    if Combat.LaserPart then
        pcall(function() Combat.LaserPart:Destroy() end)
        Combat.LaserPart = nil
    end
    if UI.ScreenGui then
        pcall(function() UI.ScreenGui:Destroy() end)
        UI.ScreenGui = nil
    end
end

if typeof(getgenv) == "function" then
    getgenv().BSS_UnloadOld = unloadScript
end

Components.SwitchTab("Informasi")
Utils.Notify(
    "BimSakSin Hub v3.0 + AntiBan v3.1",
    LocaleEngine.Text(
        "Siap digunakan! Semua modul & proteksi Anti-Ban aktif.",
        "Ready! All modules & Anti-Ban protections are active."
    ),
    Theme.Success
)
