--=============================================================
--  BimSakSin Hub :: Modular UI Framework v1.0 (Merged Suite)
--  Lingkungan : Roblox Studio / Delta Executor / LocalScript
--  Isi       : glass panel, badge verified 3D, floating toggle
--              tengkorak 3D, tab, toggle/slider/button/selector,
--              toast notif, status bar FPS/Ping, aksen 4 sudut,
--              ESP pemain (Team/Teman/Musuh + jarak + avatar +
--              font tebal & bg hitam hanya di teks), ESP generator
--              (% selesai & sisa + jarak), Fly, WalkSpeed, JumpPower,
--              Noclip, Anti-Lag map, Auto Teleport, View pemain,
--              serta deteksi Region & IP pengguna via API.
--  Catatan   : framework UI terpadu dengan seluruh logika fitur
--              langsung terpasang dan aman tanpa kebocoran memori.
--=============================================================

pcall(function()
	local existing = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("BimSakSinHub")
	if existing then existing:Destroy() end
	local pg = game:GetService("Players").LocalPlayer
	if pg and pg:FindFirstChild("PlayerGui") then
		local oldPg = pg.PlayerGui:FindFirstChild("BimSakSinHub")
		if oldPg then oldPg:Destroy() end
	end
end)

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

--=============================================================
-- THEME
--=============================================================
local Theme = {
	Font    = Enum.Font.GothamBold,
	FontMed = Enum.Font.GothamMedium,

	Text     = Color3.fromRGB(22, 28, 42),
	SubText  = Color3.fromRGB(98, 110, 132),
	Accent   = Color3.fromRGB(62, 150, 255),
	AccentDeep = Color3.fromRGB(26, 86, 200),
	AccentSoft = Color3.fromRGB(150, 210, 255),
	Dark     = Color3.fromRGB(18, 24, 38),

	Ease   = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	EaseIn = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	Fast   = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	Soft   = TweenInfo.new(0.60, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out),
}

--=============================================================
-- HELPERS
--=============================================================
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
		Transparency = transparency or 0.7,
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

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
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

