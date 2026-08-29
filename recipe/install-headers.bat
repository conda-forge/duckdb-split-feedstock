@echo on
setlocal EnableExtensions

cmake -E make_directory "%LIBRARY_INC%" "%LIBRARY_LIB%" "%LIBRARY_LIB%\cmake\DuckDB"
if errorlevel 1 exit /b 1

cmake -E copy_directory "build\dist\include" "%LIBRARY_INC%"
if errorlevel 1 exit /b 1

cmake -E copy_if_different "build\dist\lib\duckdb.lib" "%LIBRARY_LIB%\duckdb.lib"
if errorlevel 1 exit /b 1

cmake -E copy_directory "build\dist\lib\cmake\DuckDB" "%LIBRARY_LIB%\cmake\DuckDB"
if errorlevel 1 exit /b 1
