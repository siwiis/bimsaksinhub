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
- Melee Immunity + Hunger & Thirst Guard (Tahan Lapar & Haus)
- Interactive Replicated Carry System (Visible to Other Players + Carry/Lepas Buttons)
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
    cleanupContainer(game:GetService("CoreGui"))

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
    Subtitle = "Mendeteksi IP & Lokasi Pemain...",
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
    StatusText = "🌐 IP: Mendeteksi... | Lokasi: Memuat...",
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
    local langBadge = string.upper(GeoLangAPI.CurrentLang or "ID")
    if GeoLangAPI.IPAddress == "Detecting..." then
        GeoLangAPI.StatusText = GeoLangAPI.T("detecting")
    else
        GeoLangAPI.StatusText = string.format(
            GeoLangAPI.T("ip_fmt"),
            GeoLangAPI.IPAddress,
            GeoLangAPI.City,
            GeoLangAPI.Country,
            GeoLangAPI.CountryCode,
            langBadge
        )
    end
    App.Subtitle = GeoLangAPI.StatusText
    if UI.SubLabel and UI.SubLabel.Parent then
        UI.SubLabel.Text = GeoLangAPI.StatusText
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

    -- Kebal Pukulan & Survival
    MeleeImmunity = false,
    HungerThirstGuard = false,
    TouchedPartsCache = {},
    EnemyToolParts = {},

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
            for _, name in ipairs({ "BSS_FlyLinearVel", "BSS_FlyAlignOri", "BSS_FlyVelocity", "BSS_FlyGyro" }) do
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
        anchor.Name = "BSS_RemoteViewAnchor"
        anchor.Size = Vector3.new(1, 1, 1)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.Parent = workspace
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
        for _, objName in ipairs({ "BSS_FlyLinearVel", "BSS_FlyAlignOri", "BSS_FlyAttachment", "BSS_FlyVelocity", "BSS_FlyGyro" }) do
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
        local att = Instance.new("Attachment")
        att.Name = "BSS_FlyAttachment"
        att.Parent = root
        Physics.FlyAttachment = att

        local lv = Instance.new("LinearVelocity")
        lv.Name = "BSS_FlyLinearVel"
        lv.Attachment0 = att
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.MaxForce = 9e9
        lv.VectorVelocity = Vector3.zero
        lv.Parent = root
        Physics.FlyLV = lv

        local ao = Instance.new("AlignOrientation")
        ao.Name = "BSS_FlyAlignOri"
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
    UI.ScreenGui = Utils.Create("ScreenGui", {
        Name = App.GuiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, getGuiParent())

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
        local copyPayload = string.format(
            "IP: %s | Kota: %s | Region: %s | Negara: %s (%s) | Bahasa: %s",
            GeoLangAPI.IPAddress,
            GeoLangAPI.City,
            GeoLangAPI.Region,
            GeoLangAPI.Country,
            GeoLangAPI.CountryCode,
            GeoLangAPI.GetLanguageLabel(GeoLangAPI.CurrentLang)
        )
        if Utils.CopyText(copyPayload) then
            Utils.Notify("Geo-IP Real-Time", GeoLangAPI.T("ip_copied") .. "\n" .. copyPayload, Theme.Success)
        else
            Utils.Notify("Geo-IP Real-Time", copyPayload, Theme.Accent)
        end
        GeoLangAPI.FetchRealTimeGeoIP(false)
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

    UI.MinimizeBtn = createTopBtn("—", -76, Theme.Accent)
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
        Name = "BSS_ESP_Folder",
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
    ItemESP.Folder = Utils.Create("Folder", { Name = "BSS_ItemESP_Folder" }, UI.ScreenGui)
    GeneratorESP.Folder = Utils.Create("Folder", { Name = "BSS_GenESP_Folder" }, UI.ScreenGui)

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
        Name = "BSS_AimFOV",
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
                Name = "BSS_RGB_AimLaser",
                Anchored = true,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                CastShadow = false,
                Material = Enum.Material.Neon,
                Transparency = 0.15,
                Size = Vector3.new(0.08, 0.08, 1),
            }, workspace)
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
-- 15. PROTECTION & SURVIVAL ENGINE (Anti-AFK, Melee Immunity, Hunger & Thirst)
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

    Components.AddToggle(page, "Penjaga Bertahan Hidup: Tahan Lapar & Haus", "Menjaga indikator lapar (Hunger) dan haus (Thirst) tetap penuh otomatis", false, 14, function(on)
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

    for idx, d in ipairs(Emotes.Catalog) do
        local btn = Utils.Create("TextButton", {
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.22,
            Font = Theme.FontBold,
            Text = "🎵 " .. d.Label,
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 15,
        }, danceGrid)
        Utils.AddCorner(btn, 8)
        local stroke = Utils.AddStroke(btn, Theme.Accent, 1, 0.45)
        Utils.RegisterAccent(stroke, "Color")
        Utils.RegisterText(btn, true, Theme.TextPrimary)

        btn.MouseButton1Click:Connect(function()
            Emotes.PlayPreset(d)
        end)
    end
end

-- ============================================================================
-- UNLIMITED SPEED & PHYSICS ENGINE (SpeedAPI - Tanpa Batas Maksimal)
-- ============================================================================
local SpeedAPI = {}

function SpeedAPI.ParseUnlimitedNumber(rawText, fallbackVal)
    local cleaned = tostring(rawText or ""):gsub("[^%d%.]", "")
    local num = tonumber(cleaned)
    if num and num == num and num >= 0 and num < math.huge then
        return num
    end
    return fallbackVal
end

function SpeedAPI.SetWalkSpeed(speedVal)
    local val = math.max(0, tonumber(speedVal) or 16)
    State.WalkSpeed = val
    local _, hum = Utils.GetCharacter()
    if hum then
        hum.WalkSpeed = val
    end
    return val
end

function SpeedAPI.SetJumpPower(jumpVal)
    local val = math.max(0, tonumber(jumpVal) or 50)
    State.JumpPower = val
    local _, hum = Utils.GetCharacter()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = val
        if hum.JumpHeight then
            hum.JumpHeight = math.max(7.2, (val * val) / (2 * math.max(1, workspace.Gravity)))
        end
    end
    return val
end

function SpeedAPI.SetFlySpeed(flyVal)
    local val = math.max(1, tonumber(flyVal) or 65)
    State.FlySpeed = val
    return val
end

-- ============================================================================
-- TAB 6: GERAK & KECEPATAN (Unlimited Speed API, Smooth Fly & NoClip)
-- ============================================================================
do
    local page = Components.CreateTab("Movement", "⚡", 6)
    Components.AddSectionHeader(page, "Kecepatan Lari & Lompat Tanpa Batas (Unlimited Speed API)", 1)

    local function createUnlimitedInputCard(titleText, placeholderText, defaultNum, order, onApply)
        local card = Utils.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 62),
            BackgroundColor3 = Theme.BgCard,
            BackgroundTransparency = 0.26,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 14,
        }, page)
        Utils.AddCorner(card, 9)
        Utils.AddStroke(card, Theme.BorderSubtle, 1, 0.3)

        local lbl = Utils.Create("TextLabel", {
            Size = UDim2.new(0.65, 0, 0, 18),
            Position = UDim2.new(0, 12, 0, 6),
            BackgroundTransparency = 1,
            Font = Theme.FontBold,
            Text = GeoLangAPI.TranslateFeatureText(titleText),
            TextColor3 = Theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
        }, card)
        Utils.RegisterText(lbl, true, Theme.TextPrimary)
        GeoLangAPI.BindFeatureText(lbl, titleText)

        local activeValLbl = Utils.Create("TextLabel", {
            Size = UDim2.new(0.35, -12, 0, 18),
            Position = UDim2.new(0.65, 0, 0, 6),
            BackgroundTransparency = 1,
            Font = Theme.FontBold,
            Text = "Aktif: " .. tostring(defaultNum),
            TextColor3 = Theme.Accent,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 15,
        }, card)
        Utils.RegisterAccent(activeValLbl, "TextColor3")

        local inputBox = Utils.Create("TextBox", {
            Size = UDim2.new(1, -118, 0, 26),
            Position = UDim2.new(0, 10, 0, 29),
            BackgroundColor3 = Theme.BgControl,
            Font = Theme.FontFamily,
            PlaceholderText = placeholderText,
            PlaceholderColor3 = Theme.TextMuted,
            Text = tostring(defaultNum),
            TextColor3 = Theme.TextPrimary,
            TextSize = 11,
            ClearTextOnFocus = false,
            ZIndex = 15,
        }, card)
        Utils.AddCorner(inputBox, 6)
        Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, inputBox)

        local applyBtn = Utils.Create("TextButton", {
            Size = UDim2.new(0, 92, 0, 26),
            Position = UDim2.new(1, -102, 0, 29),
            BackgroundColor3 = Theme.Accent,
            Font = Theme.FontBold,
            Text = "Terapkan",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            AutoButtonColor = false,
            ZIndex = 15,
        }, card)
        Utils.AddCorner(applyBtn, 6)
        Utils.RegisterAccent(applyBtn, "BackgroundColor3")

        local function commitValue(newVal, silent)
            local applied = onApply(newVal)
            inputBox.Text = tostring(applied)
            activeValLbl.Text = "Aktif: " .. tostring(applied)
            if not silent then
                Utils.Notify("Kecepatan Diatur", GeoLangAPI.TranslateFeatureText(titleText) .. " diatur ke: " .. tostring(applied), Theme.Success)
            end
        end

        applyBtn.MouseButton1Click:Connect(function()
            local parsed = SpeedAPI.ParseUnlimitedNumber(inputBox.Text, defaultNum)
            commitValue(parsed, false)
        end)

        inputBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local parsed = SpeedAPI.ParseUnlimitedNumber(inputBox.Text, defaultNum)
                commitValue(parsed, false)
            end
        end)

        return {
            SetValue = function(v, silent)
                commitValue(v, silent)
            end,
        }
    end

    local wsControl = createUnlimitedInputCard(
        "Kecepatan Lari / Jalan (WalkSpeed Unlimited)",
        "Masukkan angka bebas (mis. 50, 500, 10000)...",
        16,
        2,
        function(val)
            return SpeedAPI.SetWalkSpeed(val)
        end
    )

    local jpControl = createUnlimitedInputCard(
        "Daya Lompat Tinggi (JumpPower Unlimited)",
        "Masukkan angka bebas (mis. 120, 1000, 50000)...",
        50,
        3,
        function(val)
            return SpeedAPI.SetJumpPower(val)
        end
    )

    local maxGrav = math.max(300, math.ceil(State.OriginalGravity))
    local gravSlider = Components.AddSlider(page, "Gravitasi Dunia (Workspace Gravity)", 0, maxGrav, State.OriginalGravity, 1, 4, function(val)
        State.Gravity = val
        workspace.Gravity = val
    end)

    local flyControl
    local origGravStr = string.format("%.1f", State.OriginalGravity)
    Components.AddButton(page, "Reset Kecepatan & Fisika ke Bawaan", "Kembalikan WalkSpeed (16), JumpPower (50), FlySpeed (65), Gravity (" .. origGravStr .. ")", "Reset Semua", 5, function()
        wsControl.SetValue(16, true)
        jpControl.SetValue(50, true)
        if flyControl then
            flyControl.SetValue(65, true)
        end
        gravSlider.SetValue(State.OriginalGravity, true)
        Utils.Notify("Fisika Direset", "Nilai kecepatan & gravitasi dikembalikan ke bawaan.", Theme.Success)
    end)

    Components.AddSectionHeader(page, "Mode Terbang Bebas & Penembus Dinding", 6)

    Components.AddToggle(page, "Gerak Udara: Terbang Bebas (Admin Fly)", "Terbang bebas dan mulus ke segala arah kamera di PC maupun Mobile", false, 7, function(on)
        State.FlyEnabled = on
        if on then
            local _, hum = Utils.GetCharacter()
            if hum and hum.Sit then
                hum.Sit = false
            end
        else
            Physics.CleanupFly()
        end
        Utils.Notify("Terbang Bebas", on and "Mode terbang halus aktif." or "Mode terbang dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    flyControl = createUnlimitedInputCard(
        "Kecepatan Terbang Bebas (FlySpeed Unlimited)",
        "Masukkan kecepatan terbang bebas (mis. 150, 2000, 50000)...",
        65,
        8,
        function(val)
            return SpeedAPI.SetFlySpeed(val)
        end
    )

    Components.AddToggle(
        page,
        "Gerak Fisika: Tembus Dinding (NoClip)",
        "tidak disarankan untuk fitur NoClip ingin menembus tetapi analog di tarik berlebihan, jika ingin menembus tarik analog secara perlahan-lahan",
        false,
        9,
        function(on)
            State.NoclipEnabled = on
            if not on then Physics.RestoreNoclip() end
            Utils.Notify("Tembus Dinding (NoClip)", on and "NoClip aktif (tarik analog perlahan saat menembus)." or "Kolisi dinding dipulihkan.", on and Theme.Warning or Theme.TextSecondary)
        end
    )

    Components.AddToggle(page, "Gerak Lompat: Lompat Udara Tanpa Batas", "Melompat berkali-kali di udara tanpa perlu menyentuh permukaan tanah", false, 10, function(on)
        State.InfiniteJumpEnabled = on
        Utils.Notify("Lompat Udara", on and "Lompat udara tanpa batas aktif." or "Lompat udara dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)
end

-- ============================================================================
-- TAB 7: TELEPORTASI BEBAS & VIEW LINTAS DUNIA (Unlimited Distance & Stream API)
-- ============================================================================
do
    local page = Components.CreateTab("Teleport", "⌖", 7)
    local TPUI = {
        WpDistanceLabels = {},
        PlayerRows = {},
    }

    Components.AddSectionHeader(page, "Telemetri Dunia & Teleport Bebas Tanpa Batas Jarak", 1)

    local posCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(posCard, 9)
    Utils.AddStroke(posCard, Theme.BorderSubtle, 1, 0.3)

    UI.TelemetryLabels.Coords = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -112, 0, 20),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "XYZ: 0.0, 0.0, 0.0",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
    }, posCard)

    TPUI.WorldStatusLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -112, 0, 18),
        Position = UDim2.new(0, 12, 0, 29),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Lokasi: Main World | Jarak TP Terakhir: 0 m",
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
    }, posCard)
    Utils.RegisterText(TPUI.WorldStatusLbl, false, Theme.TextSecondary)

    local copyPosBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 92, 0, 30),
        Position = UDim2.new(1, -104, 0.5, -15),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontBold,
        Text = "Salin CFrame",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, posCard)
    Utils.AddCorner(copyPosBtn, 6)

    copyPosBtn.MouseButton1Click:Connect(function()
        local _, _, root = Utils.GetCharacter()
        if root then
            local p = root.Position
            local str = string.format("CFrame.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
            if Utils.CopyText(str) then
                Utils.Notify("CFrame Disalin", str, Theme.Success)
            else
                Utils.Notify("Koordinat", str, Theme.Accent)
            end
        end
    end)

    local tpCoordCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(tpCoordCard, 9)
    Utils.AddStroke(tpCoordCard, Theme.BorderSubtle, 1, 0.3)

    local coordBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -116, 0, 26),
        Position = UDim2.new(0, 10, 0.5, -13),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = "Koordinat X, Y, Z bebas jarak (mis. 50000, 120, -85000)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, tpCoordCard)
    Utils.AddCorner(coordBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, coordBox)

    local goCoordBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 92, 0, 26),
        Position = UDim2.new(1, -102, 0.5, -13),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = "Teleport",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, tpCoordCard)
    Utils.AddCorner(goCoordBtn, 6)
    Utils.RegisterAccent(goCoordBtn, "BackgroundColor3")

    goCoordBtn.MouseButton1Click:Connect(function()
        local nums = {}
        for m in string.gmatch(coordBox.Text, "[%-]?%d+%.?%d*") do
            local n = tonumber(m)
            if n then table.insert(nums, n) end
        end
        if #nums >= 3 then
            local okTp, dist = Utils.SafeTeleport(CFrame.new(nums[1], nums[2], nums[3]))
            if okTp then
                Utils.Notify(
                    "Teleport Koordinat",
                    string.format("Berpindah ke (%.0f, %.0f, %.0f) • Jarak: %s", nums[1], nums[2], nums[3], TeleportAPI.FormatDistance(dist)),
                    Theme.Success
                )
            end
        else
            Utils.Notify("Format Koordinat", "Masukkan 3 angka koordinat X, Y, Z.", Theme.Warning)
        end
    end)

    local tpDistCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 4,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(tpDistCard, 9)
    Utils.AddStroke(tpDistCard, Theme.BorderSubtle, 1, 0.3)

    local distDashBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -132, 0, 26),
        Position = UDim2.new(0, 10, 0.5, -13),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = "Jarak Maju (Studs / Meter, tanpa batas)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "500",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, tpDistCard)
    Utils.AddCorner(distDashBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, distDashBox)

    local dashForwardBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 108, 0, 26),
        Position = UDim2.new(1, -118, 0.5, -13),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = "Maju (Studs)",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, tpDistCard)
    Utils.AddCorner(dashForwardBtn, 6)
    Utils.RegisterAccent(dashForwardBtn, "BackgroundColor3")

    dashForwardBtn.MouseButton1Click:Connect(function()
        local _, _, root = Utils.GetCharacter()
        if not root then return end
        local rawNum = tonumber((distDashBox.Text or ""):gsub("[^%-%.%d]", "")) or 500
        State.CustomTeleportDistance = rawNum
        local cam = workspace.CurrentCamera
        local forwardVec = (cam and cam.CFrame.LookVector) or root.CFrame.LookVector
        local destPos = root.Position + (forwardVec.Unit * rawNum)
        local okTp, dist = Utils.SafeTeleport(CFrame.new(destPos, destPos + forwardVec))
        if okTp then
            Utils.Notify("Teleport Jarak", "Melompat sejauh " .. TeleportAPI.FormatDistance(dist), Theme.Success)
        end
    end)

    local wpInputCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 5,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(wpInputCard, 9)
    Utils.AddStroke(wpInputCard, Theme.BorderSubtle, 1, 0.3)

    local wpNameBox = Utils.Create("TextBox", {
        Size = UDim2.new(1, -116, 0, 26),
        Position = UDim2.new(0, 10, 0.5, -13),
        BackgroundColor3 = Theme.BgControl,
        Font = Theme.FontFamily,
        PlaceholderText = "Nama Titik Simpan (Waypoint)...",
        PlaceholderColor3 = Theme.TextMuted,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 15,
    }, wpInputCard)
    Utils.AddCorner(wpNameBox, 6)
    Utils.Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, wpNameBox)

    local saveWpBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 92, 0, 26),
        Position = UDim2.new(1, -102, 0.5, -13),
        BackgroundColor3 = Theme.Accent,
        Font = Theme.FontBold,
        Text = "+ Simpan",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 15,
    }, wpInputCard)
    Utils.AddCorner(saveWpBtn, 6)
    Utils.RegisterAccent(saveWpBtn, "BackgroundColor3")

    local waypointListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, waypointListHolder)

    local function renderWaypoints()
        for _, child in ipairs(waypointListHolder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        table.clear(TPUI.WpDistanceLabels)
        local _, _, myRoot = Utils.GetCharacter()

        for idx, wp in ipairs(State.Waypoints) do
            local row = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = Theme.BgCard,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                LayoutOrder = idx,
                ZIndex = 14,
            }, waypointListHolder)
            Utils.AddCorner(row, 8)
            Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.25)

            local initDist = myRoot and (wp.CF.Position - myRoot.Position).Magnitude or 0
            local worldTag = TeleportAPI.DetectSubWorldName(nil, wp.CF.Position)

            local titleLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(1, -148, 0, 18),
                Position = UDim2.new(0, 10, 0, 5),
                BackgroundTransparency = 1,
                Font = Theme.FontBold,
                Text = "📌 " .. wp.Name,
                TextColor3 = Theme.TextPrimary,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 15,
            }, row)
            Utils.RegisterText(titleLbl, true, Theme.TextPrimary)

            local distLbl = Utils.Create("TextLabel", {
                Size = UDim2.new(1, -148, 0, 15),
                Position = UDim2.new(0, 10, 0, 23),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = string.format("Jarak: %s • %s", TeleportAPI.FormatDistance(initDist), worldTag),
                TextColor3 = Theme.TextSecondary,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 15,
            }, row)
            Utils.RegisterText(distLbl, false, Theme.TextSecondary)
            table.insert(TPUI.WpDistanceLabels, { Label = distLbl, CF = wp.CF, WorldTag = worldTag })

            local goBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 62, 0, 26),
                Position = UDim2.new(1, -104, 0.5, -13),
                BackgroundColor3 = Theme.Accent,
                Font = Theme.FontBold,
                Text = "Teleport",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 10,
                AutoButtonColor = false,
                ZIndex = 15,
            }, row)
            Utils.AddCorner(goBtn, 6)
            Utils.RegisterAccent(goBtn, "BackgroundColor3")

            local delBtn = Utils.Create("TextButton", {
                Size = UDim2.new(0, 30, 0, 26),
                Position = UDim2.new(1, -36, 0.5, -13),
                BackgroundColor3 = Theme.Danger,
                Font = Enum.Font.GothamBold,
                Text = "✕",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 15,
            }, row)
            Utils.AddCorner(delBtn, 6)

            goBtn.MouseButton1Click:Connect(function()
                local okTp, dist = Utils.SafeTeleport(wp.CF)
                if okTp then
                    Utils.Notify("Teleport Waypoint", wp.Name .. " (" .. TeleportAPI.FormatDistance(dist) .. ")", Theme.Success)
                end
            end)

            delBtn.MouseButton1Click:Connect(function()
                table.remove(State.Waypoints, idx)
                renderWaypoints()
            end)
        end
    end

    saveWpBtn.MouseButton1Click:Connect(function()
        local _, _, root = Utils.GetCharacter()
        if not root then return end
        local customName = wpNameBox.Text ~= "" and wpNameBox.Text or ("Titik #" .. tostring(#State.Waypoints + 1))
        table.insert(State.Waypoints, { Name = customName, CF = root.CFrame })
        wpNameBox.Text = ""
        renderWaypoints()
        Utils.Notify("Titik Disimpan", customName, Theme.Success)
    end)

    Components.AddSectionHeader(page, "View & Teleport Pemain Lintas Dunia (Tanpa Batas Jarak)", 7)

    local playerListHolder = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 8,
        ZIndex = 14,
    }, page)
    Utils.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, playerListHolder)

    local function refreshPlayerList()
        for _, child in ipairs(playerListHolder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        table.clear(TPUI.PlayerRows)

        local _, _, myRoot = Utils.GetCharacter()
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                count = count + 1
                local row = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundColor3 = Theme.BgCard,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    LayoutOrder = count,
                    ZIndex = 14,
                }, playerListHolder)
                Utils.AddCorner(row, 8)
                Utils.AddStroke(row, Theme.BorderSubtle, 1, 0.25)

                local nameLbl = Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -138, 0, 18),
                    Position = UDim2.new(0, 10, 0, 6),
                    BackgroundTransparency = 1,
                    Font = Theme.FontBold,
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 15,
                }, row)
                Utils.RegisterText(nameLbl, true, Theme.TextPrimary)

                local info = TeleportAPI.ResolvePlayerState(plr)
                local initTelemetry = "Dunia: Mencari posisi..."
                if info then
                    local distVal = myRoot and (info.Position - myRoot.Position).Magnitude or 0
                    initTelemetry = string.format("Jarak: %s | %s", TeleportAPI.FormatDistance(distVal), info.WorldName)
                end

                local telemetryLbl = Utils.Create("TextLabel", {
                    Size = UDim2.new(1, -138, 0, 16),
                    Position = UDim2.new(0, 10, 0, 25),
                    BackgroundTransparency = 1,
                    Font = Theme.FontFamily,
                    Text = initTelemetry,
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 15,
                }, row)
                Utils.RegisterText(telemetryLbl, false, Theme.TextSecondary)

                local isViewingThis = (State.SpectatingPlayer == plr)
                local specBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 56, 0, 28),
                    Position = UDim2.new(1, -126, 0.5, -14),
                    BackgroundColor3 = isViewingThis and Theme.Warning or Theme.BgControl,
                    Font = Theme.FontBold,
                    Text = isViewingThis and "Stop" or "Lihat",
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 15,
                }, row)
                Utils.AddCorner(specBtn, 6)

                local tpBtn = Utils.Create("TextButton", {
                    Size = UDim2.new(0, 60, 0, 28),
                    Position = UDim2.new(1, -66, 0.5, -14),
                    BackgroundColor3 = Theme.Accent,
                    Font = Theme.FontBold,
                    Text = "Ke Sini",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 15,
                }, row)
                Utils.AddCorner(tpBtn, 6)
                Utils.RegisterAccent(tpBtn, "BackgroundColor3")

                TPUI.PlayerRows[plr] = {
                    TelemetryLbl = telemetryLbl,
                    SpecBtn = specBtn,
                }

                specBtn.MouseButton1Click:Connect(function()
                    if State.SpectatingPlayer == plr then
                        TeleportAPI.StopRemoteView(true)
                        refreshPlayerList()
                    else
                        local okView, viewInfo = TeleportAPI.StartRemoteView(plr)
                        if okView then
                            refreshPlayerList()
                            local worldInfo = viewInfo and (" [" .. viewInfo.WorldName .. "]") or ""
                            Utils.Notify("Kamera Mengintip", "Melihat " .. plr.DisplayName .. worldInfo, Theme.Accent)
                        end
                    end
                end)

                tpBtn.MouseButton1Click:Connect(function()
                    local liveInfo = TeleportAPI.ResolvePlayerState(plr)
                    if not liveInfo then
                        Utils.Notify("Pemain Belum Siap", plr.DisplayName .. " belum memiliki posisi dunia.", Theme.Warning)
                        return
                    end
                    local okTp, dist = Utils.SafeTeleport(liveInfo.CFrame * CFrame.new(0, 0.5, 3), plr)
                    if okTp then
                        Utils.Notify(
                            "Teleport ke Pemain",
                            string.format("Berpindah ke %s (%s • %s)", plr.DisplayName, TeleportAPI.FormatDistance(dist), liveInfo.WorldName),
                            Theme.Success
                        )
                    end
                end)
            end
        end

        if count == 0 then
            local empty = Utils.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.BgCard,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                ZIndex = 14,
            }, playerListHolder)
            Utils.AddCorner(empty, 8)
            Utils.Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Theme.FontFamily,
                Text = "Tidak ada pemain lain di server saat ini.",
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                ZIndex = 15,
            }, empty)
        end
    end

    function TPUI.UpdateLiveDistances()
        local _, _, myRoot = Utils.GetCharacter()
        local myPos = myRoot and myRoot.Position

        if TPUI.WorldStatusLbl and TPUI.WorldStatusLbl.Parent then
            local myWorld = myPos and TeleportAPI.DetectSubWorldName(LocalPlayer, myPos) or "Main World"
            TPUI.WorldStatusLbl.Text = string.format(
                "Lokasi: %s | TP Terakhir: %s",
                myWorld,
                TeleportAPI.FormatDistance(State.LastTeleportDistance)
            )
        end

        for _, wpItem in ipairs(TPUI.WpDistanceLabels) do
            if wpItem.Label and wpItem.Label.Parent and myPos then
                local dist = (wpItem.CF.Position - myPos).Magnitude
                wpItem.Label.Text = string.format("Jarak: %s • %s", TeleportAPI.FormatDistance(dist), wpItem.WorldTag)
            end
        end

        for plr, rowData in pairs(TPUI.PlayerRows) do
            if plr and plr.Parent and rowData.TelemetryLbl and rowData.TelemetryLbl.Parent then
                local info = TeleportAPI.ResolvePlayerState(plr)
                if info then
                    local dist = myPos and (info.Position - myPos).Magnitude or 0
                    rowData.TelemetryLbl.Text = string.format(
                        "Jarak: %s | %s",
                        TeleportAPI.FormatDistance(dist),
                        info.WorldName
                    )
                else
                    rowData.TelemetryLbl.Text = "Dunia: Menunggu data lokasi..."
                end
            end
        end
    end

    UI.UpdateTeleportLiveDistances = TPUI.UpdateLiveDistances

    refreshPlayerList()
    Utils.Track(Players.PlayerAdded:Connect(refreshPlayerList))
    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        if State.SpectatingPlayer == plr then
            TeleportAPI.StopRemoteView(false)
        end
        task.defer(refreshPlayerList)
    end))
