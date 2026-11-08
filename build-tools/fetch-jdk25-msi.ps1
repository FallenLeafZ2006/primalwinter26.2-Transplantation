$ErrorActionPreference = 'Stop'
$dest = Join-Path $PSScriptRoot '..\toolchain'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$msi = Join-Path $dest 'jdk25.msi'
$url = 'https://aka.ms/download-jdk/microsoft-jdk-25.0.5.0.2-windows-x64.msi'
$sw = [Diagnostics.Stopwatch]::StartNew()
(New-Object System.Net.WebClient).DownloadFile($url, $msi)
Write-Output ("downloaded {0:N1} MB in {1:N1}s" -f ((Get-Item $msi).Length / 1MB), $sw.Elapsed.TotalSeconds)

$out = Join-Path $dest 'jdk25'
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $out | Out-Null
Write-Output "extracting msi (administrative install)..."
$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/a', "`"$msi`"", '/qn', "TARGETDIR=`"$out`"") -Wait -PassThru -NoNewWindow
Write-Output "msiexec exit=$($p.ExitCode)"
$javaExe = Get-ChildItem $out -Recurse -Filter 'java.exe' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\\bin\\java\.exe$' } | Select-Object -First 1
if ($javaExe) {
  Write-Output "JAVA=$($javaExe.FullName)"
  & $javaExe.FullName -version 2>&1 | ForEach-Object { Write-Output $_ }
} else {
  Write-Output "NO JAVA FOUND, tree:"
  Get-ChildItem $out -Recurse -Depth 3 -Directory | Select-Object -First 30 FullName | ForEach-Object { Write-Output $_.FullName }
}
