// Input
Buffer<uint> InputString : register(t0); // 48 characters max
RWBuffer<float4> Debug : register(u1);   // Debug info
RWBuffer<float2> Layout : register(u0);  // Output: (xOffset, line)

static const float GlyphWidths[26] = {
    0.153320,
    0.129883,
    0.138672,
    0.148438,

    0.116211,
    0.109375,
    0.148203,
    0.163086,

    0.068359,
    0.098633,
    0.154297,
    0.121094,

    0.189453,
    0.157227,
    0.145508,
    0.125977,

    0.149180,
    0.146484,
    0.102539,
    0.142578,

    0.155273,
    0.140625,
    0.203867,
    0.157227,

    0.126953,
    0.124023
};

float GetKerning(uint prev, uint curr)
{
    if (prev == 'A')
    {
        if (curr == 'V' || curr == 'W' || curr == 'Y') return -0.03;
        if (curr == 'T') return -0.02;
        if (curr == 'G') return -0.01;
    }
    else if (prev == 'L')
    {
        if (curr == 'T') return -0.015;
    }
    else if (prev == 'T')
    {
        if (curr == 'A') return -0.02;
        if (curr == 'O') return -0.01;
    }
    else if (prev == 'V')
    {
        if (curr == 'A') return -0.02;
    }

    else if (prev == 'W')
    {
        if (curr == 'A') return -0.02;
    }

    else if (prev == 'Y')
    {
        if (curr == 'A') return -0.04;
    }

    else if (prev == 'R')
    {
        if (curr == 'Q') return -0.01;
    }

    return 0.0;
}

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    float xOffset = 0.0;
    float row = 0;
    uint prevChar = 0;

    for (uint i = 0; i < 48; i++)
    {
        uint ch = InputString[i];

        if (ch == 1) {
            // Newline
            row -= 0.15;
            xOffset = 0.0;
            prevChar = 0;
            Layout[i] = float2(-1.0, -1.0); // Mark as hidden
            Debug[i] = float4(row, xOffset, ch, -1);
            continue;
        }

        // Skip unsupported/empty
        if (ch > 36 || ch < 10) {
            Layout[i] = float2(xOffset, row);
            Debug[i] = float4(row, xOffset, ch, -2); // unsupported char
            xOffset += 0.05; // fallback spacing
            prevChar = ch;
            continue;
        }

        // A-Z → width lookup (A=65)
        float width = GlyphWidths[ch - 10];

        // Apply kerning if possible
        float kern = GetKerning(prevChar, ch + 55);

        // Store layout
        Layout[i] = float2(xOffset + kern, row);
        Debug[i] = float4(row, xOffset, ch, kern);

        // Advance
       // if (ch == 32)
       //     xOffset += width - 0.01; // +0.01 = spacing between letters
       // else
        xOffset += width + kern; // +0.01 = spacing between letters
        prevChar = ch + 55;
    }
}