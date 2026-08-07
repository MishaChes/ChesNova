#Requires AutoHotkey v2.0
#SingleInstance Off
FileEncoding "CP0"

launchedByLauncher := false
for arg in A_Args {
    if (arg = "--launched-by-chesnova-launcher") {
        launchedByLauncher := true
        break
    }
}
if !launchedByLauncher {
    MsgBox("Не запускайте ChesNova напрямую.`n`nИспользуйте ChesNovaLauncher.", "ChesNova", "Icon!")
    ExitApp()
}

chesNovaMutex := DllCall("CreateMutex", "Ptr", 0, "Int", false, "Str", "ChesNova_AHK_v2_SingleInstance", "Ptr")
if (A_LastError = 183) {
    MsgBox("ChesNova уже запущена.", "ChesNova", "Icon!")
    ExitApp()
}

; ============================================================
; ChesNova
; AutoHotkey v2 script
; ============================================================

; =========================
; 🧩 TRAY MENU
; =========================

; Трей пересобирается после загрузки настроек (RebuildTrayMenu)
A_TrayMenu.Delete()
A_TrayMenu.Add("🏠 Открыть меню", TrayOpenMenu)
A_TrayMenu.Add("⚙ Настройки", TrayOpenSettings)
A_TrayMenu.Add("🤖 AI-ассистент", TrayOpenAi)
A_TrayMenu.Add()
A_TrayMenu.Add("🔁 Перезапуск", TrayRestart)
A_TrayMenu.Add("❌ Выход", TrayExit)
A_TrayMenu.Default := "🏠 Открыть меню"
A_TrayMenu.ClickCount := 1

TrayOpenMenu(*) {
    OpenMenu()
}

TrayOpenSettings(*) {
    BuildMainWindow("Settings")
}

TrayOpenAi(*) {
    OpenAiAssistant()
}

TrayRestart(*) {
    RestartChesNova()
}

TrayExit(*) {
    ExitApp()
}

RebuildTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("🏠 Открыть меню", TrayOpenMenu)
    A_TrayMenu.Add("⚙ Настройки", TrayOpenSettings)
    A_TrayMenu.Add("🤖 AI-ассистент", TrayOpenAi)
    A_TrayMenu.Add()
    A_TrayMenu.Add("🔁 Перезапуск", TrayRestart)
    A_TrayMenu.Add("❌ Выход", TrayExit)
    A_TrayMenu.Default := "🏠 Открыть меню"
    A_TrayMenu.ClickCount := 1
}

; ------------------------------------------------------------
; 01. Startup, paths, settings and main HUD
; ------------------------------------------------------------
; =========================
; 🔧 INIT
; =========================

; =========================
; 📁 APP DATA
; =========================
appName := "ChesNova"
CURRENT_VERSION := "11.0.3"
appVersion := "v" CURRENT_VERSION
basePath := A_MyDocuments "\" appName
dataPath := basePath "\data"
logPath := basePath "\logs"
backupPath := basePath "\backups"
DirCreate(basePath)
DirCreate(dataPath)
DirCreate(logPath)
DirCreate(backupPath)

; =========================
; 📁 FILES
; =========================
saveFile := dataPath "\pm_count.txt"
settingsFile := basePath "\settings.ini"
historyFile := dataPath "\pm_history.csv"
punishmentsFile := dataPath "\punishments_history.csv"
pmLogsFile := dataPath "\pm_logs.csv"
daysOffFile := dataPath "\days_off.csv"
bindsFile := dataPath "\binds.csv" ; legacy-файл для миграции старых биндов
bindsDir := dataPath "\binds"
bindCategoriesFile := dataPath "\bind_categories.csv"
notificationsCacheFile := dataPath "\notifications.json"
notificationsStateFile := dataPath "\notifications_state.csv"
notificationsUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/notifications.json"
DirCreate(bindsDir)
aiHistoryFile := dataPath "\ai_history.json"
errorsLogFile := logPath "\errors.log"
; HTTP-мост для CEF HUD (ches.js)
hudBridgePort := 17890
hudBridgeStateFile := dataPath "\hud_state.json"
hudBridgePosFile := dataPath "\hud_pos.json"
hudBridgeScriptFile := dataPath "\hud_http_bridge.ps1"
hudBridgePidFile := dataPath "\hud_http_bridge.pid"
hudBridgePid := 0
; AI-ответ для in-game панели (ches.js), ~10 сек
aiHudId := 0
aiHudQuestion := ""
aiHudAnswer := ""
aiHudIsError := false
aiHudExpireTick := 0
aiHudThinking := false
try {
    if !FileExist(errorsLogFile)
        FileAppend("", errorsLogFile, "UTF-8")
}
try {
    if !FileExist(daysOffFile)
        FileAppend("", daysOffFile)
} catch as err {
    LogError("Init", "Ошибка создания days_off.csv", err.Message)
}

; =========================
; ⚙️ DEFAULT SETTINGS
; =========================
nick := "Nick_Name"
norm := 250
autoResetEnabled := 0
bindsEnabled := 0
checkUpdatesOnStartup := 1
testerMode := 0
startWithWindows := 0
resetHour := 0
resetMinute := 0
lastResetDate := ""
menuKey := "F10"
resetKey := "F9"
aiKey := "F7"
menuKeyEnabled := 1
resetKeyEnabled := 1
aiKeyEnabled := 1
geminiApiKey := ""
geminiModel := "gemini-3.6-flash"
deepseekApiKey := ""
deepseekModel := "deepseek-chat"
groqApiKey := ""
groqModel := "llama-3.1-8b-instant"
aiProvider := "gemini"  ; gemini | deepseek | groq
aiDailyLimit := 0
aiDailyUsed := 0
aiDailyRemaining := 0
aiQuotaDate := ""
aiConfigLoaded := false
uiTheme := "dark"  ; dark | light
; Палитра заполняется ApplyTheme()
colorBg := "0B0E14"
colorSidebar := "10151E"
colorCard := "171D28"
colorCardAlt := "222A37"
colorAccent := "3B82F6"
colorText := "F5F7FB"
colorMuted := "A0A8B8"
colorGreen := "3DDB7A"
colorRed := "FF5B6B"
colorYellow := "F6A623"
uiDivider := "2B3443"
uiInputBg := "151A22"
uiBtnH := 28
dotRed := colorRed
dotGreen := colorGreen
aiHistory := []  ; [{q, a, t}, ...] последние вопросы AI
aiHistoryMax := 15
; aiHistoryFile уже задан выше: dataPath "\ai_history.json"
guiX := "Center"
guiY := "Center"
menuX := "Center"
menuY := "Center"
aiGuiX := "Center"
aiGuiY := "Center"
logFile := ""
scriptsGamePath := ""

; =========================
; 📥 LOAD SETTINGS
; =========================
if FileExist(settingsFile)
{
    try {
        nick := IniRead(settingsFile, "Main", "nick", nick)
        norm := IniRead(settingsFile, "Main", "norm", norm)
        logFile := IniRead(settingsFile, "Main", "logFile", logFile)
        scriptsGamePath := IniRead(settingsFile, "Scripts", "gamePath", scriptsGamePath)
        menuKey := IniRead(settingsFile, "Keys", "menuKey", "F10")
        resetKey := IniRead(settingsFile, "Keys", "resetKey", "F9")
        aiKey := IniRead(settingsFile, "Keys", "aiKey", "F7")
        menuKeyEnabled := IniRead(settingsFile, "Keys", "menuKeyEnabled", 1)
        resetKeyEnabled := IniRead(settingsFile, "Keys", "resetKeyEnabled", 1)
        aiKeyEnabled := IniRead(settingsFile, "Keys", "aiKeyEnabled", 1)
        geminiApiKey := IniRead(settingsFile, "AI", "geminiApiKey", "")
        geminiModel := IniRead(settingsFile, "AI", "geminiModel", "gemini-3.6-flash")
        deepseekApiKey := IniRead(settingsFile, "AI", "deepseekApiKey", "")
        deepseekModel := IniRead(settingsFile, "AI", "deepseekModel", "deepseek-chat")
        groqApiKey := IniRead(settingsFile, "AI", "groqApiKey", "")
        groqModel := IniRead(settingsFile, "AI", "groqModel", "llama-3.1-8b-instant")
        aiProvider := IniRead(settingsFile, "AI", "aiProvider", "gemini")
        aiDailyLimit := Integer(IniRead(settingsFile, "AI", "aiDailyLimit", 0))
        aiDailyUsed := Integer(IniRead(settingsFile, "AI", "aiDailyUsed", 0))
        aiDailyRemaining := Integer(IniRead(settingsFile, "AI", "aiDailyRemaining", 0))
        aiQuotaDate := IniRead(settingsFile, "AI", "aiQuotaDate", "")
        autoResetEnabled := IniRead(settingsFile, "Main", "autoResetEnabled", 0)
        bindsEnabled := IniRead(settingsFile, "Main", "bindsEnabled", 0)
        checkUpdatesOnStartup := IniRead(settingsFile, "Updates", "checkOnStartup", 1)
        testerMode := IniRead(settingsFile, "Updates", "testerMode", 0)
        startWithWindows := IniRead(settingsFile, "Launcher", "startWithWindows", 0)
        resetHour := IniRead(settingsFile, "Main", "resetHour", 0)
        resetMinute := IniRead(settingsFile, "Main", "resetMinute", 0)
        lastResetDate := IniRead(settingsFile, "Main", "lastResetDate", "")
        guiX := IniRead(settingsFile, "GUI", "guiX", "Center")
        guiY := IniRead(settingsFile, "GUI", "guiY", "Center")
        menuX := IniRead(settingsFile, "GUI", "menuX", "Center")
        menuY := IniRead(settingsFile, "GUI", "menuY", "Center")
        aiGuiX := IniRead(settingsFile, "GUI", "aiGuiX", "Center")
        aiGuiY := IniRead(settingsFile, "GUI", "aiGuiY", "Center")
        uiTheme := IniRead(settingsFile, "GUI", "uiTheme", "dark")
    } catch as err {
        LogError("LoadSettings", "Повреждён settings.ini или ошибка чтения настроек", err.Message)
        ShowToast("⚠ settings.ini повреждён — значения по умолчанию", 3200)
    }
}

nick := Trim(nick)
userNick := nick
norm += 0
autoResetEnabled += 0
bindsEnabled += 0
checkUpdatesOnStartup += 0
testerMode += 0
startWithWindows += 0
menuKeyEnabled += 0
resetKeyEnabled += 0
aiKeyEnabled += 0
geminiApiKey := Trim(geminiApiKey)
deepseekApiKey := Trim(deepseekApiKey)
groqApiKey := Trim(groqApiKey)
aiProvider := StrLower(Trim(aiProvider))
if (aiProvider != "deepseek" && aiProvider != "groq")
    aiProvider := "gemini"
if (geminiModel = "" || geminiModel = "gemini-1.5-flash" || geminiModel = "gemini-2.5-flash")
    geminiModel := "gemini-3.6-flash"
if (deepseekModel = "")
    deepseekModel := "deepseek-chat"
if (groqModel = "")
    groqModel := "llama-3.1-8b-instant"

ApplyTheme(uiTheme)
LoadAiHistory()

; Локальный кэш лимита AI: если дата не сегодня — обнуляем used
if (aiQuotaDate != FormatTime(, "yyyyMMdd")) {
    aiDailyUsed := 0
    aiDailyRemaining := (aiDailyLimit > 0) ? aiDailyLimit : 0
    aiQuotaDate := FormatTime(, "yyyyMMdd")
} else if (aiDailyLimit > 0) {
    ; Есть сохранённые значения за сегодня — можно показывать до ответа Cloud
    aiConfigLoaded := true
    if (aiDailyRemaining < 0)
        aiDailyRemaining := Max(0, aiDailyLimit - aiDailyUsed)
}

cloudAccessState := "unknown"
cloudAccessMessage := "Ожидает проверки"
cloudLastCheck := ""
accessUrl := "https://script.google.com/macros/s/AKfycbx1qWofvCKam_l4JGZKXegu6wvYXXD_GOBlhh_v4QjPq0Un65ngTeaf3zR95m7seodwMw/exec"
EnsureNickBeforeCloudAccess()
SetTimer(SendCloudPing, 3600000)
SetTimer(FetchAiConfigFromCloud, 1800000)
SetTimer(StartupNetworkInit, -300)
versionInfoUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/version.json"
testVersionInfoUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Test/Test.json"
notifications := []
notificationStates := Map()
LoadNotificationsCache()
LoadNotificationStates()
SetTimer(CheckNotifications, 600000)

; =========================
; 🧮 VARIABLES
; =========================
pmCount := 0
lastSize := 0
isFirstRun := true
beepPlayed := false
punishmentRecordCache := Map()
pmLogRecordCache := Map()
punishmentTotalsDate := ""
maxErrorLogBytes := 2 * 1024 * 1024
maxHistoryFileBytes := 10 * 1024 * 1024
historyKeepRecords := 10000
viewHistoryScanLimit := 2000
viewHistoryDisplayLimit := 200
diagnosticLastCheckMs := 0
diagnosticLastProcessedLines := 0
diagnosticLastPmChanges := 0
diagnosticLastLogSize := 0
diagnosticLastReadBytes := 0
diagnosticCheckLogSamples := 0
diagnosticCheckLogTotalMs := 0
diagnosticCheckLogMaxMs := 0
healthState := "ok"
healthMessage := "Пока без замечаний"
healthIncidents := []
chatlogReadErrorStreak := 0
lastChatlogChangeTick := A_TickCount
lastHealthState := "ok"
selectedPunishmentDate := ""
selectedPunishmentType := "ban"
selectedPunishmentDays := 10
punishmentSearch := ""

MainGui := ""
StatusDotCtrl := ""
CloudDotCtrl := ""
PMCountTextCtrl := ""
HudNickCtrl := ""
HudStatsCtrl := ""
BindsPreviewCtrl := ""
SettingsGui := ""
settingsMenuHidden := false
settingsMenuBuilding := false
lastMenuOpenTick := 0
SettingsTabCtrl := ""
GuiViewCtrls := Map()
NavButtonCtrls := Map()
NavIndicatorCtrls := Map()
CurrentView := ""
SetNickCtrl := ""
SetNormCtrl := ""
SetMenuKeyCtrl := ""
SetResetKeyCtrl := ""
SetAiKeyCtrl := ""
SetMenuKeyEnabledCtrl := ""
SetResetKeyEnabledCtrl := ""
SetAiKeyEnabledCtrl := ""
SetAiProviderCtrl := ""
AiGui := ""
AiQuestionCtrl := ""
AiAnswerCtrl := ""
AiStatusCtrl := ""
AiLimitCtrl := ""
AiAskBtnCtrl := ""
lastAiOpenTick := 0
aiRequestBusy := false
aiChatCaptureBusy := false
aiChatHotstringRegistered := false
SetAutoResetCtrl := ""
SetCheckUpdatesCtrl := ""
SetStartupCtrl := ""
SetResetHourCtrl := ""
SetResetMinuteCtrl := ""
LogFileTextCtrl := ""
HistoryTextCtrl := ""
PunishmentTypeTitleCtrl := ""
PunishmentSearchCtrl := ""
PunishmentDetailsCtrl := ""
PunishmentButtonCtrls := Map()
PunishmentPeriodButtonCtrls := Map()
PmLogsTextCtrl := ""
PMLogsSearchCtrl := ""
DaysOffDateCtrl := ""
DaysOffListCtrl := ""
BindsSearchCtrl := ""
BindsCategoryCtrl := ""
BindsCategoryStatusCtrl := ""
BindsListCtrl := ""
BindsEnabledCtrl := ""
BindEditGui := ""
BindEditId := ""
BindEditTypeCtrl := ""
BindEditCategoryCtrl := ""
BindEditNameCtrl := ""
BindEditTriggerCtrl := ""
BindEditContentCtrl := ""
BindEditEnabledCtrl := ""
BindCategoryInputResult := ""
BindCategoryInputValue := ""
BindCategoryInputCtrl := ""
BindsSortColumn := 3
BindsSortAscending := true
RegisteredBindTriggers := []
RegisteredStandardHotkeys := []
DashboardNickCtrl := ""
DashboardSystemStatusCtrl := ""
DashboardCloudStatusCtrl := ""
DashboardNormCtrl := ""
NormHistoryListCtrl := ""
NormHistoryEditGui := ""
NormHistoryEditOriginalDate := ""
NormHistoryEditDateCtrl := ""
NormHistoryEditPmCtrl := ""
NormHistoryEditNormCtrl := ""
NormMonthComboCtrl := ""
NormYearEditCtrl := ""
NormDaysOffInfoCtrl := ""
DashboardVersionCtrl := ""
DashboardNormTitleCtrl := ""
DashboardNormPmCtrl := ""
DashboardNormRemainingCtrl := ""
DashboardNormPercentCtrl := ""
DashboardProgressBgCtrl := ""
DashboardProgressFillCtrl := ""
DashboardLogFileCtrl := ""
DashboardDaysOffMonthCtrl := ""
DashboardStatusChatlogCtrl := ""
DashboardStatusGameCtrl := ""
DashboardStatusHudCtrl := ""
HelpEditCtrl := ""
ErrorsLogTextCtrl := ""
CloudNickCtrl := ""
CloudStatusCtrl := ""
CloudAccessTextCtrl := ""
CloudLastCheckCtrl := ""
DiagnosticTextCtrl := ""
DiagnosticHealthCtrl := ""
TesterModeCtrl := ""
TesterStatusCtrl := ""
TesterInfoCtrl := ""
ScriptsGamePathCtrl := ""
ScriptPackageStatusCtrls := Map()
NotificationButtonCtrl := ""
NotificationIndicatorCtrl := ""
NotificationsGui := ""
HistoryGui := ""
PunishmentsGui := ""
HelpGui := ""
ResetConfirmGui := ""
ToastGui := ""

if FileExist(saveFile)
{
    pmCount := FileRead(saveFile)
    pmCount += 0
}
LoadRecordCache(punishmentsFile, punishmentRecordCache, "LoadPunishmentRecordCache")
LoadRecordCache(pmLogsFile, pmLogRecordCache, "LoadPmLogRecordCache")
punishmentTotals := LoadPunishmentTotals()
if (logFile != "" && FileExist(logFile))
    lastSize := FileGetSize(logFile)


; =========================
; 🎨 THEME
; =========================
ApplyTheme(theme := "dark") {
    global uiTheme, colorBg, colorSidebar, colorCard, colorCardAlt, colorAccent
    global colorText, colorMuted, colorGreen, colorRed, colorYellow, uiDivider, uiInputBg
    global dotRed, dotGreen

    uiTheme := "dark"
    ; Тёмная палитра (акцент можно сменить одним colorAccent)
    colorBg := "080B12"
    colorSidebar := "0E131C"
    colorCard := "151C28"
    colorCardAlt := "1E2736"
    colorAccent := "3B82F6"
    colorText := "F5F7FB"
    colorMuted := "A0A8B8"
    colorGreen := "3DDB7A"
    colorRed := "FF5B6B"
    colorYellow := "F6A623"
    uiDivider := "2E3848"
    uiInputBg := "0F141D"
    dotRed := colorRed
    dotGreen := colorGreen
}

; =========================
; 🤖 AI HISTORY
; =========================
LoadAiHistory() {
    global aiHistory, aiHistoryFile, aiHistoryMax
    aiHistory := []
    if (aiHistoryFile = "" || !FileExist(aiHistoryFile))
        return
    try {
        text := FileRead(aiHistoryFile, "UTF-8")
        ; Простой формат: строки Q|||A|||timestamp
        for _, line in StrSplit(text, "`n") {
            line := Trim(line, "`r`n")
            if (line = "")
                continue
            part := StrSplit(line, "|||")
            if (part.Length < 2)
                continue
            aiHistory.Push(Map("q", part[1], "a", part[2], "t", GetArrayValue(part, 3, "")))
        }
        while (aiHistory.Length > aiHistoryMax)
            aiHistory.RemoveAt(1)
    } catch as err {
        LogError("LoadAiHistory", "Ошибка чтения истории AI", err.Message)
    }
}

SaveAiHistory() {
    global aiHistory, aiHistoryFile
    if (aiHistoryFile = "")
        return
    try {
        file := FileOpen(aiHistoryFile, "w", "UTF-8")
        for _, item in aiHistory {
            q := StrReplace(item["q"], "|||", " / ")
            a := StrReplace(item["a"], "|||", " / ")
            t := item.Has("t") ? item["t"] : ""
            file.WriteLine(q "|||" a "|||" t)
        }
        file.Close()
    } catch as err {
        LogError("SaveAiHistory", "Ошибка записи истории AI", err.Message)
    }
}

PushAiHistory(question, answer) {
    global aiHistory, aiHistoryMax
    question := Trim(question)
    answer := Trim(answer)
    if (question = "" || answer = "")
        return
    aiHistory.Push(Map("q", question, "a", answer, "t", FormatTime(A_Now, "dd.MM HH:mm")))
    while (aiHistory.Length > aiHistoryMax)
        aiHistory.RemoveAt(1)
    SaveAiHistory()
}

BuildAiHistoryText() {
    global aiHistory
    if (aiHistory.Length = 0)
        return "История пуста. Задайте вопрос — ответы появятся здесь."
    text := ""
    ; Новые сверху
    i := aiHistory.Length
    while (i >= 1) {
        item := aiHistory[i]
        text .= "▸ " item["t"] "`n"
        text .= "Q: " item["q"] "`n"
        text .= "A: " item["a"] "`n"
        text .= "————————————————`n"
        i -= 1
    }
    return text
}

HighlightSearchMatch(text, search) {
    search := Trim(search)
    if (search = "" || text = "")
        return text
    ; Пометка совпадений маркером «»» (Edit не умеет rich text)
    pos := InStr(text, search, false)
    if !pos
        return text
    return "» " text
}

; =========================
; 🖥 MAIN GUI (AHK-HUD отключён — счётчик в игре через ches.js)
; =========================
MainGui := ""
StatusDotCtrl := ""
CloudDotCtrl := ""
PMCountTextCtrl := ""
HudNickCtrl := ""
HudStatsCtrl := ""
OnMessage(0x201, WM_LBUTTONDOWN)
OnMessage(0x84, WM_NCHITTEST)

; =========================
; ⌨️ HOTKEYS
; =========================
RegisterHotkeys()
RebuildTrayMenu()
InitializeBinds()
MaybeRotateDaysOffMonthly()
SetTimer(CheckLog, 1000)
SetTimer(CheckAutoReset, 30000)
SetTimer(RunHealthCheck, 60000)

UpdatePMDisplay()
SetTimer(CheckChatlogPathOnStartup, -1500)
StartHudHttpBridge()
OnExit(HudBridgeOnExit)

; ------------------------------------------------------------
; 02. Statistics helpers
; ------------------------------------------------------------

CheckChatlogPathOnStartup(*) {
    AutoDetectGamePaths(false)
}

; =========================
; 📁 АВТОПОИСК chatlog + корень игры
; =========================
; После первого запуска лаунчера/игры:
;   chatlog: Документы\RADMIR CRMP User Files\SAMP\chatlog.txt
;   игра:   …\RADMIR Games\RADMIR CRMP
; На последующих запусках — только проверка сохранённых путей;
; если файл/папка пропали — повторный поиск и сохранение.

GetDefaultChatlogPath() {
    return A_MyDocuments "\RADMIR CRMP User Files\SAMP\chatlog.txt"
}

IsValidGameRoot(path) {
    path := RTrim(Trim(path), "\/")
    if (path = "" || !DirExist(path))
        return false
    ; Типичные маркеры корня RADMIR CRMP
    if FileExist(path "\gta_sa.exe")
        return true
    if FileExist(path "\samp.dll")
        return true
    if DirExist(path "\models") && DirExist(path "\data")
        return true
    ; Иногда только папка с именем RADMIR CRMP
    SplitPath(path, &leaf)
    if (StrLower(leaf) = "radmir crmp")
        return true
    return false
}

FindRadmirGameRoot() {
    candidates := []

    ; Стандартные и частые места установки
    for _, drive in ["C:", "D:", "E:", "F:", "G:", "H:"] {
        candidates.Push(drive "\RADMIR Games\RADMIR CRMP")
        candidates.Push(drive "\RADMIR\RADMIR CRMP")
        candidates.Push(drive "\Games\RADMIR Games\RADMIR CRMP")
        candidates.Push(drive "\Games\RADMIR CRMP")
        candidates.Push(drive "\Program Files\RADMIR Games\RADMIR CRMP")
        candidates.Push(drive "\Program Files (x86)\RADMIR Games\RADMIR CRMP")
    }
    candidates.Push(A_MyDocuments "\RADMIR Games\RADMIR CRMP")
    candidates.Push(EnvGet("LOCALAPPDATA") "\RADMIR Games\RADMIR CRMP")
    candidates.Push(EnvGet("ProgramFiles") "\RADMIR Games\RADMIR CRMP")
    try candidates.Push(EnvGet("ProgramFiles(x86)") "\RADMIR Games\RADMIR CRMP")

    for _, path in candidates {
        path := RTrim(path, "\/")
        if IsValidGameRoot(path)
            return path
    }

    ; Лёгкий обход 1-го уровня папки "RADMIR Games" на основных дисках
    for _, drive in ["C:", "D:", "E:", "F:"] {
        root := drive "\RADMIR Games"
        if !DirExist(root)
            continue
        try {
            Loop Files, root "\*", "D" {
                if IsValidGameRoot(A_LoopFileFullPath)
                    return A_LoopFileFullPath
            }
        }
    }

    return ""
}

SaveDetectedChatlog(path) {
    global logFile, lastSize, settingsFile, LogFileTextCtrl

    path := Trim(path)
    if (path = "" || !FileExist(path))
        return false

    logFile := path
    try lastSize := FileGetSize(logFile)
    catch
        lastSize := 0
    TryIniWrite(logFile, settingsFile, "Main", "logFile", "SaveDetectedChatlog")
    if IsObject(LogFileTextCtrl)
        LogFileTextCtrl.Value := logFile
    return true
}

SaveDetectedGamePath(path) {
    global scriptsGamePath, settingsFile, ScriptsGamePathCtrl

    path := RTrim(Trim(path), "\/")
    if (path = "" || !IsValidGameRoot(path))
        return false

    scriptsGamePath := path
    TryIniWrite(scriptsGamePath, settingsFile, "Scripts", "gamePath", "SaveDetectedGamePath")
    if IsObject(ScriptsGamePathCtrl)
        ScriptsGamePathCtrl.Value := scriptsGamePath
    return true
}

; silent=true — без тостов (фоновая перепроверка).
; silent=false — тосты при первом обнаружении / проблемах.
AutoDetectGamePaths(silent := false) {
    global logFile, scriptsGamePath, lastSize

    chatlogOk := false
    gameOk := false
    chatlogFoundNow := false
    gameFoundNow := false

    ; —— chatlog ——
    if (logFile != "" && FileExist(logFile)) {
        chatlogOk := true
        try lastSize := FileGetSize(logFile)
    } else {
        defaultChatlog := GetDefaultChatlogPath()
        if FileExist(defaultChatlog) {
            if SaveDetectedChatlog(defaultChatlog) {
                chatlogOk := true
                chatlogFoundNow := true
            }
        }
    }

    ; —— корень игры ——
    if (scriptsGamePath != "" && IsValidGameRoot(scriptsGamePath)) {
        gameOk := true
    } else {
        found := FindRadmirGameRoot()
        if (found != "") {
            if SaveDetectedGamePath(found) {
                gameOk := true
                gameFoundNow := true
            }
        }
    }

    ; HUD в игре: loader-js.asi + ches.js (при известном корне)
    hudResult := Map("ok", false, "downloaded", 0)
    if gameOk {
        ; При каждом старте: ches.js и loader-js.json всегда обновляем;
        ; loader-js.asi — только если отсутствует (createOnlyMissing).
        hudResult := EnsureChesNovaHudFiles(true, true)
    }

    if silent
        return Map("chatlog", chatlogOk, "game", gameOk, "hud", hudResult.Has("installed") ? hudResult["installed"] : false)

    if chatlogFoundNow && gameFoundNow
        ShowToast("✓ chatlog и корень игры найдены автоматически", 3200)
    else if chatlogFoundNow
        ShowToast("✓ chatlog найден автоматически", 2800)
    else if gameFoundNow
        ShowToast("✓ Корень игры найден автоматически", 2800)
    else {
        if !chatlogOk {
            if (logFile = "")
                ShowToast("⚠ chatlog не найден — укажите в Настройках", 3200)
            else
                ShowToast("⚠ chatlog не найден: " logFile, 3500)
        }
        if !gameOk && (scriptsGamePath = "" || !IsValidGameRoot(scriptsGamePath)) {
            if (scriptsGamePath != "")
                ShowToast("⚠ Корень игры не найден — укажите во вкладке Скрипты", 3200)
        }
    }

    if gameOk && hudResult.Has("downloaded") && (hudResult["downloaded"] > 0)
        ShowToast("✓ Счётчик в игре установлен (loader + ches.js)", 2800)

    try RefreshSettingsView()
    try RefreshScriptsView()
    try RefreshDashboardView()

    return Map("chatlog", chatlogOk, "game", gameOk, "hud", hudResult.Has("installed") ? hudResult["installed"] : false)
}

GetChesNovaHudPaths(gamePath := "") {
    if (gamePath = "")
        gamePath := GetScriptsGamePath()
    gamePath := RTrim(Trim(gamePath), "\/")
    if (gamePath = "")
        return Map("ok", false, "loader", "", "loaderJson", "", "ches", "", "scriptsDir", "")
    scriptsDir := gamePath "\uiresources\scripts"
    return Map(
        "ok", true,
        "loader", gamePath "\loader-js.asi",
        "loaderJson", gamePath "\loader-js.json",
        "ches", scriptsDir "\ches.js",
        "scriptsDir", scriptsDir,
        "uiresources", gamePath "\uiresources"
    )
}

IsChesNovaHudInstalled(gamePath := "") {
    paths := GetChesNovaHudPaths(gamePath)
    if !paths["ok"]
        return false
    return FileExist(paths["loader"]) && FileExist(paths["loaderJson"]) && FileExist(paths["ches"])
}

; Скачивает loader-js.asi + loader-js.json в корень игры и ches.js в uiresources\scripts.
; createOnlyMissing=true — не перезаписывать существующие файлы,
; кроме тех, у которых alwaysUpdate=true (ches.js, loader-js.json — всегда после рестарта/обновы).
EnsureChesNovaHudFiles(silent := true, createOnlyMissing := false) {
    global dataPath, scriptsGamePath

    gamePath := GetScriptsGamePath()
    if (gamePath = "" || !DirExist(gamePath))
        return Map("ok", false, "reason", "no_game", "installed", false)

    paths := GetChesNovaHudPaths(gamePath)
    try {
        if !DirExist(paths["uiresources"])
            DirCreate(paths["uiresources"])
        if !DirExist(paths["scriptsDir"])
            DirCreate(paths["scriptsDir"])
    } catch as err {
        LogError("EnsureChesNovaHudFiles", "Не удалось создать папки scripts", err.Message)
        return Map("ok", false, "reason", "mkdir", "installed", false)
    }

    files := [
        Map(
            "name", "loader-js.asi",
            "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/loader-js.asi",
            "dest", paths["loader"],
            "alwaysUpdate", false
        ),
        Map(
            "name", "loader-js.json",
            "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/JS%20code/loader-js.json",
            "dest", paths["loaderJson"],
            "alwaysUpdate", true
        ),
        Map(
            "name", "ches.js",
            "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/JS%20code/ches.js",
            "dest", paths["ches"],
            "alwaysUpdate", true
        )
    ]

    downloadsPath := dataPath "\downloads"
    try DirCreate(downloadsPath)

    downloaded := 0
    skipped := 0
    for _, file in files {
        alwaysUpdate := file.Has("alwaysUpdate") && file["alwaysUpdate"]
        ; ches.js / loader-js.json — всегда к замене после рестарта или обновы
        if (createOnlyMissing && !alwaysUpdate && FileExist(file["dest"])) {
            skipped += 1
            continue
        }
        tempFile := downloadsPath "\ChesNova_hud_" A_TickCount "_" file["name"] ".tmp"
        try {
            Download(file["url"], tempFile)
            if !FileExist(tempFile) || FileGetSize(tempFile) = 0
                throw Error("Пустой файл после загрузки: " file["name"])
            ; атомарнее: удалить старый → перенести
            try {
                if FileExist(file["dest"])
                    FileDelete(file["dest"])
            }
            FileMove(tempFile, file["dest"], 1)
            downloaded += 1
        } catch as err {
            try {
                if FileExist(tempFile)
                    FileDelete(tempFile)
            }
            LogError("EnsureChesNovaHudFiles", "Ошибка загрузки " file["name"], err.Message)
            if !silent
                ShowToast("⚠ Не удалось скачать " file["name"], 2800)
            return Map("ok", false, "reason", file["name"], "installed", IsChesNovaHudInstalled(gamePath))
        }
    }

    installed := IsChesNovaHudInstalled(gamePath)
    if !silent && downloaded > 0
        ShowToast("✓ Счётчик в игре: файлы установлены", 2600)
    return Map("ok", installed, "reason", "", "installed", installed, "downloaded", downloaded, "skipped", skipped)
}

; =========================
; 📊 NORM MULTIPLIER
; =========================
GetNormMultiplier() {
    global pmCount, norm

    if (norm <= 0)
        return 0

    return Floor(pmCount / norm)
}

UpdatePMDisplay() {
    global PMCountTextCtrl, StatusDotCtrl, HudNickCtrl, HudStatsCtrl, nick, pmCount, norm, dotGreen, dotRed

    if IsObject(PMCountTextCtrl)
        PMCountTextCtrl.Text := "PM: " pmCount
    if IsObject(StatusDotCtrl) {
        StatusDotCtrl.Text := "●"
        StatusDotCtrl.SetFont("c" ((pmCount >= norm) ? dotGreen : dotRed))
    }
    if IsObject(HudNickCtrl)
        HudNickCtrl.Text := nick
    if IsObject(HudStatsCtrl)
        HudStatsCtrl.Text := BuildHudPunishmentStats()
    RefreshDashboardView()
    WriteHudBridgeState()
}
UpdateCloudHudDot() {
    global CloudDotCtrl, cloudAccessState, colorGreen, colorRed, colorYellow, colorMuted
    if !IsObject(CloudDotCtrl)
        return
    col := colorMuted
    switch cloudAccessState {
        case "ok":
            col := colorGreen
        case "blocked", "denied", "offline":
            col := colorRed
        case "unknown":
            col := colorYellow
    }
    try CloudDotCtrl.SetFont("s7 c" col, "Segoe UI")
}

; =========================
; 🌐 HTTP bridge → CEF HUD
; =========================
WriteHudBridgeState(*) {
    global hudBridgeStateFile, hudBridgePosFile, nick, pmCount, norm, healthState, healthMessage
    global aiHudId, aiHudQuestion, aiHudAnswer, aiHudIsError, aiHudExpireTick, aiHudThinking

    try {
        mult := GetNormMultiplier()
        json := "{"
            . '"nick":"' JsonEscape(nick) '",'
            . '"pm":' Integer(pmCount) ','
            . '"norm":' Integer(norm) ','
            . '"mult":' Integer(mult) ','
            . '"health":"' JsonEscape(healthState) '",'
            . '"message":"' JsonEscape(healthMessage) '"'

        ; позиция HUD из файла (ches.js сохраняет через мост)
        hudLeft := ""
        hudTop := ""
        try {
            if FileExist(hudBridgePosFile) {
                posText := Trim(FileRead(hudBridgePosFile, "UTF-8"))
                if RegExMatch(posText, '"left"\s*:\s*(-?\d+(?:\.\d+)?)', &lm)
                    hudLeft := lm[1]
                if RegExMatch(posText, '"top"\s*:\s*(-?\d+(?:\.\d+)?)', &tm)
                    hudTop := tm[1]
            }
        }
        if (hudLeft != "" && hudTop != "")
            json .= ',"hud":{"left":' hudLeft ',"top":' hudTop '}'
        else
            json .= ',"hud":null'

        if (aiHudThinking) {
            json .= ',"ai":{'
                . '"id":' Integer(Max(aiHudId, 1)) ','
                . '"thinking":true,'
                . '"q":"' JsonEscape(aiHudQuestion) '",'
                . '"a":"",'
                . '"err":false,'
                . '"ttl":0'
                . "}"
        } else if (aiHudId > 0 && aiHudAnswer != "" && A_TickCount < aiHudExpireTick) {
            remainMs := aiHudExpireTick - A_TickCount
            if (remainMs < 0)
                remainMs := 0
            json .= ',"ai":{'
                . '"id":' Integer(aiHudId) ','
                . '"thinking":false,'
                . '"q":"' JsonEscape(aiHudQuestion) '",'
                . '"a":"' JsonEscape(aiHudAnswer) '",'
                . '"err":' (aiHudIsError ? "true" : "false") ','
                . '"ttl":' Integer(remainMs)
                . "}"
        } else {
            json .= ',"ai":null'
        }

        json .= "}"
        f := FileOpen(hudBridgeStateFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо: мост не должен ломать основной цикл
    }
}

; Индикатор «AI думает…» в ches.js
PushAiThinkingToGameHud(question := "") {
    global aiHudId, aiHudQuestion, aiHudAnswer, aiHudIsError, aiHudExpireTick, aiHudThinking

    aiHudThinking := true
    aiHudQuestion := Trim(question)
    aiHudAnswer := ""
    aiHudIsError := false
    aiHudExpireTick := 0
    if (aiHudId < 1)
        aiHudId := 1
    WriteHudBridgeState()
}

; Показать ответ AI в игре через ches.js (левый нижний угол, ~10 сек)
PushAiToGameHud(question, answer, isError := false, durationMs := 10000) {
    global aiHudId, aiHudQuestion, aiHudAnswer, aiHudIsError, aiHudExpireTick, aiHudThinking

    question := Trim(question)
    answer := Trim(answer)
    if (answer = "")
        return

    aiHudThinking := false
    aiHudId += 1
    aiHudQuestion := question
    aiHudAnswer := answer
    aiHudIsError := isError ? true : false
    aiHudExpireTick := A_TickCount + Max(1000, durationMs + 0)
    WriteHudBridgeState()
    SetTimer(ClearExpiredAiHud, -durationMs - 200)
}

ClearExpiredAiHud(*) {
    global aiHudExpireTick, aiHudThinking
    if (aiHudThinking)
        return
    if (A_TickCount >= aiHudExpireTick)
        WriteHudBridgeState()
}

EnsureHudBridgeScript() {
    global hudBridgeScriptFile, hudBridgePort

    ; TcpListener — без прав админа и без netsh urlacl
    ; GET /pos?left=N&top=N — сохранить позицию HUD (CEF localStorage не переживает релог)
    script := (
        "$ErrorActionPreference = 'Continue'`n"
        "$port = " hudBridgePort "`n"
        "$stateFile = $args[0]`n"
        "$posFile = $args[1]`n"
        "$ip = [System.Net.IPAddress]::Loopback`n"
        "$listener = [System.Net.Sockets.TcpListener]::new($ip, $port)`n"
        "try { $listener.Start() } catch { exit 1 }`n"
        "while ($true) {`n"
        "  try {`n"
        "    $client = $listener.AcceptTcpClient()`n"
        "    $stream = $client.GetStream()`n"
        "    $reader = New-Object System.IO.StreamReader($stream)`n"
        "    $requestLine = $reader.ReadLine()`n"
        "    while ($true) { $line = $reader.ReadLine(); if ([string]::IsNullOrEmpty($line)) { break } }`n"
        "    if ($requestLine -match 'GET\s+/pos\?left=([0-9.\-]+)&top=([0-9.\-]+)') {`n"
        "      $left = $Matches[1]; $top = $Matches[2]`n"
        "      try {`n"
        "        $posJson = '{`"left`":' + $left + ',`"top`":' + $top + '}'`n"
        "        [System.IO.File]::WriteAllText($posFile, $posJson, [System.Text.UTF8Encoding]::new($false))`n"
        "      } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } else {`n"
        "      $json = '{`"nick`":`"`",`"pm`":0,`"health`":`"ok`",`"message`":`"`",`"hud`":null}'`n"
        "      if (Test-Path -LiteralPath $stateFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($stateFile, [System.Text.UTF8Encoding]::new($false)) } catch {}`n"
        "      }`n"
        "    }`n"
        "    $body = [System.Text.Encoding]::UTF8.GetBytes($json)`n"
        "    $header = `"HTTP/1.1 200 OK``r``nContent-Type: application/json; charset=utf-8``r``nAccess-Control-Allow-Origin: *``r``nAccess-Control-Allow-Methods: GET, OPTIONS``r``nCache-Control: no-store``r``nConnection: close``r``nContent-Length: $($body.Length)``r``n``r``n`"`n"
        "    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)`n"
        "    $stream.Write($headerBytes, 0, $headerBytes.Length)`n"
        "    $stream.Write($body, 0, $body.Length)`n"
        "    $stream.Flush()`n"
        "    $client.Close()`n"
        "  } catch { Start-Sleep -Milliseconds 30 }`n"
        "}`n"
    )
    try {
        f := FileOpen(hudBridgeScriptFile, "w", "UTF-8")
        f.Write(script)
        f.Close()
    } catch as err {
        LogError("EnsureHudBridgeScript", "Не удалось записать hud_http_bridge.ps1", err.Message)
    }
}

StopHudHttpBridge(*) {
    global hudBridgePid, hudBridgePidFile

    pid := hudBridgePid
    if (pid = 0 && FileExist(hudBridgePidFile)) {
        try pid := Integer(Trim(FileRead(hudBridgePidFile, "UTF-8")))
        catch
            pid := 0
    }
    if (pid > 0) {
        try ProcessClose(pid)
        catch {
            try Run('taskkill /PID ' pid ' /F /T', , "Hide")
        }
    }
    hudBridgePid := 0
    try {
        if FileExist(hudBridgePidFile)
            FileDelete(hudBridgePidFile)
    }
}

StartHudHttpBridge(*) {
    global hudBridgePid, hudBridgePidFile, hudBridgeScriptFile, hudBridgeStateFile, hudBridgePosFile, hudBridgePort

    StopHudHttpBridge()
    WriteHudBridgeState()
    EnsureHudBridgeScript()

    try {
        ; Hidden PowerShell HttpListener — ничего дополнительно ставить не нужно
        cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'
            . hudBridgeScriptFile '" "' hudBridgeStateFile '" "' hudBridgePosFile '"'
        Run(cmd, , "Hide", &pid)
        hudBridgePid := pid
        try {
            f := FileOpen(hudBridgePidFile, "w", "UTF-8")
            f.Write(String(pid))
            f.Close()
        }
        ; На всякий случай обновляем state раз в секунду
        SetTimer(WriteHudBridgeState, 1000)
    } catch as err {
        LogError("StartHudHttpBridge", "Не удалось запустить HTTP-мост HUD", err.Message)
    }
}

HudBridgeOnExit(*) {
    StopHudHttpBridge()
}

BuildHudPunishmentStats() {
    global punishmentTotals

    EnsureHudPunishmentDay()
    text := "K = " punishmentTotals["kick"] " | J = " punishmentTotals["jail"] " | W = " punishmentTotals["warn"] "`n"
    text .= "M = " punishmentTotals["mute"] " | V = " punishmentTotals["vmute"] " | R = " punishmentTotals["rmute"] "`n"
    text .= "G = " punishmentTotals["gunban"] " | B = " punishmentTotals["ban"] " | SB = " punishmentTotals["sban"]
    return text
}

GetNormProgressPercent() {
    global pmCount, norm

    if (norm <= 0)
        return 0

    progressPercent := Floor((pmCount / norm) * 100)
    if (progressPercent > 100)
        progressPercent := 100
    if (progressPercent < 0)
        progressPercent := 0

    return progressPercent
}

GetRemainingPm() {
    global pmCount, norm

    remainingPm := norm - pmCount
    if (remainingPm < 0)
        remainingPm := 0
    return remainingPm
}

; =========================
; ⚖️ PUNISHMENTS HELPERS
; =========================
CleanPunishmentField(value) {
    value := Trim(value)
    value := StrReplace(value, "|", "/")
    value := StrReplace(value, "`r", " ")
    value := StrReplace(value, "`n", " ")
    return value
}

GetPunishmentTypeText(type) {
    type := NormalizePunishmentType(type)
    return type
}

NormalizePunishmentType(type) {
    type := Trim(type)
    if (type = "v_mute")
        return "vmute"
    return type
}

GetCurrentAdminNick() {
    global userNick, nick

    userNick := Trim(userNick)
    if (userNick = "") {
        nick := Trim(nick)
        userNick := nick
    }

    return userNick
}

IsCurrentAdminPunishment(admin) {
    currentAdmin := GetCurrentAdminNick()
    return (currentAdmin != "" && StripPlayerId(admin) = StripPlayerId(currentAdmin))
}

StripPlayerId(value) {
    return RegExReplace(Trim(value), "\[\d+\]$")
}

PunishmentDateToYmd(date) {
    part := StrSplit(date, ".")
    if (part.Length < 3)
        return ""
    return part[3] part[2] part[1]
}

IsPunishmentInLastDays(date, days) {
    ymd := PunishmentDateToYmd(date)
    if (ymd = "")
        return false

    dateTime := ymd . "000000"
    diff := DateDiff(A_Now, dateTime, "Days")
    return (diff >= 0 && diff < days)
}

ExtractPunishmentDuration(actionText) {
    duration := ""

    if RegExMatch(actionText, "\sна\s+([0-9]+)\s*мин\.?$", &durationMatch)
        duration := durationMatch[1]
    else if RegExMatch(actionText, "\s(на\s+[^\.]+)\.?$", &durationMatch)
        duration := durationMatch[1]
    else if RegExMatch(actionText, "\s(\[[0-9]+\|[0-9]+\])$", &durationMatch)
        duration := durationMatch[1]

    return Trim(duration)
}

ParsePunishmentLine(line, &punishmentTime, &admin, &player, &punishmentType, &reason, &duration) {
    if !RegExMatch(line, "^(?:([A-Za-z_]+)\s+)?\[(\d{2}:\d{2}:\d{2})\]\s+(.+)$", &match)
        return false

    punishmentTime := match[2]
    text := match[3]
    reason := ""
    duration := ""

    if RegExMatch(text, "\s*\.?\s*Причина:\s*(.*)$", &reasonMatch)
        reason := reasonMatch[1]

    text := RegExReplace(text, "\s*\.?\s*Причина:.*$", "")

    if RegExMatch(text, "^Администратор\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)\s+(.+)$", &adminMatch) {
        admin := adminMatch[1]
        actionText := adminMatch[2]
    } else if RegExMatch(text, "^\[A\]\s+Администратор\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)\s+(.+)$", &adminMatch) {
        admin := adminMatch[1]
        actionText := adminMatch[2]
    } else if RegExMatch(text, "^\[A\]\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)\s+(.+)$", &adminMatch) {
        admin := adminMatch[1]
        actionText := adminMatch[2]
    } else {
        return false
    }

    actionText := RegExReplace(actionText, "^оффлайн\s+", "")
    duration := ExtractPunishmentDuration(actionText)

    if InStr(actionText, "навсегда забанил") {
        punishmentType := "sban"
        if RegExMatch(actionText, "навсегда забанил игрока\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "забанил") {
        punishmentType := "ban"
        if RegExMatch(actionText, "забанил игрока\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "выдал предупреждение") {
        punishmentType := "warn"
        if RegExMatch(actionText, "выдал предупреждение игроку\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "посадил в тюрьму") {
        punishmentType := "jail"
        if RegExMatch(actionText, "посадил в тюрьму игрока\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "кикнул игрока") {
        punishmentType := "kick"
        if RegExMatch(actionText, "кикнул игрока\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "выдал блокировку оружия") {
        punishmentType := "gunban"
        if RegExMatch(actionText, "выдал блокировку оружия\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "заблокировал голосовой чат") {
        punishmentType := "vmute"
        if RegExMatch(actionText, "заблокировал голосовой чат игроку\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "выдал vmute") {
        punishmentType := "vmute"
        if RegExMatch(actionText, "выдал vmute игроку\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "заблокировал репорт") {
        punishmentType := "rmute"
        if RegExMatch(actionText, "заблокировал репорт игроку\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "заблокировал чат") {
        punishmentType := "mute"
        if RegExMatch(actionText, "заблокировал чат игроку\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    if InStr(actionText, "выдал mute") {
        punishmentType := "mute"
        if RegExMatch(actionText, "выдал mute игроку\s+([A-Za-zА-Яа-яЁё_]+(?:\[\d+\])?)", &playerMatch) {
            player := playerMatch[1]
            return true
        }
    }

    return false
}

SavePunishmentFromLine(line) {
    global punishmentsFile, punishmentRecordCache, punishmentTotals, punishmentTotalsDate, HudStatsCtrl

    if !ParsePunishmentLine(line, &punishmentTime, &admin, &player, &punishmentType, &reason, &duration)
        return
    if !IsCurrentAdminPunishment(admin)
        return

    admin := CleanPunishmentField(admin)

    punishmentDate := FormatTime(A_Now, "dd.MM.yyyy")
    player := CleanPunishmentField(player)
    punishmentType := CleanPunishmentField(NormalizePunishmentType(punishmentType))
    reason := CleanPunishmentField(reason)
    duration := CleanPunishmentField(duration)
    if (reason = "")
        reason := "не указано"
    if (duration = "")
        duration := "не указано"
    record := punishmentDate "|" punishmentTime "|" admin "|" player "|" punishmentType "|" reason "|" duration

    if punishmentRecordCache.Has(record)
        return
    if TryFileAppend(record "`n", punishmentsFile, "SavePunishmentFromLine", "Не удалось записать историю наказаний") {
        punishmentRecordCache[record] := true
        EnsureHudPunishmentDay()
        if punishmentTotals.Has(punishmentType)
            punishmentTotals[punishmentType] += 1
        if IsObject(HudStatsCtrl)
            HudStatsCtrl.Text := BuildHudPunishmentStats()
        ArchiveDataFileIfNeeded(punishmentsFile, "punishments")
    }
    return


}

GetPunishmentTypes() {
    return ["kick", "jail", "warn", "mute", "vmute", "rmute", "gunban", "ban", "sban", "all"]
}


PunishmentTypeControlName(type) {
    controls := Map("kick", "PunishmentBtnKick", "jail", "PunishmentBtnJail", "warn", "PunishmentBtnWarn", "mute", "PunishmentBtnMute", "vmute", "PunishmentBtnVmute", "rmute", "PunishmentBtnRmute", "gunban", "PunishmentBtnGunban", "ban", "PunishmentBtnBan", "sban", "PunishmentBtnSban", "all", "PunishmentBtnAll")
    return controls[NormalizePunishmentType(type)]
}
PunishmentNoDurationTypes() {
    return Map("kick", true, "warn", true, "sban", true)
}

PunishmentMatchesSearch(admin, player, reason, search) {
    search := Trim(search)
    if (search = "")
        return true

    haystack := admin " " player " " reason
    return InStr(haystack, search, false) > 0
}

GetPunishmentNoDataText(days) {
    if (days = 0)
        return "За всё время наказаний не найдено"
    if (days = 1)
        return "За сегодня наказаний не найдено"
    return "За последние " days " дней наказаний не найдено"
}

GetPunishmentPeriodText(days) {
    if (days = 0)
        return "за всё время"
    if (days = 1)
        return "сегодня"
    return "последние " days " дней"
}

CreatePunishmentTotals() {
    return Map("kick", 0, "jail", 0, "warn", 0, "mute", 0, "vmute", 0, "rmute", 0, "gunban", 0, "ban", 0, "sban", 0)
}

LoadPunishmentTotals() {
    global punishmentsFile, punishmentTotalsDate

    totals := CreatePunishmentTotals()
    punishmentTotalsDate := FormatTime(A_Now, "dd.MM.yyyy")
    if !FileExist(punishmentsFile)
        return totals

    for _, line in ReadFileLines(punishmentsFile, "LoadPunishmentTotals") {
        part := StrSplit(line, "|")
        if (part.Length < 5 || part[1] != punishmentTotalsDate || !IsCurrentAdminPunishment(part[3]))
            continue
        type := NormalizePunishmentType(part[5])
        if totals.Has(type)
            totals[type] += 1
    }
    return totals
}

EnsureHudPunishmentDay() {
    global punishmentTotals, punishmentTotalsDate

    today := FormatTime(A_Now, "dd.MM.yyyy")
    if (punishmentTotalsDate = today)
        return

    punishmentTotalsDate := today
    punishmentTotals := CreatePunishmentTotals()
}

CountPunishmentsByType(type, days, search := "") {
    global punishmentsFile

    type := NormalizePunishmentType(type)
    count := 0

    if FileExist(punishmentsFile) {
        for _, line in ReadFileLines(punishmentsFile)
        {
            if (Trim(line) = "")
                continue

            part := StrSplit(line, "|")
            if (part.Length < 6)
                continue
            if !IsCurrentAdminPunishment(part[3])
                continue

            rowType := NormalizePunishmentType(part[5])
            if (type != "all" && rowType != type)
                continue
            if (days > 0 && !IsPunishmentInLastDays(part[1], days))
                continue
            if !PunishmentMatchesSearch(part[3], part[4], part[6], search)
                continue

            count++
        }
    }

    return count
}

BuildPunishmentTypeDetails(type, days := 10, search := "") {
    global punishmentsFile, viewHistoryScanLimit, viewHistoryDisplayLimit

    type := NormalizePunishmentType(type)
    noDurationTypes := PunishmentNoDurationTypes()
    details := ""
    displayed := 0

    if FileExist(punishmentsFile) {
        lines := SortRecordsNewestFirst(ReadRecentLines(punishmentsFile, viewHistoryScanLimit, "BuildPunishmentTypeDetails"), "punishment")
        for _, line in lines
        {
            if (Trim(line) = "")
                continue

            part := StrSplit(line, "|")
            if (part.Length < 6)
                continue
            if !IsCurrentAdminPunishment(part[3])
                continue

            rowType := NormalizePunishmentType(part[5])
            if (type != "all" && rowType != type)
                continue
            if (days > 0 && !IsPunishmentInLastDays(part[1], days))
                continue
            if !PunishmentMatchesSearch(part[3], part[4], part[6], search)
                continue

            displayed++
            if (displayed > viewHistoryDisplayLimit)
                break

            if (rowType = "vmute") {
                details .= BuildVmuteDetailsLine(part) "`n`n"
                continue
            }

            duration := ""
            if (part.Length >= 7)
                duration := part[7]
            if (duration = "")
                duration := "не указано"

            block := "[" part[1] " " part[2] "] " rowType "`n"
            block .= "Администратор: " part[3] "`n"
            block .= "Игрок: " part[4] "`n"
            block .= "Причина: " part[6] "`n"
            if (!noDurationTypes.Has(rowType))
                block .= "Срок: " duration "`n"
            details .= HighlightSearchMatch(block, search) "`n"
        }
    }

    if (details = "")
        details := GetPunishmentNoDataText(days)

    return details
}

BuildVmuteDetailsLine(part) {
    punishmentDate := GetArrayValue(part, 1, "не указано")
    punishmentTime := GetArrayValue(part, 2, "не указано")
    admin := GetArrayValue(part, 3, "не указано")
    player := GetArrayValue(part, 4, "не указано")
    reason := GetArrayValue(part, 6, "не указано")
    duration := NormalizePunishmentDurationMinutes(GetArrayValue(part, 7, ""))

    if (Trim(admin) = "")
        admin := "не указано"
    if (Trim(player) = "")
        player := "не указано"
    if (Trim(reason) = "")
        reason := "не указано"

    details := "[" punishmentDate " " punishmentTime "] vmute `n"
    details .= "Администратор: " admin "`n"
    details .= "Игрок: " player "`n"
    details .= "Причина: " reason "`n"
    details .= "Срок: " duration

    return details
}

NormalizePunishmentDurationMinutes(duration) {
    duration := Trim(duration)
    if (duration = "" || duration = "-")
        return "не указано"
    if (duration = "не указано")
        return duration
    if RegExMatch(duration, "\[(\d+)\|(\d+)\]", &durationMatch)
        return durationMatch[2]
    if RegExMatch(duration, "(\d+)", &durationMatch)
        return durationMatch[1]
    return duration
}

UpdatePunishmentTypeButtons(days, search := "") {
    global PunishmentButtonCtrls

    types := GetPunishmentTypes()
    for _, type in types
    {
        buttonLabel := (type = "all") ? "Все" : type
        buttonText := buttonLabel " (" CountPunishmentsByType(type, days, search) ")"
        if (PunishmentButtonCtrls.Has(type) && IsObject(PunishmentButtonCtrls[type]))
            PunishmentButtonCtrls[type].Text := buttonText
    }
    UpdatePunishmentFilterStyles()
}

UpdatePunishmentFilterStyles() {
    global PunishmentButtonCtrls, PunishmentPeriodButtonCtrls
    global selectedPunishmentType, selectedPunishmentDays
    global colorAccent, colorCardAlt, colorText

    selectedType := NormalizePunishmentType(selectedPunishmentType)
    for typeName, ctrl in PunishmentButtonCtrls {
        if !IsObject(ctrl)
            continue
        bg := (typeName = selectedType) ? colorAccent : colorCardAlt
        try {
            ctrl.Opt("Background" bg " c" colorText)
            ctrl.SetFont("s9 Bold c" colorText, "Segoe UI")
        }
    }

    for daysKey, ctrl in PunishmentPeriodButtonCtrls {
        if !IsObject(ctrl)
            continue
        bg := ((daysKey + 0) = (selectedPunishmentDays + 0)) ? colorAccent : colorCardAlt
        try {
            ctrl.Opt("Background" bg " c" colorText)
            ctrl.SetFont("s9 Bold c" colorText, "Segoe UI")
        }
    }
}

RenderPunishmentView(*) {
    global selectedPunishmentType, selectedPunishmentDays, punishmentSearch
    global SettingsGui, PunishmentSearchCtrl, PunishmentTypeTitleCtrl, PunishmentDetailsCtrl

    if IsObject(SettingsGui) {
        try values := SettingsGui.Submit(false)
        if IsSet(values) && values.HasOwnProp("PunishmentSearch")
            punishmentSearch := values.PunishmentSearch
    } else if IsObject(PunishmentSearchCtrl) {
        punishmentSearch := PunishmentSearchCtrl.Value
    }

    details := BuildPunishmentTypeDetails(selectedPunishmentType, selectedPunishmentDays, punishmentSearch)
    UpdatePunishmentTypeButtons(selectedPunishmentDays, punishmentSearch)
    if IsObject(PunishmentTypeTitleCtrl)
        PunishmentTypeTitleCtrl.Text := "Тип: " (NormalizePunishmentType(selectedPunishmentType) = "all" ? "все" : NormalizePunishmentType(selectedPunishmentType)) " / " GetPunishmentPeriodText(selectedPunishmentDays)
    if IsObject(PunishmentDetailsCtrl)
        PunishmentDetailsCtrl.Value := details
}

ShowPunishmentType(type, *) {
    global selectedPunishmentType

    selectedPunishmentType := NormalizePunishmentType(type)
    RenderPunishmentView()
}

SetPunishmentPeriod(days, *) {
    global selectedPunishmentDays

    selectedPunishmentDays := days
    RenderPunishmentView()
}
; =========================
; 📊 SAVE STATS (с защитой от дублей)
; =========================
GetHistorySaveDate() {
    completedGameDay := DateAdd(A_Now, -1, "Days")
    return FormatTime(completedGameDay, "yyyy-MM-dd")
}

SaveDayStats() {
    global pmCount, norm, historyFile
    historyDate := GetHistorySaveDate()

    ; Защита от записи одной и той же даты несколько раз
    if FileExist(historyFile) {
        for _, line in ReadFileLines(historyFile, "SaveDayStats") {
            part := StrSplit(line, ",")
            if (part.Length >= 1 && part[1] = historyDate)
                return  ; уже сохранено за этот игровой день
        }
    }

    if !TryFileAppend(historyDate "," pmCount "," norm "`n", historyFile, "SaveDayStats", "Ошибка записи истории нормы")
        ShowToast("⚠ Не удалось сохранить историю нормы", 2200)
}

BuildNormHistoryText() {
    global historyFile

    historyText := ""
    lines := []

    if FileExist(historyFile) {
        for _, line in ReadFileLines(historyFile)
        {
            if (Trim(line) != "")
                lines.Push(line)
        }
    }

    lines := SortRecordsNewestFirst(lines, "history")
    total := lines.Length

    if (total > 0) {
        displayTotal := Min(total, 7)

        Loop displayTotal
        {
            line := lines[A_Index]
            part := StrSplit(line, ",")
            if (part.Length >= 3) {
                dayPM := part[2] + 0
                dayNorm := part[3] + 0
                historyText .= part[1] "`n"
                historyText .= "PM: " dayPM " / " dayNorm "`n`n"
            }
        }
    }

    if (historyText = "")
        historyText := "Нет данных"

    return historyText
}

AppendPmLog(action, details := "") {
    global pmLogsFile

    logDate := FormatTime(A_Now, "dd.MM.yyyy")
    logTime := FormatTime(A_Now, "HH:mm:ss")
    action := CleanPunishmentField(action)
    details := CleanPunishmentField(details)
    TryFileAppend(logDate "|" logTime "|" action "|" details "`n", pmLogsFile, "AppendPmLog", "Ошибка записи PM-лога")
}

SavePmLogFromLine(line) {
    global pmLogsFile, pmLogRecordCache

    if !RegExMatch(line, "^\[(\d{2}:\d{2}:\d{2})\]\s*(.*)$", &match)
        return

    logDate := FormatTime(A_Now, "dd.MM.yyyy")
    logTime := match[1]
    details := CleanPunishmentField(match[2])
    record := logDate "|" logTime "|PM|" details

    if pmLogRecordCache.Has(record)
        return
    if TryFileAppend(record "`n", pmLogsFile, "SavePmLogFromLine", "Не удалось записать PM-лог") {
        pmLogRecordCache[record] := true
        ArchiveDataFileIfNeeded(pmLogsFile, "pm_logs")
    }
    return


}

BuildPmLogsText(search := "") {
    global pmLogsFile, viewHistoryDisplayLimit

    logsText := ""
    search := Trim(search)
    lines := ReadRecentMatchingLines(pmLogsFile, viewHistoryDisplayLimit, search, "BuildPmLogsText")
    total := lines.Length
    if (total > 0) {
        displayTotal := total

        Loop displayTotal
        {
            line := lines[total - A_Index + 1]
            part := StrSplit(line, "|")
            if (part.Length >= 4) {
                entry := "[" part[1] " " part[2] "] " part[3] ": " JoinArrayFrom(part, 4, "|")
                logsText .= HighlightSearchMatch(entry, search) "`n`n"
            }
        }
    }

    if (logsText = "")
        logsText := "PM логи пока пустые."

    return logsText
}

ConfirmClearData(filePath, title, refreshCallback := "") {
    global punishmentTotals
    message := "Очистить данные раздела " . Chr(34) . title . Chr(34) . "?`nЭто действие нельзя отменить."
    result := ShowAppDialog("Подтверждение очистки", message, "OKCancel")
    if (result != "OK")
        return

    if !CreateBackupBeforeClear(filePath)
        return

    try {
        file := FileOpen(filePath, "w")
        file.Close()
    } catch as err {
        LogError("ConfirmClearData", "Ошибка очистки файла: " filePath, err.Message)
        MsgBox("Не удалось очистить файл:`n" filePath "`n`n" err.Message, "Ошибка", "Iconx")
        return
    }

    if (refreshCallback = "RefreshPMLogsAfterClear")
        RefreshPMLogsAfterClear()
    else if (refreshCallback = "FillNormHistoryList")
        FillNormHistoryList()
    else if (refreshCallback = "RenderPunishmentView") {
        punishmentTotals := CreatePunishmentTotals()
        RenderPunishmentView()
        UpdatePMDisplay()
    }
}

CreateBackupBeforeClear(filePath) {
    global backupPath

    try DirCreate(backupPath)
    catch as err {
        LogError("CreateBackupBeforeClear", "Ошибка создания папки backup", err.Message)
        MsgBox("Не удалось создать папку backup:`n" backupPath "`n`n" err.Message, "Ошибка backup", "Iconx")
        return false
    }

    backupName := GetBackupFileName(filePath)
    if (backupName = "") {
        LogError("CreateBackupBeforeClear", "Не удалось определить имя backup-файла", filePath)
        MsgBox("Не удалось определить имя backup-файла:`n" filePath, "Ошибка backup", "Iconx")
        return false
    }

    backupFile := backupPath "\" backupName

    try {
        if FileExist(filePath)
            FileCopy(filePath, backupFile, true)
        else
            FileAppend("", backupFile)
    } catch as err {
        LogError("CreateBackupBeforeClear", "Ошибка создания backup: " backupFile, err.Message)
        MsgBox("Не удалось создать backup:`n" backupFile "`n`n" err.Message, "Ошибка backup", "Iconx")
        return false
    }

    return true
}

GetBackupFileName(filePath) {
    fileName := RegExReplace(filePath, "^.*\\")
    timestamp := FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss")

    if (fileName = "pm_logs.csv")
        return "pm_logs_" timestamp ".csv"
    if (fileName = "pm_history.csv")
        return "pm_history_" timestamp ".csv"
    if (fileName = "punishments_history.csv")
        return "punishments_history_" timestamp ".csv"
    if (fileName = "days_off.csv")
        return "days_off_" timestamp ".csv"

    return ""
}

ClearPMLogs(*) {
    global pmLogsFile
    ConfirmClearData(pmLogsFile, "PM Логи", "RefreshPMLogsAfterClear")
}

RefreshPMLogsAfterClear() {
    global PmLogsTextCtrl, PMLogsSearchCtrl

    if IsObject(PmLogsTextCtrl)
        PmLogsTextCtrl.Value := BuildPmLogsText(IsObject(PMLogsSearchCtrl) ? PMLogsSearchCtrl.Value : "")
}

ClearNormHistory(*) {
    global historyFile
    ConfirmClearData(historyFile, "История нормы", "FillNormHistoryList")
}

ClearPunishments(*) {
    global punishmentsFile
    ConfirmClearData(punishmentsFile, "Наказания", "RenderPunishmentView")
}

NormalizeDayOffDate(value) {
    value := Trim(value)
    if RegExMatch(value, "^\d{4}-\d{2}-\d{2}$")
        return value
    return ""
}

ParseDayOffRecord(line) {
    part := StrSplit(line, "|")
    dayOffDate := NormalizeDayOffDate(GetArrayValue(part, 1, ""))
    if (dayOffDate = "")
        return ""
    forumUploaded := (part.Length >= 2 && part[2] + 0) ? 1 : 0
    return Map("date", dayOffDate, "forumUploaded", forumUploaded)
}

FormatDayOffRecord(dayOffDate, forumUploaded := 0) {
    return dayOffDate "|" (forumUploaded ? 1 : 0)
}

GetDayOffRecords() {
    global daysOffFile

    records := []
    if !FileExist(daysOffFile)
        return records

    for _, line in ReadFileLines(daysOffFile) {
        record := ParseDayOffRecord(line)
        if IsObject(record)
            records.Push(record)
    }
    return records
}

IsDayOff(date) {
    date := NormalizeDayOffDate(date)
    if (date = "")
        return false

    for _, record in GetDayOffRecords() {
        if (record["date"] = date)
            return true
    }

    return false
}

CountDaysOffCurrentMonth() {
    return CountDaysOffInMonth(FormatTime(A_Now, "yyyy"), FormatTime(A_Now, "MM"))
}

CountDaysOffInMonth(year, month) {
    year := Trim(year)
    month := Trim(month)
    if !RegExMatch(year, "^\d{4}$")
        return 0
    if RegExMatch(month, "^\d{1}$")
        month := "0" month
    if !RegExMatch(month, "^\d{2}$")
        return 0

    monthPrefix := year "-" month
    count := 0
    for _, record in GetDayOffRecords() {
        if (SubStr(record["date"], 1, 7) = monthPrefix)
            count++
    }
    return count
}

; Раз в календарный месяц: backup отгулов + очистка рабочего списка.
MaybeRotateDaysOffMonthly() {
    global daysOffFile, settingsFile, backupPath

    currentMonth := FormatTime(A_Now, "yyyy-MM")
    lastMonth := ""
    try lastMonth := IniRead(settingsFile, "Main", "lastDaysOffMonth", "")

    if (lastMonth = "") {
        try IniWrite(currentMonth, settingsFile, "Main", "lastDaysOffMonth")
        return
    }
    if (lastMonth = currentMonth)
        return

    hasData := false
    if FileExist(daysOffFile) {
        for _, line in ReadFileLines(daysOffFile, "MaybeRotateDaysOffMonthly") {
            if (Trim(line) != "") {
                hasData := true
                break
            }
        }
    }

    if hasData {
        try {
            DirCreate(backupPath)
            backupFile := backupPath "\days_off_" lastMonth ".csv"
            FileCopy(daysOffFile, backupFile, true)
        } catch as err {
            LogError("MaybeRotateDaysOffMonthly", "Ошибка backup отгулов", err.Message)
            return
        }

        try {
            file := FileOpen(daysOffFile, "w")
            file.Close()
            AppendPmLog("Действие", "Отгулы: месячный backup " lastMonth " и очистка")
        } catch as err {
            LogError("MaybeRotateDaysOffMonthly", "Ошибка очистки отгулов", err.Message)
            return
        }
    }

    try IniWrite(currentMonth, settingsFile, "Main", "lastDaysOffMonth")
}

AddDayOff(*) {
    global daysOffFile, DaysOffDateCtrl, DaysOffForumCtrl

    if !IsObject(DaysOffDateCtrl)
        return

    dayOffDate := NormalizeDayOffDate(DaysOffDateCtrl.Value)
    if (dayOffDate = "") {
        ShowAppDialog("Отгулы", "Введите дату в формате yyyy-MM-dd.")
        return
    }

    if IsDayOff(dayOffDate) {
        ShowAppDialog("Отгулы", "Отгул на эту дату уже добавлен.")
        return
    }

    forumUploaded := (IsObject(DaysOffForumCtrl) && DaysOffForumCtrl.Value) ? 1 : 0
    if !TryFileAppend(FormatDayOffRecord(dayOffDate, forumUploaded) "`n", daysOffFile, "AddDayOff", "Ошибка записи days_off.csv")
        return
    DaysOffDateCtrl.Value := ""
    if IsObject(DaysOffForumCtrl)
        DaysOffForumCtrl.Value := 0
    UpdateDayOffForumStatus()
    FillDaysOffList()
    FillNormHistoryList()
    RefreshNormDaysOffInfo()
}

GetSelectedDayOffDates() {
    global DaysOffListCtrl

    dates := []

    if !IsObject(DaysOffListCtrl)
        return dates

    row := 0
    while (row := DaysOffListCtrl.GetNext(row)) {
        dayOffDate := NormalizeDayOffDate(DaysOffListCtrl.GetText(row, 1))
        if (dayOffDate != "")
            dates.Push(dayOffDate)
    }

    return dates
}


WriteDayOffRecords(records, source := "WriteDayOffRecords") {
    global daysOffFile

    try {
        file := FileOpen(daysOffFile, "w")
        for _, record in records
            file.WriteLine(FormatDayOffRecord(record["date"], record["forumUploaded"]))
        file.Close()
        return true
    } catch as err {
        LogError(source, "Ошибка записи days_off.csv", err.Message)
        MsgBox("Не удалось сохранить список отгулов.`n`n" err.Message, "Ошибка", "Iconx")
        return false
    }
}

DeleteSelectedDayOff(*) {
    global DaysOffListCtrl

    if !IsObject(DaysOffListCtrl)
        return

    selectedDates := GetSelectedDayOffDates()
    if (selectedDates.Length = 0) {
        ShowAppDialog("Отгулы", "Выберите один или несколько отгулов для удаления.")
        return
    }

    message := (selectedDates.Length = 1)
        ? "Удалить отгул за " selectedDates[1] "?"
        : "Удалить выбранные отгулы: " selectedDates.Length " шт.?"

    result := ShowAppDialog("Удаление отгула", message, "OKCancel")
    if (result != "OK")
        return

    newRecords := []
    for _, record in GetDayOffRecords() {
        if !ArrayHasValue(selectedDates, record["date"])
            newRecords.Push(record)
    }

    if !WriteDayOffRecords(newRecords, "DeleteSelectedDayOff")
        return

    FillDaysOffList()
    FillNormHistoryList()
}


SetSelectedDayOffForumStatus(uploaded, *) {
    selectedDates := GetSelectedDayOffDates()
    if (selectedDates.Length = 0) {
        ShowAppDialog("Отгулы", "Выберите дату отгула в списке.")
        return
    }

    records := GetDayOffRecords()
    for _, record in records {
        if ArrayHasValue(selectedDates, record["date"])
            record["forumUploaded"] := uploaded ? 1 : 0
    }

    if !WriteDayOffRecords(records, "SetSelectedDayOffForumStatus")
        return

    FillDaysOffList()
}

ToggleSelectedDayOffForumStatus(*) {
    selectedDates := GetSelectedDayOffDates()
    if (selectedDates.Length = 0)
        return

    records := GetDayOffRecords()
    for _, record in records {
        if ArrayHasValue(selectedDates, record["date"])
            record["forumUploaded"] := record["forumUploaded"] ? 0 : 1
    }

    if !WriteDayOffRecords(records, "ToggleSelectedDayOffForumStatus")
        return

    FillDaysOffList()
}

FillDaysOffList() {
    global daysOffFile, DaysOffListCtrl

    if !IsObject(DaysOffListCtrl)
        return

    DaysOffListCtrl.Delete()
    lines := []

    for _, record in GetDayOffRecords()
        lines.Push(FormatDayOffRecord(record["date"], record["forumUploaded"]))

    lines := SortRecordsNewestFirst(lines, "dayoff")
    for _, line in lines {
        record := ParseDayOffRecord(line)
        if IsObject(record) {
            forumText := record["forumUploaded"] ? "Залито" : "Не залито"
            DaysOffListCtrl.Add(, record["date"], forumText)
        }
    }
    RefreshNormDaysOffInfo()
}

UpdateDayOffForumStatus(*) {
    global DaysOffForumCtrl, DaysOffForumStatusCtrl, colorGreen, colorRed

    if !IsObject(DaysOffForumStatusCtrl)
        return

    uploaded := IsObject(DaysOffForumCtrl) && DaysOffForumCtrl.Value
    DaysOffForumStatusCtrl.Text := uploaded ? "На форуме залито" : "Не залито"
    DaysOffForumStatusCtrl.SetFont("s9 Bold c" (uploaded ? colorGreen : colorRed), "Segoe UI")
}

; =========================
; ⌨️ BINDS
; =========================
InitializeBinds() {
    global bindsFile, bindsDir

    DirCreate(bindsDir)

    ; Новая система хранит бинды по категориям:
    ; Documents\ChesNova\data\binds\main.csv, answers.csv, punishments.csv, events.csv, other.csv
    ; Список категорий и их статус хранится в data\bind_categories.csv.
    ; Если найден старый data\binds.csv — один раз переносим его в новую структуру.
    EnsureBindCategoriesFile()
    if !FileExist(bindsDir "\all.csv") {
        legacyCategoryBinds := ReadLegacyDefaultCategoryBinds()
        if (legacyCategoryBinds.Length > 0)
            WriteBinds(legacyCategoryBinds)
    }
    if !AnyBindCategoryFilesExist() {
        if FileExist(bindsFile) {
            legacyBinds := ReadBindsFromFile(bindsFile, "MigrateLegacyBinds")
            WriteBinds(legacyBinds)
        } else {
            CreateDefaultBinds()
        }
    }

    RegisterCustomBinds()
}

CreateDefaultBinds() {
    WriteBinds([])
}

ReadLegacyDefaultCategoryBinds() {
    global bindsDir

    binds := []
    legacyFiles := ["main.csv", "answers.csv", "punishments.csv", "events.csv", "other.csv"]

    for _, fileName in legacyFiles {
        filePath := bindsDir "\" fileName
        for _, bind in ReadBindsFromFile(filePath, "ReadLegacyDefaultCategoryBinds") {
            bind["category"] := "Все"
            binds.Push(bind)
        }
    }

    return binds
}

EnsureBindCategoriesFile() {
    SaveBindCategoryRecords(ReadBindCategoryRecords())
}

GetBindCategoryFileMap() {
    return Map(
        "Все", "all.csv"
    )
}

GetDefaultBindCategories() {
    return ["Все"]
}

IsLegacyDefaultBindCategory(category) {
    category := Trim(category)
    legacyDefaults := Map(
        "Основные", true,
        "Ответы игрокам", true,
        "Наказания", true,
        "МП", true,
        "Другое", true
    )
    return legacyDefaults.Has(category)
}

ReadBindCategoryRecords() {
    global bindCategoriesFile

    files := GetBindCategoryFileMap()
    savedRecords := []
    savedByName := Map()

    if !FileExist(bindCategoriesFile) {
        records := []
        for _, name in GetDefaultBindCategories()
            records.Push(Map("name", name, "enabled", 1, "file", files[name]))
        return records
    }

    if FileExist(bindCategoriesFile) {
        for _, line in ReadFileLines(bindCategoriesFile, "ReadBindCategoryRecords") {
            if (Trim(line) = "")
                continue

            part := StrSplit(line, "|")
            name := DecodeBindField(GetArrayValue(part, 1, ""))
            name := Trim(name)
            if (name = "" || savedByName.Has(name))
                continue
            if IsLegacyDefaultBindCategory(name)
                continue

            enabled := IsIntegerText(GetArrayValue(part, 2, "1")) ? (GetArrayValue(part, 2, "1") + 0) : 1
            fileName := DecodeBindField(GetArrayValue(part, 3, ""))
            if (fileName = "")
                fileName := files.Has(name) ? files[name] : GetSafeBindCategoryFileName(name)

            record := Map("name", name, "enabled", enabled ? 1 : 0, "file", fileName)
            savedRecords.Push(record)
            savedByName[name] := record
        }
    }

    if !savedByName.Has("Все")
        savedRecords.InsertAt(1, Map("name", "Все", "enabled", 1, "file", files["Все"]))

    return savedRecords
}

SaveBindCategoryRecords(records) {
    global bindCategoriesFile

    try {
        file := FileOpen(bindCategoriesFile, "w")
        for _, record in records {
            line := EncodeBindField(record["name"]) "|"
            line .= (record["enabled"] + 0) "|"
            line .= EncodeBindField(record["file"])
            file.WriteLine(line)
        }
        file.Close()
        return true
    } catch as err {
        LogError("SaveBindCategoryRecords", "Ошибка записи bind_categories.csv", err.Message)
        MsgBox("Не удалось сохранить категории биндов.`n`n" err.Message, "Бинды", "Iconx")
        return false
    }
}

GetSafeBindCategoryFileName(category) {
    name := Trim(category)
    name := RegExReplace(name, "[\\/:*?`"<>|]", "_")
    name := RegExReplace(name, "\s+", "_")
    name := RegExReplace(name, "^\.+|\.+$", "")
    name := Trim(name, "_ ")

    if (name = "")
        name := "category"

    return name ".csv"
}

BindCategoryExists(category) {
    category := Trim(category)
    if (category = "")
        return false

    for _, record in ReadBindCategoryRecords() {
        if (record["name"] = category)
            return true
    }

    return false
}

IsBindCategoryEnabled(category) {
    category := Trim(category)

    for _, record in ReadBindCategoryRecords() {
        if (record["name"] = category)
            return (record["enabled"] + 0) ? true : false
    }

    return true
}

GetUniqueBindCategoryFileName(category) {
    records := ReadBindCategoryRecords()
    used := Map()

    for _, record in records
        used[StrLower(record["file"])] := true

    baseName := RegExReplace(GetSafeBindCategoryFileName(category), "\.csv$", "")
    fileName := baseName ".csv"
    index := 2

    while used.Has(StrLower(fileName)) {
        fileName := baseName "_" index ".csv"
        index += 1
    }

    return fileName
}

AddBindCategoryByName(category) {
    category := Trim(category)

    if (category = "") {
        ShowAppDialog("Категории биндов", "Введите название категории.")
        return false
    }

    if BindCategoryExists(category) {
        ShowAppDialog("Категории биндов", "Такая категория уже существует: " category)
        return false
    }

    records := ReadBindCategoryRecords()
    records.Push(Map("name", category, "enabled", 1, "file", GetUniqueBindCategoryFileName(category)))
    return SaveBindCategoryRecords(records)
}

SetBindCategoryEnabled(category, enabled) {
    category := Trim(category)
    records := ReadBindCategoryRecords()

    for _, record in records {
        if (record["name"] = category) {
            record["enabled"] := enabled ? 1 : 0
            return SaveBindCategoryRecords(records)
        }
    }

    return false
}

DeleteBindCategoryByName(category) {
    category := Trim(category)

    if (category = "" || category = "Все") {
        ShowAppDialog("Категории биндов", "Выберите категорию.")
        return false
    }

    if (category = "Все") {
        ShowAppDialog("Категории биндов", "Категорию " Chr(34) "Все" Chr(34) " нельзя удалить.")
        return false
    }

    records := ReadBindCategoryRecords()
    categoryFile := GetBindCategoryFile(category)
    found := false
    newRecords := []

    for _, record in records {
        if (record["name"] = category) {
            found := true
            continue
        }
        newRecords.Push(record)
    }

    if !found
        return false

    binds := ReadBinds()
    movedCount := 0
    for _, bind in binds {
        if (bind["category"] = category) {
            bind["category"] := "Все"
            movedCount += 1
        }
    }

    message := "Удалить категорию " Chr(34) category Chr(34) "?"
    if (movedCount > 0)
        message .= "`nБинды из неё будут перенесены в " Chr(34) "Все" Chr(34) ": " movedCount " шт."

    result := ShowAppDialog("Удаление категории", message, "YesNo")
    if (result != "Yes")
        return false

    if !SaveBindCategoryRecords(newRecords)
        return false

    if !WriteBinds(binds) {
        SaveBindCategoryRecords(records)
        return false
    }

    TryFileDelete(categoryFile, "DeleteBindCategoryByName", "Ошибка удаления файла категории")

    return true
}

GetBindCategoryFile(category) {
    global bindsDir

    category := Trim(category)

    for _, record in ReadBindCategoryRecords() {
        if (record["name"] = category)
            return bindsDir "\" record["file"]
    }

    return bindsDir "\all.csv"
}

AnyBindCategoryFilesExist() {
    for _, category in GetBindCategories(false) {
        if FileExist(GetBindCategoryFile(category))
            return true
    }

    return false
}

GetBindCategories(includeAll := false) {
    categories := includeAll ? ["Все"] : []
    added := Map()
    if (includeAll)
        added["Все"] := true

    for _, record in ReadBindCategoryRecords() {
        name := record["name"]
        if added.Has(name)
            continue
        categories.Push(name)
        added[name] := true
    }

    return categories
}

GetBindTypes() {
    return ["Клавишный бинд", "Текстовая замена", "Массовые сообщения"]
}

NormalizeBindType(type) {
    rawType := Trim(type)
    type := StrLower(rawType)

    if (type = "hotstring" || type = "текстовая замена" || rawType = "Текстовая замена")
        return "hotstring"

    if (type = "macro" || type = "массовые сообщения" || rawType = "Массовые сообщения")
        return "macro"

    return "hotkey"
}

GetBindTypeText(type) {
    type := NormalizeBindType(type)

    switch type {
        case "hotkey":
            return "⌨ Клавиша"
        case "hotstring":
            return "✏ Текст"
        case "macro":
            return "📢 Макрос"
        default:
            return "⌨ Клавиша"
    }
}

GetBindEnabledText(enabled) {
    return (enabled + 0) ? "Вкл" : "Выкл"
}

GetBindRuntimeStatusText(bind) {
    if !(bind["enabled"] + 0)
        return "Выкл"

    if !IsBindCategoryEnabled(bind["category"])
        return "Кат. выкл"

    return "Вкл"
}

EncodeBindField(value) {
    value := "" value
    value := StrReplace(value, "\", "\\")
    value := StrReplace(value, "|", "\p")
    value := StrReplace(value, "`r`n", "\n")
    value := StrReplace(value, "`n", "\n")
    value := StrReplace(value, "`r", "\n")
    return value
}

DecodeBindField(value) {
    value := StrReplace(value, "\n", "`n")
    value := StrReplace(value, "\p", "|")
    value := StrReplace(value, "\\", "\")
    return value
}

NormalizeBindCategory(category) {
    category := Trim(category)
    if (category = "" || category = "Все" || IsLegacyDefaultBindCategory(category))
        return "Все"
    return category
}

ReadBinds() {
    binds := []

    for _, category in GetBindCategories(false) {
        filePath := GetBindCategoryFile(category)
        for _, bind in ReadBindsFromFile(filePath, "ReadBinds")
            binds.Push(bind)
    }

    return binds
}

ReadBindsFromFile(filePath, context := "ReadBinds") {
    binds := []

    if !FileExist(filePath)
        return binds

    for _, line in ReadFileLines(filePath, context) {
        if (Trim(line) = "")
            continue

        part := StrSplit(line, "|")

        ; Новый формат без ID:
        ; type|category|name|trigger|content|enabled
        ; Важно: если в content случайно есть символ |, берём enabled из последней колонки,
        ; а content собираем обратно из всех колонок между trigger и enabled.
        if (part.Length >= 6 && IsBindTypeValue(part[1])) {
            enabledValue := IsIntegerText(part[part.Length]) ? (part[part.Length] + 0) : 1
            contentValue := JoinArrayRange(part, 5, part.Length - 1, "|")

            binds.Push(Map(
                "type", NormalizeBindType(DecodeBindField(part[1])),
                "category", NormalizeBindCategory(DecodeBindField(part[2])),
                "name", DecodeBindField(part[3]),
                "trigger", DecodeBindField(part[4]),
                "content", DecodeBindField(contentValue),
                "enabled", enabledValue
            ))
            continue
        }

        ; Старый legacy-формат с ID:
        ; id|type|category|name|trigger|content|enabled
        ; Тут также защищаемся от | внутри content.
        if (part.Length >= 7 && IsIntegerText(part[1])) {
            enabledValue := IsIntegerText(part[part.Length]) ? (part[part.Length] + 0) : 1
            contentValue := JoinArrayRange(part, 6, part.Length - 1, "|")

            binds.Push(Map(
                "type", NormalizeBindType(DecodeBindField(part[2])),
                "category", NormalizeBindCategory(DecodeBindField(part[3])),
                "name", DecodeBindField(part[4]),
                "trigger", DecodeBindField(part[5]),
                "content", DecodeBindField(contentValue),
                "enabled", enabledValue
            ))
        }
    }

    return binds
}

IsIntegerText(value) {
    return RegExMatch(Trim(value), "^-?\d+$")
}

JoinArrayRange(arr, startIndex, endIndex, delimiter := "|") {
    result := ""

    if (endIndex < startIndex)
        return result

    Loop endIndex - startIndex + 1 {
        index := startIndex + A_Index - 1
        if (A_Index > 1)
            result .= delimiter
        result .= arr[index]
    }

    return result
}

IsBindTypeValue(value) {
    value := NormalizeBindType(value)
    return (value = "hotkey" || value = "hotstring" || value = "macro")
}

WriteBinds(binds) {
    global bindsDir

    try {
        DirCreate(bindsDir)

        grouped := Map()
        for _, category in GetBindCategories(false)
            grouped[category] := []

        seenTriggers := Map()
        for _, bind in binds {
            trigger := Trim(bind["trigger"])
            if (trigger = "")
                continue

            ; Триггер теперь является уникальным идентификатором бинда.
            ; Если случайно встретился дубль — оставляем первую запись, вторую пропускаем.
            if seenTriggers.Has(trigger)
                continue
            seenTriggers[trigger] := true

            category := Trim(bind["category"])
            if !grouped.Has(category) {
                category := "Все"
                bind["category"] := category
            }
            grouped[category].Push(bind)
        }

        for category, categoryBinds in grouped
            WriteBindsToFile(GetBindCategoryFile(category), categoryBinds)

        return true
    } catch as err {
        LogError("WriteBinds", "Ошибка записи файлов биндов по категориям", err.Message)
        MsgBox("Не удалось сохранить бинды.`n`n" err.Message, "Бинды", "Iconx")
        return false
    }
}

WriteBindsToFile(filePath, binds) {
    file := FileOpen(filePath, "w")

    for _, bind in binds {
        ; Новый формат без ID:
        ; type|category|name|trigger|content|enabled
        line := EncodeBindField(bind["type"]) "|"
        line .= EncodeBindField(bind["category"]) "|"
        line .= EncodeBindField(bind["name"]) "|"
        line .= EncodeBindField(bind["trigger"]) "|"
        line .= EncodeBindField(bind["content"]) "|"
        line .= (bind["enabled"] + 0)
        file.WriteLine(line)
    }

    file.Close()
}

GetBindByTrigger(trigger) {
    trigger := Trim(trigger)

    if (trigger = "")
        return ""

    for _, bind in ReadBinds() {
        if (bind["trigger"] = trigger)
            return bind
    }

    return ""
}

BindTriggerExists(trigger, exceptTrigger := "") {
    trigger := Trim(trigger)
    exceptTrigger := Trim(exceptTrigger)

    if (trigger = "")
        return false

    for _, bind in ReadBinds() {
        if (bind["trigger"] = trigger && bind["trigger"] != exceptTrigger)
            return true
    }

    return false
}

IsBindTriggerSuffixConflict(a, b) {
    a := Trim(a)
    b := Trim(b)
    if (a = "" || b = "" || a = b)
        return false
    if (StrLen(a) < 2 || StrLen(b) < 2)
        return false
    if (StrLen(a) <= StrLen(b))
        return (SubStr(b, 1 - StrLen(a)) = a)
    return (SubStr(a, 1 - StrLen(b)) = b)
}

FindSimilarBindTriggers(trigger, bindType := "hotkey", exceptTrigger := "") {
    trigger := Trim(trigger)
    exceptTrigger := Trim(exceptTrigger)
    bindType := NormalizeBindType(bindType)
    conflicts := []
    if (trigger = "")
        return conflicts
    checkSuffix := (bindType = "hotstring" || bindType = "macro")
    for _, bind in ReadBinds() {
        other := Trim(bind["trigger"])
        if (other = "" || other = exceptTrigger)
            continue
        otherType := NormalizeBindType(bind["type"])
        if (other = trigger) {
            conflicts.Push(Map("trigger", other, "name", bind["name"], "type", otherType, "kind", "exact"))
            continue
        }
        otherIsText := (otherType = "hotstring" || otherType = "macro")
        if (checkSuffix && otherIsText && IsBindTriggerSuffixConflict(trigger, other))
            conflicts.Push(Map("trigger", other, "name", bind["name"], "type", otherType, "kind", "suffix"))
    }
    return conflicts
}

FormatBindConflictMessage(conflicts) {
    lines := "Найдены похожие или совпадающие триггеры:`n`n"
    for _, c in conflicts {
        kindText := (c["kind"] = "exact") ? "точное совпадение" : "похожее окончание"
        lines .= "• " c["trigger"] "  (" c["name"] ") — " kindText "`n"
    }
    lines .= "`nТакие бинды часто конфликтуют (например «ит1» и «дмит1»).`nВсё равно сохранить?"
    return lines
}

ScanAllBindDuplicatePairs() {
    binds := ReadBinds()
    pairs := []
    seen := Map()
    total := binds.Length
    Loop total {
        i := A_Index
        a := binds[i]
        aTrigger := Trim(a["trigger"])
        if (aTrigger = "")
            continue
        aType := NormalizeBindType(a["type"])
        aIsText := (aType = "hotstring" || aType = "macro")
        Loop total - i {
            j := i + A_Index
            b := binds[j]
            bTrigger := Trim(b["trigger"])
            if (bTrigger = "")
                continue
            bType := NormalizeBindType(b["type"])
            bIsText := (bType = "hotstring" || bType = "macro")
            kind := ""
            if (aTrigger = bTrigger)
                kind := "exact"
            else if (aIsText && bIsText && IsBindTriggerSuffixConflict(aTrigger, bTrigger))
                kind := "suffix"
            if (kind = "")
                continue
            key := (aTrigger < bTrigger) ? (aTrigger "|" bTrigger "|" kind) : (bTrigger "|" aTrigger "|" kind)
            if seen.Has(key)
                continue
            seen[key] := true
            pairs.Push(Map("kind", kind, "aTrigger", aTrigger, "aName", a["name"], "aType", aType, "aCategory", a["category"], "bTrigger", bTrigger, "bName", b["name"], "bType", bType, "bCategory", b["category"]))
        }
    }
    return pairs
}

BuildBindDuplicatesReport(pairs) {
    if (pairs.Length = 0)
        return "Дубликаты и похожие окончания не найдены."
    text := "Найдено пар: " pairs.Length "`n————————————————————————`n`n"
    for _, p in pairs {
        kindText := (p["kind"] = "exact") ? "ТОЧНОЕ СОВПАДЕНИЕ" : "похожее окончание"
        text .= "▸ " kindText "`n"
        text .= "  1) " p["aTrigger"] "  —  " p["aName"] "`n"
        text .= "     " GetBindTypeText(p["aType"]) " / " p["aCategory"] "`n"
        text .= "  2) " p["bTrigger"] "  —  " p["bName"] "`n"
        text .= "     " GetBindTypeText(p["bType"]) " / " p["bCategory"] "`n`n"
    }
    text .= "————————————————————————`nПример: «ит1» и «дмит1»."
    return text
}

ShowBindDuplicatesScan(*) {
    global colorBg, colorCard, colorAccent, colorText, colorMuted
    pairs := ScanAllBindDuplicatePairs()
    report := BuildBindDuplicatesReport(pairs)
    dlg := Gui("+Border", "Поиск дубликатов")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")
    dlg.Add("Text", "x0 y0 w520 h420 Background" colorBg)
    dlg.Add("Text", "x18 y18 w484 h50 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x34 y28 w400 h24 Background" colorCard, "Поиск дубликатов")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    statusLine := (pairs.Length = 0) ? "Конфликтов не найдено" : ("Найдено пар: " pairs.Length)
    dlg.Add("Text", "x34 y52 w400 h18 Background" colorCard, statusLine)
    dlg.SetFont("s9 Norm c" colorText, "Segoe UI")
    dlg.Add("Edit", "x18 y80 w484 h280 +Multi +ReadOnly -Wrap +VScroll Background" colorCard " c" colorText, report)
    closeBtn := dlg.Add("Text", "x382 y372 w120 h30 +0x200 Center Background" colorAccent " c" colorText, "Закрыть")
    BindTextButton(closeBtn, colorAccent, (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())
    dlg.Show("w520 h420")
    try WinActivate(dlg.Hwnd)
}

BindMatchesSearch(bind, search) {
    search := Trim(search)
    if (search = "")
        return true

    haystack := bind["name"] " " bind["trigger"] " " bind["content"] " " bind["category"]
    return InStr(haystack, search, false) > 0
}

BindMatchesCategory(bind, category) {
    category := Trim(category)
    return (category = "" || category = "Все" || bind["category"] = category)
}

GetFilteredBinds(search := "", category := "Все") {
    binds := ReadBinds()
    filtered := []
    for _, bind in binds {
        if BindMatchesCategory(bind, category) && BindMatchesSearch(bind, search)
            filtered.Push(bind)
    }
    return SortBinds(filtered)
}

SortBinds(binds) {
    global BindsSortColumn, BindsSortAscending

    sorted := []
    for _, bind in binds {
        inserted := false
        Loop sorted.Length {
            compare := CompareBinds(bind, sorted[A_Index], BindsSortColumn)
            if ((BindsSortAscending && compare <= 0) || (!BindsSortAscending && compare >= 0)) {
                sorted.InsertAt(A_Index, bind)
                inserted := true
                break
            }
        }
        if (!inserted)
            sorted.Push(bind)
    }
    return sorted
}

CompareBinds(a, b, column) {
    aValue := GetBindSortValue(a, column)
    bValue := GetBindSortValue(b, column)
    return StrCompare(aValue, bValue, false)
}

GetBindSortValue(bind, column) {
    if (column = 1)
        return GetBindTypeText(bind["type"])
    if (column = 2)
        return bind["category"]
    if (column = 3)
        return bind["name"]
    if (column = 4)
        return bind["trigger"]
    return GetBindRuntimeStatusText(bind)
}

RefreshBindsList(*) {
    global BindsListCtrl, BindsSearchCtrl, BindsCategoryCtrl, BindsEnabledCtrl, BindsCategoryStatusCtrl, bindsEnabled

    if !IsObject(BindsListCtrl)
        return

    if IsObject(BindsEnabledCtrl)
        BindsEnabledCtrl.Value := bindsEnabled ? 1 : 0

    search := IsObject(BindsSearchCtrl) ? BindsSearchCtrl.Value : ""
    category := IsObject(BindsCategoryCtrl) ? BindsCategoryCtrl.Text : "Все"

    if IsObject(BindsCategoryStatusCtrl) {
        if (category = "" || category = "Все")
            BindsCategoryStatusCtrl.Text := "Все категории"
        else
            BindsCategoryStatusCtrl.Text := IsBindCategoryEnabled(category) ? "Категория вкл" : "Категория выкл"
    }

    BindsListCtrl.Delete()

    for _, bind in GetFilteredBinds(search, category) {
        ; 6-я скрытая колонка хранит ключ бинда — trigger.
        BindsListCtrl.Add(, GetBindTypeText(bind["type"]), bind["category"], bind["name"], bind["trigger"], GetBindRuntimeStatusText(bind), bind["trigger"])
    }
    UpdateBindPreview()
}

OnBindListSelect(*) {
    UpdateBindPreview()
}

UpdateBindPreview() {
    global BindsPreviewCtrl
    if !IsObject(BindsPreviewCtrl)
        return
    trigger := GetSelectedBindTrigger()
    if (trigger = "") {
        BindsPreviewCtrl.Value := "Выберите бинд в списке"
        return
    }
    bind := GetBindByTrigger(trigger)
    if !IsObject(bind) {
        BindsPreviewCtrl.Value := "Бинд не найден"
        return
    }
    text := GetBindTypeText(bind["type"]) " / " bind["category"] "`n"
    text .= bind["name"] "  ·  " bind["trigger"] "`n"
    text .= "————————————————`n"
    text .= bind["content"]
    BindsPreviewCtrl.Value := text
}

ExportBindsToFile(*) {
    global bindsDir
    savePath := FileSelect("S", bindsDir "\binds_export.csv", "Экспорт биндов", "Бинды CSV (*.csv)")
    if (savePath = "")
        return
    if !InStr(StrLower(savePath), ".csv")
        savePath .= ".csv"

    binds := ReadBinds()
    try {
        file := FileOpen(savePath, "w", "UTF-8")
        for _, bind in binds {
            line := EncodeBindField(bind["type"]) "|"
            line .= EncodeBindField(bind["category"]) "|"
            line .= EncodeBindField(bind["name"]) "|"
            line .= EncodeBindField(bind["trigger"]) "|"
            line .= EncodeBindField(bind["content"]) "|"
            line .= (bind["enabled"] + 0)
            file.WriteLine(line)
        }
        file.Close()
        ShowToast("✓ Экспорт: " binds.Length " биндов")
        ShowAppDialog("Экспорт биндов", "Сохранено: " binds.Length " биндов`n`n" savePath)
    } catch as err {
        LogError("ExportBindsToFile", "Ошибка экспорта", err.Message)
        ShowAppDialog("Экспорт биндов", "Не удалось сохранить файл.`n`n" err.Message)
    }
}

TestSelectedBind(*) {
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted
    trigger := GetSelectedBindTrigger()
    if (trigger = "") {
        ShowAppDialog("Тест бинда", "Выберите бинд в списке.")
        return
    }
    bind := GetBindByTrigger(trigger)
    if !IsObject(bind) {
        ShowAppDialog("Тест бинда", "Бинд не найден.")
        return
    }

    preview := "Тип: " GetBindTypeText(bind["type"]) "`n"
    preview .= "Триггер: " bind["trigger"] "`n"
    preview .= "Категория: " bind["category"] "`n"
    preview .= "————————————————`n"
    preview .= "Что уйдёт в чат / Send:`n`n"
    preview .= bind["content"]
    preview .= "`n`n————————————————`nНичего не отправлено в игру — только превью."

    dlg := Gui("+Border", "Тест бинда")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")
    dlg.Add("Text", "x0 y0 w520 h420 Background" colorBg)
    dlg.Add("Text", "x18 y18 w484 h50 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x34 y28 w400 h24 Background" colorCard, "Тест: " bind["name"])
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x34 y52 w400 h18 Background" colorCard, "Превью без отправки в игру")
    dlg.SetFont("s9 Norm c" colorText, "Segoe UI")
    dlg.Add("Edit", "x18 y80 w484 h280 +Multi +ReadOnly -Wrap +VScroll Background" colorCard " c" colorText, preview)
    closeBtn := dlg.Add("Text", "x382 y372 w120 h30 +0x200 Center Background" colorAccent " c" colorText, "Закрыть")
    BindTextButton(closeBtn, colorAccent, (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())
    dlg.Show("w520 h420")
    try WinActivate(dlg.Hwnd)
}

RefreshBindCategoryFilter(selectedCategory := "") {
    BuildMainWindow("Binds")
}

ToggleAllBindsEnabled(*) {
    global bindsEnabled, BindsEnabledCtrl, settingsFile

    bindsEnabled := (IsObject(BindsEnabledCtrl) && BindsEnabledCtrl.Value) ? 1 : 0
    TryIniWrite(bindsEnabled, settingsFile, "Main", "bindsEnabled", "ToggleAllBindsEnabled")
    RegisterCustomBinds()
    RefreshBindsList()
}

GetSelectedBindTrigger() {
    triggers := GetSelectedBindTriggers()
    return (triggers.Length > 0) ? triggers[1] : ""
}

GetSelectedBindTriggers() {
    global BindsListCtrl

    triggers := []

    if !IsObject(BindsListCtrl)
        return triggers

    row := 0
    while (row := BindsListCtrl.GetNext(row)) {
        trigger := Trim(BindsListCtrl.GetText(row, 6))
        if (trigger != "")
            triggers.Push(trigger)
    }

    return triggers
}

ArrayHasValue(arr, value) {
    for _, item in arr {
        if (item = value)
            return true
    }
    return false
}

RegisterCustomBinds() {
    global RegisteredBindTriggers, bindsEnabled

    UnregisterCustomBinds()
    RegisteredBindTriggers := []

    if (!bindsEnabled)
        return

    for _, bind in ReadBinds() {
        if !(bind["enabled"] + 0)
            continue

        if !IsBindCategoryEnabled(bind["category"])
            continue

        trigger := Trim(bind["trigger"])
        if (trigger = "")
            continue

        try {
            if (bind["type"] = "hotstring") {
                pattern := ":*?:" trigger
                Hotstring(pattern, ExecuteBindByTrigger.Bind(trigger), "On")
                RegisteredBindTriggers.Push(Map("type", "hotstring", "trigger", pattern))
            } else if (bind["type"] = "macro") {
                pattern := ":*?:" trigger
                Hotstring(pattern, ExecuteBindByTrigger.Bind(trigger), "On")
                RegisteredBindTriggers.Push(Map("type", "macro", "trigger", pattern))
            } else {
                Hotkey(trigger, ExecuteBindByTrigger.Bind(trigger), "On")
                RegisteredBindTriggers.Push(Map("type", "hotkey", "trigger", trigger))
            }
        } catch as err {
            LogError("RegisterCustomBinds", "Ошибка регистрации бинда: " trigger, err.Message)
            ShowToast("⚠ Бинд «" bind["name"] "»: " err.Message, 2800)
        }
    }
}

UnregisterCustomBinds() {
    global RegisteredBindTriggers

    for _, item in RegisteredBindTriggers {
        try {
            if (item["type"] = "hotstring" || item["type"] = "macro")
                Hotstring(item["trigger"], "Off")
            else
                Hotkey(item["trigger"], "Off")
        }
    }
}

ExecuteBindByTrigger(trigger, *) {
    global bindsEnabled

    if (!bindsEnabled)
        return

    bind := GetBindByTrigger(trigger)
    if !IsObject(bind)
        return
    if !(bind["enabled"] + 0)
        return
    if !IsBindCategoryEnabled(bind["category"])
        return

    switch bind["type"] {
        case "hotstring":
            BindSendTextWithKeys(bind["content"])
        case "macro":
            ExecuteHotkeyBindContent(bind["content"])
        case "hotkey":
            ExecuteHotkeyBindContent(bind["content"])
        default:
            ExecuteHotkeyBindContent(bind["content"])
    }
}

ExecuteHotkeyBindContent(content) {
    for _, line in StrSplit(content, "`n") {
        line := Trim(line)
        if (line = "")
            continue

        if RegExMatch(line, "i)^SendText\s*,?\s*(.*)$", &sendTextMatch) {
            BindSendTextSafe(sendTextMatch[1])
        }
        else if RegExMatch(line, "i)^SendInput\s*,\s*(.*)$", &sendMatch) {
            SendInput(BindNormalizeCommandArg(sendMatch[1]))
        }
        else if RegExMatch(line, "i)^SendInput\s+(.+)$", &sendMatch) {
            SendInput(BindNormalizeCommandArg(sendMatch[1]))
        }
        else if RegExMatch(line, "i)^Send\s*,\s*(.*)$", &sendMatch) {
            Send(BindNormalizeCommandArg(sendMatch[1]))
        }
        else if RegExMatch(line, "i)^Send\s+(.+)$", &sendMatch) {
            Send(BindNormalizeCommandArg(sendMatch[1]))
        }
        else if RegExMatch(line, "i)^SendMessage\s*,\s*(.*)$", &messageMatch) {
            ExecuteBindSendMessage(messageMatch[1])
        }
        else if RegExMatch(line, "i)^Sleep\s*,?\s*(\d+)$", &sleepMatch) {
            Sleep(sleepMatch[1] + 0)
        }
        else {
            BindSendTextSafe(line)
        }
    }
}

BindSendTextSafe(text) {
    text := BindNormalizeCommandArg(text)

    ; Если в тексте есть русские буквы — перед вводом включаем RU-раскладку.
    ; Это фиксит проблему, когда при EN-раскладке в чате игры появляется ?????.
    if RegExMatch(text, "[А-Яа-яЁё]") {
        SetKeyboardLayoutForActiveWindow("00000419")
        Sleep(100)
    }

    SendText(text)
}

; Текстовые бинды обычно печатают содержимое буквально, но для управления
; курсором поддерживаем безопасные AHK-клавиши, например: Cheat{Left 9}.
BindSendTextWithKeys(text) {
    position := 1
    keyPattern := "i)\{((?:Left|Right|Up|Down|Home|End|PgUp|PgDn|Delete|Del|Backspace|BS|Enter|Tab|Esc|Space|F(?:[1-9]|1[0-9]|2[0-4]))(?:\s+\d+)?)\}"

    while RegExMatch(text, keyPattern, &keyMatch, position) {
        literalText := SubStr(text, position, keyMatch.Pos - position)
        if (literalText != "")
            BindSendTextSafe(literalText)

        Send("{" keyMatch[1] "}")
        position := keyMatch.Pos + keyMatch.Len
    }

    literalText := SubStr(text, position)
    if (literalText != "")
        BindSendTextSafe(literalText)
}

BindNormalizeCommandArg(value) {
    value := Trim(value)

    ; Поддержка формата из биндов:
    ; SendText "текст"
    ; Send "{F6}"
    ; SendInput "текст"
    if (SubStr(value, 1, 1) = Chr(34) && SubStr(value, -1) = Chr(34)) {
        value := SubStr(value, 2, StrLen(value) - 2)
        value := StrReplace(value, Chr(34) Chr(34), Chr(34))
    }

    return value
}

SetKeyboardLayoutForActiveWindow(layoutId := "00000419") {
    try {
        hkl := DllCall("LoadKeyboardLayout", "Str", layoutId, "UInt", 1, "Ptr")
        hwnd := WinExist("A")
        if (hwnd)
            PostMessage(0x50, 0, hkl,, "ahk_id " hwnd)
    } catch as err {
        LogError("SetKeyboardLayoutForActiveWindow", "Не удалось переключить раскладку", err.Message)
    }
}

ExecuteBindSendMessage(argsText) {
    args := StrSplit(argsText, ",")
    message := Trim(GetArrayValue(args, 1, ""))
    wParam := Trim(GetArrayValue(args, 2, ""))
    lParam := Trim(GetArrayValue(args, 3, ""))
    control := Trim(GetArrayValue(args, 4, ""))
    winTitle := Trim(GetArrayValue(args, 5, "A"))

    if (wParam = "")
        wParam := 0
    if (lParam = "")
        lParam := 0

    try SendMessage(message, wParam, lParam, control, winTitle)
    catch as err {
        LogError("ExecuteBindSendMessage", "Ошибка SendMessage: " argsText, err.Message)
    }
}

; ------------------------------------------------------------
; 03. Timers and background checks
; ------------------------------------------------------------

; =========================
; 📊 LOG CHECK
; =========================
CheckLog(*) {
    global nick, norm, pmCount, lastSize, isFirstRun, beepPlayed, logFile
    global saveFile, dotGreen, dotRed, StatusDotCtrl, PMCountTextCtrl
    global diagnosticLastCheckMs, diagnosticLastProcessedLines, diagnosticLastPmChanges, diagnosticLastLogSize, diagnosticLastReadBytes
    global diagnosticCheckLogSamples, diagnosticCheckLogTotalMs, diagnosticCheckLogMaxMs
    global cloudAccessState, chatlogReadErrorStreak, lastChatlogChangeTick

    ; Счётчик работает только при подтверждённом доступе Cloud.
    if (cloudAccessState != "ok")
        return
    checkLogStartedAt := GetHighResolutionMilliseconds()
    processedLineCount := 0
    pmCountChanged := false
    if (logFile = "" || !FileExist(logFile)) {
        chatlogReadErrorStreak += 1
        return
    }

    try currentSize := FileGetSize(logFile)
    catch as err {
        chatlogReadErrorStreak += 1
        LogError("CheckLog", "Не удалось получить размер chatlog.txt", err.Message)
        return
    }
    if (isFirstRun) {
        lastSize := currentSize
        isFirstRun := false
        return
    }
    if (currentSize < lastSize)
        lastSize := 0
    if (currentSize = 0) {
        lastSize := 0
        return
    }
    if (currentSize <= lastSize)
        return

    bytesToRead := currentSize - lastSize

    try file := FileOpen(logFile, "r")
    catch as err {
        chatlogReadErrorStreak += 1
        LogError("CheckLog", "Не удалось открыть chatlog.txt", err.Message)
        return
    }
    try {
        file.Seek(lastSize, 0)
        while (!file.AtEOF) {
            line := file.ReadLine()
            if (!line)
                continue
            processedLineCount++
            if !InStr(line, nick)
                continue
            if RegExMatch(line, "^\[\d{2}:\d{2}:\d{2}\] Администратор " . nick . "\[\d+\] для ") {
                pmCount++
                pmCountChanged := true
                SavePmLogFromLine(line)
            }
            SavePunishmentFromLine(line)
        }
        lastSize := file.Pos
        file.Close()
    } catch as err {
        try file.Close()
        chatlogReadErrorStreak += 1
        LogError("CheckLog", "Ошибка чтения chatlog.txt", err.Message)
        return
    }

    chatlogReadErrorStreak := 0
    if (currentSize > 0)
        lastChatlogChangeTick := A_TickCount

    diagnosticLastCheckMs := Round(GetHighResolutionMilliseconds() - checkLogStartedAt, 3)
    diagnosticLastProcessedLines := processedLineCount
    diagnosticLastPmChanges := pmCountChanged ? 1 : 0
    diagnosticLastLogSize := currentSize
    diagnosticLastReadBytes := bytesToRead
    diagnosticCheckLogSamples += 1
    diagnosticCheckLogTotalMs += diagnosticLastCheckMs
    if (diagnosticLastCheckMs > diagnosticCheckLogMaxMs)
        diagnosticCheckLogMaxMs := diagnosticLastCheckMs

    if !pmCountChanged
        return

    TryFileDelete(saveFile, "CheckLog", "Ошибка удаления pm_count.txt перед сохранением")
    if !TryFileAppend(pmCount, saveFile, "CheckLog", "Ошибка записи pm_count.txt")
        ShowToast("⚠ Не удалось сохранить счётчик PM", 2200)

    if IsObject(PMCountTextCtrl)
        PMCountTextCtrl.Text := "PM: " pmCount
    UpdatePMDisplay()

    if (pmCount >= norm) {
        if IsObject(StatusDotCtrl) {
            StatusDotCtrl.Text := "●"
            StatusDotCtrl.SetFont("c" dotGreen)
        }
        beepPlayed := true
    } else {
        if IsObject(StatusDotCtrl) {
            StatusDotCtrl.Text := "●"
            StatusDotCtrl.SetFont("c" dotRed)
        }
        beepPlayed := false
    }
}

; =========================
; ⏰ AUTO RESET
; =========================
CheckAutoReset(*) {
    global autoResetEnabled, resetHour, resetMinute, lastResetDate
    global pmCount, beepPlayed, saveFile, settingsFile, dotRed, StatusDotCtrl, PMCountTextCtrl
    if (!autoResetEnabled)
        return

    nowDate := FormatTime(A_Now, "yyyyMMdd")
    nowKey := FormatTime(A_Now, "yyyyMMddHHmm")
    targetKey := nowDate . Format("{:02}{:02}", resetHour, resetMinute)

    if (lastResetDate = nowDate)
        return
    if (nowKey < targetKey)
        return

    SaveDayStats()
    pmCount := 0
    TryFileDelete(saveFile, "CheckAutoReset", "Ошибка удаления pm_count.txt при автосбросе")
    lastResetDate := nowDate
    if !TryIniWrite(lastResetDate, settingsFile, "Main", "lastResetDate", "CheckAutoReset")
        ShowToast("⚠ Не удалось сохранить дату автосброса", 2200)
    if IsObject(PMCountTextCtrl)
        PMCountTextCtrl.Text := "PM:0"
    UpdatePMDisplay()
    if IsObject(StatusDotCtrl) {
        StatusDotCtrl.Text := "●"
        StatusDotCtrl.SetFont("c" dotRed)
    }
    beepPlayed := false
    AppendPmLog("Действие", "Сброшен счетчик PM")
}

; ------------------------------------------------------------
; 04. HUD actions
; ------------------------------------------------------------

; =========================
; 👁 TOGGLE GUI
; =========================
; ------------------------------------------------------------
; 05. Settings window
; ------------------------------------------------------------

; =========================
; 📂 SETTINGS MENU
; =========================
OpenMenu(*) {
    global SettingsGui, settingsMenuHidden, settingsMenuBuilding, lastMenuOpenTick, menuX, menuY

    if (settingsMenuBuilding)
        return

    if IsObject(SettingsGui) {
        if (A_TickCount - lastMenuOpenTick < 500)
            return
        if (settingsMenuHidden) {
            SettingsGui.Show("w920 h590 x" menuX " y" menuY)
            settingsMenuHidden := false
            lastMenuOpenTick := A_TickCount
            return
        }
        CloseSettings()
        return
    }

    BuildMainWindow("Dashboard")
}

BuildMainWindow(initialView := "Dashboard") {
    global SettingsGui, settingsMenuHidden, settingsMenuBuilding, lastMenuOpenTick, GuiViewCtrls, NavButtonCtrls, NavIndicatorCtrls, CurrentView
    global menuX, menuY, appVersion, colorBg, colorSidebar, colorText, colorMuted, colorCard, colorCardAlt, colorRed, colorGreen
    global NotificationButtonCtrl, NotificationIndicatorCtrl

    if (settingsMenuBuilding)
        return

    settingsMenuBuilding := true
    Critical("On")

    SaveMenuPosition()
    SafeDestroyGui(&SettingsGui)
    settingsMenuHidden := false
    ResetDashboardControls()
    ResetDiagnosticsControls()
    ResetCloudControls()
    ResetNotificationControls()
    GuiViewCtrls := Map()
    NavButtonCtrls := Map()
    NavIndicatorCtrls := Map()
    CurrentView := ""

    SettingsGui := Gui("+Border -Caption", "ChesNova " appVersion)
    SettingsGui.OnEvent("Close", CloseSettings)
    SettingsGui.BackColor := colorBg
    SettingsGui.MarginX := 0
    SettingsGui.MarginY := 0
    SettingsGui.SetFont("s10 c" colorText, "Segoe UI")

    windowHeight := 590
    ; Верхняя строка и левая панель повторяют структуру макета.
    SettingsGui.Add("Text", "x0 y0 w920 h28 Background" colorCard)
    SettingsGui.Add("Text", "x0 y28 w216 h" (windowHeight - 28) " Background" colorSidebar)
    SettingsGui.Add("Text", "x216 y28 w704 h" (windowHeight - 28) " Background" colorBg)
    SettingsGui.Add("Text", "x0 y27 w920 h1 Background" uiDivider)
    SettingsGui.Add("Text", "x215 y28 w1 h" (windowHeight - 28) " Background" uiDivider)
    SettingsGui.SetFont("s10 Bold c" colorText, "Segoe UI")
    SettingsGui.Add("Text", "x18 y5 w300 h18 Background" colorCard, "ChesNova " appVersion)
    SettingsGui.SetFont("s10 Bold c" colorText, "Segoe UI")
    cloudBtn := SettingsGui.Add("Text", "x704 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "☁")
    BindTextButton(cloudBtn, colorCardAlt, (*) => ShowView("Cloud"))
    diagnosticsBtn := SettingsGui.Add("Text", "x670 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "D")
    BindTextButton(diagnosticsBtn, colorCardAlt, (*) => ShowView("Diagnostics"))
    settingsBtn := SettingsGui.Add("Text", "x738 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "⚙")
    BindTextButton(settingsBtn, colorCardAlt, (*) => ShowView("Settings"))
    NotificationButtonCtrl := SettingsGui.Add("Text", "x772 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "🔔")
    BindTextButton(NotificationButtonCtrl, colorCardAlt, OpenNotifications)
    NotificationButtonCtrl.SetFont("s10 Norm c" colorText, "Segoe UI Emoji")
    NotificationIndicatorCtrl := SettingsGui.Add("Text", "x794 y2 w7 h8 +0x200 Center Background" colorCardAlt " c" colorGreen, "●")
    NotificationIndicatorCtrl.SetFont("s6 Bold c" colorGreen, "Segoe UI")
    hideWindowBtn := SettingsGui.Add("Text", "x846 y3 w32 h22 +0x200 Center Background" colorCardAlt " c" colorText, Chr(0x2212))
    BindTextButton(hideWindowBtn, colorCardAlt, HideSettingsMenu)
    closeWindowBtn := SettingsGui.Add("Text", "x882 y3 w32 h22 +0x200 Center Background" colorCardAlt " c" colorText, Chr(0x00D7))
    BindTextButton(closeWindowBtn, colorCardAlt, CloseSettings)

    ; Сайдбар: сверху частое, снизу редкое
    BuildNavButton("Dashboard", "⌂   Главная", 48)
    BuildNavButton("Punishments", "⚖   Наказания", 88)
    BuildNavButton("PMLogs", "▤   PM логи", 128)
    BuildNavButton("NormHistory", "◷   Норма", 168)
    BuildNavButton("DaysOff", "☀   Отгулы", 208)
    BuildNavButton("Binds", "⌨   Бинды", 248)
    BuildNavButton("Scripts", "✦   Скрипты", 288)
    BuildNavButton("Tester", "🧪  Тестировщик", 328)
    BuildNavButton("Updates", "↻   Обновления", windowHeight - 82)
    BuildNavButton("Help", "?   Помощь", windowHeight - 42)

    DashboardView()
    PMLogsView()
    PunishmentsView()
    NormHistoryView()
    DaysOffView()
    BindsView()
    SettingsView()
    UpdatesView()
    HelpView()
    CloudView()
    DiagnosticsView()
    ScriptsViewCompact()
    TesterView()
    UpdateNotificationIndicator()

    if (menuX = "Center")
        SettingsGui.Show("w920 h" windowHeight " xCenter yCenter")
    else
        SettingsGui.Show("w920 h" windowHeight " x" menuX " y" menuY)
    ShowView(initialView)
    lastMenuOpenTick := A_TickCount
    settingsMenuBuilding := false
    Critical("Off")
}

BuildNavButton(viewName, label, y) {
    global SettingsGui, NavButtonCtrls, NavIndicatorCtrls, colorSidebar, colorMuted

    SettingsGui.SetFont("s10 Norm c" colorMuted, "Segoe UI")
    ctrl := SettingsGui.Add("Text", "x24 y" y " w178 h34 +0x200 Background" colorSidebar, "  " label)
    ctrl.OnEvent("Click", (*) => ShowView(viewName))
    NavButtonCtrls[viewName] := ctrl
    indicator := SettingsGui.Add("Text", "x14 y" (y + 6) " w3 h22 Background" colorSidebar)
    NavIndicatorCtrls[viewName] := indicator
    return ctrl
}

BuildSidebarActionButton(label, y, callback) {
    global SettingsGui, colorCard, colorMuted

    SettingsGui.SetFont("s10 Norm c" colorMuted, "Segoe UI")
    ctrl := SettingsGui.Add("Text", "x24 y" y " w178 h34 +0x200 Background" colorCard, "  " label)
    BindTextButton(ctrl, colorCard, callback)
    return ctrl
}

AddViewControl(viewName, controlType, options, text := "") {
    global SettingsGui, GuiViewCtrls

    if (!GuiViewCtrls.Has(viewName))
        GuiViewCtrls[viewName] := []

    ctrl := SettingsGui.Add(controlType, options, text)
    GuiViewCtrls[viewName].Push(ctrl)
    return ctrl
}

ShowView(viewName, *) {
    global GuiViewCtrls, NavButtonCtrls, NavIndicatorCtrls, CurrentView
    global selectedPunishmentDays, selectedPunishmentType, punishmentSearch
    global PmLogsTextCtrl, PMLogsSearchCtrl
    global colorAccent, colorText, colorMuted, colorSidebar, colorCardAlt

    if (!GuiViewCtrls.Has(viewName))
        return

    for name, ctrls in GuiViewCtrls {
        for _, ctrl in ctrls
            ctrl.Visible := (name = viewName)
    }

    for name, ctrl in NavButtonCtrls {
        if (name = viewName) {
            ctrl.Opt("Background" colorCardAlt " c" colorText)
            ctrl.SetFont("s10 Bold c" colorText, "Segoe UI")
            if NavIndicatorCtrls.Has(name)
                NavIndicatorCtrls[name].Opt("Background" colorAccent)
        } else {
            ctrl.Opt("Background" colorSidebar " c" colorMuted)
            ctrl.SetFont("s10 Norm c" colorMuted, "Segoe UI")
            if NavIndicatorCtrls.Has(name)
                NavIndicatorCtrls[name].Opt("Background" colorSidebar)
        }
    }

    CurrentView := viewName

    if (viewName = "Dashboard")
        RefreshDashboardView()
    else if (viewName = "PMLogs" && IsObject(PmLogsTextCtrl))
        PmLogsTextCtrl.Value := BuildPmLogsText(IsObject(PMLogsSearchCtrl) ? PMLogsSearchCtrl.Value : "")
    else if (viewName = "Punishments") {
        UpdatePunishmentTypeButtons(selectedPunishmentDays, punishmentSearch)
        ShowPunishmentType(selectedPunishmentType)
    } else if (viewName = "NormHistory")
        FillNormHistoryList()
    else if (viewName = "DaysOff")
        FillDaysOffList()
    else if (viewName = "Binds")
        RefreshBindsList()
    else if (viewName = "Settings")
        RefreshSettingsView()
    else if (viewName = "Updates")
        RefreshUpdatesView()
    else if (viewName = "Help")
        RefreshErrorsLogView()
    else if (viewName = "Cloud")
        RefreshCloudView()
    else if (viewName = "Diagnostics")
        RefreshDiagnosticsView()
    else if (viewName = "Scripts")
        RefreshScriptsView()
    else if (viewName = "Tester")
        RefreshTesterView()
}

; =========================
; 🛠️ SCRIPTS
; Реестр пакетов: чтобы добавить новый скрипт, достаточно добавить ещё
; одну карту в GetScriptPackages() — интерфейс и установщик останутся общими.
; =========================
GetScriptPackages() {
    return [
        Map(
            "id", "atools",
            "displayTitle", "aTools",
            "author", "Anthony Fernandez",
            "title", "🛠️ aTools",
            "description", "Установка необходимых файлов для работы aTools и _otools.",
            "authors", "aTools — Anthony Fernandez`n_otools — Takumi Onishi",
            "topic", "https://forum.radmir.games/threads/instrumenty-dlya-administratsii.2840899/",
            "files", [
                Map("name", "aTools.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/aTools.asi", "relativePath", "aTools.asi")
            ],
            "activationCommands", ""
        ),
        Map(
            "id", "onishi",
            "displayTitle", "Onishi",
            "author", "Takumi Onishi",
            "title", "Onishi",
            "description", "Onishi script with loader (скрипты уже в loader-js.json).",
            "authors", "Takumi Onishi",
            "topic", "https://forum.radmir.games/threads/instrumenty-dlya-administratsii.2840899/",
            "files", [
                Map("name", "loader-js.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/loader-js.asi", "relativePath", "loader-js.asi"),
                Map("name", "loader-js.json", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/JS%20code/loader-js.json", "relativePath", "loader-js.json"),
                Map("name", "_otools.js", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/_otools.js", "relativePath", "uiresources\scripts\_otools.js")
            ],
            "activationCommands", ""
        ),
        Map(
            "id", "fpsunlocker",
            "displayTitle", "FPSUnlocker",
            "author", "Misha Ches",
            "title", "FPSUnlocker",
            "description", "Разблокировка FPS для более плавной игры.",
            "authors", "Misha Ches",
            "topic", "https://github.com/MishaChes/ChesNova/blob/main/files/FPSUnlock.asi",
            "files", [
                Map("name", "FPSUnlock.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/FPSUnlock.asi", "relativePath", "FPSUnlock.asi")
            ],
            "activationCommands", ""
        ),
        Map(
            "id", "camhunt",
            "displayTitle", "CamHunt",
            "author", "Misha Ches",
            "title", "CamHunt",
            "description", "Камхак CamHunt. Установщик добавляет только недостающие файлы.",
            "authors", "Misha Ches",
            "topic", "https://github.com/MishaChes/ChesNova/tree/main/files/CamHunt",
            "skipExisting", true,
            "files", [
                Map("name", "CLEO.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/CLEO.asi", "relativePath", "CLEO.asi"),
                Map("name", "CamHunt", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/CamHunt", "relativePath", "CamHunt"),
                Map("name", "CamHunt.sp", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/CamHunt.sp", "relativePath", "CamHunt.sp"),
                Map("name", "Hooks.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/Hooks.asi", "relativePath", "Hooks.asi"),
                Map("name", "SA_GUI.fp", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/SA_GUI.fp", "relativePath", "SA_GUI.fp"),
                Map("name", "msvcr100d.dll", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/msvcr100d.dll", "relativePath", "msvcr100d.dll"),
                Map("name", "CamHunt.cfg", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/CLEO/CamHunt.cfg", "relativePath", "CLEO\CamHunt.cfg"),
                Map("name", "newOpcodes.cleo", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/CLEO/newOpcodes.cleo", "relativePath", "CLEO\newOpcodes.cleo"),
                Map("name", "ch_font.dat", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/data/Fonts/ch_font.dat", "relativePath", "data\Fonts\ch_font.dat"),
                Map("name", "ch_font.txd", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/data/Fonts/ch_font.txd", "relativePath", "data\Fonts\ch_font.txd"),
                Map("name", "CamHunt.txd", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/CamHunt/models/CamHunt.txd", "relativePath", "models\CamHunt.txd")
            ],
            "activationCommands", ""
        ),
        Map(
            "id", "weather_time",
            "displayTitle", "Погода/Время",
            "author", "Misha Ches",
            "title", "Погода/Время",
            "description", "Скрипт погоды и времени с конфигурационным файлом.",
            "authors", "Misha Ches",
            "topic", "https://github.com/MishaChes/ChesNova/blob/main/files/weather_time.asi",
            "files", [
                Map("name", "weather_time.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/weather_time.asi", "relativePath", "weather_time.asi"),
                Map("name", "weather_time.ini", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/weather_time.ini", "relativePath", "weather_time.ini")
            ],
            "activationCommands", ""
        ),
        Map(
            "id", "clientside",
            "displayTitle", "clientside.dll",
            "author", "Юсиф",
            "title", "clientside.dll",
            "description", "Новый скрипт для crashlog'ов.",
            "authors", "Юсиф",
            "topic", "https://github.com/MishaChes/ChesNova/blob/main/files/clientside.dll",
            "files", [
                Map("name", "clientside.dll", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/clientside.dll", "relativePath", "clientside.dll")
            ],
            "activationCommands", ""
        )
    ]
}

GetScriptPackageById(packageId) {
    for _, package in GetScriptPackages() {
        if (package["id"] = packageId)
            return package
    }
    return ""
}

; =========================
; 🆕 VERSION CHECK
; Отдельный модуль: в будущем сюда можно добавить скачивание и автоустановку.
; =========================
CheckForUpdatesManual(*) {
    CheckForUpdates(true)
}

CheckForUpdates(manual := false) {
    global CURRENT_VERSION

    try {
        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        if (versionInfo["latest"] = "")
            throw Error("В version.json отсутствует поле latest.")

        if (CompareVersions(versionInfo["latest"], CURRENT_VERSION) > 0)
            ShowUpdateDialog(versionInfo)
        else if manual
            ShowAppDialog("Обновления", "У вас уже установлена последняя версия: v" CURRENT_VERSION ".")
    } catch as err {
        LogError("CheckForUpdates", "Не удалось проверить наличие обновлений", err.Message)
        if manual
            ShowAppDialog("Обновления", "Не удалось проверить обновления. Проверьте подключение к интернету и повторите попытку.")
    }
}

DownloadVersionManifest() {
    global versionInfoUrl

    ; Уникальный параметр и no-cache не дают GitHub CDN вернуть старую копию JSON.
    requestUrl := versionInfoUrl "?nocache=" A_Now "_" A_TickCount
    result := HttpGetText(requestUrl)
    if (result["status"] != 200)
        throw Error("GitHub вернул HTTP " result["status"] ".")
    return result["text"]
}

ParseVersionManifest(jsonText) {
    changelog := []
    if RegExMatch(jsonText, Chr(34) "changelog" Chr(34) "\s*:\s*\[([^\]]*)\]", &changelogBlock) {
        position := 1
        while RegExMatch(changelogBlock[1], Chr(34) "((?:\\.|[^" Chr(34) "])*)" Chr(34), &entry, position) {
            changelog.Push(DecodeJsonText(entry[1]))
            position := entry.Pos + entry.Len
        }
    }

    requiredValue := StrLower(JsonVersionField(jsonText, "required", "false"))
    return Map(
        "latest", JsonVersionField(jsonText, "latest", ""),
        "download", JsonVersionField(jsonText, "download", ""),
        "changelog", changelog,
        "required", (requiredValue = "true" || requiredValue = "1") ? true : false
    )
}

JsonVersionField(jsonText, field, defaultValue := "") {
    quotedPattern := Chr(34) field Chr(34) "\s*:\s*" Chr(34) "((?:\\.|[^" Chr(34) "])*)" Chr(34)
    if RegExMatch(jsonText, quotedPattern, &quotedMatch)
        return DecodeJsonText(quotedMatch[1])

    rawPattern := Chr(34) field Chr(34) "\s*:\s*([^,}\r\n]+)"
    if RegExMatch(jsonText, rawPattern, &rawMatch)
        return Trim(rawMatch[1], " ")

    return defaultValue
}

DecodeJsonText(value) {
    value := StrReplace(value, "\n", Chr(10))
    value := StrReplace(value, "\r", Chr(13))
    value := StrReplace(value, "\" Chr(34), Chr(34))
    return StrReplace(value, "\\", "\")
}

CompareVersions(firstVersion, secondVersion) {
    firstParts := StrSplit(RegExReplace(Trim(firstVersion), "i)^v"), ".")
    secondParts := StrSplit(RegExReplace(Trim(secondVersion), "i)^v"), ".")
    totalParts := Max(firstParts.Length, secondParts.Length)

    Loop totalParts {
        firstNumber := (A_Index <= firstParts.Length) ? (firstParts[A_Index] + 0) : 0
        secondNumber := (A_Index <= secondParts.Length) ? (secondParts[A_Index] + 0) : 0
        if (firstNumber > secondNumber)
            return 1
        if (firstNumber < secondNumber)
            return -1
    }
    return 0
}

ShowUpdateDialog(versionInfo) {
    global CURRENT_VERSION, colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorRed

    lineBreak := Chr(10)
    changelogText := ""
    for _, entry in versionInfo["changelog"]
        changelogText .= "• " entry lineBreak
    if (changelogText = "")
        changelogText := "• Список изменений не указан." lineBreak

    isRequired := versionInfo["required"]
    dlgHeight := isRequired ? 330 : 300
    dlg := Gui("+Border", "Обновление ChesNova")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")
    dlg.Add("Text", "x0 y0 w520 h" dlgHeight " Background" colorBg)
    dlg.Add("Text", "x18 y18 w484 h" (dlgHeight - 90) " Background" colorCard)
    dlg.SetFont("s13 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y34 w400 h28 Background" colorCard, "🆕 Доступна новая версия ChesNova")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y74 w400 h42 Background" colorCard, "Текущая версия: v" CURRENT_VERSION lineBreak "Новая версия: v" versionInfo["latest"])
    dlg.SetFont("s10 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y128 w180 h20 Background" colorCard, "Что нового:")
    dlg.SetFont("s9 Norm c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y152 w430 h" (isRequired ? 100 : 76) " Background" colorCard, RTrim(changelogText, lineBreak))
    startupLaterButton := dlg.Add("Text", "x206 y" (dlgHeight - 52) " w128 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Позже")
    BindTextButton(startupLaterButton, colorCardAlt, (*) => dlg.Destroy())
    startupUpdateButton := dlg.Add("Text", "x346 y" (dlgHeight - 52) " w136 h30 +0x200 Center Background" colorAccent " c" colorText, "Обновить")
    BindTextButton(startupUpdateButton, colorAccent, StartManualUpdateFromDialog.Bind(dlg))

    if isRequired {
        dlg.SetFont("s9 Bold c" colorRed, "Segoe UI")
        dlg.Add("Text", "x38 y" (dlgHeight - 112) " w280 h20 Background" colorCard, "Это обязательное обновление")
        downloadButton := dlg.Add("Text", "x314 y" (dlgHeight - 52) " w168 h30 +0x200 Center Background" colorAccent " c" colorText, "📥 Скачать")
    } else {
        laterButton := dlg.Add("Text", "x206 y" (dlgHeight - 52) " w128 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Позже")
        BindTextButton(laterButton, colorCardAlt, (*) => dlg.Destroy())
        downloadButton := dlg.Add("Text", "x346 y" (dlgHeight - 52) " w136 h30 +0x200 Center Background" colorAccent " c" colorText, "📥 Скачать")
    }

    BindTextButton(downloadButton, colorAccent, OpenUpdateDownload.Bind(versionInfo["download"], dlg))
    downloadButton.Visible := false
    if IsSet(laterButton)
        laterButton.Visible := false
    dlg.Show("w520 h" dlgHeight)
    try WinActivate(dlg.Hwnd)
}

StartManualUpdateFromDialog(dlg, *) {
    try dlg.Destroy()
    ManualUpdateChesNova()
}

OpenUpdateDownload(downloadUrl, dlg := "", *) {
    if (downloadUrl = "") {
        ShowAppDialog("Обновления", "В version.json не указана ссылка для скачивания.")
        return
    }

    try {
        Run(downloadUrl)
        if IsObject(dlg)
            dlg.Destroy()
    } catch as err {
        LogError("OpenUpdateDownload", "Не удалось открыть ссылку на обновление", err.Message)
        ShowAppDialog("Обновления", "Не удалось открыть ссылку для скачивания." Chr(10) Chr(10) err.Message)
    }
}

DownloadLatestUpdate(*) {
    try {
        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        OpenUpdateDownload(versionInfo["download"])
    } catch as err {
        LogError("DownloadLatestUpdate", "Не удалось получить ссылку на обновление", err.Message)
        ShowAppDialog("Обновления", "Не удалось получить ссылку на обновление." Chr(10) Chr(10) err.Message)
    }
}

ManualUpdateChesNova(*) {
    global basePath, backupPath, CURRENT_VERSION

    mainScript := basePath "\ChesNova.ahk"
    newScript := basePath "\ChesNova_new.ahk"
    updateUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/ChesNova.ahk"

    try {
        if !FileExist(mainScript)
            throw Error("Текущий файл ChesNova.ahk не найден.")

        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        if (versionInfo["latest"] = "")
            throw Error("В version.json отсутствует поле latest.")
        if (CompareVersions(versionInfo["latest"], CURRENT_VERSION) <= 0) {
            ShowAppDialog("Обновления", "У вас уже установлена последняя версия: v" CURRENT_VERSION ".")
            return
        }

        if FileExist(newScript)
            FileDelete(newScript)

        ; The working file remains untouched until the complete new file is on disk.
        Download(updateUrl, newScript)
        if !FileExist(newScript) || FileGetSize(newScript) = 0
            throw Error("Загруженный файл пустой.")

        DirCreate(backupPath)
        backupFile := backupPath "\ChesNova_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".ahk"
        FileCopy(mainScript, backupFile, 0)

        try {
            FileDelete(mainScript)
            FileMove(newScript, mainScript, 0)
        } catch as installErr {
            ; If replacing fails, immediately restore the known-working backup.
            if !FileExist(mainScript) && FileExist(backupFile)
                FileCopy(backupFile, mainScript, 1)
            throw installErr
        }
    } catch as err {
        if FileExist(newScript)
            try FileDelete(newScript)
        LogError("ManualUpdateChesNova", "Не удалось установить обновление", err.Message)
        MsgBox("Не удалось загрузить обновление.`n`nПроверьте подключение к интернету.", "ChesNova", "Iconx")
        return
    }

    ShowUpdateInstalledDialog()
}

ShowUpdateInstalledDialog() {
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    dlg := Gui("+Border", "Обновление ChesNova")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.Add("Text", "x0 y0 w560 h208 Background" colorBg)
    dlg.Add("Text", "x18 y18 w524 h126 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y34 w460 h26 Background" colorCard, "✅ Обновление успешно загружено.")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y74 w460 h42 Background" colorCard, "Для применения изменений необходимо перезапустить ChesNova.")
    dlg.SetFont("s9 Bold c" colorText, "Segoe UI")
    laterButton := dlg.Add("Text", "x250 y160 w108 h30 +0x200 Center Background" colorCardAlt, "Позже")
    BindTextButton(laterButton, colorCardAlt, (*) => dlg.Destroy())
    restartButton := dlg.Add("Text", "x370 y160 w172 h30 +0x200 Center Background" colorAccent, "Перезапустить сейчас")
    BindTextButton(restartButton, colorAccent, RestartChesNova.Bind(dlg))
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show("w560 h208")
    try WinActivate(dlg.Hwnd)
}

RestartChesNova(dlg := "", *) {
    global basePath

    launcherPath := basePath "\ChesNovaLauncher.ahk"
    if !FileExist(launcherPath) {
        MsgBox("Не найден ChesNovaLauncher.ahk в папке Documents\ChesNova.", "ChesNova", "Iconx")
        return
    }

    try {
        Run('"' A_AhkPath '" "' launcherPath '" --restart')
        if IsObject(dlg)
            try dlg.Destroy()
        ExitApp()
    } catch as err {
        LogError("RestartChesNova", "Не удалось перезапустить ChesNova", err.Message)
        MsgBox("Не удалось перезапустить ChesNova.", "ChesNova", "Iconx")
    }
}

PromptRestartAfterUpdate(title, message) {
    result := ShowAppDialog(title, message "`n`nПерезапустить ChesNova сейчас?", "YesNo")
    if (result = "Yes")
        RestartChesNova()
}

LoadNotificationsCache() {
    global notificationsCacheFile, notifications

    if !FileExist(notificationsCacheFile)
        return

    try notifications := ParseNotificationsJson(FileRead(notificationsCacheFile, "UTF-8"))
    catch as err
        LogError("LoadNotificationsCache", "Не удалось прочитать кэш уведомлений", err.Message)
}

LoadNotificationStates() {
    global notificationsStateFile, notificationStates

    notificationStates := Map()
    if !FileExist(notificationsStateFile)
        return

    for _, line in ReadFileLines(notificationsStateFile, "LoadNotificationStates") {
        part := StrSplit(line, "|")
        if (part.Length < 3 || Trim(part[1]) = "")
            continue
        notificationStates[part[1]] := Map("received", part[2], "read", (part[3] + 0) ? 1 : 0, "dismissed", (part.Length >= 4 && part[4] + 0) ? 1 : 0)
    }
}

SaveNotificationStates() {
    global notificationsStateFile, notificationStates

    try {
        file := FileOpen(notificationsStateFile, "w", "UTF-8")
        for id, state in notificationStates
            dismissed := state.Has("dismissed") ? state["dismissed"] : 0
            file.WriteLine(id "|" state["received"] "|" state["read"] "|" dismissed)
        file.Close()
    } catch as err {
        LogError("SaveNotificationStates", "Не удалось сохранить статусы уведомлений", err.Message)
    }
}

ParseNotificationsJson(jsonText) {
    result := []
    position := 1

    while RegExMatch(jsonText, "\{[^{}]*\}", &objectMatch, position) {
        objectText := objectMatch[0]
        position := objectMatch.Pos + objectMatch.Len
        id := JsonNotificationField(objectText, "id", "")
        title := JsonNotificationField(objectText, "title", "")
        text := JsonNotificationField(objectText, "text", "")
        active := StrLower(JsonNotificationField(objectText, "active", "true"))
        if (id = "" || active = "false" || active = "0")
            continue

        result.Push(Map(
            "id", id,
            "title", title = "" ? "Уведомление" : title,
            "text", text,
            "type", JsonNotificationField(objectText, "type", "Информация"),
            "date", JsonNotificationField(objectText, "date", "")
        ))
    }

    return result
}

JsonNotificationField(objectText, field, defaultValue := "") {
    quotedPattern := Chr(34) field Chr(34) "\s*:\s*" Chr(34) "((?:\\.|[^" Chr(34) "])*)" Chr(34)
    if RegExMatch(objectText, quotedPattern, &quotedMatch) {
        value := quotedMatch[1]
        value := StrReplace(value, "\n", Chr(10))
        value := StrReplace(value, "\r", Chr(13))
        value := StrReplace(value, "\" Chr(34), Chr(34))
        value := StrReplace(value, "\\", "\")
        return value
    }

    rawPattern := Chr(34) field Chr(34) "\s*:\s*([^,}\r\n]+)"
    if RegExMatch(objectText, rawPattern, &rawMatch)
        return Trim(rawMatch[1], " ")

    return defaultValue
}

CheckNotifications(*) {
    global notificationsUrl, notificationsCacheFile, notifications, notificationStates

    try {
        result := HttpGetTextAsync(notificationsUrl "?nocache=" A_Now "_" A_TickCount)
        if (result["status"] != 200)
            throw Error("HTTP " result["status"])
        jsonText := result["text"]
        try {
            if FileExist(notificationsCacheFile ".tmp")
                FileDelete(notificationsCacheFile ".tmp")
            FileAppend(jsonText, notificationsCacheFile ".tmp", "UTF-8")
            FileMove(notificationsCacheFile ".tmp", notificationsCacheFile, 1)
        }
        notifications := ParseNotificationsJson(jsonText)

        statesChanged := false
        for _, notification in notifications {
            id := notification["id"]
            if !notificationStates.Has(id) {
                notificationStates[id] := Map("received", A_Now, "read", 0, "dismissed", 0)
                statesChanged := true
            }
        }
        if statesChanged
            SaveNotificationStates()
    } catch as err {
        try {
            if FileExist(notificationsCacheFile ".tmp")
                FileDelete(notificationsCacheFile ".tmp")
        }
        LogError("CheckNotifications", "Не удалось проверить notifications.json", err.Message)
    }

    UpdateNotificationIndicator()
}

HasUnreadNotifications() {
    global notifications, notificationStates

    for _, notification in notifications {
        id := notification["id"]
        if !notificationStates.Has(id) || (!notificationStates[id]["read"] && !notificationStates[id].Get("dismissed", 0))
            return true
    }
    return false
}

UpdateNotificationIndicator() {
    global NotificationIndicatorCtrl, colorGreen, colorRed

    if !IsSet(NotificationIndicatorCtrl) || !IsObject(NotificationIndicatorCtrl)
        return

    try NotificationIndicatorCtrl.SetFont("s7 Bold c" (HasUnreadNotifications() ? colorRed : colorGreen), "Segoe UI")
}

MarkNotificationsRead() {
    global notifications, notificationStates

    changed := false
    for _, notification in notifications {
        id := notification["id"]
        if !notificationStates.Has(id) {
            notificationStates[id] := Map("received", A_Now, "read", 1, "dismissed", 0)
            changed := true
        } else if !notificationStates[id]["read"] {
            notificationStates[id]["read"] := 1
            changed := true
        }
    }

    if changed
        SaveNotificationStates()
}

ClearNotifications(*) {
    global notifications, notificationStates, NotificationsGui

    for _, notification in notifications {
        id := notification["id"]
        if !notificationStates.Has(id)
            notificationStates[id] := Map("received", A_Now, "read", 1, "dismissed", 1)
        else {
            notificationStates[id]["read"] := 1
            notificationStates[id]["dismissed"] := 1
        }
    }

    SaveNotificationStates()
    UpdateNotificationIndicator()
    SafeDestroyGui(&NotificationsGui)
    OpenNotifications()
}

OpenNotifications(*) {
    global NotificationsGui, notifications, notificationStates
    global colorBg, colorCardAlt, colorAccent, colorText, colorMuted

    MarkNotificationsRead()
    UpdateNotificationIndicator()
    SafeDestroyGui(&NotificationsGui)

    visibleNotifications := GetVisibleNotifications()
    visibleNotificationCount := CountVisibleNotifications()

    NotificationsGui := Gui("+Border", "Уведомления")
    NotificationsGui.BackColor := colorBg
    NotificationsGui.MarginX := 0
    NotificationsGui.MarginY := 0
    NotificationsGui.SetFont("s10 c" colorText, "Segoe UI")
    NotificationsGui.Add("Text", "x0 y0 w560 h530 Background" colorBg)
    NotificationsGui.SetFont("s14 Bold c" colorText, "Segoe UI")
    NotificationsGui.Add("Text", "x24 y20 w400 h28 Background" colorBg, "🔔 Уведомления (" visibleNotificationCount ")")
    NotificationsGui.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    NotificationsGui.Add("Text", "x24 y54 w500 h20 Background" colorBg, "Последние 10 уведомлений. Новые отображаются сверху.")

    if (visibleNotifications.Length = 0) {
        NotificationsGui.SetFont("s10 Norm c" colorMuted, "Segoe UI")
        NotificationsGui.Add("Text", "x24 y112 w512 h350 +0x200 Center Background" colorBg, "Уведомлений пока нет.")
    } else {
        NotificationsGui.SetFont("s10 Norm c" colorText, "Segoe UI")
        feedText := BuildNotificationsFeed(visibleNotifications)
        NotificationsGui.Add("Edit", "x24 y88 w512 h374 +ReadOnly +VScroll -HScroll Background" colorBg " c" colorText, feedText)
    }

    clearButton := NotificationsGui.Add("Text", "x270 y478 w126 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Очистить")
    BindTextButton(clearButton, colorCardAlt, ClearNotifications)
    closeButton := NotificationsGui.Add("Text", "x408 y478 w128 h30 +0x200 Center Background" colorAccent " c" colorText, "Закрыть")
    BindTextButton(closeButton, colorAccent, (*) => SafeDestroyGui(&NotificationsGui))
    NotificationsGui.OnEvent("Close", (*) => SafeDestroyGui(&NotificationsGui))
    NotificationsGui.Show("w560 h530")
}

CountVisibleNotifications() {
    global notifications, notificationStates

    count := 0
    for _, notification in notifications {
        id := notification["id"]
        if !notificationStates.Has(id) || !notificationStates[id].Get("dismissed", 0)
            count += 1
    }
    return count
}

GetVisibleNotifications() {
    global notifications, notificationStates

    sorted := []
    for _, notification in notifications {
        id := notification["id"]
        if notificationStates.Has(id) && notificationStates[id].Get("dismissed", 0)
            continue

        fallbackDate := notificationStates.Has(id) ? notificationStates[id]["received"] : A_Now
        item := Map(
            "notification", notification,
            "date", notification["date"] != "" ? notification["date"] : fallbackDate,
            "sortKey", GetNotificationSortKey(notification["date"], fallbackDate)
        )

        inserted := false
        for index, existingItem in sorted {
            if (item["sortKey"] >= existingItem["sortKey"]) {
                sorted.InsertAt(index, item)
                inserted := true
                break
            }
        }
        if !inserted
            sorted.Push(item)
    }

    while (sorted.Length > 10)
        sorted.Pop()
    return sorted
}

BuildNotificationsFeed(items) {
    feedText := ""
    for index, item in items {
        notification := item["notification"]
        if (index > 1)
            feedText .= "`r`n`r`n──────────────────────────`r`n`r`n"
        feedText .= StrUpper(notification["title"]) "`r`n"
        feedText .= TruncateNotificationText(notification["text"]) "`r`n`r`n"
        feedText .= FormatNotificationDate(item["date"])
    }
    return feedText
}

TruncateNotificationText(text, maxLines := 3, charsPerLine := 54) {
    text := RegExReplace(Trim(StrReplace(text, "`r", " ")), "\s+", " ")
    maxLength := maxLines * charsPerLine
    wasTruncated := (StrLen(text) > maxLength)
    if wasTruncated
        text := RTrim(SubStr(text, 1, maxLength - 3)) "..."

    result := ""
    while (StrLen(text) > charsPerLine) {
        breakAt := 0
        Loop charsPerLine {
            position := charsPerLine - A_Index + 1
            if (SubStr(text, position, 1) = " ") {
                breakAt := position
                break
            }
        }
        if (breakAt = 0)
            breakAt := charsPerLine
        result .= Trim(SubStr(text, 1, breakAt)) "`r`n"
        text := LTrim(SubStr(text, breakAt + 1))
    }
    return result text
}

GetNotificationSortKey(dateValue, fallbackDate) {
    if RegExMatch(dateValue, "(\d{4})[-./](\d{2})[-./](\d{2}).*?(\d{2}):(\d{2})", &match)
        return match[1] match[2] match[3] match[4] match[5] "00"
    if RegExMatch(dateValue, "(\d{2})[.\-/](\d{2})[.\-/](\d{4}).*?(\d{2}):(\d{2})", &match)
        return match[3] match[2] match[1] match[4] match[5] "00"
    return RegExReplace(fallbackDate, "\D")
}

FormatNotificationDate(dateValue) {
    if RegExMatch(dateValue, "(\d{4})[-./](\d{2})[-./](\d{2}).*?(\d{2}):(\d{2})", &match)
        return match[3] "." match[2] "." match[1] " • " match[4] ":" match[5]
    if RegExMatch(dateValue, "(\d{2})[.\-/](\d{2})[.\-/](\d{4}).*?(\d{2}):(\d{2})", &match)
        return match[1] "." match[2] "." match[3] " • " match[4] ":" match[5]
    return FormatTime(dateValue, "dd.MM.yyyy • HH:mm")
}

ScriptsView() {
    global ScriptsGamePathCtrl, ScriptPackageStatusCtrls, scriptsGamePath
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorRed

    view := "Scripts"
    ScriptPackageStatusCtrls := Map()
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Скрипты")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y84 w600 h20 Background" colorBg " c" colorMuted, "Укажите корень игры. Автопоиск пути не используется.")

    ; Путь + действия в одну линию (x250..x850)
    ScriptsGamePathCtrl := AddViewControl(view, "Edit", "x250 y112 w340 h28 c" colorText " Background" uiInputBg, scriptsGamePath)
    pathButton := AddViewControl(view, "Text", "x598 y112 w118 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Папка")
    BindTextButton(pathButton, colorCardAlt, SelectScriptsGamePath)
    checkButton := AddViewControl(view, "Text", "x724 y112 w126 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Проверить")
    BindTextButton(checkButton, colorCardAlt, CheckScriptPackages)

    cardH := 64
    cardGap := 8
    startY := 150
    for index, package in GetScriptPackages() {
        cardY := startY + ((index - 1) * (cardH + cardGap))
        ; Карточка
        AddViewControl(view, "Text", "x250 y" cardY " w600 h" cardH " Background" colorCard)
        AddViewControl(view, "Text", "x250 y" cardY " w4 h" cardH " Background" colorAccent)

        ; Верхний ряд: название | статус | установить
        AddViewControl(view, "Text", "x272 y" (cardY + 8) " w200 h20 Background" colorCard " c" colorText, package["displayTitle"])
        ScriptPackageStatusCtrls[package["id"]] := AddViewControl(view, "Text", "x480 y" (cardY + 10) " w180 h18 Background" colorCard " c" colorRed, "●")
        installButton := AddViewControl(view, "Text", "x678 y" (cardY + 6) " w152 h28 +0x200 Center Background" colorAccent " c" colorText, "Установить")
        BindTextButton(installButton, colorAccent, InstallScriptPackage.Bind(package["id"]))

        ; Нижний ряд: автор / заметка | ссылка
        note := package.Has("skipExisting") && package["skipExisting"] ? "Только недостающие файлы" : "Отдельный пакет"
        if (package["id"] = "onishi")
            note := "Loader + json, без //loader"
        AddViewControl(view, "Text", "x272 y" (cardY + 38) " w250 h18 Background" colorCard " c" colorMuted, "Автор: " package["author"])
        AddViewControl(view, "Text", "x520 y" (cardY + 38) " w150 h18 Background" colorCard " c" colorMuted, note)
        topicButton := AddViewControl(view, "Text", "x678 y" (cardY + 36) " w152 h24 +0x200 Center Background" colorCardAlt " c" colorText, "Ссылка")
        BindTextButton(topicButton, colorCardAlt, OpenScriptTopic.Bind(package["topic"]))
    }

    RefreshScriptsView()
}



ScriptsViewCompact() {
    global ScriptsGamePathCtrl, ScriptPackageStatusCtrls, scriptsGamePath
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorRed

    view := "Scripts"
    ScriptPackageStatusCtrls := Map()
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Скрипты")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y84 w600 h20 Background" colorBg " c" colorMuted, "Укажите корень игры. Автопоиск пути не используется.")

    ; Путь + действия в одну линию (x250..x850)
    ScriptsGamePathCtrl := AddViewControl(view, "Edit", "x250 y112 w340 h28 c" colorText " Background" uiInputBg, scriptsGamePath)
    pathButton := AddViewControl(view, "Text", "x598 y112 w118 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Папка")
    BindTextButton(pathButton, colorCardAlt, SelectScriptsGamePath)
    checkButton := AddViewControl(view, "Text", "x724 y112 w126 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Проверить")
    BindTextButton(checkButton, colorCardAlt, CheckScriptPackages)

    cardH := 64
    cardGap := 8
    startY := 150
    for index, package in GetScriptPackages() {
        cardY := startY + ((index - 1) * (cardH + cardGap))
        ; Карточка
        AddViewControl(view, "Text", "x250 y" cardY " w600 h" cardH " Background" colorCard)
        AddViewControl(view, "Text", "x250 y" cardY " w4 h" cardH " Background" colorAccent)

        ; Верхний ряд: название | статус | установить
        AddViewControl(view, "Text", "x272 y" (cardY + 8) " w200 h20 Background" colorCard " c" colorText, package["displayTitle"])
        ScriptPackageStatusCtrls[package["id"]] := AddViewControl(view, "Text", "x480 y" (cardY + 10) " w180 h18 Background" colorCard " c" colorRed, "●")
        installButton := AddViewControl(view, "Text", "x678 y" (cardY + 6) " w152 h28 +0x200 Center Background" colorAccent " c" colorText, "Установить")
        BindTextButton(installButton, colorAccent, InstallScriptPackage.Bind(package["id"]))

        ; Нижний ряд: автор / заметка | ссылка
        note := package.Has("skipExisting") && package["skipExisting"] ? "Только недостающие файлы" : "Отдельный пакет"
        if (package["id"] = "onishi")
            note := "Loader + json, без //loader"
        AddViewControl(view, "Text", "x272 y" (cardY + 38) " w250 h18 Background" colorCard " c" colorMuted, "Автор: " package["author"])
        AddViewControl(view, "Text", "x520 y" (cardY + 38) " w150 h18 Background" colorCard " c" colorMuted, note)
        topicButton := AddViewControl(view, "Text", "x678 y" (cardY + 36) " w152 h24 +0x200 Center Background" colorCardAlt " c" colorText, "Ссылка")
        BindTextButton(topicButton, colorCardAlt, OpenScriptTopic.Bind(package["topic"]))
    }

    RefreshScriptsView()
}



SelectScriptsGamePath(*) {
    global ScriptsGamePathCtrl, scriptsGamePath, settingsFile

    selectedPath := FileSelect("D", scriptsGamePath, "Выберите корень игры")
    if (selectedPath = "")
        return

    scriptsGamePath := RTrim(selectedPath, "\/")
    if IsObject(ScriptsGamePathCtrl)
        ScriptsGamePathCtrl.Value := scriptsGamePath
    TryIniWrite(scriptsGamePath, settingsFile, "Scripts", "gamePath", "SelectScriptsGamePath")
}

GetScriptsGamePath() {
    global ScriptsGamePathCtrl, scriptsGamePath, settingsFile

    path := IsObject(ScriptsGamePathCtrl) ? Trim(ScriptsGamePathCtrl.Value) : Trim(scriptsGamePath)
    path := RTrim(path, "\/")
    if (path = "" || !IsValidGameRoot(path)) {
        found := FindRadmirGameRoot()
        if (found != "") {
            path := found
            SaveDetectedGamePath(path)
        }
    } else {
        scriptsGamePath := path
        TryIniWrite(path, settingsFile, "Scripts", "gamePath", "GetScriptsGamePath")
    }
    return path
}

GetScriptPackageInstallStatus(package) {
    gamePath := GetScriptsGamePath()
    if (gamePath = "")
        return Map("installed", false, "text", "● Не установлен — укажите путь к игре.", "color", "FF5B6B")

    missingFiles := []
    for _, file in package["files"] {
        if !FileExist(gamePath "\" file["relativePath"])
            missingFiles.Push(file["name"])
    }

    if (missingFiles.Length = 0)
        return Map("installed", true, "text", "● Установлен", "color", "41D07A")

    return Map("installed", false, "text", "● Не установлен: " JoinArrayRange(missingFiles, 1, missingFiles.Length, ", "), "color", "FF5B6B")
}

RefreshScriptsView(*) {
    global ScriptPackageStatusCtrls

    for _, package in GetScriptPackages() {
        if !ScriptPackageStatusCtrls.Has(package["id"])
            continue

        status := GetScriptPackageInstallStatus(package)
        ctrl := ScriptPackageStatusCtrls[package["id"]]
        ctrl.Text := status["installed"] ? "● Установлен" : "● Не установлен"
        ctrl.SetFont("s9 Bold c" status["color"], "Segoe UI")
    }
}

CheckScriptPackages(*) {
    missingPackages := []
    installedPackages := []
    lineBreak := Chr(10)

    for _, package in GetScriptPackages() {
        status := GetScriptPackageInstallStatus(package)
        if status["installed"]
            installedPackages.Push(package["title"])
        else
            missingPackages.Push(package["title"] lineBreak status["text"])
    }

    RefreshScriptsView()
    ShowScriptCheckResultDialog(installedPackages, missingPackages)
}


ShowScriptCheckResultDialog(installedPackages, missingPackages) {
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorRed

    lineBreak := Chr(10)
    hasMissing := missingPackages.Length > 0
    body := hasMissing
        ? "Требуется установка:" lineBreak lineBreak JoinArrayRange(missingPackages, 1, missingPackages.Length, lineBreak lineBreak)
        : "Установлено:" lineBreak lineBreak JoinArrayRange(installedPackages, 1, installedPackages.Length, lineBreak)

    dlg := Gui("+Border", "Проверка скриптов")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")

    dlg.Add("Text", "x0 y0 w560 h360 Background" colorBg)
    dlg.Add("Text", "x18 y18 w524 h278 Background" colorCard)
    dlg.SetFont("s12 Bold c" (hasMissing ? colorRed : colorGreen), "Segoe UI")
    dlg.Add("Text", "x38 y34 w460 h26 Background" colorCard, hasMissing ? "⚠️ Требуется установка" : "✅ Все скрипты установлены")
    dlg.SetFont("s9 Norm c" colorText, "Segoe UI")
    resultText := dlg.Add("Edit", "x38 y72 w484 h196 ReadOnly -Wrap +VScroll Background" uiInputBg " cFFFFFF", body)
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y272 w484 h18 Background" colorCard, "Если список длинный, используйте прокрутку внутри поля.")
    closeButton := dlg.Add("Text", "x414 y314 w108 h28 +0x200 Center Background" colorAccent " c" colorText, "OK")
    BindTextButton(closeButton, colorAccent, (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show("w560 h360")
}

OpenScriptTopic(url, *) {
    try Run(url)
    catch as err
        ShowAppDialog("Скрипты", "Не удалось открыть официальную тему.`n`n" err.Message)
}

IsGameProcessRunning() {
    ; Типичные процессы SA-MP / Radmir / GTA SA
    processNames := [
        "gta_sa.exe",
        "gta-sa.exe",
        "samp.exe",
        "samp_debug.exe",
        "proxy_sa.exe",
        "ragemp_v.exe",
        "multiplayer_sa.exe"
    ]
    for _, name in processNames {
        if ProcessExist(name)
            return true
    }
    try {
        if WinExist("ahk_exe gta_sa.exe") || WinExist("ahk_exe gta-sa.exe")
            return true
    }
    return false
}

InstallScriptPackage(packageId, *) {
    global dataPath

    package := GetScriptPackageById(packageId)
    if !IsObject(package) {
        ShowAppDialog("Скрипты", "Пакет скрипта не найден.")
        return
    }

    gamePath := GetScriptsGamePath()
    if (gamePath = "") {
        ShowAppDialog("Скрипты", "⚠️ Укажите путь к корню игры.")
        return
    }
    if !DirExist(gamePath) {
        ShowAppDialog("Скрипты", "Указанная папка игры не найдена:`n" gamePath)
        return
    }

    if IsGameProcessRunning() {
        result := ShowAppDialog(
            "Скрипты",
            "Игра сейчас запущена.`n`nЗакройте GTA / Radmir полностью, затем нажмите OK, чтобы продолжить установку.`nИначе файлы могут быть заняты и установка не завершится.",
            "OKCancel"
        )
        if (result != "OK")
            return
        if IsGameProcessRunning() {
            ShowAppDialog("Скрипты", "Игра всё ещё запущена.`nЗакройте её и повторите установку.")
            return
        }
    }

    uiResourcesPath := gamePath "\uiresources"
    scriptsPath := uiResourcesPath "\scripts"
    try {
        if !DirExist(uiResourcesPath)
            DirCreate(uiResourcesPath)
        if !DirExist(scriptsPath)
            DirCreate(scriptsPath)
    } catch as err {
        LogError("InstallScriptPackage", "Не удалось создать папки для пакета " packageId, err.Message)
        ShowAppDialog("Скрипты", "Не удалось создать папки uiresources и scripts.`nПроверьте доступ к папке игры.`n`n" err.Message)
        return
    }

    downloadedFiles := []
    downloadsPath := dataPath "\downloads"
    DirCreate(downloadsPath)
    try {
        for index, file in package["files"] {
            tempFile := downloadsPath "\ChesNova_" package["id"] "_" A_TickCount "_" index ".tmp"
            Download(file["url"], tempFile)
            downloadedFiles.Push(Map("temp", tempFile, "file", file))
        }
    } catch as err {
        for _, downloaded in downloadedFiles {
            try FileDelete(downloaded["temp"])
        }
        LogError("InstallScriptPackage", "Не удалось скачать файл " file["name"], err.Message)
        ShowAppDialog("Скрипты", "Не удалось скачать файл " file["name"] ".`nПроверьте подключение к интернету и повторите попытку.`n`n" err.Message)
        return
    }

    try {
        for _, downloaded in downloadedFiles {
            destination := gamePath "\" downloaded["file"]["relativePath"]
            destinationDir := RegExReplace(destination, "\\[^\\]+$")
            if !DirExist(destinationDir)
                DirCreate(destinationDir)
            if (package.Has("skipExisting") && package["skipExisting"] && FileExist(destination)) {
                try FileDelete(downloaded["temp"])
                continue
            }
            FileMove(downloaded["temp"], destination, 1)
        }
    } catch as err {
        for _, downloaded in downloadedFiles {
            if FileExist(downloaded["temp"])
                try FileDelete(downloaded["temp"])
        }
        LogError("InstallScriptPackage", "Не удалось установить пакет " packageId " в " gamePath, err.Message)
        ShowAppDialog("Скрипты", "Не удалось записать файлы в папку игры.`nПроверьте доступ к папке и закройте игру, если файлы заняты.`n`n" err.Message)
        return
    }

    RefreshScriptsView()
    if (package["activationCommands"] != "")
        ShowScriptInstallComplete(package)
    else
        ShowToast("✓ Пакет установлен")
}

ShowScriptInstallComplete(package) {
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    dlg := Gui("+Border", "Скрипты — установка")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")
    dlg.Add("Text", "x0 y0 w470 h262 Background" colorBg)
    dlg.Add("Text", "x18 y18 w434 h178 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y34 w360 h26 Background" colorCard, "✅ Установка завершена.")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y72 w380 h40 Background" colorCard, "Для активации скрипта зайдите в игру и выполните команды:")
    commandsCtrl := dlg.Add("Edit", "x38 y120 w380 h50 ReadOnly -Wrap Background" uiInputBg " cFFFFFF", package["activationCommands"])
    copyButton := dlg.Add("Text", "x38 y212 w190 h30 +0x200 Center Background" colorAccent " c" colorText, "📋 Скопировать команды")
    BindTextButton(copyButton, colorAccent, (*) => CopyScriptCommands(package["activationCommands"]))
    closeButton := dlg.Add("Text", "x310 y212 w108 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Закрыть")
    BindTextButton(closeButton, colorCardAlt, (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show("w470 h262")
    try WinActivate(dlg.Hwnd)
}

CopyScriptCommands(commands, *) {
    A_Clipboard := commands
    ShowToast("✓ Команды скопированы")
}

DashboardView() {
    global DashboardNickCtrl, DashboardSystemStatusCtrl, DashboardCloudStatusCtrl, DashboardNormCtrl, DashboardVersionCtrl
    global DashboardNormPmCtrl, DashboardNormRemainingCtrl, DashboardNormPercentCtrl, DashboardProgressBgCtrl, DashboardProgressFillCtrl, DashboardLogFileCtrl, DashboardDaysOffMonthCtrl
    global DashboardStatusChatlogCtrl, DashboardStatusGameCtrl, DashboardStatusHudCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorYellow

    view := "Dashboard"

    ; Заголовок
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Главная")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)

    ; Профиль
    AddViewControl(view, "Text", "x250 y94 w600 h88 Background" colorCard)
    AddViewControl(view, "Text", "x270 y108 w220 h20 Background" colorCard " c" colorMuted, "Администратор")
    DashboardNickCtrl := AddViewControl(view, "Text", "x270 y130 w400 h28 Background" colorCard " c" colorAccent " +0x200", "")
    AddViewControl(view, "Text", "x270 y160 w200 h18 Background" colorCard " c" colorGreen, "• Профиль активен")

    ; Норма
    AddViewControl(view, "Text", "x250 y198 w290 h108 Background" colorCard)
    AddViewControl(view, "Text", "x270 y214 w190 h20 Background" colorCard " c" colorMuted, "📨 Норма PM")
    DashboardNormPmCtrl := AddViewControl(view, "Text", "x270 y238 w240 h28 Background" colorCard " c" colorAccent " +0x200", "")
    DashboardNormRemainingCtrl := AddViewControl(view, "Text", "x270 y270 w240 h22 Background" colorCard " c" colorMuted, "")

    ; Отгулы
    AddViewControl(view, "Text", "x560 y198 w290 h108 Background" colorCard)
    AddViewControl(view, "Text", "x580 y214 w200 h20 Background" colorCard " c" colorMuted, "🏖 Отгулы за месяц")
    DashboardDaysOffMonthCtrl := AddViewControl(view, "Text", "x580 y238 w210 h28 Background" colorCard " c" colorGreen " +0x200", "")
    AddViewControl(view, "Text", "x580 y270 w220 h22 Background" colorCard " c" colorMuted, "Текущий календарный месяц")

    ; Статус системы — три пункта в столбик
    AddViewControl(view, "Text", "x250 y322 w290 h168 Background" colorCard)
    AddViewControl(view, "Text", "x270 y336 w240 h20 Background" colorCard " c" colorMuted, "🛡 Статус системы")
    DashboardStatusChatlogCtrl := AddViewControl(view, "Text", "x270 y366 w250 h24 Background" colorCard " c" colorMuted " +0x200", "●  chatlog")
    DashboardStatusGameCtrl := AddViewControl(view, "Text", "x270 y398 w250 h24 Background" colorCard " c" colorMuted " +0x200", "●  корень игры")
    DashboardStatusHudCtrl := AddViewControl(view, "Text", "x270 y430 w250 h24 Background" colorCard " c" colorMuted " +0x200", "●  счётчик в игре")
    ; legacy aliases (не показываем, но Refresh не падает)
    DashboardSystemStatusCtrl := DashboardStatusChatlogCtrl
    DashboardLogFileCtrl := DashboardStatusGameCtrl

    ; Cloud
    AddViewControl(view, "Text", "x560 y322 w290 h168 Background" colorCard)
    AddViewControl(view, "Text", "x580 y336 w220 h20 Background" colorCard " c" colorMuted, "☁ Cloud")
    DashboardCloudStatusCtrl := AddViewControl(view, "Text", "x580 y380 w250 h28 Background" colorCard " c" colorAccent " +0x200", "")
    AddViewControl(view, "Text", "x580 y420 w250 h40 Background" colorCard " c" colorMuted, "Проверка доступа по нику`nиз таблицы Cloud")

    ; Кнопка
    openSettingsBtn := AddViewControl(view, "Text", "x405 y508 w290 h34 +0x200 Center Background" colorAccent " c" colorText, "⚙  Открыть настройки")
    BindTextButton(openSettingsBtn, colorAccent, (*) => ShowView("Settings"))
}

RefreshDashboardView() {
    global SettingsGui
    global nick, pmCount, norm, logFile, scriptsGamePath, appVersion
    global colorAccent, colorGreen, colorRed, colorMuted
    global DashboardNickCtrl, DashboardCloudStatusCtrl
    global DashboardNormPmCtrl, DashboardNormRemainingCtrl, DashboardDaysOffMonthCtrl
    global DashboardStatusChatlogCtrl, DashboardStatusGameCtrl, DashboardStatusHudCtrl

    if !IsObject(SettingsGui)
        return

    try {
        if IsObject(DashboardNickCtrl)
            DashboardNickCtrl.Text := nick

        remainingPm := GetRemainingPm()
        progressPercent := GetNormProgressPercent()

        if IsObject(DashboardNormPmCtrl)
            DashboardNormPmCtrl.Text := pmCount " / " norm " PM"
        if IsObject(DashboardNormRemainingCtrl)
            DashboardNormRemainingCtrl.Text := "Осталось: " remainingPm " PM  •  " progressPercent "%"

        if IsObject(DashboardDaysOffMonthCtrl)
            DashboardDaysOffMonthCtrl.Text := CountDaysOffCurrentMonth() " дн."

        ; —— статус системы: chatlog / корень / счётчик ——
        chatlogOk := (logFile != "" && FileExist(logFile))
        gameOk := (scriptsGamePath != "" && IsValidGameRoot(scriptsGamePath))
        hudOk := gameOk && IsChesNovaHudInstalled(scriptsGamePath)

        SetDashboardStatusLine(DashboardStatusChatlogCtrl, "chatlog", chatlogOk)
        SetDashboardStatusLine(DashboardStatusGameCtrl, "корень игры", gameOk)
        SetDashboardStatusLine(DashboardStatusHudCtrl, "счётчик в игре", hudOk)

        if IsObject(DashboardCloudStatusCtrl) {
            DashboardCloudStatusCtrl.Text := GetCloudStatusText()
            DashboardCloudStatusCtrl.SetFont("s10 Bold c" GetCloudStatusColor(), "Segoe UI")
        }
    } catch as err {
        ResetDashboardControls()
    }
}

SetDashboardStatusLine(ctrl, label, isOk) {
    global colorGreen, colorRed
    if !IsObject(ctrl)
        return
    try {
        ctrl.Text := (isOk ? "●  " : "●  ") label
        ctrl.SetFont("s10 Bold c" (isOk ? colorGreen : colorRed), "Segoe UI")
    }
}

PMLogsView() {
    global PMLogsSearchCtrl, PmLogsTextCtrl
    global colorBg, colorCard, colorCardAlt, colorText, colorMuted

    view := "PMLogs"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "PM Логи")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y84 w300 h20 Background" colorBg " c" colorMuted, "Поиск по нику или тексту")
    PMLogsSearchCtrl := AddViewControl(view, "Edit", "x250 y112 w470 h28 c" colorText " Background" uiInputBg, "")
    PMLogsSearchCtrl.OnEvent("Change", PMLogsSearchChanged)
    clearButton := AddViewControl(view, "Text", "x732 y112 w118 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Очистить")
    BindTextButton(clearButton, colorCardAlt, ClearPMLogs)
    PmLogsTextCtrl := AddViewControl(view, "Edit", "vPmLogsText x250 y152 w600 h350 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, BuildPmLogsText())
}

PMLogsSearchChanged(*) {
    global PMLogsSearchCtrl, PmLogsTextCtrl

    if (IsObject(PMLogsSearchCtrl) && IsObject(PmLogsTextCtrl))
        PmLogsTextCtrl.Value := BuildPmLogsText(PMLogsSearchCtrl.Value)
}

PunishmentsView() {
    global selectedPunishmentDays, selectedPunishmentType, punishmentSearch
    global PunishmentTypeTitleCtrl, PunishmentSearchCtrl, PunishmentDetailsCtrl, PunishmentButtonCtrls
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Punishments"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Наказания")
    AddViewControl(view, "Text", "x250 y84 w110 h20 Background" colorBg " c" colorMuted, "Тип")
    AddViewControl(view, "Text", "x380 y84 w220 h20 Background" colorBg " c" colorMuted, "Период")
    AddViewControl(view, "Text", "x610 y84 w240 h20 Background" colorBg " c" colorMuted, "Поиск")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)

    global PunishmentPeriodButtonCtrls
    PunishmentButtonCtrls := Map()
    PunishmentPeriodButtonCtrls := Map()
    typeY := 112
    for typeName, handler in Map(
        "kick", ShowPunishmentKick,
        "jail", ShowPunishmentJail,
        "warn", ShowPunishmentWarn,
        "mute", ShowPunishmentMute,
        "vmute", ShowPunishmentVmute,
        "rmute", ShowPunishmentRmute,
        "gunban", ShowPunishmentGunban,
        "ban", ShowPunishmentBan,
        "sban", ShowPunishmentSban,
        "all", ShowPunishmentAll
    ) {
        label := (typeName = "all") ? "Все (0)" : (typeName " (0)")
        btn := AddViewControl(view, "Text", "x250 y" typeY " w110 h28 +0x200 Center Background" colorCardAlt " c" colorText, label)
        btn.OnEvent("Click", handler)
        PunishmentButtonCtrls[typeName] := btn
        typeY += 32
    }

    todayButton := AddViewControl(view, "Text", "x380 y112 w70 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Сегодня")
    todayButton.OnEvent("Click", SetPunishmentToday)
    threeDaysButton := AddViewControl(view, "Text", "x456 y112 w70 h28 +0x200 Center Background" colorCardAlt " c" colorText, "3 дня")
    threeDaysButton.OnEvent("Click", SetPunishment3Days)
    tenDaysButton := AddViewControl(view, "Text", "x532 y112 w70 h28 +0x200 Center Background" colorCardAlt " c" colorText, "10 дней")
    tenDaysButton.OnEvent("Click", SetPunishment10Days)
    allTimeButton := AddViewControl(view, "Text", "x380 y148 w146 h28 +0x200 Center Background" colorCardAlt " c" colorText, "За всё время")
    allTimeButton.OnEvent("Click", SetPunishmentAllTime)
    PunishmentPeriodButtonCtrls[1] := todayButton
    PunishmentPeriodButtonCtrls[3] := threeDaysButton
    PunishmentPeriodButtonCtrls[10] := tenDaysButton
    PunishmentPeriodButtonCtrls[0] := allTimeButton
    clearButton := AddViewControl(view, "Text", "x532 y148 w70 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Очистить")
    BindTextButton(clearButton, colorCardAlt, ClearPunishments)
    PunishmentSearchCtrl := AddViewControl(view, "Edit", "vPunishmentSearch x610 y112 w240 h28 c" colorText " Background" uiInputBg, punishmentSearch)
    PunishmentSearchCtrl.OnEvent("Change", RefreshPunishmentView)

    PunishmentTypeTitleCtrl := AddViewControl(view, "Text", "vPunishmentTypeTitle x380 y188 w470 h22 Background" colorBg " c" colorText, "Выберите тип наказания")
    PunishmentDetailsCtrl := AddViewControl(view, "Edit", "vPunishmentDetails x380 y218 w470 h288 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, "Выберите тип наказания слева")

    UpdatePunishmentTypeButtons(selectedPunishmentDays, punishmentSearch)
    ShowPunishmentType(selectedPunishmentType)
}

NormHistoryView() {
    global NormHistoryListCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "NormHistory"
    AddViewControl(view, "Text", "x250 y34 w360 h28 Background" colorBg " c" colorText, "История нормы")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y80 w300 h18 Background" colorBg " c" colorMuted, "Новые записи сверху")
    editButton := AddViewControl(view, "Text", "x580 y78 w130 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Редактировать")
    BindTextButton(editButton, colorCardAlt, OpenNormHistoryEdit)
    clearButton := AddViewControl(view, "Text", "x720 y78 w130 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Очистить")
    BindTextButton(clearButton, colorCardAlt, ClearNormHistory)

    NormHistoryListCtrl := AddViewControl(view, "ListView", "x250 y116 w600 h400 Background" colorCard " c" colorText, ["Дата", "PM", "Норма", "Статус"])
    NormHistoryListCtrl.ModifyCol(1, 150)
    NormHistoryListCtrl.ModifyCol(2, 90)
    NormHistoryListCtrl.ModifyCol(3, 90)
    NormHistoryListCtrl.ModifyCol(4, 190)
}

RefreshNormDaysOffInfo(*) {
    global NormMonthComboCtrl, NormYearEditCtrl, NormDaysOffInfoCtrl

    if !IsObject(NormDaysOffInfoCtrl)
        return

    monthText := IsObject(NormMonthComboCtrl) ? NormMonthComboCtrl.Text : FormatTime(A_Now, "MM")
    yearText := IsObject(NormYearEditCtrl) ? Trim(NormYearEditCtrl.Value) : FormatTime(A_Now, "yyyy")

    monthNum := ""
    if RegExMatch(monthText, "^(\d{2})", &m)
        monthNum := m[1]
    else
        monthNum := FormatTime(A_Now, "MM")

    if !RegExMatch(yearText, "^\d{4}$")
        yearText := FormatTime(A_Now, "yyyy")

    count := CountDaysOffInMonth(yearText, monthNum)
    monthLabel := monthText
    if (InStr(monthText, "—"))
        monthLabel := Trim(SubStr(monthText, InStr(monthText, "—") + 1))
    else
        monthLabel := monthNum

    NormDaysOffInfoCtrl.Text := "Отгулов за " monthLabel " " yearText ":  " count
}

FillNormHistoryList() {
    global historyFile, NormHistoryListCtrl

    if !IsObject(NormHistoryListCtrl)
        return

    NormHistoryListCtrl.Delete()
    lines := []

    if FileExist(historyFile) {
        for _, line in ReadFileLines(historyFile)
        {
            if (Trim(line) != "")
                lines.Push(line)
        }
    }

    lines := SortRecordsNewestFirst(lines, "history")
    for _, line in lines {
        part := StrSplit(line, ",")
        if (part.Length >= 3) {
            dayPM := part[2] + 0
            dayNorm := part[3] + 0
            status := IsDayOff(part[1]) ? "🟨 отгул" : ((dayPM >= dayNorm) ? "🟦 выполнена" : "🟥 не выполнена")
            NormHistoryListCtrl.Add(, part[1], dayPM, dayNorm, status)
        }
    }
}

OpenNormHistoryEdit(*) {
    global NormHistoryListCtrl, NormHistoryEditGui, NormHistoryEditOriginalDate
    global NormHistoryEditDateCtrl, NormHistoryEditPmCtrl, NormHistoryEditNormCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    if !IsObject(NormHistoryListCtrl)
        return

    row := NormHistoryListCtrl.GetNext()
    if (!row) {
        ShowAppDialog("История нормы", "Выберите запись истории нормы для редактирования.")
        return
    }

    recordDate := NormHistoryListCtrl.GetText(row, 1)
    recordPm := NormHistoryListCtrl.GetText(row, 2)
    recordNorm := NormHistoryListCtrl.GetText(row, 3)
    NormHistoryEditOriginalDate := recordDate

    SafeDestroyGui(&NormHistoryEditGui)
    NormHistoryEditGui := Gui("+Border", "Редактирование истории нормы")
    NormHistoryEditGui.OnEvent("Close", CancelNormHistoryEdit)
    NormHistoryEditGui.BackColor := colorBg
    NormHistoryEditGui.MarginX := 0
    NormHistoryEditGui.MarginY := 0
    NormHistoryEditGui.SetFont("s10 c" colorText, "Segoe UI")

    NormHistoryEditGui.Add("Text", "x0 y0 w360 h244 Background" colorBg)
    NormHistoryEditGui.Add("Text", "x18 y18 w324 h154 Background" colorCard)
    NormHistoryEditGui.SetFont("s12 Bold c" colorText, "Segoe UI")
    NormHistoryEditGui.Add("Text", "x34 y30 w270 h24 Background" colorCard, "Редактирование нормы")
    NormHistoryEditGui.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    NormHistoryEditGui.Add("Text", "x34 y66 w80 h20 Background" colorCard, "Дата")
    NormHistoryEditDateCtrl := NormHistoryEditGui.Add("Edit", "x130 y62 w178 h24 cFFFFFF Background" uiInputBg, recordDate)
    NormHistoryEditGui.Add("Text", "x34 y100 w80 h20 Background" colorCard, "PM")
    NormHistoryEditPmCtrl := NormHistoryEditGui.Add("Edit", "x130 y96 w178 h24 Number cFFFFFF Background" uiInputBg, recordPm)
    NormHistoryEditGui.Add("Text", "x34 y134 w80 h20 Background" colorCard, "Норма")
    NormHistoryEditNormCtrl := NormHistoryEditGui.Add("Edit", "x130 y130 w178 h24 Number cFFFFFF Background" uiInputBg, recordNorm)

    AddMiniWindowButton(NormHistoryEditGui, 110, 190, 104, 30, "Отмена", colorCardAlt, CancelNormHistoryEdit)
    AddMiniWindowButton(NormHistoryEditGui, 226, 190, 116, 30, "Сохранить", colorAccent, SaveNormHistoryEdit)
    NormHistoryEditGui.Show("w360 h244")
    try WinActivate(NormHistoryEditGui.Hwnd)
}

SaveNormHistoryEdit(*) {
    global historyFile, NormHistoryEditGui, NormHistoryEditOriginalDate
    global NormHistoryEditDateCtrl, NormHistoryEditPmCtrl, NormHistoryEditNormCtrl

    if !IsObject(NormHistoryEditGui)
        return

    newDate := NormalizeDayOffDate(NormHistoryEditDateCtrl.Value)
    if (newDate = "") {
        ShowAppDialog("История нормы", "Введите дату в формате yyyy-MM-dd.")
        return
    }

    newPm := Trim(NormHistoryEditPmCtrl.Value)
    newNorm := Trim(NormHistoryEditNormCtrl.Value)
    if (newPm = "" || newNorm = "") {
        ShowAppDialog("История нормы", "PM и норма должны быть заполнены.")
        return
    }

    newPm += 0
    newNorm += 0
    existingRecords := ReadNormHistoryRecords("SaveNormHistoryEdit")
    dateExists := false

    for _, record in existingRecords {
        if (record["date"] = newDate && record["date"] != NormHistoryEditOriginalDate) {
            dateExists := true
            break
        }
    }

    if (dateExists) {
        result := ShowAppDialog("Подтверждение замены", "Запись за " newDate " уже существует.`nЗаменить существующую запись?", "OKCancel")
        if (result != "OK")
            return
    }

    newRecords := []
    for _, record in existingRecords {
        if (record["date"] = NormHistoryEditOriginalDate)
            continue
        if (dateExists && record["date"] = newDate)
            continue
        newRecords.Push(record)
    }

    newRecords.Push(Map("date", newDate, "pm", newPm, "norm", newNorm))
    if !WriteNormHistoryRecords(newRecords)
        return
    SafeDestroyGui(&NormHistoryEditGui)
    FillNormHistoryList()
    ShowToast("✓ Запись нормы сохранена")
}

CancelNormHistoryEdit(*) {
    global NormHistoryEditGui
    SafeDestroyGui(&NormHistoryEditGui)
}

ReadNormHistoryRecords(source := "ReadNormHistoryRecords") {
    global historyFile

    records := []
    if !FileExist(historyFile)
        return records

    for _, line in ReadFileLines(historyFile, source) {
        part := StrSplit(line, ",")
        if (part.Length >= 3 && NormalizeDayOffDate(part[1]) != "")
            records.Push(Map("date", part[1], "pm", part[2] + 0, "norm", part[3] + 0))
    }

    return records
}

WriteNormHistoryRecords(records) {
    global historyFile

    lines := SortRecordsNewestFirst(BuildNormHistoryLines(DedupeNormHistoryRecords(records)), "history")
    try {
        file := FileOpen(historyFile, "w")
        for _, line in lines
            file.WriteLine(line)
        file.Close()
        return true
    } catch as err {
        LogError("WriteNormHistoryRecords", "Ошибка записи истории нормы", err.Message)
        MsgBox("Не удалось сохранить историю нормы.`n`n" err.Message, "Ошибка", "Iconx")
        return false
    }
}

DedupeNormHistoryRecords(records) {
    seen := Map()
    deduped := []

    for _, record in records {
        recordDate := record["date"]
        if (seen.Has(recordDate))
            continue
        seen[recordDate] := true
        deduped.Push(record)
    }

    return deduped
}

BuildNormHistoryLines(records) {
    lines := []
    for _, record in records
        lines.Push(record["date"] "," record["pm"] "," record["norm"])
    return lines
}

DaysOffView() {
    global DaysOffDateCtrl, DaysOffForumCtrl, DaysOffForumStatusCtrl, DaysOffListCtrl
    global NormMonthComboCtrl, NormYearEditCtrl, NormDaysOffInfoCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorRed

    view := "DaysOff"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Отгулы")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y84 w220 h20 Background" colorBg " c" colorMuted, "Дата отгула")
    DaysOffDateCtrl := AddViewControl(view, "Edit", "vDaysOffDate x250 y112 w160 h28 c" colorText " Background" uiInputBg, FormatTime(A_Now, "yyyy-MM-dd"))
    DaysOffForumCtrl := AddViewControl(view, "Checkbox", "x426 y118 w18 h18 Background" colorBg)
    DaysOffForumCtrl.OnEvent("Click", UpdateDayOffForumStatus)
    DaysOffForumStatusCtrl := AddViewControl(view, "Text", "x452 y116 w120 h22 Background" colorBg " c" colorRed, "Не залито")
    addButton := AddViewControl(view, "Text", "x580 y112 w110 h28 +0x200 Center Background" colorAccent " c" colorText, "Добавить")
    BindTextButton(addButton, colorAccent, AddDayOff)
    deleteButton := AddViewControl(view, "Text", "x700 y112 w150 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Удалить")
    BindTextButton(deleteButton, colorCardAlt, DeleteSelectedDayOff)
    AddViewControl(view, "Text", "x250 y148 w300 h18 Background" colorBg " c" colorMuted, "Формат: yyyy-MM-dd")
    AddViewControl(view, "Text", "x250 y176 w260 h20 Background" colorBg " c" colorMuted, "Все добавленные отгулы")
    uploadedButton := AddViewControl(view, "Text", "x540 y172 w140 h28 +0x200 Center Background" colorGreen " c" colorText, "Залито")
    BindTextButton(uploadedButton, colorGreen, SetSelectedDayOffForumStatus.Bind(1))
    notUploadedButton := AddViewControl(view, "Text", "x690 y172 w160 h28 +0x200 Center Background" colorRed " c" colorText, "Не залито")
    BindTextButton(notUploadedButton, colorRed, SetSelectedDayOffForumStatus.Bind(0))
    DaysOffListCtrl := AddViewControl(view, "ListView", "x250 y210 w600 h200 Background" colorCard " c" colorText, ["Дата", "Форум"])
    DaysOffListCtrl.ModifyCol(1, 180)
    DaysOffListCtrl.ModifyCol(2, 130)
    DaysOffListCtrl.OnEvent("DoubleClick", ToggleSelectedDayOffForumStatus)

    ; Инфо-табло: отгулы за выбранный месяц/год
    AddViewControl(view, "Text", "x250 y428 w600 h112 Background" colorCard)
    AddViewControl(view, "Text", "x270 y440 w360 h22 Background" colorCard " c" colorText, "Сколько отгулов за период")
    AddViewControl(view, "Text", "x270 y470 w60 h20 Background" colorCard " c" colorMuted, "Месяц")
    monthNames := ["01 — Январь", "02 — Февраль", "03 — Март", "04 — Апрель", "05 — Май", "06 — Июнь", "07 — Июль", "08 — Август", "09 — Сентябрь", "10 — Октябрь", "11 — Ноябрь", "12 — Декабрь"]
    NormMonthComboCtrl := AddViewControl(view, "ComboBox", "x330 y466 w180 h200", monthNames)
    currentMonthIdx := Integer(FormatTime(A_Now, "MM"))
    if (currentMonthIdx >= 1 && currentMonthIdx <= 12)
        NormMonthComboCtrl.Choose(currentMonthIdx)
    AddViewControl(view, "Text", "x530 y470 w40 h20 Background" colorCard " c" colorMuted, "Год")
    NormYearEditCtrl := AddViewControl(view, "Edit", "x575 y466 w70 h28 Number c" colorText " Background" uiInputBg, FormatTime(A_Now, "yyyy"))
    showButton := AddViewControl(view, "Text", "x660 y466 w170 h28 +0x200 Center Background" colorAccent " c" colorText, "Показать")
    BindTextButton(showButton, colorAccent, RefreshNormDaysOffInfo)
    NormDaysOffInfoCtrl := AddViewControl(view, "Text", "x270 y508 w560 h24 Background" colorCard " c" colorAccent " +0x200", "")
    UpdateDayOffForumStatus()
    RefreshNormDaysOffInfo()
}

BindsView() {
    global BindsSearchCtrl, BindsCategoryCtrl, BindsCategoryStatusCtrl, BindsListCtrl, BindsEnabledCtrl, bindsEnabled
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Binds"
    AddViewControl(view, "Text", "x250 y34 w360 h28 Background" colorBg " c" colorText, "Бинды")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)

    AddViewControl(view, "Text", "x250 y94 w600 h116 Background" colorCard)
    BindsEnabledCtrl := AddViewControl(view, "Checkbox", "x270 y112 w160 h24 Checked" bindsEnabled " c" colorText " Background" colorCard, "Бинды включены")
    BindsEnabledCtrl.OnEvent("Click", ToggleAllBindsEnabled)

    AddViewControl(view, "Text", "x270 y146 w80 h20 Background" colorCard " c" colorMuted, "Поиск")
    BindsSearchCtrl := AddViewControl(view, "Edit", "x270 y170 w230 h28 c" colorText " Background" uiInputBg, "")
    BindsSearchCtrl.OnEvent("Change", RefreshBindsList)
    AddViewControl(view, "Text", "x520 y146 w150 h20 Background" colorCard " c" colorMuted, "Фильтр категории")
    BindsCategoryCtrl := AddViewControl(view, "ComboBox", "x520 y170 w180 h120", GetBindCategories(true))
    BindsCategoryCtrl.Choose(1)
    BindsCategoryCtrl.OnEvent("Change", RefreshBindsList)
    BindsCategoryStatusCtrl := AddViewControl(view, "Text", "x710 y173 w120 h20 Background" colorCard " c" colorMuted, "Выберите фильтр")

    ; Ряд 1 — категории + импорт/экспорт (сетка ~600)
    addCategoryButton := AddViewControl(view, "Text", "x250 y222 w95 h28 +0x200 Center Background" colorAccent " c" colorText, "Доб. кат.")
    BindTextButton(addCategoryButton, colorAccent, AddBindCategory)
    deleteCategoryButton := AddViewControl(view, "Text", "x353 y222 w95 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Удал. кат.")
    BindTextButton(deleteCategoryButton, colorCardAlt, DeleteSelectedBindCategory)
    toggleCategoryButton := AddViewControl(view, "Text", "x456 y222 w100 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Вкл/Выкл")
    BindTextButton(toggleCategoryButton, colorCardAlt, ToggleSelectedBindCategory)
    importButton := AddViewControl(view, "Text", "x564 y222 w90 h28 +0x200 Center Background" colorAccent " c" colorText, "Импорт")
    BindTextButton(importButton, colorAccent, ImportBindsFromFile)
    exportButton := AddViewControl(view, "Text", "x662 y222 w90 h28 +0x200 Center Background" colorAccent " c" colorText, "Экспорт")
    BindTextButton(exportButton, colorAccent, ExportBindsToFile)
    testButton := AddViewControl(view, "Text", "x760 y222 w90 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Тест")
    BindTextButton(testButton, colorCardAlt, TestSelectedBind)

    ; Ряд 2 — бинды
    addButton := AddViewControl(view, "Text", "x250 y270 w112 h28 +0x200 Center Background" colorAccent " c" colorText, "Добавить")
    BindTextButton(addButton, colorAccent, AddBind)
    editButton := AddViewControl(view, "Text", "x374 y270 w112 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Изменить")
    BindTextButton(editButton, colorCardAlt, EditSelectedBind)
    deleteButton := AddViewControl(view, "Text", "x498 y270 w112 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Удалить")
    BindTextButton(deleteButton, colorCardAlt, DeleteSelectedBind)
    toggleButton := AddViewControl(view, "Text", "x622 y270 w112 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Вкл/Выкл")
    BindTextButton(toggleButton, colorCardAlt, ToggleSelectedBind)
    dupButton := AddViewControl(view, "Text", "x746 y270 w104 h28 +0x200 Center Background" colorAccent " c" colorText, "Дубликаты")
    BindTextButton(dupButton, colorAccent, ShowBindDuplicatesScan)

    ; Список + превью справа
    BindsListCtrl := AddViewControl(view, "ListView", "x250 y316 w360 h200 Background" colorCard " c" colorText, ["Тип", "Категория", "Название", "Триггер", "Статус", "Ключ"])
    BindsListCtrl.ModifyCol(1, 70)
    BindsListCtrl.ModifyCol(2, 70)
    BindsListCtrl.ModifyCol(3, 90)
    BindsListCtrl.ModifyCol(4, 70)
    BindsListCtrl.ModifyCol(5, 50)
    BindsListCtrl.ModifyCol(6, 0)
    BindsListCtrl.OnEvent("ColClick", SortBindsByColumn)
    BindsListCtrl.OnEvent("DoubleClick", EditSelectedBind)
    BindsListCtrl.OnEvent("ItemSelect", OnBindListSelect)
    BindsListCtrl.OnEvent("Click", OnBindListSelect)

    AddViewControl(view, "Text", "x620 y316 w230 h18 Background" colorBg " c" colorMuted, "Превью содержимого")
    global BindsPreviewCtrl
    BindsPreviewCtrl := AddViewControl(view, "Edit", "x620 y336 w230 h180 ReadOnly +Multi +WantReturn +VScroll Background" colorCard " c" colorText, "Выберите бинд в списке")
}

SortBindsByColumn(ctrl, column) {
    global BindsSortColumn, BindsSortAscending

    if (column > 5)
        return

    if (BindsSortColumn = column)
        BindsSortAscending := !BindsSortAscending
    else {
        BindsSortColumn := column
        BindsSortAscending := true
    }

    RefreshBindsList()
}

AddBind(*) {
    OpenBindEditor("")
}

AddBindCategory(*) {
    result := ShowBindCategoryInputDialog()
    if (result.Result != "OK")
        return

    category := Trim(result.Value)
    if !AddBindCategoryByName(category)
        return

    RefreshBindCategoryFilter(category)
    RefreshBindsList()
}

; Импорт биндов из CSV того же формата, что пишет ChesNova:
; type|category|name|trigger|content|enabled
; Категория берётся из имени файла; файл копируется в data\binds\imports\.
ImportBindsFromFile(*) {
    global bindsDir

    selectedPath := FileSelect(1, bindsDir, "Импорт биндов", "Бинды CSV (*.csv)")
    if (selectedPath = "")
        return

    SplitPath(selectedPath, &fileName, &sourceDir, &ext, &nameNoExt)
    categoryName := Trim(nameNoExt)

    if (categoryName = "") {
        ShowAppDialog("Импорт биндов", "Не удалось определить имя категории из файла.")
        return
    }
    if (categoryName = "Все") {
        ShowAppDialog("Импорт биндов", "Нельзя импортировать в системную категорию " Chr(34) "Все" Chr(34) ". Переименуйте файл.")
        return
    }

    importedBinds := ReadBindsFromFile(selectedPath, "ImportBindsFromFile")
    if (importedBinds.Length = 0) {
        ShowAppDialog("Импорт биндов", "В файле нет распознанных биндов.`n`nОжидается формат:`ntype|category|name|trigger|content|enabled")
        return
    }

    categoryCreated := false
    if !BindCategoryExists(categoryName) {
        if !AddBindCategoryByName(categoryName)
            return
        categoryCreated := true
    }

    existingBinds := ReadBinds()
    existingTriggers := Map()
    for _, bind in existingBinds {
        trigger := Trim(bind["trigger"])
        if (trigger != "")
            existingTriggers[trigger] := true
    }

    addedCount := 0
    skippedCount := 0
    for _, bind in importedBinds {
        trigger := Trim(bind["trigger"])
        if (trigger = "") {
            skippedCount += 1
            continue
        }
        if existingTriggers.Has(trigger) {
            skippedCount += 1
            continue
        }

        bind["category"] := categoryName
        bind["type"] := NormalizeBindType(bind["type"])
        bind["name"] := Trim(bind["name"])
        bind["trigger"] := trigger
        bind["content"] := bind["content"]
        bind["enabled"] := (bind["enabled"] + 0) ? 1 : 0
        if (bind["name"] = "")
            bind["name"] := trigger

        existingBinds.Push(bind)
        existingTriggers[trigger] := true
        addedCount += 1
    }

    if (addedCount = 0) {
        ShowAppDialog("Импорт биндов", "Новых биндов нет.`nВсе триггеры из файла уже существуют или строки пустые.`nПропущено: " skippedCount)
        return
    }

    if !WriteBinds(existingBinds) {
        ShowAppDialog("Импорт биндов", "Не удалось сохранить импортированные бинды.")
        return
    }

    ; Копия исходника в папку imports (не move — оригинал у автора сохраняется)
    try {
        importsDir := bindsDir "\imports"
        DirCreate(importsDir)
        destPath := importsDir "\" fileName
        if (StrLower(selectedPath) != StrLower(destPath))
            FileCopy(selectedPath, destPath, 1)
    } catch as err {
        LogError("ImportBindsFromFile", "Не удалось скопировать файл в imports", err.Message)
    }

    RegisterCustomBinds()
    RefreshBindCategoryFilter(categoryName)

    message := "Категория: " categoryName
    if categoryCreated
        message .= " (создана)"
    message .= "`nДобавлено биндов: " addedCount
    if (skippedCount > 0)
        message .= "`nПропущено (дубли/пустые): " skippedCount
    message .= "`nКопия файла: data\binds\imports\"

    ShowAppDialog("Импорт биндов", message)
    ShowToast("✓ Импорт: +" addedCount " в «" categoryName "»")
}

GetSelectedBindCategory() {
    global BindsCategoryCtrl

    if !IsObject(BindsCategoryCtrl)
        return ""

    category := Trim(BindsCategoryCtrl.Text)
    if (category = "Все")
        category := ""

    return category
}

DeleteSelectedBindCategory(*) {
    category := GetSelectedBindCategory()
    if (category = "") {
        ShowAppDialog("Категории биндов", "Выберите категорию в фильтре.")
        return
    }

    if !DeleteBindCategoryByName(category)
        return

    RefreshBindCategoryFilter("Все")
    RegisterCustomBinds()
    RefreshBindsList()
}

ToggleSelectedBindCategory(*) {
    category := GetSelectedBindCategory()
    if (category = "") {
        ShowAppDialog("Категории биндов", "Выберите категорию в фильтре.")
        return
    }

    SetBindCategoryEnabled(category, IsBindCategoryEnabled(category) ? 0 : 1)
    RegisterCustomBinds()
    RefreshBindsList()
}

EditSelectedBind(*) {
    trigger := GetSelectedBindTrigger()
    if (trigger = "") {
        ShowAppDialog("Бинды", "Выберите бинд для редактирования.")
        return
    }

    OpenBindEditor(trigger)
}

DeleteSelectedBind(*) {
    triggers := GetSelectedBindTriggers()
    if (triggers.Length = 0) {
        ShowAppDialog("Бинды", "Выберите один или несколько биндов для удаления.")
        return
    }

    message := (triggers.Length = 1)
        ? "Удалить выбранный бинд?"
        : "Удалить выбранные бинды: " triggers.Length " шт.?"

    result := ShowAppDialog("Удаление бинда", message, "YesNo")
    if (result != "Yes")
        return

    newBinds := []
    for _, bind in ReadBinds() {
        if !ArrayHasValue(triggers, bind["trigger"])
            newBinds.Push(bind)
    }

    if !WriteBinds(newBinds)
        return
    RegisterCustomBinds()
    RefreshBindsList()
}

ToggleSelectedBind(*) {
    triggers := GetSelectedBindTriggers()
    if (triggers.Length = 0) {
        ShowAppDialog("Бинды", "Выберите один или несколько биндов для включения или выключения.")
        return
    }

    binds := ReadBinds()
    for _, bind in binds {
        if ArrayHasValue(triggers, bind["trigger"])
            bind["enabled"] := bind["enabled"] ? 0 : 1
    }

    if !WriteBinds(binds)
        return
    RegisterCustomBinds()
    RefreshBindsList()
}

OpenBindEditor(originalTrigger := "") {
    global BindEditGui, BindEditId, BindEditTypeCtrl, BindEditCategoryCtrl, BindEditNameCtrl, BindEditTriggerCtrl, BindEditContentCtrl, BindEditEnabledCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    originalTrigger := Trim(originalTrigger)

    ; Если окно добавления/редактирования уже открыто или скрыто — не пересоздаём его,
    ; чтобы случайное переключение окон не сбрасывало введённые данные.
    if IsObject(BindEditGui) {
        if (BindEditId = originalTrigger) {
            try BindEditGui.Show()
            try WinActivate(BindEditGui.Hwnd)
            return
        }

        ; Если пользователь выбрал другой бинд для редактирования, создаём окно заново под выбранный trigger.
        SafeDestroyGui(&BindEditGui)
    }

    BindEditId := originalTrigger
    bind := (originalTrigger != "") ? GetBindByTrigger(originalTrigger) : ""
    typeText := IsObject(bind) ? GetBindTypeText(bind["type"]) : GetBindTypeText("hotkey")
    category := IsObject(bind) ? bind["category"] : "Все"
    bindName := IsObject(bind) ? bind["name"] : ""
    trigger := IsObject(bind) ? bind["trigger"] : ""
    content := IsObject(bind) ? bind["content"] : GetBindTemplateByType(typeText)
    enabled := IsObject(bind) ? (bind["enabled"] + 0) : 1

    BindEditGui := Gui("+Resize +MinSize640x500 +Border", originalTrigger != "" ? "Редактирование бинда" : "Добавление бинда")
    BindEditGui.OnEvent("Close", HideBindEdit)
    BindEditGui.OnEvent("Escape", HideBindEdit)
    BindEditGui.BackColor := colorBg
    BindEditGui.MarginX := 0
    BindEditGui.MarginY := 0
    BindEditGui.SetFont("s10 c" colorText, "Segoe UI")

    BindEditGui.Add("Text", "x0 y0 w640 h500 Background" colorBg)
    BindEditGui.Add("Text", "x18 y18 w604 h394 Background" colorCard)
    BindEditGui.SetFont("s12 Bold c" colorText, "Segoe UI")
    BindEditGui.Add("Text", "x34 y30 w260 h26 Background" colorCard, originalTrigger != "" ? "Редактирование бинда" : "Добавление бинда")
    BindEditGui.SetFont("s9 Norm c" colorMuted, "Segoe UI")

    BindEditGui.Add("Text", "x34 y76 w90 h20 Background" colorCard, "Тип")
    BindEditTypeCtrl := BindEditGui.Add("ComboBox", "x34 y100 w170 h120", GetBindTypes())
    ChooseComboText(BindEditTypeCtrl, typeText, GetBindTypes())
    BindEditTypeCtrl.OnEvent("Change", BindTypeChanged)
    BindEditGui.Add("Text", "x224 y76 w120 h20 Background" colorCard, "Категория")
    BindEditCategoryCtrl := BindEditGui.Add("ComboBox", "x224 y100 w180 h120", GetBindCategories(false))
    ChooseComboText(BindEditCategoryCtrl, category, GetBindCategories(false))
    BindEditEnabledCtrl := BindEditGui.Add("Checkbox", "x424 y100 w140 Checked" enabled " c" colorText " Background" colorCard, "Включён")

    BindEditGui.Add("Text", "x34 y142 w120 h20 Background" colorCard, "Название")
    BindEditNameCtrl := BindEditGui.Add("Edit", "x34 y166 w270 h26 c" colorText " Background" uiInputBg, bindName)
    BindEditGui.Add("Text", "x324 y142 w120 h20 Background" colorCard, "Триггер")
    BindEditTriggerCtrl := BindEditGui.Add("Edit", "x324 y166 w262 h26 c" colorText " Background" uiInputBg, trigger)

    BindEditGui.Add("Text", "x34 y212 w180 h20 Background" colorCard, "Содержимое бинда")
    BindEditContentCtrl := BindEditGui.Add("Edit", "x34 y238 w552 h150 c" colorText " Background" uiInputBg " +WantReturn +VScroll", content)

    AddMiniWindowButton(BindEditGui, 390, 440, 104, 30, "Отмена", colorCardAlt, CancelBindEdit)
    AddMiniWindowButton(BindEditGui, 506, 440, 116, 30, "Сохранить", colorAccent, SaveBindEdit)
    BindEditGui.Show("w640 h500")
}


GetBindTemplateByType(type) {
    type := NormalizeBindType(type)

    switch type {
        case "hotkey":
            return "Send `"{F6}`"`nSleep 100`nSendText `"/fly`"`nSend `"{Enter}`"`n`nSendMessage, 0x50,, 0x4190419,, A`nSleep 100`nSend `"{F6}`"`nSleep 100`nSendText `"/pm  Чесик начал следить за игроком.`"`nSend `"{left 32}`""

        case "macro":
            return "SendText `"Здравствуйте игроки`"`nSend `"{Enter}`"`n`nSleep 1000`n`nSend `"{F6}`"`nSleep 100`nSendText `"С вами администратор Chesik`"`nSend `"{Enter}`"`n`nSleep 1000`n`nSend `"{F6}`"`nSleep 100`nSendText `"Сейчас начнем проверку, просьба не мешать.`"`nSend `"{Enter}`""

        case "hotstring":
            return "игрок получит конфетки"
    }

    return ""
}

IsDefaultBindTemplate(content) {
    content := Trim(content)

    if (content = "")
        return true

    for _, type in GetBindTypes() {
        if (content = Trim(GetBindTemplateByType(type)))
            return true
    }

    ; Поддержка старых английских названий, если шаблон уже был создан раньше.
    for _, type in ["Hotkey", "Hotstring", "Macro"] {
        if (content = Trim(GetBindTemplateByType(type)))
            return true
    }

    return false
}

BindTypeChanged(ctrl, *) {
    global BindEditContentCtrl

    if !IsObject(BindEditContentCtrl)
        return

    if !IsDefaultBindTemplate(BindEditContentCtrl.Value)
        return

    BindEditContentCtrl.Value := GetBindTemplateByType(ctrl.Text)
}

ChooseComboText(ctrl, value, options) {
    index := 1
    for i, option in options {
        if (option = value) {
            index := i
            break
        }
    }
    ctrl.Choose(index)
}

SaveBindEdit(*) {
    global BindEditGui, BindEditId, BindEditTypeCtrl, BindEditCategoryCtrl, BindEditNameCtrl, BindEditTriggerCtrl, BindEditContentCtrl, BindEditEnabledCtrl

    if !IsObject(BindEditGui)
        return

    bindType := NormalizeBindType(BindEditTypeCtrl.Text)
    category := Trim(BindEditCategoryCtrl.Text)
    bindName := Trim(BindEditNameCtrl.Value)
    trigger := Trim(BindEditTriggerCtrl.Value)
    content := BindEditContentCtrl.Value
    enabled := BindEditEnabledCtrl.Value ? 1 : 0
    originalTrigger := Trim(BindEditId)

    if (category = "" || bindName = "" || trigger = "" || Trim(content) = "") {
        ShowAppDialog("Бинды", "Заполните категорию, название, триггер и содержимое.")
        return
    }

    if !BindCategoryExists(category) {
        ShowAppDialog("Бинды", "Такой категории нет: " category)
        return
    }

    if (bindType = "hotstring" || bindType = "macro")
        trigger := RegExReplace(trigger, "^:\*?\??:|::$")

    if BindTriggerExists(trigger, originalTrigger) {
        ShowAppDialog("Бинды", "Бинд с таким триггером уже существует: " trigger)
        return
    }

    conflicts := FindSimilarBindTriggers(trigger, bindType, originalTrigger)
    suffixConflicts := []
    for _, c in conflicts {
        if (c["kind"] = "suffix")
            suffixConflicts.Push(c)
    }
    if (suffixConflicts.Length > 0) {
        result := ShowAppDialog("Поиск дубликатов", FormatBindConflictMessage(suffixConflicts), "YesNo")
        if (result != "Yes")
            return
    }

    binds := ReadBinds()
    updated := false
    newBind := Map("type", bindType, "category", category, "name", bindName, "trigger", trigger, "content", content, "enabled", enabled)

    for i, bind in binds {
        if (bind["trigger"] = originalTrigger) {
            binds[i] := newBind
            updated := true
            break
        }
    }

    if (!updated)
        binds.Push(newBind)

    if !WriteBinds(binds)
        return
    RegisterCustomBinds()
    RefreshBindsList()
    SafeDestroyGui(&BindEditGui)
    ShowToast("✓ Бинд сохранён")
}

HideBindEdit(*) {
    global BindEditGui

    if IsObject(BindEditGui)
        BindEditGui.Hide()
}

CancelBindEdit(*) {
    HideBindEdit()
}

SettingsView() {
    global nick, norm, autoResetEnabled, checkUpdatesOnStartup, startWithWindows, resetHour, resetMinute, menuKey, resetKey, aiKey, menuKeyEnabled, resetKeyEnabled, aiKeyEnabled, aiProvider, uiTheme, logFile
    global SetNickCtrl, SetNormCtrl, SetMenuKeyCtrl, SetResetKeyCtrl, SetAiKeyCtrl, SetMenuKeyEnabledCtrl, SetResetKeyEnabledCtrl, SetAiKeyEnabledCtrl, SetAiProviderCtrl
    global SetAutoResetCtrl, SetCheckUpdatesCtrl, SetStartupCtrl, SetResetHourCtrl, SetResetMinuteCtrl, LogFileTextCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorYellow

    view := "Settings"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Настройки")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)

    ; —— Левая колонка ——
    ; Профиль
    AddViewControl(view, "Text", "x250 y88 w280 h102 Background" colorCard)
    AddViewControl(view, "Text", "x270 y104 w220 h22 Background" colorCard " c" colorText, "Пользователь")
    AddViewControl(view, "Text", "x270 y136 w110 h22 Background" colorCard " c" colorMuted, "Ник")
    SetNickCtrl := AddViewControl(view, "Edit", "vSetNick x390 y132 w120 h26 c" colorText " Background" uiInputBg, nick)
    AddViewControl(view, "Text", "x270 y166 w110 h22 Background" colorCard " c" colorMuted, "Норма PM")
    SetNormCtrl := AddViewControl(view, "Edit", "vSetNorm x390 y162 w120 h26 Number c" colorText " Background" uiInputBg, norm)

    ; Горячие клавиши
    AddViewControl(view, "Text", "x250 y206 w280 h196 Background" colorCard)
    AddViewControl(view, "Text", "x270 y222 w200 h22 Background" colorCard " c" colorText, "Горячие клавиши")
    AddViewControl(view, "Text", "x494 y230 w28 h18 Background" colorCard " c" colorMuted, "Вкл.")
    AddViewControl(view, "Text", "x270 y256 w110 h22 Background" colorCard " c" colorMuted, "Открыть меню")
    SetMenuKeyCtrl := AddViewControl(view, "Edit", "vSetMenuKey x390 y252 w98 h26 c" colorText " Background" uiInputBg, menuKey)
    SetMenuKeyEnabledCtrl := AddViewControl(view, "Checkbox", "vSetMenuKeyEnabled x496 y256 w20 h20 Checked" menuKeyEnabled " Background" colorCard)
    AddViewControl(view, "Text", "x270 y292 w110 h22 Background" colorCard " c" colorMuted, "Сброс PM")
    SetResetKeyCtrl := AddViewControl(view, "Edit", "vSetResetKey x390 y288 w98 h26 c" colorText " Background" uiInputBg, resetKey)
    SetResetKeyEnabledCtrl := AddViewControl(view, "Checkbox", "vSetResetKeyEnabled x496 y292 w20 h20 Checked" resetKeyEnabled " Background" colorCard)
    AddViewControl(view, "Text", "x270 y328 w110 h22 Background" colorCard " c" colorMuted, "AI-ассистент")
    SetAiKeyCtrl := AddViewControl(view, "Edit", "vSetAiKey x390 y324 w98 h26 c" colorText " Background" uiInputBg, aiKey)
    SetAiKeyEnabledCtrl := AddViewControl(view, "Checkbox", "vSetAiKeyEnabled x496 y328 w20 h20 Checked" aiKeyEnabled " Background" colorCard)
    AddViewControl(view, "Text", "x270 y364 w240 h22 Background" colorCard " c" colorMuted, "В игре: /ai вопрос + Enter")

    ; ИИ — отдельная карточка
    AddViewControl(view, "Text", "x250 y418 w280 h138 Background" colorCard)
    AddViewControl(view, "Text", "x270 y434 w240 h22 Background" colorCard " c" colorText, "ИИ-модель")
    providerChoices := ["Gemini", "DeepSeek · платная", "Groq"]
    if (aiProvider = "deepseek")
        providerIndex := 2
    else if (aiProvider = "groq")
        providerIndex := 3
    else
        providerIndex := 1
    SetAiProviderCtrl := AddViewControl(view, "DropDownList", "vSetAiProvider x270 y464 w240 h120 Choose" providerIndex " c" colorText " Background" uiInputBg, providerChoices)
    AddViewControl(view, "Text", "x270 y500 w240 h20 Background" colorCard " c" colorMuted, "Gemini и Groq — бесплатно")
    AddViewControl(view, "Text", "x270 y520 w240 h20 Background" colorCard " c" colorMuted, "DeepSeek — платная")

    ; —— Правая колонка ——
    AddViewControl(view, "Text", "x550 y88 w300 h142 Background" colorCard)
    AddViewControl(view, "Text", "x570 y104 w220 h22 Background" colorCard " c" colorText, "Автосброс нормы")
    SetAutoResetCtrl := AddViewControl(view, "Checkbox", "vSetAutoReset x570 y136 Checked" autoResetEnabled " c" colorText " Background" colorCard, "Включить автосброс")
    AddViewControl(view, "Text", "x570 y172 w60 h22 Background" colorCard " c" colorMuted, "Часы")
    SetResetHourCtrl := AddViewControl(view, "Edit", "vSetResetHour x635 y168 w58 h26 Number c" colorText " Background" uiInputBg, resetHour)
    AddViewControl(view, "Text", "x708 y172 w64 h22 Background" colorCard " c" colorMuted, "Минуты")
    SetResetMinuteCtrl := AddViewControl(view, "Edit", "vSetResetMinute x782 y168 w48 h26 Number c" colorText " Background" uiInputBg, resetMinute)

    AddViewControl(view, "Text", "x550 y246 w300 h180 Background" colorCard)
    AddViewControl(view, "Text", "x570 y262 w220 h22 Background" colorCard " c" colorText, "Файл логов")
    logText := logFile
    if (logText = "")
        logText := "Файл не выбран"
    LogFileTextCtrl := AddViewControl(view, "Edit", "vLogFileText x570 y292 w260 h58 ReadOnly -Wrap c" colorText " Background" uiInputBg, logText)
    selectLogButton := AddViewControl(view, "Text", "x570 y366 w260 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Выбрать chatlog.txt")
    BindTextButton(selectLogButton, colorCardAlt, SelectLogFile)

    AddViewControl(view, "Text", "x550 y442 w300 h86 Background" colorCard)
    AddViewControl(view, "Text", "x570 y456 w260 h20 Background" colorCard " c" colorText, "Запуск и автоматизация")
    SetStartupCtrl := AddViewControl(view, "Checkbox", "vSetStartup x570 y482 Checked" startWithWindows " c" colorText " Background" colorCard, "Запускать вместе с Windows")

    saveButton := AddViewControl(view, "Text", "x550 y540 w300 h34 +0x200 Center Background" colorAccent " cFFFFFF", "Сохранить настройки")
    BindTextButton(saveButton, colorAccent, SaveSettings)
}

UpdatesView() {
    global appVersion, checkUpdatesOnStartup, SetCheckUpdatesCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Updates"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Обновления")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y94 w600 h116 Background" colorCard)
    AddViewControl(view, "Text", "x274 y116 w250 h24 Background" colorCard " c" colorText, "ChesNova " appVersion)
    AddViewControl(view, "Text", "x274 y148 w430 h24 Background" colorCard " c" colorMuted, "Проверяйте новые версии и управляйте обновлением приложения.")
    SetCheckUpdatesCtrl := AddViewControl(view, "Checkbox", "vSetCheckUpdates x274 y176 Checked" checkUpdatesOnStartup " c" colorText " Background" colorCard, "Проверять обновления при запуске")
    AddViewControl(view, "Text", "x250 y226 w600 h100 Background" colorCard)
    AddViewControl(view, "Text", "x274 y242 w260 h20 Background" colorCard " c" colorText, "Действия с обновлением")
    checkButton := AddViewControl(view, "Text", "x274 y270 w268 h34 +0x200 Center Background" colorCardAlt " c" colorText, "Проверить обновления")
    BindTextButton(checkButton, colorCardAlt, CheckForUpdatesManual)
    updateButton := AddViewControl(view, "Text", "x558 y270 w268 h34 +0x200 Center Background" colorAccent " cFFFFFF", "Обновить ChesNova")
    BindTextButton(updateButton, colorAccent, ManualUpdateChesNova)
    AddViewControl(view, "Text", "x250 y342 w600 h86 Background" colorCard)
    AddViewControl(view, "Text", "x274 y358 w530 h20 Background" colorCard " c" colorMuted, "Настройка проверки при запуске сохраняется отдельно.")
    saveButton := AddViewControl(view, "Text", "x274 y388 w552 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Сохранить настройки")
    BindTextButton(saveButton, colorCardAlt, SaveSettings)
    AddViewControl(view, "Text", "x250 y444 w600 h72 Background" colorCard)
    AddViewControl(view, "Text", "x274 y458 w530 h18 Background" colorCard " c" colorMuted, "Если автоматическое обновление недоступно:")
    downloadButton := AddViewControl(view, "Text", "x274 y484 w552 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Скачать последнюю версию")
    BindTextButton(downloadButton, colorCardAlt, DownloadLatestUpdate)
}

RefreshUpdatesView(*) {
    global checkUpdatesOnStartup, SetCheckUpdatesCtrl

    if IsObject(SetCheckUpdatesCtrl)
        SetCheckUpdatesCtrl.Value := checkUpdatesOnStartup
}

TesterView() {
    global TesterModeCtrl, TesterStatusCtrl, TesterInfoCtrl, testerMode
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorRed

    view := "Tester"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Тестировщик")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y88 w600 h40 Background" colorBg " c" colorMuted, "Тестовые сборки с GitHub. Включи режим, чтобы проверять и скачивать beta-версии.")

    AddViewControl(view, "Text", "x250 y140 w600 h100 Background" colorCard)
    TesterModeCtrl := AddViewControl(view, "Checkbox", "x274 y158 w400 h24 Checked" testerMode " c" colorText " Background" colorCard, "Я тестировщик — показывать тестовый канал")
    TesterModeCtrl.OnEvent("Click", ToggleTesterMode)
    TesterStatusCtrl := AddViewControl(view, "Text", "x274 y196 w552 h28 Background" colorCard " c" colorAccent " +0x200", "")

    AddViewControl(view, "Text", "x250 y256 w600 h170 Background" colorCard)
    AddViewControl(view, "Text", "x274 y268 w500 h20 Background" colorCard " c" colorText, "Тестовый канал")
    TesterInfoCtrl := AddViewControl(view, "Edit", "x274 y292 w552 h78 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, "")
    checkButton := AddViewControl(view, "Text", "x274 y380 w170 h28 +0x200 Center Background" colorAccent " c" colorText, "Проверить")
    BindTextButton(checkButton, colorAccent, CheckTestUpdates)
    downloadButton := AddViewControl(view, "Text", "x456 y380 w170 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Скачать")
    BindTextButton(downloadButton, colorCardAlt, DownloadTestUpdate)
    installButton := AddViewControl(view, "Text", "x638 y380 w188 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Установить test")
    BindTextButton(installButton, colorCardAlt, InstallTestUpdate)

    AddViewControl(view, "Text", "x250 y424 w600 h100 Background" colorCard)
    AddViewControl(view, "Text", "x274 y436 w500 h20 Background" colorCard " c" colorText, "Стабильный релиз")
    AddViewControl(view, "Text", "x274 y460 w360 h36 Background" colorCard " c" colorMuted, "Вернуть официальную сборку из versions/version.json")
    rollbackButton := AddViewControl(view, "Text", "x640 y458 w186 h32 +0x200 Center Background" colorAccent " c" colorText, "Откат на релиз")
    BindTextButton(rollbackButton, colorAccent, RollbackToStableRelease)

    AddViewControl(view, "Text", "x250 y540 w600 h28 Background" colorBg " c" colorMuted, "GitHub test: Test/Test.json  •  релиз: versions/version.json")

    RefreshTesterView()
}

RefreshTesterView(*) {
    global TesterModeCtrl, TesterStatusCtrl, TesterInfoCtrl, testerMode, colorGreen, colorMuted

    if IsObject(TesterModeCtrl)
        TesterModeCtrl.Value := testerMode ? 1 : 0

    if IsObject(TesterStatusCtrl) {
        if testerMode {
            TesterStatusCtrl.Text := "Режим тестировщика включён"
            TesterStatusCtrl.SetFont("c" colorGreen)
        } else {
            TesterStatusCtrl.Text := "Режим выключен — тестовые сборки недоступны"
            TesterStatusCtrl.SetFont("c" colorMuted)
        }
    }

    if IsObject(TesterInfoCtrl) && (TesterInfoCtrl.Value = "") {
        if testerMode
            TesterInfoCtrl.Value := "Нажми «Проверить», чтобы загрузить информацию о тестовой версии."
        else
            TesterInfoCtrl.Value := "Включи «Я тестировщик», затем нажми «Проверить»."
    }
}

ToggleTesterMode(*) {
    global TesterModeCtrl, testerMode, settingsFile

    testerMode := (IsObject(TesterModeCtrl) && TesterModeCtrl.Value) ? 1 : 0
    TryIniWrite(testerMode, settingsFile, "Updates", "testerMode", "ToggleTesterMode")
    RefreshTesterView()
    if testerMode
        ShowToast("✓ Режим тестировщика включён")
    else
        ShowToast("Режим тестировщика выключен")
}

EnsureTesterModeEnabled() {
    global testerMode
    if testerMode
        return true
    ShowAppDialog("Тестировщик", "Сначала включи «Я тестировщик».`nБез этого тестовые сборки недоступны.")
    return false
}

DownloadTestVersionManifest() {
    global testVersionInfoUrl
    requestUrl := testVersionInfoUrl "?nocache=" A_Now "_" A_TickCount
    result := HttpGetText(requestUrl)
    if (result["status"] != 200)
        throw Error("GitHub вернул HTTP " result["status"] " для Test/Test.json.")
    return result["text"]
}

CheckTestUpdates(*) {
    global CURRENT_VERSION, TesterInfoCtrl

    if !EnsureTesterModeEnabled()
        return

    progressDlg := ShowCloudCheckProgressDialog()
    try progressDlg.Title := "Тестировщик"
    Sleep(40)

    try {
        versionInfo := ParseVersionManifest(DownloadTestVersionManifest())
        try progressDlg.Destroy()

        if (versionInfo["latest"] = "")
            throw Error("В Test/Test.json нет поля latest.")

        lineBreak := Chr(10)
        text := "Текущая версия: v" CURRENT_VERSION lineBreak
        text .= "Тестовая latest: v" versionInfo["latest"] lineBreak
        cmp := CompareVersions(versionInfo["latest"], CURRENT_VERSION)
        if (cmp > 0)
            text .= "Статус: есть более новая test-сборка" lineBreak
        else if (cmp = 0)
            text .= "Статус: test совпадает с текущей" lineBreak
        else
            text .= "Статус: test старше текущей (или другой номер)" lineBreak
        text .= lineBreak "Что нового:" lineBreak
        if (versionInfo["changelog"].Length = 0)
            text .= "• список изменений не указан"
        else {
            for _, entry in versionInfo["changelog"]
                text .= "• " entry lineBreak
        }
        if (versionInfo["download"] != "")
            text .= lineBreak "Ссылка: " versionInfo["download"]

        if IsObject(TesterInfoCtrl)
            TesterInfoCtrl.Value := text

        ShowAppDialog("Тестировщик", "Проверка test-канала завершена.`n`nТестовая версия: v" versionInfo["latest"])
        ShowToast("✓ Test-канал проверен")
    } catch as err {
        try progressDlg.Destroy()
        LogError("CheckTestUpdates", "Ошибка test-канала", err.Message)
        if IsObject(TesterInfoCtrl)
            TesterInfoCtrl.Value := "Ошибка: " err.Message
        ShowAppDialog("Тестировщик", "Не удалось проверить test-канал.`n`nУбедись, что на GitHub есть файл:`nTest/Test.json`n`n" err.Message)
    }
}

DownloadTestUpdate(*) {
    if !EnsureTesterModeEnabled()
        return

    try {
        versionInfo := ParseVersionManifest(DownloadTestVersionManifest())
        if (versionInfo["download"] = "") {
            ShowAppDialog("Тестировщик", "В Test/Test.json нет ссылки download.")
            return
        }
        Run(versionInfo["download"])
        ShowToast("✓ Открыта ссылка на test-сборку")
    } catch as err {
        LogError("DownloadTestUpdate", "Ошибка скачивания test", err.Message)
        ShowAppDialog("Тестировщик", "Не удалось скачать test-сборку.`n`n" err.Message)
    }
}

InstallTestUpdate(*) {
    global basePath, backupPath, CURRENT_VERSION

    if !EnsureTesterModeEnabled()
        return

    result := ShowAppDialog(
        "Тестировщик",
        "Установить тестовую сборку поверх текущей?`nБудет создан backup, затем файл заменят.`n`nСтабильный канал при этом не меняется — только локальный ChesNova.ahk.",
        "YesNo"
    )
    if (result != "Yes")
        return

    mainScript := basePath "\ChesNova.ahk"
    newScript := basePath "\ChesNova_test_new.ahk"

    try {
        versionInfo := ParseVersionManifest(DownloadTestVersionManifest())
        downloadUrl := versionInfo["download"]
        if (downloadUrl = "")
            throw Error("Нет поля download в Test/Test.json.")

        ; Если в манифесте zip — только открываем ссылку (установка zip вручную).
        if InStr(StrLower(downloadUrl), ".zip") {
            Run(downloadUrl)
            ShowAppDialog("Тестировщик", "Это ZIP-сборка.`nСсылка открыта в браузере — распакуй и замени файлы вручную.")
            return
        }

        if !FileExist(mainScript)
            throw Error("Не найден текущий ChesNova.ahk.")

        if FileExist(newScript)
            FileDelete(newScript)

        Download(downloadUrl, newScript)
        if !FileExist(newScript) || FileGetSize(newScript) = 0
            throw Error("Загруженный test-файл пустой.")

        DirCreate(backupPath)
        backupFile := backupPath "\ChesNova_before_test_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".ahk"
        FileCopy(mainScript, backupFile, 0)

        try {
            FileDelete(mainScript)
            FileMove(newScript, mainScript, 0)
        } catch as installErr {
            if !FileExist(mainScript) && FileExist(backupFile)
                FileCopy(backupFile, mainScript, 1)
            throw installErr
        }

        ShowToast("✓ Test-сборка установлена")
        PromptRestartAfterUpdate("Тестировщик", "Тестовая сборка установлена.`nBackup: " backupFile)
    } catch as err {
        if FileExist(newScript)
            try FileDelete(newScript)
        LogError("InstallTestUpdate", "Ошибка установки test", err.Message)
        ShowAppDialog("Тестировщик", "Не удалось установить test-сборку.`n`n" err.Message)
    }
}

; Откат с test-сборки на стабильный релиз (versions/version.json + versions/ChesNova.ahk).
RollbackToStableRelease(*) {
    global basePath, backupPath, CURRENT_VERSION

    if !EnsureTesterModeEnabled()
        return

    result := ShowAppDialog(
        "Откат на релиз",
        "Установить стабильную версию с GitHub?`nТекущий файл будет сохранён в backup, затем заменён релизом.`n`nСейчас у вас: v" CURRENT_VERSION,
        "YesNo"
    )
    if (result != "Yes")
        return

    mainScript := basePath "\ChesNova.ahk"
    newScript := basePath "\ChesNova_release_new.ahk"
    stableAhkUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/ChesNova.ahk"

    progressDlg := ShowCloudCheckProgressDialog()
    Sleep(40)

    try {
        if !FileExist(mainScript)
            throw Error("Не найден текущий ChesNova.ahk.")

        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        latest := versionInfo["latest"]
        downloadUrl := versionInfo["download"]

        ; Для авто-установки нужен .ahk. В манифесте часто zip — тогда берём versions/ChesNova.ahk.
        installUrl := stableAhkUrl
        if (downloadUrl != "" && InStr(StrLower(downloadUrl), ".ahk") && !InStr(StrLower(downloadUrl), ".zip"))
            installUrl := downloadUrl

        if FileExist(newScript)
            FileDelete(newScript)

        Download(installUrl, newScript)
        if !FileExist(newScript) || FileGetSize(newScript) = 0
            throw Error("Загруженный релизный файл пустой.`nURL: " installUrl)

        DirCreate(backupPath)
        backupFile := backupPath "\ChesNova_before_rollback_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".ahk"
        FileCopy(mainScript, backupFile, 0)

        try {
            FileDelete(mainScript)
            FileMove(newScript, mainScript, 0)
        } catch as installErr {
            if !FileExist(mainScript) && FileExist(backupFile)
                FileCopy(backupFile, mainScript, 1)
            throw installErr
        }

        try progressDlg.Destroy()

        msg := "Стабильный релиз установлен."
        if (latest != "")
            msg .= "`nВерсия на GitHub: v" latest
        msg .= "`nBackup: " backupFile
        ShowToast("✓ Откат на релиз выполнен")
        PromptRestartAfterUpdate("Откат на релиз", msg)
    } catch as err {
        try progressDlg.Destroy()
        if FileExist(newScript)
            try FileDelete(newScript)
        LogError("RollbackToStableRelease", "Ошибка отката на релиз", err.Message)
        ShowAppDialog("Откат на релиз", "Не удалось установить стабильную версию.`n`n" err.Message)
    }
}

RefreshSettingsView() {
    global logFile, LogFileTextCtrl

    if IsObject(LogFileTextCtrl)
        LogFileTextCtrl.Value := (logFile = "") ? "Файл не выбран" : logFile
}

HelpView() {
    global HelpEditCtrl, ErrorsLogTextCtrl
    global colorBg, colorCard, colorCardAlt, colorText, colorMuted

    view := "Help"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Помощь")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    helpText := "
(
СТАРТ

1. Откройте меню (по умолчанию F10).
2. Укажите игровой ник и норму PM.
3. chatlog.txt и корень игры подхватываются автоматически
   (при необходимости — вручную в «Настройках» / «Скриптах»).
4. Счётчик в игре ставится сам: loader-js.asi + ches.js
   (вкладка «Скрипты», путь к RADMIR CRMP).
5. Дождитесь зелёного статуса Cloud (вкладка Cloud).

Без подтверждённого Cloud счётчик PM не считает.

————————————————
ГОРЯЧИЕ КЛАВИШИ (по умолчанию)

F10 — меню ChesNova
F9  — сброс PM (с сохранением в историю)
F7  — AI-ассистент (окно в Windows)

В чате игры: /ai ваш вопрос + Enter
  → ответ показывается в игре (левый нижний угол, ~10 сек)

Клавиши можно сменить или отключить во вкладке «Настройки».

————————————————
СЧЁТЧИК В ИГРЕ (ches.js)

Правый нижний угол: ник, точка здоровья (ok / warn / critical), PM.
Левый нижний угол: ответ AI или «AI думает…».

Данные идут из ChesNova по локальному HTTP-мосту
(127.0.0.1:17890). Окно AHK-оверлея больше не используется.

————————————————
НОРМА И ОТГУЛЫ

Сброс: F9 или автосброс по времени в настройках.
История нормы и отгулы — во вкладках «Норма» и «Отгулы».

————————————————
НАКАЗАНИЯ И PM-ЛОГИ

Считаются только ваши действия из chatlog.
Фильтр по типу, периоду и поиску. Совпадения помечаются «».

————————————————
БИНДЫ

Включите «Бинды включены».
Типы: клавиша, текстовая замена, макрос.

Примеры триггеров:
  F1     — клавиша
  +1     — Shift+1
  ^F5    — Ctrl+F5
  !F2    — Alt+F2

Превью — справа от списка.
«Тест» — что уйдёт в чат, без отправки в игру.
Импорт / экспорт — CSV.

————————————————
AI

Ключ и дневной лимит — из Cloud по нику.
В «Настройках» можно выбрать ИИ: Gemini, DeepSeek или Groq.
  Gemini — A1000, DeepSeek — A999, Groq — A998.
F7 — полное окно ассистента (история, лимит).
/ai в игре — быстрый ответ прямо в HUD.

————————————————
ОБНОВЛЕНИЯ И СКРИПТЫ

«Обновления» — проверить / установить релиз.
«Скрипты» — путь к игре, установка loader + ches.js и пакетов.
«Тестировщик» — только если вы тестер.

————————————————
ПОДДЕРЖКА

Автор: Misha_Ches
VK: vk.com/m.ches
)"
    HelpEditCtrl := AddViewControl(view, "Edit", "vHelpEdit x250 y84 w600 h240 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, helpText)

    AddViewControl(view, "Text", "x250 y342 w220 Background" colorBg " c" colorMuted, "Последние ошибки")
    refreshErrorsButton := AddViewControl(view, "Text", "x500 y338 w100 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Обновить")
    BindTextButton(refreshErrorsButton, colorCardAlt, RefreshErrorsLogView)
    openErrorsButton := AddViewControl(view, "Text", "x610 y338 w110 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Открыть файл")
    BindTextButton(openErrorsButton, colorCardAlt, OpenErrorsLogFile)
    clearErrorsButton := AddViewControl(view, "Text", "x730 y338 w120 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Очистить лог")
    BindTextButton(clearErrorsButton, colorCardAlt, ClearErrorsLog)
    ErrorsLogTextCtrl := AddViewControl(view, "Edit", "vErrorsLogText x250 y376 w600 h108 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, GetLastErrorLogLines())
}

DiagnosticsView() {
    global DiagnosticTextCtrl, DiagnosticHealthCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Diagnostics"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Диагностика")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)
    AddViewControl(view, "Text", "x250 y94 w600 h380 Background" colorCard)
    DiagnosticHealthCtrl := AddViewControl(view, "Text", "x274 y112 w530 h24 Background" colorCard " c" colorAccent " +0x200", GetHealthStatusLine())
    AddViewControl(view, "Text", "x274 y140 w400 h18 Background" colorCard " c" colorMuted, "Проверка раз в 1 мин • автообновление на этой вкладке")
    refreshButton := AddViewControl(view, "Text", "x660 y500 w190 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Обновить")
    BindTextButton(refreshButton, colorCardAlt, RefreshDiagnosticsView)
    DiagnosticTextCtrl := AddViewControl(view, "Edit", "x274 y168 w530 h310 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, BuildDiagnosticsText())
    RunHealthCheck()
}

BuildDiagnosticsText() {
    global logFile, pmLogsFile, punishmentsFile, errorsLogFile
    global diagnosticLastCheckMs, diagnosticLastProcessedLines, diagnosticLastPmChanges, diagnosticLastLogSize, diagnosticLastReadBytes
    global diagnosticCheckLogSamples, diagnosticCheckLogTotalMs, diagnosticCheckLogMaxMs
    global healthState, healthMessage, healthIncidents, cloudAccessState, chatlogReadErrorStreak

    text := "—— Здоровье ——`n"
    text .= GetHealthStatusLine() "`n"
    text .= "Cloud: " GetCloudStatusText() "`n"
    text .= "Ошибки чтения chatlog подряд: " chatlogReadErrorStreak "`n`n"

    text .= "—— CheckLog ——`n"
    text .= "Интервал: 1000 мс`n"
    text .= "HUD: in-game (ches.js + HTTP-мост :17890)`n"
    text .= "Последний проход: " diagnosticLastCheckMs " мс`n"
    text .= "Среднее: " (diagnosticCheckLogSamples ? Round(diagnosticCheckLogTotalMs / diagnosticCheckLogSamples, 3) : 0) " мс`n"
    text .= "Максимум: " diagnosticCheckLogMaxMs " мс`n"
    text .= "Строк за проход: " diagnosticLastProcessedLines "`n"
    text .= "Новых PM: " diagnosticLastPmChanges "`n"
    text .= "Прочитано: " FormatDiagnosticBytes(diagnosticLastReadBytes) "`n"
    text .= "Размер chatlog: " FormatDiagnosticBytes(diagnosticLastLogSize) "`n`n"

    text .= "—— Файлы ——`n"
    text .= "chatlog.txt: " FormatDiagnosticFileSize(logFile) "`n"
    text .= "pm_logs.csv: " FormatDiagnosticFileSize(pmLogsFile) "`n"
    text .= "punishments_history.csv: " FormatDiagnosticFileSize(punishmentsFile) "`n"
    text .= "errors.log: " FormatDiagnosticFileSize(errorsLogFile) "`n`n"

    text .= "—— Последние инциденты ——`n"
    if (healthIncidents.Length = 0)
        text .= "нет`n"
    else {
        maxShow := Min(healthIncidents.Length, 12)
        Loop maxShow
            text .= healthIncidents[A_Index] "`n"
    }
    return text
}

GetHealthStatusLine() {
    global healthState, healthMessage
    label := "OK"
    if (healthState = "warn")
        label := "ВНИМАНИЕ"
    else if (healthState = "critical")
        label := "КРИТИЧНО"
    return label " — " healthMessage
}

GetHealthStatusColor() {
    global healthState, colorGreen, colorRed, colorYellow, colorAccent
    if (healthState = "ok")
        return colorGreen
    if (healthState = "warn")
        return colorYellow
    if (healthState = "critical")
        return colorRed
    return colorAccent
}

PushHealthIncident(message) {
    global healthIncidents
    entry := FormatTime(A_Now, "HH:mm:ss") "  " message
    healthIncidents.InsertAt(1, entry)
    while (healthIncidents.Length > 15)
        healthIncidents.Pop()
}

RunHealthCheck(*) {
    global logFile, cloudAccessState, diagnosticLastCheckMs, diagnosticCheckLogMaxMs
    global chatlogReadErrorStreak, lastChatlogChangeTick
    global healthState, healthMessage, lastHealthState, CurrentView
    global SettingsGui, settingsMenuBuilding

    issuesCritical := []
    issuesWarn := []

    if (logFile = "" || !FileExist(logFile))
        issuesCritical.Push("chatlog.txt не найден")

    if (cloudAccessState = "blocked" || cloudAccessState = "denied")
        issuesCritical.Push("Cloud: " GetCloudStatusText())
    else if (cloudAccessState = "offline")
        issuesCritical.Push("нет связи с Cloud")
    else if (cloudAccessState != "ok")
        issuesWarn.Push("Cloud ещё не подтверждён")

    if (chatlogReadErrorStreak >= 3)
        issuesCritical.Push("ошибки чтения chatlog (" chatlogReadErrorStreak " подряд)")
    else if (chatlogReadErrorStreak >= 1)
        issuesWarn.Push("сбои чтения chatlog (" chatlogReadErrorStreak ")")

    if (diagnosticLastCheckMs >= 400 || diagnosticCheckLogMaxMs >= 800)
        issuesWarn.Push("медленный CheckLog (last " diagnosticLastCheckMs " / max " diagnosticCheckLogMaxMs " мс)")

    ; Лог молчит 10+ минут при активном доступе Cloud
    silentMs := A_TickCount - lastChatlogChangeTick
    if (cloudAccessState = "ok" && lastChatlogChangeTick > 0 && silentMs >= 600000)
        issuesWarn.Push("chatlog не обновлялся " Round(silentMs / 60000) " мин")

    if (issuesCritical.Length > 0) {
        healthState := "critical"
        healthMessage := issuesCritical[1]
        if (issuesCritical.Length > 1)
            healthMessage .= " (+" (issuesCritical.Length - 1) ")"
    } else if (issuesWarn.Length > 0) {
        healthState := "warn"
        healthMessage := issuesWarn[1]
        if (issuesWarn.Length > 1)
            healthMessage .= " (+" (issuesWarn.Length - 1) ")"
    } else {
        healthState := "ok"
        healthMessage := "Всё в порядке"
    }

    if (healthState != lastHealthState) {
        if (healthState = "critical") {
            PushHealthIncident("КРИТИЧНО: " healthMessage)
            ShowToast("⚠ Критично: " healthMessage, 2800)
        } else if (healthState = "warn") {
            PushHealthIncident("Внимание: " healthMessage)
            ShowToast("⚠ " healthMessage, 2200)
        } else if (lastHealthState != "ok") {
            PushHealthIncident("Восстановлено: " healthMessage)
            ShowToast("✓ Здоровье: OK", 1600)
        }
        lastHealthState := healthState
    }

    WriteHudBridgeState()

    if (settingsMenuBuilding || !IsObject(SettingsGui) || CurrentView != "Diagnostics")
        return
    RefreshDiagnosticsView()
}
GetHighResolutionMilliseconds() {
    static frequency := 0

    if !frequency
        DllCall("QueryPerformanceFrequency", "Int64*", &frequency)

    counter := 0
    DllCall("QueryPerformanceCounter", "Int64*", &counter)
    return (counter * 1000.0) / frequency
}

FormatDiagnosticFileSize(filePath) {
    if (filePath = "" || !FileExist(filePath))
        return "не найден"
    return FormatDiagnosticBytes(FileGetSize(filePath))
}

FormatDiagnosticBytes(bytes) {
    if (bytes < 1024)
        return bytes " B"
    if (bytes < 1024 * 1024)
        return Round(bytes / 1024, 1) " KB"
    return Round(bytes / 1024 / 1024, 2) " MB"
}

RefreshDiagnosticsView(*) {
    global DiagnosticTextCtrl, DiagnosticHealthCtrl, SettingsGui, settingsMenuBuilding
    if (settingsMenuBuilding || !IsObject(SettingsGui))
        return
    try {
        if IsObject(DiagnosticTextCtrl)
            DiagnosticTextCtrl.Value := BuildDiagnosticsText()
        if IsObject(DiagnosticHealthCtrl) {
            DiagnosticHealthCtrl.Text := GetHealthStatusLine()
            DiagnosticHealthCtrl.SetFont("c" GetHealthStatusColor())
        }
    } catch as err {
        ResetDiagnosticsControls()
    }
}

CloudView() {
    global CloudNickCtrl, CloudStatusCtrl, CloudAccessTextCtrl, CloudLastCheckCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen

    view := "Cloud"
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Cloud")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background" uiDivider)

    AddViewControl(view, "Text", "x250 y94 w600 h120 Background" colorCard)
    AddViewControl(view, "Text", "x270 y112 w220 h22 Background" colorCard " c" colorMuted, "Аккаунт администратора")
    CloudNickCtrl := AddViewControl(view, "Text", "x270 y140 w260 h30 Background" colorCard " c" colorAccent " +0x200", "")
    CloudStatusCtrl := AddViewControl(view, "Text", "x270 y174 w260 h24 Background" colorCard " c" colorGreen " +0x200", "")
    checkButton := AddViewControl(view, "Text", "x610 y128 w110 h30 +0x200 Center Background" colorAccent " c" colorText, "Проверить")
    BindTextButton(checkButton, colorAccent, CloudCheckAccess)
    changeNickButton := AddViewControl(view, "Text", "x732 y128 w98 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Сменить ник")
    BindTextButton(changeNickButton, colorCardAlt, CloudChangeNick)

    AddViewControl(view, "Text", "x250 y236 w290 h116 Background" colorCard)
    AddViewControl(view, "Text", "x270 y258 w220 h22 Background" colorCard " c" colorMuted, "Статус доступа")
    CloudAccessTextCtrl := AddViewControl(view, "Text", "x270 y286 w230 h26 Background" colorCard " c" colorAccent " +0x200", "")
    CloudLastCheckCtrl := AddViewControl(view, "Text", "x270 y318 w230 h22 Background" colorCard " c" colorMuted, "")
}

RefreshCloudView(*) {
    global SettingsGui
    global nick, cloudAccessMessage, cloudLastCheck
    global CloudNickCtrl, CloudStatusCtrl, CloudAccessTextCtrl, CloudLastCheckCtrl
    global pmCount, norm, colorMuted

    UpdateCloudHudDot()
    if !IsObject(SettingsGui)
        return

    try {
        if IsObject(CloudNickCtrl)
            CloudNickCtrl.Text := nick
        if IsObject(CloudStatusCtrl) {
            CloudStatusCtrl.Text := GetCloudStatusText()
            CloudStatusCtrl.SetFont("c" GetCloudStatusColor())
        }
        if IsObject(CloudAccessTextCtrl) {
            CloudAccessTextCtrl.Text := cloudAccessMessage
            CloudAccessTextCtrl.SetFont("c" GetCloudStatusColor())
        }
        if IsObject(CloudLastCheckCtrl)
            CloudLastCheckCtrl.Text := (cloudLastCheck = "") ? "Проверка ещё не выполнялась" : "Последняя проверка: " cloudLastCheck
    } catch as err {
        ResetCloudControls()
    }
}

CloudCheckAccess(*) {
    global nick, cloudAccessState, cloudAccessMessage, colorGreen, colorRed

    progressDlg := ShowCloudCheckProgressDialog()
    ; Даем окну отрисоваться до синхронного HTTP-запроса.
    Sleep(50)
    CheckCloudAccess(false, false)
    try progressDlg.Destroy()

    RefreshDashboardView()
    RefreshCloudView()

    if (cloudAccessState = "ok") {
        ShowAppDialog(
            "Cloud",
            "Проверка завершена успешно.`n`nНик: " nick "`nСтатус: доступ подтверждён.",
            "OK",
            colorGreen
        )
        ShowToast("✓ Cloud: доступ подтверждён")
        return
    }

    detail := cloudAccessMessage
    if (detail = "")
        detail := GetCloudStatusText()

    ShowAppDialog(
        "Cloud",
        "Проверка завершена неудачно.`n`nНик: " nick "`nПричина: " detail,
        "OK",
        colorRed
    )
}

ShowCloudCheckProgressDialog() {
    global colorBg, colorCard, colorAccent, colorText, colorMuted

    dlg := Gui("+Border -SysMenu", "Cloud")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")
    dlg.Add("Text", "x0 y0 w380 h140 Background" colorBg)
    dlg.Add("Text", "x18 y18 w344 h104 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y40 w300 h24 Background" colorCard, "Проверка доступа…")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y72 w300 h36 Background" colorCard, "Сверяем ник с таблицей Cloud.`nПодождите несколько секунд.")
    dlg.Show("w380 h140")
    try WinActivate(dlg.Hwnd)
    return dlg
}

CloudChangeNick(*) {
    EnsureNickBeforeCloudAccess(true, "Введите ник для Cloud-доступа.")
    CheckCloudAccess(false, false)
    RefreshDashboardView()
    RefreshCloudView()
}

SendCloudPing(*) {
    CheckCloudAccess(false, false)
    RefreshDashboardView()
    RefreshCloudView()
}

StartupNetworkInit(*) {
    global checkUpdatesOnStartup
    CheckCloudAccess(true, true)
    FetchAiConfigFromCloud()
    if (checkUpdatesOnStartup)
        CheckForUpdates()
    CheckNotifications()
}

GetCloudStatusText() {
    global cloudAccessState

    switch cloudAccessState {
        case "ok":
            return "подключено"
        case "blocked":
            return "заблокировано"
        case "offline":
            return "нет связи"
        case "denied":
            return "ник не найден"
    }

    return "не проверено"
}

GetCloudStatusColor() {
    global cloudAccessState, colorGreen, colorRed, colorYellow, colorAccent

    switch cloudAccessState {
        case "ok":
            return colorGreen
        case "blocked", "denied", "offline":
            return colorRed
    }

    return colorAccent
}

GetCloudLocalDataSummary() {
    global pmLogsFile, historyFile

    return "PM логи: " CountFileRecords(pmLogsFile) "  •  Нормы: " CountFileRecords(historyFile)
}

GetCloudLocalDataDetails() {
    global punishmentsFile, daysOffFile, pmCount, norm

    return "Наказания: " CountFileRecords(punishmentsFile) "  •  Отгулы: " CountFileRecords(daysOffFile) "  •  Сегодня: " pmCount "/" norm
}

CountFileRecords(filePath) {
    count := 0
    if !FileExist(filePath)
        return 0

    for _, line in ReadFileLines(filePath) {
        if (Trim(line) != "")
            count++
    }

    return count
}

OpenMenuLegacy(*) {
    BuildMainWindow("Settings")
}


ResetDashboardControls() {
    global DashboardNickCtrl, DashboardSystemStatusCtrl, DashboardCloudStatusCtrl
    global DashboardNormCtrl, DashboardVersionCtrl, DashboardNormTitleCtrl
    global DashboardNormPmCtrl, DashboardNormRemainingCtrl, DashboardNormPercentCtrl
    global DashboardProgressBgCtrl, DashboardProgressFillCtrl, DashboardLogFileCtrl
    global DashboardDaysOffMonthCtrl
    global DashboardStatusChatlogCtrl, DashboardStatusGameCtrl, DashboardStatusHudCtrl

    DashboardNickCtrl := ""
    DashboardSystemStatusCtrl := ""
    DashboardCloudStatusCtrl := ""
    DashboardNormCtrl := ""
    DashboardVersionCtrl := ""
    DashboardNormTitleCtrl := ""
    DashboardNormPmCtrl := ""
    DashboardNormRemainingCtrl := ""
    DashboardNormPercentCtrl := ""
    DashboardProgressBgCtrl := ""
    DashboardProgressFillCtrl := ""
    DashboardLogFileCtrl := ""
    DashboardDaysOffMonthCtrl := ""
    DashboardStatusChatlogCtrl := ""
    DashboardStatusGameCtrl := ""
    DashboardStatusHudCtrl := ""
}

ResetDiagnosticsControls() {
    global DiagnosticTextCtrl, DiagnosticHealthCtrl
    DiagnosticTextCtrl := ""
    DiagnosticHealthCtrl := ""
}

ResetCloudControls() {
    global CloudNickCtrl, CloudStatusCtrl, CloudAccessTextCtrl, CloudLastCheckCtrl

    CloudNickCtrl := ""
    CloudStatusCtrl := ""
    CloudAccessTextCtrl := ""
    CloudLastCheckCtrl := ""
}

ResetNotificationControls() {
    global NotificationButtonCtrl, NotificationIndicatorCtrl

    NotificationButtonCtrl := ""
    NotificationIndicatorCtrl := ""
}

CloseSettings(*) {
    global SettingsGui, settingsMenuHidden, CurrentView
    SaveMenuPosition()
    SafeDestroyGui(&SettingsGui)
    settingsMenuHidden := false
    CurrentView := ""
    ResetDashboardControls()
    ResetDiagnosticsControls()
    ResetCloudControls()
    ResetNotificationControls()
}

HideSettingsMenu(*) {
    global SettingsGui, settingsMenuHidden

    if !IsObject(SettingsGui)
        return

    SaveMenuPosition()
    SettingsGui.Hide()
    settingsMenuHidden := true
}

SaveMenuPosition() {
    global SettingsGui, menuX, menuY, settingsFile

    if !IsObject(SettingsGui)
        return

    try {
        SettingsGui.GetPos(&menuX, &menuY)
        TryIniWrite(menuX, settingsFile, "GUI", "menuX", "SaveMenuPosition")
        TryIniWrite(menuY, settingsFile, "GUI", "menuY", "SaveMenuPosition")
    } catch as err {
        LogError("SaveMenuPosition", "Ошибка сохранения позиции меню", err.Message)
    }
}

SelectLogFile(*) {
    global logFile, lastSize, LogFileTextCtrl, settingsFile

    startDir := GetDefaultChatlogPath()
    if !FileExist(startDir)
        startDir := A_MyDocuments "\RADMIR CRMP User Files\SAMP"
    selectedFile := FileSelect(3, startDir, "Выберите chatlog.txt", "*.txt")
    if (selectedFile != "") {
        logFile := selectedFile
        try lastSize := FileGetSize(logFile)
        catch
            lastSize := 0
        if IsObject(LogFileTextCtrl)
            LogFileTextCtrl.Value := logFile
        TryIniWrite(logFile, settingsFile, "Main", "logFile", "SelectLogFile")
        AppendPmLog("Действие", "Выбран файл логов: " logFile)
        ShowToast("✓ chatlog выбран", 1800)
    }
}

; ------------------------------------------------------------
; 06. History window
; ------------------------------------------------------------

; =========================
; 📊 HISTORY — ТОЛЬКО ПОСЛЕДНИЕ 7 ДНЕЙ
; =========================
OpenHistory(*) {
    BuildMainWindow("NormHistory")
}

OpenHistoryLegacy(*) {
    BuildMainWindow("NormHistory")
}
CloseHistory(*) {
    global HistoryGui
    SafeDestroyGui(&HistoryGui)
}


; ------------------------------------------------------------
; 07. Punishments window
; ------------------------------------------------------------

; =========================
; ⚖️ PUNISHMENTS — ИСТОРИЯ ПО ДНЯМ
; =========================
OpenPunishments(*) {
    BuildMainWindow("Punishments")
}

OpenPunishmentsLegacy(*) {
    BuildMainWindow("Punishments")
}

RefreshPunishmentView(*) {
    RenderPunishmentView()
}

SetPunishmentToday(*) {
    SetPunishmentPeriod(1)
}

SetPunishment3Days(*) {
    SetPunishmentPeriod(3)
}

SetPunishment10Days(*) {
    SetPunishmentPeriod(10)
}

SetPunishmentAllTime(*) {
    SetPunishmentPeriod(0)
}

ShowPunishmentKick(*) {
    ShowPunishmentType("kick")
}

ShowPunishmentJail(*) {
    ShowPunishmentType("jail")
}

ShowPunishmentWarn(*) {
    ShowPunishmentType("warn")
}

ShowPunishmentMute(*) {
    ShowPunishmentType("mute")
}

ShowPunishmentVmute(*) {
    ShowPunishmentType("vmute")
}

ShowPunishmentRmute(*) {
    ShowPunishmentType("rmute")
}

ShowPunishmentGunban(*) {
    ShowPunishmentType("gunban")
}

ShowPunishmentBan(*) {
    ShowPunishmentType("ban")
}

ShowPunishmentSban(*) {
    ShowPunishmentType("sban")
}

ShowPunishmentAll(*) {
    ShowPunishmentType("all")
}

ClosePunishments(*) {
    global PunishmentsGui
    SafeDestroyGui(&PunishmentsGui)
}
; ------------------------------------------------------------
; 08. Help window
; ------------------------------------------------------------

; =========================
; ❓ HELP MENU (FIX FOCUS + VK)
; =========================
OpenHelp(*) {
    BuildMainWindow("Help")
}

OpenHelpLegacy(*) {
    BuildMainWindow("Help")
}

CloseHelp(*) {
    global HelpGui
    SafeDestroyGui(&HelpGui)
}

; ------------------------------------------------------------
; 09. Save settings and manual commands
; ------------------------------------------------------------

; =========================
; 💾 SAVE SETTINGS
; =========================
SaveSettings(*) {
    global SettingsGui
    global nick, userNick, norm, autoResetEnabled, bindsEnabled, checkUpdatesOnStartup, startWithWindows, resetHour, resetMinute
    global menuKey, resetKey, aiKey, menuKeyEnabled, resetKeyEnabled, aiKeyEnabled, aiProvider
    global geminiApiKey, geminiModel, deepseekApiKey, deepseekModel, groqApiKey, groqModel
    global uiTheme, settingsFile, logFile, lastResetDate, guiX, guiY, menuX, menuY, aiGuiX, aiGuiY

    SaveMenuPosition()
    values := SettingsGui.Submit()
    wasAutoResetEnabled := autoResetEnabled
    nick := Trim(values.SetNick)
    userNick := nick
    norm := values.SetNorm + 0
    autoResetEnabled := values.SetAutoReset
    checkUpdatesOnStartup := values.SetCheckUpdates
    startWithWindows := values.SetStartup
    resetHour := values.SetResetHour
    resetMinute := values.SetResetMinute

    if (autoResetEnabled && !wasAutoResetEnabled) {
        nowDate := FormatTime(A_Now, "yyyyMMdd")
        nowKey := FormatTime(A_Now, "yyyyMMddHHmm")
        targetKey := nowDate . Format("{:02}{:02}", resetHour, resetMinute)
        if (nowKey >= targetKey)
            lastResetDate := nowDate
    }

    menuKey := values.SetMenuKey
    resetKey := values.SetResetKey
    aiKey := values.SetAiKey
    menuKeyEnabled := values.SetMenuKeyEnabled
    resetKeyEnabled := values.SetResetKeyEnabled
    aiKeyEnabled := values.SetAiKeyEnabled
    if values.HasOwnProp("SetAiProvider") {
        providerText := StrLower(Trim(values.SetAiProvider))
        if InStr(providerText, "deepseek")
            aiProvider := "deepseek"
        else if InStr(providerText, "groq")
            aiProvider := "groq"
        else
            aiProvider := "gemini"
    }

    try {
        IniWrite(nick, settingsFile, "Main", "nick")
        IniWrite(norm, settingsFile, "Main", "norm")
        IniWrite(logFile, settingsFile, "Main", "logFile")
        IniWrite(autoResetEnabled, settingsFile, "Main", "autoResetEnabled")
        IniWrite(bindsEnabled, settingsFile, "Main", "bindsEnabled")
        IniWrite(checkUpdatesOnStartup, settingsFile, "Updates", "checkOnStartup")
        IniWrite(testerMode, settingsFile, "Updates", "testerMode")
        IniWrite(startWithWindows, settingsFile, "Launcher", "startWithWindows")
        IniWrite(resetHour, settingsFile, "Main", "resetHour")
        IniWrite(resetMinute, settingsFile, "Main", "resetMinute")
        IniWrite(lastResetDate, settingsFile, "Main", "lastResetDate")
        IniWrite(menuKey, settingsFile, "Keys", "menuKey")
        IniWrite(resetKey, settingsFile, "Keys", "resetKey")
        IniWrite(aiKey, settingsFile, "Keys", "aiKey")
        IniWrite(menuKeyEnabled, settingsFile, "Keys", "menuKeyEnabled")
        IniWrite(resetKeyEnabled, settingsFile, "Keys", "resetKeyEnabled")
        IniWrite(aiKeyEnabled, settingsFile, "Keys", "aiKeyEnabled")
        IniWrite(geminiApiKey, settingsFile, "AI", "geminiApiKey")
        IniWrite(geminiModel, settingsFile, "AI", "geminiModel")
        IniWrite(deepseekApiKey, settingsFile, "AI", "deepseekApiKey")
        IniWrite(deepseekModel, settingsFile, "AI", "deepseekModel")
        IniWrite(groqApiKey, settingsFile, "AI", "groqApiKey")
        IniWrite(groqModel, settingsFile, "AI", "groqModel")
        IniWrite(aiProvider, settingsFile, "AI", "aiProvider")
        IniWrite(guiX, settingsFile, "GUI", "guiX")
        IniWrite(guiY, settingsFile, "GUI", "guiY")
        IniWrite(menuX, settingsFile, "GUI", "menuX")
        IniWrite(menuY, settingsFile, "GUI", "menuY")
        IniWrite(aiGuiX, settingsFile, "GUI", "aiGuiX")
        IniWrite(aiGuiY, settingsFile, "GUI", "aiGuiY")
        IniWrite(uiTheme, settingsFile, "GUI", "uiTheme")
        SetWindowsStartup(startWithWindows)
    } catch as err {
        LogError("SaveSettings", "Ошибка записи settings.ini", err.Message)
        MsgBox("Не удалось сохранить настройки.`n`n" err.Message, "Ошибка", "Iconx")
        return
    }
    AppendPmLog("Действие", "Сохранены настройки ChesNova")
    ShowToast("✓ Настройки сохранены")

    SafeDestroyGui(&SettingsGui)
    ResetDashboardControls()
    ResetDiagnosticsControls()
    ResetCloudControls()
    ResetNotificationControls()

    RegisterHotkeys()

    UpdatePMDisplay()
}

SetWindowsStartup(enabled) {
    launcherPath := A_MyDocuments "\ChesNova\ChesNovaLauncher.ahk"
    runKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

    if enabled
        RegWrite(launcherPath, "REG_SZ", runKey, "ChesNova")
    else {
        try RegDelete(runKey, "ChesNova")
    }
}

; =========================
; RESET
; =========================
ResetPM(*) {
    global ResetConfirmGui

    SafeDestroyGui(&ResetConfirmGui)
    ResetConfirmGui := Gui("+Border", "Сброс PM")
    ResetConfirmGui.BackColor := "121214"
    ResetConfirmGui.MarginX := 14
    ResetConfirmGui.MarginY := 14
    ResetConfirmGui.SetFont("s10 cFFFFFF", "Segoe UI")
    ResetConfirmGui.SetFont("s12 Bold")
    ResetConfirmGui.Add("Text", "x14 y10 w220", "Сброс PM")
    ResetConfirmGui.SetFont("s12 Bold cFF4D4D")
    closeCtrl := ResetConfirmGui.Add("Text", "x260 y8 w20 Center", "✕")
    closeCtrl.OnEvent("Click", CancelResetPM)
    ResetConfirmGui.Add("Text", "x10 y38 w275 h1 0x10 Background2a2a2a")
    ResetConfirmGui.SetFont("s9 Norm cFFFFFF")
    ResetConfirmGui.Add("Text", "x14 y55 w260", "Сбросить текущий счетчик PM?")
    ResetConfirmGui.Add("Text", "x14 y80 w260 cA8A8A8", "Текущий результат будет сохранен в историю.")
    global colorAccent, colorCardAlt, colorText
    resetButton := ResetConfirmGui.Add("Text", "x14 y120 w125 h30 +0x200 Center Background" colorAccent " c" colorText, "Сбросить")
    BindTextButton(resetButton, colorAccent, ConfirmResetPM)
    cancelButton := ResetConfirmGui.Add("Text", "x149 y120 w125 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Отмена")
    BindTextButton(cancelButton, colorCardAlt, CancelResetPM)
    ResetConfirmGui.Show("w290 h165")
    try WinActivate(ResetConfirmGui.Hwnd)
}

ConfirmResetPM(*) {
    global ResetConfirmGui, pmCount, saveFile, dotRed, beepPlayed, PMCountTextCtrl, StatusDotCtrl

    SafeDestroyGui(&ResetConfirmGui)
    SaveDayStats()
    pmCount := 0
    TryFileDelete(saveFile, "ConfirmResetPM", "Ошибка удаления pm_count.txt")
    if IsObject(PMCountTextCtrl)
        PMCountTextCtrl.Text := "PM:0"
    UpdatePMDisplay()
    if IsObject(StatusDotCtrl) {
        StatusDotCtrl.Text := "●"
        StatusDotCtrl.SetFont("c" dotRed)
    }
    beepPlayed := false
    ShowToast("✓ Счётчик PM сброшен")
}

CancelResetPM(*) {
    global ResetConfirmGui
    SafeDestroyGui(&ResetConfirmGui)
}
; =========================
; CENTER GUI
; =========================
SaveAiQuotaLocal() {
    global settingsFile, aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiQuotaDate
    aiQuotaDate := FormatTime(, "yyyyMMdd")
    try {
        IniWrite(aiDailyLimit, settingsFile, "AI", "aiDailyLimit")
        IniWrite(aiDailyUsed, settingsFile, "AI", "aiDailyUsed")
        IniWrite(aiDailyRemaining, settingsFile, "AI", "aiDailyRemaining")
        IniWrite(aiQuotaDate, settingsFile, "AI", "aiQuotaDate")
    }
}

RefreshAiLimitUi() {
    global AiLimitCtrl
    try {
        if IsObject(AiLimitCtrl)
            AiLimitCtrl.Text := GetAiLimitStatusText()
    }
}

; Сверка при чтении конфига: Cloud не должен занижать локальный used за сегодня.
MergeAiQuotaFromCloud(cloudLimit, cloudUsed, cloudRemaining) {
    global aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiQuotaDate
    today := FormatTime(, "yyyyMMdd")
    localUsed := aiDailyUsed
    localLimit := aiDailyLimit

    if (cloudLimit > 0)
        aiDailyLimit := cloudLimit
    else if (localLimit > 0)
        aiDailyLimit := localLimit

    if (aiQuotaDate = today && localUsed > cloudUsed)
        aiDailyUsed := localUsed
    else
        aiDailyUsed := cloudUsed

    if (aiDailyLimit > 0)
        aiDailyRemaining := Max(0, aiDailyLimit - aiDailyUsed)
    else
        aiDailyRemaining := cloudRemaining

    aiQuotaDate := today
    SaveAiQuotaLocal()
}

; После успешного ai_use: used растёт минимум на +1 локально (если Cloud «залип»).
ApplySuccessfulAiUse(cloudLimit, cloudUsed, cloudRemaining) {
    global aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiQuotaDate
    today := FormatTime(, "yyyyMMdd")

    if (cloudLimit > 0)
        aiDailyLimit := cloudLimit

    if (aiQuotaDate != today) {
        aiDailyUsed := Max(cloudUsed, 1)
        aiQuotaDate := today
    } else {
        ; Локально +1, но не ниже того что сказал Cloud
        aiDailyUsed := Max(aiDailyUsed + 1, cloudUsed)
    }

    if (aiDailyLimit > 0)
        aiDailyRemaining := Max(0, aiDailyLimit - aiDailyUsed)
    else
        aiDailyRemaining := Max(0, cloudRemaining)

    SaveAiQuotaLocal()
    RefreshAiLimitUi()
}

FetchAiConfigFromCloud(*) {
    global nick, accessUrl, appVersion, settingsFile
    global geminiApiKey, deepseekApiKey, groqApiKey, geminiModel, deepseekModel, groqModel
    global aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiConfigLoaded
    global AiLimitCtrl

    if (Trim(nick) = "" || nick = "Nick_Name")
        return false

    url := accessUrl "?nick=" UriEncode(nick)
        . "&version=" UriEncode(appVersion)
        . "&action=ai_config"
        . "&used=" aiDailyUsed
        . "&day=" FormatTime(, "yyyy-MM-dd")
    try {
        result := HttpGetTextAsync(url)
        if (result["status"] != 200)
            return false
        response := Trim(result["text"])
    } catch as err {
        LogError("FetchAiConfigFromCloud", "Сеть", err.Message)
        return false
    }

    parts := StrSplit(response, "|")
    if (parts.Length < 5 || parts[1] != "OK")
        return false

    ; Форматы (с конца: limit|used|remaining):
    ; 7+: OK|gemini|deepseek|groq|limit|used|remaining
    ; 6:  OK|gemini|deepseek|limit|used|remaining
    ; 5:  OK|gemini|limit|used|remaining
    if (parts.Length >= 7) {
        geminiApiKey := Trim(parts[2])
        deepseekApiKey := Trim(parts[3])
        groqApiKey := Trim(parts[4])
        MergeAiQuotaFromCloud(Integer(parts[5]), Integer(parts[6]), Integer(parts[7]))
    } else if (parts.Length >= 6) {
        geminiApiKey := Trim(parts[2])
        deepseekApiKey := Trim(parts[3])
        MergeAiQuotaFromCloud(Integer(parts[4]), Integer(parts[5]), Integer(parts[6]))
    } else {
        geminiApiKey := Trim(parts[2])
        MergeAiQuotaFromCloud(Integer(parts[3]), Integer(parts[4]), Integer(parts[5]))
    }
    aiConfigLoaded := true

    if (geminiModel = "" || geminiModel = "gemini-1.5-flash" || geminiModel = "gemini-2.5-flash")
        geminiModel := "gemini-3.6-flash"
    if (deepseekModel = "")
        deepseekModel := "deepseek-chat"
    if (groqModel = "")
        groqModel := "llama-3.1-8b-instant"

    try {
        IniWrite(geminiApiKey, settingsFile, "AI", "geminiApiKey")
        IniWrite(deepseekApiKey, settingsFile, "AI", "deepseekApiKey")
        IniWrite(groqApiKey, settingsFile, "AI", "groqApiKey")
        IniWrite(geminiModel, settingsFile, "AI", "geminiModel")
        IniWrite(deepseekModel, settingsFile, "AI", "deepseekModel")
        IniWrite(groqModel, settingsFile, "AI", "groqModel")
    }

    try {
        if IsObject(AiLimitCtrl)
            AiLimitCtrl.Text := GetAiLimitStatusText()
    }
    return true
}

ConsumeAiQuotaFromCloud() {
    global nick, accessUrl, aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiQuotaDate

    if (Trim(nick) = "")
        return Map("ok", false, "reason", "Нет ника")

    today := FormatTime(, "yyyyMMdd")
    ; Локальный стоп, если за сегодня лимит уже выбран
    if (aiDailyLimit > 0 && aiQuotaDate = today && aiDailyUsed >= aiDailyLimit) {
        RefreshAiLimitUi()
        return Map("ok", false, "reason", "Лимит на сегодня исчерпан (" aiDailyUsed "/" aiDailyLimit ")")
    }

    ; Перед списанием отправляем локальный used — сервер возьмёт max(sheet, client)
    url := accessUrl "?nick=" UriEncode(nick)
        . "&action=ai_use"
        . "&used=" aiDailyUsed
        . "&day=" FormatTime(, "yyyy-MM-dd")
    try {
        result := HttpGetTextAsync(url)
        if (result["status"] != 200)
            return Map("ok", false, "reason", "HTTP " result["status"])
        response := Trim(result["text"])
    } catch as err {
        return Map("ok", false, "reason", err.Message)
    }

    parts := StrSplit(response, "|")
    if (parts.Length < 4)
        return Map("ok", false, "reason", "Некорректный ответ Cloud")

    if (parts[1] = "LIMIT") {
        cloudLimit := Integer(parts[2])
        cloudUsed := Integer(parts[3])
        cloudRemaining := Integer(parts[4])
        if (cloudLimit > 0)
            aiDailyLimit := cloudLimit
        ; Если Cloud «залип» на LIMIT, но локально ещё есть запас — считаем локально
        if (aiQuotaDate = today && aiDailyLimit > 0 && aiDailyUsed < aiDailyLimit) {
            ApplySuccessfulAiUse(aiDailyLimit, aiDailyUsed + 1, aiDailyLimit - aiDailyUsed - 1)
            return Map("ok", true, "reason", "")
        }
        MergeAiQuotaFromCloud(cloudLimit, cloudUsed, cloudRemaining)
        RefreshAiLimitUi()
        return Map("ok", false, "reason", "Лимит на сегодня исчерпан (" aiDailyUsed "/" aiDailyLimit ")")
    }
    if (parts[1] != "OK")
        return Map("ok", false, "reason", response)

    ApplySuccessfulAiUse(Integer(parts[2]), Integer(parts[3]), Integer(parts[4]))
    return Map("ok", true, "reason", "")
}

GetCurrentAiApiKey() {
    global aiProvider, geminiApiKey, deepseekApiKey, groqApiKey
    if (aiProvider = "deepseek")
        return Trim(deepseekApiKey)
    if (aiProvider = "groq")
        return Trim(groqApiKey)
    return Trim(geminiApiKey)
}

GetAiProviderLabel() {
    global aiProvider
    if (aiProvider = "deepseek")
        return "DeepSeek"
    if (aiProvider = "groq")
        return "Groq"
    return "Gemini"
}

GetAiKeyCellHint() {
    global aiProvider
    if (aiProvider = "deepseek")
        return "A999"
    if (aiProvider = "groq")
        return "A998"
    return "A1000"
}

GetAiLimitStatusText() {
    global aiConfigLoaded, aiDailyLimit, aiDailyUsed, aiDailyRemaining, cloudAccessState
    if !aiConfigLoaded {
        if (cloudAccessState = "ok")
            return "Лимит: загрузка из Cloud…"
        if (cloudAccessState = "unknown")
            return "Лимит: ожидание проверки Cloud…"
        return "Лимит: Cloud не подтверждён (" GetCloudStatusText() ")"
    }
    if (GetCurrentAiApiKey() = "")
        return "Ключ " GetAiProviderLabel() " пуст (проверьте " GetAiKeyCellHint() " в таблице)"
    return GetAiProviderLabel() " · лимит сегодня: " aiDailyUsed "/" aiDailyLimit " (осталось " aiDailyRemaining ")"
}

SetAiAskButtonLoading(isLoading) {
    global AiAskBtnCtrl, colorAccent, colorCardAlt, colorText
    if !IsObject(AiAskBtnCtrl)
        return
    try {
        if (isLoading) {
            AiAskBtnCtrl.Text := "Загрузка…"
            AiAskBtnCtrl.Opt("Background" colorCardAlt)
        } else {
            AiAskBtnCtrl.Text := "Спросить"
            AiAskBtnCtrl.Opt("Background" colorAccent)
        }
    }
}

SaveAiGuiPosition() {
    global AiGui, aiGuiX, aiGuiY, settingsFile
    if !IsObject(AiGui)
        return
    try {
        AiGui.GetPos(&aiGuiX, &aiGuiY)
        TryIniWrite(aiGuiX, settingsFile, "GUI", "aiGuiX", "SaveAiGuiPosition")
        TryIniWrite(aiGuiY, settingsFile, "GUI", "aiGuiY", "SaveAiGuiPosition")
    }
}

OpenAiAssistant(*) {
    global AiGui, AiQuestionCtrl, AiAnswerCtrl, AiStatusCtrl, AiLimitCtrl, AiAskBtnCtrl, lastAiOpenTick
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, uiInputBg, uiDivider
    global aiGuiX, aiGuiY, aiConfigLoaded

    if (A_TickCount - lastAiOpenTick < 350)
        return
    lastAiOpenTick := A_TickCount

    if IsObject(AiGui) {
        try {
            if WinExist("ahk_id " AiGui.Hwnd) {
                CloseAiAssistant()
                return
            }
        }
        SafeDestroyGui(&AiGui)
        AiQuestionCtrl := ""
        AiAnswerCtrl := ""
        AiStatusCtrl := ""
        AiLimitCtrl := ""
        AiAskBtnCtrl := ""
    }

    ; Окно сразу — без ожидания сети (не блокирует бинды)
    AiGui := Gui("+AlwaysOnTop +Border -MinimizeBox", "ChesNova AI")
    AiGui.BackColor := colorBg
    AiGui.MarginX := 0
    AiGui.MarginY := 0
    AiGui.OnEvent("Close", CloseAiAssistant)
    AiGui.OnEvent("Escape", CloseAiAssistant)

    AiGui.Add("Text", "x0 y0 w460 h520 Background" colorBg)
    AiGui.SetFont("s12 Bold c" colorText, "Segoe UI")
    AiGui.Add("Text", "x18 y14 w424 h26 Background" colorBg, "AI-ассистент")
    AiGui.Add("Text", "x18 y46 w424 h1 Background" uiDivider)

    AiGui.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    AiLimitCtrl := AiGui.Add("Text", "x18 y56 w424 h20 Background" colorBg " c" colorMuted, GetAiLimitStatusText())

    AiGui.SetFont("s9 Bold c" colorText, "Segoe UI")
    AiGui.Add("Text", "x18 y84 w424 h20 Background" colorBg, "Ваш вопрос")
    AiGui.SetFont("s10 Norm c" colorText, "Segoe UI")
    AiQuestionCtrl := AiGui.Add("Edit", "x18 y108 w424 h90 +Multi +WantReturn -Wrap VScroll Background" uiInputBg " c" colorText, "")

    AiAskBtnCtrl := AiGui.Add("Text", "x18 y210 w136 h32 +0x200 Center Background" colorAccent " c" colorText, "Спросить")
    BindTextButton(AiAskBtnCtrl, colorAccent, SubmitAiQuestion)
    clearBtn := AiGui.Add("Text", "x162 y210 w136 h32 +0x200 Center Background" colorCardAlt " c" colorText, "Очистить")
    BindTextButton(clearBtn, colorCardAlt, ClearAiAssistant)
    histBtn := AiGui.Add("Text", "x306 y210 w136 h32 +0x200 Center Background" colorCardAlt " c" colorText, "История")
    BindTextButton(histBtn, colorCardAlt, ShowAiHistoryDialog)

    AiGui.SetFont("s9 Bold c" colorText, "Segoe UI")
    AiGui.Add("Text", "x18 y256 w424 h20 Background" colorBg, "Ответ")
    AiGui.SetFont("s10 Norm c" colorText, "Segoe UI")
    AiAnswerCtrl := AiGui.Add("Edit", "x18 y280 w424 h170 +Multi +ReadOnly Wrap +VScroll Background" colorCard " c" colorText, "")

    AiGui.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    AiStatusCtrl := AiGui.Add("Text", "x18 y462 w424 h40 Background" colorBg " c" colorMuted, "Ключ и лимит — из Google-таблицы по нику.")

    showOpts := "w460 h520"
    if (aiGuiX = "Center" || aiGuiY = "Center" || aiGuiX = "" || aiGuiY = "")
        showOpts .= " xCenter yCenter"
    else
        showOpts .= " x" aiGuiX " y" aiGuiY
    AiGui.Show(showOpts)

    try {
        WinActivate(AiGui.Hwnd)
        AiQuestionCtrl.Focus()
    }

    if !aiConfigLoaded {
        if IsObject(AiLimitCtrl)
            AiLimitCtrl.Text := "Лимит: загрузка из Cloud…"
        if IsObject(AiStatusCtrl)
            AiStatusCtrl.Text := "Подключение к Cloud, загрузка ключа и лимита…"
    }
    SetTimer(RefreshAiConfigAfterOpen, -50)
}

RefreshAiConfigAfterOpen(*) {
    global AiLimitCtrl, AiStatusCtrl, aiProvider, colorGreen, colorRed
    ok := FetchAiConfigFromCloud()
    if IsObject(AiLimitCtrl)
        AiLimitCtrl.Text := GetAiLimitStatusText()
    if !IsObject(AiStatusCtrl)
        return
    if ok && (GetCurrentAiApiKey() != "") {
        AiStatusCtrl.Text := "Готово (" GetAiProviderLabel() "). Можно задавать вопрос."
        AiStatusCtrl.SetFont("s9 Norm c" colorGreen, "Segoe UI")
    } else if ok {
        AiStatusCtrl.Text := "Конфиг получен, но ключ " GetAiProviderLabel() " пуст (проверьте " GetAiKeyCellHint() ")."
        AiStatusCtrl.SetFont("s9 Norm c" colorRed, "Segoe UI")
    } else {
        AiStatusCtrl.Text := "Не удалось загрузить AI-конфиг. Проверьте Cloud и ник."
        AiStatusCtrl.SetFont("s9 Norm c" colorRed, "Segoe UI")
    }
}

SubmitAiQuestion(*) {
    global AiQuestionCtrl, AiAnswerCtrl, AiStatusCtrl, AiLimitCtrl, aiRequestBusy
    global geminiApiKey, aiProvider, colorAccent, colorYellow, colorRed, colorMuted, colorGreen

    if !IsObject(AiQuestionCtrl) || aiRequestBusy
        return

    question := Trim(AiQuestionCtrl.Value)
    if (question = "") {
        if IsObject(AiStatusCtrl) {
            AiStatusCtrl.Text := "Введите вопрос, затем нажмите «Спросить»."
            AiStatusCtrl.SetFont("s9 Norm c" colorYellow, "Segoe UI")
        }
        return
    }

    aiRequestBusy := true
    SetAiAskButtonLoading(true)
    if IsObject(AiAnswerCtrl)
        AiAnswerCtrl.Value := "Загрузка ответа…"
    if IsObject(AiStatusCtrl) {
        AiStatusCtrl.Text := "Ожидание ответа Gemini…"
        AiStatusCtrl.SetFont("s9 Norm c" colorAccent, "Segoe UI")
    }

    ; Не блокируем UI полностью: async HTTP с Sleep внутри
    if (GetCurrentAiApiKey() = "")
        FetchAiConfigFromCloud()

    if (GetCurrentAiApiKey() = "") {
        if IsObject(AiAnswerCtrl)
            AiAnswerCtrl.Value := ""
        if IsObject(AiStatusCtrl) {
            AiStatusCtrl.Text := "Ключ " GetAiProviderLabel() " пуст. Проверьте " GetAiKeyCellHint() " и доступ ника."
            AiStatusCtrl.SetFont("s9 Norm c" colorRed, "Segoe UI")
        }
        SetAiAskButtonLoading(false)
        aiRequestBusy := false
        return
    }

    quota := ConsumeAiQuotaFromCloud()
    if IsObject(AiLimitCtrl)
        AiLimitCtrl.Text := GetAiLimitStatusText()

    if !quota["ok"] {
        if IsObject(AiAnswerCtrl)
            AiAnswerCtrl.Value := ""
        if IsObject(AiStatusCtrl) {
            AiStatusCtrl.Text := quota["reason"]
            AiStatusCtrl.SetFont("s9 Norm c" colorRed, "Segoe UI")
        }
        SetAiAskButtonLoading(false)
        aiRequestBusy := false
        return
    }

    try {
        if IsObject(AiStatusCtrl) {
            AiStatusCtrl.Text := "Ожидание ответа " GetAiProviderLabel() "…"
            AiStatusCtrl.SetFont("s9 Norm c" colorAccent, "Segoe UI")
        }
        answer := AskAI(question)
        PushAiHistory(question, answer)
        if IsObject(AiAnswerCtrl)
            AiAnswerCtrl.Value := answer
        if IsObject(AiStatusCtrl) {
            AiStatusCtrl.Text := "Ответ получен (" GetAiProviderLabel() ")."
            AiStatusCtrl.SetFont("s9 Norm c" colorGreen, "Segoe UI")
        }
        if IsObject(AiLimitCtrl)
            AiLimitCtrl.Text := GetAiLimitStatusText()
        try RefreshAiHistoryPanel()
    } catch as err {
        LogError("SubmitAiQuestion", GetAiProviderLabel(), err.Message)
        if IsObject(AiAnswerCtrl)
            AiAnswerCtrl.Value := "Ошибка: " err.Message
        if IsObject(AiStatusCtrl) {
            AiStatusCtrl.Text := "Не удалось получить ответ."
            AiStatusCtrl.SetFont("s9 Norm c" colorRed, "Segoe UI")
        }
    }

    SetAiAskButtonLoading(false)
    aiRequestBusy := false
}

ClearAiAssistant(*) {
    global AiQuestionCtrl, AiAnswerCtrl, AiStatusCtrl, colorMuted, aiRequestBusy
    if aiRequestBusy
        return
    if IsObject(AiQuestionCtrl)
        AiQuestionCtrl.Value := ""
    if IsObject(AiAnswerCtrl)
        AiAnswerCtrl.Value := ""
    if IsObject(AiStatusCtrl) {
        AiStatusCtrl.Text := "Поле очищено."
        AiStatusCtrl.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    }
    try {
        if IsObject(AiQuestionCtrl)
            AiQuestionCtrl.Focus()
    }
}

CloseAiAssistant(*) {
    global AiGui, AiQuestionCtrl, AiAnswerCtrl, AiStatusCtrl, AiLimitCtrl, AiAskBtnCtrl, aiRequestBusy
    SaveAiGuiPosition()
    aiRequestBusy := false
    SafeDestroyGui(&AiGui)
    AiQuestionCtrl := ""
    AiAnswerCtrl := ""
    AiStatusCtrl := ""
    AiLimitCtrl := ""
    AiAskBtnCtrl := ""
}

RefreshAiHistoryPanel() {
    ; no-op: история в отдельном диалоге
}

ShowAiHistoryDialog(*) {
    global colorBg, colorCard, colorAccent, colorText, colorMuted
    report := BuildAiHistoryText()
    dlg := Gui("+Border", "История AI")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")
    dlg.Add("Text", "x0 y0 w520 h440 Background" colorBg)
    dlg.Add("Text", "x18 y18 w484 h50 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x34 y28 w400 h24 Background" colorCard, "История вопросов")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x34 y52 w400 h18 Background" colorCard, "Последние ответы (новые сверху)")
    dlg.SetFont("s9 Norm c" colorText, "Segoe UI")
    dlg.Add("Edit", "x18 y80 w484 h300 +Multi +ReadOnly -Wrap +VScroll Background" colorCard " c" colorText, report)
    closeBtn := dlg.Add("Text", "x382 y392 w120 h30 +0x200 Center Background" colorAccent " c" colorText, "Закрыть")
    BindTextButton(closeBtn, colorAccent, (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())
    dlg.Show("w520 h440")
    try WinActivate(dlg.Hwnd)
}

GetAiSystemPrompt() {
    return "Ты помощник администратора игрового сервера (CRMP / SA-MP). Отвечай кратко, по делу, на русском. Обычный текст без markdown, без HTML, без JSON-экранирования (не пиши \\u003e и подобное). Для цитат используй символ >. Помогай с формулировками наказаний, ответами на репорты и шаблонами. Не выдумывай внутренние правила сервера, если их не указали."
}

JsonEscape(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`r`n", "\n")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}

ExtractGeminiText(responseText) {
    if RegExMatch(responseText, '"text"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        return GeminiUnescape(m[1])
    if RegExMatch(responseText, '"message"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        return "API: " GeminiUnescape(m[1])
    return "Не удалось разобрать ответ API.`n" SubStr(responseText, 1, 400)
}

GeminiUnescape(str) {
    ; \uXXXX (например \u003e -> >)
    while RegExMatch(str, "\\u([0-9a-fA-F]{4})", &um) {
        code := Integer("0x" um[1])
        str := StrReplace(str, um[0], Chr(code))
    }
    str := StrReplace(str, "\n", "`n")
    str := StrReplace(str, "\r", "`r")
    str := StrReplace(str, "\t", "`t")
    str := StrReplace(str, '\"', '"')
    str := StrReplace(str, "\\/", "/")
    str := StrReplace(str, "\\\\", "\")
    return str
}

; Async HTTP без readyState (у WinHttpRequest в AHK v2 его нет).
; Ждём ответ кусками через WaitForResponse(0) + Sleep — таймеры/бинды живут.
HttpWaitAsync(http, timeoutMs := 60000) {
    deadline := A_TickCount + timeoutMs
    loop {
        try {
            ; 0 = проверить без долгого ожидания; true = ответ уже есть
            if http.WaitForResponse(0)
                return
        } catch {
            ; ещё не готов / временная ошибка COM
        }
        if (A_TickCount >= deadline)
            throw Error("HTTP timeout (" timeoutMs " ms)")
        Sleep(15)
    }
}

; Читает тело ответа WinHttp строго как UTF-8 (иначе кириллица от Groq/DeepSeek → кракозябры).
HttpResponseTextUtf8(http) {
    try {
        stream := ComObject("ADODB.Stream")
        stream.Type := 1  ; adTypeBinary
        stream.Open()
        stream.Write(http.ResponseBody)
        stream.Position := 0
        stream.Type := 2  ; adTypeText
        stream.Charset := "UTF-8"
        text := stream.ReadText()
        stream.Close()
        return Trim(text)
    } catch {
        try
            return Trim(http.ResponseText)
        catch
            return ""
    }
}

HttpGetTextAsync(url, resolveMs := 15000, connectMs := 15000, sendMs := 30000, receiveMs := 45000) {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, true)
    try http.SetTimeouts(resolveMs, connectMs, sendMs, receiveMs)
    http.SetRequestHeader("Cache-Control", "no-cache")
    http.SetRequestHeader("Pragma", "no-cache")
    http.Send()
    HttpWaitAsync(http, resolveMs + connectMs + sendMs + receiveMs + 5000)
    return Map("status", http.Status, "text", HttpResponseTextUtf8(http))
}

; authMode: "google" → x-goog-api-key, "bearer" → Authorization: Bearer
HttpPostJson(url, jsonBody, apiKey := "", authMode := "google", resolveMs := 15000, connectMs := 15000, sendMs := 30000, receiveMs := 60000) {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", url, true)
    try http.SetTimeouts(resolveMs, connectMs, sendMs, receiveMs)
    http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    http.SetRequestHeader("Accept", "application/json")
    http.SetRequestHeader("Cache-Control", "no-cache")
    if (apiKey != "") {
        if (authMode = "bearer")
            http.SetRequestHeader("Authorization", "Bearer " apiKey)
        else
            http.SetRequestHeader("x-goog-api-key", apiKey)
    }
    http.Send(jsonBody)
    HttpWaitAsync(http, resolveMs + connectMs + sendMs + receiveMs + 5000)
    return Map("status", http.Status, "text", HttpResponseTextUtf8(http))
}



RegisterAiChatHotstring() {
    global aiChatHotstringRegistered, aiKeyEnabled
    if aiChatHotstringRegistered {
        try Hotstring(":*?B0X:/ai ", "Off")
        try Hotstring(":*?B0X:/AI ", "Off")
        aiChatHotstringRegistered := false
    }
    if !aiKeyEnabled
        return
    try {
        Hotstring(":*?B0X:/ai ", OnAiChatPrefix)
        Hotstring(":*?B0X:/AI ", OnAiChatPrefix)
        aiChatHotstringRegistered := true
    } catch as err {
        LogError("RegisterAiChatHotstring", "Не удалось зарегистрировать /ai", err.Message)
    }
}

OnAiChatPrefix(*) {
    SetTimer(CaptureAiChatQuestion, -1)
}

CaptureAiChatQuestion(*) {
    global aiChatCaptureBusy, aiRequestBusy
    if aiChatCaptureBusy || aiRequestBusy
        return
    aiChatCaptureBusy := true
    try {
        ih := InputHook("V L400", "{Enter}{Esc}")
        ih.Start()
        ih.Wait()
        if (ih.EndReason != "EndKey" || ih.EndKey = "Escape")
            return
        question := Trim(ih.Input)
        if (StrLen(question) < 2)
            return
        q := question
        SetTimer(() => RunAiFromGameChat(q), -80)
    } catch as err {
        LogError("CaptureAiChatQuestion", "Ошибка захвата вопроса", err.Message)
    } finally {
        aiChatCaptureBusy := false
    }
}

RunAiFromGameChat(question) {
    global aiRequestBusy, aiProvider
    question := Trim(question)
    if (question = "" || aiRequestBusy)
        return

    ; Только in-game UI (ches.js): без компактного окна AHK
    PushAiThinkingToGameHud(question)
    aiRequestBusy := true
    try {
        if (GetCurrentAiApiKey() = "")
            FetchAiConfigFromCloud()
        if (GetCurrentAiApiKey() = "") {
            msg := "Ключ " GetAiProviderLabel() " пуст. Проверьте Cloud / " GetAiKeyCellHint() " в таблице."
            PushAiToGameHud(question, msg, true)
            return
        }
        quota := ConsumeAiQuotaFromCloud()
        if !quota["ok"] {
            PushAiToGameHud(question, quota["reason"], true)
            return
        }
        answer := AskAI(question)
        PushAiHistory(question, answer)
        PushAiToGameHud(question, answer, false, 10000)
        ShowToast("✓ AI ответил (" GetAiProviderLabel() ")", 1400)
    } catch as err {
        LogError("RunAiFromGameChat", GetAiProviderLabel(), err.Message)
        PushAiToGameHud(question, "Ошибка: " err.Message, true)
    } finally {
        aiRequestBusy := false
    }
}

AskAI(question) {
    global aiProvider
    if (aiProvider = "deepseek")
        return AskDeepSeek(question)
    if (aiProvider = "groq")
        return AskGroq(question)
    return AskGemini(question)
}

AskGemini(question) {
    global geminiApiKey, geminiModel

    model := Trim(geminiModel)
    if (model = "" || model = "gemini-1.5-flash" || model = "gemini-2.5-flash")
        model := "gemini-3.6-flash"

    url := "https://generativelanguage.googleapis.com/v1beta/models/" model ":generateContent"
    body := "{"
    body .= '"systemInstruction":{"parts":[{"text":"' JsonEscape(GetAiSystemPrompt()) '"}]},'
    body .= '"contents":[{"role":"user","parts":[{"text":"' JsonEscape(question) '"}]}],'
    body .= '"generationConfig":{"maxOutputTokens":1024}'
    body .= "}"

    result := HttpPostJson(url, body, geminiApiKey, "google")
    if (result["status"] != 200)
        throw Error("HTTP " result["status"] "`n" SubStr(result["text"], 1, 400))

    textOut := ExtractGeminiText(result["text"])
    if (Trim(textOut) = "")
        throw Error("Пустой ответ от модели.")
    return textOut
}

AskDeepSeek(question) {
    global deepseekApiKey, deepseekModel

    model := Trim(deepseekModel)
    if (model = "")
        model := "deepseek-chat"

    url := "https://api.deepseek.com/chat/completions"
    body := "{"
    body .= '"model":"' JsonEscape(model) '",'
    body .= '"messages":['
    body .= '{"role":"system","content":"' JsonEscape(GetAiSystemPrompt()) '"},'
    body .= '{"role":"user","content":"' JsonEscape(question) '"}'
    body .= '],'
    body .= '"max_tokens":1024,'
    body .= '"stream":false'
    body .= "}"

    result := HttpPostJson(url, body, deepseekApiKey, "bearer")
    if (result["status"] != 200)
        throw Error("HTTP " result["status"] "`n" SubStr(result["text"], 1, 400))

    textOut := ExtractOpenAiText(result["text"])
    if (Trim(textOut) = "")
        throw Error("Пустой ответ от DeepSeek.")
    return textOut
}

AskGroq(question) {
    global groqApiKey, groqModel

    model := Trim(groqModel)
    if (model = "")
        model := "llama-3.1-8b-instant"

    url := "https://api.groq.com/openai/v1/chat/completions"
    body := "{"
    body .= '"model":"' JsonEscape(model) '",'
    body .= '"messages":['
    body .= '{"role":"system","content":"' JsonEscape(GetAiSystemPrompt()) '"},'
    body .= '{"role":"user","content":"' JsonEscape(question) '"}'
    body .= '],'
    body .= '"max_tokens":1024,'
    body .= '"stream":false'
    body .= "}"

    result := HttpPostJson(url, body, groqApiKey, "bearer")
    if (result["status"] != 200)
        throw Error("HTTP " result["status"] "`n" SubStr(result["text"], 1, 400))

    textOut := ExtractOpenAiText(result["text"])
    if (Trim(textOut) = "")
        throw Error("Пустой ответ от Groq.")
    return textOut
}

ExtractOpenAiText(responseText) {
    ; OpenAI-совместимый ответ: choices[0].message.content
    if RegExMatch(responseText, '"content"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        return GeminiUnescape(m[1])
    if RegExMatch(responseText, '"message"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        return "API: " GeminiUnescape(m[1])
    if RegExMatch(responseText, '"error"\s*:\s*\{[^}]*"message"\s*:\s*"((?:\\.|[^"\\])*)"', &m)
        return "API: " GeminiUnescape(m[1])
    return "Не удалось разобрать ответ API.`n" SubStr(responseText, 1, 400)
}

RegisterHotkeys() {
    global menuKey, resetKey, aiKey, menuKeyEnabled, resetKeyEnabled, aiKeyEnabled, RegisteredStandardHotkeys

    for _, key in RegisteredStandardHotkeys {
        try Hotkey(key, "Off")
    }
    RegisteredStandardHotkeys := []

    if menuKeyEnabled {
        Hotkey(menuKey, OpenMenu, "On")
        RegisteredStandardHotkeys.Push(menuKey)
    }
    if resetKeyEnabled {
        Hotkey(resetKey, ResetPM, "On")
        RegisteredStandardHotkeys.Push(resetKey)
    }
    if aiKeyEnabled {
        Hotkey(aiKey, OpenAiAssistant, "On")
        RegisteredStandardHotkeys.Push(aiKey)
    }
    RegisterAiChatHotstring()
    try RebuildTrayMenu()
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global MainGui, SettingsGui

    if IsObject(MainGui) && (hwnd = MainGui.Hwnd || DllCall("IsChild", "Ptr", MainGui.Hwnd, "Ptr", hwnd, "Int")) {
        DragGuiWindow(MainGui.Hwnd)
        return
    }

    if IsObject(SettingsGui) && (hwnd = SettingsGui.Hwnd || DllCall("IsChild", "Ptr", SettingsGui.Hwnd, "Ptr", hwnd, "Int")) {
        MouseGetPos(&mouseX, &mouseY)
        SettingsGui.GetPos(&winX, &winY)
        relX := mouseX - winX
        relY := mouseY - winY
        if (relY >= 0 && relY <= 70 && relX < 780)
            DragGuiWindow(SettingsGui.Hwnd)
        return
    }
}

WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    global MainGui, SettingsGui

    if IsObject(MainGui) && (hwnd = MainGui.Hwnd)
        return 2

    if IsObject(SettingsGui) && (hwnd = SettingsGui.Hwnd) {
        mouseX := lParam & 0xFFFF
        if (mouseX & 0x8000)
            mouseX -= 0x10000
        mouseY := (lParam >> 16) & 0xFFFF
        if (mouseY & 0x8000)
            mouseY -= 0x10000
        SettingsGui.GetPos(&winX, &winY)
        relX := mouseX - winX
        relY := mouseY - winY
        if (relY >= 0 && relY <= 70 && relX < 780)
            return 2
    }

}

DragGuiWindow(guiHwnd) {
    DllCall("ReleaseCapture")
    DllCall("SendMessage", "Ptr", guiHwnd, "UInt", 0xA1, "Ptr", 2, "Ptr", 0)
}

SortRecordsNewestFirst(lines, recordType) {
    sorted := []

    for _, line in lines {
        lineKey := GetRecordSortKey(line, recordType)
        inserted := false

        Loop sorted.Length {
            currentKey := GetRecordSortKey(sorted[A_Index], recordType)
            if (lineKey >= currentKey) {
                sorted.InsertAt(A_Index, line)
                inserted := true
                break
            }
        }

        if (!inserted)
            sorted.Push(line)
    }

    return sorted
}

GetRecordSortKey(line, recordType) {
    if (recordType = "dayoff") {
        record := ParseDayOffRecord(line)
        date := IsObject(record) ? StrReplace(record["date"], "-", "") : ""
        return date "000000"
    }

    if (recordType = "history") {
        part := StrSplit(line, ",")
        date := GetArrayValue(part, 1, "")
        date := StrReplace(date, "-", "")
        return date "000000"
    }

    part := StrSplit(line, "|")
    date := GetArrayValue(part, 1, "")
    time := GetArrayValue(part, 2, "")
    return DmyTimeToSortKey(date, time)
}

DmyTimeToSortKey(date, time) {
    datePart := StrSplit(date, ".")
    if (datePart.Length < 3)
        dateKey := "00000000"
    else
        dateKey := Format("{:04}{:02}{:02}", datePart[3] + 0, datePart[2] + 0, datePart[1] + 0)

    timeKey := RegExReplace(time, "\D")
    if (StrLen(timeKey) < 6)
        timeKey := SubStr(timeKey "000000", 1, 6)

    return dateKey timeKey
}

GetArrayValue(arr, index, defaultValue := "") {
    if (arr.Length >= index)
        return arr[index]
    return defaultValue
}

JoinArrayFrom(arr, startIndex, delimiter := "|") {
    value := ""

    Loop arr.Length {
        if (A_Index < startIndex)
            continue
        if (value != "")
            value .= delimiter
        value .= arr[A_Index]
    }

    return value
}

LogError(source, message, extra := "") {
    global errorsLogFile, logPath

    try {
        DirCreate(logPath)
        RotateErrorsLogIfNeeded()
        entry := "[" FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "] [" source "]`n" message
        if (extra != "")
            entry .= "`n" extra
        entry .= "`n`n"
        FileAppend(entry, errorsLogFile, "UTF-8")
    } catch {
        ; Логгер не должен вызывать сам себя при ошибке записи errors.log.
    }
}

RotateErrorsLogIfNeeded() {
    global errorsLogFile, backupPath, maxErrorLogBytes

    try {
        if !FileExist(errorsLogFile) || FileGetSize(errorsLogFile) < maxErrorLogBytes
            return

        DirCreate(backupPath)
        archiveFile := backupPath "\\errors_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".log"
        FileMove(errorsLogFile, archiveFile, 0)
    }
}

ArchiveDataFileIfNeeded(filePath, archiveLabel) {
    global backupPath, maxHistoryFileBytes, historyKeepRecords

    try {
        if !FileExist(filePath) || FileGetSize(filePath) < maxHistoryFileBytes
            return

        lines := ReadFileLines(filePath, "ArchiveDataFileIfNeeded")
        if (lines.Length <= historyKeepRecords)
            return

        archiveCount := lines.Length - historyKeepRecords
        DirCreate(backupPath)
        archiveFile := backupPath "\\" archiveLabel "_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".csv"

        archive := FileOpen(archiveFile, "w")
        Loop archiveCount
            archive.Write(lines[A_Index] "`n")
        archive.Close()

        active := FileOpen(filePath, "w")
        Loop historyKeepRecords
            active.Write(lines[archiveCount + A_Index] "`n")
        active.Close()
    }
}

TryFileAppend(text, filePath, source, message) {
    try {
        FileAppend(text, filePath)
        return true
    } catch as err {
        LogError(source, message ": " filePath, err.Message)
        return false
    }
}

TryFileDelete(filePath, source, message) {
    if !FileExist(filePath)
        return true

    try {
        FileDelete(filePath)
        return true
    } catch as err {
        LogError(source, message ": " filePath, err.Message)
        return false
    }
}

TryIniWrite(value, filePath, section, key, source) {
    try {
        IniWrite(value, filePath, section, key)
        return true
    } catch as err {
        LogError(source, "Ошибка записи settings.ini [" section "] " key, err.Message)
        return false
    }
}

GetLastErrorLogLines(maxLines := 20) {
    global errorsLogFile

    if !FileExist(errorsLogFile)
        return "Лог ошибок пуст."

    try {
        lines := []
        file := FileOpen(errorsLogFile, "r", "UTF-8")
        while (!file.AtEOF) {
            line := RTrim(file.ReadLine(), "`r`n")
            lines.Push(line)
        }
        file.Close()
    } catch {
        return "Не удалось прочитать errors.log."
    }

    total := lines.Length
    if (total = 0)
        return "Лог ошибок пуст."

    startIndex := Max(1, total - maxLines + 1)
    text := ""
    Loop total - startIndex + 1
        text .= lines[startIndex + A_Index - 1] "`n"
    return RTrim(text, "`n")
}

RefreshErrorsLogView(*) {
    global ErrorsLogTextCtrl

    if IsObject(ErrorsLogTextCtrl)
        ErrorsLogTextCtrl.Value := GetLastErrorLogLines()
}

OpenErrorsLogFile(*) {
    global errorsLogFile

    try {
        if !FileExist(errorsLogFile)
            FileAppend("", errorsLogFile, "UTF-8")
        Run(errorsLogFile)
    } catch as err {
        LogError("OpenErrorsLogFile", "Не удалось открыть errors.log", err.Message)
        ShowToast("⚠ Не удалось открыть errors.log", 2200)
    }
}

ClearErrorsLog(*) {
    global errorsLogFile

    result := ShowAppDialog("Подтверждение очистки", "Очистить errors.log?", "OKCancel")
    if (result != "OK")
        return

    try {
        file := FileOpen(errorsLogFile, "w", "UTF-8")
        file.Close()
    } catch as err {
        LogError("ClearErrorsLog", "Не удалось очистить errors.log", err.Message)
        ShowToast("⚠ Не удалось очистить errors.log", 2200)
        return
    }

    RefreshErrorsLogView()
}


; ------------------------------------------------------------
; 09. Unified mini windows and dialogs
; ------------------------------------------------------------

AppDialogResult := ""
NickInputResult := ""
NickInputValue := ""
NickInputEditCtrl := ""

ShowAppDialog(title, message, buttons := "OK", accentColor := "") {
    global AppDialogResult, colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorRed

    if (accentColor = "")
        accentColor := colorAccent

    ; Высота под текст: длинные сообщения больше не обрезаются.
    lineBreak := Chr(10)
    normalized := StrReplace(StrReplace(message, "`r`n", lineBreak), "`r", lineBreak)
    lineCount := 1
    Loop Parse, normalized, lineBreak
        lineCount := A_Index
    approxWrapped := 0
    Loop Parse, normalized, lineBreak {
        lineLen := StrLen(A_LoopField)
        approxWrapped += Max(1, Ceil(lineLen / 42))
    }
    textLines := Max(lineCount, approxWrapped)
    textHeight := Min(220, Max(64, textLines * 16))
    cardHeight := 58 + textHeight
    dlgHeight := cardHeight + 72
    buttonY := dlgHeight - 40

    AppDialogResult := ""
    ; Обычное окно с заголовком (как редактор биндов): видно на панели задач, не AlwaysOnTop.
    dlg := Gui("+Border", title)
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")

    dlg.Add("Text", "x0 y0 w420 h" dlgHeight " Background" colorBg)
    dlg.Add("Text", "x18 y18 w384 h" cardHeight " Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y32 w330 h24 Background" colorCard, title)
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y66 w345 h" textHeight " Background" colorCard, message)

    if (buttons = "OKCancel") {
        AddDialogTextButton(dlg, 176, buttonY, 104, 28, "Отмена", colorCardAlt, "Cancel")
        AddDialogTextButton(dlg, 292, buttonY, 104, 28, "OK", accentColor, "OK")
    } else if (buttons = "YesNo") {
        AddDialogTextButton(dlg, 176, buttonY, 104, 28, "Нет", colorCardAlt, "No")
        AddDialogTextButton(dlg, 292, buttonY, 104, 28, "Да", colorRed, "Yes")
    } else {
        AddDialogTextButton(dlg, 292, buttonY, 104, 28, "OK", accentColor, "OK")
    }

    dlg.OnEvent("Close", (*) => CloseAppDialog(dlg, "Cancel"))
    dlg.Show("w420 h" dlgHeight)
    try WinActivate(dlg.Hwnd)
    WinWaitClose("ahk_id " dlg.Hwnd)
    return AppDialogResult
}

AddDialogTextButton(dlg, x, y, w, h, label, bgColor, result) {
    global colorText, colorAccent
    dlg.SetFont("s9 Bold c" colorText, "Segoe UI")
    ctrl := dlg.Add("Text", "x" x " y" y " w" w " h" h " +0x200 Center Background" bgColor, label)
    ctrl.OnEvent("Click", (*) => (FlashControl(ctrl, bgColor), CloseAppDialog(dlg, result)))
    return ctrl
}

CloseAppDialog(dlg, result) {
    global AppDialogResult
    AppDialogResult := result
    try dlg.Destroy()
}

AddMiniWindowButton(guiObj, x, y, w, h, label, bgColor, callback) {
    global colorText
    guiObj.SetFont("s9 Bold c" colorText, "Segoe UI")
    ctrl := guiObj.Add("Text", "x" x " y" y " w" w " h" h " +0x200 Center Background" bgColor, label)
    ctrl.OnEvent("Click", (*) => (FlashControl(ctrl, bgColor), callback()))
    return ctrl
}

; Короткая вспышка фона — видно, что клик принят.
FlashControl(ctrl, normalBg := "", flashBg := "", ms := 140) {
    global colorAccent
    if !IsObject(ctrl)
        return
    if (flashBg = "")
        flashBg := (normalBg = colorAccent) ? "8B83FF" : colorAccent
    try {
        ctrl.Opt("Background" flashBg)
        restoreBg := normalBg
        restoreCtrl := ctrl
        SetTimer(() => RestoreControlBackground(restoreCtrl, restoreBg), -ms)
    }
}

RestoreControlBackground(ctrl, normalBg) {
    if !IsObject(ctrl) || (normalBg = "")
        return
    try ctrl.Opt("Background" normalBg)
}

; Ненавязчивое уведомление об успехе (не модальное, само закрывается).
ShowToast(message, durationMs := 1600) {
    global ToastGui, colorBg, colorCard, colorAccent, colorText

    SafeDestroyGui(&ToastGui)
    ToastGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "ChesNovaToast")
    ToastGui.BackColor := colorBg
    ToastGui.MarginX := 0
    ToastGui.MarginY := 0
    ToastGui.SetFont("s9 Bold c" colorText, "Segoe UI")
    ToastGui.Add("Text", "x0 y0 w320 h44 Background" colorCard)
    ToastGui.Add("Text", "x0 y0 w4 h44 Background" colorAccent)
    ToastGui.Add("Text", "x16 y12 w290 h22 Background" colorCard " c" colorText, message)
    ToastGui.Show("w320 h44 xCenter y80 NA")
    SetTimer(CloseToastGui, -durationMs)
}

CloseToastGui(*) {
    global ToastGui
    SafeDestroyGui(&ToastGui)
}

; Обёртка клика для Text-кнопок в главном меню: вспышка + действие.
BindTextButton(ctrl, normalBg, callback) {
    ctrl.OnEvent("Click", (*) => (FlashControl(ctrl, normalBg), callback()))
    return ctrl
}

ShowBindCategoryInputDialog(defaultValue := "") {
    global BindCategoryInputResult, BindCategoryInputValue, BindCategoryInputCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    BindCategoryInputResult := ""
    BindCategoryInputValue := ""

    dlg := Gui("+Border", "Категория биндов")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")

    dlg.Add("Text", "x0 y0 w420 h218 Background" colorBg)
    dlg.Add("Text", "x18 y18 w384 h136 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y32 w280 h26 Background" colorCard, "Новая категория")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y70 w344 h22 Background" colorCard, "Название категории")
    BindCategoryInputCtrl := dlg.Add("Edit", "x38 y98 w344 h26 c" colorText " Background" uiInputBg, defaultValue)

    AddMiniWindowButton(dlg, 178, 172, 104, 28, "Отмена", colorCardAlt, (*) => CloseBindCategoryInputDialog(dlg, "Cancel"))
    AddMiniWindowButton(dlg, 294, 172, 108, 28, "Добавить", colorAccent, (*) => CloseBindCategoryInputDialog(dlg, "OK"))

    dlg.OnEvent("Close", (*) => CloseBindCategoryInputDialog(dlg, "Cancel"))
    dlg.OnEvent("Escape", (*) => CloseBindCategoryInputDialog(dlg, "Cancel"))

    BindCategoryInputValue := defaultValue
    dlg.Show("w420 h218")
    try BindCategoryInputCtrl.Focus()
    WinWaitClose("ahk_id " dlg.Hwnd)

    return {Result: BindCategoryInputResult, Value: BindCategoryInputValue}
}

CloseBindCategoryInputDialog(dlg, result) {
    global BindCategoryInputResult, BindCategoryInputValue, BindCategoryInputCtrl

    BindCategoryInputResult := result
    if IsObject(BindCategoryInputCtrl)
        BindCategoryInputValue := BindCategoryInputCtrl.Value
    try dlg.Destroy()
}

ShowNickInputDialog(message, defaultValue := "") {
    global NickInputResult, NickInputValue, NickInputEditCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    NickInputResult := ""
    NickInputValue := ""

    dlg := Gui("+Border", "ChesNova Cloud")
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")

    dlg.Add("Text", "x0 y0 w460 h244 Background" colorBg)
    dlg.Add("Text", "x24 y24 w412 h158 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x48 y40 w364 h26 Background" colorCard, "Cloud доступ")
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x48 y78 w364 h38 Background" colorCard, message)
    dlg.Add("Text", "x48 y130 w180 h20 Background" colorCard " c" colorMuted, "Ник администратора")
    NickInputEditCtrl := dlg.Add("Edit", "x48 y152 w364 h26 c" colorText " Background" uiInputBg, defaultValue)

    dlg.SetFont("s9 Bold c" colorText, "Segoe UI")
    cancelBtn := dlg.Add("Text", "x226 y198 w90 h30 +0x200 Center Background" colorCardAlt, "Отмена")
    BindTextButton(cancelBtn, colorCardAlt, (*) => CloseNickInputDialog(dlg, "Cancel"))
    okBtn := dlg.Add("Text", "x328 y198 w84 h30 +0x200 Center Background" colorAccent, "OK")
    BindTextButton(okBtn, colorAccent, (*) => CloseNickInputDialog(dlg, "OK"))

    dlg.OnEvent("Close", (*) => CloseNickInputDialog(dlg, "Cancel"))
    dlg.OnEvent("Escape", (*) => CloseNickInputDialog(dlg, "Cancel"))

    NickInputValue := defaultValue
    dlg.Show("w460 h244")
    try NickInputEditCtrl.Focus()
    WinWaitClose("ahk_id " dlg.Hwnd)

    return {Result: NickInputResult, Value: NickInputValue}
}

CloseNickInputDialog(dlg, result) {
    global NickInputResult, NickInputValue, NickInputEditCtrl

    NickInputResult := result
    if IsObject(NickInputEditCtrl)
        NickInputValue := NickInputEditCtrl.Value
    try dlg.Destroy()
}

SafeDestroyGui(&guiObj) {
    if IsObject(guiObj) {
        try guiObj.Destroy()
    }
    guiObj := ""
}

SafeFileRead(filePath, source := "SafeFileRead") {
    try
        return FileRead(filePath)
    catch as err {
        LogError(source, "Ошибка чтения файла: " filePath, err.Message)
        return ""
    }
}

ReadFileLines(filePath, source := "ReadFileLines") {
    lines := []
    if !FileExist(filePath)
        return lines

    try file := FileOpen(filePath, "r")
    catch as err {
        LogError(source, "Ошибка открытия файла: " filePath, err.Message)
        return lines
    }

    while (!file.AtEOF) {
        line := file.ReadLine()
        line := RTrim(line, "`r`n")
        lines.Push(line)
    }
    file.Close()
    return lines
}

ReadRecentLines(filePath, limit, source := "ReadRecentLines") {
    lines := []
    if !FileExist(filePath)
        return lines

    try file := FileOpen(filePath, "r")
    catch as err {
        LogError(source, "Не удалось открыть файл: " filePath, err.Message)
        return lines
    }

    try {
        while (!file.AtEOF) {
            line := RTrim(file.ReadLine(), "`r`n")
            lines.Push(line)
            if (lines.Length > limit)
                lines.RemoveAt(1)
        }
        file.Close()
    } catch as err {
        try file.Close()
        LogError(source, "Не удалось прочитать файл: " filePath, err.Message)
    }

    return lines
}

ReadRecentMatchingLines(filePath, limit, search := "", source := "ReadRecentMatchingLines") {
    lines := []
    if !FileExist(filePath)
        return lines

    try file := FileOpen(filePath, "r")
    catch as err {
        LogError(source, "Не удалось открыть файл: " filePath, err.Message)
        return lines
    }

    try {
        while (!file.AtEOF) {
            line := RTrim(file.ReadLine(), "`r`n")
            if (Trim(line) = "" || (search != "" && !InStr(line, search, false)))
                continue
            lines.Push(line)
            if (lines.Length > limit)
                lines.RemoveAt(1)
        }
        file.Close()
    } catch as err {
        try file.Close()
        LogError(source, "Не удалось прочитать файл: " filePath, err.Message)
    }

    return lines
}

LoadRecordCache(filePath, recordCache, source := "LoadRecordCache") {
    if !FileExist(filePath)
        return

    for _, record in ReadFileLines(filePath, source) {
        if (record != "")
            recordCache[record] := true
    }
}



EnsureNickBeforeCloudAccess(forcePrompt := false, message := "") {
    global nick, userNick, settingsFile

    nick := Trim(nick)
    if (!forcePrompt && nick != "" && nick != "Nick_Name") {
        userNick := nick
        return
    }

    loop {
        prompt := message
        if (prompt != "")
            prompt .= "`n`n"
        prompt .= "Введите ваш ник администратора для проверки доступа:"

        result := ShowNickInputDialog(prompt, nick)
        if (result.Result = "Cancel")
            ExitApp()

        enteredNick := Trim(result.Value)
        if (enteredNick != "" && enteredNick != "Nick_Name") {
            nick := enteredNick
            userNick := nick
            try IniWrite(nick, settingsFile, "Main", "nick")
            return
        }

        MsgBox("Введите корректный ник администратора.", "ChesNova", "Icon!")
    }
}
; HTTP GET с таймаутами. resolve/connect/send/receive в мс.
HttpGetText(url, resolveMs := 15000, connectMs := 15000, sendMs := 30000, receiveMs := 45000) {
    return HttpGetTextAsync(url, resolveMs, connectMs, sendMs, receiveMs)
}

FormatHttpError(err) {
    msg := err.Message
    if InStr(msg, "0x80072EE2") || InStr(msg, "истекло") || InStr(msg, "timed out") || InStr(msg, "timeout")
        return "Сервер Cloud не ответил вовремя (таймаут).`nПроверьте интернет или повторите через минуту.`n`nGoogle Apps Script иногда «просыпается» 10–30 сек."
    if InStr(msg, "0x80072EFD") || InStr(msg, "0x80072EE7")
        return "Нет связи с интернетом или DNS не резолвит адрес.`nПроверьте сеть / VPN / антивирус."
    if InStr(msg, "0x80072F7D") || InStr(msg, "0x80072F8F")
        return "Проблема с SSL/HTTPS.`nПроверьте системное время и антивирус-HTTPS-сканер."
    return msg
}

CheckCloudAccess(exitOnDenied := true, promptOnDenied := true) {
    global nick, accessUrl, cloudAccessState, cloudAccessMessage, cloudLastCheck, appVersion

    loop {
        url := accessUrl "?nick=" UriEncode(nick) "&version=" UriEncode(appVersion)
        response := ""
        lastErr := ""

        ; До 2 попыток: cold start Google Script часто рвёт первый запрос.
        loop 2 {
            try {
                result := HttpGetText(url)
                if (result["status"] != 200)
                    throw Error("HTTP " result["status"])
                response := result["text"]
                lastErr := ""
                break
            } catch as err {
                lastErr := err
                if (A_Index < 2)
                    Sleep(1200)
            }
        }

        if (lastErr != "") {
            cloudAccessState := "offline"
            cloudAccessMessage := "Нет связи с Cloud"
            cloudLastCheck := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

            if (promptOnDenied)
                MsgBox("Не удалось проверить доступ.`n`n" FormatHttpError(lastErr), "ChesNova", "Iconx")

            ; Сетевой сбой ≠ отказ в доступе: не закрываем программу.
            return false
        }

        cloudLastCheck := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

        if (response = "OK") {
            cloudAccessState := "ok"
            cloudAccessMessage := "Доступ подтверждён"
            return true
        }

        if (response = "BLOCK") {
            cloudAccessState := "blocked"
            cloudAccessMessage := "Доступ заблокирован"

            if (promptOnDenied)
                MsgBox("Доступ заблокирован.", "ChesNova", "Iconx")

            if (exitOnDenied)
                ExitApp()

            return false
        }

        cloudAccessState := "denied"
        cloudAccessMessage := "Ник не найден: " nick

        if (!promptOnDenied)
            return false

        MsgBox("Ник не найден в базе доступа.`nНик: " nick, "ChesNova", "Iconx")
        EnsureNickBeforeCloudAccess(true, "Ник не найден в базе доступа.`nНик: " nick)
    }
}

UriEncode(str) {
    result := ""

    Loop Parse, str {
        ch := A_LoopField
        code := Ord(ch)

        if ((code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || ch = "_" || ch = "-" || ch = ".")
            result .= ch
        else
            result .= "%" Format("{:02X}", code)
    }

    return result
}
