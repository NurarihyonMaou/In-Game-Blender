// ---- Created with 3Dmigoto v1.3.16 on Thu Jul 18 09:43:51 2024
Texture2D<float4> t4 : register(t4);

Texture2D<float4> t3 : register(t3);

Texture2D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s4_s : register(s4);

SamplerState s3_s : register(s3);

SamplerState s2_s : register(s2);

SamplerState s1_s : register(s1);

SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[17];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[102];
}




// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> StereoParams : register(t125);
Texture2D<float4> tex17 : register(t17);


void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD2,
  float4 v5 : TEXCOORD3,
  float2 v6 : TEXCOORD4,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1,
  out float4 o2 : SV_Target2,
  out float o3 : SV_Target3,
  out float o4 : SV_Target4,
  out float o5 : SV_Target5)
{
  const float4 icb[] = { { 1.000000, 0, 0, 0},
                              { 0, 1.000000, 0, 0},
                              { 0, 0, 1.000000, 0},
                              { 0, 0, 0, 1.000000} };
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xy = cmp(float2(0,0) != cb0[76].wx);
  r0.z = -0.00999999978 + v1.w;
  r0.z = cmp(r0.z < 0);
  r0.x = r0.x ? r0.z : 0;
  if (r0.x != 0) discard;
  if (r0.y != 0) {
    r0.x = cmp(cb0[76].y < 0.949999988);
    if (r0.x != 0) {
      r0.xy = v4.yx / v4.ww;
      r0.xy = cb1[7].yx * r0.xy;
      r0.xy = float2(0.25,0.25) * r0.xy;
      r0.zw = cmp(r0.xy >= -r0.xy);
      r0.xy = frac(abs(r0.xy));
      r0.xy = r0.zw ? r0.xy : -r0.xy;
      r0.xy = float2(4,4) * r0.xy;
      r0.xy = (uint2)r0.xy;
      r1.x = dot(cb0[8].xyzw, icb[r0.y+0].xyzw);
      r1.y = dot(cb0[9].xyzw, icb[r0.y+0].xyzw);
      r1.z = dot(cb0[10].xyzw, icb[r0.y+0].xyzw);
      r1.w = dot(cb0[11].xyzw, icb[r0.y+0].xyzw);
      r0.x = dot(r1.xyzw, icb[r0.x+0].xyzw);
      r0.x = cb0[76].y * 17 + -r0.x;
      r0.x = -0.00999999978 + r0.x;
      r0.x = cmp(r0.x < 0);
      if (r0.x != 0) discard;
    }
  }
  r0.x = dot(v5.xyz, v5.xyz);
  r0.x = rsqrt(r0.x);
  r0.yzw = v5.xyz * r0.xxx;
  r1.xy = cmp(float2(0,0.5) < cb0[95].ww);
  r1.z = cmp(0 != v6.y);
  r2.xyz = r1.zzz ? cb0[96].xyz : cb0[95].xyz;
  r1.xzw = r1.xxx ? r2.xyz : cb0[91].xyz;
  r1.xzw = v5.xyz * r0.xxx + r1.xzw;
  r0.x = dot(r1.xzw, r1.xzw);
  r0.x = rsqrt(r0.x);
  r1.xzw = r1.xzw * r0.xxx;
  r0.x = -1 + cb0[76].z;
  r2.xyzw = t0.SampleBias(s0_s, v2.xy, r0.x).xyzw;
  r3.xyz = cmp(cb0[28].xxx == float3(3,1,2));
  r3.w = cb0[41].w * r2.w;
  r4.xyz = cb0[42].xyz + -r2.xyz;
  r4.xyz = r3.www * r4.xyz + r2.xyz;
  r2.xyz = r3.xxx ? r4.xyz : r2.xyz;
  r3.x = -cb0[28].y + r2.w;
  r3.x = cmp(r3.x < 0);
  r3.x = r3.y ? r3.x : 0;
  if (r3.x != 0) discard;
  r4.xyzw = t1.SampleBias(s1_s, v2.xy, r0.x).xyzw;
  r3.xy = cmp(float2(0,0) != cb0[35].xy);
  r0.x = cmp(0 != cb0[52].x);
  r5.xyzw = cmp(r4.wwww >= float4(0.800000012,0.400000006,0.200000003,0.600000024));
  r0.x = r0.x ? r5.x : 0;
  r0.x = r0.x ? 2 : 1;
  r3.w = cmp(0 != cb0[57].w);
  r3.w = r5.y ? r3.w : 0;
  r6.xyz = cmp(r4.www < float3(0.600000024,0.400000006,0.800000012));
  r3.w = r3.w ? r6.x : 0;
  r0.x = r3.w ? 3 : r0.x;
  r3.w = cmp(0 != cb0[63].w);
  r3.w = r5.z ? r3.w : 0;
  r3.w = r6.y ? r3.w : 0;
  r0.x = r3.w ? 4 : r0.x;
  r3.w = cmp(0 != cb0[69].w);
  r3.w = r5.w ? r3.w : 0;
  r3.w = r6.z ? r3.w : 0;
  r0.x = r3.w ? 5 : r0.x;
  r5.xyzw = cmp(r0.xxxx == float4(2,3,4,5));
  r6.xyz = r5.xxx ? cb0[52].yzw : cb0[25].xyz;
  r6.xyz = r5.yyy ? cb0[58].xyz : r6.xyz;
  r6.xyz = r5.zzz ? cb0[64].xyz : r6.xyz;
  r6.xyz = r5.www ? cb0[70].xyz : r6.xyz;
  r2.xyz = r6.xyz * r2.xyz;
  r3.w = cmp(0.00999999978 < r2.w);
  r3.z = r3.w ? r3.z : 0;
  r2.w = r3.z ? r2.w : 0;
  r3.w = -0.5 + r4.y;
  r3.x = r3.x ? r3.w : 0;
  r3.x = dot(r3.xx, abs(r3.xx));
  r3.x = 0.5 + r3.x;
  r3.w = v1.x * r3.x;
  r3.x = r3.y ? r3.w : r3.x;
  r3.y = cmp(r3.x < 0.0500000007);
  r3.w = cmp(0.949999988 < r3.x);
  r3.x = v3.w + r3.x;
  r3.x = 0.5 * r3.x;
  r3.x = r3.w ? 1 : r3.x;
  r3.x = r3.y ? 0 : r3.x;
  r3.y = cmp(r3.x < cb0[35].z);
  r3.x = cb0[35].z + -r3.x;
  r6.y = r3.x / cb0[35].z;
  r3.x = cmp(0 != cb0[38].y);
  r3.w = v1.y + v1.y;
  r3.w = max(0.00999999978, r3.w);
  r3.w = cb0[38].x * r3.w;
  r3.x = r3.x ? r3.w : cb0[38].x;
  r3.x = r6.y / r3.x;
  r3.x = min(1, r3.x);
  r6.z = 1 + -r3.x;
  r6.yz = r3.yy ? r6.yz : float2(0,1);
  r6.x = r3.y ? 1.000000 : 0;
  r3.x = cmp(9.99999975e-06 < v6.x);
  r7.xy = r3.xx ? float2(1,0) : r6.xz;
  r3.x = cmp(0.5 < cb0[91].w);
  r3.y = cb0[90].w + cb0[90].w;
  r3.y = min(1, r3.y);
  r3.x = r3.x ? r3.y : 1;
  r3.y = cmp(0.899999976 < r4.x);
  if (r3.y != 0) {
    r3.yw = cb2[15].xy * v3.yy;
    r3.yw = cb2[14].xy * v3.xx + r3.yw;
    r8.yz = cb2[16].xy * v3.zz + r3.yw;
    r8.x = cb0[79].z * r8.y;
    r3.yw = r8.xz * float2(0.5,0.5) + float2(0.5,0.5);
    r3.y = t2.Sample(s3_s, r3.yw).x;
    r3.y = saturate(cb0[79].y * r3.y);
    r6.xzw = -cb0[81].xyz + cb0[80].xyz;
    r6.xzw = r3.yyy * r6.xzw + cb0[81].xyz;
    r6.xzw = r6.xzw * r2.xyz;
    r3.y = dot(v3.xyz, r1.xzw);
    r3.y = max(0.00100000005, r3.y);
    r3.y = log2(r3.y);
    r3.y = cb0[82].w * r3.y;
    r3.y = exp2(r3.y);
    r8.x = saturate(cb0[83].w * r3.y);
    r3.y = cmp(cb0[84].z < r8.x);
    if (r3.y != 0) {
      r9.xyz = cb0[85].xyz;
    } else {
      r3.y = cmp(0 != cb0[84].y);
      if (r3.y != 0) {
        r8.y = 0.5;
        r8.yzw = t3.Sample(s4_s, r8.xy).xyz;
        r9.xyz = r8.yzw * r4.zzz;
      } else {
        r8.xyz = cb0[83].xyz * r8.xxx;
        r9.xyz = r8.xyz * r4.zzz;
      }
    }
    r3.y = cmp(0 != v6.x);
    r8.xyz = cb0[84].xxx * r9.xyz;
    r8.xyz = r3.yyy ? r8.xyz : r9.xyz;
    r3.y = cmp(0 != cb0[38].z);
    r9.xyz = float3(-1,-1,-1) + cb0[82].xyz;
    r9.xyz = r6.yyy * r9.xyz + float3(1,1,1);
    r9.xyz = r3.yyy ? r9.xyz : cb0[82].xyz;
    r10.xyz = r9.xyz * r6.xzw;
    r3.y = cmp(0 != r7.x);
    r11.xyz = cb0[87].xxx * r6.xzw;
    r11.xyz = r3.yyy ? r10.xyz : r11.xyz;
    r3.y = cmp(r3.x < 1);
    r6.xyz = -r6.xzw * r9.xyz + r11.xyz;
    r6.xyz = r3.xxx * r6.xyz + r10.xyz;
    r6.xyz = r3.yyy ? r6.xyz : r11.xyz;
    r8.xyz = cb0[87].xxx * r8.xyz;
  } else {
    r3.y = -1 + r0.x;
    r3.w = r3.y * 0.100000001 + 0.0500000007;
    r4.y = cmp(0 != cb0[36].w);
    if (r4.y != 0) {
      r4.w = r3.y * 0.100000001 + 0.550000012;
      r7.z = 1 + -r3.w;
      r7.w = 1 + -r4.w;
      r9.xyz = t4.Sample(s2_s, r7.yz).xyz;
      r11.xyz = t4.Sample(s2_s, r7.yw).xyz;
      r9.xyz = -r11.xyz + r9.xyz;
      r9.xyz = cb0[88].zzz * r9.xyz + r11.xyz;
      r11.xz = float2(0,0);
      r11.yw = r7.zw;
      r12.xyz = t4.Sample(s2_s, r11.xy).xyz;
      r11.xyz = t4.Sample(s2_s, r11.zw).xyz;
      r12.xyz = r12.xyz + -r11.xyz;
      r11.xyz = cb0[88].zzz * r12.xyz + r11.xyz;
    } else {
      r12.x = 1 + -r3.w;
      r12.y = r7.y;
      r9.xyz = t4.Sample(s2_s, r12.yx).xyz;
      r12.z = 0;
      r11.xyz = t4.Sample(s2_s, r12.zx).xyz;
    }
    r4.w = cmp(r3.x < 1);
    if (r4.w != 0) {
      if (r4.y != 0) {
        r3.y = r3.y * 0.100000001 + 0.550000012;
        r12.yw = float2(1,1) + -r3.wy;
        r12.xz = float2(0,0);
        r7.yzw = t4.Sample(s2_s, r12.xy).xyz;
        r12.xyz = t4.Sample(s2_s, r12.zw).xyz;
        r7.yzw = -r12.xyz + r7.yzw;
        r7.yzw = cb0[88].zzz * r7.yzw + r12.xyz;
      } else {
        r12.y = 1 + -r3.w;
        r12.x = 0;
        r7.yzw = t4.Sample(s2_s, r12.xy).xyz;
      }
    } else {
      r7.yzw = float3(0,0,0);
    }
    r10.xyz = r11.xyz * r2.xyz;
    r3.y = cmp(0 != r7.x);
    r9.xyz = r9.xyz * r2.xyz;
    r11.xyz = cb0[87].xxx * r2.xyz;
    r9.xyz = r3.yyy ? r9.xyz : r11.xyz;
    r11.xyz = r7.yzw * r2.xyz;
    r7.xyz = -r2.xyz * r7.yzw + r9.xyz;
    r7.xyz = r3.xxx * r7.xyz + r11.xyz;
    r6.xyz = r4.www ? r7.xyz : r9.xyz;
    r3.y = cmp(r0.x == 1.000000);
    r3.w = r5.z ? cb0[67].w : cb0[73].w;
    r4.y = r5.z ? cb0[68].x : cb0[74].x;
    r3.w = r5.y ? cb0[61].w : r3.w;
    r4.y = r5.y ? cb0[62].x : r4.y;
    r7.x = r5.x ? cb0[55].w : r3.w;
    r7.y = r5.x ? cb0[56].x : r4.y;
    r3.yw = r3.yy ? cb0[41].xy : r7.xy;
    r1.x = dot(v3.xyz, r1.xzw);
    r1.x = max(0.00100000005, r1.x);
    r1.x = log2(r1.x);
    r1.x = r3.y * r1.x;
    r1.x = exp2(r1.x);
    r1.z = 1 + -r4.z;
    r1.x = cmp(r1.z < r1.x);
    r4.yzw = cb0[39].yzw * r3.www;
    r4.xyz = r4.yzw * r4.xxx;
    r4.xyz = r1.xxx ? r4.xyz : 0;
    r4.xyz = cb0[87].xxx * r4.xyz;
    r8.xyz = r1.xxx ? r4.xyz : 0;
  }
  r1.xzw = cb0[46].xyz * r2.xyz;
  r1.xzw = cb0[45].zzz * r1.xzw;
  r0.x = cmp(r0.x == 1.000000);
  r2.xyz = cb0[45].www * r1.xzw;
  r4.xyz = cb0[53].xxx * r1.xzw;
  r7.xyz = cb0[58].www * r1.xzw;
  r9.xyz = cb0[64].www * r1.xzw;
  r11.xyz = cb0[70].www * r1.xzw;
  r1.xzw = r5.www ? r11.xyz : r1.xzw;
  r1.xzw = r5.zzz ? r9.xyz : r1.xzw;
  r1.xzw = r5.yyy ? r7.xyz : r1.xzw;
  r1.xzw = r5.xxx ? r4.xyz : r1.xzw;
  r1.xzw = r0.xxx ? r2.xyz : r1.xzw;
  r0.x = cmp(r3.x < 1);
  r2.xyz = r8.xyz * r3.xxx;
  r2.xyz = r0.xxx ? r2.xyz : r8.xyz;
  r2.xyz = r6.xyz + r2.xyz;
  r1.xzw = -r2.xyz + r1.xzw;
  r1.xzw = r2.www * r1.xzw + r2.xyz;
  r1.xzw = r3.zzz ? r1.xzw : r2.xyz;
  r0.x = dot(v3.xyz, v3.xyz);
  r0.x = rsqrt(r0.x);
  r2.xyz = v3.xyz * r0.xxx;
  r0.x = saturate(dot(r0.yzw, r2.xyz));
  r0.x = 1 + -r0.x;
  r0.x = max(9.99999975e-05, r0.x);
  r0.x = log2(r0.x);
  r0.x = cb0[101].x * r0.x;
  r0.x = exp2(r0.x);
  r0.yzw = max(cb0[100].xyz, cb0[99].xyz);
  r0.xyz = r0.yzw * r0.xxx;
  r3.xyz = r0.xyz * cb0[101].yyy + r1.xzw;
  r0.w = 1 + -r2.w;
  r0.w = cb0[101].z * r0.w + r2.w;
  r0.xyz = r0.xyz * cb0[101].yyy + r10.xyz;
  r1.x = max(r3.y, r3.z);
  r2.w = max(r3.x, r1.x);
  r1.x = cmp(1 < r2.w);
  r2.xyz = r3.xyz / r2.www;
  r3.w = 1;
  r2.xyzw = r1.xxxx ? r2.xyzw : r3.xyzw;
  r1.xzw = -r2.xyz + r0.xyz;
  r1.xzw = cb0[97].xxx * r1.xzw + r2.xyz;
  r0.xyz = r1.yyy ? r1.xzw : r0.xyz;
  r1.x = saturate(0.0500000007 * r2.w);
    //Sample mask
    r11 = tex17.Sample(s2_s, v2.xy);
    //
    //o1.w = sqrt(r1.x);
    o1.w = r11.y ? max(r11.y * IniParams[18].y, sqrt(r1.x)) : sqrt(r1.x);
    //
  r1.x = (uint)cb0[79].x;
  o0.xyz = v3.xyz * float3(0.5,0.5,0.5) + float3(0.5,0.5,0.5);
  r1.x = (uint)r1.x;
  o5.x = 0.00392156886 * r1.x;
  r1.x = cmp(0 != cb0[24].x);
  r1.y = 0.00392156886 * cb0[24].y;
    //o2.z = r1.x ? r1.y : r0.z;
    r1.x = r1.x ? r1.y : r0.z;
    o2.z = r11.z ? lerp(r1.x, IniParams[17].z, min(IniParams[17].w, 0.75)) : r1.x;
    //
  o0.w = r5.x ? 0.333000 : 0;
    //o1.xyz = r2.xyz;
    o1.xyz = r11.z ? lerp(r2.xyz, IniParams[17].xyz, min(IniParams[17].w, 0.75)) : r2.xyz;
    //
    //o2.xyw = r0.xyw;
    o2.xy = r11.z ? lerp(r0.xy, IniParams[17].xy, min(IniParams[17].w, 0.75)) : r0.xy;
    o2.w = r11.y ? max(r11.y * IniParams[18].y, r0.w) : r0.w;
    //
  o3.x = 0.0156862754;
    //o4.x = r0.w;
    o4.x = r11.z ? max(r11.z * IniParams[18].z, r0.w) : r0.w;
    //
  return;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// Generated by Microsoft (R) D3D Shader Disassembler
//
//   using 3Dmigoto v1.3.16 on Thu Jul 18 09:43:51 2024
//
//
// Input signature:
//
// Name                 Index   Mask Register SysValue  Format   Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_POSITION              0   xyzw        0      POS   float
// COLOR                    0   xyzw        1     NONE   float   xy w
// TEXCOORD                 0   xyzw        2     NONE   float   xyzw
// TEXCOORD                 1   xyzw        3     NONE   float   xyzw
// TEXCOORD                 2   xyzw        4     NONE   float   xy w
// TEXCOORD                 3   xyz         5     NONE   float   xyz
// TEXCOORD                 4   xy          6     NONE   float   xy
// SV_IsFrontFace           0   x           7    FFACE    uint   x
//
//
// Output signature:
//
// Name                 Index   Mask Register SysValue  Format   Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_Target                0   xyzw        0   TARGET   float   xyzw
// SV_Target                1   xyzw        1   TARGET   float   xyzw
// SV_Target                2   xyzw        2   TARGET   float   xyzw
// SV_Target                3   x           3   TARGET   float   x
// SV_Target                4   x           4   TARGET   float   x
// SV_Target                5   x           5   TARGET   float   x
//
ps_5_0
dcl_globalFlags refactoringAllowed
dcl_immediateConstantBuffer { { 1.000000, 0, 0, 0},
                              { 0, 1.000000, 0, 0},
                              { 0, 0, 1.000000, 0},
                              { 0, 0, 0, 1.000000} }
dcl_constantbuffer CB0[102], immediateIndexed
dcl_constantbuffer CB1[8], immediateIndexed
dcl_constantbuffer CB2[17], immediateIndexed
dcl_sampler s0, mode_default
dcl_sampler s1, mode_default
dcl_sampler s2, mode_default
dcl_sampler s3, mode_default
dcl_sampler s4, mode_default
dcl_resource_texture2d (float,float,float,float) t0
dcl_resource_texture2d (float,float,float,float) t1
dcl_resource_texture2d (float,float,float,float) t2
dcl_resource_texture2d (float,float,float,float) t3
dcl_resource_texture2d (float,float,float,float) t4
dcl_input_ps linear v1.xyw
dcl_input_ps linear v2.xyzw
dcl_input_ps linear v3.xyzw
dcl_input_ps linear v4.xyw
dcl_input_ps linear v5.xyz
dcl_input_ps linear v6.xy
dcl_input_ps_sgv constant v7.x, is_front_face
dcl_output o0.xyzw
dcl_output o1.xyzw
dcl_output o2.xyzw
dcl_output o3.x
dcl_output o4.x
dcl_output o5.x
dcl_temps 14
ne r0.xy, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[76].wxww
add r0.z, v1.w, l(-0.010000)
lt r0.z, r0.z, l(0.000000)
and r0.x, r0.x, r0.z
discard_nz r0.x
if_nz r0.y
  lt r0.x, cb0[76].y, l(0.950000)
  if_nz r0.x
    div r0.xy, v4.yxyy, v4.wwww
    mul r0.xy, r0.xyxx, cb1[7].yxyy
    mul r0.xy, r0.xyxx, l(0.250000, 0.250000, 0.000000, 0.000000)
    ge r0.zw, r0.xxxy, -r0.xxxy
    frc r0.xy, |r0.xyxx|
    movc r0.xy, r0.zwzz, r0.xyxx, -r0.xyxx
    mul r0.xy, r0.xyxx, l(4.000000, 4.000000, 0.000000, 0.000000)
    ftou r0.xy, r0.xyxx
    dp4 r1.x, cb0[8].xyzw, icb[r0.y + 0].xyzw
    dp4 r1.y, cb0[9].xyzw, icb[r0.y + 0].xyzw
    dp4 r1.z, cb0[10].xyzw, icb[r0.y + 0].xyzw
    dp4 r1.w, cb0[11].xyzw, icb[r0.y + 0].xyzw
    dp4 r0.x, r1.xyzw, icb[r0.x + 0].xyzw
    mad r0.x, cb0[76].y, l(17.000000), -r0.x
    add r0.x, r0.x, l(-0.010000)
    lt r0.x, r0.x, l(0.000000)
    discard_nz r0.x
  endif
endif
ieq r0.x, v7.x, l(0)
ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[75].w
and r0.y, r0.y, r0.x
movc r0.yz, r0.yyyy, v2.zzwz, v2.xxyx
movc r1.xyz, v7.xxxx, v3.xyzx, -v3.xyzx
dp3 r0.w, v5.xyzx, v5.xyzx
rsq r0.w, r0.w
mul r2.xyz, r0.wwww, v5.xyzx
lt r3.xy, l(0.000000, 0.500000, 0.000000, 0.000000), cb0[95].wwww
ne r1.w, l(0.000000, 0.000000, 0.000000, 0.000000), v6.y
movc r4.xyz, r1.wwww, cb0[96].xyzx, cb0[95].xyzx
movc r3.xzw, r3.xxxx, r4.xxyz, cb0[91].xxyz
mad r3.xzw, v5.xxyz, r0.wwww, r3.xxzw
dp3 r0.w, r3.xzwx, r3.xzwx
rsq r0.w, r0.w
mul r3.xzw, r0.wwww, r3.xxzw
add r0.w, cb0[76].z, l(-1.000000)
sample_b_indexable(texture2d)(float,float,float,float) r4.xyzw, r0.yzyy, t0.xyzw, s0, r0.w
eq r5.xyz, cb0[28].xxxx, l(3.000000, 1.000000, 2.000000, 0.000000)
mul r1.w, r4.w, cb0[41].w
add r6.xyz, -r4.xyzx, cb0[42].xyzx
mad r6.xyz, r1.wwww, r6.xyzx, r4.xyzx
movc r4.xyz, r5.xxxx, r6.xyzx, r4.xyzx
add r1.w, r4.w, -cb0[28].y
lt r1.w, r1.w, l(0.000000)
and r1.w, r5.y, r1.w
discard_nz r1.w
sample_b_indexable(texture2d)(float,float,float,float) r6.xyzw, r0.yzyy, t1.xyzw, s1, r0.w
ne r0.yz, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[35].xxyx
ne r0.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[52].x
ge r7.xyzw, r6.wwww, l(0.800000, 0.400000, 0.200000, 0.600000)
and r0.w, r0.w, r7.x
movc r0.w, r0.w, l(2.000000), l(1.000000)
ne r1.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[57].w
and r1.w, r7.y, r1.w
lt r5.xyw, r6.wwww, l(0.600000, 0.400000, 0.000000, 0.800000)
and r1.w, r1.w, r5.x
movc r0.w, r1.w, l(3.000000), r0.w
ne r1.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[63].w
and r1.w, r7.z, r1.w
and r1.w, r5.y, r1.w
movc r0.w, r1.w, l(4.000000), r0.w
ne r1.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[69].w
and r1.w, r7.w, r1.w
and r1.w, r5.w, r1.w
movc r0.w, r1.w, l(5.000000), r0.w
eq r7.xyzw, r0.wwww, l(2.000000, 3.000000, 4.000000, 5.000000)
movc r5.xyw, r7.xxxx, cb0[52].yzyw, cb0[25].xyxz
movc r5.xyw, r7.yyyy, cb0[58].xyxz, r5.xyxw
movc r5.xyw, r7.zzzz, cb0[64].xyxz, r5.xyxw
movc r5.xyw, r7.wwww, cb0[70].xyxz, r5.xyxw
mul r4.xyz, r4.xyzx, r5.xywx
lt r1.w, l(0.010000), r4.w
and r1.w, r1.w, r5.z
and r2.w, r4.w, r1.w
add r4.w, r6.y, l(-0.500000)
and r0.y, r0.y, r4.w
dp2 r0.y, r0.yyyy, |r0.yyyy|
add r0.y, r0.y, l(0.500000)
mul r4.w, r0.y, v1.x
movc r0.y, r0.z, r4.w, r0.y
lt r0.z, r0.y, l(0.050000)
lt r4.w, l(0.950000), r0.y
add r0.y, r0.y, v3.w
mul r0.y, r0.y, l(0.500000)
movc r0.y, r4.w, l(1.000000), r0.y
movc r0.y, r0.z, l(0), r0.y
lt r0.z, r0.y, cb0[35].z
add r0.y, -r0.y, cb0[35].z
div r5.y, r0.y, cb0[35].z
ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[38].y
add r4.w, v1.y, v1.y
max r4.w, r4.w, l(0.010000)
mul r4.w, r4.w, cb0[38].x
movc r0.y, r0.y, r4.w, cb0[38].x
div r0.y, r5.y, r0.y
min r0.y, r0.y, l(1.000000)
add r5.z, -r0.y, l(1.000000)
movc r5.yz, r0.zzzz, r5.yyzy, l(0,0,1.000000,0)
and r5.x, r0.z, l(0x3f800000)
lt r0.y, l(0.000010), v6.x
or r0.x, r0.x, r0.y
movc r8.xy, r0.xxxx, l(1.000000,0,0,0), r5.xzxx
lt r0.x, l(0.500000), cb0[91].w
add r0.y, cb0[90].w, cb0[90].w
min r0.y, r0.y, l(1.000000)
movc r0.x, r0.x, r0.y, l(1.000000)
lt r0.y, l(0.900000), r6.x
if_nz r0.y
  mul r0.yz, r1.yyyy, cb2[15].xxyx
  mad r0.yz, cb2[14].xxyx, r1.xxxx, r0.yyzy
  mad r9.yz, cb2[16].xxyx, r1.zzzz, r0.yyzy
  mul r9.x, r9.y, cb0[79].z
  mad r0.yz, r9.xxzx, l(0.000000, 0.500000, 0.500000, 0.000000), l(0.000000, 0.500000, 0.500000, 0.000000)
  sample_indexable(texture2d)(float,float,float,float) r0.y, r0.yzyy, t2.yxzw, s3
  mul_sat r0.y, r0.y, cb0[79].y
  add r5.xzw, cb0[80].xxyz, -cb0[81].xxyz
  mad r5.xzw, r0.yyyy, r5.xxzw, cb0[81].xxyz
  mul r5.xzw, r4.xxyz, r5.xxzw
  dp3 r0.y, r1.xyzx, r3.xzwx
  max r0.y, r0.y, l(0.001000)
  log r0.y, r0.y
  mul r0.y, r0.y, cb0[82].w
  exp r0.y, r0.y
  mul_sat r9.x, r0.y, cb0[83].w
  lt r0.y, cb0[84].z, r9.x
  if_nz r0.y
    mov r10.xyz, cb0[85].xyzx
  else
    ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[84].y
    if_nz r0.y
      mov r9.y, l(0.500000)
      sample_indexable(texture2d)(float,float,float,float) r9.yzw, r9.xyxx, t3.wxyz, s4
      mul r10.xyz, r6.zzzz, r9.yzwy
    else
      mul r9.xyz, r9.xxxx, cb0[83].xyzx
      mul r10.xyz, r6.zzzz, r9.xyzx
    endif
  endif
  ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), v6.x
  mul r9.xyz, r10.xyzx, cb0[84].xxxx
  movc r9.xyz, r0.yyyy, r9.xyzx, r10.xyzx
  ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[38].z
  add r10.xyz, cb0[82].xyzx, l(-1.000000, -1.000000, -1.000000, 0.000000)
  mad r10.xyz, r5.yyyy, r10.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
  movc r10.xyz, r0.yyyy, r10.xyzx, cb0[82].xyzx
  mul r11.xyz, r5.xzwx, r10.xyzx
  ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), r8.x
  mul r12.xyz, r5.xzwx, cb0[87].xxxx
  movc r12.xyz, r0.yyyy, r11.xyzx, r12.xyzx
  lt r0.y, r0.x, l(1.000000)
  mad r5.xyz, -r5.xzwx, r10.xyzx, r12.xyzx
  mad r5.xyz, r0.xxxx, r5.xyzx, r11.xyzx
  movc r5.xyz, r0.yyyy, r5.xyzx, r12.xyzx
  mul r9.xyz, r9.xyzx, cb0[87].xxxx
