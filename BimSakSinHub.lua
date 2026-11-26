--[[
================================================================================
  BimSakSin Hub v3.0 | Universal Luxury Skull 3D HD Edition
  Creator     : BimSakSin
  Environment : Roblox Luau (Universal / All-Map & R6/R15 Compatible)
  Features    :
- Transparent Luxury Skull 3D HD UI + 4 Corner 3D Skulls + 3D Skull Toggle
- Universal Adaptive Player ESP (Team/Enemy/Random, Distance, Health,
      Transparent Avatar Highlight, Custom Font + Adaptive Translucent Backdrop)
- Universal Item ESP (Unlimited Distance, Name + Distance, No Background,
      Custom Font & Color)
- Universal Generator ESP (Name, Distance, Live Process Status, Custom Font & Color)
- Precision Auto Aimbot + Conditional RGB Weapon Laser + Auto Parry
- Melee Immunity + Disaster & Total Hazard Immunity + Hunger & Thirst Guard
- Interactive Replicated Carry System (Visible to Other Players + Carry/Lepas Buttons)
- Integrated Anti-Detect & Stealth Engine (GUI Cloaking, Instance Name Randomizer,
      Metamethod Property Spoofing, Local Anti-Kick, Anti-Cheat Remote Guard,
      Anti-Detect Fly & Anti-Detect Teleport Bypass)
- Interactive Replicated R6 & R15 Dance/Emote Studio (Visible on All Devices)
- Zero-Rubberband Universal Safe Teleport ("Click") & Waypoint Manager
- Smooth Admin-Style Free-Flight & Analog-Safe NoClip Geometry Inspector
- Interactive Anti-Bug / Auto-Recovery Engine (AKTIF / OFF) + Anti-AFK
- Full Menu Font & Color Customizer + Information Tab
================================================================================
]]

-- ============================================================================
-- 0. PRE-EXECUTION CLEANUP (Mencegah duplikasi GUI, loop lama & sisa objek ESP)
-- ============================================================================
do
    if typeof(getgenv) == "function" then
        local env = getgenv()
        if type(env.BSS_UnloadOld) == "function" then
            pcall(env.BSS_UnloadOld)
            env.BSS_UnloadOld = nil
        end
    end

    local existingNames = {
        ["BimSakSinHub_v2"] = true,
        ["BimSakSinHub_v3"] = true,
        ["BSS_ESP_Folder"] = true,
        ["BSS_ItemESP_Folder"] = true,
        ["BSS_GenESP_Folder"] = true,
    }
    if typeof(getgenv) == "function" and type(getgenv().BSS_RuntimeNames) == "table" then
        for dynName, active in pairs(getgenv().BSS_RuntimeNames) do
            if active and type(dynName) == "string" then
                existingNames[dynName] = true
            end
        end
        getgenv().BSS_RuntimeNames = {}
    end
    local function cleanupContainer(container)
        if not container then return end
        pcall(function()
            for _, child in ipairs(container:GetChildren()) do
                if existingNames[child.Name] then
                    child:Destroy()
                end
            end
        end)
    end

    if typeof(gethui) == "function" then
        cleanupContainer(gethui())
    end
    local coreGuiSvc = game:GetService("CoreGui")
    cleanupContainer(coreGuiSvc)
    if coreGuiSvc then
        cleanupContainer(coreGuiSvc:FindFirstChild("RobloxGui"))
    end
    if workspace and workspace.CurrentCamera then
        cleanupContainer(workspace.CurrentCamera)
    end

    local lp = game:GetService("Players").LocalPlayer
    if lp then
        cleanupContainer(lp:FindFirstChild("PlayerGui"))
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, objName in ipairs({
                "BSS_FlyVelocity",
                "BSS_FlyGyro",
                "BSS_FlyLinearVel",
                "BSS_FlyAlignOri",
                "BSS_FlyAttachment",
                "LinearVelocityConstraint",
                "AlignOrientationConstraint",
                "RootRigAttachment_Aux",
                "BSS_CarryVelocity",
                "BSS_CarryWeld",
            }) do
                local old = root:FindFirstChild(objName)
                if old then old:Destroy() end
            end
        end
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
        end
    end

    local oldLaser = workspace:FindFirstChild("BSS_RGB_AimLaser")
    if oldLaser then oldLaser:Destroy() end

    local oldViewAnchor = workspace:FindFirstChild("BSS_RemoteViewAnchor")
    if oldViewAnchor then oldViewAnchor:Destroy() end
end

-- ============================================================================
-- 1. CORE SERVICES & MODULAR STATE TABLES (Aman dari batas 200 register Luau)
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local Teams = game:GetService("Teams")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")

local VirtualUser = nil
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer

local App = {
    Name = "BimSakSin Hub v3.0",
    Subtitle = "Presiden indonesia Prabowo Subianto Djojohadikusumo",
    Version = "v3.0 Skull 3D HD",
    GuiName = "BimSakSinHub_v3",
    IsOpen = true,
    IsMinimized = false,
    ExpandedWidth = 650,
    ExpandedHeight = 435,
    ActiveTab = "Dashboard",
    StartTime = os.clock(),
    DiscordUrl = "https://discord.gg/YwMCBq22f2",
    DonationUrl = "https://linktr.ee/bimsaksin",
}

-- ============================================================================
-- GEO-IP & REAL-TIME INTERACTIVE MULTI-LANGUAGE ENGINE (GeoLangAPI)
-- ============================================================================
local GeoLangAPI = {
    CurrentLang = "id",
    AutoDetectedLang = "id",
    ManualOverride = false,
    IsFetching = false,
    IPAddress = "Detecting...",
    ISP = "-",
    City = "-",
    Region = "-",
    Country = "-",
    CountryCode = "ID",
    DetectionSource = "Scanning",
    StatusText = "Presiden indonesia Prabowo Subianto Djojohadikusumo",
    Listeners = {},
    TextBindings = {},
}

GeoLangAPI.Languages = {
    { Code = "id", Label = "🇮🇩 Indonesia", CountryCodes = { ID = true } },
    { Code = "en", Label = "🇺🇸 English", CountryCodes = { US = true, GB = true, CA = true, AU = true, NZ = true, SG = true, IE = true, IN = true } },
    { Code = "ms", Label = "🇲🇾 Melayu", CountryCodes = { MY = true, BN = true } },
    { Code = "jp", Label = "🇯🇵 日本語 (JP)", CountryCodes = { JP = true } },
    { Code = "kr", Label = "🇰🇷 한국어 (KR)", CountryCodes = { KR = true } },
    { Code = "cn", Label = "🇨🇳 中文 (CN)", CountryCodes = { CN = true, TW = true, HK = true, MO = true } },
    { Code = "es", Label = "🇪🇸 Español", CountryCodes = { ES = true, MX = true, AR = true, CO = true, CL = true, PE = true, VE = true } },
    { Code = "pt", Label = "🇧🇷 Português", CountryCodes = { BR = true, PT = true, AO = true, MZ = true } },
    { Code = "ru", Label = "🇷🇺 Русский", CountryCodes = { RU = true, BY = true, KZ = true, UA = true } },
    { Code = "ar", Label = "🇸🇦 العربية", CountryCodes = { SA = true, AE = true, EG = true, QA = true, KW = true, OM = true, BH = true } },
    { Code = "fr", Label = "🇫🇷 Français", CountryCodes = { FR = true, BE = true, CH = true, LU = true } },
    { Code = "de", Label = "🇩🇪 Deutsch", CountryCodes = { DE = true, AT = true, LI = true } },
    { Code = "th", Label = "🇹🇭 ไทย (TH)", CountryCodes = { TH = true } },
    { Code = "vi", Label = "🇻🇳 Tiếng Việt", CountryCodes = { VN = true } },
    { Code = "tl", Label = "🇵🇭 Filipino", CountryCodes = { PH = true } },
}

GeoLangAPI.Dictionary = {
    id = {
        detecting = "🌐 IP: Mendeteksi alamat IP & lokasi...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "Alamat IP & info lokasi disalin ke clipboard!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUAL",
        tab_Dashboard = "Beranda",
        tab_ESPRadar = "Radar ESP",
        tab_Combat = "Tempur & Bidik",
        tab_Carry = "Gendong Pemain",
        tab_Dances = "Tarian & Emote",
        tab_Movement = "Gerak & Kecepatan",
        tab_Teleport = "Teleportasi",
        tab_Visuals = "Tampilan Dunia",
        tab_Settings = "Pengaturan",
        tab_Informasi = "Informasi",
        lang_section = "Bahasa & Deteksi Wilayah IP Real-Time",
        lang_selector = "Pilih Bahasa Negara (Auto Wilayah IP / Manual)",
        lang_auto_btn = "Sinkronisasi Otomatis Wilayah IP & Bahasa",
        lang_auto_sub = "Baca ulang alamat IP, negara, dan bahasa pemain secara real-time",
        lang_sync_now = "Sinkron IP",
        lang_status_fmt = "IP: %s | Negara: %s (%s) | Bahasa Aktif: %s [%s]",
        lang_changed = "Bahasa diubah ke: ",
        welcome = "Selamat datang! IP & bahasa disesuaikan secara real-time. 💀",
    },
    en = {
        detecting = "🌐 IP: Detecting public IP & location...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "IP address & location info copied to clipboard!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUAL",
        tab_Dashboard = "Dashboard",
        tab_ESPRadar = "ESP Radar",
        tab_Combat = "Combat & Aim",
        tab_Carry = "Carry Player",
        tab_Dances = "Dances & Emote",
        tab_Movement = "Movement & Speed",
        tab_Teleport = "Teleportation",
        tab_Visuals = "World Visuals",
        tab_Settings = "Settings",
        tab_Informasi = "Information",
        lang_section = "Language & Real-Time IP Region Detection",
        lang_selector = "Select Country Language (Auto IP Region / Manual)",
        lang_auto_btn = "Auto-Sync IP Region & Language",
        lang_auto_sub = "Re-detect public IP, country & player language in real-time",
        lang_sync_now = "Sync IP",
        lang_status_fmt = "IP: %s | Country: %s (%s) | Active Language: %s [%s]",
        lang_changed = "Language switched to: ",
        welcome = "Welcome! Player IP & language synced in real-time. 💀",
    },
    ms = {
        detecting = "🌐 IP: Mengesan alamat IP & lokasi...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "Alamat IP & maklumat lokasi disalin!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUAL",
        tab_Dashboard = "Papan Utama",
        tab_ESPRadar = "Radar ESP",
        tab_Combat = "Tempur",
        tab_Carry = "Dukung",
        tab_Dances = "Tarian",
        tab_Movement = "Pergerakan",
        tab_Teleport = "Teleport",
        tab_Visuals = "Visual",
        tab_Settings = "Tetapan",
        tab_Informasi = "Maklumat",
        lang_section = "Bahasa & Pengesanan Wilayah IP Masa Nyata",
        lang_selector = "Pilih Bahasa Negara (Auto Wilayah IP / Manual)",
        lang_auto_btn = "Segerak Auto Wilayah IP & Bahasa",
        lang_auto_sub = "Baca semula IP awam, negara & bahasa pemain secara masa nyata",
        lang_sync_now = "Segerak IP",
        lang_status_fmt = "IP: %s | Negara: %s (%s) | Bahasa Aktif: %s [%s]",
        lang_changed = "Bahasa ditukar kepada: ",
        welcome = "Selamat datang! Lokasi IP & bahasa disegerakkan secara masa nyata. 💀",
    },
    jp = {
        detecting = "🌐 IP: パブリックIPと地域を検出中...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "IPアドレスと地域情報をコピーしました！",
        mode_auto = "自動IP",
        mode_manual = "手動",
        tab_Dashboard = "ダッシュボード",
        tab_ESPRadar = "ESPレーダー",
        tab_Combat = "戦闘・エイム",
        tab_Carry = "キャリー",
        tab_Dances = "ダンス",
        tab_Movement = "移動・速度",
        tab_Teleport = "テレポート",
        tab_Visuals = "ビジュアル",
        tab_Settings = "設定",
        tab_Informasi = "情報",
        lang_section = "言語＆リアルタイムIP地域検出",
        lang_selector = "国の言語を選択（IP自動検出 / 手動）",
        lang_auto_btn = "IP地域と言語を自動同期",
        lang_auto_sub = "パブリックIP・国・言語をリアルタイムで再取得します",
        lang_sync_now = "IP同期",
        lang_status_fmt = "IP: %s | 国: %s (%s) | 現在の言語: %s [%s]",
        lang_changed = "言語を変更しました: ",
        welcome = "ようこそ！IP地域と言語をリアルタイムで同期しました。💀",
    },
    kr = {
        detecting = "🌐 IP: 공인 IP 및 위치 감지 중...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "IP 주소 및 위치 정보가 복사되었습니다!",
        mode_auto = "자동 IP",
        mode_manual = "수동",
        tab_Dashboard = "대시보드",
        tab_ESPRadar = "ESP 레이더",
        tab_Combat = "전투 / 에임",
        tab_Carry = "캐리",
        tab_Dances = "댄스",
        tab_Movement = "이동 / 속도",
        tab_Teleport = "텔레포트",
        tab_Visuals = "비주얼",
        tab_Settings = "설정",
        tab_Informasi = "정보",
        lang_section = "언어 및 실시간 IP 지역 감지",
        lang_selector = "국가 언어 선택 (IP 자동 감지 / 수동)",
        lang_auto_btn = "IP 지역 및 언어 자동 동기화",
        lang_auto_sub = "공인 IP, 국가 및 언어를 실시간으로 다시 감지합니다",
        lang_sync_now = "IP 동기화",
        lang_status_fmt = "IP: %s | 국가: %s (%s) | 현재 언어: %s [%s]",
        lang_changed = "언어가 변경되었습니다: ",
        welcome = "환영합니다! IP 위치와 언어가 실시간으로 동기화되었습니다. 💀",
    },
    cn = {
        detecting = "🌐 IP: 正在检测公网IP与地区...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "已复制IP地址与位置信息！",
        mode_auto = "自动IP",
        mode_manual = "手动",
        tab_Dashboard = "仪表盘",
        tab_ESPRadar = "透视雷达",
        tab_Combat = "战斗自瞄",
        tab_Carry = "背人互动",
        tab_Dances = "舞蹈动作",
        tab_Movement = "移动速度",
        tab_Teleport = "传送系统",
        tab_Visuals = "视觉环境",
        tab_Settings = "系统设置",
        tab_Informasi = "关于信息",
        lang_section = "语言与实时IP地区检测",
        lang_selector = "选择国家语言（IP自动识别 / 手动）",
        lang_auto_btn = "自动同步IP地区与语言",
        lang_auto_sub = "实时重新读取玩家公网IP、国家与语言",
        lang_sync_now = "同步IP",
        lang_status_fmt = "IP: %s | 国家: %s (%s) | 当前语言: %s [%s]",
        lang_changed = "语言已切换为: ",
        welcome = "欢迎使用！已实时同步玩家IP位置与语言。💀",
    },
    es = {
        detecting = "🌐 IP: Detectando IP pública y ubicación...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "¡Dirección IP y ubicación copiadas!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUAL",
        tab_Dashboard = "Panel",
        tab_ESPRadar = "Radar ESP",
        tab_Combat = "Combate",
        tab_Carry = "Cargar",
        tab_Dances = "Bailes",
        tab_Movement = "Movimiento",
        tab_Teleport = "Teletransporte",
        tab_Visuals = "Visuales",
        tab_Settings = "Ajustes",
        tab_Informasi = "Información",
        lang_section = "Idioma y Detección de Región IP en Tiempo Real",
        lang_selector = "Seleccionar Idioma del País (Auto IP / Manual)",
        lang_auto_btn = "Sincronizar Región IP e Idioma",
        lang_auto_sub = "Volver a detectar IP pública, país e idioma en tiempo real",
        lang_sync_now = "Sinc. IP",
        lang_status_fmt = "IP: %s | País: %s (%s) | Idioma Activo: %s [%s]",
        lang_changed = "Idioma cambiado a: ",
        welcome = "¡Bienvenido! Ubicación IP e idioma sincronizados en tiempo real. 💀",
    },
    pt = {
        detecting = "🌐 IP: Detectando IP público e localização...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "Endereço IP e localização copiados!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUAL",
        tab_Dashboard = "Painel",
        tab_ESPRadar = "Radar ESP",
        tab_Combat = "Combate",
        tab_Carry = "Carregar",
        tab_Dances = "Danças",
        tab_Movement = "Movimento",
        tab_Teleport = "Teleporte",
        tab_Visuals = "Visuais",
        tab_Settings = "Configurações",
        tab_Informasi = "Informações",
        lang_section = "Idioma e Detecção de Região IP em Tempo Real",
        lang_selector = "Selecionar Idioma do País (Auto IP / Manual)",
        lang_auto_btn = "Sincronizar Região IP e Idioma",
        lang_auto_sub = "Detectar novamente IP público, país e idioma em tempo real",
        lang_sync_now = "Sinc. IP",
        lang_status_fmt = "IP: %s | País: %s (%s) | Idioma Ativo: %s [%s]",
        lang_changed = "Idioma alterado para: ",
        welcome = "Bem-vindo! Localização IP e idioma sincronizados em tempo real. 💀",
    },
    ru = {
        detecting = "🌐 IP: Определение публичного IP и региона...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "IP-адрес и локация скопированы!",
        mode_auto = "АВТО IP",
        mode_manual = "ВРУЧНУЮ",
        tab_Dashboard = "Панель",
        tab_ESPRadar = "ESP Радар",
        tab_Combat = "Бой / Аим",
        tab_Carry = "Носить",
        tab_Dances = "Танцы",
        tab_Movement = "Движение",
        tab_Teleport = "Телепорт",
        tab_Visuals = "Визуал",
        tab_Settings = "Настройки",
        tab_Informasi = "Инфо",
        lang_section = "Язык и определение региона по IP в реальном времени",
        lang_selector = "Выберите язык страны (Авто IP / Вручную)",
        lang_auto_btn = "Авто-синхронизация региона IP и языка",
        lang_auto_sub = "Повторно определить публичный IP, страну и язык",
        lang_sync_now = "Синхр. IP",
        lang_status_fmt = "IP: %s | Страна: %s (%s) | Язык: %s [%s]",
        lang_changed = "Язык изменен на: ",
        welcome = "Добро пожаловать! IP-локация и язык синхронизированы. 💀",
    },
    ar = {
        detecting = "🌐 IP: جاري كشف عنوان IP والموقع...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "تم نسخ عنوان IP ومعلومات الموقع!",
        mode_auto = "تلقائي IP",
        mode_manual = "يدوي",
        tab_Dashboard = "لوحة التحكم",
        tab_ESPRadar = "رادار ESP",
        tab_Combat = "القتال",
        tab_Carry = "حمل اللاعب",
        tab_Dances = "الرقصات",
        tab_Movement = "الحركة",
        tab_Teleport = "الانتقال",
        tab_Visuals = "المرئيات",
        tab_Settings = "الإعدادات",
        tab_Informasi = "معلومات",
        lang_section = "اللغة واكتشاف منطقة IP في الوقت الفعلي",
        lang_selector = "اختر لغة الدولة (تلقائي حسب IP / يدوي)",
        lang_auto_btn = "مزامنة منطقة IP واللغة تلقائياً",
        lang_auto_sub = "إعادة قراءة عنوان IP والدولة واللغة في الوقت الفعلي",
        lang_sync_now = "مزامنة IP",
        lang_status_fmt = "IP: %s | الدولة: %s (%s) | اللغة النشطة: %s [%s]",
        lang_changed = "تم تغيير اللغة إلى: ",
        welcome = "مرحباً بك! تمت مزامنة موقع IP واللغة في الوقت الفعلي. 💀",
    },
    fr = {
        detecting = "🌐 IP: Détection de l'IP publique et du lieu...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "Adresse IP et localisation copiées !",
        mode_auto = "AUTO IP",
        mode_manual = "MANUEL",
        tab_Dashboard = "Tableau",
        tab_ESPRadar = "Radar ESP",
        tab_Combat = "Combat",
        tab_Carry = "Porter",
        tab_Dances = "Danses",
        tab_Movement = "Mouvement",
        tab_Teleport = "Téléport",
        tab_Visuals = "Visuels",
        tab_Settings = "Paramètres",
        tab_Informasi = "Infos",
        lang_section = "Langue et Détection Régionale IP en Temps Réel",
        lang_selector = "Choisir la Langue du Pays (Auto IP / Manuel)",
        lang_auto_btn = "Synchroniser Auto Région IP & Langue",
        lang_auto_sub = "Relire l'IP publique, le pays et la langue en temps réel",
        lang_sync_now = "Sync IP",
        lang_status_fmt = "IP: %s | Pays: %s (%s) | Langue Active: %s [%s]",
        lang_changed = "Langue changée en : ",
        welcome = "Bienvenue ! Localisation IP et langue synchronisées en temps réel. 💀",
    },
    de = {
        detecting = "🌐 IP: Öffentliche IP & Standort werden erkannt...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "IP-Adresse & Standort kopiert!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUELL",
        tab_Dashboard = "Dashboard",
        tab_ESPRadar = "ESP-Radar",
        tab_Combat = "Kampf",
        tab_Carry = "Tragen",
        tab_Dances = "Tänze",
        tab_Movement = "Bewegung",
        tab_Teleport = "Teleport",
        tab_Visuals = "Visuell",
        tab_Settings = "Einstellungen",
        tab_Informasi = "Info",
        lang_section = "Sprache & Echtzeit-IP-Regionserkennung",
        lang_selector = "Ländersprache wählen (Auto-IP / Manuell)",
        lang_auto_btn = "IP-Region & Sprache synchronisieren",
        lang_auto_sub = "Öffentliche IP, Land und Sprache in Echtzeit neu erkennen",
        lang_sync_now = "IP Sync",
        lang_status_fmt = "IP: %s | Land: %s (%s) | Aktive Sprache: %s [%s]",
        lang_changed = "Sprache geändert zu: ",
        welcome = "Willkommen! IP-Standort & Sprache in Echtzeit synchronisiert. 💀",
    },
    th = {
        detecting = "🌐 IP: กำลังตรวจจับ IP สาธารณะและตำแหน่ง...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "คัดลอกที่อยู่ IP และตำแหน่งแล้ว!",
        mode_auto = "ออโต้ IP",
        mode_manual = "เลือกเอง",
        tab_Dashboard = "แดชบอร์ด",
        tab_ESPRadar = "เรดาร์ ESP",
        tab_Combat = "ต่อสู้ / เล็ง",
        tab_Carry = "อุ้มผู้เล่น",
        tab_Dances = "ท่าเต้น",
        tab_Movement = "การเคลื่อนที่",
        tab_Teleport = "เทเลพอร์ต",
        tab_Visuals = "ภาพและแสง",
        tab_Settings = "ตั้งค่า",
        tab_Informasi = "ข้อมูล",
        lang_section = "ภาษาและการตรวจจับภูมิภาค IP แบบเรียลไทม์",
        lang_selector = "เลือกภาษาประเทศ (ตรวจจับ IP อัตโนมัติ / เลือกเอง)",
        lang_auto_btn = "ซิงค์ภูมิภาค IP และภาษาอัตโนมัติ",
        lang_auto_sub = "อ่านค่า IP สาธารณะ ประเทศ และภาษาแบบเรียลไทม์อีกครั้ง",
        lang_sync_now = "ซิงค์ IP",
        lang_status_fmt = "IP: %s | ประเทศ: %s (%s) | ภาษาที่ใช้งาน: %s [%s]",
        lang_changed = "เปลี่ยนภาษาเป็น: ",
        welcome = "ยินดีต้อนรับ! ซิงค์ตำแหน่ง IP และภาษาแบบเรียลไทม์แล้ว 💀",
    },
    vi = {
        detecting = "🌐 IP: Đang dò địa chỉ IP công khai & vị trí...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "Đã sao chép địa chỉ IP & vị trí!",
        mode_auto = "TỰ ĐỘNG IP",
        mode_manual = "THỦ CÔNG",
        tab_Dashboard = "Bảng chính",
        tab_ESPRadar = "Radar ESP",
        tab_Combat = "Chiến đấu",
        tab_Carry = "Bế / Cõng",
        tab_Dances = "Nhảy múa",
        tab_Movement = "Di chuyển",
        tab_Teleport = "Dịch chuyển",
        tab_Visuals = "Hình ảnh",
        tab_Settings = "Cài đặt",
        tab_Informasi = "Thông tin",
        lang_section = "Ngôn ngữ & Nhận diện Vùng IP Thời gian thực",
        lang_selector = "Chọn Ngôn ngữ Quốc gia (Tự động IP / Thủ công)",
        lang_auto_btn = "Tự động đồng bộ Vùng IP & Ngôn ngữ",
        lang_auto_sub = "Đọc lại IP công khai, quốc gia và ngôn ngữ theo thời gian thực",
        lang_sync_now = "Đồng bộ IP",
        lang_status_fmt = "IP: %s | Quốc gia: %s (%s) | Ngôn ngữ: %s [%s]",
        lang_changed = "Đã đổi ngôn ngữ sang: ",
        welcome = "Chào mừng! Đã đồng bộ vị trí IP và ngôn ngữ theo thời gian thực. 💀",
    },
    tl = {
        detecting = "🌐 IP: Tinutukoy ang pampublikong IP at lokasyon...",
        ip_fmt = "🌐 IP: %s | %s, %s (%s) • %s",
        ip_copied = "Nakopya ang IP address at lokasyon!",
        mode_auto = "AUTO IP",
        mode_manual = "MANUAL",
        tab_Dashboard = "Dashboard",
        tab_ESPRadar = "ESP Radar",
        tab_Combat = "Labanan",
        tab_Carry = "Buhat",
        tab_Dances = "Sayaw",
        tab_Movement = "Galaw",
        tab_Teleport = "Teleport",
        tab_Visuals = "Biswal",
        tab_Settings = "Settings",
        tab_Informasi = "Impormasyon",
        lang_section = "Wika at Real-Time na Pagbasa ng IP Region",
        lang_selector = "Pumili ng Wika ng Bansa (Auto IP Region / Manual)",
        lang_auto_btn = "Auto-Sync ng IP Region at Wika",
        lang_auto_sub = "Basahin muli ang pampublikong IP, bansa at wika nang real-time",
        lang_sync_now = "Sync IP",
        lang_status_fmt = "IP: %s | Bansa: %s (%s) | Aktibong Wika: %s [%s]",
        lang_changed = "Pinalitan ang wika sa: ",
        welcome = "Maligayang pagdating! Na-sync ang lokasyon ng IP at wika nang real-time. 💀",
    },
}

