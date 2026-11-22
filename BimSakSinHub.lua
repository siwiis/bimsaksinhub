--======================================================================
--  BimSakSin Hub :: Complete Interactive Suite v2.0
--  Target   : Roblox Client / Delta Executor Ready (Single-File Standalone)
--  Desain   : Ultra-Clean Glassmorphism Putih Transparan (Web-Style),
--             Badge Centang Biru 3D Beranimasi Halus di Samping Judul,
--             Floating Toggle Tengkorak 3D HD Beranimasi + 4 Sudut Aksen
--  Catatan  : Tanpa nama sponsor. Semua koneksi, loop, ESP, & tween
--             dikelola aman dengan pembersihan otomatis (zero leak/bug).
--======================================================================

-- Cleanup instance lama jika script dijalankan ulang (anti-duplicate)
pcall(function()
	local existing = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("BimSakSinHub")
	if existing then existing:Destroy() end
	local pg = game:GetService("Players").LocalPlayer
	if pg and pg:FindFirstChild("PlayerGui") then
		local oldPg = pg.PlayerGui:FindFirstChild("BimSakSinHub")
		if oldPg then oldPg:Destroy() end
	end
end)

--======================================================================
-- SERVICES
--======================================================================
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--======================================================================
-- REGISTRY & STATE (ANTI MEMORY LEAK)
--======================================================================
local Connections = {}
local ESPObjects  = {}
local GenObjects  = {}

local State = {
	-- Visual & ESP
	PlayerESP       = false,
	ESPBoxHighlight = true,
	ESPDistance     = true,
	ESPTeamMode     = "Semua", -- "Semua" | "Musuh" | "Teman"
	GeneratorESP    = false,

	-- Movement
	FlyEnabled      = false,
	FlySpeed        = 65,
	WalkSpeedOn     = false,
	WalkSpeedVal    = 32,
	JumpPowerOn     = false,
	JumpPowerVal    = 85,
	Noclip          = false,

	-- World & Utility
	AntiLag         = false,
	AutoTeleport    = false,
	AutoTeleportSec = 3,
	SelectedTarget  = nil,
	Spectating      = false,
}

local function bind(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(Connections, conn)
	return conn
end

--======================================================================
-- THEME (PURE TRANSLUCENT WHITE GLASSMORPHISM)
--======================================================================
local Theme = {
	Font       = Enum.Font.GothamBold,
	FontMed    = Enum.Font.GothamMedium,

	Text       = Color3.fromRGB(16, 22, 34),
	SubText    = Color3.fromRGB(72, 84, 108),
	Accent     = Color3.fromRGB(45, 136, 255),
	AccentDeep = Color3.fromRGB(20, 78, 195),
	AccentSoft = Color3.fromRGB(145, 205, 255),
	Success    = Color3.fromRGB(34, 197, 94),
	Danger     = Color3.fromRGB(239, 68, 68),
	Warning    = Color3.fromRGB(245, 158, 11),

	Ease       = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	EaseIn     = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	Fast       = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	Soft       = TweenInfo.new(0.65, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out),
}

--======================================================================
-- UI INSTANCE HELPERS
--======================================================================
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color        = color or Color3.fromRGB(255, 255, 255),
		Thickness    = thickness or 1,
		Transparency = transparency or 0.55,
	}, parent)
end

local function gradient(parent, c1, c2, rotation)
	local g = new("UIGradient", { Rotation = rotation or 90 }, parent)
	g.Color = ColorSequence.new(c1, c2)
	return g
end

local function tween(inst, props, info)
	local t = TweenService:Create(inst, info or Theme.Ease, props)
	t:Play()
	return t
end

