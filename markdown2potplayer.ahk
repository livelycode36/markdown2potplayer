#Requires AutoHotkey v2.0
#SingleInstance force
#Include "lib\note2potplayer\RegisterUrlProtocol.ahk"
#Include "lib\MyTool.ahk"
#Include "lib\ReduceTime.ahk"
#Include "lib\ImageTemplateParser.ahk"
#Include "lib\sqlite\SqliteControl.ahk"

#Include lib\entity\Config.ahk
#Include lib\PotplayerController.ahk
#Include lib\gui\GuiController.ahk

main()

main(){
    global
    TraySetIcon("lib/icon.png", 1, false)
    
    InitSqlite()

    app_config := Config()
    potplayer_controller := PotplayerController(app_config.PotplayerProcessName)

    InitGui(app_config)

    RegisterUrlProtocol(app_config.UrlProtocol)

    RegisterHotKey()
}

RegisterHotKey(){
    HotIf CheckCurrentProgram
    Hotkey app_config.HotkeyBacklink " Up", Potplayer2Obsidian
    Hotkey app_config.HotkeyIamgeBacklink " Up", Potplayer2ObsidianImage
    Hotkey app_config.HotkeyAbFragment " Up", Potplayer2ObsidianFragment
    Hotkey app_config.HotkeyAbCirculation " Up", Potplayer2ObsidianFragment
}

RefreshHotkey(old_hotkey,new_hotkey,callback){
    try{
        Hotkey old_hotkey " Up", "off"
        HotIf CheckCurrentProgram
        Hotkey new_hotkey " Up" ,callback
    }
    catch Error as err{
        ; 热键设置无效
        ; 防止无效的快捷键产生报错，中断程序
        Exit
    }
}

CheckCurrentProgram(*){
    programs := app_config.PotplayerProcessName "`n" app_config.NoteAppName
    Loop Parse programs, "`n"{
        program := A_LoopField
        if program{
            if WinActive("ahk_exe" program){
                return true
            }
        }
    }
    return false
}

; 【主逻辑】将Potplayer的播放链接粘贴到Obsidian中
Potplayer2Obsidian(*){
    ReleaseCommonUseKeyboard()

    media_path := GetMediaPath()
    media_time := GetMediaTime()
    
    markdown_link := RenderMarkdownTemplate(app_config.MarkdownTemplate, media_path, media_time)
    PauseMedia()

    SendText2NoteApp(markdown_link)
}

RenderMarkdownTemplate(markdown_template, media_path, media_time){
    if (InStr(markdown_template, "{title}") != 0){
        markdown_template := RenderTitle(markdown_template, app_config.MarkdownTitle, media_path, media_time)
    }
    return markdown_template
}

; 【主逻辑】粘贴图像
Potplayer2ObsidianImage(*){
    ReleaseCommonUseKeyboard()

    media_path := GetMediaPath()
    media_time := GetMediaTime()
    image := SaveImage()

    PauseMedia()

    RenderImage(app_config.MarkdownImageTemplate, media_path, media_time, image)
}

GetMediaPath(){
    return PressDownHotkey(potplayer_controller.GetMediaPathToClipboard)
}
GetMediaTime(){
    time := PressDownHotkey(potplayer_controller.GetMediaTimestampToClipboard)

    if (app_config.ReduceTime != "0") {
        time := ReduceTime(time, app_config.ReduceTime)
    }
    return time
}
PressDownHotkey(operate_potplayer){
    ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := ""
    ; 调用函数会丢失this，将对象传入，以便不会丢失this => https://wyagd001.github.io/v2/docs/Objects.htm#Custom_Classes_method
    operate_potplayer(potplayer_controller)
    ClipWait 1,0
    result := A_Clipboard
    ; MyLog "剪切板的值是：" . result

    ; 解决：一旦potplayer左上角出现提示，快捷键不生效的问题
    if (result == "") {
        SafeRecursion()
        ; 无限重试！
        result := PressDownHotkey(operate_potplayer)
    }
    running_count := 0
    return result
}

PauseMedia(){
    if (app_config.IsStop != "0") {
        potplayer_controller.Pause()
    }
}

RenderTitle(markdown_template, markdown_title, media_path, media_time){
    markdown_link := GenerateMarkdownLink(markdown_title, media_path, media_time)
    result := StrReplace(markdown_template, "{title}",markdown_link)
    return result
}

