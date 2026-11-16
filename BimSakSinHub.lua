--[[
    BimSakSin Hub v4.1 (Persistent JSON Config Edition)
    Kompatibel dengan: Mobile (Touch) & PC (Mouse/Keyboard)
    Fitur Auto-Save & Load Config:
    - Waypoint Favorit (Disimpan permanen dengan koordinat X, Y, Z)
    - Tema Warna Aksen, Posisi & Visibilitas Watermark HUD (FPS, Ping & Waktu)
    - Status & Preferensi Anti-AFK, Auto-Rejoin, & Mode Server Hop
    - Keybind Pintasan Keyboard (Toggle UI, Fly, Noclip, InfJump, Teleport)
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ============================================================================
-- SISTEM CONFIGURASI PERSISTEN (JSON FILE MANAGEMENT)
-- ============================================================================
local CONFIG_FOLDER = "BimSakSinHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local DefaultConfig = {
    Theme = "Cyan Electric",
    WatermarkCorner = "Kiri Atas",
    WatermarkVisible = true,
    AntiAfk = true,
    AutoRejoin = false,
    AutoRejoinMode = "Server Sama (Fallback Publik)",
    ServerHopMode = "Server Acak (Random)",
    Keybinds = {
        ToggleUI = Enum.KeyCode.RightShift.Value,
        Fly = Enum.KeyCode.F.Value,
        Noclip = Enum.KeyCode.N.Value,
        InfJump = Enum.KeyCode.J.Value,
        TeleportCoord = Enum.KeyCode.T.Value,
    },
    Waypoints = {},
}

local CurrentConfig = table.clone(DefaultConfig)

local function saveConfig()
    pcall(function()
        if writefile and makefolder and isfolder then
            if not isfolder(CONFIG_FOLDER) then
                makefolder(CONFIG_FOLDER)
            end
            local encoded = HttpService:JSONEncode(CurrentConfig)
            writefile(CONFIG_FILE, encoded)
        end
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    if CurrentConfig[k] ~= nil then
                        if type(CurrentConfig[k]) == "table" and type(v) == "table" then
                            for subK, subV in pairs(v) do
                                CurrentConfig[k][subK] = subV
                            end
                        else
                            CurrentConfig[k] = v
                        end
                    end
                end
            end
        end
    end)
end

loadConfig()

-- Menentukan parent GUI yang aman (CoreGui dengan fallback ke PlayerGui)
local function getSafeGuiParent()
    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then
        local testSuccess = pcall(function()
            local probe = Instance.new("Folder")
            probe.Parent = coreGui
            probe:Destroy()
        end)
        if testSuccess then
            return coreGui
        end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = getSafeGuiParent()
local UI_NAME = "BimSakSinHub_UI"

local existingGui = GuiParent:FindFirstChild(UI_NAME)
if existingGui then
    existingGui:Destroy()
end

-- ============================================================================
-- KONFIGURASI TEMA & WARNA
-- ============================================================================
local Themes = {
    ["Cyan Electric"] = Color3.fromRGB(0, 185, 255),
    ["Emerald Green"] = Color3.fromRGB(16, 185, 129),
    ["Royal Purple"]  = Color3.fromRGB(147, 51, 234),
    ["Sunset Orange"] = Color3.fromRGB(249, 115, 22),
}

local Palette = {
    Background    = Color3.fromRGB(17, 19, 26),
    Sidebar       = Color3.fromRGB(22, 25, 34),
    Card          = Color3.fromRGB(28, 32, 44),
    CardHover     = Color3.fromRGB(35, 40, 55),
    Stroke        = Color3.fromRGB(48, 54, 72),
    TextPrimary   = Color3.fromRGB(242, 244, 248),
    TextSecondary = Color3.fromRGB(156, 163, 180),
    SwitchOff     = Color3.fromRGB(55, 62, 82),
    Danger        = Color3.fromRGB(239, 68, 68),
    Warning       = Color3.fromRGB(245, 158, 11),
    Success       = Color3.fromRGB(16, 185, 129),
    Accent        = Themes[CurrentConfig.Theme] or Themes["Cyan Electric"],
}

-- ============================================================================
-- ENGINE UTAMA BIMSAKSIN UI
-- ============================================================================
local BimSakSinUI = {}
local Connections = {}
local AccentRegistry = {}
local CleanupCallbacks = {}
local ThemeChangeListeners = {}
local WindowLocked = false
local ActiveKeybindCapture = nil

local function trackConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local function registerCleanup(fn)
    table.insert(CleanupCallbacks, fn)
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
    CurrentConfig.Theme = themeName
    saveConfig()

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

local NotifyContainer = createInstance("Frame", {
    Name = "NotificationContainer",
    Size = UDim2.new(0, 290, 1, -24),
    Position = UDim2.new(1, -304, 0, 12),
    BackgroundTransparency = 1,
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
        Size = UDim2.new(1, 0, 0, 64),
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
        Size = UDim2.new(1, -22, 0, 20),
        Position = UDim2.new(0, 14, 0, 8),
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
        Position = UDim2.new(0, 14, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Palette.TextSecondary,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTransparency = 1,
        Parent = toast,
    })

    TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05
    }):Play()
    TweenService:Create(titleLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
    TweenService:Create(msgLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

    task.delay(duration, function()
        if not toast or not toast.Parent then
            return
        end
        local outTween = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        })
        TweenService:Create(titleLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
        TweenService:Create(msgLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
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
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
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
-- WATERMARK HUD ELEGAN (PERSISTENT CORNER & VISIBILITY)
-- ============================================================================
local WatermarkPositions = {
    ["Kiri Atas"]   = { Anchor = Vector2.new(0, 0), Pos = UDim2.new(0, 16, 0, 56) },
    ["Kanan Atas"]  = { Anchor = Vector2.new(1, 0), Pos = UDim2.new(1, -16, 0, 56) },
    ["Kiri Bawah"]  = { Anchor = Vector2.new(0, 1), Pos = UDim2.new(0, 16, 1, -16) },
    ["Kanan Bawah"] = { Anchor = Vector2.new(1, 1), Pos = UDim2.new(1, -16, 1, -16) },
}

local initialCornerData = WatermarkPositions[CurrentConfig.WatermarkCorner] or WatermarkPositions["Kiri Atas"]

local WatermarkFrame = createInstance("Frame", {
    Name = "BimSakSinWatermarkHUD",
    AnchorPoint = initialCornerData.Anchor,
    Position = initialCornerData.Pos,
    Size = UDim2.new(0, 0, 0, 30),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = Palette.Background,
    BackgroundTransparency = 0.12,
    Visible = CurrentConfig.WatermarkVisible,
    Active = true,
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
local wmStroke = addStroke(WatermarkFrame, Palette.Stroke, 1.2)
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
    Text = "BimSakSin Hub v4.1",
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
    Text = os.date("%H:%M:%S"),
    TextColor3 = Palette.TextSecondary,
    TextSize = 12,
    Parent = WatermarkFrame,
})

local function setWatermarkCorner(cornerName)
    local preset = WatermarkPositions[cornerName]
    if not preset then
        return
    end
    CurrentConfig.WatermarkCorner = cornerName
    saveConfig()

    WatermarkFrame.AnchorPoint = preset.Anchor
    TweenService:Create(
        WatermarkFrame,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = preset.Pos }
    ):Play()
end

function BimSakSinUI:CreateWindow(config)
    local titleText = config.Title or "BimSakSin Hub v4.1"
    local subtitleText = config.Subtitle or "Professional Edition"
    local uiToggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    local FloatingPill = createInstance("TextButton", {
        Name = "FloatingRestorePill",
        Size = UDim2.new(0, 145, 0, 38),
        Position = UDim2.new(0, 20, 0.5, -19),
        BackgroundColor3 = Palette.Background,
        Font = Enum.Font.GothamBold,
        Text = "  Buka BimSakSin",
        TextColor3 = Palette.TextPrimary,
        TextSize = 12,
        Visible = false,
        AutoButtonColor = false,
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

    local MainFrame = createInstance("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 580, 0, 380),
        Position = UDim2.new(0.5, -290, 0.5, -190),
        BackgroundColor3 = Palette.Background,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    addCorner(MainFrame, 12)
    addStroke(MainFrame, Palette.Stroke, 1.2)

    local TopBar = createInstance("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
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
        Size = UDim2.new(0, 300, 0, 20),
        Position = UDim2.new(0, 34, 0, 7),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = titleText,
        TextColor3 = Palette.TextPrimary,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    createInstance("TextLabel", {
        Size = UDim2.new(0, 300, 0, 16),
        Position = UDim2.new(0, 34, 0, 25),
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

    local function toggleMinimize(state)
        if state == nil then
            state = MainFrame.Visible
        end
        MainFrame.Visible = not state
        FloatingPill.Visible = state
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
            toggleMinimize(MainFrame.Visible)
        end
    end))

    local Sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
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
        Size = UDim2.new(0, 1, 1, -48),
        Position = UDim2.new(0, 150, 0, 48),
        BackgroundColor3 = Palette.Stroke,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    local ContentHolder = createInstance("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -151, 1, -48),
        Position = UDim2.new(0, 151, 0, 48),
        BackgroundTransparency = 1,
        Parent = MainFrame,
    })

    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
    }

    function WindowObj:SetToggleKey(newKeyCode)
        uiToggleKey = newKeyCode
        if newKeyCode then
            CurrentConfig.Keybinds.ToggleUI = newKeyCode.Value
            saveConfig()
        end
    end

    function WindowObj:Destroy()
        ActiveKeybindCapture = nil
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
                if state == newState and fireCallback then
                    return
                end
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
                SetState = function(_, newState)
                    updateVisual(newState, true)
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

            local track = createInstance("TextButton", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.new(0, 12, 0, 36),
                BackgroundColor3 = Palette.SwitchOff,
                Text = "",
                AutoButtonColor = false,
                Parent = card,
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

            trackConnection(track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    setSliderFromInput(input.Position.X)
                end
            end))

            trackConnection(UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setSliderFromInput(input.Position.X)
                end
            end))

            trackConnection(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end))

            return {
                SetValue = function(_, val)
                    currentVal = math.clamp(val, minVal, maxVal)
                    local ratio = (currentVal - minVal) / math.max(1, (maxVal - minVal))
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    valLabel.Text = tostring(currentVal) .. suffix
                    task.spawn(callback, currentVal)
                end
            }
        end

        function TabAPI:AddDropdown(opts)
            local label = opts.Name or "Pilih Opsi"
            local items = opts.Options or {}
            local selected = opts.Default or items[1] or "-"
            local callback = opts.Callback or function() end
            local expanded = false

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
                Size = UDim2.new(0.48, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = label,
                TextColor3 = Palette.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn,
            })

            local selectedLabel = createInstance("TextLabel", {
                Size = UDim2.new(0.52, -14, 1, 0),
                Position = UDim2.new(0.48, 0, 0, 0),
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

            for _, optionText in ipairs(items) do
                local optBtn = createInstance("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Palette.Sidebar,
                    Font = Enum.Font.Gotham,
                    Text = "  " .. optionText,
                    TextColor3 = (optionText == selected) and Palette.TextPrimary or Palette.TextSecondary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    Parent = listFrame,
                })
                addCorner(optBtn, 6)

                trackConnection(optBtn.MouseButton1Click:Connect(function()
                    selected = optionText
                    expanded = false
                    selectedLabel.Text = selected .. "  ▼"
                    TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 42)
                    }):Play()
                    task.spawn(callback, selected)
                end))
            end

            trackConnection(headerBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                selectedLabel.Text = selected .. (expanded and "  ▲" or "  ▼")
                local targetHeight = expanded and (50 + (#items * 32)) or 42
                TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, targetHeight)
                }):Play()
            end))
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
            local configKeyName = opts.ConfigKeyName
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
                end
                keyBtn.Text = currentKey and currentKey.Name or "Belum Diatur"
                TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
            end

            trackConnection(keyBtn.MouseButton1Click:Connect(function()
                if listening then
                    stopListening()
                    return
                end
                listening = true
                ActiveKeybindCapture = keyBtn
                keyBtn.Text = "Tekan Tombol..."
                TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
            end))

            trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                            currentKey = nil
                            stopListening()
                            if configKeyName then
                                CurrentConfig.Keybinds[configKeyName] = nil
                                saveConfig()
                            end
                            task.spawn(onKeyChanged, nil)
                            BimSakSinUI:Notify({
                                Title = "Keybind Dihapus",
                                Message = label .. " tidak lagi terikat tombol keyboard.",
                                Duration = 2.5,
                            })
                        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                            currentKey = input.KeyCode
                            stopListening()
                            if configKeyName then
                                CurrentConfig.Keybinds[configKeyName] = currentKey.Value
                                saveConfig()
                            end
                            task.spawn(onKeyChanged, currentKey)
                            BimSakSinUI:Notify({
                                Title = "Keybind Diperbarui",
                                Message = label .. " diatur ke tombol [" .. currentKey.Name .. "].",
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
                SetKey = function(_, newKey)
                    currentKey = newKey
                    stopListening()
                    if configKeyName then
                        CurrentConfig.Keybinds[configKeyName] = newKey and newKey.Value or nil
                        saveConfig()
                    end
                    task.spawn(onKeyChanged, currentKey)
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

                createInstance("TextLabel", {
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

            local savedWaypoints = {}
            for _, wpData in ipairs(CurrentConfig.Waypoints or {}) do
                if wpData and wpData.Name and wpData.Pos then
                    table.insert(savedWaypoints, {
                        Name = wpData.Name,
                        Position = Vector3.new(wpData.Pos[1], wpData.Pos[2], wpData.Pos[3]),
                    })
                end
            end
            local waypointCounter = #savedWaypoints + 1

            local function persistWaypoints()
                local serialized = {}
                for _, wp in ipairs(savedWaypoints) do
                    table.insert(serialized, {
                        Name = wp.Name,
                        Pos = { wp.Position.X, wp.Position.Y, wp.Position.Z },
                    })
                end
                CurrentConfig.Waypoints = serialized
                saveConfig()
            end

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
                        persistWaypoints()
                        rebuildWaypointList()
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
                persistWaypoints()
                rebuildWaypointList()

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
                persistWaypoints()
                rebuildWaypointList()
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
                AddWaypoint = function(_, wpName, vec3)
                    table.insert(savedWaypoints, {
                        Name = wpName,
                        Position = vec3,
                    })
                    persistWaypoints()
                    rebuildWaypointList()
                end,
            }
        end

        return TabAPI
    end

    return WindowObj
end

-- ============================================================================
-- INISIALISASI PANEL & TAB UTAMA (BIMSAKSIN HUB v4.1)
-- ============================================================================
local Window = BimSakSinUI:CreateWindow({
    Title = "BimSakSin Hub v4.1",
    Subtitle = "Professional Roblox Suite • Persistent JSON",
    ToggleKey = Enum.KeyCode.FromValue(CurrentConfig.Keybinds.ToggleUI) or Enum.KeyCode.RightShift,
})

local TabDashboard  = Window:CreateTab("Dashboard")
local TabPlayerList = Window:CreateTab("Pemain")
local TabPlayer     = Window:CreateTab("Karakter")
local TabVisual     = Window:CreateTab("Visual")
local TabSettings   = Window:CreateTab("Pengaturan")

-- ---------------- TAB 1: DASHBOARD ----------------
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
            if setclipboard then
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
            if setclipboard then
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

-- ---------------- TAB 2: DAFTAR PEMAIN (TP & SPECTATE) ----------------
local spectatedPlayer = nil
local spectateButtons = {}

TabPlayerList:AddSection("Kontrol Kamera & Pencarian")
local spectateStatusCard = TabPlayerList:AddInfoCard("Status Spectate", "Kamera Lokal (Kamu)")

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
    spectateStatusCard:SetValue("Kamera Lokal (Kamu)")
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
    spectateStatusCard:SetValue(targetPlayer.DisplayName)
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

            local avatarImg = createInstance("ImageLabel", {
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(0, 8, 0.5, -17),
                BackgroundColor3 = Palette.Sidebar,
                Image = "",
                Parent = row,
            })
            addCorner(avatarImg, 17)

            task.spawn(function()
                local ok, thumbUrl = pcall(function()
                    return Players:GetUserThumbnailAsync(
                        plr.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size48x48
                    )
                end)
                if ok and thumbUrl and avatarImg and avatarImg.Parent then
                    avatarImg.Image = thumbUrl
                end
            end)

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

-- ---------------- TAB 3: KARAKTER, FLY, NOCLIP, INFINITE JUMP & WAYPOINT ----------------
local desiredWalkSpeed = 16
local desiredJumpPower = 50
local lockCharacterStats = false

local infiniteJumpEnabled = false
local lastAirJumpTime = 0
local AIR_JUMP_COOLDOWN = 0.18

local noclipEnabled = false
local originalCollideStates = setmetatable({}, { __mode = "k" })

local flyEnabled = false
local flySpeed = 60
local currentFlyVelocity = Vector3.zero
local flyAttachment = nil
local flyLinearVel = nil
local flyAlignOrient = nil

local function destroyFlyConstraints()
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

registerCleanup(function()
    infiniteJumpEnabled = false
    flyEnabled = false
    destroyFlyConstraints()
    noclipEnabled = false
    restoreCharacterCollision()
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
                Message = "Gunakan WASD/Analog + Space (Naik) / Ctrl (Turun).",
                Duration = 3,
            })
        else
            destroyFlyConstraints()
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
    Default = 60,
    Suffix = " st/s",
    Callback = function(val)
        flySpeed = val
    end
})

