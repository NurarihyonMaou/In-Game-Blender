Texture1D<float4> IniParams : register(t120);
RWBuffer<uint> StringData : register(u0);

void write_digits(uint number, inout uint index, RWBuffer<uint> outBuffer)
{
    if (number == 0)
    {
        outBuffer[index++] = '0';
        return;
    }

    uint digits[10];
    uint num_digits = 0;

    while (number > 0)
    {
        digits[num_digits++] = number % 10;
        number /= 10;
    }

    for (int i = num_digits - 1; i >= 0; --i)
        outBuffer[index++] = '0' + digits[i];
}

void write_float(float value, uint decimals, inout uint index, RWBuffer<uint> outBuffer)
{
    if (value < 0.0f)
    {
        outBuffer[index++] = '-';
        value = -value;
    }

    uint intPart = (uint)value;
    float frac = value - (float)intPart;

    if (decimals == 0)
    {
        write_digits(intPart, index, outBuffer);
        return;
    }

    uint scale = (uint)pow(10.0f, (float)decimals);
    uint fracPart = (uint)round(frac * scale);

    if (fracPart >= scale)
    {
        intPart += 1;
        fracPart = 0;
    }

    write_digits(intPart, index, outBuffer);
    outBuffer[index++] = '.';

    uint temp = fracPart;
    uint len = 0;

    if (temp == 0)
        len = 1;

    while (temp > 0)
    {
        temp /= 10;
        len++;
    }

    for (uint k = 0; k < decimals - len; k++)
        outBuffer[index++] = '0';

    write_digits(fracPart, index, outBuffer);
}

[numthreads(1, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
    uint index = 0;
    float value = IniParams[67].x;
    uint decimals = (uint)max(IniParams[67].y, 0.0f);

    write_float(value, decimals, index, StringData);

    StringData[index] = 0;
}