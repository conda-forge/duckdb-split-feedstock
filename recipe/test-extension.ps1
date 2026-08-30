param(
    [Parameter(Mandatory = $true)]
    [string]$ExtensionName
)

$extensionPath = Join-Path $env:LIBRARY_PREFIX "duckdb\extensions\v$env:PKG_VERSION\windows_arm64\$ExtensionName.duckdb_extension"
if (-not (Test-Path $extensionPath)) {
    throw "Missing packaged extension: $extensionPath"
}

& "$PSScriptRoot\test-pe.ps1" $extensionPath
$extensionSqlPath = $extensionPath.Replace('\', '/').Replace("'", "''")
& duckdb -unsigned -bail -c "load '$extensionSqlPath';"
if ($LASTEXITCODE -ne 0) {
    throw "DuckDB failed to load the packaged $ExtensionName extension"
}

& duckdb -unsigned -bail -c "load $ExtensionName;"
if ($LASTEXITCODE -ne 0) {
    throw "DuckDB failed to discover $ExtensionName in the conda extension directory"
}
