// **** RESPONSIVE UI SHADER ****
// Contributors: SinsOfSeven, Nurarihyon
// Version 1.0
// Ispired by VV_Mod_Maker
// https://github.com/SinsOfSeven/SliderImpact/blob/main/ResponsiveUI/draw_2d.hlsl


Texture1D<float4> IniParams : register(t120);

#define SIZE IniParams[87].xy
#define OFFSET IniParams[87].zw
#define BoxMin IniParams[88].xy
#define BoxMax IniParams[88].zw

#define FadeOut IniParams[89].x

#define USE_BOX IniParams[136].x
#define USE_FADEOUT IniParams[136].y
#define SPECIAL_EFFECT IniParams[136].z
#define SPECIAL_EFFECT2 IniParams[136].w

#define SpecialValX IniParams[137].x
#define SpecialValY IniParams[137].y

#define Direction IniParams[137].z
#define UseDirection IniParams[137].w

#define packedHSV IniParams[100].x
#define packedHSL IniParams[100].y
#define packedRGB IniParams[100].z
#define useWhichPacked IniParams[100].w
#define TINT_STRENGTH IniParams[101].x

struct vs2ps {
    float4 pos : SV_Position0;
    float2 uv : TEXCOORD1;
};


float3 RGBtoHSL(float3 rgb)
{
    float r = rgb.r;
    float g = rgb.g;
    float b = rgb.b;

    float maxC = max(r, max(g, b));
    float minC = min(r, min(g, b));
    float delta = maxC - minC;

    float h = 0.0;
    float s = 0.0;
    float l = (maxC + minC) / 2.0;

    if (delta > 0.0)
    {
        // Saturation
        s = delta / (1.0 - abs(2.0 * l - 1.0));

        // Hue
        if (maxC == r)
            h = (g - b) / delta;
        else if (maxC == g)
            h = (b - r) / delta + 2.0;
        else
            h = (r - g) / delta + 4.0;

        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }

    return float3(h, s, l);
}

float3 HSVtoRGB(float H, float S, float V)
{
    float C = V * S;
    float X = C * (1 - abs(fmod(H / 60.0, 2) - 1));
    float m = V - C;
    float3 color = float3(0, 0, 0);

    if (H < 60)       color = float3(C, X, 0);
    else if (H < 120) color = float3(X, C, 0);
    else if (H < 180) color = float3(0, C, X);
    else if (H < 240) color = float3(0, X, C);
    else if (H < 300) color = float3(X, 0, C);
    else              color = float3(C, 0, X);

    return color + m;
}

float3 HSLtoRGB(float3 hsl)
{
    float H = hsl.x;
    float S = hsl.y;
    float L = hsl.z;

    float C = (1 - abs(2 * L - 1)) * S;
    float Hprime = H * 6.0;
    float X = C * (1 - abs(fmod(Hprime, 2.0) - 1.0));

    float3 rgb1;
    if (Hprime < 1) rgb1 = float3(C, X, 0);
    else if (Hprime < 2) rgb1 = float3(X, C, 0);
    else if (Hprime < 3) rgb1 = float3(0, C, X);
    else if (Hprime < 4) rgb1 = float3(0, X, C);
    else if (Hprime < 5) rgb1 = float3(X, 0, C);
    else rgb1 = float3(C, 0, X);

    float m = L - 0.5 * C;
    return rgb1 + m;
}

float3 UnpackHSL(float packed)
{
    uint data = asuint(packed);

    uint H = (data >> 16) & 0xFFFF;
    uint S = (data >> 8) & 0xFF;
    uint L = data & 0xFF;

    float3 hsl;
    hsl.x = (float)H / 65535.0;
    hsl.y = (float)S / 255.0;
    hsl.z = (float)L / 255.0;

    return hsl;
}


float3 UnpackRGB(float packed)
{
    uint data = asuint(packed);

    uint R = (data >> 20) & 0x3FF;
    uint G = (data >> 10) & 0x3FF;
    uint B = data & 0x3FF;

    float3 rgb;
    rgb.r = (float)R / 1023.0;
    rgb.g = (float)G / 1023.0;
    rgb.b = (float)B / 1023.0;

    return rgb;
}

