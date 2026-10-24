// ============================================================================
// MeshEditorOverlay.hlsl
//
// Visualize:
//   1. Selected vertex
//   2. Proportional falloff radius
//
// Inputs:
//   t0 = MeshEditorCapture
//   t1 = MeshEditorState
//
// EditorState:
//   [0].x = selected vertex ID
//   [0].y = selection valid
//   [0].w = drag active
//
//   [1].xy = drag start cursor
//
//   [2].xyz = screen-right local basis
//   [2].w   = basis valid
//
//   [3].xyz = screen-down local basis
//   [3].w   = conditioning
//
//   [6].x = proportional radius in local/skinned units
// ============================================================================

Texture2D<float4> VertexScreen : register(t0);

Buffer<float4> EditorState : register(t1);

Texture1D<float4> IniParams : register(t120);

#define CURSOR IniParams[31]

#define CAPTURE_WIDTH  512u
#define CAPTURE_HEIGHT 256u
#define VERTEX_COUNT 79355u

// -----------------------------------------------------------------------------
// Visual tuning
// -----------------------------------------------------------------------------

#define MARKER_RADIUS_PX       4.0f
#define MARKER_RING_WIDTH_PX   1.5f

#define CROSS_HALF_PX          8.0f
#define CROSS_WIDTH_PX         1.5f

#define FALLOFF_RING_WIDTH_PX  2.0f

#define MAX_RADIUS_PX          2000.0f


// ============================================================================
// Fullscreen quad
// ============================================================================

struct VS_OUT
{
    float4 pos : SV_Position0;
};

#ifdef VERTEX_SHADER

void main(
    out VS_OUT output,
    uint vertexID : SV_VertexID)
{
    if (vertexID == 0u)
        output.pos = float4(-1.0f, -1.0f, 0.0f, 1.0f);
    else if (vertexID == 1u)
        output.pos = float4(-1.0f,  1.0f, 0.0f, 1.0f);
    else if (vertexID == 2u)
        output.pos = float4( 1.0f, -1.0f, 0.0f, 1.0f);
    else
        output.pos = float4( 1.0f,  1.0f, 0.0f, 1.0f);
}

#endif


// ============================================================================
// Helpers
// ============================================================================

uint2 VertexTexel(uint vertexID)
{
    return uint2(
        vertexID % CAPTURE_WIDTH,
        vertexID / CAPTURE_WIDTH);
}

float4 LoadVertexClip(uint vertexID)
{
    if (vertexID >= VERTEX_COUNT)
        return 0.0f;

    uint2 p =
        VertexTexel(vertexID);

    if (p.y >= CAPTURE_HEIGHT)
        return 0.0f;

    return VertexScreen.Load(
        int3(p, 0));
}

float2 ClipToScreen(
    float4 clip,
    float2 screenSize,
    out bool valid)
{
    valid = false;

    if (clip.w <= 1e-7f)
        return 0.0f;

    float2 ndc =
        clip.xy / clip.w;

    if (any(abs(ndc) > float2(4.0f, 4.0f)))
        return 0.0f;

    float2 screen;

    screen.x =
        ndc.x * 0.5f * screenSize.x +
        0.5f * screenSize.x;

    screen.y =
        0.5f * screenSize.y -
        ndc.y * 0.5f * screenSize.y;

    valid = true;

    return screen;
}


// ============================================================================
// Pixel Shader
// ============================================================================

#ifdef PIXEL_SHADER

