#Requires AutoHotkey v2.0
#SingleInstance force
#Include lib\Tool.ahk
#Include sqlite\SqliteControl.ahk

potplayer_path := GetKeyName("path")

open_window_parameter := InitOpenWindowParameter(potplayer_path)
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