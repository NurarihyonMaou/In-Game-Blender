// ============================================================================
// MeshEditorSmoothApply.hlsl
// ============================================================================

#define VERTEX_COUNT 79355u
#define POSITION_SCALE 1000000.0f

#define BRUSH_TRI 9u
#define BRUSH_BARY 10u
#define BRUSH_POS 11u

#define PROPORTIONAL_RADIUS IniParams[33].x
#define SMOOTH_STRENGTH IniParams[34].y

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
RWBuffer<float4> EditorState : register(u1);
RWBuffer<uint> Accum : register(u2);
RWBuffer<float4> VertexDelta : register(u3);

Texture1D<float4> IniParams : register(t120);

#define PROPORTIONAL_RADIUS IniParams[33].x
#define SMOOTH_STRENGTH    IniParams[34].y
#define MIRROR_PARAMS      IniParams[36]
#define REPLAY_CENTER      IniParams[26]
#define REPLAY_STATE       IniParams[27]

float3 GetBrushCenter()
{
    float4 tri = EditorState[BRUSH_TRI];
    float4 bary = EditorState[BRUSH_BARY];

    if (tri.w <= 0.5f)
        return 0.0f;

    uint i0 = (uint)max(tri.x + 0.5f, 0.0f);
    uint i1 = (uint)max(tri.y + 0.5f, 0.0f);
    uint i2 = (uint)max(tri.z + 0.5f, 0.0f);

    if (i0 >= VERTEX_COUNT || i1 >= VERTEX_COUNT || i2 >= VERTEX_COUNT)
        return 0.0f;

    float3 p0 = BasePositionBuffer[i0].pos;
    float3 p1 = BasePositionBuffer[i1].pos;
    float3 p2 = BasePositionBuffer[i2].pos;

    return p0 * bary.x + p1 * bary.y + p2 * bary.z;
}

float3 GetActiveBrushCenter()
{
    return REPLAY_STATE.x > 0.5f
        ? REPLAY_CENTER.xyz
        : GetBrushCenter();
}

bool IsReplay()
{
    return EditorState[27].x > 0.5f;
}

float CalculateFalloff(float3 vertexPos, float3 brushPos, float radius)
{
    if (radius <= 0.0f)
        return 0.0f;

    float distance = length(vertexPos - brushPos);
    float t = saturate(distance / radius);

    return 1.0f - t * t * (3.0f - 2.0f * t);
}

float MirrorEnabled()
{
    return MIRROR_PARAMS.x > 0.5f ? 1.0f : 0.0f;
}

uint MirrorAxis()
{
    return (uint)clamp(MIRROR_PARAMS.y + 0.5f, 0.0f, 2.0f);
}

float MirrorPlane()
{
    return MIRROR_PARAMS.z;
}

float MirrorEpsilon()
{
    return max(MIRROR_PARAMS.w, 1e-7f);
}

float3 MirrorPoint(float3 p)
{
    uint axis = MirrorAxis();
    float plane = MirrorPlane();

    if (axis == 0u)
        p.x = 2.0f * plane - p.x;
    else if (axis == 1u)
        p.y = 2.0f * plane - p.y;
    else
        p.z = 2.0f * plane - p.z;

    return p;
}

bool MirrorDistinct(float3 p)
{
    uint axis = MirrorAxis();
    float plane = MirrorPlane();

    float d = axis == 0u ? abs(p.x - plane) :
              axis == 1u ? abs(p.y - plane) :
                           abs(p.z - plane);

    return d > MirrorEpsilon();
}

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    if (vertexID >= VERTEX_COUNT)
        return;

    bool replay = REPLAY_STATE.x > 0.5f;
    float3 brushPos = GetActiveBrushCenter();
    bool brushValid = replay || EditorState[BRUSH_POS].w > 0.5f;

    if (vertexID == 0u)
    {
        if (brushValid)
        {
            EditorState[15] = float4(brushPos, 1.0f);

        }
        else
        {
            EditorState[15] = float4(0, 0, 0, 0);
        }
    }

    if (!brushValid)
        return;

    uint count = Accum[vertexID * 4u + 3u];

    if (count == 0u)
        return;

    float3 basePos = BasePositionBuffer[vertexID].pos;
    float3 currentDelta = VertexDelta[vertexID].xyz;

    float radius = max(PROPORTIONAL_RADIUS, 0.0f);

    float falloff = CalculateFalloff(basePos, brushPos, radius);

    if (MIRROR_PARAMS.x > 0.5f && MirrorDistinct(brushPos))
    {
        float3 mirrorBrushPos = MirrorPoint(brushPos);
        float mirrorFalloff = CalculateFalloff(basePos, mirrorBrushPos, radius);
        falloff = max(falloff, mirrorFalloff);
    }

    if (falloff <= 0.0f)
        return;

    int sumX = (int)Accum[vertexID * 4u + 0u];
    int sumY = (int)Accum[vertexID * 4u + 1u];
    int sumZ = (int)Accum[vertexID * 4u + 2u];

    float3 neighborAverageDelta = float3(
        (float)sumX / (POSITION_SCALE * count),
        (float)sumY / (POSITION_SCALE * count),
        (float)sumZ / (POSITION_SCALE * count)
    );

    float weight = saturate(falloff * SMOOTH_STRENGTH);
    float3 smoothedDelta = lerp(currentDelta, neighborAverageDelta, weight);

    VertexDelta[vertexID] = float4(smoothedDelta, 0.0f);
}