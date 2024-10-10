#Requires Autohotkey v2
#Include i18n\I18n.ahk

;AutoGUI creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;EasyAutoGUI-AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

creationGui() {
	i18n_local := I18n(A_WorkingDir "\lib\gui\i18n")

	guiData := Constructor(i18n_local)

	; =======界面设置=========
	guiData.myGui.OnEvent('Close', (*) => guiData.myGui.Hide())
	guiData.myGui.OnEvent('Escape', (*) => guiData.myGui.Hide())
	version := "0.2.5"
	guiData.myGui.Title := "markdown2potpalyer - " version

	; =======托盘菜单=========
	myMenu := A_TrayMenu

	window_size := "w477 h780"

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
	Tab := myGui.Add("Tab3", "x0 y0 w493 h745", [i18n_local.Gui_Tab_backlink_setting, i18n_local.Gui_Tab_potplayer_hotkey_setting])
	Tab.UseTab(1)

	myGui.Add("Text", "x40 y24 w132 h23", i18n_local.Gui_potplayer_path)
	; =======模板=========
	Edit_potplayer := myGui.Add("Edit", "x160 y22 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
	Button_potplayer := myGui.Add("Button", "x384 y22 w103 h23", i18n_local.Gui_choose_potplayer)

	myGui.Add("Text", "x40 y49 w109 h23", i18n_local.Gui_note_names)
	Edit_note_app_name := myGui.Add("Edit", "x160 y48 w162 h63 +Multi", "Obsidian.exe`nTypora.exe")
	myGui.Add("Text", "x160 y121 w123 h23", i18n_local.Gui_note_names_tips)

	myGui.Add("Text", "x40 y136 w63 h23", i18n_local.Gui_subtitle_template_name)
	Edit_subtitle_template := myGui.Add("Edit", "x160 y136 w162 h30 +Multi", "字幕：`n{subtitle}")
	Button_srt_to_backlink_mdfile := myGui.Add("Button", "x384 y136 w103 h23", "srt转回链md")

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

	Tab.UseTab(2)
	myGui.Add("Text", "x86 y24 w42 h23", i18n_local.Gui_hotkey_previous_frame)
	hk_previous_frame := myGui.Add("Hotkey", "x152 y24 w120 h21")
	myGui.Add("Text", "x86 y48 w38 h23", i18n_local.Gui_hotkey_next_frame)
	hk_next_frame := myGui.Add("Hotkey", "x152 y48 w120 h21")
	myGui.Add("Text", "x86 y80", i18n_local.Gui_hotkey_forward)
	hk_forward := myGui.Add("Hotkey", "x152 y80 w120 h21")
	Edit_forward_seconds := myGui.Add("Edit", "x280 y80 w37 h21")
	myGui.Add("Text", "x322 y80 w17", i18n_local.Gui_second)
	myGui.Add("Text", "x86 y104", i18n_local.Gui_hotkey_backward)
	hk_backward := myGui.Add("Hotkey", "x152 y104 w120 h21")
	Edit_backward_seconds := myGui.Add("Edit", "x281 y104 w36 h21")
	myGui.Add("Text", "x322 y102", i18n_local.Gui_second)
	myGui.Add("Text", "x86 y133", i18n_local.Gui_hotkey_play_or_pause)
	hk_play_or_pause := myGui.Add("Hotkey", "x152 y129 w120 h21")
	myGui.Add("Text", "x86 y153 w24 h21", i18n_local.Gui_hotkey_stop)
	hk_stop := myGui.Add("Hotkey", "x152 y153 w120 h21")

	Tab.UseTab()
	myGui.Add("Link", "x432 y755 w48 h12", "<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">" i18n_local.Gui_check_update "</a>")

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
	guiData.controls.hk_previous_frame := hk_previous_frame
	guiData.controls.hk_next_frame := hk_next_frame
	guiData.controls.hk_forward := hk_forward
	guiData.controls.Edit_forward_seconds := Edit_forward_seconds
	guiData.controls.hk_backward := hk_backward
	guiData.controls.Edit_backward_seconds := Edit_backward_seconds
	guiData.controls.hk_play_or_pause := hk_play_or_pause
	guiData.controls.hk_stop := hk_stop

	return guiData
}