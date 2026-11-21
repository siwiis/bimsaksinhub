--// =========================================================================
--// BIMSAKSIN HUB
--// =========================================================================

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

--// ================= CLEANUP INSTANCE SEBELUMNYA =================
pcall(function()
    if getgenv and getgenv().BimSakSinHubCleanup then
        getgenv().BimSakSinHubCleanup()
    end
end)

local Connections = {}
local function bindConnection(conn)
    table.insert(Connections, conn)
    return conn
end

--// ================= KONFIGURASI & STATE =================
local Config = {
    PlayerESP = false,
    TeamFriendCheck = true,
    EnemyOnlyESP = false,
    GeneratorESP = false,
    AutoGenerator = false,
    AutoTPGenerator = false,
    Noclip = false,
    Fly = false,
    Speed = 16,
    FlySpeed = 65
}

local NetworkInfo = {
    Region = "Mendeteksi...",
    IP = "Memuat...",
    Masked = false
}

local IsAlive = true
local IsPanelOpen = true

local playerEspCache = {}
local playerEspConns = {}
local friendStatusCache = {}
local playerEspCleared = true

local generatorCache = {}
local generatorEspCache = {}
local generatorEspCleared = true

local noclipCache = {}
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

--// ================= HELPER KARAKTER =================
local function getChar()
    return LocalPlayer.Character
end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

--// ================= API: DETEKSI TEAM / TEMAN VS MUSUH =================
local COLOR_ENEMY  = Color3.fromRGB(248, 113, 113) -- Merah Koral (Musuh)
local COLOR_TEAM   = Color3.fromRGB(52, 211, 153)  -- Hijau Zamrud (Satu Team)
local COLOR_FRIEND = Color3.fromRGB(56, 189, 248)  -- Biru Langit (Teman Roblox)

local function cacheFriendStatus(player)
    if not player or player == LocalPlayer or friendStatusCache[player.UserId] ~= nil then
        return
    end
    friendStatusCache[player.UserId] = false
    task.spawn(function()
        local ok, isFriend = pcall(function()
            return LocalPlayer:IsFriendsWith(player.UserId)
        end)
        if ok and isFriend then
            friendStatusCache[player.UserId] = true
        end
    end)
end

