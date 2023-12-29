#Requires AutoHotkey v2.0.0
; ======================================================================================================================
; Function:         Class definitions as wrappers for SQLite3.dll to work with SQLite DBs.
; AHK version:      AHK 2.0.2 (U32/U64)
; Tested on:        Win 10 Pro (x64), SQLite 3.40.1 (x64)
; Version:          2.0.0/2023-01-05/just me    - Initial release for AHK 2.0
;                   2.0.1/2023-04-03/just me    - Added EnableLoadExtension() method
;                                               - Added LoadExtension() method
;                   2.0.2/2023-07-24/just me    - Added _ErrStr() method
;                                               - Fixed bug in _SetError() when the DB could not be opened
;                   2.0.3/2023-08-28/just me    - Fixed v2.1.2 related bug in Class _Pepared->Next() method.
;                   2.0.4/2023-08-31/just me    - Fixed possible naming conflicts with the global scope
;                   2.0.5/2023-09-08/just me    - Final fix for _Pepared->Next() method.
; Remarks:          Names of "private" properties / methods are prefixed with an underscore,
;                   they must not be set / called by the script!
;
;                   SQLite3.dll file is assumed to be in the script's folder, otherwise you have to
;                   provide an INI-File SQLiteDB.ini in the script's folder containing the path:
;                   [Main]
;                   DllPath=Path to SQLite3.dll
;
;                   Encoding of SQLite DBs is assumed to be UTF-8
;                   Minimum supported SQLite3.dll version is 3.6
;                   Download the current version of SQLite3.dll (and also SQlite3.exe) from www.sqlite.org
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the
; use of this software.
; ======================================================================================================================
; CLASS SQliteDB - SQLiteDB main class
; ======================================================================================================================
Class SQLiteDB {
   ; ===================================================================================================================
   ; CONSTRUCTOR __New
   ; ===================================================================================================================
   __New() {
      Local DLL, LibVersion, SQLiteDLL
      This._Path := ""                  ; Database path                                 (String)
      This._Handle := 0                 ; Database handle                               (Pointer)
      This._Stmts := Map()              ; Valid prepared statements                     (Map)
      If (SQLiteDB._RefCount = 0) {
         SQLiteDLL := SQLiteDB._SQLiteDLL
         If !FileExist(SQLiteDLL)
            If FileExist(A_ScriptDir . "\SQLiteDB.ini") {
               SQLiteDLL := IniRead(A_ScriptDir . "\SQLiteDB.ini", "Main", "DllPath", SQLiteDLL)
               SQLiteDB._SQLiteDLL := SQLiteDLL
         }
         If !(DLL := DllCall("LoadLibrary", "Str", SQLiteDB._SQLiteDLL, "UPtr")) {
            MsgBox("DLL " . SQLiteDLL . " does not exist!", "SQLiteDB Error", 16)
            ExitApp
         }
         LibVersion := StrGet(DllCall("SQlite3.dll\sqlite3_libversion", "Cdecl UPtr"), "UTF-8")
         If (VerCompare(LibVersion, SQLiteDB._MinVersion) < 0) {
            DllCall("FreeLibrary", "Ptr", DLL)
            MsgBox("Version " . LibVersion . " of SQLite3.dll is not supported!`n`n" .
                   "You can download the current version from www.sqlite.org!",
                   "SQLiteDB ERROR", 16)
            ExitApp
         }
         SQLiteDB.Version := LibVersion
      }
      SQLiteDB._RefCount += 1
   }
   ; ===================================================================================================================
   ; DESTRUCTOR __Delete
   ; ===================================================================================================================
   __Delete() {
      Local DLL
      If (This._Handle)
         This.CloseDB()
      SQLiteDB._RefCount -= 1
      If (SQLiteDB._RefCount = 0) {
         If (DLL := DllCall("GetModuleHandle", "Str", SQLiteDB._SQLiteDLL, "UPtr"))
            DllCall("FreeLibrary", "Ptr", DLL)
      }
   }
   ; ===================================================================================================================
   ; Properties
   ; ===================================================================================================================
    ErrorMsg := ""              ; Error message                           (String) 
    ErrorCode := 0              ; SQLite error code / ErrorLevel          (Variant)
    Changes := 0                ; Changes made by last call of Exec()     (Integer)
    SQL := ""                   ; Last executed SQL statement             (String)
   ; ===================================================================================================================
   ; METHOD OpenDB         Open a database
   ; Parameters:           DBPath      - Path of the database file
   ;                       Access      - Wanted access: "R"ead / "W"rite
   ;                       Create      - Create new database in write mode, if it doesn't exist
   ; Return values:        On success  - True
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; Remarks:              If DBPath is empty in write mode, a database called ":memory:" is created in memory
   ;                       and deletet on call of CloseDB.
   ; ===================================================================================================================
   OpenDB(DBPath, Access := "W", Create := True) {
      Static SQLITE_OPEN_READONLY  := 0x01 ; Database opened as read-only
      Static SQLITE_OPEN_READWRITE := 0x02 ; Database opened as read-write
      Static SQLITE_OPEN_CREATE    := 0x04 ; Database will be created if not exists
      Static MEMDB := ":memory:"
      Local Flags, HDB, RC, UTF8
      This.ErrorMsg := ""
      This.ErrorCode := 0
      HDB := 0
      If (DBPath = "")
         DBPath := MEMDB
      If (DBPath = This._Path) && (This._Handle)
         Return True
      If (This._Handle)
         Return This._SetError(0, "you must first close DB`n" . This._Path)
      Flags := 0
      Access := SubStr(Access, 1, 1)
      If (Access != "W") && (Access != "R")
         Access := "R"
      Flags := SQLITE_OPEN_READONLY
      If (Access = "W") {
         Flags := SQLITE_OPEN_READWRITE
         If (Create)
            Flags |= SQLITE_OPEN_CREATE
      }
      This._Path := DBPath
      UTF8 := This._StrToUTF8(DBPath)
      HDB := 0
      RC := DllCall("SQlite3.dll\sqlite3_open_v2", "Ptr", UTF8, "UPtrP", &HDB, "Int", Flags, "Ptr", 0, "Cdecl Int")
      If (RC) {
         This._Path := ""
         Return This._SetError(RC, This._ErrStr(RC) . "`n" . DBPath)
      }
      This._Handle := HDB
      Return True
   }
   ; ===================================================================================================================
   ; METHOD CloseDB        Close database
   ; Parameters:           None
   ; Return values:        On success  - True
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   CloseDB() {
      Local Each, Stmt, RC
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := ""
      If !(This._Handle)
         Return True
      For Each, Stmt in This._Stmts
         DllCall("SQlite3.dll\sqlite3_finalize", "Ptr", Stmt, "Cdecl Int")
      If (RC := DllCall("SQlite3.dll\sqlite3_close", "Ptr", This._Handle, "Cdecl Int"))
         Return This._SetError(RC)
      This._Path := ""
      This._Handle := ""
      This._Stmts := Map()
      Return True
   }
   ; ===================================================================================================================
   ; METHOD AttachDB       Add another database file to the current database connection
   ;                       http://www.sqlite.org/lang_attach.html
   ; Parameters:           DBPath      - Path of the database file
   ;                       DBAlias     - Database alias name used internally by SQLite
   ; Return values:        On success  - True
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   AttachDB(DBPath, DBAlias) {
      Return This.Exec("ATTACH DATABASE '" . DBPath . "' As " . DBAlias . ";")
   }
   ; ===================================================================================================================
   ; METHOD DetachDB       Detaches an additional database connection previously attached using AttachDB()
   ;                       http://www.sqlite.org/lang_detach.html
   ; Parameters:           DBAlias     - Database alias name used with AttachDB()
   ; Return values:        On success  - True
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   DetachDB(DBAlias) {
      Return This.Exec("DETACH DATABASE " . DBAlias . ";")
   }
   ; ===================================================================================================================
   ; METHOD Exec           Execute SQL statement
   ; Parameters:           SQL         - Valid SQL statement
   ;                       Callback    - Name of a callback function to invoke for each result row coming out
   ;                                     of the evaluated SQL statements.
   ;                                     The function must accept 4 parameters:
   ;                                     1: SQLiteDB object
   ;                                     2: Number of columns
   ;                                     3: Pointer to an array of pointers to columns text
   ;                                     4: Pointer to an array of pointers to column names
   ;                                     The address of the current SQL string is passed in A_EventInfo.
   ;                                     If the callback function returns non-zero, DB.Exec() returns SQLITE_ABORT
   ;                                     without invoking the callback again and without running any subsequent
   ;                                     SQL statements.  
   ; Return values:        On success  - True, the number of changed rows is given in property Changes
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   Exec(SQL, Callback := "") {
      Local CBPtr, Err, RC, UTF8
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := SQL
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      CBPtr := 0
      Err := 0
      If (Type(Callback) = "Func") && (Callback.MinParams = 4)
         CBPtr := CallbackCreate(Callback, "C", 4)
      UTF8 := This._StrToUTF8(SQL)
      RC := DllCall("SQlite3.dll\sqlite3_exec", "Ptr", This._Handle, "Ptr", UTF8, "Int", CBPtr, "Ptr", ObjPtr(This),
                    "UPtrP", &Err, "Cdecl Int")
      If (CBPtr)
         CallbackFree(CBPtr)
      If (RC) {
         This.ErrorMsg := StrGet(Err, "UTF-8")
         This.ErrorCode := RC
         DllCall("SQLite3.dll\sqlite3_free", "Ptr", Err, "Cdecl")
         Return False
      }
      This.Changes := This._Changes()
      Return True
   }
   ; ===================================================================================================================
   ; METHOD GetTable       Get complete result for SELECT query
   ; Parameters:           SQL         - SQL SELECT statement
   ;                       ByRef TB    - Variable to store the result object (TB _Table)
   ;                       MaxResult   - Number of rows to return:
   ;                          0          Complete result (default)
   ;                         -1          Return only RowCount and ColumnCount
   ;                         -2          Return counters and array ColumnNames
   ;                          n          Return counters and ColumnNames and first n rows
   ; Return values:        On success  - True, TB contains the result object
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   GetTable(SQL, &TB, MaxResult := 0) {
      TB := ""
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := SQL
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      Local Names := ""
      Local Err := 0, GetRows := 0, RC := 0
      Local I := 0, Rows := Cols := 0
      Local Table := 0
      If !IsInteger(MaxResult)
         MaxResult := 0
      If (MaxResult < -2)
         MaxResult := 0
      Local UTF8 := This._StrToUTF8(SQL)
      RC := DllCall("SQlite3.dll\sqlite3_get_table", "Ptr", This._Handle, "Ptr", UTF8, "UPtrP", &Table,
                    "IntP", &Rows, "IntP", &Cols, "UPtrP", &Err, "Cdecl Int")
      If (RC) {
         This.ErrorMsg := StrGet(Err, "UTF-8")
         This.ErrorCode := RC
         DllCall("SQLite3.dll\sqlite3_free", "Ptr", Err, "Cdecl")
         Return False
      }
      TB := SQLiteDB._Table()
      TB.ColumnCount := Cols
      TB.RowCount := Rows
      If (MaxResult = -1) {
         DllCall("SQLite3.dll\sqlite3_free_table", "Ptr", Table, "Cdecl")
         Return True
      }
      If (MaxResult = -2)
         GetRows := 0
      Else If (MaxResult > 0) && (MaxResult <= Rows)
         GetRows := MaxResult
      Else
         GetRows := Rows
      Local Offset := 0
      Names := []
      Names.Length := Cols
      Loop Cols {
         Names[A_Index] := StrGet(NumGet(Table + Offset, "UPtr"), "UTF-8")
         Offset += A_PtrSize
      }
      TB.ColumnNames := Names
      TB.HasNames := True
      TB.Rows.Length := GetRows
      Local ColArr
      Loop GetRows {
         ColArr := []
         ColArr.Length := Cols
         Loop Cols {
            ColArr[A_Index] := (Pointer := NumGet(Table + Offset, "UPtr")) ? StrGet(Pointer, "UTF-8") : ""
            Offset += A_PtrSize
         }
         TB.Rows[A_Index] := ColArr
      }
      If (GetRows)
         TB.HasRows := True
      DllCall("SQLite3.dll\sqlite3_free_table", "Ptr", Table, "Cdecl")
      Return True
   }
   ; ===================================================================================================================
   ; Prepared statement 10:54 2019.07.05. by Dixtroy
   ;  DB := SQLiteDB()
   ;  DB.OpenDB(DBFileName)
   ;  DB.Prepare 1 or more, just once
   ;  DB.Step 1 or more on prepared one, repeatable
   ;  DB.Finalize at the end
   ; ===================================================================================================================
   ; ===================================================================================================================
   ; METHOD Prepare        Prepare database table for further actions.
   ; Parameters:           SQL         - SQL statement to be compiled
   ;                       ByRef ST    - Variable to store the statement object (Class _Statement)
   ; Return values:        On success  - True, ST contains the statement object
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; Remarks:              You have to pass one ? for each column you want to assign a value later.
   ; ===================================================================================================================
   Prepare(SQL, &ST) {
      Local ColumnCount, ColumnNames, Pointer, RC
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := SQL
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      Local Stmt := 0
      Local UTF8 := This._StrToUTF8(SQL)
      RC := DllCall("SQlite3.dll\sqlite3_prepare_v2", "Ptr", This._Handle, "Ptr", UTF8, "Int", -1,
                    "UPtrP", &Stmt, "Ptr", 0, "Cdecl Int")
      If (RC)
         Return This._SetError(RC)
      ColumnNames := []
      ColumnCount := DllCall("SQlite3.dll\sqlite3_column_count", "Ptr", Stmt, "Cdecl Int")
      If (ColumnCount > 0) {
         ColumnNames.Length := ColumnCount
         Loop ColumnCount {
            Pointer := DllCall("SQlite3.dll\sqlite3_column_name", "Ptr", Stmt, "Int", A_Index - 1, "Cdecl UPtr")
            ColumnNames[A_Index] := StrGet(Pointer, "UTF-8")
         }
      }
		ST := SQLiteDB._Prepared()
      ST.ColumnCount := ColumnCount
      ST.ColumnNames := ColumnNames
      ST.ParamCount := DllCall("SQlite3.dll\sqlite3_bind_parameter_count", "Ptr", Stmt, "Cdecl Int")
      ST._Handle := Stmt
      ST._DB := This
      This._Stmts[Stmt] := Stmt
      Return True
   }
   ; ===================================================================================================================
   ; METHOD CreateScalarFunc  Create a scalar application defined function
   ; Parameters:              Name  -  the name of the function
   ;                          Args  -  the number of arguments that the SQL function takes
   ;                          Func  -  a pointer to AHK functions that implement the SQL function
   ;                          Enc   -  specifies what text encoding this SQL function prefers for its parameters
   ;                          Param -  an arbitrary pointer accessible within the funtion with sqlite3_user_data()
   ; Return values:           On success  - True
   ;                          On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; Documentation:           www.sqlite.org/c3ref/create_function.html
   ; ===================================================================================================================
   CreateScalarFunc(Name, Args, Func, Enc := 0x0801, Param := 0) {
      ; SQLITE_DETERMINISTIC = 0x0800 - the function will always return the same result given the same inputs
      ;                                 within a single SQL statement
      ; SQLITE_UTF8 = 0x0001
      This.ErrorMsg := ""
      This.ErrorCode := 0
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      Local RC := DllCall("SQLite3.dll\sqlite3_create_function", "Ptr", This._Handle, "AStr", Name, "Int", Args,
                          "Int", Enc, "Ptr", Param, "Ptr", Func, "Ptr", 0, "Ptr", 0, "Cdecl Int")
      Return (RC) ? This._SetError(RC) : True
   }
   ; ===================================================================================================================
   ; METHOD EnableLoadExtension  Enable or disable the sqlite3_load_extension() interface
   ; Parameters:                 Enable (1 = enable, 0 = disable)
   ; Return values:              On success  - True
   ;                             On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; Documentation:              www.sqlite.org/c3ref/enable_load_extension.html
   ;                             #define SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION 1005 /* int int* */
   ; ===================================================================================================================
   EnableLoadExtension(Enable := 1) {
      Local RC := DllCall("SQLite3.dll\sqlite3_db_config", "Ptr", This._Handle, "Int", 1005, "Int", !!Enable,
                          "Ptr", 0, "Cdecl Int")
      Return (RC) ? This._SetError(RC) : True
   }
   ; ===================================================================================================================
   ; METHOD LoadExtension     Enable or disable the sqlite3_load_extension() interface
   ; Parameters:              File - Name of the shared library containing extension
   ;                          Proc - Name of the entry point. Derived from File if omitted.
   ; Return values:           On success  - True
   ;                          On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; Documentation:           https://www.sqlite.org/c3ref/load_extension.html
   ; ===================================================================================================================
   LoadExtension(File, Proc?) {
      Local RC := IsSet(Proc) ? DllCall("SQLite3.dll\sqlite3_load_extension", "Ptr", This._Handle, "AStr", File,
                                        "AStr", Proc, "Ptr", 0, "Cdecl Int")
                              : DllCall("SQLite3.dll\sqlite3_load_extension", "Ptr", This._Handle, "AStr", File,
                                        "Ptr", 0, "Ptr", 0, "Cdecl Int")
      Return (RC) ? This._SetError(RC) : True
   }
   ; ===================================================================================================================
   ; METHOD LastInsertRowID   Get the ROWID of the last inserted row
   ; Parameters:              ByRef RowID - Variable to store the ROWID
   ; Return values:           On success  - True, RowID contains the ROWID
   ;                          On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   LastInsertRowID(&RowID) {
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := ""
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      RowID := DllCall("SQLite3.dll\sqlite3_last_insert_rowid", "Ptr", This._Handle, "Cdecl Int64")
      Return True
   }
   ; ===================================================================================================================
   ; METHOD TotalChanges   Get the number of changed rows since connecting to the database
   ; Parameters:           ByRef Rows  - Variable to store the number of rows
   ; Return values:        On success  - True, Rows contains the number of rows
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   TotalChanges(&Rows) {
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := ""
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      Rows := DllCall("SQLite3.dll\sqlite3_total_changes", "Ptr", This._Handle, "Cdecl Int")
      Return True
   }
   ; ===================================================================================================================
   ; METHOD SetTimeout     Set the timeout to wait before SQLITE_BUSY or SQLITE_IOERR_BLOCKED is returned,
   ;                       when a table is locked.
   ; Parameters:           TimeOut     - Time to wait in milliseconds
   ; Return values:        On success  - True
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   SetTimeout(Timeout := 1000) {
      Local RC
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := ""
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      If !IsInteger(Timeout)
         Timeout := 1000
      If (RC := DllCall("SQLite3.dll\sqlite3_busy_timeout", "Ptr", This._Handle, "Int", Timeout, "Cdecl Int"))
         Return This._SetError(RC)
      Return True
   }
   ; ===================================================================================================================
   ; METHOD EscapeStr      Escapes special characters in a string to be used as field content
   ; Parameters:           Str         - String to be escaped
   ;                       Quote       - Add single quotes around the outside of the total string (True / False)
   ; Return values:        On success  - True
   ;                       On failure  - False, ErrorMsg / ErrorCode contain additional information
   ; ===================================================================================================================
   EscapeStr(&Str, Quote := True) {
      This.ErrorMsg := ""
      This.ErrorCode := 0
      This.SQL := ""
      If !(This._Handle)
         Return This._SetError(0, "Invalid database handle!")
      If IsNumber(Str)
         Return True
      Local OP := Buffer(16, 0)
      StrPut(Quote ? "%Q" : "%q", OP, "UTF-8")
      Local UTF8 := This._StrToUTF8(Str)
      Local Ptr := DllCall("SQLite3.dll\sqlite3_mprintf", "Ptr", OP, "Ptr", UTF8, "Cdecl UPtr")
      Str := StrGet(Ptr, "UTF-8")
      DllCall("SQLite3.dll\sqlite3_free", "Ptr", Ptr, "Cdecl")
      Return True
   }
   ; ===================================================================================================================
   ; METHOD ExtErrCode     Gets the extended result code in case of errors.
   ; Parameters:           None.
   ; Return values:        On success  - Extended result code
   ;                       On failure  - 0
   ; Remarks:              Extended result code list -> https://www.sqlite.org/rescode.html#extrc
   ; ===================================================================================================================
   ExtErrCode() {
      If !(This._Handle)
         Return 0
      Return DllCall("SQLite3.dll\sqlite3_extended_errcode", "Ptr", This._Handle, "Cdecl Int")
   }
   ; ===================================================================================================================
   ; PRIVATE _Changes
   ; ===================================================================================================================
   _Changes() {
      Return DllCall("SQLite3.dll\sqlite3_changes", "Ptr", This._Handle, "Cdecl Int")
   }
   ; ===================================================================================================================
   ; PRIVATE _ErrMsg
   ; ===================================================================================================================
   _ErrMsg() {
      Local RC
      If (RC := DllCall("SQLite3.dll\sqlite3_errmsg", "Ptr", This._Handle, "Cdecl UPtr"))
         Return StrGet(RC, "UTF-8")
      Return ""
   }
   ; ===================================================================================================================
   ; PRIVATE _ErrCode
   ; ===================================================================================================================
   _ErrCode() {
      Return DllCall("SQLite3.dll\sqlite3_errcode", "Ptr", This._Handle, "Cdecl Int")
   }
   ; ===================================================================================================================
   ; PRIVATE _ErrStr
   ; ===================================================================================================================
   _ErrStr(ErrCode) {
      Return StrGet(DllCall("SQLite3.dll\sqlite3_errstr", "Int", ErrCode, "Cdecl UPtr"), "UTF-8")
   }
   ; ===================================================================================================================
   ; PRIVATE _SetError
   ; ===================================================================================================================
   _SetError(RC, Msg?) {
      This.ErrorMsg := IsSet(Msg) ? Msg : This._ErrMsg()
      This.ErrorCode := RC
      Return False
   }
   ; ===================================================================================================================
   ; PRIVATE _StrToUTF8
   ; ===================================================================================================================
   _StrToUTF8(Str) {
      Local UTF8 := Buffer(StrPut(Str, "UTF-8"), 0)
      StrPut(Str, UTF8, "UTF-8")
      Return UTF8
   }
   ; ===================================================================================================================
   ; PRIVATE _Returncode
   ; ===================================================================================================================
   _ReturnCode(RC) {
      Static RCODE := {SQLITE_OK:           0, ; Successful result
                       SQLITE_ERROR:        1, ; SQL error or missing database
                       SQLITE_INTERNAL:     2, ; NOT USED. Internal logic error in SQLite
                       SQLITE_PERM:         3, ; Access permission denied
                       SQLITE_ABORT:        4, ; Callback routine requested an abort
                       SQLITE_BUSY:         5, ; The database file is locked
                       SQLITE_LOCKED:       6, ; A table in the database is locked
                       SQLITE_NOMEM:        7, ; A malloc() failed
                       SQLITE_READONLY:     8, ; Attempt to write a readonly database
                       SQLITE_INTERRUPT:    9, ; Operation terminated by sqlite3_interrupt()
                       SQLITE_IOERR:       10, ; Some kind of disk I/O error occurred
                       SQLITE_CORRUPT:     11, ; The database disk image is malformed
                       SQLITE_NOTFOUND:    12, ; NOT USED. Table or record not found
                       SQLITE_FULL:        13, ; Insertion failed because database is full
                       SQLITE_CANTOPEN:    14, ; Unable to open the database file
                       SQLITE_PROTOCOL:    15, ; NOT USED. Database lock protocol error
                       SQLITE_EMPTY:       16, ; Database is empty
                       SQLITE_SCHEMA:      17, ; The database schema changed
                       SQLITE_TOOBIG:      18, ; String or BLOB exceeds size limit
                       SQLITE_CONSTRAINT:  19, ; Abort due to constraint violation
                       SQLITE_MISMATCH:    20, ; Data type mismatch
                       SQLITE_MISUSE:      21, ; Library used incorrectly
                       SQLITE_NOLFS:       22, ; Uses OS features not supported on host
                       SQLITE_AUTH:        23, ; Authorization denied
                       SQLITE_FORMAT:      24, ; Auxiliary database format error
                       SQLITE_RANGE:       25, ; 2nd parameter to sqlite3_bind out of range
                       SQLITE_NOTADB:      26, ; File opened that is not a database file
                       SQLITE_ROW:        100, ; sqlite3_step() has another row ready
                       SQLITE_DONE:       101} ; sqlite3_step() has finished executing
      Return RCODE.HasOwnProp(RC) ? RCODE.%RC% : ""
   }
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; PRIVATE Properties ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   Static Version := ""
   Static _SQLiteDLL := A_ScriptDir . "\SQLite3.dll"
   Static _RefCount := 0
   Static _MinVersion := "3.6"
   ; ===================================================================================================================
   ; CLASS _Table
   ; Object returned from method GetTable()
   ; _Table is an independent object and does not need SQLite after creation at all.
   ; ===================================================================================================================
   Class _Table {
      ; ----------------------------------------------------------------------------------------------------------------
      ; CONSTRUCTOR  Create instance variables
      ; ----------------------------------------------------------------------------------------------------------------
      __New() {
          This.ColumnCount := 0          ; Number of columns in the result table         (Integer)
          This.RowCount := 0             ; Number of rows in the result table            (Integer)
          This.ColumnNames := []         ; Names of columns in the result table          (Array)
          This.Rows := []                ; Rows of the result table                      (Array of Arrays)
          This.HasNames := False         ; Does var ColumnNames contain names?           (Bool)
          This.HasRows := False          ; Does var Rows contain rows?                   (Bool)
          This._CurrentRow := 0          ; Row index of last returned row                (Integer)
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD GetRow      Get row for RowIndex
      ; Parameters:        RowIndex    - Index of the row to retrieve, the index of the first row is 1
      ;                    ByRef Row   - Variable to pass out the row array
      ; Return values:     On failure  - False
      ;                    On success  - True, Row contains a valid array
      ; Remarks:           _CurrentRow is set to RowIndex, so a subsequent call of NextRow() will return the
      ;                    following row.
      ; ----------------------------------------------------------------------------------------------------------------
      GetRow(RowIndex, &Row) {
         Row := ""
         If (RowIndex < 1 || RowIndex > This.RowCount)
            Return False
         If !This.Rows.Has(RowIndex)
            Return False
         Row := This.Rows[RowIndex]
         This._CurrentRow := RowIndex
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Next        Get next row depending on _CurrentRow
      ; Parameters:        ByRef Row   - Variable to pass out the row array
      ; Return values:     On failure  - False, -1 for EOR (end of rows)
      ;                    On success  - True, Row contains a valid array
      ; ----------------------------------------------------------------------------------------------------------------
      Next(&Row) {
         Row := ""
         If (This._CurrentRow >= This.RowCount)
            Return -1
         This._CurrentRow += 1
         If !This.Rows.Has(This._CurrentRow)
            Return False
         Row := This.Rows[This._CurrentRow]
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Reset       Reset _CurrentRow to zero
      ; Parameters:        None
      ; Return value:      True
      ; ----------------------------------------------------------------------------------------------------------------
      Reset() {
         This._CurrentRow := 0
         Return True
      }
   }
   ; ===================================================================================================================
   ; CLASS _Prepared
   ; Object returned from method Prepare()
   ; The life-cycle of a prepared statement object usually goes like this:
   ; 1. Create the prepared statement object (PST) by calling DB.Prepare().
   ; 2. Bind values to parameters using the PST.Bind() method of the statement object if needed.
   ; 3. Run the SQL by calling PST.Step() one or more times.
   ; 4. Reset the prepared statement using PTS.Reset() then go back to step 2. Do this zero or more times.
   ; 5. Destroy the object using PST.Free().
   ; The lifetime of a prepared statement depends on the lifetime of the related SQLiteDB object.
   ; The rows (records) of the result of a query statement can be fetched sequentially by successive calls of
   ; PST.Step(&Row)
   ; ===================================================================================================================
   Class _Prepared {
      ; ----------------------------------------------------------------------------------------------------------------
      ; CONSTRUCTOR  Create instance variables
      ; ----------------------------------------------------------------------------------------------------------------
      __New() {
         This.ColumnCount := 0         ; Number of columns in the result               (Integer)
         This.ColumnNames := []        ; Names of columns in the result                (Array)
         This.CurrentStep := 0         ; Index of current step                         (Integer)
         This.ErrorMsg := ""           ; Last error message                            (String)
         This.ErrorCode := 0           ; Last SQLite error code / ErrorLevel           (Variant)
         This._Handle := 0             ; Query handle                                  (Pointer)
         This._DB := {}                ; SQLiteDB object                               (Object)
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; DESTRUCTOR   Clear instance variables
      ; ----------------------------------------------------------------------------------------------------------------
      __Delete() {
         If This.HasOwnProp("_Handle") && (This._Handle != 0)
            This.Free()
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Bind        Bind values to SQL parameters.
      ; Parameters:        Params      -  Array of SQL parameters.
      ;                                   The index within the array determines the indes of the SQL parameter.
      ;                                   Each array element must be an associative array with one key/value pair:
      ;                                      Key   = one of the types defined below in Types
      ;                                      Value = type dependend value of the parameter
      ; Return values:     On success  - True
      ;                    On failure  - False, ErrorMsg / ErrorCode contain additional information
      ; ----------------------------------------------------------------------------------------------------------------
      Bind(Params) {
         Static Types := {Blob: 1, Double: 1, Int: 1, Int64: 1, Null: 1, Text: 1}
         Local Index, Param, ParamType, RC, UTF8, Value
         This.ErrorMsg := ""
         This.ErrorCode := 0
         If !(This._Handle) {
            This.ErrorMsg := "Invalid statement handle!"
            Return False
         }
         For Index, Param In Params {
            If (Index < 1) || (Index > This.ParamCount)
               Return This._SetError(0, "Invalid parameter index: " . Index . "!")
            For ParamType, Value In Param {
               If !Types.HasOwnProp(Type)
                  Return This._SetError(0, "Invalid parameter type " . ParamType . " at index " Index . "!")
               Switch ParamType {
                  Case "Blob":
                     ; Value = Buffer object
                     If !(ParamType(Value) = "Buffer")
                        Return This._SetError(0, "Invalid blob object at index " . Index . "!")
                     ; Let SQLite always create a copy of the BLOB
                     RC := DllCall("SQlite3.dll\sqlite3_bind_blob", "Ptr", This._Handle, "Int", Index, "Ptr", Value,
                                   "Int", Value.Size, "Ptr", -1, "Cdecl Int")
                     If (RC)
                        Return This._SetError(RC)
                  Case "Double":
                     ; Value = double value
                     If !IsFloat(Value)
                        Return This._SetError(0, "Invalid value for double at index " . Index . "!")
                     RC := DllCall("SQlite3.dll\sqlite3_bind_double", "Ptr", This._Handle, "Int", Index, "Double", Value,
                                   "Cdecl Int")
                     If (RC)
                        Return This._SetError(RC)
                  Case "Int":
                     ; Value = integer value
                     If !IsInteger(Value)
                        Return This._SetError(0, "Invalid value for int at index " . Index . "!")
                     RC := DllCall("SQlite3.dll\sqlite3_bind_int", "Ptr", This._Handle, "Int", Index, "Int", Value,
                                   "Cdecl Int")
                     If (RC)
                        Return This._SetError(RC)
                  Case "Int64":
                     ; Value = integer value
                     If !IsInteger(Value)
                        Return This._SetError(0, "Invalid value for int64 at index " . Index . "!")
                     RC := DllCall("SQlite3.dll\sqlite3_bind_int64", "Ptr", This._Handle, "Int", Index, "Int64", Value,
                                   "Cdecl Int")
                     If (RC)
                        Return This._SetError(RC)
                  Case "Null":
                     RC := DllCall("SQlite3.dll\sqlite3_bind_null", "Ptr", This._Handle, "Int", Index, "Cdecl Int")
                     If (RC)
                        Return This._SetError(RC)
                  Case "Text":
                     ; Value = zero-terminated string
                     UTF8 := This._DB._StrToUTF8(Value)
                     ; Let SQLite always create a copy of the text
                     RC := DllCall("SQlite3.dll\sqlite3_bind_text", "Ptr", This._Handle, "Int", Index, "Ptr", UTF8,
                                   "Int", -1, "Ptr", -1, "Cdecl Int")
                     If (RC)
                        Return This._SetError(RC)
               }
               Break
            }
         }
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Step        Execute the statement and get next row of the query result if available.
      ; Parameters:        Row         - Optional: VarRef to store the row array
      ; Return values:     On success  - True, Row contains the row array
      ;                    On failure  - False, ErrorMsg / ErrorCode contain additional information
      ;                                  -1 for EOR (end of records)
      ; ----------------------------------------------------------------------------------------------------------------
      Step(Row?) { ; !!!!! Note: If Row is not omitted is must be a VarRef !!!!!
         Static SQLITE_INTEGER := 1, SQLITE_FLOAT := 2, SQLITE_BLOB := 4, SQLITE_NULL := 5
         Static EOR := -1
         Local Blob, BlobPtr, BlobSize, Column, ColumnType, RC, Res, Value
         If IsSet(Row) && !(Row Is VarRef)
            Throw TypeError("Parameter #1 requires a variable reference, but received a" .
                            (Type(Row) ~= "i)^[aeiou]" ? "n " : " ") . Type(Row) ".", -1, Row)
         This.ErrorMsg := ""
         This.ErrorCode := 0
         If !(This._Handle)
            Return This._SetError(0, "Invalid query handle!")
         RC := DllCall("SQlite3.dll\sqlite3_step", "Ptr", This._Handle, "Cdecl Int")
         If (RC = This._DB._ReturnCode("SQLITE_DONE"))
            Return (This._SetError(RC, "EOR") | EOR)
         If (RC != This._DB._ReturnCode("SQLITE_ROW"))
            Return This._SetError(RC)
         This.CurrentStep += 1
         If !IsSet(Row)
            Return True
         Res := []
         RC := DllCall("SQlite3.dll\sqlite3_data_count", "Ptr", This._Handle, "Cdecl Int")
         If (RC < 1)
            Return True
         Res.Length := RC
         Loop RC {
            Column := A_Index - 1
            ColumnType := DllCall("SQlite3.dll\sqlite3_column_type", "Ptr", This._Handle, "Int", Column, "Cdecl Int")
            Switch ColumnType {
               Case SQLITE_BLOB:
                  BlobPtr := DllCall("SQlite3.dll\sqlite3_column_blob", "Ptr", This._Handle, "Int", Column, "Cdecl UPtr")
                  BlobSize := DllCall("SQlite3.dll\sqlite3_column_bytes", "Ptr", This._Handle, "Int", Column, "Cdecl Int")
                  If (BlobPtr = 0) || (BlobSize = 0)
                     Res[A_Index] := ""
                  Else {
                     Blob := Buffer(BlobSize)
                     DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", Blob, "Ptr", BlobPtr, "Ptr", BlobSize)
                     Res[A_Index] := Blob
                  }
               Case SQLITE_INTEGER:
                  Value := DllCall("SQlite3.dll\sqlite3_column_int64", "Ptr", This._Handle, "Int", Column, "Cdecl Int64")
                  Res[A_Index] := Value
               Case SQLITE_FLOAT:
                  Value := DllCall("SQlite3.dll\sqlite3_column_double", "Ptr", This._Handle, "Int", Column, "Cdecl Double")
                  Res[A_Index] := Value
               Case SQLITE_NULL:
                  Res[A_Index] := ""
               Default:
                  Value := DllCall("SQlite3.dll\sqlite3_column_text", "Ptr", This._Handle, "Int", Column, "Cdecl UPtr")
                  Res[A_Index] := StrGet(Value, "UTF-8")
            }
         }
         %Row% := Res
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Next        Alternative name for Step().
      ; Parameters:        Row         - Optional: VarRef to store the row array
      ; ----------------------------------------------------------------------------------------------------------------
      Next(Row?) { ; !!!!! Note: If Row is not omitted is must be a VarRef !!!!!
         If !IsSet(Row)
            Return This.Step()
         If Row Is VarRef
            Return This.Step(Row)
         Throw TypeError("Parameter #1 requires a variable reference, but received a" .
                         (Type(Row) ~= "i)^[aeiou]" ? "n " : " ") . Type(Row) ".", -1, Row)
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Reset       Reset result pointer of the prepared statement.
      ; Parameters:        ClearBindings  - Clear bound SQL parameter values (True/False)
      ; Return values:     On success     - True
      ;                    On failure     - False, ErrorMsg / ErrorCode contain additional information
      ; Remarks:           After a call of this method you can access the query result via Next() again.
      ; ----------------------------------------------------------------------------------------------------------------
      Reset(ClearBindings := True) {
         Local RC
         This.ErrorMsg := ""
         This.ErrorCode := 0
         If !(This._Handle)
            Return This._SetError(0, "Invalid query handle!")
         If (RC := DllCall("SQlite3.dll\sqlite3_reset", "Ptr", This._Handle, "Cdecl Int"))
            Return This._SetError(RC)
         If (ClearBindings) && (RC := DllCall("SQlite3.dll\sqlite3_clear_bindings", "Ptr", This._Handle, "Cdecl Int"))
            Return This._SetError(RC)
         This.CurrentStep := 0
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD Free        Free the prepared statement.
      ; Parameters:        None
      ; Return values:     On success  - True
      ;                    On failure  - False, ErrorMsg / ErrorCode contain additional information
      ; Remarks:           After the call of this method further access on the query result is impossible.
      ; ----------------------------------------------------------------------------------------------------------------
      Free() {
         Local RC
         This.ErrorMsg := ""
         This.ErrorCode := 0
         If !(This._Handle)
            Return True
         If (RC := DllCall("SQlite3.dll\sqlite3_finalize", "Ptr", This._Handle, "Cdecl Int"))
            Return This._SetError(RC)
         This._DB._Stmts.Delete(This._Handle)
         This._Handle := 0
         This._DB := 0
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; METHOD _SetError   Internally used for error handling
      ; Parameters:        RC - SQLite error code
      ;                    Msg - error message (optional), if omitted the SQLite error text will be set
      ; ----------------------------------------------------------------------------------------------------------------
      _SetError(RC, Msg?) {
         This.ErrorMsg := IsSet(Msg) ? Msg : This._DB._ErrMsg()
         This.ErrorCode := RC
         Return False
      }
   }
}
; ======================================================================================================================
; Exemplary custom callback function regexp()
; Parameters:        Context  -  handle to a sqlite3_context object
;                    ArgC     -  number of elements passed in Values (must be 2 for this function)
;                    Values   -  pointer to an array of pointers which can be passed to sqlite3_value_text():
;                                1. Needle
;                                2. Haystack
; Return values:     Call sqlite3_result_int() passing 1 (True) for a match, otherwise pass 0 (False).
; ======================================================================================================================
SQLiteDB_RegExp(Context, ArgC, Values) {
   Local AddrH, AddrN, Result := 0
   If (ArgC = 2) {
      AddrN := DllCall("SQLite3.dll\sqlite3_value_text", "Ptr", NumGet(Values + 0, "UPtr"), "Cdecl UPtr")
      AddrH := DllCall("SQLite3.dll\sqlite3_value_text", "Ptr", NumGet(Values + A_PtrSize, "UPtr"), "Cdecl UPtr")
      Result := RegExMatch(StrGet(AddrH, "UTF-8"), StrGet(AddrN, "UTF-8"))
   }
   DllCall("SQLite3.dll\sqlite3_result_int", "Ptr", Context, "Int", !!Result, "Cdecl") ; 0 = false, 1 = trus
}