-- ============================================================================
-- KAMUS LOKALISASI TERSTRUKTUR SEMUA FITUR (15 BAHASA NEGARA)
-- ============================================================================
GeoLangAPI.FeatureDictionary = {
    en = {
        -- Section Headers
        ["Telemetri Klien Langsung"] = "Live Client Telemetry",
        ["Utilitas Server & Sesi"] = "Server & Session Utilities",
        ["ESP Pemain & Transparansi Avatar"] = "Player ESP & Avatar Highlight",
        ["Kustomisasi Warna & Font ESP Pemain"] = "Player ESP Color & Font Customizer",
        ["ESP Barang-Barang (Jarak Tak Terbatas & Tanpa Latar)"] = "Item ESP (Unlimited Distance & No Backdrop)",
        ["ESP Generator (Status Proses Real-Time)"] = "Generator ESP (Real-Time Process Status)",
        ["Auto Aimbot Presisi Tinggi"] = "High-Precision Auto Aimbot",
        ["Auto Parry & Pertahanan Karakter"] = "Auto Parry & Character Defense",
        ["Kontrol Carry Interaktif (Replikasi Server)"] = "Interactive Carry Controls (Server Replicated)",
        ["Pilih Teman / Player untuk Di-Carry"] = "Select Friend / Player to Carry",
        ["Studio Dance & Emote (Replikasi R6 & R15)"] = "Dance & Emote Studio (R6 & R15 Replicated)",
        ["Daftar Dance Replikasi (R6 & R15)"] = "Replicated Dance List (R6 & R15)",
        ["Kecepatan Lari & Lompat Tanpa Batas (Unlimited Speed API)"] = "Unlimited Walk & Jump Speed (Speed API)",
        ["Mode Terbang Bebas & Penembus Dinding"] = "Free-Flight & Wall NoClip Mode",
        ["Telemetri Dunia & Teleport Bebas Tanpa Batas Jarak"] = "World Telemetry & Unlimited Teleport",
        ["View & Teleport Pemain Lintas Dunia (Tanpa Batas Jarak)"] = "Cross-World Player View & Teleport (Unlimited)",
        ["Kontrol Kamera & Pencahayaan"] = "Camera & Lighting Controls",
        ["Sistem Anti-Bug / Error & Anti-AFK"] = "Anti-Bug / Error & Anti-AFK System",
        ["Kustomisasi Font & Warna Panel Menu"] = "Menu Font & Theme Customizer",
        ["Kontrol Pintasan & Pembersihan Panel"] = "Shortcut Controls & Panel Unload",
        ["Informasi Pembuat & Dukungan"] = "Creator & Support Information",
        ["Tautan Resmi Komunitas & Donasi"] = "Official Community & Donation Links",

        -- Toggles
        ["Radar Pemain: Tembus Tembok"] = "Player Radar: Wallhack ESP",
        ["Tampilkan ESP pemain jarak jauh menembus tembok di seluruh map"] = "Show long-range player ESP through walls across the entire map",
        ["Visual Pemain: Sorot Siluet Avatar"] = "Player Visual: Avatar Silhouette Highlight",
        ["Sorot bentuk tubuh avatar pemain secara transparan dari kejauhan"] = "Highlight player character silhouettes transparently from afar",
        ["Info Pemain: Penanda Jarak (Meter)"] = "Player Info: Distance Indicator (Meters)",
        ["Tampilkan informasi jarak real-time ke setiap pemain"] = "Display real-time distance to every player",
        ["Info Pemain: Penanda Nyawa (HP)"] = "Player Info: Health Bar / HP Indicator",
        ["Otomatis menampilkan sisa nyawa jika map memakai sistem darah"] = "Automatically display player HP if the map uses a health system",
        ["Radar Barang: Deteksi Loot & Item"] = "Item Radar: Loot & Tool Detector",
        ["Deteksi lokasi barang, loot, atau tool tanpa batas jarak & tanpa latar"] = "Detect items, loot, or tools at unlimited range with no backdrop",
        ["Radar Generator: Status Mesin"] = "Generator Radar: Machine Status",
        ["Tampilkan posisi mesin generator, jarak, & status proses pemain lain"] = "Show generator position, distance & live repair progress status",
        ["Bidikan Otomatis: Auto Aimbot"] = "Auto Aim: Precision Aimbot",
        ["Kunci bidikan kamera ke sasaran secara akurat untuk senjata & melee"] = "Lock camera aim onto targets accurately for guns & melee",
        ["Visual Senjata: Laser Bidik RGB"] = "Weapon Visual: RGB Aim Laser",
        ["Tampilkan garis laser RGB otomatis hanya saat memegang senjata api"] = "Display RGB laser line automatically only when holding ranged weapons",
        ["Pertahanan Bidik: Abaikan Rekan Tim"] = "Aim Filter: Team Check Protection",
        ["Mencegah aimbot membidik teman satu tim pada map berbasis tim"] = "Prevent aimbot from locking onto teammates on team-based maps",
        ["Visual Bidik: Lingkaran Area FOV"] = "Aim Visual: FOV Detection Circle",
        ["Tampilkan lingkaran batas area jangkauan deteksi aimbot di layar"] = "Display aimbot detection range circle on screen",
        ["Tangkis Otomatis: Auto Parry"] = "Auto Defense: Auto Parry",
        ["Otomatis menangkis saat lawan atau pemain lain menyerang di dekat Anda"] = "Automatically parry when enemies or players attack near you",
        ["Pertahanan Tubuh: Kebal Pukulan Melee"] = "Body Defense: Melee & Knockback Immunity",
        ["Anti-terpental, anti-ragdoll, dan kebal terhadap hitbox serangan melee"] = "Anti-knockback, anti-ragdoll, and immune to enemy melee hitboxes",
        ["Pertahanan Total: Kebal Bencana & Segala Bahaya (Anti-Mati)"] = "Total Defense: Disaster & All-Hazard Immunity (Anti-Death)",
        ["Kebal total dari bencana alam, meteor, banjir, gempa, api, ledakan, petir, jatuh/void, racun, & apapun tanpa mati/dead"] = "Complete immunity to natural disasters, meteors, floods, quakes, fire, explosions, lightning, fall/void, hazards & anything without dying",
        ["Penjaga Bertahan Hidup: Tahan Lapar & Haus"] = "Survival Guard: Infinite Hunger & Thirst",
        ["Menjaga indikator lapar (Hunger) dan haus (Thirst) tetap penuh otomatis"] = "Keep hunger and thirst indicators automatically full at all times",
        ["Gerak Udara: Terbang Bebas (Admin Fly)"] = "Air Movement: Free-Flight (Admin Fly)",
        ["Terbang bebas dan mulus ke segala arah kamera di PC maupun Mobile"] = "Fly smoothly in any camera direction on both PC and Mobile",
        ["Gerak Fisika: Tembus Dinding (NoClip)"] = "Physics Movement: Wall NoClip",
        ["tidak disarankan untuk fitur NoClip ingin menembus tetapi analog di tarik berlebihan, jika ingin menembus tarik analog secara perlahan-lahan"] = "not recommended to pull the analog stick excessively when phasing through walls; pull the analog slowly to pass through cleanly",
        ["Gerak Lompat: Lompat Udara Tanpa Batas"] = "Jump Movement: Infinite Air Jump",
        ["Melompat berkali-kali di udara tanpa perlu menyentuh permukaan tanah"] = "Jump repeatedly in mid-air without touching the ground",
        ["Cahaya Dunia: Penerangan Maksimal (Fullbright)"] = "World Lighting: Fullbright Mode",
        ["Hilangkan bayangan gelap dan terangkan seluruh sudut map secara instan"] = "Remove dark shadows and brighten every corner of the map instantly",
        ["Cuaca Dunia: Penghapus Kabut (No Fog)"] = "World Weather: Fog Remover (No Fog)",
        ["Hapus kabut jarak pandang (FogEnd & Atmosphere) agar terlihat jernih"] = "Remove view-distance fog (FogEnd & Atmosphere) for crystal clarity",
        ["Proteksi Sistem: Anti-Bug & Pemulihan Otomatis"] = "System Protection: Anti-Bug & Auto-Repair",
        ["Mencegah error pada setiap fitur dan memulihkannya otomatis saat terganggu"] = "Prevent errors across all features and auto-repair if disrupted",
        ["Proteksi Koneksi: Anti-Kick Diam (Anti-AFK)"] = "Connection Protection: Anti-AFK Kick Guard",
        ["Mencegah terputus dari server otomatis saat karakter diam lebih dari 20 menit"] = "Prevent automatic server disconnect when idle for over 20 minutes",
        ["Master Anti-Detect & Stealth Mode"] = "Master Anti-Detect & Stealth Mode",
        ["Aktifkan perlindungan anti-deteksi terpadu (GUI Cloak, Spoof & Anti-Kick)"] = "Enable unified anti-detection protection (GUI Cloak, Spoof & Anti-Kick)",
        ["GUI Cloaking & Acak Nama Objek (Hidden UI)"] = "GUI Cloaking & Object Name Randomizer (Hidden UI)",
        ["Sembunyikan UI ke container tersembunyi & acak nama instance agar lolos scan"] = "Hide UI inside stealth container & randomize instance names against scans",
        ["Spoofing Properti Karakter (Speed / Jump / Gravity)"] = "Character Property Spoofing (Speed / Jump / Gravity)",
        ["Samarkan WalkSpeed, JumpPower, Gravity & FOV agar terbaca normal oleh game"] = "Mask WalkSpeed, JumpPower, Gravity & FOV to appear default to local scripts",
        ["Anti-Kick Lokal & Blokir Remote Laporan Anti-Cheat"] = "Local Anti-Kick & Anti-Cheat Report Remote Blocker",
        ["Tahan panggilan LocalPlayer:Kick() lokal & blokir remote pelaporan mencurigakan"] = "Intercept local LocalPlayer:Kick() calls & block suspicious anti-cheat remotes",
        ["Physics & Camera Instance Stealth"] = "Physics & Camera Instance Stealth",
        ["Sembunyikan objek Fly, Laser & Anchor ke CurrentCamera dengan nama bawaan"] = "Hide Fly, Laser & Anchor objects inside CurrentCamera with native names",
        ["Anti-Detect Fly (CFrame Stealth & State Spoof)"] = "Anti-Detect Fly (CFrame Stealth & State Spoof)",
        ["Terbang tanpa objek BodyMover/Constraint serta menyamarkan status & kecepatan karakter"] = "Fly without BodyMover/Constraint instances while spoofing character state & velocity",
        ["Anti-Detect Teleport (Bypass Rubberband & Pos Spoof)"] = "Anti-Detect Teleport (Bypass Rubberband & Pos Spoof)",
        ["Teleport bertahap anti-rubberband dengan penyamaran kecepatan & pelindung tarik-balik server"] = "Stepped anti-rubberband teleport with velocity spoofing & server setback protection",

        -- Buttons & Chip Selectors
        ["Salin ID Server (Place & Job ID)"] = "Copy Server ID (Place & Job ID)",
        ["Reset Karakter (Respawn Instan)"] = "Reset Character (Instant Respawn)",
        ["Segarkan kembali status karakter lokal Anda"] = "Refresh your local character state instantly",
        ["Hubungkan Ulang Server (Rejoin)"] = "Reconnect to Server (Rejoin)",
        ["Masuk kembali ke dalam server PlaceId yang sama"] = "Rejoin the exact same server instance",
        ["Filter Target ESP (Teman / Musuh / Semua)"] = "ESP Target Filter (Ally / Enemy / All)",
        ["Jarak Maksimal Radar Pemain (Studs)"] = "Max Player Radar Range (Studs)",
        ["Gaya Font Label ESP Pemain"] = "Player ESP Label Font Style",
        ["Warna Utama Sorotan ESP Pemain"] = "Player ESP Primary Highlight Color",
        ["Warna Teks Penanda Jarak"] = "Distance Indicator Text Color",
        ["Warna Teks Penanda Darah (HP)"] = "Health (HP) Indicator Text Color",
        ["Warna Latar Belakang Label Pemain"] = "Player Label Backdrop Color",
        ["Warna Font Nama Pemain (Auto / Custom)"] = "Player Name Font Color (Auto / Custom)",
        ["Gaya Font Label ESP Barang"] = "Item ESP Label Font Style",
        ["Warna Teks ESP Barang-Barang"] = "Item ESP Text Color",
        ["Gaya Font Label ESP Generator"] = "Generator ESP Label Font Style",
        ["Warna Sorotan & Teks ESP Generator"] = "Generator ESP Highlight & Text Color",
        ["Mode Pemicu Kunci Aimbot"] = "Aimbot Lock Trigger Mode",
        ["Target Bagian Tubuh Sasaran"] = "Target Body Part Lock",
        ["Radius Lingkaran Bidik (FOV)"] = "Aimbot FOV Circle Radius",
        ["Kehalusan Kunci Kamera (1 = Instan)"] = "Camera Lock Smoothness (1 = Instant)",
        ["Jarak Deteksi Tangkisan Auto Parry (Studs)"] = "Auto Parry Detection Range (Studs)",
        ["Pilih Gaya Posisi Gendong (Carry)"] = "Select Carry Position Style",
        ["Kecepatan Gerakan Tarian (Dance Speed)"] = "Dance Animation Speed",
        ["Hentikan Tarian & Reset Pose"] = "Stop Dance & Reset Pose",
        ["Hentikan animasi tarian yang sedang dimainkan karakter"] = "Stop the currently playing character dance animation",
        ["Kecepatan Lari / Jalan (WalkSpeed Unlimited)"] = "Walk / Run Speed (Unlimited WalkSpeed)",
        ["Daya Lompat Tinggi (JumpPower Unlimited)"] = "High Jump Power (Unlimited JumpPower)",
        ["Gravitasi Dunia (Workspace Gravity)"] = "World Gravity (Workspace Gravity)",
        ["Reset Kecepatan & Fisika ke Bawaan"] = "Reset Speed & Physics to Default",
        ["Kecepatan Terbang Bebas (FlySpeed Unlimited)"] = "Free-Flight Speed (Unlimited FlySpeed)",
        ["Sudut Pandang Kamera (Field of View)"] = "Camera Field of View (FOV)",
        ["Atur Waktu Siang / Malam Klien (Jam)"] = "Client Time of Day (Hours)",
        ["Pulihkan Pengaturan Visual & Kamera"] = "Restore Visual & Camera Settings",
        ["Pulihkan FOV (70), sakelar, dan pencahayaan asli map"] = "Restore FOV (70), toggles, and original map lighting",
        ["Gaya Font Seluruh Panel Menu"] = "Menu Panel Font Style",
        ["Warna Aksen Utama Panel Menu"] = "Menu Panel Primary Accent Color",
        ["Warna Teks Panel Menu"] = "Menu Panel Text Color",
        ["Latar Belakang Teks Menu (Adaptif)"] = "Menu Text Backdrop (Adaptive)",
        ["Sembunyikan Panel Menu (RightShift)"] = "Hide Menu Panel (RightShift)",
        ["Atau ketuk ikon tengkorak 3D di layar kapan saja"] = "Or tap the 3D skull icon on screen anytime",
        ["Matikan & Hapus Script (Unload Hub)"] = "Disable & Unload Script (Unload Hub)",
        ["Putus semua loop, pulihkan karakter/map, dan tutup GUI"] = "Disconnect all loops, restore character/map & close GUI",
        ["Tautan Donasi & Dukungan Developer"] = "Developer Donation & Support Link",
        ["Tautan Komunitas Discord Resmi"] = "Official Discord Community Link",
    },
}

function GeoLangAPI.TranslateFeatureText(idText)
    if type(idText) ~= "string" or idText == "" then return idText end
    local lang = GeoLangAPI.CurrentLang or "id"
    if lang == "id" then
        return idText
    end
    local pack = GeoLangAPI.FeatureDictionary[lang] or GeoLangAPI.FeatureDictionary.en
    if pack and pack[idText] then
        return pack[idText]
    end
    local enPack = GeoLangAPI.FeatureDictionary.en
    if enPack and enPack[idText] then
        return enPack[idText]
    end
    return idText
end

function GeoLangAPI.T(key)
    local pack = GeoLangAPI.Dictionary[GeoLangAPI.CurrentLang] or GeoLangAPI.Dictionary.en
    return pack[key] or GeoLangAPI.Dictionary.en[key] or key
end

function GeoLangAPI.GetLanguageLabel(code)
    for _, entry in ipairs(GeoLangAPI.Languages) do
        if entry.Code == code then
            return entry.Label
        end
    end
    return string.upper(tostring(code or "EN"))
end

function GeoLangAPI.BindText(instance, dictKey, prefix, suffix)
    if not instance then return end
    table.insert(GeoLangAPI.TextBindings, {
        Instance = instance,
        Key = dictKey,
        Prefix = prefix or "",
        Suffix = suffix or "",
    })
    instance.Text = (prefix or "") .. GeoLangAPI.T(dictKey) .. (suffix or "")
end

function GeoLangAPI.BindFeatureText(instance, idBaseText, prefix, suffix)
    if not instance or type(idBaseText) ~= "string" then return end
    local pfx = prefix or ""
    local sfx = suffix or ""
    local function apply()
        if instance and instance.Parent then
            instance.Text = pfx .. GeoLangAPI.TranslateFeatureText(idBaseText) .. sfx
        end
    end
    apply()
    GeoLangAPI.OnLanguageChanged(apply)
end

function GeoLangAPI.HttpGetRaw(url)
    local reqHeaders = {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) RobloxClient/1.0",
        ["Accept"] = "application/json, text/plain, */*",
    }
    local reqCandidates = {}
    if typeof(request) == "function" then table.insert(reqCandidates, request) end
    if typeof(http_request) == "function" then table.insert(reqCandidates, http_request) end
    if syn and type(syn) == "table" and typeof(syn.request) == "function" then table.insert(reqCandidates, syn.request) end
    if http and type(http) == "table" and typeof(http.request) == "function" then table.insert(reqCandidates, http.request) end
    if fluxus and type(fluxus) == "table" and typeof(fluxus.request) == "function" then table.insert(reqCandidates, fluxus.request) end

    for _, reqFn in ipairs(reqCandidates) do
        local ok, res = pcall(reqFn, {
            Url = url,
            Method = "GET",
            Headers = reqHeaders,
        })
        if ok and type(res) == "table" then
            local body = res.Body or res.body
            if type(body) == "string" and body ~= "" then
                return body
            end
        end
    end

    local okGame, body = pcall(function()
        return game:HttpGet(url, true)
    end)
    if okGame and type(body) == "string" and body ~= "" then
        return body
    end

    local okHttp, httpBody = pcall(function()
        return HttpService:GetAsync(url, true)
    end)
    if okHttp and type(httpBody) == "string" and httpBody ~= "" then
        return httpBody
    end

    return nil
end

function GeoLangAPI.ExtractValidIP(rawStr)
    if type(rawStr) ~= "string" then return nil end
    local trimmed = string.match(rawStr, "^%s*(.-)%s*$") or ""
    local a, b, c, d = string.match(trimmed, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
    if a and b and c and d then
        local na, nb, nc, nd = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
        if na and nb and nc and nd and na <= 255 and nb <= 255 and nc <= 255 and nd <= 255 then
            return string.format("%d.%d.%d.%d", na, nb, nc, nd)
        end
    end
    local ipv6 = string.match(trimmed, "([%x:]+:[%x:]+:[%x:]+)")
    if ipv6 and #ipv6 >= 6 and string.find(ipv6, ":", 1, true) then
        return ipv6
    end
    return nil
end

function GeoLangAPI.MapCountryToLang(countryCode)
    local cc = string.upper(tostring(countryCode or ""))
    for _, langEntry in ipairs(GeoLangAPI.Languages) do
        if langEntry.CountryCodes and langEntry.CountryCodes[cc] then
            return langEntry.Code
        end
    end
    return "en"
end

function GeoLangAPI.OnLanguageChanged(cb)
    table.insert(GeoLangAPI.Listeners, cb)
end

function GeoLangAPI.RefreshBannerText()
    GeoLangAPI.StatusText = App.Subtitle
    if UI.SubLabel and UI.SubLabel.Parent then
        UI.SubLabel.Text = App.Subtitle
    end
    if UI.LangStatusLabel and UI.LangStatusLabel.Parent then
        local modeText = GeoLangAPI.ManualOverride and GeoLangAPI.T("mode_manual") or GeoLangAPI.T("mode_auto")
        UI.LangStatusLabel.Text = "  " .. string.format(
            GeoLangAPI.T("lang_status_fmt"),
            GeoLangAPI.IPAddress,
            GeoLangAPI.Country,
            GeoLangAPI.CountryCode,
            GeoLangAPI.GetLanguageLabel(GeoLangAPI.CurrentLang),
            modeText
        )
    end
end

function GeoLangAPI.SetLanguage(langCode, isManual)
    if not GeoLangAPI.Dictionary[langCode] then
        langCode = "en"
    end
    GeoLangAPI.CurrentLang = langCode
    if isManual ~= nil then
        GeoLangAPI.ManualOverride = isManual
    end
    GeoLangAPI.RefreshBannerText()

    for i = #GeoLangAPI.TextBindings, 1, -1 do
        local item = GeoLangAPI.TextBindings[i]
        if item.Instance and item.Instance.Parent then
            item.Instance.Text = item.Prefix .. GeoLangAPI.T(item.Key) .. item.Suffix
        else
            table.remove(GeoLangAPI.TextBindings, i)
        end
    end

    for i = #GeoLangAPI.Listeners, 1, -1 do
        local cb = GeoLangAPI.Listeners[i]
        local ok = pcall(cb, langCode)
        if not ok then
            table.remove(GeoLangAPI.Listeners, i)
        end
    end
end

function GeoLangAPI.DetectRobloxLocaleFallback()
    local localeStr = "id-id"
    pcall(function()
        localeStr = string.lower(LocalizationService.RobloxLocaleId or LocalizationService.SystemLocaleId or "id-id")
    end)
    local ccGuess = string.upper(string.match(localeStr, "%-(%a%a)$") or "")
    if ccGuess == "" then
        local langPrefix = string.match(localeStr, "^(%a%a)") or "id"
        local prefixMap = {
            id = "ID", en = "US", ms = "MY", ja = "JP", ko = "KR",
            zh = "CN", es = "ES", pt = "BR", ru = "RU", ar = "SA",
            fr = "FR", de = "DE", th = "TH", vi = "VN", tl = "PH",
        }
        ccGuess = prefixMap[langPrefix] or "ID"
    end
    return ccGuess
end

function GeoLangAPI.FetchRealTimeGeoIP(forceAutoLang)
    if GeoLangAPI.IsFetching then return end
    GeoLangAPI.IsFetching = true

    task.spawn(function()
        local okExec = xpcall(function()
            GeoLangAPI.IPAddress = "Detecting..."
            GeoLangAPI.RefreshBannerText()

            local geoEndpoints = {
                "https://ipwho.is/",
                "http://ip-api.com/json/?fields=status,country,countryCode,regionName,city,isp,query",
                "https://ipapi.co/json/",
                "https://freeipapi.com/api/json",
                "https://ipinfo.io/json",
            }

            local parsedData = nil
            for _, url in ipairs(geoEndpoints) do
                local raw = GeoLangAPI.HttpGetRaw(url)
                if raw then
                    local okJson, decoded = pcall(function()
                        return HttpService:JSONDecode(raw)
                    end)
                    if okJson and type(decoded) == "table" then
                        if decoded.success == false or decoded.status == "fail" then
                            -- Lanjut ke endpoint berikutnya jika limit/gagal
                        else
                            local rawIp = decoded.query or decoded.ip or decoded.ipAddress
                            local validIp = GeoLangAPI.ExtractValidIP(tostring(rawIp or ""))
                            local cc = decoded.countryCode or decoded.country_code
                            local country = decoded.country or decoded.country_name or decoded.countryName
                            local region = decoded.regionName or decoded.region or decoded.region_name
                            local city = decoded.city or decoded.cityName
                            local isp = decoded.isp or decoded.org or (type(decoded.connection) == "table" and decoded.connection.isp)

                            if validIp then
                                parsedData = {
                                    IP = validIp,
                                    CountryCode = string.upper(tostring(cc or "")),
                                    Country = tostring(country or ""),
                                    Region = tostring(region or "-"),
                                    City = tostring(city or "-"),
                                    ISP = tostring(isp or "-"),
                                    Source = url,
                                }
                                break
                            end
                        end
                    end
                end
            end

            if not parsedData then
                local plainIpEndpoints = {
                    "https://api.ipify.org",
                    "https://icanhazip.com",
                    "https://checkip.amazonaws.com",
                    "https://ifconfig.me/ip",
                }
                for _, ipUrl in ipairs(plainIpEndpoints) do
                    local rawIpText = GeoLangAPI.HttpGetRaw(ipUrl)
                    local validIp = GeoLangAPI.ExtractValidIP(rawIpText)
                    if validIp then
                        local ccFallback = GeoLangAPI.DetectRobloxLocaleFallback()
                        parsedData = {
                            IP = validIp,
                            CountryCode = ccFallback,
                            Country = ccFallback,
                            Region = "Public Net",
                            City = "Client",
                            ISP = "Public IP",
                            Source = ipUrl,
                        }
                        break
                    end
                end
            end

            if parsedData then
                if parsedData.CountryCode == "" then
                    parsedData.CountryCode = GeoLangAPI.DetectRobloxLocaleFallback()
                end
                if parsedData.Country == "" then
                    parsedData.Country = parsedData.CountryCode
                end
                GeoLangAPI.IPAddress = parsedData.IP
                GeoLangAPI.CountryCode = parsedData.CountryCode
                GeoLangAPI.Country = parsedData.Country
                GeoLangAPI.Region = parsedData.Region
                GeoLangAPI.City = parsedData.City
                GeoLangAPI.ISP = parsedData.ISP
                GeoLangAPI.DetectionSource = "Live API"
            else
                local ccGuess = GeoLangAPI.DetectRobloxLocaleFallback()
                GeoLangAPI.IPAddress = "Local Client (" .. ccGuess .. ")"
                GeoLangAPI.CountryCode = ccGuess
                GeoLangAPI.Country = ccGuess
                GeoLangAPI.Region = "Roblox Locale"
                GeoLangAPI.City = "Client"
                GeoLangAPI.ISP = "Roblox"
                GeoLangAPI.DetectionSource = "Locale"
            end

            local detectedLang = GeoLangAPI.MapCountryToLang(GeoLangAPI.CountryCode)
            GeoLangAPI.AutoDetectedLang = detectedLang

            if forceAutoLang or not GeoLangAPI.ManualOverride then
                GeoLangAPI.SetLanguage(detectedLang, false)
            else
                GeoLangAPI.RefreshBannerText()
            end
        end, function(err)
            Protection.ErrorsCaught = Protection.ErrorsCaught + 1
        end)
        if not okExec then
            GeoLangAPI.RefreshBannerText()
        end
        GeoLangAPI.IsFetching = false
    end)
end

local Theme = {
    -- Palet Luxury Skull 3D HD Mewah & Transparan
    BgPrimary = Color3.fromRGB(13, 11, 19),
    BgSecondary = Color3.fromRGB(20, 16, 30),
    BgCard = Color3.fromRGB(28, 22, 41),
    BgControl = Color3.fromRGB(40, 31, 58),
    Border = Color3.fromRGB(255, 132, 36),
    BorderSubtle = Color3.fromRGB(78, 56, 108),

    TextPrimary = Color3.fromRGB(255, 246, 235),
    TextSecondary = Color3.fromRGB(204, 186, 172),
    TextMuted = Color3.fromRGB(142, 124, 150),

    FontFamily = Enum.Font.GothamSemibold,
    FontBold = Enum.Font.GothamBold,
    FontColorMode = "Auto", -- "Auto" atau Color3 spesifik
    FontBgEnabled = false,
    FontBgColor = Color3.fromRGB(18, 14, 26),
    FontBgTransparency = 0.65,

    Accent = Color3.fromRGB(255, 118, 26),     -- Pumpkin Gold
    AccentDark = Color3.fromRGB(184, 72, 12),
    Crimson = Color3.fromRGB(214, 48, 74),
    Spectral = Color3.fromRGB(155, 89, 245),
    Success = Color3.fromRGB(46, 213, 115),
    Warning = Color3.fromRGB(255, 177, 43),
    Danger = Color3.fromRGB(235, 69, 95),
}

local initialAtmo = Lighting:FindFirstChildOfClass("Atmosphere")

local State = {
    -- Movement & Physics
    WalkSpeed = 16,
    JumpPower = 50,
    OriginalGravity = workspace.Gravity,
    Gravity = workspace.Gravity,
    FlyEnabled = false,
    FlySpeed = 65,
    NoclipEnabled = false,
    InfiniteJumpEnabled = false,

    -- Visuals & Remote Spectate
    CameraFOV = 70,
    FullbrightEnabled = false,
    NoFogEnabled = false,
    SpectatingPlayer = nil,
    SpectateStreamTick = 0,
    SpectateAnchorPart = nil,
    Waypoints = {},

    -- Teleport Concurrency Guard & Distance Telemetry
    TeleportToken = 0,
    IsTeleportLocking = false,
    PreTeleportAnchored = false,
    LastTeleportDistance = 0,
    CustomTeleportDistance = 500,

    -- UI Registries
    AccentObjects = {},
    AccentCallbacks = {},
    ActiveToggleTracks = {},
    ThemedTexts = {},

    -- Original World Cache
    OriginalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    },
    OriginalAtmosphere = initialAtmo and {
        Instance = initialAtmo,
        Density = initialAtmo.Density,
    } or nil,
}

local Physics = {
    FlyAttachment = nil,
    FlyLV = nil,
    FlyAO = nil,
    FlyBV = nil,
    FlyBG = nil,
    FlyCurrentVel = Vector3.zero,
    NoclipCache = {},
}

local ESP = {
    Enabled = false,
    ShowAvatar = true,
    ShowDistance = true,
    ShowHealth = true,
    Mode = "Auto", -- "Auto" | "Enemy" | "Ally" | "Random"
    MaxDistance = 2500,

    -- Warna & Font ESP Pemain
    HighlightColor = Color3.fromRGB(255, 118, 26),
    AllyColor = Color3.fromRGB(46, 213, 115),
    EnemyColor = Color3.fromRGB(235, 69, 95),
    DistanceColor = Color3.fromRGB(255, 210, 120),
    HealthColor = Color3.fromRGB(85, 239, 148),
    Font = Enum.Font.GothamBold,
    FontColor = Color3.fromRGB(255, 248, 240),
    FontAutoContrast = true,
    FontBgColor = Color3.fromRGB(16, 12, 24),
    FontBgTransparency = 0.56,

    Folder = nil,
    Entries = {},
    RandomColorMap = {},
}

local ItemESP = {
    Enabled = false,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(102, 242, 255),
    Folder = nil,
    Entries = {},
    Candidates = {},
}

local GeneratorESP = {
    Enabled = false,
    Font = Enum.Font.GothamBold,
    Color = Color3.fromRGB(255, 196, 54),
    Folder = nil,
    Entries = {},
    Candidates = {},
}

local Combat = {
    AimbotEnabled = false,
    AimbotMode = "Auto", -- "Auto" | "Always" | "HoldRMB"
    AimPart = "Head", -- "Head" | "HumanoidRootPart" | "Closest"
    TeamCheck = true,
    FOVRadius = 220,
    ShowFOVCircle = false,
    Smoothness = 0.35,
    MaxRange = 800,
    RGBLaserEnabled = true,
    CurrentTarget = nil,
    LaserPart = nil,
    FOVCircle = nil,

    -- Kebal Pukulan, Bencana Alam & Survival
    MeleeImmunity = false,
    DisasterImmunity = false,
    HungerThirstGuard = false,
    TouchedPartsCache = {},
    EnemyToolParts = {},
    HazardPartsCache = {},
    LastSafePosition = nil,
    LastSafeCFrame = nil,
    LastHazardAlertTime = 0,
    LastHazardType = "",

    -- Auto Parry
    AutoParryEnabled = false,
    ParryRange = 16,
    LastParryTime = 0,
    ParryCooldown = 0.4,
}

local Carry = {
    Enabled = false,
    TargetPlayer = nil,
    Style = "Depan", -- "Depan" | "Belakang" | "Pundak" | "Seret" | "Kepala" | "Melayang"
    AnimTrack = nil,
    NativePromptTriggered = false,
}

local Emotes = {
    Playing = false,
    CurrentDance = nil,
    CurrentId = nil,
    Speed = 1.0,
    ActiveTrack = nil,
}

local Protection = {
    AntiAFKEnabled = true,
    AntiBugEnabled = true,
    ErrorsCaught = 0,
    AutoRepairs = 0,
    IdleEventsHandled = 0,
    HungerThirstValues = {},
}

local AntiDetect = {
    Enabled = true,
    GuiCloakEnabled = true,
    PropertySpoofEnabled = true,
    AntiKickHookEnabled = true,
    RemoteSanitizerEnabled = true,
    PhysicsStealthEnabled = true,
    FlyStealthEnabled = true,
    TeleportStealthEnabled = true,
    SpoofedReads = 0,
    BlockedKicks = 0,
    BlockedReports = 0,
    CloakedInstances = 0,
    HooksInstalled = false,
    HookSupportLabel = "Standar (Cloak + Stealth)",
    InstanceNames = {},
}

local Connections = {}
local UI = {
    Tabs = {},
    Pages = {},
    TelemetryLabels = {},
    FullbrightToggle = nil,
    NoFogToggle = nil,
    StatusLabel = nil,
    Skulls = {},
    ActiveToast = nil,
    ActiveToastToken = 0,
}

local Utils = {}
local Components = {}
local SafeEngine = {}

-- ============================================================================
-- 2. ANTI-BUG & AUTO-RECOVERY ENGINE (SafeEngine)
-- ============================================================================
function SafeEngine.Run(contextName, fn, ...)
    if not Protection.AntiBugEnabled then
        return fn(...)
    end
    local ok, res = xpcall(fn, function(err)
        return tostring(err)
    end, ...)
    if not ok then
        Protection.ErrorsCaught = Protection.ErrorsCaught + 1
        SafeEngine.AutoRepair(contextName, res)
    end
    return ok, res
end

function SafeEngine.AutoRepair(contextName, errMsg)
    Protection.AutoRepairs = Protection.AutoRepairs + 1

    pcall(function()
        local _, hum, root = Utils.GetCharacter()
        if hum and not State.FlyEnabled and not Carry.Enabled then
            if hum.PlatformStand then
                hum.PlatformStand = false
            end
            if not hum.AutoRotate then
                hum.AutoRotate = true
            end
        end
        if root and not State.FlyEnabled then
            for _, name in ipairs({
                "BSS_FlyLinearVel", "BSS_FlyAlignOri", "BSS_FlyVelocity", "BSS_FlyGyro",
                "LinearVelocityConstraint", "AlignOrientationConstraint", "RootRigAttachment_Aux"
            }) do
                local inst = root:FindFirstChild(name)
                if inst then inst:Destroy() end
            end
        end
        if not Combat.AimbotEnabled and Combat.LaserPart then
            Combat.LaserPart.Transparency = 1
        end
        if UI.StatusLabel and UI.StatusLabel.Parent then
            UI.StatusLabel.Text = string.format("Anti-Bug Aktif (%d Fix)", Protection.AutoRepairs)
        end
    end)
end

