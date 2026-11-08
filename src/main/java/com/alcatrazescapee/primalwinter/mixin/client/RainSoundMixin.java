package com.alcatrazescapee.primalwinter.mixin.client;

import com.alcatrazescapee.primalwinter.platform.XPlatform;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.level.Level;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Honours the {@code snowSounds} config option by suppressing vanilla's ambient rain sound, which the mod replaces with wind.
 */
@Mixin(Level.class)
public abstract class RainSoundMixin
{
    @Inject(method = "playLocalSound(DDDLnet/minecraft/sounds/SoundEvent;Lnet/minecraft/sounds/SoundSource;FFZ)V", at = @At("HEAD"), cancellable = true)
    private void primalwinter$muteRainSound(double x, double y, double z, SoundEvent sound, SoundSource source, float volume, float pitch, boolean distanceDelay, CallbackInfo ci)
    {
        if (!XPlatform.INSTANCE.config().snowSounds.get() && sound.location().getPath().contains("rain"))
        {
            ci.cancel();
        }
    }
}
