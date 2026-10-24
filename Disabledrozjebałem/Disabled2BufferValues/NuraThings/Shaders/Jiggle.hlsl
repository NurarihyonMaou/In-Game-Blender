struct PosBuf {
    float3 position;
    float3 normal;
    float4 tangent;
};


struct BlendBuf {
    float4 blendWeights;
    int4 blendIndices;
};

RWStructuredBuffer<PosBuf> rwPos       : register(u0); // output mesh
RWBuffer<float3> rwPrevPivotPos          : register(u3); // persistent state
RWBuffer<float3> rwPivotVelocity         : register(u4); // persistent state
RWBuffer<float3> PivotBuffer           : register(u1); // from PivotFetcher
RWBuffer<float>  WeightSum             : register(u2);


StructuredBuffer<PosBuf> basePos       : register(t2);
Buffer<float3> PrevPivotPos          : register(t3);
Buffer<float3> PivotVelocity         : register(t4);

RWBuffer<float4> Debug : register(u5);

StructuredBuffer<BlendBuf> blendBuffer : register(t51);
//StructuredBuffer<uint> VertexRegion     : register(t2); // optional, if multiple regions

Texture1D<float4> IniParams : register(t120);
// Params: x=stiffness, y=damping, z=blend, w=deltaTime
// Extra: x=motionThreshold, y=restDamping
#define JiggleParams IniParams[80]
#define BoneIDs   IniParams[77] // x = BoneA, y = BoneB, z = unused, w = unused

[numthreads(64,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint id = DTid.x;

    int boneA = (int)BoneIDs.x;
    int boneB = (int)BoneIDs.y;

    BlendBuf blend = blendBuffer[id];

    float3 pos = basePos[id].position;
    float3 nor = basePos[id].normal;
    float4 tan = basePos[id].tangent;

   // PosBuf vtx = basePos[id]; // could be rwPos if you want cumulative updates
    uint region = 0; // single region example; extend for multiple regions

    // --- Load pivot ---
    float3 basePivot = PivotBuffer[region] / max(WeightSum[region], 1e-5);
    float3 prevPivot = PrevPivotPos[region];
    float3 vel       = PivotVelocity[region];

    // --- Motion detection ---
    float3 delta = basePivot - prevPivot;
    float speed  = length(delta);
    float3 acc = float3(0,0,0);

    if (speed > JiggleParams.x) // motionThreshold
    {
        acc = delta * JiggleParams.y;      // stiffness
        vel = vel * JiggleParams.z + acc;  // damping
        vel = 4;
    }
    else
    {
        vel *= JiggleParams.w;              // rest damping
        vel = 0;
    }
    // --- Integrate ---
    float3 jigPivot = prevPivot + vel * JiggleParams.w;

    // --- Save state (single thread) ---
    if (id == 0)
    {
        rwPrevPivotPos[region] = jigPivot;
        rwPivotVelocity[region] = vel;

        Debug[5] = float4(speed, basePivot);
        Debug[6] = float4(69, prevPivot);
    }


    // --- Apply pivot offset ---
    float3 offset = (jigPivot - basePivot) * JiggleParams.z; // blend strength

    [unroll]
    for (int k = 0; k < 4; ++k)
    {
        int b = blend.blendIndices[k];
        float w = blend.blendWeights[k];
        if (b == boneA || b == boneB)
            pos += offset;
    }


    rwPos[id].position = pos;
    rwPos[id].normal = nor;
    rwPos[id].tangent = tan;

}
