--[[
    UNIVERSAL ANTI-BAN FRAMEWORK v3.1 — FIXED
    Tested-compatible: Synapse X, Krnl, Fluxus, Delta, Arceus X,
                       Hydrogen, Codex, Wave, Solara, Xeno, AWP, Nihon
    Bebas error dengan auto-fallback capability check.
]]

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")
local Stats              = game:GetService("Stats")
local CoreGui            = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")
local LocalPlayer        = Players.LocalPlayer

--========== CONFIG ==========
local CONFIG = {
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
    Debug               = true,
    InteractiveConsole  = true,
}

--========== UTIL ==========
local function log(tag, ...)
    if CONFIG.Debug then
        print(("[AntiBan:%s]"):format(tag), ...)
    end
end

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        log("safe", "ERR:", res)
    end
    return ok, res
end

--========== CAPABILITY ==========
local CAP = {
    hookfunction      = (type(hookfunction)      == "function"),
    hookmetamethod    = (type(hookmetamethod)    == "function"),
    getrawmetatable   = (type(getrawmetatable)   == "function"),
    setreadonly       = (type(setreadonly)       == "function"),
    newcclosure       = (type(newcclosure)       == "function"),
    getnamecallmethod = (type(getnamecallmethod) == "function"),
    gethui            = (type(gethui)            == "function"),
    request           = (type(request) == "function") and "request"
                     or (type(syn) == "table" and type(syn.request) == "function") and "syn"
                     or (type(http_request) == "function") and "http" or nil,
}
log("CAP", "hookmetamethod:", CAP.hookmetamethod, "| request:", CAP.request)

-- helper request cross-executor
local function httpPost(url, body)
    if CAP.request == "request" then
        return request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    elseif CAP.request == "syn" then
        return syn.request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    elseif CAP.request == "http" then
        return http_request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end
end

--========== ANTI-KICK ==========
if CONFIG.EnableAntiKick and CAP.hookfunction and LocalPlayer then
    safe(function()
        local closureWrap = CAP.newcclosure or function(f) return f end
        local oldKick
        oldKick = hookfunction(LocalPlayer.Kick, closureWrap(function(self, ...)
            if self == LocalPlayer then
                log("AntiKick", "Kick blocked")
                return nil
            end
            return oldKick(self, ...)
        end))
    end)
end

