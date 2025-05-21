#Requires Autohotkey v2
#Include i18n\I18n.ahk
#Include ..\MyTool.ahk

;AutoGUI creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;EasyAutoGUI-AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

creationGui() {
	i18n_local := I18n(A_WorkingDir "\lib\gui\i18n")

	guiData := Constructor(i18n_local)

	; =======界面设置=========
	guiData.myGui.OnEvent('Close', (*) => guiData.myGui.Hide())
	guiData.myGui.OnEvent('Escape', (*) => guiData.myGui.Hide())
	guiData.myGui.Title := "markdown2potpalyer"

	; =======托盘菜单=========
	myMenu := A_TrayMenu

	window_size := "w477 h788"

	myMenu.Add("&Open", (*) => guiData.myGui.Show(window_size))
	myMenu.Default := "&Open"
	myMenu.ClickCount := 2

	myMenu.Rename("&Open", i18n_local.Gui_open)
	myMenu.Rename("E&xit", i18n_local.Gui_exit)
	myMenu.Rename("&Pause Script", i18n_local.Gui_pause_script)
	myMenu.Rename("&Suspend Hotkeys", i18n_local.Gui_suspend_hotkeys)

	return guiData
}

Constructor(i18n_local) {
	guiData := {
		myGui: {},
		controls: {}
	}

	myGui := Gui()
	myGui.BackColor := "0xffffff"
	Tab := myGui.Add("Tab3", "x0 y0 w493 h745", [i18n_local.Gui_Tab_backlink_setting])
	Tab.UseTab(1)

	myGui.Add("Text", "x40 y24 w132 h23", i18n_local.Gui_potplayer_path)
	; =======模板=========
	Edit_potplayer := myGui.Add("Edit", "x160 y22 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
	Button_potplayer := myGui.Add("Button", "x384 y22 w103 h23", i18n_local.Gui_choose_potplayer)

	myGui.Add("Text", "x40 y49 w109 h23", i18n_local.Gui_note_names)
	Edit_note_app_name := myGui.Add("Edit", "x160 y48 w162 h63 +Multi", "Obsidian.exe`nTypora.exe")
	myGui.Add("Text", "x160 y121 w123 h23", i18n_local.Gui_note_names_tips)

	myGui.Add("Text", "x40 y150 w63 h23", i18n_local.Gui_subtitle_template_name)
	Edit_subtitle_template := myGui.Add("Edit", "x160 y150 w162 h30 +Multi", "字幕：`n{subtitle}")
	Button_srt_to_backlink_mdfile := myGui.Add("Button", "x384 y150 w103 h23", i18n_local.Gui_srt_to_backlink)

	myGui.Add("Text", "x40 y185 w63 h23", i18n_local.Gui_backlink_name)
	Edit_title := myGui.Add("Edit", "x160 y185 w148 h23", "{name} | {time}")

	myGui.Add("Text", "x40 y223 w51 h23", i18n_local.Gui_backlink_template)
	Edit_markdown_template := myGui.Add("Edit", "x160 y223 w149 h48 +Multi", "`n视频：{title}`n")

	myGui.Add("Text", "x40 y284 w77 h23", i18n_local.Gui_image_backlink_tempalte_name)
	Edit_image_template := myGui.Add("Edit", "x160 y284 w151 h66 +Multi", "`n图片:{image}`n视频:{title}`n")

	myGui.Add("Text", "x40 y355 w111", i18n_local.Gui_send_image_delays)
	Edit_send_image_delays := myGui.Add("Edit", "x160 y355 w120 h21")
	myGui.Add("Text", "x288 y355 w22 h23", "ms")

	; =======快捷键=========
	myGui.Add("Text", "x40 y387 w105 h23", i18n_local.Gui_hotkey_title)
	hk_subtitle := myGui.Add("Hotkey", "x160 y387 w156 h21", "!t")

	myGui.Add("Text", "x40 y416 w105 h23", i18n_local.Gui_hotkey_backlink)
	hk_backlink := myGui.Add("Hotkey", "x160 y416 w156 h21", "!g")

	myGui.Add("Text", "x40 y448 w105 h32", i18n_local.Gui_hotkey_image_and_backlink)
	hk_image_backlink := myGui.Add("Hotkey", "x160 y448 w156 h21", "^!g")

	myGui.Add("Text", "x40 y472 w114 h23", i18n_local.Gui_hotkey_ab_fragment)
	hk_ab_fragment := myGui.Add("Hotkey", "x160 y472 w156 h21", "F1")

	myGui.Add("Text", "x40 y501 w98 h23", i18n_local.Gui_hotkey_ab_fragment_detection_delays)
	Edit_ab_fragment_detection_delays := myGui.Add("Edit", "x160 y501 w120 h21", "1000")
	myGui.Add("Text", "x288 y501 w31 h23", "ms")

	CheckBox_loop_ab_fragment := myGui.Add("CheckBox", "x160 y518 w120 h23", i18n_local.Gui_is_loop_ab_fragment)

	myGui.Add("Text", "x40 y547 w105 h12", i18n_local.Gui_hotkey_ab_circulation)
	hk_ab_circulation := myGui.Add("Hotkey", "x160 y547 w156 h21")

	; =======其他设置=========
	myGui.Add("Text", "x40 y582 w105 h36", i18n_local.Gui_edit_url_protocol)
	Edit_url_protocol := myGui.Add("Edit", "x160 y582 w156 h21", "jv://open")

	myGui.Add("Text", "x40 y618 w60 h23", i18n_local.Gui_reduce_time)
	Edit_reduce_time := myGui.Add("Edit", "x160 y618 w120 h21", "0")

	CheckBox_is_stop := myGui.Add("CheckBox", "x160 y642 w69 h23", i18n_local.Gui_is_stop)
	CheckBox_remove_suffix_of_video_file := myGui.Add("CheckBox", "x160 y666 w150 h23", i18n_local.Gui_remove_suffix_of_video_file)
	CheckBox_path_is_encode := myGui.Add("CheckBox", "x160 y690 w120 h23", i18n_local.Gui_is_path_encode)
	CheckBox_bootup := myGui.Add("CheckBox", "x160 y714 w120 h23", i18n_local.Gui_bootup)

	Tab.UseTab()
  myGui.Add("Text", "x332 y755 w150 h12", i18n_local.Gui_current_version ":0.2.6")
  myGui.Add("Link", "x332 y770 w150 h12", i18n_local.Gui_latest_version ":<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">" getLatestVersionFromGithub() "</a>")
	; myGui.Add("Link", "x432 y755 w48 h12", "<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">去下载</a>")

	guiData.myGui := myGui
	guiData.controls.Edit_potplayer := Edit_potplayer
	guiData.controls.Button_potplayer := Button_potplayer
	guiData.controls.Edit_note_app_name := Edit_note_app_name
	guiData.controls.Edit_subtitle_template := Edit_subtitle_template
	guiData.controls.Button_srt_to_backlink_mdfile := Button_srt_to_backlink_mdfile
	guiData.controls.Edit_title := Edit_title
	guiData.controls.Edit_markdown_template := Edit_markdown_template
	guiData.controls.Edit_image_template := Edit_image_template
	guiData.controls.Edit_send_image_delays := Edit_send_image_delays
	guiData.controls.hk_backlink := hk_backlink
	guiData.controls.hk_image_backlink := hk_image_backlink
	guiData.controls.hk_ab_fragment := hk_ab_fragment
	guiData.controls.Edit_ab_fragment_detection_delays := Edit_ab_fragment_detection_delays
	guiData.controls.CheckBox_loop_ab_fragment := CheckBox_loop_ab_fragment
	guiData.controls.hk_ab_circulation := hk_ab_circulation
	guiData.controls.Edit_url_protocol := Edit_url_protocol
	guiData.controls.Edit_reduce_time := Edit_reduce_time
	guiData.controls.CheckBox_is_stop := CheckBox_is_stop
	guiData.controls.CheckBox_remove_suffix_of_video_file := CheckBox_remove_suffix_of_video_file
	guiData.controls.CheckBox_path_is_encode := CheckBox_path_is_encode
	guiData.controls.CheckBox_bootup := CheckBox_bootup

	return guiData
}