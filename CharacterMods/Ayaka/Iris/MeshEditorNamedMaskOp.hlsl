// MeshEditorNamedMaskOp.hlsl
// x37 = slot, y37 = operation, z37 = active slot.
// operation 0: load the selected named slot into ResourceMeshEditorMask.
// operation 1: clear the selected named slot (and the active cache if it is that slot).
// operation 2: copy ResourceMeshEditorMask into the selected named slot.

RWBuffer<float> NamedMasks : register(u0);
RWBuffer<float> ActiveMask : register(u1);
Texture1D<float4> IniParams : register(t120);

#define SLOT_PARAM       IniParams[37].x
#define OPERATION_PARAM  IniParams[37].y
#define ACTIVE_SLOT_PARAM IniParams[37].z

#define VERTEX_COUNT    79355u
#define MASK_SLOT_COUNT 8u

uint ClampSlot(float value)
{
    return (uint)clamp((int)(value + 0.5f), 0, (int)MASK_SLOT_COUNT - 1);
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    uint slot = ClampSlot(SLOT_PARAM);
    uint activeSlot = ClampSlot(ACTIVE_SLOT_PARAM);
    int operation = (int)(OPERATION_PARAM + 0.5f);
    uint namedIndex = slot * VERTEX_COUNT + vertexID;

    if (operation == 0)
    {
        ActiveMask[vertexID] = NamedMasks[namedIndex];
    }
    else if (operation == 1)
    {
        NamedMasks[namedIndex] = 0.0f;
        if (activeSlot == slot)
            ActiveMask[vertexID] = 0.0f;
    }
    else if (operation == 2)
    {
        NamedMasks[namedIndex] = saturate(ActiveMask[vertexID]);
    }
}
