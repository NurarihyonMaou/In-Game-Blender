// ============================================================================
// MeshEditorSmoothAccumulate.hlsl
// ============================================================================

#define VERTEX_COUNT 79355u

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
Buffer<float4> VertexDelta : register(t1);
Buffer<uint> IndexBuffer : register(t2);

RWBuffer<uint> Accum : register(u0);

#define POSITION_SCALE 1000000.0f

uint Quantize(float value)
{
    return (uint)(int)round(value * POSITION_SCALE);
}

void AddNeighbor(uint vertexID, uint neighborID)
{
    if (vertexID >= VERTEX_COUNT || neighborID >= VERTEX_COUNT)
        return;

    float3 delta = VertexDelta[neighborID].xyz;

    uint original;

    InterlockedAdd(Accum[vertexID * 4u + 0u], Quantize(delta.x), original);
    InterlockedAdd(Accum[vertexID * 4u + 1u], Quantize(delta.y), original);
    InterlockedAdd(Accum[vertexID * 4u + 2u], Quantize(delta.z), original);
    InterlockedAdd(Accum[vertexID * 4u + 3u], 1u, original);
}

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint triangleID = id.x;

    //if (triangleID >= 6574u)
    //    return;

    uint indexBase = triangleID * 3u;

    uint i0 = IndexBuffer[indexBase + 0u];
    uint i1 = IndexBuffer[indexBase + 1u];
    uint i2 = IndexBuffer[indexBase + 2u];

    AddNeighbor(i0, i0);
    AddNeighbor(i0, i1);
    AddNeighbor(i0, i2);
    
    AddNeighbor(i1, i1);
    AddNeighbor(i1, i0);
    AddNeighbor(i1, i2);
    
    AddNeighbor(i2, i2);
    AddNeighbor(i2, i0);
    AddNeighbor(i2, i1);
}