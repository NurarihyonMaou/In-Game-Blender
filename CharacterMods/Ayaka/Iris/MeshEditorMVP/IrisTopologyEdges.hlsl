// Screen-space thick edge overlay. Every indexed triangle contributes its three
// edges; the edge nearest the most recent temporary hit is highlighted orange.
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> VertexScreen : register(t0);
Buffer<uint> SelectedRefCount : register(t1);

#define VERTEX_COUNT 79355u
#define CAPTURE_WIDTH 512u
#define CAPTURE_HEIGHT 256u
#define SCREEN_WIDTH max(IniParams[31].z, 1.0f)
#define SCREEN_HEIGHT max(IniParams[31].w, 1.0f)
#define TEMP_SELECTION_VALID (IniParams[40].y > 0.5f)
#define PERSISTENT_EDGE_VALID (IniParams[43].z > 0.5f)
#define EDGE_HIGHLIGHT_DISABLED (IniParams[43].z < -0.5f)
#define SELECTION_MASK_ACTIVE (IniParams[44].x > 0.5f)

struct VSOut
{
    float4 pos : SV_Position;
    nointerpolation uint vertexID : TEXCOORD0;
};

struct GSOut
{
    float4 pos : SV_Position;
    float2 edgeUV : TEXCOORD0;
    nointerpolation float selected : TEXCOORD1;
};

#ifdef VERTEX_SHADER
VSOut main(uint vertexID : SV_VertexID)
{
    VSOut output;
    output.vertexID = vertexID;
    if (vertexID >= VERTEX_COUNT)
        output.pos = float4(0.0f, 0.0f, 0.0f, 0.0f);
    else
        output.pos = VertexScreen.Load(int3(vertexID % CAPTURE_WIDTH, vertexID / CAPTURE_WIDTH, 0));
    return output;
}
#endif

#ifdef GEOMETRY_SHADER
bool SameEdge(uint a, uint b, uint c, uint d)
{
    return (a == c && b == d) || (a == d && b == c);
}

void BuildEdgeQuad(
    float4 a, float4 b, bool selected,
    out GSOut o0, out GSOut o1, out GSOut o2, out GSOut o3)
{
    float2 ndcA = a.xy / a.w;
    float2 ndcB = b.xy / b.w;
    float2 pixelDelta = (ndcB - ndcA) * float2(SCREEN_WIDTH, SCREEN_HEIGHT) * 0.5f;
    float pixelLength = max(length(pixelDelta), 1e-5f);
    float2 normal = float2(-pixelDelta.y, pixelDelta.x) / pixelLength;
    float widthPixels = selected ? 2.2f : 1.05f;
    float2 offsetNdc = normal * widthPixels * float2(2.0f / SCREEN_WIDTH, 2.0f / SCREEN_HEIGHT);

    o0.pos = a; o0.pos.xy += offsetNdc * a.w; o0.edgeUV = float2(0.0f, -1.0f); o0.selected = selected ? 1.0f : 0.0f;
    o1.pos = a; o1.pos.xy -= offsetNdc * a.w; o1.edgeUV = float2(0.0f,  1.0f); o1.selected = selected ? 1.0f : 0.0f;
    o2.pos = b; o2.pos.xy += offsetNdc * b.w; o2.edgeUV = float2(1.0f, -1.0f); o2.selected = selected ? 1.0f : 0.0f;
    o3.pos = b; o3.pos.xy -= offsetNdc * b.w; o3.edgeUV = float2(1.0f,  1.0f); o3.selected = selected ? 1.0f : 0.0f;
}

[maxvertexcount(12)]
void main(triangle VSOut input[3], inout TriangleStream<GSOut> stream)
{
    uint v0 = input[0].vertexID;
    uint v1 = input[1].vertexID;
    uint v2 = input[2].vertexID;

    float3 triangleRaw = IniParams[41].xyz;
    uint tri0 = (uint)round(triangleRaw.x);
    uint tri1 = (uint)round(triangleRaw.y);
    uint tri2 = (uint)round(triangleRaw.z);
    float3 bary = saturate(IniParams[42].xyz);

    uint edgeA = 0u;
    uint edgeB = 0u;
    if (PERSISTENT_EDGE_VALID)
    {
        edgeA = (uint)max(round(IniParams[43].x), 0.0f);
        edgeB = (uint)max(round(IniParams[43].y), 0.0f);
    }
    else if (bary.x <= bary.y && bary.x <= bary.z)
    {
        edgeA = tri1;
        edgeB = tri2;
    }
    else if (bary.y <= bary.z)
    {
        edgeA = tri2;
        edgeB = tri0;
    }
    else
    {
        edgeA = tri0;
        edgeB = tri1;
    }

    bool hoverHighlightEnabled = !EDGE_HIGHLIGHT_DISABLED && (TEMP_SELECTION_VALID || PERSISTENT_EDGE_VALID);
    GSOut o0, o1, o2, o3;

    if (input[0].pos.w > 1e-6f && input[1].pos.w > 1e-6f)
    {
        bool selectedByMask = SELECTION_MASK_ACTIVE && SelectedRefCount.Load(v0) > 0u && SelectedRefCount.Load(v1) > 0u;
        bool hovered = hoverHighlightEnabled && SameEdge(v0, v1, edgeA, edgeB);
        bool highlight = selectedByMask || hovered;
        BuildEdgeQuad(input[0].pos, input[1].pos, highlight, o0, o1, o2, o3);
        stream.Append(o0); stream.Append(o1); stream.Append(o2); stream.Append(o3); stream.RestartStrip();
    }
    if (input[1].pos.w > 1e-6f && input[2].pos.w > 1e-6f)
    {
        bool selectedByMask = SELECTION_MASK_ACTIVE && SelectedRefCount.Load(v1) > 0u && SelectedRefCount.Load(v2) > 0u;
        bool hovered = hoverHighlightEnabled && SameEdge(v1, v2, edgeA, edgeB);
        bool highlight = selectedByMask || hovered;
        BuildEdgeQuad(input[1].pos, input[2].pos, highlight, o0, o1, o2, o3);
        stream.Append(o0); stream.Append(o1); stream.Append(o2); stream.Append(o3); stream.RestartStrip();
    }
    if (input[2].pos.w > 1e-6f && input[0].pos.w > 1e-6f)
    {
        bool selectedByMask = SELECTION_MASK_ACTIVE && SelectedRefCount.Load(v2) > 0u && SelectedRefCount.Load(v0) > 0u;
        bool hovered = hoverHighlightEnabled && SameEdge(v2, v0, edgeA, edgeB);
        bool highlight = selectedByMask || hovered;
        BuildEdgeQuad(input[2].pos, input[0].pos, highlight, o0, o1, o2, o3);
        stream.Append(o0); stream.Append(o1); stream.Append(o2); stream.Append(o3); stream.RestartStrip();
    }
}
#endif

#ifdef PIXEL_SHADER
float4 main(GSOut input) : SV_Target1
{
    float aa = max(fwidth(input.edgeUV.y), 0.025f);
    float coverage = 1.0f - smoothstep(1.0f - aa, 1.0f + aa, abs(input.edgeUV.y));
    float3 edgeColor = lerp(float3(0.06f, 0.72f, 1.0f), float3(1.0f, 0.25f, 0.025f), input.selected);
    float alpha = lerp(0.80f, 0.98f, input.selected) * coverage;
    return float4(edgeColor, alpha);
}
#endif