local function hasActiveTeams()
    return (#Teams:GetTeams() > 0) and (LocalPlayer.Team ~= nil)
end

-- Mengembalikan: isEnemy (bool), label (string), color (Color3)
local function getPlayerRelation(player)
    if not player or player == LocalPlayer then
        return false, "SAYA", COLOR_TEAM
    end

    if not Config.TeamFriendCheck then
        return true, "MUSUH", COLOR_ENEMY
    end

    -- Cek teman Roblox
    if friendStatusCache[player.UserId] == true then
        return false, "TEMAN", COLOR_FRIEND
    end

    -- Cek satu team via Teams API
    if hasActiveTeams() then
        if not player.Neutral and not LocalPlayer.Neutral then
            if player.Team == LocalPlayer.Team or player.TeamColor == LocalPlayer.TeamColor then
                return false, "TEAM", COLOR_TEAM
            end
        end
    end

    return true, "MUSUH", COLOR_ENEMY
end

--// ================= API: NETWORK REGION & IP =================
local function httpGetAsync(url)
    local reqFunc = (typeof(request) == "function" and request)
        or (typeof(http_request) == "function" and http_request)
        or (syn and typeof(syn.request) == "function" and syn.request)
        or (fluxus and typeof(fluxus.request) == "function" and fluxus.request)

    if reqFunc then
        local ok, res = pcall(reqFunc, { Url = url, Method = "GET" })
        if ok and res and res.Body and #res.Body > 0 then
            return res.Body
        end
    end

    local okGet, body = pcall(function()
        return game:HttpGet(url)
    end)
    if okGet and body and #body > 0 then
        return body
    end
    return nil
end

local function maskIPAddress(ipStr)
    if not ipStr or ipStr == "Tidak Tersedia" or ipStr == "Memuat..." or ipStr == "Local Client" then
        return ipStr
    end
    local parts = string.split(ipStr, ".")
    if #parts == 4 then
        return parts[1] .. "." .. parts[2] .. ".***.***"
    end
    return string.sub(ipStr, 1, 6) .. "****"
end

local function fetchRegionAndIP(onUpdated)
    task.spawn(function()
        local okLoc, countryCode = pcall(function()
            return LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
        end)
        if okLoc and countryCode and countryCode ~= "" then
            NetworkInfo.Region = countryCode
            if onUpdated then onUpdated() end
        end

        local raw = httpGetAsync("http://ip-api.com/json/?fields=status,countryCode,regionName,city,query")
        if raw then
            local okJson, data = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if okJson and type(data) == "table" and data.status == "success" then
                local city = data.city or data.regionName or ""
                local cc = data.countryCode or NetworkInfo.Region
                NetworkInfo.Region = (city ~= "" and (city .. ", " .. cc)) or cc
                NetworkInfo.IP = data.query or "Tidak Tersedia"
                if onUpdated then onUpdated() end
                return
            end
        end

        local rawBackup = httpGetAsync("https://ipwho.is/")
        if rawBackup then
            local okJson2, data2 = pcall(function()
                return HttpService:JSONDecode(rawBackup)
            end)
            if okJson2 and type(data2) == "table" and data2.success then
                local city = data2.city or data2.region or ""
                local cc = data2.country_code or NetworkInfo.Region
                NetworkInfo.Region = (city ~= "" and (city .. ", " .. cc)) or cc
                NetworkInfo.IP = data2.ip or "Tidak Tersedia"
                if onUpdated then onUpdated() end
                return
            end
        end

        if NetworkInfo.IP == "Memuat..." then
            NetworkInfo.IP = "Local Client"
            if onUpdated then onUpdated() end
        end
    end)
end

--// ================= ANTI-AFK =================
bindConnection(LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

--// ================= HELPER TEKS OUTLINE PER HURUF (TANPA BACKGROUND) =================
local HasDrawing = (typeof(Drawing) == "table" or typeof(Drawing) == "function")

local function newOutlinedText(sizePx, color)
    if not HasDrawing then return nil end
    local ok, txt = pcall(function()
        local t = Drawing.new("Text")
        t.Size = sizePx
        t.Font = Drawing.Fonts.UI -- Font tipis bersih (tidak terlalu besar & tidak tebal)
        t.Color = color or Color3.fromRGB(248, 250, 252)
        t.Center = true
        t.Outline = true -- Outline hanya di setiap huruf, tanpa kotak background
        t.OutlineColor = Color3.fromRGB(10, 14, 24)
        t.Transparency = 1
        t.Visible = false
        return t
    end)
    return ok and txt or nil
end

--// ================= FITUR 1: ESP PEMAIN (NAMA, JARAK & AURA AVATAR) =================
local function clearPlayerVisuals(player)
    local entry = playerEspCache[player]
    if not entry then return end

    if entry.name then pcall(function() entry.name.Visible = false entry.name:Remove() end) end
    if entry.dist then pcall(function() entry.dist.Visible = false entry.dist:Remove() end) end
    if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
    if entry.billboard then pcall(function() entry.billboard:Destroy() end) end

    playerEspCache[player] = nil
end

local function removePlayerESP(player)
    clearPlayerVisuals(player)
    if playerEspConns[player] then
        for _, c in ipairs(playerEspConns[player]) do
            pcall(function() c:Disconnect() end)
        end
        playerEspConns[player] = nil
    end
end

local function createPlayerESP(player)
    if player == LocalPlayer then return end
    cacheFriendStatus(player)
    removePlayerESP(player)
    playerEspConns[player] = {}

    local function setupCharVisuals(char)
        if not char or not IsAlive then return end
        clearPlayerVisuals(player)

        local _, _, relColor = getPlayerRelation(player)
        local entry = {}

        -- 1. Aura pada Avatar (Highlight API)
        pcall(function()
            local hl = Instance.new("Highlight")
            hl.Name = "BimSakSin_AvatarAura"
            hl.Adornee = char
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillColor = relColor
            hl.OutlineColor = relColor
            hl.FillTransparency = 0.72
            hl.OutlineTransparency = 0.2
            hl.Enabled = false
            hl.Parent = char
            entry.highlight = hl
        end)

        -- 2. Teks Nama & Jarak (Outline per huruf saja, tanpa kotak background)
        if HasDrawing then
            entry.name = newOutlinedText(12, relColor)
            entry.dist = newOutlinedText(11, Color3.fromRGB(226, 232, 240))
        else
            -- Fallback BillboardGui transparan murni dengan UIStroke per huruf
            pcall(function()
                local head = char:WaitForChild("Head", 3)
                if head then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "BimSakSin_Tag"
                    bb.Adornee = head
                    bb.Size = UDim2.new(0, 160, 0, 34)
                    bb.StudsOffset = Vector3.new(0, 2.3, 0)
                    bb.AlwaysOnTop = true
                    bb.Enabled = false
                    bb.Parent = char

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "TagText"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1 -- Tanpa kotak background
                    lbl.Font = Enum.Font.Gotham -- Font reguler tidak tebal
                    lbl.TextSize = 11
                    lbl.TextColor3 = relColor
                    lbl.Text = player.DisplayName
                    lbl.Parent = bb

                    local stroke = Instance.new("UIStroke")
                    stroke.Thickness = 1.2
                    stroke.Color = Color3.fromRGB(10, 14, 24)
                    stroke.Parent = lbl

                    entry.billboard = bb
                end
            end)
        end

        playerEspCache[player] = entry
    end

    if player.Character then
        setupCharVisuals(player.Character)
    end

    table.insert(playerEspConns[player], player.CharacterAdded:Connect(setupCharVisuals))
    table.insert(playerEspConns[player], player.CharacterRemoving:Connect(function()
        clearPlayerVisuals(player)
    end))
end

for _, plr in ipairs(Players:GetPlayers()) do
    createPlayerESP(plr)
end
bindConnection(Players.PlayerAdded:Connect(createPlayerESP))
bindConnection(Players.PlayerRemoving:Connect(removePlayerESP))

--// ================= FITUR 2: GENERATOR SCANNER, ESP & AUTO GENERATOR =================
local PROGRESS_KEYS = { "Progress", "RepairProgress", "Repair", "Charge", "Percent", "Completion", "Value" }

local function getGeneratorBasePart(genObj)
    if not genObj or not genObj.Parent then return nil end
    if genObj:IsA("BasePart") then return genObj end
    if genObj:IsA("Model") then
        if genObj.PrimaryPart then return genObj.PrimaryPart end
        return genObj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function isGeneratorObject(obj)
    if not obj or not obj.Parent then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    if Players:GetPlayerFromCharacter(obj) or obj:FindFirstAncestorOfClass("Player") then
        return false
    end

    if CollectionService:HasTag(obj, "Generator") or CollectionService:HasTag(obj, "Gen") then
        return true
    end

    local lowerName = string.lower(obj.Name)
    if string.find(lowerName, "generator", 1, true) or lowerName == "gen" or string.match(lowerName, "^gen[%d_%-%s]*$") then
        local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
        local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
        local hasProgAttr = false
        for _, key in ipairs(PROGRESS_KEYS) do
            if obj:GetAttribute(key) ~= nil then
                hasProgAttr = true
                break
            end
        end
        local hasProgVal = false
        for _, key in ipairs(PROGRESS_KEYS) do
            local child = obj:FindFirstChild(key, true)
            if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
                hasProgVal = true
                break
            end
        end
        return hasPrompt or hasClick or hasProgAttr or hasProgVal or obj:IsA("Model")
    end

    return false
end

local function getGeneratorProgress(genObj)
    if not genObj or not genObj.Parent then return 0, false end

    local rawVal = nil
    local maxVal = 100

    -- 1. Cek Attribute API
    for _, key in ipairs(PROGRESS_KEYS) do
        local attr = genObj:GetAttribute(key)
        if type(attr) == "number" then
            rawVal = attr
            break
        elseif type(attr) == "boolean" and attr == true and (key == "Completed" or key == "Done") then
            return 100, true
        end
    end

    local maxAttr = genObj:GetAttribute("MaxProgress") or genObj:GetAttribute("MaxValue") or genObj:GetAttribute("Goal")
    if type(maxAttr) == "number" and maxAttr > 0 then
        maxVal = maxAttr
    end

    -- 2. Cek ValueBase API di dalam objek generator
    if rawVal == nil then
        for _, key in ipairs(PROGRESS_KEYS) do
            local valObj = genObj:FindFirstChild(key, true)
            if valObj and (valObj:IsA("NumberValue") or valObj:IsA("IntValue")) then
                rawVal = valObj.Value
                local parentMax = valObj.Parent and (valObj.Parent:FindFirstChild("MaxProgress") or valObj.Parent:FindFirstChild("MaxValue"))
                if parentMax and (parentMax:IsA("NumberValue") or parentMax:IsA("IntValue")) and parentMax.Value > 0 then
                    maxVal = parentMax.Value
                end
                break
            end
        end
    end

    -- 3. Cek status ProximityPrompt (jika prompt sudah nonaktif & sebelumnya ada progres)
    local prompt = genObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if rawVal == nil and prompt and not prompt.Enabled then
        return 100, true
    end

    if rawVal == nil then
        return 0, false
    end

    local pct = 0
    if maxVal == 100 and rawVal > 0 and rawVal <= 1 then
        pct = math.floor(rawVal * 100 + 0.5)
    else
        pct = math.floor((rawVal / maxVal) * 100 + 0.5)
    end

    pct = math.clamp(pct, 0, 100)
    return pct, (pct >= 100)
end

local function clearGeneratorVisual(genObj)
    local vis = generatorEspCache[genObj]
    if not vis then return end
    if vis.title then pcall(function() vis.title.Visible = false vis.title:Remove() end) end
    if vis.sub then pcall(function() vis.sub.Visible = false vis.sub:Remove() end) end
    if vis.highlight then pcall(function() vis.highlight:Destroy() end) end
    generatorEspCache[genObj] = nil
end

local function registerGenerator(obj)
    if generatorCache[obj] or not isGeneratorObject(obj) then return end
    local basePart = getGeneratorBasePart(obj)
    if not basePart then return end

    generatorCache[obj] = basePart

    local vis = {}
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "BimSakSin_GenAura"
        hl.Adornee = obj
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = Color3.fromRGB(251, 191, 36)
        hl.OutlineColor = Color3.fromRGB(251, 191, 36)
        hl.FillTransparency = 0.78
        hl.OutlineTransparency = 0.3
        hl.Enabled = false
        hl.Parent = obj
        vis.highlight = hl
    end)

    if HasDrawing then
        vis.title = newOutlinedText(12, Color3.fromRGB(251, 191, 36))
        vis.sub = newOutlinedText(11, Color3.fromRGB(226, 232, 240))
    end

    generatorEspCache[obj] = vis
end

local function unregisterGenerator(obj)
    if generatorCache[obj] then
        generatorCache[obj] = nil
    end
    clearGeneratorVisual(obj)
end

-- Inisialisasi awal & event-driven listener untuk generator
task.spawn(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isGeneratorObject(obj) then
            registerGenerator(obj)
        end
    end
end)

bindConnection(Workspace.DescendantAdded:Connect(function(obj)
    if IsAlive and isGeneratorObject(obj) then
        task.defer(registerGenerator, obj)
    end
end))

bindConnection(Workspace.DescendantRemoving:Connect(function(obj)
    if generatorCache[obj] then
        unregisterGenerator(obj)
    end
end))

local function getNearestIncompleteGenerator()
    local root = getRoot()
    if not root then return nil, nil, math.huge, 0 end

    local bestGen, bestPart, minDist, bestPct = nil, nil, math.huge, 0
    for genObj, part in pairs(generatorCache) do
        if genObj and genObj.Parent and part and part.Parent then
            local pct, isDone = getGeneratorProgress(genObj)
            if not isDone then
                local d = (part.Position - root.Position).Magnitude
                if d < minDist then
                    minDist = d
                    bestGen = genObj
                    bestPart = part
                    bestPct = pct
                end
            end
        end
    end
    return bestGen, bestPart, minDist, bestPct
end

local function tpToGenerator(genObj)
    local root = getRoot()
    local part = generatorCache[genObj] or getGeneratorBasePart(genObj)
    if root and part then
        root.CFrame = part.CFrame * CFrame.new(0, 2.5, 4)
        return true
    end
    return false
end

local function interactWithGenerator(genObj)
    if not genObj or not genObj.Parent then return false end

    -- 1. API ProximityPrompt
    local prompt = genObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        if typeof(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt)
            return true
        else
            pcall(function()
                prompt:InputHoldBegin()
                VirtualInputManager:SendKeyEvent(true, prompt.KeyboardKeyCode, false, game)
            end)
            return true
        end
    end

    -- 2. API ClickDetector
    local clickDet = genObj:FindFirstChildWhichIsA("ClickDetector", true)
    if clickDet and typeof(fireclickdetector) == "function" then
        pcall(fireclickdetector, clickDet)
        return true
    end

    return false
end

-- Loop Auto Generator (Ringan & Aman)
task.spawn(function()
    while IsAlive do
        task.wait(0.25)
        if Config.AutoGenerator then
            pcall(function()
                local root = getRoot()
                local hum = getHum()
                if not root or not hum or hum.Health <= 0 then return end

                local genObj, part, dist = getNearestIncompleteGenerator()
                if genObj and part then
                    if Config.AutoTPGenerator and dist > 10 then
                        root.CFrame = part.CFrame * CFrame.new(0, 2, 3.8)
                        task.wait(0.1)
                    end
                    if (part.Position - root.Position).Magnitude <= 18 then
                        interactWithGenerator(genObj)
                    end
                end
            end)
        end
    end
end)

--// ================= RENDER LOOP ESP (PEMAIN & GENERATOR) =================
bindConnection(RunService.RenderStepped:Connect(function()
    if not IsAlive then return end
    local cam = Workspace.CurrentCamera
    local myRoot = getRoot()

    -- A. Render Player ESP
    if not Config.PlayerESP then
        if not playerEspCleared then
            for _, esp in pairs(playerEspCache) do
                if esp.name then esp.name.Visible = false end
                if esp.dist then esp.dist.Visible = false end
                if esp.highlight then esp.highlight.Enabled = false end
                if esp.billboard then esp.billboard.Enabled = false end
            end
            playerEspCleared = true
        end
    elseif cam and myRoot then
        playerEspCleared = false
        for plr, esp in pairs(playerEspCache) do
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local isEnemy, roleTag, roleColor = getPlayerRelation(plr)

            local visible = (root ~= nil) and (hum ~= nil) and (hum.Health > 0)
            if visible and Config.EnemyOnlyESP and not isEnemy then
                visible = false
            end

            if visible then
                if esp.highlight then
                    esp.highlight.Enabled = true
                    esp.highlight.FillColor = roleColor
                    esp.highlight.OutlineColor = roleColor
                end

                local distMeters = math.floor((root.Position - myRoot.Position).Magnitude)

                if HasDrawing and esp.name and esp.dist then
                    local targetPos = (head and head.Position or root.Position) + Vector3.new(0, 1.35, 0)
                    local pos, onScreen = cam:WorldToViewportPoint(targetPos)
                    if onScreen and pos.Z > 0 then
                        esp.name.Color = roleColor
                        esp.name.Text = "[" .. roleTag .. "] " .. plr.DisplayName
                        esp.name.Position = Vector2.new(pos.X, pos.Y - 14)
                        esp.name.Visible = true

                        esp.dist.Text = tostring(distMeters) .. "m"
                        esp.dist.Position = Vector2.new(pos.X, pos.Y)
                        esp.dist.Visible = true
                    else
                        esp.name.Visible = false
                        esp.dist.Visible = false
                    end
                elseif esp.billboard then
                    esp.billboard.Enabled = true
                    local tagText = esp.billboard:FindFirstChild("TagText")
                    if tagText then
                        tagText.TextColor3 = roleColor
                        tagText.Text = "[" .. roleTag .. "] " .. plr.DisplayName .. "\n" .. tostring(distMeters) .. "m"
                    end
                end
            else
                if esp.highlight then esp.highlight.Enabled = false end
                if esp.name then esp.name.Visible = false end
                if esp.dist then esp.dist.Visible = false end
                if esp.billboard then esp.billboard.Enabled = false end
            end
        end
    end

    -- B. Render Generator ESP (Jarak & Proses Pengerjaan)
    if not Config.GeneratorESP then
        if not generatorEspCleared then
            for _, vis in pairs(generatorEspCache) do
                if vis.title then vis.title.Visible = false end
                if vis.sub then vis.sub.Visible = false end
                if vis.highlight then vis.highlight.Enabled = false end
            end
            generatorEspCleared = true
        end
    elseif cam and myRoot then
        generatorEspCleared = false
        for genObj, part in pairs(generatorCache) do
            local vis = generatorEspCache[genObj]
            if vis then
                if genObj and genObj.Parent and part and part.Parent then
                    local pct, isDone = getGeneratorProgress(genObj)
                    local genColor = isDone and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(251, 191, 36)
                    local distMeters = math.floor((part.Position - myRoot.Position).Magnitude)

                    if vis.highlight then
                        vis.highlight.Enabled = true
                        vis.highlight.FillColor = genColor
                        vis.highlight.OutlineColor = genColor
                    end

                    if vis.title and vis.sub then
                        local pos, onScreen = cam:WorldToViewportPoint(part.Position + Vector3.new(0, 2.2, 0))
                        if onScreen and pos.Z > 0 then
                            vis.title.Color = genColor
                            vis.title.Text = isDone and "Generator • SELESAI (100%)" or ("Generator • " .. tostring(pct) .. "%")
                            vis.title.Position = Vector2.new(pos.X, pos.Y - 13)
                            vis.title.Visible = true

                            vis.sub.Text = tostring(distMeters) .. "m"
                            vis.sub.Position = Vector2.new(pos.X, pos.Y)
                            vis.sub.Visible = true
                        else
                            vis.title.Visible = false
                            vis.sub.Visible = false
                        end
                    end
                else
                    if vis.highlight then vis.highlight.Enabled = false end
                    if vis.title then vis.title.Visible = false end
                    if vis.sub then vis.sub.Visible = false end
                end
            end
        end
    end
end))

--// ================= FITUR 3: MOVEMENT (FLY, NOCLIP, SPEED) =================
local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if bodyVelocity then
        pcall(function() bodyVelocity:Destroy() end)
        bodyVelocity = nil
    end
    if bodyGyro then
        pcall(function() bodyGyro:Destroy() end)
        bodyGyro = nil
    end
    local hum = getHum()
    if hum then
        hum.PlatformStand = false
    end
end

local function startFly()
    stopFly()
    local root = getRoot()
    local hum = getHum()
    if not root or not hum then return end

    hum.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "BimSakSin_FlyVel"
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "BimSakSin_FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 15000
    bodyGyro.D = 500
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not Config.Fly or not IsAlive then
            stopFly()
            return
        end

        local curRoot = getRoot()
        local curHum = getHum()
        local cam = Workspace.CurrentCamera
        if not curRoot or not curHum or not cam or not bodyVelocity or not bodyGyro then
            return
        end

        local direction = Vector3.zero
        local forward = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector

        if not UIS:GetFocusedTextBox() then
            if UIS:IsKeyDown(Enum.KeyCode.W) then direction += forward end
            if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= forward end
            if UIS:IsKeyDown(Enum.KeyCode.D) then direction += right end
            if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= right end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.new(0, 1, 0) end
        end

        if direction.Magnitude == 0 and curHum.MoveDirection.Magnitude > 0 then
            direction = curHum.MoveDirection
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        bodyVelocity.Velocity = direction * Config.FlySpeed
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function restoreNoclip()
    for part, originalCollide in pairs(noclipCache) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CanCollide = originalCollide
        end
    end
    table.clear(noclipCache)
end

bindConnection(RunService.Stepped:Connect(function()
    if not IsAlive then return end
    if Config.Noclip then
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if noclipCache[part] == nil then
                        noclipCache[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end
    elseif next(noclipCache) ~= nil then
        restoreNoclip()
    end
end))

--// ================= FITUR 4: TELEPORT =================
local function tpToPlayer(targetPlayer)
    local myRoot = getRoot()
    if not myRoot or not targetPlayer or not targetPlayer.Character then return false end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3.2)
        return true
    end
    return false
end

local function tpNearestPlayer(onlyEnemies)
    local myRoot = getRoot()
    if not myRoot then return nil end
    local nearestPlr, minDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local isEnemy = getPlayerRelation(plr)
            if not onlyEnemies or isEnemy then
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                local h = plr.Character:FindFirstChildOfClass("Humanoid")
                if r and h and h.Health > 0 then
                    local d = (r.Position - myRoot.Position).Magnitude
                    if d < minDist then
                        minDist = d
                        nearestPlr = plr
                    end
                end
            end
        end
    end

    if nearestPlr and tpToPlayer(nearestPlr) then
        return nearestPlr.DisplayName
    end
    return nil
end

local function tpSpawn()
    local myRoot = getRoot()
    if not myRoot then return false end
    local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawnLoc then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("SpawnLocation") then
                spawnLoc = obj
                break
            end
        end
    end
    if spawnLoc then
        myRoot.CFrame = spawnLoc.CFrame * CFrame.new(0, 5, 0)
        return true
    end
    return false
end

--// ================= RESPAWN HANDLER =================
bindConnection(LocalPlayer.CharacterAdded:Connect(function()
    table.clear(noclipCache)
    task.wait(0.6)
    if not IsAlive then return end

    if Config.Fly then
        startFly()
    end
    local hum = getHum()
    if hum then
        hum.WalkSpeed = Config.Speed
    end
end))

--// =========================================================================
--// UI PANEL: BIMSAKSIN HUB (TRANSPARAN BENING TANPA SPONSOR)
--// =========================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHub_" .. tostring(math.random(10000, 99999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function tween(obj, duration, props, style, dir)
    local info = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Builder Emblem Logo ☠️ 3D HD
local function create3DSkullEmblem(parent, sizePx, iconSize)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, sizePx, 0, sizePx)
    container.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
    container.BackgroundTransparency = 0.25
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.25
    stroke.Parent = container

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(244, 63, 94))
    })
    strokeGrad.Rotation = 45
    strokeGrad.Parent = stroke

    local skullShadow = Instance.new("TextLabel")
    skullShadow.Size = UDim2.new(1, 0, 1, 0)
    skullShadow.Position = UDim2.new(0, 2, 0, 3)
    skullShadow.BackgroundTransparency = 1
    skullShadow.Text = "☠️"
    skullShadow.TextSize = iconSize
    skullShadow.Font = Enum.Font.GothamBlack
    skullShadow.TextColor3 = Color3.fromRGB(10, 15, 28)
    skullShadow.TextTransparency = 0.35
    skullShadow.Parent = container

    local skullRim = Instance.new("TextLabel")
    skullRim.Size = UDim2.new(1, 0, 1, 0)
    skullRim.Position = UDim2.new(0, -1, 0, -1)
    skullRim.BackgroundTransparency = 1
    skullRim.Text = "☠️"
    skullRim.TextSize = iconSize
    skullRim.Font = Enum.Font.GothamBlack
    skullRim.TextColor3 = Color3.fromRGB(56, 189, 248)
    skullRim.TextTransparency = 0.55
    skullRim.Parent = container

    local skullMain = Instance.new("TextLabel")
    skullMain.Size = UDim2.new(1, 0, 1, 0)
    skullMain.Position = UDim2.new(0, 0, 0, 0)
    skullMain.BackgroundTransparency = 1
    skullMain.Text = "☠️"
    skullMain.TextSize = iconSize
    skullMain.Font = Enum.Font.GothamBlack
    skullMain.TextColor3 = Color3.fromRGB(255, 255, 255)
    skullMain.Parent = container

    return container, skullMain, strokeGrad
