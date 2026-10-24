// VertexEditorSelect.hlsl
//
// Selects one vertex from the current HoverResult and maintains the
// persistent editor interaction state.
//
// HoverResult layout used here:
//
//   [1]  vertex 0 ID
//   [2]  vertex 1 ID
//   [3]  vertex 2 ID
//   [16] hover valid
//   [17] bary.x
//   [18] bary.y
//   [19] bary.z
//
// EditorState:
//
//   [0].x = selected vertex ID
//   [0].y = selection valid
//   [0].z = previous mouse-held state
//   [0].w = initialized
//
//   [1].x = capture cursor X
//   [1].y = capture cursor Y
//
//   [2].xyz = current transient drag offset
//   [2].w   = drag active
//
//   [3].xyz = last committed delta (debug only)
//   [3].w   = reserved
//
// VertexDelta:
//   3 * vertexID + 0 = X
//   3 * vertexID + 1 = Y
//   3 * vertexID + 2 = Z
//
// NOTE:
//   This MVP deliberately uses fixed VB0 local X/Y axes.
//   Once this works, replace these two axes with the screen-right/
//   screen-down basis from rzm_object_detect.hlsl.

Buffer<float> HoverResult : register(t0);

RWBuffer<float4> EditorState : register(u0);
RWBuffer<float>  VertexDelta : register(u1);

Texture1D<float4> IniParams : register(t120);

// Existing user input contract.
#define CURSOR_PARAMS IniParams[31]
#define HOLD_PARAM    IniParams[32]

// Fresh controls for this MVP.
//
// [90].x = local movement scale
// [90].y = X direction
// [90].z = Y direction
#define EDIT_PARAMS IniParams[90]

float SafeNonZero(float v, float fallback)
{
    return abs(v) > 1e-8 ? v : fallback;
}

float SafePositive(float v, float fallback)
{
    return v > 0.0 ? v : fallback;
}

float3 ComputeDragOffset(float2 currentCursor, float2 captureCursor)
{
    float screenW = SafePositive(CURSOR_PARAMS.z, 1920.0);
    float screenH = SafePositive(CURSOR_PARAMS.w, 1080.0);

    // Same normalization concept as the working Rayvich interaction:
    // use the smaller screen dimension as the reference.
    float screenReference = max(min(screenW, screenH), 1.0);

    float2 deltaPx =
        currentCursor - captureCursor;

    float2 delta =
        deltaPx / screenReference;

    float scale = SafePositive(EDIT_PARAMS.x, 1.0);
    float xSign = SafeNonZero(EDIT_PARAMS.y, 1.0);
    float ySign = SafeNonZero(EDIT_PARAMS.z, 1.0);

    delta.x *= scale * xSign;
    delta.y *= scale * ySign;

    // MVP:
    //
    // screen +X -> local +X
    // screen +Y -> local +Y
    //
    // Change the signs in IniParams if this is reversed for the mesh.
    return float3(delta.x, delta.y, 0.0);
}

uint SelectVertexFromHover()
{
    float v0 = HoverResult[1];
    float v1 = HoverResult[2];
    float v2 = HoverResult[3];

    float w0 = HoverResult[17];
    float w1 = HoverResult[18];
    float w2 = HoverResult[19];

    if (w0 >= w1 && w0 >= w2)
        return (uint)(v0 + 0.5);

    if (w1 >= w0 && w1 >= w2)
        return (uint)(v1 + 0.5);

    return (uint)(v2 + 0.5);
}

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    float4 state0 = EditorState[0];
    float4 state1 = EditorState[1];
    float4 state2 = EditorState[2];

    float hold = HOLD_PARAM.x;
    bool mouseHeld = hold > 0.5;

    float previousHold = state0.z;
    bool pressed = mouseHeld && previousHold <= 0.5;
    bool released = !mouseHeld && previousHold > 0.5;

    bool hoverValid = HoverResult[16] > 0.5;

    float selectedVertex = state0.x;
    bool selectionValid = state0.y > 0.5;

    float2 captureCursor = state1.xy;

    float3 currentOffset = state2.xyz;

    // ------------------------------------------------------------
    // FIRST INITIALIZATION
    // ------------------------------------------------------------

    if (state0.w < 0.5)
    {
        state0 = float4(
            -1.0,
            0.0,
            hold,
            1.0
        );

        state1 = 0.0;
        state2 = 0.0;

        selectedVertex = -1.0;
        selectionValid = false;
        currentOffset = 0.0;
    }

    // ------------------------------------------------------------
    // NEW CLICK
    // ------------------------------------------------------------

    if (pressed)
    {
        if (hoverValid)
        {
            uint newVertex = SelectVertexFromHover();

            selectedVertex = (float)newVertex;
            selectionValid = true;

            captureCursor = CURSOR_PARAMS.xy;

            currentOffset = 0.0;
        }
        else
        {
            // Clicking empty space does not destroy the previous selection.
            currentOffset = 0.0;
        }
    }

    // ------------------------------------------------------------
    // LIVE DRAG
    // ------------------------------------------------------------

    if (mouseHeld && selectionValid)
    {
        currentOffset =
            ComputeDragOffset(
                CURSOR_PARAMS.xy,
                captureCursor);
    }

    // ------------------------------------------------------------
    // RELEASE -> COMMIT
    // ------------------------------------------------------------

    if (released && selectionValid)
    {
        uint vertexID = (uint)(selectedVertex + 0.5);

        uint base = vertexID * 3u;

        VertexDelta[base + 0u] += currentOffset.x;
        VertexDelta[base + 1u] += currentOffset.y;
        VertexDelta[base + 2u] += currentOffset.z;

        EditorState[3] =
            float4(currentOffset, 1.0);

        currentOffset = 0.0;
    }

    // ------------------------------------------------------------
    // WRITE STATE
    // ------------------------------------------------------------

    EditorState[0] = float4(
        selectedVertex,
        selectionValid ? 1.0 : 0.0,
        hold,
        1.0
    );

    EditorState[1] = float4(
        captureCursor,
        0.0,
        0.0
    );

    EditorState[2] = float4(
        currentOffset,
        (mouseHeld && selectionValid) ? 1.0 : 0.0
    );
}