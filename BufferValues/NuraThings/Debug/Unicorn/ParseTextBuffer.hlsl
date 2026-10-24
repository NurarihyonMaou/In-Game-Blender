/*
 * Rich Text Formatter Compute Shader for 3DMigoto
 * Copyright (C) 2025  Unicornshell
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */


/* Formatted text iniparam syntax:
	{[slot component (wxyz)][slot index (0-idk)]:[width].[precision][type]}
	 ^------ required -----^^---- required ----^ ^------ optional -------^
	
		- "slot" will end up looking like x0, z1, w12, etc.
		
		- "width" is optional, after the column. It is an int that specifies the minimum width of the number, else it will add left padding
		
		- "precision" is an optional number, after the dot. It specifies, for floats, the amount of decimals. Does nothing for ints
		
		- "type" is either "f" or "i". It will convert the float to int if "i" is written
		  Float is the default, you don't actually need to specify it
		
	Note: You can escape the start of a sequence ( a.k.a. an open curly bracket { ) with backslash \
*/


/* Showcase text Example:
	The current runtime is {x0:.0f}s, which is {y1:i}m
	
	The value of $foo is {y0:5.1f}
	The cursor position is [{z0:4i},{w0:4i}]
	Average framerate is {x1:.2f} FPS
	
	Here's how you use the syntax (until I add buffers too):
	
	To view z0 as a float with at least 3 numbers total and 2 decimals, write "\{z0:3.2f}" or "\{z0:3.2f}"
	
	To view y12 as an int, write "\{y12:i}"
	
	Notes:
	You have to use a backslash to escape a \{sequence} formed by an open bracket \{
	It will look like this: \\{sequence}
	
	Inputing the wrong syntax will probably end up breaking shit, so make sure your syntax is correct.
	(For example, only use xyzw for slot letters)
	
	There shouldn't be ANY spaces inside string formatting brackets
*/



#ifdef SHADER_TOOLS
	#define COMPUTE_SHADER
#endif

Buffer<uint> RichText : register(t10);

//optional extra text (TODO)
/*
Buffer<uint> Raw0 : register(t0);
Buffer<uint> Raw1 : register(t1);
Buffer<uint> Raw2 : register(t2);
Buffer<uint> Raw3 : register(t3);
Buffer<uint> Raw4 : register(t4);
Buffer<uint> Raw5 : register(t5);
Buffer<uint> Raw6 : register(t6);
Buffer<uint> Raw7 : register(t7);
Buffer<uint> Raw8 : register(t8);
Buffer<uint> Raw9 : register(t9);
*/

#define LPadding '0'
//#define LPadding ' '


// 3Dmigoto declarations
Texture1D<float4> IniParams : register(t120);

#ifdef COMPUTE_SHADER

RWStructuredBuffer<uint> OutText : register(u0);

uint WriteFormattedFloat(float value, RWStructuredBuffer<uint> buf, uint precision, uint width, inout uint idx) {

	if (value < 0.0) {
		width = (width > 0) ? width - 1 : 0;
		value = -value;
		buf[idx++] = '-';
	}
	
	uint intPart = (uint)value;
	float decimalPart = value - intPart;
	
	uint digits[10];
	uint count = 0;
	
	//int part
	do {
		digits[count++] = intPart % 10;
		intPart /= 10;
	} while (intPart > 0);
		
	//we know the total length already since precision is fixed
	//don't forget to add the extra space taken by the decimal
	uint totalLen = count + ((precision > 0) ? (1 + precision) : 0);
	
	//pad with spaces if less than minimum width
	if (totalLen < width) {
		for (uint i = 0; i < width - totalLen; ++i) {
			buf[idx++] = LPadding;
		}
	}
	
	for (int i = count - 1; i >= 0; --i) {
		buf[idx++] = '0' + digits[i];
	}
	
	//float part
	if (precision > 0) {
		buf[idx++] = '.';
		
		for (uint i = 0; i < precision; ++i) {
			decimalPart *= 10;
			uint digit = (uint)decimalPart;
			buf[idx++] = '0' + digit;
			decimalPart -= digit;
		}
	}
	
	return idx;
}

