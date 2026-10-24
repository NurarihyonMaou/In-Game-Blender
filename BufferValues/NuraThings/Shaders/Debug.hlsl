struct PosBuf {
    float3 position;
    float3 normal;
    float4 tangent;
};

struct BlendBuf {
    float4 blendWeights;
    int4 blendIndices;
};

RWStructuredBuffer<BlendBuf> blendBuffer : register(u2);

Texture1D<float4> IniParams : register(t120);

#define BoneIDs   IniParams[77] // x = BoneA, y = BoneB

RWStructuredBuffer<PosBuf> rwPos       : register(u1); // output mesh
Buffer<float4> PrevPivotPos          : register(t2); // persistent state
Buffer<float4> PivotBuffer           : register(t1); // from PivotFetcher
RWBuffer<float4> Debug                 : register(u0);
Buffer<float> Weights                 : register(t3);
[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint id = DTid.x;

   //Debug[2] = float4(169, rwPos[id].position);
   //    Debug[3] = float4(19, rwPos[id].normal);
   //        Debug[4] = float4(rwPos[id].tangent);
   //Debug[7] = float4(PrevPivotPos[0]);
   //Debug[12] = float4(PivotBuffer[0]);
    int boneA = (int)BoneIDs.x;
    int boneB = (int)BoneIDs.y;

    BlendBuf blend = blendBuffer[id];

    [unroll]
    for (int k = 0; k < 4; ++k)
    {
        int b = blend.blendIndices[k];
        float w = blend.blendWeights[k];
        Debug[12] = float4(k, b, w, id);
        if (b == boneA || b == boneB){
            Debug[13] = float4(Debug[13].x+1, b, w, blend.blendWeights[k]);
        }
    }
}