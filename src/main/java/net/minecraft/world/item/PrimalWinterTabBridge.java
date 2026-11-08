package net.minecraft.world.item;

import java.util.List;
import java.util.function.Supplier;
import net.minecraft.world.level.ItemLike;

/**
 * In 26.2 {@code CreativeModeTab.Output} is no longer accessible from outside {@code net.minecraft.world.item}, which makes
 * {@link CreativeModeTab.DisplayItemsGenerator} impossible to implement from mod code. This bridge lives in that package so it can
 * implement the generator on the mod's behalf.
 */
public final class PrimalWinterTabBridge
{
    private PrimalWinterTabBridge() {}

    public static CreativeModeTab.DisplayItemsGenerator displayItems(Supplier<List<? extends ItemLike>> items)
    {
        return (params, output) -> {
            for (ItemLike item : items.get())
            {
                output.accept(item);
            }
        };
    }
}
