--[[
================================================================================
  BimSakSin Hub v3.2 + Universal Anti-Ban Framework v3.1.1 | Edisi Universal
  Creator     : BimSakSin
  Environment : Roblox Luau (Universal / Semua Map & Kompatibel R6/R15)
  Patch Log   :
    - v3.2  : Perbaikan 20 bug (null-safety LocalPlayer, SafeEngine triple-return,
              parry spam guard, Carries platformstand, emote ID strict,
              auto-reconnect SecurityHub, memory leak console drag, auto-gen
              remote cooldown, flight reset guard, config console sync).
    - v3.1.1: Anti-Kick hook + namecall guard, Anti-Remote, Anti-Stats Scan,
              HWID Spoofer, SafeFire API, Webhook Reporter.
  Struktur Tab (urut kegunaan):
    1. Informasi        7. Gendong
    2. Beranda          8. Tari & Emote
    3. Radar ESP        9. Visual
    4. Pertarungan     10. Salin Aset
    5. Pergerakan      11. Keamanan & AC
    6. Teleportasi     12. Pengaturan
================================================================================
]]

-- ============================================================================
-- 0. PRE-EXECUTION CLEANUP
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
        ["BimSakSinHub_v2"] = true, ["BimSakSinHub_v3"] = true,
        ["BSS_ESP_Folder"] = true, ["BSS_ItemESP_Folder"] = true, ["BSS_GenESP_Folder"] = true,
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
    if typeof(gethui) == "function" then pcall(function() cleanupContainer(gethui()) end) end
    local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if okCore then cleanupContainer(coreGui) end

    local lp = game:GetService("Players").LocalPlayer
    if lp then
        pcall(function()
            cleanupContainer(lp:FindFirstChild("PlayerGui"))
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for _, objName in ipairs({
                    "BSS_FlyVelocity","BSS_FlyGyro","BSS_FlyLinearVel",
                    "BSS_FlyAlignOri","BSS_FlyAttachment","BSS_CarryVelocity","BSS_CarryWeld",
                }) do
                    local old = root:FindFirstChild(objName)
                    if old then old:Destroy() end
                end
            end
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false; hum.AutoRotate = true end
        end)
    end
    local oldLaser = workspace:FindFirstChild("BSS_RGB_AimLaser")
    if oldLaser then oldLaser:Destroy() end
end

-- ============================================================================
-- 1. CORE SERVICES
-- ============================================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local Stats              = game:GetService("Stats")
local TeleportService    = game:GetService("TeleportService")
local Teams              = game:GetService("Teams")
local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LogService         = game:GetService("LogService")
local CoreGui            = game:GetService("CoreGui")
local LocalizationService= game:GetService("LocalizationService")

-- [FIX #1] LocalPlayer null-safe extraction
local VirtualUser, VirtualInputManager
pcall(function() VirtualUser = game:GetService("VirtualUser") end)
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
    end)
    if not LocalPlayer then
        task.wait(0.1)
        LocalPlayer = Players.LocalPlayer
    end
end

local App = {
    Name     = "BimSakSin Hub v3.2",
    Subtitle = "Semoga hari-hari kalian menyenangkan",
    Version  = "v3.2 Universal + AntiBan v3.1.1",
    GuiName  = "BimSakSinHub_v3",
    IsOpen   = true, IsMinimized = false,
    ExpandedWidth = 650, ExpandedHeight = 435, ActiveTab = "Informasi",
    StartTime    = os.clock(),
    DiscordUrl   = "https://discord.gg/YwMCBq22f2",
    DonationUrl  = "https://linktr.ee/bimsaksin",
}

-- ============================================================================
-- 1A. LOCALE ENGINE
-- ============================================================================
local LocaleEngine = {
    Mode = "Auto", CurrentLang = "id",
    SystemLocale = "id-ID", RobloxLocale = "id-ID",
    CountryCode = "ID", RegionDisplay = "Indonesia (ID / id-ID)",
    Updaters = {},
}

