// MeshEditorMaskPaint.hlsl
// Paints the active named mask and keeps ResourceMeshEditorMask as the active-mask cache.

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

StructuredBuffer<PosBuf> BasePositionBuffer : register(t0);
RWBuffer<float> Mask : register(u0);
RWBuffer<float4> EditorState : register(u1);
RWBuffer<float> NamedMasks : register(u2);
Texture1D<float4> IniParams : register(t120);

#define PROPORTIONAL_RADIUS IniParams[33].x
#define INVERT_DIRECTION    IniParams[34].z
#define MASK_STRENGTH       IniParams[37].x
#define ACTIVE_MASK_SLOT    IniParams[37].y
#define MIRROR_PARAMS       IniParams[36]

#define STATE_BRUSH_TRI    9u
#define STATE_BRUSH_BARY   10u
#define STATE_BRUSH_POS    11u
#define STATE_BRUSH_CENTER 17u

#define VERTEX_COUNT    79355u
#define MASK_SLOT_COUNT 8u

uint GetActiveMaskSlot()
{
    int slot = (int)(ACTIVE_MASK_SLOT + 0.5f);
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

    // Use statically addressed components. FXC can reject p[axis] as an l-value
    // with error X3500: array reference is not natively addressable.
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

bool GetBrushCenter(out float3 brushPos)
{
    float4 tri = EditorState[STATE_BRUSH_TRI];
    float4 bary = EditorState[STATE_BRUSH_BARY];
    brushPos = 0.0f;

    // tri.w is the nearest-vertex slot (0, 1, or 2), NOT a validity bit.
    if (tri.x < 0.0f || tri.y < 0.0f || tri.z < 0.0f)
        return false;

    if (tri.x >= (float)VERTEX_COUNT ||
        tri.y >= (float)VERTEX_COUNT ||
        tri.z >= (float)VERTEX_COUNT)
        return false;

    uint i0 = (uint)(tri.x + 0.5f);
    uint i1 = (uint)(tri.y + 0.5f);
    uint i2 = (uint)(tri.z + 0.5f);

    float3 p0 = BasePositionBuffer[i0].pos;
    float3 p1 = BasePositionBuffer[i1].pos;
    float3 p2 = BasePositionBuffer[i2].pos;

    brushPos = p0 * bary.x + p1 * bary.y + p2 * bary.z;
    return true;
}

void ApplyMaskAt(uint vertexID, float3 brushPos)
{
    float radius = max(PROPORTIONAL_RADIUS, 1e-6f);
    float3 vertexPos = BasePositionBuffer[vertexID].pos;
    float distanceToBrush = length(vertexPos - brushPos);

    if (distanceToBrush >= radius)
        return;

    float falloff = 1.0f - smoothstep(0.0f, radius, distanceToBrush);
    float direction = (INVERT_DIRECTION > 0.5f) ? -1.0f : 1.0f;
    float delta = direction * max(MASK_STRENGTH, 0.0f) * falloff;

    uint slot = GetActiveMaskSlot();
    uint namedIndex = slot * VERTEX_COUNT + vertexID;

    // ResourceMeshEditorMask is the currently loaded cache; the named buffer is authoritative.
    float updated = saturate(Mask[vertexID] + delta);
    Mask[vertexID] = updated;
    NamedMasks[namedIndex] = updated;
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    float4 brushState = EditorState[STATE_BRUSH_POS];
    float3 brushPos = 0.0f;
    bool brushValid = brushState.w > 0.5f && GetBrushCenter(brushPos);

    // The recorder reads this dedicated slot at scalar offsets 68..71.
    if (vertexID == 0u)
    {
        if (brushValid)
            EditorState[STATE_BRUSH_CENTER] = float4(brushPos, 1.0f);
        else
            EditorState[STATE_BRUSH_CENTER] = 0.0f;
    }

    if (!brushValid)
        return;

    ApplyMaskAt(vertexID, brushPos);

    if (MirrorEnabled() && MirrorDistinct(brushPos))
        ApplyMaskAt(vertexID, MirrorPoint(brushPos));
}
