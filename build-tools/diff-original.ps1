$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$orig = Join-Path $root 'tmp_pw\primal-winter-HEAD'
$port = Join-Path $root 'primal-winter-26.2'

function Rel($base, $path) { return $path.Substring($base.Length + 1) }
function Map-Java($rel) {
  # Common/<...>/java/x  and  Fabric/src/main/java/x  both map to src/main/java/x
  if ($rel -match '^Common\\src\\main\\java\\(.*)$') { return "src\main\java\$($matches[1])" }
  if ($rel -match '^Fabric\\src\\main\\java\\(.*)$') { return "src\main\java\$($matches[1])" }
  return $null
}
function Map-Res($rel) {
  if ($rel -match '^Common\\src\\main\\resources\\(.*)$') { return "src\main\resources\$($matches[1])" }
  if ($rel -match '^Common\\src\\generated\\resources\\(.*)$') { return "src\main\resources\$($matches[1])" }
  if ($rel -match '^Fabric\\src\\main\\resources\\(.*)$') { return "src\main\resources\$($matches[1])" }
  return $null
}

$missing = New-Object System.Collections.Generic.List[string]
$changed = New-Object System.Collections.Generic.List[string]
$same = 0

$origFiles = Get-ChildItem $orig -Recurse -File | Where-Object { $_.FullName -notmatch '\\NeoForge\\' -and $_.FullName -notmatch '\\\.github\\' -and $_.FullName -notmatch '\\\.idea\\' -and $_.FullName -notmatch '\\img\\' -and $_.Extension -in '.java', '.json', '.ogg', '.png', '.mcmeta' }
foreach ($f in $origFiles) {
  $rel = Rel $orig $f.FullName
  $mapped = Map-Java $rel
  if (-not $mapped) { $mapped = Map-Res $rel }
  if (-not $mapped) { continue }
  $target = Join-Path $port $mapped
  if (-not (Test-Path $target)) { $missing.Add($mapped); continue }
  $a = (Get-FileHash $f.FullName -Algorithm MD5).Hash
  $b = (Get-FileHash $target -Algorithm MD5).Hash
  if ($a -ne $b) { $changed.Add($mapped) } else { $same++ }
}

Write-Output "=== 原版有、移植版没有 (deleted): $($missing.Count) ==="
$missing | ForEach-Object { "  - $_" }
Write-Output ""
Write-Output "=== 两边都有但内容不同 (modified): $($changed.Count) ==="
$changed | ForEach-Object { "  ~ $_" }
Write-Output ""
Write-Output "=== 完全相同: $same ==="
