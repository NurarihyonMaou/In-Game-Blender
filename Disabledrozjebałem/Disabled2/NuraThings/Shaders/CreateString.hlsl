Texture1D<float4> IniParams                  : register(t120);
RWBuffer<uint>   StringData                  : register(u0);
RWBuffer<float4> Debug                       : register(u1);

Buffer<uint>     ModNameChars                : register(t121);
Buffer<uint>     ModNameOffsets              : register(t122);

Buffer<uint>     ModCounter                  : register(t123);
Buffer<uint>     ModToModelType              : register(t124);


Buffer<uint4>    BoundPairs                  : register(t119);
Buffer<uint>     BoundPairsCount             : register(t125);

Buffer<uint>     ResourceModelsIDs           : register(t118);
Buffer<uint>     ResourceModelsNamesList     : register(t126);
Buffer<uint>     ResourceModelsNamesOffsets  : register(t127);


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

    // Reverse digits
    for (int i = num_digits - 1; i >= 0; --i)
    {
        outBuffer[index++] = '0' + digits[i];
    }
}

void append_mod_name(uint localX, uint localY, inout uint index, RWBuffer<uint> outBuffer)
{
    uint modID = -1;

    uint totalMods = ModCounter[0];
    // guard in case ModCounter has garbage
    if (totalMods > 2048) 
        totalMods = 2048;
    
    uint TypeXCounter = 0;

    for (uint i = 0; i < totalMods; i++)
    {
        if (ModToModelType[i] != localX)
            continue;
        else{
            TypeXCounter += 1;

            if (TypeXCounter == localY)
                modID = i;
        }
    }

    if (modID == -1)
        return;

    uint offset = ModNameOffsets[modID];
    uint c;

    // Read and append characters until null (0) or max length
    [loop]
    for (uint k = 0; k < 64; k++)  // Assume max 64 chars per name
    {
        c = ModNameChars[offset + k];
        if (c == '\n') break;  // Null terminator
        outBuffer[index++] = c;
    }
}

uint gib_type_index(uint typeID){
    uint type_index = -1;

    for (uint ModelID = 0; ModelID < 256; ModelID++)
        if (ResourceModelsIDs[ModelID] == typeID){
            type_index = ModelID;
            break;
        }

    return type_index;
}

void append_type_name(uint typeID, inout uint index, RWBuffer<uint> outBuffer)
{
    uint type_index = gib_type_index(typeID);
    
    if(type_index == -1)
        return;

    uint offset = ResourceModelsNamesOffsets[type_index];
    uint c;

    [loop]
    for (uint k = 0; k < 64; ++k) // assume max 32 chars per type
    {
        c = ResourceModelsNamesList[offset + k];
        if (c == '\n') break; // null terminator
        outBuffer[index++] = c;
    }
}

void write_time(uint total_seconds, inout uint index, RWBuffer<uint> outBuffer)
{
    uint seconds = total_seconds % 60;
    uint minutes = (total_seconds / 60) % 60;
    uint hours   = (total_seconds / 3600) % 24;
    uint days    = total_seconds / 86400;

    if (days > 0)
    {
        write_digits(days, index, outBuffer); outBuffer[index++] = 'd'; outBuffer[index++] = ' ';
        write_digits(hours, index, outBuffer); outBuffer[index++] = 'h'; outBuffer[index++] = ' ';
        write_digits(minutes, index, outBuffer); outBuffer[index++] = 'm'; outBuffer[index++] = ' ';
        write_digits(seconds, index, outBuffer); outBuffer[index++] = 's';
    }
    else if (hours > 0)
    {
        write_digits(hours, index, outBuffer); outBuffer[index++] = 'h'; outBuffer[index++] = ' ';
        write_digits(minutes, index, outBuffer); outBuffer[index++] = 'm'; outBuffer[index++] = ' ';
        write_digits(seconds, index, outBuffer); outBuffer[index++] = 's';
    }
    else if (minutes > 0)
    {
        write_digits(minutes, index, outBuffer); outBuffer[index++] = 'm'; outBuffer[index++] = ' ';
        write_digits(seconds, index, outBuffer); outBuffer[index++] = 's';
    }
    else
    {
        write_digits(seconds, index, outBuffer); outBuffer[index++] = 's';
    }
}


