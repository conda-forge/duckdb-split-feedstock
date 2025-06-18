#!/bin/bash

set -euxo pipefail

mkdir -p build
pushd build

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"

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

export OVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g2063dda

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/dist \
    -DOVERRIDE_GIT_DESCRIBE="$OVERRIDE_GIT_DESCRIBE" \
    -DDUCKDB_EXTENSION_CONFIGS="$PWD/../bundled_extensions.cmake" \
    -DWITH_INTERNAL_ICU=OFF \
    ..

ninja
ninja install
