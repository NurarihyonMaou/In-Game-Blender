// MeshEditorPick.hlsl
//
// Software triangle picker.
//
// Inputs:
//   t0 = MeshEditorCapture texture. Texel vertexID contains native VS
//        SV_Position for that vertex.
//   t1 = current/deformed VB0, stride 40.
//   t2 = current IB, R32_UINT.
//
// Output Hover layout:
//   [0] = valid, depth, triangleIndex, indexBase
//   [1] = hit local position xyz, valid
//   [2] = i0, i1, i2, nearestSlot
//   [3] = bary.x, bary.y, bary.z, insideFlag
//   [4] = nearest vertex local position xyz, screen distance squared
//   [5] = screen-right local xyz, basis-valid
//   [6] = screen-down local xyz, conditioning
//   [7] = selected/nearest vertex ID, firstIndex, indexCount, reserved
//
// The picker deliberately does NOT use SV_PrimitiveID from the game's draw.
// It walks the actual active IB itself.

#define THREADS_PER_GROUP 128u
#define VERTEX_COUNT      79355u
#define CAPTURE_WIDTH     512u
#define CAPTURE_HEIGHT    256u
#define HUGE               3.402823e+38f

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

Texture2D<float4> VertexScreen : register(t0);
StructuredBuffer<PosBuf> PositionBuffer : register(t1);
Buffer<uint> IndexBuffer : register(t2);
Texture2D<float4> VisibleDepthMap : register(t4);
RWBuffer<float4> HoverResult : register(u0);

Texture1D<float4> IniParams : register(t120);

// [31].xy = cursor in window/render pixels; INI supplies bottom-origin Y
// [31].zw = width/height used by the render path
#define CURSOR IniParams[31]

// [140].x = first index
// [140].y = index count; 0 = all remaining indices
// [140].z = vertex count (diagnostic/future use)
// [140].w = hit pad in pixels
#define PICK_PARAMS IniParams[140]

groupshared float  sBestDepth[THREADS_PER_GROUP];
groupshared uint   sBestIndexBase[THREADS_PER_GROUP];
groupshared uint   sBestTri[THREADS_PER_GROUP];
groupshared uint   sBestV0[THREADS_PER_GROUP];
groupshared uint   sBestV1[THREADS_PER_GROUP];
groupshared uint   sBestV2[THREADS_PER_GROUP];
groupshared uint   sBestSlot[THREADS_PER_GROUP];
groupshared float3 sBestBary[THREADS_PER_GROUP];
groupshared float  sBestInside[THREADS_PER_GROUP];
groupshared float3 sBestHit[THREADS_PER_GROUP];
groupshared float3 sBestNearestPos[THREADS_PER_GROUP];
groupshared float  sBestNearestDistSq[THREADS_PER_GROUP];
groupshared float3 sBestRight[THREADS_PER_GROUP];
groupshared float3 sBestDown[THREADS_PER_GROUP];
groupshared float  sBestBasisValid[THREADS_PER_GROUP];
groupshared float  sBestConditioning[THREADS_PER_GROUP];

float2 ClipToScreen(float4 clip, float2 screenSize, out float depth, out bool valid)
{
    depth = HUGE;
    valid = false;

    if (clip.w <= 1e-7f)
        return 0.0f;

    float2 ndc = clip.xy / clip.w;

    if (any(abs(ndc) > float2(4.0f, 4.0f)))
        return 0.0f;

    depth = clip.z / clip.w;
    if (depth != depth || abs(depth) > 4.0f)
        return 0.0f;

    float2 screen;
    screen.x = ndc.x * 0.5f * screenSize.x + 0.5f * screenSize.x;
    screen.y = 0.5f * screenSize.y - ndc.y * 0.5f * screenSize.y;

    valid = true;
    return screen;
}

float Cross2(float2 a, float2 b)
{
    return a.x * b.y - a.y * b.x;
}

float3 Barycentric2D(float2 p, float2 a, float2 b, float2 c)
{
    float2 v0 = b - a;
    float2 v1 = c - a;
    float2 v2 = p - a;

    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);

    float denom = d00 * d11 - d01 * d01;

    if (abs(denom) <= 1e-10f)
        return float3(0.0f, 0.0f, 0.0f);

    float v = (d11 * d20 - d01 * d21) / denom;
    float w = (d00 * d21 - d01 * d20) / denom;

    return float3(1.0f - v - w, v, w);
}

