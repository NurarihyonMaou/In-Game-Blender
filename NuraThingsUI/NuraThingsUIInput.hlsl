// Current UI input/hit-test shader. NuraThingsUIState.hlsl is the legacy
// prototype; NuraThingsUI.ini invokes this shader, not the legacy file.
RWBuffer<float> UIState : register(u0);
RWBuffer<uint> MaskNames : register(u1);
RWBuffer<float> NuraUIModuleWidgets : register(u2);
Buffer<uint> NuraUIModuleRegistry : register(t0);

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
#define MASK_UI IniParams[38]

#define WEIGHT_UI IniParams[116]
#define CURRENT_MESH_TOOL IniParams[117].x
#define WEIGHT_VG_LIST_SCROLL IniParams[118].x
#define KEYBIND_ACTION_SCROLL IniParams[119].x
#define NURAUI_MODULE_SCROLL IniParams[118].y
#define KEYBIND_ACTION_LIST_FORCE_OPEN IniParams[119].y

#define WRITE_NAME(BASE, OFFSET) \
    MaskNames[(OFFSET) + 0]  = (uint)max(IniParams[(BASE) + 0].x, 0.0f); \
    MaskNames[(OFFSET) + 1]  = (uint)max(IniParams[(BASE) + 0].y, 0.0f); \
    MaskNames[(OFFSET) + 2]  = (uint)max(IniParams[(BASE) + 0].z, 0.0f); \
    MaskNames[(OFFSET) + 3]  = (uint)max(IniParams[(BASE) + 0].w, 0.0f); \
    MaskNames[(OFFSET) + 4]  = (uint)max(IniParams[(BASE) + 1].x, 0.0f); \
    MaskNames[(OFFSET) + 5]  = (uint)max(IniParams[(BASE) + 1].y, 0.0f); \
    MaskNames[(OFFSET) + 6]  = (uint)max(IniParams[(BASE) + 1].z, 0.0f); \
    MaskNames[(OFFSET) + 7]  = (uint)max(IniParams[(BASE) + 1].w, 0.0f); \
    MaskNames[(OFFSET) + 8]  = (uint)max(IniParams[(BASE) + 2].x, 0.0f); \
    MaskNames[(OFFSET) + 9]  = (uint)max(IniParams[(BASE) + 2].y, 0.0f); \
    MaskNames[(OFFSET) + 10] = (uint)max(IniParams[(BASE) + 2].z, 0.0f); \
    MaskNames[(OFFSET) + 11] = (uint)max(IniParams[(BASE) + 2].w, 0.0f); \
    MaskNames[(OFFSET) + 12] = (uint)max(IniParams[(BASE) + 3].x, 0.0f); \
    MaskNames[(OFFSET) + 13] = (uint)max(IniParams[(BASE) + 3].y, 0.0f); \
    MaskNames[(OFFSET) + 14] = (uint)max(IniParams[(BASE) + 3].z, 0.0f); \
    MaskNames[(OFFSET) + 15] = (uint)max(IniParams[(BASE) + 3].w, 0.0f)

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

    float favoriteWheelEnabled = IniParams[120].x > 0.5f ? 1.0f : 0.0f;

    bool lmb = UI_INPUT.x > 0.5f;

    bool prevLmb = UIState[2] > 0.5f;

    bool click = lmb && !prevLmb;

    float currentRadius = UI_CONFIG.w;
    uint maskSlot = (uint)clamp(MASK_UI.x + 0.5f, 0.0f, 7.0f);
    bool renameOpen = MASK_UI.y > 0.5f;
    uint renameSlot = (uint)clamp(MASK_UI.z + 0.5f, 0.0f, 7.0f);

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
        UIState[18] = (float)maskSlot;
        UIState[19] = renameOpen ? 1.0f : 0.0f;
        UIState[20] = (float)renameSlot;
        UIState[21] = (float)clamp(MASK_UI.w + 0.5f, 0.0f, 7.0f);
        UIState[29] = 0.0f;

        UIState[37] = clamp(WEIGHT_UI.x, 0.0f, 117.0f);
        UIState[38] = clamp(WEIGHT_UI.y, 0.0f, 4.0f);
        UIState[39] = saturate(WEIGHT_UI.z);
        UIState[40] = clamp(WEIGHT_UI.w, 0.05f, 1.0f);
        UIState[41] = 0.0f;
        UIState[42] = 0.0f;
        UIState[43] = 0.0f;
        UIState[44] = floor(clamp(WEIGHT_VG_LIST_SCROLL, 0.0f, 110.0f) + 0.5f);
        UIState[45] = 0.0f;
        UIState[46] = 0.0f; // Independent named-mask panel visibility.
        UIState[47] = 0.0f; // KeyBind Manager panel visibility.
        UIState[48] = 0.0f; // Selected keybind slot.
        UIState[49] = 0.0f; // Selected macro slot.
        UIState[50] = 1.0f; // Action selector.
        UIState[51] = 0.0f; // Action argument.
        UIState[52] = 0.0f; // KeyBind action dropdown visibility.
        UIState[53] = floor(clamp(KEYBIND_ACTION_SCROLL, 0.0f, 13.0f) + 0.5f);
        UIState[54] = 0.0f; // Mouse over the action dropdown list.
        UIState[55] = 0.0f; // Selected module slot + 1; zero means no module selected.
        UIState[56] = 0.0f; // Favorite wheel selected module slot + 1.
        UIState[57] = favoriteWheelEnabled; // Persistent Favorite Wheel enable state, mirrored for UI rendering.

    }

    // Type-5 controls are one-frame pulses. Clear the currently selected module's
    // pulse slots every frame, including while the menu is closed, before handling a new click.
    uint pulseModuleOneBased = (uint)max(UIState[55] + 0.5f, 0.0f);
    if (pulseModuleOneBased > 0u && pulseModuleOneBased <= 32u)
    {
        uint pulseModuleSlot = pulseModuleOneBased - 1u;
        [unroll]
        for (uint pulseWidget = 0u; pulseWidget < 8u; ++pulseWidget)
        {
            uint pulseBase = (pulseModuleSlot * 8u + pulseWidget) * 8u;
            uint pulseType = (uint)max(round(NuraUIModuleWidgets[pulseBase]), 0.0f);
            if (pulseType == 5u)
                NuraUIModuleWidgets[pulseBase + 5u] = 0.0f;
        }
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

    float weightVG = clamp(WEIGHT_UI.x, 0.0f, 117.0f);
    uint weightMode = (uint)clamp(WEIGHT_UI.y + 0.5f, 0.0f, 4.0f);
    float weightTarget = saturate(WEIGHT_UI.z);
    float weightStrength = clamp(WEIGHT_UI.w, 0.05f, 1.0f);
    bool weightModeOpen = UIState[41] > 0.5f;
    bool mirrorOpen = UIState[42] > 0.5f;
    bool weightVGListOpen = UIState[43] > 0.5f;
    bool maskPanelOpen = UIState[46] > 0.5f;
    bool keybindPanelOpen = UIState[47] > 0.5f;
    uint keybindSelectedSlot = (uint)clamp(UIState[48] + 0.5f, 0.0f, 7.0f);
    uint keybindSelectedMacro = (uint)clamp(UIState[49] + 0.5f, 0.0f, 3.0f);
    uint keybindAction = (uint)clamp(UIState[50] + 0.5f, 1.0f, 21.0f);
    uint keybindArg = (uint)clamp(UIState[51] + 0.5f, 0.0f, 4.0f);
    bool keybindActionListOpen = UIState[52] > 0.5f || KEYBIND_ACTION_LIST_FORCE_OPEN > 0.5f;
    float keybindActionListScroll = floor(clamp(KEYBIND_ACTION_SCROLL, 0.0f, 13.0f) + 0.5f);
    float weightVGListScroll = floor(clamp(WEIGHT_VG_LIST_SCROLL, 0.0f, 110.0f) + 0.5f);
    uint currentMeshTool = (uint)clamp(CURRENT_MESH_TOOL + 0.5f, 0.0f, 15.0f);
    uint previousTool = tool;

    // In Overlay mode the real Mesh Editor tool is authoritative. This keeps the UI
    // synchronized when V cycles into/out of Weight Paint instead of writing stale UIState[1].
    if (overlay && !mainUI)
    {
        tool = currentMeshTool;
        if (tool != previousTool)
        {
            activeSlider = 0u;
            falloffOpen = false;
            weightModeOpen = false;
            mirrorOpen = false;
            if (tool == 15u)
            {
                strength = saturate((weightStrength - 0.05f) / 0.95f);
                actualStrength = weightStrength;
            }
            else
            {
                strength = GetStrengthUI(tool);
                actualStrength = GetStrengthDefault(tool);
            }
        }
        if (tool == 15u)
        {
            weightVG = clamp(WEIGHT_UI.x, 0.0f, 117.0f);
            weightMode = (uint)clamp(WEIGHT_UI.y + 0.5f, 0.0f, 4.0f);
            weightTarget = saturate(WEIGHT_UI.z);
            weightStrength = clamp(WEIGHT_UI.w, 0.05f, 1.0f);
            if (activeSlider != 51u)
            {
                strength = saturate((weightStrength - 0.05f) / 0.95f);
                actualStrength = weightStrength;
            }
        }
        else
        {
            weightModeOpen = false;
            mirrorOpen = false;
        }
    }
    if (tool != 15u)
    {
        weightVGListOpen = false;
        maskPanelOpen = false;
    }
    if (keybindPanelOpen) maskPanelOpen = false;

    // -------------------------------------------------------------------------
    // Jiggle System state. Each group occupies two IniParams rows beginning at 39:
    // row A = enabled, mask slot, stiffness, damping
    // row B = strength, inertia, maximum offset, reserved
    // -------------------------------------------------------------------------
    uint jiggleGroup = (uint)clamp(UIState[21] + 0.5f, 0.0f, 7.0f);
    float4 jiggleCfg = IniParams[39 + jiggleGroup * 2u];
    float4 jiggleExtra = IniParams[40 + jiggleGroup * 2u];

    float jiggleEnabled = UIState[22];
    uint jiggleMaskSlot = (uint)clamp(UIState[23] + 0.5f, 0.0f, 7.0f);
    float jiggleStiffness = UIState[24];
    float jiggleDamping = UIState[25];
    float jiggleStrength = UIState[26];
    float jiggleInertia = UIState[27];
    float jiggleMaxOffset = UIState[28];
    uint jiggleTab = (uint)clamp(UIState[29] + 0.5f, 0.0f, 2.0f);

    float4 jiggleAxisGravity = IniParams[56 + jiggleGroup];
    float4 jiggleAdvanced = IniParams[64 + jiggleGroup];
    float jiggleAxisX = UIState[30];
    float jiggleAxisY = UIState[31];
    float jiggleAxisZ = UIState[32];
    float jiggleGravity = UIState[33];
    float jiggleMotionSensitivity = UIState[34];
    float jiggleMotionSmoothing = UIState[35];
    float jiggleEdgeFalloff = UIState[36];

    bool jiggleSliderActive = activeSlider >= 520u && activeSlider <= 528u;
    if (!jiggleSliderActive)
    {
        jiggleEnabled = jiggleCfg.x;
        jiggleMaskSlot = (uint)clamp(jiggleCfg.y + 0.5f, 0.0f, 7.0f);
        jiggleStiffness = jiggleCfg.z;
        jiggleDamping = jiggleCfg.w;
        jiggleStrength = jiggleExtra.x;
        jiggleInertia = jiggleExtra.y;
        jiggleMaxOffset = jiggleExtra.z;
        jiggleAxisX = jiggleAxisGravity.x;
        jiggleAxisY = jiggleAxisGravity.y;
        jiggleAxisZ = jiggleAxisGravity.z;
        jiggleGravity = jiggleAxisGravity.w;
        jiggleMotionSensitivity = jiggleAdvanced.x;
        jiggleMotionSmoothing = jiggleAdvanced.y;
        jiggleEdgeFalloff = jiggleAdvanced.z;
    }

    uint hover = 0u;

    uint clicked = 0u;

    // The clicked favorite's module ID is passed through UIState[58].
    // This avoids a second INI-side lookup from the R32_UINT module registry.
    float favoriteClickedModuleId = 0.0f;

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

                if (hover >= 10u && hover <= 16u)

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

        else if (page == 1u)
        {
            // Group selectors: 4 columns x 2 rows.
            if (InRect(p, float2(0.36f, 0.255f), float2(0.47f, 0.300f))) hover = 500u;
            else if (InRect(p, float2(0.48f, 0.255f), float2(0.59f, 0.300f))) hover = 501u;
            else if (InRect(p, float2(0.60f, 0.255f), float2(0.71f, 0.300f))) hover = 502u;
            else if (InRect(p, float2(0.72f, 0.255f), float2(0.82f, 0.300f))) hover = 503u;
            else if (InRect(p, float2(0.36f, 0.315f), float2(0.47f, 0.360f))) hover = 504u;
            else if (InRect(p, float2(0.48f, 0.315f), float2(0.59f, 0.360f))) hover = 505u;
            else if (InRect(p, float2(0.60f, 0.315f), float2(0.71f, 0.360f))) hover = 506u;
            else if (InRect(p, float2(0.72f, 0.315f), float2(0.82f, 0.360f))) hover = 507u;

            // Enabled toggle and mask-slot selector.
            else if (InRect(p, float2(0.36f, 0.400f), float2(0.49f, 0.455f))) hover = 510u;
            else if (InRect(p, float2(0.57f, 0.400f), float2(0.61f, 0.455f))) hover = 511u;
            else if (InRect(p, float2(0.73f, 0.400f), float2(0.77f, 0.455f))) hover = 512u;

            // Jiggle subpages. Tabs sit between the mask row and the first slider.
            else if (InRect(p, float2(0.36f, 0.458f), float2(0.50f, 0.480f))) hover = 513u;
            else if (InRect(p, float2(0.505f, 0.458f), float2(0.655f, 0.480f))) hover = 514u;
            else if (InRect(p, float2(0.660f, 0.458f), float2(0.82f, 0.480f))) hover = 515u;

            if (jiggleTab == 0u)
            {
                // Basic spring settings. Separate label IDs are hover-only so
                // clicking a label cannot accidentally start dragging its slider.
                if (InRect(p, float2(0.50f, 0.480f), float2(0.74f, 0.520f))) hover = 520u;
                else if (InRect(p, float2(0.50f, 0.545f), float2(0.74f, 0.585f))) hover = 521u;
                else if (InRect(p, float2(0.50f, 0.610f), float2(0.74f, 0.650f))) hover = 522u;
                else if (InRect(p, float2(0.50f, 0.675f), float2(0.74f, 0.715f))) hover = 523u;
                else if (InRect(p, float2(0.50f, 0.740f), float2(0.74f, 0.780f))) hover = 524u;
                else if (InRect(p, float2(0.35f, 0.480f), float2(0.495f, 0.520f))) hover = 560u;
                else if (InRect(p, float2(0.35f, 0.545f), float2(0.495f, 0.585f))) hover = 561u;
                else if (InRect(p, float2(0.35f, 0.610f), float2(0.495f, 0.650f))) hover = 562u;
                else if (InRect(p, float2(0.35f, 0.675f), float2(0.495f, 0.715f))) hover = 563u;
                else if (InRect(p, float2(0.35f, 0.740f), float2(0.495f, 0.780f))) hover = 564u;
            }
            else if (jiggleTab == 1u)
            {
                // Motion response controls.
                if (InRect(p, float2(0.50f, 0.480f), float2(0.74f, 0.520f))) hover = 525u;
                else if (InRect(p, float2(0.50f, 0.545f), float2(0.74f, 0.585f))) hover = 526u;
                else if (InRect(p, float2(0.50f, 0.610f), float2(0.74f, 0.650f))) hover = 527u;
                else if (InRect(p, float2(0.50f, 0.690f), float2(0.575f, 0.735f))) hover = 530u;
                else if (InRect(p, float2(0.585f, 0.690f), float2(0.660f, 0.735f))) hover = 531u;
                else if (InRect(p, float2(0.670f, 0.690f), float2(0.745f, 0.735f))) hover = 532u;
                else if (InRect(p, float2(0.35f, 0.480f), float2(0.495f, 0.520f))) hover = 565u;
                else if (InRect(p, float2(0.35f, 0.545f), float2(0.495f, 0.585f))) hover = 566u;
                else if (InRect(p, float2(0.35f, 0.610f), float2(0.495f, 0.650f))) hover = 567u;
            }
            else
            {
                // Mask falloff and presets.
                if (InRect(p, float2(0.50f, 0.480f), float2(0.74f, 0.520f))) hover = 528u;
                else if (InRect(p, float2(0.365f, 0.565f), float2(0.505f, 0.615f))) hover = 540u;
                else if (InRect(p, float2(0.515f, 0.565f), float2(0.655f, 0.615f))) hover = 541u;
                else if (InRect(p, float2(0.665f, 0.565f), float2(0.815f, 0.615f))) hover = 542u;
                else if (InRect(p, float2(0.365f, 0.635f), float2(0.505f, 0.685f))) hover = 543u;
                else if (InRect(p, float2(0.515f, 0.635f), float2(0.655f, 0.685f))) hover = 544u;
                else if (InRect(p, float2(0.665f, 0.635f), float2(0.815f, 0.685f))) hover = 545u;
                else if (InRect(p, float2(0.35f, 0.480f), float2(0.495f, 0.520f))) hover = 568u;
            }

            if (click)
            {
                clicked = hover;

                if (hover >= 500u && hover <= 507u)
                {
                    jiggleGroup = hover - 500u;
                    jiggleCfg = IniParams[39 + jiggleGroup * 2u];
                    jiggleExtra = IniParams[40 + jiggleGroup * 2u];

                    jiggleEnabled = jiggleCfg.x;
                    jiggleMaskSlot = (uint)clamp(jiggleCfg.y + 0.5f, 0.0f, 7.0f);
                    jiggleStiffness = jiggleCfg.z;
                    jiggleDamping = jiggleCfg.w;
                    jiggleStrength = jiggleExtra.x;
                    jiggleInertia = jiggleExtra.y;
                    jiggleMaxOffset = jiggleExtra.z;
                    jiggleAxisGravity = IniParams[56 + jiggleGroup];
                    jiggleAdvanced = IniParams[64 + jiggleGroup];
                    jiggleAxisX = jiggleAxisGravity.x;
                    jiggleAxisY = jiggleAxisGravity.y;
                    jiggleAxisZ = jiggleAxisGravity.z;
                    jiggleGravity = jiggleAxisGravity.w;
                    jiggleMotionSensitivity = jiggleAdvanced.x;
                    jiggleMotionSmoothing = jiggleAdvanced.y;
                    jiggleEdgeFalloff = jiggleAdvanced.z;
                    activeSlider = 0u;
                }
                else if (hover == 510u)
                {
                    jiggleEnabled = jiggleEnabled > 0.5f ? 0.0f : 1.0f;
                    activeSlider = 0u;
                }
                else if (hover == 511u)
                {
                    jiggleMaskSlot = (jiggleMaskSlot + 7u) % 8u;
                    activeSlider = 0u;
                }
                else if (hover == 512u)
                {
                    jiggleMaskSlot = (jiggleMaskSlot + 1u) % 8u;
                    activeSlider = 0u;
                }
                else if (hover >= 513u && hover <= 515u)
                {
                    jiggleTab = hover - 513u;
                    activeSlider = 0u;
                }
                else if (hover >= 530u && hover <= 532u)
                {
                    if (hover == 530u) jiggleAxisX = jiggleAxisX > 0.5f ? 0.0f : 1.0f;
                    else if (hover == 531u) jiggleAxisY = jiggleAxisY > 0.5f ? 0.0f : 1.0f;
                    else jiggleAxisZ = jiggleAxisZ > 0.5f ? 0.0f : 1.0f;
                    activeSlider = 0u;
                }
                else if (hover == 545u)
                {
                    jiggleEnabled = 0.0f;
                    activeSlider = 0u;
                }
                else if (hover >= 540u && hover <= 544u)
                {
                    // Presets are applied to the currently selected group, then persisted by the INI bridge.
                    jiggleEnabled = 1.0f;
                    jiggleTab = 0u;
                    activeSlider = 0u;
                    if (hover == 540u) // SUBTLE
                    {
                        jiggleStiffness = 140.0f; jiggleDamping = 24.0f; jiggleStrength = 0.40f;
                        jiggleInertia = 0.30f; jiggleMaxOffset = 0.010f;
                        jiggleAxisX = 1.0f; jiggleAxisY = 1.0f; jiggleAxisZ = 0.0f; jiggleGravity = 0.0f;
                        jiggleMotionSensitivity = 0.55f; jiggleMotionSmoothing = 0.35f; jiggleEdgeFalloff = 1.40f;
                    }
                    else if (hover == 541u) // NATURAL
                    {
                        jiggleStiffness = 85.0f; jiggleDamping = 10.0f; jiggleStrength = 1.00f;
                        jiggleInertia = 0.80f; jiggleMaxOffset = 0.018f;
                        jiggleAxisX = 1.0f; jiggleAxisY = 1.0f; jiggleAxisZ = 0.0f; jiggleGravity = 0.0f;
                        jiggleMotionSensitivity = 1.00f; jiggleMotionSmoothing = 0.65f; jiggleEdgeFalloff = 1.00f;
                    }
                    else if (hover == 542u) // ZZZ-like: more elastic, more inertia, wider travel
                    {
                        jiggleStiffness = 58.0f; jiggleDamping = 6.0f; jiggleStrength = 1.25f;
                        jiggleInertia = 1.20f; jiggleMaxOffset = 0.045f;
                        jiggleAxisX = 1.0f; jiggleAxisY = 1.0f; jiggleAxisZ = 0.0f; jiggleGravity = 0.0f;
                        jiggleMotionSensitivity = 1.25f; jiggleMotionSmoothing = 0.80f; jiggleEdgeFalloff = 0.85f;
                    }
                    else if (hover == 543u) // STRONG
                    {
                        jiggleStiffness = 42.0f; jiggleDamping = 4.0f; jiggleStrength = 1.55f;
                        jiggleInertia = 1.40f; jiggleMaxOffset = 0.075f;
                        jiggleAxisX = 1.0f; jiggleAxisY = 1.0f; jiggleAxisZ = 1.0f; jiggleGravity = 0.03f;
                        jiggleMotionSensitivity = 1.50f; jiggleMotionSmoothing = 0.85f; jiggleEdgeFalloff = 0.80f;
                    }
                    else // EXTREME
                    {
                        jiggleStiffness = 28.0f; jiggleDamping = 2.5f; jiggleStrength = 2.10f;
                        jiggleInertia = 1.80f; jiggleMaxOffset = 0.130f;
                        jiggleAxisX = 1.0f; jiggleAxisY = 1.0f; jiggleAxisZ = 1.0f; jiggleGravity = 0.07f;
                        jiggleMotionSensitivity = 1.70f; jiggleMotionSmoothing = 0.90f; jiggleEdgeFalloff = 0.70f;
                    }
                }
                else if (hover >= 520u && hover <= 528u)
                {
                    activeSlider = hover;
                }
            }

            if (lmb && activeSlider >= 520u && activeSlider <= 528u)
            {
                float t = saturate((p.x - 0.51f) / 0.22f);

                if (activeSlider == 520u)
                    jiggleStiffness = lerp(0.0f, 200.0f, t);
                else if (activeSlider == 521u)
                    jiggleDamping = lerp(0.0f, 40.0f, t);
                else if (activeSlider == 522u)
                    jiggleStrength = lerp(0.0f, 3.0f, t);
                else if (activeSlider == 523u)
                    jiggleInertia = lerp(0.0f, 2.0f, t);
                else if (activeSlider == 524u)
                    jiggleMaxOffset = lerp(0.005f, 0.25f, t);
                else if (activeSlider == 525u)
                    jiggleGravity = lerp(-1.0f, 1.0f, t);
                else if (activeSlider == 526u)
                    jiggleMotionSensitivity = lerp(0.0f, 2.0f, t);
                else if (activeSlider == 527u)
                    jiggleMotionSmoothing = lerp(0.05f, 1.0f, t);
                else if (activeSlider == 528u)
                    jiggleEdgeFalloff = lerp(0.25f, 2.5f, t);
            }

            if (!lmb)
                activeSlider = 0u;
        }
        else if (page == 5u)
        {
            if (InRect(p, float2(0.365f, 0.330f), float2(0.560f, 0.390f)))
                hover = 730u;
        }
        else if (page == 6u)
        {
            // Module directory. Clicking a row selects it; OPEN enters its actual view.
            uint moduleScroll = (uint)clamp(floor(NURAUI_MODULE_SCROLL + 0.5f), 0.0f, 24.0f);
            uint selectedModuleOneBased = (uint)max(UIState[55] + 0.5f, 0.0f);
            if (InRect(p, float2(0.345f, 0.220f), float2(0.575f, 0.825f)))
            {
                hover = 699u;
                if (p.x >= 0.350f && p.x <= 0.565f && p.y >= 0.235f && p.y <= 0.783f)
                {
                    uint row = (uint)clamp(floor((p.y - 0.235f) / 0.070f), 0.0f, 7.0f);
                    float rowTop = 0.235f + (float)row * 0.070f;
                    uint slot = moduleScroll + row;
                    if (slot < 32u && NuraUIModuleRegistry[slot] != 0u)
                    {
                        if (InRect(p, float2(0.525f, rowTop), float2(0.565f, rowTop + 0.058f)))
                            hover = 640u + slot; // Favorite star; does not select/open the module.
                        else if (InRect(p, float2(0.350f, rowTop), float2(0.520f, rowTop + 0.058f)))
                            hover = 600u + slot; // Select module row.
                    }
                }
            }
            else if (InRect(p, float2(0.585f, 0.220f), float2(0.830f, 0.825f)))
            {
                hover = 699u;
                if (selectedModuleOneBased > 0u &&
                    InRect(p, float2(0.615f, 0.680f), float2(0.800f, 0.735f)))
                    hover = 700u;
            }
            activeSlider = 0u;
        }
        else if (page == 7u)
        {
            // Every module gets the same generic widget hit-testing on its own view.
            uint selectedModuleOneBased = (uint)max(UIState[55] + 0.5f, 0.0f);
            if (InRect(p, float2(0.355f, 0.215f), float2(0.455f, 0.265f)))
            {
                hover = 701u; // Back to the module directory.
            }
            else if (selectedModuleOneBased > 0u && selectedModuleOneBased <= 32u)
            {
                uint moduleSlot = selectedModuleOneBased - 1u;
                [loop]
                for (uint widget = 0u; widget < 8u; ++widget)
                {
                    uint base = (moduleSlot * 8u + widget) * 8u;
                    uint widgetType = (uint)max(round(NuraUIModuleWidgets[base]), 0.0f);
                    if (widgetType == 0u)
                        continue;
                    float2 mn = float2(NuraUIModuleWidgets[base + 1u], NuraUIModuleWidgets[base + 2u]);
                    float2 mx = float2(NuraUIModuleWidgets[base + 3u], NuraUIModuleWidgets[base + 4u]);
                    if (InRect(p, mn, mx))
                    {
                        hover = 800u + widget;
                        break;
                    }
                }
            }
            if (click)
            {
                if (hover == 701u)
                {
                    clicked = hover;
                    page = 6u;
                    activeSlider = 0u;
                }
                else if (hover >= 800u && hover < 808u && selectedModuleOneBased > 0u && selectedModuleOneBased <= 32u)
                {
                    uint widget = hover - 800u;
                    uint base = ((selectedModuleOneBased - 1u) * 8u + widget) * 8u;
                    uint widgetType = (uint)max(round(NuraUIModuleWidgets[base]), 0.0f);
                    clicked = hover;
                    if (widgetType == 1u)
                    {
                        activeSlider = hover;
                    }
                    else if (widgetType == 2u)
                    {
                        NuraUIModuleWidgets[base + 5u] = NuraUIModuleWidgets[base + 5u] > 0.5f ? 0.0f : 1.0f;
                    }
                    else if (widgetType == 3u)
                    {
                        // Action widget: click increments a persistent event counter.
                        // A module can detect a new activation by comparing this value
                        // with the value it observed on its previous frame.
                        float actionMin = floor(NuraUIModuleWidgets[base + 6u] + 0.5f);
                        float actionMax = floor(NuraUIModuleWidgets[base + 7u] + 0.5f);
                        float actionValue = floor(NuraUIModuleWidgets[base + 5u] + 0.5f);
                        if (actionMax <= actionMin)
                            actionMax = actionMin + 1.0f;
                        actionValue = (actionValue >= actionMax) ? actionMin : actionValue + 1.0f;
                        NuraUIModuleWidgets[base + 5u] = actionValue;
                    }
                    else if (widgetType == 4u)
                    {
                        // Cycle widget: click advances an integer-valued selection.
                        float cycleMin = floor(NuraUIModuleWidgets[base + 6u] + 0.5f);
                        float cycleMax = floor(NuraUIModuleWidgets[base + 7u] + 0.5f);
                        float cycleValue = floor(NuraUIModuleWidgets[base + 5u] + 0.5f);
                        if (cycleMax < cycleMin)
                            cycleMax = cycleMin;
                        cycleValue = (cycleValue >= cycleMax) ? cycleMin : cycleValue + 1.0f;
                        NuraUIModuleWidgets[base + 5u] = cycleValue;
                    }
                    else if (widgetType == 5u)
                    {
                        // Momentary button: emit a one-frame pulse; the next input dispatch clears it.
                        NuraUIModuleWidgets[base + 5u] = 1.0f;
                    }
                }
            }
            if (lmb && activeSlider >= 800u && activeSlider < 808u && selectedModuleOneBased > 0u && selectedModuleOneBased <= 32u)
            {
                uint widget = activeSlider - 800u;
                uint base = ((selectedModuleOneBased - 1u) * 8u + widget) * 8u;
                uint widgetType = (uint)max(round(NuraUIModuleWidgets[base]), 0.0f);
                if (widgetType == 1u)
                {
                    float x1 = NuraUIModuleWidgets[base + 1u];
                    float x2 = NuraUIModuleWidgets[base + 3u];
                    float minValue = NuraUIModuleWidgets[base + 6u];
                    float maxValue = NuraUIModuleWidgets[base + 7u];
                    float t = saturate((p.x - x1) / max(x2 - x1, 0.0001f));
                    NuraUIModuleWidgets[base + 5u] = lerp(minValue, maxValue, t);
                }
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
        // Rename modal remains modal. The keybind manager is a separate overlay panel.
        if (renameOpen)
        {
            if (InRect(p, float2(0.36f, 0.58f), float2(0.49f, 0.625f)))
                hover = 340u;
            else if (InRect(p, float2(0.51f, 0.58f), float2(0.64f, 0.625f)))
                hover = 341u;
        }
        else if (InRect(p, float2(0.012f, 0.804f), float2(0.100f, 0.861f)))
        {
            hover = 254u;
        }
        else if (InRect(p, float2(0.012f, 0.735f), float2(0.100f, 0.792f)))
        {
            hover = 108u;
        }
        else if (keybindPanelOpen && InRect(p, float2(0.735f, 0.125f), float2(0.980f, 0.710f)))
        {
            hover = 369u; // Consume clicks on the manager panel background.
            if (keybindActionListOpen && InRect(p, float2(0.750f, 0.180f), float2(0.965f, 0.444f)))
            {
                uint actionRow = (uint)clamp(floor((p.y - 0.180f) / 0.033f), 0.0f, 7.0f);
                hover = 400u + actionRow;
            }
            else if (InRect(p, float2(0.750f, 0.180f), float2(0.965f, 0.209f))) hover = 370u;
            else if (InRect(p, float2(0.750f, 0.213f), float2(0.965f, 0.242f))) hover = 371u;
            else if (InRect(p, float2(0.750f, 0.246f), float2(0.965f, 0.275f))) hover = 372u;
            else if (InRect(p, float2(0.750f, 0.279f), float2(0.965f, 0.308f))) hover = 373u;
            else if (InRect(p, float2(0.750f, 0.312f), float2(0.965f, 0.341f))) hover = 374u;
            else if (InRect(p, float2(0.750f, 0.345f), float2(0.965f, 0.374f))) hover = 375u;
            else if (InRect(p, float2(0.750f, 0.378f), float2(0.965f, 0.407f))) hover = 376u;
            else if (InRect(p, float2(0.750f, 0.411f), float2(0.965f, 0.440f))) hover = 377u;
            else if (InRect(p, float2(0.750f, 0.463f), float2(0.820f, 0.498f))) hover = 380u;
            else if (InRect(p, float2(0.825f, 0.463f), float2(0.890f, 0.498f))) hover = 381u;
            else if (InRect(p, float2(0.895f, 0.463f), float2(0.965f, 0.498f))) hover = 384u;
            else if (InRect(p, float2(0.750f, 0.505f), float2(0.965f, 0.540f))) hover = 382u;
            else if (InRect(p, float2(0.750f, 0.545f), float2(0.790f, 0.580f))) hover = 385u;
            else if (InRect(p, float2(0.910f, 0.545f), float2(0.965f, 0.580f))) hover = 386u;
            else if (InRect(p, float2(0.750f, 0.585f), float2(0.800f, 0.620f))) hover = 390u;
            else if (InRect(p, float2(0.805f, 0.585f), float2(0.850f, 0.620f))) hover = 391u;
            else if (InRect(p, float2(0.855f, 0.585f), float2(0.900f, 0.620f))) hover = 392u;
            else if (InRect(p, float2(0.905f, 0.585f), float2(0.965f, 0.620f))) hover = 393u;
            else if (InRect(p, float2(0.750f, 0.625f), float2(0.800f, 0.660f))) hover = 394u;
            else if (InRect(p, float2(0.805f, 0.625f), float2(0.850f, 0.660f))) hover = 395u;
            else if (InRect(p, float2(0.855f, 0.625f), float2(0.900f, 0.660f))) hover = 396u;
            else if (InRect(p, float2(0.905f, 0.625f), float2(0.965f, 0.660f))) hover = 397u;
            else if (InRect(p, float2(0.750f, 0.665f), float2(0.850f, 0.700f))) hover = 398u;
            else if (InRect(p, float2(0.860f, 0.665f), float2(0.965f, 0.700f))) hover = 399u;
        }
        else if (tool == 15u)
        {
            // Weight Paint controls: centred slider cells, dropdowns and a scrollable VG list.
            if (weightVGListOpen && InRect(p, float2(0.286f, 0.130f), float2(0.299f, 0.402f))) hover = 268u;
            else if (weightVGListOpen && InRect(p, float2(0.120f, 0.126f), float2(0.300f, 0.404f)))
            {
                uint listRow = (uint)clamp(floor((p.y - 0.130f) / 0.034f), 0.0f, 7.0f);
                hover = 260u + listRow;
            }
            else if (falloffOpen && InRect(p, float2(0.500f, 0.084f), float2(0.620f, 0.118f))) hover = 231u;
            else if (falloffOpen && InRect(p, float2(0.500f, 0.120f), float2(0.620f, 0.154f))) hover = 232u;
            else if (falloffOpen && InRect(p, float2(0.500f, 0.156f), float2(0.620f, 0.190f))) hover = 233u;
            else if (falloffOpen && InRect(p, float2(0.500f, 0.192f), float2(0.620f, 0.226f))) hover = 234u;
            else if (falloffOpen && InRect(p, float2(0.500f, 0.228f), float2(0.620f, 0.262f))) hover = 235u;

            else if (weightModeOpen && InRect(p, float2(0.640f, 0.084f), float2(0.770f, 0.118f))) hover = 243u;
            else if (weightModeOpen && InRect(p, float2(0.640f, 0.120f), float2(0.770f, 0.154f))) hover = 244u;
            else if (weightModeOpen && InRect(p, float2(0.640f, 0.156f), float2(0.770f, 0.190f))) hover = 245u;
            else if (weightModeOpen && InRect(p, float2(0.640f, 0.192f), float2(0.770f, 0.226f))) hover = 251u;
            else if (weightModeOpen && InRect(p, float2(0.640f, 0.228f), float2(0.770f, 0.262f))) hover = 252u;

            else if (mirrorOpen && InRect(p, float2(0.790f, 0.084f), float2(0.960f, 0.118f))) hover = 247u;
            else if (mirrorOpen && InRect(p, float2(0.790f, 0.120f), float2(0.960f, 0.154f))) hover = 248u;
            else if (mirrorOpen && InRect(p, float2(0.790f, 0.156f), float2(0.960f, 0.190f))) hover = 249u;
            else if (mirrorOpen && InRect(p, float2(0.790f, 0.192f), float2(0.960f, 0.226f))) hover = 250u;

            // Independent named-mask panel toggle. This occupies the spare row below MIRROR.
            // When the MIRROR popup is open its options above take priority.
            else if (!mirrorOpen && InRect(p, float2(0.790f, 0.084f), float2(0.960f, 0.118f))) hover = 253u;

            // Named-mask panel is routable while Weight Paint (tool 15) remains active.
            // The panel background itself receives a hit ID so blank-panel clicks cannot
            // fall through to an underlying control.
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.140f), float2(0.783f, 0.183f))) hover = 330u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.140f), float2(0.874f, 0.183f))) hover = 300u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.140f), float2(0.960f, 0.183f))) hover = 320u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.187f), float2(0.783f, 0.230f))) hover = 331u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.187f), float2(0.874f, 0.230f))) hover = 301u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.187f), float2(0.960f, 0.230f))) hover = 321u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.234f), float2(0.783f, 0.277f))) hover = 332u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.234f), float2(0.874f, 0.277f))) hover = 302u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.234f), float2(0.960f, 0.277f))) hover = 322u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.281f), float2(0.783f, 0.324f))) hover = 333u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.281f), float2(0.874f, 0.324f))) hover = 303u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.281f), float2(0.960f, 0.324f))) hover = 323u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.328f), float2(0.783f, 0.371f))) hover = 334u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.328f), float2(0.874f, 0.371f))) hover = 304u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.328f), float2(0.960f, 0.371f))) hover = 324u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.375f), float2(0.783f, 0.418f))) hover = 335u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.375f), float2(0.874f, 0.418f))) hover = 305u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.375f), float2(0.960f, 0.418f))) hover = 325u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.422f), float2(0.783f, 0.465f))) hover = 336u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.422f), float2(0.874f, 0.465f))) hover = 306u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.422f), float2(0.960f, 0.465f))) hover = 326u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.469f), float2(0.783f, 0.512f))) hover = 337u;
            else if (maskPanelOpen && InRect(p, float2(0.787f, 0.469f), float2(0.874f, 0.512f))) hover = 307u;
            else if (maskPanelOpen && InRect(p, float2(0.880f, 0.469f), float2(0.960f, 0.512f))) hover = 327u;
            else if (maskPanelOpen && InRect(p, float2(0.760f, 0.555f), float2(0.805f, 0.593f))) hover = 350u;
            else if (maskPanelOpen && InRect(p, float2(0.810f, 0.555f), float2(0.855f, 0.593f))) hover = 351u;
            else if (maskPanelOpen && InRect(p, float2(0.860f, 0.555f), float2(0.905f, 0.593f))) hover = 352u;
            else if (maskPanelOpen && InRect(p, float2(0.910f, 0.555f), float2(0.960f, 0.593f))) hover = 353u;
            else if (maskPanelOpen && InRect(p, float2(0.768f, 0.600f), float2(0.828f, 0.638f))) hover = 354u;
            else if (maskPanelOpen && InRect(p, float2(0.833f, 0.600f), float2(0.893f, 0.638f))) hover = 355u;
            else if (maskPanelOpen && InRect(p, float2(0.898f, 0.600f), float2(0.960f, 0.638f))) hover = 356u;
            else if (maskPanelOpen && InRect(p, float2(0.780f, 0.516f), float2(0.860f, 0.548f))) hover = 361u;
            else if (maskPanelOpen && InRect(p, float2(0.885f, 0.516f), float2(0.960f, 0.548f))) hover = 362u;
            else if (maskPanelOpen && InRect(p, float2(0.750f, 0.125f), float2(0.970f, 0.665f))) hover = 359u;

            // One selector button opens the vertically scrollable VG ID list.
            else if (InRect(p, float2(0.120f, 0.087f), float2(0.300f, 0.120f))) hover = 240u;

            // Slider hitboxes include their label/value line and the track below.
            else if (InRect(p, float2(0.150f, 0.035f), float2(0.250f, 0.084f))) hover = 200u;
            else if (InRect(p, float2(0.290f, 0.035f), float2(0.375f, 0.084f))) hover = 201u;
            else if (InRect(p, float2(0.395f, 0.035f), float2(0.480f, 0.084f))) hover = 202u;
            else if (InRect(p, float2(0.500f, 0.047f), float2(0.620f, 0.081f))) hover = 230u;
            else if (InRect(p, float2(0.640f, 0.047f), float2(0.770f, 0.081f))) hover = 242u;
            else if (InRect(p, float2(0.790f, 0.047f), float2(0.960f, 0.081f))) hover = 246u;

            // Existing tool buttons remain available; Weight Paint itself is selected with V.
            else if (InRect(p, float2(0.012f, 0.140f), float2(0.100f, 0.205f))) hover = 100u;
            else if (InRect(p, float2(0.012f, 0.213f), float2(0.100f, 0.278f))) hover = 101u;
            else if (InRect(p, float2(0.012f, 0.286f), float2(0.100f, 0.351f))) hover = 102u;
            else if (InRect(p, float2(0.012f, 0.359f), float2(0.100f, 0.424f))) hover = 103u;
            else if (InRect(p, float2(0.012f, 0.432f), float2(0.100f, 0.497f))) hover = 104u;
            else if (InRect(p, float2(0.012f, 0.505f), float2(0.100f, 0.570f))) hover = 105u;
            else if (InRect(p, float2(0.012f, 0.578f), float2(0.100f, 0.643f))) hover = 106u;
            else if (InRect(p, float2(0.012f, 0.651f), float2(0.100f, 0.716f))) hover = 107u;
        }
        else
        {
            // Existing overlay controls for the non-Weight-Paint tools are unchanged.
            if (falloffOpen && InRect(p, float2(+0.5600f, +0.0764f), float2(+0.6600f, +0.1104f))) hover = 231u;
            else if (falloffOpen && InRect(p, float2(+0.5600f, +0.1106f), float2(+0.6600f, +0.1446f))) hover = 232u;
            else if (falloffOpen && InRect(p, float2(+0.5600f, +0.1460f), float2(+0.6600f, +0.1800f))) hover = 233u;
            else if (falloffOpen && InRect(p, float2(+0.5600f, +0.1850f), float2(+0.6600f, +0.2190f))) hover = 234u;
            else if (falloffOpen && InRect(p, float2(+0.5600f, +0.2222f), float2(+0.6600f, +0.2562f))) hover = 235u;

            // Named mask slots and operations.
            else if (InRect(p, float2(0.760f, 0.140f), float2(0.783f, 0.183f))) hover = 330u;
            else if (InRect(p, float2(0.787f, 0.140f), float2(0.874f, 0.183f))) hover = 300u;
            else if (InRect(p, float2(0.880f, 0.140f), float2(0.960f, 0.183f))) hover = 320u;
            else if (InRect(p, float2(0.760f, 0.187f), float2(0.783f, 0.230f))) hover = 331u;
            else if (InRect(p, float2(0.787f, 0.187f), float2(0.874f, 0.230f))) hover = 301u;
            else if (InRect(p, float2(0.880f, 0.187f), float2(0.960f, 0.230f))) hover = 321u;
            else if (InRect(p, float2(0.760f, 0.234f), float2(0.783f, 0.277f))) hover = 332u;
            else if (InRect(p, float2(0.787f, 0.234f), float2(0.874f, 0.277f))) hover = 302u;
            else if (InRect(p, float2(0.880f, 0.234f), float2(0.960f, 0.277f))) hover = 322u;
            else if (InRect(p, float2(0.760f, 0.281f), float2(0.783f, 0.324f))) hover = 333u;
            else if (InRect(p, float2(0.787f, 0.281f), float2(0.874f, 0.324f))) hover = 303u;
            else if (InRect(p, float2(0.880f, 0.281f), float2(0.960f, 0.324f))) hover = 323u;
            else if (InRect(p, float2(0.760f, 0.328f), float2(0.783f, 0.371f))) hover = 334u;
            else if (InRect(p, float2(0.787f, 0.328f), float2(0.874f, 0.371f))) hover = 304u;
            else if (InRect(p, float2(0.880f, 0.328f), float2(0.960f, 0.371f))) hover = 324u;
            else if (InRect(p, float2(0.760f, 0.375f), float2(0.783f, 0.418f))) hover = 335u;
            else if (InRect(p, float2(0.787f, 0.375f), float2(0.874f, 0.418f))) hover = 305u;
            else if (InRect(p, float2(0.880f, 0.375f), float2(0.960f, 0.418f))) hover = 325u;
            else if (InRect(p, float2(0.760f, 0.422f), float2(0.783f, 0.465f))) hover = 336u;
            else if (InRect(p, float2(0.787f, 0.422f), float2(0.874f, 0.465f))) hover = 306u;
            else if (InRect(p, float2(0.880f, 0.422f), float2(0.960f, 0.465f))) hover = 326u;
            else if (InRect(p, float2(0.760f, 0.469f), float2(0.783f, 0.512f))) hover = 337u;
            else if (InRect(p, float2(0.787f, 0.469f), float2(0.874f, 0.512f))) hover = 307u;
            else if (InRect(p, float2(0.880f, 0.469f), float2(0.960f, 0.512f))) hover = 327u;
            else if (InRect(p, float2(0.760f, 0.555f), float2(0.805f, 0.593f))) hover = 350u;
            else if (InRect(p, float2(0.810f, 0.555f), float2(0.855f, 0.593f))) hover = 351u;
            else if (InRect(p, float2(0.860f, 0.555f), float2(0.905f, 0.593f))) hover = 352u;
            else if (InRect(p, float2(0.910f, 0.555f), float2(0.960f, 0.593f))) hover = 353u;
            else if (InRect(p, float2(0.768f, 0.600f), float2(0.828f, 0.638f))) hover = 354u;
            else if (InRect(p, float2(0.833f, 0.600f), float2(0.893f, 0.638f))) hover = 355u;
            else if (InRect(p, float2(0.898f, 0.600f), float2(0.960f, 0.638f))) hover = 356u;

            // Tool buttons and existing top bar.
            else if (InRect(p, float2(0.012f, 0.140f), float2(0.100f, 0.205f))) hover = 100u;
            else if (InRect(p, float2(0.012f, 0.213f), float2(0.100f, 0.278f))) hover = 101u;
            else if (InRect(p, float2(0.012f, 0.286f), float2(0.100f, 0.351f))) hover = 102u;
            else if (InRect(p, float2(0.012f, 0.359f), float2(0.100f, 0.424f))) hover = 103u;
            else if (InRect(p, float2(0.012f, 0.432f), float2(0.100f, 0.497f))) hover = 104u;
            else if (InRect(p, float2(0.012f, 0.505f), float2(0.100f, 0.570f))) hover = 105u;
            else if (InRect(p, float2(0.012f, 0.578f), float2(0.100f, 0.643f))) hover = 106u;
            else if (InRect(p, float2(0.012f, 0.651f), float2(0.100f, 0.716f))) hover = 107u;
            else if (InRect(p, float2(0.16f, 0.039f), float2(0.245f, 0.069f))) hover = 200u;
            else if (InRect(p, float2(+0.3629f, +0.0405f), float2(+0.4379f, +0.0705f))) hover = 201u;
            else if (InRect(p, float2(+0.5600f, +0.0414f), float2(+0.6600f, +0.0714f))) hover = 230u;
            else if (InRect(p, float2(0.70f, 0.060f), float2(0.74f, 0.082f))) hover = 210u;
            else if (InRect(p, float2(0.75f, 0.060f), float2(0.79f, 0.082f))) hover = 211u;
            else if (InRect(p, float2(0.80f, 0.060f), float2(0.84f, 0.082f))) hover = 212u;
            else if (InRect(p, float2(0.86f, 0.060f), float2(0.97f, 0.082f))) hover = 220u;
            else if (InRect(p, float2(0.780f, 0.516f), float2(0.860f, 0.548f))) hover = 361u;
            else if (InRect(p, float2(0.885f, 0.516f), float2(0.960f, 0.548f))) hover = 362u;
        }

        if (click)
        {
            clicked = hover;
            if (renameOpen)
            {
                if (hover == 340u || hover == 341u)
                {
                    renameOpen = false;
                    activeSlider = 0u;
                }
            }
            else if (hover == 254u)
            {
                keybindPanelOpen = !keybindPanelOpen;
                keybindActionListOpen = false;
                if (keybindPanelOpen)
                {
                    maskPanelOpen = false;
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false;
                    weightVGListOpen = false; activeSlider = 0u;
                }
            }
            else if (hover >= 100u && hover <= 108u)
            {
                if (hover == 108u)
                {
                    tool = 15u;
                    strength = saturate((weightStrength - 0.05f) / 0.95f);
                    actualStrength = weightStrength;
                }
                else
                {
                    tool = hover - 100u;
                    strength = GetStrengthUI(tool);
                    actualStrength = GetStrengthDefault(tool);
                }
                activeSlider = 0u;
                maskPanelOpen = false;
                keybindPanelOpen = false;
                keybindActionListOpen = false;
                falloffOpen = false; weightModeOpen = false; mirrorOpen = false; weightVGListOpen = false;
            }
            else if (hover == 253u && tool == 15u)
            {
                maskPanelOpen = !maskPanelOpen;
                if (maskPanelOpen)
                {
                    keybindPanelOpen = false;
                    keybindActionListOpen = false;
                }
                falloffOpen = false; weightModeOpen = false; mirrorOpen = false;
                weightVGListOpen = false; activeSlider = 0u;
            }
            else if (keybindPanelOpen)
            {
                if (keybindActionListOpen)
                {
                    if (hover >= 400u && hover <= 407u)
                    {
                        keybindAction = (uint)clamp(keybindActionListScroll + (float)(hover - 400u) + 1.0f, 1.0f, 21.0f);
                        keybindActionListOpen = false;
                    }
                    else
                    {
                        keybindActionListOpen = false;
                    }
                    activeSlider = 0u;
                }
                else if (hover >= 370u && hover <= 377u)
                {
                    keybindSelectedSlot = hover - 370u;
                    activeSlider = 0u;
                }
                else if (hover == 382u)
                {
                    keybindActionListOpen = !keybindActionListOpen;
                    activeSlider = 0u;
                }
                else if (hover == 385u)
                {
                    keybindArg = keybindArg == 0u ? 4u : keybindArg - 1u;
                    activeSlider = 0u;
                }
                else if (hover == 386u)
                {
                    keybindArg = keybindArg >= 4u ? 0u : keybindArg + 1u;
                    activeSlider = 0u;
                }
                else if (hover >= 390u && hover <= 393u)
                {
                    keybindSelectedMacro = hover - 390u;
                    activeSlider = 0u;
                }
                else
                {
                    activeSlider = 0u;
                }
            }
            else if (tool == 15u)
            {
                // The mask panel is an independent UI surface; clicking it never changes
                // Weight Paint's tool ID or weight mode. The shared INI dispatcher consumes
                // the same mask action IDs as it does for the other Mesh Editor tools.
                if (maskPanelOpen && hover >= 300u && hover <= 307u)
                {
                    maskSlot = hover - 300u;
                    activeSlider = 0u;
                }
                else if (maskPanelOpen && hover >= 320u && hover <= 327u)
                {
                    renameSlot = hover - 320u;
                    renameOpen = true;
                    activeSlider = 0u;
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false;
                    weightVGListOpen = false;
                }
                else if (maskPanelOpen && ((hover >= 330u && hover <= 337u) ||
                                           (hover >= 350u && hover <= 356u) ||
                                           hover == 359u || hover == 361u || hover == 362u))
                {
                    // Selection, preview toggles and mask operations are dispatched by INI.
                    // Keep the mask panel open; do not retarget or start a weight operation.
                    activeSlider = 0u;
                }
                else if (hover >= 260u && hover <= 267u)
                {
                    weightVG = clamp(floor(weightVGListScroll + (float)(hover - 260u) + 0.5f), 0.0f, 117.0f);
                    weightVGListOpen = false;
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false; activeSlider = 0u;
                }
                else if (hover >= 231u && hover <= 235u)
                {
                    falloffMode = hover - 231u;
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false; weightVGListOpen = false;
                    activeSlider = 0u;
                }
                else if (hover >= 243u && hover <= 245u)
                {
                    weightMode = hover - 243u;
                    weightModeOpen = false;
                    falloffOpen = false;
                    mirrorOpen = false;
                    activeSlider = 0u;
                }
                else if (hover == 251u || hover == 252u)
                {
                    weightMode = hover == 251u ? 3u : 4u;
                    weightModeOpen = false;
                    falloffOpen = false;
                    mirrorOpen = false;
                    activeSlider = 0u;
                }
                else if (hover >= 247u && hover <= 250u)
                {
                    uint mirrorChoice = hover - 247u;
                    if (mirrorChoice == 0u)
                    {
                        mirror = 0.0f;
                    }
                    else
                    {
                        mirror = 1.0f;
                        mirrorAxis = mirrorChoice - 1u;
                    }
                    mirrorOpen = false;
                    falloffOpen = false;
                    weightModeOpen = false;
                    activeSlider = 0u;
                }
                else if (hover == 268u)
                {
                    activeSlider = 53u;
                    weightVGListScroll = floor(clamp(((p.y - 0.143f) / 0.233f) * 110.0f, 0.0f, 110.0f) + 0.5f);
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false;
                }
                else if (hover == 240u)
                {
                    bool openingVGList = !weightVGListOpen;
                    weightVGListOpen = openingVGList;
                    if (openingVGList)
                        weightVGListScroll = floor(clamp(weightVG - 3.5f, 0.0f, 110.0f) + 0.5f);
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false; activeSlider = 0u;
                }
                else if (hover == 200u) { activeSlider = 50u; falloffOpen = false; weightModeOpen = false; mirrorOpen = false; }
                else if (hover == 201u) { activeSlider = 51u; falloffOpen = false; weightModeOpen = false; mirrorOpen = false; }
                else if (hover == 202u) { activeSlider = 52u; falloffOpen = false; weightModeOpen = false; mirrorOpen = false; }
                else if (hover == 230u) { falloffOpen = !falloffOpen; weightModeOpen = false; mirrorOpen = false; weightVGListOpen = false; activeSlider = 0u; }
                else if (hover == 242u) { weightModeOpen = !weightModeOpen; if (weightModeOpen) maskPanelOpen = false; falloffOpen = false; mirrorOpen = false; weightVGListOpen = false; activeSlider = 0u; }
                else if (hover == 246u) { mirrorOpen = !mirrorOpen; if (mirrorOpen) maskPanelOpen = false; falloffOpen = false; weightModeOpen = false; weightVGListOpen = false; activeSlider = 0u; }
                else if (hover >= 100u && hover <= 107u)
                {
                    tool = hover - 100u;
                    activeSlider = 0u;
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false; weightVGListOpen = false;
                    strength = GetStrengthUI(tool);
                    actualStrength = GetStrengthDefault(tool);
                }
                else if (hover != 0u)
                {
                    falloffOpen = false; weightModeOpen = false; mirrorOpen = false; weightVGListOpen = false;
                    activeSlider = 0u;
                }
            }
            else
            {
                if (hover >= 300u && hover <= 307u)
                {
                    maskSlot = hover - 300u;
                    activeSlider = 0u;
                }
                else if (hover >= 320u && hover <= 327u)
                {
                    renameSlot = hover - 320u;
                    renameOpen = true;
                    activeSlider = 0u;
                    falloffOpen = false;
                }
                else if (hover >= 231u && hover <= 235u)
                {
                    falloffMode = hover - 231u;
                    falloffOpen = false;
                    activeSlider = 0u;
                }
                else if (hover >= 100u && hover <= 107u)
                {
                    tool = hover - 100u;
                    activeSlider = 0u;
                    strength = GetStrengthUI(tool);
                    actualStrength = GetStrengthDefault(tool);
                }
                else if (hover == 200u) activeSlider = 50u;
                else if (hover == 201u) activeSlider = 51u;
                else if (hover >= 210u && hover <= 212u)
                {
                    uint newAxis = hover - 210u;
                    if (mirror > 0.5f && mirrorAxis == newAxis) mirror = 0.0f;
                    else { mirror = 1.0f; mirrorAxis = newAxis; }
                    activeSlider = 0u;
                }
                else if (hover == 220u) activeSlider = 0u;
                else if (hover == 230u) { falloffOpen = !falloffOpen; activeSlider = 0u; }
                else if (hover == 361u)
                {
                    clicked = hover;
                }
                else if (hover == 362u)
                {
                    clicked = hover;
                }
            }
        }

        if (lmb && activeSlider == 50u)
        {
            float t = saturate((p.x - 0.16f) / 0.085f);
            radius = lerp(0.010f, 1.0f, t);
        }
        else if (lmb && activeSlider == 51u)
        {
            if (tool == 15u)
            {
                float t = saturate((p.x - 0.30f) / 0.065f);
                strength = t;
                weightStrength = lerp(0.05f, 1.0f, t);
                actualStrength = weightStrength;
            }
            else
            {
                float t = saturate((p.x - 0.3660f) / 0.075f);
                strength = t;
                actualStrength = GetStrengthValue(tool, t);
            }
        }
        else if (lmb && activeSlider == 52u && tool == 15u)
        {
            weightTarget = saturate((p.x - 0.405f) / 0.065f);
        }
        else if (lmb && activeSlider == 53u && tool == 15u && weightVGListOpen)
        {
            weightVGListScroll = floor(clamp(((p.y - 0.143f) / 0.233f) * 110.0f, 0.0f, 110.0f) + 0.5f);
        }
        if (!lmb) activeSlider = 0u;
    }

    else

    {

        activeSlider = 0u;

    }

    // Sidebar hit-tests take priority over page contents, so handle page navigation
    // once here, outside the content-page branches.
    if (mainUI && click && hover >= 10u && hover <= 15u)
    {
        clicked = hover;
        if (hover == 10u) page = 0u;
        else if (hover == 11u) page = 1u;
        else if (hover == 12u) page = 2u;
        else if (hover == 13u) page = 4u;
        else if (hover == 14u) page = 5u;
        else if (hover == 15u) page = 6u;
        activeSlider = 0u;
    }
    else if (mainUI && click && hover >= 640u && hover < 672u)
    {
        uint favoriteSlot = hover - 640u;
        if (favoriteSlot < 32u)
        {
            uint favoriteModuleId = NuraUIModuleRegistry[favoriteSlot];
            if (favoriteModuleId != 0u)
            {
                clicked = hover;
                favoriteClickedModuleId = (float)favoriteModuleId;
            }
        }
        activeSlider = 0u;
    }
    else if (mainUI && click && hover == 730u)
    {
        clicked = hover;
        favoriteWheelEnabled = 1.0f - favoriteWheelEnabled;
        activeSlider = 0u;
    }
    else if (mainUI && click && hover >= 600u && hover < 632u)
    {
        clicked = hover;
        UIState[55] = (float)(hover - 599u);
        activeSlider = 0u;
    }
    else if (mainUI && click && page == 6u && hover == 700u && UIState[55] > 0.5f)
    {
        clicked = hover;
        page = 7u;
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
    UIState[18] = (float)maskSlot;
    UIState[19] = renameOpen ? 1.0f : 0.0f;
    UIState[20] = (float)renameSlot;

    UIState[21] = (float)jiggleGroup;
    UIState[22] = jiggleEnabled;
    UIState[23] = (float)jiggleMaskSlot;
    UIState[24] = jiggleStiffness;
    UIState[25] = jiggleDamping;
    UIState[26] = jiggleStrength;
    UIState[27] = jiggleInertia;
    UIState[28] = jiggleMaxOffset;
    UIState[29] = (float)jiggleTab;
    UIState[30] = jiggleAxisX;
    UIState[31] = jiggleAxisY;
    UIState[32] = jiggleAxisZ;
    UIState[33] = jiggleGravity;
    UIState[34] = jiggleMotionSensitivity;
    UIState[35] = jiggleMotionSmoothing;
    UIState[36] = jiggleEdgeFalloff;

    UIState[37] = clamp(weightVG, 0.0f, 117.0f);
    UIState[38] = (float)clamp(weightMode, 0u, 4u);
    UIState[39] = saturate(weightTarget);
    UIState[40] = clamp(weightStrength, 0.05f, 1.0f);
    UIState[41] = weightModeOpen ? 1.0f : 0.0f;
    UIState[42] = mirrorOpen ? 1.0f : 0.0f;
    UIState[43] = weightVGListOpen ? 1.0f : 0.0f;
    UIState[44] = floor(clamp(weightVGListScroll, 0.0f, 110.0f) + 0.5f);
    UIState[45] = (weightVGListOpen && InRect(p, float2(0.120f, 0.126f), float2(0.300f, 0.404f))) ? 1.0f : 0.0f;
    UIState[46] = maskPanelOpen ? 1.0f : 0.0f;
    UIState[47] = keybindPanelOpen ? 1.0f : 0.0f;
    UIState[48] = (float)keybindSelectedSlot;
    UIState[49] = (float)keybindSelectedMacro;
    UIState[50] = (float)keybindAction;
    UIState[51] = (float)keybindArg;
    UIState[52] = keybindActionListOpen ? 1.0f : 0.0f;
    UIState[53] = floor(clamp(keybindActionListScroll, 0.0f, 13.0f) + 0.5f);
    UIState[54] = (keybindActionListOpen && keybindPanelOpen && InRect(p, float2(0.750f, 0.180f), float2(0.965f, 0.444f))) ? 1.0f : 0.0f;
    UIState[57] = favoriteWheelEnabled;
    UIState[58] = favoriteClickedModuleId;

    WRITE_NAME(80, 0);
    WRITE_NAME(84, 16);
    WRITE_NAME(88, 32);
    WRITE_NAME(92, 48);
    WRITE_NAME(96, 64);
    WRITE_NAME(100, 80);
    WRITE_NAME(104, 96);
    WRITE_NAME(108, 112);
    WRITE_NAME(112, 128);

}