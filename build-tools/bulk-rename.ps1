$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$src = Join-Path $root 'primal-winter-26.2\src\main\java'

$pairs = @(
  @{ from = 'net.minecraft.resources.ResourceLocation'; to = 'net.minecraft.resources.Identifier' },
  @{ from = 'net.minecraft.world.level.GameRules';     to = 'net.minecraft.world.level.gamerules.GameRules' },
  @{ from = 'WaterlilyBlock';                          to = 'LilyPadBlock' },
  @{ from = 'CherryLeavesBlock';                       to = 'LeavesBlock' },
  @{ from = 'ServerWorldEvents';                       to = 'ServerLevelEvents' },
  @{ from = 'ResourceLocation';                        to = 'Identifier' }
)

$files = Get-ChildItem $src -Recurse -Filter *.java
$changed = @{}
foreach ($f in $files) {
  $text = [IO.File]::ReadAllText($f.FullName)
  $original = $text
  foreach ($p in $pairs) {
    $text = [regex]::Replace($text, [regex]::Escape($p.from), $p.to)
  }
  if ($text -ne $original) {
    [IO.File]::WriteAllText($f.FullName, $text, (New-Object System.Text.UTF8Encoding($false)))
    $changed[$f.FullName] = $true
  }
}
Write-Output "rewritten files: $($changed.Count)"
$changed.Keys | ForEach-Object { Write-Output ("  " + ($_ -replace [regex]::Escape($src) + '\\', '')) }
