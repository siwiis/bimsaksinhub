-- BimSakSin Hub - Steal a Wild Horse (Roblox)
-- Pure custom UI Hub (zero external sponsor branding), centered/responsive title header
-- with live Map Name subtitle directly beneath "BimSakSin Hub" and smooth rotating
-- black-white RGB border effect around the map name badge.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local State = {
    Alive = true,
    -- Horse Teleport & Labels
    TeleportSide = "Left", -- "Left", "Right", "Front", "Back"
    SafeDistanceOffset = 14, -- studs outside horse/danger circle
    ShowHorseLabels = true,
    -- Locked Pen / Gate Bypass
    PenBypassEnabled = false,
    -- Movement
    SpeedEnabled = false,
    WalkSpeed = 32,
    JumpEnabled = false,
    JumpPower = 75,
    FlyEnabled = false,
    FlySpeed = 60,
    -- Player ESP
    EspEnabled = true,
    AvatarRedColor = Color3.fromRGB(255, 35, 35),
    NameFontColor = Color3.fromRGB(255, 255, 255),
    NameBgColor = Color3.fromRGB(10, 10, 12),
    MinLabelScale = 0.72, -- fixed minimum size when far away
    MaxLabelScale = 1.15, -- max size when very close
    ReferenceDistance = 120, -- studs at which scaling clamps to MinLabelScale
}

-- ============================================================================
-- CONFIG PERSISTENCE (SAFE JSON SAVE/LOAD WITH SCHEMA MERGE)
-- ============================================================================
local CONFIG_FILE = "bimsaksin_hub_wild_horse_config.json"

local function serializeState()
    return {
        TeleportSide = State.TeleportSide,
        SafeDistanceOffset = State.SafeDistanceOffset,
        ShowHorseLabels = State.ShowHorseLabels,
        PenBypassEnabled = State.PenBypassEnabled,
        SpeedEnabled = State.SpeedEnabled,
        WalkSpeed = State.WalkSpeed,
        JumpEnabled = State.JumpEnabled,
        JumpPower = State.JumpPower,
        FlyEnabled = State.FlyEnabled,
        FlySpeed = State.FlySpeed,
        EspEnabled = State.EspEnabled,
        NameFontColor = {
            R = math.floor(State.NameFontColor.R * 255 + 0.5),
            G = math.floor(State.NameFontColor.G * 255 + 0.5),
            B = math.floor(State.NameFontColor.B * 255 + 0.5),
        },
    }
end

local function saveConfig()
    if type(writefile) ~= "function" then return false end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(serializeState())
    end)
    if not ok or not encoded then return false end
    local writeOk = pcall(function()
        writefile(CONFIG_FILE, encoded)
    end)
    return writeOk
end

local function loadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return false end
    local existsOk, exists = pcall(function()
        return isfile(CONFIG_FILE)
    end)
    if not existsOk or not exists then return false end

    local readOk, raw = pcall(function()
        return readfile(CONFIG_FILE)
    end)
    if not readOk or type(raw) ~= "string" then return false end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not decodeOk or type(data) ~= "table" then return false end

    if type(data.TeleportSide) == "string" then State.TeleportSide = data.TeleportSide end
    if type(data.SafeDistanceOffset) == "number" then State.SafeDistanceOffset = data.SafeDistanceOffset end
    if type(data.ShowHorseLabels) == "boolean" then State.ShowHorseLabels = data.ShowHorseLabels end
    if type(data.PenBypassEnabled) == "boolean" then State.PenBypassEnabled = data.PenBypassEnabled end
    if type(data.SpeedEnabled) == "boolean" then State.SpeedEnabled = data.SpeedEnabled end
    if type(data.WalkSpeed) == "number" then State.WalkSpeed = data.WalkSpeed end
    if type(data.JumpEnabled) == "boolean" then State.JumpEnabled = data.JumpEnabled end
    if type(data.JumpPower) == "number" then State.JumpPower = data.JumpPower end
    if type(data.FlyEnabled) == "boolean" then State.FlyEnabled = data.FlyEnabled end
    if type(data.FlySpeed) == "number" then State.FlySpeed = data.FlySpeed end
    if type(data.EspEnabled) == "boolean" then State.EspEnabled = data.EspEnabled end
    if type(data.NameFontColor) == "table" and data.NameFontColor.R and data.NameFontColor.G and data.NameFontColor.B then
        State.NameFontColor = Color3.fromRGB(
            math.clamp(tonumber(data.NameFontColor.R) or 255, 0, 255),
            math.clamp(tonumber(data.NameFontColor.G) or 255, 0, 255),
            math.clamp(tonumber(data.NameFontColor.B) or 255, 0, 255)
        )
    end
    return true
end

loadConfig()

local Connections = {}
local EspObjects = {}
local HorseLabels = {}
local BypassedParts = {}

local function trackConn(conn)
    table.insert(Connections, conn)
    return conn
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function getHumanoid()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ============================================================================
-- 1. HORSE DETECTION, SAFE SIDE TELEPORT & WORLD LABELS
-- ============================================================================
local HORSE_KEYWORDS = { "horse", "pony", "mare", "stallion", "foal", "wildhorse" }

