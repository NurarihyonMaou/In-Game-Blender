RWTexture2D<float4> texInput : register(u0);
Texture1D<float4> IniParams : register(t120);

RWStructuredBuffer<float3> StoreGlowColors : register(u1);

[numthreads(32, 32, 1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint2 coord = DTid.xy;
    float3 inputColor = texInput[coord].rgb;

    if (any(inputColor != float3(0, 0, 0)))
    {
        bool alreadyStored = false;
        for (uint i = 0; i < StoreGlowColors.Length; ++i)
        {
            if (all(StoreGlowColors[i] == inputColor))
            {
                alreadyStored = true;
                break;
            }
        }

        if (!alreadyStored)
        {
            uint index = 0;
            InterlockedAdd(StoreGlowColors.IncrementCounter(), 1, index);
            StoreGlowColors[index] = inputColor;
        }
    }
}