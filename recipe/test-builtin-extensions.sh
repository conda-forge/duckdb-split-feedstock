set -euxo pipefail

PKG_PREFIX='duckdb-extension-'
EXTENSION_NAME="${PKG_NAME#$PKG_PREFIX}"

if [[ "${target_platform}" == linux-* ]]; then
  # jemalloc is statically linked into DuckDB only on the Linux platform.
  EXPECTED_EXTENSIONS='"autocomplete", "core_functions", "icu", "jemalloc", "json", "parquet", "shell"'
else
  EXPECTED_EXTENSIONS='"autocomplete", "core_functions", "icu", "json", "parquet", "shell"'
fi

QUERY="select extension_name from duckdb_extensions() where (installed and install_mode = 'STATICALLY_LINKED');"

# Check that the built-in extensions are as expected.
duckdb -json -c "${QUERY}" | jq -r -e "
  map(.extension_name) as \$actual
  | ([${EXPECTED_EXTENSIONS}] | sort) as \$expected
  | (\$actual | sort) == \$expected
"
