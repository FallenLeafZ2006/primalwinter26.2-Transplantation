param([string]$Class, [string]$Filter = '')
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$javap = (Get-ChildItem (Join-Path $root 'toolchain\jdk25') -Recurse -Filter javap.exe | Select-Object -First 1).FullName
$cp = Get-Content (Join-Path $root 'libs\cp.txt') -Raw
$out = & $javap -cp $cp -public $Class 2>&1
if ($Filter) { $out = $out | Select-String -Pattern $Filter }
$out | ForEach-Object { Write-Output ($_.ToString() -replace '\s+$', '') }
