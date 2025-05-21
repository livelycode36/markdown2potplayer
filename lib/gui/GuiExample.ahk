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
	myGui.Title := "markdown2potpalyer"

	; =======托盘菜单=========
	myMenu := A_TrayMenu

	myMenu.Default := "&Open"
	myMenu.ClickCount := 2

	myMenu.Rename("&Open", "打开")
	myMenu.Rename("E&xit", "退出")
	myMenu.Rename("&Pause Script", "暂停脚本")
	myMenu.Rename("&Suspend Hotkeys", "暂停热键")

	myGui.Show("w477 h755")
}

Constructor() {
	myGui := Gui()
	myGui.BackColor := "0xffffff"
	; Tab := myGui.Add("Tab3", "x0 y0 w493 h745", ["回链设置", "Potplayer控制"])
	Tab := myGui.Add("Tab3", "x0 y0 w493 h725", ["回链设置"])
	Tab.UseTab(1)

	myGui.Add("Text", "x40 y24 w132 h20", "potplayer的路径")
	; =======模板=========
	Edit_potplayer := myGui.Add("Edit", "x160 y22 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
	Button_potplayer := myGui.Add("Button", "x380 y22 w90 h20", "选择Potplayer")

	myGui.Add("Text", "x40 y49 w132 h20", "笔记软件的程序名称")
	Edit_note_app_name := myGui.Add("Edit", "x160 y48 w190 h45 +Multi", "Obsidian.exe`nTypora.exe")
	myGui.Add("Text", "x160 y100 w123 h20", "多个笔记软件每行一个")

	myGui.Add("Text", "x40 y125 w63 h20", "字幕模板")
	Edit_note_app_name := myGui.Add("Edit", "x160 y125 w190 h30 +Multi", "字幕：`n{subtitle}")
	Button_srt_to_backlink_mdfile := myGui.Add("Button", "x380 y125 w90 h20", "srt转回链md")
	myGui.SetFont("s8")
  myGui.Add("Text", "x40 y160 w80 h20", "上/下句话(暂停)")
  hk_subtitle_previous_sentence_once := myGui.Add("Hotkey", "x160 y160 w90 h13", "^p")
  hk_subtitle_next_sentence_once := myGui.Add("Hotkey", "x260 y160 w90 h13", "^n")
	myGui.Add("Text", "x40 y175 w80 h20", "上/下句话(循环)")
  hk_subtitle_previous_sentence_loop := myGui.Add("Hotkey", "x160 y175 w90 h13", "^!p")
  hk_subtitle_next_sentence_loop := myGui.Add("Hotkey", "x260 y175 w90 h13", "^!n")
  myGui.SetFont()

	myGui.Add("Text", "x40 y195 w63 h20", "回链的名称")
	Edit_title := myGui.Add("Edit", "x160 y195 w190 h17", "{name} | {time}")

	myGui.Add("Text", "x40 y218 w51 h20", "回链模板")
	Edit_markdown_template := myGui.Add("Edit", "x160 y218 w190 h40 +Multi", "`n视频：{title}`n")

	myGui.Add("Text", "x40 y265 w77 h20", "图片回链模板")
	Edit_image_template := myGui.Add("Edit", "x160 y265 w190 h50 +Multi", "`n图片:{image}`n视频:{title}`n")

	myGui.Add("Text", "x40 y320 w111", "图片粘贴延迟")
	Edit6 := myGui.Add("Edit", "x160 y320 w120 h17")
	myGui.Add("Text", "x288 y320 w22 h20", "ms")

	; =======快捷键=========
  myGui.Add("Text", "x40 y343 w105 h20", "回链快捷键")
  hk_backlink := myGui.Add("Hotkey", "x160 y343 w120 h17", "!g")

  myGui.Add("Text", "x40 y365 w105 h20", "笔记快捷键")
  hk_backlink := myGui.Add("Hotkey", "x160 y365 w120 h17", "!n")

	myGui.Add("Text", "x40 y387 w105 h20", "字幕快捷键")
	hk_subtitle := myGui.Add("Hotkey", "x160 y387 w120 h17", "!t")

	myGui.Add("Text", "x40 y409 w105 h32", "图片+回链快捷键")
	hk_image_backlink := myGui.Add("Hotkey", "x160 y409 w120 h17", "^!g")
  myGui.SetFont("s8")
  myGui.Add("Text", "x40 y431 w105 h32", "外部工具截图快捷键")
  myGui.SetFont()
  hk_image_other_tool_screenshot := myGui.Add("Hotkey", "x160 y431 w120 h17", "!a")
  myGui.Add("Text", "x40 y453 w105 h32", "图片编辑")
  hk_image_edit := myGui.Add("Hotkey", "x160 y453 w120 h17", "!a")
  myGui.Add("Text", "x40 y475 w105 h32", "图片检测超时")
  Edit_Image_screenshot_detection_delays := myGui.Add("Edit", "x160 y475 w120 h17", "1000")
	myGui.Add("Text", "x288 y475 w31 h20", "s")

	myGui.Add("Text", "x40 y497 w114 h20", "A-B片段快捷键")
	hk_ab_fragment := myGui.Add("Hotkey", "x160 y497 w120 h17", "F1")

	myGui.Add("Text", "x40 y519 w98 h20", "A-B片段检测延迟")
	Edit_ab_fragment_detection_delays := myGui.Add("Edit", "x160 y519 w120 h17", "1000")
	myGui.Add("Text", "x288 y519 w31 h20", "ms")

	CheckBox_loop_ab_fragment := myGui.Add("CheckBox", "x160 y541 w120 h20", "循环播放片段")

	myGui.Add("Text", "x40 y563 w105 h12", "A-B循环快捷键")
	hk_ab_circulation := myGui.Add("Hotkey", "x160 y563 w190 h17")

	; =======其他设置=========
  myGui.SetFont("s8")
	myGui.Add("Text", "x40 y585 w105 h36", "修改协议【谨慎】此项重启生效")
	Edit_url_protocol := myGui.Add("Edit", "x160 y585 w190 h17", "jv://open")
  myGui.SetFont()

	myGui.Add("Text", "x40 y607 w60 h20", "减少的时间")
	Edit_reduce_time := myGui.Add("Edit", "x160 y607 w120 h17", "0")

	CheckBox_is_stop := myGui.Add("CheckBox", "x160 y629 w69 h17", "暂停")
	CheckBox_remove_suffix_of_video_file := myGui.Add("CheckBox", "x160 y651 w150 h17", "本地视频移除文件后缀名")
	CheckBox_path_is_encode := myGui.Add("CheckBox", "x160 y673 w120 h17", "路径编码")
	CheckBox_bootup := myGui.Add("CheckBox", "x160 y695 w120 h17", "开机启动")

	; Tab.UseTab(2)
	; myGui.Add("Text", "x86 y24 w42 h20", "上一帧")
	; hk_previous_frame := myGui.Add("Hotkey", "x152 y24 w120 h17")
	; myGui.Add("Text", "x86 y48 w38 h20", "下一帧")
	; hk_next_frame := myGui.Add("Hotkey", "x152 y48 w120 h17")
	; myGui.Add("Text", "x86 y80", "快进")
	; hk_forward := myGui.Add("Hotkey", "x152 y80 w120 h17")
	; Edit_forward_seconds := myGui.Add("Edit", "x280 y80 w37 h17")
	; myGui.Add("Text", "x322 y80 w17", "秒")
	; myGui.Add("Text", "x86 y104", "快退")
	; hk_backward := myGui.Add("Hotkey", "x152 y104 w120 h17")
	; Edit_backward_seconds := myGui.Add("Edit", "x281 y104 w36 h17")
	; myGui.Add("Text", "x322 y102", "秒")
	; myGui.Add("Text", "x86 y133", "播放/暂停")
	; hk_play_or_pause := myGui.Add("Hotkey", "x152 y129 w120 h17")
	; myGui.Add("Text", "x86 y153 w24 h17", "停止")
	; hk_stop := myGui.Add("Hotkey", "x152 y153 w120 h17")

	Tab.UseTab()
	myGui.Add("Text", "x332 y725 w150 h12", "当前版本:0.2.6")
	myGui.Add("Link", "x332 y740 w150 h12", "最新版本:<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">0.2.6</a>")

	return myGui
}