TabPlayer:AddKeybind({
    Name = "Shortcut Toggle Fly",
    Default = Enum.KeyCode.FromValue(CurrentConfig.Keybinds.Fly) or Enum.KeyCode.F,
    ConfigKeyName = "Fly",
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
        if not state then
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
    Default = Enum.KeyCode.FromValue(CurrentConfig.Keybinds.Noclip) or Enum.KeyCode.N,
    ConfigKeyName = "Noclip",
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
    Default = Enum.KeyCode.FromValue(CurrentConfig.Keybinds.InfJump) or Enum.KeyCode.J,
    ConfigKeyName = "InfJump",
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
    Default = Enum.KeyCode.FromValue(CurrentConfig.Keybinds.TeleportCoord) or Enum.KeyCode.T,
    ConfigKeyName = "TeleportCoord",
    Callback = function()
        coordControl:TriggerTeleport()
    end
})

TabPlayer:AddSection("Lokasi Teleport Favorit (Waypoint)")

TabPlayer:AddWaypointManager({
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
})

TabPlayer:AddSection("Kontrol Gerakan Lokal")

local walkSlider = TabPlayer:AddSlider({
    Name = "Kecepatan Jalan (WalkSpeed)",
    Min = 16,
    Max = 120,
    Default = 16,
    Suffix = " ws",
    Callback = function(val)
        desiredWalkSpeed = val
        applyCharacterStats()
    end
})

