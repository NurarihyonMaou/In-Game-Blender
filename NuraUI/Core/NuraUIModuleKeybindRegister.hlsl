// NuraUI compact module KeyBind row registration.
// IniParams[68].x = module ID; IniParams[68].y = module-local row index (0..3).
// ModuleKeybindRegistry stores nonzero unique tokens in the compact global row order.
// ModuleKeybindSlotOut[localRow] receives the global row index (0..127), or 128 on failure.
RWBuffer<uint> ModuleRegistry : register(u0);
RWBuffer<uint> ModuleKeybindRegistry : register(u1);
RWBuffer<float> ModuleKeybindSlotOut : register(u2);
Texture1D<float4> IniParams : register(t120);

static const uint NURAUI_MODULE_CAPACITY = 32u;
static const uint NURAUI_KEYBIND_ROWS_PER_MODULE = 4u;
static const uint NURAUI_KEYBIND_ROW_CAPACITY = 128u;

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint moduleId = (uint)max(round(IniParams[68].x), 0.0f);
    uint localRow = (uint)clamp(round(IniParams[68].y), 0.0f, 3.0f);
    ModuleKeybindSlotOut[localRow] = (float)NURAUI_KEYBIND_ROW_CAPACITY;

    if (moduleId == 0u)
        return;

    // Refuse rows from modules that failed Core registration.
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

    // Module IDs are nonzero. Four adjacent tokens are reserved logically per ID.
    // Local rows 0..3 therefore remain unique without storing text in the GPU buffer.
    uint rowToken = moduleId * NURAUI_KEYBIND_ROWS_PER_MODULE + localRow;
    if (rowToken == 0u)
        return;

    uint rowSlot = NURAUI_KEYBIND_ROW_CAPACITY;
    [loop]
    for (uint j = 0u; j < NURAUI_KEYBIND_ROW_CAPACITY; ++j)
    {
        if (ModuleKeybindRegistry[j] == rowToken)
        {
            rowSlot = j;
            break;
        }
    }

    // A row that has not been registered yet claims the first free slot.
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
                break;
            }
        }
    }

    ModuleKeybindSlotOut[localRow] = (float)rowSlot;
}
