--=============================================================================
-- BimSakSin Hub | Modular Client Utility & Telemetry Overlay (Delta Executor)
--=============================================================================
-- Clean Architecture:
--   1. Config & State Manager (JSON Persistence + Safe Schema Merging)
--   2. Lifecycle & Cleanup Manager (Zero Orphaned Connections / Memory Safe)
--   3. UI Component Factory (Ultra-Transparent White Glassmorphism + 3D Animated Icons)
--   4. Feature Controllers (ESP, Generator Tracker, Movement, Network Telemetry, Anti-Lag, Target View/TP)
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
    Loops = {},
    ESPObjects = {},
    GeneratorObjects = {},
    OriginalMaterials = {},
    OriginalLighting = {},
    SelectedTarget = nil,
    ViewingTarget = false,
}

function Hub:AddConnection(conn)
    if conn then
        table.insert(self.Connections, conn)
    end
    return conn
end

function Hub:Cleanup()
    self.Alive = false
    self.ViewingTarget = false
    if Camera and LocalPlayer and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
        end
    end

    for _, conn in ipairs(self.Connections) do
        pcall(function()
            if conn.Connected then
                conn:Disconnect()
            end
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
        pcall(function()
            self.ScreenGui:Destroy()
        end)
    end
end

if getgenv then
    getgenv().BimSakSinHubCleanup = function()
        Hub:Cleanup()
    end
end

--// 2. CONFIG & STATE MANAGER
local CONFIG_FILE = "BimSakSinHub_Config.json"

local DefaultConfig = {
    ESP_Enabled = true,
    ESP_ShowDistance = true,
    ESP_AvatarMarker = true,
    ESP_TeamCheck = true, -- Distinguishes Teammates vs Enemies
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
    Floating_Pos = { X = 0.04, Y = 0.35 },
}

local State = {}
for k, v in pairs(DefaultConfig) do
    State[k] = v
end

local function SaveConfig()
    if type(writefile) ~= "function" then return end
    pcall(function()
        local encoded = HttpService:JSONEncode(State)
        writefile(CONFIG_FILE, encoded)
    end)
end

local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local raw = readfile(CONFIG_FILE)
            local decoded = HttpService:JSONDecode(raw)
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

--// 3. HELPER UTILITIES (Safe Parent, Relationship Resolver, Text Formatting)
local function GetSafeGuiParent()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function GetPlayerRelation(targetPlayer)
    if targetPlayer == LocalPlayer then
        return "SELF", Color3.fromRGB(255, 255, 255)
    end

    -- Check Friend Status safely
    local isFriend = false
    pcall(function()
        isFriend = LocalPlayer:IsFriendsWith(targetPlayer.UserId)
    end)

    -- Check Team Status
    local sameTeam = false
    if LocalPlayer.Team ~= nil and targetPlayer.Team ~= nil then
        sameTeam = (LocalPlayer.Team == targetPlayer.Team)
    elseif LocalPlayer.TeamColor ~= nil and targetPlayer.TeamColor ~= nil and not LocalPlayer.Neutral then
        sameTeam = (LocalPlayer.TeamColor == targetPlayer.TeamColor)
    end

    if isFriend then
        return "TEMAN", Color3.fromRGB(0, 230, 255)
    elseif State.ESP_TeamCheck and sameTeam then
        return "TEAM", Color3.fromRGB(80, 255, 130)
    else
        return "MUSUH", Color3.fromRGB(255, 75, 95)
    end
end

-- Creates text label with thick black outline/background tightly wrapping text ONLY (no boxy frame background)
local function CreateTightStyledText(parent, name, order, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.LayoutOrder = order
    lbl.AutomaticSize = Enum.AutomaticSize.XY
    lbl.Size = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1 -- Zero box background!
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = textSize or 14
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.08 -- Thick crisp black glyph backing
    lbl.RichText = true
    lbl.Parent = parent

    -- Secondary thick black UIStroke around font glyphs for high-contrast readability
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 2.4
    stroke.Transparency = 0.12
    stroke.Parent = lbl

    return lbl
end

--// 4. UI COMPONENT FACTORY (Ultra-Transparent White Glassmorphism)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = GetSafeGuiParent()
Hub.ScreenGui = ScreenGui

-- Smooth Tween Helper
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

-- 3D HD Skull Builder (ViewportFrame with Rotating 3D Mesh/Construct + Corner Accents)
local function Build3DSkullViewport(parent, sizeUDim2, posUDim2, anchorPoint)
    local vp = Instance.new("ViewportFrame")
    vp.Size = sizeUDim2
    vp.Position = posUDim2
    vp.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
    vp.BackgroundTransparency = 1
    vp.Ambient = Color3.fromRGB(220, 235, 255)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(-1, -1, -1)
    vp.Parent = parent

    local wm = Instance.new("WorldModel")
    wm.Parent = vp

    local vpCam = Instance.new("Camera")
    vpCam.CFrame = CFrame.new(Vector3.new(0, 0.1, 3.6), Vector3.new(0, 0, 0))
    vpCam.Parent = vp
    vp.CurrentCamera = vpCam

    local skullModel = Instance.new("Model")
    skullModel.Name = "HD_Skull_3D"
    skullModel.Parent = wm

    -- Cranium (Smooth Metallic/Pearl 3D Sphere Mesh)
    local cranium = Instance.new("Part")
    cranium.Size = Vector3.new(1.55, 1.45, 1.65)
    cranium.Position = Vector3.new(0, 0.28, 0)
    cranium.Material = Enum.Material.SmoothPlastic
    cranium.Color = Color3.fromRGB(245, 248, 255)
    cranium.Anchored = true
    local craniumMesh = Instance.new("SpecialMesh")
    craniumMesh.MeshType = Enum.MeshType.Sphere
    craniumMesh.Parent = cranium
    cranium.Parent = skullModel

    -- Cheekbones & Jaw Structure
    local jaw = Instance.new("Part")
    jaw.Size = Vector3.new(0.95, 0.72, 1.05)
    jaw.Position = Vector3.new(0, -0.45, 0.18)
    jaw.Material = Enum.Material.SmoothPlastic
    jaw.Color = Color3.fromRGB(230, 236, 245)
    jaw.Anchored = true
    local jawMesh = Instance.new("SpecialMesh")
    jawMesh.MeshType = Enum.MeshType.Sphere
    jawMesh.Parent = jaw
    jaw.Parent = skullModel

    -- Glowing Cyan-Blue 3D Eye Sockets
    for _, side in ipairs({ -1, 1 }) do
        local eye = Instance.new("Part")
        eye.Size = Vector3.new(0.36, 0.36, 0.25)
        eye.Position = Vector3.new(side * 0.34, 0.15, 0.72)
        eye.Material = Enum.Material.Neon
        eye.Color = Color3.fromRGB(40, 175, 255)
        eye.Anchored = true
        local eyeMesh = Instance.new("SpecialMesh")
        eyeMesh.MeshType = Enum.MeshType.Sphere
        eyeMesh.Parent = eye
        eye.Parent = skullModel
    end

    -- Nasal Cavity
    local nose = Instance.new("Part")
    nose.Size = Vector3.new(0.22, 0.28, 0.2)
    nose.Position = Vector3.new(0, -0.1, 0.76)
    nose.Material = Enum.Material.SmoothPlastic
    nose.Color = Color3.fromRGB(25, 30, 40)
    nose.Anchored = true
    local noseMesh = Instance.new("SpecialMesh")
    noseMesh.MeshType = Enum.MeshType.Wedge
    noseMesh.Parent = nose
    nose.Parent = skullModel

    -- Teeth Detail Ridges
    for i = -2, 2 do
        local tooth = Instance.new("Part")
        tooth.Size = Vector3.new(0.11, 0.22, 0.14)
        tooth.Position = Vector3.new(i * 0.15, -0.62, 0.65)
        tooth.Material = Enum.Material.SmoothPlastic
        tooth.Color = Color3.fromRGB(255, 255, 255)
        tooth.Anchored = true
        tooth.Parent = skullModel
    end

    skullModel.PrimaryPart = cranium

    return vp, skullModel
end

-- 3D Animated Blue Verification Checkmark Builder (Positioned neatly behind "BimSakSin Hub")
local function Build3DBlueCheckmark(parent)
    local vp = Instance.new("ViewportFrame")
    vp.Name = "BlueBadge3D"
    vp.Size = UDim2.new(0, 26, 0, 26)
    vp.BackgroundTransparency = 1
    vp.Ambient = Color3.fromRGB(180, 225, 255)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(1, -1, -1)
    vp.Parent = parent

    local wm = Instance.new("WorldModel")
    wm.Parent = vp

    local cam = Instance.new("Camera")
    cam.CFrame = CFrame.new(Vector3.new(0, 0, 3.1), Vector3.new(0, 0, 0))
    cam.Parent = vp
    vp.CurrentCamera = cam

    local badgeModel = Instance.new("Model")
    badgeModel.Parent = wm

    -- 3D Starburst / Rosette Medal Base (Verified Blue)
    local layers = 3
    for i = 1, layers do
        local disc = Instance.new("Part")
        disc.Size = Vector3.new(1.55, 1.55, 0.26)
        disc.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad((i - 1) * 30))
        disc.Material = Enum.Material.Neon
        disc.Color = Color3.fromRGB(24, 155, 255)
        disc.Anchored = true
        disc.Parent = badgeModel
        if i == 1 then
            badgeModel.PrimaryPart = disc
        end
    end

    -- 3D White Checkmark Short Leg
    local leg1 = Instance.new("Part")
    leg1.Size = Vector3.new(0.24, 0.56, 0.36)
    leg1.CFrame = CFrame.new(-0.22, -0.08, 0.04) * CFrame.Angles(0, 0, math.rad(42))
    leg1.Material = Enum.Material.SmoothPlastic
    leg1.Color = Color3.fromRGB(255, 255, 255)
    leg1.Anchored = true
    leg1.Parent = badgeModel

    -- 3D White Checkmark Long Leg
    local leg2 = Instance.new("Part")
    leg2.Size = Vector3.new(0.24, 0.96, 0.36)
    leg2.CFrame = CFrame.new(0.22, 0.08, 0.04) * CFrame.Angles(0, 0, math.rad(-42))
    leg2.Material = Enum.Material.SmoothPlastic
    leg2.Color = Color3.fromRGB(255, 255, 255)
    leg2.Anchored = true
    leg2.Parent = badgeModel

    return vp, badgeModel
end

--// FLOATING TOGGLE BUTTON (Ultra-Transparent White Glass + 3D HD Skull Logo)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "BimSakSin_FloatingToggle"
FloatingBtn.Size = UDim2.new(0, 58, 0, 58)
FloatingBtn.Position = UDim2.new(State.Floating_Pos.X, 0, State.Floating_Pos.Y, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.BackgroundTransparency = 0.84 -- True transparent white glass look
FloatingBtn.Text = ""
FloatingBtn.AutoButtonColor = false
FloatingBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(255, 255, 255)
FloatStroke.Thickness = 1.6
FloatStroke.Transparency = 0.35
FloatStroke.Parent = FloatingBtn

local FloatGradient = Instance.new("UIGradient")
FloatGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 235, 255)),
})
FloatGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.15),
    NumberSequenceKeypoint.new(1, 0.45),
})
FloatGradient.Rotation = 45
FloatGradient.Parent = FloatingBtn