local function isHorseModel(obj)
    if not obj or not obj:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local nameLower = string.lower(obj.Name)
    for _, kw in ipairs(HORSE_KEYWORDS) do
        if string.find(nameLower, kw, 1, true) then
            return true
        end
    end
    -- Fallback: model with Humanoid that is not a player and has horse-like parts
    if obj:FindFirstChildOfClass("Humanoid") then
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") and string.find(string.lower(d.Name), "hoof", 1, true) then
                return true
            end
        end
    end
    return false
end

local function getModelPivotCFrame(model)
    if not model or not model.Parent then return nil end
    local ok, pivot = pcall(function()
        return model:GetPivot()
    end)
    if ok and pivot then
        return pivot
    end
    local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    return primary and primary.CFrame or nil
end

-- Estimates radius of any danger/kick circle around the horse + user safe offset
local function getSafeOffsetVector(horseModel, pivot, side)
    local radius = 6
    for _, d in ipairs(horseModel:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = string.lower(d.Name)
            if string.find(n, "circle", 1, true) or string.find(n, "zone", 1, true) or string.find(n, "kick", 1, true) or string.find(n, "hitbox", 1, true) or string.find(n, "danger", 1, true) then
                local maxXZ = math.max(d.Size.X, d.Size.Z) * 0.5
                if maxXZ > radius then
                    radius = maxXZ
                end
            end
        end
    end

    local totalDist = radius + math.max(4, State.SafeDistanceOffset)
    local sideMap = {
        Left = -pivot.RightVector * totalDist,
        Right = pivot.RightVector * totalDist,
        Front = pivot.LookVector * totalDist,
        Back = -pivot.LookVector * totalDist,
    }
    local dir = sideMap[side] or (-pivot.RightVector * totalDist)
    return dir + Vector3.new(0, 2.5, 0)
end

local function clearHorseLabels()
    for model, gui in pairs(HorseLabels) do
        if gui and gui.Parent then
            gui:Destroy()
        end
        HorseLabels[model] = nil
    end
end

local function ensureHorseLabel(horseModel)
    if not State.ShowHorseLabels then return end
    if HorseLabels[horseModel] then return HorseLabels[horseModel] end

    local adornee = horseModel.PrimaryPart or horseModel:FindFirstChildWhichIsA("BasePart")
    if not adornee then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HorseTargetLabel"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 180, 0, 34)
    billboard.StudsOffset = Vector3.new(0, 4.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2000

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 200, 70)
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 240, 190)
    label.TextScaled = false
    label.Text = horseModel.Name
    label.Parent = frame

    billboard.Parent = LocalPlayer:WaitForChild("PlayerGui")
    HorseLabels[horseModel] = billboard
    return billboard
end

local function refreshHorseLabels()
    if not State.ShowHorseLabels then
        clearHorseLabels()
        return
    end
    local activeSet = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isHorseModel(obj) then
            activeSet[obj] = true
            ensureHorseLabel(obj)
        end
    end
    for model, gui in pairs(HorseLabels) do
        if not activeSet[model] or not model.Parent then
            if gui then gui:Destroy() end
            HorseLabels[model] = nil
        end
    end
end

local function getDetectedHorses()
    local root = getRootPart()
    local originPos = root and root.Position or Camera.CFrame.Position
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isHorseModel(obj) then
            local pivot = getModelPivotCFrame(obj)
            if pivot then
                table.insert(list, {
                    model = obj,
                    name = obj.Name,
                    distance = (pivot.Position - originPos).Magnitude,
                })
            end
        end
    end
    table.sort(list, function(a, b)
        return a.distance < b.distance
    end)
    return list
end

function TeleportToHorseSide(horseModel, sideOverride)
    local root = getRootPart()
    if not root or not horseModel or not horseModel.Parent then return false end

    local pivot = getModelPivotCFrame(horseModel)
    if not pivot then return false end

    local side = sideOverride or State.TeleportSide
    local offset = getSafeOffsetVector(horseModel, pivot, side)
    local targetPos = pivot.Position + offset
    -- Face toward the horse safely from the offset position
    local lookCFrame = CFrame.lookAt(targetPos, Vector3.new(pivot.Position.X, targetPos.Y, pivot.Position.Z))

    local char = getCharacter()
    if char then
        char:PivotTo(lookCFrame)
    else
        root.CFrame = lookCFrame
    end
    return true
end

