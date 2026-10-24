Buffer<float> UIState : register(t0);
Buffer<float4> HoverResult : register(t1);
Texture1D<float4> IniParams : register(t120);
#define SCREEN_WIDTH IniParams[31].z
#define SCREEN_HEIGHT IniParams[31].w
#define CURSOR IniParams[31].xy

struct VSOut
{
    float4 pos : SV_Position;
};

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
    return p.x >= mn.x && p.x <= mx.x && p.y >= mn.y && p.y <= mx.y ? 1.0f : 0.0f;
}

float RoundRect(float2 p, float2 mn, float2 mx, float radius)
{
    float aspect = SCREEN_WIDTH / max(SCREEN_HEIGHT, 1.0f);
    float2 center = (mn + mx) * 0.5f;
    float2 halfSize = (mx - mn) * 0.5f;
    float2 d = p - center;
    d.x *= aspect;
    halfSize.x *= aspect;
    radius *= aspect;
    float2 q = abs(d) - halfSize + radius;
    float dist = length(max(q, 0.0f)) + min(max(q.x, q.y), 0.0f) - radius;
    float aa = fwidth(dist);
    return 1.0f - smoothstep(-aa, aa, dist);
}

float Circle(float2 p, float2 center, float radius)
{
    float aspect = SCREEN_WIDTH / max(SCREEN_HEIGHT, 1.0f);
    float2 d = p - center;
    d.x *= aspect;
    float dist = length(d);
    float aa = fwidth(dist);
    return 1.0f - smoothstep(radius - aa, radius + aa, dist);
}

float4 ToolButton(uint tool, uint id, uint hover)
{
    bool active = tool == id;
    bool hovered = hover == 100u + id;
    if (hovered) return float4(0.0f, 0.16f, 0.21f, 1.0f);
    if (active) return float4(0.0f, 0.13f, 0.18f, 1.0f);
    return float4(0.035f, 0.040f, 0.048f, 0.94f);
}

float4 MirrorButton(bool active, bool hovered)
{
    if (hovered) return float4(0.0f, 0.16f, 0.21f, 1.0f);
    if (active) return float4(0.0f, 0.13f, 0.18f, 1.0f);
    return float4(0.035f, 0.040f, 0.048f, 0.94f);
}

float4 MaskActionButton(uint id, uint hover)
{
    if (hover == id)
        return float4(0.0f, 0.19f, 0.25f, 1.0f);

    if (id == 350u) // CLEAR is destructive: keep it subtly red.
        return float4(0.105f, 0.040f, 0.047f, 0.98f);

    if (id == 351u) // FILL
        return float4(0.035f, 0.070f, 0.060f, 0.98f);

    return float4(0.035f, 0.040f, 0.048f, 0.98f);
}

float BrushSurfaceRing(float2 pixelOffset, float radius, float3 rightLocal, float3 downLocal, float widthPixels)
{
    float3 localOffset = rightLocal * pixelOffset.x + downLocal * pixelOffset.y;
    float distanceLocal = length(localOffset);
    float pixelFootprint = max(fwidth(distanceLocal), 1e-6f);
    float halfWidth = pixelFootprint * widthPixels * 0.5f;
    float edgeAA = pixelFootprint * 0.75f;
    return 1.0f - smoothstep(halfWidth, halfWidth + edgeAA, abs(distanceLocal - radius));
}

float BrushSurfaceRingAtCursor(float2 p, float2 screen, float radius, float widthPixels)
{
    if (radius <= 1e-6f || HoverResult[0].x <= 0.5f ||
        HoverResult[5].w <= 0.5f || HoverResult[6].w <= 0.0f)
        return 0.0f;

    float2 pixelOffset = p * screen - CURSOR;
    return BrushSurfaceRing(
        pixelOffset, radius, HoverResult[5].xyz, HoverResult[6].xyz, widthPixels);
}

