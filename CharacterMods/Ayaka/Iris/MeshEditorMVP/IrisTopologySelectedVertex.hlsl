// Highlight the last temporary-selected vertex with a larger antialiased marker.
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> VertexScreen : register(t0);
Buffer<uint> SelectedRefCount : register(t1);

#define VERTEX_COUNT 79355u
#define CAPTURE_WIDTH 512u
#define CAPTURE_HEIGHT 256u
#define SCREEN_WIDTH max(IniParams[31].z, 1.0f)
#define SCREEN_HEIGHT max(IniParams[31].w, 1.0f)
#define SELECTED_VERTEX (uint)round(IniParams[40].x)
#define SELECTION_VALID (IniParams[40].y > 0.5f)
#define SELECTION_MASK_ACTIVE (IniParams[44].x > 0.5f)

struct VSOut
{
    float4 pos : SV_Position;
    nointerpolation uint vertexID : TEXCOORD0;
};

struct GSOut
{
    float4 pos : SV_Position;
    float2 uv : TEXCOORD0;
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
[maxvertexcount(4)]
void main(point VSOut input[1], inout TriangleStream<GSOut> stream)
{
    bool pickedByMask = SELECTION_MASK_ACTIVE && SelectedRefCount.Load(input[0].vertexID) > 0u;
    bool hoveredVertex = SELECTION_VALID && input[0].vertexID == SELECTED_VERTEX;
    if (!pickedByMask && !hoveredVertex)
        return;

    float4 center = input[0].pos;
    if (center.w <= 1e-6f)
        return;

    const float radiusPixels = 7.0f;
    float2 radiusNdc = float2(2.0f * radiusPixels / SCREEN_WIDTH, 2.0f * radiusPixels / SCREEN_HEIGHT);
    GSOut o;

    o.pos = center; o.pos.xy += float2(-radiusNdc.x, radiusNdc.y) * center.w; o.uv = float2(-1.0f, -1.0f); stream.Append(o);
    o.pos = center; o.pos.xy += float2( radiusNdc.x, radiusNdc.y) * center.w; o.uv = float2( 1.0f, -1.0f); stream.Append(o);
    o.pos = center; o.pos.xy += float2(-radiusNdc.x,-radiusNdc.y) * center.w; o.uv = float2(-1.0f,  1.0f); stream.Append(o);
    o.pos = center; o.pos.xy += float2( radiusNdc.x,-radiusNdc.y) * center.w; o.uv = float2( 1.0f,  1.0f); stream.Append(o);
    stream.RestartStrip();
}
#endif

#ifdef PIXEL_SHADER
float4 main(GSOut input) : SV_Target1
{
    float distance = length(input.uv);
    float aa = max(fwidth(distance), 1e-4f);
    float outer = 1.0f - smoothstep(1.0f - aa, 1.0f + aa, distance);
    float inner = 1.0f - smoothstep(0.40f - aa, 0.50f + aa, distance);
    float rim = smoothstep(0.58f - aa, 0.70f + aa, distance) * outer;
    float3 color = lerp(float3(1.0f, 0.23f, 0.035f), float3(1.0f, 0.95f, 0.75f), rim);
    color = lerp(color, float3(1.0f, 0.24f, 0.025f), inner);
    return float4(color, outer * 0.98f);
}
#endif
