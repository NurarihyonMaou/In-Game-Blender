// Topology-aware one-ring weight accumulation for Weight Paint Smooth.
// Each triangle contributes the two other vertex weights to each corner.
struct BlendBuf
{
    float4 blendWeights;
    int4 blendIndices;
};

Buffer<uint> CombinedIB : register(t0);
StructuredBuffer<BlendBuf> EditableBlend : register(t1);
RWBuffer<uint> SmoothAccum : register(u0); // per vertex: fixed-point sum, neighbour contribution count
Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355u
#define INDEX_COUNT 240852u
#define WEIGHT_SCALE 65535.0f

float SelectedWeight(BlendBuf blend, int selectedVG)
{
    float value = 0.0f;
    if (blend.blendIndices.x == selectedVG) value = blend.blendWeights.x;
    else if (blend.blendIndices.y == selectedVG) value = blend.blendWeights.y;
    else if (blend.blendIndices.z == selectedVG) value = blend.blendWeights.z;
    else if (blend.blendIndices.w == selectedVG) value = blend.blendWeights.w;
    return saturate(value);
}

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint triangleID = tid.x;
    if (triangleID >= INDEX_COUNT / 3u) return;

    uint i = triangleID * 3u;
    uint a = CombinedIB[i + 0u];
    uint b = CombinedIB[i + 1u];
    uint c = CombinedIB[i + 2u];
    if (a >= VERTEX_COUNT || b >= VERTEX_COUNT || c >= VERTEX_COUNT) return;
    if (a == b || b == c || a == c) return;

    int selectedVG = (int)clamp(round(IniParams[40].x), 0.0f, 117.0f);
    float wa = SelectedWeight(EditableBlend[a], selectedVG);
    float wb = SelectedWeight(EditableBlend[b], selectedVG);
    float wc = SelectedWeight(EditableBlend[c], selectedVG);

    uint ignored;
    InterlockedAdd(SmoothAccum[a * 2u + 0u], (uint)round((wb + wc) * WEIGHT_SCALE), ignored);
    InterlockedAdd(SmoothAccum[a * 2u + 1u], 2u, ignored);
    InterlockedAdd(SmoothAccum[b * 2u + 0u], (uint)round((wa + wc) * WEIGHT_SCALE), ignored);
    InterlockedAdd(SmoothAccum[b * 2u + 1u], 2u, ignored);
    InterlockedAdd(SmoothAccum[c * 2u + 0u], (uint)round((wa + wb) * WEIGHT_SCALE), ignored);
    InterlockedAdd(SmoothAccum[c * 2u + 1u], 2u, ignored);
}
