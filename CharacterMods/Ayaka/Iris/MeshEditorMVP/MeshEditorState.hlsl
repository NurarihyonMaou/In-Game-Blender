// ============================================================================
// MeshEditorState.hlsl
// ============================================================================

Texture1D<float4> IniParams : register(t120);
Buffer<float4> HoverResult : register(t0);
RWBuffer<float4> EditorState : register(u0);

#define CURSOR IniParams[31]
#define HOLD IniParams[32].x
#define PROPORTIONAL_RADIUS IniParams[33].x

#define STATE_PREV_CURSOR 8
#define STATE_BRUSH_TRI 9
#define STATE_BRUSH_BARY 10
#define STATE_BRUSH_POS 11
#define STATE_EVENTS 12
#define STATE_PRESSED 13
#define STATE_RELEASED 14

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    float4 s0 = EditorState[0];
    float4 s1 = EditorState[1];
    float4 s2 = EditorState[2];
    float4 s3 = EditorState[3];
    float4 s4 = EditorState[4];
    float4 s5 = EditorState[5];
    float4 s6 = EditorState[6];
    float4 s7 = EditorState[7];
    float4 s8 = EditorState[STATE_PREV_CURSOR];
    float4 s9 = EditorState[STATE_BRUSH_TRI];
    float4 s10 = EditorState[STATE_BRUSH_BARY];
    float4 s11 = EditorState[STATE_BRUSH_POS];
    float4 s12 = EditorState[STATE_EVENTS];
    float4 s13 = EditorState[STATE_PRESSED];
    float4 s14 = EditorState[STATE_RELEASED];

    float hold = HOLD > 0.5f ? 1.0f : 0.0f;
    float prevHold = s0.z > 0.5f ? 1.0f : 0.0f;

    bool pressed = hold > 0.5f && prevHold <= 0.5f;
    bool released = hold <= 0.5f && prevHold > 0.5f;

    bool hoverValid = HoverResult[0].x > 0.5f;
    bool hoverSurfaceValid = HoverResult[5].w > 0.5f && HoverResult[6].w > 0.0f;

    float selectedVertex = s0.x;
    bool selectedValid = s0.y > 0.5f;

    s5.w = 0.0f;
    s6 = float4(max(PROPORTIONAL_RADIUS, 0.0f), 0.0f, 0.0f, 0.0f);
    s12 = float4(0.0f, 0.0f, hold, 0.0f);
    s13 = 0.0f;
    s14 = 0.0f;

    if (pressed)
    {
        if (hoverValid && hoverSurfaceValid)
        {
            selectedVertex = HoverResult[7].x;
            selectedValid = selectedVertex >= 0.0f;

            if (selectedValid)
            {
                s1.xy = CURSOR.xy;
                s8.xy = CURSOR.xy;

                s2.xyz = HoverResult[5].xyz;
                s2.w = HoverResult[5].w;

                s3.xyz = HoverResult[6].xyz;
                s3.w = HoverResult[6].w;

                s4.xyz = 0.0f;
                s4.w = 1.0f;

                s9 = HoverResult[2];
                s10 = HoverResult[3];
                s11 = HoverResult[1];

                s12.x = 1.0f;
                s13.x = 1.0f;
            }
        }
        else
        {
            selectedVertex = -1.0f;
            selectedValid = false;

            s1 = 0.0f;
            s2 = 0.0f;
            s3 = 0.0f;
            s4 = 0.0f;
            s8 = 0.0f;
            s9 = 0.0f;
            s10 = 0.0f;
            s11 = 0.0f;
        }
    }

    if (selectedValid && (hold > 0.5f || released))
    {
        if (hold > 0.5f)
        {
            s7.xy = CURSOR.xy - s8.xy;
            s8.xy = CURSOR.xy;

            float2 totalDeltaPx = CURSOR.xy - s1.xy;
            s4.xyz = s2.xyz * totalDeltaPx.x - s3.xyz * totalDeltaPx.y; // Screen Y is inverted relative to the local drag basis.

            if (hoverValid && hoverSurfaceValid)
            {
                s9 = HoverResult[2];
                s10 = HoverResult[3];
                s11 = HoverResult[1];
            }
            else
            {
                s11 = float4(0.0f, 0.0f, 0.0f, 0.0f);
            }
        }
        else
        {
            s7.xy = 0.0f;
        }

        s4.w = 1.0f;
    }
    else if (!hold)
    {
        s4.xyz = 0.0f;
        s4.w = 0.0f;
        s7.xy = 0.0f;
    }

    if (released && selectedValid)
    {
        s5.w = 1.0f;
        s12.y = 1.0f;
        s14.x = 1.0f;
    }

    s0.x = selectedVertex;
    s0.y = selectedValid ? 1.0f : 0.0f;
    s0.z = hold;
    s0.w = (hold > 0.5f && selectedValid) ? 1.0f : 0.0f;

    EditorState[0] = s0;
    EditorState[1] = s1;
    EditorState[2] = s2;
    EditorState[3] = s3;
    EditorState[4] = s4;
    EditorState[5] = s5;
    EditorState[6] = s6;
    EditorState[7] = s7;
    EditorState[STATE_PREV_CURSOR] = s8;
    EditorState[STATE_BRUSH_TRI] = s9;
    EditorState[STATE_BRUSH_BARY] = s10;
    EditorState[STATE_BRUSH_POS] = s11;
    EditorState[STATE_EVENTS] = s12;
    EditorState[STATE_PRESSED] = s13;
    EditorState[STATE_RELEASED] = s14;
}