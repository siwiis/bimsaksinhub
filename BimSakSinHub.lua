--=============================================================================
-- BimSakSin Hub v2 | Professional Modular Utility & Telemetry Overlay (Delta)
--=============================================================================
-- Pembaruan & Perbaikan Utama:
--   1. Compact Top-Bar Glass Layout (menyerupai desain referensi kedua, ringkas & elegan)
--   2. Tombol (-) Minimize ke Floating Skull & Tombol (X) Close + Full Reset Semua Fitur
--   3. Bottom Resize Grip Bar (tahan & seret tab bar bawah untuk memperbesar/memperkecil panel)
--   4. Refined Character ESP (ukuran font proporsional di atas kepala, outline hitam presisi)
--   5. Deep Universal Generator ESP + Real-Time Progress (%) & Live Generator List
--   6. Interactive Player Teleport & Spectate (View) Cards + Quick Nearest Enemy/Player TP
--   7. Live Theme & Font Color Customizer (mengubah warna kaca panel & warna teks seluruh fitur)
--   8. Proporsional 3D HD Skull & 3D Verified Blue Checkmark Badge
--=============================================================================

if getgenv and getgenv().BimSakSinHubCleanup then
    pcall(getgenv().BimSakSinHubCleanup)
end

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// 1. LIFECYCLE & CLEANUP REGISTRY
local Hub = {
    Alive = true,
    Connections = {},
    ESPObjects = {},
    GeneratorObjects = {},
    OriginalMaterials = {},
    OriginalLighting = {},
    SelectedTarget = nil,
    ViewingTarget = false,
    ThemeObjects = {
        Panels = {},
        Strokes = {},
        Texts = {},
        Accents = {},
    },
    ToggleRefreshers = {},
}

function Hub:AddConnection(conn)
    if conn then
        table.insert(self.Connections, conn)
    end
    return conn
end

--// 2. CONFIG & STATE MANAGER
local CONFIG_FILE = "BimSakSinHub_v2_Config.json"

local ThemePresets = {
    { Name = "Crystal White", Panel = {255, 255, 255}, Font = {255, 255, 255}, Accent = {45, 175, 255} },
    { Name = "Midnight Obsidian", Panel = {18, 22, 30}, Font = {245, 248, 255}, Accent = {56, 189, 248} },
    { Name = "Cyber Cyan", Panel = {12, 38, 52}, Font = {190, 248, 255}, Accent = {0, 230, 255} },
    { Name = "Emerald Glass", Panel = {14, 42, 32}, Font = {210, 255, 230}, Accent = {50, 235, 145} },
    { Name = "Crimson Dark", Panel = {42, 16, 22}, Font = {255, 225, 230}, Accent = {255, 75, 100} },
    { Name = "Royal Gold", Panel = {36, 30, 16}, Font = {255, 244, 200}, Accent = {255, 195, 45} },
}

local DefaultConfig = {
    ESP_Enabled = true,
    ESP_ShowDistance = true,
    ESP_AvatarMarker = true,
    ESP_TeamCheck = true,
    Generator_ESP = true,
    Fly_Enabled = false,
    Fly_Speed = 60,
    WalkSpeed_Enabled = false,
    WalkSpeed_Value = 32,
    JumpPower_Enabled = false,
    JumpPower_Value = 85,
    Noclip_Enabled = false,
    AntiLag_Enabled = false,
    Panel_Open = true,
    Panel_Width = 450,
    Panel_Height = 325,
    Floating_Pos = { X = 0.84, Y = 0.28 },
    Theme_Index = 1,
}

local State = {}
for k, v in pairs(DefaultConfig) do
    State[k] = (type(v) == "table") and { X = v.X, Y = v.Y } or v
end

local function SaveConfig()
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(State))
    end)
end

local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" then
                for k, defaultVal in pairs(DefaultConfig) do
                    if decoded[k] ~= nil and type(decoded[k]) == type(defaultVal) then
                        State[k] = decoded[k]
                    end
                end
            end
        end
    end)
end

LoadConfig()

--// Forward declarations for cleanup/reset
local DisableFly, ApplyAntiLag, StopSpectating

function Hub:Cleanup()
    self.Alive = false
    if StopSpectating then pcall(StopSpectating) end
    if DisableFly then pcall(DisableFly) end
    if ApplyAntiLag then pcall(function() ApplyAntiLag(false) end) end

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    for _, conn in ipairs(self.Connections) do
        pcall(function()
            if conn.Connected then conn:Disconnect() end
        end)
    end
    table.clear(self.Connections)

    for _, espData in pairs(self.ESPObjects) do
        pcall(function()
            if espData.Billboard then espData.Billboard:Destroy() end
            if espData.Highlight then espData.Highlight:Destroy() end
        end)
    end
    table.clear(self.ESPObjects)

    for _, genData in pairs(self.GeneratorObjects) do
        pcall(function()
            if genData.Billboard then genData.Billboard:Destroy() end
            if genData.Highlight then genData.Highlight:Destroy() end
        end)
    end
    table.clear(self.GeneratorObjects)

    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
    end
end

if getgenv then
    getgenv().BimSakSinHubCleanup = function()
        Hub:Cleanup()
    end
end

