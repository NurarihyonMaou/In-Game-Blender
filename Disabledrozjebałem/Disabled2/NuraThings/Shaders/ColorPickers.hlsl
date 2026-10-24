// Output texture
RWTexture2D<float4> texOutput : register(u0);
Texture1D<float4> IniParams : register(t120);
RWBuffer<float> StoreColors : register(u1); // H, S, V, PackedColor (RGB/HSV/HSL)
RWBuffer<float4> Debug : register(u2); 
//RWStructuredBuffer<float3> StoredGlowColors : register(u3); 

#define CURSOR IniParams[89].xy
#define SCREEN_RES IniParams[89].zw

#define RGBA IniParams[90].xyzw
#define AFFECT_COLOR IniParams[91].x

#define USE_PACKED IniParams[91].y
#define PACKED_COLOR IniParams[91].z

#define SELECTOR_TYPE IniParams[91].w

#define KURWA IniParams[93].xyzw
#define TESTKURWA IniParams[100].xyz

#define PI 3.14
//#define HUE_RANGE IniParams[92].zw


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


// Optional RGBA/HSV Mix
float3 MixRGBAwithHSV(float3 baseRGB, float4 rgba, float3 hsv)
{
    float3 hsvColor = HSVtoRGB(hsv.x, hsv.y, hsv.z);
    return lerp(baseRGB, hsvColor, rgba.w); // Mix based on Alpha
}


float3 ComplementaryColor(float3 color)
{
    return float3(1.0, 1.0, 1.0) - color; // Inverts the Color to get the Complementary Color
}


float PackHSV(float3 hsv)
{
    // Clamp to safety bounds
    hsv.x = clamp(hsv.x, 0.0, 360.0);
    hsv.y = clamp(hsv.y, 0.0, 1.0);
    hsv.z = clamp(hsv.z, 0.0, 1.0);

    uint H = (uint)(hsv.x / 360.0 * 65535.0 + 0.5); // 16 bits
    uint S = (uint)(hsv.y * 255.0 + 0.5);           // 8 bits
    uint V = (uint)(hsv.z * 255.0 + 0.5);           // 8 bits

    uint packed = (H << 16) | (S << 8) | V;
    return asfloat(packed);
}


float3 UnpackHSV(float packed)
{
    uint data = asuint(packed);

    uint H = (data >> 16) & 0xFFFF;
    uint S = (data >> 8) & 0xFF;
    uint V = data & 0xFF;

    float3 hsv;
    hsv.x = (float)H / 65535.0 * 360;
    hsv.y = (float)S / 255.0;
    hsv.z = (float)V / 255.0;

    return hsv;
}


