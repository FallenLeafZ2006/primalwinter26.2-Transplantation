package com.alcatrazescapee.primalwinter.client;

import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.particle.Particle;
import net.minecraft.client.particle.ParticleProvider;
import net.minecraft.client.particle.SpriteSet;
import net.minecraft.client.particle.WaterDropParticle;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.core.particles.SimpleParticleType;
import net.minecraft.util.RandomSource;

/**
 * The mod's own snowflake: a water drop particle re-textured with the four frame animated snow sprite, used for the dense blizzard
 * weather effect.
 */
public class SnowParticle extends WaterDropParticle
{
    protected SnowParticle(ClientLevel level, double x, double y, double z, TextureAtlasSprite sprite)
    {
        super(level, x, y, z, sprite);
    }

    public record Provider(SpriteSet sprite) implements ParticleProvider<SimpleParticleType>
    {
        @Override
        public Particle createParticle(SimpleParticleType type, ClientLevel level, double x, double y, double z, double vx, double vy, double vz, RandomSource random)
        {
            final SnowParticle particle = new SnowParticle(level, x, y, z, sprite.first());
            particle.setSpriteFromAge(sprite);
            return particle;
        }
    }
}
