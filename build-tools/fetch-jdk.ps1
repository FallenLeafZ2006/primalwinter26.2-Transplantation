$ErrorActionPreference = 'Stop'
$dest = Join-Path $PSScriptRoot '..\toolchain'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$candidates = @(
  @{ name = 'tencent';  url = 'https://mirrors.cloud.tencent.com/Adoptium/25/jdk/x64/windows/OpenJDK25U-jdk_x64_windows_hotspot_25.0.5_8.zip' },
  @{ name = 'huawei';   url = 'https://mirrors.huaweicloud.com/Adoptium/25/jdk/x64/windows/OpenJDK25U-jdk_x64_windows_hotspot_25.0.5_8.zip' },
  @{ name = 'microsoft'; url = 'https://aka.ms/download-jdk/microsoft-jdk-25-windows-x64.zip' },
  @{ name = 'tuna';     url = 'https://mirrors.tuna.tsinghua.edu.cn/Adoptium/25/jdk/x64/windows/OpenJDK25U-jdk_x64_windows_hotspot_25.0.5_8.zip' }
)

function Test-Range([string]$url) {
  try {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Timeout = 15000; $req.ReadWriteTimeout = 15000
    $req.AddRange(0, 524287)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $resp = $req.GetResponse()
    $s = $resp.GetResponseStream()
    $buf = New-Object byte[] 65536; $total = 0
    while ($total -lt 524288) { $n = $s.Read($buf, 0, $buf.Length); if ($n -le 0) { break }; $total += $n }
    $s.Close(); $resp.Close()
    $sec = [math]::Max($sw.Elapsed.TotalSeconds, 0.001)
    return ($total / 1KB / $sec)
  } catch { return -1 }
}

$chosen = $null
foreach ($c in $candidates) {
  $kbps = Test-Range $c.url
  Write-Output ("probe {0,-10} {1,8:N1} KB/s" -f $c.name, $kbps)
  if ($kbps -gt 200) { $chosen = $c; break }
}
if (-not $chosen) { $chosen = $candidates[0]; Write-Output "no fast mirror, falling back to tencent" }

$zip = Join-Path $dest 'jdk25.zip'
Write-Output "downloading from $($chosen.name): $($chosen.url)"
$sw = [Diagnostics.Stopwatch]::StartNew()
(New-Object System.Net.WebClient).DownloadFile($chosen.url, $zip)
Write-Output ("downloaded {0:N1} MB in {1:N1}s" -f ((Get-Item $zip).Length / 1MB), $sw.Elapsed.TotalSeconds)

$out = Join-Path $dest 'jdk25'
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $out -Force
$javaExe = (Get-ChildItem $out -Recurse -Filter 'java.exe' | Where-Object { $_.FullName -match 'bin\\java\.exe$' } | Select-Object -First 1).FullName
Write-Output "JAVA=$javaExe"
& $javaExe -version 2>&1 | ForEach-Object { Write-Output $_ }
