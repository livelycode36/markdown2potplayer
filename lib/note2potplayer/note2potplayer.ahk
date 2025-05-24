#Requires AutoHotkey v2.0
#SingleInstance force
#Include ..\MyTool.ahk
#Include sqlite\SqliteControl.ahk
#Include ..\PotplayerControl.ahk
#Include ..\TimeTool.ahk
#Include ..\PotplayerFragment.ahk

; 1. init
potplayer_path := GetKeyName("path")

potplayer := {
  info: EnrichInfo(potplayer_path),
  control: PotplayerControl(potplayer_path)
}

EnrichInfo(potplayer_path) {
  info := {
    path: potplayer_path,
    isRunning: IsPotplayerRunning(potplayer_path),
    openWindow: IsPotplayerRunning(potplayer_path) ? "/current" : "/new"
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
  potplayer.jump := {
    time: "",
    path: parameters_map["path"],
    timeSpan: parameters_map["time"]
  }

  ; 情况0：是同一个视频进行跳转，之前可能设置了AB循环，所以此处先取消A-B循环
  CancelABCycleIfNeeded(potplayer.control, potplayer.info.path, potplayer.jump.path)
  ; 情况1：单个时间戳 00:01:53
  if (IsSingleTimestamp(potplayer.jump.timeSpan)) {
    JumpToSingleTimestamp(potplayer.jump.path, potplayer.jump.timeSpan)
  } else {
    ; 情况2：时间戳片段
    time := TimeSpanToTime(potplayer.jump.timeSpan)
    time_start := time.start
    time_end := time.end
    if (IsAbFragment(potplayer.jump.timeSpan)) {
      if (GetKeyName("loop_ab_fragment")) {
        JumpToAbCirculation(potplayer.control, potplayer_path, potplayer.jump.path, time_start, time_end)
      } else {
        JumpToAbFragment(potplayer.control, potplayer_path, potplayer.jump.path, time_start, time_end, GetKeyName("ab_fragment_detection_delays"))
      }
    } else if (IsAbCirculation(potplayer.jump.timeSpan)) {
      ; 情况3：时间戳循环
      JumpToAbCirculation(potplayer.control, potplayer_path, potplayer.jump.path, time_start, time_end)
    }
  }
  ExitApp()
}

; 解析时间片段字符串
TimeSpanToTime(media_time) {
  ; 1. 解析时间戳
  time_separator := ["∞", "-"]

  index_of := ""
  for index, separator in time_separator {
    index_of := InStr(media_time, separator)
    if (index_of > 0) {
      break
    }
  }
  Assert(index_of == "", "时间戳格式错误")

  time := {
    start: SubStr(media_time, 1, index_of - 1),
    end: SubStr(media_time, index_of + 1)
  }
  return time
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
    && IsSameVideo(potplayer.control, potplayer.jump.path)) {
    potplayer.control.SetMediaTimeMilliseconds(TimestampToMilliseconds(time))
    potplayer.control.Play()
  } else {
    OpenPotplayerAndJumpToTimestamp(path, time)
  }
}

IsAbCirculation(time_span) {
  if (InStr(time_span, "∞") > 0)
    return true
  else
    return false
}

CallPotplayer() {
  if (potplayer.info.isRunning
    && potplayer.control.GetPlayStatus() != "Stopped"
    && IsSameVideo(potplayer.control, potplayer.jump.path)) {
    potplayer.control.SetMediaTimeMilliseconds(TimestampToMilliseconds(potplayer.jump.time.start))
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
    if (WinGetTitle("ahk_id " potplayer.control.getHwnd()) != "PotPlayer"
    && potplayer.control.GetPlayStatus() == "Running") {
      break
    }
    Sleep 1000
  }
}