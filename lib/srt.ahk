#Requires AutoHotkey v2.0
#Include CharsetDetect.ahk

SubtitlesFromSrt(srtPath) {
    if not FileExist(srtPath) {
        MsgBox "The target file:" srtPath " does not exist."
        Exit
    }

    detect := TextEncodingDetect()
    FileEncoding(detect.DetectEncoding(srtPath))

    srtContent := FileRead(srtPath)

    pattern := "(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\R([\s\S]*?)(?:\R\R|\z)"

    ; 查找所有匹配项并转换时间为毫秒
    subtitles_data := []
    pos := 1
    while (pos := RegExMatch(srtContent, pattern, &match, pos)) {
        subtitles_data.Push({
            timeStart: SrtTimeToMs(match[1]),
            timeEnd: SrtTimeToMs(match[2]),
            subtitle: Trim(match[3])
        })
        pos += match.Len
    }
    return subtitles_data
}

; 函数：根据时间戳查找对应的字幕
FindSubtitleByTimestamp(timestamp, subtitles_data) {
    for subtitle_data in subtitles_data {
        if (subtitle_data.timeStart <= timestamp && timestamp <= subtitle_data.timeEnd) {
            return subtitle_data
        }
    }
    return false
}

; 测试
; subtitles := SubtitlesFromSrt("../test.srt")

; for subtitle in subtitles {
;     MsgBox("找到匹配的字幕：`n开始时间: " MsToSrtTime(subtitle.startTime)
;         "`n结束时间: " MsToSrtTime(subtitle.endTime)
;         "`n字幕内容: " subtitle.subtitle)
; }

; userTimestamp := 180000  ; 假设用户输入的时间戳是180秒（180000毫秒）
; result := FindSubtitleByTimestamp(userTimestamp, subtitles)

; if (result) {
;     MsgBox("找到匹配的字幕：`n开始时间: " MsToSrtTime(result.startTime)
;         "`n结束时间: " MsToSrtTime(result.endTime)
;         "`n字幕内容: " result.subtitle)
; } else {
;     MsgBox("未找到匹配的字幕。")
; }

; 辅助函数
; 将毫秒转换回SRT时间格式
MsToSrtTime(ms) {
    hours := Floor(ms / 3600000)
    minutes := Floor((ms - hours * 3600000) / 60000)
    seconds := Floor((ms - hours * 3600000 - minutes * 60000) / 1000)
    milliseconds := ms - hours * 3600000 - minutes * 60000 - seconds * 1000

    return Format("{:02d}:{:02d}:{:02d},{:03d}", hours, minutes, seconds, milliseconds)
}

; SrtTimeToMs 函数定义（与之前相同）
SrtTimeToMs(timeStr) {
    timeParts := StrSplit(timeStr, ":")
    ms := StrSplit(timeParts[3], ",")[2]

    return (Integer(timeParts[1]) * 3600000) +  ; 小时
    (Integer(timeParts[2]) * 60000) +    ; 分钟
    (Integer(StrSplit(timeParts[3], ",")[1]) * 1000) +  ; 秒
    Integer(ms)  ; 毫秒
}