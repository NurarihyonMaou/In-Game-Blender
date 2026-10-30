// MeshEditorScaleSelected.hlsl
// Applies non-cumulative S previews/commits in BASE/OBJECT space.
// The operation scales absolute edited positions around a stored pivot, then
// converts the result back into VertexDelta. Unselected vertices remain unchanged.
struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePosition : register(t0);
Buffer<float4> BaselineDelta : register(t1);
Buffer<uint> SelectedRefCount : register(t2);
RWBuffer<float4> VertexDelta : register(u0);
Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355u
#define SCALE_PIVOT IniParams[50].xyz
#define SCALE_FACTORS IniParams[51].xyz

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    float4 baseline = BaselineDelta[vertexID];
    if (SelectedRefCount[vertexID] > 0u)
    {
        float3 basePos = BasePosition[vertexID].pos;
        float3 editedPos = basePos + baseline.xyz;
        float3 scaledPos = SCALE_PIVOT + (editedPos - SCALE_PIVOT) * SCALE_FACTORS;
        baseline.xyz = scaledPos - basePos;
    }
    VertexDelta[vertexID] = baseline;
}
