--!strict
-- Roblox Luau UI Hub: ESP, Generator, Movement, Teleport, Warna & Opt
-- Versi v2: Menambahkan kontrol Slider interaktif real-time (ukuran font ESP, kecepatan RGB, WalkSpeed, JumpPower)
-- 100% mempertahankan seluruh kode, logika, struktur, dan fitur sebelumnya tanpa merusak bagian mana pun.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------------
-- 1. CONFIG & STATE MANAGER
---------------------------------------------------------------------------
local DefaultConfig = {
	Theme = {
		PrimaryAccent = Color3.fromRGB(0, 210, 255),
		SecondaryAccent = Color3.fromRGB(168, 85, 247),
		PanelBg = Color3.fromRGB(16, 19, 28),
		SurfaceBg = Color3.fromRGB(26, 31, 45),
		TextPrimary = Color3.fromRGB(248, 250, 252),
		TextMuted = Color3.fromRGB(148, 163, 184),
		OnColor = Color3.fromRGB(34, 197, 94),
		OffColor = Color3.fromRGB(239, 68, 68),
		AllyColor = Color3.fromRGB(59, 130, 246),
		EnemyColor = Color3.fromRGB(244, 63, 94),
		NeutralColor = Color3.fromRGB(250, 204, 21),
	},
	RGB = {
		Enabled = true,
		Speed = 0.35, -- putaran per detik
		Thickness = 2,
	},
	ESP = {
		Enabled = true,
		ShowTeammates = true,
		ShowEnemies = true,
		ShowDistance = true,
		ShowHealth = true,
		NameTextSize = 11, -- diperkecil agar ringkas dan tidak menumpuk
		MaxStuds = 5000,
	},
	Movement = {
		WalkSpeedEnabled = false,
		WalkSpeed = 24,
		JumpPowerEnabled = false,
		JumpPower = 65,
	},
	Generator = {
		AutoHighlight = false,
	},
	Teleport = {
		LastSavedCFrame = nil,
	},
}

local function deepCopy(tbl: any): any
	if type(tbl) ~= "table" then
		return tbl
	end
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function mergeConfig(defaults: any, saved: any): any
	local result = deepCopy(defaults)
	if type(saved) ~= "table" then
		return result
	end
	for k, v in pairs(result) do
		if saved[k] ~= nil then
			if type(v) == "table" and type(saved[k]) == "table" then
				result[k] = mergeConfig(v, saved[k])
			else
				result[k] = saved[k]
			end
		end
	end
	return result
end

local ConfigFileName = "hub_esp_config.json"

local function loadConfig(): typeof(DefaultConfig)
	local okRead, rawData = pcall(function()
		if typeof(isfile) == "function" and typeof(readfile) == "function" then
			if isfile(ConfigFileName) then
				return readfile(ConfigFileName)
			end
		end
		return nil
	end)

	if okRead and type(rawData) == "string" and #rawData > 0 then
		local okDecode, decoded = pcall(function()
			return game:GetService("HttpService"):JSONDecode(rawData)
		end)
		if okDecode and type(decoded) == "table" then
			return mergeConfig(DefaultConfig, decoded)
		end
	end

	return deepCopy(DefaultConfig)
end

local function saveConfig(cfg: any): boolean
	local okEncode, encoded = pcall(function()
		return game:GetService("HttpService"):JSONEncode(cfg)
	end)
	if not okEncode or type(encoded) ~= "string" then
		return false
	end

	local okWrite = pcall(function()
		if typeof(writefile) == "function" then
			writefile(ConfigFileName, encoded)
		end
	end)
	return okWrite
end

local Config = loadConfig()

---------------------------------------------------------------------------
-- 2. LIFECYCLE & CLEANUP MANAGER
---------------------------------------------------------------------------
local Connections: { RBXScriptConnection } = {}
local EspEntries: { [Player]: { Billboard: BillboardGui, NameLabel: TextLabel, MetaLabel: TextLabel, Highlight: Highlight } } = {}
local HubAlive = true
local ScreenGui: ScreenGui

local function trackConn(conn: RBXScriptConnection): RBXScriptConnection
	table.insert(Connections, conn)
	return conn
end

local function clearAllEsp()
	for plr, entry in pairs(EspEntries) do
		pcall(function()
			if entry.Billboard then entry.Billboard:Destroy() end
			if entry.Highlight then entry.Highlight:Destroy() end
		end)
		EspEntries[plr] = nil
	end
