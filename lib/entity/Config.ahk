#Requires AutoHotkey v2.0
#Include ../sqlite/SqliteControl.ahk
#Include ../MyTool.ahk

Class Config {
    ; 其他微调设置
    PotplayerPath {
        get => GetKey("path")
        set => UpdateOrInsertConfig("path", Value)
    }
    PotplayerProcessName {
        get => GetNameForPath(this.PotplayerPath)
    }

    IsStop {
        get => GetKey("is_stop")
        set => UpdateOrInsertConfig("is_stop", Value)
    }

    ReduceTime {
        get => GetKey("reduce_time")
        set => UpdateOrInsertConfig("reduce_time", Value)
    }

    NoteAppName {
        get => GetKey("app_name")
        set => UpdateOrInsertConfig("app_name", Value)
    }

    MarkdownPathIsEncode {
        get => GetKey("path_is_encode")
        set => UpdateOrInsertConfig("path_is_encode", Value)
    }

    MarkdownRemoveSuffixOfVideoFile {
        get => GetKey("remove_suffix_of_video_file")
        set => UpdateOrInsertConfig("remove_suffix_of_video_file", Value)
    }

    UrlProtocol {
        get => GetKey("url_protocol")
        set => UpdateOrInsertConfig("url_protocol", Value)
    }

    SendImageDelays {
        get => GetKey("send_image_delays")
        set => UpdateOrInsertConfig("send_image_delays", Value)
    }

    ; ============回链的设置================
    SubtitleTemplate {
        get => GetKey("subtitle_template")
        set => UpdateOrInsertConfig("subtitle_template", Value)
    }
    ; backlink_template
    MarkdownTemplate {
        get => GetKey("template")
        set => UpdateOrInsertConfig("template", Value)
    }

    MarkdownImageTemplate {
        get => GetKey("image_template")
        set => UpdateOrInsertConfig("image_template", Value)
    }

    MarkdownTitle {
        get => GetKey("title")
        set => UpdateOrInsertConfig("title", Value)
    }

    ; ============回链快捷键相关================
    HotkeySubtitle {
        get => GetKey("hotkey_subtitle")
        set => UpdateOrInsertConfig("hotkey_subtitle", Value)
    }
    HotkeySubtitlePreviousOnce{
        get => GetKey("hotkey_subtitle_previous_once")
        set => UpdateOrInsertConfig("hotkey_subtitle_previous_once", Value)
    }
    HotkeySubtitleCurrentOnce {
        get => GetKey("hotkey_subtitle_current_once")
        set => UpdateOrInsertConfig("hotkey_subtitle_current_once", Value)
    }
    HotkeySubtitleNextOnce {
        get => GetKey("hotkey_subtitle_next_once")
        set => UpdateOrInsertConfig("hotkey_subtitle_next_once", Value)
    }
    HotkeySubtitlePreviousLoop {
        get => GetKey("hotkey_subtitle_previous_loop")
        set => UpdateOrInsertConfig("hotkey_subtitle_previous_loop", Value)
    }
    HotkeySubtitleCurrentLoop {
        get => GetKey("hotkey_subtitle_current_loop")
        set => UpdateOrInsertConfig("hotkey_subtitle_current_loop", Value)
    }
    HotkeySubtitleNextLoop {
        get => GetKey("hotkey_subtitle_next_loop")
        set => UpdateOrInsertConfig("hotkey_subtitle_next_loop", Value)
    }
    HotkeyUserNote  {
      get => GetKey("hotkey_user_note")
      set => UpdateOrInsertConfig("hotkey_user_note", Value)
    }
    HotkeyBacklink {
        get => GetKey("hotkey_backlink")
        set => UpdateOrInsertConfig("hotkey_backlink", Value)
    }
    HotkeyIamgeBacklink {
        get => GetKey("hotkey_iamge_backlink")
        set => UpdateOrInsertConfig("hotkey_iamge_backlink", Value)
    }
    HotkeyScreenshotToolHotkeys {
      get => GetKey("hotkey_image_screenshot_tool_hotkeys")
      set => UpdateOrInsertConfig("hotkey_image_screenshot_tool_hotkeys", Value)
    }
    HotkeyImageEdit {
      get => GetKey("hotkey_image_edit")
      set => UpdateOrInsertConfig("hotkey_image_edit", Value)
    }
    ImageEditDetectionTime {
      get => GetKey("image_edit_detection_time")
      set => UpdateOrInsertConfig("image_edit_detection_time", Value)
    }
    HotkeyAbFragment {
        get => GetKey("hotkey_ab_fragment")
        set => UpdateOrInsertConfig("hotkey_ab_fragment", Value)
    }

    AbFragmentDetectionDelays {
        get => GetKey("ab_fragment_detection_delays")
        set => UpdateOrInsertConfig("ab_fragment_detection_delays", Value)
    }

    LoopAbFragment {
        get => GetKey("loop_ab_fragment")
        set => UpdateOrInsertConfig("loop_ab_fragment", Value)
    }
    HotkeyAbCirculation {
        get => GetKey("hotkey_ab_circulation")
        set => UpdateOrInsertConfig("hotkey_ab_circulation", Value)
    }
}