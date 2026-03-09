#!/bin/bash

set -euxo pipefail

mkdir -p build
pushd build

# The trailing ; is important!
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17 -DEXTENSION_DIRECTORIES=~/.duckdb/extensions;$PREFIX/duckdb/extensions;"

if [[ "${target_platform}" == "linux-64" ]]; then
    DUCKDB_ARCH='linux_amd64'
elif [[ "${target_platform}" == "linux-ppc64le" ]]; then
    DUCKDB_ARCH='linux_ppc64le'
    export CFLAGS="${CXXFLAGS/-fno-plt/}"
    export CXXFLAGS="${CXXFLAGS/-fno-plt/}"
    export CMAKE_ARGS="${CMAKE_ARGS} -DDUCKDB_PLATFORM=linux_ppc64le -DDUCKDB_EXPLICIT_PLATFORM=linux_ppc64le"
elif [[ "${target_platform}" == "linux-aarch64" ]]; then
    DUCKDB_ARCH='linux_arm64'
elif [[ "${target_platform}" == "osx-64" ]]; then
    DUCKDB_ARCH='osx_amd64'
elif [[ "${target_platform}" == "osx-arm64" ]]; then
    DUCKDB_ARCH='osx_arm64'
    export CMAKE_ARGS="${CMAKE_ARGS} -DDUCKDB_PLATFORM=osx_arm64 -DDUCKDB_EXPLICIT_PLATFORM=osx_arm64"
else
    echo "Unknown target platform: ${target_platform}"
    exit 1
fi

# Persist DuckDB architecture for extension installation scripts.
echo "${DUCKDB_ARCH}" > "$(pwd)/.duckdb_arch"

export OPENSSL_ROOT_DIR="${PREFIX}"

# This is the extension config that is used to build / test
cat > $PWD/bundled_extensions.cmake <<EOF
#
## Extensions that are linked
#
duckdb_extension_load(icu)
duckdb_extension_load(json)
duckdb_extension_load(parquet)
duckdb_extension_load(autocomplete)

#
## Extensions that are not linked
#
duckdb_extension_load(tpcds DONT_LINK)
duckdb_extension_load(tpch DONT_LINK)

# https://github.com/duckdb/duckdb/blob/v1.5.0/.github/config/extensions/httpfs.cmake
duckdb_extension_load(httpfs
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-httpfs
    GIT_TAG 74f954001f3a740c909181b02259de6c7b942632
)

# https://github.com/duckdb/duckdb/blob/v1.5.0/.github/config/extensions/fts.cmake
duckdb_extension_load(fts
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-fts
    GIT_TAG 6814ec9a7d5fd63500176507262b0dbf7cea0095
)

# https://github.com/duckdb/duckdb/blob/v1.5.0/.github/config/extensions/ducklake.cmake
duckdb_extension_load(ducklake
    DONT_LINK
    GIT_URL https://github.com/duckdb/ducklake
    GIT_TAG 7ea15644fd5f5ff42b86b8a703c14172acc7b8bd
)
EOF

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/dist \
    -DOVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g3a3967a \
    -DDUCKDB_EXTENSION_CONFIGS="$PWD/bundled_extensions.cmake" \
    -DWITH_INTERNAL_ICU=OFF \
    ..

ninja
ninja install