function TeleportToNearestHorseSide(sideOverride)
    local root = getRootPart()
    if not root then return false end

    local bestHorse, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isHorseModel(obj) then
            local pivot = getModelPivotCFrame(obj)
            if pivot then
                local d = (pivot.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestHorse = obj
                end
            end
        end
    end

    if bestHorse then
        return TeleportToHorseSide(bestHorse, sideOverride)
    end
    return false
end

-- ============================================================================
-- 2. LOCKED PEN / RANCH GATE BYPASS (CLIENT COLLISION / BARRIER PASS-THROUGH)
-- ============================================================================
local PEN_KEYWORDS = { "pen", "gate", "fence", "lock", "door", "barrier", "ranch", "stall", "corral", "wall" }

local function isPenBarrierPart(part)
    if not part or not part:IsA("BasePart") then return false end
    if part.CanCollide == false then return false end
    local char = getCharacter()
    if char and part:IsDescendantOf(char) then return false end

    local fullLower = string.lower(part:GetFullName())
    for _, kw in ipairs(PEN_KEYWORDS) do
        if string.find(fullLower, kw, 1, true) then
            -- Avoid large terrain/ground floors
            if part.Size.Y >= 2.5 and part.Size.Y <= 40 and math.max(part.Size.X, part.Size.Z) <= 80 then
                return true
            end
        end
    end
    return false
end

local function applyPenBypass()
    local root = getRootPart()
    if not root then return end

    if not State.PenBypassEnabled then
        for part, origCollide in pairs(BypassedParts) do
            if part and part.Parent then
                part.CanCollide = origCollide
            end
            BypassedParts[part] = nil
        end
        return
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isPenBarrierPart(obj) then
            if (obj.Position - root.Position).Magnitude <= 90 then
                if BypassedParts[obj] == nil then
                    BypassedParts[obj] = obj.CanCollide
                end
                obj.CanCollide = false
            end
        end
    end
end

-- ============================================================================
-- 3. UNLIMITED SPEED, JUMP & FLY
-- ============================================================================
local flyBodyVel, flyBodyGyro

local function stopFly()
    if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

local function updateMovement()
    local hum = getHumanoid()
    local root = getRootPart()

    if hum then
        if State.SpeedEnabled then
            hum.WalkSpeed = State.WalkSpeed
        end
        if State.JumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower
        end
    end

    if State.FlyEnabled and root then
        if not flyBodyVel or not flyBodyVel.Parent then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBodyVel.Velocity = Vector3.zero
            flyBodyVel.Parent = root
        end
        if not flyBodyGyro or not flyBodyGyro.Parent then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBodyGyro.P = 1e5
            flyBodyGyro.CFrame = Camera.CFrame
            flyBodyGyro.Parent = root
        end

        local moveDir = Vector3.zero
        local camCF = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.yAxis end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end

        flyBodyVel.Velocity = moveDir * State.FlySpeed
        flyBodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + camCF.LookVector)
    else
        stopFly()
    end
end

-- ============================================================================
-- 4. UNLIMITED-RANGE PLAYER ESP (RED AVATAR, WALL-VISIBLE, RGB NAME BORDER)
-- ============================================================================
local function setAvatarRedTint(character, enabled)
    if not character then return end
    local highlight = character:FindFirstChild("SiwiisRedAvatarESP")
    if enabled then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "SiwiisRedAvatarESP"
            highlight.Adornee = character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- visible through walls
            highlight.FillColor = State.AvatarRedColor
            highlight.FillTransparency = 0.35
            highlight.OutlineColor = Color3.fromRGB(255, 110, 110)
            highlight.OutlineTransparency = 0.05
            highlight.Parent = character
        else
            highlight.Enabled = true
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillColor = State.AvatarRedColor
        end
    else
        if highlight then
            highlight.Enabled = false
        end
    end
end

