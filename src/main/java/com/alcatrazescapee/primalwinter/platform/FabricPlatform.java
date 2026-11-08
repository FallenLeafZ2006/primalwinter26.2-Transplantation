package com.alcatrazescapee.primalwinter.platform;

import net.fabricmc.fabric.api.creativetab.v1.FabricCreativeModeTab;
import net.minecraft.core.Registry;
import net.minecraft.world.item.CreativeModeTab;

public final class FabricPlatform implements XPlatform
{
    private final FabricConfig config = new FabricConfig();

    @Override
    public <T> RegistryInterface<T> registryInterface(Registry<T> registry)
    {
        return new FabricRegistryInterface<>(registry);
    }

    @Override
    public CreativeModeTab.Builder creativeTab()
    {
        return FabricCreativeModeTab.builder();
    }

    @Override
    public Config config()
    {
        return config;
    }
}