end

local function cleanupHub()
	if not HubAlive then return end
	HubAlive = false
	clearAllEsp()
	for _, conn in ipairs(Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(Connections)
	if ScreenGui and ScreenGui.Parent then
		pcall(function()
			ScreenGui:Destroy()
		end)
	end
end

---------------------------------------------------------------------------
-- 3. UI COMPONENT FACTORY & RGB BORDER ENGINE
---------------------------------------------------------------------------
local function getGuiParent(): Instance
	local ok, res = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
		return CoreGui
	end)
	if ok and res then
		return res
	end
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	return playerGui or CoreGui
end

-- Menghapus / menyembunyikan label hint "tahan & geser untuk mengatur ukuran panel" jika ada
local function suppressResizeHint(container: Instance)
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("TextLabel") or desc:IsA("TextButton") then
			local lowerText = string.lower(desc.Text)
			if string.find(lowerText, "tahan", 1, true)
				or string.find(lowerText, "geser", 1, true)
				or string.find(lowerText, "ukuran panel", 1, true)
			then
				desc.Visible = false
				desc.Text = ""
			end
		end
	end
end

local function applyCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function applyStroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local RgbStrokes: { UIStroke } = {}

local function attachRgbBorder(target: Instance, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or Config.RGB.Thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.new(1, 1, 1)

	local grad = Instance.new("UIGradient")
	grad.Name = "RgbGradient"
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 90)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 165, 0)),
		ColorSequenceKeypoint.new(0.40, Color3.fromRGB(40, 255, 130)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 195, 255)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(150, 90, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 90)),
	})
	grad.Parent = stroke
	stroke.Parent = target

	table.insert(RgbStrokes, stroke)
	return stroke
end

-- Membuat ScreenGui utama
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimsaksinProHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = getGuiParent()

-- Floating Toggle Button dengan garis pinggir RGB
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.fromOffset(112, 36)
FloatingToggle.Position = UDim2.new(0.03, 0, 0.18, 0)
FloatingToggle.BackgroundColor3 = Config.Theme.SurfaceBg
FloatingToggle.Text = "● HUB MENU"
FloatingToggle.TextColor3 = Config.Theme.TextPrimary
FloatingToggle.Font = Enum.Font.GothamBold
FloatingToggle.TextSize = 12
FloatingToggle.AutoButtonColor = false
FloatingToggle.Parent = ScreenGui
applyCorner(FloatingToggle, 10)
attachRgbBorder(FloatingToggle, 2)

-- Main Panel dengan garis pinggir RGB
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.fromOffset(470, 300)
MainPanel.Position = UDim2.new(0.5, -235, 0.5, -150)
MainPanel.BackgroundColor3 = Config.Theme.PanelBg
MainPanel.BorderSizePixel = 0
MainPanel.Active = true
MainPanel.Parent = ScreenGui
applyCorner(MainPanel, 12)
attachRgbBorder(MainPanel, 2)

-- Header Bar
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 38)
HeaderBar.BackgroundColor3 = Config.Theme.SurfaceBg
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainPanel
applyCorner(HeaderBar, 12)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Config.Theme.SurfaceBg
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.fromOffset(14, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "CONTROL HUB • ESP & UTILITY"
TitleLabel.TextColor3 = Config.Theme.TextPrimary
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.Parent = HeaderBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.fromOffset(64, 24)
CloseBtn.Position = UDim2.new(1, -74, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 72)
CloseBtn.Text = "HIDE"
CloseBtn.TextColor3 = Config.Theme.TextPrimary
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Parent = HeaderBar
applyCorner(CloseBtn, 6)

-- Tab Bar (kontras tinggi & teks terlihat jelas)
local TabBar = Instance.new("ScrollingFrame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -16, 0, 34)
TabBar.Position = UDim2.fromOffset(8, 44)
TabBar.BackgroundColor3 = Color3.fromRGB(21, 25, 36)
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 2
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.Parent = MainPanel
applyCorner(TabBar, 8)
applyStroke(TabBar, Color3.fromRGB(51, 65, 85), 1, 0.3)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 6)
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabBar

local TabPad = Instance.new("UIPadding")
TabPad.PaddingLeft = UDim.new(0, 6)
TabPad.PaddingRight = UDim.new(0, 6)
TabPad.Parent = TabBar

-- Content Area
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -16, 1, -90)
ContentArea.Position = UDim2.fromOffset(8, 84)
ContentArea.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 4
ContentArea.ScrollBarImageColor3 = Config.Theme.PrimaryAccent
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainPanel
applyCorner(ContentArea, 8)
applyStroke(ContentArea, Color3.fromRGB(45, 55, 72), 1, 0.35)

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentArea

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 8)
ContentPad.PaddingBottom = UDim.new(0, 8)
ContentPad.PaddingLeft = UDim.new(0, 8)
ContentPad.PaddingRight = UDim.new(0, 8)
ContentPad.Parent = ContentArea