local _, FloatingSkullModel = Build3DSkullViewport(
    FloatingBtn,
    UDim2.new(0, 48, 0, 48),
    UDim2.new(0.5, 0, 0.5, 0),
    Vector2.new(0.5, 0.5)
)

MakeDraggable(FloatingBtn, FloatingBtn, function(newPos)
    State.Floating_Pos = { X = newPos.X.Scale, Y = newPos.Y.Scale }
    SaveConfig()
end)

--// MAIN PANEL (Ultra-Transparent White Glassmorphism + 4 Corner 3D HD Skulls)
local MainPanel = Instance.new("Frame")
MainPanel.Name = "BimSakSin_MainPanel"
MainPanel.Size = UDim2.new(0, 560, 0, 390)
MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
MainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
MainPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainPanel.BackgroundTransparency = 0.86 -- Ultra-transparent crisp white web-glass
MainPanel.BorderSizePixel = 0
MainPanel.ClipsDescendants = false
MainPanel.Parent = ScreenGui

local PanelScale = Instance.new("UIScale")
PanelScale.Scale = State.Panel_Open and 1 or 0.01
PanelScale.Parent = MainPanel
MainPanel.Visible = State.Panel_Open

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 16)
PanelCorner.Parent = MainPanel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(255, 255, 255)
PanelStroke.Thickness = 1.6
PanelStroke.Transparency = 0.3
PanelStroke.Parent = MainPanel

