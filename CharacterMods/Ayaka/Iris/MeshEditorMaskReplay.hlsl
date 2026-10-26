// MeshEditorMaskReplay.hlsl
// Replays a mask dab into the named-mask slot stored with its stroke.
// IMPORTANT: this intentionally uses BASE positions, matching MeshEditorMaskPaint.hlsl.
// Do not add VertexDelta here unless live painting is changed to use the same deformed space.

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
Buffer<float4> DabHistory : register(t1);
RWBuffer<float> NamedMasks : register(u0);
Texture1D<float4> IniParams : register(t120);

#define BRUSH_POS       IniParams[34].xyz
#define STRENGTH        IniParams[34].w
#define RADIUS          IniParams[35].x
#define MIRROR_PARAMS   IniParams[36]
#define MASK_SLOT_PARAM IniParams[37].x
#define DAB_HISTORY_INDEX IniParams[43].x

#define VERTEX_COUNT    79355u
#define MASK_SLOT_COUNT 8u

uint GetMaskSlot()
{
    int slot = (int)(MASK_SLOT_PARAM + 0.5f);
    return (uint)clamp(slot, 0, (int)MASK_SLOT_COUNT - 1);
}

bool MirrorEnabled()
{
    return MIRROR_PARAMS.x > 0.5f;
}

float3 MirrorPoint(float3 p)
{
    int axis = clamp((int)(MIRROR_PARAMS.y + 0.5f), 0, 2);
    float coordinate = (axis == 0) ? p.x : ((axis == 1) ? p.y : p.z);
    float reflected = 2.0f * MIRROR_PARAMS.z - coordinate;

    if (axis == 0)
        p.x = reflected;
    else if (axis == 1)
        p.y = reflected;
    else
        p.z = reflected;

    return p;
}

bool MirrorDistinct(float3 p)
{
    int axis = clamp((int)(MIRROR_PARAMS.y + 0.5f), 0, 2);
    float coordinate = (axis == 0) ? p.x : ((axis == 1) ? p.y : p.z);
    return abs(coordinate - MIRROR_PARAMS.z) > max(MIRROR_PARAMS.w, 0.0f);
}

void ApplyBrush(uint vertexID, float3 brushPos)
{
    float radius = max(RADIUS, 1e-6f);

    // Must exactly match MeshEditorMaskPaint.hlsl's live-paint position space.
    float3 vertexPos = BasePositionBuffer[vertexID].pos;
    float distanceToBrush = length(vertexPos - brushPos);
    if (distanceToBrush >= radius)
        return;

    float falloff = 1.0f - smoothstep(0.0f, radius, distanceToBrush);
    uint namedIndex = GetMaskSlot() * VERTEX_COUNT + vertexID;
    NamedMasks[namedIndex] = saturate(NamedMasks[namedIndex] + STRENGTH * falloff);
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    uint dabIndex = (uint)max(DAB_HISTORY_INDEX + 0.5f, 0.0f);
    float4 dabRecord = DabHistory[dabIndex];
    if (dabRecord.w <= 0.5f)
        return;
    float3 brushPos = dabRecord.xyz;

    ApplyBrush(vertexID, brushPos);

    if (MirrorEnabled() && MirrorDistinct(brushPos))
        ApplyBrush(vertexID, MirrorPoint(brushPos));
}