float3 UnpackHSV(float packed)
{
    uint data = asuint(packed);

    uint H = (data >> 16) & 0xFFFF;
    uint S = (data >> 8) & 0xFF;
    uint V = data & 0xFF;

    float3 hsv;
    hsv.x = (float)H / 65535.0 * 360.0;
    hsv.y = (float)S / 255.0;
    hsv.z = (float)V / 255.0;

    return hsv;
}

float3 RGBtoHSV(float3 c)
{
    float R = c.r;
    float G = c.g;
    float B = c.b;

    float maxC = max(R, max(G, B));
    float minC = min(R, min(G, B));
    float delta = maxC - minC;

    float H = 0.0;
    if (delta > 0.00001)
    {
        if (maxC == R)
            H = 60.0 * fmod(((G - B) / delta), 6.0);
        else if (maxC == G)
            H = 60.0 * (((B - R) / delta) + 2.0);
        else if (maxC == B)
            H = 60.0 * (((R - G) / delta) + 4.0);
    }

    if (H < 0.0)
        H += 360.0;

    float S = (maxC <= 0.0) ? 0.0 : delta / maxC;
    float V = maxC;

    return float3(H, S, V);
}

float3 HSVtoHSL(float3 hsv)
{
    float H = hsv.x;
    float S_HSV = hsv.y;
    float V = hsv.z;

    float L = V * (1.0 - S_HSV * 0.5);

    float S_HSL;
    if (L == 0.0 || L == 1.0)
    {
        S_HSL = 0.0;
    }
    else
    {
        S_HSL = (V - L) / min(L, 1.0 - L);
    }

    return float3(H, S_HSL, L);
}

#ifdef VERTEX_SHADER
void main(
        out vs2ps output,
        uint vertex : SV_VertexID)
{
    float2 BaseCoord,Offset;
    Offset.x = OFFSET.x*2-1;
    Offset.y = (1-OFFSET.y)*2-1;
    BaseCoord.xy = float2((2*SIZE.x),(2*(-SIZE.y)));
    // Not using vertex buffers so manufacture our own coordinates.

    for (int i = 0; i < 3; i++){
        for (int shade = 0; shade < 360; shade++){
            switch(vertex) {
                case 0:
                    output.pos.xy = float2(BaseCoord.x+Offset.x, BaseCoord.y+Offset.y);
                    output.uv = float2(1,0);
                    break;
                case 1:
                    output.pos.xy = float2(BaseCoord.x+Offset.x, 0+Offset.y);
                    output.uv = float2(1,1);
                    break;
                case 2:
                    output.pos.xy = float2(0+Offset.x, BaseCoord.y+Offset.y);
                    output.uv = float2(0,0);
                    break;
                case 3:
                    output.pos.xy = float2(0+Offset.x, 0+Offset.y);
                    output.uv = float2(0,1);
                    break;
                default:
                    output.pos.xy = 0;
                    output.uv = float2(0,0);
                    break;
            };
            output.pos.zw = float2(0, 1);
        }
    }

}
#endif

#ifdef PIXEL_SHADER
Texture2D<float4> tex : register(t100);

