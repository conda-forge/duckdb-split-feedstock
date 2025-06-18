@echo on

set OVERRIDE_GIT_DESCRIBE=v%PKG_VERSION%-0-g2063dda

:: This is the extension config that is used to build / test
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
echo duckdb_extension_load^(httpfs DONT_LINK^)
echo duckdb_extension_load^(fts DONT_LINK^)
) > "%CD%\bundled_extensions.cmake"

python scripts/windows_ci.py
cmake %CMAKE_ARGS% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_GENERATOR_PLATFORM=x64 ^
  -DDUCKDB_EXTENSION_CONFIGS="%CD%/bundled_extensions.cmake" ^
  -DDISABLE_UNITY=1 ^
  -DOVERRIDE_GIT_DESCRIBE="%OVERRIDE_GIT_DESCRIBE%"

cmake --build . --config Release --parallel