float BrushCenterMark(float2 p, float2 screen, float widthPixels)
{
    float2 d = abs(p * screen - CURSOR);
    float horizontal = (d.y <= widthPixels * 0.5f && d.x <= 4.0f) ? 1.0f : 0.0f;
    float vertical = (d.x <= widthPixels * 0.5f && d.y <= 4.0f) ? 1.0f : 0.0f;
    return max(horizontal, vertical);
}

#ifdef PIXEL_SHADER
float4 main(VSOut input) : SV_Target0
{
    float2 screen = float2(max(SCREEN_WIDTH, 1.0f), max(SCREEN_HEIGHT, 1.0f));
    float2 p = input.pos.xy / screen;
    uint tool = (uint)max(UIState[1] + 0.5f, 0.0f);
    bool weightPaint = tool == 15u;
    uint hover = (uint)max(UIState[3] + 0.5f, 0.0f);
    float mirror = UIState[5];
    uint mirrorAxis = (uint)max(UIState[6] + 0.5f, 0.0f);
    uint activeSlider = (uint)max(UIState[7] + 0.5f, 0.0f);
    float radius = UIState[8];
    float strength = UIState[9];
    uint falloffMode = (uint)clamp(UIState[16] + 0.5f, 0.0f, 4.0f);
    bool falloffOpen = UIState[17] > 0.5f;
    uint weightMode = (uint)clamp(UIState[38] + 0.5f, 0.0f, 2.0f);
    bool weightModeOpen = UIState[41] > 0.5f;
    bool mirrorOpen = UIState[42] > 0.5f;
    bool weightVGListOpen = UIState[43] > 0.5f;
    float weightVGListScroll = clamp(UIState[44], 0.0f, 110.0f);
    float weightTarget = saturate(UIState[39]);
    int activeMaskSlot = UIState[18];
    bool renameOpen = UIState[19] > 0.5f;
    uint renameSlot = (uint)clamp(UIState[20] + 0.5f, 0.0f, 7.0f);
    float4 col = float4(0.0f, 0.0f, 0.0f, 0.0f);

    uint maskPreviewFlags = (uint)max(IniParams[39].x + 0.5f, 0.0f);

    uint maskPreviewMode = (uint)clamp(IniParams[39].y + 0.5f, 0.0f, 2.0f);

    bool selectedMaskPreview = (maskPreviewFlags & (1u << activeMaskSlot)) != 0u;

    if (weightPaint)
    {
        float header = RoundRect(p, float2(0.10f, 0.015f), float2(0.99f, 0.128f), 0.012f);
        col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.96f), header);
        if (Box(p, float2(0.10f, 0.125f), float2(0.99f, 0.127f)) > 0.5f)
            col = float4(0.0f, 0.40f, 0.58f, 1.0f);
    }
    else
    {
        float header = RoundRect(p, float2(0.10f, 0.015f), float2(0.99f, 0.090f), 0.012f);
        col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.94f), header);
        if (Box(p, float2(0.10f, 0.087f), float2(0.99f, 0.089f)) > 0.5f)
            col = float4(0.0f, 0.40f, 0.58f, 1.0f);
    }

    // The tool bar is shared by every Mesh Editor tool.
    float toolbar = RoundRect(p, float2(0.012f, 0.130f), float2(0.100f, 0.799f), 0.010f);
    col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.94f), toolbar);
    if (Box(p, float2(0.012f, 0.140f), float2(0.100f, 0.205f)) > 0.5f) col = ToolButton(tool, 0u, hover);
    if (Box(p, float2(0.012f, 0.213f), float2(0.100f, 0.278f)) > 0.5f) col = ToolButton(tool, 1u, hover);
    if (Box(p, float2(0.012f, 0.286f), float2(0.100f, 0.351f)) > 0.5f) col = ToolButton(tool, 2u, hover);
    if (Box(p, float2(0.012f, 0.359f), float2(0.100f, 0.424f)) > 0.5f) col = ToolButton(tool, 3u, hover);
    if (Box(p, float2(0.012f, 0.432f), float2(0.100f, 0.497f)) > 0.5f) col = ToolButton(tool, 4u, hover);
    if (Box(p, float2(0.012f, 0.505f), float2(0.100f, 0.570f)) > 0.5f) col = ToolButton(tool, 5u, hover);
    if (Box(p, float2(0.012f, 0.578f), float2(0.100f, 0.643f)) > 0.5f) col = ToolButton(tool, 6u, hover);
    if (Box(p, float2(0.012f, 0.651f), float2(0.100f, 0.716f)) > 0.5f) col = ToolButton(tool, 7u, hover);
    if (Box(p, float2(0.012f, 0.724f), float2(0.100f, 0.789f)) > 0.5f) col = ToolButton(tool, 15u, hover);

    if (weightPaint)
    {
        // Slider labels/values occupy a dedicated line; the tracks sit below them.
        float radiusT = saturate((radius - 0.010f) / 0.990f);
        float radiusX = lerp(0.160f, 0.245f, radiusT);
        float radiusTrack = RoundRect(p, float2(0.160f, 0.072f), float2(0.245f, 0.078f), 0.003f);
        col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), radiusTrack);
        float radiusFill = RoundRect(p, float2(0.160f, 0.072f), float2(radiusX, 0.078f), 0.003f);
        col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), radiusFill);
        bool radiusActive = hover == 200u || activeSlider == 50u;
        float radiusMask = Circle(p, float2(radiusX, 0.075f), radiusActive ? 0.009f : 0.007f);
        if (radiusMask > 0.0f) col = lerp(col, radiusActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), radiusMask);

        float strengthX = lerp(0.300f, 0.365f, strength);
        float strengthTrack = RoundRect(p, float2(0.300f, 0.072f), float2(0.365f, 0.078f), 0.003f);
        col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), strengthTrack);
        float strengthFill = RoundRect(p, float2(0.300f, 0.072f), float2(strengthX, 0.078f), 0.003f);
        col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), strengthFill);
        bool strengthActive = hover == 201u || activeSlider == 51u;
        float strengthMask = Circle(p, float2(strengthX, 0.075f), strengthActive ? 0.009f : 0.007f);
        if (strengthMask > 0.0f) col = lerp(col, strengthActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), strengthMask);

        float targetX = lerp(0.405f, 0.470f, weightTarget);
        float targetTrack = RoundRect(p, float2(0.405f, 0.072f), float2(0.470f, 0.078f), 0.003f);
        col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), targetTrack);
        float targetFill = RoundRect(p, float2(0.405f, 0.072f), float2(targetX, 0.078f), 0.003f);
        col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), targetFill);
        bool targetActive = hover == 202u || activeSlider == 52u;
        float targetMask = Circle(p, float2(targetX, 0.075f), targetActive ? 0.009f : 0.007f);
        if (targetMask > 0.0f) col = lerp(col, targetActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), targetMask);

        // Dropdown buttons are vertically centred on the same control baseline.
        float falloffMask = RoundRect(p, float2(0.500f, 0.047f), float2(0.620f, 0.081f), 0.006f);
        float4 falloffColor = (hover == 230u || falloffOpen) ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.96f);
        col = lerp(col, falloffColor, falloffMask);
        if (falloffOpen)
        {
            float dropdown = RoundRect(p, float2(0.500f, 0.083f), float2(0.620f, 0.265f), 0.006f);
            col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.99f), dropdown);
            if (Box(p, float2(0.500f, 0.084f), float2(0.620f, 0.118f)) > 0.5f) col = hover == 231u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 0u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.500f, 0.120f), float2(0.620f, 0.154f)) > 0.5f) col = hover == 232u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 1u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.500f, 0.156f), float2(0.620f, 0.190f)) > 0.5f) col = hover == 233u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 2u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.500f, 0.192f), float2(0.620f, 0.226f)) > 0.5f) col = hover == 234u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 3u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.500f, 0.228f), float2(0.620f, 0.262f)) > 0.5f) col = hover == 235u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 4u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        }

        float modeMask = RoundRect(p, float2(0.640f, 0.047f), float2(0.770f, 0.081f), 0.006f);
        float4 modeButtonColor = (hover == 242u || weightModeOpen) ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.96f);
        col = lerp(col, modeButtonColor, modeMask);
        if (weightModeOpen)
        {
            float dropdown = RoundRect(p, float2(0.640f, 0.083f), float2(0.770f, 0.191f), 0.006f);
            col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.99f), dropdown);
            if (Box(p, float2(0.640f, 0.084f), float2(0.770f, 0.118f)) > 0.5f) col = hover == 243u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (weightMode == 0u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.640f, 0.120f), float2(0.770f, 0.154f)) > 0.5f) col = hover == 244u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (weightMode == 1u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.640f, 0.156f), float2(0.770f, 0.190f)) > 0.5f) col = hover == 245u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (weightMode == 2u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        }

        float mirrorMask = RoundRect(p, float2(0.790f, 0.047f), float2(0.960f, 0.081f), 0.006f);
        float4 mirrorColor = (hover == 246u || mirrorOpen) ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.96f);
        col = lerp(col, mirrorColor, mirrorMask);
        if (mirrorOpen)
        {
            float dropdown = RoundRect(p, float2(0.790f, 0.083f), float2(0.960f, 0.227f), 0.006f);
            col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.99f), dropdown);
            if (Box(p, float2(0.790f, 0.084f), float2(0.960f, 0.118f)) > 0.5f) col = hover == 247u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (mirror <= 0.5f ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.790f, 0.120f), float2(0.960f, 0.154f)) > 0.5f) col = hover == 248u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (mirror > 0.5f && mirrorAxis == 0u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.790f, 0.156f), float2(0.960f, 0.190f)) > 0.5f) col = hover == 249u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (mirror > 0.5f && mirrorAxis == 1u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.790f, 0.192f), float2(0.960f, 0.226f)) > 0.5f) col = hover == 250u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (mirror > 0.5f && mirrorAxis == 2u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        }

        // VG ID dropdown. The popup contains eight visible rows and a wheel-driven scrollbar.
        float vgBar = RoundRect(p, float2(0.120f, 0.087f), float2(0.300f, 0.120f), 0.006f);
        float4 vgButtonColor = (hover == 240u || weightVGListOpen) ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.98f);
        col = lerp(col, vgButtonColor, vgBar);
        if (weightVGListOpen)
        {
            float listPanel = RoundRect(p, float2(0.120f, 0.126f), float2(0.300f, 0.404f), 0.006f);
            col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.99f), listPanel);
            [unroll] for (uint row = 0u; row < 8u; ++row)
            {
                float rowTop = 0.130f + (float)row * 0.034f;
                float rowBottom = rowTop + 0.033f;
                float rowMask = RoundRect(p, float2(0.124f, rowTop), float2(0.285f, rowBottom), 0.003f);
                uint rowVG = (uint)clamp(weightVGListScroll + (float)row + 0.5f, 0.0f, 117.0f);
                float4 rowColor = (rowVG == (uint)(UIState[37] + 0.5f)) ? float4(0.0f, 0.13f, 0.18f, 1.0f) : (hover == 260u + row ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.98f));
                col = lerp(col, rowColor, rowMask);
            }
            float scrollTrack = RoundRect(p, float2(0.289f, 0.132f), float2(0.295f, 0.398f), 0.002f);
            col = lerp(col, float4(0.065f, 0.075f, 0.085f, 1.0f), scrollTrack);
            float thumbY = lerp(0.132f, 0.376f, weightVGListScroll / 110.0f);
            float scrollThumb = RoundRect(p, float2(0.288f, thumbY), float2(0.296f, thumbY + 0.022f), 0.002f);
            col = lerp(col, hover == 268u ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.48f, 0.64f, 1.0f), scrollThumb);
        }
    }
    else
    {
        // Legacy controls are rendered only for non-Weight-Paint tools.
        float radiusT = saturate((radius - 0.010f) / 0.990f);
        float radiusX = lerp(0.160f, 0.245f, radiusT);
        float radiusTrack = RoundRect(p, float2(0.160f, 0.051f), float2(0.245f, 0.057f), 0.003f);
        col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), radiusTrack);
        float radiusFill = RoundRect(p, float2(0.160f, 0.051f), float2(radiusX, 0.057f), 0.003f);
        col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), radiusFill);
        bool radiusActive = hover == 200u || activeSlider == 50u;
        float radiusMask = Circle(p, float2(radiusX, 0.054f), radiusActive ? 0.009f : 0.007f);
        if (radiusMask > 0.0f) col = lerp(col, radiusActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), radiusMask);

        float strengthX = lerp(0.3660f, 0.4350f, strength);
        float strengthTrack = RoundRect(p, float2(0.3660f, 0.051f), float2(0.4350f, 0.057f), 0.003f);
        col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), strengthTrack);
        float strengthFill = RoundRect(p, float2(0.3660f, 0.051f), float2(strengthX, 0.057f), 0.003f);
        col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), strengthFill);
        bool strengthActive = hover == 201u || activeSlider == 51u;
        float strengthMask = Circle(p, float2(strengthX, 0.054f), strengthActive ? 0.009f : 0.007f);
        if (strengthMask > 0.0f) col = lerp(col, strengthActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), strengthMask);

        float falloffMask = RoundRect(p, float2(0.56, 0.039f), float2(0.66f, 0.069f), 0.008f);
        float4 falloffColor = (hover == 230u || falloffOpen) ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.94f);
        col = lerp(col, falloffColor, falloffMask);
        if (falloffOpen)
        {
            float dropdown = RoundRect(p, float2(0.56, 0.071f), float2(0.66f, 0.255f), 0.008f);
            col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.98f), dropdown);
            if (Box(p, float2(0.56, 0.074f), float2(0.66f, 0.108f)) > 0.5f) col = hover == 231u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 0u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.56, 0.110f), float2(0.66, 0.144f)) > 0.5f) col = hover == 232u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 1u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.56, 0.146f), float2(0.66, 0.180f)) > 0.5f) col = hover == 233u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 2u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.56, 0.182f), float2(0.66, 0.216f)) > 0.5f) col = hover == 234u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 3u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
            if (Box(p, float2(0.56, 0.218f), float2(0.66, 0.252f)) > 0.5f) col = hover == 235u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 4u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        }

        if (Box(p, float2(0.70f, 0.060f), float2(0.74f, 0.082f)) > 0.5f) col = MirrorButton(mirror > 0.5f && mirrorAxis == 0u, hover == 210u);
        if (Box(p, float2(0.75f, 0.060f), float2(0.79f, 0.082f)) > 0.5f) col = MirrorButton(mirror > 0.5f && mirrorAxis == 1u, hover == 211u);
        if (Box(p, float2(0.80f, 0.060f), float2(0.84f, 0.082f)) > 0.5f) col = MirrorButton(mirror > 0.5f && mirrorAxis == 2u, hover == 212u);
        if (Box(p, float2(0.86f, 0.060f), float2(0.97f, 0.082f)) > 0.5f)
            col = hover == 220u ? float4(0.17f, 0.06f, 0.06f, 1.0f) : float4(0.075f, 0.040f, 0.045f, 1.0f);
    }

    if (!weightPaint)
    {
        // COMPACT NAMED MASKS PANEL — coordinates match NuraThingsUIInput.hlsl.
        float maskPanel = RoundRect(p, float2(0.750f, 0.125f), float2(0.970f, 0.665f), 0.010f);
        col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.96f), maskPanel);

        float2 rowMin[8] = {
            float2(0.760f,0.140f), float2(0.760f,0.187f),
            float2(0.760f,0.234f), float2(0.760f,0.281f),
            float2(0.760f,0.328f), float2(0.760f,0.375f),
            float2(0.760f,0.422f), float2(0.760f,0.469f)
        };
        float2 rowMax[8] = {
            float2(0.960f,0.183f), float2(0.960f,0.230f),
            float2(0.960f,0.277f), float2(0.960f,0.324f),
            float2(0.960f,0.371f), float2(0.960f,0.418f),
            float2(0.960f,0.465f), float2(0.960f,0.512f)
        };

        [unroll] for (uint slot = 0u; slot < 8u; ++slot)
        {
            float row = Box(p, rowMin[slot], rowMax[slot]);

            float selectBox = Box(
                p,
                float2(0.787f, rowMin[slot].y),
                float2(0.874f, rowMax[slot].y)
            );

            float renameBox = Box(
                p,
                float2(0.880f, rowMin[slot].y),
                rowMax[slot]
            );

            if (row > 0.5f)
            {
                if (hover == 300u + slot ||
                    hover == 320u + slot)
                {
                    col = float4(0.0f, 0.16f, 0.21f, 1.0f);
                }
                else if (activeMaskSlot != -1 && activeMaskSlot == (int)slot && selectBox > 0.5f)
                {
                    // Main editable mask.
                    col = float4(0.0f, 0.13f, 0.18f, 1.0f);
                }
                else
                {
                    col = float4(0.035f, 0.040f, 0.048f, 0.96f);
                }

                if (renameBox > 0.5f)
                {
                    col = hover == 320u + slot
                        ? float4(0.0f, 0.16f, 0.21f, 1.0f)
                        : float4(0.075f, 0.080f, 0.090f, 1.0f);
                }

                // Checkbox: this mask is included in the preview.
                float checkShape = RoundRect(
                    p,
                    float2(0.765f, rowMin[slot].y + 0.010f),
                    float2(0.780f, rowMax[slot].y - 0.010f),
                    0.002f
                );

                bool previewEnabled =
                    (maskPreviewFlags & (1u << slot)) != 0u;

                float4 checkColor;

                if (hover == 330u + slot || hover == 300u + slot)
                {
                    checkColor = float4(0.0f, 0.19f, 0.25f, 1.0f);
                }
                else if (previewEnabled)
                {
                    checkColor = float4(0.0f, 0.55f, 0.72f, 1.0f);
                }
                else
                {
                    checkColor = float4(0.075f, 0.085f, 0.100f, 1.0f);
                }

                col = lerp(col, checkColor, checkShape);
            }
        }

        // -------------------------------------------------------------------------
        // Named-mask preview controls: VIEW, ALL/NONE, current preview mode.
        // -------------------------------------------------------------------------
    
        float b;
    
        // ALL / NONE
        b = RoundRect(p, float2(0.780f, 0.516f), float2(0.860f, 0.548f), 0.004f);
    
        float4 allColor =
            hover == 361u
                ? float4(0.0f, 0.19f, 0.25f, 1.0f)
                : maskPreviewFlags == 255u
                    ? float4(0.0f, 0.13f, 0.18f, 1.0f)
                    : float4(0.035f, 0.040f, 0.048f, 0.98f);
    
        col = lerp(col, allColor, b);
    
        // MODE
        b = RoundRect(p, float2(0.885f, 0.516f), float2(0.960f, 0.548f), 0.004f);
    
        float4 modeColor;
    
        if (hover == 362u)
            modeColor = float4(0.0f, 0.19f, 0.25f, 1.0f);
        else if (maskPreviewMode == 0u)
            modeColor = float4(0.0f, 0.13f, 0.18f, 1.0f);
        else if (maskPreviewMode == 1u)
            modeColor = float4(0.15f, 0.045f, 0.05f, 1.0f);
        else
            modeColor = float4(0.12f, 0.065f, 0.18f, 1.0f);
    
        col = lerp(col, modeColor, b);

        // Mask operation buttons: Clear, Fill, Invert, Threshold, Contrast, Smooth, Sharpen.
    
        b = RoundRect(p, float2(0.760f, 0.555f), float2(0.805f, 0.593f), 0.004f);
        col = lerp(col, MaskActionButton(350u, hover), b);
        b = RoundRect(p, float2(0.810f, 0.555f), float2(0.855f, 0.593f), 0.004f);
        col = lerp(col, MaskActionButton(351u, hover), b);
        b = RoundRect(p, float2(0.860f, 0.555f), float2(0.905f, 0.593f), 0.004f);
        col = lerp(col, MaskActionButton(352u, hover), b);
        b = RoundRect(p, float2(0.910f, 0.555f), float2(0.960f, 0.593f), 0.004f);
        col = lerp(col, MaskActionButton(353u, hover), b);
        b = RoundRect(p, float2(0.768f, 0.600f), float2(0.828f, 0.638f), 0.004f);
        col = lerp(col, MaskActionButton(354u, hover), b);
        b = RoundRect(p, float2(0.833f, 0.600f), float2(0.893f, 0.638f), 0.004f);
        col = lerp(col, MaskActionButton(355u, hover), b);
        b = RoundRect(p, float2(0.898f, 0.600f), float2(0.960f, 0.638f), 0.004f);
        col = lerp(col, MaskActionButton(356u, hover), b);

    }

    if (renameOpen)
    {
        float modal = RoundRect(p, float2(0.33f,0.32f), float2(0.67f,0.66f), 0.014f);
        col = lerp(col, float4(0.012f,0.016f,0.022f,0.99f), modal);
        float modalEdge = Box(p, float2(0.33f,0.32f), float2(0.67f,0.327f));
        col = lerp(col, float4(0.0f,0.52f,0.70f,1.0f), modalEdge);
        float editBox = RoundRect(p, float2(0.36f,0.435f), float2(0.64f,0.515f), 0.006f);
        col = lerp(col, float4(0.035f,0.045f,0.055f,1.0f), editBox);
        float saveBox = RoundRect(p, float2(0.36f,0.58f), float2(0.49f,0.625f), 0.006f);
        col = lerp(col, hover == 340u ? float4(0.0f,0.20f,0.25f,1.0f) : float4(0.0f,0.13f,0.18f,1.0f), saveBox);
        float cancelBox = RoundRect(p, float2(0.51f,0.58f), float2(0.64f,0.625f), 0.006f);
        col = lerp(col, hover == 341u ? float4(0.22f,0.07f,0.08f,1.0f) : float4(0.075f,0.040f,0.045f,1.0f), cancelBox);
    }

    // BRUSH PREVIEW
    // Hide the surface brush while the pointer is over the UI itself.
    bool overUI =
        p.x <= 0.11f ||
        p.x >= 0.750f ||
        (weightPaint ? (p.y <= 0.130f || falloffOpen || weightModeOpen || mirrorOpen) : (p.y <= 0.095f || falloffOpen)) ||
        renameOpen;

    if (!overUI && HoverResult[0].x > 0.5f)
    {
        // Dark under-stroke keeps the radius visible against both bright and dark mesh areas.
        float outerRing = BrushSurfaceRingAtCursor(p, screen, radius, 4.0f);
        col = lerp(col, float4(0.005f, 0.010f, 0.016f, 1.0f), outerRing);

        // A crisp cyan line sits on top of the dark outline. Width is measured in screen pixels;
        // fwidth(distanceLocal) converts that width to this triangle's local-space basis.
        float ring = BrushSurfaceRingAtCursor(p, screen, radius, 1.6f);
        col = lerp(col, float4(0.05f, 0.88f, 1.0f, 1.0f), ring);

        // Small centered crosshair; there is no translucent filled disc anymore.
        float centerShadow = BrushCenterMark(p, screen, 3.0f);
        col = lerp(col, float4(0.005f, 0.010f, 0.016f, 1.0f), centerShadow);
        float centerMark = BrushCenterMark(p, screen, 1.0f);
        col = lerp(col, float4(0.95f, 1.0f, 1.0f, 1.0f), centerMark);
    }

    return col;
}
#endif
