#Requires AutoHotkey v2.0
#Include MyTool.ahk

class PotplayerControl {
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
        Assert(!WinExist("ahk_exe " this._PotplayerProcessName), "PotPlayer is not running")

        ids := WinGetList("ahk_exe " this._PotplayerProcessName)
        hwnd := ""
        for id in ids{
            title := WinGetTitle("ahk_id " id)
            if (InStr(title, "PotPlayer")){
                hwnd := id
                break
            }
        }
        return hwnd
    }

    ; 剪切板
    GetMediaPathToClipboard(){
        this.PostCommand(this.COMMAND_TYPE,10928,0)
    }

    GetMediaTimestampToClipboard(){
        this.PostCommand(this.COMMAND_TYPE,10924,0)
    }
    SaveImageToClipboard(){
        this.SendCommand(this.COMMAND_TYPE,10223,0)
    }

    ; 状态
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
        return "Undefined"
    }
    Play(){
        this.PostCommand(this.COMMAND_TYPE,20001,0)
    }
    Pause(){
        this.PostCommand(this.COMMAND_TYPE,20000,0)

    }
    PlayPause(){
        status := this.GetPlayStatus()
        if (status == "Running"){
            this.PostCommand(this.COMMAND_TYPE,20000,0)
        }
    }
    Stop(){
        this.PostCommand(this.COMMAND_TYPE,20002,0)
    }

    ; 速度
    PreviousFrame(){
        this.PostCommand(this.COMMAND_TYPE,10242,0)
    }
    NextFrame(){
        this.PostCommand(this.COMMAND_TYPE,10241,0)
    }
    Forward(){
        this.PostCommand(this.COMMAND_TYPE,10060,0)
    }
    Backward(){
        this.PostCommand(this.COMMAND_TYPE,10059,0)
    }
    SpeedUp(){
        this.PostCommand(this.COMMAND_TYPE,10248,0)
    }
    SpeedDown(){
        this.PostCommand(this.COMMAND_TYPE,10247,0)
    }
    SpeedNormal(){
        this.PostCommand(this.COMMAND_TYPE,10246,0)
    }

    ; 时间
    GetMediaTimeMilliseconds(){
        return this.SendCommand(this.REQUEST_TYPE,20484,0)
    }
    SetMediaTimeMilliseconds(ms){
        this.PostCommand(this.REQUEST_TYPE,20485, ms)
    }
    GetCurrentSecondsTime(){
        return Integer(this.GetMediaTimeMilliseconds()/1000)
    }
    GetTotalTimeSeconds(){
        return Integer(this.SendCommand(this.REQUEST_TYPE,20482,0)/1000)
    }
    SetCurrentSecondsTime(seconds){
        if (seconds < 0){
            seconds := 0
        }
        this.SetMediaTimeMilliseconds(seconds*1000)
    }

    ; A-B 循环
    SetStartPointOfTheABCycle(){
        this.PostCommand(this.COMMAND_TYPE,10249,0)
    }
    SetEndPointOfTheABCycle(){
        this.PostCommand(this.COMMAND_TYPE,10250,0)
    }
}

; 示例
; potplayer := PotplayerControl("PotplayerMini64.exe")

; potplayer.SpeedUp()
; potplayer.SpeedDown()
; potplayer.SpeedNormal()