local PanelGlassGrad = Instance.new("UIGradient")
PanelGlassGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 248, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 240, 255)),
})
PanelGlassGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(1, 0.35),
})
PanelGlassGrad.Rotation = 135
PanelGlassGrad.Parent = MainPanel

-- 4 Corner 3D HD Skull Badges on the Main Panel
local CornerSkullModels = {}
local cornerConfigs = {
    { pos = UDim2.new(0, 4, 0, 4), anchor = Vector2.new(0.5, 0.5), dir = 1 },
    { pos = UDim2.new(1, -4, 0, 4), anchor = Vector2.new(0.5, 0.5), dir = -1 },
    { pos = UDim2.new(0, 4, 1, -4), anchor = Vector2.new(0.5, 0.5), dir = -1 },
    { pos = UDim2.new(1, -4, 1, -4), anchor = Vector2.new(0.5, 0.5), dir = 1 },
}
for idx, cfg in ipairs(cornerConfigs) do
    local _, model = Build3DSkullViewport(
        MainPanel,
        UDim2.new(0, 34, 0, 34),
        cfg.pos,
        cfg.anchor
    )
    table.insert(CornerSkullModels, { Model = model, Dir = cfg.dir, Phase = idx * 0.8 })
end

-- Header Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, -24, 0, 46)
Header.Position = UDim2.new(0, 12, 0, 8)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BackgroundTransparency = 0.88
Header.Parent = MainPanel

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderStroke = Instance.new("UIStroke")
HeaderStroke.Color = Color3.fromRGB(255, 255, 255)
HeaderStroke.Thickness = 1
HeaderStroke.Transparency = 0.45
HeaderStroke.Parent = Header

MakeDraggable(Header, MainPanel)

-- Title Container: "BimSakSin Hub" + Spaced 3D Animated Blue Checkmark Behind Title
local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(0, 260, 1, 0)
TitleContainer.Position = UDim2.new(0, 22, 0, 0)
TitleContainer.BackgroundTransparency = 1
TitleContainer.Parent = Header

local TitleLayout = Instance.new("UIListLayout")
TitleLayout.FillDirection = Enum.FillDirection.Horizontal
TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TitleLayout.Padding = UDim.new(0, 6) -- Natural verification badge spacing behind title
TitleLayout.Parent = TitleContainer

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "HubTitle"
TitleLabel.AutomaticSize = Enum.AutomaticSize.X
TitleLabel.Size = UDim2.new(0, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextSize = 19
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TitleLabel.TextStrokeTransparency = 0.25
TitleLabel.Parent = TitleContainer

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(15, 25, 45)
TitleStroke.Thickness = 1.6
TitleStroke.Transparency = 0.2
TitleStroke.Parent = TitleLabel

local _, BlueCheckmarkModel = Build3DBlueCheckmark(TitleContainer)

-- Close / Minimize Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0.5, 0)
CloseBtn.AnchorPoint = Vector2.new(0, 0.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.82
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "—"
CloseBtn.TextSize = 15
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- Smooth Panel Open / Close Animation
local isAnimatingPanel = false
local function SetPanelOpen(openState)
    if isAnimatingPanel then return end
    isAnimatingPanel = true
    State.Panel_Open = openState
    SaveConfig()

    if openState then
        MainPanel.Visible = true
        PanelScale.Scale = 0.82
        MainPanel.BackgroundTransparency = 1
        TweenObj(PanelScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
        local t = TweenObj(MainPanel, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.86 })
        t.Completed:Wait()
    else
        TweenObj(PanelScale, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.82 })
        local t = TweenObj(MainPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
        t.Completed:Wait()
        MainPanel.Visible = false
    end
    isAnimatingPanel = false
end

Hub:AddConnection(FloatingBtn.MouseButton1Click:Connect(function()
    TweenObj(FloatingBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 52, 0, 52) })
    task.delay(0.12, function()
        if FloatingBtn and FloatingBtn.Parent then
            TweenObj(FloatingBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 58, 0, 58) })
        end
    end)
    SetPanelOpen(not State.Panel_Open)
end))

