#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%\lib\MyTool.ahk"
#Include "%A_ScriptDir%\lib\ReduceTime.ahk"

potplayer_path := IniRead("config.ini", "PotPlayer", "path")
is_stop := IniRead("config.ini", "PotPlayer", "is_stop")
reduce_time := IniRead("config.ini", "PotPlayer", "reduce_time")
screenshot := 0
potplayer_name := GetProgramName(potplayer_path)
note_app_name := IniRead("config.ini", "Note", "app_name")
url_protocol := IniRead("config.ini", "Note", "url_protocol")
markdown_template := IniRead("config.ini", "MarkDown", "template")
markdown_tittle := IniRead("config.ini", "MarkDown", "tittle")
path_is_encode := IniRead("config.ini", "MarkDown", "path_is_encode")
running_count := 0

InitNote2PotPlayer()

#HotIf WinActive("ahk_exe " . potplayer_name) or WinActive("ahk_exe " . note_app_name)
{
    ; 【定义热键，默认：Alt+G】如何定义热键参考官方文档：https://wyagd001.github.io/v2/docs/Hotkeys.htm
    !g up::{
        ; 在笔记软件中按快捷键没有问题。但是在Potplayer中按快捷键，会出现问题：Potplayer的快捷键被触发了，解决办法是：等待快捷键释放，然后再执行
        KeyWait "Alt","T1"
        KeyWait "g","T1"

        global screenshot := 0
        Potplayer2Obsidian(markdown_tittle)
    }
    ^!g up::{
        KeyWait "Control","T1"
        KeyWait "Alt","T1"
        KeyWait "g","T1"
        
        global screenshot := 1
        Potplayer2Obsidian(markdown_tittle)
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
Potplayer2Obsidian(markdown_tittle){
    ; 激活potplayer窗口
    if WinActive("ahk_exe " . note_app_name){
        ActivateProgram(potplayer_name)
    }
    
    media_path := GetMediaPath()
    media_time := GetMediaTime()
    SaveScreenshot()
    StopMedia()
    Paste2NoteApp(media_path, media_time, markdown_tittle,markdown_template)
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

    global running_count += 1
    ; 解决：一旦potplayer左上角出现提示，快捷键不生效的问题
    if (result == "") {
        if (running_count > 10) {
            MsgBox "error: Replication failed!"
            Exit
        }

        ; 无限重试！
        ActivateProgram(potplayer_name) ;防止potplayer关闭，导致无限递归
        result := PressDownHotkey(hotkey)
    }
    return result
}

StopMedia(){
    if (is_stop != "0") {
        Send "{Space}"
    }
}

Paste2NoteApp(media_path, media_time, markdown_tittle, markdown_template){
    ActivateProgram(note_app_name)
    Sleep 300 ; 给程序切换窗口的时间

    SendScreenshot()
    Sleep 500 ; 给Obsidian的图片处理插件的时间
    markdown_link := GenerateMarkdownLink(media_path, media_time, markdown_tittle)
    if (markdown_template == "") {
        Send2NoteApp(markdown_link)
    } else {
        Send2NoteApp(GenerateTemplate(markdown_link))
    }
}

GenerateMarkdownLink(media_path, media_time, markdown_tittle){
    ; // [用户想要的标题格式](mk-potplayer://open?path=1&aaa=123&time=456)
    markdown_tittle := StrReplace(markdown_tittle, "{name}",GetProgramName(media_path))
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

GenerateTemplate(markdown_link){
    global markdown_template
    result := StrReplace(markdown_template, "{tittle}",markdown_link)
    ; result := StrReplace(result, "{enter}","`n")
    result := StrReplace(result, "{enter}","`r`n")
    return result
}

Send2NoteApp(text){
    A_Clipboard := ""  ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := text
    ClipWait 1,0   ; 等待剪贴板中出现文本.
    Send "^v"
}
; 截图1：截取Potplayer的当前画面
SaveScreenshot(){
    if (screenshot == "0"){
        return
    }

    ClipboardSave := ""
    Send "^c"
    ClipWait 0.60,1
}
; 截图2：将截图发送到笔记软件中
SendScreenshot(){
    if (screenshot == "0"){
        return
    }
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
}

ActivateProgram(process_name){
    if (WinExist("ahk_exe " . process_name)) {
        WinActivate ("ahk_exe " . process_name)
    } else {
        MsgBox process_name . " is not running"
        Exit
    }
}