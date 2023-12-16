#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%\lib\MyTool.ahk"
#Include "%A_ScriptDir%\lib\ReduceTime.ahk"

potplayer_path := IniRead("config.ini", "PotPlayer", "path")
is_stop := IniRead("config.ini", "PotPlayer", "is_stop")
reduce_time := IniRead("config.ini", "PotPlayer", "reduce_time")

potplayer_name := GetNameForPath(potplayer_path)

note_app_name := IniRead("config.ini", "Note", "app_name")
url_protocol := IniRead("config.ini", "Note", "url_protocol")

markdown_template := IniRead("config.ini", "MarkDown", "template")
markdown_image_template := IniRead("config.ini", "MarkDown", "image_template")
markdown_tittle := IniRead("config.ini", "MarkDown", "tittle")
path_is_encode := IniRead("config.ini", "MarkDown", "path_is_encode")

running_count := 0
clipboard_has_screenshot := 0
InitNote2PotPlayer()

#HotIf WinActive("ahk_exe " . potplayer_name) or WinActive("ahk_exe " . note_app_name)
{
    ; 【定义热键，默认：Alt+G】
    ; 如何定义热键参考官方文档：https://wyagd001.github.io/v2/docs/Hotkeys.htm
    !g up::{
        ; 在笔记软件中按快捷键没有问题。但是在Potplayer中按快捷键，会出现问题：Potplayer的快捷键被触发了，解决办法是：等待快捷键释放，然后再执行
        KeyWait "Alt","T1"
        KeyWait "g","T1"

        Potplayer2Obsidian(markdown_template)
        StopMedia()
    }
    ^!g up::{
        KeyWait "Control","T1"
        KeyWait "Alt","T1"
        KeyWait "g","T1"
        
        Potplayer2ObsidianScreenshot(markdown_image_template)
        StopMedia()
    }
}

InitNote2PotPlayer(){
    protocol_name := GetProtocolName(url_protocol)
    RegistrationProtocol(protocol_name)
}
  
GetProtocolName(url_protocol){
    index_of := InStr(url_protocol, ":")
    if (index_of = 0){
        MsgBox "error: protocol no ':' found"
        Exit
    }
    result := SubStr(url_protocol, 1,index_of-1)
    return result
}
  
RegistrationProtocol(protocol_name){
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name
    RegWrite "", "REG_SZ", "HKEY_CURRENT_USER\Software\Classes\" protocol_name, "URL Protocol"
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell"
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell\open"
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell\open\command"
    RegWrite A_ScriptDir "\note2potplayer.exe `"%1`"", "REG_SZ", "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell\open\command"
}

; 【主逻辑】将Potplayer的播放链接粘贴到Obsidian中
Potplayer2Obsidian(markdown_template){
    ; 用户模板中有{tittle}，则渲染模板，否则不渲染直接粘贴用户的数据
    if (InStr(markdown_template,"{tittle}")){
        ActivateProgram(potplayer_name)
        media_path := GetMediaPath()
        media_time := GetMediaTime()
    
        markdown_template := RenderTittle(media_path, media_time, markdown_tittle, markdown_template)
    }
    markdown_template := RenderEnter(markdown_template)
    Paste2NoteApp(markdown_template)
}

; 【主逻辑】粘贴图像
Potplayer2ObsidianScreenshot(markdown_image_template){
    image_templates := ImageTemplateConvertedToImagesTemplates(markdown_image_template)

    For index, template in image_templates{
        if (template == "{image}"){
            PasteImage2NoteApp()
        } else {
            Potplayer2Obsidian(template)
        }
    }
}

ActivateProgram(process_name){
    if WinActive("ahk_exe " . process_name){
        return
    }

    if (WinExist("ahk_exe " . process_name)) {
        WinActivate ("ahk_exe " . process_name)
        Sleep 300 ; 给程序切换窗口的时间
    } else {
        MsgBox process_name . " is not running"
        Exit
    }
}

GetMediaPath(){
    hotkey := "!,"

    return PressDownHotkey(hotkey)
}
GetMediaTime(){
    hotkey := "!."
    time := PressDownHotkey(hotkey)

    if (reduce_time != "0") {
        time := ReduceTime(time,reduce_time)
    }
    return time
}
PressDownHotkey(hotkey){
    clip_saved := A_Clipboard
    ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := ""
    Send hotkey
    ClipWait 0.60,0
    result := A_Clipboard
    ; MyLog "剪切板的值是：" . result
    A_Clipboard := clip_saved

    global running_count := 0
    ; 解决：一旦potplayer左上角出现提示，快捷键不生效的问题
    if (result == "") {
        global running_count += 1
        if (running_count > 20) {
            MsgBox "error: Replication failed!"
            running_count := 0
            Exit
        }

        ; 无限重试！
        result := PressDownHotkey(hotkey)
    }
    return result
}

StopMedia(){
    if (is_stop != "0") {
        ActivateProgram(potplayer_name)
        Send "{Space}"
    }
}

RenderTittle(media_path, media_time, markdown_tittle, markdown_template){
    markdown_link := GenerateMarkdownLink(media_path, media_time, markdown_tittle)
    result := StrReplace(markdown_template, "{tittle}",markdown_link)
    return result
}

RenderEnter(template){
    result := StrReplace(template, "{enter}","`n")
    return result
}

