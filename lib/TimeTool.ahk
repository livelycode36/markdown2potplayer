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
; 描述: 将自定义时间戳格式转换为毫秒，支持多种灵活格式:
;       - 纯秒数: "123"
;       - HH:MM:SS.mmm 或 HH:MM:SS (可选毫秒)
;       - MM:SS.mmm 或 MM:SS (可选毫秒)  
;       - SS.mmm (秒.毫秒，毫秒1-3位)
;       - 支持前导零可选，毫秒位数1-3位
; 参数: timestamp - 格式化的时间戳字符串或纯秒数.
; 返回: 毫秒数 (整数). 如果格式无效则返回空字符串 "" (AHK中常用于表示失败或无效).
; ======================================================================================================================
TimestampToMilliseconds(timestamp) {
  if (!IsObject(timestamp) && !timestamp == "") {
    return ""
  }

  ; 检查是否为纯秒数格式 (只包含数字，无冒号和小数点)
  if (RegExMatch(timestamp, "^\d+$")) {
    try {
      local seconds := Integer(timestamp)
      if (seconds >= 0)
        return seconds * 1000
      else
        return ""
    } catch Error as e {
      return ""
    }
  }

  local hours := 0, minutes := 0, seconds := 0, milliseconds := 0

  try {
    ; 检查是否包含冒号
    if (InStr(timestamp, ":")) {
      local parts := StrSplit(timestamp, ":")
      
      if (parts.Length == 3) { ; HH:MM:SS.mmm 或 HH:MM:SS
        hours := Integer(parts[1])
        minutes := Integer(parts[2])
        
        ; 检查第三部分是否包含毫秒
        if (InStr(parts[3], ".")) {
          local secMsParts := StrSplit(parts[3], ".")
          if (secMsParts.Length != 2)
            return ""
          seconds := Integer(secMsParts[1])
          local msStr := secMsParts[2]
          ; 毫秒可以是1-3位，需要补齐到3位进行计算
          if (RegExMatch(msStr, "^\d{1,3}$")) {
            if (StrLen(msStr) == 1)
              milliseconds := Integer(msStr) * 100
            else if (StrLen(msStr) == 2)
              milliseconds := Integer(msStr) * 10
            else
              milliseconds := Integer(msStr)
          } else {
            return ""
          }
        } else {
          ; 没有毫秒部分
          seconds := Integer(parts[3])
          milliseconds := 0
        }
        
      } else if (parts.Length == 2) { ; MM:SS.mmm 或 MM:SS
        minutes := Integer(parts[1])
        
        ; 检查第二部分是否包含毫秒
        if (InStr(parts[2], ".")) {
          local secMsParts := StrSplit(parts[2], ".")
          if (secMsParts.Length != 2)
            return ""
          seconds := Integer(secMsParts[1])
          local msStr := secMsParts[2]
          ; 毫秒可以是1-3位，需要补齐到3位进行计算
          if (RegExMatch(msStr, "^\d{1,3}$")) {
            if (StrLen(msStr) == 1)
              milliseconds := Integer(msStr) * 100
            else if (StrLen(msStr) == 2)
              milliseconds := Integer(msStr) * 10
            else
              milliseconds := Integer(msStr)
          } else {
            return ""
          }
        } else {
          ; 没有毫秒部分
          seconds := Integer(parts[2])
          milliseconds := 0
        }
        
      } else {
        return "" ; 无效格式
      }
      
    } else if (InStr(timestamp, ".")) {
      ; SS.mmm 格式（只有秒和毫秒）
      local secMsParts := StrSplit(timestamp, ".")
      if (secMsParts.Length != 2)
        return ""
      
      seconds := Integer(secMsParts[1])
      local msStr := secMsParts[2]
      ; 毫秒可以是1-3位，需要补齐到3位进行计算
      if (RegExMatch(msStr, "^\d{1,3}$")) {
        if (StrLen(msStr) == 1)
          milliseconds := Integer(msStr) * 100
        else if (StrLen(msStr) == 2)
          milliseconds := Integer(msStr) * 10
        else
          milliseconds := Integer(msStr)
      } else {
        return ""
      }
      
    } else {
      return "" ; 无效格式
    }

    ; 验证数值范围
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
; 描述: 从时间戳字符串或时间片段中移除毫秒部分.
;       支持单个时间戳: "01:01.012" 变为 "01:01", "25:01:01.012" 变为 "25:01:01"
;       支持时间片段: "00:24.271-00:31.089" 变为 "00:24-00:31"
; 参数: timestamp - 输入的时间戳字符串或时间片段字符串.
; 返回: 移除了毫秒部分的时间戳字符串或时间片段. 如果输入不包含 '.', 则原样返回.
; ======================================================================================================================
RemoveMillisecondsFromTimestamp(timestamp) {
  if timestamp = "" {
    return timestamp ; 如果为空字符串，直接返回原值
  }

  ; 检查是否包含连字符，判断是否为时间片段格式
  local dashPos := InStr(timestamp, "-")
  if (dashPos > 0) {
    ; 处理时间片段格式 "00:24.271-00:31.089"
    local startTime := SubStr(timestamp, 1, dashPos - 1)
    local endTime := SubStr(timestamp, dashPos + 1)

    ; 分别处理开始时间和结束时间的毫秒
    local processedStart := RemoveMillisecondsFromSingleTimestamp(startTime)
    local processedEnd := RemoveMillisecondsFromSingleTimestamp(endTime)

    return processedStart "-" processedEnd
  } else {
    ; 处理单个时间戳格式
    return RemoveMillisecondsFromSingleTimestamp(timestamp)
  }
}

; 辅助函数: 处理单个时间戳的毫秒移除
; 参数: singleTimestamp - 单个时间戳字符串
; 返回: 移除毫秒后的时间戳
RemoveMillisecondsFromSingleTimestamp(singleTimestamp) {
  if singleTimestamp = "" {
    return singleTimestamp
  }

  local pos := InStr(singleTimestamp, ".")
  if (pos > 0)
    return SubStr(singleTimestamp, 1, pos - 1)
  else
    return singleTimestamp ; 没有找到 '.', 原样返回
}

; ======================================================================================================================
; 函数: RemoveMillisecondsFromTimeRange
; 描述: 从时间段字符串中移除毫秒部分，支持两种分隔符：- 和 ∞
;       例如 "09:19.237-14:13.934" 变为 "09:19-14:13"
;       例如 "19:33.470∞25:10.986" 变为 "19:33∞25:10"
;       如果输入是单个时间戳，则调用 RemoveMillisecondsFromTimestamp 处理
; 参数: timeRange - 输入的时间段字符串或单个时间戳
; 返回: 移除了毫秒部分的时间段字符串
; ======================================================================================================================
RemoveMillisecondsFromTimeRange(timeRange) {
  if timeRange = "" {
    return timeRange
  }

  ; 检查是否包含 "-" 分隔符
  local dashPos := InStr(timeRange, "-")
  if (dashPos > 0) {
    ; 分割时间段
    local startTime := SubStr(timeRange, 1, dashPos - 1)
    local endTime := SubStr(timeRange, dashPos + 1)
    
    ; 分别处理起始和结束时间
    local cleanStartTime := RemoveMillisecondsFromTimestamp(startTime)
    local cleanEndTime := RemoveMillisecondsFromTimestamp(endTime)
    
    return cleanStartTime "-" cleanEndTime
  }
  
  ; 检查是否包含 "∞" 分隔符
  local infinityPos := InStr(timeRange, "∞")
  if (infinityPos > 0) {
    ; 分割时间段
    local startTime := SubStr(timeRange, 1, infinityPos - 1)
    local endTime := SubStr(timeRange, infinityPos + 1)
    
    ; 分别处理起始和结束时间
    local cleanStartTime := RemoveMillisecondsFromTimestamp(startTime)
    local cleanEndTime := RemoveMillisecondsFromTimestamp(endTime)
    
    return cleanStartTime "∞" cleanEndTime
  }
  
  ; 如果没有分隔符，当作单个时间戳处理
  return RemoveMillisecondsFromTimestamp(timeRange)
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

; MsgBox "--- 时间戳转毫秒 ---" Chr(10)
; . "`" 01: 01.012`": " TimestampToMilliseconds("01:01.012") Chr(10) ; 61012
; . "`" 01: 01: 01.012`": " TimestampToMilliseconds("01:01:01.012") Chr(10) ; 3661012
; . "`" 25: 01: 01.012`": " TimestampToMilliseconds("25:01:01.012") Chr(10) ; 90061012
; . "`" 00: 00.123`": " TimestampToMilliseconds("00:00.123") Chr(10) ; 123
; . "`" 00: 59.999`": " TimestampToMilliseconds("00:59.999") Chr(10) ; 59999
; . "`" 00: 00.000`": " TimestampToMilliseconds("00:00.000") Chr(10) ; 0

; MsgBox "--- 纯秒数格式测试 (新功能) ---" Chr(10)
; . "`"0`": " TimestampToMilliseconds("0") Chr(10) ; 0
; . "`"1`": " TimestampToMilliseconds("1") Chr(10) ; 1000
; . "`"30`": " TimestampToMilliseconds("30") Chr(10) ; 30000
; . "`"60`": " TimestampToMilliseconds("60") Chr(10) ; 60000
; . "`"3600`": " TimestampToMilliseconds("3600") Chr(10) ; 3600000
; . "`"7200`": " TimestampToMilliseconds("7200") Chr(10) ; 7200000

; MsgBox "--- 边界值测试 ---" Chr(10)
; . "`"00:00.000`" (最小值): " TimestampToMilliseconds("00:00.000") Chr(10) ; 0
; . "`"59:59.999`" (MM:SS最大值): " TimestampToMilliseconds("59:59.999") Chr(10) ; 3599999
; . "`"23:59:59.999`" (HH:MM:SS最大值): " TimestampToMilliseconds("23:59:59.999") Chr(10) ; 86399999
; . "`"00:01.001`" (最小非零): " TimestampToMilliseconds("00:01.001") Chr(10) ; 1001
; . "`"12:34:56.789`" (常规值): " TimestampToMilliseconds("12:34:56.789") Chr(10) ; 45296789

; MsgBox "--- 错误格式测试 ---" Chr(10)
; . "`"`" (空字符串): " TimestampToMilliseconds("") Chr(10) ; 应该返回 ""
; . "`"abc`": " TimestampToMilliseconds("abc") Chr(10) ; 应该返回 ""
; . "`"12a`": " TimestampToMilliseconds("12a") Chr(10) ; 应该返回 ""
; . "`"-5`": " TimestampToMilliseconds("-5") Chr(10) ; 应该返回 ""
; . "`"1.5`" (小数点但不是时间): " TimestampToMilliseconds("1.5") Chr(10) ; 这现在是合法的SS.mmm格式！
; . "`"01.30`" (秒.毫秒超范围): " TimestampToMilliseconds("01.30") Chr(10) ; 这现在是合法的1秒300毫秒
; . "`"01:30:99`" (秒超范围): " TimestampToMilliseconds("01:30:99") Chr(10) ; 应该返回 ""

; MsgBox "--- 超出范围测试 ---" Chr(10)
; . "`"60:00.000`" (分钟超范围): " TimestampToMilliseconds("60:00.000") Chr(10) ; 应该返回 ""
; . "`"00:60.000`" (秒超范围): " TimestampToMilliseconds("00:60.000") Chr(10) ; 应该返回 ""
; . "`"00:00.1000`" (毫秒超范围): " TimestampToMilliseconds("00:00.1000") Chr(10) ; 应该返回 ""
; . "`"24:00:00.000`" (小时边界): " TimestampToMilliseconds("24:00:00.000") Chr(10) ; 应该返回 ""
; . "`"-01:00.000`" (负分钟): " TimestampToMilliseconds("-01:00.000") Chr(10) ; 应该返回 ""

; MsgBox "--- 格式错误测试 ---" Chr(10)
; . "`"1:1.1`" (格式不正确): " TimestampToMilliseconds("1:1.1") Chr(10) ; 应该返回 ""
; . "`"01:01.01.01`" (多余小数点): " TimestampToMilliseconds("01:01.01.01") Chr(10) ; 应该返回 ""
; . "`"01::01.000`" (双冒号): " TimestampToMilliseconds("01::01.000") Chr(10) ; 应该返回 ""
; . "`"01;01.000`" (错误分隔符): " TimestampToMilliseconds("01;01.000") Chr(10) ; 应该返回 ""
; . "`"01:01,000`" (逗号而非点): " TimestampToMilliseconds("01:01,000") Chr(10) ; 应该返回 ""

; MsgBox "--- 空格和特殊字符测试 ---" Chr(10)
; . "`" 01:01.012 `" (前后空格): " TimestampToMilliseconds(" 01:01.012 ") Chr(10) ; 应该返回 ""
; . "`"01 : 01.012`" (内部空格): " TimestampToMilliseconds("01 : 01.012") Chr(10) ; 应该返回 ""
; . "`"01:01 .012`" (点前空格): " TimestampToMilliseconds("01:01 .012") Chr(10) ; 应该返回 ""
; . "`"01:01. 012`" (点后空格): " TimestampToMilliseconds("01:01. 012") Chr(10) ; 应该返回 ""

; MsgBox "--- 过长输入测试 ---" Chr(10)
; . "`"01:01:01:01.000`" (四段时间): " TimestampToMilliseconds("01:01:01:01.000") Chr(10) ; 应该返回 ""
; . "`"001:001.000`" (前导零过多): " TimestampToMilliseconds("001:001.000") Chr(10) ; 应该返回 ""
; . "`"12345678`" (纯数字过长): " TimestampToMilliseconds("12345678") Chr(10) ; 应该是合法的
; . "`"00:00.0000`" (毫秒位数过多): " TimestampToMilliseconds("00:00.0000") Chr(10) ; 应该返回 ""

; MsgBox "--- 数字类型测试 ---" Chr(10)
; . "数字 123 (非字符串): " TimestampToMilliseconds(123) Chr(10) ; 应该返回 ""
; . "数字 0 (非字符串): " TimestampToMilliseconds(0) Chr(10) ; 应该返回 ""
; . "浮点数 12.5 (非字符串): " TimestampToMilliseconds(12.5) Chr(10) ; 应该返回 ""

; MsgBox "--- 极值测试 ---" Chr(10)
; . "`"99999999`" (超大秒数): " TimestampToMilliseconds("99999999") Chr(10) ; 应该是合法的
; . "`"999:59.999`" (超大分钟): " TimestampToMilliseconds("999:59.999") Chr(10) ; 应该是合法的
; . "`"999:59:59.999`" (超大小时): " TimestampToMilliseconds("999:59:59.999") Chr(10) ; 应该是合法的

; MsgBox "--- 前导零测试 ---" Chr(10)
; . "`"00000`" (多个前导零): " TimestampToMilliseconds("00000") Chr(10) ; 应该是0
; . "`"000123`" (前导零+数字): " TimestampToMilliseconds("000123") Chr(10) ; 应该是123000
; . "`"00:00.000`" (正常前导零): " TimestampToMilliseconds("00:00.000") Chr(10) ; 应该是0

; MsgBox "--- formatDuration (方便操作的函数) ---" Chr(10)
; . "90061012 ms using formatDuration: " FormatDuration(90061012) ; 25:01:01.012

; MsgBox "--- 新支持的灵活格式测试 ---" Chr(10)
; . "`"01:01:01`" (HH:MM:SS无毫秒): " TimestampToMilliseconds("01:01:01") Chr(10) ; 3661000
; . "`"01:01.1`" (MM:SS.1位毫秒): " TimestampToMilliseconds("01:01.1") Chr(10) ; 61100
; . "`"01:01.01`" (MM:SS.2位毫秒): " TimestampToMilliseconds("01:01.01") Chr(10) ; 61010
; . "`"01:01.001`" (MM:SS.3位毫秒): " TimestampToMilliseconds("01:01.001") Chr(10) ; 61001
; . "`"01.1`" (SS.1位毫秒): " TimestampToMilliseconds("01.1") Chr(10) ; 1100
; . "`"01.01`" (SS.2位毫秒): " TimestampToMilliseconds("01.01") Chr(10) ; 1010
; . "`"01.001`" (SS.3位毫秒): " TimestampToMilliseconds("01.001") Chr(10) ; 1001
; . "`"1.001`" (无前导零): " TimestampToMilliseconds("1.001") Chr(10) ; 1001
; . "`"12:34:56`" (HH:MM:SS无毫秒): " TimestampToMilliseconds("12:34:56") Chr(10) ; 45296000
; . "`"59:59`" (MM:SS无毫秒): " TimestampToMilliseconds("59:59") Chr(10) ; 3599000

; MsgBox "--- 边界值测试 ---" Chr(10)
; . "`"00:00.000`" (最小值): " TimestampToMilliseconds("00:00.000") Chr(10) ; 0
; . "`"59:59.999`" (MM:SS最大值): " TimestampToMilliseconds("59:59.999") Chr(10) ; 3599999
; . "`"23:59:59.999`" (HH:MM:SS最大值): " TimestampToMilliseconds("23:59:59.999") Chr(10) ; 86399999
; . "`"00:01.001`" (最小非零): " TimestampToMilliseconds("00:01.001") Chr(10) ; 1001
; . "`"12:34:56.789`" (常规值): " TimestampToMilliseconds("12:34:56.789") Chr(10) ; 45296789

; MsgBox "--- 时间段毫秒移除测试 ---" Chr(10)
; . "Input: `"09:19.237-14:13.934`" -> Output: `"" RemoveMillisecondsFromTimeRange("09:19.237-14:13.934") "`"" Chr(10)
; . "Input: `"19:33.470∞25:10.986`" -> Output: `"" RemoveMillisecondsFromTimeRange("19:33.470∞25:10.986") "`"" Chr(10)
; . "Input: `"01:23:45.678-02:34:56.789`" -> Output: `"" RemoveMillisecondsFromTimeRange("01:23:45.678-02:34:56.789") "`"" Chr(10)
; . "Input: `"12:34.567∞23:45.890`" -> Output: `"" RemoveMillisecondsFromTimeRange("12:34.567∞23:45.890") "`"" Chr(10)
; . "Input: `"05:15-10:30`" (已无毫秒) -> Output: `"" RemoveMillisecondsFromTimeRange("05:15-10:30") "`"" Chr(10)
; . "Input: `"08:20∞12:40`" (已无毫秒) -> Output: `"" RemoveMillisecondsFromTimeRange("08:20∞12:40") "`"" Chr(10)
; . "Input: `"01:23.456`" (单个时间戳) -> Output: `"" RemoveMillisecondsFromTimeRange("01:23.456") "`"" Chr(10)
; . "Input: `"02:34`" (单个时间戳无毫秒) -> Output: `"" RemoveMillisecondsFromTimeRange("02:34") "`"" Chr(10)
; . "Input: `"`" (空字符串) -> Output: `"" RemoveMillisecondsFromTimeRange("") "`"" Chr(10)