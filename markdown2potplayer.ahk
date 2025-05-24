#Requires AutoHotkey v2.0
#SingleInstance force
#Include "lib\note2potplayer\RegisterUrlProtocol.ahk"
#Include "lib\MyTool.ahk"
#Include "lib\TimeTool.ahk"
#Include "lib\TemplateParser.ahk"
#Include "lib\sqlite\SqliteControl.ahk"
#Include lib\srt.ahk
#Include lib\Render.ahk
#Include lib\socket\SocketService.ahk
#Include lib\entity\Config.ahk
#Include lib\entity\MediaData.ahk
#Include lib\PotplayerControl.ahk
#Include lib\gui\GuiControl.ahk
#Include lib\gui\i18n\I18n.ahk
#Include lib/PotplayerFragment.ahk

main()

main() {
    global
    TraySetIcon("lib/icon.png", 1, false)

    InitSqlite()
    app_config := Config()
    potplayer_control := PotplayerControl(app_config.PotplayerProcessName)

    InitGui(app_config, potplayer_control)

    InitServer()

    RegisterUrlProtocol(app_config.UrlProtocol)

    RegisterHotKey()
    RegisterSubtitleFragmentHotkeys()
}

RegisterHotKey() {
  HotIf CheckCurrentProgram
  if(app_config.HotkeySubtitle!= ""){
    Hotkey(app_config.HotkeySubtitle " Up", Potplayer2Obsidian)
  }
  if (app_config.HotkeyUserNote != "") {
    Hotkey(app_config.HotkeyUserNote " Up", Potplayer2Obsidian)
  }
  if (app_config.HotkeyBacklink!= ""){
    Hotkey(app_config.HotkeyBacklink " Up", Potplayer2Obsidian)
  }
  if (app_config.HotkeyIamgeBacklink!= ""){
    Hotkey(app_config.HotkeyIamgeBacklink " Up", Potplayer2ObsidianImage)
  }
  if (app_config.HotkeyImageEdit != "") {
    Hotkey(app_config.HotkeyImageEdit " Up", Potplayer2ObsidianImage)
  }
  if (app_config.HotkeyAbFragment!= ""){
    Hotkey(app_config.HotkeyAbFragment " Up", Potplayer2ObsidianFragment)
  }
  if (app_config.HotkeyAbCirculation!= ""){
    Hotkey(app_config.HotkeyAbCirculation " Up", Potplayer2ObsidianFragment)
  }
}

RefreshHotkey(old_hotkey, new_hotkey, callback) {
    try {
        ; 情况1：用户删除热键
        if new_hotkey == "" {
            if (old_hotkey != "") {
                Hotkey old_hotkey " Up", "off"
            }
        } else {
            ; 情况2：用户重设热键
            if (old_hotkey != "") {
                Hotkey old_hotkey " Up", "off"
            }
            HotIf CheckCurrentProgram
            Hotkey new_hotkey " Up", callback
        }
    }
    catch Error as err {
        ; 热键设置无效
        ; 防止无效的快捷键产生报错，中断程序
        Exit
    }
}

CheckCurrentProgram(*) {
    programs := app_config.PotplayerProcessName "`n" app_config.NoteAppName
    Loop Parse programs, "`n" {
        program := A_LoopField
        if program {
            if WinActive("ahk_exe " program) {
                return true
            }
        }
    }
    return false
}

lastMediaPath := ""
; 【主逻辑】将Potplayer的播放链接粘贴到Obsidian中
Potplayer2Obsidian(hotkey) {
    global lastMediaPath
    ; 取消可能正在进行的截图等待
    CancelScreenshotWaiting()
    
    ReleaseCommonUseKeyboard()

    if (lastMediaPath == "") {
        lastMediaPath := UrlDecode(GetMediaPath())
    }

    nameInPath := UrlDecode(GetNameForPath(lastMediaPath))
    nameInPotplayer := StrReplace(GetPotplayerTitle(app_config.PotplayerProcessName), " - PotPlayer", "")

    if (nameInPath == nameInPotplayer) {
        media_path := lastMediaPath
    } else {
        lastMediaPath := UrlDecode(GetMediaPath())
        media_path := lastMediaPath
    }

    media_data := MediaData(media_path, GetMediaTime(), "")

    if (hotkey == (app_config.HotkeySubtitle " Up")) {
        backlink_template := app_config.SubtitleTemplate

        rendered_template := RenderTemplate(app_config.SubtitleTemplate, media_data, hotkey)
    } else {
        rendered_template := RenderTemplate(app_config.MarkdownTemplate, media_data, hotkey)
    }

    PauseMedia()

    if (IsWordProgram()) {
        SendText2wordApp(rendered_template)
    } else {
        SendText2NoteApp(rendered_template)
    }
}