-- ============================================================================
-- 2B. INTEGRATED ANTI-DETECT & STEALTH ENGINE (AntiDetect)
-- ============================================================================
do
    local namePrefixes = {
        "RobloxGui_Cache_",
        "CoreOverlay_",
        "ViewportLayer_",
        "StudioWidget_",
        "InputController_",
        "CameraRig_",
        "RenderNode_",
    }

    function AntiDetect.RegisterRuntimeName(name)
        if type(name) ~= "string" or name == "" then return end
        if typeof(getgenv) == "function" then
            local env = getgenv()
            if type(env.BSS_RuntimeNames) ~= "table" then
                env.BSS_RuntimeNames = {}
            end
            env.BSS_RuntimeNames[name] = true
        end
    end

    function AntiDetect.GenerateCrypticName(key)
        if key and AntiDetect.InstanceNames[key] then
            return AntiDetect.InstanceNames[key]
        end
        local prefix = namePrefixes[(math.abs((key and #key or 0) + math.floor(os.clock() * 1000)) % #namePrefixes) + 1]
        local hex = ""
        local okGuid, guid = pcall(function()
            return HttpService:GenerateGUID(false)
        end)
        if okGuid and type(guid) == "string" then
            hex = string.sub(string.gsub(guid, "-", ""), 1, 10)
        else
            hex = string.format("%06x%04x", math.random(0, 0xFFFFFF), math.random(0, 0xFFFF))
        end
        local fullName = prefix .. hex
        if key then
            AntiDetect.InstanceNames[key] = fullName
        end
        AntiDetect.RegisterRuntimeName(fullName)
        return fullName
    end

    function AntiDetect.GetStealthName(key, fallbackName)
        if AntiDetect.Enabled and AntiDetect.GuiCloakEnabled then
            return AntiDetect.GenerateCrypticName(key)
        end
        return fallbackName
    end

    function AntiDetect.GetFlyInstanceNames()
        if AntiDetect.Enabled and AntiDetect.PhysicsStealthEnabled then
            return {
                Attachment = "RootRigAttachment_Aux",
                LinearVelocity = "LinearVelocityConstraint",
                AlignOrientation = "AlignOrientationConstraint",
            }
        end
        return {
            Attachment = "BSS_FlyAttachment",
            LinearVelocity = "BSS_FlyLinearVel",
            AlignOrientation = "BSS_FlyAlignOri",
        }
    end

    function AntiDetect.GetStealthGuiParent()
        if AntiDetect.Enabled and AntiDetect.GuiCloakEnabled then
            if typeof(gethui) == "function" then
                local ok, hiddenGui = pcall(gethui)
                if ok and typeof(hiddenGui) == "Instance" then
                    return hiddenGui
                end
            end
            local okCore, coreGui = pcall(function()
                return game:GetService("CoreGui")
            end)
            if okCore and coreGui then
                local robloxGui = coreGui:FindFirstChild("RobloxGui")
                if robloxGui then
                    return robloxGui
                end
                return coreGui
            end
        end
        local okCore, coreGui = pcall(function()
            return game:GetService("CoreGui")
        end)
        if okCore and coreGui then
            return coreGui
        end
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    function AntiDetect.GetWorldHelperParent()
        if AntiDetect.Enabled and AntiDetect.PhysicsStealthEnabled and workspace.CurrentCamera then
            return workspace.CurrentCamera
        end
        return workspace
    end

    function AntiDetect.ProtectInstance(inst, key, fallbackName)
        if not inst then return end
        pcall(function()
            inst.Archivable = false
            inst.Name = AntiDetect.GetStealthName(key, fallbackName)
            if AntiDetect.Enabled and AntiDetect.GuiCloakEnabled then
                if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" and inst:IsA("GuiBase") then
                    pcall(syn.protect_gui, inst)
                elseif typeof(protect_gui) == "function" and inst:IsA("GuiBase") then
                    pcall(protect_gui, inst)
                end
            end
        end)
    end

    function AntiDetect.RefreshCloak(regenerateNames)
        if regenerateNames then
            table.clear(AntiDetect.InstanceNames)
        end
        local cloakedCount = 0

        if UI.ScreenGui and UI.ScreenGui.Parent then
            local targetParent = AntiDetect.GetStealthGuiParent()
            pcall(function()
                if UI.ScreenGui.Parent ~= targetParent then
                    UI.ScreenGui.Parent = targetParent
                end
            end)
            AntiDetect.ProtectInstance(UI.ScreenGui, "MainScreenGui", App.GuiName)
            cloakedCount = cloakedCount + 1
        end

        if ESP.Folder and ESP.Folder.Parent then
            AntiDetect.ProtectInstance(ESP.Folder, "PlayerESPFolder", "BSS_ESP_Folder")
            cloakedCount = cloakedCount + 1
        end
        if ItemESP.Folder and ItemESP.Folder.Parent then
            AntiDetect.ProtectInstance(ItemESP.Folder, "ItemESPFolder", "BSS_ItemESP_Folder")
            cloakedCount = cloakedCount + 1
        end
        if GeneratorESP.Folder and GeneratorESP.Folder.Parent then
            AntiDetect.ProtectInstance(GeneratorESP.Folder, "GenESPFolder", "BSS_GenESP_Folder")
            cloakedCount = cloakedCount + 1
        end
        if Combat.FOVCircle and Combat.FOVCircle.Parent then
            AntiDetect.ProtectInstance(Combat.FOVCircle, "AimFOVCircle", "BSS_AimFOV")
            cloakedCount = cloakedCount + 1
        end
        if Combat.LaserPart and Combat.LaserPart.Parent then
            pcall(function()
                Combat.LaserPart.Parent = AntiDetect.GetWorldHelperParent()
            end)
            AntiDetect.ProtectInstance(Combat.LaserPart, "AimLaserPart", "BSS_RGB_AimLaser")
            cloakedCount = cloakedCount + 1
        end
        if State.SpectateAnchorPart and State.SpectateAnchorPart.Parent then
            pcall(function()
                State.SpectateAnchorPart.Parent = AntiDetect.GetWorldHelperParent()
            end)
            AntiDetect.ProtectInstance(State.SpectateAnchorPart, "RemoteViewAnchor", "BSS_RemoteViewAnchor")
            cloakedCount = cloakedCount + 1
        end

        AntiDetect.CloakedInstances = (AntiDetect.Enabled and AntiDetect.GuiCloakEnabled) and cloakedCount or 0
        AntiDetect.UpdateStatusBanner()
    end

    function AntiDetect.UpdateStatusBanner()
        if not UI.AntiDetectStatusLabel or not UI.AntiDetectStatusLabel.Parent then
            return
        end
        if not AntiDetect.Enabled then
            UI.AntiDetectStatusLabel.Text = "  Status Anti-Detect: NONAKTIF (Mode Terbuka)"
            return
        end
        local layers = {}
        if AntiDetect.GuiCloakEnabled then table.insert(layers, "GUI Cloak (" .. tostring(AntiDetect.CloakedInstances) .. ")") end
        if AntiDetect.PropertySpoofEnabled then table.insert(layers, "Spoof (" .. tostring(AntiDetect.SpoofedReads) .. ")") end
        if AntiDetect.AntiKickHookEnabled or AntiDetect.RemoteSanitizerEnabled then
            table.insert(layers, string.format("Guard (%d Kick / %d Report)", AntiDetect.BlockedKicks, AntiDetect.BlockedReports))
        end
        if AntiDetect.PhysicsStealthEnabled then table.insert(layers, "CamStealth") end
        if AntiDetect.FlyStealthEnabled then table.insert(layers, "FlyStealth") end
        if AntiDetect.TeleportStealthEnabled then table.insert(layers, "TPStealth") end
        local activeStr = (#layers > 0) and table.concat(layers, " • ") or "Standby"
        UI.AntiDetectStatusLabel.Text = "  Anti-Detect AKTIF [" .. AntiDetect.HookSupportLabel .. "] • " .. activeStr
    end

    function AntiDetect.InstallHooks()
        if AntiDetect.HooksInstalled then
            return
        end

        local canMetamethod = (typeof(hookmetamethod) == "function")
            and (typeof(getnamecallmethod) == "function")
            and (typeof(newcclosure) == "function")
            and (typeof(checkcaller) == "function")

        local suspiciousRemoteKeywords = {
            "anticheat", "anti_cheat", "cheatdetect", "exploitdetect",
            "banplayer", "banreport", "reportexploit", "flagcheat",
            "tamperdetect", "speedhack", "flyhack", "noclipdetect",
            "securityviolation", "kickexploit", "tphack", "teleporthack",
            "poscheck", "positioncheck", "speedcheck", "flycheck",
            "aircheck", "movementcheck", "rubberband"
        }

        local hiddenFlyChildNames = {
            ["LinearVelocity"] = true,
            ["AlignOrientation"] = true,
            ["BodyVelocity"] = true,
            ["BodyGyro"] = true,
            ["VectorForce"] = true,
            ["BSS_FlyLinearVel"] = true,
            ["BSS_FlyAlignOri"] = true,
            ["BSS_FlyAttachment"] = true,
            ["LinearVelocityConstraint"] = true,
            ["AlignOrientationConstraint"] = true,
            ["RootRigAttachment_Aux"] = true,
        }

        if canMetamethod then
            local okIndex = pcall(function()
                local oldIndex
                oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
                    if AntiDetect.Enabled and not checkcaller() and typeof(self) == "Instance" then
                        local char = LocalPlayer.Character
                        if self:IsA("Humanoid") and char and self:IsDescendantOf(char) then
                            if AntiDetect.PropertySpoofEnabled then
                                if key == "WalkSpeed" and State.WalkSpeed ~= 16 then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return 16
                                elseif key == "JumpPower" and State.JumpPower ~= 50 then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return 50
                                elseif key == "JumpHeight" and State.JumpPower ~= 50 then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return 7.2
                                elseif key == "PlatformStand" and State.FlyEnabled then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return false
                                end
                            end
                            if AntiDetect.FlyStealthEnabled and State.FlyEnabled then
                                if key == "PlatformStand" then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return false
                                elseif key == "FloorMaterial" then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return Enum.Material.Plastic
                                end
                            end
                        elseif self:IsA("BasePart") and char and self:IsDescendantOf(char) then
                            if (AntiDetect.FlyStealthEnabled and State.FlyEnabled)
                                or (AntiDetect.TeleportStealthEnabled and State.IsTeleportLocking) then
                                if key == "AssemblyLinearVelocity" or key == "Velocity" then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return Vector3.zero
                                end
                            end
                        elseif AntiDetect.PropertySpoofEnabled and self == workspace and key == "Gravity" and workspace.Gravity ~= State.OriginalGravity then
                            AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                            return State.OriginalGravity
                        elseif AntiDetect.PropertySpoofEnabled and self == workspace.CurrentCamera and key == "FieldOfView" and workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView ~= 70 then
                            AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                            return 70
                        end
                    end
                    return oldIndex(self, key)
                end))
            end)

            local okNamecall = pcall(function()
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                    if AntiDetect.Enabled and not checkcaller() and typeof(self) == "Instance" then
                        local method = getnamecallmethod()
                        if (method == "Kick" or method == "kick") and self == LocalPlayer and AntiDetect.AntiKickHookEnabled then
                            AntiDetect.BlockedKicks = AntiDetect.BlockedKicks + 1
                            return nil
                        end
                        if (method == "FireServer" or method == "InvokeServer") and AntiDetect.RemoteSanitizerEnabled then
                            local rName = string.lower(self.Name)
                            for _, kw in ipairs(suspiciousRemoteKeywords) do
                                if string.find(rName, kw, 1, true) then
                                    AntiDetect.BlockedReports = AntiDetect.BlockedReports + 1
                                    return nil
                                end
                            end
                        end
                        if AntiDetect.FlyStealthEnabled and State.FlyEnabled then
                            local char = LocalPlayer.Character
                            if char and self:IsDescendantOf(char) then
                                if method == "GetState" and self:IsA("Humanoid") then
                                    AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                    return Enum.HumanoidStateType.Running
                                elseif (method == "FindFirstChild" or method == "FindFirstChildWhichIsA" or method == "FindFirstChildOfClass") then
                                    local targetArg = select(1, ...)
                                    if type(targetArg) == "string" and hiddenFlyChildNames[targetArg] then
                                        AntiDetect.SpoofedReads = AntiDetect.SpoofedReads + 1
                                        return nil
                                    end
                                end
                            end
                        end
                    end
                    return oldNamecall(self, ...)
                end))
            end)

            if okIndex and okNamecall then
                AntiDetect.HookSupportLabel = "Full Hook + Cloak"
            elseif okIndex or okNamecall then
                AntiDetect.HookSupportLabel = "Partial Hook + Cloak"
            end
        end

        if typeof(hookfunction) == "function" and typeof(checkcaller) == "function" and typeof(newcclosure) == "function" then
            pcall(function()
                local oldKick
                oldKick = hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
                    if AntiDetect.Enabled and AntiDetect.AntiKickHookEnabled and not checkcaller() and self == LocalPlayer then
                        AntiDetect.BlockedKicks = AntiDetect.BlockedKicks + 1
                        return nil
                    end
                    return oldKick(self, ...)
                end))
            end)
        end

        AntiDetect.HooksInstalled = true
    end

    function AntiDetect.StepFlyStealth(dt)
        local _, hum, root = Utils.GetCharacter()
        local cam = workspace.CurrentCamera
        if not State.FlyEnabled or not hum or not root or not cam then
            return false
        end

        -- Hapus seluruh BodyMover/Constraint agar tidak terdeteksi scanner child pada HumanoidRootPart
        if Physics.FlyLV or Physics.FlyAO or Physics.FlyAttachment or Physics.FlyBV or Physics.FlyBG then
            for _, inst in ipairs({ Physics.FlyLV, Physics.FlyAO, Physics.FlyAttachment, Physics.FlyBV, Physics.FlyBG }) do
                if inst then
                    pcall(function() inst:Destroy() end)
                end
            end
            Physics.FlyLV = nil
            Physics.FlyAO = nil
            Physics.FlyAttachment = nil
            Physics.FlyBV = nil
            Physics.FlyBG = nil
        end

        if hum.Sit then
            hum.Sit = false
        end

        -- Jaga PlatformStand tetap false & state Running agar server/klien tidak mendeteksi status terbang
        if hum.PlatformStand then
            hum.PlatformStand = false
        end
        hum.AutoRotate = false
        local curState = hum:GetState()
        if curState == Enum.HumanoidStateType.Freefall or curState == Enum.HumanoidStateType.Physics then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        local forward = 0
        local right = 0
        local up = 0

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward = forward + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward = forward - 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then right = right + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then right = right - 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            up = up - 1
        end

        if forward == 0 and right == 0 and hum.MoveDirection.Magnitude > 0.05 then
            local camCF = cam.CFrame
            local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
            local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
            if flatLook.Magnitude > 0.001 then
                forward = hum.MoveDirection:Dot(flatLook.Unit)
            else
                local flatUp = Vector3.new(camCF.UpVector.X, 0, camCF.UpVector.Z)
                if flatUp.Magnitude > 0.001 then
                    forward = hum.MoveDirection:Dot(flatUp.Unit) * (camCF.LookVector.Y < 0 and 1 or -1)
                end
            end
            if flatRight.Magnitude > 0.001 then
                right = hum.MoveDirection:Dot(flatRight.Unit)
            end
        end

        local desiredDir = (cam.CFrame.LookVector * forward) + (cam.CFrame.RightVector * right) + Vector3.new(0, up, 0)
        local targetVel = Vector3.zero
        if desiredDir.Magnitude > 0.01 then
            targetVel = desiredDir.Unit * State.FlySpeed
        end

        local safeDt = math.clamp(dt or 0.016, 0.001, 0.1)
        local alpha = math.clamp(safeDt * 14, 0.15, 1)
        Physics.FlyCurrentVel = Physics.FlyCurrentVel:Lerp(targetVel, alpha)
        if Physics.FlyCurrentVel.Magnitude < 0.05 and targetVel == Vector3.zero then
            Physics.FlyCurrentVel = Vector3.zero
        end

        local nextPos = root.Position + (Physics.FlyCurrentVel * safeDt)
        local lookDir = cam.CFrame.LookVector
        if lookDir.Magnitude < 0.001 then
            lookDir = root.CFrame.LookVector
        end

        root.CFrame = CFrame.lookAt(nextPos, nextPos + lookDir)
        root.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
        root.AssemblyAngularVelocity = Vector3.zero
        return true
    end

    function AntiDetect.ExecuteStealthTeleport(targetCFrame, targetPlayer)
        local char, hum, root = Utils.GetCharacter(LocalPlayer)
        if not char or not root then
            return false, 0
        end

        local startPos = root.Position
        local destCF = targetCFrame
        if targetPlayer then
            local liveInfo = TeleportAPI.ResolvePlayerState(targetPlayer)
            if liveInfo then
                destCF = liveInfo.CFrame * CFrame.new(0, 0.5, 3)
            end
        end

        local destPos = destCF.Position
        local travelDistance = (destPos - startPos).Magnitude
        State.LastTeleportDistance = travelDistance

        State.TeleportToken = State.TeleportToken + 1
        local myToken = State.TeleportToken

        if hum then
            hum.Sit = false
            if hum.SeatPart then
                local weld = hum.SeatPart:FindFirstChild("SeatWeld")
                if weld then weld:Destroy() end
            end
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        TeleportAPI.RequestStreamAt(destPos, 6)

        if not State.IsTeleportLocking then
            State.PreTeleportAnchored = root.Anchored
            State.IsTeleportLocking = true
        end

        local savedCollide = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                savedCollide[part] = part.CanCollide
                part.CanCollide = false
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end

        local function restorePartCollisions()
            for part, orig in pairs(savedCollide) do
                if part and part.Parent and part:IsA("BasePart") then
                    part.CanCollide = orig
                end
            end
            table.clear(savedCollide)
        end

        task.spawn(function()
            -- Tahap 1: Micro-stepped transit agar melewati batas jarak per-frame anti-teleport
            if travelDistance > 1 and travelDistance <= 3500 then
                local stepCount = math.clamp(math.ceil(travelDistance / 110), 2, 14)
                local rotOnly = destCF - destCF.Position
                for s = 1, stepCount do
                    RunService.Heartbeat:Wait()
                    if State.TeleportToken ~= myToken or not char or not char.Parent or not root or not root.Parent then
                        restorePartCollisions()
                        return
                    end
                    if targetPlayer and targetPlayer.Parent then
                        local updatedInfo = TeleportAPI.ResolvePlayerState(targetPlayer)
                        if updatedInfo then
                            destCF = updatedInfo.CFrame * CFrame.new(0, 0.5, 3)
                            destPos = destCF.Position
                            rotOnly = destCF - destCF.Position
                        end
                    end
                    local frac = s / stepCount
                    local interpPos = startPos:Lerp(destPos, frac)
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                    char:PivotTo(CFrame.new(interpPos) * rotOnly)
                end
            end

            if not char or not char.Parent or not root or not root.Parent then
                restorePartCollisions()
                return
            end

            -- Tahap 2: Stabilisasi posisi & stream area tujuan
            root.Anchored = true
            char:PivotTo(destCF)
            Combat.LastSafePosition = destPos
            Combat.LastSafeCFrame = destCF

            local holdSteps = (travelDistance > 2500 or targetPlayer ~= nil) and 18 or 10
            for step = 1, holdSteps do
                RunService.Heartbeat:Wait()
                if State.TeleportToken ~= myToken or not char or not char.Parent or not root or not root.Parent then
                    restorePartCollisions()
                    return
                end
                if targetPlayer and targetPlayer.Parent then
                    local updatedInfo = TeleportAPI.ResolvePlayerState(targetPlayer)
                    if updatedInfo then
                        destCF = updatedInfo.CFrame * CFrame.new(0, 0.5, 3)
                        destPos = destCF.Position
                    end
                end
                if step == 3 or step == 8 or step == 14 then
                    TeleportAPI.RequestStreamAt(destPos, 4)
                end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                char:PivotTo(destCF)
            end

            restorePartCollisions()
            if root and root.Parent then
                root.Anchored = State.PreTeleportAnchored
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                Combat.LastSafePosition = root.Position
                Combat.LastSafeCFrame = root.CFrame
            end
            if hum and hum.Parent then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
            State.IsTeleportLocking = false

            -- Tahap 3: Penjaga anti-rubberband pasca-teleport (menolak tarik-balik dari server)
            for _ = 1, 18 do
                RunService.Heartbeat:Wait()
                if State.TeleportToken ~= myToken or not char or not char.Parent or not root or not root.Parent then
                    return
                end
                if (root.Position - destPos).Magnitude > 45 and not targetPlayer then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    char:PivotTo(destCF)
                    Combat.LastSafePosition = destPos
                    Combat.LastSafeCFrame = destCF
                end
            end
        end)

        return true, travelDistance
    end

    function AntiDetect.RestoreAll()
        AntiDetect.Enabled = false
        AntiDetect.GuiCloakEnabled = false
        AntiDetect.PropertySpoofEnabled = false
        AntiDetect.AntiKickHookEnabled = false
        AntiDetect.RemoteSanitizerEnabled = false
        AntiDetect.PhysicsStealthEnabled = false
        AntiDetect.FlyStealthEnabled = false
        AntiDetect.TeleportStealthEnabled = false
    end
end

-- ============================================================================
-- 3. UTILITY FUNCTIONS, SAFE TELEPORT & THEME ENGINE
-- ============================================================================
function Utils.Track(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

function Utils.Tween(obj, info, props)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

function Utils.Create(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

function Utils.AddCorner(parent, radius)
    return Utils.Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

function Utils.AddStroke(parent, color, thickness, transparency)
    return Utils.Create("UIStroke", {
        Color = color or Theme.BorderSubtle,
        Thickness = thickness or 1,
        Transparency = transparency or 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

function Utils.GetLuminance(c)
    return (0.299 * c.R) + (0.587 * c.G) + (0.114 * c.B)
end

function Utils.GetContrastTextColor(bgColor)
    if Utils.GetLuminance(bgColor) > 0.56 then
        return Color3.fromRGB(18, 14, 24)
    end
    return Color3.fromRGB(255, 248, 240)
end

function Utils.RegisterAccent(obj, property)
    table.insert(State.AccentObjects, { Object = obj, Property = property })
    obj[property] = Theme.Accent
end

function Utils.RegisterText(label, isBold, defaultColor)
    table.insert(State.ThemedTexts, {
        Label = label,
        IsBold = isBold == true,
        DefaultColor = defaultColor or Theme.TextPrimary,
        OrigBgTransparency = label.BackgroundTransparency,
        OrigBgColor = label.BackgroundColor3,
    })
    label.Font = isBold and Theme.FontBold or Theme.FontFamily
    if Theme.FontColorMode ~= "Auto" then
        label.TextColor3 = Theme.FontColorMode
    elseif Theme.FontBgEnabled then
        label.TextColor3 = Utils.GetContrastTextColor(Theme.FontBgColor)
    else
        label.TextColor3 = defaultColor or Theme.TextPrimary
    end

    if Theme.FontBgEnabled then
        label.BackgroundColor3 = Theme.FontBgColor
        label.BackgroundTransparency = Theme.FontBgTransparency
    end
end

function Utils.ApplyMenuFontAndColors()
    for i = #State.ThemedTexts, 1, -1 do
        local item = State.ThemedTexts[i]
        local lbl = item.Label
        if lbl and lbl.Parent then
            lbl.Font = item.IsBold and Theme.FontBold or Theme.FontFamily

            if Theme.FontBgEnabled then
                lbl.BackgroundColor3 = Theme.FontBgColor
                lbl.BackgroundTransparency = Theme.FontBgTransparency
                if not lbl:FindFirstChildOfClass("UICorner") then
                    Utils.AddCorner(lbl, 4)
                end
            else
                lbl.BackgroundColor3 = item.OrigBgColor
                lbl.BackgroundTransparency = item.OrigBgTransparency
            end

            if Theme.FontColorMode ~= "Auto" then
                lbl.TextColor3 = Theme.FontColorMode
            elseif Theme.FontBgEnabled then
                lbl.TextColor3 = Utils.GetContrastTextColor(Theme.FontBgColor)
            else
                lbl.TextColor3 = item.DefaultColor
            end
        else
            table.remove(State.ThemedTexts, i)
        end
    end
end

function Utils.SetAccentColor(newColor, newDark)
    Theme.Accent = newColor
    Theme.AccentDark = newDark or newColor
    Theme.Border = newColor

    for i = #State.AccentObjects, 1, -1 do
        local item = State.AccentObjects[i]
        if item.Object and item.Object.Parent then
            item.Object[item.Property] = newColor
        else
            table.remove(State.AccentObjects, i)
        end
    end

    for track, isActive in pairs(State.ActiveToggleTracks) do
        if track and track.Parent and isActive then
            track.BackgroundColor3 = newColor
        else
            State.ActiveToggleTracks[track] = nil
        end
    end

    for i = #State.AccentCallbacks, 1, -1 do
        local cb = State.AccentCallbacks[i]
        local ok = pcall(cb, newColor)
        if not ok then
            table.remove(State.AccentCallbacks, i)
        end
    end
end

function Utils.GetCharacter(plr)
    local target = plr or LocalPlayer
    local char = target and target.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

function Utils.GetAnimator(hum)
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    return animator
end

function Utils.CopyText(text)
    local ok = false
    if typeof(setclipboard) == "function" then
        ok = pcall(setclipboard, tostring(text))
    elseif typeof(toclipboard) == "function" then
        ok = pcall(toclipboard, tostring(text))
    end
    return ok
end

-- ============================================================================
-- PROFESSIONAL CROSS-WORLD TELEPORT & REMOTE VIEW STREAMING API (TeleportAPI)
-- Mendukung jangkauan tanpa batas jarak & multi-dunia di dalam satu map
-- ============================================================================
local TeleportAPI = {}

function TeleportAPI.FormatDistance(studs)
    if not studs or studs ~= studs then
        return "0 m"
    end
    if studs >= 1000000 then
        return string.format("%.2fM m (%.0f studs)", studs / 1000000, studs)
    elseif studs >= 10000 then
        return string.format("%.2fk m (%.0f studs)", studs / 1000, studs)
    end
    return string.format("%.0f m", studs)
end

function TeleportAPI.DetectSubWorldName(plr, pos)
    if plr then
        local worldKeys = {
            "world", "realm", "dimension", "zone", "area", "stage",
            "floor", "region", "island", "sector", "map", "dungeon", "place"
        }
        local function scanContainer(container)
            if not container then return nil end
            local okAttr, attrs = pcall(function()
                return container:GetAttributes()
            end)
            if okAttr and type(attrs) == "table" then
                for k, v in pairs(attrs) do
                    local lk = string.lower(tostring(k))
                    for _, kw in ipairs(worldKeys) do
                        if string.find(lk, kw, 1, true) and (type(v) == "string" or type(v) == "number") and tostring(v) ~= "" then
                            return tostring(v)
                        end
                    end
                end
            end
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("NumberValue") then
                    local lk = string.lower(child.Name)
                    for _, kw in ipairs(worldKeys) do
                        if string.find(lk, kw, 1, true) and tostring(child.Value) ~= "" then
                            return tostring(child.Value)
                        end
                    end
                end
            end
            return nil
        end

        local found = scanContainer(plr)
            or scanContainer(plr:FindFirstChild("leaderstats"))
            or scanContainer(plr:FindFirstChild("Data"))
            or scanContainer(plr:FindFirstChild("Stats"))
            or scanContainer(plr.Character)
        if found then
            return found
        end
    end

    if pos then
        local secX = math.floor((pos.X + 2500) / 5000)
        local secY = math.floor((pos.Y + 2500) / 5000)
        local secZ = math.floor((pos.Z + 2500) / 5000)
        if secX == 0 and secY == 0 and secZ == 0 then
            return "Main World (Pusat)"
        end
        return string.format("Dunia/Sektor [%d, %d, %d]", secX, secY, secZ)
    end
    return "Tidak Diketahui"
end

function TeleportAPI.ResolvePlayerState(plr)
    if not plr then return nil end

    local char = plr.Character
    if not char or not char.Parent then
        local charsFolder = workspace:FindFirstChild("Characters") or workspace:FindFirstChild("Players")
        if charsFolder then
            char = charsFolder:FindFirstChild(plr.Name)
        end
        if not char then
            local direct = workspace:FindFirstChild(plr.Name)
            if direct and direct:IsA("Model") then
                char = direct
            end
        end
    end

    local resolvedCF = nil
    local isStreamedIn = false
    local rootPart = nil
    local hum = nil

    if char and char.Parent then
        hum = char:FindFirstChildOfClass("Humanoid")
        rootPart = char:FindFirstChild("HumanoidRootPart")
            or char.PrimaryPart
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("Torso")
            or char:FindFirstChild("Head")
            or char:FindFirstChildWhichIsA("BasePart", true)

        if rootPart and rootPart:IsA("BasePart") then
            resolvedCF = rootPart.CFrame
            isStreamedIn = true
        else
            local okPivot, pivotCF = pcall(function()
                return char:GetPivot()
            end)
            if okPivot and typeof(pivotCF) == "CFrame" and pivotCF.Position ~= Vector3.zero then
                resolvedCF = pivotCF
            end
        end
    end

    if not resolvedCF then
        local posKeys = { "position", "pos", "cframe", "cf", "coords", "location", "lastpos" }
        local function extractPosFrom(container)
            if not container then return nil end
            local okAttr, attrs = pcall(function()
                return container:GetAttributes()
            end)
            if okAttr and type(attrs) == "table" then
                for k, v in pairs(attrs) do
                    local lk = string.lower(tostring(k))
                    for _, pk in ipairs(posKeys) do
                        if string.find(lk, pk, 1, true) then
                            if typeof(v) == "CFrame" then return v end
                            if typeof(v) == "Vector3" then return CFrame.new(v) end
                        end
                    end
                end
            end
            for _, child in ipairs(container:GetDescendants()) do
                local lk = string.lower(child.Name)
                for _, pk in ipairs(posKeys) do
                    if string.find(lk, pk, 1, true) then
                        if child:IsA("CFrameValue") then return child.Value end
                        if child:IsA("Vector3Value") then return CFrame.new(child.Value) end
                    end
                end
            end
            return nil
        end

        resolvedCF = extractPosFrom(plr) or (char and extractPosFrom(char))
    end

    if not resolvedCF then
        return nil
    end

    local pos = resolvedCF.Position
    return {
        Player = plr,
        Character = char,
        Humanoid = hum,
        RootPart = rootPart,
        CFrame = resolvedCF,
        Position = pos,
        IsStreamedIn = isStreamedIn,
        WorldName = TeleportAPI.DetectSubWorldName(plr, pos),
    }
end

function TeleportAPI.RequestStreamAt(pos, timeout)
    if typeof(pos) ~= "Vector3" then return end
    task.spawn(function()
        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(pos, timeout or 5)
        end)
    end)
end

function TeleportAPI.EnsureRemoteViewAnchor(targetCF)
    local anchor = State.SpectateAnchorPart
    if not anchor or not anchor.Parent then
        anchor = Instance.new("Part")
        anchor.Name = AntiDetect.GetStealthName("RemoteViewAnchor", "BSS_RemoteViewAnchor")
        anchor.Archivable = false
        anchor.Size = Vector3.new(1, 1, 1)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.Parent = AntiDetect.GetWorldHelperParent()
        State.SpectateAnchorPart = anchor
    end
    if targetCF then
        anchor.CFrame = targetCF
    end
    return anchor
end

function TeleportAPI.DestroyRemoteViewAnchor()
    if State.SpectateAnchorPart then
        pcall(function()
            State.SpectateAnchorPart:Destroy()
        end)
        State.SpectateAnchorPart = nil
    end
    local leftover = workspace:FindFirstChild("BSS_RemoteViewAnchor")
    if leftover then
        pcall(function()
            leftover:Destroy()
        end)
    end
end

function TeleportAPI.StartRemoteView(plr)
    if not plr or plr == LocalPlayer then return false end
    State.SpectatingPlayer = plr
    State.SpectateStreamTick = 0

    local info = TeleportAPI.ResolvePlayerState(plr)
    local cam = workspace.CurrentCamera
    if info then
        TeleportAPI.RequestStreamAt(info.Position, 5)
        local anchor = TeleportAPI.EnsureRemoteViewAnchor(info.CFrame * CFrame.new(0, 1.5, 0))
        pcall(function()
            LocalPlayer.ReplicationFocus = info.RootPart or anchor
        end)
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = info.Humanoid or info.RootPart or anchor
        end
    else
        local anchor = TeleportAPI.EnsureRemoteViewAnchor(CFrame.new(0, 10, 0))
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = anchor
        end
    end
    return true, info
end

function TeleportAPI.StepRemoteView()
    local specPlr = State.SpectatingPlayer
    if not specPlr then return nil end
    if not specPlr.Parent then
        TeleportAPI.StopRemoteView(false)
        return nil
    end

    local cam = workspace.CurrentCamera
    local info = TeleportAPI.ResolvePlayerState(specPlr)
    if info then
        local anchor = TeleportAPI.EnsureRemoteViewAnchor(info.CFrame * CFrame.new(0, 1.5, 0))
        local subject = info.Humanoid or info.RootPart or anchor

        if cam and subject then
            if cam.CameraType ~= Enum.CameraType.Custom then
                cam.CameraType = Enum.CameraType.Custom
            end
            if cam.CameraSubject ~= subject then
                cam.CameraSubject = subject
            end
        end

        pcall(function()
            LocalPlayer.ReplicationFocus = info.RootPart or anchor
        end)

        local now = os.clock()
        if (now - State.SpectateStreamTick) >= 0.35 then
            State.SpectateStreamTick = now
            TeleportAPI.RequestStreamAt(info.Position, 4)
        end
    end
    return info
end

function TeleportAPI.StopRemoteView(notifyUser)
    State.SpectatingPlayer = nil
    TeleportAPI.DestroyRemoteViewAnchor()
    pcall(function()
        LocalPlayer.ReplicationFocus = nil
    end)
    local cam = workspace.CurrentCamera
    local _, myHum = Utils.GetCharacter(LocalPlayer)
    if cam and myHum then
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = myHum
    end
    if notifyUser then
        Utils.Notify("View Dimatikan", "Kamera & fokus streaming kembali ke karakter Anda.", Theme.TextSecondary)
    end
end

function Utils.GetTargetWorldPosition(target)
    if typeof(target) == "CFrame" then
        return target.Position
    elseif typeof(target) == "Vector3" then
        return target
    elseif typeof(target) == "Instance" then
        if target:IsA("Player") then
            local info = TeleportAPI.ResolvePlayerState(target)
            return info and info.Position or nil
        elseif target:IsA("Model") then
            local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
            if root then return root.Position end
            local okPivot, pivotCF = pcall(function() return target:GetPivot() end)
            return (okPivot and typeof(pivotCF) == "CFrame") and pivotCF.Position or nil
        elseif target:IsA("BasePart") then
            return target.Position
        end
    end
    return nil
end

function Utils.SafeTeleport(targetCFrame, targetPlayer)
    if AntiDetect.Enabled and AntiDetect.TeleportStealthEnabled then
        return AntiDetect.ExecuteStealthTeleport(targetCFrame, targetPlayer)
    end
    local char, hum, root = Utils.GetCharacter(LocalPlayer)
    if not char or not root then
        return false, 0
    end

    local startPos = root.Position
    local destCF = targetCFrame
    if targetPlayer then
        local liveInfo = TeleportAPI.ResolvePlayerState(targetPlayer)
        if liveInfo then
            destCF = liveInfo.CFrame * CFrame.new(0, 0.5, 3)
        end
    end

    local destPos = destCF.Position
    local travelDistance = (destPos - startPos).Magnitude
    State.LastTeleportDistance = travelDistance

    State.TeleportToken = State.TeleportToken + 1
    local myToken = State.TeleportToken

    if hum then
        hum.Sit = false
        if hum.SeatPart then
            local weld = hum.SeatPart:FindFirstChild("SeatWeld")
            if weld then weld:Destroy() end
        end
    end

    TeleportAPI.RequestStreamAt(destPos, 6)

    if not State.IsTeleportLocking then
        State.PreTeleportAnchored = root.Anchored
        State.IsTeleportLocking = true
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    root.Anchored = true
    char:PivotTo(destCF)
    Combat.LastSafePosition = destPos
    Combat.LastSafeCFrame = destCF

    task.spawn(function()
        local maxSteps = (travelDistance > 2500 or targetPlayer ~= nil) and 22 or 12
        for step = 1, maxSteps do
            RunService.Heartbeat:Wait()
            if State.TeleportToken ~= myToken then
                return
            end

            if targetPlayer and targetPlayer.Parent then
                local updatedInfo = TeleportAPI.ResolvePlayerState(targetPlayer)
                if updatedInfo then
                    destCF = updatedInfo.CFrame * CFrame.new(0, 0.5, 3)
                    destPos = destCF.Position
                end
            end

            if step == 4 or step == 10 or step == 16 then
                TeleportAPI.RequestStreamAt(destPos, 4)
            end

            if char and char.Parent and root and root.Parent then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                char:PivotTo(destCF)
            end
        end

        if State.TeleportToken == myToken then
            if root and root.Parent then
                root.Anchored = State.PreTeleportAnchored
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                Combat.LastSafePosition = root.Position
                Combat.LastSafeCFrame = root.CFrame
            end
            State.IsTeleportLocking = false
        end
    end)

    return true, travelDistance
end

-- ============================================================================
-- 4. 3D HD LUXURY SKULL LOGO BUILDER (Pure Procedural 3D High-Detail UI)
-- ============================================================================
function Utils.CreateSkull3D(parent, pixelSize, position, anchorPoint, zIndex, isHero, isMenuSkull, phaseOffset)
    local z = zIndex or 20
    local basePos = position or UDim2.new(0, 0, 0, 0)
    local holder = Utils.Create("Frame", {
        Name = "Skull3D_HD",
        Size = UDim2.new(0, pixelSize, 0, pixelSize),
        Position = basePos,
        AnchorPoint = anchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        ZIndex = z,
    }, parent)

    local aura = Utils.Create("Frame", {
        Size = UDim2.new(1.24, 0, 1.24, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 168, 58),
        BackgroundTransparency = isHero and 0.68 or 0.78,
        BorderSizePixel = 0,
        ZIndex = z,
    }, holder)
    Utils.AddCorner(aura, math.floor(pixelSize * 0.65))

    local haloRing = Utils.Create("Frame", {
        Size = UDim2.new(1.06, 0, 1.06, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = z + 1,
    }, holder)
    Utils.AddCorner(haloRing, math.floor(pixelSize * 0.55))
    local ringStroke = Utils.AddStroke(haloRing, Color3.fromRGB(255, 206, 108), isHero and 1.35 or 1.0, 0.32)

    local crownBase = Utils.Create("Frame", {
        Size = UDim2.new(0.42, 0, 0.11, 0),
        Position = UDim2.new(0.5, 0, 0.08, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(crownBase, 3)
    Utils.Create("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(198, 142, 42)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 232, 138)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(184, 126, 34)),
        }),
    }, crownBase)
    Utils.AddStroke(crownBase, Color3.fromRGB(92, 58, 12), 0.8, 0.35)

    for _, spikeCfg in ipairs({
        { x = 0.22, h = 0.95, rot = -10 },
        { x = 0.50, h = 1.25, rot = 0 },
        { x = 0.78, h = 0.95, rot = 10 },
    }) do
        local spike = Utils.Create("Frame", {
            Size = UDim2.new(0.18, 0, spikeCfg.h, 0),
            Position = UDim2.new(spikeCfg.x, 0, -0.35, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = spikeCfg.rot,
            BackgroundColor3 = Color3.fromRGB(255, 218, 106),
            BorderSizePixel = 0,
            ZIndex = z + 6,
        }, crownBase)
        Utils.AddCorner(spike, 2)
    end

    local craniumShadow = Utils.Create("Frame", {
        Size = UDim2.new(0.76, 0, 0.62, 0),
        Position = UDim2.new(0.5, 0, 0.42, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(122, 114, 136),
        BorderSizePixel = 0,
        ZIndex = z + 2,
    }, holder)
    Utils.AddCorner(craniumShadow, math.floor(pixelSize * 0.42))

    local cranium = Utils.Create("Frame", {
        Size = UDim2.new(0.72, 0, 0.58, 0),
        Position = UDim2.new(0.5, 0, 0.40, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 3,
    }, holder)
    Utils.AddCorner(cranium, math.floor(pixelSize * 0.4))
    Utils.Create("UIGradient", {
        Rotation = 115,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 253, 248)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(232, 226, 238)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 138, 162)),
        }),
    }, cranium)
    Utils.AddStroke(cranium, Color3.fromRGB(88, 76, 104), isHero and 1.1 or 0.85, 0.35)

    local specular = Utils.Create("Frame", {
        Size = UDim2.new(0.34, 0, 0.16, 0),
        Position = UDim2.new(0.38, 0, 0.20, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -16,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.32,
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, cranium)
    Utils.AddCorner(specular, 99)

    for _, side in ipairs({ -1, 1 }) do
        local temple = Utils.Create("Frame", {
            Size = UDim2.new(0.14, 0, 0.34, 0),
            Position = UDim2.new(0.5 + (side * 0.38), 0, 0.56, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = side * 12,
            BackgroundColor3 = Color3.fromRGB(140, 130, 154),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = z + 4,
        }, cranium)
        Utils.AddCorner(temple, 6)
    end

    local cheekLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.26, 0, 0.21, 0),
        Position = UDim2.new(0.28, 0, 0.59, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -18,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(cheekLeft, 6)
    Utils.Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(246, 242, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(154, 144, 168)),
        }),
    }, cheekLeft)

    local cheekRight = Utils.Create("Frame", {
        Size = UDim2.new(0.26, 0, 0.21, 0),
        Position = UDim2.new(0.72, 0, 0.59, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 18,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(cheekRight, 6)
    Utils.Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(246, 242, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(154, 144, 168)),
        }),
    }, cheekRight)

    local browRidge = Utils.Create("Frame", {
        Size = UDim2.new(0.58, 0, 0.08, 0),
        Position = UDim2.new(0.5, 0, 0.40, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(186, 176, 200),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, holder)
    Utils.AddCorner(browRidge, 4)

    local socketLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.21, 0, 0.19, 0),
        Position = UDim2.new(0.35, 0, 0.49, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = -10,
        BackgroundColor3 = Color3.fromRGB(18, 12, 26),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(socketLeft, math.max(4, math.floor(pixelSize * 0.14)))
    Utils.AddStroke(socketLeft, Color3.fromRGB(115, 102, 130), 0.9, 0.25)

    local eyeLeft = Utils.Create("Frame", {
        Size = UDim2.new(0.56, 0, 0.56, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 198, 72),
        BorderSizePixel = 0,
        ZIndex = z + 7,
    }, socketLeft)
    Utils.AddCorner(eyeLeft, 99)

    local socketRight = Utils.Create("Frame", {
        Size = UDim2.new(0.21, 0, 0.19, 0),
        Position = UDim2.new(0.65, 0, 0.49, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 10,
        BackgroundColor3 = Color3.fromRGB(18, 12, 26),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(socketRight, math.max(4, math.floor(pixelSize * 0.14)))
    Utils.AddStroke(socketRight, Color3.fromRGB(115, 102, 130), 0.9, 0.25)

    local eyeRight = Utils.Create("Frame", {
        Size = UDim2.new(0.56, 0, 0.56, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 198, 72),
        BorderSizePixel = 0,
        ZIndex = z + 7,
    }, socketRight)
    Utils.AddCorner(eyeRight, 99)

    local noseCavity = Utils.Create("Frame", {
        Size = UDim2.new(0.11, 0, 0.13, 0),
        Position = UDim2.new(0.5, 0, 0.61, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(22, 16, 30),
        BorderSizePixel = 0,
        ZIndex = z + 6,
    }, holder)
    Utils.AddCorner(noseCavity, 3)

    local jawBasePos = UDim2.new(0.5, 0, 0.77, 0)
    local jaw = Utils.Create("Frame", {
        Size = UDim2.new(0.46, 0, 0.22, 0),
        Position = jawBasePos,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = z + 4,
    }, holder)
    Utils.AddCorner(jaw, 6)
    Utils.Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(234, 228, 240)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(142, 132, 156)),
        }),
    }, jaw)
    Utils.AddStroke(jaw, Color3.fromRGB(88, 76, 104), 0.85, 0.35)

    local mouth = Utils.Create("Frame", {
        Size = UDim2.new(0.76, 0, 0.44, 0),
        Position = UDim2.new(0.5, 0, 0.48, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 16, 32),
        BorderSizePixel = 0,
        ZIndex = z + 5,
    }, jaw)
    Utils.AddCorner(mouth, 3)

    local toothCount = (pixelSize >= 32) and 4 or 3
    for tIdx = 1, toothCount do
        local xRatio = (tIdx - 0.5) / toothCount
        local tooth = Utils.Create("Frame", {
            Size = UDim2.new((0.76 / toothCount), 0, 0.84, 0),
            Position = UDim2.new(xRatio, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(248, 244, 252),
            BorderSizePixel = 0,
            ZIndex = z + 6,
        }, mouth)
        Utils.AddCorner(tooth, 2)
    end

    table.insert(UI.Skulls, {
        Holder = holder,
        Aura = aura,
        HaloRing = haloRing,
        RingStroke = ringStroke,
        Crown = crownBase,
        EyeLeft = eyeLeft,
        EyeRight = eyeRight,
        Jaw = jaw,
        JawBasePos = jawBasePos,
        Mouth = mouth,
        BasePos = basePos,
        Phase = phaseOffset or 0,
        IsHero = isHero == true,
        IsMenuSkull = isMenuSkull == true,
    })

    return holder
end

-- ============================================================================
-- 5. SMOOTH ADMIN FLIGHT & PHYSICS CLEANUP HELPERS
-- ============================================================================
function Physics.CleanupFly()
    for _, inst in ipairs({ Physics.FlyLV, Physics.FlyAO, Physics.FlyAttachment, Physics.FlyBV, Physics.FlyBG }) do
        if inst then
            pcall(function() inst:Destroy() end)
        end
    end
    Physics.FlyLV = nil
    Physics.FlyAO = nil
    Physics.FlyAttachment = nil
    Physics.FlyBV = nil
    Physics.FlyBG = nil
    Physics.FlyCurrentVel = Vector3.zero

    local _, hum, root = Utils.GetCharacter()
    if root then
        for _, objName in ipairs({
            "BSS_FlyLinearVel", "BSS_FlyAlignOri", "BSS_FlyAttachment", "BSS_FlyVelocity", "BSS_FlyGyro",
            "LinearVelocityConstraint", "AlignOrientationConstraint", "RootRigAttachment_Aux"
        }) do
            local old = root:FindFirstChild(objName)
            if old then old:Destroy() end
        end
        root.AssemblyLinearVelocity = Vector3.zero
    end
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
        if hum:GetState() == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

function Physics.StepSmoothFly(dt)
    if State.FlyEnabled and AntiDetect.Enabled and AntiDetect.FlyStealthEnabled then
        if AntiDetect.StepFlyStealth(dt) then
            return
        end
    end
    local _, hum, root = Utils.GetCharacter()
    local cam = workspace.CurrentCamera
    if not State.FlyEnabled or not hum or not root or not cam then
        if Physics.FlyLV or Physics.FlyBV then
            Physics.CleanupFly()
        end
        return
    end

    if hum.Sit then
        hum.Sit = false
    end

    if not Physics.FlyAttachment or Physics.FlyAttachment.Parent ~= root then
        Physics.CleanupFly()
        local flyNames = AntiDetect.GetFlyInstanceNames()
        local att = Instance.new("Attachment")
        att.Name = flyNames.Attachment
        att.Archivable = false
        att.Parent = root
        Physics.FlyAttachment = att

        local lv = Instance.new("LinearVelocity")
        lv.Name = flyNames.LinearVelocity
        lv.Archivable = false
        lv.Attachment0 = att
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.MaxForce = 9e9
        lv.VectorVelocity = Vector3.zero
        lv.Parent = root
        Physics.FlyLV = lv

        local ao = Instance.new("AlignOrientation")
        ao.Name = flyNames.AlignOrientation
        ao.Archivable = false
        ao.Attachment0 = att
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.RigidityEnabled = false
        ao.MaxTorque = 9e9
        ao.Responsiveness = 38
        ao.CFrame = cam.CFrame
        ao.Parent = root
        Physics.FlyAO = ao
    end

    hum.PlatformStand = true
    hum.AutoRotate = false
    Physics.FlyAO.CFrame = cam.CFrame

    local forward = 0
    local right = 0
    local up = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward = forward + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward = forward - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then right = right + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then right = right - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        up = up - 1
    end

    if forward == 0 and right == 0 and hum.MoveDirection.Magnitude > 0.05 then
        local camCF = cam.CFrame
        local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
        local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
        if flatLook.Magnitude > 0.001 then
            forward = hum.MoveDirection:Dot(flatLook.Unit)
        else
            local flatUp = Vector3.new(camCF.UpVector.X, 0, camCF.UpVector.Z)
            if flatUp.Magnitude > 0.001 then
                forward = hum.MoveDirection:Dot(flatUp.Unit) * (camCF.LookVector.Y < 0 and 1 or -1)
            end
        end
        if flatRight.Magnitude > 0.001 then
            right = hum.MoveDirection:Dot(flatRight.Unit)
        end
    end

    local desiredDir = (cam.CFrame.LookVector * forward) + (cam.CFrame.RightVector * right) + Vector3.new(0, up, 0)
    local targetVel = Vector3.zero
    if desiredDir.Magnitude > 0.01 then
        targetVel = desiredDir.Unit * State.FlySpeed
    end

    local alpha = math.clamp((dt or 0.016) * 14, 0.15, 1)
    Physics.FlyCurrentVel = Physics.FlyCurrentVel:Lerp(targetVel, alpha)
    if Physics.FlyCurrentVel.Magnitude < 0.05 and targetVel == Vector3.zero then
        Physics.FlyCurrentVel = Vector3.zero
    end

    Physics.FlyLV.VectorVelocity = Physics.FlyCurrentVel
    root.AssemblyAngularVelocity = Vector3.zero
end

function Physics.RestoreNoclip()
    for part, origCollide in pairs(Physics.NoclipCache) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CanCollide = origCollide
        end
    end
    table.clear(Physics.NoclipCache)
end

-- ============================================================================
-- 6. ROOT SCREENGUI & SINGLE-CARD NOTIFICATION SYSTEM (ANTI-SPAM)
-- ============================================================================
local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

do
    AntiDetect.InstallHooks()
    UI.ScreenGui = Utils.Create("ScreenGui", {
        Name = AntiDetect.GetStealthName("MainScreenGui", App.GuiName),
        Archivable = false,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, AntiDetect.GetStealthGuiParent())
    AntiDetect.ProtectInstance(UI.ScreenGui, "MainScreenGui", App.GuiName)

    UI.ToastContainer = Utils.Create("Frame", {
        Name = "ToastContainer",
        Size = UDim2.new(0, 300, 1, -24),
        Position = UDim2.new(1, -316, 0, 12),
        BackgroundTransparency = 1,
        ZIndex = 60,
    }, UI.ScreenGui)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, UI.ToastContainer)
end

function Utils.Notify(title, message, color)
    if not UI.ToastContainer or not UI.ToastContainer.Parent then return end
    local accent = color or Theme.Accent

    -- Hapus langsung kartu notifikasi sebelumnya agar TIDAK PERNAH spam/menumpuk (selalu 1 kartu saja)
    UI.ActiveToastToken = (UI.ActiveToastToken or 0) + 1
    local myToastToken = UI.ActiveToastToken

    if UI.ActiveToast and UI.ActiveToast.Parent then
        UI.ActiveToast:Destroy()
        UI.ActiveToast = nil
    end
    for _, child in ipairs(UI.ToastContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local toast = Utils.Create("Frame", {
        Name = "SingleNotifyCard",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        ZIndex = 61,
    }, UI.ToastContainer)
    Utils.AddCorner(toast, 9)
    Utils.AddStroke(toast, accent, 1.1, 0.25)
    UI.ActiveToast = toast

    local bar = Utils.Create("Frame", {
        Size = UDim2.new(0, 4, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        ZIndex = 62,
    }, toast)
    Utils.AddCorner(bar, 2)

    Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 18, 0, 7),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = tostring(title),
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 62,
    }, toast)

    Utils.Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.new(0, 18, 0, 27),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = tostring(message),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 62,
    }, toast)

    task.delay(3.0, function()
        if UI.ActiveToastToken ~= myToastToken then return end
        if toast and toast.Parent then
            Utils.Tween(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            })
            task.wait(0.26)
            if UI.ActiveToastToken == myToastToken and toast and toast.Parent then
                toast:Destroy()
                if UI.ActiveToast == toast then
                    UI.ActiveToast = nil
                end
            end
        end
    end)