end

-- Drag Handler Halus (Klik vs Geser)
local function makeSmoothDraggable(handle, target, onClick)
    local dragging = false
    local dragStart = Vector2.zero
    local startPos = UDim2.new()
    local movedDistance = 0

    bindConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = target.Position
            movedDistance = 0
        end
    end))

    bindConnection(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            movedDistance = delta.Magnitude
            if movedDistance >= 4 then
                local nextPos = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
                tween(target, 0.08, { Position = nextPos }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end
        end
    end))

    bindConnection(UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if movedDistance < 6 and onClick then
                onClick()
            end
        end
    end))
end

--// ================= FLOATING TOGGLE BUTTON (LOGO ☠️ 3D HD) =================
local FloatingDock = Instance.new("Frame")
FloatingDock.Name = "FloatingSkullToggle"
FloatingDock.Size = UDim2.new(0, 60, 0, 60)
FloatingDock.Position = UDim2.new(0, 24, 0.5, -30)
FloatingDock.BackgroundTransparency = 1
FloatingDock.ZIndex = 20
FloatingDock.Parent = ScreenGui

local dockScale = Instance.new("UIScale")
dockScale.Scale = 1
dockScale.Parent = FloatingDock

local DockGlow = Instance.new("Frame")
DockGlow.Size = UDim2.new(1, 12, 1, 12)
DockGlow.Position = UDim2.new(0, -6, 0, -6)
DockGlow.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
DockGlow.BackgroundTransparency = 0.84
DockGlow.BorderSizePixel = 0
DockGlow.ZIndex = 19
DockGlow.Parent = FloatingDock

