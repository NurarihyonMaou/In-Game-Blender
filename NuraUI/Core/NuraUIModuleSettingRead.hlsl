// Copies the current module-owned global setting values into a compact two-value buffer.
// This lets module INIs use fixed store indices for persistent variables.
Buffer<float> ModuleSettingSlots : register(t0);
Buffer<float> ModuleSettingDescriptors : register(t1);
RWBuffer<float> ModuleSettingValues : register(u0);

static const uint NURAUI_SETTING_ROW_CAPACITY = 64u;
static const uint NURAUI_SETTING_STRIDE = 8u;

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    [unroll]
    for (uint localIndex = 0u; localIndex < 2u; ++localIndex)
    {
        uint row = (uint)max(round(ModuleSettingSlots[localIndex]), 0.0f);
        // The module pre-seeds ModuleSettingValues with its own defaults/current
        // values. Only overwrite entries backed by a valid Core row so unused
        // optional settings keep their module-owned fallback value.
        if (row < NURAUI_SETTING_ROW_CAPACITY)
            ModuleSettingValues[localIndex] = ModuleSettingDescriptors[row * NURAUI_SETTING_STRIDE + 1u];
    }
}