bool PointInTriangle(float2 p, float2 a, float2 b, float2 c)
{
    float e0 = Cross2(b - a, p - a);
    float e1 = Cross2(c - b, p - b);
    float e2 = Cross2(a - c, p - c);

    bool hasNeg = e0 < 0.0f || e1 < 0.0f || e2 < 0.0f;
    bool hasPos = e0 > 0.0f || e1 > 0.0f || e2 > 0.0f;

    return !(hasNeg && hasPos);
}

float DistSqPointSegment(float2 p, float2 a, float2 b, out float t)
{
    float2 ab = b - a;
    float denom = max(dot(ab, ab), 1e-10f);
    t = saturate(dot(p - a, ab) / denom);

    float2 d = p - (a + ab * t);
    return dot(d, d);
}

float DistSqPointTriangle(
    float2 p,
    float2 a,
    float2 b,
    float2 c)
{
    if (PointInTriangle(p, a, b, c))
        return 0.0f;

    float t0, t1, t2;
    float d0 = DistSqPointSegment(p, a, b, t0);
    float d1 = DistSqPointSegment(p, b, c, t1);
    float d2 = DistSqPointSegment(p, c, a, t2);

    return min(d0, min(d1, d2));
}

uint2 VertexTexel(uint vertexID)
{
    return uint2(
        vertexID % CAPTURE_WIDTH,
        vertexID / CAPTURE_WIDTH);
}

float4 LoadVertexClip(uint vertexID)
{
    if (vertexID >= VERTEX_COUNT)
        return 0.0f;

    uint2 p = VertexTexel(vertexID);
    if (p.y >= CAPTURE_HEIGHT)
        return 0.0f;

    return VertexScreen.Load(int3(p, 0));
}

// Compare the candidate's projected surface depth with the depth rendered by
// the real Head/Body/Dress draw lists. The depth RT is a 64x64 patch centred
// on CURSOR. A 3x3 neighbourhood handles pixel-centre / top-left edge rules.
bool VisibleDepthMatches(
    float2 candidateScreen,
    float candidateDepth,
    float2 cursor)
{
    // Explicit initialization for shader compiler analysis.
    uint mapWidth = 64u;
    uint mapHeight = 64u;

    VisibleDepthMap.GetDimensions(mapWidth, mapHeight);

    if (mapWidth == 0u || mapHeight == 0u)
        return false;

    float2 patchPosition =
        candidateScreen
        - cursor
        + float2((float)mapWidth, (float)mapHeight) * 0.5f;

    int2 centre = int2(floor(patchPosition));

    float epsilon = max(IniParams[145].x, 0.0001f);

    bool matched = false;

    [unroll]
    for (int oy = -1; oy <= 1; ++oy)
    {
        [unroll]
        for (int ox = -1; ox <= 1; ++ox)
        {
            int2 p = centre + int2(ox, oy);

            if (p.x < 0 ||
                p.y < 0 ||
                p.x >= (int)mapWidth ||
                p.y >= (int)mapHeight)
            {
                continue;
            }

            float4 sampleValue = float4(0.0f, 0.0f, 0.0f, 0.0f);

            sampleValue = VisibleDepthMap.Load(int3(p, 0));

            bool validSample = sampleValue.y > 0.5f;

            float depthDifference =
                abs(sampleValue.x - candidateDepth);

            if (validSample && depthDifference <= epsilon)
                matched = true;
        }
    }

    return matched;
}

float3 SafeNormalize(float3 v, float3 fallback)
{
    float lenSq = dot(v, v);
    if (lenSq <= 1e-12f)
        return fallback;
    return v * rsqrt(lenSq);
}

