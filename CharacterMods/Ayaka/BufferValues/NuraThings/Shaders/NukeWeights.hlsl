struct BlendBuf {
    float4 blendWeights;
    int4 blendIndices;
};

RWStructuredBuffer<BlendBuf> blendBuffer : register(u0);
RWBuffer<float4> Debug : register(u1);

Texture1D<float4> IniParams : register(t120);
#define BoneIDs   IniParams[77] // x = BoneA, y = BoneB

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint id = DTid.x;

    int boneA = (int)BoneIDs.x;
    int boneB = (int)BoneIDs.y;

    BlendBuf blend = blendBuffer[id];

    // First pass: zero out jiggle bones
    [unroll]
    for (int k = 0; k < 4; ++k)
    {
        int b = blend.blendIndices[k];
        if (b == boneA || b == boneB)
            blend.blendWeights[k] = 0.0;
    }

    // Compute remaining total weight
    float total = 
        blend.blendWeights.x +
        blend.blendWeights.y +
        blend.blendWeights.z +
        blend.blendWeights.w;

    // If something remains, redistribute proportionally so sum = 1.0
    if (total > 1e-6)
        blend.blendWeights /= total;
    else
        blend.blendWeights = float4(0, 0, 0, 0); // fully removed if no valid weights

    blendBuffer[id] = blend;
}
