// **** WEAPON SHAPE KEY SHADER ****
// Contributors: Cybertron, SinsOfSeven
// Helpers: DiXiao, Leo, Silent
struct VertexAttributes {
  uint2 position;//8
  uint normal;//12
  uint color;//16
  uint texcoord0;//20
  uint texcoord1;//24
  uint tangent;//28
};

RWStructuredBuffer<VertexAttributes> rw_buffer : register(u0);
StructuredBuffer<VertexAttributes> base : register(t0);
StructuredBuffer<VertexAttributes> shapekey : register(t1);

Texture1D<float4> IniParams : register(t120);
#define rotation IniParams[0]

float2 uintToHalf2ToFloat2(in uint a){
  return float2(f16tof32(a.x & 0xffff), f16tof32(a.x >> 0x10 & 0xffff));
}

uint float2ToHalf2ToUint(in float2 a){
  return uint(asuint(f32tof16(a.x)) | asuint(f32tof16(a.y)) << 0x10);
}

float3 RotateVector(float3 v, float3 angles)
{ //Thanky DiXiao and Silent
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

[numthreads(1, 1, 1)]
void main(uint3 threadID : SV_DispatchThreadID)
{
  float4 p,a,c = float4(0,0,0,1);
  uint i = threadID.x + rotation.w;
  p.xy = uintToHalf2ToFloat2(base[i].position.x);
  p.zw = uintToHalf2ToFloat2(base[i].position.y);
  a.xyz = float3(radians(rotation.x), radians(rotation.y), radians(rotation.z));
  c.xyz = RotateVector(p.xyz, a.xyz);

  // c += (a-b)*key;
  if(i>threadID.y){
    rw_buffer[i].position.x = float2ToHalf2ToUint(c.xy);
    rw_buffer[i].position.y = float2ToHalf2ToUint(c.zw);
  }
}

