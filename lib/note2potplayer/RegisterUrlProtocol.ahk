#Requires AutoHotkey v2.0

; 注册协议
RegisterUrlProtocol(url_protocol){
    protocol_name := GetUrlProtocolName(url_protocol)
    RegistrationUrlProtocol(protocol_name)
}

GetUrlProtocolName(url_protocol){
    index_of := InStr(url_protocol, ":")
    if (index_of = 0){
        MsgBox "error: protocol no ':' found"
        Exit
    }
    result := SubStr(url_protocol, 1,index_of-1)
    return result
}
  
RegistrationUrlProtocol(protocol_name){
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name
    RegWrite "", "REG_SZ", "HKEY_CURRENT_USER\Software\Classes\" protocol_name, "URL Protocol"
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell"
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell\open"
    RegCreateKey "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell\open\command"
    RegWrite A_ScriptDir "\lib\note2potplayer\note2potplayer.exe `"%1`"", "REG_SZ", "HKEY_CURRENT_USER\Software\Classes\" protocol_name "\shell\open\command"
}