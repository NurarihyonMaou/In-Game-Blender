// MeshEditorCombineMasks.hlsl
// Builds the combined protective mask from the eight named masks.
// Mask storage is slot-major: NamedMasks[slot * VERTEX_COUNT + vertexID].
// The editable ResourceMeshEditorMask cache is never modified by this shader.

Buffer<float> NamedMasks : register(t0);
RWBuffer<float> CombinedMask : register(u0);
Texture1D<float4> IniParams : register(t120);

#define ACTIVE_MASK_FLAGS IniParams[38].x
#define VERTEX_COUNT     79355u
#define MASK_SLOT_COUNT  8u

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    int activeFlags = (int)(ACTIVE_MASK_FLAGS + 0.5f);
    float protection = 0.0f;

    [unroll]
    for (uint slot = 0u; slot < MASK_SLOT_COUNT; ++slot)
    {
        int slotBit = (1 << slot);
        if ((activeFlags & slotBit) != 0)
        {
            uint index = slot * VERTEX_COUNT + vertexID;
            protection = max(protection, saturate(NamedMasks[index]));
        }
    }

    CombinedMask[vertexID] = protection;
}