local jumpSlider = TabPlayer:AddSlider({
    Name = "Kekuatan Lompat (JumpPower)",
    Min = 50,
    Max = 200,
    Default = 50,
    Suffix = " jp",
    Callback = function(val)
        desiredJumpPower = val
        applyCharacterStats()
    end
})

TabPlayer:AddToggle({
    Name = "Kunci Nilai Gerakan Saat Respawn",
    Default = false,
    Callback = function(state)
        lockCharacterStats = state
        if state then
            applyCharacterStats()
        end
        BimSakSinUI:Notify({
            Title = "Pengunci Statistik",
            Message = state and "Nilai WalkSpeed & JumpPower dikunci." or "Pengunci dimatikan.",
            Duration = 2.5,
        })
    end
})

TabPlayer:AddSection("Kontrol Kamera")

local fovSlider = TabPlayer:AddSlider({
    Name = "Field of View (FOV Kamera)",
    Min = 50,
    Max = 120,
    Default = 70,
    Suffix = "°",
    Callback = function(val)
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = val
        end
    end
})

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

-- ---------------- TAB 4: VISUAL & PENANDA LOKAL ----------------
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime  = Lighting.ClockTime,
    FogEnd     = Lighting.FogEnd,
    Ambient    = Lighting.Ambient,
}

