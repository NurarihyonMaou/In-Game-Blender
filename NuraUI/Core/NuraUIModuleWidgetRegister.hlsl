// NuraUI Drop-in Widget Registry
// IniParams[68]: moduleId, widgetIndex, widgetType, x1
// IniParams[69]: y1, x2, y2, defaultValue
// IniParams[70]: minValue, maxValue, reserved, reserved
// Type 1 = slider, 2 = toggle, 3 = action counter, 4 = cycle selector. Positions are normalized (0..1).
RWBuffer<uint> ModuleRegistry : register(u0);
RWBuffer<float> ModuleWidgets : register(u1);
Texture1D<float4> IniParams : register(t120);

static const uint NURAUI_MODULE_CAPACITY = 32u;
static const uint NURAUI_WIDGETS_PER_MODULE = 8u;
static const uint NURAUI_WIDGET_STRIDE = 8u;

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint moduleId = (uint)max(round(IniParams[68].x), 0.0f);
    uint widgetIndex = (uint)clamp(round(IniParams[68].y), 0.0f, 7.0f);
    uint widgetType = (uint)clamp(round(IniParams[68].z), 0.0f, 4.0f);
    if (moduleId == 0u || widgetType == 0u)
        return;

    uint moduleSlot = NURAUI_MODULE_CAPACITY;
    [loop]
    for (uint i = 0u; i < NURAUI_MODULE_CAPACITY; ++i)
    {
        if (ModuleRegistry[i] == moduleId)
        {
            moduleSlot = i;
            break;
        }
    }
    if (moduleSlot >= NURAUI_MODULE_CAPACITY)
        return;

    uint base = (moduleSlot * NURAUI_WIDGETS_PER_MODULE + widgetIndex) * NURAUI_WIDGET_STRIDE;
    ModuleWidgets[base + 0u] = (float)widgetType;
    ModuleWidgets[base + 1u] = IniParams[68].w;
    ModuleWidgets[base + 2u] = IniParams[69].x;
    ModuleWidgets[base + 3u] = IniParams[69].y;
    ModuleWidgets[base + 4u] = IniParams[69].z;
    ModuleWidgets[base + 5u] = IniParams[69].w;
    ModuleWidgets[base + 6u] = IniParams[70].x;
    ModuleWidgets[base + 7u] = IniParams[70].y;
}