--// 3. HELPER UTILITIES & THEME ENGINE
local function GetSafeGuiParent()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function GetCurrentTheme()
    local idx = math.clamp(State.Theme_Index or 1, 1, #ThemePresets)
    local p = ThemePresets[idx]
    return {
        Name = p.Name,
        PanelColor = Color3.fromRGB(p.Panel[1], p.Panel[2], p.Panel[3]),
        FontColor = Color3.fromRGB(p.Font[1], p.Font[2], p.Font[3]),
        AccentColor = Color3.fromRGB(p.Accent[1], p.Accent[2], p.Accent[3]),
    }
end

local function RegisterThemePanel(obj)
    table.insert(Hub.ThemeObjects.Panels, obj)
    obj.BackgroundColor3 = GetCurrentTheme().PanelColor
end

local function RegisterThemeStroke(obj)
    table.insert(Hub.ThemeObjects.Strokes, obj)
    obj.Color = GetCurrentTheme().FontColor
end

local function RegisterThemeText(obj)
    table.insert(Hub.ThemeObjects.Texts, obj)
    obj.TextColor3 = GetCurrentTheme().FontColor
end

local function RegisterThemeAccent(obj)
    table.insert(Hub.ThemeObjects.Accents, obj)
    obj.BackgroundColor3 = GetCurrentTheme().AccentColor
end

local function ApplyThemeToAllUI()
    local theme = GetCurrentTheme()
    for _, pnl in ipairs(Hub.ThemeObjects.Panels) do
        if pnl and pnl.Parent then
            pnl.BackgroundColor3 = theme.PanelColor
        end
    end
    for _, strk in ipairs(Hub.ThemeObjects.Strokes) do
        if strk and strk.Parent then
            strk.Color = theme.FontColor
        end
    end
    for _, txt in ipairs(Hub.ThemeObjects.Texts) do
        if txt and txt.Parent then
            txt.TextColor3 = theme.FontColor
        end
    end
    for _, acc in ipairs(Hub.ThemeObjects.Accents) do
        if acc and acc.Parent then
            acc.BackgroundColor3 = theme.AccentColor
        end
    end
    for _, refreshFn in ipairs(Hub.ToggleRefreshers) do
        pcall(refreshFn)
    end
end

local function GetPlayerRelation(targetPlayer)
    if targetPlayer == LocalPlayer then
        return "SELF", Color3.fromRGB(255, 255, 255)
    end

    local isFriend = false
    pcall(function()
        isFriend = LocalPlayer:IsFriendsWith(targetPlayer.UserId)
    end)

    local sameTeam = false
    if LocalPlayer.Team ~= nil and targetPlayer.Team ~= nil then
        sameTeam = (LocalPlayer.Team == targetPlayer.Team)
    elseif LocalPlayer.TeamColor ~= nil and targetPlayer.TeamColor ~= nil and not LocalPlayer.Neutral then
        sameTeam = (LocalPlayer.TeamColor == targetPlayer.TeamColor)
    end

    if isFriend then
        return "TEMAN", Color3.fromRGB(56, 232, 255)
    elseif State.ESP_TeamCheck and sameTeam then
        return "TEAM", Color3.fromRGB(95, 255, 145)
    else
        return "MUSUH", Color3.fromRGB(255, 82, 102)
    end
end

-- Refined Proportional Text with Crisp Tight Black Outline (No Box, Not Oversized)
local function CreateTightStyledText(parent, name, order, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.LayoutOrder = order
    lbl.AutomaticSize = Enum.AutomaticSize.XY
    lbl.Size = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = textSize or 11
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.05
    lbl.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 1.65 -- Clean tight black contour around characters only
    stroke.Transparency = 0.08
    stroke.Parent = lbl

    return lbl
end

--// 4. UI COMPONENT FACTORY (Compact Glassmorphism Layout Like Reference Image 2)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = GetSafeGuiParent()
Hub.ScreenGui = ScreenGui

local function TweenObj(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Draggable Utility
local function MakeDraggable(dragHandle, targetFrame, onDragEnd)
    local dragging = false
    local dragInput, dragStart, startPos

    Hub:AddConnection(dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                    if onDragEnd then onDragEnd(targetFrame.Position) end
                end
            end)
        end
    end))

    Hub:AddConnection(dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    Hub:AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- 3D HD Skull Builder (Balanced Medium-HD Proportions)
local function Build3DSkullViewport(parent, sizeUDim2, posUDim2, anchorPoint)
    local vp = Instance.new("ViewportFrame")
    vp.Size = sizeUDim2
    vp.Position = posUDim2
    vp.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    vp.BackgroundTransparency = 1
    vp.Ambient = Color3.fromRGB(225, 240, 255)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(-1, -1, -1)
    vp.Parent = parent

    local wm = Instance.new("WorldModel")
    wm.Parent = vp

    local vpCam = Instance.new("Camera")
    vpCam.CFrame = CFrame.new(Vector3.new(0, 0.08, 3.25), Vector3.new(0, 0, 0))
    vpCam.Parent = vp
    vp.CurrentCamera = vpCam

    local skullModel = Instance.new("Model")
    skullModel.Name = "HD_Skull_3D"
    skullModel.Parent = wm

    local cranium = Instance.new("Part")
    cranium.Size = Vector3.new(1.6, 1.5, 1.7)
    cranium.Position = Vector3.new(0, 0.28, 0)
    cranium.Material = Enum.Material.SmoothPlastic
    cranium.Color = Color3.fromRGB(245, 248, 255)
    cranium.Anchored = true
    local craniumMesh = Instance.new("SpecialMesh")
    craniumMesh.MeshType = Enum.MeshType.Sphere
    craniumMesh.Parent = cranium
    cranium.Parent = skullModel

    local jaw = Instance.new("Part")
    jaw.Size = Vector3.new(0.98, 0.74, 1.08)
    jaw.Position = Vector3.new(0, -0.45, 0.18)
    jaw.Material = Enum.Material.SmoothPlastic
    jaw.Color = Color3.fromRGB(230, 236, 248)
    jaw.Anchored = true
    local jawMesh = Instance.new("SpecialMesh")
    jawMesh.MeshType = Enum.MeshType.Sphere
    jawMesh.Parent = jaw
    jaw.Parent = skullModel

    for _, side in ipairs({ -1, 1 }) do
        local eye = Instance.new("Part")
        eye.Size = Vector3.new(0.38, 0.38, 0.28)
        eye.Position = Vector3.new(side * 0.35, 0.15, 0.74)
        eye.Material = Enum.Material.Neon
        eye.Color = Color3.fromRGB(45, 180, 255)
        eye.Anchored = true
        local eyeMesh = Instance.new("SpecialMesh")
        eyeMesh.MeshType = Enum.MeshType.Sphere
        eyeMesh.Parent = eye
        eye.Parent = skullModel
    end

    local nose = Instance.new("Part")
    nose.Size = Vector3.new(0.24, 0.3, 0.22)
    nose.Position = Vector3.new(0, -0.1, 0.78)
    nose.Material = Enum.Material.SmoothPlastic
    nose.Color = Color3.fromRGB(25, 30, 42)
    nose.Anchored = true
    local noseMesh = Instance.new("SpecialMesh")
    noseMesh.MeshType = Enum.MeshType.Wedge
    noseMesh.Parent = nose
    nose.Parent = skullModel

    for i = -2, 2 do
        local tooth = Instance.new("Part")
        tooth.Size = Vector3.new(0.12, 0.23, 0.15)
        tooth.Position = Vector3.new(i * 0.15, -0.62, 0.67)
        tooth.Material = Enum.Material.SmoothPlastic
        tooth.Color = Color3.fromRGB(255, 255, 255)
        tooth.Anchored = true
        tooth.Parent = skullModel
    end

    skullModel.PrimaryPart = cranium
    return vp, skullModel
end

-- 3D Verified Blue Checkmark Badge (Medium-Proportional, Clearly Visible Behind Title)
local function Build3DBlueCheckmark(parent)
    local vp = Instance.new("ViewportFrame")
    vp.Name = "BlueBadge3D"
    vp.Size = UDim2.new(0, 30, 0, 30) -- Balanced medium size, clearly visible
    vp.BackgroundTransparency = 1
    vp.Ambient = Color3.fromRGB(190, 230, 255)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(1, -1, -1)
    vp.Parent = parent

    local wm = Instance.new("WorldModel")
    wm.Parent = vp

    local cam = Instance.new("Camera")
    cam.CFrame = CFrame.new(Vector3.new(0, 0, 2.85), Vector3.new(0, 0, 0))
    cam.Parent = vp
    vp.CurrentCamera = cam

    local badgeModel = Instance.new("Model")
    badgeModel.Parent = wm

    for i = 1, 3 do
        local disc = Instance.new("Part")
        disc.Size = Vector3.new(1.62, 1.62, 0.28)
        disc.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad((i - 1) * 30))
        disc.Material = Enum.Material.Neon
        disc.Color = Color3.fromRGB(28, 162, 255)
        disc.Anchored = true
        disc.Parent = badgeModel
        if i == 1 then
            badgeModel.PrimaryPart = disc
        end
    end

    local leg1 = Instance.new("Part")
    leg1.Size = Vector3.new(0.26, 0.58, 0.38)
    leg1.CFrame = CFrame.new(-0.22, -0.08, 0.05) * CFrame.Angles(0, 0, math.rad(42))
    leg1.Material = Enum.Material.SmoothPlastic
    leg1.Color = Color3.fromRGB(255, 255, 255)
    leg1.Anchored = true
    leg1.Parent = badgeModel

    local leg2 = Instance.new("Part")
    leg2.Size = Vector3.new(0.26, 1.0, 0.38)
    leg2.CFrame = CFrame.new(0.22, 0.08, 0.05) * CFrame.Angles(0, 0, math.rad(-42))
    leg2.Material = Enum.Material.SmoothPlastic
    leg2.Color = Color3.fromRGB(255, 255, 255)
    leg2.Anchored = true
    leg2.Parent = badgeModel

    return vp, badgeModel
end

--// FLOATING TOGGLE BUTTON (Balanced Medium Size 64x64 with 3D HD Skull)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "BimSakSin_FloatingToggle"
FloatingBtn.Size = UDim2.new(0, 64, 0, 64)
FloatingBtn.Position = UDim2.new(State.Floating_Pos.X, 0, State.Floating_Pos.Y, 0)
FloatingBtn.BackgroundTransparency = 0.80
FloatingBtn.Text = ""
FloatingBtn.AutoButtonColor = false
FloatingBtn.Parent = ScreenGui
RegisterThemePanel(FloatingBtn)

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 1.8
FloatStroke.Transparency = 0.3
FloatStroke.Parent = FloatingBtn
RegisterThemeStroke(FloatStroke)

local _, FloatingSkullModel = Build3DSkullViewport(
    FloatingBtn,
    UDim2.new(0, 52, 0, 52),
    UDim2.new(0.5, 0, 0.5, 0),
    Vector2.new(0.5, 0.5)
)

MakeDraggable(FloatingBtn, FloatingBtn, function(newPos)
    State.Floating_Pos = { X = newPos.X.Scale, Y = newPos.Y.Scale }
    SaveConfig()
end)

--// COMPACT MAIN PANEL (Matches Reference Image 2 Proportions + Bottom Resize Grip)
local MIN_WIDTH, MAX_WIDTH = 360, 680
local MIN_HEIGHT, MAX_HEIGHT = 240, 520

local MainPanel = Instance.new("Frame")
MainPanel.Name = "BimSakSin_MainPanel"
MainPanel.Size = UDim2.new(0, math.clamp(State.Panel_Width, MIN_WIDTH, MAX_WIDTH), 0, math.clamp(State.Panel_Height, MIN_HEIGHT, MAX_HEIGHT))
MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
MainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
MainPanel.BackgroundTransparency = 0.82
MainPanel.BorderSizePixel = 0
MainPanel.ClipsDescendants = false
MainPanel.Parent = ScreenGui
RegisterThemePanel(MainPanel)

local PanelScale = Instance.new("UIScale")
PanelScale.Scale = State.Panel_Open and 1 or 0.01
PanelScale.Parent = MainPanel
MainPanel.Visible = State.Panel_Open

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = MainPanel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Thickness = 1.6
PanelStroke.Transparency = 0.32
PanelStroke.Parent = MainPanel
RegisterThemeStroke(PanelStroke)

-- 4 Corner 3D HD Skull Badges (Balanced Medium Size 38x38)
local CornerSkullModels = {}
local cornerConfigs = {
    { pos = UDim2.new(0, 2, 0, 2), anchor = Vector2.new(0.5, 0.5), dir = 1 },
    { pos = UDim2.new(1, -2, 0, 2), anchor = Vector2.new(0.5, 0.5), dir = -1 },
    { pos = UDim2.new(0, 2, 1, -2), anchor = Vector2.new(0.5, 0.5), dir = -1 },
    { pos = UDim2.new(1, -2, 1, -2), anchor = Vector2.new(0.5, 0.5), dir = 1 },
}
for idx, cfg in ipairs(cornerConfigs) do
    local _, model = Build3DSkullViewport(
        MainPanel,
        UDim2.new(0, 38, 0, 38),
        cfg.pos,
        cfg.anchor
    )
    table.insert(CornerSkullModels, { Model = model, Dir = cfg.dir, Phase = idx * 0.8 })
end

--// COMPACT HEADER BAR (Like Reference Image 2: Left Skull Badge, Title + Blue Check, Region Line, Right (-) & (X))
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, -20, 0, 50)
Header.Position = UDim2.new(0, 10, 0, 8)
Header.BackgroundTransparency = 0.88
Header.Parent = MainPanel
RegisterThemePanel(Header)

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderStroke = Instance.new("UIStroke")
HeaderStroke.Thickness = 1
HeaderStroke.Transparency = 0.5
HeaderStroke.Parent = Header
RegisterThemeStroke(HeaderStroke)