local function draggable(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos = false, nil, nil

	bind(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if endConn then endConn:Disconnect() end
				end
			end)
		end
	end)

	bind(UserInputService.InputChanged, function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

--======================================================================
-- TENGKORAK 3D HD PROSEDURAL BERANIMASI (FLOATING TOGGLE ICON)
--======================================================================
local function buildSkull3D(parent)
	local root = new("Frame", {
		Name = "Skull3D_HD",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.70, 0.70),
		BackgroundTransparency = 1,
	}, parent)

	-- Aura luar 3D berdenyut
	local aura = new("Frame", {
		Size = UDim2.fromScale(1.48, 1.48),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, root)
	corner(aura, 999)
	gradient(aura, Theme.AccentSoft, Theme.AccentDeep, 90)

	-- Bayangan belakang 3D (depth layer)
	local headShadow = new("Frame", {
		Size = UDim2.fromScale(0.82, 0.72),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 2, 0.39, 3),
		BackgroundColor3 = Color3.fromRGB(95, 130, 190),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)
	corner(headShadow, 999)

	-- Cranium utama (glossy HD)
	local head = new("Frame", {
		Size = UDim2.fromScale(0.82, 0.71),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.37),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	corner(head, 999)
	gradient(head, Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 210, 248), 125)
	stroke(head, Color3.fromRGB(255, 255, 255), 1.2, 0.15)

	-- Specular highlight HD di dahi
	local spec = new("Frame", {
		Size = UDim2.fromScale(0.42, 0.20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.42, 0.22),
		Rotation = -18,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, head)
	corner(spec, 999)

	-- Tulang pipi kiri & kanan (efek kontur 3D)
	for i = -1, 1, 2 do
		local cheek = new("Frame", {
			Size = UDim2.fromScale(0.24, 0.22),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.28 * i, 0.54),
			Rotation = 15 * i,
			BackgroundColor3 = Color3.fromRGB(232, 242, 255),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, root)
		corner(cheek, 999)
		gradient(cheek, Color3.fromRGB(255, 255, 255), Color3.fromRGB(172, 196, 236), 110)
	end

	-- Rahang 3D
	local jaw = new("Frame", {
		Size = UDim2.fromScale(0.46, 0.25),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.75),
		BackgroundColor3 = Color3.fromRGB(240, 247, 255),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	corner(jaw, 5)
	gradient(jaw, Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 192, 230), 115)
	stroke(jaw, Color3.fromRGB(255, 255, 255), 1, 0.35)

	-- Rongga mata & pupil menyala biru
	for i = -1, 1, 2 do
		local eye = new("Frame", {
			Size = UDim2.fromScale(0.22, 0.28),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.17 * i, 0.38),
			Rotation = 9 * i,
			BackgroundColor3 = Color3.fromRGB(12, 16, 28),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		corner(eye, 999)
		stroke(eye, Theme.AccentSoft, 1, 0.55)

		local pupil = new("Frame", {
			Size = UDim2.fromScale(0.36, 0.32),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.42, 0.42),
			BackgroundColor3 = Color3.fromRGB(90, 185, 255),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, eye)
		corner(pupil, 999)
	end

	-- Rongga hidung
	local nose = new("Frame", {
		Size = UDim2.fromScale(0.11, 0.11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.57),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(12, 16, 28),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, root)
	corner(nose, 2)

	-- Gigi 3D
	for i = -1, 1 do
		local tooth = new("Frame", {
			Size = UDim2.fromScale(0.025, 0.13),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.085 * i, 0.76),
			BackgroundColor3 = Color3.fromRGB(95, 115, 150),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		corner(tooth, 2)
	end

	-- Animasi idle halus (melayang + rotasi lembut + denyut aura)
	TweenService:Create(root, TweenInfo.new(2.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.fromScale(0.5, 0.44),
		Rotation = 4,
	}):Play()

	TweenService:Create(aura, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.96,
		Size = UDim2.fromScale(1.72, 1.72),
	}):Play()

	return root
end

--======================================================================
-- BADGE CENTANG BIRU 3D BERANIMASI HALUS (VERIFIED BADGE)
--======================================================================
local function buildVerified3D(parent, px)
	px = px or 20
	local badge = new("Frame", {
		Name = "Verified3D",
		Size = UDim2.fromOffset(px, px),
		BackgroundTransparency = 1,
	}, parent)

	-- Glow halo di belakang lencana
	local glow = new("Frame", {
		Size = UDim2.fromScale(1.65, 1.65),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, badge)
	corner(glow, 999)
	gradient(glow, Theme.AccentSoft, Theme.Accent, 90)

	-- Lapisan belakang 3D (depth shadow lingkaran)
	local backDisc = new("Frame", {
		Size = UDim2.fromScale(0.92, 0.92),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 1, 0.5, 2),
		BackgroundColor3 = Theme.AccentDeep,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, badge)
	corner(backDisc, 999)

	-- Lencana utama biru 3D glossy
	local disc = new("Frame", {
		Size = UDim2.fromScale(0.92, 0.92),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, badge)
	corner(disc, 999)
	gradient(disc, Color3.fromRGB(115, 195, 255), Theme.AccentDeep, 135)
	stroke(disc, Color3.fromRGB(255, 255, 255), 1.1, 0.25)

	-- Simbol centang putih tajam di tengah
	local function arm(pos, size, rot, color, z, offX, offY)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(pos.X, offX or 0, pos.Y, offY or 0),
			Size = UDim2.fromScale(size.X, size.Y),
			Rotation = rot,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z,
		}, disc)
		corner(f, 999)
		return f
	end

	-- Bayangan centang
	arm(Vector2.new(0.35, 0.58), Vector2.new(0.28, 0.12),  45, Theme.AccentDeep, 4, 0, 1)
	arm(Vector2.new(0.60, 0.50), Vector2.new(0.46, 0.12), -45, Theme.AccentDeep, 4, 0, 1)

	-- Batang centang putih
	arm(Vector2.new(0.35, 0.56), Vector2.new(0.28, 0.12),  45, Color3.fromRGB(255, 255, 255), 5)
	arm(Vector2.new(0.60, 0.48), Vector2.new(0.46, 0.12), -45, Color3.fromRGB(255, 255, 255), 5)

	-- Animasi halus: napas skala + denyut cahaya
	local scale = new("UIScale", { Scale = 1 }, badge)
	TweenService:Create(scale, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Scale = 1.10,
	}):Play()
	TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.94,
		Size = UDim2.fromScale(1.90, 1.90),
	}):Play()

	return badge
end

--======================================================================
-- HUB FRAMEWORK (ULTRA-TRANSPARENT WHITE GLASS UI)
--======================================================================
local Hub = {}
Hub.__index = Hub

function Hub.new(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Hub)
	self.Title      = cfg.Title or "BimSakSin Hub"
	self.Subtitle   = cfg.Subtitle or "Interactive Control Suite"
	self.Pages      = {}
	self.TabButtons = {}
	self.RowCount   = {}
	self.IsOpen     = false
	self.FPS        = 60

	local parentGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

	local gui = new("ScreenGui", {
		Name = "BimSakSinHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	}, parentGui)
	self.Gui = gui

	--------------------------------------------------------------------
	-- PANEL UTAMA (TRANSFARAN PUTIH SEPERTI GLASSMORPHISM WEB)
	--------------------------------------------------------------------
	local root = new("CanvasGroup", {
		Name = "MainPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 430),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
	}, gui)
	corner(root, 20)
	stroke(root, Color3.fromRGB(255, 255, 255), 1.5, 0.25)

	local rootGrad = gradient(root, Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 236, 255), 135)
	rootGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.18),
		NumberSequenceKeypoint.new(1, 0.28),
	})

	self.Root  = root
	self.Scale = new("UIScale", { Scale = 0.90 }, root)

	-- 4 SUDUT PANEL BERANIMASI HALUS SAAT DIBUKA
	self.CornerLines = {}
	local function cornerAccent(pos, anchorX, anchorY, delay)
		local hLine = new("Frame", {
			Position = pos,
			AnchorPoint = Vector2.new(anchorX, anchorY),
			Size = UDim2.fromOffset(0, 2.5),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			ZIndex = 40,
		}, root)
		corner(hLine, 2)

		local vLine = new("Frame", {
			Position = pos,
			AnchorPoint = Vector2.new(anchorX, anchorY),
			Size = UDim2.fromOffset(2.5, 0),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			ZIndex = 40,
		}, root)
		corner(vLine, 2)

		table.insert(self.CornerLines, { h = hLine, v = vLine, delay = delay })
	end
	cornerAccent(UDim2.fromOffset(10, 10), 0, 0, 0.02)
	cornerAccent(UDim2.new(1, -10, 0, 10), 1, 0, 0.07)
	cornerAccent(UDim2.new(0, 10, 1, -10), 0, 1, 0.12)
	cornerAccent(UDim2.new(1, -10, 1, -10), 1, 1, 0.17)

	--------------------------------------------------------------------
	-- HEADER (JUDUL + CENTANG BIRU 3D BERJARAK PROPORSIONAL)
	--------------------------------------------------------------------
	local header = new("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 48),
		Position = UDim2.fromOffset(16, 14),
	}, root)

	local titleRow = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.fromScale(0, 0.42),
		AnchorPoint = Vector2.new(0, 0.5),
	}, header)
	new("UIListLayout", {
		FillDirection     = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding           = UDim.new(0, 8), -- jarak ideal seperti centang verifikasi
		SortOrder         = Enum.SortOrder.LayoutOrder,
	}, titleRow)

	local titleLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28),
		Font = Theme.Font,
		TextSize = 21,
		Text = self.Title,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, titleRow)

	local verifiedBadge = buildVerified3D(titleRow, 20)
	verifiedBadge.LayoutOrder = 2

	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 33),
		Size = UDim2.new(1, -110, 0, 14),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = self.Subtitle,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local function headerButton(glyph, xOffset, hoverColor)
		local btn = new("TextButton", {
			Text = glyph,
			Font = Theme.Font,
			TextSize = 14,
			TextColor3 = Theme.Text,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.65,
			Size = UDim2.fromOffset(28, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			AutoButtonColor = false,
		}, header)
		corner(btn, 9)
		stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.35)
		bind(btn.MouseEnter, function()
			tween(btn, { BackgroundTransparency = 0.30, TextColor3 = hoverColor }, Theme.Fast)
		end)
		bind(btn.MouseLeave, function()
			tween(btn, { BackgroundTransparency = 0.65, TextColor3 = Theme.Text }, Theme.Fast)
		end)
		return btn
	end

	local btnClose = headerButton("✕", 0, Theme.Danger)
	local btnMin   = headerButton("–", -34, Theme.AccentDeep)

	--------------------------------------------------------------------
	-- SIDEBAR KATEGORI (GLASS PUTIH TRANSPARAN)
	--------------------------------------------------------------------
	local sidebar = new("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.72,
		Size = UDim2.new(0, 148, 1, -124),
		Position = UDim2.fromOffset(16, 72),
		BorderSizePixel = 0,
	}, root)
	corner(sidebar, 14)
	stroke(sidebar, Color3.fromRGB(255, 255, 255), 1.1, 0.35)
	new("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
	}, sidebar)
	self.Sidebar = sidebar

	--------------------------------------------------------------------
	-- AREA KONTEN SCROLLABLE
	--------------------------------------------------------------------
	local content = new("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -190, 1, -124),
		Position = UDim2.fromOffset(176, 72),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollBarImageTransparency = 0.35,
		ClipsDescendants = true,
	}, root)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)
	new("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, content)
	self.Content = content

	--------------------------------------------------------------------
	-- FOOTER / STATUS BAR REAL-TIME
	--------------------------------------------------------------------
	local footer = new("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 18),
		Position = UDim2.new(0, 16, 1, -30),
	}, root)

	self.StatusLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = "FPS 60  •  PING 0 ms  •  PLAYERS 0",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, footer)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.Font,
		TextSize = 11,
		Text = "v2.0",
		TextColor3 = Theme.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, footer)

	--------------------------------------------------------------------
	-- FLOATING TOGGLE (PUTIH GLASS TRANSPARAN + TENGKORAK 3D HD)
	--------------------------------------------------------------------
	local float = new("CanvasGroup", {
		Name = "FloatingToggle",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -26, 1, -26),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, gui)
	corner(float, 999)
	stroke(float, Color3.fromRGB(255, 255, 255), 1.6, 0.20)
	gradient(float, Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 222, 255), 135)
	self.Floating = float

	local floatGlow = new("Frame", {
		Size = UDim2.fromScale(1.24, 1.24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 0.80,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, float)
	corner(floatGlow, 999)

	buildSkull3D(float)
	draggable(float)

	local floatBtn = new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, float)

	bind(floatBtn.MouseEnter, function()
		tween(float, { Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 0.55 }, Theme.Fast)
	end)
	bind(floatBtn.MouseLeave, function()
		local targetSize = self.IsOpen and UDim2.fromOffset(52, 52) or UDim2.fromOffset(64, 64)
		local targetTrans = self.IsOpen and 0.62 or 0.72
		tween(float, { Size = targetSize, BackgroundTransparency = targetTrans }, Theme.Fast)
	end)
	bind(floatBtn.MouseButton1Click, function()
		self:SetOpen(not self.IsOpen)
	end)

	TweenService:Create(floatGlow, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.96,
		Size = UDim2.fromScale(1.48, 1.48),
	}):Play()

	tween(float, { GroupTransparency = 0 }, Theme.Soft)

	--------------------------------------------------------------------
	-- TOAST NOTIFICATION HOLDER
	--------------------------------------------------------------------
	self.ToastHolder = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 24),
		Size = UDim2.fromOffset(265, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, gui)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.ToastHolder)

	bind(btnClose.MouseButton1Click, function() self:SetOpen(false) end)
	bind(btnMin.MouseButton1Click, function() self:SetOpen(false) end)
	draggable(root, header)

	-- Shortcut tombol RightShift untuk buka/tutup panel
	bind(UserInputService.InputBegan, function(input, gpe)
		if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
			self:SetOpen(not self.IsOpen)
		end
	end)

	--------------------------------------------------------------------
	-- FPS & PING MONITOR LOOP
	--------------------------------------------------------------------
	local frames, elapsed = 0, 0
	bind(RunService.RenderStepped, function(dt)
		frames  += 1
		elapsed += dt
		if elapsed >= 1 then
			self.FPS = math.floor(frames / elapsed + 0.5)
			frames, elapsed = 0, 0
		end
	end)

	task.spawn(function()
		while gui and gui.Parent do
			task.wait(1)
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
			end)
			self.StatusLabel.Text = string.format(
				"FPS %d  •  PING %d ms  •  PLAYERS %d  •  %s",
				self.FPS or 60, ping, #Players:GetPlayers(), os.date("%H:%M:%S")
			)
		end
	end)

	return self
