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

A_TrayMenu.Delete() ; убираем стандартные пункты

A_TrayMenu.Add("🏠 Открыть меню", TrayOpenMenu)
A_TrayMenu.Add("⚙ Настройки", TrayOpenSettings)
A_TrayMenu.Add("🔄 Центрировать HUD", TrayCenterHUD)
A_TrayMenu.Add()
A_TrayMenu.Add("❌ Выход", TrayExit)

A_TrayMenu.Default := "🏠 Открыть меню"
A_TrayMenu.ClickCount := 1

TrayOpenMenu(*) {
    OpenMenu()
}

TrayOpenSettings(*) {
    BuildMainWindow("Settings")
}

TrayCenterHUD(*) {
    CenterGUI()
}

TrayExit(*) {
    ExitApp()
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
CURRENT_VERSION := "10.4"
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
errorsLogFile := logPath "\errors.log"
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
startWithWindows := 0
resetHour := 0
resetMinute := 0
lastResetDate := ""
menuKey := "F10"
resetKey := "F9"
centerKey := "F5"
 hideKey := "F2"
 hudDesign := "Compact"
; Тёмная оболочка; макет определяет расположение элементов.
colorBg := "0B0E14"
colorSidebar := "10151E"
colorCard := "171D28"
colorCardAlt := "222A37"
colorAccent := "6C63FF"
colorText := "F5F7FB"
colorMuted := "939CAC"
colorGreen := "41D07A"
colorRed := "FF5B6B"
colorYellow := "F6A623"
dotRed := colorRed
dotGreen := colorGreen
guiX := "Center"
guiY := "Center"
menuX := "Center"
menuY := "Center"
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
        centerKey := IniRead(settingsFile, "Keys", "centerKey", "F5")
        hideKey := IniRead(settingsFile, "Keys", "hideKey", "F2")
        autoResetEnabled := IniRead(settingsFile, "Main", "autoResetEnabled", 0)
        bindsEnabled := IniRead(settingsFile, "Main", "bindsEnabled", 0)
        checkUpdatesOnStartup := IniRead(settingsFile, "Updates", "checkOnStartup", 1)
        startWithWindows := IniRead(settingsFile, "Launcher", "startWithWindows", 0)
        resetHour := IniRead(settingsFile, "Main", "resetHour", 0)
        resetMinute := IniRead(settingsFile, "Main", "resetMinute", 0)
        lastResetDate := IniRead(settingsFile, "Main", "lastResetDate", "")
        guiX := IniRead(settingsFile, "GUI", "guiX", "Center")
        guiY := IniRead(settingsFile, "GUI", "guiY", "Center")
        menuX := IniRead(settingsFile, "GUI", "menuX", "Center")
        menuY := IniRead(settingsFile, "GUI", "menuY", "Center")
        hudDesign := IniRead(settingsFile, "GUI", "hudDesign", "Compact")
    } catch as err {
        LogError("LoadSettings", "Повреждён settings.ini или ошибка чтения настроек", err.Message)
        MsgBox("Повреждён settings.ini или не удалось прочитать настройки.`nБудут использованы значения по умолчанию.`n`n" err.Message, "ChesNova", "Iconx")
    }
}

nick := Trim(nick)
userNick := nick
norm += 0
autoResetEnabled += 0
bindsEnabled += 0
checkUpdatesOnStartup += 0
startWithWindows += 0

cloudAccessState := "unknown"
cloudAccessMessage := "Ожидает проверки"
cloudLastCheck := ""
accessUrl := "https://script.google.com/macros/s/AKfycbx1qWofvCKam_l4JGZKXegu6wvYXXD_GOBlhh_v4QjPq0Un65ngTeaf3zR95m7seodwMw/exec"
EnsureNickBeforeCloudAccess()
CheckCloudAccess(true, true)
SetTimer(SendCloudPing, 3600000)
versionInfoUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/version.json"
if (checkUpdatesOnStartup)
    CheckForUpdates()
notifications := []
notificationStates := Map()
LoadNotificationsCache()
LoadNotificationStates()
CheckNotifications()
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
guiHidden := false
selectedPunishmentDate := ""
selectedPunishmentType := "ban"
selectedPunishmentDays := 10
punishmentSearch := ""

MainGui := ""
StatusDotCtrl := ""
PMCountTextCtrl := ""
HudNickCtrl := ""
HudStatsCtrl := ""
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
SetCenterKeyCtrl := ""
SetHideKeyCtrl := ""
SetHudDesignCtrl := ""
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
DashboardVersionCtrl := ""
DashboardNormTitleCtrl := ""
DashboardNormPmCtrl := ""
DashboardNormRemainingCtrl := ""
DashboardNormPercentCtrl := ""
DashboardProgressBgCtrl := ""
DashboardProgressFillCtrl := ""
DashboardLogFileCtrl := ""
DashboardDaysOffMonthCtrl := ""
HelpEditCtrl := ""
ErrorsLogTextCtrl := ""
CloudNickCtrl := ""
CloudStatusCtrl := ""
CloudAccessTextCtrl := ""
CloudLastCheckCtrl := ""
DiagnosticTextCtrl := ""
ScriptsGamePathCtrl := ""
ScriptPackageStatusCtrls := Map()
NotificationButtonCtrl := ""
NotificationIndicatorCtrl := ""
NotificationsGui := ""
HistoryGui := ""
PunishmentsGui := ""
HelpGui := ""
ResetConfirmGui := ""

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
; 🖥 MAIN GUI
; =========================
MainGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "PM Counter")
MainGui.BackColor := colorCard
MainGui.MarginX := 6
MainGui.MarginY := 4
MainGui.SetFont("s8 Bold cFFFFFF", "Segoe UI")
StatusDotCtrl := MainGui.Add("Text", "vStatusDot x6 y5 c" dotRed, "●")
PMCountTextCtrl := MainGui.Add("Text", "vPMCountText x20 y4 w68 cFFFFFF", "Загрузка...")

if (guiX = "Center")
    MainGui.Show("w90 h24 xCenter yCenter")
else
    MainGui.Show("w90 h24 x" guiX " y" guiY)

BuildMainHud()

OnMessage(0x201, WM_LBUTTONDOWN)
OnMessage(0x84, WM_NCHITTEST)

; =========================
; ⌨️ HOTKEYS
; =========================
RegisterHotkeys()
InitializeBinds()
SetTimer(CheckLog, 1000)
SetTimer(CheckAutoReset, 30000)

UpdatePMDisplay()

; ------------------------------------------------------------
; 02. Statistics helpers
; ------------------------------------------------------------

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
}

BuildMainHud() {
    global MainGui, StatusDotCtrl, PMCountTextCtrl, HudNickCtrl, HudStatsCtrl
    global hudDesign, guiX, guiY, colorCard, colorAccent, colorText, colorMuted, dotRed, nick, pmCount

    if IsObject(MainGui)
        try MainGui.Destroy()

    StatusDotCtrl := ""
    PMCountTextCtrl := ""
    HudNickCtrl := ""
    HudStatsCtrl := ""
    MainGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "PM Counter")
    MainGui.BackColor := colorCard
    MainGui.MarginX := 6
    MainGui.MarginY := 4

    if (hudDesign = "Expanded") {
        MainGui.SetFont("s8 c" colorText, "Segoe UI")
        HudNickCtrl := MainGui.Add("Text", "x4 y4 w142 h17 Center c" colorText, nick)
        MainGui.Add("Text", "x4 y23 w142 h1 Background2B3443")
        PMCountTextCtrl := MainGui.Add("Text", "x4 y29 w142 h19 Center c" colorText, "PM: " pmCount)
        MainGui.Add("Text", "x48 y51 w54 h2 Background" colorAccent)
        HudStatsCtrl := MainGui.Add("Text", "x4 y58 w142 h45 Center c" colorMuted, BuildHudPunishmentStats())
        if (guiX = "Center")
            MainGui.Show("w150 h108 xCenter yCenter")
        else
            MainGui.Show("w150 h108 x" guiX " y" guiY)
    } else {
        MainGui.SetFont("s8 Bold c" colorText, "Segoe UI")
        StatusDotCtrl := MainGui.Add("Text", "x6 y5 c" dotRed, "●")
        PMCountTextCtrl := MainGui.Add("Text", "x20 y4 w68 c" colorText, "PM: " pmCount)
        if (guiX = "Center")
            MainGui.Show("w90 h24 xCenter yCenter")
        else
            MainGui.Show("w90 h24 x" guiX " y" guiY)
    }
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

            details .= "[" part[1] " " part[2] "] " rowType "`n"
            details .= "Администратор: " part[3] "`n"
            details .= "Игрок: " part[4] "`n"
            details .= "Причина: " part[6] "`n"
            if (!noDurationTypes.Has(rowType))
                details .= "Срок: " duration "`n"
            details .= "`n"
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
        controlName := PunishmentTypeControlName(type)
        buttonLabel := (type = "all") ? "Все" : type
        buttonText := buttonLabel " (" CountPunishmentsByType(type, days, search) ")"
        if (PunishmentButtonCtrls.Has(type) && IsObject(PunishmentButtonCtrls[type]))
            PunishmentButtonCtrls[type].Text := buttonText
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
        MsgBox("Не удалось сохранить историю нормы.`nПодробности записаны в errors.log.", "Ошибка", "Iconx")
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
            if (part.Length >= 4)
                logsText .= "[" part[1] " " part[2] "] " part[3] ": " JoinArrayFrom(part, 4, "|") "`n`n"
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

