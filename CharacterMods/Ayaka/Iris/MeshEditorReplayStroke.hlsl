// ============================================================================
// MeshEditorReplayStroke.hlsl
// ============================================================================
//
// Replay one stored Mesh Editor stroke into VertexDelta.
//
// IniParams:
//   [34].x = selected vertex ID
//   [35].xyz = stroke payload
//   [35].w = radius
//   [36].x = tool
//
// Payload:
//
//   Grab:
//       xyz = BASE SPACE drag delta
//
//   Inflate:
//       x = scalar inflate amount
//       y/z = 0
// ============================================================================

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

Texture1D<float4> IniParams : register(t120);

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
RWBuffer<float4> VertexDelta : register(u0);

#define STROKE_VERTEX IniParams[34].x
#define STROKE_DX     IniParams[35].x
#define STROKE_DY     IniParams[35].y
#define STROKE_DZ     IniParams[35].z
#define STROKE_RADIUS IniParams[35].w
#define STROKE_TOOL   IniParams[36].x

#define TOOL_GRAB     0.0f
#define TOOL_INFLATE  1.0f

float CalculateFalloff(float3 vertexPos, float3 selectedPos, float radius)
{
    if (radius <= 0.0f)
        return 0.0f;

    float distance = length(vertexPos - selectedPos);
    float t = saturate(distance / radius);

    return 1.0f - t * t * (3.0f - 2.0f * t);
}

float3 GetBaseNormal(uint vertexID)
{
    float3 normal = BasePositionBuffer[vertexID].nor;
    float lenSq = dot(normal, normal);

    if (lenSq < 1e-12f)
        return float3(0.0f, 1.0f, 0.0f);

    return normalize(normal);
}

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    if (vertexID >= 79355u)
        return;

    uint selectedVertex = (uint)max(STROKE_VERTEX + 0.5f, 0.0f);

    if (selectedVertex >= 79355u)
        return;

    float3 selectedPos = BasePositionBuffer[selectedVertex].pos;
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = vertexID == selectedVertex
        ? 1.0f
        : CalculateFalloff(vertexPos, selectedPos, STROKE_RADIUS);

    float3 strokeDelta = 0.0f;

    if (STROKE_TOOL == TOOL_GRAB)
    {
        strokeDelta = float3(STROKE_DX, STROKE_DY, STROKE_DZ);
    }
    else if (STROKE_TOOL == TOOL_INFLATE)
    {
        float3 normal = GetBaseNormal(vertexID);
        strokeDelta = normal * STROKE_DX;
    }

    float3 persistentDelta = VertexDelta[vertexID].xyz;
    persistentDelta += strokeDelta * falloff;

    VertexDelta[vertexID] = float4(persistentDelta, 0.0f);
}