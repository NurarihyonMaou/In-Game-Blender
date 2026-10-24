#!/usr/bin/env python3
from PIL import Image, ImageFont, ImageDraw
import argparse, sys

CHARS_ACROSS = 16
CHARS_DOWN = 6

def render_font(font_path, char_width, char_height, output):
    # Use 8-bit grayscale to store width/height metadata
    image = Image.new('L', (char_width * CHARS_ACROSS, char_height * CHARS_DOWN))
    pixels = image.load()
    draw = ImageDraw.Draw(image)

    try:
        font = ImageFont.truetype(font_path, char_height)
    except OSError:
        print(f"Cannot open {font_path}. Use full path if necessary.")
        sys.exit(1)

    for i, c in enumerate(range(0x20, 0x7f)):
        x = i % CHARS_ACROSS
        y = i // CHARS_ACROSS

        # Draw character at top-left of its cell
        draw.text((x * char_width, y * char_height), chr(c), font=font, fill=255)

        # Encode width/height into char127 (last cell)
        w = font.getbbox(chr(c))[2] - font.getbbox(chr(c))[0]
        h = font.getbbox(chr(c))[3] - font.getbbox(chr(c))[1]

        # Pixel positions in char127
        meta_x = (CHARS_ACROSS - 1) * char_width + x
        meta_y = (CHARS_DOWN - 1) * char_height + y*2
        if meta_y < char_height * CHARS_DOWN:
            pixels[meta_x, meta_y] = w
        if meta_y+1 < char_height * CHARS_DOWN:
            pixels[meta_x, meta_y+1] = h

    # Draw char 127 blank (optional)
    x127 = (0x7f % CHARS_ACROSS) * char_width
    y127 = (0x7f // CHARS_ACROSS) * char_height
    draw.rectangle([x127, y127, x127 + char_width, y127 + char_height], fill=0)

    image.save(output)
    print(f"Saved pixel-perfect font atlas with char127 metadata to {output}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("font", help="Path to .ttf pixel font")
    parser.add_argument("output", help="Output image path (PNG recommended)")
    parser.add_argument("--char-width", type=int, default=16, help="Width of each character cell")
    parser.add_argument("--char-height", type=int, default=16, help="Height of each character cell")
    args = parser.parse_args()

    render_font(args.font, args.char_width, args.char_height, args.output)

if __name__ == "__main__":
    main()
