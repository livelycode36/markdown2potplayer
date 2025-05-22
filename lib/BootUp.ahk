#Requires AutoHotkey v2.0

key := "markdown2potplayer"
value := "`"" A_ScriptDir "\" key ".exe`""

set_boot_up(){
    RegWrite value, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", key
}

get_boot_up(){
    try
        regValue := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", key)
    catch as OSError ; if the key doesn't exist
        return false
    
    if (regValue == value)
        return true
    else
        return false
}

remove_boot_up(){
    try
        RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", key)
    catch as OSError ; if the key doesn't exist
        return false
}

adaptive_bootup(){
    if get_boot_up(){
        remove_boot_up()
        MsgBox "Startup launch: OFF"
    }
    else{
        set_boot_up()
        MsgBox "Startup launch: ON"
    }
}