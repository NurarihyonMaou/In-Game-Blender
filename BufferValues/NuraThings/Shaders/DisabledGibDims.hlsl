// Compute Shader example to verify font dimensions & char dims

RWStructuredBuffer<float4> Debug : register(u0); // debug output buffer

// Assume your font resource:
Texture2D<float> font : register(t0);

static float2 char_size;
static float2 meta_pos_start;

void get_meta()
{
    float font_width, font_height;
    font.GetDimensions(font_width, font_height);
    char_size = float2(font_width, font_height) / float2(16, 6);
    meta_pos_start = float2(15 * char_size.x, 5 * char_size.y);
}

float2 get_char_dimensions(uint c)
{
    float2 meta_pos;
    float2 dim;

    meta_pos.x = meta_pos_start.x + (c % 16);
    meta_pos.y = meta_pos_start.y + (c / 16 - 2) * 2;

    dim.x = font.Load(int3(meta_pos.xy, 0)) * 255;
    meta_pos.y += 1;
    dim.y = font.Load(int3(meta_pos.xy, 0)) * 255;

    return dim;
}

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    get_meta();

    uint c = DTid.x;

    if (c < 128)
    {
        float2 dims = get_char_dimensions(c);

        // Write debug info: (char_code, width, height, unused)
        Debug[c] = float4(c, dims.x, dims.y, 0);
    }
}
