@echo on
setlocal EnableExtensions

set "EXTENSION_NAME=%PKG_NAME:duckdb-extension-=%"
set /p DUCKDB_ARCH=<build\.duckdb_arch
set "DUCKDB_VERSION=v%PKG_VERSION%"
set "EXTENSION_DIR=%LIBRARY_PREFIX%\duckdb\extensions\%DUCKDB_VERSION%\%DUCKDB_ARCH%"
set "EXTENSION_SOURCE=build\repository\%DUCKDB_VERSION%\%DUCKDB_ARCH%\%EXTENSION_NAME%.duckdb_extension"

cmake -E make_directory "%EXTENSION_DIR%"
if errorlevel 1 exit /b 1

cmake -E copy_if_different "%EXTENSION_SOURCE%" "%EXTENSION_DIR%\%EXTENSION_NAME%.duckdb_extension"
if errorlevel 1 exit /b 1
