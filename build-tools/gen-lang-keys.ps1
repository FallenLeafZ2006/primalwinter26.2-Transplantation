$ErrorActionPreference = 'Stop'
$assets = Resolve-Path (Join-Path $PSScriptRoot '..\primal-winter-26.2\src\main\resources\assets\primalwinter')
$utf8 = New-Object System.Text.UTF8Encoding($false)

foreach ($langFile in Get-ChildItem (Join-Path $assets 'lang') -Filter *.json) {
  $p = $langFile.FullName
  $text = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
  try { $obj = $text | ConvertFrom-Json } catch { Write-Output "PARSE FAIL $($langFile.Name): $($_.Exception.Message)"; continue }

  $pairs = New-Object System.Collections.Generic.List[string]
  $seen = New-Object System.Collections.Generic.HashSet[string]
  foreach ($prop in $obj.PSObject.Properties) {
    $esc = $prop.Value -replace '\\', '\\' -replace '"', '\"'
    $pairs.Add('  "' + $prop.Name + '": "' + $esc + '"')
    [void]$seen.Add($prop.Name)
  }
  $added = 0
  foreach ($prop in $obj.PSObject.Properties) {
    if ($prop.Name -like 'block.primalwinter.*') {
      $itemKey = $prop.Name -replace '^block\.', 'item.'
      if (-not $seen.Contains($itemKey)) {
        $esc = $prop.Value -replace '\\', '\\' -replace '"', '\"'
        $pairs.Add('  "' + $itemKey + '": "' + $esc + '"')
        [void]$seen.Add($itemKey)
        $added++
      }
    }
  }
  $out = "{`n" + ($pairs -join ",`n") + "`n}`n"
  [IO.File]::WriteAllText($p, $out, $utf8)
  Write-Output ("{0,-12} entries={1,3}  added item keys={2}" -f $langFile.Name, $pairs.Count, $added)
}

# validate every lang file parses again
foreach ($langFile in Get-ChildItem (Join-Path $assets 'lang') -Filter *.json) {
  try { $null = [IO.File]::ReadAllText($langFile.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json; Write-Output "VALID $($langFile.Name)" }
  catch { Write-Output "INVALID $($langFile.Name)" }
}
