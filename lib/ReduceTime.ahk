#Requires AutoHotkey v2.0

; 修改秒数并返回新的时间格式
ReduceTime(originalTime, secondsToModify) {
  seconds := TimeToSeconds(originalTime)

  newSeconds := seconds - secondsToModify

  if (newSeconds < 0){
    newSeconds := 0
  }

  result := SecondsToTimeFormat(newSeconds)
  return result
}

; 将时间字符串转换为秒
TimeToSeconds(timeStr) {
  RegExMatch(timeStr, "^((?<hours>\d+):)?((?<minutes>[0-5][0-9]):)?(?<seconds>[0-5][0-9])(\.(?<ms>\d+))?$", &matches)
  h := matches.hours ? matches.hours : 0
  m := matches.minutes ? matches.minutes : 0
  s := matches.seconds ? matches.seconds : 0
  ms := matches.seconds

  ; 修正正则表达式的bug：当传入的数据是"16:34"，会出现h=16，m=0，s=34的情况
  if (CountCharOccurrences(timeStr, ":") > 1) {
    if (h > 0 && m = 0 && s >= 0) {
      m := h
      h := 0
    }
  }
  
  result := (h * 3600) + (m * 60) + s
  return result
}

; 查找字符串中`char`字符的总个数
CountCharOccurrences(string, char) {
  parts := StrSplit(string, char)
  if parts.Length > 1 {
    return parts.Length - 1
  }
  return parts.Length
}

; 将秒转换回原始格式
SecondsToTimeFormat(duration) {
  if (duration < 60){
    if (duration < 10){
      duration := "0" duration
    }
    return duration
  }

  seconds := Mod(duration , 60)
  minutes := Mod(duration // 60,60)
  hours := duration // 3600

  ModifyTimeFormat(&hours, &minutes, &seconds)

  if (hours > 0){
    return hours ":" minutes ":" seconds
  }
  else{
    return minutes ":" seconds
  }
}

; 修正秒数和分钟数的显示格式
ModifyTimeFormat(&hours, &minutes, &seconds) {
  if (hours < 10){
    hours := "0" hours
  }
  if (minutes < 10){
    minutes := "0" minutes
  }
  if (seconds < 10){
    seconds := "0" seconds
  }
}

; 示例
; originalTime1 := "60"
; MsgBox TimeToSeconds(originalTime1)
; originalTime2 := "16:34"
; MsgBox TimeToSeconds(originalTime2)
; originalTime3 := "01:40:26"
; MsgBox TimeToSeconds(originalTime3)

; ; ; 假设我们要给每个时间增加 30 秒
; newTime1 := ModifySeconds(originalTime1, 3)
; newTime2 := ModifySeconds(originalTime2, 3)
; newTime3 := ModifySeconds(originalTime3, 3)

; MsgBox newTime1 ; 显示新的时间
; MsgBox newTime2
; MsgBox newTime3