do
    local namesID = { ID="Indonesia",MY="Malaysia",SG="Singapura",US="Amerika Serikat",GB="Inggris",JP="Jepang",KR="Korea Selatan",PH="Filipina",TH="Thailand",VN="Vietnam",AU="Australia",DE="Jerman",FR="Prancis",BR="Brasil",RU="Rusia" }
    local namesEN = { ID="Indonesia",MY="Malaysia",SG="Singapore",US="United States",GB="United Kingdom",JP="Japan",KR="South Korea",PH="Philippines",TH="Thailand",VN="Vietnam",AU="Australia",DE="Germany",FR="France",BR="Brazil",RU="Russia" }

    local function readInitialLocales()
        local sysLoc, rbxLoc = "", ""
        pcall(function() sysLoc = tostring(LocalizationService.SystemLocaleId or "") end)
        pcall(function() rbxLoc = tostring(LocalizationService.RobloxLocaleId or "") end)
        LocaleEngine.SystemLocale = (sysLoc ~= "") and sysLoc or "id-ID"
        LocaleEngine.RobloxLocale = (rbxLoc ~= "") and rbxLoc or LocaleEngine.SystemLocale
        local region = string.match(LocaleEngine.SystemLocale, "%-(%a%a)$")
                    or string.match(LocaleEngine.RobloxLocale, "%-(%a%a)$")
        LocaleEngine.CountryCode = region and string.upper(region) or "ID"
    end

    function LocaleEngine.ComputeEffectiveLang()
        if LocaleEngine.Mode == "id" or LocaleEngine.Mode == "en" then return LocaleEngine.Mode end
        local cc = string.upper(LocaleEngine.CountryCode or "")
        local ls, lr = string.lower(LocaleEngine.SystemLocale or ""), string.lower(LocaleEngine.RobloxLocale or "")
        if cc == "ID" or string.sub(ls,1,2)=="id" or string.sub(lr,1,2)=="id" then return "id" end
        if cc ~= "" and cc ~= "ID" then return "en" end
        return "id"
    end

    function LocaleEngine.UpdateRegionSummary()
        local cc = string.upper(LocaleEngine.CountryCode or "ID")
        local locTag = LocaleEngine.SystemLocale ~= "" and LocaleEngine.SystemLocale or LocaleEngine.RobloxLocale
        local tbl = (LocaleEngine.CurrentLang == "id") and namesID or namesEN
        local cName = tbl[cc] or ("Region " .. cc)
        LocaleEngine.RegionDisplay = string.format("%s (%s • %s)", cName, cc, locTag)
    end

    function LocaleEngine.Text(idText, enText)
        if LocaleEngine.CurrentLang == "en" and enText and enText ~= "" then return enText end
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
        App.Subtitle = LocaleEngine.Text("Semoga hari-hari kalian menyenangkan","Wishing you a wonderful day ahead")
        for i = #LocaleEngine.Updaters, 1, -1 do
            local ok = pcall(LocaleEngine.Updaters[i], LocaleEngine.CurrentLang)
            if not ok then table.remove(LocaleEngine.Updaters, i) end
        end
    end

    function LocaleEngine.SetMode(mode)
        LocaleEngine.Mode = mode or "Auto"
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
        end)
        if ok and type(regionCode) == "string" and #regionCode >= 2 then
            LocaleEngine.CountryCode = string.upper(string.sub(regionCode,1,2))
            LocaleEngine.RefreshAll()
        end
    end)
end

-- ============================================================================
-- 1B. THEME
-- ============================================================================
local Theme = {
    BgPrimary=Color3.fromRGB(13,11,19), BgSecondary=Color3.fromRGB(20,16,30),
    BgCard=Color3.fromRGB(28,22,41),    BgControl=Color3.fromRGB(40,31,58),
    Border=Color3.fromRGB(255,132,36),  BorderSubtle=Color3.fromRGB(78,56,108),
    TextPrimary=Color3.fromRGB(255,246,235), TextSecondary=Color3.fromRGB(204,186,172),
    TextMuted=Color3.fromRGB(142,124,150),
    FontFamily=Enum.Font.GothamSemibold, FontBold=Enum.Font.GothamBold,
    FontColorMode="Auto", FontBgEnabled=false,
    FontBgColor=Color3.fromRGB(18,14,26), FontBgTransparency=0.65,
    Accent=Color3.fromRGB(255,118,26), AccentDark=Color3.fromRGB(184,72,12),
    Crimson=Color3.fromRGB(214,48,74), Spectral=Color3.fromRGB(155,89,245),
    Success=Color3.fromRGB(46,213,115), Warning=Color3.fromRGB(255,177,43), Danger=Color3.fromRGB(235,69,95),
}

-- ============================================================================
-- 1C. STATE / PHYSICS / ESP / etc.
-- ============================================================================
local initialAtmo = Lighting:FindFirstChildOfClass("Atmosphere")

local State = {
    WalkSpeed=16, JumpPower=50,
    OriginalGravity=workspace.Gravity, Gravity=workspace.Gravity,
    FlyEnabled=false, FlySpeed=65, NoclipEnabled=false
