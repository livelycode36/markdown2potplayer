#Requires AutoHotkey v2.0

; potplayer_name := "PotPlayerMini64.exe"

COMMAND_TYPE := 273
REQUEST_TYPE := 1024

SendCommand(msg_type,wParam,lParam){
    hwnd := GetPotplayerHwnd()
    return SendMessage(msg_type,wParam,lParam,hwnd)
}
PostCommand(msg_type,wParam,lParam){
    hwnd := GetPotplayerHwnd()
    return PostMessage(msg_type,wParam,lParam,hwnd)
}

GetPotplayerHwnd(){
    if WinExist("ahk_exe" potplayer_name) == 0{
        throw "PotPlayer is not running"
        ; MsgBox "PotPlayer is not running"
        ; Exit
    }
    ids := WinGetList("ahk_exe" potplayer_name)
    hwnd := ""
    for id in ids{
        title := WinGetTitle("ahk_id" id)
        if (InStr(title, "PotPlayer")){
            hwnd := id
            break
        }
    }
    return hwnd
}

GetMediaPathToClipboard(){
    PostCommand(COMMAND_TYPE,10928,0)
}

GetMediaTimestampToClipboard(){
    PostCommand(COMMAND_TYPE,10924,0)
}
GetMediaTimeMilliseconds(){
    return SendCommand(REQUEST_TYPE,20484,0)
}
SaveImageToClipboard(){
    SendCommand(COMMAND_TYPE,10223,0)
}
Pause(){
    status := GetPlayStatus()
    if (status == "Running"){
        PostCommand(COMMAND_TYPE,20000,0)
    }
}
GetPlayStatus(){
    status := SendCommand(REQUEST_TYPE,20486,0)
    switch status {
        case -1:
            return "Stopped"
        case 1:
            return "Paused"
        case 2:
            return "Running"
    }
}