end

--======================================================================
-- OPEN / CLOSE ANIMATION (SMOOTH GLASS & 4 CORNER ACCENTS)
--======================================================================
function Hub:SetOpen(open)
	if self.IsOpen == open then return end
	self.IsOpen = open

	if open then
		self.Root.Visible = true
		self.Root.GroupTransparency = 1
		self.Scale.Scale = 0.90

		tween(self.Scale, { Scale = 1 }, Theme.Ease)
		tween(self.Root, { GroupTransparency = 0 }, Theme.Soft)

		for _, line in ipairs(self.CornerLines) do
			line.h.Size = UDim2.fromOffset(0, 2.5)
			line.v.Size = UDim2.fromOffset(2.5, 0)
			task.delay(line.delay, function()
				if self.IsOpen then
					tween(line.h, { Size = UDim2.fromOffset(22, 2.5) }, Theme.Ease)
					tween(line.v, { Size = UDim2.fromOffset(2.5, 22) }, Theme.Ease)
				end
			end)
		end

		tween(self.Floating, { Size = UDim2.fromOffset(52, 52), BackgroundTransparency = 0.62 }, Theme.Fast)
	else
		for _, line in ipairs(self.CornerLines) do
			tween(line.h, { Size = UDim2.fromOffset(0, 2.5) }, Theme.EaseIn)
			tween(line.v, { Size = UDim2.fromOffset(2.5, 0) }, Theme.EaseIn)
		end

		tween(self.Scale, { Scale = 0.90 }, Theme.EaseIn)
		tween(self.Root, { GroupTransparency = 1 }, Theme.EaseIn)
		task.delay(0.32, function()
			if not self.IsOpen and self.Root then
				self.Root.Visible = false
			end
		end)
		tween(self.Floating, { Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 0.72 }, Theme.Ease)
	end
end