; // [用户想要的标题格式](mk-potplayer://open?path=1&aaa=123&time=456)
GenerateMarkdownLink(markdown_title, media_path, media_time){
    ; B站的视频
    if (InStr(media_path,"https://www.bilibili.com/video/")){
        ; 正常播放的情况
        name := StrReplace(GetPotplayerTitle(app_config.PotplayerProcessName), " - PotPlayer", "")
        
        ; 视频没有播放，已经停止的情况
        if name == "PotPlayer"{
            name := GetFileNameInPath(media_path)
        }
    } else{
        ; 本地视频
        name := GetFileNameInPath(media_path)
    }
    markdown_title := StrReplace(markdown_title, "{name}",name)
    markdown_title := StrReplace(markdown_title, "{time}",media_time)

    markdown_link := app_config.UrlProtocol "?path=" ProcessUrl(media_path) "&time=" media_time
    result := "[" markdown_title "](" markdown_link ")"
    return result
}

GetFileNameInPath(path){
    name := GetNameForPath(path)
    if (app_config.MarkdownRemoveSuffixOfVideoFile != "0"){
        name := RemoveSuffix(name)
    }
    return name
}

RenderImage(markdown_image_template, media_path, media_time, image){
    image_templates := ImageTemplateConvertedToImagesTemplates(markdown_image_template)
    For index, image_template in image_templates{
        if (image_template == "{image}"){
            SendImage2NoteApp(image)
        } else {
            SendText2NoteApp(RenderMarkdownTemplate(image_template, media_path, media_time))
        }
    }
}

RemoveSuffix(name){
    index_of := InStr(name, ".")
    if (index_of = 0){
        return name
    }
    result := SubStr(name, 1,index_of-1)
    return result
}

; 路径地址处理
ProcessUrl(media_path){
    ; 进行Url编码
    if (app_config.MarkdownPathIsEncode != "0"){
        media_path := UrlEncode(media_path)
    }
    ; 但是 obidian中的potplayer回链路径有空格，在obsidian的预览模式【无法渲染】，所以将空格进行Url编码
    media_path := StrReplace(media_path, " ", "%20")

    return media_path
}

SendText2NoteApp(text){
    ActivateNoteProgram(app_config.NoteAppName)
    A_Clipboard := ""
    A_Clipboard := text
    ClipWait 2,0
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 粘贴文字需要等待一下obsidian有延迟，不然会出现粘贴的文字【消失】
    Sleep 300
}

SaveImage(){
    Assert(potplayer_controller.GetPlayStatus() == "Stopped" , "视频尚未播放，无法截图！")

    A_Clipboard := ""
    potplayer_controller.SaveImageToClipboard()
    if !ClipWait(2,1){
        SafeRecursion()
    }
    running_count := 0
    return ClipboardAll()
}
SendImage2NoteApp(image){
    ActivateNoteProgram(app_config.NoteAppName)
    A_Clipboard := ""
    A_Clipboard := ClipboardAll(image)
    ClipWait 2,1
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 给Obsidian图片插件处理图片的时间
    Sleep 1000
}

; 【A-B片段、循环】
PressHotkeyCount := 0
Potplayer2ObsidianFragment(HotkeyName){
    global
    ReleaseCommonUseKeyboard()

    PressHotkeyCount += 1

    if (PressHotkeyCount == 1){
        ; 第一次按下快捷键，记录时间
        fragment_start_time := GetMediaTime()
        ; 通知用户
        ToolTip("已经记录起点的时间！请再次按下快捷键，记录终点的时间。按Esc取消")
        SetTimer () => ToolTip(), -2000
        Hotkey("Esc",cancel)
        cancel(*){
            PressHotkeyCount := 0
            Hotkey("Esc", "off")
        }
    } else if (PressHotkeyCount == 2){
        Assert(fragment_start_time == "", "未设置起点时间，无法生成该片段的链接！")
        Hotkey("Esc", "off")

        ; 第二次按下快捷键，记录时间
        fragment_end_time := GetMediaTime()

        ; 如果终点时间小于起点时间，就交换两个时间
        if (TimeToSeconds(fragment_end_time) < TimeToSeconds(fragment_start_time)){
            temp := fragment_start_time
            fragment_start_time := fragment_end_time
            fragment_end_time := temp
            ; 释放内存
            temp := ""
        }

        ; 重置计数器
        PressHotkeyCount := 0

        media_path := GetMediaPath()
        
        if fragment_start_time == fragment_end_time{
            fragment_time := fragment_start_time
        }else if HotkeyName == app_config.HotkeyAbFragment " Up"{
            fragment_time := fragment_start_time "-" fragment_end_time
        }else if HotkeyName == app_config.HotkeyAbCirculation " Up"{
            fragment_time := fragment_start_time "∞" fragment_end_time
        }
        
        ; 生成片段链接
        markdown_link := RenderMarkdownTemplate(app_config.MarkdownTemplate, media_path, fragment_time)
        PauseMedia()

        ; 发送到Obsidian
        SendText2NoteApp(markdown_link)
    }
}