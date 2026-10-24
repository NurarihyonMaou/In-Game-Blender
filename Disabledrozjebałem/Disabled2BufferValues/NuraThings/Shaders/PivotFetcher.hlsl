struct PosBuf {
    float3 position;
    float3 normal;
    float4 tangent;
};

struct BlendBuf {
    float4 blendWeights;
    int4 blendIndices;
};

StructuredBuffer<PosBuf> basePos       : register(t50);
StructuredBuffer<BlendBuf> blendBuffer : register(t51);

RWBuffer<float3> PivotBuffer : register(u1);
RWBuffer<float>  WeightSum   : register(u2);

Texture1D<float4> IniParams : register(t120);
#define BoneIDs   IniParams[77] // x = BoneA, y = BoneB, z = unused, w = unused

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint i = DTid.x;

    int boneA = (int)BoneIDs.x;
    int boneB = (int)BoneIDs.y;

    PosBuf vtx = basePos[i];
    BlendBuf blend = blendBuffer[i];

    float influence = 0;
    [unroll]
    for (int k = 0; k < 4; ++k)
    {
        int b = blend.blendIndices[k];
        float w = blend.blendWeights[k];

        if (b == boneA || b == boneB)
            influence += w;
    }

    if (influence > 0.0001)
    {
        float3 weighted = vtx.position * influence;
        PivotBuffer[0].xyz += float3(weighted.x, weighted.y, weighted.z);
        WeightSum[0] += influence;
    }
}
