// Drop-in module visual: one self-rendered list row plus its selected detail pane.
// Generic control widgets are rendered/hit-tested by Core; values live in the shared registry.
#include "..\..\Core\NuraUIModuleAPI.hlsli"

Buffer<float> UIState : register(t0);
Buffer<float> ModuleSlot : register(t1);
Buffer<float> ModuleWidgets : register(t2);
Buffer<float> ModuleSettings : register(t3);
Texture1D<float4> IniParams : register(t120);

struct VSOut { float4 pos : SV_Position; };

#ifdef VERTEX_SHADER
VSOut main(uint id : SV_VertexID)
{
    VSOut o;
    if (id == 0u)      o.pos = float4(-1.0f,  1.0f, 0.0f, 1.0f);
    else if (id == 1u) o.pos = float4( 1.0f,  1.0f, 0.0f, 1.0f);
    else if (id == 2u) o.pos = float4(-1.0f, -1.0f, 0.0f, 1.0f);
    else               o.pos = float4( 1.0f, -1.0f, 0.0f, 1.0f);
    return o;
}
#else
float4 main(VSOut input) : SV_Target0
{
    uint page = (uint)max(UIState[0] + 0.5f, 0.0f);
    uint slot = (uint)max(ModuleSlot[0] + 0.5f, 0.0f);
    uint scroll = (uint)clamp(floor(IniParams[118].y + 0.5f), 0.0f, 24.0f);
    uint selectedOneBased = (uint)max(UIState[55] + 0.5f, 0.0f);
    uint hover = (uint)max(UIState[3] + 0.5f, 0.0f);
    float2 screenSize = max(float2(IniParams[31].z, IniParams[31].w), float2(1.0f, 1.0f));
    float2 p = input.pos.xy / screenSize;
    float4 color = float4(0.0f, 0.0f, 0.0f, 0.0f);

    if (page == 6u && slot < 32u)
    {
        if (slot >= scroll && slot < scroll + 8u)
        {
            float row = (float)(slot - scroll);
            float top = 0.235f + row * 0.070f;
            float2 center = float2(0.4575f, top + 0.029f);
            float2 halfSize = float2(0.1075f, 0.029f);
            float box = NuraUI_ModuleRoundRect(p, center, halfSize, 0.006f);
            bool selected = selectedOneBased == slot + 1u;
            bool hovered = hover == 600u + slot;
            float4 fill = hovered ? float4(0.0f, 0.16f, 0.21f, 1.0f)
                         : selected ? float4(0.0f, 0.12f, 0.16f, 1.0f)
                                    : float4(0.025f, 0.035f, 0.045f, 0.98f);
            color = NuraUI_ModuleOverlay(color, fill, box);
            float accent = NuraUI_ModuleBox(p, float2(0.352f, top + 0.008f), float2(0.358f, top + 0.050f));
            color = NuraUI_ModuleOverlay(color, float4(0.95f, 0.58f, 0.10f, 1.0f), accent);
        }

        if (selectedOneBased == slot + 1u)
        {
            float detail = NuraUI_ModuleRoundRect(p, float2(0.7075f, 0.5225f), float2(0.1225f, 0.3025f), 0.008f);
            float openCutout = NuraUI_ModuleBox(p, float2(0.615f, 0.680f), float2(0.800f, 0.735f));
            color = NuraUI_ModuleOverlay(color, float4(0.025f, 0.035f, 0.045f, 0.98f), detail * (1.0f - openCutout));
            float header = NuraUI_ModuleRoundRect(p, float2(0.7075f, 0.255f), float2(0.108f, 0.003f), 0.002f);
            color = NuraUI_ModuleOverlay(color, float4(0.42f, 0.22f, 0.72f, 1.0f), header);
        }
    }

    // The sample demonstrates the four persistent widget types plus Type 5:
    // slider = preview length, toggle = enable/attenuate, action = event counter,
    // cycle = output mode (four accent colors); pulse button flashes the preview for one frame.
    if (page == 7u && selectedOneBased == slot + 1u && slot < 32u)
    {
        uint sliderBase = NURAUI_MODULE_WIDGET_BASE(slot, 0u);
        uint toggleBase = NURAUI_MODULE_WIDGET_BASE(slot, 1u);
        uint actionBase = NURAUI_MODULE_WIDGET_BASE(slot, 2u);
        uint cycleBase = NURAUI_MODULE_WIDGET_BASE(slot, 3u);
        uint pulseBase = NURAUI_MODULE_WIDGET_BASE(slot, 4u);

        float globalIntensity = saturate(ModuleSettings[1]);
        float sliderValue = saturate(ModuleWidgets[sliderBase + 5u]) * globalIntensity;
        bool globalEnabled = ModuleSettings[0] > 0.5f;
        bool enabled = ModuleWidgets[toggleBase + 5u] > 0.5f && globalEnabled;
        float actionCount = max(ModuleWidgets[actionBase + 5u], 0.0f);
        uint outputMode = (uint)clamp(floor(ModuleWidgets[cycleBase + 5u] + 0.5f), 0.0f, 3.0f);

        float4 modeColor = float4(0.85f, 0.32f, 0.06f, 1.0f);
        if (outputMode == 1u) modeColor = float4(0.90f, 0.20f, 0.52f, 1.0f);
        else if (outputMode == 2u) modeColor = float4(0.10f, 0.58f, 0.95f, 1.0f);
        else if (outputMode == 3u) modeColor = float4(0.95f, 0.58f, 0.08f, 1.0f);
        float4 fillColor = enabled ? modeColor : lerp(modeColor, float4(0.020f, 0.030f, 0.040f, 1.0f), 0.72f);
        // Optional module-local response to Core's one-frame Type-5 pulse.
        bool actionPulse = ModuleWidgets[pulseBase + 5u] > 0.5f;
        if (actionPulse)
            fillColor = float4(1.0f, 0.76f, 0.12f, 1.0f);

        float2 meterMin = float2(0.420f, 0.640f);
        float2 meterMax = float2(0.790f, 0.680f);
        float outer = NuraUI_ModuleRoundRect(p, float2((meterMin.x + meterMax.x) * 0.5f, (meterMin.y + meterMax.y) * 0.5f),
            float2((meterMax.x - meterMin.x) * 0.5f, (meterMax.y - meterMin.y) * 0.5f), 0.006f);
        color = NuraUI_ModuleOverlay(color, float4(0.015f, 0.024f, 0.032f, 1.0f), outer);

        float fillRight = lerp(meterMin.x, meterMax.x, sliderValue);
        float fillMask = NuraUI_ModuleBox(p, meterMin, float2(max(fillRight, meterMin.x + 0.001f), meterMax.y));
        color = NuraUI_ModuleOverlay(color, fillColor, fillMask * step(meterMin.x + 0.002f, fillRight));
        float edge = NuraUI_ModuleRoundRect(p, float2(fillRight, 0.660f), float2(0.0035f, 0.018f), 0.002f);
        color = NuraUI_ModuleOverlay(color, float4(0.82f, 0.95f, 1.0f, 1.0f), edge);

        // Nine-step activity strip: each click advances the action counter.
        float activityPhase = fmod(floor(actionCount), 9.0f);
        [unroll]
        for (uint marker = 0u; marker < 8u; ++marker)
        {
            float segWidth = (meterMax.x - meterMin.x) / 8.0f;
            float segLeft = meterMin.x + (float)marker * segWidth + 0.002f;
            float segRight = meterMin.x + (float)(marker + 1u) * segWidth - 0.002f;
            float seg = NuraUI_ModuleRoundRect(p, float2((segLeft + segRight) * 0.5f, 0.699f),
                float2((segRight - segLeft) * 0.5f, 0.0045f), 0.002f);
            float active = step((float)marker + 1.0f, activityPhase);
            float4 activityColor = active > 0.5f ? fillColor : float4(0.035f, 0.055f, 0.065f, 1.0f);
            color = NuraUI_ModuleOverlay(color, activityColor, seg);
        }
    }
    return color;
}
#endif
