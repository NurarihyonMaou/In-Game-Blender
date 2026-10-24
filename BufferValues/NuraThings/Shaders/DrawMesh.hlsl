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

    PosBuf vertexData = positionBuffer[input.vertexID];

    TexBuf texData = TexcoordBuffer[input.vertexID];
    output.uv = saturate(texData.texcoord); 

    vertexData.pos.y -= 1;

    float4x4 modelMatrix = float4x4(
        cos(ANGLE),  0.0, sin(ANGLE), 0.0,   // Rotation around Y-Axis (cos(θ), 0, sin(θ), 0)
        0.0,         1.0, 0.0,        0.0,   // No Scaling or Rotation on Y-Axis
        -sin(ANGLE), 0.0, cos(ANGLE), 0.0,  // Rotation around Y-Axis (-sin(θ), 0, cos(θ), 0)
        0,    -0.1, SIZE,        1.0    // Translation along Z-Axis
    );

    float4x4 viewMatrix = float4x4(
        1.0, 0.0, 0.0, 0.0,   // No Rotation along X-Axis
        0.0, 1.0, 0.0, 0.0,   // No Rotation along Y-Axis
        0.0, 0.0, 1.0, 0.0,   // No Rotation along Z-Axis
        0.0, 0.0, -0.5, 1.0   // Camera Positioned 0.5 Units back along Z-axis
    );

    float4x4 projectionMatrix = float4x4(
        1.3579952, 0.0,       0.0,      0.0,
        0.0,       1.7925903, 0.0,      0.0,
        0.0,       0.0,       1.001001, 1.0,
        0.0,       0.0,       -0.1001001, 0.0
    );
    
    // Apply Transformations
    float4 worldPos = mul(float4(vertexData.pos, 1.0), modelMatrix); // Model to world space
    float4 viewPos = mul(worldPos, viewMatrix); // Model to View Space
  
    output.pos = mul(viewPos, projectionMatrix);

    output.depth = output.pos.z-9999;

    output.normal = normalize(vertexData.nor);   
    output.tangent = normalize(vertexData.tan);
}

#endif

#ifdef PIXEL_SHADER

void main(VSOutput input, out float4 color : SV_Target) {
    

    float currentDepth = Depth[input.pos.xy];

    if (input.depth <= currentDepth && RUN == 0)
        Depth[input.pos.xy] = input.depth;
    else
        discard;

    color = myTexture.Sample(mySampler, input.uv);
    color.w = 1;
}

#endif
