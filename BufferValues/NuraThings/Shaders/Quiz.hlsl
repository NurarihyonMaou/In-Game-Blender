// QuizGenAnswers.hlsl (REWORKED for '|' separators and '~' correct marker)

Texture1D<float4> IniParams : register(t120);

// outputs
RWBuffer<uint> StringData           : register(u0); // R8_UINT char buffer for TextPrinter
RWBuffer<uint> GeneratedCorrectIdx  : register(u1); // one uint per question -> which choice (0..2) is correct
RWBuffer<float4> DebugBuf           : register(u2); // optional debug
RWBuffer<float> AnsweredBuf           : register(u3);

// question data
Buffer<uint> QuestionChars          : register(t121); // all question text packed, '|' terminators
Buffer<uint> QuestionPrefixOffsets  : register(t122); // offset into QuestionChars for prefix per question

// word bank data (multiple banks, each bank contains words separated by '|' and bank ends where next bank starts)
Buffer<uint> WordBankChars          : register(t126); // all words packed, '|' terminated within bank
Buffer<uint> WordBankOffsets        : register(t127); // start char offset per bank

#define INI_Q_STATE 78
#define INI_Q_META  79

int get_current_q() { return (int)IniParams[INI_Q_STATE].x; }
uint get_user_answer() { return (uint)IniParams[INI_Q_STATE].z; }
uint get_seed()      { return (uint)IniParams[INI_Q_STATE].y; }
int get_total_q()    { return (int)IniParams[INI_Q_META].x; }
int get_max_words()  { return (int)IniParams[INI_Q_META].y; }

// LCG
uint lcg(uint state) { return state * 1664525u + 1013904223u; }

// copy from QuestionChars until '|' or 0
void copy_string_from_questions(uint qcharOffset, inout uint outIdx)
{
    for(uint k = 0; ; ++k)
    {
        uint c = QuestionChars[qcharOffset + k];
        if (c == 0 || c == 124 /* '|' */) break;
        StringData[outIdx++] = c;
    }
}

// copy from WordBankChars starting at charOffset until '|' or 0
// If first char is '~' (126) then do NOT output it and set markedOut=1
// --- safer helpers for banks/words ---

// get WordBankChars total length
uint get_wordchars_length()
{
    uint totalChars = 0;
    WordBankChars.GetDimensions(totalChars);
    return totalChars;
}

// get number of banks
uint get_num_banks()
{
    uint numBanks = 0;
    WordBankOffsets.GetDimensions(numBanks);
    return numBanks;
}

// get bank start and end offsets (end = next bank start or total length)
// FALLBACK: if provided offset is out of range, scan to find the N-th bank by counting '|' in the file
void get_bank_bounds(uint bankIndex, out uint bankStart, out uint bankEnd)
{
    uint numBanks = get_num_banks();
    uint totalChars = get_wordchars_length();

    if (bankIndex < numBanks)
    {
        bankStart = WordBankOffsets[bankIndex];
        if (bankIndex + 1 < numBanks)
            bankEnd = WordBankOffsets[bankIndex + 1];
        else
            bankEnd = totalChars;

        // sanity: if offsets are nonsense, fallback to scanning
        if (bankStart >= totalChars || bankEnd > totalChars || bankEnd <= bankStart)
        {
            // fallback scan
            bankStart = 0;
            uint cur = 0;
            uint found = 0;
            while (cur < totalChars && found < bankIndex)
            {
                // advance until next '|' then skip it
                while (cur < totalChars && WordBankChars[cur] != 124 /* '|' */) cur++;
                if (cur < totalChars && WordBankChars[cur] == 124) { cur++; found++; }
            }
            bankStart = cur;
            // find end
            uint cur2 = bankStart;
            while (cur2 < totalChars && WordBankChars[cur2] != 124 /* '|' */) cur2++;
            bankEnd = (cur2 < totalChars && WordBankChars[cur2] == 124) ? cur2+1 : cur2;
        }
    }
    else
    {
        // totally out of declared range - fallback to scanning
        uint cur = 0;
        uint total = totalChars;
        uint found = 0;
        while (cur < total && found < bankIndex)
        {
            while (cur < total && WordBankChars[cur] != 124) cur++;
            if (cur < total && WordBankChars[cur] == 124) { cur++; found++; }
        }
        bankStart = cur;
        uint cur2 = bankStart;
        while (cur2 < total && WordBankChars[cur2] != 124) cur2++;
        bankEnd = (cur2 < total && WordBankChars[cur2] == 124) ? cur2+1 : cur2;
    }
}

