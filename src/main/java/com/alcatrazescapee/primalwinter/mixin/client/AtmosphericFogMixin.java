package com.alcatrazescapee.primalwinter.mixin.client;

import com.alcatrazescapee.primalwinter.platform.XPlatform;
import net.minecraft.util.Util;
import net.minecraft.client.Camera;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.renderer.fog.FogData;
import net.minecraft.client.renderer.fog.environment.AtmosphericFogEnvironment;
import net.minecraft.core.BlockPos;
import net.minecraft.util.Mth;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LightLayer;
import net.minecraft.world.level.material.FogType;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Reproduces the original mod's fog behaviour: density is driven by the sky light at the player's eye (so the blizzard closes in when
 * the sky is dark), smoothed over time and scaled by render distance, while the colour lerps between the configured day and night
 * colours using the sun angle.
 */
@Mixin(AtmosphericFogEnvironment.class)
public abstract class AtmosphericFogMixin
{
    @Inject(method = "setupFog", at = @At("RETURN"))
    private void primalwinter$applyWinterFog(FogData fog, Camera camera, ClientLevel level, float partialTick, DeltaTracker deltaTracker, CallbackInfo ci)
    {
        if (level == null || !XPlatform.INSTANCE.config().isWinterDimension(level.dimension()))
        {
            return;
        }
        if (!(camera.entity() instanceof Player player))
        {
            return;
        }

        final long now = Util.getMillis();
        final boolean firstTick = prevFogTick == -1;
        final float deltaTick = firstTick ? 1e10f : (now - prevFogTick) * 0.00005f;
        prevFogTick = now;

        float expected = 0.0f;
        final int light = level.getBrightness(LightLayer.SKY, BlockPos.containing(player.getEyePosition()));
        expected = Mth.clampedMap(light, 0.0f, 15.0f, 0.0f, 1.0f);

        final float renderDistanceAdjustment = (12.0f * 16.0f) / (Minecraft.getInstance().options.getEffectiveRenderDistance() * 16.0f);

        if (expected > prevFogDensity)
        {
            prevFogDensity = Math.min(prevFogDensity + 4.0f * deltaTick, expected);
        }
        else if (expected < prevFogDensity)
        {
            prevFogDensity = Math.max(prevFogDensity - deltaTick, expected);
        }

        if (camera.getFluidInCamera() != FogType.NONE)
        {
            prevFogDensity = -1.0f;
            prevFogTick = -1L;
            return;
        }

        if (prevFogDensity > 0.0f)
        {
            final float scaledDelta = 1.0f - (1.0f - prevFogDensity) * (1.0f - prevFogDensity);
            final float density = XPlatform.INSTANCE.config().fogDensity.get();
            final float farScale = Mth.lerp(scaledDelta, 1.0f, density) * renderDistanceAdjustment;
            final float nearScale = Mth.lerp(scaledDelta, 1.0f, 0.3f * density) * renderDistanceAdjustment;

            fog.environmentalStart = Math.max(0.0f, fog.environmentalStart * nearScale);
            fog.environmentalEnd = Math.max(fog.environmentalStart + 1.0f, fog.environmentalEnd * farScale);
            fog.skyEnd = Math.min(fog.skyEnd, fog.environmentalEnd * 2.0f);
            fog.cloudEnd = Math.min(fog.cloudEnd, fog.environmentalEnd * 2.5f);

            // Colour: lerp between day and night using the sun height, so dawn/dusk fade smoothly
            final float angle = ((level.getOverworldClockTime() % 24000L) / 24000.0f - 0.25f) * Mth.TWO_PI;
            final float height = Mth.cos(angle);
            final float delta = Mth.clamp((height + 0.4f) / 0.8f, 0.0f, 1.0f);

            final int colorDay = XPlatform.INSTANCE.config().fogColorDay.get();
            final int colorNight = XPlatform.INSTANCE.config().fogColorNight.get();
            final float red = (((colorDay >> 16) & 0xFF) * delta + ((colorNight >> 16) & 0xFF) * (1.0f - delta)) / 255.0f;
            final float green = (((colorDay >> 8) & 0xFF) * delta + ((colorNight >> 8) & 0xFF) * (1.0f - delta)) / 255.0f;
            final float blue = ((colorDay & 0xFF) * delta + (colorNight & 0xFF) * (1.0f - delta)) / 255.0f;
            fog.color.set(red, green, blue, 1.0f);
        }
    }

    private static float prevFogDensity = -1.0f;
    private static long prevFogTick = -1L;
}
