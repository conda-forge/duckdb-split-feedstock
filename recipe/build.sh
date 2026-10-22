#!/bin/bash

set -euxo pipefail

mkdir -p build
pushd build

# c++std=23 is used upstream for DuckDB 2.0.0 and above.
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=23"
# quietly ignore deprecated warnings, as they are not actionable for us.
export CXXFLAGS="${CXXFLAGS} -Wno-deprecated-declarations"

DUCKDB_LINK_JOBS="${CPU_COUNT:-1}"
if (( DUCKDB_LINK_JOBS > 8 )); then
    DUCKDB_LINK_JOBS=8
fi

if [[ "${target_platform}" == linux-* ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DDUCKDB_LINKER=lld -DCMAKE_LTO=thin -DDUCKDB_RELEASE_LINK_JOBS=${DUCKDB_LINK_JOBS}"
elif [[ "${target_platform}" == osx-* ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DDUCKDB_RELEASE_LINK_JOBS=${DUCKDB_LINK_JOBS}"
fi

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
echo "v${PKG_VERSION}" > "$(pwd)/.duckdb_version"

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
duckdb_extension_statically_link(autocomplete)

#
## Extensions that are not linked
#
duckdb_extension_load(tpcds)
duckdb_extension_load(tpch)

# https://github.com/duckdb/duckdb/blob/v2.0.0/.github/config/extensions/httpfs.cmake
duckdb_extension_load(httpfs
    GIT_URL https://github.com/duckdb/duckdb-httpfs
    GIT_TAG 77392a72077a85897db2519fae11e2c0da972b8a
)

# https://github.com/duckdb/duckdb/blob/v2.0.0/.github/config/extensions/fts.cmake
duckdb_extension_load(fts
    GIT_URL https://github.com/duckdb/duckdb-fts
    GIT_TAG 2266e67d01c737cb65114e77c7c672e58869a635
    APPLY_PATCHES
)

# https://github.com/duckdb/duckdb/blob/v2.0.0/.github/config/extensions/ducklake.cmake
duckdb_extension_load(ducklake
    GIT_URL https://github.com/duckdb/ducklake
    GIT_TAG 417a9117f590e8141742ac0579d02f6a90162e37
    APPLY_PATCHES
)
EOF

cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/dist \
    -DOVERRIDE_GIT_DESCRIBE="v${PKG_VERSION}" \
    -DGIT_COMMIT_HASH="d54cbbe3df" \
    -DEXTENSION_DIRECTORIES="~/.duckdb/extensions;$PREFIX/duckdb/extensions;" \
    -DDUCKDB_EXTENSION_CONFIGS="$PWD/bundled_extensions.cmake" \
    ..

ninja -j"${CPU_COUNT}"
ninja install
