Texture2D<float4> VertexScreen : register(t0);
Buffer<float> NamedMasks : register(t1);
Texture1D<float4> IniParams : register(t120);

#define ACTIVE_MASK_FLAGS IniParams[38].x
#define PREVIEW_MODE      IniParams[39].x

#define CAPTURE_WIDTH    512u
#define CAPTURE_HEIGHT   256u
#define VERTEX_COUNT     79355u
#define MASK_SLOT_COUNT  8u

struct VS_OUT
{
    float4 pos     : SV_Position;
    float  mask    : TEXCOORD0;
    float3 color   : TEXCOORD1;
    float  overlap : TEXCOORD2;
};

float4 LoadVertexClip(uint vertexID)
{
    if (vertexID >= VERTEX_COUNT)
        return float4(0, 0, 0, 0);

    uint2 p = uint2(
        vertexID % CAPTURE_WIDTH,
        vertexID / CAPTURE_WIDTH
    );

    if (p.y >= CAPTURE_HEIGHT)
        return float4(0, 0, 0, 0);

    return VertexScreen.Load(int3(p, 0));
}

float3 GetMaskColor(uint slot)
{
    if (slot == 0u) return float3(1.00f, 0.12f, 0.12f);
    if (slot == 1u) return float3(0.05f, 0.82f, 1.00f);
    if (slot == 2u) return float3(0.12f, 1.00f, 0.24f);
    if (slot == 3u) return float3(0.74f, 0.18f, 1.00f);
    if (slot == 4u) return float3(1.00f, 0.82f, 0.08f);
    if (slot == 5u) return float3(1.00f, 0.32f, 0.04f);
    if (slot == 6u) return float3(0.12f, 0.22f, 1.00f);

    return float3(1.00f, 0.12f, 0.68f);
}

void LoadMaskData(
    uint vertexID,
    out float combinedMask,
    out float3 combinedColor,
    out float overlapCount)
{
    int activeFlags = (int)(ACTIVE_MASK_FLAGS + 0.5f);

    float totalWeight = 0.0f;
    combinedMask = 0.0f;
    combinedColor = 0.0f;
    overlapCount = 0.0f;

    [unroll]
    for (uint slot = 0u; slot < MASK_SLOT_COUNT; ++slot)
    {
        if ((activeFlags & (1 << slot)) == 0)
            continue;

        uint maskIndex = slot * VERTEX_COUNT + vertexID;
        float weight = saturate(NamedMasks[maskIndex]);

        combinedMask = max(combinedMask, weight);

        if (weight > 0.025f)
            overlapCount += 1.0f;

        combinedColor += GetMaskColor(slot) * weight;
        totalWeight += weight;
    }

    if (totalWeight > 1e-5f)
        combinedColor /= totalWeight;
    else
        combinedColor = 0.0f;
}

#ifdef VERTEX_SHADER

VS_OUT main(uint vertexID : SV_VertexID)
{
    VS_OUT output;

    output.pos = LoadVertexClip(vertexID);
    output.mask = 0.0f;
    output.color = 0.0f;
    output.overlap = 0.0f;

    if (vertexID >= VERTEX_COUNT)
        return output;

    LoadMaskData(
        vertexID,
        output.mask,
        output.color,
        output.overlap
    );

    return output;
}

#endif

#ifdef PIXEL_SHADER

float4 main(VS_OUT input) : SV_Target1
{
    float mask = saturate(input.mask);
    int mode = (int)(PREVIEW_MODE + 0.5f);

    // MODE 2: show how many enabled masks overlap here.
    if (mode == 2)
    {
        float overlap = input.overlap;

        if (overlap <= 0.025f)
            discard;

        float3 color;

        if (overlap < 1.5f)
            color = float3(0.15f, 0.85f, 1.00f);
        else if (overlap < 3.5f)
            color = float3(0.20f, 1.00f, 0.25f);
        else if (overlap < 5.5f)
            color = float3(1.00f, 0.82f, 0.08f);
        else
            color = float3(1.00f, 0.12f, 0.58f);

        int activeFlags = (int)(ACTIVE_MASK_FLAGS + 0.5f);
        float activeCount = 0.0f;

        [unroll]
        for (uint slot = 0u; slot < MASK_SLOT_COUNT; ++slot)
        {
            if ((activeFlags & (1 << slot)) != 0)
                activeCount += 1.0f;
        }

        float alpha = saturate(
            0.35f + 0.45f * (overlap / max(activeCount, 1.0f))
        );

        return float4(color, alpha);
    }

    if (mask <= 0.001f)
        discard;

    // MODE 1: uniform red protection overlay.
    if (mode == 1){
        // Neutral charcoal with a very subtle cool tint.
        const float3 MASK_COLOR = float3(
            0.065f,
            0.070f,
            0.080f
        );
    
        // Gradual darkening proportional to mask strength.
        // Fully masked: 58% opacity.
        float opacity = mask * 0.52f;
    
        return float4(MASK_COLOR, opacity);
    }

    // MODE 0: color-coded active named masks.
    float alpha = saturate(0.78f * max(mask, 0.18f));

    return float4(input.color, alpha);
}

#endif