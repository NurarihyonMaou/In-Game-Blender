import struct

stride = 32
format_string = "4f 4i"

with open("KamisatoAyakaBlend.buf", "rb") as f:
    data = f.read()

num_vertices = len(data) // stride

for i in range(num_vertices):
    start = i * stride
    end = start + stride
    vertex_data = struct.unpack(format_string, data[start:end])
    blend_weights = vertex_data[0:4]
    blend_indices = vertex_data[4:8]
    
    print(f"Vertex {i}: Weights = {blend_weights}, Indices = {blend_indices}")
