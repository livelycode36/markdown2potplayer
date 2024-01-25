#Requires Autohotkey v2
#Include Gui.ahk ; 加载Gui
#Include ..\BootUp.ahk
#Include ..\..\markdown2potplayer.ahk

InitGui(app_config){
  ; 回显：Potplayer路径
  Edit_potplayer.Value := app_config.PotplayerPath
  ; 点击选择potplayer路径
  Button_potplayer.OnEvent("Click",SelectPotplayerProgram)
  SelectPotplayerProgram(*){
    SelectedFile := FileSelect(1, , "Open a file", "Text Documents (*.exe)")
    if SelectedFile{
      edit_potplayer.Value := SelectedFile
    }
  }
  Button_potplayer.OnEvent("LoseFocus",(*) => app_config.PotplayerPath := edit_potplayer.Value)
  
  ; 回显：减少的时间
  Edit_reduce_time.Value := app_config.ReduceTime
  Edit_reduce_time.OnEvent("LoseFocus",(*) => app_config.ReduceTime := Edit_reduce_time.Value)
  
  ; 回显：笔记软件名称
  Edit_note_app_name.Value := app_config.NoteAppName
  Edit_note_app_name.OnEvent("LoseFocus",(*) => app_config.NoteAppName := Edit_note_app_name.Value)
  
  ; 回显：回链标题
  Edit_title.Value := app_config.MarkdownTitle
  Edit_title.OnEvent("LoseFocus",(*) => app_config.MarkdownTitle := Edit_title.Value)
  
  ; 回显：回链模板
  Edit_makrdown_template.Value := app_config.MarkdownTemplate
  Edit_makrdown_template.OnEvent("LoseFocus",(*) => app_config.MarkdownTemplate := Edit_makrdown_template.Value)
  
  ; 回显：图片回链模板
  Edit_image_tempalte.Value := app_config.MarkdownImageTemplate
  Edit_image_tempalte.OnEvent("LoseFocus",(*) => app_config.MarkdownImageTemplate := Edit_image_tempalte.Value)
  
  ; 回显：是否暂停
  CheckBox_is_stop.Value := app_config.IsStop
  CheckBox_is_stop.OnEvent("Click", (*) => app_config.IsStop := CheckBox_is_stop.Value)
  
  CheckBox_remove_suffix_of_video_file.Value := app_config.MarkdownRemoveSuffixOfVideoFile
  CheckBox_remove_suffix_of_video_file.OnEvent("Click", (*) => app_config.MarkdownRemoveSuffixOfVideoFile := CheckBox_remove_suffix_of_video_file.Value)
  
  ; 回显：路径是否编码
  CheckBox_path_is_encode.Value := app_config.MarkdownPathIsEncode
  checkBox_path_is_encode.OnEvent("Click", (*) => app_config.MarkdownPathIsEncode := checkBox_path_is_encode.Value)
  
  ; 回显: 是否开机启动
  CheckBox_bootup.Value := get_boot_up()
  CheckBox_bootup.OnEvent("Click", (*) => adaptive_bootup())
  
  ; 回显: Url协议
  Edit_url_protocol.Value := app_config.UrlProtocol
  Edit_url_protocol.OnEvent("LoseFocus",(*) => app_config.UrlProtocol := Edit_url_protocol.Value)
  
  ; 回显: 回链快捷键
  hk_backlink.Value := app_config.HotkeyBacklink
  hk_backlink.OnEvent("Change", Update_Hk_Backlink)
  Update_Hk_Backlink(GuiCtrlObj, Info){
    RefreshHotkey(app_config.HotkeyBacklink, GuiCtrlObj.Value, Potplayer2Obsidian)
    app_config.HotkeyBacklink := GuiCtrlObj.Value
  }
  
  ; 回显: 图片+回链快捷键
  hk_image_backlink.Value := app_config.HotkeyIamgeBacklink
  hk_image_backlink.OnEvent("Change", Update_Hk_Image_Backlink)
  Update_Hk_Image_Backlink(GuiCtrlObj, Info){
    RefreshHotkey(app_config.HotkeyIamgeBacklink, GuiCtrlObj.Value, Potplayer2ObsidianImage)
    app_config.HotkeyIamgeBacklink := GuiCtrlObj.Value
  }
  
  ; 回显: ab片段快捷键
  hk_ab_fragment.Value := app_config.HotkeyAbFragment
  hk_ab_fragment.OnEvent("Change", Update_Hk_Ab_Fragment)
  Update_Hk_Ab_Fragment(GuiCtrlObj, Info){
    RefreshHotkey(app_config.HotkeyAbFragment, GuiCtrlObj.Value, Potplayer2ObsidianFragment)
    app_config.HotkeyAbFragment := GuiCtrlObj.Value
  }

  ; 回显: ab循环快捷键
  hk_ab_circulation.Value := app_config.HotkeyAbCirculation
  hk_ab_circulation.OnEvent("Change", Update_Hk_Ab_Circulation)
  Update_Hk_Ab_Circulation(GuiCtrlObj, Info){
    RefreshHotkey(app_config.HotkeyAbCirculation, GuiCtrlObj.Value, Potplayer2ObsidianFragment)
    app_config.HotkeyAbCirculation := GuiCtrlObj.Value
  }

  ; =======界面设置=========
  myGui.OnEvent('Close', (*) => myGui.Hide())
  myGui.OnEvent('Escape', (*) => myGui.Hide())
  myGui.Title := "markdown2potpalyer"
  
  ; =======托盘菜单=========
  myMenu := A_TrayMenu
  
  myMenu.Add("&Open", (*) => myGui.Show("w500 h666"))
  myMenu.Default := "&Open"
  myMenu.ClickCount := 2
  
  myMenu.Rename("&Open" , "打开")
  myMenu.Rename("E&xit" , "退出")
  myMenu.Rename("&Pause Script" , "暂停脚本")
  myMenu.Rename("&Suspend Hotkeys" , "暂停热键")
}