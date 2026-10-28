// NuraUI Favorite Wheel selector. Reads a cursor-centred radial wheel while F10 is held.
RWBuffer<float> UIState : register(u0);
Buffer<uint> NuraUIModuleRegistry : register(t0);
Texture1D<float4> IniParams : register(t120);
static const float NURAUI_PI = 3.14159265359f;
static const float NURAUI_TAU = 6.28318530718f;

uint FavoriteModuleId(uint index)
{
    if (index == 0u) return (uint)max(round(IniParams[121].x), 0.0f);
    if (index == 1u) return (uint)max(round(IniParams[121].y), 0.0f);
    if (index == 2u) return (uint)max(round(IniParams[121].z), 0.0f);
    if (index == 3u) return (uint)max(round(IniParams[121].w), 0.0f);
    if (index == 4u) return (uint)max(round(IniParams[122].x), 0.0f);
    if (index == 5u) return (uint)max(round(IniParams[122].y), 0.0f);
    if (index == 6u) return (uint)max(round(IniParams[122].z), 0.0f);
    return (uint)max(round(IniParams[122].w), 0.0f);
}

[numthreads(1,1,1)]
void main(uint3 id : SV_DispatchThreadID)
{
    if (IniParams[120].x < 0.5f || IniParams[120].y < 0.5f)
    {
        UIState[56] = 0.0f;
        return;
    }

    float2 screen = max(IniParams[31].zw, float2(1.0f, 1.0f));
    float2 cursor = IniParams[31].xy / screen;
    float2 center = IniParams[124].xy / screen;
    float aspect = screen.x / screen.y;
    center.x = clamp(center.x, 0.285f / max(aspect, 0.001f), 1.0f - 0.285f / max(aspect, 0.001f));
    center.y = clamp(center.y, 0.285f, 0.715f);

    float2 delta = cursor - center;
    delta.x *= aspect;
    float radius = length(delta);
    if (radius < 0.095f || radius > 0.285f)
    {
        UIState[56] = 0.0f;
        UIState[0] = IniParams[123].x;
        UIState[55] = IniParams[123].y;
        return;
    }

    float angle = atan2(delta.y, delta.x);
    if (angle < 0.0f) angle += NURAUI_TAU;
    uint favoriteIndex = (uint)floor((angle + NURAUI_PI / 8.0f) / (NURAUI_PI / 4.0f)) % 8u;
    uint wantedModuleId = FavoriteModuleId(favoriteIndex);
    if (wantedModuleId == 0u)
    {
        UIState[56] = 0.0f;
        UIState[0] = IniParams[123].x;
        UIState[55] = IniParams[123].y;
        return;
    }

    [loop]
    for (uint slot = 0u; slot < 32u; ++slot)
    {
        if (NuraUIModuleRegistry[slot] == wantedModuleId)
        {
            UIState[56] = (float)(slot + 1u);
            UIState[55] = (float)(slot + 1u);
            UIState[0] = 7.0f;
            return;
        }
    }

    // Favorite refers to a module which is not currently registered. Do not open a stale slot.
    UIState[56] = 0.0f;
    UIState[0] = IniParams[123].x;
    UIState[55] = IniParams[123].y;
}
