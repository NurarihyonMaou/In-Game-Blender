// NuraUI compact module KeyBind row registration.
// IniParams[68].x = module ID; .y = local row (0..3); .z = initial persisted key ID (0..36).
// The caller gates this dispatch on its own module-registration flag. Keep u0 reserved for
// compatibility with existing module INIs, but do not make row registration depend on
// rereading ModuleRegistry; a one-time registry lookup failure used to permanently hide rows.
// Key IDs: 0 = unbound, 1..26 = A..Z, 27..36 = 0..9.
// Descriptor stride: moduleId, localRow, keyId, stable token.
RWBuffer<uint> ModuleRegistry : register(u0); // Kept for the existing module binding layout; intentionally not used as a gate.
RWBuffer<uint> ModuleKeybindRegistry : register(u1);
RWBuffer<float> ModuleKeybindDescriptors : register(u2);
RWBuffer<float> ModuleKeybindSlotOut : register(u3);
Texture1D<float4> IniParams : register(t120);

static const uint NURAUI_MODULE_CAPACITY = 32u;
static const uint NURAUI_KEYBIND_ROWS_PER_MODULE = 4u;
static const uint NURAUI_KEYBIND_ROW_CAPACITY = 128u;

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint moduleId = (uint)max(round(IniParams[68].x), 0.0f);
    uint localRow = (uint)clamp(round(IniParams[68].y), 0.0f, 3.0f);
    uint initialKey = (uint)clamp(round(IniParams[68].z), 0.0f, 36.0f);
    ModuleKeybindSlotOut[localRow] = (float)NURAUI_KEYBIND_ROW_CAPACITY;
    if (moduleId == 0u) return;

    uint rowToken = moduleId * NURAUI_KEYBIND_ROWS_PER_MODULE + localRow;
    if (rowToken == 0u) return;

    uint rowSlot = NURAUI_KEYBIND_ROW_CAPACITY;
    bool initializeRow = false;
    [loop]
    for (uint j = 0u; j < NURAUI_KEYBIND_ROW_CAPACITY; ++j)
    {
        if (ModuleKeybindRegistry[j] == rowToken) { rowSlot = j; break; }
    }
    if (rowSlot == NURAUI_KEYBIND_ROW_CAPACITY)
    {
        [loop]
        for (uint k = 0u; k < NURAUI_KEYBIND_ROW_CAPACITY; ++k)
        {
            uint previousValue;
            InterlockedCompareExchange(ModuleKeybindRegistry[k], 0u, rowToken, previousValue);
            if (previousValue == 0u || previousValue == rowToken)
            {
                rowSlot = k;
                initializeRow = (previousValue == 0u);
                break;
            }
        }
    }

    if (rowSlot < NURAUI_KEYBIND_ROW_CAPACITY)
    {
        uint base = rowSlot * 4u;
        uint descriptorToken = (uint)max(round(ModuleKeybindDescriptors[base + 3u]), 0.0f);
        // Repair a missing/stale descriptor even if the compact registry token survived.
        // Preserve an already assigned key when the descriptor is intact.
        if (initializeRow || descriptorToken != rowToken)
        {
            ModuleKeybindDescriptors[base + 0u] = (float)moduleId;
            ModuleKeybindDescriptors[base + 1u] = (float)localRow;
            ModuleKeybindDescriptors[base + 2u] = (float)initialKey;
            ModuleKeybindDescriptors[base + 3u] = (float)rowToken;
        }
        else
        {
            ModuleKeybindDescriptors[base + 0u] = (float)moduleId;
            ModuleKeybindDescriptors[base + 1u] = (float)localRow;
        }
    }
    ModuleKeybindSlotOut[localRow] = (float)rowSlot;
}
