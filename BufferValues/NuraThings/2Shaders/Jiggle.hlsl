struct PosBuf {
    float3 position;
    float3 normal;
    float4 tangent;
};

struct BlendBuf {
    float4 blendWeights;
    int4   blendIndices;
};

RWStructuredBuffer<PosBuf> rwPos   : register(u0);
RWBuffer<float4> PrevDriverPos     : register(u1);
RWBuffer<float4> Velocity          : register(u2);

RWBuffer<float4> Debug       : register(u4);

StructuredBuffer<BlendBuf> blendBuf : register(t0);
Buffer<float4> PivotBuffer       : register(t1);

#define DELTA_TIME           0.016f      // typical frame ~60FPS
#define STIFFNESS            0.05f
#define DAMPING              0.85f
#define MOVEMENT_THRESHOLD   0.001f

static const float3 DISPLAY_SCALE_BOOBS = float3(0.5f, 1.0f, 1.0f);
static const float3 DISPLAY_SCALE_BUTT  = float3(0.7f, 1.0f, 1.0f);

#define SPEED_MIN            0.01f       // walk threshold
#define SPEED_MAX            0.2f        // run threshold

static const int HIP      = 19;
static const int THIGH_L  = 90;
static const int THIGH_R  = 113;
static const int BOOB_L   = 2;
static const int BOOB_R   = 3;

bool IsBoob(uint id)
{
    [unroll]
    for (int i = 0; i < 4; i++)
        if ((blendBuf[id].blendIndices[i] == BOOB_L || blendBuf[id].blendIndices[i] == BOOB_R)
            && blendBuf[id].blendWeights[i] > 0.1)
            return true;
    return false;
}

bool IsButt(uint id)
{
    float hip = 0, thigh = 0, booba = 0;
    [unroll]
    for (int i = 0; i < 4; i++)
    {
        int b = blendBuf[id].blendIndices[i];
        float w = blendBuf[id].blendWeights[i];
        if (b == HIP) hip += w;
        if (b == THIGH_L || b == THIGH_R) thigh += w;
        if (b == BOOB_L || b == BOOB_R) booba += w;
    }
    return hip > 0.3 && thigh > 0.1 && booba > 0.03;
}

float3 GetForward(float3 hipPos, float3 spinePos)
{
    return normalize(spinePos - hipPos);
}

[numthreads(64,1,1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint idx = id.x;
    if(idx >= 79355) return;

    float3 hipPivot   = PivotBuffer[0].xyz;
    float3 spinePivot = PivotBuffer[1].xyz;

    float3 vertexPos = rwPos[idx].position;

    // Compute local forward/back direction
    //float3 forward = normalize(spinePivot - hipPivot);
    //forward.y = 0; // flatten horizontal
    //forward = normalize(forward);
    //
    //// Compute vector from hip to vertex in horizontal plane
    //float3 toVertex = vertexPos - hipPivot;
    //toVertex.y = 0;
    //
    //// Project along forward/back axis
    //float z = dot(toVertex, forward);
    //
    //// Only jiggle if z < 0 (behind hip)
    //if(IsButt(idx) && z >= 0) return;
   //
    //float lateralDist = length(float2(toVertex.x, toVertex.z));
    //if(IsButt(idx) && (z >= 0 || lateralDist < 0.05)) return;
//

   // if(IsButt(idx) && dot(toVertex, forward) > 0) return; // front cut

    float3 driver = hipPivot;
    float3 prev   = PrevDriverPos[0].xyz;
    float3 delta  = driver - prev;

    float3 vel = Velocity[idx].xyz;
    vel += delta * 0.05;
    vel *= 0.85;

    Debug[3] = float4(hipPivot, 69);
    Debug[4] = float4(spinePivot, 96);
    Debug[5] = float4(vertexPos, 5);
   //Debug[6] = float4(forward, 6);
   //Debug[7] = float4(toVertex, 7);

    // per-region, per-axis display scale
    float3 scale = float3(1,1,1);


    float3 deltaXZ = float3(delta.x, 0, delta.z);
    float rawSpeed = length(deltaXZ) / DELTA_TIME;
    float smooth = Velocity[0].w;

    if (idx == 0)
    {
        smooth = lerp(smooth, rawSpeed, 0.15); // smoothing
        Velocity[0] = float4(Velocity[0].x, Velocity[0].y, Velocity[0].z, smooth);
    }

    if (any(vel))
        if (IsBoob(idx)){

            #define WALK_SPEED  0.02
            #define RUN_SPEED   0.05

            float speedFactor = saturate(
                (smooth - WALK_SPEED) / (RUN_SPEED - WALK_SPEED)
            );

            float3 scaleWalk = float3(500, 50, 100);
            float3 scaleRun  = float3(100, 50, 100);

            scale = lerp(scaleWalk, scaleRun, speedFactor);

            Debug[6] = float4(69, 69, 69, smooth);
            Debug[7] = float4(scale, speedFactor);
        }

    if (IsButt(idx))
    {
        float3 forward = normalize(spinePivot - hipPivot);
        float3 right   = normalize(cross(float3(0,1,0), forward));
        float3 up      = float3(0,1,0);

        float lateral = dot(vel, right);
        float vertical = dot(vel, up);

        float3 constrained = right*lateral*1.0 + up*vertical*0.6;

        float dist = length(vertexPos - hipPivot);
        float falloff = saturate(1.0 - dist*3.0);
        falloff = pow(falloff, 1.2);

        float pelvisFade = saturate((dist - 0.05) * 10.0);

        float3 axisScale = float3(150, 150, 1000);

        rwPos[idx].position += constrained * axisScale * falloff * pelvisFade;
    }


    //if (IsBoob(idx))      scale = displayScaleBoobs;
    //else if (IsButt(idx)) scale = displayScaleButt;

    if(IsBoob(idx))
        rwPos[idx].position += vel * scale;

    if (any(vel)){
        Debug[0] = float4(vel, 69);
        Debug[1] = float4(delta, length(delta));
    }

    Velocity[idx] = float4(vel, Velocity[idx].w);

    if (idx == 0)
        PrevDriverPos[0] = float4(driver, 0);
}
