RWBuffer<uint> StringData       : register(u0);
RWBuffer<uint> StringCount   : register(u1);
RWBuffer<float4> Debug   : register(u2);


Texture1D<float4> IniParams  : register(t120);

[numthreads(1,1,1)]
void main(uint3 tid : SV_DispatchThreadID)
{
    uint code = (uint)IniParams[26].x;
    uint ascii = 0;
    Debug[18] = float4(code, 69, 69, 69);
    // Special handling
    if (code == 54) { // Backspace
        if (StringCount[0] > 0) {
            StringData[StringCount[0]-1] = 0;
            InterlockedAdd(StringCount[0], -1);
        }
        return;
    }
    else if (code == 78) {
        // Shift+Enter = NewLine
        ascii = '\n'; // ASCII 10
    }
    else {
        // Map normal keys → ASCII
        switch(code) {
            case 2:   ascii = ' '; break;
            case 10:  ascii = 'a'; break;
            case 11:  ascii = 'b'; break;
            case 12:  ascii = 'c'; break;
            case 13:  ascii = 'd'; break;
            case 14:  ascii = 'e'; break;
            case 15:  ascii = 'f'; break;
            case 16:  ascii = 'g'; break;
            case 17:  ascii = 'h'; break;
            case 18:  ascii = 'i'; break;
            case 19:  ascii = 'j'; break;
            case 20:  ascii = 'k'; break;
            case 21:  ascii = 'l'; break;
            case 22:  ascii = 'm'; break;
            case 23:  ascii = 'n'; break;
            case 24:  ascii = 'o'; break;
            case 25:  ascii = 'p'; break;
            case 26:  ascii = 'q'; break;
            case 27:  ascii = 'r'; break;
            case 28:  ascii = 's'; break;
            case 29:  ascii = 't'; break;
            case 30:  ascii = 'u'; break;
            case 31:  ascii = 'v'; break;
            case 32:  ascii = 'w'; break;
            case 33:  ascii = 'x'; break;
            case 34:  ascii = 'y'; break;
            case 35:  ascii = 'z'; break;
        
            case 40:  ascii = '0'; break;
            case 41:  ascii = '1'; break;
            case 42:  ascii = '2'; break;
            case 43:  ascii = '3'; break;
            case 44:  ascii = '4'; break;
            case 45:  ascii = '5'; break;
            case 46:  ascii = '6'; break;
            case 47:  ascii = '7'; break;
            case 48:  ascii = '8'; break;
            case 49:  ascii = '9'; break;
        
            case 54:  /* Backspace handled separately */ break;
            case 57:  ascii = '\t'; break; // Tab
            case 78:  ascii = '\n'; break; // Shift+Enter / NewLine
        
            case 79:  ascii = 'A'; break;
            case 80:  ascii = 'B'; break;
            case 81:  ascii = 'C'; break;
            case 82:  ascii = 'D'; break;
            case 83:  ascii = 'E'; break;
            case 84:  ascii = 'F'; break;
            case 85:  ascii = 'G'; break;
            case 86:  ascii = 'H'; break;
            case 87:  ascii = 'I'; break;
            case 88:  ascii = 'J'; break;
            case 89:  ascii = 'K'; break;
            case 90:  ascii = 'L'; break;
            case 91:  ascii = 'M'; break;
            case 92:  ascii = 'N'; break;
            case 93:  ascii = 'O'; break;
            case 94:  ascii = 'P'; break;
            case 95:  ascii = 'Q'; break;
            case 96:  ascii = 'R'; break;
            case 97:  ascii = 'S'; break;
            case 98:  ascii = 'T'; break;
            case 99:  ascii = 'U'; break;
            case 100: ascii = 'V'; break;
            case 101: ascii = 'W'; break;
            case 102: ascii = 'X'; break;
            case 103: ascii = 'Y'; break;
            case 104: ascii = 'Z'; break;
        
            // Symbols / Shifted
            case 105: ascii = '!'; break;
            case 106: ascii = '"'; break;
            case 107: ascii = '#'; break;
            case 108: ascii = '$'; break;
            case 109: ascii = '%'; break;
            case 110: ascii = '&'; break;
            case 111: ascii = '\''; break;
            case 112: ascii = '('; break;
            case 113: ascii = ')'; break;
            case 114: ascii = '*'; break;
            case 115: ascii = '+'; break;
            case 116: ascii = ','; break;
            case 117: ascii = '-'; break;
            case 118: ascii = '.'; break;
            case 119: ascii = '/'; break;
            case 120: ascii = ':'; break;
            case 121: ascii = ';'; break;
            case 122: ascii = '<'; break;
            case 123: ascii = '='; break;
            case 124: ascii = '>'; break;
            case 125: ascii = '?'; break;
            case 126: ascii = '@'; break;
            case 127: ascii = '['; break;
            case 128: ascii = '\\'; break;
            case 129: ascii = ']'; break;
            case 130: ascii = '^'; break;
            case 131: ascii = '_'; break;
            case 132: ascii = '`'; break;
            case 133: ascii = '{'; break;
            case 134: ascii = '|'; break;
            case 135: ascii = '}'; break;
            case 136: ascii = '~'; break;
        }

    }

    // Append if valid character
    if (ascii > 1) {
        uint idx = StringCount[0];
        StringData[idx] = ascii;
        InterlockedAdd(StringCount[0], 1, idx);
        Debug[12] = float4(ascii, idx, 69, StringCount[0]);
    }
}