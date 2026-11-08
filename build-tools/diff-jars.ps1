$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Entries($path) {
  $z = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $path))
  $list = $z.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | Select-Object -ExpandProperty FullName
  $z.Dispose()
  return $list
}

$released = Entries '.\research\primalwinter-6.0.2-fabric.jar'
$port = Entries '.\primalwinter-1.0.0+26.2.jar'

$relSet = New-Object System.Collections.Generic.HashSet[string]
$portSet = New-Object System.Collections.Generic.HashSet[string]
$released | ForEach-Object { [void]$relSet.Add($_) }
$port | ForEach-Object { [void]$portSet.Add($_) }

function Report($title, $filter) {
  Write-Output "=== $title ==="
  $a = $released | Where-Object { $_ -like $filter -and -not $portSet.Contains($_) }
  $b = $port | Where-Object { $_ -like $filter -and -not $relSet.Contains($_) }
  Write-Output "-- 原版有、我们没有 ($($a.Count))"
  $a | Select-Object -First 60 | ForEach-Object { "   - $_" }
  Write-Output "-- 我们有、原版没有 ($($b.Count))"
  $b | Select-Object -First 60 | ForEach-Object { "   + $_" }
  Write-Output ""
}

Report '类文件 com/alcatrazescapee' 'com/alcatrazescapee/*'
Report '资源 assets/' 'assets/*'
Report '数据 data/' 'data/*'
Write-Output "=== 总条目数 ==="
"released=$($released.Count)  port=$($port.Count)"