; 【主逻辑】粘贴图像
Potplayer2ObsidianImage(hotkey) {
  ReleaseCommonUseKeyboard()
  
  ; 取消可能正在进行的截图等待
  CancelScreenshotWaiting()

  iamgeData := SaveImage(hotkey)
  
  ; 对于 HotkeyIamgeBacklink，仍然是同步的
  if (hotkey == (app_config.HotkeyIamgeBacklink " Up")) {
    if (iamgeData == "edit image timeout") {
      return
    }
    
    media_data := MediaData(GetMediaPath(), GetMediaTime(), "")
    PauseMedia()
    RenderImage(app_config.MarkdownImageTemplate, media_data, iamgeData)
  }
  
  ; 对于 HotkeyImageEdit，现在是异步的，SaveImage 已经启动了异步流程
  ; ProcessScreenshotResult 会在检测到图片时自动调用
}

GetMediaPath() {
    return PressDownHotkey(potplayer_control.GetMediaPathToClipboard)
}
GetMediaTime() {
    milliseconds := potplayer_control.GetMediaTimeMilliseconds()

    if (app_config.ReduceTime != "0") {
        milliseconds := (milliseconds - (app_config.ReduceTime * 1000))
    }

    if (milliseconds < 0) {
        milliseconds := 0
    }

    timestamp := MillisecondsToTimestamp(milliseconds)

    return timestamp
}

GetMediaTimeMilliseconds() {
    return potplayer_control.GetMediaTimeMilliseconds()
}
GetMediaSubtitle() {
    subtitle_from_potplayer := ""
    subtitle_from_potplayer := PressDownHotkey(potplayer_control.GetSubtitleToClipboard)
    return subtitle_from_potplayer
}
PressDownHotkey(operate_potplayer) {
    ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := ""
    ; 调用函数会丢失this，将对象传入，以便不会丢失this => https://wyagd001.github.io/v2/docs/Objects.htm#Custom_Classes_method
    operate_potplayer(potplayer_control)
    result := ""
    if(!ClipWait(1, 0)){
      return result
    }
    result := A_Clipboard
    ; MyLog "剪切板的值是：" . result

    ; 解决：一旦potplayer左上角出现提示，快捷键不生效的问题
    ; if (result == "") {
    ;     SafeRecursion()
    ;     ; 无限重试！
    ;     result := PressDownHotkey(operate_potplayer)
    ; }
    ; running_count := 0
    return result
}

PauseMedia() {
    if (app_config.IsStop != "0") {
        potplayer_control.PlayPause()
    }
}

IsWordProgram() {
    target_program := SelectedNoteProgram(app_config.NoteAppName)
    return target_program == "wps.exe" || target_program == "winword.exe"
}
IsNotionProgram() {
    target_program := StrLower(SelectedNoteProgram(app_config.NoteAppName))
    return target_program == "msedge.exe"
        || target_program == "chrome.exe"
        || target_program == "360chrome.exe"
        || target_program == "firefox.exe"
}

GetFileNameInPath(path) {
    name := GetNameForPath(path)
    if (app_config.MarkdownRemoveSuffixOfVideoFile != "0") {
        name := RemoveSuffix(name)
    }
    return name
}

RemoveSuffix(name) {
    index_of := InStr(name, ".", , -1)
    if (index_of = 0) {
        return name
    }
    result := SubStr(name, 1, index_of - 1)
    return result
}

; 路径地址处理
ProcessUrl(media_path) {
    ; 进行Url编码
    if (app_config.MarkdownPathIsEncode != "0" ||
        ; 全系urlencode的bug：如果路径中存在"\["会让，在【ob的预览模式】下(回链会被ob自动urlencode)，"\"离奇消失变为,"["；例如：G:\BaiduSyncdisk\123\[456] 在bug下变为：G:\BaiduSyncdisk\123[456] <= 丢失了"\"
        ; 所以先将"\["替换为"%5C["（\的urlencode编码%5C）。变为：G:\BaiduSyncdisk\123%5C[456]
        ; Typora能打开
        InStr(media_path, "\[") != 0 ||
        InStr(media_path, "\!") != 0) {
        media_path := UrlEncode(media_path)
    } else {
        ; ob 能打开，Typora打不开
        ; media_path := StrReplace(media_path, "\[", "%5C[")
        ; media_path := StrReplace(media_path, "\!", "%5C!")

        ; 但是 obidian中的potplayer回链路径有空格，在obsidian的预览模式【无法渲染】，所以将空格进行Url编码
        media_path := StrReplace(media_path, " ", "%20")
    }

    return media_path
}

SendText2NoteApp(text) {
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)

    A_Clipboard := ""
    A_Clipboard := text
    ; 超时
    if(!ClipWait(2, 0)){
     return 
    }
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 粘贴文字需要等待一下obsidian有延迟，不然会出现粘贴的文字【消失】
    Sleep 300
}
SendText2wordApp(text) {
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)
    Run(A_ScriptDir "\lib\word\word.exe " text, , "Hide", ,)
}

