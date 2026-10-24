// Each entry: { ModType, ModID, BoundType, BoundID }
RWBuffer<uint4> BoundPairs : register(u0);
RWBuffer<uint> PairCounter : register(u1);

RWBuffer<float> SelectedPair : register(u2);
RWBuffer<float> Output : register(u3);
RWBuffer<float4> Debug : register(u4);

Texture1D<float4> IniParams : register(t120);

[numthreads(1,1,1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    int pairIndex = (int)IniParams[44].x;
    uint idx = 0;

    if (pairIndex == -2) {
        BoundPairs[idx] = uint4(IniParams[45].x, IniParams[45].y, IniParams[45].z, IniParams[45].w);
        InterlockedAdd(PairCounter[0], 1, idx);
    }
    else if (pairIndex > -1) {
        uint4 pair = BoundPairs[pairIndex-1];

        SelectedPair[0] = (float)pair.x;
        SelectedPair[1] = (float)pair.y;
    }

    Output[0] = float(PairCounter[0]);
    Debug[0] = float4(SelectedPair[0], SelectedPair[1], pairIndex-1, idx);
    Debug[2] = float4(BoundPairs[pairIndex-1]);
}
