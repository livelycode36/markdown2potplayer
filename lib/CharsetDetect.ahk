class TextEncodingDetect {
    UTF8Bom := [0xEF, 0xBB, 0xBF]
    UTF16LeBom := [0xFF, 0xFE]
    UTF16BeBom := [0xFE, 0xFF]
    UTF32LeBom := [0xFF, 0xFE, 0x00, 0x00]

    DetectEncoding(fileName) {
        if !FileExist(fileName) {
            MsgBox("File not found")
            return ""
        }

        buffer := FileRead(fileName, "RAW")
        size := buffer.Size

        encodingType := this.DetectWithBom(buffer)
        if (encodingType == "Utf8Bom") {
            encodingType := "UTF-8"
        } else if (encodingType == "UnicodeBom") {
            encodingType := "UTF-16"
        }

        if encodingType != "None" {
            return encodingType
        }

        encodingType := this.DetectWithoutBom(buffer, size)
        if (encodingType == "GBK" ||
            encodingType == "Ansi") {
            ; CP0 是 系统默认编码
            encodingType := "CP0"
        }

        return encodingType != "None" ? encodingType : "None"
    }

    DetectWithBom(buffer) {
        if (buffer.Size >= 3 && this.ByteAt(buffer, 0) = this.UTF8Bom[1] && this.ByteAt(buffer, 1) = this.UTF8Bom[2] && this.ByteAt(buffer, 2) = this.UTF8Bom[3]) {
            return "Utf8Bom"
        }

        if (buffer.Size >= 2 && this.ByteAt(buffer, 0) = this.UTF16LeBom[1] && this.ByteAt(buffer, 1) = this.UTF16LeBom[2]) {
            return "UnicodeBom"
        }

        if (buffer.Size >= 2 && this.ByteAt(buffer, 0) = this.UTF16BeBom[1] && this.ByteAt(buffer, 1) = this.UTF16BeBom[2]) {
            if (buffer.Size >= 4 && this.ByteAt(buffer, 2) = this.UTF32LeBom[3] && this.ByteAt(buffer, 3) = this.UTF32LeBom[4]) {
                return "Utf32Bom"
            }
            return "BigEndianUnicodeBom"
        }

        return "None"
    }

    DetectWithoutBom(buffer, size) {
        ; Check for UTF-8 encoding
        encoding := this.CheckUtf8(buffer, size)
        if encoding != "None" {
            return encoding
        }

        ; Check for ANSI encoding
        if !this.ContainsZero(buffer, size) {
            return this.CheckChinese(buffer, size) ? "GBK" : "Ansi"
        }

        return "None"
    }

    CheckUtf8(buffer, size) {
        pos := 0
        while pos < size {
            ch := this.ByteAt(buffer, pos)
            pos++

            if ch < 0x80 {
                continue
            }

            if ch >= 0xC2 && ch <= 0xDF {
                if !this.IsContinuationByte(this.ByteAt(buffer, pos)) {
                    return "None"
                }
                pos++
                continue
            }

            if ch >= 0xE0 && ch <= 0xEF {
                if !this.IsContinuationByte(this.ByteAt(buffer, pos)) || !this.IsContinuationByte(this.ByteAt(buffer, pos + 1)) {
                    return "None"
                }
                pos += 2
                continue
            }

            if ch >= 0xF0 && ch <= 0xF4 {
                if !this.IsContinuationByte(this.ByteAt(buffer, pos)) || !this.IsContinuationByte(this.ByteAt(buffer, pos + 1)) || !this.IsContinuationByte(this.ByteAt(buffer, pos + 2)) {
                    return "None"
                }
                pos += 3
                continue
            }

            return "None"
        }
        ; return "Utf8Nobom"
        return "UTF-8"
    }

    IsContinuationByte(byte) {
        return byte >= 0x80 && byte <= 0xBF
    }

    ContainsZero(buffer, size) {
        pos := 0
        while pos < size {
            if this.ByteAt(buffer, pos) = 0 {
                return true
            }
            pos++
        }
        return false
    }

    CheckChinese(buffer, size) {
        pos := 0
        while pos < size - 1 {
            ch1 := this.ByteAt(buffer, pos)
            ch2 := this.ByteAt(buffer, pos + 1)
            pos += 2

            if (ch1 >= 176 && ch1 <= 247 && ch2 >= 160 && ch2 <= 254) ; GB2312
                || (ch1 >= 129 && ch1 <= 254 && ch2 >= 64 && ch2 <= 254)  ; GBK
                || (ch1 >= 129 && ((ch2 >= 64 && ch2 <= 126) || (ch2 >= 161 && ch2 <= 254))) { ; Big5
                return true
            }
        }
        return false
    }

    ByteAt(buffer, index) {
        return NumGet(buffer, index, "UChar")
    }
}

; 使用示例：
; detect := TextEncodingDetect()
; encoding := detect.DetectEncoding("C:\Users\Thunder\Downloads\Compressed\02 音名与钢琴键盘.srt")
; MsgBox "Detected Encoding: " encoding