local highlightEnabled = false
local nameTagEnabled = false
local autoTeamColorEnabled = true
local selectedFallbackColorOption = "Ikuti Warna Tema"
local PlayerMarkers = {}

local HighlightColors = {
    ["Merah Terang"] = Color3.fromRGB(255, 65, 65),
    ["Hijau Neon"]   = Color3.fromRGB(34, 197, 94),
    ["Kuning Emas"]  = Color3.fromRGB(250, 204, 21),
    ["Putih Bersih"] = Color3.fromRGB(248, 250, 252),
}

local function getFallbackHighlightColor()
    if selectedFallbackColorOption == "Ikuti Warna Tema" then
        return Palette.Accent
    end
    return HighlightColors[selectedFallbackColorOption] or Palette.Accent
end

local function getMarkerColorForPlayer(plr)
    if autoTeamColorEnabled and #Teams:GetTeams() > 0 and plr and not plr.Neutral then
        if plr.Team and plr.Team.TeamColor then
            return plr.Team.TeamColor.Color
        elseif plr.TeamColor then
            return plr.TeamColor.Color
        end
    end
    return getFallbackHighlightColor()
end

local function updateSinglePlayerMarkerColor(plr)
    local entry = PlayerMarkers[plr]
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
        if autoTeamColorEnabled and not plr.Neutral and plr.Team then
            entry.NameLabel.Text = string.format("[%s] %s", plr.Team.Name, plr.DisplayName)
        else
            entry.NameLabel.Text = plr.DisplayName
        end
    end
end

local function clearPlayerMarker(plr)
    local entry = PlayerMarkers[plr]
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
end

local function fullRemovePlayerTracking(plr)
    local entry = PlayerMarkers[plr]
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
        PlayerMarkers[plr] = nil
    end
end

