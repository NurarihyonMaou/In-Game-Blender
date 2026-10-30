// Toggle one picked Vertex (mode 0), Face (mode 1), or Edge (mode 2).
// This shader is dispatched once per click; the small serial scan only searches
// the current selected-element list, not the full mesh.
Texture1D<float4> IniParams : register(t120);
RWBuffer<uint> SelectedVertices : register(u0); // one vertex ID per item
RWBuffer<uint> SelectedFaces : register(u1);    // three vertex IDs per item
RWBuffer<uint> SelectedEdges : register(u2);    // two vertex IDs per item
RWBuffer<uint> SelectedMeta : register(u3);      // [vertexCount, faceCount, edgeCount]
RWBuffer<uint> SelectedRefCount : register(u4); // incidence count per vertex

#define VERTEX_COUNT 79355u
#define MAX_FACE_COUNT 80284u
#define MAX_EDGE_COUNT 240852u

bool ValidVertex(uint v) { return v < VERTEX_COUNT; }

bool SameFace(uint a0, uint a1, uint a2, uint b0, uint b1, uint b2)
{
    return (a0 == b0 && a1 == b1 && a2 == b2) ||
           (a0 == b0 && a1 == b2 && a2 == b1) ||
           (a0 == b1 && a1 == b0 && a2 == b2) ||
           (a0 == b1 && a1 == b2 && a2 == b0) ||
           (a0 == b2 && a1 == b0 && a2 == b1) ||
           (a0 == b2 && a1 == b1 && a2 == b0);
}

void AddVertexRef(uint v)
{
    if (ValidVertex(v)) SelectedRefCount[v] = SelectedRefCount[v] + 1u;
}

void RemoveVertexRef(uint v)
{
    if (ValidVertex(v) && SelectedRefCount[v] > 0u)
        SelectedRefCount[v] = SelectedRefCount[v] - 1u;
}

[numthreads(1, 1, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    uint mode = (uint)max(round(IniParams[50].x), 0.0f);
    uint v0 = (uint)max(round(IniParams[51].x), 0.0f);
    uint v1 = (uint)max(round(IniParams[51].y), 0.0f);
    uint v2 = (uint)max(round(IniParams[51].z), 0.0f);

    if (mode == 0u)
    {
        if (!ValidVertex(v0)) return;
        uint count = min(SelectedMeta[0], VERTEX_COUNT);
        uint found = 0xffffffffu;
        [loop] for (uint i = 0u; i < count; ++i)
        {
            if (SelectedVertices[i] == v0) { found = i; break; }
        }
        if (found != 0xffffffffu)
        {
            uint last = count - 1u;
            if (found != last) SelectedVertices[found] = SelectedVertices[last];
            SelectedMeta[0] = last;
            RemoveVertexRef(v0);
        }
        else if (count < VERTEX_COUNT)
        {
            SelectedVertices[count] = v0;
            SelectedMeta[0] = count + 1u;
            AddVertexRef(v0);
        }
        return;
    }

    if (mode == 1u)
    {
        if (!ValidVertex(v0) || !ValidVertex(v1) || !ValidVertex(v2)) return;
        uint count = min(SelectedMeta[1], MAX_FACE_COUNT);
        uint found = 0xffffffffu;
        [loop] for (uint i = 0u; i < count; ++i)
        {
            uint base = i * 3u;
            if (SameFace(SelectedFaces[base], SelectedFaces[base + 1u], SelectedFaces[base + 2u], v0, v1, v2))
            { found = i; break; }
        }
        if (found != 0xffffffffu)
        {
            uint last = count - 1u;
            uint base = found * 3u;
            uint lastBase = last * 3u;
            uint a = SelectedFaces[base];
            uint b = SelectedFaces[base + 1u];
            uint c = SelectedFaces[base + 2u];
            if (found != last)
            {
                SelectedFaces[base] = SelectedFaces[lastBase];
                SelectedFaces[base + 1u] = SelectedFaces[lastBase + 1u];
                SelectedFaces[base + 2u] = SelectedFaces[lastBase + 2u];
            }
            SelectedMeta[1] = last;
            RemoveVertexRef(a); RemoveVertexRef(b); RemoveVertexRef(c);
        }
        else if (count < MAX_FACE_COUNT)
        {
            uint base = count * 3u;
            SelectedFaces[base] = v0;
            SelectedFaces[base + 1u] = v1;
            SelectedFaces[base + 2u] = v2;
            SelectedMeta[1] = count + 1u;
            AddVertexRef(v0); AddVertexRef(v1); AddVertexRef(v2);
        }
        return;
    }

    if (mode == 2u)
    {
        if (!ValidVertex(v0) || !ValidVertex(v1) || v0 == v1) return;
        uint count = min(SelectedMeta[2], MAX_EDGE_COUNT);
        uint found = 0xffffffffu;
        [loop] for (uint i = 0u; i < count; ++i)
        {
            uint base = i * 2u;
            uint a = SelectedEdges[base];
            uint b = SelectedEdges[base + 1u];
            if ((a == v0 && b == v1) || (a == v1 && b == v0)) { found = i; break; }
        }
        if (found != 0xffffffffu)
        {
            uint last = count - 1u;
            uint base = found * 2u;
            uint lastBase = last * 2u;
            uint a = SelectedEdges[base];
            uint b = SelectedEdges[base + 1u];
            if (found != last)
            {
                SelectedEdges[base] = SelectedEdges[lastBase];
                SelectedEdges[base + 1u] = SelectedEdges[lastBase + 1u];
            }
            SelectedMeta[2] = last;
            RemoveVertexRef(a); RemoveVertexRef(b);
        }
        else if (count < MAX_EDGE_COUNT)
        {
            uint base = count * 2u;
            SelectedEdges[base] = v0;
            SelectedEdges[base + 1u] = v1;
            SelectedMeta[2] = count + 1u;
            AddVertexRef(v0); AddVertexRef(v1);
        }
    }
}
