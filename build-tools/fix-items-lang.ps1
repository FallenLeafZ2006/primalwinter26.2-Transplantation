$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$assets = Join-Path $root 'primal-winter-26.2\src\main\resources\assets\primalwinter'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# 1. item model definitions must point at the item model when one exists (mushrooms / vine / bamboo / sugar cane / lily pad ...)
$fixed = 0
foreach ($f in Get-ChildItem (Join-Path $assets 'items') -Filter *.json) {
  $id = $f.BaseName
  $itemModel = Join-Path $assets "models\item\$id.json"
  if (-not (Test-Path $itemModel)) { continue }
  $json = @"
{
  "model": {
    "type": "minecraft:model",
    "model": "primalwinter:item/$id"
  }
}
"@
  [IO.File]::WriteAllText($f.FullName, $json, $utf8)
  $fixed++
}
Write-Output "items repointed to item models: $fixed"

# 2. complete + translate Chinese names
$zh = Join-Path $assets 'lang\zh_cn.json'
$obj = [IO.File]::ReadAllText($zh, [Text.Encoding]::UTF8) | ConvertFrom-Json
$have = @{}
foreach ($p in $obj.PSObject.Properties) { $have[$p.Name] = $p.Value }

$names = [ordered]@{
  'snowy_mud'                    = '积雪的泥巴'
  'snowy_cherry_log'             = '冰冻的樱花原木'
  'snowy_cherry_leaves'          = '冰冻的樱花树叶'
  'snowy_mangrove_log'           = '冰冻的红树林原木'
  'snowy_mangrove_leaves'        = '冰冻的红树林树叶'
  'snowy_mangrove_roots'         = '冰冻的红树林根'
  'snowy_muddy_mangrove_roots'   = '冰冻的泥泞红树林根'
  'snowy_brown_mushroom_block'   = '覆雪的棕色蘑菇方块'
  'snowy_red_mushroom_block'     = '覆雪的红色蘑菇方块'
  'snowy_mushroom_stem'          = '覆雪的蘑菇柄'
  'snowy_lily_pad'               = '覆雪的睡莲'
  'snowy_sugar_cane'             = '覆雪的甘蔗'
  'snowy_cactus'                 = '覆雪的仙人掌'
  'snowy_bamboo'                 = '覆雪的竹子'
}

$added = 0; $changed = 0
foreach ($id in $names.Keys) {
  foreach ($prefix in @('block', 'item')) {
    $key = "$prefix.primalwinter.$id"
    $val = $names[$id]
    if (-not $have.ContainsKey($key)) { $have[$key] = $val; $added++ }
    elseif ($have[$key] -ne $val) { $have[$key] = $val; $changed++ }
  }
}

$lines = New-Object System.Collections.Generic.List[string]
foreach ($k in $have.Keys) {
  $esc = $have[$k] -replace '\\', '\\' -replace '"', '\"'
  $lines.Add('  "' + $k + '": "' + $esc + '"')
}
[IO.File]::WriteAllText($zh, "{`n" + ($lines -join ",`n") + "`n}`n", $utf8)
Write-Output "zh_cn: added=$added changed=$changed total=$($lines.Count)"

# 3. report any block ids still missing a zh_cn name
$blocks = (Select-String -Path (Join-Path $root 'primal-winter-26.2\src\main\java\com\alcatrazescapee\primalwinter\blocks\PrimalWinterBlocks.java') -Pattern 'register\("([a-z_]+)"' -AllMatches).Matches | ForEach-Object { $_.Groups[1].Value }
$missing = $blocks | Where-Object { -not $have.ContainsKey("block.primalwinter.$_") }
if ($missing) { "STILL MISSING: $($missing -join ', ')" } else { "all $($blocks.Count) block names present" }
