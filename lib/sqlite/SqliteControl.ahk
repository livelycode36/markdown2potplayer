#Requires AutoHotkey v2.0.0
#Include "Class_SQLiteDB.ahk"

; 数据库文件路径
db_file_path := "config.db"
table_name := "config"

InitSqlite() {
  if !TableExist(table_name) {
    DB := OpenLocalDB()
    ; 创建 config 表
    SQL_CreateTable := 
    "CREATE TABLE IF NOT EXISTS " table_name " ("
    . " key TEXT PRIMARY KEY,"
    . " value TEXT"
    . " );"
  
    if !DB.Exec(SQL_CreateTable) {
      MsgBox("无法创建表 " table_name "`n错误信息: " DB.ErrorMsg)
      DB.CloseDB()
      ExitApp
    }
    DB.CloseDB()
  }

  ; 初始化插入数据
  config_data := Map()
  config_data["path"] := "C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe"
  config_data["is_stop"] := "0"
  config_data["reduce_time"] := "0"
  config_data["app_name"] := "Obsidian.exe"
  config_data["url_protocol"] := "jv://open"
  config_data["path_is_encode"] := "0"
  config_data["remove_suffix_of_video_file"] := "1"
  config_data["title"] := "{name} | {time}"
  config_data["template"] := 
  "`n"
  . "视频:{title}"
  . "`n"
  config_data["image_template"] := 
  "`n"
  . "图片:{image}"
  . "`n"
  . "视频:{title}"
  . "`n"
  config_data["hotkey_backlink"] := "!g"
  config_data["hotkey_iamge_backlink"] := "^!g"

  DB := OpenLocalDB()
  ; 插入数据
  for key, value in config_data {
    ; 检查 config 表中是否存在 key 值
    SQL_Check_Key := "SELECT COUNT(*) FROM " table_name " WHERE key = '" key "'"
    Result := ""
    If !DB.GetTable(SQL_Check_Key, &Result){
      MsgBox "打开数据表" table_name "失败！"
      ExitApp
    }

    ; 如果 key 不存在，则插入
    If Result.RowCount = 0 || Result.Rows[1][1] = 0{
      SQL := "INSERT INTO config (key, value) VALUES ('" key "', '" value "')"
      If !DB.Exec(SQL)
        ExitApp
    }
  }
  ; 关闭数据库
  DB.CloseDB()
}

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

TableExist(table_name){
  DB := OpenLocalDB()

  ; 检查 config 表是否存在
  SQL_CheckTable := "SELECT name FROM sqlite_master WHERE type='table' AND name='" table_name "';"
  Result := ""
  if !DB.GetTable(SQL_CheckTable, &Result) {
    MsgBox("无法检查表 " table_name " 是否存在`n错误信息: " . DB.ErrorMsg)
    DB.CloseDB()
    ExitApp
  }

  DB.CloseDB()
  ; 判断表是否存在
  if Result.RowCount > 0 {
    ; MsgBox("表 " table_name " 存在。")
    return true
  } else {
    ; MsgBox("表 " table_name " 不存在。")
    return false
  }
}

GetKey(key){
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

UpdateOrIntertAndRefreshConfig(key, value){
  DB := OpenLocalDB()

  ; 插入或更新配置项
  SQL_InsertOrUpdate := "INSERT OR REPLACE INTO " table_name " (key, value) VALUES ('" key "', '" value "');"
  if !DB.Exec(SQL_InsertOrUpdate) {
      MsgBox("无法插入或更新配置项 '" table_name "'`n错误信息: " . DB.ErrorMsg)
      DB.CloseDB()
      ExitApp
  }
  DB.CloseDB()

  RefreshConfig()
}