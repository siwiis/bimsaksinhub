-- BimSakSin Hub v4.6 (Fixed Out of Local Registers & Hardened Edition)
-- Kompatibel dengan Mobile Executor (Delta, Codex, Arceus X, Fluxus) & PC

local function safeGetService(serviceName)
    local ok, svc = pcall(function()
        return game:GetService(serviceName)
    end)
    return ok and svc or nil
end

local Players = safeGetService("Players")
local Teams = safeGetService("Teams")
local TweenService = safeGetService("TweenService")
local UserInputService = safeGetService("UserInputService")
local RunService = safeGetService("RunService")
local Lighting = safeGetService("Lighting")
local Stats = safeGetService("Stats")
local GuiService = safeGetService("GuiService")
local TeleportService = safeGetService("TeleportService")
local HttpService = safeGetService("HttpService")

if not Players then
    warn("[BimSakSin Hub] Service Players tidak tersedia.")
    return
end

-- Penantian LocalPlayer anti-hang
local LocalPlayer = Players.LocalPlayer
local waitStart = os.clock()
while not LocalPlayer and (os.clock() - waitStart) < 15 do
    task.wait(0.05)
    LocalPlayer = Players.LocalPlayer
end

if not LocalPlayer then
    warn("[BimSakSin Hub] Gagal mendeteksi LocalPlayer.")
    return
end

-- Helper waktu aman (anti nil jika os.date dibatasi executor)
local function getSafeTimeString()
    if type(os) == "table" and type(os.date) == "function" then
        local ok, formatted = pcall(os.date, "%H:%M:%S")
        if ok and type(formatted) == "string" then
            return formatted
        end
    end
    local totalSec = math.floor(workspace.DistributedGameTime or 0)
    local hrs = math.floor(totalSec / 3600) % 24
    local mins = math.floor(totalSec / 60) % 60
    local secs = totalSec % 60
    return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

-- Menentukan parent GUI paling aman (Prioritas gethui() -> CoreGui -> PlayerGui)
local function getSafeGuiParent()
    if type(gethui) == "function" then
        local ok, hiddenUi = pcall(gethui)
        if ok and typeof(hiddenUi) == "Instance" then
            return hiddenUi
        end
    end

    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and coreGui then
        local testSuccess = pcall(function()
            local probe = Instance.new("Folder")
            probe.Parent = coreGui
            probe:Destroy()
        end)
        if testSuccess then
            return coreGui
        end
    end

    return LocalPlayer:WaitForChild("PlayerGui", 10)
end

local GuiParent = getSafeGuiParent()
if not GuiParent then
    warn("[BimSakSin Hub] Tidak menemukan parent GUI yang valid.")
    return
end

local UI_NAME = "BimSakSinHub_UI"

-- Hapus instance lama jika script dijalankan ulang agar tidak bertumpuk
local existingGui = GuiParent:FindFirstChild(UI_NAME)
if existingGui then
    pcall(function()
        existingGui:Destroy()
    end)
end

-- ============================================================================
-- SISTEM SAVE & LOAD CONFIG OTOMATIS (JSON FILESYSTEM - ANTI CRASH)
-- ============================================================================
local CONFIG_FOLDER = "BimSakSinHub"
local GLOBAL_CONFIG_PATH = CONFIG_FOLDER .. "/global_config.json"
local WAYPOINT_CONFIG_PATH = string.format("%s/waypoints_%s.json", CONFIG_FOLDER, tostring(game.PlaceId))

local DefaultConfig = {
    AutoSave = true,
    Theme = "Cyan Electric",
    WatermarkVisible = true,
    WatermarkCorner = "Kiri Atas",
    WindowLocked = false,

    -- Keybinds
    ToggleUIKey = "RightShift",
    FlyKey = "F",
    NoclipKey = "N",
    InfJumpKey = "J",
    TpCoordKey = "T",
    TpGenKey = "G",
    AutoFarmKey = "H",

    -- Preferensi Karakter & Kamera
    FlySpeed = 60,
    WalkSpeed = 16,
    JumpPower = 50,
    LockStats = false,
    FOV = 70,

    -- Preferensi Visual, Tracer, Generator ESP, Auto Perfect & Auto Farm
    AutoTeamColor = true,
    FallbackHighlightColor = "Ikuti Warna Tema",
    TracerOrigin = "Bawah Layar",
    TracerThickness = 1,
    GenHighlight = true,
    GenHideCompleted = false,
    GenOnlyUntouched = false,
    GenMaxDistance = 1500,
    GenTpTargetMode = "Prioritas Belum Dikerjakan (0%) - Aktif",
    AutoPerfectGen = false,
    AutoInteractGen = false,
    GenSkillMode = "Selalu Perfect (Tepat Tengah)",
    GenTimingOffset = 0,
    AutoFarmTargetMode = "Prioritas 0% (Fallback <100%)",
    AutoFarmDelay = 1,
    AutoFarmStuckTimeout = 18,
    LightingPreset = "Default Server",
    NoFog = false,

    -- Pengaturan Sesi & Server
    AntiAFK = true,
    AutoRejoin = false,
    AutoRejoinMode = "Server Sama (Fallback Publik)",
    ServerHopMode = "Server Acak (Random)",
}

local function cloneDefaultConfig()
    local copy = {}
    for k, v in pairs(DefaultConfig) do
        copy[k] = v
    end
    return copy
end

local ConfigData = cloneDefaultConfig()
local SavedWaypointsData = {}

local ConfigManager = {
    Supported = (type(writefile) == "function" and type(readfile) == "function"),
    LoadedFromDisk = false,
    IsApplying = false,
    SaveToken = 0,
    OnStatusChanged = nil,
}

local function ensureConfigFolder()
    if not ConfigManager.Supported then
        return false
    end
    local ok = pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" then
            if not isfolder(CONFIG_FOLDER) then
                makefolder(CONFIG_FOLDER)
            end
        end
    end)
    return ok
end

local function safeIsFile(path)
    if type(isfile) == "function" then
        local ok, exists = pcall(isfile, path)
        return ok and exists == true
    end
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, path)
        return ok and type(content) == "string" and content ~= ""
    end
    return false
end

local function resolveKeyCodeFromName(keyName)
    if type(keyName) ~= "string" or keyName == "" then
        return nil
    end
    local ok, keyEnum = pcall(function()
        return Enum.KeyCode[keyName]
    end)
    if ok and typeof(keyEnum) == "EnumItem" then
        return keyEnum
    end
    return nil
end

function ConfigManager:Load()
    ConfigData = cloneDefaultConfig()
    table.clear(SavedWaypointsData)
    self.LoadedFromDisk = false

    if not self.Supported or not HttpService then
        return
    end

    pcall(function()
        ensureConfigFolder()

        if safeIsFile(GLOBAL_CONFIG_PATH) then
            local okRead, rawJson = pcall(readfile, GLOBAL_CONFIG_PATH)
            if okRead and type(rawJson) == "string" and rawJson ~= "" then
                local okDecode, parsed = pcall(function()
                    return HttpService:JSONDecode(rawJson)
                end)
                if okDecode and type(parsed) == "table" then
                    for key, defaultVal in pairs(DefaultConfig) do
                        if parsed[key] ~= nil and type(parsed[key]) == type(defaultVal) then
                            ConfigData[key] = parsed[key]
                        end
                    end
                    self.LoadedFromDisk = true
                end
            end
        end

        if safeIsFile(WAYPOINT_CONFIG_PATH) then
            local okRead, rawWpJson = pcall(readfile, WAYPOINT_CONFIG_PATH)
            if okRead and type(rawWpJson) == "string" and rawWpJson ~= "" then
                local okDecode, parsedList = pcall(function()
                    return HttpService:JSONDecode(rawWpJson)
                end)
                if okDecode and type(parsedList) == "table" then
                    for _, item in ipairs(parsedList) do
                        if type(item) == "table"
                            and type(item.Name) == "string"
                            and type(item.X) == "number"
                            and type(item.Y) == "number"
                            and type(item.Z) == "number" then
                            table.insert(SavedWaypointsData, {
                                Name = item.Name,
                                X = item.X,
                                Y = item.Y,
                                Z = item.Z,
                            })
                        end
                    end
                end
            end
        end
    end)
end

function ConfigManager:SaveNow(sourceWaypointsList)
    if not self.Supported or not HttpService then
        return false, "Executor tidak mendukung writefile"
    end

    ensureConfigFolder()

    if type(sourceWaypointsList) == "table" then
        table.clear(SavedWaypointsData)
        for _, wp in ipairs(sourceWaypointsList) do
            if wp and wp.Position then
                table.insert(SavedWaypointsData, {
                    Name = tostring(wp.Name or "Lokasi"),
                    X = math.floor(wp.Position.X * 10 + 0.5) / 10,
                    Y = math.floor(wp.Position.Y * 10 + 0.5) / 10,
                    Z = math.floor(wp.Position.Z * 10 + 0.5) / 10,
                })
            end
        end
    end

    local okGlobal, errGlobal = pcall(function()
        local encoded = HttpService:JSONEncode(ConfigData)
        writefile(GLOBAL_CONFIG_PATH, encoded)
    end)

    local okWp, errWp = pcall(function()
        local encodedWp = HttpService:JSONEncode(SavedWaypointsData)
        writefile(WAYPOINT_CONFIG_PATH, encodedWp)
    end)

    if okGlobal and okWp then
        local timestamp = getSafeTimeString()
        if self.OnStatusChanged then
            self.OnStatusChanged("Tersimpan (" .. timestamp .. ")")
        end
        return true
    end

    if self.OnStatusChanged then
        self.OnStatusChanged("Gagal Menyimpan")
    end
    return false, tostring(errGlobal or errWp)
end

function ConfigManager:ScheduleSave(sourceWaypointsList)
    if not self.Supported or self.IsApplying or not ConfigData.AutoSave then
        return
    end
    self.SaveToken = self.SaveToken + 1
    local currentToken = self.SaveToken
    task.delay(0.5, function()
        if self.SaveToken == currentToken and ConfigData.AutoSave and not self.IsApplying then
            self:SaveNow(sourceWaypointsList)
        end
    end)
end

ConfigManager:Load()

-- ============================================================================
-- KONFIGURASI TEMA & WARNA
-- ============================================================================
local Themes = {
    ["Cyan Electric"] = Color3.fromRGB(0, 185, 255),
    ["Emerald Green"] = Color3.fromRGB(16, 185, 129),
    ["Royal Purple"]  = Color3.fromRGB(147, 51, 234),
    ["Sunset Orange"] = Color3.fromRGB(249, 115, 22),
}

if not Themes[ConfigData.Theme] then
    ConfigData.Theme = "Cyan Electric"
end

local Palette = {
    Background    = Color3.fromRGB(15, 17, 24),
    Sidebar       = Color3.fromRGB(20, 23, 32),
    Card          = Color3.fromRGB(26, 30, 42),
    CardHover     = Color3.fromRGB(34, 39, 54),
    Stroke        = Color3.fromRGB(46, 52, 70),
    TextPrimary   = Color3.fromRGB(244, 246, 250),
    TextSecondary = Color3.fromRGB(152, 160, 178),
    SwitchOff     = Color3.fromRGB(52, 59, 78),
    Danger        = Color3.fromRGB(239, 68, 68),
    Warning       = Color3.fromRGB(245, 158, 11),
    Success       = Color3.fromRGB(16, 185, 129),
    Accent        = Themes[ConfigData.Theme],
}

-- ============================================================================
-- ENGINE UTAMA BIMSAKSIN UI
-- ============================================================================
local BimSakSinUI = {}
local Connections = {}
local AccentRegistry = {}
local CleanupCallbacks = {}
local ThemeChangeListeners = {}
local WindowLocked = ConfigData.WindowLocked
local ActiveKeybindCapture = nil
local CancelActiveKeybindFn = nil

local function trackConnection(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

local function registerCleanup(fn)
    if type(fn) == "function" then
        table.insert(CleanupCallbacks, fn)
    end
end

local function registerAccent(instance, property)
    table.insert(AccentRegistry, { Instance = instance, Property = property })
    instance[property] = Palette.Accent
end

local function applyThemeAccent(themeName)
    local newColor = Themes[themeName]
    if not newColor then
        return
    end
    Palette.Accent = newColor
    for i = #AccentRegistry, 1, -1 do
        local item = AccentRegistry[i]
        if item.Instance and item.Instance.Parent then
            TweenService:Create(
                item.Instance,
                TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { [item.Property] = newColor }
            ):Play()
        else
            table.remove(AccentRegistry, i)
        end
    end
    for _, listener in ipairs(ThemeChangeListeners) do
        task.spawn(listener, newColor)
    end
end

local function createInstance(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function addCorner(parent, radius)
    return createInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function addStroke(parent, color, thickness)
    return createInstance("UIStroke", {
        Color = color or Palette.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local ScreenGui = createInstance("ScreenGui", {
    Name = UI_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    Parent = GuiParent,
})

local TracerOverlay = createInstance("Frame", {
    Name = "TracerOverlayLayer",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = ScreenGui,
})

local NotifyContainer = createInstance("Frame", {
    Name = "NotificationContainer",
    Size = UDim2.new(0, 285, 1, -24),
    Position = UDim2.new(1, -299, 0, 12),
    BackgroundTransparency = 1,
    ZIndex = 20,
    Parent = ScreenGui,
}, {
    createInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
    })
})

function BimSakSinUI:Notify(options)
    local title = options.Title or "Informasi"
    local message = options.Message or ""
    local duration = options.Duration or 3.5

    local toast = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = NotifyContainer,
    })
    addCorner(toast, 10)
    local stroke = addStroke(toast, Palette.Stroke, 1)

    local accentBar = createInstance("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = Palette.Accent,
        BorderSizePixel = 0,
        Parent = toast,
    })
    registerAccent(accentBar, "BackgroundColor3")

    local titleLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, -22, 0, 19),
        Position = UDim2.new(0, 14, 0, 7),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Palette.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextTransparency = 1,
        Parent = toast,
    })

    local msgLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, -22, 0, 30),
        Position = UDim2.new(0, 14, 0, 26),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Palette.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTransparency = 1,
        Parent = toast,
    })

    TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.04
    }):Play()
    TweenService:Create(titleLabel, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()
    TweenService:Create(msgLabel, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()

    task.delay(duration, function()
        if not toast or not toast.Parent then
            return
        end
        local outTween = TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        })
        TweenService:Create(titleLabel, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
        TweenService:Create(msgLabel, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), { Transparency = 1 }):Play()
        outTween:Play()
        outTween.Completed:Wait()
        if toast then
            toast:Destroy()
        end
    end)
end