local function applyMarkerToCharacter(plr, char)
    if plr == LocalPlayer or not char then
        return
    end

    local entry = PlayerMarkers[plr]
    if not entry then
        entry = {}
        PlayerMarkers[plr] = entry
    end

    clearPlayerMarker(plr)

    local activeColor = getMarkerColorForPlayer(plr)

    if highlightEnabled then
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

    if nameTagEnabled then
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 3)
        if head and nameTagEnabled then
            local bb = Instance.new("BillboardGui")
            bb.Name = "BimSakSinLocalNameTag"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 190, 0, 38)
            bb.StudsOffset = Vector3.new(0, 2.4, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = 2500
            bb.Parent = head

            local displayTitle = plr.DisplayName
            if autoTeamColorEnabled and #Teams:GetTeams() > 0 and not plr.Neutral and plr.Team then
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
end

local function refreshAllPlayerMarkers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local entry = PlayerMarkers[plr]
            if not entry then
                entry = {}
                PlayerMarkers[plr] = entry

                entry.CharConn = trackConnection(plr.CharacterAdded:Connect(function(newChar)
                    task.wait(0.15)
                    if highlightEnabled or nameTagEnabled then
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

            if (highlightEnabled or nameTagEnabled) and plr.Character then
                applyMarkerToCharacter(plr, plr.Character)
            else
                clearPlayerMarker(plr)
            end
        end
    end
end

local function updateAllMarkerColors()
    for plr, _ in pairs(PlayerMarkers) do
        updateSinglePlayerMarkerColor(plr)
    end
end

table.insert(ThemeChangeListeners, function()
    if selectedFallbackColorOption == "Ikuti Warna Tema" then
        updateAllMarkerColors()
    end
end)

registerCleanup(function()
    highlightEnabled = false
    nameTagEnabled = false
    for plr, _ in pairs(PlayerMarkers) do
        fullRemovePlayerTracking(plr)
    end
end)

TabVisual:AddSection("Penanda Visual Pemain (Lokal)")

TabVisual:AddToggle({
    Name = "Highlight Karakter Pemain",
    Default = false,
    Callback = function(state)
        highlightEnabled = state
        refreshAllPlayerMarkers()
        local infoTim = (autoTeamColorEnabled and #Teams:GetTeams() > 0)
            and " (mengikuti warna Team)."
            or "."
        BimSakSinUI:Notify({
            Title = "Highlight Pemain",
            Message = state and ("Penanda siluet pemain aktif" .. infoTim) or "Penanda siluet pemain dimatikan.",
            Duration = 2.5,
        })
    end
})

TabVisual:AddToggle({
    Name = "Label Nama & Jarak Pemain",
    Default = false,
    Callback = function(state)
        nameTagEnabled = state
        refreshAllPlayerMarkers()
    end
})

TabVisual:AddToggle({
    Name = "Sesuaikan Warna Team Otomatis",
    Default = true,
    Callback = function(state)
        autoTeamColorEnabled = state
        updateAllMarkerColors()
        local hasTeams = #Teams:GetTeams() > 0
        BimSakSinUI:Notify({
            Title = "Mode Warna Team",
            Message = state
                and (hasTeams and "Warna penanda mengikuti masing-masing Team." or "Aktif (game ini tidak memakai Teams, memakai warna cadangan).")
                or "Menggunakan warna statis pilihan.",
            Duration = 3,
        })
    end
})

TabVisual:AddDropdown({
    Name = "Warna Cadangan / Non-Team",
    Options = { "Ikuti Warna Tema", "Merah Terang", "Hijau Neon", "Kuning Emas", "Putih Bersih" },
    Default = "Ikuti Warna Tema",
    Callback = function(choice)
        selectedFallbackColorOption = choice
        updateAllMarkerColors()
    end
})

TabVisual:AddSection("Pencahayaan Lokal")

TabVisual:AddDropdown({
    Name = "Preset Suasana",
    Options = { "Default Server", "Siang Cerah (Fullbright)", "Malam Sinematik", "Sunset Hangat" },
    Default = "Default Server",
    Callback = function(choice)
        if choice == "Default Server" then
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime  = OriginalLighting.ClockTime
            Lighting.FogEnd     = OriginalLighting.FogEnd
            Lighting.Ambient    = OriginalLighting.Ambient
        elseif choice == "Siang Cerah (Fullbright)" then
            Lighting.Brightness = 2.5
            Lighting.ClockTime  = 14
            Lighting.FogEnd     = 100000
            Lighting.Ambient    = Color3.fromRGB(180, 180, 180)
        elseif choice == "Malam Sinematik" then
            Lighting.Brightness = 0.8
            Lighting.ClockTime  = 0
            Lighting.Ambient    = Color3.fromRGB(45, 55, 85)
        elseif choice == "Sunset Hangat" then
            Lighting.Brightness = 1.6
            Lighting.ClockTime  = 17.8
            Lighting.Ambient    = Color3.fromRGB(140, 100, 85)
        end
        BimSakSinUI:Notify({
            Title = "Preset Visual",
            Message = "Suasana diubah ke: " .. choice,
            Duration = 2.5,
        })
    end
})

TabVisual:AddSlider({
    Name = "Intensitas Cahaya (Brightness)",
    Min = 0,
    Max = 5,
    Default = math.floor(Lighting.Brightness),
    Suffix = "x",
    Callback = function(val)
        Lighting.Brightness = val
    end
})

TabVisual:AddToggle({
    Name = "Hilangkan Kabut (No Fog)",
    Default = false,
    Callback = function(state)
        Lighting.FogEnd = state and 100000 or OriginalLighting.FogEnd
    end
})

-- ---------------- TAB 5: PENGATURAN UI, ANTI-AFK, AUTO-REJOIN & SERVER HOP ----------------
local antiAfkEnabled = CurrentConfig.AntiAfk
local antiAfkPreventedCount = 0

local autoRejoinEnabled = CurrentConfig.AutoRejoin
local autoRejoinMode = CurrentConfig.AutoRejoinMode
local isRejoining = false
local rejoinRetryCount = 0
local MAX_REJOIN_RETRIES = 3

local serverHopMode = CurrentConfig.ServerHopMode
local isServerHopping = false
local hopCandidatePool = {}
local hopRetryCount = 0
local MAX_HOP_RETRIES = 3

registerCleanup(function()
    antiAfkEnabled = false
    autoRejoinEnabled = false
    isRejoining = false
    isServerHopping = false
    table.clear(hopCandidatePool)
end)

TabSettings:AddSection("Perlindungan Sesi (Anti-AFK)")

local antiAfkStatusCard = TabSettings:AddInfoCard("Status Anti-AFK", antiAfkEnabled and "Aktif (0x Dicegah)" or "Nonaktif")

TabSettings:AddToggle({
    Name = "Anti-AFK Aman (Cegah Kick 20 Menit)",
    Default = CurrentConfig.AntiAfk,
    Callback = function(state)
        antiAfkEnabled = state
        CurrentConfig.AntiAfk = state
        saveConfig()

        if state then
            antiAfkStatusCard:SetValue(string.format("Aktif (%dx Dicegah)", antiAfkPreventedCount))
            BimSakSinUI:Notify({
                Title = "Anti-AFK Aktif",
                Message = "Sesi aman dari pemutusan otomatis saat karakter diam.",
                Duration = 2.5,
            })
        else
            antiAfkStatusCard:SetValue("Nonaktif")
            BimSakSinUI:Notify({
                Title = "Anti-AFK Dimatikan",
                Message = "Timer AFK standar server kembali berlaku.",
                Duration = 2.5,
            })
        end
    end
})

trackConnection(LocalPlayer.Idled:Connect(function()
    if not antiAfkEnabled then
        return
    end

    local ok = pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)

    if ok then
        antiAfkPreventedCount = antiAfkPreventedCount + 1
        antiAfkStatusCard:SetValue(string.format("Aktif (%dx Dicegah)", antiAfkPreventedCount))
        BimSakSinUI:Notify({
            Title = "Anti-AFK Bekerja",
            Message = string.format("Timer diam direset otomatis (Total: %dx).", antiAfkPreventedCount),
            Duration = 3,
        })
    end
end))

TabSettings:AddSection("Pindah Server (Server Hop & JobId)")

local serverHopStatusCard = TabSettings:AddInfoCard("Status Pindah Server", "Siap")

local function httpGetPublicServers(sortOrder)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100",
        game.PlaceId,
        sortOrder
    )

    local rawBody = nil
    local okGet = pcall(function()
        rawBody = game:HttpGet(url)
    end)

    if not okGet or not rawBody or rawBody == "" then
        local reqFn = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
        if reqFn then
            local okReq, res = pcall(function()
                return reqFn({ Url = url, Method = "GET" })
            end)
            if okReq and type(res) == "table" and res.Body then
                rawBody = res.Body
            end
        end
    end

    if not rawBody or rawBody == "" then
        return nil, "Gagal menghubungi API daftar server Roblox."
    end

    local okDecode, decoded = pcall(function()
        return HttpService:JSONDecode(rawBody)
    end)

    if not okDecode or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
        return nil, "Respons server tidak valid atau terkena batas permintaan (Rate Limit)."
    end

    return decoded.data, nil
end

local function executeServerHop()
    if isServerHopping or isRejoining then
        BimSakSinUI:Notify({
            Title = "Proses Berjalan",
            Message = "Harap tunggu proses perpindahan server sebelumnya selesai.",
            Duration = 2.5,
        })
        return
    end

    isServerHopping = true
    hopRetryCount = 0
    table.clear(hopCandidatePool)

    serverHopStatusCard:SetValue("Mencari Server...")
    BimSakSinUI:Notify({
        Title = "Server Hop",
        Message = "Mencari daftar server publik (" .. serverHopMode .. ")...",
        Duration = 2.5,
    })

    task.spawn(function()
        local sortOrder = (serverHopMode == "Server Sepi (Pemain Terdikit)") and "Asc" or "Desc"
        local serverList, fetchErr = httpGetPublicServers(sortOrder)

        if not serverList then
            isServerHopping = false
            serverHopStatusCard:SetValue("Gagal Mengambil Data")
            BimSakSinUI:Notify({
                Title = "Server Hop Gagal",
                Message = fetchErr or "Tidak dapat memuat daftar server.",
                Duration = 4,
            })
            return
        end

        for _, srv in ipairs(serverList) do
            if type(srv) == "table"
                and type(srv.id) == "string"
                and srv.id ~= ""
                and srv.id ~= game.JobId
                and type(srv.playing) == "number"
                and type(srv.maxPlayers) == "number"
                and srv.playing >= 1
                and srv.playing < srv.maxPlayers then
                table.insert(hopCandidatePool, srv)
            end
        end

        if #hopCandidatePool == 0 then
            isServerHopping = false
            serverHopStatusCard:SetValue("Tidak Ada Server Lain")
            BimSakSinUI:Notify({
                Title = "Server Hop",
                Message = "Tidak ditemukan server publik lain yang tersedia saat ini.",
                Duration = 3.5,
            })
            return
        end

        local chosenIndex = 1
        if serverHopMode == "Server Sepi (Pemain Terdikit)" then
            table.sort(hopCandidatePool, function(a, b)
                return a.playing < b.playing
            end)
            chosenIndex = 1
        elseif serverHopMode == "Server Ramai (Hampir Penuh)" then
            table.sort(hopCandidatePool, function(a, b)
                return a.playing > b.playing
            end)
            chosenIndex = 1
        else
            chosenIndex = math.random(1, #hopCandidatePool)
        end

        local targetServer = table.remove(hopCandidatePool, chosenIndex)
        serverHopStatusCard:SetValue(string.format("Pindah (%d/%d Pemain)...", targetServer.playing, targetServer.maxPlayers))

        BimSakSinUI:Notify({
            Title = "Server Ditemukan",
            Message = string.format("Berpindah ke server baru (%d/%d pemain)...", targetServer.playing, targetServer.maxPlayers),
            Duration = 3,
        })

        local okTp, tpErr = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, LocalPlayer)
        end)

        if not okTp then
            isServerHopping = false
            serverHopStatusCard:SetValue("Gagal Teleport")
            BimSakSinUI:Notify({
                Title = "Teleport Gagal",
                Message = tostring(tpErr),
                Duration = 4,
            })
        end
    end)
end

local function executeJoinByJobId(rawJobId)
    if isServerHopping or isRejoining then
        BimSakSinUI:Notify({
            Title = "Proses Berjalan",
            Message = "Harap tunggu proses perpindahan server sebelumnya selesai.",
            Duration = 2.5,
        })
        return
    end

    local cleanJobId = (rawJobId or ""):match("^%s*(.-)%s*$") or ""
    if cleanJobId == "" then
        BimSakSinUI:Notify({
            Title = "JobId Kosong",
            Message = "Masukkan atau tempel kode JobId server tujuan terlebih dahulu.",
            Duration = 3,
        })
        return
    end

    if cleanJobId == game.JobId then
        BimSakSinUI:Notify({
            Title = "Sudah di Server Ini",
            Message = "Kamu sudah berada di server dengan JobId tersebut.",
            Duration = 3,
        })
        return
    end

    isServerHopping = true
    hopRetryCount = 0
    table.clear(hopCandidatePool)

    serverHopStatusCard:SetValue("Join via JobId...")
    BimSakSinUI:Notify({
        Title = "Menghubungkan ke Server",
        Message = "Mencoba masuk ke JobId: " .. cleanJobId,
        Duration = 3,
    })

    local okTp, tpErr = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, cleanJobId, LocalPlayer)
    end)

    if not okTp then
        isServerHopping = false
        serverHopStatusCard:SetValue("JobId Tidak Valid")
        BimSakSinUI:Notify({
            Title = "Gagal Join JobId",
            Message = tostring(tpErr),
            Duration = 4,
        })
    end
