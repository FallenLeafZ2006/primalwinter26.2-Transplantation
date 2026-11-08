package com.alcatrazescapee.primalwinter;

import java.util.List;
import com.alcatrazescapee.primalwinter.blocks.PrimalWinterBlocks;
import com.alcatrazescapee.primalwinter.client.PrimalWinterAmbience;
import com.alcatrazescapee.primalwinter.client.SnowParticle;
import com.alcatrazescapee.primalwinter.platform.XPlatform;
import com.alcatrazescapee.primalwinter.util.ConfigPacket;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.client.particle.v1.ParticleProviderRegistry;
import net.minecraft.client.Minecraft;
import net.minecraft.client.color.block.BlockColors;
import net.minecraft.client.color.block.BlockTintSources;
import net.minecraft.core.BlockPos;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.Mth;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.FoliageColor;
import net.minecraft.world.level.LightLayer;
import net.minecraft.world.level.levelgen.Heightmap;
import net.minecraft.world.level.material.FogType;

public final class FabricPrimalWinterClient implements ClientModInitializer
{
    private boolean colorsRegistered = false;
    private int windSoundTime = 0;
    private int rainSoundTime = 0;

    @Override
    public void onInitializeClient()
    {
        // Server tells us which dimensions are winter dimensions; fog / ambience read this
        ClientPlayNetworking.registerGlobalReceiver(ConfigPacket.TYPE, (payload, context) -> XPlatform.INSTANCE.config().onSync(payload));

        ParticleProviderRegistry.getInstance().register(PrimalWinterAmbience.SNOW.get(), SnowParticle.Provider::new);

        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            if (!colorsRegistered)
            {
                // Block colours are only created later in Minecraft's constructor, so they cannot be registered from the entrypoint
                setupBlockColors();
                colorsRegistered = true;
            }
            if (client.level == null || client.player == null)
            {
                return;
            }
            if (!XPlatform.INSTANCE.config().isWinterDimension(client.level.dimension()))
            {
                rainSoundTime = 0;
                windSoundTime = 0;
                return;
            }

            tickSnowParticlesAndSounds(client);
        });
    }

    /**
     * Mirrors the original mod's replacement of {@code LevelRenderer#tickRain}: snow lands on the ground around the camera, vanilla rain
     * sounds are replayed at a much lower volume, and wind gusts are added on top.
     */
    private void tickSnowParticlesAndSounds(Minecraft minecraft)
    {
        final RandomSource random = RandomSource.create(minecraft.level.getGameTime() * 312987231L);
        final BlockPos origin = BlockPos.containing(minecraft.player.getEyePosition());
        final int particleAmount = 100;

        BlockPos pos = null;
        for (int i = 0; i < particleAmount; i++)
        {
            final int offsetX = random.nextInt(21) - 10;
            final int offsetZ = random.nextInt(21) - 10;
            final BlockPos candidate = minecraft.level.getHeightmapPos(Heightmap.Types.MOTION_BLOCKING, origin.offset(offsetX, 0, offsetZ));
            if (candidate.getY() > minecraft.level.getMinY() && candidate.getY() <= origin.getY() + 10 && candidate.getY() >= origin.getY() - 10)
            {
                pos = candidate.below();
                minecraft.level.addParticle(
                    PrimalWinterAmbience.SNOW.get(),
                    pos.getX() + random.nextDouble(),
                    pos.getY() + 0.1,
                    pos.getZ() + random.nextDouble(),
                    0.0, 0.0, 0.0);
            }
        }

        if (pos != null && random.nextInt(3) < rainSoundTime++ && XPlatform.INSTANCE.config().snowSounds.get())
        {
            rainSoundTime = 0;
            if (pos.getY() > origin.getY() + 1 && minecraft.level.getHeightmapPos(Heightmap.Types.MOTION_BLOCKING, origin).getY() > Mth.floor(origin.getY()))
            {
                minecraft.level.playLocalSound(pos, SoundEvents.WEATHER_RAIN_ABOVE, SoundSource.WEATHER, 0.05f, 0.2f, false);
            }
            else
            {
                minecraft.level.playLocalSound(pos, SoundEvents.WEATHER_RAIN, SoundSource.WEATHER, 0.1f, 0.5f, false);
            }
        }

        if (windSoundTime-- < 0 && pos != null && XPlatform.INSTANCE.config().windSounds.get())
        {
            final int light = minecraft.level.getBrightness(LightLayer.SKY, pos);
            if (light > 3)
            {
                float volume = 0.2f + (light - 3) * 0.01f;
                float pitch = 0.7f;
                if (minecraft.gameRenderer.mainCamera().getFluidInCamera() != FogType.NONE)
                {
                    pitch = 0.3f;
                }
                windSoundTime = 20 * 3 + random.nextInt(30);
                minecraft.level.playLocalSound(pos, PrimalWinterAmbience.WIND.get(), SoundSource.WEATHER, volume, pitch, false);
            }
            else
            {
                windSoundTime += 5;
            }
        }
    }

    /**
     * Restores the original mod's leaf tinting: evergreen and birch leaves use their fixed colours, everything else follows the biome's
     * foliage colour.
     */
    private static void setupBlockColors()
    {
        final BlockColors colors = Minecraft.getInstance().getBlockColors();

        colors.register(
            List.of(BlockTintSources.constant(FoliageColor.FOLIAGE_EVERGREEN)),
            PrimalWinterBlocks.SNOWY_SPRUCE_LEAVES.get());
        colors.register(
            List.of(BlockTintSources.constant(FoliageColor.FOLIAGE_BIRCH)),
            PrimalWinterBlocks.SNOWY_BIRCH_LEAVES.get());
        colors.register(
            List.of(BlockTintSources.foliage()),
            PrimalWinterBlocks.SNOWY_OAK_LEAVES.get(),
            PrimalWinterBlocks.SNOWY_DARK_OAK_LEAVES.get(),
            PrimalWinterBlocks.SNOWY_JUNGLE_LEAVES.get(),
            PrimalWinterBlocks.SNOWY_ACACIA_LEAVES.get(),
            PrimalWinterBlocks.SNOWY_MANGROVE_LEAVES.get(),
            PrimalWinterBlocks.SNOWY_VINE.get());
    }
}