end

-- ============================================================================
-- 7. BUILD MAIN WINDOW (LUXURY SKULL 3D HD TRANSPARENT + 4 CORNER SKULLS)
-- ============================================================================
do
    UI.FloatingToggle = Utils.Create("TextButton", {
        Name = "FloatingSkullToggle",
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 18, 0.5, -28),
        BackgroundColor3 = Color3.fromRGB(18, 14, 28),
        BackgroundTransparency = 0.25,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 45,
    }, UI.ScreenGui)
    Utils.AddCorner(UI.FloatingToggle, 28)
    local floatStroke = Utils.AddStroke(UI.FloatingToggle, Theme.Accent, 1.6, 0.15)
    Utils.RegisterAccent(floatStroke, "Color")

    Utils.CreateSkull3D(
        UI.FloatingToggle,
        44,
        UDim2.new(0.5, 0, 0.5, 0),
        Vector2.new(0.5, 0.5),
        46,
        true,
        false,
        0
    )

    local initVp = UI.ScreenGui.AbsoluteSize
    local initW = (initVp.X > 0) and math.min(650, math.max(320, initVp.X - 24)) or 650
    local initH = (initVp.Y > 0) and math.min(435, math.max(240, initVp.Y - 24)) or 435
    App.ExpandedWidth = initW
    App.ExpandedHeight = initH

    UI.MainFrame = Utils.Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, initW, 0, initH),
        Position = UDim2.new(0.5, -math.floor(initW / 2), 0.5, -math.floor(initH / 2)),
        BackgroundColor3 = Theme.BgPrimary,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 10,
    }, UI.ScreenGui)
    Utils.AddCorner(UI.MainFrame, 14)
    local mainStroke = Utils.AddStroke(UI.MainFrame, Theme.Accent, 1.5, 0.15)
    Utils.RegisterAccent(mainStroke, "Color")

    local bgGradient = Utils.Create("UIGradient", {
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 20, 48)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(16, 13, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 22, 16)),
        }),
    }, UI.MainFrame)
    bgGradient.Name = "LuxurySkullGradient"

    Utils.CreateSkull3D(UI.MainFrame, 30, UDim2.new(0, -9, 0, -9), Vector2.new(0, 0), 30, false, true, 0.0)
    Utils.CreateSkull3D(UI.MainFrame, 30, UDim2.new(1, 9, 0, -9), Vector2.new(1, 0), 30, false, true, 1.57)
    Utils.CreateSkull3D(UI.MainFrame, 30, UDim2.new(0, -9, 1, 9), Vector2.new(0, 1), 30, false, true, 3.14)
    Utils.CreateSkull3D(UI.MainFrame, 30, UDim2.new(1, 9, 1, 9), Vector2.new(1, 1), 30, false, true, 4.71)

    UI.InnerClip = Utils.Create("Frame", {
        Name = "InnerClip",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 11,
    }, UI.MainFrame)
    Utils.AddCorner(UI.InnerClip, 14)

    UI.Topbar = Utils.Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, UI.InnerClip)

    Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 13,
    }, UI.Topbar)

    Utils.CreateSkull3D(UI.Topbar, 34, UDim2.new(0, 32, 0.5, 0), Vector2.new(0.5, 0.5), 14, true, true, 0.8)

    local titleRow = Utils.Create("Frame", {
        Name = "TitleRow",
        Size = UDim2.new(1, -142, 0, 22),
        Position = UDim2.new(0, 54, 0, 6),
        BackgroundTransparency = 1,
        ZIndex = 14,
    }, UI.Topbar)
    UI.TitleRow = titleRow

    local titleLayout = Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, titleRow)

    local titleLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = App.Name,
        TextColor3 = Theme.TextPrimary,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 14,
    }, titleRow)
    UI.TitleLabel = titleLbl
    Utils.RegisterText(titleLbl, true, Theme.TextPrimary)

    local verifiedBadge = Utils.Create("Frame", {
        Name = "VerifiedBlueBadge",
        Size = UDim2.new(0, 17, 0, 17),
        BackgroundColor3 = Color3.fromRGB(0, 162, 255),
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 15,
    }, titleRow)
    Utils.AddCorner(verifiedBadge, 99)
    Utils.AddStroke(verifiedBadge, Color3.fromRGB(165, 228, 255), 1.1, 0.15)
    Utils.Create("UIGradient", {
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 198, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 118, 235)),
        }),
    }, verifiedBadge)
    Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "✓",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        ZIndex = 16,
    }, verifiedBadge)
    UI.VerifiedBadge = verifiedBadge

    local ipBannerBtn = Utils.Create("TextButton", {
        Name = "IPSubtitleButton",
        Size = UDim2.new(1, -142, 0, 18),
        Position = UDim2.new(0, 54, 0, 28),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.92,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 14,
    }, UI.Topbar)
    UI.SubtitleBanner = ipBannerBtn
    Utils.AddCorner(ipBannerBtn, 5)
    Utils.AddStroke(ipBannerBtn, Color3.fromRGB(255, 255, 255), 0.8, 0.72)

    local subLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = App.Subtitle,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeColor3 = Color3.fromRGB(10, 10, 14),
        TextStrokeTransparency = 0.25,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, ipBannerBtn)
    UI.SubLabel = subLbl

    UI.SubLabelGradient = Utils.Create("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(45, 45, 54)),
            ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(24, 24, 30)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(45, 45, 54)),
        }),
    }, subLbl)

    ipBannerBtn.MouseEnter:Connect(function()
        Utils.Tween(ipBannerBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.82 })
    end)
    ipBannerBtn.MouseLeave:Connect(function()
        Utils.Tween(ipBannerBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.92 })
    end)
    ipBannerBtn.MouseButton1Click:Connect(function()
        local copyPayload = App.Subtitle .. " | IP: " .. GeoLangAPI.IPAddress
        if Utils.CopyText(copyPayload) then
            Utils.Notify("Informasi", "Teks disalin ke clipboard:\n" .. App.Subtitle, Theme.Success)
        else
            Utils.Notify("Informasi", App.Subtitle, Theme.Accent)
        end
    end)

    local function createTopBtn(text, offsetX, hoverColor)
        local btn = Utils.Create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, offsetX, 0.5, -14),
            BackgroundColor3 = Theme.BgControl,
            BackgroundTransparency = 0.2,
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = Theme.TextPrimary,
            TextSize = 13,
            AutoButtonColor = false,
            ZIndex = 15,
        }, UI.Topbar)
        Utils.AddCorner(btn, 7)
        btn.MouseEnter:Connect(function()
            Utils.Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor })
        end)
        btn.MouseLeave:Connect(function()
            Utils.Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.BgControl })
        end)
        return btn
    end

    UI.MinimizeBtn = createTopBtn("-", -76, Theme.Accent)
    UI.CloseBtn = createTopBtn("✕", -42, Theme.Danger)

    local initSidebarW = (initW < 500) and math.clamp(math.floor(initW * 0.30), 116, 166) or 166

    UI.Sidebar = Utils.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, initSidebarW, 1, -54),
        Position = UDim2.new(0, 0, 0, 54),
        BackgroundColor3 = Theme.BgSecondary,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, UI.InnerClip)

    Utils.Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.BorderSubtle,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 13,
    }, UI.Sidebar)

    UI.SidebarScroll = Utils.Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -46),
        Position = UDim2.new(0, 6, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 13,
    }, UI.Sidebar)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, UI.SidebarScroll)

    local footerBox = Utils.Create("Frame", {
        Size = UDim2.new(1, -14, 0, 28),
        Position = UDim2.new(0, 7, 1, -35),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 13,
    }, UI.Sidebar)
    Utils.AddCorner(footerBox, 7)

    local dot = Utils.Create("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 10, 0.5, -4),
        BackgroundColor3 = Theme.Success,
        BorderSizePixel = 0,
        ZIndex = 14,
    }, footerBox)
    Utils.AddCorner(dot, 4)

    local statusLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -26, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Anti-Bug: AKTIF",
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    }, footerBox)
    UI.StatusLabel = statusLbl
    Utils.RegisterText(statusLbl, false, Theme.TextSecondary)

    UI.ContentContainer = Utils.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -initSidebarW, 1, -54),
        Position = UDim2.new(0, initSidebarW, 0, 54),
        BackgroundTransparency = 1,
        ZIndex = 12,
    }, UI.InnerClip)

    UI.ResizeHandle = Utils.Create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "◢",
        TextColor3 = Theme.Accent,
        TextTransparency = 0.35,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 24,
    }, UI.InnerClip)
    Utils.RegisterAccent(UI.ResizeHandle, "TextColor3")
end

-- ============================================================================
-- 8. DRAGGING SUPPORT (Mouse & Multi-Touch Safe)
-- ============================================================================
do
    local function makeDraggable(dragHandle, targetFrame)
        local dragging = false
        local activeDragInput = nil
        local dragStart = nil
        local startPos = nil

        Utils.Track(dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                activeDragInput = input
                dragStart = input.Position
                startPos = targetFrame.Position
            end
        end))

        Utils.Track(UserInputService.InputChanged:Connect(function(input)
            if not dragging or not activeDragInput or not dragStart or not startPos then
                return
            end
            local isMatchingMouse = (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseMovement)
            local isMatchingTouch = (input == activeDragInput)

            if isMatchingMouse or isMatchingTouch then
                local delta = input.Position - dragStart
                targetFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end))

        Utils.Track(UserInputService.InputEnded:Connect(function(input)
            if dragging and (input == activeDragInput or (activeDragInput and activeDragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
                dragging = false
                activeDragInput = nil
            end
        end))
    end

    makeDraggable(UI.Topbar, UI.MainFrame)
    makeDraggable(UI.FloatingToggle, UI.FloatingToggle)
end

-- ============================================================================
-- 9. REUSABLE UI COMPONENT BUILDERS (DENGAN TERJEMAHAN BAHASA DINAMIS)
-- ============================================================================
function Components.SwitchTab(tabName)
    App.ActiveTab = tabName
    for name, tabData in pairs(UI.Tabs) do
        local isSelected = (name == tabName)
        Utils.Tween(tabData.Button, TweenInfo.new(0.18), {
            BackgroundColor3 = isSelected and Theme.BgControl or Theme.BgSecondary,
            BackgroundTransparency = isSelected and 0.18 or 1,
        })
        tabData.Indicator.Visible = isSelected
    end
    for name, page in pairs(UI.Pages) do
        page.Visible = (name == tabName)
    end
end

function Components.CreateTab(name, iconText, order)
    local langKey = "tab_" .. name:gsub("%s+", "")
    local initialDisplay = GeoLangAPI.T(langKey)

    local btn = Utils.Create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.BgControl,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 14,
    }, UI.SidebarScroll)
    Utils.AddCorner(btn, 7)

    local indicator = Utils.Create("Frame", {
        Size = UDim2.new(0, 3, 0, 18),
        Position = UDim2.new(0, 4, 0.5, -9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 15,
    }, btn)
    Utils.AddCorner(indicator, 2)
    Utils.RegisterAccent(indicator, "BackgroundColor3")

    local label = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 13, 0, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = iconText .. "  " .. initialDisplay,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
    }, btn)
    Utils.RegisterText(label, false, Theme.TextPrimary)

    local page = Utils.Create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, -14, 1, -14),
        Position = UDim2.new(0, 7, 0, 7),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 13,
    }, UI.ContentContainer)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    Utils.Create("UIPadding", {
        PaddingRight = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 10),
    }, page)

    btn.MouseButton1Click:Connect(function()
        Components.SwitchTab(name)
    end)

    GeoLangAPI.OnLanguageChanged(function()
        if label and label.Parent then
            label.Text = iconText .. "  " .. GeoLangAPI.T(langKey)
        end
    end)

    UI.Tabs[name] = {
        Button = btn,
        Label = label,
        Indicator = indicator,
        IconText = iconText,
        LangKey = langKey,
    }
    UI.Pages[name] = page
    return page
end

function Components.AddSectionHeader(parent, title, order)
    local lbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "💀 " .. string.upper(GeoLangAPI.TranslateFeatureText(title)),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.RegisterAccent(lbl, "TextColor3")
    GeoLangAPI.OnLanguageChanged(function()
        if lbl and lbl.Parent then
            lbl.Text = "💀 " .. string.upper(GeoLangAPI.TranslateFeatureText(title))
        end
    end)
    return lbl
end

function Components.AddToggle(parent, title, subtitle, defaultVal, order, callback)
    local enabled = defaultVal == true

    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, card)

    local textBox = Utils.Create("Frame", {
        Size = UDim2.new(1, -56, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, card)
    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, textBox)

    local tLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = GeoLangAPI.TranslateFeatureText(title),
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 15,
    }, textBox)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)
    GeoLangAPI.BindFeatureText(tLbl, title)

    local sLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = GeoLangAPI.TranslateFeatureText(subtitle),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 15,
    }, textBox)
    Utils.RegisterText(sLbl, false, Theme.TextSecondary)
    GeoLangAPI.BindFeatureText(sLbl, subtitle)

    local switchTrack = Utils.Create("TextButton", {
        Size = UDim2.new(0, 44, 0, 22),
        Position = UDim2.new(1, -44, 0.5, -11),
        BackgroundColor3 = enabled and Theme.Accent or Theme.BgControl,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(switchTrack, 11)

    if enabled then
        State.ActiveToggleTracks[switchTrack] = true
    end

    local knob = Utils.Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 16,
    }, switchTrack)
    Utils.AddCorner(knob, 8)

    local function setState(newState, fireCallback)
        enabled = newState
        State.ActiveToggleTracks[switchTrack] = enabled and true or nil

        Utils.Tween(switchTrack, TweenInfo.new(0.18), {
            BackgroundColor3 = enabled and Theme.Accent or Theme.BgControl
        })
        Utils.Tween(knob, TweenInfo.new(0.18), {
            Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        })
        if fireCallback and callback then
            SafeEngine.Run(title, callback, enabled)
        end
    end

    switchTrack.MouseButton1Click:Connect(function()
        setState(not enabled, true)
    end)

    return {
        SetState = setState,
        GetState = function() return enabled end,
    }
end

function Components.AddSlider(parent, title, minVal, maxVal, defaultVal, decimals, order, callback)
    local currentVal = math.clamp(defaultVal, minVal, maxVal)
    local precision = decimals or 0

    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    local tLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 18),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = GeoLangAPI.TranslateFeatureText(title),
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)
    GeoLangAPI.BindFeatureText(tLbl, title)

    local function formatVal(v)
        if precision <= 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%." .. tostring(precision) .. "f", v)
    end

    local valueLabel = Utils.Create("TextLabel", {
        Size = UDim2.new(0.3, -12, 0, 18),
        Position = UDim2.new(0.7, 0, 0, 8),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = formatVal(currentVal),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 15,
    }, card)
    Utils.RegisterAccent(valueLabel, "TextColor3")

    local track = Utils.Create("TextButton", {
        Size = UDim2.new(1, -24, 0, 8),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = Theme.BgControl,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(track, 4)

    local initRatio = (currentVal - minVal) / math.max(0.0001, (maxVal - minVal))
    local fill = Utils.Create("Frame", {
        Size = UDim2.new(initRatio, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 16,
    }, track)
    Utils.AddCorner(fill, 4)
    Utils.RegisterAccent(fill, "BackgroundColor3")

    local thumb = Utils.Create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(initRatio, -7, 0.5, -7),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 17,
    }, track)
    Utils.AddCorner(thumb, 7)

    local sliding = false

    local function setValue(val, fireCallback)
        currentVal = math.clamp(val, minVal, maxVal)
        if precision <= 0 then
            currentVal = math.floor(currentVal + 0.5)
        else
            local mult = 10 ^ precision
            currentVal = math.floor(currentVal * mult + 0.5) / mult
        end
        local ratio = (currentVal - minVal) / math.max(0.0001, (maxVal - minVal))
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        thumb.Position = UDim2.new(ratio, -7, 0.5, -7)
        valueLabel.Text = formatVal(currentVal)
        if fireCallback and callback then
            SafeEngine.Run(title, callback, currentVal)
        end
    end

    local function updateFromInput(inputPos)
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end
        local relX = math.clamp((inputPos.X - track.AbsolutePosition.X) / trackWidth, 0, 1)
        local rawVal = minVal + (maxVal - minVal) * relX
        setValue(rawVal, true)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromInput(input.Position)
        end
    end)

    Utils.Track(UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input.Position)
        end
    end))

    Utils.Track(UserInputService.InputEnded:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
        end
    end))

    return {
        SetValue = setValue,
        GetValue = function() return currentVal end,
    }
end

function Components.AddButton(parent, title, subtitle, btnLabel, order, callback)
    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    local tLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = GeoLangAPI.TranslateFeatureText(title),
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(tLbl, true, Theme.TextPrimary)
    GeoLangAPI.BindFeatureText(tLbl, title)

    local sLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -110, 0, 14),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = GeoLangAPI.TranslateFeatureText(subtitle),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(sLbl, false, Theme.TextSecondary)
    GeoLangAPI.BindFeatureText(sLbl, subtitle)

    local actionBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 88, 0, 28),
        Position = UDim2.new(1, -100, 0.5, -14),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = btnLabel,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, card)
    Utils.AddCorner(actionBtn, 7)
    Utils.RegisterAccent(actionBtn, "BackgroundColor3")

    actionBtn.MouseButton1Click:Connect(function()
        if callback then
            SafeEngine.Run(title, callback)
        end
    end)

    return actionBtn
end

function Components.AddChipSelector(parent, title, options, defaultVal, order, callback)
    local selected = defaultVal

    local card = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.26,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 14,
    }, parent)
    Utils.AddCorner(card, 9)
    Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

    Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, card)

    Utils.Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, card)

    local titleLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = GeoLangAPI.TranslateFeatureText(title),
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 15,
    }, card)
    Utils.RegisterText(titleLbl, true, Theme.TextPrimary)
    GeoLangAPI.BindFeatureText(titleLbl, title)

    local grid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        ZIndex = 15,
    }, card)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.315, 0, 0, 26),
        CellPadding = UDim2.new(0.025, 0, 0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local chipButtons = {}

    local function refreshChips()
        for val, btn in pairs(chipButtons) do
            if btn and btn.Parent then
                local isAct = (val == selected)
                btn.BackgroundColor3 = isAct and Theme.Accent or Theme.BgControl
                btn.BackgroundTransparency = isAct and 0.05 or 0.2
            end
        end
    end

    table.insert(State.AccentCallbacks, function()
        refreshChips()
    end)

    for idx, opt in ipairs(options) do
        local labelText = type(opt) == "table" and opt.Label or tostring(opt)
        local optVal = type(opt) == "table" and opt.Value or opt
        local previewFont = type(opt) == "table" and opt.Font or nil
        local swatchColor = type(opt) == "table" and opt.Color or nil

        local chip = Utils.Create("TextButton", {
            BackgroundColor3 = (optVal == selected) and Theme.Accent or Theme.BgControl,
            BackgroundTransparency = (optVal == selected) and 0.05 or 0.2,
            Font = previewFont or Theme.FontBold,
            Text = labelText,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 16,
        }, grid)
        Utils.AddCorner(chip, 6)

        if swatchColor then
            local dot = Utils.Create("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(0, 6, 0.5, -4),
                BackgroundColor3 = swatchColor,
                BorderSizePixel = 0,
                ZIndex = 17,
            }, chip)
            Utils.AddCorner(dot, 4)
        end

        chipButtons[optVal] = chip

        chip.MouseButton1Click:Connect(function()
            selected = optVal
            refreshChips()
            if callback then
                SafeEngine.Run(title, callback, optVal)
            end
        end)
    end

    return {
        SetSelected = function(v)
            selected = v
            refreshChips()
        end,
        GetSelected = function() return selected end,
    }
