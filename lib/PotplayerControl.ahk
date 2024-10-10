#Requires AutoHotkey v2.0
#Include MyTool.ahk

class PotplayerControl {
    __New(potplayer_process_name) {
        this._PotplayerProcessName := potplayer_process_name
        this.COMMAND_TYPE := 273
        this.REQUEST_TYPE := 1024
        this.hwnd := ""
    }

    SendCommand(msg_type, wParam, lParam) {
        hwnd := this.GetPotplayerHwnd()
        return SendMessage(msg_type, wParam, lParam, hwnd)
    }
    PostCommand(msg_type, wParam, lParam) {
        hwnd := this.GetPotplayerHwnd()
        return PostMessage(msg_type, wParam, lParam, hwnd)
    }

    GetOncePotplayerHwnd() {
        if (this.hwnd != "") {
            return this.hwnd
        }
        return this.GetPotplayerHwnd()
    }

    GetPotplayerHwnd() {
        Assert(!WinExist("ahk_exe " this._PotplayerProcessName), "PotPlayer is not running")

        ids := WinGetList("ahk_exe " this._PotplayerProcessName)
        for id in ids {
            title := WinGetTitle("ahk_id " id)
            if (InStr(title, "PotPlayer")) {
                this.hwnd := id
                return id
            }
        }
    }

    GetMediaPathToClipboard() {
        this.PostCommand(this.COMMAND_TYPE, 10928, 0)
    }

    GetMediaTimestampToClipboard() {
        this.PostCommand(this.COMMAND_TYPE, 10924, 0)
    }

    GetSubtitleToClipboard() {
        this.PostCommand(this.COMMAND_TYPE, 10624, 0)
    }
    SaveImageToClipboard() {
        this.SendCommand(this.COMMAND_TYPE, 10223, 0)
    }

    ; 状态
    GetPlayStatus() {
        status := this.SendCommand(this.REQUEST_TYPE, 20486, 0)
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
    PlayOrPause() {
        this.PostCommand(this.COMMAND_TYPE, 20001, 0)
    }
    Play() {
        status := this.GetPlayStatus()
        if (status != "Running") {
            this.PostCommand(this.COMMAND_TYPE, 20000, 0)
        }
    }
    PlayPause() {
        status := this.GetPlayStatus()
        if (status == "Running") {
            this.PostCommand(this.COMMAND_TYPE, 20000, 0)
        }
    }
    Stop() {
        this.PostCommand(this.COMMAND_TYPE, 20002, 0)
    }

    ; 速度
    PreviousFrame() {
        this.PostCommand(this.COMMAND_TYPE, 10242, 0)
    }
    NextFrame() {
        this.PostCommand(this.COMMAND_TYPE, 10241, 0)
    }
    Forward() {
        this.PostCommand(this.COMMAND_TYPE, 10060, 0)
    }
    Backward() {
        this.PostCommand(this.COMMAND_TYPE, 10059, 0)
    }
    SpeedUp() {
        this.PostCommand(this.COMMAND_TYPE, 10248, 0)
    }
    SpeedDown() {
        this.PostCommand(this.COMMAND_TYPE, 10247, 0)
    }
    SpeedNormal() {
        this.PostCommand(this.COMMAND_TYPE, 10246, 0)
    }

    ; 时间
    GetMediaTimeMilliseconds() {
        return this.SendCommand(this.REQUEST_TYPE, 20484, 0)
    }
    ; 受【选项-播放-时间跨度-如果存在关键帧数据则以关键帧为移动单位】的potplayer后处理影响不够精准，关掉此选项则非常精准
    SetMediaTimeMilliseconds(ms) {
        this.PostCommand(this.REQUEST_TYPE, 20485, ms)
    }
    GetCurrentSecondsTime() {
        return Integer(this.GetMediaTimeMilliseconds() / 1000)
    }
    GetTotalTimeSeconds() {
        return Integer(this.SendCommand(this.REQUEST_TYPE, 20482, 0) / 1000)
    }
    SetCurrentSecondsTime(seconds) {
        if (seconds < 0) {
            seconds := 0
        }
        this.SetMediaTimeMilliseconds(seconds * 1000)
    }

    ForwardBySeconds(forward_seconds, potplayer_control) {
        try {
            if (forward_seconds != 0) {
                potplayer_control.SetMediaTimeMilliseconds(Integer(this.GetMediaTimeMilliseconds() + (forward_seconds * 1000)))
            } else {
                potplayer_control.Forward()
            }
        } catch Error as err {
            MsgBox "Forward Seconds and Backward Seconds It can't be empty"
        }
    }
    BackwardBySeconds(backward_seconds, potplayer_control) {
        try {
            if (backward_seconds != 0) {
                potplayer_control.SetMediaTimeMilliseconds(Integer(this.GetMediaTimeMilliseconds() - (backward_seconds * 1000)))
            } else {
                potplayer_control.Backward()
            }
        } catch Error as err {
            MsgBox "Forward Seconds and Backward Seconds It can't be empty"
        }
    }

    ; A-B 循环
    SetStartPointOfTheABCycle() {
        this.PostCommand(this.COMMAND_TYPE, 10249, 0)
    }
    SetEndPointOfTheABCycle() {
        this.PostCommand(this.COMMAND_TYPE, 10250, 0)
    }
    CancelTheABCycle() {
        ; 解除区段循环：起点
        this.PostCommand(this.COMMAND_TYPE, 10251, 0)
        ; 解除区段循环：终点
        this.PostCommand(this.COMMAND_TYPE, 10252, 0)
    }
}

; 示例
; potplayer := PotplayerControl("PotplayerMini64.exe")

; potplayer.SpeedUp()
; potplayer.SpeedDown()
; potplayer.SpeedNormal()
