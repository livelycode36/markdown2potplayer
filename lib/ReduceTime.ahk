#Requires AutoHotkey v2.0

; 修改秒数并返回新的时间格式
ReduceTime(originalTime, secondsToModify) {
    newSeconds := TimestampToMilliSecond(originalTime) - (secondsToModify * 1000)

    if (newSeconds < 0) {
        newSeconds := 0
    }

    return MilliSecondToTimestamp(newSeconds)
}

GetMilliseconds(originalTime) {
    ms := ""
    if (InStr(originalTime, ".")) {
        ms := SubStr(originalTime, InStr(originalTime, "."))
    }
    return ms
}

; 将时间字符串转换为毫秒
TimestampToMilliSecond(timeStr) {
    if (timeStr = "" ||
        timeStr = "0") {
        return 0
    }
    parts := StrSplit(timeStr, ":")
    milliseconds := 0

    if (InStr(timeStr, ".") > 0) {
        seconds_millis := StrSplit(parts[-1], ".")
        parts[-1] := seconds_millis.Get(1)
        milliseconds := Integer(seconds_millis.Get(2))
    } else {
        milliseconds := 0
    }

    Loop parts.Length
        parts[A_Index] := Integer(parts[A_Index])

    if (parts.Length = 1)
        milliseconds += Integer(parts.Get(1)) * 1000
    else if (parts.Length = 2)
        milliseconds += (Integer(parts.Get(1)) * 60 + Integer(parts.Get(2))) * 1000
    else if (parts.Length = 3)
        milliseconds += (Integer(parts.Get(1)) * 3600 + Integer(parts.Get(2)) * 60 + Integer(parts.Get(3))) * 1000

    return milliseconds
}

RemoveMillisecondFormTimestamp(timestamp) {
    return RegExReplace(timestamp, "\.\d{3}")
}
; 测试不同的时间戳格式
; timestamps := ['0.123', '1', '1:01', '1:01:01', '1:01:01.123']
; Loop timestamps.Length
;     MsgBox TimeToMilliSecond(timestamps[A_Index])

; 将毫秒转换回原始格式
MilliSecondToTimestamp(milliseconds) {
    if (milliseconds == "" ||
        milliseconds == 0) {
        return "00:00"
    }

    ; 1. 确定毫秒中包含多少完整的小时，然后从总毫秒数中减去这些小时对应的毫秒数
    ; 2. 计算剩余毫秒数中包含多少完整的分钟，并同样从剩余毫秒数中减去
    ; 3. 计算剩余毫秒数中包含多少完整的秒，并从剩余毫秒数中减去
    ; 4. 剩余的就是不足一秒的毫秒数
    hours := milliseconds // 3600000
    remainder := Mod(milliseconds, 3600000)

    minutes := remainder // 60000
    remainder := Mod(remainder, 60000)

    seconds := remainder // 1000
    millis := Mod(remainder, 1000)

    ; MsgBox "Hours:" hours '`n' "minutes:" minutes '`n' "seconds:" seconds '`n' "millis:" millis

    result := ""
    if hours > 0
        result .= Format("{:02}", hours) ":"

    if milliseconds > 0
        result .= Format("{:02}", minutes) ":"

    if milliseconds > 0
        result .= Format("{:02}", seconds)

    if millis > 0
        result .= "." Format("{:03}", millis)
    ; 如果毫秒小于1000，则显示0.x毫秒
    else if milliseconds < 1000
        result .= "00:00." Format("{:03}", milliseconds)
    return result
}
; 测试不同的毫秒值
; milliseconds_values := [123, 1000, 60000, 61000, 3600000,3661000, 3661123]
; Loop milliseconds_values.Length
;   MsgBox MilliSecondToTimestamp(milliseconds_values[A_Index])
