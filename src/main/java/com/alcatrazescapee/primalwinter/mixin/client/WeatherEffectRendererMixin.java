package com.alcatrazescapee.primalwinter.mixin.client;

import com.alcatrazescapee.primalwinter.platform.XPlatform;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.renderer.WeatherEffectRenderer;
import net.minecraft.client.renderer.state.level.WeatherRenderState;
import net.minecraft.core.BlockPos;
import net.minecraft.util.Mth;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.LightLayer;
import net.minecraft.world.level.levelgen.Heightmap;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Replaces vanilla weather with the mod's heavy snow, mirroring the original mod: the {@code snowDensity} option is the radius (in blocks)
 * of snow columns drawn around the camera, and each column is a tall streak spanning {@code +/- snowDensity} blocks vertically, clipped to
 * the terrain surface.
 */
@Mixin(WeatherEffectRenderer.class)
public abstract class WeatherEffectRendererMixin
{
    @Inject(method = "extractRenderState", at = @At("RETURN"))
    private void primalwinter$replaceWeather(ClientLevel level, float partialTick, Vec3 cameraPos, WeatherRenderState state, CallbackInfo ci)
    {
        if (level == null || state == null || !XPlatform.INSTANCE.config().isWinterDimension(level.dimension()))
        {
            return;
        }

        state.rainColumns.clear();
        state.snowColumns.clear();

        if (!level.isRaining() && !level.isThundering())
        {
            state.intensity = 0.0f;
            return;
        }

        final int radius = XPlatform.INSTANCE.config().snowDensity.get();
        final int camX = Mth.floor(cameraPos.x);
        final int camY = Mth.floor(cameraPos.y);
        final int camZ = Mth.floor(cameraPos.z);
        final RandomSource random = RandomSource.create(level.getGameTime() * 312987231L);
        final BlockPos.MutableBlockPos cursor = new BlockPos.MutableBlockPos();

        for (int dz = -radius; dz <= radius; dz++)
        {
            for (int dx = -radius; dx <= radius; dx++)
            {
                final int x = camX + dx;
                final int z = camZ + dz;
                final int height = level.getHeight(Heightmap.Types.MOTION_BLOCKING, x, z);
                final int bottom = Math.max(height, camY - radius);
                final int top = Math.max(height, camY + radius);
                if (top <= bottom)
                {
                    continue;
                }

                cursor.set(x, Math.max(height, camY), z);
                final int sky = level.getBrightness(LightLayer.SKY, cursor);
                final int block = level.getBrightness(LightLayer.BLOCK, cursor);
                final int lightCoords = (sky << 20) | (block << 4);

                state.snowColumns.add(new WeatherEffectRenderer.ColumnInstance(
                    x, z, bottom, top,
                    random.nextFloat(), random.nextFloat(),
                    lightCoords));
            }
        }

        state.intensity = 1.0f;
        state.radius = radius;
    }
}
