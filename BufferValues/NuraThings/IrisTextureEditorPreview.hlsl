// IrisTextureEditorPreview.hlsl
// Stage T0: read-only preview for the original diffuse texture resources.
// The VS fits the source's actual aspect ratio inside a fixed on-screen box.
// The PS manually bilinearly samples mip 0; it works with sampled DDS formats
// including block-compressed inputs, without requiring a writable UAV format.
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> PreviewTexture : register(t0);

struct VSOutput
{
    float4 pos : SV_Position;
    float2 uv : TEXCOORD0;
};

#ifdef VERTEX_SHADER
VSOutput main(uint vertexID : SV_VertexID)
{
    VSOutput output;
    float2 quad[4] = {
        float2(0.0f, 0.0f),
        float2(1.0f, 0.0f),
        float2(0.0f, 1.0f),
        float2(1.0f, 1.0f)
    };
    float2 q = quad[vertexID & 3u];

    uint width, height;
    PreviewTexture.GetDimensions(width, height);
    float textureAspect = (float)max(width, 1u) / (float)max(height, 1u);

    float2 boxOrigin = IniParams[210].xy;
    float2 boxSize = max(IniParams[211].xy, float2(0.001f, 0.001f));
    float boxAspect = boxSize.x / boxSize.y;
    float2 fittedSize = boxSize;

    if (textureAspect > boxAspect)
        fittedSize.y = boxSize.x / textureAspect;
    else
        fittedSize.x = boxSize.y * textureAspect;

    float2 origin = boxOrigin + (boxSize - fittedSize) * 0.5f;
    float2 screenPos = origin + q * fittedSize;
    output.pos = float4(screenPos.x * 2.0f - 1.0f, 1.0f - screenPos.y * 2.0f, 0.0f, 1.0f);
    output.uv = q;
    return output;
}
#else
float4 main(VSOutput input) : SV_Target
{
    uint width, height;
    PreviewTexture.GetDimensions(width, height);
    if (width == 0u || height == 0u)
        return float4(1.0f, 0.0f, 1.0f, 1.0f);

    float2 samplePos = saturate(input.uv) * float2(width, height) - 0.5f;
    int2 p0 = (int2)floor(samplePos);
    float2 f = frac(samplePos);
    int2 p1 = p0 + 1;
    int2 maxPos = int2((int)width - 1, (int)height - 1);
    p0 = clamp(p0, int2(0, 0), maxPos);
    p1 = clamp(p1, int2(0, 0), maxPos);

    float4 c00 = PreviewTexture.Load(int3(p0, 0));
    float4 c10 = PreviewTexture.Load(int3(p1.x, p0.y, 0));
    float4 c01 = PreviewTexture.Load(int3(p0.x, p1.y, 0));
    float4 c11 = PreviewTexture.Load(int3(p1, 0));
    float4 color = lerp(lerp(c00, c10, f.x), lerp(c01, c11, f.x), f.y);

    // Small dark header strip and a numeric slot indicator for the six resources.
    if (input.uv.y < 0.055f)
        color.rgb = lerp(color.rgb, float3(0.018f, 0.022f, 0.028f), 0.82f);

    float2 badge = input.uv / float2(0.075f, 0.055f);
    int slot = (int)round(IniParams[210].z) + 1;
    bool segA = slot != 1 && slot != 4;
    bool segB = slot != 5 && slot != 6;
    bool segC = slot != 2;
    bool segD = slot != 1 && slot != 4 && slot != 7;
    bool segE = slot == 2 || slot == 6 || slot == 8;
    bool segF = slot == 1 || slot == 2 || slot == 3 || slot == 7;
    bool segG = slot != 0;
    bool segment =
        (segA && badge.y > 0.08f && badge.y < 0.19f && badge.x > 0.23f && badge.x < 0.77f) ||
        (segG && badge.y > 0.445f && badge.y < 0.555f && badge.x > 0.23f && badge.x < 0.77f) ||
        (segD && badge.y > 0.81f && badge.y < 0.92f && badge.x > 0.23f && badge.x < 0.77f) ||
        (segF && badge.x > 0.08f && badge.x < 0.19f && badge.y > 0.16f && badge.y < 0.45f) ||
        (segB && badge.x > 0.81f && badge.x < 0.92f && badge.y > 0.16f && badge.y < 0.45f) ||
        (segE && badge.x > 0.08f && badge.x < 0.19f && badge.y > 0.55f && badge.y < 0.84f) ||
        (segC && badge.x > 0.81f && badge.x < 0.92f && badge.y > 0.55f && badge.y < 0.84f);
    if (input.uv.x < 0.075f && input.uv.y < 0.055f && segment)
        color.rgb = float3(1.0f, 0.82f, 0.18f);

    return float4(color.rgb, color.a);
}
#endif
