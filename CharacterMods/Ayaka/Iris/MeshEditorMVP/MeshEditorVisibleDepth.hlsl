// MeshEditorVisibleDepth.hlsl
//
// Cursor-centred visible-depth pass for the Ayaka mesh editor.
//
// The game's native VS is intentionally kept active. Its clip-space
// SV_Position is remapped in GS so that a 64x64 render target represents a
// 64x64-pixel window around the mouse cursor. Z/W are preserved, so raster
// depth testing uses the original projected depth.
//
// The PS stores its interpolated depth in .x and a valid-fragment marker in .y.

#define VISIBLE_DEPTH_WIDTH  64.0f
#define VISIBLE_DEPTH_HEIGHT 64.0f
#define VISIBLE_DEPTH_HALF   32.0f

Texture1D<float4> IniParams : register(t120);

// INI binds y31 = window_height - cursor_window_y (bottom-origin Y).
// This shader converts that value back to top-left coordinates for projection.
// IniParams[31].zw = window/render width and height
#define CURSOR IniParams[31]

struct VS_OUT
{
    float4 pos : SV_Position;
};

struct GS_OUT
{
    float4 pos : SV_Position;
};

float4 RemapToCursorPatch(float4 clipPos)
{
    float2 screenSize = max(CURSOR.zw, float2(1.0f, 1.0f));
    float2 cursor = float2(CURSOR.x, screenSize.y - CURSOR.y);

    // Avoid division by zero for vertices on/behind the eye plane.
    if (abs(clipPos.w) <= 1e-7f)
    {
        clipPos.xy = float2(1e6f, 1e6f);
        return clipPos;
    }

    // Match ClipToScreen() in MeshEditorPick.hlsl (top-left screen origin).
    float2 ndc = clipPos.xy / clipPos.w;
    float2 screen;
    screen.x = ndc.x * 0.5f * screenSize.x + 0.5f * screenSize.x;
    screen.y = 0.5f * screenSize.y - ndc.y * 0.5f * screenSize.y;

    // Shift the mouse neighbourhood to the centre of the small RT.
    float2 patchPixel = screen - cursor + float2(VISIBLE_DEPTH_HALF, VISIBLE_DEPTH_HALF);
    float2 patchNdc;
    patchNdc.x = patchPixel.x / VISIBLE_DEPTH_WIDTH * 2.0f - 1.0f;
    patchNdc.y = 1.0f - patchPixel.y / VISIBLE_DEPTH_HEIGHT * 2.0f;

    // Preserve z and w: only XY is remapped, so depth remains comparable with
    // the software picker's clip.z / clip.w values.
    clipPos.xy = patchNdc * clipPos.w;
    return clipPos;
}

#ifdef GEOMETRY_SHADER

[maxvertexcount(3)]
void main(triangle VS_OUT input[3], inout TriangleStream<GS_OUT> stream)
{
    GS_OUT output;

    [unroll]
    for (uint i = 0u; i < 3u; ++i)
    {
        output.pos = RemapToCursorPatch(input[i].pos);
        stream.Append(output);
    }

    stream.RestartStrip();
}

#endif

#ifdef PIXEL_SHADER

float4 main(GS_OUT input) : SV_Target0
{
    // SV_Position.z in the PS is the rasterized depth after perspective divide.
    // .y is a valid-fragment marker; depth itself can legally be zero.
    return float4(input.pos.z, 1.0f, 0.0f, 1.0f);
}

#endif
