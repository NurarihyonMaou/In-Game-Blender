from PIL import Image, ImageDraw
import numpy as np
from collections import deque

# === CONFIG ===
image_path = "ASCIIGlyph.dds"   # your glyph atlas image
alpha_threshold = 16            # alpha > this is visible
output_hlsl_file = "glyph_widths_hlsl.txt"
debug_image_path = "glyphs_detected.png"

# === LOAD IMAGE ===
img = Image.open(image_path).convert("RGBA")
w, h = img.size
pixels = np.array(img)
alpha = pixels[:, :, 3]

# === VISITED MASK ===
visited = np.zeros((h, w), dtype=bool)

glyph_bboxes = []

def neighbors(y, x):
    for ny, nx in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]:
        if 0 <= ny < h and 0 <= nx < w:
            yield ny, nx

def bfs_find_glyph(start_y, start_x):
    queue = deque()
    queue.append((start_y, start_x))
    visited[start_y, start_x] = True

    min_x, max_x = start_x, start_x
    min_y, max_y = start_y, start_y

    while queue:
        y, x = queue.popleft()

        for ny, nx in neighbors(y, x):
            if not visited[ny, nx] and alpha[ny, nx] > alpha_threshold:
                visited[ny, nx] = True
                queue.append((ny, nx))

                # Expand bounding box
                min_x = min(min_x, nx)
                max_x = max(max_x, nx)
                min_y = min(min_y, ny)
                max_y = max(max_y, ny)

    return (min_x, min_y, max_x, max_y)

# === FIND ALL GLYPHS ===
for y in range(h):
    for x in range(w):
        if not visited[y, x] and alpha[y, x] > alpha_threshold:
            bbox = bfs_find_glyph(y, x)
            glyph_bboxes.append(bbox)

# Sort glyphs left-to-right, top-to-bottom roughly
glyph_bboxes.sort(key=lambda b: (b[1], b[0]))  # sort by y, then x

# === OUTPUT HLSL ARRAY ===
hlsl_lines = ["static const float GlyphWidths[] = {"]
for min_x, min_y, max_x, max_y in glyph_bboxes:
    glyph_width = (max_x + 1) - min_x  # in pixels
    normalized_width = glyph_width / w
    hlsl_lines.append(f"    {normalized_width:.6f},")
hlsl_lines.append("};")

with open(output_hlsl_file, "w") as f:
    f.write("\n".join(hlsl_lines))

print(f"✅ Glyph widths written to: {output_hlsl_file}")

# === DEBUG IMAGE (Optional) ===
draw = ImageDraw.Draw(img)
for i, (min_x, min_y, max_x, max_y) in enumerate(glyph_bboxes):
    draw.rectangle([min_x, min_y, max_x, max_y], outline="red")
    draw.text((min_x, min_y-10), str(i), fill="yellow")
img.save(debug_image_path)
print(f"✅ Debug glyph bounding boxes image saved to: {debug_image_path}")