else
  add r0.y, r0.w, l(-1.000000)
  mad r0.z, r0.y, l(0.100000), l(0.050000)
  ne r4.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[36].w
  if_nz r4.w
    mad r5.w, r0.y, l(0.100000), l(0.550000)
    add r8.z, -r0.z, l(1.000000)
    add r8.w, -r5.w, l(1.000000)
    sample_indexable(texture2d)(float,float,float,float) r10.xyz, r8.yzyy, t4.xyzw, s2
    sample_indexable(texture2d)(float,float,float,float) r12.xyz, r8.ywyy, t4.xyzw, s2
    add r10.xyz, r10.xyzx, -r12.xyzx
    mad r10.xyz, cb0[88].zzzz, r10.xyzx, r12.xyzx
    mov r12.xz, l(0,0,0,0)
    mov r12.yw, r8.zzzw
    sample_indexable(texture2d)(float,float,float,float) r13.xyz, r12.xyxx, t4.xyzw, s2
    sample_indexable(texture2d)(float,float,float,float) r12.xyz, r12.zwzz, t4.xyzw, s2
    add r13.xyz, -r12.xyzx, r13.xyzx
    mad r12.xyz, cb0[88].zzzz, r13.xyzx, r12.xyzx
  else
    add r13.x, -r0.z, l(1.000000)
    mov r13.y, r8.y
    sample_indexable(texture2d)(float,float,float,float) r10.xyz, r13.yxyy, t4.xyzw, s2
    mov r13.z, l(0)
    sample_indexable(texture2d)(float,float,float,float) r12.xyz, r13.zxzz, t4.xyzw, s2
  endif
  lt r5.w, r0.x, l(1.000000)
  if_nz r5.w
    if_nz r4.w
      mad r0.y, r0.y, l(0.100000), l(0.550000)
      add r13.yw, -r0.zzzy, l(0.000000, 1.000000, 0.000000, 1.000000)
      mov r13.xz, l(0,0,0,0)
      sample_indexable(texture2d)(float,float,float,float) r8.yzw, r13.xyxx, t4.wxyz, s2
      sample_indexable(texture2d)(float,float,float,float) r13.xyz, r13.zwzz, t4.xyzw, s2
      add r8.yzw, r8.yyzw, -r13.xxyz
      mad r8.yzw, cb0[88].zzzz, r8.yyzw, r13.xxyz
    else
      add r13.y, -r0.z, l(1.000000)
      mov r13.x, l(0)
      sample_indexable(texture2d)(float,float,float,float) r8.yzw, r13.xyxx, t4.wxyz, s2
    endif
  else
    mov r8.yzw, l(0,0,0,0)
  endif
  mul r11.xyz, r4.xyzx, r12.xyzx
  ne r0.y, l(0.000000, 0.000000, 0.000000, 0.000000), r8.x
  mul r10.xyz, r4.xyzx, r10.xyzx
  mul r12.xyz, r4.xyzx, cb0[87].xxxx
  movc r10.xyz, r0.yyyy, r10.xyzx, r12.xyzx
  mul r12.xyz, r4.xyzx, r8.yzwy
  mad r8.xyz, -r4.xyzx, r8.yzwy, r10.xyzx
  mad r8.xyz, r0.xxxx, r8.xyzx, r12.xyzx
  movc r5.xyz, r5.wwww, r8.xyzx, r10.xyzx
  eq r0.y, r0.w, l(1.000000)
  movc r0.z, r7.z, cb0[67].w, cb0[73].w
  movc r4.w, r7.z, cb0[68].x, cb0[74].x
  movc r0.z, r7.y, cb0[61].w, r0.z
  movc r4.w, r7.y, cb0[62].x, r4.w
  movc r8.x, r7.x, cb0[55].w, r0.z
  movc r8.y, r7.x, cb0[56].x, r4.w
  movc r0.yz, r0.yyyy, cb0[41].xxyx, r8.xxyx
  dp3 r3.x, r1.xyzx, r3.xzwx
  max r3.x, r3.x, l(0.001000)
  log r3.x, r3.x
  mul r0.y, r0.y, r3.x
  exp r0.y, r0.y
  add r3.x, -r6.z, l(1.000000)
  lt r0.y, r3.x, r0.y
  mul r3.xzw, r0.zzzz, cb0[39].yyzw
  mul r3.xzw, r6.xxxx, r3.xxzw
  and r3.xzw, r0.yyyy, r3.xxzw
  mul r3.xzw, r3.xxzw, cb0[87].xxxx
  and r9.xyz, r0.yyyy, r3.xzwx
