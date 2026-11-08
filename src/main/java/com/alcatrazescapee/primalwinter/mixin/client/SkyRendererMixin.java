package com.alcatrazescapee.primalwinter.mixin.client;

import com.alcatrazescapee.primalwinter.platform.XPlatform;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.renderer.SkyRenderer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * The original mod suppressed the orange sunrise/sunset glow in winter dimensions. 26.2 removed
 * {@code DimensionSpecialEffects#getSunriseColor} and renders the glow through {@code SkyRenderer} instead, so the same effect is
 * achieved by cancelling the sunrise/sunset pass.
 */
@Mixin(SkyRenderer.class)
public abstract class SkyRendererMixin
{
    @Inject(method = "renderSunriseAndSunset", at = @At("HEAD"), cancellable = true)
    private void primalwinter$noSunriseGlow(PoseStack poseStack, float partialTick, int color, CallbackInfo ci)
    {
        final ClientLevel level = Minecraft.getInstance().level;
        if (level != null && XPlatform.INSTANCE.config().isWinterDimension(level.dimension()))
        {
            ci.cancel();
        }
    }
}
