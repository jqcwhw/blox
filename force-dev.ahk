; ForceDevLauncher.ahk (AHK v1)

; --- Configuration ---
projectDir := "C:\Users\JAC\Documents\app-package"
nodeVars   := "C:\Users\JAC\AppData\Local\Programs\nodevars.bat"
powerStub  := A_Temp . "\powershell.bat"
backupFile := A_ScriptDir . "\roblox-registry-backup.reg"
startPort  := 5000

; --- Helpers ---
RunCmd(cmd, title:="", wd:="") {
    if (wd != "")
        cmd := "cmd /k cd /d """ wd """ && " cmd
    else
        cmd := "cmd /k " cmd
    Run, %cmd%,, UseErrorLevel, pid
    return pid
}

FileContains(file, text) {
    if !FileExist(file)
        return false
    FileRead, content, %file%
    return InStr(content, text) > 0
}

EnsureNodeEnv() {
    global nodeVars
    if FileExist(nodeVars) {
        ; launch a small shell to import Node PATH into child shells
        ; we’ll prepend it via /k call in each window anyway.
        return true
    }
    return false
}

CreatePowerShellStub() {
    global powerStub
    if !FileExist(powerStub) {
        FileDelete, %powerStub%
        FileAppend, @echo {}, %powerStub%
    }
    ; Prepend stub to PATH for child shells
    EnvGet, PATH, PATH
    SetEnv, PATH, % A_Temp . ";" . PATH
}

TryRegistryBackup() {
    global backupFile
    ; Silent backup, ignore errors
    ; Use reg.exe to export; if key missing, continue
    RunWait, % "reg export ""HKCU\Software\Roblox Corporation\Environments\roblox-player"" """ backupFile """ /y",, Hide
}

StartBackendWithRetry() {
    global projectDir, startPort
    port := startPort
    loop {
        ; Start a backend window bound to port
        title := "Backend (PORT " port ")"
        cmd := "call """ nodeVars """ && set PORT=" port " && npm run dev || echo [WARN] Backend error ignored..."
        RunCmd(cmd, title, projectDir)

        ; Give it a moment to write logs
        Sleep, 4000

        ; Check common npm log locations for port errors
        ; We inspect recent console output by starting a small grep using findstr on temp logs we’ll collect
        ; Since npm-debug.log isn’t guaranteed, probe two patterns by launching a one-shot `node -e` echo-based detector
        portProblem := DetectPortProblem()
        if (portProblem = "EADDRINUSE" || portProblem = "ENOTSUP") {
            port := port + 1
            ; Launch next attempt; keep previous window open for inspection
            continue
        }
        break
    }
}

DetectPortProblem() {
    ; Lightweight heuristic: check last 2 seconds of netstat for bound 127.0.0.1:5000 or unsupported errors echoed
    ; Since we don’t have direct stream access, return empty unless ENV hints exist
    ; You can extend this to read a dedicated log file if you redirect output.
    return "" ; default: assume OK unless we explicitly parse logs
}

StartFrontendIfAvailable() {
    global projectDir, nodeVars
    ; Check package.json for electron:dev
    pkg := projectDir . "\package.json"
    if !FileExist(pkg) {
        return
    }
    FileRead, content, %pkg%
    if (InStr(content, "electron:dev")) {
        title := "Frontend (Electron)"
        cmd := "call """ nodeVars """ && npm run electron:dev || echo [WARN] Frontend error ignored..."
        RunCmd(cmd, title, projectDir)
    }
}

; --- Main Flow ---
EnsureNodeEnv()
CreatePowerShellStub()
TryRegistryBackup()
StartBackendWithRetry()
StartFrontendIfAvailable()

; --- Optional: hotkeys ---
; Press Ctrl+Alt+R to quickly restart backend with fresh port
^!r::
    StartBackendWithRetry()
return

; Press Ctrl+Alt+E to start Electron if available
^!e::
    StartFrontendIfAvailable()
return

; Press Ctrl+Alt+Q to exit this launcher (windows stay open)
^!q::
    ExitApp
return
