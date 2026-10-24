Buffer<uint> SmoothAccum : register(t0);

RWBuffer<float> NamedMasks : register(u0);
RWBuffer<float> ActiveMask : register(u1);

Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355
#define MASK_SCALE 65535.0f

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint vertex = tid.x;

    if (vertex >= VERTEX_COUNT)
        return;

    uint slot = (uint)clamp(
        round(IniParams[37].x),
        0.0f,
        7.0f
    );

    uint operation = (uint)round(IniParams[37].y);
    uint activeSlot = (uint)round(IniParams[37].w);

    float strength = saturate(IniParams[37].z);

    uint index = slot * VERTEX_COUNT + vertex;

    float value = saturate(NamedMasks[index]);

    uint sum = SmoothAccum[vertex * 4 + 0];
    uint count = SmoothAccum[vertex * 4 + 1];

    if (count > 0)
    {
        float average = saturate(
            (float)sum / (MASK_SCALE * (float)count)
        );

        if (operation == 5) // SMOOTH
        {
            value = lerp(value, average, strength);
        }
        else if (operation == 6) // SHARPEN
        {
            value = saturate(
                value + (value - average) * strength
            );
        }
    }

    NamedMasks[index] = value;

    if (slot == activeSlot)
        ActiveMask[vertex] = value;
}