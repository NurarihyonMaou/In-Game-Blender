// SinglePass_RecolorEyes.hlsl
// For non-indexed meshes: every 3 vertices == 1 triangle
// Inputs: blendBuffer (t50), TexcoordBuffer (t51), texInput (t0)
// Output: texOutput (u0)

struct BlendBuf {
    float4 blendWeights;
    int4   blendIndices;
};

struct TexBuf {
    uint   color;
    float2 texcoord;
};

StructuredBuffer<BlendBuf> blendBuffer   : register(t50);
StructuredBuffer<TexBuf>   TexcoordBuffer: register(t51);

Texture2D<float4> texInput    : register(t0);
RWTexture2D<float4> texOutput : register(u0);


bool PointInTriangle(float2 p, float2 a, float2 b, float2 c)
{
    // Barycentric method with epsilon safety
    float2 v0 = c - a;
    float2 v1 = b - a;
    float2 v2 = p - a;

    float dot00 = dot(v0, v0);
    float dot01 = dot(v0, v1);
    float dot02 = dot(v0, v2);
    float dot11 = dot(v1, v1);
    float dot12 = dot(v1, v2);

    float denom = dot00 * dot11 - dot01 * dot01;
    if (abs(denom) < 1e-8) return false;
    float invDen = 1.0 / denom;

    float u = (dot11 * dot02 - dot01 * dot12) * invDen;
    float v = (dot00 * dot12 - dot01 * dot02) * invDen;

    return (u >= -1e-6) && (v >= -1e-6) && (u + v <= 1.0 + 1e-6);
}

[numthreads(64,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{

    uint triCount = 135440/3;            // number of triangles (vertexCount / 3)
    uint texWidth = 2048;
    uint texHeight = 1024;

    float3 recolorTint = float3(0.6, 0.2, 0.2);
    float  recolorStrength = 0.75;   // 0..1

    float eyeBlendThreshold = 0.05;  // e.g. 0.05
    int   eyeBlendIndexA = 8;     // e.g. 8
    int   eyeBlendIndexB = 9;     // e.g. 9 (set -1 if unused)

    float uvFlipY = 1;            // 1 to flip sampling UV Y, 0 otherwise
    float marginUV = 0.001;           // e.g. 0.001 - expands bbox so tiny tris get painted



    uint triIdx = DTid.x;
    if (triIdx >= triCount) return;

    uint i0 = triIdx * 3u + 0u;
    uint i1 = triIdx * 3u + 1u;
    uint i2 = triIdx * 3u + 2u;

    // read blend info
    BlendBuf b0 = blendBuffer[i0];
    BlendBuf b1 = blendBuffer[i1];
    BlendBuf b2 = blendBuffer[i2];

    // test if this triangle belongs to eye bone(s)
    bool isEye = false;
    [unroll]
    for (int k = 0; k < 4; ++k) {
        if ((b0.blendIndices[k] == eyeBlendIndexA && b0.blendWeights[k] > eyeBlendThreshold) ||
            (b1.blendIndices[k] == eyeBlendIndexA && b1.blendWeights[k] > eyeBlendThreshold) ||
            (b2.blendIndices[k] == eyeBlendIndexA && b2.blendWeights[k] > eyeBlendThreshold)) { isEye = true; break; }
    }
    if (!isEye && eyeBlendIndexB >= 0) {
        [unroll]
        for (int k = 0; k < 4; ++k) {
            if ((b0.blendIndices[k] == eyeBlendIndexB && b0.blendWeights[k] > eyeBlendThreshold) ||
                (b1.blendIndices[k] == eyeBlendIndexB && b1.blendWeights[k] > eyeBlendThreshold) ||
                (b2.blendIndices[k] == eyeBlendIndexB && b2.blendWeights[k] > eyeBlendThreshold)) { isEye = true; break; }
        }
    }
    if (!isEye) return; // not an eye triangle → done

    // read triangle UVs
    float2 a = TexcoordBuffer[i0].texcoord;
    float2 b = TexcoordBuffer[i1].texcoord;
    float2 c = TexcoordBuffer[i2].texcoord;

    // compute min/max UV with small margin
    float2 minUV = min(a, min(b, c)) - marginUV;
    float2 maxUV = max(a, max(b, c)) + marginUV;

    // clamp to [0,1]
    minUV = clamp(minUV, 0.0, 1.0);
    maxUV = clamp(maxUV, 0.0, 1.0);

    // convert to pixel coords
    int2 pMin = int2(floor(minUV * float2(texWidth, texHeight)));
    int2 pMax = int2(ceil (maxUV * float2(texWidth, texHeight)));

    // clamp pixel bounds
    pMin = int2(max(pMin.x, 0), max(pMin.y, 0));
    pMax = int2(min(pMax.x, int(texWidth) - 1), min(pMax.y, int(texHeight) - 1));

    // rasterize pixels inside bbox
    for (int y = pMin.y; y <= pMax.y; ++y)
    {
        for (int x = pMin.x; x <= pMax.x; ++x)
        {
            // compute pixel uv (center)
            float2 pUV = (float2(x, y) + 0.5) / float2(texWidth, texHeight);
            if (uvFlipY > 0.5) pUV.y = 1.0 - pUV.y;

            if (PointInTriangle(pUV, a, b, c))
            {
                // read, filter, recolor, write
                float4 col = texInput.Load(int3(x, y, 0));
                if (any(col.rgb > 0.05) && any(col.rgb < 0.95))
                {
                    col.rgb = lerp(col.rgb, recolorTint, recolorStrength);
                    texOutput[int2(x, y)] = col;
                }
            }
        }
    }
}