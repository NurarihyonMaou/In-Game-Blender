struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

RWStructuredBuffer<PosBuf> Position : register(u0);

Buffer<float> HoverResult : register(t2);

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    if (vertexID >= 79355)
        return;

    uint selectedVertex = (uint)HoverResult[1];

    if (vertexID != selectedVertex)
        return;

    PosBuf vertex = Position[selectedVertex];

    vertex.pos.y += 200;

    Position[vertexID] = vertex;
}