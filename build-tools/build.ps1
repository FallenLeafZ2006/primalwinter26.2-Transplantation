param([switch]$All)
$ErrorActionPreference = 'Continue'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$proj = Join-Path $root 'primal-winter-26.2'
$javac = (Get-ChildItem (Join-Path $root 'toolchain\jdk25') -Recurse -Filter javac.exe | Select-Object -First 1).FullName
$cp = Get-Content (Join-Path $root 'libs\cp.txt') -Raw
$classes = Join-Path $proj 'build\classes'
if (Test-Path $classes) { Remove-Item $classes -Recurse -Force }
New-Item -ItemType Directory -Force -Path $classes | Out-Null

$files = Get-ChildItem (Join-Path $proj 'src\main\java') -Recurse -Filter *.java | ForEach-Object { $_.FullName }

$sw = [Diagnostics.Stopwatch]::StartNew()
$out = & $javac '-J-Duser.language=en' '-J-Duser.country=US' -encoding UTF-8 -nowarn -Xmaxerrs 2000 --release 25 -proc:none -cp $cp -d $classes $files 2>&1
$code = $LASTEXITCODE
$out | Set-Content -Path (Join-Path $proj 'build\javac.log') -Encoding UTF8

$errors = $out | Select-String -Pattern ': error:' -SimpleMatch
$warnings = $out | Select-String -Pattern ': warning:' -SimpleMatch
Write-Output "javac exit=$code  errors=$($errors.Count)  warnings=$($warnings.Count)  time=$([math]::Round($sw.Elapsed.TotalSeconds,1))s"
if ($errors.Count -gt 0) {
  Write-Output "--- error summary by file ---"
  $errors | ForEach-Object { ($_ -split ': error:')[0] } | Group-Object | Sort-Object Count -Descending | Select-Object -First 25 | ForEach-Object { Write-Output ("{0,4}x {1}" -f $_.Count, ($_.Name -replace [regex]::Escape($proj + '\src\main\java\'), '')) }
  Write-Output "--- first 40 errors ---"
  $errors | Select-Object -First 40 | ForEach-Object { Write-Output ($_.Line -replace [regex]::Escape($proj + '\src\main\java\'), '') }
}
if ($errors.Count -gt 0) {
  $first = ($out | Select-String -Pattern ': error:' -SimpleMatch | Select-Object -First 1)
  $start = [array]::IndexOf($out, $first.Line)
  if ($start -lt 0) { $start = 0 }
  Write-Output "--- detail dump ---"
  $i = 0
  while ($i -lt $out.Count -and $i -lt ($start + 120)) {
    $l = $out[$i] -replace [regex]::Escape($proj + '\src\main\java\com\alcatrazescapee\primalwinter\'), ''
    Write-Output $l
    $i++
  }
}
