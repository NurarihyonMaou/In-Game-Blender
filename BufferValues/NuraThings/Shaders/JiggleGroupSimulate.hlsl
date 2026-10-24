// Iris - axis-filtered 8-group spring simulation.
// State layout: 4 float4 entries per group:
//   +0: simulated offset.xyz, initialized flag in .w
//   +1: simulated velocity.xyz
//   +2: previous group center.xyz, valid flag in .w
//   +3: previous filtered center velocity.xyz
// IniParams:
//   [146].x       = dt
//   [148 + group] = enabled, stiffness, damping, strength
//   [156 + group] = inertia, max_offset, ...
//   [164 + group] = axis_x, axis_y, axis_z, ...
//   [172 + group] = gravity_y, motion_sensitivity, response_smoothing, edge_falloff

#define GROUP_COUNT 8u
#define STATE_STRIDE 4u

Buffer<float4> GroupCenters : register(t0);
RWBuffer<float4> GroupState : register(u0);
RWBuffer<float4> Debug : register(u1);
Texture1D<float4> IniParams : register(t120);

float3 ClampMagnitude(float3 value, float maxMagnitude)
{
    float lenSq = dot(value, value);
    float maxSq = maxMagnitude * maxMagnitude;
    if (lenSq > maxSq && lenSq > 1e-12f)
        value *= maxMagnitude * rsqrt(lenSq);
    return value;
}

[numthreads(8, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint group = dispatchThreadID.x;
    if (group >= GROUP_COUNT)
        return;

    uint stateBase = group * STATE_STRIDE;
    float4 center = GroupCenters[group];
    float4 settings = IniParams[148 + group];
    float4 extra = IniParams[156 + group];
    float3 axis = saturate(IniParams[164 + group].xyz);
    float4 advanced = IniParams[172 + group];
    float gravityY = clamp(advanced.x, -1.0f, 1.0f);
    float motionSensitivity = clamp(advanced.y, 0.0f, 2.0f);
    float responseSmoothing = clamp(advanced.z, 0.05f, 1.0f);

    float4 offsetRecord = GroupState[stateBase + 0u];
    float4 velocityRecord = GroupState[stateBase + 1u];
    float4 previousCenterRecord = GroupState[stateBase + 2u];
    float4 previousCenterVelocityRecord = GroupState[stateBase + 3u];

    bool enabled = settings.x > 0.5f;
    bool centerValid = center.w > 1e-6f;

    // A disabled/empty group is reset so re-enabling it cannot kick from stale velocity.
    if (!enabled || !centerValid)
    {
        GroupState[stateBase + 0u] = 0.0f;
        GroupState[stateBase + 1u] = 0.0f;
        GroupState[stateBase + 2u] = float4(center.xyz, centerValid ? 1.0f : 0.0f);
        GroupState[stateBase + 3u] = 0.0f;
        Debug[group] = 0.0f;
        return;
    }

    if (offsetRecord.w < 0.5f || previousCenterRecord.w < 0.5f)
    {
        GroupState[stateBase + 0u] = float4(0.0f, 0.0f, 0.0f, 1.0f);
        GroupState[stateBase + 1u] = 0.0f;
        GroupState[stateBase + 2u] = float4(center.xyz, 1.0f);
        GroupState[stateBase + 3u] = 0.0f;
        Debug[group] = 0.0f;
        return;
    }

    // Clamp dt against pauses and unusually long frame times.
    float dt = clamp(IniParams[146].x, 1.0f / 240.0f, 1.0f / 30.0f);
    float stiffness = max(settings.y, 0.0f);
    float damping = max(settings.z, 0.0f);
    float inertia = max(extra.x, 0.0f);
    float maxOffset = max(extra.y, 0.0f);

    float3 offset = offsetRecord.xyz * axis;
    float3 velocity = velocityRecord.xyz * axis;

    // Estimate acceleration of the mask-weighted center; spring inertia reacts opposite to it.
    float3 rawCenterVelocity = ((center.xyz - previousCenterRecord.xyz) / dt) * axis;
    // Low smoothing values damp quick position changes; 1.0 follows the raw center velocity.
    float3 centerVelocity = lerp(previousCenterVelocityRecord.xyz, rawCenterVelocity, responseSmoothing);
    float3 centerAcceleration = (centerVelocity - previousCenterVelocityRecord.xyz) / dt;
    centerAcceleration = ClampMagnitude(centerAcceleration, 30.0f);
    centerAcceleration *= axis;

    float3 acceleration =
          (-stiffness * offset)
        - (damping * velocity)
        - (inertia * motionSensitivity * centerAcceleration);
    // Optional gravity/bias along model-space Y; it is still subject to the Y-axis switch.
    acceleration.y += gravityY;
    acceleration *= axis;

    // Semi-implicit Euler integration.
    velocity += acceleration * dt;
    velocity *= axis;
    offset += velocity * dt;
    offset *= axis;

    if (maxOffset > 0.0f)
        offset = ClampMagnitude(offset, maxOffset);
    else
        offset = 0.0f;

    GroupState[stateBase + 0u] = float4(offset, 1.0f);
    GroupState[stateBase + 1u] = float4(velocity, 0.0f);
    GroupState[stateBase + 2u] = float4(center.xyz, 1.0f);
    GroupState[stateBase + 3u] = float4(centerVelocity, 0.0f);
    Debug[group] = float4(offset, maxOffset);
}
