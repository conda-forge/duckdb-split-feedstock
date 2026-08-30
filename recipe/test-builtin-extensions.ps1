$query = "select extension_name from duckdb_extensions() where installed and install_mode = 'STATICALLY_LINKED';"
$json = (& duckdb -json -c $query) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    throw "DuckDB failed to list built-in extensions"
}

$actual = @($json | ConvertFrom-Json | ForEach-Object { $_.extension_name } | Sort-Object)
$expected = @('autocomplete', 'core_functions', 'icu', 'json', 'parquet', 'shell') | Sort-Object
if ($actual.Count -ne $expected.Count -or
    (Compare-Object -ReferenceObject $expected -DifferenceObject $actual)) {
    throw "Unexpected built-in extensions: $($actual -join ', ')"
}

& duckdb -bail -c "select 42 as answer;"
if ($LASTEXITCODE -ne 0) {
    throw "DuckDB CLI smoke query failed"
}
