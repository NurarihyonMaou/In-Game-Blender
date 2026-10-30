// Convert the screen-plane mouse basis into base/object space once, using the
// active pose's skin matrix at the hovered anchor vertex. The resulting basis
// is then saved in scalar globals and the committed Move delta is deterministic
// during persistent-pool replay, even if the game's animation later changes.

struct BlendBuf
{
    float4 blendWeights;
    int4 blendIndices;
};

Buffer<float4> BoneMatrices : register(t0);
StructuredBuffer<BlendBuf> Blend : register(t1);
RWBuffer<float4> MoveBasis : register(u0);
Texture1D<float4> IniParams : register(t120);

#define POSED_RIGHT IniParams[50].xyz
#define POSED_DOWN  IniParams[51].xyz
#define ANCHOR_ID   (uint)max(round(IniParams[52].x), 0.0f)

float3x3 LoadBoneMatrix3x3(uint bone)
{
    uint i = bone * 3u;
    return float3x3(
        BoneMatrices[i + 0u].xyz,
        BoneMatrices[i + 1u].xyz,
        BoneMatrices[i + 2u].xyz);
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
            0.0f, 0.0f, 1.0f);
    }
    float invDet = 1.0f / det;
    return float3x3(
        A * invDet, B * invDet, C * invDet,
        D * invDet, E * invDet, F * invDet,
        G * invDet, H * invDet, I * invDet);
}

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    float3x3 invSkin = Inverse3x3(GetSkinMatrix(ANCHOR_ID));
    MoveBasis[0] = float4(mul(invSkin, POSED_RIGHT), 1.0f);
    MoveBasis[1] = float4(mul(invSkin, POSED_DOWN), 1.0f);
}
