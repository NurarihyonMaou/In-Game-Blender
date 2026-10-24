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

RWStructuredBuffer<PosBuf> rwPos       : register(u0);

RWBuffer<float4> PivotBuffer : register(u1);
RWBuffer<float>  WeightSum   : register(u2);
//RWBuffer<float>  InfluenceOut : register(u3);

Texture1D<float4> IniParams : register(t120);

#define BoneIDs   IniParams[77] // x = BoneA, y = BoneB, z = unused, w = unused
#define MorphInfo  IniParams[78] // x = Strength, y = PowCurve, z = unused, w = unused
#define ShapeInfo  IniParams[79] // xyz = Scale, w = Push

[numthreads(64,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint i = DTid.x;

    int boneA = (int)BoneIDs.x;
    int boneB = (int)BoneIDs.y;
    float strength = MorphInfo.x;
    float powCurve = MorphInfo.y;

    float3 scaleVec = ShapeInfo.xyz;
    float push = ShapeInfo.w;

    PosBuf vtx = basePos[i];
    BlendBuf blend = blendBuffer[i];

    float weight = 0;
    [unroll]
    for (int k = 0; k < 4; ++k)
    {
        int b = blend.blendIndices[k];
        float w = blend.blendWeights[k];
        if (b == boneA || b == boneB)
            weight += w;
    }

    float influence = pow(saturate(weight), powCurve);

    float3 pivot = PivotBuffer[0].xyz / max(WeightSum[0], 1e-5);
    float3 delta = vtx.position - pivot;
    float3 scaled = delta * scaleVec;
    float3 offset = scaled - delta;

    float3 pushVec = normalize(vtx.normal) * push;

    vtx.position += (offset + pushVec) * strength * influence;


//float3 totalOffset = (offset + pushVec) * strength * influence;
//float moveDir = dot(normalize(totalOffset), normalize(vtx.normal));
//
//// Only allow movement outward
//if (moveDir < 0)
//    totalOffset = float3(0,0,0);
//
//vtx.position += totalOffset;



    rwPos[i] = vtx;
    //[i] = influence;
}


//struct PosBuf {
//    float3 position;
//    float3 normal;  
//    float4 tangent; 
//};
//
//struct BlendBuf {
//    float4 blendWeights;
//    int4 blendIndices;
//};
//
//
//StructuredBuffer<PosBuf> basePos : register(t50);
//StructuredBuffer<BlendBuf> blendBuffer : register(t51);
//
//RWBuffer<float4> Debug : register(u3);
//RWStructuredBuffer<PosBuf> rwPos : register(u0);
//
//Texture1D<float4> IniParams : register(t120);
//
//[numthreads(1, 1, 1)]
//void main(uint3 DTid : SV_DispatchThreadID)
//{
//    uint i = DTid.x;
//
//    PosBuf v = basePos[i];
//    float3 P = v.position;
//    float3 N = normalize(v.normal);
//
//    float4 w = blendBuffer[i].blendWeights;
//    int4   idx = blendBuffer[i].blendIndices;
//
//    [unroll]
//    for (int k = 0; k < 4; ++k)
//    {
//        float weight = w[k];
//        int group = idx[k];
//
//        if (weight > 0.01 && (group == 2 || group == 3))
//        {
//            float3 scale = float3(1.1, 1.0, 1.1);
//            float  push  = 0.05;                 
//            float3 pivot = float3(0.0, 1.3, 0.2);
//
//            float3 dS = (P - pivot) * (scale - 1.0);
//            float3 dP = N * push;
//
//            P += weight * (dS + dP);
//        }
//    }
//
//    v.position = P;
//    rwPos[i] = v;
//
//    if (i < 192)
//        Debug[i] = float4(P, 69);
//}
