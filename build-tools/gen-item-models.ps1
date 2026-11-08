$ErrorActionPreference = 'Stop'
$res = Resolve-Path (Join-Path $PSScriptRoot '..\primal-winter-26.2\src\main\resources')
$assets = Join-Path $res 'assets\primalwinter'
$itemsDir = Join-Path $assets 'items'
if (Test-Path $itemsDir) { Remove-Item $itemsDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $itemsDir | Out-Null

$count = 0
foreach ($bs in Get-ChildItem (Join-Path $assets 'blockstates') -Filter *.json) {
  $text = [IO.File]::ReadAllText($bs.FullName)
  $m = [regex]::Match($text, '"model"\s*:\s*"([^"]+)"')
  if (-not $m.Success) { Write-Output "SKIP $($bs.BaseName) (no model)"; continue }
  $model = $m.Groups[1].Value
  $id = $bs.BaseName
  $json = @"
{
  "model": {
    "type": "minecraft:model",
    "model": "$model"
  }
}
"@
  [IO.File]::WriteAllText((Join-Path $itemsDir "$id.json"), $json, (New-Object System.Text.UTF8Encoding($false)))
  $count++
}
Write-Output "generated items/*.json : $count"

# add item.* language keys mirroring block.*
foreach ($lang in @('en_us.json', 'zh_cn.json')) {
  $p = Join-Path $assets "lang\$lang"
  $obj = Get-Content $p -Raw | ConvertFrom-Json
  $add = [ordered]@{}
  foreach ($prop in $obj.PSObject.Properties) {
    if ($prop.Name -like 'block.primalwinter.*') {
      $itemKey = $prop.Name -replace '^block\.', 'item.'
      if (-not $obj.PSObject.Properties[$itemKey]) { $add[$itemKey] = $prop.Value }
    }
  }
  if ($add.Count -gt 0) {
    $lines = @()
    $existing = Get-Content $p -Raw
    # rebuild json preserving original entries then appending new ones
    $pairs = @()
    foreach ($prop in $obj.PSObject.Properties) { $pairs += ('  "' + $prop.Name + '": "' + ($prop.Value -replace '\\', '\\' -replace '"', '\"') + '"') }
    foreach ($k in $add.Keys) { $pairs += ('  "' + $k + '": "' + ($add[$k] -replace '\\', '\\' -replace '"', '\"') + '"') }
    $out = "{`n" + ($pairs -join ",`n") + "`n}`n"
    [IO.File]::WriteAllText($p, $out, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "$lang : added $($add.Count) item keys"
  } else { Write-Output "$lang : nothing to add" }
}
