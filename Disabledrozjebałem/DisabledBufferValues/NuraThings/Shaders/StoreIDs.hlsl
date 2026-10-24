RWBuffer<float> ModelIDs : register(u0);
RWBuffer<float> ModelID : register(u1);
RWBuffer<float4> Debug : register(u2);

Buffer<uint> ModelNames : register(t0);        // Output[] from above
Buffer<uint> UsedIDs : register(t1);           // model_id list
Buffer<uint> NameOffsets : register(t2); 
RWBuffer<uint> ActiveModelNames : register(u3); // Output target (64 chars per model)

Texture1D<float4> IniParams : register(t120);
#define MODEL_ID IniParams[98].x
#define RESET_IDs IniParams[98].y
#define INDEX IniParams[98].z
#define PRESERVE_ID IniParams[98].w

[numthreads(1,1,1)]
void main(uint3 ThreadId : SV_DispatchThreadID)
{
    bool isInArray = false;
    int emptySpot = -1;
    int mod_types_count = 0;

    if (RESET_IDs) {
        ModelID[2] = ModelID[0];
        ModelID[1] = 0;
    }

    // Insert MODEL_ID
    for (int id = 0; id < 64; id++) {
        if (emptySpot == -1 && ModelIDs[id] == 0) emptySpot = id;
        if (MODEL_ID != 0 && ModelIDs[id] == MODEL_ID) {
            isInArray = true;
            break;
        }
    }

    if (!isInArray && emptySpot != -1) {
        ModelIDs[emptySpot] = MODEL_ID;
        int i = emptySpot;
        while (i > 0 && ModelIDs[i - 1] > ModelIDs[i] && ModelIDs[i - 1] != 0) {
            float tmp = ModelIDs[i];
            ModelIDs[i] = ModelIDs[i - 1];
            ModelIDs[i - 1] = tmp;
            i--;
        }
    }

    // Count
    for (int i = 63; i >= 0; i--) {
        if (ModelIDs[i] != 0) {
            mod_types_count = i + 1;
            break;
        }
    }

    int oldID = ModelID[2];
    bool ID_Set = false;

    if (PRESERVE_ID == 1 && oldID != 0) {
        for (int i = 0; i < 64; i++) {
            if (oldID == ModelIDs[i]) {
                ID_Set = true;
                break;
            }
        }
    }

    if (PRESERVE_ID == 0) {
        ModelID[0] = ModelIDs[INDEX];
        ModelID[2] = ModelID[0];
    } else {
        ModelID[0] = ID_Set ? ModelID[2] : ModelIDs[INDEX];
    }

    ModelID[1] = mod_types_count;

    // ⬇️ Copy active model names
// pointer into the ActiveModelNames char buffer:
    uint writePos = 0;

    for (int x = 0; x < 64; x++) {
        uint id = asuint(ModelIDs[x]);
        if (id == 0) break;

        // find slot in UsedIDs[]
        int entry = -1;
        for (int j = 0; j < 256; j++) {
            if (UsedIDs[j] == id) {
                entry = j;
                break;
            }
        }
        if (entry < 0) continue;

        // read its start offset in NameChars[]
        uint baseIdx = NameOffsets[entry];

        // copy until '\n'
        for (uint c = baseIdx; ; c++) {
            uint ch = ModelNames[c];                // ← use NameChars[], not ModelNames[]
            ActiveModelNames[writePos++] = ch;
            if (ch == '\n') 
                break;
        }
    }
    Debug[0] = float4(ModelIDs[0], asfloat(UsedIDs[0]), NameOffsets[0], ModelNames[0]);
    Debug[2] = float4(ActiveModelNames[0], ActiveModelNames[1], ActiveModelNames[2], ActiveModelNames[3]);
}