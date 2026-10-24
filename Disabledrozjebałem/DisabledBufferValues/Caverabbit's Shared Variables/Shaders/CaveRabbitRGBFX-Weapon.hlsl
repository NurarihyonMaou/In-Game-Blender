// ---- Created with 3Dmigoto v1.3.16 on Thu Jul 18 10:03:52 2024
Texture2D<float4> t6 : register(t6);

Texture2D<float4> t5 : register(t5);

Texture2D<float4> t4 : register(t4);

Texture2D<float4> t3 : register(t3);

Texture2D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s6_s : register(s6);

SamplerState s5_s : register(s5);

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
  float4 cb0[108];
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
  float4 v6 : TEXCOORD4,
  float4 v7 : TEXCOORD8,
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
  r0.x = r3.x ? r4.y : 0.5;
  r3.x = cmp(0 != cb0[52].x);
  r5.xyzw = cmp(r4.wwww >= float4(0.800000012,0.400000006,0.200000003,0.600000024));
  r3.x = r3.x ? r5.x : 0;
  r3.x = r3.x ? 2 : 1;
  r3.w = cmp(0 != cb0[57].w);
  r3.w = r5.y ? r3.w : 0;
  r6.xyz = cmp(r4.www < float3(0.600000024,0.400000006,0.800000012));
  r3.w = r3.w ? r6.x : 0;
  r3.x = r3.w ? 3 : r3.x;
  r3.w = cmp(0 != cb0[63].w);
  r3.w = r5.z ? r3.w : 0;
  r3.w = r6.y ? r3.w : 0;
  r3.x = r3.w ? 4 : r3.x;
  r3.w = cmp(0 != cb0[69].w);
  r3.w = r5.w ? r3.w : 0;
  r3.w = r6.z ? r3.w : 0;
  r3.x = r3.w ? 5 : r3.x;
  r5.xyzw = cmp(r3.xxxx == float4(2,3,4,5));
  r6.xyz = r5.xxx ? cb0[52].yzw : cb0[25].xyz;
  r6.xyz = r5.yyy ? cb0[58].xyz : r6.xyz;
  r6.xyz = r5.zzz ? cb0[64].xyz : r6.xyz;
  r6.xyz = r5.www ? cb0[70].xyz : r6.xyz;
  r2.xyz = r6.xyz * r2.xyz;
  r3.w = cmp(0.00999999978 < r2.w);
  r3.z = r3.w ? r3.z : 0;
  r2.w = r3.z ? r2.w : 0;
  r3.w = v1.x * r0.x;
  r0.x = r3.y ? r3.w : r0.x;
  r3.y = cmp(r0.x < 0.0500000007);
  r3.w = cmp(0.949999988 < r0.x);
  r0.x = v3.w + r0.x;
  r0.x = 0.5 * r0.x;
  r0.x = r3.w ? 1 : r0.x;
  r0.x = r3.y ? 0 : r0.x;
  r3.y = cmp(r0.x < cb0[35].z);
  if (r3.y != 0) {
    r3.y = cmp(0 != cb0[38].z);
    r6.x = r5.x ? cb0[57].y : cb0[38].w;
    r6.y = r5.x ? cb0[57].z : cb0[39].x;
    r4.yw = r5.yy ? cb0[63].yz : r6.xy;
    r4.yw = r5.zz ? cb0[69].yz : r4.yw;
    r4.yw = r5.ww ? cb0[75].yz : r4.yw;
    r0.x = cb0[35].z + -r0.x;
    r0.x = r0.x / r4.y;
    r3.w = cmp(r0.x >= 1);
    r0.x = 0.00999999978 + r0.x;
    r0.x = log2(r0.x);
    r0.x = r4.w * r0.x;
    r0.x = exp2(r0.x);
    r0.x = min(1, r0.x);
    r0.x = r3.w ? 1 : r0.x;
    r0.x = r3.y ? r0.x : 1;
    r3.y = 0;
  } else {
    r0.x = 0;
    r3.y = 1;
  }
  r3.y = 1 + -r3.y;
  r3.w = cmp(9.99999975e-06 < v6.x);
  r3.y = r3.w ? 1 : r3.y;
  r3.w = cmp(0.5 < cb0[91].w);
  r4.y = cb0[90].w + cb0[90].w;
  r4.y = min(1, r4.y);
  r3.w = r3.w ? r4.y : 1;
  r4.y = cmp(0.899999976 < r4.x);
  if (r4.y != 0) {
    r4.yw = cb2[15].xy * v3.yy;
    r4.yw = cb2[14].xy * v3.xx + r4.yw;
    r6.yz = cb2[16].xy * v3.zz + r4.yw;
    r6.x = cb0[79].z * r6.y;
    r4.yw = r6.xz * float2(0.5,0.5) + float2(0.5,0.5);
    r4.y = t2.Sample(s2_s, r4.yw).x;
    r4.y = saturate(cb0[79].y * r4.y);
    r6.xyz = -cb0[81].xyz + cb0[80].xyz;
    r6.xyz = r4.yyy * r6.xyz + cb0[81].xyz;
    r6.xyz = r6.xyz * r2.xyz;
    r4.y = dot(v3.xyz, r1.xzw);
    r4.y = max(0.00100000005, r4.y);
    r4.y = log2(r4.y);
    r4.y = cb0[82].w * r4.y;
    r4.y = exp2(r4.y);
    r7.x = saturate(cb0[83].w * r4.y);
    r4.y = cmp(cb0[84].z < r7.x);
    if (r4.y != 0) {
      r8.xyz = cb0[85].xyz;
    } else {
      r4.y = cmp(0 != cb0[84].y);
      if (r4.y != 0) {
        r7.y = 0.5;
        r7.yzw = t3.Sample(s3_s, r7.xy).xyz;
        r8.xyz = r7.yzw * r4.zzz;
      } else {
        r7.xyz = cb0[83].xyz * r7.xxx;
        r8.xyz = r7.xyz * r4.zzz;
      }
    }
    r4.y = cmp(0 != v6.x);
    r7.xyz = cb0[84].xxx * r8.xyz;
    r7.xyz = r4.yyy ? r7.xyz : r8.xyz;
    r4.y = cmp(0 != cb0[38].z);
    r8.xyz = float3(-1,-1,-1) + cb0[82].xyz;
    r8.xyz = r0.xxx * r8.xyz + float3(1,1,1);
    r8.xyz = r4.yyy ? r8.xyz : cb0[82].xyz;
    r9.xyz = r8.xyz * r6.xyz;
    r4.y = cmp(0 != r3.y);
    r10.xyz = cb0[87].xxx * r6.xyz;
    r10.xyz = r4.yyy ? r9.xyz : r10.xyz;
    r4.y = cmp(r3.w < 1);
    r6.xyz = -r6.xyz * r8.xyz + r10.xyz;
    r6.xyz = r3.www * r6.xyz + r9.xyz;
    r6.xyz = r4.yyy ? r6.xyz : r10.xyz;
    r7.xyz = cb0[87].xxx * r7.xyz;
  } else {
    r4.y = cmp(r3.x == 1.000000);
    if (r4.y != 0) {
      r4.w = cmp(0 != cb0[36].w);
      r8.xyz = -cb0[37].xyz + cb0[36].xyz;
      r8.xyz = cb0[88].zzz * r8.xyz + cb0[37].xyz;
      r8.xyz = r4.www ? r8.xyz : cb0[36].xyz;
    } else {
      if (r5.x != 0) {
        r4.w = cmp(0 != cb0[36].w);
        r10.xyz = -cb0[55].xyz + cb0[54].xyz;
        r10.xyz = cb0[88].zzz * r10.xyz + cb0[55].xyz;
        r8.xyz = r4.www ? r10.xyz : cb0[54].xyz;
      } else {
        r4.w = cmp(0 != cb0[36].w);
        r10.xyz = -cb0[61].xyz + cb0[60].xyz;
        r10.xyz = cb0[88].zzz * r10.xyz + cb0[61].xyz;
        r10.xyz = r4.www ? r10.xyz : cb0[60].xyz;
        r11.xyz = -cb0[67].xyz + cb0[66].xyz;
        r11.xyz = cb0[88].zzz * r11.xyz + cb0[67].xyz;
        r11.xyz = r4.www ? r11.xyz : cb0[66].xyz;
        r12.xyz = -cb0[73].xyz + cb0[72].xyz;
        r12.xyz = cb0[88].zzz * r12.xyz + cb0[73].xyz;
        r12.xyz = r4.www ? r12.xyz : cb0[72].xyz;
        r11.xyz = r5.zzz ? r11.xyz : r12.xyz;
        r8.xyz = r5.yyy ? r10.xyz : r11.xyz;
      }
    }
    r4.w = cmp(r3.w < 1);
    r10.xyz = r4.www ? r8.xyz : 0;
    r6.w = cmp(0 != cb0[38].z);
    r7.w = cmp(0 != v6.x);
    r7.w = ~(int)r7.w;
    r6.w = r6.w ? r7.w : 0;
    r11.xyz = float3(-1,-1,-1) + r8.xyz;
    r11.xyz = r0.xxx * r11.xyz + float3(1,1,1);
    r11.xyz = r6.www ? r11.xyz : r8.xyz;
    r9.xyz = r8.xyz * r2.xyz;
    r0.x = cmp(0 != r3.y);
    r8.xyz = r11.xyz * r2.xyz;
    r11.xyz = cb0[87].xxx * r2.xyz;
    r8.xyz = r0.xxx ? r8.xyz : r11.xyz;
    r11.xyz = r10.xyz * r2.xyz;
    r10.xyz = -r2.xyz * r10.xyz + r8.xyz;
    r10.xyz = r3.www * r10.xyz + r11.xyz;
    r6.xyz = r4.www ? r10.xyz : r8.xyz;
    r0.x = r5.z ? cb0[67].w : cb0[73].w;
    r3.y = r5.z ? cb0[68].x : cb0[74].x;
    r0.x = r5.y ? cb0[61].w : r0.x;
    r3.y = r5.y ? cb0[62].x : r3.y;
    r8.x = r5.x ? cb0[55].w : r0.x;
    r8.y = r5.x ? cb0[56].x : r3.y;
    r4.yw = r4.yy ? cb0[41].xy : r8.xy;
    r0.x = dot(v3.xyz, r1.xzw);
    r0.x = max(0.00100000005, r0.x);
    r0.x = log2(r0.x);
    r0.x = r4.y * r0.x;
    r0.x = exp2(r0.x);
    r1.x = 1 + -r4.z;
    r0.x = cmp(r1.x < r0.x);
    r1.xzw = cb0[39].yzw * r4.www;
    r1.xzw = r1.xzw * r4.xxx;
    r1.xzw = r0.xxx ? r1.xzw : 0;
    r1.xzw = cb0[87].xxx * r1.xzw;
    r7.xyz = r0.xxx ? r1.xzw : 0;
  }
  r1.xzw = cb0[46].xyz * r2.xyz;
  r1.xzw = cb0[45].zzz * r1.xzw;
  r0.x = cmp(r3.x == 1.000000);
  r2.xyz = cb0[45].www * r1.xzw;
  r4.xyz = cb0[53].xxx * r1.xzw;
  r8.xyz = cb0[58].www * r1.xzw;
  r10.xyz = cb0[64].www * r1.xzw;
  r11.xyz = cb0[70].www * r1.xzw;
  r1.xzw = r5.www ? r11.xyz : r1.xzw;
  r1.xzw = r5.zzz ? r10.xyz : r1.xzw;
  r1.xzw = r5.yyy ? r8.xyz : r1.xzw;
  r1.xzw = r5.xxx ? r4.xyz : r1.xzw;
  r1.xzw = r0.xxx ? r2.xyz : r1.xzw;
  r0.x = cmp(r3.w < 1);
  r2.xyz = r7.xyz * r3.www;
  r2.xyz = r0.xxx ? r2.xyz : r7.xyz;
  r2.xyz = r6.xyz + r2.xyz;
  r1.xzw = -r2.xyz + r1.xzw;
  r1.xzw = r2.www * r1.xzw + r2.xyz;
  r1.xzw = r3.zzz ? r1.xzw : r2.xyz;
  r0.x = dot(v3.xyz, v3.xyz);
  r0.x = rsqrt(r0.x);
  r2.xyz = v3.xyz * r0.xxx;
  r0.x = dot(r2.xyz, r0.yzw);
  r0.x = 1 + -r0.x;
  r0.x = max(9.99999975e-05, r0.x);
  r0.y = r0.x * r0.x;
  r0.x = r0.x * r0.y;
  r0.yz = v2.zw * cb0[99].xy + cb0[99].zw;
  r0.w = cmp(cb0[100].z == 1.000000);
  r3.x = 1 + -v2.w;
  r0.w = r0.w ? r3.x : v2.w;
  r0.w = cb0[100].y * 2.0999999 + r0.w;
  r3.y = -1 + r0.w;
  r3.x = v2.z;
  r3.xy = t4.Sample(s5_s, r3.xy).xy;
  r0.yz = cb1[0].yy * cb0[100].xx + r0.yz;
  r0.y = t5.Sample(s4_s, r0.yz).x;
  r0.x = r0.x * 1.10000002 + r0.y;
  r0.y = -0.25 + cb0[100].y;
  r0.y = 6.28000021 * r0.y;
  r0.y = sin(r0.y);
  r0.y = 1 + r0.y;
  r0.x = r0.y * r0.x;
  r0.y = 3 * r3.y;
  r0.x = r0.x * 0.5 + r0.y;
  r0.yzw = cb1[5].xyz + -v7.xyz;
  r3.y = dot(r0.yzw, r0.yzw);
  r3.y = rsqrt(r3.y);
  r0.yzw = r3.yyy * r0.yzw;
  r0.y = saturate(dot(r0.yzw, r2.xyz));
  r0.y = 1 + -r0.y;
  r0.y = max(9.99999975e-05, r0.y);
  r0.y = log2(r0.y);
  r0.y = cb0[102].x * r0.y;
  r0.y = exp2(r0.y);
  r0.yzw = cb0[103].xyz * r0.yyy;
  r2.xy = v2.zw * cb0[105].xy + cb0[105].zw;
  r3.y = cmp(cb0[106].x == 1.000000);
  r3.z = 1 + -r2.y;
  r2.y = r3.y ? r3.z : r2.y;
  r3.y = cb1[0].y * cb0[106].y;
  r2.z = r2.y * 0.5 + r3.y;
  r2.x = t6.Sample(s6_s, r2.xz).x;
  r2.x = cb0[106].z * r2.x;
  r1.xzw = r0.xxx * cb0[101].xyz + r1.xzw;
  r1.xzw = r0.yzw * cb0[104].xxx + r1.xzw;
  r4.xyz = r2.xxx * cb0[107].xyz + r1.xzw;
  r1.x = r0.x + r2.w;
  r1.x = r0.y * cb0[104].x + r1.x;
  r1.x = saturate(r2.x * cb0[107].x + r1.x);
  r2.yzw = r0.xxx * cb0[101].xyz + r9.xyz;
  r0.xyz = r0.yzw * cb0[104].xxx + r2.yzw;
  r0.xyz = r2.xxx * cb0[107].xyz + r0.xyz;
  r0.w = max(r4.y, r4.z);
  r2.w = max(r4.x, r0.w);
  r0.w = cmp(1 < r2.w);
  r2.xyz = r4.xyz / r2.www;
  r4.w = 1;
  r2.xyzw = r0.wwww ? r2.xyzw : r4.xyzw;
  r3.yzw = -r2.xyz + r0.xyz;
  r3.yzw = cb0[97].xxx * r3.yzw + r2.xyz;
  r0.xyz = r1.yyy ? r3.yzw : r0.xyz;
  r0.w = -0.00100000005 + r3.x;
  r0.w = cmp(r0.w < 0);
  if (r0.w != 0) discard;
  r0.w = saturate(0.0500000007 * r2.w);
    //Sample mask
    r11 = tex17.Sample(s2_s, v2.xy);
    //
    //o1.w = sqrt(r0.w);
    o1.w = r11.y ? max(r11.y * IniParams[18].y, sqrt(r0.w)) : sqrt(r0.w);
    //
  o0.xyz = v3.xyz * float3(0.5,0.5,0.5) + float3(0.5,0.5,0.5);
  r0.w = cmp(0 != cb0[24].x);
  r1.y = 0.00392156886 * cb0[24].y;
    //o2.z = r0.w ? r1.y : r0.z;
    r0.w = r0.w ? r1.y : r0.z;
    o2.z = r11.z ? lerp(r0.w, IniParams[17].z, min(IniParams[17].w, 0.75)) : r0.w;
    //
  o0.w = r5.x ? 0.333000 : 0;
    //o1.xyz = r2.xyz;
    o1.xyz = r11.z ? lerp(r2.xyz, IniParams[17].xyz, min(IniParams[17].w, 0.75)) : r2.xyz;
    //
    //o2.xy = r0.xy;
    o2.xy = r11.z ? lerp(r0.xy, IniParams[17].xy, min(IniParams[17].w, 0.75)) : r0.xy;
    //
    //o2.w = r1.x;
    o2.w = r11.y ? max(r11.y * IniParams[18].y, r1.x) : r1.x;
    //
  o3.x = 0.0156862754;
    //o4.x = r1.x;
    o4.x = r11.z ? max(r11.z * IniParams[18].z, r1.x) : r1.x;
    //
  o5.x = 0;
  return;
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// Generated by Microsoft (R) D3D Shader Disassembler
//
//   using 3Dmigoto v1.3.16 on Thu Jul 18 10:03:52 2024
//
//
// Input signature:
//
// Name                 Index   Mask Register SysValue  Format   Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_POSITION              0   xyzw        0      POS   float
// COLOR                    0   xyzw        1     NONE   float   x  w
// TEXCOORD                 0   xyzw        2     NONE   float   xyzw
// TEXCOORD                 1   xyzw        3     NONE   float   xyzw
// TEXCOORD                 2   xyzw        4     NONE   float   xy w
// TEXCOORD                 3   xyz         5     NONE   float   xyz
// TEXCOORD                 4   xy          6     NONE   float   xy
// TEXCOORD                 8   xyzw        7     NONE   float   xyz
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
dcl_constantbuffer CB0[108], immediateIndexed
dcl_constantbuffer CB1[8], immediateIndexed
dcl_constantbuffer CB2[17], immediateIndexed
dcl_sampler s0, mode_default
dcl_sampler s1, mode_default
dcl_sampler s2, mode_default
dcl_sampler s3, mode_default
dcl_sampler s4, mode_default
dcl_sampler s5, mode_default
dcl_sampler s6, mode_default
dcl_resource_texture2d (float,float,float,float) t0
dcl_resource_texture2d (float,float,float,float) t1
dcl_resource_texture2d (float,float,float,float) t2
dcl_resource_texture2d (float,float,float,float) t3
dcl_resource_texture2d (float,float,float,float) t4
dcl_resource_texture2d (float,float,float,float) t5
dcl_resource_texture2d (float,float,float,float) t6
dcl_input_ps linear v1.xw
dcl_input_ps linear v2.xyzw
dcl_input_ps linear v3.xyzw
dcl_input_ps linear v4.xyw
dcl_input_ps linear v5.xyz
dcl_input_ps linear v6.xy
dcl_input_ps linear v7.xyz
dcl_output o0.xyzw
dcl_output o1.xyzw
dcl_output o2.xyzw
dcl_output o3.x
dcl_output o4.x
dcl_output o5.x
dcl_temps 13
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
dp3 r0.x, v5.xyzx, v5.xyzx
rsq r0.x, r0.x
mul r0.yzw, r0.xxxx, v5.xxyz
lt r1.xy, l(0.000000, 0.500000, 0.000000, 0.000000), cb0[95].wwww
ne r1.z, l(0.000000, 0.000000, 0.000000, 0.000000), v6.y
movc r2.xyz, r1.zzzz, cb0[96].xyzx, cb0[95].xyzx
movc r1.xzw, r1.xxxx, r2.xxyz, cb0[91].xxyz
mad r1.xzw, v5.xxyz, r0.xxxx, r1.xxzw
dp3 r0.x, r1.xzwx, r1.xzwx
rsq r0.x, r0.x
mul r1.xzw, r0.xxxx, r1.xxzw
add r0.x, cb0[76].z, l(-1.000000)
sample_b_indexable(texture2d)(float,float,float,float) r2.xyzw, v2.xyxx, t0.xyzw, s0, r0.x
eq r3.xyz, cb0[28].xxxx, l(3.000000, 1.000000, 2.000000, 0.000000)
mul r3.w, r2.w, cb0[41].w
add r4.xyz, -r2.xyzx, cb0[42].xyzx
mad r4.xyz, r3.wwww, r4.xyzx, r2.xyzx
movc r2.xyz, r3.xxxx, r4.xyzx, r2.xyzx
add r3.x, r2.w, -cb0[28].y
lt r3.x, r3.x, l(0.000000)
and r3.x, r3.y, r3.x
discard_nz r3.x
sample_b_indexable(texture2d)(float,float,float,float) r4.xyzw, v2.xyxx, t1.xyzw, s1, r0.x
ne r3.xy, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[35].xyxx
movc r0.x, r3.x, r4.y, l(0.500000)
ne r3.x, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[52].x
ge r5.xyzw, r4.wwww, l(0.800000, 0.400000, 0.200000, 0.600000)
and r3.x, r3.x, r5.x
movc r3.x, r3.x, l(2.000000), l(1.000000)
ne r3.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[57].w
and r3.w, r5.y, r3.w
lt r6.xyz, r4.wwww, l(0.600000, 0.400000, 0.800000, 0.000000)
and r3.w, r3.w, r6.x
movc r3.x, r3.w, l(3.000000), r3.x
ne r3.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[63].w
and r3.w, r5.z, r3.w
and r3.w, r6.y, r3.w
movc r3.x, r3.w, l(4.000000), r3.x
ne r3.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[69].w
and r3.w, r5.w, r3.w
and r3.w, r6.z, r3.w
movc r3.x, r3.w, l(5.000000), r3.x
eq r5.xyzw, r3.xxxx, l(2.000000, 3.000000, 4.000000, 5.000000)
movc r6.xyz, r5.xxxx, cb0[52].yzwy, cb0[25].xyzx
movc r6.xyz, r5.yyyy, cb0[58].xyzx, r6.xyzx
movc r6.xyz, r5.zzzz, cb0[64].xyzx, r6.xyzx
movc r6.xyz, r5.wwww, cb0[70].xyzx, r6.xyzx
mul r2.xyz, r2.xyzx, r6.xyzx
lt r3.w, l(0.010000), r2.w
and r3.z, r3.w, r3.z
and r2.w, r2.w, r3.z
mul r3.w, r0.x, v1.x
movc r0.x, r3.y, r3.w, r0.x
lt r3.y, r0.x, l(0.050000)
lt r3.w, l(0.950000), r0.x
add r0.x, r0.x, v3.w
mul r0.x, r0.x, l(0.500000)
movc r0.x, r3.w, l(1.000000), r0.x
movc r0.x, r3.y, l(0), r0.x
lt r3.y, r0.x, cb0[35].z
if_nz r3.y
  ne r3.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[38].z
  movc r6.x, r5.x, cb0[57].y, cb0[38].w
  movc r6.y, r5.x, cb0[57].z, cb0[39].x
  movc r4.yw, r5.yyyy, cb0[63].yyyz, r6.xxxy
  movc r4.yw, r5.zzzz, cb0[69].yyyz, r4.yyyw
  movc r4.yw, r5.wwww, cb0[75].yyyz, r4.yyyw
  add r0.x, -r0.x, cb0[35].z
  div r0.x, r0.x, r4.y
  ge r3.w, r0.x, l(1.000000)
  add r0.x, r0.x, l(0.010000)
  log r0.x, r0.x
  mul r0.x, r0.x, r4.w
  exp r0.x, r0.x
  min r0.x, r0.x, l(1.000000)
  movc r0.x, r3.w, l(1.000000), r0.x
  movc r0.x, r3.y, r0.x, l(1.000000)
  mov r3.y, l(0)
