param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$bytes = [System.IO.File]::ReadAllBytes($Path)
if ($bytes.Length -lt 64) {
    throw "$Path is too small to be a PE binary"
}
if ($bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) {
    throw "$Path does not have an MZ header"
}

$peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
if ($peOffset -lt 0 -or $peOffset + 6 -gt $bytes.Length) {
    throw "$Path has an invalid PE header offset"
}
if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or
    $bytes[$peOffset + 2] -ne 0 -or $bytes[$peOffset + 3] -ne 0) {
    throw "$Path does not have a PE signature"
}

$machine = [System.BitConverter]::ToUInt16($bytes, $peOffset + 4)
$expectedMachine = 0xaa64

if ($machine -ne $expectedMachine) {
    throw ('Expected ARM64 machine 0x{0:x4} for {1}, got 0x{2:x4}' -f $expectedMachine, $Path, $machine)
}

Write-Host ('Verified ARM64 PE machine 0x{0:x4}: {1}' -f $machine, $Path)
