// NuraUI modular global Settings registration.
// IniParams[68] = module ID, local setting index (0..1), type (1 toggle, 2 slider), initial value.
// IniParams[69].xy = min/max. New rows are packed into a 64-entry global list.
// The local output buffer receives the global row index or 64 on failure.
RWBuffer<uint> ModuleRegistry : register(u0);
RWBuffer<uint> ModuleSettingRegistry : register(u1);
RWBuffer<float> ModuleSettingDescriptors : register(u2);
RWBuffer<float> ModuleSettingSlotOut : register(u3);
Texture1D<float4> IniParams : register(t120);

static const uint NURAUI_MODULE_CAPACITY = 32u;
static const uint NURAUI_SETTINGS_PER_MODULE = 2u;
static const uint NURAUI_SETTING_ROW_CAPACITY = 64u;
static const uint NURAUI_SETTING_STRIDE = 8u;

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint moduleId = (uint)max(round(IniParams[68].x), 0.0f);
    uint localIndex = (uint)clamp(round(IniParams[68].y), 0.0f, 1.0f);
    uint type = (uint)clamp(round(IniParams[68].z), 0.0f, 2.0f);
    ModuleSettingSlotOut[localIndex] = (float)NURAUI_SETTING_ROW_CAPACITY;
    if (moduleId == 0u || type == 0u)
        return;

    bool moduleFound = false;
    [loop]
    for (uint i = 0u; i < NURAUI_MODULE_CAPACITY; ++i)
    {
        if (ModuleRegistry[i] == moduleId)
        {
            moduleFound = true;
            break;
        }
    }
    if (!moduleFound)
        return;

    // Non-zero module ID and localIndex 0..1 produce stable, unique tokens.
    uint token = moduleId * NURAUI_SETTINGS_PER_MODULE + localIndex;
    if (token == 0u)
        return;

    uint row = NURAUI_SETTING_ROW_CAPACITY;
    bool initializeRow = false;
    [loop]
    for (uint j = 0u; j < NURAUI_SETTING_ROW_CAPACITY; ++j)
    {
        if (ModuleSettingRegistry[j] == token)
        {
            row = j;
            break;
        }
    }

    if (row == NURAUI_SETTING_ROW_CAPACITY)
    {
        [loop]
        for (uint k = 0u; k < NURAUI_SETTING_ROW_CAPACITY; ++k)
        {
            uint previousValue;
            InterlockedCompareExchange(ModuleSettingRegistry[k], 0u, token, previousValue);
            if (previousValue == 0u)
            {
                row = k;
                initializeRow = true;
                break;
            }
            if (previousValue == token)
            {
                row = k;
                break;
            }
        }
    }

    if (row >= NURAUI_SETTING_ROW_CAPACITY)
        return;

    if (initializeRow)
    {
        float minimum = IniParams[69].x;
        float maximum = max(IniParams[69].y, minimum);
        float initialValue = clamp(IniParams[68].w, minimum, maximum);
        uint base = row * NURAUI_SETTING_STRIDE;
        ModuleSettingDescriptors[base + 0u] = (float)type;
        ModuleSettingDescriptors[base + 1u] = initialValue;
        ModuleSettingDescriptors[base + 2u] = minimum;
        ModuleSettingDescriptors[base + 3u] = maximum;
        ModuleSettingDescriptors[base + 4u] = (float)moduleId;
        ModuleSettingDescriptors[base + 5u] = (float)localIndex;
        ModuleSettingDescriptors[base + 6u] = 0.0f;
        ModuleSettingDescriptors[base + 7u] = 0.0f;
    }

    ModuleSettingSlotOut[localIndex] = (float)row;
}
