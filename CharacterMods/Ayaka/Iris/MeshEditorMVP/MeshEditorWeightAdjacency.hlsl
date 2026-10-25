// Builds a bounded one-ring adjacency table from the merged triangle index buffer.
// t0: ResourceMeshEditorCombinedIB (R32_UINT, 240852 entries)
// u0: ResourceMeshEditorWeightAdjacency (R32_UINT, 79355 * 33 entries)
// IniParams[55].x: 0 = clear per-vertex counts, 1 = append triangle neighbors.

Buffer<uint> CombinedIB : register(t0);
RWBuffer<uint> Adjacency : register(u0);
Texture1D<float4> IniParams : register(t120);

#define VERTEX_COUNT 79355u
#define INDEX_COUNT 240852u
#define MAX_NEIGHBORS 32u
#define ADJACENCY_STRIDE (MAX_NEIGHBORS + 1u)

void AppendNeighbor(uint vertexID, uint neighborID)
{
    if (vertexID >= VERTEX_COUNT || neighborID >= VERTEX_COUNT || vertexID == neighborID)
        return;

    uint baseIndex = vertexID * ADJACENCY_STRIDE;
    uint slot;
    InterlockedAdd(Adjacency[baseIndex], 1u, slot);

    // Counts may exceed the storage cap on unusual high-valence vertices, but
    // the write is always bounds-checked and the consumer clamps the count.
    if (slot < MAX_NEIGHBORS)
        Adjacency[baseIndex + 1u + slot] = neighborID;
}

[numthreads(64, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint id = dispatchThreadID.x;

    if (IniParams[55].x < 0.5f)
    {
        if (id < VERTEX_COUNT)
            Adjacency[id * ADJACENCY_STRIDE] = 0u;
        return;
    }

    if (id >= INDEX_COUNT || (id % 3u) != 0u || id + 2u >= INDEX_COUNT)
        return;

    uint a = CombinedIB[id + 0u];
    uint b = CombinedIB[id + 1u];
    uint c = CombinedIB[id + 2u];

    if (a >= VERTEX_COUNT || b >= VERTEX_COUNT || c >= VERTEX_COUNT)
        return;

    AppendNeighbor(a, b);
    AppendNeighbor(a, c);
    AppendNeighbor(b, a);
    AppendNeighbor(b, c);
    AppendNeighbor(c, a);
    AppendNeighbor(c, b);
}
