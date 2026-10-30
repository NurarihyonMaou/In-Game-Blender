// Copies up to four registered key IDs into a module-owned persist-sync buffer.
Buffer<float> ModuleKeybindSlots : register(t0);
Buffer<uint> ModuleKeybindRegistry : register(t1);
Buffer<float> ModuleKeybindDescriptors : register(t2);
RWBuffer<float> ModuleKeybindValues : register(u0);
static const uint ROW_CAPACITY = 128u;
[numthreads(8, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    if (id.x >= 4u) return;
    uint row = (uint)max(round(ModuleKeybindSlots[id.x]), 0.0f);
    float value = 0.0f;
    if (row < ROW_CAPACITY && ModuleKeybindRegistry[row] != 0u)
        value = (float)clamp(round(ModuleKeybindDescriptors[row * 4u + 2u]), 0.0f, 36.0f);
    ModuleKeybindValues[id.x] = value;
}
