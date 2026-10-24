// MeshEditorCapture.hlsl
//
// Purpose:
//   Run the game's native VS unchanged, then capture the native VS
//   SV_Position for every logical vertex into a small lookup texture.
//
// The custom draw is NON-INDEXED point_list:
//   primitive 0   -> vertex 0
//   primitive 1   -> vertex 1
//   ...
//   primitive N   -> vertex N
//
// Therefore GS SV_PrimitiveID is the VB vertex index.
//
// The PS is intentionally dumb: it only writes the VS result supplied by GS.
// All actual picking is done later by MeshEditorPick.hlsl in CS.

#define MESH_EDITOR_VERTEX_COUNT 79355u
#define CAPTURE_WIDTH            512u
#define CAPTURE_HEIGHT           256u

struct VS_OUT
{
    float4 pos : SV_Position;
};

struct GS_OUT
{
    float4 pos  : SV_Position;
    float4 data : TEXCOORD0;
};

#ifdef GEOMETRY_SHADER

[maxvertexcount(1)]
void main(
    point VS_OUT input[1],
    uint primitiveID : SV_PrimitiveID,
    inout PointStream<GS_OUT> stream)
{
    uint vertexID = primitiveID;

    if (vertexID >= MESH_EDITOR_VERTEX_COUNT)
        return;

    uint px = vertexID % CAPTURE_WIDTH;
    uint py = vertexID / CAPTURE_WIDTH;

    // Pixel-center in the capture RT, top-left origin.
    float2 pixel = float2(px, py) + 0.5f;

    // Convert to D3D NDC.
    float2 ndc;
    ndc.x = pixel.x / (float)CAPTURE_WIDTH * 2.0f - 1.0f;
    ndc.y = 1.0f - pixel.y / (float)CAPTURE_HEIGHT * 2.0f;

    GS_OUT output;
    output.pos  = float4(ndc, 0.0f, 1.0f);
    output.data = input[0].pos;

    stream.Append(output);
}

#endif

#ifdef PIXEL_SHADER

void main(
    GS_OUT input,
    out float4 result : SV_Target0)
{
    // Raw native VS SV_Position: clip-space x/y/z/w.
    result = input.data;
}

#endif