void BuildScreenBasis(
    float3 p0,
    float3 p1,
    float3 p2,
    float2 s0,
    float2 s1,
    float2 s2,
    out float3 rightLocal,
    out float3 downLocal,
    out float valid,
    out float conditioning)
{
    rightLocal = 0.0f;
    downLocal = 0.0f;
    valid = 0.0f;
    conditioning = 0.0f;

    float3 e1 = p1 - p0;
    float3 e2 = p2 - p0;

    float2 q1 = s1 - s0;
    float2 q2 = s2 - s0;

    float det = Cross2(q1, q2);
    float denom = max(length(q1) * length(q2), 1e-8f);

    conditioning = abs(det) / denom;

    // Need a real projected triangle.  Very edge-on triangles have a badly
    // conditioned inverse and are deliberately rejected for drag basis.
    if (abs(det) <= 1e-5f || conditioning <= 1e-3f)
        return;

    // Solve M*[a,b] = (1,0), where M columns are q1/q2.
    float aR =  q2.y / det;
    float bR = -q1.y / det;

    // Solve M*[a,b] = (0,1).
    float aD = -q2.x / det;
    float bD =  q1.x / det;

    rightLocal = e1 * aR + e2 * bR;
    downLocal  = e1 * aD + e2 * bD;

    if (!all(abs(rightLocal) < float3(1e5f, 1e5f, 1e5f)) ||
        !all(abs(downLocal)  < float3(1e5f, 1e5f, 1e5f)))
    {
        rightLocal = 0.0f;
        downLocal = 0.0f;
        return;
    }

    valid = 1.0f;
}

void ConsiderTriangle(
    uint indexBase,
    uint triIndex,
    float2 cursor,
    float2 screenSize,
    float padPx,
    inout float bestDepth,
    inout uint bestIndexBase,
    inout uint bestTri,
    inout uint bestV0,
    inout uint bestV1,
    inout uint bestV2,
    inout uint bestSlot,
    inout float3 bestBary,
    inout float bestInside,
    inout float3 bestHit,
    inout float3 bestNearestPos,
    inout float bestNearestDistSq,
    inout float3 bestRight,
    inout float3 bestDown,
    inout float bestBasisValid,
    inout float bestConditioning)
{
    uint i0 = IndexBuffer[indexBase + 0u];
    uint i1 = IndexBuffer[indexBase + 1u];
    uint i2 = IndexBuffer[indexBase + 2u];

    if (i0 >= VERTEX_COUNT || i1 >= VERTEX_COUNT || i2 >= VERTEX_COUNT)
        return;

    float3 p0 = PositionBuffer[i0].pos;
    float3 p1 = PositionBuffer[i1].pos;
    float3 p2 = PositionBuffer[i2].pos;

    float depth0, depth1, depth2;
    bool valid0, valid1, valid2;

    float2 s0 = ClipToScreen(LoadVertexClip(i0), screenSize, depth0, valid0);
    float2 s1 = ClipToScreen(LoadVertexClip(i1), screenSize, depth1, valid1);
    float2 s2 = ClipToScreen(LoadVertexClip(i2), screenSize, depth2, valid2);

    if (!valid0 || !valid1 || !valid2)
        return;

    float3 bary = float3(0,0,0);
    float inside = 0;
    bool hit = false;

    if (PointInTriangle(cursor, s0, s1, s2))
    {
        bary = Barycentric2D(cursor, s0, s1, s2);
        inside = 1.0f;
        hit = true;
    }
    else if (padPx > 0.0f)
    {
        float distanceSq = DistSqPointTriangle(cursor, s0, s1, s2);
        if (distanceSq <= padPx * padPx)
        {
            float t0, t1, t2;
            float d0 = DistSqPointSegment(cursor, s0, s1, t0);
            float d1 = DistSqPointSegment(cursor, s1, s2, t1);
            float d2 = DistSqPointSegment(cursor, s2, s0, t2);

            if (d0 <= d1 && d0 <= d2)
                bary = float3(1.0f - t0, t0, 0.0f);
            else if (d1 <= d0 && d1 <= d2)
                bary = float3(0.0f, 1.0f - t1, t1);
            else
                bary = float3(t2, 0.0f, 1.0f - t2);

            inside = 0.0f;
            hit = true;
        }
    }

    if (!hit)
        return;

    // Exact surface hit position in the local VB space.
    float3 hitLocal =
          p0 * bary.x
        + p1 * bary.y
        + p2 * bary.z;

    // Depth at the actual hit point.  For this software picker, barycentric
    // interpolation of NDC depth is a good match to the rasterized surface.
    float hitDepth =
          depth0 * bary.x
        + depth1 * bary.y
        + depth2 * bary.z;

    // The candidate must agree with a fragment rasterized by the real visible
    // mesh draw calls. This rejects triangles hidden behind another surface or
    // belonging to portions absent from the actual draw lists.
    float2 candidateScreen = s0 * bary.x + s1 * bary.y + s2 * bary.z;
    if (!VisibleDepthMatches(candidateScreen, hitDepth, cursor))
        return;

    float dV0 = dot(cursor - s0, cursor - s0);
    float dV1 = dot(cursor - s1, cursor - s1);
    float dV2 = dot(cursor - s2, cursor - s2);

    uint nearestSlot = 0u;
    float nearestDistSq = dV0;

    if (dV1 < nearestDistSq)
    {
        nearestDistSq = dV1;
        nearestSlot = 1u;
    }

    if (dV2 < nearestDistSq)
    {
        nearestDistSq = dV2;
        nearestSlot = 2u;
    }

    // Smaller depth is nearer to the camera.
    if (hitDepth > bestDepth)
        return;

    float3 rightLocal;
    float3 downLocal;
    float basisValid;
    float conditioning;

    BuildScreenBasis(
        p0, p1, p2,
        s0, s1, s2,
        rightLocal, downLocal,
        basisValid, conditioning);

    float3 nearestPos =
        nearestSlot == 0u ? p0 :
        nearestSlot == 1u ? p1 : p2;

    bestDepth          = hitDepth;
    bestIndexBase      = indexBase;
    bestTri            = triIndex;
    bestV0             = i0;
    bestV1             = i1;
    bestV2             = i2;
    bestSlot           = nearestSlot;
    bestBary           = bary;
    bestInside         = inside;
    bestHit            = hitLocal;
    bestNearestPos     = nearestPos;
    bestNearestDistSq  = nearestDistSq;
    bestRight          = rightLocal;
    bestDown           = downLocal;
    bestBasisValid     = basisValid;
    bestConditioning   = conditioning;
}

