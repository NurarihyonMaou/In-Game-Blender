struct GS_INPUT
{
    float4 Position : SV_Position;
};

struct GS_OUTPUT
{
    float4 Position : SV_Position;

    noperspective float3 Bary : TEXCOORD0;
    noperspective float3 InvW : TEXCOORD1;

    uint PrimitiveID : SV_PrimitiveID;
};

[maxvertexcount(3)]
void main(
    triangle GS_INPUT input[3],
    uint primitiveID : SV_PrimitiveID,
    inout TriangleStream<GS_OUTPUT> output)
{
    GS_OUTPUT o;

    o.PrimitiveID = primitiveID;

    o.Position = input[0].Position;
    o.Bary = float3(1.0, 0.0, 0.0);
    o.InvW = float3(
        1.0 / input[0].Position.w,
        0.0,
        0.0
    );
    output.Append(o);

    o.Position = input[1].Position;
    o.Bary = float3(0.0, 1.0, 0.0);
    o.InvW = float3(
        0.0,
        1.0 / input[1].Position.w,
        0.0
    );
    output.Append(o);

    o.Position = input[2].Position;
    o.Bary = float3(0.0, 0.0, 1.0);
    o.InvW = float3(
        0.0,
        0.0,
        1.0 / input[2].Position.w
    );
    output.Append(o);

    output.RestartStrip();
}