local function createPlayerNameEsp(player)
    local gui = Instance.new("BillboardGui")
    gui.Name = "SiwiisPlayerNameESP"
    gui.AlwaysOnTop = true -- visible through walls & transparent/solid obstacles
    gui.MaxDistance = 0 -- 0 means no distance limit in Roblox BillboardGui
    gui.Size = UDim2.new(0, 140, 0, 28)
    gui.StudsOffset = Vector3.new(0, 3.2, 0)

    -- Outer rotating RGB border frame
    local borderFrame = Instance.new("Frame")
    borderFrame.Name = "RgbBorder"
    borderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    borderFrame.Position = UDim2.fromScale(0.5, 0.5)
    borderFrame.Size = UDim2.new(1, 0, 1, 0)
    borderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    borderFrame.BorderSizePixel = 0
    borderFrame.Parent = gui

    local outerCorner = Instance.new("UICorner")
    outerCorner.CornerRadius = UDim.new(0, 6)
    outerCorner.Parent = borderFrame

    local rgbGradient = Instance.new("UIGradient")
    rgbGradient.Name = "RotatingRgb"
    rgbGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(160, 220, 255)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 160, 220)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(180, 255, 180)),
        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(255, 235, 150)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
    })
    rgbGradient.Parent = borderFrame

    -- Inner black background box (leaves 2px RGB border around edges)
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "BlackBackground"
    bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    bgFrame.Position = UDim2.fromScale(0.5, 0.5)
    bgFrame.Size = UDim2.new(1, -4, 1, -4)
    bgFrame.BackgroundColor3 = State.NameBgColor
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = borderFrame

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 4)
    innerCorner.Parent = bgFrame

    -- Small-to-medium semi-bold text label (GothamMedium: not too thin, not overly heavy)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerNameLabel"
    nameLabel.Size = UDim2.fromScale(1, 1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13 -- small-medium size
    nameLabel.TextColor3 = State.NameFontColor
    nameLabel.TextScaled = false
    nameLabel.TextWrapped = false
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
    nameLabel.Parent = bgFrame

    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return {
        gui = gui,
        borderFrame = borderFrame,
        rgbGradient = rgbGradient,
        bgFrame = bgFrame,
        nameLabel = nameLabel,
    }
end

local function removePlayerEsp(player)
    local entry = EspObjects[player]
    if entry then
        if entry.gui and entry.gui.Parent then
            entry.gui:Destroy()
        end
        if player.Character then
            setAvatarRedTint(player.Character, false)
        end
        EspObjects[player] = nil
    end
end

local function ensurePlayerEsp(player)
    if player == LocalPlayer then return nil end
    if EspObjects[player] then return EspObjects[player] end
    local entry = createPlayerNameEsp(player)
    EspObjects[player] = entry
    return entry
end

-- Scales smoothly with avatar when nearby, and clamps to a fixed size at far distances
local function computeClampedScale(distance)
    local t = math.clamp(distance / math.max(1, State.ReferenceDistance), 0, 1)
    -- Near (t=0) -> MaxLabelScale; Far (t>=1) -> fixed MinLabelScale
    return State.MaxLabelScale + (State.MinLabelScale - State.MaxLabelScale) * t
end

local function updatePlayerEsp(dt)
    local root = getRootPart()
    local originPos = root and root.Position or Camera.CFrame.Position
    local rotAngle = (os.clock() * 140) % 360

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
            local entry = ensurePlayerEsp(player)

            if not State.EspEnabled or not char or not head then
                entry.gui.Enabled = false
                if char then setAvatarRedTint(char, false) end
            else
                entry.gui.Enabled = true
                entry.gui.Adornee = head
                entry.gui.MaxDistance = 0 -- unlimited range

                setAvatarRedTint(char, true)

                local dist = (head.Position - originPos).Magnitude
                local scale = computeClampedScale(dist)

                -- Base compact size (132x26 px) scaled smoothly & clamped at far distance
                local width = math.floor(132 * scale)
                local height = math.floor(26 * scale)
                entry.gui.Size = UDim2.new(0, width, 0, height)

                entry.bgFrame.BackgroundColor3 = State.NameBgColor
                entry.nameLabel.TextColor3 = State.NameFontColor
                entry.nameLabel.TextSize = math.clamp(math.floor(13 * scale), 10, 15)
                entry.nameLabel.Text = string.format("%s [%dm]", player.Name, math.floor(dist))

                entry.rgbGradient.Rotation = rotAngle
            end
        end
    end
end

-- ============================================================================
-- 5. BIMSAKSIN HUB UI (CLEAN CUSTOM PANEL, NO SPONSORS, MAP SUBTITLE + RGB)
-- ============================================================================
local function resolveCurrentMapName()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
        return info.Name
    end
    return "Steal a Wild Horse"
end

local CurrentMapName = resolveCurrentMapName()

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ExistingHub = PlayerGui:FindFirstChild("BimSakSinHubGui")
if ExistingHub then
    ExistingHub:Destroy()
end

local HubGui = Instance.new("ScreenGui")
HubGui.Name = "BimSakSinHubGui"
HubGui.ResetOnSpawn = false
HubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HubGui.Parent = PlayerGui

local THEME = {
    Bg = Color3.fromRGB(13, 14, 18),
    Header = Color3.fromRGB(18, 20, 26),
    Card = Color3.fromRGB(23, 25, 33),
    CardHover = Color3.fromRGB(32, 35, 46),
    Accent = Color3.fromRGB(245, 245, 250),
    AccentDark = Color3.fromRGB(48, 52, 68),
    ToggleOn = Color3.fromRGB(46, 196, 118),
    ToggleOff = Color3.fromRGB(56, 60, 74),
    Text = Color3.fromRGB(245, 247, 252),
    SubText = Color3.fromRGB(175, 182, 198),
    Border = Color3.fromRGB(48, 52, 66),
    Danger = Color3.fromRGB(215, 58, 58),
}

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 460, 0, 384)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -192)
MainFrame.BackgroundColor3 = THEME.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Parent = HubGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = THEME.Border
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Header Bar (Draggable, Clean, Zero Sponsor Text)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 62)
TopBar.BackgroundColor3 = THEME.Header
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local TopCover = Instance.new("Frame")
TopCover.Size = UDim2.new(1, 0, 0, 10)
TopCover.Position = UDim2.new(0, 0, 1, -10)
TopCover.BackgroundColor3 = THEME.Header
TopCover.BorderSizePixel = 0
TopCover.Parent = TopBar

