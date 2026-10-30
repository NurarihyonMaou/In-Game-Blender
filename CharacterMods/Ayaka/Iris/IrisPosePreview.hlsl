Texture1D<float4> IniParams : register(t120);
Texture2D<float4> PoseThumbnail0 : register(t0);
Texture2D<float4> PoseThumbnail1 : register(t1);
Texture2D<float4> PoseThumbnail2 : register(t2);
Texture2D<float4> PoseThumbnail3 : register(t3);
Texture2D<float4> PoseThumbnail4 : register(t4);
Texture2D<float4> PoseThumbnail5 : register(t5);
Texture2D<float4> PoseThumbnail6 : register(t6);
Texture2D<float4> PoseThumbnail7 : register(t7);
Texture2D<float4> PoseFrameCapture : register(t8);

struct VSOutput
{
    float4 pos : SV_Position;
    float2 uv : TEXCOORD0;
};

#ifdef VERTEX_SHADER
VSOutput main(uint vertexID : SV_VertexID)
{
    VSOutput output;
    float2 quad[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };
    float2 q = quad[vertexID & 3];

    if (IniParams[199].x > 0.5)
    {
        output.pos = float4(q.x * 2.0 - 1.0, 1.0 - q.y * 2.0, 0.0, 1.0);
    }
    else
    {
        int slot = (int)(IniParams[200].x + 0.5);
        float col = (float)(slot % 4);
        float row = (float)(slot / 4);
        float2 origin = float2(0.02 + col * 0.12, 0.04 + row * 0.28);
        float2 size = float2(0.11, 0.26);
        float2 screenPos = origin + q * size;
        output.pos = float4(screenPos.x * 2.0 - 1.0, 1.0 - screenPos.y * 2.0, 0.0, 1.0);
    }
    output.uv = q;
    return output;
}
#else
bool InRect(float2 p, float2 lo, float2 hi)
{
    return all(p >= lo) && all(p <= hi);
}

float4 ReadThumbnail(int slot, int2 pixel)
{
    if (slot == 0) return PoseThumbnail0.Load(int3(pixel, 0));
    if (slot == 1) return PoseThumbnail1.Load(int3(pixel, 0));
    if (slot == 2) return PoseThumbnail2.Load(int3(pixel, 0));
    if (slot == 3) return PoseThumbnail3.Load(int3(pixel, 0));
    if (slot == 4) return PoseThumbnail4.Load(int3(pixel, 0));
    if (slot == 5) return PoseThumbnail5.Load(int3(pixel, 0));
    if (slot == 6) return PoseThumbnail6.Load(int3(pixel, 0));
    return PoseThumbnail7.Load(int3(pixel, 0));
}