//precision is unused
uint WriteFormattedInt(float fvalue, RWStructuredBuffer<uint> buf, uint precision, uint width, inout uint idx) {
	//int is slow, uint is fast
	//convert to uint cause the negative sign can just be added
	uint value = (uint)fvalue;
	
	if (fvalue < 0) {
		width = (width > 0) ? width - 1 : 0;
		buf[idx++] = '-';
	}
	
	uint digits[10];
	uint count = 0;
	
	do {
		digits[count++] = value % 10;
		value /= 10;
	} while (value > 0);
	
	uint totalLen = count;
	
	if (totalLen < width)	{
		for (uint i = 0; i < width - totalLen; ++i)
		buf[idx++] = LPadding;
	}
	
	for (int i = count - 1; i >= 0; --i) {
		buf[idx++] = '0' + digits[i];
	}

	return idx;
}


//Parses the buffer. Recursively called when slots are used
//Returns the new WriteIndex
uint parseBuffer(Buffer<uint> InText, uint WriteIndex, RWStructuredBuffer<uint> OutText) {
	
	return WriteIndex;
}



[numthreads(1, 1, 1)]
void main() {
	uint readIdx = 0;
	uint writeIdx = 0;
	uint c;
	
	//loop until null terminator
	while ((c = RichText[readIdx++]) != 0) {
		// You can escape the parser by adding a backslash just before the curly
		// Subtract by 2 instead of 1 because we just increased with ++
		if (c == '{') {
		
			// Parse Component
			// first, we expect a letter from w to z
			uint component_char = RichText[readIdx++];
			uint component;
			if (component_char == 'x') component = 0;
			else if (component_char == 'y') component = 1;
			else if (component_char == 'z') component = 2;
			else if (component_char == 'w') component = 3;
			else if (component_char == 't') component = 4;
			
			// Parse Number Index
			// then, we're looking for an int for the index, and stop when that ends
			uint index = 0;
			uint num;
			while ((num = RichText[readIdx++]) != 0) {
				if (num >= '0' && num <= '9') {
					index = index * 10 + (num - '0');
				} else {
					readIdx -= 1;
					break;
				}
			}
			
			
			// Defaults
			uint width = 0;
			uint precision = 1;
			uint type = 'f';
			
			// Parse Format Spec
			if (RichText[readIdx] == ':') {
				readIdx++;
				uint spec;
				while ((spec = RichText[readIdx++]) != 0) {
					// Parse precision segment -> Get a number
					if (spec == '.') {
						//readIdx++;
						uint p = 0;
						while (RichText[readIdx] >= '0' && RichText[readIdx] <= '9') {
							p = p * 10 + (RichText[readIdx++] - '0');
						}
						precision = p;
						// Do not break, we can expect a typecast after this
						
					// Parse the width section (appears before the .)
					} else if (spec >= '0' && spec <= '9') {
						width = width * 10 + (spec - '0');
						//readIdx++;
						
						// Do not break, we can expect a precision and typecast
						
					// Parse type cast
					} else if (spec == 'f' || spec == 'i') {
						type = spec;
						//readIdx++;
						// you can probably break after this, there shouldn't be anything else
					// We've hit the end
					} else {
						readIdx -= 1;
						break;
					}
				}
			
			
			}
			//Stop reading anything up to the end
			uint skipped;
			while ((skipped = RichText[readIdx++]) != '}' && skipped != 0) {/*nothing*/}
			
			
			float4 val = IniParams[index];
			float extracted = val[component];
			if (type == 'i') {
				WriteFormattedInt(extracted, OutText, precision, width, writeIdx);
			} else {
				WriteFormattedFloat(extracted, OutText, precision, width, writeIdx);
			}
				
			
		//skip the backslash if it is about to escape an open bracket
		//LIMITATIONS: you need to escape every single open bracket else it will try to pair them
			} else if (c == '\\'  && RichText[readIdx] == '{') {
			//jump over backslash, write open bracket, and move index past bracket so it doesn't try to parse it
			OutText[writeIdx++] = RichText[readIdx++];
			
		} else {
			//copy value
			OutText[writeIdx++] = c;
		}
	}
	// Null-terminate the output
	OutText[writeIdx] = 0;
}


#endif