local function makeDraggable(dragHandle, targetFrame, checkLock)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    trackConnection(dragHandle.InputBegan:Connect(function(input)
        if checkLock and WindowLocked then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = targetFrame.Position
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newOffsetX = startPos.X.Offset + delta.X
            local newOffsetY = startPos.Y.Offset + delta.Y

            local cam = workspace.CurrentCamera
            if cam then
                local vp = cam.ViewportSize
                local absSize = targetFrame.AbsoluteSize
                local anchor = targetFrame.AnchorPoint
                local baseScreenX = (startPos.X.Scale * vp.X) + newOffsetX - (anchor.X * absSize.X)
                local baseScreenY = (startPos.Y.Scale * vp.Y) + newOffsetY - (anchor.Y * absSize.Y)

                local clampedX = math.clamp(baseScreenX, 4, math.max(4, vp.X - absSize.X - 4))
                local clampedY = math.clamp(baseScreenY, 4, math.max(4, vp.Y - absSize.Y - 4))

                newOffsetX = clampedX - (startPos.X.Scale * vp.X) + (anchor.X * absSize.X)
                newOffsetY = clampedY - (startPos.Y.Scale * vp.Y) + (anchor.Y * absSize.Y)
            end

            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                newOffsetX,
                startPos.Y.Scale,
                newOffsetY
            )
        end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            dragInput = nil
        end
    end))
end

-- ============================================================================
-- WATERMARK HUD ELEGAN
-- ============================================================================
local WatermarkPositions = {
    ["Kiri Atas"]   = { Anchor = Vector2.new(0, 0), Pos = UDim2.new(0, 16, 0, 56) },
    ["Kanan Atas"]  = { Anchor = Vector2.new(1, 0), Pos = UDim2.new(1, -16, 0, 56) },
    ["Kiri Bawah"]  = { Anchor = Vector2.new(0, 1), Pos = UDim2.new(0, 16, 1, -16) },
    ["Kanan Bawah"] = { Anchor = Vector2.new(1, 1), Pos = UDim2.new(1, -16, 1, -16) },
}

local initialWmPreset = WatermarkPositions[ConfigData.WatermarkCorner] or WatermarkPositions["Kiri Atas"]

local WatermarkFrame = createInstance("Frame", {
    Name = "BimSakSinWatermarkHUD",
    AnchorPoint = initialWmPreset.Anchor,
    Position = initialWmPreset.Pos,
    Size = UDim2.new(0, 0, 0, 30),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = Palette.Background,
    BackgroundTransparency = 0.1,
    Visible = ConfigData.WatermarkVisible,
    Active = true,
    ZIndex = 5,
    Parent = ScreenGui,
}, {
    createInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 11),
        PaddingRight = UDim.new(0, 12),
    }),
    createInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })
})
addCorner(WatermarkFrame, 8)
addStroke(WatermarkFrame, Palette.Stroke, 1.2)
makeDraggable(WatermarkFrame, WatermarkFrame, true)

local wmAccentDot = createInstance("Frame", {
    LayoutOrder = 1,
    Size = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = Palette.Accent,
    Parent = WatermarkFrame,
})
addCorner(wmAccentDot, 4)
registerAccent(wmAccentDot, "BackgroundColor3")

createInstance("TextLabel", {
    LayoutOrder = 2,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "BimSakSin Hub v4.6",
    TextColor3 = Palette.TextPrimary,
    TextSize = 12,
    Parent = WatermarkFrame,
})

createInstance("TextLabel", {
    LayoutOrder = 3,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "•",
    TextColor3 = Palette.TextSecondary,
    TextSize = 12,
    Parent = WatermarkFrame,
})

local wmFpsLabel = createInstance("TextLabel", {
    LayoutOrder = 4,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "60 FPS",
    TextColor3 = Palette.Accent,
    TextSize = 12,
    Parent = WatermarkFrame,
})
registerAccent(wmFpsLabel, "TextColor3")

createInstance("TextLabel", {
    LayoutOrder = 5,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "•",
    TextColor3 = Palette.TextSecondary,
    TextSize = 12,
    Parent = WatermarkFrame,
})

local wmPingLabel = createInstance("TextLabel", {
    LayoutOrder = 6,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "0 ms",
    TextColor3 = Palette.Success,
    TextSize = 12,
    Parent = WatermarkFrame,
})

createInstance("TextLabel", {
    LayoutOrder = 7,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "•",
    TextColor3 = Palette.TextSecondary,
    TextSize = 12,
    Parent = WatermarkFrame,
})

local wmTimeLabel = createInstance("TextLabel", {
    LayoutOrder = 8,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = getSafeTimeString(),
    TextColor3 = Palette.TextSecondary,
    TextSize = 12,
    Parent = WatermarkFrame,
})

local function setWatermarkCorner(cornerName)
    local preset = WatermarkPositions[cornerName]
    if not preset then
        return
    end
    WatermarkFrame.AnchorPoint = preset.Anchor
    TweenService:Create(
        WatermarkFrame,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = preset.Pos }
    ):Play()
end

