#!/bin/bash

set -euxo pipefail

# Check if we have access to the output name.
env | grep 'duckdb-extension-'
env

# TODO: Retrieve the extension name dynamically.
EXTENSION_NAME='httpfs'

DUCKDB_ARCH="$(cat ./build/.duckdb_arch)"
DUCKDB_VERSION="v${PKG_VERSION}"

mkdir -p "${PREFIX}/duckdb/extensions/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"

cp "./build/repository/${DUCKDB_VERSION}/${DUCKDB_ARCH}/${EXTENSION_NAME}.duckdb_extension" "${PREFIX}/duckdb/extensions/${DUCKDB_VERSION}/${DUCKDB_ARCH}/"