-- Responsive Centered Title ("BimSakSin Hub")
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "HubTitle"
TitleLabel.AnchorPoint = Vector2.new(0.5, 0)
TitleLabel.Size = UDim2.new(1, -152, 0, 26)
TitleLabel.Position = UDim2.new(0.5, 0, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 17
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.Parent = TopBar

local TitleTextConstraint = Instance.new("UITextSizeConstraint")
TitleTextConstraint.MinTextSize = 13
TitleTextConstraint.MaxTextSize = 18
TitleTextConstraint.Parent = TitleLabel

-- Map Name Badge directly below "BimSakSin Hub" with smooth rotating Black-White-RGB border
local MapBadgeOuter = Instance.new("Frame")
MapBadgeOuter.Name = "MapBadgeOuter"
MapBadgeOuter.AnchorPoint = Vector2.new(0.5, 0)
MapBadgeOuter.Size = UDim2.new(0, 230, 0, 22)
MapBadgeOuter.Position = UDim2.new(0.5, 0, 0, 34)
MapBadgeOuter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MapBadgeOuter.BorderSizePixel = 0
MapBadgeOuter.Parent = TopBar

local MapOuterCorner = Instance.new("UICorner")
MapOuterCorner.CornerRadius = UDim.new(0, 6)
MapOuterCorner.Parent = MapBadgeOuter

local MapRgbGradient = Instance.new("UIGradient")
MapRgbGradient.Name = "SmoothBlackWhiteRgb"
MapRgbGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.18, Color3.fromRGB(20, 20, 24)),
    ColorSequenceKeypoint.new(0.36, Color3.fromRGB(145, 215, 255)),
    ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.68, Color3.fromRGB(255, 165, 220)),
    ColorSequenceKeypoint.new(0.84, Color3.fromRGB(22, 22, 26)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
})
MapRgbGradient.Parent = MapBadgeOuter

local MapBadgeInner = Instance.new("Frame")
MapBadgeInner.Name = "MapBadgeInner"
MapBadgeInner.AnchorPoint = Vector2.new(0.5, 0.5)
MapBadgeInner.Position = UDim2.fromScale(0.5, 0.5)
MapBadgeInner.Size = UDim2.new(1, -3, 1, -3)
MapBadgeInner.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
MapBadgeInner.BorderSizePixel = 0
MapBadgeInner.Parent = MapBadgeOuter

local MapInnerCorner = Instance.new("UICorner")
MapInnerCorner.CornerRadius = UDim.new(0, 5)
MapInnerCorner.Parent = MapBadgeInner

local MapNameLabel = Instance.new("TextLabel")
MapNameLabel.Name = "MapNameLabel"
MapNameLabel.Size = UDim2.new(1, -10, 1, 0)
MapNameLabel.Position = UDim2.new(0, 5, 0, 0)
MapNameLabel.BackgroundTransparency = 1
MapNameLabel.Font = Enum.Font.GothamMedium
MapNameLabel.TextSize = 11
MapNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
MapNameLabel.TextXAlignment = Enum.TextXAlignment.Center
MapNameLabel.TextColor3 = Color3.fromRGB(240, 244, 252)
MapNameLabel.Text = CurrentMapName
MapNameLabel.Parent = MapBadgeInner

-- Dynamically fit MapBadgeOuter width cleanly to the map title text
do
    local estWidth = math.clamp(#CurrentMapName * 7 + 26, 130, 280)
    MapBadgeOuter.Size = UDim2.new(0, estWidth, 0, 22)
end

-- Floating Toggle Pill (when minimized)
local OpenPill = Instance.new("TextButton")
OpenPill.Name = "OpenPill"
OpenPill.Size = UDim2.new(0, 132, 0, 32)
OpenPill.Position = UDim2.new(0, 16, 0.5, -16)
OpenPill.BackgroundColor3 = THEME.Header
OpenPill.BorderSizePixel = 0
OpenPill.Font = Enum.Font.GothamBold
OpenPill.TextSize = 12
OpenPill.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenPill.Text = "BimSakSin Hub"
OpenPill.Visible = false
OpenPill.Parent = HubGui

local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(0, 8)
PillCorner.Parent = OpenPill

local PillStroke = Instance.new("UIStroke")
PillStroke.Color = Color3.fromRGB(220, 220, 230)
PillStroke.Thickness = 1.2
PillStroke.Parent = OpenPill

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 24)
MinBtn.Position = UDim2.new(1, -66, 0, 8)
MinBtn.BackgroundColor3 = THEME.Card
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.TextColor3 = THEME.Text
MinBtn.Text = "–"
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = THEME.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Text = "X"
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

trackConn(MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenPill.Visible = true
end))

trackConn(OpenPill.MouseButton1Click:Connect(function()
    OpenPill.Visible = false
    MainFrame.Visible = true
end))

-- Drag logic for MainFrame
do
    local dragging, dragInput, dragStart, startPos
    trackConn(TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))
    trackConn(TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- Navigation Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 68)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 6)
TabLayout.Parent = TabBar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -110)
ContentContainer.Position = UDim2.new(0, 10, 0, 104)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Tabs = {}
local ActiveTabName = nil

