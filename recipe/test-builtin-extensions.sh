set -euxo pipefail

PKG_PREFIX='duckdb-extension-'
EXTENSION_NAME="${PKG_NAME#$PKG_PREFIX}"

# jemalloc is statically linked into DuckDB only on the Linux platform. Skip it here for simplicity.
QUERY="select extension_name from duckdb_extensions() where (installed and install_mode = 'STATICALLY_LINKED' and extension_name <> 'jemalloc');"

# Check that the built-in extensions are as expected.
duckdb -json -c "${QUERY}" | jq -r -e '
  map(.extension_name) as $actual
  | (["autocomplete", "core_functions", "icu", "json", "parquet", "shell"] | sort) as $expected
  | ($actual | sort) == $expected
'