function BimSakSinUI:CreateWindow(config)
    local titleText = config.Title or "BimSakSin Hub v4.6"
    local subtitleText = config.Subtitle or "Professional Edition"
    local uiToggleKey = config.ToggleKey

    local FloatingPill = createInstance("TextButton", {
        Name = "FloatingRestorePill",
        Size = UDim2.new(0, 148, 0, 38),
        Position = UDim2.new(0, 18, 0.5, -19),
        BackgroundColor3 = Palette.Background,
        Font = Enum.Font.GothamBold,
        Text = "   Buka BimSakSin",
        TextColor3 = Palette.TextPrimary,
        TextSize = 12,
        Visible = false,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    addCorner(FloatingPill, 19)
    local pillStroke = addStroke(FloatingPill, Palette.Accent, 1.5)
    registerAccent(pillStroke, "Color")

    local pillDot = createInstance("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 14, 0.5, -4),
        BackgroundColor3 = Palette.Accent,
        Parent = FloatingPill,
    })
    addCorner(pillDot, 4)
    registerAccent(pillDot, "BackgroundColor3")
    makeDraggable(FloatingPill, FloatingPill, false)

    local BASE_WIDTH = 580
    local BASE_HEIGHT = 385

    local MainFrame = createInstance("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, BASE_WIDTH, 0, BASE_HEIGHT),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Palette.Background,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    addCorner(MainFrame, 12)
    addStroke(MainFrame, Palette.Stroke, 1.2)

    local MainUIScale = createInstance("UIScale", {
        Scale = 1,
        Parent = MainFrame,
    })

    local isWindowOpen = true
    local currentViewportScale = 1

    local function updateResponsiveScale()
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local vp = cam.ViewportSize
        if vp.X <= 0 or vp.Y <= 0 then
            return
        end
        local scaleX = (vp.X - 24) / BASE_WIDTH
        local scaleY = (vp.Y - 24) / BASE_HEIGHT
        currentViewportScale = math.clamp(math.min(1, scaleX, scaleY), 0.58, 1)
        if isWindowOpen then
            MainUIScale.Scale = currentViewportScale
        end
    end

    updateResponsiveScale()
    if workspace.CurrentCamera then
        trackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
    end

    local topAccentLine = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Palette.Accent,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = MainFrame,
    })
    registerAccent(topAccentLine, "BackgroundColor3")

    local TopBar = createInstance("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Palette.Sidebar,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    makeDraggable(TopBar, MainFrame, true)

    createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Palette.Stroke,
        BorderSizePixel = 0,
        Parent = TopBar,
    })

    local brandBadge = createInstance("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 16, 0.5, -5),
        BackgroundColor3 = Palette.Accent,
        Parent = TopBar,
    })
    addCorner(brandBadge, 5)
    registerAccent(brandBadge, "BackgroundColor3")

    createInstance("TextLabel", {
        Size = UDim2.new(0, 320, 0, 20),
        Position = UDim2.new(0, 34, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = titleText,
        TextColor3 = Palette.TextPrimary,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    createInstance("TextLabel", {
        Size = UDim2.new(0, 320, 0, 16),
        Position = UDim2.new(0, 34, 0, 27),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitleText,
        TextColor3 = Palette.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    local MinBtn = createInstance("TextButton", {
        Size = UDim2.new(0, 30, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = Palette.Card,
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = Palette.TextPrimary,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = TopBar,
    })
    addCorner(MinBtn, 6)

    trackConnection(MinBtn.MouseEnter:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.15), { BackgroundColor3 = Palette.CardHover }):Play()
    end))
    trackConnection(MinBtn.MouseLeave:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.15), { BackgroundColor3 = Palette.Card }):Play()
    end))

    local CloseBtn = createInstance("TextButton", {
        Size = UDim2.new(0, 30, 0, 28),
        Position = UDim2.new(1, -36, 0.5, -14),
        BackgroundColor3 = Palette.Card,
        Font = Enum.Font.GothamBold,
        Text = "✕",
        TextColor3 = Palette.Danger,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = TopBar,
    })
    addCorner(CloseBtn, 6)

    trackConnection(CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Palette.Danger,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }):Play()
    end))
    trackConnection(CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Palette.Card,
            TextColor3 = Palette.Danger,
        }):Play()
    end))

    local function toggleMinimize(minimizeState)
        if minimizeState == nil then
            minimizeState = isWindowOpen
        end
        if minimizeState then
            isWindowOpen = false
            local shrink = TweenService:Create(
                MainUIScale,
                TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Scale = currentViewportScale * 0.9 }
            )
            shrink:Play()
            shrink.Completed:Connect(function()
                if not isWindowOpen then
                    MainFrame.Visible = false
                    FloatingPill.Visible = true
                end
            end)
        else
            isWindowOpen = true
            FloatingPill.Visible = false
            MainUIScale.Scale = currentViewportScale * 0.9
            MainFrame.Visible = true
            TweenService:Create(
                MainUIScale,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Scale = currentViewportScale }
            ):Play()
        end
    end

    trackConnection(MinBtn.MouseButton1Click:Connect(function()
        toggleMinimize(true)
    end))

    trackConnection(FloatingPill.MouseButton1Click:Connect(function()
        toggleMinimize(false)
    end))

    trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if ActiveKeybindCapture then
            return
        end
        if not gameProcessed and uiToggleKey and input.KeyCode == uiToggleKey then
            toggleMinimize(isWindowOpen)
        end
    end))

    local Sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 146, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = Palette.Sidebar,
        BorderSizePixel = 0,
        Parent = MainFrame,
    }, {
        createInstance("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }),
        createInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
    })

    createInstance("Frame", {
        Size = UDim2.new(0, 1, 1, -50),
        Position = UDim2.new(0, 146, 0, 50),
        BackgroundColor3 = Palette.Stroke,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    local ContentHolder = createInstance("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -147, 1, -50),
        Position = UDim2.new(0, 147, 0, 50),
        BackgroundTransparency = 1,
        Parent = MainFrame,
    })

    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
    }

    function WindowObj:SetToggleKey(newKeyCode)
        uiToggleKey = newKeyCode
    end

    function WindowObj:Destroy()
        ActiveKeybindCapture = nil
        CancelActiveKeybindFn = nil
        for _, fn in ipairs(CleanupCallbacks) do
            pcall(fn)
        end
        for _, conn in ipairs(Connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(Connections)
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    trackConnection(CloseBtn.MouseButton1Click:Connect(function()
        WindowObj:Destroy()
    end))

    function WindowObj:CreateTab(tabName)
        local tabBtn = createInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Palette.Card,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = "   " .. tabName,
            TextColor3 = Palette.TextSecondary,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = Sidebar,
        })
        addCorner(tabBtn, 8)

        local indicator = createInstance("Frame", {
            Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, 0, 0.5, -9),
            BackgroundColor3 = Palette.Accent,
            Visible = false,
            Parent = tabBtn,
        })
        addCorner(indicator, 2)
        registerAccent(indicator, "BackgroundColor3")

        local page = createInstance("ScrollingFrame", {
            Name = tabName .. "_Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Palette.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = ContentHolder,
        }, {
            createInstance("UIPadding", {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 14),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
            }),
            createInstance("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            })
        })
        registerAccent(page, "ScrollBarImageColor3")

        local tabData = {
            Button = tabBtn,
            Indicator = indicator,
            Page = page,
        }

        local function activateTab()
            for _, t in ipairs(WindowObj.Tabs) do
                t.Page.Visible = false
                t.Indicator.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.18), {
                    BackgroundTransparency = 1,
                    TextColor3 = Palette.TextSecondary,
                }):Play()
            end
            page.Visible = true
            indicator.Visible = true
            TweenService:Create(tabBtn, TweenInfo.new(0.18), {
                BackgroundTransparency = 0,
                TextColor3 = Palette.TextPrimary,
            }):Play()
            WindowObj.ActiveTab = tabData
        end

        trackConnection(tabBtn.MouseButton1Click:Connect(activateTab))
        table.insert(WindowObj.Tabs, tabData)

        if #WindowObj.Tabs == 1 then
            activateTab()
        end

        local TabAPI = {
            Container = page,
        }

        function TabAPI:AddSection(sectionTitle)
            createInstance("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = string.upper(sectionTitle),
                TextColor3 = Palette.TextSecondary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
        end

        function TabAPI:AddInfoCard(title, initialValue)
            local card = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Palette.Card,
                Parent = page,
            })
            addCorner(card, 8)
            addStroke(card, Palette.Stroke, 1)

            createInstance("TextLabel", {
                Size = UDim2.new(0.45, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = title,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })

            local valLabel = createInstance("TextLabel", {
                Size = UDim2.new(0.55, -14, 1, 0),
                Position = UDim2.new(0.45, 0, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = initialValue or "-",
                TextColor3 = Palette.Accent,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = card,
            })
            registerAccent(valLabel, "TextColor3")

            return {
                SetValue = function(_, newVal)
                    valLabel.Text = tostring(newVal)
                end
            }
        end

        function TabAPI:AddToggle(opts)
            local label = opts.Name or "Toggle"
            local state = opts.Default == true
            local callback = opts.Callback or function() end

            local row = createInstance("TextButton", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Palette.Card,
                Text = "",
                AutoButtonColor = false,
                Parent = page,
            })
            addCorner(row, 8)
            addStroke(row, Palette.Stroke, 1)

            createInstance("TextLabel", {
                Size = UDim2.new(1, -74, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = label,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            local switchBg = createInstance("Frame", {
                Size = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(1, -56, 0.5, -11),
                BackgroundColor3 = state and Palette.Accent or Palette.SwitchOff,
                Parent = row,
            })
            addCorner(switchBg, 11)

            local knob = createInstance("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = switchBg,
            })
            addCorner(knob, 8)

            local function updateVisual(newState, fireCallback)
                state = newState
                TweenService:Create(switchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = state and Palette.Accent or Palette.SwitchOff,
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                }):Play()
                if fireCallback then
                    task.spawn(callback, state)
                end
            end

            trackConnection(row.MouseButton1Click:Connect(function()
                updateVisual(not state, true)
            end))

            table.insert(ThemeChangeListeners, function(newAccent)
                if state and switchBg and switchBg.Parent then
                    TweenService:Create(switchBg, TweenInfo.new(0.25), { BackgroundColor3 = newAccent }):Play()
                end
            end)

            return {
                SetState = function(_, newState, silent)
                    local targetState = (newState == true)
                    if state == targetState and not silent then
                        return
                    end
                    updateVisual(targetState, not silent)
                end,
                GetState = function()
                    return state
                end
            }
        end

        function TabAPI:AddSlider(opts)
            local label = opts.Name or "Slider"
            local minVal = opts.Min or 0
            local maxVal = opts.Max or 100
            local currentVal = math.clamp(opts.Default or minVal, minVal, maxVal)
            local suffix = opts.Suffix or ""
            local callback = opts.Callback or function() end

            local card = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = Palette.Card,
                Parent = page,
            })
            addCorner(card, 8)
            addStroke(card, Palette.Stroke, 1)

            createInstance("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 22),
                Position = UDim2.new(0, 12, 0, 6),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = label,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })

            local valLabel = createInstance("TextLabel", {
                Size = UDim2.new(0.3, -12, 0, 22),
                Position = UDim2.new(0.7, 0, 0, 6),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(currentVal) .. suffix,
                TextColor3 = Palette.Accent,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = card,
            })
            registerAccent(valLabel, "TextColor3")

            local hitArea = createInstance("TextButton", {
                Size = UDim2.new(1, -24, 0, 18),
                Position = UDim2.new(0, 12, 0, 31),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = card,
            })

            local track = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 8),
                Position = UDim2.new(0, 0, 0.5, -4),
                BackgroundColor3 = Palette.SwitchOff,
                Parent = hitArea,
            })
            addCorner(track, 4)

            local initialRatio = (currentVal - minVal) / math.max(1, (maxVal - minVal))
            local fill = createInstance("Frame", {
                Size = UDim2.new(initialRatio, 0, 1, 0),
                BackgroundColor3 = Palette.Accent,
                Parent = track,
            })
            addCorner(fill, 4)
            registerAccent(fill, "BackgroundColor3")

            local sliding = false

            local function setSliderFromInput(inputPosX)
                local trackPos = track.AbsolutePosition.X
                local trackSize = math.max(1, track.AbsoluteSize.X)
                local ratio = math.clamp((inputPosX - trackPos) / trackSize, 0, 1)
                local newVal = math.floor(minVal + (maxVal - minVal) * ratio + 0.5)

                fill.Size = UDim2.new(ratio, 0, 1, 0)
                if newVal ~= currentVal then
                    currentVal = newVal
                    valLabel.Text = tostring(currentVal) .. suffix
                    task.spawn(callback, currentVal)
                end
            end

            trackConnection(hitArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    page.ScrollingEnabled = false
                    setSliderFromInput(input.Position.X)
                end
            end))

            trackConnection(UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setSliderFromInput(input.Position.X)
                end
            end))

            trackConnection(UserInputService.InputEnded:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    sliding = false
                    page.ScrollingEnabled = true
                end
            end))

            return {
                SetValue = function(_, val, silent)
                    currentVal = math.clamp(val, minVal, maxVal)
                    local ratio = (currentVal - minVal) / math.max(1, (maxVal - minVal))
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    valLabel.Text = tostring(currentVal) .. suffix
                    if not silent then
                        task.spawn(callback, currentVal)
                    end
                end,
                GetValue = function()
                    return currentVal
                end
            }
        end

        function TabAPI:AddDropdown(opts)
            local label = opts.Name or "Pilih Opsi"
            local items = opts.Options or {}
            local selected = opts.Default or items[1] or "-"
            local callback = opts.Callback or function() end
            local expanded = false
            local optionButtons = {}

            local container = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Palette.Card,
                ClipsDescendants = true,
                Parent = page,
            })
            addCorner(container, 8)
            addStroke(container, Palette.Stroke, 1)

            local headerBtn = createInstance("TextButton", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
                Text = "",
                Parent = container,
            })

            createInstance("TextLabel", {
                Size = UDim2.new(0.46, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = label,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = headerBtn,
            })

            local selectedLabel = createInstance("TextLabel", {
                Size = UDim2.new(0.54, -14, 1, 0),
                Position = UDim2.new(0.46, 0, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = selected .. "  ▼",
                TextColor3 = Palette.Accent,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = headerBtn,
            })
            registerAccent(selectedLabel, "TextColor3")

            local listFrame = createInstance("Frame", {
                Size = UDim2.new(1, -16, 0, #items * 32),
                Position = UDim2.new(0, 8, 0, 44),
                BackgroundTransparency = 1,
                Parent = container,
            }, {
                createInstance("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                })
            })

            local function refreshOptionHighlights()
                for optName, btn in pairs(optionButtons) do
                    local isSelected = (optName == selected)
                    btn.TextColor3 = isSelected and Palette.Accent or Palette.TextSecondary
                    btn.Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham
                end
            end

            local function applySelection(optionText, fireCallback)
                if not optionButtons[optionText] then
                    return
                end
                selected = optionText
                expanded = false
                selectedLabel.Text = selected .. "  ▼"
                refreshOptionHighlights()
                TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, 42)
                }):Play()
                if fireCallback then
                    task.spawn(callback, selected)
                end
            end

            for _, optionText in ipairs(items) do
                local optBtn = createInstance("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Palette.Sidebar,
                    Font = (optionText == selected) and Enum.Font.GothamBold or Enum.Font.Gotham,
                    Text = "  " .. optionText,
                    TextColor3 = (optionText == selected) and Palette.Accent or Palette.TextSecondary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    AutoButtonColor = false,
                    Parent = listFrame,
                })
                addCorner(optBtn, 6)
                optionButtons[optionText] = optBtn

                trackConnection(optBtn.MouseButton1Click:Connect(function()
                    applySelection(optionText, true)
                end))
            end

            table.insert(ThemeChangeListeners, function()
                refreshOptionHighlights()
            end)

            trackConnection(headerBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                selectedLabel.Text = selected .. (expanded and "  ▲" or "  ▼")
                local targetHeight = expanded and (50 + (#items * 32)) or 42
                TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, targetHeight)
                }):Play()
            end))

            return {
                SetValue = function(_, optionText, silent)
                    applySelection(optionText, not silent)
                end,
                GetValue = function()
                    return selected
                end
            }
        end

        function TabAPI:AddButton(opts)
            local label = opts.Name or "Tombol Aksi"
            local callback = opts.Callback or function() end

            local btn = createInstance("TextButton", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Palette.Card,
                Font = Enum.Font.GothamBold,
                Text = label,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                AutoButtonColor = false,
                Parent = page,
            })
            addCorner(btn, 8)
            local btnStroke = addStroke(btn, Palette.Stroke, 1)

            trackConnection(btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Palette.CardHover }):Play()
                TweenService:Create(btnStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
            end))

            trackConnection(btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Palette.Card }):Play()
                TweenService:Create(btnStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
            end))

            trackConnection(btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
            end))
        end

        function TabAPI:AddKeybind(opts)
            local label = opts.Name or "Keybind"
            local currentKey = opts.Default
            local onKeyChanged = opts.OnKeyChanged or function() end
            local onTriggered = opts.Callback or function() end
            local listening = false

            local row = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Palette.Card,
                Parent = page,
            })
            addCorner(row, 8)
            addStroke(row, Palette.Stroke, 1)

            createInstance("TextLabel", {
                Size = UDim2.new(1, -135, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = label,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            local keyBtn = createInstance("TextButton", {
                Size = UDim2.new(0, 112, 0, 28),
                Position = UDim2.new(1, -122, 0.5, -14),
                BackgroundColor3 = Palette.Sidebar,
                Font = Enum.Font.GothamBold,
                Text = currentKey and currentKey.Name or "Belum Diatur",
                TextColor3 = Palette.Accent,
                TextSize = 11,
                AutoButtonColor = false,
                Parent = row,
            })
            addCorner(keyBtn, 6)
            local keyStroke = addStroke(keyBtn, Palette.Stroke, 1)
            registerAccent(keyBtn, "TextColor3")

            local function stopListening()
                listening = false
                if ActiveKeybindCapture == keyBtn then
                    ActiveKeybindCapture = nil
                    CancelActiveKeybindFn = nil
                end
                keyBtn.Text = currentKey and currentKey.Name or "Belum Diatur"
                TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
            end

            trackConnection(keyBtn.MouseButton1Click:Connect(function()
                if listening then
                    stopListening()
                    return
                end
                if CancelActiveKeybindFn then
                    CancelActiveKeybindFn()
                end
                listening = true
                ActiveKeybindCapture = keyBtn
                CancelActiveKeybindFn = stopListening
                keyBtn.Text = "Tekan Tombol..."
                TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
            end))

            trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                            currentKey = nil
                            stopListening()
                            task.spawn(onKeyChanged, nil)
                            BimSakSinUI:Notify({
                                Title = "Keybind Dihapus",
                                Message = label .. " tidak lagi terikat tombol keyboard.",
                                Duration = 2.5,
                            })
                        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                            currentKey = input.KeyCode
                            stopListening()
                            task.spawn(onKeyChanged, currentKey)
                            BimSakSinUI:Notify({
                                Title = "Keybind Diperbarui",
                                Message = label .. " diatur ke tombol [" .. currentKey.Name + "].",
                                Duration = 2.5,
                            })
                        end
                    end
                    return
                end

                if not gameProcessed and not ActiveKeybindCapture and currentKey then
                    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                        task.spawn(onTriggered)
                    end
                end
            end))

            return {
                GetKey = function()
                    return currentKey
                end,
                SetKey = function(_, newKey, silent)
                    currentKey = newKey
                    stopListening()
                    if not silent then
                        task.spawn(onKeyChanged, currentKey)
                    end
                end,
            }
        end

        function TabAPI:AddCoordinateInput(opts)
            local title = opts.Name or "Teleport Koordinat (X, Y, Z)"
            local onTeleport = opts.OnTeleport or function() end

            local card = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 118),
                BackgroundColor3 = Palette.Card,
                Parent = page,
            })
            addCorner(card, 8)
            addStroke(card, Palette.Stroke, 1)

            createInstance("TextLabel", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.new(0, 12, 0, 8),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = title,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })

            local inputsContainer = createInstance("Frame", {
                Size = UDim2.new(1, -24, 0, 32),
                Position = UDim2.new(0, 12, 0, 34),
                BackgroundTransparency = 1,
                Parent = card,
            })

            local axisNames = { "X", "Y", "Z" }
            local axisBoxes = {}

            for i, axis in ipairs(axisNames) do
                local cell = createInstance("Frame", {
                    Size = UDim2.new(0.32, 0, 1, 0),
                    Position = UDim2.new((i - 1) * 0.34, 0, 0, 0),
                    BackgroundColor3 = Palette.Sidebar,
                    Parent = inputsContainer,
                })
                addCorner(cell, 6)
                local cellStroke = addStroke(cell, Palette.Stroke, 1)

                local axisLbl = createInstance("TextLabel", {
                    Size = UDim2.new(0, 22, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = axis .. ":",
                    TextColor3 = Palette.Accent,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = cell,
                })
                registerAccent(axisLbl, "TextColor3")

                local box = createInstance("TextBox", {
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 24, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    PlaceholderText = "0.0",
                    PlaceholderColor3 = Palette.TextSecondary,
                    Text = "",
                    TextColor3 = Palette.TextPrimary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = cell,
                })

                trackConnection(box.Focused:Connect(function()
                    TweenService:Create(cellStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
                end))

                trackConnection(box.FocusLost:Connect(function()
                    TweenService:Create(cellStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
                end))

                axisBoxes[axis] = box
            end

            local actionsRow = createInstance("Frame", {
                Size = UDim2.new(1, -24, 0, 32),
                Position = UDim2.new(0, 12, 0, 74),
                BackgroundTransparency = 1,
                Parent = card,
            })

            local captureBtn = createInstance("TextButton", {
                Size = UDim2.new(0.48, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Palette.Sidebar,
                Font = Enum.Font.GothamSemibold,
                Text = "Ambil Posisi Saat Ini",
                TextColor3 = Palette.TextPrimary,
                TextSize = 11,
                AutoButtonColor = false,
                Parent = actionsRow,
            })
            addCorner(captureBtn, 6)
            addStroke(captureBtn, Palette.Stroke, 1)

            local tpCoordBtn = createInstance("TextButton", {
                Size = UDim2.new(0.49, 0, 1, 0),
                Position = UDim2.new(0.51, 0, 0, 0),
                BackgroundColor3 = Palette.Accent,
                Font = Enum.Font.GothamBold,
                Text = "Teleport ke Koordinat",
                TextColor3 = Color3.fromRGB(15, 20, 28),
                TextSize = 11,
                AutoButtonColor = false,
                Parent = actionsRow,
            })
            addCorner(tpCoordBtn, 6)
            registerAccent(tpCoordBtn, "BackgroundColor3")

            local function parseCoords()
                local x = tonumber((axisBoxes.X.Text:gsub(",", ".")))
                local y = tonumber((axisBoxes.Y.Text:gsub(",", ".")))
                local z = tonumber((axisBoxes.Z.Text:gsub(",", ".")))
                return x, y, z
            end

            local function executeTeleport()
                local x, y, z = parseCoords()
                if not x or not y or not z then
                    BimSakSinUI:Notify({
                        Title = "Koordinat Tidak Valid",
                        Message = "Pastikan nilai X, Y, dan Z berisi angka yang valid.",
                        Duration = 3,
                    })
                    return
                end
                task.spawn(onTeleport, Vector3.new(x, y, z))
            end

            trackConnection(captureBtn.MouseButton1Click:Connect(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    BimSakSinUI:Notify({
                        Title = "Gagal Mengambil Posisi",
                        Message = "Karakter kamu belum aktif di dalam map.",
                        Duration = 2.5,
                    })
                    return
                end
                local pos = hrp.Position
                axisBoxes.X.Text = string.format("%.1f", pos.X)
                axisBoxes.Y.Text = string.format("%.1f", pos.Y)
                axisBoxes.Z.Text = string.format("%.1f", pos.Z)
                BimSakSinUI:Notify({
                    Title = "Posisi Tersimpan",
                    Message = string.format("Koordinat: %.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z),
                    Duration = 2.5,
                })
            end))

            trackConnection(tpCoordBtn.MouseButton1Click:Connect(executeTeleport))

            return {
                SetCoordinates = function(_, vec3)
                    axisBoxes.X.Text = string.format("%.1f", vec3.X)
                    axisBoxes.Y.Text = string.format("%.1f", vec3.Y)
                    axisBoxes.Z.Text = string.format("%.1f", vec3.Z)
                end,
                GetCoordinates = parseCoords,
                TriggerTeleport = executeTeleport,
            }
        end

        function TabAPI:AddWaypointManager(opts)
            local getCustomCoords = opts.GetCoordinates or function() return nil end
            local onLoadToInput = opts.OnLoadToInput or function() end
            local onTeleport = opts.OnTeleport or function() end
            local onWaypointsChanged = opts.OnWaypointsChanged or function() end

            local savedWaypoints = {}
            local waypointCounter = 1

            local createCard = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 88),
                BackgroundColor3 = Palette.Card,
                Parent = page,
            })
            addCorner(createCard, 8)
            addStroke(createCard, Palette.Stroke, 1)

            local nameCell = createInstance("Frame", {
                Size = UDim2.new(1, -24, 0, 32),
                Position = UDim2.new(0, 12, 0, 10),
                BackgroundColor3 = Palette.Sidebar,
                Parent = createCard,
            })
            addCorner(nameCell, 6)
            local nameStroke = addStroke(nameCell, Palette.Stroke, 1)

            local nameBox = createInstance("TextBox", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                PlaceholderText = "Nama lokasi favorit (opsional, mis. Base / Puncak)...",
                PlaceholderColor3 = Palette.TextSecondary,
                Text = "",
                TextColor3 = Palette.TextPrimary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = nameCell,
            })

            trackConnection(nameBox.Focused:Connect(function()
                TweenService:Create(nameStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
            end))

            trackConnection(nameBox.FocusLost:Connect(function()
                TweenService:Create(nameStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
            end))

            local btnRow = createInstance("Frame", {
                Size = UDim2.new(1, -24, 0, 30),
                Position = UDim2.new(0, 12, 0, 48),
                BackgroundTransparency = 1,
                Parent = createCard,
            })

            local saveCurrentBtn = createInstance("TextButton", {
                Size = UDim2.new(0.49, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Palette.Accent,
                Font = Enum.Font.GothamBold,
                Text = "+ Simpan Posisi Saat Ini",
                TextColor3 = Color3.fromRGB(15, 20, 28),
                TextSize = 11,
                AutoButtonColor = false,
                Parent = btnRow,
            })
            addCorner(saveCurrentBtn, 6)
            registerAccent(saveCurrentBtn, "BackgroundColor3")

            local saveInputBtn = createInstance("TextButton", {
                Size = UDim2.new(0.49, 0, 1, 0),
                Position = UDim2.new(0.51, 0, 0, 0),
                BackgroundColor3 = Palette.Sidebar,
                Font = Enum.Font.GothamSemibold,
                Text = "+ Simpan dari Input X/Y/Z",
                TextColor3 = Palette.TextPrimary,
                TextSize = 11,
                AutoButtonColor = false,
                Parent = btnRow,
            })
            addCorner(saveInputBtn, 6)
            addStroke(saveInputBtn, Palette.Stroke, 1)

            local listHeaderRow = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent = page,
            })

            local countLabel = createInstance("TextLabel", {
                Size = UDim2.new(0.65, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = "Daftar Tersimpan (0 Lokasi)",
                TextColor3 = Palette.TextSecondary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = listHeaderRow,
            })

            local clearAllBtn = createInstance("TextButton", {
                Size = UDim2.new(0, 96, 0, 22),
                Position = UDim2.new(1, -96, 0.5, -11),
                BackgroundColor3 = Palette.Card,
                Font = Enum.Font.GothamBold,
                Text = "Hapus Semua",
                TextColor3 = Palette.Danger,
                TextSize = 10,
                Visible = false,
                AutoButtonColor = false,
                Parent = listHeaderRow,
            })
            addCorner(clearAllBtn, 6)
            addStroke(clearAllBtn, Palette.Stroke, 1)

            local listContainer = createInstance("Frame", {
                Name = "WaypointListContainer",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = page,
            }, {
                createInstance("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                })
            })

            local function rebuildWaypointList()
                for _, child in ipairs(listContainer:GetChildren()) do
                    if child:IsA("Frame") then
                        child:Destroy()
                    end
                end

                local total = #savedWaypoints
                countLabel.Text = string.format("Daftar Tersimpan (%d Lokasi)", total)
                clearAllBtn.Visible = (total > 0)

                if total == 0 then
                    local emptyCard = createInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, 38),
                        BackgroundColor3 = Palette.Card,
                        Parent = listContainer,
                    })
                    addCorner(emptyCard, 8)
                    addStroke(emptyCard, Palette.Stroke, 1)

                    createInstance("TextLabel", {
                        Size = UDim2.new(1, -24, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = "Belum ada lokasi teleport favorit yang disimpan.",
                        TextColor3 = Palette.TextSecondary,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = emptyCard,
                    })
                    return
                end

                for idx, wp in ipairs(savedWaypoints) do
                    local row = createInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, 48),
                        BackgroundColor3 = Palette.Card,
                        Parent = listContainer,
                    })
                    addCorner(row, 8)
                    addStroke(row, Palette.Stroke, 1)

                    createInstance("TextLabel", {
                        Size = UDim2.new(1, -148, 0, 18),
                        Position = UDim2.new(0, 12, 0, 6),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        Text = wp.Name,
                        TextColor3 = Palette.TextPrimary,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = row,
                    })

                    createInstance("TextLabel", {
                        Size = UDim2.new(1, -148, 0, 15),
                        Position = UDim2.new(0, 12, 0, 25),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = string.format("X: %.1f • Y: %.1f • Z: %.1f", wp.Position.X, wp.Position.Y, wp.Position.Z),
                        TextColor3 = Palette.TextSecondary,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = row,
                    })

                    local loadBtn = createInstance("TextButton", {
                        Size = UDim2.new(0, 40, 0, 28),
                        Position = UDim2.new(1, -134, 0.5, -14),
                        BackgroundColor3 = Palette.Sidebar,
                        Font = Enum.Font.GothamBold,
                        Text = "Isi",
                        TextColor3 = Palette.TextPrimary,
                        TextSize = 11,
                        AutoButtonColor = false,
                        Parent = row,
                    })
                    addCorner(loadBtn, 6)
                    addStroke(loadBtn, Palette.Stroke, 1)

                    loadBtn.MouseButton1Click:Connect(function()
                        task.spawn(onLoadToInput, wp.Position, wp.Name)
                    end)

                    local tpBtn = createInstance("TextButton", {
                        Size = UDim2.new(0, 44, 0, 28),
                        Position = UDim2.new(1, -88, 0.5, -14),
                        BackgroundColor3 = Palette.Accent,
                        Font = Enum.Font.GothamBold,
                        Text = "TP",
                        TextColor3 = Color3.fromRGB(15, 20, 28),
                        TextSize = 11,
                        AutoButtonColor = false,
                        Parent = row,
                    })
                    addCorner(tpBtn, 6)
                    registerAccent(tpBtn, "BackgroundColor3")

                    tpBtn.MouseButton1Click:Connect(function()
                        task.spawn(onTeleport, wp.Position, wp.Name)
                    end)

                    local delBtn = createInstance("TextButton", {
                        Size = UDim2.new(0, 28, 0, 28),
                        Position = UDim2.new(1, -38, 0.5, -14),
                        BackgroundColor3 = Palette.Sidebar,
                        Font = Enum.Font.GothamBold,
                        Text = "✕",
                        TextColor3 = Palette.Danger,
                        TextSize = 11,
                        AutoButtonColor = false,
                        Parent = row,
                    })
                    addCorner(delBtn, 6)
                    addStroke(delBtn, Palette.Stroke, 1)

                    delBtn.MouseButton1Click:Connect(function()
                        local removedName = wp.Name
                        table.remove(savedWaypoints, idx)
                        rebuildWaypointList()
                        onWaypointsChanged(savedWaypoints)
                        BimSakSinUI:Notify({
                            Title = "Waypoint Dihapus",
                            Message = "Lokasi \"" .. removedName .. "\" telah dihapus.",
                            Duration = 2.5,
                        })
                    end)
                end
            end

            local function addWaypointEntry(vec3)
                local rawName = nameBox.Text:match("^%s*(.-)%s*$") or ""
                local finalName = (rawName ~= "") and rawName or ("Lokasi #" .. tostring(waypointCounter))
                waypointCounter = waypointCounter + 1
                nameBox.Text = ""

                table.insert(savedWaypoints, {
                    Name = finalName,
                    Position = vec3,
                })
                rebuildWaypointList()
                onWaypointsChanged(savedWaypoints)

                BimSakSinUI:Notify({
                    Title = "Waypoint Tersimpan",
                    Message = string.format("\"%s\" (%.1f, %.1f, %.1f)", finalName, vec3.X, vec3.Y, vec3.Z),
                    Duration = 3,
                })
            end

            trackConnection(saveCurrentBtn.MouseButton1Click:Connect(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    BimSakSinUI:Notify({
                        Title = "Gagal Menyimpan",
                        Message = "Karakter kamu belum aktif di dalam map.",
                        Duration = 2.5,
                    })
                    return
                end
                addWaypointEntry(hrp.Position)
            end))

            trackConnection(saveInputBtn.MouseButton1Click:Connect(function()
                local x, y, z = getCustomCoords()
                if not x or not y or not z then
                    BimSakSinUI:Notify({
                        Title = "Input X/Y/Z Kosong",
                        Message = "Isi koordinat X, Y, dan Z terlebih dahulu.",
                        Duration = 2.5,
                    })
                    return
                end
                addWaypointEntry(Vector3.new(x, y, z))
            end))

            trackConnection(clearAllBtn.MouseButton1Click:Connect(function()
                table.clear(savedWaypoints)
                rebuildWaypointList()
                onWaypointsChanged(savedWaypoints)
                BimSakSinUI:Notify({
                    Title = "Daftar Dikosongkan",
                    Message = "Semua lokasi waypoint favorit telah dihapus.",
                    Duration = 2.5,
                })
            end))

            rebuildWaypointList()

            return {
                GetWaypoints = function()
                    return savedWaypoints
                end,
                SetWaypoints = function(_, rawEntries)
                    table.clear(savedWaypoints)
                    for _, entry in ipairs(rawEntries or {}) do
                        table.insert(savedWaypoints, {
                            Name = entry.Name,
                            Position = Vector3.new(entry.X, entry.Y, entry.Z),
                        })
                    end
                    waypointCounter = #savedWaypoints + 1
                    rebuildWaypointList()
                end,
                ClearWaypoints = function(_, silent)
                    table.clear(savedWaypoints)
                    waypointCounter = 1
                    rebuildWaypointList()
                    if not silent then
                        onWaypointsChanged(savedWaypoints)
                    end
                end
            }
        end

        return TabAPI
    end

    return WindowObj
