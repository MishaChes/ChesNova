#Requires AutoHotkey v2.0
#SingleInstance Force

; ChesNova Launcher: ensures the main script exists, then starts it through UI Access.
ScriptUrl := "https://raw.githubusercontent.com/MishaChes/ChesNova/main/versions/ChesNova.ahk"

; All ChesNova files and user data live in Documents\ChesNova.
AppDir := A_MyDocuments "\ChesNova"
MainScript := AppDir "\ChesNova.ahk"
NewScript := AppDir "\ChesNova_new.ahk"

DirCreate(AppDir)

if IsChesNovaRunning(MainScript) {
    MsgBox("ChesNova уже запущена.")
    ExitApp
}

; The launcher downloads only on the first start, when the main file is missing.
if !FileExist(MainScript) {
    scriptText := ""
    if !HttpGet(ScriptUrl, &scriptText) {
        if !FileExist(MainScript) {
            ShowDownloadError()
            ExitApp
        }
    } else {
        try {
            if FileExist(NewScript)
                FileDelete(NewScript)
            FileAppend(scriptText, NewScript, "UTF-8")
            FileMove(NewScript, MainScript, 1)
        } catch {
            if !FileExist(MainScript) {
                ShowDownloadError()
                ExitApp
            }
        }
    }
}

if !FileExist(MainScript) {
    ShowDownloadError()
    ExitApp
}

uiaPath := FindUiAccess()
if (uiaPath = "") {
    MsgBox("Не найден AutoHotkey UI Access. ChesNova не может быть запущена.")
    ExitApp
}

Run('"' uiaPath '" "' MainScript '"')
ExitApp


ShowDownloadError() {
    MsgBox("Не удалось загрузить ChesNova." . Chr(10) . Chr(10) . "Проверьте подключение к интернету.")
}


HttpGet(url, &responseText) {
    responseText := ""
    try {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        ; Short timeouts keep the launcher from lingering when GitHub is unavailable.
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
    ; A launcher started by a UIA executable can use that executable directly.
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
        for process in ComObjGet("winmgmts:").ExecQuery("SELECT CommandLine FROM Win32_Process") {
            if (process.CommandLine != "" && InStr(StrLower(process.CommandLine), target))
                return true
        }
    }
    return false
}
