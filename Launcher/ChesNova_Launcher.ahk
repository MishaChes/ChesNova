#Requires AutoHotkey v2.0
#SingleInstance Force
FileEncoding "UTF-8"

; ChesNova Launcher owns only bootstrap, UI Access and the Windows Run entry.
ScriptUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/ChesNova.ahk"
AppDir := A_MyDocuments "\ChesNova"
LauncherPath := AppDir "\ChesNovaLauncher.ahk"
MainScript := AppDir "\ChesNova.ahk"
restartRequested := false
for arg in A_Args {
    if (arg = "--restart") {
        restartRequested := true
        break
    }
}

DirCreate(AppDir)
DirCreate(AppDir "\data")
DirCreate(AppDir "\logs")
DirCreate(AppDir "\backups")

; The downloaded launcher moves itself to its permanent location exactly once.
if (StrLower(A_ScriptFullPath) != StrLower(LauncherPath)) {
    try FileCopy(A_ScriptFullPath, LauncherPath, 1)
    catch as err {
        MsgBox("Не удалось скопировать ChesNovaLauncher в папку Documents\ChesNova.`n`n" err.Message, "ChesNova", "Iconx")
        ExitApp()
    }

    Run('"' A_AhkPath '" "' LauncherPath '"')
    ExitApp()
}

; A restart starts this launcher before the old main process has fully exited.
if restartRequested
    Sleep(800)

if IsChesNovaRunning(MainScript) {
    MsgBox("ChesNova уже запущена.", "ChesNova", "Icon!")
    ExitApp()
}

; Download only on the first run. Existing local ChesNova.ahk is never updated here.
if !FileExist(MainScript) {
    scriptText := ""
    if !HttpGet(ScriptUrl, &scriptText) {
        ShowDownloadError()
        ExitApp()
    }

    try FileAppend(scriptText, MainScript, "UTF-8")
    catch as err {
        MsgBox("Не удалось сохранить ChesNova.ahk.`n`n" err.Message, "ChesNova", "Iconx")
        ExitApp()
    }
}

uiaPath := FindUiAccess()
if (uiaPath = "") {
    MsgBox("Не найден AutoHotkey UI Access. ChesNova не может быть запущена.", "ChesNova", "Icon!")
    ExitApp()
}

Run('"' uiaPath '" "' MainScript '" --launched-by-chesnova-launcher')
ExitApp()

ShowDownloadError() {
    MsgBox("Не удалось загрузить ChesNova.`n`nПроверьте подключение к интернету.", "ChesNova", "Iconx")
}

HttpGet(url, &responseText) {
    responseText := ""
    try {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.SetTimeouts(1000, 1000, 1500, 1500)
        request.Open("GET", url, false)
        request.Send()
        if (request.Status != 200)
            return false
        responseText := request.ResponseText
        return true
    } catch {
        return false
    }
}

FindUiAccess() {
    if InStr(StrLower(A_AhkPath), "_uia.exe")
        return A_AhkPath

    candidates := [
        "C:\Program Files\AutoHotkey\AutoHotkeyU64_UIA.exe",
        "C:\Program Files\AutoHotkey\v2\AutoHotkey64_UIA.exe",
        "C:\Program Files\AutoHotkey\v1.1\AutoHotkeyU64_UIA.exe",
        "C:\Program Files (x86)\AutoHotkey\AutoHotkeyU64_UIA.exe"
    ]
    for path in candidates {
        if FileExist(path)
            return path
    }
    return ""
}

IsChesNovaRunning(mainScript) {
    target := StrLower(mainScript)
    try {
        for process in ComObjGet("winmgmts:").ExecQuery("SELECT Name, CommandLine FROM Win32_Process") {
            if (process.Name != "" && RegExMatch(process.Name, "i)^AutoHotkey.*\.exe$")
                && process.CommandLine != "" && InStr(StrLower(process.CommandLine), target))
                return true
        }
    }
    return false
}
