// Module-owned hotkey can select its registered slot and open the generic module view.
RWBuffer<float> UIState : register(u0);
Texture1D<float4> IniParams : register(t120);
[numthreads(1,1,1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint moduleSlot = (uint)clamp(round(IniParams[68].x), 0.0f, 31.0f);
    UIState[0] = 7.0f;
    UIState[4] = 0.0f;
    UIState[55] = (float)(moduleSlot + 1u);
    UIState[56] = 0.0f;
}
