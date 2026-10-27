Buffer<float> UIState : register(t0);
Buffer<float> NuraUIModuleWidgets : register(t1);

Texture1D<float4> IniParams : register(t120);

#define SCREEN_WIDTH IniParams[31].z

#define SCREEN_HEIGHT IniParams[31].w

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

#endif

float Box(float2 p, float2 minP, float2 maxP)

{

    if (p.x >= minP.x && p.x <= maxP.x &&

        p.y >= minP.y && p.y <= maxP.y)

        return 1.0f;

    return 0.0f;

}

float RoundRect(float2 p, float2 minP, float2 maxP, float radius)

{

    float aspect = SCREEN_WIDTH / max(SCREEN_HEIGHT, 1.0f);

    float2 center = (minP + maxP) * 0.5f;

    float2 halfSize = (maxP - minP) * 0.5f;

    float2 d = p - center;

    d.x *= aspect;

    halfSize.x *= aspect;

    radius *= aspect;

    float2 q = abs(d) - halfSize + radius;

    float dist = length(max(q, 0.0f)) +

                 min(max(q.x, q.y), 0.0f) - radius;

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

float4 ButtonColor(bool active, bool hovered)
{
    if (hovered)
        return float4(0.0f, 0.16f, 0.21f, 1.0f);

    if (active)
        return float4(0.0f, 0.15f, 0.20f, 1.0f);

    return float4(0.0f, 0.07f, 0.09f, 1.0f);
}

float4 JiggleSlider(float2 p, float4 col, float y, float value, uint id, uint hover, uint activeSlider)
{
    float knobX = lerp(0.51f, 0.73f, saturate(value));
    float track = RoundRect(p, float2(0.51f, y - 0.008f), float2(0.73f, y + 0.008f), 0.006f);
    col = lerp(col, float4(0.020f, 0.030f, 0.040f, 1.0f), track);

    float fill = RoundRect(p, float2(0.51f, y - 0.008f), float2(knobX, y + 0.008f), 0.006f);
    col = lerp(col, float4(0.0f, 0.12f, 0.16f, 1.0f), fill);

    bool selected = (hover == id || activeSlider == id);
    float knob = Circle(p, float2(knobX, y), selected ? 0.010f : 0.0075f);
    if (knob > 0.0f)
    {
        float4 knobColor = selected
            ? float4(0.0f, 0.65f, 0.85f, 1.0f)
            : float4(0.0f, 0.45f, 0.65f, 1.0f);
        col = lerp(col, knobColor, knob);
    }

    return col;
}

#ifdef PIXEL_SHADER

float4 main(VSOut input) : SV_Target0

{

    float2 screen = float2(

        max(SCREEN_WIDTH, 1.0f),

        max(SCREEN_HEIGHT, 1.0f)

    );

    float2 p = input.pos.xy / screen;

    uint page = (uint)max(UIState[0] + 0.5f, 0.0f);

    uint tool = (uint)max(UIState[1] + 0.5f, 0.0f);

    uint hover = (uint)max(UIState[3] + 0.5f, 0.0f);

    uint falloffMode = (uint)clamp(UIState[16] + 0.5f, 0.0f, 4.0f);

    bool falloffDropdownOpen = UIState[17] > 0.5f;

    float mirror = UIState[5];

    uint mirrorAxis = (uint)max(UIState[6] + 0.5f, 0.0f);

    uint activeSlider = (uint)max(UIState[7] + 0.5f, 0.0f);
    uint selectedModuleOneBased = (uint)max(UIState[55] + 0.5f, 0.0f);

    float radius = UIState[8];

    float strength = UIState[9];

    uint jiggleGroup = (uint)clamp(UIState[21] + 0.5f, 0.0f, 7.0f);
    float jiggleEnabled = UIState[22];
    uint jiggleMaskSlot = (uint)clamp(UIState[23] + 0.5f, 0.0f, 7.0f);
    float jiggleStiffness = UIState[24];
    float jiggleDamping = UIState[25];
    float jiggleStrength = UIState[26];
    float jiggleInertia = UIState[27];
    float jiggleMaxOffset = UIState[28];
    uint jiggleTab = (uint)clamp(UIState[29] + 0.5f, 0.0f, 2.0f);
    float jiggleAxisX = UIState[30];
    float jiggleAxisY = UIState[31];
    float jiggleAxisZ = UIState[32];
    float jiggleGravity = UIState[33];
    float jiggleMotionSensitivity = UIState[34];
    float jiggleMotionSmoothing = UIState[35];
    float jiggleEdgeFalloff = UIState[36];

    float4 col = float4(0.0f, 0.0f, 0.0f, 0.0f);

    // =========================================================================
    // MAIN WINDOW
    // =========================================================================
    if (Box(p, float2(0.16f, 0.12f), float2(0.86f, 0.88f)) > 0.5f)

    {

        col = float4(0.025f, 0.030f, 0.040f, 0.96f);

        // ---------------------------------------------------------------------
        // Header
        // ---------------------------------------------------------------------
        if (Box(p, float2(0.16f, 0.12f), float2(0.86f, 0.18f)) > 0.5f)

            col = float4(0.035f, 0.045f, 0.055f, 1.0f);

        if (Box(p, float2(0.16f, 0.178f), float2(0.86f, 0.181f)) > 0.5f)

            col = float4(0.0f, 0.45f, 0.65f, 1.0f);

        // ---------------------------------------------------------------------
        // Sidebar
        // ---------------------------------------------------------------------
        if (Box(p, float2(0.16f, 0.18f), float2(0.33f, 0.88f)) > 0.5f)

            col = float4(0.018f, 0.022f, 0.030f, 1.0f);

        if (Box(p, float2(0.17f, 0.23f), float2(0.32f, 0.31f)) > 0.5f)

            col = page == 0u

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        if (Box(p, float2(0.17f, 0.32f), float2(0.32f, 0.40f)) > 0.5f)

            col = page == 1u

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        if (Box(p, float2(0.17f, 0.41f), float2(0.32f, 0.49f)) > 0.5f)

            col = page == 2u

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        if (Box(p, float2(0.17f, 0.50f), float2(0.32f, 0.58f)) > 0.5f)

            col = page == 3u

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        if (Box(p, float2(0.17f, 0.59f), float2(0.32f, 0.67f)) > 0.5f)

            col = page == 4u

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        if (Box(p, float2(0.17f, 0.68f), float2(0.32f, 0.76f)) > 0.5f)

            col = page == 5u

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        if (Box(p, float2(0.17f, 0.77f), float2(0.32f, 0.85f)) > 0.5f)

            col = (page == 6u || page == 7u)

                ? float4(0.0f, 0.10f, 0.14f, 1.0f)

                : float4(0.025f, 0.030f, 0.040f, 1.0f);

        // =========================================================================
        // MESH PAGE
        // =========================================================================
        if (page == 0u)

        {

            // ---------------------------------------------------------------------
            // Tools card
            // ---------------------------------------------------------------------
            if (Box(p, float2(0.35f, 0.21f), float2(0.83f, 0.59f)) > 0.5f)

                col = float4(0.035f, 0.045f, 0.055f, 1.0f);

            // Grab
            if (Box(p, float2(0.36f, 0.27f), float2(0.59f, 0.335f)) > 0.5f)

                col = ButtonColor(tool == 0u, hover == 30u);

            // Inflate
            if (Box(p, float2(0.60f, 0.27f), float2(0.82f, 0.335f)) > 0.5f)

                col = ButtonColor(tool == 1u, hover == 31u);

            // Smooth
            if (Box(p, float2(0.36f, 0.345f), float2(0.59f, 0.410f)) > 0.5f)

                col = ButtonColor(tool == 2u, hover == 32u);

            // Pinch
            if (Box(p, float2(0.60f, 0.345f), float2(0.82f, 0.410f)) > 0.5f)

                col = ButtonColor(tool == 3u, hover == 33u);

            // Crease
            if (Box(p, float2(0.36f, 0.420f), float2(0.59f, 0.485f)) > 0.5f)

                col = ButtonColor(tool == 4u, hover == 34u);

            // Flatten
            if (Box(p, float2(0.60f, 0.420f), float2(0.82f, 0.485f)) > 0.5f)

                col = ButtonColor(tool == 5u, hover == 35u);

            // Scale
            if (Box(p, float2(0.36f, 0.495f), float2(0.59f, 0.560f)) > 0.5f)

                col = ButtonColor(tool == 6u, hover == 36u);

            // Mask
            if (Box(p, float2(0.60f, 0.495f), float2(0.82f, 0.560f)) > 0.5f)

                col = ButtonColor(tool == 7u, hover == 37u);

            // ---------------------------------------------------------------------
            // Brush card
            // ---------------------------------------------------------------------
            if (Box(p, float2(0.35f, 0.61f), float2(0.83f, 0.85f)) > 0.5f)

                col = float4(0.035f, 0.045f, 0.055f, 1.0f);

            // ---------------------------------------------------------------------
            // Radius slider
            // ---------------------------------------------------------------------
            float radiusT = saturate((radius - 0.02f) / 0.23f);

            float radiusX = lerp(0.50f, 0.80f, radiusT);

            float radiusTrack = RoundRect(

                p,

                float2(0.50f, 0.660f),

                float2(0.80f, 0.681f),

                0.009f

            );

            col = lerp(

                col,

                float4(0.020f, 0.030f, 0.040f, 1.0f),

                radiusTrack

            );

            float radiusFill = RoundRect(

                p,

                float2(0.50f, 0.660f),

                float2(radiusX, 0.681f),

                0.009f

            );

            col = lerp(

                col,

                float4(0.0f, 0.12f, 0.16f, 1.0f),

                radiusFill

            );

            float2 radiusKnob = float2(radiusX, 0.6705f);

            float radiusKnobRadius =

                (hover == 50u || activeSlider == 50u) ? 0.012f : 0.009f;

            float radiusMask = Circle(

                p,

                radiusKnob,

                radiusKnobRadius

            );

            if (radiusMask > 0.0f)

            {

                float4 knobColor =

                    (hover == 50u || activeSlider == 50u)

                    ? float4(0.0f, 0.65f, 0.85f, 1.0f)

                    : float4(0.0f, 0.45f, 0.65f, 1.0f);

                col = lerp(col, knobColor, radiusMask);

            }

            // ---------------------------------------------------------------------
            // Strength slider
            // ---------------------------------------------------------------------
            if (tool != 0u)

            {

                float strengthX = lerp(0.50f, 0.80f, strength);

                float strengthTrack = RoundRect(

                    p,

                    float2(0.50f, 0.715f),

                    float2(0.80f, 0.736f),

                    0.009f

                );

                col = lerp(

                    col,

                    float4(0.020f, 0.030f, 0.040f, 1.0f),

                    strengthTrack

                );

                float strengthFill = RoundRect(

                    p,

                    float2(0.50f, 0.715f),

                    float2(strengthX, 0.736f),

                    0.009f

                );

                col = lerp(

                    col,

                    float4(0.0f, 0.12f, 0.16f, 1.0f),

                    strengthFill

                );

                float2 strengthKnob = float2(strengthX, 0.7255f);

                float strengthKnobRadius =

                    (hover == 51u || activeSlider == 51u) ? 0.012f : 0.009f;

                float strengthMask = Circle(

                    p,

                    strengthKnob,

                    strengthKnobRadius

                );

                if (strengthMask > 0.0f)

                {

                    float4 knobColor =

                        (hover == 51u || activeSlider == 51u)

                        ? float4(0.0f, 0.65f, 0.85f, 1.0f)

                        : float4(0.0f, 0.45f, 0.65f, 1.0f);

                    col = lerp(col, knobColor, strengthMask);

                }

            }

            // ---------------------------------------------------------------------
            // Mirror X / Y / Z
            // ---------------------------------------------------------------------
            if (Box(p, float2(0.37f, 0.775f), float2(0.48f, 0.815f)) > 0.5f)

                col = ButtonColor(

                    mirror > 0.5f && mirrorAxis == 0u,

                    hover == 60u

                );

            if (Box(p, float2(0.49f, 0.775f), float2(0.60f, 0.815f)) > 0.5f)

                col = ButtonColor(

                    mirror > 0.5f && mirrorAxis == 1u,

                    hover == 61u

                );

            if (Box(p, float2(0.61f, 0.775f), float2(0.72f, 0.815f)) > 0.5f)

                col = ButtonColor(

                    mirror > 0.5f && mirrorAxis == 2u,

                    hover == 62u

                );

            // Clear
            if (Box(p, float2(0.74f, 0.775f), float2(0.82f, 0.815f)) > 0.5f)

                col = ButtonColor(false, hover == 70u);

        }

        // =========================================================================
        // JIGGLE SYSTEM PAGE
        // =========================================================================
        if (page == 1u)
        {
            if (Box(p, float2(0.35f, 0.205f), float2(0.83f, 0.85f)) > 0.5f)
                col = float4(0.035f, 0.045f, 0.055f, 1.0f);

            // Eight independent groups.
            if (Box(p, float2(0.36f, 0.255f), float2(0.47f, 0.300f)) > 0.5f) col = ButtonColor(jiggleGroup == 0u, hover == 500u);
            if (Box(p, float2(0.48f, 0.255f), float2(0.59f, 0.300f)) > 0.5f) col = ButtonColor(jiggleGroup == 1u, hover == 501u);
            if (Box(p, float2(0.60f, 0.255f), float2(0.71f, 0.300f)) > 0.5f) col = ButtonColor(jiggleGroup == 2u, hover == 502u);
            if (Box(p, float2(0.72f, 0.255f), float2(0.82f, 0.300f)) > 0.5f) col = ButtonColor(jiggleGroup == 3u, hover == 503u);
            if (Box(p, float2(0.36f, 0.315f), float2(0.47f, 0.360f)) > 0.5f) col = ButtonColor(jiggleGroup == 4u, hover == 504u);
            if (Box(p, float2(0.48f, 0.315f), float2(0.59f, 0.360f)) > 0.5f) col = ButtonColor(jiggleGroup == 5u, hover == 505u);
            if (Box(p, float2(0.60f, 0.315f), float2(0.71f, 0.360f)) > 0.5f) col = ButtonColor(jiggleGroup == 6u, hover == 506u);
            if (Box(p, float2(0.72f, 0.315f), float2(0.82f, 0.360f)) > 0.5f) col = ButtonColor(jiggleGroup == 7u, hover == 507u);

            // Enabled toggle and mask-slot selector.
            if (Box(p, float2(0.36f, 0.400f), float2(0.49f, 0.455f)))
                col = ButtonColor(jiggleEnabled > 0.5f, hover == 510u);
            if (Box(p, float2(0.57f, 0.400f), float2(0.61f, 0.455f)))
                col = ButtonColor(false, hover == 511u);
            if (Box(p, float2(0.62f, 0.400f), float2(0.72f, 0.455f)))
                col = float4(0.020f, 0.030f, 0.040f, 1.0f);
            if (Box(p, float2(0.73f, 0.400f), float2(0.77f, 0.455f)))
                col = ButtonColor(false, hover == 512u);

            // Settings tabs.
            if (Box(p, float2(0.36f, 0.458f), float2(0.50f, 0.480f)))
                col = ButtonColor(jiggleTab == 0u, hover == 513u);
            if (Box(p, float2(0.505f, 0.458f), float2(0.655f, 0.480f)))
                col = ButtonColor(jiggleTab == 1u, hover == 514u);
            if (Box(p, float2(0.660f, 0.458f), float2(0.82f, 0.480f)))
                col = ButtonColor(jiggleTab == 2u, hover == 515u);

            if (jiggleTab == 0u)
            {
                col = JiggleSlider(p, col, 0.500f, jiggleStiffness / 200.0f, 520u, hover, activeSlider);
                col = JiggleSlider(p, col, 0.565f, jiggleDamping / 40.0f, 521u, hover, activeSlider);
                col = JiggleSlider(p, col, 0.630f, jiggleStrength / 3.0f, 522u, hover, activeSlider);
                col = JiggleSlider(p, col, 0.695f, jiggleInertia / 2.0f, 523u, hover, activeSlider);
                col = JiggleSlider(p, col, 0.760f, (jiggleMaxOffset - 0.005f) / 0.245f, 524u, hover, activeSlider);
            }
            else if (jiggleTab == 1u)
            {
                col = JiggleSlider(p, col, 0.500f, (jiggleGravity + 1.0f) / 2.0f, 525u, hover, activeSlider);
                col = JiggleSlider(p, col, 0.565f, jiggleMotionSensitivity / 2.0f, 526u, hover, activeSlider);
                col = JiggleSlider(p, col, 0.630f, (jiggleMotionSmoothing - 0.05f) / 0.95f, 527u, hover, activeSlider);
                if (Box(p, float2(0.50f, 0.690f), float2(0.575f, 0.735f)))
                    col = ButtonColor(jiggleAxisX > 0.5f, hover == 530u);
                if (Box(p, float2(0.585f, 0.690f), float2(0.660f, 0.735f)))
                    col = ButtonColor(jiggleAxisY > 0.5f, hover == 531u);
                if (Box(p, float2(0.670f, 0.690f), float2(0.745f, 0.735f)))
                    col = ButtonColor(jiggleAxisZ > 0.5f, hover == 532u);
            }
            else
            {
                col = JiggleSlider(p, col, 0.500f, (jiggleEdgeFalloff - 0.25f) / 2.25f, 528u, hover, activeSlider);
                if (Box(p, float2(0.365f, 0.565f), float2(0.505f, 0.615f))) col = ButtonColor(false, hover == 540u);
                if (Box(p, float2(0.515f, 0.565f), float2(0.655f, 0.615f))) col = ButtonColor(false, hover == 541u);
                if (Box(p, float2(0.665f, 0.565f), float2(0.815f, 0.615f))) col = ButtonColor(false, hover == 542u);
                if (Box(p, float2(0.365f, 0.635f), float2(0.505f, 0.685f))) col = ButtonColor(false, hover == 543u);
                if (Box(p, float2(0.515f, 0.635f), float2(0.655f, 0.685f))) col = ButtonColor(false, hover == 544u);
                if (Box(p, float2(0.665f, 0.635f), float2(0.815f, 0.685f))) col = ButtonColor(false, hover == 545u);
            }
        }

        // =========================================================================
        // DROP-IN MODULE DIRECTORY (page 6)
        // Each module draws its own row and details through its own Module.ini.
        // =========================================================================
        if (page == 6u)
        {
            if (Box(p, float2(0.35f, 0.205f), float2(0.83f, 0.85f)) > 0.5f)
                col = float4(0.035f, 0.045f, 0.055f, 1.0f);
            if (Box(p, float2(0.345f, 0.220f), float2(0.575f, 0.825f)) > 0.5f)
                col = float4(0.018f, 0.022f, 0.030f, 1.0f);
            if (Box(p, float2(0.585f, 0.220f), float2(0.830f, 0.825f)) > 0.5f)
                col = float4(0.018f, 0.022f, 0.030f, 1.0f);
            if (Box(p, float2(0.345f, 0.220f), float2(0.575f, 0.225f)) > 0.5f ||
                Box(p, float2(0.585f, 0.220f), float2(0.830f, 0.225f)) > 0.5f)
                col = float4(0.0f, 0.45f, 0.65f, 1.0f);
            if (selectedModuleOneBased > 0u && Box(p, float2(0.615f, 0.680f), float2(0.800f, 0.735f)) > 0.5f)
                col = ButtonColor(false, hover == 700u);
        }

        // Generic module view: module-owned widget descriptors are rendered by Core.
        // A module may add further artwork/text from its own Module.ini/HLSL.
        if (page == 7u && selectedModuleOneBased > 0u && selectedModuleOneBased <= 32u)
        {
            if (Box(p, float2(0.35f, 0.205f), float2(0.83f, 0.85f)) > 0.5f)
                col = float4(0.035f, 0.045f, 0.055f, 1.0f);
            if (Box(p, float2(0.355f, 0.215f), float2(0.455f, 0.265f)) > 0.5f)
                col = ButtonColor(false, hover == 701u);
            if (Box(p, float2(0.365f, 0.285f), float2(0.815f, 0.290f)) > 0.5f)
                col = float4(0.0f, 0.45f, 0.65f, 1.0f);

            uint moduleSlot = selectedModuleOneBased - 1u;
            [loop]
            for (uint widget = 0u; widget < 8u; ++widget)
            {
                uint base = (moduleSlot * 8u + widget) * 8u;
                uint widgetType = (uint)max(round(NuraUIModuleWidgets[base]), 0.0f);
                if (widgetType == 0u) continue;

                float2 mn = float2(NuraUIModuleWidgets[base + 1u], NuraUIModuleWidgets[base + 2u]);
                float2 mx = float2(NuraUIModuleWidgets[base + 3u], NuraUIModuleWidgets[base + 4u]);
                float value = NuraUIModuleWidgets[base + 5u];
                bool widgetHovered = hover == 800u + widget;

                if (widgetType == 1u)
                {
                    float range = max(NuraUIModuleWidgets[base + 7u] - NuraUIModuleWidgets[base + 6u], 0.0001f);
                    float t = saturate((value - NuraUIModuleWidgets[base + 6u]) / range);
                    float midY = (mn.y + mx.y) * 0.5f;
                    float trackHalfHeight = max((mx.y - mn.y) * 0.17f, 0.003f);
                    float knobX = lerp(mn.x, mx.x, t);
                    float track = RoundRect(p, float2(mn.x, midY - trackHalfHeight), float2(mx.x, midY + trackHalfHeight), 0.004f);
                    col = lerp(col, float4(0.015f, 0.024f, 0.032f, 1.0f), track);
                    float fill = RoundRect(p, float2(mn.x, midY - trackHalfHeight), float2(knobX, midY + trackHalfHeight), 0.004f);
                    bool sliderActive = widgetHovered || activeSlider == 800u + widget;
                    float fillGreen = sliderActive ? 0.64f : 0.42f;
                    col = lerp(col, float4(0.0f, fillGreen, 0.58f, 1.0f), fill);
                    float knob = Circle(p, float2(knobX, midY), sliderActive ? 0.012f : 0.009f);
                    col = lerp(col, float4(0.0f, 0.65f, 0.86f, 1.0f), knob);
                }
                else if (widgetType == 2u)
                {
                    float box = RoundRect(p, mn, mx, 0.006f);
                    float4 buttonFill = value > 0.5f
                        ? (widgetHovered ? float4(0.0f, 0.28f, 0.34f, 1.0f) : float4(0.0f, 0.18f, 0.23f, 1.0f))
                        : (widgetHovered ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.025f, 0.035f, 0.045f, 1.0f));
                    col = lerp(col, buttonFill, box);
                    float border = Box(p, mn, float2(mx.x, mn.y + 0.003f)) + Box(p, float2(mn.x, mx.y - 0.003f), mx);
                    col = lerp(col, float4(0.0f, 0.45f, 0.65f, 1.0f), saturate(border));
                }
                else if (widgetType == 3u)
                {
                    // Action button. Five internal markers make successive presses visible.
                    float box = RoundRect(p, mn, mx, 0.006f);
                    float4 buttonFill = widgetHovered
                        ? float4(0.0f, 0.20f, 0.27f, 1.0f)
                        : float4(0.025f, 0.045f, 0.055f, 1.0f);
                    col = lerp(col, buttonFill, box);
                    float border = Box(p, mn, float2(mx.x, mn.y + 0.0025f))
                                 + Box(p, float2(mn.x, mx.y - 0.0025f), mx);
                    col = lerp(col, float4(0.0f, 0.45f, 0.65f, 1.0f), saturate(border));
                    float actionPhase = fmod(floor(max(value, 0.0f)), 6.0f);
                    float midY = (mn.y + mx.y) * 0.5f;
                    float usableWidth = max(mx.x - mn.x, 0.001f) * 0.56f;
                    [unroll]
                    for (uint marker = 0u; marker < 5u; ++marker)
                    {
                        float markerX = (mn.x + mx.x) * 0.5f + (((float)marker - 2.0f) / 4.0f) * usableWidth;
                        float markerMask = Circle(p, float2(markerX, midY), 0.0042f);
                        float markerActive = step((float)marker + 1.0f, actionPhase);
                        float4 markerColor = markerActive > 0.5f
                            ? float4(0.0f, 0.78f, 0.88f, 1.0f)
                            : float4(0.10f, 0.18f, 0.22f, 1.0f);
                        col = lerp(col, markerColor, markerMask);
                    }
                }
                else if (widgetType == 4u)
                {
                    // Cycle selector. A moving marker shows the current enum value.
                    float box = RoundRect(p, mn, mx, 0.006f);
                    float4 buttonFill = widgetHovered
                        ? float4(0.0f, 0.16f, 0.22f, 1.0f)
                        : float4(0.025f, 0.035f, 0.045f, 1.0f);
                    col = lerp(col, buttonFill, box);
                    float border = Box(p, mn, float2(mx.x, mn.y + 0.0025f))
                                 + Box(p, float2(mn.x, mx.y - 0.0025f), mx);
                    col = lerp(col, float4(0.0f, 0.45f, 0.65f, 1.0f), saturate(border));

                    float minValue = NuraUIModuleWidgets[base + 6u];
                    float maxValue = max(NuraUIModuleWidgets[base + 7u], minValue);
                    float cycleT = (maxValue > minValue)
                        ? saturate((value - minValue) / (maxValue - minValue))
                        : 0.0f;
                    float midY = (mn.y + mx.y) * 0.5f;
                    float trackInset = (mx.x - mn.x) * 0.13f;
                    float trackMinX = mn.x + trackInset;
                    float trackMaxX = mx.x - trackInset;
                    float track = RoundRect(p, float2(trackMinX, midY - 0.003f), float2(trackMaxX, midY + 0.003f), 0.002f);
                    col = lerp(col, float4(0.01f, 0.025f, 0.032f, 1.0f), track);
                    float markerX = lerp(trackMinX, trackMaxX, cycleT);
                    float marker = Circle(p, float2(markerX, midY), 0.0065f);
                    col = lerp(col, float4(0.0f, 0.78f, 0.90f, 1.0f), marker);
                }
            }
        }

        // =========================================================================
        // JIGGLE TOOLTIPS
        // =========================================================================
        // The footer occupies the unused strip below the controls, so descriptions
        // never cover the sliders or preset buttons. Text is rendered by the
        // existing MSDF text path in NuraThingsUI_Integration.ini.
        bool jiggleTooltipHover =
               (hover >= 500u && hover <= 507u)
            || (hover >= 510u && hover <= 515u)
            || (hover >= 520u && hover <= 528u)
            || (hover >= 530u && hover <= 532u)
            || (hover >= 540u && hover <= 545u)
            || (hover >= 560u && hover <= 568u);

        if (page == 1u && jiggleTooltipHover)
        {
            if (Box(p, float2(0.35f, 0.795f), float2(0.83f, 0.845f)) > 0.5f)
                col = float4(0.018f, 0.026f, 0.034f, 1.0f);

            if (Box(p, float2(0.35f, 0.795f), float2(0.83f, 0.800f)) > 0.5f)
                col = float4(0.0f, 0.48f, 0.64f, 1.0f);
        }

        // =========================================================================
        // HOVER
        // =========================================================================
        if (hover == 10u && Box(p, float2(0.17f, 0.23f), float2(0.32f, 0.31f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 11u && Box(p, float2(0.17f, 0.32f), float2(0.32f, 0.40f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 12u && Box(p, float2(0.17f, 0.41f), float2(0.32f, 0.49f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 13u && Box(p, float2(0.17f, 0.50f), float2(0.32f, 0.58f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 14u && Box(p, float2(0.17f, 0.59f), float2(0.32f, 0.67f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 15u && Box(p, float2(0.17f, 0.68f), float2(0.32f, 0.76f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 16u && Box(p, float2(0.17f, 0.77f), float2(0.32f, 0.85f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 30u && Box(p, float2(0.36f, 0.27f), float2(0.59f, 0.335f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 31u && Box(p, float2(0.60f, 0.27f), float2(0.82f, 0.335f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 32u && Box(p, float2(0.36f, 0.345f), float2(0.59f, 0.410f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 33u && Box(p, float2(0.60f, 0.345f), float2(0.82f, 0.410f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 34u && Box(p, float2(0.36f, 0.420f), float2(0.59f, 0.485f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 35u && Box(p, float2(0.60f, 0.420f), float2(0.82f, 0.485f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 36u && Box(p, float2(0.36f, 0.495f), float2(0.59f, 0.560f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 37u && Box(p, float2(0.60f, 0.495f), float2(0.82f, 0.560f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 60u && Box(p, float2(0.37f, 0.775f), float2(0.48f, 0.815f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 61u && Box(p, float2(0.49f, 0.775f), float2(0.60f, 0.815f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 62u && Box(p, float2(0.61f, 0.775f), float2(0.72f, 0.815f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

        else if (hover == 70u && Box(p, float2(0.74f, 0.775f), float2(0.82f, 0.815f)) > 0.5f)

            col = float4(0.0f, 0.16f, 0.21f, 1.0f);

    }

    if (page == 0u && hover >= 30u && hover <= 37u)
    {
        float toolTipMask = RoundRect(p, float2(0.35f, 0.565f), float2(0.83f, 0.605f), 0.006f);
        col = lerp(col, float4(0.012f, 0.020f, 0.028f, 0.98f), toolTipMask);
        float toolTipEdge = Box(p, float2(0.35f, 0.565f), float2(0.83f, 0.568f));
        col = lerp(col, float4(0.0f, 0.40f, 0.58f, 1.0f), toolTipEdge);
    }

    return col;

}

#endif