// ============================================================================*

// MeshEditorDeform.hlsl*

// ============================================================================*

//*

// VertexDelta      = BASE SPACE.*

// WritablePosition = BASE SPACE.*

//*

// Mouse interaction = POSED / SKINNED.*

//*

// Tools:*

//   0 = Grab*

//   1 = Inflate*

//   2 = Smooth*

//   3 = Pinch*

//   4 = Crease*

//   5 = Flatten*

//   6 = Scale*

//*

// Smooth is handled by dedicated Smooth passes.*

//*

// Falloff Modes:*

//   0 = Smooth*

//   1 = Linear*

//   2 = Sharp*

//   3 = Constant*

//   4 = Sphere*

//*

// Dab State:*

//   [15].xyz = Dab Position / Grab Delta*

//   [15].w   = Dab Valid*

//   [16].x   = Dab Strength*

//   [16].y   = Dab Radius*

//*

// Mask:*

//   0 = fully editable*

//   1 = fully protected*

//*

// ============================================================================*

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

struct BlendBuf
{
    float4 blendWeights;
    int4 blendIndices;
};

Buffer<float4> BoneMatrices : register(t0);
RWBuffer<float4> VertexDelta : register(u1);
StructuredBuffer<PosBuf> BasePositionBuffer : register(t3);
StructuredBuffer<BlendBuf> Blend : register(t4);
RWStructuredBuffer<PosBuf> WritablePosition : register(u0);
RWBuffer<float4> EditorState : register(u2);
Buffer<float> Mask : register(t5);
Texture1D<float4> IniParams : register(t120);

#define PROPORTIONAL_RADIUS IniParams[33].x
#define FALLOFF_MODE        IniParams[33].y

#define MESH_EDITOR_TOOL    IniParams[34].x
#define SCULPT_STRENGTH     IniParams[34].y
#define INVERT_DIRECTION    IniParams[34].z

#define TOOL_GRAB           0.0f
#define TOOL_INFLATE        1.0f
#define TOOL_SMOOTH         2.0f
#define TOOL_PINCH          3.0f
#define TOOL_CREASE         4.0f
#define TOOL_FLATTEN        5.0f
#define TOOL_SCALE          6.0f

#define VERTEX_COUNT        79355u

#define STATE_BRUSH_TRI     9u
#define STATE_BRUSH_BARY    10u
#define STATE_BRUSH_POS     11u
#define STATE_DAB_DATA      15u
#define STATE_DAB_META      16u

#define MIRROR_PARAMS       IniParams[36]

// ============================================================================*

// MASK*

// ============================================================================*

float GetMaskFactor(uint vertexID)
{
    return 1.0f - saturate(Mask[vertexID]);
}

float3 ApplyMask(uint vertexID, float3 delta)
{
    return delta * GetMaskFactor(vertexID);
}

// ============================================================================*

// BRUSH CENTER*

// ============================================================================*

