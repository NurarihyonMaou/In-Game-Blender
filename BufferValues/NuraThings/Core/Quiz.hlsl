// QuizGenAnswers.hlsl
Texture1D<float4> IniParams : register(t120);

// outputs
RWBuffer<uint> StringData           : register(u0); // R8_UINT char buffer for TextPrinter
RWBuffer<uint> GeneratedCorrectIdx  : register(u1); // one uint per question -> which choice (0..2) is correct
RWBuffer<float4> DebugBuf             : register(u2); // optional debug

// question data
Buffer<uint> QuestionChars          : register(t121); // all question text (prefix/suffix) packed, '\n' terminators
Buffer<uint> QuestionPrefixOffsets  : register(t122); // offset into QuestionChars for prefix per question
Buffer<uint> QuestionSuffixOffsets  : register(t123); // offset into QuestionChars for suffix per question
Buffer<uint> QuestionBankIndex      : register(t124); // which word bank to use per question (index into WordBankOffsets)
Buffer<uint> QuestionCorrectWordIdx : register(t125); // index within the bank of the correct word for this question

// word bank data (multiple banks possible)
Buffer<uint> WordBankChars          : register(t126); // all words packed per-bank, '\n' terminated
Buffer<uint> WordBankOffsets        : register(t127); // start offset (into WordBankWordsIndex array) per bank OR start char offset per bank
Buffer<uint> WordBankCounts         : register(t119); // number of words per bank

// IniParams layout helpers:
// [210].x = currentQuestion (float but used as int)
// [210].y = rngSeed
// [210].z = requiredChoicesCount (we'll ignore, default 3)
// [211].x = totalQuestions
// [211].y = maxWordsPerBank (not strictly required)

#define INI_Q_STATE 78
#define INI_Q_META  79

int get_current_q() { return 1; }
uint get_seed()      { return 1; }
int get_total_q()    { return 12;}
int get_max_words()  { return 3;}

// simple LCG RNG (returns new state)
uint lcg(uint state)
{
    // parameters from Numerical Recipes-like (32-bit)
    return state * 1664525u + 1013904223u;
}

// copy string from WordBankChars or QuestionChars into StringData starting at 'outIdx'.
// stops on '\n' (10) or 0 and writes characters, advances outIdx.
void copy_string_chars(Buffer<uint> bankChars, uint baseOffset, inout uint outIdx)
{
    // bankChars here is bound to WordBankChars or QuestionChars depending on caller.
    // But HLSL doesn't let us pass Buffer<uint> by value easily — so we'll use two separate functions below.
}

// copy from QuestionChars
void copy_string_from_questions(uint qcharOffset, inout uint outIdx)
{
    // copy until '\n' or 0
    for(uint k = 0; ; ++k)
    {
        uint c = QuestionChars[qcharOffset + k];
        if (c == 0 || c == 10) break;
        StringData[outIdx++] = c;
    }
}

// copy from WordBankChars starting at charOffset
void copy_string_from_words(uint charOffset, inout uint outIdx)
{
    for(uint k = 0; ; ++k)
    {
        uint c = WordBankChars[charOffset + k];
        if (c == 0 || c == 10) break;
        StringData[outIdx++] = c;
    }
}

// find the char-offset of the nth word in a bank.
// bankCharStart = global char offset where bank starts inside WordBankChars.
// wordIdx = 0..(count-1)
uint find_word_char_offset_in_bank(uint bankCharStart, uint wordIdx, uint bankCount)
{
    // simple linear scan: step through words (they are '\n' terminated). Not optimal for huge banks,
    // but simplest: walk until you hit wordIdx-th '\n' occurrence.
    uint cur = bankCharStart;
    uint found = 0;
    if (wordIdx == 0) return cur;
    while (found < wordIdx)
    {
        uint c = WordBankChars[cur++];
        // advance until newline
        while (WordBankChars[cur] != 10 && WordBankChars[cur] != 0) cur++;
        // now cur points at '\n' or 0; skip it if it's '\n'
        if (WordBankChars[cur] == 10) { cur++; found++; }
        else { /*hit 0 - shorter than expected*/ break; }
    }
    return cur;
}