end

-- ============================================================================
-- INISIALISASI PANEL & TAB UTAMA (BIMSAKSIN HUB v4.6 - MODULAR DIPECAH)
-- ============================================================================
local initialUiKey = resolveKeyCodeFromName(ConfigData.ToggleUIKey)

local Window = BimSakSinUI:CreateWindow({
    Title = "BimSakSin Hub v4.6",
    Subtitle = "Professional Roblox Suite • Auto-Farm & Perfect",
    ToggleKey = initialUiKey,
})

local TabDashboard  = Window:CreateTab("Dashboard")
local TabPlayerList = Window:CreateTab("Pemain")
local TabPlayer     = Window:CreateTab("Karakter")
local TabVisual     = Window:CreateTab("Visual")
local TabSettings   = Window:CreateTab("Pengaturan")

-- ---------------- TAB 1: DASHBOARD (Fungsi Modular) ----------------
local function initTabDashboard()
    TabDashboard:AddSection("Telemetri Performa Real-Time")
    local fpsCard  = TabDashboard:AddInfoCard("Frame Rate (FPS)", "60 FPS")
    local pingCard = TabDashboard:AddInfoCard("Latensi Jaringan (Ping)", "0 ms")

    TabDashboard:AddSection("Informasi Sesi & Server")
    TabDashboard:AddInfoCard("Nama Pemain", LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")")
    local playerCountCard = TabDashboard:AddInfoCard("Jumlah Pemain di Server", tostring(#Players:GetPlayers()) .. " Pemain")
    TabDashboard:AddInfoCard("Place ID", tostring(game.PlaceId))

    TabDashboard:AddButton({
        Name = "Salin Place ID ke Clipboard",
        Callback = function()
            local placeStr = tostring(game.PlaceId)
            local copied = pcall(function()
                if type(setclipboard) == "function" then
                    setclipboard(placeStr)
                else
                    error("Clipboard API tidak tersedia")
                end
            end)
            if copied then
                BimSakSinUI:Notify({
                    Title = "Berhasil Disalin",
                    Message = "Place ID (" .. placeStr .. ") tersimpan di clipboard.",
                    Duration = 3,
                })
            else
                BimSakSinUI:Notify({
                    Title = "Place ID",
                    Message = "ID Map: " .. placeStr,
                    Duration = 4,
                })
            end
        end
    })

    local currentJobId = tostring(game.JobId or "")
    local displayJobId = (currentJobId ~= "") and currentJobId or "Studio / Server Lokal"
    TabDashboard:AddInfoCard("Server Job ID", displayJobId)

    TabDashboard:AddButton({
        Name = "Salin JobId Server ke Clipboard",
        Callback = function()
            local jobStr = tostring(game.JobId or "")
            if jobStr == "" then
                BimSakSinUI:Notify({
                    Title = "JobId Tidak Tersedia",
                    Message = "Server lokal / Roblox Studio tidak memiliki JobId publik.",
                    Duration = 3,
                })
                return
            end
            local copied = pcall(function()
                if type(setclipboard) == "function" then
                    setclipboard(jobStr)
                else
                    error("Clipboard API tidak tersedia")
                end
            end)
            if copied then
                BimSakSinUI:Notify({
                    Title = "JobId Disalin",
                    Message = "Kode JobId server tersimpan di clipboard.",
                    Duration = 3,
                })
            else
                BimSakSinUI:Notify({
                    Title = "Server Job ID",
                    Message = jobStr,
                    Duration = 5,
                })
            end
        end
    })
    return fpsCard, pingCard, playerCountCard
end

local fpsCard, pingCard, playerCountCard = initTabDashboard()

-- ---------------- TAB 2: DAFTAR PEMAIN (TP & SPECTATE - Modular) ----------------
local spectatedPlayer = nil
local spectateButtons = {}
local ThumbnailCache = {}
local spectateStatusCard

local function initTabPlayerList()
    TabPlayerList:AddSection("Kontrol Kamera & Pencarian")
    spectateStatusCard = TabPlayerList:AddInfoCard("Status Spectate", "Kamera Lokal (Kamu)")

    local searchFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Palette.Card,
        Parent = TabPlayerList.Container,
    })
    addCorner(searchFrame, 8)
    local searchStroke = addStroke(searchFrame, Palette.Stroke, 1)

    local searchBox = createInstance("TextBox", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Cari nama atau @username pemain...",
        PlaceholderColor3 = Palette.TextSecondary,
        Text = "",
        TextColor3 = Palette.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchFrame,
    })

    trackConnection(searchBox.Focused:Connect(function()
        TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
    end))

    trackConnection(searchBox.FocusLost:Connect(function()
        TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
    end))

    return searchBox
end

local searchBox = initTabPlayerList()

local function updateAllSpectateButtons()
    for plr, btn in pairs(spectateButtons) do
        if btn and btn.Parent then
            local isTarget = (spectatedPlayer == plr)
            btn.Text = isTarget and "Stop" or "Lihat"
            btn.BackgroundColor3 = isTarget and Palette.Danger or Palette.Sidebar
            btn.TextColor3 = isTarget and Color3.fromRGB(255, 255, 255) or Palette.TextPrimary
        end
    end
end

