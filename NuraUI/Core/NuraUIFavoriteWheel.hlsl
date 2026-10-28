Buffer<float> UIState : register(t0);
Buffer<uint> NuraUIModuleRegistry : register(t1);
Texture1D<float4> IniParams : register(t120);
#define SCREEN_WIDTH max(IniParams[31].z, 1.0f)
#define SCREEN_HEIGHT max(IniParams[31].w, 1.0f)
struct VSOut { float4 pos : SV_Position; };
#ifdef VERTEX_SHADER
VSOut main(uint id : SV_VertexID)
{
    VSOut o;
    if (id == 0u) o.pos = float4(-1.0f, 1.0f, 0.0f, 1.0f);
    else if (id == 1u) o.pos = float4(1.0f, 1.0f, 0.0f, 1.0f);
    else if (id == 2u) o.pos = float4(-1.0f, -1.0f, 0.0f, 1.0f);
    else o.pos = float4(1.0f, -1.0f, 0.0f, 1.0f);
    return o;
}
#endif
float Box(float2 p, float2 mn, float2 mx)
{
    return (p.x >= mn.x && p.x <= mx.x && p.y >= mn.y && p.y <= mx.y) ? 1.0f : 0.0f;
}
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
bool IsRegistered(uint moduleId)
{
    if (moduleId == 0u) return false;
    [loop] for (uint i = 0u; i < 32u; ++i) if (NuraUIModuleRegistry[i] == moduleId) return true;
    return false;
}
uint RegisteredSlotPlusOne(uint moduleId)
{
    if (moduleId == 0u) return 0u;
    [loop] for (uint i = 0u; i < 32u; ++i) if (NuraUIModuleRegistry[i] == moduleId) return i + 1u;
    return 0u;
}
float SegDigit(float2 p, uint digit)
{
    float s0 = Box(p, float2(-0.011f,-0.022f), float2(0.011f,-0.017f));
    float s1 = Box(p, float2(0.010f,-0.016f), float2(0.015f,-0.001f));
    float s2 = Box(p, float2(0.010f, 0.001f), float2(0.015f, 0.016f));
    float s3 = Box(p, float2(-0.011f,0.017f), float2(0.011f,0.022f));
    float s4 = Box(p, float2(-0.015f,0.001f), float2(-0.010f,0.016f));
    float s5 = Box(p, float2(-0.015f,-0.016f), float2(-0.010f,-0.001f));
    float s6 = Box(p, float2(-0.011f,-0.002f), float2(0.011f,0.002f));
    bool a = false, b = false, c = false, d = false, e = false, f = false, g = false;
    if (digit == 1u) { b = true; c = true; }
    else if (digit == 2u) { a=true; b=true; g=true; e=true; d=true; }
    else if (digit == 3u) { a=true; b=true; g=true; c=true; d=true; }
    else if (digit == 4u) { f=true; g=true; b=true; c=true; }
    else if (digit == 5u) { a=true; f=true; g=true; c=true; d=true; }
    else if (digit == 6u) { a=true; f=true; g=true; e=true; c=true; d=true; }
    else if (digit == 7u) { a=true; b=true; c=true; }
    else { a=true; b=true; c=true; d=true; e=true; f=true; g=true; }
    return max(max(max(a?s0:0.0f,b?s1:0.0f), max(c?s2:0.0f,d?s3:0.0f)), max(max(e?s4:0.0f,f?s5:0.0f),g?s6:0.0f));
}
#ifdef PIXEL_SHADER
float4 main(VSOut input) : SV_Target0
{
    float2 screen = float2(SCREEN_WIDTH, SCREEN_HEIGHT);
    float2 p = input.pos.xy / screen;
    float2 center = IniParams[124].xy / screen;
    float aspect = screen.x / screen.y;
    center.x = clamp(center.x, 0.285f / max(aspect, 0.001f), 1.0f - 0.285f / max(aspect, 0.001f));
    center.y = clamp(center.y, 0.285f, 0.715f);
    float4 col = float4(0.006f, 0.010f, 0.016f, 0.0f);
    col.a = 0.0f;
    // Dim only the central wheel backdrop to keep the game visible.
    float2 v = p - center;
    v.x *= aspect;
    float radius = length(v);
    if (radius < 0.305f) col = float4(0.006f, 0.010f, 0.016f, 0.36f);
    if (radius < 0.276f && radius > 0.100f)
    {
        float angle = atan2(v.y, v.x);
        if (angle < 0.0f) angle += 6.28318530718f;
        uint sector = (uint)floor((angle + 0.3926990817f) / 0.7853981634f) % 8u;
        float sectorAngle = (float)sector * 0.7853981634f;
        float delta = atan2(sin(angle - sectorAngle), cos(angle - sectorAngle));
        bool inSector = abs(delta) <= 0.3926990817f;
        if (inSector)
        {
            uint moduleId = FavoriteModuleId(sector);
            bool valid = IsRegistered(moduleId);
            if (valid)
            {
                uint sectorModuleSlot = RegisteredSlotPlusOne(moduleId);
                bool selectedSector = UIState[56] > 0.5f && sectorModuleSlot > 0u &&
                                      (uint)round(UIState[56]) == sectorModuleSlot &&
                                      (uint)round(UIState[55]) == sectorModuleSlot;
                float4 baseColor = selectedSector
                    ? float4(0.0f, 0.20f, 0.27f, 0.96f)
                    : float4(0.022f, 0.040f, 0.052f, 0.94f);
                col = baseColor;
                float radialEdge = (radius < 0.105f || radius > 0.272f) ? 0.0f : 1.0f;
                if (radialEdge > 0.5f && (abs(delta) > 0.374f)) col = float4(0.0f,0.45f,0.65f,0.95f);
            }
        }
    }
    // Outer and inner rings, drawn over sector fills.
    float outerRing = 1.0f - smoothstep(0.002f, 0.005f, abs(radius - 0.278f));
    float innerRing = 1.0f - smoothstep(0.002f, 0.005f, abs(radius - 0.098f));
    col = lerp(col, float4(0.0f,0.55f,0.78f,0.98f), saturate(max(outerRing, innerRing)));
    if (radius < 0.095f) col = float4(0.018f,0.030f,0.042f,0.98f);
    // Numeric labels represent favorite order 1..8, starting at the right and moving clockwise.
    [unroll] for (uint i=0u; i<8u; ++i)
    {
        uint mid = FavoriteModuleId(i);
        if (!IsRegistered(mid)) continue;
        float angle = (float)i * 0.7853981634f;
        float2 labelCenter = center + float2(cos(angle) * 0.190f / max(aspect,0.001f), sin(angle) * 0.190f);
        float2 q = p - labelCenter;
        q.x *= aspect;
        float glyph = SegDigit(q, i + 1u);
        uint labelModuleSlot = RegisteredSlotPlusOne(mid);
        bool selectedLabel = UIState[56] > 0.5f && labelModuleSlot > 0u &&
                             (uint)round(UIState[56]) == labelModuleSlot &&
                             (uint)round(UIState[55]) == labelModuleSlot;
        float4 digitColor = selectedLabel
            ? float4(0.25f,0.92f,1.0f,1.0f) : float4(0.82f,0.91f,0.96f,1.0f);
        col = lerp(col, digitColor, glyph);
    }
    return col;
}
#endif
