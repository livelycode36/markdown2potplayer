#Requires AutoHotkey v2.0

; ======================================================================================================================
; 函数: MillisecondsToTimestamp
; 描述: 将毫秒转换为自定义时间戳格式 (HH:MM:SS.mmm 或 MM:SS.mmm).
; 参数: ms - 输入的毫秒数 (整数).
; 返回: 格式化的时间戳字符串. 如果输入无效则返回 "Invalid input".
; ======================================================================================================================
MillisecondsToTimestamp(ms) {
  if !IsInteger(ms) || ms < 0 {
    return "Invalid input"
  }


  local milliseconds := Mod(ms, 1000)
  local totalSeconds := Floor(ms / 1000)
  local seconds := Mod(totalSeconds, 60)
  local totalMinutes := Floor(totalSeconds / 60)
  local minutes := Mod(totalMinutes, 60)
  local hours := Floor(totalMinutes / 60)

  local formattedMs := Format("{:03}", milliseconds)
  local formattedS := Format("{:02}", seconds)
  local formattedM := Format("{:02}", minutes)

  if (hours > 0)
    return Format("{:02}:{}:{}.{}", hours, formattedM, formattedS, formattedMs)
  else
    return Format("{}:{}.{}", formattedM, formattedS, formattedMs)
}

