#Requires AutoHotkey v2.0
#SingleInstance force

; SetWorkingDir对#Include无效，只能这样引用lib库
#Include "%A_ScriptDir%\..\MyTool.ahk"

; -1去掉自身"lib"，-2去掉自身"lib"和路径的"/"
root_dir := SubStr(A_WorkingDir, 1, InStr(A_ScriptDir,"lib")-2)
SetWorkingDir(root_dir)
; SetWorkingDir让IniRead读取根目录的配置文件
potplayer_path := IniRead("config.ini", "PotPlayer", "path" , )

open_window_parameter := InitOpenWindowParameter(potplayer_path)

main()

main(){
  CallbackPotplayer()
}

; 【主逻辑】Potplayer的回调函数（回链）
CallbackPotplayer(){
  url := ReceivParameter()
  ParseUrl(url)
}

ReceivParameter(){
  ; 获取命令行参数的数量
  paramCount := A_Args.Length

  ; 如果没有参数，显示提示信息
  if (paramCount = 0) {
    MsgBox "请提供至少一个参数。"
    ExitApp
  }

  ; 循环遍历参数并显示在控制台
  for n, param in A_Args{
    return param
  }
}

InitOpenWindowParameter(potplayer_path){
  if (IsPotplayerRunning(potplayer_path)) {
    return "/current"
  } else {
    return "/new"
  }
}

ParseUrl(url){
  ;url := "mk-potplayer://open?type=1&aaa=123&bbb=456"
  ; MsgBox url
  
  index_of := InStr(url, "?")
  parameters_of_url := SubStr(url, index_of + 1)

  ; 1. 解析键值对
  parameters := StrSplit(parameters_of_url, "&")
  parameters_map := Map()

  ; 1.1 遍历键值对，存储到字典中
  for index, pair in parameters {
    index_of := InStr(pair, "=")
    key := SubStr(pair, 1, index_of - 1)
    value := SubStr(pair, index_of + 1)
    parameters_map[key] := value
  }
  
  ; 2. 跳转Potplayer
  ; D:\PotPlayer64\PotPlayerMini64.exe "D:\123.mp4" /seek=00:01:53.824 /new
  media_path := parameters_map["path"]
  media_time := parameters_map["time"]

  ; 2.1 如果是B站视频，无需处理
  if (InStr(media_path,"https://www.bilibili.com/video/")){

    ; 3. 本地路径的视频，判断路径是否经过URL编码
    ; 被URL编码后的路径，没有路径分隔符
  } else if !(InStr(media_path,"/") || InStr(media_path,"\")) {
    media_path := UrlDecode(media_path)
  }

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
  ExitApp
}