local function createTab(tabName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -4.5, 1, 0)
    btn.BackgroundColor3 = THEME.Card
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = THEME.SubText
    btn.Text = tabName
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = THEME.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = ContentContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = page

    Tabs[tabName] = { button = btn, page = page }

    trackConn(btn.MouseButton1Click:Connect(function()
        for name, data in pairs(Tabs) do
            local selected = (name == tabName)
            data.page.Visible = selected
            data.button.BackgroundColor3 = selected and THEME.AccentDark or THEME.Card
            data.button.TextColor3 = selected and Color3.new(1, 1, 1) or THEME.SubText
        end
        ActiveTabName = tabName
    end))

    if not ActiveTabName then
        ActiveTabName = tabName
        btn.BackgroundColor3 = THEME.AccentDark
        btn.TextColor3 = Color3.new(1, 1, 1)
        page.Visible = true
    end

    return page
end

-- UI Component Helpers
local function addToggle(parent, labelText, initialState, onChanged)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = THEME.Card
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -74, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = THEME.Text
    lbl.Text = labelText
    lbl.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 22)
    btn.Position = UDim2.new(1, -62, 0.5, -11)
    btn.BackgroundColor3 = initialState and THEME.ToggleOn or THEME.ToggleOff
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = initialState and "ON" or "OFF"
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local current = initialState
    trackConn(btn.MouseButton1Click:Connect(function()
        current = not current
        btn.BackgroundColor3 = current and THEME.ToggleOn or THEME.ToggleOff
        btn.Text = current and "ON" or "OFF"
        onChanged(current)
        saveConfig()
    end))

    return card
end

-- Supports BOTH quick slider bar AND direct unlimited numeric input (no upper cap!)
local function addUnlimitedNumberControl(parent, labelText, initialVal, sliderMin, sliderMax, onChanged)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = THEME.Card
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -110, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = THEME.Text
    lbl.Text = labelText
    lbl.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 86, 0, 22)
    box.Position = UDim2.new(1, -96, 0, 5)
    box.BackgroundColor3 = THEME.Header
    box.BorderSizePixel = 0
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.TextColor3 = THEME.Accent
    box.ClearTextOnFocus = false
    box.Text = tostring(initialVal)
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 8)
    track.Position = UDim2.new(0, 12, 0, 38)
    track.BackgroundColor3 = THEME.Header
    track.BorderSizePixel = 0
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local initRatio = math.clamp((initialVal - sliderMin) / math.max(1, sliderMax - sliderMin), 0, 1)
    fill.Size = UDim2.new(initRatio, 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function applyValue(val)
        box.Text = tostring(val)
        local ratio = math.clamp((val - sliderMin) / math.max(1, sliderMax - sliderMin), 0, 1)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        onChanged(val)
        saveConfig()
    end

    trackConn(box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num and num >= 0 then
            applyValue(num)
        else
            box.Text = tostring(initialVal)
        end
    end))

    local sliding = false
    local function updateFromX(xPos)
        local rel = math.clamp((xPos - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        local val = math.floor(sliderMin + (sliderMax - sliderMin) * rel)
        applyValue(val)
    end

    trackConn(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromX(input.Position.X)
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end))
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end))

    return card
end

local function addActionButton(parent, btnText, bgColor, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = bgColor or THEME.AccentDark
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = btnText
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    trackConn(btn.MouseButton1Click:Connect(onClick))
    return btn
end

-- ============================================================================
-- BUILD TABS: HORSE TP | MOVEMENT | PLAYER ESP | KANDANG & CONFIG
-- ============================================================================
local TabHorse = createTab("Teleport Kuda")
local TabMove = createTab("Speed & Fly")
local TabEsp = createTab("Player ESP")
local TabRanch = createTab("Kandang & Config")

-- TAB 1: TELEPORT KUDA & LABEL NAMA KUDA
addToggle(TabHorse, "Tampilkan Label Nama Kuda di Map", State.ShowHorseLabels, function(v)
    State.ShowHorseLabels = v
    refreshHorseLabels()
end)

addUnlimitedNumberControl(TabHorse, "Jarak Aman dari Lingkaran Kuda (Studs)", State.SafeDistanceOffset, 4, 50, function(v)
    State.SafeDistanceOffset = v
end)

-- Side Selector Row (Left / Right / Front / Back)
do
    local sideCard = Instance.new("Frame")
    sideCard.Size = UDim2.new(1, 0, 0, 62)
    sideCard.BackgroundColor3 = THEME.Card
    sideCard.Parent = TabHorse
    Instance.new("UICorner", sideCard).CornerRadius = UDim.new(0, 7)

    local sLbl = Instance.new("TextLabel")
    sLbl.Size = UDim2.new(1, -24, 0, 22)
    sLbl.Position = UDim2.new(0, 12, 0, 4)
    sLbl.BackgroundTransparency = 1
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextSize = 12
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.TextColor3 = THEME.SubText
    sLbl.Text = "Pilih Sisi Teleport Kuda (Anti-Tendang):"
    sLbl.Parent = sideCard

    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -24, 0, 26)
    btnRow.Position = UDim2.new(0, 12, 0, 29)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = sideCard

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 6)
    rowLayout.Parent = btnRow

    local sides = {
        { id = "Left", label = "Kiri" },
        { id = "Right", label = "Kanan" },
        { id = "Front", label = "Depan" },
        { id = "Back", label = "Belakang" },
    }
    local sideBtns = {}

    for _, s in ipairs(sides) do
        local sb = Instance.new("TextButton")
        sb.Size = UDim2.new(0.25, -4.5, 1, 0)
        sb.BackgroundColor3 = (State.TeleportSide == s.id) and THEME.AccentDark or THEME.Header
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 12
        sb.TextColor3 = Color3.new(1, 1, 1)
        sb.Text = s.label
        sb.Parent = btnRow
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 5)
        sideBtns[s.id] = sb

        trackConn(sb.MouseButton1Click:Connect(function()
            State.TeleportSide = s.id
            for k, b in pairs(sideBtns) do
                b.BackgroundColor3 = (k == s.id) and THEME.AccentDark or THEME.Header
            end
            saveConfig()
        end))
    end
