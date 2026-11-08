$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$dir = Join-Path $root 'testserver'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$jar = Join-Path $dir 'server.jar'
if (-not (Test-Path $jar)) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  (New-Object System.Net.WebClient).DownloadFile('https://bmclapi2.bangbang93.com/version/26.2/server', $jar)
  Write-Output ("downloaded {0:N1} MB in {1:N1}s" -f ((Get-Item $jar).Length / 1MB), $sw.Elapsed.TotalSeconds)
}
Write-Output "server.jar = $([math]::Round((Get-Item $jar).Length/1MB,1)) MB"