// count number of words in bank (words separated by '|' and ending at bankEnd)
uint count_words_in_bank(uint bankStart, uint bankEnd)
{
    if (bankEnd <= bankStart) return 0;
    uint cidx = bankStart;
    uint cnt = 0;
    while (cidx < bankEnd)
    {
        // scan until '|' or end
        while (cidx < bankEnd && WordBankChars[cidx] != 124 /* '|' */) cidx++;
        // consume separator (if present)
        if (cidx < bankEnd && WordBankChars[cidx] == 124) { cidx++; cnt++; }
    }
    return cnt;
}

// find char offset of nth word (0-based) within bank (stops at bankEnd)
uint find_word_char_offset_in_bank(uint bankStart, uint bankEnd, uint wordIdx)
{
    uint cur = bankStart;
    uint found = 0;
    if (wordIdx == 0) return cur;
    while (cur < bankEnd && found < wordIdx)
    {
        // advance until '|'
        while (cur < bankEnd && WordBankChars[cur] != 124 /* '|' */) cur++;
        if (cur < bankEnd && WordBankChars[cur] == 124) { cur++; found++; }
        else break;
    }
    return cur;
}

// copy from WordBankChars starting at charOffset until '|' or bankEnd or 0
// Skip initial spaces, detect leading '~' (marker), and output markedOut = 1 if present.
// Do NOT write beyond bankEnd.
void copy_string_from_words(uint charOffset, uint bankEnd, inout uint outIdx, out uint markedOut)
{
    markedOut = 0;
    uint cur = charOffset;
    // skip leading spaces (32) and CR(13)/LF(10)
    while (cur < bankEnd && (WordBankChars[cur] == 32 || WordBankChars[cur] == 13 || WordBankChars[cur] == 10)) cur++;

    // check marker
    if (cur < bankEnd && WordBankChars[cur] == 126 /* '~' */) { markedOut = 1; cur++; }

    // skip any spaces after marker
    while (cur < bankEnd && (WordBankChars[cur] == 32 || WordBankChars[cur] == 13 || WordBankChars[cur] == 10)) cur++;

    // copy until '|' or bankEnd or 0
    while (cur < bankEnd)
    {
        uint c = WordBankChars[cur];
        if (c == 0 || c == 124 /* '|' */) break;

        if (c == '/')
            c = 10;

        StringData[outIdx++] = c;
        cur++;
    }
}