MakeDraggable(Header, MainPanel)

-- Left Header Emblem Circle with 3D HD Skull
local HeaderEmblem = Instance.new("Frame")
HeaderEmblem.Size = UDim2.new(0, 36, 0, 36)
HeaderEmblem.Position = UDim2.new(0, 8, 0.5, 0)
HeaderEmblem.AnchorPoint = Vector2.new(0, 0.5)
HeaderEmblem.BackgroundTransparency = 0.80
HeaderEmblem.Parent = Header
RegisterThemePanel(HeaderEmblem)

local EmblemCorner = Instance.new("UICorner")
EmblemCorner.CornerRadius = UDim.new(1, 0)
EmblemCorner.Parent = HeaderEmblem

local EmblemStroke = Instance.new("UIStroke")
EmblemStroke.Thickness = 1.4
EmblemStroke.Transparency = 0.35
EmblemStroke.Parent = HeaderEmblem
RegisterThemeStroke(EmblemStroke)

local _, HeaderSkullModel = Build3DSkullViewport(
    HeaderEmblem,
    UDim2.new(0, 32, 0, 32),
    UDim2.new(0.5, 0, 0.5, 0),
    Vector2.new(0.5, 0.5)
)

-- Title + Spaced 3D Blue Checkmark Row
local TitleRow = Instance.new("Frame")
TitleRow.Size = UDim2.new(1, -135, 0, 26)
TitleRow.Position = UDim2.new(0, 50, 0, 4)
TitleRow.BackgroundTransparency = 1
TitleRow.Parent = Header

local TitleLayout = Instance.new("UIListLayout")
TitleLayout.FillDirection = Enum.FillDirection.Horizontal
TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TitleLayout.Padding = UDim.new(0, 5)
TitleLayout.Parent = TitleRow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "HubTitle"
TitleLabel.AutomaticSize = Enum.AutomaticSize.X
TitleLabel.Size = UDim2.new(0, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextSize = 16
TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TitleLabel.TextStrokeTransparency = 0.18
TitleLabel.Parent = TitleRow
RegisterThemeText(TitleLabel)

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(0, 0, 0)
TitleStroke.Thickness = 1.2
TitleStroke.Transparency = 0.25
TitleStroke.Parent = TitleLabel

local _, BlueCheckmarkModel = Build3DBlueCheckmark(TitleRow)

-- Subtitle Live Telemetry Line under Title (Region, IP Masked, Ping)
local HeaderSubtitle = Instance.new("TextLabel")
HeaderSubtitle.Size = UDim2.new(1, -135, 0, 16)
HeaderSubtitle.Position = UDim2.new(0, 50, 0, 30)
HeaderSubtitle.BackgroundTransparency = 1
HeaderSubtitle.Font = Enum.Font.GothamSemibold
HeaderSubtitle.Text = "🌐 Region: Mendeteksi... | Ping: --ms"
HeaderSubtitle.TextSize = 10
HeaderSubtitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderSubtitle.TextTruncate = Enum.TextTruncate.AtEnd
HeaderSubtitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
HeaderSubtitle.TextStrokeTransparency = 0.25
HeaderSubtitle.Parent = Header
RegisterThemeText(HeaderSubtitle)

-- Right Header Control Buttons: (-) Minimize & (X) Close + Full Feature Reset
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinimizeBtn"
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -72, 0.5, 0)
MinBtn.AnchorPoint = Vector2.new(0, 0.5)
MinBtn.BackgroundTransparency = 0.78
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.Text = "–"
MinBtn.TextSize = 16
MinBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextStrokeTransparency = 0.3
MinBtn.AutoButtonColor = false
MinBtn.Parent = Header
RegisterThemePanel(MinBtn)
RegisterThemeText(MinBtn)

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

local MinStroke = Instance.new("UIStroke")
MinStroke.Thickness = 1.2
MinStroke.Transparency = 0.35
MinStroke.Parent = MinBtn
RegisterThemeStroke(MinStroke)

local CloseResetBtn = Instance.new("TextButton")
CloseResetBtn.Name = "CloseResetBtn"
CloseResetBtn.Size = UDim2.new(0, 30, 0, 30)
CloseResetBtn.Position = UDim2.new(1, -36, 0.5, 0)
CloseResetBtn.AnchorPoint = Vector2.new(0, 0.5)
CloseResetBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 85)
CloseResetBtn.BackgroundTransparency = 0.35
CloseResetBtn.Font = Enum.Font.GothamBlack
CloseResetBtn.Text = "✕"
CloseResetBtn.TextSize = 13
CloseResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseResetBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
CloseResetBtn.TextStrokeTransparency = 0.25
CloseResetBtn.AutoButtonColor = false
CloseResetBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseResetBtn

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Color3.fromRGB(255, 160, 175)
CloseStroke.Thickness = 1.2
CloseStroke.Transparency = 0.25
CloseStroke.Parent = CloseResetBtn

-- Smooth Panel Open / Minimize Animation
local isAnimatingPanel = false
local function SetPanelOpen(openState)
    if isAnimatingPanel then return end
    isAnimatingPanel = true
    State.Panel_Open = openState
    SaveConfig()

    if openState then
        MainPanel.Visible = true
        PanelScale.Scale = 0.84
        MainPanel.BackgroundTransparency = 1
        TweenObj(PanelScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
        local t = TweenObj(MainPanel, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.82 })
        t.Completed:Wait()
    else
        TweenObj(PanelScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.84 })
        local t = TweenObj(MainPanel, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
        t.Completed:Wait()
        MainPanel.Visible = false
    end
    isAnimatingPanel = false
end

-- Full Feature Reset Function (Triggered by X Button)
local function ResetAllFeaturesAndClose()
    State.ESP_Enabled = false
    State.ESP_ShowDistance = false
    State.ESP_AvatarMarker = false
    State.Generator_ESP = false
    State.Fly_Enabled = false
    State.WalkSpeed_Enabled = false
    State.JumpPower_Enabled = false
    State.Noclip_Enabled = false
    State.AntiLag_Enabled = false

    if DisableFly then pcall(DisableFly) end
    if StopSpectating then pcall(StopSpectating) end
    if ApplyAntiLag then pcall(function() ApplyAntiLag(false) end) end

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end

    for _, espData in pairs(Hub.ESPObjects) do
        pcall(function()
            if espData.Billboard then espData.Billboard.Enabled = false end
            if espData.Highlight then espData.Highlight.Enabled = false end
        end)
    end
    for _, genData in pairs(Hub.GeneratorObjects) do
        pcall(function()
            if genData.Billboard then genData.Billboard.Enabled = false end
            if genData.Highlight then genData.Highlight.Enabled = false end
        end)
    end

    for _, refreshFn in ipairs(Hub.ToggleRefreshers) do
        pcall(refreshFn)
    end

    SaveConfig()
    SetPanelOpen(false)
end

Hub:AddConnection(FloatingBtn.MouseButton1Click:Connect(function()
    TweenObj(FloatingBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 56, 0, 56) })
    task.delay(0.1, function()
        if FloatingBtn and FloatingBtn.Parent then
            TweenObj(FloatingBtn, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 64, 0, 64) })
        end
    end)
    SetPanelOpen(not State.Panel_Open)
