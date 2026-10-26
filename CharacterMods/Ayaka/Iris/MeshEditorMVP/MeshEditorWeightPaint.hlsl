// MeshEditorWeightPaint.hlsl
// GPU-side weight painting for the existing four-influence Blend buffer.
//
// Input resources:
//   t0 = current writable position buffer (base/object space, including sculpt delta)
//   t1 = combined protection mask
//   t2 = immutable source Blend buffer used to recover other influence ratios
//   t3 = one-ring adjacency (count + up to 32 neighbor vertex IDs per vertex)
//   t4 = selected-VG weight snapshot captured before each smooth dab
//   u0 = editable Blend buffer (RWStructuredBuffer<BlendBuf>, stride 32)
//   u1 = MeshEditorState
//
// IniParams:
//   [36] = mirror (enabled, axis, plane, epsilon)
//   [40] = selected VG ID, operation (0 replace / 1 add / 2 subtract / 3 smooth / 4 gradient), strength, target weight
//   [41] = radius, replay flag, falloff mode, reserved
//   [42] = replay brush centre for dab modes, or Gradient start.xyz + valid flag
//   [43] = Gradient end.xyz + valid flag (used only when mode == 4)
//
// Live painting computes its brush centre from the same triangle+barycentric state
// as the mask painter and publishes the centre in EditorState[17] for stroke history.
// Replay receives the saved centre in IniParams[42].

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

StructuredBuffer<PosBuf> PositionBuffer : register(t0);
Buffer<float> ProtectionMask : register(t1);
StructuredBuffer<BlendBuf> OriginalBlend : register(t2);
Buffer<uint> WeightAdjacency : register(t3);
Buffer<float> WeightSnapshot : register(t4);
Buffer<float4> DabHistory : register(t5);
RWStructuredBuffer<BlendBuf> EditableBlend : register(u0);
RWBuffer<float4> EditorState : register(u1);
Texture1D<float4> IniParams : register(t120);

#define PAINT_PARAMS   IniParams[40]
#define PAINT_EXT      IniParams[41]
#define REPLAY_BRUSH   IniParams[42]
#define GRADIENT_END   IniParams[43]
#define REPLAY_DAB_INDEX IniParams[44].x
#define MIRROR_PARAMS  IniParams[36]

#define MAX_WEIGHT_NEIGHBORS 32u
#define WEIGHT_ADJACENCY_STRIDE (MAX_WEIGHT_NEIGHBORS + 1u)

#define STATE_BRUSH_TRI    9u
#define STATE_BRUSH_BARY   10u
#define STATE_BRUSH_POS    11u
#define STATE_BRUSH_CENTER 17u

#define VERTEX_COUNT 79355u

// FXC can reject dynamically indexed vector-component writes as non-addressable
// l-values. Keep component reads/writes explicit for reliable SM5 compilation.
float GetFloat4Component(float4 value, uint index)
{
    if (index == 0u) return value.x;
    if (index == 1u) return value.y;
    if (index == 2u) return value.z;
    return value.w;
}

void SetFloat4Component(inout float4 value, uint index, float component)
{
    if (index == 0u) value.x = component;
    else if (index == 1u) value.y = component;
    else if (index == 2u) value.z = component;
    else value.w = component;
}

int GetInt4Component(int4 value, uint index)
{
    if (index == 0u) return value.x;
    if (index == 1u) return value.y;
    if (index == 2u) return value.z;
    return value.w;
}

void SetInt4Component(inout int4 value, uint index, int component)
{
    if (index == 0u) value.x = component;
    else if (index == 1u) value.y = component;
    else if (index == 2u) value.z = component;
    else value.w = component;
}

uint SelectedVG()
{
    return (uint)clamp((int)(PAINT_PARAMS.x + 0.5f), 0, 117);
}

uint PaintMode()
{
    return (uint)clamp((int)(PAINT_PARAMS.y + 0.5f), 0, 4);
}

uint FalloffMode()
{
    return (uint)clamp((int)(PAINT_EXT.z + 0.5f), 0, 4);
}

bool IsReplay()
{
    return PAINT_EXT.y > 0.5f;
}

