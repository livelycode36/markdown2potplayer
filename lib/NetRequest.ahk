#Requires AutoHotkey v2.0
#Include "./JSON.ahk"

/**
 * From: https://github.com/dcazrael/autohotkey_libraries
 * Allows us to requests data from the web.
 * You can use either WinHttpRequests or create a com instance of a browser
 * 
 * @Parameters
 *    url      - [String] expects URL
 * 
 * @Remarks
 *    For better output control JSON.ahk has been included.
 *    This is by no means necessary, but it's easier dealing with 
 *    JSON objects, than working with the string responses.
 */
Class NetRequest {
    static request_header := Map("GET", "application/json", "POST", "application/x-www-form-urlencoded;charset=utf-8")
    static method := Map("GET", "GET", "POST", "POST")
    status := "instantiated"

    __New() {
    }

    /**
     * Sets the host and endpoint for the API you want to use.
     *
     * @Parameters
     *    host        - [String] expects valid URL
     *    endpoint    - [String] valid endpoint for API you want to hit
     *                            e.g., /rest/asset/v1/programs.json
     *
     * @Return
     *    Nothing
     */
    apiSetup(host, endpoint) {
        this.host := host
        this.endpoint := endpoint
    }

    /**
     * Used for requesting data from APIs.
     * Returns the response text from the HTTP request.
     *
     * @Parameters
     *    method        - [String] "GET" or "POST" (default: "GET")
     *    body          - [String] Data for POST requests (optional for GET)
     *    params        - [Array] Parameters for the API call. 
     *                          Strings without "=" are treated as path segments (e.g., "id").
     *                          Strings with "=" are treated as query parameters (e.g., "name=Alf").
     *
     * @Return
     *    [Object] JSON Object or [String] error message or [Boolean] false on failure.
     */
    apiRequest(method := "GET", body := "", params*) {
        local parameters := ""
        local start_query := true
        if params.Length > 0 {
            for parm in params {
                if (!InStr(parm, "=")) {
                    parameters .= "/" . parm
                } else {
                    parameters .= (start_query ? "?" : "&") . parm
                    start_query := false
                }
            }
        }

        request := this.createRequestObj(this.host . "/" . this.endpoint . parameters, method, body)
        if (!IsObject(request)) { ; Could be an error string or false
            return request
        }
        
        try {
            ; The following line calls JSON.Load(). If you see a warning like "This local variable appears to never be assigned a value. Specifically: JSON",
            ; it likely means that the JSON.ahk library is not v2 compatible, or does not correctly define a class named 'JSON' with a static 'Load' method.
            ; The #Include "./JSON.ahk" directive at the top of this script is supposed to make the JSON class available.
            ; If JSON.ahk is correct and v2 compatible, this warning might be a linter/parser quirk. 
            ; If the script fails at runtime due to 'JSON' being an unknown variable, the issue lies with JSON.ahk.
            responseText := request.ResponseText
            json_response := JSON.Load(&responseText)
            return json_response
        } Catch Error as e {
            ; Msgbox("JSON Parsing Error: " e.Message, "Error", 16)
            return "JSON Parsing Error: " e.Message
        }
    }

    /**
     * Checks status of URL by returning status code.
     *
     * @Parameters
     *    URL    - [String] expects valid URL
     *
     * @Return
     *    [String] HTTP status code or error message.
     */
    checkStatus(URL) {
        request := this.createRequestObj(URL)
        if IsObject(request)
            return request.status
        return request ; Error message
    }

    /**
     * Opens Internet Explorer and navigates to URL.
     * Can be visible or hidden.
     * Returns COM Object to interact with.
     *
     * @Parameters
     *    URL           - [String] expects valid URL
     *    visibility    - [Boolean] expects true or false (default: false)
     *
     * @Return
     *    [Object] COM Object for Internet Explorer.
     */
    webBrowser(URL, visibility := false) {
        wb := ComObject("InternetExplorer.Application")
        wb.Visible := visibility
        wb.Navigate(URL)
        while wb.Busy || wb.ReadyState != 4 {
            Sleep(100)
        }
        return wb
    }

    /**
     * Creates a COM object used for HTTP requests.
     * Can be used with both "GET" and "POST".
     *
     * @Parameters
     *    endpoint     - [String] expects valid URL or endpoint
     *    method       - [String] expects "GET" or "POST" (default: "GET")
     *    body         - [String] values we want to pass via POST (optional for GET)
     *    timeouts     - [Map] expects timeouts passed in key:value pairs, e.g.:
     *                    Map("resolve_timeout", 0, "connect_timeout", 30000, 
     *                        "send_timeout", 30000, "receive_timeout", 60000)
     *
     * @Return
     *    [Object] WinHttpRequest COM object or [String] error message or [Boolean] false.
     */
    createRequestObj(endpoint := "", method := "GET", body := "", timeouts := "") {
        local request_obj
        try {
            request_obj := ComObject("WinHttp.WinHttpRequest.5.1")
            
            ; Attempt to set system proxy
            ; Constants for SetProxy
            WINHTTP_ACCESS_TYPE_DEFAULT_PROXY := 0
            WINHTTP_ACCESS_TYPE_NO_PROXY := 1
            WINHTTP_ACCESS_TYPE_NAMED_PROXY := 3

            ; Try to get system proxy settings using default (WINHTTP_ACCESS_TYPE_DEFAULT_PROXY)
            ; This tells WinHTTP to use the proxy settings configured in Internet Explorer or via netsh winhttp set proxy.
            ; If no proxy is configured, it will attempt a direct connection.
            Try request_obj.SetProxy(WINHTTP_ACCESS_TYPE_DEFAULT_PROXY) ; Use system default proxy settings
            Catch Error as e_proxy ; Specify Error class for clarity and correctness
            {
                ; If setting default proxy fails, log it or notify, but continue (might work without proxy or with specific proxy later)
                ; Msgbox("Failed to set system default proxy: " e_proxy.Message, "Proxy Warning", 48) ; 48 for Warning Icon
            }
        } Catch Error as e {
            ; Msgbox("Fatal Error: Unable to create HTTP object. " e.Message, "Error", 16)
            return "Fatal Error. Unable to create HTTP object"
        }

        this.defineTimeout(&request_obj, timeouts)

        try {
            request_obj.Open(method, endpoint)
        } Catch Error as e {
            ; Msgbox("Error opening request: " e.Message, "Error", 16)
            current_time := FormatTime(,"yyyy.MM.dd hh:mm:ss")
            ; FileAppend(current_time ": " e.Message ", line:" e.Line "`n`nEndpoint: " endpoint, A_ScriptDir "\netrequest_error.txt")
            return "Error opening request: " e.Message
        }
        
        try request_obj.SetRequestHeader("Content-Type", NetRequest.request_header[method])
        Catch Error as e {
             ; Msgbox("Error setting request header: " e.Message, "Error", 16)
             return "Error setting request header: " e.Message
        }

        try {
            if (body == "") {
                request_obj.Send()
            } else {
                request_obj.Send(body)
            }
        } Catch Error as e {
            local user_friendly_message := "Error sending request: " e.Message
            if InStr(e.Message, "0x80072EE7") {
                user_friendly_message := "网络错误 (0x80072EE7): 服务器名称或地址无法解析。`n`n请检查您的网络连接和 DNS 设置。"
            }
            ; Msgbox(user_friendly_message, "请求错误", 16) ; Use 16 for Stop/Error Icon
            current_time := FormatTime(,"yyyy.MM.dd hh:mm:ss")
            ; FileAppend(current_time ": " e.Message " (User Msg: " user_friendly_message "), line:" e.Line "`n`nEndpoint: " endpoint, A_ScriptDir "\netrequest_error.txt")
            return user_friendly_message ; Return the potentially more friendly message
        }

        try {
            request_obj.WaitForResponse()
        } Catch Error as e {
            ; Msgbox("Error waiting for response: " e.Message, "Error", 16)
            current_time := FormatTime(,"yyyy.MM.dd hh:mm:ss")
            ; FileAppend(current_time ": " e.Message ", line:" e.Line "`n`nEndpoint: " endpoint, A_ScriptDir "\netrequest_error.txt")
            return "Error waiting for response: " e.Message
        }

        if (request_obj.ResponseText == "") { ; Check ResponseText as request_obj itself will be an object
            ; Msgbox("Fatal Error: Couldn't receive response or response was empty.", "Error", "IconError")
            return "Fatal Error. Couldn't receive response."
        }
        return request_obj
    }

    /**
     * Defines the default timeouts or allows them to be adjusted.
     * Timeouts are always defined in milliseconds.
     *
     * @Parameters
     *    com_obj              - [Object] expects valid COM object for HTTP requests (passed by reference)
     *    timeouts             - [Map] expects timeouts as key-value pairs (see createRequestObj for format)
     *                         If not a Map, default timeouts are used.
     *
     * @Return
     *    Nothing
     */
    defineTimeout(&com_obj, timeouts) {
        local resolve_timeout, connect_timeout, send_timeout, receive_timeout
        if (timeouts is Map) {
            resolve_timeout := timeouts.Has("resolve_timeout") ? timeouts["resolve_timeout"] : 0
            connect_timeout := timeouts.Has("connect_timeout") ? timeouts["connect_timeout"] : 30000
            send_timeout := timeouts.Has("send_timeout") ? timeouts["send_timeout"] : 30000
            receive_timeout := timeouts.Has("receive_timeout") ? timeouts["receive_timeout"] : 60000 ; Corrected from 600000
        } else {
            resolve_timeout := 0
            connect_timeout := 30000
            send_timeout := 30000
            receive_timeout := 60000 ; Corrected from 600000
        }
        com_obj.SetTimeouts(resolve_timeout, connect_timeout, send_timeout, receive_timeout)
    }

    /**
     * Searches the DOM for tags with passed attributes.
     * (Note: This method relies on Internet Explorer COM object, which is deprecated and may not work reliably.)
     *
     * @Parameters
     *    browser_obj     - [Object] expects browser_obj.document (e.g., from webBrowser() method)
     *    item            - [String] expects valid CSS selector (e.g., "[attribute=value]")
     *
     * @Return
     *    [Array] Array of matching DOM elements.
     */
    searchForMatches(browser_obj, item) {
        local matching_elements := []
        local all_elements := browser_obj.querySelectorAll(item)
        Loop all_elements.length {
            if (all_elements[A_Index-1]) {
                matching_elements.Push(all_elements[A_Index-1])
            }
        }
        return matching_elements
    }
}