--=============================================================
-- SKULL 3D (prosedural HD, tanpa asset ID)
--=============================================================
local function buildSkull(parent)
	local root = new("Frame", {
		Name = "SkullIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.68, 0.68),
		BackgroundTransparency = 1,
	}, parent)

	-- aura nyala
	local aura = new("Frame", {
		Size = UDim2.fromScale(1.45, 1.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, root)
	corner(aura, 999)
	gradient(aura, Theme.AccentSoft, Theme.AccentDeep, 90)

	-- kedalaman bayangan belakang 3D
	local depth = new("Frame", {
		Size = UDim2.fromScale(0.81, 0.71),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 2, 0.39, 3),
		BackgroundColor3 = Color3.fromRGB(115, 145, 200),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, root)
	corner(depth, 999)

	-- tengkorak (cranium)
	local head = new("Frame", {
		Size = UDim2.fromScale(0.80, 0.70),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		BackgroundColor3 = Color3.fromRGB(242, 247, 255),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	corner(head, 999)
	gradient(head, Color3.fromRGB(255, 255, 255), Color3.fromRGB(188, 204, 230), 115)
	stroke(head, Color3.fromRGB(255, 255, 255), 1.1, 0.20)

	-- highlight specular HD
	local spec = new("Frame", {
		Size = UDim2.fromScale(0.38, 0.18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.42, 0.22),
		Rotation = -16,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, head)
	corner(spec, 999)

	-- rahang
	local jaw = new("Frame", {
		Size = UDim2.fromScale(0.44, 0.24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.75),
		BackgroundColor3 = Color3.fromRGB(226, 236, 250),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	corner(jaw, 4)
	gradient(jaw, Color3.fromRGB(246, 250, 255), Color3.fromRGB(178, 194, 220), 115)

	-- mata
	for i = -1, 1, 2 do
		local eye = new("Frame", {
			Size = UDim2.fromScale(0.215, 0.27),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.165 * i, 0.37),
			Rotation = 8 * i,
			BackgroundColor3 = Color3.fromRGB(14, 18, 30),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		corner(eye, 999)

		local shine = new("Frame", {
			Size = UDim2.fromScale(0.30, 0.26),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.35, 0.28),
			BackgroundColor3 = Color3.fromRGB(120, 190, 255),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, eye)
		corner(shine, 999)
	end

	-- hidung
	local nose = new("Frame", {
		Size = UDim2.fromScale(0.10, 0.10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(14, 18, 30),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, root)
	corner(nose, 2)

	-- gigi
	for i = -1, 1 do
		local tooth = new("Frame", {
			Size = UDim2.fromScale(0.022, 0.12),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.08 * i, 0.76),
			BackgroundColor3 = Color3.fromRGB(120, 136, 164),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, root)
		corner(tooth, 2)
	end

	-- animasi idle: mengambang halus + aura berdenyut
	TweenService:Create(root, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.fromScale(0.5, 0.445),
		Rotation = 3,
	}):Play()

	TweenService:Create(aura, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.97,
		Size = UDim2.fromScale(1.70, 1.70),
	}):Play()

	return root
end

--=============================================================
-- BADGE CENTANG BIRU 3D BERANIMASI
--=============================================================
local function buildVerified(parent, px)
	px = px or 20
	local badge = new("Frame", {
		Name = "Verified",
		Size = UDim2.fromOffset(px, px),
		BackgroundTransparency = 1,
	}, parent)

	-- glow di belakang centang
	local glow = new("Frame", {
		Size = UDim2.fromScale(1.55, 1.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.80,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, badge)
	corner(glow, 999)
	gradient(glow, Theme.AccentSoft, Theme.Accent, 90)

	-- kedalaman cakram 3D
	local depthDisc = new("Frame", {
		Size = UDim2.fromScale(0.92, 0.92),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 1, 0.5, 2),
		BackgroundColor3 = Theme.AccentDeep,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, badge)
	corner(depthDisc, 999)

	-- cakram lencana biru 3D glossy
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
	stroke(disc, Color3.fromRGB(255, 255, 255), 1, 0.25)

	-- koordinat centang
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

	-- bayangan centang
	arm(Vector2.new(0.35, 0.58), Vector2.new(0.28, 0.12),  45, Theme.AccentDeep, 4, 0, 1)
	arm(Vector2.new(0.60, 0.50), Vector2.new(0.46, 0.12), -45, Theme.AccentDeep, 4, 0, 1)

	-- batang utama centang
	arm(Vector2.new(0.35, 0.56), Vector2.new(0.28, 0.12),  45, Color3.fromRGB(255, 255, 255), 5)
	arm(Vector2.new(0.60, 0.48), Vector2.new(0.46, 0.12), -45, Color3.fromRGB(255, 255, 255), 5)

	-- animasi halus: denyut glow + napas skala
	local scale = new("UIScale", { Scale = 1 }, badge)
	TweenService:Create(scale, TweenInfo.new(1.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Scale = 1.08,
	}):Play()
	TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.95,
		Size = UDim2.fromScale(1.85, 1.85),
	}):Play()

	return badge
end

--=============================================================
-- HUB
--=============================================================
local Hub = {}
Hub.__index = Hub

function Hub.new(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Hub)
	self.Title       = cfg.Title or "BimSakSin Hub"
	self.Subtitle    = cfg.Subtitle or "Interactive Control Suite"
	self.Pages       = {}
	self.TabButtons  = {}
	self.RowCount    = {}
	self.IsOpen      = false
	self.FPS         = 60

	local parentGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

	local gui = new("ScreenGui", {
		Name = "BimSakSinHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 500,
	}, parentGui)
	self.Gui = gui

	----------------------------------------------------------------
	-- PANEL UTAMA (TRANSFARAN PUTIH SEPERTI WEB GLASSMORPHISM)
	----------------------------------------------------------------
	local root = new("CanvasGroup", {
		Name = "MainPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(592, 424),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.80,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
	}, gui)
	corner(root, 18)
	stroke(root, Color3.fromRGB(255, 255, 255), 1.4, 0.30)
	local rootGrad = gradient(root, Color3.fromRGB(255, 255, 255), Color3.fromRGB(214, 232, 255), 135)
	rootGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.28),
	})
	self.Root  = root
	self.Scale = new("UIScale", { Scale = 0.94 }, root)

	-- aksen 4 sudut
	self.CornerLines = {}
	local function cornerAccent(pos, anchorX, anchorY, delay)
		local hLine = new("Frame", {
			Position = pos,
			AnchorPoint = Vector2.new(anchorX, anchorY),
			Size = UDim2.fromOffset(0, 2),
			BackgroundColor3 = Theme.AccentSoft,
			BorderSizePixel = 0,
			ZIndex = 30,
		}, root)
		corner(hLine, 1)

		local vLine = new("Frame", {
			Position = pos,
			AnchorPoint = Vector2.new(anchorX, anchorY),
			Size = UDim2.fromOffset(2, 0),
			BackgroundColor3 = Theme.AccentSoft,
			BorderSizePixel = 0,
			ZIndex = 30,
		}, root)
		corner(vLine, 1)

		table.insert(self.CornerLines, { h = hLine, v = vLine, delay = delay })
	end
	cornerAccent(UDim2.fromOffset(8, 8), 0, 0, 0.00)
	cornerAccent(UDim2.new(1, -8, 0, 8), 1, 0, 0.05)
	cornerAccent(UDim2.new(0, 8, 1, -8), 0, 1, 0.10)
	cornerAccent(UDim2.new(1, -8, 1, -8), 1, 1, 0.15)

	------------------------------------------------------------
	-- HEADER
	------------------------------------------------------------
	local header = new("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 46),
		Position = UDim2.fromOffset(14, 14),
	}, root)

	local titleRow = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
	}, header)
	new("UIListLayout", {
		FillDirection     = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding           = UDim.new(0, 8),
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
	new("UIShadow", { BlurRadius = 6, Color = Color3.fromRGB(120, 180, 255), Offset = Vector2.new(0, 1), Transparency = 0.55 }, titleLbl)

	buildVerified(titleRow, 19).LayoutOrder = 2

	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, -120, 0, 14),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = self.Subtitle,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local function headerButton(glyph, xOffset, color)
		local btn = new("TextButton", {
			Text = glyph,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = color,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.62,
			Size = UDim2.fromOffset(28, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			AutoButtonColor = false,
		}, header)
		corner(btn, 9)
		stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.45)
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundTransparency = 0.30, TextColor3 = Theme.AccentDeep }, Theme.Fast)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundTransparency = 0.62, TextColor3 = color }, Theme.Fast)
		end)
		return btn
	end

	local btnClose = headerButton("✕", 0, Color3.fromRGB(70, 80, 100))
	local btnMin   = headerButton("–", -34, Color3.fromRGB(70, 80, 100))

	------------------------------------------------------------
	-- SIDEBAR
	------------------------------------------------------------
	local sidebar = new("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.68,
		Size = UDim2.new(0, 148, 1, -128),
		Position = UDim2.fromOffset(14, 72),
		BorderSizePixel = 0,
	}, root)
	corner(sidebar, 12)
	stroke(sidebar, Color3.fromRGB(255, 255, 255), 1, 0.45)
	new("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, sidebar)
	self.Sidebar = sidebar

	------------------------------------------------------------
	-- CONTENT
	------------------------------------------------------------
	local content = new("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -188, 1, -128),
		Position = UDim2.fromOffset(174, 72),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollBarImageTransparency = 0.45,
		ClipsDescendants = true,
	}, root)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)
	new("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, content)
	self.Content = content

	------------------------------------------------------------
	-- FOOTER / STATUS BAR
	------------------------------------------------------------
	local footer = new("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 18),
		Position = UDim2.new(0, 14, 1, -32),
	}, root)

	self.StatusLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = "FPS 60   •   PING 0 ms   •   PLAYERS 0",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, footer)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = "v1.0",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, footer)

	------------------------------------------------------------
	-- FLOATING TOGGLE (PUTIH TRANSFARAN + TENGKORAK 3D HD)
	------------------------------------------------------------
	local float = new("CanvasGroup", {
		Name = "FloatingToggle",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.74,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, gui)
	corner(float, 999)
	stroke(float, Color3.fromRGB(255, 255, 255), 1.5, 0.25)
	gradient(float, Color3.fromRGB(255, 255, 255), Color3.fromRGB(198, 224, 255), 135)
	self.Floating = float

	local floatGlow = new("Frame", {
		Size = UDim2.fromScale(1.22, 1.22),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, float)
	corner(floatGlow, 999)

	buildSkull(float)
	draggable(float)

	local floatBtn = new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, float)

	floatBtn.MouseEnter:Connect(function()
		tween(float, { Size = UDim2.fromOffset(68, 68), BackgroundTransparency = 0.58 }, Theme.Fast)
	end)
	floatBtn.MouseLeave:Connect(function()
		local sz = self.IsOpen and UDim2.fromOffset(48, 48) or UDim2.fromOffset(62, 62)
		local tr = self.IsOpen and 0.64 or 0.74
		tween(float, { Size = sz, BackgroundTransparency = tr }, Theme.Fast)
	end)
	floatBtn.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)

	TweenService:Create(floatGlow, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.97,
		Size = UDim2.fromScale(1.45, 1.45),
	}):Play()

	tween(float, { GroupTransparency = 0 }, Theme.Soft)

	------------------------------------------------------------
	-- TOAST HOLDER
	------------------------------------------------------------
	self.ToastHolder = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 24),
		Size = UDim2.fromOffset(255, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, gui)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.ToastHolder)

	------------------------------------------------------------
	-- EVENTS
	------------------------------------------------------------
	btnClose.MouseButton1Click:Connect(function() self:SetOpen(false) end)
	btnMin.MouseButton1Click:Connect(function() self:SetOpen(false) end)
	draggable(root, header)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
			self:SetOpen(not self.IsOpen)
		end
	end)

	------------------------------------------------------------
	-- STATUS LOOP
	------------------------------------------------------------
	task.spawn(function()
		local frames, elapsed = 0, 0
		RunService.RenderStepped:Connect(function(dt)
			frames  += 1
			elapsed += dt
			if elapsed >= 1 then
				self.FPS = math.floor(frames / elapsed + 0.5)
				frames, elapsed = 0, 0
			end
		end)

		while gui.Parent do
			task.wait(1)
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
			end)
			self.StatusLabel.Text = string.format(
				"FPS %d   •   PING %d ms   •   PLAYERS %d   •   %s",
				self.FPS or 60, ping, #Players:GetPlayers(), os.date("%H:%M:%S")
			)
		end
	end)

	return self