end

TabSettings:AddDropdown({
    Name = "Mode Pencarian Server",
    Options = { "Server Acak (Random)", "Server Sepi (Pemain Terdikit)", "Server Ramai (Hampir Penuh)" },
    Default = CurrentConfig.ServerHopMode,
    Callback = function(choice)
        serverHopMode = choice
        CurrentConfig.ServerHopMode = choice
        saveConfig()
        BimSakSinUI:Notify({
            Title = "Mode Server Hop",
            Message = "Prioritas pencarian: " .. choice,
            Duration = 2.5,
        })
    end
})

TabSettings:AddButton({
    Name = "Server Hop (Pindah Server Lain)",
    Callback = function()
        executeServerHop()
    end
})

local jobIdJoinCard = createInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 114),
    BackgroundColor3 = Palette.Card,
    Parent = TabSettings.Container,
})
addCorner(jobIdJoinCard, 8)
addStroke(jobIdJoinCard, Palette.Stroke, 1)

createInstance("TextLabel", {
    Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "Join Server Spesifik via JobId",
    TextColor3 = Palette.TextPrimary,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = jobIdJoinCard,
})

local jobIdInputCell = createInstance("Frame", {
    Size = UDim2.new(1, -24, 0, 32),
    Position = UDim2.new(0, 12, 0, 34),
    BackgroundColor3 = Palette.Sidebar,
    Parent = jobIdJoinCard,
})
addCorner(jobIdInputCell, 6)
local jobIdInputStroke = addStroke(jobIdInputCell, Palette.Stroke, 1)

local jobIdBox = createInstance("TextBox", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    PlaceholderText = "Tempel kode JobId server (contoh: a1b2c3d4-...)...",
    PlaceholderColor3 = Palette.TextSecondary,
    Text = "",
    TextColor3 = Palette.TextPrimary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = jobIdInputCell,
})

trackConnection(jobIdBox.Focused:Connect(function()
    TweenService:Create(jobIdInputStroke, TweenInfo.new(0.15), { Color = Palette.Accent }):Play()
end))

trackConnection(jobIdBox.FocusLost:Connect(function()
    TweenService:Create(jobIdInputStroke, TweenInfo.new(0.15), { Color = Palette.Stroke }):Play()
end))

local jobIdActionsRow = createInstance("Frame", {
    Size = UDim2.new(1, -24, 0, 30),
    Position = UDim2.new(0, 12, 0, 74),
    BackgroundTransparency = 1,
    Parent = jobIdJoinCard,
})

local clearJobIdBtn = createInstance("TextButton", {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Palette.Sidebar,
    Font = Enum.Font.GothamSemibold,
    Text = "Bersihkan",
    TextColor3 = Palette.TextPrimary,
    TextSize = 11,
    AutoButtonColor = false,
    Parent = jobIdActionsRow,
})
addCorner(clearJobIdBtn, 6)
addStroke(clearJobIdBtn, Palette.Stroke, 1)

local joinJobIdBtn = createInstance("TextButton", {
    Size = UDim2.new(0.65, 0, 1, 0),
    Position = UDim2.new(0.35, 0, 0, 0),
    BackgroundColor3 = Palette.Accent,
    Font = Enum.Font.GothamBold,
    Text = "Join Server via JobId",
    TextColor3 = Color3.fromRGB(15, 20, 28),
    TextSize = 11,
    AutoButtonColor = false,
    Parent = jobIdActionsRow,
})
addCorner(joinJobIdBtn, 6)
registerAccent(joinJobIdBtn, "BackgroundColor3")

trackConnection(clearJobIdBtn.MouseButton1Click:Connect(function()
    jobIdBox.Text = ""
end))

trackConnection(joinJobIdBtn.MouseButton1Click:Connect(function()
    executeJoinByJobId(jobIdBox.Text)
end))

TabSettings:AddSection("Pemulihan Koneksi (Auto-Rejoin)")

local autoRejoinStatusCard = TabSettings:AddInfoCard("Status Auto-Rejoin", autoRejoinEnabled and "Siaga" or "Nonaktif")

local function executeServerRejoin(isAutomatic, reasonText)
    if isRejoining or isServerHopping then
        return
    end
    isRejoining = true
    rejoinRetryCount = 0

    local placeId = game.PlaceId
    local jobId = game.JobId
    local preferSameInstance = (autoRejoinMode == "Server Sama (Fallback Publik)") and (jobId ~= nil and jobId ~= "")

    autoRejoinStatusCard:SetValue("Menghubungkan Ulang...")
    BimSakSinUI:Notify({
        Title = isAutomatic and "Koneksi Terputus" or "Memulai Rejoin",
        Message = (reasonText and (reasonText .. " • ") or "") .. "Masuk kembali dalam 2 detik...",
        Duration = 3,
    })

    task.spawn(function()
        task.wait(2)
        if isAutomatic and not autoRejoinEnabled then
            isRejoining = false
            autoRejoinStatusCard:SetValue("Nonaktif")
            return
        end

        local ok, err = pcall(function()
            if preferSameInstance then
                TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
            else
                TeleportService:Teleport(placeId, LocalPlayer)
            end
        end)

        if not ok then
            isRejoining = false
            autoRejoinStatusCard:SetValue(autoRejoinEnabled and "Siaga (Gagal Rejoin)" or "Nonaktif")
            BimSakSinUI:Notify({
                Title = "Rejoin Gagal",
                Message = tostring(err),
                Duration = 4,
            })
        end
    end)