[numthreads(THREADS_PER_GROUP, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID,
          uint3 groupThreadID    : SV_GroupThreadID)
{
    uint tid = groupThreadID.x;

    float2 screenSize = max(CURSOR.zw, float2(1.0f, 1.0f));
    // The INI binds y31 = window_height - cursor_window_y (bottom-origin).
    // ClipToScreen() uses top-left coordinates, so convert back here.
    float2 cursor = float2(CURSOR.x, screenSize.y - CURSOR.y);

    uint ibCount;
    IndexBuffer.GetDimensions(ibCount);

    uint firstIndex = (uint)max(PICK_PARAMS.x, 0.0f);
    uint requestedCount = (uint)max(PICK_PARAMS.y, 0.0f);

    if (firstIndex > ibCount)
        firstIndex = ibCount;

    uint usableCount = ibCount - firstIndex;
    uint indexCount = requestedCount == 0u
        ? usableCount
        : min(requestedCount, usableCount);

    indexCount -= indexCount % 3u;

    float padPx = max(PICK_PARAMS.w, 0.0f);

    float bestDepth = HUGE;
    uint bestIndexBase = 0u;
    uint bestTri = 0u;
    uint bestV0 = 0u;
    uint bestV1 = 0u;
    uint bestV2 = 0u;
    uint bestSlot = 0u;
    float3 bestBary = 0.0f;
    float bestInside = 0.0f;
    float3 bestHit = 0.0f;
    float3 bestNearestPos = 0.0f;
    float bestNearestDistSq = HUGE;
    float3 bestRight = 0.0f;
    float3 bestDown = 0.0f;
    float bestBasisValid = 0.0f;
    float bestConditioning = 0.0f;

    uint triangleCount = indexCount / 3u;

    [loop]
    for (uint tri = tid; tri < triangleCount; tri += THREADS_PER_GROUP)
    {
        uint indexBase = firstIndex + tri * 3u;

        ConsiderTriangle(
            indexBase,
            tri,
            cursor,
            screenSize,
            padPx,
            bestDepth,
            bestIndexBase,
            bestTri,
            bestV0,
            bestV1,
            bestV2,
            bestSlot,
            bestBary,
            bestInside,
            bestHit,
            bestNearestPos,
            bestNearestDistSq,
            bestRight,
            bestDown,
            bestBasisValid,
            bestConditioning);
    }

    bool haveHit = bestDepth < HUGE;

    sBestDepth[tid] = bestDepth;
    sBestIndexBase[tid] = bestIndexBase;
    sBestTri[tid] = bestTri;
    sBestV0[tid] = bestV0;
    sBestV1[tid] = bestV1;
    sBestV2[tid] = bestV2;
    sBestSlot[tid] = bestSlot;
    sBestBary[tid] = bestBary;
    sBestInside[tid] = bestInside;
    sBestHit[tid] = bestHit;
    sBestNearestPos[tid] = bestNearestPos;
    sBestNearestDistSq[tid] = bestNearestDistSq;
    sBestRight[tid] = bestRight;
    sBestDown[tid] = bestDown;
    sBestBasisValid[tid] = bestBasisValid;
    sBestConditioning[tid] = bestConditioning;

    if (tid == 0u)
    {
        HoverResult[0] = float4(-1.0f, HUGE, 0.0f, 0.0f);
        HoverResult[1] = 0.0f;
        HoverResult[2] = 0.0f;
        HoverResult[3] = 0.0f;
        HoverResult[4] = 0.0f;
        HoverResult[5] = 0.0f;
        HoverResult[6] = 0.0f;
        HoverResult[7] = 0.0f;
    }

    GroupMemoryBarrierWithGroupSync();

    for (uint stride = THREADS_PER_GROUP / 2u; stride > 0u; stride >>= 1u)
    {
        if (tid < stride)
        {
            if (sBestDepth[tid + stride] < sBestDepth[tid])
            {
                sBestDepth[tid] = sBestDepth[tid + stride];
                sBestIndexBase[tid] = sBestIndexBase[tid + stride];
                sBestTri[tid] = sBestTri[tid + stride];
                sBestV0[tid] = sBestV0[tid + stride];
                sBestV1[tid] = sBestV1[tid + stride];
                sBestV2[tid] = sBestV2[tid + stride];
                sBestSlot[tid] = sBestSlot[tid + stride];
                sBestBary[tid] = sBestBary[tid + stride];
                sBestInside[tid] = sBestInside[tid + stride];
                sBestHit[tid] = sBestHit[tid + stride];
                sBestNearestPos[tid] = sBestNearestPos[tid + stride];
                sBestNearestDistSq[tid] = sBestNearestDistSq[tid + stride];
                sBestRight[tid] = sBestRight[tid + stride];
                sBestDown[tid] = sBestDown[tid + stride];
                sBestBasisValid[tid] = sBestBasisValid[tid + stride];
                sBestConditioning[tid] = sBestConditioning[tid + stride];
            }
        }

        GroupMemoryBarrierWithGroupSync();
    }

    if (tid == 0u && sBestDepth[0] < HUGE)
    {
        uint selectedVertex =
            sBestSlot[0] == 0u ? sBestV0[0] :
            sBestSlot[0] == 1u ? sBestV1[0] :
                                  sBestV2[0];

        HoverResult[0] = float4(
            1.0f,
            sBestDepth[0],
            (float)sBestTri[0],
            (float)sBestIndexBase[0]);

        HoverResult[1] = float4(sBestHit[0], 1.0f);

        HoverResult[2] = float4(
            (float)sBestV0[0],
            (float)sBestV1[0],
            (float)sBestV2[0],
            (float)sBestSlot[0]);

        HoverResult[3] = float4(
            sBestBary[0],
            sBestInside[0]);

        HoverResult[4] = float4(
            sBestNearestPos[0],
            sBestNearestDistSq[0]);

        HoverResult[5] = float4(
            sBestRight[0],
            sBestBasisValid[0]);

        HoverResult[6] = float4(
            sBestDown[0],
            sBestConditioning[0]);

        HoverResult[7] = float4(
            (float)selectedVertex,
            (float)firstIndex,
            (float)indexCount,
            1.0f);
    }
}
