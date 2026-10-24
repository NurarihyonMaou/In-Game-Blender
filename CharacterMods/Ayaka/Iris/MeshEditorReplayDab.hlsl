struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

RWBuffer<float4> VertexDelta : register(u0);
StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
Buffer<float> Mask : register(t5);

Texture1D<float4> IniParams : register(t120);

#define DAB_PARAMS      IniParams[34]
#define STROKE_PARAMS   IniParams[35]
#define MIRROR_PARAMS   IniParams[36]

#define TOOL_GRAB       0.0f
#define TOOL_INFLATE    1.0f
#define TOOL_PINCH      3.0f
#define TOOL_CREASE     4.0f
#define TOOL_FLATTEN    5.0f
#define TOOL_SCALE      6.0f

#define VERTEX_COUNT    79355u

float CalculateFalloff(float3 vertexPos, float3 brushPos, float radius)
{
    if (radius <= 0.0f)
        return 0.0f;

    float distance = length(vertexPos - brushPos);
    float t = saturate(distance / radius);

    return 1.0f - t * t * (3.0f - 2.0f * t);
}

float3 GetBaseNormal(uint vertexID)
{
    float3 normal = BasePositionBuffer[vertexID].nor;
    float lenSq = dot(normal, normal);

    if (lenSq <= 1e-12f)
        return float3(0.0f, 1.0f, 0.0f);

    return normal * rsqrt(lenSq);
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

float3 MirrorVector(float3 v)
{
    uint axis = MirrorAxis();

    if (axis == 0u)
        v.x = -v.x;
    else if (axis == 1u)
        v.y = -v.y;
    else
        v.z = -v.z;

    return v;
}

bool MirrorDistinct(float3 p)
{
    uint axis = MirrorAxis();
    float plane = MirrorPlane();
    float d;

    if (axis == 0u)
        d = abs(p.x - plane);
    else if (axis == 1u)
        d = abs(p.y - plane);
    else
        d = abs(p.z - plane);

    return d > MirrorEpsilon();
}

float3 ApplyGrab(
    uint vertexID,
    uint selectedVertex,
    float3 center,
    float3 baseDrag,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = vertexID == selectedVertex
        ? 1.0f
        : CalculateFalloff(vertexPos, center, radius);

    if (falloff <= 0.0f)
        return 0.0f;

    return baseDrag * falloff;
}

float3 ApplyInflate(
    uint vertexID,
    float3 brushPos,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = CalculateFalloff(
        vertexPos,
        brushPos,
        radius);

    if (falloff <= 0.0f)
        return 0.0f;

    return GetBaseNormal(vertexID) * (amount * falloff);
}

float3 ApplyPinch(
    uint vertexID,
    float3 brushPos,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = CalculateFalloff(
        vertexPos,
        brushPos,
        radius);

    if (falloff <= 0.0f)
        return 0.0f;

    float3 normal = GetBaseNormal(vertexID);
    float3 offset = brushPos - vertexPos;

    offset -= normal * dot(offset, normal);

    return offset * (amount * falloff);
}

float3 ApplyCrease(
    uint vertexID,
    float3 brushPos,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = CalculateFalloff(
        vertexPos,
        brushPos,
        radius);

    if (falloff <= 0.0f)
        return 0.0f;

    float narrowFalloff = falloff * falloff * falloff;
    float3 normal = GetBaseNormal(vertexID);

    return -normal * (amount * narrowFalloff);
}

float3 ApplyFlatten(
    uint vertexID,
    float3 brushPos,
    float3 brushNormal,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = CalculateFalloff(
        vertexPos,
        brushPos,
        radius);

    if (falloff <= 0.0f)
        return 0.0f;

    float distance = dot(vertexPos - brushPos, brushNormal);
    float flattenAmount = saturate(amount * 100.0f);

    return -brushNormal * (distance * flattenAmount * falloff);
}

float3 ApplyScale(
    uint vertexID,
    float3 brushPos,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;

    float falloff = CalculateFalloff(
        vertexPos,
        brushPos,
        radius);

    if (falloff <= 0.0f)
        return 0.0f;

    float3 offset = vertexPos - brushPos;

    return offset * (amount * falloff);
}

[numthreads(64, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    if (vertexID >= VERTEX_COUNT)
        return;

    // Keep all contributions from THIS replayed dab separate from the
    // accumulated delta. The mask attenuates the new dab, never the previous
    // VertexDelta; otherwise replay can repeatedly rescale prior edits.
    float3 delta = VertexDelta[vertexID].xyz;
    float3 strokeDelta = 0.0f;

    float radius = max(STROKE_PARAMS.x, 0.0f);
    uint tool = (uint)clamp(STROKE_PARAMS.y + 0.5f, 0.0f, 6.0f);

    if (tool == 0u)
    {
        uint selectedVertex = (uint)max(STROKE_PARAMS.z + 0.5f, 0.0f);

        if (selectedVertex < VERTEX_COUNT)
        {
            float3 baseDrag = DAB_PARAMS.xyz;
            float3 selectedPos = BasePositionBuffer[selectedVertex].pos;

            strokeDelta += ApplyGrab(
                vertexID,
                selectedVertex,
                selectedPos,
                baseDrag,
                radius);

            if (MirrorEnabled() > 0.5f && MirrorDistinct(selectedPos))
            {
                strokeDelta += ApplyGrab(
                    vertexID,
                    selectedVertex,
                    MirrorPoint(selectedPos),
                    MirrorVector(baseDrag),
                    radius);
            }
        }
    }
    else if (tool == 1u)
    {
        float3 brushPos = DAB_PARAMS.xyz;
        float amount = DAB_PARAMS.w;

        strokeDelta += ApplyInflate(
            vertexID,
            brushPos,
            amount,
            radius);

        if (MirrorEnabled() > 0.5f && MirrorDistinct(brushPos))
        {
            strokeDelta += ApplyInflate(
                vertexID,
                MirrorPoint(brushPos),
                amount,
                radius);
        }
    }
    else if (tool == 3u)
    {
        float3 brushPos = DAB_PARAMS.xyz;
        float amount = DAB_PARAMS.w;

        strokeDelta += ApplyPinch(
            vertexID,
            brushPos,
            amount,
            radius);

        if (MirrorEnabled() > 0.5f && MirrorDistinct(brushPos))
        {
            strokeDelta += ApplyPinch(
                vertexID,
                MirrorPoint(brushPos),
                amount,
                radius);
        }
    }
    else if (tool == 4u)
    {
        float3 brushPos = DAB_PARAMS.xyz;
        float amount = DAB_PARAMS.w;

        strokeDelta += ApplyCrease(
            vertexID,
            brushPos,
            amount,
            radius);

        if (MirrorEnabled() > 0.5f && MirrorDistinct(brushPos))
        {
            strokeDelta += ApplyCrease(
                vertexID,
                MirrorPoint(brushPos),
                amount,
                radius);
        }
    }
    else if (tool == 5u)
    {
        float3 brushPos = DAB_PARAMS.xyz;
        float amount = DAB_PARAMS.w;

        uint selectedVertex = (uint)max(STROKE_PARAMS.z + 0.5f, 0.0f);

        if (selectedVertex < VERTEX_COUNT)
        {
            float3 brushNormal = GetBaseNormal(selectedVertex);

            strokeDelta += ApplyFlatten(
                vertexID,
                brushPos,
                brushNormal,
                amount,
                radius);

            if (MirrorEnabled() > 0.5f && MirrorDistinct(brushPos))
            {
                strokeDelta += ApplyFlatten(
                    vertexID,
                    MirrorPoint(brushPos),
                    MirrorVector(brushNormal),
                    amount,
                    radius);
            }
        }
    }
    else if (tool == 6u)
    {
        float3 brushPos = DAB_PARAMS.xyz;
        float amount = DAB_PARAMS.w;

        strokeDelta += ApplyScale(
            vertexID,
            brushPos,
            amount,
            radius);

        if (MirrorEnabled() > 0.5f && MirrorDistinct(brushPos))
        {
            strokeDelta += ApplyScale(
                vertexID,
                MirrorPoint(brushPos),
                amount,
                radius);
        }
    }

    // Mask semantics: 0 = editable; 1 = fully protected.
    float maskFactor = 1.0f - saturate(Mask[vertexID]);
    delta += strokeDelta * maskFactor;

    VertexDelta[vertexID] = float4(delta, 0.0f);
}