IsDayOff(date) {
    global daysOffFile

    date := NormalizeDayOffDate(date)
    if (date = "" || !FileExist(daysOffFile))
        return false

    for _, line in ReadFileLines(daysOffFile) {
        if (NormalizeDayOffDate(line) = date)
            return true
    }

    return false
}

CountDaysOffCurrentMonth() {
    global daysOffFile

    count := 0
    monthPrefix := FormatTime(A_Now, "yyyy-MM")

    if !FileExist(daysOffFile)
        return 0

    for _, line in ReadFileLines(daysOffFile) {
        lineDate := NormalizeDayOffDate(line)
        if (lineDate != "" && SubStr(lineDate, 1, 7) = monthPrefix)
            count++
    }

    return count
}

AddDayOff(*) {
    global daysOffFile, DaysOffDateCtrl

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

    if !TryFileAppend(dayOffDate "`n", daysOffFile, "AddDayOff", "Ошибка записи days_off.csv")
        return
    DaysOffDateCtrl.Value := ""
    FillDaysOffList()
    FillNormHistoryList()
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

DeleteSelectedDayOff(*) {
    global daysOffFile, DaysOffListCtrl

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

    newLines := []
    if FileExist(daysOffFile) {
        for _, line in ReadFileLines(daysOffFile) {
            lineDate := NormalizeDayOffDate(line)
            if (lineDate != "" && !ArrayHasValue(selectedDates, lineDate))
                newLines.Push(lineDate)
        }
    }

    try {
        file := FileOpen(daysOffFile, "w")
        for _, lineDate in newLines
            file.WriteLine(lineDate)
        file.Close()
    } catch as err {
        LogError("DeleteSelectedDayOff", "Ошибка записи days_off.csv", err.Message)
        MsgBox("Не удалось сохранить список отгулов.`n`n" err.Message, "Ошибка", "Iconx")
        return
    }

    FillDaysOffList()
    FillNormHistoryList()
}

FillDaysOffList() {
    global daysOffFile, DaysOffListCtrl

    if !IsObject(DaysOffListCtrl)
        return

    DaysOffListCtrl.Delete()
    lines := []

    if FileExist(daysOffFile) {
        for _, line in ReadFileLines(daysOffFile) {
            lineDate := NormalizeDayOffDate(line)
            if (lineDate != "")
                lines.Push(lineDate)
        }
    }

    lines := SortRecordsNewestFirst(lines, "dayoff")
    for _, lineDate in lines
        DaysOffListCtrl.Add(, lineDate)
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
            return "Клавишный бинд"
        case "hotstring":
            return "Текстовая замена"
        case "macro":
            return "Массовые сообщения"
        default:
            return "Клавишный бинд"
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
            message := "Не удалось зарегистрировать бинд " . Chr(34) . bind["name"] . Chr(34) . ":`n" . err.Message
            MsgBox(message, "Бинды", "Icon!")
        }
    }
}

