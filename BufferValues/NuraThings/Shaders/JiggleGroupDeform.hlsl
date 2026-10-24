// Iris - weighted translation from the per-group spring offsets.
// Position resource stride is 40 bytes: float3 pos, float3 normal, float4 tangent.
// GroupState uses 4 float4 records per group; see JiggleGroupSimulate.hlsl.

#define VERTEX_COUNT 79355u
#define GROUP_COUNT 8u
#define STATE_STRIDE 4u

struct PosBuf
{
    float3 pos;
    float3 nor;
    float4 tan;
};

Buffer<float> NamedMasks : register(t0);
Buffer<float4> GroupState : register(t1);
RWStructuredBuffer<PosBuf> PositionBuffer : register(u0);
Texture1D<float4> IniParams : register(t120);

float3 ClampMagnitude(float3 value, float maxMagnitude)
{
    float lenSq = dot(value, value);
    float maxSq = maxMagnitude * maxMagnitude;
    if (lenSq > maxSq && lenSq > 1e-12f)
        value *= maxMagnitude * rsqrt(lenSq);
    return value;
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint vertexID = dispatchThreadID.x;
    if (vertexID >= VERTEX_COUNT)
        return;

    PosBuf vertex = PositionBuffer[vertexID];

    [unroll]
    for (uint group = 0u; group < GROUP_COUNT; ++group)
    {
        float4 settings = IniParams[148 + group];
        if (settings.x <= 0.5f)
            continue;

        uint stateBase = group * STATE_STRIDE;
        float4 offsetRecord = GroupState[stateBase + 0u];
        if (offsetRecord.w < 0.5f)
            continue;

        float4 extra = IniParams[156 + group];
        float3 axis = saturate(IniParams[164 + group].xyz);
        float4 advanced = IniParams[172 + group];
        float edgeFalloff = clamp(advanced.w, 0.25f, 4.0f);

        int maskSlot = clamp((int)(IniParams[124 + group].x + 0.5f), 0, 7);
        uint maskIndex = (uint)maskSlot * VERTEX_COUNT + vertexID;
        float rawMaskWeight = saturate(NamedMasks[maskIndex]);
        float maskWeight = pow(rawMaskWeight, edgeFalloff);
        if (maskWeight <= 1e-5f)
            continue;
        float maxOffset = max(extra.y, 0.0f);
        float3 offset = offsetRecord.xyz * axis * max(settings.w, 0.0f);

        // Max Offset is a cap on the final visible movement, including Strength.
        if (maxOffset > 0.0f)
            offset = ClampMagnitude(offset, maxOffset);
        else
            offset = 0.0f;

        // The mask provides the falloff/attachment to the surrounding body mesh.
        vertex.pos += offset * maskWeight;
    }

    PositionBuffer[vertexID] = vertex;
}
