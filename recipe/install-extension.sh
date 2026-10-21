#!/bin/bash

set -euxo pipefail

PKG_PREFIX='duckdb-extension-'
EXTENSION_NAME="${PKG_NAME#$PKG_PREFIX}"

DUCKDB_ARCH="$(head -n 1 ./build/duckdb_platform_out)"
DUCKDB_VERSION="v${PKG_VERSION}"

mkdir -p "${PREFIX}/duckdb/extensions/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"

ls -lha "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"

cp "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/${EXTENSION_NAME}.duckdb_extension" "${PREFIX}/duckdb/extensions/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"
