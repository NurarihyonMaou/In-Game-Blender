Texture1D<float4> IniParams : register(t120);
Buffer<uint> StringData   : register(t0); // decoded glyph IDs 0–38
Buffer<float2> LayoutData   : register(t2);
Texture2D<float4> GlyphAtlas       : register(t1);
SamplerState     samLinear         : register(s0);

#define StartOffset IniParams[96].xy
#define SpacingX    IniParams[96].z
#define SpacingY    IniParams[96].w
#define FontSize    IniParams[97].x

struct VS_OUT {
    float4 pos : SV_Position;
    float2 uv  : TEXCOORD0;
};

static const float4 GlyphUVs[26] = {
    float4(0.060547, 0.020833, 0.213867, 0.123698),
    float4(0.324219, 0.022135, 0.454102, 0.126953),
    float4(0.559570, 0.019531, 0.698242, 0.128255),
    float4(0.795898, 0.022135, 0.944336, 0.126953),

    float4(0.079102, 0.147786, 0.195312, 0.251953),
    float4(0.329102, 0.147786, 0.438477, 0.251953),
    float4(0.553711, 0.146484, 0.711914, 0.253906),
    float4(0.792969, 0.147135, 0.956055, 0.252604),
    
    float4(0.102539, 0.272135, 0.170898, 0.376953),
    float4(0.320312, 0.272135, 0.418945, 0.378906),
    float4(0.551758, 0.272135, 0.706055, 0.377604),
    float4(0.814453, 0.272135, 0.935547, 0.376302),

    float4(0.042969, 0.397135, 0.232422, 0.502604),
    float4(0.301758, 0.397135, 0.458984, 0.502604),
    float4(0.558594, 0.400391, 0.704102, 0.501953),
    float4(0.813477, 0.397135, 0.939453, 0.502604),


    float4(0.057617, 0.520182, 0.216797, 0.632812),
    float4(0.313477, 0.522135, 0.459961, 0.627604),
    float4(0.583008, 0.521484, 0.685547, 0.628255),
    float4(0.803711, 0.522786, 0.946289, 0.627604),

    float4(0.056641, 0.647135, 0.211914, 0.753255),
    float4(0.314453, 0.649089, 0.455078, 0.748698),
    float4(0.521484, 0.649089, 0.735352, 0.753906),
    float4(0.798828, 0.649089, 0.956055, 0.753255),
    
    float4(0.069336, 0.764974, 0.196289, 0.877604),
    float4(0.322266, 0.771484, 0.446289, 0.873047),
};

#ifdef VERTEX_SHADER
VS_OUT main(uint vID : SV_VertexID, uint instID : SV_InstanceID)
{
    VS_OUT o;
    uint id = StringData[instID];

    int column = LayoutData[instID].x;
    int row = LayoutData[instID].y;

    float2 startOffset = StartOffset;

    // skip space(0)/newline(1)
    if (id == 0) {
        o.pos = float4(-1,-1,0,1);
        o.uv  = 0;
        return o;
    }

    // Adjust id to index GlyphUVs: assuming glyph IDs correspond to letters A-Z = 10..35
    // so subtract 10 for zero-based index in GlyphUVs
    int glyphIndex = int(id) - 10;
    if (glyphIndex < 0 || glyphIndex >= 26) {
        // fallback to offscreen if invalid glyph index
        o.pos = float4(-1, -1, 0, 1);
        o.uv = 0;
        return o;
    }

    float4 uvRect = GlyphUVs[glyphIndex];
    // uvRect = (minX, minY, maxX, maxY)

    // Quad corners (same order as before)
    static const float2 uvOffset[4] = {
        float2(0.0, 0.0),  // top-left
        float2(1.0, 0.0),  // top-right
        float2(0.0, 1.0),  // bottom-left
        float2(1.0, 1.0)   // bottom-right
    };

    int q = vID % 4;

    // Interpolate UV for this corner
    float2 uv = lerp(uvRect.xy, uvRect.zw, uvOffset[q]);

    // Compute on-screen position
    float2 base = float2(StartOffset.x + LayoutData[instID].x, LayoutData[instID].y);

    float2 uvSize = uvRect.zw - uvRect.xy;
    float glyphAspect = uvSize.x / uvSize.y;

    // Height = FontSize, Width = scaled
    float2 glyphSize = FontSize * float2(glyphAspect, 1.0);

    // Set quad vertex positions (relative to top-left)
    float2 quadPos;
    if (q == 0) quadPos = float2(0,           0);            // top-left
    if (q == 1) quadPos = float2(glyphSize.x, 0);            // top-right
    if (q == 2) quadPos = float2(0,          -glyphSize.y);  // bottom-left
    if (q == 3) quadPos = float2(glyphSize.x,-glyphSize.y);  // bottom-right

    float2 finalPos = base + quadPos;

    o.pos = float4(finalPos, 0.0, 1.0);
    o.uv = uv;
    return o;
}
#endif


#ifdef PIXEL_SHADER
float4 main(VS_OUT i) : SV_Target
{
    return GlyphAtlas.Sample(samLinear, i.uv);
}
#endif