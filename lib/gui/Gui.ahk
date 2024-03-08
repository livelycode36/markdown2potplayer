
#Requires Autohotkey v2
#Include i18n\I18n.ahk
;AutoGUI 2.5.8 
;Auto-GUI-v2 credit to Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter credit to github.com/mmikeww/AHK-v2-script-converter

i18n_local := I18n(A_WorkingDir "\lib\gui\i18n")

myGui := Gui()
Tab := myGui.Add("Tab3", "x0 y0 w503 h640", [i18n_local.Gui_Tab_backlink_setting, i18n_local.Gui_Tab_potplayer_hotkey_setting])
Tab.UseTab(1)

myGui.Add("Text", "x56 y24 w132 h23", i18n_local.Gui_potplayer_path)
Edit_potplayer := myGui.Add("Edit", "x160 y22 w215 h25", "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe")
Button_potplayer := myGui.Add("Button", "x384 y22 w103 h23", i18n_local.Gui_choose_potplayer)

myGui.Add("Text", "x56 y48 h23", i18n_local.Gui_reduce_time)
Edit_reduce_time := myGui.Add("Edit", "x160 y48 w120 h21", "0")

myGui.Add("Text", "x56 y80 w109 h23", i18n_local.Gui_note_names)
Edit_note_app_name := myGui.Add("Edit", "x160 y80 w162 h63 +Multi", "Obsidian.exe`nTypora.exe")
myGui.Add("Text", "x160 y152 w123 h23", i18n_local.Gui_note_names_tips)

myGui.Add("Text", "x56 y184 w63 h23", i18n_local.Gui_backlink_name)
Edit_title := myGui.Add("Edit", "x160 y184 w148 h21", "{name} | {time}")

myGui.Add("Text", "x56 y216 w51 h23", i18n_local.Gui_backlink_template)
Edit_markdown_template := myGui.Add("Edit", "x160 y216 w149 h60 +Multi", "`n视频：{title}`n")

myGui.Add("Text", "x56 y288 w77 h23", i18n_local.Gui_image_backlink_tempalte_name)
Edit_image_template := myGui.Add("Edit", "x160 y288 w151 h79 +Multi", "`n图片:{image}`n视频:{title}`n")

CheckBox_is_stop := myGui.Add("CheckBox", "x160 y368 w69 h23", i18n_local.Gui_is_stop)
CheckBox_remove_suffix_of_video_file := myGui.Add("CheckBox", "x160 y388 w150 h23", i18n_local.Gui_remove_suffix_of_video_file)
CheckBox_path_is_encode := myGui.Add("CheckBox", "x160 y416 w120 h23", i18n_local.Gui_is_path_encode)
CheckBox_bootup := myGui.Add("CheckBox", "x160 y440 w120 h23", i18n_local.Gui_bootup)

myGui.Add("Text", "x56 y469 w105 h36", i18n_local.Gui_edit_url_protocol)
Edit_url_protocol := myGui.Add("Edit", "x160 y470 w146 h21", "jv://open")

myGui.Add("Text", "x56 y506 w105 h23", i18n_local.Gui_hotkey_backlink)
hk_backlink := myGui.Add("Hotkey", "x160 y504 w155 h21", "!g")

myGui.Add("Text", "x56 y538 w105 h23", i18n_local.Gui_hotkey_image_and_backlink)
hk_image_backlink := myGui.Add("Hotkey", "x160 y536 w156 h21", "^!g")

myGui.Add("Text", "x56 y566 w105", i18n_local.Gui_hotkey_ab_fragment)
hk_ab_fragment := myGui.Add("Hotkey", "x160 y562 w156 h21","F1")
CheckBox_loop_ab_fragment := myGui.Add("CheckBox", "x160 y584 w120 h23", i18n_local.Gui_is_loop_ab_fragment)

myGui.Add("Text", "x56 y610 w105", i18n_local.Gui_hotkey_ab_circulation)
hk_ab_circulation := myGui.Add("Hotkey", "x160 y609 w156 h21")

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
myGui.Add("Link", "x404 y640", "<a href=`"https://github.com/livelycode36/markdown2potplayer/releases/latest`">" i18n_local.Gui_check_update "</a>")
