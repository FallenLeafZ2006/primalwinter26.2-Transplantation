param([string]$Pattern, [int]$Limit = 40)
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Select-String -Path (Join-Path $root 'libs\classindex.txt') -Pattern $Pattern | Select-Object -First $Limit | ForEach-Object { $_.Line }