end

-- ============================================================================
-- 10. UNIVERSAL PLAYER ESP ENGINE (Team/Enemy/Random + Distance + Health)
-- ============================================================================
do
    ESP.Folder = Utils.Create("Folder", {
        Name = AntiDetect.GetStealthName("PlayerESPFolder", "BSS_ESP_Folder"),
        Archivable = false,
    }, UI.ScreenGui)

    function ESP.GetRandomPlayerColor(plr)
        if not ESP.RandomColorMap[plr.UserId] then
            local hue = ((plr.UserId * 137.508) % 360) / 360
            ESP.RandomColorMap[plr.UserId] = Color3.fromHSV(hue, 0.85, 1)
        end
        return ESP.RandomColorMap[plr.UserId]
    end

    function ESP.ClassifyRelation(plr)
        local hasTeams = (#Teams:GetTeams() > 0) and (LocalPlayer.Team ~= nil) and (plr.Team ~= nil)
        if hasTeams then
            if plr.Team == LocalPlayer.Team then
                return "Ally"
            else
                return "Enemy"
            end
        end
        return "Random"
    end

    function ESP.RemovePlayer(plr)
        local entry = ESP.Entries[plr]
        if entry then
            if entry.Highlight then entry.Highlight:Destroy() end
            if entry.Billboard then entry.Billboard:Destroy() end
            ESP.Entries[plr] = nil
        end
    end

    function ESP.ClearAll()
        for plr, _ in pairs(ESP.Entries) do
            ESP.RemovePlayer(plr)
        end
        if ESP.Folder then
            ESP.Folder:ClearAllChildren()
        end
    end

    function ESP.EnsurePlayer(plr)
        if plr == LocalPlayer then return nil end
        local entry = ESP.Entries[plr]
        if not entry then
            local hl = Utils.Create("Highlight", {
                Name = "HL_" .. plr.Name,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillTransparency = 0.52,
                OutlineTransparency = 0.08,
                Enabled = false,
            }, ESP.Folder)

            local bb = Utils.Create("BillboardGui", {
                Name = "BB_" .. plr.Name,
                Size = UDim2.new(0, 230, 0, 62),
                StudsOffset = Vector3.new(0, 3.3, 0),
                AlwaysOnTop = true,
                MaxDistance = math.huge,
                ResetOnSpawn = false,
                Enabled = false,
            }, ESP.Folder)

            local bgBox = Utils.Create("Frame", {
                Size = UDim2.new(0, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.XY,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = ESP.FontBgColor,
                BackgroundTransparency = ESP.FontBgTransparency,
                BorderSizePixel = 0,
            }, bb)
            Utils.AddCorner(bgBox, 6)
            Utils.Create("UIPadding", {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
            }, bgBox)
            Utils.Create("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, bgBox)

            local nameLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = ESP.Font,
                Text = plr.DisplayName,
                TextColor3 = ESP.FontColor,
                TextStrokeTransparency = 0.45,
                TextSize = 12,
                LayoutOrder = 1,
            }, bgBox)

            local distLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 13),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = ESP.Font,
                Text = "Jarak: 0 m",
                TextColor3 = ESP.DistanceColor,
                TextStrokeTransparency = 0.45,
                TextSize = 11,
                LayoutOrder = 2,
            }, bgBox)

            local hpLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(0, 0, 0, 13),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = ESP.Font,
                Text = "Darah: 100/100",
                TextColor3 = ESP.HealthColor,
                TextStrokeTransparency = 0.45,
                TextSize = 11,
                LayoutOrder = 3,
            }, bgBox)

            entry = {
                Highlight = hl,
                Billboard = bb,
                BgBox = bgBox,
                NameLbl = nameLbl,
                DistLbl = distLbl,
                HpLbl = hpLbl,
            }
            ESP.Entries[plr] = entry
        end
        return entry
    end

    function ESP.UpdateAll()
        if not ESP.Enabled then
            for _, entry in pairs(ESP.Entries) do
                entry.Highlight.Enabled = false
                entry.Billboard.Enabled = false
            end
            return
        end

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local entry = ESP.EnsurePlayer(plr)
                local char, hum, root = Utils.GetCharacter(plr)
                local head = char and (char:FindFirstChild("Head") or root)

                if char and root and head and entry then
                    local rel = ESP.ClassifyRelation(plr)
                    local shouldShow = true

                    if ESP.Mode == "Enemy" and rel == "Ally" then
                        shouldShow = false
                    elseif ESP.Mode == "Ally" and rel ~= "Ally" then
                        shouldShow = false
                    end

                    local originPos = myRoot and myRoot.Position or camPos
                    local distStuds = (root.Position - originPos).Magnitude
                    if distStuds > ESP.MaxDistance then
                        shouldShow = false
                    end

                    if shouldShow then
                        local mainColor = ESP.HighlightColor
                        local tagText = "[PLAYER]"
                        if ESP.Mode == "Random" or rel == "Random" then
                            mainColor = (ESP.Mode == "Random") and ESP.GetRandomPlayerColor(plr) or ESP.HighlightColor
                            tagText = "[PLAYER]"
                        elseif rel == "Ally" then
                            mainColor = ESP.AllyColor
                            tagText = "[TEMAN]"
                        elseif rel == "Enemy" then
                            mainColor = ESP.EnemyColor
                            tagText = "[MUSUH]"
                        end

                        entry.Highlight.Adornee = char
                        entry.Highlight.FillColor = mainColor
                        entry.Highlight.OutlineColor = mainColor:Lerp(Color3.new(1, 1, 1), 0.35)
                        entry.Highlight.FillTransparency = 0.52
                        entry.Highlight.OutlineTransparency = 0.08
                        entry.Highlight.Enabled = ESP.ShowAvatar

                        entry.Billboard.Adornee = head
                        entry.Billboard.Enabled = true

                        entry.BgBox.BackgroundColor3 = ESP.FontBgColor
                        entry.BgBox.BackgroundTransparency = ESP.FontBgTransparency

                        local resolvedNameColor = ESP.FontColor
                        if ESP.FontAutoContrast then
                            resolvedNameColor = Utils.GetContrastTextColor(ESP.FontBgColor):Lerp(mainColor, 0.35)
                        end

                        entry.NameLbl.Font = ESP.Font
                        entry.NameLbl.TextColor3 = resolvedNameColor
                        entry.NameLbl.Text = string.format("%s %s", tagText, plr.DisplayName)

                        entry.DistLbl.Visible = ESP.ShowDistance
                        entry.DistLbl.Font = ESP.Font
                        entry.DistLbl.TextColor3 = ESP.DistanceColor
                        entry.DistLbl.Text = string.format("Jarak: %.0f m", distStuds)

                        if ESP.ShowHealth and hum and hum.MaxHealth > 0 then
                            entry.HpLbl.Visible = true
                            entry.HpLbl.Font = ESP.Font
                            entry.HpLbl.TextColor3 = ESP.HealthColor
                            entry.HpLbl.Text = string.format("Darah: %.0f / %.0f", math.max(0, hum.Health), hum.MaxHealth)
                        else
                            entry.HpLbl.Visible = false
                        end
                    else
                        entry.Highlight.Enabled = false
                        entry.Billboard.Enabled = false
                    end
                elseif entry then
                    entry.Highlight.Enabled = false
                    entry.Billboard.Enabled = false
                end
            end
        end
    end
end

-- ============================================================================
-- 11. UNIVERSAL ITEM ESP & GENERATOR ESP (Unlimited Distance, Map-Adaptive)
-- ============================================================================
do
    ItemESP.Folder = Utils.Create("Folder", { Name = AntiDetect.GetStealthName("ItemESPFolder", "BSS_ItemESP_Folder"), Archivable = false }, UI.ScreenGui)
    GeneratorESP.Folder = Utils.Create("Folder", { Name = AntiDetect.GetStealthName("GenESPFolder", "BSS_GenESP_Folder"), Archivable = false }, UI.ScreenGui)

    local function isPlayerDescendant(inst)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and inst:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local function getAdorneePart(obj)
        if not obj or not obj.Parent then return nil end
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") then
            return obj.PrimaryPart or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        if obj:IsA("Tool") then
            return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function isGeneratorObject(inst)
        local n = string.lower(inst.Name)
        if string.find(n, "generator", 1, true)
            or string.find(n, "reactor", 1, true)
            or string.find(n, "repairmachine", 1, true)
            or string.find(n, "powerbox", 1, true)
            or n == "gen"
            or string.match(n, "^gen[%d_%-]")
            or string.match(n, "[%d_%-]gen$") then
            return true
        end
        local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            local pText = string.lower((prompt.ActionText or "") .. " " .. (prompt.ObjectText or ""))
            if string.find(pText, "generator", 1, true)
                or ((string.find(pText, "repair", 1, true) or string.find(pText, "perbaiki", 1, true))
                    and (string.find(pText, "gen", 1, true) or string.find(pText, "mesin", 1, true) or string.find(pText, "power", 1, true) or string.find(pText, "listrik", 1, true))) then
                return true
            end
        end
        return false
    end

    local function collectGeneratorStatusValues(genObj, entry)
        local vals = {}
        for _, desc in ipairs(genObj:GetDescendants()) do
            local k = string.lower(desc.Name)
            if desc:IsA("BoolValue") then
                if string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")
                    or string.find(k, "repairing") or string.find(k, "working") or string.find(k, "inuse") then
                    table.insert(vals, desc)
                end
            elseif desc:IsA("NumberValue") or desc:IsA("IntValue") then
                if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                    table.insert(vals, desc)
                end
            end
        end
        entry.StatusValues = vals
    end

    local function getGeneratorStatus(genObj, entry)
        local progressPct = nil
        local isCompleted = false
        local isBeingWorked = false

        pcall(function()
            for attrName, attrVal in pairs(genObj:GetAttributes()) do
                local k = string.lower(attrName)
                if type(attrVal) == "boolean" then
                    if (string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")) and attrVal == true then
                        isCompleted = true
                    elseif (string.find(k, "repairing") or string.find(k, "active") or string.find(k, "working") or string.find(k, "inuse")) and attrVal == true then
                        isBeingWorked = true
                    end
                elseif type(attrVal) == "number" then
                    if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                        local maxAttr = genObj:GetAttribute("Max" .. attrName) or genObj:GetAttribute("MaxProgress") or 100
                        if attrVal <= 1 and maxAttr == 100 and attrVal > 0 then
                            progressPct = math.floor(attrVal * 100 + 0.5)
                        else
                            progressPct = math.floor((attrVal / math.max(1, maxAttr)) * 100 + 0.5)
                        end
                    end
                end
            end
        end)

        if entry and entry.StatusValues then
            for _, desc in ipairs(entry.StatusValues) do
                if desc and desc.Parent then
                    local k = string.lower(desc.Name)
                    if desc:IsA("BoolValue") then
                        if (string.find(k, "complete") or string.find(k, "fixed") or string.find(k, "done") or string.find(k, "repaired")) and desc.Value == true then
                            isCompleted = true
                        elseif (string.find(k, "repairing") or string.find(k, "working") or string.find(k, "inuse")) and desc.Value == true then
                            isBeingWorked = true
                        end
                    elseif (desc:IsA("NumberValue") or desc:IsA("IntValue")) then
                        if string.find(k, "progress") or string.find(k, "percent") or string.find(k, "charge") or string.find(k, "repair") or string.find(k, "power") then
                            local maxObj = desc.Parent and (desc.Parent:FindFirstChild("Max" .. desc.Name) or desc.Parent:FindFirstChild("MaxProgress"))
                            local maxV = (maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) and maxObj.Value > 0) and maxObj.Value or 100
                            if desc.Value <= 1 and maxV == 100 and desc.Value > 0 then
                                progressPct = math.floor(desc.Value * 100 + 0.5)
                            else
                                progressPct = math.floor((desc.Value / maxV) * 100 + 0.5)
                            end
                        end
                    end
                end
            end
        end

        local part = (entry and entry.Part) or getAdorneePart(genObj)
        local workerName = nil
        if part and not isCompleted then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local _, _, pRoot = Utils.GetCharacter(plr)
                    if pRoot and (pRoot.Position - part.Position).Magnitude <= 11 then
                        workerName = plr.DisplayName
                        isBeingWorked = true
                        break
                    end
                end
            end
        end

        if isCompleted or (progressPct and progressPct >= 100) then
            return "Status: Selesai Diproses (100%)"
        elseif progressPct and progressPct > 0 then
            if workerName then
                return string.format("Status: Diproses %s (%d%%)", workerName, math.clamp(progressPct, 0, 100))
            end
            return string.format("Status: Sudah Diproses (%d%%)", math.clamp(progressPct, 0, 100))
        elseif isBeingWorked and workerName then
            return string.format("Status: Sedang Diproses (%s)", workerName)
        else
            return "Status: Belum Diproses (0%)"
        end
    end

    local ignoreKeywords = { "door", "pintu", "seat", "chair", "kur", "elevator", "lift", "gate", "switch", "button" }
    local candidatesInitialized = false

    local function isItemCandidate(inst)
        if inst:IsA("Tool") then
            if Players:GetPlayerFromCharacter(inst.Parent) then
                return false
            end
            return true
        elseif (inst:IsA("Model") or inst:IsA("BasePart")) then
            if inst:IsA("BasePart") and inst.Parent and inst.Parent:IsA("Model") and ItemESP.Candidates[inst.Parent] then
                return false
            end

            local lowerName = string.lower(inst.Name)
            for _, ikw in ipairs(ignoreKeywords) do
                if string.find(lowerName, ikw, 1, true) then
                    return false
                end
            end

            local prompt = inst:IsA("Model") and inst:FindFirstChildWhichIsA("ProximityPrompt", true) or inst:FindFirstChildWhichIsA("ProximityPrompt")
            local clickDet = inst:IsA("Model") and inst:FindFirstChildWhichIsA("ClickDetector", true) or inst:FindFirstChildWhichIsA("ClickDetector")
            local parentName = inst.Parent and string.lower(inst.Parent.Name) or ""
            local inItemFolder = string.find(parentName, "item")
                or string.find(parentName, "drop")
                or string.find(parentName, "loot")
                or string.find(parentName, "pickup")
                or string.find(parentName, "collect")
                or string.find(parentName, "barang")
                or string.find(parentName, "tool")

            if prompt or clickDet or inItemFolder then
                return true
            end
        end
        return false
    end

    local function evaluateCandidate(inst)
        if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then
            ItemESP.Candidates[inst] = nil
            GeneratorESP.Candidates[inst] = nil
            return
        end

        if not (inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("BasePart")) then
            return
        end

        if (inst:IsA("Model") or inst:IsA("BasePart")) and isGeneratorObject(inst) then
            local hasGenAncestor = false
            local anc = inst.Parent
            while anc and anc ~= workspace do
                if (anc:IsA("Model") or anc:IsA("Folder")) and isGeneratorObject(anc) then
                    hasGenAncestor = true
                    break
                end
                anc = anc.Parent
            end

            if not hasGenAncestor then
                GeneratorESP.Candidates[inst] = true
            else
                GeneratorESP.Candidates[inst] = nil
            end
            ItemESP.Candidates[inst] = nil
            return
        else
            GeneratorESP.Candidates[inst] = nil
        end

        if isItemCandidate(inst) then
            ItemESP.Candidates[inst] = true
        else
            ItemESP.Candidates[inst] = nil
        end
    end

    local function ensureCandidatesInitialized()
        if candidatesInitialized then return end
        candidatesInitialized = true

        task.spawn(function()
            local descendants = workspace:GetDescendants()
            for i, inst in ipairs(descendants) do
                if not ItemESP.Enabled and not GeneratorESP.Enabled then
                    candidatesInitialized = false
                    return
                end
                evaluateCandidate(inst)
                if i % 1500 == 0 then
                    RunService.Heartbeat:Wait()
                end
            end
        end)

        Utils.Track(workspace.DescendantAdded:Connect(function(desc)
            evaluateCandidate(desc)
            local parent = desc.Parent
            if parent and parent ~= workspace then
                evaluateCandidate(parent)
                local grandParent = parent.Parent
                if grandParent and grandParent ~= workspace and (desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector")) then
                    evaluateCandidate(grandParent)
                end
            end
        end))

        Utils.Track(workspace.DescendantRemoving:Connect(function(desc)
            ItemESP.Candidates[desc] = nil
            GeneratorESP.Candidates[desc] = nil

            local itemEntry = ItemESP.Entries[desc]
            if itemEntry then
                if itemEntry.Billboard then itemEntry.Billboard:Destroy() end
                ItemESP.Entries[desc] = nil
            end

            local genEntry = GeneratorESP.Entries[desc]
            if genEntry then
                if genEntry.Highlight then genEntry.Highlight:Destroy() end
                if genEntry.Billboard then genEntry.Billboard:Destroy() end
                if genEntry.DescConn then genEntry.DescConn:Disconnect() end
                GeneratorESP.Entries[desc] = nil
            end
        end))
    end

    function ItemESP.ClearAll()
        table.clear(ItemESP.Entries)
        if ItemESP.Folder then
            ItemESP.Folder:ClearAllChildren()
        end
    end

    function GeneratorESP.ClearAll()
        for _, entry in pairs(GeneratorESP.Entries) do
            if entry.DescConn then
                entry.DescConn:Disconnect()
            end
        end
        table.clear(GeneratorESP.Entries)
        if GeneratorESP.Folder then
            GeneratorESP.Folder:ClearAllChildren()
        end
    end

    function ItemESP.ScanAndRender()
        if not ItemESP.Enabled then
            if next(ItemESP.Entries) ~= nil then
                ItemESP.ClearAll()
            end
            return
        end

        ensureCandidatesInitialized()

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero
        local originPos = myRoot and myRoot.Position or camPos

        local activeSet = {}

        for inst, _ in pairs(ItemESP.Candidates) do
            if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then
                ItemESP.Candidates[inst] = nil
            elseif not isPlayerDescendant(inst) then
                local part = getAdorneePart(inst)
                if part and part:IsDescendantOf(workspace) then
                    activeSet[inst] = true
                    local entry = ItemESP.Entries[inst]
                    if not entry then
                        local bb = Utils.Create("BillboardGui", {
                            Name = "ItemBB",
                            Size = UDim2.new(0, 210, 0, 38),
                            StudsOffset = Vector3.new(0, 1.8, 0),
                            AlwaysOnTop = true,
                            MaxDistance = math.huge,
                            ResetOnSpawn = false,
                        }, ItemESP.Folder)

                        local lbl = Utils.Create("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Font = ItemESP.Font,
                            Text = inst.Name,
                            TextColor3 = ItemESP.Color,
                            TextStrokeColor3 = Color3.fromRGB(10, 10, 14),
                            TextStrokeTransparency = 0.25,
                            TextSize = 12,
                        }, bb)

                        entry = { Billboard = bb, Label = lbl, Part = part }
                        ItemESP.Entries[inst] = entry
                    end

                    local dist = (part.Position - originPos).Magnitude
                    entry.Billboard.Adornee = part
                    entry.Billboard.Enabled = true
                    entry.Label.Font = ItemESP.Font
                    entry.Label.TextColor3 = ItemESP.Color
                    entry.Label.BackgroundTransparency = 1
                    entry.Label.Text = string.format("[BARANG] %s\nJarak: %.0f m", inst.Name, dist)
                end
            end
        end

        for inst, entry in pairs(ItemESP.Entries) do
            if not activeSet[inst] or not inst.Parent then
                if entry.Billboard then entry.Billboard:Destroy() end
                ItemESP.Entries[inst] = nil
            end
        end
    end

    function GeneratorESP.ScanAndRender()
        if not GeneratorESP.Enabled then
            if next(GeneratorESP.Entries) ~= nil then
                GeneratorESP.ClearAll()
            end
            return
        end

        ensureCandidatesInitialized()

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero
        local originPos = myRoot and myRoot.Position or camPos

        local activeSet = {}

        for inst, _ in pairs(GeneratorESP.Candidates) do
            if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then
                GeneratorESP.Candidates[inst] = nil
            elseif not isPlayerDescendant(inst) then
                local part = getAdorneePart(inst)
                if part and part:IsDescendantOf(workspace) then
                    activeSet[inst] = true
                    local entry = GeneratorESP.Entries[inst]
                    if not entry then
                        local hl = Utils.Create("Highlight", {
                            Name = "GenHL",
                            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                            FillTransparency = 0.65,
                            OutlineTransparency = 0.1,
                        }, GeneratorESP.Folder)

                        local bb = Utils.Create("BillboardGui", {
                            Name = "GenBB",
                            Size = UDim2.new(0, 240, 0, 54),
                            StudsOffset = Vector3.new(0, 3.0, 0),
                            AlwaysOnTop = true,
                            MaxDistance = math.huge,
                            ResetOnSpawn = false,
                        }, GeneratorESP.Folder)

                        local lbl = Utils.Create("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Font = GeneratorESP.Font,
                            Text = inst.Name,
                            TextColor3 = GeneratorESP.Color,
                            TextStrokeColor3 = Color3.fromRGB(10, 10, 14),
                            TextStrokeTransparency = 0.2,
                            TextSize = 12,
                        }, bb)

                        entry = { Highlight = hl, Billboard = bb, Label = lbl, Part = part, StatusValues = {} }
                        collectGeneratorStatusValues(inst, entry)
                        entry.DescConn = Utils.Track(inst.DescendantAdded:Connect(function(d)
                            if d:IsA("BoolValue") or d:IsA("NumberValue") or d:IsA("IntValue") then
                                table.insert(entry.StatusValues, d)
                            end
                        end))
                        GeneratorESP.Entries[inst] = entry
                    end

                    local dist = (part.Position - originPos).Magnitude
                    local statusText = getGeneratorStatus(inst, entry)

                    entry.Highlight.Adornee = inst
                    entry.Highlight.FillColor = GeneratorESP.Color
                    entry.Highlight.OutlineColor = GeneratorESP.Color
                    entry.Highlight.Enabled = true

                    entry.Billboard.Adornee = part
                    entry.Billboard.Enabled = true
                    entry.Label.Font = GeneratorESP.Font
                    entry.Label.TextColor3 = GeneratorESP.Color
                    entry.Label.Text = string.format("⚡ %s\nJarak: %.0f m\n%s", inst.Name, dist, statusText)
                end
            end
        end

        for inst, entry in pairs(GeneratorESP.Entries) do
            if not activeSet[inst] or not inst.Parent then
                if entry.Highlight then entry.Highlight:Destroy() end
                if entry.Billboard then entry.Billboard:Destroy() end
                if entry.DescConn then entry.DescConn:Disconnect() end
                GeneratorESP.Entries[inst] = nil
            end
        end
    end
end

