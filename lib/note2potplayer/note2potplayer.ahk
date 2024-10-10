#Requires AutoHotkey v2.0
#SingleInstance force
#Include ..\MyTool.ahk
#Include sqlite\SqliteControl.ahk
#Include ..\PotplayerControl.ahk
#Include ..\ReduceTime.ahk

; 1. init
ab_fragment_detection_delays := GetKeyName("ab_fragment_detection_delays")
potplayer_path := GetKeyName("path")

potplayer := {}
potplayer.info := EnrichInfo(potplayer_path)
potplayer.control := PotplayerControl(potplayer.info.path)

EnrichInfo(potplayer_path) {
  info := {}

  info.path := potplayer_path

  info.isRunning := IsPotplayerRunning(potplayer_path)

  if (info.isRunning) {
    info.openWindow := "/current"
  } else {
    info.openWindow := "/new"
  }

  return info
}

; 2. 主逻辑
AppMain()
AppMain() {
  CallbackPotplayer()
}

; 【主逻辑】Potplayer的回调函数（回链）
CallbackPotplayer() {
  url := ReceivParameter()
  if url {
    ParseUrl(url)
  } else {
    MsgBox "至少传递1个参数"
  }
  ExitApp
}

ReceivParameter() {
  ; 获取命令行参数的数量
  paramCount := A_Args.Length

  ; 如果没有参数，显示提示信息
  if (paramCount = 0) {
    return false
  }

  params := ""
  ; 循环遍历参数并显示在控制台
  for n, param in A_Args {
    params .= param " "
  }
  return Trim(params)
}

ParseUrl(url) {
  ;url := "jv://open?path=https://www.bilibili.com/video/123456/?spm_id_from=..search-card.all.click&time=00:01:53.824"
  ; MsgBox url
  url := UrlDecode(url)
  index_of := InStr(url, "?")
  parameters_of_url := SubStr(url, index_of + 1)

  ; 1. 解析键值对
  parameters := StrSplit(parameters_of_url, "&")
  parameters_map := Map()

  ; 1.1 常规解析
  for index, pair in parameters {
    index_of := InStr(pair, "=")
    if (index_of > 0) {
      key := SubStr(pair, 1, index_of - 1)
      value := SubStr(pair, index_of + 1)
      parameters_map[key] := value
    }
  }

  ; 1.2 对path参数特殊处理，因为路径中可能是网址
  path := SubStr(parameters_of_url, 1, InStr(parameters_of_url, "&time=") - 1)
  path := StrReplace(path, "path=", "")
  parameters_map["path"] := path

  ; 2. 跳转Potplayer
  ; D:\PotPlayer64\PotPlayerMini64.exe "D:\123.mp4" /seek=00:01:53.824 /new
  potplayer.jump := {}
  potplayer.jump.time := ""
  potplayer.jump.path := parameters_map["path"]
  potplayer.jump.timeSpan := parameters_map["time"]

  ; 情况0：是同一个视频进行跳转，之前可能设置了AB循环，所以此处先取消A-B循环
  if (potplayer.info.isRunning
    && potplayer.control.GetPlayStatus() != "Stopped"
    && IsSameVideo(potplayer.jump.path)) {
    potplayer.control.CancelTheABCycle()
  }

  ; 情况1：单个时间戳 00:01:53
  if (IsSingleTimestamp(potplayer.jump.timeSpan)) {
    JumpToSingleTimestamp(potplayer.jump.path, potplayer.jump.timeSpan)
    ; 情况2：时间戳片段 00:01:53-00:02:53
  } else if (IsAbFragment(potplayer.jump.timeSpan)) {
    if (GetKeyName("loop_ab_fragment")) {
      JumpToAbCirculation(potplayer.jump.path, potplayer.jump.timeSpan)
    } else {
      JumpToAbFragment(potplayer.jump.path, potplayer.jump.timeSpan)
    }
    ; 情况3：时间戳循环 00:01:53∞00:02:53
  } else if (IsAbCirculation(potplayer.jump.timeSpan)) {
    JumpToAbCirculation(potplayer.jump.path, potplayer.jump.timeSpan)
  }
  ExitApp()
}

; 解析时间片段字符串
TimeSpanToTime(media_time) {
  ; 1. 解析时间戳
  time_separator := ["∞", "-"]

  index_of := ""
  Loop time_separator.Length {
    index_of := InStr(media_time, time_separator[A_Index])
    if (index_of > 0) {
      break
    }
  }
  Assert(index_of == "", "时间戳格式错误")

  time := {}
  time.start := SubStr(media_time, 1, index_of - 1)
  time.end := SubStr(media_time, index_of + 1)
  return time
}

; 判断当前播放的视频，是否是跳转的视频
IsSameVideo(jump_path) {
  ; 判断网络视频
  if (InStr(jump_path, "http")) {
    current_path := GetPotplayerpath()
    if (InStr(jump_path, current_path)) {
      return true
    }

    GetPotplayerpath() {
      A_Clipboard := ""
      potplayer.control.GetMediaPathToClipboard()
      ClipWait 1, 0
      return A_Clipboard
    }
  }

  ; 判断本地视频
  potplayer_title := WinGetTitle("ahk_id " potplayer.control.GetOncePotplayerHwnd())
  video_name := GetNameForPath(UrlDecode(jump_path))
  if (InStr(potplayer_title, video_name)) {
    return true
  }
}

