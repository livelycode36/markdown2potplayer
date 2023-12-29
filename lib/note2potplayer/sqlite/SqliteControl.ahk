#Requires AutoHotkey v2.0.0
#Include "Class_SQLiteDB.ahk"

; 数据库文件路径
db_file_path := SubStr(A_ScriptDir, 1,InStr(A_ScriptDir,"\lib",,1) -1 ) "\config.db"
table_name := "config"

OpenLocalDB(){
  ; 创建 SQLiteDB 实例
  DB := SQLiteDB()
  
  ; 打开或创建数据库
  if !DB.OpenDB(db_file_path) {
    MsgBox("无法打开或创建数据库: " db_file_path "`n错误信息: " DB.ErrorMsg)
    ExitApp
  }
  return DB
}

GetKeyName(key){
  DB := OpenLocalDB()

  ; 读取 key 为 'app_name' 的值
  SQL_SelectValue := "SELECT value FROM " table_name " WHERE key = '" key "';"
  Result := ""
  if !DB.GetTable(SQL_SelectValue, &Result) {
      MsgBox("无法读取配置项 '" key "'`n错误信息: " . DB.ErrorMsg)
      DB.CloseDB()
      ExitApp
  }

  ; 显示结果
  if Result.RowCount > 0 {
      ; MsgBox("配置项 '" key "' 的值为: " . Result.Rows[1][1]) ; 获取第一行第一列的值
      return Result.Rows[1][1]
  } else {
      ; MsgBox("配置项 '" key "' 不存在。")
      return false
  }

  DB.CloseDB()
}