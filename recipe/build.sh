#!/bin/bash

set -euxo pipefail

mkdir -p build
pushd build
cmake ${CMAKE_ARGS} -GNinja -DCMAKE_INSTALL_PREFIX=$(pwd)/dist -DDUCKDB_FORCE_VERSION=$PKG_VERSION ..
ninja
ninja install
