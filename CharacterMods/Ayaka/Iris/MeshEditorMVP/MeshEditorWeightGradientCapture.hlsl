// Capture Gradient stroke endpoints in the SAME position space used by
// MeshEditorWeightPaint.hlsl. HoverResult[1]/EditorState[11] is the picker's
// interpolated hit point from the rendered capture VB, which can be posed/skinned.
// Weight Paint evaluates vertices from ResourceWritablePosition, so using the hit
// point directly can put the whole gradient segment in a different space and make
// its falloff miss every vertex. Reconstruct the hit from triangle+barycentrics on
// ResourceWritablePosition, exactly like GetLiveBrushCenter() in WeightPaint.

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> PositionBuffer : register(t0);
RWBuffer<float4> EditorState : register(u0);
RWBuffer<float4> GradientState : register(u1); // [0] = first point, [1] = latest point

#define STATE_BRUSH_TRI    9u
#define STATE_BRUSH_BARY   10u
#define STATE_BRUSH_POS    11u
#define STATE_BRUSH_CENTER 17u
#define VERTEX_COUNT 79355u

[numthreads(1, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    float4 hit = EditorState[STATE_BRUSH_POS];
    float4 tri = EditorState[STATE_BRUSH_TRI];
    float3 bary = EditorState[STATE_BRUSH_BARY].xyz;

    bool valid = hit.w > 0.5f
        && tri.x >= 0.0f && tri.y >= 0.0f && tri.z >= 0.0f
        && tri.x < (float)VERTEX_COUNT
        && tri.y < (float)VERTEX_COUNT
        && tri.z < (float)VERTEX_COUNT;

    if (valid)
    {
        uint i0 = (uint)(tri.x + 0.5f);
        uint i1 = (uint)(tri.y + 0.5f);
        uint i2 = (uint)(tri.z + 0.5f);

        // Match the weight painter's base/object-space vertex positions.
        float3 p0 = PositionBuffer[i0].pos;
        float3 p1 = PositionBuffer[i1].pos;
        float3 p2 = PositionBuffer[i2].pos;
        float3 p = p0 * bary.x + p1 * bary.y + p2 * bary.z;

        float4 start = GradientState[0];
        if (start.w <= 0.5f)
            start = float4(p, 1.0f);

        GradientState[0] = start;
        GradientState[1] = float4(p, 1.0f);

        // CommandListMeshEditorRecordWeightDab stores this centre in the
        // persistent stroke pool every held frame. It now uses WeightPaint space.
        EditorState[STATE_BRUSH_CENTER] = float4(p, 1.0f);
    }
    else
    {
        EditorState[STATE_BRUSH_CENTER] = 0.0f;
    }
}
