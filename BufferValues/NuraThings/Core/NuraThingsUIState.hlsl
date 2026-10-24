RWBuffer<float> UIState : register(u0);

Texture1D<float4> IniParams : register(t120);

#define UI_CURSOR IniParams[31]

#define UI_INPUT IniParams[32]

#define UI_CONFIG IniParams[33]

#define UI_OVERLAY IniParams[36].x

#define STRENGTH_SCULPT IniParams[34].x

#define STRENGTH_SMOOTH IniParams[34].y

#define STRENGTH_PINCH IniParams[34].z

#define STRENGTH_CREASE IniParams[34].w

#define STRENGTH_FLATTEN IniParams[35].x

#define STRENGTH_SCALE IniParams[35].y

#define STRENGTH_MASK IniParams[35].z

#define TOOL_GRAB 0u

#define TOOL_INFLATE 1u

#define TOOL_SMOOTH 2u

#define TOOL_PINCH 3u

#define TOOL_CREASE 4u

#define TOOL_FLATTEN 5u

#define TOOL_SCALE 6u

#define TOOL_MASK 7u

#define UI_FALLOFF UIState[16]
#define UI_FALLOFF_OPEN UIState[17]

bool InRect(float2 p, float2 mn, float2 mx)

{

    return p.x >= mn.x && p.x <= mx.x &&

           p.y >= mn.y && p.y <= mx.y;

}

float GetStrengthDefault(uint tool)

{

    if (tool <= 1u)

        return STRENGTH_SCULPT;

    else if (tool == 2u)

        return STRENGTH_SMOOTH;

    else if (tool == 3u)

        return STRENGTH_PINCH;

    else if (tool == 4u)

        return STRENGTH_CREASE;

    else if (tool == 5u)

        return STRENGTH_FLATTEN;

    else if (tool == 6u)

        return STRENGTH_SCALE;

    else

        return STRENGTH_MASK;

}

float GetStrengthMin(uint tool)

{

    if (tool <= 1u)

        return 0.0001f;

    else if (tool == 2u)

        return 0.010f;

    else if (tool == 3u)

        return 0.0001f;

    else if (tool == 4u)

        return 0.00001f;

    else if (tool == 5u)

        return 0.000005f;

    else if (tool == 6u)

        return 0.001f;

    else

        return 0.0f;

}

float GetStrengthMax(uint tool)

{

    if (tool <= 1u)

        return 0.010f;

    else if (tool == 2u)

        return 0.70f;

    else if (tool == 3u)

        return 0.005f;

    else if (tool == 4u)

        return 0.0005f;

    else if (tool == 5u)

        return 0.0002f;

    else if (tool == 6u)

        return 0.02f;

    else

        return 1.0f;

}

float GetStrengthUI(uint tool)

{

    float minValue = GetStrengthMin(tool);

    float maxValue = GetStrengthMax(tool);

    float value = GetStrengthDefault(tool);

    return saturate((value - minValue) / (maxValue - minValue));

}

float GetStrengthValue(uint tool, float uiValue)

{

    return lerp(

        GetStrengthMin(tool),

        GetStrengthMax(tool),

        saturate(uiValue)

    );

}

[numthreads(1, 1, 1)]

void main(uint3 id : SV_DispatchThreadID)

