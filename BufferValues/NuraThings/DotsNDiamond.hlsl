//====================================================
// 3DMigoto declarations
//====================================================

Texture1D<float4> IniParams : register(t120);

Texture2D DotTex     : register(t41);
Texture2D DiamondTex : register(t42);

Buffer<int3> DrawData : register(t40);

SamplerState LinearSampler : register(s0);


//====================================================
// Params
//====================================================

// x33 = R of Icons
// y33 = G of Icons
// z33 = B of Icons
// w33 = ImageMode

#define RIcon ((float)IniParams[33].x)
#define GIcon ((float)IniParams[33].y)
#define BIcon ((float)IniParams[33].z)

#define ImageMode ((int)IniParams[33].w)


// x34 = IconSize
// y34 = MinGap
// z34 = MaxWidth
// w34 = DotSpacingY

#define IconSize    IniParams[34].x
#define MinGap      IniParams[34].y
#define MaxWidth    IniParams[34].z


#define PosX IniParams[35].x
#define PosY IniParams[35].y

//====================================================
// Vertex Shader
//====================================================

#ifdef VERTEX_SHADER

struct VS_OUT
{
    float4 pos : SV_POSITION;
};

VS_OUT main(uint id : SV_VertexID)
{
    VS_OUT o;

    float2 verts[3] =
    {
        float2(-1,-1),
        float2(-1, 3),
        float2(3,-1)
    };

    o.pos = float4(verts[id],0,1);

    return o;
}

#endif


//====================================================
// Pixel Shader
//====================================================

#ifdef PIXEL_SHADER

struct PS_INPUT
{
    float4 pos : SV_POSITION;
};


float4 DrawSDF(
    float dist,
    float4 fillColor,
    float4 outlineColor,
    float outlineWidth)
{
    // Anti-alias width
    float aa = max(fwidth(dist), 0.001);

    // Interior
    float fill =
        1.0 - smoothstep(-aa, aa, dist);

    // Outer outline only
    float outline =
        smoothstep(outlineWidth + aa,
                   outlineWidth - aa,
                   dist) *
        (1.0 - fill);

    float4 result = float4(0,0,0,0);

    result.rgb =
          fillColor.rgb    * fill
        + outlineColor.rgb * outline;

    result.a =
          fillColor.a    * fill
        + outlineColor.a * outline;

    return result;
}

float CircleSDF(float2 p, float size)
{
    return length(p) - size * 0.5;
}

float DiamondSDF(float2 p, float radius)
{
    p /= radius;

    return abs(p.x) + abs(p.y) - 1.0;
}

float4 main(PS_INPUT input) : SV_Target
{
    //------------------------------------------------
    // Screen UV
    //------------------------------------------------

    float2 resolution = float2(1920.0,1080.0);

    float2 uv = input.pos.xy - resolution * 0.5;

    uv /= resolution.y;


    // ResponsiveUI style position

    float2 offset;

    offset.x = PosX * 2.0 - 1.0;
    offset.y = PosY * 2.0 - 1.0;


    // zamiana clip -> pixel units

    offset *= 0.5 * resolution.y;

    uv -= offset / resolution.y;


    //------------------------------------------------
    // Output
    //------------------------------------------------

    float alpha = 0.0;

    float4 color = float4(0.82,0.82,0.82,1);
    float4 icon_color = float4(RIcon,GIcon,BIcon,1);

    float4 shape;

    //------------------------------------------------
    // Data
    //------------------------------------------------

    int DotCount      = DrawData[0].x;
    int SelectedIndex = DrawData[0].y;
    int MinVal        = DrawData[0].z;


    //------------------------------------------------
    // Compute columns from width
    //------------------------------------------------

    int Columns = (int)floor(
        (MaxWidth + MinGap) /
        (IconSize + MinGap)
    );

    Columns = max(1,min(Columns,DotCount));


    //------------------------------------------------
    // Rows
    //------------------------------------------------

    int Rows =
        (DotCount + Columns - 1) / Columns;


    //------------------------------------------------
    // Horizontal spacing
    //------------------------------------------------

    float DotSpacingX = 0.0;

    if(Columns > 1)
    {
        DotSpacingX =
            (MaxWidth - IconSize) /
            (Columns - 1);
    }


    //------------------------------------------------
    // Grid bounds
    //------------------------------------------------

    float GridWidth =
        (Columns - 1) * DotSpacingX;

    float GridHeight =
        (Rows - 1) * MinGap;


    float GridLeft =
        -GridWidth * 0.5;

    float GridTop =
        -GridHeight * 0.5;


    //------------------------------------------------
    // Draw
    //------------------------------------------------

    [loop]
    for(int i = 0; i < DotCount; i++)
    {
        int row = i / Columns;

        int col = i % Columns;


        //--------------------------------------------
        // Position
        //--------------------------------------------

        float x =
            GridLeft +
            col * DotSpacingX;

        float y =
            GridTop +
            row * (MinGap + IconSize);


        float2 p =
            uv - float2(x,y);

        
        float d =
            CircleSDF(
                p,
            IconSize);

        float4 dot =
            DrawSDF(
                d,
                icon_color,
                float4(0,0,0,1),
                0.001);


        d =
            DiamondSDF(
                p,
                IconSize);
    
        float4 diamond =
            DrawSDF(
                d,
                icon_color,
                float4(0,0,0,1),
                0.05);


        //--------------------------------------------
        // Selected
        //--------------------------------------------

        bool selected =
            (i == (SelectedIndex - MinVal));


        //--------------------------------------------
        // Image mode
        //--------------------------------------------

        if(ImageMode)
        {
            float2 texUV =
                p / IconSize + 0.5;


            if(texUV.x < 0 || texUV.x > 1 ||
               texUV.y < 0 || texUV.y > 1)
            {
                continue;
            }


            float4 tex;


            if(selected)
            {
                tex =
                    DiamondTex.Sample(
                        LinearSampler,
                        texUV
                    );
            }
            else
            {
                tex =
                    DotTex.Sample(
                        LinearSampler,
                        texUV
                    );
            }


            if(tex.a > 0.01)
            {
                color = tex;

                alpha = tex.a;
            }
        }


        //--------------------------------------------
        // Shape mode
        //--------------------------------------------

        else
        {
            if(selected)
                shape = diamond;
            else
                shape = dot;

            if(shape.a > alpha)
            {
                alpha = shape.a;
                color = shape;
            }
        }
    }


    //------------------------------------------------
    // Discard
    //------------------------------------------------

    if(alpha < 0.01)
        discard;


    return color;
}

#endif