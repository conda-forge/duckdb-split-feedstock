param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$bytes = [System.IO.File]::ReadAllBytes($Path)
if ($bytes.Length -lt 64) {
    throw "$Path is too small to be a PE binary"
}

$peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
$machine = [System.BitConverter]::ToUInt16($bytes, $peOffset + 4)
$expectedMachine = 0xaa64

if ($machine -ne $expectedMachine) {
    throw ('Expected ARM64 machine 0x{0:x4} for {1}, got 0x{2:x4}' -f $expectedMachine, $Path, $machine)
}

Write-Host ('Verified ARM64 PE machine 0x{0:x4}: {1}' -f $machine, $Path)