--======================================================================
-- CATEGORY / TAB BUILDER
--======================================================================
function Hub:AddCategory(name)
	if self.Pages[name] then return self.Pages[name] end

	local btn = new("TextButton", {
		Name = name,
		Text = "",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 35),
		AutoButtonColor = false,
		LayoutOrder = #self.TabButtons + 1,
	}, self.Sidebar)
	corner(btn, 10)

	local indicator = new("Frame", {
		Size = UDim2.new(0, 3.5, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, btn)
	corner(indicator, 2)

	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, 0),
		Position = UDim2.fromOffset(11, 0),
		Font = Theme.FontMed,
		TextSize = 12,
		Text = name,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)

	bind(btn.MouseEnter, function()
		if self.ActiveTab ~= name then
			tween(btn, { BackgroundTransparency = 0.65 }, Theme.Fast)
		end
	end)
	bind(btn.MouseLeave, function()
		if self.ActiveTab ~= name then
			tween(btn, { BackgroundTransparency = 1 }, Theme.Fast)
		end
	end)
	bind(btn.MouseButton1Click, function()
		self:SelectCategory(name)
	end)

	local page = new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, self.Content)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)

	local pageTitle = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Font = Theme.Font,
		TextSize = 14,
		Text = name,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
	}, page)

	local underline = new("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(30, 2.5),
		Position = UDim2.new(0, 0, 0, 24),
	}, pageTitle)
	corner(underline, 2)

	self.Pages[name]      = page
	self.TabButtons[name] = { button = btn, label = label, indicator = indicator }
	self.RowCount[name]   = 0

	if not self.ActiveTab then
		self:SelectCategory(name)
	end

	return page
end

function Hub:SelectCategory(name)
	if self.ActiveTab == name then return end
	self.ActiveTab = name

	for cat, page in pairs(self.Pages) do
		page.Visible = (cat == name)
	end

	for cat, tab in pairs(self.TabButtons) do
		local active = (cat == name)
		tween(tab.button, { BackgroundTransparency = active and 0.40 or 1 }, Theme.Fast)
		tween(tab.indicator, { Size = UDim2.new(0, 3.5, active and 0.58 or 0, 0) }, Theme.Fast)
		tab.label.TextColor3 = active and Theme.AccentDeep or Theme.SubText
		tab.label.Font = active and Theme.Font or Theme.FontMed
	end
end

--======================================================================
-- CONTROLS: TOGGLE / SLIDER / BUTTON / DROPDOWN / INFO CARD
--======================================================================
local function buildToggle(parent, default, onChanged)
	local state = default and true or false

	local track = new("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(42, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(196, 206, 224),
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, parent)
	corner(track, 999)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, track)
	corner(knob, 999)
	stroke(knob, Color3.fromRGB(120, 132, 150), 1, 0.70)

	local function apply(animate)
		local goalColor = state and Theme.Accent or Color3.fromRGB(196, 206, 224)
		local goalPos   = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
		if animate then
			tween(track, { BackgroundColor3 = goalColor }, Theme.Fast)
			tween(knob,  { Position = goalPos }, Theme.Fast)
		else
			track.BackgroundColor3 = goalColor
			knob.Position = goalPos
		end
	end
	apply(false)

	bind(track.MouseButton1Click, function()
		state = not state
		apply(true)
		if onChanged then onChanged(state) end
	end)

	return {
		Set = function(val)
			state = val and true or false
			apply(true)
		end
	}
end

local function buildSlider(parent, min, max, default, onChanged)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(156, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 1,
	}, parent)

	local valueLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(38, 22),
		Font = Theme.Font,
		TextSize = 11,
		Text = tostring(default),
		TextColor3 = Theme.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)

	local track = new("Frame", {
		Size = UDim2.new(1, -42, 0, 6),
		Position = UDim2.fromOffset(42, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(198, 208, 226),
		BorderSizePixel = 0,
	}, holder)
	corner(track, 999)

	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 999)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, track)
	corner(knob, 999)
	stroke(knob, Theme.Accent, 1.2, 0.25)

	local value = math.clamp(default or min, min, max)

	local function setFromX(x)
		if track.AbsoluteSize.X <= 0 then return end
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * rel + 0.5)
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.fromScale(rel, 0.5)
		valueLbl.Text = tostring(value)
		if onChanged then onChanged(value) end
	end

	local dragging = false

	bind(track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
			tween(knob, { Size = UDim2.fromOffset(17, 17) }, Theme.Fast)
		end
	end)

	bind(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	bind(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				tween(knob, { Size = UDim2.fromOffset(14, 14) }, Theme.Fast)
			end
		end
	end)

	task.defer(function()
		local rel = (value - min) / math.max(max - min, 0.0001)
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.fromScale(rel, 0.5)
		valueLbl.Text = tostring(value)
	end)

	return holder
end

local function buildButton(parent, labelText, onClick)
	local btn = new("TextButton", {
		Text = labelText or "JALANKAN",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.fromOffset(82, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		AutoButtonColor = false,
	}, parent)
	corner(btn, 8)
	gradient(btn, Theme.AccentSoft, Theme.AccentDeep, 90)
	stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.45)

	bind(btn.MouseEnter, function()
		tween(btn, { Size = UDim2.fromOffset(88, 28) }, Theme.Fast)
	end)
	bind(btn.MouseLeave, function()
		tween(btn, { Size = UDim2.fromOffset(82, 26) }, Theme.Fast)
	end)
	bind(btn.MouseButton1Click, function()
		local orig = btn.Text
		btn.Text = "✓ OK"
		task.delay(0.75, function()
			if btn and btn.Parent then btn.Text = orig end
		end)
		if onClick then onClick() end
	end)

	return btn
end

local function buildCycleSelector(parent, getOptions, defaultText, onChanged)
	local idx = 1
	local btn = new("TextButton", {
		Text = defaultText or "Pilih...",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.AccentDeep,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.40,
		Size = UDim2.fromOffset(118, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		AutoButtonColor = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	corner(btn, 8)
	stroke(btn, Theme.Accent, 1, 0.45)

	bind(btn.MouseButton1Click, function()
		local opts = getOptions()
		if not opts or #opts == 0 then
			btn.Text = "Kosong"
			return
		end
		idx = (idx % #opts) + 1
		local chosen = opts[idx]
		btn.Text = tostring(chosen)
		if onChanged then onChanged(chosen) end
	end)

	return btn
end

function Hub:AddFeature(category, data)
	if not self.Pages[category] then
		self:AddCategory(category)
	end
	local page = self.Pages[category]
	self.RowCount[category] += 1

	local row = new("Frame", {
		Name = data.Name or "Feature",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.62,
		BorderSizePixel = 0,
		LayoutOrder = self.RowCount[category],
	}, page)
	corner(row, 12)
	local rs = stroke(row, Color3.fromRGB(255, 255, 255), 1, 0.35)

	local nameLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -182, 0, 18),
		Font = Theme.Font,
		TextSize = 13,
		Text = data.Name or "Fitur",
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local descLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 26),
		Size = UDim2.new(1, -182, 0, 17),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = data.Desc or "",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	local controlHolder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 28),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
	}, row)

	local ctrl
	if data.Type == "slider" then
		ctrl = buildSlider(controlHolder, data.Min or 0, data.Max or 100, data.Default or 0, data.Callback)
	elseif data.Type == "button" then
		ctrl = buildButton(controlHolder, data.ButtonText or "JALANKAN", data.Callback)
	elseif data.Type == "selector" then
		ctrl = buildCycleSelector(controlHolder, data.GetOptions, data.DefaultText, data.Callback)
	else
		ctrl = buildToggle(controlHolder, data.Default, data.Callback)
	end

	bind(row.MouseEnter, function()
		tween(row, { BackgroundTransparency = 0.38 }, Theme.Fast)
		tween(rs,  { Transparency = 0.15 }, Theme.Fast)
		tween(nameLbl, { TextColor3 = Theme.AccentDeep }, Theme.Fast)
	end)
	bind(row.MouseLeave, function()
		tween(row, { BackgroundTransparency = 0.62 }, Theme.Fast)
		tween(rs,  { Transparency = 0.35 }, Theme.Fast)
		tween(nameLbl, { TextColor3 = Theme.Text }, Theme.Fast)
	end)

	return row, ctrl, descLbl
