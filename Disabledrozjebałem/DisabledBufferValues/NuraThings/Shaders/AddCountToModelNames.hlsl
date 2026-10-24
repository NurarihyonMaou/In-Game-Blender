// Input buffers
Buffer<uint> ResourceModelsNamesList       : register(t0);
Buffer<uint> ResourceModelsNamesListOffsets: register(t1);
RWBuffer<float> ModsPerTypeCount               : register(u3); // indexed by model_type_id
Buffer<uint> ModelTypeCount                 : register(t3); // [0] = total number of model types
Buffer<uint> ModelsNamesListCounter         : register(t4);
Buffer<uint> UsedIDs         : register(t5);
// Output buffer
RWBuffer<uint> ResourceModelsNamesWithCount : register(u0);
RWBuffer<uint> ResourceModelsNamesWithCountCounter : register(u1);
RWBuffer<float4> Debug : register(u2);
[numthreads(1,1,1)]
void main(uint3 id : SV_DispatchThreadID)
{

    uint inputLength = uint(ModelsNamesListCounter[0]);
    uint totalModels = uint(ModelTypeCount[0]);
    uint modelIndex = -1;
    uint modelType = 0;

    // For each char in input buffer
    for (uint i = 0; i < inputLength; i++)
    {
        uint c = ResourceModelsNamesList[i];

        if (c != 10) // not newline
        {
            // Append character atomically
            uint pos = 0;
            InterlockedAdd(ResourceModelsNamesWithCountCounter[0], 1, pos);
            ResourceModelsNamesWithCount[pos] = c;
        }
        else
        {
            modelIndex++;

            modelType = asfloat(UsedIDs[modelIndex]);

            uint count = uint(asfloat(ModsPerTypeCount[modelType]));

            // Convert count to digits
            uint digits[10];
            uint digitCount = 0;
            uint tmp = count;
            if (tmp == 0)
            {
                digits[digitCount++] = '0';
            }
            else
            {
                while (tmp > 0)
                {
                    digits[digitCount++] = '0' + (tmp % 10);
                    tmp /= 10;
                }
            }

            // Reserve space for ' ' + digits + '\n'
            uint reserveCount = 3 + digitCount + 1;
            uint pos = 0;
            InterlockedAdd(ResourceModelsNamesWithCountCounter[0], reserveCount, pos);

            // Write space
            ResourceModelsNamesWithCount[pos + 0] = ' ';
            ResourceModelsNamesWithCount[pos + 1] = '-';
            ResourceModelsNamesWithCount[pos + 2] = ' ';

            // Write digits in correct order
            for (int d = digitCount - 1; d >= 0; d--)
            {
                ResourceModelsNamesWithCount[pos + 3 + (digitCount - 1 - d)] = digits[d];
            }

            // Write newline
            ResourceModelsNamesWithCount[pos + 3 + digitCount] = 10;
        }
    }
    Debug[4] = float4(float(inputLength), float(totalModels), ModsPerTypeCount[8], asfloat(modelType));
}