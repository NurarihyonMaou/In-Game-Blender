RWBuffer<float> ModelIDs : register(u0);
RWBuffer<float> ModelID : register(u1);
Texture1D<float4> IniParams : register(t120);

#define MODEL_ID IniParams[98].x
#define RESET_IDs IniParams[98].y
#define INDEX IniParams[98].z

[numthreads(1,1,1)]
void main(uint3 ThreadId : SV_DispatchThreadID){
    bool isInArray = false;
    int emptySpot = -1;
    int mod_types_count = 0;

    if(RESET_IDs){
        for (int id = 0; id < 64; id++)
            ModelIDs[id] = 0;

        ModelID[0] = 0;
        ModelID[1] = 0;
        
        return;
    }

    // Step 1: Check if MODEL_ID already exists and find an empty spot.
    for(int id = 0; id < 64; id++){
        if(emptySpot == -1 && ModelIDs[id] == 0)
            emptySpot = id;

        if(MODEL_ID != 0 && ModelIDs[id] == MODEL_ID){
            isInArray = true;
            break;
        }
    }

    // Step 2: Insert MODEL_ID if it's not already in the array.
    if(!isInArray && emptySpot != -1){
        ModelIDs[emptySpot] = MODEL_ID;

        // Step 3: Perform Insertion Sort on the modified list
        int i = emptySpot;
        while (i > 0 && ModelIDs[i - 1] > ModelIDs[i] && ModelIDs[i - 1] != 0){
            // Swap ModelIDs[i] with ModelIDs[i - 1]
            float temp = ModelIDs[i];
            ModelIDs[i] = ModelIDs[i - 1];
            ModelIDs[i - 1] = temp;
            i--;
        }
    }

    // Step 4: Find the count of valid models in ModelIDs (non-zero entries)
    for (int types_count = 63; types_count >= 0; types_count--){
        if(ModelIDs[types_count] != 0){
            mod_types_count = types_count+1;
            break;
        }
    }

    // Step 5: Set the output values.
    ModelID[0] = ModelIDs[INDEX];
    ModelID[1] = mod_types_count;
}