-- Drag support untuk Panel Utama & Floating Toggle
local function makeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	trackConn(dragHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position
		end
	end))

	trackConn(UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	trackConn(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

makeDraggable(HeaderBar, MainPanel)
makeDraggable(FloatingToggle, FloatingToggle)

trackConn(CloseBtn.MouseButton1Click:Connect(function()
	MainPanel.Visible = false
end))

trackConn(FloatingToggle.MouseButton1Click:Connect(function()
	MainPanel.Visible = not MainPanel.Visible
end))

-- Sistem Tab & Kontrol Toggle ber-indikator status jelas
local TabPages: { [string]: Frame } = {}
local TabButtons: { [string]: TextButton } = {}
local ActiveTabName: string? = nil

local function selectTab(tabName: string)
	ActiveTabName = tabName
	for name, page in pairs(TabPages) do
		page.Visible = (name == tabName)
	end
	for name, btn in pairs(TabButtons) do
		local isActive = (name == tabName)
		btn.BackgroundColor3 = isActive and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(30, 36, 52)
		btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(203, 213, 225)
	end
end

local function createTab(tabName: string): Frame
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. tabName
	btn.Size = UDim2.fromOffset(88, 24)
	btn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
	btn.Text = tabName
	btn.TextColor3 = Color3.fromRGB(203, 213, 225)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextWrapped = false
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.Parent = TabBar
	applyCorner(btn, 6)

	local page = Instance.new("Frame")
	page.Name = "Page_" .. tabName
	page.Size = UDim2.new(1, 0, 0, 0)
	page.AutomaticSize = Enum.AutomaticSize.Y
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = ContentArea

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Padding = UDim.new(0, 7)
	pageLayout.Parent = page

	TabButtons[tabName] = btn
	TabPages[tabName] = page

	trackConn(btn.MouseButton1Click:Connect(function()
		selectTab(tabName)
	end))

	if ActiveTabName == nil then
		selectTab(tabName)
	end

	return page
end

-- Komponen Toggle dengan tanda visual jelas: Badge teks [ON]/[OFF], dot indikator, dan pill switch
local function createToggleRow(
	parent: Frame,
	titleText: string,
	descText: string,
	initialState: boolean,
	onChanged: (state: boolean) -> ()
)
	local state = initialState

	local row = Instance.new("Frame")
	row.Name = "Toggle_" .. titleText
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Config.Theme.SurfaceBg
	row.BorderSizePixel = 0
	row.Parent = parent
	applyCorner(row, 8)
	applyStroke(row, Color3.fromRGB(51, 65, 85), 1, 0.4)

	-- Garis indikator status di sisi kiri baris
	local statusBar = Instance.new("Frame")
	statusBar.Size = UDim2.new(0, 4, 1, -8)
	statusBar.Position = UDim2.fromOffset(4, 4)
	statusBar.BorderSizePixel = 0
	statusBar.Parent = row
	applyCorner(statusBar, 2)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -155, 0, 18)
	titleLbl.Position = UDim2.fromOffset(14, 5)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = titleText
	titleLbl.TextColor3 = Config.Theme.TextPrimary
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 12
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
	titleLbl.Parent = row

	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, -155, 0, 14)
	descLbl.Position = UDim2.fromOffset(14, 24)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = descText
	descLbl.TextColor3 = Config.Theme.TextMuted
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextSize = 10
	descLbl.TextTruncate = Enum.TextTruncate.AtEnd
	descLbl.Parent = row

	-- Tombol Switch + Tanda Status [● ON] / [○ OFF]
	local switchBtn = Instance.new("TextButton")
	switchBtn.Name = "SwitchBtn"
	switchBtn.Size = UDim2.fromOffset(74, 26)
	switchBtn.Position = UDim2.new(1, -82, 0.5, -13)
	switchBtn.BorderSizePixel = 0
	switchBtn.Font = Enum.Font.GothamBold
	switchBtn.TextSize = 11
	switchBtn.AutoButtonColor = false
	switchBtn.Parent = row
	applyCorner(switchBtn, 6)

	local function refreshVisual()
		if state then
			statusBar.BackgroundColor3 = Config.Theme.OnColor
			switchBtn.BackgroundColor3 = Config.Theme.OnColor
			switchBtn.Text = "● ON"
			switchBtn.TextColor3 = Color3.fromRGB(10, 20, 14)
		else
			statusBar.BackgroundColor3 = Config.Theme.OffColor
			switchBtn.BackgroundColor3 = Color3.fromRGB(51, 58, 74)
			switchBtn.Text = "○ OFF"
			switchBtn.TextColor3 = Color3.fromRGB(248, 113, 113)
		end
	end

	refreshVisual()

	trackConn(switchBtn.MouseButton1Click:Connect(function()
		state = not state
		refreshVisual()
		task.spawn(function()
			pcall(onChanged, state)
		end)
	end))