else
  mov r0.x, l(0)
  mov r3.y, l(1.000000)
endif
add r3.y, -r3.y, l(1.000000)
lt r3.w, l(0.000010), v6.x
movc r3.y, r3.w, l(1.000000), r3.y
lt r3.w, l(0.500000), cb0[91].w
add r4.y, cb0[90].w, cb0[90].w
min r4.y, r4.y, l(1.000000)
movc r3.w, r3.w, r4.y, l(1.000000)
lt r4.y, l(0.900000), r4.x
if_nz r4.y
  mul r4.yw, v3.yyyy, cb2[15].xxxy
  mad r4.yw, cb2[14].xxxy, v3.xxxx, r4.yyyw
  mad r6.yz, cb2[16].xxyx, v3.zzzz, r4.yywy
  mul r6.x, r6.y, cb0[79].z
  mad r4.yw, r6.xxxz, l(0.000000, 0.500000, 0.000000, 0.500000), l(0.000000, 0.500000, 0.000000, 0.500000)
  sample_indexable(texture2d)(float,float,float,float) r4.y, r4.ywyy, t2.yxzw, s2
  mul_sat r4.y, r4.y, cb0[79].y
  add r6.xyz, cb0[80].xyzx, -cb0[81].xyzx
  mad r6.xyz, r4.yyyy, r6.xyzx, cb0[81].xyzx
  mul r6.xyz, r2.xyzx, r6.xyzx
  dp3 r4.y, v3.xyzx, r1.xzwx
  max r4.y, r4.y, l(0.001000)
  log r4.y, r4.y
  mul r4.y, r4.y, cb0[82].w
  exp r4.y, r4.y
  mul_sat r7.x, r4.y, cb0[83].w
  lt r4.y, cb0[84].z, r7.x
  if_nz r4.y
    mov r8.xyz, cb0[85].xyzx
  else
    ne r4.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[84].y
    if_nz r4.y
      mov r7.y, l(0.500000)
      sample_indexable(texture2d)(float,float,float,float) r7.yzw, r7.xyxx, t3.wxyz, s3
      mul r8.xyz, r4.zzzz, r7.yzwy
    else
      mul r7.xyz, r7.xxxx, cb0[83].xyzx
      mul r8.xyz, r4.zzzz, r7.xyzx
    endif
  endif
  ne r4.y, l(0.000000, 0.000000, 0.000000, 0.000000), v6.x
  mul r7.xyz, r8.xyzx, cb0[84].xxxx
  movc r7.xyz, r4.yyyy, r7.xyzx, r8.xyzx
  ne r4.y, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[38].z
  add r8.xyz, cb0[82].xyzx, l(-1.000000, -1.000000, -1.000000, 0.000000)
  mad r8.xyz, r0.xxxx, r8.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
  movc r8.xyz, r4.yyyy, r8.xyzx, cb0[82].xyzx
  mul r9.xyz, r6.xyzx, r8.xyzx
  ne r4.y, l(0.000000, 0.000000, 0.000000, 0.000000), r3.y
  mul r10.xyz, r6.xyzx, cb0[87].xxxx
  movc r10.xyz, r4.yyyy, r9.xyzx, r10.xyzx
  lt r4.y, r3.w, l(1.000000)
  mad r6.xyz, -r6.xyzx, r8.xyzx, r10.xyzx
  mad r6.xyz, r3.wwww, r6.xyzx, r9.xyzx
  movc r6.xyz, r4.yyyy, r6.xyzx, r10.xyzx
  mul r7.xyz, r7.xyzx, cb0[87].xxxx