Hub:AddConnection(CloseBtn.MouseButton1Click:Connect(function()
    SetPanelOpen(false)
end))

--// 3D LOGO ANIMATION LOOP (Smooth Continuous Motion for Blue Checkmark & All 3D HD Skulls)
local animClock = 0
Hub:AddConnection(RunService.RenderStepped:Connect(function(dt)
    if not Hub.Alive then return end
    animClock = animClock + dt

    -- Smooth 3D Blue Checkmark Y-axis rotation + gentle float
    if BlueCheckmarkModel and BlueCheckmarkModel.PrimaryPart then
        local rotY = math.sin(animClock * 2.2) * math.rad(28)
        local bobY = math.sin(animClock * 3.0) * 0.08
        BlueCheckmarkModel:PivotTo(CFrame.new(0, bobY, 0) * CFrame.Angles(0, rotY, 0))
    end

    -- Floating Toggle 3D HD Skull smooth spin & hover
    if FloatingSkullModel and FloatingSkullModel.PrimaryPart then
        local rotY = animClock * 1.4
        local bobY = math.sin(animClock * 2.6) * 0.09
        FloatingSkullModel:PivotTo(CFrame.new(0, bobY, 0) * CFrame.Angles(math.sin(animClock * 1.5) * 0.12, rotY, 0))
    end

    -- 4 Corner Panel 3D HD Skulls synchronized smooth rotation
    for _, item in ipairs(CornerSkullModels) do
        if item.Model and item.Model.PrimaryPart then
            local rotY = (animClock * 1.3 * item.Dir) + item.Phase
            local bobY = math.sin(animClock * 2.5 + item.Phase) * 0.07
            item.Model:PivotTo(CFrame.new(0, bobY, 0) * CFrame.Angles(0, rotY, 0))
        end
    end
end))

--// NAVIGATION SIDEBAR & CONTENT PAGES
local BodyFrame = Instance.new("Frame")
BodyFrame.Size = UDim2.new(1, -24, 1, -68)
BodyFrame.Position = UDim2.new(0, 12, 0, 60)
BodyFrame.BackgroundTransparency = 1
BodyFrame.Parent = MainPanel

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 138, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Sidebar.BackgroundTransparency = 0.88
Sidebar.Parent = BodyFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Color3.fromRGB(255, 255, 255)
SidebarStroke.Thickness = 1
SidebarStroke.Transparency = 0.45
SidebarStroke.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.Parent = Sidebar

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingTop = UDim.new(0, 10)
SidebarPad.PaddingLeft = UDim.new(0, 8)
SidebarPad.PaddingRight = UDim.new(0, 8)
SidebarPad.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -146, 1, 0)
ContentContainer.Position = UDim2.new(0, 146, 0, 0)
ContentContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ContentContainer.BackgroundTransparency = 0.89
ContentContainer.Parent = BodyFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 12)
ContentCorner.Parent = ContentContainer

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = Color3.fromRGB(255, 255, 255)
ContentStroke.Thickness = 1
ContentStroke.Transparency = 0.45
ContentStroke.Parent = ContentContainer

local Tabs = {}
local ActiveTabName = nil

local function CreateTab(tabName)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "_TabBtn"
    tabBtn.Size = UDim2.new(1, 0, 0, 34)
    tabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.BackgroundTransparency = 0.92
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.Text = tabName
    tabBtn.TextSize = 13
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tabBtn.TextStrokeTransparency = 0.45
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = tabBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.65
    btnStroke.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingBottom = UDim.new(0, 8)
    pagePad.Parent = page

    Tabs[tabName] = { Button = tabBtn, Stroke = btnStroke, Page = page }

    Hub:AddConnection(tabBtn.MouseButton1Click:Connect(function()
        for name, data in pairs(Tabs) do
            local isTarget = (name == tabName)
            data.Page.Visible = isTarget
            TweenObj(data.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = isTarget and 0.68 or 0.92
            })
            TweenObj(data.Stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Transparency = isTarget and 0.15 or 0.65
            })
        end
        ActiveTabName = tabName
    end))

    if not ActiveTabName then
        ActiveTabName = tabName
        page.Visible = true
        tabBtn.BackgroundTransparency = 0.68
        btnStroke.Transparency = 0.15
    end

    return page
end

-- Interactive Component Builders
local function AddSectionHeader(parent, titleText, descText)
    local card = Instance.new("Frame")
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -4, 0, 34)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.88
    card.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = titleText
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.TextStrokeTransparency = 0.35
    title.Parent = card

    if descText then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, 0, 0, 15)
        desc.Position = UDim2.new(0, 0, 0, 18)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.Text = descText
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = Color3.fromRGB(235, 245, 255)
        desc.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        desc.TextStrokeTransparency = 0.5
        desc.Parent = card
    end
end

