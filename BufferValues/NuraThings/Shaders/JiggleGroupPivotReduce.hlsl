// JiggleGroupPivotReduce.hlsl

Buffer<float4> PartialSums : register(t0);
RWBuffer<float4> GroupCenters : register(u0);
RWBuffer<float4> Debug : register(u1);

#define MASK_SLOT_COUNT 8u
#define CHUNK_COUNT 1240u
#define VERTEX_COUNT 79355u

[numthreads(8, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint slot = dispatchThreadID.x;

    if (slot >= MASK_SLOT_COUNT)
        return;

    float4 sum = 0.0f;

    [loop]
    for (uint chunk = 0u; chunk < CHUNK_COUNT; ++chunk)
    {
        sum += PartialSums[slot * CHUNK_COUNT + chunk];
    }

    float4 center = 0.0f;

    if (sum.w > 1e-6f)
        center = float4(sum.xyz / sum.w, sum.w);

    GroupCenters[slot] = center;

    // Diagnostic output: Debug[8..15].
    // xyz = weighted center, w = total mask weight.
    Debug[8u + slot] = center;
}