end

-- ============================================================================
-- TAB 8: TAMPILAN DUNIA (KAMERA & PENCAHAYAAN)
-- ============================================================================
do
    local page = Components.CreateTab("Visuals", "☀", 8)
    Components.AddSectionHeader(page, "Kontrol Kamera & Pencahayaan", 1)

    local fovSlider = Components.AddSlider(page, "Sudut Pandang Kamera (Field of View)", 40, 120, 70, 0, 2, function(val)
        State.CameraFOV = val
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = val end
    end)

    UI.FullbrightToggle = Components.AddToggle(page, "Cahaya Dunia: Penerangan Maksimal (Fullbright)", "Hilangkan bayangan gelap dan terangkan seluruh sudut map secara instan", false, 3, function(on)
        State.FullbrightEnabled = on
        if on then
            Lighting.Brightness = 2.5
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        else
            Lighting.Brightness = State.OriginalLighting.Brightness
            Lighting.ClockTime = State.OriginalLighting.ClockTime
            Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
            Lighting.Ambient = State.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        end
        Utils.Notify("Penerangan Maksimal", on and "Fullbright diaktifkan." or "Pencahayaan asli dipulihkan.", on and Theme.Success or Theme.TextSecondary)
    end)

    UI.NoFogToggle = Components.AddToggle(page, "Cuaca Dunia: Penghapus Kabut (No Fog)", "Hapus kabut jarak pandang (FogEnd & Atmosphere) agar terlihat jernih", false, 4, function(on)
        State.NoFogEnabled = on
        if on then
            Lighting.FogEnd = 1000000
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then
                if not State.OriginalAtmosphere then
                    State.OriginalAtmosphere = { Instance = atmo, Density = atmo.Density }
                end
                atmo.Density = 0
            end
        else
            Lighting.FogEnd = State.OriginalLighting.FogEnd
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo and State.OriginalAtmosphere and State.OriginalAtmosphere.Instance == atmo then
                atmo.Density = State.OriginalAtmosphere.Density
            end
        end
        Utils.Notify("Penghapus Kabut", on and "Kabut dihapus." or "Kabut asli dipulihkan.", on and Theme.Success or Theme.TextSecondary)
    end)

    local clockSlider = Components.AddSlider(page, "Atur Waktu Siang / Malam Klien (Jam)", 0, 24, Lighting.ClockTime, 1, 5, function(val)
        Lighting.ClockTime = val
    end)

    Components.AddButton(page, "Pulihkan Pengaturan Visual & Kamera", "Pulihkan FOV (70), sakelar, dan pencahayaan asli map", "Pulihkan", 6, function()
        fovSlider.SetValue(70, true)
        if UI.FullbrightToggle then UI.FullbrightToggle.SetState(false, true) end
        if UI.NoFogToggle then UI.NoFogToggle.SetState(false, true) end
        clockSlider.SetValue(State.OriginalLighting.ClockTime, true)
        Utils.Notify("Visual Dipulihkan", "Semua visual kembali ke bawaan.", Theme.Success)
    end)
