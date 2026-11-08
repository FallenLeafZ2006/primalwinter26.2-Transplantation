$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$libs = 'D:\.minecraft\libraries'
$versionJson = 'D:\.minecraft\versions\26.2-Fabric 0.20.1\26.2-Fabric 0.20.1.json'
$clientJar = 'D:\.minecraft\versions\26.2-Fabric 0.20.1\26.2-Fabric 0.20.1.jar'

$out = Join-Path $root 'libs'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$jars = New-Object System.Collections.Generic.List[string]
$jars.Add((Resolve-Path $clientJar).Path)

$json = Get-Content $versionJson -Raw | ConvertFrom-Json
$missing = @()
foreach ($lib in $json.libraries) {
  $path = $null
  if ($lib.downloads -and $lib.downloads.artifact -and $lib.downloads.artifact.path) { $path = $lib.downloads.artifact.path }
  elseif ($lib.name) {
    $parts = $lib.name -split ':'
    if ($parts.Count -ge 3) {
      $group = $parts[0] -replace '\.', '/'
      $path = "$group/$($parts[1])/$($parts[2])/$($parts[1])-$($parts[2]).jar"
    }
  }
  if (-not $path) { continue }
  $full = Join-Path $libs $path
  if (Test-Path $full) { $jars.Add((Resolve-Path $full).Path) } else { $missing += $path }
}
Write-Output "version-json jars: $($jars.Count), missing: $($missing.Count)"
$missing | Select-Object -First 10 | ForEach-Object { Write-Output "  missing $_" }

# Fabric API nested modules
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fapiDir = Join-Path $out 'fabric-api'
if (Test-Path $fapiDir) { Remove-Item $fapiDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $fapiDir | Out-Null
$fapi = Join-Path $out 'fabric-api-0.161.0+26.2.jar'
$z = [IO.Compression.ZipFile]::OpenRead($fapi)
$n = 0
foreach ($e in $z.Entries) {
  if ($e.FullName -like 'META-INF/jars/*.jar') {
    $target = Join-Path $fapiDir ([IO.Path]::GetFileName($e.FullName))
    [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
    $jars.Add($target); $n++
  }
}
$z.Dispose()
Write-Output "fabric-api modules extracted: $n"

# loader
$jars.Add((Resolve-Path (Join-Path $out 'fabric-loader-0.20.1.jar')).Path)

# epsilon config library
$eps = Join-Path $out 'epsilon-0.6.jar'
if (-not (Test-Path $eps)) {
  try {
    (New-Object System.Net.WebClient).DownloadFile('https://alcatrazescapee.com/maven/com/alcatrazescapee/epsilon/0.6/epsilon-0.6.jar', $eps)
    Write-Output "epsilon downloaded: $([math]::Round((Get-Item $eps).Length/1KB,1)) KB"
  } catch { Write-Output "epsilon FAIL: $($_.Exception.Message)" }
}
if (Test-Path $eps) { $jars.Add((Resolve-Path $eps).Path) }

# loader + its nested jars (mixinextras)
$loader = Join-Path $out 'fabric-loader-0.20.1.jar'
$jars.Add((Resolve-Path $loader).Path)
$loaderDir = Join-Path $out 'loader-nested'
if (Test-Path $loaderDir) { Remove-Item $loaderDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $loaderDir | Out-Null
$z = [IO.Compression.ZipFile]::OpenRead($loader)
$n = 0
foreach ($e in $z.Entries) {
  if ($e.FullName -like 'META-INF/jars/*.jar') {
    $target = Join-Path $loaderDir ([IO.Path]::GetFileName($e.FullName))
    [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
    $jars.Add($target); $n++
  }
}
$z.Dispose()
Write-Output "loader nested jars: $n"

# small compile-time libraries
$extra = @(
  @{ f = 'annotations-23.0.0.jar'; u = 'https://maven.aliyun.com/repository/public/org/jetbrains/annotations/23.0.0/annotations-23.0.0.jar' },
  @{ f = 'jsr305-3.0.2.jar';       u = 'https://maven.aliyun.com/repository/public/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2.jar' }
)
foreach ($x in $extra) {
  $p = Join-Path $out $x.f
  if (-not (Test-Path $p)) {
    try { (New-Object System.Net.WebClient).DownloadFile($x.u, $p); Write-Output "downloaded $($x.f)" } catch { Write-Output "FAIL $($x.f): $($_.Exception.Message)" }
  }
  if (Test-Path $p) { $jars.Add((Resolve-Path $p).Path) }
}

$cp = ($jars | Select-Object -Unique) -join ';'
Set-Content -Path (Join-Path $out 'cp.txt') -Value $cp -Encoding Default
Write-Output "classpath entries: $($jars.Count)  -> libs/cp.txt"
