RWBuffer<uint> AtomicCounter : register(u0); 
RWBuffer<float4> SecuredFloats : register(u1); 

RWBuffer<float4> PivotBuffer : register(u3);
RWBuffer<float>  WeightSum   : register(u4);

#define VERTEX_COUNT 133438
Texture1D<float4> IniParams : register(t120);
#define REGION_COUNT IniParams[76].x

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    for(int r=0; r<REGION_COUNT; r++)
    {
        uint numContribs = AtomicCounter[r];
        if(numContribs == 0) continue;

        float3 pivot = float3(0,0,0);
        float totalWeight = 0;

        for(uint i=0; i<numContribs; i++)
        {
            float4 val = SecuredFloats[i + r * VERTEX_COUNT];
            pivot += val.xyz;
            totalWeight += val.w;
        }

        pivot /= totalWeight;

        PivotBuffer[r] = float4(pivot,1);
        WeightSum[r] = totalWeight;
    }
}
