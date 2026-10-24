Buffer<uint> FullModIDs      : register(t0);
Buffer<uint> ModToModelType  : register(t1);
RWBuffer<float> Output       : register(u0);
RWBuffer<float4> Debug       : register(u1);
Texture1D<float4> IniParams  : register(t120);

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint localIndex = IniParams[3].x;      // e.g. 6 (1-based)
    uint modelType  = asuint(IniParams[3].y);      // e.g. 36

    uint count = 0;
    float resultModID = 0;

    // Assume max 512 mods total
    for (uint i = 0; i < 2048; i++) {
        if (ModToModelType[i] == modelType) {
            count++;
            if (count == asuint(localIndex)) {
                resultModID = asfloat(FullModIDs[i]);
                break;
            }
        }
    }

    Output[0] = resultModID;
}
