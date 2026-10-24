Texture1D<float4> IniParams : register(t120);

RWBuffer<float> HoveredID : register(u0);
Texture2D<float4> Image : register(t0);

#define SIZE     IniParams[87].xy
#define OFFSET   IniParams[87].zw

#define ELEM_ID  IniParams[54].x
#define CURSOR_X IniParams[54].y
#define CURSOR_Y IniParams[54].z


[numthreads(1, 1, 1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    // 1️⃣ Bounding box test
    bool inside =
        (CURSOR_X >= OFFSET.x) &&
        (CURSOR_X <= OFFSET.x + SIZE.x) &&
        (CURSOR_Y >= OFFSET.y) &&
        (CURSOR_Y <= OFFSET.y + SIZE.y);

    if (!inside)
        return;

    // 2️⃣ Convert cursor to local UV (0–1 inside element)
    float2 localUV;
    localUV.x = (CURSOR_X - OFFSET.x) / SIZE.x;
    localUV.y = (CURSOR_Y - OFFSET.y) / SIZE.y;

    // Flip Y jeśli potrzebujesz (zależnie od orientacji)
    localUV.y = 1.0 - localUV.y;

    // 3️⃣ Get texture size
    uint width, height;
    Image.GetDimensions(width, height);

    if (width == 0 || height == 0)
        return;

    // 4️⃣ Convert UV to pixel coords
    uint px = clamp((uint)(localUV.x * width), 0, width - 1);
    uint py = clamp((uint)(localUV.y * height), 0, height - 1);

    float alpha = Image.Load(int3(px, py, 0)).a;

    // 5️⃣ Write result
    if (alpha > 0.01)
        HoveredID[0] = ELEM_ID;
}
