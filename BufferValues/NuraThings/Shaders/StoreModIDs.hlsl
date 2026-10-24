RWBuffer<float> ModIDs : register(u0);
RWBuffer<float> ModID : register(u1);
RWBuffer<bool> ReAssignedIDs : register(u2);
Texture1D<float4> IniParams : register(t120);

#define MOD_ID IniParams[98].x
#define RESET_IDs IniParams[98].y
#define MOD_INDEX IniParams[98].z
//#define GET_RANDOM_ID IniParams[98].w
#define G_TIME IniParams[99].x 
#define G_FRAME IniParams[99].y 

//int get_random_id(int maxIndex) {
//    float seed = G_TIME + G_FRAME; 
//    float randomValue = frac(sin(seed) * 43758.5453123);
//    return lerp(0, maxIndex, randomValue); // Scale to range [minVal, maxVal]
//}

[numthreads(1,1,1)]
void main(uint3 ThreadId : SV_DispatchThreadID) {
    bool isInArray = false;
    int emptySpot = -1;

    if (RESET_IDs == 1) {
        //for (int i = 0; i < 128; i++) // Renamed 'id' to 'i'
        //    ModIDs[i] = 0;

        ModID[0] = 0;

        //return;
    }

    if (RESET_IDs == 2) {
        int writeIndex = 0;
        int targetValue = ModIDs[(int)MOD_INDEX]; // Capture the value at MOD_INDEX before reassignment

        // Compact the array
        for (int i = 0; i < 256; i++) { // Renamed 'id' to 'i'
            if (ModIDs[i] != 0) {
                ModIDs[writeIndex] = ModIDs[i];
                writeIndex++;
            }
        }

        // Fill the remaining slots with zeros
        for (int j = writeIndex; j < 256; j++) { // Renamed 'id' to 'j'
            ModIDs[j] = 0;
        }

        // Find the new index of the captured value
        int newIndex = -1;
        for (int k = 0; k < writeIndex; k++) { // Renamed 'id' to 'k'
            if (ModIDs[k] == targetValue) {
                newIndex = k;
                break;
            }
        }

        // Use the new index to return the value
        if (newIndex != -1) {
            ModID[0] = ModIDs[newIndex];
        } else {
            ModID[0] = 0; // Default to 0 if the value is no longer present
        }

        ReAssignedIDs[0] = 1;
        return;
    }

    for (int m = 0; m < 256; m++) { // Renamed 'id' to 'm'
        if (emptySpot == -1 && ModIDs[m] == 0)
            emptySpot = m;

        if (MOD_ID != 0 && ModIDs[m] == MOD_ID) {
            isInArray = true;
        }
    }

    if (!isInArray && emptySpot != -1){
        ModIDs[emptySpot] = MOD_ID;
    }

    //if(GET_RANDOM_ID){
    //    ModID[0] = ModIDs[get_random_id(emptySpot)];
    //}
    //else
    //    ModID[0] = ModIDs[MOD_INDEX];
}