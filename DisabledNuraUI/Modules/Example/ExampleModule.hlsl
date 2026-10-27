// NuraUI Drop-in Module demo panel.
#include "..\..\Core\NuraUIModuleAPI.hlsli"

Buffer<float> ModuleSlot : register(t0);
Texture1D<float4> IniParams : register(t120);

struct VSOut
{
    float4 pos : SV_Position;
};

#ifdef VERTEX_SHADER
VSOut main(uint id : SV_VertexID)
{
    VSOut o;
    if (id == 0u)
        o.pos = float4(-1.0f,  1.0f, 0.0f, 1.0f);
    else if (id == 1u)
        o.pos = float4( 1.0f,  1.0f, 0.0f, 1.0f);
    else if (id == 2u)
        o.pos = float4(-1.0f, -1.0f, 0.0f, 1.0f);
    else
        o.pos = float4( 1.0f, -1.0f, 0.0f, 1.0f);
    return o;
}
#else
float4 main(VSOut input) : SV_Target
{
    uint slot = (uint)max(ModuleSlot[0], 0.0f);
    if (slot >= 32u)
        discard;

    float2 screenSize = max(float2(IniParams[31].z, IniParams[31].w), float2(1.0f, 1.0f));
    float2 p = input.pos.xy / screenSize;

    float outer = NuraUI_ModuleRoundRect(p, float2(0.50f, 0.50f), float2(0.245f, 0.155f), 0.012f);
    float inner = NuraUI_ModuleRoundRect(p, float2(0.50f, 0.50f), float2(0.241f, 0.151f), 0.010f);
    float border = saturate(outer - inner);

    float4 color = float4(0.0f, 0.0f, 0.0f, 0.0f);
    color = NuraUI_ModuleOverlay(color, float4(0.012f, 0.018f, 0.027f, 0.96f), outer);
    color = NuraUI_ModuleOverlay(color, float4(0.00f, 0.68f, 0.88f, 0.95f), border);

    // Header line and a small visual slot meter; the bar length reflects this
    // module's automatically assigned registry slot (0..31).
    float headerLine = NuraUI_ModuleRoundRect(p, float2(0.50f, 0.505f), float2(0.205f, 0.0015f), 0.001f);
    color = NuraUI_ModuleOverlay(color, float4(0.04f, 0.20f, 0.25f, 0.90f), headerLine);

    float progress = ((float)slot + 1.0f) / 32.0f;
    float barTrack = NuraUI_ModuleRoundRect(p, float2(0.50f, 0.61f), float2(0.18f, 0.006f), 0.005f);
    float barFill = NuraUI_ModuleRoundRect(p, float2(0.32f + 0.18f * progress, 0.61f), float2(0.18f * progress, 0.006f), 0.005f);
    color = NuraUI_ModuleOverlay(color, float4(0.05f, 0.07f, 0.09f, 0.95f), barTrack);
    color = NuraUI_ModuleOverlay(color, float4(0.0f, 0.60f, 0.78f, 1.0f), barFill);

    return color;
}
#endif
