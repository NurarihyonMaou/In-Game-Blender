Texture1D<float4> IniParams : register(t120);

RWBuffer<float> SV : register(u0);
RWBuffer<float4> Debug : register(u1); // for debugging

[numthreads(1, 1, 1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint iFrameEnc = int(IniParams[91].y);
    uint iTimeEnc  = int(IniParams[91].z);
    uint iEncoded  = int(IniParams[91].x);
    uint iHscore   = int(IniParams[91].w);

    uint frame = (iFrameEnc / 7) - 42;
    uint time  = (iTimeEnc / 13) - iHscore;

    uint decodedScore = (iEncoded - ((frame % 10000) * 3 + (time % 3600))) / 1337;
    uint expectedHash = (((iHscore * 1337u) + (frame * 7u)) ^ (time * 13u)) % 16777216u;

    bool tampered = abs(int(iHscore - decodedScore)) > 0;

    SV[0] = tampered;
    SV[1] = expectedHash;
    Debug[25] = float4(iFrameEnc, iTimeEnc, iEncoded, expectedHash);
    Debug[26] = float4(frame, time, decodedScore, tampered);
   // Debug[27] = float4(hscore, tampered, (abs(hscore - encoded)), 69);
}