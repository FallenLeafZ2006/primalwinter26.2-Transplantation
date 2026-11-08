param([switch]$Capture, [string]$Out = 'shot-game.png')
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr l);
  public delegate bool EnumWindowsProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
}
"@
$script:found = [IntPtr]::Zero
$cb = [W+EnumWindowsProc]{
  param($h, $l)
  $cn = New-Object System.Text.StringBuilder 64
  [void][W]::GetClassName($h, $cn, 64)
  if ($cn.ToString() -eq 'GLFW30') { $script:found = $h; return $false }
  return $true
}
[void][W]::EnumWindows($cb, [IntPtr]::Zero)
if ($script:found -eq [IntPtr]::Zero) { Write-Output "GAME WINDOW NOT FOUND"; exit 1 }
$h = $script:found
$title = New-Object System.Text.StringBuilder 256
[void][W]::GetWindowText($h, $title, 256)
Write-Output "hwnd=$($h.ToInt64()) title=$($title.ToString())"
if ([W]::IsIconic($h)) { [void][W]::ShowWindow($h, 9) ; Start-Sleep -Milliseconds 400 }
[void][W]::BringWindowToTop($h)
[void][W]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 600
$fg = [W]::GetForegroundWindow()
Write-Output "foreground=$($fg.ToInt64()) match=$($fg -eq $h)"

if ($Capture) {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $g.Dispose()
  $path = Join-Path (Get-Location) $Out
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output "saved $path"
}