end

-- Komponen Slider Interaktif Real-Time (mendukung Mouse & Touch)
local function createSliderRow(
	parent: Frame,
	titleText: string,
	minVal: number,
	maxVal: number,
	stepVal: number,
	initialVal: number,
	suffixText: string,
	onChanged: (value: number) -> ()
)
	local currentVal = math.clamp(initialVal, minVal, maxVal)

	local row = Instance.new("Frame")
	row.Name = "Slider_" .. titleText
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = Config.Theme.SurfaceBg
	row.BorderSizePixel = 0
	row.Parent = parent
	applyCorner(row, 8)
	applyStroke(row, Color3.fromRGB(51, 65, 85), 1, 0.4)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -95, 0, 18)
	titleLbl.Position = UDim2.fromOffset(12, 6)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = titleText
	titleLbl.TextColor3 = Config.Theme.TextPrimary
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 12
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
	titleLbl.Parent = row

	local valueBadge = Instance.new("TextLabel")
	valueBadge.Size = UDim2.fromOffset(72, 18)
	valueBadge.Position = UDim2.new(1, -82, 0, 6)
	valueBadge.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	valueBadge.TextColor3 = Config.Theme.PrimaryAccent
	valueBadge.Font = Enum.Font.GothamBold
	valueBadge.TextSize = 11
	valueBadge.Parent = row
	applyCorner(valueBadge, 5)

	local trackBtn = Instance.new("TextButton")
	trackBtn.Name = "SliderTrack"
	trackBtn.Size = UDim2.new(1, -24, 0, 10)
	trackBtn.Position = UDim2.fromOffset(12, 32)
	trackBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	trackBtn.BorderSizePixel = 0
	trackBtn.Text = ""
	trackBtn.AutoButtonColor = false
	trackBtn.Parent = row
	applyCorner(trackBtn, 5)

	local fillBar = Instance.new("Frame")
	fillBar.Name = "FillBar"
	fillBar.Size = UDim2.new(0, 0, 1, 0)
	fillBar.BackgroundColor3 = Config.Theme.PrimaryAccent
	fillBar.BorderSizePixel = 0
	fillBar.Parent = trackBtn
	applyCorner(fillBar, 5)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(14, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = trackBtn
	applyCorner(knob, 7)

	local function formatValue(v: number): string
		if stepVal < 1 then
			return string.format("%.2f%s", v, suffixText)
		end
		return string.format("%d%s", math.floor(v + 0.5), suffixText)
	end

	local function applyVisual(v: number)
		local ratio = 0
		if maxVal > minVal then
			ratio = math.clamp((v - minVal) / (maxVal - minVal), 0, 1)
		end
		fillBar.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueBadge.Text = formatValue(v)
	end

	local function updateFromInputX(inputX: number)
		local absPos = trackBtn.AbsolutePosition.X
		local absSize = trackBtn.AbsoluteSize.X
		if absSize <= 0 then return end
		local alpha = math.clamp((inputX - absPos) / absSize, 0, 1)
		local raw = minVal + (maxVal - minVal) * alpha
		local snapped = math.floor((raw / stepVal) + 0.5) * stepVal
		snapped = math.clamp(snapped, minVal, maxVal)
		if stepVal < 1 then
			snapped = math.floor(snapped * 100 + 0.5) / 100
		end
		if snapped ~= currentVal then
			currentVal = snapped
			applyVisual(currentVal)
			task.spawn(function()
				pcall(onChanged, currentVal)
			end)
		end
	end

	applyVisual(currentVal)

	local sliding = false
	trackConn(trackBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateFromInputX(input.Position.X)
		end
	end))

	trackConn(UserInputService.InputChanged:Connect(function(input: InputObject)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInputX(input.Position.X)
		end
	end))

	trackConn(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end))
