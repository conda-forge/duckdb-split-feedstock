#!/bin/bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Stage spatial patch where DuckDB's APPLY_PATCHES mechanism expects it.
SPATIAL_PATCH_NAME="0001-Use-standard-CMake-SQLite3-package.patch"
SPATIAL_PATCH_BASE="${RECIPE_DIR:-${SCRIPT_DIR}}"
SPATIAL_PATCH_SRC="${SPATIAL_PATCH_BASE}/patches/extensions/spatial/${SPATIAL_PATCH_NAME}"
if [[ ! -f "${SPATIAL_PATCH_SRC}" ]]; then
    SPATIAL_PATCH_SRC="${SCRIPT_DIR}/patches/${SPATIAL_PATCH_NAME}"
fi
if [[ ! -f "${SPATIAL_PATCH_SRC}" ]]; then
    echo "Could not find spatial patch file: ${SPATIAL_PATCH_NAME}" >&2
    exit 1
fi
SPATIAL_PATCH_DST_DIR="../.github/patches/extensions/spatial"
mkdir -p "${SPATIAL_PATCH_DST_DIR}"
cp "${SPATIAL_PATCH_SRC}" "${SPATIAL_PATCH_DST_DIR}/${SPATIAL_PATCH_NAME}"

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

# https://github.com/duckdb/duckdb/blob/v1.5.3/.github/config/extensions/httpfs.cmake
duckdb_extension_load(httpfs
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-httpfs
    GIT_TAG 52afb4204a3238d6ee132e83340f8d68c40ee91c
)

# https://github.com/duckdb/duckdb/blob/v1.5.3/.github/config/extensions/fts.cmake
duckdb_extension_load(fts
    DONT_LINK
    GIT_URL https://github.com/duckdb/duckdb-fts
    GIT_TAG 6814ec9a7d5fd63500176507262b0dbf7cea0095
)

# https://github.com/duckdb/duckdb/blob/v1.5.3/.github/config/extensions/ducklake.cmake
duckdb_extension_load(ducklake
    DONT_LINK
    GIT_URL https://github.com/duckdb/ducklake
    GIT_TAG e6a3bd0a8554b74d97cbc7e8acc3e2c9f01a0385
)

# https://github.com/duckdb/duckdb/blob/v1.5.3/.github/config/extensions/spatial.cmake
duckdb_extension_load(spatial
    DONT_LINK LOAD_TESTS
    GIT_URL https://github.com/duckdb/duckdb-spatial
    GIT_TAG b68b309d371dba936c5bb362980e559b7756b16d
    INCLUDE_DIR src/spatial
    TEST_DIR test/sql
    APPLY_PATCHES
    )
EOF

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/dist \
    -DOVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g14eca11 \
    -DDUCKDB_EXTENSION_CONFIGS="$PWD/bundled_extensions.cmake" \
    -DWITH_INTERNAL_ICU=OFF \
    ..

ninja
ninja install
