-- =========================================================
-- BIMSAKSIN HUB | GLASSMORPHISM + DRAGGABLE MINI BSS TOGGLE
-- =========================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Bersihkan UI lama agar tidak numpuk saat dieksekusi ulang
if PlayerGui:FindFirstChild("BimSakSinHubGlass") then
    PlayerGui.BimSakSinHubGlass:Destroy()
end
if CoreGui:FindFirstChild("BimSakSinHubGlass") then
    CoreGui.BimSakSinHubGlass:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BimSakSinHubGlass"
ScreenGui.ResetOnSpawn = false

-- Gunakan gethui jika didukung executor, atau PlayerGui agar pasti muncul di HP
if gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = PlayerGui
end
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

---------------------------------------------------------
-- 1. FLOATING TOGGLE "BSS" (Kecil, Transparan, Draggable)
---------------------------------------------------------
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "BssToggle"
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 25, 0.5, -25) -- Posisi awal di pinggir kiri layar
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ToggleBtn.BackgroundTransparency = 0.45 -- Semi-transparan (tidak silau)
ToggleBtn.Text = "BSS"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0) -- Bentuk bulat mulus
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 180)
ToggleStroke.Transparency = 0.3
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = ToggleBtn

-- Fitur Drag (Bisa digeser-geser pakai jari di HP)
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

---------------------------------------------------------
-- 2. PANEL UTAMA (Konsep Glassmorphism / Kaca Transparan Mewah)
---------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 270)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -135) -- Ditengah layar
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.25 -- Efek kaca buram transparan khas Glassmorphism
MainFrame.Visible = false -- Sembunyi secara default, dibuka lewat tombol BSS
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 180)
MainStroke.Transparency = 0.4
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Judul Panel
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 45)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BimSakSin Hub // Glass Edition"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Tombol Close (X) Mewah di Dalam Panel
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0, 9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize, CloseBtn.Font = 12, Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

---------------------------------------------------------
-- 3. CONTOH FITUR DALAM PANEL
---------------------------------------------------------
local SampleToggle = Instance.new("TextButton")
SampleToggle.Size = UDim2.new(1, -30, 0, 42)
SampleToggle.Position = UDim2.new(0, 15, 0, 55)
SampleToggle.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SampleToggle.BackgroundTransparency = 0.4
SampleToggle.TextColor3 = Color3.fromRGB(0, 255, 180)
SampleToggle.Text = "ESP Survivor & Killer: [ OFF ]"
SampleToggle.TextSize, SampleToggle.Font = 13, Enum.Font.GothamMedium
SampleToggle.Parent = MainFrame

local STCorner = Instance.new("UICorner")
STCorner.CornerRadius = UDim.new(0, 8)
STCorner.Parent = SampleToggle

local isOn = false
SampleToggle.MouseButton1Click:Connect(function()
    isOn = not isOn
    if isOn then
        SampleToggle.Text = "ESP Survivor & Killer: [ ACTIVE ]"
        SampleToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        SampleToggle.Text = "ESP Survivor & Killer: [ OFF ]"
        SampleToggle.TextColor3 = Color3.fromRGB(0, 255, 180)
    end
end)

---------------------------------------------------------
-- 4. SISTEM INTERAKSI BUKA / TUTUP PANEL
---------------------------------------------------------
local isOpen = false
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end)

CloseBtn.MouseButton1Click:Connect(function()
    isOpen = false
    MainFrame.Visible = false
end)

print("BimSakSin Hub Glassmorphism Berhasil Dijalankan!")
