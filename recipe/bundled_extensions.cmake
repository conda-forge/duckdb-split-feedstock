#
## Extensions that are linked
#
duckdb_extension_load(icu)
duckdb_extension_load(json)
duckdb_extension_load(parquet)
duckdb_extension_load(autocomplete)

#
## Extensions that are not linked
#
duckdb_extension_load(tpcds DONT_LINK)
duckdb_extension_load(tpch DONT_LINK)
duckdb_extension_load(httpfs DONT_LINK)
duckdb_extension_load(fts DONT_LINK)