{

    float2 screen = max(UI_CURSOR.zw, float2(1.0f, 1.0f));

    float2 p = UI_CURSOR.xy / screen;

    bool mainUI = UI_CONFIG.x > 0.5f;

    bool overlay = UI_OVERLAY > 0.5f;

    bool open = mainUI || overlay;

    bool lmb = UI_INPUT.x > 0.5f;

    bool prevLmb = UIState[2] > 0.5f;

    bool click = lmb && !prevLmb;

    float currentRadius = UI_CONFIG.w;


    // -------------------------------------------------------------------------

    // Debug

    // -------------------------------------------------------------------------

    UIState[11] = click ? 1.0f : 0.0f;

    UIState[12] = lmb ? 1.0f : 0.0f;

    UIState[13] = !prevLmb ? 1.0f : 0.0f;

    UIState[14] = open ? 1.0f : 0.0f;

    // -------------------------------------------------------------------------

    // Initialize

    // -------------------------------------------------------------------------

    if (UIState[10] < 0.5f)

    {

        UIState[0] = 0.0f;

        UIState[1] = TOOL_GRAB;

        UIState[2] = 0.0f;

        UIState[3] = 0.0f;

        UIState[4] = 0.0f;

        UIState[5] = UI_CONFIG.y;

        UIState[6] = UI_CONFIG.z;

        UIState[7] = 0.0f;

        UIState[8] = currentRadius;

        UIState[9] = GetStrengthUI(TOOL_GRAB);

        UIState[15] = GetStrengthDefault(TOOL_GRAB);

        UIState[10] = 1.0f;

        UIState[16] = UI_FALLOFF;
        UIState[17] = 0.0f;

    }

    uint page = (uint)max(UIState[0] + 0.5f, 0.0f);

    uint tool = (uint)max(UIState[1] + 0.5f, 0.0f);

    uint activeSlider = (uint)max(UIState[7] + 0.5f, 0.0f);

    uint mirrorAxis = (uint)max(UIState[6] + 0.5f, 0.0f);

    float mirror = UIState[5];

    float radius = UIState[8];

    float strength = saturate(UIState[9]);

    float actualStrength = UIState[15];

    uint falloffMode = (uint)clamp(UIState[16] + 0.5f, 0.0f, 4.0f);
    bool falloffOpen = UI_FALLOFF_OPEN > 0.5f;
    uint hover = 0u;

    uint clicked = 0u;

    // -------------------------------------------------------------------------

    // Synchronize values which are not currently being edited

    // -------------------------------------------------------------------------

    if (activeSlider != 50u)

        radius = currentRadius;

    // -------------------------------------------------------------------------

    // UI

    // -------------------------------------------------------------------------

    if (mainUI)

    {

        // ---------------------------------------------------------------------

        // Sidebar gets priority over everything else.

        // ---------------------------------------------------------------------

        if (InRect(p, float2(0.17f, 0.23f), float2(0.32f, 0.31f)))

            hover = 10u;

        else if (InRect(p, float2(0.17f, 0.32f), float2(0.32f, 0.40f)))

            hover = 11u;

        else if (InRect(p, float2(0.17f, 0.41f), float2(0.32f, 0.49f)))

            hover = 12u;

        else if (InRect(p, float2(0.17f, 0.50f), float2(0.32f, 0.58f)))

            hover = 13u;

        else if (InRect(p, float2(0.17f, 0.59f), float2(0.32f, 0.67f)))

            hover = 14u;

        else if (InRect(p, float2(0.17f, 0.68f), float2(0.32f, 0.76f)))

            hover = 15u;

        // ---------------------------------------------------------------------

        // Mesh content

        // ---------------------------------------------------------------------

        else if (page == 0u)

        {

            // -----------------------------------------------------------------

            // Tools: 2 columns x 4 rows

            // -----------------------------------------------------------------

            if (InRect(p, float2(0.36f, 0.27f), float2(0.59f, 0.335f)))

                hover = 30u;

            else if (InRect(p, float2(0.60f, 0.27f), float2(0.82f, 0.335f)))

                hover = 31u;

            else if (InRect(p, float2(0.36f, 0.345f), float2(0.59f, 0.410f)))

                hover = 32u;

            else if (InRect(p, float2(0.60f, 0.345f), float2(0.82f, 0.410f)))

                hover = 33u;

            else if (InRect(p, float2(0.36f, 0.420f), float2(0.59f, 0.485f)))

                hover = 34u;

            else if (InRect(p, float2(0.60f, 0.420f), float2(0.82f, 0.485f)))

                hover = 35u;

            else if (InRect(p, float2(0.36f, 0.495f), float2(0.59f, 0.560f)))

                hover = 36u;

            else if (InRect(p, float2(0.60f, 0.495f), float2(0.82f, 0.560f)))

                hover = 37u;

            // -----------------------------------------------------------------

            // Radius

            // -----------------------------------------------------------------

            else if (InRect(p, float2(0.50f, 0.660f), float2(0.80f, 0.681f)))

                hover = 50u;

            // -----------------------------------------------------------------

            // Strength

            // -----------------------------------------------------------------

            else if (tool != TOOL_GRAB &&

                     InRect(p, float2(0.50f, 0.715f), float2(0.80f, 0.736f)))

                hover = 51u;

            // -----------------------------------------------------------------

            // Mirror X / Y / Z / Clear

            // -----------------------------------------------------------------

            else if (InRect(p, float2(0.37f, 0.775f), float2(0.48f, 0.815f)))

                hover = 60u;

            else if (InRect(p, float2(0.49f, 0.775f), float2(0.60f, 0.815f)))

                hover = 61u;

            else if (InRect(p, float2(0.61f, 0.775f), float2(0.72f, 0.815f)))

                hover = 62u;

            else if (InRect(p, float2(0.74f, 0.775f), float2(0.82f, 0.815f)))

                hover = 70u;

            // -----------------------------------------------------------------

            // Click

            // -----------------------------------------------------------------

            if (click)

            {

                clicked = hover;

                // Sidebar page

                if (hover >= 10u && hover <= 15u)

                {

                    page = hover - 10u;

                    activeSlider = 0u;

                }

                // Tools

                else if (hover >= 30u && hover <= 37u)

                {

                    tool = hover - 30u;

                    activeSlider = 0u;

                    strength = GetStrengthUI(tool);

                    actualStrength = GetStrengthDefault(tool);

                }

                // Radius

                else if (hover == 50u)

                {

                    activeSlider = 50u;

                }

                // Strength

                else if (hover == 51u)

                {

                    activeSlider = 51u;

                }

                // Mirror

                else if (hover >= 60u && hover <= 62u)

                {

                    uint newAxis = hover - 60u;

                    if (mirror > 0.5f && mirrorAxis == newAxis)

                        mirror = 0.0f;

                    else

                    {

                        mirror = 1.0f;

                        mirrorAxis = newAxis;

                    }

                    activeSlider = 0u;

                }

                // Clear

                else if (hover == 70u)

                {

                    activeSlider = 0u;

                }

            }

            // -----------------------------------------------------------------

            // Slider dragging

            // -----------------------------------------------------------------

            if (lmb && activeSlider == 50u)

            {

                float t = saturate((p.x - 0.50f) / 0.30f);

                radius = lerp(0.010f, 1.0f, t);

            }

            else if (lmb && activeSlider == 51u)

            {

                float t = saturate((p.x - 0.50f) / 0.30f);

                strength = t;

                actualStrength = GetStrengthValue(tool, t);

            }

            if (!lmb)

                activeSlider = 0u;

        }

        else

        {

            activeSlider = 0u;

        }

    }

    else if (overlay)

    {

        // -------------------------------------------------------------------------

        // Blender-like Toolbar

        // -------------------------------------------------------------------------

        if (falloffOpen && InRect(p, float2(0.575f, 0.074f), float2(0.695f, 0.108f)))
            hover = 231u;
        else if (falloffOpen && InRect(p, float2(0.575f, 0.110f), float2(0.695f, 0.144f)))
            hover = 232u;
        else if (falloffOpen && InRect(p, float2(0.575f, 0.146f), float2(0.695f, 0.180f)))
            hover = 233u;
        else if (falloffOpen && InRect(p, float2(0.575f, 0.182f), float2(0.695f, 0.216f)))
            hover = 234u;
        else if (falloffOpen && InRect(p, float2(0.575f, 0.218f), float2(0.695f, 0.252f)))
            hover = 235u;

        if (InRect(p, float2(0.012f, 0.140f), float2(0.100f, 0.205f)))

            hover = 100u;

        else if (InRect(p, float2(0.012f, 0.213f), float2(0.100f, 0.278f)))

            hover = 101u;

        else if (InRect(p, float2(0.012f, 0.286f), float2(0.100f, 0.351f)))

            hover = 102u;

        else if (InRect(p, float2(0.012f, 0.359f), float2(0.100f, 0.424f)))

            hover = 103u;

        else if (InRect(p, float2(0.012f, 0.432f), float2(0.100f, 0.497f)))

            hover = 104u;

        else if (InRect(p, float2(0.012f, 0.505f), float2(0.100f, 0.570f)))

            hover = 105u;

        else if (InRect(p, float2(0.012f, 0.578f), float2(0.100f, 0.643f)))

            hover = 106u;

        else if (InRect(p, float2(0.012f, 0.651f), float2(0.100f, 0.716f)))

            hover = 107u;

        // -------------------------------------------------------------------------

        // Header sliders

        // -------------------------------------------------------------------------

        // Radius: 0.16 -> 0.245

        else if (InRect(p, float2(0.16f, 0.039f), float2(0.245f, 0.069f)))

            hover = 200u;

        // Strength: 0.47 -> 0.545

        else if (InRect(p, float2(0.47f, 0.039f), float2(0.545f, 0.069f)))

            hover = 201u;
        else if (InRect(p, float2(0.58f, 0.039f), float2(0.69f, 0.069f)))
            hover = 230u;

        // -------------------------------------------------------------------------

        // Mirror X / Y / Z

        // -------------------------------------------------------------------------

        else if (InRect(p, float2(0.80f, 0.039f), float2(0.845f, 0.069f)))

            hover = 210u;

        else if (InRect(p, float2(0.848f, 0.039f), float2(0.893f, 0.069f)))

            hover = 211u;

        else if (InRect(p, float2(0.896f, 0.039f), float2(0.941f, 0.069f)))

            hover = 212u;

        // -------------------------------------------------------------------------

        // Clear

        // -------------------------------------------------------------------------

        else if (InRect(p, float2(0.944f, 0.039f), float2(0.986f, 0.069f)))

            hover = 220u;

        // -------------------------------------------------------------------------

        // Click

        // -------------------------------------------------------------------------

        if (click)
        {
            clicked = hover;
            if (falloffOpen)
            {
                if (hover >= 231u && hover <= 235u)
                {
                    falloffMode = hover - 231u;
                    falloffOpen = false;
                }
                else
                {
                    falloffOpen = false;
                }
                activeSlider = 0u;
            }
            else if (hover >= 100u && hover <= 107u)
            {
                tool = hover - 100u;
                activeSlider = 0u;
                strength = GetStrengthUI(tool);
                actualStrength = GetStrengthDefault(tool);
            }
            else if (hover == 200u)
            {
                activeSlider = 50u;
            }
            else if (hover == 201u)
            {
                activeSlider = 51u;
            }
            else if (hover >= 210u && hover <= 212u)
            {
                uint newAxis = hover - 210u;
                if (mirror > 0.5f && mirrorAxis == newAxis)
                    mirror = 0.0f;
                else
                {
                    mirror = 1.0f;
                    mirrorAxis = newAxis;
                }
                activeSlider = 0u;
            }
            else if (hover == 220u)
            {
                activeSlider = 0u;
            }
            else if (hover == 230u)
            {
                falloffOpen = true;
                activeSlider = 0u;
            }
        }

        // -------------------------------------------------------------------------

        // Slider dragging

        // -------------------------------------------------------------------------

        if (lmb && activeSlider == 50u)

        {

            float t = saturate((p.x - 0.16f) / 0.085f);

            radius = lerp(0.010f, 1.0f, t);

        }

        else if (lmb && activeSlider == 51u)

        {

            float t = saturate((p.x - 0.47f) / 0.075f);

            strength = t;

            actualStrength = GetStrengthValue(tool, t);

        }

        if (!lmb)

            activeSlider = 0u;

    }

    else

    {

        activeSlider = 0u;

    }

    // -------------------------------------------------------------------------

    // Store State

    // -------------------------------------------------------------------------

    UIState[0] = (float)page;

    UIState[1] = (float)tool;

    UIState[2] = lmb ? 1.0f : 0.0f;

    UIState[3] = (float)hover;

    UIState[4] = (float)clicked;

    UIState[5] = mirror;

    UIState[6] = (float)mirrorAxis;

    UIState[7] = (float)activeSlider;

    UIState[8] = radius;

    UIState[9] = saturate(strength);

    UIState[15] = actualStrength;

    UIState[16] = (float)falloffMode;
    UIState[17] = falloffOpen ? 1.0f : 0.0f;

}