end

addActionButton(TabHorse, "Teleport ke Kuda Terdekat (Sisi Aman)", THEME.ToggleOn, function()
    TeleportToNearestHorseSide()
end)

-- Dynamic Horse List Container (lists all detected horse names & distances)
local HorseListHeader = Instance.new("TextLabel")
HorseListHeader.Size = UDim2.new(1, 0, 0, 22)
HorseListHeader.BackgroundTransparency = 1
HorseListHeader.Font = Enum.Font.GothamBold
HorseListHeader.TextSize = 12
HorseListHeader.TextXAlignment = Enum.TextXAlignment.Left
HorseListHeader.TextColor3 = THEME.Accent
HorseListHeader.Text = "Daftar Nama Kuda di Map (Klik untuk Teleport):"
HorseListHeader.Parent = TabHorse

local HorseListHolder = Instance.new("Frame")
HorseListHolder.Size = UDim2.new(1, 0, 0, 0)
HorseListHolder.AutomaticSize = Enum.AutomaticSize.Y
HorseListHolder.BackgroundTransparency = 1
HorseListHolder.Parent = TabHorse

local HorseListLayout = Instance.new("UIListLayout")
HorseListLayout.Padding = UDim.new(0, 5)
HorseListLayout.Parent = HorseListHolder

