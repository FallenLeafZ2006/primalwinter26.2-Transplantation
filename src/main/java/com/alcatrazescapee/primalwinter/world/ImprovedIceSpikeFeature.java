package com.alcatrazescapee.primalwinter.world;

import com.mojang.serialization.Codec;
import net.minecraft.core.BlockPos;
import net.minecraft.tags.BlockTags;
import net.minecraft.world.level.WorldGenLevel;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.levelgen.feature.FeaturePlaceContext;
import net.minecraft.world.level.levelgen.feature.SpikeFeature;
import net.minecraft.world.level.levelgen.feature.configurations.SpikeConfiguration;

/**
 * The standard spike feature does not place unless it encounters a valid block. This avoids that restriction by placing a snow block
 * at the origin first, so ice spikes can generate on any surface.
 */
public class ImprovedIceSpikeFeature extends SpikeFeature
{
    public ImprovedIceSpikeFeature(Codec<SpikeConfiguration> codec)
    {
        super(codec);
    }

    @Override
    public boolean place(FeaturePlaceContext<SpikeConfiguration> context)
    {
        final WorldGenLevel level = context.level();
        BlockPos pos = context.origin();
        while (level.isEmptyBlock(pos) && pos.getY() > level.getMinY() + 2)
        {
            pos = pos.below();
        }
        final BlockState originalState = level.getBlockState(pos);
        if (!originalState.is(BlockTags.LEAVES) && !originalState.is(BlockTags.LOGS))
        {
            level.setBlock(pos, Blocks.SNOW_BLOCK.defaultBlockState(), 2);
        }
        return super.place(context);
    }
}
