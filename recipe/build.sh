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

# This is the extension config that is used to build / test
cat > $PWD/bundled_extensions.cmake <<EOF
#
## Extensions that are linked
#
duckdb_extension_load(autocomplete)
duckdb_extension_load(icu)
duckdb_extension_load(json)
duckdb_extension_load(parquet)

#
## Extensions that are not linked
#
# https://github.com/duckdb/duckdb/blob/v1.4.3/.github/config/extensions/avro.cmake
duckdb_extension_load(avro
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-avro
    GIT_TAG 93da8a19b41eb577add83d0552c6946a16e97c83
)

# https://github.com/duckdb/duckdb/blob/v1.4.3/.github/config/extensions/aws.cmake
duckdb_extension_load(aws
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-aws
    GIT_TAG 55bf3621fb7db254b473c94ce6360643ca38fac0
)

# https://github.com/duckdb/duckdb/blob/v1.4.3/.github/config/extensions/ducklake.cmake
duckdb_extension_load(ducklake
    DONT_LINK
    GIT_URL https://github.com/duckdb/ducklake
    GIT_TAG de813ff4d052bffe3e9e7ffcdc31d18ca38e5ecd
)

# https://github.com/duckdb/duckdb/blob/v1.4.3/.github/config/extensions/fts.cmake
duckdb_extension_load(fts
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-fts
    GIT_TAG 39376623630a968154bef4e6930d12ad0b59d7fb
)

# https://github.com/duckdb/duckdb/blob/v1.4.3/.github/config/extensions/httpfs.cmake
duckdb_extension_load(httpfs
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-httpfs
    GIT_TAG 9c7d34977b10346d0b4cbbde5df807d1dab0b2bf
    INCLUDE_DIR src/include
)

# https://github.com/duckdb/duckdb/blob/v1.4.3/.github/config/extensions/iceberg.cmake
duckdb_extension_load(iceberg
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-iceberg
    GIT_TAG 1c0c4c60818f58b603fc50d5267b1f1202fe5484
)

duckdb_extension_load(tpcds DONT_LINK)
duckdb_extension_load(tpch DONT_LINK)
EOF

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/dist \
    -DOVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g68d7555 \
    -DDUCKDB_EXTENSION_CONFIGS="$PWD/bundled_extensions.cmake" \
    -DWITH_INTERNAL_ICU=OFF \
    ..

ninja
ninja install