bool MirrorEnabled()
{
    return MIRROR_PARAMS.x > 0.5f;
}

float3 MirrorPoint(float3 p)
{
    int axis = clamp((int)(MIRROR_PARAMS.y + 0.5f), 0, 2);
    float plane = MIRROR_PARAMS.z;

    if (axis == 0)
        p.x = 2.0f * plane - p.x;
    else if (axis == 1)
        p.y = 2.0f * plane - p.y;
    else
        p.z = 2.0f * plane - p.z;

    return p;
}

bool MirrorDistinct(float3 p)
{
    int axis = clamp((int)(MIRROR_PARAMS.y + 0.5f), 0, 2);
    float coordinate = axis == 0 ? p.x : (axis == 1 ? p.y : p.z);
    return abs(coordinate - MIRROR_PARAMS.z) > max(MIRROR_PARAMS.w, 0.0f);
}

bool GetLiveBrushCenter(out float3 brushPos)
{
    brushPos = 0.0f;

    float4 brushState = EditorState[STATE_BRUSH_POS];
    if (brushState.w <= 0.5f)
        return false;

    float4 tri = EditorState[STATE_BRUSH_TRI];
    float4 bary = EditorState[STATE_BRUSH_BARY];

    // tri.w is a nearest-vertex slot, not a validity flag.
    if (tri.x < 0.0f || tri.y < 0.0f || tri.z < 0.0f ||
        tri.x >= (float)VERTEX_COUNT ||
        tri.y >= (float)VERTEX_COUNT ||
        tri.z >= (float)VERTEX_COUNT)
        return false;

    uint i0 = (uint)(tri.x + 0.5f);
    uint i1 = (uint)(tri.y + 0.5f);
    uint i2 = (uint)(tri.z + 0.5f);

    float3 p0 = PositionBuffer[i0].pos;
    float3 p1 = PositionBuffer[i1].pos;
    float3 p2 = PositionBuffer[i2].pos;

    brushPos = p0 * bary.x + p1 * bary.y + p2 * bary.z;
    return true;
}

float CalculateFalloff(float distanceToBrush, float radius)
{
    if (radius <= 1e-7f || distanceToBrush >= radius)
        return 0.0f;

    float t = saturate(distanceToBrush / radius);
    uint mode = FalloffMode();
    float falloff;

    if (mode == 0u)
        falloff = 1.0f - t * t * (3.0f - 2.0f * t);
    else if (mode == 1u)
        falloff = 1.0f - t;
    else if (mode == 2u)
    {
        float invT = 1.0f - t;
        falloff = invT * invT * invT;
    }
    else if (mode == 3u)
        falloff = 1.0f;
    else
        falloff = sqrt(max(1.0f - t * t, 0.0f));

    return saturate(falloff);
}

