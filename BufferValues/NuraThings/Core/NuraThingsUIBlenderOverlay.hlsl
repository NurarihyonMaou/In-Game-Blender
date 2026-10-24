Buffer<float> UIState : register(t0);
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

#ifdef PIXEL_SHADER
float4 main(VSOut input) : SV_Target0
{
    float2 screen = float2(max(SCREEN_WIDTH, 1.0f), max(SCREEN_HEIGHT, 1.0f));
    float2 p = input.pos.xy / screen;
    uint tool = (uint)max(UIState[1] + 0.5f, 0.0f);
    uint hover = (uint)max(UIState[3] + 0.5f, 0.0f);
    float mirror = UIState[5];
    uint mirrorAxis = (uint)max(UIState[6] + 0.5f, 0.0f);
    uint activeSlider = (uint)max(UIState[7] + 0.5f, 0.0f);
    float radius = UIState[8];
    float strength = UIState[9];
    uint falloffMode = (uint)clamp(UIState[16] + 0.5f, 0.0f, 4.0f);
    bool falloffOpen = UIState[17] > 0.5f;
    float4 col = float4(0.0f, 0.0f, 0.0f, 0.0f);

    float header = RoundRect(p, float2(0.10f, 0.015f), float2(0.99f, 0.090f), 0.012f);
    col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.94f), header);
    if (Box(p, float2(0.10f, 0.087f), float2(0.99f, 0.089f)) > 0.5f)
        col = float4(0.0f, 0.40f, 0.58f, 1.0f);

    float toolbar = RoundRect(p, float2(0.012f, 0.130f), float2(0.100f, 0.726f), 0.010f);
    col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.94f), toolbar);
    if (Box(p, float2(0.012f, 0.140f), float2(0.100f, 0.205f)) > 0.5f) col = ToolButton(tool, 0u, hover);
    if (Box(p, float2(0.012f, 0.213f), float2(0.100f, 0.278f)) > 0.5f) col = ToolButton(tool, 1u, hover);
    if (Box(p, float2(0.012f, 0.286f), float2(0.100f, 0.351f)) > 0.5f) col = ToolButton(tool, 2u, hover);
    if (Box(p, float2(0.012f, 0.359f), float2(0.100f, 0.424f)) > 0.5f) col = ToolButton(tool, 3u, hover);
    if (Box(p, float2(0.012f, 0.432f), float2(0.100f, 0.497f)) > 0.5f) col = ToolButton(tool, 4u, hover);
    if (Box(p, float2(0.012f, 0.505f), float2(0.100f, 0.570f)) > 0.5f) col = ToolButton(tool, 5u, hover);
    if (Box(p, float2(0.012f, 0.578f), float2(0.100f, 0.643f)) > 0.5f) col = ToolButton(tool, 6u, hover);
    if (Box(p, float2(0.012f, 0.651f), float2(0.100f, 0.716f)) > 0.5f) col = ToolButton(tool, 7u, hover);

    float radiusT = saturate((radius - 0.02f) / 0.23f);
    float radiusX = lerp(0.16f, 0.245f, radiusT);
    float radiusTrack = RoundRect(p, float2(0.16f, 0.051f), float2(0.245f, 0.057f), 0.003f);
    col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), radiusTrack);
    float radiusFill = RoundRect(p, float2(0.16f, 0.051f), float2(radiusX, 0.057f), 0.003f);
    col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), radiusFill);
    bool radiusActive = hover == 200u || activeSlider == 50u;
    float radiusMask = Circle(p, float2(radiusX, 0.054f), radiusActive ? 0.009f : 0.007f);
    if (radiusMask > 0.0f) col = lerp(col, radiusActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), radiusMask);

    float strengthX = lerp(0.47f, 0.545f, strength);
    float strengthTrack = RoundRect(p, float2(0.47f, 0.051f), float2(0.545f, 0.057f), 0.003f);
    col = lerp(col, float4(0.055f, 0.060f, 0.070f, 1.0f), strengthTrack);
    float strengthFill = RoundRect(p, float2(0.47f, 0.051f), float2(strengthX, 0.057f), 0.003f);
    col = lerp(col, float4(0.0f, 0.13f, 0.18f, 1.0f), strengthFill);
    bool strengthActive = hover == 201u || activeSlider == 51u;
    float strengthMask = Circle(p, float2(strengthX, 0.054f), strengthActive ? 0.009f : 0.007f);
    if (strengthMask > 0.0f) col = lerp(col, strengthActive ? float4(0.0f, 0.65f, 0.85f, 1.0f) : float4(0.0f, 0.45f, 0.65f, 1.0f), strengthMask);

    float falloffMask = RoundRect(p, float2(0.58f, 0.039f), float2(0.69f, 0.069f), 0.008f);
    float4 falloffColor = (hover == 230u || falloffOpen) ? float4(0.0f, 0.16f, 0.21f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 0.94f);
    col = lerp(col, falloffColor, falloffMask);

    if (falloffOpen)
    {
        float dropdown = RoundRect(p, float2(0.575f, 0.071f), float2(0.695f, 0.255f), 0.008f);
        col = lerp(col, float4(0.020f, 0.024f, 0.030f, 0.98f), dropdown);
        if (Box(p, float2(0.575f, 0.074f), float2(0.695f, 0.108f)) > 0.5f) col = hover == 231u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 0u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        if (Box(p, float2(0.575f, 0.110f), float2(0.695f, 0.144f)) > 0.5f) col = hover == 232u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 1u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        if (Box(p, float2(0.575f, 0.146f), float2(0.695f, 0.180f)) > 0.5f) col = hover == 233u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 2u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        if (Box(p, float2(0.575f, 0.182f), float2(0.695f, 0.216f)) > 0.5f) col = hover == 234u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 3u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
        if (Box(p, float2(0.575f, 0.218f), float2(0.695f, 0.252f)) > 0.5f) col = hover == 235u ? float4(0.0f, 0.16f, 0.21f, 1.0f) : (falloffMode == 4u ? float4(0.0f, 0.13f, 0.18f, 1.0f) : float4(0.035f, 0.040f, 0.048f, 1.0f));
    }

    if (Box(p, float2(0.70f, 0.060f), float2(0.74f, 0.082f)) > 0.5f) col = MirrorButton(mirror > 0.5f && mirrorAxis == 0u, hover == 210u);
    if (Box(p, float2(0.75f, 0.060f), float2(0.79f, 0.082f)) > 0.5f) col = MirrorButton(mirror > 0.5f && mirrorAxis == 1u, hover == 211u);
    if (Box(p, float2(0.80f, 0.060f), float2(0.84f, 0.082f)) > 0.5f) col = MirrorButton(mirror > 0.5f && mirrorAxis == 2u, hover == 212u);

    if (Box(p, float2(0.86f, 0.060f), float2(0.97f, 0.082f)) > 0.5f)
        col = hover == 220u ? float4(0.17f, 0.06f, 0.06f, 1.0f) : float4(0.075f, 0.040f, 0.045f, 1.0f);

    return col;
}
#endif
