// MeshEditorScalePivot.hlsl
// Calculates the centroid (median of the selected vertices) in base/object space.
// Runs once when S starts. SelectionRefCount is treated as a boolean so a vertex
// shared by several selected faces/edges contributes only once.
struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePosition : register(t0);
Buffer<float4> BaselineDelta : register(t1);
Buffer<uint> SelectedRefCount : register(t2);
RWBuffer<float4> ScalePivot : register(u0);

#define VERTEX_COUNT 79355u

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    float3 sum = 0.0f;
    uint count = 0u;

    [loop]
    for (uint vertexID = 0u; vertexID < VERTEX_COUNT; ++vertexID)
    {
        if (SelectedRefCount[vertexID] > 0u)
        {
            sum += BasePosition[vertexID].pos + BaselineDelta[vertexID].xyz;
            count++;
        }
    }

    float3 pivot = (count > 0u) ? (sum / (float)count) : float3(0.0f, 0.0f, 0.0f);
    ScalePivot[0] = float4(pivot, 1.0f);
}