end))

Hub:AddConnection(MinBtn.MouseButton1Click:Connect(function()
    SetPanelOpen(false)
end))

Hub:AddConnection(CloseResetBtn.MouseButton1Click:Connect(function()
    ResetAllFeaturesAndClose()
end))

--// 3D LOGO ANIMATION LOOP
local animClock = 0
Hub:AddConnection(RunService.RenderStepped:Connect(function(dt)
    if not Hub.Alive then return end
    animClock = animClock + dt

    if BlueCheckmarkModel and BlueCheckmarkModel.PrimaryPart then
        local rotY = math.sin(animClock * 2.2) * math.rad(28)
        local bobY = math.sin(animClock * 3.0) * 0.08
        BlueCheckmarkModel:PivotTo(CFrame.new(0, bobY, 0) * CFrame.Angles(0, rotY, 0))
    end

    if FloatingSkullModel and FloatingSkullModel.PrimaryPart then
        FloatingSkullModel:PivotTo(CFrame.new(0, math.sin(animClock * 2.6) * 0.08, 0) * CFrame.Angles(0, animClock * 1.4, 0))
    end

    if HeaderSkullModel and HeaderSkullModel.PrimaryPart then
        HeaderSkullModel:PivotTo(CFrame.new(0, math.sin(animClock * 2.4) * 0.06, 0) * CFrame.Angles(0, -animClock * 1.3, 0))
    end

    for _, item in ipairs(CornerSkullModels) do
        if item.Model and item.Model.PrimaryPart then
            local rotY = (animClock * 1.3 * item.Dir) + item.Phase
            local bobY = math.sin(animClock * 2.5 + item.Phase) * 0.07
            item.Model:PivotTo(CFrame.new(0, bobY, 0) * CFrame.Angles(0, rotY, 0))
        end
    end
end))

--// HORIZONTAL TOP TAB BAR (Matches Reference Image 2 Compact Layout)
local TopTabBar = Instance.new("ScrollingFrame")
TopTabBar.Name = "TopTabBar"
TopTabBar.Size = UDim2.new(1, -20, 0, 32)
TopTabBar.Position = UDim2.new(0, 10, 0, 62)
TopTabBar.BackgroundTransparency = 1
TopTabBar.BorderSizePixel = 0
TopTabBar.ScrollBarThickness = 0
TopTabBar.ScrollingDirection = Enum.ScrollingDirection.X
TopTabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TopTabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TopTabBar.Parent = MainPanel

local TopTabLayout = Instance.new("UIListLayout")
TopTabLayout.FillDirection = Enum.FillDirection.Horizontal
TopTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TopTabLayout.Padding = UDim.new(0, 6)
TopTabLayout.Parent = TopTabBar

--// MAIN SCROLLABLE FEATURE CONTAINER
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -20, 1, -124)
ContentContainer.Position = UDim2.new(0, 10, 0, 98)
ContentContainer.BackgroundTransparency = 0.90
ContentContainer.Parent = MainPanel
RegisterThemePanel(ContentContainer)

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = ContentContainer

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Thickness = 1
ContentStroke.Transparency = 0.55
ContentStroke.Parent = ContentContainer
RegisterThemeStroke(ContentStroke)

--// BOTTOM RESIZE GRIP BAR (Hold & Drag Bottom Bar to Resize Panel Smoothly)
local BottomResizeBar = Instance.new("TextButton")
BottomResizeBar.Name = "BottomResizeBar"
BottomResizeBar.Size = UDim2.new(1, -20, 0, 18)
BottomResizeBar.Position = UDim2.new(0, 10, 1, -22)
BottomResizeBar.BackgroundTransparency = 0.86
BottomResizeBar.Text = "⋯  Tahan & Geser untuk Atur Ukuran Panel  ⋯"
BottomResizeBar.Font = Enum.Font.GothamBold
BottomResizeBar.TextSize = 9
BottomResizeBar.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
BottomResizeBar.TextStrokeTransparency = 0.35
BottomResizeBar.AutoButtonColor = false
BottomResizeBar.Parent = MainPanel
RegisterThemePanel(BottomResizeBar)
RegisterThemeText(BottomResizeBar)

local ResizeCorner = Instance.new("UICorner")
ResizeCorner.CornerRadius = UDim.new(0, 7)
ResizeCorner.Parent = BottomResizeBar

local ResizeStroke = Instance.new("UIStroke")
ResizeStroke.Thickness = 1
ResizeStroke.Transparency = 0.5
ResizeStroke.Parent = BottomResizeBar
RegisterThemeStroke(ResizeStroke)

do
    local resizing = false
    local resizeStartPos, startSize

    Hub:AddConnection(BottomResizeBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStartPos = input.Position
            startSize = Vector2.new(MainPanel.AbsoluteSize.X, MainPanel.AbsoluteSize.Y)

            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    if endConn then endConn:Disconnect() end
                    State.Panel_Width = MainPanel.AbsoluteSize.X
                    State.Panel_Height = MainPanel.AbsoluteSize.Y
                    SaveConfig()
                end
            end)
        end
    end))

    Hub:AddConnection(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartPos
            -- Because AnchorPoint is (0.5, 0.5), doubling delta keeps center smooth while expanding symmetrically
            local newW = math.clamp(startSize.X + delta.X * 1.4, MIN_WIDTH, MAX_WIDTH)
            local newH = math.clamp(startSize.Y + delta.Y * 1.6, MIN_HEIGHT, MAX_HEIGHT)
            MainPanel.Size = UDim2.new(0, math.floor(newW), 0, math.floor(newH))
        end
    end))
end

--// TAB & COMPONENT FACTORY (High-Contrast Styled Typography)
local Tabs = {}
local ActiveTabName = nil

local function CreateTab(tabName)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "_TabBtn"
    tabBtn.AutomaticSize = Enum.AutomaticSize.X
    tabBtn.Size = UDim2.new(0, 82, 0, 28)
    tabBtn.BackgroundTransparency = 0.90
    tabBtn.Font = Enum.Font.GothamBlack
    tabBtn.Text = "  " .. tabName .. "  "
    tabBtn.TextSize = 11
    tabBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tabBtn.TextStrokeTransparency = 0.15
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = TopTabBar
    RegisterThemePanel(tabBtn)
    RegisterThemeText(tabBtn)

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = tabBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1.2
    btnStroke.Transparency = 0.55
    btnStroke.Parent = tabBtn
    RegisterThemeStroke(btnStroke)

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingBottom = UDim.new(0, 6)
    pagePad.Parent = page

    Tabs[tabName] = { Button = tabBtn, Stroke = btnStroke, Page = page }

    Hub:AddConnection(tabBtn.MouseButton1Click:Connect(function()
        for name, data in pairs(Tabs) do
            local isTarget = (name == tabName)
            data.Page.Visible = isTarget
            TweenObj(data.Button, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                BackgroundTransparency = isTarget and 0.66 or 0.90
            })
            TweenObj(data.Stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                Transparency = isTarget and 0.10 or 0.55
            })
        end
        ActiveTabName = tabName
    end))

    if not ActiveTabName then
        ActiveTabName = tabName
        page.Visible = true
        tabBtn.BackgroundTransparency = 0.66
        btnStroke.Transparency = 0.10
    end

    return page
end

-- Styled Rich Text Helper for Feature Cards (Crisp, Bold, High-Contrast Outline, Never Plain)
local function StyleFeatureLabel(lbl, size, isBold)
    lbl.Font = isBold and Enum.Font.GothamBlack or Enum.Font.GothamBold
    lbl.TextSize = size
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.12
    RegisterThemeText(lbl)

    local txtStroke = Instance.new("UIStroke")
    txtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    txtStroke.Color = Color3.fromRGB(0, 0, 0)
    txtStroke.Thickness = 1.15
    txtStroke.Transparency = 0.25
    txtStroke.Parent = lbl
end

local function AddSectionHeader(parent, titleText, descText)
    local card = Instance.new("Frame")
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -4, 0, 32)
    card.BackgroundTransparency = 0.85
    card.Parent = parent
    RegisterThemePanel(card)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = card

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Transparency = 0.55
    s.Parent = card
    RegisterThemeStroke(s)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 5)
    pad.PaddingLeft = UDim.new(0, 9)
    pad.PaddingRight = UDim.new(0, 9)
    pad.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    StyleFeatureLabel(title, 12, true)

    if descText then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, 0, 0, 14)
        desc.Position = UDim2.new(0, 0, 0, 16)
        desc.BackgroundTransparency = 1
        desc.Text = descText
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = card
        StyleFeatureLabel(desc, 10, false)
    end
end