; 字符串中不包含"-、∞"，则为单个时间戳
IsSingleTimestamp(media_time) {
  if (InStr(media_time, "-") > 0 || InStr(media_time, "∞") > 0)
    return false
  else
    return true
}

; 使用时间戳跳转
OpenPotplayerAndJumpToTimestamp(media_path, media_time) {
  run_command := potplayer_path . " `"" . media_path . "`" /seek=" . media_time . " " . potplayer.info.openWindow
  try {
    Run run_command
  } catch Error as err
    if err.Extra {
      MsgBox "错误：" err.Extra
      MsgBox run_command
    } else {
      throw err
    }
}

IsAbFragment(media_time) {
  if (InStr(media_time, "-") > 0)
    return true
  else
    return false
}

JumpToSingleTimestamp(path, time) {
  if (potplayer.info.isRunning
    && potplayer.control.GetPlayStatus() != "Stopped"
    && IsSameVideo(potplayer.jump.path)) {
    potplayer.control.SetMediaTimeMilliseconds(TimestampToMilliSecond(time))
    potplayer.control.Play()
  } else {
    OpenPotplayerAndJumpToTimestamp(path, time)
  }
}

JumpToAbFragment(media_path, media_time_span) {
  ; 1. 解析时间戳
  potplayer.jump.time := TimeSpanToTime(media_time_span)

  ; 2. 跳转
  CallPotplayer()
  Sleep 500

  flag_ab_fragment := true

  Hotkey "Esc", CancelAbFragment
  CancelAbFragment(*) {
    flag_ab_fragment := false
    Hotkey "Esc", "off"
  }

  duration := TimestampToMilliSecond(potplayer.jump.time.end) - TimestampToMilliSecond(potplayer.jump.time.start)
  past := 0
  ; 3. 检查结束时间
  while (flag_ab_fragment) {
    ; 异常情况：用户关闭Potplayer
    if (!IsPotplayerRunning(potplayer_path)) {
      break
      ; 异常情况：用户停止播放视频
    } else if (potplayer.control.GetPlayStatus() != "Running") {
      break
    }
    ; todo: 异常情况：不是同一个视频
    ; - 在播放B站视频时，可以加载视频列表，这样用户就会切换视频，此时就要结束循环 else if (!IsSameVideo(media_path)) {break}
    ; - 另一种思路：当前循环的时间超过了时间期间，就结束循环； +5是为了防止误差
    ; else if (past >= duration + 5000) {
    ;   break
    ; }

    ; 正常情况：当前播放时间超过了结束时间、用户手动调整时间，超过了结束时间
    current_time := potplayer.control.GetMediaTimeMilliseconds()
    if (current_time >= TimestampToMilliSecond(potplayer.jump.time.end)) {
      potplayer.control.PlayPause()
      Hotkey "Esc", "off"
      break
    }
    Sleep ab_fragment_detection_delays
    past += ab_fragment_detection_delays
  }
}

IsAbCirculation(time_span) {
  if (InStr(time_span, "∞") > 0)
    return true
  else
    return false
}
JumpToAbCirculation(media_path, media_time_span) {
  call_data := {}
  call_data.media_path := media_path
  potplayer.jump.time := time := TimeSpanToTime(media_time_span)

  ; 2. 跳转
  CallPotplayer()

  ; 3. 设置A-B循环起点
  potplayer.control.SetStartPointOfTheABCycle()

  ; 4. 设置A-B循环终点
  potplayer.control.SetMediaTimeMilliseconds(TimestampToMilliSecond(time.end))
  potplayer.control.SetEndPointOfTheABCycle()
}

CallPotplayer() {
  if (potplayer.info.isRunning
    && potplayer.control.GetPlayStatus() != "Stopped"
    && IsSameVideo(potplayer.jump.path)) {
    potplayer.control.SetMediaTimeMilliseconds(TimestampToMilliSecond(potplayer.jump.time.start))
    potplayer.control.Play()
  } else {
    ; 播放指定视频
    PlayVideo(potplayer.jump.path, potplayer.jump.time.start)
  }
}
PlayVideo(media_path, time_start) {
  if (potplayer.info.isRunning && potplayer.control.GetPlayStatus() != "Stopped") {
    potplayer.control.Stop()
  }
  OpenPotplayerAndJumpToTimestamp(media_path, time_start)
  WaitForPotplayerToFinishLoadingTheVideo(GetNameForPath(media_path))
  potplayer.control.Play()
}
; 已开Potplayer跳转到下一个视频，判断当前potplayer播放器的状态
WaitForPotplayerToFinishLoadingTheVideo(video_name) {
  WinWaitActive("ahk_exe " GetNameForPath(potplayer_path))

  while (true) {
    if (WinGetTitle("ahk_id " potplayer.control.GetOncePotplayerHwnd()) != "PotPlayer"
    && potplayer.control.GetPlayStatus() == "Running") {
      break
    }
    Sleep 1000
  }
}