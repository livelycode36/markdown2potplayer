#Requires AutoHotkey v2.0
#Include ../sqlite/SqliteControl.ahk
#Include ../MyTool.ahk

Class Config {
    ; 其他微调设置
    PotplayerPath {
        get => GetKey("path")
        set => UpdateOrIntert("path", Value)
    }
    PotplayerProcessName {
        get => GetNameForPath(this.PotplayerPath)
    }

    IsStop {
        get => GetKey("is_stop")
        set => UpdateOrIntert("is_stop", Value)
    }

    ReduceTime {
        get => GetKey("reduce_time")
        set => UpdateOrIntert("reduce_time", Value)
    }

    NoteAppName {
        get => GetKey("app_name")
        set => UpdateOrIntert("app_name", Value)
    }

    MarkdownPathIsEncode {
        get => GetKey("path_is_encode")
        set => UpdateOrIntert("path_is_encode", Value)
    }

    MarkdownRemoveSuffixOfVideoFile {
        get => GetKey("remove_suffix_of_video_file")
        set => UpdateOrIntert("remove_suffix_of_video_file", Value)
    }

    UrlProtocol {
        get => GetKey("url_protocol")
        set => UpdateOrIntert("url_protocol", Value)
    }

    SendImageDelays {
        get => GetKey("send_image_delays")
        set => UpdateOrIntert("send_image_delays", Value)
    }

    ; ============回链的设置================
    SubtitleTemplate {
        get => GetKey("subtitle_template")
        set => UpdateOrIntert("subtitle_template", Value)
    }
    ; backlink_template
    MarkdownTemplate {
        get => GetKey("template")
        set => UpdateOrIntert("template", Value)
    }

    MarkdownImageTemplate {
        get => GetKey("image_template")
        set => UpdateOrIntert("image_template", Value)
    }

    MarkdownTitle {
        get => GetKey("title")
        set => UpdateOrIntert("title", Value)
    }

    ; ============回链快捷键相关================
    HotkeySubtitle {
        get => GetKey("hotkey_subtitle")
        set => UpdateOrIntert("hotkey_subtitle", Value)
    }
    HotkeyBacklink {
        get => GetKey("hotkey_backlink")
        set => UpdateOrIntert("hotkey_backlink", Value)
    }
    HotkeyIamgeBacklink {
        get => GetKey("hotkey_iamge_backlink")
        set => UpdateOrIntert("hotkey_iamge_backlink", Value)
    }
    HotkeyAbFragment {
        get => GetKey("hotkey_ab_fragment")
        set => UpdateOrIntert("hotkey_ab_fragment", Value)
    }

    AbFragmentDetectionDelays {
        get => GetKey("ab_fragment_detection_delays")
        set => UpdateOrIntert("ab_fragment_detection_delays", Value)
    }

    LoopAbFragment {
        get => GetKey("loop_ab_fragment")
        set => UpdateOrIntert("loop_ab_fragment", Value)
    }
    HotkeyAbCirculation {
        get => GetKey("hotkey_ab_circulation")
        set => UpdateOrIntert("hotkey_ab_circulation", Value)
    }

    ; ============映射Potplayer快捷键相关================
    HotkeyPreviousFrame {
        get => GetKey("hotkey_previous_frame")
        set => UpdateOrIntert("hotkey_previous_frame", Value)
    }
    HotkeyNextFrame {
        get => GetKey("hotkey_next_frame")
        set => UpdateOrIntert("hotkey_next_frame", Value)
    }
    HotkeyForward {
        get => GetKey("hotkey_forward")
        set => UpdateOrIntert("hotkey_forward", Value)
    }
    ForwardSeconds {
        get => GetKey("forward_seconds")
        set => UpdateOrIntert("forward_seconds", Value)
    }
    HotkeyBackward {
        get => GetKey("hotkey_backward")
        set => UpdateOrIntert("hotkey_backward", Value)
    }
    BackwardSeconds {
        get => GetKey("backward_seconds")
        set => UpdateOrIntert("backward_seconds", Value)
    }
    HotkeyPlayOrPause {
        get => GetKey("hotkey_play_or_pause")
        set => UpdateOrIntert("hotkey_play_or_pause", Value)
    }
    HotkeyStop {
        get => GetKey("hotkey_stop")
        set => UpdateOrIntert("hotkey_stop", Value)
    }
}