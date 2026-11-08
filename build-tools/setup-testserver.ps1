$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$ts = Join-Path $root 'testserver'
$bundle = Join-Path $ts 'bundle'
$run = Join-Path $ts 'run'
$L = 'D:\.minecraft\libraries'

if (-not (Test-Path (Join-Path $bundle 'META-INF'))) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $ts 'server.jar'), $bundle)
}
New-Item -ItemType Directory -Force -Path $run | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $run 'mods') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ts 'extras') | Out-Null

$cp = New-Object System.Collections.Generic.List[string]
Get-ChildItem (Join-Path $bundle 'META-INF\libraries') -Recurse -Filter *.jar | ForEach-Object { $cp.Add($_.FullName) }
$serverJar = Join-Path $bundle 'META-INF\versions\26.2\server-26.2.jar'
$cp.Add($serverJar)

$deps = @(
  "$L\net\fabricmc\fabric-loader\0.20.1\fabric-loader-0.20.1.jar",
  "$L\net\fabricmc\sponge-mixin\0.17.5+mixin.0.8.7\sponge-mixin-0.17.5+mixin.0.8.7.jar",
  "$L\org\ow2\asm\asm\9.9.1\asm-9.9.1.jar",
  "$L\org\ow2\asm\asm-analysis\9.9.1\asm-analysis-9.9.1.jar",
  "$L\org\ow2\asm\asm-commons\9.9.1\asm-commons-9.9.1.jar",
  "$L\org\ow2\asm\asm-tree\9.9.1\asm-tree-9.9.1.jar",
  "$L\org\ow2\asm\asm-util\9.9.1\asm-util-9.9.1.jar"
)
foreach ($d in $deps) {
  if (Test-Path $d) { $cp.Add($d); Write-Output "dep: $(Split-Path $d -Leaf)" } else { Write-Output "MISSING: $d" }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead($deps[0])
foreach ($e in $z.Entries) {
  if ($e.FullName -like 'META-INF/jars/*.jar') {
    $t = Join-Path $ts ('extras\' + [IO.Path]::GetFileName($e.FullName))
    [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $t, $true)
    $cp.Add($t); Write-Output "nested: $(Split-Path $t -Leaf)"
  }
}
$z.Dispose()

Set-Content -Path (Join-Path $ts 'cp.txt') -Value (($cp | Select-Object -Unique) -join ';') -Encoding Default
Set-Content -Path (Join-Path $run 'fabric-server-launcher.properties') -Value ("serverJar=" + $serverJar) -Encoding ASCII
Set-Content -Path (Join-Path $run 'eula.txt') -Value 'eula=true' -Encoding ASCII
@'
online-mode=false
level-name=world
max-players=1
view-distance=6
simulation-distance=6
spawn-protection=0
'@ | Set-Content -Path (Join-Path $run 'server.properties') -Encoding ASCII

$mods = Join-Path $run 'mods'
Copy-Item (Join-Path $root 'libs\fabric-api-0.161.0+26.2.jar') $mods -Force
Copy-Item (Join-Path $root 'primal-winter-26.2\build\primalwinter-1.0.0+26.2.jar') $mods -Force
Get-ChildItem $mods | ForEach-Object { Write-Output "mod: $($_.Name)" }
Write-Output "cp entries: $($cp.Count)  SETUP OK"