void main(
    float4 position : SV_Position0,
    out float4 result : SV_Target0)
{
    result = 0.0f;

    float4 state0 =
        EditorState[0];

    bool selectedValid =
        state0.y > 0.5f;

    if (!selectedValid)
        discard;

    float2 screenSize =
        max(
            CURSOR.zw,
            float2(1.0f, 1.0f));

    uint selectedVertex =
        (uint)max(
            state0.x + 0.5f,
            0.0f);

    if (selectedVertex >= VERTEX_COUNT)
        discard;


    // =========================================================================
    // SELECTED VERTEX POSITION
    // =========================================================================

    float2 selectedScreen;

    bool dragging =
        state0.w > 0.5f;

    if (dragging)
    {
        // During drag the selected vertex visually follows the cursor.
        selectedScreen =
            CURSOR.xy;
    }
    else
    {
        float4 clip =
            LoadVertexClip(
                selectedVertex);

        bool validClip;

        selectedScreen =
            ClipToScreen(
                clip,
                screenSize,
                validClip);

        if (!validClip)
            discard;
    }


    // =========================================================================
    // DISTANCE FROM SELECTED VERTEX
    // =========================================================================

    float2 delta =
        position.xy -
        selectedScreen;

    float distancePx =
        length(delta);


    // =========================================================================
    // SELECTED VERTEX MARKER
    // =========================================================================

    float markerRing =
        1.0f -
        smoothstep(
            MARKER_RADIUS_PX,
            MARKER_RADIUS_PX + MARKER_RING_WIDTH_PX,
            distancePx);

    float markerDot =
        1.0f -
        smoothstep(
            2.0f,
            3.5f,
            distancePx);


    // Crosshair
    float crossHorizontal =
        (
            abs(delta.y) <= CROSS_WIDTH_PX &&
            abs(delta.x) <= CROSS_HALF_PX
        )
        ? 1.0f
        : 0.0f;

    float crossVertical =
        (
            abs(delta.x) <= CROSS_WIDTH_PX &&
            abs(delta.y) <= CROSS_HALF_PX
        )
        ? 1.0f
        : 0.0f;

    float marker =
        max(
            markerRing,
            max(
                markerDot,
                max(
                    crossHorizontal,
                    crossVertical)));


    // =========================================================================
    // FALL0FF RADIUS
    //
    // Actual falloff is:
    //
    //     length(vertexPos - selectedPos) <= radius
    //
    // State [2]/[3] contain local units per screen pixel.
    //
    // So:
    //
    //     radiusPxX = radius / unitsPerPixelX
    //     radiusPxY = radius / unitsPerPixelY
    //
    // This gives us the projected footprint of the radius.
    // =========================================================================

    float radius =
        max(
            EditorState[6].x,
            0.0f);

    float radiusPxX = 0.0f;
    float radiusPxY = 0.0f;

    bool basisValid =
        EditorState[2].w > 0.5f &&
        EditorState[3].w > 0.0f;

    if (
        basisValid &&
        radius > 0.0f)
    {
        float unitsPerPixelX =
            max(
                length(
                    EditorState[2].xyz),
                1e-6f);

        float unitsPerPixelY =
            max(
                length(
                    EditorState[3].xyz),
                1e-6f);

        radiusPxX =
            radius /
            unitsPerPixelX;

        radiusPxY =
            radius /
            unitsPerPixelY;

        radiusPxX =
            min(
                radiusPxX,
                MAX_RADIUS_PX);

        radiusPxY =
            min(
                radiusPxY,
                MAX_RADIUS_PX);
    }


    // =========================================================================
    // FALL0FF RING
    // =========================================================================

    float falloffRing =
        0.0f;

    if (
        radiusPxX > 0.0f &&
        radiusPxY > 0.0f)
    {
        float2 ellipse =
            delta /
            float2(
                radiusPxX,
                radiusPxY);

        float ellipseDistance =
            length(ellipse);

        float ringDistance =
            abs(
                ellipseDistance -
                1.0f);

        float ringWidth =
            FALLOFF_RING_WIDTH_PX /
            max(
                min(
                    radiusPxX,
                    radiusPxY),
                1.0f);

        falloffRing =
            1.0f -
            smoothstep(
                ringWidth,
                ringWidth + 0.01f,
                ringDistance);
    }


    // =========================================================================
    // COMPOSITE
    // =========================================================================

    // Selected vertex = cyan
    float3 markerColor =
        float3(
            0.0f,
            1.0f,
            1.0f);

    // Falloff = yellow
    float3 falloffColor =
        float3(
            1.0f,
            0.8f,
            0.0f);

    if (marker > 0.0f)
    {
        result =
            float4(
                markerColor,
                1.0f);
    }
    else if (falloffRing > 0.0f)
    {
        result =
            float4(
                falloffColor,
                1.0f);
    }
    else
    {
        discard;
    }
}

#endif