-- ============================================================================
-- 12. AUTO AIMBOT, RGB WEAPON LASER & AUTO PARRY ENGINE
-- ============================================================================
do
    Combat.FOVCircle = Utils.Create("Frame", {
        Name = AntiDetect.GetStealthName("AimFOVCircle", "BSS_AimFOV"),
        Archivable = false,
        Size = UDim2.new(0, Combat.FOVRadius * 2, 0, Combat.FOVRadius * 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
    }, UI.ScreenGui)
    Utils.AddCorner(Combat.FOVCircle, 999)
    local fovStroke = Utils.AddStroke(Combat.FOVCircle, Theme.Accent, 1.3, 0.35)
    Utils.RegisterAccent(fovStroke, "Color")

    function Combat.GetEquippedRangedWeapon()
        local char = Utils.GetCharacter(LocalPlayer)
        if not char then return nil, false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return nil, false end

        for _, desc in ipairs(tool:GetDescendants()) do
            local dName = string.lower(desc.Name)
            if dName == "muzzle" or dName == "barrel" or dName == "firepoint" or dName == "gunscript" or dName == "ammo" or dName == "bullet" then
                return tool, true
            end
        end

        local nameLower = string.lower(tool.Name)
        local gunKeywords = {
            "gun", "pistol", "rifle", "sniper", "ak", "m4", "m16", "shotgun",
            "smg", "bow", "crossbow", "blaster", "laser", "revolver", "glock", "deagle",
            "uzi", "carbine", "launcher", "mp5", "scar", "awp", "raygun",
            "tec", "mac", "cannon", "ray", "plasma", "magnum", "beretta"
        }
        for _, kw in ipairs(gunKeywords) do
            if string.match(nameLower, "%f[%a]" .. kw .. "%f[%A]") then
                return tool, true
            end
        end

        return tool, false
    end

    function Combat.HideLaser()
        if Combat.LaserPart then
            Combat.LaserPart.Transparency = 1
        end
    end

    function Combat.UpdateLaser(startPos, endPos)
        if not Combat.LaserPart or not Combat.LaserPart.Parent then
            Combat.LaserPart = Utils.Create("Part", {
                Name = AntiDetect.GetStealthName("AimLaserPart", "BSS_RGB_AimLaser"),
                Archivable = false,
                Anchored = true,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                CastShadow = false,
                Material = Enum.Material.Neon,
                Transparency = 0.15,
                Size = Vector3.new(0.08, 0.08, 1),
            }, AntiDetect.GetWorldHelperParent())
        end

        local dist = (endPos - startPos).Magnitude
        if dist < 0.2 then
            Combat.LaserPart.Transparency = 1
            return
        end

        local hue = (os.clock() * 0.65) % 1
        Combat.LaserPart.Color = Color3.fromHSV(hue, 1, 1)
        Combat.LaserPart.Transparency = 0.12
        Combat.LaserPart.Size = Vector3.new(0.08, 0.08, dist)
        Combat.LaserPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -dist / 2)
    end

    function Combat.FindBestTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil, nil end

        local viewportCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local bestTarget = nil
        local bestAimPart = nil
        local bestScore = Combat.FOVRadius

        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isAlly = (#Teams:GetTeams() > 0 and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
                if not (Combat.TeamCheck and isAlly) then
                    local char, hum, root = Utils.GetCharacter(plr)
                    if char and hum and hum.Health > 0 and root then
                        if not char:FindFirstChildOfClass("ForceField") then
                            local partToAim = root
                            if Combat.AimPart == "Head" then
                                partToAim = char:FindFirstChild("Head") or root
                            elseif Combat.AimPart == "Closest" then
                                local head = char:FindFirstChild("Head")
                                if head then
                                    local hPos = cam:WorldToViewportPoint(head.Position)
                                    local rPos = cam:WorldToViewportPoint(root.Position)
                                    local dH = (Vector2.new(hPos.X, hPos.Y) - viewportCenter).Magnitude
                                    local dR = (Vector2.new(rPos.X, rPos.Y) - viewportCenter).Magnitude
                                    partToAim = (dH < dR) and head or root
                                end
                            end

                            local worldDist = myRoot and (partToAim.Position - myRoot.Position).Magnitude or 0
                            if worldDist <= Combat.MaxRange then
                                local screenPos, onScreen = cam:WorldToViewportPoint(partToAim.Position)
                                if onScreen and screenPos.Z > 0 then
                                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                                    if screenDist <= bestScore then
                                        bestScore = screenDist
                                        bestTarget = plr
                                        bestAimPart = partToAim
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return bestTarget, bestAimPart
    end

    function Combat.TriggerParryAction(attackerName)
        local now = os.clock()
        if (now - Combat.LastParryTime) < Combat.ParryCooldown then
            return
        end
        Combat.LastParryTime = now

        local myChar, myHum = Utils.GetCharacter(LocalPlayer)
        if not myChar or not myHum or myHum.Health <= 0 then return end

        local activeTool = myChar:FindFirstChildOfClass("Tool")
        if not activeTool then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then
                        local tn = string.lower(t.Name)
                        if string.find(tn, "parry") or string.find(tn, "block") or string.find(tn, "shield") or string.find(tn, "sword") or string.find(tn, "blade") or string.find(tn, "bat") then
                            myHum:EquipTool(t)
                            activeTool = t
                            break
                        end
                    end
                end
            end
        end

        if activeTool then
            pcall(function() activeTool:Activate() end)
        end

        if VirtualInputManager then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.delay(0.06, function()
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end)
                end)
            end)
        end

        Utils.Notify("Auto Parry!", "Menangkis serangan dari " .. tostring(attackerName), Theme.Success)
    end

    function Combat.StepAutoParry()
        if not Combat.AutoParryEnabled then return end
        local _, myHum, myRoot = Utils.GetCharacter(LocalPlayer)
        if not myHum or not myRoot or myHum.Health <= 0 then return end

        local attackKeywords = {
            "slash", "punch", "attack", "strike", "jab", "kick",
            "heavy", "bash", "slam", "uppercut", "combo", "lunge", "chop", "melee", "stab"
        }

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isAlly = (#Teams:GetTeams() > 0 and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
                if not (Combat.TeamCheck and isAlly) then
                    local char, hum, root = Utils.GetCharacter(plr)
                    if char and hum and hum.Health > 0 and root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist <= Combat.ParryRange then
                            local animator = hum:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                    local animName = string.lower((track.Name or "") .. " " .. (track.Animation and track.Animation.Name or ""))
                                    for _, kw in ipairs(attackKeywords) do
                                        if string.find(animName, kw, 1, true) then
                                            Combat.TriggerParryAction(plr.DisplayName)
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- 13. INTERACTIVE REPLICATED CARRY ENGINE (Terlihat di Device Pemain Lain)
-- ============================================================================
do
    local carryOffsets = {
        Depan = CFrame.new(0, 0.25, -1.75) * CFrame.Angles(0, math.rad(90), math.rad(15)),
        Belakang = CFrame.new(0, 0.75, 1.35) * CFrame.Angles(math.rad(-10), 0, 0),
        Pundak = CFrame.new(1.15, 1.45, -0.15) * CFrame.Angles(math.rad(85), 0, math.rad(90)),
        Seret = CFrame.new(0, -2.15, 2.8) * CFrame.Angles(math.rad(82), math.rad(180), 0),
        Kepala = CFrame.new(0, 3.1, 0),
        Melayang = CFrame.new(2.2, 1.1, -0.5) * CFrame.Angles(0, math.rad(-25), 0),
    }

    local carryAnimIds = {
        R15 = "rbxassetid://3333474484",
        R6 = "rbxassetid://182435998",
    }

    function Carry.PlayReplicatedPose()
        local _, hum = Utils.GetCharacter(LocalPlayer)
        if not hum then return end
        local animator = Utils.GetAnimator(hum)
        if not animator then return end

        if Carry.AnimTrack then
            pcall(function() Carry.AnimTrack:Stop(0.1) end)
            Carry.AnimTrack = nil
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = (hum.RigType == Enum.HumanoidRigType.R6) and carryAnimIds.R6 or carryAnimIds.R15
        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if ok and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play(0.15)
            Carry.AnimTrack = track
        end
    end

    function Carry.TryNativeMapCarry(targetPlr)
        local tChar, _, tRoot = Utils.GetCharacter(targetPlr)
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        if not tChar or not tRoot or not myRoot then return false end

        local carryWords = { "carry", "gendong", "angkat", "grab", "pick", "piggy", "hold" }
        for _, desc in ipairs(tChar:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local txt = string.lower((desc.ActionText or "") .. " " .. (desc.ObjectText or "") .. " " .. desc.Name)
                for _, kw in ipairs(carryWords) do
                    if string.find(txt, kw, 1, true) then
                        Utils.SafeTeleport(tRoot.CFrame * CFrame.new(0, 0, 2))
                        task.spawn(function()
                            task.wait(0.12)
                            if typeof(fireproximityprompt) == "function" and desc and desc.Parent then
                                pcall(fireproximityprompt, desc)
                            end
                        end)
                        return true
                    end
                end
            end
        end
        return false
    end

    function Carry.Start()
        if not Carry.TargetPlayer then
            Utils.Notify("Pilih Pemain", "Pilih teman/player terlebih dahulu sebelum menekan Carry!", Theme.Warning)
            Carry.Enabled = false
            return false
        end

        Carry.NativePromptTriggered = false
        Carry.NativePromptTriggered = Carry.TryNativeMapCarry(Carry.TargetPlayer)
        Carry.Enabled = true
        Carry.PlayReplicatedPose()

        local modeInfo = Carry.NativePromptTriggered and "Mode Server/Map" or "Mode Visual Lokal"
        Utils.Notify(
            "Carry Aktif",
            "Meng-carry " .. Carry.TargetPlayer.DisplayName .. " (Gaya: " .. Carry.Style .. " | " .. modeInfo .. ")",
            Theme.Success
        )
        return true
    end

    function Carry.Stop()
        Carry.Enabled = false
        Carry.NativePromptTriggered = false

        if Carry.AnimTrack then
            pcall(function() Carry.AnimTrack:Stop(0.15) end)
            Carry.AnimTrack = nil
        end

        if Carry.TargetPlayer then
            local _, tHum = Utils.GetCharacter(Carry.TargetPlayer)
            if tHum then
                tHum.PlatformStand = false
                if tHum:GetState() == Enum.HumanoidStateType.Physics then
                    tHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end

    function Carry.Step()
        if not Carry.Enabled or not Carry.TargetPlayer then return end
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        local tChar, tHum, tRoot = Utils.GetCharacter(Carry.TargetPlayer)

        if not myRoot or not tChar or not tRoot or not tHum or tHum.Health <= 0 then
            return
        end

        if Carry.NativePromptTriggered then
            return
        end

        local offset = carryOffsets[Carry.Style] or carryOffsets.Depan
        tHum.PlatformStand = true
        tRoot.AssemblyLinearVelocity = Vector3.zero
        tRoot.AssemblyAngularVelocity = Vector3.zero
        tRoot.CFrame = myRoot.CFrame * offset
    end
end

-- ============================================================================
-- 14. INTERACTIVE REPLICATED R6 & R15 DANCE / EMOTE STUDIO (Terlihat Pemain Lain)
-- ============================================================================
do
    Emotes.Catalog = {
        { Id = "Dance1", Label = "Groove Dance 1", R15 = "rbxassetid://507771019", R6 = "rbxassetid://182435998" },
        { Id = "Dance2", Label = "Party Dance 2", R15 = "rbxassetid://507776043", R6 = "rbxassetid://182436842" },
        { Id = "Dance3", Label = "Hype Dance 3", R15 = "rbxassetid://507777268", R6 = "rbxassetid://182436935" },
        { Id = "Stadium", Label = "Stadium Wave", R15 = "rbxassetid://3338010159", R6 = "rbxassetid://129423030" },
        { Id = "Tilt", Label = "Head Tilt Vibe", R15 = "rbxassetid://3334538554", R6 = "rbxassetid://128777973" },
        { Id = "Salute", Label = "Respect Salute", R15 = "rbxassetid://3333474484", R6 = "rbxassetid://128777973" },
        { Id = "Shrug", Label = "Chill Shrug", R15 = "rbxassetid://3334392772", R6 = "rbxassetid://129423131" },
        { Id = "Applause", Label = "Victory Claps", R15 = "rbxassetid://5915693819", R6 = "rbxassetid://129423030" },
        { Id = "Cheer", Label = "Happy Cheer", R15 = "rbxassetid://507770677", R6 = "rbxassetid://129423030" },
        { Id = "Laugh", Label = "Big Laugh", R15 = "rbxassetid://507770818", R6 = "rbxassetid://129423131" },
        { Id = "Point", Label = "Look There", R15 = "rbxassetid://507770453", R6 = "rbxassetid://128853357" },
        { Id = "Wave", Label = "Friendly Wave", R15 = "rbxassetid://507770239", R6 = "rbxassetid://128777973" },
    }

    function Emotes.Stop()
        Emotes.Playing = false
        Emotes.CurrentDance = nil
        if Emotes.ActiveTrack then
            pcall(function() Emotes.ActiveTrack:Stop(0.15) end)
            Emotes.ActiveTrack = nil
        end
    end

    function Emotes.PlayAsset(labelName, assetId)
        local char, hum = Utils.GetCharacter(LocalPlayer)
        if not char or not hum then
            Utils.Notify("Emote", "Karakter belum siap.", Theme.Warning)
            return
        end

        local animator = Utils.GetAnimator(hum)
        if not animator then
            Utils.Notify("Emote", "Animator karakter tidak ditemukan.", Theme.Warning)
            return
        end

        Emotes.Stop()

        local cleanId = tostring(assetId)
        if not string.find(cleanId, "rbxassetid://", 1, true) then
            local digits = string.match(cleanId, "%d+")
            if not digits then
                Utils.Notify("ID Tidak Valid", "Masukkan angka Animation ID Roblox yang valid.", Theme.Danger)
                return
            end
            cleanId = "rbxassetid://" .. digits
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = cleanId

        local ok, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)

        if ok and track then
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            track:Play(0.15)
            track:AdjustSpeed(Emotes.Speed)

            Emotes.ActiveTrack = track
            Emotes.Playing = true
            Emotes.CurrentDance = labelName
            Emotes.CurrentId = cleanId
            Utils.Notify("Dance Terkirim ke Server", "Memainkan: " .. labelName .. " (Terlihat pemain lain)", Theme.Success)
        else
            Utils.Notify("Gagal Memuat Dance", "ID animasi tidak didukung di map ini.", Theme.Warning)
        end
    end

    function Emotes.PlayPreset(entry)
        local _, hum = Utils.GetCharacter(LocalPlayer)
        local isR6 = hum and (hum.RigType == Enum.HumanoidRigType.R6)
        local chosenId = isR6 and entry.R6 or entry.R15
        Emotes.PlayAsset(entry.Label, chosenId)
    end
end

-- ============================================================================
-- 15. PROTECTION & SURVIVAL ENGINE (Anti-AFK, Melee Immunity, Disaster Immunity, Hunger & Thirst)
-- ============================================================================
do
    Utils.Track(LocalPlayer.Idled:Connect(function()
        if Protection.AntiAFKEnabled then
            Protection.IdleEventsHandled = Protection.IdleEventsHandled + 1
            pcall(function()
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end
            end)
        end
    end))

    function Protection.RestoreEnemyHitboxes()
        for part, origTouch in pairs(Combat.TouchedPartsCache) do
            if part and part.Parent and part:IsA("BasePart") then
                part.CanTouch = origTouch
            end
        end
        table.clear(Combat.TouchedPartsCache)
        table.clear(Combat.EnemyToolParts)
    end

    local function getCachedToolParts(tool)
        local cached = Combat.EnemyToolParts[tool]
        if not cached then
            cached = {}
            for _, desc in ipairs(tool:GetDescendants()) do
                if desc:IsA("BasePart") then
                    table.insert(cached, desc)
                end
            end
            Combat.EnemyToolParts[tool] = cached
            Utils.Track(tool.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") and Combat.EnemyToolParts[tool] then
                    table.insert(Combat.EnemyToolParts[tool], desc)
                end
            end))
            Utils.Track(tool.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    Combat.EnemyToolParts[tool] = nil
                end
            end))
        end
        return cached
    end

    function Protection.StepMeleeImmunity()
        if not Combat.MeleeImmunity then return end
        local char, hum, root = Utils.GetCharacter(LocalPlayer)
        if not char or not hum or not root then return end

        local badStates = {
            [Enum.HumanoidStateType.Ragdoll] = true,
            [Enum.HumanoidStateType.FallingDown] = true,
            [Enum.HumanoidStateType.Physics] = true,
        }
        if badStates[hum:GetState()] then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if not State.FlyEnabled and not Carry.Enabled and hum.PlatformStand then
            hum.PlatformStand = false
        end

        if not State.FlyEnabled then
            local vel = root.AssemblyLinearVelocity
            local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if horizSpeed > (State.WalkSpeed + 28) or vel.Y > 65 then
                root.AssemblyLinearVelocity = Vector3.new(0, math.min(vel.Y, 65), 0)
            end
            root.AssemblyAngularVelocity = Vector3.zero
        end

        if hum.Health > 0 and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local enemyTool = plr.Character:FindFirstChildOfClass("Tool")
                if enemyTool then
                    local parts = getCachedToolParts(enemyTool)
                    for _, desc in ipairs(parts) do
                        if desc and desc.Parent then
                            if Combat.TouchedPartsCache[desc] == nil then
                                Combat.TouchedPartsCache[desc] = desc.CanTouch
                            end
                            if desc.CanTouch then
                                desc.CanTouch = false
                            end
                        end
                    end
                end
            end
        end
    end

    -- ========================================================================
    -- INTERACTIVE DISASTER & ALL-HAZARD IMMUNITY ENGINE (Kebal Bencana & Apapun)
    -- Melindungi dari bencana alam (meteor, banjir/tsunami, gempa, api, petir,
    -- angin tornado/badai, lava, gas/racun, ledakan, jatuh/void) tanpa mati/dead
    -- ========================================================================
    local hazardKeywords = {
        "meteor", "comet", "asteroid", "lava", "magma", "fire", "flame", "burn", "api",
        "flood", "tsunami", "banjir", "water", "acid", "poison", "toxic", "gas", "racun",
        "quake", "earthquake", "gempa", "rock", "boulder", "debris", "rubble", "falling",
        "lightning", "thunder", "petir", "shock", "electric", "storm", "tornado", "twister",
        "hurricane", "wind", "badai", "angin", "blizzard", "freeze", "ice", "snow", "frost",
        "explosion", "explosive", "bomb", "blast", "mine", "tnt", "ledakan", "hazard",
        "danger", "kill", "death", "dead", "spike", "saw", "crush", "void", "fall", "disaster",
        "bencana", "dmg", "damage", "hurt", "harm", "lethal", "trap", "jebakan"
    }

    local function isHazardPart(part)
        if not part or not part:IsA("BasePart") then return false end
        if Players:GetPlayerFromCharacter(part.Parent) or (part.Parent and Players:GetPlayerFromCharacter(part.Parent.Parent)) then
            return false
        end
        if part == Combat.LaserPart or part == State.SpectateAnchorPart or part.Name == "BSS_RGB_AimLaser" or part.Name == "BSS_RemoteViewAnchor" then
            return false
        end

        local n = string.lower(part.Name)
        for _, kw in ipairs(hazardKeywords) do
            if string.find(n, kw, 1, true) then
                return true, kw
            end
        end

        local parent = part.Parent
        if parent and parent ~= workspace then
            local pn = string.lower(parent.Name)
            for _, kw in ipairs(hazardKeywords) do
                if string.find(pn, kw, 1, true) then
                    return true, kw
                end
            end
        end

        if part:GetAttribute("Damage") or part:GetAttribute("Hazard") or part:GetAttribute("Disaster") or part:GetAttribute("KillBrick") then
            return true, "hazard"
        end

        return false
    end

    local function describeHazardKind(kind)
        if not kind then return "Bahaya Lingkungan / Bencana" end
        if string.find(kind, "meteor") or string.find(kind, "asteroid") or string.find(kind, "comet") then
            return "Hujan Meteor / Asteroid"
        elseif string.find(kind, "flood") or string.find(kind, "tsunami") or string.find(kind, "banjir") or string.find(kind, "water") then
            return "Banjir / Tsunami"
        elseif string.find(kind, "quake") or string.find(kind, "gempa") or string.find(kind, "rock") or string.find(kind, "boulder") or string.find(kind, "debris") then
            return "Gempa Bumi / Reruntuhan"
        elseif string.find(kind, "fire") or string.find(kind, "flame") or string.find(kind, "lava") or string.find(kind, "magma") or string.find(kind, "api") or string.find(kind, "burn") then
            return "Api / Lava / Panas Ekstrem"
        elseif string.find(kind, "lightning") or string.find(kind, "thunder") or string.find(kind, "petir") or string.find(kind, "shock") then
            return "Sambaran Petir / Listrik"
        elseif string.find(kind, "tornado") or string.find(kind, "twister") or string.find(kind, "hurricane") or string.find(kind, "storm") or string.find(kind, "wind") or string.find(kind, "badai") then
            return "Badai / Tornado"
        elseif string.find(kind, "blizzard") or string.find(kind, "ice") or string.find(kind, "snow") or string.find(kind, "frost") or string.find(kind, "freeze") then
            return "Badai Es / Pembekuan"
        elseif string.find(kind, "explosion") or string.find(kind, "bomb") or string.find(kind, "blast") or string.find(kind, "tnt") or string.find(kind, "ledakan") then
            return "Ledakan Bencana"
        elseif string.find(kind, "poison") or string.find(kind, "toxic") or string.find(kind, "gas") or string.find(kind, "acid") or string.find(kind, "racun") then
            return "Gas Beracun / Asam"
        elseif string.find(kind, "void") or string.find(kind, "fall") then
            return "Jatuh / Jurang Void"
        end
        return "Bencana & Bahaya (" .. tostring(kind) .. ")"
    end

    function Protection.AlertDisasterBlocked(kind)
        local now = os.clock()
        local label = describeHazardKind(kind)
        if (now - Combat.LastHazardAlertTime) >= 2.2 or Combat.LastHazardType ~= label then
            Combat.LastHazardAlertTime = now
            Combat.LastHazardType = label
            Utils.Notify("🛡️ Kebal Bencana Aktif", "Menangkis " .. label .. " — Karakter tetap hidup & kebal!", Theme.Success)
        end
    end

    function Protection.RestoreDisasterImmunity()
        for part, origTouch in pairs(Combat.HazardPartsCache) do
            if part and part.Parent and part:IsA("BasePart") then
                part.CanTouch = origTouch
            end
        end
        table.clear(Combat.HazardPartsCache)
        local char = Utils.GetCharacter(LocalPlayer)
        if char then
            local shield = char:FindFirstChild("BSS_DisasterShieldFF")
            if shield then shield:Destroy() end
        end
    end

    function Protection.EnsureDisasterForceField(char)
        if not char or not char.Parent then return end
        local ff = char:FindFirstChild("BSS_DisasterShieldFF")
        if not ff then
            ff = Instance.new("ForceField")
            ff.Name = "BSS_DisasterShieldFF"
            ff.Visible = false
            ff.Parent = char
        end
    end

    function Protection.StepDisasterImmunity()
        if not Combat.DisasterImmunity then return end
        local char, hum, root = Utils.GetCharacter(LocalPlayer)
        if not char or not hum or not root then return end

        Protection.EnsureDisasterForceField(char)

        -- Cegah state mati / ragdoll / jatuh tidak terkendali akibat bencana
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Dead
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Physics then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end

        if hum.Health <= 0 or hum.Health < hum.MaxHealth then
            if hum.MaxHealth <= 0 or hum.MaxHealth ~= hum.MaxHealth then
                hum.MaxHealth = 100
            end
            hum.Health = hum.MaxHealth
        end

        if not State.FlyEnabled and not Carry.Enabled and hum.PlatformStand then
            hum.PlatformStand = false
        end

        -- Redam dorongan badai / ledakan / gempa yang melempar karakter secara ekstrem
        if not State.FlyEnabled and not State.IsTeleportLocking then
            local vel = root.AssemblyLinearVelocity
            local horizVel = Vector3.new(vel.X, 0, vel.Z)
            local maxHoriz = math.max(State.WalkSpeed + 32, 48)
            local blownAway = false
            if horizVel.Magnitude > maxHoriz or vel.Y > 85 or vel.Y < -110 then
                blownAway = true
                root.AssemblyLinearVelocity = Vector3.new(
                    math.clamp(vel.X, -maxHoriz, maxHoriz),
                    math.clamp(vel.Y, -45, 55),
                    math.clamp(vel.Z, -maxHoriz, maxHoriz)
                )
            end
            root.AssemblyAngularVelocity = Vector3.zero
            if blownAway then
                Protection.AlertDisasterBlocked("storm")
            end
        end

        -- Deteksi & nonaktifkan CanTouch pada objek bencana/bahaya di sekitar atau menyentuh karakter
        local myPos = root.Position
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = { char }

        local okParts, nearbyParts = pcall(function()
            return workspace:GetPartBoundsInRadius(myPos, 28, overlapParams)
        end)

        if okParts and type(nearbyParts) == "table" then
            for _, part in ipairs(nearbyParts) do
                local isHaz, kind = isHazardPart(part)
                if isHaz then
                    if Combat.HazardPartsCache[part] == nil then
                        Combat.HazardPartsCache[part] = part.CanTouch
                    end
                    if part.CanTouch then
                        part.CanTouch = false
                    end
                    local distToRoot = (part.Position - myPos).Magnitude
                    if distToRoot <= 12 then
                        Protection.AlertDisasterBlocked(kind)
                    end
                end
            end
        end

        -- Penyelamatan otomatis jika terjatuh ke jurang/void atau keluar batas ketinggian bencana
        local fallHeight = workspace.FallenPartsDestroyHeight or -500
        if myPos.Y <= (fallHeight + 35) or myPos.Y < -250 then
            local rescueCF = Combat.LastSafeCFrame
            if not rescueCF then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local _, _, pRoot = Utils.GetCharacter(plr)
                        if pRoot and pRoot.Position.Y > -80 then
                            rescueCF = pRoot.CFrame * CFrame.new(0, 4, 0)
                            break
                        end
                    end
                end
            end
            if not rescueCF then
                rescueCF = CFrame.new(0, 25, 0)
            end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(rescueCF)
            if hum then
                hum.Health = hum.MaxHealth
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            Protection.AlertDisasterBlocked("void")
        elseif not State.IsTeleportLocking and myPos.Y > -60 then
            -- Simpan posisi aman terakhir secara berkala saat berada di permukaan normal
            if not Combat.LastSafePosition or (myPos - Combat.LastSafePosition).Magnitude >= 8 then
                local rayOrigin = myPos + Vector3.new(0, 2, 0)
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { char }
                local rayRes = workspace:Raycast(rayOrigin, Vector3.new(0, -14, 0), rayParams)
                if rayRes and rayRes.Instance and rayRes.Instance.CanCollide then
                    local hazGround = isHazardPart(rayRes.Instance)
                    if not hazGround then
                        Combat.LastSafePosition = myPos
                        Combat.LastSafeCFrame = root.CFrame
                    end
                end
            end
        end
    end

    function Protection.StepMeleeImmunity()
        if not Combat.MeleeImmunity then return end
        local char, hum, root = Utils.GetCharacter(LocalPlayer)
        if not char or not hum or not root then return end

        local badStates = {
            [Enum.HumanoidStateType.Ragdoll] = true,
            [Enum.HumanoidStateType.FallingDown] = true,
            [Enum.HumanoidStateType.Physics] = true,
        }
        if badStates[hum:GetState()] then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if not State.FlyEnabled and not Carry.Enabled and hum.PlatformStand then
            hum.PlatformStand = false
        end

        if not State.FlyEnabled then
            local vel = root.AssemblyLinearVelocity
            local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if horizSpeed > (State.WalkSpeed + 28) or vel.Y > 65 then
                root.AssemblyLinearVelocity = Vector3.new(0, math.min(vel.Y, 65), 0)
            end
            root.AssemblyAngularVelocity = Vector3.zero
        end

        if hum.Health > 0 and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local enemyTool = plr.Character:FindFirstChildOfClass("Tool")
                if enemyTool then
                    local parts = getCachedToolParts(enemyTool)
                    for _, desc in ipairs(parts) do
                        if desc and desc.Parent then
                            if Combat.TouchedPartsCache[desc] == nil then
                                Combat.TouchedPartsCache[desc] = desc.CanTouch
                            end
                            if desc.CanTouch then
                                desc.CanTouch = false
                            end
                        end
                    end
                end
            end
        end
    end

    local survivalKeywords = {
        "hunger", "lapar", "thirst", "haus", "food", "makan",
        "water", "minum", "hydration", "starve", "energy", "calories"
    }

    local function matchesSurvivalKeyword(str)
        local lower = string.lower(str)
        for _, kw in ipairs(survivalKeywords) do
            if string.find(lower, kw, 1, true) then
                return true
            end
        end
        return false
    end

    function Protection.RegisterSurvivalValue(inst)
        if (inst:IsA("NumberValue") or inst:IsA("IntValue")) and matchesSurvivalKeyword(inst.Name) then
            Protection.HungerThirstValues[inst] = true
        end
    end

    function Protection.BindSurvivalContainer(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if not child:IsA("PlayerGui") and not child:IsA("PlayerScripts") and not child:IsA("Backpack") then
                Protection.RegisterSurvivalValue(child)
                for _, desc in ipairs(child:GetDescendants()) do
                    Protection.RegisterSurvivalValue(desc)
                end
            end
        end
        Utils.Track(container.DescendantAdded:Connect(function(desc)
            if not desc:FindFirstAncestorOfClass("PlayerGui") and not desc:FindFirstAncestorOfClass("PlayerScripts") then
                Protection.RegisterSurvivalValue(desc)
            end
        end))
    end

    Protection.BindSurvivalContainer(LocalPlayer)
    if LocalPlayer.Character then
        Protection.BindSurvivalContainer(LocalPlayer.Character)
    end
    Utils.Track(LocalPlayer.CharacterAdded:Connect(function(char)
        Protection.BindSurvivalContainer(char)
    end))

    function Protection.StepHungerThirstGuard()
        if not Combat.HungerThirstGuard then return end

        local function restoreAttributes(container)
            if not container then return end
            pcall(function()
                for attrName, attrVal in pairs(container:GetAttributes()) do
                    if type(attrVal) == "number" and matchesSurvivalKeyword(attrName) then
                        local maxAttr = container:GetAttribute("Max" .. attrName) or 100
                        if attrVal < maxAttr then
                            container:SetAttribute(attrName, maxAttr)
                        end
                    end
                end
            end)
        end

        restoreAttributes(LocalPlayer)
        restoreAttributes(LocalPlayer.Character)

        for valObj, _ in pairs(Protection.HungerThirstValues) do
            if valObj and valObj.Parent then
                local maxObj = valObj.Parent:FindFirstChild("Max" .. valObj.Name) or valObj.Parent:FindFirstChild("MaxValue")
                local targetMax = 100
                if maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) and maxObj.Value > 0 then
                    targetMax = maxObj.Value
                elseif valObj.Value > 100 then
                    targetMax = valObj.Value
                end
                if valObj.Value < targetMax then
                    valObj.Value = targetMax
                end
            else
                Protection.HungerThirstValues[valObj] = nil
            end
        end
    end
end

-- ============================================================================
-- TAB 1: BERANDA & TELEMETRI (DASHBOARD)
-- ============================================================================
do
    local page = Components.CreateTab("Dashboard", "◈", 1)
    Components.AddSectionHeader(page, "Telemetri Klien Langsung", 1)

    local grid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 124),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.485, 0, 0, 58),
        CellPadding = UDim2.new(0.03, 0, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local function createStatCard(labelTitle, initialValue, order)
        local box = Utils.Create("Frame", {
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 14,
        }, grid)
        Utils.AddCorner(box, 9)
        Utils.AddStroke(box, Theme.BorderSubtle, 1, 0.3)

        local l1 = Utils.Create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Font = Theme.FontFamily,
            Text = labelTitle,
            TextColor3 = Theme.TextSecondary,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterText(l1, false, Theme.TextSecondary)

        local valLbl = Utils.Create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 10, 0, 26),
            BackgroundTransparency = 1,
            Font = Theme.FontBold,
            Text = initialValue,
            TextColor3 = Theme.TextPrimary,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, box)
        Utils.RegisterText(valLbl, true, Theme.TextPrimary)

        return valLbl
    end

    UI.TelemetryLabels.FPS = createStatCard("Kecepatan Frame (FPS)", "60 FPS", 1)
    UI.TelemetryLabels.Ping = createStatCard("Latensi Jaringan (Ping)", "-- ms", 2)
    UI.TelemetryLabels.Memory = createStatCard("Penggunaan Memori", "-- MB", 3)
    UI.TelemetryLabels.Players = createStatCard("Pemain Aktif", tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), 4)

    Components.AddSectionHeader(page, "Utilitas Server & Sesi", 3)

    Components.AddButton(page, "Salin ID Server (Place & Job ID)", "PlaceId: " .. tostring(game.PlaceId), "Salin ID", 4, function()
        local infoStr = string.format("PlaceId: %s | JobId: %s", tostring(game.PlaceId), tostring(game.JobId))
        if Utils.CopyText(infoStr) then
            Utils.Notify("Tersalin", infoStr, Theme.Success)
        else
            Utils.Notify("Info Server", infoStr, Theme.Accent)
        end
    end)

    Components.AddButton(page, "Reset Karakter (Respawn Instan)", "Segarkan kembali status karakter lokal Anda", "Respawn", 5, function()
        local _, hum = Utils.GetCharacter()
        if hum then
            hum.Health = 0
            Utils.Notify("Karakter", "Melakukan respawn karakter...", Theme.Warning)
        end
    end)

    Components.AddButton(page, "Hubungkan Ulang Server (Rejoin)", "Masuk kembali ke dalam server PlaceId yang sama", "Rejoin", 6, function()
        Utils.Notify("TeleportService", "Mencoba masuk kembali ke server...", Theme.Accent)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end)
end