; 添加截图等待状态跟踪变量
IsWaitingForScreenshot := false
ScreenshotContext := {hotkey: "", media_data: ""}
SaveImage(hotkey) {
  global IsWaitingForScreenshot
  
  ; 如果已经在等待截图，先取消之前的等待
  if (IsWaitingForScreenshot) {
      SetTimer(ScreenshotTimeout, 0)
      IsWaitingForScreenshot := false
  }
  
  Assert(potplayer_control.GetPlayStatus() == "Stopped", "Please start video playback to take screenshots.")

  if (hotkey == (app_config.HotkeyIamgeBacklink " Up")) {
    A_Clipboard := ""
    potplayer_control.SaveImageToClipboard()
    if !ClipWait(2, 1) {
      SafeRecursion()
    }
    running_count := 0
    return ClipboardAll()
  }

  if (hotkey == (app_config.HotkeyImageEdit " Up")) {
    ActivateProgram(app_config.PotplayerProcessName)
    Send app_config.HotkeyScreenshotToolHotkeys
    A_Clipboard := ""
    
    ; 设置等待状态和上下文
    IsWaitingForScreenshot := true
    ScreenshotContext.hotkey := hotkey
    
    ; 启动异步检查定时器 - 每250ms检查一次剪切板
    SetTimer(CheckClipboardForImage, 250)
    
    ; 设置超时定时器
    SetTimer(ScreenshotTimeout, app_config.ImageEditDetectionTime * 1000)
    
    ; 立即返回，不阻塞快捷键
    return "async_started"
  }
}

; 截图超时处理函数
ScreenshotTimeout() {
    global IsWaitingForScreenshot
    if (IsWaitingForScreenshot) {
        IsWaitingForScreenshot := false
        ; 停止剪切板检查定时器
        SetTimer(CheckClipboardForImage, 0)
        ; 这里可以添加超时提示，比如：
        ; ToolTip("截图已超时或被取消")
        ; SetTimer(() => ToolTip(), -2000)
    }
}

; 异步检查剪切板是否有图片
CheckClipboardForImage() {
    global IsWaitingForScreenshot, ScreenshotContext
    
    if (!IsWaitingForScreenshot) {
        ; 停止检查
        SetTimer(CheckClipboardForImage, 0)
        return
    }
    
    ; 检查剪切板是否有图片
    if ClipWait(0, 1) {
        try {
            clipboard_data := ClipboardAll()
            ; 停止所有定时器并重置状态
            SetTimer(CheckClipboardForImage, 0)
            SetTimer(ScreenshotTimeout, 0)
            IsWaitingForScreenshot := false
            
            ; 继续处理截图 - 直接调用后续流程
            ProcessScreenshotResult(clipboard_data, ScreenshotContext.hotkey)
            
        } catch {
            ; 获取剪切板数据失败，继续等待
        }
    }
}

; 处理截图结果
ProcessScreenshotResult(image_data, hotkey) {
    ; 获取媒体数据
    media_data := MediaData(GetMediaPath(), GetMediaTime(), "")
    
    ; 暂停媒体
    PauseMedia()
    
    ; 渲染图片
    RenderImage(app_config.MarkdownImageTemplate, media_data, image_data)
}

; 取消截图等待（用于防止其他操作与截图冲突）
CancelScreenshotWaiting() {
    global IsWaitingForScreenshot
    if (IsWaitingForScreenshot) {
        SetTimer(CheckClipboardForImage, 0)
        SetTimer(ScreenshotTimeout, 0)
        IsWaitingForScreenshot := false
    }
}

SendImage2NoteApp(image) {
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)
    A_Clipboard := ""
    A_Clipboard := ClipboardAll(image)
    if(!ClipWait(2, 1)){
      return
    }
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 给Obsidian图片插件处理图片的时间
    Sleep app_config.SendImageDelays
}

