#Requires AutoHotkey v2.0
#SingleInstance force

AppMain()
AppMain(){
    text := ReceivParameter()

    result := DllCall("user32.dll\OpenClipboard")
    If(result = 0){
        MsgBox "OpenClipboard failed"
        return
    }
    DllCall("user32.dll\EmptyClipboard")

    html_code := DllCall("user32.dll\RegisterClipboardFormat", "Ptr", StrBuf("HTML Format","UTF-16"))

    DllCall("user32.dll\SetClipboardData", "UInt", html_code, "Ptr", StrBuf(text,"UTF-8"))
    DllCall("user32.dll\CloseClipboard")

    Send "{LCtrl down}"
    Send "{v}"
    Send "{LCtrl up}"

    ; 复制或转换字符串.
    StrBuf(str, encoding) {
        ; 计算所需的大小并分配缓冲.
        buf := Buffer(StrPut(str, encoding))
        ; 复制或转换字符串.
        StrPut(str, buf, encoding)
        return buf
    }
}
ReceivParameter(){
  ; 如果没有参数
  if (A_Args.Length = 0) {
      return false
  }

  params := ""
  ; 循环遍历参数并显示在控制台
  for n, param in A_Args{
    params .= param " "
  }
  return Trim(params)
}