end

-- ============================================================================
-- TAB 9: PENGATURAN (ANTI-BUG, BAHASA IP, & KUSTOMISASI TEMA)
-- ============================================================================
do
    local page = Components.CreateTab("Settings", "⚙", 9)
    Components.AddSectionHeader(page, "Sistem Anti-Bug / Error & Anti-AFK", 1)

    Components.AddToggle(page, "Proteksi Sistem: Anti-Bug & Pemulihan Otomatis", "Mencegah error pada setiap fitur dan memulihkannya otomatis saat terganggu", true, 2, function(on)
        Protection.AntiBugEnabled = on
        if UI.StatusLabel and UI.StatusLabel.Parent then
            UI.StatusLabel.Text = on and "Anti-Bug: AKTIF" or "Anti-Bug: OFF"
        end
        Utils.Notify("Anti-Bug Engine", on and "Anti-Bug & Auto-Recovery AKTIF." or "Anti-Bug dimatikan.", on and Theme.Success or Theme.Warning)
    end)

    Components.AddToggle(page, "Proteksi Koneksi: Anti-Kick Diam (Anti-AFK)", "Mencegah terputus dari server otomatis saat karakter diam lebih dari 20 menit", true, 3, function(on)
        Protection.AntiAFKEnabled = on
        Utils.Notify("Anti-AFK", on and "Anti-AFK aktif." or "Anti-AFK dimatikan.", on and Theme.Success or Theme.TextSecondary)
    end)

    -- ========================================================================
    -- REAL-TIME IP REGION & INTERACTIVE COUNTRY LANGUAGE SELECTOR
    -- ========================================================================
    local langSectionHeader = Components.AddSectionHeader(page, GeoLangAPI.T("lang_section"), 4)
    GeoLangAPI.OnLanguageChanged(function()
        if langSectionHeader and langSectionHeader.Parent then
            langSectionHeader.Text = "💀 " .. string.upper(GeoLangAPI.T("lang_section"))
        end
    end)

    local langStatusCard = Utils.Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.22,
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
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 5,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(langStatusCard, 7)
    Utils.AddStroke(langStatusCard, Theme.Accent, 1, 0.35)
    Utils.RegisterAccent(langStatusCard, "TextColor3")
    UI.LangStatusLabel = langStatusCard

    local langOptions = {}
    for _, lEntry in ipairs(GeoLangAPI.Languages) do
        table.insert(langOptions, { Label = lEntry.Label, Value = lEntry.Code })
    end

    local langChipSelector = Components.AddChipSelector(
        page,
        GeoLangAPI.T("lang_selector"),
        langOptions,
        GeoLangAPI.CurrentLang,
        6,
        function(chosenCode)
            GeoLangAPI.SetLanguage(chosenCode, true)
            Utils.Notify(
                "🌐 Geo-Language",
                GeoLangAPI.T("lang_changed") .. GeoLangAPI.GetLanguageLabel(chosenCode),
                Theme.Success
            )
        end
    )

    GeoLangAPI.OnLanguageChanged(function(newCode)
        if langChipSelector and langChipSelector.SetSelected then
            langChipSelector.SetSelected(newCode)
        end
    end)

    local syncIpBtn = Components.AddButton(
        page,
        GeoLangAPI.T("lang_auto_btn"),
        GeoLangAPI.T("lang_auto_sub"),
        GeoLangAPI.T("lang_sync_now"),
        7,
        function()
            GeoLangAPI.ManualOverride = false
            GeoLangAPI.FetchRealTimeGeoIP(true)
            Utils.Notify("🌐 Geo-IP Sync", GeoLangAPI.T("detecting"), Theme.Accent)
        end
    )
    GeoLangAPI.OnLanguageChanged(function()
        if syncIpBtn and syncIpBtn.Parent then
            syncIpBtn.Text = GeoLangAPI.T("lang_sync_now")
        end
    end)

    Components.AddSectionHeader(page, "Kustomisasi Font & Warna Panel Menu", 8)

    Components.AddChipSelector(page, "Gaya Font Seluruh Panel Menu", {
        { Label = "Gotham Modern", Value = Enum.Font.GothamSemibold, Font = Enum.Font.GothamSemibold },
        { Label = "Fredoka Bulat", Value = Enum.Font.FredokaOne, Font = Enum.Font.FredokaOne },
        { Label = "Creepster Seram", Value = Enum.Font.Creepster, Font = Enum.Font.Creepster },
        { Label = "Roboto Mono", Value = Enum.Font.RobotoMono, Font = Enum.Font.RobotoMono },
        { Label = "Bangers Komik", Value = Enum.Font.Bangers, Font = Enum.Font.Bangers },
        { Label = "Merriweather", Value = Enum.Font.Merriweather, Font = Enum.Font.Merriweather },
    }, Enum.Font.GothamSemibold, 9, function(val)
        Theme.FontFamily = val
        Theme.FontBold = (val == Enum.Font.GothamSemibold) and Enum.Font.GothamBold or val
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Font Menu", "Gaya font seluruh menu berhasil diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Warna Aksen Utama Panel Menu", {
        { Label = "Emas Tengkorak", Value = Color3.fromRGB(255, 118, 26), Color = Color3.fromRGB(255, 118, 26) },
        { Label = "Merah Crimson", Value = Color3.fromRGB(214, 48, 74), Color = Color3.fromRGB(214, 48, 74) },
        { Label = "Ungu Spektral", Value = Color3.fromRGB(155, 89, 245), Color = Color3.fromRGB(155, 89, 245) },
        { Label = "Hijau Racun", Value = Color3.fromRGB(46, 213, 115), Color = Color3.fromRGB(46, 213, 115) },
        { Label = "Cyan Mistis", Value = Color3.fromRGB(24, 220, 255), Color = Color3.fromRGB(24, 220, 255) },
        { Label = "Pink Neon", Value = Color3.fromRGB(255, 105, 180), Color = Color3.fromRGB(255, 105, 180) },
    }, Color3.fromRGB(255, 118, 26), 10, function(val)
        Utils.SetAccentColor(val, val)
        Utils.Notify("Warna Aksen", "Warna aksen panel menu diperbarui.", val)
    end)

    Components.AddChipSelector(page, "Warna Teks Panel Menu", {
        { Label = "Auto Kontras", Value = "Auto", Color = Color3.fromRGB(255, 246, 235) },
        { Label = "Putih Gading", Value = Color3.fromRGB(255, 246, 235), Color = Color3.fromRGB(255, 246, 235) },
        { Label = "Emas Hangat", Value = Color3.fromRGB(255, 206, 110), Color = Color3.fromRGB(255, 206, 110) },
        { Label = "Cyan Terang", Value = Color3.fromRGB(130, 245, 255), Color = Color3.fromRGB(130, 245, 255) },
        { Label = "Hijau Mint", Value = Color3.fromRGB(145, 255, 185), Color = Color3.fromRGB(145, 255, 185) },
        { Label = "Hitam Gelap", Value = Color3.fromRGB(22, 16, 30), Color = Color3.fromRGB(22, 16, 30) },
    }, "Auto", 11, function(val)
        Theme.FontColorMode = val
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Warna Teks Menu", "Warna font menu diperbarui.", Theme.Accent)
    end)

    Components.AddChipSelector(page, "Latar Belakang Teks Menu (Adaptif)", {
        { Label = "Tanpa Latar", Value = "None" },
        { Label = "Gelap Transparan", Value = Color3.fromRGB(18, 14, 26), Color = Color3.fromRGB(18, 14, 26) },
        { Label = "Ungu Transparan", Value = Color3.fromRGB(42, 22, 66), Color = Color3.fromRGB(42, 22, 66) },
        { Label = "Labu Transparan", Value = Color3.fromRGB(58, 28, 14), Color = Color3.fromRGB(58, 28, 14) },
        { Label = "Putih Transparan", Value = Color3.fromRGB(238, 232, 245), Color = Color3.fromRGB(238, 232, 245) },
    }, "None", 12, function(val)
        if val == "None" then
            Theme.FontBgEnabled = false
        else
            Theme.FontBgEnabled = true
            Theme.FontBgColor = val
        end
        Utils.ApplyMenuFontAndColors()
        Utils.Notify("Latar Teks Menu", "Latar teks menu diperbarui.", Theme.Accent)
    end)

    Components.AddSectionHeader(page, "Kontrol Pintasan & Pembersihan Panel", 13)

    Components.AddButton(page, "Sembunyikan Panel Menu (RightShift)", "Atau ketuk ikon tengkorak 3D di layar kapan saja", "Sembunyikan", 14, function()
        App.IsOpen = false
        UI.MainFrame.Visible = false
    end)

    Components.AddButton(page, "Matikan & Hapus Script (Unload Hub)", "Putus semua loop, pulihkan karakter/map, dan tutup GUI", "Unload", 15, function()
        if UI.UnloadAll then
            UI.UnloadAll()
        end
    end)
