#Requires AutoHotkey v2.0
#SingleInstance force
#Include ..\MyTool.ahk
#Include sqlite\SqliteControl.ahk
#Include ..\PotplayerController.ahk
#Include ..\ReduceTime.ahk

; init
potplayer_path := GetKeyName("path")
open_window_parameter := InitOpenWindowParameter(potplayer_path)
potplayer_control := PotplayerController(GetNameForPath(potplayer_path))

InitOpenWindowParameter(potplayer_path){
  if (IsPotplayerRunning(potplayer_path)) {
    return "/current"
  } else {
    return "/new"
  }
}

AppMain()
AppMain(){
  CallbackPotplayer()
}

; 【主逻辑】Potplayer的回调函数（回链）
CallbackPotplayer(){
  url := ReceivParameter()
  if url{
    ParseUrl(url)
  }else{
    MsgBox "至少传递1个参数"
  }
  ExitApp
}

ReceivParameter(){
  ; 获取命令行参数的数量
  paramCount := A_Args.Length

  ; 如果没有参数，显示提示信息
  if (paramCount = 0) {
      return false
  }

  ; 循环遍历参数并显示在控制台
  for n, param in A_Args{
      return param
  }
}

ParseUrl(url){
  ;url := "jv://open?path=https://www.bilibili.com/video/123456/?spm_id_from=..search-card.all.click&time=00:01:53.824"
  ; MsgBox url
  url := UrlDecode(url)
  
  index_of := InStr(url, "?")
  parameters_of_url := SubStr(url, index_of + 1)

  ; 1. 解析键值对
  parameters := StrSplit(parameters_of_url, "&")
  parameters_map := Map()

  ; 1.1 普通解析
  for index, pair in parameters {
    index_of := InStr(pair, "=")
    if (index_of > 0) {
      key := SubStr(pair, 1, index_of - 1)
      value := SubStr(pair, index_of + 1)
      parameters_map[key] := value
    }
  }
  
  ; 1.2 对path参数特殊处理，因为路径中可能是网址
  path := SubStr(parameters_of_url,1, InStr(parameters_of_url, "&time=") -1)
  path := StrReplace(path, "path=", "")
  parameters_map["path"] := path

  ; 2. 跳转Potplayer
  ; D:\PotPlayer64\PotPlayerMini64.exe "D:\123.mp4" /seek=00:01:53.824 /new
  media_path := parameters_map["path"]
  media_time := parameters_map["time"]

  ; 情况1：单个时间戳 00:01:53
  if(IsSingleTimestamp(media_time)){
    JumpToTimestamp(media_path, media_time)
    ExitApp()
  }

  ; 情况2：时间戳片段 00:01:53-00:02:53
  if(IsAbFragment(media_time)){
    JumpToAbFragment(media_path, media_time)
    ExitApp()
  }

  ; 情况3：时间戳循环 00:01:53∞00:02:53
  if(IsAbCirculation(media_time)){
    JumpToAbCirculation(media_path, media_time)
    ExitApp()
  }
}

; 字符串中不包含"-、∞"，则为单个时间戳
IsSingleTimestamp(media_time){
  if(InStr(media_time, "-") > 0 || InStr(media_time, "∞") > 0)
    return false
  else
    return true
}

; 使用时间戳跳转
JumpToTimestamp(media_path, media_time){
  run_command := potplayer_path . " `"" . media_path . "`" /seek=" . media_time . " " . open_window_parameter
  try
    Run run_command
  catch Error as err
    if err.Extra{
      MsgBox "错误：" err.Extra
      MsgBox run_command
    } else {
      throw err
    }
}

IsAbFragment(media_time){
  if(InStr(media_time, "-") > 0)
    return true
  else
    return false
}
JumpToAbFragment(media_path, media_time){
  ; 1. 解析时间戳
  index_of := InStr(media_time, "-")
  start_time := SubStr(media_time, 1, index_of - 1)
  end_time := SubStr(media_time, index_of + 1)

  ; 2. 跳转
  JumpToTimestamp(media_path, start_time)
  
  WaitForPotplayerToFinishLoadingTheVideo()

  flag_ab_fragment := true

  Hotkey "Esc", CancelAbFragment
  CancelAbFragment(*){
    flag_ab_fragment := false
    Hotkey "Esc", "off"
  }

  ; 3. 检查结束时间
  while (flag_ab_fragment) {
    ; 异常情况：用户停止播放视频
    if (potplayer_control.GetPlayStatus() != "Running") {
      break
    }

    ; 正常情况：当前播放时间超过了结束时间、用户手动调整时间，超过了结束时间
    current_time := potplayer_control.GetCurrentSecondsTime()
    if (current_time >= TimeToSeconds(end_time)) {
      potplayer_control.Pause()
      Hotkey "Esc", "off"
      break
    }
    Sleep 1000
  }
}

IsAbCirculation(media_time){
  if(InStr(media_time, "∞") > 0)
    return true
  else
    return false
}
JumpToAbCirculation(media_path, media_time){
  ; 1. 解析时间戳
  index_of := InStr(media_time, "∞")
  start_time := SubStr(media_time, 1, index_of - 1)
  end_time := SubStr(media_time, index_of + 1)

  ; 2. 跳转
  JumpToTimestamp(media_path, start_time)


  WaitForPotplayerToFinishLoadingTheVideo

  ; 3. 设置A-B循环起点
  potplayer_control.SetStartPointOfTheABCycle()

  ; 4. 设置A-B循环终点
  potplayer_control.SetCurrentSecondsTime(TimeToSeconds(end_time))
  potplayer_control.SetEndPointOfTheABCycle()
}

WaitForPotplayerToFinishLoadingTheVideo(){
  ; 如果Potplayer已经打开，则等待Potplayer跳转完成
  if(IsPotplayerRunning(potplayer_path)){
    ; 1 获取Potplayer的窗口句柄
    ids := WinGetList("ahk_exe" GetNameForPath(potplayer_path))
    hwnd := ""
    for id in ids{
        title := WinGetTitle("ahk_id" id)
        if (InStr(title, "PotPlayer")){
            hwnd := id
            break
        }
    }

    ; 2 等待Potplayer加载视频，从上一个视频，跳转到下一个视频，窗口的命名会发生变化 => PotPlayer - 123.mp4 => Potplayer => PotPlayer - 456.mp4
    while (WinGetTitle("ahk_id" hwnd) != "PotPlayer") {
      Sleep 100
    }
  }

  ; 跳转到下一个视频，等待视频加载完成，检查播放器是否已经开始播放
  while (potplayer_control.GetPlayStatus() != "Running") {
    Sleep 1000
  }
}