local function stopSpectate(silent)
    spectatedPlayer = nil
    if spectateStatusCard then
        spectateStatusCard:SetValue("Kamera Lokal (Kamu)")
    end
    updateAllSpectateButtons()

    local cam = workspace.CurrentCamera
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if cam and myHum then
        cam.CameraSubject = myHum
        cam.CameraType = Enum.CameraType.Custom
    end

    if not silent then
        BimSakSinUI:Notify({
            Title = "Spectate Dihentikan",
            Message = "Kamera dikembalikan ke karaktermu.",
            Duration = 2.5,
        })
    end
end

registerCleanup(function()
    stopSpectate(true)
    table.clear(ThumbnailCache)
end)

local function startSpectate(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then
        BimSakSinUI:Notify({
            Title = "Gagal Spectate",
            Message = "Pemain sudah keluar dari server.",
            Duration = 2.5,
        })
        return
    end

    local targetChar = targetPlayer.Character
    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera

    if not cam or not targetHum then
        BimSakSinUI:Notify({
            Title = "Karakter Belum Siap",
            Message = targetPlayer.DisplayName .. " belum spawn di map.",
            Duration = 2.5,
        })
        return
    end

    spectatedPlayer = targetPlayer
    cam.CameraSubject = targetHum
    cam.CameraType = Enum.CameraType.Custom
    if spectateStatusCard then
        spectateStatusCard:SetValue(targetPlayer.DisplayName)
    end
    updateAllSpectateButtons()

    BimSakSinUI:Notify({
        Title = "Mode Spectate Aktif",
        Message = "Memantau kamera: " .. targetPlayer.DisplayName,
        Duration = 2.5,
    })
end

local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then
        BimSakSinUI:Notify({
            Title = "Teleport Gagal",
            Message = "Pemain target tidak ditemukan di server.",
            Duration = 2.5,
        })
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetChar = targetPlayer.Character
    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if not myHRP then
        BimSakSinUI:Notify({
            Title = "Teleport Gagal",
            Message = "Karakter kamu belum aktif atau sedang mati.",
            Duration = 2.5,
        })
        return
    end

    if not targetHRP then
        BimSakSinUI:Notify({
            Title = "Teleport Gagal",
            Message = "Karakter " .. targetPlayer.DisplayName .. " belum spawn.",
            Duration = 2.5,
        })
        return
    end

    myHRP.AssemblyLinearVelocity = Vector3.zero
    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)

    BimSakSinUI:Notify({
        Title = "Teleport Berhasil",
        Message = "Berpindah ke lokasi " .. targetPlayer.DisplayName,
        Duration = 2.5,
    })
end

TabPlayerList:AddButton({
    Name = "Reset Kamera ke Karakter Sendiri",
    Callback = function()
        stopSpectate(false)
    end
})

TabPlayerList:AddSection("Daftar Pemain Aktif di Server")

local playerRowsContainer = createInstance("Frame", {
    Name = "PlayerRowsContainer",
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Parent = TabPlayerList.Container,
}, {
    createInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
})

local function rebuildPlayerList()
    for _, child in ipairs(playerRowsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    table.clear(spectateButtons)

    local query = string.lower(searchBox.Text or "")
    local allPlayers = Players:GetPlayers()

    table.sort(allPlayers, function(a, b)
        if a == LocalPlayer then
            return true
        end
        if b == LocalPlayer then
            return false
        end
        return string.lower(a.DisplayName) < string.lower(b.DisplayName)
    end)

    for _, plr in ipairs(allPlayers) do
        local matchDisplay = string.find(string.lower(plr.DisplayName), query, 1, true)
        local matchUser = string.find(string.lower(plr.Name), query, 1, true)

        if query == "" or matchDisplay or matchUser then
            local row = createInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Palette.Card,
                Parent = playerRowsContainer,
            })
            addCorner(row, 8)
            addStroke(row, Palette.Stroke, 1)

            local cachedThumb = ThumbnailCache[plr.UserId]
            local avatarImg = createInstance("ImageLabel", {
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(0, 8, 0.5, -17),
                BackgroundColor3 = Palette.Sidebar,
                Image = cachedThumb or "",
                Parent = row,
            })
            addCorner(avatarImg, 17)

            if not cachedThumb then
                task.spawn(function()
                    local ok, thumbUrl = pcall(function()
                        return Players:GetUserThumbnailAsync(
                            plr.UserId,
                            Enum.ThumbnailType.HeadShot,
                            Enum.ThumbnailSize.Size48x48
                        )
                    end)
                    if ok and thumbUrl then
                        ThumbnailCache[plr.UserId] = thumbUrl
                        if avatarImg and avatarImg.Parent then
                            avatarImg.Image = thumbUrl
                        end
                    end
                end)
            end

            local isSelf = (plr == LocalPlayer)
            local textRightMargin = isSelf and -70 or -134

            createInstance("TextLabel", {
                Size = UDim2.new(1, textRightMargin, 0, 18),
                Position = UDim2.new(0, 50, 0, 7),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = plr.DisplayName,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            local subtitleInfo = "@" .. plr.Name
            if not plr.Neutral and plr.Team then
                subtitleInfo = subtitleInfo .. " • " .. plr.Team.Name
            end

            createInstance("TextLabel", {
                Size = UDim2.new(1, textRightMargin, 0, 15),
                Position = UDim2.new(0, 50, 0, 26),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = subtitleInfo,
                TextColor3 = Palette.TextSecondary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            if isSelf then
                local selfBadge = createInstance("TextLabel", {
                    Size = UDim2.new(0, 54, 0, 24),
                    Position = UDim2.new(1, -62, 0.5, -12),
                    BackgroundColor3 = Palette.Sidebar,
                    Font = Enum.Font.GothamBold,
                    Text = "Kamu",
                    TextColor3 = Palette.Accent,
                    TextSize = 11,
                    Parent = row,
                })
                addCorner(selfBadge, 6)
                registerAccent(selfBadge, "TextColor3")
            else
                local isTarget = (spectatedPlayer == plr)
                local specBtn = createInstance("TextButton", {
                    Size = UDim2.new(0, 56, 0, 28),
                    Position = UDim2.new(1, -120, 0.5, -14),
                    BackgroundColor3 = isTarget and Palette.Danger or Palette.Sidebar,
                    Font = Enum.Font.GothamBold,
                    Text = isTarget and "Stop" or "Lihat",
                    TextColor3 = isTarget and Color3.fromRGB(255, 255, 255) or Palette.TextPrimary,
                    TextSize = 11,
                    AutoButtonColor = false,
                    Parent = row,
                })
                addCorner(specBtn, 6)
                addStroke(specBtn, Palette.Stroke, 1)
                spectateButtons[plr] = specBtn

                trackConnection(specBtn.MouseButton1Click:Connect(function()
                    if spectatedPlayer == plr then
                        stopSpectate(false)
                    else
                        startSpectate(plr)
                    end
                end))

                local tpBtn = createInstance("TextButton", {
                    Size = UDim2.new(0, 48, 0, 28),
                    Position = UDim2.new(1, -56, 0.5, -14),
                    BackgroundColor3 = Palette.Accent,
                    Font = Enum.Font.GothamBold,
                    Text = "TP",
                    TextColor3 = Color3.fromRGB(15, 20, 28),
                    TextSize = 11,
                    AutoButtonColor = false,
                    Parent = row,
                })
                addCorner(tpBtn, 6)
                registerAccent(tpBtn, "BackgroundColor3")

                trackConnection(tpBtn.MouseButton1Click:Connect(function()
                    teleportToPlayer(plr)
                end))
            end
        end
    end
end

trackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(rebuildPlayerList))

-- ---------------- TAB 3: KARAKTER, FLY, NOCLIP & WAYPOINT (Modular) ----------------
local desiredWalkSpeed = ConfigData.WalkSpeed
local desiredJumpPower = ConfigData.JumpPower
local lockCharacterStats = ConfigData.LockStats
local statLockConnections = {}

local infiniteJumpEnabled = false
local lastAirJumpTime = 0
local AIR_JUMP_COOLDOWN = 0.18

local noclipEnabled = false
local cachedCharParts = {}
local charPartConnections = {}
local originalCollideStates = setmetatable({}, { __mode = "k" })

local function rebuildCharacterPartsCache(char)
    for _, c in ipairs(charPartConnections) do
        if c and c.Connected then
            c:Disconnect()
        end
    end
    table.clear(charPartConnections)
    table.clear(cachedCharParts)

    if not char then
        return
    end

    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") then
            table.insert(cachedCharParts, desc)
        end
    end

    table.insert(charPartConnections, char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(cachedCharParts, desc)
        end
    end))

    table.insert(charPartConnections, char.DescendantRemoving:Connect(function(desc)
        if desc:IsA("BasePart") then
            local idx = table.find(cachedCharParts, desc)
            if idx then
                table.remove(cachedCharParts, idx)
            end
            originalCollideStates[desc] = nil
        end
    end))
end

local flyEnabled = false
local flySpeed = ConfigData.FlySpeed
local currentFlyVelocity = Vector3.zero
local flyAttachment = nil
local flyLinearVel = nil
local flyAlignOrient = nil
local mobileFlyUpHeld = false
local mobileFlyDownHeld = false

local MobileFlyHud = createInstance("Frame", {
    Name = "MobileFlyControls",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -18, 0.5, 0),
    Size = UDim2.new(0, 68, 0, 114),
    BackgroundColor3 = Palette.Background,
    BackgroundTransparency = 0.12,
    Visible = false,
    ZIndex = 8,
    Parent = ScreenGui,
})
addCorner(MobileFlyHud, 12)
addStroke(MobileFlyHud, Palette.Stroke, 1.2)
makeDraggable(MobileFlyHud, MobileFlyHud, true)

local flyUpBtn = createInstance("TextButton", {
    Size = UDim2.new(1, -12, 0, 46),
    Position = UDim2.new(0, 6, 0, 6),
    BackgroundColor3 = Palette.Card,
    Font = Enum.Font.GothamBold,
    Text = "▲\nNaik",
    TextColor3 = Palette.Accent,
    TextSize = 11,
    AutoButtonColor = false,
    Parent = MobileFlyHud,
})
addCorner(flyUpBtn, 8)
addStroke(flyUpBtn, Palette.Stroke, 1)
registerAccent(flyUpBtn, "TextColor3")

local flyDownBtn = createInstance("TextButton", {
    Size = UDim2.new(1, -12, 0, 46),
    Position = UDim2.new(0, 6, 0, 60),
    BackgroundColor3 = Palette.Card,
    Font = Enum.Font.GothamBold,
    Text = "Turun\n▼",
    TextColor3 = Palette.TextPrimary,
    TextSize = 11,
    AutoButtonColor = false,
    Parent = MobileFlyHud,
})
addCorner(flyDownBtn, 8)
addStroke(flyDownBtn, Palette.Stroke, 1)

trackConnection(flyUpBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mobileFlyUpHeld = true
        flyUpBtn.BackgroundColor3 = Palette.CardHover
    end
end))
trackConnection(flyUpBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mobileFlyUpHeld = false
        flyUpBtn.BackgroundColor3 = Palette.Card
    end
end))

trackConnection(flyDownBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mobileFlyDownHeld = true
        flyDownBtn.BackgroundColor3 = Palette.CardHover
    end
end))
trackConnection(flyDownBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mobileFlyDownHeld = false
        flyDownBtn.BackgroundColor3 = Palette.Card
    end
end))

local function destroyFlyConstraints()
    mobileFlyUpHeld = false
    mobileFlyDownHeld = false
    if MobileFlyHud and MobileFlyHud.Parent then
        MobileFlyHud.Visible = false
    end

    if flyLinearVel then
        flyLinearVel:Destroy()
        flyLinearVel = nil
    end
    if flyAlignOrient then
        flyAlignOrient:Destroy()
        flyAlignOrient = nil
    end
    if flyAttachment then
        flyAttachment:Destroy()
        flyAttachment = nil
    end
    currentFlyVelocity = Vector3.zero

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function setupFlyConstraints(char)
    destroyFlyConstraints()
    if not char then
        return false
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        return false
    end

    hum.PlatformStand = true
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    local att = Instance.new("Attachment")
    att.Name = "BimSakSinFlyAttachment"
    att.Parent = hrp
    flyAttachment = att

    local lv = Instance.new("LinearVelocity")
    lv.Name = "BimSakSinLinearVelocity"
    lv.Attachment0 = att
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.MaxForce = math.huge
    lv.VectorVelocity = Vector3.zero
    lv.Parent = hrp
    flyLinearVel = lv

    local ao = Instance.new("AlignOrientation")
    ao.Name = "BimSakSinAlignOrientation"
    ao.Attachment0 = att
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.RigidityEnabled = false
    ao.Responsiveness = 25
    ao.MaxTorque = math.huge
    ao.CFrame = hrp.CFrame
    ao.Parent = hrp
    flyAlignOrient = ao

    if MobileFlyHud and MobileFlyHud.Parent then
        MobileFlyHud.Visible = true
    end

    return true
end

local function restoreCharacterCollision()
    for part, wasCollidable in pairs(originalCollideStates) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CanCollide = wasCollidable
        end
    end
    table.clear(originalCollideStates)

    local char = LocalPlayer.Character
    if char then
        for _, partName in ipairs({ "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Head" }) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function bindCharacterStatLocks(char)
    for _, c in ipairs(statLockConnections) do
        if c and c.Connected then
            c:Disconnect()
        end
    end
    table.clear(statLockConnections)

    if not char then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then
        return
    end

    table.insert(statLockConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if lockCharacterStats and not flyEnabled and hum.WalkSpeed ~= desiredWalkSpeed then
            hum.WalkSpeed = desiredWalkSpeed
        end
    end))

    table.insert(statLockConnections, hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if lockCharacterStats and not flyEnabled and hum.JumpPower ~= desiredJumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = desiredJumpPower
        end
    end))
end

registerCleanup(function()
    infiniteJumpEnabled = false
    flyEnabled = false
    destroyFlyConstraints()
    noclipEnabled = false
    restoreCharacterCollision()
    for _, c in ipairs(statLockConnections) do
        if c and c.Connected then
            c:Disconnect()
        end
    end
    table.clear(statLockConnections)
    for _, c in ipairs(charPartConnections) do
        if c and c.Connected then
            c:Disconnect()
        end
    end
    table.clear(charPartConnections)
    table.clear(cachedCharParts)
end)

local function applyCharacterStats()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = desiredWalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = desiredJumpPower
    end
end

if LocalPlayer.Character then
    rebuildCharacterPartsCache(LocalPlayer.Character)
    bindCharacterStatLocks(LocalPlayer.Character)
    if desiredWalkSpeed ~= 16 or desiredJumpPower ~= 50 or lockCharacterStats then
        applyCharacterStats()
    end
end

local function teleportToVector3(targetPos, locationLabel)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        BimSakSinUI:Notify({
            Title = "Teleport Gagal",
            Message = "Karakter kamu belum aktif atau sedang mati.",
            Duration = 2.5,
        })
        return
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    local currentRot = hrp.CFrame.Rotation
    hrp.CFrame = CFrame.new(targetPos) * currentRot

    local titleStr = locationLabel and ("Teleport: " .. locationLabel) or "Teleport Koordinat Berhasil"
    BimSakSinUI:Notify({
        Title = titleStr,
        Message = string.format("Berpindah ke X: %.1f, Y: %.1f, Z: %.1f", targetPos.X, targetPos.Y, targetPos.Z),
        Duration = 3,
    })