float3 GetBrushCenter()
{
    float4 tri = EditorState[STATE_BRUSH_TRI];
    float4 bary = EditorState[STATE_BRUSH_BARY];

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

bool BrushValid()
{
    return EditorState[STATE_BRUSH_POS].w > 0.5f;
}

// ============================================================================*

// BONE / SKINNING*

// ============================================================================*

float3x3 LoadBoneMatrix3x3(uint bone)
{
    uint i = bone * 3u;

    return float3x3(
        BoneMatrices[i + 0u].xyz,
        BoneMatrices[i + 1u].xyz,
        BoneMatrices[i + 2u].xyz
    );
}

float3x3 GetSkinMatrix(uint vertexID)
{
    BlendBuf b = Blend[vertexID];

    float3x3 m0 = LoadBoneMatrix3x3((uint)b.blendIndices.x);
    float3x3 m1 = LoadBoneMatrix3x3((uint)b.blendIndices.y);
    float3x3 m2 = LoadBoneMatrix3x3((uint)b.blendIndices.z);
    float3x3 m3 = LoadBoneMatrix3x3((uint)b.blendIndices.w);

    return b.blendWeights.x * m0
         + b.blendWeights.y * m1
         + b.blendWeights.z * m2
         + b.blendWeights.w * m3;
}

// ============================================================================*

// INVERSE 3x3*

// ============================================================================*

float3x3 Inverse3x3(float3x3 m)
{
    float a = m[0][0], b = m[0][1], c = m[0][2];
    float d = m[1][0], e = m[1][1], f = m[1][2];
    float g = m[2][0], h = m[2][1], i = m[2][2];

    float A = e * i - f * h;
    float B = c * h - b * i;
    float C = b * f - c * e;
    float D = f * g - d * i;
    float E = a * i - c * g;
    float F = c * d - a * f;
    float G = d * h - e * g;
    float H = b * g - a * h;
    float I = a * e - b * d;

    float det = a * A + b * D + c * G;

    if (abs(det) < 1e-8f)
    {
        return float3x3(
            1.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f,
            0.0f, 0.0f, 1.0f
        );
    }

    float invDet = 1.0f / det;

    return float3x3(
        A * invDet, B * invDet, C * invDet,
        D * invDet, E * invDet, F * invDet,
        G * invDet, H * invDet, I * invDet
    );
}

// ============================================================================*

// POSED -> BASE*

// ============================================================================*

float3 PosedToBaseDelta(uint vertexID, float3 posedDelta)
{
    return mul(Inverse3x3(GetSkinMatrix(vertexID)), posedDelta);
}

// ============================================================================*

// FALLOFF*

// ============================================================================*

float CalculateFalloff(float3 vertexPos, float3 brushPos, float radius)
{
    if (radius <= 0.0f)
        return 0.0f;

    float distance = length(vertexPos - brushPos);
    float t = saturate(distance / radius);
    float falloff = 0.0f;

    uint mode = (uint)clamp(FALLOFF_MODE + 0.5f, 0.0f, 4.0f);

    if (mode == 0u)
    {
        // Smooth - current behavior.
        falloff = 1.0f - t * t * (3.0f - 2.0f * t);
    }
    else if (mode == 1u)
    {
        // Linear.
        falloff = 1.0f - t;
    }
    else if (mode == 2u)
    {
        // Sharp.
        float invT = 1.0f - t;
        falloff = invT * invT * invT;
    }
    else if (mode == 3u)
    {
        // Constant.
        falloff = t < 1.0f ? 1.0f : 0.0f;
    }
    else
    {
        // Sphere.
        falloff = sqrt(max(1.0f - t * t, 0.0f));
    }

    return saturate(falloff);
}

// ============================================================================*

// BASE NORMAL*

// ============================================================================*

float3 GetBaseNormal(uint vertexID)
{
    float3 normal = BasePositionBuffer[vertexID].nor;
    float lenSq = dot(normal, normal);

    if (lenSq <= 1e-12f)
        return float3(0.0f, 1.0f, 0.0f);

    return normal * rsqrt(lenSq);
}

// ============================================================================*

// MIRROR*

// ============================================================================*

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

// ============================================================================*

// GRAB*

// ============================================================================*

float3 ApplyGrabAt(
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

// ============================================================================*

// SCULPT TOOLS*

// ============================================================================*

float3 ApplyInflate(
    uint vertexID,
    float3 brushPos,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;
    float falloff = CalculateFalloff(vertexPos, brushPos, radius);

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
    float falloff = CalculateFalloff(vertexPos, brushPos, radius);

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
    float falloff = CalculateFalloff(vertexPos, brushPos, radius);

    if (falloff <= 0.0f)
        return 0.0f;

    float narrowFalloff = falloff * falloff * falloff;

    return -GetBaseNormal(vertexID) * (amount * narrowFalloff);
}

float3 ApplyFlatten(
    uint vertexID,
    float3 brushPos,
    float3 brushNormal,
    float amount,
    float radius)
{
    float3 vertexPos = BasePositionBuffer[vertexID].pos;
    float falloff = CalculateFalloff(vertexPos, brushPos, radius);

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
    float falloff = CalculateFalloff(vertexPos, brushPos, radius);

    if (falloff <= 0.0f)
        return 0.0f;

    return (vertexPos - brushPos) * (amount * falloff);
}

// ============================================================================*

// COMMON SCULPT DISPATCH*

// ============================================================================*

float3 ApplySculptDab(
    uint vertexID,
    uint selectedVertex,
    float3 brushPos,
    float amount,
    float radius)
{
    float3 result = 0.0f;

    if (MESH_EDITOR_TOOL == TOOL_INFLATE)
        result = ApplyInflate(vertexID, brushPos, amount, radius);
    else if (MESH_EDITOR_TOOL == TOOL_PINCH)
        result = ApplyPinch(vertexID, brushPos, amount, radius);
    else if (MESH_EDITOR_TOOL == TOOL_CREASE)
        result = ApplyCrease(vertexID, brushPos, amount, radius);
    else if (MESH_EDITOR_TOOL == TOOL_FLATTEN)
        result = ApplyFlatten(
            vertexID,
            brushPos,
            GetBaseNormal(selectedVertex),
            amount,
            radius
        );
    else if (MESH_EDITOR_TOOL == TOOL_SCALE)
        result = ApplyScale(vertexID, brushPos, amount, radius);

    return result;
}

// ============================================================================*

// DAB STATE*

// ============================================================================*

void WriteDabState(float3 brushPos, float amount, float radius)
{
    EditorState[STATE_DAB_DATA] = float4(brushPos, 1.0f);
    EditorState[STATE_DAB_META] = float4(amount, radius, 0.0f, 0.0f);
}

void ClearDabState()
{
    EditorState[STATE_DAB_DATA] = 0.0f;
    EditorState[STATE_DAB_META] = 0.0f;
}

// ============================================================================*

// MAIN*

// ============================================================================*

[numthreads(64, 1, 1)]

void main(uint3 id : SV_DispatchThreadID)
{
    uint vertexID = id.x;

    if (vertexID >= VERTEX_COUNT)
        return;

    PosBuf v = WritablePosition[vertexID];

    float4 selection = EditorState[0];
    float4 dragState = EditorState[4];
    float4 commitState = EditorState[5];

    bool selectionValid = selection.y > 0.5f;
    bool dragValid = dragState.w > 0.5f;
    bool commit = commitState.w > 0.5f;
    bool hold = selection.z > 0.5f;

    float3 persistentDelta = VertexDelta[vertexID].xyz;
    float3 transientDelta = 0.0f;

    if (selectionValid && dragValid)
    {
        uint selectedVertex = (uint)max(selection.x + 0.5f, 0.0f);

        if (selectedVertex < VERTEX_COUNT)
        {
            float radius = max(PROPORTIONAL_RADIUS, 0.0f);

            // ----------------------------------------------------------------*

            // GRAB*

            // ----------------------------------------------------------------*

            if (MESH_EDITOR_TOOL == TOOL_GRAB)
            {
                float3 baseDrag = PosedToBaseDelta(selectedVertex, dragState.xyz);
                float3 selectedPos = BasePositionBuffer[selectedVertex].pos;

                transientDelta = ApplyGrabAt(
                    vertexID,
                    selectedVertex,
                    selectedPos,
                    baseDrag,
                    radius
                );

                if (MirrorEnabled() > 0.5f && MirrorDistinct(selectedPos))
                {
                    transientDelta += ApplyGrabAt(
                        vertexID,
                        selectedVertex,
                        MirrorPoint(selectedPos),
                        MirrorVector(baseDrag),
                        radius
                    );
                }

                transientDelta = ApplyMask(vertexID, transientDelta);

                if (commit && vertexID == selectedVertex)
                {
                    EditorState[STATE_DAB_DATA] = float4(baseDrag, 1.0f);
                    EditorState[STATE_DAB_META] = float4(0.0f, radius, 0.0f, 0.0f);
                }

                if (commit)
                {
                    persistentDelta += transientDelta;
                    VertexDelta[vertexID] = float4(persistentDelta, 0.0f);
                    transientDelta = 0.0f;
                }
            }

            // ----------------------------------------------------------------*

            // SCULPT*

            // ----------------------------------------------------------------*

            else if (hold &&
                     (MESH_EDITOR_TOOL == TOOL_INFLATE ||
                      MESH_EDITOR_TOOL == TOOL_PINCH ||
                      MESH_EDITOR_TOOL == TOOL_CREASE ||
                      MESH_EDITOR_TOOL == TOOL_FLATTEN ||
                      MESH_EDITOR_TOOL == TOOL_SCALE))
            {
                float3 brushPos = GetBrushCenter();
                bool brushValid = BrushValid();

                if (vertexID == selectedVertex)
                {
                    if (brushValid)
                    {
                        WriteDabState(
                            brushPos,
                            SCULPT_STRENGTH,
                            radius
                        );
                    }
                    else
                    {
                        ClearDabState();
                    }
                }

                if (brushValid)
                {
                    float3 dabDelta = ApplySculptDab(
                        vertexID,
                        selectedVertex,
                        brushPos,
                        SCULPT_STRENGTH,
                        radius
                    );

                    if (MirrorEnabled() > 0.5f && MirrorDistinct(brushPos))
                    {
                        dabDelta += ApplySculptDab(
                            vertexID,
                            selectedVertex,
                            MirrorPoint(brushPos),
                            SCULPT_STRENGTH,
                            radius
                        );
                    }

                    dabDelta = ApplyMask(vertexID, dabDelta);

                    persistentDelta +=
                        (!INVERT_DIRECTION) ? dabDelta : -dabDelta;

                    VertexDelta[vertexID] = float4(
                        persistentDelta,
                        0.0f
                    );
                }
            }
        }
    }

    // ========================================================================*

    // FINAL POSITION*

    // ========================================================================*

    v.pos += persistentDelta + transientDelta;
    WritablePosition[vertexID] = v;
}