local dockGlowCorner = Instance.new("UICorner")
dockGlowCorner.CornerRadius = UDim.new(1, 0)
dockGlowCorner.Parent = DockGlow

local FloatingEmblem, FloatingSkullText, FloatingGrad = create3DSkullEmblem(FloatingDock, 60, 30)
FloatingEmblem.ZIndex = 21

local FloatingHitbox = Instance.new("TextButton")
FloatingHitbox.Size = UDim2.new(1, 0, 1, 0)
FloatingHitbox.BackgroundTransparency = 1
FloatingHitbox.Text = ""
FloatingHitbox.ZIndex = 25
FloatingHitbox.Parent = FloatingDock

bindConnection(FloatingHitbox.MouseEnter:Connect(function()
    tween(dockScale, 0.22, { Scale = 1.08 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(DockGlow, 0.22, { BackgroundTransparency = 0.68 })
end))

bindConnection(FloatingHitbox.MouseLeave:Connect(function()
    tween(dockScale, 0.22, { Scale = 1.0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tween(DockGlow, 0.22, { BackgroundTransparency = 0.84 })
end))

--// ================= PANEL UTAMA: TRANSPARAN BENING =================
local MainPanel = Instance.new("Frame")
MainPanel.Name = "BimSakSinMainPanel"
MainPanel.Size = UDim2.new(0, 440, 0, 380)
MainPanel.Position = UDim2.new(0.5, -220, 0.5, -190)
MainPanel.BackgroundColor3 = Color3.fromRGB(12, 17, 29)
MainPanel.BackgroundTransparency = 0.32 -- Transparan bening
MainPanel.BorderSizePixel = 0
MainPanel.ClipsDescendants = true
MainPanel.ZIndex = 10
MainPanel.Parent = ScreenGui

local panelScale = Instance.new("UIScale")
panelScale.Scale = 0.88
panelScale.Parent = MainPanel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = MainPanel

local glassGradient = Instance.new("UIGradient")
glassGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 39, 64)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 23, 42)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24))
})
glassGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(0.5, 0.3),
    NumberSequenceKeypoint.new(1, 0.22)
})
glassGradient.Rotation = 135
glassGradient.Parent = MainPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 1.4
panelStroke.Color = Color3.fromRGB(255, 255, 255)
panelStroke.Transparency = 0.6
panelStroke.Parent = MainPanel