Paste2NoteApp(template){
    ActivateProgram(note_app_name)
    Send2NoteApp(template)
}

GenerateMarkdownLink(media_path, media_time, markdown_tittle){
    ; // [用户想要的标题格式](mk-potplayer://open?path=1&aaa=123&time=456)
    markdown_tittle := StrReplace(markdown_tittle, "{name}",GetNameForPath(media_path))
    markdown_tittle := StrReplace(markdown_tittle, "{time}",media_time)

    markdown_link := url_protocol "?path=" ProcessUrl(media_path) "&time=" media_time
    result := "[" markdown_tittle "](" markdown_link ")"
    return result
}

; 路径地址处理
ProcessUrl(media_path){
    ; 进行Url编码
    if (path_is_encode != "0"){
        media_path := UrlEncode(media_path)
    }
    ; 但是 obidian中的potplayer回链路径有空格，在obsidian的预览模式【无法渲染】，所以将空格进行Url编码
    media_path := StrReplace(media_path, " ", "%20")

    return media_path
}

Send2NoteApp(text){
    A_Clipboard := ""  ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := text
    ClipWait 2,0   ; 等待剪贴板中出现文本.
    ; Send "^v"
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
}

PasteImage2NoteApp(){
    ; 粘贴
    EnableWatchingClipboard()
    ; 截图
    SaveScreenshot()
}

; 【bug】：ClipWait无法检测剪切板是否有图片，所以使用OnClipboardChange的回调函数监控剪切板
EnableWatchingClipboard(){
    global clipboard_has_screenshot := 0
    OnClipboardChange SendScreenshot
}
DisableWatchingClipboard(){
    OnClipboardChange(SendScreenshot, 0)
    global clipboard_has_screenshot := 1
}
; 截图1：截取Potplayer的当前画面
SaveScreenshot(){
    ActivateProgram(potplayer_name)
    Send "^c"
    Sleep 500
    
    ; 【bug】:ClipWait无法检测剪切板是否有图片
    ; ClipWait(1,0)

    global running_count := 0
    ; 解决：一旦potplayer左上角出现提示，快捷键不生效的问题
    if (clipboard_has_screenshot == 0) {
        global running_count += 1
        if (running_count > 20) {
            MsgBox "error: Replication failed!"
            running_count := 0
            Exit
        }
        SaveScreenshot()
    }
}
; 截图2：将截图发送到笔记软件中
SendScreenshot(DataType){
    if DataType == 2 {
        DisableWatchingClipboard()

        ; 激活Obsidian
        ActivateProgram(note_app_name)

        Send "{LCtrl down}"
        Send "{v}"
        Send "{LCtrl up}"

        ; 给Obsidian的图片处理插件的时间
        Sleep 1000
    }
}

; 将用户的图像模板，例如：{image}{enter}tittle:{tittle}，以{image}分割，转为数组 => ["{image}","{enter}tittle:{tittle}"]
ImageTemplateConvertedToImagesTemplates(image_template){
    if (image_template == "{image}"){
      templates := ["{image}"]
      return templates
    } else {
      tempaltes := StrSplit(image_template, "{image}")
  
      For index, value in tempaltes{
        ; 当{image}在开头 及 末尾时，该项为null，所以它(null等于{images})本身就是{images}，不需要补{images}
        if (value == ""){
          continue
        }

        ; 修正：在模板的最后一项为【正常数据】的情况：
        ; 最后一项不需要补{image}，所以跳过
        if (index == tempaltes.Length && value != ""){
          continue
        }

        ; 修正：在模板的最后一项为{image}的情况：
        ; 因为是以{image}分割，所以最后一项为{image}时，值为null，当最后一项为{image}时，它的上一项也会补为{image}，所以 跳过 最后一项的上一项补{image}
        if ((index == tempaltes.Length - 1) && (tempaltes[tempaltes.Length] == "")){
            continue
        }
    
        ; 将非{image}的项后，加上{image}。因为是以{image}分割，所以给个数组项的后一项，都是{image}，将{imgae}给它补回去
        if (value != "{image}"){
          tempaltes.InsertAt(index + 1, "{image}")
        }
      }

      ; 修正：当{image}在开头 及 末尾时，该项为null
      For index, value in tempaltes{
        if (value == "" && index == 1){
            tempaltes[1] := "{image}"
        }

        if (value == "" && index == tempaltes.Length){
            tempaltes[tempaltes.Length] := "{image}"
        }
      }

      return tempaltes
    }
}