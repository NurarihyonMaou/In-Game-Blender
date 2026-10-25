// Captures the currently selected vertex-group weight from the editable Blend.
// The snapshot is taken before each Smooth dab, preventing UAV read/write races.
// t0: EditableBlend (structured buffer, stride 32)
// u0: ResourceMeshEditorWeightSmoothWeights (R32_FLOAT, one entry per vertex)
// IniParams[40].x: selected vertex-group ID

struct BlendBuf
{
    float4 blendWeights;
    int4 blendIndices;
};

StructuredBuffer<BlendBuf> EditableBlend : register(t0);
RWBuffer<float> WeightSnapshot : register(u0);
Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355u

int GetInt4Component(int4 value, uint index)
{
    if (index == 0u) return value.x;
    if (index == 1u) return value.y;
    if (index == 2u) return value.z;
    return value.w;
}

float GetFloat4Component(float4 value, uint index)
{
    if (index == 0u) return value.x;
    if (index == 1u) return value.y;
    if (index == 2u) return value.z;
    return value.w;
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    uint selectedVG = (uint)clamp((int)(IniParams[40].x + 0.5f), 0, 117);
    BlendBuf blend = EditableBlend[vertexID];
    float selectedWeight = 0.0f;

    [unroll]
    for (uint slot = 0u; slot < 4u; ++slot)
    {
        if (GetInt4Component(blend.blendIndices, slot) == (int)selectedVG)
            selectedWeight = max(selectedWeight, GetFloat4Component(blend.blendWeights, slot));
    }

    WeightSnapshot[vertexID] = saturate(selectedWeight);
}