local function AddToggle(parent, titleText, subtitleText, stateKey, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -4, 0, 42)
    row.BackgroundTransparency = 0.86
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = parent
    RegisterThemePanel(row)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = row

    local s = Instance.new("UIStroke")
    s.Thickness = 1.1
    s.Transparency = 0.48
    s.Parent = row
    RegisterThemeStroke(s)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -58, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    StyleFeatureLabel(lbl, 12, true)

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -58, 0, 14)
    sub.Position = UDim2.new(0, 10, 0, 22)
    sub.BackgroundTransparency = 1
    sub.Text = subtitleText
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = row
    StyleFeatureLabel(sub, 10, false)

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -48, 0.5, 0)
    pill.AnchorPoint = Vector2.new(0, 0.5)
    pill.BackgroundColor3 = State[stateKey] and GetCurrentTheme().AccentColor or GetCurrentTheme().PanelColor
    pill.BackgroundTransparency = State[stateKey] and 0.15 or 0.72
    pill.Parent = row

    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(1, 0)
    pc.Parent = pill

    local pStroke = Instance.new("UIStroke")
    pStroke.Thickness = 1
    pStroke.Transparency = 0.35
    pStroke.Parent = pill
    RegisterThemeStroke(pStroke)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = State[stateKey] and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = pill

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local function RefreshVisual()
        local on = State[stateKey]
        local th = GetCurrentTheme()
        TweenObj(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            BackgroundColor3 = on and th.AccentColor or th.PanelColor,
            BackgroundTransparency = on and 0.15 or 0.72
        })
        TweenObj(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        })
    end

    table.insert(Hub.ToggleRefreshers, RefreshVisual)

    Hub:AddConnection(row.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        RefreshVisual()
        SaveConfig()
        if callback then
            task.spawn(callback, State[stateKey])
        end
    end))

    return RefreshVisual
end

local function AddSlider(parent, titleText, minVal, maxVal, stateKey, callback)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -4, 0, 44)
    box.BackgroundTransparency = 0.86
    box.Parent = parent
    RegisterThemePanel(box)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = box

    local s = Instance.new("UIStroke")
    s.Thickness = 1.1
    s.Transparency = 0.48
    s.Parent = box
    RegisterThemeStroke(s)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = box
    StyleFeatureLabel(lbl, 11, true)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.28, -10, 0, 16)
    valLbl.Position = UDim2.new(0.72, 0, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(State[stateKey])
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = box
    StyleFeatureLabel(valLbl, 12, true)

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 27)
    track.BackgroundTransparency = 0.72
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = box
    RegisterThemePanel(track)

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track

    local fill = Instance.new("Frame")
    local initRatio = math.clamp((State[stateKey] - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(initRatio, 0, 1, 0)
    fill.BackgroundTransparency = 0.1
    fill.Parent = track
    RegisterThemeAccent(fill)

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill

    local sliding = false
    local function UpdateFromInput(inputPos)
        local ratio = math.clamp((inputPos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local value = math.floor(minVal + (maxVal - minVal) * ratio + 0.5)
        State[stateKey] = value
        valLbl.Text = tostring(value)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        if callback then callback(value) end
    end

    Hub:AddConnection(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            UpdateFromInput(input.Position)
        end
    end))

    Hub:AddConnection(UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromInput(input.Position)
        end
    end))

    Hub:AddConnection(UserInputService.InputEnded:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
            SaveConfig()
        end
    end))
end

local function AddActionButton(parent, btnText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 34)
    btn.BackgroundTransparency = 0.80
    btn.Text = btnText
    btn.AutoButtonColor = false
    btn.Parent = parent
    RegisterThemePanel(btn)
    StyleFeatureLabel(btn, 11, true)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Thickness = 1.2
    s.Transparency = 0.4
    s.Parent = btn
    RegisterThemeStroke(s)

    Hub:AddConnection(btn.MouseButton1Click:Connect(function()
        TweenObj(btn, TweenInfo.new(0.08), { BackgroundTransparency = 0.60 })
        task.delay(0.1, function()
            if btn and btn.Parent then
                TweenObj(btn, TweenInfo.new(0.14), { BackgroundTransparency = 0.80 })
            end
        end)
        if callback then callback() end
    end))

    return btn
end

--// BUILD COMPACT TOP TABS (Matching Reference Image 2 Navigation Style)
local TabESP = CreateTab("ESP")
local TabGenerator = CreateTab("Generator")
local TabMove = CreateTab("Movement")
local TabTeleport = CreateTab("Teleport")
local TabTheme = CreateTab("Warna & Opt")

--=============================================================================
-- 5. FEATURE CONTROLLER A: REFINED PROPORTIONAL CHARACTER ESP
--=============================================================================
AddSectionHeader(TabESP, "Player ESP & Avatar Marker", "Ukuran font proporsional di atas kepala dengan outline hitam presisi.")
AddToggle(TabESP, "Aktifkan Player ESP", "Nama, status Team/Teman/Musuh, dan jarak", "ESP_Enabled")
AddToggle(TabESP, "Tampilkan Jarak & HP", "Info jarak meter & HP ringkas di bawah nama", "ESP_ShowDistance")
AddToggle(TabESP, "Tanda Avatar ESP (Highlight & Pin)", "Outline tubuh avatar & pin kecil di atas kepala", "ESP_AvatarMarker")
AddToggle(TabESP, "Deteksi Team & Teman", "Teman (Cyan), Team (Hijau), Musuh (Merah)", "ESP_TeamCheck")

local function RemovePlayerESP(player)
    local data = Hub.ESPObjects[player]
    if data then
        pcall(function()
            if data.Billboard then data.Billboard:Destroy() end
            if data.Highlight then data.Highlight:Destroy() end
        end)
        Hub.ESPObjects[player] = nil
    end
end

local function EnsurePlayerESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then
        RemovePlayerESP(player)
        return
    end

    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not hum or hum.Health <= 0 then
        RemovePlayerESP(player)
        return
    end

    local data = Hub.ESPObjects[player]
    if not data or not data.Billboard or not data.Billboard.Parent or data.Billboard.Adornee ~= head then
        RemovePlayerESP(player)

        local bb = Instance.new("BillboardGui")
        bb.Name = "BimSakSin_ESP_" .. player.Name
        bb.Adornee = head
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 170, 0, 44) -- Compact, non-overlapping billboard bounds
        bb.StudsOffset = Vector3.new(0, 2.05, 0) -- Positioned cleanly right above avatar head
        bb.ResetOnSpawn = false
        bb.Parent = ScreenGui

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Padding = UDim.new(0, 0)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = bb

        -- Compact Diamond Marker Pin above head
        local markerLbl = CreateTightStyledText(bb, "MarkerLabel", 1, 10)
        markerLbl.Text = "◆"

        -- Proportional Crisp Name Label (11pt GothamBold with tight black stroke)
        local nameLbl = CreateTightStyledText(bb, "NameLabel", 2, 11)

        -- Proportional Compact Distance + HP Label (10pt)
        local distLbl = CreateTightStyledText(bb, "DistLabel", 3, 10)

        -- Clean Avatar Highlight Outline
        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSin_AvatarHL"
        hl.Adornee = char
        hl.FillTransparency = 0.82
        hl.OutlineTransparency = 0.12
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = ScreenGui

        data = {
            Billboard = bb,
            MarkerLabel = markerLbl,
            NameLabel = nameLbl,
            DistLabel = distLbl,
            Highlight = hl,
        }
        Hub.ESPObjects[player] = data
    end

    data.Billboard.Enabled = State.ESP_Enabled
    data.Highlight.Enabled = State.ESP_Enabled and State.ESP_AvatarMarker
    data.MarkerLabel.Visible = State.ESP_AvatarMarker

    if not State.ESP_Enabled then return end

    local relationTag, relationColor = GetPlayerRelation(player)
    data.MarkerLabel.TextColor3 = relationColor
    data.Highlight.FillColor = relationColor
    data.Highlight.OutlineColor = relationColor

    -- Clean concise display name (avoids ultra-long screen clutter)
    local shortName = player.DisplayName
    if #shortName > 16 then
        shortName = string.sub(shortName, 1, 15) .. "…"
    end

    data.NameLabel.TextColor3 = relationColor
    data.NameLabel.Text = string.format("[%s] %s", relationTag, shortName)

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = char:FindFirstChild("HumanoidRootPart") or head
    local dist = (myRoot and targetRoot) and math.floor((myRoot.Position - targetRoot.Position).Magnitude) or 0
    local hp = math.floor(hum.Health)

    data.DistLabel.Visible = State.ESP_ShowDistance
    data.DistLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
    data.DistLabel.Text = string.format("%dm • %d HP", dist, hp)
end

