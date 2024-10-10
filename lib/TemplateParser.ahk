#Requires AutoHotkey v2.0

/**
 * 使用指定的分隔符将字符串分成子字符串数组
 * 例如：{image}123123{image}{image}456456{image}，以{image}分割，转为数组 => ["{image}", "123123", "{image}", "{image}", "456456", "{image}"]
 * 
 * @param template 用户模板
 * @param identifier 分隔符
 */
TemplateConvertedToTemplates(template, delimiter) {
  result := []
  searchIndex := 1

  while (true) {
    delimiterIndex := InStr(template, delimiter, false, searchIndex)
    ; 情况1: 搜索结束
    if (delimiterIndex = 0) {
      if (searchIndex > 0 && searchIndex < StrLen(template)) {
        result.Push(SubStr(template, searchIndex))
      }
      break
    }
    ; 情况2: 搜索到 identifier自身
    if (delimiterIndex == searchIndex) {
      result.Push(delimiter)
    } else {
      ; 情况3：正常分割
      result.Push(SubStr(template, searchIndex, delimiterIndex - searchIndex))
      result.Push(delimiter)
    }

    ; 移动游标
    searchIndex := delimiterIndex + StrLen(delimiter)
  }

  return result
}

; test
; testString := "{image}123123{image}{image}456456{image}"
; delimiterString := "{image}"
; result := TemplateConvertedToTemplates(testString, delimiterString)

; for index, item in result
;   MsgBox("Item " . index . ": " . item)
