#Requires AutoHotkey v2.0
#Include MyTool.ahk

class PotplayerController {
    __New(potplayer_process_name){
        this._PotplayerProcessName := potplayer_process_name
        this.COMMAND_TYPE := 273
        this.REQUEST_TYPE := 1024
    }

    SendCommand(msg_type,wParam,lParam){
        hwnd := this.GetPotplayerHwnd()
        return SendMessage(msg_type,wParam,lParam,hwnd)
    }
    PostCommand(msg_type,wParam,lParam){
        hwnd := this.GetPotplayerHwnd()
        return PostMessage(msg_type,wParam,lParam,hwnd)
    }

    GetPotplayerHwnd(){
        Assert(!WinExist("ahk_exe" this._PotplayerProcessName), "PotPlayer is not running")

        ids := WinGetList("ahk_exe" this._PotplayerProcessName)
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
        this.PostCommand(this.COMMAND_TYPE,10928,0)
    }

    GetMediaTimestampToClipboard(){
        this.PostCommand(this.COMMAND_TYPE,10924,0)
    }
    GetMediaTimeMilliseconds(){
        return this.SendCommand(this.REQUEST_TYPE,20484,0)
    }
    SaveImageToClipboard(){
        this.SendCommand(this.COMMAND_TYPE,10223,0)
    }
    Pause(){
        status := this.GetPlayStatus()
        if (status == "Running"){
            this.PostCommand(this.COMMAND_TYPE,20000,0)
        }
    }
    GetPlayStatus(){
        status := this.SendCommand(this.REQUEST_TYPE,20486,0)
        switch status {
            case -1:
                return "Stopped"
            case 1:
                return "Paused"
            case 2:
                return "Running"
        }
    }
    GetCurrentSecondsTime(){
        return Integer(this.SendCommand(this.REQUEST_TYPE,20484,0)/1000)
    }
    SetCurrentSecondsTime(seconds){
        if (seconds < 0){
            seconds := 0
        }
        this.PostCommand(this.REQUEST_TYPE,20485, seconds * 1000)
    }

    SetStartPointOfTheABCycle(){
        this.PostCommand(this.COMMAND_TYPE,10249,0)
    }

    SetEndPointOfTheABCycle(){
        this.PostCommand(this.COMMAND_TYPE,10250,0)
    }
}