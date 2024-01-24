#Requires AutoHotkey v2.0
#Include ../sqlite/SqliteControl.ahk
#Include ../MyTool.ahk

Class Config{
    PotplayerPath{
        get => GetKey("path")
        set => UpdateOrIntert("path",Value)
    }
    PotplayerProcessName{
        get => GetNameForPath(this.PotplayerPath)
    }

    IsStop{
        get => GetKey("is_stop")
        set => UpdateOrIntert("is_stop",Value)
    }

    ReduceTime{
        get => GetKey("reduce_time")
        set => UpdateOrIntert("reduce_time",Value)
    }

    NoteAppName{
        get => GetKey("app_name")
        set => UpdateOrIntert("app_name",Value)
    }
    
    MarkdownTemplate{
        get => GetKey("template")
        set => UpdateOrIntert("template",Value)
    }

    MarkdownImageTemplate{
        get => GetKey("image_template")
        set => UpdateOrIntert("image_template",Value)
    }

    MarkdownTitle{
        get => GetKey("title")
        set => UpdateOrIntert("title",Value)
    }

    MarkdownPathIsEncode{
        get => GetKey("path_is_encode")
        set => UpdateOrIntert("path_is_encode",Value)
    }

    MarkdownRemoveSuffixOfVideoFile{
        get => GetKey("remove_suffix_of_video_file")
        set => UpdateOrIntert("remove_suffix_of_video_file",Value)
    }

    UrlProtocol{
        get => GetKey("url_protocol")
        set => UpdateOrIntert("url_protocol",Value)
    }

    HotkeyBacklink{
        get => GetKey("hotkey_backlink") " Up"
        set => UpdateOrIntert("hotkey_backlink",Value)
    }

    HkIamgeBacklink{
        get => GetKey("hotkey_iamge_backlink") " Up"
        set => UpdateOrIntert("hotkey_iamge_backlink",Value)
    }
}