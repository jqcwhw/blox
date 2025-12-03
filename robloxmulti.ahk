; Roblox Multi-Instance Launcher (AHK v1)
; Launches multiple Roblox clients into Pet Simulator 99 (placeId 8737899170)

robloxExe := "C:\Users\JAC\AppData\Local\Roblox\Versions\version-889d2588b25a43d1"
placeId   := "8737899170"
launcherUrl := "https://assetgame.roblox.com/game/PlaceLauncher.ashx?request=RequestGame&placeId=" placeId "&isPlayTogetherGame=false"

; --- Step 1: Mutex bypass ---
RunWait, powershell -Command "try { $m = New-Object System.Threading.Mutex($false,'ROBLOX_singletonEvent'); $m.WaitOne(0) | Out-Null; while($true){Start-Sleep 5} } catch {}",, Hide

; --- Step 2: Registry tweaks ---
RegWrite, REG_DWORD, HKEY_CURRENT_USER\SOFTWARE\Roblox Corporation\Roblox, MultipleRoblox, 1
RegWrite, REG_DWORD, HKEY_CURRENT_USER\SOFTWARE\Roblox Corporation\Roblox, SingletonMutex, 0

; --- Step 3: Launch methods ---
LaunchDirect() {
    global robloxExe, launcherUrl
    Run, "%robloxExe%" --app -j "%launcherUrl%",, UseErrorLevel
}

LaunchProtocol() {
    global placeId
    proto := "roblox-player:1+launchmode:play+placeId:" placeId "+launchtime:" A_Now
    Run, cmd /c start "" "%proto%",, Hide
}

; --- Step 4: Try multiple approaches ---
; Direct launch
LaunchDirect()
Sleep, 2000

; Protocol fallback
LaunchProtocol()
Sleep, 2000

; Extra direct instances
Loop, 2 {
    LaunchDirect()
    Sleep, 1000
}

MsgBox, Multi-instance launcher finished. Roblox should now be running multiple clients.
