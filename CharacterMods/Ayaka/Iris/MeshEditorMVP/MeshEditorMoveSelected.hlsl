// Applies one non-cumulative Move preview/commit to the currently selected
// vertices. All values are in BASE/OBJECT space, matching VertexDelta.
// The baseline is captured once at G start (live preview) or immediately before
// replay (Undo/Redo), so mouse movement never compounds the previous preview.

Buffer<float4> BaselineDelta : register(t0);
Buffer<uint> SelectedRefCount : register(t1);
RWBuffer<float4> VertexDelta : register(u0);
Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355u
#define MOVE_DELTA IniParams[50].xyz

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    float4 result = BaselineDelta[vertexID];
    if (SelectedRefCount[vertexID] > 0u)
        result.xyz += MOVE_DELTA;

    VertexDelta[vertexID] = result;
}
