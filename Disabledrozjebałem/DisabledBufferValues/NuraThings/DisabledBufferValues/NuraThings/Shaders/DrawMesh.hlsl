Texture1D<float4> IniParams : register(t120);

// Buffers
RWTexture2D<float> Depth: register(u3); // Depth texture
//SamplerState DepthSampler : register(s1);     // Sampler for the depth texture

Texture2D myTexture : register(t12);                    // Main texture
SamplerState mySampler : register(s0);                  // Sampler for the texture
RWBuffer<float4> DebugRW : register(u1);                // Debug buffer

#define ANGLE IniParams[79].y
//#define V_ANGLE IniParams[81].y

#define OFFSET_X IniParams[79].x
#define SIZE IniParams[79].z
#define RUN IniParams[79].w

// Define input and output structures
struct VSInput {
    uint vertexID : SV_VertexID; // Input vertex ID (from DrawIndexed call)
};

// Structure definition to hold position, normal, and tangent data
struct PosBuf {
    float3 pos;  // Position
    float3 nor;  // Normal
    float4 tan;  // Tangent vector (x, y, z, w where w is the bitangent direction)
};

// Structure for texture coordinates and colors
struct TexBuf {
    uint color;      // Color as a uint (could represent a packed RGB value)
    float2 texcoord; // Texture coordinates
};

StructuredBuffer<TexBuf> TexcoordBuffer : register(t1); // Buffer for texture coordinates and colors

// Position, normal, and tangent buffer structure
StructuredBuffer<PosBuf> positionBuffer : register(t0); // Position buffer

struct VSOutput {
    float4 pos : SV_Position;     // Clip space position
    float2 uv : TEXCOORD0;       // Texture coordinates
    float3 normal : TEXCOORD1;   // Normal vector
    float4 tangent : TEXCOORD2;  // Tangent vector
    float depth : TEXCOORD3; // Добавляем глубину
};

#ifdef VERTEX_SHADER

void main(VSInput input, out VSOutput output) {
    // Fetch the vertex data (position, normal, tangent) from the structured buffer
    PosBuf vertexData = positionBuffer[input.vertexID];

    // Fetch the texture data (color and texcoord) from the TexcoordBuffer
    TexBuf texData = TexcoordBuffer[input.vertexID]; // Assuming TexcoordBuffer is populated correctly
    output.uv = saturate(texData.texcoord);  // Use the texture coordinates from TexBuf

    vertexData.pos.y -= 0.8;
    //vertexData.pos.x += OFFSET_X;

    //float4x4 modelMatrix = mul(
    //    float4x4(
    //        1.0, 0.0,           0.0,          0.0,  // No rotation on X-axis (identity row)
    //        0.0, cos(V_ANGLE), -sin(V_ANGLE), 0.0,  // Rotation around X-axis
    //        0.0, sin(V_ANGLE),  cos(V_ANGLE),  0.0,  // Rotation around X-axis
    //        0.0, 0.0,           0.0,          1.0   // No translation or scaling on X-axis
    //    ),
    //    float4x4(
    //        cos(ANGLE),  0.0, sin(ANGLE), 0.0,      // Rotation around Y-axis
    //        0.0,         1.0, 0.0,        0.0,      // No scaling or rotation on Y-axis
    //        -sin(ANGLE), 0.0, cos(ANGLE), 0.0,      // Rotation around Y-axis
    //        OFFSET_X,    -0.1, SIZE,       1.0      // Translation
    //    )
    //);

    float4x4 modelMatrix = float4x4(
        cos(ANGLE),  0.0, sin(ANGLE), 0.0,   // Rotation around Y-axis (cos(θ), 0, sin(θ), 0)
        0.0,         1.0, 0.0,        0.0,   // No scaling or rotation on Y-axis
        -sin(ANGLE), 0.0, cos(ANGLE), 0.0,  // Rotation around Y-axis (-sin(θ), 0, cos(θ), 0)
        OFFSET_X,    -0.1, SIZE,        1.0    // Translation along Z-axis (move 2 units forward)
    );

    float4x4 viewMatrix = float4x4(
        1.0, 0.0, 0.0, 0.0,   // No rotation along X-axis
        0.0, 1.0, 0.0, 0.0,   // No rotation along Y-axis
        0.0, 0.0, 1.0, 0.0,   // No rotation along Z-axis
        0.0, 0.0, -0.5, 1.0   // Camera positioned 0.5 units back along Z-axis
    );

    float4x4 projectionMatrix = float4x4(
        1.3579952, 0.0,       0.0,      0.0,
        0.0,       1.7925903, 0.0,      0.0,
        0.0,       0.0,       1.001001, 1.0,
        0.0,       0.0,       -0.1001001, 0.0
    );
    
    // Apply transformations
    float4 worldPos = mul(float4(vertexData.pos, 1.0), modelMatrix); // Model to world space
    float4 viewPos = mul(worldPos, viewMatrix); // Model to view space
  
    output.pos = mul(viewPos, projectionMatrix);

    output.depth = output.pos.z-9999;

    output.normal = normalize(vertexData.nor);   
    output.tangent = normalize(vertexData.tan);
}

