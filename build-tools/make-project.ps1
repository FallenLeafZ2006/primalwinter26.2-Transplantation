$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$srcRoot = Join-Path $root 'tmp_pw\primal-winter-HEAD'
$proj = Join-Path $root 'primal-winter-26.2'

New-Item -ItemType Directory -Force -Path $proj | Out-Null
foreach ($d in @('src\main\java', 'src\main\resources')) {
  $p = Join-Path $proj $d
  if (Test-Path $p) { Remove-Item $p -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}

function Copy-Tree($from, $to) {
  if (-not (Test-Path $from)) { return }
  robocopy $from $to /E /NFL /NDL /NJH /NJS /NC /NS | Out-Null
}

Copy-Tree (Join-Path $srcRoot 'Common\src\main\java')      (Join-Path $proj 'src\main\java')
Copy-Tree (Join-Path $srcRoot 'Fabric\src\main\java')      (Join-Path $proj 'src\main\java')
Copy-Tree (Join-Path $srcRoot 'Common\src\main\resources') (Join-Path $proj 'src\main\resources')
Copy-Tree (Join-Path $srcRoot 'Common\src\generated\resources') (Join-Path $proj 'src\main\resources')
Copy-Tree (Join-Path $srcRoot 'Fabric\src\main\resources') (Join-Path $proj 'src\main\resources')

$javaCount = (Get-ChildItem (Join-Path $proj 'src\main\java') -Recurse -Filter *.java).Count
$resCount = (Get-ChildItem (Join-Path $proj 'src\main\resources') -Recurse -File).Count
Write-Output "copied: $javaCount java files, $resCount resources"
Get-ChildItem (Join-Path $proj 'src\main\java\com\alcatrazescapee\primalwinter') | Select-Object Name | ForEach-Object { Write-Output "  $($_.Name)" }