end

--=============================================================
-- OPEN / CLOSE
--=============================================================
function Hub:SetOpen(open)
	if self.IsOpen == open then return end
	self.IsOpen = open

	if open then
		self.Root.Visible = true
		self.Root.GroupTransparency = 1
		self.Scale.Scale = 0.92

		tween(self.Scale, { Scale = 1 }, Theme.Ease)
		tween(self.Root, { GroupTransparency = 0 }, Theme.Soft)

		for _, line in ipairs(self.CornerLines) do
			line.h.Size = UDim2.fromOffset(0, 2)
			line.v.Size = UDim2.fromOffset(2, 0)
			task.delay(line.delay, function()
				if self.IsOpen then
					tween(line.h, { Size = UDim2.fromOffset(20, 2) }, Theme.Ease)
					tween(line.v, { Size = UDim2.fromOffset(2, 20) }, Theme.Ease)
				end
			end)
		end

		tween(self.Floating, { Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 0.64 }, Theme.Fast)
	else
		for _, line in ipairs(self.CornerLines) do
			tween(line.h, { Size = UDim2.fromOffset(0, 2) }, Theme.EaseIn)
			tween(line.v, { Size = UDim2.fromOffset(2, 0) }, Theme.EaseIn)
		end

		tween(self.Scale, { Scale = 0.92 }, Theme.EaseIn)
		tween(self.Root, { GroupTransparency = 1 }, Theme.Soft)
		task.delay(0.6, function()
			if not self.IsOpen then
				self.Root.Visible = false
			end
		end)
		tween(self.Floating, { Size = UDim2.fromOffset(62, 62), BackgroundTransparency = 0.74 }, Theme.Ease)
	end
