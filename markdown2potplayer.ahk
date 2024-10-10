#Requires AutoHotkey v2.0
#SingleInstance force
#Include "lib\note2potplayer\RegisterUrlProtocol.ahk"
#Include "lib\MyTool.ahk"
#Include "lib\ReduceTime.ahk"
#Include "lib\TemplateParser.ahk"
#Include "lib\sqlite\SqliteControl.ahk"
#Include lib\srt.ahk
#Include lib\Redner.ahk
#Include lib\socket\SocketService.ahk
#Include lib\entity\Config.ahk
#Include lib\entity\MediaData.ahk
#Include lib\PotplayerControl.ahk
#Include lib\gui\GuiControl.ahk

main()

main() {
    global
    TraySetIcon("lib/icon.png", 1, false)

    InitConfigSqlite()
    app_config := Config()
    potplayer_control := PotplayerControl(app_config.PotplayerProcessName)

    InitGui(app_config, potplayer_control)

    InitServer()

    RegisterUrlProtocol(app_config.UrlProtocol)

    RegisterHotKey()
}

RegisterHotKey() {
    HotIf CheckCurrentProgram
    Hotkey(app_config.HotkeySubtitle " Up", Potplayer2Obsidian)
    Hotkey(app_config.HotkeyBacklink " Up", Potplayer2Obsidian)
    Hotkey(app_config.HotkeyIamgeBacklink " Up", Potplayer2ObsidianImage)
    Hotkey(app_config.HotkeyAbFragment " Up", Potplayer2ObsidianFragment)
    Hotkey(app_config.HotkeyAbCirculation " Up", Potplayer2ObsidianFragment)
    if (app_config.HotkeyPreviousFrame != "")
        Hotkey(app_config.HotkeyPreviousFrame " Up", potplayer_control.PreviousFrame)
    if (app_config.HotkeyNextFrame != "")
        Hotkey(app_config.HotkeyNextFrame " Up", potplayer_control.NextFrame)
    if (app_config.HotkeyForward != "")
        Hotkey(app_config.HotkeyForward " Up", () => potplayer_control.ForwardBySeconds(app_config.ForwardSeconds))
    if (app_config.HotkeyBackward != "")
        Hotkey(app_config.HotkeyBackward " Up", () => potplayer_control.BackwardBySeconds(app_config.BackwardSeconds))
    if (app_config.HotkeyPlayOrPause != "")
        Hotkey(app_config.HotkeyPlayOrPause " Up", potplayer_control.PlayOrPause)
    if (app_config.HotkeyStop != "")
        Hotkey(app_config.HotkeyStop " Up", potplayer_control.Stop)
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

; 【主逻辑】将Potplayer的播放链接粘贴到Obsidian中
Potplayer2Obsidian(hotkey) {
    ReleaseCommonUseKeyboard()

    media_data := MediaData(GetMediaPath(), GetMediaTime(), "")

    if (hotkey == (app_config.HotkeySubtitle " Up")) {
        backlink_template := app_config.SubtitleTemplate

        rendered_template := RenderTemplate(app_config.SubtitleTemplate, media_data)
    } else {
        rendered_template := RenderTemplate(app_config.MarkdownTemplate, media_data)
    }

    PauseMedia()

    if (IsWordProgram()) {
        SendText2wordApp(rendered_template)
    } else {
        SendText2NoteApp(rendered_template)
    }
}

; 【主逻辑】粘贴图像
Potplayer2ObsidianImage(*) {
    ReleaseCommonUseKeyboard()

    media_data := MediaData(GetMediaPath(), GetMediaTime(), "")
    image := SaveImage()

    PauseMedia()

    RenderImage(app_config.MarkdownImageTemplate, media_data, image)
}

GetMediaPath() {
    return PressDownHotkey(potplayer_control.GetMediaPathToClipboard)
}
GetMediaTime() {
    time := PressDownHotkey(potplayer_control.GetMediaTimestampToClipboard)

    if (app_config.ReduceTime != "0") {
        time := ReduceTime(time, app_config.ReduceTime)
    }
    return time
}

GetMediaTimeMilliseconds() {
    return potplayer_control.GetMediaTimeMilliseconds()
}
GetMediaSubtitle() {
    subtitle_from_otplayer := ""
    subtitle_from_otplayer := PressDownHotkey(potplayer_control.GetSubtitleToClipboard)
    return subtitle_from_otplayer
}
PressDownHotkey(operate_potplayer) {
    ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := ""
    ; 调用函数会丢失this，将对象传入，以便不会丢失this => https://wyagd001.github.io/v2/docs/Objects.htm#Custom_Classes_method
    operate_potplayer(potplayer_control)
    ClipWait 1, 0
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
    ClipWait 2, 0
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

SaveImage() {
    Assert(potplayer_control.GetPlayStatus() == "Stopped", "视频尚未播放，无法截图！")

    A_Clipboard := ""
    potplayer_control.SaveImageToClipboard()
    if !ClipWait(2, 1) {
        SafeRecursion()
    }
    running_count := 0
    return ClipboardAll()
}
SendImage2NoteApp(image) {
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)
    A_Clipboard := ""
    A_Clipboard := ClipboardAll(image)
    ClipWait 2, 1
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
    ReleaseCommonUseKeyboard()

    PressHotkeyCount += 1

    if (PressHotkeyCount == 1) {
        ; 第一次按下快捷键，记录时间
        fragment_time_start := GetMediaTime()
        ; 通知用户
        ToolTip("已经记录起点的时间！请再次按下快捷键，记录终点的时间。按Esc取消")
        SetTimer () => ToolTip(), -2000

        HotIf CheckCurrentProgram
        Hotkey("Escape Up", cancel, "On")
        cancel(*) {
            ; 重置计数器
            PressHotkeyCount := 0
            Hotkey("Escape Up", "off")
        }
    } else if (PressHotkeyCount == 2) {
        Assert(fragment_time_start == "", "未设置起点时间，无法生成该片段的链接！")
        ; 重置计数器
        PressHotkeyCount := 0
        Hotkey("Escape Up", "off")

        ; 第二次按下快捷键，记录时间
        fragment_time_end := GetMediaTime()

        ; 如果终点时间小于起点时间，就交换两个时间
        if (TimestampToMilliSecond(fragment_time_end) < TimestampToMilliSecond(fragment_time_start)) {
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