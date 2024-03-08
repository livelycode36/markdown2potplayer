#Requires AutoHotkey v2.0
#SingleInstance force
#Include "lib\note2potplayer\RegisterUrlProtocol.ahk"
#Include "lib\MyTool.ahk"
#Include "lib\ReduceTime.ahk"
#Include "lib\TemplateParser.ahk"
#Include "lib\sqlite\SqliteControl.ahk"
#Include lib\socket\Socket.ahk

#Include lib\entity\Config.ahk
#Include lib\PotplayerControl.ahk
#Include lib\gui\GuiControl.ahk

main()

main(){
    global
    TraySetIcon("lib/icon.png", 1, false)
    
    InitSqlite()

    app_config := Config()
    potplayer_control := PotplayerControl(app_config.PotplayerProcessName)

    InitGui(app_config, potplayer_control)

    InitServer()

    RegisterUrlProtocol(app_config.UrlProtocol)

    RegisterHotKey()
}

InitServer() {
    sock := winsock("server", callback, "IPV4")
    sock.Bind("0.0.0.0", 33660)
    sock.Listen()

    callback(sock, event, err) {
        if (sock.name = "server") || instr(sock.name, "serving-") {
            if (event = "accept") {
                sock.Accept(&addr, &newsock) ; pass &addr param to extract addr of connected machine
            } else if (event = "close") {
            } else if (event = "read") {
                If !(buf := sock.Recv()).size
                    return

                ; 返回html
                html_body := '<h1>open potplayer...</h1>'
                httpResponse := "HTTP/1.1 200 0K`r`n"
                    . "Content-Type: text/html; charset=UTF-8`r`n"
                    . "Content-Length: " StrLen(html_body) "`r`n"
                    . "`r`n"
                httpResponse := httpResponse html_body
                strbuf := Buffer(StrPut(httpResponse, "UTF-8"))
                StrPut(httpResponse, strbuf, "UTF-8")
                sock.Send(strbuf)
                sock.ConnectFinish()

                ; 得到回链
                request := strget(buf, "UTF-8")
                RegExMatch(request, "GET /(.+?) HTTP/1.1", &match)
                if (match == "") {
                    return
                }
                backlink := match[1]
                if (!InStr(backlink, "path=")) {
                    return
                }

                ; 打开potplayer
                cmd := A_ScriptDir "\lib\note2potplayer\note2potplayer.exe " backlink
                Run(cmd,,"Hide",,)
                Send "^w"

                ; 我真无语，Run命令会阻塞socket库，且autohotkey没有多线程，只能用这种方法，让socket库继续运行
                Run(A_ScriptDir "\markdown2potplayer.exe")
                ExitApp
            }
        }
    }
}

RegisterHotKey(){
    HotIf CheckCurrentProgram
    Hotkey app_config.HotkeyBacklink " Up", Potplayer2Obsidian
    Hotkey app_config.HotkeyIamgeBacklink " Up", Potplayer2ObsidianImage
    Hotkey app_config.HotkeyAbFragment " Up", Potplayer2ObsidianFragment
    Hotkey app_config.HotkeyAbCirculation " Up", Potplayer2ObsidianFragment
    Hotkey app_config.HotkeyPreviousFrame " Up", (*) => potplayer_control.PreviousFrame()
    Hotkey app_config.HotkeyNextFrame " Up", (*) => potplayer_control.NextFrame()
    Hotkey app_config.HotkeyForward " Up", (*) => Forward(app_config, potplayer_control)
    Hotkey app_config.HotkeyBackward " Up", (*) => Backward(app_config, potplayer_control)
    Hotkey app_config.HotkeyPlayOrPause " Up", (*) => potplayer_control.PlayOrPause()
    Hotkey app_config.HotkeyStop " Up", (*) => potplayer_control.Stop()
}

