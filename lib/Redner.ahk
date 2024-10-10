#Requires AutoHotkey v2.0

RenderTemplate(backlink_template, media_data) {
    backlink_template := RenderSrtTemplate(backlink_template, media_data, "")

    markdown_link_data := RenderNameAndTimeAndLink(app_config, media_data)

    if (InStr(backlink_template, "{title}") != 0) {
        rendered_link := RenderTitle(app_config, markdown_link_data)
        backlink_template := StrReplace(backlink_template, "{title}", rendered_link)
    }

    if (InStr(backlink_template, "{link}") != 0) {
        backlink_template := StrReplace(backlink_template, "{link}", markdown_link_data.link)
    }

    if (InStr(backlink_template, "{name}") != 0) {
        backlink_template := StrReplace(backlink_template, "{name}", media_data.Path)
    }

    if (InStr(backlink_template, "{time}") != 0) {
        backlink_template := StrReplace(backlink_template, "{time}", media_data.Time)
    }

    if (InStr(backlink_template, "{subtitle}") != 0) {
        backlink_template := RenderSubtitleTemplate(backlink_template, media_data)
    }

    return backlink_template
}

RenderSubtitleTemplate(target_string, media_data) {
    if (InStr(target_string, "{subtitle}") != 0) {
        if (media_data.Subtitle == "") {
            media_data.Subtitle := GetMediaSubtitle()
        }
        target_string := StrReplace(target_string, "{subtitle}", media_data.Subtitle)
    }
    return target_string
}

RenderTitle(app_config, markdown_link_data) {
    result_link := ""
    ; 生成word链接
    if (IsWordProgram()) {
        result_link := "<a href='http://127.0.0.1:33660/" markdown_link_data.link "'>" markdown_link_data.title "</a>"

    } else {
        ; 生成MarkDown链接
        result_link := GenerateMarkdownLink(markdown_link_data.title, markdown_link_data.link)
    }
    return result_link
}

RenderSrtTemplate(backlink_template, media_data, subtitle_data) {
    if (InStr(backlink_template, '{subtitleTimeRange}') != 0 ||
        InStr(backlink_template, '{subtitleTimeStart}') != 0 ||
        InStr(backlink_template, '{subtitleTimeEnd}') != 0 ||
        InStr(backlink_template, '{subtitleOrigin}') != 0) {

        if (!subtitle_data) {
            SplitPath media_data.Path, &name, &dir, &ext, &name_no_ext, &drive
            subtitles_data := SubtitlesFromSrt(dir "/" name_no_ext ".srt")
            subtitle_data := FindSubtitleByTimestamp(GetMediaTimeMilliseconds() + 1, subtitles_data)
        }

        if (subtitle_data) {
            if (InStr(backlink_template, '{subtitleTimeRange}') != 0) {
                ; 1. 修改渲染回链的 link 中的 time
                media_data.Time := MilliSecondToTimestamp(subtitle_data.timeStart + 1) "-" MilliSecondToTimestamp(subtitle_data.timeEnd - 1)
                ; 2. 修改渲染回链的 title 中的 time
                backlink_template := StrReplace(backlink_template, "{subtitleTimeRange}", RemoveMillisecondFormTimestamp(media_data.Time))
            } else if (InStr(backlink_template, '{subtitleTimeStart}') != 0) {
                media_data.Time := MilliSecondToTimestamp(subtitle_data.timeStart + 1)
                backlink_template := StrReplace(backlink_template, "{subtitleTimeStart}", RemoveMillisecondFormTimestamp(media_data.Time))
            } else if (InStr(backlink_template, '{subtitleTimeEnd}') != 0) {
                media_data.Time := MilliSecondToTimestamp(subtitle_data.timeEnd - 1)
                backlink_template := StrReplace(backlink_template, "{subtitleTimeEnd}", RemoveMillisecondFormTimestamp(media_data.Time))
            }

            if (InStr(backlink_template, '{subtitleOrigin}') != 0) {
                backlink_template := StrReplace(backlink_template, "{subtitleOrigin}", subtitle_data.subtitle)
            }

            return backlink_template
        }
    }
    return backlink_template
}

; // [用户想要的标题格式](mk-potplayer://open?path=1&aaa=123&time=456)
RenderNameAndTimeAndLink(app_config, media_data) {
    ; B站的视频
    if (InStr(media_data.Path, "https://www.bilibili.com/video/")) {
        ; 正常播放的情况
        name := StrReplace(GetPotplayerTitle(app_config.PotplayerProcessName), " - PotPlayer", "")

        ; 视频没有播放，已经停止的情况，不是暂停是停止
        if name == "PotPlayer" {
            name := GetFileNameInPath(media_data.Path)
        }
    } else {
        ; 本地视频
        name := GetFileNameInPath(media_data.Path)
    }
    ; 渲染 title
    title := app_config.MarkdownTitle
    title := StrReplace(title, "{name}", name)
    title := StrReplace(title, "{time}", media_data.Time)
    ; 渲染 title 中的 字幕模板
    title := RenderSubtitleTemplate(title, media_data)

    markdown2potplayer_link := GenerateMarkdownLink2PotplayerLink(app_config, media_data)

    result := {}
    result.title := title
    result.link := markdown2potplayer_link
    return result
}

GenerateMarkdownLink(markdown_title, markdown_link) {
    if (IsNotionProgram()) {
        result := "[" markdown_title "](http://127.0.0.1:33660/" markdown_link ")"
    } else {
        result := "[" markdown_title "](" markdown_link ")"
    }
    return result
}

GenerateMarkdownLink2PotplayerLink(app_config, media_data) {
    return app_config.UrlProtocol "?path=" ProcessUrl(media_data.Path) "&time=" media_data.Time
}

RenderImage(markdown_image_template, media_data, image) {
    identifier := "{image}"
    image_templates := TemplateConvertedToTemplates(markdown_image_template, identifier)
    For index, image_template in image_templates {
        if (image_template == identifier) {
            SendImage2NoteApp(image)
        } else {
            rendered_template := RenderTemplate(image_template, media_data)
            if (IsWordProgram() && InStr(image_template, "{title}")) {
                SendText2wordApp(rendered_template)
            } else {
                SendText2NoteApp(rendered_template)
            }
        }
    }
}