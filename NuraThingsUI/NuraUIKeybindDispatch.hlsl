// Converts a pressed key ID to one compact global module KeyBind row.
// IniParams[68].x = key ID (1..36). UIState[61] = matched row, or 128 when unbound.
RWBuffer<float> UIState : register(u0);
Buffer<uint> KeybindRegistry : register(t0);
Buffer<float> KeybindDescriptors : register(t1);
Texture1D<float4> IniParams : register(t120);
static const uint ROW_CAPACITY = 128u;
[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint keyId = (uint)clamp(round(IniParams[68].x), 0.0f, 36.0f);
    uint matchedRow = ROW_CAPACITY;
    if (keyId > 0u)
    {
        [loop]
        for (uint row = 0u; row < ROW_CAPACITY; ++row)
        {
            if (KeybindRegistry[row] == 0u) continue;
            uint base = row * 4u;
            uint assignedKey = (uint)max(round(KeybindDescriptors[base + 2u]), 0.0f);
            if (assignedKey == keyId) { matchedRow = row; break; }
        }
    }
    UIState[61] = (float)matchedRow;
}
