#!/bin/bash

set -euxo pipefail

PKG_PREFIX='duckdb-extension-'
EXTENSION_NAME="${PKG_NAME#$PKG_PREFIX}"

QUERY="set extension_directory='${PREFIX}/duckdb/extensions'; select extension_name from duckdb_extensions() where (installed and install_path != '(BUILT-IN)');"
QUERY_RESULT="$(duckdb -json -c "${QUERY}")"

if [[ $("${QUERY_RESULT}" | jq -r '.[].extension_name') == "${EXTENSION_NAME}" ]]; then
    exit 0
else
    exit 1
fi
