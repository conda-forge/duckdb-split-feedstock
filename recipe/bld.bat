python scripts/windows_ci.py
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_GENERATOR_PLATFORM=x64 \
    -DDUCKDB_EXTENSION_CONFIGS="$PWD/bundled_extensions.cmake" \
    -DDISABLE_UNITY=1 \
    -DOVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g2063dda \
    -DWITH_INTERNAL_ICU=OFF
cmake --build . --config Release --parallel
