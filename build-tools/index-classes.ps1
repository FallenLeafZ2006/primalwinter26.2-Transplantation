$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$cp = (Get-Content (Join-Path $root 'libs\cp.txt') -Raw).Trim() -split ';'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$lines = New-Object System.Collections.Generic.List[string]
foreach ($jar in $cp) {
  if (-not (Test-Path $jar)) { continue }
  try {
    $z = [IO.Compression.ZipFile]::OpenRead($jar)
    foreach ($e in $z.Entries) {
      if ($e.FullName -like '*.class' -and $e.FullName -notlike 'META-INF/*') { $lines.Add($e.FullName) }
    }
    $z.Dispose()
  } catch { }
}
$lines | Sort-Object -Unique | Set-Content -Path (Join-Path $root 'libs\classindex.txt') -Encoding ASCII
Write-Output "class index entries: $($lines.Count)"

# epsilon contents
Write-Output "=== epsilon ==="
$eps = Join-Path $root 'libs\epsilon-0.6.jar'
if (Test-Path $eps) {
  $z = [IO.Compression.ZipFile]::OpenRead($eps)
  $z.Entries | Select-Object -First 15 -ExpandProperty FullName
  $z.Dispose()
}

# mixinextras in loader
Write-Output "=== loader jar: mixinextras / nested ==="
$z = [IO.Compression.ZipFile]::OpenRead((Join-Path $root 'libs\fabric-loader-0.20.1.jar'))
$z.Entries | Where-Object { $_.FullName -match 'mixinextras|META-INF/jars' } | Select-Object -First 20 -ExpandProperty FullName
$z.Dispose()

# fabric api packages
Write-Output "=== fabric-api packages (net/fabricmc/fabric/api/*) ==="
$mods = Get-ChildItem (Join-Path $root 'libs\fabric-api') -Filter *.jar
$pkgs = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in $mods) {
  try {
    $z = [IO.Compression.ZipFile]::OpenRead($m.FullName)
    foreach ($e in $z.Entries) {
      if ($e.FullName -match '^(net/fabricmc/fabric/api/[^/]+/[^/]+)/') { [void]$pkgs.Add($matches[1]) }
    }
    $z.Dispose()
  } catch { }
}
$pkgs | Sort-Object | ForEach-Object { Write-Output $_ }
