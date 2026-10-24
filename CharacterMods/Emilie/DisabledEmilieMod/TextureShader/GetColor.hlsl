RWBuffer<float4> color : register(u6);
RWBuffer<float4> color_hair : register(u7);
RWBuffer<float4> color_eyes : register(u4);

Texture2D<float4> CWheel : register(t52);
Texture1D<float4> IniParams : register(t120);

#define RGB_Toggle IniParams[99].x

[numthreads(32, 32, 1)]
void main(uint3 threadID : SV_DispatchThreadID)
{
    uint3 CWheelPos = uint3(IniParams[101].x, IniParams[101].y, 0);
    uint3 CWheelPos2 = uint3(IniParams[101].z, IniParams[101].w, 0);
    uint3 CWheelPos3 = uint3(IniParams[102].x, IniParams[102].y, 0);
    

    if(threadID.x == CWheelPos.x && threadID.y == CWheelPos.y)
            color[0] = float4(CWheel[threadID.xy].r, CWheel[threadID.xy].g, CWheel[threadID.xy].b, 1);

    if(threadID.x == CWheelPos2.x && threadID.y == CWheelPos2.y)
            color_hair[0] = float4(CWheel[threadID.xy].r, CWheel[threadID.xy].g, CWheel[threadID.xy].b, 1);

    if(threadID.x == CWheelPos3.x && threadID.y == CWheelPos3.y)
            color_eyes[0] = float4(CWheel[threadID.xy].r, CWheel[threadID.xy].g, CWheel[threadID.xy].b, 1);

         
    
}