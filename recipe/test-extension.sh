#!/bin/bash

set -euxo pipefail

PKG_PREFIX='duckdb-extension-'
EXTENSION_NAME="${PKG_NAME#$PKG_PREFIX}"

QUERY="select extension_name from duckdb_extensions() where (installed and install_mode != 'STATICALLY_LINKED');"
QUERY_RESULT="$(duckdb -json -c "${QUERY}")"

if [[ $(echo "${QUERY_RESULT}" | jq -r '.[].extension_name') == "${EXTENSION_NAME}" ]]; then
    QUERY="LOAD ${EXTENSION_NAME};"
    echo "Test whether the extension loads in unsigned mode"
    duckdb -unsigned -bail -json -c "${QUERY}"
    # FIXME: We cannot sign DuckDB extensions in conda-forge
    # echo "Test whether the extension loads in default mode"
    # duckdb -bail -json -c "${QUERY}"
else
    exit 1
fi
