
struct BlendBuf
{
    float4 blendWeights;
    int4 blendIndices;
};

RWStructuredBuffer<BlendBuf> blendBuffer : register(u0);
Buffer<float> MeshEditorMask : register(t0);

Texture1D<float4> IniParams : register(t120);

// x = BoneA, y = BoneB, z = Jiggle Strength
#define BoneIDs IniParams[77]

#define VERTEX_COUNT 79355

[numthreads(128, 1, 1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint id = DTid.x;

    if (id >= VERTEX_COUNT)
        return;

    int boneA = (int)BoneIDs.x;
    int boneB = (int)BoneIDs.y;
    float strength = max(BoneIDs.z, 0.0);

    BlendBuf blend = blendBuffer[id];

    float4 originalWeights = blend.blendWeights;
    float4 weights = originalWeights;

    float jiggleTotal = 0.0;
    float otherTotal = 0.0;

    [unroll]
    for (int k = 0; k < 4; ++k)
    {
        int bone = blend.blendIndices[k];

        if (bone == boneA || bone == boneB)
            jiggleTotal += weights[k];
        else
            otherTotal += weights[k];
    }

    if (jiggleTotal > 1e-6)
    {
        // Strength = 0: preserve the existing Nuke behavior.
        if (strength <= 1e-6)
        {
            if (otherTotal > 1e-6)
            {
                [unroll]
                for (int k = 0; k < 4; ++k)
                {
                    int bone = blend.blendIndices[k];

                    if (bone == boneA || bone == boneB)
                        weights[k] = 0.0;
                }

                weights /= otherTotal;
            }
            else
            {
                // Do not create an all-zero skinning record if Weight Paint
                // has intentionally assigned only the two Nuke/Jiggle VG IDs.
                // In that case there is no valid alternative influence to normalize.
                weights = originalWeights;
            }
        }
        // Strength > 0: redistribute weight between
        // jiggle bones and all remaining influences.
        else if (otherTotal > 1e-6)
        {
            float totalWeight = jiggleTotal + otherTotal;

            float targetJiggle = min(
                jiggleTotal * strength,
                totalWeight
            );

            float jiggleScale = targetJiggle / jiggleTotal;
            float otherScale =
                (totalWeight - targetJiggle) / otherTotal;

            [unroll]
            for (int k = 0; k < 4; ++k)
            {
                int bone = blend.blendIndices[k];

                if (bone == boneA || bone == boneB)
                    weights[k] *= jiggleScale;
                else
                    weights[k] *= otherScale;
            }
        }
    }

    float maskFactor = 1.0f - saturate(MeshEditorMask[id]);

    blend.blendWeights = lerp(originalWeights, weights, maskFactor);

    blendBuffer[id] = blend;
}