RefreshHotkey(old_hotkey,new_hotkey,callback){
    try{
        ; 情况1：用户删除热键
        if new_hotkey == ""{
            if(old_hotkey != ""){
                Hotkey old_hotkey " Up", "off"
            }
        } else{
            ; 情况2：用户重设热键
            if(old_hotkey != ""){
                Hotkey old_hotkey " Up", "off"
            }
            HotIf CheckCurrentProgram
            Hotkey new_hotkey " Up", callback
        }
    }
    catch Error as err{
        ; 热键设置无效
        ; 防止无效的快捷键产生报错，中断程序
        Exit
    }
}
Forward(app_config, potplayer_control){
    try{
        if(app_config.ForwardSeconds != 0){
            potplayer_control.SetMediaTimeMilliseconds(Integer(potplayer_control.GetMediaTimeMilliseconds() + (app_config.ForwardSeconds * 1000)))
        }else{
            potplayer_control.Forward()
        }
    }catch Error as err{
        MsgBox "Forward Seconds and Backward Seconds It can't be empty"
    }
}
Backward(app_config, potplayer_control){
    try{
        if(app_config.BackwardSeconds != 0){
            potplayer_control.SetMediaTimeMilliseconds(Integer(potplayer_control.GetMediaTimeMilliseconds() - (app_config.BackwardSeconds * 1000)))
        }else{
            potplayer_control.Backward()
        }
    }catch Error as err{
        MsgBox "Forward Seconds and Backward Seconds It can't be empty"
    }
}
CheckCurrentProgram(*){
    programs := app_config.PotplayerProcessName "`n" app_config.NoteAppName
    Loop Parse programs, "`n"{
        program := A_LoopField
        if program{
            if WinActive("ahk_exe " program){
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

    if(IsWordProgram()){
        SendText2wordApp(markdown_link)
    }else{
        SendText2NoteApp(markdown_link)
    }
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
    return PressDownHotkey(potplayer_control.GetMediaPathToClipboard)
}
GetMediaTime(){
    time := PressDownHotkey(potplayer_control.GetMediaTimestampToClipboard)

    if (app_config.ReduceTime != "0") {
        time := ReduceTime(time, app_config.ReduceTime)
    }
    return time
}
PressDownHotkey(operate_potplayer){
    ; 先让剪贴板为空, 这样可以使用 ClipWait 检测文本什么时候被复制到剪贴板中.
    A_Clipboard := ""
    ; 调用函数会丢失this，将对象传入，以便不会丢失this => https://wyagd001.github.io/v2/docs/Objects.htm#Custom_Classes_method
    operate_potplayer(potplayer_control)
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
        potplayer_control.PlayPause()
    }
}

RenderTitle(markdown_template, markdown_title, media_path, media_time){
    markdown_link_data := GenerateMarkdownLinkData(markdown_title, media_path, media_time)
    ; 生成word链接
    if(IsWordProgram()){
        word_link := "<a href='http://127.0.0.1:33660/" markdown_link_data.link "'>"  markdown_link_data.title "</a>"
        result := StrReplace(markdown_template, "{title}",word_link)
        result := StrReplace(result, "`n","<br/>")
    }else{
        ; 生成MarkDown链接
        markdown_link := GenerateMarkdownLink(markdown_link_data.title, markdown_link_data.link)
        result := StrReplace(markdown_template, "{title}",markdown_link)
    }
    return result
}

IsWordProgram(){
    target_program := SelectedNoteProgram(app_config.NoteAppName)
    return target_program == "wps.exe" || target_program == "winword.exe"
}
IsNotionProgram(){
    target_program := StrLower(SelectedNoteProgram(app_config.NoteAppName))
    return  target_program == "msedge.exe" 
    || target_program == "chrome.exe"
    || target_program == "360chrome.exe"
    || target_program == "firefox.exe"
}

; // [用户想要的标题格式](mk-potplayer://open?path=1&aaa=123&time=456)
GenerateMarkdownLinkData(markdown_title, media_path, media_time){
    ; B站的视频
    if (InStr(media_path,"https://www.bilibili.com/video/")){
        ; 正常播放的情况
        name := StrReplace(GetPotplayerTitle(app_config.PotplayerProcessName), " - PotPlayer", "")
        
        ; 视频没有播放，已经停止的情况，不是暂停是停止
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
    
    result := {}
    result.title := markdown_title
    result.link := markdown_link
    return result
}

GenerateMarkdownLink(markdown_title, markdown_link){
    if(IsNotionProgram()){
        result := "[" markdown_title "](http://127.0.0.1:33660/" markdown_link ")"
    }else{
        result := "[" markdown_title "](" markdown_link ")"
    }
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
    identifier := "{image}"
    image_templates := TemplateConvertedToTemplates(markdown_image_template, identifier)
    For index, image_template in image_templates{
        if (image_template == identifier){
            SendImage2NoteApp(image)
        } else {
            rendered_template := RenderMarkdownTemplate(image_template, media_path, media_time)
            if(IsWordProgram() && InStr(image_template,"{title}")){
                SendText2wordApp(rendered_template)
            }else{
                SendText2NoteApp(rendered_template)
            }
        }
    }
}

RemoveSuffix(name){
    index_of := InStr(name, ".",,-1)
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
    }else{
        ; 全系urlencode的bug：如果路径中存在"\["会让，在【ob的预览模式】下(回链会被ob自动urlencode)，"\"离奇消失变为,"["；例如：G:\BaiduSyncdisk\123\[456] 在bug下变为：G:\BaiduSyncdisk\123[456] <= 丢失了"\"
        ; 所以先将"\["替换为"%5C["（\的urlencode编码%5C）。变为：G:\BaiduSyncdisk\123%5C[456]
        media_path := StrReplace(media_path, "\[", "%5C[")
        media_path := StrReplace(media_path, "\!", "%5C!")
        ; 但是 obidian中的potplayer回链路径有空格，在obsidian的预览模式【无法渲染】，所以将空格进行Url编码
        media_path := StrReplace(media_path, " ", "%20")
    }

    return media_path
}

SendText2NoteApp(text){
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)

    A_Clipboard := ""
    A_Clipboard := text
    ClipWait 2,0
    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"
    ; 粘贴文字需要等待一下obsidian有延迟，不然会出现粘贴的文字【消失】
    Sleep 300
}
SendText2wordApp(text){
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)
    Run(A_ScriptDir "\lib\word\word.exe " text,,"Hide",,)
}

SaveImage(){
    Assert(potplayer_control.GetPlayStatus() == "Stopped" , "视频尚未播放，无法截图！")

    A_Clipboard := ""
    potplayer_control.SaveImageToClipboard()
    if !ClipWait(2,1){
        SafeRecursion()
    }
    running_count := 0
    return ClipboardAll()
}
SendImage2NoteApp(image){
    selected_note_program := SelectedNoteProgram(app_config.NoteAppName)
    ActivateProgram(selected_note_program)
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
        
        HotIf CheckCurrentProgram
        Hotkey("Escape Up",cancel,"On")
        cancel(*){
            ; 重置计数器
            PressHotkeyCount := 0
            Hotkey("Escape Up", "off")
        }
    } else if (PressHotkeyCount == 2){
        Assert(fragment_start_time == "", "未设置起点时间，无法生成该片段的链接！")
        ; 重置计数器
        PressHotkeyCount := 0
        Hotkey("Escape Up", "off")

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

        ; 发送到笔记软件
        if(IsWordProgram()){
            SendText2wordApp(markdown_link)
        }else{
            SendText2NoteApp(markdown_link)
        }
    }
}