--=============================================================================
-- 6. FEATURE CONTROLLER B: DEEP INTERACTIVE GENERATOR ESP + LIVE TELEPORT
--=============================================================================
AddSectionHeader(TabGenerator, "Generator Telemetry & Live Progress", "Deteksi otomatis semua generator, jarak, % selesai & belum, + TP.")
AddToggle(TabGenerator, "Aktifkan Generator ESP", "Tampilkan pin, outline, jarak & persentase setiap generator", "Generator_ESP")

local GeneratorSummaryLabel = Instance.new("TextLabel")
GeneratorSummaryLabel.Size = UDim2.new(1, -4, 0, 26)
GeneratorSummaryLabel.BackgroundTransparency = 0.86
GeneratorSummaryLabel.Text = "  ⚡ Memindai generator di map..."
GeneratorSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
GeneratorSummaryLabel.Parent = TabGenerator
RegisterThemePanel(GeneratorSummaryLabel)
StyleFeatureLabel(GeneratorSummaryLabel, 11, true)
local gslc = Instance.new("UICorner")
gslc.CornerRadius = UDim.new(0, 8)
gslc.Parent = GeneratorSummaryLabel

-- Container for interactive per-generator cards inside the Generator Tab
local GeneratorCardsContainer = Instance.new("Frame")
GeneratorCardsContainer.AutomaticSize = Enum.AutomaticSize.Y
GeneratorCardsContainer.Size = UDim2.new(1, -4, 0, 20)
GeneratorCardsContainer.BackgroundTransparency = 1
GeneratorCardsContainer.Parent = TabGenerator

local GenCardsLayout = Instance.new("UIListLayout")
GenCardsLayout.Padding = UDim.new(0, 5)
GenCardsLayout.Parent = GeneratorCardsContainer

-- Deep Multi-Method Generator Progress Reader (Attributes, Values, TextLabels, BillboardGuis, ProximityPrompts)
local function ReadGeneratorProgress(genObj)
    local bestPct = nil

    -- Method 1: Check Model/Part Attributes
    for attrName, attrVal in pairs(genObj:GetAttributes()) do
        local lname = string.lower(attrName)
        if type(attrVal) == "number" and (
            string.find(lname, "prog") or
            string.find(lname, "perc") or
            string.find(lname, "rep") or
            string.find(lname, "charg") or
            string.find(lname, "work") or
            string.find(lname, "fix") or
            string.find(lname, "comp")
        ) then
            local maxVal = genObj:GetAttribute("Max" .. attrName)
                or genObj:GetAttribute("MaxProgress")
                or genObj:GetAttribute("MaxCharge")
                or (attrVal <= 1.01 and attrVal > 0 and 1 or 100)
            local pct = math.clamp((attrVal / math.max(maxVal, 0.001)) * 100, 0, 100)
            bestPct = math.max(bestPct or 0, math.floor(pct + 0.5))
        elseif type(attrVal) == "boolean" and attrVal == true and (
            string.find(lname, "done") or
            string.find(lname, "comp") or
            string.find(lname, "fix") or
            string.find(lname, "rep")
        ) then
            bestPct = 100
        end
    end

    -- Method 2: Check Descendant ValueObjects, TextLabels (e.g. "45%"), and ProximityPrompts
    for _, desc in ipairs(genObj:GetDescendants()) do
        local lname = string.lower(desc.Name)
        if desc:IsA("BoolValue") and desc.Value == true and (
            string.find(lname, "done") or string.find(lname, "comp") or string.find(lname, "fix") or string.find(lname, "rep")
        ) then
            bestPct = 100
        elseif (desc:IsA("NumberValue") or desc:IsA("IntValue")) and (
            string.find(lname, "prog") or string.find(lname, "perc") or string.find(lname, "rep") or
            string.find(lname, "charg") or string.find(lname, "work") or string.find(lname, "fix")
        ) then
            local val = desc.Value
            local parentMax = desc.Parent and (desc.Parent:FindFirstChild("MaxProgress") or desc.Parent:FindFirstChild("MaxCharge") or desc.Parent:FindFirstChild("Max"))
            local maxVal = (parentMax and parentMax.Value) or (val <= 1.01 and val > 0 and 1 or 100)
            local pct = math.clamp((val / math.max(maxVal, 0.001)) * 100, 0, 100)
            bestPct = math.max(bestPct or 0, math.floor(pct + 0.5))
        elseif desc:IsA("TextLabel") and desc.Text then
            local numStr = string.match(desc.Text, "(%d+)%s*%%")
            if numStr then
                local parsed = tonumber(numStr)
                if parsed then
                    bestPct = math.max(bestPct or 0, math.clamp(parsed, 0, 100))
                end
            end
        end
    end

    return bestPct or 0
end

-- Smart Generator Detector (Finds Model/Part generators across survival/escape/horror maps)
local function IsGeneratorInstance(inst)
    if not (inst:IsA("Model") or inst:IsA("BasePart")) then return false end
    -- Skip player characters
    if Players:GetPlayerFromCharacter(inst) then return false end
    local ancestorModel = inst:FindFirstAncestorOfClass("Model")
    if ancestorModel and Players:GetPlayerFromCharacter(ancestorModel) then return false end

    local lname = string.lower(inst.Name)
    local isMatch = string.find(lname, "generator")
        or string.find(lname, "gen_")
        or string.find(lname, "_gen")
        or lname == "gen"
        or string.match(lname, "^gen%d+$") ~= nil

    if not isMatch then
        -- Also detect models containing a ProximityPrompt with "Repair" / "Perbaiki" / "Generator"
        if inst:IsA("Model") then
            for _, child in ipairs(inst:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    local act = string.lower((child.ActionText or "") .. " " .. (child.ObjectText or ""))
                    if string.find(act, "generator") or string.find(act, "repair") or string.find(act, "perbaik") then
                        isMatch = true
                        break
                    end
                end
            end
        end
    end

    if not isMatch then return false end

    -- Prevent duplicate tracking of child parts inside an already matched Generator Model
    local parent = inst.Parent
    while parent and parent ~= Workspace do
        local pname = string.lower(parent.Name)
        if parent:IsA("Model") and (string.find(pname, "generator") or string.find(pname, "gen_") or pname == "gen" or string.match(pname, "^gen%d+$")) then
            return false
        end
        parent = parent.Parent
    end

    return true
end

local function ScanGenerators()
    for obj, data in pairs(Hub.GeneratorObjects) do
        if not obj or not obj.Parent then
            pcall(function()
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
                if data.Card then data.Card:Destroy() end
            end)
            Hub.GeneratorObjects[obj] = nil
        end
    end

    local index = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if IsGeneratorInstance(inst) then
            index = index + 1
            if not Hub.GeneratorObjects[inst] then
                local adornee = inst:IsA("BasePart") and inst or (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true))
                if adornee then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "BimSakSin_GenESP"
                    bb.Adornee = adornee
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 190, 0, 42)
                    bb.StudsOffset = Vector3.new(0, 2.8, 0)
                    bb.Parent = ScreenGui

                    local layout = Instance.new("UIListLayout")
                    layout.FillDirection = Enum.FillDirection.Vertical
                    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    layout.VerticalAlignment = Enum.VerticalAlignment.Center
                    layout.Padding = UDim.new(0, 0)
                    layout.Parent = bb

                    local titleLbl = CreateTightStyledText(bb, "GenTitle", 1, 11)
                    local progLbl = CreateTightStyledText(bb, "GenProg", 2, 10)

                    local hl = Instance.new("Highlight")
                    hl.Adornee = inst
                    hl.FillTransparency = 0.78
                    hl.OutlineTransparency = 0.08
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = ScreenGui

                    -- Interactive Card in Generator Tab with One-Click Teleport
                    local card = Instance.new("TextButton")
                    card.Size = UDim2.new(1, 0, 0, 32)
                    card.BackgroundTransparency = 0.86
                    card.Text = "  ⚡ Generator #" .. index .. " • Memuat..."
                    card.TextXAlignment = Enum.TextXAlignment.Left
                    card.AutoButtonColor = false
                    card.Parent = GeneratorCardsContainer
                    RegisterThemePanel(card)
                    StyleFeatureLabel(card, 11, true)

                    local cc = Instance.new("UICorner")
                    cc.CornerRadius = UDim.new(0, 8)
                    cc.Parent = card

                    local cs = Instance.new("UIStroke")
                    cs.Thickness = 1
                    cs.Transparency = 0.5
                    cs.Parent = card
                    RegisterThemeStroke(cs)

                    Hub:AddConnection(card.MouseButton1Click:Connect(function()
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot and adornee and adornee.Parent then
                            myRoot.CFrame = adornee.CFrame * CFrame.new(0, 3, 4)
                        end
                    end))

                    Hub.GeneratorObjects[inst] = {
                        Index = index,
                        Adornee = adornee,
                        Billboard = bb,
                        TitleLabel = titleLbl,
                        ProgLabel = progLbl,
                        Highlight = hl,
                        Card = card,
                    }
                end
            end
        end
    end

    GeneratorSummaryLabel.Text = string.format("  ⚡ Terdeteksi: %d Generator (Klik kartu untuk TP)", index)
