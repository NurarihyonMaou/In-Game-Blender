RWTexture2D<float4> tex : register(u5);
Texture2D<float4> mask : register(t51);
RWBuffer<float4> color : register(u6);
RWBuffer<float4> color_hair : register(u7);
RWBuffer<float4> color_eyes : register(u4);

Texture1D<float4> IniParams : register(t120);
#define Color IniParams[87].xyzw
#define Hair_Color IniParams[88].xyzw
#define Eyes_Color IniParams[89].xyzw

#define RGB_Toggle IniParams[99].x
#define Slider_Type IniParams[99].y

#define Hue_Val IniParams[100].x
#define Hue_Val_Hair IniParams[100].y
#define Hue_Val_Eyes IniParams[100].z

float4 convertHueToRGB(float Hue){
	    if(Hue == -1)
		return float4(1, 1, 1, 1);    

            float H = Hue;
            float R = abs(H * 6 - 3) - 1;
            float G = 2 - abs(H * 6 - 2);
            float B = 2 - abs(H * 6 - 4);
            
            return saturate(float4(R, G, B, 1));
}

[numthreads(32, 32, 1)]
void main(uint3 threadID : SV_DispatchThreadID)
{
    float4 outfit = float4(0, 0, 0, 0);
    float4 hair = float4(0, 0, 0, 0);
    float4 eyes = float4(0, 0, 0, 0);

    if(color[0].w != 0 || color_hair[0].w != 0 || color_eyes[0].w != 0){
        outfit = color[0];
        hair = color_hair[0];
        eyes = color_eyes[0];
    }

    if(RGB_Toggle == 0 && tex[threadID.xy].r >= 0.04 && tex[threadID.xy].g <= 0.15 && tex[threadID.xy].b <= 0.15){
        switch(Slider_Type){
            case 0:
                tex[threadID.xy] = lerp(tex[threadID.xy], Color, 0.1);
                //tex[threadID.xy] *= Color;
                break;
            case 1:
                tex[threadID.xy] *= lerp(tex[threadID.xy], convertHueToRGB(Hue_Val), 15);
                 break;
            case 2:
                tex[threadID.xy] = lerp(tex[threadID.xy], outfit, 0.1);
                //tex[threadID.xy] *= outfit;
                break;
        }
    }

    else if (RGB_Toggle == 1){
        if(mask[threadID.xy].r >= 0.99 && mask[threadID.xy].g == 0 && mask[threadID.xy].b == 0)
            switch(Slider_Type){
                case 0:
                    tex[threadID.xy] = lerp(tex[threadID.xy], Hair_Color, 0.1);
                    //tex[threadID.xy] *= Hair_Color;
                    break;
                case 1:
                    tex[threadID.xy] *= lerp(tex[threadID.xy], convertHueToRGB(Hue_Val_Hair), 15);
                     break;
                case 2:
                    tex[threadID.xy] = lerp(tex[threadID.xy], hair, 0.1);
                    //tex[threadID.xy] *= hair;
                    break;
            }
    }
    else if (RGB_Toggle == 2)
        if(tex[threadID.xy].r >= 0.05 && tex[threadID.xy].g <= 0.15 && tex[threadID.xy].b <= 0.3){
            switch(Slider_Type){
                case 0:
                    tex[threadID.xy] = lerp(tex[threadID.xy], Eyes_Color, 0.1);
                    //tex[threadID.xy] *= Eyes_Color;
                    break;
                case 1:
                    tex[threadID.xy] *= lerp(tex[threadID.xy], convertHueToRGB(Hue_Val_Eyes), 15);
                     break;
                case 2:
                    tex[threadID.xy] = lerp(tex[threadID.xy], eyes, 0.1);
                    //tex[threadID.xy] *= eyes;
                    break;
            }
    }
}