; ======================================================================================================================
; 函数: TimestampToMilliseconds
; 描述: 将自定义时间戳格式 (HH:MM:SS.mmm 或 MM:SS.mmm) 转换为毫秒.
; 参数: timestamp - 格式化的时间戳字符串.
; 返回: 毫秒数 (整数). 如果格式无效则返回空字符串 "" (AHK中常用于表示失败或无效).
; ======================================================================================================================
TimestampToMilliseconds(timestamp) {
  if (!IsObject(timestamp) && !timestamp == "") {
    return ""
  }

  local parts := StrSplit(timestamp, ":")
  local hours := 0, minutes := 0, seconds := 0, milliseconds := 0

  try {
    if (parts.Length == 3) { ; HH:MM:SS.mmm
      hours := Integer(parts[1])
      minutes := Integer(parts[2])
      local secMsParts := StrSplit(parts[3], ".")
      if (secMsParts.Length != 2)
        return ""
      seconds := Integer(secMsParts[1])
      milliseconds := Integer(secMsParts[2])
    } else if (parts.Length == 2) { ; MM:SS.mmm
      minutes := Integer(parts[1])
      local secMsParts := StrSplit(parts[2], ".")
      if (secMsParts.Length != 2)
        return ""
      seconds := Integer(secMsParts[1])
      milliseconds := Integer(secMsParts[2])
    } else {
      return "" ; 无效格式
    }

    if (hours < 0 || minutes < 0 || minutes >= 60 || seconds < 0 || seconds >= 60 || milliseconds < 0 || milliseconds >= 1000)
      return "" ; 数值范围无效

  } catch Error as e {
    ; MsgBox "Error during conversion: " e.Message
    return "" ; 转换出错
  }

  return (hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds
}

; ======================================================================================================================
; 函数: FormatDuration
; 描述: 格式化毫秒为易读的持续时间字符串 (一个方便操作的函数示例).
;       这个函数与 MillisecondsToTimestamp 类似，但可以根据需要进行扩展.
; 参数: ms - 输入的毫秒数 (整数).
; 返回: 格式化的持续时间字符串.
; ======================================================================================================================
FormatDuration(ms) {
  ; 对于这个示例，我们让它和 MillisecondsToTimestamp 的行为一致
  return MillisecondsToTimestamp(ms)
}

; 函数: RemoveMillisecondsFromTimestamp
; 描述: 从时间戳字符串中移除毫秒部分.
;       例如 "01:01.012" 变为 "01:01", "25:01:01.012" 变为 "25:01:01".
; 参数: timestamp - 输入的时间戳字符串.
; 返回: 移除了毫秒部分的时间戳字符串. 如果输入不包含 '.', 则原样返回.
; ======================================================================================================================
RemoveMillisecondsFromTimestamp(timestamp) {
  if timestamp = "" {
    return timestamp ; 如果不是字符串，直接返回原值
  }

  local pos := InStr(timestamp, ".")
  if (pos > 0)
    return SubStr(timestamp, 1, pos - 1)
  else
    return timestamp ; 没有找到 '.', 原样返回
}

IsInteger(val) {
  return RegExMatch(val, "^[-+]?\d+$")
}

; ======================================================================================================================
; 示例用法
; ======================================================================================================================
; MsgBox "--- 移除时间戳中的毫秒部分 ---" Chr(10)
;   . "Input: `" 01: 01.012`" -> Output: `" " RemoveMillisecondsFromTimestamp(" 01: 01.012 ") "`"" Chr(10)
;   . "Input: `" 25: 01: 01.012`" -> Output: `" " RemoveMillisecondsFromTimestamp(" 25: 01: 01.012 ") "`"" Chr(10)
;   . "Input: `" 00: 59.999`" -> Output: `" " RemoveMillisecondsFromTimestamp(" 00: 59.999 ") "`"" Chr(10)
;   . "Input: `" 10: 30`" (no ms) -> Output: `" " RemoveMillisecondsFromTimestamp(" 10: 30 ") "`"" Chr(10)
;   . "Input: `" Invalid.Format`" -> Output: `" " RemoveMillisecondsFromTimestamp(" Invalid.Format ") "`"" Chr(10)
;   . "Input: `" AnotherInvalid`" -> Output: `" " RemoveMillisecondsFromTimestamp(" AnotherInvalid ") "`"" Chr(10)
;   . "Input: 123 (not a string) -> Output: " RemoveMillisecondsFromTimestamp(123) ; 数字输入

; MsgBox "--- 毫秒转时间戳 ---" Chr(10)
;   . "61012 ms: " MillisecondsToTimestamp(61012) Chr(10) ; 01:01.012
;   . "3661012 ms: " MillisecondsToTimestamp(3661012) Chr(10) ; 01:01:01.012
;   . "90061012 ms: " MillisecondsToTimestamp(90061012) Chr(10) ; 25:01:01.012
;   . "123 ms: " MillisecondsToTimestamp(123) Chr(10) ; 00:00.123
;   . "59999 ms: " MillisecondsToTimestamp(59999) Chr(10) ; 00:59.999
;   . "0 ms: " MillisecondsToTimestamp(0) Chr(10) ; 00:00.000
;   . "-100 ms (invalid): " MillisecondsToTimestamp(-100) Chr(10)
;   . "A_ScreenWidth (invalid type): " MillisecondsToTimestamp(A_ScreenWidth) ; 演示非数字输入

; MsgBox "--- 时间戳转毫秒 ---" Chr(10)
;   . "`" 01: 01.012`": " TimestampToMilliseconds("01:01.012") Chr(10) ; 61012
;   . "`" 01: 01: 01.012`": " TimestampToMilliseconds("01:01:01.012") Chr(10) ; 3661012
;   . "`" 25: 01: 01.012`": " TimestampToMilliseconds("25:01:01.012") Chr(10) ; 90061012
;   . "`" 00: 00.123`": " TimestampToMilliseconds("00:00.123") Chr(10) ; 123
;   . "`" 00: 59.999`": " TimestampToMilliseconds("00:59.999") Chr(10) ; 59999
;   . "`" 00: 00.000`": " TimestampToMilliseconds("00:00.000") Chr(10) ; 0
;   . "`" 1: 1.1`" (invalid format): " TimestampToMilliseconds("1:1.1") Chr(10)
;   . "`" 60: 00.000`" (invalid minutes): " TimestampToMilliseconds("60:00.000") Chr(10)
;   . "`" 00: 60.000`" (invalid seconds): " TimestampToMilliseconds("00:60.000") Chr(10)
;   . "`" 00: 00.1000`" (invalid ms): " TimestampToMilliseconds("00:00.1000") Chr(10)
;   . "`" 10: 20: 30`" (invalid format, missing ms): " TimestampToMilliseconds("10:20:30") Chr(10)
;   . "`" - 01: 00: 00.000`" (invalid format): " TimestampToMilliseconds("-01:00:00.000")

; MsgBox "--- formatDuration (方便操作的函数) ---" Chr(10)
;   . "90061012 ms using formatDuration: " FormatDuration(90061012) ; 25:01:01.012