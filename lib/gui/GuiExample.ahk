#Requires Autohotkey v2
#SingleInstance force

;AutoGUI creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;EasyAutoGUI-AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

if A_LineFile = A_ScriptFullPath && !A_IsCompiled {
	myGui := Constructor()

	; =======界面设置=========
	myGui.OnEvent('Close', (*) => myGui.Hide())
	myGui.OnEvent('Escape', (*) => myGui.Hide())
	version := "0.2.5"
	myGui.Title := "markdown2potpalyer - " version

	; =======托盘菜单=========
	myMenu := A_TrayMenu

	myMenu.Default := "&Open"
	myMenu.ClickCount := 2

	myMenu.Rename("&Open", "打开")
	myMenu.Rename("E&xit", "退出")
	myMenu.Rename("&Pause Script", "暂停脚本")
	myMenu.Rename("&Suspend Hotkeys", "暂停热键")

	myGui.Show("w485 h774")
}

Constructor() {
	myGui := Gui()
	myGui.BackColor := "0xffffff"
	Tab := myGui.Add("Tab3", "x0 y0 w493 h745", ["回链设置", "Potplayer控制"])
	Tab.UseTab(1)

	myGui.Add("Text", "x40 y24 w132 h23", "potplayer播放器的路径")
	; =======模板=========
	Edit_potplayer := myGui.Add("Edit", "x160 y22 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
	Button_potplayer := myGui.Add("Button", "x384 y22 w103 h23", "选择Potplayer")

	myGui.Add("Text", "x40 y49 w109 h23", "笔记软件的程序名称")
	Edit_note_app_name := myGui.Add("Edit", "x160 y48 w162 h63 +Multi", "Obsidian.exe`nTypora.exe")
	myGui.Add("Text", "x160 y121 w123 h23", "多个笔记软件每行一个")

	myGui.Add("Text", "x40 y136 w63 h23", "字幕模板")
	Edit_note_app_name := myGui.Add("Edit", "x160 y136 w162 h30 +Multi", "字幕：`n{subtitle}")
	Button_srt_to_backlink_mdfile := myGui.Add("Button", "x384 y136 w103 h23", "srt转回链md")

	myGui.Add("Text", "x40 y185 w63 h23", "回链的名称")
	Edit_title := myGui.Add("Edit", "x160 y185 w148 h23", "{name} | {time}")

	myGui.Add("Text", "x40 y223 w51 h23", "回链模板")
	Edit_markdown_template := myGui.Add("Edit", "x160 y223 w149 h48 +Multi", "`n视频：{title}`n")

	myGui.Add("Text", "x40 y284 w77 h23", "图片回链模板")
	Edit_image_template := myGui.Add("Edit", "x160 y284 w151 h66 +Multi", "`n图片:{image}`n视频:{title}`n")

	myGui.Add("Text", "x40 y355 w111", "图片粘贴延迟")
	Edit6 := myGui.Add("Edit", "x160 y355 w120 h21")
	myGui.Add("Text", "x288 y355 w22 h23", "ms")

	; =======快捷键=========
	myGui.Add("Text", "x40 y387 w105 h23", "字幕快捷键")
	hk_subtitle := myGui.Add("Hotkey", "x160 y387 w156 h21", "!t")

	myGui.Add("Text", "x40 y416 w105 h23", "回链快捷键")
	hk_backlink := myGui.Add("Hotkey", "x160 y416 w156 h21", "!g")

	myGui.Add("Text", "x40 y448 w105 h32", "图片+回链快捷键")
	hk_image_backlink := myGui.Add("Hotkey", "x160 y448 w156 h21", "^!g")

	myGui.Add("Text", "x40 y472 w114 h23", "A-B片段快捷键")
	hk_ab_fragment := myGui.Add("Hotkey", "x160 y472 w156 h21", "F1")

	myGui.Add("Text", "x40 y501 w98 h23", "A-B片段检测延迟")
	Edit_ab_fragment_detection_delays := myGui.Add("Edit", "x160 y501 w120 h21", "1000")
	myGui.Add("Text", "x288 y501 w31 h23", "ms")

	CheckBox_loop_ab_fragment := myGui.Add("CheckBox", "x160 y518 w120 h23", "循环播放片段")

	myGui.Add("Text", "x40 y547 w105 h12", "A-B循环快捷键")
	hk_ab_circulation := myGui.Add("Hotkey", "x160 y547 w156 h21")

	; =======其他设置=========
	myGui.Add("Text", "x40 y582 w105 h36", "修改协议【谨慎】此项重启生效")
	Edit_url_protocol := myGui.Add("Edit", "x160 y582 w156 h21", "jv://open")

	myGui.Add("Text", "x40 y618 w60 h23", "减少的时间")
	Edit_reduce_time := myGui.Add("Edit", "x160 y618 w120 h21", "0")

	CheckBox_is_stop := myGui.Add("CheckBox", "x160 y642 w69 h23", "暂停")
	CheckBox_remove_suffix_of_video_file := myGui.Add("CheckBox", "x160 y666 w150 h23", "本地视频移除文件后缀名")
	CheckBox_path_is_encode := myGui.Add("CheckBox", "x160 y690 w120 h23", "路径编码")
	CheckBox_bootup := myGui.Add("CheckBox", "x160 y714 w120 h23", "开机启动")

	Tab.UseTab(2)
	myGui.Add("Text", "x86 y24 w42 h23", "上一帧")
	hk_previous_frame := myGui.Add("Hotkey", "x152 y24 w120 h21")
	myGui.Add("Text", "x86 y48 w38 h23", "下一帧")
	hk_next_frame := myGui.Add("Hotkey", "x152 y48 w120 h21")
	myGui.Add("Text", "x86 y80", "快进")
	hk_forward := myGui.Add("Hotkey", "x152 y80 w120 h21")
	Edit_forward_seconds := myGui.Add("Edit", "x280 y80 w37 h21")
	myGui.Add("Text", "x322 y80 w17", "秒")
	myGui.Add("Text", "x86 y104", "快退")
	hk_backward := myGui.Add("Hotkey", "x152 y104 w120 h21")
	Edit_backward_seconds := myGui.Add("Edit", "x281 y104 w36 h21")
	myGui.Add("Text", "x322 y102", "秒")
	myGui.Add("Text", "x86 y133", "播放/暂停")
	hk_play_or_pause := myGui.Add("Hotkey", "x152 y129 w120 h21")
	myGui.Add("Text", "x86 y153 w24 h21", "停止")
	hk_stop := myGui.Add("Hotkey", "x152 y153 w120 h21")

	Tab.UseTab()
	myGui.Add("Link", "x432 y755 w48 h12", "<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">检查更新</a>")

	return myGui
}