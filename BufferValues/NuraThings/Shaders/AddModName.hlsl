// AddModName.hlsl
Buffer<uint>   ThisModName : register(t0); // input: up to 64 chars, 0-terminated
RWBuffer<uint> NameChars   : register(u0); // global char pool (no gaps)
RWBuffer<uint> NameOffsets : register(u1); // per-model start index
RWBuffer<uint> UsedIDs     : register(u2); // per-model ID list
RWBuffer<uint> CharCounter : register(u3); // CharCounter[0] = next free char idx
RWBuffer<uint> IDCounter   : register(u4); // IDCounter[0] = next free slot
RWBuffer<float> FloatOutput      : register(u5);
//RWBuffer<float4> Debug      : register(u5);
Texture1D<float4> IniParams : register(t120);
#define mod_id asuint(IniParams[47].x)

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    if (mod_id == 0) return;

    // 1) skip if already registered
    for (uint i = 0; i < 512; i++)
        if (UsedIDs[i] == mod_id)
            return;

    // 2) claim an ID slot
    uint slot;
    InterlockedAdd(IDCounter[0], 1, slot);
    UsedIDs[slot] = mod_id;

    // 3) record where this name will start
    uint startIdx;
    InterlockedAdd(CharCounter[0], 0, startIdx); 
    // (InterlockedAdd with 0 just reads the current counter atomically)
    NameOffsets[slot] = startIdx;

    // 4) for each character, allocate 1 slot and write it
    for (uint c = 0; c < 64; c++) {
        uint idx;
        InterlockedAdd(CharCounter[0], 1, idx);  // idx = old counter, then counter++

        uint ch = ThisModName[c];
        if (ch == 0) {
            NameChars[idx] = '\n';
            break;
        }
        NameChars[idx] = ch;
    }

    FloatOutput[0] = float(IDCounter[0]);
    //Debug[slot] = float4(slot, asfloat(mod_id), asfloat(UsedIDs[slot]), asfloat(startIdx));
}