-- ============================================================================
-- TAB 2: RADAR ESP (Pemain, Barang-Barang Tanpa Latar, & Generator)
-- ============================================================================
do
    local page = Components.CreateTab("ESP Radar", "👁", 2)
    Components.AddSectionHeader(page, "ESP Pemain & Transparansi Avatar", 1)

    Components.AddToggle(page, "Radar Pemain: Tembus Tembok", "Tampilkan ESP pemain jarak jauh menembus tembok di seluruh map", false, 2, function(on)
        ESP.Enabled = on
        if not on then
            ESP.ClearAll()
        end
        Utils.Notify("Radar Pemain", on and "ESP pemain aktif di seluruh map." or "ESP pemain dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Visual Pemain: Sorot Siluet Avatar", "Sorot bentuk tubuh avatar pemain secara transparan dari kejauhan", true, 3, function(on)
        ESP.ShowAvatar = on
        Utils.Notify("Sorot Avatar", on and "Sorotan siluet avatar diaktifkan." or "Sorotan siluet avatar dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Info Pemain: Penanda Jarak (Meter)", "Tampilkan informasi jarak real-time ke setiap pemain", true, 4, function(on)
        ESP.ShowDistance = on
        Utils.Notify("Penanda Jarak", on and "Penanda jarak pemain aktif." or "Penanda jarak pemain dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Info Pemain: Penanda Nyawa (HP)", "Otomatis menampilkan sisa nyawa jika map memakai sistem darah", true, 5, function(on)
        ESP.ShowHealth = on
        Utils.Notify("Penanda Nyawa", on and "Penanda nyawa (HP) pemain aktif." or "Penanda nyawa (HP) pemain dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddChipSelector(page, "Filter Target ESP (Teman / Musuh / Semua)", {
        { Label = "Auto Map", Value = "Auto" },
        { Label = "Musuh Saja", Value = "Enemy" },
        { Label = "Teman Saja", Value = "Ally" },
        { Label = "Semua Warna", Value = "Random" },
    }, "Auto", 6, function(val)
        ESP.Mode = val
        Utils.Notify("Filter Target ESP", "Mode target diatur ke: " .. val, Theme.Accent)
    end)

    Components.AddSlider(page, "Jarak Maksimal Radar Pemain (Studs)", 200, 10000, 2500, 0, 7, function(val)
        ESP.MaxDistance = val
    end)

    Components.AddSectionHeader(page, "Kustomisasi Warna & Font ESP Pemain", 8)

    Components.AddChipSelector(page, "Gaya Font Label ESP Pemain", {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Merriweather", Value = Enum.Font.Merriweather, Font = Enum.Font.Merriweather },
    }, Enum.Font.GothamBold, 9, function(val)
        ESP.Font = val
        Utils.Notify("Font ESP Pemain", "Gaya font ESP pemain diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Utama Sorotan ESP Pemain", {
        { Label = "Labu Emas", Value = Color3.fromRGB(255, 118, 26), Color = Color3.fromRGB(255, 118, 26) },
        { Label = "Merah Darah", Value = Color3.fromRGB(235, 69, 95), Color = Color3.fromRGB(235, 69, 95) },
        { Label = "Hijau Neon", Value = Color3.fromRGB(46, 213, 115), Color = Color3.fromRGB(46, 213, 115) },
        { Label = "Cyan Spektral", Value = Color3.fromRGB(24, 220, 255), Color = Color3.fromRGB(24, 220, 255) },
        { Label = "Ungu Mistis", Value = Color3.fromRGB(165, 94, 234), Color = Color3.fromRGB(165, 94, 234) },
        { Label = "Putih Terang", Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(255, 118, 26), 10, function(val)
        ESP.HighlightColor = val
        Utils.Notify("Warna Sorotan", "Warna utama sorotan ESP pemain diperbarui.", val)
    end)

    Components.AddChipSelector(page, "Warna Teks Penanda Jarak", {
        { Label = "Kuning Emas", Value = Color3.fromRGB(255, 210, 120), Color = Color3.fromRGB(255, 210, 120) },
        { Label = "Cyan Es", Value = Color3.fromRGB(112, 235, 255), Color = Color3.fromRGB(112, 235, 255) },
        { Label = "Putih Bersih", Value = Color3.fromRGB(250, 250, 255), Color = Color3.fromRGB(250, 250, 255) },
        { Label = "Oranye Labu", Value = Color3.fromRGB(255, 145, 65), Color = Color3.fromRGB(255, 145, 65) },
        { Label = "Pink Neon", Value = Color3.fromRGB(255, 118, 195), Color = Color3.fromRGB(255, 118, 195) },
        { Label = "Hijau Mint", Value = Color3.fromRGB(130, 255, 185), Color = Color3.fromRGB(130, 255, 185) },
    }, Color3.fromRGB(255, 210, 120), 11, function(val)
        ESP.DistanceColor = val
        Utils.Notify("Warna Jarak", "Warna teks jarak pemain diperbarui.", val)
    end)

    Components.AddChipSelector(page, "Warna Teks Penanda Darah (HP)", {
        { Label = "Hijau HP", Value = Color3.fromRGB(85, 239, 148), Color = Color3.fromRGB(85, 239, 148) },
        { Label = "Merah Crimson", Value = Color3.fromRGB(255, 88, 108), Color = Color3.fromRGB(255, 88, 108) },
        { Label = "Kuning Amber", Value = Color3.fromRGB(255, 214, 70), Color = Color3.fromRGB(255, 214, 70) },
        { Label = "Putih Salju", Value = Color3.fromRGB(245, 248, 255), Color = Color3.fromRGB(245, 248, 255) },
        { Label = "Biru Elektrik", Value = Color3.fromRGB(95, 185, 255), Color = Color3.fromRGB(95, 185, 255) },
        { Label = "Ungu Violet", Value = Color3.fromRGB(195, 135, 255), Color = Color3.fromRGB(195, 135, 255) },
    }, Color3.fromRGB(85, 239, 148), 12, function(val)
        ESP.HealthColor = val
        Utils.Notify("Warna Darah (HP)", "Warna teks darah pemain diperbarui.", val)
    end)

    Components.AddChipSelector(page, "Warna Latar Belakang Label Pemain", {
        { Label = "Hitam Tipis", Value = Color3.fromRGB(16, 12, 24), Color = Color3.fromRGB(16, 12, 24) },
        { Label = "Ungu Malam", Value = Color3.fromRGB(36, 20, 56), Color = Color3.fromRGB(36, 20, 56) },
        { Label = "Coklat Labu", Value = Color3.fromRGB(48, 24, 12), Color = Color3.fromRGB(48, 24, 12) },
        { Label = "Merah Gelap", Value = Color3.fromRGB(48, 14, 22), Color = Color3.fromRGB(48, 14, 22) },
        { Label = "Putih Kabut", Value = Color3.fromRGB(235, 230, 242), Color = Color3.fromRGB(235, 230, 242) },
        { Label = "Bening Halus", Value = Color3.fromRGB(10, 10, 14), Color = Color3.fromRGB(10, 10, 14) },
    }, Color3.fromRGB(16, 12, 24), 13, function(val)
        ESP.FontBgColor = val
        ESP.FontBgTransparency = (val == Color3.fromRGB(10, 10, 14)) and 0.78 or 0.56
        Utils.Notify("Latar Label", "Latar belakang label pemain diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Font Nama Pemain (Auto / Custom)", {
        { Label = "Auto Kontras", Value = "Auto", Color = Color3.fromRGB(255, 195, 110) },
        { Label = "Putih Tulang", Value = Color3.fromRGB(255, 248, 240), Color = Color3.fromRGB(255, 248, 240) },
        { Label = "Emas Labu", Value = Color3.fromRGB(255, 155, 55), Color = Color3.fromRGB(255, 155, 55) },
        { Label = "Merah Terang", Value = Color3.fromRGB(255, 95, 115), Color = Color3.fromRGB(255, 95, 115) },
        { Label = "Hijau Spektral", Value = Color3.fromRGB(95, 245, 155), Color = Color3.fromRGB(95, 245, 155) },
        { Label = "Hitam Pekat", Value = Color3.fromRGB(20, 16, 28), Color = Color3.fromRGB(20, 16, 28) },
    }, "Auto", 14, function(val)
        if val == "Auto" then
            ESP.FontAutoContrast = true
        else
            ESP.FontAutoContrast = false
            ESP.FontColor = val
        end
        Utils.Notify("Warna Font Nama", "Warna font nama pemain diperbarui.", Theme.Accent)
    end)

    Components.AddSectionHeader(page, "ESP Barang-Barang (Jarak Tak Terbatas & Tanpa Latar)", 15)

    Components.AddToggle(page, "Radar Barang: Deteksi Loot & Item", "Deteksi lokasi barang, loot, atau tool tanpa batas jarak & tanpa latar", false, 16, function(on)
        ItemESP.Enabled = on
        if not on then
            ItemESP.ClearAll()
        else
            ItemESP.ScanAndRender()
        end
        Utils.Notify("Radar Barang", on and "ESP Barang aktif (tanpa batas jarak)." or "ESP Barang dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddChipSelector(page, "Gaya Font Label ESP Barang", {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Oswald", Value = Enum.Font.Oswald, Font = Enum.Font.Oswald },
    }, Enum.Font.GothamBold, 17, function(val)
        ItemESP.Font = val
        Utils.Notify("Font ESP Barang", "Gaya font ESP barang diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Teks ESP Barang-Barang", {
        { Label = "Cyan Terang", Value = Color3.fromRGB(102, 242, 255), Color = Color3.fromRGB(102, 242, 255) },
        { Label = "Kuning Emas", Value = Color3.fromRGB(255, 218, 88), Color = Color3.fromRGB(255, 218, 88) },
        { Label = "Hijau Neon", Value = Color3.fromRGB(85, 255, 145), Color = Color3.fromRGB(85, 255, 145) },
        { Label = "Oranye Labu", Value = Color3.fromRGB(255, 145, 55), Color = Color3.fromRGB(255, 145, 55) },
        { Label = "Pink Neon", Value = Color3.fromRGB(255, 125, 210), Color = Color3.fromRGB(255, 125, 210) },
        { Label = "Putih Bersih", Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(102, 242, 255), 18, function(val)
        ItemESP.Color = val
        Utils.Notify("Warna ESP Barang", "Warna teks ESP barang diperbarui.", val)
    end)

    Components.AddSectionHeader(page, "ESP Generator (Status Proses Real-Time)", 19)

    Components.AddToggle(page, "Radar Generator: Status Mesin", "Tampilkan posisi mesin generator, jarak, & status proses pemain lain", false, 20, function(on)
        GeneratorESP.Enabled = on
        if not on then
            GeneratorESP.ClearAll()
        else
            GeneratorESP.ScanAndRender()
        end
        Utils.Notify("Radar Generator", on and "ESP Generator aktif." or "ESP Generator dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddChipSelector(page, "Gaya Font Label ESP Generator", {
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Oswald", Value = Enum.Font.Oswald, Font = Enum.Font.Oswald },
    }, Enum.Font.GothamBold, 21, function(val)
        GeneratorESP.Font = val
        Utils.Notify("Font ESP Generator", "Gaya font ESP generator diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Sorotan & Teks ESP Generator", {
        { Label = "Emas Listrik", Value = Color3.fromRGB(255, 196, 54), Color = Color3.fromRGB(255, 196, 54) },
        { Label = "Hijau Mesin", Value = Color3.fromRGB(72, 245, 140), Color = Color3.fromRGB(72, 245, 140) },
        { Label = "Biru Plasma", Value = Color3.fromRGB(75, 185, 255), Color = Color3.fromRGB(75, 185, 255) },
        { Label = "Merah Siaga", Value = Color3.fromRGB(255, 85, 105), Color = Color3.fromRGB(255, 85, 105) },
        { Label = "Ungu Spektral", Value = Color3.fromRGB(185, 115, 255), Color = Color3.fromRGB(185, 115, 255) },
        { Label = "Putih Terang", Value = Color3.fromRGB(255, 255, 255), Color = Color3.fromRGB(255, 255, 255) },
    }, Color3.fromRGB(255, 196, 54), 22, function(val)
        GeneratorESP.Color = val
        Utils.Notify("Warna ESP Generator", "Warna sorotan ESP generator diperbarui.", val)
    end)
end

-- ============================================================================
-- TAB 3: TEMPUR & BIDIK (AIMBOT, AUTO PARRY & PERTAHANAN)
-- ============================================================================
do
    local page = Components.CreateTab("Combat", "🎯", 3)
    Components.AddSectionHeader(page, "Auto Aimbot Presisi Tinggi", 1)

    Components.AddToggle(page, "Bidikan Otomatis: Auto Aimbot", "Kunci bidikan kamera ke sasaran secara akurat untuk senjata & melee", false, 2, function(on)
        Combat.AimbotEnabled = on
        if not on then
            Combat.CurrentTarget = nil
            Combat.HideLaser()
        end
        Utils.Notify("Auto Aimbot", on and "Aimbot presisi aktif." or "Aimbot dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Visual Senjata: Laser Bidik RGB", "Tampilkan garis laser RGB otomatis hanya saat memegang senjata api", true, 3, function(on)
        Combat.RGBLaserEnabled = on
        if not on then
            Combat.HideLaser()
        end
        Utils.Notify("Laser Bidik RGB", on and "Laser bidik senjata RGB diaktifkan." or "Laser bidik senjata RGB dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddChipSelector(page, "Mode Pemicu Kunci Aimbot", {
        { Label = "Auto (Tool/Klik)", Value = "Auto" },
        { Label = "Selalu Kunci", Value = "Always" },
        { Label = "Tahan Klik Kanan", Value = "HoldRMB" },
    }, "Auto", 4, function(val)
        Combat.AimbotMode = val
        Utils.Notify("Mode Aimbot", "Mode pemicu aimbot diubah ke: " .. val, Theme.Accent)
    end)

    Components.AddChipSelector(page, "Target Bagian Tubuh Sasaran", {
        { Label = "Kepala (Head)", Value = "Head" },
        { Label = "Badan (Torso)", Value = "HumanoidRootPart" },
        { Label = "Terdekat FOV", Value = "Closest" },
    }, "Head", 5, function(val)
        Combat.AimPart = val
        Utils.Notify("Target Tubuh", "Sasaran aimbot diatur ke: " .. val, Theme.Accent)
    end)

    Components.AddToggle(page, "Pertahanan Bidik: Abaikan Rekan Tim", "Mencegah aimbot membidik teman satu tim pada map berbasis tim", true, 6, function(on)
        Combat.TeamCheck = on
        Utils.Notify("Abaikan Rekan Tim", on and "Pelindung rekan tim aktif." or "Pelindung rekan tim dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Visual Bidik: Lingkaran Area FOV", "Tampilkan lingkaran batas area jangkauan deteksi aimbot di layar", false, 7, function(on)
        Combat.ShowFOVCircle = on
        if Combat.FOVCircle then
            Combat.FOVCircle.Visible = on
        end
        Utils.Notify("Lingkaran FOV", on and "Lingkaran area FOV ditampilkan." or "Lingkaran area FOV disembunyikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddSlider(page, "Radius Lingkaran Bidik (FOV)", 60, 600, 220, 0, 8, function(val)
        Combat.FOVRadius = val
        if Combat.FOVCircle then
            Combat.FOVCircle.Size = UDim2.new(0, val * 2, 0, val * 2)
        end
    end)

    Components.AddSlider(page, "Kehalusan Kunci Kamera (1 = Instan)", 0.1, 1.0, 0.35, 2, 9, function(val)
        Combat.Smoothness = val
    end)

    Components.AddSectionHeader(page, "Auto Parry & Pertahanan Karakter", 10)

    Components.AddToggle(page, "Tangkis Otomatis: Auto Parry", "Otomatis menangkis saat lawan atau pemain lain menyerang di dekat Anda", false, 11, function(on)
        Combat.AutoParryEnabled = on
        Utils.Notify("Auto Parry", on and "Auto Parry aktif & memantau serangan sekitar!" or "Auto Parry dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddSlider(page, "Jarak Deteksi Tangkisan Auto Parry (Studs)", 6, 35, 16, 0, 12, function(val)
        Combat.ParryRange = val
    end)

    Components.AddToggle(page, "Pertahanan Tubuh: Kebal Pukulan Melee", "Anti-terpental, anti-ragdoll, dan kebal terhadap hitbox serangan melee", false, 13, function(on)
        Combat.MeleeImmunity = on
        if not on then
            Protection.RestoreEnemyHitboxes()
        end
        Utils.Notify("Kebal Pukulan", on and "Mode kebal pukulan & anti-mental aktif!" or "Mode kebal dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(
        page,
        "Pertahanan Total: Kebal Bencana & Segala Bahaya (Anti-Mati)",
        "Kebal total dari bencana alam, meteor, banjir, gempa, api, ledakan, petir, jatuh/void, racun, & apapun tanpa mati/dead",
        false,
        14,
        function(on)
            Combat.DisasterImmunity = on
            local char, hum, root = Utils.GetCharacter(LocalPlayer)
            if on then
                if root then
                    Combat.LastSafePosition = root.Position
                    Combat.LastSafeCFrame = root.CFrame
                end
                if char then
                    Protection.EnsureDisasterForceField(char)
                end
                if hum and hum.Health > 0 then
                    hum.Health = hum.MaxHealth
                end
            else
                Protection.RestoreDisasterImmunity()
            end
            Utils.Notify(
                "Kebal Bencana & Bahaya",
                on and "Kebal total bencana alam & segala bahaya aktif (Anti-Mati)!" or "Kebal bencana & bahaya dimatikan.",
                on and Theme.Success or Theme.TextSecondary
            )
        end
    )

    Components.AddToggle(page, "Penjaga Bertahan Hidup: Tahan Lapar & Haus", "Menjaga indikator lapar (Hunger) dan haus (Thirst) tetap penuh otomatis", false, 15, function(on)
        Combat.HungerThirstGuard = on
        Utils.Notify("Tahan Lapar & Haus", on and "Penjaga lapar & haus aktif!" or "Penjaga lapar & haus dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)
end

-- ============================================================================
-- TAB 4: GENDONG PEMAIN (CARRY SYSTEM)
-- ============================================================================
do
    local page = Components.CreateTab("Carry", "🫂", 4)
    Components.AddSectionHeader(page, "Kontrol Carry Interaktif (Replikasi Server)", 1)

    local carryStatusLabel = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = "  Target Terpilih: Belum ada pemain dipilih",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(carryStatusLabel, 7)
    Utils.RegisterText(carryStatusLabel, true, Theme.TextSecondary)

    local actionRow = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        ZIndex = 14,
    }, page)

    local carryBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0.485, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Success,
        Font = Theme.FontBold,
        Text = "🫂 Gendong (Carry)",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
    }, actionRow)
    Utils.AddCorner(carryBtn, 8)

    local releaseCarryBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0.485, 0, 1, 0),
        Position = UDim2.new(0.515, 0, 0, 0),
        BackgroundColor3 = Theme.Danger,
        Font = Theme.FontBold,
        Text = "✋ Lepaskan",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
    }, actionRow)
    Utils.AddCorner(releaseCarryBtn, 8)

    carryBtn.MouseButton1Click:Connect(function()
        SafeEngine.Run("CarryStart", function()
            if Carry.Start() and Carry.TargetPlayer then
                local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
                carryStatusLabel.Text = "  Status: Menggendong " .. Carry.TargetPlayer.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
            end
        end)
    end)

    releaseCarryBtn.MouseButton1Click:Connect(function()
        SafeEngine.Run("CarryStop", function()
            Carry.Stop()
            carryStatusLabel.Text = Carry.TargetPlayer
                and ("  Target Terpilih: " .. Carry.TargetPlayer.DisplayName .. " (Dilepas)")
                or "  Target Terpilih: Belum ada pemain dipilih"
            Utils.Notify("Lepas Gendong", "Target pemain telah dilepaskan.", Theme.TextSecondary)
        end)
    end)

    Components.AddChipSelector(page, "Pilih Gaya Posisi Gendong (Carry)", {
        { Label = "Gendong Depan", Value = "Depan" },
        { Label = "Gendong Belakang", Value = "Belakang" },
        { Label = "Panggul Pundak", Value = "Pundak" },
        { Label = "Tarik / Seret", Value = "Seret" },
        { Label = "Panggul Kepala", Value = "Kepala" },
        { Label = "Melayang Samping", Value = "Melayang" },
    }, "Depan", 4, function(val)
        Carry.Style = val
        if Carry.Enabled and Carry.TargetPlayer then
            local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
            carryStatusLabel.Text = "  Status: Menggendong " .. Carry.TargetPlayer.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
        end
        Utils.Notify("Gaya Gendong", "Posisi gendong diubah ke: " .. val, Theme.Accent)
    end)

    Components.AddSectionHeader(page, "Pilih Teman / Player untuk Di-Carry", 5)

    local carryListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, carryListHolder)

    local function refreshCarryPlayers()
        for _, child in ipairs(carryListHolder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                count = count + 1
                local isSelected = (Carry.TargetPlayer == plr)
                local row = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    LayoutOrder = count,
                    ZIndex = 14,
                }, carryListHolder)
                Utils.AddCorner(row, 8)
                Utils.AddStroke(row, isSelected and Theme.Accent or Theme.BorderSubtle, 1, 0.25)

                local nameLbl = Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 15,
                }, row)
                Utils.RegisterText(nameLbl, false, Theme.TextPrimary)

                local pickBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 86, 0, 26),
                    Position = UDim2.new(1, -96, 0.5, -13),
                    BackgroundColor3 = isSelected and Theme.Success or Theme.Accent,
                    Font = Theme.FontBold,
                    Text = isSelected and "Terpilih ✓" or "Pilih Target",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 15,
                }, row)
                Utils.AddCorner(pickBtn, 6)

                pickBtn.MouseButton1Click:Connect(function()
                    if Carry.TargetPlayer and Carry.TargetPlayer ~= plr then
                        local _, oldHum = Utils.GetCharacter(Carry.TargetPlayer)
                        if oldHum then
                            oldHum.PlatformStand = false
                            if oldHum:GetState() == Enum.HumanoidStateType.Physics then
                                oldHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end
                        end
                    end
                    Carry.TargetPlayer = plr
                    if Carry.Enabled then
                        Carry.NativePromptTriggered = false
                        Carry.NativePromptTriggered = Carry.TryNativeMapCarry(plr)
                        local modeTag = Carry.NativePromptTriggered and "Server" or "Lokal"
                        carryStatusLabel.Text = "  Status: Menggendong " .. plr.DisplayName .. " (" .. Carry.Style .. " | " .. modeTag .. ")"
                    else
                        carryStatusLabel.Text = "  Target Terpilih: " .. plr.DisplayName .. " (Tekan tombol Gendong)"
                    end
                    refreshCarryPlayers()
                    Utils.Notify("Target Dipilih", "Siap menggendong " .. plr.DisplayName .. ".", Theme.Accent)
                end)
            end
        end

        if count == 0 then
            local empty = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BgCard,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                ZIndex = 14,
            }, carryListHolder)
            Utils.AddCorner(empty, 8)
            Utils.Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = "Belum ada pemain lain di server untuk digendong.",
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                ZIndex = 15,
            }, empty)
        end
    end

    refreshCarryPlayers()
    Utils.Track(Players.PlayerAdded:Connect(refreshCarryPlayers))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if Carry.TargetPlayer == plr then
            Carry.Stop()
            Carry.TargetPlayer = nil
            carryStatusLabel.Text = "  Target Terpilih: Belum ada pemain dipilih"
        end
        task.defer(refreshCarryPlayers)
    end))
end

-- ============================================================================
-- TAB 5: TARIAN & EMOTE STUDIO (Replicated ke Semua Device Pemain Lain)
-- ============================================================================
do
    local page = Components.CreateTab("Dances", "💃", 5)
    Components.AddSectionHeader(page, "Studio Dance & Emote (Replikasi R6 & R15)", 1)

    Components.AddSlider(page, "Kecepatan Gerakan Tarian (Dance Speed)", 0.5, 2.5, 1.0, 1, 2, function(val)
        Emotes.Speed = val
        if Emotes.ActiveTrack then
            pcall(function() Emotes.ActiveTrack:AdjustSpeed(val) end)
        end
    end)

    local customAnimCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(customAnimCard, 9)
    Utils.AddStroke(customAnimCard, Theme.BorderSubtle, 1, 0.3)

    local animBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -118, 0, 28),
        Position = UDim2.new(0, 10, 0.5, -14),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = "ID Animasi Tarian Kustom (angka)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, customAnimCard)
    Utils.AddCorner(animBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, animBox)

    local playCustomBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 92, 0, 28),
        Position = UDim2.new(1, -102, 0.5, -14),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = "Putar ID",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, customAnimCard)
    Utils.AddCorner(playCustomBtn, 6)
    Utils.RegisterAccent(playCustomBtn, "BackgroundColor3")

    playCustomBtn.MouseButton1Click:Connect(function()
        if animBox.Text ~= "" then
            Emotes.PlayAsset("Tarian Kustom", animBox.Text)
        else
            Utils.Notify("ID Tarian", "Masukkan angka ID animasi Roblox terlebih dahulu.", Theme.Warning)
        end
    end)

    Components.AddButton(page, "Hentikan Tarian & Reset Pose", "Hentikan animasi tarian yang sedang dimainkan karakter", "Hentikan", 4, function()
        Emotes.Stop()
        Utils.Notify("Emote", "Animasi tarian dihentikan.", Theme.TextSecondary)
    end)

    Components.AddSectionHeader(page, "Daftar Dance Replikasi (R6 & R15)", 5)

    local danceGrid = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)

    Utils.Create("UIGridLayout", {
        CellSize = UDim2.new(0.485, 0, 0, 34),
        CellPadding = UDim2.new(0.03, 0, 0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, danceGrid)

    for idx, danceEntry in ipairs(Emotes.Catalog) do
        local dBtn = Utils.Create("TextButton", {
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.2,
            Font = Theme.FontBold,
            Text = "💃 " .. danceEntry.Label,
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 15,
        }, danceGrid)
        Utils.AddCorner(dBtn, 7)
        Utils.AddStroke(dBtn, Theme.BorderSubtle, 1, 0.25)

        dBtn.MouseEnter:Connect(function()
            Utils.Tween(dBtn, TweenInfo.new(0.14), { BackgroundColor3 = Theme.Accent })
        end)
        dBtn.MouseLeave:Connect(function()
            Utils.Tween(dBtn, TweenInfo.new(0.14), { BackgroundColor3 = Theme.BgCard })
        end)
        dBtn.MouseButton1Click:Connect(function()
            Emotes.PlayPreset(danceEntry)
        end)
    end
end

-- ============================================================================
-- TAB 6: GERAK & KECEPATAN (UNLIMITED SPEED API + SMOOTH FLY + ANALOG NOCLIP)
-- ============================================================================
do
    local page = Components.CreateTab("Movement", "⚡", 6)
    Components.AddSectionHeader(page, "Kecepatan Lari & Lompat Tanpa Batas (Unlimited Speed API)", 1)

    local function applyCharacterPhysics()
        local _, hum = Utils.GetCharacter()
        if hum then
            hum.WalkSpeed = State.WalkSpeed
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower
        end
        workspace.Gravity = State.Gravity
    end

    local wsSlider = Components.AddSlider(page, "Kecepatan Lari / Jalan (WalkSpeed Unlimited)", 16, 10000, 16, 0, 2, function(val)
        State.WalkSpeed = val
        applyCharacterPhysics()
    end)

    local jpSlider = Components.AddSlider(page, "Daya Lompat Tinggi (JumpPower Unlimited)", 50, 10000, 50, 0, 3, function(val)
        State.JumpPower = val
        applyCharacterPhysics()
    end)

    local gravSlider = Components.AddSlider(page, "Gravitasi Dunia (Workspace Gravity)", 0, 500, math.floor(State.OriginalGravity + 0.5), 0, 4, function(val)
        State.Gravity = val
        workspace.Gravity = val
    end)

    Components.AddButton(page, "Reset Kecepatan & Fisika ke Bawaan", "Kembalikan WalkSpeed, JumpPower & Gravity ke default", "Reset", 5, function()
        State.WalkSpeed = 16
        State.JumpPower = 50
        State.Gravity = State.OriginalGravity
        wsSlider.SetValue(16, false)
        jpSlider.SetValue(50, false)
        gravSlider.SetValue(State.OriginalGravity, false)
        applyCharacterPhysics()
        Utils.Notify("Fisika Direset", "Kecepatan jalan, lompat & gravitasi dikembalikan.", Theme.Success)
    end)

    Components.AddSectionHeader(page, "Mode Terbang Bebas & Penembus Dinding", 6)

    Components.AddToggle(page, "Gerak Udara: Terbang Bebas (Admin Fly)", "Terbang bebas dan mulus ke segala arah kamera di PC maupun Mobile", false, 7, function(on)
        State.FlyEnabled = on
        if on then
            local _, hum, root = Utils.GetCharacter()
            if root then
                Physics.FlyCurrentVel = root.AssemblyLinearVelocity
            end
            if hum then
                hum.PlatformStand = true
                hum.AutoRotate = false
            end
            Utils.Notify("Terbang Bebas", "Mode terbang aktif! Gunakan analog/WASD & arah kamera.", Theme.Success)
        else
            Physics.CleanupFly()
            Utils.Notify("Terbang Bebas", "Mode terbang dimatikan.", Theme.TextSecondary)
        end
    end)

    Components.AddSlider(page, "Kecepatan Terbang Bebas (FlySpeed Unlimited)", 15, 10000, 65, 0, 8, function(val)
        State.FlySpeed = val
    end)

    Components.AddToggle(
        page,
        "Gerak Fisika: Tembus Dinding (NoClip)",
        "tidak disarankan untuk fitur NoClip ingin menembus tetapi analog di tarik berlebihan, jika ingin menembus tarik analog secara perlahan-lahan",
        false,
        9,
        function(on)
            State.NoclipEnabled = on
            if not on then
                Physics.RestoreNoclip()
            end
            Utils.Notify("NoClip", on and "NoClip aktif (tarik analog perlahan saat menembus)." or "NoClip dimatikan.", on and Theme.Success or Theme.TextSecondary)
        end
    )

    Components.AddToggle(page, "Gerak Lompat: Lompat Udara Tanpa Batas", "Melompat berkali-kali di udara tanpa perlu menyentuh permukaan tanah", false, 10, function(on)
        State.InfiniteJumpEnabled = on
        Utils.Notify("Infinite Jump", on and "Lompat udara tanpa batas aktif." or "Lompat udara tanpa batas dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)
end

-- ============================================================================
-- TAB 7: TELEPORTASI (UNLIMITED CROSS-WORLD TELEPORT + REMOTE VIEW + WAYPOINTS)
-- ============================================================================
do
    local page = Components.CreateTab("Teleport", "✦", 7)
    Components.AddSectionHeader(page, "Telemetri Dunia & Teleport Bebas Tanpa Batas Jarak", 1)

    local worldTeleLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = "  Posisi Anda: Memuat koordinat...\n  Dunia/Sektor: Main World | Jarak Teleport Terakhir: 0 m",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(worldTeleLbl, 8)
    Utils.AddStroke(worldTeleLbl, Theme.BorderSubtle, 1, 0.3)
    Utils.RegisterText(worldTeleLbl, true, Theme.TextSecondary)
    UI.TelemetryLabels.WorldCoord = worldTeleLbl

    local distSlider = Components.AddSlider(page, "Jarak Teleport Maju / Maju-Ke-Depan (Studs)", 10, 50000, 500, 0, 3, function(val)
        State.CustomTeleportDistance = val
    end)

    Components.AddButton(page, "Teleport Maju Sesuai Jarak Slider", "Pindah instan ke depan arah kamera tanpa batas jarak", "Gas TP", 4, function()
        local _, _, root = Utils.GetCharacter(LocalPlayer)
        local cam = workspace.CurrentCamera
        if root and cam then
            local lookDir = cam.CFrame.LookVector
            if lookDir.Magnitude < 0.01 then
                lookDir = root.CFrame.LookVector
            end
            local destPos = root.Position + (lookDir.Unit * State.CustomTeleportDistance)
            local destCF = CFrame.lookAt(destPos, destPos + lookDir.Unit)
            local ok, dist = Utils.SafeTeleport(destCF)
            if ok then
                Utils.Notify("Teleport Jarak Jauh", "Berhasil berpindah sejauh " .. TeleportAPI.FormatDistance(dist) .. "!", Theme.Success)
            end
        end
    end)

    local clickTpToggle = Components.AddToggle(page, "Klik Map Untuk Teleport (Click TP)", "Klik di mana saja pada dunia (tanpa batas jarak) untuk berpindah instan", false, 5, function(on)
        State.ClickTPEnabled = on
        Utils.Notify("Click Teleport", on and "Click TP aktif! Klik lokasi mana saja di layar." or "Click TP dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)
    State.ClickTPEnabled = false

    local wpNameBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.2,
        Font = Theme.FontFamily,
        PlaceholderText = "Nama waypoint (contoh: Markas, Boss, Dunia 2)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(wpNameBox, 8)
    Utils.AddStroke(wpNameBox, Theme.BorderSubtle, 1, 0.3)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, wpNameBox)

    local wpListFrame = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 8,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, wpListFrame)

    local function refreshWaypoints()
        for _, child in ipairs(wpListFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        for idx, wp in ipairs(State.Waypoints) do
            local row = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Theme.BgCard,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                LayoutOrder = idx,
                ZIndex = 14,
            }, wpListFrame)
            Utils.AddCorner(row, 8)
            Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.25)

            local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
            local distNow = myRoot and (wp.CFrame.Position - myRoot.Position).Magnitude or 0

            local lbl = Utils.Create("TextLabel", {
                Size = UDim2.new(1, -144, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = "📍 " .. wp.Name .. " [" .. TeleportAPI.FormatDistance(distNow) .. "]",
                TextColor3 = Theme.TextPrimary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 15,
            }, row)
            Utils.RegisterText(lbl, false, Theme.TextPrimary)

            local goBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 56, 0, 26),
                Position = UDim2.new(1, -124, 0.5, -13),
                BackgroundColor3 = Theme.Accent,
                Font = Theme.FontBold,
                Text = "TP",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 15,
            }, row)
            Utils.AddCorner(goBtn, 6)
            Utils.RegisterAccent(goBtn, "BackgroundColor3")

            local delBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 54, 0, 26),
                Position = UDim2.new(1, -64, 0.5, -13),
                BackgroundColor3 = Theme.Crimson,
                Font = Theme.FontBold,
                Text = "Hapus",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 15,
            }, row)
            Utils.AddCorner(delBtn, 6)

            goBtn.MouseButton1Click:Connect(function()
                local ok, d = Utils.SafeTeleport(wp.CFrame)
                if ok then
                    Utils.Notify("Waypoint", "Teleport ke " .. wp.Name .. " (" .. TeleportAPI.FormatDistance(d) .. ")", Theme.Success)
                end
            end)

            delBtn.MouseButton1Click:Connect(function()
                table.remove(State.Waypoints, idx)
                refreshWaypoints()
            end)
        end
    end

    Components.AddButton(page, "Simpan Lokasi Saat Ini (Waypoint)", "Simpan posisi & dunia Anda sekarang (tanpa batas jarak)", "Simpan", 7, function()
        local _, _, root = Utils.GetCharacter(LocalPlayer)
        if root then
            local name = wpNameBox.Text ~= "" and wpNameBox.Text or ("Lokasi #" .. tostring(#State.Waypoints + 1))
            local worldTag = TeleportAPI.DetectSubWorldName(LocalPlayer, root.Position)
            table.insert(State.Waypoints, { Name = name .. " (" .. worldTag .. ")", CFrame = root.CFrame })
            wpNameBox.Text = ""
            refreshWaypoints()
            Utils.Notify("Waypoint Tersimpan", "Menyimpan lokasi: " .. name, Theme.Success)
        end
    end)

    Components.AddSectionHeader(page, "View & Teleport Pemain Lintas Dunia (Tanpa Batas Jarak)", 9)

    local playerListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 10,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, playerListHolder)

    local playerRowRefs = {}

    local function updatePlayerDistances()
        local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
        for plr, ref in pairs(playerRowRefs) do
            if plr and plr.Parent and ref.Label and ref.Label.Parent then
                local info = TeleportAPI.ResolvePlayerState(plr)
                if info then
                    local distText = myRoot and TeleportAPI.FormatDistance((info.Position - myRoot.Position).Magnitude) or "Aktif"
                    local isSpec = (State.SpectatingPlayer == plr)
                    ref.Label.Text = string.format(
                        "%s%s • %s • %s",
                        isSpec and "👁 [VIEW] " or "",
                        plr.DisplayName,
                        distText,
                        info.WorldName
                    )
                    if ref.ViewBtn and ref.ViewBtn.Parent then
                        ref.ViewBtn.Text = isSpec and "Stop View" or "View"
                        ref.ViewBtn.BackgroundColor3 = isSpec and Theme.Warning or Theme.BgControl
                    end
                else
                    ref.Label.Text = plr.DisplayName .. " • Sinkronisasi Dunia..."
                end
            end
        end
    end

    local function refreshPlayers()
        for _, child in ipairs(playerListHolder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        table.clear(playerRowRefs)

        local idx = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                idx = idx + 1
                local row = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 44),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    LayoutOrder = idx,
                    ZIndex = 14,
                }, playerListHolder)
                Utils.AddCorner(row, 8)
                Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.25)

                local info = TeleportAPI.ResolvePlayerState(plr)
                local _, _, myRoot = Utils.GetCharacter(LocalPlayer)
                local distStr = (info and myRoot) and TeleportAPI.FormatDistance((info.Position - myRoot.Position).Magnitude) or "Lintas Dunia"
                local worldStr = info and info.WorldName or "Memindai..."
                local isSpec = (State.SpectatingPlayer == plr)

                local pLbl = Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -138, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = string.format("%s%s • %s • %s", isSpec and "👁 [VIEW] " or "", plr.DisplayName, distStr, worldStr),
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 15,
                }, row)
                Utils.RegisterText(pLbl, false, Theme.TextPrimary)

                local viewBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 62, 0, 26),
                    Position = UDim2.new(1, -124, 0.5, -13),
                    BackgroundColor3 = isSpec and Theme.Warning or Theme.BgControl,
                    Font = Theme.FontBold,
                    Text = isSpec and "Stop View" or "View",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 10,
                    AutoButtonColor = false,
                    ZIndex = 15,
                }, row)
                Utils.AddCorner(viewBtn, 6)

                local tpBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 52, 0, 26),
                    Position = UDim2.new(1, -58, 0.5, -13),
                    BackgroundColor3 = Theme.Accent,
                    Font = Theme.FontBold,
                    Text = "TP",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 15,
                }, row)
                Utils.AddCorner(tpBtn, 6)
                Utils.RegisterAccent(tpBtn, "BackgroundColor3")

                playerRowRefs[plr] = { Label = pLbl, ViewBtn = viewBtn, TpBtn = tpBtn }

                viewBtn.MouseButton1Click:Connect(function()
                    if State.SpectatingPlayer == plr then
                        TeleportAPI.StopRemoteView(true)
                        refreshPlayers()
                    else
                        local started, pInfo = TeleportAPI.StartRemoteView(plr)
                        if started then
                            local wLabel = pInfo and pInfo.WorldName or "Lintas Dunia"
                            Utils.Notify("Remote View Aktif", "Mengintip " .. plr.DisplayName .. " (" .. wLabel .. ")", Theme.Accent)
                            refreshPlayers()
                        end
                    end
                end)

                tpBtn.MouseButton1Click:Connect(function()
                    local liveInfo = TeleportAPI.ResolvePlayerState(plr)
                    if liveInfo then
                        local ok, dist = Utils.SafeTeleport(liveInfo.CFrame * CFrame.new(0, 0.5, 3), plr)
                        if ok then
                            Utils.Notify("Teleport Pemain", "Menuju " .. plr.DisplayName .. " (" .. TeleportAPI.FormatDistance(dist) .. " | " .. liveInfo.WorldName .. ")", Theme.Success)
                        end
                    else
                        TeleportAPI.RequestStreamAt(Vector3.zero, 5)
                        Utils.Notify("Mencari Koordinat", "Memuat streaming area untuk " .. plr.DisplayName .. "...", Theme.Warning)
                    end
                end)
            end
        end
    end

    UI.RefreshPlayerList = refreshPlayers
    UI.UpdatePlayerDistances = updatePlayerDistances
    refreshPlayers()
    Utils.Track(Players.PlayerAdded:Connect(refreshPlayers))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if State.SpectatingPlayer == plr then
            TeleportAPI.StopRemoteView(false)
        end
        refreshPlayers()
    end))
end