// Keep skinning weights normalized without destroying the other influences when
// the selected VG reaches 1.0. If an earlier version already zeroed the other
// channels, recover their distribution from the immutable source Blend buffer.
// The true single-influence case cannot be subtracted safely without inventing a
// fallback VG, so it remains at weight 1.0 rather than collapsing the mesh.
void NormalizeWeights(inout float4 weights, int4 indices, uint selectedSlot, uint vertexID, uint mode)
{
    weights = max(weights, 0.0f);

    float selectedWeight = saturate(GetFloat4Component(weights, selectedSlot));
    if (mode == 2u)
        selectedWeight = max(selectedWeight, 0.01f);

    // Never let the painted VG completely erase the remaining slot distribution.
    // If no current distribution remains, the original buffer below is the fallback.
    selectedWeight = min(selectedWeight, 0.99f);

    float otherTotal = 0.0f;
    [unroll]
    for (uint k = 0u; k < 4u; ++k)
    {
        if (k != selectedSlot)
            otherTotal += GetFloat4Component(weights, k);
    }

    if (otherTotal <= 1e-8f)
    {
        BlendBuf sourceBlend = OriginalBlend[vertexID];
        float4 sourceWeights = max(sourceBlend.blendWeights, 0.0f);
        int4 sourceIndices = sourceBlend.blendIndices;

        // Restore the original weights for each still-present non-selected VG.
        // The selected slot may have been repurposed to introduce a fifth VG, so
        // match by VG ID rather than blindly copying the same source slot.
        [unroll]
        for (uint k = 0u; k < 4u; ++k)
        {
            if (k == selectedSlot)
                continue;

            int currentVG = GetInt4Component(indices, k);
            float restoredWeight = 0.0f;
            bool foundSameSlot = false;

            if (GetInt4Component(sourceIndices, k) == currentVG && currentVG != GetInt4Component(indices, selectedSlot))
            {
                restoredWeight = GetFloat4Component(sourceWeights, k);
                foundSameSlot = true;
            }

            if (!foundSameSlot && currentVG != GetInt4Component(indices, selectedSlot))
            {
                [unroll]
                for (uint j = 0u; j < 4u; ++j)
                {
                    if (GetInt4Component(sourceIndices, j) == currentVG)
                        restoredWeight += GetFloat4Component(sourceWeights, j);
                }
            }

            SetFloat4Component(weights, k, restoredWeight);
        }

        otherTotal = 0.0f;
        [unroll]
        for (uint k2 = 0u; k2 < 4u; ++k2)
        {
            if (k2 != selectedSlot)
                otherTotal += GetFloat4Component(weights, k2);
        }
    }

    if (otherTotal > 1e-8f)
    {
        float remainingWeight = 1.0f - selectedWeight;
        float scale = remainingWeight / otherTotal;

        [unroll]
        for (uint k3 = 0u; k3 < 4u; ++k3)
        {
            if (k != selectedSlot)
                SetFloat4Component(weights, k3, GetFloat4Component(weights, k3) * scale);
        }

        SetFloat4Component(weights, selectedSlot, selectedWeight);
    }
    else
    {
        // No valid alternative VG exists in either the edited or source Blend.
        // A fully normalized single-influence vertex must remain at weight 1.
        weights = 0.0f;
        SetFloat4Component(weights, selectedSlot, 1.0f);
    }
}

float GetSnapshotWeight(uint vertexID)
{
    return saturate(WeightSnapshot[vertexID]);
}

void ApplyWeightSmoothAt(uint vertexID, float falloff)
{
    if (falloff <= 0.0f)
        return;

    float protection = saturate(ProtectionMask[vertexID]);
    float amount = saturate(PAINT_PARAMS.z) * falloff * (1.0f - protection);
    if (amount <= 0.0f)
        return;

    uint selectedVG = SelectedVG();
    uint adjacencyBase = vertexID * WEIGHT_ADJACENCY_STRIDE;
    uint neighborCount = min(WeightAdjacency[adjacencyBase], MAX_WEIGHT_NEIGHBORS);
    if (neighborCount == 0u)
        return;

    float neighborWeightTotal = 0.0f;
    uint validNeighbors = 0u;
    [loop]
    for (uint n = 0u; n < MAX_WEIGHT_NEIGHBORS; ++n)
    {
        if (n >= neighborCount)
            break;

        uint neighborID = WeightAdjacency[adjacencyBase + 1u + n];
        if (neighborID >= VERTEX_COUNT || neighborID == vertexID)
            continue;

        // This buffer is captured before the dab, so every vertex smooths from
        // the same pre-dab state rather than racing writes from neighboring threads.
        neighborWeightTotal += GetSnapshotWeight(neighborID);
        validNeighbors++;
    }

    if (validNeighbors == 0u)
        return;

    float averageWeight = saturate(neighborWeightTotal / (float)validNeighbors);
    BlendBuf blend = EditableBlend[vertexID];
    float4 weights = saturate(blend.blendWeights);
    int4 indices = blend.blendIndices;

    int selectedSlot = -1;
    uint lowestSlot = 0u;
    float lowestWeight = GetFloat4Component(weights, 0u);

    [unroll]
    for (uint k = 0u; k < 4u; ++k)
    {
        if (GetInt4Component(indices, k) == (int)selectedVG)
            selectedSlot = (int)k;

        float weight = GetFloat4Component(weights, k);
        if (weight < lowestWeight)
        {
            lowestWeight = weight;
            lowestSlot = k;
        }
    }

    // Smooth can introduce the selected VG where neighboring vertices already
    // use it. Do not add an influence when the local neighborhood has no weight.
    if (selectedSlot < 0)
    {
        if (averageWeight <= 1e-8f)
            return;

        selectedSlot = (int)lowestSlot;
        SetInt4Component(indices, lowestSlot, (int)selectedVG);
        SetFloat4Component(weights, lowestSlot, 0.0f);
    }

    uint slot = (uint)selectedSlot;
    float oldWeight = saturate(GetFloat4Component(weights, slot));
    SetFloat4Component(weights, slot, lerp(oldWeight, averageWeight, amount));

    NormalizeWeights(weights, indices, slot, vertexID, 3u);
    blend.blendWeights = weights;
    blend.blendIndices = indices;
    EditableBlend[vertexID] = blend;
}

