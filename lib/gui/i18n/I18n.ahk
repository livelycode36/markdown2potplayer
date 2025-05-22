#Requires AutoHotkey v2.0
#Include LCID.ahk
/*
    i18n for AutoHotkey
    Version: 1.0.0
    Author: Maël Schweighardt (https://github.com/iammael/i18n-autohotkey)
    License: MIT (https://github.com/iammael/i18n-autohotkey/blob/master/LICENSE)
*/

class I18n {
    __New(languageFolder) {
        this.LanguageFolder := languageFolder
        ; languageFile := LCID[A_Language]
        languageFile := "en-US"
        this.LanguageFile := languageFolder "\" languageFile ".ini"
        if (!FileExist(this.LanguageFile)) {
            this.LanguageFile := languageFolder "\en-US.ini"
        }

        this._init()
    }

    _init() {
        Section := IniRead(this.LanguageFile, "Strings")
        keys_values := StrSplit(Section, "`n")

        for key_value in keys_values {
            key := StrSplit(key_value, "=")[1]
            value := StrSplit(key_value, "=")[2]
            this.DefineProp(key, {Value:value})
        }
    }
}
