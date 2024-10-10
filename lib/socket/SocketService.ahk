#Requires AutoHotkey v2.0

#Include Socket.ahk

InitServer() {
    sock := winsock("server", callback, "IPV4")
    sock.Bind("0.0.0.0", 33660)
    sock.Listen()

    callback(sock, event, err) {
        if (sock.name = "server") || instr(sock.name, "serving-") {
            if (event = "accept") {
                sock.Accept(&addr, &newsock) ; pass &addr param to extract addr of connected machine
            } else if (event = "close") {
            } else if (event = "read") {
                If !(buf := sock.Recv()).size
                    return

                ; 返回html
                html_body := '<h1>open potplayer...</h1>'
                httpResponse := "HTTP/1.1 200 0K`r`n"
                    . "Content-Type: text/html; charset=UTF-8`r`n"
                    . "Content-Length: " StrLen(html_body) "`r`n"
                    . "`r`n"
                httpResponse := httpResponse html_body
                strbuf := Buffer(StrPut(httpResponse, "UTF-8"))
                StrPut(httpResponse, strbuf, "UTF-8")
                sock.Send(strbuf)
                sock.ConnectFinish()

                ; 得到回链
                request := strget(buf, "UTF-8")
                RegExMatch(request, "GET /(.+?) HTTP/1.1", &match)
                if (match == "") {
                    return
                }
                backlink := match[1]
                if (!InStr(backlink, "path=")) {
                    return
                }

                ; 打开potplayer
                Run(backlink)
                ; 关闭 notion打开的网页标签
                Send "^w"
            }
        }
    }
}