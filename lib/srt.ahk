#Requires AutoHotkey v2.0
#Include CharsetDetect.ahk

SubtitlesDataFromSrt(srtPath) {
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

; 获取当前/上一/下一字幕片段
; mode: "current" | "prev" | "next"
GetSubtitleSegmentByTimestamp(subtitles_data, milliseconds, mode := "current") {
    if subtitles_data.Length = 0 {
        return false
    }
    
    ; 初始化索引变量
    idx := 0
    
    ; 遍历字幕数据，查找时间戳对应的位置
    for i, subtitle in subtitles_data {
        ; 如果时间戳在当前字幕的时间范围内
        if (subtitle.timeStart <= milliseconds && milliseconds <= subtitle.timeEnd) {
            idx := i  ; 记录当前字幕索引
            break
        }
        ; 如果时间戳小于当前字幕的开始时间（说明时间戳在两个字幕之间）
        if (milliseconds < subtitle.timeStart) {
            idx := i  ; 记录当前字幕索引（时间戳位于前一个字幕之后）
            break
        }
    }
    
    ; 处理时间戳在所有字幕之前的情况
    if (idx = 0) {
        ; timestamp 在所有字幕之前
        if (mode = "current" || mode = "next")
            return subtitles_data[1]  ; 返回第一个字幕
        else
            return false  ; prev模式下返回false
    }
    
    ; 根据不同模式处理
    if (mode = "current") {
        ; 当前模式：返回包含时间戳的字幕，或最接近的前一个字幕
        if (subtitles_data[idx].timeStart <= milliseconds && milliseconds <= subtitles_data[idx].timeEnd) {
            return subtitles_data[idx]  ; 时间戳在当前字幕范围内
        } else if (idx > 1) {
            return subtitles_data[idx-1]  ; 返回前一个字幕
        } else {
            return subtitles_data[1]  ; 如果是第一个字幕，返回第一个
        }
    } else if (mode = "prev") {
        ; 前一个模式：返回前一个字幕
        if (idx = 1) {
            return subtitles_data[1]  ; 如果已经是第一个，返回第一个
        } else {
            return subtitles_data[idx-1]  ; 返回前一个字幕
        }
    } else if (mode = "next") {
        ; 下一个模式：返回下一个字幕
        if (idx >= subtitles_data.Length) {
            return subtitles_data[subtitles_data.Length]  ; 如果已经是最后一个，返回最后一个
        } else {
            return subtitles_data[idx+1]  ; 返回下一个字幕
        }
    }
    
    return false  ; 默认返回false
}