end

--=============================================================
-- TAB / KATEGORI
--=============================================================
function Hub:AddCategory(name)
	if self.Pages[name] then return self.Pages[name] end

	local btn = new("TextButton", {
		Name = name,
		Text = "",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		AutoButtonColor = false,
		LayoutOrder = #self.TabButtons + 1,
	}, self.Sidebar)
	corner(btn, 9)

	local indicator = new("Frame", {
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, btn)
	corner(indicator, 2)

	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Font = Theme.Font,
		TextSize = 12,
		Text = name,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)

	btn.MouseEnter:Connect(function()
		if self.ActiveTab ~= name then
			tween(btn, { BackgroundTransparency = 0.62 }, Theme.Fast)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= name then
			tween(btn, { BackgroundTransparency = 1 }, Theme.Fast)
		end
	end)
	btn.MouseButton1Click:Connect(function()
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
		Size = UDim2.new(1, 0, 0, 22),
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
		Size = UDim2.fromOffset(0, 2),
		Position = UDim2.new(0, 0, 0, 24),
	}, pageTitle)
	corner(underline, 1)
	tween(underline, { Size = UDim2.fromOffset(26, 2) }, Theme.Ease)

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
		tween(tab.button, { BackgroundTransparency = active and 0.35 or 1 }, Theme.Fast)
		tween(tab.indicator, { Size = UDim2.new(0, 3, active and 0.55 or 0, 0) }, Theme.Fast)
		tab.label.TextColor3 = active and Theme.AccentDeep or Theme.SubText
		tab.label.Font = active and Theme.Font or Theme.FontMed
	end
end

--=============================================================
-- KONTROL: TOGGLE / SLIDER / BUTTON / SELECTOR
--=============================================================
local function buildToggle(parent, default, onChanged)
	local state = default and true or false

	local track = new("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(40, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(202, 210, 224),
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
	stroke(knob, Color3.fromRGB(120, 132, 150), 1, 0.75)

	local function apply(animate)
		local goalColor = state and Theme.Accent or Color3.fromRGB(202, 210, 224)
		local goalPos   = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
		if animate then
			tween(track, { BackgroundColor3 = goalColor }, Theme.Fast)
			tween(knob,  { Position = goalPos }, Theme.Fast)
		else
			track.BackgroundColor3 = goalColor
			knob.Position = goalPos
		end
	end
	apply(false)

	track.MouseButton1Click:Connect(function()
		state = not state
		apply(true)
		if onChanged then onChanged(state) end
	end)

	return track
end

local function buildSlider(parent, min, max, default, onChanged)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(150, 22),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundTransparency = 1,
	}, parent)

	local valueLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(42, 22),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = tostring(default),
		TextColor3 = Theme.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)

	local track = new("Frame", {
		Size = UDim2.new(1, -48, 0, 6),
		Position = UDim2.fromOffset(48, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(206, 214, 228),
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
	stroke(knob, Theme.Accent, 1, 0.35)

	local value = math.clamp(default or min, min, max)

	local function setFromX(x)
		if track.AbsoluteSize.X <= 0 then return end
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		value = min + (max - min) * rel
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.fromScale(rel, 0.5)
		valueLbl.Text = tostring(math.floor(value + 0.5))
		if onChanged then onChanged(value) end
	end

	local dragging = false

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
			tween(knob, { Size = UDim2.fromOffset(17, 17) }, Theme.Fast)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				tween(knob, { Size = UDim2.fromOffset(14, 14) }, Theme.Fast)
			end
		end
	end)

	-- posisi awal
	task.defer(function()
		local rel = (value - min) / math.max(max - min, 0.0001)
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.fromScale(rel, 0.5)
		valueLbl.Text = tostring(math.floor(value + 0.5))
	end)

	return holder
end

local function buildButton(parent, labelText, onClick)
	local btn = new("TextButton", {
		Text = labelText or "RUN",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.fromOffset(78, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		AutoButtonColor = false,
	}, parent)
	corner(btn, 8)
	gradient(btn, Theme.AccentSoft, Theme.AccentDeep, 90)
	stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.6)

	btn.MouseEnter:Connect(function()
		tween(btn, { Size = UDim2.fromOffset(84, 28) }, Theme.Fast)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { Size = UDim2.fromOffset(78, 26) }, Theme.Fast)
	end)
	btn.MouseButton1Click:Connect(function()
		local orig = btn.Text
		btn.Text = "✓"
		task.delay(0.7, function()
			if btn and btn.Parent then btn.Text = orig end
		end)
		if onClick then onClick() end
	end)

	return btn
end

local function buildSelector(parent, getOptions, defaultText, onChanged)
	local idx = 0
	local btn = new("TextButton", {
		Text = defaultText or "Pilih",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.AccentDeep,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromOffset(118, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		AutoButtonColor = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	corner(btn, 8)
	stroke(btn, Theme.Accent, 1, 0.50)

	btn.MouseButton1Click:Connect(function()
		local opts = getOptions and getOptions() or {}
		if #opts == 0 then
			btn.Text = "Kosong"
			return
		end
		idx = (idx % #opts) + 1
		local val = opts[idx]
		btn.Text = tostring(val)
		if onChanged then onChanged(val) end
	end)

	return btn
end

--=============================================================
-- TAMBAH FITUR & KARTU INFORMASI
--=============================================================
function Hub:AddFeature(category, data)
	if not self.Pages[category] then
		self:AddCategory(category)
	end
	local page = self.Pages[category]
	self.RowCount[category] += 1

	local row = new("Frame", {
		Name = data.Name or "Feature",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.56,
		BorderSizePixel = 0,
		LayoutOrder = self.RowCount[category],
	}, page)
	corner(row, 12)
	local rs = stroke(row, Color3.fromRGB(255, 255, 255), 1, 0.45)

	local nameLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -180, 0, 17),
		Font = Theme.Font,
		TextSize = 13,
		Text = data.Name or "Fitur",
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local descLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 25),
		Size = UDim2.new(1, -180, 0, 16),
		Font = Theme.FontMed,
		TextSize = 11,
		Text = data.Desc or "",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	-- kontrol
	local controlHolder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
	}, row)

	if data.Type == "slider" then
		buildSlider(controlHolder, data.Min or 0, data.Max or 100, data.Default or 0, data.Callback)
	elseif data.Type == "button" then
		buildButton(controlHolder, data.ButtonText or "RUN", data.Callback)
	elseif data.Type == "selector" then
		buildSelector(controlHolder, data.GetOptions, data.DefaultText, data.Callback)
	else
		buildToggle(controlHolder, data.Default, data.Callback)
	end

	-- hover halus
	row.MouseEnter:Connect(function()
		tween(row, { BackgroundTransparency = 0.30 }, Theme.Fast)
		tween(rs,  { Transparency = 0.15 }, Theme.Fast)
		tween(nameLbl, { TextColor3 = Theme.AccentDeep }, Theme.Fast)
	end)
	row.MouseLeave:Connect(function()
		tween(row, { BackgroundTransparency = 0.56 }, Theme.Fast)
		tween(rs,  { Transparency = 0.45 }, Theme.Fast)
		tween(nameLbl, { TextColor3 = Theme.Text }, Theme.Fast)
	end)

	return row
end

function Hub:AddInfoCard(category, title, bodyText)
	if not self.Pages[category] then
		self:AddCategory(category)
	end
	local page = self.Pages[category]
	self.RowCount[category] += 1

	local card = new("Frame", {
		Name = title or "InfoCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.56,
		BorderSizePixel = 0,
		LayoutOrder = self.RowCount[category],
	}, page)
	corner(card, 12)
	stroke(card, Color3.fromRGB(255, 255, 255), 1, 0.45)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 9),
		PaddingBottom = UDim.new(0, 9),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, card)
	new("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Theme.Font,
		TextSize = 12,
		Text = title or "Informasi",
		TextColor3 = Theme.AccentDeep,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, card)

	local body = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.FontMed,
		TextSize = 11,
		Text = bodyText or "",
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 2,
	}, card)

	return body
