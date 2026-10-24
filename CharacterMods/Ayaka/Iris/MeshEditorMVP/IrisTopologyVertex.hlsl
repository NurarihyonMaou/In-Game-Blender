Texture1D<float4> IniParams : register(t120);

#define SCREEN_WIDTH  max(IniParams[31].z, 1.0f)
#define SCREEN_HEIGHT max(IniParams[31].w, 1.0f)

struct GSIn
{
    float4 pos : SV_Position;
};

struct GSOut
{
    float4 pos : SV_Position;
    float2 uv  : TEXCOORD0;
};


#ifdef GEOMETRY_SHADER
[maxvertexcount(4)]
void main(point GSIn input[1], inout TriangleStream<GSOut> stream)
{
    float4 center = input[0].pos;

    // Ignore points behind the camera.
    if (center.w <= 1e-6f)
        return;

    // Point radius in screen pixels.
    const float radiusPixels = 3.0f;

    float2 radiusNdc = float2(
        2.0f * radiusPixels / SCREEN_WIDTH,
        2.0f * radiusPixels / SCREEN_HEIGHT
    );

    GSOut o;

    // Top-left.
    o.pos = center;
    o.pos.xy += float2(-radiusNdc.x, radiusNdc.y) * center.w;
    o.uv = float2(-1.0f, -1.0f);
    stream.Append(o);

    // Top-right.
    o.pos = center;
    o.pos.xy += float2(radiusNdc.x, radiusNdc.y) * center.w;
    o.uv = float2(1.0f, -1.0f);
    stream.Append(o);

    // Bottom-left.
    o.pos = center;
    o.pos.xy += float2(-radiusNdc.x, -radiusNdc.y) * center.w;
    o.uv = float2(-1.0f, 1.0f);
    stream.Append(o);

    // Bottom-right.
    o.pos = center;
    o.pos.xy += float2(radiusNdc.x, -radiusNdc.y) * center.w;
    o.uv = float2(1.0f, 1.0f);
    stream.Append(o);

    stream.RestartStrip();
}
#endif

#ifdef PIXEL_SHADER

struct PSIn
{
    float4 pos : SV_Position;
    float2 uv  : TEXCOORD0;
};

float4 main(PSIn input) : SV_Target1
{
    float distance = length(input.uv);
    float aa = max(fwidth(distance), 1e-4f);

    // Antialiased circular silhouette.
    float alpha = 1.0f - smoothstep(
        1.0f - aa,
        1.0f + aa,
        distance
    );

    // Golden center; dark outer rim.
    float core = 1.0f - smoothstep(
        0.48f - aa,
        0.68f + aa,
        distance
    );

    float3 color = lerp(
        float3(0.012f, 0.018f, 0.024f),
        float3(1.0f, 0.72f, 0.16f),
        core
    );

    return float4(color, alpha);
}

#endif