end

trackConnection(TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player ~= LocalPlayer then
        return
    end

    if isServerHopping then
        hopRetryCount = hopRetryCount + 1
        if hopRetryCount <= MAX_HOP_RETRIES and #hopCandidatePool > 0 then
            local nextIdx = (serverHopMode == "Server Acak (Random)") and math.random(1, #hopCandidatePool) or 1
            local nextServer = table.remove(hopCandidatePool, nextIdx)
            serverHopStatusCard:SetValue(string.format("Mencoba Server Lain (%d/%d)...", hopRetryCount, MAX_HOP_RETRIES))
            BimSakSinUI:Notify({
                Title = "Server Tujuan Penuh",
                Message = string.format("Mengalihkan ke server cadangan (%d/%d pemain)...", nextServer.playing, nextServer.maxPlayers),
                Duration = 2.5,
            })
            task.delay(1.5, function()
                if isServerHopping then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, nextServer.id, LocalPlayer)
                    end)
                end
            end)
        else
            isServerHopping = false
            table.clear(hopCandidatePool)
            serverHopStatusCard:SetValue("Gagal Pindah Server")
            BimSakSinUI:Notify({
                Title = "Gagal Masuk Server",
                Message = "Tidak berhasil masuk ke server tujuan: " .. tostring(errorMessage),
                Duration = 4,
            })
        end
        return
    end

    if isRejoining then
        rejoinRetryCount = rejoinRetryCount + 1
        if rejoinRetryCount <= MAX_REJOIN_RETRIES then
            autoRejoinStatusCard:SetValue(string.format("Mencoba Server Publik (%d/%d)...", rejoinRetryCount, MAX_REJOIN_RETRIES))
            BimSakSinUI:Notify({
                Title = "Server Lama Penuh / Tutup",
                Message = "Mengalihkan otomatis ke server publik yang tersedia...",
                Duration = 3,
            })
            task.delay(2, function()
                if isRejoining then
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end)
                end
            end)
        else
            isRejoining = false
            autoRejoinStatusCard:SetValue(autoRejoinEnabled and "Siaga (Batas Coba Tercapai)" or "Nonaktif")
            BimSakSinUI:Notify({
                Title = "Auto-Rejoin Berhenti",
                Message = "Gagal masuk setelah " .. tostring(MAX_REJOIN_RETRIES) .. " percobaan: " .. tostring(errorMessage),
                Duration = 4,
            })
        end
    end
end))

trackConnection(GuiService.ErrorMessageChanged:Connect(function()
    if not autoRejoinEnabled or isRejoining or isServerHopping then
        return
    end
    local errCode = GuiService:GetErrorCode()
    local errMsg = GuiService:GetErrorMessage()
    if errCode ~= Enum.ConnectionError.OK or (errMsg and errMsg ~= "") then
        executeServerRejoin(true, "Error Koneksi Terdeteksi")
    end
end))

pcall(function()
    local coreGui = game:GetService("CoreGui")
    local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
    local promptOverlay = promptGui and promptGui:FindFirstChild("promptOverlay")
    if promptOverlay then
        trackConnection(promptOverlay.ChildAdded:Connect(function(child)
            if autoRejoinEnabled and not isRejoining and not isServerHopping and child.Name == "ErrorPrompt" then
                executeServerRejoin(true, "Dialog Disconnect Terdeteksi")
            end
        end))
    end
end)

TabSettings:AddToggle({
    Name = "Auto-Rejoin Saat Terputus",
    Default = CurrentConfig.AutoRejoin,
    Callback = function(state)
        autoRejoinEnabled = state
        CurrentConfig.AutoRejoin = state
        saveConfig()

        if state then
            autoRejoinStatusCard:SetValue("Siaga (Mendeteksi Error)")
            BimSakSinUI:Notify({
                Title = "Auto-Rejoin Aktif",
                Message = "Otomatis masuk kembali jika koneksi server terputus.",
                Duration = 2.5,
            })
        else
            isRejoining = false
            autoRejoinStatusCard:SetValue("Nonaktif")
            BimSakSinUI:Notify({
                Title = "Auto-Rejoin Dimatikan",
                Message = "Pemulihan koneksi otomatis dinonaktifkan.",
                Duration = 2.5,
            })
        end
    end
})

TabSettings:AddDropdown({
    Name = "Target Server Rejoin",
    Options = { "Server Sama (Fallback Publik)", "Server Publik Acak" },
    Default = CurrentConfig.AutoRejoinMode,
    Callback = function(choice)
        autoRejoinMode = choice
        CurrentConfig.AutoRejoinMode = choice
        saveConfig()
        BimSakSinUI:Notify({
            Title = "Mode Rejoin Diubah",
            Message = "Target: " .. choice,
            Duration = 2.5,
        })
    end
})

TabSettings:AddButton({
    Name = "Rejoin Server Sekarang",
    Callback = function()
        executeServerRejoin(false, "Rejoin Manual")
    end
})

TabSettings:AddSection("Tampilan & Kontrol Panel")

TabSettings:AddDropdown({
    Name = "Warna Aksen Tema",
    Options = { "Cyan Electric", "Emerald Green", "Royal Purple", "Sunset Orange" },
    Default = CurrentConfig.Theme,
    Callback = function(themeName)
        applyThemeAccent(themeName)
        BimSakSinUI:Notify({
            Title = "Tema Diperbarui",
            Message = "Warna aksen diganti ke " .. themeName,
            Duration = 2.5,
        })
    end
})

TabSettings:AddToggle({
    Name = "Tampilkan Watermark HUD (FPS, Ping & Waktu)",
    Default = CurrentConfig.WatermarkVisible,
    Callback = function(state)
        CurrentConfig.WatermarkVisible = state
        saveConfig()
        if WatermarkFrame and WatermarkFrame.Parent then
            WatermarkFrame.Visible = state
        end
    end
})

TabSettings:AddDropdown({
    Name = "Posisi Sudut Watermark",
    Options = { "Kiri Atas", "Kanan Atas", "Kiri Bawah", "Kanan Bawah" },
    Default = CurrentConfig.WatermarkCorner,
    Callback = function(cornerName)
        setWatermarkCorner(cornerName)
    end
})

TabSettings:AddKeybind({
    Name = "Tombol Buka / Sembunyikan Panel",
    Default = Enum.KeyCode.FromValue(CurrentConfig.Keybinds.ToggleUI) or Enum.KeyCode.RightShift,
    ConfigKeyName = "ToggleUI",
    OnKeyChanged = function(newKey)
        Window:SetToggleKey(newKey)
    end,
})

