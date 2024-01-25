
#Requires Autohotkey v2
;AutoGUI 2.5.8 
;Auto-GUI-v2 credit to Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter credit to github.com/mmikeww/AHK-v2-script-converter

myGui := Gui()
myGui.Add("Text", "x24 y16 w132 h23", "potplayer播放器的路径")
Edit_potplayer := myGui.Add("Edit", "x160 y16 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
Button_potplayer := myGui.Add("Button", "x384 y16 w103 h23", "选择potplayer")

myGui.Add("Text", "x91 y48 w63 h23", "减少的时间")
Edit_reduce_time := myGui.Add("Edit", "x160 y48 w120 h21", "0")

myGui.Add("Text", "x40 y80 w109 h23", "笔记软件的程序名称")
Edit_note_app_name := myGui.Add("Edit", "x160 y80 w162 h63 +Multi", "Obsidian.exe`nTypora.exe")
myGui.Add("Text", "x160 y152 w123 h23", "多个笔记软件每行一个")

myGui.Add("Text", "x88 y184 w63 h23", "回链的名称")
Edit_title := myGui.Add("Edit", "x160 y184 w148 h21", "{name} | {time}")

myGui.Add("Text", "x104 y216 w51 h23", "回链模板")
Edit_makrdown_template := myGui.Add("Edit", "x160 y216 w149 h60 +Multi", "`n视频：{title}`n")

myGui.Add("Text", "x80 y288 w77 h23", "图片回链模板")
Edit_image_tempalte := myGui.Add("Edit", "x160 y288 w151 h79 +Multi", "`n图片:{image}`n视频:{title}`n")

CheckBox_is_stop := myGui.Add("CheckBox", "x160 y368 w69 h23", "是否暂停")
CheckBox_remove_suffix_of_video_file := myGui.Add("CheckBox", "x160 y388 w150 h23", "本地视频移除文件后缀名")
CheckBox_path_is_encode := myGui.Add("CheckBox", "x160 y416 w120 h23", "路径是否编码")
CheckBox_bootup := myGui.Add("CheckBox", "x160 y440 w120 h23", "开机启动")

myGui.Add("Text", "x56 y469 w100 h36", "修改协议【谨慎】`n此项重启生效")
Edit_url_protocol := myGui.Add("Edit", "x160 y470 w146 h21", "jv://open")

myGui.Add("Text", "x93 y506 w63 h23", "回链快捷键")
hk_backlink := myGui.Add("Hotkey", "x160 y504 w155 h21", "!g")

myGui.Add("Text", "x65 y538 w90 h23", "图片+回链快捷键")
hk_image_backlink := myGui.Add("Hotkey", "x160 y536 w156 h21", "^!g")

myGui.Add("Text", "x80 y566 w79 h16", "A-B片段快捷键")
hk_ab_fragment := myGui.Add("Hotkey", "x160 y562 w156 h21","F1")
myGui.Add("Text", "x80 y592 w79 h16", "A-B循环快捷键")
hk_ab_circulation := myGui.Add("Hotkey", "x160 y592 w156 h21","F2")

myGui.Add("Link", "x448 y648 w51 h17", "<a href=`"https://github.com/livelycode36/markdown2potplayer`">查看更新</a>")
