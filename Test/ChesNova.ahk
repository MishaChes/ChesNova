#Requires AutoHotkey v2.0
#SingleInstance Off
FileEncoding "CP0"
#Warn All, Off

; Запуск с --syntax-check — только проверка парсинга, логика не запускается.
if (A_Args.Length >= 1 && A_Args[1] = "--syntax-check")
    ExitApp()

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

; Любая неперехваченная ошибка — обычное окно с описанием (и запись в errors.log).
OnError(ChesNova_ShowErrorBox)

; ============================================================
; ChesNova
; AutoHotkey v2 script
; ============================================================
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
CURRENT_VERSION := "12.1.1"
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
zCountFile := dataPath "\z_count.txt"
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
notesFile := dataPath "\notes.json"
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
scriptDeleteRetry := Map()
hudBridgeVisible := 1
panelToggleSeq := 0
noteToggleSeq := 0
pendingNormResetConfirm := 0
hudAdminConnected := 0
hudAdminUnlocked := 0
lastAdminLogSize := 0
hudBridgeSettingsFile := dataPath "\hud_settings_state.json"
hudBridgePendingSettingsFile := dataPath "\hud_settings_pending.ini"
hudBridgePunishmentsFile := dataPath "\hud_punishments_state.json"
hudBridgePunishmentsCacheStamp := ""
hudBridgePmLogsFile := dataPath "\hud_pmlogs_state.json"
hudBridgePmLogsCacheStamp := ""
hudBridgeCommandFile := dataPath "\hud_commands.ini"
hudBridgeResetPendingFile := dataPath "\hud_reset_pending.txt"
hudBridgeNormFile := dataPath "\hud_norm_state.json"
hudBridgeNormCacheStamp := ""
hudBridgeDaysoffFile := dataPath "\hud_daysoff_state.json"
hudBridgeDaysoffCacheStamp := ""
hudBridgeScriptsFile := dataPath "\hud_scripts_state.json"
hudBridgeBindsFile := dataPath "\hud_binds_state.json"
hudBridgeBindsCacheStamp := ""
hudBridgeBindsContentFile := dataPath "\hud_binds_content.tmp"
hudBridgeTesterFile := dataPath "\hud_tester_state.json"
hudBridgeUpdatesFile := dataPath "\hud_updates_state.json"
hudBridgeNotificationsFile := dataPath "\hud_notifications_state.json"
hudBridgeCloudFile := dataPath "\hud_cloud_state.json"
hudBridgeHelpFile := dataPath "\hud_help_state.json"
hudBridgeDiagnosticsFile := dataPath "\hud_diagnostics_state.json"
hudBridgeAiFile := dataPath "\hud_ai_state.json"
hudBridgeAiQuestionFile := dataPath "\hud_ai_question.tmp"
hudBridgeVehiclesFile := dataPath "\vehicles.json"
hudBridgeDmMapFile := dataPath "\hud_dm_map.jpg"
hudBridgeRulesCrimeFile := dataPath "\rules_crime.json"
hudBridgeRulesGovFile := dataPath "\rules_gov.json"
hudBridgeRulesCommonFile := dataPath "\rules_common.json"
; AI-ответ для in-game панели (ches.js), ~10 сек
aiHudId := 0
aiHudQuestion := ""
aiHudAnswer := ""
aiHudIsError := false
aiHudExpireTick := 0
aiHudThinking := false
; Уведомление в игре после установки скрипта (по центру экрана, ~5 сек)
scriptNoticeId := 0
scriptNoticeText := ""
scriptNoticeExpireTick := 0
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
testerLastCheck := ""
updatesLatestVersion := ""
updatesHasUpdate := 0
updatesRequired := 0
updatesChangelog := []
updatesDownloadUrl := ""
updatesLastCheck := ""
updatesMessage := ""
startWithWindows := 0
resetHour := 0
resetMinute := 0
lastResetDate := ""
menuKey := "F10"
resetKey := "F9"
aiKey := "F7"
noteKey := "F5"
menuKeyEnabled := 0
resetKeyEnabled := 0
aiKeyEnabled := 0
noteKeyEnabled := 0
aiEnabled := 0  ; по умолчанию выкл. (РФ/блокировки API — без сетевых запросов AI)
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
        noteKey := IniRead(settingsFile, "Keys", "noteKey", "F5")
        menuKeyEnabled := IniRead(settingsFile, "Keys", "menuKeyEnabled", 0)
        resetKeyEnabled := IniRead(settingsFile, "Keys", "resetKeyEnabled", 0)
        aiKeyEnabled := IniRead(settingsFile, "Keys", "aiKeyEnabled", 0)
        noteKeyEnabled := IniRead(settingsFile, "Keys", "noteKeyEnabled", 0)
        aiEnabled := IniRead(settingsFile, "AI", "aiEnabled", 0)
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
aiEnabled += 0
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
; Supabase (замена Google Apps Script): проверка доступа, отчёт о запуске, AI-ключи и квота.
supabaseUrl := "https://sqpshbbsecfiltoconre.supabase.co"
supabaseRest := supabaseUrl "/rest/v1"
supabaseApiKey := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxcHNoYmJzZWNmaWx0b2NvbnJlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzQyNzk0NywiZXhwIjoyMTAzMDAzOTQ3fQ.-dcLsZnTbAtX_tA3wNLTP7oDSYW1l6O_ugL65m26f8w"
EnsureNickBeforeCloudAccess()
SetTimer(SendCloudPing, 3600000)
SetTimer(FetchAiConfigFromCloud, 1800000)
SetTimer(StartupNetworkInit, -300)
SetTimer(UpdateVehiclesData, -25000)
SetTimer(UpdateRulesData, -28000)
SetTimer(DownloadDmMap, -30000)
versionInfoUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/version.json"
testVersionInfoUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Test/Test.json"
stableChesJsUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/JS%20code/ches.js"
testChesJsUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Test/ches.js"
testAhkUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Test/ChesNova.ahk"
vehiclesUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/JS%20code/vehicles.json"
rulesCrimeUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Info/rules_crime.json"
rulesGovUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Info/rules_gov.json"
rulesCommonUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/Info/rules_common.json"
dmMapUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/map.jpg"
notifications := []
notificationStates := Map()
LoadNotificationsCache()
LoadNotificationStates()
SetTimer(CheckNotifications, 600000)

; =========================
; 🧮 VARIABLES
; =========================
pmCount := 0
zCount := 0
zAwaitAnswer := 0
zEnterDeadline := 0
zEnterPending := 0
zEnterPendingDeadline := 0
zEnterProbeMs := 2000
zClaimActive := 0
zClaimTicket := ""
zClaimStartTick := 0
zClaimDeadline := 0
zClaimWindowMs := 3000
zEnterWindowMs := 300000
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
SetAiEnabledCtrl := ""
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
    if (pmCount = "")
        pmCount := 0
    else
        pmCount += 0
}
if FileExist(zCountFile)
{
    loadedZ := FileRead(zCountFile)
    if (loadedZ = "")
        zCount := 0
    else
        zCount += 0
}
LoadRecordCache(punishmentsFile, punishmentRecordCache, "LoadPunishmentRecordCache")
LoadRecordCache(pmLogsFile, pmLogRecordCache, "LoadPmLogRecordCache")
punishmentTotals := LoadPunishmentTotals()
if (logFile != "" && FileExist(logFile))
    lastSize := FileGetSize(logFile)



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

; =========================
; ⌨️ HOTKEYS
; =========================
RegisterHotkeys()
InitializeBinds()
MaybeRotateDaysOffMonthly()
SetTimer(CheckLog, 1000)
SetTimer(CheckAdminLoginState, 1000)
SetTimer(CheckAutoReset, 30000)
SetTimer(RunHealthCheck, 10000)

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

; Добавляет уникальный query-параметр, чтобы Download() (WinINet) не отдавал файл из кэша Windows
BustUrl(url) {
    sep := InStr(url, "?") ? "&" : "?"
    return url sep "_cb=" A_TickCount
}