end

--=============================================================
-- NOTIFIKASI
--=============================================================
function Hub:Notify(text, duration)
	duration = duration or 3

	local toast = new("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Color3.fromRGB(20, 26, 40),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, self.ToastHolder)
	corner(toast, 10)
	stroke(toast, Theme.AccentSoft, 1, 0.6)

	local accentBar = new("Frame", {
		Size = UDim2.new(0, 3, 0.6, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, toast)
	corner(accentBar, 2)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Theme.FontMed,
		TextSize = 12,
		Text = text,
		TextColor3 = Color3.fromRGB(236, 244, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, toast)

	tween(toast, { GroupTransparency = 0 }, Theme.Soft)

	task.delay(duration, function()
		if not toast or not toast.Parent then return end
		tween(toast, { GroupTransparency = 1 }, Theme.Soft)
		task.delay(0.5, function()
			if toast and toast.Parent then toast:Destroy() end
		end)
	end)
end

--=============================================================
-- INISIALISASI & FITUR TERGABUNG PADA PANEL UTAMA
--=============================================================
local App = Hub.new({
	Title    = "BimSakSin Hub",
	Subtitle = "Interactive Control & Visual Suite",
})

local State = {
	PlayerESP       = false,
	AvatarMarker    = true,
	ESPDistance     = true,
	ESPFilter       = "Semua", -- "Semua" | "Musuh" | "Teman"
	GeneratorESP    = false,

	FlyEnabled      = false,
	FlySpeed        = 65,
	WalkSpeedOn     = false,
	WalkSpeedVal    = 32,
	JumpPowerOn     = false,
	JumpPowerVal    = 85,
	Noclip          = false,

	AntiLag         = false,
	AutoTeleport    = false,
	AutoTeleportSec = 3,
	SelectedTarget  = nil,
	Spectating      = false,
}

local ESPObjects = {}
local GenObjects = {}

-- 1. ESP PEMAIN (TEAM / TEMAN / MUSUH + JARAK + TANDA AVATAR + FONT TEBAL & BG HITAM DI TEKS SAJA)
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
		return "Teman", Color3.fromRGB(72, 225, 130)
	elseif sameTeam then
		return "Team", Color3.fromRGB(75, 175, 255)
	else
		return "Musuh", Color3.fromRGB(255, 85, 85)
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

	local hl = new("Highlight", {
		Name = "BSS_AvatarESP",
		Adornee = char,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillTransparency = 0.72,
		OutlineTransparency = 0.05,
	}, App.Gui)

	local bb = new("BillboardGui", {
		Name = "BSS_PlayerTag",
		Adornee = hrp,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 260, 0, 32),
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

	-- Latar belakang hitam tebal sedang hanya menempel pada teks (bukan kotak besar)
	local label = new("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		TextStrokeTransparency = 0.15,
	}, holder)
	corner(label, 5)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
	}, label)

	ESPObjects[plr] = { Billboard = bb, Highlight = hl, Label = label }
end

task.spawn(function()
	while App.Gui and App.Gui.Parent do
		task.wait(0.1)
		if not State.PlayerESP then
			for plr, _ in pairs(ESPObjects) do
				clearPlayerESP(plr)
			end
			continue
		end

		local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then continue end
			local char = plr.Character
			local hrp  = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
			local hum  = char and char:FindFirstChildOfClass("Humanoid")

			if not char or not hrp or (hum and hum.Health <= 0) then
				clearPlayerESP(plr)
				continue
			end

			local rel, relColor = getPlayerRelation(plr)
			local allowed = (State.ESPFilter == "Semua")
				or (State.ESPFilter == "Musuh" and rel == "Musuh")
				or (State.ESPFilter == "Teman" and (rel == "Team" or rel == "Teman"))

			if not allowed then
				clearPlayerESP(plr)
				continue
			end

			if not ESPObjects[plr] or ESPObjects[plr].Billboard.Adornee ~= hrp then
				createPlayerESP(plr)
			end

			local obj = ESPObjects[plr]
			if obj then
				local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude + 0.5) or 0
				local distPart = State.ESPDistance and string.format(" [%dm]", dist) or ""
				obj.Label.Text = string.format("[%s] %s%s", rel:upper(), plr.DisplayName, distPart)
				obj.Label.TextColor3 = relColor
				obj.Highlight.Enabled = State.AvatarMarker
				obj.Highlight.FillColor = relColor
				obj.Highlight.OutlineColor = relColor
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	clearPlayerESP(plr)
end)