[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint i = 0;
    uint STRING_TYPE = (uint)IniParams[67].z;

    int x = (int)IniParams[67].x; 
    int y = (int)IniParams[67].y;
    uint z = asuint(IniParams[68].x);
    uint w = asuint(IniParams[68].y);


    uint time = IniParams[67].x;
    uint last_session = IniParams[67].y;
    uint modded_objects_detections = IniParams[67].w;

    uint time_spent = IniParams[68].x;
    uint frames_ever = IniParams[68].y;

    uint random_mode_one_triggers = IniParams[68].z;
    uint random_mode_two_triggers = IniParams[68].w;
 
    uint menu_uses = IniParams[66].x;
    uint game_sessions = IniParams[66].y;
    uint reloads = IniParams[66].z;

    switch(STRING_TYPE){
        case 0:
            StringData[i++] = 'M';
            StringData[i++] = 'o';
            StringData[i++] = 'd';
            StringData[i++] = ' ';
            StringData[i++] = 'T';
            StringData[i++] = 'y';
            StringData[i++] = 'p';
            StringData[i++] = 'e';
            //StringData[i++] = ' ';
            //StringData[i++] = 'I';
            //StringData[i++] = 'D';
            StringData[i++] = ':';
            StringData[i++] = ' ';

            write_digits(x, i, StringData);
            StringData[i++] = '/';           
            write_digits(y, i, StringData);  
        break;

        case 1:        
            StringData[i++] = 'M';
            StringData[i++] = 'o';
            StringData[i++] = 'd';
            StringData[i++] = ' ';
            StringData[i++] = 'C';
            StringData[i++] = 'o';
            StringData[i++] = 'u';
            StringData[i++] = 'n';
            StringData[i++] = 't';
            StringData[i++] = ':';
            StringData[i++] = ' ';

            write_digits(x, i, StringData);
        break;

        case 2:
            StringData[i++] = 'R';
            StringData[i++] = 'M';
            StringData[i++] = 'o';
            StringData[i++] = 'd';
            StringData[i++] = 'e';
            StringData[i++] = ':';
            StringData[i++] = ' ';

            if (x == 0){
                StringData[i++] = 'O';
                StringData[i++] = 'f';
                StringData[i++] = 'f';
            }

            if (x == 1){
                StringData[i++] = 'E';
                StringData[i++] = 'v';
                StringData[i++] = 'e';
                StringData[i++] = 'r';
                StringData[i++] = 'y';
                StringData[i++] = ' ';
                StringData[i++] = 'S';
                StringData[i++] = 'w';
                StringData[i++] = 'a';
                StringData[i++] = 'p';
            }


            if (x == 2){
                StringData[i++] = 'F';
                StringData[i++] = 'i';
                StringData[i++] = 'r';
                StringData[i++] = 's';
                StringData[i++] = 't';
                StringData[i++] = ' ';
                StringData[i++] = 'L';
                StringData[i++] = 'o';
                StringData[i++] = 'a';
                StringData[i++] = 'd';
            }

        break;

        case 3:

            if (x == -1 || y == -1){
                StringData[i++] = 'I';
                StringData[i++] = 'n';
                StringData[i++] = 'c';
                StringData[i++] = 'o';
                StringData[i++] = 'r';
                StringData[i++] = 'r';
                StringData[i++] = 'e';
                StringData[i++] = 'c';
                StringData[i++] = 't';
                StringData[i++] = ' ';
                StringData[i++] = 'M';
                StringData[i++] = 'o';
                StringData[i++] = 'd';
                StringData[i++] = ' ';
                StringData[i++] = 'I';
                StringData[i++] = 'D';
                return;
            }
            if (x > 0 && z > 0){
                StringData[i++] = 'B';
                StringData[i++] = 'i';
                StringData[i++] = 'n';
                StringData[i++] = 'd';
                StringData[i++] = ' ';
                append_mod_name(z, x, i, StringData);
            }
            if (y > 0 && w > 0){
                StringData[i++] = ' ';
                StringData[i++] = 't';
                StringData[i++] = 'o';
                StringData[i++] = ' ';
                append_mod_name(w, y, i, StringData);
            }

        break;

        case 4:
                StringData[i++] = 'F';
                StringData[i++] = 'P';
                StringData[i++] = 'S';
                StringData[i++] = ':';
                StringData[i++] = ' ';
                write_digits(x, i, StringData);
        break;

        case 5:
                StringData[i++] = 'T';
                StringData[i++] = 'y';
                StringData[i++] = 'p';
                StringData[i++] = 'e';
                StringData[i++] = 's';
                StringData[i++] = ':';
                StringData[i++] = ' ';
                write_digits(y, i, StringData);
                StringData[i++] = ' ';
                StringData[i++] = 'M';
                StringData[i++] = 'o';
                StringData[i++] = 'd';
                StringData[i++] = 's';
                StringData[i++] = ':';
                StringData[i++] = ' ';
                write_digits(x, i, StringData);
        break;

        case 6:
            if (x == 0){
                StringData[i++] = 'C';
                StringData[i++] = 'l';
                StringData[i++] = 'i';
                StringData[i++] = 'c';
                StringData[i++] = 'k';
                StringData[i++] = ' ';
                StringData[i++] = 'T';
                StringData[i++] = 'y';
                StringData[i++] = 'p';
                StringData[i++] = 'e';
                StringData[i++] = ' ';
                StringData[i++] = 't';
                StringData[i++] = 'o';
                StringData[i++] = ' ';
                StringData[i++] = 'C';
                StringData[i++] = 'h';
                StringData[i++] = 'e';
                StringData[i++] = 'c';
                StringData[i++] = 'k';
                StringData[i++] = ' ';
                StringData[i++] = 'M';
                StringData[i++] = 'o';
                StringData[i++] = 'd';
                StringData[i++] = 's';
            }
            else{
                StringData[i++] = 'C';
                StringData[i++] = 'l';
                StringData[i++] = 'i';
                StringData[i++] = 'c';
                StringData[i++] = 'k';
                StringData[i++] = ' ';
                StringData[i++] = 't';
                StringData[i++] = 'o';
                StringData[i++] = ' ';
                StringData[i++] = 'S';
                StringData[i++] = 'e';
                StringData[i++] = 'l';
                StringData[i++] = 'e';
                StringData[i++] = 'c';
                StringData[i++] = 't';
                StringData[i++] = ' ';
                StringData[i++] = 'M';
                StringData[i++] = 'o';
                StringData[i++] = 'd';
                StringData[i++] = 's';
            }

        break;

        case 7: // Render all Bound Pairs as "(TypeName) ModName - (TypeName) ModName" array
        {
            uint totalPairs = BoundPairsCount[0]; // total number of bound pairs

            for (uint pairIndex = 0; pairIndex < totalPairs; pairIndex++)
            {
                uint4 pair = BoundPairs[pairIndex];
                float typeA = pair.x;
                uint idxA  = pair.y;
                float typeB = pair.z;
                uint idxB  = pair.w;

                // --- Left side ---
                StringData[i++] = '(';
                append_type_name(asuint(typeA), i, StringData);
                StringData[i++] = ')';
                StringData[i++] = ' ';
                append_mod_name(asuint(typeA), idxA, i, StringData);

                // Separator
                StringData[i++] = ' ';
                StringData[i++] = '-';
                StringData[i++] = ' ';

                // --- Right side ---
                StringData[i++] = '(';
                append_type_name(asuint(typeB), i, StringData);
                StringData[i++] = ')';
                StringData[i++] = ' ';
                append_mod_name(asuint(typeB), idxB, i, StringData);

                // Add newline between pairs
                StringData[i++] = '\n';
            }

            // If no pairs, fallback message
            if (totalPairs == 0)
            {
                StringData[i++] = 'N';
                StringData[i++] = 'o';
                StringData[i++] = ' ';
                StringData[i++] = 'P';
                StringData[i++] = 'a';
                StringData[i++] = 'i';
                StringData[i++] = 'r';
                StringData[i++] = '\n';
            }
        }
        break;

        case 8:
        {
            // Current Session:
            StringData[i++] = 'C';
            StringData[i++] = 'u';
            StringData[i++] = 'r';
            StringData[i++] = 'r';
            StringData[i++] = 'e';
            StringData[i++] = 'n';
            StringData[i++] = 't';
            StringData[i++] = ' ';
            StringData[i++] = 'S';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = 's';
            StringData[i++] = 'i';
            StringData[i++] = 'o';
            StringData[i++] = 'n';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_time((uint)time, i, StringData);
            StringData[i++] = '\n';

            // Last Session:
            StringData[i++] = 'L';
            StringData[i++] = 'a';
            StringData[i++] = 's';
            StringData[i++] = 't';
            StringData[i++] = ' ';
            StringData[i++] = 'S';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = 's';
            StringData[i++] = 'i';
            StringData[i++] = 'o';
            StringData[i++] = 'n';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_time((uint)last_session, i, StringData);
            StringData[i++] = '\n';

            // Time Spent:
            StringData[i++] = 'T';
            StringData[i++] = 'i';
            StringData[i++] = 'm';
            StringData[i++] = 'e';
            StringData[i++] = ' ';
            StringData[i++] = 'S';
            StringData[i++] = 'p';
            StringData[i++] = 'e';
            StringData[i++] = 'n';
            StringData[i++] = 't';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_time((uint)time_spent, i, StringData);
            StringData[i++] = '\n';
            StringData[i++] = '\n';


            // Max FPS:
            StringData[i++] = 'H';
            StringData[i++] = 'i';
            StringData[i++] = 'g';
            StringData[i++] = 'h';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = 't';
            StringData[i++] = ' ';
            StringData[i++] = 'F';
            StringData[i++] = 'P';
            StringData[i++] = 'S';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)IniParams[65].x, i, StringData);
            StringData[i++] = '\n';

            // Lowest FPS:
            StringData[i++] = 'L';
            StringData[i++] = 'o';
            StringData[i++] = 'w';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = 't';
            StringData[i++] = ' ';
            StringData[i++] = 'F';
            StringData[i++] = 'P';
            StringData[i++] = 'S';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)IniParams[65].y, i, StringData);
            StringData[i++] = '\n';

            // Frames:
            StringData[i++] = 'F';
            StringData[i++] = 'r';
            StringData[i++] = 'a';
            StringData[i++] = 'm';
            StringData[i++] = 'e';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)frames_ever, i, StringData);
            StringData[i++] = '\n';


            // Modded Objects Detected X Times:
            StringData[i++] = 'M';
            StringData[i++] = 'o';
            StringData[i++] = 'd';
            StringData[i++] = 'd';
            StringData[i++] = 'e';
            StringData[i++] = 'd';
            StringData[i++] = ' ';
            StringData[i++] = 'O';
            StringData[i++] = 'b';
            StringData[i++] = 'j';
            StringData[i++] = 'e';
            StringData[i++] = 'c';
            StringData[i++] = 't';
            StringData[i++] = 's';
            StringData[i++] = ' ';
            StringData[i++] = 'D';
            StringData[i++] = 'e';
            StringData[i++] = 't';
            StringData[i++] = 'e';
            StringData[i++] = 'c';
            StringData[i++] = 't';
            StringData[i++] = 'e';
            StringData[i++] = 'd';
            StringData[i++] = ' ';
            write_digits((uint)modded_objects_detections, i, StringData);
            StringData[i++] = ' ';
            StringData[i++] = 'T';
            StringData[i++] = 'i';
            StringData[i++] = 'm';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = '\n';
            StringData[i++] = '\n';


            // R1:
            StringData[i++] = 'R';
            StringData[i++] = 'M';
            StringData[i++] = 'o';
            StringData[i++] = 'd';
            StringData[i++] = 'e';
            StringData[i++] = '1';
            StringData[i++] = ' ';
            StringData[i++] = 'T';
            StringData[i++] = 'r';
            StringData[i++] = 'i';
            StringData[i++] = 'g';
            StringData[i++] = 'g';
            StringData[i++] = 'e';
            StringData[i++] = 'r';
            StringData[i++] = 's';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)random_mode_one_triggers, i, StringData);
            StringData[i++] = '\n';

            // R2:
            StringData[i++] = 'R';
            StringData[i++] = 'M';
            StringData[i++] = 'o';
            StringData[i++] = 'd';
            StringData[i++] = 'e';
            StringData[i++] = '2';
            StringData[i++] = ' ';
            StringData[i++] = 'T';
            StringData[i++] = 'r';
            StringData[i++] = 'i';
            StringData[i++] = 'g';
            StringData[i++] = 'g';
            StringData[i++] = 'e';
            StringData[i++] = 'r';
            StringData[i++] = 's';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)random_mode_two_triggers, i, StringData);
            StringData[i++] = '\n';
            StringData[i++] = '\n';
            
            // Menu:
            StringData[i++] = 'M';
            StringData[i++] = 'e';
            StringData[i++] = 'n';
            StringData[i++] = 'u';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)menu_uses, i, StringData);
            StringData[i++] = '\n';

            // Sessions:
            StringData[i++] = 'S';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = 's';
            StringData[i++] = 'i';
            StringData[i++] = 'o';
            StringData[i++] = 'n';
            StringData[i++] = 's';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)game_sessions, i, StringData);
            StringData[i++] = '\n';

            // Reloads:
            StringData[i++] = 'R';
            StringData[i++] = 'e';
            StringData[i++] = 'l';
            StringData[i++] = 'o';
            StringData[i++] = 'a';
            StringData[i++] = 'd';
            StringData[i++] = 's';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits((uint)reloads, i, StringData);
            StringData[i++] = '\n';

        }
        break;

        case 9:
        {
            StringData[i++] = 'F';
            StringData[i++] = 'P';
            StringData[i++] = 'S';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_digits(y, i, StringData);
            StringData[i++] = ' ';

            // Current Session:
            StringData[i++] = 'C';
            StringData[i++] = 'u';
            StringData[i++] = 'r';
            StringData[i++] = 'r';
            StringData[i++] = 'e';
            StringData[i++] = 'n';
            StringData[i++] = 't';
            StringData[i++] = ' ';
            StringData[i++] = 'S';
            StringData[i++] = 'e';
            StringData[i++] = 's';
            StringData[i++] = 's';
            StringData[i++] = 'i';
            StringData[i++] = 'o';
            StringData[i++] = 'n';
            StringData[i++] = ':';
            StringData[i++] = ' ';
            write_time((uint)time, i, StringData);
        }
        break;

    }

    //for(int k = 0; k < 64; k++)
    //    Debug[k] = float4(asfloat(ModToModelType[z]), float(i), float(z), float(w));
}