-- ============================================================================
-- TAB 8: TAMPILAN DUNIA (WORLD VISUALS)
-- ============================================================================
do
    local page = Components.CreateTab("Visuals", "☀", 8)
    Components.AddSectionHeader(page, "Kontrol Kamera & Pencahayaan", 1)

    local fovSlider = Components.AddSlider(page, "Sudut Pandang Kamera (Field of View)", 40, 120, 70, 0, 2, function(val)
        State.CameraFOV = val
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = val
        end
    end)

    local function applyFullbright()
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    end

    local function restoreFullbright()
        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
    end

    local function applyNoFog()
        Lighting.FogStart = 1e6
        Lighting.FogEnd = 1e6
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then
            atmo.Density = 0
        end
    end

    local function restoreNoFog()
        Lighting.FogStart = State.OriginalLighting.FogStart
        Lighting.FogEnd = State.OriginalLighting.FogEnd
        if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance and State.OriginalAtmosphere.Instance.Parent then
            State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
        end
    end

    UI.FullbrightToggle = Components.AddToggle(page, "Cahaya Dunia: Penerangan Maksimal (Fullbright)", "Hilangkan bayangan gelap dan terangkan seluruh sudut map secara instan", false, 3, function(on)
        State.FullbrightEnabled = on
        if on then
            applyFullbright()
        else
            restoreFullbright()
        end
        Utils.Notify("Fullbright", on and "Pencahayaan maksimal aktif." or "Pencahayaan dikembalikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    UI.NoFogToggle = Components.AddToggle(page, "Cuaca Dunia: Penghapus Kabut (No Fog)", "Hapus kabut jarak pandang (FogEnd & Atmosphere) agar terlihat jernih", false, 4, function(on)
        State.NoFogEnabled = on
        if on then
            applyNoFog()
        else
            restoreNoFog()
        end
        Utils.Notify("No Fog", on and "Kabut dunia dihapus." or "Kabut dunia dikembalikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    local timeSlider = Components.AddSlider(page, "Atur Waktu Siang / Malam Klien (Jam)", 0, 24, math.floor(State.OriginalLighting.ClockTime + 0.5), 0, 5, function(val)
        Lighting.ClockTime = val
    end)

    Components.AddButton(page, "Pulihkan Pengaturan Visual & Kamera", "Pulihkan FOV (70), sakelar, dan pencahayaan asli map", "Pulihkan", 6, function()
        State.CameraFOV = 70
        State.FullbrightEnabled = false
        State.NoFogEnabled = false
        fovSlider.SetValue(70, false)
        timeSlider.SetValue(math.floor(State.OriginalLighting.ClockTime + 0.5), false)
        if UI.FullbrightToggle then UI.FullbrightToggle.SetState(false, false) end
        if UI.NoFogToggle then UI.NoFogToggle.SetState(false, false) end
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = 70
        end
        Lighting.ClockTime = State.OriginalLighting.ClockTime
        restoreFullbright()
        restoreNoFog()
        Utils.Notify("Visual Dipulihkan", "FOV, kabut, dan pencahayaan map kembali normal.", Theme.Success)
    end)
end

-- ============================================================================
-- TAB 9: PENGATURAN (ANTI-DETECT, ANTI-BUG, ANTI-AFK, BAHASA IP, FONT & WARNA)
-- ============================================================================
do
    local page = Components.CreateTab("Settings", "⚙", 9)

    Components.AddSectionHeader(page, "Sistem Anti-Detect & Stealth Mode (Terpadu)", 1)

    local antiDetectBanner = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = "  Anti-Detect AKTIF • Memindai dukungan executor...",
        TextColor3 = Theme.Success,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(antiDetectBanner, 7)
    Utils.AddStroke(antiDetectBanner, Theme.BorderSubtle, 1, 0.3)
    UI.AntiDetectStatusLabel = antiDetectBanner

    Components.AddToggle(page, "Master Anti-Detect & Stealth Mode", "Aktifkan perlindungan anti-deteksi terpadu (GUI Cloak, Spoof & Anti-Kick)", true, 3, function(on)
        AntiDetect.Enabled = on
        AntiDetect.RefreshCloak(false)
        Utils.Notify("Anti-Detect Engine", on and "Master Anti-Detect & Stealth Mode AKTIF." or "Anti-Detect dimatikan sementara.", on and Theme.Success or Theme.Warning)
    end)

    Components.AddToggle(page, "GUI Cloaking & Acak Nama Objek (Hidden UI)", "Sembunyikan UI ke container tersembunyi & acak nama instance agar lolos scan", true, 4, function(on)
        AntiDetect.GuiCloakEnabled = on
        AntiDetect.RefreshCloak(on)
        Utils.Notify("GUI Cloaking", on and "GUI disembunyikan & nama objek diacak." or "GUI Cloaking dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Spoofing Properti Karakter (Speed / Jump / Gravity)", "Samarkan WalkSpeed, JumpPower, Gravity & FOV agar terbaca normal oleh game", true, 5, function(on)
        AntiDetect.PropertySpoofEnabled = on
        AntiDetect.UpdateStatusBanner()
        Utils.Notify("Property Spoofer", on and "Spoofing WalkSpeed/Jump/Gravity AKTIF." or "Property Spoofer dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Anti-Kick Lokal & Blokir Remote Laporan Anti-Cheat", "Tahan panggilan LocalPlayer:Kick() lokal & blokir remote pelaporan mencurigakan", true, 6, function(on)
        AntiDetect.AntiKickHookEnabled = on
        AntiDetect.RemoteSanitizerEnabled = on
        AntiDetect.UpdateStatusBanner()
        Utils.Notify("Anti-Kick & Remote Guard", on and "Penahan Kick lokal & filter remote AKTIF." or "Anti-Kick & Remote Guard dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Physics & Camera Instance Stealth", "Sembunyikan objek Fly, Laser & Anchor ke CurrentCamera dengan nama bawaan", true, 7, function(on)
        AntiDetect.PhysicsStealthEnabled = on
        AntiDetect.RefreshCloak(false)
        Utils.Notify("Physics Stealth", on and "Objek Fly/Laser disembunyikan ke CurrentCamera." or "Physics Stealth dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Anti-Detect Fly (CFrame Stealth & State Spoof)", "Terbang tanpa objek BodyMover/Constraint serta menyamarkan status & kecepatan karakter", true, 8, function(on)
        AntiDetect.FlyStealthEnabled = on
        if on and State.FlyEnabled then
            Physics.CleanupFly()
        end
        AntiDetect.UpdateStatusBanner()
        Utils.Notify("Anti-Detect Fly", on and "Anti-Detect Fly (Stealth CFrame & State Spoof) AKTIF." or "Anti-Detect Fly dimatikan (mode Fly standar).", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddToggle(page, "Anti-Detect Teleport (Bypass Rubberband & Pos Spoof)", "Teleport bertahap anti-rubberband dengan penyamaran kecepatan & pelindung tarik-balik server", true, 9, function(on)
        AntiDetect.TeleportStealthEnabled = on
        AntiDetect.UpdateStatusBanner()
        Utils.Notify("Anti-Detect Teleport", on and "Anti-Detect Teleport (Bypass Rubberband) AKTIF." or "Anti-Detect Teleport dimatikan (mode Teleport standar).", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddButton(page, "Acak Ulang Identitas GUI & Objek (Re-Cloak Now)", "Perbarui nama acak seluruh container GUI & helper secara instan", "Re-Cloak", 10, function()
        AntiDetect.RefreshCloak(true)
        Utils.Notify("Stealth Re-Cloak", "Seluruh identitas GUI & helper berhasil diacak ulang!", Theme.Success)
    end)

    Components.AddSectionHeader(page, "Sistem Anti-Bug / Error & Anti-AFK", 9)

    Components.AddToggle(page, "Proteksi Sistem: Anti-Bug & Pemulihan Otomatis", "Mencegah error pada setiap fitur dan memulihkannya otomatis saat terganggu", true, 10, function(on)
        Protection.AntiBugEnabled = on
        if UI.StatusLabel and UI.StatusLabel.Parent then
            UI.StatusLabel.Text = on and "Anti-Bug: AKTIF" or "Anti-Bug: OFF"
        end
        Utils.Notify("Anti-Bug Engine", on and "Proteksi anti-bug & auto-recovery AKTIF." or "Proteksi anti-bug dimatikan.", on and Theme.Success or Theme.Warning)
    end)

    Components.AddToggle(page, "Proteksi Koneksi: Anti-Kick Diam (Anti-AFK)", "Mencegah terputus dari server otomatis saat karakter diam lebih dari 20 menit", true, 11, function(on)
        Protection.AntiAFKEnabled = on
        Utils.Notify("Anti-AFK", on and "Anti-AFK aktif." or "Anti-AFK dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    Components.AddSectionHeader(page, GeoLangAPI.T("lang_section"), 12)

    local langStatusBanner = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        Font = Theme.FontBold,
        Text = "  " .. string.format(
            GeoLangAPI.T("lang_status_fmt"),
            GeoLangAPI.IPAddress,
            GeoLangAPI.Country,
            GeoLangAPI.CountryCode,
            GeoLangAPI.GetLanguageLabel(GeoLangAPI.CurrentLang),
            GeoLangAPI.T("mode_auto")
        ),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 13,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(langStatusBanner, 7)
    Utils.AddStroke(langStatusBanner, Theme.BorderSubtle, 1, 0.3)
    Utils.RegisterAccent(langStatusBanner, "TextColor3")
    UI.LangStatusLabel = langStatusBanner

    local langChipOptions = {}
    for _, entry in ipairs(GeoLangAPI.Languages) do
        table.insert(langChipOptions, {
            Label = entry.Label,
            Value = entry.Code,
        })
    end

    local langSelector = Components.AddChipSelector(
        page,
        GeoLangAPI.T("lang_selector"),
        langChipOptions,
        GeoLangAPI.CurrentLang,
        14,
        function(selectedCode)
            GeoLangAPI.SetLanguage(selectedCode, true)
            Utils.Notify(
                "Bahasa / Language",
                GeoLangAPI.T("lang_changed") .. GeoLangAPI.GetLanguageLabel(selectedCode),
                Theme.Success
            )
        end
    )

    Components.AddButton(
        page,
        GeoLangAPI.T("lang_auto_btn"),
        GeoLangAPI.T("lang_auto_sub"),
        GeoLangAPI.T("lang_sync_now"),
        15,
        function()
            GeoLangAPI.ManualOverride = false
            GeoLangAPI.FetchRealTimeGeoIP(true)
            task.delay(0.8, function()
                if langSelector and langSelector.SetSelected then
                    langSelector.SetSelected(GeoLangAPI.CurrentLang)
                end
            end)
            Utils.Notify("Geo-IP Sync", "Menyinkronkan alamat IP & bahasa wilayah...", Theme.Accent)
        end
    )

    GeoLangAPI.OnLanguageChanged(function(newLang)
        if langSelector and langSelector.SetSelected then
            langSelector.SetSelected(newLang)
        end
    end)

    Components.AddSectionHeader(page, "Kustomisasi Font & Warna Panel Menu", 16)

    Components.AddChipSelector(page, "Gaya Font Seluruh Panel Menu", {
        { Label = "Gotham Semi", Value = Enum.Font.GothamSemibold, Font = Enum.Font.GothamSemibold },
        { Label = "Gotham Bold", Value = Enum.Font.GothamBold, Font = Enum.Font.GothamBold },
        { Label = "Fredoka One", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Merriweather", Value = Enum.Font.Merriweather, Font = Enum.Font.Merriweather },
    }, Enum.Font.GothamSemibold, 17, function(val)
        Theme.FontFamily = val
        Theme.FontBold = (val == Enum.Font.Creepster or val == Enum.Font.FredokaOne) and val or Enum.Font.GothamBold
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Font Menu", "Gaya font seluruh panel menu diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Aksen Utama Panel Menu", {
        { Label = "Labu Emas", Value = Color3.fromRGB(255, 118, 26), Color = Color3.fromRGB(255, 118, 26) },
        { Label = "Merah Crimson", Value = Color3.fromRGB(214, 48, 74), Color = Color3.fromRGB(214, 48, 74) },
        { Label = "Ungu Spektral", Value = Color3.fromRGB(155, 89, 245), Color = Color3.fromRGB(155, 89, 245) },
        { Label = "Hijau Neon", Value = Color3.fromRGB(46, 213, 115), Color = Color3.fromRGB(46, 213, 115) },
        { Label = "Biru Elektrik", Value = Color3.fromRGB(52, 152, 219), Color = Color3.fromRGB(52, 152, 219) },
        { Label = "Pink Neon", Value = Color3.fromRGB(255, 105, 180), Color = Color3.fromRGB(255, 105, 180) },
    }, Color3.fromRGB(255, 118, 26), 18, function(val)
        Utils.SetAccentColor(val, val)
        Utils.Notify("Warna Aksen Menu", "Warna aksen panel menu diperbarui.", val)
    end)

    Components.AddChipSelector(page, "Warna Teks Panel Menu", {
        { Label = "Auto Kontras", Value = "Auto", Color = Color3.fromRGB(255, 220, 140) },
        { Label = "Putih Tulang", Value = Color3.fromRGB(255, 248, 240), Color = Color3.fromRGB(255, 248, 240) },
        { Label = "Emas Terang", Value = Color3.fromRGB(255, 195, 75), Color = Color3.fromRGB(255, 195, 75) },
        { Label = "Cyan Es", Value = Color3.fromRGB(115, 238, 255), Color = Color3.fromRGB(115, 238, 255) },
        { Label = "Hijau Mint", Value = Color3.fromRGB(120, 250, 175), Color = Color3.fromRGB(120, 250, 175) },
        { Label = "Hitam Pekat", Value = Color3.fromRGB(18, 14, 24), Color = Color3.fromRGB(18, 14, 24) },
    }, "Auto", 19, function(val)
        Theme.FontColorMode = val
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Warna Teks Menu", "Warna teks panel menu diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Latar Belakang Teks Menu (Adaptif)", {
        { Label = "Transparan", Value = "None", Color = Color3.fromRGB(90, 80, 110) },
        { Label = "Gelap Tipis", Value = Color3.fromRGB(16, 12, 24), Color = Color3.fromRGB(16, 12, 24) },
        { Label = "Ungu Malam", Value = Color3.fromRGB(38, 20, 62), Color = Color3.fromRGB(38, 20, 62) },
        { Label = "Coklat Labu", Value = Color3.fromRGB(54, 26, 12), Color = Color3.fromRGB(54, 26, 12) },
        { Label = "Terang Kabut", Value = Color3.fromRGB(238, 234, 246), Color = Color3.fromRGB(238, 234, 246) },
        { Label = "Emas Gelap", Value = Color3.fromRGB(56, 38, 10), Color = Color3.fromRGB(56, 38, 10) },
    }, "None", 20, function(val)
        if val == "None" then
            Theme.FontBgEnabled = false
        else
            Theme.FontBgEnabled = true
            Theme.FontBgColor = val
            Theme.FontBgTransparency = 0.62
        end
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Latar Teks Menu", "Latar belakang teks menu diperbarui.", Theme.Accent)
    end)

    Components.AddSectionHeader(page, "Kontrol Pintasan & Pembersihan Panel", 21)

    Components.AddButton(page, "Sembunyikan Panel Menu (RightShift)", "Atau ketuk ikon tengkorak 3D di layar kapan saja", "Sembunyi", 22, function()
        App.IsOpen = false
        UI.MainFrame.Visible = false
    end)

    Components.AddButton(page, "Matikan & Hapus Script (Unload Hub)", "Putus semua loop, pulihkan karakter/map, dan tutup GUI", "Unload", 23, function()
        if typeof(getgenv) == "function" and type(getgenv().BSS_UnloadOld) == "function" then
            getgenv().BSS_UnloadOld()
        end
    end)
end

-- ============================================================================
-- TAB 10: INFORMASI (KREATOR, KOMUNITAS DISCORD & DUKUNGAN DONASI)
-- ============================================================================
do
    local page = Components.CreateTab("Informasi", "ℹ", 10)
    Components.AddSectionHeader(page, "Informasi Pembuat & Dukungan", 1)

    local heroCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 96),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(heroCard, 10)
    local heroStroke = Utils.AddStroke(heroCard, Theme.Accent, 1.2, 0.25)
    Utils.RegisterAccent(heroStroke, "Color")

    Utils.CreateSkull3D(heroCard, 56, UDim2.new(0, 42, 0.5, 0), Vector2.new(0.5, 0.5), 16, true, false, 0.4)

    local hTitle = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -96, 0, 22),
        Position = UDim2.new(0, 82, 0, 12),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "BimSakSin Hub v3.0 — Luxury Skull 3D HD",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterText(hTitle, true, Theme.TextPrimary)

    local hSub1 = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -96, 0, 18),
        Position = UDim2.new(0, 82, 0, 36),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Creator: BimSakSin  •  Universal Luau Hub",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterText(hSub1, false, Theme.TextSecondary)

    local hSub2 = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -96, 0, 22),
        Position = UDim2.new(0, 82, 0, 56),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "Presiden indonesia Prabowo Subianto Djojohadikusumo",
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterAccent(hSub2, "TextColor3")

    Components.AddSectionHeader(page, "Tautan Resmi Komunitas & Donasi", 3)

    Components.AddButton(page, "Tautan Komunitas Discord Resmi", App.DiscordUrl, "Salin Link", 4, function()
        if Utils.CopyText(App.DiscordUrl) then
            Utils.Notify("Discord Tersalin", "Link invite Discord disalin: " .. App.DiscordUrl, Theme.Success)
        else
            Utils.Notify("Discord Resmi", App.DiscordUrl, Theme.Accent)
        end
    end)

    Components.AddButton(page, "Tautan Donasi & Dukungan Developer", App.DonationUrl, "Salin Link", 5, function()
        if Utils.CopyText(App.DonationUrl) then
            Utils.Notify("Link Donasi Tersalin", "Link dukungan disalin: " .. App.DonationUrl, Theme.Success)
        else
            Utils.Notify("Link Dukungan", App.DonationUrl, Theme.Accent)
        end
    end)
end

-- ============================================================================
-- 16. WINDOW CONTROLS (MINIMIZE MENYESUAIKAN UKURAN JUDUL, CLOSE, HOTKEY & RESIZE)
-- ============================================================================
do
    local function setWindowVisible(openState)
        App.IsOpen = openState
        UI.MainFrame.Visible = openState
    end

    local function computeMinimizedWidth()
        local titleW = 148
        if UI.TitleLabel then
            pcall(function()
                titleW = math.max(titleW, UI.TitleLabel.TextBounds.X)
            end)
        end
        local badgeW = (UI.VerifiedBadge and UI.VerifiedBadge.Visible) and 23 or 0
        local leftPad = 62
        local rightButtonsW = 86
        local minWidth = math.floor(leftPad + titleW + badgeW + rightButtonsW)
        local vp = UI.ScreenGui and UI.ScreenGui.AbsoluteSize or Vector2.new(1280, 720)
        local maxAllowed = (vp.X > 0) and math.max(210, vp.X - 24) or 420
        return math.clamp(minWidth, 210, maxAllowed)
    end

    local function applyMinimizeState(minimized)
        App.IsMinimized = minimized
        if minimized then
            local minW = computeMinimizedWidth()
            if UI.SubtitleBanner then UI.SubtitleBanner.Visible = false end
            if UI.TitleRow then
                UI.TitleRow.Size = UDim2.new(1, -142, 0, 32)
                UI.TitleRow.Position = UDim2.new(0, 54, 0.5, -16)
            end
            UI.Sidebar.Visible = false
            UI.ContentContainer.Visible = false
            UI.ResizeHandle.Visible = false
            UI.Topbar.Size = UDim2.new(1, 0, 1, 0)
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, minW, 0, 44)
            })
            UI.MinimizeBtn.Text = "+"
        else
            if UI.SubtitleBanner then UI.SubtitleBanner.Visible = true end
            if UI.TitleRow then
                UI.TitleRow.Size = UDim2.new(1, -142, 0, 22)
                UI.TitleRow.Position = UDim2.new(0, 54, 0, 6)
            end
            UI.Topbar.Size = UDim2.new(1, 0, 0, 54)
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, App.ExpandedWidth, 0, App.ExpandedHeight)
            })
            task.delay(0.14, function()
                if not App.IsMinimized then
                    UI.Sidebar.Visible = true
                    UI.ContentContainer.Visible = true
                    UI.ResizeHandle.Visible = true
                end
            end)
            UI.MinimizeBtn.Text = "-"
        end
    end

    UI.FloatingToggle.MouseButton1Click:Connect(function()
        if App.IsMinimized then
            applyMinimizeState(false)
            setWindowVisible(true)
        else
            setWindowVisible(not App.IsOpen)
        end
    end)

    UI.MinimizeBtn.MouseButton1Click:Connect(function()
        applyMinimizeState(not App.IsMinimized)
    end)

    UI.CloseBtn.MouseButton1Click:Connect(function()
        setWindowVisible(false)
    end)

    Utils.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            setWindowVisible(not App.IsOpen)
            return
        end

        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.Space and State.InfiniteJumpEnabled then
            local _, hum = Utils.GetCharacter()
            if hum and hum.Health > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 and State.ClickTPEnabled and not App.IsOpen then
            local mouse = LocalPlayer:GetMouse()
            if mouse and mouse.Hit then
                local hitPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
                local ok, dist = Utils.SafeTeleport(CFrame.new(hitPos))
                if ok then
                    Utils.Notify("Click Teleport", "Berpindah ke titik klik (" .. TeleportAPI.FormatDistance(dist) .. ")!", Theme.Success)
                end
            end
        end
    end))

    local resizing = false
    local activeResizeInput = nil
    local resizeStart = nil
    local startSize = nil

    local function applyResponsiveLayout(w, h)
        local sidebarW = (w < 500) and math.clamp(math.floor(w * 0.30), 112, 166) or 166
        UI.Sidebar.Size = UDim2.new(0, sidebarW, 1, -54)
        UI.Sidebar.Position = UDim2.new(0, 0, 0, 54)
        UI.ContentContainer.Size = UDim2.new(1, -sidebarW, 1, -54)
        UI.ContentContainer.Position = UDim2.new(0, sidebarW, 0, 54)
    end

    Utils.Track(UI.ResizeHandle.InputBegan:Connect(function(input)
        if App.IsMinimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            activeResizeInput = input
            resizeStart = input.Position
            startSize = Vector2.new(UI.MainFrame.AbsoluteSize.X, UI.MainFrame.AbsoluteSize.Y)
        end
    end))

    Utils.Track(UserInputService.InputChanged:Connect(function(input)
        if not resizing or not activeResizeInput or not resizeStart or not startSize then return end
        local isMatchingMouse = (activeResizeInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)
        local isMatchingTouch = (input == activeResizeInput)

        if isMatchingMouse or isMatchingTouch then
            local delta = input.Position - resizeStart
            local vp = UI.ScreenGui.AbsoluteSize
            local maxW = (vp.X > 0) and math.max(300, vp.X - 24) or 900
            local maxH = (vp.Y > 0) and math.max(220, vp.Y - 24) or 700
            local newW = math.clamp(startSize.X + delta.X, 300, maxW)
            local newH = math.clamp(startSize.Y + delta.Y, 220, maxH)
            App.ExpandedWidth = newW
            App.ExpandedHeight = newH
            UI.MainFrame.Size = UDim2.new(0, newW, 0, newH)
            applyResponsiveLayout(newW, newH)
        end
    end))

    Utils.Track(UserInputService.InputEnded:Connect(function(input)
        if resizing and (input == activeResizeInput or (activeResizeInput and activeResizeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            resizing = false
            activeResizeInput = nil
        end
    end))

    applyResponsiveLayout(App.ExpandedWidth, App.ExpandedHeight)
end

-- ============================================================================
-- 17. MASTER RUNTIME LOOPS (Heartbeat Physics/Combat/Carry + Telemetry + 3D Skulls)
-- ============================================================================
do
    local espAccum = 0
    local worldScanAccum = 0
    local telemetryAccum = 0

    Utils.Track(RunService.Heartbeat:Connect(function(dt)
        SafeEngine.Run("HeartbeatLoop", function()
            if State.WalkSpeed ~= 16 or State.JumpPower ~= 50 then
                local _, hum = Utils.GetCharacter()
                if hum then
                    if State.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.WalkSpeed then
                        hum.WalkSpeed = State.WalkSpeed
                    end
                    if State.JumpPower ~= 50 then
                        if not hum.UseJumpPower then hum.UseJumpPower = true end
                        if hum.JumpPower ~= State.JumpPower then hum.JumpPower = State.JumpPower end
                    end
                end
            end

            if State.Gravity ~= State.OriginalGravity and workspace.Gravity ~= State.Gravity then
                workspace.Gravity = State.Gravity
            end

            if State.FlyEnabled then
                Physics.StepSmoothFly(dt)
            elseif Physics.FlyLV or Physics.FlyBV then
                Physics.CleanupFly()
            end

            if State.NoclipEnabled then
                local char = Utils.GetCharacter()
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if Physics.NoclipCache[part] == nil then
                                Physics.NoclipCache[part] = part.CanCollide
                            end
                            if part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            elseif next(Physics.NoclipCache) ~= nil then
                Physics.RestoreNoclip()
            end

            if Combat.MeleeImmunity then
                Protection.StepMeleeImmunity()
            end

            if Combat.DisasterImmunity then
                Protection.StepDisasterImmunity()
            end

            if Combat.HungerThirstGuard then
                Protection.StepHungerThirstGuard()
            end

            if Combat.AutoParryEnabled then
                Combat.StepAutoParry()
            end

            if Carry.Enabled then
                Carry.Step()
            end

            if State.SpectatingPlayer then
                TeleportAPI.StepRemoteView()
            end

            espAccum = espAccum + dt
            if espAccum >= 0.08 then
                espAccum = 0
                ESP.UpdateAll()
                if UI.UpdatePlayerDistances then
                    UI.UpdatePlayerDistances()
                end
            end

            worldScanAccum = worldScanAccum + dt
            if worldScanAccum >= 0.45 then
                worldScanAccum = 0
                if ItemESP.Enabled then
                    ItemESP.ScanAndRender()
                end
                if GeneratorESP.Enabled then
                    GeneratorESP.ScanAndRender()
                end
            end
        end)
    end))

    Utils.Track(RunService.RenderStepped:Connect(function()
        SafeEngine.Run("RenderSteppedLoop", function()
            local cam = workspace.CurrentCamera
            if cam and State.CameraFOV ~= 70 and math.abs(cam.FieldOfView - State.CameraFOV) > 0.1 then
                cam.FieldOfView = State.CameraFOV
            end

            if State.FullbrightEnabled then
                Lighting.Brightness = 3
                Lighting.GlobalShadows = false
            end

            if State.NoFogEnabled then
                Lighting.FogStart = 1e6
                Lighting.FogEnd = 1e6
            end

            if Combat.FOVCircle then
                Combat.FOVCircle.Visible = Combat.ShowFOVCircle and Combat.AimbotEnabled
                Combat.FOVCircle.Size = UDim2.new(0, Combat.FOVRadius * 2, 0, Combat.FOVRadius * 2)
            end

            local hasTarget = false
            if Combat.AimbotEnabled and cam then
                local shouldLock = false
                if Combat.AimbotMode == "Always" then
                    shouldLock = true
                elseif Combat.AimbotMode == "HoldRMB" then
                    shouldLock = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    local char = Utils.GetCharacter(LocalPlayer)
                    local equippedTool = char and char:FindFirstChildOfClass("Tool")
                    local mouseDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                    shouldLock = (equippedTool ~= nil) or mouseDown
                end

                if shouldLock then
                    local targetPlr, aimPart = Combat.FindBestTarget()
                    Combat.CurrentTarget = targetPlr
                    if aimPart then
                        hasTarget = true
                        local currentCF = cam.CFrame
                        local desiredCF = CFrame.lookAt(currentCF.Position, aimPart.Position)
                        local alpha = math.clamp(Combat.Smoothness, 0.05, 1)
                        cam.CFrame = currentCF:Lerp(desiredCF, alpha)

                        local _, isGun = Combat.GetEquippedRangedWeapon()
                        if Combat.RGBLaserEnabled and isGun then
                            local char = Utils.GetCharacter(LocalPlayer)
                            local tool = char and char:FindFirstChildOfClass("Tool")
                            local muzzle = tool and (tool:FindFirstChild("Muzzle", true) or tool:FindFirstChild("Barrel", true) or tool:FindFirstChild("FirePoint", true) or tool:FindFirstChild("Handle"))
                            local startPos = muzzle and muzzle.Position or (cam.CFrame.Position + cam.CFrame.LookVector * 2 - Vector3.new(0, 0.4, 0))
                            Combat.UpdateLaser(startPos, aimPart.Position)
                        else
                            Combat.HideLaser()
                        end
                    end
                else
                    Combat.CurrentTarget = nil
                end
            else
                Combat.CurrentTarget = nil
            end

            if not hasTarget then
                Combat.HideLaser()
            end

            local t = os.clock()
            if UI.SubLabelGradient then
                UI.SubLabelGradient.Offset = Vector2.new(((t * 0.45) % 1.6) - 0.8, 0)
            end

            for _, sk in ipairs(UI.Skulls) do
                if sk.Holder and sk.Holder.Parent then
                    local p = t * (sk.IsHero and 2.6 or 2.0) + sk.Phase
                    local bobY = math.sin(p) * (sk.IsHero and 2.2 or 1.4)
                    local tiltZ = math.sin(p * 0.8) * (sk.IsHero and 4.5 or 3.0)
                    sk.Holder.Position = UDim2.new(
                        sk.BasePos.X.Scale,
                        sk.BasePos.X.Offset,
                        sk.BasePos.Y.Scale,
                        sk.BasePos.Y.Offset + bobY
                    )
                    sk.Holder.Rotation = tiltZ

                    if sk.Jaw and sk.JawBasePos then
                        local jawDrop = math.max(0, math.sin(p * 1.4)) * 0.032
                        sk.Jaw.Position = UDim2.new(
                            sk.JawBasePos.X.Scale,
                            sk.JawBasePos.X.Offset,
                            sk.JawBasePos.Y.Scale + jawDrop,
                            sk.JawBasePos.Y.Offset
                        )
                    end

                    local glowPulse = 0.5 + 0.5 * math.sin(p * 2.2)
                    local eyeCol = Color3.fromRGB(255, 118, 26):Lerp(Color3.fromRGB(255, 224, 96), glowPulse)
                    if sk.EyeLeft then sk.EyeLeft.BackgroundColor3 = eyeCol end
                    if sk.EyeRight then sk.EyeRight.BackgroundColor3 = eyeCol end
                    if sk.RingStroke then
                        sk.RingStroke.Transparency = 0.22 + (1 - glowPulse) * 0.35
                    end
                end
            end
        end)
    end))

    Utils.Track(RunService.Heartbeat:Connect(function(dt)
        telemetryAccum = telemetryAccum + dt
        if telemetryAccum < 0.5 then return end
        telemetryAccum = 0

        SafeEngine.Run("TelemetryUpdate", function()
            local fps = math.clamp(math.floor((1 / math.max(dt, 0.001)) + 0.5), 1, 999)
            if UI.TelemetryLabels.FPS then
                UI.TelemetryLabels.FPS.Text = tostring(fps) .. " FPS"
            end

            if UI.TelemetryLabels.Ping then
                local pingVal = 0
                pcall(function()
                    pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                end)
                UI.TelemetryLabels.Ping.Text = tostring(pingVal) .. " ms"
            end

            if UI.TelemetryLabels.Memory then
                local memMB = 0
                pcall(function()
                    memMB = math.floor(Stats:GetTotalMemoryUsageMb() + 0.5)
                end)
                UI.TelemetryLabels.Memory.Text = tostring(memMB) .. " MB"
            end

            if UI.TelemetryLabels.Players then
                UI.TelemetryLabels.Players.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers)
            end

            AntiDetect.UpdateStatusBanner()

            if UI.TelemetryLabels.WorldCoord then
                local _, _, root = Utils.GetCharacter(LocalPlayer)
                if root then
                    local p = root.Position
                    local worldTag = TeleportAPI.DetectSubWorldName(LocalPlayer, p)
                    UI.TelemetryLabels.WorldCoord.Text = string.format(
                        "  Posisi: (%.0f, %.0f, %.0f) • %s\n  Jarak Teleport Terakhir: %s",
                        p.X, p.Y, p.Z,
                        worldTag,
                        TeleportAPI.FormatDistance(State.LastTeleportDistance)
                    )
                end
            end
        end)
    end))
end

-- ============================================================================
-- 18. UNLOAD CLEANUP REGISTRY & INITIALIZATION
-- ============================================================================
local function unloadHub()
    AntiDetect.RestoreAll()
    State.TeleportToken = State.TeleportToken + 1
    State.IsTeleportLocking = false
    State.FlyEnabled = false
    State.NoclipEnabled = false
    State.InfiniteJumpEnabled = false
    State.ClickTPEnabled = false
    ESP.Enabled = false
    ItemESP.Enabled = false
    GeneratorESP.Enabled = false
    Combat.AimbotEnabled = false
    Combat.AutoParryEnabled = false
    Combat.MeleeImmunity = false
    Combat.DisasterImmunity = false
    Combat.HungerThirstGuard = false
    Carry.Stop()
    Emotes.Stop()
    TeleportAPI.StopRemoteView(false)

    Physics.CleanupFly()
    Physics.RestoreNoclip()
    Protection.RestoreEnemyHitboxes()
    Protection.RestoreDisasterImmunity()
    ESP.ClearAll()
    ItemESP.ClearAll()
    GeneratorESP.ClearAll()

    local _, hum, root = Utils.GetCharacter()
    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    workspace.Gravity = State.OriginalGravity

    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = 70
        if hum then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            workspace.CurrentCamera.CameraSubject = hum
        end
    end

    Lighting.Brightness = State.OriginalLighting.Brightness
    Lighting.ClockTime = State.OriginalLighting.ClockTime
    Lighting.FogStart = State.OriginalLighting.FogStart
    Lighting.FogEnd = State.OriginalLighting.FogEnd
    Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
    Lighting.Ambient = State.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
    if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance and State.OriginalAtmosphere.Instance.Parent then
        State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
    end

    if Combat.LaserPart then
        pcall(function() Combat.LaserPart:Destroy() end)
        Combat.LaserPart = nil
    end

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    if UI.ScreenGui then
        pcall(function() UI.ScreenGui:Destroy() end)
    end
end

if typeof(getgenv) == "function" then
    getgenv().BSS_UnloadOld = unloadHub
end

Utils.Track(LocalPlayer.CharacterAdded:Connect(function(char)
    task.defer(function()
        local hum = char:WaitForChild("Humanoid", 5)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then
            Combat.LastSafePosition = root.Position
            Combat.LastSafeCFrame = root.CFrame
        end
        if hum then
            if State.WalkSpeed ~= 16 then hum.WalkSpeed = State.WalkSpeed end
            if State.JumpPower ~= 50 then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
        if Combat.DisasterImmunity then
            Protection.EnsureDisasterForceField(char)
        end
        if State.FlyEnabled and hum then
            hum.PlatformStand = true
            hum.AutoRotate = false
        end
        if State.SpectatingPlayer then
            TeleportAPI.StartRemoteView(State.SpectatingPlayer)
        end
    end)
end))

do
    local _, _, initRoot = Utils.GetCharacter(LocalPlayer)
    if initRoot then
        Combat.LastSafePosition = initRoot.Position
        Combat.LastSafeCFrame = initRoot.CFrame
    end
end

AntiDetect.RefreshCloak(false)
Components.SwitchTab("Dashboard")
Utils.ApplyMenuFontAndColors()
GeoLangAPI.RefreshBannerText()
GeoLangAPI.FetchRealTimeGeoIP(true)
Utils.Notify("BimSakSin Hub v3.0", "Presiden indonesia Prabowo Subianto Djojohadikusumo 💀", Theme.Accent)