end

function Hub:AddInfoCard(category, title, initialBody)
	if not self.Pages[category] then
		self:AddCategory(category)
	end
	local page = self.Pages[category]
	self.RowCount[category] += 1

	local card = new("Frame", {
		Name = title,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.58,
		BorderSizePixel = 0,
		LayoutOrder = self.RowCount[category],
	}, page)
	corner(card, 12)
	stroke(card, Color3.fromRGB(255, 255, 255), 1, 0.35)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, card)
	new("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Theme.Font,
		TextSize = 12,
		Text = title,
		TextColor3 = Theme.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, card)

	local bodyLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.FontMed,
		TextSize = 11,
		Text = initialBody or "",
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 2,
	}, card)

	return bodyLbl
end

function Hub:Notify(text, duration)
	duration = duration or 3

	local toast = new("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, self.ToastHolder)
	corner(toast, 12)
	stroke(toast, Color3.fromRGB(255, 255, 255), 1.2, 0.20)

	local accentBar = new("Frame", {
		Size = UDim2.new(0, 3.5, 0.62, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, toast)
	corner(accentBar, 2)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -22, 1, 0),
		Font = Theme.Font,
		TextSize = 12,
		Text = text,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, toast)

	tween(toast, { GroupTransparency = 0 }, Theme.Soft)

	task.delay(duration, function()
		if not toast or not toast.Parent then return end
		tween(toast, { GroupTransparency = 1 }, Theme.Soft)
		task.delay(0.65, function()
			if toast and toast.Parent then toast:Destroy() end
		end)
	end)
end

--======================================================================
-- INISIALISASI HUB
--======================================================================
local App = Hub.new({
	Title    = "BimSakSin Hub",
	Subtitle = "Interactive Control & Visual Suite",
})

--======================================================================
-- MODUL 1: ESP PEMAIN (FONT TEBAL, BG HITAM HANYA DI TEKS, TEAM/MUSUH/TEMAN)
--======================================================================
local function getPlayerRelation(plr)
	if plr == LocalPlayer then return "Self", Color3.fromRGB(160, 210, 255) end

	local sameTeam = false
	if LocalPlayer.Team ~= nil and plr.Team ~= nil then
		sameTeam = (LocalPlayer.Team == plr.Team)
	elseif LocalPlayer.TeamColor ~= nil and plr.TeamColor ~= nil and LocalPlayer.Neutral == false then
		sameTeam = (LocalPlayer.TeamColor == plr.TeamColor)
	end

	local isFriend = false
	pcall(function()
		isFriend = LocalPlayer:IsFriendsWith(plr.UserId)
	end)

	if isFriend then
		return "Teman", Color3.fromRGB(56, 224, 120)
	elseif sameTeam then
		return "Team", Color3.fromRGB(65, 175, 255)
	else
		return "Musuh", Color3.fromRGB(255, 78, 78)
	end
end

local function clearPlayerESP(plr)
	local obj = ESPObjects[plr]
	if obj then
		if obj.Billboard then obj.Billboard:Destroy() end
		if obj.Highlight then obj.Highlight:Destroy() end
		ESPObjects[plr] = nil
	end
end

local function createPlayerESP(plr)
	if plr == LocalPlayer then return end
	clearPlayerESP(plr)

	local char = plr.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	if not hrp then return end

	-- Tanda ESP pada avatar (Highlight outline halus + fill tipis)
	local hl = new("Highlight", {
		Name = "BSS_AvatarMarker",
		Adornee = char,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillTransparency = 0.72,
		OutlineTransparency = 0.05,
	}, App.Gui)

	-- Billboard nama & jarak: TANPA latar belakang kotak besar,
	-- HANYA latar belakang hitam tebal sedang tepat di belakang teks!
	local bb = new("BillboardGui", {
		Name = "BSS_NameTag",
		Adornee = hrp,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 260, 0, 32),
		StudsOffset = Vector3.new(0, 3.3, 0),
		MaxDistance = 5000,
	}, App.Gui)

	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, bb)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, holder)

	-- Label nama dengan latar belakang hitam tebal sedang tepat menempel pada font
	local textPill = new("TextLabel", {
		Name = "TagText",
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(8, 10, 14),
		BackgroundTransparency = 0.22, -- hitam tebal sedang
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack, -- font tebal
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		TextStrokeTransparency = 0.15,
	}, holder)
	corner(textPill, 5)
	stroke(textPill, Color3.fromRGB(0, 0, 0), 1.4, 0.25)
	new("UIPadding", {
		PaddingLeft   = UDim.new(0, 7),
		PaddingRight  = UDim.new(0, 7),
		PaddingTop    = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
	}, textPill)

	ESPObjects[plr] = {
		Billboard = bb,
		Highlight = hl,
		Label     = textPill,
	}
end

