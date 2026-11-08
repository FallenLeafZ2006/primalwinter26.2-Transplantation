package com.alcatrazescapee.primalwinter.platform;

import java.util.function.Supplier;
import net.minecraft.core.Holder;
import net.minecraft.core.Registry;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.Identifier;

public interface RegistryHolder<T> extends Supplier<T>
{
    @Override
    T get();

    Identifier id();
}
