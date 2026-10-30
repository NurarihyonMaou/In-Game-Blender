// MeshEditorRotateSelected.hlsl
// Non-cumulative rotation of the multi-selected vertices around a saved object-space pivot.
// VertexDelta is a BASE/OBJECT-space delta; rotation is applied to the edited position
// (BasePosition + BaselineDelta) and converted back into a delta from BasePosition.
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
#define ROTATE_PIVOT IniParams[50].xyz
#define ROTATE_ANGLE IniParams[51].x
#define ROTATE_AXIS ((int)round(IniParams[51].y))

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    float4 result = BaselineDelta[vertexID];
    if (SelectedRefCount[vertexID] > 0u)
    {
        float3 basePos = BasePosition[vertexID].pos;
        float3 editedPos = basePos + result.xyz;
        float3 p = editedPos - ROTATE_PIVOT;
        float s = sin(ROTATE_ANGLE);
        float c = cos(ROTATE_ANGLE);
        float3 rotated = p;

        if (ROTATE_AXIS == 0)
        {
            rotated.y = p.y * c - p.z * s;
            rotated.z = p.y * s + p.z * c;
        }
        else if (ROTATE_AXIS == 1)
        {
            rotated.x = p.x * c + p.z * s;
            rotated.z = -p.x * s + p.z * c;
        }
        else
        {
            rotated.x = p.x * c - p.y * s;
            rotated.y = p.x * s + p.y * c;
        }

        result.xyz = (ROTATE_PIVOT + rotated) - basePos;
    }

    VertexDelta[vertexID] = result;
}
