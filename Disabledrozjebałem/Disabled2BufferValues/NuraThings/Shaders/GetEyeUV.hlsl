struct BlendBuf {
    float4 blendWeights;
    int4 blendIndices;
};

struct TexBuf {
    uint color;      // Color as a uint (could represent a packed RGB value)
    float2 texcoord; // Texture coordinates
};

StructuredBuffer<BlendBuf> blendBuffer : register(t50);
StructuredBuffer<TexBuf> TexcoordBuffer : register(t51); 

RWBuffer<float2> EyeUVs : register(u0);
RWBuffer<uint>Counter : register(u1);


[numthreads(64,1,1)]
void main(uint3 id : SV_DispatchThreadID)
{
    BlendBuf v = blendBuffer[id.x];

    if ((v.blendIndices.x == 8 || v.blendIndices.x == 9) && v.blendWeights.x > 0.5) {
        uint index = Counter[0];
        InterlockedAdd(Counter[0], 1, index);
        EyeUVs[index] = TexcoordBuffer[id.x].texcoord;
    }
}