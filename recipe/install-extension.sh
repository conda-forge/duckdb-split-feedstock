#!/bin/bash

set -euxo pipefail

PKG_PREFIX='duckdb-extension-'
EXTENSION_NAME="${PKG_NAME#$PKG_PREFIX}"

DUCKDB_ARCH="$(cat ./build/.duckdb_arch)"
DUCKDB_VERSION="v${PKG_VERSION}"

mkdir -p "${PREFIX}/duckdb/extensions/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"

ls -lha "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"

if [[ "${target_platform}" == "osx-arm64" ]]; then
  python $RECIPE_DIR/fix-linkedit-segments.py "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/${EXTENSION_NAME}.duckdb_extension"
  codesign -s - -f "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/${EXTENSION_NAME}.duckdb_extension"
fi
cp "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/${EXTENSION_NAME}.duckdb_extension" "${PREFIX}/duckdb/extensions/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"
