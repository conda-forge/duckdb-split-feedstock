#!/bin/bash

set -euxo pipefail

mkdir -p build
pushd build

if [[ "${target_platform}" == "osx-arm64" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DDUCKDB_PLATFORM=osx_arm64 -DDUCKDB_EXPLICIT_PLATFORM=osx_arm64"
elif [[ "${target_platform}" == "linux-ppc64le" ]]; then
  export CFLAGS="${CXXFLAGS/-fno-plt/}"
  export CXXFLAGS="${CXXFLAGS/-fno-plt/}"
  export CMAKE_ARGS="${CMAKE_ARGS} -DDUCKDB_PLATFORM=linux_ppc64le -DDUCKDB_EXPLICIT_PLATFORM=linux_ppc64le"
fi

cmake ${CMAKE_ARGS} -GNinja -DCMAKE_INSTALL_PREFIX=$(pwd)/dist -DOVERRIDE_GIT_DESCRIBE=v$PKG_VERSION-0-g4a89d97 ..

ninja
ninja install
