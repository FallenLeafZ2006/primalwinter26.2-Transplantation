param([string]$Server = '127.0.0.1:25565')
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$java = (Get-ChildItem (Join-Path $root 'toolchain\jdk25') -Recurse -Filter java.exe | Where-Object { $_.FullName -match '\\bin\\java\.exe$' } | Select-Object -First 1).FullName
$verDir = 'D:\.minecraft\versions\26.2-Fabric 0.20.1'
$verName = '26.2-Fabric 0.20.1'
$j = Get-Content (Join-Path $verDir "$verName.json") -Raw | ConvertFrom-Json
$libs = 'D:\.minecraft\libraries'
$run = Join-Path $root 'clientrun'
New-Item -ItemType Directory -Force -Path $run | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $run 'mods') | Out-Null
$natives = Join-Path $root 'clientrun\natives'
New-Item -ItemType Directory -Force -Path $natives | Out-Null

$cp = New-Object System.Collections.Generic.List[string]
$missing = 0
foreach ($l in $j.libraries) {
  $allowed = $true
  if ($l.rules) {
    $allowed = $false
    foreach ($r in $l.rules) {
      $osMatch = (-not $r.os) -or ($r.os.name -eq 'windows')
      if ($r.action -eq 'allow' -and $osMatch) { $allowed = $true }
      elseif ($r.action -eq 'disallow' -and $osMatch) { $allowed = $false }
    }
  }
  if (-not $allowed) { continue }
  $rel = $null
  if ($l.downloads -and $l.downloads.artifact -and $l.downloads.artifact.path) { $rel = $l.downloads.artifact.path }
  elseif ($l.name) {
    $p = $l.name -split ':'
    if ($p.Count -ge 3) { $rel = (($p[0] -replace '\.', '/') + '/' + $p[1] + '/' + $p[2] + '/' + $p[1] + '-' + $p[2] + '.jar') }
  }
  if (-not $rel) { continue }
  $full = Join-Path $libs ($rel -replace '/', '\')
  if (Test-Path $full) { $cp.Add($full) } else { $missing++ }
}
$cp.Add((Join-Path $verDir "$verName.jar"))
Write-Output "libraries ok=$($cp.Count) missing=$missing"

$cpStr = ($cp | Select-Object -Unique) -join ';'
$argsList = New-Object System.Collections.Generic.List[string]
$argsList.Add('-Xmx3G')
$argsList.Add('--enable-native-access=ALL-UNNAMED')
$argsList.Add('--sun-misc-unsafe-memory-access=allow')
$tmp = Join-Path $root 'clientrun\tmp'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$argsList.Add('-Djava.io.tmpdir=' + $tmp)
$libDir = Join-Path $natives '3.4.1-snapshot\x64'
New-Item -ItemType Directory -Force -Path $libDir | Out-Null
$argsList.Add('-Djava.library.path=' + $libDir)
$argsList.Add('-Djna.tmpdir=' + $natives)
$argsList.Add('-Dorg.lwjgl.system.SharedLibraryExtractPath=' + $natives)
$argsList.Add('-Dio.netty.native.workdir=' + $natives)
$argsList.Add('-Dminecraft.launcher.brand=dsh')
$argsList.Add('-Dminecraft.launcher.version=1.0')
$argsList.Add('-cp')
$argsList.Add($cpStr)
$argsList.Add($j.mainClass)
$argsList.Add('--username'); $argsList.Add('Dev')
$argsList.Add('--version'); $argsList.Add($verName)
$argsList.Add('--gameDir'); $argsList.Add($run)
$argsList.Add('--assetsDir'); $argsList.Add('D:\.minecraft\assets')
$argsList.Add('--assetIndex'); $argsList.Add($j.assetIndex.id)
$argsList.Add('--uuid'); $argsList.Add('00000000000000000000000000000000')
$argsList.Add('--accessToken'); $argsList.Add('0')
$argsList.Add('--versionType'); $argsList.Add('release')
if ($Server) { $argsList.Add('--quickPlayMultiplayer'); $argsList.Add($Server) }

$log = Join-Path $run 'client-stdout.log'
Write-Output "launching client..."
& $java @argsList 2>&1 | Tee-Object -FilePath $log
Write-Output "client exited code=$LASTEXITCODE"
