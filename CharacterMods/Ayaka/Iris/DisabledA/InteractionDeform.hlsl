// DeformSelectedVertex.hlsl

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePosition : register(t0);
StructuredBuffer<float>  Selection     : register(t1);
StructuredBuffer<float>  Interaction   : register(t2);

RWStructuredBuffer<PosBuf> Position : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    uint vertexCount;
    uint stride;
    Position.GetDimensions(vertexCount, stride);

    if (vertexID >= vertexCount)
        return;

    PosBuf v = BasePosition[vertexID];

    float selectedVertex = Selection[0];
    float selectedValid  = Selection[2];

    float3 offset = float3(
        Interaction[0],
        Interaction[1],
        Interaction[2]
    );

    if (selectedValid > 0.5f &&
        abs((float)vertexID - selectedVertex) < 0.5f)
    {
        v.pos += offset;
    }

    Position[vertexID] = v;
}