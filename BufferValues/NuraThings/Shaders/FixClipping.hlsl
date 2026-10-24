struct PosBuf {
    float3 position;
    float3 normal;
    float4 tangent;
};

// Buffers
StructuredBuffer<PosBuf> SkirtVerticesIn : register(t1);  // Input skirt vertex positions (posed)
RWStructuredBuffer<PosBuf> SkirtVerticesOut : register(u0);
RWBuffer<float4> Debug : register(u3);

StructuredBuffer<float4> BoneMatrices : register(t0);      // vs-t0

Texture1D<float4> IniParams : register(t120);

cbuffer Params : register(b0)
{
    uint NumVerts = 133438;

    uint ThighIndexLeft = 113;
    uint ThighIndexRight = 90;

    uint KneeLeftIndex = 93;
    uint KneeRightIndex = 70;

}

//------------------------------------------
// Rebuild float4x4 from 3x4 matrix
float4x4 GetBoneMatrix(uint idx)
{
    float4 r0 = BoneMatrices[idx*3 + 0];
    float4 r1 = BoneMatrices[idx*3 + 1];
    float4 r2 = BoneMatrices[idx*3 + 2];
    float4 r3 = float4(0,0,0,1); // add last row
    return float4x4(r0,r1,r2,r3);
}

float3 ClosestPointOnSegment(float3 a, float3 b, float3 p)
{
    float3 ab = b - a;
    float denom = dot(ab, ab);

    float t;
    if (denom > 1e-8)         // avoid tiny lengths
        t = dot(p - a, ab) / denom;
    else
        t = 0.0;               // segment degenerate, closest point = a

    t = saturate(t);
    return a + t * ab;
}

// Capsule push-out
float3 ResolveCapsule(float3 pos, float3 capA, float3 capB, float radius)
{
    float3 closest = ClosestPointOnSegment(capA, capB, pos);
    float3 delta = pos - closest;
    float dist = length(delta);

    if (dist < radius)
    {
        float3 dir = (dist > 1e-6) ? delta / dist : float3(0,1,0);
        return closest + dir * radius - pos;
    }
    return float3(0,0,0);
}

// Capsule push-out along vertex normal
float3 ResolveCapsuleNormal(float3 pos, float3 normal, float3 capA, float3 capB, float radius)
{
    float3 closest = ClosestPointOnSegment(capA, capB, pos);
    float dist = distance(pos, closest);

    if (dist < radius)
    {
        // How deep inside capsule?
        float penetration = radius - dist;

        // Push outwards along normal
        return normal * penetration;
    }
    return float3(0,0,0);
}


//------------------------------------------
[numthreads(64,1,1)]
void main(uint3 id : SV_DispatchThreadID)
{
    if (id.x >= NumVerts) return;

    float3 pos = SkirtVerticesIn[id.x].position;
    float3 nor = SkirtVerticesIn[id.x].normal;
    float4 tan = SkirtVerticesIn[id.x].tangent;

    float ThighRadius = IniParams[43].x;
    float Margin = IniParams[43].y; // Currently used as Offset

    // Build posed capsules from bone matrices
    float4x4 hipLeftMat  = GetBoneMatrix(ThighIndexLeft);
    float4x4 kneeLeftMat = GetBoneMatrix(KneeLeftIndex);

    float3 capLeftA  = hipLeftMat[3].xyz;  // translation part
    float3 capLeftB  = kneeLeftMat[3].xyz;

    float4x4 hipRightMat  = GetBoneMatrix(ThighIndexRight);
    float4x4 kneeRightMat = GetBoneMatrix(KneeRightIndex);

    float3 capRightA = hipRightMat[3].xyz;
    float3 capRightB = kneeRightMat[3].xyz;

    capLeftA.x -= Margin;
    capLeftB.x -= Margin;

    capRightA.x -= Margin;
    capRightB.x -= Margin;

    // Push skirt vertex out of both capsules
   // pos += ResolveCapsule(pos, capLeftA, capLeftB, ThighRadius);
   // pos += ResolveCapsule(pos, capRightA, capRightB, ThighRadius);

    // Push skirt vertex out of both capsules ALONG NORMAL
    pos += ResolveCapsuleNormal(pos, nor, capLeftA, capLeftB, ThighRadius);
    pos += ResolveCapsuleNormal(pos, nor, capRightA, capRightB, ThighRadius);

    SkirtVerticesOut[id.x].position = pos;
    SkirtVerticesOut[id.x].normal = nor;
    SkirtVerticesOut[id.x].tangent = tan;

    Debug[3] = float4(hipLeftMat[3].xyz, 69);
}