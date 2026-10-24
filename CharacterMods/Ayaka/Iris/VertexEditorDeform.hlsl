// VertexEditorDeform.hlsl
//
// BasePosition -> persistent VertexDelta -> transient drag -> WritablePosition
//
// Base vertex layout:
//     float3 position
//     float3 normal
//     float4 tangent
//
// stride = 40 bytes

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePosition : register(t0);
Buffer<float4>           EditorState  : register(t1);
Buffer<float>            VertexDelta  : register(t2);

RWStructuredBuffer<PosBuf> WritablePosition : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    uint vertexCount;
    uint vertexStride;

    WritablePosition.GetDimensions(
        vertexCount,
        vertexStride);

    if (vertexID >= vertexCount)
        return;

    // Always start from the original/base vertex.
    PosBuf v = BasePosition[vertexID];

    // ------------------------------------------------------------
    // PERSISTENT EDIT
    // ------------------------------------------------------------

    uint deltaBase = vertexID * 3u;

    float3 persistentDelta = float3(
        VertexDelta[deltaBase + 0u],
        VertexDelta[deltaBase + 1u],
        VertexDelta[deltaBase + 2u]
    );

    v.pos += persistentDelta;

    // ------------------------------------------------------------
    // CURRENT DRAG PREVIEW
    // ------------------------------------------------------------

    float4 selection = EditorState[0];
    float4 dragState = EditorState[2];

    bool selectionValid = selection.y > 0.5;
    bool dragActive = dragState.w > 0.5;

    uint selectedVertex =
        (uint)(selection.x + 0.5);

    if (selectionValid &&
        dragActive &&
        vertexID == selectedVertex)
    {
        v.pos += dragState.xyz;
    }

    WritablePosition[vertexID] = v;
}