--=============================================================
--  BimSakSin Hub :: Modular UI Framework v1.0
--  Lingkungan : Roblox Studio / LocalScript di game milikmu sendiri
--  Isi       : glass panel, badge verified 3D, floating toggle
--              tengkorak 3D, tab, toggle/slider/button, tooltip,
--              toast notif, status bar FPS/Ping, aksen 4 sudut
--  Catatan   : framework UI murni. Semua aksi fitur diserahkan ke
--              callback milikmu (RemoteEvent / logika game sendiri).
--=============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")

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
-- SKULL 3D (prosedural, tanpa asset ID)
--=============================================================
local function buildSkull(parent)
	local root = new("Frame", {
		Name = "SkullIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.66, 0.66),
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
	stroke(head, Color3.fromRGB(255, 255, 255), 1, 0.25)

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

	-- koordinat centang (skala 0-1 dari badge)
	local function arm(pos, size, rot, color, z, offX, offY)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(pos.X, offX or 0, pos.Y, offY or 0),
			Size = UDim2.fromScale(size.X, size.Y),
			Rotation = rot,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z,
		}, badge)
		corner(f, 999)
		return f
	end

	-- bayangan (efek tebal / 3D)
	arm(Vector2.new(0.292, 0.625), Vector2.new(0.354, 0.105),  45, Theme.AccentDeep, 2, 1, 2)
	arm(Vector2.new(0.625, 0.542), Vector2.new(0.589, 0.105), -45, Theme.AccentDeep, 2, 1, 2)

	-- batang utama
	local a1 = arm(Vector2.new(0.292, 0.625), Vector2.new(0.354, 0.105),  45, Color3.fromRGB(255, 255, 255), 3)
	local a2 = arm(Vector2.new(0.625, 0.542), Vector2.new(0.589, 0.105), -45, Color3.fromRGB(255, 255, 255), 3)
	gradient(a1, Color3.fromRGB(255, 255, 255), Theme.AccentSoft, 45)
	gradient(a2, Color3.fromRGB(210, 240, 255), Theme.Accent, 45)
	stroke(a1, Color3.fromRGB(255, 255, 255), 1, 0.35)
	stroke(a2, Color3.fromRGB(255, 255, 255), 1, 0.35)

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
	self.Subtitle    = cfg.Subtitle or "Developer Panel"
	self.Pages       = {}
	self.TabButtons  = {}
	self.RowCount    = {}
	self.IsOpen      = false
	self.FPS         = 60

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local gui = new("ScreenGui", {
		Name = "BimSakSinHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 500,
	}, playerGui)
	self.Gui = gui

	----------------------------------------------------------------
	-- PANEL UTAMA
	----------------------------------------------------------------
	local root = new("CanvasGroup", {
		Name = "MainPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(568, 408),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
	}, gui)
	corner(root, 18)
	stroke(root, Color3.fromRGB(255, 255, 255), 1.4, 0.4)
	local rootGrad = gradient(root, Color3.fromRGB(255, 255, 255), Color3.fromRGB(198, 220, 255), 135)
	rootGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.35),
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
		Padding           = UDim.new(0, 7),
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
			BackgroundTransparency = 0.55,
			Size = UDim2.fromOffset(28, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			AutoButtonColor = false,
		}, header)
		corner(btn, 9)
		stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.5)
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundTransparency = 0.30, TextColor3 = Theme.AccentDeep }, Theme.Fast)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundTransparency = 0.55, TextColor3 = color }, Theme.Fast)
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
		BackgroundTransparency = 0.50,
		Size = UDim2.new(0, 144, 1, -128),
		Position = UDim2.fromOffset(14, 72),
		BorderSizePixel = 0,
	}, root)
	corner(sidebar, 12)
	stroke(sidebar, Color3.fromRGB(255, 255, 255), 1, 0.55)
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
		Size = UDim2.new(1, -184, 1, -128),
		Position = UDim2.fromOffset(170, 72),
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
	new("UIPadding", { PaddingRight = UDim.new(0, 6) }, content)
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
	-- FLOATING TOGGLE (TENGKORAK 3D)
	------------------------------------------------------------
	local float = new("CanvasGroup", {
		Name = "FloatingToggle",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = Color3.fromRGB(20, 26, 40),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, gui)
	corner(float, 999)
	stroke(float, Theme.AccentSoft, 1.4, 0.45)
	gradient(float, Color3.fromRGB(38, 52, 84), Color3.fromRGB(12, 16, 26), 135)
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
		tween(float, { Size = UDim2.fromOffset(66, 66) }, Theme.Fast)
	end)
	floatBtn.MouseLeave:Connect(function()
		tween(float, { Size = UDim2.fromOffset(60, 60) }, Theme.Fast)
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
		Size = UDim2.fromOffset(250, 0),
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
				tween(line.h, { Size = UDim2.fromOffset(18, 2) }, Theme.Ease)
				tween(line.v, { Size = UDim2.fromOffset(2, 18) }, Theme.Ease)
			end)
		end

		tween(self.Floating, { Size = UDim2.fromOffset(46, 46), BackgroundTransparency = 0.35 }, Theme.Fast)
	else
		tween(self.Scale, { Scale = 0.92 }, Theme.EaseIn)
		tween(self.Root, { GroupTransparency = 1 }, Theme.Soft)
		task.delay(0.6, function()
			if not self.IsOpen then
				self.Root.Visible = false
			end
		end)
		tween(self.Floating, { Size = UDim2.fromOffset(60, 60), BackgroundTransparency = 0.05 }, Theme.Ease)
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
-- KONTROL: TOGGLE / SLIDER / BUTTON
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
		Size = UDim2.fromOffset(66, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		AutoButtonColor = false,
	}, parent)
	corner(btn, 8)
	gradient(btn, Theme.AccentSoft, Theme.AccentDeep, 90)
	stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.6)

	btn.MouseEnter:Connect(function()
		tween(btn, { Size = UDim2.fromOffset(72, 28) }, Theme.Fast)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { Size = UDim2.fromOffset(66, 26) }, Theme.Fast)
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

--=============================================================
-- TAMBAH FITUR
--   data = {
--     Name = "Nama Fitur",
--     Desc = "Kegunaan / struktur kerja fitur",
--     Type = "toggle" | "slider" | "button",
--     Default, Min, Max,
--     Callback = function(state) end
--   }
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
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
		LayoutOrder = self.RowCount[category],
	}, page)
	corner(row, 12)
	local rs = stroke(row, Color3.fromRGB(255, 255, 255), 1, 0.5)

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
		tween(row, { BackgroundTransparency = 0.52 }, Theme.Fast)
		tween(rs,  { Transparency = 0.5 }, Theme.Fast)
		tween(nameLbl, { TextColor3 = Theme.Text }, Theme.Fast)
	end)

	return row
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

return Hub
