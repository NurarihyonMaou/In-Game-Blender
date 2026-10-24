Buffer<uint> CombinedIB : register(t0);
Buffer<float> NamedMasks : register(t1);

RWBuffer<uint> SmoothAccum : register(u0);

Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355
#define INDEX_COUNT 240852
#define MASK_SCALE 65535.0f

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint triangleID = tid.x;

    if (triangleID >= INDEX_COUNT / 3)
        return;

    uint i = triangleID * 3;

    uint a = CombinedIB[i + 0];
    uint b = CombinedIB[i + 1];
    uint c = CombinedIB[i + 2];

    if (a >= VERTEX_COUNT ||
        b >= VERTEX_COUNT ||
        c >= VERTEX_COUNT)
        return;

    uint slot = (uint)clamp(
        round(IniParams[37].x),
        0.0f,
        7.0f
    );

    uint baseIndex = slot * VERTEX_COUNT;

    float ma = saturate(NamedMasks[baseIndex + a]);
    float mb = saturate(NamedMasks[baseIndex + b]);
    float mc = saturate(NamedMasks[baseIndex + c]);

    uint sumA =
        (uint)round(mb * MASK_SCALE) +
        (uint)round(mc * MASK_SCALE);

    uint sumB =
        (uint)round(ma * MASK_SCALE) +
        (uint)round(mc * MASK_SCALE);

    uint sumC =
        (uint)round(ma * MASK_SCALE) +
        (uint)round(mb * MASK_SCALE);

    InterlockedAdd(SmoothAccum[a * 4 + 0], sumA);
    InterlockedAdd(SmoothAccum[a * 4 + 1], 2u);

    InterlockedAdd(SmoothAccum[b * 4 + 0], sumB);
    InterlockedAdd(SmoothAccum[b * 4 + 1], 2u);

    InterlockedAdd(SmoothAccum[c * 4 + 0], sumC);
    InterlockedAdd(SmoothAccum[c * 4 + 1], 2u);
}