end

local function initTabPlayer()
    TabPlayer:AddSection("Kontrol Terbang (Fly Mode)")

    local flyToggle = TabPlayer:AddToggle({
        Name = "Fly Mode (Terbang Bebas)",
        Default = false,
        Callback = function(state)
            flyEnabled = state
            if state then
                local ok = setupFlyConstraints(LocalPlayer.Character)
                if not ok then
                    BimSakSinUI:Notify({
                        Title = "Menunggu Karakter",
                        Message = "Fly akan otomatis aktif saat karakter spawn.",
                        Duration = 2.5,
                    })
                    return
                end
                BimSakSinUI:Notify({
                    Title = "Fly Mode Aktif",
                    Message = "PC: WASD + Space/Ctrl • Mobile: Analog + Tombol Naik/Turun.",
                    Duration = 3,
                })
            else
                destroyFlyConstraints()
                if lockCharacterStats then
                    applyCharacterStats()
                end
                BimSakSinUI:Notify({
                    Title = "Fly Mode Dimatikan",
                    Message = "Fisika gravitasi karakter dikembalikan normal.",
                    Duration = 2.5,
                })
            end
        end
    })

    local flySpeedSlider = TabPlayer:AddSlider({
        Name = "Kecepatan Terbang (Fly Speed)",
        Min = 16,
        Max = 250,
        Default = ConfigData.FlySpeed,
        Suffix = " st/s",
        Callback = function(val)
            flySpeed = val
            ConfigData.FlySpeed = val
            ConfigManager:ScheduleSave()
        end
    })

    TabPlayer:AddKeybind({
        Name = "Shortcut Toggle Fly",
        Default = resolveKeyCodeFromName(ConfigData.FlyKey),
        OnKeyChanged = function(newKey)
            ConfigData.FlyKey = newKey and newKey.Name or ""
            ConfigManager:ScheduleSave()
        end,
        Callback = function()
            flyToggle:SetState(not flyToggle:GetState())
        end
    })

    TabPlayer:AddSection("Navigasi Fisika, Noclip & Lompat Udara")

    local noclipToggle = TabPlayer:AddToggle({
        Name = "Noclip Aman (Tembus Objek Lokal)",
        Default = false,
        Callback = function(state)
            noclipEnabled = state
            if state and LocalPlayer.Character and #cachedCharParts == 0 then
                rebuildCharacterPartsCache(LocalPlayer.Character)
            elseif not state then
                restoreCharacterCollision()
            end
            BimSakSinUI:Notify({
                Title = "Mode Noclip",
                Message = state and "Noclip aktif (tabrakan karakter dinonaktifkan sementara)." or "Noclip dimatikan & tabrakan dipulihkan.",
                Duration = 2.5,
            })
        end
    })

    TabPlayer:AddKeybind({
        Name = "Shortcut Toggle Noclip",
        Default = resolveKeyCodeFromName(ConfigData.NoclipKey),
        OnKeyChanged = function(newKey)
            ConfigData.NoclipKey = newKey and newKey.Name or ""
            ConfigManager:ScheduleSave()
        end,
        Callback = function()
            noclipToggle:SetState(not noclipToggle:GetState())
        end
    })

    local infJumpToggle = TabPlayer:AddToggle({
        Name = "Infinite Jump Aman (Lompat Udara)",
        Default = false,
        Callback = function(state)
            infiniteJumpEnabled = state
            BimSakSinUI:Notify({
                Title = "Infinite Jump",
                Message = state and "Lompat udara aktif dengan proteksi jeda aman." or "Infinite Jump dimatikan.",
                Duration = 2.5,
            })
        end
    })

    TabPlayer:AddKeybind({
        Name = "Shortcut Toggle Infinite Jump",
        Default = resolveKeyCodeFromName(ConfigData.InfJumpKey),
        OnKeyChanged = function(newKey)
            ConfigData.InfJumpKey = newKey and newKey.Name or ""
            ConfigManager:ScheduleSave()
        end,
        Callback = function()
            infJumpToggle:SetState(not infJumpToggle:GetState())
        end
    })

    TabPlayer:AddSection("Teleport Koordinat (X, Y, Z)")

    local coordControl = TabPlayer:AddCoordinateInput({
        Name = "Tujuan Teleport Koordinat",
        OnTeleport = function(targetPos)
            teleportToVector3(targetPos, nil)
        end
    })

    TabPlayer:AddKeybind({
        Name = "Shortcut Teleport ke Koordinat",
        Default = resolveKeyCodeFromName(ConfigData.TpCoordKey),
        OnKeyChanged = function(newKey)
            ConfigData.TpCoordKey = newKey and newKey.Name or ""
            ConfigManager:ScheduleSave()
        end,
        Callback = function()
            coordControl:TriggerTeleport()
        end
    })

    TabPlayer:AddSection("Lokasi Teleport Favorit (Tersimpan per Map)")

    local waypointManagerCtrl = TabPlayer:AddWaypointManager({
        GetCoordinates = function()
            return coordControl:GetCoordinates()
        end,
        OnLoadToInput = function(vec3, wpName)
            coordControl:SetCoordinates(vec3)
            BimSakSinUI:Notify({
                Title = "Koordinat Dimuat",
                Message = string.format("\"%s\" dimuat ke kolom X/Y/Z.", wpName),
                Duration = 2.5,
            })
        end,
        OnTeleport = function(vec3, wpName)
            teleportToVector3(vec3, wpName)
        end,
        OnWaypointsChanged = function(updatedList)
            ConfigManager:ScheduleSave(updatedList)
        end,
    })

    if #SavedWaypointsData > 0 then
        waypointManagerCtrl:SetWaypoints(SavedWaypointsData)
    end

    TabPlayer:AddSection("Kontrol Gerakan Lokal")

    local walkSlider = TabPlayer:AddSlider({
        Name = "Kecepatan Jalan (WalkSpeed)",
        Min = 16,
        Max = 120,
        Default = ConfigData.WalkSpeed,
        Suffix = " ws",
        Callback = function(val)
            desiredWalkSpeed = val
            ConfigData.WalkSpeed = val
            applyCharacterStats()
            ConfigManager:ScheduleSave()
        end
    })

    local jumpSlider = TabPlayer:AddSlider({
        Name = "Kekuatan Lompat (JumpPower)",
        Min = 50,
        Max = 200,
        Default = ConfigData.JumpPower,
        Suffix = " jp",
        Callback = function(val)
            desiredJumpPower = val
            ConfigData.JumpPower = val
            applyCharacterStats()
            ConfigManager:ScheduleSave()
        end
    })

    local lockStatsToggle = TabPlayer:AddToggle({
        Name = "Kunci Nilai Gerakan Saat Respawn",
        Default = ConfigData.LockStats,
        Callback = function(state)
            lockCharacterStats = state
            ConfigData.LockStats = state
            if state then
                applyCharacterStats()
                if LocalPlayer.Character then
                    bindCharacterStatLocks(LocalPlayer.Character)
                end
            end
            ConfigManager:ScheduleSave()
            BimSakSinUI:Notify({
                Title = "Pengunci Statistik",
                Message = state and "Nilai WalkSpeed & JumpPower dikunci otomatis." or "Pengunci dimatikan.",
                Duration = 2.5,
            })
        end
    })

    TabPlayer:AddSection("Kontrol Kamera")

    local fovSlider = TabPlayer:AddSlider({
        Name = "Field of View (FOV Kamera)",
        Min = 50,
        Max = 120,
        Default = ConfigData.FOV,
        Suffix = "°",
        Callback = function(val)
            ConfigData.FOV = val
            local cam = workspace.CurrentCamera
            if cam then
                cam.FieldOfView = val
            end
            ConfigManager:ScheduleSave()
        end
    })

    if workspace.CurrentCamera and ConfigData.FOV ~= 70 then
        workspace.CurrentCamera.FieldOfView = ConfigData.FOV
    end

    TabPlayer:AddButton({
        Name = "Reset Karakter, Fly, Noclip & Kamera ke Default",
        Callback = function()
            infJumpToggle:SetState(false)
            flyToggle:SetState(false)
            flySpeedSlider:SetValue(60)
            noclipToggle:SetState(false)
            walkSlider:SetValue(16)
            jumpSlider:SetValue(50)
            fovSlider:SetValue(70)
            stopSpectate(true)
            BimSakSinUI:Notify({
                Title = "Reset Berhasil",
                Message = "Infinite Jump, Fly, Noclip, kecepatan, lompatan, FOV, dan kamera kembali standar.",
                Duration = 3,
            })
        end
    })
    
    return waypointManagerCtrl
end

local waypointManagerCtrl = initTabPlayer()

-- ---------------- TAB 4: VISUAL, TRACER, GENERATOR & AUTO FARM (Modular) ----------------
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime  = Lighting.ClockTime,
    FogEnd     = Lighting.FogEnd,
    Ambient    = Lighting.Ambient,
}

local VisualESP = {
    HighlightEnabled = false,
    NameTagEnabled = false,
    TracerEnabled = false,
    TracerOrigin = ConfigData.TracerOrigin,
    TracerThickness = ConfigData.TracerThickness,
    AutoTeamColor = ConfigData.AutoTeamColor,
    FallbackColorOption = ConfigData.FallbackHighlightColor,
    PlayerMarkers = {},
    MaxHighlights = 30,
}

local HighlightColors = {
    ["Merah Terang"] = Color3.fromRGB(255, 65, 65),
    ["Hijau Neon"]   = Color3.fromRGB(34, 197, 94),
    ["Kuning Emas"]  = Color3.fromRGB(250, 204, 21),
    ["Putih Bersih"] = Color3.fromRGB(248, 250, 252),
}

local function getFallbackHighlightColor()
    if VisualESP.FallbackColorOption == "Ikuti Warna Tema" then
        return Palette.Accent
    end
    return HighlightColors[VisualESP.FallbackColorOption] or Palette.Accent
end

local function getTeamCount()
    if not Teams then
        return 0
    end
    local ok, list = pcall(function()
        return Teams:GetTeams()
    end)
    return (ok and type(list) == "table") and #list or 0
end

local function getMarkerColorForPlayer(plr)
    if VisualESP.AutoTeamColor and getTeamCount() > 0 and plr and not plr.Neutral then
        if plr.Team and plr.Team.TeamColor then
            return plr.Team.TeamColor.Color
        elseif plr.TeamColor then
            return plr.TeamColor.Color
        end
    end
    return getFallbackHighlightColor()
end

local function countActiveHighlights()
    local total = 0
    for _, entry in pairs(VisualESP.PlayerMarkers) do
        if entry.Highlight and entry.Highlight.Parent then
            total = total + 1
        end
    end
    return total
end

local function ensurePlayerTracerLine(plr, entry)
    if entry.TracerLine and entry.TracerLine.Parent then
        return entry.TracerLine
    end
    local line = createInstance("Frame", {
        Name = "Tracer_" .. plr.Name,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = getMarkerColorForPlayer(plr),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, VisualESP.TracerThickness),
        Visible = false,
        ZIndex = 1,
        Parent = TracerOverlay,
    })
    entry.TracerLine = line
    return line
end

local function updateSinglePlayerMarkerColor(plr)
    local entry = VisualESP.PlayerMarkers[plr]
    if not entry then
        return
    end
    local resolvedColor = getMarkerColorForPlayer(plr)
    if entry.Highlight and entry.Highlight.Parent then
        entry.Highlight.FillColor = resolvedColor
        entry.Highlight.OutlineColor = resolvedColor
    end
    if entry.NameLabel and entry.NameLabel.Parent then
        entry.NameLabel.TextColor3 = resolvedColor
        if VisualESP.AutoTeamColor and not plr.Neutral and plr.Team then
            entry.NameLabel.Text = string.format("[%s] %s", plr.Team.Name, plr.DisplayName)
        else
            entry.NameLabel.Text = plr.DisplayName
        end
    end
    if entry.TracerLine and entry.TracerLine.Parent then
        entry.TracerLine.BackgroundColor3 = resolvedColor
    end
end

local function clearPlayerMarker(plr)
    local entry = VisualESP.PlayerMarkers[plr]
    if not entry then
        return
    end
    if entry.Highlight then
        entry.Highlight:Destroy()
        entry.Highlight = nil
    end
    if entry.Billboard then
        entry.Billboard:Destroy()
        entry.Billboard = nil
        entry.NameLabel = nil
        entry.DistanceLabel = nil
    end
    if entry.TracerLine then
        entry.TracerLine:Destroy()
        entry.TracerLine = nil
    end
end

local function fullRemovePlayerTracking(plr)
    local entry = VisualESP.PlayerMarkers[plr]
    if entry then
        clearPlayerMarker(plr)
        if entry.CharConn and entry.CharConn.Connected then
            entry.CharConn:Disconnect()
        end
        if entry.TeamConn and entry.TeamConn.Connected then
            entry.TeamConn:Disconnect()
        end
        if entry.TeamColorConn and entry.TeamColorConn.Connected then
            entry.TeamColorConn:Disconnect()
        end
        VisualESP.PlayerMarkers[plr] = nil
    end
end

local function applyMarkerToCharacter(plr, char)
    if plr == LocalPlayer or not char then
        return
    end

    local entry = VisualESP.PlayerMarkers[plr]
    if not entry then
        entry = {}
        VisualESP.PlayerMarkers[plr] = entry
    end

    if entry.Highlight then
        entry.Highlight:Destroy()
        entry.Highlight = nil
    end
    if entry.Billboard then
        entry.Billboard:Destroy()
        entry.Billboard = nil
        entry.NameLabel = nil
        entry.DistanceLabel = nil
    end

    local activeColor = getMarkerColorForPlayer(plr)

    if VisualESP.HighlightEnabled and countActiveHighlights() < VisualESP.MaxHighlights then
        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSinLocalHighlight"
        hl.Adornee = char
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = activeColor
        hl.FillTransparency = 0.65
        hl.OutlineColor = activeColor
        hl.OutlineTransparency = 0.1
        hl.Parent = char
        entry.Highlight = hl
    end

    if VisualESP.NameTagEnabled then
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 3)
        if head and VisualESP.NameTagEnabled then
            local bb = Instance.new("BillboardGui")
            bb.Name = "BimSakSinLocalNameTag"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 190, 0, 38)
            bb.StudsOffset = Vector3.new(0, 2.4, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = 2500
            bb.Parent = head

            local displayTitle = plr.DisplayName
            if VisualESP.AutoTeamColor and getTeamCount() > 0 and not plr.Neutral and plr.Team then
                displayTitle = string.format("[%s] %s", plr.Team.Name, plr.DisplayName)
            end

            local nameLbl = createInstance("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = displayTitle,
                TextColor3 = activeColor,
                TextStrokeTransparency = 0.35,
                TextSize = 13,
                Parent = bb,
            })

            local distLbl = createInstance("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(0, 0, 0, 18),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = "0 stud",
                TextColor3 = Color3.fromRGB(235, 240, 245),
                TextStrokeTransparency = 0.4,
                TextSize = 11,
                Parent = bb,
            })

            entry.Billboard = bb
            entry.NameLabel = nameLbl
            entry.DistanceLabel = distLbl
        end
    end

    if VisualESP.TracerEnabled then
        local line = ensurePlayerTracerLine(plr, entry)
        line.BackgroundColor3 = activeColor
    elseif entry.TracerLine then
        entry.TracerLine.Visible = false
    end
