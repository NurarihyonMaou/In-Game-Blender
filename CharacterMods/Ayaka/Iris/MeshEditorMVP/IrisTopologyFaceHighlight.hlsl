// Highlight the last temporary-selected triangle.
// VS reads the captured clip-space position by logical vertex ID, so the
// topology pass does not depend on the game's shader output layout.
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> VertexScreen : register(t0);
Buffer<uint> SelectedRefCount : register(t1);

#define VERTEX_COUNT 79355u
#define CAPTURE_WIDTH 512u
#define CAPTURE_HEIGHT 256u
#define SELECTION_VALID (IniParams[40].w > 0.5f)
#define SELECTION_MASK_ACTIVE (IniParams[44].x > 0.5f)
#define SELECTED_TRI (uint3)round(IniParams[41].xyz)

struct VSOut
{
    float4 pos : SV_Position;
    nointerpolation uint vertexID : TEXCOORD0;
};

struct GSOut
{
    float4 pos : SV_Position;
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
bool ContainsVertex(uint v, uint3 tri)
{
    return v == tri.x || v == tri.y || v == tri.z;
}

bool IsSelectedTriangle(uint a, uint b, uint c)
{
    uint3 target = SELECTED_TRI;
    return ContainsVertex(a, target) &&
           ContainsVertex(b, target) &&
           ContainsVertex(c, target);
}

[maxvertexcount(3)]
void main(triangle VSOut input[3], inout TriangleStream<GSOut> stream)
{
    uint v0 = input[0].vertexID;
    uint v1 = input[1].vertexID;
    uint v2 = input[2].vertexID;
    bool hoverFace = SELECTION_VALID && IsSelectedTriangle(v0, v1, v2);
    bool selectedFace = SELECTION_MASK_ACTIVE &&
        SelectedRefCount.Load(v0) > 0u &&
        SelectedRefCount.Load(v1) > 0u &&
        SelectedRefCount.Load(v2) > 0u;
    if (!hoverFace && !selectedFace)
        return;

    [unroll]
    for (uint i = 0u; i < 3u; ++i)
    {
        GSOut output;
        output.pos = input[i].pos;
        stream.Append(output);
    }
    stream.RestartStrip();
}
#endif

#ifdef PIXEL_SHADER
float4 main(GSOut input) : SV_Target1
{
    // Warm orange translucent fill, leaving the underlying texture readable.
    return float4(1.0f, 0.24f, 0.025f, 0.28f);
}
#endif