local function rebuildHorseListUI()
    for _, child in ipairs(HorseListHolder:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    local horses = getDetectedHorses()
    if #horses == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 28)
        empty.BackgroundColor3 = THEME.Card
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextColor3 = THEME.SubText
        empty.Text = "Belum ada kuda terdeteksi di Workspace..."
        empty.Parent = HorseListHolder
        Instance.new("UICorner", empty).CornerRadius = UDim.new(0, 6)
        return
    end

    for _, item in ipairs(horses) do
        local rowBtn = Instance.new("TextButton")
        rowBtn.Size = UDim2.new(1, 0, 0, 30)
        rowBtn.BackgroundColor3 = THEME.Card
        rowBtn.Font = Enum.Font.GothamMedium
        rowBtn.TextSize = 12
        rowBtn.TextXAlignment = Enum.TextXAlignment.Left
        rowBtn.TextColor3 = THEME.Text
        rowBtn.Text = string.format("  %s  (%dm)  [TP %s]", item.name, math.floor(item.distance), State.TeleportSide)
        rowBtn.Parent = HorseListHolder
        Instance.new("UICorner", rowBtn).CornerRadius = UDim.new(0, 6)

        rowBtn.MouseButton1Click:Connect(function()
            TeleportToHorseSide(item.model)
        end)
    end
end

addActionButton(TabHorse, "Refresh Daftar Nama Kuda", THEME.CardHover, function()
    refreshHorseLabels()
    rebuildHorseListUI()
end)

-- TAB 2: SPEED LARI, LOMPAT & FLY (NO LIMIT)
addToggle(TabMove, "Aktifkan Speed Lari (No Limit)", State.SpeedEnabled, function(v)
    State.SpeedEnabled = v
    if not v then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16 end
    end
end)

addUnlimitedNumberControl(TabMove, "Kecepatan Lari (Ketik angka bebas)", State.WalkSpeed, 16, 300, function(v)
    State.WalkSpeed = v
end)

addToggle(TabMove, "Aktifkan Speed / Tinggi Lompat (No Limit)", State.JumpEnabled, function(v)
    State.JumpEnabled = v
    if not v then
        local hum = getHumanoid()
        if hum then hum.JumpPower = 50 end
    end
end)

addUnlimitedNumberControl(TabMove, "Kekuatan Lompat (Ketik angka bebas)", State.JumpPower, 50, 400, function(v)
    State.JumpPower = v
end)

addToggle(TabMove, "Aktifkan Fly (WASD + Space + Ctrl)", State.FlyEnabled, function(v)
    State.FlyEnabled = v
    if not v then stopFly() end
end)

addUnlimitedNumberControl(TabMove, "Kecepatan Fly (Ketik angka bebas)", State.FlySpeed, 20, 500, function(v)
    State.FlySpeed = v
end)

-- TAB 3: PLAYER ESP (NO LIMIT DISTANCE, MERAH TEMBUS TEMBOK, NAMA RGB)
addToggle(TabEsp, "Aktifkan Player ESP (Merah + Nama RGB + No Limit)", State.EspEnabled, function(v)
    State.EspEnabled = v
end)

-- Font Color Picker Presets for ESP Name
do
    local colorCard = Instance.new("Frame")
    colorCard.Size = UDim2.new(1, 0, 0, 68)
    colorCard.BackgroundColor3 = THEME.Card
    colorCard.Parent = TabEsp
    Instance.new("UICorner", colorCard).CornerRadius = UDim.new(0, 7)

    local cLbl = Instance.new("TextLabel")
    cLbl.Size = UDim2.new(1, -24, 0, 22)
    cLbl.Position = UDim2.new(0, 12, 0, 4)
    cLbl.BackgroundTransparency = 1
    cLbl.Font = Enum.Font.GothamMedium
    cLbl.TextSize = 12
    cLbl.TextXAlignment = Enum.TextXAlignment.Left
    cLbl.TextColor3 = THEME.Text
    cLbl.Text = "Sesuaikan Warna Font Nama ESP:"
    cLbl.Parent = colorCard

    local paletteRow = Instance.new("Frame")
    paletteRow.Size = UDim2.new(1, -24, 0, 28)
    paletteRow.Position = UDim2.new(0, 12, 0, 30)
    paletteRow.BackgroundTransparency = 1
    paletteRow.Parent = colorCard

    local pLayout = Instance.new("UIListLayout")
    pLayout.FillDirection = Enum.FillDirection.Horizontal
    pLayout.Padding = UDim.new(0, 6)
    pLayout.Parent = paletteRow

    local presets = {
        { name = "Putih", col = Color3.fromRGB(255, 255, 255) },
        { name = "Merah", col = Color3.fromRGB(255, 85, 85) },
        { name = "Kuning", col = Color3.fromRGB(255, 225, 85) },
        { name = "Hijau", col = Color3.fromRGB(95, 255, 145) },
        { name = "Cyan", col = Color3.fromRGB(85, 225, 255) },
        { name = "Pink", col = Color3.fromRGB(255, 130, 225) },
    }

    for _, p in ipairs(presets) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(1 / #presets, -5, 1, 0)
        cb.BackgroundColor3 = THEME.Header
        cb.Font = Enum.Font.GothamBold
        cb.TextSize = 11
        cb.TextColor3 = p.col
        cb.Text = p.name
        cb.Parent = paletteRow
        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 5)

        trackConn(cb.MouseButton1Click:Connect(function()
            State.NameFontColor = p.col
            saveConfig()
        end))
    end
end

-- TAB 4: MASUK KANDANG PEMAIN TERKUNCI & PENGATURAN
addToggle(TabRanch, "Masuk Kandang Pemain Terkunci (Bypass Pagar/Pintu)", State.PenBypassEnabled, function(v)
    State.PenBypassEnabled = v
    applyPenBypass()
end)

addActionButton(TabRanch, "Simpan Pengaturan (Save Config)", THEME.AccentDark, function()
    saveConfig()
end)

addActionButton(TabRanch, "Unload & Hapus Script Sepenuhnya", THEME.Danger, function()
    if _G.CleanupWildHorseScript then
        _G.CleanupWildHorseScript()
    end
end)

-- ============================================================================
-- LIFECYCLE & MAIN LOOP
-- ============================================================================
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        ensurePlayerEsp(plr)
    end
end

trackConn(Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        ensurePlayerEsp(plr)
    end
end))

trackConn(Players.PlayerRemoving:Connect(function(plr)
    removePlayerEsp(plr)
end))

trackConn(RunService.RenderStepped:Connect(function(dt)
    if not State.Alive then return end
    updateMovement()
    updatePlayerEsp(dt)
    -- Smooth black-white RGB rotation around the map name badge below "BimSakSin Hub"
    MapRgbGradient.Rotation = (os.clock() * 95) % 360
end))

-- Periodic scan for horse labels, UI list refresh & locked pen barriers
task.spawn(function()
    while State.Alive do
        refreshHorseLabels()
        applyPenBypass()
        if MainFrame.Visible and ActiveTabName == "Teleport Kuda" then
            rebuildHorseListUI()
        end
        task.wait(1.0)
    end
end)

-- Cleanup helper (disconnects events, restores collisions, removes ESP & Hub UI)
_G.CleanupWildHorseScript = function()
    State.Alive = false
    stopFly()
    clearHorseLabels()
    State.PenBypassEnabled = false
    applyPenBypass()
    for plr in pairs(EspObjects) do
        removePlayerEsp(plr)
    end
    for _, conn in ipairs(Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(Connections)
    if HubGui and HubGui.Parent then
        HubGui:Destroy()
    end
end

trackConn(CloseBtn.MouseButton1Click:Connect(function()
    _G.CleanupWildHorseScript()
end))