end

-- ============================================================================
-- TAB 10: INFORMASI (Pembuat, Tautan Discord & Linktr.ee Donasi)
-- ============================================================================
do
    local page = Components.CreateTab("Informasi", "ℹ", 10)
    Components.AddSectionHeader(page, "Informasi Pembuat & Dukungan", 1)

    local heroCard = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 128),
        BackgroundColor3 = Theme.BgCard,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 14,
    }, page)
    Utils.AddCorner(heroCard, 12)
    local hStroke = Utils.AddStroke(heroCard, Theme.Accent, 1.3, 0.2)
    Utils.RegisterAccent(hStroke, "Color")

    Utils.CreateSkull3D(heroCard, 66, UDim2.new(0, 48, 0.5, 0), Vector2.new(0.5, 0.5), 16, true, false, 0.4)

    local infoTitle = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -104, 0, 22),
        Position = UDim2.new(0, 92, 0, 14),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "BimSakSin Hub v3.0 — Luxury Skull 3D HD",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterText(infoTitle, true, Theme.TextPrimary)

    local creatorLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -104, 0, 18),
        Position = UDim2.new(0, 92, 0, 38),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = "Pembuat (Creator): BimSakSin",
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterAccent(creatorLbl, "TextColor3")

    local descLbl = Utils.Create("TextLabel", {
        Size = UDim2.new(1, -104, 0, 56),
        Position = UDim2.new(0, 92, 0, 58),
        BackgroundTransparency = 1,
        Font = Theme.FontFamily,
        Text = "Universal Script Hub semua map Roblox (R6 & R15). Dilengkapi Radar ESP Pemain/Barang/Generator, Aimbot Laser RGB, Auto Parry, Carry Replikasi, Dance Studio, serta perlindungan Anti-Bug otomatis.",
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 15,
    }, heroCard)
    Utils.RegisterText(descLbl, false, Theme.TextSecondary)

    Components.AddSectionHeader(page, "Tautan Resmi Komunitas & Donasi", 3)

    Components.AddButton(page, "Tautan Donasi & Dukungan Developer", App.DonationUrl, "Salin Link", 4, function()
        if Utils.CopyText(App.DonationUrl) then
            Utils.Notify("Link Donasi Disalin", "Berhasil menyalin: " .. App.DonationUrl, Theme.Success)
        else
            Utils.Notify("Link Donasi", App.DonationUrl, Theme.Accent)
        end
    end)

    Components.AddButton(page, "Tautan Komunitas Discord Resmi", App.DiscordUrl, "Salin Discord", 5, function()
        if Utils.CopyText(App.DiscordUrl) then
            Utils.Notify("Discord Disalin", "Berhasil menyalin: " .. App.DiscordUrl, Theme.Success)
        else
            Utils.Notify("Discord Resmi", App.DiscordUrl, Theme.Accent)
        end
    end)