-- 2. ESP GENERATOR (JARAK + PERSEN SELESAI & BELUM DIKERJAKAN)
local function extractGenPercent(inst)
	local keys = { "Progress", "Percent", "Percentage", "RepairProgress", "Charge", "Completion", "Work", "Value" }
	for _, k in ipairs(keys) do
		local v = inst:GetAttribute(k)
		if type(v) == "number" then
			return v <= 1 and math.clamp(v * 100, 0, 100) or math.clamp(v, 0, 100)
		end
	end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("NumberValue") or d:IsA("IntValue") then
			local n = d.Name:lower()
			if n:find("prog") or n:find("perc") or n:find("rep") or n:find("charg") or n:find("work") or n:find("val") then
				return d.Value <= 1 and math.clamp(d.Value * 100, 0, 100) or math.clamp(d.Value, 0, 100)
			end
		elseif d:IsA("BoolValue") then
			local n = d.Name:lower()
			if (n:find("done") or n:find("fixed") or n:find("complete") or n:find("repaired")) and d.Value == true then
				return 100
			end
		end
	end
	if inst:GetAttribute("Completed") == true or inst:GetAttribute("Repaired") == true or inst:GetAttribute("Fixed") == true then
		return 100
	end
	return 0
end

local function clearGenESP()
	for _, obj in pairs(GenObjects) do
		if obj.Billboard then obj.Billboard:Destroy() end
		if obj.Highlight then obj.Highlight:Destroy() end
	end
	table.clear(GenObjects)
end

local function findGenerators()
	local list = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") or obj:IsA("BasePart") then
			local n = obj.Name:lower()
			if n:find("generator") or n == "gen" or n:match("^gen[%d_]") then
				if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent.Name:lower():find("generator") then
					continue
				end
				table.insert(list, obj)
			end
		end
	end
	return list
end