else
  eq r4.y, r3.x, l(1.000000)
  if_nz r4.y
    ne r4.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[36].w
    add r8.xyz, cb0[36].xyzx, -cb0[37].xyzx
    mad r8.xyz, cb0[88].zzzz, r8.xyzx, cb0[37].xyzx
    movc r8.xyz, r4.wwww, r8.xyzx, cb0[36].xyzx
  else
    if_nz r5.x
      ne r4.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[36].w
      add r10.xyz, cb0[54].xyzx, -cb0[55].xyzx
      mad r10.xyz, cb0[88].zzzz, r10.xyzx, cb0[55].xyzx
      movc r8.xyz, r4.wwww, r10.xyzx, cb0[54].xyzx
    else
      ne r4.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[36].w
      add r10.xyz, cb0[60].xyzx, -cb0[61].xyzx
      mad r10.xyz, cb0[88].zzzz, r10.xyzx, cb0[61].xyzx
      movc r10.xyz, r4.wwww, r10.xyzx, cb0[60].xyzx
      add r11.xyz, cb0[66].xyzx, -cb0[67].xyzx
      mad r11.xyz, cb0[88].zzzz, r11.xyzx, cb0[67].xyzx
      movc r11.xyz, r4.wwww, r11.xyzx, cb0[66].xyzx
      add r12.xyz, cb0[72].xyzx, -cb0[73].xyzx
      mad r12.xyz, cb0[88].zzzz, r12.xyzx, cb0[73].xyzx
      movc r12.xyz, r4.wwww, r12.xyzx, cb0[72].xyzx
      movc r11.xyz, r5.zzzz, r11.xyzx, r12.xyzx
      movc r8.xyz, r5.yyyy, r10.xyzx, r11.xyzx
    endif
  endif
  lt r4.w, r3.w, l(1.000000)
  and r10.xyz, r8.xyzx, r4.wwww
  ne r6.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[38].z
  ne r7.w, l(0.000000, 0.000000, 0.000000, 0.000000), v6.x
  not r7.w, r7.w
  and r6.w, r6.w, r7.w
  add r11.xyz, r8.xyzx, l(-1.000000, -1.000000, -1.000000, 0.000000)
  mad r11.xyz, r0.xxxx, r11.xyzx, l(1.000000, 1.000000, 1.000000, 0.000000)
  movc r11.xyz, r6.wwww, r11.xyzx, r8.xyzx
  mul r9.xyz, r2.xyzx, r8.xyzx
  ne r0.x, l(0.000000, 0.000000, 0.000000, 0.000000), r3.y
  mul r8.xyz, r2.xyzx, r11.xyzx
  mul r11.xyz, r2.xyzx, cb0[87].xxxx
  movc r8.xyz, r0.xxxx, r8.xyzx, r11.xyzx
  mul r11.xyz, r2.xyzx, r10.xyzx
  mad r10.xyz, -r2.xyzx, r10.xyzx, r8.xyzx
  mad r10.xyz, r3.wwww, r10.xyzx, r11.xyzx
  movc r6.xyz, r4.wwww, r10.xyzx, r8.xyzx
  movc r0.x, r5.z, cb0[67].w, cb0[73].w
  movc r3.y, r5.z, cb0[68].x, cb0[74].x
  movc r0.x, r5.y, cb0[61].w, r0.x
  movc r3.y, r5.y, cb0[62].x, r3.y
  movc r8.x, r5.x, cb0[55].w, r0.x
  movc r8.y, r5.x, cb0[56].x, r3.y
  movc r4.yw, r4.yyyy, cb0[41].xxxy, r8.xxxy
  dp3 r0.x, v3.xyzx, r1.xzwx
  max r0.x, r0.x, l(0.001000)
  log r0.x, r0.x
  mul r0.x, r0.x, r4.y
  exp r0.x, r0.x
  add r1.x, -r4.z, l(1.000000)
  lt r0.x, r1.x, r0.x
  mul r1.xzw, r4.wwww, cb0[39].yyzw
  mul r1.xzw, r4.xxxx, r1.xxzw
  and r1.xzw, r0.xxxx, r1.xxzw
  mul r1.xzw, r1.xxzw, cb0[87].xxxx
  and r7.xyz, r0.xxxx, r1.xzwx