end

-- ============================================================================
-- 16. WINDOW CONTROLS, RESPONSIVE VIEWPORT GUARD & FULL CLEANUP
-- ============================================================================
do
    local function toggleGuiVisibility()
        App.IsOpen = not App.IsOpen
        UI.MainFrame.Visible = App.IsOpen
    end

    UI.FloatingToggle.MouseButton1Click:Connect(toggleGuiVisibility)

    UI.CloseBtn.MouseButton1Click:Connect(function()
        App.IsOpen = false
        UI.MainFrame.Visible = false
        Utils.Notify("Menu Ditutup", "Ketuk tengkorak 3D HD di layar atau tekan RightShift untuk membuka kembali.", Theme.Accent)
    end)

    UI.MinimizeBtn.MouseButton1Click:Connect(function()
        App.IsMinimized = not App.IsMinimized
        if App.IsMinimized then
            UI.Sidebar.Visible = false
            UI.ContentContainer.Visible = false
            UI.ResizeHandle.Visible = false
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, App.ExpandedWidth, 0, 54)
            })
        else
            Utils.Tween(UI.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, App.ExpandedWidth, 0, App.ExpandedHeight)
            })
            task.delay(0.14, function()
                if not App.IsMinimized and UI.Sidebar and UI.ContentContainer then
                    UI.Sidebar.Visible = true
                    UI.ContentContainer.Visible = true
                    UI.ResizeHandle.Visible = true
                end
            end)
        end
    end)

    local resizing = false
    local activeResizeInput = nil
    local resizeStart = nil
    local resizeStartSize = nil

    Utils.Track(UI.ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            activeResizeInput = input
            resizeStart = input.Position
            resizeStartSize = UI.MainFrame.AbsoluteSize
        end
    end))

    Utils.Track(UserInputService.InputChanged:Connect(function(input)
        if not resizing or App.IsMinimized or not activeResizeInput or not resizeStart or not resizeStartSize then
            return
        end
        local isMatchingMouse = (activeResizeInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)
        local isMatchingTouch = (input == activeResizeInput)

        if isMatchingMouse or isMatchingTouch then
            local delta = input.Position - resizeStart
            local vp = UI.ScreenGui.AbsoluteSize
            local maxW = (vp.X > 0) and math.max(320, vp.X - 24) or 940
            local maxH = (vp.Y > 0) and math.max(240, vp.Y - 24) or 680

            App.ExpandedWidth = math.clamp(resizeStartSize.X + delta.X, 320, maxW)
            App.ExpandedHeight = math.clamp(resizeStartSize.Y + delta.Y, 240, maxH)
            UI.MainFrame.Size = UDim2.new(0, App.ExpandedWidth, 0, App.ExpandedHeight)

            local sidebarW = (App.ExpandedWidth < 500) and math.clamp(math.floor(App.ExpandedWidth * 0.30), 116, 166) or 166
            UI.Sidebar.Size = UDim2.new(0, sidebarW, 1, -54)
            UI.ContentContainer.Size = UDim2.new(1, -sidebarW, 1, -54)
            UI.ContentContainer.Position = UDim2.new(0, sidebarW, 0, 54)
        end
    end))

    Utils.Track(UserInputService.InputEnded:Connect(function(input)
        if resizing and (input == activeResizeInput or (activeResizeInput and activeResizeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            resizing = false
            activeResizeInput = nil
        end
    end))

    local function enforceViewportBounds()
        if not UI.ScreenGui or not UI.MainFrame or not UI.MainFrame.Parent then
            return
        end
        local vp = UI.ScreenGui.AbsoluteSize
        if vp.X <= 0 or vp.Y <= 0 then
            return
        end

        local maxW = math.max(320, vp.X - 24)
        local maxH = math.max(240, vp.Y - 24)

        if App.ExpandedWidth > maxW or App.ExpandedHeight > maxH then
            App.ExpandedWidth = math.min(App.ExpandedWidth, maxW)
            App.ExpandedHeight = math.min(App.ExpandedHeight, maxH)
            if not App.IsMinimized then
                UI.MainFrame.Size = UDim2.new(0, App.ExpandedWidth, 0, App.ExpandedHeight)
            else
                UI.MainFrame.Size = UDim2.new(0, App.ExpandedWidth, 0, 54)
            end
        end

        local sidebarW = (App.ExpandedWidth < 500) and math.clamp(math.floor(App.ExpandedWidth * 0.30), 116, 166) or 166
        UI.Sidebar.Size = UDim2.new(0, sidebarW, 1, -54)
        UI.ContentContainer.Size = UDim2.new(1, -sidebarW, 1, -54)
        UI.ContentContainer.Position = UDim2.new(0, sidebarW, 0, 54)

        local absPos = UI.MainFrame.AbsolutePosition
        local absSize = UI.MainFrame.AbsoluteSize
        local clampedX = math.clamp(absPos.X, 6, math.max(6, vp.X - absSize.X - 6))
        local clampedY = math.clamp(absPos.Y, 6, math.max(6, vp.Y - absSize.Y - 6))
        if math.abs(clampedX - absPos.X) > 2 or math.abs(clampedY - absPos.Y) > 2 then
            UI.MainFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
        end

        if UI.FloatingToggle and UI.FloatingToggle.Parent then
            local fPos = UI.FloatingToggle.AbsolutePosition
            local fSize = UI.FloatingToggle.AbsoluteSize
            local fx = math.clamp(fPos.X, 6, math.max(6, vp.X - fSize.X - 6))
            local fy = math.clamp(fPos.Y, 6, math.max(6, vp.Y - fSize.Y - 6))
            if math.abs(fx - fPos.X) > 2 or math.abs(fy - fPos.Y) > 2 then
                UI.FloatingToggle.Position = UDim2.new(0, fx, 0, fy)
            end
        end
    end

    Utils.Track(UI.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(enforceViewportBounds))
    task.defer(enforceViewportBounds)

    Utils.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            toggleGuiVisibility()
        end
    end))

    Utils.Track(UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJumpEnabled then
            local _, hum = Utils.GetCharacter()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end))

    UI.UnloadAll = function()
        State.FlyEnabled = false
        State.NoclipEnabled = false
        State.InfiniteJumpEnabled = false
        ESP.Enabled = false
        ItemESP.Enabled = false
        GeneratorESP.Enabled = false
        Combat.AimbotEnabled = false
        Combat.AutoParryEnabled = false
        Combat.MeleeImmunity = false
        Combat.HungerThirstGuard = false
        Carry.Stop()
        Emotes.Stop()

        Physics.CleanupFly()
        Physics.RestoreNoclip()
        Protection.RestoreEnemyHitboxes()
        ESP.ClearAll()
        ItemESP.ClearAll()
        GeneratorESP.ClearAll()

        if Combat.LaserPart then
            pcall(function() Combat.LaserPart:Destroy() end)
            Combat.LaserPart = nil
        end

        for _, conn in ipairs(Connections) do
            if conn and conn.Connected then
                pcall(function() conn:Disconnect() end)
            end
        end
        table.clear(Connections)

        local _, hum = Utils.GetCharacter()
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        workspace.Gravity = State.OriginalGravity

        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = 70
            if hum then cam.CameraSubject = hum end
        end

        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.ClockTime = State.OriginalLighting.ClockTime
        Lighting.FogEnd = State.OriginalLighting.FogEnd
        Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        if State.OriginalAtmosphere and State.OriginalAtmosphere.Instance then
            pcall(function()
                State.OriginalAtmosphere.Instance.Density = State.OriginalAtmosphere.Density
            end)
        end

        if UI.ScreenGui then
            UI.ScreenGui:Destroy()
        end
    end

    if typeof(getgenv) == "function" then
        getgenv().BSS_UnloadOld = UI.UnloadAll
    end
