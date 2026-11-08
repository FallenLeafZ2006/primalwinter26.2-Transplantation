package com.alcatrazescapee.primalwinter.util;

import com.alcatrazescapee.primalwinter.PrimalWinter;
import com.mojang.serialization.Codec;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.datafix.DataFixTypes;
import net.minecraft.world.level.saveddata.SavedData;
import net.minecraft.world.level.saveddata.SavedDataType;

public final class NewWorldSavedData extends SavedData
{
    private static final Codec<NewWorldSavedData> CODEC = CompoundTag.CODEC.xmap(tag -> new NewWorldSavedData(), data -> new CompoundTag());

    @SuppressWarnings("ConstantConditions")
    public static void onlyForNewWorlds(ServerLevel level, Runnable action)
    {
        final SavedDataType<NewWorldSavedData> type = new SavedDataType<>(
            Helpers.identifier("new_world"),
            () -> {
                action.run();
                return new NewWorldSavedData();
            },
            CODEC,
            DataFixTypes.LEVEL
        );
        level.getDataStorage().computeIfAbsent(type);
    }

    @Override
    public boolean isDirty()
    {
        return true; // Assume it is always dirty, so it is always saved, so we don't run this on existing worlds
    }
}