; Скачивает loader-js.asi + loader-js.json в корень игры и ches.js в uiresources\scripts.
; createOnlyMissing=true — не перезаписывать существующие файлы,
; кроме тех, у которых alwaysUpdate=true (ches.js, loader-js.json — всегда после рестарта/обновы).
EnsureChesNovaHudFiles(silent := true, createOnlyMissing := false) {
    global dataPath, scriptsGamePath, testerMode

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
            "url", testerMode ? testChesJsUrl : stableChesJsUrl,
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
            ; BustUrl: Download() идёт через WinINet и может отдать файл из кэша Windows
            Download(BustUrl(file["url"]), tempFile)
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
    global hudBridgeStateFile, hudBridgePosFile, hudBridgeVisible, pendingNormResetConfirm, panelToggleSeq, noteToggleSeq, nick, pmCount, norm, healthState, healthMessage
    global hudAdminConnected, hudAdminUnlocked
    global zCount, zClaimActive, zAwaitAnswer, zEnterPending
    global aiHudId, aiHudQuestion, aiHudAnswer, aiHudIsError, aiHudExpireTick, aiHudThinking
    global scriptNoticeId, scriptNoticeText, scriptNoticeExpireTick
    global logFile, scriptsGamePath

    try {
        mult := GetNormMultiplier()
        json := "{"
            . '"nick":"' JsonEscape(nick) '",'
            . '"pm":' Integer(pmCount) ','
            . '"norm":' Integer(norm) ','
            . '"mult":' Integer(mult) ','
            . '"health":"' JsonEscape(healthState) '",'
            . '"message":"' JsonEscape(healthMessage) '",'
            . '"hudVisible":' ((hudAdminUnlocked ? hudBridgeVisible : 0) ? 1 : 0) ','
            . '"adminConnected":' (hudAdminConnected ? 1 : 0) ','
            . '"adminUnlocked":' (hudAdminUnlocked ? 1 : 0) ','
            . '"zCount":' Integer(zCount) ','
            . '"zAwaitAnswer":' (zAwaitAnswer ? 1 : 0) ','
            . '"zPending":' (zClaimActive ? 1 : 0) ','
            . '"zEnterPending":' (zEnterPending ? 1 : 0) ','
            . '"confirmReset":' (pendingNormResetConfirm ? 1 : 0) ','
            . '"panelToggle":' Integer(panelToggleSeq) ','
            . '"noteToggle":' Integer(noteToggleSeq) ','
            . '"daysOff":' CountDaysOffCurrentMonth() ','
            . '"chatlogOk":' ((logFile != "" && FileExist(logFile)) ? 1 : 0) ','
            . '"gameOk":' ((scriptsGamePath != "" && IsValidGameRoot(scriptsGamePath)) ? 1 : 0) ','
            . '"hudOk":' ((scriptsGamePath != "" && IsChesNovaHudInstalled(scriptsGamePath)) ? 1 : 0)

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

        if (scriptNoticeText != "" && A_TickCount < scriptNoticeExpireTick) {
            remainMs := scriptNoticeExpireTick - A_TickCount
            if (remainMs < 0)
                remainMs := 0
            json .= ',"scriptNotice":{'
                . '"id":' Integer(scriptNoticeId) ','
                . '"text":"' JsonEscape(scriptNoticeText) '",'
                . '"ttl":' Integer(remainMs)
                . "}"
        } else {
            json .= ',"scriptNotice":null'
        }

        json .= "}"
        f := FileOpen(hudBridgeStateFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо: мост не должен ломать основной цикл
    }
}

; Текущие настройки для панели (GET /settings) — пишется при старте, сохранении и раз в сек
WriteSettingsState(*) {
    global hudBridgeSettingsFile, nick, norm, autoResetEnabled, resetHour, resetMinute, startWithWindows
    global menuKey, resetKey, aiKey, menuKeyEnabled, resetKeyEnabled, aiKeyEnabled
    global logFile, scriptsGamePath

    try {
        json := "{"
            . '"nick":"' JsonEscape(nick) '",'
            . '"logFile":"' JsonEscape(logFile) '",'
            . '"gamePath":"' JsonEscape(scriptsGamePath) '",'
            . '"norm":' Integer(norm) ','
            . '"autoReset":' (autoResetEnabled ? 1 : 0) ','
            . '"startWithWindows":' (startWithWindows ? 1 : 0) ','
            . '"hours":"' Format("{:02}", resetHour) '",'
            . '"minutes":"' Format("{:02}", resetMinute) '",'
            . '"menuKey":"' JsonEscape(menuKey) '",'
            . '"resetKey":"' JsonEscape(resetKey) '",'
            . '"aiKey":"' JsonEscape(aiKey) '",'
            . '"menuKeyEnabled":' (menuKeyEnabled ? 1 : 0) ','
            . '"resetKeyEnabled":' (resetKeyEnabled ? 1 : 0) ','
            . '"aiKeyEnabled":' (aiKeyEnabled ? 1 : 0) ','
            . '"noteKey":"' JsonEscape(noteKey) '",'
            . '"noteKeyEnabled":' (noteKeyEnabled ? 1 : 0)
            . "}"
        f := FileOpen(hudBridgeSettingsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Данные наказаний для панели (GET /punishments) — пишется при изменении файла истории
WritePunishmentsState(*) {
    global hudBridgePunishmentsFile, hudBridgePunishmentsCacheStamp, punishmentsFile
    global viewHistoryScanLimit, viewHistoryDisplayLimit

    try {
        if !FileExist(punishmentsFile) {
            if (hudBridgePunishmentsCacheStamp = "empty")
                return
            hudBridgePunishmentsCacheStamp := "empty"
            f := FileOpen(hudBridgePunishmentsFile, "w", "UTF-8")
            f.Write('{"ok":true,"records":[]}')
            f.Close()
            return
        }

        stamp := ""
        try stamp := FileGetTime(punishmentsFile, "M")
        catch
            stamp := ""
        if (stamp != "" && stamp = hudBridgePunishmentsCacheStamp)
            return
        hudBridgePunishmentsCacheStamp := stamp

        records := []
        lines := SortRecordsNewestFirst(ReadRecentLines(punishmentsFile, viewHistoryScanLimit, "WritePunishmentsState"), "punishment")
        for _, line in lines {
            if (Trim(line) = "")
                continue

            part := StrSplit(line, "|")
            if (part.Length < 6)
                continue
            if !IsCurrentAdminPunishment(part[3])
                continue

            rowType := NormalizePunishmentType(part[5])
            duration := ""
            if (part.Length >= 7)
                duration := part[7]
            if (duration = "")
                duration := ""

            rec := '{'
                . '"date":"' JsonEscape(part[1]) '",'
                . '"time":"' JsonEscape(part[2]) '",'
                . '"type":"' JsonEscape(rowType) '",'
                . '"player":"' JsonEscape(part[4]) '",'
                . '"reason":"' JsonEscape(part[6]) '",'
                . '"duration":"' JsonEscape(duration) '"'
                . '}'
            records.Push(rec)

            if (records.Length >= viewHistoryDisplayLimit)
                break
        }

        json := '{"ok":true,"records":['
        for i, rec in records {
            if (i > 1)
                json .= ","
            json .= rec
        }
        json .= "]}"
        f := FileOpen(hudBridgePunishmentsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Очистить PM-логи из панели (GET /pmlogs/clear)
ClearPmLogsFromPanel(*) {
    global pmLogsFile, hudBridgePmLogsCacheStamp

    if !CreateBackupBeforeClear(pmLogsFile)
        return
    try {
        file := FileOpen(pmLogsFile, "w")
        file.Close()
        hudBridgePmLogsCacheStamp := ""
        WritePmLogsState()
    } catch as err {
        LogError("ClearPmLogsFromPanel", "Ошибка очистки PM-логов", err.Message)
    }
}

; Вкл/выкл всех биндов из панели (GET /binds/toggle)
SetBindsEnabledFromPanel(enabledRaw) {
    global settingsFile, bindsEnabled

    newValue := Trim(enabledRaw)
    if (newValue = "0" || newValue = "1") {
        newValue := Integer(newValue)
        if (newValue != bindsEnabled) {
            bindsEnabled := newValue
            TryIniWrite(bindsEnabled, settingsFile, "Main", "bindsEnabled", "SetBindsEnabledFromPanel")
            RegisterCustomBinds()
            WriteBindsState()
        }
    }
}

; Сохранить бинд из панели (GET /binds/save → hud_commands.ini)
SaveBindFromPanel(bindType, category, bindName, trigger, content, enabled, originalTrigger) {
    bindType := NormalizeBindType(bindType)
    category := Trim(category)
    bindName := Trim(bindName)
    trigger := Trim(trigger)
    enabled := (Trim(enabled) = "1") ? 1 : 0
    originalTrigger := Trim(originalTrigger)

    if (category = "" || bindName = "" || trigger = "" || Trim(content) = "") {
        ShowToast("⚠ Бинд: заполните все поля", 2200)
        return
    }
    if !BindCategoryExists(category) {
        ShowToast("⚠ Такой категории нет: " category, 2200)
        return
    }
    if (bindType = "hotstring" || bindType = "macro")
        trigger := RegExReplace(trigger, "^:\*?\??:|::$")
    if BindTriggerExists(trigger, originalTrigger) {
        ShowToast("⚠ Бинд с таким триггером уже существует", 2200)
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
    if !updated
        binds.Push(newBind)

    if !WriteBinds(binds)
        return
    RegisterCustomBinds()
    WriteBindsState()
    ShowToast("✓ Бинд сохранён", 1800)
}

; Удалить бинды из панели (GET /binds/delete → hud_commands.ini)
DeleteBindsFromPanel(triggersRaw) {
    triggers := []
    for _, t in StrSplit(triggersRaw, ",") {
        t := Trim(t)
        if (t != "" && !ArrayHasValue(triggers, t))
            triggers.Push(t)
    }
    if (triggers.Length = 0)
        return

    newBinds := []
    for _, bind in ReadBinds() {
        if !ArrayHasValue(triggers, bind["trigger"])
            newBinds.Push(bind)
    }
    if !WriteBinds(newBinds)
        return
    RegisterCustomBinds()
    WriteBindsState()
    ShowToast("✓ Бинды удалены", 1800)
}

; Вкл/выкл отдельных биндов из панели (GET /binds/enable → hud_commands.ini)
SetBindEnabledFromPanel(triggersRaw, enabledRaw) {
    enabled := (Trim(enabledRaw) = "1") ? 1 : 0
    triggers := []
    for _, t in StrSplit(triggersRaw, ",") {
        t := Trim(t)
        if (t != "" && !ArrayHasValue(triggers, t))
            triggers.Push(t)
    }
    if (triggers.Length = 0)
        return

    binds := ReadBinds()
    changed := false
    for _, bind in binds {
        if ArrayHasValue(triggers, bind["trigger"]) {
            newValue := enabled
            if ((bind["enabled"] + 0) != newValue) {
                bind["enabled"] := newValue
                changed := true
            }
        }
    }
    if !changed
        return
    if !WriteBinds(binds)
        return
    RegisterCustomBinds()
    WriteBindsState()
    ShowToast(enabled ? "✓ Бинды включены" : "✓ Бинды выключены", 1800)
}

; Добавить категорию биндов из панели (GET /binds/category/add → hud_commands.ini)
AddBindCategoryFromPanel(category) {
    category := Trim(category)
    if (category = "") {
        ShowToast("⚠ Категории: введите название", 2200)
        return
    }
    if BindCategoryExists(category) {
        ShowToast("⚠ Такая категория уже существует: " category, 2200)
        return
    }
    if !AddBindCategoryByName(category) {
        ShowToast("⚠ Не удалось создать категорию", 2200)
        return
    }
    RegisterCustomBinds()
    WriteBindsState()
    ShowToast("✓ Категория добавлена: " category, 1800)
}

; Вкл/выкл категории биндов из панели (GET /binds/category/toggle → hud_commands.ini)
SetBindCategoryEnabledFromPanel(category, enabledRaw) {
    category := Trim(category)
    if (category = "")
        return
    enabled := (Trim(enabledRaw) = "1") ? 1 : 0
    if !SetBindCategoryEnabled(category, enabled)
        return
    RegisterCustomBinds()
    WriteBindsState()
    ShowToast(enabled ? "✓ Категория включена: " category : "✓ Категория выключена: " category, 1800)
}

; Удалить категорию биндов из панели (GET /binds/category/delete → hud_commands.ini)
DeleteBindCategoryFromPanel(category) {
    category := Trim(category)
    if (category = "" || category = "Все") {
        ShowToast("⚠ Эту категорию нельзя удалить", 2200)
        return
    }

    records := ReadBindCategoryRecords()
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
        return

    binds := ReadBinds()
    movedCount := 0
    for _, bind in binds {
        if (bind["category"] = category) {
            bind["category"] := "Все"
            movedCount += 1
        }
    }

    categoryFile := GetBindCategoryFile(category)

    if !SaveBindCategoryRecords(newRecords)
        return

    if !WriteBinds(binds) {
        SaveBindCategoryRecords(records)
        ShowToast("⚠ Не удалось удалить категорию", 2200)
        return
    }

    TryFileDelete(categoryFile, "DeleteBindCategoryFromPanel", "Ошибка удаления файла категории")

    RegisterCustomBinds()
    WriteBindsState()
    ShowToast("✓ Категория удалена: " category, 1800)
}

WritePmLogsState(*) {
    global hudBridgePmLogsFile, hudBridgePmLogsCacheStamp, pmLogsFile
    global viewHistoryDisplayLimit

    try {
        if !FileExist(pmLogsFile) {
            if (hudBridgePmLogsCacheStamp = "empty")
                return
            hudBridgePmLogsCacheStamp := "empty"
            f := FileOpen(hudBridgePmLogsFile, "w", "UTF-8")
            f.Write('{"ok":true,"records":[]}')
            f.Close()
            return
        }

        stamp := ""
        try stamp := FileGetTime(pmLogsFile, "M")
        catch
            stamp := ""
        if (stamp != "" && stamp = hudBridgePmLogsCacheStamp)
            return
        hudBridgePmLogsCacheStamp := stamp

        records := []
        lines := ReadRecentLines(pmLogsFile, viewHistoryDisplayLimit, "WritePmLogsState")
        for _, line in lines {
            if (Trim(line) = "")
                continue

            part := StrSplit(line, "|")
            if (part.Length < 4)
                continue

            message := ""
            Loop part.Length - 3 {
                if (A_Index > 1)
                    message .= "|"
                message .= part[A_Index + 3]
            }

            rec := '{'
                . '"date":"' JsonEscape(part[1]) '",'
                . '"time":"' JsonEscape(part[2]) '",'
                . '"nick":"' JsonEscape(part[3]) '",'
                . '"message":"' JsonEscape(message) '"'
                . '}'
            records.Push(rec)
        }

        reversed := []
        Loop records.Length {
            reversed.Push(records[records.Length - A_Index + 1])
        }

        json := '{"ok":true,"records":['
        for i, rec in reversed {
            if (i > 1)
                json .= ","
            json .= rec
        }
        json .= "]}"
        f := FileOpen(hudBridgePmLogsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; История нормы для панели (GET /norm) — пишется при изменении файла истории
WriteNormHistoryState(*) {
    global hudBridgeNormFile, hudBridgeNormCacheStamp, historyFile

    try {
        if !FileExist(historyFile) {
            if (hudBridgeNormCacheStamp = "empty")
                return
            hudBridgeNormCacheStamp := "empty"
            f := FileOpen(hudBridgeNormFile, "w", "UTF-8")
            f.Write('{"ok":true,"records":[]}')
            f.Close()
            return
        }

        stamp := ""
        try stamp := FileGetTime(historyFile, "M")
        catch
            stamp := ""
        if (stamp != "" && stamp = hudBridgeNormCacheStamp)
            return
        hudBridgeNormCacheStamp := stamp

        records := []
        lines := SortRecordsNewestFirst(ReadFileLines(historyFile, "WriteNormHistoryState"), "history")
        for _, line in lines {
            if (Trim(line) = "")
                continue

            part := StrSplit(line, ",")
            if (part.Length < 3)
                continue

            date := part[1]
            displayDate := date
            if RegExMatch(date, "^(\d{4})-(\d{2})-(\d{2})$", &dm)
                displayDate := dm[3] "." dm[2] "." dm[1]

            pm := part[2] + 0
            normVal := part[3] + 0

            rec := '{'
                . '"date":"' JsonEscape(displayDate) '",'
                . '"raw":"' JsonEscape(date) '",'
                . '"pm":' Integer(pm) ','
                . '"norm":' Integer(normVal)
                . '}'
            records.Push(rec)
        }

        json := '{"ok":true,"records":['
        for i, rec in records {
            if (i > 1)
                json .= ","
            json .= rec
        }
        json .= "]}"
        f := FileOpen(hudBridgeNormFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Раз в секунду обновляем и state, и settings для панели
UpdateHudBridgeState(*) {
    WriteHudBridgeState()
    WriteSettingsState()
    WritePunishmentsState()
    WritePmLogsState()
    WriteNormHistoryState()
    WriteDaysoffState()
    WriteScriptsState()
    WriteBindsState()
}

; Список отгулов для панели (GET /daysoff → hud_daysoff_state.json)
WriteDaysoffState(*) {
    global hudBridgeDaysoffFile, hudBridgeDaysoffCacheStamp, daysOffFile

    try {
        if !FileExist(daysOffFile) {
            if (hudBridgeDaysoffCacheStamp = "empty")
                return
            hudBridgeDaysoffCacheStamp := "empty"
            f := FileOpen(hudBridgeDaysoffFile, "w", "UTF-8")
            f.Write('{"ok":true,"records":[]}')
            f.Close()
            return
        }

        stamp := ""
        try stamp := FileGetTime(daysOffFile, "M")
        catch
            stamp := ""
        if (stamp != "" && stamp = hudBridgeDaysoffCacheStamp)
            return
        hudBridgeDaysoffCacheStamp := stamp

        records := []
        lines := SortRecordsNewestFirst(ReadFileLines(daysOffFile, "WriteDaysoffState"), "dayoff")
        for _, line in lines {
            if (Trim(line) = "")
                continue
            rec := ParseDayOffRecord(line)
            if !IsObject(rec)
                continue
            records.Push(Map("date", rec["date"], "forumUploaded", rec["forumUploaded"]))
        }

        json := '{"ok":true,"records":['
        for i, record in records {
            if (i > 1)
                json .= ","
            json .= '{"date":"' JsonEscape(record["date"]) '","forum":' Integer(record["forumUploaded"]) '}'
        }
        json .= "]}"
        f := FileOpen(hudBridgeDaysoffFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Добавить отгул из панели (GET /daysoff/add → hud_commands.ini)
AddDayOffFromPanel(date, uploaded) {
    global daysOffFile, hudBridgeDaysoffCacheStamp

    dayOffDate := NormalizeDayOffDate(date)
    if (dayOffDate = "")
        return
    if IsDayOff(dayOffDate)
        return

    forumUploaded := (uploaded = "1") ? 1 : 0
    if !TryFileAppend(FormatDayOffRecord(dayOffDate, forumUploaded) "`n", daysOffFile, "AddDayOffFromPanel", "Ошибка записи days_off.csv")
        return
    hudBridgeDaysoffCacheStamp := ""
    WriteDaysoffState()
    ShowToast("✓ Отгул за " dayOffDate " добавлен", 1800)
}

; Удалить отгулы из панели (GET /daysoff/delete → hud_commands.ini)
DeleteDayOffFromPanel(dates) {
    global daysOffFile, hudBridgeDaysoffCacheStamp

    selectedDates := StrSplit(dates, ",")
    if (selectedDates.Length = 0)
        return

    newRecords := []
    for _, record in GetDayOffRecords() {
        if !ArrayHasValue(selectedDates, record["date"])
            newRecords.Push(record)
    }

    if !WriteDayOffRecords(newRecords, "DeleteDayOffFromPanel")
        return
    hudBridgeDaysoffCacheStamp := ""
    WriteDaysoffState()
    ShowToast("✓ Отгул(ы) удалены", 1800)
}

; Залить / снять с форума из панели (GET /daysoff/forum → hud_commands.ini)
SetDayOffForumFromPanel(dates, uploaded) {
    global daysOffFile, hudBridgeDaysoffCacheStamp

    selectedDates := StrSplit(dates, ",")
    if (selectedDates.Length = 0)
        return

    records := GetDayOffRecords()
    for _, record in records {
        if ArrayHasValue(selectedDates, record["date"])
            record["forumUploaded"] := (uploaded = "1") ? 1 : 0
    }

    if !WriteDayOffRecords(records, "SetDayOffForumFromPanel")
        return
    hudBridgeDaysoffCacheStamp := ""
    WriteDaysoffState()
    ShowToast(uploaded = "1" ? "✓ Отмечено как залито" : "✓ Отмечено как не залито", 1800)
}

; Список скриптов и их статус для панели (GET /scripts → hud_scripts_state.json)
WriteScriptsState(*) {
    global hudBridgeScriptsFile, scriptsGamePath, settingsFile

    try {
        gamePath := Trim(scriptsGamePath)
        gamePath := RTrim(gamePath, "\/")
        gameOk := (gamePath != "" && IsValidGameRoot(gamePath))

        packages := '['
        for i, package in GetScriptPackages() {
            status := GetScriptPackageInstallStatus(package)
            note := package.Has("skipExisting") && package["skipExisting"] ? "Только недостающие файлы" : "Отдельный пакет"
            if (package["id"] = "onishi")
                note := "Loader + json, без //loader"
            if (i > 1)
                packages .= ","
            fileNames := ""
            for fi, file in package["files"] {
                if (fi > 1)
                    fileNames .= ", "
                fileNames .= file["name"]
            }
            desc := package.Has("description") ? package["description"] : ""
            authors := package.Has("authors") ? package["authors"] : package["author"]
            activation := package.Has("activationCommands") ? package["activationCommands"] : ""
            packages .= '{'
                . '"id":"' JsonEscape(package["id"]) '",'
                . '"title":"' JsonEscape(package["displayTitle"]) '",'
                . '"author":"' JsonEscape(package["author"]) '",'
                . '"authors":"' JsonEscape(authors) '",'
                . '"description":"' JsonEscape(desc) '",'
                . '"files":"' JsonEscape(fileNames) '",'
                . '"activation":"' JsonEscape(activation) '",'
                . '"note":"' JsonEscape(note) '",'
                . '"topic":"' JsonEscape(package["topic"]) '",'
                . '"installed":' (status["installed"] ? 1 : 0) ','
                . '"status":"' JsonEscape(status["text"]) '"'
                . '}'
        }
        packages .= ']'

        json := '{"ok":true,"gamePath":"' JsonEscape(gamePath) '","gameOk":' (gameOk ? 1 : 0) ',"packages":' packages '}'
        f := FileOpen(hudBridgeScriptsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Список биндов для панели (GET /binds → hud_binds_state.json)
WriteBindsState(*) {
    global hudBridgeBindsFile, hudBridgeBindsCacheStamp, bindsEnabled

    try {
        cats := '['
        catCount := 0
        for _, record in ReadBindCategoryRecords() {
            if (record["name"] = "Все")
                continue
            if (catCount > 0)
                cats .= ","
            cats .= '{"name":"' JsonEscape(record["name"]) '","enabled":' Integer(record["enabled"]) '}'
            catCount += 1
        }
        cats .= ']'

        binds := '['
        bindCount := 0
        for _, bind in ReadBinds() {
            if (bindCount > 0)
                binds .= ","
            binds .= '{'
                . '"type":"' JsonEscape(bind["type"]) '",'
                . '"category":"' JsonEscape(bind["category"]) '",'
                . '"name":"' JsonEscape(bind["name"]) '",'
                . '"trigger":"' JsonEscape(bind["trigger"]) '",'
                . '"content":"' JsonEscape(bind["content"]) '",'
                . '"enabled":' Integer(bind["enabled"]) ','
                . '"runtime":"' JsonEscape(GetBindRuntimeStatusText(bind)) '"'
                . '}'
            bindCount += 1
        }
        binds .= ']'

        json := '{"ok":true,"enabled":' (bindsEnabled ? 1 : 0) ',"categories":' cats ',"binds":' binds '}'
        f := FileOpen(hudBridgeBindsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Состояние тестера для панели (GET /tester → hud_tester_state.json)
WriteTesterState(*) {
    global hudBridgeTesterFile, testerMode, CURRENT_VERSION, testerLastCheck

    try {
        info := testerLastCheck
        if (info = "")
            info := testerMode
                ? "Нажми «Проверить», чтобы загрузить информацию о тестовой версии."
                : "Включи «Я тестировщик», затем нажми «Проверить»."

        json := '{"ok":true,'
            . '"enabled":' (testerMode ? 1 : 0) ','
            . '"version":"' JsonEscape(CURRENT_VERSION) '",'
            . '"info":"' JsonEscape(info) '"'
            . '}'
        f := FileOpen(hudBridgeTesterFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Состояние обновлений для панели (GET /updates → hud_updates_state.json)
WriteUpdatesState(*) {
    global hudBridgeUpdatesFile, CURRENT_VERSION, checkUpdatesOnStartup
    global updatesLatestVersion, updatesHasUpdate, updatesRequired, updatesChangelog, updatesDownloadUrl, updatesLastCheck, updatesMessage

    try {
        changelogJson := '['
        changelogCount := 0
        for _, entry in updatesChangelog {
            if (changelogCount > 0)
                changelogJson .= ","
            changelogJson .= '"' JsonEscape(entry) '"'
            changelogCount += 1
        }
        changelogJson .= ']'

        json := '{"ok":true,'
            . '"version":"' JsonEscape(CURRENT_VERSION) '",'
            . '"latest":"' JsonEscape(updatesLatestVersion) '",'
            . '"hasUpdate":' (updatesHasUpdate ? 1 : 0) ','
            . '"required":' (updatesRequired ? 1 : 0) ','
            . '"changelog":' changelogJson ','
            . '"download":"' JsonEscape(updatesDownloadUrl) '",'
            . '"checkOnStartup":' (checkUpdatesOnStartup ? 1 : 0) ','
            . '"lastCheck":"' JsonEscape(updatesLastCheck) '",'
            . '"message":"' JsonEscape(updatesMessage) '"'
            . '}'
        f := FileOpen(hudBridgeUpdatesFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Состояние уведомлений для панели (GET /notifications → hud_notifications_state.json)
WriteNotificationsState(*) {
    global hudBridgeNotificationsFile, notifications, notificationStates

    try {
        items := '['
        itemCount := 0
        for _, notification in notifications {
            id := notification["id"]
            dismissed := 0
            read := 0
            if notificationStates.Has(id) {
                read := notificationStates[id].Get("read", 0)
                dismissed := notificationStates[id].Get("dismissed", 0)
            }
            if (dismissed)
                continue
            if (itemCount > 0)
                items .= ","
            items .= '{'
                . '"id":"' JsonEscape(id) '",'
                . '"title":"' JsonEscape(notification["title"]) '",'
                . '"text":"' JsonEscape(notification["text"]) '",'
                . '"type":"' JsonEscape(notification["type"]) '",'
                . '"date":"' JsonEscape(notification["date"]) '",'
                . '"read":' Integer(read)
                . '}'
            itemCount += 1
        }
        items .= ']'

        json := '{"ok":true,"items":' items '}'
        f := FileOpen(hudBridgeNotificationsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Состояние Cloud для панели (GET /cloud → hud_cloud_state.json)
WriteCloudState(*) {
    global hudBridgeCloudFile, nick, cloudAccessState, cloudAccessMessage, cloudLastCheck

    try {
        json := '{"ok":true,'
            . '"nick":"' JsonEscape(nick) '",'
            . '"status":"' JsonEscape(cloudAccessState) '",'
            . '"message":"' JsonEscape(cloudAccessMessage) '",'
            . '"lastCheck":"' JsonEscape(cloudLastCheck) '"'
            . '}'
        f := FileOpen(hudBridgeCloudFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}


; Состояние AI для панели (GET /ai → hud_ai_state.json)
WriteAiState(*) {
    global hudBridgeAiFile, aiEnabled, aiProvider, aiConfigLoaded
    global aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiHistory, aiRequestBusy
    global cloudAccessState

    try {
        items := "["
        itemCount := 0
        ; новые сверху
        i := aiHistory.Length
        while (i >= 1) {
            item := aiHistory[i]
            if (itemCount > 0)
                items .= ","
            tVal := item.Has("t") ? item["t"] : ""
            rec := "{"
                . '"q":"' JsonEscape(item["q"]) '",'
                . '"a":"' JsonEscape(item["a"]) '",'
                . '"t":"' JsonEscape(tVal) '"'
                . "}"
            items .= rec
            itemCount += 1
            i -= 1
        }
        items .= "]"

        limitText := GetAiLimitStatusText()
        json := "{"
            . '"ok":true,'
            . '"enabled":' (aiEnabled ? 1 : 0) ','
            . '"provider":"' JsonEscape(aiProvider) '",'
            . '"busy":' (aiRequestBusy ? 1 : 0) ','
            . '"configLoaded":' (aiConfigLoaded ? 1 : 0) ','
            . '"limit":' Integer(aiDailyLimit) ','
            . '"used":' Integer(aiDailyUsed) ','
            . '"remaining":' Integer(aiDailyRemaining) ','
            . '"limitText":"' JsonEscape(limitText) '",'
            . '"cloud":"' JsonEscape(cloudAccessState) '",'
            . '"history":' items
            . "}"
        f := FileOpen(hudBridgeAiFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

SetAiEnabledFromPanel(enabledRaw) {
    global settingsFile, aiEnabled

    newValue := Trim(enabledRaw)
    if (newValue != "0" && newValue != "1")
        return
    newValue := Integer(newValue)
    if (newValue = aiEnabled) {
        WriteAiState()
        return
    }
    aiEnabled := newValue
    TryIniWrite(aiEnabled, settingsFile, "AI", "aiEnabled", "SetAiEnabledFromPanel")
    RegisterAiChatHotstring()
    if aiEnabled
        SetTimer(FetchAiConfigFromCloud, -500)
    WriteAiState()
    ShowToast(aiEnabled ? "✓ AI включён" : "AI выключен", 1800)
}

SetAiProviderFromPanel(providerRaw) {
    global settingsFile, aiProvider

    provider := StrLower(Trim(providerRaw))
    if (provider != "gemini" && provider != "deepseek" && provider != "groq")
        return
    if (provider = aiProvider) {
        WriteAiState()
        return
    }
    aiProvider := provider
    TryIniWrite(aiProvider, settingsFile, "AI", "aiProvider", "SetAiProviderFromPanel")
    WriteAiState()
    ShowToast("✓ Провайдер: " GetAiProviderLabel(), 1600)
}

ClearAiHistoryFromPanel(*) {
    global aiHistory
    aiHistory := []
    SaveAiHistory()
    WriteAiState()
    ShowToast("✓ История AI очищена", 1600)
}

AskAiFromPanel(*) {
    global hudBridgeAiQuestionFile, aiRequestBusy, aiEnabled

    question := ""
    try {
        if FileExist(hudBridgeAiQuestionFile)
            question := Trim(FileRead(hudBridgeAiQuestionFile, "UTF-8"))
    }
    try {
        if FileExist(hudBridgeAiQuestionFile)
            FileDelete(hudBridgeAiQuestionFile)
    }
    question := Trim(question)
    if (question = "" || StrLen(question) < 2) {
        ShowToast("⚠ Введите вопрос", 1800)
        return
    }
    if aiRequestBusy {
        ShowToast("⚠ AI уже обрабатывает запрос", 1800)
        return
    }
    if !aiEnabled {
        PushAiToGameHud(question, "AI отключён в настройках ChesNova", true)
        WriteAiState()
        return
    }

    PushAiThinkingToGameHud(question)
    WriteAiState()
    aiRequestBusy := true
    try {
        if (GetCurrentAiApiKey() = "")
            FetchAiConfigFromCloud()
        if (GetCurrentAiApiKey() = "") {
            msg := "Ключ " GetAiProviderLabel() " пуст. Проверьте Cloud / " GetAiKeyCellHint() " в таблице."
            PushAiToGameHud(question, msg, true)
            WriteAiState()
            return
        }
        quota := ConsumeAiQuotaFromCloud()
        if !quota["ok"] {
            PushAiToGameHud(question, quota["reason"], true)
            WriteAiState()
            return
        }
        answer := AskAI(question)
        PushAiHistory(question, answer)
        PushAiToGameHud(question, answer, false, 10000)
        WriteAiState()
    } catch as err {
        LogError("AskAiFromPanel", GetAiProviderLabel(), err.Message)
        PushAiToGameHud(question, "Ошибка: " err.Message, true)
        WriteAiState()
    } finally {
        aiRequestBusy := false
        WriteAiState()
    }
}

; Состояние помощи для панели (GET /help → hud_help_state.json)
WriteHelpState(*) {
    global hudBridgeHelpFile

    try {
        text := GetLastErrorLogLines(30)
        errors := '['
        errorCount := 0
        for _, line in StrSplit(RTrim(text, "`n"), "`n") {
            line := RTrim(line, "`r")
            if (Trim(line) = "")
                continue
            if (errorCount > 0)
                errors .= ","
            timeMatch := ""
            msg := line
            if RegExMatch(line, "^\[([^\]]+)\]\s+\[([^\]]+)\]", &m) {
                timeMatch := m[1]
                msg := "[" m[2] "] " StrReplace(SubStr(line, m.Pos + m.Len), "`r", "")
            }
            errors .= '{'
                . '"time":"' JsonEscape(timeMatch) '",'
                . '"msg":"' JsonEscape(msg) '"'
                . '}'
            errorCount += 1
        }
        errors .= ']'

        json := '{"ok":true,"errors":' errors '}'
        f := FileOpen(hudBridgeHelpFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Состояние диагностики для панели (GET /diagnostics → hud_diagnostics_state.json)
WriteDiagnosticsState(*) {
    global hudBridgeDiagnosticsFile, healthState, healthMessage

    try {
        json := '{"ok":true,'
            . '"health":"' JsonEscape(healthState) '",'
            . '"healthMsg":"' JsonEscape(healthMessage) '",'
            . '"text":"' JsonEscape(BuildDiagnosticsText()) '"'
            . '}'
        f := FileOpen(hudBridgeDiagnosticsFile, "w", "UTF-8")
        f.Write(json)
        f.Close()
    } catch as err {
        ; тихо
    }
}

; Проверить обновления из панели (GET /updates/check → hud_commands.ini)
CheckUpdatesFromPanel() {
    global CURRENT_VERSION, updatesLatestVersion, updatesHasUpdate, updatesRequired, updatesChangelog, updatesDownloadUrl, updatesLastCheck, updatesMessage

    updatesMessage := "Проверка…"
    updatesLastCheck := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    WriteUpdatesState()

    try {
        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        if (versionInfo["latest"] = "")
            throw Error("В version.json нет поля latest.")

        updatesLatestVersion := versionInfo["latest"]
        updatesDownloadUrl := versionInfo["download"]
        updatesChangelog := versionInfo["changelog"]
        updatesRequired := versionInfo["required"]
        updatesHasUpdate := (CompareVersions(updatesLatestVersion, CURRENT_VERSION) > 0)
        updatesMessage := updatesHasUpdate
            ? "Доступна новая версия v" updatesLatestVersion
            : "Установлена последняя версия v" CURRENT_VERSION
        ShowToast(updatesHasUpdate ? "✓ Есть обновление v" updatesLatestVersion : "✓ Версия актуальна", 2000)
    } catch as err {
        updatesMessage := "Не удалось проверить: " err.Message
        LogError("CheckUpdatesFromPanel", "Ошибка проверки обновлений", err.Message)
        ShowToast("⚠ Не удалось проверить обновления", 2200)
    }
    WriteUpdatesState()
}

; Сохранить настройку проверки обновлений при запуске (GET /updates/save → hud_commands.ini)
SetUpdateCheckFromPanel(valueRaw) {
    global settingsFile, checkUpdatesOnStartup

    value := Trim(valueRaw)
    if (value = "0" || value = "1") {
        newValue := Integer(value)
        if (newValue != checkUpdatesOnStartup) {
            checkUpdatesOnStartup := newValue
            TryIniWrite(checkUpdatesOnStartup, settingsFile, "Updates", "checkOnStartup", "SetUpdateCheckFromPanel")
            WriteUpdatesState()
        }
    }
}

; Установить обновление из панели (GET /updates/install → hud_commands.ini)
InstallUpdateFromPanel() {
    global CURRENT_VERSION, basePath, backupPath

    mainScript := basePath "\ChesNova.ahk"
    newScript := basePath "\ChesNova_new.ahk"
    updateUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/ChesNova.ahk"

    try {
        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        if (versionInfo["latest"] = "")
            throw Error("В version.json отсутствует поле latest.")
        if (CompareVersions(versionInfo["latest"], CURRENT_VERSION) <= 0) {
            ShowToast("✓ Установлена последняя версия v" CURRENT_VERSION, 2000)
            return
        }
        if !FileExist(mainScript)
            throw Error("Текущий файл ChesNova.ahk не найден.")

        if FileExist(newScript)
            FileDelete(newScript)

        Download(BustUrl(updateUrl), newScript)
        if !FileExist(newScript) || FileGetSize(newScript) = 0
            throw Error("Загруженный файл пустой.")

        DirCreate(backupPath)
        backupFile := backupPath "\ChesNova_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".ahk"
        FileCopy(mainScript, backupFile, 0)

        try {
            FileDelete(mainScript)
            FileMove(newScript, mainScript, 0)
        } catch as installErr {
            if !FileExist(mainScript) && FileExist(backupFile)
                FileCopy(backupFile, mainScript, 1)
            throw installErr
        }

        ShowToast("✓ Обновление установлено, перезапустите ChesNova", 2500)
        PromptRestartAfterUpdate("Обновление", "Новая версия v" versionInfo["latest"] " установлена.")
    } catch as err {
        if FileExist(newScript)
            try FileDelete(newScript)
        LogError("InstallUpdateFromPanel", "Ошибка установки обновления", err.Message)
        ShowToast("⚠ Не удалось установить обновление", 2200)
    }
}

; Проверить уведомления из панели (GET /notifications/refresh → hud_commands.ini)
RefreshNotificationsFromPanel() {
    CheckNotifications()
    WriteNotificationsState()
    WriteHudBridgeState()
}

; Отметить уведомления прочитанными из панели (GET /notifications/read → hud_commands.ini)
MarkNotificationsReadFromPanel() {
    MarkNotificationsRead()
    WriteNotificationsState()
}

; Проверить доступ Cloud из панели (GET /cloud/check → hud_commands.ini)
CheckCloudFromPanel() {
    CheckCloudAccess(false, false)
    WriteCloudState()
    WriteHudBridgeState()
    ShowToast("✓ Cloud: " GetCloudStatusText(), 2000)
}

; Сменить ник из панели (GET /cloud/nick → hud_commands.ini)
SetCloudNickFromPanel(newNickRaw) {
    global settingsFile, nick, userNick

    newNick := Trim(newNickRaw)
    if (newNick = "" || newNick = "Nick_Name")
        return
    if (newNick != nick) {
        nick := newNick
        userNick := newNick
        TryIniWrite(nick, settingsFile, "Main", "nick", "SetCloudNickFromPanel")
        WriteSettingsState()
    }
    CheckCloudAccess(false, false)
    WriteCloudState()
    WriteHudBridgeState()
    ShowToast("✓ Ник сохранён: " nick, 2000)
}

; Очистить errors.log из панели (GET /help/clear → hud_commands.ini)
ClearErrorsLogFromPanel() {
    global errorsLogFile

    try {
        file := FileOpen(errorsLogFile, "w", "UTF-8")
        file.Close()
        WriteHelpState()
        ShowToast("✓ Лог ошибок очищен", 1800)
    } catch as err {
        LogError("ClearErrorsLogFromPanel", "Не удалось очистить errors.log", err.Message)
        ShowToast("⚠ Не удалось очистить errors.log", 2200)
    }
}

; Обновить диагностику из панели (GET /diagnostics/refresh → hud_commands.ini)
RefreshDiagnosticsFromPanel() {
    RunHealthCheck()
    WriteDiagnosticsState()
}

; Установить пакет скрипта из панели (GET /scripts/install → hud_commands.ini)
InstallScriptPackageFromPanel(packageId) {
    global dataPath

    package := GetScriptPackageById(packageId)
    if !IsObject(package) {
        ShowToast("⚠ Пакет скрипта не найден", 2200)
        return
    }

    gamePath := GetScriptsGamePath()
    if (gamePath = "") {
        ShowToast("⚠ Укажите путь к корню игры", 2200)
        return
    }
    if !DirExist(gamePath) {
        ShowToast("⚠ Папка игры не найдена: " gamePath, 2800)
        return
    }

    uiResourcesPath := gamePath "\uiresources"
    scriptsPath := uiResourcesPath "\scripts"
    try {
        if !DirExist(uiResourcesPath)
            DirCreate(uiResourcesPath)
        if !DirExist(scriptsPath)
            DirCreate(scriptsPath)
    } catch as err {
        LogError("InstallScriptPackageFromPanel", "Не удалось создать папки для пакета " packageId, err.Message)
        ShowToast("⚠ Не удалось создать папки uiresources/scripts", 2600)
        return
    }

    downloadedFiles := []
    downloadsPath := dataPath "\downloads"
    DirCreate(downloadsPath)
    try {
        for index, file in package["files"] {
            tempFile := downloadsPath "\ChesNova_" package["id"] "_" A_TickCount "_" index ".tmp"
            Download(BustUrl(file["url"]), tempFile)
            downloadedFiles.Push(Map("temp", tempFile, "file", file))
        }
    } catch as err {
        for _, downloaded in downloadedFiles {
            try FileDelete(downloaded["temp"])
        }
        LogError("InstallScriptPackageFromPanel", "Не удалось скачать файл " file["name"], err.Message)
        ShowToast("⚠ Не удалось скачать " file["name"], 2600)
        return
    }

    written := 0
    skippedLocked := 0
    failedNames := []
    try {
        for _, downloaded in downloadedFiles {
            rel := StrReplace(downloaded["file"]["relativePath"], "/", "\")
            while InStr(rel, "\\")
                rel := StrReplace(rel, "\\", "\")
            rel := LTrim(rel, "\")
            destination := gamePath "\" rel
            ; SplitPath — не создаём папку с именем файла (баг RegExReplace)
            SplitPath(destination, &destName, &destinationDir)
            if (destinationDir = "")
                destinationDir := gamePath
            if !DirExist(destinationDir)
                DirCreate(destinationDir)
            ; Старый баг: вместо файла могла появиться папка _otools.js
            if DirExist(destination) {
                try DirDelete(destination, true)
                catch as dirErr
                    LogError("InstallScriptPackageFromPanel", "Не удалось удалить ошибочную папку: " destination, dirErr.Message)
            }
            if (package.Has("skipExisting") && package["skipExisting"] && FileExist(destination) && !DirExist(destination)) {
                try FileDelete(downloaded["temp"])
                written += 1
                continue
            }
            destExists := FileExist(destination) && !DirExist(destination)
            okWrite := false
            try {
                FileCopy(downloaded["temp"], destination, 1)
                okWrite := true
            } catch {
                try {
                    FileMove(downloaded["temp"], destination, 1)
                    okWrite := true
                } catch {
                    okWrite := false
                }
            }
            try {
                if FileExist(downloaded["temp"])
                    FileDelete(downloaded["temp"])
            }
            if okWrite {
                written += 1
            } else if destExists {
                skippedLocked += 1
                written += 1
                LogError("InstallScriptPackageFromPanel", "Файл занят (игра запущена?), пропуск перезаписи: " downloaded["file"]["name"], destination)
            } else {
                failedNames.Push(downloaded["file"]["name"])
            }
        }
    } catch as err {
        for _, downloaded in downloadedFiles {
            if FileExist(downloaded["temp"])
                try FileDelete(downloaded["temp"])
        }
        LogError("InstallScriptPackageFromPanel", "Не удалось установить пакет " packageId " в " gamePath, err.Message)
        ShowToast("⚠ Не удалось записать файлы в папку игры", 2600)
        return
    }

    if (failedNames.Length > 0) {
        LogError("InstallScriptPackageFromPanel", "Частичная установка " packageId, "Не записаны: " JoinArrayRange(failedNames, 1, failedNames.Length, ", "))
        WriteScriptsState()
        ShowToast("⚠ Часть файлов не записана: " failedNames[1] (failedNames.Length > 1 ? "…" : "") " — закройте игру и повторите", 3600)
        return
    }

    WriteScriptsState()
    PushScriptNotice("Для того чтобы скрипт заработал, перезайдите в игру")
    if (skippedLocked > 0)
        ShowToast("✓ " package["displayTitle"] " установлен (часть .asi уже была, игра могла держать файлы)", 3200)
    else
        ShowToast("✓ Пакет " package["displayTitle"] " установлен", 2200)
}

; Удалить пакет скрипта из панели (GET /scripts/delete → hud_commands.ini)
UninstallScriptPackageFromPanel(packageId) {
    global scriptDeleteRetry

    package := GetScriptPackageById(packageId)
    if !IsObject(package) {
        ShowToast("⚠ Пакет скрипта не найден", 2200)
        return
    }

    gamePath := GetScriptsGamePath()
    if (gamePath = "") {
        ShowToast("⚠ Укажите путь к корню игры", 2200)
        return
    }
    if !DirExist(gamePath) {
        ShowToast("⚠ Папка игры не найдена: " gamePath, 2800)
        return
    }

    protected := ["loader-js.asi", "loader-js.json", "ches.js"]
    deleted := 0
    kept := 0
    lockedPaths := []
    for _, file in package["files"] {
        rel := StrReplace(file["relativePath"], "/", "\")
        while InStr(rel, "\\")
            rel := StrReplace(rel, "\\", "\")
        rel := LTrim(rel, "\")
        destination := gamePath "\" rel
        if IsPathProtected(rel, protected) {
            kept += 1
            continue
        }
        try {
            if DirExist(destination) {
                DirDelete(destination, true)
                deleted += 1
                continue
            }
            if FileExist(destination) {
                FileDelete(destination)
                deleted += 1
            }
        } catch as err {
            lockedPaths.Push(destination)
            LogError("UninstallScriptPackageFromPanel", "Не удалось удалить " destination, err.Message)
        }
    }

    ; Дополнительная зачистка рантайм-файлов пакета (не влияет на статус установки)
    if package.Has("cleanup") {
        for _, relRaw in package["cleanup"] {
            rel := StrReplace(relRaw, "/", "\")
            destination := gamePath "\" rel
            try {
                if DirExist(destination) {
                    DirDelete(destination, true)
                    continue
                }
                if FileExist(destination)
                    FileDelete(destination)
            } catch as err {
                lockedPaths.Push(destination)
                LogError("UninstallScriptPackageFromPanel", "Не удалось удалить " destination, err.Message)
            }
        }
    }

    if (lockedPaths.Length > 0) {
        scriptDeleteRetry[packageId] := Map("package", package, "remaining", lockedPaths, "attempt", 0, "notified", 0)
        SetTimer(RetryScriptDeletion, 2500)
        WriteScriptsState()
        ShowToast("⏳ Файлы заняты игрой, удалю автоматически после закрытия игры", 3200)
        return
    }

    WriteScriptsState()
    PushScriptNotice("Скрипт удалён. Чтобы применить, перезайдите в игру")
    if (deleted = 0 && kept > 0)
        ShowToast("⚠ У пакета нет файлов для удаления (защищены ядровые: " kept ")", 3200)
    else if (kept > 0)
        ShowToast("✓ " package["displayTitle"] " удалён (защищены ядровые файлы: " kept ")", 3200)
    else
        ShowToast("✓ Пакет " package["displayTitle"] " удалён", 2400)
}

; Доретраить удаление занятых файлов (игра закроется → .asi освободится)
RetryScriptDeletion(*) {
    global scriptDeleteRetry

    if (scriptDeleteRetry.Count = 0) {
        SetTimer(RetryScriptDeletion, 0)
        return
    }
    done := []
    for packageId, entry in scriptDeleteRetry {
        entry["attempt"] += 1
        stillLocked := []
        for _, destination in entry["remaining"] {
            try {
                if DirExist(destination) {
                    DirDelete(destination, true)
                    continue
                }
                if FileExist(destination) {
                    FileDelete(destination)
                    continue
                }
            } catch as err {
                stillLocked.Push(destination)
            }
        }
        if (stillLocked.Length = 0) {
            done.Push(packageId)
            WriteScriptsState()
            PushScriptNotice("Скрипт удалён. Чтобы применить, перезайдите в игру")
            ShowToast("✓ " entry["package"]["displayTitle"] " удалён", 2600)
        } else if (entry["attempt"] >= 240) {
            done.Push(packageId)
            WriteScriptsState()
            LogError("UninstallScriptPackageFromPanel", "Не удалось удалить файлы " packageId, JoinArrayRange(entry["remaining"], 1, entry["remaining"].Length, ", "))
            ShowToast("⚠ Не удалось удалить файлы. Закройте игру и повторите", 3600)
        } else if (entry["notified"] + 24 <= entry["attempt"]) {
            entry["notified"] := entry["attempt"]
            ShowToast("⏳ Удаление ждёт: закройте игру, файлы уйдут сами", 2200)
        }
    }
    for _, packageId in done
        scriptDeleteRetry.Delete(packageId)
    if (scriptDeleteRetry.Count = 0)
        SetTimer(RetryScriptDeletion, 0)
}

IsPathProtected(rel, protectedList) {
    SplitPath(rel, &fileName)
    for _, name in protectedList {
        if (StrLower(fileName) = StrLower(name))
            return true
    }
    return false
}

; Сохранить путь к игре из панели (GET /scripts/path → hud_commands.ini)
SaveScriptsPathFromPanel(path) {
    global scriptsGamePath, settingsFile

    path := RTrim(Trim(path), "\/")
    if (path = "")
        return
    if !DirExist(path) {
        ShowToast("⚠ Папка не найдена", 2000)
        return
    }
    scriptsGamePath := path
    TryIniWrite(path, settingsFile, "Scripts", "gamePath", "SaveScriptsPathFromPanel")
    WriteScriptsState()
    ShowToast("✓ Путь к игре сохранён", 1800)
}

; Сохранить путь к chatlog из панели (GET /settings/chatlog → hud_commands.ini)
SaveChatlogPathFromPanel(path) {
    global logFile, lastSize, settingsFile

    path := Trim(path)
    if (path = "")
        return
    if !FileExist(path) || DirExist(path) {
        ShowToast("⚠ Файл chatlog не найден", 2000)
        return
    }
    logFile := path
    try lastSize := FileGetSize(logFile)
    catch
        lastSize := 0
    TryIniWrite(logFile, settingsFile, "Main", "logFile", "SaveChatlogPathFromPanel")
    WriteSettingsState()
    ShowToast("✓ Путь к chatlog сохранён", 1800)
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

; Показать уведомление в игре (по центру экрана, ~5 сек) — после установки скрипта
PushScriptNotice(text, durationMs := 5000) {
    global scriptNoticeId, scriptNoticeText, scriptNoticeExpireTick

    text := Trim(text)
    if (text = "")
        return
    scriptNoticeId += 1
    scriptNoticeText := text
    scriptNoticeExpireTick := A_TickCount + Max(1000, durationMs)
    WriteHudBridgeState()
    SetTimer(ClearExpiredScriptNotice, -durationMs - 200)
}

ClearExpiredScriptNotice(*) {
    global scriptNoticeExpireTick
    if (A_TickCount >= scriptNoticeExpireTick)
        WriteHudBridgeState()
}

EnsureHudBridgeScript() {
    global hudBridgeScriptFile, hudBridgePort

    ; TcpListener — без прав админа и без netsh urlacl
    ; GET /pos?left=N&top=N — сохранить позицию HUD (CEF localStorage не переживает релог)
    ; GET /settings?k=v&k2=v2 — сохранить настройки (пишется hud_settings_pending.ini)
    ; GET /settings — отдать текущие настройки панели (hud_settings_state.json)
    script := (
        "$ErrorActionPreference = 'Continue'`n"
        "$port = " hudBridgePort "`n"
        "$stateFile = $args[0]`n"
        "$posFile = $args[1]`n"
        "$settingsFile = $args[2]`n"
        "$pendingFile = $args[3]`n"
        "$punFile = $args[4]`n"
        "$pmFile = $args[5]`n"
        "$cmdFile = $args[6]`n"
        "$normFile = $args[7]`n"
        "$daysOffFile = $args[8]`n"
        "$scriptsFile = $args[9]`n"
        "$bindsFile = $args[10]`n"
        "$testerFile = $args[11]`n"
        "$updatesFile = $args[12]`n"
        "$notificationsFile = $args[13]`n"
        "$cloudFile = $args[14]`n"
        "$helpFile = $args[15]`n"
        "$diagnosticsFile = $args[16]`n"
        "$aiFile = $args[17]`n"
        "$aiQuestionFile = $args[18]`n"
        "$vehiclesFile = $args[19]`n"
        "$dmMapFile = $args[20]`n"
        "$notesFile = $args[21]`n"
        "$rulesCrimeFile = $args[22]`n"
        "$rulesGovFile = $args[23]`n"
        "$rulesCommonFile = $args[24]`n"
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
        "    if ($requestLine -match 'GET\s+/settings\?([^\s]+)') {`n"
        "      $query = $Matches[1]`n"
        "      $pairs = $query -split '&'`n"
        "      $lines = @('[Settings]')`n"
        "      foreach ($pair in $pairs) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) {`n"
        "          $k = [System.Uri]::UnescapeDataString($kv[0])`n"
        "          $v = [System.Uri]::UnescapeDataString($kv[1])`n"
        "          $lines += ($k + '=' + $v)`n"
        "        }`n"
        "      }`n"
        "      try { [System.IO.File]::WriteAllLines($pendingFile, $lines, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/settings/chatlog\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'saveChatlogPath=' + $vals['path'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/settings') {`n"
        "      $json = '{`"ok`":true}'`n"
        "      if (Test-Path -LiteralPath $settingsFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($settingsFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/norm/save\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'saveNorm=1' + [Environment]::NewLine + 'normOrigDate=' + $vals['orig'] + [Environment]::NewLine + 'normDate=' + $vals['date'] + [Environment]::NewLine + 'normPm=' + $vals['pm'] + [Environment]::NewLine + 'normValue=' + $vals['norm'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/norm(\?[^\s]+)?\s') {`n"
        "      $json = '{`"ok`":true,`"records`":[]}'`n"
        "      if (Test-Path -LiteralPath $normFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($normFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/pmlogs/clear') {`n"
        "      $json = '{`"ok`":true}'`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, '[Commands]`nclearPmLogs=1`n', [System.Text.Encoding]::Unicode) } catch {}`n"
        "    } elseif ($requestLine -match 'GET\s+/reset/confirm') {`n"
        "      $json = '{`"ok`":true}'`n"
        "      try {`n"
        "        $resetFile = Join-Path (Split-Path $cmdFile -Parent) 'hud_reset_pending.txt'`n"
        "        [System.IO.File]::WriteAllText($resetFile, 'confirm', [System.Text.UTF8Encoding]::new($false))`n"
        "      } catch {}`n"
        "    } elseif ($requestLine -match 'GET\s+/reset/cancel') {`n"
        "      $json = '{`"ok`":true}'`n"
        "      try {`n"
        "        $resetFile = Join-Path (Split-Path $cmdFile -Parent) 'hud_reset_pending.txt'`n"
        "        [System.IO.File]::WriteAllText($resetFile, 'cancel', [System.Text.UTF8Encoding]::new($false))`n"
        "      } catch {}`n"
        "    } elseif ($requestLine -match 'GET\s+/pmlogs') {`n"
        "      $json = '{`"ok`":true,`"records`":[]}'`n"
        "      if (Test-Path -LiteralPath $pmFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($pmFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/daysoff/add\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'addDayOff=1' + [Environment]::NewLine + 'dayOffDate=' + $vals['date'] + [Environment]::NewLine + 'dayOffForum=' + $vals['forum'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/daysoff/delete\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'deleteDayOff=1' + [Environment]::NewLine + 'dayOffDates=' + $vals['dates'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/daysoff/forum\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'setDayOffForum=1' + [Environment]::NewLine + 'dayOffDates=' + $vals['dates'] + [Environment]::NewLine + 'dayOffUploaded=' + $vals['uploaded'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/daysoff') {`n"
        "      $json = '{`"ok`":true,`"records`":[]}'`n"
        "      if (Test-Path -LiteralPath $daysOffFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($daysOffFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/scripts/install\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'installScript=' + $vals['id'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
         "      $json = '{`"ok`":true}'`n"
         "    } elseif ($requestLine -match 'GET\s+/scripts/delete\?([^\s]+)') {`n"
         "      $q = $Matches[1]`n"
         "      $parts = $q -split '&'`n"
         "      $vals = @{}`n"
         "      foreach ($pair in $parts) {`n"
         "        $kv = $pair -split '=', 2`n"
         "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
         "      }`n"
         "      $iniText = '[Commands]' + [Environment]::NewLine + 'deleteScript=' + $vals['id'] + [Environment]::NewLine`n"
         "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
         "      $json = '{`"ok`":true}'`n"
         "    } elseif ($requestLine -match 'GET\s+/scripts/path\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'saveScriptsPath=' + $vals['path'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/scripts/topic\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'openScriptTopic=' + $vals['url'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/scripts') {`n"
        "      $json = '{`"ok`":true,`"gamePath`":`"`",`"gameOk`":0,`"packages`":[]}'`n"
        "      if (Test-Path -LiteralPath $scriptsFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($scriptsFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/punishments') {`n"
        "      $json = '{`"ok`":true,`"records`":[]}'`n"
        "      if (Test-Path -LiteralPath $punFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($punFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/toggle\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'setBindsEnabled=' + $vals['enabled'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/save\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $dataPath = Split-Path $cmdFile -Parent`n"
        "      try { [System.IO.File]::WriteAllText((Join-Path $dataPath 'hud_binds_content.tmp'), [string]$vals['content'], [System.Text.UTF8Encoding]::new($false)) } catch {}`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'saveBind=1' + [Environment]::NewLine + 'bindType=' + $vals['type'] + [Environment]::NewLine + 'bindCategory=' + $vals['category'] + [Environment]::NewLine + 'bindName=' + $vals['name'] + [Environment]::NewLine + 'bindTrigger=' + $vals['trigger'] + [Environment]::NewLine + 'bindEnabled=' + $vals['enabled'] + [Environment]::NewLine + 'bindOriginalTrigger=' + $vals['originalTrigger'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/delete\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'deleteBind=' + $vals['triggers'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/enable\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'setBindEnabled=' + $vals['triggers'] + [Environment]::NewLine + 'bindEnabledValue=' + $vals['enabled'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/category/add\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'addBindCategory=' + $vals['name'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/category/toggle\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'setBindCategory=' + $vals['name'] + [Environment]::NewLine + 'bindCategoryEnabled=' + $vals['enabled'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds/category/delete\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      $vals = @{}`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
        "      }`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'deleteBindCategory=' + $vals['name'] + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/binds') {`n"
        "      $json = '{`"ok`":true,`"enabled`":0,`"categories`":[],`"binds`":[]}'`n"
        "      if (Test-Path -LiteralPath $bindsFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($bindsFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/tester/toggle\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      $vals = @{}`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
    "      }`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'setTesterMode=' + $vals['enabled'] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/tester/check') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'checkTestUpdates=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/tester/download') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'downloadTestUpdate=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/tester/install') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'installTestUpdate=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/tester/rollback') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'rollbackStable=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/tester') {`n"
    "      $json = '{`"ok`":true,`"enabled`":0,`"version`":`"`",`"info`":`"`"}'`n"
    "      if (Test-Path -LiteralPath $testerFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($testerFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/updates/check') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'checkUpdates=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/updates/save\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      $vals = @{}`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
    "      }`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'setUpdateCheck=' + $vals['checkOnStartup'] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/updates/install') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'installUpdate=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/updates') {`n"
    "      $json = '{`"ok`":true,`"version`":`"`",`"latest`":`"`",`"hasUpdate`":0,`"required`":0,`"changelog`":[],`"download`":`"`",`"checkOnStartup`":1,`"lastCheck`":`"`",`"message`":`"`"}'`n"
    "      if (Test-Path -LiteralPath $updatesFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($updatesFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/notifications/refresh') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'refreshNotifications=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/notifications/read') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'markNotificationsRead=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/notifications') {`n"
    "      $json = '{`"ok`":true,`"items`":[]}'`n"
    "      if (Test-Path -LiteralPath $notificationsFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($notificationsFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/cloud/check') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'checkCloud=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/cloud/nick\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      $vals = @{}`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
    "      }`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'setCloudNick=' + $vals['nick'] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/cloud') {`n"
    "      $json = '{`"ok`":true,`"nick`":`"`",`"status`":`"pending`",`"message`":`"`",`"lastCheck`":`"`"}'`n"
    "      if (Test-Path -LiteralPath $cloudFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($cloudFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/help/open') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'openErrorsLog=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/help/clear') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'clearErrorsLog=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/help') {`n"
    "      $json = '{`"ok`":true,`"errors`":[]}'`n"
    "      if (Test-Path -LiteralPath $helpFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($helpFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/ai/toggle\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      $vals = @{}`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
    "      }`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'setAiEnabled=' + $vals['enabled'] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/ai/provider\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      $vals = @{}`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
    "      }`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'setAiProvider=' + $vals['id'] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/ai/clear') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'clearAiHistory=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/ai/ask\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      $vals = @{}`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) { $vals[$kv[0]] = [System.Uri]::UnescapeDataString($kv[1]) }`n"
    "      }`n"
    "      try {`n"
    "        if ($vals.ContainsKey('q')) { [System.IO.File]::WriteAllText($aiQuestionFile, $vals['q'], [System.Text.UTF8Encoding]::new($false)) }`n"
    "      } catch {}`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'askAi=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/ai') {`n"
    "      $json = '{`"ok`":true,`"enabled`":0,`"provider`":`"gemini`",`"busy`":0,`"history`":[],`"limitText`":`"`"}'`n"
    "      if (Test-Path -LiteralPath $aiFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($aiFile, [System.Text.Encoding]::UTF8) } catch {`n"
    "          try { $json = [System.IO.File]::ReadAllText($aiFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "        }`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/diagnostics/refresh') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'refreshDiagnostics=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/diagnostics') {`n"
    "      $json = '{`"ok`":true,`"health`":`"ok`",`"healthMsg`":`"`",`"text`":`"`"}'`n"
    "      if (Test-Path -LiteralPath $diagnosticsFile) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($diagnosticsFile, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/pos\?left=([0-9.\-]+)&top=([0-9.\-]+)') {`n"
        "      $left = $Matches[1]; $top = $Matches[2]`n"
        "      try {`n"
        "        $posJson = '{`"left`":' + $left + ',`"top`":' + $top + '}'`n"
        "        [System.IO.File]::WriteAllText($posFile, $posJson, [System.Text.UTF8Encoding]::new($false))`n"
        "      } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/vehicles/refresh') {`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'refreshVehicles=1' + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/useful/map/download') {`n"
        "      $iniText = '[Commands]' + [Environment]::NewLine + 'refreshDmMap=1' + [Environment]::NewLine`n"
        "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/useful/map') {`n"
        "      $json = '{`"ok`":false,`"image`":`"`"}'`n"
        "      if (Test-Path -LiteralPath $dmMapFile) {`n"
        "        try {`n"
        "          $mapBytes = [System.IO.File]::ReadAllBytes($dmMapFile)`n"
        "          if ($mapBytes.Length -gt 0) {`n"
        "            $mapB64 = [Convert]::ToBase64String($mapBytes)`n"
        "            $json = '{`"ok`":true,`"image`":`"data:image/jpeg;base64,' + $mapB64 + '`"}'`n"
        "          }`n"
        "        } catch {}`n"
        "      }`n"
        "    } elseif ($requestLine -match 'GET\s+/notes/save\?([^\s]+)') {`n"
        "      $q = $Matches[1]`n"
        "      $parts = $q -split '&'`n"
        "      foreach ($pair in $parts) {`n"
        "        $kv = $pair -split '=', 2`n"
        "        if ($kv.Count -eq 2) {`n"
        "          $k = [System.Uri]::UnescapeDataString($kv[0])`n"
        "          $v = [System.Uri]::UnescapeDataString($kv[1])`n"
        "          if ($k -eq 'text') {`n"
        "            try { [System.IO.File]::WriteAllText($notesFile, $v, [System.Text.Encoding]::UTF8) } catch {}`n"
        "          }`n"
        "        }`n"
        "      }`n"
        "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/notes') {`n"
        "      $json = '{`"ok`":true,`"text`":`"`"}'`n"
        "      if (Test-Path -LiteralPath $notesFile) {`n"
        "        try { $notesText = [System.IO.File]::ReadAllText($notesFile, [System.Text.Encoding]::UTF8) } catch { $notesText = '' }`n"
        "        $notesText = $notesText.Replace('\\', '\\\\').Replace('`"', '\`"').Replace([char]13, '\r').Replace([char]10, '\n')`n"
        "        $json = '{`"ok`":true,`"text`":`"' + $notesText + '`"}'`n"
        "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/open\?([^\s]+)') {`n"
    "      $q = $Matches[1]`n"
    "      $parts = $q -split '&'`n"
    "      foreach ($pair in $parts) {`n"
    "        $kv = $pair -split '=', 2`n"
    "        if ($kv.Count -eq 2) {`n"
    "          $k = [System.Uri]::UnescapeDataString($kv[0])`n"
    "          $v = [System.Uri]::UnescapeDataString($kv[1])`n"
    "          if ($k -eq 'url' -and $v -match '^https?://') {`n"
    "            try { Start-Process $v } catch {}`n"
    "          }`n"
    "        }`n"
    "      }`n"
    "      $json = '{`"ok`":true}'`n"
        "    } elseif ($requestLine -match 'GET\s+/rules\?type=([a-z]+)') {`n"
    "      $rf = $null`n"
    "      if ($Matches[1] -eq 'crime') { $rf = $rulesCrimeFile }`n"
    "      elseif ($Matches[1] -eq 'gov') { $rf = $rulesGovFile }`n"
    "      elseif ($Matches[1] -eq 'common') { $rf = $rulesCommonFile }`n"
    "      $json = '{`"ok`":false}'`n"
    "      if ($rf -and (Test-Path -LiteralPath $rf)) {`n"
    "        try { $json = [System.IO.File]::ReadAllText($rf, [System.Text.Encoding]::UTF8) } catch {}`n"
    "      }`n"
"    } elseif ($requestLine -match 'GET\s+/vehicles') {`n"
        "      $json = '{`"ok`":true,`"updated`":`"`",`"vehicles`":[]}'`n"
        "      if (Test-Path -LiteralPath $vehiclesFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($vehiclesFile, [System.Text.Encoding]::UTF8) } catch {`n"
        "          try { $json = [System.IO.File]::ReadAllText($vehiclesFile, [System.Text.Encoding]::Unicode) } catch {}`n"
        "        }`n"
        "      }`n"
    "    } elseif ($requestLine -match 'GET\s+/hud/toggle') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'toggleHud=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/z/saw\?t=([^&]+)') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'zSaw=' + $Matches[1] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/z/claim\?t=(\d+)') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'zClaim=1' + [Environment]::NewLine + 'zClaimTicket=' + $Matches[1] + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/z/answer') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'zAnswer=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } elseif ($requestLine -match 'GET\s+/norma/ask') {`n"
    "      $iniText = '[Commands]' + [Environment]::NewLine + 'promptNormReset=1' + [Environment]::NewLine`n"
    "      try { [System.IO.File]::WriteAllText($cmdFile, $iniText, [System.Text.Encoding]::Unicode) } catch {}`n"
    "      $json = '{`"ok`":true}'`n"
    "    } else {`n"
        "      $json = '{`"nick`":`"`",`"pm`":0,`"health`":`"ok`",`"message`":`"`",`"hud`":null}'`n"
        "      if (Test-Path -LiteralPath $stateFile) {`n"
        "        try { $json = [System.IO.File]::ReadAllText($stateFile, [System.Text.Encoding]::Unicode) } catch {}`n"
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
    global hudBridgeSettingsFile, hudBridgePendingSettingsFile, hudBridgePunishmentsFile, hudBridgePmLogsFile
    global hudBridgeCommandFile, hudBridgeNormFile, hudBridgeDaysoffFile, hudBridgeScriptsFile
    global hudBridgeBindsFile, hudBridgeTesterFile
    global hudBridgeUpdatesFile, hudBridgeNotificationsFile, hudBridgeCloudFile, hudBridgeHelpFile, hudBridgeDiagnosticsFile
    global hudBridgeAiFile, hudBridgeAiQuestionFile, hudBridgeVehiclesFile

    StopHudHttpBridge()
    WriteHudBridgeState()
    WriteSettingsState()
    WritePunishmentsState()
    WritePmLogsState()
    WriteNormHistoryState()
    WriteDaysoffState()
    WriteScriptsState()
    WriteBindsState()
    WriteTesterState()
    WriteUpdatesState()
    WriteNotificationsState()
    WriteCloudState()
    WriteHelpState()
    WriteDiagnosticsState()
    WriteAiState()
    EnsureHudBridgeScript()

    try {
        ; Hidden PowerShell HttpListener — ничего дополнительно ставить не нужно
        cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'
            . hudBridgeScriptFile '" "' hudBridgeStateFile '" "' hudBridgePosFile '" "'
            . hudBridgeSettingsFile '" "' hudBridgePendingSettingsFile '" "' hudBridgePunishmentsFile '" "'
            . hudBridgePmLogsFile '" "' hudBridgeCommandFile '" "' hudBridgeNormFile '" "'
            . hudBridgeDaysoffFile '" "' hudBridgeScriptsFile '" "' hudBridgeBindsFile '" "' hudBridgeTesterFile '" "'
            . hudBridgeUpdatesFile '" "' hudBridgeNotificationsFile '" "' hudBridgeCloudFile '" "'
            . hudBridgeHelpFile '" "' hudBridgeDiagnosticsFile '" "'
            . hudBridgeAiFile '" "' hudBridgeAiQuestionFile '" "' hudBridgeVehiclesFile '" "'
            . hudBridgeDmMapFile '" "' notesFile '" "'
            . hudBridgeRulesCrimeFile '" "' hudBridgeRulesGovFile '" "' hudBridgeRulesCommonFile '"'
        Run(cmd, , "Hide", &pid)
        hudBridgePid := pid
        try {
            f := FileOpen(hudBridgePidFile, "w", "UTF-8")
            f.Write(String(pid))
            f.Close()
        }
        ; На всякий случай обновляем state и настройки раз в секунду
        SetTimer(UpdateHudBridgeState, 1000)
        SetTimer(CheckPendingSettings, 250)
        SetTimer(CheckPendingCommands, 250)
        SetTimer(CheckPendingReset, 200)
    } catch as err {
        LogError("StartHudHttpBridge", "Не удалось запустить HTTP-мост HUD", err.Message)
    }
}

; Команды от панели (GET /pmlogs/clear → hud_commands.ini)
CheckPendingReset(*) {
    global hudBridgeResetPendingFile

    if !FileExist(hudBridgeResetPendingFile)
        return
    action := ""
    try {
        action := Trim(FileRead(hudBridgeResetPendingFile, "UTF-8"))
    } catch {
        action := ""
    }
    try {
        if FileExist(hudBridgeResetPendingFile)
            FileDelete(hudBridgeResetPendingFile)
    } catch {
    }
    if (action = "confirm")
        DoManualNormReset()
    else if (action = "cancel")
        CancelPendingNormReset()
}

CheckPendingCommands(*) {
    global hudBridgeCommandFile, dataPath

    try {
        if !FileExist(hudBridgeCommandFile)
            return
        if IniRead(hudBridgeCommandFile, "Commands", "clearPmLogs", "") = "1" {
            ClearPmLogsFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "toggleHud", "") = "1" {
            ToggleGameHud()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "promptNormReset", "") = "1" {
            PromptManualNormReset()
        }
        setBindsEnabled := IniRead(hudBridgeCommandFile, "Commands", "setBindsEnabled", "")
        if (setBindsEnabled != "") {
            SetBindsEnabledFromPanel(setBindsEnabled)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "saveNorm", "") = "1" {
            origDate := Trim(IniRead(hudBridgeCommandFile, "Commands", "normOrigDate", ""))
            newDate := Trim(IniRead(hudBridgeCommandFile, "Commands", "normDate", ""))
            newPmRaw := Trim(IniRead(hudBridgeCommandFile, "Commands", "normPm", ""))
            newNormRaw := Trim(IniRead(hudBridgeCommandFile, "Commands", "normValue", ""))
            if (origDate != "" && newDate != "" && newPmRaw != "" && newNormRaw != "") {
                SaveNormHistoryFromPanel(origDate, newDate, newPmRaw, newNormRaw)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "addDayOff", "") = "1" {
            dayOffDate := Trim(IniRead(hudBridgeCommandFile, "Commands", "dayOffDate", ""))
            dayOffForum := Trim(IniRead(hudBridgeCommandFile, "Commands", "dayOffForum", "0"))
            if (dayOffDate != "") {
                AddDayOffFromPanel(dayOffDate, dayOffForum)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "deleteDayOff", "") = "1" {
            deleteDates := Trim(IniRead(hudBridgeCommandFile, "Commands", "dayOffDates", ""))
            if (deleteDates != "") {
                DeleteDayOffFromPanel(deleteDates)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "setDayOffForum", "") = "1" {
            forumDates := Trim(IniRead(hudBridgeCommandFile, "Commands", "dayOffDates", ""))
            forumUploaded := Trim(IniRead(hudBridgeCommandFile, "Commands", "dayOffUploaded", "0"))
            if (forumDates != "") {
                SetDayOffForumFromPanel(forumDates, forumUploaded)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "installScript", "") != "" {
            installScriptId := Trim(IniRead(hudBridgeCommandFile, "Commands", "installScript", ""))
            if (installScriptId != "") {
                InstallScriptPackageFromPanel(installScriptId)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "deleteScript", "") != "" {
            deleteScriptId := Trim(IniRead(hudBridgeCommandFile, "Commands", "deleteScript", ""))
            if (deleteScriptId != "") {
                UninstallScriptPackageFromPanel(deleteScriptId)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "saveScriptsPath", "") != "" {
            scriptsPathRaw := Trim(IniRead(hudBridgeCommandFile, "Commands", "saveScriptsPath", ""))
            if (scriptsPathRaw != "") {
                SaveScriptsPathFromPanel(scriptsPathRaw)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "saveChatlogPath", "") != "" {
            chatlogPathRaw := Trim(IniRead(hudBridgeCommandFile, "Commands", "saveChatlogPath", ""))
            if (chatlogPathRaw != "") {
                SaveChatlogPathFromPanel(chatlogPathRaw)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "openScriptTopic", "") != "" {
            topicUrl := Trim(IniRead(hudBridgeCommandFile, "Commands", "openScriptTopic", ""))
            if (topicUrl != "") {
                OpenScriptTopic(topicUrl)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "saveBind", "") = "1" {
            bindType := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindType", ""))
            bindCategory := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindCategory", ""))
            bindName := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindName", ""))
            bindTrigger := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindTrigger", ""))
            bindEnabled := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindEnabled", ""))
            bindOriginalTrigger := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindOriginalTrigger", ""))
            bindContent := ""
            try {
                if FileExist(hudBridgeBindsContentFile)
                    bindContent := FileRead(hudBridgeBindsContentFile, "UTF-8")
            }
            SaveBindFromPanel(bindType, bindCategory, bindName, bindTrigger, bindContent, bindEnabled, bindOriginalTrigger)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "deleteBind", "") != "" {
            deleteBindTriggers := Trim(IniRead(hudBridgeCommandFile, "Commands", "deleteBind", ""))
            if (deleteBindTriggers != "") {
                DeleteBindsFromPanel(deleteBindTriggers)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "setBindEnabled", "") != "" {
            enableBindTriggers := Trim(IniRead(hudBridgeCommandFile, "Commands", "setBindEnabled", ""))
            enableBindValue := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindEnabledValue", ""))
            if (enableBindTriggers != "") {
                SetBindEnabledFromPanel(enableBindTriggers, enableBindValue)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "addBindCategory", "") != "" {
            newCategoryName := Trim(IniRead(hudBridgeCommandFile, "Commands", "addBindCategory", ""))
            if (newCategoryName != "") {
                AddBindCategoryFromPanel(newCategoryName)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "setBindCategory", "") != "" {
            toggleCategoryName := Trim(IniRead(hudBridgeCommandFile, "Commands", "setBindCategory", ""))
            toggleCategoryValue := Trim(IniRead(hudBridgeCommandFile, "Commands", "bindCategoryEnabled", "0"))
            if (toggleCategoryName != "") {
                SetBindCategoryEnabledFromPanel(toggleCategoryName, toggleCategoryValue)
            }
        }
        if IniRead(hudBridgeCommandFile, "Commands", "deleteBindCategory", "") != "" {
            deleteCategoryName := Trim(IniRead(hudBridgeCommandFile, "Commands", "deleteBindCategory", ""))
            if (deleteCategoryName != "") {
                DeleteBindCategoryFromPanel(deleteCategoryName)
            }
        }
        setTesterMode := IniRead(hudBridgeCommandFile, "Commands", "setTesterMode", "")
        if (setTesterMode != "") {
            ToggleTesterModeFromPanel(setTesterMode)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "checkTestUpdates", "") = "1" {
            CheckTestUpdatesFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "downloadTestUpdate", "") = "1" {
            DownloadTestUpdateFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "installTestUpdate", "") = "1" {
            InstallTestUpdateFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "rollbackStable", "") = "1" {
            RollbackToStableReleaseFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "checkUpdates", "") = "1" {
            CheckUpdatesFromPanel()
        }
        setUpdateCheck := IniRead(hudBridgeCommandFile, "Commands", "setUpdateCheck", "")
        if (setUpdateCheck != "") {
            SetUpdateCheckFromPanel(setUpdateCheck)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "installUpdate", "") = "1" {
            InstallUpdateFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "refreshNotifications", "") = "1" {
            RefreshNotificationsFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "markNotificationsRead", "") = "1" {
            MarkNotificationsReadFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "checkCloud", "") = "1" {
            CheckCloudFromPanel()
        }
        setCloudNick := Trim(IniRead(hudBridgeCommandFile, "Commands", "setCloudNick", ""))
        if (setCloudNick != "") {
            SetCloudNickFromPanel(setCloudNick)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "openErrorsLog", "") = "1" {
            OpenErrorsLogFile()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "clearErrorsLog", "") = "1" {
            ClearErrorsLogFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "refreshDiagnostics", "") = "1" {
            RefreshDiagnosticsFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "refreshVehicles", "") = "1" {
            UpdateVehiclesData(true)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "refreshDmMap", "") = "1" {
            DownloadDmMap(true)
        }
        setAiEnabled := IniRead(hudBridgeCommandFile, "Commands", "setAiEnabled", "")
        if (setAiEnabled != "") {
            SetAiEnabledFromPanel(setAiEnabled)
        }
        setAiProvider := Trim(IniRead(hudBridgeCommandFile, "Commands", "setAiProvider", ""))
        if (setAiProvider != "") {
            SetAiProviderFromPanel(setAiProvider)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "clearAiHistory", "") = "1" {
            ClearAiHistoryFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "askAi", "") = "1" {
            AskAiFromPanel()
        }
        if IniRead(hudBridgeCommandFile, "Commands", "zSaw", "") != "" {
            zSawText := Trim(IniRead(hudBridgeCommandFile, "Commands", "zSaw", ""))
            zSawStamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            TryFileAppend(zSawStamp " " zSawText "`n", dataPath "\z_saw.log", "CheckPendingCommands", "Ошибка записи z_saw.log")
        }
        if IniRead(hudBridgeCommandFile, "Commands", "zClaim", "") = "1" {
            zClaimTicketParam := Trim(IniRead(hudBridgeCommandFile, "Commands", "zClaimTicket", ""))
            ArmZClaim(zClaimTicketParam)
        }
        if IniRead(hudBridgeCommandFile, "Commands", "zAnswer", "") = "1" {
            CompleteZClaim()
        }
    } catch as err {
        LogError("CheckPendingCommands", "Не удалось разобрать команды из панели", err.Message)
    }

    try {
        if FileExist(hudBridgeCommandFile)
            FileDelete(hudBridgeCommandFile)
    }
}

; Применение настроек, присланных панелью (GET /settings?k=v → hud_settings_pending.ini)
CheckPendingSettings(*) {
    global hudBridgePendingSettingsFile, settingsFile
    global nick, userNick, norm, autoResetEnabled, resetHour, resetMinute, startWithWindows
    global menuKey, resetKey, aiKey, noteKey, menuKeyEnabled, resetKeyEnabled, aiKeyEnabled, noteKeyEnabled

    if !FileExist(hudBridgePendingSettingsFile)
        return

    try {
        newNick := IniRead(hudBridgePendingSettingsFile, "Settings", "nick", "")
        newNorm := IniRead(hudBridgePendingSettingsFile, "Settings", "norm", "")
        newAutoReset := IniRead(hudBridgePendingSettingsFile, "Settings", "autoReset", "")
        newStartWithWindows := IniRead(hudBridgePendingSettingsFile, "Settings", "startWithWindows", "")
        newHours := IniRead(hudBridgePendingSettingsFile, "Settings", "hours", "")
        newMinutes := IniRead(hudBridgePendingSettingsFile, "Settings", "minutes", "")
        newMenuKey := IniRead(hudBridgePendingSettingsFile, "Settings", "menuKey", "")
        newResetKey := IniRead(hudBridgePendingSettingsFile, "Settings", "resetKey", "")
        newAiKey := IniRead(hudBridgePendingSettingsFile, "Settings", "aiKey", "")
        newNoteKey := IniRead(hudBridgePendingSettingsFile, "Settings", "noteKey", "")
        newMenuKeyEnabled := IniRead(hudBridgePendingSettingsFile, "Settings", "menuKeyEnabled", "")
        newResetKeyEnabled := IniRead(hudBridgePendingSettingsFile, "Settings", "resetKeyEnabled", "")
        newAiKeyEnabled := IniRead(hudBridgePendingSettingsFile, "Settings", "aiKeyEnabled", "")
        newNoteKeyEnabled := IniRead(hudBridgePendingSettingsFile, "Settings", "noteKeyEnabled", "")
    } catch as err {
        return
    }

    ; применяем только те, что реально пришли (пустая строка = не менять)
    changed := false
    try {
        if (newNick != "") {
            if (Trim(newNick) != nick) {
                nick := Trim(newNick)
                userNick := nick
                changed := true
            }
        }
        if (newNorm != "" && RegExMatch(newNorm, "^\d+$")) {
            newNormVal := Integer(newNorm)
            if (newNormVal != norm) {
                norm := newNormVal
                changed := true
            }
        }
        if (newAutoReset != "" && RegExMatch(newAutoReset, "^\d+$")) {
            newAr := Integer(newAutoReset)
            if (newAr != autoResetEnabled) {
                autoResetEnabled := newAr
                changed := true
            }
        }
        if (newStartWithWindows != "" && RegExMatch(newStartWithWindows, "^\d+$")) {
            newSw := Integer(newStartWithWindows)
            if (newSw != startWithWindows) {
                startWithWindows := newSw
                try SetWindowsStartup(startWithWindows)
                changed := true
            }
        }
        if (newHours != "" && RegExMatch(newHours, "^\d+$")) {
            newH := Integer(newHours)
            if (newH < 0)
                newH := 0
            if (newH > 23)
                newH := 23
            if (newH != resetHour) {
                resetHour := newH
                changed := true
            }
        }
        if (newMinutes != "" && RegExMatch(newMinutes, "^\d+$")) {
            newM := Integer(newMinutes)
            if (newM < 0)
                newM := 0
            if (newM > 59)
                newM := 59
            if (newM != resetMinute) {
                resetMinute := newM
                changed := true
            }
        }
        if (newMenuKey != "") {
            if (newMenuKey != menuKey) {
                menuKey := newMenuKey
                changed := true
            }
        }
        if (newResetKey != "") {
            if (newResetKey != resetKey) {
                resetKey := newResetKey
                changed := true
            }
        }
        if (newAiKey != "") {
            if (newAiKey != aiKey) {
                aiKey := newAiKey
                changed := true
            }
        }
        if (newNoteKey != "") {
            if (newNoteKey != noteKey) {
                noteKey := newNoteKey
                changed := true
            }
        }
        if (newMenuKeyEnabled != "" && RegExMatch(newMenuKeyEnabled, "^\d+$")) {
            newMke := Integer(newMenuKeyEnabled)
            if (newMke != menuKeyEnabled) {
                menuKeyEnabled := newMke
                changed := true
            }
        }
        if (newResetKeyEnabled != "" && RegExMatch(newResetKeyEnabled, "^\d+$")) {
            newRke := Integer(newResetKeyEnabled)
            if (newRke != resetKeyEnabled) {
                resetKeyEnabled := newRke
                changed := true
            }
        }
        if (newAiKeyEnabled != "" && RegExMatch(newAiKeyEnabled, "^\d+$")) {
            newAke := Integer(newAiKeyEnabled)
            if (newAke != aiKeyEnabled) {
                aiKeyEnabled := newAke
                changed := true
            }
        }
        if (newNoteKeyEnabled != "" && RegExMatch(newNoteKeyEnabled, "^\d+$")) {
            newNke := Integer(newNoteKeyEnabled)
            if (newNke != noteKeyEnabled) {
                noteKeyEnabled := newNke
                changed := true
            }
        }
    } catch as err {
        LogError("CheckPendingSettings", "Не удалось разобрать настройки из панели", err.Message)
    }

    if (changed) {
        ; сохраняем в settings.ini, пере-регистрируем хоткеи и обновляем state
        try {
            IniWrite(nick, settingsFile, "Main", "nick")
            IniWrite(norm, settingsFile, "Main", "norm")
            IniWrite(autoResetEnabled, settingsFile, "Main", "autoResetEnabled")
            IniWrite(startWithWindows, settingsFile, "Launcher", "startWithWindows")
            IniWrite(resetHour, settingsFile, "Main", "resetHour")
            IniWrite(resetMinute, settingsFile, "Main", "resetMinute")
            IniWrite(menuKey, settingsFile, "Keys", "menuKey")
            IniWrite(resetKey, settingsFile, "Keys", "resetKey")
            IniWrite(aiKey, settingsFile, "Keys", "aiKey")
            IniWrite(noteKey, settingsFile, "Keys", "noteKey")
            IniWrite(menuKeyEnabled, settingsFile, "Keys", "menuKeyEnabled")
            IniWrite(resetKeyEnabled, settingsFile, "Keys", "resetKeyEnabled")
            IniWrite(aiKeyEnabled, settingsFile, "Keys", "aiKeyEnabled")
            IniWrite(noteKeyEnabled, settingsFile, "Keys", "noteKeyEnabled")
        } catch as err {
            LogError("CheckPendingSettings", "Ошибка записи settings.ini", err.Message)
        }
        try {
            RegisterHotkeys()
        } catch as err {
            LogError("CheckPendingSettings", "Ошибка регистрации хоткеев из панели", err.Message)
        }
        UpdatePMDisplay()
        WriteHudBridgeState()
        WriteSettingsState()
        ShowToast("✓ Настройки из панели применены", 1800)
    }

    try {
        if FileExist(hudBridgePendingSettingsFile)
            FileDelete(hudBridgePendingSettingsFile)
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
            if RegExMatch(line, "^\[\d{2}:\d{2}:\d{2}\] (?:Администратор|Агент поддержки) " . nick . "\[\d+\] для ") {
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
; 👮 ВХОД С АДМИНКОЙ (chatlog)
;  Сканируем только НОВЫЕ строки chatlog (вне CheckLog — тот зависит от Cloud и ника).
;  «[HH:MM:SS] Подключились. Присоединение к игре...» → новый вход в игру: HUD запирается.
;  «[HH:MM:SS] Вы вошли как администратор N уровня»   → админ распознан: HUD открывается.
;  Состояние уходит в hud_state.json (adminConnected/adminUnlocked), чес.js читает его при поллинге.
; =========================
CheckAdminLoginState(*) {
    global logFile, lastAdminLogSize, hudAdminConnected, hudAdminUnlocked
    global zClaimActive, zClaimDeadline
    global zEnterPending, zEnterPendingDeadline

    ; Окно ожидания приёма истекло без ошибки → обращение принято, ждём ответ агента.
    if (zClaimActive && A_TickCount >= zClaimDeadline)
        AcceptZClaim()

    if (logFile = "" || !FileExist(logFile))
        return
    try currentSize := FileGetSize(logFile)
    catch as err {
        LogError("CheckAdminLoginState", "Не удалось получить размер chatlog.txt", err.Message)
        return
    }
    if (lastAdminLogSize = 0) {
        ; Пропускаем уже существующий хвост файла — интересны только новые входы
        lastAdminLogSize := currentSize
        return
    }
    if (currentSize < lastAdminLogSize)
        lastAdminLogSize := 0
    if (currentSize = 0) {
        lastAdminLogSize := 0
        return
    }
    if (currentSize <= lastAdminLogSize)
        return

    try file := FileOpen(logFile, "r")
    catch as err {
        LogError("CheckAdminLoginState", "Не удалось открыть chatlog.txt", err.Message)
        return
    }
    stateChanged := false
    try {
        file.Seek(lastAdminLogSize, 0)
        while (!file.AtEOF) {
            line := file.ReadLine()
            if (!line)
                continue
            ; Новый вход в игру → запираем HUD (ждём сообщение админа)
            if (InStr(line, "Подключились") && InStr(line, "Присоединение к игре")) {
                if (!hudAdminConnected || hudAdminUnlocked) {
                    hudAdminConnected := 1
                    hudAdminUnlocked := 0
                    stateChanged := true
                }
                continue
            }
            ; Распознан вход с админкой → открываем HUD
            if (!hudAdminUnlocked && InStr(line, "вошли как администратор")) {
                hudAdminConnected := 1
                hudAdminUnlocked := 1
                stateChanged := true
            }
            ; Зетка: во время окна ожидания появилась ошибка приёма → обращение не засчитываем
            if (zClaimActive && RegExMatch(line, "i)(обращение не существует|уже занимается|используйте: /z)"))
                CancelZClaim()
            ; Зетка: Enter пустого поля → «Вы не ввели сообщение» → +1 не даём,
            ; но ожидание НЕ сбрасываем: ждём следующий Enter (без ошибки в чате).
            if (zEnterPending && InStr(line, "Вы не ввели сообщение")) {
                zEnterPending := 0
                zEnterPendingDeadline := 0
                WriteHudBridgeState()
            }
        }
        lastAdminLogSize := file.Pos
        file.Close()
    } catch as err {
        try file.Close()
        LogError("CheckAdminLoginState", "Ошибка чтения chatlog.txt", err.Message)
        return
    }

    ; Enter прошёл без ошибки («Вы не ввели сообщение» не появилось) → засчитываем.
    if (zEnterPending && A_TickCount > zEnterPendingDeadline) {
        zEnterPending := 0
        zEnterPendingDeadline := 0
        CompleteZClaim()
    }

    if (stateChanged)
        WriteHudBridgeState()
}

; =========================
; 🎫 ЗЕТКИ АГЕНТА ПОДДЕРЖКИ (chatlog)
;  Агент пишет в чат «/z <номер обращения>» — чес.js перехватывает и шлёт
;  команду zClaim в мост. Приём считается успешным, если в течение ~3 секунд
;  в chatlog НЕ появилась ошибка («обращение не существует» / «уже занимается»
;  / «Используйте: /z [id запроса]»).
;  Зетку засчитываем следующим «чистым» ENTER после принятия (бинди-текст
;  «Приятной игры <3» — тоже считается): если после ENTER в chatlog появилось
;  «Вы не ввели сообщение» — +1 не даём и продолжаем ждать следующий ENTER.
; =========================
ArmZClaim(ticket) {
    global zClaimActive, zClaimTicket, zClaimStartTick, zClaimDeadline, zClaimWindowMs
    global zAwaitAnswer, zEnterDeadline, zEnterPending, zEnterPendingDeadline
    zAwaitAnswer := 0
    zEnterDeadline := 0
    zEnterPending := 0
    zEnterPendingDeadline := 0
    zClaimActive := 1
    zClaimTicket := ticket
    zClaimStartTick := A_TickCount
    zClaimDeadline := zClaimStartTick + zClaimWindowMs
}

CancelZClaim() {
    global zClaimActive, zClaimTicket, zAwaitAnswer, zEnterDeadline, zEnterPending, zEnterPendingDeadline
    zClaimActive := 0
    zClaimTicket := ""
    zAwaitAnswer := 0
    zEnterDeadline := 0
    zEnterPending := 0
    zEnterPendingDeadline := 0
}

; Обращение принято без ошибки → переходим в стадию «ждём ответ агента» (без +1).
AcceptZClaim() {
    global zClaimActive, zClaimTicket, zAwaitAnswer, zEnterDeadline, zEnterWindowMs
    zClaimActive := 0
    zAwaitAnswer := 1
    zEnterDeadline := A_TickCount + zEnterWindowMs
    WriteHudBridgeState()
}

; Агент нажал ENTER после принятия обращения → +1 зетка.
CompleteZClaim() {
    global zClaimActive, zClaimTicket, zCount, zCountFile, zAwaitAnswer, zEnterDeadline, zEnterPending, zEnterPendingDeadline
    if (!zAwaitAnswer)
        return
    zAwaitAnswer := 0
    zEnterDeadline := 0
    zEnterPending := 0
    zEnterPendingDeadline := 0
    zClaimActive := 0
    doneTicket := zClaimTicket
    zClaimTicket := ""
    zCount += 1
    TryFileDelete(zCountFile, "CompleteZClaim", "Ошибка удаления z_count.txt перед записью")
    if (!TryFileAppend(zCount, zCountFile, "CompleteZClaim", "Ошибка записи z_count.txt"))
        ShowToast("⚠ Не удалось сохранить счётчик Z", 2200)
    WriteHudBridgeState()
    ShowToast("Z +1 (обращение #" doneTicket ")", 1500)
}

; ENTER после принятия обращения = момент ответа. Но сразу не считаем:
; в течение zEnterProbeMs смотрим chatlog — если там «Вы не ввели сообщение»,
; Enter был пустым → ждём следующего Enter (завершение в CheckAdminLoginState).
ZAnswerEnter(*) {
    global zAwaitAnswer, zEnterDeadline, zEnterPending, zEnterPendingDeadline, zEnterProbeMs
    if (!zAwaitAnswer)
        return
    if (zEnterDeadline && A_TickCount > zEnterDeadline) {
        CancelZClaim()
        return
    }
    if (zEnterPending)
        return
    zEnterPending := 1
    zEnterPendingDeadline := A_TickCount + zEnterProbeMs
}

; =========================
; ⏰ AUTO RESET
; =========================
CheckAutoReset(*) {
    global autoResetEnabled, resetHour, resetMinute, lastResetDate
    global pmCount, beepPlayed, saveFile, settingsFile, dotRed, StatusDotCtrl, PMCountTextCtrl
    global zCount, zCountFile
    global zClaimActive, zAwaitAnswer, zEnterDeadline, zEnterPending, zEnterPendingDeadline
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
    zCount := 0
    TryFileDelete(zCountFile, "CheckAutoReset", "Ошибка удаления z_count.txt при автосбросе")
    zClaimActive := 0
    zAwaitAnswer := 0
    zEnterDeadline := 0
    zEnterPending := 0
    zEnterPendingDeadline := 0
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

GetScriptPackages() {
    return [
        Map(
            "id", "atools",
            "displayTitle", "aTools",
            "author", "Anthony Fernandez",
            "title", "aTools",
            "description", "Основные команды:`n/wh`n/ddl`n/unl`n/trec`n`nПолная информация на форуме.",
            "authors", "Anthony Fernandez",
            "topic", "https://forum.radmir.games/threads/instrumenty-dlya-administratsii.2840899/",
            "files", [
                Map("name", "aTools.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/aTools.asi", "relativePath", "aTools.asi")
            ],
            "cleanup", ["atools-config.json"],
            "activationCommands", "/wh  /ddl  /unl  /trec"
        ),
        Map(
            "id", "onishi",
            "displayTitle", "Onishi",
            "author", "Takumi Onishi",
            "title", "Onishi",
            "description", "Основные команды:`n/onishi`n`nПри запущенной игре .asi может быть занят — _otools.js ставится в uiresources\\scripts.",
            "authors", "Takumi Onishi",
            "topic", "https://forum.radmir.games/threads/instrumenty-dlya-administratsii.2840899/",
            "files", [
                Map("name", "_otools.js", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/_otools.js", "relativePath", "uiresources\scripts\_otools.js"),
                Map("name", "loader-js.json", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/JS%20code/loader-js.json", "relativePath", "loader-js.json"),
                Map("name", "loader-js.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/loader-js.asi", "relativePath", "loader-js.asi")
            ],
            "activationCommands", "/onishi"
        ),
        Map(
            "id", "fpsunlocker",
            "displayTitle", "FPSUnlocker",
            "author", "Misha Ches",
            "title", "FPSUnlocker",
            "description", "Снимает ограничитель FPS.",
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
            "description", "Свободная камера.`nИспользуется исключительно для съёмок контента.",
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
            "description", "Меняет вашу погоду и время, не затрагивая серверные команды.`n`nОсновные команды:`n/st  /sw",
            "authors", "Misha Ches",
            "topic", "https://github.com/MishaChes/ChesNova/blob/main/files/weather_time.asi",
            "files", [
                Map("name", "weather_time.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/weather_time.asi", "relativePath", "weather_time.asi"),
                Map("name", "weather_time.ini", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/weather_time.ini", "relativePath", "weather_time.ini")
            ],
            "activationCommands", "/st  /sw"
        ),
        Map(
            "id", "clientside",
            "displayTitle", "clientside.dll",
            "author", "Юсиф",
            "title", "clientside.dll",
            "description", "Логирует доп. информацию в краш-лог.",
            "authors", "Юсиф",
            "topic", "https://github.com/MishaChes/ChesNova/blob/main/files/clientside.dll",
            "files", [
                Map("name", "clientside.dll", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/clientside.dll", "relativePath", "clientside.dll")
            ],
            "activationCommands", ""
        ),
        Map(
            "id", "tracer",
            "displayTitle", "Трасера",
            "author", "Юра",
            "title", "Трасера",
            "description", "Отображает трасер пуль.",
            "authors", "Юра",
            "topic", "https://github.com/MishaChes/ChesNova/blob/main/files/BulletTrace.asi",
            "files", [
                Map("name", "BulletTrace.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/BulletTrace.asi", "relativePath", "BulletTrace.asi"),
                Map("name", "BulletTrace.json", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/BulletTrace.json", "relativePath", "BulletTrace.json")
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
CheckForUpdates(manual := false) {
    global CURRENT_VERSION

    try {
        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        if (versionInfo["latest"] = "")
            throw Error("В version.json отсутствует поле latest.")

        if (CompareVersions(versionInfo["latest"], CURRENT_VERSION) > 0)
            LogError("CheckForUpdates", "Доступна новая версия: v" versionInfo["latest"])
    } catch as err {
        LogError("CheckForUpdates", "Не удалось проверить наличие обновлений", err.Message)
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

OpenUpdateDownload(downloadUrl, dlg := "", *) {
    if (downloadUrl = "") {
        LogError("OpenUpdateDownload", "В version.json не указана ссылка для скачивания")
        return
    }

    try {
        Run(downloadUrl)
        if IsObject(dlg)
            dlg.Destroy()
    } catch as err {
        LogError("OpenUpdateDownload", "Не удалось открыть ссылку на обновление", err.Message)
    }
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
        return Map("installed", false, "text", "Не установлен — укажите путь к игре.", "color", "FF5B6B")

    missingFiles := []
    for _, file in package["files"] {
        rel := StrReplace(file["relativePath"], "/", "\")
        while InStr(rel, "\\")
            rel := StrReplace(rel, "\\", "\")
        path := gamePath "\" rel
        ; Папка с именем файла (баг старых установок) ≠ установленный файл
        if !FileExist(path) || DirExist(path)
            missingFiles.Push(file["name"])
    }

    if (missingFiles.Length = 0)
        return Map("installed", true, "text", "Установлен", "color", "41D07A")

    return Map("installed", false, "text", "Не установлен: " JoinArrayRange(missingFiles, 1, missingFiles.Length, ", "), "color", "FF5B6B")
}


SaveNormHistoryFromPanel(origDate, newDate, newPmRaw, newNormRaw) {
    global historyFile

    newDate := NormalizeDayOffDate(newDate)
    if (newDate = "")
        return

    newPm := Trim(newPmRaw)
    newNorm := Trim(newNormRaw)
    if (newPm = "" || newNorm = "")
        return

    newPm += 0
    newNorm += 0
    existingRecords := ReadNormHistoryRecords("SaveNormHistoryFromPanel")
    dateExists := false

    for _, record in existingRecords {
        if (record["date"] = newDate && record["date"] != origDate) {
            dateExists := true
            break
        }
    }

    newRecords := []
    for _, record in existingRecords {
        if (record["date"] = origDate)
            continue
        if (dateExists && record["date"] = newDate)
            continue
        newRecords.Push(record)
    }

    newRecords.Push(Map("date", newDate, "pm", newPm, "norm", newNorm))
    if WriteNormHistoryRecords(newRecords) {
        WriteNormHistoryState()
        ShowToast("✓ Запись нормы сохранена", 1800)
    }
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

ToggleTesterModeFromPanel(enabledRaw) {
    global settingsFile, testerMode

    newValue := Trim(enabledRaw)
    if (newValue = "0" || newValue = "1") {
        newValue := Integer(newValue)
        if (newValue != testerMode) {
            testerMode := newValue
            TryIniWrite(testerMode, settingsFile, "Updates", "testerMode", "ToggleTesterModeFromPanel")
            WriteTesterState()
            ShowToast(testerMode ? "✓ Режим тестировщика включён" : "Режим тестировщика выключен", 1800)
        }
    }
}

; Проверка test-канала из панели (GET /tester/check → hud_commands.ini)
CheckTestUpdatesFromPanel() {
    global testerMode, testerLastCheck, CURRENT_VERSION

    if !testerMode {
        testerLastCheck := "Сначала включи «Я тестировщик»."
        WriteTesterState()
        ShowToast("⚠ Включи режим тестировщика", 2200)
        return
    }

    testerLastCheck := "Проверка…"
    WriteTesterState()

    try {
        versionInfo := ParseVersionManifest(DownloadTestVersionManifest())
        if (versionInfo["latest"] = "")
            throw Error("В Test/Test.json нет поля latest.")

        cmp := CompareVersions(versionInfo["latest"], CURRENT_VERSION)
        status := (cmp > 0) ? "есть более новая test-сборка"
            : (cmp = 0) ? "test совпадает с текущей"
            : "test старше текущей"

        text := "Текущая версия: v" CURRENT_VERSION
            . "`nТестовая latest: v" versionInfo["latest"]
            . "`nСтатус: " status
            . "`n`nЧто нового:`n"
        if (versionInfo["changelog"].Length = 0)
            text .= "• список изменений не указан"
        else
            for _, entry in versionInfo["changelog"]
                text .= "• " entry "`n"
        if (versionInfo["download"] != "")
            text .= "`nСсылка: " versionInfo["download"]

        testerLastCheck := text
        ShowToast("✓ Test-канал проверен", 1800)
    } catch as err {
        testerLastCheck := "Ошибка: " err.Message
        LogError("CheckTestUpdatesFromPanel", "Ошибка test-канала", err.Message)
        ShowToast("⚠ Не удалось проверить test-канал", 2200)
    }
    WriteTesterState()
}

; Скачать test-сборку из панели (GET /tester/download → hud_commands.ini)
DownloadTestUpdateFromPanel() {
    global testerMode, testAhkUrl

    if !testerMode {
        ShowToast("⚠ Включи режим тестировщика", 2200)
        return
    }

    try {
        versionInfo := ParseVersionManifest(DownloadTestVersionManifest())
        downloadUrl := versionInfo["download"]
        if (downloadUrl = "")
            downloadUrl := testAhkUrl
        Run(downloadUrl)
        ShowToast("✓ Открыта ссылка на test-сборку", 1800)
    } catch as err {
        LogError("DownloadTestUpdateFromPanel", "Ошибка скачивания test", err.Message)
        ShowToast("⚠ Не удалось скачать test-сборку", 2200)
    }
}

; Установить test-сборку из панели (GET /tester/install → hud_commands.ini)
InstallTestUpdateFromPanel() {
    global testerMode, basePath, backupPath, testAhkUrl

    if !testerMode {
        ShowToast("⚠ Включи режим тестировщика", 2200)
        return
    }

    mainScript := basePath "\ChesNova.ahk"
    newScript := basePath "\ChesNova_test_new.ahk"

    try {
        ; Прямая ссылка на test-сборку: Test/ChesNova.ahk
        downloadUrl := testAhkUrl

        if !FileExist(mainScript)
            throw Error("Не найден текущий ChesNova.ahk.")

        if FileExist(newScript)
            FileDelete(newScript)

        Download(BustUrl(downloadUrl), newScript)
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

        ShowToast("✓ Test-сборка установлена", 2200)
        WriteTesterState()
    } catch as err {
        if FileExist(newScript)
            try FileDelete(newScript)
        LogError("InstallTestUpdateFromPanel", "Ошибка установки test", err.Message)
        ShowToast("⚠ Не удалось установить test-сборку", 2200)
    }
}

; Откат на стабильный релиз из панели (GET /tester/rollback → hud_commands.ini)
RollbackToStableReleaseFromPanel() {
    global testerMode, basePath, backupPath

    if !testerMode {
        ShowToast("⚠ Включи режим тестировщика", 2200)
        return
    }

    mainScript := basePath "\ChesNova.ahk"
    newScript := basePath "\ChesNova_release_new.ahk"
    stableAhkUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/ChesNova.ahk"

    try {
        if !FileExist(mainScript)
            throw Error("Не найден текущий ChesNova.ahk.")

        versionInfo := ParseVersionManifest(DownloadVersionManifest())
        latest := versionInfo["latest"]
        downloadUrl := versionInfo["download"]

        installUrl := stableAhkUrl
        if (downloadUrl != "" && InStr(StrLower(downloadUrl), ".ahk") && !InStr(StrLower(downloadUrl), ".zip"))
            installUrl := downloadUrl

        if FileExist(newScript)
            FileDelete(newScript)

        Download(BustUrl(installUrl), newScript)
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

        ShowToast("✓ Откат на релиз выполнен", 2200)
        WriteTesterState()
    } catch as err {
        if FileExist(newScript)
            try FileDelete(newScript)
        LogError("RollbackToStableReleaseFromPanel", "Ошибка отката на релиз", err.Message)
        ShowToast("⚠ Не удалось выполнить откат", 2200)
    }
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
SendCloudPing(*) {
    CheckCloudAccess(false, false)
    WriteCloudState()
    WriteHudBridgeState()
}
StartupNetworkInit(*) {
    global checkUpdatesOnStartup, aiEnabled
    CheckCloudAccess(true, true)
    WriteCloudState()
    if aiEnabled
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
GetCloudLocalDataSummary() {
    global pmLogsFile, historyFile

    return "PM логи: " CountFileRecords(pmLogsFile) "  •  Нормы: " CountFileRecords(historyFile)
}

GetCloudLocalDataDetails() {
    global punishmentsFile, daysOffFile, pmCount, norm, zCount

    return "Наказания: " CountFileRecords(punishmentsFile) "  •  Отгулы: " CountFileRecords(daysOffFile) "  •  Сегодня: " pmCount "/" norm "  •  Z: " zCount
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

; Безопасный Integer: пустая/нечисловая строка → default (не падаем на ответе Cloud)
SafeInteger(value, default := 0) {
    value := Trim(value)
    if (value = "" || !RegExMatch(value, "^-?\d+$"))
        return default
    try
        return Integer(value)
    catch
        return default
}

FetchAiConfigFromCloud(*) {
    global nick, appVersion, settingsFile, aiEnabled
    global geminiApiKey, deepseekApiKey, groqApiKey, geminiModel, deepseekModel, groqModel
    global aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiConfigLoaded
    global AiLimitCtrl

    if !aiEnabled
        return false
    if (Trim(nick) = "" || nick = "Nick_Name")
        return false

    keysFound := 0

    ; 1) API-ключи провайдеров из таблицы ai_keys (enabled = true).
    try {
        res := SupaGet("/ai_keys?enabled=eq.true&select=provider,api_key")
        if (res["status"] = 200) {
            text := Trim(res["text"])
            pos := 1
            loop {
                found := RegExMatch(text, '\{[^{}]*\}', &mObj, pos)
                if !found
                    break
                objText := mObj[0]
                prov := JsonUnquote(JsonGetField(objText, "provider"))
                keyVal := JsonUnquote(JsonGetField(objText, "api_key"))
                if (prov = "gemini")
                    geminiApiKey := Trim(keyVal)
                else if (prov = "deepseek")
                    deepseekApiKey := Trim(keyVal)
                else if (prov = "groq")
                    groqApiKey := Trim(keyVal)
                pos := found + mObj.Len[0]
            }
            keysFound := 1
        }
    } catch as err {
        LogError("FetchAiConfigFromCloud", "Не удалось получить ai_keys", err.Message)
    }

    ; 2) Квота администратора из строки admins.
    quotaMerged := false
    try {
        res := SupaGet("/admins?nick=eq." UriEncode(nick) "&select=ai_limit,ai_used,ai_day")
        if (res["status"] = 200 && Trim(res["text"]) != "" && Trim(res["text"]) != "[]") {
            objText := res["text"]
            cloudLimit := SafeInteger(JsonUnquote(JsonGetField(objText, "ai_limit")))
            todayIso := FormatTime(, "yyyy-MM-dd")
            dayRaw := JsonUnquote(JsonGetField(objText, "ai_day"))
            serverUsed := SafeInteger(JsonUnquote(JsonGetField(objText, "ai_used")))
            usedToday := (SubStr(dayRaw, 1, 10) = todayIso) ? serverUsed : 0
            remaining := (cloudLimit > 0) ? Max(0, cloudLimit - usedToday) : 0
            MergeAiQuotaFromCloud(cloudLimit, usedToday, remaining)
            quotaMerged := true
        }
    } catch as err {
        LogError("FetchAiConfigFromCloud", "Не удалось получить квоту", err.Message)
    }

    if (!keysFound && !quotaMerged)
        return false

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
    global nick, aiDailyLimit, aiDailyUsed, aiDailyRemaining, aiQuotaDate, aiEnabled

    if !aiEnabled
        return Map("ok", false, "reason", "AI отключён в настройках")
    if (Trim(nick) = "")
        return Map("ok", false, "reason", "Нет ника")

    today := FormatTime(, "yyyyMMdd")
    ; Локальный стоп, если за сегодня лимит уже выбран
    if (aiDailyLimit > 0 && aiQuotaDate = today && aiDailyUsed >= aiDailyLimit) {
        RefreshAiLimitUi()
        return Map("ok", false, "reason", "Лимит на сегодня исчерпан (" aiDailyUsed "/" aiDailyLimit ")")
    }

    todayIso := FormatTime(, "yyyy-MM-dd")

    ; Читаем серверное состояние квоты из строки admins.
    srvLimit := 0
    srvUsed := 0
    srvDay := ""
    try {
        res := SupaGet("/admins?nick=eq." UriEncode(nick) "&select=ai_limit,ai_used,ai_day")
        if (res["status"] != 200)
            return Map("ok", false, "reason", "Supabase HTTP " res["status"])
        if (Trim(res["text"]) = "" || Trim(res["text"]) = "[]")
            return Map("ok", false, "reason", "Ник не найден в базе")
        srvLimit := SafeInteger(JsonUnquote(JsonGetField(res["text"], "ai_limit")))
        srvUsed := SafeInteger(JsonUnquote(JsonGetField(res["text"], "ai_used")))
        srvDay := SubStr(JsonUnquote(JsonGetField(res["text"], "ai_day")), 1, 10)
    } catch as err {
        return Map("ok", false, "reason", err.Message)
    }

    ; Эффективные значения: сервер приоритетен, локальный used учитываем максимумом за сегодня.
    effLimit := (srvLimit > 0) ? srvLimit : aiDailyLimit
    effUsed := (srvDay = todayIso) ? Max(srvUsed, aiDailyUsed) : aiDailyUsed

    if (effLimit > 0 && effUsed >= effLimit) {
        MergeAiQuotaFromCloud(effLimit, effUsed, 0)
        RefreshAiLimitUi()
        return Map("ok", false, "reason", "Лимит на сегодня исчерпан (" effUsed "/" effLimit ")")
    }

    newUsed := effUsed + 1
    patchOk := false
    try {
        patched := SupaPatch("/admins?nick=eq." UriEncode(nick),
            '{"ai_used":' newUsed ',"ai_day":"' todayIso '"}')
        if (patched["status"] >= 200 && patched["status"] < 300)
            patchOk := true
    } catch {
        patchOk := false
    }

    if !patchOk {
        ; Сеть моргнула при списании: если локально запас есть — считаем локально.
        if (effLimit <= 0 || aiDailyUsed < effLimit) {
            ApplySuccessfulAiUse(effLimit, aiDailyUsed + 1, Max(0, effLimit - aiDailyUsed - 1))
            return Map("ok", true, "reason", "")
        }
        return Map("ok", false, "reason", "Не удалось обновить квоту в Cloud")
    }

    ApplySuccessfulAiUse(effLimit, newUsed, Max(0, effLimit - newUsed))
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
    global aiConfigLoaded, aiDailyLimit, aiDailyUsed, aiDailyRemaining, cloudAccessState, aiEnabled
    if !aiEnabled
        return "AI отключён (включите в Настройках)"
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

ToggleGamePanel(*) {
    global panelToggleSeq
    panelToggleSeq += 1
    WriteHudBridgeState()
}

ToggleGameHud(*) {
    global hudBridgeVisible
    hudBridgeVisible := hudBridgeVisible ? 0 : 1
    WriteHudBridgeState()
    if hudBridgeVisible
        ShowToast("HUD: показан", 1200)
    else
        ShowToast("HUD: скрыт", 1200)
}

ToggleNotes(*) {
    global noteToggleSeq
    noteToggleSeq += 1
    WriteHudBridgeState()
}

; Хоткей сброса нормы → запрос подтверждения в игровой панели (CEF)
PromptManualNormReset(*) {
    global pendingNormResetConfirm
    pendingNormResetConfirm := 1
    WriteHudBridgeState()
}

CancelPendingNormReset() {
    global pendingNormResetConfirm
    pendingNormResetConfirm := 0
    WriteHudBridgeState()
}

DoManualNormReset() {
    global pmCount, beepPlayed, saveFile, settingsFile, lastResetDate
    global StatusDotCtrl, PMCountTextCtrl, dotRed, pendingNormResetConfirm
    global zCount, zCountFile
    global zClaimActive, zAwaitAnswer, zEnterDeadline, zEnterPending, zEnterPendingDeadline

    pendingNormResetConfirm := 0
    SaveDayStats()
    pmCount := 0
    TryFileDelete(saveFile, "DoManualNormReset", "Ошибка удаления pm_count.txt")
    zCount := 0
    TryFileDelete(zCountFile, "DoManualNormReset", "Ошибка удаления z_count.txt")
    zClaimActive := 0
    zAwaitAnswer := 0
    zEnterDeadline := 0
    zEnterPending := 0
    zEnterPendingDeadline := 0
    lastResetDate := FormatTime(A_Now, "yyyyMMdd")
    TryIniWrite(lastResetDate, settingsFile, "Main", "lastResetDate", "DoManualNormReset")
    if IsObject(PMCountTextCtrl)
        PMCountTextCtrl.Text := "PM:0"
    UpdatePMDisplay()
    if IsObject(StatusDotCtrl) {
        StatusDotCtrl.Text := "●"
        StatusDotCtrl.SetFont("c" dotRed)
    }
    beepPlayed := false
    AppendPmLog("Действие", "Сброшен счетчик PM (вручную)")
    WriteHudBridgeState()
    WriteNormHistoryState()
    WritePmLogsState()
    ShowToast("✓ Норма сброшена", 1800)
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

; ============================================================
; ☁️ SUPABASE REST (замена Google Apps Script)
; ============================================================

SupaGet(path) {
    global supabaseRest, supabaseApiKey
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", supabaseRest path, true)
    try http.SetTimeouts(15000, 15000, 30000, 45000)
    http.SetRequestHeader("apikey", supabaseApiKey)
    http.SetRequestHeader("Authorization", "Bearer " supabaseApiKey)
    http.SetRequestHeader("Cache-Control", "no-cache")
    http.Send()
    HttpWaitAsync(http, 110000)
    return Map("status", http.Status, "text", HttpResponseTextUtf8(http))
}

; Прямой глагол PATCH (проверено: Supabase/PostgREST + WinHttpRequest корректно обновляют строки).
SupaPatch(path, jsonBody) {
    global supabaseRest, supabaseApiKey
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("PATCH", supabaseRest path, true)
    try http.SetTimeouts(15000, 15000, 30000, 45000)
    http.SetRequestHeader("apikey", supabaseApiKey)
    http.SetRequestHeader("Authorization", "Bearer " supabaseApiKey)
    http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    http.SetRequestHeader("Prefer", "return=minimal")
    http.Send(jsonBody)
    HttpWaitAsync(http, 110000)
    return Map("status", http.Status, "text", HttpResponseTextUtf8(http))
}

; Достать значение поля из JSON-текста: строка в кавычках / true / false / null / число.
JsonGetField(jsonText, key) {
    m := ""
    rx := '"' key '"\s*:\s*("(?:[^"\\]|\\.)*"|true|false|null|-?\d+(?:\.\d+)?)'
    if RegExMatch(jsonText, rx, &m)
        return m[1]
    return ""
}

; Убрать кавычки и базовые escape-последовательности.
JsonUnquote(val) {
    val := Trim(val)
    if (val = "" || val = "null")
        return ""
    if (SubStr(val, 1, 1) != '"')
        return val
    inner := SubStr(val, 2, StrLen(val) - 2)
    inner := StrReplace(inner, '\"', '"')
    inner := StrReplace(inner, '\\', '\')
    inner := StrReplace(inner, '\n', '`n')
    inner := StrReplace(inner, '\r', '`r')
    inner := StrReplace(inner, '\/', '/')
    return inner
}



RegisterAiChatHotstring() {
    global aiChatHotstringRegistered, aiKeyEnabled, aiEnabled
    if aiChatHotstringRegistered {
        try Hotstring(":*?B0X:/ai ", "Off")
        try Hotstring(":*?B0X:/AI ", "Off")
        aiChatHotstringRegistered := false
    }
    if !aiEnabled
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
    global aiRequestBusy, aiProvider, aiEnabled
    question := Trim(question)
    if (question = "" || aiRequestBusy)
        return
    if !aiEnabled {
        PushAiToGameHud(question, "AI отключён в настройках ChesNova", true)
        return
    }

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
        ; без тоста AHK — ответ только в in-game панели (ches.js)
    } catch as err {
        LogError("RunAiFromGameChat", GetAiProviderLabel(), err.Message)
        PushAiToGameHud(question, "Ошибка: " err.Message, true)
    } finally {
        aiRequestBusy := false
        try {
            WriteAiState()
        }
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

; Hotkeys: HUD (aiKey), ручной сброс нормы (resetKey), хотстринг /ai.
RegisterHotkeys() {
    global aiKey, aiKeyEnabled, resetKey, resetKeyEnabled, menuKey, menuKeyEnabled, noteKey, noteKeyEnabled, RegisteredStandardHotkeys

    for _, key in RegisteredStandardHotkeys {
        try Hotkey(key, "Off")
    }
    RegisteredStandardHotkeys := []

    if menuKeyEnabled {
        try {
            Hotkey(menuKey, ToggleGamePanel, "On")
            RegisteredStandardHotkeys.Push(menuKey)
        } catch as err {
            LogError("RegisterHotkeys", "Не удалось зарегистрировать menuKey: " menuKey, err.Message)
        }
    }
    if aiKeyEnabled {
        try {
            Hotkey(aiKey, ToggleGameHud, "On")
            RegisteredStandardHotkeys.Push(aiKey)
        } catch as err {
            LogError("RegisterHotkeys", "Не удалось зарегистрировать aiKey: " aiKey, err.Message)
        }
    }
    if resetKeyEnabled {
        try {
            Hotkey(resetKey, PromptManualNormReset, "On")
            RegisteredStandardHotkeys.Push(resetKey)
        } catch as err {
            LogError("RegisterHotkeys", "Не удалось зарегистрировать resetKey: " resetKey, err.Message)
        }
    }
    if noteKeyEnabled {
        try {
            Hotkey(noteKey, ToggleNotes, "On")
            RegisteredStandardHotkeys.Push(noteKey)
        } catch as err {
            LogError("RegisterHotkeys", "Не удалось зарегистрировать noteKey: " noteKey, err.Message)
        }
    }
    try {
        Hotkey("~Enter", ZAnswerEnter, "On")
        RegisteredStandardHotkeys.Push("~Enter")
        Hotkey("~NumpadEnter", ZAnswerEnter, "On")
        RegisteredStandardHotkeys.Push("~NumpadEnter")
    } catch as err {
        LogError("RegisterHotkeys", "Не удалось зарегистрировать Enter-хук зеток", err.Message)
    }
    RegisterAiChatHotstring()
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

; Окно при фатальной ошибке: скрипт не смог запуститься / упал во время работы.
ChesNova_ShowErrorBox(err, *) {
    loc := ""
    try loc := "`nФайл: " err.File "`nСтрока: " err.Line
    LogError("Ошибка выполнения", err.Message, Trim(loc, "`n"))
    MsgBox("ChesNova не смогла запуститься и будет закрыта.`n`n"
        . "Ошибка: " err.Message . loc "`n`n"
        . "Подробности: Documents\ChesNova\logs\errors.log",
        "ChesNova — Ошибка", "Icon2")
    ExitApp(1)
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
    global nick, userNick

    nick := Trim(nick)
    if (nick != "" && nick != "Nick_Name")
        userNick := nick
    ; Без GUI ник не запрашивается — задаётся в панели (Cloud → ник администратора).
    return
}
; HTTP GET с таймаутами. resolve/connect/send/receive в мс.
HttpGetText(url, resolveMs := 15000, connectMs := 15000, sendMs := 30000, receiveMs := 45000) {
    return HttpGetTextAsync(url, resolveMs, connectMs, sendMs, receiveMs)
}

FormatHttpError(err) {
    msg := err.Message
    if InStr(msg, "0x80072EE2") || InStr(msg, "истекло") || InStr(msg, "timed out") || InStr(msg, "timeout")
        return "Сервер Cloud не ответил вовремя (таймаут).`nПроверьте интернет или повторите через минуту."
    if InStr(msg, "0x80072EFD") || InStr(msg, "0x80072EE7")
        return "Нет связи с интернетом или DNS не резолвит адрес.`nПроверьте сеть / VPN / антивирус."
    if InStr(msg, "0x80072F7D") || InStr(msg, "0x80072F8F")
        return "Проблема с SSL/HTTPS.`nПроверьте системное время и антивирус-HTTPS-сканер."
    return msg
}

CheckCloudAccess(exitOnDenied := true, promptOnDenied := true) {
    global nick, cloudAccessState, cloudAccessMessage, cloudLastCheck, appVersion
    global supabaseRest

    if (Trim(nick) = "" || nick = "Nick_Name") {
        cloudAccessState := "denied"
        cloudAccessMessage := "Ник не задан"
        if (promptOnDenied)
            MsgBox("Задайте ник в панели (Cloud).", "ChesNova", "Iconx")
        return false
    }

    response := ""
    lastErr := ""

    ; До 2 попыток: сеть может моргнуть при старте.
    loop 2 {
        try {
            result := SupaGet("/admins?nick=eq." UriEncode(nick) "&select=nick,status")
            if (result["status"] != 200)
                throw Error("Supabase HTTP " result["status"])
            response := Trim(result["text"])
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

    if (response = "" || response = "[]") {
        cloudAccessState := "denied"
        cloudAccessMessage := "Ник не найден: " nick
        LogError("CheckCloudAccess", "Ник не найден в базе доступа: " nick)

        if (promptOnDenied && exitOnDenied)
            MsgBox("Ник «" nick "» не найден в базе доступа.", "ChesNova", "Iconx")
        if (exitOnDenied)
            ExitApp()

        return false
    }

    statusRaw := JsonUnquote(JsonGetField(response, "status"))
    if (statusRaw = "false") {
        cloudAccessState := "blocked"
        cloudAccessMessage := "Доступ заблокирован"

        if (promptOnDenied)
            MsgBox("Доступ заблокирован.", "ChesNova", "Iconx")

        if (exitOnDenied)
            ExitApp()

        return false
    }

    cloudAccessState := "ok"
    cloudAccessMessage := "Доступ подтверждён"

    ; Отчёт о запуске: last_launch + version (не влияет на результат проверки).
    try {
        stamp := FormatTime(A_NowUTC, "yyyy-MM-dd'T'HH:mm:ss") "Z"
        SupaPatch("/admins?nick=eq." UriEncode(nick),
            '{"last_launch":"' stamp '","version":"' appVersion '"}')
    } catch as err {
        LogError("CheckCloudAccess", "Не удалось отправить отчёт о запуске", err.Message)
    }

    return true
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
; ============================================================
; 🔇 БЕЗ GUI: визуал полностью отключён, остались только «мозги».
; Пустышки сохраняют совместимость с логикой, которая вызывала окна/тосты.
; ============================================================

MsgBox(params*) {
    return
}

ShowToast(message, durationMs := 1600) {
    return
}

ShowAppDialog(title, message, buttons := "OK", accentColor := "") {
    ; Молчаливое подтверждение: действие продолжается по умолчанию.
    if (buttons = "YesNo")
        return "Yes"
    return "OK"
}

RefreshDashboardView(*) {
    return
}

; ============================================================
; HEADLESS STUBS: удалённые GUI-функции, оставленные как no-op,
; чтобы вызовы из логики не падали в рантайме.
; ============================================================

RefreshSettingsView(*) {
    return
}

RefreshScriptsView(*) {
    return
}

DownloadTestVersionManifest() {
    global testVersionInfoUrl

    ; Уникальный параметр и no-cache не дают GitHub CDN вернуть старую копию JSON.
    requestUrl := testVersionInfoUrl "?nocache=" A_Now "_" A_TickCount
    result := HttpGetText(requestUrl)
    if (result["status"] != 200)
        throw Error("GitHub вернул HTTP " result["status"] ".")
    return result["text"]
}

; Скачать актуальный список транспорта (JS code/vehicles.json на GitHub) и закэшировать локально.
UpdateVehiclesData(manual := false) {
    global vehiclesUrl, hudBridgeVehiclesFile

    try {
        requestUrl := vehiclesUrl "?nocache=" A_Now "_" A_TickCount
        result := HttpGetText(requestUrl)
        if (result["status"] != 200)
            throw Error("GitHub вернул HTTP " result["status"] ".")
        text := Trim(result["text"])
        if (text = "" || !InStr(text, "vehicles"))
            throw Error("Ответ не похож на список транспорта.")

        try {
            f := FileOpen(hudBridgeVehiclesFile, "w", "UTF-8-RAW")
            f.Write(text)
            f.Close()
        }
        if (manual)
            ShowToast("✓ Список транспорта обновлён", 2000)
    } catch as err {
        LogError("UpdateVehiclesData", "Не удалось обновить список транспорта", err.Message)
        if (manual)
            ShowToast("⚠ Не удалось обновить список транспорта", 2200)
    }
}

; Скачать JSON правил (Info/*.json на GitHub) в локальные файлы для панели.
UpdateRulesData(manual := false) {
    global rulesCrimeUrl, rulesGovUrl, rulesCommonUrl
    global hudBridgeRulesCrimeFile, hudBridgeRulesGovFile, hudBridgeRulesCommonFile

    pairs := [
        [rulesCrimeUrl, hudBridgeRulesCrimeFile, "crime"],
        [rulesGovUrl, hudBridgeRulesGovFile, "gov"],
        [rulesCommonUrl, hudBridgeRulesCommonFile, "common"]
    ]
    failed := 0
    for pair in pairs {
        try {
            requestUrl := pair[1] "?nocache=" A_Now "_" A_TickCount
            result := HttpGetText(requestUrl)
            if (result["status"] != 200)
                throw Error("HTTP " result["status"])
            text := Trim(result["text"])
            if (text = "" || !InStr(text, "sections"))
                throw Error("Пустой ответ")
            try {
                f := FileOpen(pair[2], "w", "UTF-8-RAW")
                f.Write(text)
                f.Close()
            }
        } catch as err {
            failed += 1
            LogError("UpdateRulesData", "Не удалось скачать правила (" pair[3] ")", err.Message)
        }
    }
    if (manual) {
        if (failed = 0)
            ShowToast("✓ Правила обновлены", 2000)
        else
            ShowToast("⚠ Правила: не удалось обновить " failed " из 3", 2400)
    }
}

; Скачать бинарный файл (GET) и сохранить в filePath.
DownloadBinaryToFile(url, filePath) {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, true)
    try http.SetTimeouts(15000, 15000, 30000, 60000)
    http.SetRequestHeader("Cache-Control", "no-cache")
    http.SetRequestHeader("Pragma", "no-cache")
    http.Send()
    HttpWaitAsync(http, 110000)
    if (http.Status != 200)
        throw Error("GitHub вернул HTTP " http.Status ".")
    stream := ComObject("ADODB.Stream")
    stream.Type := 1
    stream.Open()
    stream.Write(http.ResponseBody)
    stream.SaveToFile(filePath, 2)
    stream.Close()
}

; Скачать карту DM-зоны (files/map.jpg на GitHub) в локальный файл для панели.
DownloadDmMap(manual := false) {
    global dmMapUrl, hudBridgeDmMapFile

    try {
        requestUrl := dmMapUrl "?nocache=" A_Now "_" A_TickCount
        DownloadBinaryToFile(requestUrl, hudBridgeDmMapFile)
        if (manual)
            ShowToast("✓ Карта DM-зоны обновлена", 2000)
    } catch as err {
        LogError("DownloadDmMap", "Не удалось скачать карту DM-зоны", err.Message)
        if (manual)
            ShowToast("⚠ Не удалось скачать карту DM-зоны", 2200)
    }
}
