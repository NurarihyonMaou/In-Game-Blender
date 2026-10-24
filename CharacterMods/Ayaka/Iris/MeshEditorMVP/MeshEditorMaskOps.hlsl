RWBuffer<float> NamedMasks : register(u0);
RWBuffer<float> ActiveMask : register(u1);

Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355
#define MASK_SLOT_COUNT 8

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint vertex = tid.x;

    if (vertex >= VERTEX_COUNT)
        return;

    uint slot = (uint)clamp(
        round(IniParams[37].x),
        0.0f,
        (float)(MASK_SLOT_COUNT - 1)
    );

    uint operation = (uint)round(IniParams[37].y);
    uint activeSlot = (uint)round(IniParams[37].w);

    float parameter = IniParams[37].z;

    uint index = slot * VERTEX_COUNT + vertex;

    float value = saturate(NamedMasks[index]);

    switch (operation)
    {
        case 0: // CLEAR
            value = 0.0f;
            break;

        case 1: // FILL
            value = 1.0f;
            break;

        case 2: // INVERT
            value = 1.0f - value;
            break;

        case 3: // THRESHOLD
            value = value >= parameter ? 1.0f : 0.0f;
            break;

        case 4: // CONTRAST
            value = saturate(
                (value - 0.5f) * parameter + 0.5f
            );
            break;

        default:
            return;
    }

    NamedMasks[index] = value;

    // Only update the working mask when operating on
    // the currently selected slot.
    if (slot == activeSlot)
        ActiveMask[vertex] = value;
}