param([int]$X, [int]$Y, [double]$Scale = 1.5)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
"@
$px = [int]($X * $Scale)
$py = [int]($Y * $Scale)
[void][M]::SetCursorPos($px, $py)
Start-Sleep -Milliseconds 200
[M]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)  # left down
Start-Sleep -Milliseconds 60
[M]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)  # left up
Write-Output "clicked capture($X,$Y) -> physical($px,$py)"
