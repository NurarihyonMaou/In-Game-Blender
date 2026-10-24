struct PosBuf {
    float3 position;
    float3 normal;
    float4 tangent;
};

struct BlendBuf {
    float4 blendWeights;
    int4 blendIndices;
};

#define MAX_REGIONS 3
#define INFLUENCE_EPS 1e-5
#define VERTEX_COUNT 133438

RWStructuredBuffer<PosBuf> basePos       : register(u0);
StructuredBuffer<BlendBuf> blendBuffer   : register(t0);

RWBuffer<uint> AtomicCounter             : register(u1); 
RWBuffer<float4> SecuredFloats           : register(u2);

Texture1D<float4> IniParams              : register(t120);
#define REGION_COUNT IniParams[76].x
#define REGION_BONE_BASE 90

[numthreads(64,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint i = DTid.x;
    if(i >= VERTEX_COUNT) return;

    PosBuf vb = basePos[i];
    BlendBuf blend = blendBuffer[i];

    int rc = (int)REGION_COUNT;
    if(rc <= 0) return;

    [unroll]
    for(int r=0; r<MAX_REGIONS; ++r)
    {
        if(r >= rc) break;

        float4 bones = IniParams[REGION_BONE_BASE + r];
        int bone0 = (int)bones.x;
        int bone1 = (int)bones.y;
        int bone2 = (int)bones.z;

        float influence = 0;
        [unroll]
        for(int k=0;k<4;k++)
        {
            int b = blend.blendIndices[k];
            float w = blend.blendWeights[k];
            if(b==bone0 || (bone1 > 0 && b==bone1) || (bone2 > 0 && b==bone2)) influence += w;
        }

        if(influence <= INFLUENCE_EPS) continue;

        float3 weighted = vb.position * influence;
        uint idx;
        InterlockedAdd(AtomicCounter[r],1,idx);
        SecuredFloats[idx + r * VERTEX_COUNT] = float4(weighted,influence);
    }
}
