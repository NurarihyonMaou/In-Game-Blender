// FilterModsBySelectedType_WithTypeLookup.hlsl

// Inputs (read‐only)
Buffer<uint> FullModIDs           : register(t0);  // local mod_id
Buffer<uint> ModToModelType       : register(t1);  // model_type_id
Buffer<uint> FullModNameOffsets   : register(t2);  // start offsets
Buffer<uint> FullModNameChars     : register(t3);  // flat char array
Buffer<uint> ModCounter           : register(t4);  // total mods
Buffer<uint> ModelsUsedIDs        : register(t5);  // display‐ordered model_type_id list
Buffer<uint> ModelsUsedIDsCounter : register(t6);  // count of entries in ModelsUsedIDs

// Output
RWBuffer<uint> ActiveModNames     : register(u0);  // compact name list
RWBuffer<uint> ActiveModCounter   : register(u1);  // char write head
RWBuffer<uint> ActiveModCount     : register(u2);
RWBuffer<float> ActiveModCountFloat : register(u3);
RWBuffer<float4> Debug   : register(u4);
// Which line the user clicked on
Texture1D<float4> IniParams       : register(t120);
#define selectedLine IniParams[75].x-1

[numthreads(1,1,1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    // Reset write head
    ActiveModCounter[0] = 0;
    ActiveModCount[0] = 0;

    //Debug[7] = float4(ModelsUsedIDsCounter[0], ActiveModCounter[0], asfloat(selectedLine), asfloat(ModelsUsedIDs[selectedLine]));
    // 1) Figure out how many model types we actually have
    uint typeCount = ModelsUsedIDsCounter[0];
    if (typeCount == 0) return; 

    // 2) Clamp the clicked line to [0..typeCount-1]
    uint lineY = selectedLine;
    if (lineY >= typeCount) 
        return;

    // 3) Lookup the *real* modelTypeID from the display list
    uint modelTypeID = ModelsUsedIDs[lineY];

    // 4) Now filter all mods
    uint totalMods = ModCounter[0];
    // guard in case ModCounter has garbage
    if (totalMods > 2048) 
        totalMods = 2048;

    // maximum space in the output buffer
    const uint maxChars = 64 * 100;

    uint prevCount;

    for (uint i = 0; i < totalMods; i++)
    {
        if (ModToModelType[i] != modelTypeID)
            continue;

       InterlockedAdd(ActiveModCount[0], 1, prevCount);

        uint offset = FullModNameOffsets[i];

        // copy up to 64 characters (string ends on '\n')
        [unroll(64)]
        for (uint c = 0; c < 64; c++)
        {
            uint ch = FullModNameChars[offset + c];

            uint dst;
            InterlockedAdd(ActiveModCounter[0], 1, dst);
            if (dst >= maxChars) 
                break;  // safety check

            ActiveModNames[dst] = ch;
            if (ch == '\n')
                break;
        }
    }

    // (optional) null‐terminate with newline
    //uint endPos;
    //InterlockedAdd(ActiveModCounter[0], 1, endPos);
    //if (endPos < maxChars)
    //    ActiveModNames[endPos] = '\n';
    ActiveModCountFloat[0] = float(ActiveModCount[0]);
}