task.spawn(function()
	local gens = {}
	local lastScan = 0

	while App.Gui and App.Gui.Parent do
		task.wait(0.25)
		if not State.GeneratorESP then
			if next(GenObjects) ~= nil then clearGenESP() end
			continue
		end

		if tick() - lastScan >= 3 then
			gens = findGenerators()
			lastScan = tick()
		end

		local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		for _, gen in ipairs(gens) do
			if not gen or not gen.Parent then continue end
			local adornee = gen:IsA("Model") and (gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")) or gen
			if not adornee then continue end

			if not GenObjects[gen] then
				local hl = new("Highlight", {
					Name = "BSS_GenESP",
					Adornee = gen,
					DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
					FillTransparency = 0.76,
					OutlineTransparency = 0.1,
				}, App.Gui)

				local bb = new("BillboardGui", {
					Name = "BSS_GenTag",
					Adornee = adornee,
					AlwaysOnTop = true,
					Size = UDim2.new(0, 290, 0, 32),
					StudsOffset = Vector3.new(0, 3.0, 0),
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
					BackgroundColor3 = Color3.fromRGB(10, 12, 18),
					BackgroundTransparency = 0.25,
					BorderSizePixel = 0,
					Font = Enum.Font.GothamBlack,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(255, 215, 80),
					TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					TextStrokeTransparency = 0.15,
				}, holder)
				corner(lbl, 5)
				new("UIPadding", {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					PaddingTop = UDim.new(0, 2),
					PaddingBottom = UDim.new(0, 2),
				}, lbl)

				GenObjects[gen] = { Billboard = bb, Highlight = hl, Label = lbl }
			end

			local donePct = math.floor(extractGenPercent(gen) + 0.5)
			local leftPct = math.max(0, 100 - donePct)
			local dist    = myHrp and math.floor((myHrp.Position - adornee.Position).Magnitude + 0.5) or 0
			local col     = donePct >= 100 and Color3.fromRGB(72, 225, 130)
				or (donePct > 0 and Color3.fromRGB(255, 200, 65) or Color3.fromRGB(255, 110, 110))

			local gObj = GenObjects[gen]
			gObj.Label.Text = string.format("GEN [%dm] • Selesai %d%% | Sisa %d%%", dist, donePct, leftPct)
			gObj.Label.TextColor3 = col
			gObj.Highlight.FillColor = col
			gObj.Highlight.OutlineColor = col
		end
	end
end)

-- 3. FLY, WALKSPEED, JUMP POWER, NOCLIP
local flyBV, flyBG

local function stopFly()
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

local function startFly()
	stopFly()
	local char = LocalPlayer.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	hum.PlatformStand = true
	flyBG = new("BodyGyro", { P = 9e4, MaxTorque = Vector3.new(9e9, 9e9, 9e9), CFrame = hrp.CFrame }, hrp)
	flyBV = new("BodyVelocity", { Velocity = Vector3.zero, MaxForce = Vector3.new(9e9, 9e9, 9e9) }, hrp)
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")

	if hum then
		if State.WalkSpeedOn then hum.WalkSpeed = State.WalkSpeedVal end
		if State.JumpPowerOn then
			hum.UseJumpPower = true
			hum.JumpPower = State.JumpPowerVal
		end
	end

	if State.FlyEnabled and hrp then
		if not flyBV or not flyBV.Parent then startFly() end
		local cam = Workspace.CurrentCamera
		if cam and flyBV and flyBG then
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
			if dir.Magnitude > 0 then dir = dir.Unit * State.FlySpeed end
			flyBV.Velocity = dir
			flyBG.CFrame = cam.CFrame
		end
	elseif flyBV then
		stopFly()
	end
end)

RunService.Stepped:Connect(function()
	if not State.Noclip then return end
	local char = LocalPlayer.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then
			p.CanCollide = false
		end
	end
end)

-- 4. ANTI-LAG MAP
local function setAntiLag(enabled)
	if enabled then
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
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
		App:Notify("Anti-Lag aktif: efek berat map dikurangi", 2.5)
	else
		Lighting.GlobalShadows = true
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
		App:Notify("Anti-Lag nonaktif", 2)
	end
end

-- 5. AUTO TELEPORT & VIEW PEMAIN
local function getTargetList()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(out, p.Name) end
	end
	return out
end

local function tpToTarget(name)
	if not name then return end
	local plr = Players:FindFirstChild(name)
	local tHrp = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local mHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if tHrp and mHrp then
		mHrp.CFrame = tHrp.CFrame * CFrame.new(0, 2, 3)
	end
end

local function spectateTarget(active, name)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if active then
		local plr = name and Players:FindFirstChild(name)
		local hum = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
	else
		local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myHum then cam.CameraSubject = myHum end
	end
end

task.spawn(function()
	while App.Gui and App.Gui.Parent do
		task.wait(math.max(0.5, State.AutoTeleportSec))
		if State.AutoTeleport and State.SelectedTarget then
			tpToTarget(State.SelectedTarget)
		end
	end
end)

-- 6. DETEKSI REGION & IP API SETIAP PENGGUNA
local function fetchNetworkAPI(cb)
	task.spawn(function()
		local info = { IP = "Sandbox Protected", Country = "ID", City = "-", ISP = "-" }
		local req = (syn and syn.request) or http_request or request or (http and http.request)
		if req then
			local ok, res = pcall(function() return req({ Url = "http://ip-api.com/json/", Method = "GET" }) end)
			if ok and res and res.Body then
				local pOk, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
				if pOk and type(decoded) == "table" and decoded.status == "success" then
					info.IP = tostring(decoded.query or info.IP)
					info.Country = tostring(decoded.country or info.Country)
					info.City = tostring(decoded.city or info.City)
					info.ISP = tostring(decoded.isp or info.ISP)
				end
			end
		else
			pcall(function() info.Country = LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer) end)
		end
		if cb then cb(info) end
	end)
end

