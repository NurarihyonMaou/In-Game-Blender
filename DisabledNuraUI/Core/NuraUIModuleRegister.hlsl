// NuraUI Drop-in Module Registry
// One dispatch per module on first frame. The module ID is passed in IniParams[68].x.
// Each module writes its discovered slot to its own one-element RWBuffer.

RWBuffer<uint> ModuleRegistry : register(u0);
RWBuffer<float> ModuleSlotOut : register(u1);
Texture1D<float4> IniParams   : register(t120);

static const uint NURAUI_MODULE_CAPACITY = 32u;

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint moduleId = (uint)max(round(IniParams[68].x), 0.0f);
    uint slot = NURAUI_MODULE_CAPACITY;

    if (moduleId != 0u)
    {
        // Reuse the existing slot if this ID has already registered.
        [loop]
        for (uint i = 0u; i < NURAUI_MODULE_CAPACITY; ++i)
        {
            if (ModuleRegistry[i] == moduleId)
            {
                slot = i;
                break;
            }
        }

        // Otherwise claim the first empty slot. InterlockedCompareExchange
        // prevents two modules from taking the same slot if dispatch order changes.
        if (slot == NURAUI_MODULE_CAPACITY)
        {
            [loop]
            for (uint j = 0u; j < NURAUI_MODULE_CAPACITY; ++j)
            {
                uint previousValue;
                InterlockedCompareExchange(ModuleRegistry[j], 0u, moduleId, previousValue);
                if (previousValue == 0u || previousValue == moduleId)
                {
                    slot = j;
                    break;
                }
            }
        }
    }

    ModuleSlotOut[0] = (float)slot;
}