local panelStrokeGrad = Instance.new("UIGradient")
panelStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(125, 211, 252)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(192, 132, 252)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 189, 248))
})
panelStrokeGrad.Rotation = 35
panelStrokeGrad.Parent = panelStroke

local TopGlassReflection = Instance.new("Frame")
TopGlassReflection.Size = UDim2.new(1, -32, 0, 1)
TopGlassReflection.Position = UDim2.new(0, 16, 0, 1)
TopGlassReflection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopGlassReflection.BackgroundTransparency = 0.68
TopGlassReflection.BorderSizePixel = 0
TopGlassReflection.ZIndex = 12
TopGlassReflection.Parent = MainPanel

--// ================= HEADER PANEL (BIMSAKSIN HUB + REGION/IP) =================
local Header = Instance.new("Frame")
Header.Name = "HeaderBar"
Header.Size = UDim2.new(1, 0, 0, 56)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BackgroundTransparency = 0.95
Header.BorderSizePixel = 0
Header.ZIndex = 12
Header.Parent = MainPanel

local HeaderDivider = Instance.new("Frame")
HeaderDivider.Size = UDim2.new(1, -24, 0, 1)
HeaderDivider.Position = UDim2.new(0, 12, 1, -1)
HeaderDivider.BackgroundColor3 = Color3.fromRGB(148, 163, 184)
HeaderDivider.BackgroundTransparency = 0.84
HeaderDivider.BorderSizePixel = 0
HeaderDivider.ZIndex = 12
HeaderDivider.Parent = Header

-- Emblem ☠️ 3D HD Sisi Kiri Panel
local LeftEmblem, LeftSkullText = create3DSkullEmblem(Header, 34, 18)
LeftEmblem.Position = UDim2.new(0, 14, 0.5, -17)
LeftEmblem.ZIndex = 14

-- Judul "BimSakSin Hub" + Bar Region & IP
local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(1, -162, 1, 0)
TitleContainer.Position = UDim2.new(0, 56, 0, 0)
TitleContainer.BackgroundTransparency = 1
TitleContainer.ZIndex = 13
TitleContainer.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 22)
TitleLabel.Position = UDim2.new(0, 0, 0, 7)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "BimSakSin Hub"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 17
TitleLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
TitleLabel.ZIndex = 14
TitleLabel.Parent = TitleContainer

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(125, 211, 252)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 132, 252))
})
titleGrad.Parent = TitleLabel

local RegionIpBtn = Instance.new("TextButton")
RegionIpBtn.Size = UDim2.new(1, 0, 0, 18)
RegionIpBtn.Position = UDim2.new(0, 0, 0, 31)
RegionIpBtn.BackgroundTransparency = 1
RegionIpBtn.Text = "🌐 Region: Mendeteksi... | IP: Memuat..."
RegionIpBtn.TextXAlignment = Enum.TextXAlignment.Left
RegionIpBtn.Font = Enum.Font.Gotham
RegionIpBtn.TextSize = 11
RegionIpBtn.TextColor3 = Color3.fromRGB(125, 211, 252)
RegionIpBtn.ZIndex = 15
RegionIpBtn.Parent = TitleContainer

local function updateRegionIpDisplay()
    if not RegionIpBtn or not RegionIpBtn.Parent then return end
    local shownIP = NetworkInfo.Masked and maskIPAddress(NetworkInfo.IP) or NetworkInfo.IP
    local pingStr = ""
    pcall(function()
        local pingItem = Stats.Network.ServerStatsItem["Data Ping"]
        if pingItem then
            pingStr = " • " .. tostring(math.floor(pingItem:GetValue())) .. "ms"
        end
    end)
    RegionIpBtn.Text = "🌐 Region: " .. NetworkInfo.Region .. " | IP: " .. shownIP .. pingStr
end

bindConnection(RegionIpBtn.MouseButton1Click:Connect(function()
    NetworkInfo.Masked = not NetworkInfo.Masked
    updateRegionIpDisplay()
end))

