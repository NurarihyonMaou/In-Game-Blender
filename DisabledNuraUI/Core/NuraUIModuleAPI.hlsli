#ifndef NURAUI_MODULE_API_HLSLI
#define NURAUI_MODULE_API_HLSLI

// Shared visual primitives for every NuraUI module.
// p / center / halfSize are normalized screen coordinates (0..1).

float NuraUI_ModuleRoundRect(float2 p, float2 center, float2 halfSize, float radius)
{
    float2 q = abs(p - center) - halfSize + radius;
    float distanceToEdge = length(max(q, 0.0f)) + min(max(q.x, q.y), 0.0f) - radius;
    float aa = max(fwidth(distanceToEdge), 0.0005f);
    return 1.0f - smoothstep(-aa, aa, distanceToEdge);
}

float NuraUI_ModuleBox(float2 p, float2 topLeft, float2 bottomRight)
{
    float2 inside = step(topLeft, p) * step(p, bottomRight);
    return inside.x * inside.y;
}

float4 NuraUI_ModuleOverlay(float4 destination, float4 source, float mask)
{
    return lerp(destination, source, saturate(mask));
}

#endif // NURAUI_MODULE_API_HLSLI
