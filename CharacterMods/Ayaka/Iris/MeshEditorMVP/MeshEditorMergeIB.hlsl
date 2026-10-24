// MeshEditorMergeIB.hlsl
// Concatenates the three Ayaka index buffers into one triangle-aligned IB.
// All three IBs reference the same 79,355-vertex VB0, so the index values
// themselves are copied unchanged.

Buffer<uint> HeadIB  : register(t0);
Buffer<uint> BodyIB  : register(t1);
Buffer<uint> DressIB : register(t2);

RWBuffer<uint> CombinedIB : register(u0);

static const uint COMBINED_CAPACITY = 240852u;

[numthreads(128, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    const uint dst = id.x;
    if (dst >= COMBINED_CAPACITY)
        return;

    uint headCount;
    uint bodyCount;
    uint dressCount;

    HeadIB.GetDimensions(headCount);
    BodyIB.GetDimensions(bodyCount);
    DressIB.GetDimensions(dressCount);

    // Keep each IB's first index aligned to a triangle boundary.
    const uint headSpan  = ((headCount  + 2u) / 3u) * 3u;
    const uint bodySpan  = ((bodyCount  + 2u) / 3u) * 3u;
    const uint dressSpan = ((dressCount + 2u) / 3u) * 3u;

    if (dst < headCount)
    {
        CombinedIB[dst] = HeadIB[dst];
        return;
    }

    if (dst < headSpan)
    {
        CombinedIB[dst] = 0u;
        return;
    }

    const uint bodyStart = headSpan;
    if (dst < bodyStart + bodyCount)
    {
        CombinedIB[dst] = BodyIB[dst - bodyStart];
        return;
    }

    if (dst < bodyStart + bodySpan)
    {
        CombinedIB[dst] = 0u;
        return;
    }

    const uint dressStart = bodyStart + bodySpan;
    if (dst < dressStart + dressCount)
    {
        CombinedIB[dst] = DressIB[dst - dressStart];
        return;
    }

    if (dst < dressStart + dressSpan)
    {
        CombinedIB[dst] = 0u;
        return;
    }

    // Clear any unused tail in the allocated resource. Zeroes form only
    // degenerate triangles when the picker scans this tail.
    CombinedIB[dst] = 0u;
}