#endif

#ifdef PIXEL_SHADER

void main(VSOutput input, out float4 color : SV_Target) {
    
    // Sample the depth from the depth map
    //float storedDepth = DepthMap.Sample(DepthSampler, input.uv).r; // Sample depth texture
//
    //// Get the current fragment's depth
    //float currentDepth = input.depth;
//
    //// Compare depths
    //if (currentDepth > storedDepth) {
    //    discard; // Discard fragment if current depth is greater than stored depth
    //}

    float currentDepth = Depth[input.pos.xy];

    if (input.depth <= currentDepth) {
        //if (RUN <= 5){
        Depth[input.pos.xy] = input.depth;
        //}
    } 
    else
        discard;

    // Proceed to render the color if depths match
   // color = float4(input.uv.xy, 0.0f, 1.0f);

    color = myTexture.Sample(mySampler, input.uv);
    color.w = 1; // Black and white grid
    //color.xyzw = float4(1,1,0,1);
    //color.w = 1;
    //color = float4(input2.vertexID / 255.0, 0, 0, 1.0); // Red gradient based on vertexID
    //color = float4(smoothstep(0.0, 1.0, normalizedPos.x), smoothstep(0.0, 1.0, normalizedPos.y), 0.5, 1.0);
    // Optionally, output normal as color for debugging
    // color = float4((input.normal * 0.5) + 0.5, 1.0);  // Uncomment for normal visualization

    //color = float4((input.normal * 0.5) + 0.5, 1.0);  // Output normals as colors
    // Output the final color
    //color = float4(sampledColor.rgb, 1.0);  // Set alpha to 1.0 (fully opaque)
}

#endif

#ifdef COMPUTE_SHADER

[numthreads(1,1,1)]
void main(uint3 ThreadId : SV_DispatchThreadID) {
    for (uint i = 0; i < 128; i++) {
        // Fetch the corresponding vertex position, normal, and tangent from the buffer
        PosBuf vertexData = positionBuffer[i];
        float4x4 modelMatrix = float4x4(
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        );

        float4x4 viewMatrix = float4x4(
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        );

        float4x4 projectionMatrix = float4x4(
            1.3579952, 0.0,       0.0,      0.0,
            0.0,       1.7925903, 0.0,      0.0,
            0.0,       0.0,       1.001001, 1.0,
            0.0,       0.0,       -0.1001001, 0.0
        );
        
        float4 worldPos = mul(float4(vertexData.pos, 1.0), modelMatrix); // Model to world space
        float4 viewPos = mul(worldPos, viewMatrix);   // World to view space

        //DepthMap[ThreadId.xy] = viewPos.z;

        DebugRW[i] = Depth[float2(2,3)]; // Store debug info
    }
}

#endif
