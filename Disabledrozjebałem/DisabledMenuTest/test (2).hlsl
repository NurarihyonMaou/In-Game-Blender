#define window_size   IniParams[1].xy

#define rotation  IniParams[2].x
#define active  IniParams[3].x

Texture2D<float4> StereoParams : register(t125);
Texture1D<float4> IniParams : register(t120);

struct vs2ps {
	float4 pos : SV_Position0;
	float2 texcoord : TEXCOORD0;
};

#ifdef VERTEX_SHADER
struct vb_struct {
    float3 POSITION; 	// Offset:    0
	uint NORMAL; 		// Offset:    12
	uint COLOR; 		// Offset:    16
	uint BLENDINDICES; 	// Offset:    20
	uint BLENDWEIGHT; 	// Offset:    24
	uint TEXCOORD0; 	// Offset:    28
	uint TEXCOORD1; 	// Offset:    32
	uint TEXCOORD2; 	// Offset:    36
	uint TEXCOORD3; 	// Offset:    40
	float2 TEXCOORD4; 	// Offset:    48
	uint TANGENT; 		// Offset:    52
};

StructuredBuffer<vb_struct> vb0 : register(t0);

Buffer<float3> Orig : register(t1);

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

float2 HalfToFloat2(in uint val)
{
	float2 result;
	result.x = f16tof32(val);
	result.y = f16tof32(val >> 16);

	return result;
}

void main(out vs2ps output, uint vertex : SV_VertexID )
{   
	output.texcoord = HalfToFloat2(vb0[vertex].TEXCOORD0);
	output.pos.xyz = vb0[vertex].POSITION.xzy;
	
	if (active == 1) output.pos.xyz = Orig[vertex].xzy;
	
	output.pos.xyz = output.pos.xyz / 120.0;
	
	float3 Rotate = float3(0,rotation-180,0);
    float3 angles = float3(radians(Rotate.x), radians(Rotate.y), radians(Rotate.z));
    output.pos.xyz = RotateVector(output.pos.xyz, angles);
	
	output.pos.x -= 1;
	output.pos.y -= 0.9;
	
    output.pos.z = output.pos.z +0.5;
	output.pos.xy *= float2(1440.0/2560.0,1);
	
	output.pos.w = 1;	
}
#endif /* VERTEX_SHADER */

#ifdef PIXEL_SHADER

SamplerState s0_s : register(s0);

Texture2D<float4> t0 : register(t0);
RWTexture2D<float> Depth : register(u7);

//d[earlydepthstencil]
void main(vs2ps input, out float4 result : SV_Target0, out float oDepth: SV_Depth)
{
    //float currentDepth = Depth[input.pos.xy];
	
	result.w = 1;
    //if (input.depth <= currentDepth) Depth[input.pos.xy] = input.depth;
    //else discard;
	
	result.w = 1;
	result.xyz = t0.Sample(s0_s, input.texcoord.xy).xyz;
	
	oDepth = input.pos.z;
}
#endif /* PIXEL_SHADER */
