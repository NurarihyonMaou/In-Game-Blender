/*
 * Genshin Impact UI Scale & Pading Library mod for 3DMigoto
 * Copyright (C) 2026  Unicornshell
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

/*
- Compute shader to fetch GI interface scaling and padding

- Uses minimap border [fde82878] textureoverride
  > Reads the 4 vertices, and writes them as a float2[4] RWStructuredBuffer to u0
  > When running on the last vertex (vertexID = 3), uses the saved vertices to compute scaling and padding
  > Writes the following as a float2[2] RWBuffer to u1 for use in shader mods
	> Filters with color as to not use wrong values (during fade-in/fade-out animations)
	
- Precision >= 0.000001
*/

cbuffer CB1 : register(b1) {
	float4 cb1[4];
}

cbuffer CB2 : register(b2) {
	float4 cb2[21];
}

//Inputs, mimicking the vertex shader
struct vb0 {
	float3 position : POSITION;
	uint   color    : COLOR   ;  // seemingly actually 4 uint8s
	float2 texcoord : TEXCOORD;
};

// 3Dmigoto declarations
Texture1D<float4> IniParams : register(t120);

StructuredBuffer<vb0> VS_Input : register(t0); // input buffer

RWStructuredBuffer<float2> MinimapVertexData : register(u0); // output buffer
RWBuffer<float2> UITransformData : register(u1); // output buffer

#define FIRST_VERTEX (uint)IniParams[0].x

// Assuming 2560x1440 or 1920x1080 27" display, these are the scaling values.
// They actually stay fairly consistent across resolutions, but some larger screens become weird which is why this mod exists
#define ReferenceScale float2(0.225,0.400)
#define ReferencePaddingOffset float2(0.035, 0.009955)

[numthreads(4, 1, 1)]
void main(uint3 DTid : SV_DispatchThreadID) {

	uint vertexID = DTid.x;
	
	vb0 input = VS_Input[vertexID+FIRST_VERTEX];
	
	// matrix transform
	float4 r0 = input.position.y * cb1[1];
	r0 = cb1[0] * input.position.x + r0;
	r0 = cb1[2] * input.position.z + r0;
	r0 = r0 + cb1[3];
	
	// projection matrix
	float4 r1 = r0.y * cb2[18];
	r1 = cb2[17] * r0.x + r1;
	r1 = cb2[19] * r0.z + r1;
	float4 svpos = cb2[20] * r0.w + r1;
	
	// convert color (u32) to unpacked u8[4]
	uint4 color = uint4(
		(input.color & 0xFF000000) >> 24,
		(input.color & 0x00FF0000) >> 16,
		(input.color & 0x0000FF00) >> 8,
		(input.color & 0x000000FF)
	);
	
	// tbf I don't really know how that works but it seems to be consistent
	if (color.x == 204 && color.w == 255) {
		MinimapVertexData[vertexID] = svpos.xy;
	
	// Yes, vertexID 0 and 2 are fucking useless :)
	
	// After writing the vertex data, it's time to compute the output scaling and padding.
	// Because the minimap border isn't actually on the edge, I have to use the scale to remove some side padding
		if (vertexID == 3) {
			float2 scale = (abs(MinimapVertexData[1]) - abs(MinimapVertexData[3])) / ReferenceScale;
			UITransformData[0].xy = scale;
			UITransformData[1].xy = float2(1.0, 1.0) - (abs(MinimapVertexData[1]) + (ReferencePaddingOffset * scale));
		}
	}
}