-- Loop pembaruan ESP Pemain (efisien 0.1s)
task.spawn(function()
	while App.Gui and App.Gui.Parent do
		task.wait(0.1)
		if not State.PlayerESP then
			for plr, _ in pairs(ESPObjects) do
				clearPlayerESP(plr)
			end
			continue
		end

		local myChar = LocalPlayer.Character
		local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then continue end
			local char = plr.Character
			local hrp  = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
			local hum  = char and char:FindFirstChildOfClass("Humanoid")

			if not char or not hrp or (hum and hum.Health <= 0) then
				clearPlayerESP(plr)
				continue
			end

			local relation, relColor = getPlayerRelation(plr)
			local showByFilter = (State.ESPTeamMode == "Semua")
				or (State.ESPTeamMode == "Musuh" and relation == "Musuh")
				or (State.ESPTeamMode == "Teman" and (relation == "Team" or relation == "Teman"))

			if not showByFilter then
				clearPlayerESP(plr)
				continue
			end

			if not ESPObjects[plr] or ESPObjects[plr].Billboard.Adornee ~= hrp then
				createPlayerESP(plr)
			end

			local obj = ESPObjects[plr]
			if obj then
				local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude + 0.5) or 0
				local distStr = State.ESPDistance and string.format(" [%dm]", dist) or ""
				obj.Label.Text = string.format("[%s] %s%s", relation:upper(), plr.DisplayName, distStr)
				obj.Label.TextColor3 = relColor

				obj.Highlight.Enabled = State.ESPBoxHighlight
				obj.Highlight.FillColor = relColor
				obj.Highlight.OutlineColor = relColor
			end
		end
	end
end)

bind(Players.PlayerRemoving, function(plr)
	clearPlayerESP(plr)
end)

--======================================================================
-- MODUL 2: ESP GENERATOR (DETEKSI OTOMATIS + JARAK + PERSEN SELESAI/SISA)
--======================================================================
local function extractGeneratorProgress(inst)
	-- 1. Cek Attribute umum pada model/part generator
	local attrNames = { "Progress", "Percent", "Percentage", "RepairProgress", "Charge", "Completion", "Work", "Value" }
	for _, attr in ipairs(attrNames) do
		local v = inst:GetAttribute(attr)
		if type(v) == "number" then
			return v <= 1 and math.clamp(v * 100, 0, 100) or math.clamp(v, 0, 100)
		end
	end

	-- 2. Cek NumberValue / IntValue di dalam generator
	for _, desc in ipairs(inst:GetDescendants()) do
		if desc:IsA("NumberValue") or desc:IsA("IntValue") then
			local n = desc.Name:lower()
			if n:find("prog") or n:find("perc") or n:find("rep") or n:find("charg") or n:find("work") or n:find("val") then
				local v = desc.Value
				if type(v) == "number" then
					return v <= 1 and math.clamp(v * 100, 0, 100) or math.clamp(v, 0, 100)
				end
			end
		elseif desc:IsA("BoolValue") then
			local n = desc.Name:lower()
			if (n:find("done") or n:find("fixed") or n:find("complete") or n:find("repaired")) and desc.Value == true then
				return 100
			end
		end
	end

	-- 3. Cek status Bool Attribute
	if inst:GetAttribute("Completed") == true or inst:GetAttribute("Repaired") == true or inst:GetAttribute("Fixed") == true then
		return 100
	end

	return 0
end

local function clearAllGenESP()
	for gen, obj in pairs(GenObjects) do
		if obj.Billboard then obj.Billboard:Destroy() end
		if obj.Highlight then obj.Highlight:Destroy() end
	end
	table.clear(GenObjects)
end

local function scanGenerators()
	local found = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") or obj:IsA("BasePart") then
			local n = obj.Name:lower()
			if n:find("generator") or n == "gen" or n:match("^gen[%d_]") then
				-- Hindari duplikasi child part dari model generator yang sama
				if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent.Name:lower():find("generator") then
					continue
				end
				table.insert(found, obj)
			end
		end
	end
	return found
end

task.spawn(function()
	local cachedGens = {}
	local lastScan = 0

	while App.Gui and App.Gui.Parent do
		task.wait(0.25)
		if not State.GeneratorESP then
			if next(GenObjects) ~= nil then
				clearAllGenESP()
			end
			continue
		end

		if tick() - lastScan >= 3 then
			cachedGens = scanGenerators()
			lastScan = tick()
		end

		local myChar = LocalPlayer.Character
		local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")

		for _, gen in ipairs(cachedGens) do
			if not gen or not gen.Parent then
				if GenObjects[gen] then
					if GenObjects[gen].Billboard then GenObjects[gen].Billboard:Destroy() end
					if GenObjects[gen].Highlight then GenObjects[gen].Highlight:Destroy() end
					GenObjects[gen] = nil
				end
				continue
			end

			local adornee = gen:IsA("Model") and (gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")) or gen
			if not adornee then continue end

			if not GenObjects[gen] then
				local hl = new("Highlight", {
					Name = "BSS_GenHighlight",
					Adornee = gen,
					DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
					FillTransparency = 0.75,
					OutlineTransparency = 0.1,
				}, App.Gui)

				local bb = new("BillboardGui", {
					Name = "BSS_GenTag",
					Adornee = adornee,
					AlwaysOnTop = true,
					Size = UDim2.new(0, 290, 0, 34),
					StudsOffset = Vector3.new(0, 3.2, 0),
					MaxDistance = 5000,
				}, App.Gui)

				local holder = new("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}, bb)
				new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}, holder)

				local lbl = new("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.XY,
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = Color3.fromRGB(8, 10, 14),
					BackgroundTransparency = 0.22,
					BorderSizePixel = 0,
					Font = Enum.Font.GothamBlack,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(255, 220, 90),
					TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					TextStrokeTransparency = 0.15,
				}, holder)
				corner(lbl, 5)
				stroke(lbl, Color3.fromRGB(0, 0, 0), 1.4, 0.25)
				new("UIPadding", {
					PaddingLeft = UDim.new(0, 7),
					PaddingRight = UDim.new(0, 7),
					PaddingTop = UDim.new(0, 2),
					PaddingBottom = UDim.new(0, 2),
				}, lbl)

				GenObjects[gen] = { Billboard = bb, Highlight = hl, Label = lbl }
			end

			local donePct = math.floor(extractGeneratorProgress(gen) + 0.5)
			local leftPct = math.max(0, 100 - donePct)
			local dist    = myHrp and math.floor((myHrp.Position - adornee.Position).Magnitude + 0.5) or 0

			local statusColor = donePct >= 100
				and Color3.fromRGB(56, 224, 120)
				or (donePct > 0 and Color3.fromRGB(255, 200, 65) or Color3.fromRGB(255, 110, 110))

			local gObj = GenObjects[gen]
			gObj.Label.Text = string.format(
				"GENERATOR [%dm]  •  Selesai: %d%% | Sisa: %d%%",
				dist, donePct, leftPct
			)
			gObj.Label.TextColor3 = statusColor
			gObj.Highlight.FillColor = statusColor
			gObj.Highlight.OutlineColor = statusColor
		end
	end
end)

--======================================================================
-- MODUL 3: MOVEMENT (FLY, WALKSPEED, JUMP POWER, NOCLIP)
--======================================================================
local flyBV, flyBG

local function stopFly()
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
	local char = LocalPlayer.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

