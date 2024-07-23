#!/bin/bash

set -euxo pipefail

mkdir -p build
pushd build

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

BUILD_EXTENSIONS='json;httpfs;autocomplete;fts;icu;inet;tpcds;tpch'
# We skip the parquet extension because it's compiled into libduckdb by default.
SKIP_EXTENSIONS='parquet;jemalloc'

export OPENSSL_ROOT_DIR="${PREFIX}"

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/dist \
    -DOVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g4a89d97 \
    -DBUILD_EXTENSIONS="${BUILD_EXTENSIONS}" \
    -DSKIP_EXTENSIONS="${SKIP_EXTENSIONS}" \
    -DDISABLE_BUILTIN_EXTENSIONS=ON \
    ..

ninja
ninja install
