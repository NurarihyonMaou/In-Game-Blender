Texture1D<float4> IniParams : register(t120);

RWBuffer<uint> OutputString : register(u0); // 48 decoded digits
RWBuffer<float4> Debug         : register(u1); // for debugging

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint index = DTid.x;  
    if (index >= 48) return;

    // Which of the 12 floats holds this character group?
    uint textCodeIndex = index / 4;     // 0..11
    uint digitOffset   = index % 4;     // 0..3

    uint iniBlock = textCodeIndex / 4;  // 0..2  maps to IniParams[93,94,95]
    uint comp     = textCodeIndex % 4;  // .x/.y/.z/.w

    // Read the packed float
    float4 block = IniParams[93 + iniBlock];
    uint packed  = (uint)(block[comp] + 0.5);

    // Pure integer divisors for base‐40
    static const uint DIVS[4] = { 1u, 40u, 1600u, 64000u };

    // Decode
    uint digit = (packed / DIVS[digitOffset]) % 40u;

    OutputString[index] = digit;
    Debug[index]        = digit;  // write to debug UAV
}
