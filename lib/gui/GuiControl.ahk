#Requires Autohotkey v2
#Include Gui.ahk ; 加载Gui
#Include ..\BootUp.ahk
#Include ..\..\markdown2potplayer.ahk

InitGui(app_config, potplayer_control) {
  guiData := creationGui()

  ; 回显：Potplayer路径
  guiData.controls.Edit_potplayer.Value := app_config.PotplayerPath
  ; 点击选择potplayer路径
  guiData.controls.Button_potplayer.OnEvent("Click", SelectPotplayerProgram)
  SelectPotplayerProgram(*) {
    SelectedFile := FileSelect(1, , "Open a file", "Text Documents (*.exe)")
    if SelectedFile {
      guiData.controls.edit_potplayer.Value := SelectedFile
    }
  }
  guiData.controls.Button_potplayer.OnEvent("LoseFocus", (*) => app_config.PotplayerPath := guiData.controls.edit_potplayer.Value)

  ; 回显：笔记软件名称
  guiData.controls.Edit_note_app_name.Value := app_config.NoteAppName
  guiData.controls.Edit_note_app_name.OnEvent("LoseFocus", (*) => app_config.NoteAppName := guiData.controls.Edit_note_app_name.Value)

  ; 回显：字幕模板
  guiData.controls.Edit_subtitle_template.Value := app_config.SubtitleTemplate
  guiData.controls.Edit_subtitle_template.OnEvent("LoseFocus", (*) => app_config.SubtitleTemplate := guiData.controls.Edit_subtitle_template.Value)

  ; srt转回链md文件
  guiData.controls.Button_srt_to_backlink_mdfile.OnEvent("Click", SelectSrtFiles)
  SelectSrtFiles(*) {
    SelectedFiles := FileSelect("M3", , "Open a file", "Text Documents (*.srt)")
    if SelectedFiles.Length = 0 {
      return
    }

    InputBoxObj := InputBox("Please enter the video file extension (default: .mp4)", "tips", "", ".mp4")
    videoFileExtension := ".mp4"
    if InputBoxObj.Result = "Cancel"
      return
    else
      videoFileExtension := InputBoxObj.Value

    for FileName in SelectedFiles {
      subtitles := SubtitlesDataFromSrt(FileName)
      if (subtitles) {
        md_content := ""
        for subtitle in subtitles {
          SplitPath FileName, &name, &dir, &ext, &name_no_ext, &drive
          videoFilePath := dir "\" name_no_ext videoFileExtension

          media_data := MediaData(videoFilePath, MillisecondsToTimestamp(subtitle.timeStart), subtitle.subtitle)
          rendered_template := RenderSrtTemplate(app_config.SubtitleTemplate, media_data, subtitle)
          rendered_template := RenderTemplate(rendered_template, media_data) "`r`n`r`n"

          md_content := md_content rendered_template
        }
        if (md_content != "") {
          SplitPath FileName, &name, &dir, &ext, &name_no_ext, &drive
          md_path := dir "\" name_no_ext ".md"

          if (FileExist(md_path)) {
            result := MsgBox("file:" md_path " already exists, overwrite?", , "YesNo")
            if (result == "No")
              return
            FileDelete(md_path)
          }
          FileEncoding("CP0")
          FileAppend(md_content, md_path)

          ToolTip("file: " md_path " generated successfully!")
          SetTimer () => ToolTip(), -2000
        }
      }
    }
  }

  ; 字幕导航
  ; 回显：使用字幕文件定位上一句
  guiData.controls.hk_subtitle_previous_once.Value := app_config.HotkeySubtitlePreviousOnce
  guiData.controls.hk_subtitle_previous_once.OnEvent("Change", Update_Hk_Subtitle_Previous_Once)
  Update_Hk_Subtitle_Previous_Once(GuiCtrlObj, Info) {
    RefreshHotkeyWithoutUp(app_config.HotkeySubtitlePreviousOnce, GuiCtrlObj.Value, (*) => SubtitleFragmentPlay("prev", "single"))
    app_config.HotkeySubtitlePreviousOnce := GuiCtrlObj.Value
  }
  ; 回显：使用字幕文件定位当前句
  guiData.controls.hk_subtitle_current_once.Value := app_config.HotkeySubtitleCurrentOnce
  guiData.controls.hk_subtitle_current_once.OnEvent("Change", Update_Hk_Subtitle_Current_Once)
  Update_Hk_Subtitle_Current_Once(GuiCtrlObj, Info) {
    RefreshHotkeyWithoutUp(app_config.HotkeySubtitleCurrentOnce, GuiCtrlObj.Value, (*) => SubtitleFragmentPlay("current", "single"))
    app_config.HotkeySubtitleCurrentOnce := GuiCtrlObj.Value
  }
  ; 回显：使用字幕文件定位下一句
  guiData.controls.hk_subtitle_next_once.Value := app_config.HotkeySubtitleNextOnce
  guiData.controls.hk_subtitle_next_once.OnEvent("Change", Update_Hk_Subtitle_Next_Once)
  Update_Hk_Subtitle_Next_Once(GuiCtrlObj, Info) {
    RefreshHotkeyWithoutUp(app_config.HotkeySubtitleNextOnce, GuiCtrlObj.Value, (*) => SubtitleFragmentPlay("next", "single"))
    app_config.HotkeySubtitleNextOnce := GuiCtrlObj.Value
  }
  ; 回显：使用字幕文件定位上一句(循环)
  guiData.controls.hk_subtitle_previous_loop.Value := app_config.HotkeySubtitlePreviousLoop
  guiData.controls.hk_subtitle_previous_loop.OnEvent("Change", Update_Hk_Subtitle_Previous_Loop)
  Update_Hk_Subtitle_Previous_Loop(GuiCtrlObj, Info) {
    RefreshHotkeyWithoutUp(app_config.HotkeySubtitlePreviousLoop, GuiCtrlObj.Value, (*) => SubtitleFragmentPlay("prev", "loop"))
    app_config.HotkeySubtitlePreviousLoop := GuiCtrlObj.Value
  }
  ; 回显：使用字幕文件定位当前句(循环)
  guiData.controls.hk_subtitle_current_loop.Value := app_config.HotkeySubtitleCurrentLoop
  guiData.controls.hk_subtitle_current_loop.OnEvent("Change", Update_Hk_Subtitle_Current_Loop)
  Update_Hk_Subtitle_Current_Loop(GuiCtrlObj, Info) {
    RefreshHotkeyWithoutUp(app_config.HotkeySubtitleCurrentLoop, GuiCtrlObj.Value, (*) => SubtitleFragmentPlay("current", "loop"))
    app_config.HotkeySubtitleCurrentLoop := GuiCtrlObj.Value
  }
  ; 回显：使用字幕文件定位下一句(循环)
  guiData.controls.hk_subtitle_next_loop.Value := app_config.HotkeySubtitleNextLoop
  guiData.controls.hk_subtitle_next_loop.OnEvent("Change", Update_Hk_Subtitle_Next_Loop)
  Update_Hk_Subtitle_Next_Loop(GuiCtrlObj, Info) {
    RefreshHotkeyWithoutUp(app_config.HotkeySubtitleNextLoop, GuiCtrlObj.Value, (*) => SubtitleFragmentPlay("next", "loop"))
    app_config.HotkeySubtitleNextLoop := GuiCtrlObj.Value
  }

  ; 回显：回链标题
  guiData.controls.Edit_title.Value := app_config.MarkdownTitle
  guiData.controls.Edit_title.OnEvent("LoseFocus", (*) => app_config.MarkdownTitle := guiData.controls.Edit_title.Value)

  ; 回显：回链模板
  guiData.controls.Edit_markdown_template.Value := app_config.MarkdownTemplate
  guiData.controls.Edit_markdown_template.OnEvent("LoseFocus", (*) => app_config.MarkdownTemplate := guiData.controls.Edit_markdown_template.Value)

  ; 回显：图片回链模板
  guiData.controls.Edit_image_template.Value := app_config.MarkdownImageTemplate
  guiData.controls.Edit_image_template.OnEvent("LoseFocus", (*) => app_config.MarkdownImageTemplate := guiData.controls.Edit_image_template.Value)

  ; 回显：发送图片延迟
  guiData.controls.Edit_send_image_delays.Value := app_config.SendImageDelays
  guiData.controls.Edit_send_image_delays.OnEvent("LoseFocus", (*) => app_config.SendImageDelays := guiData.controls.Edit_send_image_delays.Value)

  ; 回显: 回链快捷键
  guiData.controls.hk_backlink.Value := app_config.HotkeyBacklink
  guiData.controls.hk_backlink.OnEvent("Change", Update_Hk_Backlink)
  Update_Hk_Backlink(GuiCtrlObj, Info) {
    RefreshHotkey(app_config.HotkeyBacklink, GuiCtrlObj.Value, Potplayer2Obsidian)
    app_config.HotkeyBacklink := GuiCtrlObj.Value
  }

  ; 回显: 用户笔记快捷键
  guiData.controls.hk_user_note.Value := app_config.HotkeyUserNote
  guiData.controls.hk_user_note.OnEvent("Change", Update_Hk_UserNote)
  Update_Hk_UserNote(GuiCtrlObj, Info) {
    RefreshHotkey(app_config.HotkeyUserNote, GuiCtrlObj.Value, Potplayer2Obsidian)
    app_config.HotkeyUserNote := GuiCtrlObj.Value
  }

  ; 回显: 图片+回链快捷键
  guiData.controls.hk_image_backlink.Value := app_config.HotkeyIamgeBacklink
  guiData.controls.hk_image_backlink.OnEvent("Change", Update_Hk_Image_Backlink)
  Update_Hk_Image_Backlink(GuiCtrlObj, Info) {
    RefreshHotkey(app_config.HotkeyIamgeBacklink, GuiCtrlObj.Value, Potplayer2ObsidianImage)
    app_config.HotkeyIamgeBacklink := GuiCtrlObj.Value
  }

  ; 回显: 第三方截图工具的快捷键
  guiData.controls.hk_image_screenshot_tool_hotkeys.Value := app_config.HotkeyScreenshotToolHotkeys
  guiData.controls.hk_image_screenshot_tool_hotkeys.OnEvent("Change", Update_Hk_Image_Screenshot_Tool_Hotkeys)
  Update_Hk_Image_Screenshot_Tool_Hotkeys(GuiCtrlObj, Info) {
    app_config.HotkeyScreenshotToolHotkeys := GuiCtrlObj.Value
  }

  ; 回显: 图片编辑快捷键
  guiData.controls.hk_image_edit.Value := app_config.HotkeyImageEdit
  guiData.controls.hk_image_edit.OnEvent("Change", Update_Hk_Image_Edit)
  Update_Hk_Image_Edit(GuiCtrlObj, Info) {
    RefreshHotkey(app_config.HotkeyImageEdit, GuiCtrlObj.Value, Potplayer2ObsidianImage)
    app_config.HotkeyImageEdit := GuiCtrlObj.Value
  }

  ; 回显: 检测图片编辑延迟
  guiData.controls.Edit_image_edit_detection_time.Value := app_config.ImageEditDetectionTime
  guiData.controls.Edit_image_edit_detection_time.OnEvent("Change", Update_Image_Edit_Detection_Time)
  Update_Image_Edit_Detection_Time(GuiCtrlObj, Info) {
    app_config.ImageEditDetectionTime := GuiCtrlObj.Value
  }

  ; 回显: ab片段快捷键
  guiData.controls.hk_ab_fragment.Value := app_config.HotkeyAbFragment
  guiData.controls.hk_ab_fragment.OnEvent("Change", Update_Hk_Ab_Fragment)
  Update_Hk_Ab_Fragment(GuiCtrlObj, Info) {
    RefreshHotkey(app_config.HotkeyAbFragment, GuiCtrlObj.Value, Potplayer2ObsidianFragment)
    app_config.HotkeyAbFragment := GuiCtrlObj.Value
  }

  ; 回显: ab片段检测延迟
  guiData.controls.Edit_ab_fragment_detection_delays.Value := app_config.AbFragmentDetectionDelays
  guiData.controls.Edit_ab_fragment_detection_delays.OnEvent("Change", (*) => app_config.AbFragmentDetectionDelays := guiData.controls.Edit_ab_fragment_detection_delays.Value)

  ; 回显: 是否 循环ab片段
  guiData.controls.CheckBox_loop_ab_fragment.Value := app_config.LoopAbFragment
  guiData.controls.CheckBox_loop_ab_fragment.OnEvent("Click", (*) => app_config.LoopAbFragment := guiData.controls.CheckBox_loop_ab_fragment.Value)

  ; 回显: ab循环快捷键
  guiData.controls.hk_ab_circulation.Value := app_config.HotkeyAbCirculation
  guiData.controls.hk_ab_circulation.OnEvent("Change", Update_Hk_Ab_Circulation)
  Update_Hk_Ab_Circulation(GuiCtrlObj, Info) {
    RefreshHotkey(app_config.HotkeyAbCirculation, GuiCtrlObj.Value, Potplayer2ObsidianFragment)
    app_config.HotkeyAbCirculation := GuiCtrlObj.Value
  }

  ;=================其他设置=================
  ; 回显: Url协议
  guiData.controls.Edit_url_protocol.Value := app_config.UrlProtocol
  guiData.controls.Edit_url_protocol.OnEvent("LoseFocus", (*) => app_config.UrlProtocol := guiData.controls.Edit_url_protocol.Value)

  ; 回显：减少的时间
  guiData.controls.Edit_reduce_time.Value := app_config.ReduceTime
  guiData.controls.Edit_reduce_time.OnEvent("LoseFocus", (*) => app_config.ReduceTime := guiData.controls.Edit_reduce_time.Value)

  ; 回显：是否暂停
  guiData.controls.CheckBox_is_stop.Value := app_config.IsStop
  guiData.controls.CheckBox_is_stop.OnEvent("Click", (*) => app_config.IsStop := guiData.controls.CheckBox_is_stop.Value)

  guiData.controls.CheckBox_remove_suffix_of_video_file.Value := app_config.MarkdownRemoveSuffixOfVideoFile
  guiData.controls.CheckBox_remove_suffix_of_video_file.OnEvent("Click", (*) => app_config.MarkdownRemoveSuffixOfVideoFile := guiData.controls.CheckBox_remove_suffix_of_video_file.Value)

  ; 回显：路径是否编码
  guiData.controls.CheckBox_path_is_encode.Value := app_config.MarkdownPathIsEncode
  guiData.controls.checkBox_path_is_encode.OnEvent("Click", (*) => app_config.MarkdownPathIsEncode := guiData.controls.checkBox_path_is_encode.Value)

  ; 回显: 是否开机启动
  guiData.controls.CheckBox_bootup.Value := get_boot_up()
  guiData.controls.CheckBox_bootup.OnEvent("Click", (*) => adaptive_bootup())
}