; 【A-B片段、循环】
PressHotkeyCount := 0
Potplayer2ObsidianFragment(HotkeyName) {
  global

  ; 取消可能正在进行的截图等待
  CancelScreenshotWaiting()
  
  ReleaseCommonUseKeyboard()

  i18n_strings := I18n(A_WorkingDir "\lib\gui\i18n")

  PressHotkeyCount += 1

  if (PressHotkeyCount == 1) {
      ; 第一次按下快捷键，记录时间
      fragment_time_start := GetMediaTime()
      ; 通知用户
      ToolTip(i18n_strings.tips_ab_start)
      SetTimer () => ToolTip(), -2000

      HotIf CheckCurrentProgram
      Hotkey("Escape Up", cancel, "On")
      cancel(*) {
          ; 重置计数器
          PressHotkeyCount := 0
          Hotkey("Escape Up", "off")
      }
  } else if (PressHotkeyCount == 2) {
      Assert(fragment_time_start == "", i18n_strings.tips_ab_failed)
      ; 重置计数器
      PressHotkeyCount := 0
      Hotkey("Escape Up", "off")

      ; 第二次按下快捷键，记录时间
      fragment_time_end := GetMediaTime()

      ; 如果终点时间小于起点时间，就交换两个时间
      if (TimestampToMilliseconds(fragment_time_end) < TimestampToMilliseconds(fragment_time_start)) {
          temp := fragment_time_start
          fragment_time_start := fragment_time_end
          fragment_time_end := temp
          ; 释放内存
          temp := ""
      }

      media_path := GetMediaPath()
      if fragment_time_start == fragment_time_end {
          fragment_time := fragment_time_start
      } else if HotkeyName == app_config.HotkeyAbFragment " Up" {
          fragment_time := fragment_time_start "-" fragment_time_end
      } else if HotkeyName == app_config.HotkeyAbCirculation " Up" {
          fragment_time := fragment_time_start "∞" fragment_time_end
      }

      ; 生成片段链接
      markdown_link := RenderTemplate(app_config.MarkdownTemplate, MediaData(media_path, fragment_time, ""))
      PauseMedia()

      ; 发送到笔记软件
      if (IsWordProgram()) {
          SendText2wordApp(markdown_link)
      } else {
          SendText2NoteApp(markdown_link)
      }
  }
}

RegisterSubtitleFragmentHotkeys() {
    Hotkey("^j", (*) => SubtitleFragmentPlay("prev", "single"))
    Hotkey("^k", (*) => SubtitleFragmentPlay("current", "single"))
    Hotkey("^l", (*) => SubtitleFragmentPlay("next", "single"))
    Hotkey("^!j", (*) => SubtitleFragmentPlay("prev", "loop"))
    Hotkey("^!k", (*) => SubtitleFragmentPlay("current", "loop"))
    Hotkey("^!l", (*) => SubtitleFragmentPlay("next", "loop"))
}

SubtitleFragmentPlay(mode, playtype) {
    global app_config, potplayer_control
    media_path := GetMediaPath()
    if (media_path == "") {
        MsgBox "未获取到视频路径"
        return
    }
    srt_path := GetNameForPathWithoutExt(media_path) ".srt"
    if !FileExist(srt_path) {
        MsgBox "未找到对应的SRT字幕文件: " srt_path
        return
    }
    subtitles_data := SubtitlesDataFromSrt(srt_path)
    milliseconds := potplayer_control.GetMediaTimeMilliseconds()
    frag := GetSubtitleSegmentByTimestamp(subtitles_data, milliseconds, mode)
    if !frag {
        MsgBox "未找到对应字幕片段"
        return
    }
    time_start := MsToSrtTime(frag.timeStart)
    time_end := MsToSrtTime(frag.timeEnd)
    ; 转为00:00:00.000格式
    time_start := StrReplace(time_start, ",", ".")
    time_end := StrReplace(time_end, ",", ".")
    MsgBox("time_start: " time_start "`n" "time_end: " time_end)
    ; 取消AB循环
    CancelABCycleIfNeeded(potplayer_control, app_config.PotplayerProcessName, media_path)
    if (playtype = "single") {
        ; JumpToAbFragment(potplayer_control, app_config.PotplayerProcessName, media_path, time_start, time_end, app_config.AbFragmentDetectionDelays)
        text := app_config.UrlProtocol "?path=" ProcessUrl(media_path) "&time=" time_start "-" time_end
        Run A_ScriptDir "\lib\note2potplayer\note2potplayer.exe " text
    } else {
        JumpToAbCirculation(potplayer_control, app_config.PotplayerProcessName, media_path, time_start, time_end)
    }
}