void main(vs2ps input, out float4 result : SV_Target0)
{
    if (USE_BOX == 69){
        // Get Screen Pixel Coordinates
        float2 pos = input.pos.xy;

        // Clip to UI Box Bounds
        if (pos.x < BoxMin.x || pos.x > BoxMax.x || pos.y < BoxMin.y || pos.y > BoxMax.y)
            discard;
    }

    if (SPECIAL_EFFECT == 69){
        float fill = saturate(SpecialValX / max(SpecialValY, 0.001));

        // Only draw filled portion
        if (input.uv.x > fill)
            discard;

        float3 color;
        if (fill > 0.5)
        {
            color = lerp(float3(1.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), (fill - 0.5) * 2.0); // yellow → green
        }
        else if (fill > 0.25)
        {
            color = lerp(float3(1.0, 0.0, 0.0), float3(1.0, 1.0, 0.0), (fill - 0.25) * 4.0); // red → yellow
        }
        else
        {
            color = float3(1.0, 0.0, 0.0); // red
        }

        result = float4(color, 1.0);
    }
    else{

        if (SPECIAL_EFFECT2 == 69){
            // Rotate image around center
            float2 uv = input.uv - 0.5;

            float angle = radians(SpecialValX);  // rotation in degrees
            float cosA = cos(angle);
            float sinA = sin(angle);

            float2 rotatedUV;
            rotatedUV.x = uv.x * cosA - uv.y * sinA;
            rotatedUV.y = uv.x * sinA + uv.y * cosA;
            rotatedUV += 0.5;

            // Flip Y once (needed only once total)
            rotatedUV.y = 1 - rotatedUV.y;

            input.uv = rotatedUV;

            // Discard if outside bounds
            if (rotatedUV.x < 0.0 || rotatedUV.x > 1.0 || rotatedUV.y < 0.0 || rotatedUV.y > 1.0)
                discard;
        }
        else
            input.uv.y = 1 - input.uv.y;


        uint width, height;
        tex.GetDimensions(width, height);
        if (!width || !height) discard;
        result = tex.Load(int3(input.uv.xy * float2(width, height), 0));

        if (SPECIAL_EFFECT == 96) {
            float3 hsvTex = RGBtoHSV(result.rgb); // Original texture HSV
            float3 packed = float3(0,0,0);
        
            if (useWhichPacked == 0) {
                // HSV sliders
                packed = UnpackHSV(packedHSV); // Expect H in [0..360], S/V in [0..1]
                
                hsvTex.x = lerp(hsvTex.x, packed.x, TINT_STRENGTH);
                hsvTex.y = lerp(hsvTex.y, packed.y, TINT_STRENGTH);
                hsvTex.z = lerp(hsvTex.z, packed.z, TINT_STRENGTH * 0.1); // small V shift

                result.rgb = HSVtoRGB(hsvTex.x, hsvTex.y, hsvTex.z);
            }
            else if (useWhichPacked == 1) {
                // RGB sliders
                float3 rgbPacked = UnpackRGB(packedRGB);
                float3 hsvPacked = RGBtoHSV(rgbPacked);
        
                hsvTex.x = lerp(hsvTex.x, hsvPacked.x, TINT_STRENGTH);
                hsvTex.y = lerp(hsvTex.y, hsvPacked.y, TINT_STRENGTH);
                hsvTex.z = lerp(hsvTex.z, hsvPacked.z, TINT_STRENGTH * 0.1);

                result.rgb = HSVtoRGB(hsvTex.x, hsvTex.y, hsvTex.z);
            }
            else if (useWhichPacked == 2) {
                float3 hsl = UnpackHSL(packedHSL);

                // Step 1: Convert RGB input to HSL
                float3 texHSL = RGBtoHSL(result.rgb);

                // Blend between original lightness and tint lightness
                float blendLightness = lerp(texHSL.z, hsl.z, TINT_STRENGTH);

                // Step 2: Blend hue and saturation, but keep the lightness from the original pixel
                float3 targetHSL = float3(hsl.x*360, hsl.y, blendLightness); // preserve lightness

                
                //float3 blendedHSL = lerp(texHSL, targetHSL, 0.5);

                result.rgb = HSLtoRGB(float3(targetHSL.x, targetHSL.y, targetHSL.z));
            }

        }

        if (UseDirection){
            float dist;

            if (Direction == 0)
                dist = abs(input.uv.x - 0.25);
    
            else if (Direction == 1)
                dist = abs(input.uv.x - 0.75);

            float mask = 0.2 - smoothstep(0.15, 0.5, dist);

            if (Direction != -1)
                result.rgb += mask;
        }

        if (USE_FADEOUT == 69)
            result.a *= saturate(FadeOut);
    }
}
#endif