end

local function refreshAllPlayerMarkers()
    local otherPlayers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(otherPlayers, plr)
        end
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myHRP then
        local myPos = myHRP.Position
        table.sort(otherPlayers, function(a, b)
            local aHRP = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
            local bHRP = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
            local distA = aHRP and (myPos - aHRP.Position).Magnitude or math.huge
            local distB = bHRP and (myPos - bHRP.Position).Magnitude or math.huge
            return distA < distB
        end)
    end

    for _, plr in ipairs(otherPlayers) do
        local entry = VisualESP.PlayerMarkers[plr]
        if not entry then
            entry = {}
            VisualESP.PlayerMarkers[plr] = entry

            entry.CharConn = trackConnection(plr.CharacterAdded:Connect(function(newChar)
                task.wait(0.15)
                if VisualESP.HighlightEnabled or VisualESP.NameTagEnabled or VisualESP.TracerEnabled then
                    applyMarkerToCharacter(plr, newChar)
                end
            end))

            entry.TeamConn = trackConnection(plr:GetPropertyChangedSignal("Team"):Connect(function()
                updateSinglePlayerMarkerColor(plr)
                rebuildPlayerList()
            end))

            entry.TeamColorConn = trackConnection(plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
                updateSinglePlayerMarkerColor(plr)
            end))
        end

        if (VisualESP.HighlightEnabled or VisualESP.NameTagEnabled or VisualESP.TracerEnabled) and plr.Character then
            applyMarkerToCharacter(plr, plr.Character)
        else
            clearPlayerMarker(plr)
        end
    end
end

local function updateAllMarkerColors()
    for plr, _ in pairs(VisualESP.PlayerMarkers) do
        updateSinglePlayerMarkerColor(plr)
    end
end

table.insert(ThemeChangeListeners, function()
    if VisualESP.FallbackColorOption == "Ikuti Warna Tema" then
        updateAllMarkerColors()
    end
end)

-- Generator & Auto Farm Engine
local GeneratorESP = {
    Enabled = false,
    HighlightEnabled = ConfigData.GenHighlight,
    HideCompleted = ConfigData.GenHideCompleted,
    OnlyUntouched = ConfigData.GenOnlyUntouched,
    MaxDistance = ConfigData.GenMaxDistance,
    TpTargetMode = ConfigData.GenTpTargetMode,
    AutoPerfect = ConfigData.AutoPerfectGen,
    AutoInteract = ConfigData.AutoInteractGen,
    SkillMode = ConfigData.GenSkillMode,
    TimingOffset = ConfigData.GenTimingOffset,

    AutoFarm = false,
    FarmTargetMode = ConfigData.AutoFarmTargetMode,
    FarmDelay = ConfigData.AutoFarmDelay,
    FarmStuckTimeout = ConfigData.AutoFarmStuckTimeout,
    CurrentFarmTarget = nil,
    CurrentFarmLastPct = -1,
    CurrentFarmProgressTick = 0,
    NextFarmAllowedTick = 0,
    IgnoredFarmGens = {},
    AllCompletedNotified = false,
    FarmCompletedCount = 0,

    PerfectHitCount = 0,
    LastSkillTriggerTick = 0,
    LastInteractTick = 0,
    LastNotifiedPerfectTick = 0,
    Tracked = {},
    SummaryCard = nil,
    AutoStatusCard = nil,
}

local GEN_KEYWORDS = { "generator", "genset", "computer", "terminal", "powerbox", "fusebox", "reactor" }
local GEN_EXACT_SHORT_NAMES = { gen = true, pc = true, machine = true, mesin = true }
local GEN_IGNORE_KEYWORDS = { "terrain", "player", "character", "regenerate", "generic", "projectile", "particle", "sound" }
local STATUS_COLORS = {
    Working   = Color3.fromRGB(250, 204, 21),
    Untouched = Color3.fromRGB(248, 113, 113),
    Partial   = Color3.fromRGB(56, 189, 248),
    Completed = Color3.fromRGB(52, 211, 153),
}

local function isGeneratorCandidate(inst)
    if not inst or (not inst:IsA("Model") and not inst:IsA("BasePart")) then return false end
    if inst:IsDescendantOf(Players) then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and inst:IsDescendantOf(plr.Character) then return false end
    end
    local lowerName = string.lower(inst.Name)
    for _, badWord in ipairs(GEN_IGNORE_KEYWORDS) do
        if string.find(lowerName, badWord, 1, true) then return false end
    end
    local matchedName = false
    if GEN_EXACT_SHORT_NAMES[lowerName] or lowerName:match("^gen[%s_%-%d]*$") or lowerName:match("^pc[%s_%-%d]*$") then
        matchedName = true
    else
        for _, kw in ipairs(GEN_KEYWORDS) do
            if string.find(lowerName, kw, 1, true) then matchedName = true; break end
        end
    end
    if not matchedName then return false end
    local parent = inst.Parent
    while parent and parent ~= workspace do
        local pLower = string.lower(parent.Name)
        if GEN_EXACT_SHORT_NAMES[pLower] or pLower:match("^gen[%s_%-%d]*$") then return false end
        for _, kw in ipairs(GEN_KEYWORDS) do
            if string.find(pLower, kw, 1, true) then return false end
        end
        parent = parent.Parent
    end
    return true
end

local function resolveGeneratorRootPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart end
        for _, nameHint in ipairs({ "Main", "Core", "Screen", "Monitor", "Body", "Hitbox", "Base", "Root" }) do
            local found = inst:FindFirstChild(nameHint, true)
            if found and found:IsA("BasePart") then return found end
        end
        local largestPart = nil
        local largestVol = -1
        for _, desc in ipairs(inst:GetDescendants()) do
            if desc:IsA("BasePart") then
                local s = desc.Size
                local vol = s.X * s.Y * s.Z
                if vol > largestVol then largestVol = vol; largestPart = desc end
            end
        end
        return largestPart
    end
    return nil
end

local function normalizePercentNumber(rawNum)
    if type(rawNum) ~= "number" or rawNum ~= rawNum then return nil end
    if rawNum < 0 then return 0 end
    if rawNum > 0 and rawNum <= 1 then return math.clamp(math.floor(rawNum * 100 + 0.5), 0, 100) end
    return math.clamp(math.floor(rawNum + 0.5), 0, 100)
end

local function extractGeneratorTelemetry(genInst, rootPart, entry)
    local percent = nil
    local isCompleted = false
    local explicitWorkers = {}
    local targets = { genInst }
    if rootPart and rootPart ~= genInst then table.insert(targets, rootPart) end

    for _, obj in ipairs(targets) do
        local okAttr, attrs = pcall(function() return obj:GetAttributes() end)
        if okAttr and type(attrs) == "table" then
            for k, v in pairs(attrs) do
                local kl = string.lower(tostring(k))
                if (kl == "done" or kl == "completed" or kl == "fixed" or kl == "isfixed" or kl == "repaired" or kl == "hacked" or kl == "activated") and v == true then
                    isCompleted = true; percent = 100
                elseif type(v) == "number" and (string.find(kl, "prog", 1, true) or string.find(kl, "perc", 1, true) or string.find(kl, "repair", 1, true) or string.find(kl, "charge", 1, true) or string.find(kl, "work", 1, true) or string.find(kl, "hack", 1, true) or kl == "value") then
                    local maxAttr = attrs.MaxProgress or attrs.Max or attrs.MaxValue
                    if type(maxAttr) == "number" and maxAttr > 0 then
                        percent = math.clamp(math.floor((v / maxAttr) * 100 + 0.5), 0, 100)
                    else
                        percent = normalizePercentNumber(v)
                    end
                end
            end
        end
    end

    if percent == nil then percent = 0 end
    if percent >= 100 then isCompleted = true; percent = 100 end

    local now = os.clock()
    if entry.LastPct ~= nil and percent > entry.LastPct and not isCompleted then
        entry.LastActiveTick = now
    end
    entry.LastPct = percent

    local nearbyWorkers = {}
    local statusCategory = "Untouched"
    local statusText = "Belum Dikerjakan (0%)"
    local statusColor = STATUS_COLORS.Untouched

    if isCompleted then
        statusCategory = "Completed"; statusText = "Selesai (100%)"; statusColor = STATUS_COLORS.Completed
    elseif #nearbyWorkers > 0 then
        statusCategory = "Working"; statusColor = STATUS_COLORS.Working
        statusText = string.format("Dikerjakan • %d%%", percent)
    elseif percent > 0 then
        statusCategory = "Partial"; statusText = string.format("Sebagian (%d%%)", percent); statusColor = STATUS_COLORS.Partial
    else
        statusCategory = "Untouched"; statusText = "Belum Dikerjakan (0%)"; statusColor = STATUS_COLORS.Untouched
    end

    return { Percent = percent, Category = statusCategory, StatusText = statusText, Color = statusColor }
end

local function placePlayerBesideGenerator(myHRP, genRootPart, standDistance)
    local myPos = myHRP.Position
    local genPos = genRootPart.Position
    local toPlayer = myPos - genPos
    local flatDir = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    if flatDir.Magnitude < 0.1 then flatDir = -genRootPart.CFrame.LookVector else flatDir = flatDir.Unit end
    local distOffset = standDistance or 4.5
    local safeDest = genPos + (flatDir * distOffset) + Vector3.new(0, 2.2, 0)
    myHRP.AssemblyLinearVelocity = Vector3.zero
    myHRP.CFrame = CFrame.lookAt(safeDest, Vector3.new(genPos.X, safeDest.Y, genPos.Z))
end

local function teleportToNearestGenerator(targetCategory)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local candidateList = {}
    for genInst, entry in pairs(GeneratorESP.Tracked) do
        if genInst and genInst.Parent and entry.RootPart and entry.RootPart.Parent then
            table.insert(candidateList, { Instance = genInst, RootPart = entry.RootPart, Entry = entry })
        end
    end
    if #candidateList == 0 then
        scanWorkspaceForGenerators(false)
        for genInst, entry in pairs(GeneratorESP.Tracked) do
            if genInst and genInst.Parent and entry.RootPart and entry.RootPart.Parent then
                table.insert(candidateList, { Instance = genInst, RootPart = entry.RootPart, Entry = entry })
            end
        end
    end
    if #candidateList == 0 then return end
    local best = candidateList[1]
    placePlayerBesideGenerator(myHRP, best.RootPart, 4.5)
    BimSakSinUI:Notify({ Title = "TP Generator", Message = "Berpindah ke " .. best.Instance.Name, Duration = 2.5 })
end

local function triggerQuickGeneratorTeleportFromMode()
    teleportToNearestGenerator("SmartPriority")
end

local SkillCheckContainers = {}
local SKILL_UI_KEYWORDS = { "skillcheck", "skill_check", "skill", "minigame", "qte", "hack", "repair", "generator", "calib", "needle" }

local function matchesSkillKeyword(nameStr)
    local lower = string.lower(nameStr or "")
    for _, kw in ipairs(SKILL_UI_KEYWORDS) do
        if string.find(lower, kw, 1, true) then return true end
    end
    return false
end

local function isGuiHierarchyVisible(guiObj)
    if not guiObj or not guiObj.Parent then return false end
    if guiObj:IsA("GuiObject") and not guiObj.Visible then return false end
    local curr = guiObj.Parent
    while curr and curr ~= game do
        if curr:IsA("GuiObject") and not curr.Visible then return false end
        curr = curr.Parent
    end
    return true
end

local function registerSkillCheckContainer(inst)
    if inst and inst:IsA("GuiObject") and not inst:IsDescendantOf(ScreenGui) then
        SkillCheckContainers[inst] = true
    end
end

local function scanPlayerGuiForSkillChecks()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("GuiObject") and matchesSkillKeyword(desc.Name) then
            registerSkillCheckContainer(desc)
        end
    end
end

local function firePerfectSkillCheckInput(container)
    local now = os.clock()
    if now - GeneratorESP.LastSkillTriggerTick < 0.24 then return end
    GeneratorESP.LastSkillTriggerTick = now
    GeneratorESP.PerfectHitCount = GeneratorESP.PerfectHitCount + 1
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.delay(0.03, function() pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end)
        end
    end)
end

local function evaluateSkillCheckContainers(currentPingMs)
    if not GeneratorESP.AutoPerfect and not GeneratorESP.AutoFarm then return end
    for container, _ in pairs(SkillCheckContainers) do
        if not container or not container.Parent then
            SkillCheckContainers[container] = nil
        elseif isGuiHierarchyVisible(container) then
            firePerfectSkillCheckInput(container)
        end
    end
end

