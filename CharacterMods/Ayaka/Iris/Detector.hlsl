Texture1D<float4> IniParams : register(t120);

RWBuffer<float> HoverResult : register(u0);

struct PS_INPUT
{
    float4 Position : SV_Position;
    uint PrimitiveID : SV_PrimitiveID;
};

void main(PS_INPUT input)
{
    float2 cursor = floor(IniParams[31].xy);

    if (abs(input.Position.x - cursor.x) >= 1 ||
        abs(input.Position.y - cursor.y) >= 1)
        return;

    HoverResult[0] = (float)input.PrimitiveID;
    HoverResult[1] = (float)input.PrimitiveID;
}