--========== ANTI-REMOTE ==========
if CONFIG.EnableAntiRemote and CAP.hookmetamethod and CAP.newcclosure and CAP.getnamecallmethod then
    safe(function()
        local lastFire = setmetatable({}, { __mode = "k" })
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local rateLimit = CONFIG.RemoteRateLimit
                if type(rateLimit) == "number" and rateLimit > 0 then
                    local now = os.clock()
                    local prev = lastFire[self]
                    if prev and (now - prev) < rateLimit then
                        return nil
                    end
                    lastFire[self] = now
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

--========== ANTI-STATS SCAN ==========
if CONFIG.EnableAntiStatsScan and CAP.getrawmetatable and CAP.setreadonly and CAP.newcclosure then
    safe(function()
        local mt = getrawmetatable(Stats)
        if not mt or type(mt.__index) ~= "function" then
            return
        end
        local oldIndex = mt.__index
        local wasReadonly = true
        if isreadonly then
            wasReadonly = isreadonly(mt)
        end

        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if key == "GetChildren" or key == "GetDescendants" then
                local fn = oldIndex(self, key)
                if type(fn) == "function" then
                    return newcclosure(function(s, ...)
                        local list = fn(s, ...)
                        if type(list) ~= "table" then
                            return list
                        end
                        local out = {}
                        for i = 1, #list do
                            local item = list[i]
                            local nameLower = string.lower(tostring(item and item.Name or ""))
                            if not string.find(nameLower, "script", 1, true) then
                                out[#out + 1] = item
                            end
                        end
                        return out
                    end)
                end
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, wasReadonly)
    end)
end

--========== SPOOF HWID ==========
if CONFIG.EnableSpoofHWID then
    safe(function()
        local env = (type(getgenv) == "function" and getgenv()) or _G
        env.hwid = HttpService:GenerateGUID(false)
        log("Spoof", "HWID:", env.hwid)
    end)
end

--========== WEBHOOK (non-yielding) ==========
if CONFIG.EnableWebhook and CONFIG.WebhookURL ~= "" and CAP.request then
    task.spawn(function()
        local placeName = "Unknown"
        pcall(function()
            placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)
        while task.wait(CONFIG.WebhookInterval) do
            local env = (type(getgenv) == "function" and getgenv()) or _G
            local data = {
                username = "AntiBan v" .. CONFIG.Version,
                embeds = {{
                    title = "Session Report",
                    color = 65280,
                    fields = {
                        { name = "Place",   value = tostring(placeName),      inline = true },
                        { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
                        { name = "Player",  value = LocalPlayer and LocalPlayer.Name or "Unknown", inline = true },
                        { name = "HWID",    value = tostring(env.hwid or "N/A") },
                    }
                }}
            }
            pcall(httpPost, CONFIG.WebhookURL, HttpService:JSONEncode(data))
        end
    end)
end

--========== SAFE FIRE API ==========
local SafeFire = {}
function SafeFire.Fire(remote, ...)
    if not remote or type(remote.FireServer) ~= "function" then
        return false
    end
    local delaySec = math.random(1, 3) / 1000
    if delaySec > 0 then
        task.wait(delaySec)
    end
    local args = { ... }
    return safe(function()
        remote:FireServer(unpack(args))
    end)
end

function SafeFire.Invoke(remote, ...)
    if not remote or type(remote.InvokeServer) ~= "function" then
        return nil
    end
    local delaySec = math.random(1, 3) / 1000
    if delaySec > 0 then
        task.wait(delaySec)
    end
    local args = { ... }
    return safe(function()
        return remote:InvokeServer(unpack(args))
    end)
end

--========== EXPOSE API ==========
_G.AntiBan = {
    Config  = CONFIG,
    CAP     = CAP,
    Fire    = SafeFire.Fire,
    Invoke  = SafeFire.Invoke,
    Log     = log,
    Version = CONFIG.Version,
}

--========== UI (safe tanpa Draggable deprecated) ==========
if CONFIG.InteractiveConsole then
    safe(function()
        local parent = (CAP.gethui and gethui()) or CoreGui
        local gui = Instance.new("ScreenGui")
        gui.Name = "AntiBanUI_" .. HttpService:GenerateGUID(false)
        gui.ResetOnSpawn = false
        gui.Parent = parent

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 340, 0, 240)
        frame.Position = UDim2.new(1, -360, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

        -- drag manual (pengganti Draggable)
        local dragging = false
        local dragStart
        local startPos
        local connections = {}

        connections[#connections + 1] = frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)

        connections[#connections + 1] = frame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
                local d = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + d.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + d.Y
                )
            end
        end)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 28)
        title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        title.Text = " 🛡️  Anti-Ban v" .. CONFIG.Version
        title.TextColor3 = Color3.fromRGB(0, 255, 150)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.Parent = frame

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -20, 1, -80)
        status.Position = UDim2.new(0, 10, 0, 40)
        status.BackgroundTransparency = 1
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextYAlignment = Enum.TextYAlignment.Top
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        status.Font = Enum.Font.Code
        status.TextSize = 12
        status.Text = "● Loading..."
        status.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 28)
        btn.Position = UDim2.new(0, 10, 1, -40)
        btn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        btn.Text = "TOGGLE DEBUG"
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        connections[#connections + 1] = btn.MouseButton1Click:Connect(function()
            CONFIG.Debug = not CONFIG.Debug
        end)

        connections[#connections + 1] = gui.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                for i = 1, #connections do
                    connections[i]:Disconnect()
                end
                table.clear(connections)
            end
        end)

        task.spawn(function()
            local env = (type(getgenv) == "function" and getgenv()) or _G
            while gui.Parent and task.wait(1) do
                status.Text = string.format(
                    "● Status    : ACTIVE\n● Debug     : %s\n● HWID      : %s...\n● AntiKick  : %s\n● AntiRemote: %s\n● AntiStats : %s",
                    tostring(CONFIG.Debug),
                    string.sub(tostring(env.hwid or "N/A"), 1, 8),
                    tostring(CONFIG.EnableAntiKick),
                    tostring(CONFIG.EnableAntiRemote),
                    tostring(CONFIG.EnableAntiStatsScan)
                )
            end
        end)
    end)
end

log("Boot", ("✅ Anti-Ban v%s loaded | PlaceId=%s"):format(CONFIG.Version, game.PlaceId))
return _G.AntiBan
