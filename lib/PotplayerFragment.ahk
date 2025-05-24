#Requires AutoHotkey v2.0
; PotplayerFragment.ahk
; 提供AB片段/循环播放、同视频判断、AB循环取消等可复用函数

; 判断当前播放的视频，是否是跳转的视频
IsSameVideo(potplayer_control, jump_path) {
    ; 判断网络视频
    if (InStr(jump_path, "http")) {
        current_path := GetPotplayerpath(potplayer_control)
        if (InStr(jump_path, current_path)) {
            return true
        }
        return false
    }
    ; 判断本地视频
    potplayer_title := WinGetTitle("ahk_id " potplayer_control.getHwnd())
    video_name := GetNameForPath(UrlDecode(jump_path))
    if (InStr(potplayer_title, video_name)) {
        return true
    }
    return false
}

GetPotplayerpath(potplayer_control) {
    A_Clipboard := ""
    potplayer_control.GetMediaPathToClipboard()
    if (!ClipWait(1, 0)) {
        return ""
    }
    return A_Clipboard
}

; 取消A-B循环（如果已设置）
CancelABCycleIfNeeded(potplayer_control, potplayer_path, jump_path) {
    if (IsPotplayerRunning(potplayer_path)
        && potplayer_control.GetPlayStatus() != "Stopped"
        && IsSameVideo(potplayer_control, jump_path)) {
        potplayer_control.CancelTheABCycle()
    }
}

; 单次播放AB片段
JumpToAbFragment(potplayer_control, potplayer_path, media_path, time_start, time_end, ab_fragment_detection_delays) {
    ; 1. 跳转到片段起点
    if (IsPotplayerRunning(potplayer_path)
        && potplayer_control.GetPlayStatus() != "Stopped"
        && IsSameVideo(potplayer_control, media_path)) {

        potplayer_control.SetMediaTimeMilliseconds(TimestampToMilliseconds(time_start))
        potplayer_control.Play()
    } else {
        run_command := potplayer_path . " `"" . media_path . "`" /seek=" . time_start . " /current"
        try {
            Run run_command
        } catch Error as err {
            MsgBox "错误：" err.Extra
            MsgBox run_command
            return
        }
    }
    ; 等待
    Sleep 1000

    flag_ab_fragment := true

    Hotkey "Esc", CancelAbFragment
    CancelAbFragment(*) {
        flag_ab_fragment := false
        Hotkey "Esc", "off"
    }

    ; 2. 检查结束时间
    ; duration := TimestampToMilliseconds(time_end) - TimestampToMilliseconds(time_start)
    ; past := 0
    ; 3. 检查结束时间
    while (flag_ab_fragment) {
        ; 异常情况：用户关闭Potplayer
        if (!IsPotplayerRunning(potplayer_path)) {
            MsgBox("异常情况：用户关闭Potplayer")
            break
        ; 异常情况：用户停止播放视频
        } else if (potplayer_control.GetPlayStatus() != "Running") {
            MsgBox("异常情况：用户停止播放视频")
            break
        }

        ; todo: 异常情况：不是同一个视频
        ; - 在播放B站视频时，可以加载视频列表，这样用户就会切换视频，此时就要结束循环 else if (!IsSameVideo(media_path)) {break}
        ; - 另一种思路：当前循环的时间超过了时间期间，就结束循环； +1是为了防止误差
        ; else if (past >= duration + 1000) {
        ;   break
        ; }

        ; 正常情况：当前播放时间超过了结束时间、用户手动调整时间，超过了结束时间
        current_time := potplayer_control.GetMediaTimeMilliseconds()
        if (current_time >= TimestampToMilliseconds(time_end)) {
            potplayer_control.PlayPause()
            Hotkey "Esc", "off"
            flag_ab_fragment := false
            MsgBox("正常情况：当前播放时间超过了结束时间、用户手动调整时间，超过了结束时间")
            break
        }
        Sleep ab_fragment_detection_delays
        ; past += ab_fragment_detection_delays
    }

    ; potplayer_control.PlayPause()
    ; Hotkey "Esc", "off"
}

; 循环播放AB片段
JumpToAbCirculation(potplayer_control, potplayer_path, media_path, time_start, time_end) {
    if (IsPotplayerRunning(potplayer_path)
        && potplayer_control.GetPlayStatus() != "Stopped"
        && IsSameVideo(potplayer_control, media_path)) {
        potplayer_control.SetMediaTimeMilliseconds(TimestampToMilliseconds(time_start))
        potplayer_control.SetStartPointOfTheABCycle()
        potplayer_control.SetMediaTimeMilliseconds(TimestampToMilliseconds(time_end))
        potplayer_control.SetEndPointOfTheABCycle()
        potplayer_control.Play()
    } else {
        run_command := potplayer_path . " `"" . media_path . "`" /seek=" . time_start . " /current"
        try {
            Run run_command
        } catch Error as err {
            MsgBox "错误：" err.Extra
            MsgBox run_command
            return
        }
        Sleep 1000
        potplayer_control.SetMediaTimeMilliseconds(TimestampToMilliseconds(time_start))
        potplayer_control.SetStartPointOfTheABCycle()
        potplayer_control.SetMediaTimeMilliseconds(TimestampToMilliseconds(time_end))
        potplayer_control.SetEndPointOfTheABCycle()
        potplayer_control.Play()
    }
} 