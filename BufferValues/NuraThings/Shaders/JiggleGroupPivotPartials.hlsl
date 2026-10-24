// JiggleGroupPivotPartials.hlsl
// Calculates weighted center contributions for 8 named-mask groups.
// Mask layout: slot * VERTEX_COUNT + vertexID.

struct PosBuf
{
    float3 position;
    float3 normal;
    float4 tangent;
};

Buffer<float> NamedMasks : register(t0);
StructuredBuffer<PosBuf> PositionBuffer : register(t1);
RWBuffer<float4> PartialSums : register(u0);

Texture1D<float4> IniParams : register(t120);

#define GROUP_MASK_BASE 124u

#define VERTEX_COUNT 79355u
#define MASK_SLOT_COUNT 8u
#define THREADS_PER_GROUP 64u
#define CHUNK_COUNT ((VERTEX_COUNT + THREADS_PER_GROUP - 1u) / THREADS_PER_GROUP)

groupshared float4 SharedData[THREADS_PER_GROUP];

[numthreads(64, 1, 1)]
void main(
    uint3 groupID : SV_GroupID,
    uint3 groupThreadID : SV_GroupThreadID)
{
    uint blockID = groupID.x;
    uint groupIndex = blockID / CHUNK_COUNT;
    uint chunkID = blockID % CHUNK_COUNT;
    uint lane = groupThreadID.x;

    uint maskSlot = (uint)clamp(
        (int)(IniParams[GROUP_MASK_BASE + groupIndex].x + 0.5f),
        0,
        (int)MASK_SLOT_COUNT - 1
    );

    uint vertexID = chunkID * THREADS_PER_GROUP + lane;

    float4 contribution = 0.0f;

    if (groupIndex < MASK_SLOT_COUNT && vertexID < VERTEX_COUNT)
    {
        uint maskIndex = maskSlot * VERTEX_COUNT + vertexID;

        float weight = saturate(NamedMasks[maskIndex]);
        float3 position = PositionBuffer[vertexID].position;

        contribution = float4(position * weight, weight);
    }

    SharedData[lane] = contribution;
    GroupMemoryBarrierWithGroupSync();

    [unroll]
    for (uint stride = 32u; stride > 0u; stride >>= 1u)
    {
        if (lane < stride)
            SharedData[lane] += SharedData[lane + stride];

        GroupMemoryBarrierWithGroupSync();
    }

    if (lane == 0u && groupIndex < MASK_SLOT_COUNT)
    {
        uint outputIndex = groupIndex * CHUNK_COUNT + chunkID;
        PartialSums[outputIndex] = SharedData[0];
    }
}