endif
mul r3.xzw, r4.xxyz, cb0[46].xxyz
mul r3.xzw, r3.xxzw, cb0[45].zzzz
eq r0.y, r0.w, l(1.000000)
mul r4.xyz, r3.xzwx, cb0[45].wwww
mul r6.xyz, r3.xzwx, cb0[53].xxxx
mul r8.xyz, r3.xzwx, cb0[58].wwww
mul r10.xyz, r3.xzwx, cb0[64].wwww
mul r12.xyz, r3.xzwx, cb0[70].wwww
movc r3.xzw, r7.wwww, r12.xxyz, r3.xxzw
movc r3.xzw, r7.zzzz, r10.xxyz, r3.xxzw
movc r3.xzw, r7.yyyy, r8.xxyz, r3.xxzw
movc r3.xzw, r7.xxxx, r6.xxyz, r3.xxzw
movc r0.yzw, r0.yyyy, r4.xxyz, r3.xxzw
lt r3.x, r0.x, l(1.000000)
mul r4.xyz, r0.xxxx, r9.xyzx
movc r3.xzw, r3.xxxx, r4.xxyz, r9.xxyz
add r3.xzw, r3.xxzw, r5.xxyz
add r0.xyz, r0.yzwy, -r3.xzwx
mad r0.xyz, r2.wwww, r0.xyzx, r3.xzwx
movc r0.xyz, r1.wwww, r0.xyzx, r3.xzwx
dp3 r0.w, r1.xyzx, r1.xyzx
rsq r0.w, r0.w
mul r3.xzw, r0.wwww, r1.xxyz
dp3_sat r0.w, r2.xyzx, r3.xzwx
add r0.w, -r0.w, l(1.000000)
max r0.w, r0.w, l(0.000100)
log r0.w, r0.w
mul r0.w, r0.w, cb0[101].x
exp r0.w, r0.w
max r2.xyz, cb0[99].xyzx, cb0[100].xyzx
mul r2.xyz, r0.wwww, r2.xyzx
mad r0.xyz, r2.xyzx, cb0[101].yyyy, r0.xyzx
add r1.w, -r2.w, l(1.000000)
mad r1.w, cb0[101].z, r1.w, r2.w
mad r2.xyz, r2.xyzx, cb0[101].yyyy, r11.xyzx
max r2.w, r0.z, r0.y
max r4.w, r0.x, r2.w
lt r2.w, l(1.000000), r4.w
div r4.xyz, r0.xyzx, r4.wwww
mov r0.w, l(1.000000)
movc r0.xyzw, r2.wwww, r4.xyzw, r0.xyzw
add r3.xzw, -r0.xxyz, r2.xxyz
mad r3.xzw, cb0[97].xxxx, r3.xxzw, r0.xxyz
movc r2.xyz, r3.yyyy, r3.xzwx, r2.xyzx
mul_sat r0.w, r0.w, l(0.050000)
sqrt o1.w, r0.w
ftou r0.w, cb0[79].x
mad o0.xyz, r1.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), l(0.500000, 0.500000, 0.500000, 0.000000)
utof r0.w, r0.w
mul o5.x, r0.w, l(0.00392156886)
ne r0.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[24].x
mul r1.x, cb0[24].y, l(0.00392156886)
movc o2.z, r0.w, r1.x, r2.z
and o0.w, r7.x, l(0x3eaa7efa)
mov o1.xyz, r0.xyzx
mov o2.xy, r2.xyxx
mov o2.w, r1.w
mov o3.x, l(0.0156862754)
mov o4.x, r1.w
ret
// Approximately 0 instruction slots used

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
