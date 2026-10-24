#define window_size   IniParams[1].xy

#define rotation  IniParams[2].x

#define OFFSET_Y  IniParams[7].x
#define OFFSET_X  IniParams[7].y
#define ZOOM  IniParams[7].z

Texture2D<float4> StereoParams : register(t125);
Texture1D<float4> IniParams : register(t120);

struct VSOutput {
    float4 pos : SV_Position;     // Clip space position
    float2 uv : TEXCOORD0;       // Texture coordinates
    float3 normal : TEXCOORD1;   // Normal vector
    float4 tangent : TEXCOORD2;  // Tangent vector
};

#ifdef VERTEX_SHADER

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

StructuredBuffer<TexBuf> vb0 : register(t0);

StructuredBuffer<PosBuf> Orig : register(t1);

float3 RotateVector(float3 v, float3 angles)
{
    float3x3 rotationMatrix = float3x3(
        cos(angles.y) * cos(angles.z), 
        sin(angles.x) * sin(angles.y) * cos(angles.z) - cos(angles.x) * sin(angles.z), 
        cos(angles.x) * sin(angles.y) * cos(angles.z) + sin(angles.x) * sin(angles.z),

        cos(angles.y) * sin(angles.z), 
        sin(angles.x) * sin(angles.y) * sin(angles.z) + cos(angles.x) * cos(angles.z), 
        cos(angles.x) * sin(angles.y) * sin(angles.z) - sin(angles.x) * cos(angles.z),

        -sin(angles.y), 
        sin(angles.x) * cos(angles.y), 
        cos(angles.x) * cos(angles.y)
    );
    
    return mul(v, rotationMatrix);
}

void main(out VSOutput output, uint vertex : SV_VertexID )
{   
	output.uv = vb0[vertex].texcoord;
	output.pos.xyz = Orig[vertex].pos.xzy;
	
	//if (active == 1) output.pos.xyz = Orig[vertex].xzy;
	
	float3 Rotate = float3(90, 0, rotation);
    float3 angles = float3(radians(Rotate.x), radians(Rotate.y), radians(Rotate.z));
    output.pos.xyz = RotateVector(output.pos.xyz, angles);

	output.pos.x += OFFSET_X;
	output.pos.y -= OFFSET_Y;
	
    output.pos.z = output.pos.z;
	output.pos.xy *= float2(window_size.y/window_size.x,1);
	output.normal = normalize(Orig[vertex].nor);   
    output.tangent = normalize(Orig[vertex].tan);
	output.pos.w = ZOOM;
}
#endif /* VERTEX_SHADER */

#ifdef PIXEL_SHADER

SamplerState s0_s : register(s0);

Texture2D<float4> t0 : register(t0);
RWTexture2D<float> Depth : register(u7);

//d[earlydepthstencil]
void main(VSOutput input, out float4 result : SV_Target0)
{
    //float currentDepth = Depth[input.pos.xy];
	
    //if (input.depth <= currentDepth) Depth[input.pos.xy] = input.depth;
    //else discard;
	
	result.w = 1;
	result.xyz = t0.Sample(s0_s, input.uv.xy).xyz;
	
	//oDepth = input.pos.z;
}
#endif /* PIXEL_SHADER */