UnregisterCustomBinds() {
    global RegisteredBindTriggers

    for _, item in RegisteredBindTriggers {
        try {
            if (item["type"] = "hotstring" || item["type"] = "macro")
                Hotstring(item["trigger"], , "Off")
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
    global diagnosticLastCheckMs, diagnosticLastProcessedLines, diagnosticLastPmChanges, diagnosticLastLogSize
    checkLogStartedAt := A_TickCount
    processedLineCount := 0
    pmCountChanged := false
    if (logFile = "" || !FileExist(logFile))
        return

    try currentSize := FileGetSize(logFile)
    catch as err {
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

    try file := FileOpen(logFile, "r")
    catch as err {
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
        LogError("CheckLog", "Ошибка чтения chatlog.txt", err.Message)
        return
    }

    diagnosticLastCheckMs := A_TickCount - checkLogStartedAt
    diagnosticLastProcessedLines := processedLineCount
    diagnosticLastPmChanges := pmCountChanged ? 1 : 0
    diagnosticLastLogSize := currentSize

    if !pmCountChanged
        return

    TryFileDelete(saveFile, "CheckLog", "Ошибка удаления pm_count.txt перед сохранением")
    if !TryFileAppend(pmCount, saveFile, "CheckLog", "Ошибка записи pm_count.txt")
        MsgBox("Не удалось сохранить счётчик PM.`nПодробности записаны в errors.log.", "Ошибка", "Iconx")

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
        MsgBox("Не удалось сохранить дату автосброса.`nПодробности записаны в errors.log.", "Ошибка", "Iconx")
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
ToggleGUI(*) {
    global guiHidden, guiX, guiY, settingsFile, MainGui
    if (guiHidden) {
        MainGui.Show("x" guiX " y" guiY)
        guiHidden := false
    } else {
        MainGui.GetPos(&guiX, &guiY)
        TryIniWrite(guiX, settingsFile, "GUI", "guiX", "ToggleGUI")
        TryIniWrite(guiY, settingsFile, "GUI", "guiY", "ToggleGUI")
        MainGui.Hide()
        guiHidden := true
    }
}

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
            SettingsGui.Show("w920 h" Max(590, 174 + GetScriptPackages().Length * 250) " x" menuX " y" menuY)
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
    SettingsGui.Add("Text", "x0 y27 w920 h1 Background2B3443")
    SettingsGui.Add("Text", "x215 y28 w1 h" (windowHeight - 28) " Background2B3443")
    SettingsGui.SetFont("s10 Bold c" colorText, "Segoe UI")
    SettingsGui.Add("Text", "x18 y5 w300 h18 Background" colorCard, "ChesNova " appVersion)
    SettingsGui.SetFont("s10 Bold c" colorText, "Segoe UI")
    cloudBtn := SettingsGui.Add("Text", "x704 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "☁")
    cloudBtn.OnEvent("Click", (*) => ShowView("Cloud"))
    diagnosticsBtn := SettingsGui.Add("Text", "x670 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "D")
    diagnosticsBtn.OnEvent("Click", (*) => ShowView("Diagnostics"))
    settingsBtn := SettingsGui.Add("Text", "x738 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "⚙")
    settingsBtn.OnEvent("Click", (*) => ShowView("Settings"))
    NotificationButtonCtrl := SettingsGui.Add("Text", "x772 y3 w30 h22 +0x200 Center Background" colorCardAlt " c" colorText, "🔔")
    NotificationButtonCtrl.OnEvent("Click", OpenNotifications)
    NotificationButtonCtrl.SetFont("s10 Norm c" colorText, "Segoe UI Emoji")
    NotificationIndicatorCtrl := SettingsGui.Add("Text", "x794 y2 w7 h8 +0x200 Center Background" colorCardAlt " c" colorGreen, "●")
    NotificationIndicatorCtrl.SetFont("s6 Bold c" colorGreen, "Segoe UI")
    hideWindowBtn := SettingsGui.Add("Text", "x846 y3 w32 h22 +0x200 Center Background" colorCardAlt " c" colorText, Chr(0x2212))
    hideWindowBtn.OnEvent("Click", HideSettingsMenu)
    closeWindowBtn := SettingsGui.Add("Text", "x882 y3 w32 h22 +0x200 Center Background" colorCardAlt " c" colorText, Chr(0x00D7))
    closeWindowBtn.OnEvent("Click", CloseSettings)

    BuildNavButton("Dashboard", "⌂   Главная", 48)
    BuildNavButton("Punishments", "⚖   Наказания", 88)
    BuildNavButton("NormHistory", "◷   Норма", 128)
    BuildNavButton("DaysOff", "☀   Отгулы", 168)
    BuildNavButton("PMLogs", "▤   PM логи", 208)
    BuildNavButton("Binds", "⌨   Бинды", 248)
    BuildNavButton("Scripts", "✦   Скрипты", 288)
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
    ctrl.OnEvent("Click", callback)
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
            "activationCommands", "//loader add script scripts/_otools.js`n//loader reload"
        ),
        Map(
            "id", "onishi",
            "displayTitle", "Onishi",
            "author", "Takumi Onishi",
            "title", "Onishi",
            "description", "Onishi script with loader.",
            "authors", "Takumi Onishi",
            "topic", "https://forum.radmir.games/threads/instrumenty-dlya-administratsii.2840899/",
            "files", [
                Map("name", "loader-js.asi", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/loader-js.asi", "relativePath", "loader-js.asi"),
                Map("name", "_otools.js", "url", "https://raw.githubusercontent.com/MishaChes/ChesNova/main/files/_otools.js", "relativePath", "uiresources\scripts\_otools.js")
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
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", requestUrl, false)
    http.SetRequestHeader("Cache-Control", "no-cache")
    http.SetRequestHeader("Pragma", "no-cache")
    http.Send()

    if (http.Status != 200)
        throw Error("GitHub вернул HTTP " http.Status ".")

    return http.ResponseText
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
    dlg := Gui("+ToolWindow -SysMenu +AlwaysOnTop +Border", "Обновление ChesNova")
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

    if isRequired {
        dlg.SetFont("s9 Bold c" colorRed, "Segoe UI")
        dlg.Add("Text", "x38 y" (dlgHeight - 112) " w280 h20 Background" colorCard, "Это обязательное обновление")
        downloadButton := dlg.Add("Text", "x314 y" (dlgHeight - 52) " w168 h30 +0x200 Center Background" colorAccent " c" colorText, "📥 Скачать")
    } else {
        laterButton := dlg.Add("Text", "x206 y" (dlgHeight - 52) " w128 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Позже")
        laterButton.OnEvent("Click", (*) => dlg.Destroy())
        downloadButton := dlg.Add("Text", "x346 y" (dlgHeight - 52) " w136 h30 +0x200 Center Background" colorAccent " c" colorText, "📥 Скачать")
    }

    downloadButton.OnEvent("Click", OpenUpdateDownload.Bind(versionInfo["download"], dlg))
    dlg.Show("w520 h" dlgHeight)
}

OpenUpdateDownload(downloadUrl, dlg, *) {
    if (downloadUrl = "") {
        ShowAppDialog("Обновления", "В version.json не указана ссылка для скачивания.")
        return
    }

    try {
        Run(downloadUrl)
        dlg.Destroy()
    } catch as err {
        LogError("OpenUpdateDownload", "Не удалось открыть ссылку на обновление", err.Message)
        ShowAppDialog("Обновления", "Не удалось открыть ссылку для скачивания." Chr(10) Chr(10) err.Message)
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

    dlg := Gui("+ToolWindow +AlwaysOnTop +Border", "Обновление ChesNova")
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
    laterButton.OnEvent("Click", (*) => dlg.Destroy())
    restartButton := dlg.Add("Text", "x370 y160 w172 h30 +0x200 Center Background" colorAccent, "Перезапустить сейчас")
    restartButton.OnEvent("Click", RestartChesNova.Bind(dlg))
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show("w560 h208")
}

RestartChesNova(dlg, *) {
    global basePath

    launcherPath := basePath "\ChesNovaLauncher.ahk"
    if !FileExist(launcherPath) {
        MsgBox("Не найден ChesNovaLauncher.ahk в папке Documents\ChesNova.", "ChesNova", "Iconx")
        return
    }

    try {
        Run('"' A_AhkPath '" "' launcherPath '" --restart')
        dlg.Destroy()
        ExitApp()
    } catch as err {
        LogError("RestartChesNova", "Не удалось перезапустить ChesNova", err.Message)
        MsgBox("Не удалось перезапустить ChesNova.", "ChesNova", "Iconx")
    }
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

    tempFile := notificationsCacheFile ".download"
    try {
        Download(notificationsUrl, tempFile)
        jsonText := FileRead(tempFile, "UTF-8")
        FileMove(tempFile, notificationsCacheFile, 1)
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
        if FileExist(tempFile)
            try FileDelete(tempFile)
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

    NotificationsGui := Gui("+ToolWindow +AlwaysOnTop +Border", "Уведомления")
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
    clearButton.OnEvent("Click", ClearNotifications)
    closeButton := NotificationsGui.Add("Text", "x408 y478 w128 h30 +0x200 Center Background" colorAccent " c" colorText, "Закрыть")
    closeButton.OnEvent("Click", (*) => SafeDestroyGui(&NotificationsGui))
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
    AddViewControl(view, "Text", "x250 y34 w560 h30 Background" colorBg " c" colorText, "Скрипты")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")
    AddViewControl(view, "Text", "x250 y88 w600 h20 Background" colorBg " c" colorMuted, "Укажите корень игры — автоматический поиск не используется.")
    ScriptsGamePathCtrl := AddViewControl(view, "Edit", "x250 y112 w330 h26 cFFFFFF Background151A22", scriptsGamePath)
    pathButton := AddViewControl(view, "Text", "x592 y112 w126 h26 +0x200 Center Background" colorCardAlt " c" colorText, "📁 Папка")
    pathButton.OnEvent("Click", SelectScriptsGamePath)
    checkButton := AddViewControl(view, "Text", "x726 y112 w124 h26 +0x200 Center Background" colorCardAlt " c" colorText, "🔎 Проверить")
    checkButton.OnEvent("Click", CheckScriptPackages)

    for index, package in GetScriptPackages() {
        cardY := 154 + ((index - 1) * 250)
        AddViewControl(view, "Text", "x250 y" cardY " w600 h230 Background" colorCard)
        AddViewControl(view, "Text", "x250 y" cardY " w4 h230 Background" colorAccent)
        AddViewControl(view, "Text", "x272 y" (cardY + 18) " w250 h28 Background" colorCard " c" colorText, package["title"])
        ScriptPackageStatusCtrls[package["id"]] := AddViewControl(view, "Text", "x532 y" (cardY + 22) " w296 h22 Background" colorCard " c" colorRed, "")
        AddViewControl(view, "Text", "x272 y" (cardY + 52) " w450 h38 Background" colorCard " c" colorMuted, package["description"])
        AddViewControl(view, "Text", "x272 y" (cardY + 96) " w170 h18 Background" colorCard " c" colorMuted, "Авторы")
        AddViewControl(view, "Text", "x272 y" (cardY + 116) " w280 h38 Background" colorCard " c" colorText, package["authors"])
        AddViewControl(view, "Text", "x570 y" (cardY + 96) " w200 h18 Background" colorCard " c" colorMuted, "Файлы")

        filesText := ""
        for _, file in package["files"]
            filesText .= "✔ " file["name"] "`n"
        AddViewControl(view, "Text", "x570 y" (cardY + 116) " w180 h64 Background" colorCard " c" colorGreen, RTrim(filesText, "`n"))

        topicButton := AddViewControl(view, "Text", "x272 y" (cardY + 190) " w268 h28 +0x200 Center Background" colorCardAlt " c" colorText, "🌐 Официальная тема")
        topicButton.OnEvent("Click", OpenScriptTopic.Bind(package["topic"]))
        installButton := AddViewControl(view, "Text", "x550 y" (cardY + 190) " w278 h28 +0x200 Center Background" colorAccent " c" colorText, "📥 Установить")
        installButton.OnEvent("Click", InstallScriptPackage.Bind(package["id"]))
    }

    RefreshScriptsView()
}

ScriptsViewCompact() {
    global ScriptsGamePathCtrl, ScriptPackageStatusCtrls, scriptsGamePath
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorRed

    view := "Scripts"
    ScriptPackageStatusCtrls := Map()
    AddViewControl(view, "Text", "x250 y34 w560 h30 Background" colorBg " c" colorText, "Скрипты")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")
    AddViewControl(view, "Text", "x250 y88 w600 h20 Background" colorBg " c" colorMuted, "Укажите корень игры — автоматический поиск не используется.")
    ScriptsGamePathCtrl := AddViewControl(view, "Edit", "x250 y112 w330 h26 cFFFFFF Background151A22", scriptsGamePath)
    pathButton := AddViewControl(view, "Text", "x592 y112 w126 h26 +0x200 Center Background" colorCardAlt " c" colorText, "Папка")
    pathButton.OnEvent("Click", SelectScriptsGamePath)
    checkButton := AddViewControl(view, "Text", "x726 y112 w124 h26 +0x200 Center Background" colorCardAlt " c" colorText, "Проверить")
    checkButton.OnEvent("Click", CheckScriptPackages)

    for index, package in GetScriptPackages() {
        cardY := 154 + ((index - 1) * 118)
        AddViewControl(view, "Text", "x250 y" cardY " w600 h104 Background" colorCard)
        AddViewControl(view, "Text", "x250 y" cardY " w4 h104 Background" colorAccent)
        AddViewControl(view, "Text", "x272 y" (cardY + 14) " w150 h24 Background" colorCard " c" colorText, package["displayTitle"])
        ScriptPackageStatusCtrls[package["id"]] := AddViewControl(view, "Text", "x432 y" (cardY + 16) " w160 h20 Background" colorCard " c" colorRed, "●")
        installButton := AddViewControl(view, "Text", "x660 y" (cardY + 12) " w168 h28 +0x200 Center Background" colorAccent " c" colorText, "Установить")
        installButton.OnEvent("Click", InstallScriptPackage.Bind(package["id"]))
        note := (package["id"] = "onishi") ? "Loader входит в установку" : "Отдельный пакет"
        AddViewControl(view, "Text", "x272 y" (cardY + 42) " w340 h18 Background" colorCard " c" colorMuted, note)
        AddViewControl(view, "Text", "x272 y" (cardY + 72) " w250 h18 Background" colorCard " c" colorMuted, "Автор: " package["author"])
        topicButton := AddViewControl(view, "Text", "x590 y" (cardY + 68) " w238 h24 +0x200 Center Background" colorCardAlt " c" colorText, "Прямая ссылка")
        topicButton.OnEvent("Click", OpenScriptTopic.Bind(package["topic"]))
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
    if (path != "") {
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
    if (missingPackages.Length = 0)
        ShowAppDialog("Проверка скриптов", "✅ Установлено:" lineBreak JoinArrayRange(installedPackages, 1, installedPackages.Length, lineBreak))
    else
        ShowAppDialog("Проверка скриптов", "⚠️ Требуется установка:" lineBreak JoinArrayRange(missingPackages, 1, missingPackages.Length, lineBreak lineBreak))
}

OpenScriptTopic(url, *) {
    try Run(url)
    catch as err
        ShowAppDialog("Скрипты", "Не удалось открыть официальную тему.`n`n" err.Message)
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
    ShowScriptInstallComplete(package)
}

ShowScriptInstallComplete(package) {
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    dlg := Gui("+ToolWindow +AlwaysOnTop +Border", "Скрипты")
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
    commandsCtrl := dlg.Add("Edit", "x38 y120 w380 h50 ReadOnly -Wrap Background151A22 cFFFFFF", package["activationCommands"])
    copyButton := dlg.Add("Text", "x38 y212 w190 h30 +0x200 Center Background" colorAccent " c" colorText, "📋 Скопировать команды")
    copyButton.OnEvent("Click", (*) => CopyScriptCommands(package["activationCommands"]))
    closeButton := dlg.Add("Text", "x310 y212 w108 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Закрыть")
    closeButton.OnEvent("Click", (*) => dlg.Destroy())
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.Show("w470 h262")
}

CopyScriptCommands(commands, *) {
    A_Clipboard := commands
    ShowAppDialog("Скрипты", "Команды скопированы в буфер обмена.")
}

DashboardView() {
    global DashboardNickCtrl, DashboardSystemStatusCtrl, DashboardCloudStatusCtrl, DashboardNormCtrl, DashboardVersionCtrl
    global DashboardNormPmCtrl, DashboardNormRemainingCtrl, DashboardNormPercentCtrl, DashboardProgressBgCtrl, DashboardProgressFillCtrl, DashboardLogFileCtrl, DashboardDaysOffMonthCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted, colorGreen, colorYellow

    view := "Dashboard"

    ; Заголовок
    AddViewControl(view, "Text", "x250 y34 w560 h28 Background" colorBg " c" colorText, "Главная")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")

    ; Профиль без аватара
    AddViewControl(view, "Text", "x250 y94 w600 h98 Background" colorCard)
    AddViewControl(view, "Text", "x270 y105 w220 h22 Background" colorCard " c" colorMuted, "Администратор")
    DashboardNickCtrl := AddViewControl(view, "Text", "x270 y128 w260 h28 Background" colorCard " c" colorAccent " +0x200", "")
    AddViewControl(view, "Text", "x270 y160 w180 h20 Background" colorCard " c" colorGreen, "• Профиль активен")

    ; Норма без шкалы
    AddViewControl(view, "Text", "x250 y216 w290 h116 Background" colorCard)
    AddViewControl(view, "Text", "x270 y238 w190 h22 Background" colorCard " c" colorMuted, "📨 Норма PM")
    DashboardNormPmCtrl := AddViewControl(view, "Text", "x270 y264 w240 h34 Background" colorCard " c" colorAccent " +0x200", "")
    DashboardNormRemainingCtrl := AddViewControl(view, "Text", "x270 y302 w220 h22 Background" colorCard " c" colorMuted, "")

    ; Отгулы за месяц
    AddViewControl(view, "Text", "x560 y216 w290 h116 Background" colorCard)
    AddViewControl(view, "Text", "x580 y238 w190 h22 Background" colorCard " c" colorMuted, "🏖 Отгулы за месяц")
    DashboardDaysOffMonthCtrl := AddViewControl(view, "Text", "x580 y264 w210 h34 Background" colorCard " c" colorGreen " +0x200", "")
    AddViewControl(view, "Text", "x580 y302 w220 h22 Background" colorCard " c" colorMuted, "Текущий календарный месяц")

    ; Статус системы
    AddViewControl(view, "Text", "x250 y356 w290 h116 Background" colorCard)
    AddViewControl(view, "Text", "x270 y378 w220 h22 Background" colorCard " c" colorMuted, "🛡 Статус системы")
    DashboardSystemStatusCtrl := AddViewControl(view, "Text", "x270 y404 w230 h26 Background" colorCard " c" colorGreen " +0x200", "")
    DashboardLogFileCtrl := AddViewControl(view, "Text", "x270 y434 w230 h24 Background" colorCard " c" colorMuted, "")

    ; Cloud
    AddViewControl(view, "Text", "x560 y356 w290 h116 Background" colorCard)
    AddViewControl(view, "Text", "x580 y378 w220 h22 Background" colorCard " c" colorMuted, "☁ Cloud")
    DashboardCloudStatusCtrl := AddViewControl(view, "Text", "x580 y404 w230 h26 Background" colorCard " c" colorAccent " +0x200", "")
    AddViewControl(view, "Text", "x580 y434 w230 h24 Background" colorCard " c" colorMuted, "Проверка доступа активна")

    ; Быстрый переход по центру снизу
    openSettingsBtn := AddViewControl(view, "Text", "x405 y492 w290 h34 +0x200 Center Background" colorAccent " c" colorText, "⚙  Открыть настройки")
    openSettingsBtn.OnEvent("Click", (*) => ShowView("Settings"))
}

RefreshDashboardView() {
    global SettingsGui
    global nick, pmCount, norm, logFile, appVersion, colorAccent, colorGreen, colorRed, colorMuted
    global DashboardNickCtrl, DashboardSystemStatusCtrl, DashboardCloudStatusCtrl, DashboardNormCtrl, DashboardVersionCtrl
    global DashboardNormPmCtrl, DashboardNormRemainingCtrl, DashboardNormPercentCtrl, DashboardProgressFillCtrl, DashboardLogFileCtrl, DashboardDaysOffMonthCtrl

    ; Если F10-меню закрыто или пересоздаётся, старые Text-контролы уже уничтожены.
    ; Не трогаем их, чтобы не ловить ошибку "The control is destroyed".
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

        if IsObject(DashboardSystemStatusCtrl) {
            if (logFile != "" && FileExist(logFile)) {
                DashboardSystemStatusCtrl.Text := "активировано"
                DashboardSystemStatusCtrl.SetFont("c" colorGreen)
            } else {
                DashboardSystemStatusCtrl.Text := "неактивировано"
                DashboardSystemStatusCtrl.SetFont("c" colorRed)
            }
        }

        if IsObject(DashboardLogFileCtrl)
            DashboardLogFileCtrl.Text := (logFile != "" && FileExist(logFile)) ? "chatlog.txt выбран  •" : "chatlog.txt не выбран"

        if IsObject(DashboardCloudStatusCtrl) {
            DashboardCloudStatusCtrl.Text := GetCloudStatusText()
            DashboardCloudStatusCtrl.SetFont("c" GetCloudStatusColor())
        }
    } catch as err {
        ResetDashboardControls()
    }
}

PMLogsView() {
    global PMLogsSearchCtrl, PmLogsTextCtrl
    global colorBg, colorCard, colorText, colorMuted

    view := "PMLogs"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background" colorBg " c" colorText, "PM Логи")
    AddViewControl(view, "Text", "x250 y84 w220 h22 Background" colorBg " c" colorMuted, "Поиск по нику или тексту")
    PMLogsSearchCtrl := AddViewControl(view, "Edit", "x250 y112 w470 h24 c000000 BackgroundEDEDED", "")
    PMLogsSearchCtrl.OnEvent("Change", PMLogsSearchChanged)
    clearButton := AddViewControl(view, "Button", "x735 y112 w115 h28", "Очистить")
    clearButton.OnEvent("Click", ClearPMLogs)
    PmLogsTextCtrl := AddViewControl(view, "Edit", "vPmLogsText x250 y154 w600 h330 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, BuildPmLogsText())
}

PMLogsSearchChanged(*) {
    global PMLogsSearchCtrl, PmLogsTextCtrl

    if (IsObject(PMLogsSearchCtrl) && IsObject(PmLogsTextCtrl))
        PmLogsTextCtrl.Value := BuildPmLogsText(PMLogsSearchCtrl.Value)
}

PunishmentsView() {
    global selectedPunishmentDays, selectedPunishmentType, punishmentSearch
    global PunishmentTypeTitleCtrl, PunishmentSearchCtrl, PunishmentDetailsCtrl, PunishmentButtonCtrls

    view := "Punishments"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background0E1116 cFFFFFF", "Наказания")
    AddViewControl(view, "Text", "x250 y88 w105 Background0E1116 c7aa2ff", "Тип")
    AddViewControl(view, "Text", "x380 y88 w220 Background0E1116 c7aa2ff", "Период")
    AddViewControl(view, "Text", "x610 y88 w210 Background0E1116 c7aa2ff", "Поиск")
    PunishmentTypeTitleCtrl := AddViewControl(view, "Text", "vPunishmentTypeTitle x380 y174 w470 Background0E1116 cFFFFFF", "Выберите тип наказания")

    PunishmentButtonCtrls := Map()
    PunishmentButtonCtrls["kick"] := AddViewControl(view, "Button", "vPunishmentBtnKick x250 y120 w110 h26", "kick (0)")
    PunishmentButtonCtrls["kick"].OnEvent("Click", ShowPunishmentKick)
    PunishmentButtonCtrls["jail"] := AddViewControl(view, "Button", "vPunishmentBtnJail x250 y152 w110 h26", "jail (0)")
    PunishmentButtonCtrls["jail"].OnEvent("Click", ShowPunishmentJail)
    PunishmentButtonCtrls["warn"] := AddViewControl(view, "Button", "vPunishmentBtnWarn x250 y184 w110 h26", "warn (0)")
    PunishmentButtonCtrls["warn"].OnEvent("Click", ShowPunishmentWarn)
    PunishmentButtonCtrls["mute"] := AddViewControl(view, "Button", "vPunishmentBtnMute x250 y216 w110 h26", "mute (0)")
    PunishmentButtonCtrls["mute"].OnEvent("Click", ShowPunishmentMute)
    PunishmentButtonCtrls["vmute"] := AddViewControl(view, "Button", "vPunishmentBtnVmute x250 y248 w110 h26", "vmute (0)")
    PunishmentButtonCtrls["vmute"].OnEvent("Click", ShowPunishmentVmute)
    PunishmentButtonCtrls["rmute"] := AddViewControl(view, "Button", "vPunishmentBtnRmute x250 y280 w110 h26", "rmute (0)")
    PunishmentButtonCtrls["rmute"].OnEvent("Click", ShowPunishmentRmute)
    PunishmentButtonCtrls["gunban"] := AddViewControl(view, "Button", "vPunishmentBtnGunban x250 y312 w110 h26", "gunban (0)")
    PunishmentButtonCtrls["gunban"].OnEvent("Click", ShowPunishmentGunban)
    PunishmentButtonCtrls["ban"] := AddViewControl(view, "Button", "vPunishmentBtnBan x250 y344 w110 h26", "ban (0)")
    PunishmentButtonCtrls["ban"].OnEvent("Click", ShowPunishmentBan)
    PunishmentButtonCtrls["sban"] := AddViewControl(view, "Button", "vPunishmentBtnSban x250 y376 w110 h26", "sban (0)")
    PunishmentButtonCtrls["sban"].OnEvent("Click", ShowPunishmentSban)
    PunishmentButtonCtrls["all"] := AddViewControl(view, "Button", "vPunishmentBtnAll x250 y408 w110 h26", "Все (0)")
    PunishmentButtonCtrls["all"].OnEvent("Click", ShowPunishmentAll)

    todayButton := AddViewControl(view, "Button", "x380 y120 w70 h24", "Сегодня")
    todayButton.OnEvent("Click", SetPunishmentToday)
    threeDaysButton := AddViewControl(view, "Button", "x455 y120 w70 h24", "3 дня")
    threeDaysButton.OnEvent("Click", SetPunishment3Days)
    tenDaysButton := AddViewControl(view, "Button", "x530 y120 w70 h24", "10 дней")
    tenDaysButton.OnEvent("Click", SetPunishment10Days)
    allTimeButton := AddViewControl(view, "Button", "x380 y150 w145 h24", "За всё время")
    allTimeButton.OnEvent("Click", SetPunishmentAllTime)
    clearButton := AddViewControl(view, "Button", "x530 y150 w70 h24", "Очистить")
    clearButton.OnEvent("Click", ClearPunishments)
    PunishmentSearchCtrl := AddViewControl(view, "Edit", "vPunishmentSearch x610 y120 w240 h24 c000000 BackgroundEDEDED", punishmentSearch)
    PunishmentSearchCtrl.OnEvent("Change", RefreshPunishmentView)
    PunishmentDetailsCtrl := AddViewControl(view, "Edit", "vPunishmentDetails x380 y208 w470 h270 ReadOnly -Wrap +WantReturn +VScroll Background20242b cFFFFFF", "Выберите тип наказания слева")

    UpdatePunishmentTypeButtons(selectedPunishmentDays, punishmentSearch)
    ShowPunishmentType(selectedPunishmentType)
}

NormHistoryView() {
    global NormHistoryListCtrl
    global colorBg, colorCard, colorText, colorMuted

    view := "NormHistory"
    AddViewControl(view, "Text", "x250 y34 w360 h34 Background" colorBg " c" colorText, "История нормы")
    AddViewControl(view, "Text", "x250 y84 w320 h22 Background" colorBg " c" colorMuted, "Новые записи отображаются сверху")
    editButton := AddViewControl(view, "Button", "x590 y80 w130 h28", "Редактировать")
    editButton.OnEvent("Click", OpenNormHistoryEdit)
    clearButton := AddViewControl(view, "Button", "x735 y80 w115 h28", "Очистить")
    clearButton.OnEvent("Click", ClearNormHistory)
    NormHistoryListCtrl := AddViewControl(view, "ListView", "x250 y120 w600 h360 Background" colorCard " c" colorText, ["Дата", "PM", "Норма", "Статус"])
    NormHistoryListCtrl.ModifyCol(1, 150)
    NormHistoryListCtrl.ModifyCol(2, 90)
    NormHistoryListCtrl.ModifyCol(3, 90)
    NormHistoryListCtrl.ModifyCol(4, 190)
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
    NormHistoryEditGui := Gui("+ToolWindow +Border", "Редактирование истории нормы")
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
    NormHistoryEditDateCtrl := NormHistoryEditGui.Add("Edit", "x130 y62 w178 h24 cFFFFFF Background151A22", recordDate)
    NormHistoryEditGui.Add("Text", "x34 y100 w80 h20 Background" colorCard, "PM")
    NormHistoryEditPmCtrl := NormHistoryEditGui.Add("Edit", "x130 y96 w178 h24 Number cFFFFFF Background151A22", recordPm)
    NormHistoryEditGui.Add("Text", "x34 y134 w80 h20 Background" colorCard, "Норма")
    NormHistoryEditNormCtrl := NormHistoryEditGui.Add("Edit", "x130 y130 w178 h24 Number cFFFFFF Background151A22", recordNorm)

    AddMiniWindowButton(NormHistoryEditGui, 110, 190, 104, 30, "Отмена", colorCardAlt, CancelNormHistoryEdit)
    AddMiniWindowButton(NormHistoryEditGui, 226, 190, 116, 30, "Сохранить", colorAccent, SaveNormHistoryEdit)
    NormHistoryEditGui.Show("w360 h244")
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
    global DaysOffDateCtrl, DaysOffListCtrl
    global colorBg, colorCard, colorText, colorMuted

    view := "DaysOff"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background" colorBg " c" colorText, "Отгулы")
    AddViewControl(view, "Text", "x250 y84 w220 h22 Background" colorBg " c" colorMuted, "Дата отгула")
    DaysOffDateCtrl := AddViewControl(view, "Edit", "vDaysOffDate x250 y112 w160 h26 c000000 BackgroundEDEDED", FormatTime(A_Now, "yyyy-MM-dd"))
    addButton := AddViewControl(view, "Button", "x425 y112 w115 h28", "Добавить")
    addButton.OnEvent("Click", AddDayOff)
    AddViewControl(view, "Text", "x250 y144 w220 h20 Background" colorBg " c" colorMuted, "Формат даты: yyyy-MM-dd")
    deleteButton := AddViewControl(view, "Button", "x690 y112 w160 h28", "Удалить выбранный")
    deleteButton.OnEvent("Click", DeleteSelectedDayOff)
    AddViewControl(view, "Text", "x250 y176 w560 h22 Background" colorBg " c" colorMuted, "Все добавленные отгулы")
    DaysOffListCtrl := AddViewControl(view, "ListView", "x250 y206 w600 h278 Background" colorCard " c" colorText, ["Дата"])
    DaysOffListCtrl.ModifyCol(1, 180)
}

BindsView() {
    global BindsSearchCtrl, BindsCategoryCtrl, BindsCategoryStatusCtrl, BindsListCtrl, BindsEnabledCtrl, bindsEnabled
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Binds"
    AddViewControl(view, "Text", "x250 y34 w360 h28 Background" colorBg " c" colorText, "Бинды")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")

    AddViewControl(view, "Text", "x250 y94 w600 h116 Background" colorCard)
    BindsEnabledCtrl := AddViewControl(view, "Checkbox", "x270 y112 w160 h24 Checked" bindsEnabled " c" colorText " Background" colorCard, "Бинды включены")
    BindsEnabledCtrl.OnEvent("Click", ToggleAllBindsEnabled)

    AddViewControl(view, "Text", "x270 y146 w80 h20 Background" colorCard " c" colorMuted, "Поиск")
    BindsSearchCtrl := AddViewControl(view, "Edit", "x270 y170 w230 h26 cFFFFFF Background151A22", "")
    BindsSearchCtrl.OnEvent("Change", RefreshBindsList)
    AddViewControl(view, "Text", "x520 y146 w150 h20 Background" colorCard " c" colorMuted, "Фильтр категории")
    BindsCategoryCtrl := AddViewControl(view, "ComboBox", "x520 y170 w180 h120", GetBindCategories(true))
    BindsCategoryCtrl.Choose(1)
    BindsCategoryCtrl.OnEvent("Change", RefreshBindsList)
    BindsCategoryStatusCtrl := AddViewControl(view, "Text", "x710 y173 w120 h20 Background" colorCard " c" colorMuted, "Выберите фильтр")

    addCategoryButton := AddViewControl(view, "Text", "x250 y222 w190 h28 +0x200 Center Background" colorAccent " c" colorText, "Добавить катег.")
    addCategoryButton.OnEvent("Click", AddBindCategory)
    deleteCategoryButton := AddViewControl(view, "Text", "x455 y222 w190 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Удалить катег.")
    deleteCategoryButton.OnEvent("Click", DeleteSelectedBindCategory)
    toggleCategoryButton := AddViewControl(view, "Text", "x660 y222 w190 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Вкл/Выкл катег.")
    toggleCategoryButton.OnEvent("Click", ToggleSelectedBindCategory)

    addButton := AddViewControl(view, "Text", "x250 y270 w141 h28 +0x200 Center Background" colorAccent " c" colorText, "Добавить бинд")
    addButton.OnEvent("Click", AddBind)
    editButton := AddViewControl(view, "Text", "x403 y270 w141 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Редактировать")
    editButton.OnEvent("Click", EditSelectedBind)
    deleteButton := AddViewControl(view, "Text", "x556 y270 w141 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Удалить")
    deleteButton.OnEvent("Click", DeleteSelectedBind)
    toggleButton := AddViewControl(view, "Text", "x709 y270 w141 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Вкл/Выкл")
    toggleButton.OnEvent("Click", ToggleSelectedBind)

    ; 6-я колонка скрытая: там хранится trigger, потому что ID больше не используется.
    BindsListCtrl := AddViewControl(view, "ListView", "x250 y316 w600 h168 Background" colorCard " c" colorText, ["Тип", "Категория", "Название", "Триггер", "Статус", "Ключ"])
    BindsListCtrl.ModifyCol(1, 80)
    BindsListCtrl.ModifyCol(2, 135)
    BindsListCtrl.ModifyCol(3, 170)
    BindsListCtrl.ModifyCol(4, 120)
    BindsListCtrl.ModifyCol(5, 70)
    BindsListCtrl.ModifyCol(6, 0)
    BindsListCtrl.OnEvent("ColClick", SortBindsByColumn)
    BindsListCtrl.OnEvent("DoubleClick", EditSelectedBind)
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
    BindEditNameCtrl := BindEditGui.Add("Edit", "x34 y166 w270 h26 cFFFFFF Background151A22", bindName)
    BindEditGui.Add("Text", "x324 y142 w120 h20 Background" colorCard, "Триггер")
    BindEditTriggerCtrl := BindEditGui.Add("Edit", "x324 y166 w262 h26 cFFFFFF Background151A22", trigger)

    BindEditGui.Add("Text", "x34 y212 w180 h20 Background" colorCard, "Содержимое бинда")
    BindEditContentCtrl := BindEditGui.Add("Edit", "x34 y238 w552 h150 cFFFFFF Background151A22 +WantReturn +VScroll", content)

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
    global nick, norm, autoResetEnabled, checkUpdatesOnStartup, startWithWindows, resetHour, resetMinute, menuKey, resetKey, centerKey, hideKey, hudDesign, logFile
    global SetNickCtrl, SetNormCtrl, SetMenuKeyCtrl, SetResetKeyCtrl, SetCenterKeyCtrl, SetHideKeyCtrl, SetHudDesignCtrl
    global SetAutoResetCtrl, SetCheckUpdatesCtrl, SetStartupCtrl, SetResetHourCtrl, SetResetMinuteCtrl, LogFileTextCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Settings"
    AddViewControl(view, "Text", "x250 y34 w560 h30 Background" colorBg " c" colorText, "Настройки")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")

    ; Левая колонка: профиль и горячие клавиши.
    AddViewControl(view, "Text", "x250 y88 w280 h102 Background" colorCard)
    AddViewControl(view, "Text", "x270 y104 w220 h22 Background" colorCard " c" colorText, "Пользователь")
    AddViewControl(view, "Text", "x270 y136 w110 h22 Background" colorCard " c" colorMuted, "Ник")
    SetNickCtrl := AddViewControl(view, "Edit", "vSetNick x390 y132 w120 h26 c" colorText " Background151A22", nick)
    AddViewControl(view, "Text", "x270 y166 w110 h22 Background" colorCard " c" colorMuted, "Норма PM")
    SetNormCtrl := AddViewControl(view, "Edit", "vSetNorm x390 y162 w120 h26 Number c" colorText " Background151A22", norm)

    AddViewControl(view, "Text", "x250 y206 w280 h204 Background" colorCard)
    AddViewControl(view, "Text", "x270 y222 w220 h22 Background" colorCard " c" colorText, "Горячие клавиши")
    AddViewControl(view, "Text", "x270 y258 w110 h22 Background" colorCard " c" colorMuted, "Открыть меню")
    SetMenuKeyCtrl := AddViewControl(view, "Edit", "vSetMenuKey x390 y254 w120 h26 c" colorText " Background151A22", menuKey)
    AddViewControl(view, "Text", "x270 y294 w110 h22 Background" colorCard " c" colorMuted, "Сброс PM")
    SetResetKeyCtrl := AddViewControl(view, "Edit", "vSetResetKey x390 y290 w120 h26 c" colorText " Background151A22", resetKey)
    AddViewControl(view, "Text", "x270 y330 w110 h22 Background" colorCard " c" colorMuted, "Центр HUD")
    SetCenterKeyCtrl := AddViewControl(view, "Edit", "vSetCenterKey x390 y326 w120 h26 c" colorText " Background151A22", centerKey)
    AddViewControl(view, "Text", "x270 y366 w110 h22 Background" colorCard " c" colorMuted, "Скрыть HUD")
    SetHideKeyCtrl := AddViewControl(view, "Edit", "vSetHideKey x390 y362 w120 h26 c" colorText " Background151A22", hideKey)

    AddViewControl(view, "Text", "x250 y442 w280 h72 Background" colorCard)
    AddViewControl(view, "Text", "x270 y456 w120 h20 Background" colorCard " c" colorMuted, "Дизайн HUD")
    SetHudDesignCtrl := AddViewControl(view, "ComboBox", "vSetHudDesign x270 y480 w240 c000000 BackgroundEDEDED", ["Компактный", "Расширенный"])
    SetHudDesignCtrl.Choose(hudDesign = "Expanded" ? 2 : 1)

    ; Правая колонка: автоматизация и источник логов.
    AddViewControl(view, "Text", "x550 y88 w300 h142 Background" colorCard)
    AddViewControl(view, "Text", "x570 y104 w220 h22 Background" colorCard " c" colorText, "Автосброс нормы")
    SetAutoResetCtrl := AddViewControl(view, "Checkbox", "vSetAutoReset x570 y136 Checked" autoResetEnabled " c" colorText " Background" colorCard, "Включить автосброс")
    AddViewControl(view, "Text", "x570 y172 w60 h22 Background" colorCard " c" colorMuted, "Часы")
    SetResetHourCtrl := AddViewControl(view, "Edit", "vSetResetHour x635 y168 w58 h26 Number c" colorText " Background151A22", resetHour)
    AddViewControl(view, "Text", "x708 y172 w64 h22 Background" colorCard " c" colorMuted, "Минуты")
    SetResetMinuteCtrl := AddViewControl(view, "Edit", "vSetResetMinute x782 y168 w48 h26 Number c" colorText " Background151A22", resetMinute)

    AddViewControl(view, "Text", "x550 y246 w300 h180 Background" colorCard)
    AddViewControl(view, "Text", "x570 y262 w220 h22 Background" colorCard " c" colorText, "Файл логов")
    logText := logFile
    if (logText = "")
        logText := "Файл не выбран"
    LogFileTextCtrl := AddViewControl(view, "Edit", "vLogFileText x570 y292 w260 h58 ReadOnly -Wrap c" colorText " Background151A22", logText)
    selectLogButton := AddViewControl(view, "Text", "x570 y366 w260 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Выбрать chatlog.txt")
    selectLogButton.OnEvent("Click", SelectLogFile)
    AddViewControl(view, "Text", "x550 y442 w300 h72 Background" colorCard)
    SetStartupCtrl := AddViewControl(view, "Checkbox", "vSetStartup x570 y464 Checked" startWithWindows " c" colorText " Background" colorCard, "Запускать вместе с Windows")
    saveButton := AddViewControl(view, "Text", "x550 y528 w300 h34 +0x200 Center Background" colorAccent " cFFFFFF", "Сохранить настройки")
    saveButton.OnEvent("Click", SaveSettings)
}

UpdatesView() {
    global appVersion, checkUpdatesOnStartup, SetCheckUpdatesCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Updates"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background" colorBg " c" colorText, "Обновления")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")
    AddViewControl(view, "Text", "x250 y94 w600 h116 Background" colorCard)
    AddViewControl(view, "Text", "x274 y116 w250 h24 Background" colorCard " c" colorText, "ChesNova " appVersion)
    AddViewControl(view, "Text", "x274 y148 w430 h24 Background" colorCard " c" colorMuted, "Проверяйте новые версии и управляйте обновлением приложения.")
    SetCheckUpdatesCtrl := AddViewControl(view, "Checkbox", "vSetCheckUpdates x274 y176 Checked" checkUpdatesOnStartup " c" colorText " Background" colorCard, "Проверять обновления при запуске")
    checkButton := AddViewControl(view, "Text", "x250 y236 w292 h34 +0x200 Center Background" colorCardAlt " c" colorText, "Проверить обновления")
    checkButton.OnEvent("Click", CheckForUpdatesManual)
    updateButton := AddViewControl(view, "Text", "x558 y236 w292 h34 +0x200 Center Background" colorAccent " cFFFFFF", "Обновить ChesNova")
    updateButton.OnEvent("Click", ManualUpdateChesNova)
    AddViewControl(view, "Text", "x250 y294 w600 h86 Background" colorCard)
    AddViewControl(view, "Text", "x274 y314 w530 h20 Background" colorCard " c" colorMuted, "Настройка сохраняется вместе с основными настройками приложения.")
    saveButton := AddViewControl(view, "Text", "x558 y338 w292 h28 +0x200 Center Background" colorCardAlt " c" colorText, "Сохранить настройки")
    saveButton.OnEvent("Click", SaveSettings)
}

RefreshUpdatesView(*) {
    global checkUpdatesOnStartup, SetCheckUpdatesCtrl

    if IsObject(SetCheckUpdatesCtrl)
        SetCheckUpdatesCtrl.Value := checkUpdatesOnStartup
}

RefreshSettingsView() {
    global logFile, LogFileTextCtrl

    if IsObject(LogFileTextCtrl)
        LogFileTextCtrl.Value := (logFile = "") ? "Файл не выбран" : logFile
}

HelpView() {
    global HelpEditCtrl, ErrorsLogTextCtrl

    view := "Help"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background0E1116 cFFFFFF", "Помощь")
    helpText := "
(
━━━━━━━━━━━━━━━━━━━━━━
📌 НАСТРОЙКА

• Нажми F10
• Укажи ник
• Укажи норму /pm
• Выбери chatlog.txt

━━━━━━━━━━━━━━━━━━━━━━
⌨️ БИНДЫ (ФОРМАТ)

Обычные:
F1, F2, F5, F10

SHIFT:
+1 = Shift + 1
+2 = Shift + 2
+0 = Shift + 0

CTRL:
^1 = Ctrl + 1
^F5 = Ctrl + F5

ALT:
!1 = Alt + 1
!F2 = Alt + F2

━━━━━━━━━━━━━━━━━━━━━━
📂 ЛОГ ФАЙЛ

documents > RADMIR CRMP User Files > SAMP > chatlog.txt

━━━━━━━━━━━━━━━━━━━━━━
📊 ИНДИКАТОР

● Красный = не выполнено
● Зелёный = выполнено

━━━━━━━━━━━━━━━━━━━━━━
🔁 УПРАВЛЕНИЕ

F9 — сброс
F2 — скрыть HUD
F5 — центр

━━━━━━━━━━━━━━━━━━━━━━
⚖️ НАКАЗАНИЯ

История наказаний отображается по выбранному типу и периоду.

━━━━━━━━━━━━━━━━━━━━━━
👨‍💻 АВТОР

VK: @m.ches
━━━━━━━━━━━━━━━━━━━━━━
)"
    HelpEditCtrl := AddViewControl(view, "Edit", "vHelpEdit x250 y84 w600 h240 ReadOnly -Wrap +WantReturn +VScroll Background20242b cFFFFFF", helpText)

    AddViewControl(view, "Text", "x250 y342 w220 Background0E1116 c7aa2ff", "Последние ошибки")
    refreshErrorsButton := AddViewControl(view, "Button", "x500 y338 w100 h28", "Обновить")
    refreshErrorsButton.OnEvent("Click", RefreshErrorsLogView)
    openErrorsButton := AddViewControl(view, "Button", "x610 y338 w110 h28", "Открыть файл")
    openErrorsButton.OnEvent("Click", OpenErrorsLogFile)
    clearErrorsButton := AddViewControl(view, "Button", "x730 y338 w120 h28", "Очистить лог")
    clearErrorsButton.OnEvent("Click", ClearErrorsLog)
    ErrorsLogTextCtrl := AddViewControl(view, "Edit", "vErrorsLogText x250 y376 w600 h108 ReadOnly -Wrap +WantReturn +VScroll Background20242b cFFFFFF", GetLastErrorLogLines())
}

DiagnosticsView() {
    global DiagnosticTextCtrl, colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    view := "Diagnostics"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background" colorBg " c" colorText, "Диагностика")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")
    AddViewControl(view, "Text", "x250 y94 w600 h330 Background" colorCard)
    AddViewControl(view, "Text", "x274 y116 w530 h24 Background" colorCard " c" colorMuted, "Метрики по запросу. Фоновая диагностика отключена.")
    refreshButton := AddViewControl(view, "Text", "x660 y446 w190 h30 +0x200 Center Background" colorCardAlt " c" colorText, "Обновить")
    refreshButton.OnEvent("Click", RefreshDiagnosticsView)
    DiagnosticTextCtrl := AddViewControl(view, "Edit", "x274 y150 w530 h270 ReadOnly -Wrap +WantReturn +VScroll Background" colorCard " c" colorText, BuildDiagnosticsText())
}

BuildDiagnosticsText() {
    global logFile, pmLogsFile, punishmentsFile, errorsLogFile
    global diagnosticLastCheckMs, diagnosticLastProcessedLines, diagnosticLastPmChanges, diagnosticLastLogSize

    text := "Интервал CheckLog: 1000 мс`n"
    text .= "Время последнего CheckLog: " diagnosticLastCheckMs " мс`n"
    text .= "Обработано строк: " diagnosticLastProcessedLines "`n"
    text .= "Новых PM: " diagnosticLastPmChanges "`n"
    text .= "Размер chatlog при проверке: " FormatDiagnosticBytes(diagnosticLastLogSize) "`n`n"
    text .= "chatlog.txt: " FormatDiagnosticFileSize(logFile) "`n"
    text .= "pm_logs.csv: " FormatDiagnosticFileSize(pmLogsFile) "`n"
    text .= "punishments_history.csv: " FormatDiagnosticFileSize(punishmentsFile) "`n"
    text .= "errors.log: " FormatDiagnosticFileSize(errorsLogFile)
    return text
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
    global DiagnosticTextCtrl

    if IsObject(DiagnosticTextCtrl)
        DiagnosticTextCtrl.Value := BuildDiagnosticsText()
}

CloudView() {
    global CloudNickCtrl, CloudStatusCtrl, CloudAccessTextCtrl, CloudLastCheckCtrl
    global colorBg, colorCard, colorAccent, colorText, colorMuted, colorGreen

    view := "Cloud"
    AddViewControl(view, "Text", "x250 y34 w560 h34 Background" colorBg " c" colorText, "Cloud")
    AddViewControl(view, "Text", "x250 y68 w600 h1 Background2A3340")

    AddViewControl(view, "Text", "x250 y94 w600 h120 Background" colorCard)
    AddViewControl(view, "Text", "x270 y112 w220 h22 Background" colorCard " c" colorMuted, "Аккаунт администратора")
    CloudNickCtrl := AddViewControl(view, "Text", "x270 y140 w260 h30 Background" colorCard " c" colorAccent " +0x200", "")
    CloudStatusCtrl := AddViewControl(view, "Text", "x270 y174 w260 h24 Background" colorCard " c" colorGreen " +0x200", "")
    checkButton := AddViewControl(view, "Button", "x610 y128 w110 h30", "Проверить")
    checkButton.OnEvent("Click", CloudCheckAccess)
    changeNickButton := AddViewControl(view, "Button", "x732 y128 w98 h30", "Сменить ник")
    changeNickButton.OnEvent("Click", CloudChangeNick)

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
    CheckCloudAccess(false, false)
    RefreshDashboardView()
    RefreshCloudView()
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
    global SettingsGui, settingsMenuHidden
    SaveMenuPosition()
    SafeDestroyGui(&SettingsGui)
    settingsMenuHidden := false
    ResetDashboardControls()
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
    global logFile, lastSize, LogFileTextCtrl

    selectedFile := FileSelect(3, , "Выберите chatlog.txt", "*.txt")
    if (selectedFile != "") {
        logFile := selectedFile
        lastSize := FileGetSize(logFile)
        if IsObject(LogFileTextCtrl)
            LogFileTextCtrl.Value := logFile
        AppendPmLog("Действие", "Выбран файл логов: " logFile)
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
    global menuKey, resetKey, centerKey, hideKey, hudDesign, settingsFile, logFile, lastResetDate, guiX, guiY, menuX, menuY

    SaveMenuPosition()
    values := SettingsGui.Submit()
    nick := Trim(values.SetNick)
    userNick := nick
    norm := values.SetNorm + 0
    autoResetEnabled := values.SetAutoReset
    checkUpdatesOnStartup := values.SetCheckUpdates
    startWithWindows := values.SetStartup
    resetHour := values.SetResetHour
    resetMinute := values.SetResetMinute
    menuKey := values.SetMenuKey
    resetKey := values.SetResetKey
    centerKey := values.SetCenterKey
    hideKey := values.SetHideKey
    hudDesign := (values.SetHudDesign = "Расширенный") ? "Expanded" : "Compact"

    try {
        IniWrite(nick, settingsFile, "Main", "nick")
        IniWrite(norm, settingsFile, "Main", "norm")
        IniWrite(logFile, settingsFile, "Main", "logFile")
        IniWrite(autoResetEnabled, settingsFile, "Main", "autoResetEnabled")
        IniWrite(bindsEnabled, settingsFile, "Main", "bindsEnabled")
        IniWrite(checkUpdatesOnStartup, settingsFile, "Updates", "checkOnStartup")
        IniWrite(startWithWindows, settingsFile, "Launcher", "startWithWindows")
        IniWrite(resetHour, settingsFile, "Main", "resetHour")
        IniWrite(resetMinute, settingsFile, "Main", "resetMinute")
        IniWrite(lastResetDate, settingsFile, "Main", "lastResetDate")
        IniWrite(menuKey, settingsFile, "Keys", "menuKey")
        IniWrite(resetKey, settingsFile, "Keys", "resetKey")
        IniWrite(centerKey, settingsFile, "Keys", "centerKey")
        IniWrite(hideKey, settingsFile, "Keys", "hideKey")
        IniWrite(guiX, settingsFile, "GUI", "guiX")
        IniWrite(guiY, settingsFile, "GUI", "guiY")
        IniWrite(menuX, settingsFile, "GUI", "menuX")
        IniWrite(menuY, settingsFile, "GUI", "menuY")
        IniWrite(hudDesign, settingsFile, "GUI", "hudDesign")
        SetWindowsStartup(startWithWindows)
    } catch as err {
        LogError("SaveSettings", "Ошибка записи settings.ini", err.Message)
        MsgBox("Не удалось сохранить настройки.`n`n" err.Message, "Ошибка", "Iconx")
        return
    }
    AppendPmLog("Действие", "Сохранены настройки ChesNova")

    SafeDestroyGui(&SettingsGui)
    ResetDashboardControls()
    ResetCloudControls()
    ResetNotificationControls()

    RegisterHotkeys()

    BuildMainHud()
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
    ResetConfirmGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "ResetConfirm")
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
    resetButton := ResetConfirmGui.Add("Button", "x14 y120 w125 h30", "Сбросить")
    resetButton.OnEvent("Click", ConfirmResetPM)
    cancelButton := ResetConfirmGui.Add("Button", "x149 y120 w125 h30", "Отмена")
    cancelButton.OnEvent("Click", CancelResetPM)
    ResetConfirmGui.Show("w290 h165")
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
}

CancelResetPM(*) {
    global ResetConfirmGui
    SafeDestroyGui(&ResetConfirmGui)
}
; =========================
; CENTER GUI
; =========================
CenterGUI(*) {
    global MainGui, guiX, guiY, settingsFile

    MainGui.Show("xCenter yCenter")
    MainGui.GetPos(&guiX, &guiY)
    TryIniWrite(guiX, settingsFile, "GUI", "guiX", "CenterGUI")
    TryIniWrite(guiY, settingsFile, "GUI", "guiY", "CenterGUI")
}

RegisterHotkeys() {
    global menuKey, resetKey, centerKey, hideKey

    Hotkey(menuKey, OpenMenu, "On")
    Hotkey(resetKey, ResetPM, "On")
    Hotkey(centerKey, CenterGUI, "On")
    Hotkey(hideKey, ToggleGUI, "On")
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
        date := StrReplace(NormalizeDayOffDate(line), "-", "")
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
        MsgBox("Не удалось открыть errors.log.`n`n" err.Message, "Ошибки", "Iconx")
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
        MsgBox("Не удалось очистить errors.log.`n`n" err.Message, "Ошибки", "Iconx")
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

    AppDialogResult := ""
    dlg := Gui("+ToolWindow +AlwaysOnTop +Border", title)
    dlg.BackColor := colorBg
    dlg.MarginX := 0
    dlg.MarginY := 0
    dlg.SetFont("s10 c" colorText, "Segoe UI")

    dlg.Add("Text", "x0 y0 w420 h190 Background" colorBg)
    dlg.Add("Text", "x18 y18 w384 h124 Background" colorCard)
    dlg.SetFont("s12 Bold c" colorText, "Segoe UI")
    dlg.Add("Text", "x38 y32 w330 h24 Background" colorCard, title)
    dlg.SetFont("s9 Norm c" colorMuted, "Segoe UI")
    dlg.Add("Text", "x38 y66 w345 h64 Background" colorCard, message)

    if (buttons = "OKCancel") {
        AddDialogTextButton(dlg, 176, 150, 104, 28, "Отмена", colorCardAlt, "Cancel")
        AddDialogTextButton(dlg, 292, 150, 104, 28, "OK", accentColor, "OK")
    } else if (buttons = "YesNo") {
        AddDialogTextButton(dlg, 176, 150, 104, 28, "Нет", colorCardAlt, "No")
        AddDialogTextButton(dlg, 292, 150, 104, 28, "Да", colorRed, "Yes")
    } else {
        AddDialogTextButton(dlg, 292, 150, 104, 28, "OK", accentColor, "OK")
    }

    dlg.OnEvent("Close", (*) => CloseAppDialog(dlg, "Cancel"))
    dlg.Show("w420 h190")
    WinWaitClose("ahk_id " dlg.Hwnd)
    return AppDialogResult
}

AddDialogTextButton(dlg, x, y, w, h, label, bgColor, result) {
    global colorText
    dlg.SetFont("s9 Bold c" colorText, "Segoe UI")
    ctrl := dlg.Add("Text", "x" x " y" y " w" w " h" h " +0x200 Center Background" bgColor, label)
    ctrl.OnEvent("Click", (*) => CloseAppDialog(dlg, result))
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
    ctrl.OnEvent("Click", callback)
    return ctrl
}

ShowBindCategoryInputDialog(defaultValue := "") {
    global BindCategoryInputResult, BindCategoryInputValue, BindCategoryInputCtrl
    global colorBg, colorCard, colorCardAlt, colorAccent, colorText, colorMuted

    BindCategoryInputResult := ""
    BindCategoryInputValue := ""

    dlg := Gui("+ToolWindow +AlwaysOnTop +Border", "Категория биндов")
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
    BindCategoryInputCtrl := dlg.Add("Edit", "x38 y98 w344 h26 cFFFFFF Background151A22", defaultValue)

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

    dlg := Gui("+ToolWindow +AlwaysOnTop +Border", "ChesNova Cloud")
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
    NickInputEditCtrl := dlg.Add("Edit", "x48 y152 w364 h26 cFFFFFF Background151A22", defaultValue)

    dlg.SetFont("s9 Bold c" colorText, "Segoe UI")
    cancelBtn := dlg.Add("Text", "x226 y198 w90 h30 +0x200 Center Background" colorCardAlt, "Отмена")
    cancelBtn.OnEvent("Click", (*) => CloseNickInputDialog(dlg, "Cancel"))
    okBtn := dlg.Add("Text", "x328 y198 w84 h30 +0x200 Center Background" colorAccent, "OK")
    okBtn.OnEvent("Click", (*) => CloseNickInputDialog(dlg, "OK"))

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
CheckCloudAccess(exitOnDenied := true, promptOnDenied := true) {
    global nick, accessUrl, cloudAccessState, cloudAccessMessage, cloudLastCheck, appVersion

    loop {
        url := accessUrl "?nick=" UriEncode(nick) "&version=" UriEncode(appVersion)

        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", url, false)
            http.Send()
            response := Trim(http.ResponseText)
        } catch as err {
            cloudAccessState := "offline"
            cloudAccessMessage := "Нет связи с Cloud"
            cloudLastCheck := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

            if (promptOnDenied)
                MsgBox("Не удалось проверить доступ.`n`n" err.Message, "ChesNova", "Iconx")

            if (exitOnDenied)
                ExitApp()

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
