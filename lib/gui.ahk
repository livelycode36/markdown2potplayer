#Requires Autohotkey v2
#Include sqlite/SqliteControl.ahk
#Include ../markdown2potplayer.ahk
#Include BootUp.ahk

myGui := Gui()

myGui.Add("Text", "x24 y16 w132 h23", "potplayer播放器的路径")
Edit_potplayer := myGui.AddEdit("x160 y16 w215 h25", GetKey("path"))
Button_potplayer := myGui.AddButton("x384 y16 w103 h23", "选择potplayer")
Button_potplayer.OnEvent("Click",SelectPotplayerProgram)
SelectPotplayerProgram(*){
  SelectedFile := FileSelect(1, , "Open a file", "Text Documents (*.exe)")
  if SelectedFile{
    edit_potplayer.Value := SelectedFile
  }
}
Button_potplayer.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("path",edit_potplayer.Value))

myGui.Add("Text", "x91 y48 w63 h23", "减少的时间")
Edit_reduce_time := myGui.AddEdit( "x160 y48 w120 h21", GetKey("reduce_time"))
Edit_reduce_time.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("reduce_time",Edit_reduce_time.Value))

myGui.Add("Text", "x40 y80 w109 h23 +0x200", "笔记软件的程序名称")
Edit_note_app_name := myGui.AddEdit("x160 y80 w162 h63 +Multi", GetKey("app_name"))
myGui.Add("Text", "x160 y152 w123 h23", "多个笔记软件每行一个")
Edit_note_app_name.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("app_name",Edit_note_app_name.Value))

myGui.Add("Text", "x88 y184 w63 h23", "回链的名称")
Edit_title := myGui.AddEdit("x160 y184 w148 h21", GetKey("title"))
Edit_title.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("title",Edit_title.Value))

myGui.Add("Text", "x104 y216 w51 h23", "回链模板")
Edit_makrdown_template := myGui.AddEdit("x160 y216 w149 h60 +Multi", GetKey("template"))
Edit_makrdown_template.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("template",Edit_makrdown_template.Value))

myGui.Add("Text", "x80 y288 w77 h23", "图片回链模板")
Edit_image_tempalte := myGui.AddEdit("x160 y288 w151 h79 +Multi", GetKey("image_template"))
Edit_image_tempalte.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("image_template",Edit_image_tempalte.Value))

CheckBox_is_stop := myGui.AddCheckbox("x160 y368 w69 h23", "是否暂停")
CheckBox_is_stop.Value := GetKey("is_stop")
CheckBox_is_stop.OnEvent("Click", (*) => UpdateOrIntertAndRefreshConfig("is_stop",CheckBox_is_stop.Value))

CheckBox_remove_suffix_of_video_file := myGui.AddCheckbox("x160 y392 w156 h23", "本地视频移除文件后缀名")
CheckBox_remove_suffix_of_video_file.Value := GetKey("remove_suffix_of_video_file")
CheckBox_remove_suffix_of_video_file.OnEvent("Click", (*) => UpdateOrIntertAndRefreshConfig("remove_suffix_of_video_file",CheckBox_remove_suffix_of_video_file.Value))

CheckBox_path_is_encode := myGui.AddCheckbox("x160 y416 w120 h23", "路径是否编码")
CheckBox_path_is_encode.Value := GetKey("path_is_encode")
checkBox_path_is_encode.OnEvent("Click", (*) => UpdateOrIntertAndRefreshConfig("path_is_encode",checkBox_path_is_encode.Value))

CheckBox_bootup := myGui.Add("CheckBox", "x160 y440 w120 h23", "开机启动")
CheckBox_bootup.Value := get_boot_up()
CheckBox_bootup.OnEvent("Click", (*) => adaptive_bootup())

myGui.Add("Text", "x56 y469 w100 h36", "修改协议【谨慎】`n此项重启生效")
Edit_url_protocol := myGui.AddEdit("x160 y469 w146 h21", GetKey("url_protocol"))
Edit_url_protocol.OnEvent("LoseFocus",(*) => UpdateOrIntertAndRefreshConfig("url_protocol",Edit_url_protocol.Value))

myGui.Add("Text", "x93 y506 w63 h23 +0x200", "回链快捷键")
hk_backlink := myGui.Add("Hotkey", "x160 y506 w155 h21", GetKey("hotkey_backlink"))
hk_backlink.OnEvent("Change", Update_Hk_Backlink)
Update_Hk_Backlink(*){
  RefreshHotkey(GetKey("hotkey_backlink"),hk_backlink.Value,Potplayer2Obsidian)
  UpdateOrIntertAndRefreshConfig("hotkey_backlink",hk_backlink.Value)
}

myGui.Add("Text", "x72 y538 w84 h23 +0x200", "图片+回链快捷键")
hk_image_backlink := myGui.Add("Hotkey", "x160 y538 w156 h21", GetKey("hotkey_iamge_backlink"))
hk_image_backlink.OnEvent("Change", Update_Hk_Image_Backlink)
Update_Hk_Image_Backlink(*){
  RefreshHotkey(GetKey("hotkey_iamge_backlink"),hk_image_backlink.Value,Potplayer2ObsidianImage)
  UpdateOrIntertAndRefreshConfig("hotkey_iamge_backlink",hk_image_backlink.Value)
}

myGui.Add("Link", "x434 y561 w51 h17", "<a href=`"https://github.com/livelycode36/markdown2potplayer`">查看更新</a>")
myGui.OnEvent('Close', (*) => myGui.Hide())
myGui.OnEvent('Escape', (*) => myGui.Hide())
myGui.Title := "markdown2potpalyer"

; =======托盘菜单=========
myMenu := A_TrayMenu

myMenu.Add("&Open", (*) => myGui.Show("w500 h590"))
myMenu.Default := "&Open"
myMenu.ClickCount := 2

myMenu.Rename("&Open" , "打开")
myMenu.Rename("E&xit" , "退出")
myMenu.Rename("&Pause Script" , "暂停脚本")
myMenu.Rename("&Suspend Hotkeys" , "暂停热键")
