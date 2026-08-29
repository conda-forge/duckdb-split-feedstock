@echo on
setlocal EnableExtensions

cmake -E make_directory "%LIBRARY_BIN%"
if errorlevel 1 exit /b 1

cmake -E copy_if_different "build\dist\bin\duckdb.exe" "%LIBRARY_BIN%\duckdb.exe"
if errorlevel 1 exit /b 1
