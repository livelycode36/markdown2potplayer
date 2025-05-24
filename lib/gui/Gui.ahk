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

	window_size := "w477 h755"

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
	Tab := myGui.Add("Tab3", "x0 y0 w493 h725", [i18n_local.Gui_Tab_backlink_setting])
	Tab.UseTab(1)

	myGui.Add("Text", "x40 y24 w132 h20", i18n_local.Gui_potplayer_path)
	; =======模板=========
	Edit_potplayer := myGui.Add("Edit", "x160 y22 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
  Button_potplayer := myGui.Add("Button", "x380 y22 w90 h30", i18n_local.Gui_choose_potplayer)

	myGui.Add("Text", "x40 y49 w132 h25", i18n_local.Gui_note_names)
	Edit_note_app_name := myGui.Add("Edit", "x160 y48 w190 h45 +Multi", "Obsidian.exe`nTypora.exe")
  myGui.SetFont("s8")
	myGui.Add("Text", "x160 y100 w150 h20", i18n_local.Gui_note_names_tips)
  myGui.SetFont()

	myGui.Add("Text", "x40 y125 w150 h20", i18n_local.Gui_subtitle_template_name)
	Edit_subtitle_template := myGui.Add("Edit", "x160 y125 w190 h30 +Multi", "字幕：`n{subtitle}")
	Button_srt_to_backlink_mdfile := myGui.Add("Button", "x380 y125 w90 h20", i18n_local.Gui_srt_to_backlink)
	myGui.SetFont("s8")
  myGui.Add("Text", "x40 y160 w115 h20", i18n_local.Gui_subtitle_navigation_single)
  hk_subtitle_previous_once := myGui.Add("Hotkey", "x160 y160 w90 h13", "^j")
  hk_subtitle_current_once := myGui.Add("Hotkey", "x260 y160 w90 h13", "^k")
  hk_subtitle_next_once := myGui.Add("Hotkey", "x360 y160 w90 h13", "^l")
	myGui.Add("Text", "x40 y175 w115 h20", i18n_local.Gui_subtitle_navigation_loop)
  hk_subtitle_previous_loop := myGui.Add("Hotkey", "x160 y175 w90 h13", "^!j")
  hk_subtitle_current_loop := myGui.Add("Hotkey", "x260 y175 w90 h13", "^!k")
  hk_subtitle_next_loop := myGui.Add("Hotkey", "x360 y175 w90 h13", "^!l")
  myGui.SetFont()

	myGui.Add("Text", "x40 y195 w150 h23", i18n_local.Gui_backlink_name)
	Edit_title := myGui.Add("Edit", "x160 y195 w190 h17", "{name} | {time}")

	myGui.Add("Text", "x40 y218 w150 h20", i18n_local.Gui_backlink_template)
	Edit_markdown_template := myGui.Add("Edit", "x160 y218 w190 h40 +Multi", "`n视频：{title}`n")

	myGui.Add("Text", "x40 y265 w110 h40", i18n_local.Gui_image_backlink_tempalte_name)
	Edit_image_template := myGui.Add("Edit", "x160 y265 w190 h50 +Multi", "`n图片:{image}`n视频:{title}`n")

	myGui.Add("Text", "x40 y320 w111", i18n_local.Gui_send_image_delays)
	Edit_send_image_delays := myGui.Add("Edit", "x160 y320 w120 h17")
	myGui.Add("Text", "x288 y320 w22 h20", "ms")

	; =======快捷键=========
  myGui.Add("Text", "x40 y343 w105 h20", i18n_local.Gui_hotkey_backlink)
  hk_backlink := myGui.Add("Hotkey", "x160 y343 w120 h17", "!g")

  myGui.Add("Text", "x40 y365 w105 h20", i18n_local.Gui_hotkey_user_note)
  hk_user_note := myGui.Add("Hotkey", "x160 y365 w120 h17", "!n")

	myGui.Add("Text", "x40 y387 w105 h20", i18n_local.Gui_hotkey_subtitle)
	hk_subtitle := myGui.Add("Hotkey", "x160 y387 w120 h17", "!t")

  myGui.SetFont("s8")
	myGui.Add("Text", "x40 y409 w105", i18n_local.Gui_hotkey_image_and_backlink)
  hk_image_backlink := myGui.Add("Hotkey", "x160 y409 w120 h17", "^!g")
  myGui.Add("Text", "x40 y431 w105 h32", i18n_local.Gui_hotkey_screenshot_tool_hotkeys)
  myGui.SetFont()
  hk_image_screenshot_tool_hotkeys := myGui.Add("Hotkey", "x160 y431 w120 h17", "!a")
  myGui.Add("Text", "x40 y453 w105 h32", i18n_local.Gui_hotkey_image_edit_and_backlink)
  hk_image_edit := myGui.Add("Hotkey", "x160 y453 w120 h17", "!a")
  myGui.SetFont("s8")
  myGui.Add("Text", "x40 y475 w105 h32", i18n_local.Gui_image_edit_detection_time)
  myGui.SetFont()
  Edit_image_edit_detection_time := myGui.Add("Edit", "x160 y475 w120 h17", "20")
  myGui.Add("Text", "x288 y475 w31 h20", "s")

	myGui.Add("Text", "x40 y497 w114 h20", i18n_local.Gui_hotkey_ab_fragment)
	hk_ab_fragment := myGui.Add("Hotkey", "x160 y497 w120 h17", "F1")

  myGui.SetFont("s8")
	myGui.Add("Text", "x40 y519 w98 h20", i18n_local.Gui_hotkey_ab_fragment_detection_delays)
  myGui.SetFont()
	Edit_ab_fragment_detection_delays := myGui.Add("Edit", "x160 y519 w120 h17", "1000")
	myGui.Add("Text", "x288 y519 w31 h20", "ms")

	CheckBox_loop_ab_fragment := myGui.Add("CheckBox", "x160 y541 w120 h20", i18n_local.Gui_is_loop_ab_fragment)

	myGui.Add("Text", "x40 y563 w105 h12", i18n_local.Gui_hotkey_ab_circulation)
	hk_ab_circulation := myGui.Add("Hotkey", "x160 y563 w190 h17")

	; =======其他设置=========
  myGui.SetFont("s8")
	myGui.Add("Text", "x40 y585 w105 h36", i18n_local.Gui_edit_url_protocol)
	Edit_url_protocol := myGui.Add("Edit", "x160 y585 w190 h17", "jv://open")
  myGui.SetFont()

	myGui.Add("Text", "x40 y607 w150 h20", i18n_local.Gui_reduce_time)
	Edit_reduce_time := myGui.Add("Edit", "x160 y607 w120 h17", "0")

	CheckBox_is_stop := myGui.Add("CheckBox", "x160 y629 w69 h17", i18n_local.Gui_is_stop)
	CheckBox_remove_suffix_of_video_file := myGui.Add("CheckBox", "x160 y651 w250 h17", i18n_local.Gui_remove_suffix_of_video_file)
	CheckBox_path_is_encode := myGui.Add("CheckBox", "x160 y673 w120 h17", i18n_local.Gui_is_path_encode)
	CheckBox_bootup := myGui.Add("CheckBox", "x160 y695 w120 h17", i18n_local.Gui_bootup)

	Tab.UseTab()
  myGui.Add("Text", "x332 y725 w150 h12", i18n_local.Gui_current_version ":0.2.7")
  myGui.Add("Link", "x332 y740 w150 h12", i18n_local.Gui_latest_version ":<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">" getLatestVersionFromGithub() "</a>")
	; myGui.Add("Link", "x432 y755 w48 h12", "<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">去下载</a>")

	guiData.myGui := myGui
	guiData.controls.Edit_potplayer := Edit_potplayer
	guiData.controls.Button_potplayer := Button_potplayer
	guiData.controls.Edit_note_app_name := Edit_note_app_name
	guiData.controls.Edit_subtitle_template := Edit_subtitle_template
	guiData.controls.Button_srt_to_backlink_mdfile := Button_srt_to_backlink_mdfile
  guiData.controls.hk_subtitle_previous_once := hk_subtitle_previous_once
  guiData.controls.hk_subtitle_current_once := hk_subtitle_current_once
  guiData.controls.hk_subtitle_next_once := hk_subtitle_next_once
  guiData.controls.hk_subtitle_previous_loop := hk_subtitle_previous_loop
  guiData.controls.hk_subtitle_current_loop := hk_subtitle_current_loop
  guiData.controls.hk_subtitle_next_loop := hk_subtitle_next_loop
	guiData.controls.Edit_title := Edit_title
	guiData.controls.Edit_markdown_template := Edit_markdown_template
	guiData.controls.Edit_image_template := Edit_image_template
	guiData.controls.Edit_send_image_delays := Edit_send_image_delays
	guiData.controls.hk_backlink := hk_backlink
	guiData.controls.hk_user_note := hk_user_note
	guiData.controls.hk_image_backlink := hk_image_backlink
	guiData.controls.hk_image_screenshot_tool_hotkeys := hk_image_screenshot_tool_hotkeys
	guiData.controls.hk_image_edit := hk_image_edit
	guiData.controls.Edit_image_edit_detection_time := Edit_image_edit_detection_time
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