// find which word in bank is marked with '~' (returns 0xFFFFFFFF if none)
uint find_marked_index_in_bank(uint bankStart, uint bankEnd)
{
    uint cur = bankStart;
    uint idx = 0;
    while (cur < bankEnd)
    {
        uint first = WordBankChars[cur];
        if (first == 126) // '~'
            return idx;
        // advance to next '|'
        while (cur < bankEnd && WordBankChars[cur] != 124 /* '|' */) cur++;
        if (cur < bankEnd && WordBankChars[cur] == 124) { cur++; idx++; }
        else break;
    }
    return 0xffffffffu;
}

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    uint outIdx = 0;

    int q = get_current_q();
    if (q < 0) q = 0;
    int totalQ = get_total_q();
    if (q >= totalQ) q = totalQ - 1;

    uint seed = get_seed();
    seed ^= asuint(q) * 0x9E3779B9u;

    // question prefix offset
    uint qPrefixCharOffset = QuestionPrefixOffsets[q];

    // bank index == q (1 bank per question)
    uint bankIndex = (uint)q;

    // compute bank bounds and counts
    uint bankStart, bankEnd;
    get_bank_bounds(bankIndex, bankStart, bankEnd);
    uint bankCount = count_words_in_bank(bankStart, bankEnd);
    if (bankCount == 0) bankCount = 1; // fallback

    // detect marked correct index in bank (if any)
    uint marked = find_marked_index_in_bank(bankStart, bankEnd);
    uint correctWordLocalIdx = 0;
    if (marked != 0xffffffffu)
        correctWordLocalIdx = marked; // use marker as ground truth
    else
        correctWordLocalIdx = 0; // fallback if none marked

    // choose two distractors (distinct from correct)
    uint d1 = 0xffffffffu;
    uint d2 = 0xffffffffu;
    uint tryc = 0;
    uint state = seed;
    while ( (d1 == 0xffffffffu || d1 == correctWordLocalIdx) && tryc < 32 )
    {
        state = lcg(state);
        uint pick = state % bankCount;
        if (pick != correctWordLocalIdx) d1 = pick;
        tryc++;
    }
    tryc = 0;
    while ( (d2 == 0xffffffffu || d2 == correctWordLocalIdx || d2 == d1) && tryc < 64 )
    {
        state = lcg(state);
        uint pick = state % bankCount;
        if (pick != correctWordLocalIdx && pick != d1) d2 = pick;
        tryc++;
    }
    if (d1 == 0xffffffffu) d1 = (correctWordLocalIdx + 1) % bankCount;
    if (d2 == 0xffffffffu) d2 = (correctWordLocalIdx + 2) % bankCount;

    // --- choose correct position among 3 (0..2)
    state = lcg(state);
    uint correctPos = state % 3u;

    // build chosenLocal array
    uint chosenLocal[3];
    uint di = 0;
    for(uint pos = 0; pos < 3; ++pos)
    {
        if (pos == correctPos) chosenLocal[pos] = correctWordLocalIdx;
        else { if (di == 0) { chosenLocal[pos] = d1; di = 1; } else { chosenLocal[pos] = d2; di = 2; } }
    }

    // header
    const uint header[28] = {
        'S','e','l','e','c','t',' ',
        't','h','e',' ',
        'C','o','r','r','e','c','t',' ',
        'A','n','s','w','e','r',':',10,10
    };

    for(int i=0; i<28; i++)
        StringData[outIdx++] = header[i];
        
    StringData[outIdx++] = 10; // '\n'
    StringData[outIdx++] = 10;

    // question text (until '|' in Questions.txt)
    if (qPrefixCharOffset != 0xffffffffu) copy_string_from_questions(qPrefixCharOffset, outIdx);
    StringData[outIdx++] = 10;
    StringData[outIdx++] = 10;

    // write choices
    for(uint ch = 0; ch < 3; ++ch)
    {
        StringData[outIdx++] = '1' + ch;
        StringData[outIdx++] = ')';
        StringData[outIdx++] = ' ';

        uint chosenLocalIdx = chosenLocal[ch];
        uint wordCharOffset = find_word_char_offset_in_bank(bankStart, bankEnd, chosenLocalIdx);

        uint markedOut = 0;
        copy_string_from_words(wordCharOffset, bankEnd, outIdx, markedOut);

        StringData[outIdx++] = 10;

        // if this chosen item was marked as correct in file, ensure actual correctPos matches
        if (markedOut == 1)
        {
            // override correctPos so GeneratedCorrectIdx is consistent with marker
            correctPos = ch;
        }
    }

    // terminating blank line
    StringData[outIdx++] = 10;

    // store correct position for question q
    //GeneratedCorrectIdx[q] = correctPos;


    float Answered = -1;
    uint UserAnswer = get_user_answer();

    if (UserAnswer != 3)
        if (UserAnswer == GeneratedCorrectIdx[q])
            Answered = 1;
        else
            Answered = 0;

    // debug
    DebugBuf[0] = float4(asfloat(correctPos), (float)q, (float)bankStart, (float)bankEnd);
    DebugBuf[1] = float4((float)get_user_answer(), (float)GeneratedCorrectIdx[q], 69, Answered);
    AnsweredBuf[0] = Answered;
}