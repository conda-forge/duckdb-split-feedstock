@echo on
setlocal EnableExtensions

if not "%TARGET_PLATFORM%" == "win-arm64" (
  echo Unsupported Windows target: %TARGET_PLATFORM%
  exit /b 1
)

set "SRC_DIR_FORWARD=%CD:\=/%"
set "LIBRARY_PREFIX_FORWARD=%LIBRARY_PREFIX:\=/%"
set "DUCKDB_ARCH=windows_arm64"
set "DUCKDB_PLATFORM_ARGS=-DDUCKDB_EXPLICIT_PLATFORM=%DUCKDB_ARCH% -DDUCKDB_CUSTOM_PLATFORM=%DUCKDB_ARCH%"
set "CL=%CL% /bigobj"

if not exist build mkdir build
echo %DUCKDB_ARCH%> build\.duckdb_arch

(
echo #
echo ## Extensions that are linked
echo #
echo duckdb_extension_load^(icu^)
echo duckdb_extension_load^(json^)
echo duckdb_extension_load^(parquet^)
echo duckdb_extension_load^(autocomplete^)
echo.
echo #
echo ## Extensions that are not linked
echo #
echo duckdb_extension_load^(tpcds DONT_LINK^)
echo duckdb_extension_load^(tpch DONT_LINK^)
echo.
echo duckdb_extension_load^(httpfs
echo     DONT_LINK
echo     GIT_URL https://github.com/duckdb/duckdb-httpfs
echo     GIT_TAG 827222fb45a043a7a852d1f7aae46901492a3cda
echo ^)
echo.
echo duckdb_extension_load^(fts
echo     DONT_LINK
echo     GIT_URL https://github.com/duckdb/duckdb-fts
echo     GIT_TAG 6814ec9a7d5fd63500176507262b0dbf7cea0095
echo ^)
echo.
echo duckdb_extension_load^(ducklake
echo     DONT_LINK
echo     GIT_URL https://github.com/duckdb/ducklake
echo     GIT_TAG d8a1881e22516ea3d186d73e83c65fe5bd1a1dc4
echo ^)
) > build\bundled_extensions.cmake

"%PYTHON%" scripts\windows_ci.py
if errorlevel 1 exit /b 1

cmake -S . -B build -G Ninja %CMAKE_ARGS% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_CXX_STANDARD=17 ^
  -DCMAKE_INSTALL_PREFIX=%SRC_DIR_FORWARD%/build/dist ^
  -DINSTALL_CMAKE_DIR=lib/cmake/DuckDB ^
  -DDUCKDB_EXTENSION_CONFIGS=%SRC_DIR_FORWARD%/build/bundled_extensions.cmake ^
  -DEXTENSION_DIRECTORIES="~/.duckdb/extensions;%LIBRARY_PREFIX_FORWARD%/duckdb/extensions;" ^
  -DOPENSSL_ROOT_DIR=%LIBRARY_PREFIX_FORWARD% ^
  -DWITH_INTERNAL_ICU=OFF ^
  -DBUILD_UNITTESTS=FALSE ^
  -DDISABLE_UNITY=1 ^
  -DOVERRIDE_GIT_DESCRIBE=v%PKG_VERSION%-0-gd8cdaa33fd ^
  %DUCKDB_PLATFORM_ARGS%
if errorlevel 1 exit /b 1

cmake --build build --parallel %CPU_COUNT%
if errorlevel 1 exit /b 1

cmake --install build
if errorlevel 1 exit /b 1