local function triggerPromptOnGenerator(genInst)
    if not genInst or not genInst.Parent then return false end
    for _, desc in ipairs(genInst:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled then
            if type(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, desc)
                return true
            end
        end
    end
    return false
end

local function autoInteractNearbyGenerators()
    if not GeneratorESP.AutoInteract and not GeneratorESP.AutoFarm then return end
    local now = os.clock()
    if now - GeneratorESP.LastInteractTick < 0.35 then return end
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for genInst, entry in pairs(GeneratorESP.Tracked) do
        if genInst and genInst.Parent and entry.RootPart then
            if (myHRP.Position - entry.RootPart.Position).Magnitude <= 12.5 then
                if triggerPromptOnGenerator(genInst) then
                    GeneratorESP.LastInteractTick = now
                    return
                end
            end
        end
    end
end

local function clearSingleGeneratorVisual(genInst)
    local entry = GeneratorESP.Tracked[genInst]
    if not entry then return end
    if entry.Billboard then entry.Billboard:Destroy() end
    if entry.Highlight then entry.Highlight:Destroy() end
    GeneratorESP.Tracked[genInst] = nil
end

local function clearAllGeneratorVisuals()
    for genInst, _ in pairs(GeneratorESP.Tracked) do
        clearSingleGeneratorVisual(genInst)
    end
end

local function attachGeneratorVisual(genInst)
    if GeneratorESP.Tracked[genInst] then return end
    local rootPart = resolveGeneratorRootPart(genInst)
    if not rootPart then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "BimSakSinGenESP"
    bb.Adornee = rootPart
    bb.Size = UDim2.new(0, 225, 0, 44)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = GeneratorESP.MaxDistance
    bb.Enabled = GeneratorESP.Enabled
    bb.Parent = rootPart

    local bg = createInstance("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(14, 17, 25), BackgroundTransparency = 0.25, Parent = bb })
    addCorner(bg, 6)
    local bgStroke = addStroke(bg, STATUS_COLORS.Untouched, 1)

    local titleLbl = createInstance("TextLabel", { Size = UDim2.new(1, -10, 0, 18), Position = UDim2.new(0, 5, 0, 3), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "⚡ Generator", TextColor3 = Color3.fromRGB(245, 248, 255), TextSize = 12, Parent = bg })
    local statusLbl = createInstance("TextLabel", { Size = UDim2.new(1, -10, 0, 17), Position = UDim2.new(0, 5, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "Belum Dikerjakan (0%)", TextColor3 = STATUS_COLORS.Untouched, TextSize = 11, Parent = bg })

    local hl = Instance.new("Highlight")
    hl.Name = "BimSakSinGenHighlight"
    hl.Adornee = genInst
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = STATUS_COLORS.Untouched
    hl.FillTransparency = 0.72
    hl.OutlineColor = STATUS_COLORS.Untouched
    hl.Enabled = (GeneratorESP.Enabled and GeneratorESP.HighlightEnabled)
    hl.Parent = rootPart

    GeneratorESP.Tracked[genInst] = { RootPart = rootPart, Billboard = bb, Stroke = bgStroke, TitleLabel = titleLbl, StatusLabel = statusLbl, Highlight = hl, LastPct = nil, LastActiveTick = 0 }
end

local function scanWorkspaceForGenerators(showToast)
    for _, desc in ipairs(workspace:GetDescendants()) do
        if isGeneratorCandidate(desc) then attachGeneratorVisual(desc) end
    end
    local count = 0
    for _ in pairs(GeneratorESP.Tracked) do count = count + 1 end
    if showToast then
        BimSakSinUI:Notify({ Title = "Pemindaian Generator", Message = string.format("Ditemukan %d objek generator.", count), Duration = 3 })
    end
    return count
end

local function selectNextAutoFarmGenerator(myPos, now)
    for genInst, entry in pairs(GeneratorESP.Tracked) do
        if genInst and genInst.Parent and entry.RootPart then
            local info = extractGeneratorTelemetry(genInst, entry.RootPart, entry)
            if info.Category ~= "Completed" and info.Percent < 100 then
                return genInst, entry, info, (myPos - entry.RootPart.Position).Magnitude
            end
        end
    end
    return nil
end

local function stepAutoFarmGenerator()
    if not GeneratorESP.AutoFarm then return end
    local now = os.clock()
    if now < GeneratorESP.NextFarmAllowedTick then return end
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    if next(GeneratorESP.Tracked) == nil then scanWorkspaceForGenerators(false) end

    local activeTarget = GeneratorESP.CurrentFarmTarget
    if activeTarget then
        local activeEntry = GeneratorESP.Tracked[activeTarget]
        if not activeTarget.Parent or not activeEntry then
            GeneratorESP.CurrentFarmTarget = nil
        else
            local info = extractGeneratorTelemetry(activeTarget, activeEntry.RootPart, activeEntry)
            if info.Category == "Completed" or info.Percent >= 100 then
                GeneratorESP.CurrentFarmTarget = nil
                GeneratorESP.FarmCompletedCount = GeneratorESP.FarmCompletedCount + 1
                GeneratorESP.NextFarmAllowedTick = now + GeneratorESP.FarmDelay
                return
            end
        end
    end

    if not GeneratorESP.CurrentFarmTarget then
        local nextGen, nextEntry, nextInfo = selectNextAutoFarmGenerator(myHRP.Position, now)
        if nextGen then
            GeneratorESP.CurrentFarmTarget = nextGen
            placePlayerBesideGenerator(myHRP, nextEntry.RootPart, 4.3)
            triggerPromptOnGenerator(nextGen)
        end
    end
end

-- ============================================================================
-- INISIALISASI TAB VISUAL (Dibungkus fungsi modular agar hemat register)
-- ============================================================================
local function initTabVisual()
    TabVisual:AddSection("Penanda Visual Pemain (Lokal)")

    TabVisual:AddToggle({
        Name = "Highlight Karakter Pemain",
        Default = false,
        Callback = function(state)
            VisualESP.HighlightEnabled = state
            refreshAllPlayerMarkers()
            BimSakSinUI:Notify({ Title = "Highlight Pemain", Message = state and "Aktif" or "Dimatikan", Duration = 2.5 })
        end
    })

    TabVisual:AddToggle({
        Name = "Label Nama & Jarak Pemain",
        Default = false,
        Callback = function(state)
            VisualESP.NameTagEnabled = state
            refreshAllPlayerMarkers()
        end
    })

    TabVisual:AddToggle({
        Name = "Garis Tracer ESP Pemain",
        Default = false,
        Callback = function(state)
            VisualESP.TracerEnabled = state
            refreshAllPlayerMarkers()
        end
    })

    TabVisual:AddDropdown({
        Name = "Titik Asal Garis Tracer",
        Options = { "Bawah Layar", "Tengah Layar (Crosshair)", "Atas Layar", "Posisi Karakter Sendiri" },
        Default = ConfigData.TracerOrigin,
        Callback = function(choice)
            VisualESP.TracerOrigin = choice
            ConfigData.TracerOrigin = choice
            ConfigManager:ScheduleSave()
        end
    })

    TabVisual:AddSlider({
        Name = "Ketebalan Garis Tracer",
        Min = 1,
        Max = 4,
        Default = ConfigData.TracerThickness,
        Suffix = " px",
        Callback = function(val)
            VisualESP.TracerThickness = val
            ConfigData.TracerThickness = val
            ConfigManager:ScheduleSave()
        end
    })

    TabVisual:AddToggle({
        Name = "Sesuaikan Warna Team Otomatis",
        Default = ConfigData.AutoTeamColor,
        Callback = function(state)
            VisualESP.AutoTeamColor = state
            ConfigData.AutoTeamColor = state
            updateAllMarkerColors()
            ConfigManager:ScheduleSave()
        end
    })

    TabVisual:AddDropdown({
        Name = "Warna Cadangan / Non-Team",
        Options = { "Ikuti Warna Tema", "Merah Terang", "Hijau Neon", "Kuning Emas", "Putih Bersih" },
        Default = ConfigData.FallbackHighlightColor,
        Callback = function(choice)
            VisualESP.FallbackColorOption = choice
            ConfigData.FallbackHighlightColor = choice
            updateAllMarkerColors()
            ConfigManager:ScheduleSave()
        end
    })

    TabVisual:AddSection("Auto Farm, ESP Generator & Auto Perfect")

    GeneratorESP.SummaryCard = TabVisual:AddInfoCard("Ringkasan Generator Map", "Nonaktif")
    GeneratorESP.AutoStatusCard = TabVisual:AddInfoCard("Status Auto Generator", "Nonaktif")

    local autoPerfectToggle = nil

    TabVisual:AddToggle({
        Name = "Auto Farm Generator (TP 0% + Perfect Beruntun)",
        Default = false,
        Callback = function(state)
            GeneratorESP.AutoFarm = state
            GeneratorESP.CurrentFarmTarget = nil
            if state then
                scanWorkspaceForGenerators(false)
                scanPlayerGuiForSkillChecks()
                if autoPerfectToggle then autoPerfectToggle:SetState(true) end
                BimSakSinUI:Notify({ Title = "Auto Farm Aktif", Message = "Otomatis berpindah antar generator.", Duration = 3 })
            end
        end
    })

    TabVisual:AddToggle({
        Name = "Aktifkan ESP Generator (Jarak & Status)",
        Default = false,
        Callback = function(state)
            GeneratorESP.Enabled = state
            if state then scanWorkspaceForGenerators(true) end
        end
    })

    autoPerfectToggle = TabVisual:AddToggle({
        Name = "Auto Perfect Skill Check (Otomatis)",
        Default = ConfigData.AutoPerfectGen,
        Callback = function(state)
            GeneratorESP.AutoPerfect = state
            ConfigData.AutoPerfectGen = state
            ConfigManager:ScheduleSave()
            if state then scanPlayerGuiForSkillChecks() end
        end
    })

    TabVisual:AddToggle({
        Name = "Auto Interaksi Prompt Generator",
        Default = ConfigData.AutoInteractGen,
        Callback = function(state)
            GeneratorESP.AutoInteract = state
            ConfigData.AutoInteractGen = state
            ConfigManager:ScheduleSave()
        end
    })

    TabVisual:AddButton({ Name = "Pindai Ulang Generator di Map", Callback = function() scanWorkspaceForGenerators(true) end })
end

initTabVisual()

-- ---------------- TAB 5: PENGATURAN, ANTI-AFK & REJOIN (Modular) ----------------
local function initTabSettings()
    TabSettings:AddSection("Manajemen Konfigurasi (JSON Permanen)")

    local initialConfigStatus = ConfigManager.Supported
        and (ConfigManager.LoadedFromDisk and "Dimuat dari File JSON" or "Siap (File Baru)")
        or "Tidak Didukung Executor"

    local configStatusCard = TabSettings:AddInfoCard("Status Konfigurasi", initialConfigStatus)

    ConfigManager.OnStatusChanged = function(statusText)
        if configStatusCard then configStatusCard:SetValue(statusText) end
    end

    TabSettings:AddToggle({
        Name = "Simpan Konfigurasi Otomatis (Auto-Save)",
        Default = ConfigData.AutoSave,
        Callback = function(state)
            ConfigData.AutoSave = state
            if state then ConfigManager:SaveNow(waypointManagerCtrl:GetWaypoints()) end
        end
    })

    TabSettings:AddButton({
        Name = "Simpan Konfigurasi Sekarang",
        Callback = function()
            ConfigManager:SaveNow(waypointManagerCtrl:GetWaypoints())
            BimSakSinUI:Notify({ Title = "Tersimpan", Message = "Konfigurasi berhasil ditulis ke file.", Duration = 2.5 })
        end
    })

    TabSettings:AddSection("Perlindungan Sesi (Anti-AFK)")

    local antiAfkEnabled = ConfigData.AntiAFK
    local antiAfkStatusCard = TabSettings:AddInfoCard("Status Anti-AFK", antiAfkEnabled and "Aktif" or "Nonaktif")

    TabSettings:AddToggle({
        Name = "Anti-AFK Aman (Cegah Kick 20 Menit)",
        Default = antiAfkEnabled,
        Callback = function(state)
            antiAfkEnabled = state
            ConfigData.AntiAFK = state
            ConfigManager:ScheduleSave()
            antiAfkStatusCard:SetValue(state and "Aktif" or "Nonaktif")
        end
    })

    trackConnection(LocalPlayer.Idled:Connect(function()
        if not antiAfkEnabled then return end
        pcall(function()
            local virtualUser = game:GetService("VirtualUser")
            if virtualUser then
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.new())
            end
        end)
    end))

    TabSettings:AddSection("Tampilan & Kontrol Panel")

    TabSettings:AddDropdown({
        Name = "Warna Aksen Tema",
        Options = { "Cyan Electric", "Emerald Green", "Royal Purple", "Sunset Orange" },
        Default = ConfigData.Theme,
        Callback = function(themeName)
            ConfigData.Theme = themeName
            applyThemeAccent(themeName)
            ConfigManager:ScheduleSave()
        end
    })

    TabSettings:AddButton({
        Name = "Tutup & Hapus Panel UI",
        Callback = function()
            if ConfigData.AutoSave then
                ConfigManager:SaveNow(waypointManagerCtrl:GetWaypoints())
            end
            Window:Destroy()
        end
    })
end

initTabSettings()

-- Sinkronisasi Player & Render Loop Utama
trackConnection(Players.PlayerAdded:Connect(function()
    rebuildPlayerList()
    refreshAllPlayerMarkers()
end))

trackConnection(Players.PlayerRemoving:Connect(function(leavingPlayer)
    ThumbnailCache[leavingPlayer.UserId] = nil
    fullRemovePlayerTracking(leavingPlayer)
    if spectatedPlayer == leavingPlayer then stopSpectate(true) end
    task.defer(rebuildPlayerList)
end))

rebuildPlayerList()
refreshAllPlayerMarkers()

trackConnection(UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled or flyEnabled then return end
    local now = os.clock()
    if now - lastAirJumpTime < AIR_JUMP_COOLDOWN then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    lastAirJumpTime = now
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end))

trackConnection(RunService.Stepped:Connect(function()
    if not noclipEnabled then return end
    for i = 1, #cachedCharParts do
        local part = cachedCharParts[i]
        if part and part.Parent then
            if originalCollideStates[part] == nil then originalCollideStates[part] = part.CanCollide end
            if part.CanCollide then part.CanCollide = false end
        end
    end
end))

local cachedDataPingItem = nil
pcall(function()
    if Stats and Stats.Network and Stats.Network.ServerStatsItem then
        cachedDataPingItem = Stats.Network.ServerStatsItem["Data Ping"]
    end
end)

local lastKnownPingMs = 0
local frameCounter = 0
local elapsed = 0
local genRescanTimer = 0
local autoFarmTickTimer = 0

trackConnection(RunService.RenderStepped:Connect(function(dt)
    frameCounter = frameCounter + 1
    elapsed = elapsed + dt
    genRescanTimer = genRescanTimer + dt
    autoFarmTickTimer = autoFarmTickTimer + dt

    if GeneratorESP.AutoPerfect or GeneratorESP.AutoFarm then evaluateSkillCheckContainers(lastKnownPingMs) end
    if GeneratorESP.AutoInteract or GeneratorESP.AutoFarm then autoInteractNearbyGenerators() end
    if GeneratorESP.AutoFarm and autoFarmTickTimer >= 0.25 then
        autoFarmTickTimer = 0
        stepAutoFarmGenerator()
    end

    if flyEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if hrp and hum and cam then
            if not flyLinearVel or not flyLinearVel.Parent then setupFlyConstraints(char) end
            hum.PlatformStand = true
            local moveDir = hum.MoveDirection
            local flatLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
            local wishDir = (flatLook * moveDir:Dot(flatLook)) + Vector3.new(0, (mobileFlyUpHeld and 1 or (mobileFlyDownHeld and -1 or 0)), 0)
            currentFlyVelocity = currentFlyVelocity:Lerp(wishDir * flySpeed, 1 - math.exp(-12 * dt))
            if flyLinearVel then flyLinearVel.VectorVelocity = currentFlyVelocity end
        end
    end

    if elapsed >= 0.4 then
        local fps = math.floor((frameCounter / elapsed) + 0.5)
        fpsCard:SetValue(tostring(fps) .. " FPS")
        if wmFpsLabel then wmFpsLabel.Text = tostring(fps) .. " FPS" end
        if cachedDataPingItem then
            pcall(function() lastKnownPingMs = math.floor(cachedDataPingItem:GetValue()) end)
            pingCard:SetValue(tostring(lastKnownPingMs) .. " ms")
        end
        playerCountCard:SetValue(tostring(#Players:GetPlayers()) .. " Pemain")
        frameCounter = 0
        elapsed = 0
    end
end))

BimSakSinUI:Notify({
    Title = "BimSakSin Hub v4.6 Aktif",
    Message = "Berhasil dimuat tanpa error register!",
    Duration = 4,
})
