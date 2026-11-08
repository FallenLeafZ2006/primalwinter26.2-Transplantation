$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$javap = (Get-ChildItem (Join-Path $root 'toolchain\jdk25') -Recurse -Filter javap.exe | Select-Object -First 1).FullName
$cp = Get-Content (Join-Path $root 'libs\cp.txt') -Raw
$outDir = Join-Path $root 'research\api'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$classes = @(
  'net.minecraft.world.level.block.Blocks',
  'net.minecraft.world.level.block.ColorCollection',
  'net.minecraft.world.item.DyeColor',
  'net.minecraft.core.Registry',
  'net.minecraft.core.registries.BuiltInRegistries',
  'net.minecraft.resources.Identifier',
  'net.minecraft.world.level.gamerules.GameRules',
  'net.minecraft.world.level.block.state.BlockBehaviour$Properties',
  'net.minecraft.world.level.block.Block',
  'net.minecraft.world.level.block.LeavesBlock',
  'net.minecraft.world.level.block.RotatedPillarBlock',
  'net.minecraft.world.level.block.HugeMushroomBlock',
  'net.minecraft.world.level.block.MudBlock',
  'net.minecraft.world.level.block.ColoredFallingBlock',
  'net.minecraft.world.level.block.DirtPathBlock',
  'net.minecraft.world.level.block.MangroveRootsBlock',
  'net.minecraft.world.level.block.CactusBlock',
  'net.minecraft.world.level.block.SugarCaneBlock',
  'net.minecraft.world.level.block.BambooStalkBlock',
  'net.minecraft.world.level.block.VineBlock',
  'net.minecraft.world.level.levelgen.feature.Feature',
  'net.minecraft.world.level.levelgen.feature.ConfiguredFeature',
  'net.minecraft.world.level.levelgen.feature.FeaturePlaceContext',
  'net.minecraft.world.level.levelgen.feature.configurations.FeatureConfiguration',
  'net.minecraft.world.item.CreativeModeTab',
  'net.minecraft.network.protocol.common.custom.CustomPacketPayload',
  'net.minecraft.world.level.biome.Biome',
  'net.minecraft.world.level.biome.Biome$TemperatureModifier',
  'net.fabricmc.fabric.api.biome.v1.BiomeModificationContext',
  'net.fabricmc.fabric.api.biome.v1.BiomeModifications',
  'net.fabricmc.fabric.api.biome.v1.ModificationPhase',
  'net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry',
  'net.fabricmc.fabric.api.event.lifecycle.v1.ServerWorldEvents',
  'net.fabricmc.fabric.api.event.lifecycle.v1.ServerLevelEvents',
  'net.fabricmc.fabric.api.creativetab.v1.FabricCreativeModeTab',
  'net.fabricmc.fabric.api.client.rendering.v1.ColorProviderRegistry',
  'net.fabricmc.fabric.api.client.particle.v1.ParticleFactoryRegistry'
)

foreach ($c in $classes) {
  $text = & $javap -cp $cp -public $c 2>&1
  $name = ($c -replace '[.$]', '_')
  $text | Set-Content -Path (Join-Path $outDir "$name.txt") -Encoding UTF8
  $ok = ($text | Select-Object -First 1) -notmatch 'Error|error:'
  Write-Output ("{0,-6} {1}" -f $(if ($ok) { 'OK' } else { 'MISS' }), $c)
}