end

local function UpdateGeneratorVisuals()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local idx = 0
    for genObj, data in pairs(Hub.GeneratorObjects) do
        if genObj and genObj.Parent and data.Adornee then
            idx = idx + 1
            data.Billboard.Enabled = State.Generator_ESP
            data.Highlight.Enabled = State.Generator_ESP

            local donePct = ReadGeneratorProgress(genObj)
            local remPct = math.max(0, 100 - donePct)
            local dist = myRoot and math.floor((myRoot.Position - data.Adornee.Position).Magnitude) or 0

            local statusColor = donePct >= 100
                and Color3.fromRGB(85, 255, 145)
                or (donePct > 0 and Color3.fromRGB(255, 215, 70) or Color3.fromRGB(70, 210, 255))

            if State.Generator_ESP then
                data.Highlight.FillColor = statusColor
                data.Highlight.OutlineColor = statusColor
                data.TitleLabel.TextColor3 = statusColor
                data.TitleLabel.Text = string.format("⚡ GEN #%d [%dm]", idx, dist)

                data.ProgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.ProgLabel.Text = string.format("Selesai: %d%% | Belum: %d%%", donePct, remPct)
            end

            if data.Card and data.Card.Parent then
                data.Card.Text = string.format("  ⚡ Gen #%d (%dm) • %d%% Selesai / %d%% Sisa  [TP]", idx, dist, donePct, remPct)
            end
        end
    end
end

AddActionButton(TabGenerator, "🔄 Pindai Ulang Semua Generator", function()
    ScanGenerators()
    UpdateGeneratorVisuals()
end)

--=============================================================================
-- 7. FEATURE CONTROLLER C: MOVEMENT (FLY, WALKSPEED, JUMP, NOCLIP)
--=============================================================================
AddSectionHeader(TabMove, "Character Movement & Physics", "Kontrol terbang 3D, kecepatan lari, lompatan, dan noclip.")

local flyBodyGyro, flyBodyVel

DisableFly = function()
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
    if flyBodyVel then pcall(function() flyBodyVel:Destroy() end) flyBodyVel = nil end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function EnableFly()
    DisableFly()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVel.Parent = root
end

AddToggle(TabMove, "Fly Mode (3D Directional)", "Terbang bebas mengikuti arah kamera", "Fly_Enabled", function(on)
    if on then EnableFly() else DisableFly() end
end)
AddSlider(TabMove, "Kecepatan Fly", 16, 250, "Fly_Speed")

AddToggle(TabMove, "WalkHack / Custom Speed", "Atur kecepatan lari karakter secara stabil", "WalkSpeed_Enabled", function(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and not on then hum.WalkSpeed = 16 end
end)
AddSlider(TabMove, "Nilai WalkSpeed", 16, 200, "WalkSpeed_Value")

AddToggle(TabMove, "Super Jump", "Meningkatkan daya lompat karakter", "JumpPower_Enabled", function(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and not on then
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end
end)
AddSlider(TabMove, "Nilai JumpPower", 50, 300, "JumpPower_Value")

AddToggle(TabMove, "Noclip (Tembus Dinding)", "Nonaktifkan kolisi tubuh karakter", "Noclip_Enabled", function(on)
    if not on and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end)

Hub:AddConnection(RunService.Stepped:Connect(function()
    if not Hub.Alive then return end
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if hum then
        if State.WalkSpeed_Enabled then
            hum.WalkSpeed = State.WalkSpeed_Value
        end
        if State.JumpPower_Enabled then
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower_Value
        end
    end

    if State.Noclip_Enabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if State.Fly_Enabled and root and hum then
        if not flyBodyGyro or not flyBodyVel or flyBodyGyro.Parent ~= root then
            EnableFly()
        end
        if flyBodyGyro and flyBodyVel then
            local camCF = Workspace.CurrentCamera.CFrame
            local moveDir = hum.MoveDirection
            local forward = camCF.LookVector
            local right = camCF.RightVector

            local flatLook = Vector3.new(forward.X, 0, forward.Z)
            local flatRight = Vector3.new(right.X, 0, right.Z)
            if flatLook.Magnitude > 0.01 then flatLook = flatLook.Unit end
            if flatRight.Magnitude > 0.01 then flatRight = flatRight.Unit end

            local forwardAmt = moveDir:Dot(flatLook)
            local rightAmt = moveDir:Dot(flatRight)

            local velocity = (forward * forwardAmt + right * rightAmt) * State.Fly_Speed
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, State.Fly_Speed * 0.7, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                velocity = velocity - Vector3.new(0, State.Fly_Speed * 0.7, 0)
            end

            flyBodyGyro.CFrame = camCF
            flyBodyVel.Velocity = velocity
        end
    end
end))

--=============================================================================
-- 8. FEATURE CONTROLLER D: PROFESSIONAL INTERACTIVE TELEPORT & VIEW (SPECTATE)
--=============================================================================
AddSectionHeader(TabTeleport, "Interactive Teleport & View Pemain", "TP cepat ke musuh/pemain terdekat, atau pilih pemain untuk TP & View.")

local function TeleportToCharacter(targetChar)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 3)
        return true
    end
    return false
end

local function GetNearestPlayer(onlyEnemy)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, math.huge end

    local bestPlr, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local rel = GetPlayerRelation(plr)
                if not onlyEnemy or rel == "MUSUH" then
                    local d = (myRoot.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPlr = plr
                    end
                end
            end
        end
    end
    return bestPlr, bestDist
end

-- Quick Action Row: TP Musuh Terdekat & TP Player Terdekat (Matches Reference Image 2)
AddActionButton(TabTeleport, "⚔️ TP → Musuh Terdekat", function()
    local enemy = GetNearestPlayer(true)
    if enemy and enemy.Character then
        TeleportToCharacter(enemy.Character)
    end
end)

AddActionButton(TabTeleport, "🎯 TP → Player Terdekat (Semua)", function()
    local nearest = GetNearestPlayer(false)
    if nearest and nearest.Character then
        TeleportToCharacter(nearest.Character)
    end
end)

local ActiveViewBanner = Instance.new("TextButton")
ActiveViewBanner.Size = UDim2.new(1, -4, 0, 32)
ActiveViewBanner.BackgroundColor3 = Color3.fromRGB(35, 155, 255)
ActiveViewBanner.BackgroundTransparency = 0.30
ActiveViewBanner.Text = "👁️ Stop View (Kembali ke Karakter Sendiri)"
ActiveViewBanner.Visible = false
ActiveViewBanner.AutoButtonColor = false
ActiveViewBanner.Parent = TabTeleport
StyleFeatureLabel(ActiveViewBanner, 11, true)
local avc = Instance.new("UICorner")
avc.CornerRadius = UDim.new(0, 8)
avc.Parent = ActiveViewBanner

StopSpectating = function()
    Hub.ViewingTarget = false
    Hub.SelectedTarget = nil
    ActiveViewBanner.Visible = false
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if myHum then
        Workspace.CurrentCamera.CameraSubject = myHum
    end
end

Hub:AddConnection(ActiveViewBanner.MouseButton1Click:Connect(function()
    StopSpectating()
end))

-- Interactive Per-Player Cards with Dedicated [TP] and [VIEW] Action Buttons
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.AutomaticSize = Enum.AutomaticSize.Y
PlayerListFrame.Size = UDim2.new(1, -4, 0, 30)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.Parent = TabTeleport

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.Parent = PlayerListFrame

local PlayerCardRefs = {}

local function RebuildPlayerSelector()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    table.clear(PlayerCardRefs)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local rel, col = GetPlayerRelation(plr)

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 38)
            card.BackgroundTransparency = 0.86
            card.Parent = PlayerListFrame
            RegisterThemePanel(card)

            local cc = Instance.new("UICorner")
            cc.CornerRadius = UDim.new(0, 9)
            cc.Parent = card

            local cs = Instance.new("UIStroke")
            cs.Thickness = 1.1
            cs.Transparency = 0.48
            cs.Parent = card
            RegisterThemeStroke(cs)

            local infoLbl = Instance.new("TextLabel")
            infoLbl.Size = UDim2.new(1, -118, 1, 0)
            infoLbl.Position = UDim2.new(0, 9, 0, 0)
            infoLbl.BackgroundTransparency = 1
            infoLbl.Font = Enum.Font.GothamBold
            infoLbl.TextSize = 11
            infoLbl.TextXAlignment = Enum.TextXAlignment.Left
            infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
            infoLbl.TextColor3 = col
            infoLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            infoLbl.TextStrokeTransparency = 0.12
            infoLbl.Text = string.format("[%s] %s", rel, plr.DisplayName)
            infoLbl.Parent = card

            local infoStroke = Instance.new("UIStroke")
            infoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            infoStroke.Color = Color3.fromRGB(0, 0, 0)
            infoStroke.Thickness = 1.1
            infoStroke.Parent = infoLbl

            -- Dedicated TP Button
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 48, 0, 26)
            tpBtn.Position = UDim2.new(1, -106, 0.5, 0)
            tpBtn.AnchorPoint = Vector2.new(0, 0.5)
            tpBtn.BackgroundTransparency = 0.25
            tpBtn.Text = "⚡ TP"
            tpBtn.AutoButtonColor = false
            tpBtn.Parent = card
            RegisterThemeAccent(tpBtn)
            StyleFeatureLabel(tpBtn, 10, true)

            local tpc = Instance.new("UICorner")
            tpc.CornerRadius = UDim.new(0, 7)
            tpc.Parent = tpBtn

            -- Dedicated VIEW (Spectate) Toggle Button
            local viewBtn = Instance.new("TextButton")
            viewBtn.Size = UDim2.new(0, 50, 0, 26)
            viewBtn.Position = UDim2.new(1, -54, 0.5, 0)
            viewBtn.AnchorPoint = Vector2.new(0, 0.5)
            viewBtn.BackgroundTransparency = 0.72
            viewBtn.Text = (Hub.ViewingTarget and Hub.SelectedTarget == plr) and "👁️ ON" or "👁️ VIEW"
            viewBtn.AutoButtonColor = false
            viewBtn.Parent = card
            RegisterThemePanel(viewBtn)
            StyleFeatureLabel(viewBtn, 10, true)

            local vc = Instance.new("UICorner")
            vc.CornerRadius = UDim.new(0, 7)
            vc.Parent = viewBtn

            local vStroke = Instance.new("UIStroke")
            vStroke.Thickness = 1
            vStroke.Transparency = 0.35
            vStroke.Parent = viewBtn
            RegisterThemeStroke(vStroke)

            Hub:AddConnection(tpBtn.MouseButton1Click:Connect(function()
                if plr.Character then
                    TeleportToCharacter(plr.Character)
                end
            end))

            Hub:AddConnection(viewBtn.MouseButton1Click:Connect(function()
                if Hub.ViewingTarget and Hub.SelectedTarget == plr then
                    StopSpectating()
                else
                    if plr.Character then
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            Hub.SelectedTarget = plr
                            Hub.ViewingTarget = true
                            Workspace.CurrentCamera.CameraSubject = hum
                            ActiveViewBanner.Text = "👁️ Viewing: " .. plr.DisplayName .. " (Ketuk untuk Stop)"
                            ActiveViewBanner.Visible = true
                        end
                    end
                end
                RebuildPlayerSelector()
            end))

            PlayerCardRefs[plr] = { InfoLabel = infoLbl, ViewBtn = viewBtn }
        end
    end
