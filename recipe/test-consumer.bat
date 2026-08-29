@echo on
setlocal EnableExtensions

cl /nologo /W4 /I"%LIBRARY_INC%" "%RECIPE_DIR%\test-duckdb.c" ^
  /link /LIBPATH:"%LIBRARY_LIB%" duckdb.lib /OUT:test-duckdb.exe
if errorlevel 1 exit /b 1

test-duckdb.exe
if errorlevel 1 exit /b 1
