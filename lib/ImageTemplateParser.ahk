#Requires AutoHotkey v2.0

; 将用户的图像模板，例如：{image}{enter}title:{title}，以{image}分割，转为数组 => ["{image}","{enter}title:{title}"]
ImageTemplateConvertedToImagesTemplates(image_template){
    if (image_template == "{image}"){
      templates := ["{image}"]
      return templates
    } else {
      tempaltes := StrSplit(image_template, "{image}")
  
      For index, value in tempaltes{
        ; 当{image}在开头 及 末尾时，该项为null，所以它(null等于{images})本身就是{images}，不需要补{images}
        if (value == ""){
          continue
        }

        ; 修正：在模板的最后一项为【正常数据】的情况：
        ; 最后一项不需要补{image}，所以跳过
        if (index == tempaltes.Length && value != ""){
          continue
        }

        ; 修正：在模板的最后一项为{image}的情况：
        ; 因为是以{image}分割，所以最后一项为{image}时，值为null，当最后一项为{image}时，它的上一项也会补为{image}，所以 跳过 最后一项的上一项补{image}
        if ((index == tempaltes.Length - 1) && (tempaltes[tempaltes.Length] == "")){
            continue
        }
    
        ; 将非{image}的项后，加上{image}。因为是以{image}分割，所以给个数组项的后一项，都是{image}，将{imgae}给它补回去
        if (value != "{image}"){
          tempaltes.InsertAt(index + 1, "{image}")
        }
      }

      ; 修正：当{image}在开头 及 末尾时，该项为null
      For index, value in tempaltes{
        if (value == "" && index == 1){
            tempaltes[1] := "{image}"
        }

        if (value == "" && index == tempaltes.Length){
            tempaltes[tempaltes.Length] := "{image}"
        }
      }

      return tempaltes
    }
}