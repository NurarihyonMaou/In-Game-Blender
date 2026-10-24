// MeshEditorMaskDeltaApply.hlsl
// Applies the combined protective mask to the CHANGE made by one Smooth pass.
// OldDelta is the pre-smooth snapshot, SmoothedDelta is the SmoothApply output.
// Protection 0 keeps the smoothed result; protection 1 preserves the old delta.

Buffer<float4> OldDelta : register(t0);
Buffer<float4> SmoothedDelta : register(t1);
Buffer<float> CombinedMask : register(t2);
RWBuffer<float4> ResultDelta : register(u0);

#define VERTEX_COUNT 79355u

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    float4 oldValue = OldDelta[vertexID];
    float4 newValue = SmoothedDelta[vertexID];
    float protection = saturate(CombinedMask[vertexID]);

    float3 maskedDelta = lerp(newValue.xyz, oldValue.xyz, protection);
    ResultDelta[vertexID] = float4(maskedDelta, newValue.w);
}
