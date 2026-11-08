$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$proj = Join-Path $root 'primal-winter-26.2'
$jar = (Get-ChildItem (Join-Path $root 'toolchain\jdk25') -Recurse -Filter jar.exe | Select-Object -First 1).FullName
$classes = Join-Path $proj 'build\classes'
$res = Join-Path $proj 'src\main\resources'
$outJar = Join-Path $proj 'build\primalwinter-1.0.0+26.2.jar'

# 1. compile
& (Join-Path $PSScriptRoot 'build.ps1') | Out-Null
if (-not (Test-Path $classes)) { throw "classes dir missing" }

# 2. bundle epsilon (shaded config library)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$eps = Join-Path $root 'libs\epsilon-0.6.jar'
$z = [IO.Compression.ZipFile]::OpenRead($eps)
foreach ($e in $z.Entries) {
  if ($e.FullName -like '*.class') {
    $target = Join-Path $classes ($e.FullName -replace '/', '\')
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
  }
}
$z.Dispose()

# 3. copy resources over classes dir (jar layout)
$staging = Join-Path $proj 'build\jarroot'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
robocopy $classes $staging /E /NFL /NDL /NJH /NJS /NC /NS | Out-Null
robocopy $res $staging /E /NFL /NDL /NJH /NJS /NC /NS | Out-Null

# 4. build jar
if (Test-Path $outJar) { Remove-Item $outJar -Force }
Push-Location $staging
& $jar --create --file $outJar --main-class none .
Pop-Location

$size = [math]::Round((Get-Item $outJar).Length / 1MB, 2)
Write-Output "JAR: $outJar ($size MB)"

# 5. sanity check contents
$z = [IO.Compression.ZipFile]::OpenRead($outJar)
$entries = $z.Entries.Count
$hasEntry = ($z.Entries | Where-Object { $_.FullName -eq 'com/alcatrazescapee/primalwinter/FabricPrimalWinter.class' }).Count
$hasMeta = ($z.Entries | Where-Object { $_.FullName -eq 'fabric.mod.json' }).Count
$hasMixin = ($z.Entries | Where-Object { $_.FullName -eq 'primalwinter.mixins.json' }).Count
$hasEpsilon = ($z.Entries | Where-Object { $_.FullName -like 'com/alcatrazescapee/epsilon/*' }).Count
$hasAssets = ($z.Entries | Where-Object { $_.FullName -like 'assets/primalwinter/*' }).Count
$hasData = ($z.Entries | Where-Object { $_.FullName -like 'data/primalwinter/*' }).Count
$z.Dispose()
Write-Output "entries=$entries entrypoint=$hasEntry fabric.mod.json=$hasMeta mixins=$hasMixin epsilon=$hasEpsilon assets=$hasAssets data=$hasData"
