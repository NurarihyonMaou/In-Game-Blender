Buffer<uint> FullModelList      : register(t0);
RWBuffer<float> Output      : register(u0);
RWBuffer<float4> Debug      : register(u1);
Texture1D<float4> IniParams : register(t120);

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    Output[0] = asfloat(FullModelList[IniParams[3].x-1]);
}   