end

--=============================================================================
-- 9. FEATURE CONTROLLER E: LIVE PANEL & FONT COLOR CUSTOMIZER + REGION/ANTI-LAG
--=============================================================================
AddSectionHeader(TabTheme, "Kustomisasi Warna Panel & Font", "Ubah tema kaca panel serta warna teks seluruh fitur secara langsung.")

-- Theme Preset Grid (2 Columns)
local ThemeGridFrame = Instance.new("Frame")
ThemeGridFrame.AutomaticSize = Enum.AutomaticSize.Y
ThemeGridFrame.Size = UDim2.new(1, -4, 0, 60)
ThemeGridFrame.BackgroundTransparency = 1
ThemeGridFrame.Parent = TabTheme

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0.485, 0, 0, 32)
GridLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)
GridLayout.Parent = ThemeGridFrame

for idx, preset in ipairs(ThemePresets) do
    local pBtn = Instance.new("TextButton")
    pBtn.BackgroundColor3 = Color3.fromRGB(preset.Panel[1], preset.Panel[2], preset.Panel[3])
    pBtn.BackgroundTransparency = 0.45
    pBtn.Font = Enum.Font.GothamBlack
    pBtn.Text = "🎨 " .. preset.Name
    pBtn.TextSize = 11
    pBtn.TextColor3 = Color3.fromRGB(preset.Font[1], preset.Font[2], preset.Font[3])
    pBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pBtn.TextStrokeTransparency = 0.15
    pBtn.AutoButtonColor = false
    pBtn.Parent = ThemeGridFrame

    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(0, 8)
    pc.Parent = pBtn

    local ps = Instance.new("UIStroke")
    ps.Color = Color3.fromRGB(preset.Accent[1], preset.Accent[2], preset.Accent[3])
    ps.Thickness = 1.4
    ps.Parent = pBtn

    Hub:AddConnection(pBtn.MouseButton1Click:Connect(function()
        State.Theme_Index = idx
        ApplyThemeToAllUI()
        SaveConfig()
    end))
end

AddSectionHeader(TabTheme, "Anti-Lag & Server Telemetry", "Optimasi FPS setiap map serta informasi wilayah server aktif.")

ApplyAntiLag = function(enabled)
    if enabled then
        Hub.OriginalLighting = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst:IsA("BasePart") then
                if not Hub.OriginalMaterials[inst] then
                    Hub.OriginalMaterials[inst] = inst.Material
                end
                inst.Material = Enum.Material.SmoothPlastic
                inst.CastShadow = false
            elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
                inst.Enabled = false
            elseif inst:IsA("Decal") or inst:IsA("Texture") then
                inst.Transparency = 1
            end
        end
    else
        if Hub.OriginalLighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = Hub.OriginalLighting.GlobalShadows
            Lighting.FogEnd = Hub.OriginalLighting.FogEnd
        end
        for inst, origMat in pairs(Hub.OriginalMaterials) do
            if inst and inst.Parent then
                inst.Material = origMat
            end
        end
        table.clear(Hub.OriginalMaterials)
    end
end

AddToggle(TabTheme, "Aktifkan Anti-Lag Map", "SmoothPlastic, nonaktifkan bayangan & partikel berat", "AntiLag_Enabled", function(on)
    ApplyAntiLag(on)
end)

if State.AntiLag_Enabled then
    task.defer(function() ApplyAntiLag(true) end)
end

--// 10. REGION / IP TELEMETRY FETCHER & PERIODIC SCHEDULER
local function HttpGetSafe(url)
    local reqFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if type(reqFunc) == "function" then
        local ok, res = pcall(function()
            return reqFunc({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body then return res.Body end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok then return body end
    return nil
end

local CachedRegionText = "Region: Edge Server"

task.spawn(function()
    local body = HttpGetSafe("http://ip-api.com/json/?fields=status,countryCode,city,query")
    if body then
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok and type(data) == "table" and data.status == "success" then
            local maskedIp = string.gsub(tostring(data.query or ""), "(%d+%.%d+%.)%d+%.%d+", "%1***.***")
            CachedRegionText = string.format("Region: %s, %s | IP: %s", data.city or "-", data.countryCode or "-", maskedIp)
        end
    end
end)

Hub:AddConnection(Players.PlayerAdded:Connect(function()
    RebuildPlayerSelector()
end))

Hub:AddConnection(Players.PlayerRemoving:Connect(function(plr)
    RemovePlayerESP(plr)
    if Hub.SelectedTarget == plr then
        StopSpectating()
    end
    RebuildPlayerSelector()
end))

RebuildPlayerSelector()
ScanGenerators()

-- Fast 10 Hz Update Loop (ESP, Generator Progress, Live Distances, Ping)
task.spawn(function()
    while Hub.Alive do
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                pcall(EnsurePlayerESP, plr)

                -- Update live distance inside Teleport Player Cards
                local cardRef = PlayerCardRefs[plr]
                if cardRef and cardRef.InfoLabel and cardRef.InfoLabel.Parent then
                    local rel, col = GetPlayerRelation(plr)
                    local tRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    local d = (myRoot and tRoot) and math.floor((myRoot.Position - tRoot.Position).Magnitude) or 0
                    cardRef.InfoLabel.TextColor3 = col
                    cardRef.InfoLabel.Text = string.format("[%s] %s (%dm)", rel, plr.DisplayName, d)
                end
            end
        end

        pcall(UpdateGeneratorVisuals)

        local pingMs = 0
        pcall(function()
            pingMs = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        HeaderSubtitle.Text = string.format("🌐 %s • %dms", CachedRegionText, pingMs)

        task.wait(0.1)
    end
end)

-- Periodic Generator Rescan Loop (Every 3 seconds)
task.spawn(function()
    while Hub.Alive do
        task.wait(3)
        if Hub.Alive then
            pcall(ScanGenerators)
        end
    end
end)
