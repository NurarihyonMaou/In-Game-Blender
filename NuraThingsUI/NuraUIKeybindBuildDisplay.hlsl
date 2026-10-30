// Prepares the five visible KeyBinds rows for INI text rendering without dynamic INI array indexes.
// IniParams[68].x = global list scroll; empty rows are returned as index 128 and code 0.
Buffer<uint> KeybindRegistry : register(t0);
Buffer<float> KeybindDescriptors : register(t1);
RWBuffer<float> DisplayRows : register(u0);
RWBuffer<float> DisplayCodes : register(u1);
Texture1D<float4> IniParams : register(t120);
static const uint ROW_CAPACITY = 128u;
[numthreads(8, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    if (id.x >= 5u) return;
    uint scroll = (uint)clamp(round(IniParams[68].x), 0.0f, 123.0f);
    uint row = scroll + id.x;
    DisplayRows[id.x] = (float)ROW_CAPACITY;
    DisplayCodes[id.x] = 0.0f;
    if (row < ROW_CAPACITY && KeybindRegistry[row] != 0u)
    {
        DisplayRows[id.x] = (float)row;
        DisplayCodes[id.x] = (float)clamp(round(KeybindDescriptors[row * 4u + 2u]), 0.0f, 36.0f);
    }
}