endif
mul r1.xzw, r2.xxyz, cb0[46].xxyz
mul r1.xzw, r1.xxzw, cb0[45].zzzz
eq r0.x, r3.x, l(1.000000)
mul r2.xyz, r1.xzwx, cb0[45].wwww
mul r4.xyz, r1.xzwx, cb0[53].xxxx
mul r8.xyz, r1.xzwx, cb0[58].wwww
mul r10.xyz, r1.xzwx, cb0[64].wwww
mul r11.xyz, r1.xzwx, cb0[70].wwww
movc r1.xzw, r5.wwww, r11.xxyz, r1.xxzw
movc r1.xzw, r5.zzzz, r10.xxyz, r1.xxzw
movc r1.xzw, r5.yyyy, r8.xxyz, r1.xxzw
movc r1.xzw, r5.xxxx, r4.xxyz, r1.xxzw
movc r1.xzw, r0.xxxx, r2.xxyz, r1.xxzw
lt r0.x, r3.w, l(1.000000)
mul r2.xyz, r3.wwww, r7.xyzx
movc r2.xyz, r0.xxxx, r2.xyzx, r7.xyzx
add r2.xyz, r2.xyzx, r6.xyzx
add r1.xzw, r1.xxzw, -r2.xxyz
mad r1.xzw, r2.wwww, r1.xxzw, r2.xxyz
movc r1.xzw, r3.zzzz, r1.xxzw, r2.xxyz
dp3 r0.x, v3.xyzx, v3.xyzx
rsq r0.x, r0.x
mul r2.xyz, r0.xxxx, v3.xyzx
dp3 r0.x, r2.xyzx, r0.yzwy
add r0.x, -r0.x, l(1.000000)
max r0.x, r0.x, l(0.000100)
mul r0.y, r0.x, r0.x
mul r0.x, r0.y, r0.x
mad r0.yz, v2.zzwz, cb0[99].xxyx, cb0[99].zzwz
eq r0.w, cb0[100].z, l(1.000000)
add r3.x, -v2.w, l(1.000000)
movc r0.w, r0.w, r3.x, v2.w
mad r0.w, cb0[100].y, l(2.100000), r0.w
add r3.y, r0.w, l(-1.000000)
mov r3.x, v2.z
sample_indexable(texture2d)(float,float,float,float) r3.xy, r3.xyxx, t4.xyzw, s5
mad r0.yz, cb1[0].yyyy, cb0[100].xxxx, r0.yyzy
sample_indexable(texture2d)(float,float,float,float) r0.y, r0.yzyy, t5.yxzw, s4
mad r0.x, r0.x, l(1.100000), r0.y
add r0.y, cb0[100].y, l(-0.250000)
mul r0.y, r0.y, l(6.280000)
sincos r0.y, null, r0.y
add r0.y, r0.y, l(1.000000)
mul r0.x, r0.x, r0.y
mul r0.y, r3.y, l(3.000000)
mad r0.x, r0.x, l(0.500000), r0.y
add r0.yzw, -v7.xxyz, cb1[5].xxyz
dp3 r3.y, r0.yzwy, r0.yzwy
rsq r3.y, r3.y
mul r0.yzw, r0.yyzw, r3.yyyy
dp3_sat r0.y, r0.yzwy, r2.xyzx
add r0.y, -r0.y, l(1.000000)
max r0.y, r0.y, l(0.000100)
log r0.y, r0.y
mul r0.y, r0.y, cb0[102].x
exp r0.y, r0.y
mul r0.yzw, r0.yyyy, cb0[103].xxyz
mad r2.xy, v2.zwzz, cb0[105].xyxx, cb0[105].zwzz
eq r3.y, cb0[106].x, l(1.000000)
add r3.z, -r2.y, l(1.000000)
movc r2.y, r3.y, r3.z, r2.y
mul r3.y, cb0[106].y, cb1[0].y
mad r2.z, r2.y, l(0.500000), r3.y
sample_indexable(texture2d)(float,float,float,float) r2.x, r2.xzxx, t6.xyzw, s6
mul r2.x, r2.x, cb0[106].z
mad r1.xzw, r0.xxxx, cb0[101].xxyz, r1.xxzw
mad r1.xzw, r0.yyzw, cb0[104].xxxx, r1.xxzw
mad r4.xyz, r2.xxxx, cb0[107].xyzx, r1.xzwx
add r1.x, r2.w, r0.x
mad r1.x, r0.y, cb0[104].x, r1.x
mad_sat r1.x, r2.x, cb0[107].x, r1.x
mad r2.yzw, r0.xxxx, cb0[101].xxyz, r9.xxyz
mad r0.xyz, r0.yzwy, cb0[104].xxxx, r2.yzwy
mad r0.xyz, r2.xxxx, cb0[107].xyzx, r0.xyzx
max r0.w, r4.z, r4.y
max r2.w, r0.w, r4.x
lt r0.w, l(1.000000), r2.w
div r2.xyz, r4.xyzx, r2.wwww
mov r4.w, l(1.000000)
movc r2.xyzw, r0.wwww, r2.xyzw, r4.xyzw
add r3.yzw, r0.xxyz, -r2.xxyz
mad r3.yzw, cb0[97].xxxx, r3.yyzw, r2.xxyz
movc r0.xyz, r1.yyyy, r3.yzwy, r0.xyzx
add r0.w, r3.x, l(-0.001000)
lt r0.w, r0.w, l(0.000000)
discard_nz r0.w
mul_sat r0.w, r2.w, l(0.050000)
sqrt o1.w, r0.w
mad o0.xyz, v3.xyzx, l(0.500000, 0.500000, 0.500000, 0.000000), l(0.500000, 0.500000, 0.500000, 0.000000)
ne r0.w, l(0.000000, 0.000000, 0.000000, 0.000000), cb0[24].x
mul r1.y, cb0[24].y, l(0.00392156886)
movc o2.z, r0.w, r1.y, r0.z
and o0.w, r5.x, l(0x3eaa7efa)
mov o1.xyz, r2.xyzx
mov o2.xy, r0.xyxx
mov o2.w, r1.x
mov o3.x, l(0.0156862754)
mov o4.x, r1.x
mov o5.x, l(0)
ret
// Approximately 0 instruction slots used

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
