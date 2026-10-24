// MeshEditorWeightPreview.hlsl
// Heatmap for the selected VG ID, based on the editable (pre-Nuke) Blend data.

struct BlendBuf
{
    float4 blendWeights;
    int4 blendIndices;
};

Texture2D<float4> VertexScreen : register(t0);
StructuredBuffer<BlendBuf> EditableBlend : register(t1);
Texture1D<float4> IniParams : register(t120);

#define SELECTED_VG IniParams[40].x
#define CAPTURE_WIDTH 512u
#define CAPTURE_HEIGHT 256u
#define VERTEX_COUNT 79355u

struct VS_OUT
{
    float4 pos : SV_Position;
    float weight : TEXCOORD0;
};

float4 LoadVertexClip(uint vertexID)
{
    if (vertexID >= VERTEX_COUNT)
        return float4(0, 0, 0, 0);

    uint2 texel = uint2(vertexID % CAPTURE_WIDTH, vertexID / CAPTURE_WIDTH);
    if (texel.y >= CAPTURE_HEIGHT)
        return float4(0, 0, 0, 0);

    return VertexScreen.Load(int3(texel, 0));
}

float GetVertexWeight(uint vertexID)
{
    BlendBuf blend = EditableBlend[vertexID];
    int groupID = (int)(SELECTED_VG + 0.5f);
    float weight = 0.0f;

    [unroll]
    for (uint k = 0u; k < 4u; ++k)
    {
        if (blend.blendIndices[k] == groupID)
            weight += blend.blendWeights[k];
    }

    return saturate(weight);
}

#ifdef VERTEX_SHADER
VS_OUT main(uint vertexID : SV_VertexID)
{
    VS_OUT output;
    output.pos = LoadVertexClip(vertexID);
    output.weight = vertexID < VERTEX_COUNT ? GetVertexWeight(vertexID) : 0.0f;
    return output;
}
#endif

#ifdef PIXEL_SHADER
float4 main(VS_OUT input) : SV_Target1
{
    float t = saturate(input.weight);
    float3 color;

    if (t < 0.25f)
        color = lerp(float3(0.02f, 0.06f, 0.72f), float3(0.00f, 0.85f, 1.00f), t * 4.0f);
    else if (t < 0.5f)
        color = lerp(float3(0.00f, 0.85f, 1.00f), float3(0.05f, 0.95f, 0.18f), (t - 0.25f) * 4.0f);
    else if (t < 0.75f)
        color = lerp(float3(0.05f, 0.95f, 0.18f), float3(1.00f, 0.90f, 0.02f), (t - 0.5f) * 4.0f);
    else
        color = lerp(float3(1.00f, 0.90f, 0.02f), float3(1.00f, 0.04f, 0.02f), (t - 0.75f) * 4.0f);

    return float4(color, lerp(0.46f, 0.72f, t));
}
#endif