float4 main(VSOutput input) : SV_Target
{
    if (IniParams[199].x > 0.5)
    {
        uint width, height;
        PoseFrameCapture.GetDimensions(width, height);
        // Center crop: portrait framing around the character in a 16:9 viewport.
        // The thumbnail is 384x512. Average four source taps while downscaling
        // instead of taking one point sample (which caused harsh pixel aliasing).
        const float2 outputSize = float2(384.0, 512.0);
        const float2 cropMin = float2(0.33125, 0.10);
        const float2 cropExtent = float2(0.3375, 0.80);
        float2 sourceSize = float2(width, height);
        float2 sourceStep = cropExtent * sourceSize / outputSize;
        float2 sourceStart = cropMin * sourceSize +
            (saturate(input.uv) - 0.5 / outputSize) * cropExtent * sourceSize;
        int2 p00 = (int2)floor(sourceStart + sourceStep * float2(0.25, 0.25));
        int2 p10 = (int2)floor(sourceStart + sourceStep * float2(0.75, 0.25));
        int2 p01 = (int2)floor(sourceStart + sourceStep * float2(0.25, 0.75));
        int2 p11 = (int2)floor(sourceStart + sourceStep * float2(0.75, 0.75));
        int2 maxPixel = int2((int)width - 1, (int)height - 1);
        p00 = clamp(p00, int2(0, 0), maxPixel);
        p10 = clamp(p10, int2(0, 0), maxPixel);
        p01 = clamp(p01, int2(0, 0), maxPixel);
        p11 = clamp(p11, int2(0, 0), maxPixel);
        float4 c00 = PoseFrameCapture.Load(int3(p00, 0));
        float4 c10 = PoseFrameCapture.Load(int3(p10, 0));
        float4 c01 = PoseFrameCapture.Load(int3(p01, 0));
        float4 c11 = PoseFrameCapture.Load(int3(p11, 0));
        return (c00 + c10 + c01 + c11) * 0.25;
    }

    float4 poseInfo = IniParams[200];
    int slot = (int)(poseInfo.x + 0.5);
    bool saved = poseInfo.y > 0.5;
    bool selected = poseInfo.z > 0.5;
    bool active = poseInfo.w > 0.5;
    // The texture is rendered at 384x512 and shown smaller on screen.
    // Apply manual bilinear filtering because the shader uses Load(), not a sampler.
    float2 samplePos = saturate(input.uv) * float2(384.0, 512.0) - 0.5;
    int2 pixel0 = (int2)floor(samplePos);
    float2 sampleFrac = frac(samplePos);
    int2 pixel1 = pixel0 + 1;
    pixel0 = clamp(pixel0, int2(0, 0), int2(383, 511));
    pixel1 = clamp(pixel1, int2(0, 0), int2(383, 511));
    float4 c00 = ReadThumbnail(slot, pixel0);
    float4 c10 = ReadThumbnail(slot, int2(pixel1.x, pixel0.y));
    float4 c01 = ReadThumbnail(slot, int2(pixel0.x, pixel1.y));
    float4 c11 = ReadThumbnail(slot, pixel1);
    float4 thumbnail = lerp(lerp(c00, c10, sampleFrac.x), lerp(c01, c11, sampleFrac.x), sampleFrac.y);
    float4 color = saved ? thumbnail : float4(0.075, 0.08, 0.09, 0.94);

    float2 edge = min(input.uv, 1.0 - input.uv);
    bool border = edge.x < 0.014 || edge.y < 0.014;
    if (border)
    {
        if (selected) color = float4(1.0, 0.78, 0.12, 1.0);
        else if (active) color = float4(0.15, 0.68, 1.0, 1.0);
        else if (saved) color = float4(0.18, 0.82, 0.38, 1.0);
        else color = float4(0.30, 0.32, 0.35, 1.0);
    }

    // Small 7-segment number badge: slot 1..8, so the thumbnails remain easy to map to hotkeys.
    if (input.uv.x < 0.18 && input.uv.y < 0.14)
    {
        color = float4(0.015, 0.018, 0.022, 0.94);
        float2 d = input.uv / float2(0.18, 0.14);
        int digit = slot + 1;
        bool segA = digit != 1 && digit != 4;
        bool segB = digit != 5 && digit != 6;
        bool segC = digit != 2;
        bool segD = digit == 2 || digit == 3 || digit == 5 || digit == 6 || digit == 8;
        bool segE = digit == 2 || digit == 6 || digit == 8;
        bool segF = digit == 4 || digit == 5 || digit == 6 || digit == 8;
        bool segG = digit == 2 || digit == 3 || digit == 4 || digit == 5 || digit == 6 || digit == 8;
        bool isSegmentOn =
            (segA && InRect(d, float2(0.25, 0.06), float2(0.75, 0.17))) ||
            (segG && InRect(d, float2(0.25, 0.445), float2(0.75, 0.555))) ||
            (segD && InRect(d, float2(0.25, 0.83), float2(0.75, 0.94))) ||
            (segF && InRect(d, float2(0.08, 0.15), float2(0.19, 0.45))) ||
            (segB && InRect(d, float2(0.81, 0.15), float2(0.92, 0.45))) ||
            (segE && InRect(d, float2(0.08, 0.55), float2(0.19, 0.85))) ||
            (segC && InRect(d, float2(0.81, 0.55), float2(0.92, 0.85)));
        if (isSegmentOn) color = float4(1.0, 1.0, 1.0, 1.0);
    }
    return color;
}
#endif
