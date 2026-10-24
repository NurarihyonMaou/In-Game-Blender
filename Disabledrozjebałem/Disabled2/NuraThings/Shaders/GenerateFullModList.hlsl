Buffer<uint> ThisModName            : register(t0); // up to 64 chars
RWBuffer<uint> FullModNameChars     : register(u0);
RWBuffer<uint> FullModNameOffsets   : register(u1);
RWBuffer<uint> FullModIDs           : register(u2); // local mod_id
RWBuffer<uint> ModToModelType       : register(u3); // model_type_id
RWBuffer<uint> CharCounter          : register(u4); // CharCounter[0]
RWBuffer<uint> ModCounter           : register(u5); // ModCounter[0]
RWBuffer<float> ModsPerTypeCount     : register(u6); // indexed by model_type_id
RWBuffer<float4> Debug     : register(u7); // indexed by model_type_id


Texture1D<float4> IniParams : register(t120);
//#define mod_id        asuint(IniParams[47].x)  // Local to model type
//#define model_type_id asuint(IniParams[47].y)  // e.g. Yelan = 69

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{

    uint mod_id        = asuint(IniParams[47].x);
    uint model_type_id = asuint(IniParams[47].y);

    if (mod_id == 0 || model_type_id == 0 || mod_id == -1 || model_type_id == -1) return;

    // Check if this (mod_id, model_type_id) already exists
    for (uint i = 0; i < 2048; i++) {
        if (FullModIDs[i] == mod_id && ModToModelType[i] == model_type_id)
            return;
    }

    // Register new mod
    uint modIndex;
    InterlockedAdd(ModCounter[0], 1, modIndex);
    
    FullModIDs[modIndex]       = mod_id;
    ModToModelType[modIndex]   = model_type_id;

    ModsPerTypeCount[IniParams[47].y]++;

    uint startChar;
    InterlockedAdd(CharCounter[0], 0, startChar);
    FullModNameOffsets[modIndex] = startChar;

    for (uint c = 0; c < 64; c++) {
        uint idx;
        InterlockedAdd(CharCounter[0], 1, idx);
        uint ch = ThisModName[c];
        if (ch == 0) {
            FullModNameChars[idx] = '\n';
            break;
        }
        FullModNameChars[idx] = ch;
    }
}