local function startFly()
	stopFly()
	local char = LocalPlayer.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	hum.PlatformStand = true

	flyBG = new("BodyGyro", {
		P = 9e4,
		MaxTorque = Vector3.new(9e9, 9e9, 9e9),
		CFrame = hrp.CFrame,
	}, hrp)

	flyBV = new("BodyVelocity", {
		Velocity = Vector3.zero,
		MaxForce = Vector3.new(9e9, 9e9, 9e9),
	}, hrp)
end

bind(RunService.RenderStepped, function()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")

	-- WalkSpeed & JumpPower Enforcement
	if hum then
		if State.WalkSpeedOn then
			hum.WalkSpeed = State.WalkSpeedVal
		end
		if State.JumpPowerOn then
			hum.UseJumpPower = true
			hum.JumpPower = State.JumpPowerVal
		end
	end

	-- Fly Physics Control (WASD + Space/Shift)
	if State.FlyEnabled and hrp then
		if not flyBV or not flyBV.Parent then
			startFly()
		end
		local cam = Workspace.CurrentCamera
		if cam and flyBV and flyBG then
			local moveDir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, 1, 0) end

			if moveDir.Magnitude > 0 then
				moveDir = moveDir.Unit * State.FlySpeed
			end
			flyBV.Velocity = moveDir
			flyBG.CFrame = cam.CFrame
		end
	elseif flyBV then
		stopFly()
	end
end)

-- Noclip Stepped Loop
bind(RunService.Stepped, function()
	if not State.Noclip then return end
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end
end)

--======================================================================
-- MODUL 4: ANTI-LAG MAP OPTIMIZER (FPS BOOSTER)
--======================================================================
local function applyAntiLag(enable)
	if enable then
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
				v.Reflectance = 0
			elseif v:IsA("Decal") or v:IsA("Texture") then
				v.Transparency = 1
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
				v.Enabled = false
			end
		end
		App:Notify("Anti-Lag Aktif: Efek partikel & bayangan berat dimatikan", 3)
	else
		Lighting.GlobalShadows = true
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
		end)
		App:Notify("Anti-Lag Dimatikan", 2)
	end
end

--======================================================================
-- MODUL 5: NETWORK, REGION & IP API DETECTOR (INTERAKTIF & REAL-TIME)
--======================================================================
local NetworkInfoCache = {
	IP = "Mendeteksi...",
	Country = "Mendeteksi...",
	City = "-",
	ISP = "-",
	ServerRegion = "Mendeteksi...",
}

local function fetchNetworkAndRegionAPI(callback)
	task.spawn(function()
		local req = (syn and syn.request) or http_request or request or (http and http.request)
		if req then
			local ok, res = pcall(function()
				return req({ Url = "http://ip-api.com/json/", Method = "GET" })
			end)
			if ok and res and res.Body then
				local parsedOk, data = pcall(function()
					return HttpService:JSONDecode(res.Body)
				end)
				if parsedOk and type(data) == "table" and data.status == "success" then
					NetworkInfoCache.IP      = tostring(data.query or "Tersembunyi")
					NetworkInfoCache.Country = tostring(data.country or "-")
					NetworkInfoCache.City    = tostring(data.city or "-")
					NetworkInfoCache.ISP     = tostring(data.isp or "-")
				end
			end
		else
			-- Fallback jika HTTP request dibatasi lingkungan
			local code = "ID"
			pcall(function()
				code = LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
			end)
			NetworkInfoCache.IP      = "Terlindungi (Client Sandbox)"
			NetworkInfoCache.Country = code
			NetworkInfoCache.City    = "Lokal Client"
			NetworkInfoCache.ISP     = "Roblox Network Relay"
		end

		if callback then callback(NetworkInfoCache) end
	end)
end

--======================================================================
-- MODUL 6: TELEPORT & SPECTATE / VIEW PEMAIN
--======================================================================
local function getOtherPlayerNames()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(list, p.Name)
		end
	end
	return list
end

local function teleportToPlayer(targetName)
	if not targetName then
		App:Notify("Pilih target pemain terlebih dahulu!", 2.5)
		return
	end
	local target = Players:FindFirstChild(targetName)
	local tHrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local mHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if tHrp and mHrp then
		mHrp.CFrame = tHrp.CFrame * CFrame.new(0, 2, 3)
	end
end

local function setSpectateTarget(enable, targetName)
	local cam = Workspace.CurrentCamera
	if not cam then return end

	if enable then
		if not targetName then
			App:Notify("Pilih pemain yang ingin di-View terlebih dahulu!", 2.5)
			State.Spectating = false
			return
		end
		local target = Players:FindFirstChild(targetName)
		local tHum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if tHum then
			cam.CameraSubject = tHum
			App:Notify("Sedang memantau kamera: " .. target.DisplayName, 2.5)
		else
			App:Notify("Karakter target tidak ditemukan!", 2.5)
		end
	else
		local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myHum then
			cam.CameraSubject = myHum
		end
	end
end

-- Loop Auto Teleport Berkala
task.spawn(function()
	while App.Gui and App.Gui.Parent do
		task.wait(math.max(0.5, State.AutoTeleportSec))
		if State.AutoTeleport and State.SelectedTarget then
			teleportToPlayer(State.SelectedTarget)
		end
	end
end)

--======================================================================
-- PENYUSUNAN KATEGORI & FITUR INTERAKTIF (STRUKTUR JELAS & DETAIL)
--======================================================================

-- 1. TAB VISUAL & ESP
App:AddCategory("Visual & ESP")

App:AddFeature("Visual & ESP", {
	Name = "Player ESP (Nama & Status)",
	Desc = "Menampilkan nama tebal + latar hitam teks & tanda ESP di avatar",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.PlayerESP = v
		App:Notify("Player ESP: " .. (v and "AKTIF" or "NONAKTIF"), 2)
	end,
})

App:AddFeature("Visual & ESP", {
	Name = "Tanda Outline Avatar",
	Desc = "Highlight tembus dinding pada tubuh pemain sesuai Team/Teman/Musuh",
	Type = "toggle",
	Default = true,
	Callback = function(v)
		State.ESPBoxHighlight = v
	end,
})

App:AddFeature("Visual & ESP", {
	Name = "Tampilkan Jarak ESP (Meter)",
	Desc = "Menambahkan indikator jarak real-time di samping nama pemain",
	Type = "toggle",
	Default = true,
	Callback = function(v)
		State.ESPDistance = v
	end,
})

App:AddFeature("Visual & ESP", {
	Name = "Filter Target ESP",
	Desc = "Menyesuaikan tampilan ESP untuk Semua, Musuh, atau Teman/Team",
	Type = "selector",
	GetOptions = function()
		return { "Semua", "Musuh", "Teman" }
	end,
	DefaultText = "Semua",
	Callback = function(choice)
		State.ESPTeamMode = choice
		App:Notify("Filter ESP diubah ke: " .. choice, 2)
	end,
})