[numthreads(1,1,1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
    // single-threaded generator
    uint outIdx = 0;

    int q = 2;
    if (q < 0) q = 0;
    int totalQ = get_total_q();
    if (q >= totalQ) q = totalQ - 1;

    uint seed = get_seed();
    // mix seed with question so different q produce different sequences
    seed ^= asuint(q) * 0x9E3779B9u;
    // --- fetch question metadata
    uint qPrefixCharOffset = QuestionPrefixOffsets[q];
    uint qSuffixCharOffset = QuestionSuffixOffsets[q];
    uint bankIndex = QuestionBankIndex[q];
    uint correctWordLocalIdx = QuestionCorrectWordIdx[q]; // index inside bank: 0..bankCount-1

    // bounds safety
    uint bankCount = 0;

    uint bufferSize;

    WordBankCounts.GetDimensions(bufferSize);

    if (bankIndex < bufferSize) bankCount = WordBankCounts[bankIndex];
    // fallback if binding doesn't provide counts
    if (bankCount == 0) bankCount = WordBankCounts[0];

    uint bankCharStart = WordBankOffsets[bankIndex]; // char offset where bank begins in WordBankChars

    // clamp correct local idx
    if (correctWordLocalIdx >= bankCount) correctWordLocalIdx = 0;

    // --- choose two distractors (distinct from correct)
    uint d1 = 0xffffffffu;
    uint d2 = 0xffffffffu;

    // make several tries to pick distinct distractors
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
    // fallback: if still invalid, set to any different index
    if (d1 == 0xffffffffu) d1 = (correctWordLocalIdx + 1) % bankCount;
    if (d2 == 0xffffffffu) d2 = (correctWordLocalIdx + 2) % bankCount;

    // --- choose correct position among 3 (0..2)
    state = lcg(state);
    uint correctPos = state % 3u;

    // build array of chosen local word indices in order to output
    uint chosenLocal[3];
    uint di = 0;
    for(uint pos = 0; pos < 3; ++pos)
    {
        if (pos == correctPos)
        {
            chosenLocal[pos] = correctWordLocalIdx;
        }
        else
        {
            if (di == 0) { chosenLocal[pos] = d1; di = 1; }
            else         { chosenLocal[pos] = d2; di = 2; }
        }
    }

    // --- write header/instruction
    // "Select the correct answer:\n\n"
    StringData[outIdx++]='S';
    StringData[outIdx++]='e';
    StringData[outIdx++]='l';
    StringData[outIdx++]='e';
    StringData[outIdx++]='c';
    StringData[outIdx++]='t';
    StringData[outIdx++]=' ';
    StringData[outIdx++]='t';
    StringData[outIdx++]='h';
    StringData[outIdx++]='e';
    StringData[outIdx++]=' ';
    StringData[outIdx++]='c';
    StringData[outIdx++]='o';
    StringData[outIdx++]='r';
    StringData[outIdx++]='r';
    StringData[outIdx++]='e';
    StringData[outIdx++]='c';
    StringData[outIdx++]='t';
    StringData[outIdx++]=' ';
    StringData[outIdx++]='a';
    StringData[outIdx++]='n';
    StringData[outIdx++]='s';
    StringData[outIdx++]='w';
    StringData[outIdx++]='e';
    StringData[outIdx++]='r';
    StringData[outIdx++]=':';

    StringData[outIdx++] = 10; // '\n'
    StringData[outIdx++] = 10;

    // --- write question: prefix + (blank) + suffix + '\n\n'
    if (qPrefixCharOffset != 0xffffffffu) copy_string_from_questions(qPrefixCharOffset, outIdx);
    // write a blank marker or nothing; usually question already contains a blank like "Select the fruit: "
    StringData[outIdx++] = 10;
    StringData[outIdx++] = 10;

    // --- for each choice: write e.g. "1) <word>\n"
    for(uint ch = 0; ch < 3; ++ch)
    {
        // write choice number and bracket: '1) '
        StringData[outIdx++] = '1' + ch; // '1','2','3'
        StringData[outIdx++] = ')';
        StringData[outIdx++] = ' ';

        // find char offset of chosenLocal[ch] within bank
        uint chosenLocalIdx = chosenLocal[ch];
        uint wordCharOffset = find_word_char_offset_in_bank(bankCharStart, chosenLocalIdx, bankCount);

        // write the word (from WordBankChars)
        copy_string_from_words(wordCharOffset, outIdx);

        StringData[outIdx++] = 10; // newline
    }

    // blank terminating newline
    StringData[outIdx++] = 10;

    // write null terminator
    StringData[outIdx++] = 0;

    // write which position is correct for this question into GeneratedCorrectIdx[q]
    GeneratedCorrectIdx[q] = correctPos;

    // optional: debug

    //uint DebugSize;
    //DebugBuf.GetDimensions(DebugSize);
//
    //if (DebugSize > 0)
    //{
    DebugBuf[0] = float4(asfloat(correctPos), (float)q, float(seed), 69);
    DebugBuf[1] = float4((float)q, (float)bankCharStart, (float)bankCount, 96);

    for(uint f = 2; f < 6; f++)
        DebugBuf[f] = float4(StringData[0+(1*f)], StringData[1+(2*f)], StringData[2+(3*f)], StringData[3+(4*f)]);
        //DebugBuf[1] = (uint)q;
        //DebugBuf[2] = seed;
    //}
}