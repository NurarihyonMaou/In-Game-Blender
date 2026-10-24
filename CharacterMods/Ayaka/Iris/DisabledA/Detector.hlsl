// SelectVertex.hlsl

//uffer<float> HoverResult : register(t0);
//WBuffer<float> SelectionState : register(u0);
//
//exture1D<float4> IniParams : register(t120);
//
//define HOLD IniParams[32].x
//
//numthreads(1, 1, 1)]
//oid main(uint3 id : SV_DispatchThreadID)
//
//   float hold = HOLD;
//   float previousHold = SelectionState[1];
//
//   bool pressed = hold > 0.5f && previousHold <= 0.5f;
//   bool hoverValid = HoverResult[16] > 0.5f;
//
//   if (pressed && hoverValid)
//   {
//       // For this first MVP use the barycentric-dominant corner.
//       float w0 = HoverResult[17];
//       float w1 = HoverResult[18];
//       float w2 = HoverResult[19];
//
//       float vertexID;
//
//       if (w0 >= w1 && w0 >= w2)
//           vertexID = HoverResult[1];
//       else if (w1 >= w0 && w1 >= w2)
//           vertexID = HoverResult[2];
//       else
//           vertexID = HoverResult[3];
//
//       SelectionState[0] = vertexID;
//       SelectionState[2] = 1.0f;
//   }
//
//   SelectionState[1] = hold;
//