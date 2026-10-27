// Smooth the selected vertex group's weights toward the current one-ring average.
struct PosBuf { float3 pos; float3 nor; float4 tan; };
struct BlendBuf { float4 blendWeights; int4 blendIndices; };
StructuredBuffer<PosBuf> PositionBuffer : register(t0);
Buffer<float> ProtectionMask : register(t1);
Buffer<uint> SmoothAccum : register(t2);
RWStructuredBuffer<BlendBuf> EditableBlend : register(u0);
RWBuffer<float4> EditorState : register(u1);
Texture1D<float4> IniParams : register(t120);
#define PAINT_PARAMS IniParams[40]
#define PAINT_EXT IniParams[41]
#define REPLAY_BRUSH IniParams[42]
#define MIRROR_PARAMS IniParams[36]
#define STATE_BRUSH_TRI 9u
#define STATE_BRUSH_BARY 10u
#define STATE_BRUSH_POS 11u
#define STATE_BRUSH_CENTER 17u
#define VERTEX_COUNT 79355u
#define WEIGHT_SCALE 65535.0f

float Get4(float4 v, uint i) { if(i==0u)return v.x; if(i==1u)return v.y; if(i==2u)return v.z; return v.w; }
void Set4(inout float4 v, uint i, float x) { if(i==0u)v.x=x; else if(i==1u)v.y=x; else if(i==2u)v.z=x; else v.w=x; }
int GetI4(int4 v,uint i){if(i==0u)return v.x;if(i==1u)return v.y;if(i==2u)return v.z;return v.w;}

bool GetLiveCenter(out float3 center)
{
    center = 0.0f;
    float4 p = EditorState[STATE_BRUSH_POS];
    if (p.w <= 0.5f) return false;
    float4 tri = EditorState[STATE_BRUSH_TRI];
    float4 bary = EditorState[STATE_BRUSH_BARY];
    if ((uint)tri.x < 0u || (uint)tri.y < 0u || (uint)tri.z < 0u || (uint)tri.x >= VERTEX_COUNT || (uint)tri.y >= VERTEX_COUNT || (uint)tri.z >= VERTEX_COUNT) return false;
    uint a=(uint)(tri.x+0.5f), b=(uint)(tri.y+0.5f), c=(uint)(tri.z+0.5f);
    center = PositionBuffer[a].pos*bary.x + PositionBuffer[b].pos*bary.y + PositionBuffer[c].pos*bary.z;
    return true;
}
float Falloff(float d,float r)
{
    if (r<=1e-7f || d>=r) return 0.0f;
    float t=saturate(d/r); uint m=(uint)clamp(round(PAINT_EXT.z),0.0f,4.0f);
    if(m==0u) return 1.0f-t*t*(3.0f-2.0f*t);
    if(m==1u) return 1.0f-t;
    if(m==2u){float q=1.0f-t;return q*q*q;}
    if(m==3u) return 1.0f;
    return sqrt(max(1.0f-t*t,0.0f));
}
float3 MirrorPoint(float3 p)
{
    int a=(int)clamp(round(MIRROR_PARAMS.y),0.0f,2.0f); float plane=MIRROR_PARAMS.z;
    if(a==0)p.x=2.0f*plane-p.x; else if(a==1)p.y=2.0f*plane-p.y; else p.z=2.0f*plane-p.z;
    return p;
}
void Normalize(inout float4 weights,uint selectedSlot)
{
    float target=saturate(Get4(weights,selectedSlot));
    float other=0.0f; [unroll] for(uint k=0;k<4u;k++) if(k!=selectedSlot) other+=Get4(weights,k);
    if(other<=1e-8f){weights=0.0f;Set4(weights,selectedSlot,1.0f);return;}
    float scale=(1.0f-target)/other;
    [unroll] for(uint j=0;j<4u;j++) if(j!=selectedSlot) Set4(weights,j,max(Get4(weights,j),0.0f)*scale);
    Set4(weights,selectedSlot,target);
}

[numthreads(64,1,1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint v=tid.x; if(v>=VERTEX_COUNT)return;
    float3 center=0.0f; bool valid;
    if(PAINT_EXT.y>0.5f){center=REPLAY_BRUSH.xyz;valid=REPLAY_BRUSH.w>0.5f;}
    else {valid=GetLiveCenter(center); if(v==0u) EditorState[STATE_BRUSH_CENTER]=valid?float4(center,1.0f):float4(0.0f,0.0f,0.0f,0.0f);}
    if(!valid)return;

    float radius=max(PAINT_EXT.x,1e-7f);
    float coverage=Falloff(length(PositionBuffer[v].pos-center),radius);
    if(MIRROR_PARAMS.x>0.5f)
    {
        int ax=(int)clamp(round(MIRROR_PARAMS.y),0.0f,2.0f);
        float coord=ax==0?center.x:(ax==1?center.y:center.z);
        if(abs(coord-MIRROR_PARAMS.z)>max(MIRROR_PARAMS.w,0.0f))
            coverage=max(coverage,Falloff(length(PositionBuffer[v].pos-MirrorPoint(center)),radius));
    }
    if(coverage<=0.0f)return;

    uint sum=SmoothAccum[v*2u], count=SmoothAccum[v*2u+1u];
    if(count==0u)return;
    float average=saturate((float)sum/(WEIGHT_SCALE*(float)count));
    float protection=saturate(ProtectionMask[v]);
    float amount=saturate(PAINT_PARAMS.z)*coverage*(1.0f-protection);
    if(amount<=0.0f)return;

    BlendBuf blend=EditableBlend[v];
    int vg=(int)round(PAINT_PARAMS.x); int slot=-1;
    if(blend.blendIndices.x==vg)slot=0; else if(blend.blendIndices.y==vg)slot=1; else if(blend.blendIndices.z==vg)slot=2; else if(blend.blendIndices.w==vg)slot=3;
    // Smooth changes existing memberships only; it never creates a new VG influence.
    if(slot<0)return;
    float4 weights=max(blend.blendWeights,0.0f);
    float old=saturate(Get4(weights,(uint)slot));
    Set4(weights,(uint)slot,lerp(old,average,amount));
    Normalize(weights,(uint)slot);
    blend.blendWeights=weights; EditableBlend[v]=blend;
}