float PackRGB(float3 rgb)
{
    // Clamp values to [0,1]
    rgb = saturate(rgb);

    uint R = (uint)(rgb.r * 1023.0 + 0.5); // 10 bits
    uint G = (uint)(rgb.g * 1023.0 + 0.5); // 10 bits
    uint B = (uint)(rgb.b * 1023.0 + 0.5); // 10 bits

    // Layout: 0RRRRRRRRRR GGGGGGGGGG BBBBBBBBBB (2 bits unused)
    uint packed = (R << 20) | (G << 10) | B;
    return asfloat(packed);
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


float PackHSL(float3 hsl)
{
    // Clamp to safe bounds
    hsl.x = clamp(hsl.x, 0.0, 360.0); // Hue
    hsl.y = clamp(hsl.y, 0.0, 1.0);   // Saturation
    hsl.z = clamp(hsl.z, 0.0, 1.0);   // Lightness

    uint H = (uint)(hsl.x / 360 * 65535.0 + 0.5); // 16 bits
    uint S = (uint)(hsl.y * 255.0 + 0.5);           // 8 bits
    uint L = (uint)(hsl.z * 255.0 + 0.5);           // 8 bits

    uint packed = (H << 16) | (S << 8) | L;
    return asfloat(packed);
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


float3 HSLtoHSV(float3 hsl)
{
    float H = hsl.x;
    float S = hsl.y;
    float L = hsl.z;

    float V = L + S * min(L, 1.0 - L);
    float newS = (V == 0.0) ? 0.0 : 2.0 * (1.0 - L / V);

    return float3(H, newS, V); // HSV
}


float2 GetCursorUV()
{
    return CURSOR / SCREEN_RES;
}


float2 GetCursorDelta(float2 regionCenter)
{
    return GetCursorUV() - regionCenter;
}


bool IsCursorInRect(float2 minUV, float2 maxUV)
{
    float2 cursor = GetCursorUV();
    return all(cursor >= minUV) && all(cursor <= maxUV);
}


float CursorLightnessInBar(float2 minUV, float2 maxUV)
{
    float y = GetCursorUV().y;
    return saturate((y - minUV.y) / (maxUV.y - minUV.y));
}



// Minimal HSV <-> RGB conversion
float3 MinimalRGBtoHSV(float3 c) {
    float4 K = float4(0., -1./3., 2./3., -1.);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1e-10;
    return float3(abs(q.z + (q.w - q.y)/(6.*d + e)), d/(q.x + e), q.x);
}

float3 MinimalHSVtoRGB(float h, float s, float v) {
    float3 rgb = clamp(abs(frac(h + float3(0., 1./3., 2./3.)) * 6. - 3.), 0., 1.);
    return v * lerp(float3(1., 1., 1.), rgb, s);
}



[numthreads(32, 32, 1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    float2 texSize = float2(512, 512);
    uint2 pixel = DTid.xy;
    float2 uv = pixel / texSize;

    float x = uv.x;
    float y = 1.0 - uv.y;

    float3 color = float3(0, 0, 0);

    float alpha = 1.0;

    float2 imageOffset = float2(IniParams[24].x, IniParams[24].y);
    float2 imageSize = float2(512.0 / SCREEN_RES.x, 512.0 / SCREEN_RES.y);
    float2 imageCursor = (CURSOR - imageOffset) / imageSize;

    float cursorX = imageCursor.x;
    float cursorY = imageCursor.y;

    bool colorUpdated = false;

    float barWidth = 1.0 / 3.0;

    bool OutputSet = false;

    float offsetPreveiewBox = 0.2;

    switch(SELECTOR_TYPE){
        case 0:
            // StoreColors[0] = Hue, [1] = Saturation, [2] = Value.
            float3 unpackedHSV = UnpackHSV(PACKED_COLOR);

            float3 hsv = float3(StoreColors[0], StoreColors[1], StoreColors[2]);

            if (USE_PACKED){
                hsv = unpackedHSV;

                if (all(DTid.xy == uint2(0, 0))){
                    StoreColors[0] = hsv.x; // Hue
                    StoreColors[1] = hsv.y; // Saturation
                    StoreColors[2] = hsv.z; // Fix Inversion
                    StoreColors[3] = PackHSV(hsv);
                }
            }


            if (AFFECT_COLOR){
                if (cursorX < barWidth)
                {
                    hsv.x = (1.0 - cursorY) * 360.0;
                    colorUpdated = true;
                }
                else if (cursorX < 2.0 * barWidth)
                {
                    hsv.y = 1.0 - cursorY;
                    colorUpdated = true;
                }
                else if (cursorX < 3.0 * barWidth)
                {
                    hsv.z = 1.0 - cursorY;
                    colorUpdated = true;
                }
            }

            if (x < barWidth)
            {
                float hue = y*360;
                color = HSVtoRGB(hue, 1.0, 1.0);
            }
            else if (x < 2.0 * barWidth)
            {
                float sat = y;
                color = HSVtoRGB(hsv.x, sat, 1.0);
            }
            else if (x < 3.0 * barWidth)
            {
                float val = y;
                color = HSVtoRGB(hsv.x, hsv.y, val);
            }


            if (x > 0.75 && x < 0.95 && y > 0.1 && y < 0.3)
            {
                color = HSVtoRGB(hsv.x, hsv.y, hsv.z);
                break;
            }

            // --- Marker Overlay with Complementary Color ---
            if (x < 3.0 * barWidth)
            {
                float markerVal = 0.0;
                float3 markerColor = float3(1.0, 1.0, 1.0); // Default White

                // Determine the Marker Value and set the Marker Color based on the Bar.
                if (x < barWidth) // Hue Bar
                {
                    markerVal = hsv.x / 360.0;
                    markerColor = ComplementaryColor(HSVtoRGB(hsv.x, 1.0, 1.0)); // Use Complementary of the Hue Color
                }
                else if (x < 2.0 * barWidth) // Saturation Bar
                {
                    markerVal = hsv.y;
                    markerColor = ComplementaryColor(HSVtoRGB(hsv.x, hsv.y, 1.0)); // Use Complementary of the Saturation Color
                }
                else // Value Bar
                {
                    markerVal = hsv.z;
                    markerColor = ComplementaryColor(HSVtoRGB(hsv.x, hsv.y, hsv.z)); // Use Complementary of the Value Color
                }

                // Compute an Overlay Factor (a Smooth Threshold) so that Pixels near the Marker get Blended.
                float markerOverlay = smoothstep(0.02, 0.0, abs(y - markerVal));
                // Blend in the Complementary Color for the Marker.
                color = lerp(color, markerColor, markerOverlay);
            }

            // === MARKER RING ===
            float dist = distance(uv, imageCursor);
            float radius = 2.5 / texSize.x;
            float thickness = 1.5 / texSize.x;
            float circle = smoothstep(radius + thickness, radius, dist);
            color = lerp(color, float3(1, 1, 1), circle);

            // Save HSV only once (First Thread)
            if (all(DTid.xy == uint2(0, 0)) && (colorUpdated))
            {
                StoreColors[0] = hsv.x;
                StoreColors[1] = hsv.y;
                StoreColors[2] = hsv.z;
                StoreColors[3] = PackHSV(float3(hsv.x, hsv.y, hsv.z));
            }

            if (all(DTid.xy == uint2(0, 0))){

                Debug[0] = float4(hsv.x, hsv.y, hsv.z, 1);
                Debug[1] = float4(RGBA.x, RGBA.y, RGBA.z, RGBA.w);
                Debug[2] = float4(pixel, x, y);
                Debug[3] = float4(color, 1);
                Debug[4] = float4(cursorX, 1, 1, 1);
                Debug[5] = float4(imageCursor, 1, AFFECT_COLOR);
                Debug[6] = float4(StoreColors[0], StoreColors[1], StoreColors[2], StoreColors[3]);
                Debug[7] = float4(KURWA);
            }
        break;
        
        case 1:
            {
                float3 unpackedRGB = UnpackRGB(PACKED_COLOR);
                float3 rgb = HSVtoRGB(StoreColors[0], StoreColors[1], StoreColors[2]); // Reuse StoreColors for RGB

                if (USE_PACKED){
                    rgb = unpackedRGB;

                    float3 rgb_to_hsv = RGBtoHSV(rgb);

                    if (all(DTid.xy == uint2(0, 0))){
                        StoreColors[0] = rgb_to_hsv.x; // Hue
                        StoreColors[1] = rgb_to_hsv.y; // Saturation
                        StoreColors[2] = rgb_to_hsv.z; // Fix Inversion
                        StoreColors[3] = PackRGB(rgb);
                        Debug[12] = float4(69, 69, 69, 69);
                    }
                }


                if (AFFECT_COLOR) {
                    if (cursorX < barWidth)
                    {
                        rgb.r = saturate(1-cursorY);
                        colorUpdated = true;
                    }
                    else if (cursorX < 2.0 * barWidth)
                    {
                        rgb.g = saturate(1-cursorY);
                        colorUpdated = true;
                    }
                    else if (cursorX < 3.0 * barWidth)
                    {
                        rgb.b = saturate(1-cursorY);
                        colorUpdated = true;
                    }
                }

                float3 mid; // target RGB
                if (x < barWidth)
                {
                    mid = float3(1, 0, 0); // Red
                }
                else if (x < 2.0 * barWidth)
                {
                    mid = float3(0, 1, 0); // Green
                }
                else if (x < 3.0 * barWidth)
                {
                    mid = float3(0, 0, 1); // Blue
                }

                // Final Gradient from Color → Black (Top to Bottom)
                color = lerp(mid, float3(0, 0, 0), 1.0 - y);

                // Preview Box
                if (x > 0.75 && x < 0.95 && y > 0.1 && y < 0.3)
                {
                    color = rgb;
                }

                // Marker overlay
                if (x < 3.0 * barWidth)
                {
                    float markerVal = 0.0;
                    float3 markerColor = float3(1.0, 1.0, 1.0);

                    if (x < barWidth) {
                        markerVal = rgb.r;
                        markerColor = ComplementaryColor(float3(rgb.r, 0, 0));
                    } else if (x < 2.0 * barWidth) {
                        markerVal = rgb.g;
                        markerColor = ComplementaryColor(float3(0, rgb.g, 0));
                    } else {
                        markerVal = rgb.b;
                        markerColor = ComplementaryColor(float3(0, 0, rgb.b));
                    }

                    float markerOverlay = smoothstep(0.02, 0.0, abs(y - markerVal));
                    color = lerp(color, markerColor, markerOverlay);
                }

                // Marker ring at cursor
                float dist = distance(uv, imageCursor);
                float radius = 2.5 / texSize.x;
                float thickness = 1.5 / texSize.x;
                float circle = smoothstep(radius + thickness, radius, dist);
                color = lerp(color, float3(1, 1, 1), circle);

                if (all(DTid.xy == uint2(0, 0)) && (colorUpdated))
                {
                    //if(!RETURN_HSV){
                    float3 rgb_to_hsv = RGBtoHSV(rgb);
                    StoreColors[0] = rgb_to_hsv.r;
                    StoreColors[1] = rgb_to_hsv.g;
                    StoreColors[2] = rgb_to_hsv.b;
                    StoreColors[3] = PackRGB(rgb);

                }

                if (all(DTid.xy == uint2(0, 0)))
                {
                    Debug[0] = float4(rgb, 1);
                    Debug[1] = float4(RGBA.xyz, RGBA.w);
                    Debug[2] = float4(pixel, 1, 1);
                    Debug[3] = float4(color, 1);
                    Debug[4] = float4(cursorX, 1, 1, 1);
                    Debug[5] = float4(imageCursor, 1, AFFECT_COLOR);
                    Debug[6] = float4(StoreColors[0], StoreColors[1], StoreColors[2], StoreColors[3]);
                    Debug[7] = float4(KURWA);
                }
            }
        break;

        case 2:
        {
            float2 center = float2(0.4, 0.5);  // Center of Wheel
            float radius = 0.38;
            float innerRadius = 0.0;
        
            float2 barMin = float2(0.82, 0.15);
            float2 barMax = float2(0.86, 0.85);
        
            float2 fromCenter = float2(x, y) - center;
            float dist = length(fromCenter);
            float angle = atan2(fromCenter.y, fromCenter.x);
            if (angle < 0.0) angle += 2.0 * PI;
        
            float3 unpackedHSL = UnpackHSL(PACKED_COLOR);

            float hue = angle / (2.0 * PI);
            float sat = saturate((dist - innerRadius) / (radius - innerRadius));
        
            alpha = 0;

            float3 hsl = HSVtoHSL(float3(StoreColors[0], StoreColors[1], StoreColors[2]));

            float3 hsl_to_hsv = HSLtoHSV(hsl);

            if (USE_PACKED){
                hsl = unpackedHSL;

                hsl_to_hsv = HSLtoHSV(hsl);

                if (all(DTid.xy == uint2(0, 0))){
                    StoreColors[0] = hsl_to_hsv.x*360; // Hue
                    StoreColors[1] = hsl_to_hsv.y; // Saturation
                    StoreColors[2] = hsl_to_hsv.z; // Fix Inversion
                    StoreColors[3] = PackHSL(hsl_to_hsv);
                }
            }
            //}

            if (all(DTid.xy == uint2(0, 0)))
            {
                Debug[8] = float4(hsl, USE_PACKED);
                Debug[9] = float4(TESTKURWA, StoreColors[3]);
                Debug[10] = float4(StoreColors[0], StoreColors[1], StoreColors[2], PACKED_COLOR);
            }

            // --- Color Wheel (Hue/Saturation) ---
            if (dist >= innerRadius && dist <= radius)
            {
                float3 rgb = HSLtoRGB(float3(hue, sat, hsl.z)); // Apply selected Lightness
                color = rgb;
                alpha = 1.0;
                OutputSet = true;
            }
        
            // --- Lightness Bar ---
            if (x >= barMin.x && x <= barMax.x && y >= barMin.y && y <= barMax.y)
            {
                float lightness = saturate((barMax.y - y) / (barMax.y - barMin.y)); // Inverted Visually
                float3 rgb = HSLtoRGB(float3(hsl.x, hsl.y, lightness));
                color = rgb;
                alpha = 1.0;
                OutputSet = true;
            }
        
            // --- Input Handling ---
            if (!OutputSet && AFFECT_COLOR && x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0)
            {
                if (!colorUpdated)
                {
                    float2 cursorVec = float2(cursorX, 1.0 - cursorY) - center;
                    float cursorDist = length(cursorVec);
                    float cursorAngle = atan2(cursorVec.y, cursorVec.x);
                    if (cursorAngle < 0.0) cursorAngle += 2.0 * PI;
                    
                    // Clicked on Color Wheel
                    if (cursorDist >= innerRadius && cursorDist <= radius)
                    {
                        hsl.xy = float2((cursorAngle / (2.0 * PI)), saturate((cursorDist - innerRadius) / (radius - innerRadius)));

                        hsl_to_hsv = HSLtoHSV(hsl);

                        StoreColors[0] = hsl_to_hsv.x; // Hue
                        StoreColors[1] = hsl_to_hsv.y; // Saturation
                        StoreColors[2] = hsl_to_hsv.z; // Fix Inversion
                        StoreColors[3] = PackHSL(hsl);
                        
                        colorUpdated = true;
                    }
        
                    // Clicked on Lightness Bar
                    if (cursorX >= barMin.x && cursorX <= barMax.x &&
                        (1.0 - cursorY) >= barMin.y && (1.0 - cursorY) <= barMax.y)
                    {
                        hsl.z = saturate((barMax.y - (1.0 - cursorY)) / (barMax.y - barMin.y));

                        hsl_to_hsv = HSLtoHSV(hsl);

                        StoreColors[0] = hsl_to_hsv.x; // Hue
                        StoreColors[1] = hsl_to_hsv.y; // Saturation
                        StoreColors[2] = hsl_to_hsv.z; // Fix Inversion
                        StoreColors[3] = PackHSL(hsl);

                        colorUpdated = true;
                    }


                }
            }
        
            // --- Cursor Marker (Wheel) ---
            float2 marker = center + float2(cos(hsl.x * 2.0 * PI), sin(hsl.x * 2.0 * PI)) * lerp(innerRadius, radius, hsl.y);
            if (distance(float2(x, y), marker) < 0.015)
            {
                color = 1.0 - color;
                alpha = 1.0;
            }
        
            // --- Cursor Marker (Lightness Bar) ---
            float lightnessY = lerp(barMax.y, barMin.y, hsl.z); // Y is Inverted Visually
            if (x >= barMin.x && x <= barMax.x && abs(y - lightnessY) < 0.008)
            {
                color = 1.0 - color;
                alpha = 1.0;
            }

            if (all(DTid.xy == uint2(0, 0)))
            {
                Debug[0] = float4(hsl, 1);
                //Debug[1] = float4(hsl_to_hsv, 1);
                Debug[2] = float4(pixel, 1, USE_PACKED);
                Debug[3] = float4(color, SELECTOR_TYPE);
                Debug[4] = float4(cursorX, cursorY, 1, 1);
                Debug[5] = float4(imageCursor, 1, AFFECT_COLOR);
                Debug[6] = float4(StoreColors[0], StoreColors[1], StoreColors[2], StoreColors[3]);
                Debug[7] = float4(KURWA);
            }
        }
        break;

        default:
            return;
    }

    texOutput[pixel] = float4(color, alpha);
}
