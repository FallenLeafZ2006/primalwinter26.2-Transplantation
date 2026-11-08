param([string]$Command = 'time set day', [string]$Password = 'pw', [int]$Port = 25575)
$ErrorActionPreference = 'Stop'

function Send-Packet($stream, [int]$id, [int]$type, [string]$body) {
  $bytes = [Text.Encoding]::ASCII.GetBytes($body)
  $len = 4 + 4 + $bytes.Length + 2
  $buf = New-Object System.IO.MemoryStream
  $w = New-Object System.IO.BinaryWriter($buf)
  $w.Write([int]$len)
  $w.Write([int]$id)
  $w.Write([int]$type)
  $w.Write($bytes)
  $w.Write([byte]0); $w.Write([byte]0)
  $w.Flush()
  $out = $buf.ToArray()
  $stream.Write($out, 0, $out.Length)
  $stream.Flush()
}

function Read-Packet($stream) {
  $lenBuf = New-Object byte[] 4
  $read = 0
  while ($read -lt 4) { $n = $stream.Read($lenBuf, $read, 4 - $read); if ($n -le 0) { return $null }; $read += $n }
  $len = [BitConverter]::ToInt32($lenBuf, 0)
  $body = New-Object byte[] $len
  $read = 0
  while ($read -lt $len) { $n = $stream.Read($body, $read, $len - $read); if ($n -le 0) { break }; $read += $n }
  $id = [BitConverter]::ToInt32($body, 0)
  $type = [BitConverter]::ToInt32($body, 4)
  $text = [Text.Encoding]::ASCII.GetString($body, 8, $len - 10)
  return [pscustomobject]@{ Id = $id; Type = $type; Body = $text }
}

$client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', $Port)
$client.ReceiveTimeout = 5000
$stream = $client.GetStream()
Send-Packet $stream 1 3 $Password
$auth = Read-Packet $stream
if (-not $auth -or $auth.Id -eq -1) { Write-Output 'AUTH FAILED'; exit 1 }
Write-Output "auth ok"
Send-Packet $stream 2 2 $Command
$resp = Read-Packet $stream
Write-Output ("response: " + $resp.Body)
$client.Close()