end

-- ============================================================================
-- 17. RUNTIME LOOPS (3D Skull Animation, Smooth Fly, ESP, Aimbot, Parry & Guard)
-- ============================================================================
do
    local frameCounter = 0
    local lastTick = os.clock()
    local currentFPS = 60
    local slowScanAccum = 0

    local function bindCharacter(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.WalkSpeed = State.WalkSpeed
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower
        end
        if State.FlyEnabled then
            task.defer(function()
                Physics.CleanupFly()
            end)
        end
    end

    if LocalPlayer.Character then
        task.spawn(bindCharacter, LocalPlayer.Character)
    end
    Utils.Track(LocalPlayer.CharacterAdded:Connect(bindCharacter))

    Utils.Track(Players.PlayerRemoving:Connect(function(plr)
        ESP.RemovePlayer(plr)
    end))

    -- Stepped: Analog-Safe NoClip (Hanya menonaktifkan kolisi vertikal/dinding secara terukur & menjaga pijakan kaki)
    Utils.Track(RunService.Stepped:Connect(function()
        SafeEngine.Run("SteppedLoop", function()
            if State.NoclipEnabled then
                local char, hum, root = Utils.GetCharacter()
                if char and root then
                    local isMovingSlow = true
                    if hum and hum.MoveDirection.Magnitude > 0.88 then
                        isMovingSlow = false
                    end

                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if Physics.NoclipCache[part] == nil then
                                Physics.NoclipCache[part] = part.CanCollide
                            end
                            local isFootPart = (part.Name == "LeftFoot" or part.Name == "RightFoot" or part.Name == "Left Leg" or part.Name == "Right Leg")
                            if not State.FlyEnabled and isFootPart and not isMovingSlow then
                                part.CanCollide = Physics.NoclipCache[part]
                            elseif part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end

            if Combat.MeleeImmunity then
                Protection.StepMeleeImmunity()
            end
        end)
    end))

    -- Heartbeat: Smooth Admin Fly, Replicated Carry, Auto Parry, Survival Guard & Aimbot
    Utils.Track(RunService.Heartbeat:Connect(function(dt)
        SafeEngine.Run("HeartbeatLoop", function()
            local char, hum, root = Utils.GetCharacter()
            if hum then
                if hum.WalkSpeed ~= State.WalkSpeed then
                    hum.WalkSpeed = State.WalkSpeed
                end
                if hum.JumpPower ~= State.JumpPower then
                    hum.UseJumpPower = true
                    hum.JumpPower = State.JumpPower
                end
            end

            if State.FlyEnabled then
                Physics.StepSmoothFly(dt)
            end

            if Carry.Enabled then
                Carry.Step()
            end

            if Combat.AutoParryEnabled then
                Combat.StepAutoParry()
            end

            if Combat.HungerThirstGuard then
                Protection.StepHungerThirstGuard()
            end

            -- Auto Aimbot + Conditional RGB Weapon Laser
            local cam = workspace.CurrentCamera
            if Combat.AimbotEnabled and cam and root then
                local tool, isGun = Combat.GetEquippedRangedWeapon()
                local shouldLock = false

                if Combat.AimbotMode == "Always" then
                    shouldLock = true
                elseif Combat.AimbotMode == "HoldRMB" then
                    shouldLock = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    shouldLock = (tool ~= nil) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                end

                if shouldLock then
                    local targetPlr, aimPart = Combat.FindBestTarget()
                    Combat.CurrentTarget = targetPlr
                    if targetPlr and aimPart then
                        local camPos = cam.CFrame.Position
                        local desiredCF = CFrame.lookAt(camPos, aimPart.Position)
                        local alpha = math.clamp(Combat.Smoothness, 0.08, 1)
                        cam.CFrame = cam.CFrame:Lerp(desiredCF, alpha)

                        if Combat.RGBLaserEnabled and isGun and tool then
                            local muzzle = tool:FindFirstChild("Muzzle", true)
                                or tool:FindFirstChild("FirePoint", true)
                                or tool:FindFirstChild("Barrel", true)
                                or tool:FindFirstChild("Handle")
                            local startPos = (muzzle and muzzle:IsA("BasePart")) and muzzle.Position or (root.Position + Vector3.new(0, 1.5, 0))
                            Combat.UpdateLaser(startPos, aimPart.Position)
                        else
                            Combat.HideLaser()
                        end
                    else
                        Combat.HideLaser()
                    end
                else
                    Combat.CurrentTarget = nil
                    Combat.HideLaser()
                end
            else
                Combat.HideLaser()
            end
        end)
    end))

    -- RenderStepped: 3D HD Skull Animation, ESP Pemain, Item/Generator Scan & Telemetry
    Utils.Track(RunService.RenderStepped:Connect(function(dt)
        SafeEngine.Run("RenderLoop", function()
            local now = os.clock()

            -- Animasi Tengkorak 3D HD Mewah (Floating + Golden Crown & Eye Pulse + Jaw Breathing)
            local hue = (now * 0.16) % 1
            local accentGlow = Theme.Accent:Lerp(Color3.fromHSV(hue, 0.72, 1), 0.35)
            local pulse = math.sin(now * 2.8)
            local shimmer = (math.sin(now * 3.6) + 1) * 0.5

            if UI.SubLabelGradient and UI.SubLabelGradient.Parent then
                UI.SubLabelGradient.Offset = Vector2.new(-0.65 + (shimmer * 1.3), 0)
            end

            for _, sk in ipairs(UI.Skulls) do
                if sk.Holder and sk.Holder.Parent then
                    local bob = math.sin((now * 2.6) + sk.Phase) * (sk.IsHero and 2.2 or 1.8)
                    local sway = math.cos((now * 1.9) + sk.Phase) * (sk.IsHero and 5.5 or 7.5)
                    sk.Holder.Rotation = sway

                    if sk.IsMenuSkull and sk.BasePos then
                        sk.Holder.Position = UDim2.new(
                            sk.BasePos.X.Scale,
                            sk.BasePos.X.Offset,
                            sk.BasePos.Y.Scale,
                            sk.BasePos.Y.Offset + bob
                        )
                    end

                    if sk.Aura then
                        sk.Aura.BackgroundColor3 = accentGlow
                        sk.Aura.BackgroundTransparency = (sk.IsHero and 0.64 or 0.74) - (pulse * 0.06)
                    end
                    if sk.RingStroke then
                        sk.RingStroke.Color = Color3.fromRGB(255, 214, 112):Lerp(accentGlow, 0.45)
                    end
                    if sk.EyeLeft then
                        sk.EyeLeft.BackgroundColor3 = accentGlow
                    end
                    if sk.EyeRight then
                        sk.EyeRight.BackgroundColor3 = accentGlow
                    end
                    if sk.Jaw and sk.JawBasePos then
                        local jawBreath = math.max(0, math.sin((now * 2.4) + sk.Phase)) * 1.3
                        sk.Jaw.Position = UDim2.new(
                            sk.JawBasePos.X.Scale,
                            sk.JawBasePos.X.Offset,
                            sk.JawBasePos.Y.Scale,
                            sk.JawBasePos.Y.Offset + jawBreath
                        )
                    end
                end
            end

            if ESP.Enabled then
                ESP.UpdateAll()
            end

            if State.SpectatingPlayer then
                TeleportAPI.StepRemoteView()
            end

            slowScanAccum = slowScanAccum + (dt or 0.016)
            if slowScanAccum >= 0.35 then
                slowScanAccum = 0
                if ItemESP.Enabled then
                    ItemESP.ScanAndRender()
                end
                if GeneratorESP.Enabled then
                    GeneratorESP.ScanAndRender()
                end
                if UI.UpdateTeleportLiveDistances then
                    UI.UpdateTeleportLiveDistances()
                end
            end

            frameCounter = frameCounter + 1
            if (now - lastTick) >= 0.4 then
                currentFPS = math.floor(frameCounter / (now - lastTick) + 0.5)
                frameCounter = 0
                lastTick = now

                if UI.TelemetryLabels.FPS then
                    UI.TelemetryLabels.FPS.Text = tostring(currentFPS) .. " FPS"
                end

                local pingMs = 0
                pcall(function()
                    pingMs = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                end)
                if UI.TelemetryLabels.Ping then
                    UI.TelemetryLabels.Ping.Text = tostring(pingMs) .. " ms"
                end

                local memMb = 0
                pcall(function()
                    memMb = math.floor(Stats:GetTotalMemoryUsageMb() + 0.5)
                end)
                if UI.TelemetryLabels.Memory then
                    UI.TelemetryLabels.Memory.Text = tostring(memMb) .. " MB"
                end

                if UI.TelemetryLabels.Players then
                    UI.TelemetryLabels.Players.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers)
                end

                local _, _, root = Utils.GetCharacter()
                if root and UI.TelemetryLabels.Coords then
                    local p = root.Position
                    UI.TelemetryLabels.Coords.Text = string.format("XYZ: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
                end
            end
        end)
    end))
end

-- ============================================================================
-- 18. INITIALIZE DEFAULT TAB, REAL-TIME GEO-IP & WELCOME NOTIFICATION
-- ============================================================================
Components.SwitchTab("Dashboard")
GeoLangAPI.FetchRealTimeGeoIP(true)
Utils.Notify("BimSakSin Hub v3.0", GeoLangAPI.T("welcome"), Theme.Accent)
