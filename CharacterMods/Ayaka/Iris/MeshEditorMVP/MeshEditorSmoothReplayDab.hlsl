// ============================================================================
// MeshEditorSmoothReplayDab.hlsl
// ============================================================================

#define VERTEX_COUNT 79355u
#define SMOOTH_SCALE 1000000.0f

#define DAB_PARAMS  IniParams[34]
#define DAB_RADIUS  IniParams[35].x

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
RWBuffer<uint> SmoothAccum : register(u1);
RWBuffer<float4> VertexDelta : register(u2);

Texture1D<float4> IniParams : register(t120);

float CalculateFalloff(float3 vertexPos, float3 brushPos, float radius)
{
    if (radius <= 0.0f)
        return 0.0f;

    float distance = length(vertexPos - brushPos);
    float t = saturate(distance / radius);

    return 1.0f - t * t * (3.0f - 2.0f * t);
}

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    if (vertexID >= VERTEX_COUNT)
        return;

    uint count = SmoothAccum[vertexID * 4u + 3u];

    if (count == 0u)
        return;

    float3 brushPos = DAB_PARAMS.xyz;
    float strength = DAB_PARAMS.w;
    float radius = DAB_RADIUS;

    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = CalculateFalloff(vertexPos, brushPos, radius);

    if (falloff <= 0.0f)
        return;

    int sumX = (int)SmoothAccum[vertexID * 4u + 0u];
    int sumY = (int)SmoothAccum[vertexID * 4u + 1u];
    int sumZ = (int)SmoothAccum[vertexID * 4u + 2u];

    float3 neighborAverage = float3(
        (float)sumX / (SMOOTH_SCALE * count),
        (float)sumY / (SMOOTH_SCALE * count),
        (float)sumZ / (SMOOTH_SCALE * count)
    );

    float3 current = VertexDelta[vertexID].xyz;
    float weight = saturate(falloff * strength);

    VertexDelta[vertexID] = float4(
        lerp(current, neighborAverage, weight),
        0.0f
    );
}