fetchRegionAndIP(updateRegionIpDisplay)

-- Emblem ☠️ 3D HD Sisi Kanan Panel
local RightEmblem, RightSkullText = create3DSkullEmblem(Header, 34, 18)
RightEmblem.Position = UDim2.new(1, -86, 0.5, -17)
RightEmblem.ZIndex = 14

-- Tombol Minimize ke Floating Logo ☠️
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -15)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.BackgroundTransparency = 0.92
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 13
MinimizeBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
MinimizeBtn.ZIndex = 15
MinimizeBtn.Parent = Header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = MinimizeBtn

local minStroke = Instance.new("UIStroke")
minStroke.Thickness = 1
minStroke.Color = Color3.fromRGB(255, 255, 255)
minStroke.Transparency = 0.8
minStroke.Parent = MinimizeBtn

bindConnection(MinimizeBtn.MouseEnter:Connect(function()
    tween(MinimizeBtn, 0.18, { BackgroundTransparency = 0.8, TextColor3 = Color3.fromRGB(56, 189, 248) })
end))
bindConnection(MinimizeBtn.MouseLeave:Connect(function()
    tween(MinimizeBtn, 0.18, { BackgroundTransparency = 0.92, TextColor3 = Color3.fromRGB(226, 232, 240) })
end))

