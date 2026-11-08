$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$javap = (Get-ChildItem (Join-Path $root 'toolchain\jdk25') -Recurse -Filter javap.exe | Select-Object -First 1).FullName
$cp = Get-Content (Join-Path $root 'libs\cp.txt') -Raw
$outDir = Join-Path $root 'research\api'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$classes = @(
  'net.minecraft.world.level.levelgen.feature.SpikeFeature',
  'net.minecraft.world.level.levelgen.feature.configurations.SpikeConfiguration',
  'net.minecraft.world.level.levelgen.feature.SnowAndFreezeFeature',
  'net.minecraft.world.level.levelgen.placement.PlacedFeature',
  'net.minecraft.world.level.levelgen.GenerationStep$Decoration',
  'net.minecraft.world.level.biome.MobSpawnSettings$SpawnerData',
  'net.minecraft.server.level.ServerLevel',
  'net.minecraft.world.level.LevelAccessor',
  'net.minecraft.world.level.levelgen.Heightmap$Types',
  'net.minecraft.world.level.WorldGenLevel',
  'net.minecraft.world.item.Item$Properties',
  'net.minecraft.world.item.BlockItem',
  'net.minecraft.world.item.CreativeModeTab$Builder',
  'net.minecraft.network.protocol.common.custom.CustomPacketPayload$Type',
  'net.minecraft.network.codec.StreamCodec',
  'net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking',
  'net.fabricmc.fabric.api.networking.v1.ServerPlayConnectionEvents',
  'net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback',
  'net.fabricmc.fabric.api.event.lifecycle.v1.ServerLevelEvents',
  'net.minecraft.world.level.levelgen.feature.Feature',
  'net.minecraft.world.level.levelgen.feature.configurations.NoneFeatureConfiguration',
  'net.minecraft.world.level.levelgen.feature.configurations.DiskConfiguration',
  'net.minecraft.world.level.chunk.LevelChunk',
  'net.minecraft.world.level.chunk.ChunkAccess',
  'net.minecraft.server.level.ServerPlayer',
  'net.minecraft.world.level.Level',
  'net.minecraft.world.entity.EntityType',
  'net.minecraft.world.entity.MobCategory',
  'net.minecraft.world.level.block.SoundType',
  'net.minecraft.world.level.block.Blocks$1'
)

foreach ($c in $classes) {
  $text = & $javap -cp $cp -public $c 2>&1
  $name = ($c -replace '[.$]', '_')
  $text | Set-Content -Path (Join-Path $outDir "$name.txt") -Encoding UTF8
  $ok = ($text | Select-Object -First 1) -notmatch 'Error|error:'
  Write-Output ("{0,-6} {1}" -f $(if ($ok) { 'OK' } else { 'MISS' }), $c)
}
