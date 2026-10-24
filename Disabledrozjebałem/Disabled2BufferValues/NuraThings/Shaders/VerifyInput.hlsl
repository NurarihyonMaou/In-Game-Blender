Buffer<uint> StringData       : register(t0);
Buffer<uint> StringCount   : register(t1);

RWBuffer<float> Output   : register(u0);

Texture1D<float4> IniParams  : register(t120);

[numthreads(1,1,1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    Output[0] = 0;

    if (StringCount[0] != 10)
        return;

    if (StringData[0] != 'N') return;
    if (StringData[1] != 'u') return;
    if (StringData[2] != 'r') return;
    if (StringData[3] != 'a') return;
    if (StringData[4] != 'r') return;
    if (StringData[5] != 'i') return;
    if (StringData[6] != 'h') return;
    if (StringData[7] != 'y') return;
    if (StringData[8] != 'o') return;
    if (StringData[9] != 'n') return;

    Output[0] = 1;

}