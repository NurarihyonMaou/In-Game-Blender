// MeshEditorRebuildWritablePosition.hlsl
// Rebuilds base/object-space writable positions from the base VB and persistent
// sculpt deltas. Used between replayed strokes so later weight-paint strokes see
// the geometry produced by earlier sculpt strokes.

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
Buffer<float4> VertexDelta : register(t1);
RWStructuredBuffer<PosBuf> WritablePosition : register(u0);

#define VERTEX_COUNT 79355u

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    PosBuf vertex = BasePositionBuffer[vertexID];
    vertex.pos += VertexDelta[vertexID].xyz;
    WritablePosition[vertexID] = vertex;
}