end

local function createActionButton(parent: Frame, labelText: string, onClick: () -> ())
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
	btn.Text = "▶  " .. labelText
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = parent
	applyCorner(btn, 7)

	trackConn(btn.MouseButton1Click:Connect(function()
		task.spawn(function()
			pcall(onClick)
		end)
	end))
end

---------------------------------------------------------------------------
-- 4. ESP AVATAR ENGINE (TEMBUS PANDANG, JARAK JAUH, FONT KECIL & JELAS)
---------------------------------------------------------------------------
local function getRelationType(targetPlr: Player): string
	if targetPlr == LocalPlayer then
		return "Self"
	end
	if LocalPlayer.Team ~= nil and targetPlr.Team ~= nil then
		if LocalPlayer.Team == targetPlr.Team then
			return "Team"
		else
			return "Enemy"
		end
	end
	return "FriendOrOther"
end

local function getRelationColor(relation: string): Color3
	if relation == "Team" then
		return Config.Theme.AllyColor
	elseif relation == "Enemy" then
		return Config.Theme.EnemyColor
	end
	return Config.Theme.NeutralColor
end

local function removeEspForPlayer(plr: Player)
	local entry = EspEntries[plr]
	if entry then
		pcall(function()
			if entry.Billboard then entry.Billboard:Destroy() end
			if entry.Highlight then entry.Highlight:Destroy() end
		end)
		EspEntries[plr] = nil
	end
end