App:AddFeature("Visual & ESP", {
	Name = "Generator ESP + Persentase",
	Desc = "Deteksi semua generator, jarak, % sudah dikerjakan & % sisa",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.GeneratorESP = v
		App:Notify("Generator ESP: " .. (v and "AKTIF" or "NONAKTIF"), 2)
	end,
})

-- 2. TAB MOVEMENT
App:AddCategory("Movement")

App:AddFeature("Movement", {
	Name = "Fly Mode (Terbang Bebas)",
	Desc = "Kontrol arah terbang 3D via kamera (WASD + Space naik / Shift turun)",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.FlyEnabled = v
		if not v then stopFly() end
		App:Notify("Fly Mode: " .. (v and "AKTIF" or "NONAKTIF"), 2)
	end,
})

App:AddFeature("Movement", {
	Name = "Kecepatan Fly (Fly Speed)",
	Desc = "Mengatur kecepatan dorongan udara saat Fly Mode aktif",
	Type = "slider",
	Min = 16,
	Max = 250,
	Default = 65,
	Callback = function(val)
		State.FlySpeed = val
	end,
})

App:AddFeature("Movement", {
	Name = "WalkSpeed Hack",
	Desc = "Mengunci kecepatan lari karakter agar tidak di-reset game",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.WalkSpeedOn = v
		if not v and LocalPlayer.Character then
			local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if h then h.WalkSpeed = 16 end
		end
	end,
})

App:AddFeature("Movement", {
	Name = "Nilai WalkSpeed",
	Desc = "Atur kecepatan jalan/lari karakter (Default normal: 16)",
	Type = "slider",
	Min = 16,
	Max = 200,
	Default = 32,
	Callback = function(val)
		State.WalkSpeedVal = val
	end,
})

App:AddFeature("Movement", {
	Name = "High Jump Power",
	Desc = "Meningkatkan daya lompat karakter secara presisi",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.JumpPowerOn = v
		if not v and LocalPlayer.Character then
			local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if h then h.JumpPower = 50 end
		end
	end,
})

App:AddFeature("Movement", {
	Name = "Nilai JumpPower",
	Desc = "Atur ketinggian lompatan karakter (Default normal: 50)",
	Type = "slider",
	Min = 50,
	Max = 250,
	Default = 85,
	Callback = function(val)
		State.JumpPowerVal = val
	end,
})

App:AddFeature("Movement", {
	Name = "Noclip (Tembus Objek)",
	Desc = "Menonaktifkan kolisi fisik karakter agar bisa menembus dinding",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.Noclip = v
		App:Notify("Noclip: " .. (v and "AKTIF" or "NONAKTIF"), 2)
	end,
})

-- 3. TAB PLAYER & TELEPORT
App:AddCategory("Player & Teleport")

App:AddFeature("Player & Teleport", {
	Name = "Pilih Target Pemain",
	Desc = "Klik untuk mengganti pemain target Teleport / View Kamera",
	Type = "selector",
	GetOptions = getOtherPlayerNames,
	DefaultText = "Klik Pilih Target",
	Callback = function(name)
		State.SelectedTarget = name
		if State.Spectating then
			setSpectateTarget(true, name)
		end
		App:Notify("Target terpilih: " .. name, 2)
	end,
})

App:AddFeature("Player & Teleport", {
	Name = "Teleport ke Target",
	Desc = "Berpindah instan tepat ke posisi pemain yang dipilih",
	Type = "button",
	ButtonText = "TELEPORT",
	Callback = function()
		teleportToPlayer(State.SelectedTarget)
		if State.SelectedTarget then
			App:Notify("Teleport ke " .. State.SelectedTarget, 2)
		end
	end,
})

App:AddFeature("Player & Teleport", {
	Name = "Auto Teleport Loop",
	Desc = "Otomatis mengikuti & teleport ke posisi target secara berkala",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.AutoTeleport = v
		App:Notify("Auto Teleport: " .. (v and "AKTIF" or "NONAKTIF"), 2)
	end,
})

App:AddFeature("Player & Teleport", {
	Name = "Interval Auto Teleport (Detik)",
	Desc = "Jeda waktu antar perpindahan otomatis saat Auto Teleport aktif",
	Type = "slider",
	Min = 1,
	Max = 15,
	Default = 3,
	Callback = function(val)
		State.AutoTeleportSec = val
	end,
})

App:AddFeature("Player & Teleport", {
	Name = "View / Spectate Pemain",
	Desc = "Mengarahkan kamera ke sudut pandang pemain target secara langsung",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.Spectating = v
		setSpectateTarget(v, State.SelectedTarget)
	end,
})

-- 4. TAB NETWORK & OPTIMIZER
App:AddCategory("Network & System")

App:AddFeature("Network & System", {
	Name = "Anti-Lag Map (FPS Booster)",
	Desc = "Menghapus bayangan, partikel berat & tekstur untuk FPS maksimal",
	Type = "toggle",
	Default = false,
	Callback = function(v)
		State.AntiLag = v
		applyAntiLag(v)
	end,
})

local regionCardBody = App:AddInfoCard(
	"Network & System",
	"Deteksi Region & IP Pengguna (Live API)",
	"Memuat data jaringan & lokasi region..."
)

local function refreshRegionDisplay()
	fetchNetworkAndRegionAPI(function(net)
		local lines = {
			string.format("• IP Address : %s", net.IP),
			string.format("• Lokasi/Negara : %s (%s)", net.Country, net.City),
			string.format("• Provider / ISP : %s", net.ISP),
			"• Region Terdeteksi per Pengguna Aktif:",
		}
		for _, plr in ipairs(Players:GetPlayers()) do
			local regCode = "ID"
			pcall(function()
				regCode = LocalizationService:GetCountryRegionForPlayerAsync(plr)
			end)
			table.insert(lines, string.format("   - %s (@%s)  →  Region: [%s]", plr.DisplayName, plr.Name, regCode))
		end
		regionCardBody.Text = table.concat(lines, "\n")
	end)
end

App:AddFeature("Network & System", {
	Name = "Perbarui Scan IP & Region",
	Desc = "Memindai ulang IP API & kode region setiap pemain di server",
	Type = "button",
	ButtonText = "SCAN API",
	Callback = function()
		refreshRegionDisplay()
		App:Notify("Memperbarui deteksi IP & Region pengguna...", 2)
	end,
})

-- Jalankan deteksi IP & Region saat startup
refreshRegionDisplay()
bind(Players.PlayerAdded, function()
	task.wait(1)
	refreshRegionDisplay()
end)

-- Buka panel secara otomatis dengan animasi halus saat script dieksekusi
task.delay(0.25, function()
	App:SetOpen(true)
	App:Notify("BimSakSin Hub v2.0 Siap Digunakan!", 3)
end)

return App
