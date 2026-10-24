Texture1D<float4> IniParams : register(t120);

Buffer<float> HoverResult : register(t0);

RWBuffer<float> State : register(u0);

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    float hold = IniParams[32].x;
    float dt = IniParams[33].x;

    float stiffness = IniParams[34].z;
    float damping = IniParams[34].w;

    float maxDrag = IniParams[35].y;

    float3 currentOffset = float3(
        State[0],
        State[1],
        State[2]
    );

    float3 velocity = float3(
        State[3],
        State[4],
        State[5]
    );

    float3 targetOffset = float3(
        State[6],
        State[7],
        State[8]
    );

    float3 grabPoint = float3(
        State[9],
        State[10],
        State[11]
    );

    float3 previousHit = float3(
        State[12],
        State[13],
        State[14]
    );

    float previousHold = State[15];
    float grabbed = State[16];

    bool hoverValid =
        HoverResult[16] > 0.5;

    float3 currentHit = float3(
        HoverResult[20],
        HoverResult[21],
        HoverResult[22]
    );

    // ------------------------------------------------------------
    // Start grab
    // ------------------------------------------------------------

    if (hold > 0.5 &&
        previousHold <= 0.5)
    {
        if (hoverValid)
        {
            grabPoint = currentHit;
            previousHit = currentHit;

            targetOffset = 0.0;
            currentOffset = 0.0;
            velocity = 0.0;
            grabbed = 1.0;

            // Select closest vertex of hovered triangle
            float w0 = HoverResult[17];
            float w1 = HoverResult[18];
            float w2 = HoverResult[19];

            if (w0 >= w1 && w0 >= w2)
                State[17] = HoverResult[1];

            else if (w1 >= w0 && w1 >= w2)
                State[17] = HoverResult[2];

            else
                State[17] = HoverResult[3];
        }
        else
        {
            grabbed = 0.0;
        }
    }

    // ------------------------------------------------------------
    // Drag
    // ------------------------------------------------------------

    if (hold > 0.5 &&
        grabbed > 0.5 &&
        hoverValid)
    {
        float3 movement =
            currentHit - previousHit;

        targetOffset += movement;

        float amount =
            length(targetOffset);

        if (amount > maxDrag)
        {
            targetOffset *=
                maxDrag / amount;
        }

        previousHit = currentHit;
    }

    // ------------------------------------------------------------
    // Release
    // ------------------------------------------------------------

    if (hold <= 0.5)
    {
        grabbed = 0.0;
        targetOffset = 0.0;
    }

    // ------------------------------------------------------------
    // Spring
    // ------------------------------------------------------------

    float3 force =
        (targetOffset - currentOffset) * stiffness
        - velocity * damping;

    velocity += force * dt;
    currentOffset += velocity * dt;

    if (hold <= 0.5 &&
        length(currentOffset) < 0.00001 &&
        length(velocity) < 0.00001)
    {
        currentOffset = 0.0;
        velocity = 0.0;
    }

    // ------------------------------------------------------------
    // Store
    // ------------------------------------------------------------

    State[0] = currentOffset.x;
    State[1] = currentOffset.y;
    State[2] = currentOffset.z;

    State[3] = velocity.x;
    State[4] = velocity.y;
    State[5] = velocity.z;

    State[6] = targetOffset.x;
    State[7] = targetOffset.y;
    State[8] = targetOffset.z;

    State[9] = grabPoint.x;
    State[10] = grabPoint.y;
    State[11] = grabPoint.z;

    State[12] = previousHit.x;
    State[13] = previousHit.y;
    State[14] = previousHit.z;

    State[15] = hold;
    State[16] = grabbed;
}