TabSettings:AddToggle({
    Name = "Kunci Posisi Window & Watermark",
    Default = false,
    Callback = function(state)
        WindowLocked = state
    end
})

TabSettings:AddButton({
    Name = "Tutup & Hapus Panel UI",
    Callback = function()
        Window:Destroy()
    end
})

-- ============================================================================
-- SINKRONISASI PEMAIN, FLY, NOCLIP, INFINITE JUMP & TELEMETRI
-- ============================================================================
trackConnection(Players.PlayerAdded:Connect(function()
    rebuildPlayerList()
    refreshAllPlayerMarkers()
end))

trackConnection(Players.PlayerRemoving:Connect(function(leavingPlayer)
    fullRemovePlayerTracking(leavingPlayer)
    if spectatedPlayer == leavingPlayer then
        stopSpectate(true)
        BimSakSinUI:Notify({
            Title = "Target Keluar Server",
            Message = leavingPlayer.DisplayName .. " keluar. Kamera kembali ke kamu.",
            Duration = 3,
        })
    end
    task.defer(rebuildPlayerList)
end))

rebuildPlayerList()
refreshAllPlayerMarkers()

trackConnection(UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled or flyEnabled then
        return
    end

    local now = os.clock()
    if now - lastAirJumpTime < AIR_JUMP_COOLDOWN then
        return
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then
        return
    end

    local currentState = hum:GetState()
    if currentState == Enum.HumanoidStateType.Dead
        or currentState == Enum.HumanoidStateType.Seated
        or currentState == Enum.HumanoidStateType.Swimming
        or currentState == Enum.HumanoidStateType.Physics then
        return
    end

    lastAirJumpTime = now
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end))

trackConnection(RunService.Stepped:Connect(function()
    if not noclipEnabled then
        return
    end
    local char = LocalPlayer.Character
    if not char then
        return
    end
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if originalCollideStates[descendant] == nil then
                originalCollideStates[descendant] = descendant.CanCollide
            end
            if descendant.CanCollide then
                descendant.CanCollide = false
            end
        end
    end
end))

local frameCounter = 0
local elapsed = 0

trackConnection(RunService.RenderStepped:Connect(function(dt)
    frameCounter = frameCounter + 1
    elapsed = elapsed + dt

    if flyEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera

        if hrp and hum and cam then
            if not flyLinearVel or not flyLinearVel.Parent or not flyAlignOrient or not flyAlignOrient.Parent then
                setupFlyConstraints(char)
            end

            hum.PlatformStand = true

            local moveDir = hum.MoveDirection
            local flatLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
            if flatLook.Magnitude > 0.001 then
                flatLook = flatLook.Unit
            else
                flatLook = Vector3.new(0, 0, -1)
            end

            local flatRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
            if flatRight.Magnitude > 0.001 then
                flatRight = flatRight.Unit
            else
                flatRight = Vector3.new(1, 0, 0)
            end

            local forwardInput = moveDir:Dot(flatLook)
            local rightInput = moveDir:Dot(flatRight)
            local verticalInput = 0

            if not UserInputService:GetFocusedTextBox() then
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
                    verticalInput = verticalInput + 1
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
                    verticalInput = verticalInput - 1
                end
            end

            local wishDir = (cam.CFrame.LookVector * forwardInput)
                + (cam.CFrame.RightVector * rightInput)
                + Vector3.new(0, verticalInput, 0)

            if wishDir.Magnitude > 1 then
                wishDir = wishDir.Unit
            end

            local targetVel = wishDir * flySpeed
            local smoothAlpha = 1 - math.exp(-12 * math.clamp(dt, 0.001, 0.1))
            currentFlyVelocity = currentFlyVelocity:Lerp(targetVel, smoothAlpha)

            if flyLinearVel then
                flyLinearVel.VectorVelocity = currentFlyVelocity
            end
            if flyAlignOrient then
                local camLook = cam.CFrame.LookVector
                local horizLook = Vector3.new(camLook.X, 0, camLook.Z)
                if horizLook.Magnitude > 0.001 then
                    flyAlignOrient.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + horizLook.Unit)
                end
            end
        end
    end

    if elapsed >= 0.4 then
        local fps = math.floor((frameCounter / elapsed) + 0.5)
        local fpsText = tostring(fps) .. " FPS"
        fpsCard:SetValue(fpsText)

        if wmFpsLabel and wmFpsLabel.Parent then
            wmFpsLabel.Text = fpsText
        end

        local ok, pingVal = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and pingVal then
            local pingText = tostring(pingVal) .. " ms"
            pingCard:SetValue(pingText)

            if wmPingLabel and wmPingLabel.Parent then
                wmPingLabel.Text = pingText
                if pingVal < 90 then
                    wmPingLabel.TextColor3 = Palette.Success
                elseif pingVal < 180 then
                    wmPingLabel.TextColor3 = Palette.Warning
                else
                    wmPingLabel.TextColor3 = Palette.Danger
                end
            end
        end

        if wmTimeLabel and wmTimeLabel.Parent then
            wmTimeLabel.Text = os.date("%H:%M:%S")
        end

        playerCountCard:SetValue(tostring(#Players:GetPlayers()) .. " Pemain")

        if nameTagEnabled then
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                for plr, entry in pairs(PlayerMarkers) do
                    if entry.DistanceLabel and entry.DistanceLabel.Parent and plr.Character then
                        local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP then
                            local dist = math.floor((myHRP.Position - targetHRP.Position).Magnitude + 0.5)
                            entry.DistanceLabel.Text = tostring(dist) .. " stud"
                        end
                    end
                end
            end
        end

        frameCounter = 0
        elapsed = 0
    end

    if lockCharacterStats and not flyEnabled then
        applyCharacterStats()
    end

    if spectatedPlayer and spectatedPlayer.Parent then
        local targetChar = spectatedPlayer.Character
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if cam and targetHum and cam.CameraSubject ~= targetHum then
            cam.CameraSubject = targetHum
        end
    end
end))

trackConnection(LocalPlayer.CharacterRemoving:Connect(function()
    destroyFlyConstraints()
    table.clear(originalCollideStates)
end))

trackConnection(LocalPlayer.CharacterAdded:Connect(function(newChar)
    table.clear(originalCollideStates)
    if flyEnabled then
        newChar:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.15)
        if flyEnabled then
            setupFlyConstraints(newChar)
        end
    elseif lockCharacterStats then
        task.wait(0.2)
        applyCharacterStats()
    end
end))

BimSakSinUI:Notify({
    Title = "BimSakSin Hub v4.1 (Persistent)",
    Message = "Konfigurasi, Waypoint, dan Status berhasil dimuat dari file JSON.",
    Duration = 4,
})
