// Copies a dab centre / Grab delta from MeshEditorState to GPU history.
// x31 = destination dab index; y31 = source float4 index (15 sculpt / 17 mask+weight).
Buffer<float4> EditorState : register(t0);
RWBuffer<float4> DabHistory : register(u0);
Texture1D<float4> IniParams : register(t120);
#define DAB_INDEX IniParams[31].x
#define STATE_INDEX IniParams[31].y
#define DAB_CAPACITY 131072u
#define STATE_CAPACITY 32u

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint dabIndex = (uint)max(DAB_INDEX, 0.0f);
    uint stateIndex = (uint)max(STATE_INDEX, 0.0f);
    if (dabIndex >= DAB_CAPACITY || stateIndex >= STATE_CAPACITY)
        return;
    DabHistory[dabIndex] = EditorState[stateIndex];
}