-- REGISTRASI KATEGORI & FITUR KE PANEL
App:AddCategory("Visual & ESP")
App:AddFeature("Visual & ESP", {
	Name = "Player ESP",
	Desc = "Nama font tebal + bg hitam di teks, tanda avatar & jarak",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.PlayerESP = v end,
})
App:AddFeature("Visual & ESP", {
	Name = "Tanda Avatar ESP",
	Desc = "Menampilkan highlight avatar sesuai Team / Teman / Musuh",
	Type = "toggle",
	Default = true,
	Callback = function(v) State.AvatarMarker = v end,
})
App:AddFeature("Visual & ESP", {
	Name = "Tampilkan Jarak ESP",
	Desc = "Menampilkan jarak meter pada label pemain",
	Type = "toggle",
	Default = true,
	Callback = function(v) State.ESPDistance = v end,
})
App:AddFeature("Visual & ESP", {
	Name = "Filter Target ESP",
	Desc = "Pilih tampilkan Semua, Musuh, atau Teman/Team",
	Type = "selector",
	GetOptions = function() return { "Semua", "Musuh", "Teman" } end,
	DefaultText = "Semua",
	Callback = function(v) State.ESPFilter = v end,
})
App:AddFeature("Visual & ESP", {
	Name = "Generator ESP",
	Desc = "Jarak, % sudah dikerjakan & % belum dikerjakan tiap generator",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.GeneratorESP = v end,
})

App:AddCategory("Movement")
App:AddFeature("Movement", {
	Name = "Fly",
	Desc = "Terbang bebas mengikuti kamera (WASD + Space / LeftShift)",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.FlyEnabled = v; if not v then stopFly() end end,
})
App:AddFeature("Movement", {
	Name = "Fly Speed",
	Desc = "Atur kecepatan terbang",
	Type = "slider",
	Min = 16,
	Max = 250,
	Default = 65,
	Callback = function(v) State.FlySpeed = v end,
})
App:AddFeature("Movement", {
	Name = "WalkHack / Speed",
	Desc = "Mengunci kecepatan jalan/lari karakter",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.WalkSpeedOn = v end,
})
App:AddFeature("Movement", {
	Name = "Nilai WalkSpeed",
	Desc = "Atur kecepatan jalan/lari (normal 16)",
	Type = "slider",
	Min = 16,
	Max = 200,
	Default = 32,
	Callback = function(v) State.WalkSpeedVal = v end,
})
App:AddFeature("Movement", {
	Name = "Jump Power",
	Desc = "Mengatur kekuatan lompatan karakter",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.JumpPowerOn = v end,
})
App:AddFeature("Movement", {
	Name = "Nilai JumpPower",
	Desc = "Atur tinggi lompat (normal 50)",
	Type = "slider",
	Min = 50,
	Max = 250,
	Default = 85,
	Callback = function(v) State.JumpPowerVal = v end,
})
App:AddFeature("Movement", {
	Name = "Noclip",
	Desc = "Menembus dinding/objek saat aktif",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.Noclip = v end,
})

App:AddCategory("Player & World")
App:AddFeature("Player & World", {
	Name = "Target Pemain",
	Desc = "Pilih pemain untuk Teleport / Auto Teleport / View",
	Type = "selector",
	GetOptions = getTargetList,
	DefaultText = "Pilih Target",
	Callback = function(name)
		State.SelectedTarget = name
		if State.Spectating then spectateTarget(true, name) end
	end,
})
App:AddFeature("Player & World", {
	Name = "Teleport ke Pemain",
	Desc = "Pindah langsung ke posisi target terpilih",
	Type = "button",
	ButtonText = "TELEPORT",
	Callback = function() tpToTarget(State.SelectedTarget) end,
})
App:AddFeature("Player & World", {
	Name = "Auto Teleport",
	Desc = "Teleport otomatis ke target sesuai interval detik",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.AutoTeleport = v end,
})
App:AddFeature("Player & World", {
	Name = "Interval Auto TP (Detik)",
	Desc = "Jeda waktu Auto Teleport",
	Type = "slider",
	Min = 1,
	Max = 15,
	Default = 3,
	Callback = function(v) State.AutoTeleportSec = v end,
})
App:AddFeature("Player & World", {
	Name = "View Pemain",
	Desc = "Arahkan kamera ke pemain target",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.Spectating = v; spectateTarget(v, State.SelectedTarget) end,
})
App:AddFeature("Player & World", {
	Name = "Anti-Lag Map",
	Desc = "Optimasi grafis & partikel pada map untuk menaikkan FPS",
	Type = "toggle",
	Default = false,
	Callback = function(v) State.AntiLag = v; setAntiLag(v) end,
})

local regionCard = App:AddInfoCard("Player & World", "Region & IP API Pengguna", "Memuat data IP & region...")
local function updateRegionInfo()
	fetchNetworkAPI(function(info)
		local lines = {
			string.format("IP: %s | Lokasi: %s (%s) | ISP: %s", info.IP, info.Country, info.City, info.ISP),
		}
		for _, plr in ipairs(Players:GetPlayers()) do
			local code = "ID"
			pcall(function() code = LocalizationService:GetCountryRegionForPlayerAsync(plr) end)
			table.insert(lines, string.format("• %s (@%s) -> Region: %s", plr.DisplayName, plr.Name, code))
		end
		regionCard.Text = table.concat(lines, "\n")
	end)
end

App:AddFeature("Player & World", {
	Name = "Cek Ulang IP & Region API",
	Desc = "Memperbarui data IP & region setiap pengguna aktif",
	Type = "button",
	ButtonText = "CEK API",
	Callback = function() updateRegionInfo(); App:Notify("Memperbarui data IP & Region...", 2) end,
})

updateRegionInfo()
Players.PlayerAdded:Connect(function()
	task.wait(1)
	updateRegionInfo()
end)

task.delay(0.2, function()
	App:SetOpen(true)
end)

return App
