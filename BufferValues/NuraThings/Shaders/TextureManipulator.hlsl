// Compute shader to modify texture color based on target

RWTexture2D<float4> texOutput : register(u0); // The output texture (manipulated texture)
Texture2D<float4> texInput : register(t0);   // The input texture (original texture)
Texture2D<float4> Mask : register(t2);

Buffer<float> Colors : register(t1);
RWBuffer<float4> Debug : register(u1); 

Texture1D<float4> IniParams : register(t120);

#define TINT_STRENGTH IniParams[92].w
#define AFFECT_RANGE IniParams[92].xy
#define SELECTOR_TYPE IniParams[91].w
#define MASK_MODE IniParams[92].z

#define targetColors float3(Colors[0], Colors[1], Colors[2])

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

// Compute shader main entry point
[numthreads(16, 16, 1)]  // This specifies the number of threads per group
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    float4 inputColor = texInput[dispatchThreadID.xy];
    float3 rgb = inputColor.rgb;

    // Convert current pixel to HSV
    float3 pixelHSV = RGBtoHSV(rgb);
    
    float hue = pixelHSV.x; // [0-360]
    float center = AFFECT_RANGE.x;
    float range = AFFECT_RANGE.y;

    // Compute shortest distance around hue circle
    float hueDiff = abs(hue - center);
    hueDiff = min(hueDiff, 360.0 - hueDiff);

    // Strength of effect based on hue range
    float affectStrength = 0; // soft edges

    if (MASK_MODE == 0)
        affectStrength = smoothstep(range, range - 5.0, hueDiff);

    else if (MASK_MODE == 1){

        uint tw, th;
        texInput.GetDimensions(tw, th);

        uint mw, mh;
        Mask.GetDimensions(mw, mh);

        float2 uv = (dispatchThreadID.xy + 0.5) / float2(tw, th);

        uint2 maskPos = uint2(uv * float2(mw, mh));

        affectStrength = Mask[maskPos].r;
    }

    //float affectStrength=saturate((range-hueDiff)/5.0);
    // Optional: curve to control falloff softness
    // affectStrength = pow(saturate(affectStrength), 1.5);
    
    // Lerp HSV toward target
    
    //float3 hsvMixed = lerp(pixelHSV, targetHSV, affectStrength * TINT_STRENGTH);

    // Blend V slightly to allow some brightness shift but preserve texture


    if (SELECTOR_TYPE == 0){
            float3 hsvMixed = float3(
                lerp(pixelHSV.x, targetColors.x, affectStrength * TINT_STRENGTH),
                lerp(pixelHSV.y, targetColors.y, affectStrength * TINT_STRENGTH),
                lerp(pixelHSV.z, targetColors.z, affectStrength * TINT_STRENGTH * 0.1)  // small V blend
            );

    //float3 rgbMixed = float3(
    //    lerp(rgb.x, targetColors.x, affectStrength * TINT_STRENGTH),
    //    lerp(rgb.y, targetColors.y, affectStrength * TINT_STRENGTH),
    //    lerp(rgb.z, targetColors.z, affectStrength * TINT_STRENGTH)  // small V blend
    //);

        float3 finalColor = HSVtoRGB(hsvMixed.x, hsvMixed.y, hsvMixed.z);
        texOutput[dispatchThreadID.xy] = float4(finalColor, inputColor.a);
    }
    else if (SELECTOR_TYPE == 1){
        float luminance = dot(rgb, float3(0.3, 0.59, 0.11)); // or float3(0.2126, 0.7152, 0.0722) for sRGB

        // Normalize target color to preserve brightness shape
        float3 tintColor = normalize(HSVtoRGB(targetColors.x, targetColors.y, targetColors.z));
        float3 tinted = tintColor * luminance;

        // Blend between original and tinted
        float3 rgbMixed = lerp(rgb, tinted, affectStrength * TINT_STRENGTH);

       texOutput[dispatchThreadID.xy] = float4(rgbMixed, inputColor.a);
    }
 
    else if (SELECTOR_TYPE == 2){
        float3 targetToHSL = HSVtoHSL(targetColors);

        // Step 1: Convert RGB input to HSL
        float3 texHSL = RGBtoHSL(rgb);

        // Blend between original lightness and tint lightness
        float blendLightness = lerp(texHSL.z, targetToHSL.z, TINT_STRENGTH);

        // Step 2: Blend hue and saturation, but keep the lightness from the original pixel
        float3 targetHSL = float3(targetToHSL.x, targetToHSL.y, blendLightness); // preserve lightness

        // Step 3: Blend between original and target
        float3 blendedHSL = lerp(texHSL, targetHSL, affectStrength);

        // Step 4: Convert back to RGB
        float3 finalRGB = HSLtoRGB(blendedHSL);

        texOutput[dispatchThreadID.xy] = float4(finalRGB, inputColor.a);
    }

        //float4(float3(texInput[dispatchThreadID.xy].rgb * (targetHSV.xyz*(affectStrength * TINT_STRENGTH))), inputColor.a);

    //if(inputColor.r >= 0.3){
    //    float4 inputColor = texInput[dispatchThreadID.xy];
//
    //    // Convert the original texture color to grayscale (perceived brightness)
    //    float luminance = dot(inputColor.rgb, float3(0.299, 0.587, 0.114));
//
    //    // Apply HSV tint, multiplied by luminance to retain texture details
    //    float3 hsvTint = HSVtoRGB(HSV[0], HSV[1], HSV[2]);
    //    float3 finalColor = hsvTint * luminance;
//
    //    float3 mixed = lerp(inputColor.rgb, finalColor, TINT_STRENGTH); // 0.0 - 1.0
//
    //    // Output with preserved alpha
    //    texOutput[dispatchThreadID.xy] = float4(mixed, inputColor.a);
//
    //    
    //}
    //else
    //    texOutput[dispatchThreadID.xy] = inputColor;

   //if (all(dispatchThreadID.xy == uint2(0, 0))){
   //    //Debug[6] = float4(affectStrength, 1, 1, 1);
   //    Debug[7] = float4(finalColor, inputColor.a);
   //    Debug[8] = float4(hue, center, range, hueDiff);
   //    Debug[9] = float4(pixelHSV, TINT_STRENGTH);
   //    Debug[10] = float4(SELECTOR_TYPE, 0, 0, 69);
   //    Debug[11] = float4(targetColors, 72);
   //}
}