// Assigns one module action row to a captured key ID. Duplicate key IDs are cleared globally.
RWBuffer<uint> KeybindRegistry : register(u0);
RWBuffer<float> KeybindDescriptors : register(u1);
Texture1D<float4> IniParams : register(t120);
static const uint ROW_CAPACITY = 128u;
[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint row = (uint)clamp(round(IniParams[68].x), 0.0f, 128.0f);
    uint keyId = (uint)clamp(round(IniParams[68].y), 0.0f, 36.0f);
    if (row >= ROW_CAPACITY || KeybindRegistry[row] == 0u) return;
    if (keyId > 0u)
    {
        [loop]
        for (uint i = 0u; i < ROW_CAPACITY; ++i)
        {
            if (i == row || KeybindRegistry[i] == 0u) continue;
            uint baseOther = i * 4u;
            if ((uint)max(round(KeybindDescriptors[baseOther + 2u]), 0.0f) == keyId)
                KeybindDescriptors[baseOther + 2u] = 0.0f;
        }
    }
    KeybindDescriptors[row * 4u + 2u] = (float)keyId;
}