--// ================= ANIMASI BUKA / TUTUP PANEL & LOGO ☠️ =================
local function setPanelState(open)
    IsPanelOpen = open
    if open then
        MainPanel.Visible = true
        tween(FloatingSkullText, 0.35, { Rotation = 360 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(dockScale, 0.25, { Scale = 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        panelScale.Scale = 0.86
        MainPanel.BackgroundTransparency = 0.78
        tween(panelScale, 0.34, { Scale = 1.0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(MainPanel, 0.28, { BackgroundTransparency = 0.32 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        LeftSkullText.Rotation = -25
        RightSkullText.Rotation = 25
        tween(LeftSkullText, 0.45, { Rotation = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(RightSkullText, 0.45, { Rotation = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        tween(FloatingSkullText, 0.35, { Rotation = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(dockScale, 0.28, { Scale = 1.0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        tween(panelScale, 0.22, { Scale = 0.86 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local closeTween = tween(MainPanel, 0.2, { BackgroundTransparency = 0.95 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        closeTween.Completed:Connect(function()
            if not IsPanelOpen and MainPanel then
                MainPanel.Visible = false
            end
        end)
    end
end

makeSmoothDraggable(FloatingHitbox, FloatingDock, function()
    setPanelState(not IsPanelOpen)
end)

makeSmoothDraggable(Header, MainPanel, nil)

bindConnection(MinimizeBtn.MouseButton1Click:Connect(function()
    setPanelState(false)
end))

-- Animasi melayang halus 3D pada logo ☠️ + pembaruan ping & daftar generator
local refreshGeneratorListCallback = nil

task.spawn(function()
    local phase = 0
    local secTimer = 0
    while IsAlive do
        local dt = task.wait(0.03)
        phase += dt * 2.4
        secTimer += dt

        local waveY = math.sin(phase) * 2.0
        local tilt = math.cos(phase * 0.8) * 5

        if FloatingSkullText and FloatingSkullText.Parent then
            FloatingSkullText.Position = UDim2.new(0, 0, 0, waveY)
            FloatingGrad.Rotation = (phase * 28) % 360
        end
        if IsPanelOpen and LeftSkullText and RightSkullText then
            LeftSkullText.Position = UDim2.new(0, 0, 0, waveY * 0.65)
            LeftSkullText.Rotation = tilt
            RightSkullText.Position = UDim2.new(0, 0, 0, -waveY * 0.65)
            RightSkullText.Rotation = -tilt
        end

        if secTimer >= 2.0 then
            secTimer = 0
            updateRegionIpDisplay()
            if IsPanelOpen and refreshGeneratorListCallback then
                pcall(refreshGeneratorListCallback)
            end
        end
    end
end)

--// ================= NAVIGASI 4 TAB SESUAI KEGUNAAN =================
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -28, 0, 32)
TabBar.Position = UDim2.new(0, 14, 0, 64)
TabBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TabBar.BackgroundTransparency = 0.95
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 12
TabBar.Parent = MainPanel

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 9)
tabBarCorner.Parent = TabBar

local tabBarStroke = Instance.new("UIStroke")
tabBarStroke.Thickness = 1
tabBarStroke.Color = Color3.fromRGB(255, 255, 255)
tabBarStroke.Transparency = 0.86
tabBarStroke.Parent = TabBar

local tabNames = { "👁️ ESP", "⚙️ Generator", "🚀 Movement", "🌐 Teleport" }
local tabCount = #tabNames

local ActiveTabIndicator = Instance.new("Frame")
ActiveTabIndicator.Size = UDim2.new(1 / tabCount, -6, 1, -6)
ActiveTabIndicator.Position = UDim2.new(0, 3, 0, 3)
ActiveTabIndicator.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
ActiveTabIndicator.BackgroundTransparency = 0.8
ActiveTabIndicator.BorderSizePixel = 0
ActiveTabIndicator.ZIndex = 13
ActiveTabIndicator.Parent = TabBar

local indCorner = Instance.new("UICorner")
indCorner.CornerRadius = UDim.new(0, 7)
indCorner.Parent = ActiveTabIndicator

local indStroke = Instance.new("UIStroke")
indStroke.Thickness = 1
indStroke.Color = Color3.fromRGB(125, 211, 252)
indStroke.Transparency = 0.48
indStroke.Parent = ActiveTabIndicator

local ContentHolder = Instance.new("Frame")
ContentHolder.Name = "TabContentHolder"
ContentHolder.Size = UDim2.new(1, -28, 1, -108)
ContentHolder.Position = UDim2.new(0, 14, 0, 102)
ContentHolder.BackgroundTransparency = 1
ContentHolder.ClipsDescendants = true
ContentHolder.ZIndex = 12
ContentHolder.Parent = MainPanel

local tabButtons = {}
local tabPages = {}

local function switchTab(index)
    local targetX = (index - 1) / tabCount
    tween(ActiveTabIndicator, 0.26, {
        Position = UDim2.new(targetX, 3, 0, 3)
    }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    for i, btn in ipairs(tabButtons) do
        local isSelected = (i == index)
        tween(btn, 0.2, {
            TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
        })
        local page = tabPages[i]
        if isSelected then
            page.Visible = true
            page.Position = UDim2.new(0, 12, 0, 0)
            tween(page, 0.24, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        else
            page.Visible = false
        end
    end
end

for i, label in ipairs(tabNames) do
    local tBtn = Instance.new("TextButton")
    tBtn.Size = UDim2.new(1 / tabCount, 0, 1, 0)
    tBtn.Position = UDim2.new((i - 1) / tabCount, 0, 0, 0)
    tBtn.BackgroundTransparency = 1
    tBtn.Text = label
    tBtn.Font = Enum.Font.GothamSemibold
    tBtn.TextSize = 11
    tBtn.TextColor3 = (i == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
    tBtn.ZIndex = 15
    tBtn.Parent = TabBar
    tabButtons[i] = tBtn

    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. tostring(i)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(125, 211, 252)
    page.ScrollBarImageTransparency = 0.5
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = (i == 1)
    page.ZIndex = 13
    page.Parent = ContentHolder

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 4)
    pad.Parent = page

    tabPages[i] = page

    bindConnection(tBtn.MouseButton1Click:Connect(function()
        switchTab(i)
    end))
end

--// ================= KOMPONEN UI REUSABLE =================
local function addGlassCard(parent, height, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.94
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.ZIndex = 14
    card.Parent = parent

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 10)
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Thickness = 1
    cStroke.Color = Color3.fromRGB(255, 255, 255)
    cStroke.Transparency = 0.86
    cStroke.Parent = card

    return card, cStroke
end

local function createToggleControl(parent, title, desc, configKey, order, onToggle)
    local card, cardStroke = addGlassCard(parent, 46, order)

    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(1, -74, 0, 19)
    lblTitle.Position = UDim2.new(0, 12, 0, 6)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = title
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblTitle.Font = Enum.Font.GothamSemibold
    lblTitle.TextSize = 12
    lblTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
    lblTitle.ZIndex = 15
    lblTitle.Parent = card

    local lblDesc = Instance.new("TextLabel")
    lblDesc.Size = UDim2.new(1, -74, 0, 14)
    lblDesc.Position = UDim2.new(0, 12, 0, 25)
    lblDesc.BackgroundTransparency = 1
    lblDesc.Text = desc
    lblDesc.TextXAlignment = Enum.TextXAlignment.Left
    lblDesc.Font = Enum.Font.Gotham
    lblDesc.TextSize = 10
    lblDesc.TextColor3 = Color3.fromRGB(148, 163, 184)
    lblDesc.ZIndex = 15
    lblDesc.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 44, 0, 22)
    track.Position = UDim2.new(1, -56, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
    track.BackgroundTransparency = 0.25
    track.BorderSizePixel = 0
    track.ZIndex = 15
    track.Parent = card

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(226, 232, 240)
    knob.BorderSizePixel = 0
    knob.ZIndex = 16
    knob.Parent = track

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 17
    hit.Parent = card

    local function updateVisual(state, instant)
        local dur = instant and 0 or 0.22
        if state then
            tween(track, dur, { BackgroundColor3 = Color3.fromRGB(14, 165, 233), BackgroundTransparency = 0.1 })
            tween(knob, dur, { Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            tween(cardStroke, dur, { Color = Color3.fromRGB(56, 189, 248), Transparency = 0.48 })
        else
            tween(track, dur, { BackgroundColor3 = Color3.fromRGB(51, 65, 85), BackgroundTransparency = 0.25 })
            tween(knob, dur, { Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(226, 232, 240) })
            tween(cardStroke, dur, { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.86 })
        end
    end

    updateVisual(Config[configKey], true)

    bindConnection(hit.MouseEnter:Connect(function()
        tween(card, 0.18, { BackgroundTransparency = 0.89 })
    end))
    bindConnection(hit.MouseLeave:Connect(function()
        tween(card, 0.18, { BackgroundTransparency = 0.94 })
    end))

    bindConnection(hit.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        updateVisual(Config[configKey], false)
        if onToggle then
            pcall(onToggle, Config[configKey])
        end
    end))
end

local function createSliderControl(parent, title, minVal, maxVal, configKey, order, onChanged)
    local card = addGlassCard(parent, 52, order)

    local lblTitle = Instance.new("TextLabel")
    lblTitle.Size = UDim2.new(0.65, 0, 0, 18)
    lblTitle.Position = UDim2.new(0, 12, 0, 6)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = title
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblTitle.Font = Enum.Font.GothamSemibold
    lblTitle.TextSize = 12
    lblTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
    lblTitle.ZIndex = 15
    lblTitle.Parent = card

    local lblValue = Instance.new("TextLabel")
    lblValue.Size = UDim2.new(0.35, -12, 0, 18)
    lblValue.Position = UDim2.new(0.65, 0, 0, 6)
    lblValue.BackgroundTransparency = 1
    lblValue.Text = tostring(Config[configKey])
    lblValue.TextXAlignment = Enum.TextXAlignment.Right
    lblValue.Font = Enum.Font.GothamBold
    lblValue.TextSize = 12
    lblValue.TextColor3 = Color3.fromRGB(56, 189, 248)
    lblValue.ZIndex = 15
    lblValue.Parent = card

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -24, 0, 7)
    barBg.Position = UDim2.new(0, 12, 0, 32)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    barBg.BackgroundTransparency = 0.2
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 15
    barBg.Parent = card

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = barBg

    local initialRatio = math.clamp((Config[configKey] - minVal) / (maxVal - minVal), 0, 1)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(initialRatio, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 16
    barFill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = barFill

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
    })
    fillGrad.Parent = barFill

    local sliding = false

    local function applyFromInput(inputPos)
        local relX = math.clamp((inputPos.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local newVal = math.floor(minVal + (maxVal - minVal) * relX + 0.5)
        Config[configKey] = newVal
        lblValue.Text = tostring(newVal)
        barFill.Size = UDim2.new(relX, 0, 1, 0)
        if onChanged then
            pcall(onChanged, newVal)
        end
    end

    bindConnection(barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            applyFromInput(input.Position)
        end
    end))

    bindConnection(UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            applyFromInput(input.Position)
        end
    end))

    bindConnection(UIS.InputEnded:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
        end
    end))
end

local function createActionButton(parent, text, accentColor, order, onClick)
    local card, stroke = addGlassCard(parent, 36, order)
    stroke.Color = accentColor
    stroke.Transparency = 0.65

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(248, 250, 252)
    btn.ZIndex = 16
    btn.Parent = card

    bindConnection(btn.MouseEnter:Connect(function()
        tween(card, 0.18, { BackgroundColor3 = accentColor, BackgroundTransparency = 0.84 })
        tween(stroke, 0.18, { Transparency = 0.35 })
    end))

    bindConnection(btn.MouseLeave:Connect(function()
        tween(card, 0.18, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94 })
        tween(stroke, 0.18, { Transparency = 0.65 })
    end))

    bindConnection(btn.MouseButton1Click:Connect(function()
        local origText = btn.Text
        if onClick then
            local statusMsg = onClick()
            if statusMsg then
                btn.Text = statusMsg
                task.delay(1.2, function()
                    if btn and btn.Parent then
                        btn.Text = origText
                    end
                end)
            end
        end
    end))

    return btn
end

--// ================= ISI TAB 1: ESP (PEMAIN & GENERATOR) =================
createToggleControl(
    tabPages[1],
    "Player ESP (Nama, Jarak & Aura Avatar)",
    "Font outline tipis tanpa kotak • Aura highlight avatar",
    "PlayerESP",
    1
)

createToggleControl(
    tabPages[1],
    "Team & Teman Check",
    "Bedakan otomatis Musuh, Satu Team & Teman Roblox",
    "TeamFriendCheck",
    2
)

createToggleControl(
    tabPages[1],
    "Filter Musuh Saja (Enemy Only)",
    "Hanya tampilkan ESP & aura pada pemain musuh",
    "EnemyOnlyESP",
    3
)

createToggleControl(
    tabPages[1],
    "Generator ESP (Jarak & Proses %)",
    "Tampilkan status pengerjaan, persentase & jarak",
    "GeneratorESP",
    4
)

--// ================= ISI TAB 2: GENERATOR =================
createToggleControl(
    tabPages[2],
    "Auto Generator (API Interact)",
    "Otomatis mengerjakan generator terdekat via Prompt API",
    "AutoGenerator",
    1
)

createToggleControl(
    tabPages[2],
    "Auto TP ke Generator Belum Selesai",
    "Otomatis berpindah ke generator berikutnya saat Auto aktif",
    "AutoTPGenerator",
    2
)

createActionButton(
    tabPages[2],
    "⚡ TP → Generator Terdekat (Belum Selesai)",
    Color3.fromRGB(251, 191, 36),
    3,
    function()
        local genObj, _, dist, pct = getNearestIncompleteGenerator()
        if genObj and tpToGenerator(genObj) then
            return "✅ TP Generator (" .. tostring(pct) .. "% • " .. tostring(math.floor(dist)) .. "m)"
        end
        return "⚠️ Tidak ada generator aktif"
    end
)

local genListContainer = Instance.new("Frame")
genListContainer.Size = UDim2.new(1, 0, 0, 0)
genListContainer.AutomaticSize = Enum.AutomaticSize.Y
genListContainer.BackgroundTransparency = 1
genListContainer.LayoutOrder = 4
genListContainer.ZIndex = 13
genListContainer.Parent = tabPages[2]

local genListLayout = Instance.new("UIListLayout")
genListLayout.Padding = UDim.new(0, 6)
genListLayout.SortOrder = Enum.SortOrder.LayoutOrder
genListLayout.Parent = genListContainer

refreshGeneratorListCallback = function()
    if not genListContainer or not genListContainer.Parent then return end
    for _, child in ipairs(genListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local myRoot = getRoot()
    local items = {}
    for genObj, part in pairs(generatorCache) do
        if genObj and genObj.Parent and part and part.Parent then
            local pct, isDone = getGeneratorProgress(genObj)
            local dist = myRoot and math.floor((part.Position - myRoot.Position).Magnitude) or 0
            table.insert(items, { obj = genObj, pct = pct, done = isDone, dist = dist })
        end
    end

    table.sort(items, function(a, b)
        return a.dist < b.dist
    end)

    if #items == 0 then
        local emptyCard = addGlassCard(genListContainer, 34, 1)
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 1, 0)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "Tidak ada generator terdeteksi di map ini"
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.TextSize = 11
        emptyLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
        emptyLbl.ZIndex = 15
        emptyLbl.Parent = emptyCard
        return
    end

    for idx, info in ipairs(items) do
        local accent = info.done and COLOR_TEAM or Color3.fromRGB(251, 191, 36)
        local statusTxt = info.done and "SELESAI" or (tostring(info.pct) .. "%")
        createActionButton(
            genListContainer,
            "⚙️ Generator #" .. tostring(idx) .. " • [" .. statusTxt .. "] • " .. tostring(info.dist) .. "m (Klik TP)",
            accent,
            idx,
            function()
                return tpToGenerator(info.obj) and "✅ Teleported ke Generator #" .. tostring(idx) or "⚠️ Gagal TP"
            end
        )
    end
end

refreshGeneratorListCallback()

--// ================= ISI TAB 3: MOVEMENT =================
createToggleControl(
    tabPages[3],
    "3D Free Fly",
    "WASD bergerak • Space naik • LeftCtrl turun",
    "Fly",
    1,
    function(state)
        if state then startFly() else stopFly() end
    end
)

createToggleControl(
    tabPages[3],
    "Smart Noclip",
    "Tembus dinding & memulihkan kolisi saat OFF",
    "Noclip",
    2,
    function(state)
        if not state then restoreNoclip() end
    end
)

createSliderControl(
    tabPages[3],
    "WalkSpeed (Kecepatan Lari)",
    16,
    200,
    "Speed",
    3,
    function(val)
        local hum = getHum()
        if hum then
            hum.WalkSpeed = val
        end
    end
)

createSliderControl(
    tabPages[3],
    "FlySpeed (Kecepatan Terbang)",
    20,
    250,
    "FlySpeed",
    4
)

--// ================= ISI TAB 4: TELEPORT =================
createActionButton(
    tabPages[4],
    "⚔️ TP → Musuh Terdekat",
    COLOR_ENEMY,
    1,
    function()
        local targetName = tpNearestPlayer(true)
        return targetName and ("✅ TP ke Musuh: " .. targetName) or "⚠️ Tidak ada musuh aktif"
    end
)

createActionButton(
    tabPages[4],
    "🎯 TP → Player Terdekat (Semua)",
    COLOR_FRIEND,
    2,
    function()
        local targetName = tpNearestPlayer(false)
        return targetName and ("✅ TP ke " .. targetName) or "⚠️ Tidak ada player lain"
    end
)

createActionButton(
    tabPages[4],
    "🏠 TP → Spawn Location",
    Color3.fromRGB(168, 85, 247),
    3,
    function()
        return tpSpawn() and "✅ Berhasil TP ke Spawn" or "⚠️ Spawn tidak ditemukan"
    end
)

local playerListContainer = Instance.new("Frame")
playerListContainer.Size = UDim2.new(1, 0, 0, 0)
playerListContainer.AutomaticSize = Enum.AutomaticSize.Y
playerListContainer.BackgroundTransparency = 1
playerListContainer.LayoutOrder = 4
playerListContainer.ZIndex = 13
playerListContainer.Parent = tabPages[4]

local pListLayout = Instance.new("UIListLayout")
pListLayout.Padding = UDim.new(0, 6)
pListLayout.SortOrder = Enum.SortOrder.LayoutOrder
pListLayout.Parent = playerListContainer

local function refreshPlayerList()
    if not playerListContainer or not playerListContainer.Parent then return end
    for _, child in ipairs(playerListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local idx = 1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local _, roleTag, roleColor = getPlayerRelation(plr)
            createActionButton(
                playerListContainer,
                "[" .. roleTag .. "] TP → " .. plr.DisplayName .. " (@" .. plr.Name .. ")",
                roleColor,
                idx,
                function()
                    return tpToPlayer(plr) and ("✅ Teleported ke " .. plr.DisplayName) or "⚠️ Karakter tidak aktif"
                end
            )
            idx += 1
        end
    end
end

refreshPlayerList()
bindConnection(Players.PlayerAdded:Connect(function()
    task.defer(refreshPlayerList)
end))
bindConnection(Players.PlayerRemoving:Connect(function()
    task.defer(refreshPlayerList)
end))
bindConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshPlayerList))

--// ================= REGISTRASI CLEANUP GLOBAL =================
local function Cleanup()
    IsAlive = false
    Config.AutoGenerator = false
    Config.Fly = false
    Config.Noclip = false
    Config.PlayerESP = false
    Config.GeneratorESP = false

    stopFly()
    restoreNoclip()

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    for plr in pairs(playerEspCache) do
        removePlayerESP(plr)
    end

    for genObj in pairs(generatorEspCache) do
        clearGeneratorVisual(genObj)
    end
    table.clear(generatorCache)

    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
end

pcall(function()
    if getgenv then
        getgenv().BimSakSinHubCleanup = Cleanup
    end
end)

setPanelState(true)
print("✅ BimSakSin Hub loaded!")
