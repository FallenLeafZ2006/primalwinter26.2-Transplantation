$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$java = Join-Path $root 'primal-winter-26.2\src\main\java\com\alcatrazescapee\primalwinter'

$remove = @(
  'client\ClientEventHandler.java',
  'client\PrimalWinterAmbience.java',
  'client\SnowParticle.java',
  'client\ReloadableLevelRenderer.java',
  'client\package-info.java',
  'mixin\client\DimensionSpecialEffectsMixin.java',
  'mixin\client\FogRendererMixin.java',
  'mixin\client\LevelRendererMixin.java',
  'platform\client\BlockColorCallback.java',
  'platform\client\FogColorCallback.java',
  'platform\client\FogDensityCallback.java',
  'platform\client\ItemColorCallback.java',
  'platform\client\ParticleProviderCallback.java',
  'platform\client\XPlatformClient.java',
  'platform\client\package-info.java',
  'platform\NetworkSetupCallback.java',
  'FabricPrimalWinterClient.java',
  'package-info.java',
  'blocks\package-info.java',
  'platform\package-info.java',
  'util\package-info.java',
  'world\package-info.java'
)
foreach ($r in $remove) {
  $p = Join-Path $java $r
  if (Test-Path $p) { Remove-Item $p -Force; Write-Output "removed $r" } else { Write-Output "skip    $r (absent)" }
}

# also drop the client-only service files
$res = Join-Path $root 'primal-winter-26.2\src\main\resources'
foreach ($s in @('META-INF\services\com.alcatrazescapee.primalwinter.platform.client.XPlatformClient', 'primalwinter.fabric.mixins.json')) {
  $p = Join-Path $res $s
  if (Test-Path $p) { Remove-Item $p -Force; Write-Output "removed resource $s" }
}
Get-ChildItem (Join-Path $java 'client') -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "left in client/: $($_.Name)" }