void ApplyWeightAt(uint vertexID, float falloff)
{
    if (falloff <= 0.0f)
        return;

    float protection = saturate(ProtectionMask[vertexID]);
    float amount = saturate(PAINT_PARAMS.z) * falloff * (1.0f - protection);
    if (amount <= 0.0f)
        return;

    uint selectedVG = SelectedVG();
    uint mode = PaintMode();

    BlendBuf blend = EditableBlend[vertexID];
    float4 weights = saturate(blend.blendWeights);
    int4 indices = blend.blendIndices;

    int selectedSlot = -1;
    uint lowestSlot = 0u;
    float lowestWeight = GetFloat4Component(weights, 0u);

    [unroll]
    for (uint k = 0u; k < 4u; ++k)
    {
        if (GetInt4Component(indices, k) == (int)selectedVG)
            selectedSlot = (int)k;

        float weight = GetFloat4Component(weights, k);
        if (weight < lowestWeight)
        {
            lowestWeight = weight;
            lowestSlot = k;
        }
    }

    // Subtract cannot create a group that is not present on this vertex.
    if (selectedSlot < 0 && (mode == 2u || (mode == 0u && PAINT_PARAMS.w <= 0.0f)))
        return;

    // A vertex can store at most four influences. When adding a fifth,
    // replace the least-weight influence with the selected VG ID.
    if (selectedSlot < 0)
    {
        selectedSlot = (int)lowestSlot;
        SetInt4Component(indices, lowestSlot, (int)selectedVG);
        SetFloat4Component(weights, lowestSlot, 0.0f);
    }

    uint slot = (uint)selectedSlot;
    float oldWeight = saturate(GetFloat4Component(weights, slot));
    float targetWeight = saturate(PAINT_PARAMS.w);

    if (mode == 0u)          // Replace / Paint toward target weight.
        SetFloat4Component(weights, slot, lerp(oldWeight, targetWeight, amount));
    else if (mode == 1u)     // Add.
        SetFloat4Component(weights, slot, min(oldWeight + amount, 1.0f));
    else                     // Subtract.
        SetFloat4Component(weights, slot, max(oldWeight - amount, 0.01f));

    NormalizeWeights(weights, indices, slot, vertexID, mode);
    blend.blendWeights = weights;
    blend.blendIndices = indices;
    EditableBlend[vertexID] = blend;
}