local function AddToggle(parent, titleText, subtitleText, stateKey, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -4, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.90
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = row

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Transparency = 0.55
    s.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -64, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = titleText
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.4
    lbl.Parent = row

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -64, 0, 15)
    sub.Position = UDim2.new(0, 10, 0, 24)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = subtitleText
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextColor3 = Color3.fromRGB(230, 240, 255)
    sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    sub.TextStrokeTransparency = 0.55
    sub.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -52, 0.5, 0)
    pill.AnchorPoint = Vector2.new(0, 0.5)
    pill.BackgroundColor3 = State[stateKey] and Color3.fromRGB(30, 165, 255) or Color3.fromRGB(255, 255, 255)
    pill.BackgroundTransparency = State[stateKey] and 0.25 or 0.78
    pill.Parent = row

    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(1, 0)
    pc.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = State[stateKey] and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = pill

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local function RefreshVisual()
        local on = State[stateKey]
        TweenObj(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = on and Color3.fromRGB(30, 165, 255) or Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = on and 0.2 or 0.78
        })
        TweenObj(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        })
    end

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
    box.Size = UDim2.new(1, -4, 0, 48)
    box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    box.BackgroundTransparency = 0.90
    box.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = box

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Transparency = 0.55
    s.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = titleText
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.4
    lbl.Parent = box

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.28, -10, 0, 18)
    valLbl.Position = UDim2.new(0.72, 0, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBlack
    valLbl.Text = tostring(State[stateKey])
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.TextColor3 = Color3.fromRGB(90, 200, 255)
    valLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    valLbl.TextStrokeTransparency = 0.35
    valLbl.Parent = box

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    track.BackgroundTransparency = 0.78
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = box

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track

    local fill = Instance.new("Frame")
    local initRatio = math.clamp((State[stateKey] - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(initRatio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(40, 175, 255)
    fill.BackgroundTransparency = 0.15
    fill.Parent = track

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
    btn.Size = UDim2.new(1, -4, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.84
    btn.Font = Enum.Font.GothamBold
    btn.Text = btnText
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextStrokeTransparency = 0.4
    btn.AutoButtonColor = false
    btn.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Transparency = 0.45
    s.Parent = btn

    Hub:AddConnection(btn.MouseButton1Click:Connect(function()
        TweenObj(btn, TweenInfo.new(0.1), { BackgroundTransparency = 0.65 })
        task.delay(0.12, function()
            if btn and btn.Parent then
                TweenObj(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.84 })
            end
        end)
        if callback then callback() end
    end))

    return btn
end

--// BUILD STRUCTURED TABS
local TabVisual = CreateTab("Visual & ESP")
local TabGenerator = CreateTab("Generator")
local TabMove = CreateTab("Movement")
local TabPlayer = CreateTab("Player & View")
local TabSystem = CreateTab("Region & Opt")

--=============================================================================
-- 5. FEATURE CONTROLLER A: PLAYER ESP (TIGHT FONT BACKING + TEAM/FRIEND/ENEMY)
--=============================================================================
AddSectionHeader(TabVisual, "Player ESP & Avatar Marker", "Font tebal berlatar hitam pekat menempel pada teks tanpa kotak.")
AddToggle(TabVisual, "Aktifkan Player ESP", "Tampilkan nama, jarak, dan status Team/Teman/Musuh", "ESP_Enabled")
AddToggle(TabVisual, "Tampilkan Jarak (Studs)", "Menghitung jarak real-time dari kamera ke target", "ESP_ShowDistance")
AddToggle(TabVisual, "Tanda Avatar ESP (Highlight & Pin)", "Menambahkan outline avatar dan ikon penanda di atas kepala", "ESP_AvatarMarker")
AddToggle(TabVisual, "Deteksi Team & Teman Otomatis", "Memisahkan warna Teman (Cyan), Team (Hijau), Musuh (Merah)", "ESP_TeamCheck")

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
        bb.Size = UDim2.new(0, 240, 0, 72)
        bb.StudsOffset = Vector3.new(0, 2.7, 0)
        bb.ResetOnSpawn = false
        bb.Parent = ScreenGui

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Padding = UDim.new(0, 1)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = bb

        -- Avatar Marker Pin (Diamond/Chevron Symbol)
        local markerLbl = CreateTightStyledText(bb, "MarkerLabel", 1, 15)
        markerLbl.Text = "◆"

        -- Bold Name + Relation Tag (Tight Font Black Outline, No Box Background)
        local nameLbl = CreateTightStyledText(bb, "NameLabel", 2, 14)

        -- Bold Distance + HP Tag
        local distLbl = CreateTightStyledText(bb, "DistLabel", 3, 12)

        -- Avatar Highlight Outline
        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSin_AvatarHL"
        hl.Adornee = char
        hl.FillTransparency = 0.78
        hl.OutlineTransparency = 0.05
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

    -- Update visibility & values
    data.Billboard.Enabled = State.ESP_Enabled
    data.Highlight.Enabled = State.ESP_Enabled and State.ESP_AvatarMarker
    data.MarkerLabel.Visible = State.ESP_AvatarMarker

    if not State.ESP_Enabled then return end

    local relationTag, relationColor = GetPlayerRelation(player)
    data.MarkerLabel.TextColor3 = relationColor
    data.Highlight.FillColor = relationColor
    data.Highlight.OutlineColor = relationColor

    local displayName = player.DisplayName ~= player.Name
        and string.format("%s (@%s)", player.DisplayName, player.Name)
        or player.Name

    data.NameLabel.TextColor3 = relationColor
    data.NameLabel.Text = string.format("[%s] %s", relationTag, displayName)

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = char:FindFirstChild("HumanoidRootPart") or head
    local dist = (myRoot and targetRoot) and math.floor((myRoot.Position - targetRoot.Position).Magnitude) or 0
    local hp = math.floor(hum.Health)

    data.DistLabel.Visible = State.ESP_ShowDistance
    data.DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    data.DistLabel.Text = string.format("%d m  |  HP: %d", dist, hp)
end

--=============================================================================
-- 6. FEATURE CONTROLLER B: GENERATOR ESP + REAL-TIME PROGRESS (%)
--=============================================================================
AddSectionHeader(TabGenerator, "Generator Telemetry & Progress ESP", "Mendeteksi semua generator di map, jarak, serta % selesai vs % tersisa.")
AddToggle(TabGenerator, "Aktifkan Generator ESP", "Tampilkan lokasi generator, jarak, dan persentase pengerjaan", "Generator_ESP")

local GeneratorStatusLabel = Instance.new("TextLabel")
GeneratorStatusLabel.Size = UDim2.new(1, -4, 0, 28)
GeneratorStatusLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GeneratorStatusLabel.BackgroundTransparency = 0.90
GeneratorStatusLabel.Font = Enum.Font.GothamBold
GeneratorStatusLabel.Text = "  Scanning generator di map..."
GeneratorStatusLabel.TextSize = 12
GeneratorStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
GeneratorStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
GeneratorStatusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
GeneratorStatusLabel.TextStrokeTransparency = 0.45
GeneratorStatusLabel.Parent = TabGenerator
local gsc = Instance.new("UICorner")
gsc.CornerRadius = UDim.new(0, 8)
gsc.Parent = GeneratorStatusLabel

-- Universal Generator Progress Extractor (Supports Attributes, ValueObjects, & UI ProgressBars)
local function ReadGeneratorProgress(genObj)
    -- 1. Check Attributes (Progress, Percent, Repair, Charge, Work)
    local attrNames = { "Progress", "Percent", "Percentage", "RepairProgress", "Charge", "Completion", "Work" }
    for _, attr in ipairs(attrNames) do
        local val = genObj:GetAttribute(attr)
        if type(val) == "number" then
            local maxVal = genObj:GetAttribute("Max" .. attr) or genObj:GetAttribute("MaxProgress") or (val <= 1.01 and 1 or 100)
            local pct = math.clamp((val / math.max(maxVal, 0.001)) * 100, 0, 100)
            return math.floor(pct + 0.5)
        end
    end

    -- 2. Check Descendant NumberValue / IntValue / BoolValue
    local isCompleted = false
    for _, desc in ipairs(genObj:GetDescendants()) do
        local lowerName = string.lower(desc.Name)
        if desc:IsA("BoolValue") and (string.find(lowerName, "done") or string.find(lowerName, "complete") or string.find(lowerName, "fixed") or string.find(lowerName, "repaired")) then
            if desc.Value == true then
                isCompleted = true
            end
        elseif (desc:IsA("NumberValue") or desc:IsA("IntValue")) and (
            string.find(lowerName, "progress") or
            string.find(lowerName, "percent") or
            string.find(lowerName, "repair") or
            string.find(lowerName, "charge") or
            string.find(lowerName, "work")
        ) then
            local val = desc.Value
            local parentMax = desc.Parent and (desc.Parent:FindFirstChild("MaxProgress") or desc.Parent:FindFirstChild("MaxCharge"))
            local maxVal = (parentMax and parentMax.Value) or (val <= 1.01 and val > 0 and 1 or 100)
            local pct = math.clamp((val / math.max(maxVal, 0.001)) * 100, 0, 100)
            return math.floor(pct + 0.5)
        end
    end

    if isCompleted then
        return 100
    end

    return 0
end

local function IsGeneratorInstance(inst)
    if not (inst:IsA("Model") or inst:IsA("BasePart")) then return false end
    local lname = string.lower(inst.Name)
    if string.find(lname, "generator") or string.find(lname, "gen_") or lname == "gen" then
        -- Avoid matching small sub-parts inside an already tracked Generator Model
        if inst.Parent and string.find(string.lower(inst.Parent.Name), "generator") then
            return false
        end
        return true
    end
    return false
end

local function ScanGenerators()
    -- Clean invalid entries
    for obj, data in pairs(Hub.GeneratorObjects) do
        if not obj or not obj.Parent then
            pcall(function()
                if data.Billboard then data.Billboard:Destroy() end
                if data.Highlight then data.Highlight:Destroy() end
            end)
            Hub.GeneratorObjects[obj] = nil
        end
    end

    local count = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if IsGeneratorInstance(inst) then
            count = count + 1
            if not Hub.GeneratorObjects[inst] then
                local adornee = inst:IsA("BasePart") and inst or (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true))
                if adornee then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "BimSakSin_GenESP"
                    bb.Adornee = adornee
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 260, 0, 56)
                    bb.StudsOffset = Vector3.new(0, 3.2, 0)
                    bb.Parent = ScreenGui

                    local layout = Instance.new("UIListLayout")
                    layout.FillDirection = Enum.FillDirection.Vertical
                    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    layout.VerticalAlignment = Enum.VerticalAlignment.Center
                    layout.Padding = UDim.new(0, 1)
                    layout.Parent = bb

                    local titleLbl = CreateTightStyledText(bb, "GenTitle", 1, 13)
                    local progLbl = CreateTightStyledText(bb, "GenProg", 2, 12)

                    local hl = Instance.new("Highlight")
                    hl.Adornee = inst
                    hl.FillTransparency = 0.8
                    hl.OutlineTransparency = 0.1
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = ScreenGui

                    Hub.GeneratorObjects[inst] = {
                        Adornee = adornee,
                        Billboard = bb,
                        TitleLabel = titleLbl,
                        ProgLabel = progLbl,
                        Highlight = hl,
                    }
                end
            end
        end
    end

    GeneratorStatusLabel.Text = string.format("  Terdeteksi: %d Generator aktif di map", count)
end

local function UpdateGeneratorVisuals()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for genObj, data in pairs(Hub.GeneratorObjects) do
        if genObj and genObj.Parent and data.Adornee then
            data.Billboard.Enabled = State.Generator_ESP
            data.Highlight.Enabled = State.Generator_ESP

            if State.Generator_ESP then
                local donePct = ReadGeneratorProgress(genObj)
                local remPct = math.max(0, 100 - donePct)
                local dist = myRoot and math.floor((myRoot.Position - data.Adornee.Position).Magnitude) or 0

                local statusColor = donePct >= 100
                    and Color3.fromRGB(70, 255, 130)
                    or (donePct > 0 and Color3.fromRGB(255, 215, 65) or Color3.fromRGB(75, 205, 255))

                data.Highlight.FillColor = statusColor
                data.Highlight.OutlineColor = statusColor
                data.TitleLabel.TextColor3 = statusColor
                data.TitleLabel.Text = string.format("⚡ GENERATOR [%d m]", dist)

                data.ProgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.ProgLabel.Text = string.format("Selesai: %d%%  |  Belum: %d%%", donePct, remPct)
            end
        end
    end
end

AddActionButton(TabGenerator, "🔄 Rescan Generator di Map Sekarang", function()
    ScanGenerators()
    UpdateGeneratorVisuals()
end)

--=============================================================================
-- 7. FEATURE CONTROLLER C: MOVEMENT (FLY, WALKSPEED, JUMP, NOCLIP)
--=============================================================================
AddSectionHeader(TabMove, "Character Movement & Physics", "Kontrol terbang 3D kamera, kecepatan lari, lompatan, dan tembus dinding.")

local flyBodyGyro, flyBodyVel

local function DisableFly()
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

AddToggle(TabMove, "Fly Mode (3D Directional)", "Terbang bebas mengikuti arah kamera (WASD / Analog)", "Fly_Enabled", function(on)
    if on then EnableFly() else DisableFly() end
end)
AddSlider(TabMove, "Kecepatan Fly", 16, 250, "Fly_Speed")

AddToggle(TabMove, "WalkHack / Custom Speed", "Mengubah kecepatan jalan/lari karakter secara stabil", "WalkSpeed_Enabled", function(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and not on then hum.WalkSpeed = 16 end
end)
AddSlider(TabMove, "Nilai WalkSpeed", 16, 200, "WalkSpeed_Value")

AddToggle(TabMove, "Super Jump", "Meningkatkan tinggi lompatan karakter", "JumpPower_Enabled", function(on)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and not on then
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end
end)
AddSlider(TabMove, "Nilai JumpPower", 50, 300, "JumpPower_Value")

AddToggle(TabMove, "Noclip (Tembus Objek)", "Menonaktifkan kolisi karakter untuk menembus dinding", "Noclip_Enabled", function(on)
    if not on and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end)

-- Physics & Movement Step Loop
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

            -- Project MoveDirection onto camera orientation for mobile & PC compatibility
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
-- 8. FEATURE CONTROLLER D: PLAYER TARGETING, VIEW (SPECTATE) & AUTO TELEPORT
--=============================================================================
AddSectionHeader(TabPlayer, "Auto Teleport & View Pemain", "Pilih pemain target untuk memantau kamera (View) atau teleport instan.")

local SelectedPlayerLabel = Instance.new("TextLabel")
SelectedPlayerLabel.Size = UDim2.new(1, -4, 0, 28)
SelectedPlayerLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SelectedPlayerLabel.BackgroundTransparency = 0.88
SelectedPlayerLabel.Font = Enum.Font.GothamBold
SelectedPlayerLabel.Text = "  Target Dipilih: Belum ada"
SelectedPlayerLabel.TextSize = 12
SelectedPlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedPlayerLabel.TextColor3 = Color3.fromRGB(90, 210, 255)
SelectedPlayerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
SelectedPlayerLabel.TextStrokeTransparency = 0.4
SelectedPlayerLabel.Parent = TabPlayer
local spc = Instance.new("UICorner")
spc.CornerRadius = UDim.new(0, 8)
spc.Parent = SelectedPlayerLabel

AddActionButton(TabPlayer, "⚡ Auto Teleport ke Target", function()
    local target = Hub.SelectedTarget
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            myRoot.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 3)
        end
    end
end)

local ViewBtn
ViewBtn = AddActionButton(TabPlayer, "👁️ View / Spectate Target: OFF", function()
    Hub.ViewingTarget = not Hub.ViewingTarget
    if Hub.ViewingTarget and Hub.SelectedTarget and Hub.SelectedTarget.Character then
        local targetHum = Hub.SelectedTarget.Character:FindFirstChildOfClass("Humanoid")
        if targetHum then
            Workspace.CurrentCamera.CameraSubject = targetHum
            ViewBtn.Text = "👁️ View / Spectate Target: ON (" .. Hub.SelectedTarget.Name .. ")"
            return
        end
    end
    Hub.ViewingTarget = false
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if myHum then
        Workspace.CurrentCamera.CameraSubject = myHum
    end
    ViewBtn.Text = "👁️ View / Spectate Target: OFF"
end)

-- Dynamic Player List Container inside TabPlayer
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.AutomaticSize = Enum.AutomaticSize.Y
PlayerListFrame.Size = UDim2.new(1, -4, 0, 40)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.Parent = TabPlayer

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.Parent = PlayerListFrame

local function RebuildPlayerSelector()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local rel, col = GetPlayerRelation(plr)
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, 0, 0, 32)
            pBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            pBtn.BackgroundTransparency = (Hub.SelectedTarget == plr) and 0.72 or 0.90
            pBtn.Font = Enum.Font.GothamBold
            pBtn.Text = string.format("  [%s] %s (@%s)", rel, plr.DisplayName, plr.Name)
            pBtn.TextSize = 11
            pBtn.TextXAlignment = Enum.TextXAlignment.Left
            pBtn.TextColor3 = col
            pBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            pBtn.TextStrokeTransparency = 0.45
            pBtn.Parent = PlayerListFrame

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = pBtn

            Hub:AddConnection(pBtn.MouseButton1Click:Connect(function()
                Hub.SelectedTarget = plr
                SelectedPlayerLabel.Text = "  Target Dipilih: " .. plr.DisplayName .. " (@" .. plr.Name .. ")"
                if Hub.ViewingTarget and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        Workspace.CurrentCamera.CameraSubject = hum
                        ViewBtn.Text = "👁️ View / Spectate Target: ON (" .. plr.Name .. ")"
                    end
                end
                RebuildPlayerSelector()
            end))
        end
    end
end

--=============================================================================
-- 9. FEATURE CONTROLLER E: REGION / SERVER IP TELEMETRY & ANTI-LAG ENGINE
--=============================================================================
AddSectionHeader(TabSystem, "Region & Server Network Telemetry", "Mendeteksi wilayah server, ping jaringan, dan metadata pengguna aktif.")

local RegionInfoLabel = Instance.new("TextLabel")
RegionInfoLabel.AutomaticSize = Enum.AutomaticSize.Y
RegionInfoLabel.Size = UDim2.new(1, -4, 0, 96)
RegionInfoLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RegionInfoLabel.BackgroundTransparency = 0.90
RegionInfoLabel.Font = Enum.Font.GothamBold
RegionInfoLabel.Text = "  Memuat informasi Region & Server API..."
RegionInfoLabel.TextSize = 11
RegionInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
RegionInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
RegionInfoLabel.TextWrapped = true
RegionInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RegionInfoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
RegionInfoLabel.TextStrokeTransparency = 0.45
RegionInfoLabel.Parent = TabSystem

local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(0, 10)
rc.Parent = RegionInfoLabel

local rpad = Instance.new("UIPadding")
rpad.PaddingTop = UDim.new(0, 8)
rpad.PaddingBottom = UDim.new(0, 8)
rpad.PaddingLeft = UDim.new(0, 10)
rpad.PaddingRight = UDim.new(0, 10)
rpad.Parent = RegionInfoLabel

-- Public HTTP Request Resolver (Delta / Executor Compatible)
local function HttpGetSafe(url)
    local reqFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if type(reqFunc) == "function" then
        local ok, res = pcall(function()
            return reqFunc({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body then
            return res.Body
        end
    end
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok then return body end
    return nil
end

local CachedServerRegion = "Mendeteksi..."
local CachedClientLocale = "ID / UTC+7"

task.spawn(function()
    -- Detect Local Player Locale via Roblox LocalizationService API
    pcall(function()
        local LocalizationService = game:GetService("LocalizationService")
        CachedClientLocale = tostring(LocalizationService.RobloxLocaleId)
    end)

    -- Fetch Server Node Region / IP Geolocation via Public Telemetry Endpoint
    local body = HttpGetSafe("http://ip-api.com/json/?fields=status,country,countryCode,regionName,city,isp,query")
    if body then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if ok and type(data) == "table" and data.status == "success" then
            CachedServerRegion = string.format("%s, %s (%s) | Node: %s", data.city or "-", data.country or "-", data.countryCode or "-", data.query or "Protected")
        else
            CachedServerRegion = "Roblox Dedicated Edge Node"
        end
    else
        CachedServerRegion = "Roblox Dedicated Edge Node"
    end
end)

-- Anti-Lag Map Optimizer Engine
local function ApplyAntiLag(enabled)
    if enabled then
        Hub.OriginalLighting = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            Brightness = Lighting.Brightness,
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

AddSectionHeader(TabSystem, "Anti-Lag Map Optimizer", "Menurunkan beban shader, partikel, dan shadow di semua map untuk FPS maksimal.")
AddToggle(TabSystem, "Aktifkan Anti-Lag Engine", "Optimasi material SmoothPlastic, matikan partikel & shadow berat", "AntiLag_Enabled", function(on)
    ApplyAntiLag(on)
end)

if State.AntiLag_Enabled then
    task.defer(function() ApplyAntiLag(true) end)
end

--// 10. PERIODIC RUNTIME SCHEDULER (Frame-Safe, Zero Lag)
Hub:AddConnection(Players.PlayerAdded:Connect(function()
    RebuildPlayerSelector()
end))

Hub:AddConnection(Players.PlayerRemoving:Connect(function(plr)
    RemovePlayerESP(plr)
    if Hub.SelectedTarget == plr then
        Hub.SelectedTarget = nil
        Hub.ViewingTarget = false
        SelectedPlayerLabel.Text = "  Target Dipilih: Belum ada"
        ViewBtn.Text = "👁️ View / Spectate Target: OFF"
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if myHum then Workspace.CurrentCamera.CameraSubject = myHum end
    end
    RebuildPlayerSelector()
end))

RebuildPlayerSelector()
ScanGenerators()

-- Fast ESP & Generator Distance Loop (10 Hz / 0.1s interval for crisp numbers without frame drops)
task.spawn(function()
    while Hub.Alive do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                pcall(EnsurePlayerESP, plr)
            end
        end
        pcall(UpdateGeneratorVisuals)

        -- Update Region & Telemetry Card
        local pingMs = 0
        pcall(function()
            pingMs = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local jobIdShort = (#game.JobId > 0) and string.sub(game.JobId, 1, 18) .. "..." or "Local/Studio"
        RegionInfoLabel.Text = string.format(
            "Server Region: %s\nUser Locale: %s  |  Ping: %d ms\nActive Players: %d/%d  |  Server ID: %s",
            CachedServerRegion,
            CachedClientLocale,
            pingMs,
            #Players:GetPlayers(),
            Players.MaxPlayers,
            jobIdShort
        )

        task.wait(0.1)
    end
end)

-- Periodic Generator Rescan Loop (Every 3 seconds to catch newly spawned generators)
task.spawn(function()
    while Hub.Alive do
        task.wait(3)
        if Hub.Alive then
            pcall(ScanGenerators)
        end
    end
end)
