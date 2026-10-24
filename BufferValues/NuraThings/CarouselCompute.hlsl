Texture1D<float4> IniParams : register(t120);

RWBuffer<uint> StringData : register(u0);
RWBuffer<int3> DrawData : register(u1);

#define AnimValue IniParams[200].x
#define MinValue ((int)IniParams[200].y)
#define MaxValue ((int)IniParams[200].z)
#define HalfCount ((int)IniParams[200].w)


int WrapInt(int v,int minV,int maxV)
{
    int range = maxV - minV + 1;

    int x = (v - minV) % range;

    if(x < 0)
        x += range;

    return x + minV;
}


void write_digits(uint number,inout uint index)
{
    if(number == 0)
    {
        StringData[index++]='0';
        return;
    }

    uint digits[10];

    uint count=0;

    while(number>0)
    {
        digits[count++]=number%10;
        number/=10;
    }


    for(int i=count-1;i>=0;i--)
    {
        StringData[index++]='0'+digits[i];
    }
}


void write_int(int value,inout uint index)
{
    if(value<0)
    {
        StringData[index++]='-';
        value=-value;
    }

   // if(value < 10 && value > -10)
   // {
   //     StringData[index++]=' ';
   // }

    write_digits(value,index);
}


[numthreads(1,1,1)]
void main()
{
    uint i=0;

    float anim=AnimValue;

    int center=(int)round(anim);

    int halfC=HalfCount;

    //--------------------------------
    // Left → Center → Right
    //--------------------------------
    int firstValue = WrapInt(center - halfC, MinValue, MaxValue);
    DrawData[0] = int3((MaxValue - MinValue) + 1, firstValue, MinValue);
    
    for(int offset=-halfC;offset<=halfC;offset++)
    {

        int v=WrapInt(center+offset,MinValue,MaxValue);

        write_int(v,i);

        //--------------------------------
        // spacing
        //--------------------------------

        if(offset!=halfC)
        {
            StringData[i++]=' ';
            StringData[i++]=' ';
            StringData[i++]=' ';
        }

    }

}