local function ensureEspForPlayer(plr: Player)
	if plr == LocalPlayer then return end
	if not Config.ESP.Enabled then
		removeEspForPlayer(plr)
		return
	end

	local relation = getRelationType(plr)
	if relation == "Team" and not Config.ESP.ShowTeammates then
		removeEspForPlayer(plr)
		return
	end
	if relation == "Enemy" and not Config.ESP.ShowEnemies then
		removeEspForPlayer(plr)
		return
	end

	local character = plr.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if not rootPart or not rootPart:IsA("BasePart") then return end

	local color = getRelationColor(relation)
	local existing = EspEntries[plr]

	if existing then
		if existing.Billboard.Adornee ~= rootPart then
			existing.Billboard.Adornee = rootPart
		end
		if existing.Highlight.Adornee ~= character then
			existing.Highlight.Adornee = character
		end
		existing.Billboard.AlwaysOnTop = true
		existing.Billboard.MaxDistance = Config.ESP.MaxStuds
		existing.NameLabel.TextSize = Config.ESP.NameTextSize
		existing.NameLabel.TextColor3 = color
		existing.MetaLabel.TextSize = math.max(8, Config.ESP.NameTextSize - 1)
		existing.Highlight.FillColor = color
		existing.Highlight.OutlineColor = color
		return
	end

	-- BillboardGui menembus dinding (AlwaysOnTop = true) & terlihat dari jauh
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HubAvatarESP_" .. plr.Name
	billboard.Adornee = rootPart
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = Config.ESP.MaxStuds
	billboard.Size = UDim2.fromOffset(120, 28)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.Parent = ScreenGui

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameTag"
	nameLabel.Size = UDim2.new(1, 0, 0, 14)
	nameLabel.Position = UDim2.fromOffset(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = plr.DisplayName
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = Config.ESP.NameTextSize
	nameLabel.Parent = billboard

	local metaLabel = Instance.new("TextLabel")
	metaLabel.Name = "MetaTag"
	metaLabel.Size = UDim2.new(1, 0, 0, 12)
	metaLabel.Position = UDim2.fromOffset(0, 14)
	metaLabel.BackgroundTransparency = 1
	metaLabel.Text = ""
	metaLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
	metaLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	metaLabel.TextStrokeTransparency = 0.2
	metaLabel.Font = Enum.Font.GothamMedium
	metaLabel.TextSize = math.max(8, Config.ESP.NameTextSize - 1)
	metaLabel.Parent = billboard

	-- Highlight transparan agar avatar terlihat menembus dari berbagai sisi
	local highlight = Instance.new("Highlight")
	highlight.Name = "HubAvatarHighlight_" .. plr.Name
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = color
	highlight.FillTransparency = 0.72
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0.15
	highlight.Parent = ScreenGui

	EspEntries[plr] = {
		Billboard = billboard,
		NameLabel = nameLabel,
		MetaLabel = metaLabel,
		Highlight = highlight,
	}
end

local function updateEspLoop()
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			ensureEspForPlayer(plr)
			local entry = EspEntries[plr]
			local char = plr.Character
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if entry and root and root:IsA("BasePart") then
				local parts = {}
				local relation = getRelationType(plr)
				table.insert(parts, string.upper(relation))

				if Config.ESP.ShowDistance and myRoot and myRoot:IsA("BasePart") then
					local dist = math.floor((root.Position - myRoot.Position).Magnitude)
					table.insert(parts, tostring(dist) .. "m")
				end

				if Config.ESP.ShowHealth and hum and hum.MaxHealth > 0 then
					local hpPct = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
					table.insert(parts, tostring(hpPct) .. "%")
				end

				entry.MetaLabel.Text = table.concat(parts, " • ")
				entry.Billboard.Enabled = Config.ESP.Enabled
				entry.Highlight.Enabled = Config.ESP.Enabled
			end
		end
	end
end

---------------------------------------------------------------------------
-- 5. BANGUN TAB & FITUR
---------------------------------------------------------------------------
local espTab = createTab("ESP")
local genTab = createTab("Generator")
local moveTab = createTab("Movement")
local tpTab = createTab("Teleport")
local optTab = createTab("Warna & Opt")

createToggleRow(espTab, "Avatar ESP Master", "Aktifkan penanda nama & outline tembus pandang", Config.ESP.Enabled, function(v)
	Config.ESP.Enabled = v
	if not v then
		clearAllEsp()
	end
end)

createToggleRow(espTab, "ESP Rekan Tim", "Tampilkan penanda avatar satu tim", Config.ESP.ShowTeammates, function(v)
	Config.ESP.ShowTeammates = v
end)

createToggleRow(espTab, "ESP Musuh / Lainnya", "Tampilkan penanda avatar musuh & pemain lain", Config.ESP.ShowEnemies, function(v)
	Config.ESP.ShowEnemies = v
end)

createToggleRow(espTab, "Tampilkan Jarak & HP", "Info jarak stud/meter dan persentase HP di bawah nama", Config.ESP.ShowDistance, function(v)
	Config.ESP.ShowDistance = v
	Config.ESP.ShowHealth = v
end)

createSliderRow(espTab, "Ukuran Font Nama ESP", 8, 18, 1, Config.ESP.NameTextSize, "px", function(val)
	Config.ESP.NameTextSize = val
	for _, entry in pairs(EspEntries) do
		entry.NameLabel.TextSize = val
		entry.MetaLabel.TextSize = math.max(8, val - 1)
	end
end)

createToggleRow(genTab, "Generator Highlight", "Sorot objek Generator di workspace agar mudah terlihat", Config.Generator.AutoHighlight, function(v)
	Config.Generator.AutoHighlight = v
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and string.find(string.lower(obj.Name), "gen", 1, true) then
			local hl = obj:FindFirstChild("HubGenHighlight")
			if v then
				if not hl then
					local newHl = Instance.new("Highlight")
					newHl.Name = "HubGenHighlight"
					newHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					newHl.FillColor = Color3.fromRGB(250, 204, 21)
					newHl.FillTransparency = 0.65
					newHl.OutlineColor = Color3.fromRGB(255, 255, 255)
					newHl.Parent = obj
				end
			elseif hl then
				hl:Destroy()
			end
		end
	end
end)

createToggleRow(moveTab, "Custom WalkSpeed", "Ubah kecepatan jalan karakter secara aman", Config.Movement.WalkSpeedEnabled, function(v)
	Config.Movement.WalkSpeedEnabled = v
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = v and Config.Movement.WalkSpeed or 16
	end
end)

createSliderRow(moveTab, "Nilai WalkSpeed", 16, 120, 1, Config.Movement.WalkSpeed, "", function(val)
	Config.Movement.WalkSpeed = val
	if Config.Movement.WalkSpeedEnabled then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = val
		end
	end
end)

createToggleRow(moveTab, "Custom JumpPower", "Ubah tinggi lompatan karakter secara aman", Config.Movement.JumpPowerEnabled, function(v)
	Config.Movement.JumpPowerEnabled = v
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = v and Config.Movement.JumpPower or 50
	end
end)

createSliderRow(moveTab, "Nilai JumpPower", 50, 200, 1, Config.Movement.JumpPower, "", function(val)
	Config.Movement.JumpPower = val
	if Config.Movement.JumpPowerEnabled then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = val
		end
	end
end)

createActionButton(tpTab, "Simpan Posisi Saat Ini", function()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		Config.Teleport.LastSavedCFrame = {
			root.CFrame.X, root.CFrame.Y, root.CFrame.Z,
		}
		saveConfig(Config)
	end
end)

createActionButton(tpTab, "Teleport ke Posisi Tersimpan", function()
	local saved = Config.Teleport.LastSavedCFrame
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if type(saved) == "table" and #saved >= 3 and root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(saved[1], saved[2], saved[3]) + Vector3.new(0, 2, 0)
	end
end)

createToggleRow(optTab, "Animasi Garis Pinggir RGB", "Garis RGB berjalan di pinggir Panel Utama & Floating Toggle", Config.RGB.Enabled, function(v)
	Config.RGB.Enabled = v
	for _, stroke in ipairs(RgbStrokes) do
		stroke.Enabled = v
	end
end)

createSliderRow(optTab, "Kecepatan Garis RGB", 0.10, 2.00, 0.05, Config.RGB.Speed, "x", function(val)
	Config.RGB.Speed = val
end)

createActionButton(optTab, "Simpan Konfigurasi JSON", function()
	saveConfig(Config)
end)

createActionButton(optTab, "Unload / Bersihkan Hub", function()
	cleanupHub()
end)

-- Bersihkan teks "tahan & geser untuk mengatur ukuran panel" bila ada
suppressResizeHint(ScreenGui)

---------------------------------------------------------------------------
-- 6. LOOP RINGAN & EVENT HANDLERS
---------------------------------------------------------------------------
trackConn(Players.PlayerRemoving:Connect(function(plr: Player)
	removeEspForPlayer(plr)
end))

trackConn(LocalPlayer.CharacterAdded:Connect(function(char: Model)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum and hum:IsA("Humanoid") then
		if Config.Movement.WalkSpeedEnabled then
			hum.WalkSpeed = Config.Movement.WalkSpeed
		end
		if Config.Movement.JumpPowerEnabled then
			hum.UseJumpPower = true
			hum.JumpPower = Config.Movement.JumpPower
		end
	end
end))

local elapsedAccum = 0
local espTimer = 0
local hueOffset = 0

trackConn(RunService.RenderStepped:Connect(function(dt: number)
	if not HubAlive then return end

	-- Animasi garis RGB pada Panel Utama & Floating Toggle
	if Config.RGB.Enabled then
		hueOffset = (hueOffset + dt * Config.RGB.Speed) % 1
		for _, stroke in ipairs(RgbStrokes) do
			local grad = stroke:FindFirstChildOfClass("UIGradient")
			if grad then
				grad.Offset = Vector2.new(hueOffset * 2 - 1, 0)
			end
		end
	end

	-- Update ESP tiap ~0.12 detik agar performa tetap stabil
	espTimer += dt
	if espTimer >= 0.12 then
		espTimer = 0
		pcall(updateEspLoop)
	end

	-- Jaga movement tetap aktif jika diaktifkan
	elapsedAccum += dt
	if elapsedAccum >= 0.5 then
		elapsedAccum = 0
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			if Config.Movement.WalkSpeedEnabled and hum.WalkSpeed ~= Config.Movement.WalkSpeed then
				hum.WalkSpeed = Config.Movement.WalkSpeed
			end
			if Config.Movement.JumpPowerEnabled and hum.JumpPower ~= Config.Movement.JumpPower then
				hum.UseJumpPower = true
				hum.JumpPower = Config.Movement.JumpPower
			end
		end
	end
end))

selectTab("ESP")