void ApplyWeightGradientAt(uint vertexID)
{
    if (REPLAY_BRUSH.w <= 0.5f || GRADIENT_END.w <= 0.5f)
        return;

    float3 start = REPLAY_BRUSH.xyz;
    float3 end = GRADIENT_END.xyz;
    float3 axis = end - start;
    float axisLengthSq = dot(axis, axis);
    if (axisLengthSq <= 1e-12f)
        return;

    float radius = max(PAINT_EXT.x, 1e-7f);
    float3 vertexPos = PositionBuffer[vertexID].pos;
    float t = saturate(dot(vertexPos - start, axis) / axisLengthSq);
    float3 closest = start + axis * t;
    float falloff = CalculateFalloff(length(vertexPos - closest), radius);

    if (MirrorEnabled() && MirrorDistinct(start))
    {
        float3 mirroredStart = MirrorPoint(start);
        float3 mirroredEnd = MirrorPoint(end);
        float3 mirroredAxis = mirroredEnd - mirroredStart;
        float mirroredLengthSq = dot(mirroredAxis, mirroredAxis);
        if (mirroredLengthSq > 1e-12f)
        {
            float mirroredT = saturate(dot(vertexPos - mirroredStart, mirroredAxis) / mirroredLengthSq);
            float3 mirroredClosest = mirroredStart + mirroredAxis * mirroredT;
            float mirroredFalloff = CalculateFalloff(length(vertexPos - mirroredClosest), radius);
            if (mirroredFalloff > falloff)
            {
                falloff = mirroredFalloff;
                t = mirroredT;
            }
        }
    }

    if (falloff <= 0.0f)
        return;

    float protection = saturate(ProtectionMask[vertexID]);
    float amount = saturate(PAINT_PARAMS.z) * falloff * (1.0f - protection);
    if (amount <= 0.0f)
        return;

    uint selectedVG = SelectedVG();
    BlendBuf blend = EditableBlend[vertexID];
    float4 weights = saturate(blend.blendWeights);
    int4 indices = blend.blendIndices;

    int selectedSlot = -1;
    uint lowestSlot = 0u;
    float lowestWeight = GetFloat4Component(weights, 0u);

    [unroll]
    for (uint k = 0u; k < 4u; ++k)
    {
        if (GetInt4Component(indices, k) == (int)selectedVG)
            selectedSlot = (int)k;

        float weight = GetFloat4Component(weights, k);
        if (weight < lowestWeight)
        {
            lowestWeight = weight;
            lowestSlot = k;
        }
    }

    float targetWeight = saturate(PAINT_PARAMS.w) * t;
    if (selectedSlot < 0 && targetWeight <= 1e-8f)
        return;

    if (selectedSlot < 0)
    {
        selectedSlot = (int)lowestSlot;
        SetInt4Component(indices, lowestSlot, (int)selectedVG);
        SetFloat4Component(weights, lowestSlot, 0.0f);
    }

    uint slot = (uint)selectedSlot;
    float oldWeight = saturate(GetFloat4Component(weights, slot));
    SetFloat4Component(weights, slot, lerp(oldWeight, targetWeight, amount));
    NormalizeWeights(weights, indices, slot, vertexID, 4u);

    blend.blendWeights = weights;
    blend.blendIndices = indices;
    EditableBlend[vertexID] = blend;
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    if (PaintMode() == 4u)
    {
        ApplyWeightGradientAt(vertexID);
        return;
    }

    float3 brushPos = 0.0f;
    bool brushValid;

    if (IsReplay())
    {
        uint dabIndex = (uint)max(REPLAY_DAB_INDEX + 0.5f, 0.0f);
        float4 dabRecord = DabHistory[dabIndex];
        brushPos = dabRecord.xyz;
        brushValid = dabRecord.w > 0.5f;
    }
    else
    {
        brushValid = GetLiveBrushCenter(brushPos);
        if (vertexID == 0u)
        {
            if (brushValid)
                EditorState[STATE_BRUSH_CENTER] = float4(brushPos, 1.0f);
            else
                EditorState[STATE_BRUSH_CENTER] = 0.0f;
        }
    }

    if (!brushValid)
        return;

    float radius = max(PAINT_EXT.x, 1e-7f);
    float3 vertexPos = PositionBuffer[vertexID].pos;
    float falloff = CalculateFalloff(length(vertexPos - brushPos), radius);

    if (MirrorEnabled() && MirrorDistinct(brushPos))
    {
        float3 mirroredBrush = MirrorPoint(brushPos);
        float mirroredFalloff = CalculateFalloff(length(vertexPos - mirroredBrush), radius);
        // Use the strongest coverage so overlapping mirrored brush regions
        // do not apply the same stroke twice.
        falloff = max(falloff, mirroredFalloff);
    }

    if (PaintMode() == 3u)
        ApplyWeightSmoothAt(vertexID, falloff);
    else
        ApplyWeightAt(vertexID, falloff);
}
